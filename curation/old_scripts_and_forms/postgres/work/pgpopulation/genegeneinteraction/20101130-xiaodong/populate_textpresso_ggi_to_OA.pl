#!/usr/bin/perl -w

# populate sentid tables for interaction curation.  obo_name_int_sentid, obo_data_int_sentid, int_curator, int_sentid
# 2010 12 03
#
# changed assocation to green for X  2010 12 06

# TODO remove deletions, they're only for testing.  2010 12 03

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my $directory = '/home/postgres/work/pgpopulation/genegeneinteraction/20101130-xiaodong';
chdir($directory) or die "Cannot go to $directory ($!)";

my @del_pgcommands;
my @obo_pgcommands;
my @int_pgcommands;

my %obo_sentid;

$result = $dbh->prepare( " SELECT * FROM obo_name_int_sentid; " );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { if ($row[1]) { $obo_sentid{$row[1]}++; } }

my %colorMap;
$colorMap{'gene_celegans'} = 'red';
$colorMap{'regulation'} = 'blue';
$colorMap{'association'} = 'green';

my $joinkey = '1';
$result = $dbh->prepare( " SELECT * FROM int_curator ORDER BY joinkey::integer DESC; " );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
my @row = $result->fetchrow();
if ($row[0]) { $joinkey = $row[0]; } 
  else { die "ERROR no starting joinkey from int_curator to populate int_ tables\n"; }

push @del_pgcommands, "DELETE FROM obo_name_int_sentid WHERE obo_timestamp > '2010-12-03';";
push @del_pgcommands, "DELETE FROM obo_data_int_sentid WHERE obo_timestamp > '2010-12-03';";
push @del_pgcommands, "DELETE FROM int_sentid WHERE int_timestamp > '2010-12-03';";
push @del_pgcommands, "DELETE FROM int_curator WHERE int_timestamp > '2010-12-03';";

my $infile = 'new_ggi_20101130';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) {
  chomp $line;
  my ($a, $sid, $b, $c, $sentence) = split/\t/, $line;
  unless ($sid) { print "ERROR, no sentence ID for $line\n"; }
  unless ($sentence) { print "ERROR, no sentence data for $line\n"; }
  next unless ($sid || $sentence);
  if ($sid =~ m/\'/) { $sid =~ s/\'//g; }			# strip any ' from sentence ID (shouldn't be any)
  next if ($obo_sentid{$sid});					# skip sentence IDs that have already been read
  if ($sentence =~ m/\'/) { $sentence =~ s/\'/''/g; }		# escape ' from sentence
  foreach my $tag (sort keys %colorMap) {
    if ($sentence =~ m/<$tag>/) { 
      $sentence =~ s/<$tag>/<span style=\"color: $colorMap{$tag};\">/g;
      $sentence =~ s/<\/$tag>/<\/span>/g; } }
  push @obo_pgcommands, "INSERT INTO obo_name_int_sentid VALUES ('$sid', '$sid');";
  push @obo_pgcommands, "INSERT INTO obo_data_int_sentid VALUES ('$sid', 'sentence ID : $sid\nsentence data : $sentence');";
  $joinkey++;
    # int_ data goes in in reverse so that when queried by reverse timestamp they'll be in order.  joinkeys are still assigned in sentence order so that later queries by pgid would have them in order.
  unshift @int_pgcommands, "INSERT INTO int_sentid VALUES ('$joinkey', '$sid');";
  unshift @int_pgcommands, "INSERT INTO int_curator VALUES ('$joinkey', 'WBPerson4793');";
} # while (my $line = <IN>)
close (IN) or die "Cannot close $infile : $!";

foreach my $command (@del_pgcommands, @obo_pgcommands, @int_pgcommands) {
  print "$command\n";
  $dbh->do( $command );
}


__END__

