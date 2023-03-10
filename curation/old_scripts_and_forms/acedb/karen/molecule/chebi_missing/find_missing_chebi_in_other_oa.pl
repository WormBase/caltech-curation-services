#!/usr/bin/perl -w

# find molecule entries missing chebi that exist in other OAs.  2014 04 30

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my @tables = qw( app_molecule  grg_moleculeregulator  pro_molecule  rna_molecule );
my %tables;
$tables{'app'}{'molecule'}++;
$tables{'grg'}{'moleculeregulator'}++;
$tables{'pro'}{'molecule'}++;
$tables{'rna'}{'molecule'}++;
$tables{'mop'}{'paper'}++;

my @refTables = qw( mop_publicname mop_molecule mop_chemi mop_paper mop_smmid );

my %papToPmid;
$result = $dbh->prepare( "SELECT * FROM pap_identifier WHERE pap_identifier ~ 'pmid' ;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $papToPmid{"WBPaper$row[0]"} = $row[1]; }

my %pgidToMol; 
$result = $dbh->prepare( "SELECT * FROM mop_name ;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $pgidToMol{$row[0]} = $row[1]; }

my %noChebi; my %molData;
$result = $dbh->prepare( "SELECT * FROM mop_name WHERE joinkey NOT IN (SELECT joinkey FROM mop_chebi);" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { 
  $noChebi{molToPgid}{$row[1]} = $row[0]; 
  $noChebi{pgidToMol}{$row[0]} = $row[1]; 
  $molData{$row[1]}{mop_name}{$row[1]}++; 
} 

my $pgids = join"','", sort keys %{ $noChebi{pgidToMol} };
foreach my $refTable (@refTables) {
  my $result = $dbh->prepare( "SELECT * FROM $refTable WHERE joinkey IN ('$pgids');" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { 
    my $molId = $pgidToMol{$row[0]};
    $molData{$molId}{$refTable}{$row[1]}++;
  } # while (my @row = $result->fetchrow)
} # foreach my $refTable (@refTables)

my %notFound;
foreach my $prefix (sort keys %tables) {
  foreach my $tablePart (sort keys %{ $tables{$prefix} }) {
    my $pgtable = $prefix . '_' . $tablePart;
    $result = $dbh->prepare( "SELECT * FROM $pgtable;" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) {
      my $otherRefTable = $prefix . '_paper';
      if ($prefix eq 'mop') {
          my $mol = $pgidToMol{$row[0]};
          if ($noChebi{molToPgid}{$mol}) { 
            $molData{$mol}{$prefix}{$row[0]}++;
#             $molData{$mol}{$otherRefTable} = $row[1];		# already have this stored from refTables
            $notFound{$mol}{$prefix}++; } }
        else {
          my $pgidOther = $row[0];
          my (@mols) = $row[1] =~ m/(WBMol:\d+)/g;
          foreach my $mol (@mols) {
            if ($noChebi{molToPgid}{$mol}) { 
              $notFound{$mol}{$prefix}++;
              $molData{$mol}{$prefix}{$pgidOther}++;
              my $pgidMol = $noChebi{molToPgid}{$mol};
              my $result2 = $dbh->prepare( "SELECT * FROM $otherRefTable WHERE joinkey = '$pgidOther';" );
              $result2->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
              while (my @row2 = $result2->fetchrow) {
                if ($row2[1]) { 
                  $molData{$mol}{$otherRefTable}{$row2[1]}++; 
        } } } } }
    } # while (my @row = $result->fetchrow)
  } # foreach my $tablePart (sort keys %{ $tables{$prefix} })
} # foreach my $prefix (sort keys %tables)

foreach my $mol (sort keys %notFound) {
  my ($publicname, @nothing) = sort keys %{ $molData{$mol}{'mop_publicname'} };
  print "$mol\t$publicname\n";
  my %aggPapers; my %aggPmids;
  foreach my $table (sort keys %{ $molData{$mol} }) {
    next if ( ($table =~ m/_publicname/) || ($table =~ m/_name/) );
    my $data = join", ", sort keys %{ $molData{$mol}{$table} };
    print "$table\t$data\n";
    if ($data =~ m/(WBPaper\d+)/) { my (@paps) = $data =~ m/(WBPaper\d+)/g; foreach (@paps) { $aggPapers{$_}++; } }
  } #foreach my $table (sort keys %{ $molData{$mol} })
  foreach my $pap (sort keys %aggPapers) { 
    if ($papToPmid{$pap}) { $aggPmids{$papToPmid{$pap}}++; }
      else { $aggPmids{$pap}++; } }				# keep those that are not PMIDs as WBPaper
  my $aggPapers = join", ", sort keys %aggPapers;
  print "aggregatedWBPapers\t$aggPapers\n";
  my $aggPmids = join", ", sort keys %aggPmids;
  print "aggregatedWBPmids\t$aggPmids\n";
  print "\n";
#   print "$mol\n";
} # foreach my $mol (sort keys %notFound)

