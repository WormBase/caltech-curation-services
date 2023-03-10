#!/usr/bin/perl -w

# convert gop_with and gop_with_hst data into gop_with (other), gop_with_wbvariation, and gop_with_wbgene (and the _hst counterparts)  2010 06 13

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

my $result = $dbh->prepare( "SELECT * FROM gop_with WHERE gop_with IS NOT NULL" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  my $id = $row[0];
  my $old = $row[1];
  my $timestamp = $row[2];
  my (@entries) = split/\|/, $old;
  my @other; my @variation; my @wbvar; my @wbgenes;
  foreach my $entry (@entries) { 
    my $orig_entry = $entry;
    $entry =~ s/WB://g;
    if ($var_data{$entry}{id}) { push @variation, "WB:$entry"; push @wbvar, $var_data{$entry}{id}}
      elsif ($entry =~ m/^WBGene\d+$/) { push @wbgenes, $entry; }
      else { push @other, "$orig_entry"; } }
  my $other = join"|", @other;
  my $variation = join"|", @variation;
  my $wbvar = join"\",\"", @wbvar; if ($wbvar) { $wbvar = '"'. $wbvar . '"'; }
  my $wbgenes = join"\",\"", @wbgenes; if ($wbgenes) { $wbgenes = '"'. $wbgenes . '"'; }
#   print "$id\t$old\t$with\t$variation\t$wbvar\n";
#   print "$id\t$old\t$other\t$wbgenes\t$wbvar\n";
  push @pgcommands, "DELETE FROM gop_with WHERE joinkey = '$id' AND gop_timestamp = '$timestamp';";
  if ($other) { push @pgcommands, "INSERT INTO gop_with VALUES ('$id', '$other', '$timestamp');"; }
  if ($wbgenes) { push @pgcommands, "INSERT INTO gop_with_wbgene VALUES ('$id', '$wbgenes', '$timestamp');"; }
  if ($wbvar) { push @pgcommands, "INSERT INTO gop_with_wbvariation VALUES ('$id', '$wbvar', '$timestamp');"; }
} # while (@row = $result->fetchrow)

$result = $dbh->prepare( "SELECT * FROM gop_with_hst WHERE gop_with_hst IS NOT NULL" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  my $id = $row[0];
  my $old = $row[1];
  my $timestamp = $row[2];
  my (@entries) = split/\|/, $old;
  my @other; my @variation; my @wbvar; my @wbgenes;
  foreach my $entry (@entries) { 
    my $orig_entry = $entry;
    $entry =~ s/WB://g;
    if ($var_data{$entry}{id}) { push @variation, "WB:$entry"; push @wbvar, $var_data{$entry}{id}}
      elsif ($entry =~ m/^WBGene\d+$/) { push @wbgenes, $entry; }
      else { push @other, "$orig_entry"; } }
  my $other = join"|", @other;
  my $variation = join"|", @variation;
  my $wbvar = join"\",\"", @wbvar; if ($wbvar) { $wbvar = '"'. $wbvar . '"'; }
  my $wbgenes = join"\",\"", @wbgenes; if ($wbgenes) { $wbgenes = '"'. $wbgenes . '"'; }
#   print "$id\t$old\t$with\t$variation\t$wbvar\n";
#   print "$id\t$old\t$other\t$wbgenes\t$wbvar\n";
  push @pgcommands, "DELETE FROM gop_with_hst WHERE joinkey = '$id' AND gop_timestamp = '$timestamp';";
  if ($other) { push @pgcommands, "INSERT INTO gop_with_hst VALUES ('$id', '$other', '$timestamp');"; }
  if ($wbgenes) { push @pgcommands, "INSERT INTO gop_with_wbgene_hst VALUES ('$id', '$wbgenes', '$timestamp');"; }
  if ($wbvar) { push @pgcommands, "INSERT INTO gop_with_wbvariation_hst VALUES ('$id', '$wbvar', '$timestamp');"; }
} # while (@row = $result->fetchrow)

foreach my $command (@pgcommands) {
  print "$command\n";
# UNCOMMENT TO change database
#   $result = $dbh->do( $command );
} # foreach my $command (@pgcommands)


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

