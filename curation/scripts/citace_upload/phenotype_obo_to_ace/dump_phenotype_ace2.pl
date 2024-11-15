#!/usr/bin/env perl

# Checkout PhenOnt.obo and process for .ace output
# For Carol.  2006 01 11
#
# Check for obsoletes and put in Remark tag if so, with comment data.
# For Carol.  2006 08 07
#
# Get rid of OBSOLETE in Remark.  If alt_id put under Remark, and for the
# alt_id entry only write the Dead tag.  2006 11 03
#
# Some changes for Carol regarding Dead and Remark  2006 11 08
#
# Added : for new WBPhenotype:\d+ format.  2008 06 23
#
# name: field in .obo no longer has underscores, now it has space.  2010 05 26
#
# use cvs from cgi from spica instead of local (tazendra) cvs  2010 06 23
#
# updated for pap_ vs old wpa_ and gop_ vs old got_ pgtables.  2011 05 18
#
# no longer dump obsolete terms, for Gary and Chris.  2015 10 07
#
# Chris needs to be able to change the obo url, updating using his suggestion
# to do what we did for https://github.com/WormBase/caltech-curation-services/blob/main/curation/scripts/citace_upload/lifestage/lifestageAceFromObo.pl
# 2024 04 09
# 
# modified to allow WS### as command line parameter for chris_one_button.pl dumper script.  2024 10 07
# 
# generate obo file that was downloaded for one button script to transfer to Data_for_Ontology.  2024 11 15

use strict;
use diagnostics;
use LWP::Simple;
# use Pg;
use DBI;

use Dotenv -load => '/usr/lib/.env';


my $dbh = DBI->connect ( "dbi:Pg:dbname=$ENV{PSQL_DATABASE};host=$ENV{PSQL_HOST};port=$ENV{PSQL_PORT}", "$ENV{PSQL_USERNAME}", "$ENV{PSQL_PASSWORD}") or die "Cannot connect to database!\n";
# my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

# my $conn = Pg::connectdb("dbname=testdb");
# die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my %all_evi;

my %paperid;
my %phenotypeTerms;
my $error_file = 'errorfile';
open (ERR, ">$error_file") or die "Cannot create $error_file : $!";
my $outfile = 'phenotype_from_obo.ace';
open (OUT, ">$outfile") or die "Cannot create $outfile : $!";


my %existing_evidence;                          # existing wbpersons and wbpapers and go_terms
&populateExistingEvidence();

&populateXref();
&readCvs;

sub populateXref {
  my $result = $dbh->prepare( "SELECT * FROM pap_identifier ;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { $paperid{$row[1]} = $row[0]; }
#   my $result = $dbh->prepare( "SELECT * FROM wpa_identifier ORDER BY wpa_timestamp;" );
#   $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
#   while (my @row = $result->fetchrow) {
#     next unless $row[1];
#     if ($row[0]) { 
#       $row[0] =~ s///g;
#       $row[1] =~ s///g;
#       if ($row[3] eq 'valid') { $paperid{$row[1]} = $row[0]; }
#         else { if ($paperid{$row[1]}) { delete $paperid{$row[1]}; } } } }
} # sub populateXref


sub readCvs {
#   my $directory = '/home/acedb/carol/dump_phenotype_ace';
#   chdir($directory) or die "Cannot go to $directory ($!)";

# use cvs from cgi from spica instead of local cvs  2010 06 23
#   `cvs -d /var/lib/cvsroot checkout PhenOnt`;
#   my $file = $directory . '/PhenOnt/PhenOnt.obo';
# #   my $file = $directory . '/PhenOnt.obo.3';
#   $/ = "";
#   open (IN, "<$file") or die "Cannot open $file : $!";
#   while (my $para = <IN>) { # }

#   my $obofile = get "http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/phenotype_ontology_obo.cgi";
#   my $obofile = get "http://purl.obolibrary.org/obo/wbphenotype/releases/2019-01-29/wbphenotype-merged.obo";	# updated url 2019 02 27
#   my $obofile = get "https://www.dropbox.com/s/1glm0lamc78clce/wbphenotype.obo?dl=0";	# updated url 2019 02 28
#   my $obofile = get "http://tazendra.caltech.edu/~azurebrd/var/work/chris/wbphenotype.obo";	# temp testing 2019 02 28
#   my $obofile = get "https://github.com/obophenotype/c-elegans-phenotype-ontology/raw/vWS295/wbphenotype.obo";

  my $url = '';
  if ($ARGV[0]) {
    # chris_one_button.pl passing WS as parameter to construct url
    $url = 'https://github.com/obophenotype/c-elegans-phenotype-ontology/raw/v' . $ARGV[0] . '/wbphenotype.obo'; }
  else {
    # Chris needs to be able to change the url, so using an external file for it
    my $infile = 'obo_url';
    open (IN, "<$infile") or die "Cannot open $infile : $!";
    my $url = <IN>;
    chomp $url;
    close (IN) or die "Cannot open $infile : $!"; }

  my $obofile = get $url;
  my $obooutfile = 'phenotype_ontology.' . $ARGV[0] . '.obo';
  open (OBO, ">$obooutfile") or die "Cannot create $obooutfile : $!";
  print OBO $obofile;
  close (OBO) or die "Cannot close $obooutfile : $!";

  my (@entries) = split/\n\n/, $obofile;
  foreach my $para (@entries) {
    next unless ($para =~ m/id:/);
#     next if ($para =~ m/is_obsolete: true/);					# no longer skip obsoletes for Chris 2019 02 27

#     if ($para =~ m/id: WBPhenotype:(\d+).*?\bname: ([\w\- ]+)/s)
    if ($para =~ m/id: WBPhenotype:(\d+)/) {
      my $number = 'WBPhenotype:' . $1;
#  if ($number eq 'WBPhenotype:0001976') { print qq(NAME $name PARA $para); }
      my (@all_lines) = split/\n/, $para;
      foreach my $line (@all_lines) {
        if ($line =~ m/^name: ([\w\- ]*)/) { $phenotypeTerms{$number}{name} = $1; }
        if ($line =~ m/^def: "(.*?)" \[(.*?)\]/) {
          my $description = $1; my $evi_long = $2;
          if ($description =~ m/\\n/) { $description =~ s/\\n//g; }
          my $outline = "Description\t\"$description\"";
          if ($evi_long) { $phenotypeTerms{$number}{desc} = &attachEvi($outline, $evi_long); } 
            else { $phenotypeTerms{$number}{desc} = "$outline\n"; }
          $phenotypeTerms{$number}{evi} = $evi_long;
        }
        if ($line =~ m/^synonym:\s+\"([^"]+)\".*?\[(.*?)\]/) {
          my $syn = $1; my $evi_long = $2;
#             if ($number eq 'WBPhenotype0000038') { print "LIN $syn_line AT\n"; }
          next unless ($syn);
          my $outline = '';
          if ($line =~ m/three_letter_name/) {
              if ($evi_long) { $outline = &attachEvi("Short_name\t\"$syn\"", $evi_long); }
                else { $outline = "Short_name\t\"$syn\"\t$evi_long\n"; } }
            else {
              if ($evi_long) { $outline = &attachEvi("Synonym\t\"$syn\"", $evi_long); }
                else { $outline = "Synonym\t\"$syn\"\t$evi_long\n"; } }
#           if ($number eq 'WBPhenotype0000038') { print "AT $outline AT\n"; }
          $phenotypeTerms{$number}{syn} .= $outline;
        }
        if ($line =~ m/^replaced_by: (.*)/ ) { $phenotypeTerms{$number}{replaced_by} .= "Replaced_by\t\"$1\"\n"; }
        if ($line =~ m/^is_a: WBPhenotype:(\d{7})/) {
          my $num = "WBPhenotype:" . $1;
          $phenotypeTerms{$number}{specof} .= "Specialisation_of\t\"$num\"\n";
          $phenotypeTerms{$num}{genof} .= "Generalisation_of\t\"$number\"\n"; }
        if ($line =~ m/^part_of WBPhenotype:(\d{7})/) {
          my $num = "WBPhenotype:" . $1;
          $phenotypeTerms{$number}{specof} .= "Specialisation_of\t\"$num\"\n";
          $phenotypeTerms{$num}{genof} .= "Generalisation_of\t\"$number\"\n"; }
        if ($line =~ m/^alt_id: (WBPhenotype:\d+)/) {
          my $other_num = $1;
          $phenotypeTerms{$number}{remark} .= "Remark\t\"Alternate_ID: $other_num\"\n";
          $phenotypeTerms{$other_num}{dead} .= "Dead\tAlternate_phenotype\t\"$number\"\n"; }
        if ($line =~ m/^consider: (WBPhenotype:\d+)/ ) {
            my $other_num = $1;
            $phenotypeTerms{$number}{dead} .= "Dead\tAlternate_phenotype\t\"$other_num\"\n"; }
        if ($line =~ m/^is_obsolete: true/) { $phenotypeTerms{$number}{dead} .= "Dead\n"; }	# 2006 11 08
        if ($line =~ m/^comment: (.*?)$/) {
          my $comment = $1;
          if ($comment =~ m/\"/) { $comment =~ s/\"/\'/g; }
          if ($para =~ m/is_obsolete: true/) {
#               $phenotypeTerms{$number}{remark} .= "Remark\t\"OBSOLETE.  $comment\"\n";	# no longer say OBSOLETE for Carol 2006 11 03
#               $phenotypeTerms{$number}{remark} .= "Remark\t\"$comment\"\n"; 	# no longer dump remarks for obsolete for Chris  2019 02 27
            }
            else { 					# go to assay if not obsolete and no alt_id 2006 11 08
              unless ($para =~ m/alt_id: WBPhenotype:\d+/) { $phenotypeTerms{$number}{assay} .= "Assay\t\"$comment\"\n"; } } }
    } }
  }
#   close (IN) or die "Cannot close $file : $!";	# use cvs from cgi from spica
#   $directory .= '/PhenOnt';
#   `rm -rf $directory`; 
} # sub readCvs 

foreach my $num (sort keys %phenotypeTerms) {
  print OUT "\nPhenotype : \"$num\"\n";
  if ($phenotypeTerms{$num}{dead}) { 
      print OUT "$phenotypeTerms{$num}{dead}"; 
#       next if ($phenotypeTerms{$num}{dead} =~ m/Alternate_phenotype/); 	# stop if it's an alt for something else 2006 11 08	# no longer skip 2019 02 28
  }
  if ($phenotypeTerms{$num}{name}) { 	# no longer attach all evidence to Primary_name  for Carol / Anthony  2006 05 02
    print OUT "Primary_name\t\"$phenotypeTerms{$num}{name}\"\n"; } 
#       if ($phenotypeTerms{$num}{evi}) { 
#           my $line = &attachEvi("Primary_name\t\"$phenotypeTerms{$num}{name}\"", $phenotypeTerms{$num}{evi}); 
#           if ($line) { print OUT "$line"; }
#             else { print ERR "BAD EVIDENCE $phenotypeTerms{$num}{evi}\n"; } }
#         else { print OUT "Primary_name\t\"$phenotypeTerms{$num}{name}\"\n"; } }
#     else { print ERR "ERROR $num HAS NO NAME\n"; }
  if ($phenotypeTerms{$num}{desc}) { 
      print OUT "$phenotypeTerms{$num}{desc}"; }
  if ($phenotypeTerms{$num}{syn}) { 
      print OUT "$phenotypeTerms{$num}{syn}"; }
  if ($phenotypeTerms{$num}{specof}) { 
      print OUT "$phenotypeTerms{$num}{specof}"; }
  if ($phenotypeTerms{$num}{genof}) { 
      print OUT "$phenotypeTerms{$num}{genof}"; }
  if ($phenotypeTerms{$num}{assay}) { 
      print OUT "$phenotypeTerms{$num}{assay}"; }
  if ($phenotypeTerms{$num}{remark}) { 
      print OUT "$phenotypeTerms{$num}{remark}"; }
  if ($phenotypeTerms{$num}{replaced_by}) { 
      print OUT "$phenotypeTerms{$num}{replaced_by}"; }
} # foreach my $num (sort keys %phenotypeTerms)

# foreach my $evi (sort keys %all_evi) { print ERR "$evi\n"; }

close (ERR) or die "Cannot close $error_file : $!";
close (OUT) or die "Cannot close $outfile : $!";

sub attachEvi {
    # Also check papers and people and go terms to see if they are valid
  my ($line, $evi) = @_;
  my $lines = '';
  my @evi; my @tran_evi;
  if ($evi =~ m/, /) { @evi = split/, /, $evi; } else { push @evi, $evi; }
  foreach my $evi (@evi) { $all_evi{$evi}++; }
  foreach my $evi (@evi) {
    if ($evi =~ m/WB:WBPerson(\d+)/) { 	# check WBPerson but only skip if bad, print it out later if it matches after potential conversions below
      unless ($existing_evidence{person}{$1}) { print ERR "LINE $line HAS BAD WBPERSON WBPerson$1\n"; next; } }

    if ($evi =~ m/WB:WBPaper(\d+)/) { 
      if ($existing_evidence{paper}{$1}) { push @tran_evi, "Paper_evidence\t\"WBPaper$1\""; }
        else { print ERR "LINE $line HAS BAD WBPAPER WBPaper$1\n"; } }
    elsif ($evi =~ m/WB:WBperson557/) { push @tran_evi, "Curator_confirmed\t\"WBPerson557\""; }
    elsif ($evi =~ m/WB:WBPerson557/) { push @tran_evi, "Curator_confirmed\t\"WBPerson557\""; }
    elsif ($evi =~ m/WB:(WBPerson\d+)/) { push @tran_evi, "Person_evidence\t\"$1\""; }
    elsif ($evi =~ m/WB:WBperson(\d+)/) { push @tran_evi, "Person_evidence\t\"WBPerson$1\""; }
    elsif ($evi =~ m/WB:cab/) { push @tran_evi, "Curator_confirmed\t\"WBPerson48\""; }
    elsif ($evi =~ m/WB:kmva/) { push @tran_evi, "Curator_confirmed\t\"WBPerson1843\""; }
    elsif ($evi =~ m/WB:rk/) { push @tran_evi, "Curator_confirmed\t\"WBPerson324\""; }
    elsif ($evi =~ m/WB:IA/) { push @tran_evi, "Curator_confirmed\t\"WBPerson22\""; }
    elsif ($evi =~ m/WB:ia/) { push @tran_evi, "Curator_confirmed\t\"WBPerson22\""; }
    elsif ($evi =~ m/WB:(cgc\d+)/) { 
      if ($paperid{$1}) { push @tran_evi, "Paper_evidence\t\"WBPaper$paperid{$1}\""; } }
    elsif ($evi =~ m/cgc:(\d+)/) { my $cgc = 'cgc' . $1; 
      if ($paperid{$cgc}) { push @tran_evi, "Paper_evidence\t\"WBPaper$paperid{$cgc}\""; } }
    elsif ($evi =~ m/pmid:(\d+)/) { my $pmid = 'pmid' . $1; 
      if ($paperid{$pmid}) { push @tran_evi, "Paper_evidence\t\"WBPaper$paperid{$pmid}\""; } }
    elsif ($evi =~ m/(GO:\d+)/) { 
      if ($existing_evidence{goterm}{$1}) { push @tran_evi, "GO_term_evidence\t\"$1\""; }
        else { print ERR "LINE $line HAS BAD GOTERM $1\n"; } }
    elsif ($evi =~ m/XX:/) { 1; }		# ignore placeholder
    else { print ERR "NOT a convertible evidence $evi in line $line\n"; }
  }
  foreach my $evi (@tran_evi) { $lines .= "$line\t$evi\n"; }
  return $lines;
} # sub attachEvi


sub populateExistingEvidence {          # get hash of valid wbpersons and wbpapers and go_terms
  my $result = $dbh->prepare( "SELECT * FROM two ORDER BY two" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    $existing_evidence{person}{$row[1]}++; } 
  $result = $dbh->prepare( "SELECT * FROM pap_status WHERE pap_status = 'valid'" );  
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { $existing_evidence{paper}{$row[0]}++; }
#   $result = $dbh->prepare( "SELECT * FROM gop_goid" );
#   $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
#   while (my @row = $result->fetchrow) {
#     $existing_evidence{goterm}{$row[1]}++; } 
  $result = $dbh->prepare( "SELECT * FROM obo_name_goid" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    $existing_evidence{goterm}{$row[0]}++; } 
#   $result = $dbh->prepare( "SELECT * FROM wpa ORDER BY wpa_timestamp" );  
#   $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
#   while (my @row = $result->fetchrow) {
#     if ($row[3] eq 'valid') { $existing_evidence{paper}{$row[0]}++; }
#       else { delete $existing_evidence{paper}{$row[0]}; } }
#   $result = $dbh->prepare( "SELECT * FROM got_goterm" );
#   $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
#   while (my @row = $result->fetchrow) {
#     $existing_evidence{goterm}{$row[0]}++; } 
} # sub populateExistingEvidence



__END__

format-version: 1.2
date: 02:11:2006 10:39
saved-by: carolbas
auto-generated-by: OBO-Edit 1.002
subsetdef: phenotype_slim_wb "WB phenotype slim"
synonymtypedef: three_letter_name "Short_name" BROAD
default-namespace: C_elegans_phenotype_ontology

[Term]
id: WBPhenotype0000000
name: chromosome_instability
is_a: WBPhenotype0000585 ! cell_homeostasis_metabolism_abnormal

[Term]
id: WBPhenotype0000001
name: body_posture_abnormal
def: "Characteristic sinusoidal body posture is altered." [WB:cab]
subset: phenotype_slim_wb
is_a: WBPhenotype0000525 ! organism_behavior_abnormal

[Term]
id: WBPhenotype0000002
name: kinker
is_a: WBPhenotype0004017 ! locomotor_coordination_abnormal

[Term]
id: WBPhenotype0000003
name: flattened_locomotion_path
is_a: WBPhenotype0000643 ! locomotion_abnormal

[Term]
id: WBPhenotype0000004
name: constitutive_egg_laying
def: "Eggs are laid in M9, normally an inhibitor of egg laying." [WB:cab]
comment: Liquid M9.
synonym: "Egl_c" BROAD three_letter_name []
is_a: WBPhenotype0000005 ! hyperactive_egg_laying

[Term]
id: WBPhenotype0000005
name: hyperactive_egg_laying
is_a: WBPhenotype0000640 ! egg_laying_abnormal

[Term]
id: WBPhenotype0000006
name: egg_laying_defective
def: "Eggs are laid at a slower rate, eggs are laid at a later stage, or worms fail to respond to a typical external stimulator of egg laying." [WB:cab, WB:WBPaper00004402, WB:WBPaper00004651, WB:WBPaper00005654, WB:WBPaper00006395, WB:WBPaper00024497, WB:WBPaper00025054]
synonym: "Egl_D" BROAD three_letter_name []
is_a: WBPhenotype0000640 ! egg_laying_abnormal

[Term]
id: WBPhenotype0000007
name: bag_of_worms
def: "A worm carcass is formed with retained eggs that hatch inside." [WB:cab]
is_a: WBPhenotype0000545 ! eggs_retained

[Term]
id: WBPhenotype0000008
name: anesthetic_hypersensitive
is_a: WBPhenotype0000010 ! hypersensitive_to_drug
is_a: WBPhenotype0000627 ! anesthetic_response_abnormal

[Term]
id: WBPhenotype0000009
name: anesthetic_resistant
is_a: WBPhenotype0000011 ! resistant_to_drug
is_a: WBPhenotype0000627 ! anesthetic_response_abnormal

[Term]
id: WBPhenotype0000010
name: hypersensitive_to_drug
is_a: WBPhenotype0000631 ! drug_response_abnormal

[Term]
id: WBPhenotype0000011
name: resistant_to_drug
is_a: WBPhenotype0000631 ! drug_response_abnormal

[Term]
id: WBPhenotype0000012
name: dauer_constitutive
def: "Any abnormality that results in the formation of dauer larvae under otherwise favorable environmental, or growth, conditions." [WB:kmva]
synonym: "Daf_c" BROAD three_letter_name []
is_a: WBPhenotype0000637 ! dauer_formation_abnormal

[Term]
id: WBPhenotype0000013
name: dauer_defective
def: "Any abnormality that results in failure to form dauer larvae under dauer-inducing conditions." [WB:kmva]
is_a: WBPhenotype0000637 ! dauer_formation_abnormal

[Term]
id: WBPhenotype0000014
name: cord_commissures_abnormal
is_a: WBPhenotype0001226 ! commissure_abnormal

[Term]
id: WBPhenotype0000015
name: chemotaxis_defective
def: "Failure to move towards typically attractive chemicals." [WB:cab]
is_a: WBPhenotype0000635 ! chemotaxis_abnormal

[Term]
id: WBPhenotype0000016
name: aldicarb_hypersensitive
synonym: "Hic" BROAD three_letter_name []
is_a: WBPhenotype0000500 ! acetylcholinesterase_inhibitor_hypersensitive

[Term]
id: WBPhenotype0000017
name: aldicarb_resistant
synonym: "Ric" BROAD three_letter_name []
is_a: WBPhenotype0000011 ! resistant_to_drug

[Term]
id: WBPhenotype0000018
name: pharyngeal_pumping_increased
is_a: WBPhenotype0001006 ! pharyngeal_pumping_rate_abnormal

[Term]
id: WBPhenotype0000019
name: pharyngeal_pumping_decreased
is_a: WBPhenotype0001006 ! pharyngeal_pumping_rate_abnormal

[Term]
id: WBPhenotype0000020
name: pharyngeal_pumping_irregular
is_a: WBPhenotype0001006 ! pharyngeal_pumping_rate_abnormal

[Term]
id: WBPhenotype0000021
name: squat
synonym: "Sqt" BROAD three_letter_name []
is_a: WBPhenotype0000231 ! body_size_abnormal

[Term]
id: WBPhenotype0000022
name: long
synonym: "Lon" BROAD three_letter_name []
is_a: WBPhenotype0000231 ! body_size_abnormal

[Term]
id: WBPhenotype0000023
name: serotonin_hypersensitive
is_a: WBPhenotype0000010 ! hypersensitive_to_drug

[Term]
id: WBPhenotype0000024
name: serotonin_resistant
is_a: WBPhenotype0000011 ! resistant_to_drug

[Term]
id: WBPhenotype0000025
name: blistered
def: "Blistering of cuticle." [WB:cab, WB:WBPaper00004402, WB:WBPaper00005654, WB:WBPaper00006395, WB:WBPaper00024497]
synonym: "Bli" BROAD three_letter_name []
is_a: WBPhenotype0000535 ! organism_morphology_abnormal
is_a: WBPhenotype0000703 ! epithelial_morphology_abnormal

[Term]
id: WBPhenotype0000026
name: lipid_depleted
synonym: "fat_depleted" RELATED []
synonym: "Lpd" RELATED []
is_a: WBPhenotype0001183 ! fat_content_reduced

[Term]
id: WBPhenotype0000027
name: organism_metabolism_processing_abnormal
is_a: WBPhenotype0000577 ! organism_homeostasis_metabolism_abnormal

[Term]
id: WBPhenotype0000028
name: RNA_processing_abnormal
is_a: WBPhenotype0000027 ! organism_metabolism_processing_abnormal

[Term]
id: WBPhenotype0000029
name: systemic_RNAi_abnormal
is_a: WBPhenotype0000743 ! RNAi_response_abnormal

[Term]
id: WBPhenotype0000030
name: growth_abnormal
is_a: WBPhenotype0000577 ! organism_homeostasis_metabolism_abnormal

[Term]
id: WBPhenotype0000031
name: slow_growth
def: "Developmental growth is retarded." [WB:cab, WB:WBPaper00004402, WB:WBPaper00004403, WB:WBPaper00004651, WB:WBPaper00004769, WB:WBPaper00005654, WB:WBPaper00006395, WB:WBPaper00024497]
synonym: "Gro" BROAD three_letter_name []
is_a: WBPhenotype0000030 ! growth_abnormal

[Term]
id: WBPhenotype0000032
name: sick
synonym: "Sck" BROAD three_letter_name []
is_a: WBPhenotype0000030 ! growth_abnormal

[Term]
id: WBPhenotype0000033
name: developmental_timing_abnormal
alt_id: WBPhenotype0000437
def: "The timing of specific developmental events in some tissues is altered relative to the timing of events in other tissues." [pmid:6494891, WB:cab]
comment: Alternate ID: WBPhenotype0000437
subset: phenotype_slim_wb
synonym: "heterochronic_defect" EXACT []
is_a: WBPhenotype0000531 ! organism_development_abnormal

[Term]
id: WBPhenotype0000034
name: embryonic_polarity_abnormal
is_a: WBPhenotype0000749 ! embryonic_development_abnormal

[Term]
id: WBPhenotype0000035
name: larval_body_morphology_abnormal
subset: phenotype_slim_wb
is_a: WBPhenotype0000934 ! developmental_morphology_abnormal

[Term]
id: WBPhenotype0000036
name: adult_body_morphology_abnormal
subset: phenotype_slim_wb
is_a: WBPhenotype0000934 ! developmental_morphology_abnormal

[Term]
id: WBPhenotype0000037
name: egg_morphology_abnormal
subset: phenotype_slim_wb
is_a: WBPhenotype0000934 ! developmental_morphology_abnormal

[Term]
id: WBPhenotype0000038
name: exploded_through_vulva
synonym: "gonad_exploded_through_vulva" RELATED []
synonym: "Rup" BROAD three_letter_name []
is_a: WBPhenotype0000577 ! organism_homeostasis_metabolism_abnormal

[Term]
id: WBPhenotype0000039
name: life_span_abnormal
def: "Life span is either longer or shorter than typical of wild-type animals." [WB:cab, WB:WBPaper00005863, WB:WBPaper00026717]
subset: phenotype_slim_wb
synonym: "Age" BROAD three_letter_name []
synonym: "longevity_abnormal" RELATED []
is_a: WBPhenotype0000576 ! organism_physiology_abnormal

[Term]
id: WBPhenotype0000040
name: one_cell_arrest_early_emb
def: "Embryos fail to divide and arrest as one-cell embryos." [WB:cab, WB:cgc5599]
synonym: "catastrophic_one_cell_arrest" RELATED [WB:cgc5599]
synonym: "Emb" BROAD three_letter_name []
synonym: "Ocs" BROAD three_letter_name []
is_a: WBPhenotype0001100 ! early_embryonic_lethal

[Term]
id: WBPhenotype0000041
name: osmotic_integrity_abnormal
is_a: WBPhenotype0000577 ! organism_homeostasis_metabolism_abnormal

[Term]
id: WBPhenotype0000042
name: slow_embryonic_development
synonym: "Sle" BROAD three_letter_name []
is_a: WBPhenotype0000749 ! embryonic_development_abnormal

[Term]
id: WBPhenotype0000043
name: general_pace_of_development_abnormal
subset: phenotype_slim_wb
is_a: WBPhenotype0000531 ! organism_development_abnormal
is_a: WBPhenotype0000576 ! organism_physiology_abnormal

[Term]
id: WBPhenotype0000044
name: egg_size_abnormal_early_emb
def: "Egg is smaller or larger than normal." [WB:cab, WB:cgc7141]
synonym: "Emb" BROAD three_letter_name []
is_a: WBPhenotype0000037 ! egg_morphology_abnormal
is_a: WBPhenotype0001100 ! early_embryonic_lethal

[Term]
id: WBPhenotype0000045
name: developmental_delay_postembryonic
def: "Postembryonic development is delayed compared with wild type." [WB:cab, WB:WBPaper00025054]
is_a: WBPhenotype0000049 ! postembryonic_development_abnormal

[Term]
id: WBPhenotype0000046
name: pace_of_p_lineage_abnormal_early_emb
def: "More than five minutes between AB and P1 divisions." [WB:cab, WB:cgc7141]
synonym: "Emb" BROAD three_letter_name []
is_a: WBPhenotype0000099 ! P_lineage_abnormal
is_a: WBPhenotype0000746 ! cell_division_abnormal

[Term]
id: WBPhenotype0000047
name: gastrulation_abnormal
is_a: WBPhenotype0000749 ! embryonic_development_abnormal

[Term]
id: WBPhenotype0000048
name: hatching_abnormal
is_a: WBPhenotype0000749 ! embryonic_development_abnormal

[Term]
id: WBPhenotype0000049
name: postembryonic_development_abnormal
subset: phenotype_slim_wb
is_a: WBPhenotype0000531 ! organism_development_abnormal

[Term]
id: WBPhenotype0000050
name: embryonic_lethal
def: "More than 10% of embryos die during embryonic development." [WB:cab, WB:WBPaper00004403, WB:WBPaper00004540, WB:WBPaper00004651, WB:WBPaper00004769, WB:WBPaper00005654, WB:WBPaper00024497, WB:WBPaper00024925, WB:WBPaper00025054]
subset: phenotype_slim_wb
synonym: "Emb" BROAD three_letter_name []
synonym: "embryonic_death" RELATED []
synonym: "Let" BROAD three_letter_name []
is_a: WBPhenotype0000062 ! lethal
is_a: WBPhenotype0000749 ! embryonic_development_abnormal

[Term]
id: WBPhenotype0000051
name: embryonic_terminal_arrest_variable_emb
synonym: "Emb" BROAD three_letter_name []
synonym: "Etv" RELATED []
is_a: WBPhenotype0000749 ! embryonic_development_abnormal

[Term]
id: WBPhenotype0000052
name: maternal_effect_lethal_emb
synonym: "Emb" BROAD three_letter_name []
synonym: "Mel" RELATED []
is_a: WBPhenotype0000050 ! embryonic_lethal

[Term]
id: WBPhenotype0000053
name: paralyzed_arrested_elongation_at_two_fold
def: "Mutant embryos do not move (wild-type embryos move soon after they reach the one-and-one-half-fold stage of elongation), and elongation in mutants arrests at the two-fold stage. Development in mutants continues (e.g. pharyngeal and cuticle formation is normal), but the myofilament lattice in body wall muscle cells is abnormal.  Embryos hatch as inviable larvae." [WB:cab, WB:cgc1894]
synonym: "active_elongation_arrest" RELATED []
synonym: "Pat" BROAD three_letter_name []
synonym: "two_fold_arrest" RELATED []
is_a: WBPhenotype0000050 ! embryonic_lethal
is_a: WBPhenotype0000494 ! two_fold_arrest

[Term]
id: WBPhenotype0000054
name: larval_lethal
subset: phenotype_slim_wb
synonym: "larval_death" RELATED []
synonym: "Let" BROAD three_letter_name []
synonym: "Lvl" BROAD three_letter_name []
is_a: WBPhenotype0000062 ! lethal

[Term]
id: WBPhenotype0000055
name: early_larval_arrest
def: "Larval arrest during the L1 or L2 stages of larval development." [WB:cab]
is_a: WBPhenotype0000059 ! larval_arrest

[Term]
id: WBPhenotype0000056
name: late_larval_arrest
def: "Larval arrest during the L3 or L4 stages of larval development." [WB:cab]
is_a: WBPhenotype0000059 ! larval_arrest

[Term]
id: WBPhenotype0000057
name: early_larval_lethal
synonym: "Let" BROAD three_letter_name []
synonym: "Lvl" BROAD three_letter_name []
is_a: WBPhenotype0000054 ! larval_lethal

[Term]
id: WBPhenotype0000058
name: late_larval_lethal
synonym: "Let" BROAD three_letter_name []
synonym: "Lvl" RELATED []
is_a: WBPhenotype0000054 ! larval_lethal

[Term]
id: WBPhenotype0000059
name: larval_arrest
synonym: "Lva" BROAD three_letter_name []
is_a: WBPhenotype0000750 ! larval_development_abnormal
is_a: WBPhenotype0001016 ! larval_growth_abnormal

[Term]
id: WBPhenotype0000060
name: adult_early_lethal
def: "Early lethality during the adult stage.  When applied to large-scale RNAi screens, this phenotype is present in at least 10% of analyzed worms (or at least 30% in the case of rrf-3)." [WB:cab, WB:WBPaper00004402, WB:WBPaper00005654, WB:WBPaper00006395]
subset: phenotype_slim_wb
synonym: "Adl" BROAD three_letter_name [WB:WBPaper00004402, WB:WBPaper00005654]
synonym: "Let" BROAD three_letter_name []
is_a: WBPhenotype0000062 ! lethal

[Term]
id: WBPhenotype0000061
name: extended_life_span
synonym: "Age" BROAD three_letter_name []
synonym: "longevity_increased" RELATED []
is_a: WBPhenotype0000039 ! life_span_abnormal

[Term]
id: WBPhenotype0000062
name: lethal
subset: phenotype_slim_wb
synonym: "Let" BROAD three_letter_name []
is_a: WBPhenotype0000531 ! organism_development_abnormal

[Term]
id: WBPhenotype0000063
name: terminal_arrest_variable
synonym: "Var" BROAD three_letter_name []
is_a: WBPhenotype0000062 ! lethal

[Term]
id: WBPhenotype0000064
name: sexually_dimorphic_lethality
is_a: WBPhenotype0000062 ! lethal

[Term]
id: WBPhenotype0000065
name: male_specific_lethality
subset: phenotype_slim_wb
is_a: WBPhenotype0000064 ! sexually_dimorphic_lethality

[Term]
id: WBPhenotype0000066
name: hermaphrodite_specific_lethality
subset: phenotype_slim_wb
is_a: WBPhenotype0000064 ! sexually_dimorphic_lethality

[Term]
id: WBPhenotype0000067
name: organism_stress_response_abnormal
is_a: WBPhenotype0000738 ! organism_environmental_stimulus_response_abnormal

[Term]
id: WBPhenotype0000068
name: oxidative_stress_response_abnormal
is_a: WBPhenotype0000142 ! cell_stress_response_abnormal

[Term]
id: WBPhenotype0000069
name: progeny_abnormal
subset: phenotype_slim_wb
is_a: WBPhenotype0000531 ! organism_development_abnormal

[Term]
id: WBPhenotype0000070
name: male_tail_abnormal
is_a: WBPhenotype0000073 ! tail_morphology_abnormal

[Term]
id: WBPhenotype0000071
name: head_morphology_abnormal
is_a: WBPhenotype0000582 ! organism_segment_morphology_abnormal

[Term]
id: WBPhenotype0000072
name: body_morphology_abnormal
subset: phenotype_slim_wb
is_a: WBPhenotype0000582 ! organism_segment_morphology_abnormal

[Term]
id: WBPhenotype0000073
name: tail_morphology_abnormal
is_a: WBPhenotype0000582 ! organism_segment_morphology_abnormal

[Term]
id: WBPhenotype0000074
name: genetic_pathway_abnormal
subset: phenotype_slim_wb
is_a: WBPhenotype0000576 ! organism_physiology_abnormal

[Term]
id: WBPhenotype0000075
name: cuticle_attachment_abnormal
is_a: WBPhenotype0000201 ! cuticle_development_abnormal

[Term]
id: WBPhenotype0000076
name: epithelial_attachment_abnormal
synonym: "hypodermal_attachment_abnormal" RELATED []
is_a: WBPhenotype0000608 ! epithelial_system_physiology_abnormal

[Term]
id: WBPhenotype0000077
name: cuticle_shedding_abnormal
is_a: WBPhenotype0000638 ! molt_defect

[Term]
id: WBPhenotype0000078
name: seam_cells_stacked
is_a: WBPhenotype0000703 ! epithelial_morphology_abnormal

[Term]
id: WBPhenotype0000079
name: branched_adult_alae
is_a: WBPhenotype0000948 ! cuticle_morphology_abnormal

[Term]
id: WBPhenotype0000080
name: no_anterior_pharynx
is_a: WBPhenotype0000115 ! anterior_pharynx_abnormal

[Term]
id: WBPhenotype0000081
name: L1_arrest
is_a: WBPhenotype0000055 ! early_larval_arrest
is_a: WBPhenotype0000751 ! L1_larval_development_abnormal

[Term]
id: WBPhenotype0000082
name: L2_arrest
is_a: WBPhenotype0000055 ! early_larval_arrest
is_a: WBPhenotype0000752 ! L2_larval_development_abnormal
is_a: WBPhenotype0001019 ! mid_larval_arrest

[Term]
id: WBPhenotype0000083
name: L3_arrest
is_a: WBPhenotype0000056 ! late_larval_arrest
is_a: WBPhenotype0000753 ! L3_larval_development_abnormal
is_a: WBPhenotype0001019 ! mid_larval_arrest

[Term]
id: WBPhenotype0000084
name: L4_arrest
is_a: WBPhenotype0000056 ! late_larval_arrest
is_a: WBPhenotype0000754 ! L4_larval_development_abnormal

[Term]
id: WBPhenotype0000085
name: swollen_intestine
is_a: WBPhenotype0000710 ! intestinal_morphology_abnormal

[Term]
id: WBPhenotype0000086
name: shrunken_intestine
is_a: WBPhenotype0000710 ! intestinal_morphology_abnormal

[Term]
id: WBPhenotype0000087
name: body_wall_cell_development_abnormal
is_a: WBPhenotype0000861 ! body_wall_muscle_development_abnormal

[Term]
id: WBPhenotype0000088
name: body_muscle_displaced
is_a: WBPhenotype0000861 ! body_wall_muscle_development_abnormal

[Term]
id: WBPhenotype0000089
name: alpha_amanitin_resistant
is_a: WBPhenotype0000011 ! resistant_to_drug

[Term]
id: WBPhenotype0000090
name: epidermis_cuticle_detached
synonym: "hypodermis_detached_from_cuticle" RELATED []
is_a: WBPhenotype0000075 ! cuticle_attachment_abnormal
is_a: WBPhenotype0000076 ! epithelial_attachment_abnormal

[Term]
id: WBPhenotype0000091
name: epidermis_muscle_detached
synonym: "hypodermis_detached_from_muscle" RELATED []
is_a: WBPhenotype0000076 ! epithelial_attachment_abnormal
is_a: WBPhenotype0000474 ! muscle_attachment_abnormal

[Term]
id: WBPhenotype0000092
name: intestinal_cell_proliferation_abnormal
is_a: WBPhenotype0000705 ! intestinal_cell_development_abnormal

[Term]
id: WBPhenotype0000093
name: lineage_abnormal
subset: phenotype_slim_wb
synonym: "Lin" BROAD three_letter_name []
is_a: WBPhenotype0000529 ! cell_development_abnormal

[Term]
id: WBPhenotype0000094
name: anus_development_abnormal
relationship: part_of WBPhenotype0000617 ! alimentary_system_development_abnormal

[Term]
id: WBPhenotype0000095
name: M_lineage_abnormal
is_a: WBPhenotype0000825 ! postembryonic_cell_lineage_abnormal

[Term]
id: WBPhenotype0000096
name: cloacal_development_abnormal
relationship: part_of WBPhenotype0000617 ! alimentary_system_development_abnormal

[Term]
id: WBPhenotype0000097
name: AB_lineage_abnormal
is_a: WBPhenotype0000824 ! embryonic_cell_lineage_abnormal

[Term]
id: WBPhenotype0000098
name: pharyngeal_intestinal_valve_development_abnormal
relationship: part_of WBPhenotype0000617 ! alimentary_system_development_abnormal

[Term]
id: WBPhenotype0000099
name: P_lineage_abnormal
is_a: WBPhenotype0000825 ! postembryonic_cell_lineage_abnormal

[Term]
id: WBPhenotype0000100
name: cell_UV_response_abnormal
is_a: WBPhenotype0000142 ! cell_stress_response_abnormal

[Term]
id: WBPhenotype0000101
name: UV_induced_apoptosis_increased
is_a: WBPhenotype0000100 ! cell_UV_response_abnormal
is_a: WBPhenotype0000183 ! apoptosis_enhanced

[Term]
id: WBPhenotype0000102
name: presynaptic_vesicle_clusters_abnormal
is_a: WBPhenotype0000846 ! presynaptic_region_physiology_abnormal

[Term]
id: WBPhenotype0000103
name: gut_granules_abnormal
is_a: WBPhenotype0000708 ! intestinal_development_abnormal

[Term]
id: WBPhenotype0000104
name: cell_polarity_abnormal
subset: phenotype_slim_wb
is_a: WBPhenotype0000529 ! cell_development_abnormal

[Term]
id: WBPhenotype0000105
name: oocyte_meiotic_maturation_abnormal
synonym: "Oma" BROAD three_letter_name []
is_a: WBPhenotype0000812 ! germ_cell_development_abnormal

[Term]
id: WBPhenotype0000106
name: inhibition_of_oocyte_maturation_abnormal
is_a: WBPhenotype0000105 ! oocyte_meiotic_maturation_abnormal

[Term]
id: WBPhenotype0000107
name: inhibition_of_ovulation_abnormal
is_a: WBPhenotype0000666 ! ovulation_abnormal

[Term]
id: WBPhenotype0000108
name: severe_dumpy
is_obsolete: true

[Term]
id: WBPhenotype0000109
name: moderate_dumpy
is_obsolete: true

[Term]
id: WBPhenotype0000110
name: slightly_dumpy
is_obsolete: true

[Term]
id: WBPhenotype0000111
name: pattern_of_gene_expression_abnormal
is_a: WBPhenotype0000717 ! gene_expression_abnormal

[Term]
id: WBPhenotype0000112
name: protein_expression_abnormal
is_a: WBPhenotype0000717 ! gene_expression_abnormal

[Term]
id: WBPhenotype0000113
name: RNA_expression_abnormal
is_a: WBPhenotype0000717 ! gene_expression_abnormal

[Term]
id: WBPhenotype0000114
name: mRNA_expression_abnormal
is_a: WBPhenotype0000113 ! RNA_expression_abnormal

[Term]
id: WBPhenotype0000115
name: anterior_pharynx_abnormal
is_a: WBPhenotype0000707 ! pharyngeal_development_abnormal

[Term]
id: WBPhenotype0000116
name: mid_larval_lethal
synonym: "Let" BROAD three_letter_name []
synonym: "Lvl" RELATED []
is_a: WBPhenotype0000054 ! larval_lethal

[Term]
id: WBPhenotype0000117
name: L1_lethal
synonym: "Let" BROAD three_letter_name []
synonym: "Lvl" BROAD three_letter_name []
is_a: WBPhenotype0000057 ! early_larval_lethal

[Term]
id: WBPhenotype0000118
name: L2_lethal
synonym: "Let" BROAD three_letter_name []
synonym: "Lvl" RELATED []
is_a: WBPhenotype0000057 ! early_larval_lethal
is_a: WBPhenotype0000116 ! mid_larval_lethal

[Term]
id: WBPhenotype0000119
name: protein_expression_levels_high
is_a: WBPhenotype0000112 ! protein_expression_abnormal

[Term]
id: WBPhenotype0000120
name: protein_expression_levels_reduced
def: "Any change that results in lower than normal levels of protein expression." [WB:kmva]
is_a: WBPhenotype0000112 ! protein_expression_abnormal

[Term]
id: WBPhenotype0000121
name: translation_abnormal
is_a: WBPhenotype0000112 ! protein_expression_abnormal

[Term]
id: WBPhenotype0000122
name: post_translational_processing_abnormal
is_a: WBPhenotype0000027 ! organism_metabolism_processing_abnormal

[Term]
id: WBPhenotype0000123
name: enzyme_expression_levels_reduced
is_a: WBPhenotype0000120 ! protein_expression_levels_reduced

[Term]
id: WBPhenotype0000124
name: enzyme_activity_low
is_a: WBPhenotype0000727 ! enzyme_activity_abnormal

[Term]
id: WBPhenotype0000125
name: enzyme_activity_high
is_a: WBPhenotype0000727 ! enzyme_activity_abnormal

[Term]
id: WBPhenotype0000126
name: general_pace_of_development_abnormal_early_emb
def: "More than 30 minutes from PN meeting to furrow initiation in AB." [WB:cab, WB:cgc7141]
synonym: "Emb" BROAD three_letter_name []
is_a: WBPhenotype0000043 ! general_pace_of_development_abnormal
is_a: WBPhenotype0001186 ! delayed_at_pronuclear_contact_early_emb

[Term]
id: WBPhenotype0000127
name: dauer_recovery_abnormal
def: "Characteristic exit fro mthe dauer stage is altered." [WB:cab]
is_a: WBPhenotype0000049 ! postembryonic_development_abnormal
is_a: WBPhenotype0001001 ! dauer_behavior_abnormal

[Term]
id: WBPhenotype0000128
name: temperature_induced_dauer_formation_enhanced
def: "Dauer larvae are more likely to form at high temperature, even in the presence of food." [WB:cgc424]
synonym: "Hid" BROAD three_letter_name []
is_a: WBPhenotype0000639 ! temperature_induced_dauer_formation_abnormal

[Term]
id: WBPhenotype0000129
name: temperature_induced_dauer_formation_defective
is_a: WBPhenotype0000013 ! dauer_defective
is_a: WBPhenotype0000639 ! temperature_induced_dauer_formation_abnormal

[Term]
id: WBPhenotype0000130
name: pheromone_induced_dauer_formation_enhance
is_a: WBPhenotype0000132 ! pheromone_induced_dauer_formation_abnormal

[Term]
id: WBPhenotype0000131
name: pheromone_induced_dauer_formation_defective
is_a: WBPhenotype0000013 ! dauer_defective
is_a: WBPhenotype0000132 ! pheromone_induced_dauer_formation_abnormal

[Term]
id: WBPhenotype0000132
name: pheromone_induced_dauer_formation_abnormal
is_a: WBPhenotype0000637 ! dauer_formation_abnormal

[Term]
id: WBPhenotype0000133
name: expression_of_lipogenic_enzymes_reduced
is_a: WBPhenotype0000123 ! enzyme_expression_levels_reduced

[Term]
id: WBPhenotype0000134
name: gene_expression_levels_reduced
is_a: WBPhenotype0000717 ! gene_expression_abnormal

[Term]
id: WBPhenotype0000135
name: gene_expression_levels_high
is_a: WBPhenotype0000717 ! gene_expression_abnormal

[Term]
id: WBPhenotype0000136
name: mRNA_levels_high
is_a: WBPhenotype0000114 ! mRNA_expression_abnormal

[Term]
id: WBPhenotype0000137
name: mRNA_levels_low
is_a: WBPhenotype0000114 ! mRNA_expression_abnormal

[Term]
id: WBPhenotype0000138
name: lipid_composition_abnormal
synonym: "fat_composition_abnormal" RELATED []
synonym: "fatty_acid_composition_abnormal" RELATED []
is_a: WBPhenotype0000725 ! lipid_metabolism_abnormal

[Term]
id: WBPhenotype0000139
name: stress_induced_lethality_abnormal
is_a: WBPhenotype0000067 ! organism_stress_response_abnormal

[Term]
id: WBPhenotype0000140
name: stress_induced_arrest_abnormal
is_a: WBPhenotype0000067 ! organism_stress_response_abnormal

[Term]
id: WBPhenotype0000141
name: stress_induced_lethality_enhanced
is_a: WBPhenotype0000139 ! stress_induced_lethality_abnormal

[Term]
id: WBPhenotype0000142
name: cell_stress_response_abnormal
is_a: WBPhenotype0000585 ! cell_homeostasis_metabolism_abnormal

[Term]
id: WBPhenotype0000143
name: organism_UV_response_abnormal
is_a: WBPhenotype0000067 ! organism_stress_response_abnormal

[Term]
id: WBPhenotype0000144
name: salmonella_induced_cell_death_enhanced
is_a: WBPhenotype0000142 ! cell_stress_response_abnormal
is_a: WBPhenotype0001269 ! salmonella_induced_cell_death_abnormal

[Term]
id: WBPhenotype0000145
name: fertility_abnormal
subset: phenotype_slim_wb
is_a: WBPhenotype0000613 ! reproductive_system_physiology_abnormal

[Term]
id: WBPhenotype0000146
name: organism_temperature_response_abnormal
is_a: WBPhenotype0000067 ! organism_stress_response_abnormal

[Term]
id: WBPhenotype0000147
name: organism_starvation_response_abnormal
is_a: WBPhenotype0000067 ! organism_stress_response_abnormal

[Term]
id: WBPhenotype0000148
name: starvation_induced_dauer_formation_abnormal
is_a: WBPhenotype0000147 ! organism_starvation_response_abnormal
is_a: WBPhenotype0000637 ! dauer_formation_abnormal

[Term]
id: WBPhenotype0000149
name: starvation_induced_dauer_formation_enhanced
is_a: WBPhenotype0000148 ! starvation_induced_dauer_formation_abnormal

[Term]
id: WBPhenotype0000150
name: starvation_induced_dauer_formation_defective
is_a: WBPhenotype0000013 ! dauer_defective
is_a: WBPhenotype0000148 ! starvation_induced_dauer_formation_abnormal

[Term]
id: WBPhenotype0000151
name: anterior_pharynx_extra_cells
is_a: WBPhenotype0000115 ! anterior_pharynx_abnormal

[Term]
id: WBPhenotype0000152
name: no_cleavage_furrow_first_division_early_emb
synonym: "Emb" BROAD three_letter_name []
is_a: WBPhenotype0001129 ! cleavage_furrow_abnormal_early_emb

[Term]
id: WBPhenotype0000153
name: body_wall_contraction_abnormal
relationship: part_of WBPhenotype0000596 ! body_behavior_abnormal

[Term]
id: WBPhenotype0000154
name: reduced_brood_size
is_a: WBPhenotype0000673 ! brood_size_abnormal

[Term]
id: WBPhenotype0000155
name: cell_polarity_reversed
is_a: WBPhenotype0000104 ! cell_polarity_abnormal

[Term]
id: WBPhenotype0000156
name: body_wall_contraction_interval_abnormal
is_a: WBPhenotype0000210 ! defecation_contraction_abnormal

[Term]
id: WBPhenotype0000157
name: pos_body_wall_contraction_abnormal
synonym: "pBoc" BROAD three_letter_name []
synonym: "posterior_body_contraction_abnormal" RELATED []
synonym: "posterior_body_wall_contraction_defective" RELATED []
is_a: WBPhenotype0000210 ! defecation_contraction_abnormal

[Term]
id: WBPhenotype0000158
name: pos_body_wall_shortened_interval
is_a: WBPhenotype0000157 ! pos_body_wall_contraction_abnormal

[Term]
id: WBPhenotype0000159
name: dauer_arrest_abnormal
is_a: WBPhenotype0000308 ! dauer_development_abnormal

[Term]
id: WBPhenotype0000160
name: cleavage_furrow_not_discrete_early_emb
synonym: "Emb" BROAD three_letter_name []
is_a: WBPhenotype0001129 ! cleavage_furrow_abnormal_early_emb

[Term]
id: WBPhenotype0000161
name: nuclear_rotation_abnormal
is_a: WBPhenotype0000749 ! embryonic_development_abnormal

[Term]
id: WBPhenotype0000162
name: pale_larva
synonym: "translucent" RELATED []
is_a: WBPhenotype0000890 ! larval_pigmentation_abnormal
is_a: WBPhenotype0001261 ! pale

[Term]
id: WBPhenotype0000163
name: clear_larva
synonym: "Clr" BROAD three_letter_name []
synonym: "transparent" RELATED []
is_a: WBPhenotype0000890 ! larval_pigmentation_abnormal

[Term]
id: WBPhenotype0000164
name: thin
synonym: "slim" RELATED []
is_a: WBPhenotype0000231 ! body_size_abnormal

[Term]
id: WBPhenotype0000165
name: cell_fusion_abnormal
subset: phenotype_slim_wb
is_a: WBPhenotype0000529 ! cell_development_abnormal

[Term]
id: WBPhenotype0000166
name: seam_cell_fusion_abnormal
is_a: WBPhenotype0000165 ! cell_fusion_abnormal

[Term]
id: WBPhenotype0000167
name: precocious_seam_cell_fusion
is_a: WBPhenotype0000166 ! seam_cell_fusion_abnormal

[Term]
id: WBPhenotype0000168
name: alae_secretion_abnormal
is_a: WBPhenotype0000258 ! cell_secretion_abnormal

[Term]
id: WBPhenotype0000169
name: early_exit_cell_cycle
is_a: WBPhenotype0000740 ! cell_cycle_abnormal

[Term]
id: WBPhenotype0000170
name: precocious_alae_secretion
is_a: WBPhenotype0000168 ! alae_secretion_abnormal

[Term]
id: WBPhenotype0000171
name: cell_proliferation_abnormal
subset: phenotype_slim_wb
is_a: WBPhenotype0000529 ! cell_development_abnormal

[Term]
id: WBPhenotype0000172
name: increased_cell_proliferation
is_a: WBPhenotype0000171 ! cell_proliferation_abnormal

[Term]
id: WBPhenotype0000173
name: decreased_cell_proliferation
is_a: WBPhenotype0000171 ! cell_proliferation_abnormal

[Term]
id: WBPhenotype0000174
name: basal_lamina_development_abnormal
relationship: part_of WBPhenotype0000619 ! epithelial_system_development_abnormal

[Term]
id: WBPhenotype0000175
name: hypercontracted
is_a: WBPhenotype0000001 ! body_posture_abnormal
is_a: WBPhenotype0000644 ! paralyzed

[Term]
id: WBPhenotype0000176
name: satiety_behavior_abnormal
is_a: WBPhenotype0000659 ! feeding_behavior_abnormal

[Term]
id: WBPhenotype0000177
name: acetylcholinesterase_reduced
is_a: WBPhenotype0000124 ! enzyme_activity_low

[Term]
id: WBPhenotype0000178
name: cell_degeneration
is_a: WBPhenotype0000729 ! cell_death_abnormal

[Term]
id: WBPhenotype0000179
name: neuron_degeneration
is_a: WBPhenotype0000178 ! cell_degeneration

[Term]
id: WBPhenotype0000180
name: axon_morphology_abnormal
is_a: WBPhenotype0000905 ! neuron_morphology_abnormal

[Term]
id: WBPhenotype0000181
name: axon_trajectory_abnormal
relationship: part_of WBPhenotype0000180 ! axon_morphology_abnormal

[Term]
id: WBPhenotype0000182
name: apoptosis_reduced
is_a: WBPhenotype0000730 ! apoptosis_abnormal

[Term]
id: WBPhenotype0000183
name: apoptosis_enhanced
is_a: WBPhenotype0000730 ! apoptosis_abnormal

[Term]
id: WBPhenotype0000184
name: apoptosis_fails_to_occur
is_a: WBPhenotype0000730 ! apoptosis_abnormal

[Term]
id: WBPhenotype0000185
name: apoptosis_protracted
is_a: WBPhenotype0000730 ! apoptosis_abnormal

[Term]
id: WBPhenotype0000186
name: oogenesis_abnormal
synonym: "oocyte_development_abnormal" RELATED []
is_a: WBPhenotype0000774 ! gametogenesis_abnormal

[Term]
id: WBPhenotype0000187
name: egg_round
is_a: WBPhenotype0000037 ! egg_morphology_abnormal

[Term]
id: WBPhenotype0000188
name: gonad_arm_morphology_abnormal
is_a: WBPhenotype0000977 ! somatic_gonad_morphology_abnormal

[Term]
id: WBPhenotype0000189
name: hypodermis_disorganized
is_a: WBPhenotype0000703 ! epithelial_morphology_abnormal

[Term]
id: WBPhenotype0000190
name: no_dauer_recovery
is_a: WBPhenotype0000127 ! dauer_recovery_abnormal

[Term]
id: WBPhenotype0000191
name: organism_crowding_response_abnormal
is_a: WBPhenotype0000067 ! organism_stress_response_abnormal

[Term]
id: WBPhenotype0000192
name: constitutive_enzyme_activity
is_a: WBPhenotype0000125 ! enzyme_activity_high

[Term]
id: WBPhenotype0000193
name: dominant_negative_enzyme
is_a: WBPhenotype0000727 ! enzyme_activity_abnormal

[Term]
id: WBPhenotype0000194
name: first_polar_body_position_abnormal
is_a: WBPhenotype0000775 ! meiosis_abnormal

[Term]
id: WBPhenotype0000195
name: distal_tip_cell_migration_abnormal
synonym: "DTC_migration_abnormal" RELATED []
is_a: WBPhenotype0000594 ! cell_migration_abnormal

[Term]
id: WBPhenotype0000196
name: distal_tip_cell_morphology_abnormal
is_a: WBPhenotype0000533 ! cell_morphology_abnormal

[Term]
id: WBPhenotype0000197
name: cell_induction_abnormal
is_a: WBPhenotype0000216 ! cell_fate_specification_abnormal

[Term]
id: WBPhenotype0000198
name: vulval_precursor_cell_induction_abnormal
is_a: WBPhenotype0000220 ! vulva_cell_fate_specification_abnormal

[Term]
id: WBPhenotype0000199
name: male_tail_sensory_ray_development_abnormal
relationship: part_of WBPhenotype0001008 ! male_nervous_system_development_abnormal

[Term]
id: WBPhenotype0000200
name: pericellular_component_development_abnormal
subset: phenotype_slim_wb
is_a: WBPhenotype0000518 ! development_abnormal

[Term]
id: WBPhenotype0000201
name: cuticle_development_abnormal
is_a: WBPhenotype0000200 ! pericellular_component_development_abnormal

[Term]
id: WBPhenotype0000202
name: alae_abnormal
is_a: WBPhenotype0000201 ! cuticle_development_abnormal

[Term]
id: WBPhenotype0000203
name: odorant_adaptation_abnormal
is_a: WBPhenotype0001040 ! chemosensory_response_abnormal

[Term]
id: WBPhenotype0000204
name: anterior_body_contraction_defect
synonym: "aBoc" BROAD three_letter_name []
is_a: WBPhenotype0000210 ! defecation_contraction_abnormal

[Term]
id: WBPhenotype0000205
name: expulsion_abnormal
synonym: "Exp" RELATED []
is_a: WBPhenotype0000210 ! defecation_contraction_abnormal

[Term]
id: WBPhenotype0000206
name: autosomal_nondisjunction_meiosis
is_a: WBPhenotype0001174 ! chromosome_disjunction_abnormal

[Term]
id: WBPhenotype0000207
name: defecation_cycle_abnormal
is_a: WBPhenotype0000650 ! defecation_abnormal

[Term]
id: WBPhenotype0000208
name: long_defecation_cycle
is_a: WBPhenotype0000207 ! defecation_cycle_abnormal

[Term]
id: WBPhenotype0000209
name: short_defecation_cycle
is_a: WBPhenotype0000207 ! defecation_cycle_abnormal

[Term]
id: WBPhenotype0000210
name: defecation_contraction_abnormal
is_a: WBPhenotype0000650 ! defecation_abnormal

[Term]
id: WBPhenotype0000211
name: defecation_contraction_mistimed
is_a: WBPhenotype0000210 ! defecation_contraction_abnormal

[Term]
id: WBPhenotype0000212
name: body_constriction
is_a: WBPhenotype0000072 ! body_morphology_abnormal

[Term]
id: WBPhenotype0000213
name: zygotic_development_abnormal
is_a: WBPhenotype0000749 ! embryonic_development_abnormal

[Term]
id: WBPhenotype0000214
name: alpha_amanitin_hypersensitive
is_a: WBPhenotype0000010 ! hypersensitive_to_drug

[Term]
id: WBPhenotype0000215
name: no_germline
is_a: WBPhenotype0000812 ! germ_cell_development_abnormal

[Term]
id: WBPhenotype0000216
name: cell_fate_specification_abnormal
def: "Any abnormality in the processes that govern acquisition of particular cell fates." [WB:kmva]
subset: phenotype_slim_wb
is_a: WBPhenotype0000529 ! cell_development_abnormal

[Term]
id: WBPhenotype0000217
name: prolonged_pharyngeal_contraction
is_a: WBPhenotype0000980 ! pharyngeal_contraction_abnormal

[Term]
id: WBPhenotype0000218
name: vulval_cell_induction_increased
is_a: WBPhenotype0001272 ! vulval_cell_induction_abnormal

[Term]
id: WBPhenotype0000219
name: vulval_cell_induction_reduced
is_a: WBPhenotype0001272 ! vulval_cell_induction_abnormal
relationship: part_of WBPhenotype0000698 ! vulvaless

[Term]
id: WBPhenotype0000220
name: vulva_cell_fate_specification_abnormal
is_a: WBPhenotype0000216 ! cell_fate_specification_abnormal
is_a: WBPhenotype0000699 ! vulva_development_abnormal

[Term]
id: WBPhenotype0000221
name: neurotransmitter_metabolism_abnormal
is_a: WBPhenotype0000027 ! organism_metabolism_processing_abnormal

[Term]
id: WBPhenotype0000222
name: serotonin_metabolism_abnormal
is_a: WBPhenotype0000221 ! neurotransmitter_metabolism_abnormal

[Term]
id: WBPhenotype0000223
name: acetylcholine_metabolism_abnormal
is_a: WBPhenotype0000221 ! neurotransmitter_metabolism_abnormal

[Term]
id: WBPhenotype0000224
name: serotonin_deficient
is_a: WBPhenotype0000222 ! serotonin_metabolism_abnormal

[Term]
id: WBPhenotype0000225
name: serotonin_synthesis_defective
is_a: WBPhenotype0000222 ! serotonin_metabolism_abnormal

[Term]
id: WBPhenotype0000226
name: serotonin_catabolism_defective
is_a: WBPhenotype0000222 ! serotonin_metabolism_abnormal

[Term]
id: WBPhenotype0000227
name: male_turning_abnormal
def: "The inability of a male to properly turn, via a sharp ventral arch of the tail, as he approaches either the hermaphrodite head or tail during mating." [WB:WBPaper00000392, WB:WBPaper00002109]
is_a: WBPhenotype0004006 ! post_hermaphrodite_contact_abnormal

[Term]
id: WBPhenotype0000228
name: spontaneous_mutation_rate_increased
synonym: "Mut" RELATED []
synonym: "mutator" RELATED []
is_a: WBPhenotype0000577 ! organism_homeostasis_metabolism_abnormal

[Term]
id: WBPhenotype0000229
name: small
alt_id: WBPhenotype0000271
synonym: "body_size_reduced" EXACT []
synonym: "Sma" RELATED []
is_a: WBPhenotype0000231 ! body_size_abnormal

[Term]
id: WBPhenotype0000230
name: tail_withered
is_a: WBPhenotype0000073 ! tail_morphology_abnormal

[Term]
id: WBPhenotype0000231
name: body_size_abnormal
is_a: WBPhenotype0000072 ! body_morphology_abnormal

[Term]
id: WBPhenotype0000232
name: CAN_cell_migration_abnormal
is_a: WBPhenotype0000594 ! cell_migration_abnormal

[Term]
id: WBPhenotype0000233
name: dopamine_metabolism_abnormal
is_a: WBPhenotype0000221 ! neurotransmitter_metabolism_abnormal

[Term]
id: WBPhenotype0000234
name: dopamine_deficient
is_a: WBPhenotype0000233 ! dopamine_metabolism_abnormal

[Term]
id: WBPhenotype0000235
name: dopamine_synthesis_defective
is_a: WBPhenotype0000233 ! dopamine_metabolism_abnormal

[Term]
id: WBPhenotype0000236
name: dopamine_catabolism_defective
is_a: WBPhenotype0000233 ! dopamine_metabolism_abnormal

[Term]
id: WBPhenotype0000237
name: foraging_hyperactive
is_a: WBPhenotype0000662 ! foraging_behavior_abnormal

[Term]
id: WBPhenotype0000238
name: foraging_reduced
is_a: WBPhenotype0000662 ! foraging_behavior_abnormal

[Term]
id: WBPhenotype0000239
name: vulval_cell_lineage_abnormal
synonym: "VPC_lineage_abnormal" RELATED []
is_a: WBPhenotype0000099 ! P_lineage_abnormal

[Term]
id: WBPhenotype0000240
name: decreased_blast_cell_proliferation
is_a: WBPhenotype0000173 ! decreased_cell_proliferation

[Term]
id: WBPhenotype0000241
name: accumulated_cell_corpses
is_a: WBPhenotype0000590 ! cell_corpse_number_abnormal

[Term]
id: WBPhenotype0000242
name: body_elongation_defect
is_a: WBPhenotype0000749 ! embryonic_development_abnormal

[Term]
id: WBPhenotype0000243
name: engulfment_failure_by_killer
is_a: WBPhenotype0000885 ! engulfment_abnormal

[Term]
id: WBPhenotype0000244
name: apoptotic_arrest
synonym: "apoptosis_block" RELATED []
is_a: WBPhenotype0000730 ! apoptosis_abnormal

[Term]
id: WBPhenotype0000245
name: SM_migration_abnormal
is_a: WBPhenotype0000594 ! cell_migration_abnormal

[Term]
id: WBPhenotype0000246
name: defecation_cycle_variable_length
is_a: WBPhenotype0000207 ! defecation_cycle_abnormal

[Term]
id: WBPhenotype0000247
name: sodium_chemotaxis_defective
def: "Failure to move towards sodium." [WB:cab, WB:cgc387]
synonym: "Na_chemotaxis_defective" RELATED []
is_a: WBPhenotype0001051 ! cation_chemotaxis_defective

[Term]
id: WBPhenotype0000248
name: sensory_neuroanatomy_abnormal
is_obsolete: true

[Term]
id: WBPhenotype0000249
name: osmotic_avoidance_defect
is_a: WBPhenotype0000663 ! osmotic_avoidance_abnormal

[Term]
id: WBPhenotype0000250
name: octopamine_metabolism_abnormal
is_a: WBPhenotype0000221 ! neurotransmitter_metabolism_abnormal

[Term]
id: WBPhenotype0000251
name: octopamine_deficient
is_a: WBPhenotype0000250 ! octopamine_metabolism_abnormal

[Term]
id: WBPhenotype0000252
name: caffeine_resistant
is_a: WBPhenotype0000011 ! resistant_to_drug

[Term]
id: WBPhenotype0000253
name: movement_erratic
synonym: "movement_irregular" RELATED []
is_a: WBPhenotype0001206 ! movement_abnormal

[Term]
id: WBPhenotype0000254
name: chloride_chemotaxis_defective
def: "Failure to move towards chloride." [WB:cab, WB:cgc387]
synonym: "Cl_chemotaxis_defective" RELATED []
is_a: WBPhenotype0001052 ! anion_chemotaxis_defective

[Term]
id: WBPhenotype0000255
name: amphid_phasmid_morphology_abnormal
synonym: "dye_filling_defect" RELATED []
synonym: "Dyf" BROAD three_letter_name []
is_a: WBPhenotype0000299 ! chemosensory_cell_morphology_abnormal

[Term]
id: WBPhenotype0000256
name: amphid_morphology_abnormal
is_a: WBPhenotype0000255 ! amphid_phasmid_morphology_abnormal

[Term]
id: WBPhenotype0000257
name: phasmid_morphology_abnormal
is_a: WBPhenotype0000255 ! amphid_phasmid_morphology_abnormal

[Term]
id: WBPhenotype0000258
name: cell_secretion_abnormal
alt_id: WBPhenotype0000723
subset: phenotype_slim_wb
synonym: "cellular_secretion_abnormal" EXACT []
is_a: WBPhenotype0000536 ! cell_physiology_abnormal

[Term]
id: WBPhenotype0000259
name: sheath_cell_secretion_abnormal
is_a: WBPhenotype0000258 ! cell_secretion_abnormal

[Term]
id: WBPhenotype0000260
name: sheath_cell_secretion_failure
is_a: WBPhenotype0000259 ! sheath_cell_secretion_abnormal

[Term]
id: WBPhenotype0000261
name: amphid_sheath_secretion_failure
is_a: WBPhenotype0000260 ! sheath_cell_secretion_failure

[Term]
id: WBPhenotype0000262
name: axoneme_morphology_abnormal
is_a: WBPhenotype0000615 ! cilia_morphology_abnormal

[Term]
id: WBPhenotype0000263
name: axoneme_short
is_a: WBPhenotype0000262 ! axoneme_morphology_abnormal

[Term]
id: WBPhenotype0000264
name: camp_chemotaxis_defective
def: "Characteristic movement towards cAMP is altered." [WB:cab, WB:cgc387]
is_a: WBPhenotype0001053 ! cyclic_nucleotide_chemotaxis_defective

[Term]
id: WBPhenotype0000265
name: volatile_odorant_chemotaxis_defective
def: "Failure to move towards typically attractive volatile organic molecules, sensed by the AWA and AWC neurons." [WB:cab, WB:cgc1786]
is_a: WBPhenotype0000015 ! chemotaxis_defective
is_a: WBPhenotype0001048 ! volatile_chemosensory_response_abnormal

[Term]
id: WBPhenotype0000266
name: cell_cleavage_abnormal
is_a: WBPhenotype0000746 ! cell_division_abnormal

[Term]
id: WBPhenotype0000267
name: cell_cleavage_delayed
is_a: WBPhenotype0000266 ! cell_cleavage_abnormal

[Term]
id: WBPhenotype0000268
name: P_cell_cleavage_delayed
is_a: WBPhenotype0000267 ! cell_cleavage_delayed

[Term]
id: WBPhenotype0000269
name: unclassified
subset: phenotype_slim_wb
is_a: WBPhenotype0000886 ! Abnormal

[Term]
id: WBPhenotype0000270
name: pleiotropic_defects_severe_early_emb
def: "Often multiple pronuclei, aberrant cytoplasmic texture, drop in overall pace of development, osmotic sensitivity." [WB:cab, WB:cgc7141]
synonym: "Emb" BROAD three_letter_name []
is_a: WBPhenotype0001007 ! other_abnormality_early_emb

[Term]
id: WBPhenotype0000272
name: egg_laying_irregular
is_a: WBPhenotype0000640 ! egg_laying_abnormal

[Term]
id: WBPhenotype0000273
name: thrashing_defect
def: "The number of body thrashes in a given period of time are reduced compared with wild-type worms." [WB:cab, WB:cgc7388]
is_a: WBPhenotype0001206 ! movement_abnormal

[Term]
id: WBPhenotype0000274
name: dead_eggs_laid
is_a: WBPhenotype0000640 ! egg_laying_abnormal
is_a: WBPhenotype0000806 ! hermaphrodite_fertility_abnormal

[Term]
id: WBPhenotype0000275
name: organism_UV_hypersensitive
is_a: WBPhenotype0000143 ! organism_UV_response_abnormal

[Term]
id: WBPhenotype0000276
name: organism_X_ray_response_abnormal
is_a: WBPhenotype0000686 ! organism_ionizing_radiation_response_abnormal

[Term]
id: WBPhenotype0000277
name: rhythms_slow
subset: phenotype_slim_wb
is_a: WBPhenotype0000525 ! organism_behavior_abnormal

[Term]
id: WBPhenotype0000278
name: body_region_pigmentation_abnormal
is_a: WBPhenotype0000521 ! pigmentation_abnormal

[Term]
id: WBPhenotype0000279
name: spicule_insertion_defective
is_a: WBPhenotype0004006 ! post_hermaphrodite_contact_abnormal

[Term]
id: WBPhenotype0000280
name: breaks_in_alae
is_a: WBPhenotype0000948 ! cuticle_morphology_abnormal

[Term]
id: WBPhenotype0000281
name: male_sex_muscle_abnormal
is_a: WBPhenotype0000669 ! sex_muscle_abnormal

[Term]
id: WBPhenotype0000282
name: hermaphrodite_sex_muscle_abnormal
is_a: WBPhenotype0000669 ! sex_muscle_abnormal

[Term]
id: WBPhenotype0000283
name: vulva_uterus_connection_defect
relationship: part_of WBPhenotype0000624 ! reproductive_system_development_abnormal

[Term]
id: WBPhenotype0000284
name: sperm_transfer_defective
is_a: WBPhenotype0004006 ! post_hermaphrodite_contact_abnormal

[Term]
id: WBPhenotype0000285
name: ray_tips_swollen
is_a: WBPhenotype0000505 ! male_ray_morphology_abnormal

[Term]
id: WBPhenotype0000286
name: embryo_disorganized
is_a: WBPhenotype0000749 ! embryonic_development_abnormal

[Term]
id: WBPhenotype0000287
name: vulval_invagination_L4_abnormal
is_a: WBPhenotype0000699 ! vulva_development_abnormal

[Term]
id: WBPhenotype0000288
name: distal_germline_abnormal
is_a: WBPhenotype0000812 ! germ_cell_development_abnormal

[Term]
id: WBPhenotype0000289
name: uterus_morphology_abnormal
relationship: part_of WBPhenotype0000605 ! reproductive_system_morphology_abnormal

[Term]
id: WBPhenotype0000290
name: no_sperm
is_a: WBPhenotype0000395 ! no_differentiated_gametes

[Term]
id: WBPhenotype0000291
name: no_oocytes
is_a: WBPhenotype0000395 ! no_differentiated_gametes

[Term]
id: WBPhenotype0000292
name: organ_system_pigmentation_abnormal
is_a: WBPhenotype0000521 ! pigmentation_abnormal

[Term]
id: WBPhenotype0000293
name: alimentary_system_pigmentation_abnormal
is_a: WBPhenotype0000292 ! organ_system_pigmentation_abnormal

[Term]
id: WBPhenotype0000294
name: intestine_dark
relationship: part_of WBPhenotype0000293 ! alimentary_system_pigmentation_abnormal

[Term]
id: WBPhenotype0000295
name: thermotolerance_increased
is_a: WBPhenotype0000146 ! organism_temperature_response_abnormal

[Term]
id: WBPhenotype0000296
name: spicules_crumpled
is_a: WBPhenotype0000605 ! reproductive_system_morphology_abnormal

[Term]
id: WBPhenotype0000297
name: rays_fused
is_a: WBPhenotype0000505 ! male_ray_morphology_abnormal

[Term]
id: WBPhenotype0000298
name: rays_displaced
is_a: WBPhenotype0000505 ! male_ray_morphology_abnormal

[Term]
id: WBPhenotype0000299
name: chemosensory_cell_morphology_abnormal
is_a: WBPhenotype0000905 ! neuron_morphology_abnormal

[Term]
id: WBPhenotype0000300
name: amphid_sheath_cell_morphology_abnormal
is_a: WBPhenotype0000299 ! chemosensory_cell_morphology_abnormal

[Term]
id: WBPhenotype0000301
name: distal_tip_cell_reflex_failure
is_a: WBPhenotype0000195 ! distal_tip_cell_migration_abnormal

[Term]
id: WBPhenotype0000302
name: benzaldehyde_chemotaxis_defective
is_a: WBPhenotype0001060 ! awc_volatile_chemotaxis_defective

[Term]
id: WBPhenotype0000303
name: diacetyl_chemotaxis_defective
is_a: WBPhenotype0000265 ! volatile_odorant_chemotaxis_defective

[Term]
id: WBPhenotype0000304
name: isoamyl_alcohol_chemotaxis_defective
def: "Failure to move towards typically attractive concentrations of isoamyl alcohol." [WB:cab, WB:cgc1786]
is_a: WBPhenotype0000265 ! volatile_odorant_chemotaxis_defective

[Term]
id: WBPhenotype0000305
name: pheromone_sensation_abnormal
is_a: WBPhenotype0000132 ! pheromone_induced_dauer_formation_abnormal

[Term]
id: WBPhenotype0000306
name: transgene_expression_abnormal
is_a: WBPhenotype0000717 ! gene_expression_abnormal

[Term]
id: WBPhenotype0000307
name: dauer_pheromone_sensation_defective
is_a: WBPhenotype0000637 ! dauer_formation_abnormal

[Term]
id: WBPhenotype0000308
name: dauer_development_abnormal
def: "Any abnormality in the processes that govern development of the dauer larva, a developmentally arrested, alternative third larval stage that is specialized for survival under harsh, or otherwise unfavorable, environmental conditions." [WB:kmva]
is_a: WBPhenotype0000049 ! postembryonic_development_abnormal

[Term]
id: WBPhenotype0000309
name: SDS_sensitive_dauer
is_a: WBPhenotype0000308 ! dauer_development_abnormal

[Term]
id: WBPhenotype0000310
name: cilia_missing
is_a: WBPhenotype0000615 ! cilia_morphology_abnormal

[Term]
id: WBPhenotype0000311
name: semi_sterile
is_a: WBPhenotype0000145 ! fertility_abnormal

[Term]
id: WBPhenotype0000312
name: dauer_pheromone_production_defective
is_a: WBPhenotype0000637 ! dauer_formation_abnormal

[Term]
id: WBPhenotype0000313
name: meiosis_progression_during_oogenesis
is_a: WBPhenotype0000186 ! oogenesis_abnormal

[Term]
id: WBPhenotype0000314
name: scrawny
is_a: WBPhenotype0000231 ! body_size_abnormal

[Term]
id: WBPhenotype0000315
name: mechanosensory_abnormal
def: "Alteration with respect to perception or response to mechanical stimuli." [WB:cab]
subset: phenotype_slim_wb
synonym: "Mec" BROAD three_letter_name []
is_a: WBPhenotype0000525 ! organism_behavior_abnormal

[Term]
id: WBPhenotype0000316
name: touch_insensitive_tail
is_a: WBPhenotype0000456 ! touch_insensitive

[Term]
id: WBPhenotype0000317
name: head_withdrawal_defect
is_a: WBPhenotype0000315 ! mechanosensory_abnormal

[Term]
id: WBPhenotype0000318
name: cell_cycle_delayed
is_a: WBPhenotype0000740 ! cell_cycle_abnormal

[Term]
id: WBPhenotype0000319
name: large
alt_id: WBPhenotype0000348
synonym: "body_size_enlarged" EXACT []
is_a: WBPhenotype0000231 ! body_size_abnormal

[Term]
id: WBPhenotype0000320
name: reduced_viability_after_freezing
is_a: WBPhenotype0000067 ! organism_stress_response_abnormal

[Term]
id: WBPhenotype0000321
name: nose_morphology_abnormal
is_a: WBPhenotype0000071 ! head_morphology_abnormal

[Term]
id: WBPhenotype0000322
name: round_nose
is_a: WBPhenotype0000321 ! nose_morphology_abnormal

[Term]
id: WBPhenotype0000323
name: head_swollen
is_a: WBPhenotype0000071 ! head_morphology_abnormal

[Term]
id: WBPhenotype0000324
name: short
is_a: WBPhenotype0000231 ! body_size_abnormal

[Term]
id: WBPhenotype0000325
name: arecoline_hypersensitive
is_a: WBPhenotype0000010 ! hypersensitive_to_drug

[Term]
id: WBPhenotype0000326
name: arecoline_resistant
is_a: WBPhenotype0000011 ! resistant_to_drug

[Term]
id: WBPhenotype0000327
name: corpus_contraction_defect
is_a: WBPhenotype0000747 ! pharyngeal_contraction_defect

[Term]
id: WBPhenotype0000328
name: terminal_bulb_contraction_abnormal
is_a: WBPhenotype0000980 ! pharyngeal_contraction_abnormal

[Term]
id: WBPhenotype0000329
name: pumping_asynchronous
is_a: WBPhenotype0001006 ! pharyngeal_pumping_rate_abnormal

[Term]
id: WBPhenotype0000330
name: pharyngeal_relaxation_defect
is_a: WBPhenotype0001004 ! pharyngeal_relaxation_abnormal

[Term]
id: WBPhenotype0000331
name: inhibitors_of_na_k_atpase_resistant
is_a: WBPhenotype0000011 ! resistant_to_drug

[Term]
id: WBPhenotype0000332
name: inhibitors_of_na_k_atpase_hypersensitive
is_a: WBPhenotype0000010 ! hypersensitive_to_drug

[Term]
id: WBPhenotype0000333
name: pharyngeal_pumps_brief
is_a: WBPhenotype0001006 ! pharyngeal_pumping_rate_abnormal

[Term]
id: WBPhenotype0000334
name: isthmus_corpus_slippery
is_a: WBPhenotype0000335 ! pharynx_slippery

[Term]
id: WBPhenotype0000335
name: pharynx_slippery
is_a: WBPhenotype0000634 ! pharyngeal_pumping_abnormal

[Term]
id: WBPhenotype0000336
name: terminal_bulb_relaxation_abnormal
is_a: WBPhenotype0001004 ! pharyngeal_relaxation_abnormal

[Term]
id: WBPhenotype0000337
name: grinder_relaxation_defective
is_a: WBPhenotype0000330 ! pharyngeal_relaxation_defect

[Term]
id: WBPhenotype0000338
name: tail_bulge
is_a: WBPhenotype0000073 ! tail_morphology_abnormal

[Term]
id: WBPhenotype0000339
name: transient_bloating
is_a: WBPhenotype0000862 ! bloated

[Term]
id: WBPhenotype0000340
name: imipramine_resistant
is_a: WBPhenotype0000011 ! resistant_to_drug

[Term]
id: WBPhenotype0000341
name: imipramine_hypersensitive
is_a: WBPhenotype0000010 ! hypersensitive_to_drug

[Term]
id: WBPhenotype0000342
name: bursa_morphology_abnormal
relationship: part_of WBPhenotype0000605 ! reproductive_system_morphology_abnormal

[Term]
id: WBPhenotype0000343
name: cloaca_morphology_abnormal
relationship: part_of WBPhenotype0000605 ! reproductive_system_morphology_abnormal

[Term]
id: WBPhenotype0000344
name: cloacal_structures_protrude
is_a: WBPhenotype0000343 ! cloaca_morphology_abnormal

[Term]
id: WBPhenotype0000345
name: vpc_cell_division_abnormal
is_a: WBPhenotype0000746 ! cell_division_abnormal

[Term]
id: WBPhenotype0000346
name: adult_pigmentation_abnormal
is_a: WBPhenotype0001009 ! developmental_pigmentation_abnormal

[Term]
id: WBPhenotype0000347
name: rectal_development_abnormal
relationship: part_of WBPhenotype0000617 ! alimentary_system_development_abnormal

[Term]
id: WBPhenotype0000349
name: flaccid
synonym: "limp" RELATED []
is_a: WBPhenotype0000001 ! body_posture_abnormal

[Term]
id: WBPhenotype0000350
name: hermaphrodite_tail_spike
is_a: WBPhenotype0000073 ! tail_morphology_abnormal

[Term]
id: WBPhenotype0000351
name: failure_to_hatch
is_a: WBPhenotype0000048 ! hatching_abnormal

[Term]
id: WBPhenotype0000352
name: backing_uncoordinated
is_a: WBPhenotype0001005 ! backward_locomotion_abnormal

[Term]
id: WBPhenotype0000353
name: backing_increased
is_a: WBPhenotype0001005 ! backward_locomotion_abnormal

[Term]
id: WBPhenotype0000354
name: cell_differentiation_abnormal
subset: phenotype_slim_wb
is_a: WBPhenotype0000529 ! cell_development_abnormal

[Term]
id: WBPhenotype0000355
name: HSN_differentiation_precocious
is_a: WBPhenotype0000354 ! cell_differentiation_abnormal

[Term]
id: WBPhenotype0000356
name: spermatogenesis_delayed
is_a: WBPhenotype0000670 ! spermatogenesis_abnormal

[Term]
id: WBPhenotype0000357
name: unfertilized_oocytes_laid
is_a: WBPhenotype0000640 ! egg_laying_abnormal

[Term]
id: WBPhenotype0000358
name: extra_cell_divisions
synonym: "supernumerary_cell_divisions" RELATED []
is_a: WBPhenotype0000746 ! cell_division_abnormal

[Term]
id: WBPhenotype0000359
name: tunicamycin_response_abnormal
is_a: WBPhenotype0000631 ! drug_response_abnormal

[Term]
id: WBPhenotype0000360
name: cytoplasmic_streaming_defect
is_a: WBPhenotype0000749 ! embryonic_development_abnormal

[Term]
id: WBPhenotype0000361
name: lima_bean_arrest
synonym: "arrest_during_epiboly" RELATED []
synonym: "Emb" BROAD three_letter_name []
is_a: WBPhenotype0000867 ! embryonic_arrest

[Term]
id: WBPhenotype0000362
name: blastocoel_abnormal
is_a: WBPhenotype0000047 ! gastrulation_abnormal

[Term]
id: WBPhenotype0000363
name: cell_division_slow
is_a: WBPhenotype0000746 ! cell_division_abnormal

[Term]
id: WBPhenotype0000364
name: gut_granule_birefringence_misplaced
is_a: WBPhenotype0000705 ! intestinal_cell_development_abnormal

[Term]
id: WBPhenotype0000365
name: egg_osmotic_integrity_abnormal_early_emb
def: "Embryo fills egg shell, and lyses upon dissection or during recording." [WB:cab, WB:cgc7141]
synonym: "Emb" BROAD three_letter_name []
is_a: WBPhenotype0000041 ! osmotic_integrity_abnormal
is_a: WBPhenotype0001178 ! egg_integrity_abnormal_early_emb

[Term]
id: WBPhenotype0000366
name: three_fold_arrest
synonym: "active_elongation_arrest" RELATED []
synonym: "Emb" BROAD three_letter_name []
is_a: WBPhenotype0000779 ! late_embryonic_arrest

[Term]
id: WBPhenotype0000367
name: comma_arrest_emb
synonym: "Emb" BROAD three_letter_name []
synonym: "end_of_epiboly_arrest" RELATED []
synonym: "Let" BROAD three_letter_name []
is_a: WBPhenotype0000864 ! early_elongation_arrest

[Term]
id: WBPhenotype0000368
name: one_point_five_fold_arrest_emb
synonym: "beginning_elongation_arrest" RELATED []
synonym: "Emb" BROAD three_letter_name []
is_a: WBPhenotype0000864 ! early_elongation_arrest

[Term]
id: WBPhenotype0000369
name: pretzel_arrest
synonym: "Emb" BROAD three_letter_name []
synonym: "end_of_elongation_arrest" RELATED []
is_a: WBPhenotype0000779 ! late_embryonic_arrest

[Term]
id: WBPhenotype0000370
name: egg_long
is_a: WBPhenotype0000037 ! egg_morphology_abnormal

[Term]
id: WBPhenotype0000371
name: cell_division_incomplete
is_a: WBPhenotype0000417 ! cell_division_failure

[Term]
id: WBPhenotype0000372
name: no_polar_body_formation
is_a: WBPhenotype0000775 ! meiosis_abnormal

[Term]
id: WBPhenotype0000373
name: egg_shape_variable
is_a: WBPhenotype0000037 ! egg_morphology_abnormal

[Term]
id: WBPhenotype0000374
name: early_divisions_prolonged
is_a: WBPhenotype0000749 ! embryonic_development_abnormal

[Term]
id: WBPhenotype0000375
name: later_divisions_prolonged
is_a: WBPhenotype0000749 ! embryonic_development_abnormal

[Term]
id: WBPhenotype0000376
name: no_uterine_cavity
is_a: WBPhenotype0000289 ! uterus_morphology_abnormal

[Term]
id: WBPhenotype0000377
name: canal_lumen_morphology_abnormal
relationship: part_of WBPhenotype0000704 ! excretory_canal_morphology_abnormal

[Term]
id: WBPhenotype0000378
name: pharyngeal_pumping_shallow
is_a: WBPhenotype0000634 ! pharyngeal_pumping_abnormal

[Term]
id: WBPhenotype0000379
name: head_notched
is_a: WBPhenotype0000071 ! head_morphology_abnormal

[Term]
id: WBPhenotype0000380
name: expulsion_infrequent
is_a: WBPhenotype0000996 ! expulsion_defective

[Term]
id: WBPhenotype0000381
name: serotonin_reuptake_inhibitor_resistant
is_a: WBPhenotype0000011 ! resistant_to_drug

[Term]
id: WBPhenotype0000382
name: serotonin_reuptake_inhibitor_hypersensitive
is_a: WBPhenotype0000010 ! hypersensitive_to_drug

[Term]
id: WBPhenotype0000383
name: lipid_synthesis_defective
is_a: WBPhenotype0000725 ! lipid_metabolism_abnormal

[Term]
id: WBPhenotype0000384
name: axon_guidance_abnormal
synonym: "axon_pathfinding_abnormal" RELATED []
is_a: WBPhenotype0001224 ! axon_outgrowth_abnormal

[Term]
id: WBPhenotype0000385
name: sperm_excess
is_a: WBPhenotype0000670 ! spermatogenesis_abnormal

[Term]
id: WBPhenotype0000386
name: genotoxic_induced_apoptosis_abnormal
synonym: "DNA_damage_induced_apoptosis_abnormal" RELATED []
is_a: WBPhenotype0000730 ! apoptosis_abnormal

[Term]
id: WBPhenotype0000387
name: sperm_nonmotile
is_a: WBPhenotype0000987 ! germ_cell_physiology_abnormal

[Term]
id: WBPhenotype0000388
name: sperm_morphology_abnormal
is_a: WBPhenotype0000900 ! germ_cell_morphology_abnormal

[Term]
id: WBPhenotype0000389
name: hermaphrodite_sperm_fertilization_defective
is_a: WBPhenotype0000694 ! hermaphrodite_sterile

[Term]
id: WBPhenotype0000390
name: spermatid_activation_defective
is_a: WBPhenotype0000670 ! spermatogenesis_abnormal

[Term]
id: WBPhenotype0000391
name: defecation_missing_motor_steps
is_a: WBPhenotype0000650 ! defecation_abnormal

[Term]
id: WBPhenotype0000392
name: intestinal_fluorescence_increased
relationship: part_of WBPhenotype0000293 ! alimentary_system_pigmentation_abnormal

[Term]
id: WBPhenotype0000393
name: cell_migration_failure
is_a: WBPhenotype0000594 ! cell_migration_abnormal

[Term]
id: WBPhenotype0000394
name: electrophoretic_variant_protein
is_a: WBPhenotype0000112 ! protein_expression_abnormal

[Term]
id: WBPhenotype0000395
name: no_differentiated_gametes
is_a: WBPhenotype0000688 ! sterile
is_a: WBPhenotype0000894 ! germ_cell_differentiation_abnormal

[Term]
id: WBPhenotype0000396
name: non_reflexed_gonad_arms
is_a: WBPhenotype0000399 ! somatic_gonad_development_abnormal

[Term]
id: WBPhenotype0000397
name: harsh_body_touch_insensitive
is_a: WBPhenotype0000456 ! touch_insensitive

[Term]
id: WBPhenotype0000398
name: light_body_touch_insensitive
is_a: WBPhenotype0000456 ! touch_insensitive

[Term]
id: WBPhenotype0000399
name: somatic_gonad_development_abnormal
relationship: part_of WBPhenotype0000691 ! gonad_development_abnormal

[Term]
id: WBPhenotype0000400
name: somatic_gonad_primordium_development_defective
is_a: WBPhenotype0000399 ! somatic_gonad_development_abnormal

[Term]
id: WBPhenotype0000401
name: no_uterus
is_a: WBPhenotype0000624 ! reproductive_system_development_abnormal

[Term]
id: WBPhenotype0000402
name: avoids_bacterial_lawn
is_a: WBPhenotype0000659 ! feeding_behavior_abnormal

[Term]
id: WBPhenotype0000403
name: sperm_transfer_initiation_defective
is_a: WBPhenotype0000284 ! sperm_transfer_defective

[Term]
id: WBPhenotype0000404
name: delayed_hatching
is_a: WBPhenotype0000048 ! hatching_abnormal

[Term]
id: WBPhenotype0000405
name: giant_oocytes
is_a: WBPhenotype0001260 ! oocyte_morphology_abnormal

[Term]
id: WBPhenotype0000406
name: lumpy
is_a: WBPhenotype0000535 ! organism_morphology_abnormal

[Term]
id: WBPhenotype0000407
name: ray_loss
is_a: WBPhenotype0000199 ! male_tail_sensory_ray_development_abnormal

[Term]
id: WBPhenotype0000408
name: dauer_recovery_inhibited
is_a: WBPhenotype0000127 ! dauer_recovery_abnormal

[Term]
id: WBPhenotype0000409
name: variable_morphology
is_a: WBPhenotype0000535 ! organism_morphology_abnormal

[Term]
id: WBPhenotype0000410
name: no_defecation_cycle
is_a: WBPhenotype0000207 ! defecation_cycle_abnormal

[Term]
id: WBPhenotype0000411
name: rod_like_morphology_larva
is_a: WBPhenotype0000035 ! larval_body_morphology_abnormal

[Term]
id: WBPhenotype0000412
name: octanol_chemotaxis_defective
is_a: WBPhenotype0000265 ! volatile_odorant_chemotaxis_defective

[Term]
id: WBPhenotype0000413
name: pharyngeal_muscle_paralyzed
def: "Immobilized pharyngeal muscle that is not responsive to external stimulation." [WB:cab]
is_a: WBPhenotype0000980 ! pharyngeal_contraction_abnormal

[Term]
id: WBPhenotype0000414
name: cell_fate_transformation
is_a: WBPhenotype0000216 ! cell_fate_specification_abnormal

[Term]
id: WBPhenotype0000415
name: necrotic_cell_death_abnormal
is_a: WBPhenotype0001173 ! non_apoptotic_cell_death_abnormal

[Term]
id: WBPhenotype0000416
name: yolk_synthesis_abnormal
synonym: "vitellogenin_synthesis_abnormal" RELATED []
is_a: WBPhenotype0001093 ! intestinal_physiology_abnormal

[Term]
id: WBPhenotype0000417
name: cell_division_failure
is_a: WBPhenotype0000746 ! cell_division_abnormal

[Term]
id: WBPhenotype0000418
name: intestinal_cell_division_failure
is_a: WBPhenotype0000417 ! cell_division_failure

[Term]
id: WBPhenotype0000419
name: L3_lethal
synonym: "Let" BROAD three_letter_name []
synonym: "Lvl" RELATED []
is_a: WBPhenotype0000058 ! late_larval_lethal
is_a: WBPhenotype0000116 ! mid_larval_lethal

[Term]
id: WBPhenotype0000420
name: levamisole_hypersensitive
is_a: WBPhenotype0000010 ! hypersensitive_to_drug
is_a: WBPhenotype0000845 ! levamisole_response_abnormal

[Term]
id: WBPhenotype0000421
name: levamisole_resistant
is_a: WBPhenotype0000011 ! resistant_to_drug
is_a: WBPhenotype0000845 ! levamisole_response_abnormal

[Term]
id: WBPhenotype0000422
name: twitcher
is_a: WBPhenotype0004017 ! locomotor_coordination_abnormal

[Term]
id: WBPhenotype0000423
name: head_muscle_contraction_abnormal
relationship: part_of WBPhenotype0001002 ! head_muscle_behavior_abnormal

[Term]
id: WBPhenotype0000424
name: antibody_staining_abnormal
is_a: WBPhenotype0000112 ! protein_expression_abnormal

[Term]
id: WBPhenotype0000425
name: antibody_staining_reduced
is_a: WBPhenotype0000424 ! antibody_staining_abnormal

[Term]
id: WBPhenotype0000426
name: antibody_staining_increased
is_a: WBPhenotype0000424 ! antibody_staining_abnormal

[Term]
id: WBPhenotype0000427
name: no_cuticle
is_a: WBPhenotype0000201 ! cuticle_development_abnormal

[Term]
id: WBPhenotype0000428
name: no_adult_cuticle
is_a: WBPhenotype0000427 ! no_cuticle

[Term]
id: WBPhenotype0000429
name: copulatory_structure_development_abnormal
relationship: part_of WBPhenotype0000624 ! reproductive_system_development_abnormal

[Term]
id: WBPhenotype0000430
name: male_copulatory_structure_development_abnormal
is_a: WBPhenotype0000429 ! copulatory_structure_development_abnormal

[Term]
id: WBPhenotype0000431
name: hermaphrodite_copulatory_structure_development_abnormal
is_a: WBPhenotype0000429 ! copulatory_structure_development_abnormal

[Term]
id: WBPhenotype0000432
name: no_male_copulatory_structures
is_a: WBPhenotype0000430 ! male_copulatory_structure_development_abnormal

[Term]
id: WBPhenotype0000433
name: DNA_synthesis_abnormal
is_a: WBPhenotype0000732 ! DNA_metabolism_abnormal

[Term]
id: WBPhenotype0000434
name: sexual_maturation_defective
is_a: WBPhenotype0000624 ! reproductive_system_development_abnormal

[Term]
id: WBPhenotype0000435
name: protein_localization_abnormal
def: "Any change in the subcellular localization of a protein." [WB:kmva]
is_a: WBPhenotype0000112 ! protein_expression_abnormal

[Term]
id: WBPhenotype0000436
name: protein_subcellular_localization_abnormal
is_a: WBPhenotype0000435 ! protein_localization_abnormal

[Term]
id: WBPhenotype0000438
name: retarded_heterochronic_alterations
is_a: WBPhenotype0000033 ! developmental_timing_abnormal

[Term]
id: WBPhenotype0000439
name: precocious_heterochronic_alterations
is_a: WBPhenotype0000033 ! developmental_timing_abnormal

[Term]
id: WBPhenotype0000440
name: long_excretory_canals
relationship: part_of WBPhenotype0000704 ! excretory_canal_morphology_abnormal

[Term]
id: WBPhenotype0000441
name: tail_rounded
is_a: WBPhenotype0000073 ! tail_morphology_abnormal

[Term]
id: WBPhenotype0000442
name: larval_development_retarded
is_a: WBPhenotype0000750 ! larval_development_abnormal

[Term]
id: WBPhenotype0000443
name: spicule_morphology_abnormal
is_a: WBPhenotype0000605 ! reproductive_system_morphology_abnormal

[Term]
id: WBPhenotype0000444
name: bursa_elongated
is_a: WBPhenotype0000342 ! bursa_morphology_abnormal

[Term]
id: WBPhenotype0000445
name: yolk_synthesis_in_males
synonym: "vitellogenin_synthesis_in_males" RELATED []
is_a: WBPhenotype0000416 ! yolk_synthesis_abnormal

[Term]
id: WBPhenotype0000446
name: supernumerary_molt
is_a: WBPhenotype0000638 ! molt_defect

[Term]
id: WBPhenotype0000447
name: adult_development_abnormal
is_a: WBPhenotype0000049 ! postembryonic_development_abnormal

[Term]
id: WBPhenotype0000448
name: adult_cuticle_development_abnormal
is_a: WBPhenotype0000447 ! adult_development_abnormal

[Term]
id: WBPhenotype0000449
name: second_adult_cuticle
is_a: WBPhenotype0000448 ! adult_cuticle_development_abnormal

[Term]
id: WBPhenotype0000450
name: swollen_male_tail
is_a: WBPhenotype0000070 ! male_tail_abnormal

[Term]
id: WBPhenotype0000451
name: head_protrusions
is_a: WBPhenotype0000071 ! head_morphology_abnormal

[Term]
id: WBPhenotype0000452
name: tail_protrusions
is_a: WBPhenotype0000073 ! tail_morphology_abnormal

[Term]
id: WBPhenotype0000453
name: body_protrusions
is_a: WBPhenotype0000072 ! body_morphology_abnormal

[Term]
id: WBPhenotype0000454
name: head_twisted
is_a: WBPhenotype0000071 ! head_morphology_abnormal

[Term]
id: WBPhenotype0000455
name: jerky_movement
is_a: WBPhenotype0004017 ! locomotor_coordination_abnormal

[Term]
id: WBPhenotype0000456
name: touch_insensitive
is_a: WBPhenotype0000315 ! mechanosensory_abnormal

[Term]
id: WBPhenotype0000457
name: organism_starvation_hypersensitive
is_a: WBPhenotype0000147 ! organism_starvation_response_abnormal

[Term]
id: WBPhenotype0000458
name: starvation_resistant
is_a: WBPhenotype0000147 ! organism_starvation_response_abnormal

[Term]
id: WBPhenotype0000459
name: pesticide_response_abnormal
is_a: WBPhenotype0000738 ! organism_environmental_stimulus_response_abnormal

[Term]
id: WBPhenotype0000460
name: paraquat_response_abnormal
synonym: "methyl_viologen_response_abnormal" RELATED []
is_a: WBPhenotype0000459 ! pesticide_response_abnormal

[Term]
id: WBPhenotype0000461
name: paraquat_resistant
is_a: WBPhenotype0000460 ! paraquat_response_abnormal

[Term]
id: WBPhenotype0000462
name: paraquat_hypersensitive
is_a: WBPhenotype0000460 ! paraquat_response_abnormal

[Term]
id: WBPhenotype0000463
name: metabolic_pathway_abnormal
is_a: WBPhenotype0000027 ! organism_metabolism_processing_abnormal

[Term]
id: WBPhenotype0000464
name: oxygen_response_abnormal
is_a: WBPhenotype0000738 ! organism_environmental_stimulus_response_abnormal

[Term]
id: WBPhenotype0000465
name: high_oxygen_resistant
is_a: WBPhenotype0000464 ! oxygen_response_abnormal

[Term]
id: WBPhenotype0000466
name: high_oxygen_hypersensitive
is_a: WBPhenotype0000464 ! oxygen_response_abnormal

[Term]
id: WBPhenotype0000467
name: age_associated_fluorescence_increased
is_a: WBPhenotype0001009 ! developmental_pigmentation_abnormal

[Term]
id: WBPhenotype0000468
name: age_associated_fluorescence_decreased
is_a: WBPhenotype0001009 ! developmental_pigmentation_abnormal

[Term]
id: WBPhenotype0000469
name: Q_neuroblast_lineage_migration_abnormal
is_a: WBPhenotype0000594 ! cell_migration_abnormal

[Term]
id: WBPhenotype0000470
name: HSN_migration_abnormal
is_a: WBPhenotype0000594 ! cell_migration_abnormal

[Term]
id: WBPhenotype0000471
name: ALM_migration_abnormal
is_a: WBPhenotype0000594 ! cell_migration_abnormal

[Term]
id: WBPhenotype0000472
name: no_endoderm
is_a: WBPhenotype0000749 ! embryonic_development_abnormal

[Term]
id: WBPhenotype0000473
name: progressive_paralysis
is_a: WBPhenotype0000643 ! locomotion_abnormal

[Term]
id: WBPhenotype0000474
name: muscle_attachment_abnormal
is_a: WBPhenotype0000622 ! muscle_system_development_abnormal

[Term]
id: WBPhenotype0000475
name: muscle_detached
is_a: WBPhenotype0000474 ! muscle_attachment_abnormal

[Term]
id: WBPhenotype0000476
name: progressive_muscle_detachment
is_a: WBPhenotype0000474 ! muscle_attachment_abnormal

[Term]
id: WBPhenotype0000477
name: nucleoli_refraction_abnormal
is_a: WBPhenotype0000722 ! nucleoli_abnormal

[Term]
id: WBPhenotype0000478
name: isothermal_tracking_behavior_abnormal
def: "Deviation from a tendency for animals to track towards their cultivation temperature and  within their cultivation temperature." [WB:WBPaper00002214]
subset: phenotype_slim_wb
is_a: WBPhenotype0000525 ! organism_behavior_abnormal

[Term]
id: WBPhenotype0000479
name: eggs_pale
is_a: WBPhenotype0000970 ! embryonic_pigmentation_abnormal
is_a: WBPhenotype0001261 ! pale

[Term]
id: WBPhenotype0000480
name: pyrazine_chemotaxis_defective
is_a: WBPhenotype0000265 ! volatile_odorant_chemotaxis_defective

[Term]
id: WBPhenotype0000481
name: chemoaversion_abnormal
def: "Avoidance of odorants is altered." [WB:cab]
synonym: "chemical_avoidance_abnormal" RELATED []
is_a: WBPhenotype0001040 ! chemosensory_response_abnormal

[Term]
id: WBPhenotype0000482
name: garlic_chemoaversion_abnormal
is_a: WBPhenotype0000481 ! chemoaversion_abnormal

[Term]
id: WBPhenotype0000483
name: no_gut_granules
is_a: WBPhenotype0000103 ! gut_granules_abnormal
relationship: part_of WBPhenotype0000708 ! intestinal_development_abnormal

[Term]
id: WBPhenotype0000484
name: embryo_small
is_a: WBPhenotype0001136 ! embryonic_morphology_abnormal

[Term]
id: WBPhenotype0000485
name: dauer_death_increased
synonym: "reduced_dauer_survival" RELATED []
is_a: WBPhenotype0000308 ! dauer_development_abnormal

[Term]
id: WBPhenotype0000486
name: colchicine_hypersensitive
is_a: WBPhenotype0000010 ! hypersensitive_to_drug

[Term]
id: WBPhenotype0000487
name: colchicine_resistant
is_a: WBPhenotype0000011 ! resistant_to_drug

[Term]
id: WBPhenotype0000488
name: chloroquinone_hypersensitive
is_a: WBPhenotype0000010 ! hypersensitive_to_drug

[Term]
id: WBPhenotype0000489
name: chloroquinone_resistant
is_a: WBPhenotype0000011 ! resistant_to_drug

[Term]
id: WBPhenotype0000490
name: pharynx_disorganized
is_a: WBPhenotype0000707 ! pharyngeal_development_abnormal

[Term]
id: WBPhenotype0000491
name: isthmus_malformed
is_a: WBPhenotype0000709 ! pharyngeal_morphology_abnormal

[Term]
id: WBPhenotype0000492
name: corpus_malformed
is_a: WBPhenotype0000709 ! pharyngeal_morphology_abnormal

[Term]
id: WBPhenotype0000493
name: metacarpus_malformed
is_a: WBPhenotype0000709 ! pharyngeal_morphology_abnormal

[Term]
id: WBPhenotype0000494
name: two_fold_arrest
is_a: WBPhenotype0000779 ! late_embryonic_arrest

[Term]
id: WBPhenotype0000495
name: rays_ectopic
is_a: WBPhenotype0000199 ! male_tail_sensory_ray_development_abnormal

[Term]
id: WBPhenotype0000496
name: male_posterid_sensilla_missing
relationship: part_of WBPhenotype0001008 ! male_nervous_system_development_abnormal

[Term]
id: WBPhenotype0000497
name: organism_gamma_ray_response_abnormal
is_a: WBPhenotype0000686 ! organism_ionizing_radiation_response_abnormal

[Term]
id: WBPhenotype0000498
name: methyl_methanesulfonate_response_abnormal
synonym: "MMS_response_abnormal" RELATED []
is_a: WBPhenotype0000067 ! organism_stress_response_abnormal

[Term]
id: WBPhenotype0000499
name: ethyl_methanesulfonate_response_abnormal
synonym: "EMS_response_abnormal" RELATED []
is_a: WBPhenotype0000067 ! organism_stress_response_abnormal

[Term]
id: WBPhenotype0000500
name: acetylcholinesterase_inhibitor_hypersensitive
is_a: WBPhenotype0000010 ! hypersensitive_to_drug

[Term]
id: WBPhenotype0000501
name: left_handed_roller
synonym: "Rol" RELATED []
is_a: WBPhenotype0000645 ! roller

[Term]
id: WBPhenotype0000502
name: right_handed_roller
synonym: "Rol" BROAD three_letter_name []
is_a: WBPhenotype0000645 ! roller

[Term]
id: WBPhenotype0000503
name: abnormal_endoreduplication
is_a: WBPhenotype0000732 ! DNA_metabolism_abnormal

[Term]
id: WBPhenotype0000504
name: nuclear_division_abnormal
subset: phenotype_slim_wb
synonym: "karyokinesis_abnormal" RELATED []
is_a: WBPhenotype0000536 ! cell_physiology_abnormal

[Term]
id: WBPhenotype0000505
name: male_ray_morphology_abnormal
is_a: WBPhenotype0000299 ! chemosensory_cell_morphology_abnormal

[Term]
id: WBPhenotype0000506
name: swollen_bursa
is_a: WBPhenotype0000342 ! bursa_morphology_abnormal

[Term]
id: WBPhenotype0000507
name: acetylcholine_levels_abnormal
is_a: WBPhenotype0000027 ! organism_metabolism_processing_abnormal

[Term]
id: WBPhenotype0000508
name: nonsense_mRNA_accumulation
is_a: WBPhenotype0000027 ! organism_metabolism_processing_abnormal

[Term]
id: WBPhenotype0000509
name: sperm_pseudopods_abnormal
is_a: WBPhenotype0000388 ! sperm_morphology_abnormal

[Term]
id: WBPhenotype0000510
name: vulval_invagination_abnormal_at_L4
is_a: WBPhenotype0000695 ! vulva_morphology_abnormal

[Term]
id: WBPhenotype0000511
name: nuclear_positioning_abnormal
subset: phenotype_slim_wb
is_a: WBPhenotype0000536 ! cell_physiology_abnormal

[Term]
id: WBPhenotype0000512
name: VNC_nuclear_positioning_abnormal
is_a: WBPhenotype0000511 ! nuclear_positioning_abnormal

[Term]
id: WBPhenotype0000513
name: touch_response_abnormal
is_a: WBPhenotype0000738 ! organism_environmental_stimulus_response_abnormal

[Term]
id: WBPhenotype0000514
name: rubber_band
is_a: WBPhenotype0000513 ! touch_response_abnormal

[Term]
id: WBPhenotype0000515
name: ventral_nerve_cord_development_abnormal
is_a: WBPhenotype0000945 ! neuropil_development_abnormal

[Term]
id: WBPhenotype0000516
name: ventral_cord_disorganized
is_a: WBPhenotype0000976 ! ventral_cord_patterning_abnormal

[Term]
id: WBPhenotype0000517
name: behavior_abnormal
is_a: WBPhenotype0000886 ! Abnormal

[Term]
id: WBPhenotype0000518
name: development_abnormal
is_a: WBPhenotype0000886 ! Abnormal

[Term]
id: WBPhenotype0000519
name: physiology_abnormal
is_a: WBPhenotype0000886 ! Abnormal

[Term]
id: WBPhenotype0000520
name: morphology_abnormal
is_a: WBPhenotype0000886 ! Abnormal

[Term]
id: WBPhenotype0000521
name: pigmentation_abnormal
is_a: WBPhenotype0000886 ! Abnormal

[Term]
id: WBPhenotype0000522
name: organism_region_behavior_abnormal
is_a: WBPhenotype0000517 ! behavior_abnormal

[Term]
id: WBPhenotype0000523
name: chemical_response_abnormal
is_a: WBPhenotype0000738 ! organism_environmental_stimulus_response_abnormal

[Term]
id: WBPhenotype0000524
name: bleach_response_abnormal
is_a: WBPhenotype0000523 ! chemical_response_abnormal

[Term]
id: WBPhenotype0000525
name: organism_behavior_abnormal
subset: phenotype_slim_wb
is_a: WBPhenotype0000517 ! behavior_abnormal

[Term]
id: WBPhenotype0000526
name: cell_pigmentation_abnormal
subset: phenotype_slim_wb
is_a: WBPhenotype0000521 ! pigmentation_abnormal

[Term]
id: WBPhenotype0000527
name: organism_pigmentation_abnormal
subset: phenotype_slim_wb
synonym: "Abnormal_Coloration" RELATED []
is_a: WBPhenotype0000521 ! pigmentation_abnormal

[Term]
id: WBPhenotype0000528
name: body_region_development_abnormal
is_a: WBPhenotype0000518 ! development_abnormal

[Term]
id: WBPhenotype0000529
name: cell_development_abnormal
subset: phenotype_slim_wb
is_a: WBPhenotype0000518 ! development_abnormal

[Term]
id: WBPhenotype0000530
name: organ_system_development_abnormal
subset: phenotype_slim_wb
is_a: WBPhenotype0000518 ! development_abnormal

[Term]
id: WBPhenotype0000531
name: organism_development_abnormal
subset: phenotype_slim_wb
is_a: WBPhenotype0000518 ! development_abnormal

[Term]
id: WBPhenotype0000532
name: body_region_morphology_abnormal
is_a: WBPhenotype0000520 ! morphology_abnormal

[Term]
id: WBPhenotype0000533
name: cell_morphology_abnormal
subset: phenotype_slim_wb
is_a: WBPhenotype0000520 ! morphology_abnormal

[Term]
id: WBPhenotype0000534
name: organ_system_morphology_abnormal
subset: phenotype_slim_wb
is_a: WBPhenotype0000520 ! morphology_abnormal

[Term]
id: WBPhenotype0000535
name: organism_morphology_abnormal
def: "Body morphological defects." [WB:cab, WB:WBPaper00004402, WB:WBPaper00004403, WB:WBPaper00004651, WB:WBPaper00005654, WB:WBPaper00006395]
subset: phenotype_slim_wb
synonym: "Bmd" BROAD three_letter_name []
is_a: WBPhenotype0000520 ! morphology_abnormal

[Term]
id: WBPhenotype0000536
name: cell_physiology_abnormal
subset: phenotype_slim_wb
is_a: WBPhenotype0000519 ! physiology_abnormal

[Term]
id: WBPhenotype0000537
name: synaptic_input_abnormal
is_a: WBPhenotype0000816 ! neuron_development_abnormal

[Term]
id: WBPhenotype0000538
name: synaptic_output_abnormal
is_a: WBPhenotype0000816 ! neuron_development_abnormal

[Term]
id: WBPhenotype0000539
name: dorsal_nerve_cord_development_abnormal
is_a: WBPhenotype0000945 ! neuropil_development_abnormal

[Term]
id: WBPhenotype0000540
name: muscle_arm_development_abnormal
is_a: WBPhenotype0000087 ! body_wall_cell_development_abnormal

[Term]
id: WBPhenotype0000541
name: cord_commissures_fail_to_reach_target
is_a: WBPhenotype0000014 ! cord_commissures_abnormal

[Term]
id: WBPhenotype0000542
name: fat
is_a: WBPhenotype0000231 ! body_size_abnormal

[Term]
id: WBPhenotype0000543
name: forward_kinker
is_a: WBPhenotype0000002 ! kinker

[Term]
id: WBPhenotype0000544
name: backward_kinker
is_a: WBPhenotype0000002 ! kinker

[Term]
id: WBPhenotype0000545
name: eggs_retained
def: "Eggs are retained in the uterus at a later stage than in wild-type worms." [WB:cab]
synonym: "late_eggs_laid" RELATED []
is_a: WBPhenotype0000006 ! egg_laying_defective

[Term]
id: WBPhenotype0000546
name: early_eggs_laid
is_a: WBPhenotype0000005 ! hyperactive_egg_laying

[Term]
id: WBPhenotype0000547
name: starved
synonym: "Eat" RELATED []
is_a: WBPhenotype0000577 ! organism_homeostasis_metabolism_abnormal

[Term]
id: WBPhenotype0000548
name: muscle_dystrophy
def: "Progressive degeneration of muscle." [WB:cab]
is_a: WBPhenotype0000622 ! muscle_system_development_abnormal

[Term]
id: WBPhenotype0000549
name: head_muscle_dystrophy
def: "Progressive degeneration of the head muscle." [WB:cab]
is_a: WBPhenotype0000548 ! muscle_dystrophy
relationship: part_of WBPhenotype0001002 ! head_muscle_behavior_abnormal

[Term]
id: WBPhenotype0000550
name: body_muscle_dystrophy
def: "Progressive muscle degeneration." [WB:cab]
is_a: WBPhenotype0000548 ! muscle_dystrophy
relationship: part_of WBPhenotype0000596 ! body_behavior_abnormal

[Term]
id: WBPhenotype0000551
name: omega_turns
is_a: WBPhenotype0000643 ! locomotion_abnormal

[Term]
id: WBPhenotype0000552
name: GABA_levels_abnormal
is_a: WBPhenotype0000027 ! organism_metabolism_processing_abnormal

[Term]
id: WBPhenotype0000553
name: muscle_ultrastructure_disorganized
synonym: "muscle_birefringence_abnormal" RELATED []
is_a: WBPhenotype0000603 ! muscle_system_morphology_abnormal

[Term]
id: WBPhenotype0000554
name: hypoosmotic_shock_hypersensitive
is_a: WBPhenotype0000041 ! osmotic_integrity_abnormal

[Term]
id: WBPhenotype0000555
name: drug_adaptation_abnormal
is_a: WBPhenotype0000631 ! drug_response_abnormal

[Term]
id: WBPhenotype0000556
name: dopamine_adaptation_abnormal
is_a: WBPhenotype0000555 ! drug_adaptation_abnormal

[Term]
id: WBPhenotype0000557
name: dopamine_adaptation_defective
is_a: WBPhenotype0000556 ! dopamine_adaptation_abnormal

[Term]
id: WBPhenotype0000558
name: calcium_channel_modulator_response_abnormal
is_a: WBPhenotype0000631 ! drug_response_abnormal

[Term]
id: WBPhenotype0000559
name: calcium_channel_modulator_hypersensitive
is_a: WBPhenotype0000010 ! hypersensitive_to_drug
is_a: WBPhenotype0000558 ! calcium_channel_modulator_response_abnormal

[Term]
id: WBPhenotype0000560
name: calcium_channel_modulator_resistant
is_a: WBPhenotype0000011 ! resistant_to_drug
is_a: WBPhenotype0000558 ! calcium_channel_modulator_response_abnormal

[Term]
id: WBPhenotype0000561
name: head_levamisole_resistant
is_a: WBPhenotype0000421 ! levamisole_resistant

[Term]
id: WBPhenotype0000562
name: body_levamisole_resistant
is_a: WBPhenotype0000421 ! levamisole_resistant

[Term]
id: WBPhenotype0000563
name: shrinker
is_a: WBPhenotype0004017 ! locomotor_coordination_abnormal

[Term]
id: WBPhenotype0000564
name: echo_defecation_cycle
is_a: WBPhenotype0000207 ! defecation_cycle_abnormal

[Term]
id: WBPhenotype0000565
name: coiler
synonym: "curler" RELATED []
is_a: WBPhenotype0000001 ! body_posture_abnormal
is_a: WBPhenotype0004017 ! locomotor_coordination_abnormal

[Term]
id: WBPhenotype0000566
name: ventral_coiler
synonym: "ventral_curler" RELATED []
is_a: WBPhenotype0000565 ! coiler

[Term]
id: WBPhenotype0000567
name: dorsal_coiler
synonym: "dorsal_curler" RELATED []
is_a: WBPhenotype0000565 ! coiler

[Term]
id: WBPhenotype0000568
name: axon_ultrastructure_abnormal
is_a: WBPhenotype0000180 ! axon_morphology_abnormal

[Term]
id: WBPhenotype0000569
name: axon_variscosities
is_a: WBPhenotype0000568 ! axon_ultrastructure_abnormal

[Term]
id: WBPhenotype0000570
name: axon_cisternae
is_a: WBPhenotype0000568 ! axon_ultrastructure_abnormal

[Term]
id: WBPhenotype0000571
name: abnormal_vesicles_axons
is_a: WBPhenotype0000568 ! axon_ultrastructure_abnormal

[Term]
id: WBPhenotype0000572
name: neuronal_outgrowth_abnormal
is_a: WBPhenotype0000816 ! neuron_development_abnormal

[Term]
id: WBPhenotype0000573
name: neuronal_branching_abnormal
is_obsolete: true

[Term]
id: WBPhenotype0000574
name: excretory_canal_short
relationship: part_of WBPhenotype0000704 ! excretory_canal_morphology_abnormal

[Term]
id: WBPhenotype0000575
name: organ_system_physiology_abnormal
subset: phenotype_slim_wb
is_a: WBPhenotype0000519 ! physiology_abnormal

[Term]
id: WBPhenotype0000576
name: organism_physiology_abnormal
subset: phenotype_slim_wb
is_a: WBPhenotype0000519 ! physiology_abnormal

[Term]
id: WBPhenotype0000577
name: organism_homeostasis_metabolism_abnormal
subset: phenotype_slim_wb
is_a: WBPhenotype0000576 ! organism_physiology_abnormal

[Term]
id: WBPhenotype0000578
name: body_axis_development_abnormal
is_a: WBPhenotype0000528 ! body_region_development_abnormal

[Term]
id: WBPhenotype0000579
name: organism_segment_development_abnormal
is_a: WBPhenotype0000531 ! organism_development_abnormal

[Term]
id: WBPhenotype0000580
name: organism_segment_behavior_abnormal
is_a: WBPhenotype0000522 ! organism_region_behavior_abnormal

[Term]
id: WBPhenotype0000581
name: body_axis_morphology_abnormal
is_a: WBPhenotype0000532 ! body_region_morphology_abnormal

[Term]
id: WBPhenotype0000582
name: organism_segment_morphology_abnormal
is_a: WBPhenotype0000535 ! organism_morphology_abnormal

[Term]
id: WBPhenotype0000583
name: dumpy
def: "Worms are shorter and stouter than wild type." [WB:cab, WB:WBPaper00004402, WB:WBPaper00004403, WB:WBPaper00004651, WB:WBPaper00005654, WB:WBPaper00006395, WB:WBPaper00024497]
synonym: "Dpy" BROAD three_letter_name []
is_a: WBPhenotype0000231 ! body_size_abnormal

[Term]
id: WBPhenotype0000584
name: synaptic_transmission_abnormal
is_a: WBPhenotype0000612 ! nervous_system_physiology_abnormal

[Term]
id: WBPhenotype0000585
name: cell_homeostasis_metabolism_abnormal
subset: phenotype_slim_wb
is_a: WBPhenotype0000536 ! cell_physiology_abnormal

[Term]
id: WBPhenotype0000586
name: bleach_hypersensitive
is_a: WBPhenotype0000524 ! bleach_response_abnormal

[Term]
id: WBPhenotype0000587
name: lectin_staining_abnormal
is_a: WBPhenotype0000112 ! protein_expression_abnormal

[Term]
id: WBPhenotype0000588
name: no_male_abnormality_scored
is_obsolete: true

[Term]
id: WBPhenotype0000589
name: no_hermaphrodite_abnormality_scored
is_obsolete: true

[Term]
id: WBPhenotype0000590
name: cell_corpse_number_abnormal
is_a: WBPhenotype0000730 ! apoptosis_abnormal

[Term]
id: WBPhenotype0000591
name: metal_response_abnormal
is_a: WBPhenotype0000738 ! organism_environmental_stimulus_response_abnormal

[Term]
id: WBPhenotype0000592
name: copper_response_abnormal
is_a: WBPhenotype0000591 ! metal_response_abnormal

[Term]
id: WBPhenotype0000593
name: hypersensitive_to_copper
is_a: WBPhenotype0000592 ! copper_response_abnormal

[Term]
id: WBPhenotype0000594
name: cell_migration_abnormal
subset: phenotype_slim_wb
synonym: "Mig" BROAD three_letter_name []
synonym: "migration_of_cells_abnormal" RELATED []
is_a: WBPhenotype0000529 ! cell_development_abnormal

[Term]
id: WBPhenotype0000595
name: head_behavior_abnormal
def: "Activity characteristic of the head is altered." [WB:cab]
is_a: WBPhenotype0000580 ! organism_segment_behavior_abnormal

[Term]
id: WBPhenotype0000596
name: body_behavior_abnormal
def: "Activity characteristic of the body is altered." [WB:cab]
is_a: WBPhenotype0000580 ! organism_segment_behavior_abnormal

[Term]
id: WBPhenotype0000597
name: tail_behavior_abnormal
is_a: WBPhenotype0000580 ! organism_segment_behavior_abnormal

[Term]
id: WBPhenotype0000598
name: alimentary_system_morphology_abnormal
subset: phenotype_slim_wb
is_a: WBPhenotype0000534 ! organ_system_morphology_abnormal

[Term]
id: WBPhenotype0000599
name: coelomic_system_morphology_abnormal
subset: phenotype_slim_wb
is_a: WBPhenotype0000534 ! organ_system_morphology_abnormal

[Term]
id: WBPhenotype0000600
name: epithelial_system_morphology_abnormal
subset: phenotype_slim_wb
is_a: WBPhenotype0000534 ! organ_system_morphology_abnormal

[Term]
id: WBPhenotype0000601
name: excretory_secretory_system_morphology_abnormal
subset: phenotype_slim_wb
is_a: WBPhenotype0000534 ! organ_system_morphology_abnormal

[Term]
id: WBPhenotype0000602
name: excretory_system_morphology_abnormal
relationship: part_of WBPhenotype0000601 ! excretory_secretory_system_morphology_abnormal

[Term]
id: WBPhenotype0000603
name: muscle_system_morphology_abnormal
subset: phenotype_slim_wb
is_a: WBPhenotype0000534 ! organ_system_morphology_abnormal

[Term]
id: WBPhenotype0000604
name: nervous_system_morphology_abnormal
subset: phenotype_slim_wb
synonym: "neuroanatomical_defect" RELATED []
is_a: WBPhenotype0000534 ! organ_system_morphology_abnormal

[Term]
id: WBPhenotype0000605
name: reproductive_system_morphology_abnormal
subset: phenotype_slim_wb
is_a: WBPhenotype0000534 ! organ_system_morphology_abnormal

[Term]
id: WBPhenotype0000606
name: alimentary_system_physiology_abnormal
subset: phenotype_slim_wb
is_a: WBPhenotype0000575 ! organ_system_physiology_abnormal

[Term]
id: WBPhenotype0000607
name: coelomic_system_physiology_abnormal
subset: phenotype_slim_wb
is_a: WBPhenotype0000575 ! organ_system_physiology_abnormal

[Term]
id: WBPhenotype0000608
name: epithelial_system_physiology_abnormal
subset: phenotype_slim_wb
is_a: WBPhenotype0000575 ! organ_system_physiology_abnormal

[Term]
id: WBPhenotype0000609
name: excretory_secretory_system_physiology_abnormal
subset: phenotype_slim_wb
is_a: WBPhenotype0000575 ! organ_system_physiology_abnormal

[Term]
id: WBPhenotype0000610
name: excretory_system_physiology_abnormal
subset: phenotype_slim_wb
is_a: WBPhenotype0000575 ! organ_system_physiology_abnormal

[Term]
id: WBPhenotype0000611
name: muscle_system_physiology_abnormal
subset: phenotype_slim_wb
is_a: WBPhenotype0000575 ! organ_system_physiology_abnormal

[Term]
id: WBPhenotype0000612
name: nervous_system_physiology_abnormal
subset: phenotype_slim_wb
is_a: WBPhenotype0000575 ! organ_system_physiology_abnormal

[Term]
id: WBPhenotype0000613
name: reproductive_system_physiology_abnormal
subset: phenotype_slim_wb
is_a: WBPhenotype0000575 ! organ_system_physiology_abnormal

[Term]
id: WBPhenotype0000614
name: GLR_development_abnormal
is_a: WBPhenotype0000942 ! accessory_cell_development_abnormal

[Term]
id: WBPhenotype0000615
name: cilia_morphology_abnormal
synonym: "defective_dye_filling_of_cilia" RELATED []
is_a: WBPhenotype0000299 ! chemosensory_cell_morphology_abnormal

[Term]
id: WBPhenotype0000616
name: synapse_morphology_abnormal
is_a: WBPhenotype0000604 ! nervous_system_morphology_abnormal

[Term]
id: WBPhenotype0000617
name: alimentary_system_development_abnormal
subset: phenotype_slim_wb
is_a: WBPhenotype0000530 ! organ_system_development_abnormal

[Term]
id: WBPhenotype0000618
name: coelomic_system_development_abnormal
subset: phenotype_slim_wb
is_a: WBPhenotype0000530 ! organ_system_development_abnormal

[Term]
id: WBPhenotype0000619
name: epithelial_system_development_abnormal
subset: phenotype_slim_wb
is_a: WBPhenotype0000530 ! organ_system_development_abnormal

[Term]
id: WBPhenotype0000620
name: excretory_secretory_system_development_abnormal
subset: phenotype_slim_wb
is_a: WBPhenotype0000530 ! organ_system_development_abnormal

[Term]
id: WBPhenotype0000621
name: excretory_system_development_abnormal
subset: phenotype_slim_wb
is_a: WBPhenotype0000530 ! organ_system_development_abnormal
relationship: part_of WBPhenotype0000620 ! excretory_secretory_system_development_abnormal

[Term]
id: WBPhenotype0000622
name: muscle_system_development_abnormal
subset: phenotype_slim_wb
is_a: WBPhenotype0000530 ! organ_system_development_abnormal

[Term]
id: WBPhenotype0000623
name: nervous_system_development_abnormal
subset: phenotype_slim_wb
is_a: WBPhenotype0000530 ! organ_system_development_abnormal

[Term]
id: WBPhenotype0000624
name: reproductive_system_development_abnormal
subset: phenotype_slim_wb
synonym: "reproductive_defect" RELATED []
is_a: WBPhenotype0000530 ! organ_system_development_abnormal

[Term]
id: WBPhenotype0000625
name: synaptogenesis_abnormal
is_a: WBPhenotype0000623 ! nervous_system_development_abnormal

[Term]
id: WBPhenotype0000626
name: habituation_abnormal
subset: phenotype_slim_wb
is_a: WBPhenotype0000525 ! organism_behavior_abnormal

[Term]
id: WBPhenotype0000627
name: anesthetic_response_abnormal
is_a: WBPhenotype0000631 ! drug_response_abnormal

[Term]
id: WBPhenotype0000628
name: spindle_assembly_abnormal_early_emb
def: "Spindle bipolarity is not established." [WB:cab, WB:cgc7141]
synonym: "Emb" BROAD three_letter_name []
is_a: WBPhenotype0001102 ! mitotic_spindle_abnormal_early_emb

[Term]
id: WBPhenotype0000629
name: ectopic_neurite_outgrowth
is_a: WBPhenotype0000944 ! neurite_development_abnormal

[Term]
id: WBPhenotype0000630
name: quinine_chemoaversion_abnormal
is_a: WBPhenotype0000481 ! chemoaversion_abnormal

[Term]
id: WBPhenotype0000631
name: drug_response_abnormal
def: "Characteristic response(s) to drug(s) is abnormal." [WB:cab]
synonym: "drug_response_abnormal" RELATED []
is_a: WBPhenotype0000523 ! chemical_response_abnormal

[Term]
id: WBPhenotype0000632
name: axon_fasciculation_abnormal
is_a: WBPhenotype0000880 ! axon_development_abnormal

[Term]
id: WBPhenotype0000633
name: axon_branching_abnormal
is_a: WBPhenotype0000180 ! axon_morphology_abnormal
is_a: WBPhenotype0001224 ! axon_outgrowth_abnormal

[Term]
id: WBPhenotype0000634
name: pharyngeal_pumping_abnormal
subset: phenotype_slim_wb
is_a: WBPhenotype0000525 ! organism_behavior_abnormal

[Term]
id: WBPhenotype0000635
name: chemotaxis_abnormal
def: "Movement towards typical attractive odorants is altered." [WB:cab, WB:cgc122, WB:cgc387]
is_a: WBPhenotype0001040 ! chemosensory_response_abnormal

[Term]
id: WBPhenotype0000636
name: neuronal_degeneration_abnormal
is_a: WBPhenotype0000612 ! nervous_system_physiology_abnormal

[Term]
id: WBPhenotype0000637
name: dauer_formation_abnormal
def: "Characteristic entry into the dauer stage is altered." [WB:cab]
synonym: "Daf" BROAD three_letter_name []
is_a: WBPhenotype0000308 ! dauer_development_abnormal
is_a: WBPhenotype0001001 ! dauer_behavior_abnormal

[Term]
id: WBPhenotype0000638
name: molt_defect
synonym: "Mlt" BROAD three_letter_name []
synonym: "Mult" BROAD three_letter_name []
is_a: WBPhenotype0000750 ! larval_development_abnormal

[Term]
id: WBPhenotype0000639
name: temperature_induced_dauer_formation_abnormal
is_a: WBPhenotype0000146 ! organism_temperature_response_abnormal
is_a: WBPhenotype0000637 ! dauer_formation_abnormal

[Term]
id: WBPhenotype0000640
name: egg_laying_abnormal
def: "The stage of eggs laid, egg laying cycle, or egg laying in response to external stimuli is altered." [pmid:11813735, pmid:9697864, WB:cab]
comment: visual inspection.
subset: phenotype_slim_wb
synonym: "Egl" BROAD three_letter_name []
synonym: "oviposition_abnormal" RELATED [GO:0018991]
is_a: WBPhenotype0000525 ! organism_behavior_abnormal

[Term]
id: WBPhenotype0000641
name: activity_level_abnormal
def: "The level of activity normally characteristic of C. elegans is altered." [WB:cab]
is_a: WBPhenotype0000643 ! locomotion_abnormal

[Term]
id: WBPhenotype0000642
name: hyperactive
def: "Worms are hyperactive compared to wild type." [WB:cab, WB:WBPaper00004402, WB:WBPaper00006395]
synonym: "Hya" BROAD three_letter_name []
is_a: WBPhenotype0000641 ! activity_level_abnormal

[Term]
id: WBPhenotype0000643
name: locomotion_abnormal
subset: phenotype_slim_wb
synonym: "movement_defect" RELATED []
synonym: "unc" BROAD three_letter_name []
synonym: "uncoordinated" RELATED []
is_a: WBPhenotype0001206 ! movement_abnormal

[Term]
id: WBPhenotype0000644
name: paralyzed
def: "Immobilized worm that is not responsive to external stimulation." [WB:cab]
synonym: "Prl" BROAD three_letter_name []
synonym: "Prz" RELATED []
is_a: WBPhenotype0000641 ! activity_level_abnormal

[Term]
id: WBPhenotype0000645
name: roller
synonym: "Rol" BROAD three_letter_name []
is_a: WBPhenotype0004017 ! locomotor_coordination_abnormal

[Term]
id: WBPhenotype0000646
name: sluggish
def: "Characterized by activity levels that are reduced compared with wild-type worms." [WB:cab]
synonym: "Slu" BROAD three_letter_name []
is_a: WBPhenotype0000641 ! activity_level_abnormal

[Term]
id: WBPhenotype0000647
name: copulation_abnormal
def: "Mating is altered." [WB:cab]
subset: phenotype_slim_wb
synonym: "Cod" BROAD three_letter_name []
is_a: WBPhenotype0000525 ! organism_behavior_abnormal

[Term]
id: WBPhenotype0000648
name: male_mating_abnormal
def: "Characteristic male behavior during mating is altered." [WB:cab]
is_a: WBPhenotype0000647 ! copulation_abnormal
is_a: WBPhenotype0000888 ! male_behavior_abnormal

[Term]
id: WBPhenotype0000649
name: vulva_location_abnormal
synonym: "Lov" RELATED []
is_a: WBPhenotype0004006 ! post_hermaphrodite_contact_abnormal

[Term]
id: WBPhenotype0000650
name: defecation_abnormal
def: "Activities characteristic of defecation behavior are altered." [WB:cab]
subset: phenotype_slim_wb
is_a: WBPhenotype0000525 ! organism_behavior_abnormal

[Term]
id: WBPhenotype0000651
name: constipated
synonym: "Con" BROAD three_letter_name []
is_a: WBPhenotype0000650 ! defecation_abnormal

[Term]
id: WBPhenotype0000652
name: sensory_system_abnormal
is_a: WBPhenotype0000612 ! nervous_system_physiology_abnormal

[Term]
id: WBPhenotype0000653
name: mechanosensory_system_abnormal
is_a: WBPhenotype0000612 ! nervous_system_physiology_abnormal

[Term]
id: WBPhenotype0000654
name: synaptic_vesicle_exocytosis_abnormal
is_a: WBPhenotype0000584 ! synaptic_transmission_abnormal
is_a: WBPhenotype0000728 ! exocytosis_abnormal

[Term]
id: WBPhenotype0000655
name: GABA_synaptic_transmission_abnormal
is_a: WBPhenotype0000584 ! synaptic_transmission_abnormal

[Term]
id: WBPhenotype0000656
name: acetylcholine_synaptic_transmission_abnormal
is_a: WBPhenotype0000584 ! synaptic_transmission_abnormal

[Term]
id: WBPhenotype0000657
name: neuronal_synaptic_transmission_abnormal
is_a: WBPhenotype0000584 ! synaptic_transmission_abnormal

[Term]
id: WBPhenotype0000658
name: neuromuscular_synaptic_transmission_abnormal
is_a: WBPhenotype0000584 ! synaptic_transmission_abnormal

[Term]
id: WBPhenotype0000659
name: feeding_behavior_abnormal
subset: phenotype_slim_wb
synonym: "Eat" BROAD three_letter_name []
is_a: WBPhenotype0000525 ! organism_behavior_abnormal

[Term]
id: WBPhenotype0000660
name: social_feeding_enhanced
synonym: "social_behavior_enhanced" RELATED []
is_a: WBPhenotype0000659 ! feeding_behavior_abnormal

[Term]
id: WBPhenotype0000661
name: solitary_feeding_enhanced
synonym: "solitary_behavior_enhanced" RELATED []
is_a: WBPhenotype0000659 ! feeding_behavior_abnormal

[Term]
id: WBPhenotype0000662
name: foraging_behavior_abnormal
subset: phenotype_slim_wb
is_a: WBPhenotype0000525 ! organism_behavior_abnormal

[Term]
id: WBPhenotype0000663
name: osmotic_avoidance_abnormal
def: "Characteristic tendency of worms to avoid solutions of high osmotic strength is altered." [WB:cab]
is_a: WBPhenotype0000738 ! organism_environmental_stimulus_response_abnormal

[Term]
id: WBPhenotype0000664
name: exaggerated_body_bends
alt_id: WBPhenotype0004021
synonym: "exaggerated_body_bends" EXACT []
synonym: "loopy" RELATED []
is_a: WBPhenotype0004018 ! sinusoidal_movement_abnormal

[Term]
id: WBPhenotype0000665
name: connection_of_gonad_abnormal
is_a: WBPhenotype0000605 ! reproductive_system_morphology_abnormal

[Term]
id: WBPhenotype0000666
name: ovulation_abnormal
subset: phenotype_slim_wb
is_a: WBPhenotype0000525 ! organism_behavior_abnormal

[Term]
id: WBPhenotype0000667
name: gonad_displaced
is_a: WBPhenotype0000977 ! somatic_gonad_morphology_abnormal

[Term]
id: WBPhenotype0000668
name: endomitotic_oocytes
def: "Any abnormality that results in the presence, in proximal gonad arms, of oocytes with distended polyploid nuclei.  Such oocytes mature and exit diakinesis, but are often not properly ovulated or fertilized." [WB:kmva]
synonym: "arrest_in_meiosis_I" RELATED []
synonym: "Emo" BROAD three_letter_name []
is_a: WBPhenotype0000186 ! oogenesis_abnormal

[Term]
id: WBPhenotype0000669
name: sex_muscle_abnormal
is_a: WBPhenotype0000860 ! nonstriated_muscle_development_abnormal
relationship: part_of WBPhenotype0000624 ! reproductive_system_development_abnormal

[Term]
id: WBPhenotype0000670
name: spermatogenesis_abnormal
is_a: WBPhenotype0000774 ! gametogenesis_abnormal

[Term]
id: WBPhenotype0000671
name: resistant_to_copper
is_a: WBPhenotype0000592 ! copper_response_abnormal

[Term]
id: WBPhenotype0000672
name: presynaptic_vesicle_cluster_localization_abnormal
is_a: WBPhenotype0000102 ! presynaptic_vesicle_clusters_abnormal

[Term]
id: WBPhenotype0000673
name: brood_size_abnormal
is_a: WBPhenotype0000806 ! hermaphrodite_fertility_abnormal

[Term]
id: WBPhenotype0000674
name: slow_development
is_a: WBPhenotype0000043 ! general_pace_of_development_abnormal

[Term]
id: WBPhenotype0000675
name: zygotic_lethal
is_a: WBPhenotype0000213 ! zygotic_development_abnormal

[Term]
id: WBPhenotype0000676
name: growth_rate_abnormal
is_a: WBPhenotype0000030 ! growth_abnormal

[Term]
id: WBPhenotype0000677
name: chemosensation_defective
is_a: WBPhenotype0001050 ! chemosensation_abnormal

[Term]
id: WBPhenotype0000678
name: no_copper_sensitivity
is_a: WBPhenotype0000592 ! copper_response_abnormal

[Term]
id: WBPhenotype0000679
name: transgene_localization_abnormal
is_a: WBPhenotype0000306 ! transgene_expression_abnormal

[Term]
id: WBPhenotype0000680
name: aldicarb_response_abnormal
is_a: WBPhenotype0000631 ! drug_response_abnormal

[Term]
id: WBPhenotype0000681
name: dmpp_response_abnormal
is_a: WBPhenotype0000631 ! drug_response_abnormal

[Term]
id: WBPhenotype0000682
name: feminization_of_germline
def: "Hermaphrodites transformed into fertile females; XO animals are somatically male but may produce oocytes instead of, or in addition to, sperm." [pmid:3396865, WB:cab]
synonym: "Fog" BROAD three_letter_name []
is_a: WBPhenotype0000812 ! germ_cell_development_abnormal

[Term]
id: WBPhenotype0000683
name: masculinization_of_germline
synonym: "Mog" BROAD three_letter_name []
is_a: WBPhenotype0000688 ! sterile
is_a: WBPhenotype0000812 ! germ_cell_development_abnormal
is_a: WBPhenotype0001022 ! hermaphrodite_sexual_development_abnormal

[Term]
id: WBPhenotype0000684
name: fewer_germ_cells
def: "Fewer germ cells compared with wild-type animals." [WB:cab]
synonym: "Fgc" BROAD three_letter_name []
is_a: WBPhenotype0000688 ! sterile
is_a: WBPhenotype0000823 ! germ_cell_proliferation_abnormal

[Term]
id: WBPhenotype0000685
name: slow_larval_growth
is_a: WBPhenotype0001016 ! larval_growth_abnormal

[Term]
id: WBPhenotype0000686
name: organism_ionizing_radiation_response_abnormal
is_a: WBPhenotype0000067 ! organism_stress_response_abnormal

[Term]
id: WBPhenotype0000687
name: feminization_of_XX_and_XO_animals
def: "Feminization of XX and XO animals such that both develop to become fertile females." [WB:cab]
synonym: "Fem" BROAD three_letter_name []
is_a: WBPhenotype0000049 ! postembryonic_development_abnormal
is_a: WBPhenotype0000624 ! reproductive_system_development_abnormal

[Term]
id: WBPhenotype0000688
name: sterile
synonym: "Ste" BROAD three_letter_name []
is_a: WBPhenotype0000145 ! fertility_abnormal

[Term]
id: WBPhenotype0000689
name: maternal_sterile
def: "Worm injected with inhibiting RNA produces no, or few embryos (less than 100 embryos)." [WB:cab, WB:cgc5599, WB:cgc7141]
synonym: "Reduced fecundity of injected worm" EXACT [WB:cgc5599]
synonym: "Ste" BROAD three_letter_name []
synonym: "sterile_F0_fertility_problems" RELATED []
is_a: WBPhenotype0000694 ! hermaphrodite_sterile

[Term]
id: WBPhenotype0000690
name: gonad_migration_abnormal
synonym: "Gom" BROAD three_letter_name []
relationship: part_of WBPhenotype0000624 ! reproductive_system_development_abnormal

[Term]
id: WBPhenotype0000691
name: gonad_development_abnormal
synonym: "Gon" RELATED []
synonym: "gonadogenesis_abnormal" RELATED []
is_a: WBPhenotype0000624 ! reproductive_system_development_abnormal

[Term]
id: WBPhenotype0000692
name: male_sterile
is_a: WBPhenotype0000688 ! sterile

[Term]
id: WBPhenotype0000693
name: male_sperm_fertilization_defect
is_a: WBPhenotype0000692 ! male_sterile

[Term]
id: WBPhenotype0000694
name: hermaphrodite_sterile
is_a: WBPhenotype0000688 ! sterile

[Term]
id: WBPhenotype0000695
name: vulva_morphology_abnormal
relationship: part_of WBPhenotype0000605 ! reproductive_system_morphology_abnormal

[Term]
id: WBPhenotype0000696
name: everted_vulva
def: "Eversion of the vulva and associated gonadal region, along with gonadal defects, invariable sterility, and frequent rupture at the last molt." [WB:cab, WB:WBPerson261]
synonym: "Evl" BROAD three_letter_name []
is_a: WBPhenotype0000695 ! vulva_morphology_abnormal

[Term]
id: WBPhenotype0000697
name: protruding_vulva
synonym: "Pvl" BROAD three_letter_name []
synonym: "Pvu" BROAD three_letter_name []
is_a: WBPhenotype0000695 ! vulva_morphology_abnormal

[Term]
id: WBPhenotype0000698
name: vulvaless
synonym: "Vul" BROAD three_letter_name []
is_a: WBPhenotype0000699 ! vulva_development_abnormal

[Term]
id: WBPhenotype0000699
name: vulva_development_abnormal
def: "Abnormal vulval development" [WB:IA]
relationship: part_of WBPhenotype0000624 ! reproductive_system_development_abnormal

[Term]
id: WBPhenotype0000700
name: multivulva
synonym: "Muv" BROAD three_letter_name []
is_a: WBPhenotype0000218 ! vulval_cell_induction_increased

[Term]
id: WBPhenotype0000701
name: epithelial_development_abnormal
synonym: "hypodermal_development_abnormal" RELATED []
relationship: part_of WBPhenotype0000619 ! epithelial_system_development_abnormal

[Term]
id: WBPhenotype0000702
name: epithelial_cell_fusion_failure
xref: PMID:15341747
is_a: WBPhenotype0000701 ! epithelial_development_abnormal

[Term]
id: WBPhenotype0000703
name: epithelial_morphology_abnormal
synonym: "hypodermal_morphology_abnormal" RELATED []
relationship: part_of WBPhenotype0000600 ! epithelial_system_morphology_abnormal

[Term]
id: WBPhenotype0000704
name: excretory_canal_morphology_abnormal
relationship: part_of WBPhenotype0000916 ! excretory_cell_morphology_abnormal

[Term]
id: WBPhenotype0000705
name: intestinal_cell_development_abnormal
is_a: WBPhenotype0000529 ! cell_development_abnormal
relationship: part_of WBPhenotype0000708 ! intestinal_development_abnormal

[Term]
id: WBPhenotype0000706
name: gut_granule_biogenesis_reduced
synonym: "Glo" BROAD three_letter_name []
synonym: "gut_granule_loss" RELATED []
xref: PMID:15843430
is_a: WBPhenotype0000705 ! intestinal_cell_development_abnormal

[Term]
id: WBPhenotype0000707
name: pharyngeal_development_abnormal
relationship: part_of WBPhenotype0000617 ! alimentary_system_development_abnormal

[Term]
id: WBPhenotype0000708
name: intestinal_development_abnormal
synonym: "gut_development" RELATED []
relationship: part_of WBPhenotype0000617 ! alimentary_system_development_abnormal

[Term]
id: WBPhenotype0000709
name: pharyngeal_morphology_abnormal
relationship: part_of WBPhenotype0000598 ! alimentary_system_morphology_abnormal

[Term]
id: WBPhenotype0000710
name: intestinal_morphology_abnormal
relationship: part_of WBPhenotype0000598 ! alimentary_system_morphology_abnormal

[Term]
id: WBPhenotype0000711
name: organism_hypersensitive_ionizing_radiation
is_a: WBPhenotype0000686 ! organism_ionizing_radiation_response_abnormal

[Term]
id: WBPhenotype0000712
name: germ_cell_ionizing_radiation_response_abnormal
is_a: WBPhenotype0000987 ! germ_cell_physiology_abnormal

[Term]
id: WBPhenotype0000713
name: spermatocyte_division_abnormal
is_a: WBPhenotype0000987 ! germ_cell_physiology_abnormal

[Term]
id: WBPhenotype0000714
name: disorganized_muscle
is_a: WBPhenotype0000603 ! muscle_system_morphology_abnormal

[Term]
id: WBPhenotype0000715
name: muscle_excess
def: "Any abnormality that results in a greater than wild-type number of embryonic muscle cells." [WB:kmva, WB:WBPaper00001584]
synonym: "Mex" BROAD three_letter_name [WB:WBPaper00001584]
is_a: WBPhenotype0000622 ! muscle_system_development_abnormal

[Term]
id: WBPhenotype0000716
name: muscle_cell_attachment_abnormal
is_a: WBPhenotype0000990 ! muscle_cell_physiology_abnormal

[Term]
id: WBPhenotype0000717
name: gene_expression_abnormal
is_a: WBPhenotype0000027 ! organism_metabolism_processing_abnormal

[Term]
id: WBPhenotype0000718
name: dosage_compensation_abnormal
is_a: WBPhenotype0000717 ! gene_expression_abnormal

[Term]
id: WBPhenotype0000719
name: reporter_gene_expression_abnormal
is_obsolete: true

[Term]
id: WBPhenotype0000720
name: pattern_of_reporter_gene_expression_abnormal
is_obsolete: true

[Term]
id: WBPhenotype0000721
name: level_of_reporter_gene_expression_abnormal
is_obsolete: true

[Term]
id: WBPhenotype0000722
name: nucleoli_abnormal
subset: phenotype_slim_wb
is_a: WBPhenotype0000533 ! cell_morphology_abnormal

[Term]
id: WBPhenotype0000724
name: protein_secretion_abnormal
is_a: WBPhenotype0000258 ! cell_secretion_abnormal

[Term]
id: WBPhenotype0000725
name: lipid_metabolism_abnormal
is_a: WBPhenotype0000027 ! organism_metabolism_processing_abnormal

[Term]
id: WBPhenotype0000726
name: ligand_binding_abnormal
is_a: WBPhenotype0000727 ! enzyme_activity_abnormal

[Term]
id: WBPhenotype0000727
name: enzyme_activity_abnormal
is_a: WBPhenotype0000027 ! organism_metabolism_processing_abnormal

[Term]
id: WBPhenotype0000728
name: exocytosis_abnormal
is_a: WBPhenotype0000258 ! cell_secretion_abnormal

[Term]
id: WBPhenotype0000729
name: cell_death_abnormal
def: "Any abnormality in the specific activation or halting of processes within a cell that causes its vital functions to suddenly cease and culminate in cell death." [GO:0008219, WB:cab]
subset: phenotype_slim_wb
synonym: "Ced" BROAD three_letter_name []
is_a: WBPhenotype0000536 ! cell_physiology_abnormal

[Term]
id: WBPhenotype0000730
name: apoptosis_abnormal
synonym: "Ced" BROAD three_letter_name []
is_a: WBPhenotype0001172 ! programmed_cell_death_abnormal

[Term]
id: WBPhenotype0000731
name: increased_germ_cell_sensitivity_ionizing_radiation
is_a: WBPhenotype0000712 ! germ_cell_ionizing_radiation_response_abnormal

[Term]
id: WBPhenotype0000732
name: DNA_metabolism_abnormal
is_a: WBPhenotype0000585 ! cell_homeostasis_metabolism_abnormal

[Term]
id: WBPhenotype0000733
name: catalysis_abnormal
is_a: WBPhenotype0000727 ! enzyme_activity_abnormal

[Term]
id: WBPhenotype0000734
name: hypodermal_cell_physiology_abnormal
is_a: WBPhenotype0000608 ! epithelial_system_physiology_abnormal

[Term]
id: WBPhenotype0000735
name: endoreduplication_of_hypodermal_nuclei_abnormal
is_a: WBPhenotype0000734 ! hypodermal_cell_physiology_abnormal

[Term]
id: WBPhenotype0000736
name: autophagic_cell_death_abnormal
synonym: "autophagy_abnormal" RELATED []
is_a: WBPhenotype0000729 ! cell_death_abnormal

[Term]
id: WBPhenotype0000737
name: increased_germ_cell_resistance_ionizing_radiation
is_a: WBPhenotype0000712 ! germ_cell_ionizing_radiation_response_abnormal

[Term]
id: WBPhenotype0000738
name: organism_environmental_stimulus_response_abnormal
def: "Characteristic response to a change in the environment is altered." [WB:cab]
subset: phenotype_slim_wb
is_a: WBPhenotype0000577 ! organism_homeostasis_metabolism_abnormal

[Term]
id: WBPhenotype0000739
name: DNA_damage_response_abnormal
is_a: WBPhenotype0000142 ! cell_stress_response_abnormal

[Term]
id: WBPhenotype0000740
name: cell_cycle_abnormal
subset: phenotype_slim_wb
is_a: WBPhenotype0000536 ! cell_physiology_abnormal

[Term]
id: WBPhenotype0000741
name: DNA_damage_checkpoint_abnormal
is_a: WBPhenotype0000740 ! cell_cycle_abnormal

[Term]
id: WBPhenotype0000742
name: DNA_recombination_abnormal
is_a: WBPhenotype0000732 ! DNA_metabolism_abnormal

[Term]
id: WBPhenotype0000743
name: RNAi_response_abnormal
synonym: "Rde" BROAD three_letter_name []
is_a: WBPhenotype0000577 ! organism_homeostasis_metabolism_abnormal

[Term]
id: WBPhenotype0000744
name: transgene_induced_cosuppression_abnormal
is_a: WBPhenotype0000577 ! organism_homeostasis_metabolism_abnormal

[Term]
id: WBPhenotype0000745
name: transposon_silencing_abnormal
is_a: WBPhenotype0000577 ! organism_homeostasis_metabolism_abnormal

[Term]
id: WBPhenotype0000746
name: cell_division_abnormal
subset: phenotype_slim_wb
is_a: WBPhenotype0000536 ! cell_physiology_abnormal

[Term]
id: WBPhenotype0000747
name: pharyngeal_contraction_defect
is_a: WBPhenotype0000980 ! pharyngeal_contraction_abnormal

[Term]
id: WBPhenotype0000748
name: asymmetric_cell_division_abnormal_early_emb
def: "Symmetric (PAR-like) divisions or excessive posterior displacement (zyg-8 like phenotypes)." [WB:cab, WB:cgc7141]
synonym: "Emb" BROAD three_letter_name []
synonym: "Let" BROAD three_letter_name []
is_a: WBPhenotype0000746 ! cell_division_abnormal
is_a: WBPhenotype0001100 ! early_embryonic_lethal

[Term]
id: WBPhenotype0000749
name: embryonic_development_abnormal
subset: phenotype_slim_wb
synonym: "developmental_defects_detected_in_embryos" RELATED []
is_a: WBPhenotype0000531 ! organism_development_abnormal

[Term]
id: WBPhenotype0000750
name: larval_development_abnormal
is_a: WBPhenotype0000049 ! postembryonic_development_abnormal

[Term]
id: WBPhenotype0000751
name: L1_larval_development_abnormal
is_a: WBPhenotype0000750 ! larval_development_abnormal

[Term]
id: WBPhenotype0000752
name: L2_larval_development_abnormal
is_a: WBPhenotype0000750 ! larval_development_abnormal

[Term]
id: WBPhenotype0000753
name: L3_larval_development_abnormal
is_a: WBPhenotype0000750 ! larval_development_abnormal

[Term]
id: WBPhenotype0000754
name: L4_larval_development_abnormal
is_a: WBPhenotype0000750 ! larval_development_abnormal

[Term]
id: WBPhenotype0000755
name: L1_L2_molt_abnormal
is_a: WBPhenotype0000638 ! molt_defect

[Term]
id: WBPhenotype0000756
name: L2_L3_molt_abnormal
is_a: WBPhenotype0000638 ! molt_defect

[Term]
id: WBPhenotype0000757
name: L3_L4_molt_abnormal
is_a: WBPhenotype0000638 ! molt_defect

[Term]
id: WBPhenotype0000758
name: L4_adult_molt_abnormal
is_a: WBPhenotype0000638 ! molt_defect

[Term]
id: WBPhenotype0000759
name: spindle_abnormal_early_emb
synonym: "Emb" BROAD three_letter_name []
synonym: "Spd" BROAD three_letter_name []
is_a: WBPhenotype0000764 ! embryonic_cell_organization_biogenesis_abnormal
is_a: WBPhenotype0001100 ! early_embryonic_lethal

[Term]
id: WBPhenotype0000760
name: spindle_orientation_abnormal_early_emb
synonym: "Emb" BROAD three_letter_name []
synonym: "Spn" BROAD three_letter_name []
is_a: WBPhenotype0000761 ! spindle_position_orientation_abnormal_early_emb

[Term]
id: WBPhenotype0000761
name: spindle_position_orientation_abnormal_early_emb
synonym: "Emb" BROAD three_letter_name []
synonym: "Spi" RELATED []
synonym: "Spo" BROAD three_letter_name []
is_a: WBPhenotype0001102 ! mitotic_spindle_abnormal_early_emb

[Term]
id: WBPhenotype0000762
name: spindle_position_abnormal_early_emb
synonym: "Abs" BROAD three_letter_name []
synonym: "Emb" BROAD three_letter_name []
is_a: WBPhenotype0000761 ! spindle_position_orientation_abnormal_early_emb

[Term]
id: WBPhenotype0000763
name: embryonic_cell_physiology_abnormal
subset: phenotype_slim_wb
is_a: WBPhenotype0000536 ! cell_physiology_abnormal

[Term]
id: WBPhenotype0000764
name: embryonic_cell_organization_biogenesis_abnormal
is_a: WBPhenotype0000749 ! embryonic_development_abnormal
is_a: WBPhenotype0000763 ! embryonic_cell_physiology_abnormal
is_a: WBPhenotype0010002 ! cell_organization_and_biogenesis_abnormal

[Term]
id: WBPhenotype0000765
name: spindle_elongation_integrity_abnormal_early_emb
def: "Bipolar spindle shows clear elongation defect." [WB:cab, WB:cgc7141]
synonym: "Emb" BROAD three_letter_name []
is_a: WBPhenotype0001102 ! mitotic_spindle_abnormal_early_emb

[Term]
id: WBPhenotype0000766
name: centrosome_pair_and_associated_pronuclear_rotation_abnormal
synonym: "Rot" BROAD three_letter_name []
is_a: WBPhenotype0000764 ! embryonic_cell_organization_biogenesis_abnormal

[Term]
id: WBPhenotype0000767
name: integrity_of_membranous_organelles_abnormal_early__emb
def: "Sparse or enlarged yolk granules." [WB:cab, WB:WBPaper00025054]
synonym: "Emb" BROAD three_letter_name []
is_a: WBPhenotype0000585 ! cell_homeostasis_metabolism_abnormal
is_a: WBPhenotype0001100 ! early_embryonic_lethal

[Term]
id: WBPhenotype0000768
name: cytoplasmic_structures_abnormal_early_emb
def: "Areas devoid of yolk granules throughout the embryo." [WB:cab, WB:cgc7141]
synonym: "Aberrant_Cytoplasmic_Structures" RELATED []
synonym: "cellular_structures_disorganized" RELATED []
synonym: "Emb" BROAD three_letter_name []
is_a: WBPhenotype0001081 ! cytoplasmic_morphology_abnormal_early_emb

[Term]
id: WBPhenotype0000769
name: cytoplasmic_appearance_abnormal_early_emb
synonym: "Emb" BROAD three_letter_name []
is_a: WBPhenotype0000533 ! cell_morphology_abnormal
is_a: WBPhenotype0001100 ! early_embryonic_lethal

[Term]
id: WBPhenotype0000770
name: embryonic_cell_morphology_abnormal
subset: phenotype_slim_wb
is_a: WBPhenotype0000533 ! cell_morphology_abnormal

[Term]
id: WBPhenotype0000771
name: centrosome_attachment_abnormal_early_emb
def: "Centrosomes detach from the male pronucleus." [WB:cab, WB:cgc7141]
synonym: "Emb" BROAD three_letter_name []
is_a: WBPhenotype0000770 ! embryonic_cell_morphology_abnormal
is_a: WBPhenotype0001100 ! early_embryonic_lethal

[Term]
id: WBPhenotype0000772
name: sister_chromatid_segregation_abnormal_early_emb
def: "Daughter nuclei are deformed and stay close to central cortex, cytokinesis defects." [WB:cab, WB:cgc7141]
synonym: "Emb" BROAD three_letter_name []
is_a: WBPhenotype0001078 ! cytokinesis_abnormal_early_emb

[Term]
id: WBPhenotype0000773
name: chromosome_segregation_abnormal
def: "Any abnormality in the processes that regulate the apportionment of chromosomes to each of two daughter cells." [WB:kmva]
is_a: WBPhenotype0000585 ! cell_homeostasis_metabolism_abnormal

[Term]
id: WBPhenotype0000774
name: gametogenesis_abnormal
is_a: WBPhenotype0000624 ! reproductive_system_development_abnormal

[Term]
id: WBPhenotype0000775
name: meiosis_abnormal
synonym: "Mei" RELATED []
is_a: WBPhenotype0000823 ! germ_cell_proliferation_abnormal

[Term]
id: WBPhenotype0000776
name: passage_through_meiosis_abnormal_early_emb
def: "Male and female PNs not visible; embryo often fills egg shell completely." [WB:cab, WB:cgc71441]
synonym: "Emb" BROAD three_letter_name []
is_a: WBPhenotype0000775 ! meiosis_abnormal
is_a: WBPhenotype0001041 ! meiosis_abnormal_early_emb

[Term]
id: WBPhenotype0000777
name: polar_body_extrusion_abnormal_early_emb
def: "Unextruded or resorbed polar body(ies) leading to an extra PNs in P0 and/or extra karyomeres in AB/P1." [WB:cab, WB:cgc7141]
synonym: "Emb" BROAD three_letter_name []
is_a: WBPhenotype0000775 ! meiosis_abnormal
is_a: WBPhenotype0001147 ! polar_body_abnormal_early_emb

[Term]
id: WBPhenotype0000778
name: feeding_inefficient
is_a: WBPhenotype0000659 ! feeding_behavior_abnormal

[Term]
id: WBPhenotype0000779
name: late_embryonic_arrest
is_a: WBPhenotype0000867 ! embryonic_arrest

[Term]
id: WBPhenotype0000780
name: shaker
is_a: WBPhenotype0001206 ! movement_abnormal

[Term]
id: WBPhenotype0000781
name: thin_filaments_abnormal
is_a: WBPhenotype0000553 ! muscle_ultrastructure_disorganized

[Term]
id: WBPhenotype0000782
name: thick_filaments_abnormal
is_a: WBPhenotype0000553 ! muscle_ultrastructure_disorganized

[Term]
id: WBPhenotype0000783
name: no_M_line
is_a: WBPhenotype0000782 ! thick_filaments_abnormal

[Term]
id: WBPhenotype0000784
name: male_fertility_abnormal
is_a: WBPhenotype0000145 ! fertility_abnormal

[Term]
id: WBPhenotype0000785
name: body_part_pigmentation_abnormal
is_a: WBPhenotype0000278 ! body_region_pigmentation_abnormal

[Term]
id: WBPhenotype0000786
name: body_axis_pigmentation_abnormal
is_a: WBPhenotype0000278 ! body_region_pigmentation_abnormal

[Term]
id: WBPhenotype0000787
name: posterior_pale
is_a: WBPhenotype0000984 ! posterior_pigmentation_abnormal

[Term]
id: WBPhenotype0000788
name: anterior_pale
is_a: WBPhenotype0000971 ! anterior_pigmentation_abnormal

[Term]
id: WBPhenotype0000789
name: fluoxetine_hypersensitive
is_a: WBPhenotype0000010 ! hypersensitive_to_drug

[Term]
id: WBPhenotype0000790
name: fluoxetine_resistant
is_a: WBPhenotype0000011 ! resistant_to_drug

[Term]
id: WBPhenotype0000791
name: nose_resistant_to_fluoxetine
is_a: WBPhenotype0000790 ! fluoxetine_resistant

[Term]
id: WBPhenotype0000792
name: anterior_body_morphology_abnormal
is_a: WBPhenotype0000581 ! body_axis_morphology_abnormal

[Term]
id: WBPhenotype0000793
name: posterior_body_morphology_abnormal
is_a: WBPhenotype0000581 ! body_axis_morphology_abnormal

[Term]
id: WBPhenotype0000794
name: posterior_body_thin
is_a: WBPhenotype0000793 ! posterior_body_morphology_abnormal

[Term]
id: WBPhenotype0000795
name: body_axis_behavior_abnormal
is_a: WBPhenotype0000522 ! organism_region_behavior_abnormal

[Term]
id: WBPhenotype0000796
name: posterior_body_uncoordinated
def: "Posterior of the worm does not move in a sinusoidal motion fashion that is coordinated with the anterior body movement of the worm." [WB:cab]
is_a: WBPhenotype0000797 ! posterior_body_behavior_abnormal

[Term]
id: WBPhenotype0000797
name: posterior_body_behavior_abnormal
is_a: WBPhenotype0000795 ! body_axis_behavior_abnormal

[Term]
id: WBPhenotype0000798
name: anterior_body_behavior_abnormal
is_a: WBPhenotype0000795 ! body_axis_behavior_abnormal

[Term]
id: WBPhenotype0000799
name: anterior_development_abnormal
is_a: WBPhenotype0000578 ! body_axis_development_abnormal

[Term]
id: WBPhenotype0000800
name: posterior_development_abnormal
is_a: WBPhenotype0000578 ! body_axis_development_abnormal

[Term]
id: WBPhenotype0000801
name: ventral_development_abnormal
is_a: WBPhenotype0000578 ! body_axis_development_abnormal

[Term]
id: WBPhenotype0000802
name: dorsal_development_abnormal
is_a: WBPhenotype0000578 ! body_axis_development_abnormal

[Term]
id: WBPhenotype0000803
name: head_development_abnormal
is_a: WBPhenotype0000579 ! organism_segment_development_abnormal

[Term]
id: WBPhenotype0000804
name: body_development_abnormal
is_a: WBPhenotype0000579 ! organism_segment_development_abnormal

[Term]
id: WBPhenotype0000805
name: tail_development_abnormal
is_a: WBPhenotype0000579 ! organism_segment_development_abnormal

[Term]
id: WBPhenotype0000806
name: hermaphrodite_fertility_abnormal
is_a: WBPhenotype0000145 ! fertility_abnormal

[Term]
id: WBPhenotype0000807
name: G_lineage_abnormal
is_a: WBPhenotype0000825 ! postembryonic_cell_lineage_abnormal

[Term]
id: WBPhenotype0000808
name: K_lineage_abnormal
is_a: WBPhenotype0000825 ! postembryonic_cell_lineage_abnormal

[Term]
id: WBPhenotype0000809
name: male_specific_lineage_abnormal
is_a: WBPhenotype0000825 ! postembryonic_cell_lineage_abnormal

[Term]
id: WBPhenotype0000810
name: blast_cell_development_abnormal
is_a: WBPhenotype0000529 ! cell_development_abnormal

[Term]
id: WBPhenotype0000811
name: epithelial_cell_development_abnormal
is_a: WBPhenotype0000529 ! cell_development_abnormal

[Term]
id: WBPhenotype0000812
name: germ_cell_development_abnormal
synonym: "germline_development_abnormal" RELATED []
is_a: WBPhenotype0000529 ! cell_development_abnormal
relationship: part_of WBPhenotype0000774 ! gametogenesis_abnormal

[Term]
id: WBPhenotype0000813
name: gland_cell_development_abnormal
is_a: WBPhenotype0000529 ! cell_development_abnormal

[Term]
id: WBPhenotype0000814
name: marginal_cell_development_abnormal
is_a: WBPhenotype0000529 ! cell_development_abnormal

[Term]
id: WBPhenotype0000815
name: muscle_cell_development_abnormal
is_a: WBPhenotype0000529 ! cell_development_abnormal

[Term]
id: WBPhenotype0000816
name: neuron_development_abnormal
is_a: WBPhenotype0000529 ! cell_development_abnormal

[Term]
id: WBPhenotype0000817
name: uterine_vulval_cell_development_abnormal
is_a: WBPhenotype0000529 ! cell_development_abnormal

[Term]
id: WBPhenotype0000818
name: adult_behavior_abnormal
def: "Activity characteristic of an adult worm is altered." [WB:cab]
is_a: WBPhenotype0000819 ! postembryonic_behavior_abnormal

[Term]
id: WBPhenotype0000819
name: postembryonic_behavior_abnormal
def: "Behavior characteristic of postembryonic stage(s) is altered." [WB:cab]
is_a: WBPhenotype0001000 ! developmental_behavior_abnormal

[Term]
id: WBPhenotype0000820
name: embryonic_behavior_abnormal
def: "Activity characteristic of an embryo is altered." [WB:cab]
is_a: WBPhenotype0001000 ! developmental_behavior_abnormal

[Term]
id: WBPhenotype0000821
name: sexually_dimorphic_behavior_abnormal
subset: phenotype_slim_wb
is_a: WBPhenotype0000525 ! organism_behavior_abnormal

[Term]
id: WBPhenotype0000822
name: sex_determination_abnormal
def: "Any abnormality in the processes that govern the sexually dimorphic development of germline or somatic tissue." [WB:kmva]
synonym: "sex_specific_development_abnormal" RELATED []
is_a: WBPhenotype0000930 ! sexually_dimorphic_development_abnormal

[Term]
id: WBPhenotype0000823
name: germ_cell_proliferation_abnormal
def: "Germ cell divisions are either expanded are reduced." [WB:cab]
synonym: "germ_line_proliferation_abnormal" RELATED []
synonym: "glp" BROAD three_letter_name []
is_a: WBPhenotype0000812 ! germ_cell_development_abnormal

[Term]
id: WBPhenotype0000824
name: embryonic_cell_lineage_abnormal
is_a: WBPhenotype0000093 ! lineage_abnormal

[Term]
id: WBPhenotype0000825
name: postembryonic_cell_lineage_abnormal
is_a: WBPhenotype0000093 ! lineage_abnormal

[Term]
id: WBPhenotype0000826
name: H_Lineage_abnormal
is_a: WBPhenotype0000825 ! postembryonic_cell_lineage_abnormal

[Term]
id: WBPhenotype0000827
name: V_lineage_abnormal
is_a: WBPhenotype0000825 ! postembryonic_cell_lineage_abnormal

[Term]
id: WBPhenotype0000828
name: T_lineage_abnormal
is_a: WBPhenotype0000825 ! postembryonic_cell_lineage_abnormal

[Term]
id: WBPhenotype0000829
name: Q_lineage_abnormal
is_a: WBPhenotype0000825 ! postembryonic_cell_lineage_abnormal

[Term]
id: WBPhenotype0000830
name: B_lineage_abnormal
is_a: WBPhenotype0000809 ! male_specific_lineage_abnormal

[Term]
id: WBPhenotype0000831
name: Y_lineage_abnormal
is_a: WBPhenotype0000809 ! male_specific_lineage_abnormal

[Term]
id: WBPhenotype0000832
name: C_lineage_abnormal
is_a: WBPhenotype0000824 ! embryonic_cell_lineage_abnormal

[Term]
id: WBPhenotype0000833
name: U_lineage_abnormal
is_a: WBPhenotype0000809 ! male_specific_lineage_abnormal

[Term]
id: WBPhenotype0000834
name: E_lineage_abnormal
is_a: WBPhenotype0000824 ! embryonic_cell_lineage_abnormal

[Term]
id: WBPhenotype0000835
name: F_lineage_abnormal
is_a: WBPhenotype0000809 ! male_specific_lineage_abnormal

[Term]
id: WBPhenotype0000836
name: gonadal_lineage_abnormal
is_a: WBPhenotype0000825 ! postembryonic_cell_lineage_abnormal

[Term]
id: WBPhenotype0000837
name: hermaphrodite_gonadal_lineage_abnormal
is_a: WBPhenotype0000836 ! gonadal_lineage_abnormal

[Term]
id: WBPhenotype0000838
name: male_gonadal_lineage_abnormal
is_a: WBPhenotype0000809 ! male_specific_lineage_abnormal
is_a: WBPhenotype0000836 ! gonadal_lineage_abnormal

[Term]
id: WBPhenotype0000839
name: Z1_hermaphrodite_lineage_abnormal
is_a: WBPhenotype0000837 ! hermaphrodite_gonadal_lineage_abnormal

[Term]
id: WBPhenotype0000840
name: Z4_hermaphrodite_lineage_abnormal
is_a: WBPhenotype0000837 ! hermaphrodite_gonadal_lineage_abnormal

[Term]
id: WBPhenotype0000841
name: Z1_male_lineage_abnormal
is_a: WBPhenotype0000838 ! male_gonadal_lineage_abnormal

[Term]
id: WBPhenotype0000842
name: Z4_male_lineage_abnormal
is_a: WBPhenotype0000838 ! male_gonadal_lineage_abnormal

[Term]
id: WBPhenotype0000843
name: male_mating_efficiency_reduced
is_a: WBPhenotype0000648 ! male_mating_abnormal

[Term]
id: WBPhenotype0000844
name: serotonin_induced_pumping_abnormal
is_a: WBPhenotype0000024 ! serotonin_resistant
is_a: WBPhenotype0001285 ! induced_pharyngeal_pumping_abnormal

[Term]
id: WBPhenotype0000845
name: levamisole_response_abnormal
is_a: WBPhenotype0000631 ! drug_response_abnormal

[Term]
id: WBPhenotype0000846
name: presynaptic_region_physiology_abnormal
is_a: WBPhenotype0000584 ! synaptic_transmission_abnormal

[Term]
id: WBPhenotype0000847
name: presynaptic_component_localization_abnormal
relationship: part_of WBPhenotype0000672 ! presynaptic_vesicle_cluster_localization_abnormal

[Term]
id: WBPhenotype0000848
name: developmental_delay
is_a: WBPhenotype0000043 ! general_pace_of_development_abnormal

[Term]
id: WBPhenotype0000849
name: amphid_physiology_abnormal
is_a: WBPhenotype0000652 ! sensory_system_abnormal

[Term]
id: WBPhenotype0000850
name: touch_insensitive_anterior_body
is_a: WBPhenotype0000456 ! touch_insensitive

[Term]
id: WBPhenotype0000851
name: ciliated_neuron_physiology_abnormal
is_a: WBPhenotype0000991 ! neuron_physiology_abnormal

[Term]
id: WBPhenotype0000852
name: coelomocyte_development_abnormal
relationship: part_of WBPhenotype0000618 ! coelomic_system_development_abnormal

[Term]
id: WBPhenotype0000853
name: intraflagellar_transport_abnormal
synonym: "ift_abnormal" RELATED []
is_a: WBPhenotype0000851 ! ciliated_neuron_physiology_abnormal

[Term]
id: WBPhenotype0000854
name: intraflagellar_transport_defective
synonym: "ift_defective" RELATED []
is_a: WBPhenotype0000853 ! intraflagellar_transport_abnormal

[Term]
id: WBPhenotype0000855
name: pseudocoelom_development_abnormal
is_a: WBPhenotype0000200 ! pericellular_component_development_abnormal

[Term]
id: WBPhenotype0000856
name: excretory_gland_cell_development_abnormal
relationship: part_of WBPhenotype0000620 ! excretory_secretory_system_development_abnormal

[Term]
id: WBPhenotype0000857
name: excretory_cell_development_abnormal
synonym: "excretory_canal_cell_development_abnormal" RELATED []
relationship: part_of WBPhenotype0000621 ! excretory_system_development_abnormal

[Term]
id: WBPhenotype0000858
name: excretory_duct_cell_development_abnormal
relationship: part_of WBPhenotype0000621 ! excretory_system_development_abnormal

[Term]
id: WBPhenotype0000859
name: excretory_socket_cell_development_abnormal
synonym: "excretory_pore_cell_development_abnormal" RELATED []
relationship: part_of WBPhenotype0000621 ! excretory_system_development_abnormal

[Term]
id: WBPhenotype0000860
name: nonstriated_muscle_development_abnormal
relationship: part_of WBPhenotype0000622 ! muscle_system_development_abnormal

[Term]
id: WBPhenotype0000861
name: body_wall_muscle_development_abnormal
synonym: "somatic_muscle_development_abnormal" RELATED []
synonym: "striated_muscle_development_abnormal" RELATED []
is_a: WBPhenotype0000921 ! striated_muscle_development_abnormal

[Term]
id: WBPhenotype0000862
name: bloated
is_a: WBPhenotype0000545 ! eggs_retained

[Term]
id: WBPhenotype0000863
name: male_fertility_reduced
is_a: WBPhenotype0000784 ! male_fertility_abnormal

[Term]
id: WBPhenotype0000864
name: early_elongation_arrest
is_a: WBPhenotype0000867 ! embryonic_arrest

[Term]
id: WBPhenotype0000865
name: amphid_sheath_cell_physiology_abnormal
is_a: WBPhenotype0000849 ! amphid_physiology_abnormal

[Term]
id: WBPhenotype0000866
name: germ_cell_arrest
is_a: WBPhenotype0000823 ! germ_cell_proliferation_abnormal

[Term]
id: WBPhenotype0000867
name: embryonic_arrest
is_a: WBPhenotype0000749 ! embryonic_development_abnormal

[Term]
id: WBPhenotype0000868
name: paralyzed_body
def: "Body is paralyzed, but the head can move." [WB:cab]
is_a: WBPhenotype0000644 ! paralyzed

[Term]
id: WBPhenotype0000869
name: mitochondria_morphology_abnormal_muscle
relationship: part_of WBPhenotype0000904 ! muscle_cell_morphology_abnormal

[Term]
id: WBPhenotype0000870
name: mitochondria_morphology_abnormal_epithelial
is_a: WBPhenotype0000899 ! epithelial_cell_morphology_abnormal

[Term]
id: WBPhenotype0000871
name: connected_mitochondria_epithelial
is_a: WBPhenotype0000870 ! mitochondria_morphology_abnormal_epithelial

[Term]
id: WBPhenotype0000872
name: connected_mitochodria_muscle
is_a: WBPhenotype0000869 ! mitochondria_morphology_abnormal_muscle

[Term]
id: WBPhenotype0000873
name: checkpoint_G1_abnormal
is_a: WBPhenotype0000741 ! DNA_damage_checkpoint_abnormal

[Term]
id: WBPhenotype0000874
name: checkpoint_G2_abnormal
is_a: WBPhenotype0000741 ! DNA_damage_checkpoint_abnormal

[Term]
id: WBPhenotype0000875
name: S_phase_checkpoint_abnormal
is_a: WBPhenotype0000741 ! DNA_damage_checkpoint_abnormal

[Term]
id: WBPhenotype0000876
name: osmotic_stress_response_abnormal
is_a: WBPhenotype0000067 ! organism_stress_response_abnormal

[Term]
id: WBPhenotype0000877
name: amphid_sheath_cell_development_abnormal
is_a: WBPhenotype0000942 ! accessory_cell_development_abnormal

[Term]
id: WBPhenotype0000878
name: chemosensory_neuron_development_abnormal
is_a: WBPhenotype0000816 ! neuron_development_abnormal

[Term]
id: WBPhenotype0000879
name: telomere_length_regulation_abnormal
is_a: WBPhenotype0000585 ! cell_homeostasis_metabolism_abnormal

[Term]
id: WBPhenotype0000880
name: axon_development_abnormal
synonym: "axonogenesis_abnormal" RELATED []
is_a: WBPhenotype0000944 ! neurite_development_abnormal

[Term]
id: WBPhenotype0000881
name: cilia_mislocalized
is_a: WBPhenotype0000299 ! chemosensory_cell_morphology_abnormal

[Term]
id: WBPhenotype0000882
name: dendrite_development_abnormal
is_a: WBPhenotype0000944 ! neurite_development_abnormal

[Term]
id: WBPhenotype0000883
name: nerve_ring_development_abnormal
is_a: WBPhenotype0000945 ! neuropil_development_abnormal

[Term]
id: WBPhenotype0000884
name: morphology_AWB_abnormal
is_a: WBPhenotype0000256 ! amphid_morphology_abnormal

[Term]
id: WBPhenotype0000885
name: engulfment_abnormal
synonym: "phagocytosis_abnormal" RELATED []
is_a: WBPhenotype0000730 ! apoptosis_abnormal

[Term]
id: WBPhenotype0000886
name: Abnormal
subset: phenotype_slim_wb

[Term]
id: WBPhenotype0000887
name: hermaphrodite_behavior_abnormal
is_a: WBPhenotype0000821 ! sexually_dimorphic_behavior_abnormal

[Term]
id: WBPhenotype0000888
name: male_behavior_abnormal
is_a: WBPhenotype0000821 ! sexually_dimorphic_behavior_abnormal

[Term]
id: WBPhenotype0000889
name: sexually_dimorphic_physiology_abnormal
subset: phenotype_slim_wb
is_a: WBPhenotype0000576 ! organism_physiology_abnormal

[Term]
id: WBPhenotype0000890
name: larval_pigmentation_abnormal
is_a: WBPhenotype0001009 ! developmental_pigmentation_abnormal

[Term]
id: WBPhenotype0000891
name: clear_adult
synonym: "Clr" BROAD three_letter_name []
is_a: WBPhenotype0000346 ! adult_pigmentation_abnormal

[Term]
id: WBPhenotype0000892
name: hermaphrodite_germ_cell_proliferation_abnormal
is_a: WBPhenotype0000823 ! germ_cell_proliferation_abnormal

[Term]
id: WBPhenotype0000893
name: male_germ_cell_proliferation_abnormal
is_a: WBPhenotype0000823 ! germ_cell_proliferation_abnormal

[Term]
id: WBPhenotype0000894
name: germ_cell_differentiation_abnormal
relationship: part_of WBPhenotype0000774 ! gametogenesis_abnormal

[Term]
id: WBPhenotype0000895
name: spermatocyte_germ_cell_differentiation_abnormal
is_a: WBPhenotype0000894 ! germ_cell_differentiation_abnormal

[Term]
id: WBPhenotype0000896
name: oocyte_germ_cell_differentiation_abnormal
is_a: WBPhenotype0000894 ! germ_cell_differentiation_abnormal

[Term]
id: WBPhenotype0000897
name: connective_tissue_abnormal
is_a: WBPhenotype0000200 ! pericellular_component_development_abnormal

[Term]
id: WBPhenotype0000898
name: blast_cell_morphology_abnormal
is_a: WBPhenotype0000533 ! cell_morphology_abnormal

[Term]
id: WBPhenotype0000899
name: epithelial_cell_morphology_abnormal
is_a: WBPhenotype0000533 ! cell_morphology_abnormal

[Term]
id: WBPhenotype0000900
name: germ_cell_morphology_abnormal
is_a: WBPhenotype0000533 ! cell_morphology_abnormal

[Term]
id: WBPhenotype0000901
name: gland_cell_morphology_abnormal
is_a: WBPhenotype0000533 ! cell_morphology_abnormal

[Term]
id: WBPhenotype0000902
name: intestinal_cell_morphology_abnormal
is_a: WBPhenotype0000533 ! cell_morphology_abnormal

[Term]
id: WBPhenotype0000903
name: marginal_cell_morphology_abnormal
is_a: WBPhenotype0000533 ! cell_morphology_abnormal

[Term]
id: WBPhenotype0000904
name: muscle_cell_morphology_abnormal
is_a: WBPhenotype0000533 ! cell_morphology_abnormal

[Term]
id: WBPhenotype0000905
name: neuron_morphology_abnormal
is_a: WBPhenotype0000533 ! cell_morphology_abnormal

[Term]
id: WBPhenotype0000906
name: uterine_vulval_cell_morphology_abnormal
is_a: WBPhenotype0000533 ! cell_morphology_abnormal

[Term]
id: WBPhenotype0000907
name: anus_morphology_abnormal
relationship: part_of WBPhenotype0000598 ! alimentary_system_morphology_abnormal

[Term]
id: WBPhenotype0000908
name: cloacal_morphology_abnormal
relationship: part_of WBPhenotype0000598 ! alimentary_system_morphology_abnormal

[Term]
id: WBPhenotype0000909
name: pharyngeal_intestinal_valve_morphology_abnormal
is_a: WBPhenotype0000598 ! alimentary_system_morphology_abnormal

[Term]
id: WBPhenotype0000910
name: rectal_morphology_abnormal
relationship: part_of WBPhenotype0000598 ! alimentary_system_morphology_abnormal

[Term]
id: WBPhenotype0000911
name: coelomocyte_morphology_abnormal
relationship: part_of WBPhenotype0000599 ! coelomic_system_morphology_abnormal

[Term]
id: WBPhenotype0000912
name: pericellular_component_morphology_abnormal
is_a: WBPhenotype0000520 ! morphology_abnormal

[Term]
id: WBPhenotype0000913
name: basal_lamina_morphology_abnormal
relationship: part_of WBPhenotype0000600 ! epithelial_system_morphology_abnormal

[Term]
id: WBPhenotype0000914
name: excretory_gland_cell_morphology_abnormal
relationship: part_of WBPhenotype0000601 ! excretory_secretory_system_morphology_abnormal

[Term]
id: WBPhenotype0000915
name: pale_adult
is_a: WBPhenotype0000346 ! adult_pigmentation_abnormal
is_a: WBPhenotype0001261 ! pale

[Term]
id: WBPhenotype0000916
name: excretory_cell_morphology_abnormal
synonym: "excretory_canal_cell_morphology_abnormal" RELATED []
relationship: part_of WBPhenotype0000602 ! excretory_system_morphology_abnormal

[Term]
id: WBPhenotype0000917
name: excretory_duct_cell_morphology_abnormal
relationship: part_of WBPhenotype0000602 ! excretory_system_morphology_abnormal

[Term]
id: WBPhenotype0000918
name: excretory_socket_cell_morphology_abnormal
relationship: part_of WBPhenotype0000602 ! excretory_system_morphology_abnormal

[Term]
id: WBPhenotype0000919
name: spindle_body_wall_muscle_cell_development_abnormal
synonym: "filament_lattice_body_wall_muscle_cell_development_abnormal" RELATED []
is_a: WBPhenotype0000087 ! body_wall_cell_development_abnormal

[Term]
id: WBPhenotype0000920
name: body_body_wall_muscle_cell_development_abnormal
synonym: "muscle_belly_development_abnormal" RELATED []
is_a: WBPhenotype0000087 ! body_wall_cell_development_abnormal

[Term]
id: WBPhenotype0000921
name: striated_muscle_development_abnormal
relationship: part_of WBPhenotype0000622 ! muscle_system_development_abnormal

[Term]
id: WBPhenotype0000922
name: male_longitudinal_muscle_development_abnormal
is_a: WBPhenotype0000921 ! striated_muscle_development_abnormal

[Term]
id: WBPhenotype0000923
name: nonstriated_muscle_morphology_abnormal
relationship: part_of WBPhenotype0000603 ! muscle_system_morphology_abnormal

[Term]
id: WBPhenotype0000924
name: striated_muscle_morphology_abnormal
relationship: part_of WBPhenotype0000603 ! muscle_system_morphology_abnormal

[Term]
id: WBPhenotype0000925
name: sex_muscle_morphology_abnormal
is_a: WBPhenotype0000923 ! nonstriated_muscle_morphology_abnormal

[Term]
id: WBPhenotype0000926
name: body_wall_muscle_morphology_abnormal
is_a: WBPhenotype0000924 ! striated_muscle_morphology_abnormal

[Term]
id: WBPhenotype0000927
name: male_longitudinal_muscle_morphology_abnormal
is_a: WBPhenotype0000924 ! striated_muscle_morphology_abnormal

[Term]
id: WBPhenotype0000928
name: male_physiology_abnormal
is_a: WBPhenotype0000889 ! sexually_dimorphic_physiology_abnormal

[Term]
id: WBPhenotype0000929
name: hermaphrodite_physiology_abnormal
is_a: WBPhenotype0000889 ! sexually_dimorphic_physiology_abnormal

[Term]
id: WBPhenotype0000930
name: sexually_dimorphic_development_abnormal
subset: phenotype_slim_wb
is_a: WBPhenotype0000531 ! organism_development_abnormal

[Term]
id: WBPhenotype0000931
name: bis_phenol_A_response_abnormal
is_a: WBPhenotype0000523 ! chemical_response_abnormal

[Term]
id: WBPhenotype0000932
name: bis_phenol_A_hypersensitive
is_a: WBPhenotype0000931 ! bis_phenol_A_response_abnormal

[Term]
id: WBPhenotype0000933
name: MS_lineage_abnormal
is_a: WBPhenotype0000824 ! embryonic_cell_lineage_abnormal

[Term]
id: WBPhenotype0000934
name: developmental_morphology_abnormal
subset: phenotype_slim_wb
is_a: WBPhenotype0000535 ! organism_morphology_abnormal

[Term]
id: WBPhenotype0000935
name: D_lineage_abnormal
is_a: WBPhenotype0000824 ! embryonic_cell_lineage_abnormal

[Term]
id: WBPhenotype0000936
name: P4_lineage_abnormal
is_a: WBPhenotype0000824 ! embryonic_cell_lineage_abnormal

[Term]
id: WBPhenotype0000937
name: W_lineage_abnormal
is_a: WBPhenotype0000825 ! postembryonic_cell_lineage_abnormal

[Term]
id: WBPhenotype0000938
name: male_V_lineage_abnormal
is_a: WBPhenotype0000809 ! male_specific_lineage_abnormal

[Term]
id: WBPhenotype0000939
name: male_T_Lineage_abnormal
is_a: WBPhenotype0000809 ! male_specific_lineage_abnormal

[Term]
id: WBPhenotype0000940
name: male_P_lineage_abnormal
is_a: WBPhenotype0000809 ! male_specific_lineage_abnormal

[Term]
id: WBPhenotype0000941
name: male_M_lineage_abnormal
is_a: WBPhenotype0000809 ! male_specific_lineage_abnormal

[Term]
id: WBPhenotype0000942
name: accessory_cell_development_abnormal
relationship: part_of WBPhenotype0000623 ! nervous_system_development_abnormal

[Term]
id: WBPhenotype0000943
name: ganglion_development_abnormal
relationship: part_of WBPhenotype0000623 ! nervous_system_development_abnormal

[Term]
id: WBPhenotype0000944
name: neurite_development_abnormal
is_a: WBPhenotype0000816 ! neuron_development_abnormal

[Term]
id: WBPhenotype0000945
name: neuropil_development_abnormal
relationship: part_of WBPhenotype0000623 ! nervous_system_development_abnormal

[Term]
id: WBPhenotype0000946
name: pharyngeal_nervous_system_development_abnormal
relationship: part_of WBPhenotype0000623 ! nervous_system_development_abnormal

[Term]
id: WBPhenotype0000947
name: connective_tissue_morphology_abnormal
is_a: WBPhenotype0000912 ! pericellular_component_morphology_abnormal

[Term]
id: WBPhenotype0000948
name: cuticle_morphology_abnormal
is_a: WBPhenotype0000912 ! pericellular_component_morphology_abnormal

[Term]
id: WBPhenotype0000949
name: pseudocoelom_morphology_abnormal
is_a: WBPhenotype0000912 ! pericellular_component_morphology_abnormal

[Term]
id: WBPhenotype0000950
name: neuronal_sheath_cell_development_abnormal
is_a: WBPhenotype0000942 ! accessory_cell_development_abnormal

[Term]
id: WBPhenotype0000951
name: socket_cell_development_abnormal
is_a: WBPhenotype0000942 ! accessory_cell_development_abnormal

[Term]
id: WBPhenotype0000952
name: anterior_ganglion_development_abnormal
is_a: WBPhenotype0000943 ! ganglion_development_abnormal

[Term]
id: WBPhenotype0000953
name: dorsal_ganglion_development_abnormal
is_a: WBPhenotype0000943 ! ganglion_development_abnormal

[Term]
id: WBPhenotype0000954
name: dorsorectal_ganglia_development_abnormal
is_a: WBPhenotype0000943 ! ganglion_development_abnormal

[Term]
id: WBPhenotype0000955
name: lateral_ganglia_development_abnormal
is_a: WBPhenotype0000943 ! ganglion_development_abnormal

[Term]
id: WBPhenotype0000956
name: lumbar_ganglia_development_abnormal
is_a: WBPhenotype0000943 ! ganglion_development_abnormal

[Term]
id: WBPhenotype0000957
name: posterior_lateral_ganglion_development_abnormal
is_a: WBPhenotype0000943 ! ganglion_development_abnormal

[Term]
id: WBPhenotype0000958
name: preanal_ganglion_development_abnormal
is_a: WBPhenotype0000943 ! ganglion_development_abnormal

[Term]
id: WBPhenotype0000959
name: retrovesicular_ganglion_development_abnormal
is_a: WBPhenotype0000943 ! ganglion_development_abnormal

[Term]
id: WBPhenotype0000960
name: ventral_ganglion_development_abnormal
is_a: WBPhenotype0000943 ! ganglion_development_abnormal

[Term]
id: WBPhenotype0000961
name: pattern_of_transgene_expression_abnormal
is_a: WBPhenotype0000306 ! transgene_expression_abnormal

[Term]
id: WBPhenotype0000962
name: level_of_transgene_expression_abnormal
is_a: WBPhenotype0000306 ! transgene_expression_abnormal

[Term]
id: WBPhenotype0000963
name: male_pigmentation_abnormal
is_a: WBPhenotype0000527 ! organism_pigmentation_abnormal

[Term]
id: WBPhenotype0000964
name: dmpp_resistant
is_a: WBPhenotype0000681 ! dmpp_response_abnormal

[Term]
id: WBPhenotype0000965
name: somatic_cell_death_abnormal
is_a: WBPhenotype0000729 ! cell_death_abnormal

[Term]
id: WBPhenotype0000966
name: germline_mortal
is_a: WBPhenotype0000987 ! germ_cell_physiology_abnormal

[Term]
id: WBPhenotype0000967
name: male_tail_spike
is_a: WBPhenotype0000070 ! male_tail_abnormal

[Term]
id: WBPhenotype0000968
name: tail_spike
is_a: WBPhenotype0000073 ! tail_morphology_abnormal

[Term]
id: WBPhenotype0000969
name: accessory_cell_morphology_abnormal
is_a: WBPhenotype0000604 ! nervous_system_morphology_abnormal

[Term]
id: WBPhenotype0000970
name: embryonic_pigmentation_abnormal
is_a: WBPhenotype0001009 ! developmental_pigmentation_abnormal

[Term]
id: WBPhenotype0000971
name: anterior_pigmentation_abnormal
is_a: WBPhenotype0000786 ! body_axis_pigmentation_abnormal

[Term]
id: WBPhenotype0000972
name: neuronal_sheath_cell_morphology_abnormal
is_a: WBPhenotype0000969 ! accessory_cell_morphology_abnormal

[Term]
id: WBPhenotype0000973
name: homologous_recombination_increased
is_a: WBPhenotype0000742 ! DNA_recombination_abnormal

[Term]
id: WBPhenotype0000974
name: accessory_cell_physiology_abnormal
is_a: WBPhenotype0000612 ! nervous_system_physiology_abnormal

[Term]
id: WBPhenotype0000975
name: neuronal_sheath_cell_physiology_abnormal
is_a: WBPhenotype0000974 ! accessory_cell_physiology_abnormal

[Term]
id: WBPhenotype0000976
name: ventral_cord_patterning_abnormal
is_a: WBPhenotype0000515 ! ventral_nerve_cord_development_abnormal

[Term]
id: WBPhenotype0000977
name: somatic_gonad_morphology_abnormal
is_a: WBPhenotype0000605 ! reproductive_system_morphology_abnormal

[Term]
id: WBPhenotype0000978
name: spermatheca_physiology_abnormal
is_a: WBPhenotype0001197 ! somatic_gonad_physiology_abnormal

[Term]
id: WBPhenotype0000979
name: spermatheca_dilation_defect
is_a: WBPhenotype0000978 ! spermatheca_physiology_abnormal

[Term]
id: WBPhenotype0000980
name: pharyngeal_contraction_abnormal
is_a: WBPhenotype0000634 ! pharyngeal_pumping_abnormal

[Term]
id: WBPhenotype0000981
name: spermatocyte_meiosis_abnormal
is_a: WBPhenotype0000812 ! germ_cell_development_abnormal

[Term]
id: WBPhenotype0000982
name: spermatid_maturation_abnormal
is_a: WBPhenotype0000812 ! germ_cell_development_abnormal

[Term]
id: WBPhenotype0000983
name: fertilization_defect
is_a: WBPhenotype0000613 ! reproductive_system_physiology_abnormal

[Term]
id: WBPhenotype0000984
name: posterior_pigmentation_abnormal
is_a: WBPhenotype0000786 ! body_axis_pigmentation_abnormal

[Term]
id: WBPhenotype0000985
name: blast_cell_physiology_abnormal
is_a: WBPhenotype0000536 ! cell_physiology_abnormal

[Term]
id: WBPhenotype0000986
name: epithelial_cell_physiology_abnormal
is_a: WBPhenotype0000536 ! cell_physiology_abnormal

[Term]
id: WBPhenotype0000987
name: germ_cell_physiology_abnormal
is_a: WBPhenotype0000536 ! cell_physiology_abnormal

[Term]
id: WBPhenotype0000988
name: gland_cell_physiology_abnormal
is_a: WBPhenotype0000536 ! cell_physiology_abnormal

[Term]
id: WBPhenotype0000989
name: marginal_cell_physiology_abnormal
is_a: WBPhenotype0000536 ! cell_physiology_abnormal

[Term]
id: WBPhenotype0000990
name: muscle_cell_physiology_abnormal
is_a: WBPhenotype0000536 ! cell_physiology_abnormal

[Term]
id: WBPhenotype0000991
name: neuron_physiology_abnormal
is_a: WBPhenotype0000536 ! cell_physiology_abnormal

[Term]
id: WBPhenotype0000992
name: high_NaCl_osmotic_avoidance_defect
is_a: WBPhenotype0000249 ! osmotic_avoidance_defect

[Term]
id: WBPhenotype0000993
name: anal_depressor_contraction_defect
def: "failure in the ability of the anal depressor muscle to contract fully." [WB:WBPaper00001256]
synonym: "Exp" BROAD three_letter_name []
is_a: WBPhenotype0001092 ! larval_defecation_defect

[Term]
id: WBPhenotype0000994
name: intestinal_contractions_abnormal
is_a: WBPhenotype0000650 ! defecation_abnormal

[Term]
id: WBPhenotype0000996
name: expulsion_defective
is_a: WBPhenotype0000205 ! expulsion_abnormal

[Term]
id: WBPhenotype0000997
name: cryophilic
is_a: WBPhenotype0000478 ! isothermal_tracking_behavior_abnormal

[Term]
id: WBPhenotype0000998
name: thermophilic
is_a: WBPhenotype0000478 ! isothermal_tracking_behavior_abnormal

[Term]
id: WBPhenotype0000999
name: athermotactic
is_a: WBPhenotype0000478 ! isothermal_tracking_behavior_abnormal

[Term]
id: WBPhenotype0001000
name: developmental_behavior_abnormal
def: "Behavior characteristic during certain developmental stage(s) is altered." [WB:cab]
subset: phenotype_slim_wb
is_a: WBPhenotype0000525 ! organism_behavior_abnormal

[Term]
id: WBPhenotype0001001
name: dauer_behavior_abnormal
is_a: WBPhenotype0000819 ! postembryonic_behavior_abnormal

[Term]
id: WBPhenotype0001002
name: head_muscle_behavior_abnormal
is_a: WBPhenotype0000595 ! head_behavior_abnormal

[Term]
id: WBPhenotype0001003
name: L4_lethal
synonym: "Let" BROAD three_letter_name []
synonym: "Lvl" BROAD three_letter_name []
is_a: WBPhenotype0000058 ! late_larval_lethal

[Term]
id: WBPhenotype0001004
name: pharyngeal_relaxation_abnormal
is_a: WBPhenotype0000634 ! pharyngeal_pumping_abnormal

[Term]
id: WBPhenotype0001005
name: backward_locomotion_abnormal
is_a: WBPhenotype0000643 ! locomotion_abnormal

[Term]
id: WBPhenotype0001006
name: pharyngeal_pumping_rate_abnormal
is_a: WBPhenotype0000634 ! pharyngeal_pumping_abnormal

[Term]
id: WBPhenotype0001007
name: other_abnormality_early_emb
def: "Unclassified abnormality in the inviable one- to four-cell embryo." [WB:cab]
synonym: "Emb" BROAD three_letter_name []
synonym: "Oth" RELATED []
is_a: WBPhenotype0001100 ! early_embryonic_lethal

[Term]
id: WBPhenotype0001008
name: male_nervous_system_development_abnormal
relationship: part_of WBPhenotype0000623 ! nervous_system_development_abnormal

[Term]
id: WBPhenotype0001009
name: developmental_pigmentation_abnormal
is_a: WBPhenotype0000527 ! organism_pigmentation_abnormal

[Term]
id: WBPhenotype0001010
name: clear
def: "At least 10% of worms appear unusually transparent when compared to wild-type." [WB:cab, WB:WBPaper00004402, WB:WBPaper00005654]
synonym: "Clr" BROAD three_letter_name []
is_a: WBPhenotype0000527 ! organism_pigmentation_abnormal

[Term]
id: WBPhenotype0001011
name: complex_phenotype_early_emb
def: "Complex combination of defects that does not match other class definitions." [WB:cab, WB:cgc7141]
synonym: "Emb" BROAD three_letter_name []
is_a: WBPhenotype0001007 ! other_abnormality_early_emb

[Term]
id: WBPhenotype0001012
name: pathogen_response_abnormal
is_a: WBPhenotype0000738 ! organism_environmental_stimulus_response_abnormal

[Term]
id: WBPhenotype0001013
name: pathogen_susceptibility_increased
def: "Susceptibility to infection by pathogens is increased." [WB:cab, WB:WBPaper00005370, WB:WBPaper00024299]
synonym: "enhanced_susceptibility_to_pathogens" RELATED []
synonym: "Esp" BROAD three_letter_name []
is_a: WBPhenotype0001012 ! pathogen_response_abnormal

[Term]
id: WBPhenotype0001014
name: pathogen_resistance_increased
is_a: WBPhenotype0001012 ! pathogen_response_abnormal

[Term]
id: WBPhenotype0001015
name: developmental_growth_abnormal
is_a: WBPhenotype0000030 ! growth_abnormal

[Term]
id: WBPhenotype0001016
name: larval_growth_abnormal
is_a: WBPhenotype0001015 ! developmental_growth_abnormal

[Term]
id: WBPhenotype0001017
name: adult_growth_abnormal
is_a: WBPhenotype0001015 ! developmental_growth_abnormal

[Term]
id: WBPhenotype0001018
name: cytokinesis_abnormal
synonym: "Cyk" BROAD three_letter_name []
is_a: WBPhenotype0000746 ! cell_division_abnormal

[Term]
id: WBPhenotype0001019
name: mid_larval_arrest
def: "Larval arrest during the L2 to L3 stages of larval development." [WB:cab]
is_a: WBPhenotype0000059 ! larval_arrest

[Term]
id: WBPhenotype0001020
name: late_embryonic_lethal_emb
synonym: "Emb" BROAD three_letter_name []
synonym: "Led" RELATED []
is_a: WBPhenotype0000050 ! embryonic_lethal

[Term]
id: WBPhenotype0001021
name: male_sexual_development_abnormal
is_a: WBPhenotype0000822 ! sex_determination_abnormal

[Term]
id: WBPhenotype0001022
name: hermaphrodite_sexual_development_abnormal
is_a: WBPhenotype0000822 ! sex_determination_abnormal

[Term]
id: WBPhenotype0001023
name: sexually_dimorphic_morphology_abnormal
subset: phenotype_slim_wb
is_a: WBPhenotype0000535 ! organism_morphology_abnormal

[Term]
id: WBPhenotype0001024
name: male_morphology_abnormal
synonym: "Mab" BROAD three_letter_name []
is_a: WBPhenotype0001023 ! sexually_dimorphic_morphology_abnormal

[Term]
id: WBPhenotype0001025
name: hermaphrodite_morphology_abnormal
is_a: WBPhenotype0001023 ! sexually_dimorphic_morphology_abnormal

[Term]
id: WBPhenotype0001026
name: nuclear_morphology_alteration_early_emb
synonym: "Emb" BROAD three_letter_name []
synonym: "Nmo" BROAD three_letter_name []
is_a: WBPhenotype0001035 ! nuclear_appearance_number_abnormal_early_emb

[Term]
id: WBPhenotype0001027
name: nuclear_position_abnormal_early_emb
synonym: "Emb" BROAD three_letter_name []
synonym: "Npo" BROAD three_letter_name []
is_a: WBPhenotype0001138 ! nucleus_abnormal_early_emb

[Term]
id: WBPhenotype0001028
name: nuclear_appearance_abnormal
subset: phenotype_slim_wb
is_a: WBPhenotype0000533 ! cell_morphology_abnormal

[Term]
id: WBPhenotype0001029
name: patchy_coloration
synonym: "Pch" BROAD three_letter_name []
is_a: WBPhenotype0000527 ! organism_pigmentation_abnormal

[Term]
id: WBPhenotype0001030
name: pronuclear_envelope_abnormal_early_emb
synonym: "Emb" BROAD three_letter_name []
synonym: "Pna" BROAD three_letter_name []
is_a: WBPhenotype0001151 ! pronucleus_centrosomes_abnormal_early_emb

[Term]
id: WBPhenotype0001031
name: pronuclear_migration_reduced_early_emb
def: "Lack of male pronuclear migration, female pronuclear migration variable, sometimes multiple female pronuclei, no or small spindle." [WB:cab, WB:cgc7141]
synonym: "Emb" BROAD three_letter_name []
is_a: WBPhenotype0001152 ! pronuclear_migration_abnormal_early_emb

[Term]
id: WBPhenotype0001032
name: larval_behavior_abnormal
is_a: WBPhenotype0000819 ! postembryonic_behavior_abnormal

[Term]
id: WBPhenotype0001033
name: proximal_germ_cell_proliferation_abnormal
synonym: "Pro" BROAD three_letter_name []
is_a: WBPhenotype0001215 ! germ_cell_mitosis_abnormal

[Term]
id: WBPhenotype0001034
name: pronuclear_nuclear_appearance_abnormal_early_emb
def: "Pronuclei and nuclei are small or missing altogether, often accompanied by spindle defects." [WB:cab, WB:cgc7141]
synonym: "Emb" BROAD three_letter_name []
is_a: WBPhenotype0000764 ! embryonic_cell_organization_biogenesis_abnormal
is_a: WBPhenotype0001100 ! early_embryonic_lethal

[Term]
id: WBPhenotype0001035
name: nuclear_appearance_number_abnormal_early_emb
def: "Pronuclei are normal but nuclei are completely missing or significantly smaller than normal; often accompanied by spindle and cytokinesis defects." [WB:cab, WB:cgc7141]
synonym: "Emb" BROAD three_letter_name []
synonym: "nucleus_abnormal_emb" RELATED []
is_a: WBPhenotype0000770 ! embryonic_cell_morphology_abnormal
is_a: WBPhenotype0001138 ! nucleus_abnormal_early_emb

[Term]
id: WBPhenotype0001036
name: sterile_F1
is_a: WBPhenotype0001037 ! sterile_progeny

[Term]
id: WBPhenotype0001037
name: sterile_progeny
synonym: "Stp" BROAD three_letter_name []
is_a: WBPhenotype0000069 ! progeny_abnormal
is_a: WBPhenotype0000688 ! sterile

[Term]
id: WBPhenotype0001038
name: tumorous_germline
synonym: "Tum" BROAD three_letter_name []
is_a: WBPhenotype0000812 ! germ_cell_development_abnormal

[Term]
id: WBPhenotype0001039
name: embryonic_growth_abnormal
is_a: WBPhenotype0001015 ! developmental_growth_abnormal

[Term]
id: WBPhenotype0001040
name: chemosensory_response_abnormal
def: "Typical response to chemicals is altered." [WB:cab, WB:cgc3824]
is_a: WBPhenotype0001049 ! chemosensory_behavior_abnormal

[Term]
id: WBPhenotype0001041
name: meiosis_abnormal_early_emb
synonym: "Emb" BROAD three_letter_name []
synonym: "Mei" BROAD three_letter_name []
is_a: WBPhenotype0001100 ! early_embryonic_lethal

[Term]
id: WBPhenotype0001042
name: neuron_function_compromised
is_a: WBPhenotype0000991 ! neuron_physiology_abnormal

[Term]
id: WBPhenotype0001043
name: interphase_entry_abnormal_early_emb
def: "Embryos spend longer than normal when entering first interphase." [WB:cab, WB:cgc7141]
synonym: "Emb" BROAD three_letter_name []
is_a: WBPhenotype0000740 ! cell_cycle_abnormal
is_a: WBPhenotype0000775 ! meiosis_abnormal
is_a: WBPhenotype0001041 ! meiosis_abnormal_early_emb

[Term]
id: WBPhenotype0001044
name: cortical_dynamics_abnormal_early_emb
def: "Little/no cortical ruffling or pseudocleavage furrow, or excessive cortical activity at the two-cell stage." [WB:cab, WB:cgc7141]
synonym: "Cpa" BROAD three_letter_name []
synonym: "Emb" BROAD three_letter_name []
is_a: WBPhenotype0000764 ! embryonic_cell_organization_biogenesis_abnormal
is_a: WBPhenotype0001100 ! early_embryonic_lethal

[Term]
id: WBPhenotype0001045
name: sporadic_pumping
is_a: WBPhenotype0000019 ! pharyngeal_pumping_decreased

[Term]
id: WBPhenotype0001046
name: pharyngeal_muscle_morphology_abnormal
is_a: WBPhenotype0000923 ! nonstriated_muscle_morphology_abnormal

[Term]
id: WBPhenotype0001047
name: aqueous_chemotaxis_defective
def: "Failure to move towards typically attractive water-soluble chemicals." [WB:cab, WB:cgc3824]
is_a: WBPhenotype0000015 ! chemotaxis_defective

[Term]
id: WBPhenotype0001048
name: volatile_chemosensory_response_abnormal
is_a: WBPhenotype0001040 ! chemosensory_response_abnormal

[Term]
id: WBPhenotype0001049
name: chemosensory_behavior_abnormal
subset: phenotype_slim_wb
is_a: WBPhenotype0000525 ! organism_behavior_abnormal

[Term]
id: WBPhenotype0001050
name: chemosensation_abnormal
is_a: WBPhenotype0001049 ! chemosensory_behavior_abnormal

[Term]
id: WBPhenotype0001051
name: cation_chemotaxis_defective
def: "Failure to move towards typically attractive cations." [WB:cab, WB:cgc387]
is_a: WBPhenotype0001047 ! aqueous_chemotaxis_defective

[Term]
id: WBPhenotype0001052
name: anion_chemotaxis_defective
def: "Failure to move towards typically attractive anions." [WB:cab, WB:cgc387]
is_a: WBPhenotype0001047 ! aqueous_chemotaxis_defective

[Term]
id: WBPhenotype0001053
name: cyclic_nucleotide_chemotaxis_defective
def: "Characteristic movement towards cyclic nucleotides is altered." [WB:cab, WB:cgc387]
is_a: WBPhenotype0000015 ! chemotaxis_defective

[Term]
id: WBPhenotype0001054
name: cgmp_chemotaxis_defective
def: "Characteristic movement towards cGMP is altered." [WB:cab, WB:cgc387]
is_a: WBPhenotype0001053 ! cyclic_nucleotide_chemotaxis_defective

[Term]
id: WBPhenotype0001055
name: bromide_chemotaxis_defective
def: "Failure to move towards bromide." [WB:cab, WB:cgc387]
is_a: WBPhenotype0001052 ! anion_chemotaxis_defective

[Term]
id: WBPhenotype0001056
name: iodide_chemotaxis_defective
def: "Failure to move towards iodide." [WB:cab, WB:cgc387]
is_a: WBPhenotype0001052 ! anion_chemotaxis_defective

[Term]
id: WBPhenotype0001057
name: lithium_chemotaxis_defective
def: "Failure to move towards lithium." [WB:cab, WB:cgc387]
is_a: WBPhenotype0001051 ! cation_chemotaxis_defective

[Term]
id: WBPhenotype0001058
name: potassium_chemotaxis_defective
def: "Failure of the animals to move towards potassium." [WB:cab, WB:cgc387]
is_a: WBPhenotype0001051 ! cation_chemotaxis_defective

[Term]
id: WBPhenotype0001059
name: magnesium_chemotaxis_defective
def: "Failure to move towards magnesium." [WB:cab, WB:cgc387]
is_a: WBPhenotype0001051 ! cation_chemotaxis_defective

[Term]
id: WBPhenotype0001060
name: awc_volatile_chemotaxis_defective
is_a: WBPhenotype0000265 ! volatile_odorant_chemotaxis_defective

[Term]
id: WBPhenotype0001061
name: awa_volatile_chemotaxis_defective
is_a: WBPhenotype0000265 ! volatile_odorant_chemotaxis_defective

[Term]
id: WBPhenotype0001062
name: late_paralysis_arrested_elongation_two_fold
def: "Movement and elongation stop nearly simultaneously soon after the twofold stage of elongation.  However, mutant embryos twitch at the one-and-a-half-fold stage of elongation, like wild type, and move as well as wild type at the two- fold stage.  " [WB:cab, WB:cgc1894]
is_a: WBPhenotype0000749 ! embryonic_development_abnormal

[Term]
id: WBPhenotype0001063
name: egg_laying_phases_abnormal
def: "Fluctuation between  inactive, active, and egg-laying states is atypical, based on the analysis of the distribution of the log intervals of egg-laying events." [pmid:10757762, pmid:9697864, WB:cab]
is_a: WBPhenotype0000640 ! egg_laying_abnormal

[Term]
id: WBPhenotype0001064
name: inactive_phase_long
def: "Animals display uncharacteristically long periods during which they do not lay eggs, as in HSN-ablated and serotonin-deficient animals, based on the analysis of the distribution of the log intervals of egg-laying events." [pmid:10757762, pmid:9697864, WB:cab]
is_a: WBPhenotype0000006 ! egg_laying_defective
is_a: WBPhenotype0001066 ! inactive_phase_abnormal

[Term]
id: WBPhenotype0001065
name: fewer_egg_laying_events_during_active
def: "Fewer egg-laying events occur within the active phase of egg laying, based on the analysis of the distribution of the log intervals of egg-laying events." [pmid:9697864, WB:cab]
is_a: WBPhenotype0000006 ! egg_laying_defective
is_a: WBPhenotype0001067 ! active_phase_abnormal

[Term]
id: WBPhenotype0001066
name: inactive_phase_abnormal
def: "The period during which the animal is less likely to lay eggs is not typical compared with wild type, based on the analysis of the distribution of the log intervals of egg-laying events." [pmid:10757762, pmid:9697864, WB:cab]
is_a: WBPhenotype0001063 ! egg_laying_phases_abnormal

[Term]
id: WBPhenotype0001067
name: active_phase_abnormal
def: "The active phase of egg-laying, the period during which animals are more likely to display multiple egg-laying events, is atypical compared with wild-type animals, based on the analysis of the distribution of the log intervals of egg-laying events." [pmid:9697864, WB:cab]
is_a: WBPhenotype0001063 ! egg_laying_phases_abnormal

[Term]
id: WBPhenotype0001068
name: egg_laying_serotonin_insensitive
is_a: WBPhenotype0000024 ! serotonin_resistant
is_a: WBPhenotype0001101 ! egg_laying_response_to_drugs_abnormal

[Term]
id: WBPhenotype0001069
name: increased_egg_laying_events_during_active
def: "More eggs are laid during the active phase compared with wild type, based on the analysis of the distribution of the log intervals of egg-laying events." [pmid:9697864, WB:cab]
is_a: WBPhenotype0001067 ! active_phase_abnormal

[Term]
id: WBPhenotype0001070
name: inactive_phase_short
def: "The period during which a worm usually does not lay eggs is short compared with wild type, based on the analysis of the distribution of the log intervals of egg-laying events." [pmid:9697864, WB:cab]
is_a: WBPhenotype0001066 ! inactive_phase_abnormal

[Term]
id: WBPhenotype0001071
name: active_phase_switch_defective
def: "Activation of the active phase of egg laying is defective, leading to an abnormally long inactive phase, based on the analysis of the distribution of the log intervals of egg-laying events." [pmid:10757762, pmid:9697864, WB:cab]
is_a: WBPhenotype0001064 ! inactive_phase_long

[Term]
id: WBPhenotype0001072
name: response_to_food_abnormal
is_a: WBPhenotype0000738 ! organism_environmental_stimulus_response_abnormal

[Term]
id: WBPhenotype0001073
name: egg_laying_response_to_food_abnormal
def: "Well-fed animals do not lay more eggs compared with starved animals, unlike wild type." [pmid:10757762, WB:cab]
is_a: WBPhenotype0000640 ! egg_laying_abnormal
is_a: WBPhenotype0001072 ! response_to_food_abnormal

[Term]
id: WBPhenotype0001074
name: vulval_muscle_unresponsive_to_serotonin
def: "The vulval muscle does not respond typically to serotonin, based on imaging of calcium transients in response to serotonin." [pmid:14588249, WB:cab]
is_a: WBPhenotype0001068 ! egg_laying_serotonin_insensitive
is_a: WBPhenotype0001076 ! vulval_muscle_homeostasis_metabolism_abnormal

[Term]
id: WBPhenotype0001075
name: vulval_muscle_physiology_abnormal
is_a: WBPhenotype0000613 ! reproductive_system_physiology_abnormal

[Term]
id: WBPhenotype0001076
name: vulval_muscle_homeostasis_metabolism_abnormal
is_a: WBPhenotype0001075 ! vulval_muscle_physiology_abnormal

[Term]
id: WBPhenotype0001077
name: chromosome_segregation_abnormal_karyomeres_early_emb
def: "Karyomeres in AB or P1 often accompanied by weak/thin wobbly spindle." [WB:cab, WB:cgc7141]
synonym: "Emb" BROAD three_letter_name []
is_a: WBPhenotype0001100 ! early_embryonic_lethal

[Term]
id: WBPhenotype0001078
name: cytokinesis_abnormal_early_emb
def: "Cytokinesis is abnormal in the first or second stages of cell division." [WB:cab, WB:cgc7141]
synonym: "Cyk" BROAD three_letter_name []
synonym: "Emb" BROAD three_letter_name []
is_a: WBPhenotype0001018 ! cytokinesis_abnormal
is_a: WBPhenotype0001100 ! early_embryonic_lethal

[Term]
id: WBPhenotype0001079
name: cytoplasmic_dynamics_abnormal_early_emb
def: "Cytoplasmic movements are atypical." [WB:cab, WB:WBPerson1815]
synonym: "Emb" BROAD three_letter_name []
is_a: WBPhenotype0000769 ! cytoplasmic_appearance_abnormal_early_emb

[Term]
id: WBPhenotype0001080
name: excessive_blebbing_early_emb
def: "Excessive shaking and movements are seen in the cell membrane or cytoplasm of one-cell or two-cell embryos." [cgc:5599, WB:cab]
synonym: "Emb" BROAD three_letter_name []
is_a: WBPhenotype0001079 ! cytoplasmic_dynamics_abnormal_early_emb

[Term]
id: WBPhenotype0001081
name: cytoplasmic_morphology_abnormal_early_emb
def: "Morphology of the cytoplasm differs from wild type." [WB:cab, WB:WBPerson1815]
synonym: "Emb" BROAD three_letter_name []
is_a: WBPhenotype0000769 ! cytoplasmic_appearance_abnormal_early_emb

[Term]
id: WBPhenotype0001082
name: large_cytoplasmic_granules_early_emb
def: "Abnormally large granules are observed in the cytoplasm of P0." [WB:cab, WB:cgc5599]
synonym: "Emb" BROAD three_letter_name []
is_a: WBPhenotype0001081 ! cytoplasmic_morphology_abnormal_early_emb

[Term]
id: WBPhenotype0001083
name: multiple_cytoplasmic_cavities_early_emb
def: "Multiple vesicles, vacuoles, or cavities are seen during early embryogenesis." [cgc:5599, WB:cab]
synonym: "Emb" BROAD three_letter_name []
is_a: WBPhenotype0001081 ! cytoplasmic_morphology_abnormal_early_emb

[Term]
id: WBPhenotype0001084
name: sodium_chloride_chemotaxis_defective
alt_id: WBPhenotype0000995
comment: alt_id WBPhenotype0000995
synonym: "NaCl_chemotaxis_defect" EXACT []
is_a: WBPhenotype0000015 ! chemotaxis_defective

[Term]
id: WBPhenotype0001085
name: butanone_chemotaxis_defective
is_a: WBPhenotype0000265 ! volatile_odorant_chemotaxis_defective

[Term]
id: WBPhenotype0001086
name: trimethylthiazole_chemotaxis_defective
is_a: WBPhenotype0000265 ! volatile_odorant_chemotaxis_defective

[Term]
id: WBPhenotype0001087
name: acetone_chemotaxis_defective
is_a: WBPhenotype0000265 ! volatile_odorant_chemotaxis_defective

[Term]
id: WBPhenotype0001088
name: pentanol_chemotaxis_defective
is_a: WBPhenotype0000265 ! volatile_odorant_chemotaxis_defective

[Term]
id: WBPhenotype0001089
name: hexanol_chemotaxis_defective
is_a: WBPhenotype0000265 ! volatile_odorant_chemotaxis_defective

[Term]
id: WBPhenotype0001090
name: thermotolerance_decreased
is_a: WBPhenotype0000146 ! organism_temperature_response_abnormal

[Term]
id: WBPhenotype0001091
name: larval_defecation_abnormal
is_a: WBPhenotype0000650 ! defecation_abnormal

[Term]
id: WBPhenotype0001092
name: larval_defecation_defect
is_a: WBPhenotype0001091 ! larval_defecation_abnormal

[Term]
id: WBPhenotype0001093
name: intestinal_physiology_abnormal
relationship: part_of WBPhenotype0000606 ! alimentary_system_physiology_abnormal

[Term]
id: WBPhenotype0001094
name: NaCl_response_abnormal
def: "Organismal response to NaCl differs from wild type." [WB:cab]
is_a: WBPhenotype0000067 ! organism_stress_response_abnormal

[Term]
id: WBPhenotype0001095
name: hypersensitive_high_NaCl
def: "Generation time and number of progeny are reduced in response to growth on media containing high NaCl." [pmid:16027367, WB:cab]
is_a: WBPhenotype0001094 ! NaCl_response_abnormal

[Term]
id: WBPhenotype0001096
name: protrusion_at_vulval_region
def: "Large protrusion at the normal position of the vulva, as seen in lin-12 null animals." [cgc:646, WB:cab]
synonym: "ventral_protrusion" NARROW []
is_a: WBPhenotype0000695 ! vulva_morphology_abnormal

[Term]
id: WBPhenotype0001097
name: premature_spermatocyte_germ_cell_differentiation
def: "Premature differentiation of germ cells as sperm." [cgc:4207, WB:cab]
is_a: WBPhenotype0000895 ! spermatocyte_germ_cell_differentiation_abnormal

[Term]
id: WBPhenotype0001098
name: no_rectum
is_a: WBPhenotype0000347 ! rectal_development_abnormal

[Term]
id: WBPhenotype0001099
name: twisted_nose
is_a: WBPhenotype0000321 ! nose_morphology_abnormal

[Term]
id: WBPhenotype0001100
name: early_embryonic_lethal
synonym: "Emb" BROAD three_letter_name []
synonym: "Let" BROAD three_letter_name []
is_a: WBPhenotype0000050 ! embryonic_lethal

[Term]
id: WBPhenotype0001101
name: egg_laying_response_to_drugs_abnormal
is_a: WBPhenotype0000640 ! egg_laying_abnormal

[Term]
id: WBPhenotype0001102
name: mitotic_spindle_abnormal_early_emb
synonym: "Emb" BROAD three_letter_name []
is_a: WBPhenotype0000759 ! spindle_abnormal_early_emb

[Term]
id: WBPhenotype0001103
name: spindle_absent_early_emb
synonym: "Emb" BROAD three_letter_name []
is_a: WBPhenotype0001102 ! mitotic_spindle_abnormal_early_emb

[Term]
id: WBPhenotype0001104
name: spindle_absent_P0_early_emb
def: "No mitotic spindle is seen in P0." [WB:cab, WB:cgc5599]
synonym: "Emb" BROAD three_letter_name []
is_a: WBPhenotype0001103 ! spindle_absent_early_emb

[Term]
id: WBPhenotype0001105
name: P0_spindle_position_abnormal_early_emb
def: "Altered P0 spindle placement causes either a symmetric first division, a division in which P1 is larger than AB, or a division in which the asymmetry is exaggerated such that AB is much larger than normal." [WB:cab, WB:cgc5599]
synonym: "Emb" BROAD three_letter_name []
is_a: WBPhenotype0000762 ! spindle_position_abnormal_early_emb

[Term]
id: WBPhenotype0001106
name: spindle_orientation_abnormal_AB_or_P1_early_emb
def: "The orientation of the spindle is aberrant in either the AB or the P1 cell." [WB:cab, WB:cgc5599]
synonym: "Emb" BROAD three_letter_name []
is_a: WBPhenotype0000760 ! spindle_orientation_abnormal_early_emb

[Term]
id: WBPhenotype0001107
name: spindle_rotation_abnormal_early_emb
def: "Rotation of the embryonic spindle is aberrant." [WB:cab, WB:WBPerson1815]
synonym: "Emb" BROAD three_letter_name []
is_a: WBPhenotype0001102 ! mitotic_spindle_abnormal_early_emb

[Term]
id: WBPhenotype0001108
name: spindle_rotation_failure_P0_early_emb
def: "P0 spindle fails to rotate and extends perpendicular to the long axis of the embryo." [WB:cab, WB:cgc5599]
synonym: "Emb" BROAD three_letter_name []
is_a: WBPhenotype0001107 ! spindle_rotation_abnormal_early_emb

[Term]
id: WBPhenotype0001109
name: spindle_rotation_delayed_P0_early_emb
def: "P0 spindle rotates late in the inviable one- to four-cell embryo." [WB:cab, WB:cgc5599]
synonym: "Emb" BROAD three_letter_name []
is_a: WBPhenotype0001107 ! spindle_rotation_abnormal_early_emb

[Term]
id: WBPhenotype0001110
name: aster_abnormal_early_emb
synonym: "Emb" BROAD three_letter_name []
synonym: "Let" BROAD three_letter_name []
is_a: WBPhenotype0001100 ! early_embryonic_lethal

[Term]
id: WBPhenotype0001111
name: aster_AB_abnormal_early_emb
synonym: "Emb" BROAD three_letter_name []
synonym: "Let" BROAD three_letter_name []
is_a: WBPhenotype0001110 ! aster_abnormal_early_emb

[Term]
id: WBPhenotype0001112
name: aster_AB_resembles_P1_aster_early_emb
def: "The morphology of the AB aster resembles that of the P1 aster in the inviable one- to four-cell embryo." [WB:cab, WB:cgc5599]
synonym: "Emb" BROAD three_letter_name []
synonym: "Let" BROAD three_letter_name []
is_a: WBPhenotype0001111 ! aster_AB_abnormal_early_emb

[Term]
id: WBPhenotype0001113
name: aster_P1_abnormal_early_emb
def: "The morphology of the P1 aster is abnormal in the inviable one- to four-cell embryo." [WB:cab, WB:cgc5599]
synonym: "Emb" BROAD three_letter_name []
synonym: "Let" BROAD three_letter_name []
is_a: WBPhenotype0001110 ! aster_abnormal_early_emb

[Term]
id: WBPhenotype0001114
name: cell_cycle_abnormal_early_emb
synonym: "Emb" BROAD three_letter_name []
synonym: "Let" BROAD three_letter_name []
is_a: WBPhenotype0000740 ! cell_cycle_abnormal
is_a: WBPhenotype0001100 ! early_embryonic_lethal

[Term]
id: WBPhenotype0001115
name: cell_cycle_timing_abnormal_early_emb
def: "Cell cycle timing is abnormal during the first four cell divisions." [WB:cab, WB:WBPerson1815]
synonym: "Emb" BROAD three_letter_name []
synonym: "Let" BROAD three_letter_name []
is_a: WBPhenotype0001114 ! cell_cycle_abnormal_early_emb

[Term]
id: WBPhenotype0001116
name: absolute_cell_cycle_timing_abnormal_early_emb
synonym: "Emb" BROAD three_letter_name []
synonym: "Let" BROAD three_letter_name []
is_a: WBPhenotype0001115 ! cell_cycle_timing_abnormal_early_emb

[Term]
id: WBPhenotype0001117
name: cell_cell_contacts_abnormal_early_emb
def: "Cell-cell contacts are abnormal in the early embryo." [WB:cab, WB:WBPerson1815]
synonym: "Emb" BROAD three_letter_name []
synonym: "Let" BROAD three_letter_name []
is_a: WBPhenotype0001100 ! early_embryonic_lethal

[Term]
id: WBPhenotype0001118
name: cell_position_abnormal_early_emb
def: "Cell position is abnormal in the early embryo." [WB:cab, WB:WBPerson1815]
synonym: "Emb" BROAD three_letter_name []
synonym: "Let" BROAD three_letter_name []
is_a: WBPhenotype0001100 ! early_embryonic_lethal

[Term]
id: WBPhenotype0001119
name: cell_cycle_slow_early_emb
def: "Embryos take longer to divide during the first and second cell divisions." [WB:cab, WB:cgc5599]
synonym: "Emb" BROAD three_letter_name []
synonym: "Let" BROAD three_letter_name []
is_a: WBPhenotype0001116 ! absolute_cell_cycle_timing_abnormal_early_emb

[Term]
id: WBPhenotype0001120
name: relative_cell_cycle_timing_abnormal_early_emb
def: "Relative cell cycle timing during the first two cell divisions is aberrant." [WB:cab, WB:WBPerson1815]
synonym: "Emb" BROAD three_letter_name []
synonym: "Let" BROAD three_letter_name []
is_a: WBPhenotype0001115 ! cell_cycle_timing_abnormal_early_emb

[Term]
id: WBPhenotype0001121
name: exaggerated_asynchrony_early_emb
def: "Asynchrony of the second division is exaggerated and P1 divides more slowly than normal." [WB:cab, WB:cgc5599]
synonym: "Emb" BROAD three_letter_name []
synonym: "Let" BROAD three_letter_name []
is_a: WBPhenotype0001120 ! relative_cell_cycle_timing_abnormal_early_emb

[Term]
id: WBPhenotype0001122
name: reversed_asynchrony_early_emb
def: "P1 divides before AB." [WB:cab, WB:cgc5599]
synonym: "Emb" BROAD three_letter_name []
synonym: "Let" BROAD three_letter_name []
is_a: WBPhenotype0001120 ! relative_cell_cycle_timing_abnormal_early_emb

[Term]
id: WBPhenotype0001123
name: synchronous_second_division_early_emb
def: "AB and P1 divide synchronously." [WB:cab, WB:cgc5599]
synonym: "Emb" BROAD three_letter_name []
synonym: "Let" BROAD three_letter_name []
is_a: WBPhenotype0001120 ! relative_cell_cycle_timing_abnormal_early_emb

[Term]
id: WBPhenotype0001124
name: synchronous_division_Aba_ABp_EMS_early_emb
def: "EMS divides at the same time that ABa and ABp divide." [WB:cab, WB:cgc5599]
synonym: "Emb" BROAD three_letter_name []
synonym: "Let" BROAD three_letter_name []
is_a: WBPhenotype0001120 ! relative_cell_cycle_timing_abnormal_early_emb

[Term]
id: WBPhenotype0001125
name: synchronous_division_P2_EMS_early_emb
def: "P2 and EMS divide synchronously." [WB:cab, WB:cgc5599]
synonym: "Emb" BROAD three_letter_name []
synonym: "Let" BROAD three_letter_name []
is_a: WBPhenotype0001120 ! relative_cell_cycle_timing_abnormal_early_emb

[Term]
id: WBPhenotype0001126
name: cell_cell_contacts_abnormal_four_cell_emb
def: "Aba, ABp, EMS, or P1 contacts fewer of its sister cells than in wild-type embryos." [WB:cab, WB:cgc5599]
synonym: "Emb" BROAD three_letter_name []
synonym: "Let" BROAD three_letter_name []
is_a: WBPhenotype0001117 ! cell_cell_contacts_abnormal_early_emb

[Term]
id: WBPhenotype0001127
name: anterior_extension_EMS_fails_early_emb
def: "EMS fails to extend anteriorly and \"hug\"  ABa." [WB:cab, WB:cgc5599]
synonym: "Emb" BROAD three_letter_name []
synonym: "Let" BROAD three_letter_name []
is_a: WBPhenotype0001118 ! cell_position_abnormal_early_emb

[Term]
id: WBPhenotype0001128
name: anterior_extension_EMS_extreme_early_emb
def: "EMS extends too far anteriorly at the four cell stage." [WB:cab, WB:cgc5599]
synonym: "Emb" BROAD three_letter_name []
synonym: "Let" BROAD three_letter_name []
is_a: WBPhenotype0001118 ! cell_position_abnormal_early_emb

[Term]
id: WBPhenotype0001129
name: cleavage_furrow_abnormal_early_emb
synonym: "cleavage_furrow_abnormal" RELATED []
synonym: "Emb" BROAD three_letter_name []
is_a: WBPhenotype0001100 ! early_embryonic_lethal

[Term]
id: WBPhenotype0001130
name: cytokinesis_fails_early_emb
def: "Cells of the embryo attempt to divide but fail to form two daughter cells." [WB:cab, WB:cgc5599]
synonym: "Cyk" BROAD three_letter_name []
synonym: "Emb" BROAD three_letter_name []
is_a: WBPhenotype0001078 ! cytokinesis_abnormal_early_emb

[Term]
id: WBPhenotype0001131
name: loose_mitotic_furrow_early_emb
def: "Once formed, the mitotic furrow can \"slide\"laterally." [WB:cab, WB:cgc5599]
synonym: "Emb" BROAD three_letter_name []
is_a: WBPhenotype0001129 ! cleavage_furrow_abnormal_early_emb

[Term]
id: WBPhenotype0001132
name: ectopic_cleavage_furrows_early_emb
def: "Extra cleavage furrows are seen in one or all cells of a one-cell to four-cell embryo." [WB:cab, WB:cgc5599]
synonym: "Emb" BROAD three_letter_name []
is_a: WBPhenotype0001129 ! cleavage_furrow_abnormal_early_emb

[Term]
id: WBPhenotype0001133
name: division_axis_abnormal_early_emb
def: "Division axis within the first four divisions is not normal." [WB:cab, WB:WBPerson1815]
synonym: "Emb" BROAD three_letter_name []
is_a: WBPhenotype0001100 ! early_embryonic_lethal

[Term]
id: WBPhenotype0001134
name: division_axis_Aba_ABp_abnormal_early_emb
def: "ABa or ABp divide in the wrong orientation." [WB:cab, WB:cgc5599]
synonym: "Emb" BROAD three_letter_name []
is_a: WBPhenotype0001133 ! division_axis_abnormal_early_emb

[Term]
id: WBPhenotype0001135
name: embryonic_morphology_abnormal_early_emb
synonym: "Emb" BROAD three_letter_name []
is_a: WBPhenotype0001100 ! early_embryonic_lethal
is_a: WBPhenotype0001136 ! embryonic_morphology_abnormal

[Term]
id: WBPhenotype0001136
name: embryonic_morphology_abnormal
is_a: WBPhenotype0000037 ! egg_morphology_abnormal

[Term]
id: WBPhenotype0001137
name: embryos_small_early_emb
def: "Embryos are produced that are less than fifty percent  of the size of wild-type embryos." [WB:cab, WB:WBPaper00005599]
synonym: "Emb" BROAD three_letter_name []
is_a: WBPhenotype0001135 ! embryonic_morphology_abnormal_early_emb

[Term]
id: WBPhenotype0001138
name: nucleus_abnormal_early_emb
def: "Nucleus is abnormal in the inviable one- to four-cell embryo." [WB:cab, WB:WBPerson1815]
synonym: "Emb" BROAD three_letter_name []
is_a: WBPhenotype0001034 ! pronuclear_nuclear_appearance_abnormal_early_emb

[Term]
id: WBPhenotype0001139
name: nuclear_reassembly_abnormal_early_emb
def: "Nuclear envelope does not reassemble properly." [WB:cab, WB:cgc5599]
synonym: "Emb" BROAD three_letter_name []
is_a: WBPhenotype0001138 ! nucleus_abnormal_early_emb

[Term]
id: WBPhenotype0001140
name: neuron_migration_abnormal
is_a: WBPhenotype0000594 ! cell_migration_abnormal

[Term]
id: WBPhenotype0001141
name: nucleus_reform_remnant_early_emb
def: "After division of either one-cell or two-cell embryos, the nuclei reappear next to the cell division remnant." [WB:cab, WB:cgc5599]
synonym: "Emb" BROAD three_letter_name []
is_a: WBPhenotype0001027 ! nuclear_position_abnormal_early_emb

[Term]
id: WBPhenotype0001142
name: nuclear_number_abnormal_early_emb
def: "Nuclear number is abnormal in the inviable one- to four-cell embryo." [WB:cab, WB:WBPerson1815]
synonym: "Emb" BROAD three_letter_name []
is_a: WBPhenotype0001035 ! nuclear_appearance_number_abnormal_early_emb

[Term]
id: WBPhenotype0001143
name: multiple_nuclei_early_emb
def: "Embryos contain more than one nucleus per cell in the inviable one- to four-cell embryo." [WB:cab, WB:cgc5599]
synonym: "Emb" BROAD three_letter_name []
synonym: "karyomeres" RELATED []
synonym: "Mul" BROAD three_letter_name []
synonym: "multiple_nuclei_in_early_embryo_emb" RELATED []
is_a: WBPhenotype0000746 ! cell_division_abnormal
is_a: WBPhenotype0001142 ! nuclear_number_abnormal_early_emb

[Term]
id: WBPhenotype0001144
name: polar_body_number_size_early_emb
def: "Defects are either seen in the number or size of the polar bodies in the inviable one- to four-cell embryo." [WB:cab, WB:cgc5599]
synonym: "Emb" BROAD three_letter_name []
is_a: WBPhenotype0001147 ! polar_body_abnormal_early_emb

[Term]
id: WBPhenotype0001145
name: polar_body_number_abnormal_early_emb
def: "Polar body number is abnormal in the inviable one- to four-cell embryo." [WB:cab, WB:WBPerson1815]
synonym: "Emb" BROAD three_letter_name []
is_a: WBPhenotype0001144 ! polar_body_number_size_early_emb

[Term]
id: WBPhenotype0001146
name: polar_body_size_abnormal_early_emb
def: "Polar body size is abnormal in the inviable one- to four-cell embryo." [WB:cab, WB:WBPerson1815]
synonym: "Emb" BROAD three_letter_name []
is_a: WBPhenotype0001144 ! polar_body_number_size_early_emb

[Term]
id: WBPhenotype0001147
name: polar_body_abnormal_early_emb
def: "Polar bodies are abnormal in the inviable one- to four-cell embryo." [WB:cab, WB:WBPerson1815]
synonym: "Emb" BROAD three_letter_name []
is_a: WBPhenotype0001100 ! early_embryonic_lethal

[Term]
id: WBPhenotype0001148
name: polar_body_reabsorbed_early_emb
def: "Polar body is reabsorbed in the one- to four-cell embryo." [WB:cab, WB:WBPerson1815]
synonym: "Emb" BROAD three_letter_name []
is_a: WBPhenotype0000777 ! polar_body_extrusion_abnormal_early_emb

[Term]
id: WBPhenotype0001149
name: polar_body_reabsorbed_first_early_emb
synonym: "Emb" BROAD three_letter_name []
is_a: WBPhenotype0001148 ! polar_body_reabsorbed_early_emb

[Term]
id: WBPhenotype0001150
name: polar_body_reabsorbed_one_two_early_emb
def: "A polar body is reabsorbed in either the one cell- or the two-cell embryo." [WB:cab, WB:cgc5599]
synonym: "Emb" BROAD three_letter_name []
is_a: WBPhenotype0001148 ! polar_body_reabsorbed_early_emb

[Term]
id: WBPhenotype0001151
name: pronucleus_centrosomes_abnormal_early_emb
def: "Pronucleus is abnormal in the inviable embryo." [WB:cab, WB:WBPerson1815]
synonym: "Emb" BROAD three_letter_name []
is_a: WBPhenotype0001034 ! pronuclear_nuclear_appearance_abnormal_early_emb

[Term]
id: WBPhenotype0001152
name: pronuclear_migration_abnormal_early_emb
def: "Pronucleus migration is abnormal in the inviable embryo." [WB:cab, WB:WBPerson1815]
synonym: "Emb" BROAD three_letter_name []
is_a: WBPhenotype0001151 ! pronucleus_centrosomes_abnormal_early_emb

[Term]
id: WBPhenotype0001153
name: pronuclear_migration_failure_early_emb
def: "Neither of the pronuclei migrate and they never meet." [WB:cab, WB:cgc5599]
synonym: "Emb" BROAD three_letter_name []
is_a: WBPhenotype0001152 ! pronuclear_migration_abnormal_early_emb

[Term]
id: WBPhenotype0001154
name: paternal_pronucleus_migrates_early_emb
def: "Instead of the maternal pronucleus migrating to the posterior end of the one-cell embryo, the paternal pronucleus migrates to meet the maternal pronucleus in the anterior end." [WB:cab, WB:cgc5599]
synonym: "Emb" BROAD three_letter_name []
is_a: WBPhenotype0001152 ! pronuclear_migration_abnormal_early_emb

[Term]
id: WBPhenotype0001155
name: pronuclei_meet_centrally_early_emb
def: "The maternal and paternal pronuclei meet more centrally instead of meeting in the posterior end of the embryo." [WB:cab, WB:cgc5599]
synonym: "Emb" BROAD three_letter_name []
is_a: WBPhenotype0001152 ! pronuclear_migration_abnormal_early_emb

[Term]
id: WBPhenotype0001156
name: pronuclear_size_abnormal_early_emb
def: "Maternal or paternal pronucleus is either too small or too large." [WB:cab, WB:cgc5599]
synonym: "Emb" BROAD three_letter_name []
is_a: WBPhenotype0001159 ! pronuclear_morphology_abnormal_early_emb

[Term]
id: WBPhenotype0001157
name: pronuclear_breakdown_abnormal_early_emb
def: "Pronuclear breakdown is atypical in the inviable embryo." [WB:cab, WB:WBPerson1815]
synonym: "Emb" BROAD three_letter_name []
is_a: WBPhenotype0001151 ! pronucleus_centrosomes_abnormal_early_emb

[Term]
id: WBPhenotype0001158
name: pronuclear_breakdown_asynchronous_early_emb
def: "Instead of breaking down synchronously, the two pronuclei break down asynchronously in the inviable one-cell embryo." [WB:cab, WB:cgc5599]
synonym: "Emb" BROAD three_letter_name []
is_a: WBPhenotype0001157 ! pronuclear_breakdown_abnormal_early_emb

[Term]
id: WBPhenotype0001159
name: pronuclear_morphology_abnormal_early_emb
def: "Pronucleus morphology is atypical in the inviable embryo." [WB:cab, WB:cgc5599]
synonym: "Emb" BROAD three_letter_name []
is_a: WBPhenotype0001151 ! pronucleus_centrosomes_abnormal_early_emb

[Term]
id: WBPhenotype0001160
name: pronuclear_envelope_morphology_abnormal_early_emb
def: "Morphology of the pronuclear envelope is atypical in the inviable embryo." [WB:cab, WB:WBPerson1815]
synonym: "Emb" BROAD three_letter_name []
is_a: WBPhenotype0001159 ! pronuclear_morphology_abnormal_early_emb

[Term]
id: WBPhenotype0001161
name: maternal_pronucleus_indistinct_early_emb
def: "Maternal pronucleus has a blurry appearance.  The nuclear envelope does not have a crisp circular shape." [WB:cab, WB:cgc5599]
synonym: "Emb" BROAD three_letter_name []
is_a: WBPhenotype0001160 ! pronuclear_envelope_morphology_abnormal_early_emb

[Term]
id: WBPhenotype0001162
name: pronuclear_number_abnormal_early_emb
def: "There are more than two pronuclei in the inviable embryo." [WB:cab, WB:WBPerson1815]
synonym: "Emb" BROAD three_letter_name []
is_a: WBPhenotype0001151 ! pronucleus_centrosomes_abnormal_early_emb

[Term]
id: WBPhenotype0001163
name: pronucleus_formation_failure_early_emb
def: "Either the maternal or paternal pronucleus is absent." [WB:cab, WB:cgc5599]
synonym: "Emb" BROAD three_letter_name []
is_a: WBPhenotype0001162 ! pronuclear_number_abnormal_early_emb

[Term]
id: WBPhenotype0001164
name: excess_pronuclei_early_emb
def: "There is either more than one maternal or paternal pronucleus in the inviable embryo." [WB:cab, WB:WBPerson1815]
synonym: "Emb" BROAD three_letter_name []
is_a: WBPhenotype0001162 ! pronuclear_number_abnormal_early_emb

[Term]
id: WBPhenotype0001165
name: excess_maternal_pronuclei_early_emb
def: "One-cell embryos have two or more maternal pronuclei." [WB:cab, WB:cgc5599]
synonym: "Emb" BROAD three_letter_name []
is_a: WBPhenotype0001164 ! excess_pronuclei_early_emb

[Term]
id: WBPhenotype0001166
name: excess_paternal_pronuclei_abnormal_centrosome_early_emb
def: "More than one paternal pronucleus is present in the inviable one-cell embryo or there is a defect in centrosome structure." [WB:cab, WB:cgc5599]
synonym: "Emb" BROAD three_letter_name []
is_a: WBPhenotype0001164 ! excess_pronuclei_early_emb

[Term]
id: WBPhenotype0001167
name: pseudocleavage_abnormal_early_emb
def: "Pseudocleavage is atypical in the inviable one-cell embryo." [WB:cab, WB:WBPerson1815]
synonym: "Emb" BROAD three_letter_name []
is_a: WBPhenotype0001100 ! early_embryonic_lethal

[Term]
id: WBPhenotype0001168
name: pseudocleavage_absent_early_emb
def: "No pseudocleavage is observed before or during pronuclear migration." [WB:cab, WB:cgc5599]
synonym: "Emb" BROAD three_letter_name []
synonym: "no_pseudocleavage" RELATED []
is_a: WBPhenotype0001167 ! pseudocleavage_abnormal_early_emb

[Term]
id: WBPhenotype0001169
name: pseudocleavage_exaggerated_early_emb
def: "Embryos have more pronounced pseudocleavage than normal." [WB:cab, WB:cgc5599]
synonym: "Emb" BROAD three_letter_name []
is_a: WBPhenotype0001167 ! pseudocleavage_abnormal_early_emb

[Term]
id: WBPhenotype0001170
name: sterile_F0_48_hours_post_injection
def: "Injected worm stops producing embryos 48 hours after RNAi injection and contains no live/developing embryos at this time." [WB:cab, WB:cgc5599]
synonym: "P0_sterile" NARROW []
synonym: "Ste" BROAD []
is_a: WBPhenotype0000689 ! maternal_sterile

[Term]
id: WBPhenotype0001171
name: shortened_life_span
synonym: "Age" BROAD three_letter_name []
synonym: "longevity_decreased" RELATED []
is_a: WBPhenotype0000039 ! life_span_abnormal

[Term]
id: WBPhenotype0001172
name: programmed_cell_death_abnormal
is_a: WBPhenotype0000729 ! cell_death_abnormal

[Term]
id: WBPhenotype0001173
name: non_apoptotic_cell_death_abnormal
is_a: WBPhenotype0001172 ! programmed_cell_death_abnormal

[Term]
id: WBPhenotype0001174
name: chromosome_disjunction_abnormal
synonym: "Him" BROAD three_letter_name []
is_a: WBPhenotype0000775 ! meiosis_abnormal

[Term]
id: WBPhenotype0001175
name: high_incidence_male_progeny
def: "Higher numbers of male progeny as a result of X chromosome nondisjunction." [WB:cab, WB:WBPaper00004402, WB:WBPaper00005654]
synonym: "Him" BROAD three_letter_name []
synonym: "x_chromosome_nondisjunction" RELATED []
is_a: WBPhenotype0001174 ! chromosome_disjunction_abnormal

[Term]
id: WBPhenotype0001176
name: one_cell_shape_abnormal_early_emb
def: "One-cell embryos have an altered shape." [WB:cab, WB:cgc5599]
synonym: "Emb" BROAD three_letter_name []
is_a: WBPhenotype0001135 ! embryonic_morphology_abnormal_early_emb

[Term]
id: WBPhenotype0001177
name: embryo_osmotic_pressure_sensitive_early_emb
def: "Embryos rupture when placed on a 2% agar pad and covered with a coverslip." [WB:cab, WB:cgc5599]
synonym: "Emb" BROAD three_letter_name []
is_a: WBPhenotype0001178 ! egg_integrity_abnormal_early_emb

[Term]
id: WBPhenotype0001178
name: egg_integrity_abnormal_early_emb
synonym: "Emb" BROAD three_letter_name []
is_a: WBPhenotype0001100 ! early_embryonic_lethal

[Term]
id: WBPhenotype0001179
name: No_abnormality_scored
def: "Phenotypic examination of worms did not reveal an obvious abnormality compared with wild type." [WB:cab]
comment: The phenotype ontology was restructured such that "Abnormal" is now the root term.  The term "Abnormal" with a "Not" qualifier is a suggested replacement for this term.
synonym: "WT" RELATED []
is_obsolete: true

[Term]
id: WBPhenotype0001180
name: accumulated_germline_cell_corpses
is_a: WBPhenotype0000241 ! accumulated_cell_corpses

[Term]
id: WBPhenotype0001181
name: accumulated_somatic_cell_corpses
is_a: WBPhenotype0000241 ! accumulated_cell_corpses

[Term]
id: WBPhenotype0001182
name: fat_content_abnormal
is_a: WBPhenotype0000725 ! lipid_metabolism_abnormal

[Term]
id: WBPhenotype0001183
name: fat_content_reduced
is_a: WBPhenotype0001182 ! fat_content_abnormal

[Term]
id: WBPhenotype0001184
name: fat_content_increased
is_a: WBPhenotype0001182 ! fat_content_abnormal

[Term]
id: WBPhenotype0001185
name: embryonic_developmental_delay_early_emb
synonym: "Emb" BROAD three_letter_name []
is_a: WBPhenotype0001100 ! early_embryonic_lethal

[Term]
id: WBPhenotype0001186
name: delayed_at_pronuclear_contact_early_emb
def: "Embryos are either delayed or arrested at pronuclear contact." [WB:cab, WB:cgc5599]
synonym: "Emb" BROAD three_letter_name []
is_a: WBPhenotype0001185 ! embryonic_developmental_delay_early_emb

[Term]
id: WBPhenotype0001187
name: division_EMS_before_P1_early_emb
synonym: "Emb" BROAD three_letter_name []
synonym: "Let" BROAD three_letter_name []
is_a: WBPhenotype0001120 ! relative_cell_cycle_timing_abnormal_early_emb

[Term]
id: WBPhenotype0001188
name: radial_filament_structure_abnormal_pharynx
is_a: WBPhenotype0001046 ! pharyngeal_muscle_morphology_abnormal

[Term]
id: WBPhenotype0001189
name: adherens_junctions_abnormal_pharyngeal_muscle
is_a: WBPhenotype0001046 ! pharyngeal_muscle_morphology_abnormal

[Term]
id: WBPhenotype0001190
name: pharyngeal_physiology_abnormal
is_a: WBPhenotype0000606 ! alimentary_system_physiology_abnormal

[Term]
id: WBPhenotype0001191
name: pharyngeal_muscle_physiology_abnormal
is_a: WBPhenotype0001190 ! pharyngeal_physiology_abnormal

[Term]
id: WBPhenotype0001192
name: calcium_signaling_abnormal
is_a: WBPhenotype0001191 ! pharyngeal_muscle_physiology_abnormal

[Term]
id: WBPhenotype0001193
name: disorganized_pharyngeal_EPG
def: "Electropharyngeograms of mutants do not show a repeating, regular pattern.  In wild type each pump is associated with an excitatory depolarizing wave, often punctuated by brief negative spikes,  followed by a plateau phase, and ending with an inhibitory hyperpolarizing wave." [WB:cab, WB:cgc7545]
is_a: WBPhenotype0000980 ! pharyngeal_contraction_abnormal

[Term]
id: WBPhenotype0001194
name: ectopic_neuron
is_a: WBPhenotype0001140 ! neuron_migration_abnormal

[Term]
id: WBPhenotype0001195
name: generation_calcium_signal_defect_pharynx
def: "Rhythmic calcium increases are observed less often than in wild type.  In wild type rhythmic increases in intracellular calcium are observed using a transgenically expressed cameleon, a ratiometric calcium indicator." [WB:cab, WB:cgc4194, WB:cgc7545]
is_a: WBPhenotype0001192 ! calcium_signaling_abnormal

[Term]
id: WBPhenotype0001196
name: synchronization_calcium_signal_defect_pharynx
def: "Calcium spikes are not synchronous in the musculature of the corpus and the terminal bulb." [WB:cab, WB:cgc7545]
is_a: WBPhenotype0001192 ! calcium_signaling_abnormal

[Term]
id: WBPhenotype0001197
name: somatic_gonad_physiology_abnormal
is_a: WBPhenotype0000613 ! reproductive_system_physiology_abnormal

[Term]
id: WBPhenotype0001198
name: somatic_sheath_physiology_abnormal
is_a: WBPhenotype0001197 ! somatic_gonad_physiology_abnormal

[Term]
id: WBPhenotype0001199
name: gonad_sheath_contractions_abnormal
is_a: WBPhenotype0001198 ! somatic_sheath_physiology_abnormal

[Term]
id: WBPhenotype0001200
name: gonad_sheath_contraction_rate_reduced
def: "Basal contraction rate of the gonadal sheath is reduced relative to wild type." [WB:cab, WB:cgc7545]
is_a: WBPhenotype0001199 ! gonad_sheath_contractions_abnormal

[Term]
id: WBPhenotype0001201
name: no_expulsion_defecation
is_a: WBPhenotype0000391 ! defecation_missing_motor_steps

[Term]
id: WBPhenotype0001202
name: nicotine_hypersensitive
def: "Worms display hypersensitivity to the effects of nicotine compared with wild type." [WB:cab, WB:cgc7388]
is_a: WBPhenotype0000010 ! hypersensitive_to_drug

[Term]
id: WBPhenotype0001203
name: nicotine_resistant
def: "Worms exhibit resistance to the effects of nicotine compared to wild type." [WB:cab, WB:cgc7388]
is_a: WBPhenotype0000011 ! resistant_to_drug

[Term]
id: WBPhenotype0001204
name: muscimol_resistant
is_a: WBPhenotype0000011 ! resistant_to_drug

[Term]
id: WBPhenotype0001205
name: muscimol_hypersensitive
is_a: WBPhenotype0000010 ! hypersensitive_to_drug

[Term]
id: WBPhenotype0001206
name: movement_abnormal
subset: phenotype_slim_wb
is_a: WBPhenotype0000525 ! organism_behavior_abnormal

[Term]
id: WBPhenotype0001207
name: protein_signaling_abnormal
is_a: WBPhenotype0000577 ! organism_homeostasis_metabolism_abnormal

[Term]
id: WBPhenotype0001208
name: RNAi_resistant
is_a: WBPhenotype0000743 ! RNAi_response_abnormal

[Term]
id: WBPhenotype0001209
name: skiddy
is_a: WBPhenotype0000643 ! locomotion_abnormal

[Term]
id: WBPhenotype0001210
name: pericellular_component_physiology_abnormal
subset: phenotype_slim_wb
is_a: WBPhenotype0000519 ! physiology_abnormal

[Term]
id: WBPhenotype0001211
name: cuticle_integrity_abnormal
is_a: WBPhenotype0001210 ! pericellular_component_physiology_abnormal

[Term]
id: WBPhenotype0001212
name: cuticle_fragile
is_a: WBPhenotype0001211 ! cuticle_integrity_abnormal

[Term]
id: WBPhenotype0001213
name: locomotion_reduced
is_a: WBPhenotype0000641 ! activity_level_abnormal

[Term]
id: WBPhenotype0001214
name: metaphase_to_anaphase_transition_fails
is_a: WBPhenotype0000775 ! meiosis_abnormal

[Term]
id: WBPhenotype0001215
name: germ_cell_mitosis_abnormal
is_a: WBPhenotype0000823 ! germ_cell_proliferation_abnormal

[Term]
id: WBPhenotype0001216
name: meiosis_metaphase_to_anaphase_transition_block
is_a: WBPhenotype0000775 ! meiosis_abnormal

[Term]
id: WBPhenotype0001217
name: germ_cell_mitosis_metaphase_to_anaphase_transition_block
is_a: WBPhenotype0001215 ! germ_cell_mitosis_abnormal

[Term]
id: WBPhenotype0001218
name: sexually_dimorphic_cell_death_abnormal
is_a: WBPhenotype0000730 ! apoptosis_abnormal

[Term]
id: WBPhenotype0001219
name: cell_survival_sexually_dimorphic_abnormal
is_a: WBPhenotype0001218 ! sexually_dimorphic_cell_death_abnormal

[Term]
id: WBPhenotype0001220
name: abnormal_cell_death_sexually_dimorphic
is_a: WBPhenotype0001218 ! sexually_dimorphic_cell_death_abnormal

[Term]
id: WBPhenotype0001221
name: nose_touch_defect
is_a: WBPhenotype0000456 ! touch_insensitive

[Term]
id: WBPhenotype0001222
name: transposon_mutator
is_a: WBPhenotype0000228 ! spontaneous_mutation_rate_increased

[Term]
id: WBPhenotype0001223
name: germline_RNAi_resistant
is_a: WBPhenotype0001208 ! RNAi_resistant

[Term]
id: WBPhenotype0001224
name: axon_outgrowth_abnormal
is_a: WBPhenotype0000880 ! axon_development_abnormal

[Term]
id: WBPhenotype0001225
name: phasmid_socket_absent
synonym: "Psa" RELATED []
is_a: WBPhenotype0000257 ! phasmid_morphology_abnormal

[Term]
id: WBPhenotype0001226
name: commissure_abnormal
is_a: WBPhenotype0000181 ! axon_trajectory_abnormal
is_a: WBPhenotype0001224 ! axon_outgrowth_abnormal

[Term]
id: WBPhenotype0001227
name: commissure_absent
is_a: WBPhenotype0001226 ! commissure_abnormal

[Term]
id: WBPhenotype0001228
name: alae_absent
is_a: WBPhenotype0000202 ! alae_abnormal

[Term]
id: WBPhenotype0001229
name: anterior_neuron_migration
is_a: WBPhenotype0001140 ! neuron_migration_abnormal

[Term]
id: WBPhenotype0001230
name: anterior_cell_migration
is_a: WBPhenotype0000594 ! cell_migration_abnormal

[Term]
id: WBPhenotype0001231
name: intraflagellar_transport_accelerated
synonym: "ift_accelerated" RELATED []
is_a: WBPhenotype0000853 ! intraflagellar_transport_abnormal

[Term]
id: WBPhenotype0001232
name: serotonin_response_abnormal
is_a: WBPhenotype0000631 ! drug_response_abnormal

[Term]
id: WBPhenotype0001233
name: dapI_staining_abnormal
is_a: WBPhenotype0010002 ! cell_organization_and_biogenesis_abnormal

[Term]
id: WBPhenotype0001234
name: 2_nonanone_chemoaversion_abnormal
is_a: WBPhenotype0000481 ! chemoaversion_abnormal

[Term]
id: WBPhenotype0001235
name: cell_division_polarity_abnormal
is_a: WBPhenotype0000746 ! cell_division_abnormal

[Term]
id: WBPhenotype0001236
name: transgene_expression_increased
is_a: WBPhenotype0000962 ! level_of_transgene_expression_abnormal

[Term]
id: WBPhenotype0001237
name: ectopic_axon_outgrowth
is_a: WBPhenotype0000629 ! ectopic_neurite_outgrowth
is_a: WBPhenotype0001224 ! axon_outgrowth_abnormal

[Term]
id: WBPhenotype0001238
name: male_mating_latency_abnormal
def: "Any abnormality in the length of time required for a male to find a hermaphrodite and pause to press its ventral side against the surface of the hermaphrodite and initiate a backing up search for the vulva." [pmid:16624900, WB:cab]
is_a: WBPhenotype0000648 ! male_mating_abnormal

[Term]
id: WBPhenotype0001239
name: mating_latency_increased
is_a: WBPhenotype0001238 ! male_mating_latency_abnormal

[Term]
id: WBPhenotype0001240
name: male_tail_sensory_ray_differentiation_abnormal
is_a: WBPhenotype0000199 ! male_tail_sensory_ray_development_abnormal

[Term]
id: WBPhenotype0001241
name: ray_fusion
is_a: WBPhenotype0000199 ! male_tail_sensory_ray_development_abnormal

[Term]
id: WBPhenotype0001242
name: intraflagellar_transport_slow
is_a: WBPhenotype0000854 ! intraflagellar_transport_defective

[Term]
id: WBPhenotype0001243
name: intraflagellar_transport_distance_short
is_a: WBPhenotype0001247 ! anterograde_transport_defective

[Term]
id: WBPhenotype0001244
name: no_intraflagellar_transport
is_a: WBPhenotype0000854 ! intraflagellar_transport_defective

[Term]
id: WBPhenotype0001245
name: no_transport_middle_segment_cilia
is_a: WBPhenotype0001243 ! intraflagellar_transport_distance_short

[Term]
id: WBPhenotype0001246
name: no_transport_distal_segment_cilia
is_a: WBPhenotype0001243 ! intraflagellar_transport_distance_short

[Term]
id: WBPhenotype0001247
name: anterograde_transport_defective
is_a: WBPhenotype0000854 ! intraflagellar_transport_defective

[Term]
id: WBPhenotype0001248
name: wing_cilia_morphology_abnormal
synonym: "awc_cilia_morphology_abnormal" RELATED []
is_a: WBPhenotype0000615 ! cilia_morphology_abnormal

[Term]
id: WBPhenotype0001249
name: amphid_channel_cilia_morphology_abnormal
is_a: WBPhenotype0000615 ! cilia_morphology_abnormal

[Term]
id: WBPhenotype0001250
name: amphid_channel_axoneme_morphology_abnormal
is_a: WBPhenotype0001249 ! amphid_channel_cilia_morphology_abnormal

[Term]
id: WBPhenotype0001251
name: amphid_channel_axoneme_short
is_a: WBPhenotype0001250 ! amphid_channel_axoneme_morphology_abnormal

[Term]
id: WBPhenotype0001252
name: wing_cilia_axoneme_morphology_abnormal
is_a: WBPhenotype0001248 ! wing_cilia_morphology_abnormal

[Term]
id: WBPhenotype0001253
name: wing_cilia_axoneme_short
is_a: WBPhenotype0001252 ! wing_cilia_axoneme_morphology_abnormal

[Term]
id: WBPhenotype0001254
name: amphid_channel_cilia_bulbous
is_a: WBPhenotype0001249 ! amphid_channel_cilia_morphology_abnormal

[Term]
id: WBPhenotype0001255
name: wing_cilia_bulbous
is_a: WBPhenotype0001252 ! wing_cilia_axoneme_morphology_abnormal

[Term]
id: WBPhenotype0001256
name: dna_damage_induced_focus_formation_abnormal
is_a: WBPhenotype0000739 ! DNA_damage_response_abnormal

[Term]
id: WBPhenotype0001257
name: cross_link_induced_focus_formation_abnormal
is_a: WBPhenotype0001256 ! dna_damage_induced_focus_formation_abnormal

[Term]
id: WBPhenotype0001258
name: RNAi_enhanced
is_a: WBPhenotype0000743 ! RNAi_response_abnormal

[Term]
id: WBPhenotype0001259
name: hermaphrodite_fertility_reduced
is_a: WBPhenotype0000806 ! hermaphrodite_fertility_abnormal

[Term]
id: WBPhenotype0001260
name: oocyte_morphology_abnormal
is_a: WBPhenotype0000900 ! germ_cell_morphology_abnormal

[Term]
id: WBPhenotype0001261
name: pale
is_a: WBPhenotype0000527 ! organism_pigmentation_abnormal

[Term]
id: WBPhenotype0001262
name: vulval_development_incomplete
is_a: WBPhenotype0000699 ! vulva_development_abnormal

[Term]
id: WBPhenotype0001263
name: peroxisome_morphology_abnormal
is_a: WBPhenotype0000533 ! cell_morphology_abnormal

[Term]
id: WBPhenotype0001264
name: peroxisome_physiology_abnormal
is_a: WBPhenotype0000536 ! cell_physiology_abnormal

[Term]
id: WBPhenotype0001265
name: head_movement_abnormal
is_a: WBPhenotype0000595 ! head_behavior_abnormal

[Term]
id: WBPhenotype0001266
name: genetic_pathway_activation_abnormal
is_a: WBPhenotype0000074 ! genetic_pathway_abnormal

[Term]
id: WBPhenotype0001267
name: induced_contraction_rate_abnormal
is_a: WBPhenotype0001199 ! gonad_sheath_contractions_abnormal

[Term]
id: WBPhenotype0001268
name: induced_cell_death_abnormal
is_a: WBPhenotype0000729 ! cell_death_abnormal

[Term]
id: WBPhenotype0001269
name: salmonella_induced_cell_death_abnormal
is_a: WBPhenotype0001268 ! induced_cell_death_abnormal

[Term]
id: WBPhenotype0001270
name: salmonella_induced_cell_death_reduced
is_a: WBPhenotype0001269 ! salmonella_induced_cell_death_abnormal

[Term]
id: WBPhenotype0001271
name: pathogen_induced_death_increased
is_a: WBPhenotype0001012 ! pathogen_response_abnormal

[Term]
id: WBPhenotype0001272
name: vulval_cell_induction_abnormal
is_a: WBPhenotype0000220 ! vulva_cell_fate_specification_abnormal

[Term]
id: WBPhenotype0001273
name: organism_heat_response_abnormal
is_a: WBPhenotype0000067 ! organism_stress_response_abnormal

[Term]
id: WBPhenotype0001274
name: organism_heat_hypersensitive
is_a: WBPhenotype0001273 ! organism_heat_response_abnormal

[Term]
id: WBPhenotype0001275
name: increased_genetic_pathway_signal
is_a: WBPhenotype0000074 ! genetic_pathway_abnormal

[Term]
id: WBPhenotype0001276
name: ectopic_expression_transgene
is_a: WBPhenotype0000961 ! pattern_of_transgene_expression_abnormal

[Term]
id: WBPhenotype0001277
name: transformer
def: "XX animals are transformed into males." [WB:cab]
synonym: "Tra" RELATED []
is_a: WBPhenotype0001022 ! hermaphrodite_sexual_development_abnormal

[Term]
id: WBPhenotype0001278
name: transgene_expression_decreased
is_a: WBPhenotype0000962 ! level_of_transgene_expression_abnormal

[Term]
id: WBPhenotype0001279
name: transgene_expression_decreased_males
is_a: WBPhenotype0001278 ! transgene_expression_decreased

[Term]
id: WBPhenotype0001280
name: transgene_expression_decreased_hermaphrodites
is_a: WBPhenotype0001278 ! transgene_expression_decreased

[Term]
id: WBPhenotype0001281
name: stuffed_pharynx
def: "Pharynx becomes stuffed with food as a result of pharyngeal pumping defects." [WB:cab]
is_a: WBPhenotype0000634 ! pharyngeal_pumping_abnormal
is_a: WBPhenotype0000778 ! feeding_inefficient

[Term]
id: WBPhenotype0001282
name: mitochondrial_metabolism_abnormal
is_a: WBPhenotype0001283 ! organelle_metabolism_abnormal

[Term]
id: WBPhenotype0001283
name: organelle_metabolism_abnormal
is_a: WBPhenotype0000585 ! cell_homeostasis_metabolism_abnormal

[Term]
id: WBPhenotype0001284
name: coenzyme_Q_depleted
is_a: WBPhenotype0000026 ! lipid_depleted
is_a: WBPhenotype0001282 ! mitochondrial_metabolism_abnormal

[Term]
id: WBPhenotype0001285
name: induced_pharyngeal_pumping_abnormal
is_a: WBPhenotype0001006 ! pharyngeal_pumping_rate_abnormal

[Term]
id: WBPhenotype0001286
name: food_suppressed_pumping_abnormal
is_a: WBPhenotype0001287 ! suppressed_pharyngeal_pumping_abnormal

[Term]
id: WBPhenotype0001287
name: suppressed_pharyngeal_pumping_abnormal
is_a: WBPhenotype0001006 ! pharyngeal_pumping_rate_abnormal

[Term]
id: WBPhenotype0001288
name: movement_reduced
is_a: WBPhenotype0001206 ! movement_abnormal

[Term]
id: WBPhenotype0004001
name: hermaphrodite_mating_abnormal
def: "Characteristic hermaphrodite behavior during mating is altered." [WB:WBPerson557]
is_a: WBPhenotype0000647 ! copulation_abnormal
is_a: WBPhenotype0000887 ! hermaphrodite_behavior_abnormal

[Term]
id: WBPhenotype0004002
name: attraction_signal_defective
def: "Hermaphrodites defective for the production of the sensory signal to attract males" [WB:WBPaper00005109]
is_a: WBPhenotype0004015 ! pre_male_contact_abnormal

[Term]
id: WBPhenotype0004003
name: mate_finding_abnormal
def: "Impaired ability of the male to respond to the hermaphrodite produced mate-finding cue." [WB:WBPaper00005109]
is_a: WBPhenotype0004005 ! pre_hermaphrodite_contact_abnormal

[Term]
id: WBPhenotype0004004
name: response_to_contact_defective
def: "The inability of a male to respond properly to a potential mate after contact.  Proper response includes apposing the ventral side of his tail to the hermaphrodite's body and swimming backward." [WB:WBPaper00000392, WB:WBPaper00002109]
is_a: WBPhenotype0004006 ! post_hermaphrodite_contact_abnormal

[Term]
id: WBPhenotype0004005
name: pre_hermaphrodite_contact_abnormal
def: "Characteristic male mating prior to hermaphrodite contact is altered" [WB:WBPerson557]
is_a: WBPhenotype0000648 ! male_mating_abnormal

[Term]
id: WBPhenotype0004006
name: post_hermaphrodite_contact_abnormal
def: "characteristic of male mating after hermaphrodite contact is altered" [WB:WBPerson557]
is_a: WBPhenotype0000648 ! male_mating_abnormal

[Term]
id: WBPhenotype0004007
name: periodic_spicule_prodding_defective
is_a: WBPhenotype0000279 ! spicule_insertion_defective

[Term]
id: WBPhenotype0004008
name: sustained_spicule_protraction_defective
is_a: WBPhenotype0000279 ! spicule_insertion_defective

[Term]
id: WBPhenotype0004009
name: approximate_vulval_location_abnormal
is_a: WBPhenotype0000649 ! vulva_location_abnormal

[Term]
id: WBPhenotype0004010
name: precise_vulval_location_abnormal
is_a: WBPhenotype0000649 ! vulva_location_abnormal

[Term]
id: WBPhenotype0004011
name: sperm_transfer_cessation_defective
is_a: WBPhenotype0000284 ! sperm_transfer_defective

[Term]
id: WBPhenotype0004012
name: sperm_transfer_continuation_defective
is_a: WBPhenotype0000284 ! sperm_transfer_defective

[Term]
id: WBPhenotype0004013
name: sperm_release_defective
is_a: WBPhenotype0000284 ! sperm_transfer_defective

[Term]
id: WBPhenotype0004014
name: post_male_contact_abnormal
is_a: WBPhenotype0004001 ! hermaphrodite_mating_abnormal

[Term]
id: WBPhenotype0004015
name: pre_male_contact_abnormal
is_a: WBPhenotype0004001 ! hermaphrodite_mating_abnormal

[Term]
id: WBPhenotype0004016
name: dauer_nictation_behavior_abnormal
is_a: WBPhenotype0001001 ! dauer_behavior_abnormal

[Term]
id: WBPhenotype0004017
name: locomotor_coordination_abnormal
def: "an altered ability to maintain characteristic and effective movement." [WB:WBperson557]
is_a: WBPhenotype0000643 ! locomotion_abnormal

[Term]
id: WBPhenotype0004018
name: sinusoidal_movement_abnormal
is_a: WBPhenotype0004017 ! locomotor_coordination_abnormal

[Term]
id: WBPhenotype0004022
name: amplitude_of_movement_abnormal
is_a: WBPhenotype0004018 ! sinusoidal_movement_abnormal

[Term]
id: WBPhenotype0004023
name: frequency_of_body_bends_abnormal
is_a: WBPhenotype0004018 ! sinusoidal_movement_abnormal

[Term]
id: WBPhenotype0004024
name: wavelength_of_movement_abnormal
is_a: WBPhenotype0004018 ! sinusoidal_movement_abnormal

[Term]
id: WBPhenotype0004025
name: velocity_of_movement_abnormal
is_a: WBPhenotype0004018 ! sinusoidal_movement_abnormal

[Term]
id: WBPhenotype0004026
name: nose_touch_abnormal
is_a: WBPhenotype0000315 ! mechanosensory_abnormal

[Term]
id: WBPhenotype0004027
name: plate_tap_reflex_abnormal
def: "abnormal response to substrate vibration" [WB:WBPerson557]
is_a: WBPhenotype0000315 ! mechanosensory_abnormal

[Term]
id: WBPhenotype0004028
name: slowing_response_on_food_abnormal
is_a: WBPhenotype0000315 ! mechanosensory_abnormal

[Term]
id: WBPhenotype0004029
name: sexually_dimorphic_mechanosensory_abnormal
is_a: WBPhenotype0000315 ! mechanosensory_abnormal

[Term]
id: WBPhenotype0004030
name: male_response_to_hermaphrodite_abnormal
is_a: WBPhenotype0004029 ! sexually_dimorphic_mechanosensory_abnormal

[Term]
id: WBPhenotype0004031
name: mate_searching_abnormal
def: "An altered ability to search for a mate as defined by failure of the \"leaving assay\"" [WB:WBPaper00024428]
is_a: WBPhenotype0004005 ! pre_hermaphrodite_contact_abnormal

[Term]
id: WBPhenotype0006001
name: squashed_vulva
is_a: WBPhenotype0000510 ! vulval_invagination_abnormal_at_L4

[Term]
id: WBPhenotype0008001
name: embryonic_cell_fate_specification_abnormal
def: "Any abnormality in the processes that govern acquisition of particular cell fates in the embryo, from the time of zygote formation until hatching." [WB:kmva]
is_a: WBPhenotype0000216 ! cell_fate_specification_abnormal
is_a: WBPhenotype0000749 ! embryonic_development_abnormal

[Term]
id: WBPhenotype0008002
name: embryonic_somatic_cell_fate_specification_abnormal
def: "Any abnormality in the processes that govern acquisition of somatic cell fates in the embryo, from the time of zygote formation until hatching." [WB:kmva]
is_a: WBPhenotype0008001 ! embryonic_cell_fate_specification_abnormal

[Term]
id: WBPhenotype0008003
name: odorant_imprinting_abnormal
def: "Any abnormality that results in alterations to the process of odorant imprinting, a learned olfactory response whereby exposure of animals to odorants during specific developmental times or physiological states results in a lasting memory that determines the animal's behavior upon encountering the same odorant at a later time." [WB:WBPaper00026662, WB:WBPerson1843]
synonym: "olfactory_imprinting_abnormal" EXACT []
is_a: WBPhenotype0001040 ! chemosensory_response_abnormal

[Term]
id: WBPhenotype0010001
name: cell_growth_abnormal
def: "The process(es) by which a cell irreversibly increases in size over time by accretion and biosynthetic production of matter similar to that already present, is altered." [GO:0016049, WB:rk]
subset: phenotype_slim_wb
is_a: WBPhenotype0000536 ! cell_physiology_abnormal

[Term]
id: WBPhenotype0010002
name: cell_organization_and_biogenesis_abnormal
def: "The process(es) involved in the assembly and arrangement of cell structures is altered." [GO:0016043, WB:rk]
subset: phenotype_slim_wb
is_a: WBPhenotype0000536 ! cell_physiology_abnormal

[Term]
id: WBPhenotype0010003
name: cell_corpse_appearance_delayed
def: "The appearance of cell corpses and their clearance is delayed " [WB:rk]
is_a: WBPhenotype0000185 ! apoptosis_protracted

[Term]
id: WBPhenotype0010004
name: cell_corpse_degradation_abnormal
def: "The normal process(es) that constitute cell corpse degradation within the engulfing cell  is altered." [WB:rk]
xref: WB:rk
is_a: WBPhenotype0000730 ! apoptosis_abnormal

[Typedef]
id: part_of
name: part_of
subset: phenotype_slim_wb
is_transitive: true

