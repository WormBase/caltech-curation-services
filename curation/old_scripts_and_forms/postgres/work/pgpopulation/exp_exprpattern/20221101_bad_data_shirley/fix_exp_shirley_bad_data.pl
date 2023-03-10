#!/usr/bin/perl -w

# Shirley (grad student) messed up data on 2022 10 26, get dump of anything that's changed since then
# in exp_ tables and give to Daniela to manually fix.  Also generate files to dump postgres tables
# from mangolassi after loading the dump  backup_testdb.dump.202210260200  Then test loading them, 
# and if Daniela approves, load them on tazendra.  2022 11 01

# psql -e testdb < copy_dump_pg
# psql -e testdb < drop_load_pg


use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

# $result = $dbh->prepare( "SELECT * FROM two_comment" );
# $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
# while (my @row = $result->fetchrow) {
#   if ($row[0]) { 
#     $row[0] =~ s///g;
#     $row[1] =~ s///g;
#     $row[2] =~ s///g;
#     print "$row[0]\t$row[1]\t$row[2]\n";
#   } # if ($row[0])
# } # while (@row = $result->fetchrow)

my %fields;

&initWormExpFields();
# my ($fieldsRef, $datatypesRef) = &initWormExpFields();
# print qq($fieldsRef);
# my %fields = %$fieldsRef{'exp'};

my $directory = '/home/postgres/work/pgpopulation/exp_exprpattern/20221101_bad_data_shirley/pg_backup/';
foreach my $field (sort keys $fields{exp}) {
  next if ($field eq 'id');
#   print qq(F $field\n);
#   $result = $dbh->prepare( "SELECT * FROM exp_${field}_hst WHERE exp_timestamp > '2022-10-26 02:00:00'" );
  $result = $dbh->prepare( "SELECT * FROM exp_${field} WHERE exp_timestamp > '2022-10-26 02:00:00'" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    if ($row[0]) { 
      $row[0] =~ s///g;
      $row[1] =~ s///g;
      $row[2] =~ s///g;
      print "$field\t$row[0]\t$row[1]\t$row[2]\n";
    } # if ($row[0])
  } # while (@row = $result->fetchrow)

#   print qq(DELETE FROM exp_${field};\n);
#   print qq(DELETE FROM exp_${field}_hst;\n);
#   print qq(COPY exp_${field} FROM '${directory}exp_${field}.pg';\n);
#   print qq(COPY exp_${field}_hst FROM '${directory}exp_${field}_hst.pg';\n);
#   print qq(COPY exp_${field} TO '${directory}exp_${field}.pg';\n);
#   print qq(COPY exp_${field}_hst TO '${directory}exp_${field}_hst.pg';\n);
}



sub initWormExpFields {
#   my ($datatype, $curator_two) = @_;
#   my %fields; my %datatypes;
#   tie %{ $fields{exp} }, "Tie::IxHash";
  $fields{exp}{id}{type}                             = 'text';
  $fields{exp}{id}{label}                            = 'pgid';
  $fields{exp}{id}{tab}                              = 'tab1';
  $fields{exp}{name}{type}                           = 'text';
  $fields{exp}{name}{label}                          = 'Expr Pattern';
  $fields{exp}{name}{tab}                            = 'tab1';
  $fields{exp}{paper}{type}                          = 'multiontology';
  $fields{exp}{paper}{label}                         = 'Reference';
  $fields{exp}{paper}{tab}                           = 'tab1';
  $fields{exp}{paper}{ontology_type}                 = 'WBPaper';
  $fields{exp}{person}{type}                         = 'multiontology';
  $fields{exp}{person}{label}                        = 'Person';
  $fields{exp}{person}{tab}                          = 'tab1';
  $fields{exp}{person}{ontology_type}                = 'WBPerson';
  $fields{exp}{gene}{type}                           = 'multiontology';
  $fields{exp}{gene}{label}                          = 'Gene';
  $fields{exp}{gene}{tab}                            = 'tab1';
  $fields{exp}{gene}{ontology_type}                  = 'WBGene';
  $fields{exp}{endogenous}{type}                     = 'toggle';
  $fields{exp}{endogenous}{label}                    = 'Endogenous';
  $fields{exp}{endogenous}{tab}                      = 'tab1';
  $fields{exp}{relanatomy}{type}                     = 'dropdown';
  $fields{exp}{relanatomy}{label}                    = 'Rel Anatomy';
  $fields{exp}{relanatomy}{tab}                      = 'tab1';
  $fields{exp}{relanatomy}{dropdown_type}            = 'relanatomy';
  $fields{exp}{anatomy}{type}                        = 'multiontology';
  $fields{exp}{anatomy}{label}                       = 'Anatomy';
  $fields{exp}{anatomy}{tab}                         = 'tab1';
  $fields{exp}{anatomy}{ontology_type}               = 'obo';
  $fields{exp}{anatomy}{ontology_table}              = 'anatomy';
  $fields{exp}{qualifier}{type}                      = 'dropdown';
  $fields{exp}{qualifier}{label}                     = 'Qualifier';
  $fields{exp}{qualifier}{tab}                       = 'tab1';
  $fields{exp}{qualifier}{dropdown_type}             = 'exprqualifier';
  $fields{exp}{qualifiertext}{type}                  = 'bigtext';
  $fields{exp}{qualifiertext}{label}                 = 'Qualifier Text';
  $fields{exp}{qualifiertext}{tab}                   = 'tab1';
  $fields{exp}{qualifierls}{type}                    = 'multiontology';
  $fields{exp}{qualifierls}{label}                   = 'Qualifier LS';
  $fields{exp}{qualifierls}{tab}                     = 'tab1';
  $fields{exp}{qualifierls}{ontology_type}           = 'obo';
  $fields{exp}{qualifierls}{ontology_table}          = 'lifestage';
  $fields{exp}{goid}{type}                           = 'multiontology';
  $fields{exp}{goid}{label}                          = 'GO Term';
  $fields{exp}{goid}{tab}                            = 'tab1';
  $fields{exp}{goid}{ontology_type}                  = 'obo';
  $fields{exp}{goid}{ontology_table}                 = 'goid';
  $fields{exp}{granatomy}{type}                      = 'multiontology';
  $fields{exp}{granatomy}{label}                     = 'GR Anatomy';
  $fields{exp}{granatomy}{tab}                       = 'tab1';
  $fields{exp}{granatomy}{ontology_type}             = 'obo';
  $fields{exp}{granatomy}{ontology_table}            = 'anatomy';
  $fields{exp}{rellifestage}{type}                   = 'dropdown';
  $fields{exp}{rellifestage}{label}                  = 'Rel Life Stage';
  $fields{exp}{rellifestage}{tab}                    = 'tab1';
  $fields{exp}{rellifestage}{dropdown_type}          = 'rellifestage';
  $fields{exp}{grlifestage}{type}                    = 'multiontology';
  $fields{exp}{grlifestage}{label}                   = 'GR LS';
  $fields{exp}{grlifestage}{tab}                     = 'tab1';
  $fields{exp}{grlifestage}{ontology_type}           = 'obo';
  $fields{exp}{grlifestage}{ontology_table}          = 'lifestage';
  $fields{exp}{relcellcycle}{type}                   = 'dropdown';
  $fields{exp}{relcellcycle}{label}                  = 'Rel Cell Cycle';
  $fields{exp}{relcellcycle}{tab}                    = 'tab1';
  $fields{exp}{relcellcycle}{dropdown_type}          = 'relcellcycle';
  $fields{exp}{grcellcycle}{type}                    = 'multiontology';
  $fields{exp}{grcellcycle}{label}                   = 'GR Cell Cycle';
  $fields{exp}{grcellcycle}{tab}                     = 'tab1';
  $fields{exp}{grcellcycle}{ontology_type}           = 'obo';
  $fields{exp}{grcellcycle}{ontology_table}          = 'goid';
  $fields{exp}{subcellloc}{type}                     = 'bigtext';
  $fields{exp}{subcellloc}{label}                    = 'Subcellular Localization';
  $fields{exp}{subcellloc}{tab}                      = 'tab1';
  $fields{exp}{lifestage}{type}                      = 'multiontology';
  $fields{exp}{lifestage}{label}                     = 'Life Stage';
  $fields{exp}{lifestage}{tab}                       = 'tab1';
  $fields{exp}{lifestage}{ontology_type}             = 'obo';
  $fields{exp}{lifestage}{ontology_table}            = 'lifestage';
#   $fields{exp}{species}{type}                        = 'dropdown';
  $fields{exp}{species}{type}                        = 'ontology';
  $fields{exp}{species}{label}                       = 'Species';
  $fields{exp}{species}{tab}                         = 'tab1';
  $fields{exp}{species}{ontology_type}               = 'Papspecies';
#   $fields{exp}{species}{ontology_type}               = 'obo';
#   $fields{exp}{species}{ontology_table}              = 'species';
  $fields{exp}{exprtype}{type}                       = 'multidropdown';
  $fields{exp}{exprtype}{label}                      = 'Type';
  $fields{exp}{exprtype}{tab}                        = 'tab2';
  $fields{exp}{exprtype}{dropdown_type}              = 'exprtype';
  $fields{exp}{antibodytext}{type}                   = 'bigtext';
  $fields{exp}{antibodytext}{label}                  = 'Antibody_Text';
  $fields{exp}{antibodytext}{tab}                    = 'tab2';
  $fields{exp}{reportergene}{type}                   = 'bigtext';
  $fields{exp}{reportergene}{label}                  = 'Reporter Gene';
  $fields{exp}{reportergene}{tab}                    = 'tab2';
  $fields{exp}{insitu}{type}                         = 'bigtext';
  $fields{exp}{insitu}{label}                        = 'In Situ';
  $fields{exp}{insitu}{tab}                          = 'tab2';
  $fields{exp}{rtpcr}{type}                          = 'bigtext';
  $fields{exp}{rtpcr}{label}                         = 'RT PCR';
  $fields{exp}{rtpcr}{tab}                           = 'tab2';
  $fields{exp}{northern}{type}                       = 'bigtext';
  $fields{exp}{northern}{label}                      = 'Northern';
  $fields{exp}{northern}{tab}                        = 'tab2';
  $fields{exp}{western}{type}                        = 'bigtext';
  $fields{exp}{western}{label}                       = 'Western';
  $fields{exp}{western}{tab}                         = 'tab2';
  $fields{exp}{pictureflag}{type}                    = 'toggle';
  $fields{exp}{pictureflag}{label}                   = 'Picture_Flag';
  $fields{exp}{pictureflag}{tab}                     = 'tab2';
  $fields{exp}{antibody}{type}                       = 'multiontology';
  $fields{exp}{antibody}{label}                      = 'Antibody_Info';
  $fields{exp}{antibody}{tab}                        = 'tab2';
  $fields{exp}{antibody}{ontology_type}              = 'Antibody';
  $fields{exp}{antibodyflag}{type}                   = 'toggle';
  $fields{exp}{antibodyflag}{label}                  = 'Antibody_Flag';
  $fields{exp}{antibodyflag}{tab}                    = 'tab2';
  $fields{exp}{pattern}{type}                        = 'bigtext';
  $fields{exp}{pattern}{label}                       = 'Pattern';
  $fields{exp}{pattern}{tab}                         = 'tab2';
  $fields{exp}{remark}{type}                         = 'bigtext';
  $fields{exp}{remark}{label}                        = 'Remark';
  $fields{exp}{remark}{tab}                          = 'tab2';
  $fields{exp}{transgene}{type}                      = 'multiontology';
  $fields{exp}{transgene}{label}                     = 'Transgene';
  $fields{exp}{transgene}{tab}                       = 'tab2';
  $fields{exp}{transgene}{ontology_type}             = 'Transgene';
  $fields{exp}{construct}{type}                      = 'multiontology';
  $fields{exp}{construct}{label}                     = 'Construct';
  $fields{exp}{construct}{tab}                       = 'tab2';
  $fields{exp}{construct}{ontology_type}             = 'WBConstruct';
  $fields{exp}{transgeneflag}{type}                  = 'toggle';
  $fields{exp}{transgeneflag}{label}                 = 'Transgene_Flag';
  $fields{exp}{transgeneflag}{tab}                   = 'tab2';
  $fields{exp}{seqfeature}{type}                     = 'multiontology';
  $fields{exp}{seqfeature}{label}                    = 'Sequence Feature';
  $fields{exp}{seqfeature}{tab}                      = 'tab2';
  $fields{exp}{seqfeature}{ontology_type}            = 'WBSeqFeat';
#   $fields{exp}{seqfeature}{ontology_type}            = 'obo';		# 2014 10 01 using sqf_ tables instead of obo_*_feature tables
#   $fields{exp}{seqfeature}{ontology_table}           = 'feature';
  $fields{exp}{curator}{type}                        = 'dropdown';
  $fields{exp}{curator}{label}                       = 'Curator';
  $fields{exp}{curator}{tab}                         = 'tab2';
  $fields{exp}{curator}{dropdown_type}               = 'curator';
  $fields{exp}{nodump}{type}                         = 'toggle';
  $fields{exp}{nodump}{label}                        = 'NO DUMP';
  $fields{exp}{nodump}{tab}                          = 'tab2';
#   $fields{exp}{protein}{type}                        = 'multiontology';
#   $fields{exp}{protein}{label}                       = 'Protein';
#   $fields{exp}{protein}{tab}                         = 'tab3';
#   $fields{exp}{protein}{ontology_type}               = 'Protein';
#   $fields{exp}{proteindesc}{type}                    = 'text';
#   $fields{exp}{proteindesc}{label}                   = 'Protein Description';
#   $fields{exp}{proteindesc}{tab}                     = 'tab3';
  $fields{exp}{clone}{type}                          = 'multiontology';
  $fields{exp}{clone}{label}                         = 'Clone';
  $fields{exp}{clone}{tab}                           = 'tab3';
  $fields{exp}{clone}{ontology_type}                 = 'obo';
  $fields{exp}{clone}{ontology_table}                = 'clone';
  $fields{exp}{strain}{type}                         = 'multiontology';
  $fields{exp}{strain}{label}                        = 'Strain';
  $fields{exp}{strain}{tab}                          = 'tab3';
  $fields{exp}{strain}{ontology_type}                = 'obo';
  $fields{exp}{strain}{ontology_table}               = 'strain';
  $fields{exp}{sequence}{type}                       = 'text';
  $fields{exp}{sequence}{label}                      = 'Sequence';
  $fields{exp}{sequence}{tab}                        = 'tab3';
#   $fields{exp}{movieurl}{type}                       = 'text';
#   $fields{exp}{movieurl}{label}                      = 'Movie URL';
#   $fields{exp}{movieurl}{tab}                        = 'tab3';
#   $fields{exp}{laboratory}{type}                     = 'multiontology';
#   $fields{exp}{laboratory}{label}                    = 'Laboratory';
#   $fields{exp}{laboratory}{tab}                      = 'tab3';
#   $fields{exp}{laboratory}{ontology_type}            = 'Laboratory';
  $fields{exp}{variation}{type}                      = 'multiontology';
  $fields{exp}{variation}{label}                     = 'Variation';
  $fields{exp}{variation}{tab}                       = 'tab3';
  $fields{exp}{variation}{ontology_type}             = 'obo';
  $fields{exp}{variation}{ontology_table}            = 'variation';
#   $fields{exp}{author}{type}                         = 'text';
#   $fields{exp}{author}{label}                        = 'Author';
#   $fields{exp}{author}{tab}                          = 'tab3';
#   $fields{exp}{date}{type}                           = 'text';
#   $fields{exp}{date}{label}                          = 'Date';
#   $fields{exp}{date}{tab}                            = 'tab3';
#   $fields{exp}{contact}{type}                        = 'ontology';
#   $fields{exp}{contact}{label}                       = 'Contact';
#   $fields{exp}{contact}{tab}                         = 'tab4';
#   $fields{exp}{contact}{ontology_type}               = 'WBPerson';
#   $fields{exp}{email}{type}                          = 'text';
#   $fields{exp}{email}{label}                         = 'Email';
#   $fields{exp}{email}{tab}                           = 'tab4';
#   $fields{exp}{coaut}{type}                          = 'multiontology';
#   $fields{exp}{coaut}{label}                         = 'Co-authors';
#   $fields{exp}{coaut}{tab}                           = 'tab4';
#   $fields{exp}{coaut}{ontology_type}                 = 'WBPerson';
  $fields{exp}{micropublication}{type}               = 'toggle';
  $fields{exp}{micropublication}{label}              = 'Micropublication';
  $fields{exp}{micropublication}{tab}                = 'tab4';
#   $fields{exp}{funding}{type}                        = 'bigtext';
#   $fields{exp}{funding}{label}                       = 'Funding';
#   $fields{exp}{funding}{tab}                         = 'tab4';
  $fields{exp}{curatedby}{type}                      = 'text';
  $fields{exp}{curatedby}{label}                     = 'Curated by';
  $fields{exp}{curatedby}{tab}                       = 'tab4';
#   $datatypes{exp}{newRowSub}                         = \&newRowExp;
#   $datatypes{exp}{label}                             = 'exprpat';
#   @{ $datatypes{exp}{highestPgidTables} }            = qw( name curator );
#   return( \%fields, \%datatypes);
} # sub initWormExpFields


__END__

exp_anatomy                   exp_gene_idx                  exp_paper_hst_idx             exp_reportergene_hst
exp_anatomy_hst               exp_goid                      exp_paper_idx                 exp_reportergene_hst_idx
exp_anatomy_hst_idx           exp_goid_hst                  exp_pattern                   exp_reportergene_idx
exp_anatomy_idx               exp_goid_hst_idx              exp_pattern_hst               exp_rtpcr
exp_antibody                  exp_goid_idx                  exp_pattern_hst_idx           exp_rtpcr_hst
exp_antibodyflag              exp_granatomy                 exp_pattern_idx               exp_rtpcr_hst_idx
exp_antibodyflag_hst          exp_granatomy_hst             exp_person                    exp_rtpcr_idx
exp_antibodyflag_hst_idx      exp_granatomy_hst_idx         exp_person_hst                exp_seqfeature
exp_antibodyflag_idx          exp_granatomy_idx             exp_person_hst_idx            exp_seqfeature_hst
exp_antibody_hst              exp_grcellcycle               exp_person_idx                exp_seqfeature_hst_idx
exp_antibody_hst_idx          exp_grcellcycle_hst           exp_pictureflag               exp_seqfeature_idx
exp_antibody_idx              exp_grcellcycle_hst_idx       exp_pictureflag_hst           exp_sequence
exp_antibodytext              exp_grcellcycle_idx           exp_pictureflag_hst_idx       exp_sequence_hst
exp_antibodytext_hst          exp_grlifestage               exp_pictureflag_idx           exp_sequence_hst_idx
exp_antibodytext_hst_idx      exp_grlifestage_hst           exp_qualifier                 exp_sequence_idx
exp_antibodytext_idx          exp_grlifestage_hst_idx       exp_qualifier_hst             exp_species
exp_clone                     exp_grlifestage_idx           exp_qualifier_hst_idx         exp_species_hst
exp_clone_hst                 exp_insitu                    exp_qualifier_idx             exp_species_hst_idx
exp_clone_hst_idx             exp_insitu_hst                exp_qualifierls               exp_species_idx
exp_clone_idx                 exp_insitu_hst_idx            exp_qualifierls_hst           exp_strain
exp_construct                 exp_insitu_idx                exp_qualifierls_hst_idx       exp_strain_hst
exp_construct_hst             exp_lifestage                 exp_qualifierls_idx           exp_strain_hst_idx
exp_construct_hst_idx         exp_lifestage_hst             exp_qualifiertext             exp_strain_idx
exp_construct_idx             exp_lifestage_hst_idx         exp_qualifiertext_hst         exp_subcellloc
exp_curatedby                 exp_lifestage_idx             exp_qualifiertext_hst_idx     exp_subcellloc_hst
exp_curatedby_hst             exp_micropublication          exp_qualifiertext_idx         exp_subcellloc_hst_idx
exp_curatedby_hst_idx         exp_micropublication_hst      exp_relanatomy                exp_subcellloc_idx
exp_curatedby_idx             exp_micropublication_hst_idx  exp_relanatomy_hst            exp_transgene
exp_curator                   exp_micropublication_idx      exp_relanatomy_hst_idx        exp_transgeneflag
exp_curator_hst               exp_name                      exp_relanatomy_idx            exp_transgeneflag_hst
exp_curator_hst_idx           exp_name_hst                  exp_relcellcycle              exp_transgeneflag_hst_idx
exp_curator_idx               exp_name_hst_idx              exp_relcellcycle_hst          exp_transgeneflag_idx
exp_endogenous                exp_name_idx                  exp_relcellcycle_hst_idx      exp_transgene_hst
exp_endogenous_hst            exp_nodump                    exp_relcellcycle_idx          exp_transgene_hst_idx
exp_endogenous_hst_idx        exp_nodump_hst                exp_rellifestage              exp_transgene_idx
exp_endogenous_idx            exp_nodump_hst_idx            exp_rellifestage_hst          exp_variation
exp_exprtype                  exp_nodump_idx                exp_rellifestage_hst_idx      exp_variation_hst
exp_exprtype_hst              exp_northern                  exp_rellifestage_idx          exp_variation_hst_idx
exp_exprtype_hst_idx          exp_northern_hst              exp_remark                    exp_variation_idx
exp_exprtype_idx              exp_northern_hst_idx          exp_remark_hst                exp_western
exp_gene                      exp_northern_idx              exp_remark_hst_idx            exp_western_hst
exp_gene_hst                  exp_paper                     exp_remark_idx                exp_western_hst_idx
exp_gene_hst_idx              exp_paper_hst                 exp_reportergene              exp_western_idx


