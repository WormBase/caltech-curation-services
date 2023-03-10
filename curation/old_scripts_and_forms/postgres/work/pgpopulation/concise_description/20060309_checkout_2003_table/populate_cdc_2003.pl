#!/usr/bin/perl

# Populate cdc_2003_refs (keep history) for concise_description_checkout.cgi
# Only works for first set entered in postgres on 2004-06-17, for Kimberly.
# Set to run every monday at 3am.
# 0 3 * * mon /home/postgres/work/pgpopulation/concise_description/20060309_checkout_2003_table/populate_cdc_2003.pl
# 2006 03 10
#
# Updated from wpa to pap tables, although they're not live yet.  2010 06 23
#
# Kimberly doesn't need this anymore, textpresso has replaced this output.  2011 05 11


use strict;
use Jex;
use DBI;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 



my $result = $dbh->prepare( "SELECT * FROM car_con_last_verified WHERE car_timestamp < '2004-06-18' AND joinkey ~ 'WBGene' ORDER BY car_timestamp; " );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
my %dateSort; my @list;
while (my @row = $result->fetchrow) {
  my $date = $row[2]; $date =~ s/\D//g; ($date) = $date =~ m/(.{14})/;		# convert the date into a 14 digit number, some will share this number
  $dateSort{gene}{$row[0]} = $date; }						# store by the gene, value date
foreach my $gene (sort keys %{ $dateSort{gene} }) {				# foreach of these genes
  push @{ $dateSort{date}{ $dateSort{gene}{$gene} } }, $gene; }			# store by the date, pushing genes with the same date into an array
foreach my $date (sort keys %{ $dateSort{date} }) {				# foreach of these dates
  foreach my $gene ( @{ $dateSort{date}{$date} } ) { push @list, $gene; } }	# add the gene to the list

my %countSort;
foreach my $gene (@list) {
#   print "G $gene G\n"; 
#   my $result = $conn->exec( "SELECT COUNT(*) FROM wpa_type WHERE (wpa_type = 1 OR wpa_type = 2) AND joinkey IN ( SELECT joinkey FROM wpa_year WHERE wpa_year > 2002 AND joinkey IN ( SELECT joinkey FROM wpa_gene WHERE wpa_gene ~ '$gene' ) ); ");
    # use articles only, no reviews 2006 03 16
#   my $result = $dbh->prepare( "SELECT COUNT(*) FROM wpa_type WHERE wpa_type = 1 AND joinkey IN ( SELECT joinkey FROM wpa_year WHERE wpa_year > 2002 AND joinkey IN ( SELECT joinkey FROM wpa_gene WHERE wpa_gene ~ '$gene' ) ); ");
  my $result = $dbh->prepare( "SELECT COUNT(*) FROM pap_type WHERE pap_type = 1 AND joinkey IN ( SELECT joinkey FROM pap_year WHERE pap_year > 2002 AND joinkey IN ( SELECT joinkey FROM pap_gene WHERE pap_gene ~ '$gene' ) ); ");
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  my @row = $result->fetchrow();
  my $count = $row[0];
#   print "G $gene C $row[0]\n"; 
  $result = $dbh->do( "INSERT INTO cdc_2003_refs VALUES ('$gene', '$count', CURRENT_TIMESTAMP)" );
}





__END__

SELECT joinkey FROM wpa_type WHERE (wpa_type = 1 OR wpa_type = 2) AND joinkey IN
( SELECT joinkey FROM wpa_year WHERE wpa_year > 2002 AND joinkey IN ( SELECT
joinkey FROM wpa_gene WHERE wpa_gene ~ 'WBGene00004766' ) );

