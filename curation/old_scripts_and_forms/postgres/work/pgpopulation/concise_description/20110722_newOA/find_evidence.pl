#!/usr/bin/perl -w

# find car_ reference stuff that are not papers.  2011 07 25

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my @subtypes = qw( curator reference accession );     # changed boxes for carol 2005 05 12

my @tables = qw( car_con_ref_reference car_hum_ref_reference );
my @special;

my @PGsubparameters = qw( seq fpa fpi bio mol exp oth phe );

foreach my $sub (@PGsubparameters) { 
  my $table = "car_" . $sub . "_ref_reference";
  push @special, $table;
}

my %dataToPap;
my $result = $dbh->prepare( "SELECT * FROM pap_identifier WHERE pap_identifier IS NOT NULL" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  $dataToPap{"WBPaper$row[0]"} = $row[0];
  $dataToPap{$row[1]} = $row[0]; }

my %geneToCurator;
foreach my $table (@tables) {
  my $other = $table;
  $other =~ s/reference/curator/;
  my $result = $dbh->prepare( "SELECT * FROM $other WHERE $other IS NOT NULL AND joinkey ~ 'WBGene' AND joinkey != 'WBGene00000000' ORDER BY car_timestamp" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { $geneToCurator{$table}{$row[0]} = $row[1]; }
}
foreach my $table (@special) {
  my $other = $table;
  $other =~ s/reference/curator/;
  my $result = $dbh->prepare( "SELECT * FROM $other WHERE $other IS NOT NULL AND joinkey ~ 'WBGene' AND joinkey != 'WBGene00000000' ORDER BY car_timestamp" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { $geneToCurator{$table}{$row[0]}{$row[1]} = $row[2]; }
}


my %filter;
foreach my $table (@special) {
  my $result = $dbh->prepare( "SELECT * FROM $table WHERE $table IS NOT NULL AND joinkey ~ 'WBGene' AND joinkey != 'WBGene00000000' ORDER BY car_timestamp" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  %filter = ();
  while (my @row = $result->fetchrow) { $filter{$row[0]}{$row[1]} = $row[2]; }
  foreach my $joinkey (sort keys %filter) {
    foreach my $order (sort keys %{ $filter{$joinkey} }) {
      my $data = $filter{$joinkey}{$order};
      my @data = split/,/, $data;
      my $curator = 'unknown';
      if ($geneToCurator{$table}{$joinkey}{$order}) { $curator = $geneToCurator{$table}{$joinkey}{$order}; }
      foreach my $data (@data) {
        $data =~ s/^\s+//g; $data =~ s/\s+$//g; 
        unless ($dataToPap{$data}) { print "TABLE $table\tCURATOR $curator\tGENE $joinkey\tORDER $order\tDATA $data\n"; }
      } # foreach my $data (@data)
    } # foreach my $order (sort keys %{ $filter{$joinkey} })
  } # foreach my $joinkey (sort keys %filter)
} # foreach my $table (@special)

foreach my $table (@tables) {
  my $result = $dbh->prepare( "SELECT * FROM $table WHERE $table IS NOT NULL AND joinkey ~ 'WBGene' ORDER BY car_timestamp" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  %filter = ();
  while (my @row = $result->fetchrow) { $filter{$row[0]} = $row[1]; }
  foreach my $joinkey (sort keys %filter) {
    my $data = $filter{$joinkey};
    my @data = split/,/, $data;
    my $curator = 'unknown';
    if ($geneToCurator{$table}{$joinkey}) { $curator = $geneToCurator{$table}{$joinkey}; }
    foreach my $data (@data) {
      $data =~ s/^\s+//g; $data =~ s/\s+$//g; 
      unless ($dataToPap{$data}) { print "TABLE $table\tCURATOR $curator\tGene $joinkey\tDATA $data\n"; }
    } # foreach my $data (@data)
  } # foreach my $joinkey (sort keys %filter)
} # foreach my $table (@tables)



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

