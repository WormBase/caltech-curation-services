#!/usr/bin/perl -w

# fix WM prefixes according to
# https://docs.google.com/document/d/1K4lYpEqjrvjCcQalmvns4oywNagJTuPUTORUDseI2DA/edit#heading=h.r74ze94qkww
# for Kimberly  2023 03 03


# backup
# COPY pap_identifier TO '/home/postgres/work/pgpopulation/pap_papers/20230303_fix_wm/pap_identifier.pg';
# COPY h_pap_identifier TO '/home/postgres/work/pgpopulation/pap_papers/20230303_fix_wm/h_pap_identifier.pg';
# COPY pap_year TO '/home/postgres/work/pgpopulation/pap_papers/20230303_fix_wm/pap_year.pg';
# COPY h_pap_year TO '/home/postgres/work/pgpopulation/pap_papers/20230303_fix_wm/h_pap_year.pg';

# restore
# DELETE FROM pap_identifier;
# DELETE FROM h_pap_identifier;
# DELETE FROM pap_year;
# DELETE FROM h_pap_year;
# COPY pap_identifier FROM '/home/postgres/work/pgpopulation/pap_papers/20230303_fix_wm/pap_identifier.pg';
# COPY h_pap_identifier FROM '/home/postgres/work/pgpopulation/pap_papers/20230303_fix_wm/h_pap_identifier.pg';
# COPY pap_year FROM '/home/postgres/work/pgpopulation/pap_papers/20230303_fix_wm/pap_year.pg';
# COPY h_pap_year FROM '/home/postgres/work/pgpopulation/pap_papers/20230303_fix_wm/h_pap_year.pg';


use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;
my @pgcommands;

my @delete = qw( devgenewm2010_ab evowm2010_ab );
my %toDelete;
foreach my $ident (@delete) {
  $result = $dbh->prepare( "SELECT * FROM pap_identifier WHERE pap_identifier = '$ident';" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { $toDelete{$row[0]}{$row[1]}{$row[2]}++; } }
foreach my $joinkey (sort keys %toDelete) {
  foreach my $ident (sort keys %{ $toDelete{$joinkey} }) {
    foreach my $order (sort keys %{ $toDelete{$joinkey}{$ident} }) {
      push @pgcommands, qq(DELETE FROM pap_identifier WHERE joinkey = '$joinkey' AND pap_order = '$order' AND pap_identifier = '$ident';);
      push @pgcommands, qq(INSERT INTO h_pap_identifier VALUES ('$joinkey', NULL, '$order', 'two1843'););
    } # foreach my $order (sort keys %{ $toDelete{$joinkey}{$ident} })
  } # foreach my $ident (sort keys %{ $toDelete{$joinkey} })
} # foreach my $joinkey (sort keys %toDelete)


my %multi;
$result = $dbh->prepare( " SELECT * FROM pap_identifier WHERE pap_identifier ~ 'eawm2006ab';" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $multi{$row[1]}{$row[0]} = $row[2]; }
foreach my $ident (sort keys %multi) {
  my @paps = sort keys %{ $multi{$ident} };
  my $count = scalar @paps;
  if ($count > 1) {
    if ($count == 2) {
      my $keep = shift @paps;
      my $rename = shift @paps;
      my $newident = $ident;
      $newident =~ s/wm2006/wm2008/;
      my $order = $multi{$ident}{$rename};
      push @pgcommands, qq(DELETE FROM pap_identifier WHERE joinkey = '$rename' AND pap_order = '$order' AND pap_identifier = '$ident';);
      push @pgcommands, qq(INSERT INTO pap_identifier VALUES ('$rename', '$newident', '$order', 'two1843'););
      push @pgcommands, qq(INSERT INTO h_pap_identifier VALUES ('$rename', '$newident', '$order', 'two1843'););
      push @pgcommands, qq(DELETE FROM pap_year WHERE joinkey = '$rename';);
      push @pgcommands, qq(INSERT INTO pap_year VALUES ('$rename', '2008', NULL, 'two1843'););
      push @pgcommands, qq(INSERT INTO h_pap_year VALUES ('$rename', '2008', NULL, 'two1843'););
    } else {
      print qq($count\t);
      foreach my $pap (@paps) {
        my $order = $multi{$ident}{$pap};
        print qq($pap - $order\t);
      } # foreach my $pap (@paps)
      print qq(\n);
    }
  }
} # foreach my $ident (sort keys %multi)


foreach my $pgcommand (@pgcommands) {
  print qq($pgcommand\n);
# UNCOMMENT TO POPULATE
#   $dbh->do($pgcommand);
} # foreach my $pgcommand (@pgcommands)


__END__


my %exists;
$result = $dbh->prepare( "SELECT * FROM pap_identifier WHERE joinkey IN (SELECT joinkey FROM pap_identifier WHERE pap_identifier ~ '^10');" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[1] =~ s///g;
    $row[2] =~ s///g;
    $exists{$row[0]}{$row[1]} = $row[2]; } }

$result = $dbh->prepare( "SELECT * FROM pap_identifier WHERE pap_identifier ~ '^10';" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[1] =~ s///g;
    $row[2] =~ s///g;
    my $newval = 'doi' . $row[1];
    if ($exists{$row[0]}{$newval}) { 
      push @pgcommands, qq(DELETE FROM pap_identifier WHERE joinkey = '$row[0]' AND pap_order = '$row[2]';);
      push @pgcommands, qq(INSERT INTO h_pap_identifier VALUES ('$row[0]', NULL, '$row[2]', 'two1843'););
      print qq(EXISTS\t$row[0]\t$newval\tfrom order $row[2]\talready exists at order $exists{$row[0]}{$newval}\n); }
    else {
      print "$row[0]\t$row[1]\t$row[2]\tTO\t$newval\n";
      push @pgcommands, qq(DELETE FROM pap_identifier WHERE joinkey = '$row[0]' AND pap_order = '$row[2]';);
      push @pgcommands, qq(INSERT INTO pap_identifier VALUES ('$row[0]', '$newval', '$row[2]', 'two1843'););
      push @pgcommands, qq(INSERT INTO h_pap_identifier VALUES ('$row[0]', '$newval', '$row[2]', 'two1843'););
    }
  } # if ($row[0])
} # while (@row = $result->fetchrow)

foreach my $pgcommand (@pgcommands) {
  print qq($pgcommand\n);
# UNCOMMENT TO POPULATE
#   $dbh->do($pgcommand);
} # foreach my $pgcommand (@pgcommands)

__END__

backup
COPY pap_identifier TO '/home/postgres/work/pgpopulation/pap_papers/20230218_fix_doi/pap_identifier.pg';
COPY h_pap_identifier TO '/home/postgres/work/pgpopulation/pap_papers/20230218_fix_doi/h_pap_identifier.pg';

restore
DELETE FROM pap_identifier ;
DELETE FROM h_pap_identifier ;
COPY pap_identifier FROM '/home/postgres/work/pgpopulation/pap_papers/20230218_fix_doi/pap_identifier.pg';
COPY h_pap_identifier FROM '/home/postgres/work/pgpopulation/pap_papers/20230218_fix_doi/h_pap_identifier.pg';

