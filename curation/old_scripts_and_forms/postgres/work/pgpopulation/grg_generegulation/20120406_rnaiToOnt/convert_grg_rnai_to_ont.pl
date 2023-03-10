#!/usr/bin/perl -w

# convert grg_rnai to ontology  2012 04 06
# 
# live run 2012 04 18

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %valid;
$result = $dbh->prepare( "SELECT * FROM rna_name" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $valid{$row[1]}++; }

my @pgcommands;

$result = $dbh->prepare( "SELECT * FROM grg_rnai" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[1]) { 
    my $joinkey = $row[0]; my $timestamp = $row[2];
    my %verified;
    my (@rnai) = split/\|/, $row[1];
    foreach my $rnai (@rnai) { 
      $rnai =~ s/ //g;
      if ($valid{$rnai}) { $verified{$rnai}++; }
        else { print "ERR invalid $rnai in $joinkey\n"; }
    }
    my $rnai = join'","', sort keys %verified;
    $rnai = '"' . $rnai . '"';
    push @pgcommands, "DELETE FROM grg_rnai WHERE joinkey = '$joinkey';";
    push @pgcommands, "INSERT INTO grg_rnai VALUES ('$joinkey', '$rnai');";
    push @pgcommands, "INSERT INTO grg_rnai_hst VALUES ('$joinkey', '$rnai');";
#     print "$joinkey\t$rnai\n";  
  } # if ($row[1])
} # while (@row = $result->fetchrow)

foreach my $pgcommand (@pgcommands) {
  print "$pgcommand\n";
#   $dbh->do( $pgcommand );	# UNCOMMENT to transfer from text-pipe to multiontology
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

