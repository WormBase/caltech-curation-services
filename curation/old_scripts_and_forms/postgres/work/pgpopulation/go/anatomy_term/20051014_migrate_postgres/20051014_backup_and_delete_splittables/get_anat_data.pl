#!/usr/bin/perl -w


use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my %anat;
my $result = $conn->exec( "SELECT * FROM got_anatomy_term WHERE got_anatomy_term IS NOT NULL;" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $anat{$row[0]}++; } }

my @PGparameters = qw(curator anatomy_term);
my @PGsubparameters = qw( goterm goid paper_evidence person_evidence goinference
                         goinference_two aoinference comment);

  foreach my $type (@PGparameters) {
    foreach my $joinkey (sort keys %anat) {
      my $result = $conn->exec( "SELECT * FROM got_$type WHERE joinkey = '$joinkey';" );
      while (my @row = $result->fetchrow) {
#         print "got_$type\t$row[0]\t$row[1]\t$row[2]\n";
      } # while (my @row = $result->fetchrow)
    } # foreach my $joinkey (sort keys %anat)
#     print "\n";
  } # foreach my $type (@PGparameters)

  my %hash;
  foreach my $type (@PGsubparameters) {
    my @subtypes = qw( bio_ cell_ mol_ );
    foreach my $subt ( @subtypes ) {
      my $type = $subt . $type;
      for my $i (1 .. 8) {
        foreach my $joinkey (sort keys %anat) {
          my $result = $conn->exec( "SELECT * FROM got_$type WHERE joinkey = '$joinkey';" );
          while (my @row = $result->fetchrow) {
            $hash{$type}{$joinkey}{$row[1]}{val}{order} = $row[2];
            $hash{$type}{$joinkey}{$row[1]}{time}{order} = $row[3];
#             print "got_${type}$i\t$row[0]\t$row[1]\t$row[2]\t$row[3]\n";
          } # while (my @row = $result->fetchrow)  
        } # foreach my $joinkey (sort keys %anat)
#         print "\n";
      } # for my $i (1 .. 8)
    } # foreach my $subt ( @subtypes )
  } # foreach my $type (@PGsubparameters)

  foreach my $type (@PGsubparameters) {
    my @subtypes = qw( bio_ cell_ mol_ );
    foreach my $subt ( @subtypes ) {
      my $type = $subt . $type;
      for my $i (1 .. 8) {
        foreach my $joinkey (sort keys %anat) {
          my $result = $conn->exec( "SELECT * FROM got_${type}$i WHERE joinkey = '$joinkey';" );
          while (my @row = $result->fetchrow) {
            $hash{$type}{$joinkey}{$i}{val}{split} = $row[1];
            $hash{$type}{$joinkey}{$i}{time}{split} = $row[2];
#             print "got_${type}$i\t$row[0]\t$row[1]\t$row[2]\t$row[3]\n";
          } # while (my @row = $result->fetchrow)  
        } # foreach my $joinkey (sort keys %anat)
#         print "\n";
      } # for my $i (1 .. 8)
    } # foreach my $subt ( @subtypes )
  } # foreach my $type (@PGsubparameters)

  # compare ordered tables (tables with got_order) and split tables (got_bio_goid1, got_bio_goid2, etc.)
  # results seem to indicate that order tables have latest and more data.  2005 10 14
foreach my $type (sort keys %hash) {
  foreach my $joinkey (sort keys %{ $hash{$type} }) {
    foreach my $i (sort keys %{ $hash{$type}{$joinkey} }) {
      unless ($hash{$type}{$joinkey}{$i}{val}{split} eq $hash{$type}{$joinkey}{$i}{val}{order}) {
        print "type $type joinkey $joinkey I $i\t";
        print "split $hash{$type}{$joinkey}{$i}{val}{split} order $hash{$type}{$joinkey}{$i}{val}{order}\n"; }
      unless ($hash{$type}{$joinkey}{$i}{time}{split} eq $hash{$type}{$joinkey}{$i}{time}{order}) {
        print "type $type joinkey $joinkey I $i\t";
        print "split $hash{$type}{$joinkey}{$i}{time}{split} order $hash{$type}{$joinkey}{$i}{time}{order}\n"; }
} } }
