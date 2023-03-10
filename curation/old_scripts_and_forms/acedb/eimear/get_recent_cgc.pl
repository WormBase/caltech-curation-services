#!/usr/bin/perl -w
#
# Find the pmids and get their reference info

use strict;
use diagnostics;
use Pg;

###GLOBALS
my $dateShort = "";                             # current date
my $i = 0;
my $j = 0;
my $o;
my $print;
my %Papers;
#my @fields = qw(title author journal volume pages year abstract genes);

###MAIN
print "Enter timestamp you would like to search from (format YYYY-MM-DD): ";
my $timestamp = <STDIN>;
if ($timestamp =~ /\d{4}-\d{2}-\d{2}/){chomp($timestamp)}else{exit}

print "Opening PostGres database ....";
my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;
print "done!\n";

&getRecentPapers($timestamp);
#&getRecentUpdates($timestamp, \%Papers);
&getDate();
my $outfile = "cgc_from_".$timestamp."_to_".$dateShort;
open(OUT, ">$outfile") || die "Can't open $outfile: $!";
print OUT "$print";
close(OUT);
print "\n\nThere are $i new papers and $j updates in PostGres since $timestamp\n";

###SUBROUTINES
sub getRecentPapers{
    my $tmstp = shift;

    my %pmids;
#    my $cgcs = $conn->exec( "SELECT * FROM ref_cgc WHERE ref_timestamp >= '$tmstp';");
#    my $pmids = $conn->exec( "SELECT * FROM ref_pmid WHERE ref_timestamp >= '$tmstp';");
    my @tmp = $conn->exec( "SELECT * FROM ref_origtime WHERE ref_origtime >= '$tmstp';");
#    my @tmp = ($cgcs, $pmids);
    for (@tmp){
	print "TEMP: $_\n";
	my @row = ();
	while (@row = $_->fetchrow) {
	    print "ROW1: $row[0]\n";
	    if ($row[0]) {
		$print = ""; 
		$i++;
		$row[0] =~ s///g;
		$row[0] =~ s/\s+//g;

		print "ROW: $row[0]\n";
		&getRef($row[0]);
		$print .= $o;
	    } # if ($row[0])
	} # while (@row = $result->fetchrow)
    }
}

sub getRecentUpdates{
    my ($tmstp, $exl) = @_;
#    print "TIMESTAMP: $tmstp\n";
#    for (keys %$exl) {print "OUT: $_\n"}

#    my @fields = qw(title author journal volume pages year abstract genes);
    my @fields = qw(abstract);
    foreach my $field (@fields) {
	$field = 'ref_' . $field;
	my $cgcs = $conn->exec( "SELECT * FROM $field WHERE ref_timestamp >= '$tmstp';");
#	my $pmids = $conn->exec( "SELECT * FROM $field WHERE ref_timestamp >= '$tmstp';");
#	my @tmp = ($cgcs, $pmids);
#	for (@tmp){
	    my @row = ();
#	    while (@row = $_->fetchrow) {
	    while (@row = $cgcs->fetchrow) {
		if ($row[0]) {
		    $print = ""; 
#		    $i++;
		    $row[0] =~ s///g;
		    $row[0] =~ s/\s+//g;
		    
#		    print "$row[0]\n";
		    unless (exists $$exl{$row[0]}){print "$row[0]\n"; $j++;}
#		    print "UPDATE ROW:$row[0]\n";
#		    &getRef($row[0]);
#		    $print .= $o;
		} # if ($row[0])
	    } # while (@row = $result->fetchrow)
    }
}


#sub getFields{
#    @fields = qw(title author journal volume pages year abstract genes);
#    foreach my $field (@fields) {
#	$field = 'ref_' . $field;
#    }
    
#}
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


sub getDate{
    my $time_zone = 0;
    my $time = time() + ($time_zone * 3600);
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time);
    $year += ($year < 90) ? 2000 : 1900;
    $dateShort = sprintf("%04d-%02d-%02d",$year,$mon+1,$mday);
    print "$dateShort\n";
    return $dateShort;
}
