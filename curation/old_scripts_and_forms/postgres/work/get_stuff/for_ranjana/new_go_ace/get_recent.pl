#!/usr/bin/perl -w
#
# Get got_ data from PG and write new .ace format.  2003 02 14
#
# Filter $goid to get rid of spaces before and after.
# Get WBPerson number instead of Kishore or Schwarz.  2003 02 25

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $outfile = "outfile";
open(OUT, ">$outfile") or die "Cannot create $outfile : $!";

# print OUT "GENE FUNCTION\n\n";

my @go_tables = qw( got_bio_comment1 got_bio_comment2 got_bio_comment3 got_bio_comment4 got_bio_goid1 got_bio_goid2 got_bio_goid3 got_bio_goid4 got_bio_goinference1 got_bio_goinference2 got_bio_goinference3 got_bio_goinference4 got_bio_goinference_two1 got_bio_goinference_two2 got_bio_goinference_two3 got_bio_goinference_two4 got_bio_goterm1 got_bio_goterm2 got_bio_goterm3 got_bio_goterm4 got_bio_paper_evidence1 got_bio_paper_evidence2 got_bio_paper_evidence3 got_bio_paper_evidence4 got_bio_person_evidence1 got_bio_person_evidence2 got_bio_person_evidence3 got_bio_person_evidence4 got_bio_similarity1 got_bio_similarity2 got_bio_similarity3 got_bio_similarity4 got_cell_comment1 got_cell_comment2 got_cell_comment3 got_cell_comment4 got_cell_goid1 got_cell_goid2 got_cell_goid3 got_cell_goid4 got_cell_goinference1 got_cell_goinference2 got_cell_goinference3 got_cell_goinference4 got_cell_goinference_two1 got_cell_goinference_two2 got_cell_goinference_two3 got_cell_goinference_two4 got_cell_goterm1 got_cell_goterm2 got_cell_goterm3 got_cell_goterm4 got_cell_paper_evidence1 got_cell_paper_evidence2 got_cell_paper_evidence3 got_cell_paper_evidence4 got_cell_person_evidence1 got_cell_person_evidence2 got_cell_person_evidence3 got_cell_person_evidence4 got_cell_similarity1 got_cell_similarity2 got_cell_similarity3 got_cell_similarity4 got_curator got_goterm got_locus got_mol_comment1 got_mol_comment2 got_mol_comment3 got_mol_comment4 got_mol_goid1 got_mol_goid2 got_mol_goid3 got_mol_goid4 got_mol_goinference1 got_mol_goinference2 got_mol_goinference3 got_mol_goinference4 got_mol_goinference_two1 got_mol_goinference_two2 got_mol_goinference_two3 got_mol_goinference_two4 got_mol_goterm1 got_mol_goterm2 got_mol_goterm3 got_mol_goterm4 got_mol_paper_evidence1 got_mol_paper_evidence2 got_mol_paper_evidence3 got_mol_paper_evidence4 got_mol_person_evidence1 got_mol_person_evidence2 got_mol_person_evidence3 got_mol_person_evidence4 got_mol_similarity1 got_mol_similarity2 got_mol_similarity3 got_mol_similarity4 got_obsoleteterm got_pro_paper_evidence got_protein got_provisional got_sequence );

my %theHash;
my @sequences;		# all sequences

my %pmHash;		# hash of pmids, values cgcs

my $result = $conn->exec( "SELECT joinkey FROM got_sequence;" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    push @sequences, $row[0];
  } # if ($row[0])
} # while (@row = $result->fetchrow)

&populateXref();
foreach my $sequence (@sequences) {
  if ($sequence eq 'cgc3') { next; }		# ignore testing data
  %theHash = ();
  foreach my $go_table (@go_tables) {
    my $hash_key = $go_table;
    $hash_key =~ s/^got_//;
    $result = $conn->exec( "SELECT * FROM $go_table WHERE joinkey = '$sequence';" );
    while (my @row = $result->fetchrow) {
      if ($row[0]) { 
        $row[0] =~ s///g;
        if ($row[1]) { $row[1] =~ s///g; }	# sub out line breaks if there's data
        $theHash{$hash_key}{value} = $row[1];
      } # if ($row[0])
    } # while (@row = $result->fetchrow)
  } # foreach my $go_table (@go_tables)
  &outputAce();
} # foreach my $sequence (@sequences)

  
close (OUT) or die "Cannot close $outfile : $!";


sub outputAce {
  
  unless ($theHash{sequence}{value}) {             # no sequences, say so
    print "<FONT COLOR='red'>WARNING : no sequence for $theHash{locus}{value}</FONT><BR>\n";
  } else { # unless ($theHash{sequence})    # if sequence, then
    my $ace_entry = '';                                 # initialize entry
    my @ontology = qw(bio cell mol);
    foreach my $ontology (@ontology) {                      # for each of the three ontologies
      for my $i (1 .. 4) {                              # for each of the three possible entries
        my $goid_tag = $ontology . '_goid' . $i;
        if ($theHash{$goid_tag}{value}) {
          my $goid = $theHash{$goid_tag}{value};
	  $goid =~ s/^\s+//g; $goid =~ s/\s+$//g;

          my @evidence_tags = qw( _goinference _goinference_two );	# the inference types
	  foreach my $ev_tag (@evidence_tags) { 		# for each of the inference types
            my $evidence_tag = $ontology . $ev_tag . $i;	# get evidence tag
            if ($theHash{$evidence_tag}{value}) {
 	      my $inference = $theHash{$evidence_tag}{value};	# the inference type
	      $inference =~ s/ --.*$//g;

              my $is_evidence_flag = 0;

              my $tag = $ontology . '_paper_evidence' . $i;
              if ($theHash{$tag}{value}) {
                if ($theHash{$tag}{value} !~ m/[ ,]/) {		# and it's just one paper, print it
                  if ($theHash{$tag}{value} =~ m/PMID:(\d+)/) { 	# if it's a pmid, change it to cgc 
                    if ($pmHash{'pmid'.$1}) { $theHash{$tag}{value} = $pmHash{'pmid'.$1}; }	# if cgc, change
                  }
		  $theHash{$tag}{value} =~ s/^\s+//g; $theHash{$tag}{value} =~ s/\s+$//g;
                  $ace_entry .= "GO_term\t\"$goid\"\t\"$inference\"\tPaper_evidence\t\"[$theHash{$tag}{value}]\"\n";
		  $is_evidence_flag++;
                } else { 
                  my @papers = split /, /, $theHash{$tag}{value};
                  foreach my $paper (@papers) {			# print separate papers
                    if ($paper =~ m/PMID:(\d+)/) {			# if it's a pmid, change it to cgc 
                      if ($pmHash{'pmid'.$1}) { $paper = $pmHash{'pmid'.$1}; }	# if cgc, change
                    }
		    $paper =~ s/^\s+//g; $paper =~ s/\s+$//g;
                    $ace_entry .= "GO_term\t\"$goid\"\t\"$inference\"\tPaper_evidence\t\"[$paper]\"\n";
		  $is_evidence_flag++;
                  } # foreach my $paper (@papers)
                } # else # if ($theHash{$tag}{value} !~ m/[ ,]/)
              } # if ($theHash{$tag}{value})
    
              $tag = $ontology . '_person_evidence' . $i;
              if ($theHash{$tag}{value}) {
                if ($theHash{$tag}{value} =~ m/Kishore/) {
                  $ace_entry .= "GO_term\t\"$goid\"\t\"$inference\"\tPerson_evidence\t\"WBPerson324\"\n";
                } elsif ($theHash{$tag}{value} =~ m/Schwarz/) {
                  $ace_entry .= "GO_term\t\"$goid\"\t\"$inference\"\tPerson_evidence\t\"WBPerson567\"\n";
                } else {
                  $ace_entry .= "GO_term\t\"$goid\"\t\"$inference\"\tPerson_evidence\t\"$theHash{$tag}{value}\"\n";
                }
		$is_evidence_flag++;
              } # if ($theHash{$tag}{value})

              $tag = $ontology . '_similarity' . $i;
              if ($theHash{$tag}{value}) {
                $ace_entry .= "GO_term\t\"$goid\"\t\"$inference\"\tProtein_id_evidence\t\"$theHash{$tag}{value}\"\n";
		$is_evidence_flag++;
              } # if ($theHash{$tag}{value})

	      if ($is_evidence_flag == 0) { 
                $ace_entry .= "GO_term\t\"$goid\"\t\"$inference\"\tPerson_evidence\t\"WBPerson324\"\n";
              }
            } # if ($theHash{$evidence_tag}{value})
	  } # foreach my $ev_tag (@evidence_tags)
        } # if ($theHash{$goid_tag}{value})
      } # for my $i (1 .. 4)
    } # for my $ontology (@ontology)
    $ace_entry .= "\n";                                 # add separator

    if ($theHash{sequence}{value} eq 'no') {       # if no entry, use the Gene (locus)
      print OUT "Locus : \"$theHash{locus}{value}\"\n";
      print OUT $ace_entry;
    } else { # if ($theHash{sequence}{value})      # if there's a sequence
      if ($theHash{sequence}{value} !~ m/[ ,]/) {  # and it's just one sequence, print it
        $theHash{sequence}{value} =~ s/^\s+//g; $theHash{sequence}{value} =~ s/\s+$//g;
        print OUT "Sequence : \"$theHash{sequence}{value}\"\n";
        print OUT $ace_entry;
      } else { # if ($theHash{sequence}{value} !~ m/[ ,]/)
                                                        # if it's many sequences, print for each
        my @sequences = split /, /, $theHash{sequence}{value};
        foreach my $seq (@sequences) {                  # print separate sequences
	  $seq =~ s/^\s+//g; $seq =~ s/\s+$//g;
          print OUT "Sequence : \"$seq\"\n";
          print OUT $ace_entry;
        } # foreach my $seq (@sequences)
      } # else # if ($theHash{sequence}{value} !~ m/[ ,]/)
    } # else # if ($theHash{sequence}{value})
  } # else # if ($theHash{sequence}{value})
#   print "See all ace.ace <A HREF=\"http://minerva.caltech.edu/~postgres/cgi-bin/data/go.ace\">data</A>.<BR>";
} # sub outputAce

sub populateXref {              # if not found, get ref_xref data to try to find alternate
  my $result = $conn->exec( "SELECT * FROM ref_xref;" );
  while (my @row = $result->fetchrow) { # loop through all rows returned
    $pmHash{$row[1]} = $row[0];         # hash of pmids, values cgcs
  } # while (my @row = $result->fetchrow)
} # sub populateXref
