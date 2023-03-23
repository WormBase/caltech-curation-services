#!/usr/bin/perl -w

# compare Daniela's picture_source from canopus to postgres values.  2011 03 29

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my %pg;

my $result = $dbh->prepare( "SELECT pic_source.pic_source, pic_paper.pic_paper, pic_paper.joinkey FROM pic_source, pic_paper WHERE pic_source.joinkey = pic_paper.joinkey ;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) {
  $row[1] =~ s/\"//g;
  my $key =  "$row[1]\t$row[0]";
  $pg{$key}++;
} # while (@row = $result->fetchrow)

$result = $dbh->prepare( "SELECT pic_source.pic_source, pic_contact.pic_contact, pic_contact.joinkey FROM pic_source, pic_contact WHERE pic_source.joinkey = pic_contact.joinkey ;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) {
  $row[1] =~ s/\"//g;
  my $key =  "$row[1]\t$row[0]";
  $pg{$key}++;
} # while (@row = $result->fetchrow)

my %file;
my $infile = 'picture_source';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) {
  chomp $line;
  my ($dir, $file) = split/\t/, $line;
  if ($file =~ m/\.jpg/) { 
    my $key = "$dir\t$file";
    $file{$key}++; }
} # while (my $line = <IN>)
close (IN) or die "Cannot close $infile : $!";

foreach my $key (sort keys %file) {
  unless ($pg{$key}) { print "$key in picture_source, not postgres\n"; }
} # foreach my $key (sort keys %file)

foreach my $key (sort keys %pg) {
  unless ($file{$key}) { print "$key in postgres, not picture_source\n"; }
} # foreach my $key (sort keys %pg)
