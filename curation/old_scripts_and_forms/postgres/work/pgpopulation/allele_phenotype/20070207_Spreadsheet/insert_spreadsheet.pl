#!/usr/bin/perl -w

# take a spreadsheet output from carol for mass annotation of allele-phenotype
# connections.  2007 02 07

# FIX  Need to convert terms to WBPhenotype##### (term) using 
# sub readCvs {
#   my $directory = '/home/postgres/work/pgpopulation/allele_phenotype/20070207_Spreadsheet/temp';
#   chdir($directory) or die "Cannot go to $directory ($!)";
#   `cvs -d /var/lib/cvsroot checkout PhenOnt`;
#   my $file = $directory . '/PhenOnt/PhenOnt.obo';
#   $/ = "";
#   open (IN, "<$file") or die "Cannot open $file : $!";
#   while (my $para = <IN>) {
#     if ($para =~ m/id: WBPhenotype(\d+).*?\bname: (\w+)/s) {
#       my $term = $2; my $number = 'WBPhenotype' . $1;
#       $phenotypeTerms{term}{$term} = $number;
#       $phenotypeTerms{number}{$number} = $term; } }
#   close (IN) or die "Cannot close $file : $!";
#   $directory .= '/PhenOnt';
#   `rm -rf $directory`;
# #   foreach my $term (sort keys %{ $phenotypeTerms{term} }) { print "T $term N
# #   $phenotypeTerms{term}{$term} E<BR>\n"; }
# } # sub readCvs


use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my %hash;

my $infile = 'phenotype_curation_WBPaper00026735.txt';
open (IN, "<$infile") or die "Cannot open $infile : $!";
<IN>;
my $line = <IN>;
chomp $line;
my ($curator, $paper, $person) = split/\t/, $line;
<IN>;
<IN>;
while ($line = <IN>) {
  my $type = 'Allele';
  chomp $line;
  my ($tempname, $term, $phen_remark, $quantity_remark, $quantity, $genotype, $life_stage, $anat_term, $temperature, $preparation, $treatment, $nature, $penetrance, $mat_effect, $pat_effect, $heat_sens, $cold_sens, $func, $haplo) = split/\t/, $line; 
  my ($not, $percent, $range, $heat_degree, $cold_degree) = ('', '', '', '', '');
  if ($term =~ m/\|/) {
    if ($term =~ m/^([\s\w]+)\|([\s\w]+)$/) { 
      $term = $1; $not = 'checked'; }
    else { print "ERR found pipe term $term\n"; } }
  if ($penetrance =~ m/\|/) {
    if ($penetrance =~ m/^([\s\w]+)\|([\s\w]+)\|([\s\w]+)$/) { 
      $penetrance = $1;
      $percent = $2; 
      $range = $3; }
    elsif ($penetrance =~ m/^([\s\w]+)\|([\s\w]+)$/) { 
      $penetrance = $1;
      $percent = $2; }
    else { print "ERR found pipe penetrance $penetrance\n"; } }
  if ($hash{$tempname}{row}) { $hash{$tempname}{row}++; }
    else { $hash{$tempname}{row} = 1; }
  my $row = $hash{$tempname}{row};
  if ($tempname) { $hash{$tempname}{alp_tempname} = $tempname; }
  if ($type) { $hash{$tempname}{alp_type} = $type; }
  if ($curator) { $hash{$tempname}{alp_curator} = $curator; }
  if ($paper) { $hash{$tempname}{alp_paper} = $paper; }
  if ($person) { $hash{$tempname}{alp_person} = $person; }
  if ($term) { $hash{$tempname}{alp_term}{$row} = $term; }
  if ($not) { $hash{$tempname}{alp_not}{$row} = $not; }
  if ($phen_remark) { $hash{$tempname}{alp_phen_remark}{$row} = $phen_remark; }
  if ($quantity_remark) { $hash{$tempname}{alp_quantity_remark}{$row} = $quantity_remark; }
  if ($genotype) { $hash{$tempname}{alp_genotype}{$row} = $genotype; }
  if ($life_stage) { $hash{$tempname}{alp_life_stage}{$row} = $life_stage; }
  if ($anat_term) { $hash{$tempname}{alp_anat_term}{$row} = $anat_term; }
  if ($temperature) { $hash{$tempname}{alp_temperature}{$row} = $temperature; }
  if ($preparation) { $hash{$tempname}{alp_preparation}{$row} = $preparation; }
  if ($treatment) { $hash{$tempname}{alp_treatment}{$row} = $treatment; }
  if ($nature) { $hash{$tempname}{alp_nature}{$row} = $nature; }
  if ($penetrance) { $hash{$tempname}{alp_penetrance}{$row} = $penetrance; }
  if ($range) { $hash{$tempname}{alp_range}{$row} = $range; }
  if ($percent) { $hash{$tempname}{alp_percent}{$row} = $percent; }
  if ($mat_effect) { $hash{$tempname}{alp_mat_effect}{$row} = $mat_effect; }
  if ($pat_effect) { $hash{$tempname}{alp_pat_effect}{$row} = 'checked'; }
  if ($heat_sens) { $hash{$tempname}{alp_heat_sens}{$row} = 'checked'; }
  if ($heat_degree) { $hash{$tempname}{alp_heat_degree}{$row} = $heat_degree; }
  if ($cold_sens) { $hash{$tempname}{alp_cold_sens}{$row} = 'checked'; } 
  if ($cold_degree) { $hash{$tempname}{alp_cold_degree}{$row} = $cold_degree; }
  if ($func) { $hash{$tempname}{alp_func}{$row} = $func; }
  if ($haplo) { $hash{$tempname}{alp_haplo}{$row} = 'checked'; }
} # while ($line = <IN>)
close (IN) or die "Cannot close $infile : $!";

foreach my $tempname (sort keys %hash) {
  my $box = '1';
  my $result = $conn->exec( "SELECT * FROM alp_term WHERE joinkey = '$tempname' ORDER BY alp_box DESC;" );
  my @row = $result->fetchrow;
  if ($row[1]) { $box = $row[1]; $box++; }
  foreach my $pgtable (sort keys %{ $hash{$tempname} }) {
    next if ($pgtable eq 'row');
    if ( ($pgtable eq 'alp_type') || ($pgtable eq 'alp_tempname') ) {
      next if ($box > 1);
      my $command = "INSERT INTO $pgtable VALUES ('$tempname', '$hash{$tempname}{$pgtable}', CURRENT_TIMESTAMP);";
      print "$command\n";
      $result = $conn->exec( $command );
      }
    elsif ( ($pgtable eq 'alp_curator') || ($pgtable eq 'alp_paper') || ($pgtable eq 'alp_person') ) {
      my $command = "INSERT INTO $pgtable VALUES ('$tempname', '$box', '$hash{$tempname}{$pgtable}', CURRENT_TIMESTAMP);";
      print "$command\n";
      $result = $conn->exec( $command );
      }
    else {
      foreach my $column (sort {$a <=> $b} keys %{ $hash{$tempname}{$pgtable} }) {
        next unless ($hash{$tempname}{$pgtable}{$column});
        my $command = "INSERT INTO $pgtable VALUES ('$tempname', '$box', '$column', '$hash{$tempname}{$pgtable}{$column}', CURRENT_TIMESTAMP);";
        print "$command\n";
        $result = $conn->exec( $command );
      } # foreach my $column (sort {$a <=> $b} %{ $hash{$tempname}{$pgtable} })
    }
  } # foreach my $pgtable (sort keys %{ $hash{$tempname} })
} # foreach my $tempname (sort keys %hash)

__END__

my $result = $conn->exec( "SELECT * FROM one_groups;" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[1] =~ s///g;
    $row[2] =~ s///g;
    print "$row[0]\t$row[1]\t$row[2]\n";
  } # if ($row[0])
} # while (@row = $result->fetchrow)

__END__

DELETE FROM alp_tempname WHERE alp_timestamp ~ '2007-02-07 15:41';
DELETE FROM alp_type WHERE alp_timestamp ~ '2007-02-07 15:41';
DELETE FROM alp_curator WHERE alp_timestamp ~ '2007-02-07 15:41';
DELETE FROM alp_paper WHERE alp_timestamp ~ '2007-02-07 15:41';
DELETE FROM alp_person WHERE alp_timestamp ~ '2007-02-07 15:41';
DELETE FROM alp_term WHERE alp_timestamp ~ '2007-02-07 15:41';
DELETE FROM alp_not WHERE alp_timestamp ~ '2007-02-07 15:41';
DELETE FROM alp_phen_remark WHERE alp_timestamp ~ '2007-02-07 15:41';
DELETE FROM alp_quantity_remark WHERE alp_timestamp ~ '2007-02-07 15:41';
DELETE FROM alp_genotype WHERE alp_timestamp ~ '2007-02-07 15:41';
DELETE FROM alp_life_stage WHERE alp_timestamp ~ '2007-02-07 15:41';
DELETE FROM alp_anat_term WHERE alp_timestamp ~ '2007-02-07 15:41';
DELETE FROM alp_temperature WHERE alp_timestamp ~ '2007-02-07 15:41';
DELETE FROM alp_preparation WHERE alp_timestamp ~ '2007-02-07 15:41';
DELETE FROM alp_treatment WHERE alp_timestamp ~ '2007-02-07 15:41';
DELETE FROM alp_nature WHERE alp_timestamp ~ '2007-02-07 15:41';
DELETE FROM alp_penetrance WHERE alp_timestamp ~ '2007-02-07 15:41';
DELETE FROM alp_range WHERE alp_timestamp ~ '2007-02-07 15:41';
DELETE FROM alp_percent WHERE alp_timestamp ~ '2007-02-07 15:41';
DELETE FROM alp_mat_effect WHERE alp_timestamp ~ '2007-02-07 15:41';
DELETE FROM alp_pat_effect WHERE alp_timestamp ~ '2007-02-07 15:41';
DELETE FROM alp_heat_sens WHERE alp_timestamp ~ '2007-02-07 15:41';
DELETE FROM alp_heat_degree WHERE alp_timestamp ~ '2007-02-07 15:41';
DELETE FROM alp_cold_sens WHERE alp_timestamp ~ '2007-02-07 15:41';
DELETE FROM alp_cold_degree WHERE alp_timestamp ~ '2007-02-07 15:41';
DELETE FROM alp_func WHERE alp_timestamp ~ '2007-02-07 15:41';
DELETE FROM alp_haplo WHERE alp_timestamp ~ '2007-02-07 15:41';
