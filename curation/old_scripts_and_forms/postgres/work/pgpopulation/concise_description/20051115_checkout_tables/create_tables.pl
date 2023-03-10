#!/usr/bin/perl

# Create the allele-phenotype pg tables ( alp_ ) based on the form .cgi's
# &write();  2005 10 18

use strict;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");      # connect to postgres database
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $result;


my @tables = qw( cds locus comment grafitti checked_out updated_genelist ref_count );

foreach my $type (@tables) { $result = $conn->exec( "DROP TABLE cdc_$type;" ); }

foreach my $type (@tables) {
  my $pgcommand = "
CREATE TABLE cdc_$type (
    joinkey text, 
    cdc_$type text,
    cdc_timestamp timestamp with time zone DEFAULT \"timestamp\"('now'::text));" ;
  $result = $conn->exec( "$pgcommand" );
  print "$pgcommand\n";
  $pgcommand = "REVOKE ALL ON TABLE cdc_$type FROM PUBLIC;" ;
  $result = $conn->exec( "$pgcommand" );
  print "$pgcommand\n";
  $pgcommand = "GRANT SELECT ON TABLE cdc_$type TO acedb;" ;
  $result = $conn->exec( "$pgcommand" );
  print "$pgcommand\n";
  $pgcommand = "GRANT ALL ON TABLE cdc_$type TO apache;" ;
  $result = $conn->exec( "$pgcommand" );
  print "$pgcommand\n";
  $pgcommand = "GRANT ALL ON TABLE cdc_$type TO cecilia;" ;
  $result = $conn->exec( "$pgcommand" );
  print "$pgcommand\n";
  $pgcommand = "GRANT ALL ON TABLE cdc_$type TO azurebrd;" ;
  $result = $conn->exec( "$pgcommand" );
  print "$pgcommand\n";
  $pgcommand = "CREATE INDEX cdc_${type}_idx ON cdc_${type} USING btree (joinkey);" ;
  $result = $conn->exec( "$pgcommand" );
  print "$pgcommand\n"; }



__END__ 

my @genParams = qw ( type tempname finalname wbgene rnai_brief );
my @groupParams = qw ( curator paper person finished phenotype remark intx_desc );
my @multParams = qw ( not term go_sug suggested sug_ref sug_def genotype lifestage temperature strain preparation treatment delivered nature penetrance percent effect sensitivity degree func haplo );

my $result;

# DROP ALL TABLES
foreach my $type (@genParams) { $result = $conn->exec( "DROP TABLE alp_$type;" ); }
foreach my $type (@groupParams) { $result = $conn->exec( "DROP TABLE alp_$type;" ); }
foreach my $type (@multParams) { $result = $conn->exec( "DROP TABLE alp_$type;" ); }


foreach my $type (@genParams) {
  my $pgcommand = "
CREATE TABLE alp_$type (
    joinkey text, 
    alp_$type text,
    alp_timestamp timestamp with time zone DEFAULT \"timestamp\"('now'::text));" ;
  $result = $conn->exec( "$pgcommand" );
  print "$pgcommand\n";
  $pgcommand = "REVOKE ALL ON TABLE alp_$type FROM PUBLIC;" ;
  $result = $conn->exec( "$pgcommand" );
  print "$pgcommand\n";
  $pgcommand = "GRANT SELECT ON TABLE alp_$type TO acedb;" ;
  $result = $conn->exec( "$pgcommand" );
  print "$pgcommand\n";
  $pgcommand = "GRANT ALL ON TABLE alp_$type TO apache;" ;
  $result = $conn->exec( "$pgcommand" );
  print "$pgcommand\n";
  $pgcommand = "GRANT ALL ON TABLE alp_$type TO cecilia;" ;
  $result = $conn->exec( "$pgcommand" );
  print "$pgcommand\n";
  $pgcommand = "GRANT ALL ON TABLE alp_$type TO azurebrd;" ;
  $result = $conn->exec( "$pgcommand" );
  print "$pgcommand\n";
  $pgcommand = "CREATE INDEX alp_${type}_idx ON alp_${type} USING btree (joinkey);" ;
  $result = $conn->exec( "$pgcommand" );
  print "$pgcommand\n"; }

foreach my $type (@groupParams) {
  my $pgcommand = "
CREATE TABLE alp_$type (
    joinkey text, 
    alp_box text,
    alp_$type text,
    alp_timestamp timestamp with time zone DEFAULT \"timestamp\"('now'::text));" ;
  $result = $conn->exec( "$pgcommand" );
  print "$pgcommand\n";
  $pgcommand = "REVOKE ALL ON TABLE alp_$type FROM PUBLIC;" ;
  $result = $conn->exec( "$pgcommand" );
  print "$pgcommand\n";
  $pgcommand = "GRANT SELECT ON TABLE alp_$type TO acedb;" ;
  $result = $conn->exec( "$pgcommand" );
  print "$pgcommand\n";
  $pgcommand = "GRANT ALL ON TABLE alp_$type TO apache;" ;
  $result = $conn->exec( "$pgcommand" );
  print "$pgcommand\n";
  $pgcommand = "GRANT ALL ON TABLE alp_$type TO cecilia;" ;
  $result = $conn->exec( "$pgcommand" );
  print "$pgcommand\n";
  $pgcommand = "GRANT ALL ON TABLE alp_$type TO azurebrd;" ;
  $result = $conn->exec( "$pgcommand" );
  print "$pgcommand\n";
  $pgcommand = "CREATE INDEX alp_${type}_idx ON alp_${type} USING btree (joinkey);" ;
  $result = $conn->exec( "$pgcommand" );
  print "$pgcommand\n"; }

foreach my $type (@multParams) {
  my $pgcommand = "
CREATE TABLE alp_$type (
    joinkey text, 
    alp_box text,
    alp_column text,
    alp_$type text,
    alp_timestamp timestamp with time zone DEFAULT \"timestamp\"('now'::text));" ;
  $result = $conn->exec( "$pgcommand" );
  print "$pgcommand\n";
  $pgcommand = "REVOKE ALL ON TABLE alp_$type FROM PUBLIC;" ;
  $result = $conn->exec( "$pgcommand" );
  print "$pgcommand\n";
  $pgcommand = "GRANT SELECT ON TABLE alp_$type TO acedb;" ;
  $result = $conn->exec( "$pgcommand" );
  print "$pgcommand\n";
  $pgcommand = "GRANT ALL ON TABLE alp_$type TO apache;" ;
  $result = $conn->exec( "$pgcommand" );
  print "$pgcommand\n";
  $pgcommand = "GRANT ALL ON TABLE alp_$type TO cecilia;" ;
  $result = $conn->exec( "$pgcommand" );
  print "$pgcommand\n";
  $pgcommand = "GRANT ALL ON TABLE alp_$type TO azurebrd;" ;
  $result = $conn->exec( "$pgcommand" );
  print "$pgcommand\n";
  $pgcommand = "CREATE INDEX alp_${type}_idx ON alp_${type} USING btree (joinkey);" ;
  $result = $conn->exec( "$pgcommand" );
  print "$pgcommand\n"; }
