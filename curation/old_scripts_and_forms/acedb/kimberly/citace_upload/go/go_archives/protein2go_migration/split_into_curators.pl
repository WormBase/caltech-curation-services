#!/usr/bin/perl

# split phenote_go_withcurator.go.<date> file into separate files for each curator.
# one-time-only script to populate protein2go.  2013 01 25
#
# remembered to strip out lines with IEP now.
# switched to use new file that has both curator and pgid as extra columns.  2013 02 07

use strict;

# my $infile = '/home/acedb/ranjana/citace_upload/go_curation/go_dumper_files/phenote_go_withcurator.go.20121217';
my $infile = 'phenote_go_withcurator.go.latest';

my %map;
$map{"WBPerson324"}  = 'gene_association.wb.RanjanaKishore';
$map{"WBPerson1843"} = 'gene_association.wb.KimberlyVanAuken';
$map{"WBPerson5196"} = 'gene_association.wb.JoshJaffery';
$map{"WBPerson48"}   = 'gene_association.wb.CarolBastiani';

my %hash;
open (IN, "<$infile") or die "Cannot open $infile : $!";
my $header = '';
my $blah = <IN>; $header .= $blah;
$blah = <IN>; $header .= $blah;
$blah = <IN>; $header .= $blah;
$blah = <IN>; $header .= $blah;
while (my $line = <IN>) {
  chomp $line;
  my (@array) = split/\t/, $line;
  my $pgid = pop @array;
  my $curator = pop @array;
  my $iep_field = $array[6];
  next if ($iep_field eq 'IEP');
  $line = join("\t", @array);
  $hash{$curator}{$line}++;
} # while (my $line = <IN>)
close (IN) or die "Cannot close $infile : $!";

foreach my $curator (sort keys %hash) {  
  my $filename = $map{$curator};
#   print "-=${curator}=-\t$filename\n";
  open (OUT, ">$filename") or die "Cannot create $filename : $!";
  print OUT "$header";
  foreach my $line (sort keys %{ $hash{$curator} }) {
    print OUT "$line\n";
  }
  close (OUT) or die "Cannot close $filename : $!";
} # foreach my $curator (sort keys %hash)


__END__

Take most recent file :
/home/acedb/ranjana/citace_upload/go_curation/go_dumper_files/phenote_go_withcurator.go.20121217 

Remove curator column
Remove column 18 which has the curator
Remove all entries where column 7 is 'IEP'
Map all entries to separate output files by curator.
  WBPerson324	gene_association.wb.RanjanaKishore
  WBPerson1843	gene_association.wb.KimberlyVanAuken
  WBPerson5196	gene_association.wb.JoshJaffery	
  WBPerson48	gene_association.wb.CarolBastiani

