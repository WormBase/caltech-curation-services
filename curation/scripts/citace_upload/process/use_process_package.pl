#!/usr/bin/env perl

# use the get_process_ace.pm module from /home/postgres/work/citace_upload/process/ 
# to dump the process terms.  2012 07 17


use strict;
use Jex;

my $date = &getSimpleSecDate();
my $start_time = time;
my $estimate_time = time + 697;
my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime($estimate_time);             # get time
if ($sec < 10) { $sec = "0$sec"; }    # add a zero if needed
print "START $date -> Estimate $hour:$min:$sec\n";

$date = &getSimpleDate();

use lib qw( /usr/lib/scripts/citace_upload/process/ );
# use lib qw( /home/postgres/work/citace_upload/process/ );
# use get_allele_phenotype_ace;
use get_process_ace;

my $outfile = 'process.ace.' . $date;
# my $molfile = 'mol_phene.ace.' . $date;
# my $outlong = 'abstracts.ace.' . $date;
my $errfile = 'err_process.out.' . $date;
open (OUT, ">$outfile") or die "Cannot create $outfile : $!\n";
# open (MOL, ">$molfile") or die "Cannot create $molfile : $!\n";
# open (LON, ">$outlong") or die "Cannot create $outlong : $!\n";
open (ERR, ">$errfile") or die "Cannot create $errfile : $!\n";


# my ($all_entry, $long_text, $err_text) = &getPaper('00000003');
# my ($all_entry, $long_text, $err_text) = &getPaper('valid');
# my ($all_entry, $mol_entry, $err_text) = &getAllelePhenotype('all');
my ($all_entry, $err_text) = &getProcess('all');

# my ($all_entry, $long_text, $err_text) = &getAllelePhenotype('bx123');
# my ($all_entry, $long_text, $err_text) = &getAllelePhenotype('tm1821');

print OUT "$all_entry\n";
# print MOL "$mol_entry\n";
# print LON "$long_text\n";
if ($err_text) { print ERR "$err_text\n"; }

close (OUT) or die "Cannot close $outfile : $!";
# close (MOL) or die "Cannot close $molfile : $!";
# close (LON) or die "Cannot close $outlong : $!";
close (ERR) or die "Cannot close $errfile : $!";

$date = &getSimpleSecDate();
my $end_time = time;
my $diff_time = $end_time - $start_time;
print "DIFF $diff_time\n";
print "END $date\n";

