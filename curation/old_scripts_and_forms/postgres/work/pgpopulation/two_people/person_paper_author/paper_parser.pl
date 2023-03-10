#!/usr/bin/perl

# parse paper dump from ws90 (without timestamps) and insert into postgresql tables

use strict;
use diagnostics;

my $infile = "paper_ws90b.ace";
my $outfile = "paper_ws90.out";

open (IN, "<$infile") or die "Cannot open $infile : $!";
open (OUT, ">$outfile") or die "Cannot create $outfile : $!";

print OUT "#!\/usr\/bin\/perl\n";
print OUT "\n";
print OUT "use Pg;\n";
print OUT "use diagnostics;\n";
print OUT "\n";
print OUT "\$conn = Pg::connectdb(\"dbname=testdb\");\n";
print OUT "die \$conn->errorMessage unless PGRES_CONNECTION_OK eq \$conn->status;\n\n";

my %hash;
my $key = '';

while (<IN>) {
  if ($_ =~ /^Paper/) { 
    if ($_ =~ /^Paper : \"\[(.*)\]\"$/) { $key = $1; }
    else { next; }
  }
  elsif ($_ =~ /^Title\t \"(.*)\"$/) { push @{$hash{$key}{title}}, $1; } 
  elsif ($_ =~ /^Journal\t \"(.*)\"$/) { push @{$hash{$key}{journal}}, $1; }
  elsif ($_ =~ /^Page\t \"(.*)\"$/) { push @{$hash{$key}{page}}, $1; }
  elsif ($_ =~ /^Volume\t \"(.*)\"$/) { push @{$hash{$key}{volume}}, $1; }
  elsif ($_ =~ /^Year\t \"(.*)\"$/) { push @{$hash{$key}{year}}, $1; }
  elsif ($_ =~ /^In_book\t \"(.*)\"$/) { push @{$hash{$key}{inbook}}, $1; }
  elsif ($_ =~ /^Contained_in\t \"(.*)\"$/) { push @{$hash{$key}{contained}}, $1; }
  elsif ($_ =~ /^PMID\t \"(.*)\"$/) { push @{$hash{$key}{pmid}}, $1; }
  elsif ($_ =~ /^Author\t \"(.*)\"$/) { push @{$hash{$key}{author}}, $1; }
  elsif ($_ =~ /^Affiliation\t \"(.*)\"$/) { push @{$hash{$key}{affiliation}}, $1; }
  elsif ($_ =~ /^Type\t \"(.*)\"$/) { push @{$hash{$key}{type}}, $1; }
  elsif ($_ =~ /^Contains\t \"(.*)\"$/) { push @{$hash{$key}{contains}}, $1; }

  elsif ($_ =~ /^Full_author_name\t \"(.*)\"$/) { print; }	# no data here
  else { 1; }
} # while (<IN>)

print "stuff\n";

foreach my $key (sort keys %hash) {
  print OUT "\$result = \$conn->exec( \"INSERT INTO pap_paper VALUES ('$key', '$key');\" );\n";
  foreach my $field ( keys %{ $hash{$key} }) {
    foreach my $value ( @{ $hash{$key}{$field} }) {
      if ($field eq 'page') { $value =~ s/\"//g; }	# delete " from pages
      $value =~ s/\\//g;
      $value =~ s/\[//g;
      $value =~ s/\]//g;
      $value =~ s/'/''/g;                    	# escape apostrophies
      $value =~ s/"/\\"/g;                    	# escape double quotes
      $value =~ s/@/\\@/g;                    	# escape @s
      print OUT "\$result = \$conn->exec( \"INSERT INTO pap_$field VALUES ('$key', '$value');\" );\n";
    }
  } # foreach my $field ( @{ $hash{$key} })
} # foreach my $key (%hash)

print "stuff\n";

close (IN) or die "Cannot close $infile : $!";
close (OUT) or die "Cannot close $outfile : $!";
