#!/usr/bin/perl -w

# find entries in OAs where the pgid doesn't match the object ID, from tables that probably should
# according to 
# https://docs.google.com/spreadsheets/d/1heGsesiaKcpu00latxmzgQbtRWm5uXfeTLh7huvegjc/edit?usp=sharing



use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my @tables = qw( cns_name );

foreach my $table (@tables) {
  $result = $dbh->prepare( "SELECT * FROM $table" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    my $pgid = $row[0];
    my $name = $row[1];
    my ($nameId) = $name =~ m/(\d+)/;
    if ($nameId =~ m/^0+/) { $nameId =~ s/^(0+)//; }
    if ($pgid ne $nameId) { print qq($table\t$row[0]\t$nameId\t$row[1]\n); }
  } # while (@row = $result->fetchrow)
}

__END__


  $datatype_list{"cns"} = "construct";
  $datatype_list{"mop"} = "molecule";
  $datatype_list{"mov"} = "movie";
  $datatype_list{"pic"} = "picture";
  $datatype_list{"trp"} = "transgene";

SELECT cns_name, COUNT(*) AS count FROM cns_name  GROUP BY cns_name HAVING COUNT(*) > 1;
SELECT mop_name, COUNT(*) AS count FROM mop_name  GROUP BY mop_name HAVING COUNT(*) > 1;
SELECT mov_name, COUNT(*) AS count FROM mov_name  GROUP BY mov_name HAVING COUNT(*) > 1;
SELECT pic_name, COUNT(*) AS count FROM pic_name  GROUP BY pic_name HAVING COUNT(*) > 1;
SELECT trp_name, COUNT(*) AS count FROM trp_name  GROUP BY trp_name HAVING COUNT(*) > 1;

