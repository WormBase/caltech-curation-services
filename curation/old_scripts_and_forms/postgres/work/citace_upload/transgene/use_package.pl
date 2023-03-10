#!/usr/bin/perl

# use the get_paper_ace.pm module from /home/postgres/work/citace_upload/papers/ 
# to dump the papers, abstracts (LongText objects), and errors associated with
# them.  2005 07 13
#
# Changed for transgenes  2012 06 22

use strict;
use Jex;

my $date = &getSimpleSecDate();
my $start_time = time;
my $estimate_time = time + 7;
my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime($estimate_time);             # get time
if ($sec < 10) { $sec = "0$sec"; }    # add a zero if needed
print "START $date -> Estimate $hour:$min:$sec\n";

$date = &getSimpleDate();

use lib qw( /home/postgres/work/citace_upload/transgene );
use get_transgene_ace;

my $outfile = 'transgene.ace.' . $date;
my $outfile2 = 'transgene.ace';
my $errfile = 'err.out.' . $date;

open (OUT, ">$outfile") or die "Cannot create $outfile : $!\n";
open (OU2, ">$outfile2") or die "Cannot create $outfile2 : $!\n";
open (ERR, ">$errfile") or die "Cannot create $errfile : $!\n";


my ($all_entry, $err_text) = &getTransgene('all');

# my ($all_entry, $err_text) = &getTransgene('Expr631');
# my ($all_entry, $err_text) = &getTransgene('Expr1041');
# my ($all_entry, $err_text) = &getTransgene('Expr1087');

print OUT "$all_entry\n";
print OU2 "$all_entry\n";
if ($err_text) { print ERR "$err_text\n"; }

close (OUT) or die "Cannot close $outfile : $!";
close (OU2) or die "Cannot close $outfile2 : $!";
close (ERR) or die "Cannot close $errfile : $!";

$date = &getSimpleSecDate();
my $end_time = time;
my $diff_time = $end_time - $start_time;
print "DIFF $diff_time\n";
print "END $date\n";

