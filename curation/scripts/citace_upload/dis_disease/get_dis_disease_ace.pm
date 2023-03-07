package get_dis_disease_ace;
require Exporter;


our @ISA	= qw(Exporter);
our @EXPORT	= qw( getDisease );
our $VERSION	= 1.00;

# Dumper module to dump Ranjana's dis_ disease data.  2013 01 18
#
# added extra omimGene stuff for Ranjana.  2013 05 24
#
# added checks for dead genes and papers, put that in err_text, for Ranjana.  2013 10 25
#
# added check for invalid human DOID, for Ranjana.  2014 05 29
#
# no longer dump Database OMIM disease $omim
# instead dump each of them for each doid as Experimental_model $doid $species Accession_evidence OMIM $omim
# until Ranjana figures out how to dump them, don't dump  dis_dbdisrel  nor  dis_genedisrel 
# for Ranjana  2014 09 15
#
# dump omim data as accession_evidence for disease_relevance for  dis_dbdisrel  and  dis_genedisrel  2014 09 22
#
# doid ontology has obsolete terms, put those in deadObjects for validation.  2018 08 29



use strict;
use diagnostics;
use LWP;
use LWP::Simple;
use DBI;

use Dotenv -load => '/usr/lib/.env';

my $dbh = DBI->connect ( "dbi:Pg:dbname=$ENV{PSQL_DATABASE};host=$ENV{PSQL_HOST};port=$ENV{PSQL_PORT}", "$ENV{PSQL_USERNAME}", "$ENV{PSQL_PASSWORD}") or die "Cannot connect to database!\n";
# my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my $result;

my %theHash;
my @tables = qw( wbgene curator humandoid paperexpmod dbexpmod lastupdateexpmod species diseaserelevance paperdisrel dbdisrel genedisrel lastupdatedisrel );


my $all_entry = '';
my $err_text = '';

my %nameToIDs;							# type -> name -> ids -> count
my %ids;

my %deadObjects;
# my %validObjects;


my %dataType;
$dataType{humandoid}   = 'multi';
$dataType{paperexpmod} = 'multi';
$dataType{paperdisrel} = 'multi';
$dataType{dbexpmod}    = 'comma';
$dataType{dbdisrel}    = 'comma';




1;

sub populateDeadAndValidObjects {
  $result = $dbh->prepare( "SELECT * FROM pap_status WHERE pap_status = 'invalid';" ); $result->execute();
  while (my @row = $result->fetchrow) { $deadObjects{paper}{invalid}{"WBPaper$row[0]"} = $row[1]; }
  $result = $dbh->prepare( "SELECT * FROM gin_dead;" ); $result->execute();
  while (my @row = $result->fetchrow) {                 # Ranjana doesn't care about hierarchy, just show her an error message
    if ($row[1]) { $deadObjects{gene}{"WBGene$row[0]"} = $row[1]; } }
  $result = $dbh->prepare( "SELECT * FROM obo_data_humando WHERE obo_data_humando ~ 'is_obsolete: true';" ); $result->execute();
  while (my @row = $result->fetchrow) { $deadObjects{humando}{"$row[0]"}++; }
} # sub populateDeadAndValidObjects

sub getDisease {
  my ($flag) = shift;

  &populateDeadAndValidObjects();

  if ( $flag eq 'all' ) { $result = $dbh->prepare( "SELECT * FROM dis_wbgene; " ); }		# get all entries for all wbgenes
    else { $result = $dbh->prepare( "SELECT * FROM dis_wbgene WHERE dis_wbgene = '$flag';" ); }	# get all entries for all wbgenes with object name $flag
  $result->execute();	
  while (my @row = $result->fetchrow) { 
    if ($deadObjects{gene}{$row[1]}) { $err_text .= "pgid $row[0] has $row[1] which is $deadObjects{gene}{$row[1]}\n"; }	# add dead wbgenes to error out
      else { $theHash{object}{$row[0]} = $row[1]; $nameToIDs{object}{$row[1]}{$row[0]}++; $ids{$row[0]}++; } }		# add non-dead genes to hashes
  my $ids = ''; my $qualifier = '';
  if ($flag ne 'all') { $ids = join"','", sort keys %ids; $qualifier = "WHERE joinkey IN ('$ids')"; }
  foreach my $table (@tables) {
    $result = $dbh->prepare( "SELECT * FROM dis_$table $qualifier;" );		# get data for table with qualifier (or not if not)
    $result->execute();	
    while (my @row = $result->fetchrow) { $theHash{$table}{$row[0]} = $row[1]; }
  } # foreach my $table (@tables)

  foreach my $objName (sort keys %{ $nameToIDs{object} }) {
    my $entry = ''; my $has_data;
    $entry .= "\nGene : \"$objName\"\n";

    foreach my $pgid (sort {$a<=>$b} keys %{ $nameToIDs{object}{$objName} }) {
      my $species = ''; if ($theHash{species}{$pgid}) { $species = $theHash{species}{$pgid}; }
      my %omim = (); my %omimGene;
      if ($theHash{humandoid}{$pgid}) {
        my (@doids) = $theHash{humandoid}{$pgid} =~ m/(DOID:\d+)/g;
        my @papers; my @all_papers;
        if ($theHash{paperexpmod}{$pgid}) { (@all_papers) = $theHash{paperexpmod}{$pgid} =~ m/(WBPaper\d+)/g; }
        foreach my $paper (@all_papers) { 			# get all papers and send error message for invalid papers, and add valid to list of papers
          if ($deadObjects{paper}{invalid}{$paper}) { $err_text .= "pgid $pgid has invalid paper $paper\n"; }
            else { push @papers, $paper; } }
        if ($theHash{dbexpmod}{$pgid}) { my (@om) = $theHash{dbexpmod}{$pgid} =~ m/(\d+)/g; foreach (@om) { $omim{$_}++; } }	# Ranjana doesn't want to enter OMIM: each time, so match any group of digits to be an omim value 2013 05 15
        foreach my $doid (@doids) {
          if ($deadObjects{humando}{$doid}) { $err_text .= "pgid $pgid has invalid DOID $doid\n"; }
          foreach my $omim (sort keys %omim) { $entry .= qq(Experimental_model\t"$doid"\t"$species"\tAccession_evidence\t"OMIM"\t"$omim"\n); }	# added to dump for each doid for Ranjana 2014 09 15
          if (scalar @papers > 0) { foreach my $paper (@papers) { $entry .= qq(Experimental_model\t"$doid"\t"$species"\tPaper_evidence\t"$paper"\n); } }
            else { $entry .= qq(Experimental_model\t"$doid"\t"$species"\n); }
          if ($theHash{curator}{$pgid}) { $entry .= qq(Experimental_model\t"$doid"\t"$species"\tCurator_confirmed\t"$theHash{curator}{$pgid}"\n); }
          if ($theHash{lastupdateexpmod}{$pgid}) { if ($theHash{lastupdateexpmod}{$pgid} =~ m/(\d{4}.\d{2}.\d{2})/) { 
            # if there's a date last updated for exp mod, match the year month day and add to Date_last_updated
            $entry .= qq(Experimental_model\t"$doid"\t"$species"\tDate_last_updated\t"$1"\n); } } }
      }
      if ($theHash{diseaserelevance}{$pgid}) {
        my $disrel = $theHash{diseaserelevance}{$pgid}; if ($disrel =~ m/\'/) { $disrel =~ s/\'/''/g; } if ($disrel =~ m/\n/) { $disrel =~ s/\n/ /g; }
        my @papers; my @all_papers;
        if ($theHash{paperdisrel}{$pgid}) { (@all_papers) = $theHash{paperdisrel}{$pgid} =~ m/(WBPaper\d+)/g; }
        foreach my $paper (@all_papers) { 			# get all papers and send error message for invalid papers, and add valid to list of papers
          if ($deadObjects{paper}{invalid}{$paper}) { $err_text .= "pgid $pgid has invalid paper $paper\n"; }
            else { push @papers, $paper; } }
        if (scalar @papers > 0) { foreach my $paper (@papers) { $entry .= qq(Disease_relevance\t"$disrel"\t"$species"\tPaper_evidence\t"$paper"\n); } }
          else { $entry .= qq(Disease_relevance\t"$disrel"\t"$species"\n); }
        if ($theHash{curator}{$pgid}) { $entry .= qq(Disease_relevance\t"$disrel"\t"$species"\tCurator_confirmed\t"$theHash{curator}{$pgid}"\n); }
        if ($theHash{lastupdatedisrel}{$pgid}) { if ($theHash{lastupdatedisrel}{$pgid} =~ m/(\d{4}.\d{2}.\d{2})/) { 
          # if there's a date last updated for dis rel, match the year month day and add to Date_last_updated
          $entry .= qq(Disease_relevance\t"$disrel"\t"$species"\tDate_last_updated\t"$1"\n); } }
        if ($theHash{dbdisrel}{$pgid}) { 
          my (@om) = $theHash{dbdisrel}{$pgid} =~ m/(\d+)/g;
            foreach my $omim (@om) { 
              $entry .= qq(Disease_relevance\t"$disrel"\t"$species"\tAccession_evidence\t"OMIM"\t"$omim"\n);	# ranjana wants to dump omim accession evidence 2014 09 22
              $omim{$omim}++; } }	# Ranjana doesn't want to enter OMIM: each time, so match any group of digits to be an omim value 2013 05 15   
        if ($theHash{genedisrel}{$pgid}) { 
          my (@om) = $theHash{genedisrel}{$pgid} =~ m/(\d+)/g;
            foreach my $omim (@om) {
              $entry .= qq(Disease_relevance\t"$disrel"\t"$species"\tAccession_evidence\t"OMIM"\t"$omim"\n);	# ranjana wants to dump omim accession evidence 2014 09 22
              $omimGene{$omim}++; } }	# Ranjana doesn't want to enter OMIM: each time, so match any group of digits to be an omim value 2013 05 15
      }
      foreach my $omim (sort keys %omim) { $entry .= qq(Database\t"OMIM"\t"disease"\t"$omim"\n); }		
      foreach my $omimGene (sort keys %omimGene) { $entry .= qq(Database\t"OMIM"\t"gene"\t"$omimGene"\n); }	
      if ($entry) { $has_data++; }
    } # foreach my $pgid (sort {$a<=>$b} keys %{ $nameToIDs{$type}{$objName} })
    if ($has_data) { $all_entry .= $entry; }
  } # foreach my $objName (sort keys %{ $nameToIDs{$type} })

  return( $all_entry, $err_text );
} # sub getDisease

__END__

sub getData {
  my ($cur_entry, $table, $joinkey, $tag, $objName, $goodGenes_ref) = @_;
  if ($theHash{$table}{$joinkey}) {
    my $data = $theHash{$table}{$joinkey};
    if ($data =~ m/^\"/) { $data =~ s/^\"//; }
    if ($data =~ m/\"$/) { $data =~ s/\"$//; }
    if ($data =~ m//) { $data =~ s///g; }
    if ($data =~ m/\n/) { $data =~ s/\n/  /g; }
    if ($data =~ m/^\s+/) { $data =~ s/^\s+//g; } if ($data =~ m/\s+$/) { $data =~ s/\s+$//g; }
    my @data;
    if ($data =~ m/\",\"/) { @data = split/\",\"/, $data; }
      elsif ($pipeSplit{$table}) { @data = split/ \| /, $data; }
      else { push @data, $data; }
    foreach my $value (@data) {
      if ($value =~ m/\"/) { $value =~ s/\"/\\\"/g; }
    } # foreach my $value (@data)
  }
  return $cur_entry;
} # sub getData

