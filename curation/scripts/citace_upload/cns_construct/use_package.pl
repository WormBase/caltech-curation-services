#!/usr/bin/env perl

# use the get_paper_ace.pm module from /home/postgres/work/citace_upload/papers/ 
# to dump the papers, abstracts (LongText objects), and errors associated with
# them.  2005 07 13
#
# Change to default get all papers, not just valid ones.  2005 11 10
#
# Output to files/ folder to cleanup files older than 2 years.  2023 04 06

use strict;
use Jex;

my $date = &getSimpleSecDate();
my $start_time = time;
my $estimate_time = time + 697;
my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime($estimate_time);             # get time
if ($sec < 10) { $sec = "0$sec"; }    # add a zero if needed
# print "START $date -> Estimate $hour:$min:$sec\n";

$date = &getSimpleDate();

use lib qw( /usr/lib/scripts/citace_upload/cns_construct/ );
# use lib qw( /home/postgres/work/citace_upload/cns_construct/ );
# use get_allele_phenotype_ace;
use get_construct_ace;

# my $outfile = 'files/construct.ace.' . $date;
# my $errfile = 'files/err.out.' . $date;
my $outfile = 'construct.ace';
my $errfile = 'err.out';

open (OUT, ">$outfile") or die "Cannot create $outfile : $!\n";
open (ERR, ">$errfile") or die "Cannot create $errfile : $!\n";


my ($all_entry, $err_text) = &getConstruct('all');

# my ($all_entry, $err_text) = &getConstruct('WBCnstr00000053');

print OUT "$all_entry\n";
if ($err_text) { print ERR "$err_text"; }

close (OUT) or die "Cannot close $outfile : $!";
close (ERR) or die "Cannot close $errfile : $!";

$date = &getSimpleSecDate();
my $end_time = time;
my $diff_time = $end_time - $start_time;
# print "DIFF $diff_time\n";
# print "END $date\n";

