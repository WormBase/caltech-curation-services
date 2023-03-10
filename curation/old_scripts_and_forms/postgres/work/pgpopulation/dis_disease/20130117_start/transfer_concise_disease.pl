#!/usr/bin/perl -w

# transfer disease data from concise OA con_ to disease OA dis_ .  
# Does not delete entries from concise OA, Ranjana should do those manually afteward.  2013 01 12
#
# Live populate on tazendra.  2013 01 23

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my @con = qw( wbgene curator curhistory desctext paper accession lastupdate comment );
my %con;
my %map;
$map{wbgene}     = 'wbgene';
$map{curator}    = 'curator';
$map{curhistory} = 'curhistory';
$map{desctext}   = 'diseaserelevance';
$map{paper}      = 'paperdisrel';
$map{accession}  = 'dbdisrel';
$map{lastupdate} = 'lastupdatedisrel';
$map{comment}    = 'comment';

my %pgids;
$result = $dbh->prepare( "SELECT * FROM con_desctype WHERE con_desctype = 'Human_disease_relevance';" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $pgids{$row[0]}++; }
my $pgids = join"','", keys %pgids;

foreach my $con (@con) {
  my $dt = 'con_' . $con;
  my $ht = 'con_' . $con . '_hst';
  $result = $dbh->prepare( "SELECT * FROM $dt WHERE joinkey IN ('$pgids')" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    if ($row[0]) { 
      if ($row[1]) { if ($row[1] =~ m/\'/) { $row[1] =~ s/\'/''/g; } }
        else { $row[1] = ''; }
      my $pair = $row[1] . "\t" . $row[2];
      $con{$row[0]}{$con}{'dt'}{$pair}++;
    } # if ($row[0])
  } # while (@row = $result->fetchrow)
  $result = $dbh->prepare( "SELECT * FROM $ht WHERE joinkey IN ('$pgids')" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    if ($row[0]) { 
      if ($row[1]) { if ($row[1] =~ m/\'/) { $row[1] =~ s/\'/''/g; } }
        else { $row[1] = ''; }
      my $pair = $row[1] . "\t" . $row[2];
      $con{$row[0]}{$con}{'ht'}{$pair}++;
    } # if ($row[0])
  } # while (@row = $result->fetchrow)
} # foreach my $con (@con)

my @pgcommands;
foreach my $con (sort keys %map) {
  my $newcon = $map{$con};
  my $command = qq(DELETE FROM dis_${newcon}_hst;);
  push @pgcommands, $command;
  $command = qq(DELETE FROM dis_${newcon};);
  push @pgcommands, $command;
} # foreach my $con (sort keys %map)
my $newpgid = 0;
foreach my $pgid (sort {$a<=>$b} keys %con) {
  $newpgid++;
#   print "pgid $pgid newpgid $newpgid\n";
  foreach my $con (sort keys %{ $con{$pgid} }) {
    my $newcon = $map{$con};
    foreach my $htpair (sort keys %{ $con{$pgid}{$con}{'ht'} }) {
      my ($value, $timestamp) = split/\t/, $htpair;
      if ($con eq 'curhistory') { $value = $newpgid; }
#       print "T $con V $value T $timestamp E\n";
      my $command = qq(INSERT INTO dis_${newcon}_hst VALUES ('$newpgid', '$value', '$timestamp'););
#       print "$command\n";
      push @pgcommands, $command;
    } # foreach my $htpair (sort keys %{ $con{$pgid}{$con}{'ht'} })
    foreach my $dtpair (sort keys %{ $con{$pgid}{$con}{'dt'} }) {
      my ($value, $timestamp) = split/\t/, $dtpair;
      if ($con eq 'curhistory') { $value = $newpgid; }
#       print "T $con V $value T $timestamp E\n";
      my $command = qq(INSERT INTO dis_${newcon} VALUES ('$newpgid', '$value', '$timestamp'););
#       print "$command\n";
      push @pgcommands, $command;
    } # foreach my $dtpair (sort keys %{ $con{$pgid}{$con}{'dt'} })
  } # foreach my $con (sort keys %{ $con{$pgid} })
#   print "\n";
} # foreach my $pgid (sort {$a<=>$b} keys %con)

foreach my $pgcommand (@pgcommands) {
  print "$pgcommand\n";
# UNCOMMENT TO POPULATE
#   $result = $dbh->do( $pgcommand );
} # foreach my $pgcommand (@pgcommands)
  
__END__
