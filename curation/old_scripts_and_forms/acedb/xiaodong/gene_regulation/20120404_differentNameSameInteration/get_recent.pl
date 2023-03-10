#!/usr/bin/perl -w

# query for genereg with different name and same ID  2012 04 04

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my %hash;
my $result = $dbh->prepare( "SELECT * FROM grg_intid" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { if ($row[0]) { $hash{$row[1]}{$row[0]}++; } }

foreach my $int (sort keys %hash) {
  my @pgids = sort keys %{ $hash{$int} };
  my $intCount = scalar @pgids;
  if ($intCount > 1) { 
    my %names;
    foreach my $pgid (@pgids) {
      my $result = $dbh->prepare( "SELECT * FROM grg_name WHERE joinkey = '$pgid'" );
      $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
      while (my @row = $result->fetchrow) { if ($row[0]) { $names{$row[1]}++; } }
    } # foreach my $pgid (@pgids)
    my @names = sort keys %names;
    my $nameCount = scalar @names;
    if ($nameCount > 1) { 
     print "INT $int\tintCount $intCount\tnames @names\n"; 
    }
#     foreach my $name (sort keys %names) {
#       if ($names{$name} > 1) { print "NAME $name\tINT $int\tintCount $intCount\tname count $names{$name}\n"; }
#     } # foreach my $name (sort keys %names)
#     print "$int\t$intCount\t@pgids\n"; 
  }
} # foreach my $int (sort keys %hash)

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

