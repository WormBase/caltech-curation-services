#!/usr/bin/perl

use strict;
use Pg;

my %alleles;
my %tags;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;


$/ = '';
# my $infile = 'Mary_Ann_data.txt';
# my $infile = 'var_descriptions_24_apr.ace';
my $infile = 'var_descriptions_25_apr.ace';
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
# UNCOMMENT THIS TO TEST 
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

Variation : "ad446" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-03-19_17:26:22_ck1" Phenotype_remark -O "2004-03-19_17:26:22_ck1" "Serotonin- and dopamine-deficient, although low levels of serotonin immunoreactivity seen (possibly not genuine serotonin)" -O "2004-03-19_17:26:22_ck1" Person_evidence -O "2006-03-01_09:24:22_mt3" "WBPerson384 L" -O "2006-03-01_09:24:22_mt3"
Description	 -O "2004-03-19_17:26:22_ck1" Recessive -O "2004-03-19_17:26:22_ck1"
Description	 -O "2004-03-19_17:26:22_ck1" Completely_penetrant -O "2004-03-19_17:26:22_ck1"
Description	 -O "2004-03-19_17:26:22_ck1" Loss_of_function -O "2004-03-19_17:26:22_ck1" Amorph -O "2004-03-19_17:26:22_ck1"

Variation : "ad1674" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2005-08-18_15:05:18_ar2" Phenotype_remark -O "2003-08-18_14:57:19_krb" "No obvious phenotype" -O "2003-08-18_14:57:19_krb" Person_evidence -O "2003-08-18_14:57:19_krb" "WBPerson32" -O "2003-08-18_14:57:19_krb"

Variation : "ak63" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-01-27_11:47:08_ck1" Phenotype_remark -O "2004-01-27_11:47:08_ck1" "(1) suppresses the hyperreversal behavior of glr-1(akIs9) (2) nose touch defective" -O "2004-01-27_11:47:08_ck1" Paper_evidence -O "2006-02-28_13:54:04_mt3" "WBPaper00006349" -O "2006-02-28_13:54:04_mt3"
Description	 -O "2004-01-27_11:47:08_ck1" Recessive -O "2004-01-27_11:47:08_ck1"


Variation : "ar28" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2005-07-22_13:57:38_mt3" Phenotype_remark -O "2005-07-22_13:57:38_mt3" "Causes increased lin-12 signaling.  Causes extremely weak masculinization of hermaphrodites." -O "2005-07-22_13:57:38_mt3" Paper_evidence -O "2006-02-28_13:54:04_mt3" "WBPaper00002966" -O "2006-02-28_13:54:04_mt3"
Description	 -O "2005-07-22_13:57:38_mt3" Recessive -O "2005-07-22_13:57:38_mt3"

Variation : "ar41" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2005-07-22_13:57:38_mt3" Phenotype_remark -O "2005-07-22_13:57:38_mt3" "Causes increased lin-12 signaling. Causes extremely weak masculinization of hermaphrodites." -O "2005-07-22_13:57:38_mt3" Paper_evidence -O "2006-02-28_13:54:04_mt3" "WBPaper00002966" -O "2006-02-28_13:54:04_mt3"
Description	 -O "2005-07-22_13:57:38_mt3" Recessive -O "2005-07-22_13:57:38_mt3"


Variation : "ar197" -O "2004-09-01_16:31:44_rem"
Description	 -O "2004-09-01_16:31:44_rem" Phenotype_remark -O "2004-09-01_16:31:44_rem" "ar197 does not have any obvious phenotype on its own, but it is a very potent suppressor of the sel-12(ar171) egg-laying defect" -O "2004-09-01_16:31:44_rem" Person_evidence -O "2004-09-01_16:31:44_rem" "WBPerson292" -O "2004-09-01_16:31:44_rem"
Description	 -O "2004-09-01_16:31:44_rem" Loss_of_function -O "2004-09-01_16:31:44_rem"

Variation : "ar200" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-03-25_17:01:05_ck1" Phenotype_remark -O "2004-03-25_17:01:05_ck1" "no apparent  phenotype on its own. spr-1(ar200) is a strong suppressor of the egg-laying phenotype of sel-12 mutants" -O "2004-03-25_17:01:05_ck1" Paper_evidence -O "2006-03-01_09:24:22_mt3" "WBPaper00004474" -O "2006-03-01_09:24:22_mt3"
Description	 -O "2004-03-25_17:01:05_ck1" Recessive -O "2004-03-25_17:01:05_ck1"
Description	 -O "2004-03-25_17:01:05_ck1" Semi_dominant -O "2004-03-25_17:01:05_ck1"
Description	 -O "2004-03-25_17:01:05_ck1" Loss_of_function -O "2004-03-25_17:01:05_ck1" Uncharacterised_loss_of_function -O "2004-03-25_17:01:05_ck1"


Variation : "ar205" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-03-25_16:58:25_ck1" Phenotype_remark -O "2004-03-25_16:58:25_ck1" "no apparent phenotype on its own. Is a strong suppressor of the egg-laying defects of sel-12 mutants" -O "2004-03-25_16:58:25_ck1" Paper_evidence -O "2006-03-01_09:24:22_mt3" "WBPaper00004474" -O "2006-03-01_09:24:22_mt3"
Description	 -O "2004-03-25_16:58:25_ck1" Loss_of_function -O "2004-03-25_16:58:25_ck1" Uncharacterised_loss_of_function -O "2004-03-25_16:58:25_ck1"


Variation : "ar471" -O "2005-07-13_16:45:05_td3"
Description	 -O "2005-07-13_16:45:05_td3" Recessive -O "2005-07-13_16:45:05_td3"

Variation : "ar474" -O "2005-07-13_16:45:05_td3"
Description	 -O "2005-07-13_16:45:05_td3" Recessive -O "2005-07-13_16:45:05_td3"

Variation : "ar476" -O "2005-07-13_16:45:05_td3"
Description	 -O "2005-07-13_16:45:05_td3" Recessive -O "2005-07-13_16:45:05_td3"

Variation : "ar477" -O "2005-07-13_16:45:05_td3"
Description	 -O "2005-07-13_16:45:05_td3" Recessive -O "2005-07-13_16:45:05_td3"

Variation : "ar481" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2003-04-11_13:55:09_ck1" Gain_of_function -O "2003-04-11_13:55:09_ck1" Dominant_negative -O "2003-04-11_13:55:09_ck1"

Variation : "ar483" -O "2005-07-13_16:45:05_td3"
Description	 -O "2005-07-13_16:45:05_td3" Recessive -O "2005-07-13_16:45:05_td3"

Variation : "ar507" -O "2005-07-13_16:45:05_td3"
Description	 -O "2005-07-13_16:45:05_td3" Recessive -O "2005-07-13_16:45:05_td3"

Variation : "ar511" -O "2005-07-13_16:45:05_td3"
Description	 -O "2005-07-13_16:45:05_td3" Recessive -O "2005-07-13_16:45:05_td3"


Variation : "ax69" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2005-08-18_15:05:18_ar2" Phenotype_remark -O "2000-07-28_13:55:58.1_sylvia" "Class III B.  (g53ts, ax69ts).  Meiosis defective.  Incompletely penetrant and variably expressed." -O "2000-07-28_13:55:58.1_sylvia" Curator_confirmed -O "2006-03-01_09:24:22_mt3" "WBPerson1250" -O "2006-03-01_09:24:22_mt3"


Variation : "b284" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2005-09-26_12:03:41_mt3" Recessive -O "2005-09-26_12:03:41_mt3"
Description	 -O "2005-09-26_12:03:41_mt3" Gain_of_function -O "2005-09-26_12:03:41_mt3" Dominant_negative -O "2005-09-26_12:03:41_mt3" Person_evidence -O "2005-09-27_13:24:59_mt3" "WBPerson399" -O "2005-09-27_13:24:59_mt3"

Variation : "b1014" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2005-07-13_16:45:05_td3" Recessive -O "2005-07-13_16:45:05_td3"

Variation : "b1015" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2005-07-13_16:45:05_td3" Recessive -O "2005-07-13_16:45:05_td3"

Variation : "b1018" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2005-07-13_16:45:05_td3" Recessive -O "2005-07-13_16:45:05_td3"

Variation : "b1019" -O "2005-07-18_18:03:47_td3"
Description	 -O "2005-07-18_18:15:38_td3" Recessive -O "2005-07-18_18:15:38_td3"

Variation : "b1020" -O "2004-04-07_11:23:34_wormpub"

Variation : "b1021" -O "2004-04-07_11:23:34_wormpub"

Variation : "b1046" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2003-04-11_13:55:09_ck1" Gain_of_function -O "2003-04-11_13:55:09_ck1" Dominant_negative -O "2003-04-11_13:55:09_ck1"



Variation : "bc189" -O "2005-07-22_13:57:38_mt3"
Description	 -O "2005-07-22_13:57:38_mt3" Phenotype_remark -O "2005-07-22_13:57:38_mt3" "Causes increased lin-12 signaling.  Causes extremely weak masculinization of hermaphrodites." -O "2005-07-22_13:57:38_mt3" Paper_evidence -O "2006-02-28_13:54:04_mt3" "WBPaper00002966" -O "2006-02-28_13:54:04_mt3"
Description	 -O "2005-07-22_13:57:38_mt3" Recessive -O "2005-07-22_13:57:38_mt3"
Description	 -O "2005-07-22_13:57:38_mt3" Temperature_sensitive -O "2005-07-22_13:57:38_mt3" Heat_sensitive -O "2005-07-22_13:57:38_mt3" "bc189 n1077 behaves like a Df at 25C, like + at 15C" -O "2005-07-22_13:57:38_mt3"

Variation : "bc243" -O "2005-07-22_13:57:38_mt3"
Description	 -O "2005-07-22_13:57:38_mt3" Phenotype_remark -O "2005-07-22_13:57:38_mt3" "Causes extremely weak masculinization of hermaphrodites.  Causes increased lin-12 signaling." -O "2005-07-22_13:57:38_mt3" Paper_evidence -O "2006-02-28_13:54:04_mt3" "WBPaper00024442" -O "2006-02-28_13:54:04_mt3"
Description	 -O "2005-07-22_13:57:38_mt3" Recessive -O "2005-07-22_13:57:38_mt3"


Variation : "bn126" -O "2005-04-20_11:16:53_mt3"
Description	 -O "2005-07-20_11:11:42_wormpub" Recessive -O "2005-07-20_11:11:42_wormpub"

Variation : "cc561" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2005-06-16_09:14:32_mt3" Recessive -O "2005-06-16_09:14:32_mt3"
Description	 -O "2005-06-16_09:14:32_mt3" Loss_of_function -O "2005-06-16_09:14:32_mt3" Hypomorph -O "2005-06-16_09:14:32_mt3"

Variation : "ct76" -O "2004-04-07_13:24:12_wormpub"
Description	 -O "2005-03-07_15:52:19_mt3" Dominant -O "2005-03-07_15:52:19_mt3"

Variation : "ct77" -O "2004-04-07_13:24:12_wormpub"
Description	 -O "2005-03-08_13:32:48_mt3" Dominant -O "2005-03-08_13:32:48_mt3"

Variation : "ct417" -O 
Description	 -O "2003-04-15_10:04:46_ck1" Recessive -O "2003-04-15_10:04:46_ck1"

Variation : "ct418" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2003-04-15_10:04:46_ck1" Semi_dominant -O "2003-04-15_10:04:46_ck1"

Variation : "cu9" -O "2004-05-12_10:22:41_ck1"
Description	 -O "2004-05-12_10:22:41_ck1" Recessive -O "2004-05-12_10:22:41_ck1"

Variation : "cu11" -O "2005-10-11_14:03:57_mt3"
Description	 -O "2005-10-11_14:03:57_mt3" Phenotype_remark -O "2005-10-11_14:03:57_mt3" "Homozygous viable with stuffed pharynx" -O "2005-10-11_14:03:57_mt3" Person_evidence -O "2005-10-11_14:03:57_mt3" "WBPerson460" -O "2005-10-11_14:03:57_mt3"
Description	 -O "2005-10-11_14:03:57_mt3" Recessive -O "2005-10-11_14:03:57_mt3"
Description	 -O "2005-10-11_14:03:57_mt3" Completely_penetrant -O "2005-10-11_14:03:57_mt3"



Variation : "dd5" -O "2003-11-24_10:53:12_CGC_strain_update"
Description	 -O "2005-07-21_14:15:31_td3" Recessive -O "2005-07-21_14:15:31_td3"
Description	 -O "2005-07-21_14:15:31_td3" Temperature_sensitive -O "2005-07-21_14:15:31_td3"
Description	 -O "2005-07-21_14:15:31_td3" Maternal -O "2005-07-21_14:15:31_td3" Strictly_maternal -O "2005-07-21_14:15:31_td3"


Variation : "e14" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2005-08-18_15:05:18_ar2" Phenotype_remark -O "2004-08-18_08:15:53_krb" "Dumpy, small" -O "2004-08-18_08:15:53_krb" Paper_evidence -O "2004-08-18_08:15:53_krb" "WBPaper00005927" -O "2004-08-18_08:15:53_krb"


Variation : "e53" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2003-06-11_14:43:45_ck1" Loss_of_function -O "2003-06-11_14:43:45_ck1" Amorph -O "2003-06-11_14:43:45_ck1"


Variation : "e152" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2003-06-11_14:43:45_ck1" Loss_of_function -O "2003-06-11_14:43:45_ck1" Hypomorph -O "2003-06-11_14:43:45_ck1"


Variation : "e189" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-01-27_15:34:27_ck1" Recessive -O "2004-01-27_15:34:27_ck1"
Description	 -O "2004-01-27_15:34:27_ck1" Loss_of_function -O "2004-01-27_15:34:27_ck1" Hypomorph -O "2004-01-27_15:34:27_ck1"





Variation : "e369" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2005-08-18_15:05:18_ar2" Phenotype_remark -O "2004-07-22_11:17:44_rem" "paralysis, defective egg laying and dumpy" -O "2004-07-22_11:17:44_rem" Paper_evidence -O "2006-02-28_13:54:04_mt3" "WBPaper00002050" -O "2006-02-28_13:54:04_mt3"

Variation : "e382" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-03-25_16:58:25_ck1" Phenotype_remark -O "2004-03-25_16:58:25_ck1" "shrinker Unc" -O "2004-03-25_16:58:25_ck1" Paper_evidence -O "2006-03-01_09:24:22_mt3" "WBPaper00003576" -O "2006-03-01_09:24:22_mt3"
Description	 -O "2004-03-25_16:58:25_ck1" Recessive -O "2004-03-25_16:58:25_ck1"
Description	 -O "2004-03-25_16:58:25_ck1" Completely_penetrant -O "2004-03-25_16:58:25_ck1"
Description	 -O "2004-03-25_16:58:25_ck1" Loss_of_function -O "2004-03-25_16:58:25_ck1" Amorph -O "2004-03-25_16:58:25_ck1"

Variation : "e389" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2005-08-18_15:05:18_ar2" Phenotype_remark -O "2004-07-22_11:17:44_rem" "paralysis, defective egg-laying and dumpy" -O "2004-07-22_11:17:44_rem" Paper_evidence -O "2006-02-09_09:32:38_mt3" "WBPaper00002050" -O "2006-02-09_09:32:38_mt3"



Variation : "e407" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-03-25_16:58:25_ck1" Phenotype_remark -O "2004-03-25_16:58:25_ck1" "shrinker Unc" -O "2004-03-25_16:58:25_ck1" Paper_evidence -O "2006-03-01_09:24:22_mt3" "WBPaper00003576" -O "2006-03-01_09:24:22_mt3"
Description	 -O "2004-03-25_16:58:25_ck1" Recessive -O "2004-03-25_16:58:25_ck1"
Description	 -O "2004-03-25_16:58:25_ck1" Completely_penetrant -O "2004-03-25_16:58:25_ck1"
Description	 -O "2004-03-25_16:58:25_ck1" Loss_of_function -O "2004-03-25_16:58:25_ck1" Amorph -O "2004-03-25_16:58:25_ck1"



Variation : "e432" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-07-22_11:17:44_rem" Phenotype_remark -O "2004-07-22_11:17:44_rem" "paralysis, defective egg-laying and dumpy" -O "2004-07-22_11:17:44_rem" Paper_evidence -O "2006-02-09_09:32:38_mt3" "WBPaper00002050" -O "2006-02-09_09:32:38_mt3"


Variation : "e468" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-03-25_16:58:25_ck1" Phenotype_remark -O "2004-03-25_16:58:25_ck1" "shrinker Unc" -O "2004-03-25_16:58:25_ck1" Paper_evidence -O "2006-03-01_09:24:22_mt3" "WBPaper00003576" -O "2006-03-01_09:24:22_mt3"
Description	 -O "2004-03-25_16:58:25_ck1" Recessive -O "2004-03-25_16:58:25_ck1"
Description	 -O "2004-03-25_16:58:25_ck1" Completely_penetrant -O "2004-03-25_16:58:25_ck1"
Description	 -O "2004-03-25_16:58:25_ck1" Loss_of_function -O "2004-03-25_16:58:25_ck1" Amorph -O "2004-03-25_16:58:25_ck1"



Variation : "e553" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2003-06-11_14:43:45_ck1" Loss_of_function -O "2003-06-11_14:43:45_ck1" Amorph -O "2003-06-11_14:43:45_ck1"



Variation : "e641" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-03-25_17:01:05_ck1" Phenotype_remark -O "2004-03-25_17:01:05_ck1" "shrinker Unc" -O "2004-03-25_17:01:05_ck1" Paper_evidence -O "2006-03-01_09:24:22_mt3" "WBPaper00003576" -O "2006-03-01_09:24:22_mt3"
Description	 -O "2004-03-25_17:01:05_ck1" Recessive -O "2004-03-25_17:01:05_ck1"
Description	 -O "2004-03-25_17:01:05_ck1" Completely_penetrant -O "2004-03-25_17:01:05_ck1"
Description	 -O "2004-03-25_17:01:05_ck1" Loss_of_function -O "2004-03-25_17:01:05_ck1" Amorph -O "2004-03-25_17:01:05_ck1"



Variation : "e665" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2005-08-18_15:05:18_ar2" Phenotype_remark -O "2004-08-18_08:15:53_krb" "Uncoordinated, dominant, animals short, rigidly paralyzed with constant shaking of body" -O "2004-08-18_08:15:53_krb" Paper_evidence -O "2004-08-18_08:15:53_krb" "WBPaper00005927" -O "2004-08-18_08:15:53_krb"

Variation : "e678" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2005-08-18_15:05:18_ar2" Phenotype_remark -O "2004-08-18_08:15:53_krb" "Long(lon), 50\% longer than wild type" -O "2004-08-18_08:15:53_krb" Paper_evidence -O "2004-08-18_08:15:53_krb" "WBPaper00005927" -O "2004-08-18_08:15:53_krb"

"

Variation : "e791" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2003-06-11_14:43:45_ck1" Loss_of_function -O "2003-06-11_14:43:45_ck1" Amorph -O "2003-06-11_14:43:45_ck1"


Variation : "e879" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2003-07-30_16:23:10_ck1" Temperature_sensitive -O "2003-07-30_16:23:10_ck1"

Variation : "e929" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-03-25_17:01:05_ck1" Phenotype_remark -O "2004-03-25_17:01:05_ck1" "shrinker Unc" -O "2004-03-25_17:01:05_ck1" Paper_evidence -O "2006-03-01_09:24:22_mt3" "WBPaper00003576" -O "2006-03-01_09:24:22_mt3"
Description	 -O "2004-03-25_17:01:05_ck1" Recessive -O "2004-03-25_17:01:05_ck1"
Description	 -O "2004-03-25_17:01:05_ck1" Completely_penetrant -O "2004-03-25_17:01:05_ck1"
Description	 -O "2004-03-25_17:01:05_ck1" Loss_of_function -O "2004-03-25_17:01:05_ck1" Amorph -O "2004-03-25_17:01:05_ck1"




Variation : "e1036" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-03-10_14:18:19_wormpub" Temperature_sensitive -O "2004-03-10_14:18:19_wormpub" Cold_sensitive -O "2004-03-10_14:18:19_wormpub" "15C" -O "2004-03-10_14:18:19_wormpub" Paper_evidence -O "2006-02-09_09:32:38_mt3" "WBPaper00006290" -O "2006-02-09_09:32:38_mt3"

Variation : "e1120" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2005-08-18_15:05:18_ar2" Phenotype_remark -O "2004-07-22_11:17:44_rem" "paralysis, defective egg-laying and dumpy" -O "2004-07-22_11:17:44_rem" Paper_evidence -O "2006-02-09_09:32:38_mt3" "WBPaper0000205" -O "2006-02-09_09:32:38_mt3"

Variation : "e1141" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-08-20_16:51:40_rem" Recessive -O "2004-08-20_16:51:40_rem"
Description	 -O "2004-08-20_16:51:40_rem" Completely_penetrant -O "2004-08-20_16:51:40_rem"

Variation : "e1913e2383" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2005-08-18_15:05:18_ar2" Phenotype_remark -O "1999-09-09_11:20:52_sylvia" "wild_type" -O "1999-09-09_11:20:52_sylvia" Curator_confirmed -O "2006-03-01_09:24:22_mt3" "WBPerson1250" -O "2006-03-01_09:24:22_mt3"

Variation : "e1926" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2005-08-18_15:05:18_ar2" Phenotype_remark -O "2003-05-22_11:12:37_ck1" "lose of nearly all rays, but less severe than u282 and gm239" -O "2003-05-22_11:12:37_ck1" Curator_confirmed -O "2006-03-01_09:24:22_mt3" "WBPerson1845" -O "2006-03-01_09:24:22_mt3"

Variation : "e1960" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-03-24_10:17:33_ck1" Recessive -O "2004-03-24_10:17:33_ck1"

Variation : "e2055" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2005-07-22_13:57:38_mt3" Phenotype_remark -O "2005-07-22_13:57:38_mt3" "Causes significant masculinization of hermaphrodites.  Causes increased lin-12 signaling." -O "2005-07-22_13:57:38_mt3" Paper_evidence -O "2006-02-28_13:54:04_mt3" "WBPaper00024442" -O "2006-02-28_13:54:04_mt3"
Description	 -O "2005-07-22_13:57:38_mt3" Semi_dominant -O "2005-07-22_13:57:38_mt3"
Description	 -O "2005-07-22_13:57:38_mt3" Temperature_sensitive -O "2005-07-22_13:57:38_mt3" Cold_sensitive -O "2005-07-22_13:57:38_mt3" "Fully-penetrant Egl as homozygote at 15C or 20C but partially penetrant at 25C" -O "2005-07-22_13:57:38_mt3" Paper_evidence -O "2006-02-28_13:54:04_mt3" "WBPaper00024442" -O "2006-02-28_13:54:04_mt3"

Variation : "e2175" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2003-04-15_10:04:46_ck1" Recessive -O "2003-04-15_10:04:46_ck1"

Variation : "e2432" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-01-27_15:34:27_ck1" Recessive -O "2004-01-27_15:34:27_ck1"

Variation : "e2575" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-04-27_09:55:31_krb" Recessive -O "2004-04-27_09:55:31_krb"

Variation : "e2655" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-03-29_15:51:25_ck1" Gain_of_function -O "2004-03-29_15:51:25_ck1"

Variation : "e2661" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-03-29_15:51:09_ck1" Gain_of_function -O "2004-03-29_15:51:09_ck1"

Variation : "e2678" -O "2005-09-01_11:32:32_mt3"
Description	 -O "2005-09-01_11:32:32_mt3" Phenotype_remark -O "2005-09-01_11:32:32_mt3" "Resistant to infection by M. nematophilum -- fails to swell." -O "2005-09-01_11:32:32_mt3" Person_evidence -O "2005-09-01_14:00:47_mt3" "WBPerson261" -O "2005-09-01_14:00:47_mt3"
Description	 -O "2005-09-01_11:32:32_mt3" Recessive -O "2005-09-01_11:32:32_mt3"
Description	 -O "2005-09-01_11:32:32_mt3" Completely_penetrant -O "2005-09-01_11:32:32_mt3"
Description	 -O "2005-09-01_11:32:32_mt3" Loss_of_function -O "2005-09-01_11:32:32_mt3" Uncharacterised_loss_of_function -O "2005-09-01_11:32:32_mt3" Person_evidence -O "2005-09-01_14:00:47_mt3" "WBPerson261" -O "2005-09-01_14:00:47_mt3"

Variation : "e2687" -O "2005-09-01_11:32:32_mt3"
Description	 -O "2005-09-01_11:32:32_mt3" Phenotype_remark -O "2005-09-01_11:32:32_mt3" "Resistant to infection by M. nematophilum - fails to swell." -O "2005-09-01_11:32:32_mt3" Person_evidence -O "2005-09-01_14:00:47_mt3" "WBPerson261" -O "2005-09-01_14:00:47_mt3"
Description	 -O "2005-09-01_11:32:32_mt3" Recessive -O "2005-09-01_11:32:32_mt3"
Description	 -O "2005-09-01_11:32:32_mt3" Completely_penetrant -O "2005-09-01_11:32:32_mt3"
Description	 -O "2005-09-01_11:32:32_mt3" Loss_of_function -O "2005-09-01_11:32:32_mt3" Uncharacterised_loss_of_function -O "2005-09-01_11:32:32_mt3" Person_evidence -O "2005-09-01_14:00:47_mt3" "WBPerson261" -O "2005-09-01_14:00:47_mt3"

Variation : "e2688" -O "2005-09-01_11:32:32_mt3"
Description	 -O "2005-09-01_11:32:32_mt3" Phenotype_remark -O "2005-09-01_11:32:32_mt3" "Resistant to infection by M. nematophilum. Slightly skiddy, some cuticle fragility." -O "2005-09-01_11:32:32_mt3" Person_evidence -O "2005-09-01_14:00:47_mt3" "WBPerson261" -O "2005-09-01_14:00:47_mt3"
Description	 -O "2005-09-01_11:32:32_mt3" Recessive -O "2005-09-01_11:32:32_mt3"
Description	 -O "2005-09-01_11:32:32_mt3" Loss_of_function -O "2005-09-01_11:32:32_mt3" Uncharacterised_loss_of_function -O "2005-09-01_11:32:32_mt3" Person_evidence -O "2005-09-01_14:00:47_mt3" "WBPerson261" -O "2005-09-01_14:00:47_mt3"
Description	 -O "2005-09-01_11:32:32_mt3" Completely_penetrant -O "2005-09-02_09:45:24_mt3"

Variation : "e2691" -O "2005-09-01_11:32:32_mt3"
Description	 -O "2005-09-01_11:32:32_mt3" Phenotype_remark -O "2005-09-01_11:32:32_mt3" "Resistant to infection by M. nematophilum." -O "2005-09-01_11:32:32_mt3" Person_evidence -O "2005-09-01_14:00:47_mt3" "WBPerson261" -O "2005-09-01_14:00:47_mt3"
Description	 -O "2005-09-01_11:32:32_mt3" Recessive -O "2005-09-01_11:32:32_mt3"
Description	 -O "2005-09-01_11:32:32_mt3" Completely_penetrant -O "2005-09-01_11:32:32_mt3"
Description	 -O "2005-09-01_11:32:32_mt3" Loss_of_function -O "2005-09-01_11:32:32_mt3" Uncharacterised_loss_of_function -O "2005-09-01_11:32:32_mt3" Person_evidence -O "2005-09-01_14:00:47_mt3" "WBPerson261" -O "2005-09-01_14:00:47_mt3"

Variation : "e2693" -O "2005-09-01_11:32:32_mt3"
Description	 -O "2005-09-01_11:32:32_mt3" Phenotype_remark -O "2005-09-01_11:32:32_mt3" "Resistant to infection by M. nematophilum.  Slightly small." -O "2005-09-01_11:32:32_mt3" Person_evidence -O "2005-09-01_14:00:47_mt3" "WBPerson261" -O "2005-09-01_14:00:47_mt3"
Description	 -O "2005-09-01_11:32:32_mt3" Recessive -O "2005-09-01_11:32:32_mt3"
Description	 -O "2005-09-01_11:32:32_mt3" Completely_penetrant -O "2005-09-01_11:32:32_mt3"
Description	 -O "2005-09-01_11:32:32_mt3" Loss_of_function -O "2005-09-01_11:32:32_mt3" Uncharacterised_loss_of_function -O "2005-09-01_11:32:32_mt3" Person_evidence -O "2005-09-01_14:00:47_mt3" "WBPerson261" -O "2005-09-01_14:00:47_mt3"

Variation : "e2696" -O "2005-09-01_11:32:32_mt3"
Description	 -O "2005-09-01_11:32:32_mt3" Phenotype_remark -O "2005-09-01_11:32:32_mt3" "Resistant to infection by M. nematophilum (no tail swelling).  Slightly uncoordinated." -O "2005-09-01_11:32:32_mt3" Person_evidence -O "2005-09-01_14:00:47_mt3" "WBPerson261" -O "2005-09-01_14:00:47_mt3"
Description	 -O "2005-09-01_11:32:32_mt3" Recessive -O "2005-09-01_11:32:32_mt3"
Description	 -O "2005-09-01_11:32:32_mt3" Completely_penetrant -O "2005-09-01_11:32:32_mt3"
Description	 -O "2005-09-01_11:32:32_mt3" Loss_of_function -O "2005-09-01_11:32:32_mt3" Uncharacterised_loss_of_function -O "2005-09-01_11:32:32_mt3" Person_evidence -O "2005-09-01_14:00:47_mt3" "WBPerson261" -O "2005-09-01_14:00:47_mt3"

Variation : "e2698" -O "2005-09-01_11:32:32_mt3"
Description	 -O "2005-09-01_11:32:32_mt3" Phenotype_remark -O "2005-09-01_11:32:32_mt3" "Resistant to infection by M. nematophilum. Slightly skiddy, fragile cuticle, bleach sensitive, hypersensitive to drugs.  Abnormal lectin staining." -O "2005-09-01_11:32:32_mt3" Person_evidence -O "2005-09-01_14:00:47_mt3" "WBPerson261" -O "2005-09-01_14:00:47_mt3"
Description	 -O "2005-09-01_11:32:32_mt3" Recessive -O "2005-09-01_11:32:32_mt3"
Description	 -O "2005-09-01_11:32:32_mt3" Completely_penetrant -O "2005-09-01_11:32:32_mt3"
Description	 -O "2005-09-01_11:32:32_mt3" Loss_of_function -O "2005-09-01_11:32:32_mt3" Uncharacterised_loss_of_function -O "2005-09-01_11:32:32_mt3" Person_evidence -O "2005-09-01_14:00:47_mt3" "WBPerson261" -O "2005-09-01_14:00:47_mt3"

Variation : "e2702" -O "2005-09-01_11:32:32_mt3"
Description	 -O "2005-09-01_11:32:32_mt3" Phenotype_remark -O "2005-09-01_11:32:32_mt3" "Resistant to infection by M. nematophilum." -O "2005-09-01_11:32:32_mt3" Person_evidence -O "2005-09-01_14:00:47_mt3" "WBPerson261" -O "2005-09-01_14:00:47_mt3"
Description	 -O "2005-09-01_11:32:32_mt3" Recessive -O "2005-09-01_11:32:32_mt3"
Description	 -O "2005-09-01_11:32:32_mt3" Loss_of_function -O "2005-09-01_11:32:32_mt3" Uncharacterised_loss_of_function -O "2005-09-01_11:32:32_mt3" Person_evidence -O "2005-09-01_14:00:47_mt3" "WBPerson261" -O "2005-09-01_14:00:47_mt3"
Description	 -O "2005-09-01_11:32:32_mt3" Completely_penetrant -O "2005-09-02_09:45:24_mt3"

Variation : "e2709" -O "2005-09-01_11:32:32_mt3"
Description	 -O "2005-09-01_11:32:32_mt3" Phenotype_remark -O "2005-09-01_11:32:32_mt3" "Resistant to infection by M. nematophilum. Abnormal lectin staining." -O "2005-09-01_11:32:32_mt3" Person_evidence -O "2005-09-01_14:00:47_mt3" "WBPerson261" -O "2005-09-01_14:00:47_mt3"
Description	 -O "2005-09-01_11:32:32_mt3" Recessive -O "2005-09-01_11:32:32_mt3"
Description	 -O "2005-09-01_11:32:32_mt3" Completely_penetrant -O "2005-09-01_11:32:32_mt3"
Description	 -O "2005-09-01_11:32:32_mt3" Loss_of_function -O "2005-09-01_11:32:32_mt3" Uncharacterised_loss_of_function -O "2005-09-01_11:32:32_mt3" Person_evidence -O "2005-09-01_14:00:47_mt3" "WBPerson261" -O "2005-09-01_14:00:47_mt3"

Variation : "e2710" -O "2005-09-01_11:32:32_mt3"
Description	 -O "2005-09-01_11:32:32_mt3" Phenotype_remark -O "2005-09-01_11:32:32_mt3" "Resistant to infection by M. nematophilum. Abnormal lectin staining." -O "2005-09-01_11:32:32_mt3" Person_evidence -O "2005-09-01_14:00:47_mt3" "WBPerson261" -O "2005-09-01_14:00:47_mt3"
Description	 -O "2005-09-01_11:32:32_mt3" Recessive -O "2005-09-01_11:32:32_mt3"
Description	 -O "2005-09-01_11:32:32_mt3" Completely_penetrant -O "2005-09-01_11:32:32_mt3"
Description	 -O "2005-09-01_11:32:32_mt3" Loss_of_function -O "2005-09-01_11:32:32_mt3" Uncharacterised_loss_of_function -O "2005-09-01_11:32:32_mt3"

Variation : "e2740" -O "2005-09-01_11:32:32_mt3"
Description	 -O "2005-09-01_11:32:32_mt3" Phenotype_remark -O "2005-09-01_11:32:32_mt3" "Resistant to infection by M. nematophilum." -O "2005-09-01_11:32:32_mt3" Person_evidence -O "2005-09-01_14:00:47_mt3" "WBPerson261" -O "2005-09-01_14:00:47_mt3"
Description	 -O "2005-09-01_11:32:32_mt3" Recessive -O "2005-09-01_11:32:32_mt3"
Description	 -O "2005-09-01_11:32:32_mt3" Loss_of_function -O "2005-09-01_11:32:32_mt3" Uncharacterised_loss_of_function -O "2005-09-01_11:32:32_mt3" Person_evidence -O "2005-09-01_14:00:47_mt3" "WBPerson261" -O "2005-09-01_14:00:47_mt3"
Description	 -O "2005-09-01_11:32:32_mt3" Completely_penetrant -O "2005-09-02_09:45:24_mt3"

Variation : "e2770" -O "2005-08-05_09:36:42_td3"

Variation : "e2779" -O "2005-09-01_11:32:32_mt3"
Description	 -O "2005-09-01_11:32:32_mt3" Phenotype_remark -O "2005-09-01_11:32:32_mt3" "Little or no tail-swelling after infection by M. nematophilum (slightly leaky Bus), despite rectal colonization by bacteria." -O "2005-09-01_11:32:32_mt3" Person_evidence -O "2005-09-01_14:00:47_mt3" "WBPerson261" -O "2005-09-01_14:00:47_mt3"
Description	 -O "2005-09-01_11:32:32_mt3" Recessive -O "2005-09-01_11:32:32_mt3"
Description	 -O "2005-09-01_11:32:32_mt3" Completely_penetrant -O "2005-09-01_11:32:32_mt3"
Description	 -O "2005-09-01_11:32:32_mt3" Loss_of_function -O "2005-09-01_11:32:32_mt3" Uncharacterised_loss_of_function -O "2005-09-01_11:32:32_mt3" Person_evidence -O "2005-09-01_14:00:47_mt3" "WBPerson261" -O "2005-09-01_14:00:47_mt3"

Variation : "e2795" -O "2005-09-01_11:32:32_mt3"
Description	 -O "2005-09-01_11:32:32_mt3" Phenotype_remark -O "2005-09-01_11:32:32_mt3" "Resistant to infection by M. nematophilum. Small, skiddy, slow-growing\; frequent vulval rupture\; bleach sensitive\; hypersensitive to drugs.  Abnormal lectin staining." -O "2005-09-01_11:32:32_mt3" Person_evidence -O "2005-09-01_14:00:47_mt3" "WBPerson261" -O "2005-09-01_14:00:47_mt3"
Description	 -O "2005-09-01_11:32:32_mt3" Recessive -O "2005-09-01_11:32:32_mt3"
Description	 -O "2005-09-01_11:32:32_mt3" Completely_penetrant -O "2005-09-01_11:32:32_mt3"
Description	 -O "2005-09-01_11:32:32_mt3" Loss_of_function -O "2005-09-01_11:32:32_mt3" Uncharacterised_loss_of_function -O "2005-09-01_11:32:32_mt3" Person_evidence -O "2005-09-01_14:00:47_mt3" "WBPerson261" -O "2005-09-01_14:00:47_mt3"

Variation : "e2797" -O "2005-08-12_17:29:56_td3"

Variation : "e2800" -O "2005-09-01_11:32:32_mt3"
Description	 -O "2005-09-01_11:32:32_mt3" Phenotype_remark -O "2005-09-01_11:32:32_mt3" "Resistant to infection by M. nematophilum.  Skiddy, bleach sensitive, hypersensitive to drugs. Abnormal lectin staining." -O "2005-09-01_11:32:32_mt3" Person_evidence -O "2005-09-01_14:00:47_mt3" "WBPerson261" -O "2005-09-01_14:00:47_mt3"
Description	 -O "2005-09-01_11:32:32_mt3" Recessive -O "2005-09-01_11:32:32_mt3"
Description	 -O "2005-09-01_11:32:32_mt3" Completely_penetrant -O "2005-09-01_11:32:32_mt3"
Description	 -O "2005-09-01_11:32:32_mt3" Loss_of_function -O "2005-09-01_11:32:32_mt3" Uncharacterised_loss_of_function -O "2005-09-01_11:32:32_mt3" Person_evidence -O "2005-09-01_14:00:47_mt3" "WBPerson261" -O "2005-09-01_14:00:47_mt3"

Variation : "e2802" -O "2005-09-01_11:32:32_mt3"
Description	 -O "2005-09-01_11:32:32_mt3" Phenotype_remark -O "2005-09-01_11:32:32_mt3" "Resistant to infection by M. nematophilum. Skiddy, frequent vulval rupture\; bleach sensitive\; hypersensitive to drugs, Abnormal lectin staining." -O "2005-09-01_11:32:32_mt3" Person_evidence -O "2005-09-01_14:00:47_mt3" "WBPerson261" -O "2005-09-01_14:00:47_mt3"
Description	 -O "2005-09-01_11:32:32_mt3" Recessive -O "2005-09-01_11:32:32_mt3"
Description	 -O "2005-09-01_11:32:32_mt3" Completely_penetrant -O "2005-09-01_11:32:32_mt3"
Description	 -O "2005-09-01_11:32:32_mt3" Loss_of_function -O "2005-09-01_11:32:32_mt3" Uncharacterised_loss_of_function -O "2005-09-01_11:32:32_mt3" Person_evidence -O "2005-09-01_14:00:47_mt3" "WBPerson261" -O "2005-09-01_14:00:47_mt3"

Variation : "ed3" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-07-22_11:17:44_rem" Phenotype_remark -O "2004-07-22_11:17:44_rem" "Reduced locomotion" -O "2004-07-22_11:17:44_rem" Paper_evidence -O "2006-02-28_13:54:04_mt3" "WBPaper00002306" -O "2006-02-28_13:54:04_mt3"
Description	 -O "2004-07-22_11:17:44_rem" Loss_of_function -O "2004-07-22_11:17:44_rem"

Variation : "ed4" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-07-22_11:17:44_rem" Phenotype_remark -O "2004-08-18_08:15:53_krb" "Reduced locomotion" -O "2004-08-18_08:15:53_krb" Paper_evidence -O "2004-08-18_08:15:53_krb" "WBPaper00002306" -O "2004-08-18_08:15:53_krb"
Description	 -O "2004-07-22_11:17:44_rem" Loss_of_function -O "2004-07-22_11:17:44_rem"

Variation : "ed9" -O "2004-07-22_11:17:44_rem"
Description	 -O "2004-07-22_11:17:44_rem" Phenotype_remark -O "2004-08-18_08:15:53_krb" "impedes production of normal UNC-119 message" -O "2004-08-18_08:15:53_krb" Paper_evidence -O "2004-08-18_08:15:53_krb" "WBPaper00002306" -O "2004-08-18_08:15:53_krb"

Variation : "ev432" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2003-06-11_14:43:45_ck1" Loss_of_function -O "2003-06-11_14:43:45_ck1" Hypomorph -O "2003-06-11_14:43:45_ck1"

Variation : "ev480" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2003-06-11_14:43:45_ck1" Loss_of_function -O "2003-06-11_14:43:45_ck1" Hypomorph -O "2003-06-11_14:43:45_ck1"

Variation : "ev585" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2003-06-11_14:43:45_ck1" Loss_of_function -O "2003-06-11_14:43:45_ck1" Hypomorph -O "2003-06-11_14:43:45_ck1"

Variation : "ev724" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2005-07-18_08:19:28_td3" Recessive -O "2005-07-18_08:19:28_td3"

Variation : "f120" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-07-23_11:14:20_krb" Loss_of_function -O "2004-07-23_11:14:20_krb"

Variation : "f121" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2005-08-18_15:05:18_ar2" Phenotype_remark -O "2004-07-23_11:14:20_krb" "Lethal" -O "2004-07-23_11:14:20_krb" Paper_evidence -O "2006-02-28_13:54:04_mt3" "WBPaper00004601" -O "2006-02-28_13:54:04_mt3"

Variation : "f131" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-01-27_15:34:27_ck1" Recessive -O "2004-01-27_15:34:27_ck1"
Description	 -O "2004-01-27_15:34:27_ck1" Loss_of_function -O "2004-01-27_15:34:27_ck1" Hypomorph -O "2004-01-27_15:34:27_ck1"

Variation : "g53" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2000-07-28_13:55:58.1_sylvia" Phenotype_remark -O "2000-07-28_13:55:58.1_sylvia" "Class III B.  (g53ts, ax69ts).  Meiosis defective.  Incompletely penetrant and variably expressed. g53ts E360 to K" -O "2000-07-28_13:55:58.1_sylvia" Curator_confirmed -O "2006-03-01_09:24:22_mt3" "WBPerson1250" -O "2006-03-01_09:24:22_mt3"

Variation : "gk183" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-01-13_09:46:24_mt3" Completely_penetrant -O "2006-01-13_09:46:24_mt3"
Description	 -O "2006-01-13_09:46:24_mt3" Phenotype_remark -O "2006-01-13_09:46:24_mt3" "Loss of anti-horseradish peroxidase staining (Western blot)" -O "2006-01-13_09:46:24_mt3" Person_evidence -O "2006-01-13_09:46:24_mt3" "WBPerson2099" -O "2006-01-13_09:46:24_mt3"

Variation : "gm239" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2005-08-18_15:05:18_ar2" Phenotype_remark -O "2003-05-22_11:12:37_ck1" "lose of nearly all rays" -O "2003-05-22_11:12:37_ck1" Paper_evidence -O "2006-02-28_13:54:04_mt3" "WBPaper00004492" -O "2006-02-28_13:54:04_mt3"

Variation : "gu24" -O "2005-07-04_08:53:45_mt3"
Description	 -O "2005-07-18_13:34:02_mt3" Phenotype_remark -O "2005-07-18_13:34:02_mt3" "Reduced lin-48::gfp expression. Male: reduced mating efficiency, some males have abnormal tails. Hermaphrodite: wildtype alone, Muv in homozygotes with lin-15B" -O "2005-07-18_13:34:02_mt3" Person_evidence -O "2006-03-01_09:24:22_mt3" "WBPerson1761" -O "2006-03-01_09:24:22_mt3"
Description	 -O "2005-07-18_13:34:02_mt3" Recessive -O "2005-07-18_13:34:02_mt3"

Variation : "gu47" -O "2005-07-04_08:53:45_mt3"
Description	 -O "2005-07-18_13:34:02_mt3" Phenotype_remark -O "2005-07-18_13:34:02_mt3" "Reduced lin-48::gfp expression. Male: ME0, some males have abnormal tails. Hermaphrodite: wildtype alone, Muv in homozygotes with lin-15B" -O "2005-07-18_13:34:02_mt3" Person_evidence -O "2006-03-01_09:24:22_mt3" "WBPerson1761" -O "2006-03-01_09:24:22_mt3"
Description	 -O "2005-07-18_13:34:02_mt3" Recessive -O "2005-07-18_13:34:02_mt3"

Variation : "gu48" -O "2005-07-04_08:53:45_mt3"
Description	 -O "2005-07-18_13:34:02_mt3" Phenotype_remark -O "2005-07-18_13:34:02_mt3" "Reduced lin-48::gfp expression. Hermaphrodite: wildtype alone, Muv in homozygotes with lin-15B" -O "2005-07-18_13:34:02_mt3" Person_evidence -O "2006-03-01_09:24:22_mt3" "WBPerson1761" -O "2006-03-01_09:24:22_mt3"
Description	 -O "2005-07-18_13:34:02_mt3" Recessive -O "2005-07-18_13:34:02_mt3"

Variation : "h55" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2003-07-30_16:23:10_ck1" Loss_of_function -O "2003-07-30_16:23:10_ck1" Amorph -O "2003-07-30_16:23:10_ck1"

Variation : "h134" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2003-07-30_16:21:55_wormpub" Loss_of_function -O "2003-07-30_16:21:55_wormpub" Amorph -O "2003-07-30_16:21:55_wormpub"

Variation : "hc49" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2003-08-08_11:08:13_krb" Phenotype_remark -O "2003-08-08_11:08:13_krb" "Sterile, defective spermatocytes, defective major sperm protein assembly." -O "2003-08-08_11:08:13_krb" Person_evidence -O "2003-08-08_11:08:13_krb" "WBPerson438" -O "2003-08-08_11:08:13_krb"

Variation : "hc92" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2003-08-08_11:08:13_krb" Phenotype_remark -O "2003-08-08_11:08:13_krb" "Sterile, defective spermatocytes, defective major sperm protein assembly." -O "2003-08-08_11:08:13_krb" Person_evidence -O "2003-08-08_11:08:13_krb" "WBPerson438" -O "2003-08-08_11:08:13_krb"

Variation : "hc143" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2003-08-08_11:08:13_krb" Phenotype_remark -O "2003-08-08_11:08:13_krb" "Sterile, defective spermatocytes, defective major sperm protein assembly." -O "2003-08-08_11:08:13_krb" Person_evidence -O "2003-08-08_11:08:13_krb" "WBPerson438" -O "2003-08-08_11:08:13_krb"

Variation : "hc163" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2003-08-08_11:10:07_krb" Phenotype_remark -O "2003-08-08_11:10:07_krb" "Suppress self-sterile phenotype of spermiogenesis initiation mutants, spe-8, spe-12, spe-27, spe-29\; partially fertile\; precocious spermiogenesis initiation." -O "2003-08-08_11:10:07_krb" Person_evidence -O "2003-08-08_11:10:07_krb" "WBPerson438" -O "2003-08-08_11:10:07_krb"

Variation : "hc164" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2003-08-08_11:10:07_krb" Phenotype_remark -O "2003-08-08_11:10:07_krb" "Suppress self-sterile phenotype of spermiogenesis initiation mutants, spe-8, spe-12, spe-27, spe-29\; partially fertile\; precocious spermiogenesis initiation." -O "2003-08-08_11:10:07_krb" Person_evidence -O "2003-08-08_11:10:07_krb" "WBPerson438" -O "2003-08-08_11:10:07_krb"

Variation : "hc165" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2003-08-08_11:10:07_krb" Phenotype_remark -O "2003-08-08_11:10:07_krb" "Suppress self-sterile phenotype of spermiogenesis initiation mutants, spe-8, spe-12, spe-27, spe-29\; partially fertile\; precocious spermiogenesis initiation." -O "2003-08-08_11:10:07_krb" Person_evidence -O "2003-08-08_11:10:07_krb" "WBPerson438" -O "2003-08-08_11:10:07_krb"

Variation : "hc166" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2003-08-08_11:10:07_krb" Phenotype_remark -O "2003-08-08_11:10:07_krb" "Suppress self-sterile phenotype of spermiogenesis initiation mutants, spe-8, spe-12, spe-27, spe-29\; partially fertile\; precocious spermiogenesis initiation." -O "2003-08-08_11:10:07_krb" Person_evidence -O "2003-08-08_11:10:07_krb" "WBPerson438" -O "2003-08-08_11:10:07_krb"

Variation : "hc167" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2003-08-08_11:10:07_krb" Phenotype_remark -O "2003-08-08_11:10:07_krb" "Suppress self-sterile phenotype of spermiogenesis initiation mutants, spe-8, spe-12, spe-27, spe-29\; partially fertile\; precocious spermiogenesis initiation." -O "2003-08-08_11:10:07_krb" Person_evidence -O "2003-08-08_11:10:07_krb" "WBPerson438" -O "2003-08-08_11:10:07_krb"

Variation : "hc168" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2003-08-08_11:10:07_krb" Phenotype_remark -O "2003-08-08_11:10:07_krb" "Suppress self-sterile phenotype of spermiogenesis initiation mutants, spe-8, spe-12, spe-27, spe-29\; partially fertile\; precocious spermiogenesis initiation." -O "2003-08-08_11:10:07_krb" Person_evidence -O "2003-08-08_11:10:07_krb" "WBPerson438" -O "2003-08-08_11:10:07_krb"

Variation : "hc169" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2003-08-08_11:10:07_krb" Phenotype_remark -O "2003-08-08_11:10:07_krb" "Suppress self-sterile phenotype of spermiogenesis initiation mutants, spe-8, spe-12, spe-27, spe-29\; partially fertile\; precocious spermiogenesis initiation." -O "2003-08-08_11:10:07_krb" Person_evidence -O "2003-08-08_11:10:07_krb" "WBPerson438" -O "2003-08-08_11:10:07_krb"

Variation : "hc170" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2005-08-18_15:05:18_ar2" Phenotype_remark -O "2003-08-08_11:10:07_krb" "Suppress self-sterile phenotype of spermiogenesis initiation mutants, spe-8, spe-12, spe-27, spe-29\; partially fertile\; precocious spermiogenesis initiation." -O "2003-08-08_11:10:07_krb" Person_evidence -O "2003-08-08_11:10:07_krb" "WBPerson438" -O "2003-08-08_11:10:07_krb"

Variation : "hc171" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2005-08-18_15:05:18_ar2" Phenotype_remark -O "2003-08-08_11:10:07_krb" "Suppress self-sterile phenotype of spermiogenesis initiation mutants, spe-8, spe-12, spe-27, spe-29\; partially fertile\; precocious spermiogenesis initiation." -O "2003-08-08_11:10:07_krb" Person_evidence -O "2003-08-08_11:10:07_krb" "WBPerson438" -O "2003-08-08_11:10:07_krb"

Variation : "hc172" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2003-08-08_11:10:07_krb" Phenotype_remark -O "2003-08-08_11:10:07_krb" "Suppress self-sterile phenotype of spermiogenesis initiation mutants, spe-8, spe-12, spe-27, spe-29\; partially fertile\; precocious spermiogenesis initiation." -O "2003-08-08_11:10:07_krb" Person_evidence -O "2003-08-08_11:10:07_krb" "WBPerson438" -O "2003-08-08_11:10:07_krb"

Variation : "hc173" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2003-08-08_11:10:07_krb" Phenotype_remark -O "2003-08-08_11:10:07_krb" "Suppress self-sterile phenotype of spermiogenesis initiation mutants, spe-8, spe-12, spe-27, spe-29\; partially fertile\; precocious spermiogenesis initiation." -O "2003-08-08_11:10:07_krb" Person_evidence -O "2003-08-08_11:10:07_krb" "WBPerson438" -O "2003-08-08_11:10:07_krb"

Variation : "hc174" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2003-08-08_11:10:07_krb" Phenotype_remark -O "2003-08-08_11:10:07_krb" "Suppress self-sterile phenotype of spermiogenesis initiation mutants, spe-8, spe-12, spe-27, spe-29\; partially fertile\; precocious spermiogenesis initiation." -O "2003-08-08_11:10:07_krb" Person_evidence -O "2003-08-08_11:10:07_krb" "WBPerson438" -O "2003-08-08_11:10:07_krb"

Variation : "hc175" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2003-08-08_11:10:07_krb" Phenotype_remark -O "2003-08-08_11:10:07_krb" "Suppress self-sterile phenotype of spermiogenesis initiation mutants, spe-8, spe-12, spe-27, spe-29\; partially fertile\; precocious spermiogenesis initiation." -O "2003-08-08_11:10:07_krb" Person_evidence -O "2003-08-08_11:10:07_krb" "WBPerson438" -O "2003-08-08_11:10:07_krb"

Variation : "hc176" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2003-08-08_11:10:07_krb" Phenotype_remark -O "2003-08-08_11:10:07_krb" "Suppress self-sterile phenotype of spermiogenesis initiation mutants, spe-8, spe-12, spe-27, spe-29\; partially fertile\; precocious spermiogenesis initiation." -O "2003-08-08_11:10:07_krb" Person_evidence -O "2003-08-08_11:10:07_krb" "WBPerson438" -O "2003-08-08_11:10:07_krb"

Variation : "hc186" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2003-08-08_11:10:07_krb" Phenotype_remark -O "2003-08-08_11:10:07_krb" "Suppress self-sterile phenotype of spermiogenesis initiation mutants, spe-8, spe-12, spe-27, spe-29\; partially fertile\; precocious spermiogenesis initiation." -O "2003-08-08_11:10:07_krb" Person_evidence -O "2003-08-08_11:10:07_krb" "WBPerson438" -O "2003-08-08_11:10:07_krb"

Variation : "hc187" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2003-08-08_11:10:07_krb" Phenotype_remark -O "2003-08-08_11:10:07_krb" "Suppress self-sterile phenotype of spermiogenesis initiation mutants, spe-8, spe-12, spe-27, spe-29\; partially fertile\; precocious spermiogenesis initiation." -O "2003-08-08_11:10:07_krb" Person_evidence -O "2003-08-08_11:10:07_krb" "WBPerson438" -O "2003-08-08_11:10:07_krb"

Variation : "hc188" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2003-08-08_11:10:07_krb" Phenotype_remark -O "2003-08-08_11:10:07_krb" "Suppress self-sterile phenotype of spermiogenesis initiation mutants, spe-8, spe-12, spe-27, spe-29\; partially fertile\; precocious spermiogenesis initiation." -O "2003-08-08_11:10:07_krb" Person_evidence -O "2003-08-08_11:10:07_krb" "WBPerson438" -O "2003-08-08_11:10:07_krb"

Variation : "hc189" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2003-08-08_11:10:07_krb" Phenotype_remark -O "2003-08-08_11:10:07_krb" "Suppress self-sterile phenotype of spermiogenesis initiation mutants, spe-8, spe-12, spe-27, spe-29\; partially fertile\; precocious spermiogenesis initiation." -O "2003-08-08_11:10:07_krb" Person_evidence -O "2003-08-08_11:10:07_krb" "WBPerson438" -O "2003-08-08_11:10:07_krb"

Variation : "hc190" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2005-08-18_15:05:18_ar2" Phenotype_remark -O "2003-08-08_11:10:07_krb" "Suppress self-sterile phenotype of spermiogenesis initiation mutants, spe-8, spe-12, spe-27, spe-29\; partially fertile\; precocious spermiogenesis initiation." -O "2003-08-08_11:10:07_krb" Person_evidence -O "2003-08-08_11:10:07_krb" "WBPerson438" -O "2003-08-08_11:10:07_krb"

Variation : "hp1" -O "2004-09-17_15:15:15_rem"
Description	 -O "2004-09-17_15:15:15_rem" Phenotype_remark -O "2004-09-17_15:15:15_rem" "fsn-1(hp1) animals are slightly shorter than WT. GABAergic synpases visualized with the juIs1 (GABAergic nervous system specific synaptobrevin::GFP) marker are irregularly shaped and sized in this strain. In WT animals, puncta are uniformly spaced and sized. fsn-1(hp1) puncta are clustered, irregularly shaped, and missing or diminished along the dorsal cord." -O "2004-09-17_15:15:15_rem" Person_evidence -O "2006-03-01_09:24:22_mt3" "WBPerson2312" -O "2006-03-01_09:24:22_mt3"
Description	 -O "2004-09-17_15:15:15_rem" Recessive -O "2004-09-17_15:15:15_rem"
Description	 -O "2004-09-17_15:15:15_rem" Completely_penetrant -O "2004-09-17_15:15:15_rem"

Variation : "ia03" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2005-09-15_17:07:58_td3" Loss_of_function -O "2005-09-15_17:07:58_td3"

Variation : "je5" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-08-10_15:15:33_krb" Dominant -O "2004-08-10_15:15:33_krb"

Variation : "je6" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-08-10_15:15:33_krb" Dominant -O "2004-08-10_15:15:33_krb"

Variation : "jf61" -O "2005-01-12_10:34:16_mt3"
Description	 -O "2005-08-18_15:05:18_ar2" Phenotype_remark -O "2005-01-12_10:34:16_mt3" "maternal effect embryonic lethal\; about 2\% of progeny hatch\; him" -O "2005-01-12_10:34:16_mt3" Paper_evidence -O "2006-02-28_13:54:04_mt3" "WBPaper00024249" -O "2006-02-28_13:54:04_mt3"

Variation : "jh107" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2003-06-18_14:24:02_krb" Gain_of_function -O "2003-06-18_14:24:02_krb"

Variation : "jh131" -O "2006-03-07_14:49:53_mt3"
Description	 -O "2006-03-07_14:49:53_mt3" Loss_of_function -O "2006-03-07_14:49:53_mt3" Uncharacterised_loss_of_function -O "2006-03-07_14:49:53_mt3" Paper_evidence -O "2006-03-07_14:49:53_mt3" "WBPaper00024456" -O "2006-03-07_14:49:53_mt3"

Variation : "js379" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2003-04-28_09:52:20_ck1" Phenotype_remark -O "2003-04-28_09:52:20_ck1" "Jerky locomotion. Sensitive to aldicarb" -O "2003-04-28_09:52:20_ck1" CGC_data_submission -O "2003-04-28_09:52:20_ck1"

Variation : "ju44" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2003-05-21_16:12:52_ck1" Temperature_sensitive -O "2003-05-21_16:12:52_ck1" Heat_sensitive -O "2003-05-21_16:12:52_ck1"

Variation : "ju53" -O "2004-04-07_11:23:34_wormpub"

Variation : "ju67" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2003-06-11_14:43:45_ck1" Loss_of_function -O "2003-06-11_14:43:45_ck1" Amorph -O "2003-06-11_14:43:45_ck1"

Variation : "ju156" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2003-06-24_14:50:53_ck1" Phenotype_remark -O "2003-06-24_14:50:53_ck1" "unc and axon guidance defect" -O "2003-06-24_14:50:53_ck1" Paper_evidence -O "2006-03-01_09:24:22_mt3" "WBPaper00005955" -O "2006-03-01_09:24:22_mt3"
Description	 -O "2003-06-24_14:50:53_ck1" Recessive -O "2003-06-24_14:50:53_ck1"
Description	 -O "2003-06-24_14:50:53_ck1" Completely_penetrant -O "2003-06-24_14:50:53_ck1"
Description	 -O "2003-06-24_14:50:53_ck1" Loss_of_function -O "2003-06-24_14:50:53_ck1" Amorph -O "2003-06-24_14:50:53_ck1"

Variation : "ks38" -O "2004-07-22_11:17:44_rem"
Description	 -O "2005-08-18_15:05:18_ar2" Phenotype_remark -O "2004-07-22_11:17:44_rem" "fairly active, slightly dumpy" -O "2004-07-22_11:17:44_rem" Paper_evidence -O "2006-02-28_13:54:04_mt3" "WBPaper00002050" -O "2006-02-28_13:54:04_mt3"

Variation : "ks49" -O "2004-07-22_11:17:44_rem"
Description	 -O "2004-07-22_11:17:44_rem" Phenotype_remark -O "2004-07-22_11:17:44_rem" "reduced movement, defective egg-laying and slightly dumpy" -O "2004-07-22_11:17:44_rem" Paper_evidence -O "2006-02-28_13:54:04_mt3" "WBPaper00002050" -O "2006-02-28_13:54:04_mt3"

Variation : "ku119" -O "2004-05-25_14:04:51_CGC_strain_update"
Description	 -O "2005-07-14_13:19:23_td3" Recessive -O "2005-07-14_13:19:23_td3"

Variation : "ky51" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2001-04-04_14:05:58_sylvia" Recessive -O "2004-07-26_15:28:05_krb"

Variation : "ky346" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2003-05-21_16:12:52_ck1" Temperature_sensitive -O "2003-05-21_16:12:52_ck1" Heat_sensitive -O "2003-05-21_16:12:52_ck1" "" -O "2006-02-09_09:32:38_mt3" Paper_evidence -O "2006-02-09_09:32:38_mt3" "WBPaper00004146" -O "2006-02-09_09:32:38_mt3"

Variation : "lg601" -O "2005-07-20_10:30:13_wormpub"
Description	 -O "2005-07-20_10:30:13_wormpub" Recessive -O "2005-07-20_10:30:13_wormpub"

Variation : "lj1" -O "2005-12-08_13:42:05_mt3"
Description	 -O "2005-12-08_13:42:05_mt3" Recessive -O "2005-12-08_13:42:05_mt3"
Description	 -O "2005-12-08_13:42:05_mt3" Completely_penetrant -O "2005-12-08_13:42:05_mt3"
Description	 -O "2005-12-08_13:42:05_mt3" Loss_of_function -O "2005-12-08_13:42:05_mt3" Amorph -O "2005-12-08_13:42:05_mt3" Person_evidence -O "2005-12-08_13:42:05_mt3" "WBPerson554" -O "2005-12-08_13:42:05_mt3"
Description	 -O "2005-12-08_13:42:05_mt3" Phenotype_remark -O "2005-12-08_13:42:05_mt3" "Unc, Egl-c" -O "2005-12-08_13:42:05_mt3" Person_evidence -O "2005-12-08_13:42:05_mt3" "WBPerson554" -O "2005-12-08_13:42:05_mt3"

Variation : "lq17" -O "2005-12-07_15:37:16_mt3"
Description	 -O "2005-12-07_15:37:16_mt3" Loss_of_function -O "2005-12-07_15:37:16_mt3" Hypomorph -O "2005-12-07_15:37:16_mt3" Paper_evidence -O "2005-12-07_15:37:16_mt3" "WBPaper00026842" -O "2005-12-07_15:37:16_mt3"

Variation : "mc1" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-03-24_10:17:33_ck1" Loss_of_function -O "2004-03-24_10:17:33_ck1"

Variation : "mc2" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "1999-09-09_11:20:52_sylvia" Phenotype_remark -O "1999-09-09_11:20:52_sylvia" "mild loss-of-function,embryonic lethal." -O "1999-09-09_11:20:52_sylvia" Paper_evidence -O "2006-02-28_13:54:04_mt3" "WBPaper00002025" -O "2006-02-28_13:54:04_mt3"

Variation : "mc4" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "1999-09-09_11:20:52_sylvia" Phenotype_remark -O "1999-09-09_11:20:52_sylvia" "strong loss-of-function. embryonic lethal." -O "1999-09-09_11:20:52_sylvia" Paper_evidence -O "2006-02-28_13:54:04_mt3" "WBPaper00002025" -O "2006-02-28_13:54:04_mt3"
Description	 -O "1999-09-09_11:20:52_sylvia" Loss_of_function -O "2004-03-24_10:17:33_ck1"

Variation : "mc14" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "1999-09-09_11:20:52_sylvia" Recessive -O "1999-09-09_11:20:52_sylvia"

Variation : "mc16" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-03-24_10:17:33_ck1" Recessive -O "2004-03-24_10:17:33_ck1"

Variation : "mc35" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-03-24_10:17:33_ck1" Recessive -O "2004-03-24_10:17:33_ck1"

Variation : "mg312" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2003-04-16_12:02:16_ck1" Recessive -O "2003-04-16_12:02:16_ck1"

Variation : "mg366" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-03-29_10:14:26_ck1" Phenotype_remark -O "2004-03-29_10:14:26_ck1" "enhanced RNAi" -O "2004-03-29_10:14:26_ck1" Person_evidence -O "2006-03-01_09:24:22_mt3" "WBPerson315" -O "2006-03-01_09:24:22_mt3"
Description	 -O "2004-03-29_10:14:26_ck1" Recessive -O "2004-03-29_10:14:26_ck1"
Description	 -O "2004-03-29_10:14:26_ck1" Partially_penetrant -O "2004-03-29_10:14:26_ck1"
Description	 -O "2004-03-29_10:14:26_ck1" Loss_of_function -O "2004-03-29_10:14:26_ck1" Uncharacterised_loss_of_function -O "2004-03-29_10:14:26_ck1"

Variation : "mg388" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-03-29_11:15:37_ck1" Recessive -O "2004-03-29_11:15:37_ck1"
Description	 -O "2004-03-29_11:15:37_ck1" Loss_of_function -O "2004-03-29_11:15:37_ck1" Uncharacterised_loss_of_function -O "2004-03-29_11:15:37_ck1"

Variation : "mu27" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-06-22_11:46:17_krb" Semi_dominant -O "2004-06-22_11:46:17_krb"

Variation : "mu74" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2005-12-08_10:15:19_mt3" Phenotype_remark -O "2005-12-08_10:15:19_mt3" "Unc, Egl-c" -O "2005-12-08_10:15:19_mt3" Person_evidence -O "2006-03-01_09:24:22_mt3" "WBPerson554" -O "2006-03-01_09:24:22_mt3"
Description	 -O "2005-12-08_10:15:19_mt3" Recessive -O "2005-12-08_10:15:19_mt3"
Description	 -O "2005-12-08_10:15:19_mt3" Completely_penetrant -O "2005-12-08_10:15:19_mt3"
Description	 -O "2005-12-08_10:15:19_mt3" Loss_of_function -O "2005-12-08_10:15:19_mt3" Amorph -O "2005-12-08_10:15:19_mt3" Person_evidence -O "2005-12-08_10:15:19_mt3" "WBPerson554" -O "2005-12-08_10:15:19_mt3"

Variation : "mu220" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2001-06-06_13:47:19_sylvia" Recessive -O "2003-04-11_10:41:34_ck1"

Variation : "n152" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-01-27_15:34:27_ck1" Recessive -O "2004-01-27_15:34:27_ck1"

Variation : "n180" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-03-29_14:27:06_ck1" Loss_of_function -O "2004-03-29_15:29:27_ck1"

Variation : "n186" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-03-03_09:41:16_ck1" Loss_of_function -O "2004-03-29_15:24:52_ck1"

Variation : "n189" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-03-03_09:41:16_ck1" Loss_of_function -O "2004-03-29_15:24:52_ck1"

Variation : "n190" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-03-03_09:41:16_ck1" Loss_of_function -O "2004-03-29_15:24:52_ck1"

Variation : "n191" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-03-03_09:41:16_ck1" Loss_of_function -O "2004-03-29_15:24:52_ck1"

Variation : "n223" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-03-03_09:41:16_ck1" Loss_of_function -O "2004-03-29_15:24:52_ck1"

Variation : "n233" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-03-03_09:41:16_ck1" Loss_of_function -O "2004-03-29_15:24:52_ck1"

Variation : "n240" -O "2004-04-07_11:23:34_wormpub"

Variation : "n241" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-03-29_14:27:06_ck1" Loss_of_function -O "2004-03-29_15:29:27_ck1"

Variation : "n264" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-03-03_09:41:16_ck1" Loss_of_function -O "2004-03-29_15:24:52_ck1"

Variation : "n266" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-03-03_09:41:16_ck1" Loss_of_function -O "2004-03-29_15:24:52_ck1"

Variation : "n271" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-03-29_15:04:39_wormpub" Loss_of_function -O "2004-03-29_15:29:27_ck1"

Variation : "n345" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-03-03_09:41:16_ck1" Loss_of_function -O "2004-03-29_15:24:52_ck1"

Variation : "n508" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-03-03_09:41:16_ck1" Loss_of_function -O "2004-03-29_15:24:52_ck1"

Variation : "n659" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-03-29_14:27:06_ck1" Loss_of_function -O "2004-03-29_15:29:27_ck1"

Variation : "n668" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-03-03_09:41:16_ck1" Loss_of_function -O "2004-03-29_15:24:52_ck1"

Variation : "n1009" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-03-03_09:41:16_ck1" Loss_of_function -O "2004-03-29_15:24:52_ck1"

Variation : "n1012" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-03-03_09:41:16_ck1" Loss_of_function -O "2004-03-29_15:24:52_ck1"

Variation : "n1016" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-03-03_09:41:16_ck1" Loss_of_function -O "2004-03-29_15:24:52_ck1"

Variation : "n1017" -O "2004-04-07_11:23:34_wormpub"

Variation : "n1020" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-03-03_09:41:16_ck1" Loss_of_function -O "2004-03-29_15:24:52_ck1"

Variation : "n1023" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-03-03_09:41:16_ck1" Loss_of_function -O "2004-03-29_15:24:52_ck1"

Variation : "n1025" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-03-03_09:41:16_ck1" Loss_of_function -O "2004-03-29_15:24:52_ck1"

Variation : "n1026" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-03-29_15:04:39_wormpub" Loss_of_function -O "2004-03-29_15:29:27_ck1"

Variation : "n1028" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-03-29_14:27:06_ck1" Loss_of_function -O "2004-03-29_15:29:27_ck1"

Variation : "n1037" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-03-03_09:41:16_ck1" Loss_of_function -O "2004-03-29_15:24:52_ck1"

Variation : "n1069" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2005-07-22_13:57:38_mt3" Phenotype_remark -O "2005-07-22_13:57:38_mt3" "Causes significant masculinization of hermaphrodites.  Causes increased lin-12 signaling." -O "2005-07-22_13:57:38_mt3" Paper_evidence -O "2006-02-28_13:54:04_mt3" "WBPaper00024442" -O "2006-02-28_13:54:04_mt3"
Description	 -O "2005-07-22_13:57:38_mt3" Semi_dominant -O "2005-07-22_13:57:38_mt3"
Description	 -O "2005-07-22_13:57:38_mt3" Temperature_sensitive -O "2005-07-22_13:57:38_mt3" Cold_sensitive -O "2005-07-22_13:57:38_mt3" "Fully-penetrant Egl as homozygote at 15C or 20C but partially penetrant at 25C" -O "2005-07-22_13:57:38_mt3"

Variation : "n1074" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2005-07-22_13:57:38_mt3" Phenotype_remark -O "2005-07-22_13:57:38_mt3" "Causes significant masculinization of hermaphrodites.  Causes increased lin-12 signaling." -O "2005-07-22_13:57:38_mt3" Paper_evidence -O "2006-02-28_13:54:04_mt3" "WBPaper00024442" -O "2006-02-28_13:54:04_mt3"
Description	 -O "2005-07-22_13:57:38_mt3" Semi_dominant -O "2005-07-22_13:57:38_mt3"
Description	 -O "2005-07-22_13:57:38_mt3" Temperature_sensitive -O "2005-07-22_13:57:38_mt3" Cold_sensitive -O "2005-07-22_13:57:38_mt3" "fully-penetrant Egl as homozygote at 15C or 20C but   penetrant at 25C" -O "2005-07-22_13:57:38_mt3"

Variation : "n1077" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2005-07-22_13:57:38_mt3" Phenotype_remark -O "2005-07-22_13:57:38_mt3" "Causes significant masculinization of hermaphrodites.  Causes increased lin-12 signaling." -O "2005-07-22_13:57:38_mt3" Paper_evidence -O "2006-03-01_09:24:22_mt3" "WBPaper00024442" -O "2006-03-01_09:24:22_mt3"
Description	 -O "2005-07-22_13:57:38_mt3" Semi_dominant -O "2005-07-22_13:57:38_mt3"
Description	 -O "2005-07-22_13:57:38_mt3" Temperature_sensitive -O "2005-07-22_13:57:38_mt3" Cold_sensitive -O "2005-07-22_13:57:38_mt3" "Fully-penetrant Egl as homozygote at 15C or 20C but partially penetrant at 25C" -O "2005-07-22_13:57:38_mt3" Paper_evidence -O "2006-02-28_13:54:04_mt3" "WBPaper00024442" -O "2006-02-28_13:54:04_mt3"

Variation : "n1324" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-03-25_16:58:25_ck1" Phenotype_remark -O "2004-03-25_16:58:25_ck1" "shrinker Unc" -O "2004-03-25_16:58:25_ck1" Person_evidence -O "2006-03-01_10:50:27_mt3" "WBPerson39" -O "2006-03-01_10:50:27_mt3"
Description	 -O "2004-03-25_16:58:25_ck1" Recessive -O "2004-03-25_16:58:25_ck1"
Description	 -O "2004-03-25_16:58:25_ck1" Completely_penetrant -O "2004-03-25_16:58:25_ck1"
Description	 -O "2004-03-25_16:58:25_ck1" Loss_of_function -O "2004-03-25_16:58:25_ck1" Amorph -O "2004-03-25_16:58:25_ck1"

Variation : "n1428" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-03-29_15:21:25_ck1" Loss_of_function -O "2004-03-29_15:24:52_ck1"

Variation : "n1550" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-03-29_15:40:09_ck1" Gain_of_function -O "2004-03-29_15:40:58_ck1"

Variation : "n1553" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-03-29_15:04:39_wormpub" Loss_of_function -O "2004-03-29_15:29:27_ck1"

Variation : "n1606" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-08-18_08:15:53_krb" Phenotype_remark -O "2004-08-18_08:15:53_krb" "semidominant osmotic avoidance defective, FITC fill normal\" - but you might want to check this with Jim Thomas (who wrote the entry) or with Mark Audeh and Stephen Wicks (who recently reported the cloning of osm-12 in a meeting abstract" -O "2004-08-18_08:15:53_krb" Paper_evidence -O "2004-08-18_08:15:53_krb" "WBPaper00019165" -O "2004-08-18_08:15:53_krb"

Variation : "n1813" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-08-20_09:09:35_krb" Recessive -O "2004-08-20_09:09:35_krb"
Description	 -O "2004-08-20_09:09:35_krb" Completely_penetrant -O "2004-08-20_09:09:35_krb"
Description	 -O "2004-08-20_09:09:35_krb" Temperature_sensitive -O "2004-08-20_09:09:35_krb" Heat_sensitive -O "2004-08-20_09:09:35_krb" "slightly weaker phenotype at 15C" -O "2004-08-20_09:09:35_krb" Person_evidence -O "2004-08-20_09:09:35_krb" "WBPerson250" -O "2004-08-20_09:09:35_krb"

Variation : "n1913" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-03-29_15:21:25_ck1" Loss_of_function -O "2004-03-29_15:24:52_ck1"

Variation : "n1914" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-03-29_15:24:52_ck1" Loss_of_function -O "2004-03-29_15:24:52_ck1"

Variation : "n2174" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-03-29_15:04:39_wormpub" Loss_of_function -O "2004-03-29_15:29:27_ck1"

Variation : "n2175" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-03-29_15:04:39_wormpub" Loss_of_function -O "2004-03-29_15:29:27_ck1"

Variation : "n2259" -O "2004-12-16_16:55:29_wormpub"
Description	 -O "2004-12-16_16:55:29_wormpub" Recessive -O "2004-12-16_16:55:44_mt3"
Description	 -O "2004-12-16_16:55:29_wormpub" Completely_penetrant -O "2004-12-16_16:55:44_mt3"

Variation : "n2279" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-03-29_15:04:39_wormpub" Loss_of_function -O "2004-03-29_15:29:27_ck1"

Variation : "n2282" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-03-02_14:05:23_ck1" Loss_of_function -O "2004-03-29_15:24:52_ck1"

Variation : "n2284" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-03-29_15:24:52_ck1" Loss_of_function -O "2004-03-29_15:24:52_ck1"

Variation : "n2285" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-03-29_15:04:39_wormpub" Loss_of_function -O "2004-03-29_15:29:27_ck1"

Variation : "n2287" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-03-29_15:24:52_ck1" Loss_of_function -O "2004-03-29_15:24:52_ck1"

Variation : "n2288" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-03-29_15:56:01_ck1" Loss_of_function -O "2004-03-29_15:56:01_ck1" Hypomorph -O "2004-03-29_15:56:01_ck1"

Variation : "n2359" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-03-29_15:56:01_ck1" Loss_of_function -O "2004-03-29_15:56:01_ck1" Hypomorph -O "2004-03-29_15:56:01_ck1"

Variation : "n2392" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-03-25_17:01:05_ck1" Phenotype_remark -O "2004-03-25_17:01:05_ck1" "shrinker Unc" -O "2004-03-25_17:01:05_ck1" Person_evidence -O "2006-03-01_09:24:22_mt3" "WBPerson39" -O "2006-03-01_09:24:22_mt3"
Description	 -O "2004-03-25_17:01:05_ck1" Recessive -O "2004-03-25_17:01:05_ck1"
Description	 -O "2004-03-25_17:01:05_ck1" Completely_penetrant -O "2004-03-25_17:01:05_ck1"
Description	 -O "2004-03-25_17:01:05_ck1" Loss_of_function -O "2004-03-25_17:01:05_ck1" Amorph -O "2004-03-25_17:01:05_ck1"

Variation : "n2728" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2003-08-18_11:05:30_krb" Phenotype_remark -O "2003-08-18_11:05:30_krb" "synMuv class A" -O "2003-08-18_11:05:30_krb" Paper_evidence -O "2006-03-01_09:24:22_mt3" "WBPaper00005861" -O "2006-03-01_09:24:22_mt3"
Description	 -O "2003-08-18_11:05:30_krb" Recessive -O "2003-08-18_11:05:30_krb"
Description	 -O "2003-08-18_11:05:30_krb" Completely_penetrant -O "2003-08-18_11:05:30_krb"
Description	 -O "2003-08-18_11:05:30_krb" Loss_of_function -O "2003-08-18_11:05:30_krb" Uncharacterised_loss_of_function -O "2003-08-18_11:05:30_krb"

Variation : "n2948" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-03-25_16:58:25_ck1" Phenotype_remark -O "2004-03-25_16:58:25_ck1" "Serotonin- and dopamine-deficient, although low levels of serotonin immunoreactivity seen (possibly not genuine serotonin)" -O "2004-03-25_16:58:25_ck1" Paper_evidence -O "2006-03-01_09:24:22_mt3" "WBPaper00004195" -O "2006-03-01_09:24:22_mt3"
Description	 -O "2004-03-25_16:58:25_ck1" Recessive -O "2004-03-25_16:58:25_ck1"
Description	 -O "2004-03-25_16:58:25_ck1" Completely_penetrant -O "2004-03-25_16:58:25_ck1"
Description	 -O "2004-03-25_16:58:25_ck1" Loss_of_function -O "2004-03-25_16:58:25_ck1" Amorph -O "2004-03-25_16:58:25_ck1"

Variation : "n2990" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2003-08-18_11:05:30_krb" Phenotype_remark -O "2003-08-18_11:05:30_krb" "synMuv class B." -O "2003-08-18_11:05:30_krb" Paper_evidence -O "2006-03-01_09:24:22_mt3" "WBPaper00005861" -O "2006-03-01_09:24:22_mt3"
Description	 -O "2003-08-18_11:05:30_krb" Recessive -O "2003-08-18_11:05:30_krb"
Description	 -O "2003-08-18_11:05:30_krb" Partially_penetrant -O "2003-08-18_11:05:30_krb"
Description	 -O "2003-08-18_11:05:30_krb" Temperature_sensitive -O "2003-08-18_11:05:30_krb" Heat_sensitive -O "2003-08-18_11:05:30_krb"
Description	 -O "2003-08-18_11:05:30_krb" Loss_of_function -O "2003-08-18_11:05:30_krb" Uncharacterised_loss_of_function -O "2003-08-18_11:05:30_krb"

Variation : "n3008" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-03-25_16:58:25_ck1" Phenotype_remark -O "2004-03-25_16:58:25_ck1" "Serotonin- and dopamine-deficient, although low levels of serotonin immunoreactivity seen (possibly not genuine serotonin)" -O "2004-03-25_16:58:25_ck1" Paper_evidence -O "2006-03-01_09:24:22_mt3" "WBPaper00004195" -O "2006-03-01_09:24:22_mt3"
Description	 -O "2004-03-25_16:58:25_ck1" Recessive -O "2004-03-25_16:58:25_ck1"
Description	 -O "2004-03-25_16:58:25_ck1" Completely_penetrant -O "2004-03-25_16:58:25_ck1"
Description	 -O "2004-03-25_16:58:25_ck1" Loss_of_function -O "2004-03-25_16:58:25_ck1" Amorph -O "2004-03-25_16:58:25_ck1"

Variation : "n3310" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-03-29_15:51:09_ck1" Gain_of_function -O "2004-03-29_15:51:09_ck1"

Variation : "n3599" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2003-08-08_10:02:09_krb" Phenotype_remark -O "2003-08-08_10:02:09_krb" "Causes selected transgenes to ectopically express in the pharynx." -O "2003-08-08_10:02:09_krb" Curator_confirmed -O "2006-03-01_09:24:22_mt3" "WBPerson1971" -O "2006-03-01_09:24:22_mt3"
Description	 -O "2003-08-08_10:02:09_krb" Recessive -O "2003-08-08_10:02:09_krb"
Description	 -O "2003-08-08_10:02:09_krb" Completely_penetrant -O "2003-08-08_10:02:09_krb"
Description	 -O "2003-08-08_10:02:09_krb" Gain_of_function -O "2003-08-08_10:02:09_krb" Neomorph -O "2003-08-08_10:02:09_krb"

Variation : "n3713" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2003-08-14_09:05:05_krb" Phenotype_remark -O "2003-08-14_09:05:05_krb" "Semidominantly causes CEM survival in hermaphrodites." -O "2003-08-14_09:05:05_krb" Curator_confirmed -O "2006-03-01_09:24:22_mt3" "WBPerson1971" -O "2006-03-01_09:24:22_mt3"
Description	 -O "2003-08-14_09:05:05_krb" Semi_dominant -O "2003-08-14_09:05:05_krb"
Description	 -O "2003-08-14_09:05:05_krb" Gain_of_function -O "2003-08-14_09:05:05_krb" Uncharacterised_gain_of_function -O "2003-08-14_09:05:05_krb"

Variation : "n3714" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2003-08-14_09:05:05_krb" Phenotype_remark -O "2003-08-14_09:05:05_krb" "Semidominantly causes CEM survival in hermaphrodites." -O "2003-08-14_09:05:05_krb" Curator_confirmed -O "2006-03-01_09:24:22_mt3" "WBPerson1971" -O "2006-03-01_09:24:22_mt3"
Description	 -O "2003-08-14_09:05:05_krb" Semi_dominant -O "2003-08-14_09:05:05_krb"
Description	 -O "2003-08-14_09:05:05_krb" Gain_of_function -O "2003-08-14_09:05:05_krb" Uncharacterised_gain_of_function -O "2003-08-14_09:05:05_krb"

Variation : "n3717" -O "2005-07-22_13:57:38_mt3"
Description	 -O "2005-07-22_13:57:38_mt3" Phenotype_remark -O "2005-07-22_13:57:38_mt3" "Causes significant masculinization of hermaphrodites.  Causes increased lin-12 signaling." -O "2005-07-22_13:57:38_mt3" Paper_evidence -O "2006-03-01_09:24:22_mt3" "WBPaper00024442" -O "2006-03-01_09:24:22_mt3"
Description	 -O "2005-07-22_13:57:38_mt3" Semi_dominant -O "2005-07-22_13:57:38_mt3"
Description	 -O "2005-07-22_13:57:38_mt3" Temperature_sensitive -O "2005-07-22_13:57:38_mt3" Cold_sensitive -O "2005-07-22_13:57:38_mt3" "Fully-penetrant Egl as homozygote at 15C or 20C but partially penetrant at 25C" -O "2005-07-22_13:57:38_mt3" Paper_evidence -O "2006-02-28_13:54:04_mt3" "WBPaper00024442" -O "2006-02-28_13:54:04_mt3"

Variation : "n3720" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2003-08-14_09:05:05_krb" Phenotype_remark -O "2003-08-14_09:05:05_krb" "Semidominantly causes CEM survival in hermaphrodites." -O "2003-08-14_09:05:05_krb" Curator_confirmed -O "2006-03-01_09:24:22_mt3" "WBPerson1971" -O "2006-03-01_09:24:22_mt3"
Description	 -O "2003-08-14_09:05:05_krb" Semi_dominant -O "2003-08-14_09:05:05_krb"
Description	 -O "2003-08-14_09:05:05_krb" Gain_of_function -O "2003-08-14_09:05:05_krb" Uncharacterised_gain_of_function -O "2003-08-14_09:05:05_krb"

Variation : "n3786" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2003-08-08_10:02:09_krb" Recessive -O "2003-08-08_10:02:09_krb"
Description	 -O "2003-08-08_10:02:09_krb" Completely_penetrant -O "2003-08-08_10:02:09_krb"
Description	 -O "2003-08-08_10:02:09_krb" Loss_of_function -O "2003-08-08_10:02:09_krb" Uncharacterised_loss_of_function -O "2003-08-08_10:02:09_krb"

Variation : "n3854" -O "2005-07-22_13:57:38_mt3"
Description	 -O "2005-07-22_13:57:38_mt3" Phenotype_remark -O "2005-07-22_13:57:38_mt3" "Causes significant masculinization of hermaphrodites.  Causes increased lin-12 signaling." -O "2005-07-22_13:57:38_mt3" Paper_evidence -O "2006-03-01_09:24:22_mt3" "WBPaper00024442" -O "2006-03-01_09:24:22_mt3"
Description	 -O "2005-07-22_13:57:38_mt3" Semi_dominant -O "2005-07-22_13:57:38_mt3"
Description	 -O "2005-07-22_13:57:38_mt3" Temperature_sensitive -O "2005-07-22_13:57:38_mt3" Cold_sensitive -O "2005-07-22_13:57:38_mt3" "Fully-penetrant Egl as homozygote at 15C or 20C but partially penetrant at 25C" -O "2005-07-22_13:57:38_mt3" Paper_evidence -O "2006-02-28_13:54:04_mt3" "WBPaper00024442" -O "2006-02-28_13:54:04_mt3"

Variation : "n4041" -O "2005-07-22_13:57:38_mt3"
Description	 -O "2005-07-22_13:57:38_mt3" Phenotype_remark -O "2005-07-22_13:57:38_mt3" "Causes significant masculinization of hermaphrodites.  Causes increased lin-12 signaling." -O "2005-07-22_13:57:38_mt3" Paper_evidence -O "2006-03-01_09:24:22_mt3" "WBPaper00024442" -O "2006-03-01_09:24:22_mt3"
Description	 -O "2005-07-22_13:57:38_mt3" Semi_dominant -O "2005-07-22_13:57:38_mt3"
Description	 -O "2005-07-22_13:57:38_mt3" Temperature_sensitive -O "2005-07-22_13:57:38_mt3" Cold_sensitive -O "2005-07-22_13:57:38_mt3" "Fully-penetrant Egl as homozygote at 15C or 20C but partially penetrant at 25C" -O "2005-07-22_13:57:38_mt3" Paper_evidence -O "2006-02-28_13:54:04_mt3" "WBPaper00024442" -O "2006-02-28_13:54:04_mt3"

Variation : "n4046" -O "2005-07-22_13:57:38_mt3"
Description	 -O "2005-07-22_13:57:38_mt3" Phenotype_remark -O "2005-07-22_13:57:38_mt3" "Causes significant masculinization of hermaphrodites.  Causes increased lin-12 signaling." -O "2005-07-22_13:57:38_mt3" Paper_evidence -O "2006-03-01_09:24:22_mt3" "WBPaper00024442" -O "2006-03-01_09:24:22_mt3"
Description	 -O "2005-07-22_13:57:38_mt3" Semi_dominant -O "2005-07-22_13:57:38_mt3"
Description	 -O "2005-07-22_13:57:38_mt3" Temperature_sensitive -O "2005-07-22_13:57:38_mt3" Cold_sensitive -O "2005-07-22_13:57:38_mt3" "Fully-penetrant Egl as homozygote at 15C or 20C but partially penetrant at 25C" -O "2005-07-22_13:57:38_mt3" Paper_evidence -O "2006-02-28_13:54:04_mt3" "WBPaper00024442" -O "2006-02-28_13:54:04_mt3"

Variation : "n4111" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2003-08-14_09:05:05_krb" Phenotype_remark -O "2003-08-14_09:05:05_krb" "Recessively causes CEM death in males." -O "2003-08-14_09:05:05_krb" Curator_confirmed -O "2006-03-01_09:24:22_mt3" "WBPerson1971" -O "2006-03-01_09:24:22_mt3"
Description	 -O "2003-08-14_09:05:05_krb" Recessive -O "2003-08-14_09:05:05_krb"
Description	 -O "2003-08-14_09:05:05_krb" Loss_of_function -O "2003-08-14_09:05:05_krb" Uncharacterised_loss_of_function -O "2003-08-14_09:05:05_krb"

Variation : "n4273" -O "2005-07-22_13:57:38_mt3"
Description	 -O "2005-07-22_13:57:38_mt3" Phenotype_remark -O "2005-07-22_13:57:38_mt3" "Causes extremely weak masculinization of hermaphrodites.  Causes increased lin-12 signaling." -O "2005-07-22_13:57:38_mt3" Paper_evidence -O "2006-02-28_13:54:04_mt3" "WBPaper00024442" -O "2006-02-28_13:54:04_mt3"
Description	 -O "2005-07-22_13:57:38_mt3" Recessive -O "2005-07-22_13:57:38_mt3"

Variation : "na48" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-01-07_13:51:46_ck1" Phenotype_remark -O "2004-01-07_13:51:46_ck1" "The Pro (proximal proliferation) is characterized by a mass of proliferating germ cells (or tumor) in the proximal part of the adult gonad.  Gametes form distal to the proximal tumor.  pro-1(na48) homozygotes are Pro at 25 degrees.  Other sterile phenotypes are observed at lower temperatures.  Slow growing at all temperatures.  DTC migration defects at all temperatures" -O "2004-01-07_13:51:46_ck1" Curator_confirmed -O "2006-03-01_09:24:22_mt3" "WBPerson1845" -O "2006-03-01_09:24:22_mt3"
Description	 -O "2004-01-07_13:51:46_ck1" Recessive -O "2004-01-07_13:51:46_ck1"
Description	 -O "2004-01-07_13:51:46_ck1" Partially_penetrant -O "2004-01-07_13:51:46_ck1"
Description	 -O "2004-01-07_13:51:46_ck1" Temperature_sensitive -O "2004-01-07_13:51:46_ck1" Cold_sensitive -O "2004-01-07_13:51:46_ck1"
Description	 -O "2004-01-07_13:51:46_ck1" Loss_of_function -O "2004-01-07_13:51:46_ck1" Hypomorph -O "2004-01-07_13:51:46_ck1"

Variation : "np1" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-01-27_15:34:27_ck1" Recessive -O "2004-01-27_15:34:27_ck1"

Variation : "nr2033" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-01-27_15:34:27_ck1" Recessive -O "2004-01-27_15:34:27_ck1"
Description	 -O "2004-01-27_15:34:27_ck1" Loss_of_function -O "2004-01-27_15:34:27_ck1" Hypomorph -O "2004-01-27_15:34:27_ck1"

Variation : "ok193" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-03-24_10:17:33_ck1" Recessive -O "2004-03-24_10:17:33_ck1"

Variation : "ok265" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2003-07-29_17:17:31_ck1" Recessive -O "2003-07-29_17:17:31_ck1"
Description	 -O "2003-07-29_17:17:31_ck1" Completely_penetrant -O "2003-07-29_17:17:31_ck1"
Description	 -O "2003-07-29_17:17:31_ck1" Loss_of_function -O "2003-07-29_17:17:31_ck1" Uncharacterised_loss_of_function -O "2003-07-29_17:17:31_ck1"

Variation : "ok273" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-02-05_12:53:05_ck1" Phenotype_remark -O "2004-02-05_12:53:05_ck1" "animals are viable and fertile. nearly complete suppression of kal-1 induced branching phenotype in AIY interneurons. various axonal defects at the midline. presumptive molecular null allele" -O "2004-02-05_12:53:05_ck1" Person_evidence -O "2006-03-01_09:24:22_mt3" "WBPerson1705" -O "2006-03-01_09:24:22_mt3"
Description	 -O "2004-02-05_12:53:05_ck1" Recessive -O "2004-02-05_12:53:05_ck1"
Description	 -O "2004-02-05_12:53:05_ck1" Partially_penetrant -O "2004-02-05_12:53:05_ck1"
Description	 -O "2004-02-05_12:53:05_ck1" Loss_of_function -O "2004-02-05_12:53:05_ck1" Amorph -O "2004-02-05_12:53:05_ck1"

Variation : "ok370" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-08-18_08:15:53_krb" Loss_of_function -O "2004-08-18_08:15:53_krb" Amorph -O "2004-08-18_08:15:53_krb" Paper_evidence -O "2004-08-18_08:15:53_krb" "WBPaper00005833" -O "2004-08-18_08:15:53_krb"

Variation : "ok892" -O "2004-05-10_15:40:26_CGC_strain_update"
Description	 -O "2006-01-13_09:46:24_mt3" Completely_penetrant -O "2006-01-13_09:46:24_mt3"
Description	 -O "2006-01-13_09:46:24_mt3" Phenotype_remark -O "2006-01-13_09:46:24_mt3" "Loss of anti-horseradish peroxidase staining (Western blot)" -O "2006-01-13_09:46:24_mt3" Person_evidence -O "2006-01-13_09:46:24_mt3" "WBPerson2099" -O "2006-01-13_09:46:24_mt3"

Variation : "ok1493" -O "2005-04-20_11:16:53_mt3"
Description	 -O "2006-01-17_10:09:51_mt3" Loss_of_function -O "2006-01-17_10:09:51_mt3" Uncharacterised_loss_of_function -O "2006-01-17_10:09:51_mt3" Person_evidence -O "2006-01-17_10:09:51_mt3" "WBPerson4387" -O "2006-01-17_10:09:51_mt3"
Description	 -O "2006-01-17_10:09:51_mt3" Phenotype_remark -O "2006-01-17_10:09:51_mt3" "Diminished ability to incorporate C14 labeled propionate into protein." -O "2006-01-17_10:09:51_mt3" Person_evidence -O "2006-01-17_10:09:51_mt3" "WBPerson4387" -O "2006-01-17_10:09:51_mt3"

Variation : "ok1637" -O "2005-06-20_10:47:08_mt3"
Description	 -O "2006-01-17_10:34:19_mt3" Phenotype_remark -O "2006-01-17_10:34:19_mt3" "Diminished ability to incorporate C14 labeled propionate into protein." -O "2006-01-17_10:34:19_mt3" Person_evidence -O "2006-01-17_10:34:19_mt3" "WBPerson4387" -O "2006-01-17_10:34:19_mt3"

Variation : "or153" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-03-25_17:43:24_ck1" Partially_penetrant -O "2005-01-31_16:47:30_ar2"

Variation : "or195" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2005-03-08_16:17:11_mt3" Recessive -O "2005-03-08_16:17:11_mt3"

Variation : "os8" -O "2005-07-13_12:04:04_mt3"
Description	 -O "2005-07-13_12:04:04_mt3" Phenotype_remark -O "2005-07-13_12:04:04_mt3" "defect in asymmetric cell division of the T cell (Psa phenotype)" -O "2005-07-13_12:04:04_mt3" Person_evidence -O "2006-03-01_09:24:22_mt3" "WBPerson3204" -O "2006-03-01_09:24:22_mt3"
Description	 -O "2005-07-13_12:04:04_mt3" Recessive -O "2005-07-13_12:04:04_mt3"
Description	 -O "2005-07-13_12:04:04_mt3" Partially_penetrant -O "2005-07-13_12:04:04_mt3"
Description	 -O "2005-07-13_12:04:04_mt3" Loss_of_function -O "2005-07-13_12:04:04_mt3" Hypomorph -O "2005-07-13_12:04:04_mt3" Person_evidence -O "2006-03-01_09:24:22_mt3" "WBPerson3204" -O "2006-03-01_09:24:22_mt3"

Variation : "ot1" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-02-24_12:28:05_ck1" Phenotype_remark -O "2004-02-24_12:28:05_ck1" "axon outgrowth defects, no cell-cycle defects" -O "2004-02-24_12:28:05_ck1" Person_evidence -O "2006-03-01_09:24:22_mt3" "WBPerson260" -O "2006-03-01_09:24:22_mt3"
Description	 -O "2004-02-24_12:28:05_ck1" Recessive -O "2004-02-24_12:28:05_ck1"
Description	 -O "2004-02-24_12:28:05_ck1" Partially_penetrant -O "2004-02-24_12:28:05_ck1"
Description	 -O "2004-02-24_12:28:05_ck1" Loss_of_function -O "2004-02-24_12:28:05_ck1" Hypomorph -O "2004-02-24_12:28:05_ck1"

Variation : "ot16" -O "2004-05-11_10:10:24_ck1"
Description	 -O "2004-05-11_10:10:24_ck1" Phenotype_remark -O "2004-05-11_10:10:24_ck1" "hse-5(ot16) suppresses the branching phenotype of KAL-1 overexpression in AIY. Also axon guidance defects at the midline" -O "2004-05-11_10:10:24_ck1" Person_evidence -O "2006-03-01_09:24:22_mt3" "WBPerson1705" -O "2006-03-01_09:24:22_mt3"
Description	 -O "2004-05-11_10:10:24_ck1" Recessive -O "2004-05-11_10:10:24_ck1"

Variation : "ot17" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-02-05_12:53:05_ck1" Phenotype_remark -O "2004-02-05_12:53:05_ck1" "animals are viable and fertile. nearly complete suppression of kal-1 induced branching phenotype in AIY interneurons. various axonal defects at the ventral midline" -O "2004-02-05_12:53:05_ck1" Paper_evidence -O "2006-02-28_13:54:04_mt3" "WBPaper00005236" -O "2006-02-28_13:54:04_mt3"
Description	 -O "2004-02-05_12:53:05_ck1" Recessive -O "2004-02-05_12:53:05_ck1"
Description	 -O "2004-02-05_12:53:05_ck1" Loss_of_function -O "2004-02-05_12:53:05_ck1" Amorph -O "2004-02-05_12:53:05_ck1"

Variation : "ot19" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-02-05_12:53:05_ck1" Phenotype_remark -O "2004-02-05_12:53:05_ck1" "animals are viable and fertile. nearly complete suppression of kal-1 induced branching phenotype in AIY interneurons. various axonal defects at the ventral midline" -O "2004-02-05_12:53:05_ck1" Paper_evidence -O "2006-02-28_13:54:04_mt3" "WBPaper00005236" -O "2006-02-28_13:54:04_mt3"
Description	 -O "2004-02-05_12:53:05_ck1" Recessive -O "2004-02-05_12:53:05_ck1"
Description	 -O "2004-02-05_12:53:05_ck1" Partially_penetrant -O "2004-02-05_12:53:05_ck1"
Description	 -O "2004-02-05_12:53:05_ck1" Loss_of_function -O "2004-02-05_12:53:05_ck1" Uncharacterised_loss_of_function -O "2004-02-05_12:53:05_ck1"

Variation : "ox10" -O "2004-05-12_10:10:56_ck1"
Description	 -O "2004-05-12_10:10:56_ck1" Phenotype_remark -O "2004-05-12_10:10:56_ck1" "pBoc defective" -O "2004-05-12_10:10:56_ck1" Person_evidence -O "2006-03-01_10:50:27_mt3" "WBPerson3792" -O "2006-03-01_10:50:27_mt3"
Description	 -O "2004-05-12_10:10:56_ck1" Recessive -O "2004-05-12_10:10:56_ck1"

Variation : "ox152" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-03-31_10:25:52_ck1" Phenotype_remark -O "2004-03-31_10:25:52_ck1" "dpy" -O "2004-03-31_10:25:52_ck1" Person_evidence -O "2006-03-01_10:50:27_mt3" "WBPerson692" -O "2006-03-01_10:50:27_mt3"
Description	 -O "2004-03-31_10:25:52_ck1" Recessive -O "2004-03-31_10:25:52_ck1"
Description	 -O "2004-03-31_10:25:52_ck1" Completely_penetrant -O "2004-03-31_10:25:52_ck1"
Description	 -O "2004-03-31_10:25:52_ck1" Loss_of_function -O "2004-03-31_10:25:52_ck1" Hypomorph -O "2004-03-31_10:25:52_ck1" Person_evidence -O "2006-03-01_10:50:27_mt3" "WBPerson692" -O "2006-03-01_10:50:27_mt3"

Variation : "ox190" -O "2005-01-24_16:31:56_mt3"
Description	 -O "2005-01-24_16:31:56_mt3" Phenotype_remark -O "2005-01-24_16:31:56_mt3" "At each molt the animals fail to sufficiently open the anterior end of the old cuticle to crawl out. Instead, the partially-shed cuticle forms a tight constriction around the animal. The time required for the worm to fully shed the cuticle is variable. Approximately 40\% (7\/18) of young adult animals retain partially shed cuticles within 10 hours of the molt. Eventually, most animals are able to free themselves from the constricted cuticle\; however, sometimes the cuticle breaks off behind the constriction, leaving a tight band of cuticle girdling the worm and giving it a wasp waist appearance. This phenotype is observed at all four molts and corresponds to the expected phenotype for a defect in a protease involved in ecdysis." -O "2006-02-28_13:54:04_mt3" Paper_evidence -O "2006-02-28_13:54:04_mt3" "WBPaper00024579" -O "2006-02-28_13:54:04_mt3"
Description	 -O "2005-01-24_16:31:56_mt3" Recessive -O "2005-01-24_16:31:56_mt3"
Description	 -O "2005-01-24_16:31:56_mt3" Partially_penetrant -O "2005-01-24_16:31:56_mt3"
Description	 -O "2005-01-24_16:31:56_mt3" Loss_of_function -O "2005-01-24_16:31:56_mt3" Amorph -O "2005-01-24_16:31:56_mt3"

Variation : "ox196" -O "2004-11-25_14:03:13_mt3"
Description	 -O "2005-01-24_16:31:56_mt3" Phenotype_remark -O "2005-01-24_16:31:56_mt3" "At each molt the animals fail to sufficiently open the anterior end of the old cuticle to crawl out. Instead, the partially-shed cuticle forms a tight constriction around the animal. The time required for the worm to fully shed the cuticle is variable. Approximately 40\% (7\/18) of young adult animals retain partially shed cuticles within 10 hours of the molt. Eventually, most animals are able to free themselves from the constricted cuticle\; however, sometimes the cuticle breaks off behind the constriction, leaving a tight band of cuticle girdling the worm and giving it a wasp waist appearance. This phenotype is observed at all four molts and corresponds to the expected phenotype for a defect in a protease involved in ecdysis." -O "2005-01-24_16:31:56_mt3" Paper_evidence -O "2006-02-28_13:54:04_mt3" "WBPaper00024579" -O "2006-02-28_13:54:04_mt3"
Description	 -O "2005-01-24_16:31:56_mt3" Recessive -O "2005-01-24_16:31:56_mt3"
Description	 -O "2005-01-24_16:31:56_mt3" Partially_penetrant -O "2005-01-24_16:31:56_mt3"
Description	 -O "2005-01-24_16:31:56_mt3" Loss_of_function -O "2005-01-24_16:31:56_mt3" Amorph -O "2005-01-24_16:31:56_mt3"

Variation : "ox197" -O "2005-01-24_17:51:37_mt3"
Description	 -O "2005-01-24_17:51:37_mt3" Phenotype_remark -O "2005-01-24_17:51:37_mt3" "At each molt the animals fail to sufficiently open the anterior end of the old cuticle to crawl out. Instead, the partially-shed cuticle forms a tight constriction around the animal. The time required for the worm to fully shed the cuticle is variable. Approximately 40\% (7\/18) of young adult animals retain partially shed cuticles within 10 hours of the molt. Eventually, most animals are able to free themselves from the constricted cuticle\; however, sometimes the cuticle breaks off behind the constriction, leaving a tight band of cuticle girdling the worm and giving it a wasp waist appearance. This phenotype is observed at all four molts and corresponds to the expected phenotype for a defect in a protease involved in ecdysis" -O "2005-01-24_17:51:37_mt3" Paper_evidence -O "2006-02-28_13:54:04_mt3" "WBPaper00024579" -O "2006-02-28_13:54:04_mt3"
Description	 -O "2005-01-24_17:51:37_mt3" Recessive -O "2005-01-24_17:51:37_mt3"
Description	 -O "2005-01-24_17:51:37_mt3" Partially_penetrant -O "2005-01-24_17:51:37_mt3"
Description	 -O "2005-01-24_17:51:37_mt3" Loss_of_function -O "2005-01-24_17:51:37_mt3" Amorph -O "2005-01-24_17:51:37_mt3"

Variation : "ox199" -O "2005-01-25_10:26:01_mt3"
Description	 -O "2005-01-25_10:26:01_mt3" Phenotype_remark -O "2005-01-25_10:26:01_mt3" "At each molt the animals fail to sufficiently open the anterior end of the old cuticle to crawl out. Instead, the partially-shed cuticle forms a tight constriction around the animal. The time required for the worm to fully shed the cuticle is variable. Approximately 40\% (7\/18) of young adult animals retain partially shed cuticles within 10 hours of the molt. Eventually, most animals are able to free themselves from the constricted cuticle\; however, sometimes the cuticle breaks off behind the constriction, leaving a tight band of cuticle girdling the worm and giving it a wasp waist appearance. This phenotype is observed at all four molts and corresponds to the expected phenotype for a defect in a protease involved in ecdysis" -O "2005-01-25_10:26:01_mt3" Paper_evidence -O "2006-02-28_13:54:04_mt3" "WBPaper00024579" -O "2006-02-28_13:54:04_mt3"
Description	 -O "2005-01-25_10:26:01_mt3" Recessive -O "2005-01-25_10:26:01_mt3"
Description	 -O "2005-01-25_10:26:01_mt3" Partially_penetrant -O "2005-01-25_10:26:01_mt3"
Description	 -O "2005-01-25_10:26:01_mt3" Loss_of_function -O "2005-01-25_10:26:01_mt3" Amorph -O "2005-01-25_10:26:01_mt3"

Variation : "p673" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "1999-09-09_11:20:52_sylvia" Temperature_sensitive -O "1999-09-09_11:20:52_sylvia" -O "1999-09-09_11:20:52_sylvia"
Description	 -O "1999-09-09_11:20:52_sylvia" Maternal -O "1999-09-09_11:20:52_sylvia"

Variation : "pa4" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-03-25_17:01:05_ck1" Phenotype_remark -O "2004-03-25_17:01:05_ck1" "Serotonin- and dopamine-deficient, although low levels of serotonin immunoreactivity seen (possibly not genuine serotonin)" -O "2004-03-25_17:01:05_ck1" Person_evidence -O "2006-03-01_10:50:27_mt3" "WBPerson384 L" -O "2006-03-01_10:50:27_mt3"
Description	 -O "2004-03-25_17:01:05_ck1" Recessive -O "2004-03-25_17:01:05_ck1"
Description	 -O "2004-03-25_17:01:05_ck1" Completely_penetrant -O "2004-03-25_17:01:05_ck1"
Description	 -O "2004-03-25_17:01:05_ck1" Loss_of_function -O "2004-03-25_17:01:05_ck1" Amorph -O "2004-03-25_17:01:05_ck1"

Variation : "pk13" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2005-08-18_15:05:18_ar2" Phenotype_remark -O "1999-09-09_11:20:52_sylvia" "A deletion derivative has been isolated. The homzygote will hatch, but is a larval lethal." -O "1999-09-09_11:20:52_sylvia" Paper_evidence -O "2006-03-01_10:50:27_mt3" "WBPaper00001784" -O "2006-03-01_10:50:27_mt3"

Variation : "pk38mc15" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2005-08-18_15:05:18_ar2" Phenotype_remark -O "1999-09-09_11:20:52_sylvia" "null, embryonic lethal with associated degeneration of hypodermal cells and glial-like cells." -O "1999-09-09_11:20:52_sylvia" Curator_confirmed -O "2006-03-01_10:50:27_mt3" "WBPerson1250" -O "2006-03-01_10:50:27_mt3"

Variation : "pk204" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-02-18_09:59:43_ck1" Phenotype_remark -O "2004-02-18_09:59:43_ck1" "transposon mutator\; germline-RNAi resistant" -O "2004-02-18_09:59:43_ck1" Curator_confirmed -O "2006-03-01_10:50:27_mt3" "WBPerson1845" -O "2006-03-01_10:50:27_mt3"
Description	 -O "2004-02-18_09:59:43_ck1" Recessive -O "2004-02-18_09:59:43_ck1"
Description	 -O "2004-02-18_09:59:43_ck1" Completely_penetrant -O "2004-02-18_09:59:43_ck1"
Description	 -O "2004-02-18_09:59:43_ck1" Loss_of_function -O "2004-02-18_09:59:43_ck1" Uncharacterised_loss_of_function -O "2004-02-18_09:59:43_ck1"

Variation : "pk295" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2005-08-18_15:05:18_ar2" Phenotype_remark -O "2004-07-20_08:45:30_krb" "No observable phenotype" -O "2004-07-20_08:45:30_krb" Paper_evidence -O "2006-03-01_10:50:27_mt3" "WBPaper00022625" -O "2006-03-01_10:50:27_mt3"

Variation : "pk719" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-02-18_09:59:43_ck1" Phenotype_remark -O "2004-02-18_09:59:43_ck1" "transposon mutator\; germline-RNAi resistant" -O "2004-02-18_09:59:43_ck1" Person_evidence -O "2004-02-18_09:59:43_ck1" "WBPerson1159" -O "2004-02-18_09:59:43_ck1"
Description	 -O "2004-02-18_09:59:43_ck1" Recessive -O "2004-02-18_09:59:43_ck1"
Description	 -O "2004-02-18_09:59:43_ck1" Completely_penetrant -O "2004-02-18_09:59:43_ck1"
Description	 -O "2004-02-18_09:59:43_ck1" Loss_of_function -O "2004-02-18_09:59:43_ck1" Uncharacterised_loss_of_function -O "2004-02-18_09:59:43_ck1"

Variation : "pk720" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-02-18_09:59:43_ck1" Phenotype_remark -O "2004-02-18_09:59:43_ck1" "transposon mutator\; germline-RNAi resistant" -O "2004-02-18_09:59:43_ck1" Person_evidence -O "2006-03-01_10:50:27_mt3" "WBPerson1159" -O "2006-03-01_10:50:27_mt3"
Description	 -O "2004-02-18_09:59:43_ck1" Recessive -O "2004-02-18_09:59:43_ck1"
Description	 -O "2004-02-18_09:59:43_ck1" Completely_penetrant -O "2004-02-18_09:59:43_ck1"
Description	 -O "2004-02-18_09:59:43_ck1" Loss_of_function -O "2004-02-18_09:59:43_ck1" Uncharacterised_loss_of_function -O "2004-02-18_09:59:43_ck1" Person_evidence -O "2006-03-01_10:50:27_mt3" "WBPerson1159" -O "2006-03-01_10:50:27_mt3"

Variation : "q276" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2005-08-18_15:05:18_ar2" Phenotype_remark -O "2004-08-18_08:15:53_krb" "Transformer(tra), XX animals transformed into mating males" -O "2004-08-18_08:15:53_krb" Paper_evidence -O "2004-08-18_08:15:53_krb" "WBPaper00005927" -O "2004-08-18_08:15:53_krb"

Variation : "q519" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2003-09-25_13:25:56_wormpub" Recessive -O "2004-04-27_09:55:31_krb"


Variation : "q558" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-04-27_09:55:31_krb" Recessive -O "2004-04-27_09:55:31_krb"

Variation : "q597" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-04-27_09:55:31_krb" Recessive -O "2004-04-27_09:55:31_krb"

Variation : "q740" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2003-10-14_09:34:41_ck1" Loss_of_function -O "2003-10-14_09:34:41_ck1" Amorph -O "2003-10-14_09:34:41_ck1"

Variation : "q741" -O "2005-04-20_10:01:53_mt3"
Description	 -O "2005-09-15_17:18:41_td3" Recessive -O "2005-09-15_17:18:41_td3"

Variation : "rh252" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-08-18_08:15:53_krb" Loss_of_function -O "2004-08-18_08:15:53_krb" Amorph -O "2004-08-18_08:15:53_krb" Paper_evidence -O "2004-08-18_08:15:53_krb" "WBPaper00005833" -O "2004-08-18_08:15:53_krb"

Variation : "rt70" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-03-25_16:58:25_ck1" Phenotype_remark -O "2004-03-25_16:58:25_ck1" "Degeneration of 90\% of the  ASH neurons when animals are raised at 15 degrees." -O "2004-03-25_16:58:25_ck1" Person_evidence -O "2006-03-01_10:50:27_mt3" "WBPerson1652" -O "2006-03-01_10:50:27_mt3"
Description	 -O "2004-03-25_16:58:25_ck1" Recessive -O "2004-03-25_16:58:25_ck1"
Description	 -O "2004-03-25_16:58:25_ck1" Temperature_sensitive -O "2004-03-25_16:58:25_ck1" Cold_sensitive -O "2004-03-25_16:58:25_ck1" "15 degrees causes degeneration of ASH neurons" -O "2004-03-25_16:58:25_ck1" Person_evidence -O "2006-03-01_10:50:27_mt3" "WBPerson1652" -O "2006-03-01_10:50:27_mt3"
Description	 -O "2004-03-25_16:58:25_ck1" Loss_of_function -O "2004-03-25_16:58:25_ck1" Hypomorph -O "2004-03-25_16:58:25_ck1"

Variation : "rt97" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2005-07-20_10:11:02_wormpub" Recessive -O "2005-10-11_10:44:42_mt3"
Description	 -O "2005-07-20_10:11:02_wormpub" Completely_penetrant -O "2005-10-11_10:44:42_mt3"
Description	 -O "2005-07-20_10:11:02_wormpub" Loss_of_function -O "2005-10-11_10:44:42_mt3" Hypomorph -O "2005-10-11_10:44:42_mt3" Paper_evidence -O "2005-10-11_13:30:24_mt3" "WBPaper00013467" -O "2005-10-11_13:30:24_mt3"
Description	 -O "2005-07-20_10:11:02_wormpub" Phenotype_remark -O "2005-10-11_10:44:42_mt3" "Hemosensory defective, including detection of octanol, quinine, high osmolarity, diacetyl and isoamyl alcohol. Nose-touch normal." -O "2005-10-11_13:30:24_mt3" Paper_evidence -O "2005-10-11_13:30:24_mt3" "WBPaper00013467" -O "2005-10-11_13:30:24_mt3"

Variation : "s1586" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2003-06-13_10:26:58_ck1" Phenotype_remark -O "2003-06-13_10:26:58_ck1" "homozygous lethal at late larval stage" -O "2003-06-13_10:26:58_ck1" Paper_evidence -O "2006-02-28_13:54:04_mt3" "WBPaper00005824" -O "2006-02-28_13:54:04_mt3"
Description	 -O "2003-06-13_10:26:58_ck1" Recessive -O "2003-06-13_10:26:58_ck1"
Description	 -O "2003-06-13_10:26:58_ck1" Loss_of_function -O "2003-06-13_10:26:58_ck1" Amorph -O "2003-06-13_10:26:58_ck1"

Variation : "sa191" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2003-05-23_10:32:18_ck1" Semi_dominant -O "2003-05-23_10:32:18_ck1"

Variation : "sa201" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-12-16_15:49:57_wormpub" Recessive -O "2004-12-16_15:50:23_mt3"
Description	 -O "2004-12-16_15:49:57_wormpub" Completely_penetrant -O "2004-12-16_15:50:23_mt3"
Description	 -O "2004-12-16_15:49:57_wormpub" Loss_of_function -O "2004-12-16_15:50:23_mt3" Hypomorph -O "2004-12-16_15:50:23_mt3"

Variation : "sa573" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2003-10-16_13:35:37_wormpub" Loss_of_function -O "2003-10-16_13:35:50_ck1"

Variation : "sa589" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2003-05-21_09:56:11_ck1" Phenotype_remark -O "2003-05-21_09:56:11_ck1" "paralyzed yet viable alleles of twk-2" -O "2003-05-21_09:56:11_ck1" Paper_evidence -O "2006-02-28_13:54:04_mt3" "WBPaper00004376" -O "2006-02-28_13:54:04_mt3"

Variation : "sa691" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2003-10-16_13:35:50_ck1" Loss_of_function -O "2003-10-16_13:35:50_ck1"

Variation : "sa700" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2003-10-16_13:35:37_wormpub" Loss_of_function -O "2003-10-16_13:35:50_ck1"

Variation : "sp6" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2003-04-15_10:04:46_ck1" Recessive -O "2003-04-15_10:04:46_ck1"

Variation : "sp23" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2003-04-15_10:04:46_ck1" Recessive -O "2003-04-15_10:04:46_ck1"

Variation : "st19" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-08-10_15:15:33_krb" Dominant -O "2004-08-10_15:15:33_krb"

Variation : "st43" -O "2004-04-07_11:23:34_wormpub"

Variation : "st89" -O "2004-04-07_11:23:34_wormpub"

Variation : "st136" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-09-16_14:17:47_rem" Phenotype_remark -O "2004-09-16_14:17:47_rem" "twitching movement" -O "2004-09-16_14:17:47_rem" Person_evidence -O "2004-09-16_14:17:47_rem" "WBPerson1521" -O "2004-09-16_14:17:47_rem"
Description	 -O "2004-09-16_14:17:47_rem" Recessive -O "2004-09-16_14:17:47_rem"

Variation : "su158" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2003-06-13_10:26:58_ck1" Phenotype_remark -O "2004-08-18_08:15:53_krb" "homozygous viable and shows a more severe motility defect than a strong loss-of-function mutant e677" -O "2004-08-18_08:15:53_krb" Paper_evidence -O "2004-08-18_08:15:53_krb" "WBPaper00005824" -O "2004-08-18_08:15:53_krb"
Description	 -O "2003-06-13_10:26:58_ck1" Loss_of_function -O "2003-06-13_10:26:58_ck1" Amorph -O "2003-06-13_10:26:58_ck1" Paper_evidence -O "2006-02-09_09:32:38_mt3" "WBPaper00005824" -O "2006-02-09_09:32:38_mt3"

Variation : "su1006" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2005-08-18_15:05:18_ar2" Phenotype_remark -O "2004-08-18_08:15:53_krb" "Roller(rol), dominant, right-handed rollers in larval stages 3 and 4, and in adult" -O "2004-08-18_08:15:53_krb" Paper_evidence -O "2004-08-18_08:15:53_krb" "WBPaper00005927" -O "2004-08-18_08:15:53_krb"

Variation : "sy1" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2002-11-08_14:54:32_ck1" Phenotype_remark -O "2003-03-07_10:27:20_ck1" "Egl" -O "2004-03-19_16:42:15_ck1" Paper_evidence -O "2006-02-28_13:54:04_mt3" "WBPaper00001404" -O "2006-02-28_13:54:04_mt3"
Description	 -O "2002-11-08_14:54:32_ck1" Recessive -O "2002-11-08_14:54:32_ck1"
Description	 -O "2002-11-08_14:54:32_ck1" Partially_penetrant -O "2003-03-07_10:27:20_ck1"
Description	 -O "2002-11-08_14:54:32_ck1" Loss_of_function -O "2003-03-07_10:27:20_ck1" Hypomorph -O "2003-03-07_10:27:20_ck1"

Variation : "sy14" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-03-24_17:09:57_ck1" Loss_of_function -O "2004-03-24_17:09:57_ck1" Amorph -O "2004-03-24_17:09:57_ck1" Paper_evidence -O "2006-02-09_09:32:38_mt3" "WBPaper00001404" -O "2006-02-09_09:32:38_mt3"

Variation : "sy16" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-03-25_16:58:25_ck1" Phenotype_remark -O "2004-03-25_16:58:25_ck1" "larval lethal" -O "2004-03-25_16:58:25_ck1" Curator_confirmed -O "2006-03-01_11:41:43_mt3" "WBPerson1250" -O "2006-03-01_11:41:43_mt3"
Description	 -O "2004-03-25_16:58:25_ck1" Recessive -O "2004-03-25_16:58:25_ck1"
Description	 -O "2004-03-25_16:58:25_ck1" Completely_penetrant -O "2004-03-25_16:58:25_ck1"
Description	 -O "2004-03-25_16:58:25_ck1" Loss_of_function -O "2004-03-25_16:58:25_ck1" Amorph -O "2004-03-25_16:58:25_ck1"

Variation : "sy17" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-03-24_17:09:57_ck1" Loss_of_function -O "2004-03-24_17:09:57_ck1" Amorph -O "2004-03-24_17:09:57_ck1"

Variation : "sy97" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-02-09_10:59:41_ck1" Phenotype_remark -O "2004-02-09_10:59:41_ck1" "larval lethal vulvaless (and thus Egl) Mab (crumpled spicules)" -O "2004-02-09_10:59:41_ck1" Curator_confirmed -O "2006-03-01_10:50:27_mt3" "WBPerson1845" -O "2006-03-01_10:50:27_mt3"
Description	 -O "2004-02-09_10:59:41_ck1" Recessive -O "2004-02-09_10:59:41_ck1"
Description	 -O "2004-02-09_10:59:41_ck1" Partially_penetrant -O "2004-02-09_10:59:41_ck1"
Description	 -O "2004-02-09_10:59:41_ck1" Loss_of_function -O "2004-02-09_10:59:41_ck1" Hypomorph -O "2004-02-09_10:59:41_ck1"

Variation : "sy289" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2002-11-06_16:23:48_ck1" Recessive -O "2002-11-06_16:23:48_ck1"

Variation : "sy576" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-09-02_09:29:12_rem" Phenotype_remark -O "2004-09-02_09:29:12_rem" "unc and spicule muscles resistant to 100mM levamisole" -O "2004-09-02_09:29:12_rem" Person_evidence -O "2004-09-02_09:29:12_rem" "WBPerson191" -O "2004-09-02_09:29:12_rem"

Variation : "sy628" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-03-10_11:29:29_wormpub" Phenotype_remark -O "2004-03-25_16:58:25_ck1" "Hermaphrodite: Egl,  Male: Lov, loss of HOB-specific gene expression" -O "2004-03-25_16:58:25_ck1" Paper_evidence -O "2006-02-28_13:54:04_mt3" "WBPaper00006247" -O "2006-02-28_13:54:04_mt3"
Description	 -O "2004-03-10_11:29:29_wormpub" Recessive -O "2004-03-25_16:58:25_ck1"
Description	 -O "2004-03-10_11:29:29_wormpub" Loss_of_function -O "2004-03-25_16:58:25_ck1" Hypomorph -O "2004-03-25_16:58:25_ck1"

Variation : "sy676" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-03-08_09:18:31_ck1" Gain_of_function -O "2004-03-08_09:18:31_ck1"

Variation : "t1550" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-07-22_15:03:39_rem" Phenotype_remark -O "2004-07-22_15:03:39_rem" "lack of pronuclear migration, lack of centrosome separation lack of MT minus-end directed yolk granule movement" -O "2004-07-22_15:03:39_rem" Person_evidence -O "2006-03-01_10:50:27_mt3" "WBPerson208" -O "2006-03-01_10:50:27_mt3"
Description	 -O "2004-07-22_15:03:39_rem" Recessive -O "2004-07-22_15:03:39_rem"
Description	 -O "2004-07-22_15:03:39_rem" Completely_penetrant -O "2004-07-22_15:03:39_rem"

Variation : "t1698" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-07-22_15:03:39_rem" Phenotype_remark -O "2004-07-22_15:03:39_rem" "lack of pronuclear migration, lack of centrosome separation lack of MT minus-end directed yolk granule movement" -O "2004-07-22_15:03:39_rem" Paper_evidence -O "2006-03-01_11:41:43_mt3" "WBPaper00024358" -O "2006-03-01_11:41:43_mt3"
Description	 -O "2004-07-22_15:03:39_rem" Recessive -O "2004-07-22_15:03:39_rem"
Description	 -O "2004-07-22_15:03:39_rem" Completely_penetrant -O "2004-07-22_15:03:39_rem"

Variation : "tg113" -O "2005-12-08_14:14:36_mt3"
Description	 -O "2005-12-08_14:14:36_mt3" Loss_of_function -O "2005-12-08_14:14:36_mt3" Uncharacterised_loss_of_function -O "2005-12-08_14:14:36_mt3" Paper_evidence -O "2005-12-08_14:14:36_mt3" "WBPaper00026597" -O "2005-12-08_14:14:36_mt3"

Variation : "tm232" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm233" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm234" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm235" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. R. Horvitz: does not suppress synMuv phenotype." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm236" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm237" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm238" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable\; Dr. H. Sawa: 0\% Psa (n=98)\; Dr. J-L. Bessereau: deletion is within an intron and does not affect gene expression." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm239" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. J.K. Liu: no defects in the M lineage." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm240" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm241" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_10:46:08_NBP_allele__update" Phenotype_remark -O "2006-03-03_10:46:08_NBP_allele__update" "homozygous viable. Dr. S. Hekimi: Development in press." -O "2006-03-03_10:46:08_NBP_allele__update"

Variation : "tm242" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_10:46:08_NBP_allele__update" Phenotype_remark -O "2006-03-03_10:46:08_NBP_allele__update" "Egl?" -O "2006-03-03_10:46:08_NBP_allele__update"

Variation : "tm244" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. K.L. Chow: No observable defect in males, all animals have wild-type movement and morphology." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm245" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile. Dr. A. Chisholm: L1 lethal." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm246" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "maternal effect larval lethal. Dr. G. Hermann: WT gut granules." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm248" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm249" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm250" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm251" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "Lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm252" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_10:46:08_NBP_allele__update" Phenotype_remark -O "2006-03-03_10:46:08_NBP_allele__update" "homozygous viable. Dr. J. Liu: Development 132, 4119-4130 (2005)." -O "2006-03-03_10:46:08_NBP_allele__update"

Variation : "tm253" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile. Dr. J. Karlseder: normal telomere length regulation." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm254" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. J. Karlseder: normal telomere length regulation." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm256" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm257" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm258" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm259" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile?. Dr. P. Sengputa: normal dye filling.  Dr. W.B. Derry: non-Mendelian inheritance.  Deletion is unstable extrachromosomal?" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm260" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm261" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm262" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm263" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm264" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm265" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm266" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm267" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_10:46:08_NBP_allele__update" Phenotype_remark -O "2006-03-03_10:46:08_NBP_allele__update" "homozygous viable" -O "2006-03-03_10:46:08_NBP_allele__update"

Variation : "tm268" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable.  Dr. Y. Ohshima (J. Exp. Biol. 206, 2581- 2593, 2003)" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm269" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm270" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm271" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm272" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. P. Sengupta: normal development of AWA neurons." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm273" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm274" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm275" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile. Dr. R. Lin: normal cell division during 8-30 cell stage. Dr. P. Sengupta normal dye-filling into sensory neurons (heterozygote). Dr. J. Priess: Dev. Cell 8, 867-879 (2005). Dr. M. Maduro: normal early development (8-30 cell stage)." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm276" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_10:46:08_NBP_allele__update" Phenotype_remark -O "2006-03-03_10:46:08_NBP_allele__update" "homozygous viable" -O "2006-03-03_10:46:08_NBP_allele__update"

Variation : "tm277" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. S. Shaham: no defects in CEP sheath cells or associated neurons." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm278" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. R. Lin: Dev. Biol. 276, 493-507 (2004)." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm279" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_10:46:08_NBP_allele__update" Phenotype_remark -O "2006-03-03_10:46:08_NBP_allele__update" "homozygous viable. Dr. S. Shaham: no defects in CEP sheath cells or associated neurons." -O "2006-03-03_10:46:08_NBP_allele__update"

Variation : "tm280" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm281" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm282" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile. Dr. P. Okkema: L1 arrest with pharyngeal defects, recessive." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm284" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. R. Lin, Dr. M. Maduro: normal cell division during 8-30 cell stage. Dr. P. Sengupta: normal dye-filling into sensory neurons. Dr. J. Priess: Dev. Cell 8, 867-879 (2005)." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm287" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_10:46:08_NBP_allele__update" Phenotype_remark -O "2006-03-03_10:46:08_NBP_allele__update" "homozygous viable. Dr. P. Sengupta: normal dye-filling into sensory neurons." -O "2006-03-03_10:46:08_NBP_allele__update"

Variation : "tm288" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm289" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm290" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm291" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile Dr. Y. Kohara: Development 130\; 2495-2503  (2003)." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm292" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. J. Kaplan: WT aldicarb response." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm293" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_10:46:08_NBP_allele__update" Phenotype_remark -O "2006-03-03_10:46:08_NBP_allele__update" "homozygous viable. Dr. J. Kaplan: WT aldicarb response." -O "2006-03-03_10:46:08_NBP_allele__update"

Variation : "tm294" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm295" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm296" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_10:46:08_NBP_allele__update" Phenotype_remark -O "2006-03-03_10:46:08_NBP_allele__update" "homozygous viable" -O "2006-03-03_10:46:08_NBP_allele__update"

Variation : "tm297" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. R. Plasterk: no RNAi defective phenotype." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm299" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile. Dr. J. Gaudet: larvar lethal at L1-L2 stage." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm300" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm301" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile: Dr. R. Hosono: Exp. Cell Res. 287, 350-360 (2003)." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm302" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "developmental retardation?.  Dr. J. Kaplan: zygotic lethal, could not assay for behaviors or GLR-1" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm303" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "developmental retardation? Dr. J. Kaplan: zygotic lethal, could not assay for behaviors or GLR-1" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm304" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_10:46:08_NBP_allele__update" Phenotype_remark -O "2006-03-03_10:46:08_NBP_allele__update" "homozygous viable. Dr. K. Shen: Normal HSN vulval presynaptic vesicle clusters (unc-86::SNB-1::YFP), no obvious egg laying defects." -O "2006-03-03_10:46:08_NBP_allele__update"

Variation : "tm305" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile?" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm306" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. A. Colavita: no defects in VC axon guidance or morphology." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm307" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "Dr. C. Bargmann\; Neuron 32, 25-38 (2001)." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm308" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable\; Dr. H. Sawa: 0\% Psa (n=114)\;" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm309" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable\; Dr. H. Sawa: 0\% Psa (n=106)\;" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm310" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm311" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm312" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm313" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. P. Sengupta: normal ciliary structure of AWC, AWB and ADF neurons, not uncordinated." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm314" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm315" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. O. Hobert: No ventral midline axonal phenotype scored with oyIs14." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm316" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm317" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm318" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm319" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_10:46:08_NBP_allele__update" Phenotype_remark -O "2006-03-03_10:46:08_NBP_allele__update" "homozygous viable" -O "2006-03-03_10:46:08_NBP_allele__update"

Variation : "tm320" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm321" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm322" -O "2001-07-10_11:53:59_sylvia"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm323" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm324" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable\; Dr. M.M. Barr: Dyf+,  PKD-2::GFP localization: subtle ciliary mislocalization\; Dr. P. Sengupta: 10\% of animals fail to dye-fill one AWB neuron when grwon at 25C. Other neurons dye-fill normally." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm325" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm326" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_10:46:08_NBP_allele__update" Phenotype_remark -O "2006-03-03_10:46:08_NBP_allele__update" "lethal? (maintenance: +\/eT1 III\; tm326\/eT1 V = FX326)Dpy, slow growth?" -O "2006-03-03_10:46:08_NBP_allele__update"

Variation : "tm327" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "maternal, embryonic lethal. Dr. G. Hermann: unable to find lethals. Dr. G. Ruvkun: no effect on dauer arrest." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm328" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. K. Matsumoto: SNB-1::GFP was localized normally in sensory neurons." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm329" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. R. Plasterk: Genes &amp\; Dev. 19, 782-(2005)." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm330" -O "2001-07-10_11:53:59_sylvia"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm331" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. H. Arai: WT (Brood size, embryonic lethality, larval lehtality, growth rate)" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm332" -O "2001-07-10_11:53:59_sylvia"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm333" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm334" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. M. Krause: J. Neurosci.24, 3115-3124 (2004). Dr. C. Bargmann &amp\; Dr. K. Shen: HSN presynaptic vesicle localization normal." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm335" -O "2001-07-10_11:53:59_sylvia"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. A. Antebi: normal gonadal migration." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm336" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_10:46:08_NBP_allele__update" Phenotype_remark -O "2006-03-03_10:46:08_NBP_allele__update" "homozygous viable" -O "2006-03-03_10:46:08_NBP_allele__update"

Variation : "tm337" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "sterile, maternal" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm338" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_10:46:08_NBP_allele__update" Phenotype_remark -O "2006-03-03_10:46:08_NBP_allele__update" "homozygous viable" -O "2006-03-03_10:46:08_NBP_allele__update"

Variation : "tm340" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm341" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm342" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm343" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm344" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm345" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm346" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm348" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm349" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm350" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile. Dr. J-L. Bessereau: the allele probably habors side mutation causing lethality." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm351" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm352" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. C. Bargmann &amp\; Dr. K. Shen: HSN presynaptic vesicle localization normal. Dr. A. Chisholm &amp\; Dr. Y. Jin: J. Neurosci. 25, 7517-7528 (2005)." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm353" -O "2001-07-10_11:53:59_sylvia"
Description	 -O "2006-03-03_10:46:08_NBP_allele__update" Phenotype_remark -O "2006-03-03_10:46:08_NBP_allele__update" "homozygous viable. Dr. Y. Jin: Development 130, 3147-3161, 2003." -O "2006-03-03_10:46:08_NBP_allele__update"

Variation : "tm354" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm355" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. C.L. Creasy: fertile, normal locomotion, normal egg-laying, solitary social feeding. Dr. I. Mori: normal thermotaxis." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm356" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "sterile or lethal" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm357" -O "2001-07-10_11:53:59_sylvia"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm358" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm359" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm360" -O "2001-07-10_11:53:59_sylvia"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm361" -O "2001-07-10_11:53:59_sylvia"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm362" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm363" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm364" -O "2001-07-10_11:53:59_sylvia"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm365" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. C. Rongo: WT GLR-1::GFP localization." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm366" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm367" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile. Dr. M. Han: homozygous viable, less fertile, body morphogenesis defects." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm368" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm369" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm371" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm372" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm373" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm374" -O "2001-07-10_11:53:59_sylvia"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "maternal-effect lethal and vulval protrusion" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm375" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. M.M. Barr: PKD-2::GFP localization=WT, Dyf+." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm376" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_10:46:08_NBP_allele__update" Phenotype_remark -O "2006-03-03_10:46:08_NBP_allele__update" "homozygous viable" -O "2006-03-03_10:46:08_NBP_allele__update"

Variation : "tm377" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm378" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm379" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. J-L. Bessereau: normal UNC-29 immunostaining at NMJ. wild-type sensitivity to 0.1 mM levamisole. Dr. D.M. Miller: no locomotory pertubations. Dr. K. Ashrafi: substantially increased fat (nile red staining)." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm380" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm381" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm382" -O "2001-07-10_11:53:59_sylvia"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. M. Hengartner: no defects in phagocytosis and DTC migration." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm383" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm384" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm385" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "embryonic or larval lethal" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm387" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm388" -O "2004-12-06_16:32:12_NBP_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm389" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm390" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable Dr. T. Toyoda: Biochem. Biophys. Res. Comm. 293, 697-704 (2002)." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm391" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm392" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm393" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile. Dr. Y. Iino: Mech. Dev. 121, 213-224(2004)." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm394" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. A. Antebi: normal gonadal migration." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm395" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable, Dr. C. Rongo: normal GLR-1::GFP expression." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm396" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm397" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm398" -O "2001-07-10_11:53:59_sylvia"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm399" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. K. Ashrafi: substantially increased fat (nile red staining) and slight developmental delay." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm400" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm401" -O "2001-07-10_11:53:59_sylvia"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm402" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile. Er. V. Maricq: L1 lethal that has a severe pharyngeal pumping defects." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm403" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile. Dr. Y. Jin: could not maintain as homozygote." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm404" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm405" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm406" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm407" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm408" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm409" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm410" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile. Dr. E. Jorgensen: Development 131, 6001-6008 (2004)." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm411" -O "2002-07-22_08:54:58_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm412" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm413" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. O. Hobert: No ventral midline axonal phenotype scored with oyIs14." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm414" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm415" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. J. Ahringer: low percentage Pvl and Rup adults (might be from side mutantion)" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm416" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm417" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm418" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm419" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. M. Driscoll: No effect found on necrotic cell death." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm420" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. H. Arai: WT (Brood size, embryonic lethality, larval lehtality, growth rate), Dr. M. Han: slow growth, dumpish, mono-unsaturated fatty acids N17 are decreased." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm421" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viableDr. M. Hagiwara: EMBO Rep. 3, 962-966 (2002)" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm422" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. M. Driscoll: No effect found on necrotic cell death." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm423" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm424" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. S. Ahmed: Not hypersensitive to ionizing radiation." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm425" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable, Dr. M.M.Barr: complement n4132 mutant, WT pkd-2::gfp expression. Dr. K. Ashrafi: wild type fat (nile red staining)." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm426" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm427" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm428" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile.  Dr. P. Okkema: L1-L2 arrest with pharyngeal defects, recessive." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm429" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm430" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm431" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable\;  Dr. H. Sawa: 0.4\% Psa (n=214)\;" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm432" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_10:46:08_NBP_allele__update" Phenotype_remark -O "2006-03-03_10:46:08_NBP_allele__update" "homozygous viable. Dr. R. Lin: normal cell division during 8-30 cell stage. Dr. P. Sengupta: normal dye-filling into sensory neurons." -O "2006-03-03_10:46:08_NBP_allele__update"

Variation : "tm433" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. O. Hobert: No ventral midline axonal phenotype scored with oyIs14." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm434" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm435" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm436" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. O. Hobert: No ventral midline axonal phenotype scored with oyIs14." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm437" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm438" -O "2002-07-22_08:54:58_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm439" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm440" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. O. Hobert: No ventral midline axonal phenotype scored with oyIs14." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm442" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm444" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm445" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. G. Jansen: WT aging, WT chemotaxis to odorants." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm446" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. J. Kaplan: wild type movement, nonEgl, nonRic, apparently wild type pattern of GLR-1::GFP. Dr. J. Saterlee: normal brood size, development and movement." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm447" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm448" -O "2004-07-15_09:29:11_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm449" -O "2002-07-22_08:54:58_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm450" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm451" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile, Dr. M.M.Barr: complement n4132 mutant, WT pkd-2::gfp expression." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm452" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm453" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_10:46:08_NBP_allele__update" Phenotype_remark -O "2006-03-03_10:46:08_NBP_allele__update" "homozygous viable" -O "2006-03-03_10:46:08_NBP_allele__update"

Variation : "tm454" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm455" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm456" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. O. Hobert: No ventral midline axonal phenotype scored with oyIs14. Dr. M. Maduro: normal early embryogenesis at 4-30 cell stage." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm457" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm458" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. R. Lin, Dr. M. Maduro: normal cell division during 8-30 cell stage. Dr. P. Sengupta: normal dye-filling into sensory neurons. Dr. J. Priess: Dev. Cell 8, 867-879 (2005)." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm460" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm461" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm462" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm463" -O "2002-07-22_08:54:58_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm464" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. J. Kaplan: wild type movement, nonEgl, nonRic, apparently wild type pattern of GLR-1::GFP. Dr. J. Satterlee: normal brood size, development and movement." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm465" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm466" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm467" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm469" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable, Dr. D. Xue (Science 302, 1563, 2003)" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm470" -O "2002-07-22_08:54:58_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm471" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm472" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable\; Dr. O. Hobert: Neuron 41, 723-736 (2004)" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm473" -O "2002-07-22_08:54:58_krb"
Description	 -O "2006-03-03_10:46:08_NBP_allele__update" Phenotype_remark -O "2006-03-03_10:46:08_NBP_allele__update" "homozygous viable" -O "2006-03-03_10:46:08_NBP_allele__update"

Variation : "tm474" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm475" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm477" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm478" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm479" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm480" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm481" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm482" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm483" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile. Dr. Y. Iino: Mech. Dev. 121, 213-224 (2004)." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm484" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm485" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm486" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm488" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable, Dr. C. Rongo: normal GLR-1::GFP expression." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm489" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm490" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_10:46:08_NBP_allele__update" Phenotype_remark -O "2006-03-03_10:46:08_NBP_allele__update" "homozygous viable. Dr. R. Lin: normal cell division during 8-30 cell stage." -O "2006-03-03_10:46:08_NBP_allele__update"

Variation : "tm491" -O "2004-12-06_16:32:12_NBP_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm492" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm494" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable: Dr. M. Barr: mating behavior=WT, mating efficiency=WT, Dyf+, PKD-2::GFP localization=WT" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm495" -O "2002-07-22_08:54:58_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm496" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm497" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_10:46:08_NBP_allele__update" Phenotype_remark -O "2006-03-03_10:46:08_NBP_allele__update" "homozygous viable" -O "2006-03-03_10:46:08_NBP_allele__update"

Variation : "tm501" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "Dr. I. Katsura : Cell 109, 639-649 (2002).  Dr. K. Shen: localization and accumulation of presynaptic veiscle clusters look wild type (evaluated presynaptic vesicle cluster in AIY using an integrated line expressing ttx3:Rab3:GFP)." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm502" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm503" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm504" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm505" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm506" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm507" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm508" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. M. Hengartner: kinker\/omega." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm509" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm510" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm511" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm512" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. J.K. Liu: no defects in the M lineage. Dr. M. Maduro: normal early embryogenesis at 4-30 cell stage." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm513" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. K. Shen: Normal HSN vulval presynaptic vesicle clusters (unc-86::SNB-1::YFP), no obvious egg laying defects." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm514" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile. Dr. H. Sawa: Genes &amp\; Dev. 19, 1743-1748 (2005)." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm515" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm516" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_10:46:08_NBP_allele__update" Phenotype_remark -O "2006-03-03_10:46:08_NBP_allele__update" "lethal or sterile" -O "2006-03-03_10:46:08_NBP_allele__update"

Variation : "tm518" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm519" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_10:46:08_NBP_allele__update" Phenotype_remark -O "2006-03-03_10:46:08_NBP_allele__update" "homozygous viable. Dr. G. Ruvkun: no effect on dauer arrest. Dr. M. Driscoll: no are-related muscle defects found. Dr. C. Kenyon: grossly normal morphology and fertility, does not form dauer at 25C." -O "2006-03-03_10:46:08_NBP_allele__update"

Variation : "tm520" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm521" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile. Dr. G. Ruvkun: no effect on dauer arrest." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm522" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. P. Okkema: partially penetrant late embryonic, early larval lethal, partially temperature sensitive." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm523" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile. Dr. G. Hermann: unable to find lethals." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm524" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm525" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "Lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm526" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm528" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile?" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm529" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm530" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable, small brood size. Dr. K. Shen: normal HSN vulval vesicle clusters (unc-86::SNB-1::YFP)." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm531" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm532" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm533" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm534" -O "2004-03-23_12:06:39_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. K. Ashrafi: substantially increased fat (nile red staining)." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm535" -O "2004-03-23_12:06:39_NBP_allele"
Description	 -O "2006-03-03_10:46:08_NBP_allele__update" Phenotype_remark -O "2006-03-03_10:46:08_NBP_allele__update" "homozygous viable" -O "2006-03-03_10:46:08_NBP_allele__update"

Variation : "tm536" -O "2004-07-15_09:29:11_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. R.H. Horvitz: No extra cells in anterior pharynx. Dr. S. Shaham: Cell Death, Diff., 12, 153-161, (2005)." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm537" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm538" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm539" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm540" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm541" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm542" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm543" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm544" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm545" -O "2004-09-14_10:32:51_krb"
Description	 -O "2006-03-03_10:46:08_NBP_allele__update" Phenotype_remark -O "2006-03-03_10:46:08_NBP_allele__update" "homozygous viable" -O "2006-03-03_10:46:08_NBP_allele__update"

Variation : "tm546" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile, Dr. K. Nomura: Nature 423, 443-448 (2003)" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm547" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm548" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. K. Ashrafi: healthy, fertile, has a small body size and altered fat content at adult stage. Dr. R. Plasterk: Dpy appearance." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm549" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm550" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm551" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm552" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_10:46:08_NBP_allele__update" Phenotype_remark -O "2006-03-03_10:46:08_NBP_allele__update" "homozygous viable" -O "2006-03-03_10:46:08_NBP_allele__update"

Variation : "tm553" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm554" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm555" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm556" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm557" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. R. Plasterk: not deficient in RNAi, no mutator phenotype." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm558" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_10:46:08_NBP_allele__update" Phenotype_remark -O "2006-03-03_10:46:08_NBP_allele__update" "homozygous viable" -O "2006-03-03_10:46:08_NBP_allele__update"

Variation : "tm559" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm560" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm561" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm562" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm563" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm565" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm566" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm567" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm568" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_10:46:08_NBP_allele__update" Phenotype_remark -O "2006-03-03_10:46:08_NBP_allele__update" "homozygous viable" -O "2006-03-03_10:46:08_NBP_allele__update"

Variation : "tm569" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm570" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm572" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm573" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. K. Matsumoto: no copper sensitivity." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm574" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable, Dr. A. Dernburg: weak Him (1.3\%), 32\% inviable embryos due to autosomal nondisjunction during meiosis." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm575" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm576" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm577" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm578" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm579" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm580" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm581" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm582" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm584" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. G. Hermann: WT gut granules." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm585" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm586" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm587" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. P. Sengupta: dyf+ in all sensory neurons." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm588" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm589" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm590" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm591" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm592" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm593" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm594" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm595" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm596" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm597" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile. Dr. M. Hengartner: engulfment defect." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm598" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable, Dr. C. Rongo: normal GLR-1::GFP expression. Dr. K. Matsumoto: no Tunicamycin sensitivity." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm599" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. G. Ruvkun: no effect on dauer arrest." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm600" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm601" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm602" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm603" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm604" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm605" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm606" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm607" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile. Dr. M. Sundaram, Dr. R. Plasterk: zygotic embryonic lethal." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm608" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. M. Sundaram, Dr. R. Plasterk, Dr. K.L. Chow: deletion in the intron, wild-type. Dr. J. Ahringer: non-Egl." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm609" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm610" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm611" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile. Dr. A. Dernburg: homozyous viable, Him., Cell 123, 1051-1063 (2005)." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm612" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm613" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. Y. Jin: normal behavior." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm615" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm616" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm617" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "Homozygous viable. Dr. J. Satterlee: normal brood size, development and movement, quinine avoidance behavior." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm618" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. R. Lin, Dr. M. Maduro: normal cell division during 8-30 cell stage." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm619" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm620" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm621" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm622" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm623" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm624" -O "2006-03-03_11:10:00_NBP_allele__update"
Description	 -O "2006-03-03_11:10:00_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:10:00_NBP_allele__update" "Homozygous viable" -O "2006-03-03_11:10:00_NBP_allele__update"

Variation : "tm625" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm626" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm627" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. J-L. Bessereau: sensitive to the nicotinic agonist DMPP." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm628" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_10:46:08_NBP_allele__update" Phenotype_remark -O "2006-03-03_10:46:08_NBP_allele__update" "homozygous viable" -O "2006-03-03_10:46:08_NBP_allele__update"

Variation : "tm629" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. N. Tavernarakis: normal development, normal locomotion, slightly shorter, less progeny at 25C." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm631" -O "2006-03-03_11:10:00_NBP_allele__update"
Description	 -O "2006-03-03_11:10:00_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:10:00_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:10:00_NBP_allele__update"

Variation : "tm633" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm634" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm635" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm636" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm637" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm638" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm639" -O "2006-03-03_11:10:00_NBP_allele__update"
Description	 -O "2006-03-03_11:10:00_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:10:00_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:10:00_NBP_allele__update"

Variation : "tm640" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm641" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm642" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm644" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm645" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm646" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm647" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm648" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. J. Kaplan: decreased GLR-1::GFP in the ventral cord." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm649" -O "2006-03-03_11:10:00_NBP_allele__update"
Description	 -O "2006-03-03_11:10:00_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:10:00_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:10:00_NBP_allele__update"

Variation : "tm650" -O "2006-03-03_11:10:00_NBP_allele__update"
Description	 -O "2006-03-03_11:10:00_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:10:00_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:10:00_NBP_allele__update"

Variation : "tm651" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "Homozygous viable, Dr. J. Kaplan: wild type movement, nonEgl, nonRic." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm652" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm653" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm654" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile, Dr. R. Plasterk: Nature, 432 :231-235 (2004). Dr. M. Sundaram: zygotic sterile. Dr. Y. Jin: could not maintain as homozygote." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm656" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_10:46:08_NBP_allele__update" Phenotype_remark -O "2006-03-03_10:46:08_NBP_allele__update" "homozygous viable. Dr. H. Sawa: 0\% Psa (n=102)." -O "2006-03-03_10:46:08_NBP_allele__update"

Variation : "tm657" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. H. Sawa: 3.9\% Psa (n=178)." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm658" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm659" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm660" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm661" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm662" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm663" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm664" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm665" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. P. Sengupta: no cryophilic behavior." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm666" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. N. Tavernarakis: normal development, normal locomotion, slightly shorter, less progeny at 25C, starved appearance." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm667" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm668" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm669" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. G. Jansen: WT chemotaxix to NaCl." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm670" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm671" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. C.L. Creasy: fertile, normal locomotion, normal egg-laying, solitary social feeding." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm672" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm673" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm674" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm675" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm676" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm677" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile.  Dr. V. Maricq: maternal effect lethal  with defects in gonad and intestine development., Dr. V. Gobel: Dev. Cell 6, 865-873 (2004). Dr. M. Hengartner: defects in DTC migration but not in corpse removal in the L1 head and adult gonad." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm678" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. J. Ewbank: Dev. Biol. 278, 49 (2005)" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm680" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm681" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm683" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm684" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. N. Tavernarakis: normal development, normal locomotion, normal body size\/shape, less progeny at 25C, Egl at 25C, freequent bagging." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm685" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm686" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm687" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm688" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm689" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm690" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. M. Driscoll: No effect found on necrotic cell death. Dr. N. Tavernarakis: normal development, normal locomotion, normal body size\/shape, normal brood size." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm691" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_10:46:08_NBP_allele__update" Phenotype_remark -O "2006-03-03_10:46:08_NBP_allele__update" "homozygous viable" -O "2006-03-03_10:46:08_NBP_allele__update"

Variation : "tm692" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm693" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm694" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm695" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm696" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm697" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm698" -O "2005-07-04_11:33:05_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm699" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm700" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm701" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm702" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. K. Matsumoto: no copper sensitivity." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm703" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm704" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm705" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. J. Kaplan: wild type movement, nonEgl" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm706" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. P. Okkema: wild-type growth and no defects." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm707" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm708" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm709" -O "2005-07-04_11:33:05_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm710" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile. Dr. P. Okkema: maternal effect lehtal, late embryonic, early larval arrest." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm712" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_10:46:08_NBP_allele__update" Phenotype_remark -O "2006-03-03_10:46:08_NBP_allele__update" "homozygous viable" -O "2006-03-03_10:46:08_NBP_allele__update"

Variation : "tm713" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. J-L. Bessereau: slow development, partially resistant to the nicotinic agonist DMPP. Dr. Y. Jin: normal behavior." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm714" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm715" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile. Dr. O Hobert: could not test axonal phenotype due to lethality." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm716" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm717" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. N. Tavernarakis: normal development, normal locomotion, normal body size\/shape and normal brood size." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm718" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. O. Hobert: no neurotransmission phenotype (aldicarb\/levamisole sensitivity). Dr. K. Shen: Normal HSN vulval presynaptic vesicle clusters (unc-86::SNB-1::YFP)." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm719" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm720" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm721" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm722" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile. Dr. M. Han: early larval lethal. Dr. P. Sengupta: Dyf+ in all sensory neurons." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm723" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm724" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm725" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm726" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm727" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm728" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm729" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. K. Shen: normal DA presynaptic puncta." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm730" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. P. Sengupta: dyf+ in all sensory neurons." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm731" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm732" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. M. Hengartner: normal growth and progeny size, a slight increase in germline apoptosis." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm733" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm734" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm736" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm737" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm738" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile. Dr. V. Maricq: mostly sterile and has a defect in spermatheca dilation which leads to f failure in fertilization." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm739" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. Y. Jin: normal behavior." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm740" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm741" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_10:46:08_NBP_allele__update" Phenotype_remark -O "2006-03-03_10:46:08_NBP_allele__update" "homozygous viable" -O "2006-03-03_10:46:08_NBP_allele__update"

Variation : "tm742" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm743" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. N. Tavernarakis: normal development, normal locomotion, slightly shorter, normal brood size." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm744" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm745" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. M. Hengartner: normal growth and progeny size, a slight increase in germline apoptosis." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm746" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm747" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. R. Plasterk: extracts are proficient for in vitro Dicer activity." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm748" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm749" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm750" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm751" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm752" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm753" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. V. Maricq: reduced brood size that is a likely result of faulty spermatheca dilation." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm754" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm755" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. D.M. Miller: normal unc-25::GFP fluorescence pattern, no locomotory perturbations." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm756" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile. Dr. P. Sengupta: dyf+ in all sensory neurons. Dr. A. Dernburg: tm756 has side mutation that causes lethality." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm757" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm758" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm759" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile. Dr. M. Hengartner: no altered germline apoptosis phenotype. Dr. A. Sugimoto: Dev. Biol. in press" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm760" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. G. Ruvkun: no effect on dauer arrest." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm761" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile.  Dr. R. Horvitz: could not recover mutants from heterozygotes." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm762" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm763" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm764" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. S. Ahmed: Not hypersensitive to ionizing radiation. Dr. H-S. Koo: hypersensitive to ionizing radiation at L1 stage." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm765" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm766" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. K.L. Chow: deletion is in the first intron. Dr. M. Hengartner: no altered germline apoptosis phenotype." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm767" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm768" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm769" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm770" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm771" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. P. Okkema: wild-type viablility and growth." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm773" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm774" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm775" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm776" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. G. Ruvkun: no effect on dauer arrest." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm777" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. K.L. Chow: No observable male defect, wild-type movement and morphology." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm778" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. N. Tavernarakis: normal development, normal locomotion, normal body size\/shape and normal brood size." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm779" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm780" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm781" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm782" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm783" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. G. Ruvkun: no effect on dauer arrest." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm784" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile. Dr. P. Sengputa: some dyf defects in both the amphid and phasmid." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm785" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. P. Sengupta: dyf+ in all sensory neurons." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm786" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. P. Sengupta: normal dye filling." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm787" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm788" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm789" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm791" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm792" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm793" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_10:46:08_NBP_allele__update" Phenotype_remark -O "2006-03-03_10:46:08_NBP_allele__update" "homozygous viable" -O "2006-03-03_10:46:08_NBP_allele__update"

Variation : "tm794" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. Z. Ronai: J. Cell Biol. 165, 857-867 (2004)." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm795" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm796" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm797" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm798" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm799" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm800" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. M. Maduro: normal early development (8-30 cell stage)." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm801" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm802" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm803" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm804" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "Homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm805" -O "2005-07-04_11:33:05_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm807" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "Homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm808" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "Lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm809" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "Homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm810" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "Lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm811" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "Lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm812" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "Homozygous viable. Dr. K. Ashrafi: substantially increased fat (nile red staining)." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm813" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "Homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm814" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "Lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm815" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "Homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm816" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "Homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm817" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_10:46:08_NBP_allele__update" Phenotype_remark -O "2006-03-03_10:46:08_NBP_allele__update" "Homozygous viable" -O "2006-03-03_10:46:08_NBP_allele__update"

Variation : "tm818" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "Homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm819" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "Lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm820" -O "2005-07-04_11:33:05_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "Homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm821" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_10:46:08_NBP_allele__update" Phenotype_remark -O "2006-03-03_10:46:08_NBP_allele__update" "Homozygous viable" -O "2006-03-03_10:46:08_NBP_allele__update"

Variation : "tm822" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_10:46:08_NBP_allele__update" Phenotype_remark -O "2006-03-03_10:46:08_NBP_allele__update" "Homozygous viable" -O "2006-03-03_10:46:08_NBP_allele__update"

Variation : "tm823" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "Lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm824" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "Homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm825" -O "2005-07-04_11:33:05_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "Homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm826" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "Homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm827" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "Homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm828" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "Homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm829" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "Lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm830" -O "2005-11-15_14:05:12_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "Homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm831" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "Homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm832" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm835" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "Homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm836" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "Lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm837" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "Homozygous viable. Dr. P. Sengupta: normal dye filling." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm838" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_10:46:08_NBP_allele__update" Phenotype_remark -O "2006-03-03_10:46:08_NBP_allele__update" "Homozygous viable" -O "2006-03-03_10:46:08_NBP_allele__update"

Variation : "tm839" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "Homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm840" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "Homozygous viable. Dr. P. Sengupta: dyf+ in all sensory neurons." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm841" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "Homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm842" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "Homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm843" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "Homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm844" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "Lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm845" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "Homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm846" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "Homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm847" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "Homozygous viable. Dr. G. Hermann: WT gut granules. Dr. H.C. Korswagen: QL and QR daughter cells, HSN migration defects, polarity of V5 division defects, similar to egl-20.  Dr. N. Tavernarakis: Egl, slightly bloated." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm848" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "Homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm849" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "Homozygous viable. Dr. J. Kaplan: type movement, nonEgl." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm850" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "Homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm851" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "Lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm852" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "Lethal or sterile. Dr. Z. Zhou: arrests at L1 stage, does not bear any persistent cell corpses at 4-fold embryonic stage or arrested L1 stage." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm853" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "Lethal or sterile. Dr. H. Sawa: maternal effect lethal. Dr. M. Hengartner: induction of germ cell death upon genotyoxic stress." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm854" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "Homozygous viable. Dr. N. Tavernarakis: normal development, normal locomotion, slightly shorter, normal brood size." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm856" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. K. Shen: HSNL presynaptic components anteriorly displaced similar to syg-2(ky671) and syg-2(ky673)." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm857" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "Homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm858" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_10:46:08_NBP_allele__update" Phenotype_remark -O "2006-03-03_10:46:08_NBP_allele__update" "homozygous viable. Dr. M. Driscoll: normal brood size, development, locomotion. Dr. N. Tavernarakis: suppression of neurodegeneration, normal development, normal locomotion, normal body size\/shape, normal brood size." -O "2006-03-03_10:46:08_NBP_allele__update"

Variation : "tm860" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "Homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm861" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm862" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm863" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. J-L. Bessereau: sensitive to nicotinic agonist DMPP after backcross." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm864" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_10:46:08_NBP_allele__update" Phenotype_remark -O "2006-03-03_10:46:08_NBP_allele__update" "Homozygous viable. Dr. C.L. Creasy: fertile, normal locomotion, normal egg-laying, solitary social feeding." -O "2006-03-03_10:46:08_NBP_allele__update"

Variation : "tm865" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm867" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "Homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm868" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm869" -O "2006-03-03_11:10:00_NBP_allele__update"
Description	 -O "2006-03-03_11:10:00_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:10:00_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:10:00_NBP_allele__update"

Variation : "tm870" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm871" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm874" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm875" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm876" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm877" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm878" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm880" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm881" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm883" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. W. Schafer: fertile, locomotion grossly normal. Dr. N. Tavernarakis: normal development, normal locomotion, normal body size &amp\; shape, normal brood size." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm885" -O "2006-03-03_10:46:08_NBP_allele__update"
Description	 -O "2006-03-03_10:46:08_NBP_allele__update" Phenotype_remark -O "2006-03-03_10:46:08_NBP_allele__update" "homozygous viable" -O "2006-03-03_10:46:08_NBP_allele__update"

Variation : "tm886" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm888" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_10:46:08_NBP_allele__update" Phenotype_remark -O "2006-03-03_10:46:08_NBP_allele__update" "homozygous viable" -O "2006-03-03_10:46:08_NBP_allele__update"

Variation : "tm891" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm893" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm895" -O "2004-02-27_12:08:54_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm896" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm897" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm898" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm899" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm900" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm901" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. G. Jansen: WT avoidance of 0.5 M NaCl and WT chemotaxis to NaCl." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm902" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm903" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. G. Jansen: WT avoidance of 0.5 M NaCl and WT chemotaxis to NaCl.  Dr. L. Avery: Feeding and satiety behavior normal." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm904" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm905" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm906" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. K. Matsumoto: no copper sensitivity." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm907" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_10:46:08_NBP_allele__update" Phenotype_remark -O "2006-03-03_10:46:08_NBP_allele__update" "homozygous viable" -O "2006-03-03_10:46:08_NBP_allele__update"

Variation : "tm908" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm909" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozgyous viable. Dr. C.L. Creasy: fertile, normal locomotion, normal egg-laying, solitary social feeding." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm910" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm911" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm913" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm915" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm916" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm917" -O "2004-07-15_09:29:11_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. R.H. Horvitz: No extra cells in anterior pharynx. Dr. S. Shaham: no defects in somatic cell death." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm918" -O "2004-05-24_11:48:27_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. C.L. Creasy: fertile, normal locomotion, normal egg-laying, solitary social feeding." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm919" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm920" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. M. Barr: PKD-2::GFP localization=WT. Dr. G. Hermann: loss of gut granules (Glo)." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm921" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm922" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. S. Ahmed: immortal germline (=WT)." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm923" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. R. Sommer: no major disruptions in the reading frame." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm924" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. K. Shen: HSN presynaptic vesicle localization normal." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm925" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. M.M.  Barr: Exp Cell Res. 305, 333-342 (2005). Dr. P. Sengupta: dyf defects in some neurons." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm926" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. M. Barr: non-Unc, non-Dyf, subtle abnormal tail spike, pkd-2::gfp expression is wild-type." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm927" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm928" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm929" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm930" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm931" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm932" -O "2004-03-23_12:06:39_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm933" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. G. Hermann: WT gut granules." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm934" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm935" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile. Dr. G. Hermann: WT gut granules." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm936" -O "2004-02-27_12:08:54_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable.  Dr. R. Plasterk: Genes Dev. 19, 782-(2005)." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm937" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_10:46:08_NBP_allele__update" Phenotype_remark -O "2006-03-03_10:46:08_NBP_allele__update" "homozygous viable" -O "2006-03-03_10:46:08_NBP_allele__update"

Variation : "tm938" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile. Dr. H. Sawa: homozygous lethal at L2-L3 stage and Unc. Dr. H-S. Koo: as above." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm939" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm940" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm941" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm942" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm943" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. K. Ashrafi: mederately increased fat (nile red staining)." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm944" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm945" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm946" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm947" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm948" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm949" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm950" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm951" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_10:46:08_NBP_allele__update" Phenotype_remark -O "2006-03-03_10:46:08_NBP_allele__update" "homozygous viable" -O "2006-03-03_10:46:08_NBP_allele__update"

Variation : "tm952" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm953" -O "2004-02-27_12:08:54_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm954" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm955" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm956" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm957" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm958" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm959" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm960" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm961" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_10:46:08_NBP_allele__update" Phenotype_remark -O "2006-03-03_10:46:08_NBP_allele__update" "homozygous viable" -O "2006-03-03_10:46:08_NBP_allele__update"

Variation : "tm962" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm963" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm964" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. J. Ahringer non-Pvl." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm965" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm966" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm967" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. M. Sundaram: deletion in the intron, wild-type." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm968" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm969" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm970" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. D.M. Miller: no locomotory perturbations." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm971" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm972" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm973" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm974" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. C. Rongo: WT GLR-1::GFP localization." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm975" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm976" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm977" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm978" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_10:46:08_NBP_allele__update" Phenotype_remark -O "2006-03-03_10:46:08_NBP_allele__update" "homozygous viable" -O "2006-03-03_10:46:08_NBP_allele__update"

Variation : "tm979" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm980" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm981" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. N. Tavernarakis: normal development, normal locomotion, normal body size\/shape and normal brood size. Dr. Y. Jin: normal behavior." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm983" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm984" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm985" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm987" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm988" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm989" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm990" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile. Dr. J-L. Bessereau: no detectable movement defect." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm992" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm993" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm994" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm995" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm996" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm997" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm998" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm999" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1000" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_10:46:08_NBP_allele__update" Phenotype_remark -O "2006-03-03_10:46:08_NBP_allele__update" "homozygous viable" -O "2006-03-03_10:46:08_NBP_allele__update"

Variation : "tm1001" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1002" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_10:46:08_NBP_allele__update" Phenotype_remark -O "2006-03-03_10:46:08_NBP_allele__update" "homozygous viable" -O "2006-03-03_10:46:08_NBP_allele__update"

Variation : "tm1003" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_10:46:08_NBP_allele__update" Phenotype_remark -O "2006-03-03_10:46:08_NBP_allele__update" "homozygous viable" -O "2006-03-03_10:46:08_NBP_allele__update"

Variation : "tm1004" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_10:46:08_NBP_allele__update" Phenotype_remark -O "2006-03-03_10:46:08_NBP_allele__update" "homozygous viable" -O "2006-03-03_10:46:08_NBP_allele__update"

Variation : "tm1005" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1006" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1007" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1008" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1009" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1010" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1011" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1012" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1013" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1014" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1015" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1016" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. C.L. Creasy: fertile, normal locomotion, normal egg-laying, solitary social feeding." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1017" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1018" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozyogous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1020" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1021" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. R. Plasterk: Genes &amp\; Dev. 19, 782- (2005)." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1022" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. K. Ashrafi: wild type fat (nile red staining)." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1023" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1024" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1025" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1026" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1027" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1028" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1029" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1030" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1031" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1032" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homzygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1033" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. K. Ashrafi: moderately increased fat (nile red staining)." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1035" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1036" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1037" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. G. Ruvkun: elevation of Nile Red staining." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1038" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1040" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1041" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1042" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1043" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1044" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_10:46:08_NBP_allele__update" Phenotype_remark -O "2006-03-03_10:46:08_NBP_allele__update" "homozygous viable" -O "2006-03-03_10:46:08_NBP_allele__update"

Variation : "tm1045" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1046" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. J. Satterlee: normal brood size, development and movement." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1047" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1048" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1049" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. K. Shen: Normal HSN vulval presynaptic vesicle clusters (unc-86::SNB-1::YFP), no obvious egg laying defects." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1050" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1051" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1052" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable, Dr. C. Rongo: normal GLR-1::GFP expression." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1054" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1055" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1056" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. A. Antebi: normal gonadal migration." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1057" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1058" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1059" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1060" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1061" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_10:46:08_NBP_allele__update" Phenotype_remark -O "2006-03-03_10:46:08_NBP_allele__update" "homozygous viable" -O "2006-03-03_10:46:08_NBP_allele__update"

Variation : "tm1062" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1063" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1064" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1066" -O "2004-03-23_12:06:39_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1067" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1068" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1069" -O "2004-02-27_12:08:54_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1070" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. K. Ashrafi: moderately increased fat (nile red staining). Dr. Y. Jin: could not find any phenotype." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1071" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. A. Singson: Curr. Biol.15, 2222-2229 (2005)" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1073" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. P. Sengupta: dyf+ in all sensory neurons." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1075" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1076" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1077" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1078" -O "2004-02-27_12:08:54_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1079" -O "2004-07-15_09:29:11_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. R.H. Horvitz: No extra cells in anterior pharynx. Dr. S. Shaham: no defects in somatic cell death." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1080" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1081" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1082" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1083" -O "2004-03-23_12:06:39_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. R. Plasterk: no obvious abnormal phenotype." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1084" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. T. Burglin: Dev. Biol. 290, 323-336 (2006)." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1085" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1086" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile. Dr. S. Boulton: Mol Cell Biol  25, 3127-3139 (2005)" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1087" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. H. Arai: WT (brood size, embryonic lethality, larval lethality and growth rate)." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1088" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1089" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1091" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1092" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1093" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1095" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. H.C. Korswagen: enhances the pry-1 (mu38) phenotype, axon guidance and excretory cell developmental defect." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1096" -O "2004-04-30_10:53:50_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1097" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1098" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1099" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. K. Shen: HSN presynaptic vesicle localization normal." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1100" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1101" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1102" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. A. Dernburg: does not alleviate cosuppression in the germline." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1103" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1104" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile. Dr. S. Shaham: no apparant defects in amphid denedrite structure." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1105" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1106" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. M. Barr: PKD-2::GFP expression=WT." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1107" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1108" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1109" -O "2005-09-27_09:57:33_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1110" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1111" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. C. Bargmann: Genes &amp\; Dev.19, 270-281, 2005." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1112" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1114" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1117" -O "2004-04-30_10:53:50_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. P. Morgan: mRNA is detectable." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1118" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1121" -O "2004-06-03_15:08:27_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1123" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1124" -O "2004-09-14_10:32:51_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1125" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. G. Herman: unable to score because of inviablity." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1126" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1128" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1129" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. H. Inoue: healthy, normal locomotion, normal response to touch and tap stimuli., Dr. J. Kaplan: WT aldicarb response." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1130" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1131" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1132" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1133" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1134" -O "2004-02-27_12:08:54_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. P. Okkema: wild-type growth and no obvious defects." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1136" -O "2004-03-23_12:06:39_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable, Dr. C. Rongo: normal. GLR-1::GFP expression. Dr. K.Shen: Normal HSN vulval presynaptic vesicle clusters (unc-86::SNB-1::YFP), no obvious egg laying defects." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1137" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1138" -O "2004-03-23_12:06:39_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1139" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1140" -O "2004-03-23_12:06:39_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1141" -O "2004-03-23_12:06:39_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1143" -O "2004-02-27_12:08:54_NBP_allele"
Description	 -O "2006-03-03_10:46:08_NBP_allele__update" Phenotype_remark -O "2006-03-03_10:46:08_NBP_allele__update" "homozygous viable" -O "2006-03-03_10:46:08_NBP_allele__update"

Variation : "tm1145" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. A. Dernburg: nonHim, normal meiosis." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1146" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1147" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1148" -O "2004-02-12_13:57:16_NBP_allele"
Description	 -O "2006-03-03_10:46:08_NBP_allele__update" Phenotype_remark -O "2006-03-03_10:46:08_NBP_allele__update" "homozygous viable. Dr. H. Inoue: healthy, fertile, normal locomotion. Expression of the C08B11.7 gene was detected by RT-PCR." -O "2006-03-03_10:46:08_NBP_allele__update"

Variation : "tm1149" -O "2004-03-23_12:06:39_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1150" -O "2004-03-23_12:06:39_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1151" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1153" -O "2006-01-25_14:22:46_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1154" -O "2004-04-30_10:53:50_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1156" -O "2005-04-29_12:55:01_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1157" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1158" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1161" -O "2004-03-23_12:06:39_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1164" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1165" -O "2004-03-23_12:06:39_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. C.L. Creasy: fertile, normal locomotion, normal egg-laying, solitary social feeding." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1166" -O "2004-03-23_12:06:39_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1167" -O "2004-03-23_12:06:39_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. M. Maduro: normal early embryogenesis at 4-30 cell stage." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1168" -O "2004-02-27_12:08:54_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1169" -O "2004-04-30_10:53:50_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1170" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1171" -O "2004-03-23_12:06:39_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1172" -O "2004-02-27_12:08:54_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1173" -O "2004-02-27_12:08:54_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1174" -O "2004-02-27_12:08:54_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1175" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1176" -O "2004-03-23_12:06:39_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. H. Arai: WT (Brood size, embryonic lethality, larvar lehtality, growth rate)" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1178" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1179" -O "2004-02-27_12:08:54_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1180" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1181" -O "2004-03-23_12:06:39_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1182" -O "2006-03-03_11:10:00_NBP_allele__update"
Description	 -O "2006-03-03_11:10:00_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:10:00_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:10:00_NBP_allele__update"

Variation : "tm1185" -O "2004-03-23_12:06:39_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1187" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1188" -O "2004-04-30_10:53:50_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1189" -O "2004-03-23_12:06:39_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. H. Arai: WT (brood size, embryonic lethality, larval lethality and growth rate)." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1190" -O "2004-03-23_12:06:39_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1191" -O "2004-03-23_12:06:39_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1192" -O "2004-03-23_12:06:39_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1193" -O "2004-03-23_12:06:39_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1194" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_10:46:08_NBP_allele__update" Phenotype_remark -O "2006-03-03_10:46:08_NBP_allele__update" "lethal or sterile" -O "2006-03-03_10:46:08_NBP_allele__update"

Variation : "tm1197" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1199" -O "2006-03-03_11:10:00_NBP_allele__update"
Description	 -O "2006-03-03_11:10:00_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:10:00_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:10:00_NBP_allele__update"

Variation : "tm1201" -O "2004-04-30_10:53:50_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1203" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1204" -O "2004-03-23_12:06:39_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. J. Ahringer: non-Egl." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1205" -O "2004-03-23_12:06:39_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1206" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1208" -O "2004-04-30_10:53:50_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1209" -O "2004-04-30_10:53:50_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1210" -O "2004-03-23_12:06:39_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. C.L. Creasy: fertile, normal locomotion, normal egg-laying, solitary social feeding." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1211" -O "2004-03-23_12:06:39_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1212" -O "2004-03-23_12:06:39_NBP_allele"
Description	 -O "2006-03-03_10:46:08_NBP_allele__update" Phenotype_remark -O "2006-03-03_10:46:08_NBP_allele__update" "homozygous viable" -O "2006-03-03_10:46:08_NBP_allele__update"

Variation : "tm1214" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_10:46:08_NBP_allele__update" Phenotype_remark -O "2006-03-03_10:46:08_NBP_allele__update" "homozygous viable" -O "2006-03-03_10:46:08_NBP_allele__update"

Variation : "tm1216" -O "2004-04-30_10:53:50_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1217" -O "2005-09-21_11:08:15_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1218" -O "2004-04-30_10:53:50_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1219" -O "2004-05-24_11:48:27_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1220" -O "2004-05-24_11:48:27_NBP_allele"
Description	 -O "2006-03-03_10:46:08_NBP_allele__update" Phenotype_remark -O "2006-03-03_10:46:08_NBP_allele__update" "homozygous viable" -O "2006-03-03_10:46:08_NBP_allele__update"

Variation : "tm1221" -O "2004-05-24_11:48:27_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1222" -O "2004-05-24_11:48:27_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1223" -O "2004-03-23_12:06:39_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1224" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1225" -O "2004-03-23_12:06:39_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1226" -O "2004-05-24_11:48:27_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1227" -O "2004-04-30_10:53:50_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile. Dr. M. Han: early larval lethal. Dr. R. Plasterk: homozygous inviable and experiments terminated." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1228" -O "2004-04-30_10:53:50_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1230" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1231" -O "2004-04-30_10:53:50_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1232" -O "2004-03-23_12:06:39_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1233" -O "2004-03-23_12:06:39_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. K. Shen: HSN presynaptic vesicle localization normal.  HSN presynaptic components (syd-2, syd-1, GIT-1, SAD-1) localization normal. Dr. Y. Jin: same as reported by Denken et al.(2005)." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1234" -O "2004-07-15_09:29:11_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1235" -O "2004-05-24_11:48:27_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1236" -O "2004-04-30_10:53:50_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1237" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1238" -O "2004-04-30_10:53:50_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. H. Sawa: Dpy, fertile, low brood size., 16\%Psa, very weak Muv (2\%)." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1239" -O "2004-04-30_10:53:50_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. M. Maduro: normal early embryogenesis at 4-30 cell stage." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1240" -O "2004-07-01_10:12:36_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1241" -O "2004-04-30_10:53:50_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1242" -O "2004-04-30_10:53:50_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. H. Arai: WT (Brood size, embryonic lethality, larvar lehtality, growth rate)" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1243" -O "2004-04-30_10:53:50_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1244" -O "2004-04-30_10:53:50_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1245" -O "2004-06-15_16:55:15_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1246" -O "2004-04-30_10:53:50_NBP_allele"
Description	 -O "2006-03-03_10:46:08_NBP_allele__update" Phenotype_remark -O "2006-03-03_10:46:08_NBP_allele__update" "homozygous viable" -O "2006-03-03_10:46:08_NBP_allele__update"

Variation : "tm1247" -O "2004-04-30_10:53:50_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1248" -O "2004-05-24_11:48:27_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. H. Arai: WT (Brood size, embryonic lethality, larval lethality, growth rate)." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1249" -O "2004-04-30_10:53:50_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1251" -O "2004-04-30_10:53:50_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1252" -O "2004-04-30_10:53:50_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1253" -O "2004-06-03_15:08:27_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1255" -O "2004-04-30_10:53:50_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1256" -O "2004-04-30_10:53:50_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1257" -O "2004-04-30_10:53:50_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1258" -O "2004-04-30_10:53:50_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile.  Dr. L. Avery: Partial loss of M4 function, reduced feeding efficiency.  Homozygous viable but slow-growing on E coli DA837.  Grows better on E coli HB101 or Comamonas." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1259" -O "2004-04-30_10:53:50_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1260" -O "2004-05-24_11:48:27_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1261" -O "2004-05-24_11:48:27_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1262" -O "2004-05-24_11:48:27_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1263" -O "2004-04-30_10:53:50_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1265" -O "2004-05-24_11:48:27_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1266" -O "2004-04-30_10:53:50_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1267" -O "2004-05-24_11:48:27_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1268" -O "2004-05-24_11:48:27_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1269" -O "2004-04-30_10:53:50_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1270" -O "2004-06-15_16:55:15_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1271" -O "2004-04-30_10:53:50_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1273" -O "2004-04-30_10:53:50_NBP_allele"
Description	 -O "2006-03-03_10:46:08_NBP_allele__update" Phenotype_remark -O "2006-03-03_10:46:08_NBP_allele__update" "homozygous viable" -O "2006-03-03_10:46:08_NBP_allele__update"

Variation : "tm1274" -O "2004-04-30_10:53:50_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. M. Barr: wild-type pkd-2::gfp expression." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1275" -O "2004-04-30_10:53:50_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1276" -O "2004-04-30_10:53:50_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. J. Satterlee: reduced brood size, more severe at 25 degree. Prodruded vulva. Dr. K.L. Chow: truncated protein of 233 aa. Ray patterning defects (fusion), protruding vulva and slightly small animal. Dr. J. Ahringer: non-Pvl." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1277" -O "2004-04-30_10:53:50_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1278" -O "2004-04-30_10:53:50_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1279" -O "2004-04-30_10:53:50_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1280" -O "2004-04-30_10:53:50_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1281" -O "2004-05-24_11:48:27_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1282" -O "2004-05-24_11:48:27_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1283" -O "2004-05-24_11:48:27_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1284" -O "2004-05-24_11:48:27_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1285" -O "2004-04-30_10:53:50_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1286" -O "2004-05-24_11:48:27_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1287" -O "2004-05-24_11:48:27_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. H. Inoue: Healthy, fertile, normal growth rate, normal locomotion, normal response to touch and tap stimuli." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1288" -O "2004-06-03_15:08:27_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1289" -O "2004-05-24_11:48:27_NBP_allele"
Description	 -O "2006-03-03_10:46:08_NBP_allele__update" Phenotype_remark -O "2006-03-03_10:46:08_NBP_allele__update" "lethal or sterile" -O "2006-03-03_10:46:08_NBP_allele__update"

Variation : "tm1290" -O "2004-05-24_11:48:27_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1291" -O "2004-05-24_11:48:27_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1294" -O "2004-05-24_11:48:27_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1295" -O "2004-05-24_11:48:27_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1297" -O "2004-05-24_11:48:27_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. R. Plasterk: reduced brood size, sterile at 25C." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1298" -O "2004-05-24_11:48:27_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. H-S. Koo: bag of worms, slow larval growth.  Early embryos are slightly more sensitive to ionizing radiation but germ cells show higher resistance to ionizing radiation." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1299" -O "2004-04-30_10:53:50_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. J. Satterlee: normal brood size, development and movement." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1300" -O "2004-05-24_11:48:27_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1301" -O "2004-05-24_11:48:27_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1302" -O "2004-05-24_11:48:27_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. Y. Jin: no behavioral phenotype found." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1303" -O "2004-05-24_11:48:27_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1304" -O "2004-05-24_11:48:27_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. G. Ruvkun: strongly enhances the penetrance of entry into a supernumerary molt of let-7(mg279). It also weakly enhances the retarded seam cell division phenotypes of let-7(n2853) and daf-12(RNAi)." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1305" -O "2004-05-24_11:48:27_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1307" -O "2004-05-24_11:48:27_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1308" -O "2004-06-15_16:55:15_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1309" -O "2004-07-01_10:12:36_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1310" -O "2004-06-03_15:08:27_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1312" -O "2006-03-03_11:10:00_NBP_allele__update"
Description	 -O "2006-03-03_11:10:00_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:10:00_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:10:00_NBP_allele__update"

Variation : "tm1313" -O "2004-05-24_11:48:27_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1316" -O "2004-06-03_15:08:27_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1318" -O "2004-05-24_11:48:27_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1320" -O "2004-05-24_11:48:27_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. G. Hermann: WT gut granules. Dr. H.C. Korswagen: QL and QR daughter cells, HSN migration defects, polarity of V5 division defects, similar to egl-20." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1321" -O "2004-05-24_11:48:27_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1322" -O "2004-05-24_11:48:27_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile. Dr. H.C. Korswagen: enhances the pry-1 (mu38) phenotype, axon guidance and excretory cell developmental defect." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1323" -O "2004-05-24_11:48:27_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1325" -O "2004-06-15_16:55:15_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. R. Komuniecki: Genetics in press" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1326" -O "2004-05-24_11:48:27_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1327" -O "2004-05-24_11:48:27_NBP_allele"
Description	 -O "2006-03-03_10:46:08_NBP_allele__update" Phenotype_remark -O "2006-03-03_10:46:08_NBP_allele__update" "homozygous viable" -O "2006-03-03_10:46:08_NBP_allele__update"

Variation : "tm1328" -O "2004-07-01_10:12:36_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1329" -O "2004-07-15_09:29:11_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. R. Plasterk: extracts are proficient for in vitro Dicer activity." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1331" -O "2004-05-24_11:48:27_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1333" -O "2004-05-24_11:48:27_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1335" -O "2004-06-03_15:08:27_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1336" -O "2004-06-03_15:08:27_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1338" -O "2004-05-24_11:48:27_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1339" -O "2006-03-03_11:10:00_NBP_allele__update"
Description	 -O "2006-03-03_11:10:00_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:10:00_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:10:00_NBP_allele__update"

Variation : "tm1340" -O "2004-07-15_09:29:11_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1341" -O "2004-05-24_11:48:27_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. A. Dernburg: does not alleviate cosuppression in the germline." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1343" -O "2004-06-03_15:08:27_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. A. Antebi: normal gonadal migration." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1344" -O "2004-06-03_15:08:27_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1345" -O "2004-06-03_15:08:27_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1346" -O "2004-07-15_09:29:11_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1347" -O "2004-06-03_15:08:27_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1348" -O "2004-06-03_15:08:27_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. S. Shaham: no observed defect in amphid structure or function." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1349" -O "2004-06-03_15:08:27_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1350" -O "2004-06-03_15:08:27_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile. Dr. M. Han: early larval lethal." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1351" -O "2004-06-03_15:08:27_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1352" -O "2004-06-03_15:08:27_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1353" -O "2004-06-03_15:08:27_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. M. Driscoll: normal in regard to growth, locomotion, brood size." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1354" -O "2004-06-03_15:08:27_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1357" -O "2004-06-03_15:08:27_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. J. Ahringer: weak Egl, sluggish." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1358" -O "2004-06-03_15:08:27_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1359" -O "2004-06-03_15:08:27_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1361" -O "2005-09-21_11:08:15_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1362" -O "2004-06-03_15:08:27_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozyous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1363" -O "2004-06-15_16:55:15_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1364" -O "2004-06-03_15:08:27_NBP_allele"
Description	 -O "2006-03-03_10:46:08_NBP_allele__update" Phenotype_remark -O "2006-03-03_10:46:08_NBP_allele__update" "homozygous viable. Dr. M. Maduro: normal early development (8-30 cell stage)." -O "2006-03-03_10:46:08_NBP_allele__update"

Variation : "tm1365" -O "2004-06-15_16:55:15_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1366" -O "2004-06-15_16:55:15_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1367" -O "2004-06-03_15:08:27_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1368" -O "2004-06-15_16:55:15_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. M. Driscoll: No effect found on necrotic cell death." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1369" -O "2004-06-15_16:55:15_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1370" -O "2004-07-01_10:12:36_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile. Dr. O. Hobert: could not test nerotransmission phenotype due to lethality." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1371" -O "2004-07-01_10:12:36_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. M. Maduro: normal early development (8-30 cell stage)." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1372" -O "2004-06-15_16:55:15_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1373" -O "2004-06-15_16:55:15_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1374" -O "2004-06-03_15:08:27_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. J. Satterlee: suppress Huntington Q150 neuronal degenration in ASH neurons." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1375" -O "2004-07-01_10:12:36_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1376" -O "2004-06-15_16:55:15_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1377" -O "2004-06-15_16:55:15_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1378" -O "2004-06-15_16:55:15_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1380" -O "2004-07-01_10:12:36_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1381" -O "2004-06-15_16:55:15_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1382" -O "2004-06-15_16:55:15_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1383" -O "2004-06-15_16:55:15_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1384" -O "2004-06-15_16:55:15_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1385" -O "2004-07-01_10:12:36_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1386" -O "2004-07-01_10:12:36_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1387" -O "2004-07-01_10:12:36_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1388" -O "2004-06-15_16:55:15_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1389" -O "2004-06-15_16:55:15_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1390" -O "2004-07-01_10:12:36_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1391" -O "2004-07-01_10:12:36_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1393" -O "2004-06-15_16:55:15_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1395" -O "2004-06-15_16:55:15_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1396" -O "2004-07-01_10:12:36_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1397" -O "2004-07-01_10:12:36_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1398" -O "2004-07-01_10:12:36_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1399" -O "2004-07-01_10:12:36_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1400" -O "2004-07-01_10:12:36_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1401" -O "2004-07-01_10:12:36_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1402" -O "2004-06-15_16:55:15_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1403" -O "2004-07-01_10:12:36_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. W. Schafer: fertile, locomotion grossly normal." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1404" -O "2004-07-15_09:29:11_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1405" -O "2004-07-01_10:12:36_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1406" -O "2004-07-01_10:12:36_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. C.L. Creasy: fertile, normal locomotion, normal egg-laying, solitary social feeding." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1407" -O "2004-07-01_10:12:36_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1408" -O "2004-07-01_10:12:36_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1409" -O "2004-07-01_10:12:36_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1410" -O "2004-07-15_09:29:11_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1411" -O "2004-07-01_10:12:36_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1412" -O "2004-07-01_10:12:36_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1416" -O "2004-07-01_10:12:36_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1417" -O "2004-07-01_10:12:36_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1418" -O "2004-07-01_10:12:36_NBP_allele"
Description	 -O "2006-03-03_10:46:08_NBP_allele__update" Phenotype_remark -O "2006-03-03_10:46:08_NBP_allele__update" "homozygous viable" -O "2006-03-03_10:46:08_NBP_allele__update"

Variation : "tm1419" -O "2004-07-01_10:12:36_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1420" -O "2004-09-14_10:32:51_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1421" -O "2004-07-01_10:12:36_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1422" -O "2004-07-15_09:29:11_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1424" -O "2004-09-14_10:32:51_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1425" -O "2004-07-01_10:12:36_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1426" -O "2004-07-15_09:29:11_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1427" -O "2004-07-15_09:29:11_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1428" -O "2004-07-15_09:29:11_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1429" -O "2004-07-15_09:29:11_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1430" -O "2004-07-01_10:12:36_NBP_allele"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1431" -O "2004-07-15_09:29:11_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1432" -O "2004-07-01_10:12:36_NBP_allele"
Description	 -O "2006-03-03_10:46:08_NBP_allele__update" Phenotype_remark -O "2006-03-03_10:46:08_NBP_allele__update" "lethal or sterile" -O "2006-03-03_10:46:08_NBP_allele__update"

Variation : "tm1433" -O "2004-07-15_09:29:11_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1434" -O "2004-09-14_10:32:51_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1436" -O "2004-07-15_09:29:11_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1437" -O "2004-12-24_11:20:13_NBP_allele_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1438" -O "2006-03-03_11:10:00_NBP_allele__update"
Description	 -O "2006-03-03_11:10:00_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:10:00_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:10:00_NBP_allele__update"

Variation : "tm1439" -O "2004-09-14_10:32:51_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1440" -O "2004-07-15_09:29:11_krb"
Description	 -O "2006-03-03_10:46:08_NBP_allele__update" Phenotype_remark -O "2006-03-03_10:46:08_NBP_allele__update" "homozygous viable" -O "2006-03-03_10:46:08_NBP_allele__update"

Variation : "tm1441" -O "2006-01-19_13:44:55_NBP_ALLELE_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1442" -O "2004-07-15_09:29:11_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1443" -O "2006-03-03_10:46:08_NBP_allele__update"
Description	 -O "2006-03-03_10:46:08_NBP_allele__update" Phenotype_remark -O "2006-03-03_10:46:08_NBP_allele__update" "lethal or sterile" -O "2006-03-03_10:46:08_NBP_allele__update"

Variation : "tm1444" -O "2004-07-15_09:29:11_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1445" -O "2004-07-15_09:29:11_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1446" -O "2004-09-14_10:32:51_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable.  Low touch sensitivity at anterior body." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1447" -O "2004-09-14_10:32:51_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. M. Han: WT vulval development, slow growth and WT touch response. Dr. K. Shen: Normal HSN vulval presynaptic vesicle clusters (unc-86::SNB-1::YFP), no obvious egg laying defects. Dr. Y. Jin: could not maintain as homozygote." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1448" -O "2004-07-15_09:29:11_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "Lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1449" -O "2004-07-15_09:29:11_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1450" -O "2004-07-15_09:29:11_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile. Dr. M. Han: early larval lethal. Dr. A. Dernburg: no obvious role in meiosis." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1451" -O "2004-09-14_10:32:51_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1452" -O "2004-09-14_10:32:51_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. C. Kenyon: reduced progeny and slightly delayed development." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1453" -O "2004-09-14_10:32:51_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1454" -O "2004-09-14_10:32:51_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1455" -O "2004-07-15_09:29:11_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1456" -O "2004-12-06_16:32:12_NBP_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1457" -O "2004-07-15_09:29:11_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1458" -O "2004-07-15_09:29:11_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. A. Dernburg: Science 310, 1683-1686 (2005)." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1459" -O "2004-07-15_09:29:11_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1460" -O "2004-09-14_10:32:51_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1463" -O "2004-09-14_10:32:51_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1464" -O "2004-09-14_10:32:51_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1465" -O "2004-09-14_10:32:51_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. Y. Jin: J. Neurosci. 25, 7517-7528 (2005)" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1466" -O "2004-09-14_10:32:51_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. D.M. Miller: no locomotory perturbations. Dr. M. Driscoll: no effect on necrotic cell death. Dr. K. Shen: normal DA presynaptic puncta." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1467" -O "2004-09-14_10:32:51_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. K. Ashrafi: wild type fat (nile red staining)." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1468" -O "2004-09-14_10:32:51_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1469" -O "2004-09-14_10:32:51_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1471" -O "2004-09-14_10:32:51_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1473" -O "2004-09-14_10:32:51_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1474" -O "2004-09-14_10:32:51_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1475" -O "2004-09-14_10:32:51_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. D.M. Miller: no locomotory perturbations. Dr. P. Sengupta: Dyf+ in all sensory neurons." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1476" -O "2004-09-14_10:32:51_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1477" -O "2004-09-14_10:32:51_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1478" -O "2004-09-14_10:32:51_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. D.M. Miller: no locomotory perturbations." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1479" -O "2004-09-14_10:32:51_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "Homozygous viable. Dr. A. Dernburg: does not remove CDS, results in a weak loss-of-function, low level of embryonic leathality." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1480" -O "2004-09-14_10:32:51_krb"
Description	 -O "2006-03-03_10:46:08_NBP_allele__update" Phenotype_remark -O "2006-03-03_10:46:08_NBP_allele__update" "homozygous viable" -O "2006-03-03_10:46:08_NBP_allele__update"

Variation : "tm1481" -O "2004-09-14_10:32:51_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1482" -O "2004-09-14_10:32:51_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1483" -O "2004-09-14_10:32:51_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1484" -O "2004-09-14_10:32:51_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1485" -O "2004-09-14_10:32:51_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile. Dr. P. Sengupta: dyf+ in all sensory neurons. Dr. K. Shen: unable to examine HSN synaptic phenotypes.  Rare escapers show normal HSN vulaval presynaptic vesicle cluslters (unc-86::SNB-1::YFP)." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1486" -O "2004-09-14_10:32:51_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile. Dr. R.H. Horvitz: could not recover mutants. Dr. Y. Jin: could not maintain as homozygote." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1487" -O "2004-09-14_10:32:51_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1488" -O "2004-09-14_10:32:51_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1489" -O "2004-09-14_10:32:51_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. R.H. Horvitz: not completely penetrant multivulva and sterile at 25 degree, synthetic multivulva with mutations in class A, B and C genes." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1490" -O "2004-09-14_10:32:51_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1491" -O "2004-09-14_10:32:51_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1492" -O "2004-09-14_10:32:51_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or strile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1493" -O "2004-09-14_10:32:51_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. D.M. Miller: no locomotory perturbations." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1494" -O "2004-12-06_16:32:12_NBP_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. M. Maduro: normal early development (8-30 cell stage)." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1495" -O "2004-09-14_10:32:51_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1496" -O "2005-09-21_11:08:15_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1497" -O "2004-12-06_16:32:12_NBP_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1498" -O "2004-09-14_10:32:51_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. L. Avery: feeding and satiety behavior normal." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1499" -O "2004-09-14_10:32:51_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1500" -O "2004-09-14_10:32:51_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. P. Sengupta: dyf+ in all sensory neurons." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1501" -O "2004-09-14_10:32:51_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1502" -O "2004-09-14_10:32:51_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile. Dr. J. Liu &amp\; Dr. Y. Gruenbaum: Proc Natl Acad Sci U S A102, 16690-16695 (2005)" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1503" -O "2004-09-14_10:32:51_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. P. Sengupta: Dyf+ in all sensory neurons." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1504" -O "2004-09-14_10:32:51_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. L. Avery: feeding and satiety behavior normal." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1505" -O "2004-09-14_10:32:51_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. W. Schafer: fertile, locomotion grossly normal." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1506" -O "2004-09-14_10:32:51_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. H. Arai: WT (brood size, embryonic lethality, larval lethality and growth rate)." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1507" -O "2004-12-06_16:32:12_NBP_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. M. Driscoll: No effect found on necrotic cell death." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1508" -O "2004-09-14_10:32:51_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1509" -O "2004-09-14_10:32:51_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1510" -O "2004-09-14_10:32:51_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1511" -O "2004-09-14_10:32:51_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1512" -O "2004-09-14_10:32:51_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. Y. Jin: normal behavior." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1513" -O "2004-09-14_10:32:51_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1514" -O "2004-09-14_10:32:51_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1516" -O "2004-09-14_10:32:51_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1517" -O "2004-09-14_10:32:51_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. G. Ruvkun: normal growth, normal dauer formation." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1518" -O "2004-09-14_10:32:51_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. M. Driscoll: no effect on necrotic cell death." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1520" -O "2004-09-14_10:32:51_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. F. Slack: wild type heterochronic phenotype." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1521" -O "2004-09-14_10:32:51_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1523" -O "2004-09-14_10:32:51_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile. Dr. H.C. Korswagen: QL and QR daughter cells, HSN migration defects, polarity of V5 division defects, similar to egl-20." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1524" -O "2004-09-14_10:32:51_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozyous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1525" -O "2004-09-14_10:32:51_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1526" -O "2004-12-06_16:32:12_NBP_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. S. Shaham: no defects in somatic cell death." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1527" -O "2004-09-14_10:32:51_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. M. Sundaram: deletion in the intron, wild-type." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1528" -O "2004-09-14_10:32:51_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1529" -O "2004-09-14_10:32:51_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1530" -O "2004-09-14_10:32:51_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1531" -O "2004-09-14_10:32:51_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1532" -O "2004-09-14_10:32:51_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1533" -O "2004-09-14_10:32:51_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1534" -O "2004-09-14_10:32:51_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1535" -O "2004-12-06_16:32:12_NBP_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. R. Sommer: no major disruptions in the reading frame." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1537" -O "2004-12-06_16:32:12_NBP_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1538" -O "2004-12-06_16:32:12_NBP_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1539" -O "2004-12-06_16:32:12_NBP_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1540" -O "2004-12-06_16:32:12_NBP_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1541" -O "2004-12-06_16:32:12_NBP_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile. Dr. K. Shen: unable to examine HSN synaptic phenotypes." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1542" -O "2004-09-14_10:32:51_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1544" -O "2004-12-06_16:32:12_NBP_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1545" -O "2004-09-14_10:32:51_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1546" -O "2004-12-06_16:32:12_NBP_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1547" -O "2004-12-06_16:32:12_NBP_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1548" -O "2004-12-06_16:32:12_NBP_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile. Dr. L. Avery: homozygous viable (x10 outcrossed), superficially normal.  10 mM serotonin fails to stimulate rapid pharyngeal pumping." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1550" -O "2004-09-14_10:32:51_krb"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1552" -O "2004-12-06_16:32:12_NBP_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1553" -O "2004-12-06_16:32:12_NBP_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. L. Avery: feeding and satiety behavior normal." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1554" -O "2004-12-24_11:20:13_NBP_allele_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1555" -O "2004-12-06_16:32:12_NBP_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "Homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1556" -O "2004-12-06_16:32:12_NBP_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1557" -O "2004-12-06_16:32:12_NBP_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1558" -O "2004-12-06_16:32:12_NBP_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1559" -O "2004-12-06_16:32:12_NBP_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1561" -O "2004-12-06_16:32:12_NBP_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1564" -O "2004-12-06_16:32:12_NBP_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1565" -O "2004-12-06_16:32:12_NBP_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1566" -O "2004-12-24_11:20:13_NBP_allele_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1567" -O "2004-12-06_16:32:12_NBP_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. H. Arai: WT (brood size, embryonic lethality, larval lethality and growth rate)." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1568" -O "2004-12-06_16:32:12_NBP_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1569" -O "2006-03-03_11:10:00_NBP_allele__update"
Description	 -O "2006-03-03_11:10:00_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:10:00_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:10:00_NBP_allele__update"

Variation : "tm1570" -O "2004-12-06_16:32:12_NBP_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. M. Driscoll: No effect found on necrotic cell death." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1571" -O "2004-12-06_16:32:12_NBP_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. M. Driscoll: no effect on necrotic cell death." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1572" -O "2004-12-06_16:32:12_NBP_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozyogous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1573" -O "2004-12-24_11:20:13_NBP_allele_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1575" -O "2006-03-03_11:10:00_NBP_allele__update"
Description	 -O "2006-03-03_11:10:00_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:10:00_NBP_allele__update" "Homozygous viable" -O "2006-03-03_11:10:00_NBP_allele__update"

Variation : "tm1576" -O "2004-12-07_10:51:33_NBP_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1577" -O "2004-12-24_11:20:13_NBP_allele_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1578" -O "2004-12-06_16:32:12_NBP_update"
Description	 -O "2006-03-03_10:46:08_NBP_allele__update" Phenotype_remark -O "2006-03-03_10:46:08_NBP_allele__update" "Homozygous viable" -O "2006-03-03_10:46:08_NBP_allele__update"

Variation : "tm1579" -O "2004-12-06_16:32:12_NBP_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1580" -O "2004-12-06_16:32:12_NBP_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1582" -O "2004-12-06_16:32:12_NBP_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1583" -O "2005-01-11_17:19:30_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1584" -O "2004-12-06_16:32:12_NBP_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. H. Arai: WT (brood size, embryonic lethality, larval lethality and growth rate)." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1585" -O "2004-12-07_10:51:33_NBP_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1586" -O "2004-12-06_16:32:12_NBP_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1588" -O "2004-12-07_10:51:33_NBP_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1589" -O "2004-12-07_10:51:33_NBP_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "slow growth. Dr. H. Sawa: Slow growth in larval stage, rare embryonic lehtality (2\/100)." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1590" -O "2004-12-07_10:51:33_NBP_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1591" -O "2004-12-06_16:32:12_NBP_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1594" -O "2006-01-25_14:22:46_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1595" -O "2005-01-11_17:19:30_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1596" -O "2004-12-24_11:20:13_NBP_allele_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1597" -O "2004-12-06_16:32:12_NBP_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "Homozygous viable. Dr. J. Ahringer: low percentage embryonic lethality and pvl (might be from side mutation)." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1598" -O "2004-12-06_16:32:12_NBP_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1600" -O "2004-12-07_10:51:33_NBP_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1601" -O "2004-12-06_16:32:12_NBP_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "Lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1602" -O "2004-12-06_16:32:12_NBP_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "Homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1603" -O "2004-12-06_16:32:12_NBP_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1605" -O "2004-12-24_11:20:13_NBP_allele_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1606" -O "2004-12-24_11:20:13_NBP_allele_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1607" -O "2004-12-06_16:32:12_NBP_update"
Description	 -O "2006-03-03_10:46:08_NBP_allele__update" Phenotype_remark -O "2006-03-03_10:46:08_NBP_allele__update" "homozygous viable" -O "2006-03-03_10:46:08_NBP_allele__update"

Variation : "tm1608" -O "2004-12-07_10:51:33_NBP_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1610" -O "2004-12-07_10:51:33_NBP_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1611" -O "2004-12-07_10:51:33_NBP_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1612" -O "2004-12-07_10:51:33_NBP_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1613" -O "2004-12-07_10:51:33_NBP_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "Homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1614" -O "2004-12-07_10:51:33_NBP_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "Homozygous viable. Dr. M. Driscoll: no effect on necrotic cell death." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1615" -O "2004-12-07_10:51:33_NBP_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile. Dr. H-S. Koo: larval arrest at the L3 stage." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1617" -O "2004-12-07_10:51:33_NBP_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1618" -O "2004-12-07_10:51:33_NBP_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1619" -O "2005-01-11_17:19:30_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1620" -O "2004-12-07_10:51:33_NBP_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1621" -O "2004-12-07_10:51:33_NBP_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1622" -O "2004-12-07_10:51:33_NBP_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. M. Driscoll: no effect on necrotic cell death." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1623" -O "2004-12-07_10:51:33_NBP_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1624" -O "2004-12-24_11:20:13_NBP_allele_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1625" -O "2004-12-07_10:51:33_NBP_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1626" -O "2004-12-07_10:51:33_NBP_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1628" -O "2006-01-19_13:44:55_NBP_ALLELE_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1629" -O "2004-12-24_11:20:13_NBP_allele_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1630" -O "2004-12-07_10:51:33_NBP_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1631" -O "2005-01-11_17:19:30_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1632" -O "2004-12-07_10:51:33_NBP_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1633" -O "2005-02-09_11:44:11_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1634" -O "2004-12-24_11:20:13_NBP_allele_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1635" -O "2005-01-11_17:19:30_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1636" -O "2005-01-11_17:19:30_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1638" -O "2004-12-24_11:20:13_NBP_allele_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1639" -O "2004-12-24_11:20:13_NBP_allele_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1640" -O "2004-12-24_11:20:13_NBP_allele_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1641" -O "2004-12-07_10:51:33_NBP_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1642" -O "2004-12-24_11:20:13_NBP_allele_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1643" -O "2005-01-11_17:19:30_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1645" -O "2004-12-24_11:20:13_NBP_allele_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1646" -O "2004-12-07_10:51:33_NBP_update"
Description	 -O "2006-03-03_10:46:08_NBP_allele__update" Phenotype_remark -O "2006-03-03_10:46:08_NBP_allele__update" "homozygous viable. Dr. M. Driscoll: no effect on necrotic cell death." -O "2006-03-03_10:46:08_NBP_allele__update"

Variation : "tm1647" -O "2005-01-11_17:19:30_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. W. Schafer: fertile, locomotion grossly normal." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1649" -O "2004-12-24_11:20:13_NBP_allele_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1650" -O "2004-12-24_11:20:13_NBP_allele_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1651" -O "2004-12-24_11:20:13_NBP_allele_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1652" -O "2004-12-24_11:20:13_NBP_allele_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. L. Avery: feeding and satiety behavior normal." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1653" -O "2004-12-24_11:20:13_NBP_allele_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1654" -O "2005-01-11_17:19:30_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1655" -O "2005-01-11_17:19:30_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1656" -O "2004-12-24_11:20:13_NBP_allele_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1657" -O "2005-01-11_17:19:30_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1658" -O "2004-12-24_11:20:13_NBP_allele_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1659" -O "2005-01-11_17:19:30_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1660" -O "2004-12-24_11:20:13_NBP_allele_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1661" -O "2004-12-24_11:20:13_NBP_allele_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. H. Sawa: Some die in embryonic stage (51\/100)." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1662" -O "2004-12-24_11:20:13_NBP_allele_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1663" -O "2005-01-11_17:19:30_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1664" -O "2004-12-24_11:20:13_NBP_allele_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1665" -O "2004-12-24_11:20:13_NBP_allele_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1666" -O "2004-12-24_11:20:13_NBP_allele_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1667" -O "2004-12-24_11:20:13_NBP_allele_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1670" -O "2005-02-09_11:44:11_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1671" -O "2005-01-11_17:19:30_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1673" -O "2006-01-25_14:22:46_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1675" -O "2005-01-11_17:19:30_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1676" -O "2005-01-11_17:19:30_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1677" -O "2005-01-11_17:19:30_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1678" -O "2005-01-11_17:19:30_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. J. Ahringer: non-Egl." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1679" -O "2005-01-11_17:19:30_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1680" -O "2005-01-11_17:19:30_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1681" -O "2005-01-11_17:19:30_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1682" -O "2005-01-11_17:19:30_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. M. Driscoll: no effect on necrotic cell death." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1683" -O "2005-01-11_17:19:30_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1684" -O "2005-02-09_11:44:11_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1686" -O "2005-01-11_17:19:30_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1687" -O "2005-01-11_17:19:30_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1688" -O "2005-01-11_17:19:30_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1689" -O "2005-01-11_17:19:30_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1690" -O "2005-03-01_13:51:16_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1691" -O "2005-01-11_17:19:30_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1692" -O "2005-01-11_17:19:30_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1693" -O "2005-01-11_17:19:30_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1694" -O "2005-02-09_11:44:11_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile. Dr. M. Han: early larval lethal, escapers are sterile." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1695" -O "2006-03-03_11:10:00_NBP_allele__update"
Description	 -O "2006-03-03_11:10:00_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:10:00_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:10:00_NBP_allele__update"

Variation : "tm1696" -O "2005-01-11_17:19:30_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1697" -O "2005-01-11_17:19:30_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1698" -O "2005-02-09_11:44:11_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1700" -O "2005-01-11_17:19:30_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. M. Driscoll: no effect on necrotic cell death." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1701" -O "2005-01-11_17:19:30_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1703" -O "2005-01-11_17:19:30_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. P. Sengupta: dyf+ in all sensory neurons." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1704" -O "2005-01-11_17:19:30_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. M. Driscoll: No effect found on necrotic cell death." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1705" -O "2005-09-21_11:08:15_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1706" -O "2005-01-11_17:19:30_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. W. Schafer: fertile, locomotion grossly normal." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1707" -O "2005-01-11_17:19:30_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1708" -O "2005-02-09_11:44:11_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1709" -O "2005-02-09_11:44:11_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1710" -O "2005-02-09_11:44:11_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile. Dr. M. Han: early larval lethal." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1711" -O "2005-01-11_17:19:30_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1712" -O "2005-01-11_17:19:30_mt3"
Description	 -O "2006-03-03_10:46:08_NBP_allele__update" Phenotype_remark -O "2006-03-03_10:46:08_NBP_allele__update" "homozygous viable" -O "2006-03-03_10:46:08_NBP_allele__update"

Variation : "tm1713" -O "2005-02-09_11:44:11_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1714" -O "2005-02-09_11:44:11_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1715" -O "2005-02-09_11:44:11_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1716" -O "2005-02-09_11:44:11_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1719" -O "2005-02-09_11:44:11_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1720" -O "2005-03-01_13:51:16_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1723" -O "2005-02-09_11:44:11_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1724" -O "2005-02-09_11:44:11_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1725" -O "2005-02-09_11:44:11_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1726" -O "2005-02-09_11:44:11_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1728" -O "2005-02-09_11:44:11_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. R. Komuniecki: Genetics in press." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1729" -O "2005-02-09_11:44:11_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1730" -O "2005-02-09_11:44:11_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1731" -O "2005-04-27_11:13:02_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1732" -O "2005-02-09_11:44:11_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1733" -O "2005-02-09_11:44:11_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1736" -O "2005-02-09_11:44:11_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1737" -O "2005-02-09_11:44:11_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1738" -O "2005-02-09_11:44:11_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1739" -O "2005-02-09_11:44:11_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1741" -O "2005-02-09_11:44:11_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1742" -O "2005-03-01_13:51:16_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1743" -O "2005-02-09_11:44:11_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. H. Sawa: Healthy, no obvious Psa phenotype." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1744" -O "2005-02-09_11:44:11_mt3"
Description	 -O "2006-03-03_10:46:08_NBP_allele__update" Phenotype_remark -O "2006-03-03_10:46:08_NBP_allele__update" "homozygous viable" -O "2006-03-03_10:46:08_NBP_allele__update"

Variation : "tm1745" -O "2005-02-09_11:44:11_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. P. Sengupta: dyf+ in all sensory neurons." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1746" -O "2005-03-01_13:51:16_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1747" -O "2005-02-09_11:44:11_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1748" -O "2005-02-09_11:44:11_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1749" -O "2005-02-09_11:44:11_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1750" -O "2005-02-09_11:44:11_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1751" -O "2005-02-09_11:44:11_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1752" -O "2005-02-09_11:44:11_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1753" -O "2005-02-09_11:44:11_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile. Dr. K. Oegema: J. Cell Biol.171, 267-279 (2005)." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1754" -O "2005-02-09_11:44:11_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1756" -O "2005-03-01_13:51:16_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1757" -O "2005-02-09_11:44:11_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1758" -O "2005-02-09_11:44:11_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1759" -O "2005-02-09_11:44:11_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1760" -O "2005-02-09_11:44:11_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1761" -O "2005-02-09_11:44:11_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1762" -O "2005-03-01_13:51:16_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1763" -O "2005-03-01_13:51:16_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1765" -O "2005-03-30_09:25:17_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1766" -O "2005-02-09_11:44:11_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. I. Mori: normal thermotaxis." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1767" -O "2005-02-09_11:44:11_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1768" -O "2005-02-09_11:44:11_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1769" -O "2005-03-01_13:51:16_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1770" -O "2005-02-09_11:44:11_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1771" -O "2005-03-01_13:51:16_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile. Dr. M. Han: early larval lethal." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1772" -O "2005-03-01_13:51:16_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1773" -O "2005-02-09_11:44:11_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1774" -O "2005-03-01_13:51:16_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1775" -O "2005-03-01_13:51:16_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1776" -O "2005-03-01_13:51:16_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1777" -O "2005-03-01_13:51:16_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1778" -O "2005-03-01_13:51:16_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1779" -O "2005-03-01_13:51:16_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1780" -O "2005-02-09_11:44:11_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1781" -O "2005-03-01_13:51:16_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1782" -O "2005-03-01_13:51:16_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. W. Schafer: fertile, locomotion grossly normal." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1783" -O "2005-03-01_13:51:16_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1784" -O "2005-03-01_13:51:16_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. K. Ashrafi: healthy, fertile and has altered fat content at L4 and adult stage." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1785" -O "2005-03-01_13:51:16_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1786" -O "2005-03-01_13:51:16_mt3"
Description	 -O "2006-03-03_10:46:08_NBP_allele__update" Phenotype_remark -O "2006-03-03_10:46:08_NBP_allele__update" "homozygous viable" -O "2006-03-03_10:46:08_NBP_allele__update"

Variation : "tm1787" -O "2005-03-01_13:51:16_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1788" -O "2005-03-30_09:25:17_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1789" -O "2005-03-01_13:51:16_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1790" -O "2005-03-01_13:51:16_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1791" -O "2005-03-01_13:51:16_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. M. Colaiacovo: affects the expression of both C03D6.6 and C03D6.5 genes." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1793" -O "2005-03-01_13:51:16_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1794" -O "2005-03-01_13:51:16_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1795" -O "2005-03-30_09:25:17_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1796" -O "2005-03-01_13:51:16_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1797" -O "2005-05-25_09:09:30_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1798" -O "2005-03-01_13:51:16_mt3"
Description	 -O "2006-03-03_10:46:08_NBP_allele__update" Phenotype_remark -O "2006-03-03_10:46:08_NBP_allele__update" "homozygous viable" -O "2006-03-03_10:46:08_NBP_allele__update"

Variation : "tm1799" -O "2005-03-01_13:51:16_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1800" -O "2005-03-30_09:25:17_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1801" -O "2005-03-01_13:51:16_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1802" -O "2005-03-01_13:51:16_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1803" -O "2005-03-30_09:25:17_mt3"
Description	 -O "2006-03-03_10:46:08_NBP_allele__update" Phenotype_remark -O "2006-03-03_10:46:08_NBP_allele__update" "homozygous viable" -O "2006-03-03_10:46:08_NBP_allele__update"

Variation : "tm1804" -O "2005-03-01_13:51:16_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1805" -O "2005-03-30_09:25:17_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1806" -O "2005-03-30_09:25:17_mt3"
Description	 -O "2006-03-03_10:46:08_NBP_allele__update" Phenotype_remark -O "2006-03-03_10:46:08_NBP_allele__update" "homozygous viable" -O "2006-03-03_10:46:08_NBP_allele__update"

Variation : "tm1807" -O "2005-03-01_13:51:16_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1808" -O "2005-03-30_09:25:17_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozyogous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1809" -O "2005-03-01_13:51:16_mt3"
Description	 -O "2006-03-03_10:46:08_NBP_allele__update" Phenotype_remark -O "2006-03-03_10:46:08_NBP_allele__update" "homozygous viable" -O "2006-03-03_10:46:08_NBP_allele__update"

Variation : "tm1810" -O "2005-03-01_13:51:16_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1811" -O "2005-03-01_13:51:16_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. I Mori: normal thermotaxis." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1812" -O "2005-03-30_09:25:17_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1813" -O "2005-03-30_09:25:17_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1814" -O "2005-03-30_09:25:17_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1815" -O "2005-03-01_13:51:16_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1816" -O "2005-03-01_13:51:16_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1817" -O "2005-03-30_09:25:17_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1818" -O "2005-03-30_09:25:17_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1819" -O "2005-03-30_09:25:17_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1820" -O "2005-03-30_09:25:17_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1821" -O "2005-03-01_13:51:16_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1822" -O "2005-03-30_09:25:17_mt3"
Description	 -O "2006-03-03_10:46:08_NBP_allele__update" Phenotype_remark -O "2006-03-03_10:46:08_NBP_allele__update" "homozygous viable" -O "2006-03-03_10:46:08_NBP_allele__update"

Variation : "tm1823" -O "2005-03-30_09:25:17_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1824" -O "2005-03-01_13:51:16_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. K. Ashrafi: healthy, fertile and has altered fat content at L4 and adult stage." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1825" -O "2005-03-30_09:25:17_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1826" -O "2005-03-30_09:25:17_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1827" -O "2005-03-30_09:25:17_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1828" -O "2005-03-30_09:25:17_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1829" -O "2005-03-30_09:25:17_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1830" -O "2005-03-30_09:25:17_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1831" -O "2005-04-27_11:13:02_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1832" -O "2005-04-27_11:13:02_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1833" -O "2005-03-30_09:25:17_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1834" -O "2005-03-30_09:25:17_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1835" -O "2005-04-27_11:13:02_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1836" -O "2005-04-27_11:13:02_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1837" -O "2005-03-30_09:25:17_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1838" -O "2005-03-30_09:25:17_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1839" -O "2005-04-27_11:13:02_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1840" -O "2005-03-30_09:25:17_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1841" -O "2005-04-27_11:13:02_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1842" -O "2005-03-30_09:25:17_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1843" -O "2005-04-27_11:13:02_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1844" -O "2005-04-27_11:13:02_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1845" -O "2005-04-27_11:13:02_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1846" -O "2005-04-27_11:13:02_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1847" -O "2005-04-27_11:13:02_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1848" -O "2005-04-27_11:13:02_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1849" -O "2005-04-27_11:13:02_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1850" -O "2005-04-27_11:13:02_mt3"
Description	 -O "2006-03-03_10:46:08_NBP_allele__update" Phenotype_remark -O "2006-03-03_10:46:08_NBP_allele__update" "homozygous viable" -O "2006-03-03_10:46:08_NBP_allele__update"

Variation : "tm1851" -O "2005-04-27_11:13:02_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1852" -O "2005-04-27_11:13:02_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1853" -O "2005-04-27_11:13:02_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1854" -O "2005-04-27_11:13:02_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1855" -O "2005-04-27_11:13:02_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1856" -O "2005-04-27_11:13:02_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1857" -O "2005-04-27_11:13:02_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1858" -O "2005-04-27_11:13:02_mt3"
Description	 -O "2006-03-03_10:46:08_NBP_allele__update" Phenotype_remark -O "2006-03-03_10:46:08_NBP_allele__update" "homozygous viable" -O "2006-03-03_10:46:08_NBP_allele__update"

Variation : "tm1861" -O "2005-04-27_11:13:02_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1862" -O "2005-04-27_11:13:02_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1863" -O "2005-04-27_11:13:02_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. M. Han: WT vulval development, WT growth, WT adult alae, WT touch response." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1864" -O "2005-04-27_11:13:02_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1865" -O "2005-04-27_11:13:02_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1866" -O "2005-05-25_09:09:30_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1867" -O "2005-04-27_11:13:02_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1868" -O "2005-04-27_11:13:02_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1869" -O "2005-04-27_11:13:02_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1870" -O "2005-04-27_11:13:02_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1871" -O "2005-04-27_11:13:02_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1872" -O "2005-05-25_09:09:30_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1873" -O "2005-05-25_09:09:30_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1874" -O "2005-04-27_11:13:02_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1875" -O "2005-06-22_16:36:07_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. C. Kenyon: grossly normal morphology and fertility, does not form dauer at 25C." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1876" -O "2005-04-27_11:13:02_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homoyzgous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1877" -O "2005-04-27_11:13:02_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1878" -O "2005-05-25_09:09:30_mt3"
Description	 -O "2006-03-03_10:46:08_NBP_allele__update" Phenotype_remark -O "2006-03-03_10:46:08_NBP_allele__update" "homozygous viable" -O "2006-03-03_10:46:08_NBP_allele__update"

Variation : "tm1879" -O "2005-04-27_11:13:02_mt3"
Description	 -O "2006-03-03_10:46:08_NBP_allele__update" Phenotype_remark -O "2006-03-03_10:46:08_NBP_allele__update" "homozygous viable" -O "2006-03-03_10:46:08_NBP_allele__update"

Variation : "tm1880" -O "2005-04-27_11:13:02_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1881" -O "2005-04-27_11:13:02_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1882" -O "2005-04-27_11:13:02_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1883" -O "2005-04-27_11:13:02_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1884" -O "2005-04-27_11:13:02_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1885" -O "2005-05-25_09:09:30_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1886" -O "2005-04-27_11:13:02_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1887" -O "2005-04-27_11:13:02_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1888" -O "2005-04-27_11:13:02_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1889" -O "2005-04-27_11:13:02_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1890" -O "2005-04-27_11:13:02_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. A. Antebi: gonadal Mig on low cholesterol." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1892" -O "2005-04-27_11:13:02_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1893" -O "2005-04-27_11:13:02_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1894" -O "2005-05-25_09:09:30_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1895" -O "2005-04-27_11:13:02_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1896" -O "2005-05-25_09:09:30_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. H. Sawa: Some die in embryonic stage (10\/100)." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1897" -O "2005-04-27_11:13:02_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1898" -O "2005-05-25_09:09:30_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1899" -O "2005-04-27_11:13:02_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "Homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1900" -O "2005-04-27_11:13:02_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1901" -O "2005-05-25_09:09:30_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1903" -O "2005-05-25_09:09:30_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1904" -O "2005-06-22_16:36:07_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1905" -O "2005-05-25_09:09:30_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1906" -O "2005-05-25_09:09:30_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1907" -O "2005-05-25_09:09:30_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. C. Kenyon: grossly normal morphology and fertility, does not form dauer at 25C." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1908" -O "2005-06-22_16:36:07_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. C. Kenyon: grossly normal morphology and fertility, does not form dauer at 25C." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1909" -O "2005-05-25_09:09:30_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1910" -O "2005-05-25_09:09:30_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1911" -O "2005-05-25_09:09:30_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1912" -O "2005-06-22_16:36:07_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1913" -O "2005-05-25_09:09:30_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1915" -O "2005-06-22_16:36:07_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1916" -O "2005-05-25_09:09:30_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1917" -O "2005-05-25_09:09:30_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1919" -O "2005-05-25_09:09:30_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1920" -O "2005-05-25_09:09:30_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1922" -O "2005-05-25_09:09:30_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. C. Kenyon: grossly normal morphology and fertility, does not form dauer at 25C." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1923" -O "2005-05-25_09:09:30_mt3"
Description	 -O "2006-03-03_10:46:08_NBP_allele__update" Phenotype_remark -O "2006-03-03_10:46:08_NBP_allele__update" "homozygous viable" -O "2006-03-03_10:46:08_NBP_allele__update"

Variation : "tm1924" -O "2005-05-25_09:09:30_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile. Dr. Y. Jin: could not maintain as homozygote." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1925" -O "2005-05-25_09:09:30_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1926" -O "2005-06-22_16:36:07_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1927" -O "2005-07-04_11:33:05_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1928" -O "2005-06-22_16:36:07_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1929" -O "2005-05-25_09:09:30_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1930" -O "2005-05-25_09:09:30_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1931" -O "2005-05-25_09:09:30_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. C. Kenyon: grossly normal morphology and fertility, does not form dauer at 25C." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1932" -O "2005-05-25_09:09:30_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1933" -O "2005-06-22_16:36:07_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1934" -O "2005-07-04_11:33:05_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1935" -O "2005-06-22_16:36:07_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1936" -O "2005-06-22_16:36:07_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1937" -O "2005-09-21_11:08:15_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1938" -O "2005-05-25_09:09:30_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1939" -O "2005-06-22_16:36:07_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1940" -O "2005-05-25_09:09:30_mt3"
Description	 -O "2006-03-03_10:46:08_NBP_allele__update" Phenotype_remark -O "2006-03-03_10:46:08_NBP_allele__update" "homozygous viable" -O "2006-03-03_10:46:08_NBP_allele__update"

Variation : "tm1941" -O "2005-07-04_11:33:05_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1942" -O "2005-05-25_09:09:30_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1943" -O "2005-05-25_09:09:30_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1944" -O "2005-06-22_16:36:07_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1945" -O "2005-05-25_09:09:30_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1946" -O "2005-06-22_16:36:07_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1947" -O "2005-06-22_16:36:07_mt3"
Description	 -O "2006-03-03_10:46:08_NBP_allele__update" Phenotype_remark -O "2006-03-03_10:46:08_NBP_allele__update" "homozygous viable. Dr. C. Kenyon: grossly normal morphology and fertility, does not form dauer at 25C." -O "2006-03-03_10:46:08_NBP_allele__update"

Variation : "tm1949" -O "2005-07-04_13:29:32_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1950" -O "2005-07-04_13:29:32_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1951" -O "2005-06-22_16:36:07_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1952" -O "2005-06-22_16:36:07_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1953" -O "2005-06-22_16:36:07_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1954" -O "2005-06-22_16:36:07_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1955" -O "2005-06-22_16:36:07_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1956" -O "2005-06-22_16:36:07_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1957" -O "2005-05-25_09:09:30_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1958" -O "2005-06-22_16:36:07_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1959" -O "2005-06-22_16:36:07_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1960" -O "2005-06-22_16:36:07_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1961" -O "2005-06-22_16:36:07_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. Y. Jin: normal behavior." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1962" -O "2005-06-22_16:36:07_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1963" -O "2005-09-21_11:08:15_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1964" -O "2005-06-22_16:36:07_mt3"
Description	 -O "2006-03-03_10:46:08_NBP_allele__update" Phenotype_remark -O "2006-03-03_10:46:08_NBP_allele__update" "lethal or sterile" -O "2006-03-03_10:46:08_NBP_allele__update"

Variation : "tm1965" -O "2005-09-21_11:13:09_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1966" -O "2005-06-22_16:36:07_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1967" -O "2005-06-22_16:36:07_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1968" -O "2005-09-21_11:08:15_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1969" -O "2005-06-22_16:36:07_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1970" -O "2005-09-21_11:08:15_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1971" -O "2005-06-22_16:36:07_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1972" -O "2005-06-22_16:36:07_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1973" -O "2005-06-22_16:36:07_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1974" -O "2005-07-04_13:29:32_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1975" -O "2005-09-21_11:08:15_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1976" -O "2005-06-22_16:36:07_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1977" -O "2005-06-22_16:36:07_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1978" -O "2005-09-21_11:08:15_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1979" -O "2005-07-04_13:29:32_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1980" -O "2005-09-21_11:08:15_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1981" -O "2005-09-21_11:08:15_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1983" -O "2005-06-22_16:36:07_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. C. Kenyon: grossly normal morphology and fertility, does not form dauer at 25C." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1984" -O "2005-09-21_11:08:15_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1985" -O "2005-06-22_16:36:07_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable. Dr. M. Gotta: protein epitope is expressed." -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1986" -O "2005-09-21_11:08:15_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1987" -O "2005-09-21_11:08:15_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1988" -O "2005-09-21_11:08:15_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1989" -O "2005-09-21_11:08:15_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1990" -O "2005-09-21_11:08:15_mt3"
Description	 -O "2006-03-03_10:46:08_NBP_allele__update" Phenotype_remark -O "2006-03-03_10:46:08_NBP_allele__update" "homozygous viable" -O "2006-03-03_10:46:08_NBP_allele__update"

Variation : "tm1991" -O "2005-09-21_11:08:15_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1992" -O "2005-09-21_11:08:15_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1993" -O "2005-09-21_11:08:15_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1994" -O "2005-09-21_11:08:15_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1995" -O "2005-09-21_11:08:15_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1996" -O "2005-09-21_11:08:15_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1997" -O "2005-09-21_11:08:15_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1998" -O "2005-09-21_11:08:15_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm1999" -O "2005-09-21_11:13:09_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2000" -O "2005-09-27_09:57:33_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2001" -O "2005-09-21_11:08:15_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2004" -O "2005-09-21_11:13:09_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2008" -O "2005-09-21_11:08:15_mt3"
Description	 -O "2006-03-03_10:46:08_NBP_allele__update" Phenotype_remark -O "2006-03-03_10:46:08_NBP_allele__update" "homozygous viable. Dr. C. Kenyon: grossly normal morphology and fertility, does not form dauer at 25C." -O "2006-03-03_10:46:08_NBP_allele__update"

Variation : "tm2010" -O "2005-09-21_11:13:09_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2016" -O "2005-09-21_11:13:09_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2018" -O "2005-09-21_11:13:09_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2021" -O "2005-09-21_11:13:09_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2024" -O "2005-09-21_11:13:09_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2025" -O "2005-09-21_11:13:09_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2026" -O "2005-09-21_11:13:09_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2027" -O "2005-09-21_11:13:09_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2028" -O "2005-09-21_11:13:09_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2029" -O "2005-09-27_09:57:33_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2030" -O "2005-09-27_09:57:33_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2031" -O "2005-09-21_11:13:09_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2032" -O "2005-09-21_11:13:09_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2033" -O "2005-09-21_11:13:09_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2034" -O "2005-09-21_11:13:09_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2035" -O "2005-09-21_11:13:09_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2038" -O "2005-09-27_09:57:33_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2039" -O "2005-09-21_11:13:09_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2040" -O "2005-09-21_11:13:09_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2041" -O "2005-09-21_11:13:09_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2043" -O "2005-09-27_09:57:33_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2044" -O "2005-09-21_11:13:09_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2045" -O "2005-09-21_11:13:09_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2046" -O "2005-09-21_11:13:09_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2047" -O "2005-09-21_11:13:09_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2048" -O "2005-11-15_14:05:12_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2049" -O "2005-09-21_11:13:09_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2050" -O "2005-09-27_09:57:33_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2051" -O "2005-09-21_11:13:09_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2052" -O "2005-09-21_11:13:09_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2053" -O "2005-09-21_11:13:09_mt3"
Description	 -O "2006-03-03_10:46:08_NBP_allele__update" Phenotype_remark -O "2006-03-03_10:46:08_NBP_allele__update" "homozygous viable" -O "2006-03-03_10:46:08_NBP_allele__update"

Variation : "tm2054" -O "2005-09-21_11:13:09_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2055" -O "2005-09-27_09:57:33_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2056" -O "2005-09-21_11:13:09_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2057" -O "2005-09-27_09:57:33_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2058" -O "2006-01-19_13:44:55_NBP_ALLELE_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2059" -O "2005-09-21_11:13:09_mt3"
Description	 -O "2006-03-03_10:46:08_NBP_allele__update" Phenotype_remark -O "2006-03-03_10:46:08_NBP_allele__update" "homozygous viable" -O "2006-03-03_10:46:08_NBP_allele__update"

Variation : "tm2060" -O "2005-09-27_10:07:53_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2061" -O "2005-09-27_10:07:53_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2063" -O "2005-09-27_10:07:53_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2064" -O "2005-09-27_10:07:53_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2065" -O "2005-09-27_10:07:53_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2066" -O "2005-11-15_14:05:12_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2067" -O "2005-11-15_14:05:12_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2068" -O "2005-09-27_10:07:53_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2069" -O "2005-09-27_10:07:53_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2070" -O "2005-09-27_10:07:53_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2071" -O "2005-09-27_09:57:33_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2072" -O "2005-11-15_14:05:12_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2073" -O "2005-09-27_10:07:53_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2074" -O "2005-09-27_10:07:53_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2075" -O "2005-09-27_10:07:53_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2076" -O "2005-11-15_14:05:12_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2077" -O "2005-09-27_10:07:53_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2079" -O "2005-11-15_14:05:12_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2080" -O "2005-09-27_10:07:53_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2081" -O "2005-11-15_14:05:12_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2084" -O "2005-09-27_10:07:53_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2085" -O "2005-09-27_10:07:53_mt3"
Description	 -O "2006-03-03_10:46:08_NBP_allele__update" Phenotype_remark -O "2006-03-03_10:46:08_NBP_allele__update" "homozygous viable" -O "2006-03-03_10:46:08_NBP_allele__update"

Variation : "tm2088" -O "2005-11-15_14:05:12_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2089" -O "2005-11-15_14:05:12_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2090" -O "2005-09-27_10:07:53_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2091" -O "2005-09-27_10:07:53_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2092" -O "2005-11-15_14:05:12_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2093" -O "2005-09-27_10:07:53_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2094" -O "2005-09-27_10:07:53_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2095" -O "2005-09-27_10:07:53_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2096" -O "2005-09-27_10:07:53_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2097" -O "2005-11-15_14:05:12_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2098" -O "2005-09-27_10:07:53_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2099" -O "2005-09-27_10:07:53_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2100" -O "2005-11-15_14:05:12_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2101" -O "2006-01-19_13:44:55_NBP_ALLELE_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2102" -O "2005-11-15_14:05:12_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2103" -O "2005-09-27_10:07:53_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2104" -O "2005-09-27_10:07:53_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2105" -O "2005-09-27_10:07:53_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2106" -O "2005-11-15_14:05:12_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2107" -O "2005-11-15_14:05:12_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2108" -O "2005-09-27_10:07:53_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2109" -O "2005-11-15_14:05:12_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2110" -O "2005-11-15_14:05:12_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2111" -O "2005-11-15_14:05:12_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2112" -O "2005-11-15_14:05:12_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2113" -O "2005-11-15_14:05:12_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2114" -O "2005-11-15_14:05:12_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2115" -O "2005-11-15_14:05:12_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2116" -O "2005-11-15_14:05:12_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2117" -O "2005-11-15_14:05:12_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2118" -O "2005-11-15_14:05:12_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2120" -O "2005-11-15_14:05:12_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2121" -O "2005-11-15_14:05:12_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2122" -O "2005-11-15_14:05:12_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2123" -O "2005-11-15_14:05:12_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2124" -O "2006-01-25_14:22:46_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2125" -O "2005-11-15_14:05:12_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2126" -O "2005-11-15_14:05:12_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2127" -O "2005-11-15_14:05:12_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2128" -O "2005-11-15_14:05:12_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2129" -O "2005-11-15_14:05:12_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2130" -O "2006-01-19_13:44:55_NBP_ALLELE_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2131" -O "2005-11-15_14:05:12_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2132" -O "2005-11-15_14:05:12_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2133" -O "2005-11-15_14:05:12_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2134" -O "2005-11-15_14:05:12_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2135" -O "2005-11-15_14:05:12_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2136" -O "2005-11-15_14:05:12_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2137" -O "2005-11-15_14:05:12_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2138" -O "2005-11-15_14:05:12_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2139" -O "2005-11-15_14:05:12_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2140" -O "2005-11-15_14:05:12_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2141" -O "2005-11-15_14:05:12_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2142" -O "2005-11-15_14:05:12_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2143" -O "2005-11-15_14:05:12_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2144" -O "2005-11-15_14:05:12_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2145" -O "2005-11-15_14:05:12_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2146" -O "2005-11-15_14:05:12_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2147" -O "2005-11-15_14:05:12_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2148" -O "2005-11-15_14:05:12_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2150" -O "2005-11-15_14:05:12_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2151" -O "2005-11-15_14:05:12_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2152" -O "2005-11-15_14:05:12_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2153" -O "2005-11-15_14:05:12_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2155" -O "2005-11-15_14:05:12_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2156" -O "2005-11-15_14:05:12_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2159" -O "2005-11-15_14:05:12_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2161" -O "2005-11-15_14:05:12_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2162" -O "2005-11-15_14:05:12_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2163" -O "2005-11-15_14:05:12_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2164" -O "2005-11-15_14:05:12_wormpub"
Description	 -O "2006-03-03_10:46:08_NBP_allele__update" Phenotype_remark -O "2006-03-03_10:46:08_NBP_allele__update" "homozygous viable" -O "2006-03-03_10:46:08_NBP_allele__update"

Variation : "tm2165" -O "2005-11-15_14:05:12_wormpub"
Description	 -O "2006-03-03_10:46:08_NBP_allele__update" Phenotype_remark -O "2006-03-03_10:46:08_NBP_allele__update" "homozygous viable" -O "2006-03-03_10:46:08_NBP_allele__update"

Variation : "tm2166" -O "2006-01-19_13:44:55_NBP_ALLELE_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2167" -O "2005-11-15_14:05:12_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2169" -O "2006-01-19_13:44:55_NBP_ALLELE_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2170" -O "2005-11-15_14:05:12_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2171" -O "2005-11-15_14:05:12_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2172" -O "2006-01-19_13:44:55_NBP_ALLELE_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2173" -O "2005-11-15_14:05:12_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2174" -O "2005-11-15_14:05:12_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2175" -O "2005-11-15_14:05:12_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2176" -O "2005-11-15_14:05:12_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2178" -O "2005-11-15_14:05:12_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2179" -O "2006-01-25_14:22:46_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2180" -O "2006-01-19_13:44:55_NBP_ALLELE_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2181" -O "2006-01-19_13:44:55_NBP_ALLELE_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2182" -O "2005-11-15_14:05:12_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2183" -O "2005-11-15_14:05:12_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2184" -O "2005-11-15_14:05:12_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2185" -O "2006-01-25_14:22:46_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2186" -O "2005-11-15_14:05:12_wormpub"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2188" -O "2006-01-19_13:44:55_NBP_ALLELE_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2190" -O "2006-01-19_13:44:55_NBP_ALLELE_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2193" -O "2006-01-19_13:44:55_NBP_ALLELE_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2194" -O "2006-01-19_13:44:55_NBP_ALLELE_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2195" -O "2006-01-19_13:44:55_NBP_ALLELE_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2196" -O "2006-01-25_14:22:46_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2199" -O "2006-01-19_13:44:55_NBP_ALLELE_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2205" -O "2006-01-19_13:44:55_NBP_ALLELE_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2206" -O "2006-01-19_13:44:55_NBP_ALLELE_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2207" -O "2006-01-19_13:44:55_NBP_ALLELE_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2208" -O "2006-01-19_13:44:55_NBP_ALLELE_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2209" -O "2006-01-19_13:44:55_NBP_ALLELE_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2210" -O "2006-01-19_13:44:55_NBP_ALLELE_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2211" -O "2006-01-25_14:22:46_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2212" -O "2006-01-19_13:44:55_NBP_ALLELE_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2213" -O "2006-01-25_14:22:46_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2214" -O "2006-01-19_13:44:55_NBP_ALLELE_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2217" -O "2006-01-19_13:44:55_NBP_ALLELE_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2218" -O "2006-01-19_13:44:55_NBP_ALLELE_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2220" -O "2006-01-25_14:22:46_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2223" -O "2006-01-19_13:44:55_NBP_ALLELE_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2225" -O "2006-01-19_13:44:55_NBP_ALLELE_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2226" -O "2006-01-25_14:22:46_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2227" -O "2006-01-19_13:44:55_NBP_ALLELE_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2230" -O "2006-01-19_13:44:55_NBP_ALLELE_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2231" -O "2006-01-19_13:44:55_NBP_ALLELE_update"
Description	 -O "2006-03-03_10:46:08_NBP_allele__update" Phenotype_remark -O "2006-03-03_10:46:08_NBP_allele__update" "homozygous viable" -O "2006-03-03_10:46:08_NBP_allele__update"

Variation : "tm2232" -O "2006-01-19_13:44:55_NBP_ALLELE_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2233" -O "2006-01-19_13:44:55_NBP_ALLELE_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2234" -O "2006-01-19_13:44:55_NBP_ALLELE_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2235" -O "2006-01-25_14:22:46_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2236" -O "2006-01-19_13:44:55_NBP_ALLELE_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2238" -O "2006-01-19_13:44:55_NBP_ALLELE_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2240" -O "2006-01-19_13:44:55_NBP_ALLELE_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2241" -O "2006-01-19_13:44:55_NBP_ALLELE_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2243" -O "2006-03-03_11:10:00_NBP_allele__update"
Description	 -O "2006-03-03_11:10:00_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:10:00_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:10:00_NBP_allele__update"

Variation : "tm2244" -O "2006-01-19_13:44:55_NBP_ALLELE_update"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2245" -O "2006-01-25_14:22:46_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2246" -O "2006-01-25_14:22:46_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2247" -O "2006-01-25_14:22:46_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2249" -O "2006-01-25_14:22:46_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2250" -O "2006-01-25_14:22:46_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2251" -O "2006-01-25_14:22:46_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2253" -O "2006-03-03_11:10:00_NBP_allele__update"
Description	 -O "2006-03-03_11:10:00_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:10:00_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:10:00_NBP_allele__update"

Variation : "tm2255" -O "2006-03-03_11:10:00_NBP_allele__update"
Description	 -O "2006-03-03_11:10:00_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:10:00_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:10:00_NBP_allele__update"

Variation : "tm2256" -O "2006-03-03_11:10:00_NBP_allele__update"
Description	 -O "2006-03-03_11:10:00_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:10:00_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:10:00_NBP_allele__update"

Variation : "tm2257" -O "2006-03-03_11:10:00_NBP_allele__update"
Description	 -O "2006-03-03_11:10:00_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:10:00_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:10:00_NBP_allele__update"

Variation : "tm2258" -O "2006-03-03_11:10:00_NBP_allele__update"
Description	 -O "2006-03-03_11:10:00_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:10:00_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:10:00_NBP_allele__update"

Variation : "tm2259" -O "2006-01-25_14:22:46_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2261" -O "2006-01-25_14:22:46_mt3"
Description	 -O "2006-03-03_11:12:45_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:12:45_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:12:45_NBP_allele__update"

Variation : "tm2267" -O "2006-03-03_11:10:00_NBP_allele__update"
Description	 -O "2006-03-03_11:10:00_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:10:00_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:10:00_NBP_allele__update"

Variation : "tm2270" -O "2006-03-03_11:10:00_NBP_allele__update"
Description	 -O "2006-03-03_11:10:00_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:10:00_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:10:00_NBP_allele__update"

Variation : "tm2271" -O "2006-03-03_11:10:00_NBP_allele__update"
Description	 -O "2006-03-03_11:10:00_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:10:00_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:10:00_NBP_allele__update"

Variation : "tm2272" -O "2006-03-03_11:10:00_NBP_allele__update"
Description	 -O "2006-03-03_11:10:00_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:10:00_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:10:00_NBP_allele__update"

Variation : "tm2274" -O "2006-03-03_11:10:00_NBP_allele__update"
Description	 -O "2006-03-03_11:10:00_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:10:00_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:10:00_NBP_allele__update"

Variation : "tm2275" -O "2006-03-03_11:10:00_NBP_allele__update"
Description	 -O "2006-03-03_11:10:00_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:10:00_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:10:00_NBP_allele__update"

Variation : "tm2276" -O "2006-03-03_11:10:00_NBP_allele__update"
Description	 -O "2006-03-03_11:10:00_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:10:00_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:10:00_NBP_allele__update"

Variation : "tm2278" -O "2006-03-03_11:10:00_NBP_allele__update"
Description	 -O "2006-03-03_11:10:00_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:10:00_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:10:00_NBP_allele__update"

Variation : "tm2279" -O "2006-03-03_11:10:00_NBP_allele__update"
Description	 -O "2006-03-03_11:10:00_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:10:00_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:10:00_NBP_allele__update"

Variation : "tm2280" -O "2006-03-03_11:10:00_NBP_allele__update"
Description	 -O "2006-03-03_11:10:00_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:10:00_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:10:00_NBP_allele__update"

Variation : "tm2282" -O "2006-03-03_11:10:00_NBP_allele__update"
Description	 -O "2006-03-03_11:10:00_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:10:00_NBP_allele__update" "homozygous viable" -O "2006-03-03_11:10:00_NBP_allele__update"

Variation : "tm2284" -O "2006-03-03_11:10:00_NBP_allele__update"
Description	 -O "2006-03-03_11:10:00_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:10:00_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:10:00_NBP_allele__update"

Variation : "tm2287" -O "2006-03-03_11:10:00_NBP_allele__update"
Description	 -O "2006-03-03_11:10:00_NBP_allele__update" Phenotype_remark -O "2006-03-03_11:10:00_NBP_allele__update" "lethal or sterile" -O "2006-03-03_11:10:00_NBP_allele__update"

Variation : "tn377" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2002-11-07_16:12:39_ck1" Phenotype_remark -O "2002-11-07_16:12:39_ck1" "Class III A.  (tn377ts).  Maternal-effect lethal at 250C.  Temperature-shifted embryos show defects in germline proliferation (Glp).  Germ cells fail to complete the metaphase to anaphase transition during meiosis or mitosis." -O "2005-01-10_14:41:20_mt3" Curator_confirmed -O "2006-03-01_10:50:27_mt3" "WBPerson2970" -O "2006-03-01_10:50:27_mt3"
Description	 -O "2002-11-07_16:12:39_ck1" Temperature_sensitive -O "2002-11-07_16:12:39_ck1" Heat_sensitive -O "2002-11-07_16:12:39_ck1"
Description	 -O "2002-11-07_16:12:39_ck1" Maternal -O "2002-11-07_16:12:39_ck1" With_maternal_effect -O "2002-11-07_16:12:39_ck1"

Variation : "tn471" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2005-08-18_15:05:18_ar2" Phenotype_remark -O "2000-07-28_13:55:58.1_sylvia" "Zygotic sterile.  Germline and somatic metaphase to anaphase transition defects. Early stop codons  in several alleles and thus likely to be the null phenotype. tn471 Q476 to stop" -O "2000-07-28_13:55:58.1_sylvia" Curator_confirmed -O "2006-03-01_10:50:27_mt3" "WBPerson1250" -O "2006-03-01_10:50:27_mt3"

Variation : "tn472" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2005-08-18_15:05:18_ar2" Phenotype_remark -O "2000-07-28_13:55:58.1_sylvia" "Zygotic sterile.  Germline and somatic metaphase to anaphase transition defects. Early stop codons  in several alleles and thus likely to be the null phenotype. tn472 alters SL1\/SL2 trans-splice acceptor" -O "2000-07-28_13:55:58.1_sylvia" Curator_confirmed -O "2006-03-01_10:50:27_mt3" "WBPerson1250" -O "2006-03-01_10:50:27_mt3"

Variation : "tn473" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2005-08-18_15:05:18_ar2" Phenotype_remark -O "2000-07-28_13:55:58.1_sylvia" "Zygotic sterile.  Germline and somatic metaphase to anaphase transition defects. Early stop codons  in several alleles and thus likely to be the null phenotype. tn473 alters the intron 6 acceptor." -O "2000-07-28_13:55:58.1_sylvia" Curator_confirmed -O "2006-03-01_10:50:27_mt3" "WBPerson1250" -O "2006-03-01_10:50:27_mt3"

Variation : "tn474" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2000-07-28_13:55:58.1_sylvia" Phenotype_remark -O "2000-07-28_13:55:58.1_sylvia" "Class IV B.  (tn474, tn494).  Viable.  Fails to complement tn377ts for the Mel phenotype, but complements for the Glp phenotype. tn474 R981 to stop" -O "2000-07-28_13:55:58.1_sylvia" Paper_evidence -O "2006-03-01_10:50:27_mt3" "WBPaper00003989" -O "2006-03-01_10:50:27_mt3"

Variation : "tn475" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2000-07-28_13:55:58.1_sylvia" Phenotype_remark -O "2000-07-28_13:55:58.1_sylvia" "Zygotic sterile.  Germline and somatic metaphase to anaphase transition defects. Early stop codons  in several alleles and thus likely to be the null phenotype. tn475 G355 to stop." -O "2000-07-28_13:55:58.1_sylvia" Paper_evidence -O "2006-03-01_10:50:27_mt3" "WBPaper00003989" -O "2006-03-01_10:50:27_mt3"

Variation : "tn476" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2005-08-18_15:05:18_ar2" Phenotype_remark -O "2000-07-28_13:55:58.1_sylvia" "Zygotic sterile.  Germline and somatic metaphase to anaphase transition defects. Early stop codons  in serveral alleles and thus likely to be the null phenotype." -O "2000-07-28_13:55:58.1_sylvia" Curator_confirmed -O "2006-03-01_10:50:27_mt3" "WBPerson1250" -O "2006-03-01_10:50:27_mt3"

Variation : "tn477" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2000-07-28_13:55:58.1_sylvia" Phenotype_remark -O "2000-07-28_13:55:58.1_sylvia" "Class II allele (tn477).  Maternal-effect lethal.  Embryos arrest at the 1-cell stage and fail to complete the metaphase to anaphase transition during MI.  smg suppressible.  No apparent somatic defects.  No apparent defects in germline prolferation or spermatogenesis. tn477 Y965 to stop" -O "2000-07-28_13:55:58.1_sylvia" Paper_evidence -O "2006-03-01_10:50:27_mt3" "WBPaper00003989" -O "2006-03-01_10:50:27_mt3"
Description	 -O "2000-07-28_13:55:58.1_sylvia" Maternal -O "2000-07-28_13:55:58.1_sylvia" With_maternal_effect -O "2000-07-28_13:55:58.1_sylvia"

Variation : "tn478" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2000-07-28_13:55:58.1_sylvia" Phenotype_remark -O "2000-07-28_13:55:58.1_sylvia" "Zygotic sterile.  Germline and somatic metaphase to anaphase transition defects. Early stop codons  in several alleles and thus likely to be the null phenotype." -O "2005-01-10_14:41:20_mt3" Curator_confirmed -O "2006-03-01_10:50:27_mt3" "WBPerson2970" -O "2006-03-01_10:50:27_mt3"

Variation : "tn479" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2000-07-28_13:55:58.1_sylvia" Phenotype_remark -O "2000-07-28_13:55:58.1_sylvia" "Zygotic sterile.  Germline and somatic metaphase to anaphase transition defects. Early stop codons  in several alleles and thus likely to be the null phenotype." -O "2005-01-10_14:41:20_mt3" Curator_confirmed -O "2006-03-01_10:50:27_mt3" "WBPerson2970" -O "2006-03-01_10:50:27_mt3"

Variation : "tn480" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2000-07-28_13:55:58.1_sylvia" Phenotype_remark -O "2000-07-28_13:55:58.1_sylvia" "Zygotic sterile.  Germline and somatic metaphase to anaphase transition defects. Early stop codons  in several alleles and thus likely to be the null phenotype. tn480 W55 to stop" -O "2000-07-28_13:55:58.1_sylvia" Curator_confirmed -O "2006-03-01_10:50:27_mt3" "WBPerson1250" -O "2006-03-01_10:50:27_mt3"

Variation : "tn481" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2000-07-28_13:55:58.1_sylvia" Phenotype_remark -O "2000-07-28_13:55:58.1_sylvia" "Class IV A.  (tn481).  Viable.  Some sterility.  Fails to complement tn377ts for Mel and Glp phenotypes at 250C." -O "2005-01-10_14:41:20_mt3" Curator_confirmed -O "2006-03-01_10:50:27_mt3" "WBPerson2970" -O "2006-03-01_10:50:27_mt3"

Variation : "tn493" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2005-08-18_15:05:18_ar2" Phenotype_remark -O "2000-07-28_13:55:58.1_sylvia" "Zygotic sterile.  Germline and somatic metaphase to anaphase transition defects. Early stop codons  in serveral alleles and thus likely to be the null phenotype. tn493 alters the intron 2 splice acceptor" -O "2000-07-28_13:55:58.1_sylvia" Paper_evidence -O "2006-03-01_10:50:27_mt3" "WBPaper00003989" -O "2006-03-01_10:50:27_mt3"

Variation : "tn494" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2000-07-28_13:55:58.1_sylvia" Phenotype_remark -O "2000-07-28_13:55:58.1_sylvia" "Class IV B.  (tn474, tn494).  Viable.  Fails to complement tn377ts for the Mel phenotype, but complements for the Glp phenotype." -O "2005-01-10_14:41:20_mt3" Paper_evidence -O "2006-03-01_10:50:27_mt3" "WBPaper00003989" -O "2006-03-01_10:50:27_mt3"

Variation : "u282" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2005-08-18_15:05:18_ar2" Phenotype_remark -O "2003-05-22_11:12:37_ck1" "loss of nearly all rays" -O "2003-05-22_11:12:37_ck1" Paper_evidence -O "2006-02-28_13:54:04_mt3" "WBPaper00004492" -O "2006-02-28_13:54:04_mt3"

Variation : "u779" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2005-08-18_15:05:18_ar2" Phenotype_remark -O "2003-05-22_11:12:37_ck1" "weaker lose of ray" -O "2003-05-22_11:12:37_ck1" Paper_evidence -O "2006-02-28_13:54:04_mt3" "WBPaper00004492" -O "2006-02-28_13:54:04_mt3"

Variation : "ua1" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2003-04-08_10:14:39_ck1" Recessive -O "2003-04-08_10:14:39_ck1"
Description	 -O "2003-04-08_10:14:39_ck1" Loss_of_function -O "2004-08-18_08:15:53_krb" Amorph -O "2004-08-18_08:15:53_krb" Paper_evidence -O "2004-08-18_08:15:53_krb" "WBPaper00004813" -O "2004-08-18_08:15:53_krb"

Variation : "ua2" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2003-04-08_10:14:39_ck1" Recessive -O "2003-04-08_10:14:39_ck1"

Variation : "ut3" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-12-15_10:31:21_mt3" Recessive -O "2004-12-15_10:31:21_mt3"
Description	 -O "2004-12-15_10:31:21_mt3" Completely_penetrant -O "2004-12-15_10:31:21_mt3"
Description	 -O "2004-12-15_10:31:21_mt3" Loss_of_function -O "2004-12-15_10:31:21_mt3" Uncharacterised_loss_of_function -O "2004-12-15_10:31:21_mt3"

Variation : "ut7" -O "2004-04-07_11:23:34_wormpub"
Description	 -O "2004-12-15_11:19:31_mt3" Recessive -O "2004-12-15_11:19:31_mt3"
Description	 -O "2004-12-15_11:19:31_mt3" Completely_penetrant -O "2004-12-15_11:19:31_mt3"
Description	 -O "2004-12-15_11:19:31_mt3" Loss_of_function -O "2004-12-15_11:19:31_mt3" Uncharacterised_loss_of_function -O "2004-12-15_11:19:31_mt3"

Variation : "y356" -O "2005-12-21_16:12:37_mt3"
Description	 -O "2005-12-21_16:12:37_mt3" Loss_of_function -O "2005-12-21_17:15:02_mt3"

Variation : "yt2" -O "2005-06-08_10:08:03_mt3"
Description	 -O "2005-06-08_10:26:08_mt3" Phenotype_remark -O "2005-06-08_10:26:08_mt3" "100\% maternal effect lethal" -O "2005-06-08_10:26:08_mt3" Paper_evidence -O "2006-01-19_15:07:46_NBP_ALLELE_update" "WBPaper00025639" -O "2006-01-19_15:07:46_NBP_ALLELE_update"

Variation : "yt5" -O "2005-06-08_11:08:50_mt3"
Description	 -O "2005-06-08_11:08:50_mt3" Phenotype_remark -O "2005-06-08_11:08:50_mt3" "100\% maternal lethal at 25C and >90\% maternal lethal at 15C" -O "2005-06-08_11:08:50_mt3" Paper_evidence -O "2006-01-19_15:07:46_NBP_ALLELE_update" "WBPaper00025639" -O "2006-01-19_15:07:46_NBP_ALLELE_update"
