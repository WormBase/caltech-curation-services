#!/usr/bin/perl

# get history file from sanger to find which CEthings are outdated, and which
# CEthings should replace them.  then go through geneassociation file looking
# for old CEthigns and replace them with new ones.  2003 12 09

# ignore IEAs since not curated by caltech.
# make badlist not be the whole bad list, but only the bad list that has a 
# corresponding CEthing in the geneassociations file.
# output to 3 files instead of 2 files.  2003 12 16


use strict;
use LWP::Simple;

my $history = get "ftp://ftp.sanger.ac.uk/pub/databases/wormpep/wormpep.history";
my $gene_file = get "http://www.geneontology.org/gene-associations/gene_association.wb";

my %history;
my %bestCEthing;
my %cething;
my %cosmid;
my %badlist;
my %filteredBad;

my @history = split/\n/, $history;
foreach my $line (@history) {
  my ($a, $stuff) = $line =~ m/^(.*?)\t(.*)$/;
  if ($a =~ m/\.\d+[a-z]+/) { $a =~ s/[a-z]+$//g; }
  push @{ $history{$a} }, $line;
} # foreach my $line (@history)

foreach my $key (sort keys %history) {
	# $key is cosmid.number thing without letters
  my $bestCEthing = 0;		# has final version value (default no)
  my $highest = 0;	# highest version number (default 0)
  foreach my $line (@{ $history{$key} }) {
#     my ($a, $b, $c) = split/\t/, $line;	# old way ignoring letters
    my ($cosmidWithLetter, $cething, $b, $c) = split/\t/, $line;
    $cosmid{$cething} = $cosmidWithLetter;
# this doesn't deal with multiple letters (isoforms ?)
#     if ($c) { 
#       if ($c > $highest) { $highest = $c; $bestCEthing{$key} = $cething; } }
#     else {
#       if ($b >= $highest) { $highest = $b; $bestCEthing{$key} = $cething; } }
#     unless ($c) { $bestCEthing = 1; }		# has final version value 
    my $finalFlag = 'NF';		# default not final
    unless ($c) { $finalFlag = 'F'; }	# set final
    push @{ $bestCEthing{$key}{$finalFlag}{$b} }, $cething;
  } # foreach my $line (@{ $history{$key} })

  foreach my $line (@{ $history{$key} }) {
#     my ($cething, $b, $c) = split/\t/, $line;	# old way ignoring letters
    my ($cosmidWithLetter, $cething, $b, $c) = split/\t/, $line;
    if ($cething{$cething}) { next; }	# don't repeat cethings which already have found values since 
					# geneassociations file could have a cething in multiple lines
# need to replace this with Loop because values pushed into Array now with F and NF keys
#     $cething{$cething} = $bestCEthing{$key};
#     $cosmid{$bestCEthing{$key}} = $cosmidWithLetter;
    if ($bestCEthing{$key}{F}) {	# good, F
# if ($cething eq 'CE25737') { print "FOUND CE25737 F : $line\n"; }
      # find highest value in hash, pass all values from that array to %cething
      my ($highest, @pie) = reverse sort keys %{ $bestCEthing{$key}{F} };
      foreach my $version (sort keys %{ $bestCEthing{$key}{F} }) {
        foreach my $value (@{ $bestCEthing{$key}{F}{$highest} }) {
# if ($cething eq 'CE25737') { print "FOUND CE25737 PUSH VALUE $value\n"; }
          push @{ $cething{$cething}}, $value;
        } # foreach my $value (@{ $bestCEthing{$key}{F}{$highest} })
      } # foreach my $version (sort keys %{ $bestCEthing{$key}{F} })
    } else {				# bad, NF
# if ($cething eq 'CE25737') { print "FOUND CE25737 NF : $line\n"; }
      $badlist{$cething} = $key;
      # find highest value in hash, pass all values from that array to %cething
      my ($highest, @pie) = reverse sort keys %{ $bestCEthing{$key}{NF} };
      foreach my $version (sort keys %{ $bestCEthing{$key}{NF} }) {
        foreach my $value (@{ $bestCEthing{$key}{NF}{$highest} }) {
          push @{ $cething{$cething}}, $value;
        } # foreach my $value (@{ $bestCEthing{$key}{NF}{$highest} })
      } # foreach my $version (sort keys %{ $bestCEthing{$key}{NF} })
    }
  } # foreach my $line (@{ $history{$key} })

# don't need this because using F and NF flag
#   unless ($bestCEthing) {
#     foreach my $line (@{ $history{$key} }) {
# #       my ($cething, $b, $c) = split/\t/, $line;	# old way ignoring letters
#       my ($cosmidWithLetter, $cething, $b, $c) = split/\t/, $line;
#       $badlist{$cething} = $key; 	# add to hash of bad stuff
#     } 					# key CEthings value BAD sequence
#   }
} # foreach my $key (sort keys %history)

my $outfile = 'outfile';
my $changelist = 'changelist';
my %changeFilter;
open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
open (CHA, ">$changelist") or die "Cannot create $changelist : $!";

my @gene_file = split/\n/, $gene_file;
foreach my $line (@gene_file) {
  if ($line =~ m/\tIEA\t/) { print OUT "$line\n"; next; }	# skip IEA lines
  $line .= "\n";
  if ($line =~ m/^WB\t(CE\d+)\t/) {
    my $pie = $1; 
# if ($pie eq 'CE25737') { print "FOUND CE25737 : $line\n"; }
    unless ($cething{$pie}) { print "BAD PIE $pie\n"; }
    if (scalar(@{ $cething{$pie}}) > 1) {		# if split into many values
      my $line_copy = $line;
      $line = '';					# have to change line, so reset it
      foreach my $each_cething (@{ $cething{$pie} }) {
        my $temp_line = $line_copy;
        $temp_line =~ s/$pie/$each_cething/; 
        $line .= "$temp_line";
        if ($pie ne $each_cething) {
# if ($pie eq 'CE25737') { print "FOUND CE25737 : $each_cething\n"; }
          my $bob = "CHANGED $pie TO $each_cething IS $cosmid{$each_cething}\n"; 
          $changeFilter{$bob}++; }
        if ($badlist{$pie}) { $filteredBad{$badlist{$pie}}++; }	# filter bads through hash
      } # foreach my $each_cething (@{ $cething{$pie} })
    } else {
    # print "BLAH -=${1}=- $cething{$1}\n"; 
      $line =~ s/$pie/$cething{$pie}[0]/; 
#     if ($pie ne $cething{$pie}) { print CHA "CHANGED $pie TO $cething{$pie}\n"; }	# not filtered
      if ($pie ne $cething{$pie}[0]) {
        my $bob = "CHANGED $pie TO $cething{$pie}[0] IS $cosmid{$cething{$pie}[0]}\n"; 
        $changeFilter{$bob}++; }
      if ($badlist{$pie}) { $filteredBad{$badlist{$pie}}++; }	# filter bads through hash
    }
  }
  print OUT "$line";
} # foreach my $line (@gene_file)
close (OUT) or die "Cannot close $outfile : $!";
foreach my $bob (sort keys %changeFilter) { print CHA $bob; }
close (CHA) or die "Cannot close $changelist : $!";

my $badlist = 'badlist';
open (BAD, ">$badlist") or die "Cannot create $badlist : $!";
my $badcosmid = 'badcosmid';
open (COS, ">$badcosmid") or die "Cannot create $badcosmid : $!";
foreach my $bad (sort keys %filteredBad) {
  if ($bad =~ m/\.\d+/) { print BAD "BAD $bad\n"; }
    else { print COS "BAD $bad\n"; }
} # foreach my $bad (sort keys %filteredBad)
close (BAD) or die "Cannot close $badlist : $!";
close (COS) or die "Cannot close $badcosmid : $!";

# foreach my $key (sort keys %history) {
#   my $line = $history{$key};
#   my ($a, $b, $c) = split/\t/, $line;
#   $cething{$a} = $bestCEthing{$key};
#   print "$a : $cething{$a}\n";
# } # foreach my $key (sort keys %history)
