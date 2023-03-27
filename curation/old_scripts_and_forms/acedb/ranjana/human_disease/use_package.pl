#!/usr/bin/perl

# use the get_paper_ace.pm module from /home/postgres/work/citace_upload/papers/ 
# to dump the papers, abstracts (LongText objects), and errors associated with
# them.  2005 07 13
#
# Change to default get all human disease genes.  2013 01 18

use strict;
use Jex;

my $date = &getSimpleSecDate();
my $start_time = time;
my $estimate_time = time + 697;
my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime($estimate_time);             # get time
if ($sec < 10) { $sec = "0$sec"; }    # add a zero if needed
print "START $date -> Estimate $hour:$min:$sec\n";

$date = &getSimpleDate();

use lib qw( /home/postgres/work/citace_upload/dis_disease/ );
use get_dis_disease_ace;
use get_dis_disease_ace_annotation;

my $outfile = 'disease_' . $date . '.ace';
my $errfile = 'err.out.' . $date;

open (OUT, ">$outfile") or die "Cannot create $outfile : $!\n";
open (ERR, ">$errfile") or die "Cannot create $errfile : $!\n";

my ($all_entry, $err_text) = &getDisease('all');
# my ($all_entry, $err_text) = &getDisease('WBGene00000846');

print OUT "$all_entry\n";
if ($err_text) { print ERR "$err_text"; }

close (OUT) or die "Cannot close $outfile : $!";
close (ERR) or die "Cannot close $errfile : $!";


my $dotfile = 'doterm_associations_' . $date . '.ace';
$outfile = 'disease_annotation_' . $date . '.ace';
$errfile = 'err_annotation.out.' . $date;

open (OUT, ">$outfile") or die "Cannot create $outfile : $!\n";
open (DOT, ">$dotfile") or die "Cannot create $dotfile : $!\n";
open (ERR, ">$errfile") or die "Cannot create $errfile : $!\n";

($all_entry, my $dot_entry, $err_text) = &getDiseaseAnnotation('all');

print OUT "$all_entry\n";
print DOT "$dot_entry\n";
if ($err_text) { print ERR "$err_text"; }

close (OUT) or die "Cannot close $outfile : $!";
close (DOT) or die "Cannot close $dotfile : $!";
close (ERR) or die "Cannot close $errfile : $!";

$date = &getSimpleSecDate();
my $end_time = time;
my $diff_time = $end_time - $start_time;
print "DIFF $diff_time\n";
print "END $date\n";

