package get_allele_phenotype_phenote_ace;
require Exporter;

# use this package so that both : the dumping script for .ace uploads and
# find_diff.pl ;  and the wpa_editor.cgi  can use this to dump, or create a
# preview page respectively.  2005 07 13
#
# check the validity of a paper
#
# Add an option to get all data as well as just valid data.  When getting
# valid data then, check that the wpa is valid.
# dump Remark data as well.  2005 11 10

# Adapted for Allele Phenotype data.  2005 12 16
#
# Changed form to input terms as  WBPhenotypeID (phenotype term), so
# should always grab the WBPhenotypeID from the table.  2005 12 22

# Changed .ace output ``Remark'' from Quantity Remark to
# ``Quantity_description''  
# Added alp_phen_remark table to dump ``Remark'' .ace output.  2006 04 24

# Always display Phenotype data (with evidence)
# Always display data that has timestamps (without also showing evidence)
# If data has timestamps (acedb) , show it only with evidence that has timestamps
# If data has no timestamps, show it only with evidence that has no timestamps.
# For Carol  2006 05 12

# Also allow Condition and Phenotype_assay to be dumped if there's a Person evidence 
# for Carol 2006 07 27

# Added Laboratory_evidence only for Remark.  2008 03 04

# Exclude alleles that have not been approved by Mary Ann in the new_objects.cgi
# (using the same code to generate that list).  2008 07 17
#
# Changed for Strains to a different file.  2008 08 01
#
# Strip leading and trailing spaces in &getAppData().  2008 08 29
#
# Changed Pg.pm to DBI.pm  2009 04 23
#
# Added Species tag.  No sample from Jolene, so I don't know if it's right.  2010 02 11
#
# Species for Strain too.  2010 03 17
#
# Map Variation objects to WBVarIDs for Jolene / Mary Ann.  2010 05 12
#
# No longer need to map variation names to WBVarIDs since postgres app_tempname stores them
# directly.  2010 06 14
#
# Changed  &getLabEvidence()  since labs are now multiontology and have "," separated values.
# papers now in pap tables, not wpa  2010 08 25
#
# Rewritten for 4 tables (app_strain, app_rearrangement, app_transgene, app_variation) instead
# of app_type + app_tempname. 
# Rewritten to dump into a single file instead of a strain file and a variation + transgene file.
# Rerwitten to dump all of the same object in one group, instead of grouping by pgid (Wen's
# preference)
# Rewritten so that it queries to find joinkeys, then queries all tables instead of object by
# object, so instead of taking >900 seconds, it takes 8 seconds.  And still takes 1 second for
# querying a single object.  2010 09 08
#
# check that a given pgid doesn't have multiple names (it would dump out as multiple objects)
# don't dump .ace object if there's no phenotype.  this used to work before when dumping objects
# by pgid, but now that they're all balled into a single object dump, it was always printing
# the header.  2010 09 10
#
# Changed the code to have a $main_tag be Phenotype tag be default and to become 
# Phenotype_not_observed for all .ace entries of a given pgid.  2010 10 21
#
# Dump Molecule by getting pgid-Molecule from mop_molecule.  2011 05 17
#
# Getting dropdowns from postgres obo_ tables and hardcoded dropdown values.
# Added a Molecule dumper and now exporting phenotype + molecule + errors.
# Don't print Lab evidence unless there is lab evidence.  2011 05 27
#
# rescued_by shouldn't add evidence.
# molecule WBMolIDs now in mop_name instead of mop_molecule.  2012 10 22
#
# added %deadObjects check for dead genes and invalid papers to go to err_text.  2013 10 24
#
# replaced app_curation_status with app_nodump  2015 05 12
#
# replaced app_anat_term with app_anatomy to generalize entity-quality stuff.  2015 09 22
#
# added entity-quality stuff for six fields.  2015 09 23
#
# added picture and controlstrain  2016 10 24
#
# added parentstrain  2017 01 30
#
# Karen doesn't want app_strain dumped into phenotype_info (still dumped as the main object header) 
# No longer dumping app_strain into phenotype_info.  2017 02 24
#
# Added control vocabulary for parentstrain.  2017 02 28
#
# Added paper to community curator output.  2020 01 27



our @ISA	= qw(Exporter);
our @EXPORT	= qw(getAllelePhenotype );
our $VERSION	= 1.00;



use strict;
use diagnostics;
# use Pg;
use DBI;
# use LWP;
# use LWP::Simple;

use Dotenv -load => '/usr/lib/.env';


my $dbh = DBI->connect ( "dbi:Pg:dbname=$ENV{PSQL_DATABASE};host=$ENV{PSQL_HOST};port=$ENV{PSQL_PORT}", "$ENV{PSQL_USERNAME}", "$ENV{PSQL_PASSWORD}") or die "Cannot connect to database!\n";
# my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my $result;

my %theHash;
# my @tables = qw( laboratory curator person paper nbp term not phen_remark nature penetrance percent range_start range_end mat_effect pat_effect heat_sens heat_degree cold_sens cold_degree func haplo genotype lifestage anatomy caused_by caused_by_other temperature strain treatment species molecule rescuedby legacyinfo easescore mmateff hmateff );
my @tables = qw( laboratory communitycurator curator person paper nbp term not phen_remark nature penetrance percent range_start range_end mat_effect pat_effect heat_sens heat_degree cold_sens cold_degree func haplo genotype goprocess goprocessquality gofunction gofunctionquality gocomponent gocomponentquality molaffected molaffectedquality lifestage lifestagequality anatomy anatomyquality caused_by caused_by_other temperature strain picture parentstrain controlstrain treatment molecule rescuedby legacyinfo easescore mmateff hmateff );	

my $all_entry = '';
my $allmolecule_entry = '';
my $alllegacy_entry = '';
my $err_text = '';

my %deadObjects;

my %existing_evidence;				# existing wbpersons and wbpapers
&populateExistingEvidence();

my %dropdown;
&populateDropdown();

my %nameToIDs;							# type -> name -> ids -> count
my %ids;

my %paperCommunity;


sub getAllelePhenotype {
  my ($flag) = shift;
# takes 907 seconds to dump all one by one instead of global read

  &populateDeadObjects();

  my @types = qw( strain rearrangement transgene variation );		# rearrangements are back 2011 05 26
#   my @types = qw( strain transgene variation );			# no rearrangements
  foreach my $type (@types) {
#     if ( $flag eq 'all' ) { $result = $dbh->prepare( "SELECT * FROM app_$type WHERE joinkey NOT IN (SELECT joinkey FROM app_curation_status WHERE app_curation_status = 'down_right_disgusted');" ); }			# get all entries for type
#       else { $result = $dbh->prepare( "SELECT * FROM app_$type WHERE app_$type = '$flag' AND joinkey NOT IN (SELECT joinkey FROM app_curation_status WHERE app_curation_status = 'down_right_disgusted');" ); }	# get all entries for type of object name
    if ( $flag eq 'all' ) { $result = $dbh->prepare( "SELECT * FROM app_$type WHERE joinkey NOT IN (SELECT joinkey FROM app_nodump WHERE app_nodump = 'NO DUMP');" ); }			# get all entries for type
      else { $result = $dbh->prepare( "SELECT * FROM app_$type WHERE app_$type = '$flag' AND joinkey NOT IN (SELECT joinkey FROM app_nodump WHERE app_nodump = 'NO DUMP');" ); }	# get all entries for type of object name
    $result->execute();	
    while (my @row = $result->fetchrow) { $theHash{$type}{$row[0]} = $row[1]; $nameToIDs{$type}{$row[1]}{$row[0]}++; $ids{$row[0]}++; } }
  my $ids = ''; my $qualifier = '';
  if ($flag ne 'all') { $ids = join"','", sort keys %ids; $qualifier = "WHERE joinkey IN ('$ids')"; }
  foreach my $table (@tables) {
    $result = $dbh->prepare( "SELECT * FROM app_$table $qualifier;" );		# get data for table with qualifier (or not if not)
    $result->execute();	
    while (my @row = $result->fetchrow) { $theHash{$table}{$row[0]} = $row[1]; }
  } # foreach my $table (@tables)

  my @names = qw( strain rearrangement transgene variation );	# check that a given pgid doesn't have multiple names  2010 09 10
  foreach my $pgid (sort keys %{ $theHash{term} }) {
    my @types;
    foreach my $name (@names) {
      if ($theHash{$name}{$pgid}) { push @types, $name; } }
    if (scalar(@types) > 1) { my $types = join", ", @types; $err_text .= "$pgid has $types\n"; } }

  foreach my $type (@types) {
    foreach my $name (sort keys %{ $nameToIDs{$type} }) {
      my $entry = '';
      my $otype = ucfirst($type); 
      $entry .= "$otype : \"$name\"\n";				# added pgid for debugging  2010 08 25

      foreach my $joinkey (sort {$a<=>$b} keys %{ $nameToIDs{$type}{$name} }) {
        my $evidence = ''; ($evidence) = &getEvidence($joinkey);	# get the evidence multi-line for the joinkey and box
        my $lab_evidence = ''; ($lab_evidence) = &getLabEvidence($joinkey);	# get the evidence multi-line for the joinkey and box

        my $cur_entry = '';
        my $table = 'nbp'; my $data = &getAppData($table, $joinkey);
#         if ($data) { $cur_entry .= &addEvi($evidence, "Phenotype_remark\t\"$data\""); }
#       Don't dump Phenotype_remark anymore  for Karen  2008 02 06
        $table = 'term'; my $phenotype = &getAppData($table, $joinkey);
        if ($phenotype) {
          my $main_tag = 'Phenotype';
          $table = 'not'; $data = &getAppData($table, $joinkey);
          if ($data) { $main_tag = 'Phenotype_not_observed'; }	# replace 2010 10 21  have a main tag be Phenotype, unless there's not, in which case it becomes Phenotype_not_observed
#           if ($data) { $cur_entry .= &addEvi($evidence, "$main_tag\t\"$phenotype\"\tNOT"); }	# replace 2010 10 12, don't think it's correct, but up to Karen
#           if ($data) { $cur_entry .= &addEvi($evidence, "Phenotype_not_observed\t\"$phenotype\""); }
#           if ( ($type eq 'variation') || ($type eq 'strain') ) {		# for Variation and Strain  2010 03 17	Karen doesn't want it 2012 12 19
#             $table = 'species'; $data = &getAppData($table, $joinkey);		# get species
#             if ($data) { $cur_entry .= "Species\t\"$data\"\t// pgid $joinkey\n"; }			# if there is, write it
#               else { $cur_entry .= "Species\t\"Caenorhabditis_elegans\"\t// pgid $joinkey\n"; } }	# if there isn't, default
          $cur_entry .= &addEvi($evidence, "$main_tag\t\"$phenotype\""); 	# print the phenotype tag with its evidences
          $table = 'phen_remark'; $data = &getAppData($table, $joinkey);
          if ($data) { 
            if ($lab_evidence) { $cur_entry .= &addEvi($lab_evidence, "$main_tag\t\"$phenotype\"\tRemark\t\"$data\""); }
            $cur_entry .= &addEvi($evidence, "$main_tag\t\"$phenotype\"\tRemark\t\"$data\""); }
          $table = 'nature'; $data = &getAppData($table, $joinkey);
          if ($data) { $cur_entry .= &addEvi($evidence, "$main_tag\t\"$phenotype\"\t\"$data\""); }
          $table = 'penetrance'; my $penetrance = &getAppData($table, $joinkey);
          $table = 'percent'; my $percent = '';  $percent = &getAppData($table, $joinkey); unless ($percent) { $percent = ''; }
          if ($penetrance) { $cur_entry .= &addEvi($evidence, "$main_tag\t\"$phenotype\"\tPenetrance\t$penetrance \"$percent\""); }
#       check for complete penetrance ?
          $table = 'range_start'; my $range_start = &getAppData($table, $joinkey);
          $table = 'range_end'; my $range_end = &getAppData($table, $joinkey);
          if ($range_start) { $cur_entry .= &addEvi($evidence, "$main_tag\t\"$phenotype\"\tRange\t\"$range_start\" \"$range_end\""); }
          $table = 'mat_effect'; $data = &getAppData($table, $joinkey);
          if ($data) { $cur_entry .= &addEvi($evidence, "$main_tag\t\"$phenotype\"\t\"$data\""); }
          $table = 'pat_effect'; $data = &getAppData($table, $joinkey);
          if ($data) { $cur_entry .= &addEvi($evidence, "$main_tag\t\"$phenotype\"\tPaternal"); }
          $table = 'heat_sens'; my $heat_sens = &getAppData($table, $joinkey);
          $table = 'heat_degree'; my $heat_degree = &getAppData($table, $joinkey); unless ($heat_degree) { $heat_degree = ''; }
          if ($heat_sens) { $cur_entry .= &addEvi($evidence, "$main_tag\t\"$phenotype\"\tHeat_sensitive\t\"$heat_degree\""); }
          $table = 'cold_sens'; my $cold_sens = &getAppData($table, $joinkey);
          $table = 'cold_degree'; my $cold_degree = &getAppData($table, $joinkey); unless ($cold_degree) { $cold_degree = ''; }
          if ($cold_sens) { $cur_entry .= &addEvi($evidence, "$main_tag\t\"$phenotype\"\tCold_sensitive\t\"$cold_degree\""); }
          $table = 'func'; $data = &getAppData($table, $joinkey); unless ($phenotype) { $phenotype = 'ERR no phenotype'; }
          if ($data) { $cur_entry .= &addEvi($evidence, "$main_tag\t\"$phenotype\"\t\"$data\""); }
          $table = 'haplo'; $data = &getAppData($table, $joinkey);
          if ($data) { $cur_entry .= &addEvi($evidence, "$main_tag\t\"$phenotype\"\tHaplo_insufficient"); }
          $table = 'genotype'; $data = &getAppData($table, $joinkey);
          if ($data) { $cur_entry .= &addEvi($evidence, "$main_tag\t\"$phenotype\"\tGenotype\t\"$data\""); }
          $table = 'rescuedby'; $data = &getAppData($table, $joinkey);
          if ($data) { my @data; if ($data =~ m/\t/) { @data = split/\t/, $data; } else { push @data, $data; }
            foreach my $data (@data) { 
#               $cur_entry .= &addEvi($evidence, "$main_tag\t\"$phenotype\"\tRescued_by_transgene\t\"$data\""); 	# no evidence, says Karen 2012 10 22
              $cur_entry .= "$main_tag\t\"$phenotype\"\tRescued_by_transgene\t\"$data\"\t// pgid $joinkey\n"; } }
          $table = 'easescore'; $data = &getAppData($table, $joinkey);
          if ($data) { my @data; if ($data =~ m/\t/) { @data = split/\t/, $data; } else { push @data, $data; }
            foreach my $data (@data) { $cur_entry .= &addEvi($evidence, "$main_tag\t\"$phenotype\"\tEase_of_scoring\t\"$data\""); } }
          $table = 'caused_by'; $data = &getAppData($table, $joinkey);
          if ($data) { my @data; if ($data =~ m/\t/) { @data = split/\t/, $data; } else { push @data, $data; }
            foreach my $data (@data) { 
              if ($data) { if ($deadObjects{gene}{$data}) { $err_text .= "pgid $joinkey has gin_dead $deadObjects{gene}{$data}\n"; } }
              $cur_entry .= &addEvi($evidence, "$main_tag\t\"$phenotype\"\tCaused_by_gene\t\"$data\""); } }
          $table = 'caused_by_other'; $data = &getAppData($table, $joinkey);
          if ($data) { my @data; if ($data =~ m/\t/) { @data = split/\t/, $data; } else { push @data, $data; }
            foreach my $data (@data) { $cur_entry .= &addEvi($evidence, "$main_tag\t\"$phenotype\"\tCaused_by_other\t\"$data\""); } }
          $table = 'temperature'; $data = &getAppData($table, $joinkey);
          if ($data) { $cur_entry .= &addEvi($evidence, "$main_tag\t\"$phenotype\"\tTemperature\t\"$data\""); }
#           $table = 'strain'; $data = &getAppData($table, $joinkey);		# Karen possibly doesn't want this, she's not being clear.  2017 02 24
#           if ($data) { $cur_entry .= &addEvi($evidence, "$main_tag\t\"$phenotype\"\tStrain\t\"$data\""); }
	    # fields with associated quality have paired data that must enter something in second field before evidence hash
          $table = 'picture'; $data = &getAppData($table, $joinkey);
          if ($data) { $cur_entry .= &addEvi($evidence, "$main_tag\t\"$phenotype\"\tImage\t\"$data\""); }
          $table = 'controlstrain'; $data = &getAppData($table, $joinkey);
          if ($data) { $cur_entry .= &addEvi($evidence, "$main_tag\t\"$phenotype\"\tControl_strain\t\"$data\""); }
          $table = 'parentstrain'; $data = &getAppData($table, $joinkey);
          if ($data) { $cur_entry .= &addEvi($evidence, "$main_tag\t\"$phenotype\"\tStrain\t\"$data\""); }
          $table = 'goprocess'; $data = &getAppData($table, $joinkey);	
          if ($data) { my @data; 
            if ($data =~ m/\t/) { @data = split/\t/, $data; } else { push @data, $data; }
            my $table2 = 'goprocessquality'; my $data2 = &getAppData($table2, $joinkey); my @data2;
            if ($data2) { if ($data2 =~ m/\t/) { @data2 = split/\t/, $data2; } else { push @data2, $data2; } } else { push @data2, "PATO:0000460" }
            foreach my $data (@data) { 
              foreach my $data2 (@data2) {
                $cur_entry .= &addEvi($evidence, "$main_tag\t\"$phenotype\"\tGO_term\t\"$data\"\t\"$data2\""); } } }
          $table = 'gofunction'; $data = &getAppData($table, $joinkey);
          if ($data) { my @data; 
            if ($data =~ m/\t/) { @data = split/\t/, $data; } else { push @data, $data; }
            my $table2 = 'gofunctionquality'; my $data2 = &getAppData($table2, $joinkey); my @data2;
            if ($data2) { if ($data2 =~ m/\t/) { @data2 = split/\t/, $data2; } else { push @data2, $data2; } } else { push @data2, "PATO:0000460" }
            foreach my $data (@data) { 
              foreach my $data2 (@data2) {
                $cur_entry .= &addEvi($evidence, "$main_tag\t\"$phenotype\"\tGO_term\t\"$data\"\t\"$data2\""); } } }
          $table = 'gocomponent'; $data = &getAppData($table, $joinkey);
          if ($data) { my @data; 
            if ($data =~ m/\t/) { @data = split/\t/, $data; } else { push @data, $data; }
            my $table2 = 'gocomponentquality'; my $data2 = &getAppData($table2, $joinkey); my @data2;
            if ($data2) { if ($data2 =~ m/\t/) { @data2 = split/\t/, $data2; } else { push @data2, $data2; } } else { push @data2, "PATO:0000460" }
            foreach my $data (@data) { 
              foreach my $data2 (@data2) {
                $cur_entry .= &addEvi($evidence, "$main_tag\t\"$phenotype\"\tGO_term\t\"$data\"\t\"$data2\""); } } }
          $table = 'molaffected'; $data = &getAppData($table, $joinkey);
          if ($data) { my @data; 
            if ($data =~ m/\t/) { @data = split/\t/, $data; } else { push @data, $data; }
            my $table2 = 'molaffectedquality'; my $data2 = &getAppData($table2, $joinkey); my @data2;
            if ($data2) { if ($data2 =~ m/\t/) { @data2 = split/\t/, $data2; } else { push @data2, $data2; } } else { push @data2, "PATO:0000460" }
            foreach my $data (@data) { 
              foreach my $data2 (@data2) {
                $cur_entry .= &addEvi($evidence, "$main_tag\t\"$phenotype\"\tMolecule_affected\t\"$data\"\t\"$data2\""); } } }
          $table = 'lifestage'; $data = &getAppData($table, $joinkey);
          if ($data) { my @data; 
            if ($data =~ m/\t/) { @data = split/\t/, $data; } else { push @data, $data; }
            my $table2 = 'lifestagequality'; my $data2 = &getAppData($table2, $joinkey); my @data2;
            if ($data2) { if ($data2 =~ m/\t/) { @data2 = split/\t/, $data2; } else { push @data2, $data2; } } else { push @data2, "PATO:0000460" }
            foreach my $data (@data) { 
#               $cur_entry .= &addEvi($evidence, "$main_tag\t\"$phenotype\"\tLife_stage\t\"$data\"");
              foreach my $data2 (@data2) {
                $cur_entry .= &addEvi($evidence, "$main_tag\t\"$phenotype\"\tLife_stage\t\"$data\"\t\"$data2\""); } } }
          $table = 'anatomy'; $data = &getAppData($table, $joinkey);
          if ($data) { my @data; 
            if ($data =~ m/\t/) { @data = split/\t/, $data; } else { push @data, $data; }
            my $table2 = 'anatomyquality'; my $data2 = &getAppData($table2, $joinkey); my @data2;
            if ($data2) { if ($data2 =~ m/\t/) { @data2 = split/\t/, $data2; } else { push @data2, $data2; } } else { push @data2, "PATO:0000460" }
            foreach my $data (@data) { 
              foreach my $data2 (@data2) {
                $cur_entry .= &addEvi($evidence, "$main_tag\t\"$phenotype\"\tAnatomy_term\t\"$data\"\t\"$data2\""); } } }
          $table = 'molecule'; $data = &getAppData($table, $joinkey);
          if ($data) { $data =~ s/^\\\"//; $data =~ s/\\\"$//; my @data; if ($data =~ m/\\\",\\\"/) { @data = split/\\\",\\\"/, $data; } else { push @data, $data; }
            foreach my $data (@data) { 
              next unless $dropdown{molecule}{$data}; $data = $dropdown{molecule}{$data}; 
              $allmolecule_entry .= "Molecule : \"$data\"// pgid $joinkey\n";
              if ($lab_evidence) { $allmolecule_entry .= &addEvi($lab_evidence, "$otype\t\"$name\"\t\"$phenotype\""); }
              $allmolecule_entry .= &addEvi($evidence, "$otype\t\"$name\"\t\"$phenotype\"");
              $allmolecule_entry .= "\n";
              $cur_entry .= &addEvi($evidence, "$main_tag\t\"$phenotype\"\tMolecule\t\"$data\""); } }
#           $table = 'preparation'; $data = &getAppData($table, $joinkey);	# not in .ace model ?  2008 02 08
#           if ($data) { $cur_entry .= &addEvi($evidence, "$main_tag\t\"$phenotype\"\tPreparation\t\"$data\""); }
          $table = 'treatment'; $data = &getAppData($table, $joinkey);
          if ($data) { $cur_entry .= &addEvi($evidence, "$main_tag\t\"$phenotype\"\tTreatment\t\"$data\""); }
#           if ($header =~ m/Variation/) { # }						# for Variation only  2010 02 11
        } # if ($phenotype)
        $table = 'mmateff'; $data = &getAppData($table, $joinkey);
        if ($data) { my @data; if ($data =~ m/\t/) { @data = split/\t/, $data; } else { push @data, $data; }
          foreach my $data (@data) { $cur_entry .= &addEvi($evidence, "Male\t\"$data\""); } }
        $table = 'hmateff'; $data = &getAppData($table, $joinkey);
        if ($data) { my @data; if ($data =~ m/\t/) { @data = split/\t/, $data; } else { push @data, $data; }
          foreach my $data (@data) { $cur_entry .= &addEvi($evidence, "Hermaphrodite\t\"$data\""); } }
        $table = 'legacyinfo'; $data = &getAppData($table, $joinkey);
        if ($data) {
          if ($data =~ m/^(WBGene\d+) \| (.*)$/) {
            my ($gene, $info) = $data =~ m/^(WBGene\d+) \| (.*)$/;
            $alllegacy_entry .= "Gene : \"$gene\"\nLegacy_information\t\"$info\"\n\n"; } }

        if ($cur_entry) { $entry .= $cur_entry; }		# create the ace entry
      } # foreach my $joinkey (sort {$a<=>$b} keys %{ $nameToIDs{$type}{$name} })
      if ($entry =~ m/Phenotype/) { $all_entry .= "$entry\n"; }                  # if .ace object has a phenotype, append to whole list
    } # foreach my $name (sort keys %{ $nameToIDs{$type} })
  } # foreach my $type (@types)

  if ($alllegacy_entry) { $all_entry .= "\n$alllegacy_entry"; }

  foreach my $paper (sort keys %paperCommunity) { 
    foreach my $curator (sort keys %{ $paperCommunity{$paper} }) {
      $all_entry .= qq(Paper : "$paper"\nCommunity_curation\tPhenotype_curation_by\t"$curator"\n\n); } }

  return( $all_entry, $allmolecule_entry, $err_text );
} # sub getAllelePhenotype


sub getAppData {
  my ($table, $joinkey) = @_;
  my $data = '';
  if ($theHash{$table}{$joinkey}) {
    $data = $theHash{$table}{$joinkey};
#     if ( ($table eq 'nature') || ($table eq 'penetrance') || ($table eq 'func') ) {	# changed dropdown arbitrary IDs to just the values 2011 05 27
#         if ( $dropdown{$table}{$data} ) { $data = $dropdown{$table}{$data}; }
#           else { $err_text .= '//// ' . "$data in ID $joinkey and table $table not a valid term in obo\n"; } }
      if ( ($table eq 'anatomy') || ($table eq 'anatomyquality') || ($table eq 'lifestage') || ($table eq 'lifestagequality') || ($table eq 'molaffected') || ($table eq 'molaffectedquality') || ($table eq 'goprocess') || ($table eq 'goprocessquality') || ($table eq 'gofunction') || ($table eq 'gofunctionquality') || ($table eq 'gocomponent') || ($table eq 'gocomponentquality') || ($table eq 'parentstrain') || ($table eq 'rescuedby') ) {
        my @return_vals; if ($data =~ m/^\"/) { $data =~ s/^\"//; } if ($data =~ m/\"$/) { $data =~ s/\"$//; }
        if ($data =~ m/\",\"/) { 
          my @data = split/\",\"/, $data; 
          foreach my $data (@data) {
            if ( $dropdown{$table}{$data} ) { 
#                 if ($table eq 'lifestage') { $data = $dropdown{$table}{$data}; }
                push @return_vals, $data; }
              else { $err_text .= '//// ' . "$data in ID $joinkey and table $table not a valid term in obo\n"; } } }
          else {
            if ( $dropdown{$table}{$data} ) { 
#                 if ($table eq 'lifestage') { $data = $dropdown{$table}{$data}; }
                push @return_vals, $data; }
              else { $err_text .= '//// ' . "$data in ID $joinkey and table $table not a valid term in obo\n"; } }
        if ( (scalar @return_vals) > 0) { $data = join"\t", @return_vals; } }
    if ($data =~ m//) { $data =~ s///g; }
    if ($data =~ m/\n/) { $data =~ s/\n/  /g; }
    if ($data =~ m/^\s+/) { $data =~ s/^\s+//g; } if ($data =~ m/\s+$/) { $data =~ s/\s+$//g; }
    if ($data =~ m/\"/) { $data =~ s/\"/\\\"/g; } }
  return $data;
} # sub getAppData


sub addEvi {				# append evidence hash to a line, making it a multi-line line
  my ($evidence, $line) = @_; my $tag_data;
  chomp $line;
  my $line_ts = 0;
  if ($line =~ m/\-O \"[\d]{4}/) { 		# if the line has acedb timestamps
    $tag_data .= "$line\n";			# always print it without evidence (as well as with matching evidence later)
    $line_ts++; }				# flag it to have timestamp
  if ($evidence) {
      my @evidences = split/\n/, $evidence;			# break multi-line evidence into evidence array
      foreach my $evi (@evidences) { 
#         $tag_data .= "$line\t$evi\n"; 
        if ($evi =~ m/Curator_confirmed/) { 	# if curator evidence, check that their acedb timestamp state matches
            my $evi_ts = 0; 
            if ($evi =~ m/\-O\s+\"[\d]{4}/) { $evi_ts++; }			# flag if evidence has timestamp
            if ($evi_ts && $line_ts) { $tag_data .= "$line\t$evi\n"; }		# append lines without timestamp if evidence is without timestamp 
            if (!$evi_ts && !$line_ts) { $tag_data .= "$line\t$evi\n"; }	# append lines with timestamp if evidence is with timestamp 
          }
          else { $tag_data .= "$line\t$evi\n"; }				# always append person and paper evidence
      }
      return $tag_data; }
    else { return "$line\n"; }
} # sub addEvi


sub getLabEvidence {
  my ($joinkey) = @_; my $evidence;
  if ($theHash{laboratory}{$joinkey}) { 
    my (@labs) = split/,/, $theHash{laboratory}{$joinkey};		# labs now have multiple values and quotes around them  2010 08 25
    foreach my $lab (@labs) { 
      $lab =~ s/\"//g; 				# strip double quotes  2010 08 25
      next unless $lab;				# skip if no lab  2011 08 23
      $evidence .= "Laboratory_evidence\t\"$lab\"\n"; } }
  if ($evidence) { return $evidence; }
} # sub getLabEvidence

sub getEvidence {
  my ($joinkey) = @_; my $evidence;
  my %curators; my %papers;
  if ($theHash{curator}{$joinkey}) {
    my $curator = $theHash{curator}{$joinkey};
    if ($theHash{communitycurator}{$joinkey}) { 
      $curator = $theHash{communitycurator}{$joinkey}; 		# if community curator exists, use that. 2015 10 22
      $curators{$curator}++; }	
    $evidence .= "Curator_confirmed\t\"$curator\"\n"; }
  if ($theHash{person}{$joinkey}) { 
    my @people = split/,/, $theHash{person}{$joinkey};				# break up into people if more than one person
    foreach my $person (@people) { 
      my ($check_evi) = $person =~ m/WBPerson(\d+)/; 
      unless ($check_evi) { $evidence .= "//// ERROR Person $person NOT a valid person\n"; next ; }
      unless ($existing_evidence{person}{$check_evi}) { $evidence .= "//// ERROR Person $person NOT a valid person\n"; next ; }
      $person =~ s/^\s+//g; $evidence .= "Person_evidence\t$person\n"; } }	# already has doublequotes in DB because of phenote 2008 01 30
  if ($theHash{paper}{$joinkey}) {
    if ($theHash{paper}{$joinkey} =~ m/WBPaper\d+/) { 
        if ( $deadObjects{paper}{invalid}{$theHash{paper}{$joinkey}} ) { $err_text .= "pgid $joinkey has invalid paper $theHash{paper}{$joinkey}\n"; }
        my ($check_evi) = $theHash{paper}{$joinkey} =~ m/WBPaper(\d+)/;
        if ($existing_evidence{paper}{$check_evi}) {
            $papers{"WBPaper$check_evi"}++;
            $evidence .= "Paper_evidence\t\"WBPaper$check_evi\"\n"; } 	# 2006 08 23 get the WBPaper, not the data with comments
          else { $evidence .= "//// ERROR Paper $theHash{paper}{$joinkey} NOT a valid paper\n"; } }
      else { $err_text .= '//// ' . "$joinkey has bad paper data $theHash{paper}{$joinkey}\n"; return "ERROR"; } }
  foreach my $curator (keys %curators) { foreach my $paper (keys %papers) { $paperCommunity{$paper}{$curator}++; } }
  if ($evidence) { return $evidence; }
} # sub getEvidence

sub populateExistingEvidence {		# get hash of valid wbpersons and wbpapers
  $result = $dbh->prepare( "SELECT * FROM two ORDER BY two" );
  $result->execute();
  while (my @row = $result->fetchrow) {
    $existing_evidence{person}{$row[1]}++; }
  $result = $dbh->prepare( "SELECT * FROM pap_status WHERE pap_status = 'valid'" );
  $result->execute();			# papers now in pap tables, not wpa  2010 08 25
  while (my @row = $result->fetchrow) {
    if ($row[0]) { $existing_evidence{paper}{$row[0]}++; } }
} # sub populateExistingEvidence

sub populateDeadObjects {
  $result = $dbh->prepare( "SELECT * FROM pap_status WHERE pap_status = 'invalid';" ); $result->execute();
  while (my @row = $result->fetchrow) { $deadObjects{paper}{invalid}{"WBPaper$row[0]"} = $row[1]; }
  $result = $dbh->prepare( "SELECT * FROM gin_dead;" ); $result->execute();
  while (my @row = $result->fetchrow) {                 # Karen doesn't care about hierarchy, just show her an error message
    if ($row[1]) { $deadObjects{gene}{"WBGene$row[0]"} = $row[1]; } }
#   while (my @row = $result->fetchrow) {                 # Chris sets precedence of split before merged before suppressed before dead, and a gene can only have one value, referring to the highest priority (only 1 value per gene in gin_dead table)  2013 10 21
#     if ($row[1] =~ m/split_into (WBGene\d+)/) {       $deadObjects{gene}{"split"}{"WBGene$row[0]"} = $1; }
#       elsif ($row[1] =~ m/merged_into (WBGene\d+)/) { $deadObjects{gene}{"mapto"}{"WBGene$row[0]"} = $1; }
#       elsif ($row[1] =~ m/Suppressed/) {              $deadObjects{gene}{"suppressed"}{"WBGene$row[0]"} = $row[1]; }
#       elsif ($row[1] =~ m/Dead/) {                    $deadObjects{gene}{"dead"}{"WBGene$row[0]"} = $row[1]; } }
#   my $doAgain = 1;                                    # if a mapped gene maps to another gene, loop through all again
#   while ($doAgain > 0) {
#     $doAgain = 0;                                     # stop if no genes map to other genes
#     foreach my $gene (sort keys %{ $deadObjects{gene}{mapto} }) {
#       next unless ( $deadObjects{gene}{mapTo}{$gene} );
#       my $mappedGene = $deadObjects{gene}{mapTo}{$gene};
#       if ($deadObjects{gene}{mapTo}{$mappedGene}) {
#         $deadObjects{gene}{mapTo}{$gene} = $deadObjects{gene}{mapTo}{$mappedGene};          # set mapping of original gene to 2nd degree mapped gene
#         $doAgain++; } } }                             # loop again in case a mapped gene maps to yet another gene
} # sub populateDeadObjects



sub populateDropdown {
#   $dropdown{nature}{WBnature000001} = 'Recessive';
#   $dropdown{nature}{WBnature000002} = 'Semi_dominant';
#   $dropdown{nature}{WBnature000003} = 'Dominant';
#   $dropdown{nature}{WBnature000004} = 'Haploinsufficient';
# 
#   $dropdown{penetrance}{WBpenetrance000001} = 'Incomplete';
#   $dropdown{penetrance}{WBpenetrance000002} = 'Low';
#   $dropdown{penetrance}{WBpenetrance000003} = 'High';
#   $dropdown{penetrance}{WBpenetrance000004} = 'Complete';
#   
#   $dropdown{func}{WBfunc000001} = 'Amorph';
#   $dropdown{func}{WBfunc000002} = 'Hypomorph';
#   $dropdown{func}{WBfunc000003} = 'Isoallele';
#   $dropdown{func}{WBfunc000004} = 'Uncharacterised_loss_of_function';
#   $dropdown{func}{WBfunc000005} = 'Wild_type';
#   $dropdown{func}{WBfunc000006} = 'Hypermorph';
#   $dropdown{func}{WBfunc000007} = 'Uncharacterised_gain_of_function';
#   $dropdown{func}{WBfunc000008} = 'Neomorph';
#   $dropdown{func}{WBfunc000009} = 'Dominant_negative';
#   $dropdown{func}{WBfunc000010} = 'Mixed';
#   $dropdown{func}{WBfunc000011} = 'Gain_of_function';
#   $dropdown{func}{WBfunc000012} = 'Loss_of_function';
#   $dropdown{func}{WBfunc000013} = 'Haploinsufficient';

#   my $nature_file = get( "http://tazendra.caltech.edu/~azurebrd/var/work/phenote/nature.obo" );
#   my (@entry) = split/\n\n/, $nature_file;
#   foreach my $entry (@entry) {
#     my $name; my $id;
#     if ($entry =~ m/name: (.+)/) { $name = $1; }
#     if ($entry =~ m/id: (WBnature\d+)/) { $id = $1; }
#     next unless ($name && $id);
#     $dropdown{nature}{$id} = $name;
#   } # foreach my $entry (@entry)
#   
#   my $func_file = get( "http://tazendra.caltech.edu/~azurebrd/var/work/phenote/func.obo" );
#   (@entry) = split/\n\n/, $func_file;
#   foreach my $entry (@entry) {
#     my $name; my $id;
#     if ($entry =~ m/name: (.+)/) { $name = $1; }
#     if ($entry =~ m/id: (WBfunc\d+)/) { $id = $1; }
#     next unless ($name && $id);
#     $dropdown{func}{$id} = $name;
#   } # foreach my $entry (@entry)
#   
#   my $penetrance_file = get( "http://tazendra.caltech.edu/~azurebrd/var/work/phenote/penetrance.obo" );
#   (@entry) = split/\n\n/, $penetrance_file;
#   foreach my $entry (@entry) {
#     my $name; my $id;
#     if ($entry =~ m/name: (.+)/) { $name = $1; }
#     if ($entry =~ m/id: (WBpenetrance\d+)/) { $id = $1; }
#     next unless ($name && $id);
#     $dropdown{penetrance}{$id} = $name;
#   } # foreach my $entry (@entry)
  
#   my $anat_file = get( "http://www.berkeleybop.org/ontologies/obo-all/worm_anatomy/worm_anatomy.obo" );
#   (@entry) = split/\n\n/, $anat_file;
#   foreach my $entry (@entry) {
#     my $name; my $id;
#     if ($entry =~ m/name: (.+)\n/) { $name = $1; }
#     if ($entry =~ m/id: (WBbt:\d+)\n/) { $id = $1; }
#     next unless ($name && $id);
#     $dropdown{anatomy}{$id} = $name;
#   } # foreach my $entry (@entry)
# 
#   my $ls_file = get( "http://tazendra.caltech.edu/~azurebrd/var/work/phenote/worm_development.obo" );
#   (@entry) = split/\n\n/, $ls_file;
#   foreach my $entry (@entry) {
#     my $name; my $id;
#     next unless ($entry =~ m/\[Term\]/);
#     if ($entry =~ m/name: (.+)/) {
#       $name = $1;
#       if ($name =~ m/name: (.+)\n/) { $name = $1; } }
#     if ($entry =~ m/id: (.+)/) { $id = $1; }
#     next unless ($name && $id);
#     $dropdown{lifestage}{$id} = $name;
#   } # foreach my $entry (@entry)

  $result = $dbh->prepare( "SELECT * FROM obo_name_quality" );	# many quality fields from same type of ontology
  $result->execute();			# get from obo_ table instead of obsolete .obo file
  while (my @row = $result->fetchrow) {
    if ($row[0]) { 
      $dropdown{goprocessquality}{$row[0]}     = $row[1];
      $dropdown{gofunctionquality}{$row[0]}    = $row[1];
      $dropdown{gocomponentquality}{$row[0]}   = $row[1];
      $dropdown{molaffectedquality}{$row[0]}   = $row[1];
      $dropdown{anatomyquality}{$row[0]}       = $row[1];
      $dropdown{lifestagequality}{$row[0]}     = $row[1]; } }

  $result = $dbh->prepare( "SELECT * FROM obo_name_goidprocess" );
  $result->execute();			# get from obo_ table instead of obsolete .obo file
  while (my @row = $result->fetchrow) {
    if ($row[0]) { $dropdown{goprocess}{$row[0]} = $row[1]; } }

  $result = $dbh->prepare( "SELECT * FROM obo_name_goidfunction" );
  $result->execute();			# get from obo_ table instead of obsolete .obo file
  while (my @row = $result->fetchrow) {
    if ($row[0]) { $dropdown{gofunction}{$row[0]} = $row[1]; } }

  $result = $dbh->prepare( "SELECT * FROM obo_name_goidcomponent" );
  $result->execute();			# get from obo_ table instead of obsolete .obo file
  while (my @row = $result->fetchrow) {
    if ($row[0]) { $dropdown{gocomponent}{$row[0]} = $row[1]; } }

  $result = $dbh->prepare( "SELECT * FROM obo_name_lifestage" );
  $result->execute();			# get from obo_ table instead of obsolete .obo file
  while (my @row = $result->fetchrow) {
    if ($row[0]) { $dropdown{lifestage}{$row[0]} = $row[1]; } }

  $result = $dbh->prepare( "SELECT * FROM obo_name_strain" );
  $result->execute();			# get from obo_ table instead of obsolete .obo file
  while (my @row = $result->fetchrow) {
    if ($row[0]) { $dropdown{parentstrain}{$row[0]} = $row[1]; } }

  $result = $dbh->prepare( "SELECT * FROM obo_name_anatomy" );
  $result->execute();			# get from obo_ table instead of obsolete .obo file
  while (my @row = $result->fetchrow) {
    if ($row[0]) { $dropdown{anatomy}{$row[0]} = $row[1]; } }

  $result = $dbh->prepare( "SELECT * FROM trp_name" );
  $result->execute();			# get from obo_ table instead of obsolete .obo file
  while (my @row = $result->fetchrow) {
    if ($row[0]) { $dropdown{rescuedby}{$row[1]} = $row[1]; } }

#   $result = $dbh->prepare( "SELECT * FROM mop_molecule" );
#   $result->execute();			# papers now in pap tables, not wpa  2010 08 25
#   while (my @row = $result->fetchrow) {
#     if ($row[0]) { $dropdown{molecule}{$row[0]} = $row[1]; } }
  $result = $dbh->prepare( "SELECT * FROM mop_name" );		# molecules are now stored by wbmolID instead of pgid
  $result->execute();
  while (my @row = $result->fetchrow) {
    if ($row[0]) { 
      $dropdown{molaffected}{$row[1]} = $row[1]; 
      $dropdown{molecule}{$row[1]} = $row[1]; } }
} # sub populateDropdown


sub filterAce {
  my $identifier = shift;
  if ($identifier =~ m/\//) { $identifier =~ s/\//\\\//g; }
  if ($identifier =~ m/\\/) { $identifier =~ s/\\/\\\\/g; }
  if ($identifier =~ m/\"/) { $identifier =~ s/\"/\\\"/g; }
  if ($identifier =~ m/\s+$/) { $identifier =~ s/\s+$//; }
  if ($identifier =~ m/:/) { $identifier =~ s/:/\\:/g; }
  if ($identifier =~ m/;/) { $identifier =~ s/;/\\;/g; }
  if ($identifier =~ m/,/) { $identifier =~ s/,/\\,/g; }
  if ($identifier =~ m/-/) { $identifier =~ s/-/\\-/g; }
  if ($identifier =~ m/%/) { $identifier =~ s/%/\\%/g; }
  return $identifier;
} # sub filterAce


1;

# attach evidence with timestamps to data with timestamp only and viceversa


__END__

sub getHeader {				# get .ace object header, type and finalname
  my ($joinkey) = @_; my %tempHash; my $finalname = 'no_final_name'; my $type = ''; 
#   my $result = $dbh->prepare( "SELECT alp_finalname FROM alp_finalname WHERE joinkey = '$joinkey' ORDER BY alp_timestamp DESC;" );
#   $result->execute();
#   my @row = $result->fetchrow; if ($row[0]) { $finalname = $row[0]; }
#   $result = $dbh->prepare( "SELECT alp_type FROM alp_type WHERE joinkey = '$joinkey' ORDER BY alp_timestamp DESC;" );
#   $result->execute();
  my $result = $dbh->prepare( "SELECT app_tempname FROM app_tempname WHERE joinkey = '$joinkey' ;" );
  $result->execute();
  my @row = $result->fetchrow; if ($row[0]) { $finalname = $row[0]; }
  $result = $dbh->prepare( "SELECT app_type FROM app_type WHERE joinkey = '$joinkey' ;" );
  $result->execute();
  @row = $result->fetchrow; if ($row[0]) { $type = $row[0]; }
  my $header .= "$type : \"$finalname\"	//// pgid $joinkey\n";	# added pgid for debugging  2010 08 25
  if ($header =~ m/Allele/) { $header =~ s/Allele/Variation/g; }
# names are already WBVarIDs  2010 06 14
#   if ($header =~ m/Variation/) {
#     if ( $name_to_id{$finalname} ) { $header =~ s/$finalname/$name_to_id{$finalname}/; }
#       else { return "$finalname does not map to an ID"; } }
#   if ($badAlleles{$finalname}) { return "$finalname not in approved list"; }	# no longer want this, all alleles should be good since they're WBVarIDs  2010 06 23
  return ($header, $finalname);
} # sub getHeader

# my %curators;

# my @genParams = qw ( type tempname finalname wbgene rnai_brief );
# my @groupParams = qw ( curator paper person finished phenotype remark intx_desc);
# my @multParams = qw ( not term phen_remark quantity_remark quantity go_sug suggested sug_ref sug_def genotype lifestage anatomy temperature strain preparation treatment delivered nature penetrance percent range mat_effect pat_effect heat_sens heat_degree cold_sens cold_degree func haplo );


sub getCondition {
  my ($joinkey, $i, $j) = @_;						# get the joinkey, box, and column
  my $g_type = 'paper_' . $i;
  my $other_g_type = 'person_' . $i;
  if ($theHash{$g_type}{html_value}) { if ($theHash{$g_type}{html_value} =~ m/(WBPaper\d+)/) {
    my $paper = $1; my $condition = ''; my $condition_data = '';	# find the paper

    my %condition; my $condition_count;		# hash of conditions to match a header name to the .ace condition data generated below, and the numbers used so far corresponding to them
    my %find_paper;				# find all joinkeys (tempnames) and boxes corresponding to papers (need hash because old values stored with current values in postgres)
    my $result = $conn->exec( "SELECT * FROM alp_paper ORDER BY alp_timestamp;" );
    while (my @row = $result->fetchrow) { $find_paper{$row[0]}{$row[1]} = $row[2]; }	# keys joinkey, box, value paper
    foreach my $joinkey (sort keys %find_paper) {
      foreach my $i (sort keys %{ $find_paper{$joinkey} }) {	# scoped $i is the box number of postgres-looping entry
        if ($find_paper{$joinkey}{$i}) {			# if there's paper data
          if ($find_paper{$joinkey}{$i} =~ m/(WBPaper\d+)/) {	# if there's a paper
            my $loop_paper = $1;				# get the paper
            if ($paper eq $loop_paper) { 			# if it matches the main paper
              my @condParams = qw ( genotype lifestage temperature strain preparation treatment );	# the six conditions
              my $alp_column_max = 0;				# how many columns to loop through for a given joinkey-box
              foreach my $type (@condParams) {			# get the max column number
                my $result2 = $conn->exec( "SELECT alp_column FROM alp_$type WHERE joinkey = '$joinkey' AND alp_box = '$i';" );
                while (my @row2 = $result2->fetchrow) { if ($row2[0] > $alp_column_max) { $alp_column_max = $row2[0]; } } }
              for my $j ( 1 .. $alp_column_max ) {		# for each column
                $condition_data = '';				# initialize data for the condition
                my $result2 = $conn->exec( "SELECT * FROM alp_genotype WHERE joinkey = '$joinkey' AND alp_box = '$i' AND alp_column = '$j' ORDER BY alp_timestamp DESC;" );
                my @row2 = $result2->fetchrow;			# get latest genotype data if there's any
                if ($row2[3]) { if ($row2[3] =~ m/\w/) { $condition_data .= "Genotype\t\"$row2[3]\"\n"; } }
                $result2 = $conn->exec( "SELECT * FROM alp_lifestage WHERE joinkey = '$joinkey' AND alp_box = '$i' AND alp_column = '$j' ORDER BY alp_timestamp DESC;" );
                @row2 = $result2->fetchrow;
                if ($row2[3]) { if ($row2[3] =~ m/\w/) { 
                  if ($row2[3] =~ m/, /) { my @stuff = split/, /, $row2[3]; foreach my $stuff (@stuff) { $condition_data .= "Life_stage\t\"$stuff\"\n"; } }
                    else { $condition_data .= "Life_stage\t\"$row2[3]\"\n"; } } }	# split life_stage by commas for Carol 2006 09 08
                $result2 = $conn->exec( "SELECT * FROM alp_temperature WHERE joinkey = '$joinkey' AND alp_box = '$i' AND alp_column = '$j' ORDER BY alp_timestamp DESC;" );
                @row2 = $result2->fetchrow;
                if ($row2[3]) { if ($row2[3] =~ m/(\d+)/) { $condition_data .= "Temperature\t\"$1\"\n"; } }
                $result2 = $conn->exec( "SELECT * FROM alp_strain WHERE joinkey = '$joinkey' AND alp_box = '$i' AND alp_column = '$j' ORDER BY alp_timestamp DESC;" );
                @row2 = $result2->fetchrow;
                if ($row2[3]) { if ($row2[3] =~ m/\w/) { $condition_data .= "Strain\t\"$row2[3]\"\n"; } }
                $result2 = $conn->exec( "SELECT * FROM alp_preparation WHERE joinkey = '$joinkey' AND alp_box = '$i' AND alp_column = '$j' ORDER BY alp_timestamp DESC;" );
                @row2 = $result2->fetchrow;
                if ($row2[3]) { if ($row2[3] =~ m/\w/) { $condition_data .= "Preparation\t\"$row2[3]\"\n"; } }
                $result2 = $conn->exec( "SELECT * FROM alp_treatment WHERE joinkey = '$joinkey' AND alp_box = '$i' AND alp_column = '$j' ORDER BY alp_timestamp DESC;" );
                @row2 = $result2->fetchrow;
                if ($row2[3]) { if ($row2[3] =~ m/\w/) { $condition_data .= "Treatment\t\"$row2[3]\"\n"; } }
                if ($condition_data) { 				# if there's condition data
                  $condition_data .= "Reference\t\"$paper\"\n"; 						# only add reference if there is data in any of the other six fields
                  unless ($condition{$paper}{$condition_data}) {						# if it's a new condition
                    $condition_count++;										# add to count
                    $condition{$paper}{$condition_data} = "${paper}_${joinkey}:phenotype_${condition_count}"; } } }	# add header to hash 
								# add the variation object in the condition object name  for Carol 2006 09 08
          } } } } }

    $condition_data = '';					# init condition data for the entry generating a .ace
    my $ts_type = 'genotype_' . $i . '_' . $j;			# Genotype Data
    if ($theHash{$ts_type}{html_value}) { if ($theHash{$ts_type}{html_value} =~ m/\w/) { $condition_data .= "Genotype\t\"$theHash{$ts_type}{html_value}\"\n"; } }
    $ts_type = 'lifestage_' . $i . '_' . $j;			# Life Stage Data
    if ($theHash{$ts_type}{html_value}) { if ($theHash{$ts_type}{html_value} =~ m/\w/) { 
      if ($theHash{$ts_type}{html_value} =~ m/, /) { my @stuff = split/, /, $theHash{$ts_type}{html_value}; foreach my $stuff (@stuff) { $condition_data .= "Life_stage\t\"$stuff\"\n"; } }
        else { $condition_data .= "Life_stage\t\"$theHash{$ts_type}{html_value}\"\n"; } } }	# split life_stage by commas for Carol 2006 09 08
    $ts_type = 'temperature_' . $i . '_' . $j;			# Temperature Data
    if ($theHash{$ts_type}{html_value}) { if ($theHash{$ts_type}{html_value} =~ m/(\d+)/) { $condition_data .= "Temperature\t\"$1\"\n"; } }
    $ts_type = 'strain_' . $i . '_' . $j;			# Strain Data
    if ($theHash{$ts_type}{html_value}) { if ($theHash{$ts_type}{html_value} =~ m/\w/) { $condition_data .= "Strain\t\"$theHash{$ts_type}{html_value}\"\n"; } }
    $ts_type = 'preparation_' . $i . '_' . $j;			# Preparation Data
    if ($theHash{$ts_type}{html_value}) { if ($theHash{$ts_type}{html_value} =~ m/\w/) { $condition_data .= "Preparation\t\"$theHash{$ts_type}{html_value}\"\n"; } }
    $ts_type = 'treatment_' . $i . '_' . $j;			# Treatment Data
    if ($theHash{$ts_type}{html_value}) { if ($theHash{$ts_type}{html_value} =~ m/\w/) { $condition_data .= "Treatment\t\"$theHash{$ts_type}{html_value}\"\n"; } }
    if ($condition_data) {
      $condition_data .= "Reference\t\"$paper\"\n"; 
      $condition = "Condition : \"$condition{$paper}{$condition_data}\"\n" . $condition_data;		# get paragraph
      return ($condition, $condition{$paper}{$condition_data});
  } } }

  else { 
    my $person = ''; my $condition = ''; my $condition_data = '';	# find the person
    if ($theHash{$other_g_type}{html_value}) { if ($theHash{$other_g_type}{html_value} =~ m/(WBPerson\d+)/) { $person = $1; } }
      # also allow Condition and Phenotype_assay to be dumped if there's a Person evidence for Carol 2006 07 27
    unless ($person) {						# if no person, infer it from curator, for Carol  2006 09 08
      my $result2 = $conn->exec( "SELECT alp_curator FROM alp_curator WHERE joinkey = '$joinkey' AND alp_box = '$i' ORDER BY alp_timestamp DESC;" );
      my @row2 = $result2->fetchrow;
      my $std_name = $row2[0];
      if ($std_name =~ m/WBPerson(\d+)/) { $person = $1; }
      $result2 = $conn->exec( "SELECT joinkey FROM two_standardname WHERE two_standardname = '$std_name';" );
      @row2 = $result2->fetchrow;
      if ($row2[0]) { $row2[0] =~ s/two/WBPerson/; $person = $row2[0]; } }
    next unless $person;					# if still no person, skip it

    my %condition; my $condition_count;		# hash of conditions to match a header name to the .ace condition data generated below, and the numbers used so far corresponding to them
    my @condParams = qw ( genotype lifestage temperature strain preparation treatment );	# the six conditions
    my $alp_column_max = 0;				# how many columns to loop through for a given joinkey-box
    foreach my $type (@condParams) {			# get the max column number
      my $result2 = $conn->exec( "SELECT alp_column FROM alp_$type WHERE joinkey = '$joinkey' AND alp_box = '$i';" );
      while (my @row2 = $result2->fetchrow) { if ($row2[0] > $alp_column_max) { $alp_column_max = $row2[0]; } } }
    for my $j ( 1 .. $alp_column_max ) {		# for each column
      $condition_data = '';				# initialize data for the condition
      my $result2 = $conn->exec( "SELECT * FROM alp_genotype WHERE joinkey = '$joinkey' AND alp_box = '$i' AND alp_column = '$j' ORDER BY alp_timestamp DESC;" );
      my @row2 = $result2->fetchrow;			# get latest genotype data if there's any
      if ($row2[3]) { if ($row2[3] =~ m/\w/) { $condition_data .= "Genotype\t\"$row2[3]\"\n"; } }
      $result2 = $conn->exec( "SELECT * FROM alp_lifestage WHERE joinkey = '$joinkey' AND alp_box = '$i' AND alp_column = '$j' ORDER BY alp_timestamp DESC;" );
      @row2 = $result2->fetchrow;
      if ($row2[3]) { if ($row2[3] =~ m/\w/) { 
        if ($row2[3] =~ m/, /) { my @stuff = split/, /, $row2[3]; foreach my $stuff (@stuff) { $condition_data .= "Life_stage\t\"$stuff\"\n"; } }
          else { $condition_data .= "Life_stage\t\"$row2[3]\"\n"; } } }		# split life_stage by commas for Carol 2006 09 08
      $result2 = $conn->exec( "SELECT * FROM alp_temperature WHERE joinkey = '$joinkey' AND alp_box = '$i' AND alp_column = '$j' ORDER BY alp_timestamp DESC;" );
      @row2 = $result2->fetchrow;
      if ($row2[3]) { if ($row2[3] =~ m/(\d+)/) { $condition_data .= "Temperature\t\"$1\"\n"; } }
      $result2 = $conn->exec( "SELECT * FROM alp_strain WHERE joinkey = '$joinkey' AND alp_box = '$i' AND alp_column = '$j' ORDER BY alp_timestamp DESC;" );
      @row2 = $result2->fetchrow;
      if ($row2[3]) { if ($row2[3] =~ m/\w/) { $condition_data .= "Strain\t\"$row2[3]\"\n"; } }
      $result2 = $conn->exec( "SELECT * FROM alp_preparation WHERE joinkey = '$joinkey' AND alp_box = '$i' AND alp_column = '$j' ORDER BY alp_timestamp DESC;" );
      @row2 = $result2->fetchrow;
      if ($row2[3]) { if ($row2[3] =~ m/\w/) { $condition_data .= "Preparation\t\"$row2[3]\"\n"; } }
      $result2 = $conn->exec( "SELECT * FROM alp_treatment WHERE joinkey = '$joinkey' AND alp_box = '$i' AND alp_column = '$j' ORDER BY alp_timestamp DESC;" );
      @row2 = $result2->fetchrow;
      if ($row2[3]) { if ($row2[3] =~ m/\w/) { $condition_data .= "Treatment\t\"$row2[3]\"\n"; } }
      if ($condition_data) { 				# if there's condition data
        # $condition_data .= "Reference\t\"$person\"\n";		# person has person data here, which does not match Reference tag in acedb  for Carol  2006 09 08
        unless ($condition{$person}{$condition_data}) {						# if it's a new condition
          $condition_count++;										# add to count
          $condition{$person}{$condition_data} = "${person}_${joinkey}:phenotype_${condition_count}"; } } }	# add header to hash 
								# add the variation object in the condition object name  for Carol 2006 09 08

    $condition_data = '';					# init condition data for the entry generating a .ace
    my $ts_type = 'genotype_' . $i . '_' . $j;			# Genotype Data
    if ($theHash{$ts_type}{html_value}) { if ($theHash{$ts_type}{html_value} =~ m/\w/) { $condition_data .= "Genotype\t\"$theHash{$ts_type}{html_value}\"\n"; } }
    $ts_type = 'lifestage_' . $i . '_' . $j;			# Life Stage Data
    if ($theHash{$ts_type}{html_value}) { if ($theHash{$ts_type}{html_value} =~ m/\w/) { 
      if ($theHash{$ts_type}{html_value} =~ m/, /) { my @stuff = split/, /, $theHash{$ts_type}{html_value}; foreach my $stuff (@stuff) { $condition_data .= "Life_stage\t\"$stuff\"\n"; } }
        else { $condition_data .= "Life_stage\t\"$theHash{$ts_type}{html_value}\"\n"; } } }	# split life_stage by commas for Carol 2006 09 08
    $ts_type = 'temperature_' . $i . '_' . $j;			# Temperature Data
    if ($theHash{$ts_type}{html_value}) { if ($theHash{$ts_type}{html_value} =~ m/(\d+)/) { $condition_data .= "Temperature\t\"$1\"\n"; } }
    $ts_type = 'strain_' . $i . '_' . $j;			# Strain Data
    if ($theHash{$ts_type}{html_value}) { if ($theHash{$ts_type}{html_value} =~ m/\w/) { $condition_data .= "Strain\t\"$theHash{$ts_type}{html_value}\"\n"; } }
    $ts_type = 'preparation_' . $i . '_' . $j;			# Preparation Data
    if ($theHash{$ts_type}{html_value}) { if ($theHash{$ts_type}{html_value} =~ m/\w/) { $condition_data .= "Preparation\t\"$theHash{$ts_type}{html_value}\"\n"; } }
    $ts_type = 'treatment_' . $i . '_' . $j;			# Treatment Data
    if ($theHash{$ts_type}{html_value}) { if ($theHash{$ts_type}{html_value} =~ m/\w/) { $condition_data .= "Treatment\t\"$theHash{$ts_type}{html_value}\"\n"; } }
    if ($condition_data) {
      # $condition_data .= "Reference\t\"$person\"\n";		# person has person data here, which does not match Reference tag in acedb  for Carol  2006 09 08
      $condition = "Condition : \"$condition{$person}{$condition_data}\"\n" . $condition_data;		# get paragraph
      return ($condition, $condition{$person}{$condition_data});
  } }
} # sub getCondition



#   for my $i (1 .. $theHash{group_mult}{html_value}) {			# different box values
#     my $evidence = ''; ($evidence) = &getEvidence($joinkey, $i);	# get the evidence multi-line for the joinkey and box
#     if ($evidence) { if ($evidence eq 'ERROR') { return; } }
#     my $g_type = 'phenotype_' . $i ;					# get phenotype remark
#     my $phen_rem = '';  if ($theHash{$g_type}{html_value}) { $phen_rem = $theHash{$g_type}{html_value}; }
#     for my $j (1 .. $theHash{horiz_mult}{html_value}) {			# different column values
#       my $cur_entry = '';
#       if ($phen_rem) { $cur_entry .= &addEvi($evidence, "Phenotype_remark\t\"$phen_rem\""); }
#       my $phenotype = '';
#       my $ts_type = 'term_' . $i . '_' . $j;				# call ts_type (don't recall why)
#       if ($theHash{$ts_type}{html_value}) { 				# Phenotype Ontology Term
#           $phenotype = $theHash{$ts_type}{html_value}; 
#           if ($phenotype =~ m/(WBPhenotype\d+)/) { $phenotype = $1; 	# Storing values as PhenotypeID (phenotype term) so it should always match	2005 12 22
#             $cur_entry .= &addEvi($evidence, "Phenotype\t\"$phenotype\""); } }	# always attach the Phenotype   2006 05 12
#         else { next; }							# skip if there's no phenotype
#       $ts_type = 'not_' . $i . '_' . $j;				# NOT
#       if ($theHash{$ts_type}{html_value}) { $cur_entry .= &addEvi($evidence, "Phenotype\t\"$phenotype\"\tNOT"); }
#       $ts_type = 'phen_remark_' . $i . '_' . $j;			# Remark (Phenotype)
#       if ($theHash{$ts_type}{html_value}) { $cur_entry .= &addEvi($evidence, "Phenotype\t\"$phenotype\"\tRemark\t\"$theHash{$ts_type}{html_value}\""); }
#       $ts_type = 'quantity_remark_' . $i . '_' . $j;			# Quantity
#       if ($theHash{$ts_type}{html_value}) { $cur_entry .= &addEvi($evidence, "Phenotype\t\"$phenotype\"\tQuantity_description\t\"$theHash{$ts_type}{html_value}\""); }
#       $ts_type = 'quantity_' . $i . '_' . $j;				# Quantity Data
#       if ($theHash{$ts_type}{html_value}) {
#         my $value = $theHash{$ts_type}{html_value}; 
#         if ($value =~ m/(\d+)\D+(\d+)/) { $value = "$1\"\t\"$2"; }
#         elsif ($value =~ m/(\d+)/) { $value = "$1\"\t\"$1"; }
#         else { $err_text .= '\\\\ ' . "$joinkey has bad quantity data data $value\n"; next; }		# skip entry if quantity data doesn't have an integer
#         $cur_entry .= &addEvi($evidence, "Phenotype\t\"$phenotype\"\tQuantity\t\"$value\""); }
#       $ts_type = 'nature_' . $i . '_' . $j;				# Dominance
#       if ($theHash{$ts_type}{html_value}) { $cur_entry .= &addEvi($evidence, "Phenotype\t\"$phenotype\"\t$theHash{$ts_type}{html_value}"); }
# 
#       $ts_type = 'penetrance_' . $i . '_' . $j;				# Penetrance
#       my $ts_percent = 'percent_' . $i . '_' . $j;			# Percent
#       if ($theHash{$ts_type}{html_value}) {
#         my $percent = ''; if ($theHash{$ts_percent}{html_value}) { $percent = $theHash{$ts_percent}{html_value}; }
#         $cur_entry .= &addEvi($evidence, "Phenotype\t\"$phenotype\"\tPenetrance\t$theHash{$ts_type}{html_value} \"$percent\""); }
#       my $range = '100" "100';					# default Range for penetrance being Complete
#       my $ts_range = 'range_' . $i . '_' . $j;			# Range
#       if ($theHash{$ts_type}{html_value}) {
#         unless ($theHash{$ts_type}{html_value} =~ m/Complete/) {		# range is not 100
#           if ($theHash{$ts_range}{html_value}) {
#             $range = $theHash{$ts_range}{html_value}; 
#             if ($range =~ m/\s/) { $range =~ s/\s+/\" \"/g; }
#               else { $range = "$range\" \"$range"; } }
#       } }
#       if ($theHash{$ts_range}{html_value}) {			# output a range if there's a range 
#           $cur_entry .= &addEvi($evidence, "Phenotype\t\"$phenotype\"\tRange\t\"$range\""); }
#         elsif ($theHash{$ts_type}{html_value}) {
#           if ($theHash{$ts_type}{html_value} =~ m/Complete/) {	# output a range if penetrance is Complete
#             $cur_entry .= &addEvi($evidence, "Phenotype\t\"$phenotype\"\tRange\t\"$range\""); } } 
#         else { 1; }
#       $ts_type = 'mat_effect_' . $i . '_' . $j;				# Mat Effect
#       if ($theHash{$ts_type}{html_value}) { $cur_entry .= &addEvi($evidence, "Phenotype\t\"$phenotype\"\t$theHash{$ts_type}{html_value}"); }
#       $ts_type = 'pat_effect_' . $i . '_' . $j;				# Pat Effect
#       if ($theHash{$ts_type}{html_value}) { $cur_entry .= &addEvi($evidence, "Phenotype\t\"$phenotype\"\tPaternal"); }
#       my $degree = '';
#       $ts_type = 'heat_degree_' . $i . '_' . $j;			# Heat_sensitive degree
#       if ($theHash{$ts_type}{html_value}) { $degree = $theHash{$ts_type}{html_value}; }
#       $ts_type = 'heat_sens_' . $i . '_' . $j;				# Heat_sensitive
#       if ($theHash{$ts_type}{html_value}) { $cur_entry .= &addEvi($evidence, "Phenotype\t\"$phenotype\"\tHeat_sensitive\t\"$degree\""); }
#       $ts_type = 'cold_degree_' . $i . '_' . $j;			# Cold_sensitive degree
#       if ($theHash{$ts_type}{html_value}) { $degree = $theHash{$ts_type}{html_value}; }
#       $ts_type = 'cold_sens_' . $i . '_' . $j;				# Cold_sensitive
#       if ($theHash{$ts_type}{html_value}) { $cur_entry .= &addEvi($evidence, "Phenotype\t\"$phenotype\"\tCold_sensitive\t\"$degree\""); }
#       $ts_type = 'func_' . $i . '_' . $j;				# Functional Change
#       if ($theHash{$ts_type}{html_value}) { $cur_entry .= &addEvi($evidence, "Phenotype\t\"$phenotype\"\t$theHash{$ts_type}{html_value}"); }
#       $ts_type = 'haplo_' . $i . '_' . $j;				# Haploinsufficient
#       if ($theHash{$ts_type}{html_value}) { $cur_entry .= &addEvi($evidence, "Phenotype\t\"$phenotype\"\tHaplo_insufficient"); }
#       unless ($cur_entry) { $cur_entry .= &addEvi($evidence, "Phenotype\t\"$phenotype\""); }		# only add evidence hash if there's no other data  2005 12 20
# 
#       my ($condition, $condition_name) = &getCondition($joinkey, $i, $j);	# get condition data and condition header name for this .ace entry
#       if ($condition) { if ($finalname) {				# Show the appropriate tag in Condition based on $header  2006 11 08
#         if ($header =~ m/Transgene/) { $condition .= "Transgene\t\"$finalname\"\n"; } 
#         elsif ($header =~ m/Variation/) { $condition .= "Variation\t\"$finalname\"\n"; } 
#         elsif ($header =~ m/RNAi/) { $condition .= "RNAi\t\"$finalname\"\n"; } } }
#       if ($condition_name) {
#         $cur_entry .= "Phenotype\t\"$phenotype\"\tPhenotype_assay\t\"$condition_name\"\n";
# # Carol no longer wants curator tag for Phenotype_assay  2005 12 20
# #         my $g_type = 'curator_' . $i;						# get the curator
# #         if ($theHash{$g_type}{html_value}) { if ($curators{std}{$theHash{$g_type}{html_value}}) {
# #           $theHash{$g_type}{html_value} = $curators{std}{$theHash{$g_type}{html_value}}; $theHash{$g_type}{html_value} =~ s/two/WBPerson/g; }	# convert to WBPerson
# #           $cur_entry .= "Phenotype\t\"$phenotype\"\tPhenotype_assay\t\"$condition_name\"\tCurator_confirmed\t\"$theHash{$g_type}{html_value}\"\n"; }
#         $cur_entry .= "\n$condition"; }					# add the condition
#       if ($cur_entry) { $ace_entry .= "\n$header$cur_entry"; }		# create the ace entry
#   } }


# sub queryPostgres {					# populate %theHash with data for this joinkey
#   my $joinkey = shift;
#   $theHash{group_mult}{html_value} = 0; $theHash{horiz_mult}{html_value} = 0;
#   foreach my $type (@genParams) {
#     delete $theHash{$type}{html_value};                 # only wipe out the values, not the whole subhash  2005 11 16
#     my $result = $conn->exec( "SELECT * FROM alp_$type WHERE joinkey = '$joinkey' ORDER BY alp_timestamp;" );
#     while (my @row = $result->fetchrow) {
#       if ($row[1]) { $theHash{$type}{html_value} = $row[1]; }
#         else { $theHash{$type}{html_value} = ''; } } }
# #   if ($theHash{finalname}{html_value}) { print "Based on postgres, finalname should be : $theHash{finalname}{html_value}<BR>\n"; }
# #   if ($theHash{wbgene}{html_value}) { print "Based on postgres, wbgene should be : $theHash{wbgene}{html_value}<BR>\n"; }
#   foreach my $type (@groupParams) {
#     my $result = $conn->exec( "SELECT * FROM alp_$type WHERE joinkey = '$joinkey' ORDER BY alp_timestamp;" );
#     while (my @row = $result->fetchrow) {
#       my $g_type = $type . '_' . $row[1] ;
#       delete $theHash{$g_type}{html_value};
#       if ($row[2]) {
#           $theHash{$g_type}{html_value} = $row[2];
#           if ($theHash{horiz_mult}{html_value}) { if ($row[1] > $theHash{horiz_mult}{html_value}) { $theHash{horiz_mult}{html_value} = $row[1]; } } }
#         else { $theHash{$g_type}{html_value} = ''; } } }
#   foreach my $type (@multParams) {
#     my $result = $conn->exec( "SELECT * FROM alp_$type WHERE joinkey = '$joinkey' ORDER BY alp_timestamp;" );
#     while (my @row = $result->fetchrow) {
#       my $ts_type = $type . '_' . $row[1] . '_' . $row[2];
#       delete $theHash{$ts_type}{html_value};
#       if ($row[3]) {
#           $theHash{$ts_type}{html_value} = $row[3];
#           if ($row[1] > $theHash{group_mult}{html_value}) { $theHash{group_mult}{html_value} = $row[1]; }
#           if ($row[2] > $theHash{horiz_mult}{html_value}) { $theHash{horiz_mult}{html_value} = $row[2]; } }
#         else { $theHash{$ts_type}{html_value} = ''; } } }
# } # sub queryPostgres

# sub populateCurators {					# get curators to convert to WBPersons
#   my $result = $conn->exec( "SELECT * FROM two_standardname; " );
#   while (my @row = $result->fetchrow) {
#     $curators{two}{$row[0]} = $row[2];
#     $curators{std}{$row[2]} = $row[0];
#   } # while (my @row = $result->fetchrow)
#   $curators{std}{'Juancarlos Testing'} = 'two1823';
# } # sub populateCurators

