#!/usr/bin/perl -w

use strict;
use diagnostics;
use DBI;

my $validPaper_outfile = shift;
my $validPaperNotPassed_outfile = shift;
my $date_dir = shift;
my $dir_root = '/home/acedb/ruihua/data/datatype/';
$validPaper_outfile = $dir_root . $date_dir . '/' . $validPaper_outfile;
$validPaperNotPassed_outfile = $dir_root . $date_dir . '/' . $validPaperNotPassed_outfile;
my @outArr_validPaper;
my @outArr_validPaperNotPassed;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my %hash;
##my $result = $dbh->prepare( 'SELECT * FROM wpa_type ORDER BY wpa_timestamp' );
##$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
##while (my @row = $result->fetchrow) {
  ##if ($row[3] eq 'valid') { $hash{$row[0]}{$row[1]}++; }
    ##else { delete $hash{$row[0]}{$row[1]}; }
##} # while (@row = $result->fetchrow)

##foreach my $paper (sort keys %hash) {
  ##my (@types) = keys %{ $hash{$paper} };
##} # foreach my $paper (sort keys %hash)

# FROM HERE DOWN WILL GET ALL VALID PAPERS 

my $result = $dbh->prepare( 'SELECT * FROM wpa ORDER BY wpa_timestamp' );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[3] eq 'valid') { $hash{$row[0]}++; }
    else { delete $hash{$row[0]}; }
} # while (@row = $result->fetchrow)
##########################
foreach my $paper (sort keys %hash) {
    my $outline = "WBPaper$paper";
    push(@outArr_validPaper, $outline);
} # foreach my $paper (sort keys %hash)
##########################

# These 3 lines will delete from the results the ones that have been FP by a curator
$result = $dbh->prepare( 'SELECT * FROM cfp_curator' );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { if ($row[0]) { delete $hash{$row[0]}; } }

foreach my $paper (sort keys %hash) {
    my $outline = "WBPaper$paper";
    push(@outArr_validPaperNotPassed, $outline);
} # foreach my $paper (sort keys %hash)

##how to get paper not first passed yet.

open(OUT, ">$validPaper_outfile") || die "can't open file=$validPaper_outfile\n";
foreach(@outArr_validPaper){
    print OUT "$_\n";
}
close(OUT) || die "can't close file\n";

open(OUT, ">$validPaperNotPassed_outfile") || die "can't open file=$validPaperNotPassed_outfile\n";
foreach(@outArr_validPaperNotPassed){
    print OUT "$_\n";
}
close(OUT) || die "can't close file\n";
