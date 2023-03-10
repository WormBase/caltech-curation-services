#!/usr/bin/perl


use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my %pmid;
my $result = $conn->exec( "SELECT * FROM wpa_identifier WHERE wpa_identifier ~ 'pmid' ORDER BY wpa_timestamp;" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[1] =~ s/pmid//g;
    $pmid{$row[1]} = $row[0];
  } # if ($row[0])
} # while (@row = $result->fetchrow)

my %emails;
my $infile = 'textpresso_emails';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) {
  chomp $line;
  my ($pap, $email) = split/\t/, $line;
  $emails{$pap} = $email;
} # while (my $line = <IN>)
close (IN) or die "Cannot close $infile : $!";

$infile = 'test_papers';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $pmid = <IN>) {
  chomp $pmid;
  unless ($pmid{$pmid}) { print "no paper match for $pmid\n"; next; }
  my ($wpa) = $pmid{$pmid};
  unless ($emails{$wpa}) { print "no email match for $pmid\n"; next; }
  print "$pmid is $wpa with $emails{$wpa}\n";
} # while (my $line = <IN>)
close (IN) or die "Cannot close $infile : $!";


__END__

