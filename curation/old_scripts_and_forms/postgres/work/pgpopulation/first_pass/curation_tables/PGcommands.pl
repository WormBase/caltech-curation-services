#!/usr/bin/perl5.6.0
#
# create cur_ curation tables, copy old tables, update timestamps. 2002 02 02

use lib qw( /usr/lib/perl5/site_perl/5.6.1/i686-linux/ );
use Pg;

$conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

# $result = $conn->exec( "CREATE TABLE reference_by ( joinkey TEXT, reference_by TEXT )");
# $result = $conn->exec( "CREATE TABLE checked_out ( joinkey TEXT, checked_out TEXT )");
# $result = $conn->exec( "INSERT INTO reference_by VALUES ('cgc10', 'postgres')");
# $result = $conn->exec( "INSERT INTO checked_out VALUES ('cgc10', NULL )");

# CREATE TABLE ref_reference_by ( joinkey TEXT, ref_reference_by TEXT, ref_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP);


$result = $conn->exec( "CREATE TABLE cur_curator ( joinkey TEXT, cur_curator TEXT, cur_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP )");
$result = $conn->exec( "CREATE TABLE cur_newsymbol ( joinkey TEXT, cur_newsymbol TEXT, cur_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP )");
$result = $conn->exec( "CREATE TABLE cur_synonym ( joinkey TEXT, cur_synonym TEXT, cur_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP )");
$result = $conn->exec( "CREATE TABLE cur_mappingdata ( joinkey TEXT, cur_mappingdata TEXT, cur_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP )");
$result = $conn->exec( "CREATE TABLE cur_genefunction ( joinkey TEXT, cur_genefunction TEXT, cur_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP )");
$result = $conn->exec( "CREATE TABLE cur_associationequiv ( joinkey TEXT, cur_associationequiv TEXT, cur_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP )");
$result = $conn->exec( "CREATE TABLE cur_associationnew ( joinkey TEXT, cur_associationnew TEXT, cur_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP )");
$result = $conn->exec( "CREATE TABLE cur_expression ( joinkey TEXT, cur_expression TEXT, cur_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP )");
$result = $conn->exec( "CREATE TABLE cur_rnai ( joinkey TEXT, cur_rnai TEXT, cur_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP )");
$result = $conn->exec( "CREATE TABLE cur_transgene ( joinkey TEXT, cur_transgene TEXT, cur_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP )");
$result = $conn->exec( "CREATE TABLE cur_overexpression ( joinkey TEXT, cur_overexpression TEXT, cur_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP )");
$result = $conn->exec( "CREATE TABLE cur_mosaic ( joinkey TEXT, cur_mosaic TEXT, cur_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP )");
$result = $conn->exec( "CREATE TABLE cur_antibody ( joinkey TEXT, cur_antibody TEXT, cur_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP )");
$result = $conn->exec( "CREATE TABLE cur_extractedallelename ( joinkey TEXT, cur_extractedallelename TEXT, cur_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP )");
$result = $conn->exec( "CREATE TABLE cur_extractedallelenew ( joinkey TEXT, cur_extractedallelenew TEXT, cur_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP )");
$result = $conn->exec( "CREATE TABLE cur_newmutant ( joinkey TEXT, cur_newmutant TEXT, cur_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP )");
$result = $conn->exec( "CREATE TABLE cur_sequencechange ( joinkey TEXT, cur_sequencechange TEXT, cur_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP )");
$result = $conn->exec( "CREATE TABLE cur_genesymbols ( joinkey TEXT, cur_genesymbols TEXT, cur_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP )");
$result = $conn->exec( "CREATE TABLE cur_geneproduct ( joinkey TEXT, cur_geneproduct TEXT, cur_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP )");
$result = $conn->exec( "CREATE TABLE cur_structurecorrection ( joinkey TEXT, cur_structurecorrection TEXT, cur_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP )");
$result = $conn->exec( "CREATE TABLE cur_sequencefeatures ( joinkey TEXT, cur_sequencefeatures TEXT, cur_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP )");
$result = $conn->exec( "CREATE TABLE cur_cellname ( joinkey TEXT, cur_cellname TEXT, cur_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP )");
$result = $conn->exec( "CREATE TABLE cur_cellfunction ( joinkey TEXT, cur_cellfunction TEXT, cur_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP )");
$result = $conn->exec( "CREATE TABLE cur_ablationdata ( joinkey TEXT, cur_ablationdata TEXT, cur_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP )");
$result = $conn->exec( "CREATE TABLE cur_newsnp ( joinkey TEXT, cur_newsnp TEXT, cur_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP )");
$result = $conn->exec( "CREATE TABLE cur_stlouissnp ( joinkey TEXT, cur_stlouissnp TEXT, cur_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP )");
$result = $conn->exec( "CREATE TABLE cur_goodphoto ( joinkey TEXT, cur_goodphoto TEXT, cur_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP )");
$result = $conn->exec( "CREATE TABLE cur_comment ( joinkey TEXT, cur_comment TEXT, cur_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP )");

$result = $conn->exec( "CREATE INDEX cur_curator_idx ON cur_curator ( joinkey )");
$result = $conn->exec( "CREATE UNIQUE INDEX cur_newsymbol_idx ON cur_newsymbol ( joinkey)");
$result = $conn->exec( "CREATE UNIQUE INDEX cur_synonym_idx ON cur_synonym ( joinkey)");
$result = $conn->exec( "CREATE UNIQUE INDEX cur_mappingdata_idx ON cur_mappingdata ( joinkey)");
$result = $conn->exec( "CREATE UNIQUE INDEX cur_genefunction_idx ON cur_genefunction ( joinkey)");
$result = $conn->exec( "CREATE UNIQUE INDEX cur_associationequiv_idx ON cur_associationequiv ( joinkey)");
$result = $conn->exec( "CREATE UNIQUE INDEX cur_associationnew_idx ON cur_associationnew ( joinkey)");
$result = $conn->exec( "CREATE UNIQUE INDEX cur_expression_idx ON cur_expression ( joinkey)");
$result = $conn->exec( "CREATE UNIQUE INDEX cur_rnai_idx ON cur_rnai ( joinkey)");
$result = $conn->exec( "CREATE UNIQUE INDEX cur_transgene_idx ON cur_transgene ( joinkey)");
$result = $conn->exec( "CREATE UNIQUE INDEX cur_overexpression_idx ON cur_overexpression ( joinkey)");
$result = $conn->exec( "CREATE UNIQUE INDEX cur_mosaic_idx ON cur_mosaic ( joinkey)");
$result = $conn->exec( "CREATE UNIQUE INDEX cur_antibody_idx ON cur_antibody ( joinkey)");
$result = $conn->exec( "CREATE UNIQUE INDEX cur_extractedallelename_idx ON cur_extractedallelename ( joinkey)");
$result = $conn->exec( "CREATE UNIQUE INDEX cur_extractedallelenew_idx ON cur_extractedallelenew ( joinkey)");
$result = $conn->exec( "CREATE UNIQUE INDEX cur_newmutant_idx ON cur_newmutant ( joinkey)");
$result = $conn->exec( "CREATE UNIQUE INDEX cur_sequencechange_idx ON cur_sequencechange ( joinkey)");
$result = $conn->exec( "CREATE UNIQUE INDEX cur_genesymbols_idx ON cur_genesymbols ( joinkey)");
$result = $conn->exec( "CREATE UNIQUE INDEX cur_geneproduct_idx ON cur_geneproduct ( joinkey)");
$result = $conn->exec( "CREATE UNIQUE INDEX cur_structurecorrection_idx ON cur_structurecorrection ( joinkey)");
$result = $conn->exec( "CREATE UNIQUE INDEX cur_sequencefeatures_idx ON cur_sequencefeatures ( joinkey)");
$result = $conn->exec( "CREATE UNIQUE INDEX cur_cellname_idx ON cur_cellname ( joinkey)");
$result = $conn->exec( "CREATE UNIQUE INDEX cur_cellfunction_idx ON cur_cellfunction ( joinkey)");
$result = $conn->exec( "CREATE UNIQUE INDEX cur_ablationdata_idx ON cur_ablationdata ( joinkey)");
$result = $conn->exec( "CREATE UNIQUE INDEX cur_newsnp_idx ON cur_newsnp ( joinkey)");
$result = $conn->exec( "CREATE UNIQUE INDEX cur_stlouissnp_idx ON cur_stlouissnp ( joinkey)");
$result = $conn->exec( "CREATE UNIQUE INDEX cur_goodphoto_idx ON cur_goodphoto ( joinkey)");
$result = $conn->exec( "CREATE UNIQUE INDEX cur_comment_idx ON cur_comment ( joinkey)");

$result = $conn->exec( "GRANT ALL ON cur_curator TO nobody" );
$result = $conn->exec( "GRANT ALL ON cur_newsymbol TO nobody" );
$result = $conn->exec( "GRANT ALL ON cur_synonym TO nobody" );
$result = $conn->exec( "GRANT ALL ON cur_mappingdata TO nobody" );
$result = $conn->exec( "GRANT ALL ON cur_genefunction TO nobody" );
$result = $conn->exec( "GRANT ALL ON cur_associationequiv TO nobody" );
$result = $conn->exec( "GRANT ALL ON cur_associationnew TO nobody" );
$result = $conn->exec( "GRANT ALL ON cur_expression TO nobody" );
$result = $conn->exec( "GRANT ALL ON cur_rnai TO nobody" );
$result = $conn->exec( "GRANT ALL ON cur_transgene TO nobody" );
$result = $conn->exec( "GRANT ALL ON cur_overexpression TO nobody" );
$result = $conn->exec( "GRANT ALL ON cur_mosaic TO nobody" );
$result = $conn->exec( "GRANT ALL ON cur_antibody TO nobody" );
$result = $conn->exec( "GRANT ALL ON cur_extractedallelename TO nobody" );
$result = $conn->exec( "GRANT ALL ON cur_extractedallelenew TO nobody" );
$result = $conn->exec( "GRANT ALL ON cur_newmutant TO nobody" );
$result = $conn->exec( "GRANT ALL ON cur_sequencechange TO nobody" );
$result = $conn->exec( "GRANT ALL ON cur_genesymbols TO nobody" );
$result = $conn->exec( "GRANT ALL ON cur_geneproduct TO nobody" );
$result = $conn->exec( "GRANT ALL ON cur_structurecorrection TO nobody" );
$result = $conn->exec( "GRANT ALL ON cur_sequencefeatures TO nobody" );
$result = $conn->exec( "GRANT ALL ON cur_cellname TO nobody" );
$result = $conn->exec( "GRANT ALL ON cur_cellfunction TO nobody" );
$result = $conn->exec( "GRANT ALL ON cur_ablationdata TO nobody" );
$result = $conn->exec( "GRANT ALL ON cur_newsnp TO nobody" );
$result = $conn->exec( "GRANT ALL ON cur_stlouissnp TO nobody" );
$result = $conn->exec( "GRANT ALL ON cur_goodphoto TO nobody" );
$result = $conn->exec( "GRANT ALL ON cur_comment TO nobody" );



# $result = $conn->exec( "COPY html TO '/home/postgres/work/pgpopulation/curation_tables/html.out'; ");
# COPY ref_html FROM '/home/postgres/work/pgpopulation/curation_tables/html.out';
# UPDATE ref_html SET ref_timestamp = CURRENT_TIMESTAMP WHERE ref_timestamp IS NULL;

$result = $conn->exec( "COPY curator TO '/home/postgres/work/pgpopulation/curation_tables/curator.out'; ");
$result = $conn->exec( "COPY cur_curator FROM '/home/postgres/work/pgpopulation/curation_tables/curator.out'; ");
$result = $conn->exec( "UPDATE cur_curator SET cur_timestamp = CURRENT_TIMESTAMP WHERE cur_timestamp IS NULL;" );

$result = $conn->exec( "COPY newsymbol TO '/home/postgres/work/pgpopulation/curation_tables/newsymbol.out'; ");
$result = $conn->exec( "COPY cur_newsymbol FROM '/home/postgres/work/pgpopulation/curation_tables/newsymbol.out'; ");
$result = $conn->exec( "UPDATE cur_newsymbol SET cur_timestamp = CURRENT_TIMESTAMP WHERE cur_timestamp IS NULL;" );

$result = $conn->exec( "COPY synonym TO '/home/postgres/work/pgpopulation/curation_tables/synonym.out'; ");
$result = $conn->exec( "COPY cur_synonym FROM '/home/postgres/work/pgpopulation/curation_tables/synonym.out'; ");
$result = $conn->exec( "UPDATE cur_synonym SET cur_timestamp = CURRENT_TIMESTAMP WHERE cur_timestamp IS NULL;" );

$result = $conn->exec( "COPY mappingdata TO '/home/postgres/work/pgpopulation/curation_tables/mappingdata.out'; ");
$result = $conn->exec( "COPY cur_mappingdata FROM '/home/postgres/work/pgpopulation/curation_tables/mappingdata.out'; ");
$result = $conn->exec( "UPDATE cur_mappingdata SET cur_timestamp = CURRENT_TIMESTAMP WHERE cur_timestamp IS NULL;" );

$result = $conn->exec( "COPY genefunction TO '/home/postgres/work/pgpopulation/curation_tables/genefunction.out'; ");
$result = $conn->exec( "COPY cur_genefunction FROM '/home/postgres/work/pgpopulation/curation_tables/genefunction.out'; ");
$result = $conn->exec( "UPDATE cur_genefunction SET cur_timestamp = CURRENT_TIMESTAMP WHERE cur_timestamp IS NULL;" );

$result = $conn->exec( "COPY associationequiv TO '/home/postgres/work/pgpopulation/curation_tables/associationequiv.out'; ");
$result = $conn->exec( "COPY cur_associationequiv FROM '/home/postgres/work/pgpopulation/curation_tables/associationequiv.out'; ");
$result = $conn->exec( "UPDATE cur_associationequiv SET cur_timestamp = CURRENT_TIMESTAMP WHERE cur_timestamp IS NULL;" );

$result = $conn->exec( "COPY associationnew TO '/home/postgres/work/pgpopulation/curation_tables/associationnew.out'; ");
$result = $conn->exec( "COPY cur_associationnew FROM '/home/postgres/work/pgpopulation/curation_tables/associationnew.out'; ");
$result = $conn->exec( "UPDATE cur_associationnew SET cur_timestamp = CURRENT_TIMESTAMP WHERE cur_timestamp IS NULL;" );

$result = $conn->exec( "COPY expression TO '/home/postgres/work/pgpopulation/curation_tables/expression.out'; ");
$result = $conn->exec( "COPY cur_expression FROM '/home/postgres/work/pgpopulation/curation_tables/expression.out'; ");
$result = $conn->exec( "UPDATE cur_expression SET cur_timestamp = CURRENT_TIMESTAMP WHERE cur_timestamp IS NULL;" );

$result = $conn->exec( "COPY rnai TO '/home/postgres/work/pgpopulation/curation_tables/rnai.out'; ");
$result = $conn->exec( "COPY cur_rnai FROM '/home/postgres/work/pgpopulation/curation_tables/rnai.out'; ");
$result = $conn->exec( "UPDATE cur_rnai SET cur_timestamp = CURRENT_TIMESTAMP WHERE cur_timestamp IS NULL;" );

$result = $conn->exec( "COPY transgene TO '/home/postgres/work/pgpopulation/curation_tables/transgene.out'; ");
$result = $conn->exec( "COPY cur_transgene FROM '/home/postgres/work/pgpopulation/curation_tables/transgene.out'; ");
$result = $conn->exec( "UPDATE cur_transgene SET cur_timestamp = CURRENT_TIMESTAMP WHERE cur_timestamp IS NULL;" );

$result = $conn->exec( "COPY overexpression TO '/home/postgres/work/pgpopulation/curation_tables/overexpression.out'; ");
$result = $conn->exec( "COPY cur_overexpression FROM '/home/postgres/work/pgpopulation/curation_tables/overexpression.out'; ");
$result = $conn->exec( "UPDATE cur_overexpression SET cur_timestamp = CURRENT_TIMESTAMP WHERE cur_timestamp IS NULL;" );

$result = $conn->exec( "COPY mosaic TO '/home/postgres/work/pgpopulation/curation_tables/mosaic.out'; ");
$result = $conn->exec( "COPY cur_mosaic FROM '/home/postgres/work/pgpopulation/curation_tables/mosaic.out'; ");
$result = $conn->exec( "UPDATE cur_mosaic SET cur_timestamp = CURRENT_TIMESTAMP WHERE cur_timestamp IS NULL;" );

$result = $conn->exec( "COPY antibody TO '/home/postgres/work/pgpopulation/curation_tables/antibody.out'; ");
$result = $conn->exec( "COPY cur_antibody FROM '/home/postgres/work/pgpopulation/curation_tables/antibody.out'; ");
$result = $conn->exec( "UPDATE cur_antibody SET cur_timestamp = CURRENT_TIMESTAMP WHERE cur_timestamp IS NULL;" );

$result = $conn->exec( "COPY extractedallelename TO '/home/postgres/work/pgpopulation/curation_tables/extractedallelename.out'; ");
$result = $conn->exec( "COPY cur_extractedallelename FROM '/home/postgres/work/pgpopulation/curation_tables/extractedallelename.out'; ");
$result = $conn->exec( "UPDATE cur_extractedallelename SET cur_timestamp = CURRENT_TIMESTAMP WHERE cur_timestamp IS NULL;" );

$result = $conn->exec( "COPY extractedallelenew TO '/home/postgres/work/pgpopulation/curation_tables/extractedallelenew.out'; ");
$result = $conn->exec( "COPY cur_extractedallelenew FROM '/home/postgres/work/pgpopulation/curation_tables/extractedallelenew.out'; ");
$result = $conn->exec( "UPDATE cur_extractedallelenew SET cur_timestamp = CURRENT_TIMESTAMP WHERE cur_timestamp IS NULL;" );

$result = $conn->exec( "COPY newmutant TO '/home/postgres/work/pgpopulation/curation_tables/newmutant.out'; ");
$result = $conn->exec( "COPY cur_newmutant FROM '/home/postgres/work/pgpopulation/curation_tables/newmutant.out'; ");
$result = $conn->exec( "UPDATE cur_newmutant SET cur_timestamp = CURRENT_TIMESTAMP WHERE cur_timestamp IS NULL;" );

$result = $conn->exec( "COPY sequencechange TO '/home/postgres/work/pgpopulation/curation_tables/sequencechange.out'; ");
$result = $conn->exec( "COPY cur_sequencechange FROM '/home/postgres/work/pgpopulation/curation_tables/sequencechange.out'; ");
$result = $conn->exec( "UPDATE cur_sequencechange SET cur_timestamp = CURRENT_TIMESTAMP WHERE cur_timestamp IS NULL;" );

$result = $conn->exec( "COPY genesymbols TO '/home/postgres/work/pgpopulation/curation_tables/genesymbols.out'; ");
$result = $conn->exec( "COPY cur_genesymbols FROM '/home/postgres/work/pgpopulation/curation_tables/genesymbols.out'; ");
$result = $conn->exec( "UPDATE cur_genesymbols SET cur_timestamp = CURRENT_TIMESTAMP WHERE cur_timestamp IS NULL;" );

$result = $conn->exec( "COPY geneproduct TO '/home/postgres/work/pgpopulation/curation_tables/geneproduct.out'; ");
$result = $conn->exec( "COPY cur_geneproduct FROM '/home/postgres/work/pgpopulation/curation_tables/geneproduct.out'; ");
$result = $conn->exec( "UPDATE cur_geneproduct SET cur_timestamp = CURRENT_TIMESTAMP WHERE cur_timestamp IS NULL;" );

$result = $conn->exec( "COPY structurecorrection TO '/home/postgres/work/pgpopulation/curation_tables/structurecorrection.out'; ");
$result = $conn->exec( "COPY cur_structurecorrection FROM '/home/postgres/work/pgpopulation/curation_tables/structurecorrection.out'; ");
$result = $conn->exec( "UPDATE cur_structurecorrection SET cur_timestamp = CURRENT_TIMESTAMP WHERE cur_timestamp IS NULL;" );

$result = $conn->exec( "COPY sequencefeatures TO '/home/postgres/work/pgpopulation/curation_tables/sequencefeatures.out'; ");
$result = $conn->exec( "COPY cur_sequencefeatures FROM '/home/postgres/work/pgpopulation/curation_tables/sequencefeatures.out'; ");
$result = $conn->exec( "UPDATE cur_sequencefeatures SET cur_timestamp = CURRENT_TIMESTAMP WHERE cur_timestamp IS NULL;" );

$result = $conn->exec( "COPY cellname TO '/home/postgres/work/pgpopulation/curation_tables/cellname.out'; ");
$result = $conn->exec( "COPY cur_cellname FROM '/home/postgres/work/pgpopulation/curation_tables/cellname.out'; ");
$result = $conn->exec( "UPDATE cur_cellname SET cur_timestamp = CURRENT_TIMESTAMP WHERE cur_timestamp IS NULL;" );

$result = $conn->exec( "COPY cellfunction TO '/home/postgres/work/pgpopulation/curation_tables/cellfunction.out'; ");
$result = $conn->exec( "COPY cur_cellfunction FROM '/home/postgres/work/pgpopulation/curation_tables/cellfunction.out'; ");
$result = $conn->exec( "UPDATE cur_cellfunction SET cur_timestamp = CURRENT_TIMESTAMP WHERE cur_timestamp IS NULL;" );

$result = $conn->exec( "COPY ablationdata TO '/home/postgres/work/pgpopulation/curation_tables/ablationdata.out'; ");
$result = $conn->exec( "COPY cur_ablationdata FROM '/home/postgres/work/pgpopulation/curation_tables/ablationdata.out'; ");
$result = $conn->exec( "UPDATE cur_ablationdata SET cur_timestamp = CURRENT_TIMESTAMP WHERE cur_timestamp IS NULL;" );

$result = $conn->exec( "COPY newsnp TO '/home/postgres/work/pgpopulation/curation_tables/newsnp.out'; ");
$result = $conn->exec( "COPY cur_newsnp FROM '/home/postgres/work/pgpopulation/curation_tables/newsnp.out'; ");
$result = $conn->exec( "UPDATE cur_newsnp SET cur_timestamp = CURRENT_TIMESTAMP WHERE cur_timestamp IS NULL;" );

$result = $conn->exec( "COPY stlouissnp TO '/home/postgres/work/pgpopulation/curation_tables/stlouissnp.out'; ");
$result = $conn->exec( "COPY cur_stlouissnp FROM '/home/postgres/work/pgpopulation/curation_tables/stlouissnp.out'; ");
$result = $conn->exec( "UPDATE cur_stlouissnp SET cur_timestamp = CURRENT_TIMESTAMP WHERE cur_timestamp IS NULL;" );

$result = $conn->exec( "COPY goodphoto TO '/home/postgres/work/pgpopulation/curation_tables/goodphoto.out'; ");
$result = $conn->exec( "COPY cur_goodphoto FROM '/home/postgres/work/pgpopulation/curation_tables/goodphoto.out'; ");
$result = $conn->exec( "UPDATE cur_goodphoto SET cur_timestamp = CURRENT_TIMESTAMP WHERE cur_timestamp IS NULL;" );

$result = $conn->exec( "COPY comment TO '/home/postgres/work/pgpopulation/curation_tables/comment.out'; ");
$result = $conn->exec( "COPY cur_comment FROM '/home/postgres/work/pgpopulation/curation_tables/comment.out'; ");
$result = $conn->exec( "UPDATE cur_comment SET cur_timestamp = CURRENT_TIMESTAMP WHERE cur_timestamp IS NULL;" );


# cur_curator 
# cur_newsymbol
# cur_synonym
# cur_mappingdata
# cur_genefunction
# cur_associationequiv 
# cur_associationnew 
# cur_expression 
# cur_rnai 
# cur_transgene 
# cur_overexpression 
# cur_mosaic 
# cur_antibody 
# cur_extractedallelename 
# cur_extractedallelenew 
# cur_newmutant 
# cur_sequencechange 
# cur_genesymbols 
# cur_geneproduct 
# cur_structurecorrection 
# cur_sequencefeatures 
# cur_cellname 
# cur_cellfunction 
# cur_ablationdata 
# cur_newsnp 
# cur_stlouissnp 
# cur_goodphoto 
# cur_comment 
