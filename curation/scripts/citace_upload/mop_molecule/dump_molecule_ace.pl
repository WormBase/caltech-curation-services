#!/usr/bin/env perl

# dump mop_ data into Molecule.ace for citace upload  2010 07 31
#
# added smmid, only print mesh and ctd if it's not a WBMol.  2011 07 08
# KY-changed SMMID DB print out to SMID-DB as database named had changed 2012 02 24
#
# added Reference, Molecule_use  Change object id to come from mop_name instead of mop_molecule.  2012 10 22
#
# changed mop_molecule restriction to be if a value exists, instead of not matching WBMol.  2012 12 20 
# changed out path to /home/acedb/karen/WS_upload_scripts/Molecule 2014 01 23
#
# more tables for Karen  2015 11 25
#
# convert endogenous value from taxon id to taxon name.  2016 06 06
#
# No longer dumping bioroletext for Karen because model doesn't support it.  2017 09 14
#
# Dumping bioroletext as a Remark in #Evidence.  2019 11 14
#
# Changed for utf8 changes in postgres.  2021 05 27
#
# Dockerized cronjob. Output to /usr/caltech_curation_files/pub/citace_upload/karen/  2023 03 14
#
# cronjob
# 0 4 * * sun /usr/lib/scripts/citace_upload/mop_molecule/dump_molecule_ace.pl


use strict;
use diagnostics;
use DBI;


use lib qw(  /usr/lib/scripts/perl_modules/ );                      # for general ace dumping functions
# use lib qw( /home/postgres/work/citace_upload/ );               # for general ace dumping functions
use ace_dumper;

use Dotenv -load => '/usr/lib/.env';

my $dbh = DBI->connect ( "dbi:Pg:dbname=$ENV{PSQL_DATABASE};host=$ENV{PSQL_HOST};port=$ENV{PSQL_PORT}", "$ENV{PSQL_USERNAME}", "$ENV{PSQL_PASSWORD}") or die "Cannot connect to database!\n";
# my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my $simpleRemapHashRef = &populateSimpleRemap();


# my @tables = qw( name molecule paper publicname synonym moleculeuse chemi chebi kegg smmid inchi inchikey smiles molformula iupac exactmass biorole bioroletext essentialfor status detctmethod otherdetctmethod extrctmethod otherextrctmethod chemicalsynthesis nonbiosource endogenousin );
my @simple_tables = qw( name molecule publicname moleculeuse chemi chebi kegg smmid inchi inchikey smiles molformula iupac exactmass biorole bioroletext essentialfor status detctmethod otherdetctmethod extrctmethod otherextrctmethod chemicalsynthesis nonbiosource endogenousin );
my @other_tables = qw( paper synonym );
my %hash;
my $result;


# my $directory = '/home/acedb/karen/WS_upload_scripts/Molecule';
# chdir ($directory) or die "Cannot chdir to $directory : $!";

# my $outfile = $ENV{CALTECH_CURATION_FILES_INTERNAL_PATH}. "/pub/citace_upload/karen/Molecule.ace";
my $outfile = 'Molecule.ace';
open (OUT, ">$outfile") or die "Cannot create $outfile : $!";

foreach my $table (@other_tables) {
  my $pgtable = 'mop_' . $table;
  $result = $dbh->prepare( "SELECT * FROM $pgtable" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    if ($row[0]) { $hash{$table}{$row[0]} = $row[1]; } }
}
foreach my $table (@simple_tables) {
  my $pgtable = 'mop_' . $table;
  $result = $dbh->prepare( "SELECT * FROM $pgtable" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    if ($row[0]) { $hash{$table}{$row[0]} = &utf8ToHtml($simpleRemapHashRef, $row[1]); } }
}

my %taxonIdToName;
$result = $dbh->prepare( " SELECT * FROM obo_name_ncbitaxonid ; " );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $taxonIdToName{$row[0]} = $row[1]; } }

foreach my $joinkey (sort {$a<=>$b} keys %{ $hash{name} }) {
  my ($objid, $molecule, $publicname, $syns, $moleculeuse, $chemi, $chebi, $kegg);
  if ($hash{name}{$joinkey}) { $objid = $hash{name}{$joinkey}; }
  if ($hash{molecule}{$joinkey}) { $molecule = $hash{molecule}{$joinkey}; }
  next unless $objid;
#   next if ($molecule =~ m/WBMol/);		# always print objects for Karen 2011 07 05
  print OUT "Molecule : \"$objid\"\n";
  if ($hash{publicname}{$joinkey}) { print OUT "Public_name\t\"$hash{publicname}{$joinkey}\"\n"; }
  if ($hash{synonym}{$joinkey}) { 
    my (@syns) = split/ \| /, $hash{synonym}{$joinkey};
    foreach my $syn (@syns) { 
      $syn = &utf8ToHtml($simpleRemapHashRef, $syn);
      print OUT "Synonym\t\"$syn\"\n"; } }
#   if ($molecule !~ m/WBMol/) { # }		# used to be only dumped if didn't match WBMol, now always dump if there's a value in mop_molecule. for Karen.  2012 12 20
  my @papers = ();
  if ($hash{paper}{$joinkey}) { 
    $hash{paper}{$joinkey} =~ s/^\"//;
    $hash{paper}{$joinkey} =~ s/\"$//;
    (@papers) = split/","/, $hash{paper}{$joinkey}; 
    foreach my $paper (@papers) {
      print OUT "Reference\t\"$paper\"\n"; } }
  if ($molecule) {
      print OUT "Database\t\"NLM_MeSH\" \"UID\" \"$molecule\"\n";
      print OUT "Database\t\"CTD\" \"ChemicalID\" \"$molecule\"\n"; }
  if ($hash{chebi}{$joinkey}) {             print OUT "Database\t\"ChEBI\" \"CHEBI_ID\" \"$hash{chebi}{$joinkey}\"\n"; }
  if ($hash{chemi}{$joinkey}) {             print OUT "Database\t\"ChemIDplus\" \"RN\" \"$hash{chemi}{$joinkey}\"\n"; }
  if ($hash{kegg}{$joinkey}) {              print OUT "Database\t\"KEGG COMPOUND\" \"ACCESSION_NUMBER\" \"$hash{kegg}{$joinkey}\"\n"; }
  if ($hash{smmid}{$joinkey}) {             print OUT "Database\t\"SMID-DB\" \"$hash{smmid}{$joinkey}\"\n"; }
  if ($hash{moleculeuse}{$joinkey}) {       print OUT "Molecule_use\t\"$hash{moleculeuse}{$joinkey}\"\n"; }
  if ($hash{inchi}{$joinkey}) {             print OUT "InChi\t\"$hash{inchi}{$joinkey}\"\n"; }
  if ($hash{inchikey}{$joinkey}) {          print OUT "InChiKey\t\"$hash{inchikey}{$joinkey}\"\n"; }
  if ($hash{smiles}{$joinkey}) {            print OUT "SMILES\t\"$hash{smiles}{$joinkey}\"\n"; }
  if ($hash{molformula}{$joinkey}) {        print OUT "Formula\t\"$hash{molformula}{$joinkey}\"\n"; }
  if ($hash{iupac}{$joinkey}) {             print OUT "IUPAC\t\"$hash{iupac}{$joinkey}\"\n"; }
  if ($hash{exactmass}{$joinkey}) {         print OUT "Monoisotopic_mass\t\"$hash{exactmass}{$joinkey}\"\n"; }

# No longer dumping bioroletext for Karen because model doesn't support it.  2017 09 14
#   if ($hash{biorole}{$joinkey}) {           print OUT "Biofunction_role\t\"$hash{biorole}{$joinkey}\"\n";
#     if ($hash{bioroletext}{$joinkey}) {     print OUT "Biofunction_role\t\"$hash{biorole}{$joinkey}\"\t\"$hash{bioroletext}{$joinkey}\"\n";
#         if ($hash{bioroletext}{$joinkey} eq 'Metabolite') {
#             foreach my $paper (@papers) {           print OUT "Biofunction_role\t\"$hash{biorole}{$joinkey}\"\t\"Empty\"\tPaper_evidence\t\"$paper\"\n"; } }
#           else {
#             foreach my $paper (@papers) {           print OUT "Biofunction_role\t\"$hash{biorole}{$joinkey}\"\t\"$hash{bioroletext}{$joinkey}\"\tPaper_evidence\t\"$paper\"\n"; } } }
#       else {
#         foreach my $paper (@papers) {           print OUT "Biofunction_role\t\"$hash{biorole}{$joinkey}\"\t\"Empty\"\tPaper_evidence\t\"$paper\"\n"; } } }

  if ($hash{biorole}{$joinkey}) {           print OUT "Biofunction_role\t\"$hash{biorole}{$joinkey}\"\n";
    if ($hash{bioroletext}{$joinkey}) {     print OUT "Biofunction_role\t\"$hash{biorole}{$joinkey}\"\tRemark\t\"$hash{bioroletext}{$joinkey}\"\n"; }
    foreach my $paper (@papers) {           print OUT "Biofunction_role\t\"$hash{biorole}{$joinkey}\"\tPaper_evidence\t\"$paper\"\n"; } }
  if ($hash{essentialfor}{$joinkey}) {      print OUT "Essential_for\t\"$hash{essentialfor}{$joinkey}\"\n"; }
  if ($hash{status}{$joinkey}) {            print OUT "Status\t\"$hash{status}{$joinkey}\"\n"; 
    foreach my $paper (@papers) {           print OUT "Status\t\"$hash{status}{$joinkey}\"\tPaper_evidence\t\"$paper\"\n"; } }
  if ($hash{detctmethod}{$joinkey}) {       print OUT "Detection_method\t\"$hash{detctmethod}{$joinkey}\"\n";
    foreach my $paper (@papers) {           print OUT "Detection_method\t\"$hash{detctmethod}{$joinkey}\"\tPaper_evidence\t\"$paper\"\n"; } }
  if ($hash{otherdetctmethod}{$joinkey}) {  print OUT "Detection_method\t\"$hash{otherdetctmethod}{$joinkey}\"\n";
    foreach my $paper (@papers) {           print OUT "Detection_method\t\"$hash{otherdetctmethod}{$joinkey}\"\tPaper_evidence\t\"$paper\"\n"; } }
  if ($hash{extrctmethod}{$joinkey}) {      print OUT "Extraction_method\t\"$hash{extrctmethod}{$joinkey}\"\n";
    foreach my $paper (@papers) {           print OUT "Extraction_method\t\"$hash{extrctmethod}{$joinkey}\"\tPaper_evidence\t\"$paper\"\n"; } }
  if ($hash{otherextrctmethod}{$joinkey}) { print OUT "Extraction_method\t\"$hash{otherextrctmethod}{$joinkey}\"\n";
    foreach my $paper (@papers) {           print OUT "Extraction_method\t\"$hash{otherextrctmethod}{$joinkey}\"\tPaper_evidence\t\"$paper\"\n"; } }
  if ($hash{chemicalsynthesis}{$joinkey}) { print OUT "Chemical_synthesis\n";
    foreach my $paper (@papers) {           print OUT "Chemical_synthesis\tPaper_evidence\t\"$paper\"\n"; } }
  if ($hash{nonbiosource}{$joinkey}) {      print OUT "Nonspecies_source\t\"$hash{nonbiosource}{$joinkey}\"\n"; }
  if ($hash{endogenousin}{$joinkey}) {
    my $endogenousValue = $taxonIdToName{$hash{endogenousin}{$joinkey}} || $hash{endogenousin}{$joinkey};
                                            print OUT "Endogenous_in\t\"$endogenousValue\"\n"; }
  print OUT "\n";
} # foreach my $joinkey (sort {$a<=>$b} keys %{ $hash{molecule} })

close (OUT) or die "Cannot close $outfile : $!";

__END__

Molecule : "C087920"
Public_name "beta-selinene"
Database "NLM_MeSH" "UID" "C087920"
Database "CTD"  "ChemicalID" "C087920"
Database "ChemIDplus"  "17066-67-0"
Database "ChEBI" "CHEBI_ID" "10443"
Database "KEGG COMPOUND" "ACCESSION_NUMBER" "C09723"


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

my $result = $dbh->prepare( 'SELECT * FROM two_comment WHERE two_comment ~ ?' );
$result->execute('elegans') or die "Cannot prepare statement: $DBI::errstr\n"; 

$result->execute("doesn't") or die "Cannot prepare statement: $DBI::errstr\n"; 
my $var = "doesn't";
$result->execute($var) or die "Cannot prepare statement: $DBI::errstr\n"; 

my $data = 'data';
unless (is_utf8($data)) { from_to($data, "iso-8859-1", "utf8"); }

my $result = $dbh->do( "DELETE FROM friend WHERE firstname = 'bl\"ah'" );
(also do for INSERT and UPDATE if don't have a variable to interpolate with ? )

can cache prepared SELECTs with $dbh->prepare_cached( &c. );

if ($result->rows == 0) { print "No names matched.\n\n"; }	# test if no return

$result->finish;	# allow reinitializing of statement handle (done with query)
$dbh->disconnect;	# disconnect from DB

http://209.85.173.132/search?q=cache:5CFTbTlhBGMJ:www.perl.com/pub/1999/10/DBI.html+dbi+prepare+execute&cd=4&hl=en&ct=clnk&gl=us

interval stuff : 
SELECT * FROM afp_passwd WHERE joinkey NOT IN (SELECT joinkey FROM afp_lasttouched) AND joinkey NOT IN (SELECT joinkey FROM cfp_curator) AND afp_timestamp < CURRENT_TIMESTAMP - interval '21 days' AND afp_timestamp > CURRENT_TIMESTAMP - interval '28 days';

casting stuff to substring on other types :
SELECT * FROM afp_passwd WHERE CAST (afp_timestamp AS TEXT) ~ '2009-05-14';

to concatenate string to query result :
  SELECT 'WBPaper' || joinkey FROM pap_identifier WHERE pap_identifier ~ 'pmid';
to get :
  SELECT DISTINCT(gop_paper_evidence) FROM gop_paper_evidence WHERE gop_paper_evidence NOT IN (SELECT 'WBPaper' || joinkey FROM pap_identifier WHERE pap_identifier ~ 'pmid') AND gop_paper_evidence != '';

