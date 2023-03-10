#!/usr/bin/perl5.6.0

use lib qw( /usr/lib/perl5/site_perl/5.6.1/i686-linux/ );
use Pg;

$conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

$result = $conn->exec( "CREATE TABLE reference_by ( joinkey TEXT, reference_by TEXT )");
$result = $conn->exec( "CREATE TABLE checked_out ( joinkey TEXT, checked_out TEXT )");
$result = $conn->exec( "INSERT INTO reference_by VALUES ('cgc10', 'postgres')");
$result = $conn->exec( "INSERT INTO checked_out VALUES ('cgc10', NULL )");
