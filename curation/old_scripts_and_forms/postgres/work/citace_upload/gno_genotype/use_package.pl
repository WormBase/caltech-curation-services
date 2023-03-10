#!/usr/bin/perl


use strict;
use Jex;

my $date = &getSimpleSecDate();
my $start_time = time;
my $estimate_time = time + 697;
my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime($estimate_time);             # get time
if ($sec < 10) { $sec = "0$sec"; }    # add a zero if needed
# print "START $date -> Estimate $hour:$min:$sec\n";

$date = &getSimpleDate();

use lib qw( /home/postgres/work/citace_upload/gno_genotype/ );
# use get_allele_phenotype_ace;
use get_genotype_ace;

my $outfile = 'genotype.ace.' . $date;
my $errfile = 'err.out.' . $date;

open (OUT, ">$outfile") or die "Cannot create $outfile : $!\n";
open (ERR, ">$errfile") or die "Cannot create $errfile : $!\n";


my ($all_entry, $err_text) = &getGenotype('all');

# my ($all_entry, $err_text) = &getGenotype('WBGenotype00000001');

print OUT "$all_entry\n";
if ($err_text) { print ERR "$err_text"; }

close (OUT) or die "Cannot close $outfile : $!";
close (ERR) or die "Cannot close $errfile : $!";

$date = &getSimpleSecDate();
my $end_time = time;
my $diff_time = $end_time - $start_time;
# print "DIFF $diff_time\n";
# print "END $date\n";

