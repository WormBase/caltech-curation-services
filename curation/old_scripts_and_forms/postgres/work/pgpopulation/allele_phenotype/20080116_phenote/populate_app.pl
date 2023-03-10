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

# my @tables = qw( anat_term cold_degree cold_sens curator delivered finalname finished func genotype go_sug haplo heat_degree heat_sens intx_desc lifestage mat_effect nature not paper pat_effect penetrance percent person phen_remark phenotype quantity quantity_remark range paper_remark rnai_brief strain sug_def sug_ref suggested temperature tempname term treatment type wbgene obj_remark );

# my @one_per_tempname_tables = qw( tempname finalname wbgene );
my @one_per_tempname_tables = qw( tempname );
# NEED TO CREATE wbgene table, rename tempname to objname

my @unsure_tables = qw( paper_remark curation_status );		# store this by paper

my @new_tables = qw(entity quality suggested laboratory allele_status);

# my @tables = qw( anat_term cold_degree cold_sens curator delivered finished func genotype go_sug haplo heat_degree heat_sens intx_desc lifestage mat_effect nature not paper pat_effect penetrance percent person phen_remark nbp quantity quantity_remark range_start range_end paper_remark rnai_brief strain sug_def sug_ref suggested temperature term treatment type obj_remark );
my @tables = qw( anat_term cold_degree cold_sens curator func genotype haplo heat_degree heat_sens intx_desc lifestage mat_effect nature not paper pat_effect penetrance percent person phen_remark nbp quantity quantity_remark range_start range_end paper_remark rnai_brief strain temperature term treatment type obj_remark );

# my @genParams = qw ( type tempname finalname wbgene rnai_brief );
my @genParams = qw ( type tempname );
my @groupParams = qw ( paper person finished phenotype remark intx_desc );
# my @groupParams = qw ( paper person phenotype paper_remark intx_desc);
my @multParams = qw ( curator not term phen_remark quantity_remark quantity go_sug suggested sug_ref sug_def genotype lifestage anat_term temperature strain treatment delivered nature penetrance range percent mat_effect pat_effect heat_sens heat_degree cold_sens cold_degree func haplo obj_remark );

# NEED TO populate 
# paper with WBPaper, 
# person with "WBPerson", "WBPerson", 
# term with WBPhenotype values,
# anat_term with http://www.berkeleybop.org/ontologies/obo-all/worm_anatomy/worm_anatomy.obo
# lifestage with http://www.berkeleybop.org/ontologies/obo-all/worm_development/worm_development.obo

my %curatorObo;
my $curator_file = get( "http://tazendra.caltech.edu/~azurebrd/var/work/phenote/curator.obo" );
my (@entry) = split/\n\n/, $curator_file;
foreach my $entry (@entry) {
  my $name; my $id; 
  if ($entry =~ m/name: (.+)/) { $name = $1; }
  if ($entry =~ m/id: (WBcurator\d+)/) { $id = $1; }
  next unless ($name && $id);
  $curatorObo{$name} = $id;
} # foreach my $entry (@entry)

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


my %genParams; my %groupParams; my %multParams;		# hash to check type

foreach my $table (@genParams) { $genParams{$table}++; }
foreach my $table (@groupParams) { $groupParams{$table}++; }
foreach my $table (@multParams) { $multParams{$table}++; }

my %alp; my %uns;
&readAlp();
foreach my $table (@tables) { &createTable($table); }
foreach my $table (@one_per_tempname_tables) { &createTable($table); }
foreach my $table (@unsure_tables) { &createTable($table); }
foreach my $table (@new_tables) { &createTable($table); }
&populateTables();

sub populateTables {
  foreach my $table (@unsure_tables) {
    foreach my $joinkey (sort keys %uns) { &popUns($joinkey, $table); } }
  my $joinkey = 0;
  foreach my $tempname (sort keys %alp) {
    foreach my $box (sort keys %{ $alp{$tempname}{boxcol} }) {
      foreach my $col (sort keys %{ $alp{$tempname}{boxcol}{$box} }) {
        $joinkey++;
        foreach my $table (sort keys %{ $alp{$tempname} }) {
          if ($table eq 'boxcol') { 1; }
          elsif ($table eq 'curation_status') { 1; }	# uns table
          elsif ($genParams{$table}) { &popGen($joinkey, $tempname, $table); }
          elsif ($groupParams{$table}) { &popGroup($joinkey, $tempname, $table, $box); }
          elsif ($table eq 'range') { &popRange($joinkey, $tempname, $table, $box, $col); }
          elsif ($multParams{$table}) { &popMult($joinkey, $tempname, $table, $box, $col); }
          else { print "ERR no type grouping table $table for $joinkey $tempname $table\n"; }
        } # foreach my $table (sort keys %{ $alp{$tempname} })
      } # foreach my $col (sort keys %{ $alp{$tempname}{boxcol}{$box} })
    } # foreach my $box (sort keys %{ $alp{$tempname}{boxcol} })
  } # foreach my $joinkey (sort keys %alp)
} # sub populateTables

sub popUns {
  my ($joinkey, $table) = @_;
  foreach my $time (sort keys %{ $uns{$joinkey}{$table}{history} }) {
    my $data = $uns{$joinkey}{$table}{history}{$time};
    if ($data) { $data = "'$data'"; } else { $data = 'NULL'; }
    my $command2 = "INSERT INTO app_${table}_hst VALUES ('$joinkey', $data, '$time');";
    print "$command2\n";
    my $result = $conn->exec( $command2 ); } 
  if ($table eq 'curation_status') {	# only put normal table data for curation_status
    my $data = $uns{$joinkey}{$table}{latest}{data};
    my $time = $uns{$joinkey}{$table}{latest}{time};
    return unless ($time && $data);
    my $command = "INSERT INTO app_$table VALUES ('$joinkey', '$data', '$time');";
    print "$command\n";
    my $result = $conn->exec( $command ); } }
sub popGen {
  my ($joinkey, $tempname, $table) = @_;
  my $data = $alp{$tempname}{$table}{latest}{data};
  my $time = $alp{$tempname}{$table}{latest}{time};
  return unless ($time && $data);
  my $command = "INSERT INTO app_$table VALUES ('$joinkey', '$data', '$time');";
  print "$command\n";
  my $result = $conn->exec( $command );
  foreach $time (sort keys %{ $alp{$tempname}{$table}{history} }) {
    $data = $alp{$tempname}{$table}{history}{$time};
    if ($data) { $data = "'$data'"; } else { $data = 'NULL'; }
    my $command2 = "INSERT INTO app_${table}_hst VALUES ('$joinkey', $data, '$time');";
    print "$command2\n";
    my $result = $conn->exec( $command2 ); } }
sub popGroup {
  my ($joinkey, $tempname, $table, $box) = @_;
  my $table_name = $table; 
  if ($table eq 'phenotype') { $table_name = 'nbp'; }
  if ($table eq 'preparation') { $table_name = 'treatment'; }
  next if ($table eq 'finished');	# this was put in uns curation_status
  my $data = $alp{$tempname}{$table}{latest}{$box}{data};
  if ($table eq 'paper') { $data = &paperFilt($data); }
  elsif ($table eq 'person') { $data = &personFilt($data); }
  my $time = $alp{$tempname}{$table}{latest}{$box}{time};
  return unless ($time && $data);
  my $command = "INSERT INTO app_$table_name VALUES ('$joinkey', '$data', '$time');";
  print "$command\n";
  my $result = $conn->exec( $command );
  foreach $time (sort keys %{ $alp{$tempname}{$table}{history}{$box} }) {
    $data = $alp{$tempname}{$table}{history}{$box}{$time};
    if ($table eq 'paper') { $data = &paperFilt($data); }
    elsif ($table eq 'person') { $data = &personFilt($data); }
    if ($data) { $data = "'$data'"; } else { $data = 'NULL'; }
    my $command2 = "INSERT INTO app_${table_name}_hst VALUES ('$joinkey', $data, '$time');";
    print "$command2\n";
    my $result = $conn->exec( $command2 ); } }
sub popMult {
  my ($joinkey, $tempname, $table, $box, $col) = @_;
  my $data = $alp{$tempname}{$table}{latest}{$box}{$col}{data};
  if ($table eq 'term') { $data = &termFilt($data, 'real', $tempname); }
  elsif ($table eq 'anat_term') { $data = &anatFilt($data, 'real', $tempname); }
  elsif ($table eq 'lifestage') { $data = &lsFilt($data, 'real', $tempname); }
  elsif ($table eq 'curator') { $data = &curatorFilt($data, 'real', $tempname); }
  elsif ($table eq 'nature') { $data = &natureFilt($data, 'real', $tempname); }
  elsif ($table eq 'func') { $data = &funcFilt($data, 'real', $tempname); }
  elsif ($table eq 'penetrance') { $data = &penetranceFilt($data, 'real', $tempname); }
  elsif ($table eq 'mat_effect') { $data = &mat_effectFilt($data, 'real', $tempname); }
  my $time = $alp{$tempname}{$table}{latest}{$box}{$col}{time};
  return unless ($time && $data);
  if ($data) { $data = "'$data'"; } else { $data = 'NULL'; }
#   if ($time) { $time = "'$time'"; } else { $time = 'CURRENT_TIMESTAMP'; }
  unless ($time) { print "NO TIME $table $tempname $box $col\n"; }
  my $command = "INSERT INTO app_$table VALUES ('$joinkey', $data, '$time');";
  print "$command\n";
  my $result = $conn->exec( $command );
  foreach $time (sort keys %{ $alp{$tempname}{$table}{history}{$box}{$col} }) {
    $data = $alp{$tempname}{$table}{history}{$box}{$col}{$time};
    if ($table eq 'term') { $data = &termFilt($data, 'hist'); }
    elsif ($table eq 'anat_term') { $data = &anatFilt($data, 'hist'); }
    elsif ($table eq 'lifestage') { $data = &lsFilt($data, 'hist'); }
    elsif ($table eq 'curator') { $data = &curatorFilt($data, 'hist'); }
    elsif ($table eq 'nature') { $data = &natureFilt($data, 'hist'); }
    elsif ($table eq 'func') { $data = &funcFilt($data, 'hist'); }
    elsif ($table eq 'penetrance') { $data = &penetranceFilt($data, 'hist'); }
    elsif ($table eq 'mat_effect') { $data = &mat_effectFilt($data, 'hist'); }
    if ($data) { $data = "'$data'"; } else { $data = 'NULL'; }
    my $command2 = "INSERT INTO app_${table}_hst VALUES ('$joinkey', $data, '$time');";
    print "$command2\n"; 
    my $result = $conn->exec( $command2 ); } }
sub popRange {
  my ($joinkey, $tempname, $table, $box, $col) = @_;
  my $data = $alp{$tempname}{$table}{latest}{$box}{$col}{data};
  my $time = $alp{$tempname}{$table}{latest}{$box}{$col}{time};
  return unless ($time && $data); 
  my $start = $data; my $end = $data;
  if ($data =~ m/(\d+) (\d+)/) { $start = $1; $end = $2; }
  if ($data) { $data = "'$data'"; } else { $data = 'NULL'; }
  unless ($time) { print "NO TIME $table $tempname $box $col\n"; }
  my $command = "INSERT INTO app_${table}_start VALUES ('$joinkey', $start, '$time');";
  print "$command\n";
  my $result = $conn->exec( $command );
  $command = "INSERT INTO app_${table}_end VALUES ('$joinkey', $end, '$time');";
  print "$command\n";
  $result = $conn->exec( $command );
  foreach $time (sort keys %{ $alp{$tempname}{$table}{history}{$box}{$col} }) {
    $data = $alp{$tempname}{$table}{history}{$box}{$col}{$time};
    my $start = $data; my $end = $data;
    if ($data =~ m/(\d+) (\d+)/) { $start = $1; $end = $2; }
    if ($data) { $data = "'$data'"; } else { $data = 'NULL'; }
    my $command2 = "INSERT INTO app_${table}_start_hst VALUES ('$joinkey', $start, '$time');";
    print "$command2\n"; 
    my $result = $conn->exec( $command2 ); 
    $command2 = "INSERT INTO app_${table}_end_hst VALUES ('$joinkey', $end, '$time');";
    print "$command2\n"; 
    $result = $conn->exec( $command2 ); } }

# my @multParams = qw ( curator not term phen_remark quantity_remark quantity go_sug suggested sug_ref sug_def genotype lifestage anat_term temperature strain treatment delivered nature penetrance range percent mat_effect pat_effect heat_sens heat_degree cold_sens cold_degree func haplo obj_remark );

sub createTable {
  my $table = shift;
  my $result = $conn->exec( "DROP TABLE app_${table}_hst;" );
  $result = $conn->exec( "CREATE INDEX app_${table}_idx ON app_$table USING btree (joinkey); ");
  $result = $conn->exec( "CREATE TABLE app_${table}_hst (
    joinkey text, 
    app_${table}_hst text,
    app_timestamp timestamp with time zone DEFAULT \"timestamp\"('now'::text)); " );
  $result = $conn->exec( "REVOKE ALL ON TABLE app_${table}_hst FROM PUBLIC; ");
  $result = $conn->exec( "GRANT SELECT ON TABLE app_${table}_hst TO acedb; ");
  $result = $conn->exec( "GRANT ALL ON TABLE app_${table}_hst TO apache; ");
  $result = $conn->exec( "GRANT ALL ON TABLE app_${table}_hst TO cecilia; ");
  $result = $conn->exec( "GRANT ALL ON TABLE app_${table}_hst TO azurebrd; ");
  $result = $conn->exec( "CREATE INDEX app_${table}_hst_idx ON app_${table}_hst USING btree (joinkey); ");

  return if ( ($table eq 'paper_remark') );	# these tables only have history data
  $result = $conn->exec( "DROP TABLE app_$table;" );
  $result = $conn->exec( "CREATE TABLE app_$table (
    joinkey text, 
    app_$table text,
    app_timestamp timestamp with time zone DEFAULT \"timestamp\"('now'::text)); " );
  $result = $conn->exec( "REVOKE ALL ON TABLE app_$table FROM PUBLIC; ");
  $result = $conn->exec( "GRANT SELECT ON TABLE app_$table TO acedb; ");
  $result = $conn->exec( "GRANT ALL ON TABLE app_$table TO apache; ");
  $result = $conn->exec( "GRANT ALL ON TABLE app_$table TO cecilia; ");
  $result = $conn->exec( "GRANT ALL ON TABLE app_$table TO azurebrd; ");
}

sub readAlp {
  my %filter; my $pgdate = &getPgDate();	# populate all alp_papers as 'happy'
  my $result = $conn->exec( "SELECT * FROM alp_paper ORDER BY alp_timestamp;" );
  while (my @row = $result->fetchrow) { if ($row[0]) { $filter{$row[0]}{$row[1]} = $row[2]; } }
  foreach my $joinkey (sort keys %filter) {
    foreach my $order (sort keys %{ $filter{$joinkey} }) {
      my $data = $filter{$joinkey}{$order};
      if ($data) { if ($data =~ m/(WBPaper\d+)/) { 
        $uns{$1}{curation_status}{latest}{data} = 'happy';
        $uns{$1}{curation_status}{latest}{time} = $pgdate; } } } }

  foreach my $table (@genParams) {
    my $result = $conn->exec( "SELECT * FROM alp_$table ORDER BY alp_timestamp;");
    while (my @row = $result->fetchrow) {
      my $joinkey = $row[0];
      my $data = $row[1];
      $data = &filterForPostgres($data);
      my $timestamp = $row[2];
      $alp{$joinkey}{$table}{latest}{data} = $data;
      $alp{$joinkey}{$table}{latest}{time} = $timestamp;
      $alp{$joinkey}{$table}{history}{$timestamp} = $data; } }
  foreach my $table (@groupParams) {
    my $result = $conn->exec( "SELECT * FROM alp_$table ORDER BY alp_timestamp;");
    while (my @row = $result->fetchrow) {
      my $joinkey = $row[0];
      my $box = $row[1];
      my $data = $row[2];
      $data = &filterForPostgres($data);
      my $timestamp = $row[3];
      if ($table eq 'finished') {
          my $table2 = 'curation_status';
          if ($data) { if ($data eq 'checked') { $data = 'happy'; } else { $data = 'not_happy'; } }
            else { $data = 'not_happy'; }
          if ($alp{$joinkey}{paper}{latest}{$box}{data}) { 
            $joinkey = $alp{$joinkey}{paper}{latest}{$box}{data}; 
            ($joinkey) = $joinkey =~ m/(WBPaper\d+)/;
            $uns{$joinkey}{$table2}{history}{$timestamp} = $data;
            $uns{$joinkey}{$table2}{latest}{data} = $data;
            $uns{$joinkey}{$table2}{latest}{time} = $timestamp; } }
        else {
          $alp{$joinkey}{$table}{history}{$box}{$timestamp} = $data;
          $alp{$joinkey}{$table}{latest}{$box}{data} = $data;
          $alp{$joinkey}{$table}{latest}{$box}{time} = $timestamp; } } }
  foreach my $table (@multParams) {
    my $result = $conn->exec( "SELECT * FROM alp_$table ORDER BY alp_timestamp;");
    while (my @row = $result->fetchrow) {
      my $joinkey = $row[0];
      my $box = $row[1];
      my $col = $row[2];
      $alp{$joinkey}{boxcol}{$box}{$col}++;
      my $data = $row[3];
      $data = &filterForPostgres($data);
      my $timestamp = $row[4];
      $alp{$joinkey}{$table}{history}{$box}{$col}{$timestamp} = $data;
      $alp{$joinkey}{$table}{latest}{$box}{$col}{data} = $data;
      $alp{$joinkey}{$table}{latest}{$box}{$col}{time} = $timestamp; } }
  foreach my $table (@unsure_tables) {
    next if ($table eq 'curation_status');	# populate form groupParams
    my $result = $conn->exec( "SELECT * FROM alp_$table ORDER BY alp_timestamp;");
    while (my @row = $result->fetchrow) {
      my $joinkey = $row[1];
      my $data = $row[2];
      $data = &filterForPostgres($data);
      my $timestamp = $row[3];
      $uns{$joinkey}{$table}{latest}{data} = $data;
      $uns{$joinkey}{$table}{latest}{time} = $timestamp;
      $uns{$joinkey}{$table}{history}{$timestamp} = $data; } }

#   my $result = $conn->exec( "SELECT * FROM alp_finished ORDER BY alp_timestamp;");
#   while (my @row = $result->fetchrow) {
#     my $allele = $row[0]; my $box = $row[1]; my $data = $row[2]; my $timestamp = $row[3];
#     if ($data eq 'checked') { $data = 'happy'; }
#     if ($alp{$allele}{paper}{latest}{$box}{data}) { 
#       my $joinkey = $alp{$allele}{paper}{latest}{$box}{data};
#       ($joinkey) = $joinkey =~ m/(WBPaper\d+)/;
#       unless ($alp{$joinkey}{finished}{history}) {
#         $alp{$joinkey}{$table}{history}{$box}{$timestamp} = $data;
#         $alp{$joinkey}{$table}{latest}{$box}{data} = $data;
#         $alp{$joinkey}{$table}{latest}{$box}{time} = $timestamp; } } }

} # sub readAlp

sub filterForPostgres {
  my $data = shift;
  if ($data) { if ($data =~ m/'/) { $data =~ s/'/''/g; } }
  if ($data) { if ($data =~ m/^\s+/) { $data =~ s/^\s+//g; } }
  if ($data) { if ($data =~ m/\s+$/) { $data =~ s/\s+$//g; } }
  return $data;
} # sub filterForPostgres

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

sub curatorFilt {
  my ($data, $hist, $tempname) = @_;
  unless ($data) { return $data; }
  my $curator = $data; if ($curator =~ m/WBPerson/) { $curator =~ s/WBPerson/WBcurator/g; }
  if ($data =~ m/(WBPerson\d+)/) { 
    my ($person) = $data =~ m/(WBPerson\d+)/g; 
    $person =~ s/WBPerson/WBcurator/g;
    $data = $person; }
  elsif ($curatorObo{$curator}) { 
    $data = $curatorObo{$curator}; }
  else { if ($hist eq 'real') { print "ERR $data not right for $tempname curator\n"; } }
#   $data = "\"$data\"";
  return $data;
} # sub curatorFilt
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

`psql -e testdb < app_tables`;

my $directory = '/home/postgres/work/pgpopulation/allele_phenotype/20080116/dumps';
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
