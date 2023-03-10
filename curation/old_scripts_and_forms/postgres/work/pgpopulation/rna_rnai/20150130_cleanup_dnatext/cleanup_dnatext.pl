#!/usr/bin/perl -w

# clean up rna_dnatext of extra stuff for Chris, but keep yk stuff.  
# live run on tazendra.  2015 01 30


use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my @pgcommands;
$result = $dbh->prepare( "SELECT * FROM rna_dnatext ORDER BY joinkey::INTEGER" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[1]) { 
    my $newText = $row[1];
    my (@entries) = split/\|/, $row[1];
    foreach my $entry (@entries) {
      $entry =~ s/^\s+//;
      $entry =~ s/\s+$//;
      if ($entry =~ m/[atcg]+ (.*)/) { 
        my $extra = $1;
        next if ($extra =~ m/yk/);
#         print "$row[0]\t$extra\n"; 
        $newText =~ s/$extra//;
        $newText =~ s/^\s+//;
        $newText =~ s/\s+$//;
        $newText =~ s/\s+/ /g;
      }
    } # foreach my $entry (@entries)
    if ($newText ne $row[1]) {
      push @pgcommands, qq(DELETE FROM rna_dnatext WHERE joinkey = '$row[0]');
      push @pgcommands, qq(INSERT INTO rna_dnatext VALUES ('$row[0]', '$newText'););
      push @pgcommands, qq(INSERT INTO rna_dnatext_hst VALUES ('$row[0]', '$newText'););
    } # if ($newText ne $row[1])
  } # if ($row[1])
} # while (@row = $result->fetchrow)

foreach my $pgcommand (@pgcommands) {
  print qq($pgcommand\n);
# UNCOMMENT TO POPULATE
#   $dbh->do( $pgcommand );
} # foreach my $pgcommand (@pgcommands)
