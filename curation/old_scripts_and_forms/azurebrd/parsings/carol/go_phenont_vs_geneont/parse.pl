#!/usr/bin/perl

# Compare the phenotype.obo file with the go.obo file.  Whenever there 
# is a name or synonym that match (in a fuzzy way since GO terms will 
# never have a prefix, i.e., 'reduced' or a suffix, i.e., 'abnormal' 
# like the phenotype term names), could you print out the phenotype ID, 
# term name, and definition (where it exists) together with the GO ID, 
# term name, and def in a separate file?
# For Carol.  2007 01 30

use strict;

my %hash;
my %data;

my $gene_ont_file = 'gene_ontology_edit.obo';
$/ = "";
open (IN, "<$gene_ont_file") or die "cannot open $gene_ont_file : $!";
while (my $para = <IN>) {
  next unless ($para =~ m/namespace: biological_process/);
#   if ($para =~ m/subset: goslim_generic/) {
    my ($id) = $para =~ m/id: GO:(\d+)/;
    $data{$id} = $para;
    if ($para =~ m/name: (.*)\n/) { 
      my $name = $1; $name =~ s/ /_/g;
      next if ($name =~ m/\(/);
      if ($name =~ m/\-/) { $name =~ s/\-/\\\-/g; }
      push @{ $hash{$name} }, $id; }
    if ($para =~ m/synonym: \"(.*?)\"/) { 
      my $name = $1; $name =~ s/ /_/g;
      next if ($name =~ m/\(/);
      if ($name =~ m/\-/) { $name =~ s/\-/\\\-/g; }
      push @{ $hash{$name} }, $id; }
#   }
} # while (my $para = <IN>)
close (IN) or die "cannot close $gene_ont_file : $!";

# foreach my $name (sort keys %hash) {
# #   if (scalar( @{ $hash{$name} } ) > 1) {  my $count = scalar( @{ $hash{$name} } ); print "LOTS $count $name\n"; }
#   my $names = join", ", @{ $hash{$name} };
#   print "$name -- $names\n";
# } # foreach my $name (sort keys %hash)

my $phenont_file = 'PhenOnt.obo';
open (IN, "<$phenont_file") or die "cannot open : $phenont_file";
while (my $para = <IN>) {
  my ($phen_name) = $para =~ m/name: (.*)\n/;
  foreach my $gene_name (sort keys %hash) {
    if ($phen_name =~ m/$gene_name/) {
      print "MATCH $phen_name -- $gene_name\n";
      if ($para =~ m/id: (WBPhenotype\d+)\n/) { print "$1 $phen_name\n"; }
      if ($para =~ m/def: \"(.*?)\"/) { print "PhenOnt Definition\t\"$1\"\n"; }
      foreach my $gene_id (@{ $hash{$gene_name} }) {
        my $data = $data{$gene_id};
        my ($gene_name) = $data =~ m/name: (.*)\n/;
        my ($gene_def) = $data =~ m/def: \"(.*)\"/;
        print "GO:$gene_id $gene_name\n";
        print "GeneOnt Definition\t\"$gene_def\"\n";
      } # foreach my $gene_id (@{ $hash{$name} })
      print "\n";
    }
  } # foreach my $gene_name (sort keys %hash)
#   if ($hash{$name}) { 
#     my $names = join", ", @{ $hash{$name} };
#     print "$name -- $names\n";
#   }
} # while (my $para = <IN>)
close (IN) or die "cannot close : $phenont_file";

