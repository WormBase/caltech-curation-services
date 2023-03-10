#!/usr/bin/perl

# Create the allele-phenotype pg tables ( alp_ ) based on the form .cgi's
# &write();  2005 10 18
#
# Added quantity_remark and quantity for Carol  2005 11 22

use strict;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");      # connect to postgres database
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;


my @genParams = qw ( type tempname finalname wbgene rnai_brief );
my @groupParams = qw ( curator paper person finished phenotype remark intx_desc );
my @multParams = qw ( not term quantity_remark quantity go_sug suggested sug_ref sug_def genotype lifestage temperature strain preparation treatment delivered nature penetrance percent mat_effect pat_effect heat_sens cold_sens heat_degree cold_degree func haplo );

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
