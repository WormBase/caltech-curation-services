#!/bin/env perl
# $Id: osp2.pl,v 1.6 1997-08-09 01:44:38 mieg Exp $
# osp2.pl
# takes output from osp1- calls osp testing each pair of oligos
#  ex: osp2.pl -s /var/tmp/z1 -g /var/tmp/z2


use Getopt::Std;

#ENVIRONMENT

$osp = "osp";           # FULL PATH TO osp executable

$debug = 0 ;  # 0: run mode,  1: shell debug mode, incompatible with acedb


&getopts("s:g:l:L:");
$seq = $opt_s || die "usage: osp2.pl -s <sequence file>  -g <oligo file> 
                 -l <min_product_length>  -L<max_product_length>\n" ;
$olg = $opt_g || die "usage: osp2.pl -s <sequence file> -g <oligo file> 
                 -l <min_product_length> -L<max_product_length>\n" ;

$name = $opt_n || $$;
$opt_l =  $opt_l || 1000 ;
$opt_L =  $opt_L || 1500 ;

if ($debug==1) { print "starting l= $opt_l olg= $olg\n" ; }

open (SEQ, $seq)|| die "cannot open $seq" ;
$_ = <SEQ>;
if (/^\>(\S+)/) {
    $seqName = $1;
}
close SEQ;

open (OLG, $olg) || die "cannot open $olg" ;

$_ = <OLG>;
while (<OLG>) 
{
    if (/^\/\/ top strand/) { 
	if ($debug==1) { print "got top strand\n";}
	next;
    } elsif (/^\/\/ bottom strand/) {
	if ($debug==1) { print "got bottom strand\n"; }
	# everything that follows is on the other strand
	$firstBottom = $i;
    } else {
	($oligo, $start, $end) = split;
	next unless $oligo;
	push(@oligo, $oligo);
	push(@start, $start);
	push(@end, $end);
	$i++;
    }
}
close OLG ;
# print "got %doligos\n", $i;

# create 2-d array
# and fill with scores from tests
for ($i=0; $i<$firstBottom; $i++) {
    $tab[$i] = [];
    for ($j=$firstBottom; $j<@oligo; $j++) {  
	$dx =  $end[$j] - $start[$i] ;
	if ($debug==1) { print ("$opt_l <? $start[$i] - $end[$j] = $dx  <? $opt_L  \n") ; }
	next if $dx  < $opt_l || $dx > $opt_L ;
	if ($debug==1) { print ("******* call OSP2\n") ; }
	($length, $gc, $tm, $score) = &callOSP2($seq,
						$start[$i], 
						$end[$i],
						$start[$j],
						$end[$j]);
	$tab[$i]->[$j] = [$length, $gc, $tm, $score];
	$tab[$j] = [] unless $tab[$j];
	$tab[$j]->[$i] = [$length, $gc, $tm, $score];
    }
}

# ace file output
for ($i=0; $i<@oligo; $i++) 
{   $first = 1 ;
    # print "Oligo  $oligo[$i]\n";
    if ($tab[$i]) {
	for ($j=$firstBottom; $j<@oligo; $j++) {
	    if ($tab[$i]->[$j]) {
		my ($length, $gc, $tm, $score) = @{$tab[$i]->[$j]};
		if ($first == 1) { $first = 0 ; print "Oligo  $oligo[$i]\n";}
		print "Pairwise_scores $oligo[$j] $score $tm \n";
	    }
	}
    }
    print "\n";
}
	


sub callOSP2 {
    my ($seq, $left1, $right1, $left2, $right2) = @_;

# osp input & output files file
    $ospin = "/tmp/OSP.$$.in";
    $ospout = "/tmp/OSP.$$.out";
    
    if ($debug==2) { print "&&&&&&&&&& Calls $osp  $left1 $right1 $left2 $right2\n" ; }
# to avoid a double pipe, set up a list of commands to send osp
    open (OSPIN, ">$ospin");
    print OSPIN "2\n"; #  (2) Output SCORES for two specific primers which you supply
    print OSPIN "1\n"; # (1) Enter the name of ONE SEQUENCE FILE and a starting and ending point
    print OSPIN "$seq\n"; # Sequence file:
    print OSPIN "T\n";  #  T -- Top strand orientation
    print OSPIN "$left1\n";  # STARTING nucleotide of FIRST REGION?
    print OSPIN "$right1\n"; # ENDING nucleotide
    print OSPIN "$left2\n"; # STARTING nucleotide of SECOND REGION?
    print OSPIN "$right2\n"; # ENDING nucleotide
    print OSPIN "y\n"; # Would you like to output this information to a file?
    print OSPIN "$ospout\n"; # Output filename?
    print OSPIN "a\n"; # overwrite existing file, if needed
    close OSPIN;

# start osp

    open (OSP, "$osp <$ospin |");
    while (<OSP>) {  if ($debug==2) { print $_  ;} # show interactions 
                  }  # swallow OSP interaction
# potentially, OSP output could be interpreted here
    close OSP;
    
# now process the output file
    open (OSPOUT, "$ospout");
    while (<OSPOUT>) {last if /Length  G\+C\(\%\)/;}
    # only the last line is used now
    $_ = <OSPOUT>;
    close OSPOUT;

    $_ =~ s/^\s*//;

    my ($length, $gc, $tm, $score) = split(/\s+/, $_);

    unlink $ospin;
    unlink $ospout;

    return ($length, $gc, $tm, $score);
}
	
