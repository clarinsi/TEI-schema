#!/usr/bin/perl
use warnings;
use utf8;
binmode STDERR, 'utf8';
binmode STDIN,  'utf8';
binmode STDOUT, 'utf8';
print "### Grab selected IMP books and prepare them from ElTeC\n";
print "cd ../IMP\n";
print "rm -fr *\n";
print "wget https://www.clarin.si/repository/xmlui/bitstream/handle/11356/1031/IMP-dl-tei.zip\n";
while (<>) {
    next if /Kanoničnost/;
    chomp;
    s/^"//; s/"$//; s/\t"/\t/g; s/"\t/\t/g; s/""/"/g; s/­//g;
    my ($author, $sex, $birth, $death, $title, 
	$label, $published, $digitised, $period, $words, $canon, 
	$reprints, $status, $signature, $url) =
	    split /\t/;
    $imp_id = $url;
    next if $status eq 'WAIT';
    unless ($imp_id) {
	print STDERR "WARN: no source for $author: $title\n";
	next
    }
    next unless $imp_id =~ /^WIKI\d+$/;
    
    ($index_year = $published) =~ s/[,-].+//; 
    $fName_txt = "$imp_id-$index_year.xml";
    print "# $imp_id: $author. $title\n";
    print "unzip IMP-dl-tei.zip     IMP-dl-tei/$fName_txt\n";
    print "mv IMP-dl-tei/$fName_txt .\n";
}
print "rm IMP-dl-tei.zip\n";
print "rm -r IMP-dl-tei\n";
#print "rm IMP-corpus-tei.zip\n";
#print "rm -r IMP-corpus-tei\n";
