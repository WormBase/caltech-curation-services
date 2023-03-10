#!/usr/bin/perl -w

# get cfp_ stats for amount curated per curator and new paper count.  2009 04 23
#
# inside :
# 0 2 * * mon /home/postgres/work/get_stuff/for_paul/curation_stats/wrapper.sh
# 2009 04 23


use strict;
use diagnostics;
use DBI;
use Jex;	# mailer

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my %hash;
my $result = $dbh->prepare( "SELECT cfp_curator.joinkey, two_standardname.two_standardname FROM cfp_curator, two_standardname WHERE cfp_curator.cfp_timestamp > '2009-01-01' AND two_standardname.joinkey = cfp_curator.cfp_curator" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { if ($row[0]) { $hash{$row[1]}++; } } 

my $body = '';
foreach my $curator (sort keys %hash) {
  $body .= "$curator\t$hash{$curator}\n";
}

# this doesn't work, cross product result
# $result = $dbh->prepare( "SELECT wpa.joinkey FROM wpa, wpa_type, wpa_ignore WHERE wpa.joinkey NOT IN (SELECT joinkey FROM wpa_ignore) AND wpa.joinkey NOT IN (SELECT joinkey FROM wpa_type WHERE wpa_type = '3' OR wpa_type = '4' OR wpa_type = '17') AND wpa.wpa_timestamp > '2009-01-01'" );

my %wpa;
my %type;
my %ignore;
my %valid;


$result = $dbh->prepare( "SELECT * FROM wpa_type ORDER BY wpa_timestamp"  );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow()) {
  if ($row[3] eq 'valid') { $type{$row[0]}{$row[1]}++; }
    else { delete $type{$row[0]}{$row[1]}; }
}

$result = $dbh->prepare( "SELECT * FROM wpa_ignore ORDER BY wpa_timestamp"  );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow()) {
  if ($row[3] eq 'valid') { $ignore{$row[0]}{$row[1]}++; }
    else { delete $ignore{$row[0]}{$row[1]}; }
}

$result = $dbh->prepare( "SELECT * FROM wpa ORDER BY wpa_timestamp"  );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow()) {
  if ($row[3] eq 'valid') { $valid{$row[0]}{$row[1]}++; }
    else { delete $valid{$row[0]}{$row[1]}; }
}

$result = $dbh->prepare( "SELECT * FROM wpa WHERE wpa_timestamp > '2009-01-01'"  );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow()) {
  next unless ($valid{$row[0]});
  next if ($ignore{$row[0]});
  next if ($type{$row[0]}{2});	# review
  next if ($type{$row[0]}{3});	# meeting_abstract
  next if ($type{$row[0]}{4});	# gazette_abstract
  next if ($type{$row[0]}{17});	# other
  next if ($type{$row[0]}{18});	# wormbook
  $wpa{$row[0]}++;
}

my $count = scalar( keys %wpa);

$body .= "There have been $count papers\n";

my $user = 'allele_phenotype_stats_get_recent_app.pl';
# my $email = 'azurebrd@its.caltech.edu';
my $email = 'pws@its.caltech.edu';
my $subject = 'Papers in 2009, count and curated';

&mailer($user, $email, $subject, $body);




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
