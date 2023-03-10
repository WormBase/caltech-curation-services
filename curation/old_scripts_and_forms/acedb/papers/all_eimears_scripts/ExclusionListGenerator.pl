#!/usr/bin/perl -w

# Flat File Crossreferencer

# Written by Eimear Kenny, 2002-02-04, @ wormbase

# this is a script that takes in any files entered at the command line
# and checks every line of a given file against every line  of all the 
# other files to check whether lines are duplicated.

###### USAGE:

# ./CrossReferencer.pl <file 1> <file 2> <file 3> ...... <file n>

################
# BEGIN PROGRAM
################

#use strict;
use IO::Handle;
STDOUT->autoflush(1);

my %HoA;
my %WordHash;
my $j;
my $path = "/home2/eimear/abstracts/ACEDUMPS";
my @dumps = </home2/eimear/abstracts/ACEDUMPS/*.dump>;

foreach my $file (@dumps){    
    my $i = 0;
    open (FILE, "<$file") || die "Cannot open $file : $!";
    print "opened $file ..... \n";
    while (<FILE>) {
	$i++;
        chomp;
  	my $value = "\tOccurs in " . $file . ", at line " . $i;

        push @{ $HoA{$_} }, $value;
    }
    close (FILE) || die "Cannot close $file : $!";
} 

open (LONGOUT, ">$path/Exclusion.long") or die "Cannot open $path/Exculsion.long : $!";
open (SHORTOUT, ">$path/Exclusion") or die "Cannot open $path/Exculsion : $!";
# adds entries that appear more than once in the lists to the Exclusion lists

foreach my $line (sort keys %HoA) {
    if (scalar( @{ $HoA{$line} } ) > 1) {
    	for my $j ( 0 .. $#{ $HoA{$line} } ) {
	    print LONGOUT "$line : $HoA{$line}[$j]\n";
	    $WordHash{$line} = $line;
	}
    } 
} 

foreach (sort keys %WordHash){
  print SHORTOUT "$_\n";
}

close (SHORTOUT) or die "Cannot close Exclusion : $!";
close (LONGOUT) or die "Cannot close Exclusion.long : $!";

open (LONGOUT, ">>$path/Exclusion.long") or die "Cannot open Exculsion.long : $!";
open (SHORTOUT, ">>$path/Exclusion") or die "Cannot open Exculsion : $!"; 

# adds entries that have two or less characters to Exculsion lists

foreach my $line (sort keys %HoA) {
    my @chars = split //, $line;
    for my $j ( 0 .. $#{ $HoA{$line} } ) {
	if ( scalar(@chars) < 3 ) {            # if the amount of characters is two or less
	    print LONGOUT "$line : $HoA{$line}[$j]\n"; # add to Exclusion list
#	    print "$line : $HoA{$line}[$j]\n"; # add to Exclusion list
	    $WordHash2{$line} = $line;
	}
    }
} 

foreach (sort keys %WordHash2){
  print SHORTOUT "$_\n";
}

close (SHORTOUT) or die "Cannot close Exclusion : $!";
close (LONGOUT) or die "Cannot close Exclusion.long : $!";

open (SHORTOUT, ">>$path/Exclusion") or die "Cannot open Exculsion : $!";
print SHORTOUT "embryos\n";
print SHORTOUT "M3'\n";
print SHORTOUT "neuronal\n";
print SHORTOUT "neural\n";
print SHORTOUT "neurons\n";
print SHORTOUT "seam\n";
print SHORTOUT "set\n";
print SHORTOUT "intestinal\n";
print SHORTOUT "hypodermal\n";
close (SHORTOUT) or die "Cannot close Exclusion : $!";
