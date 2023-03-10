#!/usr/bin/perl -w

# looks for a joinkey + tempname + term  where joinkey has no paper, no person, no nbp.  These were likely mistakenly entered by duplicating a phenote character and not saving the nbp data.  match these to a tempname that has nbp, but no person nor paper (some will have multiple matches, but the nbp will be correctly duplicated) and output.  some will have no match, output those at the end.  Later will need to insert or update app_nbp for those joinkeys with that nbp + timestamp  2009 05 14
#
# inserted this script into 
# /home/acedb/work/allele_phenotype/use_package.pl
# to fix nbps before dumping (easier than fixing jolene's phenote java timestamp issue)  2009 08 08


use strict;
use diagnostics;
use DBI;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

# joinkey, tempname (allele), term where joinkey has no paper, no person, no nbp
my $result = $dbh->prepare( " SELECT app_tempname.joinkey, app_tempname.app_tempname, app_term.app_term FROM app_tempname, app_term WHERE app_tempname.joinkey = app_term.joinkey AND app_tempname.joinkey NOT IN (SELECT joinkey FROM app_paper) AND app_tempname.joinkey NOT IN (SELECT joinkey FROM app_person) AND app_tempname.joinkey NOT IN (SELECT joinkey FROM app_nbp) AND app_tempname.app_tempname != '' ORDER BY app_tempname.app_tempname; " );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 

my @nomatch;
while (my @row = $result->fetchrow) {
  my $source = "$row[0]\t$row[1]\t$row[2]\t";

  my %nbps;

  my $tempname = $row[1];
  my $result2 = $dbh->prepare( "
  SELECT app_tempname.joinkey, app_tempname.app_tempname, app_term.app_term, app_nbp.app_nbp, app_nbp.app_timestamp 
  FROM app_tempname, app_term, app_nbp 
  WHERE 
    app_tempname.joinkey = app_term.joinkey AND 
    app_tempname.joinkey = app_nbp.joinkey  AND 
    app_tempname.joinkey NOT IN (SELECT joinkey FROM app_paper) AND 
    app_tempname.joinkey NOT IN (SELECT joinkey FROM app_person) AND 
    app_nbp.app_nbp IS NOT NULL AND
    app_tempname.app_tempname = '$tempname'; 
  "); 
  $result2->execute();
  while (my @row2 = $result2->fetchrow) {
    my $key = "$row2[3]\t$row2[4]";
    push @{ $nbps{$key} },  "$row2[0]\t$row2[1]\t$row2[2]\t$row2[3]\t$row2[4]";
  } # while (my @row2 = $result2->fetchrow)

  my @keys = keys %nbps;
  if (scalar @keys > 1) { 
    foreach my $key (sort keys %nbps) {
      foreach my $match (@{ $nbps{$key} }) {
        print "ERR multiple NBPs $source\t$match\n"; } } }
  elsif (scalar @keys == 1) {
    foreach my $key (sort keys %nbps) {
      my ($nbp, $timestamp) = split/\t/, $key;
# UNCOMMENT TO INSERT DATA FOR NBP
      my $result3 = $dbh->do( "INSERT INTO app_nbp VALUES ('$row[0]', '$nbp', '$timestamp')" );
      my $result4 = $dbh->do( "INSERT INTO app_nbp_hst VALUES ('$row[0]', '$nbp', '$timestamp')" );	# forgot this nbp_hst missing data  2009 05 14
#       print "$row[0]\t$nbp\t$timestamp\n"; 
      print "$source\t$key\n"; 
  } }
  elsif (scalar @keys < 1) {
    push @nomatch, "NO MATCH $source\n"; }
} # while (@row = $result->fetchrow)

foreach (@nomatch) { print; }

__END__

$result->execute("doesn't") or die "Cannot prepare statement: $DBI::errstr\n"; 
my $var = "doesn't";
$result->execute($var) or die "Cannot prepare statement: $DBI::errstr\n"; 

my $result = $dbh->do( "DELETE FROM friend WHERE firstname = 'bl\"ah'" );
(also do for INSERT and UPDATE if don't have a variable to interpolate with ? )

can cache prepared SELECTs with $dbh->prepare_cached( &c. );

if ($result->rows == 0) { print "No names matched.\n\n"; }	# test if no return

$result->finish;	# allow reinitializing of statement handle (done with query)
$dbh->disconnect;	# disconnect from DB

http://209.85.173.132/search?q=cache:5CFTbTlhBGMJ:www.perl.com/pub/1999/10/DBI.html+dbi+prepare+execute&cd=4&hl=en&ct=clnk&gl=us
