#!/usr/bin/perl -w

# This program queries Wormbase/ACeDB using AQL to batch
# download Gene identifiers, CGC names and Sequence names.
#
# USAGE: ./DumpGenesFromWB.pl
#
#
# BEGIN PROGRAM
# 

### modules

use Ace;                            # uses aceperl module
use strict;

$|=1;  # forces output buffer to flush after every print statement!


############# WORMBASE
use constant HOST => $ENV{ACEDB_HOST} || 'aceserver.cshl.org';
use constant PORT => $ENV{ACEDB_PORT} || 2005;
    
print "Opening the database....";
my $db = Ace->connect(-host=>HOST,-port=>PORT) || die "Connection failure: ",Ace->error;
print "done.\n";

######### ACEDB
# note: when wormbase server is down or super slow, you can use your local
# version of acedb ( as long as you have giface installed) by pointing this to 
# your current db and uncommentting the code below ( you will have to comment 
# the code marked #### wormbase above). 

#print "Opening the database....";
## connects to wormbase using aceperl
#my $db = Ace->connect(-path => 'PATH TO ACEDB');
#print "done\n";

my $genes = $db->fetch_many(Gene=>'*');


while (my $i = $genes->next){
    my ($wbid, $gene, $seq) = "";
    
    $wbid = $i;
    $gene = $i->CGC_name;
    $seq = $i->Sequence_name;
    
    next unless defined($wbid);

    if ((defined ($gene)) && (defined ($seq))){print $wbid . "\t" . $gene . "\t" . $seq . "\n"}
    elsif (defined($gene)){print $wbid . "\t" . $gene . "\n"}
    elsif (defined($seq)){print $wbid . "\t\t\t" . $seq . "\n"}
}


