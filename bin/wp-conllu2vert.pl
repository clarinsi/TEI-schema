#!/usr/bin/perl -w
use utf8;
binmode(STDIN,'utf8');
binmode(STDOUT,'utf8');
binmode(STDERR,'utf8');
$first_doc = 1;
while (<>) {
    chomp;
    # New document
    if (/^# newdoc.id/) {
	unless ($first_doc) {
	    print "</p>\n";
	    print "</text>\n"
	}
	else {$first_doc = 0}
	$new_doc = 1;
	($doc_id) = / = (.+)/;
	undef %meta;
    }
    # New paragraph
    elsif (/^# newpar id/) {
	if ($new_doc) {
	    print "<text id=\"$doc_id\"";
	    foreach $att (sort keys %meta) {
		print " $att=\"$meta{$att}\"";
	    }
	    print ">\n";
	    $new_doc = 0;
	}
	else {print "</p>\n"}
	($par_id) = / = (.+)/;
	#$id = $doc_id . "." . $par_id;
	$id = $par_id;
	print "<p id=\"$id\">\n";
    }
    # New sentence
    elsif (/^# sent_id/) {
	($sent_id) = / = (.+)/;
	#$id = $doc_id . "." . $sent_id;
	$id = $sent_id;
	print "<s id=\"$id\">\n";
    }
    # Line with text, ignore
    elsif (/^# text = /) {}
    # Line with sundry metadata
    elsif (($att, $val) = /^# (.+?) = (.+)/) {
	$val =~ s| | |g;
	$val =~ s|­|-|g;
	$val =~ s|  +| |g;
	$val =~ s|^ ||;
	$val =~ s| $||;
	$val =~ s|([^\\])"|$1\\"|g;
	$meta{$att} = $val;
    }
    # End of sentence: output sentence
    elsif (/^$/) {
	#print join("\n", headify(@lines));
	print join("\n", finalize(headify(@lines)));
	print "\n";
	print "</s>\n";
	@lines = ();
    }
    # Token with annotations
    elsif (/\t/) {
	print STDERR "WARN: Removing NOBREAK SPACE in $sent_id, line: $_\n" if / /;
	s| ||g;
	print STDERR "WARN: Changing SOFT HYPHEN to HYPHEN in $sent_id, line: $_\n" if /­/;
	s|­|-|g;
	my ($i, $token, $lemma, $UPoS, $XPoS, $UFeats, $head_i, $URel, $EXT, $Local) =
	    split /\t/;
	$line = join("\t",
		     $token,
		     $lemma,
		     $XPoS,
		     $UPoS,
		     $UFeats,
		     $i, 	     
		     $URel,
		     $Local,
		     $head_i);
	push(@lines, $line);
    }
}
print "</p>\n";
print "</text>\n";

# Add annotations for syntactic head
sub headify {
    my @lines = @_;
    my $i = 0;
    my @out;
    my ($token, $lemma, $XPoS, $UPoS, $UFeats);
    foreach my $line (@lines) {
	#No syntactic annotation
	if (($head_i) = $line =~ /.+\t(\d+)$/ and 
	    $head_i > 0 and $lines[$head_i-1]) {
	    ($token,
	     $lemma,
	     $XPoS,
	     $UPoS,
	     $UFeats) = split("\t", $lines[$head_i-1]);
	}
	else {
	    $token = '_';
	    $lemma = '_';
	    $XPoS = '_';
	    $UPoS = '_';
	    $UFeats = '_';
	    $head_i = '0';
	}
	my $new_line = $line;
	$new_line =~ s/(.+)\t[0-9_]+$/$1\t$lemma\t$XPoS\t$UPoS\t$UFeats\t$head_i/;
	push(@out, $new_line);
    }
    return @out
}

#Insert <g/> and <name>
sub finalize {
    my @lines = @_;
    my $ner = 'O';
    my $prev_ner = 'O';
    my @out = ();
    foreach my $line (@lines) {
	my ($token, $lemma, $XPoS, $UPoS, $UFeats, $i,
	    $URel, $Local,
	    $h_lemma, $h_XPoS, $h_UPoS, $h_UFeats, $h_i) =
	    split /\t/, $line;
	($ner) = $Local =~ /NER=([^|]+)/ or
	    print STDERR "ERROR: No NER in $sent_id, line: $line\n";
	if ($ner eq 'O' and $prev_ner ne 'O') {
	    push(@out, "</name>")
	}
	$Local =~ s/\|?NER=[^|]+//;
	if (($type) = $ner =~ /B-(.+)/) {
	    push(@out, "<name type=\"$type\">")
	}
	elsif ($prev_ner eq 'O' and ($type) = $ner =~ /I-(.+)/) {
	    print STDERR "WARN: NER=I for first token in $sent_id, line: $line\n";
	    push(@out, "<name type=\"$type\">")
	}
	my $glue = 0;
	$glue = 1 if $Local =~ s/\|?SpaceAfter=No//;
	if ($Local) {
	    if ($UFeats eq '_') {$UFeats = $Local}
	    else {$UFeats .= "|$Local"}
	}
	$UFeats =~ s/\|/ /g;
	$h_UFeats =~ s/\|/ /g;
	push(@out, join("\t",
			($token, $lemma, $XPoS, $UPoS, $UFeats, $i,
			 $URel,
			 $h_lemma, $h_XPoS, $h_UPoS, $h_UFeats, $h_i)));
	$prev_ner = $ner;
	push(@out, "<g/>") if $glue;
    }
    if ($prev_ner ne 'O') {
	push(@out, "</name>")
    }
    return @out;
}
