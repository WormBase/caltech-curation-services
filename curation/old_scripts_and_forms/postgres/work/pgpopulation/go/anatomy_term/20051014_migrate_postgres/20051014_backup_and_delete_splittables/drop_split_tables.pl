#!/usr/bin/perl -w


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
                         goinference_two aoinference comment);

  foreach my $type (@PGsubparameters) {
    my @subtypes = qw( bio_ cell_ mol_ );
    foreach my $subt ( @subtypes ) {
      my $type = $subt . $type;
      for my $i (1 .. 8) {
#         my $result = $conn->exec( "COPY got_${type}$i TO '/home/postgres/work/pgpopulation/anatomy_term/20051114_migrate_postgres/20051014_backup_and_delete_splittables/got_${type}${i}.pg'; " );
        my $result = $conn->exec( "DROP TABLE got_${type}$i ; " );
      } # for my $i (1 .. 8)
    } # foreach my $subt ( @subtypes )
  } # foreach my $type (@PGsubparameters)
