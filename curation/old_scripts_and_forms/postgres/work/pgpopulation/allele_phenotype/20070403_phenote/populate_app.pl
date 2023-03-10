#!/usr/bin/perl -w

# populate app_ tables based on alp_ tables.  
# Drop and Create the tables and indices with psql -e testdb < app_tables
# Then copy the data with perl.  2007 05 03
#
# added obj_remark table.  2007 08 22
#
# added obj_remark table to the actual table list in app_tables.
# added paper_remark table (DIFFERENT)  2007 08 28

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

# my @tables = qw( anat_term cold_degree cold_sens curator delivered finalname finished func genotype go_sug haplo heat_degree heat_sens intx_desc lifestage mat_effect nature not paper pat_effect penetrance percent person phen_remark phenotype quantity quantity_remark range remark rnai_brief strain sug_def sug_ref suggested temperature tempname term treatment type wbgene obj_remark );
my @tables = qw( anat_term cold_degree cold_sens curator delivered finalname finished func genotype go_sug haplo heat_degree heat_sens intx_desc lifestage mat_effect nature not paper pat_effect penetrance percent person phen_remark phenotype quantity quantity_remark range paper_remark rnai_brief strain sug_def sug_ref suggested temperature tempname term treatment type wbgene obj_remark );

`psql -e testdb < app_tables`;

my $directory = '/home/postgres/work/pgpopulation/allele_phenotype/20070403_phenote/dumps';
chdir($directory) or die "Cannot go to $directory ($!)";

foreach my $table (@tables) {
  my $result = $conn->exec( "COPY alp_$table TO '${directory}/$table';" );
  $result = $conn->exec( "COPY app_$table FROM '${directory}/$table';" );
} # foreach my $table (@tables)


__END__

# populate app_ tables based on alp_ tables, but compressing all big box data
# into columns only.  2007 04 03

my @same = qw( type tempname finalname wbgene );			# no change
my @boxless = qw( curator paper person phenotype remark intx_desc );	# no box
my @compress = qw( not term phen_remark quality_remark quantity go_sug suggested sug_ref sug_def genotype lifestage anat_term temperature strain preparation treatment delivered nature penetrance percent range mat_effect pat_effect heat_sens heat_degree cold_sens cold_degree func haplo );	# compress columns

my %joinkeys;
foreach my $table (@same) {
  my $result = $conn->exec( "SELECT * FROM alp_$table;" );
  while (my @row = $result->fetchrow) {
    $joinkeys{$row[0]}++;
    my $vals = join"', '", @row;
    my $result2 = $conn->exec( "INSERT INTO app_$table VALUES ('$vals');" );
  }
}

foreach my $joinkey (sort keys %joinkeys) {
  if ($joinkey) {
    my $result = $conn->exec( "SELECT alp_box, alp_column FROM alp_term WHERE joinkey = '$joinkey' ORDER BY alp_box, alp_column DESC;" );
    my %temp; my %mappings; my %box_map; my $column = 0;
    while (my @row = $result->fetchrow) {
      my $box = $row[0]; my $column = $row[1]; $box *= 1000; my $key = $box + $column; $temp{$key}++; }
#     unless (keys %temp) { print "NO $joinkey\n"; }
    next unless keys %temp;		# skip entries without terms
    foreach my $key (sort keys %temp) { 
      $column++; $mappings{$key} = $column; 			# store mappings of box-column to column data
      if ($key =~ m/^(\d)0/) { $box_map{$1}{$column}++; } }	# as well as box to columns data
#     foreach my $key (sort keys %mappings) { print "$joinkey\t$key\t$mappings{$key}\n"; }
#     foreach my $key (sort {$a<=>$b} keys %box_map) { foreach my $column (sort {$a<=>$b} keys %{ $box_map{$key} }) { print "$joinkey\t$key\t$column\n"; } }
    my $new_joinkey = $joinkey; $new_joinkey =~ s/^\s+//g; $new_joinkey =~ s/\s+$//g;
    foreach my $table (@boxless) {
      my $cur_box = 0;
      my $result = $conn->exec( "SELECT * FROM alp_$table WHERE joinkey = '$joinkey';" );
      while (my @row = $result->fetchrow) {
        next unless (($row[0]) && ($row[1]));
        my $val = 'NULL';
        if ($row[2]) { $val = $row[2]; $val =~ s/\'/''/g; $val = "'$val'"; }
        $cur_box = $row[1];
        foreach my $column (sort {$a<=>$b} keys %{ $box_map{$cur_box} }) { 
          my $command = "INSERT INTO app_$table VALUES ('$new_joinkey', '$column', $val, '$row[3]')";
          my $result2 = $conn->exec( $command );
          print "$table\t$joinkey\t$cur_box\t$column\t$val\n";
          print "$command\n"; } } }
    foreach my $table (@compress) {
      my $cur_box = 0; my $cur_column = 0; 
      my $result = $conn->exec( "SELECT * FROM alp_$table WHERE joinkey = '$joinkey';" );
      while (my @row = $result->fetchrow) {
        next unless (($row[0]) && ($row[1]));
        my $val = 'NULL';
        if ($row[3]) { $val = $row[3]; $val =~ s/\'/''/g; $val = "'$val'"; }
        my $cur_box = $row[1]; my $cur_column = $row[2]; $cur_box *= 1000; my $key = $cur_box + $cur_column; 
#         unless ($mappings{$key}) { print "ERR no mapping for $joinkey J $table T $key KEY\n"; }
        next unless ($mappings{$key});			# no real data here
        my $column = $mappings{$key};
        my $command = "INSERT INTO app_$table VALUES ('$new_joinkey', '$column', $val, '$row[4]')";
# if ( ($table eq 'phen_remark') || ($table eq 'range') || ($table eq 'anat_term')) { my $result2 = $conn->exec( $command ); }
        my $result2 = $conn->exec( $command );
        print "$table\t$joinkey\t$key\t$column\t$val\n";
        print "$command\n"; } }
  } # if ($joinkey)
} # foreach my $joinkey (sort keys %joinkeys)

__END__


alp_anat_term        alp_finished         alp_heat_sens        alp_paper
alp_phen_remark      alp_rnai_brief       alp_tempname
alp_cold_degree      alp_func             alp_intx_desc        alp_pat_effect
alp_preparation      alp_strain           alp_term
alp_cold_sens        alp_genotype         alp_lifestage        alp_penetrance
alp_quantity         alp_sug_def          alp_treatment
alp_curator          alp_go_sug           alp_mat_effect       alp_percent
alp_quantity_remark  alp_suggested        alp_type
alp_delivered        alp_haplo            alp_nature           alp_person
alp_range            alp_sug_ref          alp_wbgene
alp_finalname        alp_heat_degree      alp_not              alp_phenotype
alp_remark           alp_temperature      

app_anat_term        app_finished         app_heat_sens        app_paper
app_phen_remark      app_rnai_brief       app_tempname
app_cold_degree      app_func             app_intx_desc        app_pat_effect
app_preparation      app_strain           app_term
app_cold_sens        app_genotype         app_lifestage        app_penetrance
app_quantity         app_sug_def          app_treatment
app_curator          app_go_sug           app_mat_effect       app_percent
app_quantity_remark  app_suggested        app_type
app_delivered        app_haplo            app_nature           app_person
app_range            app_sug_ref          app_wbgene
app_finalname        app_heat_degree      app_not              app_phenotype
app_remark           app_temperature

type tempname finalname wbgene -> no change
curator paper person phenotype remark intx_desc -> no box
not term phen_remark quality_remark quantity go_sug suggested sug_ref sug_def
genotype lifestage anat_term temperature strain preparation treatment delivered
nature penetrance percent range mat_effect pat_effect heat_sens heat_degree
cold_sens cold_degree func haplo -> compress columns


CREATE TABLE alp_type (
    joinkey text, 
    alp_type text,
    alp_timestamp timestamp with time zone DEFAULT "timestamp"('now'::text));
REVOKE ALL ON TABLE alp_type FROM PUBLIC;
GRANT SELECT ON TABLE alp_type TO acedb;
GRANT ALL ON TABLE alp_type TO acedb;
GRANT ALL ON TABLE alp_type TO apache;
GRANT ALL ON TABLE alp_type TO cecilia;
GRANT ALL ON TABLE alp_type TO azurebrd;
CREATE INDEX alp_type_idx ON alp_type USING btree (joinkey);

CREATE TABLE alp_tempname (
    joinkey text, 
    alp_tempname text,
    alp_timestamp timestamp with time zone DEFAULT "timestamp"('now'::text));
REVOKE ALL ON TABLE alp_tempname FROM PUBLIC;
GRANT SELECT ON TABLE alp_tempname TO acedb;
GRANT ALL ON TABLE alp_tempname TO acedb;
GRANT ALL ON TABLE alp_tempname TO apache;
GRANT ALL ON TABLE alp_tempname TO cecilia;
GRANT ALL ON TABLE alp_tempname TO azurebrd;
CREATE INDEX alp_tempname_idx ON alp_tempname USING btree (joinkey);

CREATE TABLE alp_finalname (
    joinkey text, 
    alp_finalname text,
    alp_timestamp timestamp with time zone DEFAULT "timestamp"('now'::text));
REVOKE ALL ON TABLE alp_finalname FROM PUBLIC;
GRANT SELECT ON TABLE alp_finalname TO acedb;
GRANT ALL ON TABLE alp_finalname TO acedb;
GRANT ALL ON TABLE alp_finalname TO apache;
GRANT ALL ON TABLE alp_finalname TO cecilia;
GRANT ALL ON TABLE alp_finalname TO azurebrd;
CREATE INDEX alp_finalname_idx ON alp_finalname USING btree (joinkey);

CREATE TABLE alp_wbgene (
    joinkey text, 
    alp_wbgene text,
    alp_timestamp timestamp with time zone DEFAULT "timestamp"('now'::text));
REVOKE ALL ON TABLE alp_wbgene FROM PUBLIC;
GRANT SELECT ON TABLE alp_wbgene TO acedb;
GRANT ALL ON TABLE alp_wbgene TO apache;
GRANT ALL ON TABLE alp_wbgene TO cecilia;
GRANT ALL ON TABLE alp_wbgene TO azurebrd;
CREATE INDEX alp_wbgene_idx ON alp_wbgene USING btree (joinkey);

CREATE TABLE alp_rnai_brief (
    joinkey text, 
    alp_rnai_brief text,
    alp_timestamp timestamp with time zone DEFAULT "timestamp"('now'::text));
REVOKE ALL ON TABLE alp_rnai_brief FROM PUBLIC;
GRANT SELECT ON TABLE alp_rnai_brief TO acedb;
GRANT ALL ON TABLE alp_rnai_brief TO apache;
GRANT ALL ON TABLE alp_rnai_brief TO cecilia;
GRANT ALL ON TABLE alp_rnai_brief TO azurebrd;
CREATE INDEX alp_rnai_brief_idx ON alp_rnai_brief USING btree (joinkey);

CREATE TABLE alp_curator (
    joinkey text, 
    alp_box text,
    alp_curator text,
    alp_timestamp timestamp with time zone DEFAULT "timestamp"('now'::text));
REVOKE ALL ON TABLE alp_curator FROM PUBLIC;
GRANT SELECT ON TABLE alp_curator TO acedb;
GRANT ALL ON TABLE alp_curator TO apache;
GRANT ALL ON TABLE alp_curator TO cecilia;
GRANT ALL ON TABLE alp_curator TO azurebrd;
CREATE INDEX alp_curator_idx ON alp_curator USING btree (joinkey);

CREATE TABLE alp_paper (
    joinkey text, 
    alp_box text,
    alp_paper text,
    alp_timestamp timestamp with time zone DEFAULT "timestamp"('now'::text));
REVOKE ALL ON TABLE alp_paper FROM PUBLIC;
GRANT SELECT ON TABLE alp_paper TO acedb;
GRANT ALL ON TABLE alp_paper TO apache;
GRANT ALL ON TABLE alp_paper TO cecilia;
GRANT ALL ON TABLE alp_paper TO azurebrd;
CREATE INDEX alp_paper_idx ON alp_paper USING btree (joinkey);

CREATE TABLE alp_person (
    joinkey text, 
    alp_box text,
    alp_person text,
    alp_timestamp timestamp with time zone DEFAULT "timestamp"('now'::text));
REVOKE ALL ON TABLE alp_person FROM PUBLIC;
GRANT SELECT ON TABLE alp_person TO acedb;
GRANT ALL ON TABLE alp_person TO apache;
GRANT ALL ON TABLE alp_person TO cecilia;
GRANT ALL ON TABLE alp_person TO azurebrd;
CREATE INDEX alp_person_idx ON alp_person USING btree (joinkey);

CREATE TABLE alp_finished (
    joinkey text, 
    alp_box text,
    alp_finished text,
    alp_timestamp timestamp with time zone DEFAULT "timestamp"('now'::text));
REVOKE ALL ON TABLE alp_finished FROM PUBLIC;
GRANT SELECT ON TABLE alp_finished TO acedb;
GRANT ALL ON TABLE alp_finished TO apache;
GRANT ALL ON TABLE alp_finished TO cecilia;
GRANT ALL ON TABLE alp_finished TO azurebrd;
CREATE INDEX alp_finished_idx ON alp_finished USING btree (joinkey);

CREATE TABLE alp_phenotype (
    joinkey text, 
    alp_box text,
    alp_phenotype text,
    alp_timestamp timestamp with time zone DEFAULT "timestamp"('now'::text));
REVOKE ALL ON TABLE alp_phenotype FROM PUBLIC;
GRANT SELECT ON TABLE alp_phenotype TO acedb;
GRANT ALL ON TABLE alp_phenotype TO acedb;
GRANT ALL ON TABLE alp_phenotype TO apache;
GRANT ALL ON TABLE alp_phenotype TO cecilia;
GRANT ALL ON TABLE alp_phenotype TO azurebrd;
CREATE INDEX alp_phenotype_idx ON alp_phenotype USING btree (joinkey);

CREATE TABLE alp_remark (
    joinkey text, 
    alp_box text,
    alp_remark text,
    alp_timestamp timestamp with time zone DEFAULT "timestamp"('now'::text));
REVOKE ALL ON TABLE alp_remark FROM PUBLIC;
GRANT SELECT ON TABLE alp_remark TO acedb;
GRANT ALL ON TABLE alp_remark TO apache;
GRANT ALL ON TABLE alp_remark TO cecilia;
GRANT ALL ON TABLE alp_remark TO azurebrd;
CREATE INDEX alp_remark_idx ON alp_remark USING btree (joinkey);

CREATE TABLE alp_intx_desc (
    joinkey text, 
    alp_box text,
    alp_intx_desc text,
    alp_timestamp timestamp with time zone DEFAULT "timestamp"('now'::text));
REVOKE ALL ON TABLE alp_intx_desc FROM PUBLIC;
GRANT SELECT ON TABLE alp_intx_desc TO acedb;
GRANT ALL ON TABLE alp_intx_desc TO apache;
GRANT ALL ON TABLE alp_intx_desc TO cecilia;
GRANT ALL ON TABLE alp_intx_desc TO azurebrd;
CREATE INDEX alp_intx_desc_idx ON alp_intx_desc USING btree (joinkey);

CREATE TABLE alp_not (
    joinkey text, 
    alp_box text,
    alp_column text,
    alp_not text,
    alp_timestamp timestamp with time zone DEFAULT "timestamp"('now'::text));
REVOKE ALL ON TABLE alp_not FROM PUBLIC;
GRANT SELECT ON TABLE alp_not TO acedb;
GRANT ALL ON TABLE alp_not TO apache;
GRANT ALL ON TABLE alp_not TO cecilia;
GRANT ALL ON TABLE alp_not TO azurebrd;
CREATE INDEX alp_not_idx ON alp_not USING btree (joinkey);

CREATE TABLE alp_term (
    joinkey text, 
    alp_box text,
    alp_column text,
    alp_term text,
    alp_timestamp timestamp with time zone DEFAULT "timestamp"('now'::text));
REVOKE ALL ON TABLE alp_term FROM PUBLIC;
GRANT SELECT ON TABLE alp_term TO acedb;
GRANT ALL ON TABLE alp_term TO apache;
GRANT ALL ON TABLE alp_term TO cecilia;
GRANT ALL ON TABLE alp_term TO azurebrd;
CREATE INDEX alp_term_idx ON alp_term USING btree (joinkey);

CREATE TABLE alp_quantity_remark (
    joinkey text, 
    alp_box text,
    alp_column text,
    alp_quantity_remark text,
    alp_timestamp timestamp with time zone DEFAULT "timestamp"('now'::text));
REVOKE ALL ON TABLE alp_quantity_remark FROM PUBLIC;
GRANT SELECT ON TABLE alp_quantity_remark TO acedb;
GRANT ALL ON TABLE alp_quantity_remark TO apache;
GRANT ALL ON TABLE alp_quantity_remark TO cecilia;
GRANT ALL ON TABLE alp_quantity_remark TO azurebrd;
CREATE INDEX alp_quantity_remark_idx ON alp_quantity_remark USING btree (joinkey);

CREATE TABLE alp_quantity (
    joinkey text, 
    alp_box text,
    alp_column text,
    alp_quantity text,
    alp_timestamp timestamp with time zone DEFAULT "timestamp"('now'::text));
REVOKE ALL ON TABLE alp_quantity FROM PUBLIC;
GRANT SELECT ON TABLE alp_quantity TO acedb;
GRANT ALL ON TABLE alp_quantity TO apache;
GRANT ALL ON TABLE alp_quantity TO cecilia;
GRANT ALL ON TABLE alp_quantity TO azurebrd;
CREATE INDEX alp_quantity_idx ON alp_quantity USING btree (joinkey);

CREATE TABLE alp_go_sug (
    joinkey text, 
    alp_box text,
    alp_column text,
    alp_go_sug text,
    alp_timestamp timestamp with time zone DEFAULT "timestamp"('now'::text));
REVOKE ALL ON TABLE alp_go_sug FROM PUBLIC;
GRANT SELECT ON TABLE alp_go_sug TO acedb;
GRANT ALL ON TABLE alp_go_sug TO apache;
GRANT ALL ON TABLE alp_go_sug TO cecilia;
GRANT ALL ON TABLE alp_go_sug TO azurebrd;
CREATE INDEX alp_go_sug_idx ON alp_go_sug USING btree (joinkey);

CREATE TABLE alp_suggested (
    joinkey text, 
    alp_box text,
    alp_column text,
    alp_suggested text,
    alp_timestamp timestamp with time zone DEFAULT "timestamp"('now'::text));
REVOKE ALL ON TABLE alp_suggested FROM PUBLIC;
GRANT SELECT ON TABLE alp_suggested TO acedb;
GRANT ALL ON TABLE alp_suggested TO apache;
GRANT ALL ON TABLE alp_suggested TO cecilia;
GRANT ALL ON TABLE alp_suggested TO azurebrd;
CREATE INDEX alp_suggested_idx ON alp_suggested USING btree (joinkey);

CREATE TABLE alp_sug_ref (
    joinkey text, 
    alp_box text,
    alp_column text,
    alp_sug_ref text,
    alp_timestamp timestamp with time zone DEFAULT "timestamp"('now'::text));
REVOKE ALL ON TABLE alp_sug_ref FROM PUBLIC;
GRANT SELECT ON TABLE alp_sug_ref TO acedb;
GRANT ALL ON TABLE alp_sug_ref TO apache;
GRANT ALL ON TABLE alp_sug_ref TO cecilia;
GRANT ALL ON TABLE alp_sug_ref TO azurebrd;
CREATE INDEX alp_sug_ref_idx ON alp_sug_ref USING btree (joinkey);

CREATE TABLE alp_sug_def (
    joinkey text, 
    alp_box text,
    alp_column text,
    alp_sug_def text,
    alp_timestamp timestamp with time zone DEFAULT "timestamp"('now'::text));
REVOKE ALL ON TABLE alp_sug_def FROM PUBLIC;
GRANT SELECT ON TABLE alp_sug_def TO acedb;
GRANT ALL ON TABLE alp_sug_def TO apache;
GRANT ALL ON TABLE alp_sug_def TO cecilia;
GRANT ALL ON TABLE alp_sug_def TO azurebrd;
CREATE INDEX alp_sug_def_idx ON alp_sug_def USING btree (joinkey);

CREATE TABLE alp_genotype (
    joinkey text, 
    alp_box text,
    alp_column text,
    alp_genotype text,
    alp_timestamp timestamp with time zone DEFAULT "timestamp"('now'::text));
REVOKE ALL ON TABLE alp_genotype FROM PUBLIC;
GRANT SELECT ON TABLE alp_genotype TO acedb;
GRANT ALL ON TABLE alp_genotype TO apache;
GRANT ALL ON TABLE alp_genotype TO cecilia;
GRANT ALL ON TABLE alp_genotype TO azurebrd;
CREATE INDEX alp_genotype_idx ON alp_genotype USING btree (joinkey);

CREATE TABLE alp_lifestage (
    joinkey text, 
    alp_box text,
    alp_column text,
    alp_lifestage text,
    alp_timestamp timestamp with time zone DEFAULT "timestamp"('now'::text));
REVOKE ALL ON TABLE alp_lifestage FROM PUBLIC;
GRANT SELECT ON TABLE alp_lifestage TO acedb;
GRANT ALL ON TABLE alp_lifestage TO apache;
GRANT ALL ON TABLE alp_lifestage TO cecilia;
GRANT ALL ON TABLE alp_lifestage TO azurebrd;
CREATE INDEX alp_lifestage_idx ON alp_lifestage USING btree (joinkey);

CREATE TABLE alp_temperature (
    joinkey text, 
    alp_box text,
    alp_column text,
    alp_temperature text,
    alp_timestamp timestamp with time zone DEFAULT "timestamp"('now'::text));
REVOKE ALL ON TABLE alp_temperature FROM PUBLIC;
GRANT SELECT ON TABLE alp_temperature TO acedb;
GRANT ALL ON TABLE alp_temperature TO apache;
GRANT ALL ON TABLE alp_temperature TO cecilia;
GRANT ALL ON TABLE alp_temperature TO azurebrd;
CREATE INDEX alp_temperature_idx ON alp_temperature USING btree (joinkey);

CREATE TABLE alp_strain (
    joinkey text, 
    alp_box text,
    alp_column text,
    alp_strain text,
    alp_timestamp timestamp with time zone DEFAULT "timestamp"('now'::text));
REVOKE ALL ON TABLE alp_strain FROM PUBLIC;
GRANT SELECT ON TABLE alp_strain TO acedb;
GRANT ALL ON TABLE alp_strain TO apache;
GRANT ALL ON TABLE alp_strain TO cecilia;
GRANT ALL ON TABLE alp_strain TO azurebrd;
CREATE INDEX alp_strain_idx ON alp_strain USING btree (joinkey);

CREATE TABLE alp_preparation (
    joinkey text, 
    alp_box text,
    alp_column text,
    alp_preparation text,
    alp_timestamp timestamp with time zone DEFAULT "timestamp"('now'::text));
REVOKE ALL ON TABLE alp_preparation FROM PUBLIC;
GRANT SELECT ON TABLE alp_preparation TO acedb;
GRANT ALL ON TABLE alp_preparation TO apache;
GRANT ALL ON TABLE alp_preparation TO cecilia;
GRANT ALL ON TABLE alp_preparation TO azurebrd;
CREATE INDEX alp_preparation_idx ON alp_preparation USING btree (joinkey);

CREATE TABLE alp_treatment (
    joinkey text, 
    alp_box text,
    alp_column text,
    alp_treatment text,
    alp_timestamp timestamp with time zone DEFAULT "timestamp"('now'::text));
REVOKE ALL ON TABLE alp_treatment FROM PUBLIC;
GRANT SELECT ON TABLE alp_treatment TO acedb;
GRANT ALL ON TABLE alp_treatment TO apache;
GRANT ALL ON TABLE alp_treatment TO cecilia;
GRANT ALL ON TABLE alp_treatment TO azurebrd;
CREATE INDEX alp_treatment_idx ON alp_treatment USING btree (joinkey);

CREATE TABLE alp_delivered (
    joinkey text, 
    alp_box text,
    alp_column text,
    alp_delivered text,
    alp_timestamp timestamp with time zone DEFAULT "timestamp"('now'::text));
REVOKE ALL ON TABLE alp_delivered FROM PUBLIC;
GRANT SELECT ON TABLE alp_delivered TO acedb;
GRANT ALL ON TABLE alp_delivered TO apache;
GRANT ALL ON TABLE alp_delivered TO cecilia;
GRANT ALL ON TABLE alp_delivered TO azurebrd;
CREATE INDEX alp_delivered_idx ON alp_delivered USING btree (joinkey);

CREATE TABLE alp_nature (
    joinkey text, 
    alp_box text,
    alp_column text,
    alp_nature text,
    alp_timestamp timestamp with time zone DEFAULT "timestamp"('now'::text));
REVOKE ALL ON TABLE alp_nature FROM PUBLIC;
GRANT SELECT ON TABLE alp_nature TO acedb;
GRANT ALL ON TABLE alp_nature TO apache;
GRANT ALL ON TABLE alp_nature TO cecilia;
GRANT ALL ON TABLE alp_nature TO azurebrd;
CREATE INDEX alp_nature_idx ON alp_nature USING btree (joinkey);

CREATE TABLE alp_penetrance (
    joinkey text, 
    alp_box text,
    alp_column text,
    alp_penetrance text,
    alp_timestamp timestamp with time zone DEFAULT "timestamp"('now'::text));
REVOKE ALL ON TABLE alp_penetrance FROM PUBLIC;
GRANT SELECT ON TABLE alp_penetrance TO acedb;
GRANT ALL ON TABLE alp_penetrance TO apache;
GRANT ALL ON TABLE alp_penetrance TO cecilia;
GRANT ALL ON TABLE alp_penetrance TO azurebrd;
CREATE INDEX alp_penetrance_idx ON alp_penetrance USING btree (joinkey);

CREATE TABLE alp_percent (
    joinkey text, 
    alp_box text,
    alp_column text,
    alp_percent text,
    alp_timestamp timestamp with time zone DEFAULT "timestamp"('now'::text));
REVOKE ALL ON TABLE alp_percent FROM PUBLIC;
GRANT SELECT ON TABLE alp_percent TO acedb;
GRANT ALL ON TABLE alp_percent TO apache;
GRANT ALL ON TABLE alp_percent TO cecilia;
GRANT ALL ON TABLE alp_percent TO azurebrd;
CREATE INDEX alp_percent_idx ON alp_percent USING btree (joinkey);

CREATE TABLE alp_mat_effect (
    joinkey text, 
    alp_box text,
    alp_column text,
    alp_mat_effect text,
    alp_timestamp timestamp with time zone DEFAULT "timestamp"('now'::text));
REVOKE ALL ON TABLE alp_mat_effect FROM PUBLIC;
GRANT SELECT ON TABLE alp_mat_effect TO acedb;
GRANT ALL ON TABLE alp_mat_effect TO apache;
GRANT ALL ON TABLE alp_mat_effect TO cecilia;
GRANT ALL ON TABLE alp_mat_effect TO azurebrd;
CREATE INDEX alp_mat_effect_idx ON alp_mat_effect USING btree (joinkey);

CREATE TABLE alp_pat_effect (
    joinkey text, 
    alp_box text,
    alp_column text,
    alp_pat_effect text,
    alp_timestamp timestamp with time zone DEFAULT "timestamp"('now'::text));
REVOKE ALL ON TABLE alp_pat_effect FROM PUBLIC;
GRANT SELECT ON TABLE alp_pat_effect TO acedb;
GRANT ALL ON TABLE alp_pat_effect TO apache;
GRANT ALL ON TABLE alp_pat_effect TO cecilia;
GRANT ALL ON TABLE alp_pat_effect TO azurebrd;
CREATE INDEX alp_pat_effect_idx ON alp_pat_effect USING btree (joinkey);

CREATE TABLE alp_heat_sens (
    joinkey text, 
    alp_box text,
    alp_column text,
    alp_heat_sens text,
    alp_timestamp timestamp with time zone DEFAULT "timestamp"('now'::text));
REVOKE ALL ON TABLE alp_heat_sens FROM PUBLIC;
GRANT SELECT ON TABLE alp_heat_sens TO acedb;
GRANT ALL ON TABLE alp_heat_sens TO apache;
GRANT ALL ON TABLE alp_heat_sens TO cecilia;
GRANT ALL ON TABLE alp_heat_sens TO azurebrd;
CREATE INDEX alp_heat_sens_idx ON alp_heat_sens USING btree (joinkey);

CREATE TABLE alp_cold_sens (
    joinkey text, 
    alp_box text,
    alp_column text,
    alp_cold_sens text,
    alp_timestamp timestamp with time zone DEFAULT "timestamp"('now'::text));
REVOKE ALL ON TABLE alp_cold_sens FROM PUBLIC;
GRANT SELECT ON TABLE alp_cold_sens TO acedb;
GRANT ALL ON TABLE alp_cold_sens TO apache;
GRANT ALL ON TABLE alp_cold_sens TO cecilia;
GRANT ALL ON TABLE alp_cold_sens TO azurebrd;
CREATE INDEX alp_cold_sens_idx ON alp_cold_sens USING btree (joinkey);

CREATE TABLE alp_heat_degree (
    joinkey text, 
    alp_box text,
    alp_column text,
    alp_heat_degree text,
    alp_timestamp timestamp with time zone DEFAULT "timestamp"('now'::text));
REVOKE ALL ON TABLE alp_heat_degree FROM PUBLIC;
GRANT SELECT ON TABLE alp_heat_degree TO acedb;
GRANT ALL ON TABLE alp_heat_degree TO apache;
GRANT ALL ON TABLE alp_heat_degree TO cecilia;
GRANT ALL ON TABLE alp_heat_degree TO azurebrd;
CREATE INDEX alp_heat_degree_idx ON alp_heat_degree USING btree (joinkey);

CREATE TABLE alp_cold_degree (
    joinkey text, 
    alp_box text,
    alp_column text,
    alp_cold_degree text,
    alp_timestamp timestamp with time zone DEFAULT "timestamp"('now'::text));
REVOKE ALL ON TABLE alp_cold_degree FROM PUBLIC;
GRANT SELECT ON TABLE alp_cold_degree TO acedb;
GRANT ALL ON TABLE alp_cold_degree TO apache;
GRANT ALL ON TABLE alp_cold_degree TO cecilia;
GRANT ALL ON TABLE alp_cold_degree TO azurebrd;
CREATE INDEX alp_cold_degree_idx ON alp_cold_degree USING btree (joinkey);

CREATE TABLE alp_func (
    joinkey text, 
    alp_box text,
    alp_column text,
    alp_func text,
    alp_timestamp timestamp with time zone DEFAULT "timestamp"('now'::text));
REVOKE ALL ON TABLE alp_func FROM PUBLIC;
GRANT SELECT ON TABLE alp_func TO acedb;
GRANT ALL ON TABLE alp_func TO apache;
GRANT ALL ON TABLE alp_func TO cecilia;
GRANT ALL ON TABLE alp_func TO azurebrd;
CREATE INDEX alp_func_idx ON alp_func USING btree (joinkey);

CREATE TABLE alp_haplo (
    joinkey text, 
    alp_box text,
    alp_column text,
    alp_haplo text,
    alp_timestamp timestamp with time zone DEFAULT "timestamp"('now'::text));
REVOKE ALL ON TABLE alp_haplo FROM PUBLIC;
GRANT SELECT ON TABLE alp_haplo TO acedb;
GRANT ALL ON TABLE alp_haplo TO apache;
GRANT ALL ON TABLE alp_haplo TO cecilia;
GRANT ALL ON TABLE alp_haplo TO azurebrd;
CREATE INDEX alp_haplo_idx ON alp_haplo USING btree (joinkey);
