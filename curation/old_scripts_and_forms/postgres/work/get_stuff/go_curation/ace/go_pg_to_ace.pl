#!/usr/bin/perl -w
#
# script to get data from go_curation

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $outfile = "/home/postgres/work/get_stuff/go_curation/ace/outfile.ace";
open(OUT, ">$outfile") or die "Cannot create $outfile : $!";

my %theHash;

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

foreach my $entry (sort keys %theHash) {
  unless ($theHash{$entry}{got_sequence}) {		# no sequences, say so
    print "ERROR : no sequence for $entry\n";
  } else { # unless ($theHash{$entry}{got_sequence})	# if sequence, then
    my $ace_entry = '';					# initialize entry
    my @ontology = qw(bio cell mol);
    for my $ontology (@ontology) {			# for each of the three ontologies
      for my $i (1 .. 3) {				# for each of the three possible entries
        my $goid_tag = 'got_' . $ontology . '_goid' . $i;
        if ($theHash{$entry}{$goid_tag}) {
          my $goid = $theHash{$entry}{$goid_tag};
  
          my $tag = 'got_' . $ontology . '_paper_evidence' . $i;
          if ($theHash{$entry}{$tag}) {
            $ace_entry .= "GO_term\t\"$goid\"\tPaper_evidence\t\"[$theHash{$entry}{$tag}]\"\n";
          } # if ($theHash{$entry}{$tag})
  
          $tag = 'got_' . $ontology . '_person_evidence' . $i;
          if ($theHash{$entry}{$tag}) {
            $ace_entry .= "GO_term\t\"$goid\"\tPerson_evidence\t\"$theHash{$entry}{$tag}\"\n";
          } # if ($theHash{$entry}{$tag})
  
          $tag = 'got_' . $ontology . '_goinference' . $i;
          if ($theHash{$entry}{$tag}) {
            $theHash{$entry}{$tag} =~ s/ --.*$//g;
            $ace_entry .= "GO_term\t\"$goid\"\tGO_inference_type\t\"$theHash{$entry}{$tag}\"\n";
          } # if ($theHash{$entry}{$tag})
  
          $tag = 'got_' . $ontology . '_similarity' . $i;
          if ($theHash{$entry}{$tag}) {
            $ace_entry .= "GO_term\t\"$goid\"\tSimilarity_evidence\t\"$theHash{$entry}{$tag}\"\n";
          } # if ($theHash{$entry}{$tag})
        } # if ($theHash{$entry}{$tag})
      } # for my $i (1 .. 3)
    } # for my $ontology (@ontology)
    $ace_entry .= "\n";					# add separator

    if ($theHash{$entry}{got_sequence} eq 'no') {	# if no entry, use the Gene (locus)
      print OUT "Locus : \"$theHash{$entry}{got_locus}\"\n"; 
      print OUT $ace_entry;
    } else { # if ($theHash{$entry}{got_sequence})	# if there's a sequence
      if ($theHash{$entry}{got_sequence} !~ m/[ ,]/) {	# and it's just one sequence, print it
        print OUT "Sequence : \"$theHash{$entry}{got_sequence}\"\n"; 
        print OUT $ace_entry;
      } else { # if ($theHash{$entry}{got_sequence} !~ m/[ ,]/)
							# if it's many sequences, print for each 
        my @sequences = split /, /, $theHash{$entry}{got_sequence};
        foreach my $seq (@sequences) {			# print separate sequences
          print OUT "Sequence : \"$seq\"\n"; 
          print OUT $ace_entry;
        } # foreach my $seq (@sequences)
      } # else # if ($theHash{$entry}{got_sequence} !~ m/[ ,]/)
    } # else # if ($theHash{$entry}{got_sequence})
  } # else # if ($theHash{$entry}{got_sequence})
} # foreach my $entry (sort keys %theHash)

close (OUT) or die "Cannot close $outfile : $!";

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
