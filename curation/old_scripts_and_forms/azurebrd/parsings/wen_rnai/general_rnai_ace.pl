#!/usr/lib/perl -w

# Purpose:    test to see if each pcr product is the db first
# Purpose:    creates statements for construction of a RNAi ace file
#
# Checks: 1. For missing PCR_products (creates an obj if missing)
#         2. For any experiments that have no gene_pairs
# Written by: Fiona Cunningham
# Date:       13th December 2002
# Note: run the check_phenotype_rnai.pl script first check that the RNAi object
#       names are not already in the database and then phenotypes are in the db


use strict;
# use lib "/sde/dumpdb/RNAi/rnai_scripts/lib/";
use lib "/home/azurebrd/work/parsings/wen_rnai/";

use constant GENE_PAIRS_FILE => "/sde/dumpdb/GENE_PAIRS/GENE_PAIRS_dumpdb_testcp.txt";
use constant CHECK_PCR_IN_DB => 1;
use constant PIANO_DATA      => 0;
use constant FRASER_DATA     => 1;
use constant WT              => 1;

use Ace;
use Ace::Object;
use Bio::DB::GFF;
use rnai_subs;
my  $rnai_subs = rnai_subs->new();

use parse_fraser;
my  $parse_fraser = parse_fraser->new();

my $DB = Ace->connect(-host => 'www.wormbase.org',
		      -port => 2005) or die "can't open database\n";


# Check that the RNAi names already in use are the same in elegans and dumpdb
#my $DB = Ace->connect(-path => '~acedb/dumpdb_test') or die "can't open db\n";


###############################################################################
# Define and open input
if (!($ARGV[1])) { die "\nUsage: input: [remap_to_wormbase output file] [data file] \n\n";}

my $data_file   = $ARGV[1];

# Open the gene_pairs file and epcr_data and store info in hash
my $epcr_data       = $rnai_subs->open_file($ARGV[0], "^\\w" );
my $gene_pairs_data = $rnai_subs->open_file(GENE_PAIRS_FILE, ".*");

# Open file data file 
open (DATA_FILE, $data_file) 
  or die ("Error: can't open data file $data_file file");



###############################################################################
my $missing_products; my $predicted_genes;
my $rnai_pcr_pair;
my $rnai;
my $pheno_data;

print STDERR "Checking for missing PCR_products and predicted genes\n";
if (FRASER_DATA) {
  while (my $line = <DATA_FILE>) { 
    my $flag =0;
    next if ($line =~/^GenePairs/);
    $pheno_data =$rnai_subs->put_file_in_hash($pheno_data,$line)if FRASER_DATA;

    my ($gene) = $line =~/^(\w+\.?\w*)\t.*/;

    ### Remove this section after a bit ###
    for my $i (0..5) {
      if ($pheno_data->{$gene}->[$i] ne "o") {
	$flag = 1; 
	print STDERR "reject: $line";  last;
      }
    }
    next  if (($flag ==1) and (WT));
    #### Remove the above
    if (!($epcr_data->{$gene}->[6])) {
      print STDERR "no remap positions for $gene\n ";
      next;
    }
    $rnai_pcr_pair->{"sjj_".$gene}= ("JA:".$gene);

    # Create hash with data for the PCR_products that aren't in the db
    $missing_products = $rnai_subs->check_pcrs("sjj_$gene", $missing_products)
      if CHECK_PCR_IN_DB;
  }
} # end of if FRASER_DATA

if (PIANO_DATA) {
  while (my $line = <DATA_FILE>) { 
    if ($line =~ /RNAi : \"(.+)\"/){
      $rnai = $1;
    }
    elsif ($line =~/PCR_product \s+ \"  (.+)  \"  /x) {
      $rnai_pcr_pair->{$1}= $rnai;  # The key is the PCR_product

      my $gene = $1;
      $gene =~ s/sjj_//;

      # Create hash with data for the PCR_products that aren't in the db
      $missing_products =$rnai_subs->check_pcrs("sjj_$gene", $missing_products)
      if CHECK_PCR_IN_DB;
    }
  }
} # end of if PIANO_DATA

print STDERR "Checking the RNAi object names\n";
# Send all the proposed new RNAi object names.  Checks to see if they are already in the db.  If the name is already in use, a new unique name will be assigned.
$rnai_pcr_pair = is_list_in_db("RNAi", $rnai_pcr_pair);


print STDERR "Starting to print out data \n";
# Print out RNAi, Oligo and PCR_product objects as necessary.
# Also print a line to remove the old PCR_product location from its linked cosmid and upgrade it.
print_ace ($missing_products, $epcr_data, $gene_pairs_data, $rnai_pcr_pair, $predicted_genes);



exit; # end of program



###############################################################################
sub print_ace {
  my ($missing_products, $epcr_data, $gene_pairs_data, $rnai_pcr_pair, $predicted_genes) = @_;

  foreach my $pcr (keys %$rnai_pcr_pair) {
    $pcr =~ /\w+?_(.+)/;
    my $gene =$1;
    my $oligo_info = $gene_pairs_data->{$gene};

    # Check that there is a gene pair for the working gene
    die "No gene pairs for $gene\n" unless $oligo_info;

    # Sequence object -> rm the existing PCR product tag
    print "\nSequence : $epcr_data->{$gene}->[6] \n";
    print "-D PCR_product  $pcr \n"; 

    # Sequence object -> add the tag
    print "\nSequence : $epcr_data->{$gene}->[6] \n";
    print "PCR_product  $pcr  $epcr_data->{$gene}->[7]   $epcr_data->{$gene}->[8] \n\n";

    # Print out the RNAi data
    $parse_fraser->print_rnai_obj
      ($pcr, $pheno_data, $rnai_pcr_pair->{$pcr}, $predicted_genes->{$pcr}, $DB, WT) if FRASER_DATA;

    # Print out PCR_products and Oligos for those which aren't in the db
    next unless $missing_products->{$gene};
    if ($missing_products->{$gene} ne $pcr) {die "Die: Error in file \n";}

    $rnai_subs->print_pcr_oligo($pcr, $rnai_pcr_pair->{$pcr}, $oligo_info, 
		      $epcr_data->{$gene}->[6] );

  }
} # end of sub print_ace


###############################################################################
sub is_list_in_db {
  my ($class, $list) = @_;
  my $query = qq(select a from a in class $class);

  my $tmp_DB = Ace->connect(-path => '~acedb/dumpdb') or die "can't open db\n";
  my @class_members = $tmp_DB->aql($query);

my @tmp;
  foreach (@class_members) {
    foreach (@$_) {  push (@tmp, $_);    }
  }
my %members =  map {$_ =>1} @tmp;

  # Check to see whether each class is in db
  foreach my $pcr (keys %$list) {
       if ($members{ $list->{$pcr} }) {  # if the name is already in db
	 my $rnai = $list->{$pcr};
	 my $i = 1;
	 my $test = $rnai."($i)";
	 while ($tmp_DB->aql
		("select a from a in class $class where a like \"$test\"")) {
	   $i++;
	   $test = $rnai."($i)";
	 }
	 $list->{$pcr} = $test;
       } # end of if $members
  } # end of foreach

  return $list;
} # end of sub
