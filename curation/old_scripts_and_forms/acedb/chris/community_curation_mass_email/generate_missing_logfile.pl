#!/usr/bin/perl -w

# sample PG query

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my $to_print = '';
my $count = 0;
$result = $dbh->prepare( "SELECT * FROM com_massemail WHERE com_timestamp > '2018-06-26 08:00' ORDER BY com_timestamp;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  my ($paper, $two, $email, @stuff) = @row;
  $count++;
  $to_print .= qq($two\t$email\t$paper\n);
  $to_print .= qq(INSERT INTO com_mass_email VALUES ('$paper', '$two', '$email');\n);
  $to_print .= qq(send email to $email\n);
  $to_print .= qq(from outreach\@wormbase.org\n\n);
} # while (@row = $result->fetchrow)

$to_print = "Total count of people that can be emailed ~>3000.  Emailing $count.\n\n" . $to_print;

print $to_print;
