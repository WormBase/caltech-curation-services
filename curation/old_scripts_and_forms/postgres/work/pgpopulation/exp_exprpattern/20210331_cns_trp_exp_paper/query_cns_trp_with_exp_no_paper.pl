#!/usr/bin/perl -w

# for Daniela to clean up constructs and transgenes that don't have papers, but do have expression from which we can get papers.  2021 03 31

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %cns_name;
my %trp_name;
my %exp_name;
my %exp_name_to_pgid;
my %cns_paper;
my %trp_paper;
my %exp_paper;
my %cnsToExp;
my %trpToExp;

$result = $dbh->prepare( "SELECT * FROM exp_paper" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $exp_paper{$row[0]} = $row[1]; } }

$result = $dbh->prepare( "SELECT * FROM cns_paper" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $cns_paper{$row[0]} = $row[1]; } }

$result = $dbh->prepare( "SELECT * FROM trp_paper" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $trp_paper{$row[0]} = $row[1]; } }

$result = $dbh->prepare( "SELECT * FROM exp_name" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $exp_name_to_pgid{$row[1]} = $row[0];
    $exp_name{$row[0]} = $row[1]; } }

$result = $dbh->prepare( "SELECT * FROM cns_name" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $cns_name{$row[0]} = $row[1]; } }

$result = $dbh->prepare( "SELECT * FROM trp_name" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $trp_name{$row[0]} = $row[1]; } }


$result = $dbh->prepare( "SELECT * FROM exp_construct" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    my $expName = $exp_name{$row[0]};
    my (@cns) = $row[1] =~ m/(WBCnstr\d+)/g;
    foreach my $cns (@cns) {
      $cnsToExp{$cns} = $expName } } }

$result = $dbh->prepare( "SELECT * FROM exp_transgene" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    my $expName = $exp_name{$row[0]};
    my (@trp) = $row[1] =~ m/(WBTransgene\d+)/g;
    foreach my $trp (@trp) {
      $trpToExp{$trp} = $expName } } }

my $cnsoutfile = 'cns_no_paper_with_expr';
open (CNS, ">$cnsoutfile") or die "Cannot create $cnsoutfile : $!";
foreach my $pgid (sort keys %cns_name) {
  next if ($cns_paper{$pgid});
  my $cns = $cns_name{$pgid};
  if ($cnsToExp{$cns}) { 
    my $expName = $cnsToExp{$cns};
    my $expPgid = $exp_name_to_pgid{$expName};
    my $expPaper = $exp_paper{$expPgid} || 'no paper';
    print CNS qq($cns\t$pgid\tno paper\t$expName\t$expPgid\t$expPaper\n);
  }
}
close (CNS) or die "Cannot close $cnsoutfile : $!";

my $trpoutfile = 'trp_no_paper_with_expr';
open (TRP, ">$trpoutfile") or die "Cannot create $trpoutfile : $!";
foreach my $pgid (sort keys %trp_name) {
  next if ($trp_paper{$pgid});
  my $trp = $trp_name{$pgid};
  if ($trpToExp{$trp}) { 
    my $expName = $trpToExp{$trp};
    my $expPgid = $exp_name_to_pgid{$expName};
    my $expPaper = $exp_paper{$expPgid} || 'no paper';
    print TRP qq($trp\t$pgid\tno paper\t$expName\t$expPgid\t$expPaper\n);
  }
}
close (TRP) or die "Cannot close $cnsoutfile : $!";

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

