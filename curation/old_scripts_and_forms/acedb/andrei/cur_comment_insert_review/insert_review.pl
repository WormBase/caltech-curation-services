#!/usr/bin/perl -w

# sample PG query

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;


  my @joinkeys = qw( 00031414 00031413 00031412 00031411 00031410 00031409 00031408 00031407 00031406 00031405 00031404 00031403 00031402 00031401 00031400 00031399 00031398 00031397 00031396 00031395 00031394 00031393 00031392 00031391 00031390 00031389 00031388 00031294 00031293 00031292 00031291 00031290 00031289 00031288 00031287 00031286 00031285 00031284 00031283 00031282 00031281 00031280 00031279 00031278 00031277 00031276 00031275 00031274 00031273 00031272 00031271 00031270 00031269 00031268 00031267 00031266 00031265 00031264 00031263 00031262 00031222 00031221 00031220 00031219 00031181 00031180 );


  my $infile = '/home/postgres/public_html/cgi-bin/curation.cgi';
  open (IN, "<$infile") or die "Cannot open $infile : $!";
  $/ = undef; my $all_file = <IN>; $/ = "\n";
  close (IN) or die "Cannot close $infile : $!";
  my $params = '';
  if ($all_file =~ m/my \@PGparameters \= qw\((.*?)\)\;/ms) { $params = $1; }
  unless ($params) { print "ERROR can't find postgres tables cur_ paramters from curation.cgi so postgres not properly populated<BR>\n"; }
  if ($params) {
    my @params = split/\s+/, $params;
    foreach my $pgparam (@params) {
      next if ($pgparam eq 'comment');
      next if ($pgparam eq 'pubID');
      next if ($pgparam eq 'pdffilename');
      next if ($pgparam eq 'reference');
      next if ($pgparam eq 'fullauthorname');
#       print "GRANT ALL ON cur_$pgparam TO acedb;\n";
      foreach my $joinkey (@joinkeys) {
#           next if ($pgparam eq 'curator');
        if ($pgparam eq 'curator') {
          my $pg_command2 = "INSERT INTO cur_$pgparam VALUES ('$joinkey', 'two480', CURRENT_TIMESTAMP);";
          my $result2 = $conn->exec( $pg_command2 ); }
        else {
          my $pg_command2 = "INSERT INTO cur_$pgparam VALUES ('$joinkey', NULL, CURRENT_TIMESTAMP);";
          my $result2 = $conn->exec( $pg_command2 ); } } } }


__END__

my $joinkey;
my $result = $conn->exec( "SELECT joinkey FROM wpa_journal WHERE wpa_journal = 'WormBook'" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { $joinkey = $row[0]; &addReview($joinkey); }
} # while (@row = $result->fetchrow)

sub addReview {
  my $joinkey = shift;
  my $result = $conn->exec( "SELECT * FROM cur_comment WHERE joinkey = '$joinkey'" );
  my @row = $result->fetchrow();
  if ($row[0]) { $result = $conn->exec( "UPDATE cur_comment SET cur_comment = 'review' WHERE joinkey = '$joinkey'" ); }
    else {
      $result = $conn->exec( "INSERT INTO cur_comment VALUES ('$joinkey', 'review');") ; 
      $result = $conn->exec( "INSERT INTO cur_curator VALUES ('$joinkey', 'two480');") ; 
      my $infile = '/home/postgres/public_html/cgi-bin/curation.cgi';
      open (IN, "<$infile") or die "Cannot open $infile : $!";
      $/ = undef; my $all_file = <IN>; $/ = "\n";
      close (IN) or die "Cannot close $infile : $!";
      my $params = '';
      if ($all_file =~ m/my \@PGparameters \= qw\((.*?)\)\;/ms) { $params = $1; }
      unless ($params) { print "ERROR can't find postgres tables cur_ paramters from curation.cgi so postgres not properly populated<BR>\n"; }
      if ($params) {
        my @params = split/\s+/, $params;
        foreach my $pgparam (@params) {
          next if ($pgparam eq 'curator');
          next if ($pgparam eq 'comment');
          next if ($pgparam eq 'pubID');
          next if ($pgparam eq 'pdffilename');
          next if ($pgparam eq 'reference');
          next if ($pgparam eq 'fullauthorname');
          my $pg_command2 = "INSERT INTO cur_$pgparam VALUES ('$joinkey', NULL, CURRENT_TIMESTAMP);";
          my $result2 = $conn->exec( $pg_command2 ); } } }
} # sub addReview

__END__

