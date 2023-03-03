package get_antibody_ace;
require Exporter;


our @ISA	= qw(Exporter);
our @EXPORT	= qw( getAntibody );
our $VERSION	= 1.00;

# dump antibody data.  for Xiaodong.  2012 05 31
#
# added Historical_gene stuff for abp_gene.  2013 05 22
#
# changed gin_dead to not have just "Dead" or "split_into / merged_into", now it has Dead / Suppressed / merged_into / split_into independent of
# each other (all merged / split must be dead though), so Chris has made a precedece for how to treat them (split > merged > suppressed > dead),
# and the dumper makes the Historical_gene comments appropriately.  2013 10 21
#
# Historical_gene Remark moved out of #Evidence into just Text.  2015 03 14
#
# Added humandoid and diseasepaper to dump as Antibody_for_disease and Paper_evidence for that tag.  2015 09 22
#
# Have replace abp_name with WBAntibody IDs and added abp_publicname with the names that used to be in abp_name.  2021 04 14
#
# Remove other_animal and possible_pseudonym from dumping, since they've been moved into remark.  2021 04 16
#
# Rewritten for unicode changes  2021 05 16
#
# Transferred to dockerized.  2023 03 01




use strict;
use diagnostics;
use LWP;
use LWP::Simple;
use DBI;

use Dotenv -load => '/usr/lib/.env';

# use lib qw( /home/postgres/work/citace_upload/ );               # for general ace dumping functions
use lib qw(  /usr/lib/scripts/perl_modules/ );                      # for general ace dumping functions
use ace_dumper;

# use ace_dumper;

# use lib qw( /home/postgres/public_html/cgi-bin/oa/ );           # to get tables/fields and which ones to split as multivalue
use lib qw( /usr/lib/priv/cgi-bin/oa/ );
use wormOA;


my $dbh = DBI->connect ( "dbi:Pg:dbname=$ENV{PSQL_DATABASE};host=$ENV{PSQL_HOST};port=$ENV{PSQL_PORT}", "$ENV{PSQL_USERNAME}", "$ENV{PSQL_PASSWORD}") or die "Cannot connect to database!\n";
# my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;


my $datatype = 'abp';
my ($fieldsRef, $datatypesRef) = &initModFields($datatype, 'two1823');
my %fields = %$fieldsRef;
my %datatypes = %$datatypesRef;

my $simpleRemapHashRef = &populateSimpleRemap();

my $deadObjectsHashRef = &populateDeadObjects();
my %deadObjects = %$deadObjectsHashRef;


my $all_entry = '';
my $err_text = '';

my %nameToIDs;							# type -> name -> ids -> count
my %ids;

my %theHash;
# my %names;
my @tables = qw( publicname summary gene clonality animal antigen peptide protein source original_publication paper remark other_name laboratory other_animal other_antigen possible_pseudonym humandoid diseasepaper );

my %tableToTag;
foreach my $table (@tables) { $tableToTag{$table} = ucfirst($table); }
$tableToTag{'publicname'}   = 'Public_name';
$tableToTag{'laboratory'}   = 'Location';
$tableToTag{'paper'}        = 'Reference';
$tableToTag{'source'}       = 'Isolation';
$tableToTag{'antigen'}      = 'Antigen';
$tableToTag{'humandoid'}    = 'Antibody_for_disease';
delete $tableToTag{'diseasepaper'};				# skip this, get separately for humandoid

my %ontologyIdToName;

my %tableToOntology;             # put stuff here if the postgres table doesn't match the deadObjects ontology name

my %pipeSplit;
$pipeSplit{"remark"}++;
$pipeSplit{"other_name"}++;

my %justTag;


1;

sub getAntibody {
  my ($flag) = shift;

#   &populateDeadObjects(); 

  if ( $flag eq 'all' ) { $result = $dbh->prepare( "SELECT * FROM ${datatype}_name; " ); }		# get all entries for type
    else { $result = $dbh->prepare( "SELECT * FROM ${datatype}_name WHERE ${datatype}_name = '$flag';" ); }	# get all entries for type of object intid
  $result->execute();	
  while (my @row = $result->fetchrow) { $theHash{object}{$row[0]} = $row[1]; $nameToIDs{object}{$row[1]}{$row[0]}++; $ids{$row[0]}++; }
  my $ids = ''; my $qualifier = '';
  if ($flag ne 'all') { $ids = join"','", sort keys %ids; $qualifier = "WHERE joinkey IN ('$ids')"; }

  # generic way to query postgres for all OA fields for the datatype, and store in arrays of html encoded entities
  foreach my $table (sort keys %{ $fields{$datatype} }) {
    next if ($table eq 'id');             # skip pgid column
  #   print qq(F $table F\n);
  #   $result = $dbh->prepare( "SELECT * FROM ${datatype}_$table WHERE ${datatype}_$table IS NOT NULL AND joinkey IN ('1', '2', '3');" );
#     $result = $dbh->prepare( "SELECT * FROM ${datatype}_$table WHERE ${datatype}_$table IS NOT NULL;" );
    $result = $dbh->prepare( "SELECT * FROM ${datatype}_$table $qualifier;" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
    while (my @row = $result->fetchrow) {
      next unless $row[1];
      if ($row[1] =~ m/\n/) { $row[1] =~ s/\n/ /g; }
      if ( ($fields{$datatype}{$table}{type} eq 'multiontology') || ($fields{$datatype}{$table}{type} eq 'multidropdown') ) {
        my ($data) = $row[1] =~ m/^\"(.*)\"$/;
        my (@data) = split/\",\"/, $data;
        foreach my $entry (@data) {
          $entry = &utf8ToHtml($simpleRemapHashRef, $entry);
          if ($entry) {
            push @{ $theHash{$table}{$row[0]} }, $entry; } }
      }
      elsif ($pipeSplit{$table}) {
        my (@data) = split/\|/, $row[1];
        foreach my $entry (@data) {
          $entry = &utf8ToHtml($simpleRemapHashRef, $entry);
          if ($entry) {
            push @{ $theHash{$table}{$row[0]} }, $entry; } }
      }
      else {
        my $entry = &utf8ToHtml($simpleRemapHashRef, $row[1]);
        if ($entry) {
          push @{ $theHash{$table}{$row[0]} }, $entry; }
      }
    } # while (my @row = $result->fetchrow)
  } # foreach my $table (sort keys %{ $fields{$datatype} })

  foreach my $name (sort keys %{ $nameToIDs{object} }) {
    my $entry = '';

    my %cur_entry;
    foreach my $joinkey (sort {$a<=>$b} keys %{ $nameToIDs{object}{$name} }) {
# print qq(J $joinkey J\n);
      next if ($theHash{nodump}{$joinkey});

      foreach my $field (sort keys %justTag) {
        foreach my $data (@{ $theHash{$field}{$joinkey} }) {
          $cur_entry{qq($data\n)}++; } }

      foreach my $field (sort keys %tableToTag) {
        foreach my $data (@{ $theHash{$field}{$joinkey} }) {
          $data =~ s/\n/ /g; $data =~ s/ +/ /g;     # daniela wants no linebreaks dumped, and multiple spaces converted to a single space 2011 02 09
          ($data) = &filterAce($data);
          if ($data) {
            my $ontology = $field;
            if ($tableToOntology{$field}) { $ontology = $tableToOntology{$field}; }
            my $isGood = 0;
            if ($deadObjects{$ontology}{$data}) {
                if ($field eq 'gene') {
                  if ($deadObjects{gene}{$data}{"split"}) {  # anything with a split gene is an error
                      $cur_entry{qq(Historical_gene\t"$data" "Note: This object originally referred to a gene ($data) that is now considered dead. Please interpret with discretion."\n)}++;
                      $err_text .= "$joinkey\tnodump\tThis pgid contains a gene that has been split $data in $field.\n"; }
                    elsif ($deadObjects{gene}{$data}{"mapto"}) {       # if gene maps to another gene, add the mapped version
                      my $mappedGene = $deadObjects{gene}{$data}{"mapto"};        # convert to new gene
                      $cur_entry{qq(Historical_gene  "$data"  "Note: This object originally referred to $data.  $data is now considered dead and has been merged into $mappedGene. $mappedGene has replaced $data accordingly."\n)}++;
                      if ($theHash{endogenous}{$joinkey}[0]) {                  # if endogenous toggle, also dump gene to endogenous .ace tag for Daniela 2014 03 19
                        $cur_entry{qq(Reflects_endogenous_expression_of\t"$mappedGene"\n)}++; }
                      $cur_entry{qq($tableToTag{$field}\t"$mappedGene" Inferred_automatically\n)}++; }
                    elsif ($deadObjects{gene}{$data}{"suppressed"}) {
                      $cur_entry{qq(Historical_gene\t"$data" "Note: This object originally referred to a gene ($data) that has been suppressed. Please interpret with discretion."\n)}++; }
                    elsif ($deadObjects{gene}{$data}{"dead"}) {
                      $cur_entry{qq(Historical_gene\t"$data" "Note: This object originally referred to a gene ($data) that is now considered dead. Please interpret with discretion."\n)}++; } }
                else {
                    $err_text .= "$name has dead $field $data $deadObjects{$ontology}{$data}\n"; } }
              elsif ($field eq 'humandoid') {
                foreach my $paper (@{ $theHash{'paper'}{$joinkey} }) {
                  $cur_entry{qq($tableToTag{$field}\t"$data"\tPaper_evidence\t"$paper"\n)}++; }
                $isGood = 1; }
              else { $isGood = 1; }
            if ($isGood) {
              if ($ontologyIdToName{$field}{$data}) { $data = $ontologyIdToName{$field}{$data}; }       # convert ontology ids to names.
              $cur_entry{qq($tableToTag{$field}\t"$data"\n)}++; } } } }

    } # foreach my $joinkey (sort {$a<=>$b} keys %{ $nameToIDs{$type}{$name} })

    foreach my $line (sort keys %cur_entry) { $entry .= $line; }
    if ($entry) {
       $all_entry .= qq(\nAntibody : "$name"\n);
       $all_entry .= $entry; }
  } # foreach my $name (sort keys %{ $nameToIDs{$type} })

  return( $all_entry, $err_text );
} # sub getAntibody


__END__
