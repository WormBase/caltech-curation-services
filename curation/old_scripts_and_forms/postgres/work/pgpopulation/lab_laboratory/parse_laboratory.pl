#!/usr/bin/perl -w

# populate MaryAnn's lab data into postgres for Cecilia to take over.  2017 10 14
#
# populated tazendra.  2018 04 10

use strict;
use diagnostics;
use DBI;
use Encode;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %skipHeader;
$skipHeader{"Clean_address"}++;
$skipHeader{"Representative"}++;
$skipHeader{"Alleles"}++;
$skipHeader{"Gene_classes"}++;
$skipHeader{"Former_gene_classes"}++;
$skipHeader{"Registered_lab_members"}++;
$skipHeader{"Past_lab_members"}++;

my %goodHeader;
$goodHeader{"Mail"}                       = "mail";
$goodHeader{"Phone"}                      = "phone";
$goodHeader{"E_mail"}                     = "email";
$goodHeader{"Fax"}                        = "fax";
$goodHeader{"URL"}                        = "url";
$goodHeader{"Strain_designation"}         = "straindesignation";
$goodHeader{"Allele_designation"}         = "alleledesignation";
$goodHeader{"Remark"}                     = "remark";

my %data;

my $counter = 0;

$/ = "";
# my $infile = 'lab_class.txt';
my $infile = 'Final_strain_dump_JC_clatech_data_only.ace';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $entry = <IN>) {
  $entry =~ s///g;
  $entry =~ s/\\n\\\n//g;
  $entry =~ s/\\//g;
  $entry = encode( "UTF-8", $entry );
  my (@lines) = split/\n/, $entry;
  my ($objline) = shift @lines;
  my ($lab) = $objline =~ m/"(.*?)"/;
  push @{ $data{$lab}{'lab_name'} }, $lab;
#   print qq(H $lab H\n);
  foreach my $line (@lines) {
    next unless $line;
    my ($header, $rest) = ('', '');
    if ($line =~ m/^(.*?)\t (.*)$/) {
        ($header, $rest) = $line =~ m/^(.*?)\t (.*)$/; }
      else { 
        $header = $line; 
        $header =~ s/\s+$//g; }
    next if ($skipHeader{$header});
#     next if ($goodHeader{$header});
#     print qq(L $line H $header H $rest E $entry E\n);
    $rest =~ s/^\"//; $rest =~ s/\"$//; $rest =~ s/\'/''/g;
#     if ($header eq 'Strain_designation') { if ($rest ne $lab) { print qq(ERROR : lab $lab is not strain designation $rest\n); } }
    my $pgtable = 'lab_' . $goodHeader{$header};
    push @{ $data{$lab}{$pgtable} }, $rest;
#     print qq(H $header R $rest E\n);
  } # foreach my $line (@lines)
} # while (my $entry = <IN>)
close (IN) or die "Cannot close $infile : $!";

my @pgcommands;
foreach my $lab (sort keys %data) {
  $counter++;
  my $joinkey = 'lab' . $counter;
  push @pgcommands, qq(INSERT INTO lab_status     VALUES ('$joinkey', 1, 'Valid', 'two2970'););
  push @pgcommands, qq(INSERT INTO lab_status_hst VALUES ('$joinkey', 1, 'Valid', 'two2970'););
  foreach my $pgtable (sort keys %{ $data{$lab} }) {
    my $count = 0;
    foreach my $entry (@{ $data{$lab}{$pgtable} }) { 
      $count++;
      print qq($lab\t$count\t$pgtable\t$entry\n);
      push @pgcommands, qq(INSERT INTO $pgtable     VALUES ('$joinkey', $count, '$entry', 'two2970'););
      push @pgcommands, qq(INSERT INTO ${pgtable}_hst VALUES ('$joinkey', $count, '$entry', 'two2970'););
    } # foreach my $entry (@{ $data{$lab}{$pgtable} })
  } # foreach my $pgtable (sort keys %{ $data{$lab} })
} # foreach my $lab (sort keys %data)

foreach my $pgcommand (@pgcommands) {
  print qq($pgcommand\n);
# UNCOMMENT TO POPULATE
#   $dbh->do( $pgcommand );
} # foreach my $pgcommand (@pgcommands)

__END__

?Laboratory Address Mail Text
                    Phone Text
                    E_mail Text
                    Fax Text
                    URL Text //to link to lab homepage ar2 02-DEC-05
            Clean_address #Address
            CGC Representative ?Person XREF CGC_representative_for
                Strain_designation UNIQUE Text
                Allele_designation UNIQUE Text
                Alleles ?Variation
                Gene_classes ?Gene_class XREF Designating_laboratory
                Former_gene_classes ?Gene_class
            Staff Registered_lab_members ?Person XREF Laboratory   // for people with WormBase Person IDs
                  Past_lab_members ?Person XREF Old_laboratory     // for anyone who has left the field, or the circle of life
            Remark ?Text #Evidence

Laboratory : "AA"
Mail	 "Max Planck Institute for Biology and Ageing"
Phone	 "49 (0)221 4726-345"
E_mail	 "aantebi@bcm.tmc.edu"
URL	 "http:\/\/www.age.mpg.de\/index.php?id=vita_antebi"
Representative	 "WBPerson759"
Allele_designation	 "dh"

Laboratory : "AB"
Mail	 "CSIRO Adelaide, Australia"
Representative	 "WBPerson796"
Strain_designation	 "AB"
Allele_designation	 "aa"
Registered_lab_members	 "WBPerson796"
Remark	 "No longer an active PI" CGC_data_submission

Laboratory : "ABA"
Mail	 "Lancaster University, Lancaster, UK"
Phone	 "+44 (0)1524 594999"
E_mail	 "a.benedetto@lancaster.ac.uk"
Representative	 "WBPerson1957"
Allele_designation	 "aeb"
Registered_lab_members	 "WBPerson1957"

$result = $dbh->prepare( "SELECT * FROM two_comment" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[1] =~ s///g;
    $row[2] =~ s///g;
    print "$row[0]\t$row[1]\t$row[2]\n";
  } # if ($row[0])
} # while (@row = $result->fetchrow)

