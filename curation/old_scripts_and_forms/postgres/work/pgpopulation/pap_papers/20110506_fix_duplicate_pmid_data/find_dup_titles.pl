#!/usr/bin/perl -w

# find papers with duplicate titles and remove duplicates from the @tables that get updated from pubmed xml by pap_match.pm  
# These were created by mistakenly running a cronjob manually while it then started from cron.  2011 05 06

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my %title;
my $result = $dbh->prepare( "SELECT * FROM pap_title ORDER BY joinkey" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  $title{$row[0]}++;
} # while (@row = $result->fetchrow)

my @joinkeys = ();
foreach my $joinkey (sort keys %title) {
  if ($title{$joinkey} > 1) { push @joinkeys, $joinkey; }
} # foreach my $joinkey (sort keys %title)
 
my @tables = qw( pubmed_final title journal abstract pages volume year month day type );

my @pgcommands;
foreach my $joinkey (@joinkeys) {
  foreach my $table (@tables) {
    $result = $dbh->prepare( "SELECT * FROM pap_$table WHERE joinkey = '$joinkey'" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    my @results;
    while (my @row = $result->fetchrow) {
      push @results, $row[4];
    }
    if (scalar @results > 1) {
      for my $i (1 .. $#results) {
        push @pgcommands, "DELETE FROM pap_$table WHERE joinkey = '$joinkey' AND pap_timestamp = '$results[$i]'";
      } # for my $i (1 .. $#resulst)
    }
} }

foreach my $command (@pgcommands) {
  print "$command\n";
  $result = $dbh->do( $command );
} # foreach my $command (@pgcommands)
