#!/usr/bin/perl -w

# find cfp_<any> without value
# check cfp_ FALSE_POSITIVE  => cur_curdata says 'negative'
# check cur_curdata says 'negative' =>  cfp_ FALSE_POSITIVE

# Some tables need fixing afp_ cfp_ catalyticact chemphen envpheno rnaseq
# Some cfp_ tables don't have a curator
# 1281 cur_curdata value is negative.  only 411 of those say FALSE somewhere in there.
# 1932 have different curator for cur_curdata and cfp_ 
#  785 have      same curator for cur_curdata and cfp_  but of that data
#                524 is rnai junk
#                261 say FALSE POSITIVE
#                 14 might be meaningful
# For Kimberly to sort out topic migration to ABC.  2023 08 09

# Delete cfp_ entries without a character in the data (empty curators not fixed).  2023 08 17


use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %datatypes;		# tie %datatypes, "Tie::IxHash";         # all allowed datatypes, was tieing to separate/order nonSvm vs Svm, but not anymore  2012 11 16
my %datatypesAfpCfp;	# key datatype value is afp_ cfp_ tables's datatype to query (e.g. datatype 'blastomere' maps to 'cellfunc' for [ac]fp_cellfunc)
my %premadeComments;

my %cfp;
my %curdata;

&populateDatatypes();
&populatePremadeComments();

# &findEmptyCfpCurator();
# &findEmptyCfpData();

&readCfp();
&readCurdata();

&compareCurdataToCfp();


sub compareCurdataToCfp {
  foreach my $datatype (sort keys %curdata) {
    foreach my $joinkey (sort keys %{ $curdata{$datatype} }) {
      my $curdata = $curdata{$datatype}{$joinkey}{data}; $curdata =~ s/\n/ /g;
      my $curwho = $curdata{$datatype}{$joinkey}{curator};
      if ($cfp{$datatype}{$joinkey}{data}) {
        my $cfp = $cfp{$datatype}{$joinkey}{data}; $cfp =~ s/\n/ /g;
        my $cfpwho = $cfp{$datatype}{$joinkey}{curator};
# curdata negative
        if ($curdata eq 'negative') { print qq($datatype\t$joinkey\t($curwho) $curdata\t($cfpwho) $cfp\n); }
# different curator
#         if ($curwho ne $cfpwho) { print qq($datatype\t$joinkey\t($curwho) $curdata\t($cfpwho) $cfp\n); }
# same curator
#         if ($curwho eq $cfpwho) { print qq($datatype\t$joinkey\t($curwho) $curdata\t($cfpwho) $cfp\n); }
  } } }
}

sub readCurdata {
  $result = $dbh->prepare( "SELECT * FROM cur_curdata WHERE cur_site = 'caltech'" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    $curdata{$row[1]}{$row[0]}{data} = $row[4];
    $curdata{$row[1]}{$row[0]}{curator} = $row[3];
    $curdata{$row[1]}{$row[0]}{timestamp} = $row[7];
} }

sub readCfp {
  foreach my $datatype (sort keys %datatypesAfpCfp) {
    $result = $dbh->prepare( "SELECT * FROM cfp_$datatypesAfpCfp{$datatype}" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) {
      $cfp{$datatype}{$row[0]}{data} = $row[1];
      $cfp{$datatype}{$row[0]}{curator} = $row[2];
      $cfp{$datatype}{$row[0]}{timestamp} = $row[3];
#       my $row = join"\t", @row;
#       print qq($datatype\tcfp_$datatypesAfpCfp{$datatype}\t$row\n);
} } }


# find empty cfp_ tables
sub findEmptyCfpData {
  my @pgcommands;
  foreach my $datatype (sort keys %datatypesAfpCfp) {
  #   $result = $dbh->prepare( "SELECT * FROM cfp_$datatypesAfpCfp{$datatype} WHERE cfp_$datatypesAfpCfp{$datatype} IS NULL OR cfp_$datatypesAfpCfp{$datatype} = ''" );
    $result = $dbh->prepare( "SELECT * FROM cfp_$datatypesAfpCfp{$datatype} WHERE cfp_$datatypesAfpCfp{$datatype} IS NULL OR cfp_$datatypesAfpCfp{$datatype} !~ '[a-zA-Z]'" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) {
      my $row = join"\t", @row;
      print qq($datatype\tcfp_$datatypesAfpCfp{$datatype}\t$row\n);
      push @pgcommands, qq(DELETE FROM cfp_$datatypesAfpCfp{$datatype} WHERE joinkey = '$row[0]' AND cfp_curator = '$row[2]';);
      push @pgcommands, qq(DELETE FROM cfp_$datatypesAfpCfp{$datatype}_hst WHERE joinkey = '$row[0]' AND cfp_curator = '$row[2]';);
    }
  }
  foreach my $pgcommand (@pgcommands) {
    print qq($pgcommand\n);
# UNCOMMENT TO POPULATE
#     $dbh->do($pgcommand);
  }
} # sub findEmtpyCfp

sub findEmptyCfpCurator {
  foreach my $datatype (sort keys %datatypesAfpCfp) {
    next if ($datatype eq 'catalyticact');
    next if ($datatype eq 'chemphen');
    next if ($datatype eq 'envpheno');
    next if ($datatype eq 'rnaseq');
#     print qq( SELECT * FROM cfp_$datatypesAfpCfp{$datatype} WHERE cfp_curator IS NULL OR cfp_curator !~ '[a-zA-Z]'\n);
    $result = $dbh->prepare( "SELECT * FROM cfp_$datatypesAfpCfp{$datatype} WHERE cfp_curator IS NULL OR cfp_curator !~ '[a-zA-Z]'" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) {
      my $row = join"\t", @row;
      print qq($datatype\tcfp_$datatypesAfpCfp{$datatype}\t$row\n);
    }
  }
} # sub findEmtpyCfp


sub populateDatatypes {
#   $result = $dbh->prepare( "SELECT DISTINCT(cur_datatype) FROM cur_svmdata" );        # switch from svm to nnc 2021 01 25
  $result = $dbh->prepare( "SELECT DISTINCT(cur_datatype) FROM cur_nncdata" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) { $datatypesAfpCfp{$row[0]} = $row[0]; }
  $datatypesAfpCfp{'chemicals'}     = 'chemicals';              # added for Karen 2013 10 02
  $datatypesAfpCfp{'blastomere'}    = 'cellfunc';
  $datatypesAfpCfp{'exprmosaic'}    = 'siteaction';
  $datatypesAfpCfp{'geneticmosaic'} = 'mosaic';
  $datatypesAfpCfp{'laserablation'} = 'ablationdata';
  $datatypesAfpCfp{'humandisease'}  = 'humdis';                 # added mapping to correct table 2018 05 17
  $datatypesAfpCfp{'rnaseq'}        = 'rnaseq';                 # for new afp form 2018 10 31
  $datatypesAfpCfp{'chemphen'}      = 'chemphen';               # for new afp form 2018 10 31
  $datatypesAfpCfp{'envpheno'}      = 'envpheno';               # for new afp form 2018 10 31
  $datatypesAfpCfp{'timeaction'}    = 'timeaction';             # for new afp form 2018 11 13
  $datatypesAfpCfp{'siteaction'}    = 'siteaction';             # for new afp form 2018 11 13
  foreach my $datatype (keys %datatypesAfpCfp) { $datatypes{$datatype}++; }
  $datatypes{'geneticablation'}++;
  $datatypes{'picture'}++;                      # for Daniela's pictures
  $datatypes{'optogenetic'}++;                  # for Raymond's anatomy but without afp / cfp
#   $datatypes{'rnaseq'}++;                     # for Kimberly Parasite  2016 07 12
#   $datatypes{'proteomics'}++;                 # for Kimberly Parasite  2016 07 12
#   $datatypes{'variants'}++;                   # for Kimberly Parasite  2016 07 12
#   delete $datatypesAfpCfp{'catalyticact'};    # has svm but no afp / cfp      # afp got added, so cfp table also created.  2018 11 07
  delete $datatypesAfpCfp{'expression_cluster'};        # has svm but no afp / cfp      # should have been removed 2017 07 08, fixed 2017 08 04
  delete $datatypesAfpCfp{'genesymbol'};                # has svm but no afp / cfp      # added 2021 01 25
  delete $datatypesAfpCfp{'transporter'};               # has svm but no afp / cfp      # added 2021 01 25
  $result = $dbh->prepare( "SELECT DISTINCT(cur_datatype) FROM cur_strdata" );  # from string search data
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) { $datatypes{$row[0]} = $row[0]; }
} # sub populateDatatypes

sub populatePremadeComments {
  $premadeComments{"1"}  = "SVM Positive, Curation Negative";
  $premadeComments{"2"}  = "C. elegans as heterologous expression system";
  $premadeComments{"3"}  = "Curated for GO (by WB)";
  $premadeComments{"4"}  = "Curated for GO (by GOA)";
  $premadeComments{"5"}  = "Curated for GO (by IntAct)";
  $premadeComments{"6"}  = "Curated for BioGRID (by WB)";
  $premadeComments{"7"}  = "Curated for BioGRID (by BG)";
  $premadeComments{"8"}  = "Curated for GO (by WB), Curated for BioGRID (by WB)";
  $premadeComments{"9"}  = "Curated for GO (by WB), Curated for BioGRID (by BG)";
  $premadeComments{"10"} = "Curated for GO (by GOA), Curated for BioGRID (by WB)";
  $premadeComments{"11"} = "Curated for GO (by GOA), Curated for BioGRID (by BG)";
  $premadeComments{"12"} = "Curated for GO (by IntAct), Curated for BioGRID (by WB)";
  $premadeComments{"13"} = "Curated for GO (by IntAct), Curated for BioGRID (by BG)";
  $premadeComments{"14"} = "Curation Negative, no Strain name given in paper";
#   $premadeComments{"15"} = "No disease models";       # removed for Ranjana and removed from postgres.  2021 03 16
  $premadeComments{"15"} = "Toxicology";
  $premadeComments{"16"} = "Host-pathogen/virulence";
  $premadeComments{"17"} = "Disease model";
  $premadeComments{"18"} = "Non-genetic disease model";
  $premadeComments{"19"} = "Genetic disease model";
} # sub populatePremadeComments

__END__

my %manually;
$result = $dbh->prepare( "SELECT * FROM pap_species WHERE pap_evidence ~ 'Manually_connected'" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    my $key = $row[0] . '\t' . $row[1];
    $manually{$key}++;
  } # if ($row[0])
} # while (@row = $result->fetchrow)

my %confirmed;
$result = $dbh->prepare( "SELECT * FROM pap_species WHERE pap_evidence ~ 'Curator_confirmed'" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    my $key = $row[0] . '\t' . $row[1];
    unless ($manually{$key}) {
      print qq($key\n);
    }
  } # if ($row[0])
} # while (@row = $result->fetchrow)

