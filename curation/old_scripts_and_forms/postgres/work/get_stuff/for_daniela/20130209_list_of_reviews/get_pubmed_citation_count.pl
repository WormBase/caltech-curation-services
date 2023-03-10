#!/usr/bin/perl -w

# for Daniela and Oliver Hobert for WormBook, get list of papers that are reviews, sort by year.  2013 02 11
#
# revisit to get those with PMIDs and get citation count from (replace number with pmid)
# http://www.ncbi.nlm.nih.gov/pmc/articles/pmid/19875495/citedby/?tool=pubmed
# for Jane.  2013 05 07

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );
use LWP::Simple;
use LWP::UserAgent;

my $ua = LWP::UserAgent->new(timeout => 30);  # instantiates a new user agent
$ua->agent( 'Mozilla/5.0 (X11; U; Linux x86_64; en-US; rv:1.9.2.18) Gecko/20110615 Ubuntu/10.04 (lucid) Firefox/3.6.18');



my %byCitations;

my $max = 4; my $count = 0;
my $infile = 'list';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) {
  chomp $line;
  my (@stuff) = split/\t/, $line;
  if ($stuff[1]) {
    my $pmid = $stuff[1];
#     print "$pmid\n";
    $count++; last if ($count > $max);		# comment out to run on whole set
    $pmid =~ s/pmid//;
    my $url = "http://www.ncbi.nlm.nih.gov/pmc/articles/pmid/${pmid}/citedby/?tool=pubmed";
#     my $page = get $url;
    my $request = HTTP::Request->new(GET => $url);  # grabs url
    my $response = $ua->request($request);        # checks url, dies if not valid.
#     unless ($response-> is_success) {
#       print "Error while getting ", $response->request->uri," -- ", $response->status_line, "\nABORTING QUERY Amazon\n";
#       die "program dying now\n";
#     }
    my $page = $response->content;
    my $citations = 0;
    if ($page =~ m/Is Cited by the Following (\d+) Articles in this Archive/) { $citations = $1; }
    push @{ $byCitations{$citations} }, $line;
    sleep(3);
#     print "PAGE $page END PAGE\n";
  }
} # while (my $line = <IN>)
close (IN) or die "Cannot close $infile : $!";

foreach my $citations (sort {$b <=> $a} keys %byCitations) {
  foreach my $line (@{ $byCitations{$citations} }) {
    print "$citations\t$line\n";
  } # foreach my $line (@{ $byCitations{$citations} })
} # foreach my $citations (sort {$b <=> $a} keys %byCitations)

__END__

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %valid;
$result = $dbh->prepare( "SELECT * FROM pap_status WHERE pap_status = 'valid';" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $valid{$row[0]}++; }

my %reviews;
$result = $dbh->prepare( "SELECT * FROM pap_type WHERE pap_type = '2';" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $reviews{$row[0]}++; }

my %pmids;
$result = $dbh->prepare( "SELECT * FROM pap_identifier WHERE pap_identifier ~ 'pmid';" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $pmids{$row[0]} = $row[1]; }

my %title;
$result = $dbh->prepare( "SELECT * FROM pap_title;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $title{$row[0]} = $row[1]; }

my %journal;
$result = $dbh->prepare( "SELECT * FROM pap_journal;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $journal{$row[0]} = $row[1]; }

my %pages;
$result = $dbh->prepare( "SELECT * FROM pap_pages;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $pages{$row[0]} = $row[1]; }

my %year;
$result = $dbh->prepare( "SELECT * FROM pap_year;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $year{$row[0]} = $row[1]; }

my %aids; my %authors;
$result = $dbh->prepare( "SELECT * FROM pap_author;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $aids{$row[0]}{$row[2]} = $row[1]; }
$result = $dbh->prepare( "SELECT * FROM pap_author_index;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $authors{$row[0]} = $row[1]; }

my %by_year;
foreach my $joinkey (sort keys %reviews) {
  next unless $valid{$joinkey};
  my @authors;
  foreach my $order (sort {$a<=>$b} keys %{ $aids{$joinkey} }) { push @authors, $authors{$aids{$joinkey}{$order}}; }
  my $authors = join", ", @authors;
  push @{ $by_year{$year{$joinkey}} }, "WBPaper$joinkey\t$pmids{$joinkey}\t$authors\t$title{$joinkey}\t$journal{$joinkey}\t$year{$joinkey}\t$pages{$joinkey}\n";
} # foreach my $joinkey (sort keys %reviews)

foreach my $year (sort {$a<=>$b} keys %by_year) {
  foreach my $line (@{ $by_year{$year} }) { print $line; }
} # foreach my $year (sort {$a<=>$b} keys %by_year)
