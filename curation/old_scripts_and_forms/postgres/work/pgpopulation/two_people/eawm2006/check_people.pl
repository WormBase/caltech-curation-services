#!/usr/bin/perl -w

# sample PG query

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my %hash;
my $result = $conn->exec( "SELECT * FROM two_lastname;" );
while (my @row = $result->fetchrow) { if ($row[0]) { $hash{$row[0]}{main}{last} = $row[2]; } }
$result = $conn->exec( "SELECT * FROM two_firstname;" );
while (my @row = $result->fetchrow) { if ($row[0]) { $hash{$row[0]}{main}{first} = $row[2]; } }
$result = $conn->exec( "SELECT * FROM two_aka_lastname;" );
while (my @row = $result->fetchrow) { if ($row[0]) { $hash{$row[0]}{$row[1]}{last} = $row[2]; } }
$result = $conn->exec( "SELECT * FROM two_aka_firstname;" );
while (my @row = $result->fetchrow) { if ($row[0]) { $hash{$row[0]}{$row[1]}{first} = $row[2]; } }

my %names;
foreach my $join (sort keys %hash) {
  foreach my $key (sort keys %{ $hash{$join} }) {
    my $first = $hash{$join}{$key}{first};
    my $last = ''; if ($hash{$join}{$key}{last}) { $last = $hash{$join}{$key}{last}; }
    my $init = ''; if ($first) { ($init) = $first =~ m/^(.)/; }
    my $name = "$last $init";
    $name = lc($name);
    $names{$name}{$join}++; } }

# foreach my $name (sort keys %names) {
#   print "$name\t";
#   foreach my $join (sort keys %{ $names{$name} }) { print "$join\t"; }
#   print "\n"; }

my $infile = 'eawm2006.txt';
open (IN, "<$infile") or die "Cannot open $infile : $!";
my $header = <IN>;
while (my $line = <IN>) {
  chomp ($line);
  my ($a, $first_mid, $last, $inst, $pi_fm, $pi_l, $country, $address, $area, $phone, $ext, $fax, $email) = split/\t/, $line;
  my ($init) = $first_mid =~ m/^(.)/;
  my $name = "$last $init";
  $name = lc($name);
  if ($names{$name}) { 
      my @joins;
      foreach my $join (sort keys %{ $names{$name} }) { push @joins, $join; }
      my $joins = join", ", @joins;
      print "$first_mid $last MATCHES $joins\n"; }
    else { print "NO MATCH $first_mid $last\n"; }

  next unless ( $pi_fm && $pi_l );
  ($init) = $pi_fm =~ m/^(.)/;
  $name = "$pi_l $init";
  $name = lc($name);
  if ($names{$name}) { 
      my @joins;
      foreach my $join (sort keys %{ $names{$name} }) { push @joins, $join; }
      my $joins = join", ", @joins;
      print "PI $pi_fm $pi_l MATCHES $joins\n"; }
    else { print "PI NO MATCH $pi_fm $pi_l\n"; }
  
} # while (my $line = <IN>)
close (IN) or die "Cannot close $infile : $!";


__END__

