#!/usr/bin/perl

# Parse XML data for localizome for Wen.  2007 04 23

use strict;

my %hash;
my $png_file = 'png_list.txt';
open (IN, "<$png_file") or die "Cannot open $png_file : $!";
while (my $line = <IN>) {
  chomp $line;
  my ($num) = $line =~ m/^(\d+?)_/;
  $hash{$num} = $line;
} # while (my $line = <IN>)
close (IN) or die "Cannot close $png_file : $!";

my @files = <chronogram.*.xml>;
foreach my $chrono_file (@files) {
  $/ = '';
  open (IN, "<$chrono_file") or die "Cannot open $chrono_file : $!";
  my $chrono = <IN>;
  close (IN) or die "Cannot close $chrono_file : $!";
  my ($id) = $chrono =~ m/<chronogram_id>\s+(\d+)\s+<\/chronogram_id>/ms;
  my ($cds) = $chrono =~ m/<chronogram_name>\s+([\.\w]+)\s+<\/chronogram_name>/ms;
  my ($transgene) = $chrono =~ m/<strain_transgene>\s+(\w+)\s+<\/strain_transgene>/ms;
  my ($strain) = $chrono =~ m/<strain_name>\s+(\w+)\s+<\/strain_name>/ms;
  print "Expr_pattern : \"Chronogram$id\"\n";
  print "CDS\t\"$cds\"\n";
  print "Type\t\"Localizome\"\n";
  print "Picture\t\"$hash{$id}\"\n";
  print "Transgene\t\"$transgene\"\n";
  print "Strain\t\"$strain\"\n";
  print "Curated_by\t\"Caltech\"\n\n";
} # foreach my $file (@files)

__END__

        <chronogram_id>
                1
        </chronogram_id>
        <chronogram_name>
                C12D8.1a
        </chronogram_name>
        <strain>
                <strain_id>
                        3277
                </strain_id>
                <strain_name>
                        BC11926
                </strain_name>
                <strain_transgene>
                        sIs10429
                </strain_transgene>
                <strain_origin>
                        BC
                </strain_origin>

