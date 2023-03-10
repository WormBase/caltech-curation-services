#!/usr/bin/perl

# seems out of use
# -rwxr-xr-x  1 postgres postgres  3080 Aug  2  2005 getAcePatch.pl*
# loci_all.txt no longer updated, probably not working as it should.  2006 12 15




# Get wbgenes from abstract.  2005 08 01

use strict;
use diagnostics;
use LWP::UserAgent;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;


my %cdsToGene;

my $u = "http://tazendra.caltech.edu/~azurebrd/sanger/loci_all.txt";
my $ua = LWP::UserAgent->new(timeout => 30); #instantiates a new user agent
my $request = HTTP::Request->new(GET => $u); #grabs url 
my $response = $ua->request($request);       #checks url, dies if not valid.
die "Error while getting ", $response->request->uri," -- ", $response->status_line, "\nAborting" unless $response-> is_success;

my @tmp = split /\n/, $response->content;    #splits by line
foreach my $line (@tmp){
    my ($three, $wb, $useful) = $line =~ m/^(.*?),(.*?),.*?,(.*?),/;      # added to convert genes
    $useful =~ s/\([^\)]*\)//g; 
    if ($useful =~ m/\s+$/) { $useful =~ s/\s+$//g; }
    my (@cds) = split/\s+/, $useful;
    foreach my $cds (@cds) { 
      $cdsToGene{cds}{$cds} = $wb;  
      if ($cds =~ m/[a-zA-Z]+$/) { $cds =~ s/[a-zA-Z]+$//g; }
      $cdsToGene{cds}{$cds} = $wb; }
    $cdsToGene{locus}{$three} = $wb;  
    if ($line =~ m/,([^,]*?) ,approved$/) {            # 2005 06 08
      my @things = split/ /, $1;
      foreach my $thing (@things) {
        if ($thing =~ m/[a-zA-Z][a-zA-Z][a-zA-Z]\-\d+/) { $cdsToGene{locus}{$thing} = $wb; } } }
}

my $infile = 'abstracts_to_fix.longtext';
my $pg_commands = 'pg_file.pg';
open (PG, ">$pg_commands") or die "Cannot create $pg_commands : $!";

$/ = undef;
open (IN, "<$infile") or die "Cannot open $infile : $!";
my $whole_file = <IN>;
close (IN) or die "Cannot close $infile : $!";

my (@groups) = $whole_file =~ m/LongText : (.*?)\n\*\*\*LongTextEnd\*\*\*/sg;
foreach my $group (@groups) {
  my ($paper, $abstract, @junk) = split/\n/, $group;
  if (@junk) { print "BAD @junk $group\n"; }
  $paper = "Paper : $paper";
  if ($abstract =~ m/,/) { $abstract =~ s/,//g; }
  if ($abstract =~ m/\(/) { $abstract =~ s/\(//g; }
  if ($abstract =~ m/\)/) { $abstract =~ s/\)//g; }
  if ($abstract =~ m/;/) { $abstract =~ s/;//g; }
  my $extra = '';
  my %filtered_loci;
  my (@words) = split/\s+/, $abstract;
  foreach my $word (@words) { 
    if ($cdsToGene{locus}{$word}) { $filtered_loci{$word}++; } }
  my ($joinkey) = $paper =~ m/WBPaper(\d+)/;
  foreach my $word (sort keys %filtered_loci) {
# These are already in somehow wpa_timestamp 2005-07-19 16:23:24
#     print PG "my \$result = \$conn->exec( \"INSERT INTO wpa_gene VALUES ('$joinkey', '$cdsToGene{locus}{$word}', 'Inferred_automatically\t\"Abstract read $word\"', 'valid', 'two1823', CURRENT_TIMESTAMP) \" ); \n";
#     my $result = $conn->exec( "INSERT INTO wpa_gene VALUES ('$joinkey', '$cdsToGene{locus}{$word}', 'Inferred_automatically\t\"Abstract read $word\"', 'valid', 'two1823', CURRENT_TIMESTAMP) " ); 
    $extra .= "Gene\t\"$cdsToGene{locus}{$word}\"\tInferred_automatically\t\"Abstract read $word\"\n"; }
  if ($extra) { print "$paper\n$extra\n"; }
}

close (PG) or die "Cannot close $pg_commands : $!";

