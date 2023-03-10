#!/usr/bin/perl -w

# populate obo tables for pcrproduct  2012 03 24
#
# live run 2012 04 19

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my @pgcommands;

# my $infile = 'WS229_PCR_products.txt';
my $infile = 'WS270_PCR_products.txt';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $name = <IN>) {
  chomp $name;
  if ($name =~ m/\'/) { $name =~ s/\'/''/g; }
  if ($name =~ m/\s+$/) { $name =~ s/\s+$//; }
  if ($name =~ m/^\s+/) { $name =~ s/^\s+//; }
  my $term_info = qq(<span style="font-weight: bold">id : </span> $name\n<span style="font-weight: bold">name : </span> $name);
  push @pgcommands, "INSERT INTO obo_name_pcrproduct VALUES ('$name', '$name')";
  push @pgcommands, "INSERT INTO obo_data_pcrproduct VALUES ('$name', E'$term_info')";
} # while (my $entry = <IN>)
close (IN) or die "Cannot close $infile : $!";

foreach my $command (@pgcommands) {
  print "$command\n";
# UNCOMMENT TO POPULATE
  $dbh->do( $command );
}

__END__


