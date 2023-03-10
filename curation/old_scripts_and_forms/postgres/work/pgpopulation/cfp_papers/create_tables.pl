#!/usr/bin/perl -w

# create cfp tables for curator first pass flagging   2009 03 16
# added structcorr sanger and stlouis into structcorr, added stlouissnp into newsnp
# if data already existed in non-curator case, append instead of replace.  check
# timestamp and use most recent.   
# use structureinformation for structinfo and domanal.  2009 03 21
#
# created a cfp_curator table, it has a cfp_curatr column in the third column
# (row[2]) because it repeats the same data as the second column and cannot have
# the same name.  was not escaping ' in data.  2009 03 23
#
# real run 2009 04 06


use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $result = '';

my @newtables = qw ( curator celegans cnonbristol nematode nonnematode genestudied genesymbol extvariation mappingdata newmutant rnai lsrnai overexpr chemicals mosaic siteaction timeaction genefunc humdis geneint funccomp geneprod otherexpr microarray genereg seqfeat matrices antibody transgene marker invitro domanal covalent structinfo massspec structcorr seqchange newsnp ablationdata cellfunc phylogenetic othersilico supplemental nocuratable comment);

my @pgcommands;

# UNCOMMENT TO CREATE TABLES
# foreach my $table (@newtables) {
#   my $table1 = 'cfp_' . $table ;
#   push @pgcommands, "CREATE TABLE $table1 ( joinkey text, $table1 text, cfp_curator text, cfp_timestamp timestamp with time zone DEFAULT \"timestamp\"('now'::text) );" ;
#   push @pgcommands, "CREATE UNIQUE INDEX ${table1}_idx ON $table1 USING btree (joinkey);" ;
#   push @pgcommands,"REVOKE ALL ON TABLE $table1 FROM PUBLIC; ";
#   push @pgcommands,"GRANT ALL ON TABLE $table1 TO postgres; ";
#   push @pgcommands,"GRANT ALL ON TABLE $table1 TO acedb; ";
#   push @pgcommands,"GRANT ALL ON TABLE $table1 TO apache; ";
#   push @pgcommands,"GRANT ALL ON TABLE $table1 TO azurebrd; ";
#   push @pgcommands,"GRANT ALL ON TABLE $table1 TO cecilia; ";
#   my $table2 = 'cfp_' . $table . '_hst';
#   push @pgcommands, "CREATE TABLE $table2 ( joinkey text, $table2 text, cfp_curator text, cfp_timestamp timestamp with time zone DEFAULT \"timestamp\"('now'::text) );" ;
#   push @pgcommands, "CREATE INDEX ${table2}_idx ON $table2 USING btree (joinkey);" ;
#   push @pgcommands,"REVOKE ALL ON TABLE $table2 FROM PUBLIC; ";
#   push @pgcommands,"GRANT ALL ON TABLE $table2 TO postgres; ";
#   push @pgcommands,"GRANT ALL ON TABLE $table2 TO acedb; ";
#   push @pgcommands,"GRANT ALL ON TABLE $table2 TO apache; ";
#   push @pgcommands,"GRANT ALL ON TABLE $table2 TO azurebrd; ";
#   push @pgcommands,"GRANT ALL ON TABLE $table2 TO cecilia; ";
#   next if $table eq 'curator';
#   my $table3 = 'tfp_' . $table ;
#   push @pgcommands, "CREATE TABLE $table3 ( joinkey text, $table3 text, tfp_timestamp timestamp with time zone DEFAULT \"timestamp\"('now'::text) );" ;
#   push @pgcommands, "CREATE UNIQUE INDEX ${table3}_idx ON $table3 USING btree (joinkey);" ;
#   push @pgcommands,"REVOKE ALL ON TABLE $table3 FROM PUBLIC; ";
#   push @pgcommands,"GRANT ALL ON TABLE $table3 TO postgres; ";
#   push @pgcommands,"GRANT ALL ON TABLE $table3 TO acedb; ";
#   push @pgcommands,"GRANT ALL ON TABLE $table3 TO apache; ";
#   push @pgcommands,"GRANT ALL ON TABLE $table3 TO azurebrd; ";
#   push @pgcommands,"GRANT ALL ON TABLE $table3 TO cecilia; ";
# }
# foreach my $pgcommand (@pgcommands) {
#   print "$pgcommand\n";
#   my $result = $conn->exec( $pgcommand );
# }

my %map;	# (old tables to new tables)
$map{'ablationdata'} = 'ablationdata';
$map{'geneinteractions'} = 'geneint';
$map{'newsymbol'} = '';
$map{'antibody'} = 'antibody';
$map{'geneproduct'} = 'geneprod';
$map{'nonntwo'} = 'nematode';
$map{'associationequiv'} = '';
$map{'generegulation'} = 'genereg';
$map{'overexpression'} = 'overexpr';
$map{'associationnew'} = '';
$map{'genesymbol'} = 'genesymbol';
$map{'rnai'} = 'rnai';
$map{'cellfunction'} = 'cellfunc';
$map{'genesymbols'} = '';
$map{'sequencechange'} = 'seqchange';
$map{'cellname'} = '';
$map{'goodphoto'} = '';
$map{'sequencefeatures'} = 'seqfeat';
$map{'chemicals'} = 'chemicals';
$map{'humandiseases'} = 'humdis';
$map{'site'} = 'siteaction';
$map{'comment'} = 'nocuratable';
$map{'invitro'} = 'invitro';
$map{'stlouissnp'} = 'newsnp';				# append to newsnp
$map{'covalent'} = 'covalent';
$map{'lsrnai'} = 'lsrnai';
$map{'structurecorrection'} = 'structcorr';
$map{'curator'} = 'curator';
$map{'mappingdata'} = 'mappingdata';
$map{'structurecorrectionsanger'} = 'structcorr';	# append to structcorr
$map{'expression'} = 'otherexpr';
$map{'marker'} = 'marker';
$map{'structurecorrectionstlouis'} = 'structcorr';	# append to structcorr
$map{'extractedallelename'} = '';			# only has 2 data (ignore, 2009 03 16)
$map{'massspec'} = 'massspec';
$map{'structureinformation'} = 'structinfo';
$map{'extractedallelenew'} = 'extvariation';
$map{'microarray'} = 'microarray';
$map{'supplemental'} = 'supplemental';
$map{'fullauthorname'} = '';
$map{'mosaic'} = 'mosaic';
$map{'synonym'} = '';
$map{'functionalcomplementation'} = 'funccomp';
$map{'newmutant'} = 'newmutant';
$map{'transgene'} = 'transgene';
$map{'genefunction'} = 'genefunc';
$map{'newsnp'} = 'newsnp';

my %curator;
$result = $conn->exec( "SELECT * FROM cur_curator ORDER BY cur_timestamp; ");
while (my @row = $result->fetchrow) { if ($row[0]) { $curator{$row[0]} = $row[1]; } }

@pgcommands = ();  my $pgcommand;
my %hash;		# store data here

foreach my $old (sort keys %map) {
  my $new = $map{$old}; 
  $old = 'cur_' . $old;
#   $result = $conn->exec( "COPY $old TO '/home/postgres/work/pgpopulation/cfp_papers/orig_tables/${old}.pg'" );
  next unless $new;
  push @pgcommands, "DELETE FROM cfp_$new;";
  push @pgcommands, "DELETE FROM cfp_${new}_hst;";
  unless ($new eq 'curator') { push @pgcommands, "DELETE FROM tfp_$new;"; }	# there is no tfp_curator table
  if ($new eq 'structinfo') {							# structinfo populates domanal
    push @pgcommands, "DELETE FROM cfp_domanal;";
    push @pgcommands, "DELETE FROM cfp_domanal_hst;";
    push @pgcommands, "DELETE FROM tfp_domanal;"; }
  $result = $conn->exec( "SELECT * FROM $old; ");
  while (my @row = $result->fetchrow) { 
    next unless ($row[1]);  $row[1] =~ s///g;
    my ($joinkey, $data, $timestamp) = ($row[0], $row[1], $row[2]);
    if ($data =~ m/\'/) { $data =~ s/\'/''/g; }
    my $curator = $curator{$joinkey};
    if ($new eq 'curator') { $hash{$row[0]}{$new}{data} = $row[1]; }	# don't append curators together
      else {
        if ($hash{$row[0]}{$new}{data}) { 				# already had data
            next if ($row[1] eq $hash{$row[0]}{$new}{data});		# skip if data is the same (don't worry about submatching)
            $hash{$row[0]}{$new}{data} .= "\n" . $row[1]; }		# append in new line
          else { $hash{$row[0]}{$new}{data} = $row[1]; } }
    if ($hash{$row[0]}{$new}{timestamp}) {
      my (@time) = $hash{$row[0]}{$new}{timestamp} =~ m/(\d)/g;
      my $time = join"", @time;
      my ($time2) = $time =~ m/^(\d{14})/;		# get the first 14 digits
      my (@new_time) = $row[2] =~ m/(\d)/g;
      my $new_time = join"", @new_time;
      my ($new_time2) = $new_time =~ m/^(\d{14})/;	# get the first 14 digits
      if ($new_time2 > $time2) { 
        if ($curator) { $hash{$row[0]}{$new}{curator} = $curator{$joinkey}; }	# replace curator if more recent
#         print "TIME2 OVER NEWTIME2 $time2 over $new_time2\n";
        $hash{$row[0]}{$new}{timestamp} = $row[2]; } }
    else { 
      if ($curator) { $hash{$row[0]}{$new}{curator} = $curator{$joinkey}; }	# new data, assign curator 
      $hash{$row[0]}{$new}{timestamp} = $row[2]; }
  }
}

foreach my $joinkey (sort keys %hash) {
  foreach my $new (sort keys %{ $hash{$joinkey} }) {
    my $curator = $hash{$joinkey}{$new}{curator};
    my $data = $hash{$joinkey}{$new}{data};
    my $timestamp = $hash{$joinkey}{$new}{timestamp};
    if ($data =~ m/Textpresso/) { 
      $data =~ s/^Textpresso : WBPaper\d+(\.sup)?(\.\d+)?\s+//; $data =~ s/ \.\.\.$//;
      $data =~ s/\'/''/g;
      $pgcommand = "INSERT INTO tfp_$new VALUES ('$joinkey', '$data', '$timestamp');";
      push @pgcommands, $pgcommand;
      next; }
    else { 
      next unless ($curator);	# skip if no curator
#       unless ($curator) { print "ERR $joinkey has no curator and $old data $data\n"; $curator = 'two480'; } 
      $data =~ s/\'/''/g;
      $pgcommand = "INSERT INTO cfp_$new VALUES ('$joinkey', '$data', '$curator', '$timestamp');";
      push @pgcommands, $pgcommand;
      $pgcommand = "INSERT INTO cfp_${new}_hst VALUES ('$joinkey', '$data', '$curator', '$timestamp');";
      push @pgcommands, $pgcommand;
      if ($new eq 'structinfo') {
        $pgcommand = "INSERT INTO cfp_domanal VALUES ('$joinkey', '$data', '$curator', '$timestamp');";
        push @pgcommands, $pgcommand;
        $pgcommand = "INSERT INTO cfp_domanal_hst VALUES ('$joinkey', '$data', '$curator', '$timestamp');";
        push @pgcommands, $pgcommand;
      }
    }
  } # foreach my $new (sort keys %{ $hash{$joinkey} })
} # foreach my $joinkey (sort keys %hash)

# UNCOMMENT TO POPULATE TABLES	# real run 2009 04 06
# foreach my $pgcommand (@pgcommands) {
#   print "$pgcommand\n";
#   $result = $conn->exec( $pgcommand );
# }


__END__


my @tables = qw( genesymbol mappingdata genefunction newmutant rnai lsrnai geneinteractions geneproduct expression sequencefeatures generegulation overexpression mosaic site microarray invitro covalent structureinformation structurecorrectionsanger sequencechange massspec ablationdata cellfunction phylogenetic othersilico chemicals transgene antibody newsnp rgngene nematode humandiseases supplemental review comment );

# my @newtables = qw( matrices timeaction celegans cnonbristol nematode nonnematode nocuratable domanal structcorr structinfo genestudied extvariation funccomp otherexpr marker siteaction email genefunc geneint geneprod seqfeat genereg overexpr seqchange cellfunc humdis );

my @tomove = qw( rgngene functionalcomplementation structureinformation structurecorrection site timeofaction domainanalysis otherexpression genefunction geneinteractions geneproduct sequencefeatures generegulation overexpression sequencechange cellfunction humandiseases );

my %moveHash;
# to delete
$moveHash{'siteofaction'} = 'siteaction';
$moveHash{'timeofaction'} = 'timeaction';
$moveHash{'domainanalysis'} = 'domanal';
$moveHash{'otherexpression'} = 'otherexpr';
$moveHash{'fxncomp'} = 'funccomp';
$moveHash{'genefunction'} = 'genefunc';
$moveHash{'geneinteractions'} = 'geneint';
$moveHash{'geneproduct'} = 'geneprod';
$moveHash{'sequencefeatures'} = 'seqfeat';
$moveHash{'generegulation'} = 'genereg';
$moveHash{'overexpression'} = 'overexpr';
$moveHash{'sequencechange'} = 'seqchange';
$moveHash{'cellfunction'} = 'cellfunc';
$moveHash{'humandiseases'} = 'humdis';

# foreach my $table (keys %moveHash) {
#   my $result = $conn->exec( "DROP TABLE afp_$table " );
#   $result = $conn->exec( "DROP TABLE afp_${table}_hst " );
# } # foreach my $table (keys %moveHash)

# to move
# $moveHash{'site'} = 'siteaction';
# $moveHash{'overexpression'} = 'overexpr';
# $moveHash{'genefunction'} = 'genefunc';
# $moveHash{'geneinteractions'} = 'geneint';
# $moveHash{'geneproduct'} = 'geneprod';
# $moveHash{'sequencefeatures'} = 'seqfeat';
# $moveHash{'generegulation'} = 'genereg';
# $moveHash{'overexpression'} = 'overexpr';
# $moveHash{'sequencechange'} = 'seqchange';
# $moveHash{'cellfunction'} = 'cellfunc';
# $moveHash{'humandiseases'} = 'humdis';

# foreach my $table (keys %moveHash) {
#   my $new = $moveHash{$table}; $new = 'afp_' . $new;
#   my $result = $conn->exec( "COPY $new FROM '/home/postgres/work/pgpopulation/afp_papers/orig_tables/afp_${table}.pg'" );
#   $result = $conn->exec( "COPY ${new}_hst FROM '/home/postgres/work/pgpopulation/afp_papers/orig_tables/afp_${table}.pg'" );
# }

# afp_ablationdata.pg      afp_geneproduct.pg     afp_mosaic.pg          afp_rgngene.pg
# afp_antibody.pg          afp_generegulation.pg  afp_nematode.pg        afp_rnai.pg
# afp_cellfunction.pg      afp_genesymbol.pg      afp_newmutant.pg       afp_sequencechange.pg
# afp_chemicals.pg         afp_humandiseases.pg   afp_newsnp.pg          afp_sequencefeatures.pg
# afp_comment.pg           afp_invitro.pg         afp_othersilico.pg     afp_site.pg
# afp_covalent.pg          afp_lsrnai.pg          afp_overexpression.pg  afp_structurecorrectionsanger.pg
# afp_expression.pg        afp_mappingdata.pg     afp_passwd.pg          afp_structureinformation.pg
# afp_genefunction.pg      afp_massspec.pg        afp_phylogenetic.pg    afp_supplemental.pg
# afp_geneinteractions.pg  afp_microarray.pg      afp_review.pg          afp_transgene.pg



my $table = 'afp_passwd_hst';



# foreach my $table (@tables) {
#   $table = 'afp_' . $table;
#   $result = $conn->exec( "COPY $table TO '/home/postgres/work/pgpopulation/afp_papers/orig_tables/${table}.pg'" );
#   my $table2 = $table . '_hst';
#   $result = $conn->exec( "COPY $table2 FROM '/home/postgres/work/pgpopulation/afp_papers/orig_tables/${table}.pg'" );
# }

# # my $result = $conn->exec( "DROP TABLE $table" );
# $result = $conn->exec( "CREATE TABLE $table ( joinkey text, $table numeric(17,7), afp_timestamp timestamp with time zone DEFAULT \"timestamp\"('now'::text) );" );
# $result = $conn->exec( "CREATE INDEX ${table}_idx ON $table USING btree (joinkey);" );
# $result = $conn->exec("REVOKE ALL ON TABLE $table FROM PUBLIC; ");
# $result = $conn->exec("GRANT ALL ON TABLE $table TO postgres; ");
# $result = $conn->exec("GRANT ALL ON TABLE $table TO acedb; ");
# $result = $conn->exec("GRANT ALL ON TABLE $table TO apache; ");
# $result = $conn->exec("GRANT ALL ON TABLE $table TO azurebrd; ");
# $result = $conn->exec("GRANT ALL ON TABLE $table TO cecilia; ");
# 
# foreach my $table (@tables) {
#   $table = 'afp_' . $table . '_hst';
# #   $result = $conn->exec( "DROP TABLE $table" );
#   $result = $conn->exec( "CREATE TABLE $table ( joinkey text, $table text, afp_timestamp timestamp with time zone DEFAULT \"timestamp\"('now'::text) );" );
#   $result = $conn->exec( "CREATE INDEX ${table}_idx ON $table USING btree (joinkey);" );
#   $result = $conn->exec("REVOKE ALL ON TABLE $table FROM PUBLIC; ");
#   $result = $conn->exec("GRANT ALL ON TABLE $table TO postgres; ");
#   $result = $conn->exec("GRANT ALL ON TABLE $table TO acedb; ");
#   $result = $conn->exec("GRANT ALL ON TABLE $table TO apache; ");
#   $result = $conn->exec("GRANT ALL ON TABLE $table TO azurebrd; ");
#   $result = $conn->exec("GRANT ALL ON TABLE $table TO cecilia; ");
# }

__END__

my $result = $conn->exec( "SELECT * FROM one_groups;" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[1] =~ s///g;
    $row[2] =~ s///g;
    print "$row[0]\t$row[1]\t$row[2]\n";
  } # if ($row[0])
} # while (@row = $result->fetchrow)

