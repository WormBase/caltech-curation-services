#!/usr/bin/perl -w

# set all micropublication biology papers to also be journal_articles.  for Daniela.  2020 01 24

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %hash;
$result = $dbh->prepare( "SELECT * FROM pap_type WHERE joinkey IN (SELECT joinkey FROM pap_journal WHERE pap_journal = 'microPublication Biology') AND joinkey NOT IN (SELECT joinkey FROM pap_type WHERE pap_type = '1') ORDER BY joinkey, pap_order" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[2] =~ s///g;
    $hash{$row[0]} = $row[2];
  } # if ($row[0])
} # while (@row = $result->fetchrow)

my @pgcommands;
foreach my $joinkey (sort keys %hash) {
  my $order = $hash{$joinkey} + 1;
  my $pgcommand = qq(INSERT INTO pap_type VALUES ('$joinkey', '1', $order, 'two12028'));
  push @pgcommands, $pgcommand;
  $pgcommand = qq(INSERT INTO h_pap_type VALUES ('$joinkey', '1', $order, 'two12028'));
  push @pgcommands, $pgcommand;
}

foreach my $pgcommand (@pgcommands) {
  print qq($pgcommand\n);
# UNCOMMENT TO POPULATE
#   $dbh->do($pgcommand);
}

__END__
