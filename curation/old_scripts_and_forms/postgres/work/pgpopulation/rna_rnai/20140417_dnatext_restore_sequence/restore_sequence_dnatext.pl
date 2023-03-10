#!/usr/bin/perl -w

# look at all rna_sequence, compare to corresponding rna_dnatext, if not in dnatext, get dnatext from file and put back on rna_dnatext.  for Chris.
# getting very few results, probably something wrong.  2014 04 17
#
# fixed.  live run  2014 04 18


use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;
my @pgcommands;

my %hash;
my %sequences;
my %dnatext;
my %pgids;

my %seqToDnatext;
my $infile = 'RNAi_OA_changes_4-12-2014.ace';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) {
  chomp $line;
  if ($line =~ m/DNA_text "(.*?)" "(.*?)"$/) { $seqToDnatext{$2} = $1; }
} # while (my $line = <IN>)
close (IN) or die "Cannot close $infile : $!";


my %name;
$result = $dbh->prepare( "SELECT * FROM rna_name " );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $name{ptn}{$row[0]}{$row[1]}++; $name{ntp}{$row[1]}{$row[0]}++; }

$result = $dbh->prepare( "SELECT * FROM rna_sequence " );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  my $pgid = $row[0];
  my $data = $row[1];
  my @data = split/\|/, $data;
  foreach my $sequence (@data) {
    if ($sequence =~ m/^\s+/) { $sequence =~ s/^\s+//; }
    if ($sequence =~ m/\s+$/) { $sequence =~ s/\s+$//; }
    $sequences{$pgid}{$sequence}++;
    $pgids{$pgid}++;
  } # foreach my $data (@data)
} # while (my @row = $result->fetchrow)
my $pgids = join"','", sort {$a<=>$b} keys %pgids;

$result = $dbh->prepare( "SELECT * FROM rna_dnatext" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  my $data = $row[1];
  my @data = split/\|/, $data;
  my %exists;
  foreach my $data (@data) {
    if ($data =~ m/^\s+/) { $data =~ s/^\s+//; }
    if ($data =~ m/\s+$/) { $data =~ s/\s+$//; }
    if ($data =~ m/^ ?([ATCGNatcgn]+) (.+) ?$/) { 	# if there's literal atcgn and a name, capture what maps to the name
      my ($text, $name) = ($1, $2);
      if ($name =~ m/^\s+/) { $name =~ s/^\s+//; }
      if ($name =~ m/\s+$/) { $name =~ s/\s+$//; }
      $dnatext{$row[0]}{name}{$name} = $data;
      $exists{$name}++;
    } else {
      $dnatext{$row[0]}{other}{$data}++;
    } # else # if ($data =~ m/^ ?([ATCGNatcgn]+) (.+) ?$/)
  } # foreach my $data (@data)
}

foreach my $pgid (sort {$a<=>$b} keys %sequences) {
  my $changed;
  my @dnatext;
  foreach my $sequence (sort keys %{ $sequences{$pgid} }) {
    if ($dnatext{$pgid}{name}{$sequence}) { print "good\t$pgid\t$sequence\n"; }
      else {
        my $dnatext = 'no_match';
        if ($seqToDnatext{$sequence}) { 
          $dnatext = $seqToDnatext{$sequence};
#           print "add $sequence to $pgid\t$dnatext\n"; 	# show only if match
          my $data = $dnatext . ' ' . $sequence;
          push @dnatext, $data; 				# only add if there's a match
        }
#         print "add $sequence to $pgid\t$dnatext\n"; 		# show whether or not match
# TO DO compile things to add, aggregate, change dnatext

# this will find if the sequence_name in a different pgid for that rnai object, just to find out, don't need to do anything.  there were no results found.
#         foreach my $name (sort keys %{ $name{ptn}{$pgid} }) {
#           foreach my $oid (sort keys %{ $name{ntp}{$name} }) {
#             next if ($pgid == $oid);
#             if ($dnatext{$oid}{name}{$sequence}) { print "across pgid\t$pgid\t$sequence\n"; }
#           } # foreach my $oid (sort keys %{ $name{ntp}{$name} })
#         } # foreach my $name (sort keys %{ $name{ptn}{$pgid} })
    }  
  } # foreach my $sequence (sort keys %{ $sequences{$pgid} })
  if (scalar @dnatext > 0) {						# there's new stuff, have to add it.
    foreach my $data (sort keys %{ $dnatext{$pgid}{other} }) { push @dnatext, $data; }
    foreach my $name (sort keys %{ $dnatext{$pgid}{name} }) {
      my $data = $dnatext{$pgid}{name}{$name};
      push @dnatext, $data; }
    my $dnatext = join" | ", @dnatext;
#     print qq(change $pgid to have rna_dnatext $dnatext\n)";
    push @pgcommands, qq(DELETE FROM rna_dnatext WHERE joinkey = '$pgid';);
    push @pgcommands, qq(INSERT INTO rna_dnatext VALUES ('$pgid', '$dnatext'););
    push @pgcommands, qq(INSERT INTO rna_dnatext_hst VALUES ('$pgid', '$dnatext'););
  }
} # foreach my $pgid (sort keys %sequences)

foreach my $pgcommand (@pgcommands) {
  print "$pgcommand\n";
# UNCOMMENT TO POPULATE
#   $dbh->do( $pgcommand );
} # foreach my $pgcommand (@pgcommands)



__END__

