#!/usr/bin/env perl


use strict;
use Jex;

my $date = &getSimpleSecDate();
my $start_time = time;
my $estimate_time = time + 697;
my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime($estimate_time);             # get time
if ($sec < 10) { $sec = "0$sec"; }    # add a zero if needed
# print "START $date -> Estimate $hour:$min:$sec\n";

$date = &getSimpleDate();

use lib qw( /usr/lib/scripts/citace_upload/gno_genotype/ );
# use lib qw( /home/postgres/work/citace_upload/gno_genotype/ );
# use get_allele_phenotype_ace;
use get_genotype_ace;

my $outfile = 'files/genotype.ace.' . $date;
my $errfile = 'files/err.out.' . $date;
my $outfile2 = 'genotype.ace';
my $errfile2 = 'err.out';

open (OUT, ">$outfile") or die "Cannot create $outfile : $!\n";
open (ERR, ">$errfile") or die "Cannot create $errfile : $!\n";
open (OU2, ">$outfile2") or die "Cannot create $outfile2 : $!\n";
open (ER2, ">$errfile2") or die "Cannot create $errfile2 : $!\n";


my ($all_entry, $err_text) = &getGenotype('all');

# my ($all_entry, $err_text) = &getGenotype('WBGenotype00000001');

print OUT "$all_entry\n";
print OU2 "$all_entry\n";
if ($err_text) { 
  print ERR "$err_text";
  print ER2 "$err_text"; }

close (OUT) or die "Cannot close $outfile : $!";
close (ERR) or die "Cannot close $errfile : $!";
close (OU2) or die "Cannot close $outfile : $!";
close (ER2) or die "Cannot close $errfile : $!";

$date = &getSimpleSecDate();
my $end_time = time;
my $diff_time = $end_time - $start_time;
# print "DIFF $diff_time\n";
# print "END $date\n";

