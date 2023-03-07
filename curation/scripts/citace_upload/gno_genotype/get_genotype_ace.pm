package get_genotype_ace;
require Exporter;


our @ISA	= qw(Exporter);
our @EXPORT	= qw( getGenotype );
our $VERSION	= 1.00;

# dump genotype data.  for Ranjana and Chris.  2020 05 12
#
# https://wiki.wormbase.org/index.php/Genotype


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
my @tables = qw( identifier name synonym gene variation rearrangement transgene othercomp species remark paper nodump );
my @maintables = qw( name synonym gene variation rearrangement transgene othercomp species remark paper );


my $all_entry = '';
my $err_text = '';

my %nameToIDs;							# type -> name -> ids -> count
my %ids;


my %tableToTag;

$tableToTag{name}                  = 'Genotype_name';
$tableToTag{synonym}               = 'Genotype_synonym';
$tableToTag{gene}                  = 'Gene';
$tableToTag{variation}             = 'Variation';
$tableToTag{rearrangement}         = 'Rearrangement';
$tableToTag{transgene}             = 'Transgene';
$tableToTag{othercomp}             = 'Other_component';
$tableToTag{species}               = 'Species';
$tableToTag{remark}                = 'Remark';
$tableToTag{paper}                 = 'Reference';


my %pipeSplit;
$pipeSplit{"synonym"}++;

my %dataType;
$dataType{"gene"}                           = 'multiontology';
$dataType{"variation"}                      = 'multiontology';
$dataType{"rearrangement"}                  = 'multiontology';
$dataType{"transgene"}                      = 'multiontology';
$dataType{"paper"}                          = 'multiontology';


my %deadObjects;	 # reading the following
#  $deadObjects{paper}{invalid}{"WBPaper$row[0]"} = $row[1];
#  $deadObjects{gene}{"dead"}{"WBGene$row[0]"} = $row[1];
#  $deadObjects{gene}{"mapto"}{"WBGene$row[0]"} = $1;
#  $deadObjects{gene}{"split"}{"WBGene$row[0]"} = $1;

my %ontologyIdToName;


1;

sub getGenotype {
  my ($flag) = shift;

  &populateDeadObjects(); 

  if ( $flag eq 'all' ) { $result = $dbh->prepare( "SELECT * FROM gno_identifier; " ); }		# get all entries for type
    else { $result = $dbh->prepare( "SELECT * FROM gno_identifier WHERE gno_identifier = '$flag';" ); }	# get all entries for type of object intid
  $result->execute();	
  while (my @row = $result->fetchrow) { $theHash{object}{$row[0]} = $row[1]; $nameToIDs{object}{$row[1]}{$row[0]}++; $ids{$row[0]}++; }
  my $ids = ''; my $qualifier = '';
  if ($flag ne 'all') { $ids = join"','", sort keys %ids; $qualifier = "WHERE joinkey IN ('$ids')"; }
  foreach my $table (@tables) {
    $result = $dbh->prepare( "SELECT * FROM gno_$table $qualifier;" );		# get data for table with qualifier (or not if not)
    $result->execute();	
    while (my @row = $result->fetchrow) { $theHash{$table}{$row[0]} = $row[1]; }
  } # foreach my $table (@tables)

  foreach my $objName (sort keys %{ $nameToIDs{object} }) {
    my $entry = ''; my $has_data;
    $entry .= "\nGenotype : \"$objName\"\n";

    foreach my $joinkey (sort {$a<=>$b} keys %{ $nameToIDs{object}{$objName} }) {
      next if ($theHash{nodump}{$joinkey});
      my $cur_entry = '';
      foreach my $table (@maintables) {
        next unless ($tableToTag{$table});
        my $tag = $tableToTag{$table};
        $cur_entry = &getData($cur_entry, $table, $joinkey, $tag, $objName);
      }
      if ($cur_entry) { $entry .= "$cur_entry"; $has_data++; }                  # if .ace object has a phenotype, append to whole list
    } # foreach my $joinkey (sort {$a<=>$b} keys %{ $nameToIDs{$type}{$objName} })
    if ($has_data) { $all_entry .= $entry; }
  } # foreach my $objName (sort keys %{ $nameToIDs{$type} })
  return( $all_entry, $err_text );
} # sub getGenotype

sub getData {
  my ($cur_entry, $table, $joinkey, $tag, $objName) = @_;
  if ($theHash{$table}{$joinkey}) {
    my $data = $theHash{$table}{$joinkey};
#     if ($data =~ m/^\"/) { $data =~ s/^\"//; }	 # chris wants leading  doublequotes dumped  2016 08 13
#     if ($data =~ m/\"$/) { $data =~ s/\"$//; }
    if ($data =~ m//) { $data =~ s///g; }
    if ($data =~ m/\n/) { $data =~ s/\n/  /g; }
    if ($data =~ m/^\s+/) { $data =~ s/^\s+//g; } if ($data =~ m/\s+$/) { $data =~ s/\s+$//g; }
    my @data;
    my $dataType = $dataType{$table} || '';
    if ( ($dataType eq 'multiontology') || ($dataType eq 'multidropdown') ) {
        if ($data =~ m/^\"/) { $data =~ s/^\"//; }	# leading  doublequotes need to be removed from multivalue fields  2016 07 28
        if ($data =~ m/\"$/) { $data =~ s/\"$//; }
        @data = split/\",\"/, $data; }
      elsif ($pipeSplit{$table}) { @data = split/ \| /, $data; }
      else { push @data, $data; }
#     if ( ($table eq 'othermethod') || ($table eq 'pos_scl') || ($table eq 'neg_scl') || ($table eq 'not_scl') || ($table eq 'northern') || ($table eq 'western') || ($table eq 'insitu') || ($table eq 'rtpcr') ) { @data = (''); }	# just a toggle, no value	# was used in gene regulation model, might want here in the future 
    foreach my $value (@data) {
      if ($value =~ m/\"/) { $value =~ s/\"/\\\"/g; }
      if ($value) {
        my $geneFound = 0;
          if ($table eq 'paper') {
            if ($deadObjects{paper}{$value}) {
                $err_text .= qq($objName\tInvalid Paper\t"$value"\t$deadObjects{paper}{$value}\n); }
              else {
                $cur_entry .= "$tag\t\"$value\"\n"; } }
          elsif ($table eq 'gene') {	
            if ($deadObjects{gene}{$value}) {
                $err_text .= qq($objName\tInvalid Gene\t"$value"\t$deadObjects{gene}{$value}\n); }
              else {
                $cur_entry .= "$tag\t\"$value\"\n"; } }
          else {									# regular values
            $cur_entry .= "$tag\t\"$value\"\n"; }
      } # if ($value)
    } # foreach my $value (@data)
  } # if ($theHash{$table}{$joinkey})
  return $cur_entry;
} # sub getData

sub populateDeadObjects {
  $result = $dbh->prepare( "SELECT * FROM pap_status WHERE pap_status = 'invalid';" ); $result->execute();
  while (my @row = $result->fetchrow) { $deadObjects{paper}{"WBPaper$row[0]"} = $row[1]; }
  $result = $dbh->prepare( "SELECT * FROM gin_dead;" ); $result->execute();
  while (my @row = $result->fetchrow) {			# Chris sets precedence of split before merged before suppressed before dead, and a gene can only have one value, referring to the highest priority (only 1 value per gene in gin_dead table)  2013 10 21
    if ($row[1] =~ m/split_into (WBGene\d+)/) {		$deadObjects{gene}{"split"}{"WBGene$row[0]"} = $1; }
      elsif ($row[1] =~ m/merged_into (WBGene\d+)/) {	$deadObjects{gene}{"mapto"}{"WBGene$row[0]"} = $1; }
      elsif ($row[1] =~ m/Suppressed/) {		$deadObjects{gene}{"suppressed"}{"WBGene$row[0]"} = $row[1]; }
      elsif ($row[1] =~ m/Dead/) {			$deadObjects{gene}{"dead"}{"WBGene$row[0]"} = $row[1]; } }
  my $doAgain = 1;                                    # if a mapped gene maps to another gene, loop through all again
  while ($doAgain > 0) {
    $doAgain = 0;                                     # stop if no genes map to other genes
    foreach my $gene (sort keys %{ $deadObjects{gene}{mapto} }) {
      next unless ( $deadObjects{gene}{mapTo}{$gene} );
      my $mappedGene = $deadObjects{gene}{mapTo}{$gene};
      if ($deadObjects{gene}{mapTo}{$mappedGene}) {
        $deadObjects{gene}{mapTo}{$gene} = $deadObjects{gene}{mapTo}{$mappedGene};          # set mapping of original gene to 2nd degree mapped gene
        $doAgain++; } } }                             # loop again in case a mapped gene maps to yet another gene
} # sub populateDeadObjects


