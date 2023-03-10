#!/usr/bin/perl -w

# from Paul's list at https://docs.google.com/spreadsheets/d/1OZjJopsz5MylkbZJv68N2zi8_mOXlD-_nUZs71OUCIU/edit?ts=6009a877#gid=0
# take top 100 entries and map them to people to get standardname / institution / address

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %email;
$result = $dbh->prepare( "SELECT * FROM two_email ORDER BY two_timestamp" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $email{$row[2]} = $row[0]; }
} # while (@row = $result->fetchrow)

my %data;
$result = $dbh->prepare( "SELECT * FROM two_institution ORDER BY two_timestamp" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $data{$row[0]}{institution}{$row[1]} = $row[2]; } }
$result = $dbh->prepare( "SELECT * FROM two_street ORDER BY two_timestamp" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $data{$row[0]}{street}{$row[1]} = $row[2]; } }
$result = $dbh->prepare( "SELECT * FROM two_state ORDER BY two_timestamp" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $data{$row[0]}{state}{$row[1]} = $row[2]; } }
$result = $dbh->prepare( "SELECT * FROM two_post ORDER BY two_timestamp" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $data{$row[0]}{post}{$row[1]} = $row[2]; } }
$result = $dbh->prepare( "SELECT * FROM two_country ORDER BY two_timestamp" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $data{$row[0]}{country}{$row[1]} = $row[2]; } }

my $infile = 'inputfile';
my $counter = 0;
open(IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) {
  $counter++;
  last if $counter > 101;
  chomp $line;
  my (@data) = split/\t/, $line;
  my $email = $data[3];
  if ($email{$email}) { 
      my $two = $email{$email};
#       print "GOOD $email $email{$email}\n";
#       print "$two\t";
      my ($inst, $street, $state, $post, $country) = ('', '', '', '', '');
      if ($data{$two}{institution}) {
        my @inst;
        foreach my $order (sort keys %{ $data{$two}{institution} }) {
          push @inst, $data{$two}{institution}{$order}; }
        $inst = join"|", @inst; }
      if ($data{$two}{street}) {
        my @street;
        foreach my $order (sort keys %{ $data{$two}{street} }) {
          push @street, $data{$two}{street}{$order}; }
        $street = join"|", @street; }
      if ($data{$two}{state}) {
        $state = $data{$two}{state}{1}; }
      if ($data{$two}{post}) {
        $post = $data{$two}{post}{1}; }
      if ($data{$two}{country}) {
        $country = $data{$two}{country}{1}; }
      my $person = $two; $person =~ s/two/WBPerson/;
      print "$email\t$person\t$inst\t$street\t$state\t$post\t$country\n";
    } else {
      print "BAD $email\n";
    } 
} # while (my $line = <IN>)
close(IN) or die "Cannot open $infile : $!";



__END__

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb;host=131.215.52.76", "", "") or die "Cannot connect to database!\n";	# for remote access

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

