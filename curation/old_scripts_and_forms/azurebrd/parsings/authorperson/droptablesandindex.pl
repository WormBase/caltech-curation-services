#!/usr/bin/perl5.6.0

use lib qw( /usr/lib/perl5/site_perl/5.6.1/i686-linux/ );
use Pg;

$conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

$result = $conn->exec( "DROP INDEX wbg_number_idx ");
$result = $conn->exec( "DROP INDEX wbg_timestamp_idx ");
$result = $conn->exec( "DROP INDEX wbg_title_idx ");
$result = $conn->exec( "DROP INDEX wbg_firstname_idx ");
$result = $conn->exec( "DROP INDEX wbg_middlename_idx ");
$result = $conn->exec( "DROP INDEX wbg_lastname_idx ");
$result = $conn->exec( "DROP INDEX wbg_suffix_idx ");
$result = $conn->exec( "DROP INDEX wbg_street_idx ");
$result = $conn->exec( "DROP INDEX wbg_city_idx ");
$result = $conn->exec( "DROP INDEX wbg_state_idx ");
$result = $conn->exec( "DROP INDEX wbg_post_idx ");
$result = $conn->exec( "DROP INDEX wbg_country_idx ");
$result = $conn->exec( "DROP INDEX wbg_mainphone_idx ");
$result = $conn->exec( "DROP INDEX wbg_labphone_idx ");
$result = $conn->exec( "DROP INDEX wbg_officephone_idx ");
$result = $conn->exec( "DROP INDEX wbg_fax_idx ");
$result = $conn->exec( "DROP INDEX wbg_email_idx ");
$result = $conn->exec( "DROP INDEX wbg_lastchange_idx ");
$result = $conn->exec( "DROP INDEX wbg_labhead_idx ");
$result = $conn->exec( "DROP INDEX wbg_labcode_idx ");
$result = $conn->exec( "DROP INDEX wbg_ponumber_idx ");
$result = $conn->exec( "DROP INDEX wbg_poposition_idx ");
$result = $conn->exec( "DROP INDEX wbg_comparedvs_idx ");
$result = $conn->exec( "DROP INDEX wbg_comparedby_idx ");
$result = $conn->exec( "DROP INDEX wbg_rejectedvs_idx ");
$result = $conn->exec( "DROP INDEX wbg_rejectedby_idx ");
$result = $conn->exec( "DROP INDEX wbg_groupedwith_idx ");
$result = $conn->exec( "DROP TABLE wbg_number ");
$result = $conn->exec( "DROP TABLE wbg_timestamp ");
$result = $conn->exec( "DROP TABLE wbg_title ");
$result = $conn->exec( "DROP TABLE wbg_firstname ");
$result = $conn->exec( "DROP TABLE wbg_middlename ");
$result = $conn->exec( "DROP TABLE wbg_lastname ");
$result = $conn->exec( "DROP TABLE wbg_suffix ");
$result = $conn->exec( "DROP TABLE wbg_street ");
$result = $conn->exec( "DROP TABLE wbg_city ");
$result = $conn->exec( "DROP TABLE wbg_state ");
$result = $conn->exec( "DROP TABLE wbg_post ");
$result = $conn->exec( "DROP TABLE wbg_country ");
$result = $conn->exec( "DROP TABLE wbg_mainphone ");
$result = $conn->exec( "DROP TABLE wbg_labphone ");
$result = $conn->exec( "DROP TABLE wbg_officephone ");
$result = $conn->exec( "DROP TABLE wbg_fax ");
$result = $conn->exec( "DROP TABLE wbg_email ");
$result = $conn->exec( "DROP TABLE wbg_lastchange ");
$result = $conn->exec( "DROP TABLE wbg_labhead ");
$result = $conn->exec( "DROP TABLE wbg_labcode ");
$result = $conn->exec( "DROP TABLE wbg_ponumber ");
$result = $conn->exec( "DROP TABLE wbg_poposition ");
$result = $conn->exec( "DROP TABLE wbg_comparedvs ");
$result = $conn->exec( "DROP TABLE wbg_comparedby ");
$result = $conn->exec( "DROP TABLE wbg_rejectedvs ");
$result = $conn->exec( "DROP TABLE wbg_rejectedby ");
$result = $conn->exec( "DROP TABLE wbg_groupedwith ");

$result = $conn->exec( "DROP INDEX ace_number_idx ");
$result = $conn->exec( "DROP INDEX ace_timestamp_idx ");
$result = $conn->exec( "DROP INDEX ace_author_idx ");
$result = $conn->exec( "DROP INDEX ace_name_idx ");
$result = $conn->exec( "DROP INDEX ace_lab_idx ");
$result = $conn->exec( "DROP INDEX ace_oldlab_idx ");
$result = $conn->exec( "DROP INDEX ace_address_idx ");
$result = $conn->exec( "DROP INDEX ace_email_idx ");
$result = $conn->exec( "DROP INDEX ace_phone_idx ");
$result = $conn->exec( "DROP INDEX ace_fax_idx ");
$result = $conn->exec( "DROP INDEX ace_comparedvs_idx ");
$result = $conn->exec( "DROP INDEX ace_comparedby_idx ");
$result = $conn->exec( "DROP INDEX ace_rejectedvs_idx ");
$result = $conn->exec( "DROP INDEX ace_rejectedby_idx ");
$result = $conn->exec( "DROP INDEX ace_groupedwith_idx ");
$result = $conn->exec( "DROP TABLE ace_number ");
$result = $conn->exec( "DROP TABLE ace_timestamp ");
$result = $conn->exec( "DROP TABLE ace_author ");
$result = $conn->exec( "DROP TABLE ace_name ");
$result = $conn->exec( "DROP TABLE ace_lab ");
$result = $conn->exec( "DROP TABLE ace_oldlab ");
$result = $conn->exec( "DROP TABLE ace_address ");
$result = $conn->exec( "DROP TABLE ace_email ");
$result = $conn->exec( "DROP TABLE ace_phone ");
$result = $conn->exec( "DROP TABLE ace_fax ");
$result = $conn->exec( "DROP TABLE ace_comparedvs ");
$result = $conn->exec( "DROP TABLE ace_comparedby ");
$result = $conn->exec( "DROP TABLE ace_rejectedvs ");
$result = $conn->exec( "DROP TABLE ace_rejectedby ");
$result = $conn->exec( "DROP TABLE ace_groupedwith ");