#!/usr/bin/perl -w
#
# Find the pmids and get their reference info

use strict;
use diagnostics;
use Pg;

###GLOBALS
my $i = 0;
my $o;
my $print;
my %Papers;

###MAIN
print "Enter timestamp you would like to search from (format YYYY-MM-DD): ";
my $timestamp = <STDIN>;
if ($timestamp =~ /\d{4}-\d{2}-\d{2}/){chomp($timestamp)}else{exit}

print "Opening PostGres database ....";
my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;
print "done!\n";

&getRecentPapers($timestamp);

my $rundate = `date +%Y-%m-%d`; chomp $rundate;

my $outfile = "cgc_from_".$timestamp."_to_".$rundate.".".$$;

open(OUT, ">$outfile") || die "Can't open $outfile: $!";
print OUT "$print";
close(OUT);
print "\n\nThere are $i new papers in PostGres since $timestamp\n";


###SUBROUTINES
sub getRecentPapers{
    my $tmstp = shift;

    my %pmids;
    my @tmp = $conn->exec( "SELECT * FROM ref_origtime WHERE ref_origtime >= '$tmstp';");
    for (@tmp){
	my @row = ();
	while (@row = $_->fetchrow) {
	    if ($row[0]) {
		$print = ""; 
		$i++;
		$row[0] =~ s///g;
		$row[0] =~ s/\s+//g;

		&getRef($row[0]);
		$print .= $o;
	    } # if ($row[0])
	} # while (@row = $result->fetchrow)
    }
}

sub getRef {
    my $pap = shift;

    my @fields = qw(title author journal volume pages year abstract genes);
    $o .= $pap;
    $Papers{$pap}++;
    foreach my $field (@fields) {
	$field = 'ref_' . $field;
	my $result = $conn->exec( "SELECT * FROM $field WHERE joinkey = '$pap';");
	my $out = '';
	while (my @row = $result->fetchrow) {
	    if ($row[1]) { 
		$row[1] =~ s///g;
		$row[1] =~ s/\n//g;
		$out = $row[1];
	    } # if ($row[0])
	} # while (@row = $result->fetchrow)
	$o .= "\t$out";
    } # foreach my $field (@fields)
    $o .= "\n";
    return $o;
} # sub getRef
