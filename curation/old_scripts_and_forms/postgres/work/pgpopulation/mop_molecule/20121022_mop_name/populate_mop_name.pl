#!/usr/bin/perl -w

# populate mop_name tables based on pgid.  2012 10 22

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my $result;
my @pgcommands;

my %pgids;
$result = $dbh->prepare( "SELECT * FROM mop_curator" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $pgids{$row[0]}++; } 
$result = $dbh->prepare( "SELECT * FROM mop_molecule" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $pgids{$row[0]}++; } 

foreach my $pgid (sort {$a<=>$b} keys %pgids) {
  my $molId = &pad8Zeros($pgid);
  my $id = "WBMol:$molId";
  push @pgcommands, "INSERT INTO mop_name VALUES ('$pgid', '$id')";
  push @pgcommands, "INSERT INTO mop_name_hst VALUES ('$pgid', '$id')";
} # foreach my $pgid (sort {$a<=>$b} keys %pgids)

foreach my $pgcommand (@pgcommands) {
  print qq($pgcommand\n);
# UNCOMMENT TO POPULATE
#   $result = $dbh->do( $pgcommand );
} # foreach my $pgcommand (@pgcommands)


sub pad8Zeros {         # take a number and pad to 8 digits
  my $number = shift;
  if ($number =~ m/^0+/) { $number =~ s/^0+//g; }               # strip leading zeros
  if ($number < 10) { $number = '0000000' . $number; }
  elsif ($number < 100) { $number = '000000' . $number; }
  elsif ($number < 1000) { $number = '00000' . $number; }
  elsif ($number < 10000) { $number = '0000' . $number; }
  elsif ($number < 100000) { $number = '000' . $number; }
  elsif ($number < 1000000) { $number = '00' . $number; }
  elsif ($number < 10000000) { $number = '0' . $number; }
  return $number;
} # sub pad8Zeros


__END__

my @fields = qw( chebi chemi curator kegg molecule publicname remark synonym );
foreach my $field (@fields) {
  my $table = "mop_$field";
  $result = $dbh->do( "DELETE FROM $table" );
  $table = "mop_$field" . "_hst";
  $result = $dbh->do( "DELETE FROM $table" );
}

my @pgcommands;
my $joinkey = 0;
$/ = "";
my $infile = 'Molecule.ace';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $entry = <IN>) {
  next unless ($entry =~ m/Molecule : "([^\"]+)"/);
  $joinkey++;
  my $value = $1; if ($value =~ m/\'/) { $value =~ s/\'/''/g; }
  push @pgcommands, "INSERT INTO mop_molecule VALUES ('$joinkey', '$value')";
  push @pgcommands, "INSERT INTO mop_molecule_hst VALUES ('$joinkey', '$value')";
  if ($entry =~ m/Public_name\s+\"([^\"]+)"/) {
    my $value = $1; if ($value =~ m/\'/) { $value =~ s/\'/''/g; }
    push @pgcommands, "INSERT INTO mop_publicname VALUES ('$joinkey', '$value')";
    push @pgcommands, "INSERT INTO mop_publicname_hst VALUES ('$joinkey', '$value')"; }
  if ($entry =~ m/Database\s+\"ChemIDplus\"\s+\"([^\"]+)"/) {
    my $value = $1; if ($value =~ m/\'/) { $value =~ s/\'/''/g; }
    push @pgcommands, "INSERT INTO mop_chemi VALUES ('$joinkey', '$value')";
    push @pgcommands, "INSERT INTO mop_chemi_hst VALUES ('$joinkey', '$value')"; }
  if ($entry =~ m/Database\s+\"ChEBI\"\s+\"CHEBI_ID\"\s+\"([^\"]+)"/) {
    my $value = $1; if ($value =~ m/\'/) { $value =~ s/\'/''/g; }
    push @pgcommands, "INSERT INTO mop_chebi VALUES ('$joinkey', '$value')";
    push @pgcommands, "INSERT INTO mop_chebi_hst VALUES ('$joinkey', '$value')"; }
  if ($entry =~ m/Database\s+\"KEGG COMPOUND\"\s+\"ACCESSION_NUMBER\"\s+\"([^\"]+)"/) {
    my $value = $1; if ($value =~ m/\'/) { $value =~ s/\'/''/g; }
    push @pgcommands, "INSERT INTO mop_kegg VALUES ('$joinkey', '$value')";
    push @pgcommands, "INSERT INTO mop_kegg_hst VALUES ('$joinkey', '$value')"; }
  if ($entry =~ m/Synonym\s+\"([^\"]+)"/) {
    my $value = $1; if ($value =~ m/\'/) { $value =~ s/\'/''/g; }
    my (@syns) = $entry =~ m/Synonym\s+\"([^\"]+)"/g; 
    my $syns = join " | ", @syns;
    if ($syns =~ m/\'/) { $syns =~ s/\'/''/g; }
    push @pgcommands, "INSERT INTO mop_synonym VALUES ('$joinkey', '$syns')";
    push @pgcommands, "INSERT INTO mop_synonym_hst VALUES ('$joinkey', '$syns')"; }
  push @pgcommands, "INSERT INTO mop_curator VALUES ('$joinkey', 'WBPerson712')";
  push @pgcommands, "INSERT INTO mop_curator_hst VALUES ('$joinkey', 'WBPerson712')";
} # while (my $entry = <IN>)
close (IN) or die "Cannot close $infile : $!";
$/ = "\n";

foreach my $command (@pgcommands) {
  print "$command\n";
# UNCOMMENT to populate data
#   $result = $dbh->do( $command );
} # foreach my $command (@pgcommands)

__END__

my $result = $dbh->prepare( "SELECT * FROM two_comment WHERE two_comment ~ ?" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[1] =~ s///g;
    $row[2] =~ s///g;
    print "$row[0]\t$row[1]\t$row[2]\n";
  } # if ($row[0])
} # while (@row = $result->fetchrow)

__END__

Molecule : "C087920"
Public_name "beta-selinene"
Database "NLM_MeSH" "UID" "C087920"
Database "CTD"  "ChemicalID" "C087920"
Database "ChemIDplus"  "17066-67-0"
Database "ChEBI" "CHEBI_ID" "10443"
Database "KEGG COMPOUND" "ACCESSION_NUMBER" "C09723"

Molecule : "D006152"
Public_name "Cyclic GMP"
Synonym "3', 5'-cyclic GMP"
Synonym "cGMP"
Database "NLM_MeSH" "UID" "D006152"
Database "CTD"  "ChemicalID" "D006152"
Database "ChemIDplus"  "7665-99-8"
Database "ChEBI" "CHEBI_ID" "16356"

