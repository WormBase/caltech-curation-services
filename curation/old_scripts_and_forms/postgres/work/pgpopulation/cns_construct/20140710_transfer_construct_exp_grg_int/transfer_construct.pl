#!/usr/bin/perl -w

# transfer transgene to construct for datatype : exp, grg, int
# for now all transgenes map to only one construct, so straightforward.
#
# live on tazendra.  2014 07 15

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;


my %transToConst;
$result = $dbh->prepare( "SELECT trp_name.trp_name, trp_construct.trp_construct FROM trp_name, trp_construct WHERE trp_name.joinkey = trp_construct.joinkey;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { if ($row[0]) { $transToConst{$row[0]} = $row[1]; } }

my @pgcommands;
my @datatype = qw( exp grg int );
foreach my $datatype (@datatype) {
  $result = $dbh->prepare( "SELECT * FROM ${datatype}_transgene ORDER BY joinkey;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { 
    my $pgid   = $row[0];
    my (@data) = $row[1] =~ m/(WBTransgene\d+)/g;
    my %const;
    foreach my $data (@data) {
      if ($transToConst{$data}) { $const{$transToConst{$data}}++; }
        else { print "ERR $datatype : $pgid : $data does not map to construct\n"; }
    }
    my $const = join'","', sort keys %const;
    push @pgcommands, qq(INSERT INTO ${datatype}_construct VALUES ('$pgid', '"$const"'););
    push @pgcommands, qq(INSERT INTO ${datatype}_construct_hst VALUES ('$pgid', '"$const"'););
  }
} # foreach my $datatype (@datatype)

foreach my $pgcommand (@pgcommands) {
  print "$pgcommand\n";
# UNCOMMENT TO POPULATE
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

