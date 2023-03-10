#!/usr/bin/perl -w

# get temperature sensitive, dominant, semi-dominant alleles from app_ tables, with reference, for Jolene  2009 08 05

use strict;
use diagnostics;
use DBI;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my %hash;

my $result = $dbh->prepare( " SELECT * FROM app_tempname WHERE app_tempname IS NOT NULL; " );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { 
  if ($row[0]) { 
    $hash{name}{$row[0]} = $row[1]; } }

$result = $dbh->prepare( " SELECT * FROM app_heat_sens WHERE app_heat_sens IS NOT NULL AND app_heat_sens != ''; " );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { 
  if ($row[0]) { my $name = $hash{name}{$row[0]};
    $hash{ts}{$name}++; 
    $hash{heat}{$name}++; } }

$result = $dbh->prepare( " SELECT * FROM app_cold_sens WHERE app_cold_sens IS NOT NULL AND app_cold_sens != ''; " );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { 
  if ($row[0]) { my $name = $hash{name}{$row[0]};
    $hash{ts}{$name}++; 
    $hash{cold}{$name}++; } }

$result = $dbh->prepare( " SELECT * FROM app_nature WHERE app_nature = 'WBnature000003'; " );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { 
  if ($row[0]) { my $name = $hash{name}{$row[0]};
    $hash{dm}{$name}++; } }

$result = $dbh->prepare( " SELECT * FROM app_nature WHERE app_nature = 'WBnature000002'; " );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { 
  if ($row[0]) { my $name = $hash{name}{$row[0]};
    $hash{sd}{$name}++; } }

$result = $dbh->prepare( " SELECT * FROM app_paper WHERE app_paper IS NOT NULL; " );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { 
  if ($row[0]) { my $name = $hash{name}{$row[0]};
    $hash{paper}{$name}{$row[1]}++; } }

$result = $dbh->prepare( " SELECT * FROM app_person WHERE app_person IS NOT NULL; " );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { 
  if ($row[0]) { my $name = $hash{name}{$row[0]};
    $row[1] =~ s/\"//g;
    $hash{person}{$name}{$row[1]}++; } }

print "Temperature Sensitive :\n";
print "heat\tcold\tpaper\tperson\tname\n";
foreach my $name (sort keys %{ $hash{ts} }) {
  my $papers = join", ", keys %{ $hash{paper}{$name} };
  my $persons = join", ", keys %{ $hash{person}{$name} };
  print "$hash{heat}{$name}\t$hash{cold}{$name}\t$papers\t$persons\t${name}ts\n";
}

print "\n\nDominant :\n";
print "dominant\tpaper\tperson\tname\n";
foreach my $name (sort keys %{ $hash{dm} }) {
  my $papers = join", ", keys %{ $hash{paper}{$name} };
  my $persons = join", ", keys %{ $hash{person}{$name} };
  print "$hash{dm}{$name}\t$papers\t$persons\t${name}dm\n";
}

print "\n\nSemi Dominant :\n";
print "semidominant\tpaper\tperson\tname\n";
foreach my $name (sort keys %{ $hash{sd} }) {
  my $papers = join", ", keys %{ $hash{paper}{$name} };
  my $persons = join", ", keys %{ $hash{person}{$name} };
  print "$hash{sd}{$name}\t$papers\t$persons\t${name}sd\n";
}


# $result = $dbh->prepare( " SELECT * FROM app_heat_sens WHERE app_heat_sens IS NOT NULL AND app_heat_sens != ''; " );
# $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
# while (my @row = $result->fetchrow) { 
#   if ($row[0]) { 
#     $hash{ts}{$row[0]}++; 
#     $hash{heat}{$row[0]}++; } }
# 
# $result = $dbh->prepare( " SELECT * FROM app_cold_sens WHERE app_cold_sens IS NOT NULL AND app_cold_sens != ''; " );
# $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
# while (my @row = $result->fetchrow) { 
#   if ($row[0]) { 
#     $hash{ts}{$row[0]}++; 
#     $hash{cold}{$row[0]}++; } }
# 
# $result = $dbh->prepare( " SELECT * FROM app_nature WHERE app_nature = 'WBnature000003'; " );
# $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
# while (my @row = $result->fetchrow) { 
#   if ($row[0]) { 
#     $hash{dm}{$row[0]}++; } }
# 
# $result = $dbh->prepare( " SELECT * FROM app_nature WHERE app_nature = 'WBnature000002'; " );
# $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
# while (my @row = $result->fetchrow) { 
#   if ($row[0]) { 
#     $hash{sd}{$row[0]}++; } }
# 
# $result = $dbh->prepare( " SELECT * FROM app_paper WHERE app_paper IS NOT NULL; " );
# $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
# while (my @row = $result->fetchrow) { 
#   if ($row[0]) { 
#     $hash{paper}{$row[0]} = $row[1]++; } }
# 
# $result = $dbh->prepare( " SELECT * FROM app_person WHERE app_person IS NOT NULL; " );
# $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
# while (my @row = $result->fetchrow) { 
#   if ($row[0]) { 
#     $row[1] =~ s/\"//g;
#     $hash{person}{$row[0]} = $row[1]++; } }



# print "Temperature Sensitive :\n";
# print "heat\tcold\tpaper\tperson\tname\n";
# foreach my $joinkey (sort keys %{ $hash{ts} }) {
#   next if ($hash{toprint}{"$hash{heat}{$joinkey}\t$hash{cold}{$joinkey}\t$hash{paper}{$joinkey}\t$hash{person}{$joinkey}\t$hash{name}{$joinkey}ts"});
#   $hash{toprint}{"$hash{heat}{$joinkey}\t$hash{cold}{$joinkey}\t$hash{paper}{$joinkey}\t$hash{person}{$joinkey}\t$hash{name}{$joinkey}ts"}++;
#   print "$hash{heat}{$joinkey}\t$hash{cold}{$joinkey}\t$hash{paper}{$joinkey}\t$hash{person}{$joinkey}\t$hash{name}{$joinkey}ts\n";
# }
# 
# print "\n\nDominant :\n";
# print "dominant\tpaper\tperson\tname\n";
# foreach my $joinkey (sort keys %{ $hash{dm} }) {
#   next if ($hash{toprint}{"$hash{dm}{$joinkey}\t$hash{paper}{$joinkey}\t$hash{person}{$joinkey}\t$hash{name}{$joinkey}dm"});
#   $hash{toprint}{"$hash{dm}{$joinkey}\t$hash{paper}{$joinkey}\t$hash{person}{$joinkey}\t$hash{name}{$joinkey}dm"}++;
#   print "$hash{dm}{$joinkey}\t$hash{paper}{$joinkey}\t$hash{person}{$joinkey}\t$hash{name}{$joinkey}dm\n";
# }
# 
# print "\n\nSemi Dominant :\n";
# print "semidominant\tpaper\tperson\tname\n";
# foreach my $joinkey (sort keys %{ $hash{sd} }) {
#   next if $hash{toprint}{"$hash{sd}{$joinkey}\t$hash{paper}{$joinkey}\t$hash{person}{$joinkey}\t$hash{name}{$joinkey}sd"};
#   $hash{toprint}{"$hash{sd}{$joinkey}\t$hash{paper}{$joinkey}\t$hash{person}{$joinkey}\t$hash{name}{$joinkey}sd"}++;
#   print "$hash{sd}{$joinkey}\t$hash{paper}{$joinkey}\t$hash{person}{$joinkey}\t$hash{name}{$joinkey}sd\n";
# }

__END__

my $result = $dbh->prepare( 'SELECT * FROM two_comment WHERE two_comment ~ ?' );
$result->execute('elegans') or die "Cannot prepare statement: $DBI::errstr\n"; 

$result->execute("doesn't") or die "Cannot prepare statement: $DBI::errstr\n"; 
my $var = "doesn't";
$result->execute($var) or die "Cannot prepare statement: $DBI::errstr\n"; 

my $result = $dbh->do( "DELETE FROM friend WHERE firstname = 'bl\"ah'" );
(also do for INSERT and UPDATE if don't have a variable to interpolate with ? )

can cache prepared SELECTs with $dbh->prepare_cached( &c. );

if ($result->rows == 0) { print "No names matched.\n\n"; }	# test if no return

$result->finish;	# allow reinitializing of statement handle (done with query)
$dbh->disconnect;	# disconnect from DB

http://209.85.173.132/search?q=cache:5CFTbTlhBGMJ:www.perl.com/pub/1999/10/DBI.html+dbi+prepare+execute&cd=4&hl=en&ct=clnk&gl=us

interval stuff : 
SELECT * FROM afp_passwd WHERE joinkey NOT IN (SELECT joinkey FROM afp_lasttouched) AND joinkey NOT IN (SELECT joinkey FROM cfp_curator) AND afp_timestamp < CURRENT_TIMESTAMP - interval '21 days' AND afp_timestamp > CURRENT_TIMESTAMP - interval '28 days';

casting stuff to substring on other types :
SELECT * FROM afp_passwd WHERE CAST (afp_timestamp AS TEXT) ~ '2009-05-14';
