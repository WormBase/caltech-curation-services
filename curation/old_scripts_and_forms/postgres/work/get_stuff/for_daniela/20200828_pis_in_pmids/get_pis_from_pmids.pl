#!/usr/bin/perl -w

# for a list of pmids, get the PIs

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;


my %pis;
$result = $dbh->prepare( "SELECT * FROM two_pis" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  $pis{$row[0]}++;
}
my %twoName;
$result = $dbh->prepare( "SELECT * FROM two_standardname" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  $twoName{$row[0]} = $row[2];
}
my %twoEmail;
$result = $dbh->prepare( "SELECT * FROM two_email ORDER BY two_timestamp" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  $twoEmail{$row[0]} = $row[2];
}


my %year; my %title;
$result = $dbh->prepare( "SELECT * FROM pap_year" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  $year{$row[0]} = $row[1];
} 
$result = $dbh->prepare( "SELECT * FROM pap_title" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  $title{$row[0]} = $row[1];
} 



my %pmids;
my $pmidFile = 'pmids';
open (IN, "<$pmidFile") or die "Cannot open $pmidFile : $!";
while (my $line = <IN>) {
  chomp $line;
  $pmids{$line}++;
} # while (my $line = <IN>)
close (IN) or die "Cannot close $pmidFile : $!";

# PI, year, pmid title

my %pmidPap; my %pap;
foreach my $pmid (sort keys %pmids) {
  $result = $dbh->prepare( "SELECT * FROM pap_identifier WHERE pap_identifier ~ 'pmid$pmid'" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    if ($row[0]) { 
      $pap{$row[0]}++;
      $pmidPap{$pmid} = $row[0];
    } # if ($row[0])
  } # while (@row = $result->fetchrow)
} 

my $noMatch = '';
foreach my $pmid (sort keys %pmids) {
  my $pap = 0;
  if ($pmidPap{$pmid}) { 
    $pap = $pmidPap{$pmid}; 
    &getPi($pmid, $pap);
  } else {
    $noMatch .= qq($pmid\tNo WormBase Paper\n);
  } 
} # foreach my $pmid (sort keys %pmids)

print qq(\nNo paper match\n$noMatch);

sub getPi {
  my ($pmid, $pap) = @_;
  my %authors; my %persons; my %verified;
  $result = $dbh->prepare( "SELECT * FROM pap_author WHERE joinkey = '$pap'" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
# print qq($pap AUT $row[1]\n);
    $authors{$row[1]}++;
  } # while (my @row = $result->fetchrow)
  foreach my $aid (sort keys %authors) {
    $result = $dbh->prepare( "SELECT * FROM pap_author_verified WHERE author_id = '$aid' AND pap_author_verified ~ 'YES'" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) {
      $verified{$aid}{$row[2]} = $row[1];
# print qq(VERIFIED $aid $row[2] $row[1]\n);
    } # while (my @row = $result->fetchrow)
  }
  foreach my $aid (sort keys %authors) {
    $result = $dbh->prepare( "SELECT * FROM pap_author_possible WHERE author_id = '$aid'" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) {
#       $persons{$aid}{$row[2]} = $row[1];
      if ($verified{$aid}{$row[2]}) { 
        $persons{$row[1]}++;
# print qq(PERSON $row[1]\n);
      }
    } # while (my @row = $result->fetchrow)
  }
  my %isPi;
  foreach my $person (sort keys %persons) {
    if ($pis{$person}) {
      my $name = $twoName{$person};
      my $email = $twoEmail{$person};
      $person =~ s/two/WBPerson/;
      my $year = ''; if ($year{$pap}) { $year = $year{$pap}; }
      my $title = ''; if ($title{$pap}) { $title = $title{$pap}; }
      print qq($pmid\t$person\t$name\t$email\tWBPaper$pap\t$year\t$title\n);
  } }
#   my $persons = join",", sort keys %persons;
#   print qq($pap\t$persons\n);
}

__END__

