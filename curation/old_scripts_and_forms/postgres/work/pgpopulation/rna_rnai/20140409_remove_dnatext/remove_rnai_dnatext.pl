#!/usr/bin/perl -w

# for a given set of WBRNAi, get the pgids, and remove the rna_dnatext in data and history.  2014 04 09
#
# live on tazendra.  2014 04 09

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %pgids;

my %rnaiIds;
my $infile = 'RNAis_to_delete_DNA_text_from_Postgres_4-9-2014.txt';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) { chomp $line; $rnaiIds{$line}++; }
close (IN) or die "Cannot close $infile : $!";
my $rnaiIds = join"','", sort keys %rnaiIds;

$result = $dbh->prepare( "SELECT * FROM rna_name WHERE rna_name IN ('$rnaiIds')" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $pgids{$row[0]}++; } }
my $pgids = join"','", sort {$a<=>$b} keys %pgids;

my %pgidsDnatext;
$result = $dbh->prepare( "SELECT * FROM rna_dnatext WHERE joinkey IN ('$pgids')" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $pgidsDnatext{$row[0]}++; } }
my $pgidsDnatext = join"','", sort {$a<=>$b} keys %pgidsDnatext;

if ($pgidsDnatext) {				# only change stuff if there's pgids to change
  my @pgcommands;
  push @pgcommands, qq(DELETE FROM rna_dnatext WHERE joinkey IN ('$pgidsDnatext'));
  
  my @historyCommand = ();
  foreach my $pgidDnatext (sort {$a<=>$b} keys %pgidsDnatext) {
    push @historyCommand, "('$pgidDnatext', NULL)";
  } # foreach my $pgidDnatext (sort {$a<=>$b} keys %pgidsDnatext)
  my $historyCommand = join", ", @historyCommand;
  $historyCommand = qq(INSERT INTO rna_dnatext_hst VALUES ) . $historyCommand;
  push @pgcommands, $historyCommand;
  
  foreach my $pgcommand (@pgcommands) {
    print qq($pgcommand\n);
# UNCOMMENT TO MAKE CHANGES
#     $result = $dbh->do( $pgcommand );
  } # foreach my $pgcommand (@pgcommands)
}

__END__

