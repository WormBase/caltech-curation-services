#!/usr/bin/env perl

# Dump Laboratory data.  2017 11 02


use strict;
use diagnostics;
# use Pg;
use DBI;
use Jex;
use LWP;

use Dotenv -load => '/usr/lib/.env';

my $dbh = DBI->connect ( "dbi:Pg:dbname=$ENV{PSQL_DATABASE};host=$ENV{PSQL_HOST};port=$ENV{PSQL_PORT}", "$ENV{PSQL_USERNAME}", "$ENV{PSQL_PASSWORD}") or die "Cannot connect to database!\n";
# my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
# my $dbh = DBI->connect ( "dbi:Pg:dbname=devdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %hash;
my @data_tables   = qw( name status mail phone email fax url alleledesignation remark );
my @normal_tables = qw( mail phone email fax url alleledesignation remark );

my $qualifier_general = ''; my $qualifier_paper_hash = '';  my $specific_two_num = 'all'; 
if ($specific_two_num ne 'all') { 
  $qualifier_paper_hash = " AND pap_author_possible.pap_author_possible = '$specific_two_num'";
  $qualifier_general    = " AND joinkey = '$specific_two_num'"; }

my %data;
foreach my $table (@data_tables) {
  $result = $dbh->prepare( "SELECT * FROM lab_$table WHERE lab_$table != 'NULL' $qualifier_general" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
    $row[0] =~ s/lab//;
    my $data = $row[2];
#     my ($date_type) = $row[4] =~ m/^(\d\d\d\d\-\d\d\-\d\d)/;
#     if ( ($table eq 'old_inst_date') || ($table eq 'old_email_date') ) {
#       if ($row[2] =~ m/^\s+/) { $row[2] =~ s/^\s+//; } if ($row[2] =~ m/\s+$/) { $row[2] =~ s/\s+$//; }
#       ($data) = $row[2] =~ m/^(\d\d\d\d\-\d\d\-\d\d)/; }
#     $data{$table}{$row[0]}{$row[1]}{time} = $date_type;
    $data{$table}{$row[0]}{$row[1]}{data} = $data; } }

my %tableToTag;
$tableToTag{mail}              = "Mail";                      
$tableToTag{phone}             = "Phone";                     
$tableToTag{email}             = "E_mail";                    
$tableToTag{fax}               = "Fax";                       
$tableToTag{url}               = "URL";                       
# $tableToTag{straindesignation} = "Strain_designation";        
$tableToTag{alleledesignation} = "Allele_designation";
$tableToTag{remark}            = "Remark";                    


foreach my $twonum (sort {$a<=>$b} keys %{ $data{status} }) {
  next if ($data{status}{$twonum}{1}{data} ne 'Valid');

  print qq(\nLaboratory : "$data{name}{$twonum}{1}{data}"\n); 
  print qq(Strain_designation\t"$data{name}{$twonum}{1}{data}"\n); 

  foreach my $table (@normal_tables) {
    foreach my $order (sort {$a<=>$b} keys %{ $data{$table}{$twonum} }) {
      my ($data, $time) = ('', '');
      if ( $data{$table}{$twonum}{$order}{time} ) { $time = $data{$table}{$twonum}{$order}{time}; }
      if ( $data{$table}{$twonum}{$order}{data} ) { $data = $data{$table}{$twonum}{$order}{data}; }
      next unless $data;			# only print stuff if there's data
      if ($data =~ m/\//)   { $data =~ s/\//\\\//g; }
      if ($data =~ m/\"/)   { $data =~ s/\"/\\\"/g; }
      if ($data =~ m/\s+/)  { $data =~ s/\s+/ /g; }
      if ($data =~ m/^\s+/) { $data =~ s/^\s+//g; }
      if ($data =~ m/\s+$/) { $data =~ s/\s+$//g; }
#       if ($time) {
#         my $datenum = $time; $datenum =~ s/\-//g;
#         if ($datenum > $highest_date_num) { $highest_date = $time; $highest_date_num = $datenum; } }
      print "$tableToTag{$table}\t\"$data\"\n";
    } # foreach my $order (sort {$a<=>$b} keys %{ $data{$table}{$twonum} })
  } # foreach my $table (@normal_tables)
} # foreach my $twonum (sort {$a<=>$b} keys %{ $data{status} })



__END__

