#!/usr/bin/perl -w

# by year, list papers + authors + authors connected to person + authors validated YES to person.  for Cecilia  2014 08 29

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

for my $year ( 2005 .. 2014 ) {
  my %paps; my %aids; my %papPos; my %papYes;

  $result = $dbh->prepare( "SELECT * FROM pap_author WHERE pap_timestamp < '${year}-12-31' AND joinkey IN (SELECT joinkey FROM pap_curation_flags WHERE pap_curation_flags = 'author_person')" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    my ($joinkey, $aid, $order) = @row;
    $paps{$joinkey}++;
    $aids{$aid}++;
  } # while (@row = $result->fetchrow)
  $result = $dbh->prepare( "SELECT * FROM pap_author_possible WHERE pap_timestamp < '${year}-12-31'" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    my ($aid, $two, $join) = @row;
    if ($aids{$aid}) { $papPos{$aid}++; }
  } # while (@row = $result->fetchrow)
  $result = $dbh->prepare( "SELECT * FROM pap_author_verified WHERE pap_timestamp < '${year}-12-31' AND pap_author_verified ~ 'YES'" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    my ($aid, $two, $join) = @row;
    if ($aids{$aid}) { $papYes{$aid}++; }
  } # while (@row = $result->fetchrow)
  my $nPaps = scalar keys %paps;
  my $nAids = scalar keys %aids;
  my $nPos  = scalar keys %papPos;
  my $nYes  = scalar keys %papYes;
  my $pPos  = int( 100 * $nPos / $nAids );
  my $pYes  = int( 100 * $nYes / $nAids );
  my $backlogPos = $nAids - $nPos;
  my $backlogYes = $nAids - $nYes;
  print "$year year\t$nPaps papers\t$nAids authors\t$nPos ($pPos%) authors connected to person\t$nYes ($pYes%) authors verified yes\n";
}

__END__


2005 year	22735 papers	 76169 authors	 39894 (52%) authors connected to person (36275 backlog)	 27060 (35%) authors verified yes (49109 backlog)
2006 year	24537 papers	 83168 authors	 56918 (68%) authors connected to person (26250 backlog)	 39733 (47%) authors verified yes (43435 backlog)
2007 year	26763 papers	 92378 authors	 65526 (70%) authors connected to person (26852 backlog)	 56271 (60%) authors verified yes (36107 backlog)
2008 year	27779 papers	 96972 authors	 70767 (72%) authors connected to person (26205 backlog)	 63271 (65%) authors verified yes (33701 backlog)
2009 year	30840 papers	109671 authors	 82390 (75%) authors connected to person (27281 backlog)	 74094 (67%) authors verified yes (35577 backlog)
2010 year	33028 papers	119534 authors	 90552 (75%) authors connected to person (28982 backlog)	 82380 (68%) authors verified yes (37154 backlog)
2011 year	35554 papers	131208 authors	104187 (79%) authors connected to person (27021 backlog)	 92786 (70%) authors verified yes (38422 backlog)
2012 year	36762 papers	137628 authors	114528 (83%) authors connected to person (23100 backlog)	100533 (73%) authors verified yes (37095 backlog)
2013 year	39480 papers	150673 authors	127936 (84%) authors connected to person (22737 backlog)	112548 (74%) authors verified yes (38125 backlog)
2014 year	40442 papers	156091 authors	135156 (86%) authors connected to person (20935 backlog)	121077 (77%) authors verified yes (35014 backlog)


2005 year	22735 papers	76169 authors	39894 (52%) authors connected to person	27060 (35%) authors verified yes
2006 year	24537 papers	83168 authors	56918 (68%) authors connected to person	39733 (47%) authors verified yes
2007 year	26763 papers	92378 authors	65526 (70%) authors connected to person	56271 (60%) authors verified yes
2008 year	27779 papers	96972 authors	70767 (72%) authors connected to person	63271 (65%) authors verified yes
2009 year	30840 papers	109671 authors	82390 (75%) authors connected to person	74094 (67%) authors verified yes
2010 year	33028 papers	119534 authors	90552 (75%) authors connected to person	82380 (68%) authors verified yes
2011 year	35554 papers	131208 authors	104187 (79%) authors connected to person	92786 (70%) authors verified yes
2012 year	36762 papers	137628 authors	114528 (83%) authors connected to person	100533 (73%) authors verified yes
2013 year	39480 papers	150673 authors	127936 (84%) authors connected to person	112548 (74%) authors verified yes
2014 year	40442 papers	156091 authors	135154 (86%) authors connected to person	121072 (77%) authors verified yes
