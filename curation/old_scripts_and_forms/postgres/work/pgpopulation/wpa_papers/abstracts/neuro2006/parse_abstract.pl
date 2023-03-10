#!/usr/bin/perl

use strict;
use diagnostics;

# unless ($ARGV[0]) { die "Need an inputfile ./parse_abstract.pl inputfile\n"; }

# my $infile = 'access_abstract.xml';
my $infile = 'Neuro_Meeting_Abstracts_2006.xml';
my $outfile = $infile . '.out';

$/ = undef;
open (IN, "<$infile") or die "Cannot open $infile : $!";
my $all_abstracts = <IN>;
close (IN) or die "Cannot close $infile : $!";

open (OUT, ">$outfile") or die "Cannot create $outfile : $!";

my (@abstracts) = split/<\/AbStract>\n<AbStract>/, $all_abstracts;
my %ids;
foreach my $atext (@abstracts) {
#   print OUT "AT $atext\n\n";
  my ($title, $authors, $body, $id);
  if ($atext =~ m/<Title>(.*?)<\/Title>/s) { $title = $1; }
  if ($atext =~ m/<Authorname>(.*?)<\/Authorname>/s) { $authors = $1; }
  if ($atext =~ m/<Body>(.*?)<\/Body>/s) { $body = $1; }
  if ($atext =~ m/<Id>(.*?)<\/Id>/s) { $id = $1; }
  unless ($title) { print "ERR No Title $atext\n"; }
  unless ($authors) { print "ERR No Authors $atext\n"; }
  unless ($body) { print "ERR No Body $atext\n"; }
  unless ($id) { print "ERR No Id $atext\n"; }
  push @{ $ids{$id} }, $atext;
# print OUT "A $authors\n";
  if ($authors =~ m/&lt;.*?&gt;/) { $authors =~ s/&lt;.*?&gt;//g; }
  if ($authors =~ m/&apos;/) { $authors =~ s/&apos;/'/g; }
  if ($authors =~ m/&ndash;/) { $authors =~ s/&ndash;/\-/g; }
  if ($authors =~ m/&lsquo;/) { $authors =~ s/&lsquo;/\"/g; }
  if ($authors =~ m/&rsquo;/) { $authors =~ s/&rsquo;/\"/g; }
  if ($authors =~ m/\s+/) { $authors =~ s/\s+/ /g; }
  if ($authors =~ m/\d+/) { $authors =~ s/\d+//g; }
  if ($authors =~ m/\*/) { $authors =~ s/\*//g; }
  if ($authors =~ m/, ,/) { $authors =~ s/, ,/,/g; }
  if ($authors =~ m/ , /) { $authors =~ s/ , /, /g; }
  if ($authors =~ m/ and /) { $authors =~ s/ and /, /g; }
  if ($authors =~ m/, $/) { $authors =~ s/, $//g; }
  if ($authors =~ m/, II/) { $authors =~ s/, II/ II/g; }
#   unless ($authors) { print "ERR No authors $atext\n"; }
# print OUT "B $authors\n";
# print "ID $id A $body\n";
  if ($title =~ m/&lt;.*?&gt;/) { $title =~ s/&lt;.*?&gt;//g; }
  if ($title =~ m/&nbsp;/) { $title =~ s/&nbsp;/ /g; }
  if ($title =~ m/&amp;nbsp;/) { $title =~ s/&amp;nbsp;/ /g; }
  if ($title =~ m/&apos;/) { $title =~ s/&apos;/'/g; }
  if ($title =~ m/&amp;/) { $title =~ s/&amp;/\&/g; }
  if ($title =~ m/&ndash;/) { $title =~ s/&ndash;/\-/g; }
  if ($title =~ m/&lsquo;/) { $title =~ s/&lsquo;/\"/g; }
  if ($title =~ m/&rsquo;/) { $title =~ s/&rsquo;/\"/g; }
  if ($body =~ m/&lt;.*?&gt;/) { $body =~ s/&lt;.*?&gt;//g; }
  if ($body =~ m/&nbsp;/) { $body =~ s/&nbsp;/ /g; }
  if ($body =~ m/&amp;nbsp;/) { $body =~ s/&amp;nbsp;/ /g; }
  if ($body =~ m/&apos;/) { $body =~ s/&apos;/'/g; }
  if ($body =~ m/&amp;/) { $body =~ s/&amp;/\&/g; }
  if ($body =~ m/&ndash;/) { $body =~ s/&ndash;/\-/g; }
  if ($body =~ m/&lsquo;/) { $body =~ s/&lsquo;/\"/g; }
  if ($body =~ m/&rsquo;/) { $body =~ s/&rsquo;/\"/g; }
# print "ID $id B $body\n";
  my (@authors) = split/, /, $authors;
  print OUT "Paper : \"WBPaper000#####\"\n";
  print OUT "Meeting_abstract\t\"neubehwm06abs$id\"\n";
  print OUT "Type\t\"Meeting_abstract\"\n";	# type 3
  print OUT "Year\t2006\n";
#   print OUT "Journal\t\"Development & Evolution Meeting\"\n";
  print OUT "Journal\t\"Neuronal Development, Synaptic Function, and Behavior Meeting\"\n";
  print OUT "Title\t\"$title\"\n";
  foreach my $author (@authors) { print OUT "Author\t\"$author\"\n"; }
  print OUT "Abstract\t\"$body\"\n";
  print OUT "\n";
} # foreach my $atext (@abstracts)

foreach my $id (sort keys %ids) {
  if (scalar (@{ $ids{$id} }) > 1) { print "ERR ID $id has " . scalar (@{ $ids{$id} }) . " entries\n"; }
}



close (OUT) or die "Cannot close $outfile : $!";

__END__

<Title>&lt;i&gt;ego-2&lt;/i&gt; encodes a BRO1 domain protein that promotes
&lt;/span&gt;&lt;i&gt;glp-1&lt;/i&gt; function</Title>
<Authorname>&lt;u&gt;Ying Liu&lt;/u&gt;, Eleanor Maine</Authorname>
<Institution>Syracuse University</Institution>
<Body>
