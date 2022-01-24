#!/usr/bin/perl
# Insert CONLL-U annotated text into source TEI
# It is assumed that <ab> is the only element containing text,
# and that it does not contain mixed content
# Usage:
# conllu2tei.pl <CONLL-U> < <SOURCE-TEI> > <TARGET-TEI>
#
use warnings;
use utf8;
binmode STDERR, 'utf8';
binmode STDIN,  'utf8';
binmode STDOUT, 'utf8';

#Prefixed to use on values, and the type of the UD linkGrp
$msd_prefix = 'mte';
$ud_prefix  = 'ud-syn';
$ud_type    = 'UD-SYN';

# Read in CONLL-U
$udFile = shift;

#Words need ID's if they are parsed
#If ab does not have ID, then take it from udFilename
($doc_prefix) = $udFile =~ m|([^/]+)\.conllu| or die "Bad $udFile\n";

open TBL, '<:utf8', $udFile or die;
$/ = "# newpar id = "; 
while (<TBL>) {
    chomp; #Newpar is snipped off, a line starts with newpar_id number
    push(@connlu, $_) if /\t/; #First one will be empty, so check if \t
}
close TBL;

#Read in one ab per line from source TEI
$/ = "</ab>";
$ab_n = 0;
while (<>) {
    if (($prefix, $ab) = m|(.*)(<ab[ >].+</ab>)|s) {
	print &id_tei($prefix) if $prefix;
	($stag, $text, $etag) = $ab =~ m|(<ab.*?>)(.+?)(</ab>)|s
	    or die "WEIRD1: $ab";
	if ($stag =~ m| xml:id="(.+?)"|) {$ab_id = $1}
	else {
	    $ab_id = $doc_prefix . '.' . ++$ab_n;
	    $stag =~ s|>| xml:id="$ab_id">|; #No need to give abs ids
	}
	$text =~ s/\s+/ /gs; # Will use it for sanity check
	$text =~ s/^ //;
	$conllu_ab = shift(@connlu);
	($conllu_incipit) = $conllu_ab =~ /\n# text = (.+)\n/
	    or die "WEIRD2: $conllu_ab";
	$conllu_incipit = &xml_encode($conllu_incipit);
	die "Out of synch:\n$conllu_incipit\n$text\n"
	    unless $text =~ /^\Q$conllu_incipit\E/;
	
	$teiana_ab = conllu2tei($ab_id, $conllu_ab);

	print "$stag\n$teiana_ab\n      $etag";
    }
    elsif (not m|</ab>|) {print}
    else {die "WIERD3: $_"}
}

sub id_tei {
    $txt = shift;
    my ($tei) = $txt =~ m|(<TEI.*?>)|s;
    if ($tei) {
	if ($tei =~ m|xml:id=|) {
	    $txt =~ s|xml:id=".+?"|xml:id="$doc_prefix"|
	}
	else {
	    $txt =~ s|(<TEI.*?)>|$1 xml:id="$doc_prefix">|s
	}
    }
    return $txt
}

#Convert one ab into TEI
sub conllu2tei {
    my $id = shift;
    my $conllu = shift;
    my $tei;
    foreach my $sent (split(/# sent_id = /, $conllu)) {
    #foreach my $sent (split(/\n\n/, $conllu)) {
	next unless $sent =~ /# text = .+\n/;
	#my ($sent_n) = $sent =~ /# sent_id = \d+\.(\d+)/
	my ($sent_n) = $sent =~ /^\d+\.(\d+)/
	    or die "WEIRD4: $sent";
	$sent_id = $id . '.' . $sent_n;
	$tei .= sent2tei($sent_id, $sent);
    }
    $tei =~ s|\s+$||;
    return $tei
}

#Convert one sentence into TEI
sub sent2tei {
    my $id = shift;
    my $conllu = shift;
    my $tei;
    my $tag;
    my $element;
    my $space;
    my @ids = ();
    my @toks = ();
    my @deps = ();
    $tei = "<s xml:id=\"$sent_id\">\n";
    foreach my $line(split(/\n/, $conllu)) {
	chomp;
	next unless $line =~ /^\d+\t/;
 	my ($n, $token, $lemma, $upos, $xpos, $ufeats, $link, $role, $extra, $local) 
	    = split /\t/, $line;
	$xpos =~ s/-+$//;   # Get rid of trailing dashes introduced by Stanford NLP
	if ($token =~ /^[[:punct:]]+$/ and ($upos ne 'PUNCT' and $upos ne 'SYM')) {
	    $tag = 'pc';
	    $lemma = $token;
	    if ($token =~ /[$%§©+−×÷=<>]/) {$upos = 'SYM'}
	    else {$upos = 'PUNCT'}
	    print STDERR "WARN: changing UPOS to $upos for\n$line\n";
	    $xpos = 'Z';
	    $ufeats = '_';
	}
	if ($xpos !~ /_/) {
	    if ($xpos =~ /Z/) {$tag = 'pc'}
	    else {$tag = 'w'}
	}
	else {
	    if ($token =~ /^[[:punct:]]+$/) {$tag = 'pc'}
	    else {$tag = 'w'}
	}
	if ($upos !~ /_/) {
	    $feats = "UposTag=$upos";
	    $feats .= "|$ufeats" if $ufeats ne '_';
	}
	$local =~ s/NER=[A-Z-]+\|?//;   #Get rid of NER for now!
	$space = $local !~ s/SpaceAfter=No//;
	$feats .= "|$local" if $local and $local ne '_';
	$token = &xml_encode($token);
	$lemma = &xml_encode($lemma);
	if ($tag eq 'w') {$element = "<$tag>$token</$tag>"}
	elsif ($tag eq 'pc') {$element = "<$tag>$token</$tag>"}
	if ($xpos ne '_') {$element =~ s|>| ana=\"$msd_prefix:$xpos\">|}
	if ($feats and $feats ne '_') {$element =~ s|>| msd=\"$feats\">|}
	if ($tag eq 'w' and $lemma ne '_') {$element =~ s|>| lemma=\"$lemma\">|}
	$element =~ s|>| join="right">| unless $space;
	push @ids, $id . '.t' . $n;
	push @toks, $element;
	push @deps, "$link\t$n\t$role" #Only if we have a parse
	    if $role ne '_';
    }
    unless (@deps) { #No parse
	$tei .= join "\n", @toks;
    }
    else { # Parsed
	#Give IDs to tokens as we have a parse
	foreach my $id (@ids) {
	    my $element = shift @toks;
	    $element =~ s| | xml:id="$id" |;
	    $tei .= "$element\n";
	}
	$tei .= "<linkGrp type=\"$ud_type\" targFunc=\"head argument\" corresp=\"#$id\">\n";
	foreach $dep (@deps) {
	    my ($head, $arg, $role) = split /\t/, $dep;
	    $head_id = $id;  #if 0 points to sentence id
	    $head_id .= '.t' . $head if $head; 
	    $arg_id = $id . '.t' . $arg;
	    $tei .= "  <link ana=\"$ud_prefix:$role\" target=\"#$head_id #$arg_id\"/>\n";
	}
	$tei .=  "</linkGrp>";
    }
    $tei .= "\n</s>\n";
    return $tei
}

sub xml_encode {
    my $str = shift;
    $str =~ s|&|&amp;|g;
    $str =~ s|<|&lt;|g;
    $str =~ s|>|&gt;|g;
    #$str =~ s|"|&quot;|g;
    return $str
}
