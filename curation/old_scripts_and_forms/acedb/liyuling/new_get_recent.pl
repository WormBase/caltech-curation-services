#! /usr/bin/perl -w

use strict;
use DBI;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to
database!\n";

#my $outfile = '/home/acedb/public_html/liyuling/tair_fp.txt';
my $outfile = '/home/acedb/public_html/liyuling/tair_tp.txt';
open (OUT, ">$outfile") or die "Cannot create $outfile : $!";

my $result = $dbh->prepare( " SELECT * FROM ccc_tair_gene_comp_go WHERE ccc_goterm != 'false positive' AND ccc_goterm != 'already curated' AND ccc_goterm != 'scrambled sentence' AND ccc_goterm != 'not go curatable';");
#my $result = $dbh->prepare( "SELECT * FROM ccc_tair_gene_comp_go WHERE ccc_goterm = 'true positive';" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) 
{

#	if($row[0])
#	{
#		print OUT "$row[0]\n";
#	}
	#my $num = @row;
	#print "$num elements\n";
	foreach(@row)
	{
	#	my $cell = $_;
		print OUT "$_	";
	}
	print OUT "\n";
}
#{ if ($row[3]) { print OUT "$row[3]\n"; } }

close (OUT) or die "Cannot close $outfile : $!";
