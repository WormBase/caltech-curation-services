#!/usr/bin/perl -w

# parse  WSxxx_species_ncbiTaxIDs.txt  into  obo_name_ncbitaxonid  obo_data_ncbitaxonid
# May manually in the future get a new set and repopulate based on that with this script.
# For Chris for phenotype OA  Caused by Pathogen.  2015 08 26


use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my @pgcommands;
push @pgcommands, qq(DELETE FROM obo_name_ncbitaxonid);
push @pgcommands, qq(DELETE FROM obo_data_ncbitaxonid);
my $infile = 'WS249_species_ncbiTaxIDs.txt';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) {
  chomp $line;
  my ($name, $taxonid) = split/\t/, $line;
  next unless ($taxonid);
  $name =~ s/^"//; $name =~ s/"$//;
  if ($name =~ m/\'/) { $name =~ s/\'/''/g; }
  push @pgcommands, qq(INSERT INTO obo_name_ncbitaxonid VALUES ('$taxonid', '$name'));
  push @pgcommands, qq(INSERT INTO obo_data_ncbitaxonid VALUES ('$taxonid', 'id: $taxonid\nname: $name'));
  print "T $taxonid\t$name\n";
} # while (my $line = <IN>)
close (IN) or die "Cannot close $infile : $!";

foreach my $pgcommand (@pgcommands) {
  print qq($pgcommand\n);
# UNCOMMENT TO POPULATE
#   $dbh->do( $pgcommand );
} # foreach my $pgcommand (@pgcommands)

#  Caenorhabditis elegans    | id: Caenorhabditis elegans    | 2015-02-19 11:24:20.924399-08


# $result = $dbh->prepare( "SELECT * FROM two_comment" );
# $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
# while (my @row = $result->fetchrow) {
#   if ($row[0]) { 
#     $row[0] =~ s///g;
#     $row[1] =~ s///g;
#     $row[2] =~ s///g;
#     print "$row[0]\t$row[1]\t$row[2]\n";
#   } # if ($row[0])
# } # while (@row = $result->fetchrow)

__END__

