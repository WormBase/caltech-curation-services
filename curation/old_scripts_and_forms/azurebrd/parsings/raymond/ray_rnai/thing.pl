#!/usr/bin/perl


# Purpose:    test to see if each pcr product is the db first
# Purpose:    creates statements for construction of a RNAi ace file
#
# Checks: 1. For missing PCR_products (creates an obj if missing)
#         2. For any experiments that have no gene_pairs
# Written by: Fiona Cunningham
# Date:       13th December 2002
# Note: run the check_phenotype_rnai.pl script first check that the RNAi object
#       names are not already in the database and then phenotypes are in the db

# had to take out smd_ from gene_name in rnai_subs.pm  &put_file_in_hash to 
# match stuff here.  (how did it ever work without this ??)  2003 02 08
#
# usage : 
# ./thing.pl smd_epcr_out.txt smd_NewGenePair_data.txt > output_file
# 2003 02 08
#
# output was wrong, had extra PCR_product : output.  It was also creating
# multiple entries that were exactly the same (don't know why)  2002 02 08


use strict;
# use lib "/sde/dumpdb/RNAi/rnai_scripts/lib/";
use lib "/home/azurebrd/work/parsings/wen_rnai/";

# use constant GENE_PAIRS_FILE => "/sde/dumpdb/GENE_PAIRS/GENE_PAIRS_dumpdb_testcp.txt";
# use constant GENE_PAIRS_FILE => "/home/azurebrd/work/parsings/wen_rnai/old/GENE_PAIRS_dumpdb_testcp.txt";
use constant GENE_PAIRS_FILE => "/home/azurebrd/work/parsings/ray_rnai/20030905/GENE_PAIRS.txt";
use constant CHECK_PCR_IN_DB => 1;
use constant PIANO_DATA      => 0;
use constant FRASER_DATA     => 1;
use constant WT              => 1;

use Ace;
use Ace::Object;
use Bio::DB::GFF;
use rnai_subs;
my  $rnai_subs = rnai_subs->new();

my %pcr_f;	# forward pcr oligo
my %pcr_b;	# backward pcr oligo

my %outputhash;	# output is repeated, this hash will filter different output

use parse_fraser;
my  $parse_fraser = parse_fraser->new();

print STDERR "TRYING TO CONNECT\n";

# my $DB = Ace->connect(-host => 'aceserver.cshl.org',
# 		      -port => 2005
# 		     ) or die "can't open database : $!\n";
my $DB = Ace->connect( -path	=> '/home/acedb/WS_current',
		       -program	=> '/home/acedb/bin/tace') or die "Connection failure : ",Ace->error;

print STDERR "CONNECTED\n";

# Check that the RNAi names already in use are the same in elegans and dumpdb
#my $DB = Ace->connect(-path => '~acedb/dumpdb_test') or die "can't open db\n";


###############################################################################
# Define and open input
if (!($ARGV[1])) { die "\nUsage: input: [remap_to_wormbase output file] [data file] \n\n";}

my $data_file   = $ARGV[1];

print STDERR "DATA $data_file\n";

# Open the gene_pairs file and epcr_data and store info in hash
my $epcr_data       = $rnai_subs->open_file($ARGV[0], "^\\w" );
my $gene_pairs_data = $rnai_subs->open_file(GENE_PAIRS_FILE, ".*");

# Open file data file 
open (DATA_FILE, "<$data_file") 
  or die ("Error: can't open data file $data_file file : $!");


my $data1 = $ARGV[1];
my $data0 = $ARGV[0];

my %sequence;		# hash of sequence data, key sequence
my %pcr_prod;		# hash of oligo data, key pcr_product

&readFiles($data0, $data1);


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

    my ($forw, $back) = $line =~ m/^.*?\t(.*?)\t(.*?)\t/;
    my (@line) = split/\t/, $line;
    $line = "$line[0]\t$line[3]\t$line[4]";

    $pheno_data =$rnai_subs->put_file_in_hash($pheno_data,$line)if FRASER_DATA;

#     my ($gene) = $line =~/^smd_([#:\[\]\w]+\.?[#:\[\]\w]*)\t.*/;
    my ($gene) = $line =~/^([#:\[\]\w]+\.?[#:\[\]\w]*)\t.*/;	# no smd for fiona file
print "LINE $line\n";
    $gene =~ s/smd_//g;		# why do these have smd_ in them ?
print "GENE $gene\n";

    ### Remove this section after a bit ###
#     for my $i (0..5) {
#       if ($pheno_data->{$gene}->[$i] ne "o") {
# 	$flag = 1; 
# 	print STDERR "reject: $pheno_data : $gene : $i : $pheno_data->{$gene}->[$i] : $line";  last;
#       }
#     }
    next  if (($flag ==1) and (WT));
    #### Remove the above
#     if (!($epcr_data->{$gene}->[6])) 
    if (!($epcr_data->{$gene}->[0])) { 	# changed for simmer.txt data
      print STDERR "no remap positions for $gene\n ";
      next;
    }
#     $rnai_pcr_pair->{"smd_".$gene}= ("JA:".$gene);
    $rnai_pcr_pair->{$gene}= ("JA:".$gene);

    $pcr_f{$gene} = $forw;
    $pcr_b{$gene} = $back;

    # Create hash with data for the PCR_products that aren't in the db
#     $missing_products = $rnai_subs->check_pcrs("smd_$gene", $missing_products)
#       if CHECK_PCR_IN_DB;
    $missing_products = $rnai_subs->check_pcrs($gene, $missing_products)
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
      $gene =~ s/smd_//;

      # Create hash with data for the PCR_products that aren't in the db
      $missing_products =$rnai_subs->check_pcrs("smd_$gene", $missing_products)
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

foreach my $entry (sort keys %outputhash) {		# output filtered data
  print $entry;
} # foreach my $entry (sort keys %outputhash)


exit; # end of program

sub getStuff {
  my $sequence = shift;
# print "SEQ $sequence\n";
  foreach my $seq_line (@{ $sequence{$sequence} }) {
#     print "Sequence : $sequence\n";
    my @array = split/\t/, $seq_line;
    my $pcr_product = $array[0];
    my $high = $array[6];
    my $low = $array[5];
    my $diff = $high - $low;
#     my $spot = $pcr_product;
#     my $spot =~ s/^smd_//g;
    my $pcr_line = $pcr_prod{$pcr_product};
    my @array2 = split/\t/, $pcr_line;
    my $pcr_f = $array2[1];
    my $pcr_b = $array2[2];
    $pcr_product =~ s/smd_//g;		# take out before printing
#     print "PCR_product\tsmd_$pcr_product\t$low\t$high\n\n";
# #     print "PCR_product : smd_$pcr_product\n";		# extra line
# #     print "SMD_spot\t\"$pcr_product\"\t1\t$diff\n";		# extra line
# #     print "PCR_product\tsmd_$pcr_product\t$low\t$high\n\n";	# extra line
#     print "PCR_product : smd_$pcr_product\n";
#     print "SMD_spot\t\"$pcr_product\"\t1\t$diff\n";
#     print "Assay_conditions\t\"GenePair_protocol\"\n";
#     print "Method\t\"GenePairs\"\n\n";
#     print "Oligo :\t$pcr_f\n";
#     print "PCR_product\t\"$pcr_product\"\n";
#     print "In_sequence\t$sequence\n\n";
#     print "Oligo :\t$pcr_b\n";
#     print "PCR_product\t\"$pcr_product\"\n";
#     print "In_sequence\t$sequence\n\n\n";

    my $entry = '';			# put everything as entry, so it may be
					# filtered by a hash
    $entry .= "Sequence : $sequence\n";
    $entry .= "PCR_product\tsmd_$pcr_product\t$low\t$high\n\n";
    $entry .= "PCR_product : smd_$pcr_product\n";
    $entry .= "SMD_spot\t\"$pcr_product\"\t1\t$diff\n";
    $entry .= "Assay_conditions\t\"GenePair_protocol\"\n";
    $entry .= "Method\t\"GenePairs\"\n\n";
    $entry .= "Oligo :\t$pcr_f\n";
    $entry .= "PCR_product\t\"$pcr_product\"\n";
    $entry .= "In_sequence\t$sequence\n\n";
    $entry .= "Oligo :\t$pcr_b\n";
    $entry .= "PCR_product\t\"$pcr_product\"\n";
    $entry .= "In_sequence\t$sequence\n\n\n";
    $outputhash{$entry}++;		# put entries in hash to filter
  } # foreach my $seq (@{ $sequence{$sequence} })
  
} # sub getStuff

sub readFiles {
  my ($data0, $data1) = @_;
  open (DA0, "<$data0") or die "Cannot open $data0 : $!";
  while (<DA0>) {
    my @array = split/\t/, $_;
    push @{ $sequence{$array[7]} }, $_;
  } # while (<DA0>)
  close (DA0) or die "Cannot close $data0 : $!";
  
  open (DA1, "<$data1") or die "Cannot open $data1 : $!";
  while (<DA1>) {
    my @array = split/\t/, $_;
    my $key = $array[0];
#     $key =~ s/^smd_//g;	# took this out because it actually has smd_ in it
    $pcr_prod{$key} = $_;
  } # while (<DA1>)
  close (DA1) or die "Cannot close $data1 : $!";
} # sub readFiles



###############################################################################
sub print_ace {
  my ($missing_products, $epcr_data, $gene_pairs_data, $rnai_pcr_pair, $predicted_genes) = @_;

  foreach my $pcr (keys %$rnai_pcr_pair) {
    $pcr =~ /\w+?_(.+)/;
    my $gene =$1;

#     my $sequence = $epcr_data->{$gene}->[6];
    my $sequence = $epcr_data->{$gene}->[0];	# changed for simmer.txt data
    &getStuff($sequence);

    my $oligo_info = $gene_pairs_data->{$gene};

    # Check that there is a gene pair for the working gene
#     die "No gene pairs for $gene\n" unless $oligo_info;

    # Sequence object -> rm the existing PCR product tag
# No need to delete for Wen
#     print "\nSequence : $epcr_data->{$gene}->[6]\n";
#     print "-D PCR_product  $pcr\n"; 

    # Sequence object -> add the tag
#     print "\nSequence : $epcr_data->{$gene}->[6]\n";
#     print "PCR_product  $pcr  $epcr_data->{$gene}->[7]   $epcr_data->{$gene}->[8]\n\n";

    # Print out the RNAi data
# Don't print for Wen
#     $parse_fraser->print_rnai_obj
#       ($pcr, $pheno_data, $rnai_pcr_pair->{$pcr}, $predicted_genes->{$pcr}, $DB, WT) if FRASER_DATA;

    # Print out PCR_products and Oligos for those which aren't in the db
#     next unless $missing_products->{$gene};
#     if ($missing_products->{$gene} ne $pcr) {die "Die: Error in file \n";}

# use rnai_subs.pm
#     $rnai_subs->print_pcr_oligo($pcr, $rnai_pcr_pair->{$pcr}, $oligo_info, 
# 		      $epcr_data->{$gene}->[6] );

# use local sub
#     &print_pcr_oligos($pcr, $rnai_pcr_pair->{$pcr}, $oligo_info, 
# 		      $epcr_data->{$gene}->[6], $epcr_data->{$gene}->[7], 
#                       $epcr_data->{$gene}->[8] );

  }
} # end of sub print_ace

sub print_pcr_oligos {
  my ($pcr, $rnai, $oligo_info, $in_sequence, $low, $high) = @_;

  my $diff = $high - $low;

  my $gene = $pcr;
  $gene =~ s/smd_//;
#   my $pcr_f = $pcr . "_f";
#   my $pcr_b = $pcr . "_b";
      
  # PCR product
    print "PCR_product : $pcr\n";
    print "SMD_spot      \"$gene\"\t1\t$diff\n";
    print "Assay_conditions   \"GenePair_protocol\"\n";
    print "Method        \"GenePairs\"\n\n";
    
    # Oligo object
    print "Oligo :        $pcr_f{$gene}\n";
    print "PCR_product   \"$pcr\" \n";
    print "In_sequence   $in_sequence\n\n";

    print "Oligo :        $pcr_b{$gene}\n";
    print "PCR_product   \"$pcr\" \n";
    print "In_sequence   $in_sequence\n\n";

} # end sub print_pcr_oligo



###############################################################################
sub is_list_in_db {
  my ($class, $list) = @_;
  my $query = qq(select a from a in class $class);

#   my $tmp_DB = Ace->connect(-path => '~acedb/dumpdb') or die "can't open db\n";
  my $tmp_DB = Ace->connect( -path	=> '/home/acedb/WS_current',
			     -program	=> '/home/acedb/bin/tace') or die "Connection failure : ",Ace->error;
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
