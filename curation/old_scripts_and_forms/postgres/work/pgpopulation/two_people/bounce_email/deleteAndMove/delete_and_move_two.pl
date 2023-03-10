#!/usr/bin/perl -w

# move and delete two_ data from people that bounced  2009 04 29

use strict;
use diagnostics;
use DBI;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my @deleteTables = qw( two_institution two_lab two_email two_fax two_street two_state two_city two_country two_post two_mainphone two_otherphone two_officephone two_labphone );

my $infile = 'newsletterApril09-bounced-toDELETEandMOVE';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) {
  next unless ($line =~ m/^(two\d+)/);
  my $joinkey = $1; 
  &deleteAndMove($joinkey);
}
close (IN) or die "Cannot close $infile : $!";

sub deleteAndMove {
  my $joinkey = shift;
  &moveTable($joinkey, 'two_institution', 'two_old_institution'); 
  &moveTable($joinkey, 'two_lab', 'two_oldlab'); 
  &moveTable($joinkey, 'two_email', 'two_old_email'); 
  foreach my $table (@deleteTables) { &deleteTable($joinkey, $table); }
  &insertComment($joinkey);
} # sub deleteAndMove

sub insertComment {
  my $joinkey = shift;
  my $comment = 'newsletterApril09 bounced, Not at institution.';
  my $result2 = $dbh->prepare_cached( "INSERT INTO two_comment VALUES( ?, ? )" );
# UNCOMMENT TO RUN
#   $result2->execute( $joinkey, $comment );
}

sub moveTable {
  my ($joinkey, $source, $dest) = @_;
  my $result = $dbh->prepare( "SELECT two_order FROM $dest WHERE joinkey = '$joinkey' ORDER BY two_order DESC;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  my @row = $result->fetchrow();
  my $order = $row[0];
  $result = $dbh->prepare( "SELECT * FROM $source WHERE joinkey = '$joinkey';" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow() ) {
    my $data = $row[2]; my $time1 = $row[3]; my $time2 = $row[4];
    $order++;
#     my $command = "INSERT INTO $dest VALUES ('$joinkey', '$order', '$data', '$time1', '$time2');";
#     print "$command\n";
    my $result2 = $dbh->prepare_cached( "INSERT INTO $dest VALUES( ?, ?, ?, ?, ? )" );
# UNCOMMENT TO RUN
#     $result2->execute( $joinkey, $order, $data, $time1, $time2 );
  } # while (my @row = $result->fetchrow() )
} # sub moveTable

sub deleteTable {
  my ($joinkey, $table) = @_;
  my $command = "DELETE FROM $table WHERE joinkey = '$joinkey';";
#   print "$command\n";
# UNCOMMENT TO RUN
#   my $result = $dbh->do( $command );
} # sub deleteTable


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
