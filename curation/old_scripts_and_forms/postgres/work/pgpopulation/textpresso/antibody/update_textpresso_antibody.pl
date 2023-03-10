#!/usr/bin/perl -w

# update tfp_antibody based on textpresso data for Wen.
#
# Last updated Jun 28 2010, Daniela using cur_strdata instead of tfp_antibody, so not using this anymore.  2018 07 25
#
# wrapped in 
# 0 4 * * * /home/postgres/work/pgpopulation/textpresso/wrapper.sh



use strict;
use diagnostics;
use LWP::Simple;
use Jex;
use DBI;

my $date = &getSimpleDate();
my $timestamp = &getSimpleSecDate();

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my $directory = '/home/postgres/work/pgpopulation/textpresso/antibody';
chdir($directory) or die "Cannot go to $directory ($!)";


$/ = undef;
my $full_file = 'anti_protein_wen';
open (IN, "<$full_file") or die "Cannot open $full_file : $!";
my $last_data = <IN>;
close (IN) or die "Cannot close $full_file : $!";

my $new_data = get "http://textpresso-dev.caltech.edu/azurebrd/wen/anti_protein_wen";
exit if ($last_data eq $new_data);

my $logfile = $directory . '/logfile.pg';
open (LOG, ">$logfile") or die "Cannot rewrite $logfile : $!";

open (OUT, ">$full_file") or die "Cannot rewrite $full_file : $!";
print OUT $new_data;
close (OUT) or die "Cannot close $full_file : $!";

my (@tlines) = split/\n/, $new_data;
my @pgcommands;

my %hash;
push @pgcommands, "DELETE FROM tfp_antibody;";
foreach my $line (@tlines) {
  my ($paper, $antibody) = split/\t+/, $line;
  if ($paper =~ m/(WBPaper\d+)/) { $paper = $1; }
  my ($joinkey) = $paper =~ m/WBPaper(\d+)/;
  $line =~ s/\t/  /g;
  if ($hash{$joinkey}) { $hash{$joinkey} .= "\n" . $line; }
    else { $hash{$joinkey} = $line; }
} # foreach my $line (@tlines)

foreach my $joinkey (sort keys %hash) {
  my $line = $hash{$joinkey};
  push @pgcommands, "INSERT INTO tfp_antibody VALUES ('$joinkey', '$line');";
}

foreach my $command (@pgcommands) {
  print LOG "$command\n";
  $result = $dbh->do( $command );
} # foreach my $command (@pgcommands)


close (LOG) or die "Cannot close $logfile : $!";

