#!/usr/bin/perl

# for Erich to change pmids to cgcs 2003 04 24

use LWP::Simple;

my %cgcHash;	# hash of cgcs, values pmids
my %pmHash;	# hash of pmids, values cgcs
&populateXref();

# sample use :
my $number_coming_in = '[pmid9685266]';
&checkNumber($number_coming_in);
$number_coming_in = 'cgc3139';
&checkNumber($number_coming_in);


sub checkNumber {
  my $number_coming_in = shift;
	# if a capitalization insensitive pmid with possibly brackets around it
  if ($number_coming_in =~ m/\[?[pP][mM][iI][dD](\d+)\]?/) {	
    if ($pmHash{$1}) { print "$number_coming_in corresponds to [cgc" . $pmHash{$1} . "]\n"; } }
	# if a capitalization insensitive cgc with possibly brackets around it
  elsif ($number_coming_in =~ m/\[?[cC][gG][cC](\d+)\]?/) {	
    if ($cgcHash{$1}) { print "$number_coming_in corresponds to [pmid" . $cgcHash{$1} . "]\n"; } }
	# neither a cgc nor pmid
  else { print "NO MATCH FOR $number_coming_in\n"; }
} # sub checkNumber

sub populateXref {	# if not found, get ref_xref data to try to find alternate
  my $page = get "http://minerva.caltech.edu/~postgres/cgi-bin/cgc_pmid_xref.cgi";
  my @lines = split/\n/, $page;
  foreach my $line (@lines) {
    $line =~ m/<TR><TD ALIGN=CENTER>cgc(\d+)<\/TD><TD ALIGN=CENTER>pmid(\d+)<\/TD><\/TR>/;
    $cgcHash{$1} = $2; 
    $pmHash{$2} = $1; 
  }
#   foreach my $cgc (sort {$a <=> $b} keys %cgcHash) { print "STUFF $cgc : $cgcHash{$cgc}\n"; }
#   foreach my $pm (sort {$a <=> $b} keys %pmHash) { print "STUFF $pm : $pmHash{$pm}\n"; }
} # sub populateXref    
