#!/usr/bin/perl5.6.0

use lib qw( /usr/lib/perl5/site_perl/5.6.1/i686-linux/ );
use Pg;

$conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

$result = $conn->exec( "DELETE FROM curator WHERE joinkey = 'cgc3'; ");
$result = $conn->exec( "DELETE FROM newsymbol WHERE joinkey = 'cgc3'; ");
$result = $conn->exec( "DELETE FROM synonym WHERE joinkey = 'cgc3'; ");
$result = $conn->exec( "DELETE FROM mappingdata WHERE joinkey = 'cgc3'; ");
$result = $conn->exec( "DELETE FROM genefunction WHERE joinkey = 'cgc3'; ");
$result = $conn->exec( "DELETE FROM associationequiv WHERE joinkey = 'cgc3'; ");
$result = $conn->exec( "DELETE FROM associationnew WHERE joinkey = 'cgc3'; ");
$result = $conn->exec( "DELETE FROM expression WHERE joinkey = 'cgc3'; ");
$result = $conn->exec( "DELETE FROM rnai WHERE joinkey = 'cgc3'; ");
$result = $conn->exec( "DELETE FROM transgene WHERE joinkey = 'cgc3'; ");
$result = $conn->exec( "DELETE FROM overexpression WHERE joinkey = 'cgc3'; ");
$result = $conn->exec( "DELETE FROM mosaic WHERE joinkey = 'cgc3'; ");
$result = $conn->exec( "DELETE FROM antibody WHERE joinkey = 'cgc3'; ");
$result = $conn->exec( "DELETE FROM extractedallelename WHERE joinkey = 'cgc3'; ");
$result = $conn->exec( "DELETE FROM extractedallelenew WHERE joinkey = 'cgc3'; ");
$result = $conn->exec( "DELETE FROM newmutant WHERE joinkey = 'cgc3'; ");
$result = $conn->exec( "DELETE FROM sequencechange WHERE joinkey = 'cgc3'; ");
$result = $conn->exec( "DELETE FROM genesymbols WHERE joinkey = 'cgc3'; ");
$result = $conn->exec( "DELETE FROM geneproduct WHERE joinkey = 'cgc3'; ");
$result = $conn->exec( "DELETE FROM structurecorrection WHERE joinkey = 'cgc3'; ");
$result = $conn->exec( "DELETE FROM sequencefeatures WHERE joinkey = 'cgc3'; ");
$result = $conn->exec( "DELETE FROM cellname WHERE joinkey = 'cgc3'; ");
$result = $conn->exec( "DELETE FROM cellfunction WHERE joinkey = 'cgc3'; ");
$result = $conn->exec( "DELETE FROM ablationdata WHERE joinkey = 'cgc3'; ");
$result = $conn->exec( "DELETE FROM newsnp WHERE joinkey = 'cgc3'; ");
$result = $conn->exec( "DELETE FROM stlouissnp WHERE joinkey = 'cgc3'; ");
$result = $conn->exec( "DELETE FROM goodphoto WHERE joinkey = 'cgc3'; ");
$result = $conn->exec( "DELETE FROM comment WHERE joinkey = 'cgc3'; ");
