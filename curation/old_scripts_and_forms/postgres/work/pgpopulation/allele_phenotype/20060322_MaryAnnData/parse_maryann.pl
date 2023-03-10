#!/usr/bin/perl

# Location now at /home/acedb/carol/read_mary_ann_data/parse_maryann.pl
#
# Read an infile from Mary Ann, create Allele data if new (type, tempname,
# finalname, phenotype).  If it already exists and has NBP data (from sanger),
# warn that it will overwrite.  If it already exists and has no NBP data, add to
# a new big box.  For Carol.  2006 05 17

use strict;
use Pg;
use Jex;	# getPgDate

my %alleles;
my %tags;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

$/ = '';
# my $infile = 'Mary_Ann_data.txt';
# my $infile = 'var_descriptions_24_apr.ace';
# my $infile = 'var_descriptions_25_apr.ace';
my $infile = 'var_descriptions_20060511.ace';
my $flag;

$flag = 'testing';
if ($ARGV[1]) { $flag = $ARGV[1]; }

unless ($ARGV[0]) {
  print "You must enter an inputfile.\n";
  print "You may also enter testing or real (to read into postgres), defaults to testing\n";
  print "Usage : ./parse_maryann.pl input_file [testing|real]\n";
  die; }
else {
  $infile = $ARGV[0]; }
print "flag $flag, infile $infile\n";

my $date = &getSimpleSecDate;
my $outfile = 'outfile.' . $date;

open (OUT, ">$outfile") or die "Cannot create $outfile : $!";


print "This script only deals with Variation data that has only Phenotype_remark\n\n";

my %existing; my $already_exists;	# hash of existing joinkeys and flag if one of them in current file
my $result = $conn->exec( "SELECT joinkey FROM alp_tempname;" );
while (my @row = $result->fetchrow() ) { $existing{$row[0]}++; }
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $para = <IN>) {
  chomp $para;
  my (@lines) = split/\n/, $para;
  my $header = shift @lines;		# skip Variation header
  my $allele = '';
  if ($header =~ m/Variation : \"([^\"]+)\"/) { $allele = $1; }
  if ($existing{$allele}) { $already_exists++; print OUT "ALREADY EXISTS $allele\n"; }
    else { print OUT "NEW allele $allele\n"; }
  my $variation_data = shift @lines;
  if ($variation_data) {
      if ($variation_data =~ m/Phenotype_remark\s+\"(.*?)$/) { 
          $variation_data = $1; 
          my $date = &getPgDate();  
          $date =~ s/\s+/_/g; 
          $variation_data .= " -O \"${date}_NBP_sanger"; }
        else { print "ERR Doesn't match Phenotype_remark : $variation_data\n"; } }
    else { next; }
  if ($existing{$allele}) { 
    my %phen; my $found_nbp; my $current_box;
    my $result = $conn->exec( "SELECT * FROM alp_phenotype WHERE joinkey = '$allele' ORDER BY alp_timestamp" );
    while (my @row = $result->fetchrow) { $phen{$row[1]} = $row[2]; }	# get each box's phenotype text
    foreach my $box (sort keys %phen) {
      $current_box = $box;			# current box is the box we're looking at 
      if ($phen{$box} =~ m/NBP/) { $found_nbp++; &replace_or_warn($allele, $variation_data, $box, $phen{$box}); } }
    unless ($found_nbp) { 		# no NBP data, add into new box
      $current_box++;
      unless ($flag eq 'testing') { 
        my $command = "INSERT INTO alp_phenotype VALUES ('$allele', '$current_box', '$variation_data', CURRENT_TIMESTAMP)";
        my $result = $conn->exec( $command );
        print OUT "NEW big box COMMAND $command\n";
      }
    }
  } # if ($existing{$allele}) 
  else {				# new Variation
    unless ($flag eq 'testing') {
      my $command = "INSERT INTO alp_type VALUES ('$allele', 'Allele');";
      print OUT "$command\n";
      my $result = $conn->exec( $command );
      $command = "INSERT INTO alp_tempname VALUES ('$allele', '$allele');";
      print OUT "$command\n";
      $result = $conn->exec( $command );
      $command = "INSERT INTO alp_finalname VALUES ('$allele', '$allele');";
      print OUT "$command\n";
      $result = $conn->exec( $command );
      $command = "INSERT INTO alp_phenotype VALUES ('$allele', '1', '$variation_data', CURRENT_TIMESTAMP)";
      $result = $conn->exec( $command );
      print OUT "$command\n";
    }
  }

# IF exists
#   check if alp_phenotype matches NBP
#     if so -> potentially replace or warn
#     if not -> add into another big box 
#   check if anything in Phenotype_remark is different, and warn
#   if nothign is different, ignore
# IF doesn't exist, create type Allele ;  tempname variation_name ;  alp_phenotype Phenotype_remark
#   make the alp_phenotype look like  data" -O "date_NBP_sanger  with current date
} # while (my $para = <IN>)
close (IN) or die "Cannot close $infile : $!";

sub replace_or_warn {
  my ($allele, $variation_data, $box, $current_data) = @_;
  my ($new) = $variation_data =~ m/^([^"]+)\"/;
  my ($cur) = $current_data =~ m/^([^"]+)\"/;
  unless ($new eq $cur) {			# if data is different (minus acedb timestamps)
    unless ($flag eq 'testing') {
      my $command = "INSERT INTO alp_phenotype VALUES ('$allele', '$box', '$variation_data', CURRENT_TIMESTAMP)";
      my $result = $conn->exec( $command );
      print OUT "$command\n";
    } # unless ($flag eq 'testing')
    print "WARN $allele HAS $current_data BEING REPLACED BY $variation_data\n";
  }
} # sub replace_or_warn

close (OUT) or die "Cannot close $outfile : $!";

__END__

open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $para = <IN>) {
  chomp $para;
  my (@lines) = split/\n/, $para;
  shift @lines;		# skip Variation header
  unless ($lines[0]) { print "SKIPPING blank entry : -=${para}=-\n"; next; }
  my $allele = '';
  if ($para =~ m/Variation : \"([^\"]+)\"/) { $allele = $1; $alleles{$1}++; }
  my $command = "INSERT INTO alp_type VALUES ('$allele', 'Allele');";
  print "$command\n";
  my $result = $conn->exec( $command );
  $command = "INSERT INTO alp_tempname VALUES ('$allele', '$allele');";
  print "$command\n";
  $result = $conn->exec( $command );
  $command = "INSERT INTO alp_finalname VALUES ('$allele', '$allele');";
  print "$command\n";
  $result = $conn->exec( $command );
  my $c_pen = 0; my $c_nat = 0; my $c_heat = 0; my $c_cold = 0; my $c_func = 0;
  foreach my $line (@lines) {
    my $tag = '';
    if ($line =~ m/^(\w+)\t \-O \"[^\"]+\" (\w+)/) { $tag = $2; $tags{$2}++; } else { print "ERR $line\n"; }
    if ($tag eq 'Completely_penetrant') { 
      if ($line =~ m/^\w+\t \-O \"[^\"]+\" \w+ (-O \"[^"]+\")/) { 
        unless ($line =~ m/^\w+\t \-O \"[^\"]+\" \w+ (-O \"[^"]+\")$/) { print "ERR incomplete LINE $line\n"; }
        $c_pen++;
        my $command = "INSERT INTO alp_penetrance VALUES ('$allele', '1', '$c_pen', 'Complete $1');";
        print "$command\n";
        my $result = $conn->exec( $command );
        print "$allele	alp_penetrance	Complete $1\n"; } }
    elsif ($tag eq 'Partially_penetrant') {
      if ($line =~ m/^\w+\t \-O \"[^\"]+\" \w+ (-O \"[^"]+\")/) { 
        unless ($line =~ m/^\w+\t \-O \"[^\"]+\" \w+ (-O \"[^"]+\")$/) { print "ERR incomplete LINE $line\n"; }
        $c_pen++;
        my $command = "INSERT INTO alp_penetrance VALUES ('$allele', '1', '$c_pen', 'Incomplete $1');";
        print "$command\n";
        my $result = $conn->exec( $command );
        print "$allele	alp_penetrance	Incomplete $1\n"; } }
    elsif ($tag eq 'Dominant') {
      if ($line =~ m/^\w+\t \-O \"[^\"]+\" \w+ (-O \"[^"]+\")/) { 
        unless ($line =~ m/^\w+\t \-O \"[^\"]+\" \w+ (-O \"[^"]+\")$/) { print "ERR incomplete LINE $line\n"; }
        $c_nat++;
        my $command = "INSERT INTO alp_nature VALUES ('$allele', '1', '$c_nat', 'Dominant $1');";
        print "$command\n";
        my $result = $conn->exec( $command );
        print "$allele	alp_nature	Dominant $1\n"; } }
    elsif ($tag eq 'Recessive') {
      if ($line =~ m/^\w+\t \-O \"[^\"]+\" \w+ (-O \"[^"]+\")/) { 
        unless ($line =~ m/^\w+\t \-O \"[^\"]+\" \w+ (-O \"[^"]+\")$/) { print "ERR incomplete LINE $line\n"; }
        $c_nat++;
        my $command = "INSERT INTO alp_nature VALUES ('$allele', '1', '$c_nat', 'Recessive $1');";
        print "$command\n";
        my $result = $conn->exec( $command );
        print "$allele	alp_nature	Recessive $1\n"; } }
    elsif ($tag eq 'Semi_dominant') {
      if ($line =~ m/^\w+\t \-O \"[^\"]+\" \w+ (-O \"[^"]+\")/) { 
        unless ($line =~ m/^\w+\t \-O \"[^\"]+\" \w+ (-O \"[^"]+\")$/) { print "ERR incomplete LINE $line\n"; }
        $c_nat++;
        my $command = "INSERT INTO alp_nature VALUES ('$allele', '1', '$c_nat', 'Semi_dominant $1');";
        print "$command\n";
        my $result = $conn->exec( $command );
        print "$allele	alp_nature	Semi_dominant $1\n"; } }
    elsif ($tag eq 'Maternal') {
      if ($line =~ m/^\w+\t \-O \"[^\"]+\" \w+ (-O \"[^"]+\")/) { 
        my $good = 0;
        if ($line =~ m/^\w+\t \-O \"[^\"]+\" \w+ -O \"[^"]+\" Strictly_maternal (-O \"[^"]+\")$/) { 
          $c_nat++;
          my $command = "INSERT INTO alp_nature VALUES ('$allele', '1', '$c_nat', 'Strictly_maternal $1');";
          print "$command\n";
          my $result = $conn->exec( $command );
          print "$allele	alp_nature	Strictly_maternal $1\n"; $good++; }
        elsif ($line =~ m/^\w+\t \-O \"[^\"]+\" \w+ -O \"[^"]+\" With_maternal_effect (-O \"[^"]+\")$/) { 
          $c_nat++;
          my $command = "INSERT INTO alp_nature VALUES ('$allele', '1', '$c_nat', 'With_maternal_effect $1');";
          print "$command\n";
          my $result = $conn->exec( $command );
          print "$allele	alp_nature	With_maternal_effect $1\n"; $good++; }
        else {
          if ($line =~ m/^\w+\t \-O \"[^\"]+\" \w+ (-O \"[^"]+\")$/) { 
            $c_nat++;
            my $command = "INSERT INTO alp_nature VALUES ('$allele', '1', '$c_nat', 'Maternal $1');";
            print "$command\n";
            my $result = $conn->exec( $command );
            print "$allele	alp_nature	Maternal $1\n"; $good++; } }
        unless ($good) { print "ERR incomplete LINE $line\n"; } } }
    elsif ($tag eq 'Temperature_sensitive') {
      if ($line =~ m/^\w+\t \-O \"[^\"]+\" \w+ (-O \"[^"]+\")/) { 
        my $good = 0;
        if ($line =~ m/^\w+\t \-O \"[^\"]+\" \w+ -O \"[^"]+\" Heat_sensitive (-O \"[^"]+\")/) {
          $c_heat++;
          my $command = "INSERT INTO alp_heat_sens VALUES ('$allele', '1', '$c_heat', 'Heat_sensitive $1');";
          print "$command\n";
          my $result = $conn->exec( $command );
          print "$allele	alp_heat_sens	Heat_sensitive $1\n"; 
          if ($line =~ m/^\w+\t \-O \"[^\"]+\" \w+ -O \"[^"]+\" Heat_sensitive -O \"[^"]+\" (\"[^"]*\" -O \"[^"]+\")/) {
            my $degree = $1; if ($degree =~ m/^\"(.*?)\"$/) { $degree = $1; }
            if ($degree) { 
              my $command = "INSERT INTO alp_heat_degree VALUES ('$allele', '1', '$c_heat', '$degree');";
              print "$command\n";
              my $result = $conn->exec( $command );
              print "$allele	alp_heat_degree	$degree\n"; }
            if ($line =~ m/^\w+\t \-O \"[^\"]+\" \w+ -O \"[^"]+\" \w+ -O \"[^"]+\" \"[^"]*\" -O \"[^"]+\" Paper_evidence -O \"[^"]+\" (\"[^"]+\" -O \"[^"]+\")$/) { 
              my $evi = $1; if ($evi =~ m/^\"/) { $evi =~ s/^\"//g; } if ($evi =~ m/\"$/) { $evi =~ s/\"$//g; }
              my $command = "INSERT INTO alp_paper VALUES ('$allele', '1', '$evi');";
              print "$command\n";
              my $result = $conn->exec( $command );
              print "$allele	alp_paper	$1\n"; $good++; }
            elsif ($line =~ m/^\w+\t \-O \"[^\"]+\" \w+ -O \"[^"]+\" \w+ -O \"[^"]+\" \"[^"]*\" -O \"[^"]+\" Person_evidence -O \"[^"]+\" (\"[^"]+\" -O \"[^"]+\")$/) { 
              my $evi = $1; if ($evi =~ m/^\"/) { $evi =~ s/^\"//g; } if ($evi =~ m/\"$/) { $evi =~ s/\"$//g; }
              my $command = "INSERT INTO alp_person VALUES ('$allele', '1', '$evi');";
              print "$command\n";
              my $result = $conn->exec( $command );
              print "$allele	alp_person	$1\n"; $good++; }
            if ($line =~ m/^\w+\t \-O \"[^\"]+\" \w+ -O \"[^"]+\" Heat_sensitive -O \"[^"]+\" (\"[^"]+\" -O \"[^"]+\")$/) { $good++; } }
          elsif ($line =~ m/^\w+\t \-O \"[^\"]+\" \w+ -O \"[^"]+\" Heat_sensitive (-O \"[^"]+\")$/) { $good++; } }
        elsif ($line =~ m/^\w+\t \-O \"[^\"]+\" \w+ -O \"[^"]+\" Cold_sensitive (-O \"[^"]+\")/) {
          $c_cold++;
          my $command = "INSERT INTO alp_cold_sens VALUES ('$allele', '1', '$c_cold', 'Cold_sensitive $1');";
          print "$command\n";
          my $result = $conn->exec( $command );
          print "$allele	alp_cold_sens	Cold_sensitive $1\n"; 
#           if ($line =~ m/^\w+\t \-O \"[^\"]+\" \w+ -O \"[^"]+\" Cold_sensitive -O \"[^"]+\" (\"[^"]+\" -O \"[^"]+\")/) { 
#             my $degree = $1; if ($degree =~ m/^\"(.*?)\"$/) { $degree = $1; }
#             my $command = "INSERT INTO alp_cold_degree VALUES ('$allele', '1', '$c_cold', '$degree');";
#             print "$command\n";
#             my $result = $conn->exec( $command );
#             print "$allele	alp_cold_degree	$degree\n"; $good++; } 
          if ($line =~ m/^\w+\t \-O \"[^\"]+\" \w+ -O \"[^"]+\" Cold_sensitive -O \"[^"]+\" (\"[^"]*\" -O \"[^"]+\")/) {
            my $degree = $1; if ($degree =~ m/^\"(.*?)\"$/) { $degree = $1; }
            if ($degree) { 
              my $command = "INSERT INTO alp_cold_degree VALUES ('$allele', '1', '$c_cold', '$degree');";
              print "$command\n";
              my $result = $conn->exec( $command );
              print "$allele	alp_cold_degree	$degree\n"; }
            if ($line =~ m/^\w+\t \-O \"[^\"]+\" \w+ -O \"[^"]+\" \w+ -O \"[^"]+\" \"[^"]*\" -O \"[^"]+\" Paper_evidence -O \"[^"]+\" (\"[^"]+\" -O \"[^"]+\")$/) { 
              my $evi = $1; if ($evi =~ m/^\"/) { $evi =~ s/^\"//g; } if ($evi =~ m/\"$/) { $evi =~ s/\"$//g; }
              my $command = "INSERT INTO alp_paper VALUES ('$allele', '1', '$evi');";
              print "$command\n";
              my $result = $conn->exec( $command );
              print "$allele	alp_paper	$1\n"; $good++; }
            elsif ($line =~ m/^\w+\t \-O \"[^\"]+\" \w+ -O \"[^"]+\" \w+ -O \"[^"]+\" \"[^"]*\" -O \"[^"]+\" Person_evidence -O \"[^"]+\" (\"[^"]+\" -O \"[^"]+\")$/) { 
              my $evi = $1; if ($evi =~ m/^\"/) { $evi =~ s/^\"//g; } if ($evi =~ m/\"$/) { $evi =~ s/\"$//g; }
              my $command = "INSERT INTO alp_person VALUES ('$allele', '1', '$evi');";
              print "$command\n";
              my $result = $conn->exec( $command );
              print "$allele	alp_person	$1\n"; $good++; }
            if ($line =~ m/^\w+\t \-O \"[^\"]+\" \w+ -O \"[^"]+\" Cold_sensitive -O \"[^"]+\" (\"[^"]+\" -O \"[^"]+\")$/) { $good++; } }
          elsif ($line =~ m/^\w+\t \-O \"[^\"]+\" \w+ -O \"[^"]+\" Cold_sensitive (-O \"[^"]+\")$/) { $good++; } }
        else {
          if ($line =~ m/^\w+\t \-O \"[^\"]+\" (\w+ -O \"[^"]+\")/) { 
            my $command = "INSERT INTO alp_remark VALUES ('$allele', '1', '$1');";
            print "$command\n";
            my $result = $conn->exec( $command );
            print "$allele	alp_remark	$1\n"; $good++; } 
#           print "BAD_DATA no heat/cold sensitive $allele\n"; $good++; 	# not really good, but not an error either
        }
        unless ($good) { print "ERR incomplete LINE $line\n"; } } }
    elsif ($tag eq 'Gain_of_function') {
      if ($line =~ m/^\w+\t \-O \"[^\"]+\" \w+ (-O \"[^"]+\")/) { 
        my $good = 0;
        if ($line =~ m/^\w+\t \-O \"[^\"]+\" \w+ -O \"[^"]+\" Dominant_negative (-O \"[^"]+\")/) {
          $c_func++;
          my $command = "INSERT INTO alp_func VALUES ('$allele', '1', '$c_func', 'Dominant_negative $1');";
          print "$command\n";
          my $result = $conn->exec( $command );
          print "$allele	alp_func	Dominant_negative $1\n"; 
          if ($line =~ m/^\w+\t \-O \"[^\"]+\" \w+ -O \"[^"]+\" \w+ -O \"[^"]+\" Person_evidence -O \"[^"]+\" (\"[^"]+\" -O \"[^"]+\")$/) { 
            my $evi = $1; if ($evi =~ m/^\"/) { $evi =~ s/^\"//g; } if ($evi =~ m/\"$/) { $evi =~ s/\"$//g; }
            my $command = "INSERT INTO alp_person VALUES ('$allele', '1', '$evi');";
            print "$command\n";
            my $result = $conn->exec( $command );
            print "$allele	alp_func	Person_evidence $1\n"; $good++; }
          if ($line =~ m/^\w+\t \-O \"[^\"]+\" \w+ -O \"[^"]+\" Dominant_negative (-O \"[^"]+\")$/) { $good++; } }
        elsif ($line =~ m/^\w+\t \-O \"[^\"]+\" \w+ -O \"[^"]+\" Neomorph (-O \"[^"]+\")/) {
          $c_func++;
          my $command = "INSERT INTO alp_func VALUES ('$allele', '1', '$c_func', 'Neomorph $1');";
          print "$command\n";
          my $result = $conn->exec( $command );
          print "$allele	alp_func	Neomorph $1\n"; 
          if ($line =~ m/^\w+\t \-O \"[^\"]+\" \w+ -O \"[^"]+\" \w+ -O \"[^"]+\" Paper_evidence -O \"[^"]+\" (\"[^"]+\" -O \"[^"]+\")$/) { 
            my $evi = $1; if ($evi =~ m/^\"/) { $evi =~ s/^\"//g; } if ($evi =~ m/\"$/) { $evi =~ s/\"$//g; }
            my $command = "INSERT INTO alp_paper VALUES ('$allele', '1', '$evi');";
            print "$command\n";
            my $result = $conn->exec( $command );
            print "$allele	alp_func	Paper_evidence $1\n"; $good++; }
          if ($line =~ m/^\w+\t \-O \"[^\"]+\" \w+ -O \"[^"]+\" Neomorph (-O \"[^"]+\")$/) { $good++; } }
#         elsif ($line =~ m/^\w+\t \-O \"[^\"]+\" \w+ -O \"[^"]+\" Neomorph (-O \"[^"]+\")$/) { 
#           $c_func++;
#           my $command = "INSERT INTO alp_func VALUES ('$allele', '1', '$c_func', 'Neomorph $1');";
#           print "$command\n";
#           my $result = $conn->exec( $command );
#           print "$allele	alp_func	Neomorph $1\n"; $good++; }
        elsif ($line =~ m/^\w+\t \-O \"[^\"]+\" \w+ -O \"[^"]+\" Uncharacterised_gain_of_function (-O \"[^"]+\")$/) { 
          $c_func++;
          my $command = "INSERT INTO alp_func VALUES ('$allele', '1', '$c_func', 'Uncharacterised_gain_of_function $1');";
          print "$command\n";
          my $result = $conn->exec( $command );
          print "$allele	alp_func	Uncharacterised_gain_of_function $1\n"; $good++; }
        else {
          if ($line =~ m/^\w+\t \-O \"[^\"]+\" \w+ (-O \"[^"]+\")$/) { 
            $c_func++;
            my $command = "INSERT INTO alp_func VALUES ('$allele', '1', '$c_func', 'Gain_of_function $1');";
            print "$command\n";
            my $result = $conn->exec( $command );
            print "$allele	alp_func	Gain_of_function $1\n"; $good++; } }
        unless ($good) { print "ERR incomplete LINE $line\n"; } } }
    elsif ($tag eq 'Loss_of_function') {
      if ($line =~ m/^\w+\t \-O \"[^\"]+\" \w+ (-O \"[^"]+\")/) { 
        my $good = 0;
        if ($line =~ m/^\w+\t \-O \"[^\"]+\" \w+ -O \"[^"]+\" Amorph (-O \"[^"]+\")/) {
          $c_func++;
          my $command = "INSERT INTO alp_func VALUES ('$allele', '1', '$c_func', 'Amorph $1');";
          print "$command\n";
          my $result = $conn->exec( $command );
          print "$allele	alp_func	Amorph $1\n"; 
          if ($line =~ m/^\w+\t \-O \"[^\"]+\" \w+ -O \"[^"]+\" \w+ -O \"[^"]+\" Person_evidence -O \"[^"]+\" (\"[^"]+\" -O \"[^"]+\")$/) { 
            my $evi = $1; if ($evi =~ m/^\"/) { $evi =~ s/^\"//g; } if ($evi =~ m/\"$/) { $evi =~ s/\"$//g; }
            my $command = "INSERT INTO alp_person VALUES ('$allele', '1', '$evi');";
            print "$command\n";
            my $result = $conn->exec( $command );
            print "$allele	alp_func	Person_evidence $1\n"; $good++; }
          elsif ($line =~ m/^\w+\t \-O \"[^\"]+\" \w+ -O \"[^"]+\" \w+ -O \"[^"]+\" Paper_evidence -O \"[^"]+\" (\"[^"]+\" -O \"[^"]+\")$/) { 
            my $evi = $1; if ($evi =~ m/^\"/) { $evi =~ s/^\"//g; } if ($evi =~ m/\"$/) { $evi =~ s/\"$//g; }
            my $command = "INSERT INTO alp_paper VALUES ('$allele', '1', '$evi');";
            print "$command\n";
            my $result = $conn->exec( $command );
            print "$allele	alp_func	Paper_evidence $1\n"; $good++; }
          elsif ($line =~ m/^\w+\t \-O \"[^\"]+\" \w+ -O \"[^"]+\" \w+ (-O \"[^"]+\")$/) { $good++; } }
        elsif ($line =~ m/^\w+\t \-O \"[^\"]+\" \w+ -O \"[^"]+\" Hypomorph (-O \"[^"]+\")/) { 
          $c_func++;
          my $command = "INSERT INTO alp_func VALUES ('$allele', '1', '$c_func', 'Hypomorph $1');";
          print "$command\n";
          my $result = $conn->exec( $command );
          print "$allele	alp_func	Hypomorph $1\n"; 
          if ($line =~ m/^\w+\t \-O \"[^\"]+\" \w+ -O \"[^"]+\" \w+ -O \"[^"]+\" Person_evidence -O \"[^"]+\" (\"[^"]+\" -O \"[^"]+\")$/) { 
            my $evi = $1; if ($evi =~ m/^\"/) { $evi =~ s/^\"//g; } if ($evi =~ m/\"$/) { $evi =~ s/\"$//g; }
            my $command = "INSERT INTO alp_person VALUES ('$allele', '1', '$evi');";
            print "$command\n";
            my $result = $conn->exec( $command );
            print "$allele	alp_func	Person_evidence $1\n"; $good++; }
          elsif ($line =~ m/^\w+\t \-O \"[^\"]+\" \w+ -O \"[^"]+\" \w+ -O \"[^"]+\" Paper_evidence -O \"[^"]+\" (\"[^"]+\" -O \"[^"]+\")$/) { 
            my $evi = $1; if ($evi =~ m/^\"/) { $evi =~ s/^\"//g; } if ($evi =~ m/\"$/) { $evi =~ s/\"$//g; }
            my $command = "INSERT INTO alp_paper VALUES ('$allele', '1', '$evi');";
            print "$command\n";
            my $result = $conn->exec( $command );
            print "$allele	alp_func	Paper_evidence $1\n"; $good++; }
          elsif ($line =~ m/^\w+\t \-O \"[^\"]+\" \w+ -O \"[^"]+\" Hypomorph (-O \"[^"]+\")$/) { $good++; } }
        elsif ($line =~ m/^\w+\t \-O \"[^\"]+\" \w+ -O \"[^"]+\" Uncharacterised_loss_of_function (-O \"[^"]+\")/) { 
          $c_func++;
          my $command = "INSERT INTO alp_func VALUES ('$allele', '1', '$c_func', 'Uncharacterised_loss_of_function $1');";
          print "$command\n";
          my $result = $conn->exec( $command );
          print "$allele	alp_func	Uncharacterised_loss_of_function $1\n";
          if ($line =~ m/^\w+\t \-O \"[^\"]+\" \w+ -O \"[^"]+\" \w+ -O \"[^"]+\" Person_evidence -O \"[^"]+\" (\"[^"]+\" -O \"[^"]+\")$/) {
            my $evi = $1; if ($evi =~ m/^\"/) { $evi =~ s/^\"//g; } if ($evi =~ m/\"$/) { $evi =~ s/\"$//g; }
            my $command = "INSERT INTO alp_person VALUES ('$allele', '1', '$evi');";
            print "$command\n";
            my $result = $conn->exec( $command );
            print "$allele	alp_func	Person_evidence $1\n"; $good++; }
          elsif ($line =~ m/^\w+\t \-O \"[^\"]+\" \w+ -O \"[^"]+\" \w+ -O \"[^"]+\" Paper_evidence -O \"[^"]+\" (\"[^"]+\" -O \"[^"]+\")$/) { 
            my $evi = $1; if ($evi =~ m/^\"/) { $evi =~ s/^\"//g; } if ($evi =~ m/\"$/) { $evi =~ s/\"$//g; }
            my $command = "INSERT INTO alp_paper VALUES ('$allele', '1', '$evi');";
            print "$command\n";
            my $result = $conn->exec( $command );
            print "$allele	alp_func	Paper_evidence $1\n"; $good++; }
          elsif ($line =~ m/^\w+\t \-O \"[^\"]+\" \w+ -O \"[^"]+\" \w+ (-O \"[^"]+\")$/) { $good++; } }
        else {
          if ($line =~ m/^\w+\t \-O \"[^\"]+\" \w+ (-O \"[^"]+\")$/) { 
            $c_func++;
            my $command = "INSERT INTO alp_func VALUES ('$allele', '1', '$c_func', 'Loss_of_function $1');";
            print "$command\n";
            my $result = $conn->exec( $command );
            print "$allele	alp_func	Loss_of_function $1\n"; $good++; } }
        unless ($good) { print "ERR $allele incomplete LINE $line\n"; } } }
    elsif ($tag eq 'Phenotype_remark') {
      if ($line =~ m/^\w+\t \-O \"[^\"]+\" \w+ (-O \"[^"]+\")/) {
        my $good = 0;
        if ($line =~ m/^\w+\t \-O \"[^\"]+\" \w+ -O \"[^"]+\" (\"[^"]+\" -O \"[^"]+\")/) {
          my $remark = $1;
          if ($line =~ m/^\w+\t \-O \"[^\"]+\" \w+ -O \"[^"]+\" (\"[^"]+\" -O \"[^"]+\" CGC_data_submission -O \"[^"]+\")$/) {
            $remark = $1; if ($remark =~ m/^\"/) { $remark =~ s/^\"//g; } if ($remark =~ m/\"$/) { $remark =~ s/\"$//g; }
            my $command = "INSERT INTO alp_phenotype VALUES ('$allele', '1', '$remark');";
            print "$command\n";
            my $result = $conn->exec( $command );
            print "$allele	alp_phenotype	Phenotype_remark $1\n"; $good++; }
          else { 
            if ($remark =~ m/^\"/) { $remark =~ s/^\"//g; } if ($remark =~ m/\"$/) { $remark =~ s/\"$//g; }
            my $command = "INSERT INTO alp_phenotype VALUES ('$allele', '1', '$remark');";
            print "$command\n";
            my $result = $conn->exec( $command );
            print "$allele	alp_phenotype	Phenotype_remark $remark\n"; }
          if ($line =~ m/^\w+\t \-O \"[^\"]+\" \w+ -O \"[^"]+\" \"[^"]+\" -O \"[^"]+\" Person_evidence -O \"[^"]+\" (\"[^"]+\" -O \"[^"]+\")$/) { 
            my $evi = $1; if ($evi =~ m/^\"/) { $evi =~ s/^\"//g; } if ($evi =~ m/\"$/) { $evi =~ s/\"$//g; }
            my $command = "INSERT INTO alp_person VALUES ('$allele', '1', '$evi');";
            print "$command\n";
            my $result = $conn->exec( $command );
            print "$allele	alp_person	$evi\n"; $good++; }
          elsif ($line =~ m/^\w+\t \-O \"[^\"]+\" \w+ -O \"[^"]+\" \"[^"]+\" -O \"[^"]+\" Curator_confirmed -O \"[^"]+\" (\"[^"]+\" -O \"[^"]+\")$/) { 
            my $evi = $1; if ($evi =~ m/^\"/) { $evi =~ s/^\"//g; } if ($evi =~ m/\"$/) { $evi =~ s/\"$//g; }
            my $command = "INSERT INTO alp_curator VALUES ('$allele', '1', '$evi');";
            print "$command\n";
            my $result = $conn->exec( $command );
            print "$allele	alp_curator	$evi\n"; $good++; }
          elsif ($line =~ m/^\w+\t \-O \"[^\"]+\" \w+ -O \"[^"]+\" \"[^"]+\" -O \"[^"]+\" Paper_evidence -O \"[^"]+\" (\"[^"]+\" -O \"[^"]+\")$/) { 
            my $evi = $1; if ($evi =~ m/^\"/) { $evi =~ s/^\"//g; } if ($evi =~ m/\"$/) { $evi =~ s/\"$//g; }
            my $command = "INSERT INTO alp_paper VALUES ('$allele', '1', '$evi');";
            print "$command\n";
            my $result = $conn->exec( $command );
            print "$allele	alp_paper	$evi\n"; $good++; }
          elsif ($line =~ m/^\w+\t \-O \"[^\"]+\" \w+ -O \"[^"]+\" (\"[^"]+\" -O \"[^"]+\")$/) { $good++; } }
        unless ($good) { print "ERR $allele incomplete LINE $line\n"; } } }

  } # foreach my $line (@lines)
  my $highest = 1;
  if ($c_pen > $highest) { $highest = $c_pen; }
  if ($c_nat > $highest) { $highest = $c_nat; }
  if ($c_heat > $highest) { $highest = $c_heat; }
  if ($c_cold > $highest) { $highest = $c_cold; }
  if ($c_func > $highest) { $highest = $c_func; }
  if ($highest > 1) { print "LARGE $allele $highest\n"; }
# fake term for testing the dumper TEST
#   for my $i (1 .. $highest) {
#     my $command = "INSERT INTO alp_term VALUES ('$allele', '1', '$i', 'WBPhenotype0000553 (muscle_ultrastructure_disorganized)');";
#     print "$command\n";
#     my $result = $conn->exec( $command );
#   }
} # while (my $para = <IN>)
close (IN) or die "Cannot close $infile : $!";

# figure out main tags
# foreach my $tag (sort keys %tags) { print "T $tag\n"; }

# wrote this to check no repeats, there aren't.
# foreach my $allele (sort keys %alleles) {
#   if ($alleles{$allele} > 1) { print "ERR $allele\n"; }
#   print "$allele $alleles{$allele}\n";
# }




__END__

Tags are :
# Completely_penetrant	-> alp_penetrance : Complete
# Dominant		-> alp_nature : Dominant
# Gain_of_function	-> alp_func (variable)
# Loss_of_function	-> alp_func (variable)
# Maternal		-> alp_mat_effect : Strictly_maternal
# Partially_penetrant	-> alp_penetrance : Incomplete
Phenotype_remark	-> alp_phenotype
# Recessive		-> alp_nature : Recessive
# Semi_dominant		-> alp_nature : Semi_dominant
# Temperature_sensitive	-> alp_heat_degree / alp_heat_sens / alp_cold_degree / alp_cold_sens


Phenotype_remark	Phenotype_remark	Phenotype_Text
Recessive	Recessive	Dominance
Semi_dominant	Semi_dominant	Dominance
Dominant	Dominant	Dominance
Partially_penetrant	Incomplete	Penetrance (text)
Completely_penetrant	Complete	Penetrance
Temperature_sensitive	
	Heat_sensitive	Heat_sensitive (text)
	Cold_sensitive	Cold_sensitive (text)
Loss_of_function	
	Haploinsufficient	Haploinsufficient 
	Hypomorph	Hypomorph	Func. Change
	Amorph	Amorph	Func. Change
	Uncharacterised_loss_of_function Uncharacterised_loss_of_function	Func. Change
Gain_of_function
	Dominant_negative		Dominant_negative	Func. Change
	Hypermorph	Hypermorph	Func. Change
	Neomorph	Neomorph	Func. Change
	Uncharacterised_gain_of_function	Uncharacterised_gain_of_function	Func. Change
Maternal
	Strictly_maternal	Strictly_maternal	Mat Effect
	With_maternal_effect	With_maternal_effect	Mat Effect

