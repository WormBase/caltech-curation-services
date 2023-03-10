#!/usr/bin/perl -w
#
# usage: ./get_ref_info.pl <paper_list> <outfile>
#

use strict;
use diagnostics;
use Pg;

###GLOBALS
my $papers = $ARGV[0];
my $outfile = $ARGV[1];
my $i = 0;
my $o;
my $print;
my %Papers;


###MAIN

print "Opening PostGres database ....";
my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;
print "done!\n";

&readPapers($papers);
&getRecentPapers(\%Papers);
&printInfo($print, $outfile);
print "\n$outfile contains reference information for $i papers\n";

###SUBROUTINES
sub getRecentPapers{
    my ($pap) = @_;

    my %pmids;
    for (keys %$pap){
	print "Getting reference info for $_ .....";
	my @tmp = $conn->exec( "SELECT * FROM ref_origtime WHERE joinkey='$_';");
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
		    print "done\n";
		}
	    }
	}
    }
    return $print;
}

sub readPapers{
    my $l = shift;
    
    open (IN, "$l") 
	or die "Can't open $l: $!";
    undef $/;
    my $w= <IN>;
    close (IN) 
	or die "Cannot close $l: $!";
    $/ = "\n";
    my @lines = split/\n/, $w;

    for (@lines){$Papers{$_}++}
    
    return %Papers;
}

sub printInfo{
    my ($p, $o) = @_;

    print "Printing outfile ... ";
    open(OUT, ">$o") 
	or die "Can't open $o: $!";
    print OUT "$p";
    close(OUT)
	or die "Can't close $o: $!";
    print "done\n";
}

sub getRef {
    my $pap = shift;

    my @fields = qw(title author journal volume pages year abstract);
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
	    }
	}
	$o .= "\t$out";
    }
    $o .= "\n";
    return $o;
}


