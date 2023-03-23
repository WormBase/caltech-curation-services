#!/usr/bin/perl -w

# find list of images that are only on canopus xor tazendra (they all should be in both)  2011 03 25

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my %canopus;
# my $infile = '1551_list';
my $infile = '266_list';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) {
  chomp $line; $canopus{$line}++; }
close (IN) or die "Cannot close $infile : $!";

my %pg;
# my $result = $dbh->prepare( "SELECT pic_source.joinkey, pic_source.pic_source, pic_contact.pic_contact FROM pic_source, pic_contact WHERE pic_source.joinkey = pic_contact.joinkey AND pic_contact.pic_contact ~ 'WBPerson1551'" );
my $result = $dbh->prepare( "SELECT pic_source.joinkey, pic_source.pic_source, pic_contact.pic_contact FROM pic_source, pic_contact WHERE pic_source.joinkey = pic_contact.joinkey AND pic_contact.pic_contact ~ 'WBPerson266'" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($pg{$row[1]}) { print "$row[1] exists for $pg{$row[1]} and $row[0]\n"; }
  $pg{$row[1]} = $row[0];
} # while (@row = $result->fetchrow)

foreach my $canopus (sort keys %canopus) {
  unless ($pg{$canopus}) { print "$canopus in canopus, not in pg\n"; }
} # foreach my $canopus (sort keys %canopus)

foreach my $pg (sort keys %pg) {
  unless ($canopus{$pg}) { print "$pg in pg, not in canopus\n"; }
} # foreach my $pg (sort keys %pg)
