#!/usr/bin/perl

# The script sits at :
# /home/acedb/erich/concise_description_uploader
# and is ran like :
# ./concise_description_uploader.pl inputfile.ace
#
# This script is designed to take a dump form the form's .ace dumper (as of 
# 2006 07 18), then read in only the Concise_description and
# Provisional_description tags (as well as the WBGene headers), ignore a set of
# additional headers, and report errors for unaccounted headers.
# As data is read entry by entry, each line is placed in a %data hash, then when
# the entry is done reading, the hash is read and processed.
# Provisional_description can have #Evidence, and types not coded for are set in
# error messages.  Date_last_udpated is ignore, accession goes to
# car_con_ref_accession, curator goes to car_con_ref_curator, everything else
# goes to car_con_ref_reference.  
# Curators could have multiple entries, which should not be joined in a given
# row, instead they must be appended to the table in separate rows.  The form's
# dumper dumps all curators in car_con_ref_curator, not the most recent entry.
# Curators must also be converted from WBPerson# to standardname based on the
# table two_standardname.
# Data beginning with ``, '' or spaces or trailing spaces, have those removed.
# (The ``, '' for the joining of evidences ;  the spaces for the joining of
# extra lines in Provisional_description, as well as generally being a good
# idea).  
# Since all data is appended, multiple uses of this script on the same data will
# result in multiple entries in postgres with the data, which redundantly take
# up space, albeit with different timestamps, and not dumping anything doubly.
# 2006 07 18
#
# Updated to overwrite old data with NULL if there used to be data but now
# isn't.  For Erich  2006 09 08


use strict;
use Pg;
use diagnostics;
use Jex;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

unless ($ARGV[0]) { die "Must have an inputfile : ./concise_description_uploader.pl INPUTFILE\n"; }

my $date = &getSimpleSecDate();

my $inputfile = $ARGV[0];
my $errorfile = 'errorfile';
my $outputfile = 'outfile.' . $date;

my %convertCurator;		# convert WBPerson into standardname
my $result = $conn->exec( "SELECT * FROM two_standardname ORDER BY two_timestamp;" );
while (my @row = $result->fetchrow) {
  my $joinkey = $row[0]; my $sname = $row[2];
  $joinkey =~ s/two/WBPerson/g;
  $convertCurator{$joinkey} = $sname;
} # while (my @row = $result->fetchrow)

my @tables_to_overwrite = qw( car_con_ref_reference car_con_ref_curator car_con_ref_accession car_con_last_verified car_con_maindata car_ext_maindata );

$/ = "";
open (IN, "<$inputfile") or die "Cannot open $inputfile : $!";
open (OUT, ">$outputfile") or die "Cannot create $outputfile : $!";
open (ERR, ">$errorfile") or die "Cannot create $errorfile : $!";
while (my $entry = <IN>) {
  my (@lines) = split/\n/, $entry; my @entry;
  my $joinkey; 
  my %data;
  foreach my $line (@lines) {
    if ($line =~ m/\/\/.*$/) { $line =~ s/\/\/.*$//g; } 
    next unless $line;
    if ($line =~ m/^Gene : \"(WBGene\d+)\"/) { $joinkey = $1; }
    elsif ($line =~ m/^Concise_description/) { 
      if ($line =~ m/^Concise_description\t\"(.*?)\"$/) {
        my $maindata = &filterForPostgres($1);
        $data{'car_con_maindata'} = $maindata; }
      else { print ERR "JOIN $joinkey\tBad Concise $line\n"; } }
    elsif ($line =~ m/^Provisional_description/) { 
      if ($line =~ m/^Provisional_description\t\".*?\"\t(\w+)\t\"(.*?)\"$/) {
        my $evidence = &filterForPostgres($2);
        my $evi_tag = $1;
	if ($evi_tag eq 'Paper_evidence') { $data{'car_con_ref_reference'} .= ", $evidence"; }
        elsif ($evi_tag eq 'Published_as') { $data{'car_con_ref_reference'} .= ", $evidence"; }
        elsif ($evi_tag eq 'Person_evidence') { $data{'car_con_ref_reference'} .= ", $evidence"; }
        elsif ($evi_tag eq 'Author_evidence') { $data{'car_con_ref_reference'} .= ", $evidence"; }
        elsif ($evi_tag eq 'Protein_id_evidence') { $data{'car_con_ref_reference'} .= ", $evidence"; }
        elsif ($evi_tag eq 'Expr_pattern_evidence') { $data{'car_con_ref_reference'} .= ", $evidence"; }
        elsif ($evi_tag eq 'Microarray_results_evidence') { $data{'car_con_ref_reference'} .= ", $evidence"; }
        elsif ($evi_tag eq 'RNAi_evidence') { $data{'car_con_ref_reference'} .= ", $evidence"; }
        elsif ($evi_tag eq 'Gene_regulation_evidence') { $data{'car_con_ref_reference'} .= ", $evidence"; }
        elsif ($evi_tag eq 'CGC_data_submission') { $data{'car_con_ref_reference'} .= ", $evidence"; }
        elsif ($evi_tag eq 'Inferred_automatically') { $data{'car_con_ref_reference'} .= ", $evidence"; }
        elsif ($evi_tag eq 'Feature_evidence') { $data{'car_con_ref_reference'} .= ", $evidence"; }
        elsif ($evi_tag eq 'Accession_evidence') { $data{'car_con_ref_accession'} .= ", $evidence"; }
        elsif ($evi_tag eq 'Curator_confirmed') { $data{'car_con_ref_curator'} .= ", $evidence"; }
#         elsif ($evi_tag eq 'Date_last_updated') { 1; }
        elsif ($evi_tag eq 'Date_last_updated') { $data{'car_con_last_verified'} .= ", $evidence"; }
        else { print ERR "JOIN $joinkey\tNot a valid Provisional evidence tag $line\n"; } }
      elsif ($line =~ m/^Provisional_description\t\"(.*?)\"$/) { 
        my $maindata = &filterForPostgres($1);
        $data{'car_ext_maindata'} .= " $maindata"; }
      else { print ERR "JOIN $joinkey\tBad Provisional $line\n"; } }
    elsif ( ($line =~ m/^Biological_process/) || ($line =~ m/^Expression/) || ($line =~ m/^Functional_pathway/) ||
            ($line =~ m/^Functional_physical_interaction/) || ($line =~ m/^Molecular_function/) ||
            ($line =~ m/^Other_description/) || ($line =~ m/^Sequence_features/) ) {
      1; }			# ignore these tags
    else { print ERR "INVALID tag header in $line\n"; }
  } # foreach my $line (@lines)
  foreach my $pgtable (@tables_to_overwrite) {
  # foreach my $pgtable (sort keys %data) 		# need to put nulls on stuff without data
    if ($data{$pgtable}) {
      if ($data{$pgtable} =~ m/^, /) { $data{$pgtable} =~ s/^, //; }
      if ($data{$pgtable} =~ m/^\s+/) { $data{$pgtable} =~ s/^\s+//; }
      if ($data{$pgtable} =~ m/\s+$/) { $data{$pgtable} =~ s/\s+$//; } }
    my @pgcommands;					# commands for postgres
    if ($pgtable eq 'car_con_ref_curator') {		# car_con_ref_curator could have multi-row data
      if ($data{'car_con_ref_curator'}) { 		# if there's data
        if ($data{'car_con_ref_curator'} =~ m/, /) {	# if there's multiple curators add them separately rows
          my (@curators) = split/, /, $data{'car_con_ref_curator'};
          foreach my $curator (@curators) {		# for each of the curators
            if ($curator) {				# if there is a curator, add it
              if ($convertCurator{$curator}) { 
                $curator = $convertCurator{$curator};
                my $command = "INSERT INTO $pgtable VALUES ('$joinkey', '$curator', CURRENT_TIMESTAMP);"; 
                push @pgcommands, $command; }
              else { print ERR "No curator convertion for $data{$pgtable}\n"; } } } }
        else { 						# if there's one curator, just add that curator
          if ($convertCurator{$data{$pgtable}}) { 
            $data{$pgtable} = $convertCurator{$data{$pgtable}};
            my $command = "INSERT INTO $pgtable VALUES ('$joinkey', '$data{$pgtable}', CURRENT_TIMESTAMP);"; 
            push @pgcommands, $command; } 
          else { print ERR "No curator convertion for $data{$pgtable}\n"; } } }
      else { 						# if there's no data, add Erich as default
        my $command = "INSERT INTO $pgtable VALUES ('$joinkey', 'Erich Schwarz', CURRENT_TIMESTAMP);"; 
        push @pgcommands, $command; } }
    else {						# normal tables just add a row
      if ($data{$pgtable}) {				# if there's data add it (even if it's the same, it updates the timestamp)
          my $command = "INSERT INTO $pgtable VALUES ('$joinkey', '$data{$pgtable}', CURRENT_TIMESTAMP);"; 
          push @pgcommands, $command; }
        else {						# if there's no data now
          my $result2 = $conn->exec( "SELECT $pgtable FROM $pgtable WHERE joinkey = '$joinkey' ORDER BY car_timestamp DESC;" ); 
          my @row2 = $result2->fetchrow;		# check if there used to be data and add a null if there was.  if there wasn't there still isn't so do nothing
          if ($row2[0]) {				# if there used to be data, add a null
            my $command = "INSERT INTO $pgtable VALUES ('$joinkey', NULL, CURRENT_TIMESTAMP);"; 
            push @pgcommands, $command; } }
    }
    foreach my $pgcommand (@pgcommands) {
      my $result2 = $conn->exec( "$pgcommand" );
      print OUT "$pgcommand\n"; }
  } # foreach my $pgtable (@tables_to_overwrite)
} # while (my $entry = <IN>)
close (ERR) or die "Cannot close $errorfile : $!";
close (OUT) or die "Cannot close $outputfile : $!";
close (IN) or die "Cannot close $inputfile : $!";

sub filterForPostgres {
  my $stuff = shift;
  if ($stuff =~ m/\'/) { $stuff =~ s/\'/''/g; }
  return $stuff;
} # sub filterForPostgres

__END__ 

tables :
car_lastcurator
car_con_maindata
car_con_ref_curator
car_con_ref_reference
car_con_ref_accession
car_con_last_verified
car_ext_maindata
my @PGsubparameters = qw( seq fpa fpi bio mol exp oth );
  maindata
  ref_curator
  ref_reference
  ref_accession

#Evidence tags
	  Paper_evidence
          Published_as
          Person_evidence
          Author_evidence
          Accession_evidence
          Protein_id_evidence
          Expr_pattern_evidence
          Microarray_results_evidence
          RNAi_evidence
          Gene_regulation_evidence
          CGC_data_submission
          Curator_confirmed
          Inferred_automatically
          Date_last_updated
