#!/usr/bin/perl -w
#
# Find the pmids and get their reference info

use strict;
use diagnostics;
use Pg;

###GLOBALS
my ($print, $o);
my %PMID;
my $pmid = $ARGV[0];
my $outfile = $ARGV[1];

&readPMIDList($pmid);
print "Opening PostGres database ....";
my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;
print "done!\n";
&getRecentPapers(\%PMID);
open(OUT, ">$outfile") || die "Can't open $outfile: $!";
print OUT "$print";
close(OUT);

sub readPMIDList{
    my $u = shift;

    open (IN, $u)  or die "Cannot open $u : $!";;
    while (<IN>) {chomp; $PMID{$_}++;}
    close (IN) or die "Cannot close $u : $!";
    return %PMID;
}

sub getRecentPapers{
    my ($u) = shift;

    for (keys %$u){
	my $pmids = $conn->exec( "SELECT * FROM ref_pmid WHERE joinkey = '$_';");
	my @row = ();
	while (@row = $pmids->fetchrow) {
	    if ($row[0]) {
		$print = ""; 
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
#    $Papers{$pap}++;
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
