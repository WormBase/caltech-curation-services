#!/usr/bin/perl -w

# CREATE gom_ tables or GO Meeting registration.  (and sequence)
# for 
# http://tazendra.caltech.edu/~postgres/cgi-bin/cecilia/gom_display.cgi
# and
# http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/go_consortium_registration.cgi
# 2005 02 07


use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $outfile = "outfile";
open(OUT, ">$outfile") or die "Cannot create $outfile : $!";

my @all_vars = qw ( Reg_fee Diet Country PostalCode State City Street
Institution Department URL FAX Phone Email Last_Name First_Name );

foreach my $var (reverse @all_vars) {
  my $table = 'gom_' . lc($var);
  my $result = $conn->exec( "
  CREATE TABLE $table (
    joinkey text,
    $table text,
    gom_timestamp timestamp with time zone DEFAULT \"timestamp\"('now'::text)
  ); " );
  $result = $conn->exec(" REVOKE ALL ON TABLE $table FROM PUBLIC; ");
  $result = $conn->exec(" GRANT SELECT ON TABLE $table TO acedb; ");
  $result = $conn->exec(" GRANT ALL ON TABLE $table TO apache; ");
  $result = $conn->exec(" GRANT ALL ON TABLE $table TO cecilia; ");
  $result = $conn->exec(" CREATE UNIQUE INDEX ${table}_idx ON wbg_lastname USING btree (joinkey); ");


} # foreach my $var (reverse @all_vars)

__END__

CREATE SEQUENCE gom_sequence
    START 1
    INCREMENT 1
    MAXVALUE 2147483647
    MINVALUE 1
    CACHE 1;
REVOKE ALL ON TABLE gom_sequence FROM PUBLIC;
GRANT SELECT ON TABLE gom_sequence TO acedb;
GRANT ALL ON TABLE gom_sequence TO apache;


# my %pos;
# my %temp_aka;
# my %aka;
# 
# my $result = $conn->exec( "SELECT * FROM pap_possible WHERE pap_possible IS NOT NULL;" ); 
# while (my @row = $result->fetchrow) {
#   if ($row[0]) { 
#     $row[1] =~ s/\".*$//g;
#     $pos{$row[2]}{$row[1]}++; } }
# 
# my @tables = qw (first middle last);
