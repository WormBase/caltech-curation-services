#!/usr/bin/perl -w
#
# script to get data from go_curation

use strict;
use diagnostics;
use Pg;
use Jex; # getSimpleDate

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $outfile = "/home/postgres/work/get_stuff/go_curation/go/outfile.go";
open(OUT, ">$outfile") or die "Cannot create $outfile : $!";

my %theHash;

my %cgcHash;	# hash of cgcs, values pmids
my %pmHash;	# hash of pmids, values cgcs
&populateXref();

my @PGparameters = qw(  locus protein sequence
			bio_goid1 bio_goid2 bio_goid3 
			bio_goinference1 bio_goinference2 bio_goinference3
			bio_goterm1 bio_goterm2 bio_goterm3 
			bio_paper_evidence1 bio_paper_evidence2 bio_paper_evidence3
			bio_person_evidence1 bio_person_evidence2 bio_person_evidence3 
			bio_similarity1 bio_similarity2 bio_similarity3
			cell_goid1 cell_goid2 cell_goid3 
			cell_goinference1 cell_goinference2 cell_goinference3
			cell_goterm1 cell_goterm2 cell_goterm3 
			cell_paper_evidence1 cell_paper_evidence2 cell_paper_evidence3
			cell_person_evidence1 cell_person_evidence2 cell_person_evidence3
			cell_similarity1 cell_similarity2 cell_similarity3
			mol_goid1 mol_goid2 mol_goid3 
			mol_goinference1 mol_goinference2 mol_goinference3
			mol_goterm1 mol_goterm2 mol_goterm3 
			mol_paper_evidence1 mol_paper_evidence2 mol_paper_evidence3
			mol_person_evidence1 mol_person_evidence2 mol_person_evidence3 
			mol_similarity1 mol_similarity2 mol_similarity3 );

foreach my $table (@PGparameters) {			# read table data into %theHash
  $table = 'got_' . $table;
  my $result = $conn->exec( "SELECT * FROM $table;" );
  while (my @row = $result->fetchrow) {
    if ($row[0]) { 					# if there's an entry (locus)
      if ($row[0] =~ //) { $row[0] =~ s///g; }	# clean it up
      if ($row[0] =~ /^\s+/) { $row[0] =~ s/^\s+//g; }
      if ($row[0] =~ /\s+$/) { $row[0] =~ s/\s+$//g; }
      unless ($row[1]) { $theHash{$row[0]}{$table} = ''; }	# assign to %theHash if no data
        else { 
        if ($row[1] =~ //) { $row[1] =~ s///g; }
        if ($row[1] =~ /^\s+/) { $row[1] =~ s/^\s+//g; }
        if ($row[1] =~ /\s+$/) { $row[1] =~ s/\s+$//g; }
        $theHash{$row[0]}{$table} = $row[1];			# assign to %theHash if data
      } # unless ($row[1]) 
    } # if ($row[0])
  } # while (@row = $result->fetchrow)
  delete $theHash{cgc3};				# don't count sample entry
} # foreach my $table (@PGparameters)

# retarded way to get the date from postgres (default to current if no date under locus [impossible])
my $result = $conn->exec( "SELECT * FROM got_locus;" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 					# if there's an entry (locus)
    if ($row[0] =~ //) { $row[0] =~ s///g; }	# clean it up
    if ($row[0] =~ /^\s+/) { $row[0] =~ s/^\s+//g; }
    if ($row[0] =~ /\s+$/) { $row[0] =~ s/\s+$//g; }
    unless ($row[2]) { $theHash{$row[0]}{date} = &getSimpleDate(); }	# assign current date if no date
      else { 
      if ($row[2] =~ //) { $row[2] =~ s///g; }
      if ($row[2] =~ /^\s+/) { $row[2] =~ s/^\s+//g; }
      if ($row[2] =~ /\s+$/) { $row[2] =~ s/\s+$//g; }
      ($theHash{$row[0]}{date}) = $row[2] =~ m/^(.*) /;
      $theHash{$row[0]}{date} =~ s/\-//g;
    } # unless ($row[1]) 
  } # if ($row[0])
} # while (@row = $result->fetchrow)
delete $theHash{cgc3};				# don't count sample entry

my $db = 'WB';
my $db_object_symbol = '';
my $goid = '';
my $db_reference = '';
my $evidence = '';
my $db_object_type = 'protein';
my $taxon = 'taxon:6239';
# my $date = &getSimpleDate();	# Jex.pm  YearMonthDay
my $aspect = '';
# my $synonym = '';

foreach my $entry (sort keys %theHash) {
#   unless ($theHash{$entry}{got_sequence}) {		# no sequences, say so
#     print "ERROR : no sequence for $entry\n";
#   } else { # unless ($theHash{$entry}{got_sequence})	# if sequence, then
    my @db_object_id = ();		# array of db_object_id's in case there are multiple gene products (proteins)
    my $date = $theHash{$entry}{date};
    unless ($theHash{$entry}{got_protein} =~ m/(CE\d+)/) { push @db_object_id, 'nuthin'; } # commented out, no longer want if not CE # { push @db_object_id, $theHash{$entry}{got_protein}; } 
      else { @db_object_id = $theHash{$entry}{got_protein} =~ m/(CE\d+)/g; } 
    foreach my $db_object_id (@db_object_id) {
      if ($db_object_id eq 'nuthin') { $db_object_id = ''; }	# get rid if no object id
      my @ontology = qw(bio cell mol);
      for my $ontology (@ontology) {			# for each of the three ontologies
        if ($ontology eq 'bio') { $aspect = 'P'; }
        elsif ($ontology eq 'cell') { $aspect = 'C'; }
        elsif ($ontology eq 'mol') { $aspect = 'F'; } 
        else { $aspect = ''; }

        $db_object_symbol = $theHash{$entry}{got_locus};
# print "-=$theHash{$entry}{got_sequence}=-\n";
        my $synonym = '';
        if ($theHash{$entry}{got_sequence} =~ m/^([A-Z0-9]+\.\d+)/) {
# print "SEQ\n";
          ($synonym) = $theHash{$entry}{got_sequence} =~ m/^([A-Z0-9]+\.\d+)/; }
        for my $i (1 .. 3) {				# for each of the three possible entries
          $goid = '';
          my $goid_tag = 'got_' . $ontology . '_goid' . $i;
          if ($theHash{$entry}{$goid_tag}) {
            $goid = $theHash{$entry}{$goid_tag};
    
            $db_reference = '';
            my $tag = 'got_' . $ontology . '_paper_evidence' . $i;
            if ($theHash{$entry}{$tag}) {
              $db_reference = $theHash{$entry}{$tag};
              $db_reference =~ s/ /\|/g;
              my ($number) = $db_reference =~ m/(\d+)/;
              if ($number < 10000) { 
                my $key = 'cgc' . $number;
                $db_reference = $cgcHash{$key};
                $db_reference =~ s/pmid/PUBMED:/;
              }
#               $db_reference = 'DBREF ' . $db_reference . 'DBREF';
            } # if ($theHash{$entry}{$tag})
            $tag = 'got_' . $ontology . '_person_evidence' . $i;
            if ($theHash{$entry}{$tag}) {
              if ($db_reference) { $db_reference .= '|' . $theHash{$entry}{$tag}; }	# if paper, tack on extra
                else { $db_reference = $theHash{$entry}{$tag}; }				# if new, treat as single
            } # if ($theHash{$entry}{$tag})
            $db_reference =~ s/PMID/PUBMED/g;
    
            $evidence = '';
            $tag = 'got_' . $ontology . '_goinference' . $i;
            if ($theHash{$entry}{$tag}) {
              $theHash{$entry}{$tag} =~ s/ --.*$//g;
              $evidence = $theHash{$entry}{$tag};
            } # if ($theHash{$entry}{$tag})
          } # if ($theHash{$entry}{$tag})
          if ($goid) {
            print OUT "$db\t$db_object_id\t$db_object_symbol\t\t$goid\t$db_reference\t$evidence\t\t$aspect\t\t$synonym\t$db_object_type\t$taxon\t$date\n"; }
        } # for my $i (1 .. 3)
      } # for my $ontology (@ontology)
    } # foreach $db_object_id (@db_object_id)

#     if ($theHash{$entry}{got_sequence} eq 'no') {	# if no entry, use the Gene (locus)
#       print OUT "Gene : \"$theHash{$entry}{got_locus}\"\n"; 
#       print OUT $ace_entry;
#     } else { # if ($theHash{$entry}{got_sequence})	# if there's a sequence
#       if ($theHash{$entry}{got_sequence} !~ m/[ ,]/) {	# and it's just one sequence, print it
#         print OUT "Sequence : \"$theHash{$entry}{got_sequence}\"\n"; 
#         print OUT $ace_entry;
#       } else { # if ($theHash{$entry}{got_sequence} !~ m/[ ,]/)
# 							# if it's many sequences, print for each 
#         my @sequences = split /, /, $theHash{$entry}{got_sequence};
#         foreach my $seq (@sequences) {			# print separate sequences
#           print OUT "Sequence : \"$seq\"\n"; 
#           print OUT $ace_entry;
#         } # foreach my $seq (@sequences)
#       } # else # if ($theHash{$entry}{got_sequence} !~ m/[ ,]/)
#     } # else # if ($theHash{$entry}{got_sequence})
#   } # else # if ($theHash{$entry}{got_sequence})
} # foreach my $entry (sort keys %theHash)

close (OUT) or die "Cannot close $outfile : $!";

sub populateXref {              # if not found, get ref_xref data to try to find alternate
  my $result = $conn->exec( "SELECT * FROM ref_xref;" );
  while (my @row = $result->fetchrow) { # loop through all rows returned
    $cgcHash{$row[0]} = $row[1];        # hash of cgcs, values pmids
    $pmHash{$row[1]} = $row[0];         # hash of pmids, values cgcs
  } # while (my @row = $result->fetchrow)
} # sub populateXref

#   Sequence : "got_sequence"
#   GO_term "got_bio_goid1"   Paper_evidence "[got_bio_paper_evidence1]"
#   GO_term "got_bio_goid1"   Person_evidence "[got_bio_person_evidence1]"
#   GO_term "got_bio_goid1"   GO_inference_type "got_bio_goinference1"
#   GO_term "got_bio_goid1"   Similarity_evidence "got_bio_similarity1"
#   GO_term "got_bio_goid2"   Paper_evidence "[got_bio_paper_evidence2]"
#   GO_term "got_bio_goid2"   Person_evidence "[got_bio_person_evidence2]"
#   GO_term "got_bio_goid2"   GO_inference_type "got_bio_goinference2"
#   GO_term "got_bio_goid2"   Similarity_evidence "got_bio_similarity2"
#   GO_term "got_bio_goid3"   Paper_evidence "[got_bio_paper_evidence3]"
#   GO_term "got_bio_goid3"   Person_evidence "[got_bio_person_evidence3]"
#   GO_term "got_bio_goid3"   GO_inference_type "got_bio_goinference3"
#   GO_term "got_bio_goid3"   Similarity_evidence "got_bio_similarity3"
#   GO_term "got_cell_goid1"  Paper_evidence "[got_cell_paper_evidence1]"
#   GO_term "got_cell_goid1"  Person_evidence "[got_cell_person_evidence1]"
#   GO_term "got_cell_goid1"  GO_inference_type "got_cell_goinference1"
#   GO_term "got_cell_goid1"  Similarity_evidence "got_cell_similarity1"
#   GO_term "got_cell_goid2"  Paper_evidence "[got_cell_paper_evidence2]"
#   GO_term "got_cell_goid2"  Person_evidence "[got_cell_person_evidence2]"
#   GO_term "got_cell_goid2"  GO_inference_type "got_cell_goinference2"
#   GO_term "got_cell_goid2"  Similarity_evidence "got_cell_similarity2"
#   GO_term "got_cell_goid3"  Paper_evidence "[got_cell_paper_evidence3]"
#   GO_term "got_cell_goid3"  Person_evidence "[got_cell_person_evidence3]"
#   GO_term "got_cell_goid3"  GO_inference_type "got_cell_goinference3"
#   GO_term "got_cell_goid3"  Similarity_evidence "got_cell_similarity3"
#   GO_term "got_mol_goid1"   Paper_evidence "[got_mol_paper_evidence1]"
#   GO_term "got_mol_goid1"   Person_evidence "[got_mol_person_evidence1]"
#   GO_term "got_mol_goid1"   GO_inference_type "got_mol_goinference1"
#   GO_term "got_mol_goid1"   Similarity_evidence "got_mol_similarity1"
#   GO_term "got_mol_goid2"   Paper_evidence "[got_mol_paper_evidence2]"
#   GO_term "got_mol_goid2"   Person_evidence "[got_mol_person_evidence2]"
#   GO_term "got_mol_goid2"   GO_inference_type "got_mol_goinference2"
#   GO_term "got_mol_goid2"   Similarity_evidence "got_mol_similarity2"
#   GO_term "got_mol_goid3"   Paper_evidence "[got_mol_paper_evidence3]"
#   GO_term "got_mol_goid3"   Person_evidence "[got_mol_person_evidence3]"
#   GO_term "got_mol_goid3"   GO_inference_type "got_mol_goinference3"
#   GO_term "got_mol_goid3"  Similarity_evidence "got_mol_similarity3"


# got_bio_comment1
# got_bio_comment2
# got_bio_comment3
# got_bio_goid1
# got_bio_goid2
# got_bio_goid3
# got_bio_goinference1
# got_bio_goinference2
# got_bio_goinference3
# got_bio_goterm1
# got_bio_goterm2
# got_bio_goterm3
# got_bio_paper_evidence1
# got_bio_paper_evidence2
# got_bio_paper_evidence3
# got_bio_person_evidence1
# got_bio_person_evidence2
# got_bio_person_evidence3
# got_bio_similarity1
# got_bio_similarity2
# got_bio_similarity3
# got_cell_comment1
# got_cell_comment2
# got_cell_comment3
# got_cell_goid1
# got_cell_goid2
# got_cell_goid3
# got_cell_goinference1
# got_cell_goinference2
# got_cell_goinference3
# got_cell_goterm1
# got_cell_goterm2
# got_cell_goterm3
# got_cell_paper_evidence1
# got_cell_paper_evidence2
# got_cell_paper_evidence3
# got_cell_person_evidence1
# got_cell_person_evidence2
# got_cell_person_evidence3
# got_cell_similarity1
# got_cell_similarity2
# got_cell_similarity3
# got_curator
# got_locus
# got_mol_comment1
# got_mol_comment2
# got_mol_comment3
# got_mol_goid1
# got_mol_goid2
# got_mol_goid3
# got_mol_goinference1
# got_mol_goinference2
# got_mol_goinference3
# got_mol_goterm1
# got_mol_goterm2
# got_mol_goterm3
# got_mol_paper_evidence1
# got_mol_paper_evidence2
# got_mol_paper_evidence3
# got_mol_person_evidence1
# got_mol_person_evidence2
# got_mol_person_evidence3
# got_mol_similarity1
# got_mol_similarity2
# got_mol_similarity3
# got_protein
# got_sequence
