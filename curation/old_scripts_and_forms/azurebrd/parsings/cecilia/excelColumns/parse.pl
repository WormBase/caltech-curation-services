#!/usr/bin/perl

# mv columns to horizontal entries for cecilia   2005 03 24

my $infile = 'infile';
open (IN, "<$infile") or die "Cannot open $infile : $!";
my $file = <IN>;
close (IN) or die "Cannot close $infile : $!";

# print "FILE $file FILE\n";
$file =~ s//\n/g;
$file =~ s/Ê//g;
# @lines = $file = split//, $file;
# print "FILE $file FILE\n";
@lines = split/\n/, $file;

  
foreach my $line (@lines) {
  
  chomp ($line);
  my @stuff = split/\t/, $line;
  foreach my $stuff (@stuff) {
    print "$stuff\n";
  } # foreach my $stuff (@stuff)
  print "\n";
} # foreach my $line (@lines)
