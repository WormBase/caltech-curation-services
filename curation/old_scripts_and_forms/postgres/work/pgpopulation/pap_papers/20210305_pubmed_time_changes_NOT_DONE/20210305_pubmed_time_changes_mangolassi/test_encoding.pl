#!/usr/bin/perl -w

# take utf-8 encoded unicode from postres, decode it, and encode for html output
# https://www.perlmonks.org/?node_id=1060768   
# 2021 03 24

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 decode);
use HTML::Entities;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my $input = "vis-à-vis Beyoncé's naïve\npapier-mâché résumé";
print $input, "\n";
print encode_entities($input), "\n";
print encode_entities(decode('utf-8', $input)), "\n";


$result = $dbh->prepare( "SELECT * FROM pap_author_affiliation WHERE author_id = '1388'" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[1] =~ s///g;
    print "$row[0]\t$row[1]\n";
    print encode_entities(decode('utf-8', $row[1])), "\n";
  } # if ($row[0])
} # while (@row = $result->fetchrow)

__END__

