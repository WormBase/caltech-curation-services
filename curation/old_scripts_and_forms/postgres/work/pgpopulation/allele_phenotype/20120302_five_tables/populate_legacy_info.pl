#!/usr/bin/perl -w

# populate  legacy_information.txt  data to  app_legacyinfo  2012 03 02
# live run 2012 03 11


use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %data;
my $pgid = &getHighestPgid();
my @pgcommands;

# print "PGID $pgid\n";

my $infile = 'legacy_information.txt';
open (IN, "<$infile") or die "Cannot open $infile : $!";
my $junk = <IN>;
while (my $line = <IN>) {
  chomp $line;
  $line =~ s/^\"//; $line =~ s/\"$//;
  my ($wbgene, $locus, $info, @junk) = split/";"/, $line;
  next unless ($info =~ m/^\[C\.elegansII\]/);
#   if (scalar @junk > 0) { print "ERR $line\n"; }
  $info = "$wbgene | $info";
  &addToApp($info);
#   print "$info\n";
} # while (my $line = <IN>)
close (IN) or die "Cannot close $infile : $!";

# "WBGene00004929";"soc-2";"[C.elegansII] n1774 : suppressor of clr-1.  OA1. [DeVore et al. 1995; NH]"

foreach my $command (@pgcommands) {
  print "$command\n";
# UNCOMMENT TO TRANSFER DATA
#   my $result2 = $dbh->do( $command );
} # foreach my $command (@pgcommands)


sub addToApp {
  my ($info) = @_;
  if ($info =~ m/\'/) { $info =~ s/\'/''/g; }
  my $curator = 'WBPerson712';
  my $fail = 'down_right_disgusted';
  my $person = '"WBPerson261"';
  $pgid++;
  push @pgcommands, "INSERT INTO app_legacyinfo VALUES ('$pgid', '$info')";
  push @pgcommands, "INSERT INTO app_legacyinfo_hst VALUES ('$pgid', '$info')";
  push @pgcommands, "INSERT INTO app_person VALUES ('$pgid', '$person')";
  push @pgcommands, "INSERT INTO app_person_hst VALUES ('$pgid', '$person')";
  push @pgcommands, "INSERT INTO app_curator VALUES ('$pgid', '$curator')";
  push @pgcommands, "INSERT INTO app_curator_hst VALUES ('$pgid', '$curator')";
  push @pgcommands, "INSERT INTO app_curation_status VALUES ('$pgid', '$fail')";
  push @pgcommands, "INSERT INTO app_curation_status_hst VALUES ('$pgid', '$fail')";
} # sub addToApp

sub getHighestPgid {                                    # get the highest joinkey from the primary tables
  my @highestPgidTables            = qw( strain rearrangement transgene variation curator );
  my $datatype = 'app';
  my $pgUnionQuery = "SELECT MAX(joinkey::integer) FROM ${datatype}_" . join" UNION SELECT MAX(joinkey::integer) FROM ${datatype}_", @highestPgidTables;
  my $result = $dbh->prepare( "SELECT max(max) FROM ( $pgUnionQuery ) AS max; " );
  $result->execute(); my @row = $result->fetchrow(); my $highest = $row[0];
  return $highest;
} # sub getHighestPgid


__END__

DELETE FROM app_legacyinfo          WHERE app_timestamp > '2012-03-02 01:00';
DELETE FROM app_legacyinfo_hst      WHERE app_timestamp > '2012-03-02 01:00';
DELETE FROM app_curator 	    WHERE app_timestamp > '2012-03-02 01:00';
DELETE FROM app_curator_hst 	    WHERE app_timestamp > '2012-03-02 01:00';
DELETE FROM app_curation_status     WHERE app_timestamp > '2012-03-02 01:00';
DELETE FROM app_curation_status_hst WHERE app_timestamp > '2012-03-02 01:00';
