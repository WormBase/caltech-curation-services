#!/usr/bin/perl -w

# populate app_ tables based on alp_ tables.  
# Drop and Create the tables and indices with psql -e testdb < app_tables
# Then copy the data with perl.  2007 05 03
#
# added obj_remark table.  2007 08 22
#
# added obj_remark table to the actual table list in app_tables.
# added paper_remark table (DIFFERENT)  2007 08 28
#
# starting over again with unique ID tables and shadow tables.  2008 01 16
#
# prepopulate curation_status with alp_paper papers as happy, and if any from
# alp_finished exist with timestamp use that instead.  2008 03 05

use strict;
use diagnostics;
use Pg;
use LWP::Simple;
use Jex;	# &getPgDate();

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my @tables = qw( wbgene goontology goid paper_evidence person_evidence curator_evidence goinference dbtype protein with qualifier comment lastupdate );

my @ont = qw( bio cell mol );


my %genParams; my %groupParams; my %multParams;		# hash to check type
my %papIds;						# paper identifiers to main papers
&popPapIds();

my %curatorObo;
my $curator_file = get( "http://tazendra.caltech.edu/~azurebrd/var/work/phenote/curator_go.obo" );
my (@entry) = split/\n\n/, $curator_file;
foreach my $entry (@entry) {
  my $name; my $id; 
  if ($entry =~ m/name: (.+)/) { $name = $1; }
  if ($entry =~ m/id: (WBPerson\d+)/) { $id = $1; }
  next unless ($name && $id);
  $curatorObo{$name} = $id;
} # foreach my $entry (@entry)

# foreach my $table (@genParams) { $genParams{$table}++; }
# foreach my $table (@groupParams) { $groupParams{$table}++; }
# foreach my $table (@multParams) { $multParams{$table}++; }

my %alp; my %uns;
foreach my $table (@tables) { &createTable($table); }
&readAlp();
# &populateTables();
# 
# sub populateTables {
#   foreach my $table (@unsure_tables) {
#     foreach my $joinkey (sort keys %uns) { &popUns($joinkey, $table); } }
#   my $joinkey = 0;
#   foreach my $tempname (sort keys %alp) {
#     foreach my $box (sort keys %{ $alp{$tempname}{boxcol} }) {
#       foreach my $col (sort keys %{ $alp{$tempname}{boxcol}{$box} }) {
#         $joinkey++;
#         foreach my $table (sort keys %{ $alp{$tempname} }) {
#           if ($table eq 'boxcol') { 1; }
#           elsif ($table eq 'curation_status') { 1; }	# uns table
#           elsif ($genParams{$table}) { &popGen($joinkey, $tempname, $table); }
#           elsif ($groupParams{$table}) { &popGroup($joinkey, $tempname, $table, $box); }
#           elsif ($table eq 'range') { &popRange($joinkey, $tempname, $table, $box, $col); }
#           elsif ($multParams{$table}) { &popMult($joinkey, $tempname, $table, $box, $col); }
#           else { print "ERR no type grouping table $table for $joinkey $tempname $table\n"; }
#         } # foreach my $table (sort keys %{ $alp{$tempname} })
#       } # foreach my $col (sort keys %{ $alp{$tempname}{boxcol}{$box} })
#     } # foreach my $box (sort keys %{ $alp{$tempname}{boxcol} })
#   } # foreach my $joinkey (sort keys %alp)
# } # sub populateTables

# sub popUns {
#   my ($joinkey, $table) = @_;
#   foreach my $time (sort keys %{ $uns{$joinkey}{$table}{history} }) {
#     my $data = $uns{$joinkey}{$table}{history}{$time};
#     if ($data) { $data = "'$data'"; } else { $data = 'NULL'; }
#     my $command2 = "INSERT INTO app_${table}_hst VALUES ('$joinkey', $data, '$time');";
#     print "$command2\n";
#     my $result = $conn->exec( $command2 ); } 
#   if ($table eq 'curation_status') {	# only put normal table data for curation_status
#     my $data = $uns{$joinkey}{$table}{latest}{data};
#     my $time = $uns{$joinkey}{$table}{latest}{time};
#     return unless ($time && $data);
#     my $command = "INSERT INTO app_$table VALUES ('$joinkey', '$data', '$time');";
#     print "$command\n";
#     my $result = $conn->exec( $command ); } }
# sub popGen {
#   my ($joinkey, $tempname, $table) = @_;
#   my $data = $alp{$tempname}{$table}{latest}{data};
#   my $time = $alp{$tempname}{$table}{latest}{time};
#   return unless ($time && $data);
#   my $command = "INSERT INTO app_$table VALUES ('$joinkey', '$data', '$time');";
#   print "$command\n";
#   my $result = $conn->exec( $command );
#   foreach $time (sort keys %{ $alp{$tempname}{$table}{history} }) {
#     $data = $alp{$tempname}{$table}{history}{$time};
#     if ($data) { $data = "'$data'"; } else { $data = 'NULL'; }
#     my $command2 = "INSERT INTO app_${table}_hst VALUES ('$joinkey', $data, '$time');";
#     print "$command2\n";
#     my $result = $conn->exec( $command2 ); } }
# sub popGroup {
#   my ($joinkey, $tempname, $table, $box) = @_;
#   my $table_name = $table; 
#   if ($table eq 'phenotype') { $table_name = 'nbp'; }
#   if ($table eq 'preparation') { $table_name = 'treatment'; }
#   next if ($table eq 'finished');	# this was put in uns curation_status
#   my $data = $alp{$tempname}{$table}{latest}{$box}{data};
#   if ($table eq 'paper') { $data = &paperFilt($data); }
#   elsif ($table eq 'person') { $data = &personFilt($data); }
#   my $time = $alp{$tempname}{$table}{latest}{$box}{time};
#   return unless ($time && $data);
#   my $command = "INSERT INTO app_$table_name VALUES ('$joinkey', '$data', '$time');";
#   print "$command\n";
#   my $result = $conn->exec( $command );
#   foreach $time (sort keys %{ $alp{$tempname}{$table}{history}{$box} }) {
#     $data = $alp{$tempname}{$table}{history}{$box}{$time};
#     if ($table eq 'paper') { $data = &paperFilt($data); }
#     elsif ($table eq 'person') { $data = &personFilt($data); }
#     if ($data) { $data = "'$data'"; } else { $data = 'NULL'; }
#     my $command2 = "INSERT INTO app_${table_name}_hst VALUES ('$joinkey', $data, '$time');";
#     print "$command2\n";
#     my $result = $conn->exec( $command2 ); } }
# sub popMult {
#   my ($joinkey, $tempname, $table, $box, $col) = @_;
#   my $data = $alp{$tempname}{$table}{latest}{$box}{$col}{data};
#   if ($table eq 'term') { $data = &termFilt($data, 'real', $tempname); }
#   elsif ($table eq 'anat_term') { $data = &anatFilt($data, 'real', $tempname); }
#   elsif ($table eq 'lifestage') { $data = &lsFilt($data, 'real', $tempname); }
#   elsif ($table eq 'curator') { $data = &curatorFilt($data, 'real', $tempname); }
#   elsif ($table eq 'nature') { $data = &natureFilt($data, 'real', $tempname); }
#   elsif ($table eq 'func') { $data = &funcFilt($data, 'real', $tempname); }
#   elsif ($table eq 'penetrance') { $data = &penetranceFilt($data, 'real', $tempname); }
#   elsif ($table eq 'mat_effect') { $data = &mat_effectFilt($data, 'real', $tempname); }
#   my $time = $alp{$tempname}{$table}{latest}{$box}{$col}{time};
#   return unless ($time && $data);
#   if ($data) { $data = "'$data'"; } else { $data = 'NULL'; }
# #   if ($time) { $time = "'$time'"; } else { $time = 'CURRENT_TIMESTAMP'; }
#   unless ($time) { print "NO TIME $table $tempname $box $col\n"; }
#   my $command = "INSERT INTO app_$table VALUES ('$joinkey', $data, '$time');";
#   print "$command\n";
#   my $result = $conn->exec( $command );
#   foreach $time (sort keys %{ $alp{$tempname}{$table}{history}{$box}{$col} }) {
#     $data = $alp{$tempname}{$table}{history}{$box}{$col}{$time};
#     if ($table eq 'term') { $data = &termFilt($data, 'hist'); }
#     elsif ($table eq 'anat_term') { $data = &anatFilt($data, 'hist'); }
#     elsif ($table eq 'lifestage') { $data = &lsFilt($data, 'hist'); }
#     elsif ($table eq 'curator') { $data = &curatorFilt($data, 'hist'); }
#     elsif ($table eq 'nature') { $data = &natureFilt($data, 'hist'); }
#     elsif ($table eq 'func') { $data = &funcFilt($data, 'hist'); }
#     elsif ($table eq 'penetrance') { $data = &penetranceFilt($data, 'hist'); }
#     elsif ($table eq 'mat_effect') { $data = &mat_effectFilt($data, 'hist'); }
#     if ($data) { $data = "'$data'"; } else { $data = 'NULL'; }
#     my $command2 = "INSERT INTO app_${table}_hst VALUES ('$joinkey', $data, '$time');";
#     print "$command2\n"; 
#     my $result = $conn->exec( $command2 ); } }
# sub popRange {
#   my ($joinkey, $tempname, $table, $box, $col) = @_;
#   my $data = $alp{$tempname}{$table}{latest}{$box}{$col}{data};
#   my $time = $alp{$tempname}{$table}{latest}{$box}{$col}{time};
#   return unless ($time && $data); 
#   my $start = $data; my $end = $data;
#   if ($data =~ m/(\d+) (\d+)/) { $start = $1; $end = $2; }
#   if ($data) { $data = "'$data'"; } else { $data = 'NULL'; }
#   unless ($time) { print "NO TIME $table $tempname $box $col\n"; }
#   my $command = "INSERT INTO app_${table}_start VALUES ('$joinkey', $start, '$time');";
#   print "$command\n";
#   my $result = $conn->exec( $command );
#   $command = "INSERT INTO app_${table}_end VALUES ('$joinkey', $end, '$time');";
#   print "$command\n";
#   $result = $conn->exec( $command );
#   foreach $time (sort keys %{ $alp{$tempname}{$table}{history}{$box}{$col} }) {
#     $data = $alp{$tempname}{$table}{history}{$box}{$col}{$time};
#     my $start = $data; my $end = $data;
#     if ($data =~ m/(\d+) (\d+)/) { $start = $1; $end = $2; }
#     if ($data) { $data = "'$data'"; } else { $data = 'NULL'; }
#     my $command2 = "INSERT INTO app_${table}_start_hst VALUES ('$joinkey', $start, '$time');";
#     print "$command2\n"; 
#     my $result = $conn->exec( $command2 ); 
#     $command2 = "INSERT INTO app_${table}_end_hst VALUES ('$joinkey', $end, '$time');";
#     print "$command2\n"; 
#     $result = $conn->exec( $command2 ); } }

# my @multParams = qw ( curator not term phen_remark quantity_remark quantity go_sug suggested sug_ref sug_def genotype lifestage anat_term temperature strain treatment delivered nature penetrance range percent mat_effect pat_effect heat_sens heat_degree cold_sens cold_degree func haplo obj_remark );

sub createTable {
  my $table = shift;
  my $result = $conn->exec( "DROP TABLE gop_${table}_hst;" );
  $result = $conn->exec( "CREATE INDEX gop_${table}_idx ON gop_$table USING btree (joinkey); ");
  $result = $conn->exec( "CREATE TABLE gop_${table}_hst (
    joinkey text, 
    gop_${table}_hst text,
    gop_timestamp timestamp with time zone DEFAULT \"timestamp\"('now'::text)); " );
  $result = $conn->exec( "REVOKE ALL ON TABLE gop_${table}_hst FROM PUBLIC; ");
  $result = $conn->exec( "GRANT SELECT ON TABLE gop_${table}_hst TO acedb; ");
  $result = $conn->exec( "GRANT ALL ON TABLE gop_${table}_hst TO apache; ");
  $result = $conn->exec( "GRANT ALL ON TABLE gop_${table}_hst TO cecilia; ");
  $result = $conn->exec( "GRANT ALL ON TABLE gop_${table}_hst TO azurebrd; ");
  $result = $conn->exec( "CREATE INDEX gop_${table}_hst_idx ON gop_${table}_hst USING btree (joinkey); ");

  $result = $conn->exec( "DROP TABLE gop_$table;" );
  $result = $conn->exec( "CREATE TABLE gop_$table (
    joinkey text, 
    gop_$table text,
    gop_timestamp timestamp with time zone DEFAULT \"timestamp\"('now'::text)); " );
  $result = $conn->exec( "REVOKE ALL ON TABLE gop_$table FROM PUBLIC; ");
  $result = $conn->exec( "GRANT SELECT ON TABLE gop_$table TO acedb; ");
  $result = $conn->exec( "GRANT ALL ON TABLE gop_$table TO apache; ");
  $result = $conn->exec( "GRANT ALL ON TABLE gop_$table TO cecilia; ");
  $result = $conn->exec( "GRANT ALL ON TABLE gop_$table TO azurebrd; ");
}

sub pgcommand {
  my ($type, $table, $joinkey, $data, $time, $genekey, $got_order) = @_;
  if ($type eq 'hst') { $table .= '_hst'; }
  my $command = "INSERT INTO gop_$table VALUES ('$joinkey', $data, '$time');";
  print "$command -- $genekey $got_order\n";
  my $result = $conn->exec( $command ); 
} # sub pgcommand

sub checkSecondary {
  my ($joinkey, $order, $ont) = @_;
  my $flag = 0;
  my @need_to_check = qw( goinference dbtype protein );
  foreach my $table (@need_to_check) {
#     my $result = $conn->exec( "SELECT * FROM got_${ont}_${table}_two WHERE got_${ont}_${table}_two IS NOT NULL AND joinkey = '$joinkey' AND got_order = '$order';" );
#     while (my @row = $result->fetchrow) { if ($row[0]) { $flag++; } } }		# this doesn't work, need to check the most recent values are not null
    my $result = $conn->exec( "SELECT * FROM got_${ont}_${table}_two WHERE joinkey = '$joinkey' AND got_order = '$order' ORDER BY got_timestamp DESC;" );
    my @row = $result->fetchrow;  if ($row[2]) { $flag++; } }
  return $flag;
} # sub checkSecondary

# NEED TO parse curator names into WBPersons
# NEED TO parse curator names into WBPersons

sub readAlp {
# my @tables = qw( wbgene goontology goid paper_evidence person_evidence curator_evidence goinference dbtype protein with qualifier comment lastupdate );
  my @usualtables = qw( goid paper_evidence person_evidence curator_evidence comment lastupdate );
  my @doubletables = qw( goinference dbtype protein with qualifier );
 
  my $joinkey = 0;
  my $result_gene = $conn->exec( "SELECT DISTINCT(joinkey) FROM got_wbgene ORDER BY joinkey;" );
  while (my @row_gene = $result_gene->fetchrow) { 
    if ($row_gene[0]) { my $genekey = $row_gene[0]; 
       next if ($genekey eq 'WBGene00000000');		# skip the test entry
# next unless ($genekey eq 'WBGene00000793');
# next unless ($genekey eq 'WBGene00004952');
# next unless ($genekey eq 'WBGene00003006');
# next unless ($genekey eq 'WBGene00000072');
      foreach my $ont (@ont) {
        my $high_order = 0;
        my $result = $conn->exec( "SELECT * FROM got_${ont}_goid WHERE joinkey = '$genekey' ORDER BY got_order DESC;" );
        my @row = $result->fetchrow; if ($row[0]) { if ($row[1] > $high_order) { $high_order = $row[1]; } }
        $result = $conn->exec( "SELECT * FROM got_${ont}_paper_evidence WHERE joinkey = '$genekey' ORDER BY got_order DESC;" );
        @row = $result->fetchrow; if ($row[0]) { if ($row[1] > $high_order) { $high_order = $row[1]; } }
        if ($high_order > 0) { for my $order ( 1 .. $high_order ) {
          $result = $conn->exec( "SELECT * FROM got_${ont}_paper_evidence WHERE joinkey = '$genekey' AND got_order = '$order' ORDER BY got_timestamp DESC;" );
          @row = $result->fetchrow; my @papers;
          if ($row[2]) {
              my $papers = $row[2]; 
              if ($papers =~ m/\s/) { $papers =~ s/\s+//g; } if ($papers =~ m/\[/) { $papers =~ s/\[//g; } if ($papers =~ m/\]/) { $papers =~ s/\]//g; } 
              if ($papers =~ m/,/) { (@papers) = split/,/, $papers; } else { push @papers, $papers; } }
            else { 
              $result = $conn->exec( "SELECT * FROM got_${ont}_goid WHERE joinkey = '$genekey' AND got_order = '$order' ORDER BY got_timestamp DESC;" );
              @row = $result->fetchrow; if ($row[2]) { print "ERROR $genekey TYPE $ont ORDER $order has no paper\n"; } }
          foreach my $paper (@papers) {
            if ($paper =~ m/WBpaper/) { $paper =~ s/WBpaper/WBPaper/g; }
            if ($papIds{$paper}) { $paper = "$papIds{$paper}"; } else { print "ERROR $paper not in list of paper IDs from $genekey TYPE $ont ORDER $order\n"; }
            $joinkey++;
# print "FOREACH $paper PAPER\n";
            $result = $conn->exec( "SELECT * FROM got_wbgene WHERE joinkey = '$genekey' ORDER BY got_timestamp;" );
            @row = $result->fetchrow; my $table = 'wbgene'; my $data = $row[1]; $data = &filterForPostgres($data); my $time = $row[2];
            &pgcommand('late', $table, $joinkey, "'$data'", $time, $genekey, $order);
            &pgcommand('hst', $table, $joinkey, "'$data'", $time, $genekey, $order);
#             if ($ont eq 'bio') { $data = "'Biological Process'"; }
#             elsif ($ont eq 'mol') { $data = "'Molecular Function'"; }
#             elsif ($ont eq 'cell') { $data = "'Cellular Component'"; } 
            $table = 'goontology'; $data = "'$ont'";
            &pgcommand('late', $table, $joinkey, $data, $time, $genekey, $order);
            &pgcommand('hst', $table, $joinkey, $data, $time, $genekey, $order); 
            foreach my $table (@usualtables, @doubletables) {
              $result = $conn->exec( "SELECT * FROM got_${ont}_$table WHERE joinkey = '$genekey' AND got_order = '$order' ORDER BY got_timestamp DESC;" );
              @row = $result->fetchrow; if ($row[0]) { 
                my $data = 'NULL'; if ($row[2]) { 
                  if ($table eq 'curator_evidence') { $row[2] = &curatorFilt($row[2], 'real', $genekey); }
                  $data = &filterForPostgres($row[2]); $data = "'$data'"; } my $time = $row[3];
                if ($table eq 'paper_evidence') { $data = "'$paper'"; }
                &pgcommand('late', $table, $joinkey, $data, $time, $genekey, $order);
                &pgcommand('hst', $table, $joinkey, $data, $time, $genekey, $order); }
              while (@row = $result->fetchrow) { if ($row[0]) {
                my $data = 'NULL'; if ($row[2]) { 
                  if ($table eq 'curator_evidence') { $row[2] = &curatorFilt($row[2], 'real', $genekey); }
                  $data = &filterForPostgres($row[2]); $data = "'$data'"; } my $time = $row[3];
                &pgcommand('hst', $table, $joinkey, $data, $time, $genekey, $order); 
            } } }
            my ($secondary_flag) = &checkSecondary( $genekey, $order, $ont );
            if ($secondary_flag > 1) {
              $joinkey++;
# print "SEC $secondary_flag FLAG\n";
              $result = $conn->exec( "SELECT * FROM got_wbgene WHERE joinkey = '$genekey' ORDER BY got_timestamp;" );
              @row = $result->fetchrow; my $table = 'wbgene'; my $data = $row[1]; $data = &filterForPostgres($data); my $time = $row[2];
              &pgcommand('late', $table, $joinkey, "'$data'", $time, $genekey, $order);
              &pgcommand('hst', $table, $joinkey, "'$data'", $time, $genekey, $order);
#               if ($ont eq 'bio') { $data = "'Biological Process'"; }
#               elsif ($ont eq 'mol') { $data = "'Molecular Function'"; }
#               elsif ($ont eq 'cell') { $data = "'Cellular Component'"; } 
              $table = 'goontology'; $data = "'$ont'";
              &pgcommand('late', $table, $joinkey, $data, $time, $genekey, $order);
              &pgcommand('hst', $table, $joinkey, $data, $time, $genekey, $order); 
              foreach my $table (@usualtables) {
                $result = $conn->exec( "SELECT * FROM got_${ont}_$table WHERE joinkey = '$genekey' AND got_order = '$order' ORDER BY got_timestamp DESC;" );
                @row = $result->fetchrow; if ($row[0]) { 
                  my $data = 'NULL'; if ($row[2]) { 
                    if ($table eq 'curator_evidence') { $row[2] = &curatorFilt($row[2], 'real', $genekey); }
                    $data = &filterForPostgres($row[2]); $data = "'$data'"; } my $time = $row[3];
                  if ($table eq 'paper_evidence') { $data = "'$paper'"; }
                  &pgcommand('late', $table, $joinkey, $data, $time, $genekey, $order);
                  &pgcommand('hst', $table, $joinkey, $data, $time, $genekey, $order); }
                while (@row = $result->fetchrow) { if ($row[0]) {
                  my $data = 'NULL'; if ($row[2]) { 
                    if ($table eq 'curator_evidence') { $row[2] = &curatorFilt($row[2], 'real', $genekey); }
                    $data = &filterForPostgres($row[2]); $data = "'$data'"; } my $time = $row[3];
                  &pgcommand('hst', $table, $joinkey, $data, $time, $genekey, $order); 
              } } }
              foreach my $table (@doubletables) {
                $result = $conn->exec( "SELECT * FROM got_${ont}_${table}_two WHERE joinkey = '$genekey' AND got_order = '$order' ORDER BY got_timestamp DESC;" );
                @row = $result->fetchrow; if ($row[0]) { 
                  my $data = 'NULL'; if ($row[2]) { $data = &filterForPostgres($row[2]); $data = "'$data'"; } my $time = $row[3];
                  &pgcommand('late', $table, $joinkey, $data, $time, $genekey, $order);
                  &pgcommand('hst', $table, $joinkey, $data, $time, $genekey, $order); }
                while (@row = $result->fetchrow) { if ($row[0]) {
                  my $data = 'NULL'; if ($row[2]) { $data = &filterForPostgres($row[2]); $data = "'$data'"; } my $time = $row[3];
                  &pgcommand('hst', $table, $joinkey, $data, $time, $genekey, $order); 
            } } } }
        } } }
  } } }

#   my %filter; my $pgdate = &getPgDate();	# populate all alp_papers as 'happy'
#   my $result = $conn->exec( "SELECT * FROM alp_paper ORDER BY alp_timestamp;" );
#   while (my @row = $result->fetchrow) { if ($row[0]) { $filter{$row[0]}{$row[1]} = $row[2]; } }
#   foreach my $joinkey (sort keys %filter) {
#     foreach my $order (sort keys %{ $filter{$joinkey} }) {
#       my $data = $filter{$joinkey}{$order};
#       if ($data) { if ($data =~ m/(WBPaper\d+)/) { 
#         $uns{$1}{curation_status}{latest}{data} = 'happy';
#         $uns{$1}{curation_status}{latest}{time} = $pgdate; } } } }

#   foreach my $table (@genParams) {
#     my $result = $conn->exec( "SELECT * FROM alp_$table ORDER BY alp_timestamp;");
#     while (my @row = $result->fetchrow) {
#       my $joinkey = $row[0];
#       my $data = $row[1];
#       $data = &filterForPostgres($data);
#       my $timestamp = $row[2];
#       $alp{$joinkey}{$table}{latest}{data} = $data;
#       $alp{$joinkey}{$table}{latest}{time} = $timestamp;
#       $alp{$joinkey}{$table}{history}{$timestamp} = $data; } }
#   foreach my $table (@groupParams) {
#     my $result = $conn->exec( "SELECT * FROM alp_$table ORDER BY alp_timestamp;");
#     while (my @row = $result->fetchrow) {
#       my $joinkey = $row[0];
#       my $box = $row[1];
#       my $data = $row[2];
#       $data = &filterForPostgres($data);
#       my $timestamp = $row[3];
#       if ($table eq 'finished') {
#           my $table2 = 'curation_status';
#           if ($data) { if ($data eq 'checked') { $data = 'happy'; } else { $data = 'not_happy'; } }
#             else { $data = 'not_happy'; }
#           if ($alp{$joinkey}{paper}{latest}{$box}{data}) { 
#             $joinkey = $alp{$joinkey}{paper}{latest}{$box}{data}; 
#             ($joinkey) = $joinkey =~ m/(WBPaper\d+)/;
#             $uns{$joinkey}{$table2}{history}{$timestamp} = $data;
#             $uns{$joinkey}{$table2}{latest}{data} = $data;
#             $uns{$joinkey}{$table2}{latest}{time} = $timestamp; } }
#         else {
#           $alp{$joinkey}{$table}{history}{$box}{$timestamp} = $data;
#           $alp{$joinkey}{$table}{latest}{$box}{data} = $data;
#           $alp{$joinkey}{$table}{latest}{$box}{time} = $timestamp; } } }
#   foreach my $table (@multParams) {
#     my $result = $conn->exec( "SELECT * FROM alp_$table ORDER BY alp_timestamp;");
#     while (my @row = $result->fetchrow) {
#       my $joinkey = $row[0];
#       my $box = $row[1];
#       my $col = $row[2];
#       $alp{$joinkey}{boxcol}{$box}{$col}++;
#       my $data = $row[3];
#       $data = &filterForPostgres($data);
#       my $timestamp = $row[4];
#       $alp{$joinkey}{$table}{history}{$box}{$col}{$timestamp} = $data;
#       $alp{$joinkey}{$table}{latest}{$box}{$col}{data} = $data;
#       $alp{$joinkey}{$table}{latest}{$box}{$col}{time} = $timestamp; } }
#   foreach my $table (@unsure_tables) {
#     next if ($table eq 'curation_status');	# populate form groupParams
#     my $result = $conn->exec( "SELECT * FROM alp_$table ORDER BY alp_timestamp;");
#     while (my @row = $result->fetchrow) {
#       my $joinkey = $row[1];
#       my $data = $row[2];
#       $data = &filterForPostgres($data);
#       my $timestamp = $row[3];
#       $uns{$joinkey}{$table}{latest}{data} = $data;
#       $uns{$joinkey}{$table}{latest}{time} = $timestamp;
#       $uns{$joinkey}{$table}{history}{$timestamp} = $data; } }
# 
# #   my $result = $conn->exec( "SELECT * FROM alp_finished ORDER BY alp_timestamp;");
# #   while (my @row = $result->fetchrow) {
# #     my $allele = $row[0]; my $box = $row[1]; my $data = $row[2]; my $timestamp = $row[3];
# #     if ($data eq 'checked') { $data = 'happy'; }
# #     if ($alp{$allele}{paper}{latest}{$box}{data}) { 
# #       my $joinkey = $alp{$allele}{paper}{latest}{$box}{data};
# #       ($joinkey) = $joinkey =~ m/(WBPaper\d+)/;
# #       unless ($alp{$joinkey}{finished}{history}) {
# #         $alp{$joinkey}{$table}{history}{$box}{$timestamp} = $data;
# #         $alp{$joinkey}{$table}{latest}{$box}{data} = $data;
# #         $alp{$joinkey}{$table}{latest}{$box}{time} = $timestamp; } } }

} # sub readAlp

sub filterForPostgres {
  my $data = shift;
  if ($data) { if ($data =~ m/'/) { $data =~ s/'/''/g; } }
  if ($data) { if ($data =~ m/^\s+/) { $data =~ s/^\s+//g; } }
  if ($data) { if ($data =~ m/\s+$/) { $data =~ s/\s+$//g; } }
  return $data;
} # sub filterForPostgres

sub curatorFilt {
  my ($data, $hist, $tempname) = @_;
  unless ($data) { return $data; }
  my $curator = $data; # if ($curator =~ m/WBPerson/) { $curator =~ s/WBPerson/WBcurator/g; }
  if ($data =~ m/(WBPerson\d+)/) { 
    my ($person) = $data =~ m/(WBPerson\d+)/g; 
    $data = $person; }
  elsif ($curatorObo{$curator}) { 
    $data = $curatorObo{$curator}; }
  else { if ($hist eq 'real') { print "ERR $data not right for $tempname curator\n"; } }
#   $data = "\"$data\"";
  return $data;
} # sub curatorFilt

sub popPapIds {
  my $result = $conn->exec( "SELECT * FROM wpa_identifier WHERE wpa_identifier IS NOT NULL ORDER BY wpa_timestamp; ");
  while (my @row = $result->fetchrow) { if ($row[3] eq 'valid') { 
    $papIds{$row[1]} = "WBPaper$row[0]"; $papIds{"WBPaper$row[0]"} = "WBPaper$row[0]"; 
    if ($row[1] =~ m/pmid/) { $row[1] =~ s/pmid/PMID:/; $papIds{$row[1]} = "WBPaper$row[0]"; }
  } }
} # sub popPapIds


__END__

sub lsFilt {
  my ($data, $hist, $tempname) = @_;
  unless ($data) { return $data; }
  my @values = (); my @ids;
  if ($data =~ m/\|/) { (@values) = split/\|/, $data; }
    else { push @values, $data; }
  foreach my $value (@values) { 
    if ($lsObo{$value}) { push @ids, $lsObo{$value}; }
    else { if ($hist eq 'real') { print "ERR $value not right for $tempname -=${data}=- lifestage\n"; } }
  } # foreach my $value (@values) 
  $data = join"\",\"", @ids;
  $data = "\"$data\"";
  return $data;
} # sub lsFilt
sub anatFilt {
  my ($data, $hist, $tempname) = @_;
  unless ($data) { return $data; }
  my @values = (); my @ids;
  if ($data =~ m/\|/) { (@values) = split/\|/, $data; }
    else { push @values, $data; }
  foreach my $value (@values) { 
    if ($anatObo{$value}) { push @ids, $anatObo{$value}; }
    elsif ($value =~ m/WBbt:\d+/) { push @ids, $value; }
    elsif ($value =~ m/WBbt\d+/) { $value =~ s/WBbt/WBbt:/; push @ids, $value; }
    else { if ($hist eq 'real') { print "ERR $value not right for $tempname -=${data}=- anat_term\n"; } }
  } # foreach my $value (@values) 
  $data = join"\",\"", @ids;
  $data = "\"$data\"";
  return $data;
} # sub anatFilt

sub natureFilt {
  my ($data, $hist, $tempname) = @_;
  unless ($data) { return $data; }
  if ($data =~ m/^(\w+)/) { $data = $1; }
  if ($natureObo{$data}) { $data = $natureObo{$data}; }
    else { if ($hist eq 'real') { print "ERR $data not right for $tempname nature\n"; } }
#   $data = "\"$data\"";
  return $data;
} # sub natureFilt
sub funcFilt {
  my ($data, $hist, $tempname) = @_;
  unless ($data) { return $data; }
  if ($data =~ m/^(\w+)/) { $data = $1; }
  if ($funcObo{$data}) { $data = $funcObo{$data}; }
    else { if ($hist eq 'real') { print "ERR $data not right for $tempname func\n"; } }
#   $data = "\"$data\"";
  return $data;
} # sub funcFilt
sub penetranceFilt {
  my ($data, $hist, $tempname) = @_;
  unless ($data) { return $data; }
  if ($data =~ m/^(\w+)/) { $data = $1; }
  if ($penetranceObo{$data}) { $data = $penetranceObo{$data}; }
    else { if ($hist eq 'real') { print "ERR $data not right for $tempname penetrance\n"; } }
#   $data = "\"$data\"";
  return $data;
} # sub penetranceFilt
sub mat_effectFilt {
  my ($data, $hist, $tempname) = @_;
  unless ($data) { return $data; }
  if ($data =~ m/^(\w+)/) { $data = $1; }
  if ($mat_effectObo{$data}) { $data = $mat_effectObo{$data}; }
    else { if ($hist eq 'real') { print "ERR $data not right for $tempname mat_effect\n"; } }
#   $data = "\"$data\"";
  return $data;
} # sub mat_effectFilt
sub personFilt {
  my ($data, $hist, $tempname) = @_;
  unless ($data) { return $data; }
  if ($data =~ m/(WBPerson\d+)/) { 
      my (@ppl) = $data =~ m/(WBPerson\d+)/g; 
      $data = join"\",\"", @ppl; }
    else { if ($hist eq 'real') { print "ERR $data not right for $tempname person\n"; } }
  $data = "\"$data\"";
  return $data;
} # sub personFilt

sub termFilt {
  my ($data, $hist, $tempname) = @_;
  unless ($data) { return $data; }
  if ($data =~ m/(WBPhenotype\d+)/) { $data = $1; }
    else { if ($hist eq 'real') { print "ERR $data not right for $tempname term\n"; } }
  return $data;
} # sub termFilt
sub paperFilt {
  my ($data, $hist, $tempname) = @_;
  unless ($data) { return $data; }
  if ($data =~ m/(WBPaper\d+)/) { $data = $1; }
    else { if ($hist eq 'real') { print "ERR $data not right for $tempname paper\n"; } }
  return $data;
} # sub paperFilt


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


gop_wbgene
gop_goontology
gop_goid
gop_paper_evidence
gop_person_evidence
gop_curator_evidence
gop_goinference
gop_dbtype
gop_protein
gop_with
gop_qualifier
gop_comment
gop_lastupdate


__END__


my %natureObo;
my $nature_file = get( "http://tazendra.caltech.edu/~azurebrd/var/work/phenote/nature.obo" );
(@entry) = split/\n\n/, $nature_file;
foreach my $entry (@entry) {
  my $name; my $id; 
  if ($entry =~ m/name: (.+)/) { $name = $1; }
  if ($entry =~ m/id: (WBnature\d+)/) { $id = $1; }
  next unless ($name && $id);
  $natureObo{$name} = $id;
} # foreach my $entry (@entry)

my %funcObo;
my $func_file = get( "http://tazendra.caltech.edu/~azurebrd/var/work/phenote/func.obo" );
(@entry) = split/\n\n/, $func_file;
foreach my $entry (@entry) {
  my $name; my $id; 
  if ($entry =~ m/name: (.+)/) { $name = $1; }
  if ($entry =~ m/id: (WBfunc\d+)/) { $id = $1; }
  next unless ($name && $id);
  $funcObo{$name} = $id;
} # foreach my $entry (@entry)

my %penetranceObo;
my $penetrance_file = get( "http://tazendra.caltech.edu/~azurebrd/var/work/phenote/penetrance.obo" );
(@entry) = split/\n\n/, $penetrance_file;
foreach my $entry (@entry) {
  my $name; my $id; 
  if ($entry =~ m/name: (.+)/) { $name = $1; }
  if ($entry =~ m/id: (WBpenetrance\d+)/) { $id = $1; }
  next unless ($name && $id);
  $penetranceObo{$name} = $id;
} # foreach my $entry (@entry)

my %mat_effectObo;
my $mat_effect_file = get( "http://tazendra.caltech.edu/~azurebrd/var/work/phenote/mat_effect.obo" );
(@entry) = split/\n\n/, $mat_effect_file;
foreach my $entry (@entry) {
  my $name; my $id; 
  if ($entry =~ m/name: (.+)/) { $name = $1; }
  if ($entry =~ m/id: (WBmat_effect\d+)/) { $id = $1; }
  next unless ($name && $id);
  $mat_effectObo{$name} = $id;
} # foreach my $entry (@entry)

my %anatObo;
my $anat_file = get( "http://www.berkeleybop.org/ontologies/obo-all/worm_anatomy/worm_anatomy.obo" );
(@entry) = split/\n\n/, $anat_file;
foreach my $entry (@entry) {
  my $name; my $id; 
  if ($entry =~ m/name: (.+)\n/) { $name = $1; }
  if ($entry =~ m/id: (WBbt:\d+)\n/) { $id = $1; }
  next unless ($name && $id);
  $anatObo{$name} = $id;
} # foreach my $entry (@entry)

my %lsObo;
# my $ls_file = get( "http://www.berkeleybop.org/ontologies/obo-all/worm_development/worm_development.obo" );
my $ls_file = get( "http://tazendra.caltech.edu/~azurebrd/var/work/phenote/worm_development.obo" );
(@entry) = split/\n\n/, $ls_file;
foreach my $entry (@entry) {
  my $name; my $id; 
  next unless ($entry =~ m/\[Term\]/);
  if ($entry =~ m/name: (.+)/) { 
    $name = $1; 
    if ($name =~ m/name: (.+)\n/) { $name = $1; } }
  if ($entry =~ m/id: (.+)/) { $id = $1; }
#     if ($id =~ m/id: (.+)\n/) { $id = $1; } }
#   print "N $name ID $id E\n";
#   unless ($name && $id) { print "NO $entry NO\n"; }
#   unless ($id) { print "NO ID $entry NO\n"; }
#   unless ($name) { print "NO NAME $entry NO\n"; }
  next unless ($name && $id);
  $lsObo{$name} = $id;
} # foreach my $entry (@entry)


