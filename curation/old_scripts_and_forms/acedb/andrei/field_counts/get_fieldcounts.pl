#!/usr/bin/perl -w

# Get count of curated papers (no meetings) by published year.
# Get count of all papers (curated or not) (no meetings) by published year.
# Get total from curation fields based on curation.cgi fields.
# Get count of entries curated in a given year.
# Get count of entries curated from papers published in a given year.
# 2007 01 05


use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my %invalid;
my $result = $conn->exec( "SELECT * FROM wpa; ");
while (my @row = $result->fetchrow) {
  if ($row[3] ne 'valid') { $invalid{$row[0]}++; }
    else { delete $invalid{$row[0]}; } }

my %bad;
$result = $conn->exec( "SELECT * FROM wpa_type WHERE wpa_type = '3' OR wpa_type = '4' OR wpa_type = '7'; ");
while (my @row = $result->fetchrow) { $bad{$row[0]}++; }    # put meeting abstracts in bad hash to exclude

my %years;
$result = $conn->exec( "SELECT * FROM wpa_year ORDER BY wpa_timestamp;" );
while (my @row = $result->fetchrow) {
  my ($year) = $row[1] =~ m/^(\d{4})/;
  if ($row[3] eq 'valid') { $years{$row[0]} = $year; }
    else { delete $years{$row[0]}; } }
my %all_papers_by_year;
foreach my $paper (sort keys %years) {
  next if ($bad{$paper});
  next if ($invalid{$paper});
  $all_papers_by_year{$years{$paper}}++; }
print "All Papers (curated or not) (no meetings) by Year\n";
foreach my $year (sort keys %all_papers_by_year) {
  print "$year\t$all_papers_by_year{$year}\n"; }
print "\n\n";
  
my %not_meeting; 
$result = $conn->exec( "SELECT * FROM cur_curator WHERE cur_curator IS NOT NULL; ");
while (my @row = $result->fetchrow) { 
  my $joinkey = $row[0];
  next if ($invalid{$joinkey});
  if ($years{$joinkey}) { 
    unless ($bad{$joinkey}) {
      $not_meeting{$years{$joinkey}}++; } } }
print "Curated papers (no meetings) total\n";
foreach my $year (sort keys %not_meeting) {
  print "$year\t$not_meeting{$year}\n"; }
print "\n\n";







my %year_pub;
my %year_cur;
my %total;

$/ = undef;
my $infile = '/home/postgres/public_html/cgi-bin/curation.cgi';
open (IN, "<$infile") or die "Cannot open $infile : $!";
my $cur_file = <IN>;
close (IN) or die "Cannot close $infile : $!";
my ($pars) = $cur_file =~ m/\nmy \@PGparameters = qw\((.*?)\);/s;
my @pg = split/\s+/, $pars;
foreach my $table (@pg) { $table = 'cur_' . $table; }

my @deleted = qw( cur_associationequiv cur_structurecorrection cur_associationnew cur_newsymbol cur_synonym cur_genesymbols cur_goodphoto cur_extractedallelename );


foreach my $table (@pg, @deleted) { 
  my $count;
  $result = $conn->exec( "SELECT * FROM $table WHERE $table IS NOT NULL;" );
  while (my @row = $result->fetchrow) {
    my $joinkey = $row[0];
    next if ($invalid{$joinkey});
    my $ts = $row[2];
    my ($year) = $ts =~ m/^(\d{4})/;
    $year_cur{$table}{$year}++;
    $total{$table}++;
    if ($years{$joinkey}) { $year_pub{$table}{$years{$joinkey}}++; }
  } # while (my @row = $result->fetchrow)
} # foreach my $table (@pg)


foreach my $table (@pg, @deleted) { 
  next if ($table eq 'cur_pubID');
  next if ($table eq 'cur_fullauthorname');
  next if ($table eq 'cur_reference');
  next if ($table eq 'cur_pdffilename');
  print "$table\tTotal\t$total{$table}\n";
  foreach my $year (sort keys %{ $year_cur{$table} }) {
    print "Curated $year : $year_cur{$table}{$year}\n"; }
  foreach my $year (sort keys %{ $year_pub{$table} }) {
    print "Published $year : $year_pub{$table}{$year}\n"; }
  print "\n\n";
} # foreach my $table (@pg)


__END__

foreach my $table (@all_pg_20080508)
my @all_pg_20080508 = qw( cur_ablationdata cur_extractedallelenew cur_lsrnai cur_site cur_antibody cur_fullauthorname cur_mappingdata cur_stlouissnp cur_associationequiv cur_functionalcomplementation cur_massspec cur_structurecorrection cur_associationnew cur_genefunction cur_microarray cur_structurecorrectionsanger cur_cellfunction cur_geneinteractions cur_mosaic cur_structurecorrectionstlouis cur_cellname cur_geneproduct cur_newmutant cur_structureinformation cur_chemicals cur_generegulation cur_newsnp cur_supplemental cur_comment cur_genesymbol cur_newsymbol cur_synonym cur_covalent cur_genesymbols cur_overexpression cur_transgene cur_curator cur_goodphoto cur_rnai cur_expression cur_humandiseases cur_sequencechange cur_extractedallelename cur_invitro cur_sequencefeatures );

foreach my $table (@all_pg_20080508) { 
  my $skip = 0;
  foreach my $pgtable (@pg) { if ($pgtable eq $table) { $skip++; } }
  unless ($skip) { print "DELETED $table\n"; }
}



