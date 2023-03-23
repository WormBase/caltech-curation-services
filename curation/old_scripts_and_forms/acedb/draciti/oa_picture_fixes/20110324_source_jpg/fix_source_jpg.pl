#!/usr/bin/perl -w

# convert all .png and .jpeg TO .jpg in pic_source
# ran on sandbox, not tazendra.
# ran on tazendra.  2011 03 24


use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my @pgcommands;

my $result = $dbh->prepare( "SELECT * FROM pic_source WHERE pic_source ~ '\.jpeg' OR pic_source ~ '\.png';" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { 
  my $joinkey = $row[0];
  my $old_source = $row[1];
  ($old_source) = &filterForPg($old_source);
  my $new_source = $old_source; $new_source =~ s/(\..*?)$/.jpg/; 
  push @pgcommands, "DELETE FROM pic_source WHERE joinkey = '$joinkey' AND pic_source = '$old_source';";
  push @pgcommands, "INSERT INTO pic_source VALUES ('$joinkey', '$new_source');";
  push @pgcommands, "INSERT INTO pic_source_hst VALUES ('$joinkey', '$new_source');";
}

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

__END__

my $infile = 'Old_pictures_mapping.txt';
open (IN, "<$infile") or die "Cannot open $infile : $!";
my $junk = <IN>; 		# skip header
while (my $line = <IN>) {
  chomp $line;
  my ($paper, $junk, $author, $contact, $person, $persontext, $number, $journal, $remark, @a) = split/\t/, $line;
  print "$paper\t$contact\t$person\t$persontext\t$remark\n";
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
      if ($contact) { $person = $contact . ',' . $person; }
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

