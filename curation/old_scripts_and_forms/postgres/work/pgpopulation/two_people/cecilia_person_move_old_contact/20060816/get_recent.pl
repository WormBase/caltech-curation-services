#!/usr/bin/perl -w

# Do what Cecilia wants listed below.  Uncomment commands to run it.  (Already
# ran)  2006 08 16
#
# Also change emails to old emails and delete.  2006 08 16

use strict;
use diagnostics;
use Pg;

my @twos = qw( 550 765 773 950 1156 1179 719 1753 1292 1438 1609 1907 1907 1969 2109 2125 2204 2155 2187 2286 2224 2309 2296 2303 2267 2323 2318 2346 2340 2542 2607 2629 2535 2642 2661 2753 2734 2763 2892 3144 3206 3237 3225 3282 3296 3495 3513 3555 3600 3683 3761 3787 3793 4018 4049 4047 4067 4179 3568 4480 4510 4495 4607 4606 4735 4803 4995 4927 5109 4010 1286 2152 3362 3544 );

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $result;
my @row;

foreach my $two (@twos) {
  my $joinkey = 'two' . $two;
#   $result = $conn->exec( "INSERT INTO two_comment VALUES ('$joinkey', 'Bounced from 1st automatic paper connection, I''ve already checked instituion website', CURRENT_TIMESTAMP);" );
#   $result = $conn->exec ( "DELETE FROM two_street WHERE joinkey = '$joinkey';" );
#   $result = $conn->exec ( "DELETE FROM two_state WHERE joinkey = '$joinkey';" );
#   $result = $conn->exec ( "DELETE FROM two_city WHERE joinkey = '$joinkey';" );
#   $result = $conn->exec ( "DELETE FROM two_country WHERE joinkey = '$joinkey';" );
#   $result = $conn->exec ( "DELETE FROM two_post WHERE joinkey = '$joinkey';" );
#   $result = $conn->exec ( "DELETE FROM two_mainphone WHERE joinkey = '$joinkey';" );
#   $result = $conn->exec ( "DELETE FROM two_labphone WHERE joinkey = '$joinkey';" );
#   $result = $conn->exec ( "DELETE FROM two_officephone WHERE joinkey = '$joinkey';" );
#   $result = $conn->exec ( "DELETE FROM two_otherphone WHERE joinkey = '$joinkey';" );
#   $result = $conn->exec ( "DELETE FROM two_fax WHERE joinkey = '$joinkey';" );

  $result = $conn->exec( "SELECT * FROM two_unable_to_contact WHERE joinkey = '$joinkey' ;" );
  @row = $result->fetchrow;
  if ($row[0]) { 
#     $result = $conn->exec( "UPDATE two_unable_to_contact SET two_unable_to_contact = 'No current address available' WHERE joinkey = '$joinkey' AND two_order = '1';" );
  } else {
#     $result = $conn->exec( "INSERT INTO two_unable_to_contact VALUES ('$joinkey', '1', 'No current address available', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);" );
  }

  $result = $conn->exec( "SELECT * FROM two_institution WHERE joinkey = '$joinkey' ORDER BY two_order;" );
  my $inst = ''; my $old_inst = '';
  @row = $result->fetchrow;
  if ($row[2]) { $inst = $row[2]; }
  @row = $result->fetchrow;
  if ($row[2]) { $old_inst = $row[2]; }
  if ($old_inst) { 
    $old_inst .= "; $inst"; 
#     $result = $conn->exec( "UPDATE two_institution SET two_institution = '$old_inst' WHERE joinkey = '$joinkey' AND two_order = '2';" );
  }
#   $result = $conn->exec ( "DELETE FROM two_institution WHERE joinkey = '$joinkey' AND two_order = '1';" );

  my $old_lab_order = 0;
  $result = $conn->exec( "SELECT two_order FROM two_oldlab WHERE joinkey = '$joinkey' ORDER BY two_order DESC;" );
  @row = $result->fetchrow;
  if ($row[0]) { $old_lab_order = $row[0]; }
  $result = $conn->exec( "SELECT two_lab FROM two_lab WHERE joinkey = '$joinkey' ORDER BY two_order DESC;" );
  while (@row = $result->fetchrow) {
    $old_lab_order++;
#     my $result2 = $conn->exec( "INSERT INTO two_oldlab VALUES ('$joinkey', '$old_lab_order', '$row[0]', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);" );
  } # while (@row = $result->fetchrow)
#   $result = $conn->exec( "DELETE FROM two_lab WHERE joinkey = '$joinkey';" );
  
  my $old_email_order = 0;
  $result = $conn->exec( "SELECT two_order FROM two_old_email WHERE joinkey = '$joinkey' ORDER BY two_order DESC;" );
  @row = $result->fetchrow;
  if ($row[0]) { $old_email_order = $row[0]; }
  $result = $conn->exec( "SELECT two_email FROM two_email WHERE joinkey = '$joinkey' ORDER BY two_order DESC;" );
  while (@row = $result->fetchrow) {
    $old_email_order++;
#     my $result2 = $conn->exec( "INSERT INTO two_old_email VALUES ('$joinkey', '$old_email_order', '$row[0]', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);" );
  } # while (@row = $result->fetchrow)
#   $result = $conn->exec( "DELETE FROM two_email WHERE joinkey = '$joinkey';" );
  
} # foreach my $two (@twos)


__END__


Delete two_street, two_state, two_city, two_country , two_post

Pasar two_institution_1 to two_instituion_2 y hacer delete two_institution_1
 Si hay otro two_nstituion2, ponerlo luego de ;
 Si no hay two_instituion, dejarlo en blanco

Pasar two_lab to two_oldlab y hacerlo delete
 Si hay otro two_oldlab, ponerlo en el sgte joinkey (1,  2 ...)

Delete two_mainphone, two_labphone, two_officephone,  two_otherphone and two_fax

Add to two_unable_to_contact 'No current address available'
 Si hay otra data substituirla por No current address available

Add to two_comment 'Bounced from 1st automatic paper connection, I've already
checked instituion website'

