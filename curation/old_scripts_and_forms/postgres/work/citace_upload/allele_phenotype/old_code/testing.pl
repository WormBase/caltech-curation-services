#!/usr/bin/perl

# Dump allele phenotype data.

# Dump concise description data to old/concise_dump.date.hour.ace
# and symlink to /home/postgres/public_html/cgi-bin/data/concise_dump_new.ace
# for cronjob for Erich.
# 0 2 * * wed /home/postgres/work/citace_upload/concise/wrapper.pl
# Matches script on altair at /home/citace/cronjobs/copyConciseAndGOTerms.pl
# 2005 09 15

# Adapted for allele-phenotype data.  2005 12 16


use Jex;
use lib qw( /home/postgres/work/citace_upload/allele_phenotype/ );
use get_allele_phenotype_ace;


my $date = &getSimpleSecDate();

my $directory = '/home/postgres/work/citace_upload/allele_phenotype';
my $outfile = $directory . '/allele_phenotype.' . $date . '.ace';

chdir($directory) or die "Cannot go to $directory ($!)";

open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
# my ($all_entry, $err_text) = &getAllelePhenotype("asdf");
# my ($all_entry, $err_text) = &getAllelePhenotype("ad1674");
# my ($all_entry, $err_text) = &getAllelePhenotype("e678");
# my ($all_entry, $err_text) = &getAllelePhenotype("all");
# my ($all_entry, $err_text) = &getAllelePhenotype("e382");
# my ($all_entry, $err_text) = &getAllelePhenotype("tn377");
# my ($all_entry, $err_text) = &getAllelePhenotype("me4");
# my ($all_entry, $err_text) = &getAllelePhenotype("tm242");
# my ($all_entry, $err_text) = &getAllelePhenotype("e444");
# my ($all_entry, $err_text) = &getAllelePhenotype("tm1784");
# my ($all_entry, $err_text) = &getAllelePhenotype("n3713");
my ($all_entry, $err_text) = &getAllelePhenotype("akEx406");
if ($err_text) { print OUT "$err_text\n"; }
print OUT "$all_entry";
close (OUT) or die "Cannot close $outfile : $!";

