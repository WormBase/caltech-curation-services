#!/usr/bin/perl

# find proofs and analyze which don't have a final/temp, and make a shell script to move them

use strict;

my %hash;
my %proofs;

my $md5_all_file = 'md5_all';
open (IN, "<$md5_all_file") or die "Cannot open $md5_all_file : $!";
while (my $line = <IN>) {
  chomp $line;
  my ($md5, $file) = split/\t/, $line;
  if ($file !~ m/supplement/) {
#     print qq($file\n);
    my $papid = 0;
    my $type = 'no_type';
    my ($path, $file_name) = $file =~ m/^(.*\/)(.*?)$/;
    if ($file =~ m/^wb\/[a-z]+\/(\d{8})[^\d]/) { 
      $papid = $1; }
    if ($file_name =~ m/[a-z][0-9][0-9]_(.*?)\.pdf/) { 
      $type = $1;
    }
    $hash{$papid}{$type}{$file}++;
    if ($type eq 'proof') { $proofs{$file}++; }
  }
}
close (IN) or die "Cannot close $md5_all_file : $!";

foreach my $file (sort keys %proofs) {
  print qq(mv $file /home2/acedb/daniel/ArchiveReference/Proofs/wb/pdf/\n);
}

# find proofs that don't have a final or temp
# foreach my $pap (sort keys %hash) {
#   foreach my $file (sort keys %{ $hash{$pap}{'proof'} }) {
#     unless (($hash{$pap}{'no_type'}) || ($hash{$pap}{'temp'})) {
#       foreach my $type (sort keys %{ $hash{$pap} }) {
#         foreach my $file2 (sort keys %{ $hash{$pap}{$type} }) {
#           print qq($pap\t$type\t$file2\n);
#     } } }
# #     print qq($file\t);
# #     print qq(\n);
#   }
# }
