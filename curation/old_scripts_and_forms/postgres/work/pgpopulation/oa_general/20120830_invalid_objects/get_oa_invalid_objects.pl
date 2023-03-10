#!/usr/bin/perl -w

# find OA objects that are invalid

# supports WBPaper WBGene Transgene  2012 08 29


use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

use lib qw( /home/postgres/public_html/cgi-bin/oa/ );
use wormOA;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my @ontTypes = qw( WBPaper Transgene WBGene );
my %ontTypes; foreach (@ontTypes) { $ontTypes{$_}++; }
# my %ontToTable;
my %invalidObj;
&populateInvalidObjects(); 

my %badData;

my $curator_two = 'two1823';
my @datatypes = qw( abp app con exp gcl gop grg int mop pic pro prt ptg rna trp );
foreach my $datatype (@datatypes) {
  my ($fieldsRef, $datatypesRef) = &initModFields($datatype, $curator_two);
  my %fields = %$fieldsRef;
  my %datatypes = %$datatypesRef;
  foreach my $datatype (sort keys %fields) {
    my %curator;
    my $curTable = $datatype . '_curator';
    $result = $dbh->prepare( "SELECT * FROM $curTable" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) { $curator{$row[0]} = $row[1]; }

    foreach my $table (sort keys %{ $fields{$datatype} }) {
      next unless ($fields{$datatype}{$table}{ontology_type}); 
      my $ontType = $fields{$datatype}{$table}{ontology_type}; 
      if ($ontTypes{$ontType}) {
        my $type    = $fields{$datatype}{$table}{type}; 
        my $pgtable = $datatype . '_' . $table;
        $result = $dbh->prepare( "SELECT * FROM $pgtable" );
        $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
        while (my @row = $result->fetchrow) {
          my $thisCurator = $curator{$row[0]}; unless ($thisCurator) { $thisCurator = 'WBPerson13481'; } $thisCurator =~ s/WBPerson/two/;
          my @data;
          if ($type eq 'ontology') { push @data, $row[1]; }
            else {
              $row[1] =~ s/^"//; $row[1] =~ s/"$//;
              (@data) = split/","/, $row[1]; }
          foreach my $data (@data) {
            if ($invalidObj{$ontType}{$data}) {
              foreach my $newObj (sort keys %{ $invalidObj{$ontType}{$data} }) {
# if ( ($pgtable eq 'abp_gene') && ($row[0] eq '2') ) { print "IS INV $thisCurator CUR $ontType OT $pgtable PGT $row[0] PGID $data OLD $newObj NEW\n"; }
                $badData{$thisCurator}{$ontType}{$pgtable}{$row[0]}{old} = $data;
                $badData{$thisCurator}{$ontType}{$pgtable}{$row[0]}{new} = $newObj;
              } # foreach my $newObj (sort keys %{ $invalidObj{$ontType}{$data} })
            } # if ($invalidObj{$ontType}{$data})
          } # foreach my $data (@data)
        } # while (my @row = $result->fetchrow)
      } # if ($ontTypes{$ontType})
    } # foreach my $table (sort keys %{ $fields{$datatype} })
  } # foreach my $datatype (sort keys %fields)
} # foreach my $datatype (@datatypes)


my %stdname;
my (@curators) = sort keys %badData;
my $joinkeys = join"','", @curators;
$result = $dbh->prepare( "SELECT * FROM two_standardname WHERE joinkey IN ('$joinkeys')" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $stdname{$row[0]} = $row[2]; }

foreach my $curator (sort keys %badData) {
  print "\nCurator $curator $stdname{$curator} :\n";
  foreach my $ontType (sort keys %{ $badData{$curator} }) {
#     print "Ontology Type $ontType :\n";
    foreach my $pgtable (sort keys %{ $badData{$curator}{$ontType} }) {
#       print "PG Table $pgtable :\n";
      foreach my $pgid (sort {$a<=>$b} keys %{ $badData{$curator}{$ontType}{$pgtable} }) {
        my $old = $badData{$curator}{$ontType}{$pgtable}{$pgid}{old};
        next unless $old;
        my $new = $badData{$curator}{$ontType}{$pgtable}{$pgid}{new};
        print qq($curator\t$ontType\t$pgtable\t$pgid\twas $old\tnow $new\n);
      } # foreach my $pgid (sort keys %{ $badData{$curator}{$ontType}{$pgtable} })
    } # foreach my $pgtable (sort keys %{ $badData{$curator}{$ontType} })
  } # foreach my $ontType (sort keys %{ $badData{$curator} })
} # foreach my $curator (sort keys %badData)


sub populateInvalidObjects {
  $result = $dbh->prepare( "SELECT * FROM gin_dead" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    my @genes;
    if ($row[1] =~ m/(WBGene\d+)/) { (@genes) = $row[1] =~ m/(WBGene\d+)/; }
      else { push @genes, 'dead'; }
    foreach my $wbgene (@genes) {
      $invalidObj{'WBGene'}{"WBGene$row[0]"}{"$wbgene"}++; } }

# UNCOMMENT when transgene OA has mergedinto table
#   $result = $dbh->prepare( "SELECT trp_name.trp_name, trp_mergedinto.trp_mergedinto FROM trp_name, trp_mergedinto WHERE trp_name.joinkey = trp_mergedinto.joinkey;" );
#   $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
#   while (my @row = $result->fetchrow) {
#     $invalidObj{'Transgene'}{$row[0]}{$row[1]}++; }

  $result = $dbh->prepare( "SELECT * FROM pap_identifier WHERE pap_identifier ~ '^00'" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    $invalidObj{'WBPaper'}{"WBPaper$row[1]"}{"WBPaper$row[0]"}++; }
} # sub populateInvalidObjects


$result = $dbh->prepare( "SELECT * FROM two_comment" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
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

