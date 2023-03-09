#!/usr/bin/perl

my $pyfile = 'alliance_molecular_interactions.txt';
my $plfile = 'biogrid_psimitab27.tab';

my %perl;
my %python;

open (IN, "<$pyfile");
while (my $line = <IN>) {
  chomp $line;
  $line =~ s///g;
  $python{$line}++;
}
close (IN);

open (IN, "<$plfile");
while (my $line = <IN>) {
  chomp $line;
  $line =~ s///g;
  $perl{$line}++;
}
close (IN);

foreach my $line (sort keys %perl) {
  next if ($python{$line});
  print qq(IN PERL $line\n);
} # foreach my $line (sort keys %perl)

foreach my $line (sort keys %python) {
  next if ($perl{$line});
  print qq(IN PYTHON $line\n);
} # foreach my $line (sort keys %python)
