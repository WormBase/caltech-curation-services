#!/usr/bin/perl -w

# populate YH into interaction  2012 06 05
# 
# live run on tazendra.  2012 06 21

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;
my %hash;

my %types;
$types{pcrbait}            = 'multi';
$types{pcrtarget}          = 'multi';
$types{sequencebait}       = 'text';
$types{sequencetarget}     = 'text';
$types{genebait}           = 'single';
$types{genetarget}         = 'multi';
$types{cdsbait}            = 'text';
$types{cdstarget}          = 'text';
$types{library}            = 'text';
# $types{libraryamount}      = 'single';
$types{detectionmethod}    = 'multi';
$types{laboratory}         = 'single';
$types{paper}              = 'single';
$types{remark}             = 'single';
$types{confidence}         = 'text';
$types{type}               = 'single';

my $pgid = 0;
$result = $dbh->prepare( "SELECT * FROM int_name ORDER BY joinkey::INTEGER DESC" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
my @row = $result->fetchrow();  
if ($row[0]) { if ($row[0] > $pgid) { $pgid = $row[0]; } }
$result = $dbh->prepare( "SELECT * FROM int_curator ORDER BY joinkey::INTEGER DESC" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
@row = $result->fetchrow();  
if ($row[0]) { if ($row[0] > $pgid) { $pgid = $row[0]; } }

$/ = "";
# my $infile = 'Updated_WS231_YH_objects.ace';
my $infile = 'Updated_WS231_YH_objects_Modified_6-5-2012.txt';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $entry = <IN>) {
  my (@lines) = split/\n/, $entry;
  my ($header) = shift @lines;
  next unless ($header =~ m/: "(WBInteraction\d+)"/);
  my $name = $1;
  foreach my $line (@lines) {
    if ($line =~ m/PCR_interactor\s+"(.*?)"\s+Bait/) {                        $hash{$name}{pcrbait}{$1}++; }
      elsif ($line =~ m/PCR_interactor\s+"(.*?)"\s+Target/) {                 $hash{$name}{pcrtarget}{$1}++; }
      elsif ($line =~ m/Sequence_interactor\s+"(.*?)"\s+Bait/) {              $hash{$name}{sequencebait}{$1}++; }
      elsif ($line =~ m/Sequence_interactor\s+"(.*?)"\s+Target/) {            $hash{$name}{sequencetarget}{$1}++; }
      elsif ($line =~ m/Interactor_overlapping_gene\s+"(.*?)"\s+Bait/) {      $hash{$name}{genebait}{$1}++; }
      elsif ($line =~ m/Interactor_overlapping_gene\s+"(.*?)"\s+Target/) {    $hash{$name}{genetarget}{$1}++; }
      elsif ($line =~ m/Interactor_overlapping_CDS\s+"(.*?)"\s+Bait/) {       $hash{$name}{cdsbait}{$1}++; }
      elsif ($line =~ m/Interactor_overlapping_CDS\s+"(.*?)"\s+Target/) {     $hash{$name}{cdstarget}{$1}++; }
      elsif ($line =~ m/Library_screened\s+(".*?")\s+(\d+)/) {                $hash{$name}{library}{"$1 $2"}++; }
      elsif ($line =~ m/Library_screened\s+(".*?")/) {                        $hash{$name}{library}{$1}++; }
      elsif ($line =~ m/(Yeast_one_hybrid)/) {                                $hash{$name}{detectionmethod}{$1}++; }
      elsif ($line =~ m/(Directed_yeast_one_hybrid)/) {                       $hash{$name}{detectionmethod}{$1}++; }
      elsif ($line =~ m/(Yeast_two_hybrid)/) {                                $hash{$name}{detectionmethod}{$1}++; }
      elsif ($line =~ m/From_laboratory\s+"(.*?)"/) {                         $hash{$name}{laboratory}{$1}++; }
      elsif ($line =~ m/Paper\s+"(.*?)"/) {                                   $hash{$name}{paper}{$1}++; }
      elsif ($line =~ m/Remark\s+"(.*?)"/) {                                  $hash{$name}{remark}{$1}++; }
      elsif ($line =~ m/Description\s+"(.*?)"/) {                             $hash{$name}{confidence}{$1}++; }
      elsif ($line =~ m/(Physical)/) {                                        $hash{$name}{type}{$1}++; }
      else { print "ERR unaccounted line in $name : $line\n"; }
  } # foreach my $line (@lines)
} # while (my $entry = <IN>)
close (IN) or die "Cannot close $infile : $!";

my @pgcommands;
foreach my $name (sort keys %hash) {
  $pgid++;
  push @pgcommands, "INSERT INTO int_name VALUES ('$pgid', '$name')";
  push @pgcommands, "INSERT INTO int_name_hst VALUES ('$pgid', '$name')";
  push @pgcommands, "INSERT INTO int_curator VALUES ('$pgid', 'WBPerson1760')";
  push @pgcommands, "INSERT INTO int_curator_hst VALUES ('$pgid', 'WBPerson1760')";
  foreach my $table (sort keys %{ $hash{$name} }) {
    my $type = $types{$table};
    my $data;
    if ($type eq 'multi') { ($data) = join'","', keys %{ $hash{$name}{$table} }; $data = '"' . $data . '"'; }
      elsif ($type eq 'single') {
        my @data = keys %{ $hash{$name}{$table} };
        if (scalar(@data) > 1) { print "ERR too many entries for $table in $name @data\n"; next; }
          else { $data = $data[0]; } }
      elsif ($type eq 'text') { ($data) = join' | ', keys %{ $hash{$name}{$table} }; }
      else { print qq(ERR unaccounted for type "$type" in $table\n); next; }
    push @pgcommands, "INSERT INTO int_$table VALUES ('$pgid', '$data')";
    push @pgcommands, "INSERT INTO int_${table}_hst VALUES ('$pgid', '$data')";
  } # foreach my $table (sort keys %{ $hash{$name} })
} # foreach my $name (sort keys %hash)

foreach my $pgcommand (@pgcommands) {
  print "$pgcommand\n"; 
# UNCOMMENT TO POPULATE
#   $dbh->do( $pgcommand );
} # foreach my $pgcommand (@pgcommands)


__END__

DELETE FROM int_pcrbait WHERE int_timestamp > '2012-06-06 15:00';
DELETE FROM int_pcrtarget WHERE int_timestamp > '2012-06-06 15:00';
DELETE FROM int_sequencebait WHERE int_timestamp > '2012-06-06 15:00';
DELETE FROM int_sequencetarget WHERE int_timestamp > '2012-06-06 15:00';
DELETE FROM int_genebait WHERE int_timestamp > '2012-06-06 15:00';
DELETE FROM int_genetarget WHERE int_timestamp > '2012-06-06 15:00';
DELETE FROM int_cdsbait WHERE int_timestamp > '2012-06-06 15:00';
DELETE FROM int_cdstarget WHERE int_timestamp > '2012-06-06 15:00';
DELETE FROM int_library WHERE int_timestamp > '2012-06-06 15:00';
DELETE FROM int_detectionmethod WHERE int_timestamp > '2012-06-06 15:00';
DELETE FROM int_laboratory WHERE int_timestamp > '2012-06-06 15:00';
DELETE FROM int_paper WHERE int_timestamp > '2012-06-06 15:00';
DELETE FROM int_remark WHERE int_timestamp > '2012-06-06 15:00';
DELETE FROM int_confidence WHERE int_timestamp > '2012-06-06 15:00';
DELETE FROM int_type WHERE int_timestamp > '2012-06-06 15:00';




Interaction : "WBInteraction000505215"
PCR_interactor	 "p_B0507.1_93"	Bait
Interactor_overlapping_gene	 "WBGene00015218"	Bait
PCR_interactor	 "mv_F43G9.11"	Target
Interactor_overlapping_gene	 "WBGene00000468"	Target
Library_screened	 "AD-TF mini library" 4
Yeast_one_hybrid	
From_laboratory	 "VL"
Paper	 "WBPaper00027683"
Physical

Interaction : "WBInteraction000505216"
PCR_interactor	 "p_B0507.1_93"	Bait
Interactor_overlapping_gene	 "WBGene00015218"	Bait
PCR_interactor	 "mv_C42D8.4"	Target
Interactor_overlapping_gene	 "WBGene00016600"	Target
Library_screened	 "AD-wrmcDNA library" 1
Yeast_one_hybrid	
From_laboratory	 "VL"
Paper	 "WBPaper00027683"
Physical

