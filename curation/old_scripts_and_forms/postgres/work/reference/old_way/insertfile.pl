#!/usr/bin/perl5.6.0

use lib qw( /usr/lib/perl5/site_perl/5.6.1/i686-linux/ );
use Pg;

$conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

$result = $conn->exec( "INSERT INTO ref_cgc VALUES ('cgc124', '124')");
$result = $conn->exec( "INSERT INTO ref_reference_by VALUES ('cgc124', 'postgres')");
$result = $conn->exec( "INSERT INTO ref_checked_out VALUES ('cgc124', NULL )");
$result = $conn->exec( "INSERT INTO ref_title VALUES ( 'cgc124', NULL )");
$result = $conn->exec( "INSERT INTO ref_journal VALUES ( 'cgc124', NULL )");
$result = $conn->exec( "INSERT INTO ref_volume VALUES ( 'cgc124', NULL )");
$result = $conn->exec( "INSERT INTO ref_pages VALUES ( 'cgc124', NULL )");
$result = $conn->exec( "INSERT INTO ref_year VALUES ( 'cgc124', NULL )");
$result = $conn->exec( "INSERT INTO ref_abstract VALUES ( 'cgc124', NULL )");
$result = $conn->exec( "INSERT INTO ref_hardcopy VALUES ( 'cgc124', NULL )");
$result = $conn->exec( "INSERT INTO ref_pdf VALUES ( 'cgc124', NULL )");
$result = $conn->exec( "INSERT INTO ref_html VALUES ( 'cgc124', NULL )");
$result = $conn->exec( "INSERT INTO ref_tif VALUES ( 'cgc124', NULL )");
$result = $conn->exec( "INSERT INTO ref_lib VALUES ( 'cgc124', NULL )");
