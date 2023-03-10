#!/usr/bin/perl -w

# Delete WBGenes completely from postgres from a list by Erich for Erich.  2006 09 11

use strict;
use diagnostics;
use Pg;

print "pie\n";

my $infile = 'genes_to_weed.txt';

my @tables = qw(
car_bio_maindata
car_bio_ref_curator
car_bio_ref_paper
car_bio_ref_person
car_bio_ref_reference
car_con_curator
car_con_last_verified
car_con_maindata
car_con_nodump
car_con_ref1
car_con_ref_accession
car_con_ref_curator
car_con_ref_paper
car_con_ref_person
car_con_ref_reference
car_concise
car_exp1
car_exp1_curator
car_exp1_ref1
car_exp2
car_exp2_curator
car_exp2_ref1
car_exp3
car_exp3_curator
car_exp3_ref1
car_exp4
car_exp4_curator
car_exp4_ref1
car_exp5
car_exp5_curator
car_exp5_ref1
car_exp6
car_exp6_curator
car_exp6_ref1
car_exp_maindata
car_exp_ref_curator
car_exp_ref_paper
car_exp_ref_person
car_exp_ref_reference
car_ext_curator
car_ext_maindata
car_ext_ref_curator
car_extra_provisional
car_fpa_maindata
car_fpa_ref_curator
car_fpa_ref_paper
car_fpa_ref_person
car_fpa_ref_reference
car_fpi_maindata
car_fpi_ref_curator
car_fpi_ref_paper
car_fpi_ref_person
car_fpi_ref_reference
car_gen1
car_gen1_curator
car_gen1_ref1
car_gen2
car_gen2_curator
car_gen2_ref1
car_gen3
car_gen3_curator
car_gen3_ref1
car_gen4
car_gen4_curator
car_gen4_ref1
car_gen5
car_gen5_curator
car_gen5_ref1
car_gen6
car_gen6_curator
car_gen6_ref1
car_lastcurator
car_mol_maindata
car_mol_ref_curator
car_mol_ref_paper
car_mol_ref_person
car_mol_ref_reference
car_ort1
car_ort1_curator
car_ort1_ref1
car_ort2
car_ort2_curator
car_ort2_ref1
car_ort3
car_ort3_curator
car_ort3_ref1
car_ort4
car_ort4_curator
car_ort4_ref1
car_oth1
car_oth1_curator
car_oth1_ref1
car_oth2
car_oth2_curator
car_oth2_ref1
car_oth3
car_oth3_curator
car_oth3_ref1
car_oth4
car_oth4_curator
car_oth4_ref1
car_oth5
car_oth5_curator
car_oth5_ref1
car_oth_maindata
car_oth_ref_curator
car_oth_ref_paper
car_oth_ref_person
car_oth_ref_reference
car_phe_maindata
car_phe_ref_curator
car_phe_ref_paper
car_phe_ref_person
car_phe_ref_reference
car_phy1
car_phy1_curator
car_phy1_ref1
car_phy2
car_phy2_curator
car_phy2_ref1
car_phy3
car_phy3_curator
car_phy3_ref1
car_phy4
car_phy4_curator
car_phy4_ref1
car_phy5
car_phy5_curator
car_phy5_ref1
car_phy6
car_phy6_curator
car_phy6_ref1
car_seq_maindata
car_seq_ref_accession
car_seq_ref_curator
car_seq_ref_paper
car_seq_ref_person
car_seq_ref_reference );


my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $outfile = "outfile";
open(OUT, ">$outfile") or die "Cannot create $outfile : $!";

open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $gene = <IN>) {
  chomp $gene;

  foreach my $table (@tables) {
    print "G $gene G\n";
    my $result = $conn->exec( "DELETE FROM $table WHERE joinkey = '$gene';" );
    while (my @row = $result->fetchrow) {
      if ($row[0]) { print "$row[1]\n";}
    }
  }
} # while (my $gene = <IN>)

close (IN) or die "Cannot close $infile : $!";

close (OUT) or die "Cannot close $outfile : $!";
