#!/bin/env perl
# $Id: osp1.pl,v 1.4 1997-08-09 01:37:41 mieg Exp $
# osp1.pl
# written by John Barnett, Oct 96

#ENVIRONMENT

$osp = "osp";           # FULL PATH TO osp executable

# call osp to find all suitable oligos in a given sequence
#### for now, assume that the sequence is short enough not to crash osp
# now assume that it is long and needs to be split

$splitLength = 1000;
# assume for now that lines are at least as long as the required overlap

$tab = +{'T' => +{}, 'B' => +{}};

# the coordinates in the output are in the same system as those in
# the header of the sequence input  -- unless -r was used

use Getopt::Std;

# binary to use
# assume in path


# get command line arguments
&getopts('s:m:p:l:t:T:');
unless ($opt_s) {
    # must have sequence argument
    print "Usage:  osp1.pl -s <sequence file> \n\t[-p <paramater file>] [-m <max score>]\n\t[-l <min>,<max primer length>]\n";
    exit 1;
}
($primerMin, $primerMax) = (18,22);
if ($opt_l) {
    ($primerMin, $primerMax) = split (/,/ , $opt_l);
    unless ($primerMin && $primerMax && ($primerMin < $primerMax)) {
	print "set primer length using:  -l <min>,<max>\n";
	exit 1;
    }
}

$oligoTm = $opt_t ? $opt_t : 53 ;
$oligoTmMax = $opt_T ? $opt_T : 55 ;

$tmp_seq = "/tmp/OSP.$$.seq";


# get sequence name and length
open (SEQ, $opt_s);
open (TMPSEQ, ">$tmp_seq");
$begin = 1;

# hope that the split doesn't come at EOF

while ($line = <SEQ>) {
    next if /^\>/;
    $lineLength = ($line =~ tr/AGCTagct/AGCTAGCT/);
    $length += $lineLength;
    print TMPSEQ $line;
    if ($length >= $splitLength) {
	# need to accumulate the overlap
	$tmpLine .= $line;
	$tmpLength += $lineLength;
	if ($tmpLength >= $primerMax) {
	    close TMPSEQ;

	    &callOSP1($tmp_seq, "T", $opt_p, $opt_m, $begin, $length, $primerMin, $primerMax, $oligoTm); # top strand
	    &callOSP1($tmp_seq, "B", $opt_p, $opt_m, $begin, $length, $primerMin, $primerMax, $oligoTm); # bottom strand
	    
	    unlink $tmp_seq;
	    open (TMPSEQ, ">$tmp_seq");
	    print TMPSEQ $tmpLine;
	    $begin += $length - $tmpLength;
	    $length = $tmpLength;
	    $tmpLength = 0; $tmpLine = "";
	}
    }
}
# one more time, to get everything to EOF
close TMPSEQ;

&callOSP1($tmp_seq, "T", $opt_p, $opt_m, $begin, $length, $primerMin, $primerMax, $oligoTm); # top strand
&callOSP1($tmp_seq, "B", $opt_p, $opt_m, $begin, $length, $primerMin, $primerMax, $oligoTm); # bottom strand

unlink $tmp_seq;

# print results
print "// top strand\n";
foreach $thing (values %{$tab->{'T'}}) {
    print $thing;
}
print "// bottom strand\n";
foreach $thing (values %{$tab->{'B'}}) {
    print $thing;
}

sub callOSP1 {
    my ($seq, $orientation, $params, $maxScore, $begin, $length, $primerMin, $primerMax, $oligoTm) = @_;
    
    $debug = 0 ;
# osp input & output files file
    $ospin = "/tmp/OSP.$$.in";
    $ospout = "/tmp/OSP.$$.out";
    
# to avoid a double pipe, set up a list of commands to send osp
    open (OSPIN, ">$ospin");
    print OSPIN "3\n"; #  (3) Search for a SINGLE primer in one sequence
    print OSPIN "$seq\n"; # Sequence filename
    print OSPIN "$orientation\n";
    if ($param && -f $param) { # parameter file supplied
	print OSPIN "R\n";
	print OSPIN "$param\n";
    } elsif ($length || $primerMin) {
	print OSPIN "C\n"; #  C -- Change specific primer/product constraints
	if ($length) {
	    print OSPIN "PROD_LEN_MIN 1\n";
	    print OSPIN "PROD_LEN_MAX $length\n";
	}
	if ($primerMin) {
	    print OSPIN "PRIM_LEN_MIN $primerMin\n";
	    print OSPIN "PRIM_LEN_MAX $primerMax\n";
	}
	if ($oligoTm) {
	    print OSPIN "PRIM_TM_MIN $oligoTm\n";
	    print OSPIN "PRIM_TM_MAX $oligoTmMax\n";
	    print OSPIN "PRIM_GC_MIN 0\n";
	    print OSPIN "PRIM_GC_MAX 0\n";
	}
	print OSPIN "*\n"; # to end
    } else {
	print OSPIN "U\n";
    }
    print OSPIN "1\n"; # Starting nucleotide?
    print OSPIN "0\n"; # Ending nucleotide
    print OSPIN "$ospout\n"; # Output filename?
    print OSPIN "1000\n"; # number of oligos to output -- this is the max OSP will find
    close OSPIN;
    
# start osp
    open (OSP, "$osp <$ospin |");
    while (<OSP>) {  if ($debug==2) { print $_  ;} # show interactions 
                  }  # swallow OSP interaction
# potentially, OSP output could be interpreted here
    close OSP;
    
# now process the output file
    open (OSPOUT, "$ospout");
    while (<OSPOUT>) {last if /Number accepted\:/;} # discard header
    $junk = <OSPOUT>; $junk = <OSPOUT>; # throw out additional two lines of junk
    
    while (<OSPOUT>) {
	if (/^Primer \#\s*(\d+).*OLIGO\:\s(\S+)\s*$/) {
	    $i = $1;
	    $oligo[$i] = $2;
	} elsif (/ 5\' end 3\' end/) {
	    # column headings; grab the next line
	    $_ = <OSPOUT>;
	s/^\s*//; # get rid of leading whitespace
	    @line = split(/\s+/, $_);
	    if ($orientation =~ /t/i) {
		$left[$i] = $line[0] + $begin-1;
		$right[$i]= $line[1] + $begin-1;
	    } else {
		$left[$i] = $begin + $length - $line[0];
		$right[$i]= $begin + $length - $line[1];
	    }
	    $len[$i] =  $line[2];
	    $gc[$i] = $line[3];
	    $tm[$i] = $line[4];
	} elsif (/Total Score\:\s*([0-9\.]+)/) {
	    $score[$i] = $1;
	}
    }
    
# summarize the output
    for ($i=1; $i<@oligo; $i++) {
	next if $maxScore && $score[$i] > $maxScore;
	$tab->{$orientation}->{"$left[$i]:$right[$i]"} = 
	    "$oligo[$i] $left[$i] $right[$i] $len[$i] $gc[$i] $tm[$i] $score[$i]\n";
    }
    
    unlink $ospin;
    unlink $ospout;

}
