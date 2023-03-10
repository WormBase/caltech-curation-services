#!/usr/bin/perl -w

# dump phenote transgene .ace data.
# set cronjob for 6 am fridays for spica to pick it up  2008 10 14
#
# a lot of fields are now multiontology / multidropdown, and need to be split on "," 
# while others still need to be split on | because they're just text with pipes 
# manually entered.  
# added restriction that it must have summary OR remark (for Karen)  2010 08 26
#
# dump Gene tags as multiontology.  2010 09 27
#
# changed  trp_location to trp_laboratory  trp_reference to trp_paper  
# trp_integrated_by to trp_integration_method .
# removed  trp_movie  and  trp_picture .
# added  trp_rescues  to dump.  
# added  trp_reporter_type .
# added extra single-tag lines for some name and reporter_type.  2011 05 17
#
# 0 6 * * fri /home/acedb/wen/phenote_transgene/transgene_dump_ace.pl
# 
# deprecated -- replaced by :
0 6 * * wed cd /home/acedb/karen/transgene; ./use_package.pl



use strict;
use diagnostics;
use Jex;
use DBI;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my $directory = '/home/acedb/wen/phenote_transgene';
chdir($directory) or die "Cannot go to $directory ($!)";

my $date = &getSimpleDate();
my $outfile = 'transgene.ace.' . $date;
open (OUT, ">$outfile") or die "Cannot open $outfile : $!";
my $outfile2 = 'transgene.ace';
open (OU2, ">$outfile2") or die "Cannot open $outfile2 : $!";

my @tables = qw( name summary driven_by_gene reporter_product other_reporter gene threeutr integration_method particle_bombardment strain map map_paper map_person marker_for marker_for_paper paper person reporter_type remark species synonym driven_by_construct laboratory objpap_falsepos );

my %allele_to_lab;			# get mapping of allele codes to lab codes from obo table
my $result = $dbh->prepare( "SELECT * FROM obo_data_laboratory WHERE obo_data_laboratory ~ 'allele_code';" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  my ($allele_code) = $row[1] =~ m/allele_code: (\w+)/;
  $allele_to_lab{$allele_code} = $row[0]; }

my %hash;
foreach my $table (@tables) {
  my $result = $dbh->prepare( "SELECT * FROM trp_$table ORDER BY trp_timestamp;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    if ($row[0]) { $hash{$table}{$row[0]} = $row[1]; } }
} # foreach my $table (@tables)

foreach my $joinkey (sort keys %{ $hash{name} }) {
  next if ($hash{objpap_falsepos}{$joinkey});	# skip fail entries  2010 08 26
  next unless ($hash{name}{$joinkey});	# skip deleted ones without name  2008 10 30
  next unless ( ($hash{summary}{$joinkey}) || ($hash{remark}{$joinkey}) );	# skip unless it has either summary or remark (for Karen) 2010 08 26
  print OUT "Transgene : $hash{name}{$joinkey}\n";
  print OU2 "Transgene : $hash{name}{$joinkey}\n";
  if ( ($hash{name}{$joinkey} =~ m/[a-z]+Ex\d+/) || ($hash{name}{$joinkey} =~ m/WBPaper\d+_Ex\d+/) ) { &printTag('Extrachromosomal'); }
  if ($hash{summary}{$joinkey}) { &printTag('Summary', $hash{summary}{$joinkey}); }
  if ($hash{driven_by_gene}{$joinkey}) { &printTag('Driven_by_gene', $hash{driven_by_gene}{$joinkey}); }
  if ($hash{reporter_product}{$joinkey}) { &printTag('Reporter_product', $hash{reporter_product}{$joinkey}); }
  if ($hash{other_reporter}{$joinkey}) { &printTag('Reporter_product', $hash{other_reporter}{$joinkey}); }
  if ($hash{gene}{$joinkey}) { &printTag('Gene', $hash{gene}{$joinkey}); }
  if ($hash{threeutr}{$joinkey}) { &printTag('3_UTR', $hash{threeutr}{$joinkey}); }
  if ($hash{integration_method}{$joinkey}) { &printTag('Integration_method', $hash{integration_method}{$joinkey}); &printTag('Integrated'); }
  if ($hash{particle_bombardment}{$joinkey}) { &printTag('Particle_bombardment', $hash{particle_bombardment}{$joinkey}); }
  if ($hash{strain}{$joinkey}) { &printTag('Strain', $hash{strain}{$joinkey}); }
  if ($hash{map}{$joinkey}) { &printTag('Map', $hash{map}{$joinkey}); }
  if ($hash{map_person}{$joinkey}) { &printTag("Map_evidence\tPerson_evidence", $hash{map_person}{$joinkey}); }
  if ($hash{map_paper}{$joinkey}) { &printTag("Map_evidence\tPaper_evidence", $hash{map_paper}{$joinkey}); }
  if ($hash{marker_for}{$joinkey}) { &printTag('Marker_for', $hash{marker_for}{$joinkey}, $joinkey); }
  if ($hash{paper}{$joinkey}) { &printTag('Reference', $hash{paper}{$joinkey}); }
#   if ($hash{person}{$joinkey}) { &printTag('Person', $hash{person}{$joinkey}); }	# tag not in model yet
  if ($hash{reporter_type}{$joinkey}) { &printTag('Reporter_type', $hash{reporter_type}{$joinkey}); }
#   if ($hash{rescues}{$joinkey}) { &printTag('Rescue', $hash{rescues}{$joinkey}); }
  if ($hash{remark}{$joinkey}) { &printTag('Remark', $hash{remark}{$joinkey}); }
  if ($hash{species}{$joinkey}) { &printTag('Species', $hash{species}{$joinkey}); }
  if ($hash{synonym}{$joinkey}) { &printTag('Synonym', $hash{synonym}{$joinkey}); }
  if ($hash{driven_by_construct}{$joinkey}) { &printTag('Driven_by_construct', $hash{driven_by_construct}{$joinkey}); }
#   if ($hash{movie}{$joinkey}) { &printTag('Movie', $hash{movie}{$joinkey}); }
#   if ($hash{picture}{$joinkey}) { &printTag('Picture', $hash{picture}{$joinkey}); }
  if ($hash{laboratory}{$joinkey}) { &printTag('Laboratory', $hash{laboratory}{$joinkey}); }			# normal case
    else {
      if ($hash{name}{$joinkey} =~ m/^([a-z]+)[A-Z]/) { my $allele_name = $1;				# get allele code from transgene name
        if ($allele_to_lab{$allele_name}) { &printTag('Laboratory', $allele_to_lab{$allele_name}); }	# get laboratory from mapping if exists
           else { print "$hash{name}{$joinkey} has neither laboratory nor allele to lab mapping\n"; } } }	# warn if there's no laboratory
  print OUT "\n";
  print OU2 "\n";
} # foreach my $joinkey (sort keys %{ $hash{name} })

close (OUT) or die "Cannot close $outfile : $!";
close (OU2) or die "Cannot close $outfile2 : $!";

sub printTag {
  my ($tag, $data, $joinkey) = @_;
  my @data = ();
  if ($data) {
      if ( ($tag eq 'Gene') || ($tag eq '3_UTR') || ($tag eq 'Driven_by_gene') || ($tag eq 'Reporter_product') || ($tag eq 'Map') || ($tag eq "Map_evidence\tPerson_evidence") || ($tag eq "Map_evidence\tPaper_evidence") || ($tag eq 'Laboratory') || ($tag eq 'Reference') || ($tag eq 'Person') ) { $data =~ s/^"//; $data =~ s/"$//; (@data) = split/\",\"/, $data; }
        else { (@data) = split/ \| /, $data; }
      foreach my $data (@data) { 
        $data =~ s/\"//g;
        $data =~ s/\n/ /g;		# replace all newlines with spaces  2010 10 29
        $data =~ s/  / /g;		# replace all double spaces with single spaces  2010 10 29
        print OUT "$tag\t\"$data\"\n";
        print OU2 "$tag\t\"$data\"\n";
        if ($tag eq 'Marker_for') { if ($hash{marker_for_paper}{$joinkey}) { &printTag( "Marker_for\t\"$data\"\tPaper_evidence\t", $hash{marker_for_paper}{$joinkey}) ; } } } }
    else {
      print OUT "$tag\n";
      print OU2 "$tag\n"; }
} # sub printTag

