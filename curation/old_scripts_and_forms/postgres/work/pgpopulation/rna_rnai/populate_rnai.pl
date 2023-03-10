#!/usr/bin/perl -w

# populate rna_ tables  and generate deletion script of data that was inserted (and method lines)   2012 03 29

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;
my @pgcommands;

my $write_deletion = 0; my $deletionFile = 'deletion.ace'; 
$write_deletion++;			# uncomment to write deletion file
if ($write_deletion) { open (OUT, ">$deletionFile") or die "Cannot create $deletionFile : $!"; }

my %rnaiToCurator;
my $infile = 'rnaiToCurator.txt';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) { chomp $line; my ($rnai, $curator) = split/\t/, $line; $rnaiToCurator{$rnai} = $curator; }
close (IN) or die "Cannot close $infile : $!";

my %validValues;
&populateValidPhenotypes();
&populateValidLaboratory();
&populateValidLifestage();
&populateValidPcrproduct();
&populateValidStrain();
&populateValidMolecule();
&populateValidPaper();
&populateValidSpecies();
&populateValidSequence();

my %multivalue;
$multivalue{'laboratory'}++;
$multivalue{'pcrproduct'}++;
$multivalue{'deliverymethod'}++;
$multivalue{'phenotype'}++;
$multivalue{'phenotypenot'}++;
$multivalue{'molecule'}++;
$multivalue{'person'}++;
# $multivalue{'sequence'}++;					# if populating sequence as multiontology

my %tags;
my %tagToTable;
$tagToTable{"Author"}                 = 'IGNORE';		# don't read to pg, don't write deletion .ace
$tagToTable{"Bacterial_feeding"}      = 'deliverymethod';	# value_is_tag
$tagToTable{"DNA_text"}               = 'dnatext';
$tagToTable{"Database"}               = 'database';
$tagToTable{"Date"}                   = 'date';
$tagToTable{"Evidence"}               = 'Evidence';
$tagToTable{"Expr_profile"}           = 'exprprofile';
$tagToTable{"Gene"}                   = 'IGNORE';
$tagToTable{"Gene_regulation"}        = 'IGNORE';
$tagToTable{"Genotype"}               = 'genotype';
$tagToTable{"History_name"}           = 'historyname';
$tagToTable{"Homol_homol"}            = 'IGNORE';
$tagToTable{"Injection"}              = 'deliverymethod';	# value_is_tag
$tagToTable{"Interaction"}            = 'IGNORE';
$tagToTable{"Laboratory"}             = 'laboratory';
$tagToTable{"Life_stage"}             = 'lifestage';
# $tagToTable{"Method"}                 = 'method';		# no longer want to populate method nor even have that table  2012 03 28
$tagToTable{"Method"}                 = 'NOPG';			# don't read to pg, do write deletion .ace
$tagToTable{"Movie"}                  = 'movie';
$tagToTable{"PCR_product"}            = 'pcrproduct';
$tagToTable{"Phenotype"}              = 'phenotype';		# subtags
$tagToTable{"Phenotype_not_observed"} = 'phenotype';
$tagToTable{"Predicted_gene"}         = 'IGNORE';
$tagToTable{"Reference"}              = 'paper';
$tagToTable{"Remark"}                 = 'remark';
$tagToTable{"Sequence"}               = 'sequence';
$tagToTable{"Soaking"}                = 'deliverymethod';	# value_is_tag
$tagToTable{"Species"}                = 'species';
$tagToTable{"Strain"}                 = 'strain';
$tagToTable{"Temperature"}            = 'temperature';
$tagToTable{"Transgene_expression"}   = 'deliverymethod';	# value_is_tag
$tagToTable{"Treatment"}              = 'treatment';
$tagToTable{"Uniquely_mapped"}        = 'IGNORE';

my %tableType;
$tableType{"DNA_text"}                = 'text_text';		#  'dnatext';
$tableType{"Database"}                = 'text_text_text';	#  'database';
$tableType{"Date"}                    = 'noquote';		#  'date';
$tableType{"Expr_profile"}            = 'text';			#  'exprprofile';
$tableType{"Genotype"}                = 'text';			#  'genotype';
$tableType{"History_name"}            = 'text';			#  'historyname';
$tableType{"Laboratory"}              = 'Laboratory';		#  'laboratory';
$tableType{"Life_stage"}              = 'Lifestage';		#  'lifestage';
$tableType{"Method"}                  = 'text';			#  'method';
$tableType{"Movie"}                   = 'text';			#  'movie';
$tableType{"PCR_product"}             = 'Pcrproduct';		#  'pcrproduct';
# $tableType{"Phenotype_not_observed"}  = 'Phenotype';		#  'phenotypenot';
$tableType{"Reference"}               = 'Paper';		#  'paper';
$tableType{"Remark"}                  = 'text';			#  'remark';
# $tableType{"Sequence"}                = 'Sequence';		#  'sequence';		# if we make ontology of all 2 million sequences, or to check all are valid
$tableType{"Sequence"}                = 'text';			#  'sequence';		# to leave as pipe text
$tableType{"Species"}                 = 'Species';		#  'species';
$tableType{"Strain"}                  = 'Strain';		#  'strain';
$tableType{"Temperature"}             = 'noquote';		#  'temperature';
$tableType{"Treatment"}               = 'text';			#  'treatment';


my %phenSubtags;
my %psubToTable;
$psubToTable{"Cold_sensitive"}        = 'coldsens';
$psubToTable{"Complete"}              = 'penetrance';	# value_is_tag
$psubToTable{"Curator_confirmed"}     = 'IGNORE';
$psubToTable{"Heat_sensitive"}        = 'heatsens';
$psubToTable{"High"}                  = 'penetrance';	# value_is_tag
$psubToTable{"Incomplete"}            = 'penetrance';	# value_is_tag
$psubToTable{"Low"}                   = 'penetrance';	# value_is_tag
$psubToTable{"Molecule"}              = 'molecule';
$psubToTable{"Not"}                   = 'phenotypenot';	# unless we can't ignore, then change table to phenotypenot only see it in WBRNAi00085012
$psubToTable{"Paper_evidence"}        = 'IGNORE';
$psubToTable{"Quantity"}              = 'quantfromto';
$psubToTable{"Quantity_description"}  = 'quantdesc';
$psubToTable{"Range"}                 = 'penfromto';
$psubToTable{"Remark"}                = 'phenremark';

my %data;
my $pgid = 0;


# $infile = 'WS231RNAi.ace';
$infile = 'final.ace';
$/ = "";
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $entry = <IN>) {
  chomp $entry;
  next unless ($entry =~ m/RNAi : \"(WBRNAi\d+)\"/);
  my $rnai = $1; my $curator = ''; if ($rnaiToCurator{$rnai}) { $curator = $rnaiToCurator{$rnai}; }
  my @lines = split/\n/, $entry;
  my $header = shift @lines;
  if ($write_deletion) { print OUT "$header\n"; }
  my %phenotypes;				# all phenotypes, delete phenotypes that have phen_info to get phenotypes that should have own OA row without phen_info
  my %phen_info;				# used to make keys for phenotype info to make new pgid for each group
  foreach my $line (@lines) {
    my ($tag, $rest);
    if ($line =~ m/^(\w+)\t(.*?)$/) { $tag = $1; $rest = $2; }
      else { print "BAD $rnai LINE $line\n"; }
    if ($rest) { $rest =~ s/\"//g; $rest =~ s/^\s+//; $rest =~ s/\s+$//; }
    my $table = '';
    if ($tagToTable{$tag}) { $table = $tagToTable{$tag}; } else { print "ERR unaccounted tag $tag in $rnai\n"; }
    next if ($table eq 'IGNORE');		# don't read to postgres, don't write to deletion file
    if ($write_deletion) { print OUT "-D $line\n"; }
    next if ($table eq 'NOPG');			# don't read to postgres, do write to deletion file
    if ($table eq 'Evidence') {
        if ($line =~ m/Person_evidence\s+\"(WBPerson\d+)\"/) { push @{ $data{$rnai}{'person'} }, $1; }
          else { print "ERR unaccounted RNAi Evidence in $rnai\t$line\n"; } }
      elsif ($table eq 'phenotype') {
        my $phen = '';
        if ($line =~ m/Phenotype(?:_not_observed)?\s+\"(WBPhenotype:\d+)\"/) {
            $phen = $1; my $subtag = ''; my $subdata = '';
            $phenotypes{$phen}++;					# track all phenotypes in the RNAi object
            if ($line =~ m/Phenotype_not_observed/) { $phen_info{$phen}{'phenotypenot'}{'NOT'}++; }	# if tag is not add to phenotypenot
            if ($line =~ m/Phenotype(?:_not_observed)?\s+\"WBPhenotype:\d+\" (\w+) \"(.*?)\"/) { $subtag = $1; $subdata = $2; }
              elsif ($line =~ m/Phenotype(?:_not_observed)?\s+\"WBPhenotype:\d+\" (\w+) ([\w ]*)/) { $subtag = $1; $subdata = $2; }
              elsif ($line =~ m/Phenotype(?:_not_observed)?\s+\"WBPhenotype:\d+\" (\w+)/) { $subtag = $1; }
#               else { print "Phenotype line without a subtag in $rnai : $line\n"; }	# 9497 lines have no subtags, this is correct
            next if ($subtag eq '');
            unless ($psubToTable{$subtag}) { print "ERR unaccounted subtag $subtag for Phenotype line in $rnai : $line\n"; next; }
            $table = $psubToTable{$subtag};
            next if ($table eq 'IGNORE');
            if ($table eq 'penetrance') { $subdata = $subtag; }
              elsif ($table eq 'coldsens') { $subdata = 'Cold Sensitive'; }
              elsif ($table eq 'heatsens') { $subdata = 'Heat Sensitive'; }
              elsif ($table eq 'phenotypenot') { $subdata = 'NOT'; }	# only one case of this WBRNAi00085012
            unless ($subdata) { print "ERR phenotype subtag $subtag has no data in line : $line\n"; }
            if ($table eq 'molecule') {
              my @array = (); push @array, $subdata;
              my $validValue = &validateArrayValues($rnai, 'Molecule', \@array);
              if ($validValue) { $subdata = $validValue; } }
# if ($rnai eq 'WBRNAi00065827') { print "PHEN $phen TABLE $table SUBTAG $subtag SUBDATA $subdata LINE $line END\n"; }
            $phen_info{$phen}{$table}{$subdata}++;			# phenotype info, for a given phenotype and postgres table, what data it has
#             $phenSubtags{$subtag}++;
          }
          else { print "ERR Phenotype line without a phenotype object $line\n"; }
      }
      elsif ($table eq 'deliverymethod') { my $data = $tag; push @{ $data{$rnai}{$table} }, $data; }
      elsif ($table eq 'phenotypenot') { 1; }			# TODO change this
      elsif ($tableType{$tag} eq 'noquote')        { 
        if ($rest =~ m/\"/) { print "ERR $rnai $tag has doublequote in $rest : $line\n"; }
        if ($rest) { push @{ $data{$rnai}{$table} }, $rest; }
      }
      elsif ($tableType{$tag} eq 'text_text_text') {
        if ($rest) { 
          my (@spaces) = $rest =~ m/ /g; if (scalar(@spaces) > 3) { print "ERR $rnai $tag has too many space : $line\n"; }
          push @{ $data{$rnai}{$table} }, $rest; } }
      elsif ($tableType{$tag} eq 'text_text')      {
        if ($rest) { 
          my (@spaces) = $rest =~ m/ /g; if (scalar(@spaces) > 2) { print "ERR $rnai $tag has too many space : $line\n"; }
          push @{ $data{$rnai}{$table} }, $rest; } }
      elsif ($tableType{$tag} eq 'text')           {
        if ($rest =~ m/\"/) { print "ERR $rnai $tag has doublequote in $rest : $line\n"; }
        if ($rest) { push @{ $data{$rnai}{$table} }, $rest; }
      }

      elsif ($tableType{$tag}) {					# there's a table type for a set of valid values
        my @array; push @array, $rest; 
#         next if ( ($tag eq 'PCR_product') || ($tag eq 'Life_stage') );
        my $validValue = &validateArrayValues($rnai, $tag, \@array);
        if ($validValue) { push @{ $data{$rnai}{$table} }, $validValue; }
      }

#       elsif ($tableType{$tag} eq 'Laboratory') { 1; }
      else { 
        print "ERR $rnai UNACCOUNTED TAG $tag BLAH $rest LINE $line\n";
#         my $data = $rest;
#         $data{$rnai}{$table} = $data; 
#         if ($rest =~ m/\"/) { print "$rnai\t$table\t$rest\t$line\n"; }
#         if ($rest) { print "$rnai\t$table\t$rest\t$line\n"; }
      }
#     $tags{$tag}++;
  } # foreach my $line (@lines)
  my %phen_lines;							# different oa lines for exact groups of #Phenotype_info subtags under Phenotype
  foreach my $phen (sort keys %phen_info) {
    delete $phenotypes{$phen};						# this phenotype accounted for in OA line that has #Phenotype_info
    my @key_phen;							# all the different subdata for #Phenotype_info subtags under Phenotype
    foreach my $table (sort keys %{ $phen_info{$phen} }) {
#       my $data = $phen_info{$phen}{$table}; 
      my $data; my (@data) = sort keys %{ $phen_info{$phen}{$table} };
      if ($multivalue{$table}) { $data = join',', @data; }
        else { $data = join' | ', @data; }
      my $pair = "${table}SPAIR\tEPAIR${data}";				# make pairs of pgtable-data.  odd divider because don't know what Remark holds
      push @key_phen, $pair;						# put all pairs in array of phenotype keys
    }
    my $key_phen = join"SDIV\tEDIV", @key_phen;				# make a phenotype key from the array of data pairs
# if ($rnai eq 'WBRNAi00007616') { print "KEYPHEN $key_phen END\n"; }
# if ($rnai eq 'WBRNAi00065827') { print "$rnai PHEN $phen KEYPHEN $key_phen END\n"; }
    $phen_lines{$key_phen}{$phen}++;					# add each phenotype that corresponds to that key
  }
  my @no_phen_info_phenotypes = sort keys %phenotypes;
  my $phens = &validateArrayValues($rnai, 'Phenotype', \@no_phen_info_phenotypes);
#   my $phens = join", ", @no_phen_info_phenotypes;
  if ($phens) {								# phenotypes without #Phentoype_info
    $pgid++;
    &addToPg($rnai, $pgid, 'name', $rnai);
    &addToPg($rnai, $pgid, 'curator', $curator);
    &addToPg($rnai, $pgid, 'phenotype', $phens);
    &addNonphenotypeToLine($rnai, $pgid);
  }
  foreach my $key_phen (sort keys %phen_lines) {			# make a new OA line
    # TODO make a new pgid here 					
# sample of multiple key_phen : WBRNAi00005004 WBRNAi00007225 WBRNAi00007216 WBRNAi00007536
    $pgid++;
    my (@phens) = sort keys %{ $phen_lines{$key_phen} };
    my $phens = &validateArrayValues($rnai, 'Phenotype', \@phens);
#     my $phens = join", ", @phens;
    &addToPg($rnai, $pgid, 'name', $rnai);
    &addToPg($rnai, $pgid, 'curator', $curator);
    &addToPg($rnai, $pgid, 'phenotype', $phens);
    &addNonphenotypeToLine($rnai, $pgid);
    my (@pairs) = split/SDIV\tEDIV/, $key_phen;
    foreach my $pair (@pairs) {
      my ($table, $data) = $pair =~ m/^(.*?)SPAIR\tEPAIR(.*?)$/;
      &addToPg($rnai, $pgid, $table, $data);
    } # foreach my $pair (@pairs)
  } # foreach my $key_phen (sort keys %phen_lines)

  if ($write_deletion) { print OUT "\n"; }
} # while (my $entry = <IN>)
close (IN) or die "Cannot close $infile : $!";
$/ = "\n";

# print "WBRNAi00005004 WBRNAi00007225 WBRNAi00007216 WBRNAi00007536\n";


foreach my $pgcommand (@pgcommands) {
#   print "$pgcommand\n";
# UNCOMMENT TO populate
#   $result = $dbh->do( $pgcommand );
} # foreach my $pgcommand (@pgcommands)

sub addNonphenotypeToLine {
  my ($rnai, $pgid) = @_;
  foreach my $table (sort keys %{ $data{$rnai} }) {
    my $data = '';
    if ($multivalue{$table}) { $data = join',', @{ $data{$rnai}{$table} }; }
      else { $data = join' | ', @{ $data{$rnai}{$table} }; }
    &addToPg($rnai, $pgid, $table, $data);
  }   
#         if ($rest) { push @{ $data{$rnai}{$table} }, $rest; }
} # sub addNonphenotypeToLine

sub addToPg {
  my ($rnai, $pgid, $table, $data) = @_;
  return unless $data;
  if ($data =~ m/\'/) { $data =~ s/\'/''/g; }
  if ($data =~ m/\\/) { $data =~ s/\\//g; }
#   print "$rnai\t$pgid\t$table\t$data\n";

  push @pgcommands, "INSERT INTO rna_$table VALUES ('$pgid', '$data');";
  push @pgcommands, "INSERT INTO rna_${table}_hst VALUES ('$pgid', '$data');";
} # sub addToPg

sub validateArrayValues {
  my ($rnai, $tag, $arrayref) = @_;
  my @array = @$arrayref;
  my %values;
  my $table;
  if ($tagToTable{$tag})  { $table = $tagToTable{$tag}; }
  if ($psubToTable{$tag}) { $table = $psubToTable{$tag}; }

  foreach my $value (@array) {
    if ($validValues{$tag}{$value}) { $values{$validValues{$tag}{$value}}++; }
      else { print "ERR INVALID $rnai $tag -=${value}=-\n"; }			# UNCOMMENT to see invalid values
  } # foreach my $value (@array)
  my @values = sort keys %values; my $values = '';
  if ($multivalue{$table}) { 
      $values = join'","', @values;
      if ($values) { $values = '"' . $values . '"'; } }
    else { 
      if (scalar @values > 1) { print "ERR Too many values for controlled vocabulary only allowing single value  $rnai $tag @values\n"; }
      else { $values = $values[0]; } }
  return $values;
} # sub validateArrayValues

foreach my $tag (sort keys %phenSubtags) {
  unless ($psubToTable{$tag}) {
    print "ERR subtag has no psubToTable $tag\n";
  }
}
# foreach my $tag (sort keys %tags) {
#   unless ($tagToTable{$tag}) {
#     print "ERR tag has no tagToTable $tag\n";
#   }
# }

sub populateValidPhenotypes {
  $result = $dbh->prepare( "SELECT * FROM obo_name_phenotype" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { if ($row[0]) { $validValues{Phenotype}{$row[0]} = $row[0]; } } }

sub populateValidLaboratory {
  $result = $dbh->prepare( "SELECT * FROM obo_name_laboratory" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { if ($row[0]) { $validValues{Laboratory}{$row[0]} = $row[0]; } } }

sub populateValidLifestage {
  $validValues{Life_stage}{"oocyte"}         = 'WBls:0000057';	# 'adult hermaphrodite';
  $validValues{Life_stage}{"Dauer"}          = 'WBls:0000032';	# 'dauer larva';
  $validValues{Life_stage}{"L3 larvae"}      = 'WBls:0000035';	# 'L3 larva';
  $validValues{Life_stage}{"young adult"}    = 'WBls:0000063';	# 'newly molted young adult hermaphrodite';
  $validValues{Life_stage}{"Mixed stages"}   = 'WBls:0000002';	# 'all stages';
  $validValues{Life_stage}{"L4-young adult"} = 'WBls:0000038';	# 'L4 larva';
  $result = $dbh->prepare( "SELECT * FROM obo_name_lifestage" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { if ($row[0]) { $validValues{Life_stage}{$row[1]} = $row[0]; } } }

sub populateValidPcrproduct {
  $result = $dbh->prepare( "SELECT * FROM obo_name_pcrproduct" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { if ($row[0]) { 
    my $changed_last_pcrprod = $row[0]; $validValues{PCR_product}{$changed_last_pcrprod} = $row[0]; 	# add values without a dot straight
    if ($row[0] =~ m/^(.*?)\.(.*?)$/) { 								# if the value has a dot enter the value with letters both up and low cased
      my $front = $1; my $back = $2; 
      $back = lc($back); $changed_last_pcrprod = "${front}.${back}"; 
      $validValues{PCR_product}{$changed_last_pcrprod} = $row[0];
      $back = uc($back); $changed_last_pcrprod = "${front}.${back}"; 
      $validValues{PCR_product}{$changed_last_pcrprod} = $row[0]; } } } }

sub populateValidStrain {
  $result = $dbh->prepare( "SELECT * FROM obo_name_strain" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { if ($row[0]) { $validValues{Strain}{$row[0]} = $row[0]; } } }

sub populateValidSequence {
  my $infile = 'WS230_Sequence_objects.txt';
  open (IN, "<$infile") or die "Cannot open $infile : $!";
  while (my $term = <IN>) { chomp $term; $term =~ s/^\"//; $term =~ s/\"$//;  $validValues{Sequence}{$term} = $term; }
  close (IN) or die "Cannot close $infile : $!";
  $result = $dbh->prepare( "SELECT * FROM gin_sequence" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { if ($row[1]) { $validValues{Sequence}{$row[1]} = $row[1]; } } }

sub populateValidMolecule {
#   $validValues{Molecule}{"WBMol:00005097"} = 'D005467';
  $validValues{Molecule}{"WBMol:00005097"} = '3778';		# lowest of two pgid that correspond to D005467
  $result = $dbh->prepare( "SELECT * FROM mop_molecule ORDER BY mop_timestamp DESC;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { if ($row[0]) { $validValues{Molecule}{"$row[1]"} = "$row[0]"; } } }

sub populateValidPaper {
  $validValues{Reference}{WBPaper00013501} = 'WBPaper00024307';
  $validValues{Reference}{WBpaper00028447} = 'WBPaper00028447';
  $result = $dbh->prepare( "SELECT * FROM pap_status WHERE pap_status = 'valid'" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { if ($row[0]) { $validValues{Reference}{"WBPaper$row[0]"} = "WBPaper$row[0]"; } } }

sub populateValidSpecies {
  $validValues{Species}{"Caenorhabditis elegans"}  = "Caenorhabditis_elegans";
  $validValues{Species}{"Caenorhabditis_sp._3"}    = "Caenorhabditis_sp._3";
  $validValues{Species}{"Panagrellus_redivivus"}   = "Panagrellus_redivivus";
  $validValues{Species}{"Cruznema_tripartitum"}    = "Cruznema_tripartitum";
  $validValues{Species}{"Caenorhabditis_brenneri"} = "Caenorhabditis_brenneri";
  $validValues{Species}{"Caenorhabditis_japonica"} = "Caenorhabditis_japonica";
  $validValues{Species}{"Caenorhabditis_briggsae"} = "Caenorhabditis_briggsae";
  $validValues{Species}{"Caenorhabditis_remanei"}  = "Caenorhabditis_remanei";
  $validValues{Species}{"Pristionchus_pacificus"}  = "Pristionchus_pacificus"; }


if ($write_deletion) { close (OUT) or die "Cannot close $deletionFile : $!"; }

__END__

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

