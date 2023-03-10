#!/usr/bin/perl -w

# get app_tempname data for conversion of variations names into wbvarIDs.  2010 06 13

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

$/ = undef;
my $variation_file = 'nameserver_Variation.txt';
open (IN, "<$variation_file") or die "Cannot open $variation_file : $!";
my $variation_nameserver_file = <IN>;
close (IN) or die "Cannot open $variation_file : $!";

my %var_data;
$variation_nameserver_file =~ s/^\[\n\s+\[\n//s;
$variation_nameserver_file =~ s/\n\s+\]\n\]//s;
my @var_entries = split/\n\s+\],\n\s+\[\n\s+/, $variation_nameserver_file;
foreach my $entry (@var_entries) {
  my (@lines) = split/\n/, $entry;
  my ($id) = $lines[0] =~ m/(WBVar\d+)/;
  my ($name) = $lines[2] =~ m/\"(.*)\",/;
  my ($dead) = $lines[3] =~ m/\"([10])\"/;
  $var_data{$name}{id} = $id;
  $var_data{$name}{dead} = !$dead;
}

my @pgcommands;
my $result = $dbh->prepare( "SELECT DISTINCT(app_tempname) FROM app_tempname WHERE app_tempname IS NOT NULL AND app_tempname != ''" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  my $entry = $row[0];
  my $new = '';
  if ($var_data{$entry}{id}) { 
      $new = "$var_data{$entry}{id}"; 
      my $command = "UPDATE app_tempname SET app_tempname = '$new' WHERE app_tempname = '$entry';";
      push @pgcommands, $command;
    }
    else { $new = 'not_a_variation'; }
# UNCOMMENT TO SEE mappings
#   print "$entry\t$new\n";
} # while (@row = $result->fetchrow)

$result = $dbh->prepare( "SELECT DISTINCT(app_tempname_hst) FROM app_tempname_hst WHERE app_tempname_hst IS NOT NULL AND app_tempname_hst != ''" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  my $entry = $row[0];
  my $new = '';
  if ($var_data{$entry}{id}) { 
      $new = "$var_data{$entry}{id}"; 
      my $command = "UPDATE app_tempname_hst SET app_tempname_hst = '$new' WHERE app_tempname_hst = '$entry';";
      push @pgcommands, $command;
    }
    else { $new = 'not_a_variation'; }
# UNCOMMENT TO SEE mappings
#   print "$entry\t$new\n";
} # while (@row = $result->fetchrow)

foreach my $command (@pgcommands) {
  print "$command\n";
# UNCOMMENT TO execute
#   $result = $dbh->do( $command );
}


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

