#!/usr/bin/perl -w

# compare small scale .ace dump vs postgres int_name, and int_index tables  2010 10 04

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my $infile = 'WS220Interaction_SmallScale.ace';

my %name;
my %ticket;
my %ace;

my $result = $dbh->prepare( "SELECT * FROM int_name " );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { if ($row[1]) { $name{$row[1]} = $row[0]; } }

$result = $dbh->prepare( "SELECT * FROM int_index " );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { if ($row[1]) { $ticket{"WBInteraction$row[0]"} = $row[1]; } }

$/ = "";
open(IN, "<$infile") or die "Cannot open $infile : $!";
while (my $entry = <IN>) { 
  if ($entry =~ m/Interaction : \"(WBInteraction\d+)\"/) { $ace{$1} = $entry; } 
#     else { print "BAD $entry ENTRY\n"; } 
}
close(IN) or die "Cannot close $infile : $!";

# print "POSTGRES\n";
# 
# foreach my $int (sort keys %name) {
#   unless ($ticket{$int}) { print "In postgres, no index $int\n"; }
#   unless ($ace{$int}) { print "In postgres, no ace $int\n"; }
# }
# 
# print "\n\nACE\n";

foreach my $int (sort keys %ace) {
#   unless ($ticket{$int}) { print "In ace, no index $int\n"; }
#   unless ($name{$int}) { print "In ace, no postgres $int\n"; }
  unless ($name{$int}) { print "$ace{$int}\n"; }
}

# print "\n\nTICKET\n";
# 
# foreach my $int (sort keys %ticket) {
#   unless ($ace{$int}) { print "In ticket, no ace $int\n"; }
#   unless ($name{$int}) { print "In ticket, no postgres $int\n"; }
# }

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

