#!/usr/bin/perl -w

# looks for a joinkey + tempname + term  where joinkey has no paper, no person, no nbp.  These were likely mistakenly entered by duplicating a phenote character and not saving the nbp data.  match these to a tempname that has nbp, but no person nor paper (some will have multiple matches, but the nbp will be correctly duplicated) and output.  some will have no match, output those at the end.  Later will need to insert or update app_nbp for those joinkeys with that nbp + timestamp  2009 05 14

use strict;
use diagnostics;
use DBI;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

# joinkey, tempname (allele), term where joinkey has no paper, no person, no nbp
my $result = $dbh->prepare( " SELECT * FROM app_nbp WHERE joinkey NOT IN (SELECT joinkey FROM app_nbp_hst); " );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  print "$row[0]\t$row[1]\t$row[2]\n";
# copy the nbp that is not in nbp_hst  2009 05 14
#   my $result4 = $dbh->do( "INSERT INTO app_nbp_hst VALUES ('$row[0]', '$row[1]', '$row[2]')" );	
} # while (@row = $result->fetchrow)

