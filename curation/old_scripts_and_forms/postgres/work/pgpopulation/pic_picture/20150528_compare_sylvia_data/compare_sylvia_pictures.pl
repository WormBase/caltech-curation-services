#!/usr/bin/perl -w

# compare dump with bad pictures to OA data pic_source.  
# If already in postgres and does not have pic_description, add Description data from .ace file
# for Daniela.  2015 05 28


use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %badNames;
$/ = "";
my $infile = 'bad_pictures.ace';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $obj = <IN>) {
  next unless ($obj =~ m/Picture : "(.*?)"/);
  my $pic  = $1;
  my $desc = '';
  if ($obj =~ m/Description[^"]*?"[^"]*?_sylvia" "(.*?)"/) { $desc = $1; }
  if ($desc =~ m/\\/) { $desc =~ s/\\//g; }
  $badNames{$pic} = $desc;
} # while (my $obj = <IN>) 
close (IN) or die "Cannot close $infile : $!";

my %picNames;
$result = $dbh->prepare( "SELECT * FROM pic_source" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  $picNames{$row[1]}{$row[0]}++;
} # while (@row = $result->fetchrow)

my %picDesc;
$result = $dbh->prepare( "SELECT * FROM pic_description" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  $picDesc{$row[0]} = $row[1];
} # while (@row = $result->fetchrow)

my @pgcommands = ();
foreach my $pic (sort keys %badNames) {
  my $desc = $badNames{$pic};
  if ($picNames{$pic}) {
    my (@pgids) = sort keys %{ $picNames{$pic} };
#     my $pgids = join",", @pgids;
#     print qq(PIC $pic PGIDS $pgids E\n);
    foreach my $pgid (@pgids) {
      if ($picDesc{$pgid}) {
        print qq(PIC $pic PGID $pgid HAS DESC\n);
      } else {
        print qq(PIC $pic PGID $pgid PG NO DESC $desc\n);
        if ($desc) { 
          $desc =~ s/\'/''/g; 
          push @pgcommands, qq(INSERT INTO pic_description VALUES ('$pgid', '$desc'););
          push @pgcommands, qq(INSERT INTO pic_description_hst VALUES ('$pgid', '$desc'););
        } 
      } 
    } # foreach my $pgid (@pgids)
  } else {
    print qq(NOMATCH $pic\n);
  }
} # foreach my $pic (sort keys %badNames)

foreach my $pgcommand (@pgcommands) {
  print qq($pgcommand\n);
# UNCOMMENT TO POPULATE
#   $dbh->do($pgcommand);
} # foreach my $pgcommand (@pgcommands)

