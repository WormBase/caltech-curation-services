#!/usr/bin/perl

# Look at all abstracts and check for words that correspond to wbgenes based off
# of wbgenes_to_words.txt (which is based on Igor's script that fetches those
# words).  Then connect those genes to papers.  For Andrei.  Also updated
# wpa_match.pm to look at that set of words when running processPubmed to make
# matches from the abstracts.  2006 06 08
#
# Got list of exclusion words from Andrei and ran this to put data in postgres.
# 2006 06 15

use strict;
use LWP::Simple;
use Jex;
use diagnostics;
use LWP::UserAgent;					# not in use
use Ace;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;


my %gene_words;		# words and their corresponding genes

my $date = &getSimpleSecDate();

my $directory = '/home/azurebrd/public_html/sanger/genes_cds';

chdir($directory) or die "Cannot go to $directory ($!)";


$|=9;   #turn off output caching

if ($#ARGV != 0) {
    print "usage: $0 out\n";
    exit;
}


open OUT, ">$ARGV[0]" || die "cannot open $ARGV[1] :$!\n";


# &updateListFromAce();
&getListFromFlatFile();
&removeAndreiExclusions();

my %abstracts;
my $result = $conn->exec( "SELECT * FROM wpa_abstract ORDER BY wpa_timestamp" );
while (my @row = $result->fetchrow) {
  if ($row[3] eq 'valid') { $abstracts{$row[0]} = $row[1]; }
    else { delete $abstracts{$row[0]}; }
} # while (my @row = $result->fetchrow)

my %frequency;		# frequency of gene_words found in abstracts (counted only once per abstract)
my $count = 0;
foreach my $abs_join (sort keys %abstracts) {
  my %filtered_loci;
#   $count++;
#   last if ($count > 1000);
  my $abstract = $abstracts{$abs_join};
  if ($abstract =~ m/,/) { $abstract =~ s/,//g; }
  if ($abstract =~ m/\(/) { $abstract =~ s/\(//g; }
  if ($abstract =~ m/\)/) { $abstract =~ s/\)//g; }
  if ($abstract =~ m/;/) { $abstract =~ s/;//g; }
  my (@words) = split/\s+/, $abstract;
  foreach my $word (@words) {
    if ($gene_words{$word}) { $filtered_loci{$word}++; } }
  foreach my $word (sort keys %filtered_loci) {
    $frequency{$word}++;
    foreach my $gene (@{ $gene_words{$word} }) {
      my $command = "INSERT INTO wpa_gene VALUES ('$abs_join', '$gene($word)', 'Inferred_automatically\t\"update2_gene_cds.pl\"', 'valid', 'two1823', CURRENT_TIMESTAMP);";
      print OUT "$abs_join\t$gene($word)\n";
      print OUT "$command\n";
# UNCOMMENT THIS TO PUT DATA IN POSTGRES
      my $result = $conn->exec( $command );
    }
  }
}

# Uncomment this to show word frequency (counted once / abstract)
# print OUT "\n\n\nFrequency of words in abstract (counted once per abstract) :\n";
# foreach my $frequency (reverse sort { $frequency{$a} <=> $frequency{$b} } keys %frequency) {
#   print OUT "$frequency\t$frequency{$frequency}\n";
# } # foreach my $frequency (reverse sort {$a<=>$b} keys %frequency)




sub getListFromFlatFile {
  my $infile = '/home/azurebrd/public_html/sanger/wbgenes_to_words.txt';
  open (IN, "<$infile") or die "Cannot open $infile : $!";
  while (<IN>) {
    chomp;  my ($gene, $other) = split/\t/, $_;
    next unless ($gene);
    next unless ($other);
    push @{ $gene_words{$other} }, $gene;
  } # while (<IN>)
  close (IN) or die "Cannot close $infile : $!";
} # sub getListFromFlatFile

sub removeAndreiExclusions {
  if ($gene_words{''}) { delete $gene_words{''}; }	# in case there's a blank entry
  if ($gene_words{run}) { delete $gene_words{run}; }        # Andrei's exclusion list 2006 07 15
  if ($gene_words{SC}) { delete $gene_words{SC}; }
  if ($gene_words{GATA}) { delete $gene_words{GATA}; }
  if ($gene_words{eT1}) { delete $gene_words{eT1}; }
  if ($gene_words{RhoA}) { delete $gene_words{RhoA}; }
  if ($gene_words{TBP}) { delete $gene_words{TBP}; }
  if ($gene_words{syn}) { delete $gene_words{syn}; }
  if ($gene_words{TRAP240}) { delete $gene_words{TRAP240}; }
  if ($gene_words{'AP-1'}) { delete $gene_words{'AP-1'}; }
} # sub removeAndreiExclusions


sub updateListFromAce {		# would use this to update the list, but now update_loci.pl does this every day instead 2006 06 08
  print "Connecting to database...";
  my $db = Ace->connect('sace://aceserver.cshl.org:2005') || die "Connection failure: ", Ace->error;
# my $db = Ace->connect(-path => '/home/igor/AceDB',  -program => '/home/igor/AceDB/bin/tace') || die print "Connection failure: ", Ace->error;
  print "done\n";

  my $query="find gene live AND species=\"*elegans\"";
  my @genes=$db->find($query);
  
  print scalar @genes, " live C. elegans genes found\n";
  
  my $i=0;
  my $j=0;
  foreach (@genes) {
    $i++;
    if ($i % 1000 == 0) {
        print "$i genes processed\n";
    }
    
    my @names=();
    push @names, $_->CGC_name;
    push @names, $_->Sequence_name;
    push @names, $_->Molecular_name;
    push @names, $_->Other_name;
    my %name_hash=();
    foreach my $n (@names) {
        $name_hash{$n}=1;
    }
    foreach my $k (keys %name_hash) {
        push @{ $gene_words{$k} }, $_;
        print OUT "$_\t$k\n";
        $j++;
    }
  }
  print "$i genes processed\n";
  print "$j records generated\n";
} # sub updateListFromAce


