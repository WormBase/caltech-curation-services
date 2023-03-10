#!/usr/bin/perl

# Create a method for entering WormBook entries as processed by Igor.
# This creates In_book entries (for WormBook)  and uses wpa_match.pm
# which has a new section to deal with wormbook data, and also now 
# includes editor and fulltext_url options.  2006 04 28

use strict;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

$/ = "";

my $infile = 'gene_connection_for_postgres.ace';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $para = <IN>) {
  my (@lines) = split/\n/, $para;
  my $header = shift @lines;
  my $joinkey = '';
  if ($header =~ m/Paper : \"WBPaper(\d+)\"/) { $joinkey = $1; } else { print "ERR no joinkey $para\n"; next; }
  foreach my $line (@lines) {
    if ($line =~ m/^Gene\t\"(.*)\"$/) { 
      my $command = "INSERT INTO wpa_gene VALUES ('$joinkey', '$1', NULL, 'valid', 'two22', CURRENT_TIMESTAMP)"; 
      my $result = $conn->exec( $command );
      print "$command\n";
    }
  } # foreach my $line (@lines)
} # while (my $para = <IN>)
close (IN) or die "Cannot close $infile : $!";


__END__

foreach my $tag (sort keys %tags) { print "TAG $tag\n"; }

TAG Abstract
TAG Author
TAG In_book
TAG PDF
TAG Title
TAG URL
TAG Year

DELETE FROM wpa WHERE wpa_timestamp > '2006-04-28 20:15:00';
DELETE FROM wpa_title WHERE wpa_timestamp > '2006-04-28 20:15:00';
DELETE FROM wpa_identifier WHERE wpa_timestamp > '2006-04-28 20:15:00';
DELETE FROM wpa_year WHERE wpa_timestamp > '2006-04-28 20:15:00';
DELETE FROM wpa_type WHERE wpa_timestamp > '2006-04-28 20:15:00';
DELETE FROM wpa_author WHERE wpa_timestamp > '2006-04-28 20:15:00';
DELETE FROM wpa_fulltext_url WHERE wpa_timestamp > '2006-04-28 20:15:00';
DELETE FROM wpa_in_book WHERE wpa_timestamp > '2006-04-28 20:15:00';
DELETE FROM wpa_editor WHERE wpa_timestamp > '2006-04-28 20:15:00';
DELETE FROM wpa_author_index WHERE wpa_timestamp > '2006-04-28 20:15:00';

