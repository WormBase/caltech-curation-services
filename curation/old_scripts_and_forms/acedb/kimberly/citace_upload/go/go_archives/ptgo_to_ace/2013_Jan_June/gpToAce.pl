#!/usr/bin/perl

# convert  gp_association.wb  to .ace file  for Kimberly and Ranjana  2013 02 15

use strict;
use warnings;

use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my %pmidToWBPaper;				# map pmid to wbpaper
my $result = $dbh->prepare( "SELECT * FROM pap_identifier WHERE pap_identifier ~ 'pmid'" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  my $pmid = $row[1]; $pmid =~ s/pmid/PMID:/;
  $pmidToWBPaper{$pmid} = "WBPaper$row[0]";
} # while (my @row = $result->fetchrow)


my %hash;						# store .ace lines by WBGene key

my %otherAssigners;				# assigneby not WormBase

my %curatorToId;
$curatorToId{"Kimberley Van Auken"} = 'WBPerson1843';
$curatorToId{"Ranjana Kishore"}     = 'WBPerson324';
$curatorToId{"Josh Jaffery"}        = 'WBPerson5196';
$curatorToId{"Carol Bastiani"}      = 'WBPerson48';

my %uniprotToWBGene;			# map gene's uniprot id to wbgene
my $infile = 'gp2protein.wb';
open(IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) {
  chomp $line;
  my ($wb, $uni) = split/\t/, $line;
  my @wbgenes; my @uniprots;
  if ($wb =~ m/WBGene\d+/) { (@wbgenes) = $wb =~ m/(WBGene\d+)/g; }
  (@uniprots) = split/;/, $uni;
  foreach my $wbgene (@wbgenes) {
    foreach my $uniprot (@uniprots) {
      $uniprot =~ s/UniProtKB://;
      $uniprotToWBGene{$uniprot} = $wbgene; } }
} # while (my $line = <IN>)
close(IN) or die "Cannot close $infile : $!";


my $outfile = 'gp_association.ace';
open(OUT, ">$outfile") or die "Cannot open $outfile : $!";

$infile = 'gp_association.wb';
open(IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) {
  next if ($line =~ m/^\!/); 
  chomp $line;
  my ($db, $dbid, $qual, $goid, $dbref, $evicode, $with, $taxonId, $date, $assignedby, $annotext, $annotprop) = split/\t/, $line;
  next if ($qual);
  my $goevi = ''; my $curator = ''; my $curatorName = ''; my $wbgene = ''; my $wbpaper = '';
  if ($annotprop) {
    my (@pairs) = split/\|/, $annotprop;
    foreach my $pair (@pairs) {
      my ($key, $value) = split/=/, $pair;
      if ($key eq 'go_evidence') { $goevi = $value; }
        elsif ($key eq 'curator_name') { $curatorName = $value;  }
   } }
  if ($assignedby eq 'WormBase') {  
      if ($curatorToId{$curatorName}) { $curator = $curatorToId{$curatorName}; }
        else { print "ERR $curatorName does not map to a curator ID\n"; } }
    else { $otherAssigners{$assignedby}++; }
  unless ($goevi) { print "ERR no evidence code $line\n"; next; }
  unless ($goid) { print "ERR no go id $line\n"; next; }
  unless ($dbid) { print "ERR no dbid $line\n"; next; }
  if ($uniprotToWBGene{$dbid}) { $wbgene  = $uniprotToWBGene{$dbid}; }
  my $line_front = qq(GO_term\t"$goid"\t"$goevi"\t);
  if ($dbref) {
    if ($pmidToWBPaper{$dbref}) {
        $wbpaper = $pmidToWBPaper{$dbref};
        $line = $line_front . qq(Paper_evidence\t"$wbpaper");
        $hash{$wbgene}{$line}++; }
      else { print "ERR $dbref does not map to WBPaper\n"; } }
  if ($curator) { 
    $line = $line_front . qq(Curator_confirmed\t"$curator");
    $hash{$wbgene}{$line}++; }
  if ($date) { 
    my ($year, $month, $day);
    if ($date =~ m/^(\d{4})(\d{2})(\d{2})/) {
        ($year, $month, $day) = $date =~ m/^(\d{4})(\d{2})(\d{2})/; 
        $line = $line_front . qq(Date_last_updated\t"$year-$month-$day");
        $hash{$wbgene}{$line}++; }
      else { print "ERR $date not in YYYYMMDD format\n"; } }
} # while (my $line = <IN>)
close(IN) or die "Cannot close $infile : $!";

foreach my $gene (sort keys %hash) {
  print OUT qq(Gene : "$gene"\n);
  foreach my $line (sort keys %{ $hash{$gene} } ) { print OUT qq($line\n); }
  print OUT qq(\n);
} # foreach my $gene (sort keys %hash)

foreach my $other (sort keys %otherAssigners) {
  print "Assigned_by $other\n";
} # foreach my $other (sort keys %otherAssigners)

close(OUT) or die "Cannot close $outfile : $!";


__END__

