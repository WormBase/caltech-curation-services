#!/usr/bin/perl -w

# Purpose: prepare data for RNAi, PCR_product and/or Oligo objects in acedb
# Output:  prints RNAi, Oligo and PCR_product objects as necessary (ace format)
# Output:  prints line to rm old PCR_product locations from their linked cosmid
#          prints new line to upgrade it.
# Checks:  for new PCR_products and adds a new PCR_prod & Oligo obj for each
# Checks:  to see if  RNAi object names are already in use
# Checks:  to see if the RNAi object has a remap position
# Author:  Fiona Cunningham
# Date:    Dec 2002

# Usage and input
if (!($ARGV[1])) { die "

USAGE: $0   [remap_to_wormbase output]  [data file] [option: WT data?]

PURPOSE: for creating PCR_product, RNAi and/or Oligo objects for acedb.

INPUTS:
* Remap_to_wormbase file: to create this file use either
   a. ePCR search page (www.wormbase.org/db/searches/epcr)
   b. script (brie2:/usr/local/wormbase/util/remap_to_wormbase.pl)
Primer pairs for wb genes are in brie2:", GENE_PAIRS_FILE,".
* Data file: Data to be processed to make acedb objects.
* Option WT data: if all the RNAi data is wildtype, type \"WT\".
\n
";}


###############################################################################
use strict;
# use constant GENE_PAIRS_FILE => "/sde/dumpdb/GENE_PAIRS/GENE_PAIRS.txt";
# this is not the right file, using old below from wen's rnai
use constant GENE_PAIRS_FILE => "/home/azurebrd/work/parsings/wen_rnai/old/GENE_PAIRS_dumpdb_testcp.txt";
use constant FRASER_DATA     => 1;
use constant WT              => $ARGV[2];  # Switches on printing WT pheno
use constant DUPLICATE_RNAi  => 1;         # allow RNAi names to be incremental

use Ace;
use Ace::Object;
use Bio::DB::GFF;
# use lib "lib/";		# using test directory, so add line below instead
use lib qw( /home/azurebrd/work/parsings/ray_fiona/lib/ );
use RNAiSubs;
use ParseFraser;
# use ParsePiano;		# don't have this module

my $parse_data;
# Add a line for your data-specific parse if necessary.
$parse_data = ParseFraser->new() if FRASER_DATA;

# Databases and Open files
my $DB = Ace->connect( -path    => '/home/acedb/WS_current',
                       -program => '/home/acedb/bin/tace') or die "Connection failure : ",Ace->error;
print STDERR "CONNECTED\n";
# my $DB = Ace->connect(-host => 'www.wormbase.org',
# 		      -port => 2005) or die "can't open database\n";


# HASHES for remap_to_wormbase and gene_pairs data with GENE NAME as the key
my $remap_data       = RNAiSubs::open_file($ARGV[0], "^\\w" );
my $gene_pairs_data  = RNAiSubs::open_file(GENE_PAIRS_FILE, ".*");
my $data_file        = $ARGV[1];


###############################################################################
print STDERR "Checking db for missing PCR_products -> will create a new PCR_product and Oligo object for missing PCR_product\n";

# Create a three hash refs
# 1. $rnai_pcr_pair    with keys as RNAi name, value = PCR_product
# 2. $missing_products with keys as gene name, value = PCR_product
# 3. $pheno_data with keys as gene name 

my ($rnai_pcr_pair, $missing_products, $pheno_data) = 
  $parse_data->rnai_pcr_hash($data_file, $remap_data,WT);


# Check all the proposed new RNAi object names to see if they are already in the db.  If the name is already in use, a new unique name will be assigned.
print STDERR "Checking the RNAi object names\n";
$rnai_pcr_pair= RNAiSubs::is_list_in_db("RNAi",$rnai_pcr_pair,DUPLICATE_RNAi);

print STDERR "Starting to print out PCR_product/ RNAi/ Oligo data \n";
RNAiSubs::print_ace($DB, $missing_products, $remap_data, $gene_pairs_data, $rnai_pcr_pair, $parse_data, WT, $pheno_data);

exit; # end of program


