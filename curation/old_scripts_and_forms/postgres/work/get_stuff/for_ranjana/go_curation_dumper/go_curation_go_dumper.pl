#!/usr/bin/perl -w

# Get got_ data from PG and write .go format.  2004 09 13
#
# write to stuff/ directory, keeping date and .extension if multiples
# files for that date.  2004 10 27
#
# output GO into a .go file for uploading to GO with 15 columns, and
# to GO2 with 17 columns (with curator and go terms) for Ranjana.
# symlink both outputs to  public_html/cgi-bin/data/
# Linked go_curation.cgi to this script to create dumps.  2005 01 26
#
# Altered go dumping of column 6 to show person evidence if there is
# no paper evidence for that entry.  For Carol.  2005 02 16
#
# Filter beginning and ending spaces from column 5 for Carol. 
# 2005 03 28
#
# Filter all beginning and trailing spaces when reading from postgres,
# then check that there's a value before adding it to the hash.
# To finish spaces thing for Carol.  2005 03 31
#
# Changed ERR style error messages to print to errorfile instead of GO 
# output.  2005 09 01
#
# No longer using this, Ranjana has copies in acedb account.  2005 11 10


use strict;
use diagnostics;
use Pg;
use Jex;
use LWP;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my %theHash;

my $directory = '/home/postgres/work/get_stuff/for_ranjana/go_curation_dumper/stuff';
my @files = <$directory/*>;
my %files;
foreach $_ (@files) { $_ =~ s/^.*\///g; $_ =~ s/\.\d+$//g; $files{$_}++; }	# put files in hash minus path minus extension


my $date = &getSimpleDate();
# $date = '20041022';
print "DATE $date\n";
my $date_extension = 0;
my $errorfile = 'errorlog.' . $date;
if ($files{$errorfile}) { 
  my @extras = <$directory/$errorfile.*>;
  if ($extras[0]) {
    my $extra = pop @extras;
    ($date_extension) = $extra =~ m/(\d+)$/; }
}
$errorfile .= '.' . ++$date_extension;
$errorfile = $directory . "/$errorfile";
# print "errorfile $errorfile\n";
open(ERR, ">$errorfile") or die "Cannot create $errorfile : $!";

my $go_file = $directory . '/go_curation.go.dump.' . $date . '.' . $date_extension;
open (GO, ">$go_file") or die "Cannot append to $go_file : $!";
print GO "!Version: \$Revision: \$\n!Organism: Caenorhabditis elegans\n!date:      \$Date:\$\n!From: WormBase\n";

my $go2_file = $directory . '/go_curation.go.dump.withcurator.' . $date . '.' . $date_extension;
open (GO2, ">$go2_file") or die "Cannot append to $go2_file :$!";
print GO2 "!Version: \$Revision: \$\n!Organism: Caenorhabditis elegans\n!date:      \$Date:\$\n!From: WormBase\n";


# print OUT "GENE FUNCTION\n\n";

my @PGparameters = qw(curator locus sequence synonym protein wbgene);
my @ontology = qw( bio cell mol );
my @column_types = qw( goterm goid paper_evidence person_evidence goinference dbtype with qualifier
goinference_two dbtype_two with_two qualifier_two similarity comment );

# ND should -> GO_REF:nd

my %joinkeys;
my $result = $conn->exec( "SELECT * FROM got_curator WHERE joinkey ~ '[A-Za-z]' AND joinkey != 'cgc3' AND joinkey != 'abcd' AND joinkey != 'test-1' AND joinkey != 'asdf' AND joinkey != 'zk512.1';");
# my $result = $conn->exec( "SELECT * FROM got_curator WHERE joinkey ~ '[A-Za-z]' AND joinkey != 'gem-3' AND joinkey != 'jkk-1' AND joinkey != 'par-2' AND joinkey != 'cgc3' AND joinkey != 'abcd' AND joinkey != 'test-1' AND joinkey != 'asdf' AND joinkey != 'zk512.1';");
# my $result = $conn->exec( "SELECT * FROM got_curator WHERE joinkey ~ 'eat'");
my $count = 0;
while ( my @row = $result->fetchrow ) {
  $joinkeys{$row[0]}++;
  $count++;
#   if ($count > 10) { last; }
# print "JOINKEY $row[0]\n";
}
# while (my @row = $result->fetchrow) { $joinkeys{$row[0]}++; }

  # look at curators's list of stuff not to dump and exclude from joinkey hash
my $not_dump_file = '/home/postgres/work/get_stuff/for_ranjana/go_curation_dumper/stuff/file_of_not_dump_joinkeys';
open (NDM, "<$not_dump_file") or die "Cannot open $not_dump_file : $!";
while (my $line = <NDM>) {
  chomp $line;
  if ($line =~ m/\/\//) { $line =~ s/\/\/.*$//g; }
  if ($line) { delete $joinkeys{$line}; }
} # while (my $line = <NDM>)
close (NDM) or die "Cannot close $not_dump_file : $!";

my $max_columns = 3;		# query each of the groups for highest to set how many columns to loop through
foreach my $ontology (@ontology) {
  my $result = $conn->exec ( "SELECT * FROM got_${ontology}_goid ORDER BY got_order DESC;");
  my @row = $result->fetchrow;
  if ($row[1] > $max_columns) { $max_columns = $row[1]; }
}


my %cgcHash;
my %pmHash;

&populateFromPostgres();
my %convertToWBPaper;		# convert cgcs to WBPapers
&populateWBPaperHash();
&populateXref();
&outputGo();
close (ERR) or die "Cannot close $errorfile : $!";
close (GO) or die "Cannot close $go_file : $!";
close (GO2) or die "Cannot close $go2_file : $!";

  # Symlink stuff to website
my $location_of_latest = '/home/postgres/public_html/cgi-bin/data/go_curation.go.latest';
my $location_of_latest_withcurator = '/home/postgres/public_html/cgi-bin/data/go_curation.go.withcurator.latest';
unlink ("$location_of_latest") or die "Cannot unlink $location_of_latest : $!";					# unlink symlink to latest
symlink("$go_file", "$location_of_latest") or warn "cannot symlink $location_of_latest : $!";			# link newest dump to latest
unlink ("$location_of_latest_withcurator") or die "Cannot unlink $location_of_latest_withcurator : $!";				# unlink symlink to latest
symlink("$go2_file", "$location_of_latest_withcurator") or warn "cannot symlink $location_of_latest_withcurator : $!";		# link newest dump to latest

sub populateFromPostgres {
  foreach my $joinkey (sort keys %joinkeys) {
    foreach my $type (@PGparameters) {		# currently getting from postgres, might want from sanger instead, or use sanger to update postgres first
        # get in timestamp order (ascending) because that way latest value overwrite old ones in hash
      my $result = $conn->exec( "SELECT * FROM got_$type WHERE joinkey = '$joinkey' ORDER BY got_timestamp;" );
      while (my @row = $result->fetchrow) { 
        if ($row[1]) {
          my $val = &filterToPrintHtml("$row[1]");        # turn value to Html
          if ($val) { if ($val =~ m/^\s+/) { $val =~ s/^\s+//g; } if ($val =~ m/\s+$/) { $val =~ s/\s+$//g; } }	# filter spaces 2005 03 31
          if ($val) { $theHash{$joinkey}{$type}{value} = $val; }       # put value in %theHash if there's a value in postgres, overwriting sanger value
        }
      }
    } # foreach my $type (@PGparameters)
    foreach my $ontology (@ontology) {          # loop through each of three ontology types
      foreach my $column_type (@column_types) {
        my $type = $ontology . '_' . $column_type;
          # get in timestamp order (ascending) because that way latest value overwrite old ones in hash
#         my $result = $conn->exec( "SELECT * FROM got_$type WHERE joinkey = '$joinkey' AND got_$type IS NOT NULL ORDER BY got_timestamp;" );
        my $result = $conn->exec( "SELECT * FROM got_$type WHERE joinkey = '$joinkey' ORDER BY got_timestamp;" );
        while (my @row = $result->fetchrow) {
# unless ($row[2]) { print "SKIPPING JOIN $joinkey : ONT $ontology : COL $column_type : TYPE $type : TEMP_TYPE (order) $row[1] : NO VAL :\n"; }
          unless ($row[2]) { delete $theHash{$joinkey}{$type}{$row[1]}; next; }	# if value is NULL, delete from hash
          my $val = &filterToPrintHtml("$row[2]");      # turn value to Html
          if ($val =~ m/^\s+/) { $val =~ s/^\s+//g; } if ($val =~ m/\s+$/) { $val =~ s/\s+$//g; }
          unless ($val) { next; }			# skip stuff that has no values after filtering beginning and trailing spaces  2005 03 31
          $theHash{$joinkey}{$type}{$row[1]}{value} = $val;      # put value in %theHash
          if ($column_type eq 'goid') { $theHash{$joinkey}{date}{$row[1]}{value} = $row[3]; }
#           my $temp_type = $type . $row[1];
#  print "JOIN $joinkey : ONT $ontology : COL $column_type : TYPE $type : TEMP_TYPE (order) $row[1] : VAL $val :\n";
#           $theHash{$joinkey}{$temp_type}{value} = $val;      # put value in %theHash
        }
  } } }
} # sub populateFromPostgres



sub outputGo {
  foreach my $joinkey (sort keys %theHash) {
#     print GO "JOINKEY $joinkey\n";
#     my $ontology = 'bio';
    foreach my $ontology (@ontology) {          # loop through each of three ontology types
#       foreach my $type (@column_types) {
#         $type = $ontology . '_' . $type;
#         foreach my $order (sort keys %{ $theHash{$joinkey}{$type} }) {
#           print "ORDER $order TYPE $type VALUE $theHash{$joinkey}{$type}{$order}{value}\n";
#         }
#       } # foreach my $type (@column_types)

        # check that max_number is the same for mandatories, i.e. goid, goinference, dbtype
      (my $max_goid, my @junk) = reverse sort keys %{ $theHash{$joinkey}{"${ontology}_goid"} } ;
#       (my $max_papevi, @junk) = reverse sort keys %{ $theHash{$joinkey}{"${ontology}_paper_evidence"} } ;	# don't include because it might be ND
      (my $max_goinf, @junk) = reverse sort keys %{ $theHash{$joinkey}{"${ontology}_goinference"} } ;
      (my $max_dbtype, @junk) = reverse sort keys %{ $theHash{$joinkey}{"${ontology}_dbtype"} } ;
      my $max_columns = 1;		# number of columns with full data
      unless ($max_goid) { $max_goid = 0; }
      unless ($max_goinf) { $max_goinf = 0; }
      unless ($max_dbtype) { $max_dbtype = 0; }
      if ( ($max_goid == $max_goinf) && ($max_goid == $max_dbtype) ) {
        $max_columns = $max_goid; }
      else { 
        print ERR "ERR different amount of values in PRIMARY mandatory columns JOINKEY $joinkey ONTOLOGY $ontology GOID $max_goid GOIN $max_goinf DBTYPE $max_dbtype\n"; next; }

        # check that max_number is the same for second set of mandatories, i.e. goid, goinference_two, dbtype_two
      (my $max_goinf_two, @junk) = reverse sort keys %{ $theHash{$joinkey}{"${ontology}_goinference_two"} } ;
      (my $max_dbtype_two, @junk) = reverse sort keys %{ $theHash{$joinkey}{"${ontology}_dbtype_two"} } ;
      my $max_columns_two = 1;			# number of columns with full data
      unless ($max_goinf_two) { $max_goinf_two = 0; }
      unless ($max_dbtype_two) { $max_dbtype_two = 0; }
      if ( ($max_goid >= $max_goinf_two) && ($max_goid >= $max_dbtype_two) && ($max_goinf_two == $max_dbtype_two) ) {
        $max_columns_two = $max_goinf_two; }
      else { 
        print ERR "ERR different amount of values in SECONDARY mandatory columns JOINKEY $joinkey ONTOLOGY $ontology GOID $max_goid GOIN $max_goinf_two DBTYPE $max_dbtype_two\n"; next; }

      for my $order (1 .. $max_columns) {			# for each entry with mandatory data
        my $col6_flag = 'paper';			# Carol wants col6 to have person data when there is no paper data  2005 02 16

        my $col1 = 'WB';				# do same thing for normal groups
        my $col2; my $col3 = $joinkey;
        my $db_object_type = $theHash{$joinkey}{"${ontology}_dbtype"}{$order}{value};
        if ($db_object_type eq 'gene') { 
#           $col2 = 'WBGene'; 
          $col2 = $theHash{$joinkey}{wbgene}{value}; }
        elsif ($db_object_type eq 'transcript') { 
#           $col2 = 'Sequence'; 
          $col2 = $theHash{$joinkey}{sequence}{value}; }
        elsif ($db_object_type eq 'protein') { 
#           $col2 = 'CE'; 
          $col2 = $theHash{$joinkey}{protein}{value}; 
          $col3 = uc($col3); }
        elsif ($db_object_type eq 'complex') { 
#           $col2 = 'CE'; 
          $col2 = $theHash{$joinkey}{protein}{value}; 
          $col3 = uc($col3); }
        elsif ($db_object_type eq 'protein_structure') { 
#           $col2 = 'CE'; 
          $col2 = $theHash{$joinkey}{protein}{value}; 
          $col3 = uc($col3); }
        else { print ERR "ERR No DBType for $joinkey\n"; }
        my $col4 = '';
        if ($theHash{$joinkey}{"${ontology}_qualifier"}{$order}{value}) { $col4 = $theHash{$joinkey}{"${ontology}_qualifier"}{$order}{value}; }
        my $col5 = $theHash{$joinkey}{"${ontology}_goid"}{$order}{value};
        if ($col5 ne '') { unless ($col5 =~ 'GO') { print ERR "ERR GOID for $joinkey not a valid GOID.\n"; } }
        my $goinference = $theHash{$joinkey}{"${ontology}_goinference"}{$order}{value};
        my $col6 = '';
        unless ($goinference) { print ERR "ERR No GOInference for $joinkey\n"; }
        if ($goinference eq 'ND') { $col6 = 'GO_REF:nd'; }
        else { 
          if ($theHash{$joinkey}{"${ontology}_paper_evidence"}{$order}{value}) { 
            $col6 = $theHash{$joinkey}{"${ontology}_paper_evidence"}{$order}{value}; }
          elsif ($theHash{$joinkey}{"${ontology}_person_evidence"}{$order}{value}) {
	    # added these 3 lines (elsif) to show person data if there is no paper data.  # for Carol  2005 02 16
            $col6_flag = 'person';
            $col6 = $theHash{$joinkey}{"${ontology}_person_evidence"}{$order}{value}; }
          else { 
            print ERR "ERR Paper is mandatory in JOINKEY $joinkey ONTOLOGY $ontology ORDER $order\n"; next; } 
          # convert to pmid for match
          # find WBPaper
          # output WBPaper|PMID:
          # one line for each paper
        }
        my $col7 = $goinference;
        my $col8 = ''; 
        if ($theHash{$joinkey}{"${ontology}_with"}{$order}{value}) { $col8 = $theHash{$joinkey}{"${ontology}_with"}{$order}{value}; }
        my $col9;
        if ($ontology eq 'bio') { $col9 = 'P'; }
        elsif ($ontology eq 'cell') { $col9 = 'C'; }
        elsif ($ontology eq 'mol') { $col9 = 'F'; }
        else { print ERR "ERR $ontology not a valid ONTOLOGY JOINKEY $joinkey ONTOLOGY $ontology ORDER $order\n"; next; } 
        my $col10 = '';
        my $col11 = '';
        if ($theHash{$joinkey}{synonym}{value}) {
          if ($theHash{$joinkey}{synonym}{value} ne 'NULL') {
            $theHash{$joinkey}{synonym}{value} =~ s/, ?/\|/g;	# replace ``, '' or ``,'' with ``|''
            $col11 = $theHash{$joinkey}{synonym}{value};
            if ($db_object_type eq 'protein') { 
              $col11 = uc($col11); }
            elsif ($db_object_type eq 'complex') { 
              $col11 = uc($col11); }
            elsif ($db_object_type eq 'protein_structure') { 
              $col11 = uc($col11); }
        } }
        my $col12 = $db_object_type;
        my $col13 = 'taxon:6239';
        my $date = $theHash{$joinkey}{date}{$order}{value};
        my ($col14) = $date =~ m/^(\d{4}\-\d{2}\-\d{2})/;
        $col14 =~ s/\-//g;
        my $col15 = 'WB';

        my $col16 = '';
        if ($theHash{$joinkey}{"${ontology}_goterm"}{$order}{value}) { 
          $col16 = $theHash{$joinkey}{"${ontology}_goterm"}{$order}{value} .  "\t" . $theHash{$joinkey}{curator}{value}; }
        else {
          print ERR "MISSING GOTERM $joinkey $ontology $order\n"; }

#         if ($col6) { print "COL6 $col6\n"; }
        my @col6;
        if ($col6 =~ m/,/) {
          @col6 = split/,/, $col6;
          foreach $col6 (@col6) { $col6 =~ s/\s+/ /g; $col6 =~ s/^\s//g; $col6 =~ s/\s$//g; }
        } else { push @col6, $col6; }
        foreach my $col6 (@col6) {
          if ($col6_flag eq 'paper') { 		# deal with data coming from paper (like it should) 2005 02 16
            if ($col6 =~ m/PMID: /) { $col6 =~ s/PMID: /pmid/; }
            elsif ($col6 =~ m/PMID:/) { $col6 =~ s/PMID:/pmid/; }
            if ($col6 =~ m/\]/) { $col6 =~ s/\]//g; } if ($col6 =~ m/\[/) { $col6 =~ s/\[//g; }
            if ($col6 =~ m/WBPaper/) { 1; }
            elsif ($col6 =~ m/GO_REF/) { 1; }
            elsif ( $convertToWBPaper{getWB}{$col6} ) { $col6 = $convertToWBPaper{getWB}{$col6}; }	# if matching wbpaper
            else { print ERR "ERR No matching WBPaper for $col6 in entry $joinkey\n"; }
            if ($convertToWBPaper{pmid}{$col6}) { 
              my $pmid = $convertToWBPaper{pmid}{$col6}; 
              $pmid =~ s/pmid/PMID:/g;
              $col6 .= "|$pmid"; }
            if ($col6 =~ m/WBPaper/) { $col6 = 'WB:' . $col6; }
          } elsif ($col6_flag eq 'person') {	# deal with data coming from person instead of paper  2005 02 16
            $col6 =~ s/\s//g; $col6 = 'WB:' . $col6;
          } # elsif ($col6_flag eq 'person') 

          my @col2;
          if ($col5 =~ m/\s+/) { $col5 =~ s/\s+/ /g; }
          if ($col5 =~ m/^\s/) { $col5 =~ s/^\s//g; } if ($col5 =~ m/\s$/) { $col5 =~ s/\s$//g; }
          if ($col2 =~ m/\n/) { $col2 =~ s/\n/ /g; }
          if ($col2 =~ m/\s+/) { $col2 =~ s/\s+/ /g; }
          if ($col2 =~ m/,/) {
            @col2 = split/,/, $col2;
            foreach $col2 (@col2) { $col2 =~ s/\s+/ /g; $col2 =~ s/^\s//g; $col2 =~ s/\s$//g; }
          } else { push @col2, $col2; }
          foreach my $col2 (@col2) {

            print GO2 "$col1\t";    print GO "$col1\t";
            print GO2 "$col2\t";    print GO "$col2\t";
            print GO2 "$col3\t";    print GO "$col3\t";
            print GO2 "$col4\t";    print GO "$col4\t";
            print GO2 "$col5\t";    print GO "$col5\t";
            print GO2 "$col6\t";    print GO "$col6\t";
            print GO2 "$col7\t";    print GO "$col7\t";
            print GO2 "$col8\t";    print GO "$col8\t";
            print GO2 "$col9\t";    print GO "$col9\t";
            print GO2 "$col10\t";   print GO "$col10\t";
            print GO2 "$col11\t";   print GO "$col11\t";
            print GO2 "$col12\t";   print GO "$col12\t";
            print GO2 "$col13\t";   print GO "$col13\t";
            print GO2 "$col14\t";   print GO "$col14\t";
            print GO2 "$col15\t";   print GO "$col15\n"; 
            print GO2 "$col16\n"; 

          } # foreach my $col2 (@col2)
        } # foreach my $col6 (@col6)

          # check that goinference_two and dbtype_two both exist to make extra line
        if ($order <= $max_goinf_two ) {			# do thing for secondary groups
            # skip entries without go evidence 2 and db object type 2
          unless ($theHash{$joinkey}{"${ontology}_goinference_two"}{$order}{value}) { 
            unless ( $theHash{$joinkey}{"${ontology}_dbtype_two"}{$order}{value}) { next; } }
#           if ( ($theHash{$joinkey}{"${ontology}_goinference_two"}{$order}{value} eq '') && ( $theHash{$joinkey}{"${ontology}_dbtype_two"}{$order}{value} eq '') ) { next; }

          my $col1 = 'WB';
          my $col2; my $col3 = $joinkey;
          my $db_object_type = $theHash{$joinkey}{"${ontology}_dbtype_two"}{$order}{value};
          if ($db_object_type eq 'gene') { 
            $col2 = $theHash{$joinkey}{wbgene}{value}; }
          elsif ($db_object_type eq 'transcript') { 
            $col2 = $theHash{$joinkey}{sequence}{value}; }
          elsif ($db_object_type eq 'protein') { 
            $col2 = $theHash{$joinkey}{protein}{value}; 
            $col3 = uc($col3); }
          elsif ($db_object_type eq 'complex') { 
            $col2 = $theHash{$joinkey}{protein}{value}; 
            $col3 = uc($col3); }
          elsif ($db_object_type eq 'protein_structure') { 
            $col2 = $theHash{$joinkey}{protein}{value}; 
            $col3 = uc($col3); }
          else { print ERR "ERR No DBType for $joinkey\n"; }
          my $col4 = '';
          if ($theHash{$joinkey}{"${ontology}_qualifier_two"}{$order}{value}) { $col4 = $theHash{$joinkey}{"${ontology}_qualifier_two"}{$order}{value}; }
          my $col5 = $theHash{$joinkey}{"${ontology}_goid"}{$order}{value};
          if ($col5 ne '') { unless ($col5 =~ 'GO') { print ERR "ERR GOID for $joinkey not a valid GOID.\n"; } }
          my $goinference = $theHash{$joinkey}{"${ontology}_goinference_two"}{$order}{value};
          my $col6 = '';
          unless ($goinference) { print ERR "ERR No GOInference for $joinkey\n"; }
          if ($goinference eq 'ND') { $col6 = 'GO_REF:nd'; }
          else { 
            if ($theHash{$joinkey}{"${ontology}_paper_evidence"}{$order}{value}) { 
              $col6 = $theHash{$joinkey}{"${ontology}_paper_evidence"}{$order}{value}; }
            elsif ($theHash{$joinkey}{"${ontology}_person_evidence"}{$order}{value}) {
	      # added these 3 lines (elsif) to show person data if there is no paper data.  # for Carol  2005 02 16
              $col6_flag = 'person';
              $col6 = $theHash{$joinkey}{"${ontology}_person_evidence"}{$order}{value}; }
            else { 
              print ERR "ERR Paper is mandatory in JOINKEY $joinkey ONTOLOGY $ontology ORDER $order\n"; next; } 
            # convert to pmid for match
            # find WBPaper
            # output WBPaper|PMID:
            # one line for each paper
          }
          my $col7 = $goinference;
          my $col8 = ''; 
          if ($theHash{$joinkey}{"${ontology}_with_two"}{$order}{value}) { $col8 = $theHash{$joinkey}{"${ontology}_with_two"}{$order}{value}; }
          my $col9;
          if ($ontology eq 'bio') { $col9 = 'P'; }
          elsif ($ontology eq 'cell') { $col9 = 'C'; }
          elsif ($ontology eq 'mol') { $col9 = 'F'; }
          else { print ERR "ERR $ontology not a valid ONTOLOGY JOINKEY $joinkey ONTOLOGY $ontology ORDER $order\n"; next; } 
          my $col10 = '';
          my $col11 = '';
          if ($theHash{$joinkey}{synonym}{value}) {
            if ($theHash{$joinkey}{synonym}{value} ne 'NULL') {
              $theHash{$joinkey}{synonym}{value} =~ s/, ?/\|/g;	# replace ``, '' or ``,'' with ``|''
              $col11 = $theHash{$joinkey}{synonym}{value};
          } }
          my $col12 = $db_object_type;
          my $col13 = 'taxon:6239';
          my $date = $theHash{$joinkey}{date}{$order}{value};
          my ($col14) = $date =~ m/^(\d{4}\-\d{2}\-\d{2})/;
          $col14 =~ s/\-//g;
          my $col15 = 'WB';

          my $col16 = '';
          if ($theHash{$joinkey}{"${ontology}_goterm"}{$order}{value}) {
            $col16 = $theHash{$joinkey}{"${ontology}_goterm"}{$order}{value} .  "\t" . $theHash{$joinkey}{curator}{value}; }
          else {
            print ERR "MISSING GOTERM $joinkey $ontology $order\n"; }

          my @col6;
          if ($col6 =~ m/,/) {
            @col6 = split/,/, $col6;
            foreach $col6 (@col6) { $col6 =~ s/\s+/ /g; $col6 =~ s/^\s//g; $col6 =~ s/\s$//g; }
          } else { push @col6, $col6; }
          foreach my $col6 (@col6) {
            if ($col6_flag eq 'paper') { 		# deal with data coming from paper (like it should) 2005 02 16
              if ($col6 =~ m/PMID: /) { $col6 =~ s/PMID: /pmid/; }
              elsif ($col6 =~ m/PMID:/) { $col6 =~ s/PMID:/pmid/; }
              if ($col6 =~ m/\]/) { $col6 =~ s/\]//g; } if ($col6 =~ m/\[/) { $col6 =~ s/\[//g; }
              if ($col6 =~ m/WBPaper/) { 1; }
              elsif ($col6 =~ m/GO_REF/) { 1; }
              elsif ( $convertToWBPaper{getWB}{$col6} ) { $col6 = $convertToWBPaper{getWB}{$col6}; }	# if matching wbpaper
              else { print ERR "ERR No matching WBPaper for $col6 in entry $joinkey\n"; }
              if ($convertToWBPaper{pmid}{$col6}) { 
                my $pmid = $convertToWBPaper{pmid}{$col6}; 
                $pmid =~ s/pmid/PMID:/g;
                $col6 .= "|$pmid"; }
              if ($col6 =~ m/WBPaper/) { $col6 = 'WB:' . $col6; }
            } elsif ($col6_flag eq 'person') {		# deal with data coming from person instead of paper  2005 02 16
              $col6 =~ s/\s//g; $col6 = 'WB:' . $col6;
            } # elsif ($col6_flag eq 'person') 
  
            my @col2;
            if ($col5 =~ m/\s+/) { $col5 =~ s/\s+/ /g; }
            if ($col5 =~ m/^\s/) { $col5 =~ s/^\s//g; } if ($col5 =~ m/\s$/) { $col5 =~ s/\s$//g; }
            if ($col2 =~ m/\n/) { $col2 =~ s/\n/ /g; }
            if ($col2 =~ m/\s+/) { $col2 =~ s/\s+/ /g; }
            if ($col2 =~ m/,/) {
              @col2 = split/,/, $col2;
              foreach $col2 (@col2) { $col2 =~ s/\s+/ /g; $col2 =~ s/^\s//g; $col2 =~ s/\s$//g; }
            } else { push @col2, $col2; }
            foreach my $col2 (@col2) {
              print GO2 "$col1\t";   print GO "$col1\t";
              print GO2 "$col2\t";   print GO "$col2\t";
              print GO2 "$col3\t";   print GO "$col3\t";
              print GO2 "$col4\t";   print GO "$col4\t";
              print GO2 "$col5\t";   print GO "$col5\t";
              print GO2 "$col6\t";   print GO "$col6\t";
              print GO2 "$col7\t";   print GO "$col7\t";
              print GO2 "$col8\t";   print GO "$col8\t";
              print GO2 "$col9\t";   print GO "$col9\t";
              print GO2 "$col10\t";  print GO "$col10\t";
              print GO2 "$col11\t";  print GO "$col11\t";
              print GO2 "$col12\t";  print GO "$col12\t";
              print GO2 "$col13\t";  print GO "$col13\t";
              print GO2 "$col14\t";  print GO "$col14\t";
              print GO2 "$col15\t";  print GO "$col15\n"; 
              print GO2 "$col16\n"; 
            } # foreach my $col2 (@col2)
          } # foreach my $col6 (@col6)
        } # if ($order <= $max_goinf_two )

      } # for my $order (1 .. $max_columns) 		# for each entry with mandatory data
    } # foreach my $ontology (@ontology)		# loop through each of three ontology types
  } # foreach my $joinkey (sort keys %theHash)
} # sub outputGo

sub populateXref {              # if not found, get ref_xref data to try to find alternate
  my $result = $conn->exec( "SELECT * FROM ref_xref;" );
  while (my @row = $result->fetchrow) { # loop through all rows returned
    $cgcHash{$row[0]} = $row[1];        # hash of cgcs, values pmids
    $pmHash{$row[1]} = $row[0];         # hash of pmids, values cgcs
  } # while (my @row = $result->fetchrow)
} # sub populateXref



sub populateWBPaperHash {
      my $u = "http://minerva.caltech.edu/~acedb/paper2wbpaper.txt";
      my $ua = LWP::UserAgent->new(timeout => 30); #instantiates a new user agent
      my $request = HTTP::Request->new(GET => $u); #grabs url
      my $response = $ua->request($request);       #checks url, dies if not valid.
      die "Error while getting ", $response->request->uri," -- ", $response->status_line, "\nAborting" unless $response-> is_success;
      my @tmp = split /\n/, $response->content;    #splits by line
      foreach (@tmp) {
        if ($_ =~m/^(.*?)\t(.*?)$/) {	
          my ($one, $two) = ($1, $2);
          if ($one =~ m/cgc/) { $convertToWBPaper{cgc}{$two} = $one; }
          if ($one =~ m/pmid/) { $convertToWBPaper{pmid}{$two} = $one; }
          $convertToWBPaper{getWB}{$one} = $two; } }
} # sub populateWBPaperHash


