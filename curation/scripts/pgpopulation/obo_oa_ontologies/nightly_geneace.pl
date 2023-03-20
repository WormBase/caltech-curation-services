#!/usr/bin/env perl

# populate postgres tables based on nightly geneace dump.
#
# 200397 INSERTs in 31 minutes 26 seconds going command by command
# 2013-09-27 16:03:44.178218-07  2013-09-27 16:35:10.069645-07
# 200397 INSERTs in 29 minutes 21 seconds going command by command
# 2013-09-27 16:39:16.049969-07  2013-09-27 17:08:37.968094-07
# about one minute if done by postgres account doing a COPY from files.  2013 09 27
#
# http://wiki.wormbase.org/index.php/WBGene_information_and_status_pipeline
# parsed laboratories into obo_ laboratory tables.  2013 10 03
#
# called by /home/postgres/work/pgpopulation/obo_oa_ontologies/update_obo_oa_ontologies.pl
# live on tazendra.  2013 10 24
#
# LWP::Simple stopped working 2014 02 06, UserAgent doesn't work either.  Using
# wget from the shell.  2014 02 06
# Changed to new ftp URL from Michael Paulini.  2014 02 06
#
# Also process the features.ace.gz for Xiaodong and Chris.  2014 03 19
#
# clones.ace.gz lacks some data, switched to clones2.ace.gz  
# Karen no longer wants filter on Plasmid.  
# explicitly added existing Type fields to capture. 
# Removed  Accession_number, In_strain, Transgene, Location  from clone.  2014 07 23
#
# Removed features.ace.gz since that's now being parsed by
# /home/postgres/work/pgpopulation/sqf_sequencefeature/populate_from_geneace/parse_seqfeat.pl 
# also called from  update_obo_oa_ontologies.pl  for Daniela + Xiaodong  2014 10 01
#
# Added species to variation for Chris.  2015 04 03
#
# Many are out of date, Chris asking Michael P what happenned.
# Added species to strain for Chris.  2015 12 16
# 
# Encode utf-8, since some data has special characters now from laboratories.  2017 09 22
#
# Remove stuff in parenthesis from rearrangement object names.  Possibly should be across 
# all objects, but Karen didn't say so.  2017 11 14
#
# Karen was wrong, we didn't need to remove them.  2017 11 27
#
# Variations exclude specific methods instead of whitelisting, for Chris 2018 05 08
#
# Get updated strains from  /home/azurebrd/public_html/cgi-bin/data/obo_tempfile_strain
# 2020 04 06
#
# Removed mh6/ from path for Paul Davis.  2020 06 11
#
# Filter strains and variations that are not WB objects.  2021 09 15
#
# Read tempfile for variations first, to allow geneace variations that are in tempfile
# and would otherwise get excluded because of their Method.  For Chris.  2021 09 21
#
# Get mapping of WS Variations to Genes from WSVar_Genes.ace from parse_ws_variations.pl
# If a Variation from geneace does not have that gene, add it.  For Kimberly.  2022 01 27
#
# Updated to get gene sequence names if there is no gene locus.  
# Updated to call parse_ws_variations.pl which will update WSVar_Genes.ace if Wen uploaded
# a new WSVariation.ace in the last 24 hours.   For Kimberly.  2022 02 07
#
# called by /home/postgres/work/pgpopulation/obo_oa_ontologies/update_obo_oa_ontologies.pl
#
# dockerized, but fails to copy from file when ran inside docker (which it has to be)
# COPY obo_name_laboratory FROM '/usr/caltech_curation_files/cronjobs/obo_oa_ontologies/geneace/obo_name_laboratory.pg';
# DBD::Pg::db do failed: ERROR:  could not open file "/usr/caltech_curation_files/cronjobs/obo_oa_ontologies/geneace/obo_name_laboratory.pg" for reading: No such file or directory
# The script is ran inside docker and the files are generated at the location inside docker
# but the postgres copy command cannot see the files.  2023 03 19

# called by /usr/lib/scripts/pgpopulation/obo_oa_ontologies/update_obo_oa_ontologies.pl




use strict;
use diagnostics;
use Jex;
use DBI;
use LWP::UserAgent;
use Tie::IxHash;
use LWP::Simple;
use utf8;
use Encode;
use Dotenv -load => '/usr/lib/.env';

my $dbh = DBI->connect ( "dbi:Pg:dbname=$ENV{PSQL_DATABASE};host=$ENV{PSQL_HOST};port=$ENV{PSQL_PORT}", "$ENV{PSQL_USERNAME}", "$ENV{PSQL_PASSWORD}") or die "Cannot connect to database!\n";
# my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my $directory = $ENV{CALTECH_CURATION_FILES_INTERNAL_PATH} . '/cronjobs/obo_oa_ontologies/geneace';
# my $directory = '/home/postgres/work/pgpopulation/obo_oa_ontologies/geneace';
chdir($directory) or die "Cannot go to $directory ($!)";



# update the WSVar_Genes.ace  if it was modified in last 24 hours.  2022 02 07
`/usr/lib/scripts/pgpopulation/obo_oa_ontologies/parse_ws_variations.pl`;
# `/home/postgres/work/pgpopulation/obo_oa_ontologies/geneace/parse_ws_variations.pl`;


my $timestamp = &getPgDate();
# print "TIME $timestamp\n";

# my $ftp_dir = 'ftp://ftp.sanger.ac.uk/pub2/wormbase/STAFF/mh6/nightly_geneace/';
# my $ftp_dir = 'ftp://ftp.sanger.ac.uk/pub/consortia/wormbase/STAFF/mh6/nightly_geneace/';
# my $ftp_dir = 'ftp://ftp.sanger.ac.uk/pub/consortia/wormbase/STAFF/nightly_geneace/';	# obsolete 2021 01 25 by paul davis
my $ftp_dir = 'ftp://ftp.ebi.ac.uk/pub/databases/wormbase/STAFF/nightly_geneace/';	# changed 2021 01 25 by paul davis

my @gz = qw( clones2.ace.gz rearrangements.ace.gz strains.ace.gz variations.ace.gz laboratories.ace.gz );

# my @gz = qw( clones2.ace.gz rearrangements.ace.gz strains.ace.gz variations.ace.gz laboratories.ace.gz features.ace.gz );	# features moved out from here and into /home/postgres/work/pgpopulation/sqf_sequencefeature/populate_from_geneace/parse_seqfeat.pl 
# my @gz = qw( clones.ace.gz rearrangements.ace.gz strains.ace.gz variations.ace.gz laboratories.ace.gz features.ace.gz );
# my @gz = qw( laboratories.ace.gz );
# my @gz = qw( variations.ace.gz );
# my @gz = qw( strains.ace.gz );

my %wbgeneToLocus;
$result = $dbh->prepare( "SELECT * FROM gin_locus" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) { $wbgeneToLocus{"WBGene$row[0]"} = $row[1]; }

my %wbgeneToSeqname;
$result = $dbh->prepare( "SELECT * FROM gin_seqname" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) { $wbgeneToSeqname{"WBGene$row[0]"} = $row[1]; }

my %std_name;
$result = $dbh->prepare( "SELECT * FROM two_standardname;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) { 
  $row[0] =~ s/two/WBPerson/;
  if ($row[2] =~ m/\'/) { $row[2] =~ s/\'/''/g; }
  $std_name{$row[0]} = $row[2]; }

my %variationsInWsGenes;
&populateVariationsInWs();

sub populateVariationsInWs {
  my $infile = 'WSVar_Genes.ace';
  open (IN, "<$infile") or die "Cannot open $infile : $!";
  while (my $line = <IN>) {
    chomp $line;
    my ($var, $genes) = split/\t/, $line;
    my (@genes) = split/, /, $genes;
    foreach my $gene (@genes) { $variationsInWsGenes{$var}{$gene}++; }
  } # while (my $entry = <IN>)
  close (IN) or die "Cannot close $infile : $!";
} # sub populateVariationsInWs

my %variationsInGeneace;	# key nameToId / idToName, subkey id / Public_name  value Public_name / id ;  to populate extra objects in tempVariation file not in geneace
my %strainsInGeneace;		# key nameToId / idToName, subkey id / Public_name  value Public_name / id ;  to populate extra objects in tempStrain file not in geneace

foreach my $gz (@gz) {	# for each .gz file to process from the sanger ftp
  my @pgcommands = ();
  my ($datatype) = $gz =~ m/^(.*?)s2?\.ace.gz/;
  my $orig_datatype = $datatype;
  if ($datatype eq 'laboratorie') { $datatype = 'laboratory'; }
  my $ftp = $ftp_dir . $gz;
#   print "FTP $ftp FTP\n";
# getting through LWP stopped working, so using wget from the shell, later Michael Paulini told me of the new URL and it worked again  2014 02 06
#   `wget $ftp`;
#   my $gzfile = $orig_datatype . 's.ace.gz';
#   my $infile = $orig_datatype . 's.ace';
#   if (-e $infile) { `rm $infile`; }				# remove previous file so gunzip won't complain it exists
#   `gunzip $gzfile`;
#   $/ = undef;
#   open (IN, "<$infile") or die "Cannot open $infile : $!";
#   my $ftpdata = <IN>;
#   close (IN) or die "Cannot close $infile : $!";
#   $/ = "\n";

# tried UserAgent in case it worked, but didn't, later when Michael Paulini gave me new URL didn't need anymore
#   my $ua = LWP::UserAgent->new(timeout => 30); # instantiates a new user agent
#   $ua->agent('Mozilla/5.0');
#   my $request  = HTTP::Request->new(GET => $ftp); # grabs url
#   my $response = $ua->request($request);       # checks url, dies if not valid.
#   my $user = 'anonymous'; my $pass = 'anonymous';
#   $request->authorization_basic($user, $pass);
#   if ($response->is_success) { print "SUCCESS $response->content END\n\n;" }
#     else { my $fail = $response->status_line; die "FAIL : $fail : END\n"; }	# failing with message : 404 Can't chdir to wormbase  2014 02 06 
#   my $ftpdata  = $response->content;    


  my %tempVar;
  if ($datatype eq 'variation') {			# for variations look at obo_tempfile_variation and add any terms not in geneace
    my $obotempfilevar = $ENV{CALTECH_CURATION_FILES_INTERNAL_PATH} . '/pub/cgi-bin/data/obo_tempfile_variation';
    # my $obotempfilevar = '/home/azurebrd/public_html/cgi-bin/data/obo_tempfile_variation';
    if (-e $obotempfilevar) { 
      open (IN, "<$obotempfilevar") or warn "Cannot open $obotempfilevar : $!";
      while (my $line = <IN>) {
        chomp $line;
        my ($varid, $pubname, $pgDate, $comment) = split/\t/, $line;
        $tempVar{$varid} = $line;
      } # while (my $line = <IN>)
    } # if (-e $obotempfilevar)
  } # if ($datatype eq 'variation')

  my $ftpdata = get $ftp;				# this automatically gunzips the file	# stopped working 2014 02 06
  $ftpdata = encode( "UTF-8", $ftpdata ); 
  next unless $ftpdata;					# if there's no data, do nothing instead of wiping out postgres tables.  2014 05 29
  if ($ftpdata =~ m/^\n/) { $ftpdata =~ s/^\n//; }	# take out leading empty line
  my $name_file = $directory . '/obo_name_' . $datatype . '.pg';
  my $data_file = $directory . '/obo_data_' . $datatype . '.pg';
  my $syn_file  = $directory . '/obo_syn_'  . $datatype . '.pg';
  open (NAME, ">$name_file") or die "Cannot create $name_file : $!";
  open (DATA, ">$data_file") or die "Cannot create $data_file : $!";
  if ( ($datatype eq 'laboratory') || ($datatype eq 'variation') ) {
    open (SYN,  ">$syn_file")  or die "Cannot create $syn_file  : $!";
  } # if ( ($datatype eq 'laboratory') || ($datatype eq 'variation') )
  my (@entries) = split/\n\n/, $ftpdata;
  foreach my $entry (@entries) {
#     next if ( ($datatype eq 'clone') && ($entry !~ m/\nPlasmid/) );
    next if ( ($datatype eq 'feature') && 
              ($entry !~ m/Method\s+\"binding_site\"/) &&
              ($entry !~ m/Method\s+\"binding_site_region\"/) &&
              ($entry !~ m/Method\s+\"DNAseI_hypersensitive_site\"/) &&
              ($entry !~ m/Method\s+\"enhancer\"/) &&
              ($entry !~ m/Method\s+\"histone_binding_site_region\"/) &&
              ($entry !~ m/Method\s+\"promoter\"/) &&
              ($entry !~ m/Method\s+\"regulatory_region\"/) &&
              ($entry !~ m/Method\s+\"TF_binding_site\"/) &&
              ($entry !~ m/Method\s+\"TF_binding_site_region\"/) 
            );
    $entry =~ s/\\//g;				# take out all backslashes
    my (@lines) = split/\n/, $entry;
    my $header = shift @lines;
    my ($objName) = $header =~ m/ : \"(.*?)\"/;
    next if ( ($datatype eq 'strain') && ($objName !~ m/^WBStrain/) );
    next if ( ($datatype eq 'variation') && ($objName !~ m/^WBVar/) );
    next if ( ($datatype eq 'variation') && !($tempVar{$objName}) && 
# exclude specific methods instead, for Chris 2018 05 08
              ( ($entry =~ m/Method\s+\"SNP\"/) ||
                ($entry =~ m/Method\s+\"WGS_Hawaiian_Waterston\"/) ||
                ($entry =~ m/Method\s+\"WGS_Pasadena_Quinlan\"/) ||
                ($entry =~ m/Method\s+\"WGS_Hobert\"/) ||
                ($entry =~ m/Method\s+\"Million_mutation\"/) ||
                ($entry =~ m/Method\s+\"WGS_Yanai\"/) ||
                ($entry =~ m/Method\s+\"WGS_De_Bono\"/) ||
                ($entry =~ m/Method\s+\"WGS_Andersen\"/) ||
                ($entry =~ m/Method\s+\"WGS_Flibotte\"/) ||
                ($entry =~ m/Method\s+\"WGS_Rose\"/) )
# used to only allow specific methods, now exclude specific methods instead, for Chris 2018 05 08
#               ($entry !~ m/Method\s+\"Allele\"/) &&
#               ($entry !~ m/Method\s+\"Deletion_allele\"/) &&
#               ($entry !~ m/Method\s+\"Deletion_and_insertion_allele\"/) &&
#               ($entry !~ m/Method\s+\"Deletion_polymorphism\"/) &&
#               ($entry !~ m/Method\s+\"Insertion_allele\"/) &&
#               ($entry !~ m/Method\s+\"Insertion_polymorhism\"/) &&
#               ($entry !~ m/Method\s+\"KO_consortium_allele\"/) &&
#               ($entry !~ m/Method\s+\"Mos_insertion\"/) &&
#               ($entry !~ m/Method\s+\"NBP_knockout_allele\"/) &&
#               ($entry !~ m/Method\s+\"NemaGENETAG_consortium_allele\"/) &&
#               ($entry !~ m/Method\s+\"Substitution_allele\"/) &&
#               ($entry !~ m/Method\s+\"Transposon_insertion\"/) &&
#               ($entry !~ m/Method\s+\"Engineered_allele\"/)
            );

    my %varGeneaceGenes;

#     if ($datatype eq 'rearrangement') {
#       if ($objName =~ m/\(.*\)/) { $objName =~ s/\(.*\)//; } }
#     print "ENTRY $entry HEADER $header NAME $objName END\n";
    my %data; tie %data, "Tie::IxHash";
    $data{"id"}{$objName}++;
    my $name = $objName;
    if ($datatype eq 'variation') {
      if ($entry =~ m/Public_name\s+\"(.*?)\"/) { $name = $1; } 
      $variationsInGeneace{nameToId}{$name}    = $objName;
      $variationsInGeneace{idToName}{$objName} = $name; }
    if ($datatype eq 'strain') {
      if ($entry =~ m/Public_name\s+\"(.*?)\"/) { $name = $1; }
      $strainsInGeneace{nameToId}{$name}    = $objName;
      $strainsInGeneace{idToName}{$objName} = $name; }
    $data{"name"}{$name}++;
#     my $data = qq(id: $objName\nname: "$name");
    foreach my $line (@lines) {
      if ($line =~ m/Reference\t \"(.*?)\"/) { 
        if ( ($datatype eq 'clone') || ($datatype eq 'variation') ) { 
          $data{"reference"}{$1}++; } }
      elsif ($line =~ m/Other_name\t \"(.*?)\"/) { 
        if ($datatype eq 'variation') { 
          print SYN qq($objName\t$1\t$timestamp\n);
          $data{"other_name"}{$1}++; } }
      elsif ($line =~ m/Accession_number\t \"(.*?)\"/) { 
        if ($datatype eq 'clone') { 
          $data{"accession_number"}{$1}++; } }
      elsif ($line =~ m/General_remark\t \"(.*?)\"/) { 
        if ($datatype eq 'clone') { 
          $data{"remark"}{$1}++; } }
      elsif ( ($line =~ m/^(Cosmid)/) || ($line =~ m/^(Fosmid)/) || ($line =~ m/^(YAC)/) ||
              ($line =~ m/^(cDNA)/) || ($line =~ m/^(Plasmid)/) || ($line =~ m/^(Other)/) ) {
        if ($datatype eq 'clone') { 
          $data{"type"}{$1}++; } }
#       elsif ($line =~ m/In_strain\t \"(.*?)\"/) { 	# Karen doesn't want these anymore  2014 07 23
#         if ($datatype eq 'clone') { 
#           $data{"strain"}{$1}++; } }
#       elsif ($line =~ m/Transgene\t \"(.*?)\"/) { 
#         if ($datatype eq 'clone') { 
#           $data{"transgene"}{$1}++; } }
      elsif ($line =~ m/Public_name\t \"(.*?)\"/) {
        if ($datatype eq 'feature') { 
          $data{"public_name"}{$1}++; } }
      elsif ($line =~ m/DNA_text\t \"(.*?)\"/) {
        if ($datatype eq 'feature') { 
          $data{"dna_text"}{$1}++; } }
      elsif ($line =~ m/Species\t \"(.*?)\"/) {
        if ( ($datatype eq 'feature') || ($datatype eq 'strain') || ($datatype eq 'variation') ) { 
          $data{"species"}{$1}++; } }
      elsif ($line =~ m/Wild_isolate/) {        # Added for Daniela  2017 08 10
        if ($datatype eq 'strain') {
          $data{"wild_isolate"}{"Wild_isolate"}++; } }
      elsif ($line =~ m/Defined_by_paper\t \"(.*?)\"/) {
        if ($datatype eq 'feature') { 
          $data{"defined_by_paper"}{$1}++; } }
      elsif ($line =~ m/Associated_with_gene\t \"(.*?)\"/) {
        if ($datatype eq 'feature') { 
          $data{"associated_with_gene"}{$1}++; } }
      elsif ($line =~ m/Associated_with_Interaction\t \"(.*?)\"/) {
        if ($datatype eq 'feature') { 
          $data{"associated_with_interaction"}{$1}++; } }
      elsif ($line =~ m/Associated_with_expression_pattern\t \"(.*?)\"/) {
        if ($datatype eq 'feature') { 
          $data{"associated_with_expression_pattern"}{$1}++; } }
      elsif ($line =~ m/Bound_by_product_of\t \"(.*?)\"/) {
        if ($datatype eq 'feature') { 
          $data{"bound_by_product_of"}{$1}++; } }
      elsif ($line =~ m/Transcription_factor\t \"(.*?)\"/) {
        if ($datatype eq 'feature') { 
          $data{"transcription_factor"}{$1}++; } }
      elsif ($line =~ m/Method\t \"(.*?)\"/) {
        if ($datatype eq 'feature') { 
          $data{"method"}{$1}++; } }
      elsif ($line =~ m/Mail\t \"(.*?)\"/) {
        if ($datatype eq 'laboratory') { 
          $data{"Mail"}{$1}++; } }
      elsif ($line =~ m/Representative\t \"(WBPerson\d+)\"/) {
        if ($datatype eq 'laboratory') {
          my $rep = $1;
          if ($std_name{$rep}) { $rep = $std_name{$rep}; }
          $data{"Representatives"}{$rep}++; } }
      elsif ($line =~ m/Allele_designation\t \"(.*?)\"/) {
        if ($datatype eq 'laboratory') { 
          $data{"Allele_designation"}{$1}++; } }
      elsif ($line =~ m/Strain_designation\t \"(.*?)\"/) {
        if ($datatype eq 'laboratory') { 
          $data{"Strain_designation"}{$1}++; } }
      elsif ($line =~ m/Map\t \"(.*?)\"/) { 
        if ($datatype eq 'rearrangement') { 
          $data{"map"}{$1}++; } }
      elsif ($line =~ m/Gene_outside\t \"(WBGene\d+)\"/) {
        if ($datatype eq 'rearrangement') { 
          my $wbgene = $1;
          if ($wbgeneToLocus{$wbgene}) { $wbgene .= ' ' . $wbgeneToLocus{$wbgene}; }
          $data{"gene_outside"}{$wbgene}++; } }
      elsif ($line =~ m/Gene_inside\t \"(WBGene\d+)\"/) {
        if ($datatype eq 'rearrangement') { 
          my $wbgene = $1;
          if ($wbgeneToLocus{$wbgene}) { $wbgene .= ' ' . $wbgeneToLocus{$wbgene}; }
          $data{"gene_inside"}{$wbgene}++; } }
      elsif ($line =~ m/Location\t \"(.*?)\"/) {
        if ($datatype eq 'strain') { 
          $data{"location"}{$1}++; } }
      elsif ($line =~ m/Strain\t \"(.*?)\"/) {
        if ($datatype eq 'strain') { 
          $data{"strain"}{$1}++; } }
      elsif ($line =~ m/Genotype\t \"(.*?)\"/) {
        if ($datatype eq 'strain') { 
          $data{"summary"}{$1}++; } }
      elsif ($line =~ m/Gene\t \"(WBGene\d+)\"/) {
        if ($datatype eq 'variation') { 
          my $wbgene = $1;
          $varGeneaceGenes{$wbgene}++;	# track genes that came from geneace
          if ($wbgeneToLocus{$wbgene}) { $wbgene .= ' ' . $wbgeneToLocus{$wbgene}; }
          elsif ($wbgeneToSeqname{$wbgene}) { $wbgene .= ' ' . $wbgeneToSeqname{$wbgene}; }
          $data{"gene"}{$wbgene}++; } }
      elsif ($line =~ m/^Dead/) {
        if ($datatype eq 'variation') { 
          $data{"status"}{"Dead"}++; } }
      elsif ($line =~ m/^Live/) {
        if ($datatype eq 'variation') { 
          $data{"status"}{"Live"}++; } }
    } # foreach my $line (@lines)

    if ($datatype eq 'variation') { 	# for variations, add genes connected to the variation from WS, if they're not already there from geneace
      foreach my $wbgene (sort keys %{ $variationsInWsGenes{$objName} }) {
        unless ($varGeneaceGenes{$wbgene}) {	# if genes didn't come from geneace, add to list of genes
          if ($wbgeneToLocus{$wbgene}) { $wbgene .= ' ' . $wbgeneToLocus{$wbgene}; }
          elsif ($wbgeneToSeqname{$wbgene}) { $wbgene .= ' ' . $wbgeneToSeqname{$wbgene}; }
          # if (%varGeneaceGenes) { print qq($objName has additional gene $wbgene\n); }	# to output list of variations that had a gene but are getting more added
          $data{"gene"}{$wbgene}++; } } }

#     my $all_data = '';
    my @all_data;
    foreach my $key (keys %data) {
      foreach my $data (sort keys %{ $data{$key} }) {
        unless ($key eq 'id') { $data = '"' . $data . '"'; }
        push @all_data, qq(${key}: $data);		# escape backslash or literal \n if doing a COPY to table FROM file
      }
    }
    my $all_data = join"\\n", @all_data;
    if ($all_data =~ m/\'/) { $all_data =~ s/\'/''/g; }
#     push @pgcommands, qq(INSERT INTO obo_data_$datatype VALUES ('$objName', E'$all_data'););	# to do insert 1 by 1
#     push @pgcommands, qq(INSERT INTO obo_name_$datatype VALUES ('$objName', E'$name'););	# to do insert 1 by 1
    print DATA qq($objName\t$all_data\t$timestamp\n);
    print NAME qq($objName\t$name\t$timestamp\n);
    if ($datatype eq 'laboratory') {
      my $reps = join", ", sort keys %{ $data{"Representatives"} };
      my $mail = join", ", sort keys %{ $data{"Mail"} };
      my $reps_mails = "$reps - $mail";
      print SYN qq($objName\t$reps_mails\t$timestamp\n);
    } # if ($datatype eq 'laboratory')
#     print qq($all_data\n\n);
  } # while (my $entry = <IN>)
  if ($datatype eq 'strain') {			# for strain look at obo_tempfile_strain and add any terms not in geneace
    my $obotempfilestrain = $ENV{CALTECH_CURATION_FILES_INTERNAL_PATH} . '/pub/cgi-bin/data/obo_tempfile_strain';
    # my $obotempfilestrain = '/home/azurebrd/public_html/cgi-bin/data/obo_tempfile_strain';
    if (-e $obotempfilestrain) { 
      my $emailForStrain = '';
      open (IN, "<$obotempfilestrain") or warn "Cannot open $obotempfilestrain : $!";
      while (my $line = <IN>) {
        chomp $line;
        my ($strainid, $pubname, $pgDate, $comment) = split/\t/, $line;
        if ( $strainsInGeneace{nameToId}{$pubname} ) {		# compare strainid-pubname by pubname to different strainid
            my $geneaceVarid = $strainsInGeneace{nameToId}{$pubname};
            if ($geneaceVarid ne $strainid) { $emailForStrain .= qq($pubname in obo_tempfile_variation says $strainid geneace says $geneaceVarid\n); } }
        if ( $strainsInGeneace{idToName}{$strainid} ) {			# compare strainid-pubname by strainid to different pubname
            my $geneacePubname = $strainsInGeneace{idToName}{$strainid};
            if ($geneacePubname ne $pubname) { $emailForStrain .= qq($strainid in obo_tempfile_variation says $pubname geneace says $geneacePubname\n); } }
          else {							# temp strainid not in geneace, add to obo tables from tempfile 
            my $terminfo = qq(id: $strainid\\nname: "$pubname"\\ntimestamp: "$pgDate"\\ncomment: "$comment");
            print DATA qq($strainid\t$terminfo\t$timestamp\n);
            print NAME qq($strainid\t$pubname\t$timestamp\n);
        } # else # if ( $strainsInGeneace{idToName}{$strainid} )
      } # while (my $line = <IN>)
      close (IN) or warn "Cannot close $obotempfilestrain : $!";
      if ($emailForStrain) {						# something is inconsitent in obo_tempaname and geneace, email Strain curators
        my $user = 'nightly_geneace.pl';
        my $email = 'ranjana@wormbase.org, cgrove@caltech.edu';
#         my $email = 'azurebrd@tazendra.caltech.edu';
        my $subject = 'geneace discrepancy with obo_tempfile_strain';
        my $body = $emailForStrain;
        &mailer($user, $email, $subject, $body); }
    } # if (-e $obotempfilestrain)
  } # if ($datatype eq 'variation')
  if ($datatype eq 'variation') {			# for variations look at obo_tempfile_variation and add any terms not in geneace
    my $emailForKaren = '';
    foreach my $objName (sort keys %tempVar) {
      my ($varid, $pubname, $pgDate, $comment) = split/\t/, $tempVar{$objName};
      if ( $variationsInGeneace{nameToId}{$pubname} ) {		# compare varid-pubname by pubname to different varid
          my $geneaceVarid = $variationsInGeneace{nameToId}{$pubname};
          if ($geneaceVarid ne $varid) { $emailForKaren .= qq($pubname in obo_tempfile_variation says $varid geneace says $geneaceVarid\n); } }
      if ( $variationsInGeneace{idToName}{$varid} ) {			# compare varid-pubname by varid to different pubname
          my $geneacePubname = $variationsInGeneace{idToName}{$varid};
          if ($geneacePubname ne $pubname) { $emailForKaren .= qq($varid in obo_tempfile_variation says $pubname geneace says $geneacePubname\n); } }
        else {							# temp varid not in geneace, add to obo tables from tempfile 
          my $terminfo = qq(id: $varid\\nname: "$pubname"\\ntimestamp: "$pgDate"\\ncomment: "$comment");
          print DATA qq($varid\t$terminfo\t$timestamp\n);
          print NAME qq($varid\t$pubname\t$timestamp\n);
      } # else # if ( $variationsInGeneace{idToName}{$varid} )
    } # foreach my $objName (sort keys %tempVar)
    if ($emailForKaren) {						# something is inconsitent in obo_tempaname and geneace, email Karen
      my $user = 'nightly_geneace.pl';
      my $email = 'kyook@wormbase.org';
#       my $email = 'azurebrd@tazendra.caltech.edu';
      my $subject = 'geneace discrepancy with obo_tempfile_variation';
      my $body = $emailForKaren;
      &mailer($user, $email, $subject, $body); }
  } # if ($datatype eq 'variation')
  close (NAME) or die "Cannot close $name_file : $!";
  close (DATA) or die "Cannot close $data_file : $!";
  push @pgcommands, "DELETE FROM obo_name_$datatype;";
  push @pgcommands, "DELETE FROM obo_data_$datatype;";
  push @pgcommands, "COPY obo_data_$datatype FROM '$data_file';";
  push @pgcommands, "COPY obo_name_$datatype FROM '$name_file';";
  if ( ($datatype eq 'laboratory') || ($datatype eq 'variation') ) {
    close (SYN)  or die "Cannot close $syn_file  : $!";
    push @pgcommands, "DELETE FROM obo_syn_$datatype;";
    push @pgcommands, "COPY obo_syn_$datatype FROM '$syn_file';";
  } # if ( ($datatype eq 'laboratory') || ($datatype eq 'variation') )
  foreach my $pgcommand (@pgcommands) {
    print qq($pgcommand\n);
# UNCOMMENT TO POPULATE
    $dbh->do( $pgcommand );
  } # foreach my $pgcommand (@pgcommands)
} # foreach my $gz (@gz)


__END__

