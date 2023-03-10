#!/usr/bin/perl -w

# compare app_strain and trp_strain to obo_name_strain for future conversion to autocomplete.  2011 05 22

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my %strain;

my $result = $dbh->prepare( "SELECT * FROM obo_name_strain " );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $strain{$row[0]}++; }

my %data;
my @datatypes = qw( app trp );
foreach my $datatype (@datatypes) {
#   my $table = $datatype . '_strain';
  my $table = $datatype . '_strain_hst';
  $result = $dbh->prepare( "SELECT * FROM $table " );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { 
    my %data; 
    my @temp = split/\|/, $row[1];
    foreach my $temp (@temp) {
      my @t2 = split/,/, $temp; foreach (@t2) { $data{$_}++; } }
    my %good; my %bad;
    foreach my $strain (sort keys %data) { 
      $strain =~ s/^\s+//; $strain =~ s/\s+$//; 
      if ($strain{$strain}) { $good{$strain}++; }
        else { $bad{$strain}++; } }
    my $bad = join", ", keys %bad;
    if ($bad) { print "BAD $table $row[0] $bad $row[2]\n"; }
    my $good = join'","', keys %good; 
    if ($good) {
      $good = '"' . $good . '"';
      print "$table $row[0] : $row[1] TO $good\n";
    }
  } # while (my @row = $result->fetchrow) 
} # foreach my $datatype (@datatypes)

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

