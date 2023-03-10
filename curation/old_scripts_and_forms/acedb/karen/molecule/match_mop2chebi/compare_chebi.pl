#!/usr/bin/perl -w

# compare chebi.obo with mop_ data
# ftp://ftp.ebi.ac.uk/pub/databases/chebi/ontology/chebi.obo
# 2015 11 04
#
# later on need to
# mop_table	chebi.obo entry	example
# mop_formula	synonym: "<formula>" RELATED FORMULA [KEGG COMPOUND:]
# mop_iupac (table not created?)	synonym: "<NAME>" EXACT IUPAC_NAME [IUPAC:]
# mop_smiles	synonym: "<smiles>" RELATED SMILES [ChEBI:]
# mop_inchi	synonym: "<InChI=>" RELATED InChI [ChEBI:]
# mop_inchikey	synonym: "<inchikey>" RELATED InChIKey [ChEBI:]


use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %any;
my %chebi;
my %mop;

my $infile = 'chebi.obo';
$/ = undef;
open (IN, "<$infile") or die "Cannot open $infile : $!";
my $allfile = <IN>;
close (IN) or die "Cannot close $infile : $!";
my (@entries) = split/\[Term\]\n/, $allfile;
my $junk = shift @entries;

foreach my $entry (@entries) {
  my ($id) = $entry =~ m/id: CHEBI:(\d+)/;
  next unless $id;
  my ($name) = $entry =~ m/name: (.*?)\n/;
  my (@syns) = $entry =~ m/synonym: "([^"]*)"/g;
  $any{$id}++;
#   $chebi{$id}{name} = $name;
#   foreach (@syns) { $chebi{$id}{syn}{$_}++; }
  $chebi{$id}{$name}++;
  foreach (@syns) { $chebi{$id}{$_}++; }
#   print qq(ID $id N $name E $entry END\n);
} # foreach my $entry (@entries)


my %filter;
$result = $dbh->prepare( "SELECT * FROM mop_chebi" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $filter{$row[0]}{'chebi'} = $row[1]; }
$result = $dbh->prepare( "SELECT * FROM mop_publicname" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $filter{$row[0]}{'publicname'} = $row[1]; }
$result = $dbh->prepare( "SELECT * FROM mop_synonym" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $filter{$row[0]}{'synonym'} = $row[1]; }
foreach my $pgid (sort keys %filter) {
  my $chebi      = $filter{$pgid}{'chebi'};
  next unless $chebi;
  my $publicname = $filter{$pgid}{'publicname'} || '';
  my $synonym    = $filter{$pgid}{'synonym'} || '';
  my (@synonyms) = split/ | /, $synonym;
  $any{$chebi}++;
#   $mop{$chebi}{publicname} = $publicname;
#   foreach (@synonyms) { $mop{$chebi}{syn}{$_}++; }
  $mop{$chebi}{$publicname}++;
  foreach (@synonyms) { $mop{$chebi}{$_}++; }
} # foreach my $pgid (sort keys %filter)

foreach my $id (sort {$a<=>$b} keys %any) {
#   unless ($chebi{$id}) { print qq($id not in chebi\n); }
#   unless ($mop{$id})   { print qq($id not in mop\n);   }
  next unless ($chebi{$id} && $mop{$id});
  my $isOk = 0;
  foreach my $name (sort keys %{ $chebi{$id} }) {
    if ($mop{$id}{$name}) { $isOk++; } }
  unless ($isOk) { 
    my $chebi = join" | ", sort keys %{ $chebi{$id} };
    my $mop   = join" | ", sort keys %{ $mop{$id}   };
    print qq(CHEBI:$id\tMOP $mop\tOBO $chebi\n);
  }
} # foreach my $id (sort keys %any)

__END__ 

$result = $dbh->prepare( "SELECT * FROM two_comment" );
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

[Term]
id: CHEBI:24431
name: chemical entity
def: "A chemical entity is a physical entity of interest in chemistry including molecular entities, parts thereof, and chemical substances." []
synonym: "grouped_by_chemistry" RELATED [ChEBI:]
synonym: "chemical entity" EXACT [UniProt:]
synonym: "." RELATED FORMULA [ChEBI:]

[Term]
id: CHEBI:23367
name: molecular entity
def: "Any constitutionally or isotopically distinct atom, molecule, ion, ion pair, radical, radical ion, complex, conformer etc., identifiable as a separately distinguishable entity." []
synonym: "entidades moleculares" RELATED [IUPAC:]
synonym: "molekulare Entitaet" RELATED [ChEBI:]
synonym: "entite moleculaire" RELATED [IUPAC:]
synonym: "entidad molecular" RELATED [IUPAC:]
synonym: "molecular entity" EXACT IUPAC_NAME [IUPAC:]
synonym: "molecular entities" RELATED [IUPAC:]
synonym: "." RELATED FORMULA [ChEBI:]
is_a: CHEBI:24431

