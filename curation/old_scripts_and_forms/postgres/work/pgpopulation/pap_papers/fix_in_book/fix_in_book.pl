#!/usr/bin/perl -w

# move in_book stuff from wiki data into their own real paper entries, merge into contained_in / contains
# 2010 01 25
#
# ran 2010 01 27, but had parse error for contained in, so have to fix with blah.pl  
#
# actual fields used in in_book :
# title  editor  publisher  volume  pages  year  journal  type  author

use strict;
use diagnostics;
use DBI;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my @tables = qw( wpa wpa_comments wpa_gene wpa_abstract wpa_contained_in wpa_hardcopy wpa_remark wpa_affiliation wpa_contains wpa_identifier wpa_rnai_curation wpa_allele_curation wpa_date_published wpa_ignore wpa_rnai_int_done wpa_author wpa_editor wpa_in_book wpa_title wpa_electronic_path_md5 wpa_journal wpa_transgene_curation wpa_electronic_path_type wpa_keyword wpa_type wpa_nematode_paper wpa_pages wpa_erratum wpa_publisher wpa_volume wpa_checked_out wpa_fulltext_url wpa_pubmed_final wpa_year );


my $wpa = 0;
my $result = $dbh->prepare( "SELECT * FROM wpa ORDER BY joinkey DESC" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
my @row = $result->fetchrow();
$wpa = $row[1];
print "Highest used wpa $wpa\n";

my %hash;
my $infile = 'in_book';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) {
  chomp ($line);
  my ($id, $title) = split/\t/, $line;
  if ($title =~ m/contained in WBPaper(\d+)/) { 
    $hash{removeinbook}{$id}++;
  } elsif ($title =~ m/same as (\d+)/) { 
    my $other_id = $1; 
    if ($hash{move}{$other_id}) { $hash{delete}{$id} = $hash{move}{$other_id}; }
      else { print "ERROR no match for $line\n"; }
  } else {
    $wpa++;
    $hash{move}{$id} = $wpa;
  }
}
close (IN) or die "Cannot close $infile : $!";

foreach my $id (sort keys %{ $hash{move} }) {
  my $wpa = $hash{move}{$id};
  &updateInBookToReal($id, $wpa);
  &removeInbook($id);
}

foreach my $id (sort keys %{ $hash{delete} }) {
  my $wpa = $hash{delete}{$id};
  &updateInBookToDelete($id, $wpa);
  &updateTypeToBook_chapter($id);
  &removeInbook($id);
}

foreach my $id (sort keys %{ $hash{removeinbook} }) {
  &updateTypeToBook_chapter($id);
  &removeInbook($id);
}

my @commands;
my $command = '';

sub updateInBookToDelete {
  my ($id, $wpa) = @_;
  my $joinkey = &padZeros($wpa);
  $command = "INSERT INTO wpa_contains VALUES ('$joinkey', 'WBPaper$id', NULL, 'valid', 'two1843');";
  push @commands, $command;
  $command = "INSERT INTO wpa_contained_in VALUES ('$id', 'WBPaper$joinkey', NULL, 'valid', 'two1843');";
  push @commands, $command;
  print "DELETE $id is now $wpa\n";
}

sub removeInbook {
  my ($id) = @_;
  my %hash;
  my $result2 = $dbh->prepare( "SELECT * FROM wpa_in_book WHERE joinkey = '${id}' ORDER BY wpa_timestamp" );
  $result2->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result2->fetchrow) {
    if ($row[3] eq 'valid') { $hash{$row[1]}++; }
      else { delete $hash{$row[1]}; }
  } # while (my @row = $result2->fetchrow)
  foreach my $type (keys %hash) {
    $command = "INSERT INTO wpa_in_book VALUES ('$id', '$type', NULL, 'invalid', 'two1843');";
    push @commands, $command;
  } # foreach my $type (keys %hash)
}

sub updateTypeToBook_chapter {
  my ($id) = @_;
  my %hash;
  my $result2 = $dbh->prepare( "SELECT * FROM wpa_type WHERE joinkey = '${id}' ORDER BY wpa_timestamp" );
  $result2->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result2->fetchrow) {
    if ($row[3] eq 'valid') { $hash{$row[1]}++; }
      else { delete $hash{$row[1]}; }
  } # while (my @row = $result2->fetchrow)
  foreach my $type (keys %hash) {
    next if ($type == 5);
    $command = "INSERT INTO wpa_type VALUES ('$id', '$type', NULL, 'invalid', 'two1843');";
    push @commands, $command;
  } # foreach my $type (keys %hash)
  unless ($hash{5}) {
    $command = "INSERT INTO wpa_type VALUES ('$id', '5', NULL, 'valid', 'two1843');";
    push @commands, $command;
  }
}

sub updateInBookToReal {
  my ($id, $wpa) = @_;
  my $joinkey = &padZeros($wpa);
  print "$id is now $joinkey\n";
  $command = "INSERT INTO wpa VALUES ('$joinkey', '$wpa', NULL, 'valid', 'two1843');";
  push @commands, $command;
  $command = "INSERT INTO wpa_contains VALUES ('$joinkey', 'WBPaper$id', NULL, 'valid', 'two1843');";
  push @commands, $command;
  $command = "INSERT INTO wpa_contained_in VALUES ('$id', 'WBPaper$joinkey', NULL, 'valid', 'two1843');";
  push @commands, $command;

    # get rid of type that should be book_chapter
  my %hash;
  my $result2 = $dbh->prepare( "SELECT * FROM wpa_type WHERE joinkey = '${id}' ORDER BY wpa_timestamp" );
  $result2->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result2->fetchrow) {
    if ($row[3] eq 'valid') { $hash{$row[1]}++; }
      else { delete $hash{$row[1]}; }
  } # while (my @row = $result2->fetchrow)
  foreach my $type (keys %hash) {
    next if ($type == 5);
    $command = "INSERT INTO wpa_type VALUES ('$id', '$type', NULL, 'invalid', 'two1843');";
    push @commands, $command;
  } # foreach my $type (keys %hash)
  unless ($hash{5}) {
    $command = "INSERT INTO wpa_type VALUES ('$id', '5', NULL, 'valid', 'two1843');";
    push @commands, $command;
  }

    # get rid of type that should be book
  %hash = ();
  $result2 = $dbh->prepare( "SELECT * FROM wpa_type WHERE joinkey = '${id}.2' ORDER BY wpa_timestamp" );
  $result2->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result2->fetchrow) {
    if ($row[3] eq 'valid') { $hash{$row[1]}++; }
      else { delete $hash{$row[1]}; }
  } # while (my @row = $result2->fetchrow)
  foreach my $type (keys %hash) {
    next if ($type == 23);
    $command = "INSERT INTO wpa_type VALUES ('$joinkey', '$type', NULL, 'invalid', 'two1843');";
# print "BOOK ${id}.2\t$type\n";
    push @commands, $command;
  } # foreach my $type (keys %hash)
  unless ($hash{23}) {
    $command = "INSERT INTO wpa_type VALUES ('$joinkey', '23', NULL, 'valid', 'two1843');";
    push @commands, $command;
  }

  foreach my $table (@tables) {
    my $flag = 0;
    my $result = $dbh->prepare( "SELECT * FROM $table WHERE joinkey = '${id}.2'" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) {
      $flag++;
#       print "$id $wpa $table $row[0] $row[1]\n";
    } # while (my @row = $result->fetchrow)
    if ($flag > 0) {
      $command = "UPDATE $table SET joinkey = '$joinkey' WHERE joinkey = '${id}.2';";
      push @commands, $command;
    }
  }
}

foreach my $command (@commands) {
  print "$command\n";
#   my $result2 = $dbh->do( $command );
}

sub padZeros {
  my $joinkey = shift;
  if ($joinkey =~ m/^0+/) { $joinkey =~ s/^0+//g; }
  if ($joinkey < 10) { $joinkey = '0000000' . $joinkey; }
  elsif ($joinkey < 100) { $joinkey = '000000' . $joinkey; }
  elsif ($joinkey < 1000) { $joinkey = '00000' . $joinkey; }
  elsif ($joinkey < 10000) { $joinkey = '0000' . $joinkey; }
  elsif ($joinkey < 100000) { $joinkey = '000' . $joinkey; }
  elsif ($joinkey < 1000000) { $joinkey = '00' . $joinkey; }
  elsif ($joinkey < 10000000) { $joinkey = '0' . $joinkey; }
  return $joinkey;
} # sub padZeros


__END__

my $result = $dbh->prepare( "SELECT * FROM two_comment WHERE two_comment ~ ?" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[1] =~ s///g;
    $row[2] =~ s///g;
    print "$row[0]\t$row[1]\t$row[2]\n";
  } # if ($row[0])
} # while (@row = $result->fetchrow)

__END__

my $result = $dbh->prepare( 'SELECT * FROM two_comment WHERE two_comment ~ ?' );
$result->execute('elegans') or die "Cannot prepare statement: $DBI::errstr\n"; 

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

interval stuff : 
SELECT * FROM afp_passwd WHERE joinkey NOT IN (SELECT joinkey FROM afp_lasttouched) AND joinkey NOT IN (SELECT joinkey FROM cfp_curator) AND afp_timestamp < CURRENT_TIMESTAMP - interval '21 days' AND afp_timestamp > CURRENT_TIMESTAMP - interval '28 days';

casting stuff to substring on other types :
SELECT * FROM afp_passwd WHERE CAST (afp_timestamp AS TEXT) ~ '2009-05-14';
