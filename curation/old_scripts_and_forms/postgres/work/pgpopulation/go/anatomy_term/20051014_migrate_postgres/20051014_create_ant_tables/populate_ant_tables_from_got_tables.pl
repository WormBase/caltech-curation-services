#!/usr/bin/perl -w

# COPY anatomy_term pg_table data from got_ pg tables  2005 10 14

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my %anat;
my $result = $conn->exec( "SELECT * FROM got_anatomy_term WHERE got_anatomy_term IS NOT NULL;" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $anat{$row[0]}++; } }

my @PGparameters = qw(curator anatomy_term);
my @PGsubparameters = qw( goterm goid paper_evidence person_evidence goinference
                          goinference_two aoinference comment qualifier
			  qualifier_two similarity with with_two );


  foreach my $type (@PGparameters) {
    my $table = "got_" . $type;
    print "$table\n";
    my $ana_table = "ant_" . $type;
    my $result = $conn->exec( "COPY $table TO '/home/postgres/work/pgpopulation/anatomy_term/20051114_migrate_postgres/20051014_create_ant_tables/${table}.pg'; ");
    $result = $conn->exec( "COPY $ana_table FROM '/home/postgres/work/pgpopulation/anatomy_term/20051114_migrate_postgres/20051014_create_ant_tables/${table}.pg'; ");
  } # foreach my $type (@PGparameters)

  my @subtypes = qw( bio_ cell_ mol_ );
  foreach my $subt ( @subtypes ) {
    foreach my $type (@PGsubparameters) {
      my $type = $subt . $type;
      my $table = "got_" . $type;
      print "$table\n";
      my $ana_table = "ant_" . $type;
      my $result = $conn->exec( "COPY $table TO '/home/postgres/work/pgpopulation/anatomy_term/20051114_migrate_postgres/20051014_create_ant_tables/${table}.pg'; ");
      $result = $conn->exec( "COPY $ana_table FROM '/home/postgres/work/pgpopulation/anatomy_term/20051114_migrate_postgres/20051014_create_ant_tables/${table}.pg'; ");
    } # foreach my $subt ( @subtypes )
  } # foreach my $type (@PGsubparameters)
