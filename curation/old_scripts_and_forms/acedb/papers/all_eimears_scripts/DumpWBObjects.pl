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

use Ace;                          # uses aceperl module
use strict;

 
### variables
print "\n\nWhat WS release is this? ";
my $WS = <STDIN>;
my $lastWS = $WS - 1;

my $oldacedumpdir = "/home2/eimear/abstracts/ACEDUMPS";
my $oldacedumpdirstore = "/home2/eimear/abstracts/OLDACEDUMPS";
if (-e $oldacedumpdir){
    print "\n\n...moving $oldacedumpdir to $oldacedumpdirstore....";
    my @args = ("mv", "$oldacedumpdir", "$oldacedumpdirstore/ACEDUMPS_$lastWS");
    system(@args) == 0
	or die "system @args failed: $?";
    print "done.\n";
}else {print "\n\nThere is no previous ACEDUMPS directory!\n\n";}

my $outpath = "/home2/eimear/abstracts/ACEDUMPS";      # path to outfile

print "Making new directory....";
my @args2 = ("mkdir", "$outpath");
system(@args2) == 0
or die "system @args2 failed: $?";
print "done.\n";

my ($in, %HoH3, @Input, $i, @terms);



$|=1;  # forces output buffer to flush after every print statement!

# list of all object class names which can be downloaded from WormBase

my @all_classes = qw(
		   2_point_data
		   Author
		   Class
		   Comment
		   Contig
		   Database
		   Display
		   DNA
		   Expr_pattern
		   Expr_profile
		   Gene_Class
		   Homol_data
		   Journal
		   Keyword
		   Laboratory
		   Lineage
		   Map
		   Method
		   Motif
		   Movie
		   Multi_pt_data
		   Oligo
		   Paper
		   PCR_product
		   Phenotype
		   Picture
		   Pos_neg_data
		   Protein
		   Reference
		   Repeat_Info
		   RNAi
		   Sequence
		   Session
		   SK_map
		   Species
		   Table
		   Tag
		   Url
		   WTP
		   Locus 
		   Allele 
		   Rearrangement 
		   Strain                         
		   Clone 
 		   Cell 
 		   Cell_group 
 		   Life_stage 
 		   RNAi 
                   Transgene 
 		   Gene 
 		   GO_term 
 		   Operon
 		   );
 
# list of object classes that are used to mark up CGC abstracts

my @cgc_classes = qw(
		   Allele 
		   Rearrangement 
		   Strain                         
		   Clone 
 		   Cell 
 		   Cell_group 
 		   Life_stage 
 		   RNAi 
                   Transgene 
 		   GO_term 
 		   Operon
 		   );

# list of most popular object class names which can be downloaded from WormBase
# please edit this list as desired!

my @refers_to = qw(
		   Locus 
		   Allele 
		   Rearrangement 
		   Strain                         
		   Clone 
 		   Cell 
 		   Cell_group 
 		   Life_stage 
 		   RNAi 
                   Transgene 
 		   Gene 
		   Phenotype
 		   GO_term 
 		   Operon
 		   );
  




print "\n\nWould you like to connect to [W]ormbase or [A]CeDB? ";
my $ans = <STDIN>;

my $db = "";
if ($ans =~ /[Ww]/){
############# WORMBASE
#    use constant HOST => $ENV{ACEDB_HOST} || 'www.wormbase.org';
#    use constant PORT => $ENV{ACEDB_PORT} || 2007;

    use constant HOST => $ENV{ACEDB_HOST} || 'aceserver.cshl.org';
    use constant PORT => $ENV{ACEDB_PORT} || 2005;
    
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
#my $db = Ace->connect(-path => '/home2/eimear/acedb/WS_current');
# connects to wormbase using aceperl
	$db = Ace->connect(-path => '/home2/eimear/acedb/WS_current');
	print "done\n";
    }else {exit}


&printList(@refers_to);
chomp (my $val = <STDIN>);
my @Val = split (/ /, $val);
foreach (@Val){
    if ($_ == 1){@terms = @all_classes}
    if ($_ == 2){@terms = @cgc_classes}
    if ($_ => 3){for (keys %{$HoH3{$_} }){@terms = $_}}
    for my $term ( @terms  ){
	my $count = $db->count($term => '*');
	print "\nThere are $count terms in the $term data class.\n";
	print "Downloading now .......";
	my $outfile = "$outpath/"."${term}.dump";                          # names outfile, <object class>.dump
	open (OUT, ">$outfile") or die "Cannot create $outfile : $!";  
	my @ready_names= $db->fetch($term);                     
	foreach (@ready_names) { print OUT "$_\n"; }   
	close (OUT) or die "Cannot close $outfile : $!";
	print "done.\n\n";
    } 
}

sub printList {
# is passed a "@" value. pushes terms in the array into a hash of hashes where
# a number is associated to the term. then prints a list of the number and the term
# to STDOUT.
    @Input = (); %HoH3 = (); 



    @Input = @_;
    $i = 3;
    foreach $in (@Input){
	$HoH3{$i}{$in} = $in;
	$i++;
    }

    
    print "\n\n\tPress:\n";


    print "\t\t\tPRECOMPUTED GROUPS OF CLASSES:\n\n";
    print "\t\t\t[1]\tALL CLASSES\n";
    print "\t\t\t[2]\tCLASSES FOR CGC PAPERS\n";
    print "\t\t\tA SELECTION OF INDIVIDUAL CLASSES:\n\n";
    for my $number (sort {$a <=> $b} keys %HoH3 ){ 
	for my $data (keys %{ $HoH3{$number} }){
	    print "\t\t\t[$number]\t$data\n";
	}
    } 
    print "\nEnter choice here: ";
    return %HoH3;
    
}

