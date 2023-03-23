#!/usr/bin/perl -w

# get mapping of pic_source to pic_paper  for only old pictures (pgid < 7229)  2011 03 23
# also to pic_contact  2011 03 24

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my $result = $dbh->prepare( "SELECT pic_source.pic_source, pic_paper.pic_paper, pic_paper.joinkey FROM pic_source, pic_paper WHERE pic_source.joinkey = pic_paper.joinkey AND pic_paper.joinkey::INTEGER < '7229';" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    print "$row[0]\t$row[1]\t$row[2]\n";
  } # if ($row[0])
} # while (@row = $result->fetchrow)

$result = $dbh->prepare( "SELECT pic_source.pic_source, pic_contact.pic_contact, pic_contact.joinkey FROM pic_source, pic_contact WHERE pic_source.joinkey = pic_contact.joinkey AND pic_contact.joinkey::INTEGER < '7229';" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    print "$row[0]\t$row[1]\t$row[2]\n";
  } # if ($row[0])
} # while (@row = $result->fetchrow)
