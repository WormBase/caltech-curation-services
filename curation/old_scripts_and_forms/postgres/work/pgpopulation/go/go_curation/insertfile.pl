#!/usr/bin/perl -w

use lib qw( /usr/lib/perl5/site_perl/5.6.1/i686-linux/ );
use DBI;

my $dbh = DBI->connect("dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database
;
my $result = $dbh->do( "DELETE FROM got_goterm;");
$result = $dbh->do( "DELETE FROM got_obsoleteterm;");
