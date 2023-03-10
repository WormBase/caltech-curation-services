#!/usr/bin/perl -w

# compare chebi.obo with mop_ data
# ftp://ftp.ebi.ac.uk/pub/databases/chebi/ontology/chebi.obo
# 2015 11 04
#
# populate some mop tables ( molformula iupac smiles inchi inchikey kegg )
# if there's data in obo file not the same as in mop table.  2015 11 10
#
# granted permission to acedb account for these mop tables on tazendra.  2015 11 24


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

my %chebiToPgid;
$result = $dbh->prepare( "SELECT * FROM mop_chebi" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $chebiToPgid{$row[1]} = $row[0]; }
my @pgtables = qw( molformula iupac smiles inchi inchikey kegg );
# my @pgtables = qw( molformula smiles inchi inchikey kegg );
foreach my $pgtable (@pgtables) {
  $result = $dbh->prepare( "SELECT * FROM mop_$pgtable" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { $mop{$pgtable}{$row[0]} = $row[1]; }
}



my %delete;
my %insert;
foreach my $entry (@entries) {
  my ($id) = $entry =~ m/id: CHEBI:(\d+)/;
  next unless $id;
  my $pgid = $chebiToPgid{$id} || '';
#   my ($molformula, $iupac, $smiles, $inchi, $inchikey) = ('', '', '', '', '');
  my %obo;
  if ($entry =~ m/synonym: "(.*?)" RELATED FORMULA \[KEGG COMPOUND:\]/) { $obo{molformula}{$id} = $1; }
  if ($entry =~ m/synonym: "(.*?)" EXACT IUPAC_NAME \[IUPAC:\]/)        { $obo{iupac}{$id}      = $1; }
  if ($entry =~ m/synonym: "(.*?)" RELATED SMILES \[ChEBI:\]/)          { $obo{smiles}{$id}     = $1; }
  if ($entry =~ m/synonym: "(.*?)" RELATED InChI \[ChEBI:\]/)           { $obo{inchi}{$id}      = $1; }
  if ($entry =~ m/synonym: "(.*?)" RELATED InChIKey \[ChEBI:\]/)        { $obo{inchikey}{$id}   = $1; }
  if ($entry =~ m/xref: KEGG COMPOUND:(.*?) "KEGG COMPOUND"/)           { $obo{kegg}{$id}       = $1; }

  unless ($pgid) { 
#     print qq(No entry for chebi $id\n);
    next; }
  foreach my $field (sort keys %obo) {
    my $obo_value = $obo{$field}{$id}   || '';
    my $mop_value = $mop{$field}{$pgid} || '';
#     if ($mop_value) { print qq(HAS MOP pgid:$pgid chebi:$id $field $mop_value\n); }
    my $same_or_diff = 'same';
    unless ($obo_value eq $mop_value) { $same_or_diff = 'diff'; }
#     print qq($same_or_diff\tpgid:$pgid\tchebi:$id\t$field\tobo:$obo_value\tmop:$mop_value\n);
    if ($same_or_diff eq 'diff') {				# must be different
      next unless ($obo_value);					# must have obo data (leave mop data if no obo data)
      print qq($same_or_diff\tpgid:$pgid\tchebi:$id\t$field\tobo:$obo_value\tmop:$mop_value\n);
      if ($mop_value) { $delete{$field}{$pgid}++; }		# if has mop data, remove it
      $obo_value =~ s/\'/''/g; 
      $obo_value =~ s/\\/\\\\/g; 
      $insert{$field}{$pgid} = $obo_value;			# always insert to mop
    } # if ($diff)
  } # foreach my $field (sort keys %obo)
  
#   my ($name) = $entry =~ m/name: (.*?)\n/;
#   my (@syns) = $entry =~ m/synonym: "([^"]*)"/g;
#   $any{$id}++;
# #   $chebi{$id}{name} = $name;
# #   foreach (@syns) { $chebi{$id}{syn}{$_}++; }
#   ($name) = lc($name);
#   $chebi{$id}{$name}++;
#   foreach my $syn (@syns) { 
#     ($syn) = lc($syn);
#     $chebi{$id}{$syn}++; }
# #   print qq(ID $id N $name E $entry END\n);
} # foreach my $entry (@entries)

my @pgcommands;
foreach my $field (sort keys %delete) {
  my $pgids = join"','", sort {$a<=>$b} keys %{ $delete{$field} };
  push @pgcommands, qq(DELETE FROM mop_$field WHERE joinkey IN ('$pgids'););
} # foreach my $field (sort keys %delete)
foreach my $field (sort keys %insert) {
  my @data;
  foreach my $pgid (sort {$a<=>$b} keys %{ $insert{$field } }) {
    push @data, qq( ('$pgid', E'$insert{$field}{$pgid}') );
#     push @pgcommands, qq(INSERT INTO mop_${field}     VALUES ('$pgid', E'$insert{$field}{$pgid}'););
#     push @pgcommands, qq(INSERT INTO mop_${field}_hst VALUES ('$pgid', E'$insert{$field}{$pgid}'););
  } # foreach my $pgid (sort {$a<=>$b} keys %{ $insert{$field } })
  my $data = join", ", @data;
  push @pgcommands, qq(INSERT INTO mop_${field}     VALUES $data;);
  push @pgcommands, qq(INSERT INTO mop_${field}_hst VALUES $data;);
} # foreach my $field (sort keys %delete)

foreach my $pgcommand (@pgcommands) {
  print qq($pgcommand\n);
# UNCOMMENT TO POPULATE
   $dbh->do( $pgcommand );
} # foreach my $pgcommand (@pgcommands)

__END__


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
  ($publicname) = lc($publicname);
  $mop{$chebi}{$publicname}++;
  foreach my $syn (@synonyms) { 
    ($syn) = lc($syn);
    $mop{$chebi}{$syn}++; }
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

