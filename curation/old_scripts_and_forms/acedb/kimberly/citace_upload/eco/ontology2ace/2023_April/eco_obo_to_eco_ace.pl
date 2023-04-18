#!/usr/bin/perl

# generate .ace for Kimberly according to
# https://wiki.wormbase.org/index.php/Evidence_Code_Ontology
# 2020 06 01
# 2021-12-08 updated version text from Relations Ontology to Evidence and Conclusion Ontology


use strict;
use LWP::Simple;

my $url = 'https://raw.githubusercontent.com/evidenceontology/evidenceontology/master/eco.obo';
my $data = get $url;

my $data_version = '';
if ($data =~ m/data-version: (.*?)\n/m) { $data_version = $1; }

my $outfile = 'eco_terms.ace';
open (OUT, ">$outfile") or die "Cannot create $outfile : $!";

my (@entries) = split/\n\n/, $data;
my $output = '';
foreach my $entry (@entries) {
  next unless ($entry =~ m/\[Term\]/);
  $entry =~ s|\\\"|'|g;
  my (@lines) = split/\n/, $entry;
  my $status = 'Valid';
  foreach my $line (@lines) {
    if ($line =~ m/^id: (.*?)$/) { $output .= qq(ECO_term : "$1"\n); }
      elsif ($line =~ m/^name: (.*?)$/) { $output .= qq(Name\t"$1"\n); }
      elsif ($line =~ m/^is_obsolete: true/) { $status = 'Obsolete'; }
      elsif ($line =~ m/^alt_id: (.*?)$/) { $output .= qq(Alt_id\t"$1"\n); }
      elsif ($line =~ m/^def: "(.*?)"/) { $output .= qq(Definition\t"$1"\n); }
      elsif ($line =~ m/^synonym: "(.*?)" ([A-Z]+)/) { 
        my ($type, $syn) = ($2, $1);
        $type = ucfirst(lc($type));
        $output .= qq(Synonym\t$type\t"$syn"\n); }
      elsif ($line =~ m/^is_a: (.*?) /) { $output .= qq(Parent\t"$1"\n); }
  } # foreach my $line (@lines)
  $output .= qq(Status\t"$status"\n);
  $output .= qq(Version\t"Evidence and Conclusion Ontology $data_version"\n);
  $output .= "\n";
} # foreach my $entry (@entries)

binmode(OUT, "encoding(UTF-8)");
print OUT $output;

close (OUT) or die "Cannot close $outfile : $!";

__END__

[Term]
id: ECO:0000000
name: evidence
def: "A type of information that is used to support an assertion." [ECO:MCC]
synonym: "evidence code" RELATED []
synonym: "evidence_code" RELATED []
disjoint_from: ECO:0000217 ! assertion method

