#!/usr/bin/perl -w

# look at OA config to query all tables for empty strings and get the most recent timestamp for each.
# to remove those entries for Chris.  2019 10 02


use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

use lib qw( /home/postgres/public_html/cgi-bin/oa );
use wormOA;


my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %fields;                             # tied for order   $fields{app}{id} = 'text';

my @delete_tables;
my $count = 0;
my $datatype_list_href = &populateWormDatatypeList();
foreach my $datatype (keys %$datatype_list_href) {
  my ($fieldsRef, $datatypesRef) = &initModFields($datatype, '');
  %fields = %$fieldsRef;
  foreach my $field (sort keys %{ $fields{$datatype} }) {
    next if ($field eq 'id');
#     print qq(D $datatype F $field E\n);
    my $table = $datatype . '_' . $field;
#     $result = $dbh->prepare( "SELECT * FROM $table WHERE $table = '' ORDER BY ${datatype}_timestamp DESC LIMIT 1" );
    $result = $dbh->prepare( "SELECT * FROM $table WHERE $table = '' ORDER BY ${datatype}_timestamp DESC" );
#     $result = $dbh->prepare( "SELECT * FROM $table WHERE $table = '' LIMIT 1" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    my @row = $result->fetchrow();
    if ($row[0]) { 
      push @delete_tables, $table;
      print qq ($table\t@row\n); }
#     $count++; last if ($count > 5);
#     while (my @row = $result->fetchrow) {
#       $count++; last if ($count > 5);
#       if ($row[0]) { print qq ($table\t@row\n); }
#     } 
  }
}

foreach my $table (@delete_tables) {
  my $pgcommand = qq(DELETE FROM $table WHERE $table = '';);
  print qq($pgcommand\n);
# UNCOMMENT TO DELETE
#   $result = $dbh->do( $pgcommand );
}

__END__

$result = $dbh->prepare( "SELECT * FROM two_comment" );
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

