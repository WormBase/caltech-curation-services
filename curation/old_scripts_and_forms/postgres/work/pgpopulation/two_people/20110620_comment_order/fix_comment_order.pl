#!/usr/bin/perl -w

# remap two_comment from all having two_order 1 to having individual orders based on timestamp.  2011 06 20

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );
use Tie::IxHash;


my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my %data;
my $result = $dbh->prepare( "SELECT * FROM two_comment ORDER BY joinkey" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
#     tie %{ $data{$row[0]} }, "Tie::IxHash";
    $data{$row[0]}{$row[2]}{curator} = $row[3];
    $data{$row[0]}{$row[2]}{timestamp} = $row[4];
  } # if ($row[0])
} # while (@row = $result->fetchrow)

my @pgcommands;
push @pgcommands, "DELETE FROM two_comment";
push @pgcommands, "DELETE FROM h_two_comment";
foreach my $joinkey (sort keys %data) {
  my $order = 0;
  foreach my $data (sort { $data{$joinkey}{$a}{timestamp} cmp $data{$joinkey}{$b}{timestamp} } keys %{ $data{$joinkey} }) {
    $order++;
    my $curator = $data{$joinkey}{$data}{curator};
    my $timestamp = $data{$joinkey}{$data}{timestamp};
    if ($data =~ m/\'/) { $data =~ s/\'/''/g; }
    push @pgcommands, "INSERT INTO two_comment VALUES ('$joinkey', '$order', '$data', '$curator', '$timestamp')";
    push @pgcommands, "INSERT INTO h_two_comment VALUES ('$joinkey', '$order', '$data', '$curator', '$timestamp')";
#     print "$joinkey O $order D $data T $timestamp\n";
  } # foreach my $data (keys %{ $data{$joinkey} })
} # foreach my $joinkey (sort keys %data)

foreach my $pgcommand (@pgcommands) {
  print "$pgcommand\n";
#   $dbh->do( $pgcommand );
} # foreach my $pgcommand (@pgcommands)

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

