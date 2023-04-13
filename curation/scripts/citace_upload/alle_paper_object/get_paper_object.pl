#!/usr/bin/env perl

# dump paper and object data from phenote tables  2008 04 25
#
# updated to get allele->WBGene from http://tazendra.caltech.edu/~azurebrd/var/work/phenote/ws_current.obo
# and output that in some guessed .ace format since Jolene didn't give me one or tell me where from the obo
# to get the mappings.  2010 01 21
#
# app_tempname doesn't exist anymore, using app_variation  2011 04 28
#
# app_type doesn't exist anymore, map %hash{type} for each object table.  2012 12 13
#
# changed to use  obo_data_variation  instead of  ws_current.obo  2014 01 23
# changed out path to /home/acedb/karen/WS_upload_scripts/paper_object 2014 01 23
#
# Dockerized cronjob. Output to /usr/caltech_curation_files/pub/citace_upload/karen/  2023 03 14
#
# cronjob
# 0 4 * * sun /usr/lib/scripts/citace_upload/alle_paper_object/get_paper_object.pl


use strict;
use diagnostics;
use LWP::Simple;
use DBI;

use Dotenv -load => '/usr/lib/.env';


my $dbh = DBI->connect ( "dbi:Pg:dbname=$ENV{PSQL_DATABASE};host=$ENV{PSQL_HOST};port=$ENV{PSQL_PORT}", "$ENV{PSQL_USERNAME}", "$ENV{PSQL_PASSWORD}") or die "Cannot connect to database!\n";
# my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n";


my %allele_to_gene;

# my $obo_file = get "http://tazendra.caltech.edu/~azurebrd/var/work/phenote/ws_current.obo";
# my (@entries) = split/\[Term\]/, $obo_file;
# foreach my $entry (@entries) {
#   my $name = '';
#   my $gene = '';
#   if ($entry =~ m/name:\s+\"(.*?)\"/) { $name = $1; }
#   if ($entry =~ m/allele:\s+\"(WBGene\d+)/) { $gene = $1; }
#   if ($gene && $name) { $allele_to_gene{$name} = $gene; }
# } # foreach my $entry (@entries)

my %hash;
my $result;

$result = $dbh->prepare( "SELECT * FROM obo_data_variation;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) { if ($row[1] =~ m/(WBGene\d+)/) { $allele_to_gene{$row[0]} = $1; } }

# my $result = $dbh->prepare( "SELECT * FROM app_type;" );
# $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
# while (my @row = $result->fetchrow) { $hash{type}{$row[0]} = $row[1]; }
# $result = $dbh->prepare( "SELECT * FROM app_tempname;" );		# app_tempname doesn't exist anymore, using app_variation  2011 04 28
$result = $dbh->prepare( "SELECT * FROM app_variation;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) { $hash{obj}{$row[0]} = $row[1]; $hash{type}{$row[0]} = 'Allele'; }
$result = $dbh->prepare( "SELECT * FROM app_strain;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) { $hash{obj}{$row[0]} = $row[1]; $hash{type}{$row[0]} = 'Strain'; }
$result = $dbh->prepare( "SELECT * FROM app_rearrangement;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) { $hash{obj}{$row[0]} = $row[1]; $hash{type}{$row[0]} = 'Rearrangement'; }
$result = $dbh->prepare( "SELECT * FROM app_transgene;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) { $hash{obj}{$row[0]} = $row[1]; $hash{type}{$row[0]} = 'Transgene'; }
$result = $dbh->prepare( "SELECT * FROM app_paper;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) { $hash{paper}{$row[1]}{$row[0]}++; }

# my $outDir = $ENV{CALTECH_CURATION_FILES_INTERNAL_PATH} . "/pub/citace_upload/karen/";
# my $outfile = '/home/acedb/karen/WS_upload_scripts/paper_object/alle_paper.ace';
# my $outfile = $outDir . 'alle_paper.ace';
my $outfile = 'alle_paper.ace';
open (OUT, ">$outfile") or die "Cannot create $outfile : $!";

my $error_messages = '';
foreach my $paper (sort keys %{ $hash{paper} }) {
  next unless ($paper);
  print OUT "Paper : $paper\n";
  foreach my $joinkey (sort keys %{ $hash{paper}{$paper} }) {
    my $type = $hash{type}{$joinkey};
    my $obj = $hash{obj}{$joinkey};
    unless ($type) { $error_messages .= "// ERR no type $joinkey PGDBID in $paper\n"; }
    unless ($obj) { $error_messages .= "// ERR no obj $joinkey PGDBID in $paper\n"; }
    if ($type && $obj) { 
      next if ($type =~ m/Multi/);
      if ($allele_to_gene{$obj}) { print OUT "Gene\t$allele_to_gene{$obj}\n"; }
      print OUT "$type\t\"$obj\"\tInferred_Automatically\t\"Inferred automatically from curated phenotype\"\n"; }
    
  } # foreach my $joinkey (sort keys %{ $hash{paper}{$paper} })
  print OUT "\n";
} # foreach my $paper (sort keys %{ $hash{paper} })

print OUT "\n\n$error_messages\n";

close (OUT) or die "Cannot close $outfile : $!";

__END__

