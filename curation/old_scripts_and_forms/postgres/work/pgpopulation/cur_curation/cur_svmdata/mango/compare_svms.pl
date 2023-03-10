#!/usr/bin/perl -w

# compare svm results for different dates.  2012 12 20

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %hash;

$result = $dbh->prepare( "SELECT * FROM cur_svmdata" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $hash{$row[1]}{$row[0]}{$row[2]} = $row[3]; }
} # while (@row = $result->fetchrow)

foreach my $datatype (sort keys %hash) {
  foreach my $joinkey (sort keys %{ $hash{$datatype} }) {
    my @dates = sort keys %{ $hash{$datatype}{$joinkey} };
    if (scalar @dates > 1) {
      my %results;
      foreach my $date (sort keys %{ $hash{$datatype}{$joinkey} }) {
        $results{ $hash{$datatype}{$joinkey}{$date} }++;
      } # foreach my $date (sort keys %{ $hash{$datatype}{$joinkey} })
      if (scalar keys %results > 1) {
        my @results = sort keys %results;
        print "$datatype\t$joinkey\t@dates\t@results\n";
      }
    }
  } # foreach my $joinkey (sort keys %{ $hash{$datatype} })
} # foreach my $datatype (sort keys %hash)

__END__

 00000003  | antibody     | 20090101 | NEG         | 0           | 2012-12-02 23:11:12.387904-08
 00000003  | geneint      | 20090101 | NEG         | 0           | 2012-12-02 23:11:12.404937-08
 00000003  | geneprod     | 20090101 | NEG         | 0           | 2012-12-02 23:11:12.413071-08

testdb=# SELECT * FROM cur_svmdata WHERE cur_paper = '00024178' AND cur_datatype = 'antibody';
 cur_paper | cur_datatype | cur_date | cur_svmdata | cur_version | cur_timestamp
-----------+--------------+----------+-------------+-------------+-------------------------------
 00024178  | antibody     | 20110708 | low         | 0           | 2012-12-02 23:18:47.306456-08
 00024178  | antibody     | 20121210 | NEG         | 1           | 2012-12-20 07:52:22.901616-08


Some old ones have results in two directories :

testdb=# SELECT * FROM cur_svmdata WHERE cur_paper = '00036143' AND cur_datatype = 'antibody';
 cur_paper | cur_datatype | cur_date | cur_svmdata | cur_version | cur_timestamp
-----------+--------------+----------+-------------+-------------+------------------------------- 
 00036143  | antibody     | 20100514 | medium      | 0           | 2012-12-02 23:23:26.183249-08
 00036143  | antibody     | 20100528 | medium      | 0           | 2012-12-02 23:23:26.191586-08
 00036143  | antibody     | 20121026 | high        | 1           | 2012-12-06 16:31:57.400491-08


Some old ones have different results in two directories :

testdb=# SELECT * FROM cur_svmdata WHERE cur_paper = '00036205' AND cur_datatype = 'antibody';
 cur_paper | cur_datatype | cur_date | cur_svmdata | cur_version | cur_timestamp
-----------+--------------+----------+-------------+-------------+-------------------------------
 00036205  | antibody     | 20100514 | high        | 0           | 2012-12-02 23:23:32.211409-08
 00036205  | antibody     | 20100528 | NEG         | 0           | 2012-12-02 23:23:32.219743-08
 00036205  | antibody     | 20121026 | high        | 1           | 2012-12-06 16:32:01.494928-08

