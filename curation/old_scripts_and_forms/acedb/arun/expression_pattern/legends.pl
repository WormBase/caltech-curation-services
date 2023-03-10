#!/usr/bin/perl -w

use strict;
use diagnostics;
use DBI;

# use the first and last docid's for 'Development'
use constant FIRST_DOCID => 7895;
use constant LAST_DOCID  => 8092;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my $outfile = "development_legends.txt";
open(OUT, ">$outfile") or die($!);
#my $result = $dbh->prepare( "SELECT * FROM pic_description" );
my $result = $dbh->prepare( "SELECT pic_description.joinkey, pic_paper.pic_paper, pic_description.pic_description, pic_source.pic_source FROM pic_description, pic_source, pic_paper WHERE pic_paper.joinkey =  pic_source.joinkey AND pic_source.joinkey = pic_description.joinkey AND pic_source.pic_source IS NOT NULL AND pic_description.pic_description IS NOT NULL AND pic_source.joinkey NOT IN (SELECT joinkey FROM pic_croppedfrom)" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) {
    # each row has 4 columns, the pgid, the docid, legend and filename
    if ( ($row[0] >= FIRST_DOCID) and ($row[0] <= LAST_DOCID) ) { 
		my $docid = $row[1];
		my $legend = $row[2];
		my $legend_filename = $row[3];
	
		# clean up legend
        my @lines = split(/\n/, $legend);
        $legend = join(" ", @lines);
        $legend =~ s/\s+/ /g;

        print OUT "$row[0]\t$docid\t$legend_filename\t$legend\n";
    }
}
close(OUT);

print "Output in $outfile.\n";
