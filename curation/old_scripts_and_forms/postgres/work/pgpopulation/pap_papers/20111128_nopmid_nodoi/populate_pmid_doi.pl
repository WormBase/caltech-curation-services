#!/usr/bin/perl -w

# look at source citations - wbpaperIDs, map to daniela's Xref results to PMID / DOI, add to pap_identifier and h_pap_identifier.  for Daniela and Kimberly.  2011 12 09
#
# ran on tazendra  2011 12 14

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my %pg; my %pmids; my %dois;
my $result = $dbh->prepare( "SELECT * FROM pap_identifier; " );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[1] =~ m/^pmid/) { $pmids{$row[1]} = $row[0]; }
  if ($row[1] =~ m/^doi/) { $dois{$row[1]} = $row[0]; }
  if ($row[2] > $pg{$row[0]}) { $pg{$row[0]} = $row[2]; }
}

my $autoretrievefile = 'doi_automatic_retrieval';
my $papercitationfile = 'type_paper_citation';

my %citationToPaper;
open (IN, "<$papercitationfile") or die "Cannot open $papercitationfile : $!";
while (my $line = <IN>) {
  chomp $line;
  my ($type, $paper, $citation) = split/\t/, $line;
  $citationToPaper{$citation} = $paper;
  $citation =~ s/\s+$//; $citation =~ s/^\s+//; $citation =~ s/\s+/ /g; $citation =~ s/\.+/./g;
  $citationToPaper{$citation} = $paper;
} # while (my $line = <IN>)
close (IN) or die "Cannot close $papercitationfile : $!";

my @pgcommands;
$/ = '';
open (IN, "<$autoretrievefile") or die "Cannot open $autoretrievefile : $!";
while (my $para = <IN>) {
  my (@lines) = split/\n/, $para;
  my $pmid = ''; my $doi = ''; my $joinkey = '';
  my $citation = shift @lines;
  foreach my $line (@lines) {
    if ($line =~ m/PMid:(\d+)/) { $pmid = 'pmid' . $1; }
    elsif ($line =~ m/http:\/\/dx.doi.org\/(.*)/) { $doi = 'doi' . $1; }
  }
  if ($citationToPaper{$citation}) { 
    $joinkey = $citationToPaper{$citation}; 
    if ($pmid) { 
      if ($pmids{$pmid}) { 
#           print "NEW $pmid for $joinkey already exists for $pmids{$pmid} : $citation\n"; 
        }
        else { &addToPgIdentifier($joinkey, $pmid); } 
    }
    if ($doi) { 
      if ($dois{$doi}) { 
#           print "NEW $doi for $joinkey already exists for $dois{$doi} : $citation\n"; 
        }
        else { &addToPgIdentifier($joinkey, $doi); }
    }
  }
#     else { if ($doi || $pmid) { print "ERR no citation match for $doi $pmid : $citation\n"; } }
} # while (my $line = <IN>)
close (IN) or die "Cannot close $autoretrievefile : $!";
$/ = "\n";

foreach my $pgcommand (@pgcommands) {
  print "$pgcommand\n";
# UNCOMMENT TO POPULATE
#   $result = $dbh->do( $pgcommand );
} # foreach my $pgcommand (@pgcommands)

sub addToPgIdentifier {
  my ($joinkey, $identifier) = @_;
  my $order = $pg{$joinkey};
  $order++; $pg{$joinkey} = $order;
  push @pgcommands, "INSERT INTO pap_identifier VALUES ('$joinkey', '$identifier', $order, 'two12028');";
  push @pgcommands, "INSERT INTO h_pap_identifier VALUES ('$joinkey', '$identifier', $order, 'two12028');";
} # sub addToPgIdentifier


__END__

my $result = $dbh->prepare( "SELECT * FROM two_comment WHERE two_comment ~ ?" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[1] =~ s///g;
    $row[2] =~ s///g;
    print "$row[0]\t$row[1]\t$row[2]\n";
  } # if ($row[0])
} # while (@row = $result->fetchrow)

__END__

my $result = $dbh->prepare( 'SELECT * FROM two_comment WHERE two_comment ~ ?' );
$result->execute('elegans') or die "Cannot prepare statement: $DBI::errstr\n"; 

$result->execute("doesn't") or die "Cannot prepare statement: $DBI::errstr\n"; 
my $var = "doesn't";
$result->execute($var) or die "Cannot prepare statement: $DBI::errstr\n"; 

my $data = 'data';
unless (is_utf8($data)) { from_to($data, "iso-8859-1", "utf8"); }

my $result = $dbh->do( "DELETE FROM friend WHERE firstname = 'bl\"ah'" );
(also do for INSERT and UPDATE if don't have a variable to interpolate with ? )

can cache prepared SELECTs with $dbh->prepare_cached( &c. );

if ($result->rows == 0) { print "No names matched.\n\n"; }	# test if no return

$result->finish;	# allow reinitializing of statement handle (done with query)
$dbh->disconnect;	# disconnect from DB

http://209.85.173.132/search?q=cache:5CFTbTlhBGMJ:www.perl.com/pub/1999/10/DBI.html+dbi+prepare+execute&cd=4&hl=en&ct=clnk&gl=us

interval stuff : 
SELECT * FROM afp_passwd WHERE joinkey NOT IN (SELECT joinkey FROM afp_lasttouched) AND joinkey NOT IN (SELECT joinkey FROM cfp_curator) AND afp_timestamp < CURRENT_TIMESTAMP - interval '21 days' AND afp_timestamp > CURRENT_TIMESTAMP - interval '28 days';

casting stuff to substring on other types :
SELECT * FROM afp_passwd WHERE CAST (afp_timestamp AS TEXT) ~ '2009-05-14';

to concatenate string to query result :
  SELECT 'WBPaper' || joinkey FROM pap_identifier WHERE pap_identifier ~ 'pmid';
to get :
  SELECT DISTINCT(gop_paper_evidence) FROM gop_paper_evidence WHERE gop_paper_evidence NOT IN (SELECT 'WBPaper' || joinkey FROM pap_identifier WHERE pap_identifier ~ 'pmid') AND gop_paper_evidence != '';

