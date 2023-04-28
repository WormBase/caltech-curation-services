#!/usr/bin/env perl

# use the get_paper_ace.pm module from /home/postgres/work/citace_upload/papers/ 
# to dump the papers, abstracts (LongText objects), and errors associated with
# them.  2005 07 13
#
# Change to default get all papers, not just valid ones.  2005 11 10

use strict;
use Jex;

my $date = &getSimpleSecDate();
my $start_time = time;
my $estimate_time = time + 18;
my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime($estimate_time);             # get time
if ($sec < 10) { $sec = "0$sec"; }    # add a zero if needed
print "START $date -> Estimate $hour:$min:$sec\n";

$date = &getSimpleDate();

use lib qw( /usr/lib/scripts/citace_upload/rnai/ );
# use lib qw( /home/postgres/work/citace_upload/rnai/ );
use get_rnai_ace;

my $outfile = 'files/rnai.ace.' . $date;
my $errfile = 'files/err.out.' . $date;

open (OUT, ">$outfile") or die "Cannot create $outfile : $!\n";
open (ERR, ">$errfile") or die "Cannot create $errfile : $!\n";

binmode OUT, ':utf8';

my ($all_entry, $err_text) = &getRnai('all');

# my ($all_entry, $err_text) = &getRnai('WBRNAi00008227');

print OUT "$all_entry\n";
if ($err_text) { print ERR "$err_text\n"; }

close (OUT) or die "Cannot close $outfile : $!";
close (ERR) or die "Cannot close $errfile : $!";

$date = &getSimpleSecDate();
my $end_time = time;
my $diff_time = $end_time - $start_time;
print "DIFF $diff_time\n";
print "END $date\n";

