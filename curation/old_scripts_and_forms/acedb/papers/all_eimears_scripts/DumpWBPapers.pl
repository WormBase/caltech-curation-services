#!/usr/bin/perl -w

# This program queries wormbase using aceperl to batch
# download object data classes!
#
# USAGE: ./DumpFromWormbase.pl
#
#
# BEGIN PROGRAM
# 

### modules

use Ace;                                                              # uses aceperl module
use strict;

#use constant HOST => $ENV{ACEDB_HOST} || 'www.wormbase.org';
#use constant PORT => $ENV{ACEDB_PORT} || 2007;
  
### variables

#my $outpath = "/home/abstracts/WBPapers/";      # path to outfile
my $outpath = "/home/eimear/abstracts/WBPapers/";      # path to outfile

$|=1;  # forces output buffer to flush after every print statement!

# connects to wormbase using aceperl

#print "Opening the database....";
#my $db = Ace->connect(-host=>HOST,-port=>PORT) || die "Connection failure: ",Ace->error;
#print "done.\n";

#print "Opening the database....";
#my $db = Ace->connect(-path => '/home/eimear/acedb/WS_current');
#my $db = Ace->connect(-path => '/home/eimear/acedb/WS_empty');
#print "done\n";

print "\n\nWould you like to connect to [W]ormbase or [A]CeDB? ";
my $ans = <STDIN>;

my $db = "";
if ($ans =~ /[Ww]/){
############# WORMBASE
    use constant HOST => $ENV{ACEDB_HOST} || 'www.wormbase.org';
    use constant PORT => $ENV{ACEDB_PORT} || 2007;
    
    print "Opening the database....";
    $db = Ace->connect(-host=>HOST,-port=>PORT) || die "Connection failure: ",Ace->error;
    print "done.\n";
    } elsif ($ans =~ /[Aa]/){
 
######### ACEDB
# note: when wormbase server is down or super slow, you can use your local
# version of acedb ( as long as you have giface installed) by pointing this to 
# your current db and uncommentting the code below ( you will have to comment 
# the code marked #### wormbase above). 

	print "Opening the database....";
#my $db = Ace->connect(-path => '/home/eimear/acedb/WS_current');
# connects to wormbase using aceperl
	$db = Ace->connect(-path => '/home/acedb/WS_current');
	print "done\n";
    }else {exit}

my $term = "Paper";

my $count = $db->count($term => '*');
print "\nThere are $count terms in the $term data class.\n";
print "Downloading now .......";
my $outfile = "$outpath"."${term}.dump";   
open (OUT, ">$outfile") or die "Cannot create $outfile : $!";  
my $i = $db->fetch_many($term => '*');                     
while (my $obj = $i->next) {
    print OUT $obj->asTable;
}

close (OUT) or die "Cannot close $outfile : $!";
print "done.\n\n";
