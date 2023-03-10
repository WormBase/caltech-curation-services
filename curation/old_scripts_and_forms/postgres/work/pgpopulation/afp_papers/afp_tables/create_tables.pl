#!/usr/bin/perl -w

# create afp tables for author first pass flagging  
#
# use numeric to get 17 digit precision with 7 decimals  (as opposed to 15 digit
# with float)  2008 06 30
#
# had messed up the revoke and grant, fixed. 
# created _hst tables without UNIQUE index.
# copied data from tables to _hst tables, backup in orig_tables/$table.pg
#
# rewrote script to recreate and repopulate the tables from original afp_ dumps.
# 2009 03 21
#
# real run  2009 04 06
#
# added gocuration history  2011 09 30


use strict;
use diagnostics;
use DBI;

# use Pg;
# 
# my $conn = Pg::connectdb("dbname=testdb");
# die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my $result;

my @afp_tables = qw( gocuration );
# my @afp_tables = qw( passwd celegans cnonbristol nematode nonnematode genestudied genesymbol extvariation mappingdata newmutant rnai lsrnai overexpr chemicals mosaic siteaction timeaction genefunc humdis geneint funccomp geneprod otherexpr microarray genereg seqfeat matrices antibody transgene marker invitro domanal covalent structinfo massspec structcorr seqchange newsnp ablationdata cellfunc phylogenetic othersilico supplemental nocuratable comment );

my %dataTable = ();
$dataTable{passwd} = 'passwd';
$dataTable{celegans} = '';
$dataTable{cnonbristol} = '';
$dataTable{nematode} = 'nematode';
$dataTable{nonnematode} = '';
$dataTable{genestudied} = 'rgngene';
$dataTable{genesymbol} = 'genesymbol';
$dataTable{extvariation} = '';
$dataTable{mappingdata} = 'mappingdata';
$dataTable{newmutant} = 'newmutant';
$dataTable{rnai} = 'rnai';
$dataTable{lsrnai} = 'lsrnai';
$dataTable{overexpr} = 'overexpression';
$dataTable{chemicals} = 'chemicals';
$dataTable{mosaid} = 'mosaid';
$dataTable{siteaction} = 'site';
$dataTable{timeaction} = '';
$dataTable{genefunc} = 'genefunction';
$dataTable{humdis} = 'humandiseases';
$dataTable{geneint} = 'geneinteractions';
$dataTable{funccomp} = '';			# functionalcomplementation was in cur_ not in afp_ 
$dataTable{geneprod} = 'geneproduct';
$dataTable{otherexpr} = 'expression';
$dataTable{microarray} = 'microarray';
$dataTable{genereg} = 'generegulation';
$dataTable{seqfeat} = 'sequencefeatures';
$dataTable{matrices} = '';
$dataTable{antibody} = 'antibody';
$dataTable{transgene} = 'transgene';
$dataTable{marker} = '';
$dataTable{invitro} = 'invitro';
$dataTable{domanal} = 'structureinformation';
$dataTable{covalent} = 'covalent';
$dataTable{structinfo} = 'structureinformation';
$dataTable{massspec} = 'massspec';
$dataTable{structcorr} = 'structurecorrectionsanger';
$dataTable{seqchange} = 'sequencechange';
$dataTable{newsnp} = 'newsnp';
$dataTable{ablationdata} = 'ablationdata';
$dataTable{cellfunc} = 'cellfunction';
$dataTable{phylogenetic} = 'phylogenetic';
$dataTable{othersilico} = 'othersilico';
$dataTable{supplemental} = 'supplemental';
$dataTable{nocuratable} = 'review';
$dataTable{comment} = 'comment';

# UNCOMMENT to repopulate afp_ tables from original dumps.  2009 03 21
# foreach my $table (@afp_tables) {
#   my $table2 = 'afp_' . $table ;
#   $result = $dbh->do("DROP TABLE $table2; ");
#   $result = $dbh->do( "CREATE TABLE $table2 ( joinkey text, $table2 text, afp_timestamp timestamp with time zone DEFAULT \"timestamp\"('now'::text), afp_curator text, afp_approve text, afp_cur_timestamp timestamp with time zone DEFAULT \"timestamp\"('now'::text) );" );
#   $result = $dbh->do( "CREATE UNIQUE INDEX ${table2}_idx ON $table2 USING btree (joinkey);" );
#   $result = $dbh->do("REVOKE ALL ON TABLE $table2 FROM PUBLIC; ");
#   $result = $dbh->do("GRANT ALL ON TABLE $table2 TO postgres; ");
#   $result = $dbh->do("GRANT ALL ON TABLE $table2 TO acedb; ");
#   $result = $dbh->do("GRANT ALL ON TABLE $table2 TO apache; ");
#   $result = $dbh->do("GRANT ALL ON TABLE $table2 TO azurebrd; ");
#   $result = $dbh->do("GRANT ALL ON TABLE $table2 TO cecilia; ");
#   my $table3 = 'afp_' . $table . '_hst';
#   $result = $dbh->do("DROP TABLE $table3; ");
#   $result = $dbh->do( "CREATE TABLE $table3 ( joinkey text, $table3 text, afp_timestamp timestamp with time zone DEFAULT \"timestamp\"('now'::text), afp_curator text, afp_approve text, afp_cur_timestamp timestamp with time zone DEFAULT \"timestamp\"('now'::text) );" );
#   $result = $dbh->do( "CREATE INDEX ${table3}_idx ON $table3 USING btree (joinkey);" );
#   $result = $dbh->do("REVOKE ALL ON TABLE $table3 FROM PUBLIC; ");
#   $result = $dbh->do("GRANT ALL ON TABLE $table3 TO postgres; ");
#   $result = $dbh->do("GRANT ALL ON TABLE $table3 TO acedb; ");
#   $result = $dbh->do("GRANT ALL ON TABLE $table3 TO apache; ");
#   $result = $dbh->do("GRANT ALL ON TABLE $table3 TO azurebrd; ");
#   $result = $dbh->do("GRANT ALL ON TABLE $table3 TO cecilia; ");
#   if ($dataTable{$table}) { 
#     my $infile = "/home/postgres/work/pgpopulation/afp_papers/orig_tables/afp_$dataTable{$table}.pg";
#     open (IN, "<$infile") or die "Cannot open $infile : $!";
#     while (my $line = <IN>) {
#       chomp $line;
#       my ($joinkey, $data, $timestamp) = split/\t/, $line;
#       $data =~ s/\'/''/g;  $data =~ s/\\r\\n/\n/g;	# replace singlequotes and newlines
#       $result = $dbh->do( "INSERT INTO afp_$table VALUES ( '$joinkey', '$data', '$timestamp', NULL, NULL, NULL)" );
#       $result = $dbh->do( "INSERT INTO afp_${table}_hst VALUES ( '$joinkey', '$data', '$timestamp', NULL, NULL, NULL)" );
#     } # while (my $line = <IN>)
#     close (IN) or die "Cannot close $infile : $!";
# #     $result = $dbh->do( "COPY afp_$table FROM '/home/postgres/work/pgpopulation/afp_papers/orig_tables/afp_$dataTable{$table}.pg'" );
# #     $result = $dbh->do( "COPY afp_${table}_hst FROM '/home/postgres/work/pgpopulation/afp_papers/orig_tables/afp_$dataTable{$table}.pg'" ); 
#   } # if ($dataTable{$table}) 
# } # foreach my $table (@afp_tables)

# afp_ablationdata.pg               afp_humandiseases.pg              afp_passwd.pg
# afp_antibody.pg                   afp_invitro.pg                    afp_phylogenetic.pg
# afp_cellfunction.pg               afp_lsrnai.pg                     afp_review.pg
# afp_chemicals.pg                  afp_mappingdata.pg                afp_rgngene.pg
# afp_comment.pg                    afp_massspec.pg                   afp_rnai.pg
# afp_covalent.pg                   afp_microarray.pg                 afp_sequencechange.pg
# afp_expression.pg                 afp_mosaic.pg                     afp_sequencefeatures.pg
# afp_genefunction.pg               afp_nematode.pg                   afp_site.pg
# afp_geneinteractions.pg           afp_newmutant.pg                  afp_structurecorrectionsanger.pg
# afp_geneproduct.pg                afp_newsnp.pg                     afp_structureinformation.pg
# afp_generegulation.pg             afp_othersilico.pg                afp_supplemental.pg
# afp_genesymbol.pg                 afp_overexpression.pg             afp_transgene.pg

__END__


my @tables = qw( genesymbol mappingdata genefunction newmutant rnai lsrnai geneinteractions geneproduct expression sequencefeatures generegulation overexpression mosaic site microarray invitro covalent structureinformation structurecorrectionsanger sequencechange massspec ablationdata cellfunction phylogenetic othersilico chemicals transgene antibody newsnp rgngene nematode humandiseases supplemental review comment );

my @newtables = qw( matrices timeaction celegans cnonbristol nematode nonnematode nocuratable domanal structcorr structinfo genestudied extvariation funccomp otherexpr marker siteaction email genefunc geneint geneprod seqfeat genereg overexpr seqchange cellfunc humdis );

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
my $result = '';

# foreach my $table (@newtables) {
#   $table = 'afp_' . $table ;
#   $result = $conn->exec( "CREATE TABLE $table ( joinkey text, $table text, afp_timestamp timestamp with time zone DEFAULT \"timestamp\"('now'::text) );" );
#   $result = $conn->exec( "CREATE UNIQUE INDEX ${table}_idx ON $table USING btree (joinkey);" );
#   $result = $conn->exec("REVOKE ALL ON TABLE $table FROM PUBLIC; ");
#   $result = $conn->exec("GRANT ALL ON TABLE $table TO postgres; ");
#   $result = $conn->exec("GRANT ALL ON TABLE $table TO acedb; ");
#   $result = $conn->exec("GRANT ALL ON TABLE $table TO apache; ");
#   $result = $conn->exec("GRANT ALL ON TABLE $table TO azurebrd; ");
#   $result = $conn->exec("GRANT ALL ON TABLE $table TO cecilia; ");
#   my $table2 = $table . '_hst';
#   $result = $conn->exec( "CREATE TABLE $table2 ( joinkey text, $table2 text, afp_timestamp timestamp with time zone DEFAULT \"timestamp\"('now'::text) );" );
#   $result = $conn->exec( "CREATE INDEX ${table2}_idx ON $table2 USING btree (joinkey);" );
#   $result = $conn->exec("REVOKE ALL ON TABLE $table2 FROM PUBLIC; ");
#   $result = $conn->exec("GRANT ALL ON TABLE $table2 TO postgres; ");
#   $result = $conn->exec("GRANT ALL ON TABLE $table2 TO acedb; ");
#   $result = $conn->exec("GRANT ALL ON TABLE $table2 TO apache; ");
#   $result = $conn->exec("GRANT ALL ON TABLE $table2 TO azurebrd; ");
#   $result = $conn->exec("GRANT ALL ON TABLE $table2 TO cecilia; ");
# }


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

