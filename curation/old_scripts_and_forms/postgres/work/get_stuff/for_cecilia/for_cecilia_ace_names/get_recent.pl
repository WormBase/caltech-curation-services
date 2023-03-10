#!/usr/bin/perl -w
#
# Quick PG query to get some data (about gene function and new mutant) for Andrei  2002 02 04

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $outfile = "outfile";
open(OUT, ">$outfile") or die "Cannot create $outfile : $!";

my $result = $conn->exec( "SELECT joinkey, ace_author FROM ace_author WHERE ace_author.joinkey IN (SELECT ace_email.joinkey FROM ace_email WHERE ace_email.ace_email IS NULL);" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[1] =~ s///g;
    print OUT "$row[0]\t$row[1]\n";
  } # if ($row[0])
} # while (@row = $result->fetchrow)

print OUT "\n\nDIVIDER\n\n";

my $faxcarta = "/home/cecilia/work/mutt/20020617/faxcarta";
open (FAX, "<$faxcarta") or die "Cannot open $faxcarta : $!";
while (<FAX>) {
  chomp;
  if ($_ =~ m/\d/) {
    my ($ace, $wbg) = split /\t/, $_;
    if ($ace) { $ace =~ s/\s//g; }
    if ($wbg) { $wbg =~ s/\s//g; }
    if ($ace) { &getAce($ace); }
    if ($wbg) { &getWbg($wbg); }
  } # if ($_ =~ m/\d/)
} # while (<FAX>)
close (FAX) or die "Cannot close $faxcarta : $!";

close (OUT) or die "Cannot close $outfile : $!";

sub getAce {
  my $ace = shift;
  $ace = 'ace' . $ace;
  my $result = $conn->exec( "SELECT joinkey, ace_author FROM ace_author WHERE ace_author.joinkey = '$ace';" );
  while (my @row = $result->fetchrow) {
    if ($row[0]) { 
      $row[0] =~ s///g;
      $row[1] =~ s///g;
      print OUT "$row[0]\t$row[1]\n";
    } # if ($row[0])
  } # while (@row = $result->fetchrow)
} # sub getAce

sub getWbg {
  my $wbg = shift;
  $wbg = 'wbg' . $wbg;
  my $result = $conn->exec( "SELECT joinkey, wbg_lastname FROM wbg_lastname WHERE wbg_lastname.joinkey = '$wbg';" );
  while (my @row = $result->fetchrow) {
    if ($row[0]) { 
      $row[0] =~ s///g;
      $row[1] =~ s///g;
      print OUT "$row[0]\t$row[1]\t";
    } # if ($row[0])
  } # while (@row = $result->fetchrow)
  $result = $conn->exec( "SELECT wbg_firstname FROM wbg_firstname WHERE wbg_firstname.joinkey = '$wbg';" );
  while (my @row = $result->fetchrow) {
    if ($row[0]) { 
      $row[0] =~ s///g;
      print OUT "$row[0]\n";
    } # if ($row[0])
  } # while (@row = $result->fetchrow)
} # sub getWbg
