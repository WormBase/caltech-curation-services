#!/usr/bin/perl

# get the types from pmids's xml that have ``other'' for type.  2009 07 07
# 
# fixed single types that map to article or multiple types that do not include review, comment, or retracted publication   2009 07 09

use strict;
use DBI;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;


my @pmids = </home/postgres/work/pgpopulation/wpa_papers/type_other/xml/*>;

my %hash;
my %good;
my @no_type;
my $count = 0;

my %makeArticle;	# single types that map to article or multiple types that do not include review, comment, or retracted publication

$/ = undef;
foreach my $file (@pmids) {
  $count++;
  my ($pmid) = $file =~ m/xml\/(.*?)$/;
  open (IN, "<$file") or die "Cannot read $file : $!";
  my $data = <IN>;
  close (IN) or die "Cannot close $file : $!";
  my (@types) = $data =~ m/<PublicationType>(.*?)<\/PublicationType>/sg;
  my @good;
  foreach my $type (@types) {
    ($type) = lc($type);
    next if ($type =~ m/^research support/i);
    push @good, $type;
  } # foreach my $type (@types)
  if (scalar(@good) > 1) {
      my $types = join ", ", @good;
      print "Multiple $pmid : $types\n"; 
      unless ( ($types =~ m/review/) || ($types =~ m/comment/) || ($types =~ m/retracted publication/) ) { $makeArticle{$pmid}++; }
    }
    else { 
      my $type = $good[0]; 
      unless ($type) { push @no_type, $pmid; }
      $good{$type}++; 
      if ($type eq 'journal article') { $makeArticle{$pmid}++; }
  }
  foreach my $type (@good) { $hash{$type}++; }
} # foreach my $file (@pmids)

print "\n\nSingle types :\n";
foreach my $type (sort {$good{$b} <=> $good{$a} } keys %good) {
  print "$good{$type}\t$type\n";
} # foreach my $type (sort {$hash{$a} <=> $hash{$b} } keys %hash)

print "\n\nAll types :\n";
foreach my $type (sort {$hash{$b} <=> $hash{$a} } keys %hash) {
  print "$hash{$type}\t$type\n";
} # foreach my $type (sort {$hash{$a} <=> $hash{$b} } keys %hash)

my $no_type = join", ", @no_type;
print "\n\nNo types : $no_type\n";

print "\nRead $count PMIDs\n";


__END__

### FROM HERE DOWN only to fix single types that map to article or multiple types that do not include review, comment, or retracted publication

my %pmidWpa;
my %wpa;
my %bad;	# pmids that map to multiple WBPapers
$result = $dbh->prepare( "SELECT * FROM wpa ORDER BY wpa_timestamp;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[3] eq 'valid') { $wpa{valid}{$row[0]}++; }
    else { delete $wpa{valid}{$row[0]}; } }
$result = $dbh->prepare( "SELECT * FROM wpa_identifier WHERE wpa_identifier ~ 'pmid' ORDER BY wpa_timestamp;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[3] eq 'valid') { $wpa{id}{$row[0]}{$row[1]}++; }
    else { delete $wpa{id}{$row[0]}{$row[1]}; } }
$result = $dbh->prepare( "SELECT * FROM wpa_type ORDER BY wpa_timestamp;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[3] eq 'valid') { $wpa{type}{$row[0]}{$row[1]}++; }
    else { delete $wpa{type}{$row[0]}{$row[1]}; } }
foreach my $wpa (keys %{ $wpa{id} }) {
  next unless ($wpa{valid}{$wpa});
  foreach my $pmid (keys %{ $wpa{id}{$wpa} }) {
    $pmid =~ s/pmid//;
    if ($pmidWpa{$pmid}) { $bad{$pmid}++; print "ERR $pmid $wpa already exists for $pmidWpa{$pmid}\n"; }
    $pmidWpa{$pmid} = $wpa;
  } # foreach my $pmid (keys %{ $wpa{id}{$wpa} })
} # foreach my $wpa (keys %{ $wpa{id} })
foreach my $pmid (keys %bad) { delete $pmidWpa{$pmid}; }

print "\n\nmake into journal article :\n";
foreach my $pmid (sort keys %makeArticle) {
  my $joinkey = $pmidWpa{$pmid};
  &updateTypeToArticle($joinkey);
  print "$pmid\t$joinkey\n";
} # foreach my $pmid (sort keys %makeArticle)

sub updateTypeToArticle {
  my $joinkey = shift;
  my @commands;
  foreach my $type ( keys %{ $wpa{type}{$joinkey} } ) {
    if ($type eq '17') {
      my $command = "INSERT INTO wpa_type VALUES ('$joinkey', '17', NULL, 'invalid', 'two1843')";
      push @commands, $command;
      $command = "INSERT INTO wpa_type VALUES ('$joinkey', '1', NULL, 'valid', 'two1843')";
      push @commands, $command;
#       print "$joinkey make invalid $type\n";
    }
  } # foreach my $type ( %{ $wpa{type}{$joinkey} } )
  foreach my $command (@commands) {
# UNCOMMENT TO RUN
#     $result = $dbh->do( $command );
    print "$command\n";
  } # foreach my $command (@commands)
}

__END__
                <PublicationType>Case Reports</PublicationType>
                <PublicationType>Journal Article</PublicationType>
                <PublicationType>Research Support, Non-U.S. Gov't</PublicationType>
