#!/usr/bin/perl

# use the get_antibody_ace.pm module from /home/postgres/work/citace_upload/antibody/ 
# to dump the papers, abstracts (LongText objects), and errors associated with
# them.  2012 05 31


use strict;
use Jex;

my $date = &getSimpleSecDate();
my $start_time = time;
my $estimate_time = time + 697;
my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime($estimate_time);             # get time
if ($sec < 10) { $sec = "0$sec"; }    # add a zero if needed
print "START $date -> Estimate $hour:$min:$sec\n";

$date = &getSimpleDate();

use lib qw( /home/postgres/work/citace_upload/antibody/ );
# use get_allele_phenotype_ace;
use get_antibody_ace;

my $outfile = 'antibody.ace.' . $date;
my $errfile = 'err.out.' . $date;

open (OUT, ">$outfile") or die "Cannot create $outfile : $!\n";
open (ERR, ">$errfile") or die "Cannot create $errfile : $!\n";


my ($all_entry, $err_text) = &getAntibody('all');

# my ($all_entry, $err_text) = &getAntibody('[cgc512]:MSP');

print OUT "$all_entry\n";
if ($err_text) { print ERR "$err_text"; }

close (OUT) or die "Cannot close $outfile : $!";
close (ERR) or die "Cannot close $errfile : $!";

$date = &getSimpleSecDate();
my $end_time = time;
my $diff_time = $end_time - $start_time;
print "DIFF $diff_time\n";
print "END $date\n";

