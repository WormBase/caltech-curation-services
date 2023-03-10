#!/usr/bin/perl -w

# change two_country and h_two_country for some countries.  for Cecilia.  2015 02 04

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my @pgcommands;
my $infile = 'countries.txt';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) {
  chomp $line;
  my ($old, $new) = split/\t/, $line;
  $old =~ s/\'/''/g;
  $result = $dbh->prepare( "SELECT * FROM two_country WHERE two_country = E'$old'" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    my $row = join"\t", @row;
    my ($joinkey, $order, $data, @rest) = @row;
    push @pgcommands, qq(DELETE FROM two_country WHERE two_country = E'$old' AND joinkey = '$joinkey' AND two_order = '$order');
    push @pgcommands, qq(INSERT INTO two_country VALUES ('$joinkey', '$order', '$new', 'two1'));
    push @pgcommands, qq(INSERT INTO h_two_country VALUES ('$joinkey', '$order', '$new', 'two1'));
  } # while (my @row = $result->fetchrow)
} # while (my $line = <IN>)
close (IN) or die "Cannot close $infile : $!";


foreach my $pgcommand (@pgcommands) {
  print "$pgcommand\n";
# UNCOMMENT TO POPULATE
#   $dbh->do( $pgcommand );
} # foreach my $command (@pgcommands)

__END__

COPY two_country TO '/home/postgres/work/pgpopulation/two_people/20150204_fix_countries/two_country.pg.backup';
COPY h_two_country TO '/home/postgres/work/pgpopulation/two_people/20150204_fix_countries/h_two_country.pg.backup';
