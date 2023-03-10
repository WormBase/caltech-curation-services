#!/usr/bin/perl -w

# delete locations from this query in trp_location and insert null into trp_location_hst
# SELECT * FROM trp_location WHERE joinkey IN (SELECT joinkey FROM trp_name WHERE trp_name !~ 'WBPaper')
# for Karen  2011 03 04
#
# ran on tazendra  2011 03 18

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 


my @pgcommands;

my $result = $dbh->prepare( "SELECT * FROM trp_location WHERE joinkey IN (SELECT joinkey FROM trp_name WHERE trp_name !~ 'WBPaper')" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  push @pgcommands, "INSERT INTO trp_location VALUES ('$row[0]', NULL);";
} # while (@row = $result->fetchrow)
push @pgcommands, "DELETE FROM trp_location WHERE joinkey IN (SELECT joinkey FROM trp_name WHERE trp_name !~ 'WBPaper');";

foreach my $command (@pgcommands) {
  print "$command\n";
# UNCOMMENT TO delete from trp_location and insert NULLs into trp_location_hst
#   $result = $dbh->do( $command );
} # foreach my $command (@pgcommands)

__END__
