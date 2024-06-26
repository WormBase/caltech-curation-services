#!/usr/bin/env perl

# use the get_movie_ace.pm module from /home/postgres/work/citace_upload/movie/ 
# to dump the movie objects.  2012 10 15
#
# added database for Daniela.  2013 10 10



use strict;
use Jex;

my $date = &getSimpleSecDate();
my $start_time = time;
my $estimate_time = time + 697;
my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime($estimate_time);             # get time
if ($sec < 10) { $sec = "0$sec"; }    # add a zero if needed
print "START $date -> Estimate $hour:$min:$sec\n";

$date = &getSimpleDate();

use lib qw( /usr/lib/scripts/citace_upload/movie/ );
# use lib qw( /home/postgres/work/citace_upload/movie/ );
# use get_allele_phenotype_ace;
use get_movie_ace;

my $outfile = 'files/movie.ace.' . $date;
my $errfile = 'files/err_movie.out.' . $date;
open (OUT, ">$outfile") or die "Cannot create $outfile : $!\n";
open (ERR, ">$errfile") or die "Cannot create $errfile : $!\n";

my ($all_entry, $err_text) = &getMovie('all');
# my ($all_entry, $err_text) = &getMovie('WBMovie0000000001');

print OUT "$all_entry\n";
if ($err_text) { print ERR "$err_text\n"; }

close (OUT) or die "Cannot close $outfile : $!";
close (ERR) or die "Cannot close $errfile : $!";

$date = &getSimpleSecDate();
my $end_time = time;
my $diff_time = $end_time - $start_time;
print "DIFF $diff_time\n";
print "END $date\n";

