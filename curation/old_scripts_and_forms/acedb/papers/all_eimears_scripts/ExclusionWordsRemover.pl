#!/usr/bin/perl -w


################
# BEGIN PROGRAM
################

#use strict;

my %Hash;
my $list = "/home2/eimear/abstracts/ACEDUMPS/Exclusion";
my @dumps = </home2/eimear/abstracts/ACEDUMPS/*.dump>;

&ExclusionList;

foreach my $file (@dumps){
    %TermHash = ();
    open (FILE, "<$file") or die "Cannot open $file: $!";
    open (FILEOUT, ">$file.out") or die "Cannot open $file.out : $!";
    open (REMOVED, ">$file.removed") or die "Cannot open $file.removed : $!";
    while (<FILE>) {
	chomp;
	$TermHash{$_} = $_;
    }
    foreach my $term (sort keys %TermHash){
	if ($Hash{$term}){print REMOVED "$Hash{$term}\n";
	}else {print FILEOUT "$term\n"}
    } 
    close (FILE) or die "Cannot close $file : $!";
    close (FILEOUT) or die "Cannot close $file.out : $!";
    close (REMOVED) or die "Cannot close $file.removed : $!";
} 


sub ExclusionList{
%Hash = ();
  open (LIST, $list) or die "Cannot open $list : $!";
  while (<LIST>){
    chomp;
    $Hash{$_}=$_;
  }
  close(LIST);
}









