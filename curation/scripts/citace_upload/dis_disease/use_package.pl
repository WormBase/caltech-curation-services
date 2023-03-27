#!/usr/bin/env perl

# use the get_paper_ace.pm module from /home/postgres/work/citace_upload/papers/ 
# to dump the papers, abstracts (LongText objects), and errors associated with
# them.  2005 07 13
#
# Change to default get all human disease genes.  2013 01 18
#
# Generate latest file in local directory and with .<date> in files/ foler.  2023 03 27


use strict;
use Jex;

my $date = &getSimpleSecDate();
my $start_time = time;
my $estimate_time = time + 697;
my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime($estimate_time);             # get time
if ($sec < 10) { $sec = "0$sec"; }    # add a zero if needed
print "START $date -> Estimate $hour:$min:$sec\n";

$date = &getSimpleDate();

use lib qw( /usr/lib/scripts/citace_upload/dis_disease/ );
# use lib qw( /home/postgres/work/citace_upload/dis_disease/ );
use get_dis_disease_ace;
use get_dis_disease_ace_annotation;

my $outfile = 'disease.ace';
my $errfile = 'err.out';
my $outfile2 = 'files/disease_' . $date . '.ace';
my $errfile2 = 'files/err.out.' . $date;

open (OUT, ">$outfile") or die "Cannot create $outfile : $!\n";
open (ERR, ">$errfile") or die "Cannot create $errfile : $!\n";
open (OU2, ">$outfile2") or die "Cannot create $outfile2 : $!\n";
open (ER2, ">$errfile2") or die "Cannot create $errfile2 : $!\n";

my ($all_entry, $err_text) = &getDisease('all');
# my ($all_entry, $err_text) = &getDisease('WBGene00000846');

print OUT "$all_entry\n";
print OU2 "$all_entry\n";
if ($err_text) { 
  print ER2 "$err_text";
  print ERR "$err_text"; }

close (OUT) or die "Cannot close $outfile : $!";
close (ERR) or die "Cannot close $errfile : $!";
close (OU2) or die "Cannot close $outfile2 : $!";
close (ER2) or die "Cannot close $errfile2 : $!";


my $dotfile = 'doterm_associations.ace';
$outfile = 'disease_annotation.ace';
$errfile = 'err_annotation.out';
my $dotfile2 = 'files/doterm_associations_' . $date . '.ace';
$outfile2 = 'files/disease_annotation_' . $date . '.ace';
$errfile2 = 'files/err_annotation.out.' . $date;

open (OUT, ">$outfile") or die "Cannot create $outfile : $!\n";
open (DOT, ">$dotfile") or die "Cannot create $dotfile : $!\n";
open (ERR, ">$errfile") or die "Cannot create $errfile : $!\n";
open (OU2, ">$outfile2") or die "Cannot create $outfile2 : $!\n";
open (DO2, ">$dotfile2") or die "Cannot create $dotfile2 : $!\n";
open (ER2, ">$errfile2") or die "Cannot create $errfile2 : $!\n";

($all_entry, my $dot_entry, $err_text) = &getDiseaseAnnotation('all');

print OUT "$all_entry\n";
print DOT "$dot_entry\n";
print OU2 "$all_entry\n";
print DO2 "$dot_entry\n";
if ($err_text) { 
  print ERR "$err_text";
  print ER2 "$err_text"; }

close (OUT) or die "Cannot close $outfile : $!";
close (DOT) or die "Cannot close $dotfile : $!";
close (ERR) or die "Cannot close $errfile : $!";
close (OU2) or die "Cannot close $outfile2 : $!";
close (DO2) or die "Cannot close $dotfile2 : $!";
close (ER2) or die "Cannot close $errfile2 : $!";

$date = &getSimpleSecDate();
my $end_time = time;
my $diff_time = $end_time - $start_time;
print "DIFF $diff_time\n";
print "END $date\n";

