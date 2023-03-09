#!/usr/bin/perl

my %g2m;
my $namefile = 'genes2molecularnamestest.txt';
open (NAM, "<$namefile") or die "Cannot open $namefile : $!";
while (<NAM>) {
  chomp;
  my ($wbg, $loc, $stuff) = split/\t/, $_;
  ($wbg) = $wbg =~ m/(\d+)/;
  if ($loc =~ m/\-/) { $g2m{$wbg} = $loc; }
} # while (<NAM>)

my $acefile = 'wbgenes_to_words.txt';
open (ACE, "<$acefile") or die "Cannot open $acefile : $!";
my $gene_count = 1;
my $match = 0;
while (<ACE>) {
  chomp;
  my ($wbg, $other) = split/\t/, $_;
  ($wbg) = $wbg =~ m/(\d+)/;
  $ace{$wbg}{$other}++;
}

foreach my $wbg (sort keys %g2m) {
  my $loc = $g2m{$wbg};
  unless ($ace{$wbg}{$loc}) { print "No match for $wbg to $loc\n"; }
} # foreach my $wbg (sort keys %g2m)


__END__

No match for 00004147 to larp-2
No match for 00006443 to pak-2
No match for 00006475 to tyra-3
No match for 00007554 to pptr-2
No match for 00007932 to zip-5
No match for 00008805 to git-1
No match for 00009743 to sptf-1
No match for 00010198 to spat-1
No match for 00010609 to dut-1
No match for 00010776 to pix-1
No match for 00010923 to rle-1
No match for 00010982 to flp-32
No match for 00011279 to asd-1
No match for 00011505 to pzf-1
No match for 00011747 to sna-2
No match for 00011926 to sptf-2
No match for 00012348 to pptr-1
No match for 00012696 to reps-1
No match for 00012735 to sptf-3
No match for 00012973 to spat-2
No match for 00016602 to mus-81
No match for 00016935 to ifta-1
No match for 00017641 to csr-1
No match for 00018037 to chtl-1
No match for 00018304 to agr-1
No match for 00018698 to vha-18
No match for 00018703 to sec-3
No match for 00018827 to pst-2
No match for 00018921 to sago-2
No match for 00019666 to sago-1
No match for 00019760 to calu-1
No match for 00019971 to ergo-1
No match for 00020496 to spat-3
No match for 00020951 to sna-1
No match for 00021152 to mgl-3
No match for 00021952 to vha-19
No match for 00043050 to oig-4
No match for 00044965 to smy-6
No match for 00044966 to smy-12
No match for 00044967 to smy-9
No match for 00045095 to rmrp-1
No match for 00045109 to smy-2
No match for 00045159 to smy-3
No match for 00045191 to aho-1
No match for 00045192 to aho-3
No match for 00045194 to smy-1
No match for 00045199 to smy-5
No match for 00045200 to smy-4
No match for 00045201 to smy-10
No match for 00045203 to smy-8
No match for 00045204 to smy-11
No match for 00045205 to smy-7

