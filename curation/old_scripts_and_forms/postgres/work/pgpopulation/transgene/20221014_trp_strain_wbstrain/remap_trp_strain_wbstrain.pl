#!/usr/bin/perl -w

# remap strain names to WBStrain IDs for Karen.  
# create new entries instead of replacing old values with new values to keep old timestamps.
# 2022 11 14
# 
# ran on tazendra 2022 11 15


use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %strainToWBStrain;
$result = $dbh->prepare( "SELECT * FROM obo_name_strain" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[1] =~ s///g;
    $strainToWBStrain{$row[1]} = $row[0];
  } # if ($row[0])
} # while (@row = $result->fetchrow)


my @pgcommands;
# $result = $dbh->prepare( "SELECT * FROM trp_strain_hst WHERE trp_strain_hst !~ 'WBSt';" );
$result = $dbh->prepare( "SELECT * FROM trp_strain WHERE trp_strain !~ 'WBSt';" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[1]) { 
    my (@strains) = split/\|/, $row[1];
    my %wbs;
    foreach my $strain (@strains) {
      $strain =~ s/\s+//g;
      if ($strainToWBStrain{$strain}) { 
        $wbs{$strainToWBStrain{$strain}}++;
      } else {
        print qq(@row\n);
    } }
    my $wbs = join'","', sort keys %wbs;
# use these to populate
#     print qq($row[0]\t"$wbs"\n);
    push @pgcommands, qq(DELETE FROM trp_strain WHERE joinkey = '$row[0]');
    push @pgcommands, qq(INSERT INTO trp_strain VALUES ('$row[0]', '"$wbs"'));
    push @pgcommands, qq(INSERT INTO trp_strain_hst VALUES ('$row[0]', '"$wbs"'));
} }

foreach my $pgcommand (@pgcommands) {
  print qq($pgcommand\n);
# UNCOMMENT TO POPULATE
#   $dbh->do($pgcommand);
}

__END__

COPY trp_strain TO '/home/postgres/work/pgpopulation/transgene/20221014_trp_strain_wbstrain/trp_strain.pg';
COPY trp_strain_hst TO '/home/postgres/work/pgpopulation/transgene/20221014_trp_strain_wbstrain/trp_strain_hst.pg';

# don't have all values in mangolassi, dump from tazendra and load here
COPY obo_name_strain TO '/home/postgres/work/pgpopulation/transgene/20221014_trp_strain_wbstrain/obo_name_strain_tazendra.pg';
COPY obo_name_strain FROM '/home/postgres/work/pgpopulation/transgene/20221014_trp_strain_wbstrain/obo_name_strain_tazendra.pg';
