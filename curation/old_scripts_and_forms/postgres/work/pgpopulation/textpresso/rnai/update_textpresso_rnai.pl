#!/usr/bin/perl -w

# update tfp_rnai based on textpresso data for Gary.  2009 04 15
#
# wrapped in 
# 0 4 * * * /home/postgres/work/pgpopulation/textpresso/wrapper.sh
#
# REMOVED gary using svm results now  2009 09 24



use strict;
use diagnostics;
use Pg;
use LWP::Simple;
use Jex;

my $date = &getSimpleDate();
my $timestamp = &getSimpleSecDate();

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;
my $result;

my $directory = '/home/postgres/work/pgpopulation/textpresso/rnai';
chdir($directory) or die "Cannot go to $directory ($!)";


$/ = undef;
my $full_file = 'rnai_gary';
open (IN, "<$full_file") or die "Cannot open $full_file : $!";
my $last_data = <IN>;
close (IN) or die "Cannot close $full_file : $!";

my $new_data = get "http://textpresso-dev.caltech.edu/azurebrd/gary/rnai_out";
exit if ($last_data eq $new_data);

my $logfile = $directory . '/logfile.pg';
open (LOG, ">$logfile") or die "Cannot rewrite $logfile : $!";

open (OUT, ">$full_file") or die "Cannot rewrite $full_file : $!";
print OUT $new_data;
close (OUT) or die "Cannot close $full_file : $!";

my (@tlines) = split/\n/, $new_data;
my @pgcommands;

my %hash;
push @pgcommands, "DELETE FROM tfp_rnai;";
foreach my $paper (@tlines) {
  my ($joinkey) = $paper =~ m/WBPaper(\d+)/;
  if ($hash{$joinkey}) { $hash{$joinkey} .= "\n" . $paper . "  yes"; }
    else { $hash{$joinkey} = $paper . "  yes"; }
} # foreach my $line (@tlines)

foreach my $joinkey (sort keys %hash) {
  my $line = $hash{$joinkey};
  push @pgcommands, "INSERT INTO tfp_rnai VALUES ('$joinkey', '$line');";
}

foreach my $command (@pgcommands) {
  print LOG "$command\n";
  $result = $conn->exec( $command );
} # foreach my $command (@pgcommands)


close (LOG) or die "Cannot close $logfile : $!";

