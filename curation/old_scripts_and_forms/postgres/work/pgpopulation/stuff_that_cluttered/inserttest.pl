#!/usr/bin/perl5.6.0

use lib qw( /usr/lib/perl5/site_perl/5.6.1/i686-linux/ );
use Pg;

$conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

print "1\n";
$result = $conn->exec(
  "INSERT INTO friend VALUES ('Sam', 'Jackson', 'Allentown', 'PA', 22)");
print "2\n";
