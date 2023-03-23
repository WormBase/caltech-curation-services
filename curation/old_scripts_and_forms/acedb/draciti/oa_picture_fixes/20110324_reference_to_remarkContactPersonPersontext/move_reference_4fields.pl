#!/usr/bin/perl -w

# move pic_paper to pic_remark pic_person pic_persontext
# ran on mangolassi, not tazendra.  2011 03 24
# ran on tazendra.  2011 03 25

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my @pgcommands;

my $infile = 'Old_pictures_mapping.txt';
open (IN, "<$infile") or die "Cannot open $infile : $!";
my $junk = <IN>; 		# skip header
while (my $line = <IN>) {
  chomp $line;
  my ($paper, $junk, $author, $contact, $person, $persontext, $number, $journal, $remark, @a) = split/\t/, $line;
  print "$paper\t$contact\t$person\t$persontext\t$remark\n";
#   if ($person) { if ($contact) { $person = $contact . ',' . $person; } }
  my @pgids;
  my $result = $dbh->prepare( "SELECT joinkey FROM pic_paper WHERE pic_paper = '$paper';" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { push @pgids, $row[0]; }
  foreach my $joinkey (@pgids) {
    if ($remark) {
      ($remark) = &filterForPg($remark);
      push @pgcommands, "INSERT INTO pic_remark VALUES ('$joinkey', '$remark')"; 
      push @pgcommands, "INSERT INTO pic_remark_hst VALUES ('$joinkey', '$remark')"; }
    push @pgcommands, "INSERT INTO pic_contact VALUES ('$joinkey', '$contact')"; 
    push @pgcommands, "INSERT INTO pic_contact_hst VALUES ('$joinkey', '$contact')"; 
    if ($person) { 
      push @pgcommands, "INSERT INTO pic_person VALUES ('$joinkey', '$person')"; 
      push @pgcommands, "INSERT INTO pic_person_hst VALUES ('$joinkey', '$person')"; }
    if ($persontext) { 
      ($persontext) = &filterForPg($persontext);
      push @pgcommands, "INSERT INTO pic_persontext VALUES ('$joinkey', '$persontext' )"; 
      push @pgcommands, "INSERT INTO pic_persontext_hst VALUES ('$joinkey', '$persontext' )"; }
    push @pgcommands, "INSERT INTO pic_paper_hst VALUES ('$joinkey', NULL);"; 
    push @pgcommands, "DELETE FROM pic_paper WHERE joinkey = '$joinkey';"; 
  }
} # while (my $line = <IN>)
close (IN) or die "Cannot close $infile : $!";

foreach my $pgcommand (@pgcommands) {
  print "$pgcommand\n";
# UNCOMMENT TO RUN
#   my $result = $dbh->do( $pgcommand );
} # foreach my $pgcommand (@pgcommands)

sub filterForPg {
  my $val = shift;
  if ($val =~ m/\'/) { $val =~ s/\'/''/g; }
  return $val;
} # sub filterForPg

