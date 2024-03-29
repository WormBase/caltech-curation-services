#!/usr/bin/perl -w

# generate topic entity classifiers for Kimberly for ABC  https://agr-jira.atlassian.net/browse/SCRUM-2664  2023 06 09

use strict;
use diagnostics;
use DBI;
use JSON;
use Encode qw( from_to is_utf8 );

use constant FALSE => \0;
use constant TRUE => \1;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

# my @wbpapers = qw( 00004952 00005199 00026609 00030933 00035427 );
# my @wbpapers = qw( 00004952 00005199 00046571 00057043 00064676 );
# my @wbpapers = qw( 00046571 );
# my @wbpapers = qw( 00005199 );
my @wbpapers = qw( 00057043 );

my %wbpToAgr;
$wbpToAgr{'00004952'} = 'AGRKB:101000000618370';
$wbpToAgr{'00005199'} = 'AGRKB:101000000618566';
$wbpToAgr{'00026609'} = 'AGRKB:101000000620861';
$wbpToAgr{'00030933'} = 'AGRKB:101000000622619';
$wbpToAgr{'00035427'} = 'AGRKB:101000000624596';
$wbpToAgr{'00046571'} = 'AGRKB:101000000630958';
$wbpToAgr{'00057043'} = 'AGRKB:101000000390100';
$wbpToAgr{'00064676'} = 'AGRKB:101000000947815';

my %speciesToTaxon;
$result = $dbh->prepare( "SELECT * FROM obo_name_ncbitaxonid WHERE joinkey IN (SELECT DISTINCT(pap_species) FROM pap_species) " );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) { $speciesToTaxon{$row[1]} = $row[0]; }

my %datatypesAfpCfp;
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
#   delete $datatypesAfpCfp{'catalyticact'};    # has svm but no afp / cfp      # afp got added, so cfp table also created.  2018 11 07
delete $datatypesAfpCfp{'expression_cluster'};        # has svm but no afp / cfp      # should have been removed 2017 07 08, fixed 2017 08 04
delete $datatypesAfpCfp{'genesymbol'};                # has svm but no afp / cfp      # added 2021 01 25
delete $datatypesAfpCfp{'transporter'};               # has svm but no afp / cfp      # added 2021 01 25

my %datatypes;
$datatypes{'blastomere'}         = 'ATP:0000143';
$datatypes{'catalyticact'}       = 'ATP:0000061';
$datatypes{'chemphen'}           = 'ATP:0000080';
$datatypes{'envphen'}            = 'ATP:0000080';
# $datatypes{'expression_cluster'} = 'no atp, skip';
$datatypes{'expmosaic'}          = 'ATP:0000034';
$datatypes{'geneint'}            = 'ATP:0000068';
$datatypes{'geneprod'}           = 'ATP:0000069';
$datatypes{'genereg'}            = 'ATP:0000024';
$datatypes{'genesymbol'}         = 'ATP:0000048';
$datatypes{'geneticablation'}    = 'ATP:0000032';
$datatypes{'geneticmosaic'}      = 'ATP:0000034';
$datatypes{'humandisease'}       = 'ATP:0000111';
$datatypes{'laserablation'}      = 'ATP:0000032';
$datatypes{'newmutant'}          = 'ATP:0000083';
$datatypes{'optogenet'}          = 'ATP:0000145';
$datatypes{'otherexpr'}          = 'ATP:0000041';
$datatypes{'overexpr'}           = 'ATP:0000084';
# $datatypes{'picture'}            = 'no atp, skip';
$datatypes{'rnai'}               = 'ATP:0000082';
$datatypes{'rnaseq'}             = 'ATP:0000146';
# $datatypes{'seqchange'}          = 'no atp, skip';
$datatypes{'siteaction'}         = 'ATP:0000033';
# $datatypes{'strain'}             = 'ATP:0000027     not in WB';
$datatypes{'structcorr'}         = 'ATP:0000054';
# $datatypes{'timeaction'}         = 'no atp, skip';
$datatypes{'transporter'}        = 'ATP:0000062';

my %entitytypes;
$entitytypes{'species'}          = 'ATP:0000123';
$entitytypes{'gene'}             = 'ATP:0000047';
$entitytypes{'variation'}        = 'ATP:0000030';
$entitytypes{'transgene'}        = 'ATP:0000099';
$entitytypes{'chemical'}         = 'ATP:0000094';
$entitytypes{'antibody'}         = 'ATP:0000096';

# my @topic_types = qw( nnc svm afp cfp 
# my %exists;
# foreach my $datatype (sort keys %datatypes) {

my %confidence_to_atp;
$confidence_to_atp{'high'} = 'ATP:0000119';
$confidence_to_atp{'medium'} = 'ATP:0000120';
$confidence_to_atp{'low'} = 'ATP:0000121';
$confidence_to_atp{'neg'} = undef;

my %curdata_to_validated;
$curdata_to_validated{'curated'} = TRUE;
$curdata_to_validated{'positive'} = TRUE;
$curdata_to_validated{'negative'} = FALSE;
$curdata_to_validated{'notvalidated'} = undef;

my %geneToTaxon;
my %varToTaxon;

# Kimberly, we have the same source ECO for different flagging sources, and I don't think we can do that, so tacking on _nnc or whatever for now.  created_by is not an option for source in the API, so we'll need to talk to Valerio about how to enter that and whether we need to.  Only antibody has string data.  What's something that's flagged as negative from ACKnowledge/afp/cfp ?  I thought everything with a value was considered positive.  The curation status form looks whether there's a cfp_curator for a paper, and considers that flagged, then if a datatype for that paper has data it's positive, and if it doesn't it's negative, for the purposes for the big table where you can see percentages, but it's not really true negative data, it's extrapolated, and it can be wrong if a paper was flagged before a datatype was added to the flagging form (made up example: if a paper was flagged in 2005 and blastomeres were added to the form in 2015).  Do you want actual positive data only, or extrapolated negatives too.  If there's a value that the forms use that means negative, we can get that.

foreach my $joinkey (@wbpapers) {
  # topics
# UNCOMMENT THIS LATER
#   foreach my $datatype (sort keys %datatypes) {
#     my %object;
#     my $topic = $datatypes{$datatype};
#     my $source = 'ECO:0000000';
#     my $reference_curie = $wbpToAgr{$joinkey};
#     $object{'reference_curie'} = $wbpToAgr{$joinkey};
#     $object{'topic'} = $datatypes{$datatype};
#     if ($datatypesAfpCfp{$datatype}) {
#       $result = $dbh->prepare( "SELECT * FROM cfp_$datatypesAfpCfp{$datatype} WHERE joinkey = '$joinkey'" );
#       $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
#       while (my @row = $result->fetchrow) {
#         if ($row[0]) { 
#           my %source;
#           $source{'source'} = $source . '_cfp';
#           $source{'confidence_level'} = undef;
#           $source{'validation_type'} = 'manual';
#           $source{'validated'} = TRUE;	# not sure we can extrapolate false if cfp_curator but not cfp_$datatype
#           $source{'note'} = $row[1];
#           $source{'mod_abbreviation'} = 'WB';
#           push @{ $object{'sources'} }, \%source;
#           print qq(cfp $datatype $row[0] $row[1]\n);
#         } # if ($row[0])
#       } # while (@row = $result->fetchrow)
#       $result = $dbh->prepare( "SELECT * FROM afp_$datatypesAfpCfp{$datatype} WHERE joinkey = '$joinkey'" );
#       $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
#       while (my @row = $result->fetchrow) {
#         if ($row[0]) { 
#           my %source;
#           $source{'source'} = $source . '_afp';
#           $source{'confidence_level'} = undef;
#           $source{'validation_type'} = 'manual';
#           $source{'validated'} = TRUE;	# not sure we can extrapolate false if afp_curator but not afp_$datatype
#           $source{'note'} = $row[1];
#           $source{'mod_abbreviation'} = 'WB';
#           push @{ $object{'sources'} }, \%source;
#           print qq(afp $datatype $row[0] $row[1]\n);
#         } # if ($row[0])
#       } # while (@row = $result->fetchrow)
#     } # if ($datatypesAfpCfp{$datatype})
#     $result = $dbh->prepare( "SELECT * FROM cur_curdata WHERE cur_datatype = '$datatype' AND cur_paper = '$joinkey'" );
#     $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
#     while (my @row = $result->fetchrow) {
#       if ($row[0]) { 
#         my %source;
#         $source{'source'} = $source . '_cur';
#         $source{'confidence_level'} = undef;
#         $source{'validation_type'} = 'manual';
#         $source{'validated'} = $curdata_to_validated{$row[4]};
#         if ($row[6]) { $source{'note'} = $row[6]; }
#           else { $source{'note'} = undef; }
#         $source{'mod_abbreviation'} = 'WB';
#         push @{ $object{'sources'} }, \%source;
#         print qq(cur $datatype $row[0] $row[4]\n);
#       } # if ($row[0])
#     } # while (@row = $result->fetchrow)
#     $result = $dbh->prepare( "SELECT * FROM cur_svmdata WHERE cur_datatype = '$datatype' AND cur_paper = '$joinkey'" );
#     $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
#     while (my @row = $result->fetchrow) {
#       if ($row[0]) { 
#         my %source;
#         $source{'source'} = $source . '_svm';
#         $source{'confidence_level'} = $confidence_to_atp{lc($row[3])};
# # This might be wrong, check Valerio/Kimberly
# #         $source{'validation_type'} = undef;
# #         $source{'validated'} = undef;
#         $source{'validation_type'} = 'svm';
#         $source{'validated'} = FALSE;
#         $source{'note'} = undef;
#         $source{'mod_abbreviation'} = 'WB';
#         push @{ $object{'sources'} }, \%source;
#         print qq(svm $datatype $row[0] $row[3]\n);
#       } # if ($row[0])
#     } # while (@row = $result->fetchrow)
#     $result = $dbh->prepare( "SELECT * FROM cur_nncdata WHERE cur_datatype = '$datatype' AND cur_paper = '$joinkey'" );
#     $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
#     while (my @row = $result->fetchrow) {
#       if ($row[0]) { 
#         my %source;
#         $source{'source'} = $source . '_nnc';
#         $source{'confidence_level'} = $confidence_to_atp{lc($row[3])};
# # This might be wrong, check Valerio/Kimberly
# #         $source{'validation_type'} = undef;
# #         $source{'validated'} = undef;
#         $source{'validation_type'} = 'nnc';
#         $source{'validated'} = FALSE;
#         $source{'note'} = undef;
#         $source{'mod_abbreviation'} = 'WB';
#         push @{ $object{'sources'} }, \%source;
#         print qq(nnc $datatype $row[0] $row[3]\n);
#       } # if ($row[0])
#     } # while (@row = $result->fetchrow)
#     if ($object{'sources'} && (scalar @{ $object{'sources'} } > 0)) {
#       my $json = encode_json \%object;
#       print qq($json\n); }
#   } # foreach my $datatype (sort keys %datatypes)

# my %entitytypes;
# $entitytypes{'species'}          = 'ATP:0000123';
# $entitytypes{'gene'}             = 'ATP:0000047';
# $entitytypes{'variation'}        = 'ATP:0000030';
# $entitytypes{'transgene'}        = 'ATP:0000099';
# $entitytypes{'chemical'}         = 'ATP:0000094';
# $entitytypes{'antibody'}         = 'ATP:0000096';
  # entities

#     my %object;
#     my $topic = 'ATP:0000142';
#     my $source = 'ECO:0000000';
#     my $reference_curie = $wbpToAgr{$joinkey};
#     $object{'reference_curie'} = $reference_curie;
#     $object{'topic'} = $topic;
#     $object{'entity_source'} = 'alliance';

    # TO FIX different rows in postgres could have the same paper-gene but different pap_evidence, each of which will create a source with the same data, which ABC won't allow
    # duplicate key value violates unique constraint \"source_topic_entity_tag_unique\"\nDETAIL:  Key (topic_entity_tag_id, mod_id, source)=(232, 2, ECO:0000000_pap_species) already exists.

    # TODO  extract tfp_species, map its data to a taxon and if joinkey+taxon match, create a source
    my %agr_species;
    $result = $dbh->prepare( "SELECT * FROM pap_species WHERE joinkey = '$joinkey'" );
    print qq( SELECT * FROM pap_species WHERE joinkey = '$joinkey';\n );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) {
      if ($row[0]) { 
        print qq(ROW @row\n);
        my $entity = 'NCBITaxon:' . $row[1];
        # my $entity_type = $entitytypes{'species'};
        # my $species = 'NCBITaxon:' . $row[1];
        # my $negated = FALSE;
        my %source = ();
        $source{'mod_abbreviation'} = 'WB';
        $source{'confidence_level'} = undef;
        if ($row[5]) {
          if ($row[5] =~ m/Curator_confirmed.*(WBPerson\d+)/) {
            # $source{'created_by'} = $1;
            # $source{'date_created'} = $row[4];
            # $source{'eco_source'} = 'ECO:0000302';
            # $source{'source_detail'} = undef;
            $source{'source'} = 'curator';
            $source{'negated'} = FALSE;
            # push @{ $object{'sources'} }, \%source;
            push @{ $agr_species{$entity} }, \%source;
          }
          elsif ($row[5] =~ m/Inferred_automatically/) {
            # $source{'created_by'} = $1;	# get from afp_contributor, loop separate source for each two#
            # $source{'date_created'} = $row[4];
            # $source{'eco_source'} = 'ECO:0000302';
            # $source{'source_detail'} = 'ACKnowledge';
            $source{'source'} = 'author';
            $source{'negated'} = FALSE;
            # push @{ $object{'sources'} }, \%source;
            push @{ $agr_species{$entity} }, \%source;
          }
          elsif ($row[5] eq '') {
            print qq(NO EVI\n);
            # $source{'created_by'} = ???
            # $source{'date_created'} = $row[4];
            # $source{'eco_source'} = 'ECO:0007669';
            # $source{'source_detail'} = 'string match to title, abstract, and gene-species association';
            $source{'source'} = 'caltech script';
            $source{'negated'} = FALSE;
            # push @{ $object{'sources'} }, \%source;
            push @{ $agr_species{$entity} }, \%source;
    } } } }
    foreach my $entity (sort keys %agr_species) {
      my %object;
      my $topic = 'ATP:0000142';
      my $source = 'ECO:0000000';
      my $reference_curie = $wbpToAgr{$joinkey};
      $object{'reference_curie'} = $reference_curie;
      $object{'topic'} = $topic;
      $object{'entity_source'} = 'alliance';
      $object{'entity'} = $entity;
      $object{'entity_type'} = $entitytypes{'species'};
      $object{'species'} = $entity;
      if ($agr_species{$entity} && (scalar @{ $agr_species{$entity} } > 0)) {
        foreach my $source_href (@{ $agr_species{$entity} }) {
          push @{ $object{'sources'} }, $source_href; }
        my $json = encode_json \%object;
        print qq($json\n);
        # $object{'sources'} = ();
        # print qq(PAP_SPECIES\t);
    } }

#     $result = $dbh->prepare( "SELECT * FROM pap_species WHERE joinkey = '$joinkey'" );
#     print qq( SELECT * FROM pap_species WHERE joinkey = '$joinkey';\n );
#     $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
#     while (my @row = $result->fetchrow) {
#       if ($row[0]) { 
#         print qq(ROW @row\n);
#         $object{'entity'} = 'NCBITaxon:' . $row[1];
#         $object{'entity_type'} = $entitytypes{'species'};
#         $object{'species'} = 'NCBITaxon:' . $row[1];
#         my %source = ();
#         $source{'mod_abbreviation'} = 'WB';
#         $source{'confidence_level'} = undef;
#         if ($row[5]) {
#           if ($row[5] =~ m/Curator_confirmed.*(WBPerson\d+)/) {
#             # $source{'created_by'} = $1;
#             # $source{'date_created'} = $row[4];
#             # $source{'eco_source'} = 'ECO:0000302';
#             # $source{'source_detail'} = undef;
#             $source{'source'} = 'curator';
#             $source{'negated'} = FALSE;
#             push @{ $object{'sources'} }, \%source; }
#           elsif ($row[5] =~ m/Inferred_automatically/) {
#             # $source{'created_by'} = $1;	# get from afp_contributor, loop separate source for each two#
#             # $source{'date_created'} = $row[4];
#             # $source{'eco_source'} = 'ECO:0000302';
#             # $source{'source_detail'} = 'ACKnowledge';
#             $source{'source'} = 'author';
#             $source{'negated'} = FALSE;
#             push @{ $object{'sources'} }, \%source; }
#           elsif ($row[5] eq '') {
#             print qq(NO EVI\n);
#             # $source{'created_by'} = ???
#             # $source{'date_created'} = $row[4];
#             # $source{'eco_source'} = 'ECO:0007669';
#             # $source{'source_detail'} = 'string match to title, abstract, and gene-species association';
#             $source{'source'} = 'caltech script';
#             $source{'negated'} = FALSE;
#             push @{ $object{'sources'} }, \%source; }
#         }
            
        
#         $source{'source'} = $source . '_pap_species';
#         $source{'confidence_level'} = undef;
#         $source{'validation_type'} = undef;
#         $source{'validated'} = FALSE;
#         $source{'note'} = undef;
#         if ($row[5]) {
#           $source{'validation_type'} = 'manual';
#           $source{'validated'} = TRUE; }
#         push @{ $object{'sources'} }, \%source;

#         my $json = encode_json \%object;
#         $object{'sources'} = ();
#         # print qq(PAP_SPECIES\t);
#         print qq($json\n);
#     } }

# PUT THIS BACK
#     $result = $dbh->prepare( "SELECT * FROM pap_gene WHERE joinkey = '$joinkey'" );
#     $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
#     while (my @row = $result->fetchrow) {
#       if ($row[0]) { 
#         my $gene = 'WB:WBGene' . $row[1];
#         my $taxon = '';
#         if ($geneToTaxon{$row[1]}) { $taxon = $geneToTaxon{$row[1]}; }
#           else {
#             my $result2 = $dbh->prepare( "SELECT * FROM gin_species WHERE joinkey = '$row[1]'" );
#             $result2->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
#             my @row2 = $result2->fetchrow();
#             my $species = $row2[1];
#             $geneToTaxon{$row[1]} = 'NCBITaxon:' . $speciesToTaxon{$species};
#             $taxon = 'NCBITaxon:' . $speciesToTaxon{$species}; }
#         $object{'entity'} = $gene;
#         $object{'entity_type'} = $entitytypes{'gene'};
#         $object{'species'} = $taxon;
#         my %source = ();
#         $source{'source'} = $source . '_pap_gene';
#         $source{'confidence_level'} = undef;
#         $source{'validation_type'} = undef;
#         $source{'validated'} = FALSE;
#         $source{'note'} = undef;
#         if ($row[5]) {
#           my $source = 'ECO:0008008';
#           if ( ($row[5] =~ m/Manually_connected/) || ($row[5] =~ m/Published_as/) || ($row[5] =~ m/Person_evidence/) ||
#                ($row[5] =~ m/Curator_confirmed/) || ($row[5] =~ m/Author_evidence/) ) { $source = 'manual'; }
#             elsif ( $row[5] =~ m/Inferred_automatically/) {
#               if ( ($row[5] =~ m/from curator first pass/) || ($row[5] =~ m/from author first pass/) ) { $source = 'manual'; } }
#           if ($source eq 'manual') {
#             $source{'validation_type'} = 'manual';
#             $source{'validated'} = TRUE; }
#           else {
#             $source{'source'} = $source; } }
#         $source{'mod_abbreviation'} = 'WB';
#         push @{ $object{'sources'} }, \%source;
#         my $json = encode_json \%object;
#         $object{'sources'} = ();
#         print qq(PAP_GENE\t);
#         print qq($json\n);
#     } }
# 
#     $result = $dbh->prepare( "SELECT * FROM afp_variation WHERE joinkey = '$joinkey'" );
#     $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
#     while (my @row = $result->fetchrow) {
#       if ($row[0]) { 
#         my (@wbvar) = $row[1] =~ m/(WBVar\d+)/;
#         foreach my $wbvar (@wbvar) {
#           my $taxon = '';
#           if ($varToTaxon{$row[1]}) { $taxon = $varToTaxon{$row[1]}; }
#             else {
#               my $result2 = $dbh->prepare( "SELECT * FROM obo_data_variation WHERE joinkey = '$row[1]'" );
#               $result2->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
#               my @row2 = $result2->fetchrow();
#               my ($species) = $row2[1] =~ m/species: "(.*)"/;
#               $varToTaxon{$row[1]} = 'NCBITaxon:' . $speciesToTaxon{$species};
#               $taxon = 'NCBITaxon:' . $speciesToTaxon{$species}; }
#           $object{'entity'} = 'WB:' . $wbvar;
#           $object{'entity_type'} = $entitytypes{'variation'};
#           $object{'species'} = $taxon;
#     } } }
} # foreach my $joinkey (@wbpapers)


__END__

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb;host=131.215.52.76", "", "") or die "Cannot connect to database!\n";	# for remote access

my $result = $dbh->prepare( 'SELECT * FROM two_comment WHERE two_comment ~ ?' );
$result->execute('elegans') or die "Cannot prepare statement: $DBI::errstr\n"; 

$result->execute("doesn't") or die "Cannot prepare statement: $DBI::errstr\n"; 
my $var = "doesn't";
$result->execute($var) or die "Cannot prepare statement: $DBI::errstr\n"; 

my $data = 'data';
unless (is_utf8($data)) { from_to($data, "iso-8859-1", "utf8"); }

my $result = $dbh->do( "DELETE FROM friend WHERE firstname = 'bl\"ah'" );
(also do for INSERT and UPDATE if don't have a variable to interpolate with ? )

can cache prepared SELECTs with $dbh->prepare_cached( &c. );

if ($result->rows == 0) { print "No names matched.\n\n"; }	# test if no return

$result->finish;	# allow reinitializing of statement handle (done with query)
$dbh->disconnect;	# disconnect from DB

http://209.85.173.132/search?q=cache:5CFTbTlhBGMJ:www.perl.com/pub/1999/10/DBI.html+dbi+prepare+execute&cd=4&hl=en&ct=clnk&gl=us

interval stuff : 
SELECT * FROM afp_passwd WHERE joinkey NOT IN (SELECT joinkey FROM afp_lasttouched) AND joinkey NOT IN (SELECT joinkey FROM cfp_curator) AND afp_timestamp < CURRENT_TIMESTAMP - interval '21 days' AND afp_timestamp > CURRENT_TIMESTAMP - interval '28 days';

casting stuff to substring on other types :
SELECT * FROM afp_passwd WHERE CAST (afp_timestamp AS TEXT) ~ '2009-05-14';

to concatenate string to query result :
  SELECT 'WBPaper' || joinkey FROM pap_identifier WHERE pap_identifier ~ 'pmid';
to get :
  SELECT DISTINCT(gop_paper_evidence) FROM gop_paper_evidence WHERE gop_paper_evidence NOT IN (SELECT 'WBPaper' || joinkey FROM pap_identifier WHERE pap_identifier ~ 'pmid') AND gop_paper_evidence != '';

