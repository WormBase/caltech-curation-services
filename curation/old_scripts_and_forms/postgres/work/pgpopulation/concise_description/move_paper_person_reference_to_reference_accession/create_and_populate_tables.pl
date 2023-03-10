#!/usr/bin/perl

# merge data from car_whatever_ref_paper and car_whatever_ref_person into
# car_whatever_ref_reference (and create that table) and create
# car_whatever_ref_accession (for con and seq).
# create car_con_last_verified to store latest timestamp of verification.
# populate with latest time any car_con data changed.
# (also wipeout these tables before creating as part of testing process)
#
# usage : ./create_and_populate_tables.pl
# 2005 05 12
#
# Final run created  2005 07 05


use strict;
use diagnostics;
use Pg;

# my @types = qw( bio con exp fpa fpi mol oth phe seq );
my @types = qw( bio con exp fpa fpi mol oth seq );		# no longer have phenotype 2005 05 16

my @acc_types = qw( con seq );

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my %theHash;

my $result;

foreach my $type (@types) {
  $result = $conn->exec( "DROP INDEX car_${type}_ref_reference_idx; " );
  $result = $conn->exec( "DROP TABLE car_${type}_ref_reference; " );
  if ($type eq 'con') { 
    $result = $conn->exec( "CREATE TABLE car_${type}_ref_reference ( joinkey text, car_${type}_ref_reference text, car_timestamp timestamp with time zone DEFAULT \"timestamp\"('now'::text)); " ); }
  else {
    $result = $conn->exec( "CREATE TABLE car_${type}_ref_reference ( joinkey text, car_order integer, car_${type}_ref_reference text, car_timestamp timestamp with time zone DEFAULT \"timestamp\"('now'::text)); " ); }
  $result = $conn->exec( "REVOKE ALL ON TABLE car_${type}_ref_reference FROM PUBLIC;" );
  $result = $conn->exec( "GRANT ALL ON TABLE car_${type}_ref_reference TO acedb;" );
  $result = $conn->exec( "GRANT ALL ON TABLE car_${type}_ref_reference TO apache; " );
  $result = $conn->exec( "CREATE INDEX car_${type}_ref_reference_idx ON car_${type}_ref_reference USING btree (joinkey); " );
}

$result = $conn->exec( "DROP INDEX car_con_last_verified_idx; " );
$result = $conn->exec( "DROP TABLE car_con_last_verified; " );
$result = $conn->exec( "CREATE TABLE car_con_last_verified ( joinkey text, car_con_last_verified text, car_timestamp timestamp with time zone DEFAULT \"timestamp\"('now'::text)); " ); 
$result = $conn->exec( "REVOKE ALL ON TABLE car_con_last_verified FROM PUBLIC;" );
$result = $conn->exec( "GRANT ALL ON TABLE car_con_last_verified TO acedb;" );
$result = $conn->exec( "GRANT ALL ON TABLE car_con_last_verified TO apache; " );
$result = $conn->exec( "CREATE INDEX car_con_last_verified_idx ON car_con_last_verified USING btree (joinkey); " );

foreach my $type (@acc_types) {
  $result = $conn->exec( "DROP INDEX car_${type}_ref_accession_idx; " );
  $result = $conn->exec( "DROP TABLE car_${type}_ref_accession; " );
  if ($type eq 'con') { $result = $conn->exec( "CREATE TABLE car_${type}_ref_accession ( joinkey text, car_${type}_ref_accession text, car_timestamp timestamp with time zone DEFAULT \"timestamp\"('now'::text) ); "
); }
  else {
    $result = $conn->exec( "CREATE TABLE car_${type}_ref_accession ( joinkey text, car_order integer, car_${type}_ref_accession text, car_timestamp timestamp with time zone DEFAULT \"timestamp\"('now'::text) ); " ); }
  $result = $conn->exec( "REVOKE ALL ON TABLE car_${type}_ref_accession FROM PUBLIC; ");
  $result = $conn->exec( "GRANT ALL ON TABLE car_${type}_ref_accession TO acedb; ");
  $result = $conn->exec( "GRANT ALL ON TABLE car_${type}_ref_accession TO apache; ");
  $result = $conn->exec( "CREATE INDEX car_${type}_ref_accession_idx ON car_${type}_ref_accession USING btree (joinkey); " );
}


foreach my $type (@types) {
  $result = $conn->exec( "SELECT * FROM car_${type}_ref_paper ORDER BY car_timestamp DESC; " );
  while (my @row = $result->fetchrow) {
    if ($row[0]) { 
      $row[0] =~ s///g; $row[1] =~ s///g; $row[2] =~ s///g; $row[3] =~ s///g;
      my $joinkey = shift(@row);
      my $order = 0;
      unless ($type eq 'con') { $order = shift(@row); }
      unless ($theHash{$type}{$joinkey}{$order}{paper}{value}) {
        $theHash{$type}{$joinkey}{$order}{paper}{value} = shift(@row);
        $theHash{$type}{$joinkey}{$order}{paper}{timestamp} = shift(@row);
        $theHash{$type}{$joinkey}{$order}{paper}{time} = $theHash{$type}{$joinkey}{$order}{paper}{timestamp};
        if ($theHash{$type}{$joinkey}{$order}{paper}{time} =~ m/\D/g) { $theHash{$type}{$joinkey}{$order}{paper}{time} =~ s/\D//g; }
      }
    } } 
  $result = $conn->exec( "SELECT * FROM car_${type}_ref_person ORDER BY car_timestamp DESC; " );
  while (my @row = $result->fetchrow) {
    if ($row[0]) { 
      $row[0] =~ s///g; $row[1] =~ s///g; $row[2] =~ s///g; $row[3] =~ s///g;
      my $joinkey = shift(@row);
      my $order = 0;
      unless ($type eq 'con') { $order = shift(@row); }
      unless ($theHash{$type}{$joinkey}{$order}{person}{value}) {
        $theHash{$type}{$joinkey}{$order}{person}{value} = shift(@row);
        $theHash{$type}{$joinkey}{$order}{person}{timestamp} = shift(@row);
        $theHash{$type}{$joinkey}{$order}{person}{time} = $theHash{$type}{$joinkey}{$order}{person}{timestamp};
        if ($theHash{$type}{$joinkey}{$order}{person}{time} =~ m/\D+/) { 
          $theHash{$type}{$joinkey}{$order}{person}{time} =~ s/\D+//g; 
          ($theHash{$type}{$joinkey}{$order}{person}{time}) = $theHash{$type}{$joinkey}{$order}{person}{time} =~ m/^\d{14}/g; }
      }
    } } 
  foreach my $joinkey (sort keys %{ $theHash{$type} } ) {
    foreach my $order (sort keys %{ $theHash{$type}{$joinkey} } ) { 
      my $time = 0;
      my $timestamp = 'CURRENT_TIMESTAMP';
      if ($theHash{$type}{$joinkey}{$order}{paper}{time}) {
        if ($theHash{$type}{$joinkey}{$order}{paper}{time} > $time) { 
          $time = $theHash{$type}{$joinkey}{$order}{paper}{time}; 
          $timestamp = $theHash{$type}{$joinkey}{$order}{paper}{timestamp}; } }
      if ($theHash{$type}{$joinkey}{$order}{person}{time}) { 
        if ($theHash{$type}{$joinkey}{$order}{person}{time} > $time) { 
          $time = $theHash{$type}{$joinkey}{$order}{person}{time}; 
          $timestamp = $theHash{$type}{$joinkey}{$order}{person}{timestamp}; } }
      my $value = '';
      if ($theHash{$type}{$joinkey}{$order}{paper}{value}) { $value .= ", " .  $theHash{$type}{$joinkey}{$order}{paper}{value}; }
      if ($theHash{$type}{$joinkey}{$order}{person}{value}) { $value .= ", " .  $theHash{$type}{$joinkey}{$order}{person}{value}; }
      if ($value) {
        $value =~ s/^,\s+//g;
        if ($type eq 'con') {
#           print "INSERT INTO car_${type}_ref_reference VALUES ('$joinkey', '$value', '$timestamp');\n " ;
          $result = $conn->exec( "INSERT INTO car_${type}_ref_reference VALUES ('$joinkey', '$value', '$timestamp'); " );
          $result = $conn->exec( "INSERT INTO car_con_last_verified VALUES ('$joinkey', '$value', '$timestamp'); " ); }
        else {
          $result = $conn->exec( "INSERT INTO car_${type}_ref_reference VALUES ('$joinkey', $order, '$value', '$timestamp'); " ); } }
      else {
        if ($type eq 'con') {
          $result = $conn->exec( "INSERT INTO car_${type}_ref_reference VALUES ('$joinkey', NULL, '$timestamp'); " );
          $result = $conn->exec( "INSERT INTO car_con_last_verified VALUES ('$joinkey', NULL, '$timestamp'); " ); }
        else {
          $result = $conn->exec( "INSERT INTO car_${type}_ref_reference VALUES ('$joinkey', $order, NULL, '$timestamp'); " ); } }
      if ( $type eq 'con' ) {
        $result = $conn->exec( "INSERT INTO car_${type}_ref_accession VALUES ('$joinkey', NULL, '$timestamp'); " ); }
      if ( $type eq 'seq' ) {
        $result = $conn->exec( "INSERT INTO car_${type}_ref_accession VALUES ('$joinkey', $order, NULL, '$timestamp'); " ); }
       
    } # foreach my $order (sort keys %{ $theHash{$type}{$joinkey} } ) 
  } # foreach my $joinkey (sort keys %{ $theHash{$type} } )
} # foreach my $type (@types)


__END__


while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[1] =~ s///g;
    $row[2] =~ s///g;
    print "$row[0]\t$row[1]\t$row[2]\n";
  } # if ($row[0])
} # while (@row = $result->fetchrow)



# car_bio_ref_paper
# car_bio_ref_person
# car_con_ref_paper
# car_con_ref_person
# car_exp_ref_paper
# car_exp_ref_person
# car_fpa_ref_paper
# car_fpa_ref_person
# car_fpi_ref_paper
# car_fpi_ref_person
# car_mol_ref_paper
# car_mol_ref_person
# car_oth_ref_paper
# car_oth_ref_person
# car_phe_ref_paper
# car_phe_ref_person
# car_seq_ref_paper
# car_seq_ref_person
# 
# CREATE TABLE car_con_ref_person (
#     joinkey text,
#     car_con_ref_person text,
#     car_timestamp timestamp with time zone DEFAULT "timestamp"('now'::text)
# ); 
# REVOKE ALL ON TABLE car_con_ref_person FROM PUBLIC;
# GRANT ALL ON TABLE car_con_ref_person TO acedb;
# GRANT ALL ON TABLE car_con_ref_person TO apache;
# 
# CREATE TABLE car_con_ref_paper (
#     joinkey text,
#     car_con_ref_paper text,
#     car_timestamp timestamp with time zone DEFAULT "timestamp"('now'::text)
# );
# REVOKE ALL ON TABLE car_con_ref_paper FROM PUBLIC;
# GRANT ALL ON TABLE car_con_ref_paper TO acedb;
# GRANT ALL ON TABLE car_con_ref_paper TO apache;
# 
# 
# CREATE TABLE car_seq_ref_person (
#     joinkey text,
#     car_order integer,
#     car_seq_ref_person text,
#     car_timestamp timestamp with time zone DEFAULT "timestamp"('now'::text)
# );
# REVOKE ALL ON TABLE car_seq_ref_person FROM PUBLIC;
# GRANT ALL ON TABLE car_seq_ref_person TO acedb;
# GRANT ALL ON TABLE car_seq_ref_person TO apache;
#     
# CREATE TABLE car_seq_ref_paper ( 
#     joinkey text,
#     car_order integer,
#     car_seq_ref_paper text,
#     car_timestamp timestamp with time zone DEFAULT "timestamp"('now'::text)
# );
# REVOKE ALL ON TABLE car_seq_ref_paper FROM PUBLIC;
# GRANT ALL ON TABLE car_seq_ref_paper TO acedb;
# GRANT ALL ON TABLE car_seq_ref_paper TO apache;

