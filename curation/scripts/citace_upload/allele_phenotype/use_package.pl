#!/usr/bin/env perl

# use the get_paper_ace.pm module from /home/postgres/work/citace_upload/papers/ 
# to dump the papers, abstracts (LongText objects), and errors associated with
# them.  2005 07 13
#
# Change to default get all papers, not just valid ones.  2005 11 10
#
# Dockerized cronjob. Output to /usr/caltech_curation_files/pub/citace_upload/karen/  2023 03 14
#
# cronjob
# 0 4 * * sun /usr/lib/scripts/citace_upload/allele_phenotype/use_package.pl

use strict;
use Jex;

my $date = &getSimpleSecDate();
my $start_time = time;
my $estimate_time = time + 697;
my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime($estimate_time);             # get time
if ($sec < 10) { $sec = "0$sec"; }    # add a zero if needed
print "START $date -> Estimate $hour:$min:$sec\n";

$date = &getSimpleDate();

use lib qw( /usr/lib/scripts/citace_upload/allele_phenotype/ );
# use lib qw( /home/postgres/work/citace_upload/allele_phenotype/ );
# use get_allele_phenotype_ace;
use get_allele_phenotype_phenote_ace;

my $outDir = $ENV{CALTECH_CURATION_FILES_INTERNAL_PATH} . "/pub/citace_upload/karen/";
my $outfile = $outDir . 'allele_phenotype.ace';
my $molfile = $outDir . 'mol_phene.ace';
# my $outfile = $outDir . 'allele_phenotype.ace.' . $date;
# my $molfile = $outDir . 'mol_phene.ace.' . $date;
# my $outlong = $outDir . 'abstracts.ace.' . $date;
my $errfile = 'err.out';
# my $errfile = 'err.out.' . $date;
open (OUT, ">$outfile") or die "Cannot create $outfile : $!\n";
open (MOL, ">$molfile") or die "Cannot create $molfile : $!\n";
# open (LON, ">$outlong") or die "Cannot create $outlong : $!\n";
open (ERR, ">$errfile") or die "Cannot create $errfile : $!\n";


# my ($all_entry, $long_text, $err_text) = &getPaper('00000003');
# my ($all_entry, $long_text, $err_text) = &getPaper('valid');
# my ($all_entry, $mol_entry, $err_text) = &getAllelePhenotype('WBVar00604179');
my ($all_entry, $mol_entry, $err_text) = &getAllelePhenotype('all');

# my ($all_entry, $long_text, $err_text) = &getAllelePhenotype('bx123');
# my ($all_entry, $long_text, $err_text) = &getAllelePhenotype('tm1821');

print OUT "$all_entry\n";
print MOL "$mol_entry\n";
# print LON "$long_text\n";
if ($err_text) { print ERR "$err_text\n"; }

close (OUT) or die "Cannot close $outfile : $!";
close (MOL) or die "Cannot close $molfile : $!";
# close (LON) or die "Cannot close $outlong : $!";
close (ERR) or die "Cannot close $errfile : $!";

$date = &getSimpleSecDate();
my $end_time = time;
my $diff_time = $end_time - $start_time;
print "DIFF $diff_time\n";
print "END $date\n";

