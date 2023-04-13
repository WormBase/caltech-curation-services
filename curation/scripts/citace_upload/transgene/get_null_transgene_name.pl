#!/usr/bin/env perl

# get_null_transgene_name.pl
# check for null entries in the postgres transgene name table and return corresponding data for trp_synonym, trp_summary, trp_paper
# This query lists all the entries by pgid that contain a null object in trp_name. 
# SELECT * FROM trp_name where trp_name = '';  which gives all pgids and timestamps
# SELECT * FROM trp_synonym where joinkey IN (SELECT joinkey FROM trp_name WHERE trp_name = '');

use strict;
use warnings;
use diagnostics;
use DBI;

use Dotenv -load => '/usr/lib/.env';

my $dbh = DBI->connect ( "dbi:Pg:dbname=$ENV{PSQL_DATABASE};host=$ENV{PSQL_HOST};port=$ENV{PSQL_PORT}", "$ENV{PSQL_USERNAME}", "$ENV{PSQL_PASSWORD}") or die "Cannot connect to database!\n";
# my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my $result;
my %null_lines;

print qq(Start postgres queries\n);
my @trp_null_values = qw(trp_curator trp_synonym trp_summary trp_paper);
foreach my $table (@trp_null_values) {
  print qq(SELECT * FROM $table where joinkey IN (SELECT joinkey FROM trp_name WHERE trp_name = '')\n);
  $result = $dbh->prepare( "SELECT * FROM $table where joinkey IN (SELECT joinkey FROM trp_name WHERE trp_name = '')" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) { $null_lines{$row[0]}{$table} = $row[1];}
}
print qq(End postgres queries\n);

foreach my $pgid (sort {$a<=>$b} keys %null_lines) {
	my @array = ();
	push @array, $pgid;
	foreach my $table (@trp_null_values) {
        my $value = 'null';
		if ($null_lines{$pgid}{$table}) { $value = $null_lines{$pgid}{$table}; }
		push @array, $value;
    }
    my $line = join"\t", @array;
	print "$line\n";
}

print qq(End output\n);
