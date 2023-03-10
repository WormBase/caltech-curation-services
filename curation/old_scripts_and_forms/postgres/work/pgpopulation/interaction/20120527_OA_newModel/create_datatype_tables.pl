#!/usr/bin/perl -w

# create <datatype>_<table> table, <datatype>_<table>_hst history table, <datatype>_<table>_idx index, <datatype>_<table>_hst_idx index. 

# delete :
# DROP TABLE int_nondirectional_hst;
# DROP TABLE int_transgeneone_hst;
# DROP TABLE int_transgeneonegene_hst;
# DROP TABLE int_transgenetwo_hst;
# DROP TABLE int_transgenetwogene_hst;
# DROP TABLE int_nondirectional;
# DROP TABLE int_transgeneone;
# DROP TABLE int_transgeneonegene;
# DROP TABLE int_transgenetwo;
# DROP TABLE int_transgenetwogene;

# create :
# process database summary detectionmethod library laboratory company pcrbait pcrtarget pcrnondir sequencebait sequencetarget sequencenondir cdsbait cdstarget cdsnondir proteinbait proteintarget proteinnondir genebait genetarget antibody antibodyremark genenondir rearrnondir rearrone rearrtwo deviation neutralityfxn lsrnai exprpattern intravariationone intravariationtwo transgene confidence pvalue loglikelihood throughput



use strict;
use diagnostics;
use DBI;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

# put postgres users that should have 'all' access to the table.
my @users_all = ('apache', 'azurebrd', 'cecilia', '"www-data"');

# put postgres users that should have 'select' access to the table.  mainly so they can log on and see the data from a shell, but would probably work if you set the webserver to have select access, it would just give error messages if someone tried to update data.
my @users_select = ('acedb');

# the code for the datatype, by convention all datatypes have three letters.
my $datatype = 'int';

# put tables here for each OA field.  Skip field 'id', fields of type 'queryonly', and any other fields that should not have a corresponding postgres table.
# my @tables = qw( process dbname dbfield dbaccession summary detectionmethod library libraryamount laboratory company pcrbait pcrtarget pcrnondir sequencebait sequencetarget sequencenondir cdsbait cdstarget cdsnondir proteinbait proteintarget proteinnondir genebait genetarget antibody antibodyremark genenondir rearrnondir rearrone rearrtwo deviation neutralityfxn lsrnai exprpattern intravariationone intravariationtwo transgene confidence pvalue loglikelihood throughput );
my @tables = qw( process database summary detectionmethod library laboratory company pcrbait pcrtarget pcrnondir sequencebait sequencetarget sequencenondir cdsbait cdstarget cdsnondir proteinbait proteintarget proteinnondir genebait genetarget antibody antibodyremark genenondir rearrnondir rearrone rearrtwo deviation neutralityfxn lsrnai exprpattern variationnondir intravariationone intravariationtwo transgene confidence pvalue loglikelihood throughput );	# libraryamount now part of library, database replaces 3 db fields.

foreach my $table (@tables) { &createTable($table); }


sub createTable {
  my $table = shift;
  my $result;
  $result = $dbh->do( "DROP TABLE ${datatype}_${table}_hst;" );
  $result = $dbh->do( "CREATE TABLE ${datatype}_${table}_hst (
                         joinkey text, 
                         ${datatype}_${table}_hst text,
                         ${datatype}_timestamp timestamp with time zone DEFAULT \"timestamp\"('now'::text)); " );
  $result = $dbh->do( "REVOKE ALL ON TABLE ${datatype}_${table}_hst FROM PUBLIC; ");
  foreach my $user (@users_select) { 
    $result = $dbh->do( "GRANT SELECT ON TABLE ${datatype}_${table}_hst TO $user; "); }
  foreach my $user (@users_all) { 
    $result = $dbh->do( "GRANT ALL ON TABLE ${datatype}_${table}_hst TO $user; "); }
  $result = $dbh->do( "CREATE INDEX ${datatype}_${table}_hst_idx ON ${datatype}_${table}_hst USING btree (joinkey); ");

  $result = $dbh->do( "DROP TABLE ${datatype}_$table;" );
  $result = $dbh->do( "CREATE TABLE ${datatype}_$table (
                         joinkey text, 
                         ${datatype}_$table text,
                         ${datatype}_timestamp timestamp with time zone DEFAULT \"timestamp\"('now'::text)); " );
  $result = $dbh->do( "REVOKE ALL ON TABLE ${datatype}_$table FROM PUBLIC; ");
  foreach my $user (@users_select) { 
    $result = $dbh->do( "GRANT SELECT ON TABLE ${datatype}_${table} TO $user; "); }
  foreach my $user (@users_all) { 
    $result = $dbh->do( "GRANT ALL ON TABLE ${datatype}_${table} TO $user; "); }
  $result = $dbh->do( "CREATE INDEX ${datatype}_${table}_idx ON ${datatype}_$table USING btree (joinkey); ");
} # sub createTable


__END__

transfer int_rnai into multiontology int_rnai and freetext int_lsrnai

update int_type table to new types :
'Physical_interaction' SET TO 'Physical'
'Predicted_interaction' SET TO 'Predicted'
'Genetic' SET TO 'Genetic_interaction'
UPDATE int_type SET int_type = 'Physical' WHERE int_type = 'Physical_interaction' ;
UPDATE int_type SET int_type = 'Predicted' WHERE int_type = 'Predicted_interaction' ;
UPDATE int_type SET int_type = 'Genetic_interaction' WHERE int_type = 'Genetic' ;

NEED TO CONVERT TO MULTI FROM SINGLE

    Physical Dumps as: Physical
    Predicted Dumps as: Predicted
    Genetic - Genetic interaction Dumps as: Genetic_interaction
    Genetic - Negative genetic Dumps as: Negative_genetic
    Genetic - Synthetic Dumps as: Synthetic
    Genetic - Enhancement Dumps as: Enhancement
    Genetic - Unilateral enhancement Dumps as: Unilateral_enhancement
    Genetic - Mutual enhancement Dumps as: Mutual_enhancement
    Genetic - Suppression Dumps as: Suppression
    Genetic - Unilateral suppression Dumps as: Unilateral_suppression
    Genetic - Mutual suppression Dumps as: Mutual_suppression
    Genetic - Asynthetic Dumps as: Asynthetic
    Genetic - Suppression/Enhancement Dumps as: Suppression_enhancement
    Genetic - Epistasis Dumps as: Epistasis
    Genetic - Maximal epistasis Dumps as: Maximal_epistasis
    Genetic - Minimal epistasis Dumps as: Minimal_epistasis
    Genetic - Suppression/Epistasis Dumps as: Suppression_epistasis
    Genetic - Agonistic epistasis Dumps as: Agonistic_epistasis
    Genetic - Antagonistic epistasis Dumps as: Antagonistic_epistasis
    Genetic - Oversuppression Dumps as: Oversuppression
    Genetic - Unilateral oversuppression Dumps as: Unilateral_oversuppression
    Genetic - Mutual oversuppression Dumps as: Mutual_oversuppression
    Genetic - Complex oversuppression Dumps as: Complex_oversuppression
    Genetic - Oversuppression/Enhancement Dumps as: Oversuppression_enhancement
    Genetic - Phenotype bias Dumps as: Phenotype_bias
    Genetic - Biased suppression Dumps as: Biased_suppression
    Genetic - Biased enhancement Dumps as: Biased_enhancement
    Genetic - Complex phenotype bias Dumps as: Complex_phenotype_bias
    Genetic - No interaction Dumps as: No_interaction 
