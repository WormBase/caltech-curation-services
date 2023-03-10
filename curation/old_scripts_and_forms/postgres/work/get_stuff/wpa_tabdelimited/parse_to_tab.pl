#!/usr/bin/perl

# take the papers.ace and abstracts.ace and create a tab-delimited file for
# Rachel Ankeny (wormbase-help email)  2008 08 027

use strict;

$/ = undef;
my %abs;
my $infile = 'abstracts.ace';
open (IN, "<$infile") or die "Cannot open $infile : $!";
my $all_file = <IN>;
close (IN) or die "Cannot close $infile : $!";
my @entries = split/\*\*\*LongTextEnd\*\*\*/, $all_file;
foreach my $entry (@entries) {
  my ($header, $text) = $entry =~ m/LongText : \"(WBPaper\d+)\"\n\n(.*?)\n\n/;
  $abs{$header} = $text; 
} # foreach my $entry (@entries)

my $count = 0;
my %paper; my %headers;
$/ = "";
my $infile = 'papers.ace';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $entry = <IN>) {
  $count++; # last if ($count > 3);
  my ($paper) = $entry =~ m/Paper : \"(WBPaper\d+)\"/;
  my @lines = split/\n/, $entry;
  foreach my $line (@lines) {
    my ($header, $data) = $line =~ m/^(.*?)\t(.*)/;
    $data =~ s/\t/ /;
    if ($data =~ m/^\s+/) { $data =~ s/^\s+//; }
    if ($data =~ m/^\"/) { $data =~ s/^\"//; } if ($data =~ m/\"$/) { $data =~ s/\"$//; }
    $headers{$header}++;
    push @{ $paper{$paper}{$header} }, $data;
  } # foreach my $line (@lines)
} # while (my $entry = <IN>)
close (IN) or die "Cannot close $infile : $!";

delete $headers{''};
my (@headers) = sort keys %headers;
my $header = join"\t", @headers;
print "PaperID\t$header\n";
foreach my $paper (sort keys %paper) {
  my @line;
#   print "TYPE $paper{$paper}{'Type'}[0] PAPER $paper\n";
#   if ($paper{$paper}{'Type'}[0] =~ m/ABSTRACT/) { print "SKIP\n"; }
  next if ($paper{$paper}{'Type'}[0] =~ m/ABSTRACT/);
  next if ($paper{$paper}{'Status'}[0] =~ m/Invalid/);
  next if ($paper{$paper}{'Meeting_abstract'}[0]);
  next if ($paper{$paper}{'WBG_abstract'}[0]);
  foreach my $header (sort keys %headers) {
    my $data = '';
    if ($paper{$paper}{$header}[0]) { 
      if ($header eq 'Abstract') { $data = $paper{$paper}{$header}[0]; $data = "\"$abs{$data}\""; }
      elsif ($header eq 'Page') { $data = $paper{$paper}{$header}[0]; $data =~ s/\"//g; $data = "\"$data\""; }
      else { $data = join"\",\"", @{ $paper{$paper}{$header} }; $data = "\"$data\""; } }
    push @line, $data;
  }
  my $line = join"\t", @line;
  print "\"$paper\"\t$line\n";
}

  



__END__


LongText : "WBPaper00000003"

Applying a series of techniques intended to induce, detect and isolate lethal
and/or sterile temperature-sensitive mutants, specific to the self-fertilizing
hermaphrodite nematode Caenorhabditis elegans, Bergerac strain, 25 such mutants
have been found. Optimal conditions for the application of mutagenic treatment
and the detection of such mutations are discussed.

***LongTextEnd***
