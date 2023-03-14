#!/usr/bin/env perl

# generate .ace data for collaborators based on common paper authorship verification.  2019 04 04

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );
use Dotenv -load => '/usr/lib/.env';

my $dbh = DBI->connect ( "dbi:Pg:dbname=$ENV{PSQL_DATABASE};host=$ENV{PSQL_HOST};port=$ENV{PSQL_PORT}", "$ENV{PSQL_USERNAME}", "$ENV{PSQL_PASSWORD}") or die "Cannot connect to database!\n";
# my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %standardname;

my %pap_author;
my %pap_possible;
my %pap_verified;
my %pap_person;
my %collab;

my %lineage;
my %haslab;

$result = $dbh->prepare( "SELECT * FROM two_lineage WHERE two_role = 'Collaborated' AND two_number ~ 'two' AND joinkey ~ 'two'" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $lineage{$row[0]}{$row[3]}++; }

$result = $dbh->prepare( "SELECT * FROM two_lab WHERE two_lab IS NOT NULL" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $haslab{$row[0]}++; }
$result = $dbh->prepare( "SELECT * FROM two_oldlab WHERE two_oldlab IS NOT NULL" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $haslab{$row[0]}++; }

$result = $dbh->prepare( "SELECT * FROM two_standardname" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $standardname{$row[0]} = $row[2]; }

$result = $dbh->prepare( "SELECT * FROM pap_author" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $pap_author{AidToPid}{$row[1]} = $row[0]; 
    $pap_author{PidToAid}{$row[0]}{$row[1]}++; } }

$result = $dbh->prepare( "SELECT * FROM pap_author_possible" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $pap_possible{$row[0]}{$row[2]} = $row[1]; } }

$result = $dbh->prepare( "SELECT * FROM pap_author_verified WHERE pap_author_verified ~ 'YES'" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    my $aid = $row[0]; my $join = $row[2];
    next unless $pap_possible{$aid}{$join};
#     unless ($two) { print qq(AID $aid JOIN $join TWO $two\n); }
    my $two = $pap_possible{$aid}{$join};
#     unless ($paper) { print qq(AID $aid JOIN $join TWO $two\n); }
    if ($pap_author{AidToPid}{$aid}) {
      my $paper = $pap_author{AidToPid}{$aid};
      $pap_person{$paper}{$two}++; }
  } # if ($row[0])
} # while (my @row = $result->fetchrow)

foreach my $paper (sort keys %pap_person) {
  foreach my $two1 (sort keys %{ $pap_person{$paper} }) {
    foreach my $two2 (sort keys %{ $pap_person{$paper} }) {
      next if ($two1 eq $two2);
      next unless ($haslab{$two1});
      next unless ($haslab{$two2});
      $collab{$two1}{$two2}{$paper}++
    } # foreach my $two (sort keys %{ $pap_person{$paper} })
  } # foreach my $two (sort keys %{ $pap_person{$paper} })
}


# vs lineage comparison
# foreach my $two (sort keys %lineage) {
#   foreach my $other (sort keys %{ $lineage{$two} }) {
#     unless ($collab{$two}{$other}) {
#       print qq($two\t$other\n);
#     }
#   } # foreach my $other (sort keys %{ $collab{$two} })
# }


# ace report
foreach my $two (sort keys %collab) {
  my $wbp = $two; $wbp =~ s/two/WBPerson/;
  print qq(Person : "$wbp"\n);
  foreach my $other (sort keys %{ $collab{$two} }) {
    my $wbo = $other; $wbo =~ s/two/WBPerson/;
    print qq(Worked_with\t"$wbo" Coauthor\n);
  } # foreach my $other (sort keys %{ $collab{$two} })
  print qq(\n);
}


# # text report
# my $most = 0;
# my $who_most = '';
# foreach my $two (sort keys %collab) {
#   my $count = scalar keys %{ $collab{$two} };
#   if ($count > $most) { 
#     $most = $count;
#     $who_most = $two; }
#   foreach my $other (sort keys %{ $collab{$two} }) {
#     my $papers = join", ", sort keys %{ $collab{$two}{$other} };
#     print qq($standardname{$two}\t$standardname{$other}\t$papers\n); 
# #     print qq($standardname{$two} ($two)\t$standardname{$other} ($two)\t$papers\n); 
# #     foreach my $paper (sort keys %{ $collab{$two}{$other} }) {
# #       print qq($standardname{$two}\t$standardname{$other}\tWBPaper$paper\n); 
# #     } # foreach my $paper (sort keys %{ $collab{$two}{$other} })
#   } # foreach my $other (sort keys %{ $collab{$two} })
# }
# print qq(Most $most by $standardname{$who_most}\n);

__END__


pap_author_verified
 10        | YES  John E Sulston |        1 | two1        | 2004-02-10 13:22:26.922696-08
 10000     | YES  Andrew Singson |        1 | two1        | 2003-08-06 11:13:13.10306-07
 100000    | YES Tugba Guven     |        1 | two3429     | 2008-12-12 11:57:53.17027-08

pap_author_possible 
 10        | two635              |        1 | two1        | 2003-10-03 13:38:00.658271-07
 1000      | two1051             |        1 | two1        | 2005-03-18 11:20:28.575995-08
 10000     | two597              |        1 | two1        | 2003-07-30 18:21:23.249328-07

pap_author 
 00036404 | 116757     |         1 | two10877    | 2010-06-25 10:09:24.184892-07
 00036404 | 116758     |         2 | two10877    | 2010-06-25 10:09:24.319114-07
 00036404 | 116759     |         3 | two10877    | 2010-06-25 10:09:24.320891-07

