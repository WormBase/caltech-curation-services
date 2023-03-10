#!/usr/bin/perl -w

use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 10:20:00.800738-08\' WHERE joinkey = \'cgc1184\' AND pap_author = \'Aamodt EJ\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two2\' WHERE joinkey = \'cgc1184\' AND pap_author = \'Aamodt EJ\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 10:20:00.814393-08\' WHERE joinkey = \'cgc1407\' AND pap_author = \'Aamodt EJ\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two2\' WHERE joinkey = \'cgc1407\' AND pap_author = \'Aamodt EJ\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 10:20:00.829164-08\' WHERE joinkey = \'cgc1411\' AND pap_author = \'Aamodt EJ\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two2\' WHERE joinkey = \'cgc1411\' AND pap_author = \'Aamodt EJ\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 10:20:00.889916-08\' WHERE joinkey = \'cgc2355\' AND pap_author = \'Aamodt EJ\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two2\' WHERE joinkey = \'cgc2355\' AND pap_author = \'Aamodt EJ\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 10:20:00.907207-08\' WHERE joinkey = \'cgc2399\' AND pap_author = \'Aamodt EJ\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two2\' WHERE joinkey = \'cgc2399\' AND pap_author = \'Aamodt EJ\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 10:20:00.961708-08\' WHERE joinkey = \'cgc2507\' AND pap_author = \'Aamodt EJ\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two2\' WHERE joinkey = \'cgc2507\' AND pap_author = \'Aamodt EJ\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 10:20:00.976237-08\' WHERE joinkey = \'cgc2800\' AND pap_author = \'Aamodt EJ\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two2\' WHERE joinkey = \'cgc2800\' AND pap_author = \'Aamodt EJ\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 10:20:00.99964-08\' WHERE joinkey = \'cgc3054\' AND pap_author = \'Aamodt EJ\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two2\' WHERE joinkey = \'cgc3054\' AND pap_author = \'Aamodt EJ\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 10:23:44.214706-08\' WHERE joinkey = \'cgc3922\' AND pap_author = \'Aamodt EJ\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two2\' WHERE joinkey = \'cgc3922\' AND pap_author = \'Aamodt EJ\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 10:23:44.273421-08\' WHERE joinkey = \'cgc3987\' AND pap_author = \'Aamodt EJ\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two2\' WHERE joinkey = \'cgc3987\' AND pap_author = \'Aamodt EJ\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 10:23:44.295456-08\' WHERE joinkey = \'cgc5229\' AND pap_author = \'Aamodt E\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two2\' WHERE joinkey = \'cgc5229\' AND pap_author = \'Aamodt E\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 10:23:44.320234-08\' WHERE joinkey = \'cgc5359\' AND pap_author = \'Aamodt E\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two2\' WHERE joinkey = \'cgc5359\' AND pap_author = \'Aamodt E\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 10:23:44.339908-08\' WHERE joinkey = \'cgc905\' AND pap_author = \'Aamodt EJ\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two2\' WHERE joinkey = \'cgc905\' AND pap_author = \'Aamodt EJ\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 10:23:44.359736-08\' WHERE joinkey = \'ecwm2000ab15\' AND pap_author = \'Aamodt EJ\" Affiliation_address \"LSUMC, Shreveport, LA 71130\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two2\' WHERE joinkey = \'ecwm2000ab15\' AND pap_author = \'Aamodt EJ\" Affiliation_address \"LSUMC, Shreveport, LA 71130\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 10:23:44.378093-08\' WHERE joinkey = \'ecwm98ab121\' AND pap_author = \'Aamodt EJ\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two2\' WHERE joinkey = \'ecwm98ab121\' AND pap_author = \'Aamodt EJ\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 10:23:44.401865-08\' WHERE joinkey = \'wbg11.4p57\' AND pap_author = \'Aamodt EJ\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two2\' WHERE joinkey = \'wbg11.4p57\' AND pap_author = \'Aamodt EJ\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 10:23:44.415503-08\' WHERE joinkey = \'wbg12.3p11A\' AND pap_author = \'Aamodt EJ\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two2\' WHERE joinkey = \'wbg12.3p11A\' AND pap_author = \'Aamodt EJ\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 10:25:28.373511-08\' WHERE joinkey = \'wbg12.3p11B\' AND pap_author = \'Aamodt EJ\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two2\' WHERE joinkey = \'wbg12.3p11B\' AND pap_author = \'Aamodt EJ\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 10:25:28.399884-08\' WHERE joinkey = \'wbg12.3p12\' AND pap_author = \'Aamodt EJ\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two2\' WHERE joinkey = \'wbg12.3p12\' AND pap_author = \'Aamodt EJ\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 10:25:28.415041-08\' WHERE joinkey = \'wbg12.3p13\' AND pap_author = \'Aamodt EJ\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two2\' WHERE joinkey = \'wbg12.3p13\' AND pap_author = \'Aamodt EJ\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 10:25:28.434666-08\' WHERE joinkey = \'wbg12.4p43\' AND pap_author = \'Aamodt EJ\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two2\' WHERE joinkey = \'wbg12.4p43\' AND pap_author = \'Aamodt EJ\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 10:25:28.455264-08\' WHERE joinkey = \'wbg13.5p42\' AND pap_author = \'Aamodt EJ\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two2\' WHERE joinkey = \'wbg13.5p42\' AND pap_author = \'Aamodt EJ\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 10:25:28.47658-08\' WHERE joinkey = \'wbg14.2p82\' AND pap_author = \'Aamodt EJ\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two2\' WHERE joinkey = \'wbg14.2p82\' AND pap_author = \'Aamodt EJ\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 10:25:28.494979-08\' WHERE joinkey = \'wbg16.4p32\' AND pap_author = \'Aamodt EJ\" Affiliation_address \"Department of Biochemistry and Molecular Biology, Louisiana State University Health Sciences Center, Shreveport, LA 71130-39 \'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two2\' WHERE joinkey = \'wbg16.4p32\' AND pap_author = \'Aamodt EJ\" Affiliation_address \"Department of Biochemistry and Molecular Biology, Louisiana State University Health Sciences Center, Shreveport, LA 71130-39 \'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 10:25:28.542509-08\' WHERE joinkey = \'wm2001p1099\' AND pap_author = \'Aamodt EJ\" Affiliation_address \"Biochemistry and Molecular Biology, LSU Health Sciences Center, Shreveport, LA 71130\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two2\' WHERE joinkey = \'wm2001p1099\' AND pap_author = \'Aamodt EJ\" Affiliation_address \"Biochemistry and Molecular Biology, LSU Health Sciences Center, Shreveport, LA 71130\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 10:25:28.561968-08\' WHERE joinkey = \'wm2001p435\' AND pap_author = \'Aamodt EJ\" Affiliation_address \"LSU Health Sciences Center, Shreveport, LA 71130-3932\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two2\' WHERE joinkey = \'wm2001p435\' AND pap_author = \'Aamodt EJ\" Affiliation_address \"LSU Health Sciences Center, Shreveport, LA 71130-3932\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 10:25:28.587996-08\' WHERE joinkey = \'wm2001p58\' AND pap_author = \'Aamodt EJ\" Affiliation_address \"Louisiana State University Health Sciences Center, Shreveport, LA 71130 USA\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two2\' WHERE joinkey = \'wm2001p58\' AND pap_author = \'Aamodt EJ\" Affiliation_address \"Louisiana State University Health Sciences Center, Shreveport, LA 71130 USA\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 10:26:51.769088-08\' WHERE joinkey = \'wm85p20\' AND pap_author = \'Aamodt EJ\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two2\' WHERE joinkey = \'wm85p20\' AND pap_author = \'Aamodt EJ\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 10:26:51.792849-08\' WHERE joinkey = \'wm87p179\' AND pap_author = \'Aamodt EJ\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two2\' WHERE joinkey = \'wm87p179\' AND pap_author = \'Aamodt EJ\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 10:26:51.807102-08\' WHERE joinkey = \'wm87p80\' AND pap_author = \'Aamodt EJ\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two2\' WHERE joinkey = \'wm87p80\' AND pap_author = \'Aamodt EJ\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 10:26:51.836374-08\' WHERE joinkey = \'wm89p197\' AND pap_author = \'Aamodt EJ\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two2\' WHERE joinkey = \'wm89p197\' AND pap_author = \'Aamodt EJ\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 10:26:51.85308-08\' WHERE joinkey = \'wm91p139\' AND pap_author = \'Aamodt EJ\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two2\' WHERE joinkey = \'wm91p139\' AND pap_author = \'Aamodt EJ\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 10:26:51.864975-08\' WHERE joinkey = \'wm93p220\' AND pap_author = \'Aamodt EJ\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two2\' WHERE joinkey = \'wm93p220\' AND pap_author = \'Aamodt EJ\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 10:26:51.885501-08\' WHERE joinkey = \'wm93p25\' AND pap_author = \'Aamodt EJ\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two2\' WHERE joinkey = \'wm93p25\' AND pap_author = \'Aamodt EJ\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 10:26:51.898042-08\' WHERE joinkey = \'wm93p488\' AND pap_author = \'Aamodt EJ\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two2\' WHERE joinkey = \'wm93p488\' AND pap_author = \'Aamodt EJ\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 10:26:51.918805-08\' WHERE joinkey = \'wm95p256\' AND pap_author = \'Aamodt EJ\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two2\' WHERE joinkey = \'wm95p256\' AND pap_author = \'Aamodt EJ\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 10:26:51.933644-08\' WHERE joinkey = \'wm95p290\' AND pap_author = \'Aamodt EJ\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two2\' WHERE joinkey = \'wm95p290\' AND pap_author = \'Aamodt EJ\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 10:28:41.537903-08\' WHERE joinkey = \'wm95p553\' AND pap_author = \'Aamodt EJ\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two2\' WHERE joinkey = \'wm95p553\' AND pap_author = \'Aamodt EJ\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 10:28:41.568746-08\' WHERE joinkey = \'wm95p86\' AND pap_author = \'Aamodt EJ\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two2\' WHERE joinkey = \'wm95p86\' AND pap_author = \'Aamodt EJ\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 10:28:41.586259-08\' WHERE joinkey = \'wm97ab394\' AND pap_author = \'Aamodt EJ\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two2\' WHERE joinkey = \'wm97ab394\' AND pap_author = \'Aamodt EJ\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 10:28:41.62096-08\' WHERE joinkey = \'wm99ab137\' AND pap_author = \'Aamodt EJ\" Affiliation_address \"Department of Biochemistry and Molecular Biology, Louisiana State University Medical Center, Shreveport, LA 71130-3932\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two2\' WHERE joinkey = \'wm99ab137\' AND pap_author = \'Aamodt EJ\" Affiliation_address \"Department of Biochemistry and Molecular Biology, Louisiana State University Medical Center, Shreveport, LA 71130-3932\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 10:28:41.636666-08\' WHERE joinkey = \'wm99ab221\' AND pap_author = \'Aamodt EJ\" Affiliation_address \"LSU Medical Center, Shreveport, LA 71130.\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two2\' WHERE joinkey = \'wm99ab221\' AND pap_author = \'Aamodt EJ\" Affiliation_address \"LSU Medical Center, Shreveport, LA 71130.\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 10:28:41.655905-08\' WHERE joinkey = \'wm99ab252\' AND pap_author = \'Aamodt EJ\" Affiliation_address \"Louisiana State University Medical Center\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two2\' WHERE joinkey = \'wm99ab252\' AND pap_author = \'Aamodt EJ\" Affiliation_address \"Louisiana State University Medical Center\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 10:28:41.697137-08\' WHERE joinkey = \'wm99ab467\' AND pap_author = \'Aamodt EJ\" Affiliation_address \"Biochemistry and Molecular Biology, LSU Medical Center, Shreveport, LA 71130.\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two2\' WHERE joinkey = \'wm99ab467\' AND pap_author = \'Aamodt EJ\" Affiliation_address \"Biochemistry and Molecular Biology, LSU Medical Center, Shreveport, LA 71130.\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 10:28:41.71733-08\' WHERE joinkey = \'wm99ab575\' AND pap_author = \'Aamodt EJ\" Affiliation_address \"Louisiana State University Medical Center, 1501 Kings Highway, Shreveport, LA 7113\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two2\' WHERE joinkey = \'wm99ab575\' AND pap_author = \'Aamodt EJ\" Affiliation_address \"Louisiana State University Medical Center, 1501 Kings Highway, Shreveport, LA 7113\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 10:29:23.433529-08\' WHERE joinkey = \'wm99ab678\' AND pap_author = \'Aamodt EJ\" Affiliation_address \"Louisiana State University Medical Center, Shreveport, LA 71130-3932.\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two2\' WHERE joinkey = \'wm99ab678\' AND pap_author = \'Aamodt EJ\" Affiliation_address \"Louisiana State University Medical Center, Shreveport, LA 71130-3932.\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 10:30:51.715738-08\' WHERE joinkey = \'cgc4465\' AND pap_author = \'Aballay A\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two3\' WHERE joinkey = \'cgc4465\' AND pap_author = \'Aballay A\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 10:30:51.741298-08\' WHERE joinkey = \'cgc4574\' AND pap_author = \'Aballay A\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two3\' WHERE joinkey = \'cgc4574\' AND pap_author = \'Aballay A\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 10:30:51.754655-08\' WHERE joinkey = \'cgc5119\' AND pap_author = \'Aballay A\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two3\' WHERE joinkey = \'cgc5119\' AND pap_author = \'Aballay A\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 10:30:51.773015-08\' WHERE joinkey = \'wm2001p603\' AND pap_author = \'Aballay A\" Affiliation_address \"Department of Genetics, Harvard Medical School, and Department of Molecular Biology, Massachusetts General Hospital, Boston, MA 02114\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two3\' WHERE joinkey = \'wm2001p603\' AND pap_author = \'Aballay A\" Affiliation_address \"Department of Genetics, Harvard Medical School, and Department of Molecular Biology, Massachusetts General Hospital, Boston, MA 02114\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 10:35:25.225353-08\' WHERE joinkey = \'cgc2791\' AND pap_author = \'Achanzar WE\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two4\' WHERE joinkey = \'cgc2791\' AND pap_author = \'Achanzar WE\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 10:35:25.260168-08\' WHERE joinkey = \'wm93p26\' AND pap_author = \'Achanzar WE\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two4\' WHERE joinkey = \'wm93p26\' AND pap_author = \'Achanzar WE\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 10:35:25.275029-08\' WHERE joinkey = \'wm95p88\' AND pap_author = \'Achanzar WE\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two4\' WHERE joinkey = \'wm95p88\' AND pap_author = \'Achanzar WE\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 12:31:46.747321-08\' WHERE joinkey = \'jwm2000ab69\' AND pap_author = \'Adachi R\" Affiliation_address \"Graduate school of Natural Science and Technology, Okayama Univ\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two5\' WHERE joinkey = \'jwm2000ab69\' AND pap_author = \'Adachi R\" Affiliation_address \"Graduate school of Natural Science and Technology, Okayama Univ\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 12:31:46.796728-08\' WHERE joinkey = \'wbg17.1p58\' AND pap_author = \'Ryota Adachi\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two5\' WHERE joinkey = \'wbg17.1p58\' AND pap_author = \'Ryota Adachi\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 12:49:06.491786-08\' WHERE joinkey = \'wbg15.1p34\' AND pap_author = \'Adams D\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two6\' WHERE joinkey = \'wbg15.1p34\' AND pap_author = \'Adams D\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 12:49:06.515845-08\' WHERE joinkey = \'wbg15.2p2b\' AND pap_author = \'Adams D\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two6\' WHERE joinkey = \'wbg15.2p2b\' AND pap_author = \'Adams D\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 12:51:46.802997-08\' WHERE joinkey = \'cgc1636\' AND pap_author = \'Ahmed S\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two7\' WHERE joinkey = \'cgc1636\' AND pap_author = \'Ahmed S\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 12:51:46.823317-08\' WHERE joinkey = \'cgc3886\' AND pap_author = \'Ahmed S\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two7\' WHERE joinkey = \'cgc3886\' AND pap_author = \'Ahmed S\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 12:51:46.83865-08\' WHERE joinkey = \'cgc3984\' AND pap_author = \'Ahmed S\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two7\' WHERE joinkey = \'cgc3984\' AND pap_author = \'Ahmed S\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 12:51:46.854929-08\' WHERE joinkey = \'cgc4949\' AND pap_author = \'Ahmed S\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two7\' WHERE joinkey = \'cgc4949\' AND pap_author = \'Ahmed S\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 12:51:46.874193-08\' WHERE joinkey = \'cgc5024\' AND pap_author = \'Ahmed S\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two7\' WHERE joinkey = \'cgc5024\' AND pap_author = \'Ahmed S\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 12:51:46.915337-08\' WHERE joinkey = \'euwm2000ab65\' AND pap_author = \'Ahmed S\" Affiliation_address \"MRC Laboratory of Molecular Biology;   Hills Road; Cambridge 2B2 2QH\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two7\' WHERE joinkey = \'euwm2000ab65\' AND pap_author = \'Ahmed S\" Affiliation_address \"MRC Laboratory of Molecular Biology;   Hills Road; Cambridge 2B2 2QH\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 12:51:46.933214-08\' WHERE joinkey = \'euwm2000ab7\' AND pap_author = \'Ahmed S\" Affiliation_address \"MRC Laboratory of Molecular Biology Genetics Unit\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two7\' WHERE joinkey = \'euwm2000ab7\' AND pap_author = \'Ahmed S\" Affiliation_address \"MRC Laboratory of Molecular Biology Genetics Unit\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 12:51:46.945384-08\' WHERE joinkey = \'euwm98ab2\' AND pap_author = \'Ahmed S\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two7\' WHERE joinkey = \'euwm98ab2\' AND pap_author = \'Ahmed S\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 12:51:46.958964-08\' WHERE joinkey = \'wm2001p123\' AND pap_author = \'Ahmed S\" Affiliation_address \"LMB. Cambridge, UK\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two7\' WHERE joinkey = \'wm2001p123\' AND pap_author = \'Ahmed S\" Affiliation_address \"LMB. Cambridge, UK\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 12:52:35.058467-08\' WHERE joinkey = \'wm2001p227\' AND pap_author = \'Ahmed S\" Affiliation_address \"MRC Laboratory of Molecular Biology, Cambridge CB2 2QH, England\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two7\' WHERE joinkey = \'wm2001p227\' AND pap_author = \'Ahmed S\" Affiliation_address \"MRC Laboratory of Molecular Biology, Cambridge CB2 2QH, England\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 12:52:35.083897-08\' WHERE joinkey = \'wm93p303\' AND pap_author = \'Ahmed S\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two7\' WHERE joinkey = \'wm93p303\' AND pap_author = \'Ahmed S\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 12:52:35.099516-08\' WHERE joinkey = \'wm97ab6\' AND pap_author = \'Ahmed S\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two7\' WHERE joinkey = \'wm97ab6\' AND pap_author = \'Ahmed S\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 12:52:35.120227-08\' WHERE joinkey = \'wm99ab60\' AND pap_author = \'Ahmed S\" Affiliation_address \"MRC Laboratory of Molecular Biology, Cambridge CB2 2QH, UK\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two7\' WHERE joinkey = \'wm99ab60\' AND pap_author = \'Ahmed S\" Affiliation_address \"MRC Laboratory of Molecular Biology, Cambridge CB2 2QH, UK\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:03:22.553531-08\' WHERE joinkey = \'cgc1378\' AND pap_author = \'Ahringer JA\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two8\' WHERE joinkey = \'cgc1378\' AND pap_author = \'Ahringer JA\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:03:22.577474-08\' WHERE joinkey = \'cgc1560\' AND pap_author = \'Ahringer JA\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two8\' WHERE joinkey = \'cgc1560\' AND pap_author = \'Ahringer JA\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:03:22.589462-08\' WHERE joinkey = \'cgc2188\' AND pap_author = \'Ahringer JA\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two8\' WHERE joinkey = \'cgc2188\' AND pap_author = \'Ahringer JA\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:03:22.602269-08\' WHERE joinkey = \'cgc2462\' AND pap_author = \'Ahringer JA\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two8\' WHERE joinkey = \'cgc2462\' AND pap_author = \'Ahringer JA\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:03:22.646692-08\' WHERE joinkey = \'cgc2601\' AND pap_author = \'Ahringer JA\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two8\' WHERE joinkey = \'cgc2601\' AND pap_author = \'Ahringer JA\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:03:22.6628-08\' WHERE joinkey = \'cgc2828\' AND pap_author = \'Ahringer JA\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two8\' WHERE joinkey = \'cgc2828\' AND pap_author = \'Ahringer JA\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:03:22.675407-08\' WHERE joinkey = \'cgc2923\' AND pap_author = \'Ahringer JA\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two8\' WHERE joinkey = \'cgc2923\' AND pap_author = \'Ahringer JA\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:03:22.690782-08\' WHERE joinkey = \'cgc3271\' AND pap_author = \'Ahringer JA\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two8\' WHERE joinkey = \'cgc3271\' AND pap_author = \'Ahringer JA\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:03:22.704933-08\' WHERE joinkey = \'cgc3578\' AND pap_author = \'Ahringer JA\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two8\' WHERE joinkey = \'cgc3578\' AND pap_author = \'Ahringer JA\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:09:33.644273-08\' WHERE joinkey = \'cgc4171\' AND pap_author = \'Ahringer JA\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two8\' WHERE joinkey = \'cgc4171\' AND pap_author = \'Ahringer JA\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:09:33.670475-08\' WHERE joinkey = \'cgc4253\' AND pap_author = \'Ahringer JA\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two8\' WHERE joinkey = \'cgc4253\' AND pap_author = \'Ahringer JA\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:09:33.682938-08\' WHERE joinkey = \'cgc4402\' AND pap_author = \'Ahringer JA\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two8\' WHERE joinkey = \'cgc4402\' AND pap_author = \'Ahringer JA\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:09:33.705947-08\' WHERE joinkey = \'cgc4509\' AND pap_author = \'Ahringer JA\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two8\' WHERE joinkey = \'cgc4509\' AND pap_author = \'Ahringer JA\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:09:33.723534-08\' WHERE joinkey = \'cgc4576\' AND pap_author = \'Ahringer JA\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two8\' WHERE joinkey = \'cgc4576\' AND pap_author = \'Ahringer JA\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:09:33.73708-08\' WHERE joinkey = \'cgc4725\' AND pap_author = \'Ahringer J\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two8\' WHERE joinkey = \'cgc4725\' AND pap_author = \'Ahringer J\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:09:33.752921-08\' WHERE joinkey = \'cgc4782\' AND pap_author = \'Ahringer J\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two8\' WHERE joinkey = \'cgc4782\' AND pap_author = \'Ahringer J\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:09:33.766925-08\' WHERE joinkey = \'cgc4811\' AND pap_author = \'Ahringer J\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two8\' WHERE joinkey = \'cgc4811\' AND pap_author = \'Ahringer J\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:09:33.785755-08\' WHERE joinkey = \'cgc5153\' AND pap_author = \'Ahringer J\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two8\' WHERE joinkey = \'cgc5153\' AND pap_author = \'Ahringer J\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:09:33.807595-08\' WHERE joinkey = \'cgc5342\' AND pap_author = \'Ahringer J\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two8\' WHERE joinkey = \'cgc5342\' AND pap_author = \'Ahringer J\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:13:34.577934-08\' WHERE joinkey = \'cgc5423\' AND pap_author = \'Ahringer J\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two8\' WHERE joinkey = \'cgc5423\' AND pap_author = \'Ahringer J\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:13:34.612724-08\' WHERE joinkey = \'ecwm2000ab22\' AND pap_author = \'Ahringer JA\" Affiliation_address \"Wellcome/CRC Institute University of Cambridge Tennis Court Road CB2 1QR Cambridge UK\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two8\' WHERE joinkey = \'ecwm2000ab22\' AND pap_author = \'Ahringer JA\" Affiliation_address \"Wellcome/CRC Institute University of Cambridge Tennis Court Road CB2 1QR Cambridge UK\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:13:34.634301-08\' WHERE joinkey = \'euwm2000ab147\' AND pap_author = \'Ahringer JA\" Affiliation_address \"Address unknown\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two8\' WHERE joinkey = \'euwm2000ab147\' AND pap_author = \'Ahringer JA\" Affiliation_address \"Address unknown\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:13:34.657474-08\' WHERE joinkey = \'euwm2000ab46\' AND pap_author = \'Ahringer JA\" Affiliation_address \"Wellcome   CRC Institute , Tennis Court Road, Cambridge CB2 1QR, ENGLAND\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two8\' WHERE joinkey = \'euwm2000ab46\' AND pap_author = \'Ahringer JA\" Affiliation_address \"Wellcome   CRC Institute , Tennis Court Road, Cambridge CB2 1QR, ENGLAND\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:13:34.672335-08\' WHERE joinkey = \'euwm96ab2\' AND pap_author = \'Ahringer JA\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two8\' WHERE joinkey = \'euwm96ab2\' AND pap_author = \'Ahringer JA\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:13:34.713918-08\' WHERE joinkey = \'euwm98ab27\' AND pap_author = \'Ahringer JA\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two8\' WHERE joinkey = \'euwm98ab27\' AND pap_author = \'Ahringer JA\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:13:34.729493-08\' WHERE joinkey = \'euwm98ab28\' AND pap_author = \'Ahringer JA\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two8\' WHERE joinkey = \'euwm98ab28\' AND pap_author = \'Ahringer JA\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:13:34.749294-08\' WHERE joinkey = \'mwwm96ab89\' AND pap_author = \'Ahringer JA\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two8\' WHERE joinkey = \'mwwm96ab89\' AND pap_author = \'Ahringer JA\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:13:34.766258-08\' WHERE joinkey = \'wbg10.1p142a\' AND pap_author = \'Ahringer JA\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two8\' WHERE joinkey = \'wbg10.1p142a\' AND pap_author = \'Ahringer JA\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:15:23.828396-08\' WHERE joinkey = \'wbg10.3p14\' AND pap_author = \'Ahringer JA\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two8\' WHERE joinkey = \'wbg10.3p14\' AND pap_author = \'Ahringer JA\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:15:23.847698-08\' WHERE joinkey = \'wbg13.2p77\' AND pap_author = \'Ahringer JA\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two8\' WHERE joinkey = \'wbg13.2p77\' AND pap_author = \'Ahringer JA\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:15:23.858623-08\' WHERE joinkey = \'wbg13.2p94\' AND pap_author = \'Ahringer JA\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two8\' WHERE joinkey = \'wbg13.2p94\' AND pap_author = \'Ahringer JA\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:15:23.873892-08\' WHERE joinkey = \'wbg9.3p56\' AND pap_author = \'Ahringer JA\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two8\' WHERE joinkey = \'wbg9.3p56\' AND pap_author = \'Ahringer JA\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:15:23.887511-08\' WHERE joinkey = \'wcwm2000ab35\' AND pap_author = \'Ahringer JA\" Affiliation_address \"Wellcome-CRC Institute, Tennis Court Road, Cambridge, UK\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two8\' WHERE joinkey = \'wcwm2000ab35\' AND pap_author = \'Ahringer JA\" Affiliation_address \"Wellcome-CRC Institute, Tennis Court Road, Cambridge, UK\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:15:23.91171-08\' WHERE joinkey = \'wm2001p1093\' AND pap_author = \'Ahringer JA\" Affiliation_address \"Wellcome-CRC Institute, Tennis Court Road, Cambridge CB2 1QR, UK\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two8\' WHERE joinkey = \'wm2001p1093\' AND pap_author = \'Ahringer JA\" Affiliation_address \"Wellcome-CRC Institute, Tennis Court Road, Cambridge CB2 1QR, UK\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:15:23.944709-08\' WHERE joinkey = \'wm2001p12\' AND pap_author = \'Ahringer JA\" Affiliation_address \"Wellcome-CRC Institute, Cambridge CB2 1QR, UK\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two8\' WHERE joinkey = \'wm2001p12\' AND pap_author = \'Ahringer JA\" Affiliation_address \"Wellcome-CRC Institute, Cambridge CB2 1QR, UK\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:15:23.974999-08\' WHERE joinkey = \'wm2001p155\' AND pap_author = \'Ahringer JA\" Affiliation_address \"Wellcome/CRC Institute, Tennis Court Road, Cambridge, UK\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two8\' WHERE joinkey = \'wm2001p155\' AND pap_author = \'Ahringer JA\" Affiliation_address \"Wellcome/CRC Institute, Tennis Court Road, Cambridge, UK\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:15:24.002264-08\' WHERE joinkey = \'wm2001p22\' AND pap_author = \'Ahringer JA\" Affiliation_address \"Wellcome/CRC Institute, Tennis Court Road, Cambridge CB2 1QR, UK\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two8\' WHERE joinkey = \'wm2001p22\' AND pap_author = \'Ahringer JA\" Affiliation_address \"Wellcome/CRC Institute, Tennis Court Road, Cambridge CB2 1QR, UK\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:15:24.034841-08\' WHERE joinkey = \'wm2001p228\' AND pap_author = \'Ahringer JA\" Affiliation_address \"Wellcome/CRC institute, University of Cambridge, Tennis Court Road, CB2 1QR Cambridge, UK\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two8\' WHERE joinkey = \'wm2001p228\' AND pap_author = \'Ahringer JA\" Affiliation_address \"Wellcome/CRC institute, University of Cambridge, Tennis Court Road, CB2 1QR Cambridge, UK\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:19:36.721516-08\' WHERE joinkey = \'wm2001p313\' AND pap_author = \'Ahringer JA\" Affiliation_address \"Wellcome/CRC Institute, University of Cambridge\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two8\' WHERE joinkey = \'wm2001p313\' AND pap_author = \'Ahringer JA\" Affiliation_address \"Wellcome/CRC Institute, University of Cambridge\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:19:36.757578-08\' WHERE joinkey = \'wm2001p360\' AND pap_author = \'Ahringer JA\" Affiliation_address \"Wellcome/CRC Institute, University of Cambridge, Tennis Court Road, CB2 1QR Cambridge, UK\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two8\' WHERE joinkey = \'wm2001p360\' AND pap_author = \'Ahringer JA\" Affiliation_address \"Wellcome/CRC Institute, University of Cambridge, Tennis Court Road, CB2 1QR Cambridge, UK\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:19:36.791641-08\' WHERE joinkey = \'wm85p97\' AND pap_author = \'Ahringer JA\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two8\' WHERE joinkey = \'wm85p97\' AND pap_author = \'Ahringer JA\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:19:36.817272-08\' WHERE joinkey = \'wm89p10\' AND pap_author = \'Ahringer JA\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two8\' WHERE joinkey = \'wm89p10\' AND pap_author = \'Ahringer JA\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:19:36.8368-08\' WHERE joinkey = \'wm91p31\' AND pap_author = \'Ahringer JA\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two8\' WHERE joinkey = \'wm91p31\' AND pap_author = \'Ahringer JA\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:19:36.849361-08\' WHERE joinkey = \'wm91p359\' AND pap_author = \'Ahringer JA\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two8\' WHERE joinkey = \'wm91p359\' AND pap_author = \'Ahringer JA\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:19:36.862217-08\' WHERE joinkey = \'wm93p28\' AND pap_author = \'Ahringer JA\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two8\' WHERE joinkey = \'wm93p28\' AND pap_author = \'Ahringer JA\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:19:36.875284-08\' WHERE joinkey = \'wm95p36\' AND pap_author = \'Ahringer JA\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two8\' WHERE joinkey = \'wm95p36\' AND pap_author = \'Ahringer JA\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:19:36.88705-08\' WHERE joinkey = \'wm97ab149\' AND pap_author = \'Ahringer JA\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two8\' WHERE joinkey = \'wm97ab149\' AND pap_author = \'Ahringer JA\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:19:36.904385-08\' WHERE joinkey = \'wm97ab560\' AND pap_author = \'Ahringer JA\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two8\' WHERE joinkey = \'wm97ab560\' AND pap_author = \'Ahringer JA\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:21:16.518507-08\' WHERE joinkey = \'wm97ab7\' AND pap_author = \'Ahringer JA\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two8\' WHERE joinkey = \'wm97ab7\' AND pap_author = \'Ahringer JA\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:21:16.539526-08\' WHERE joinkey = \'wm99ab141\' AND pap_author = \'Ahringer JA\" Affiliation_address \"Wellcome CRC Institute, University of Cambridge, Tennis Court Road, Cambridge CB2 1QR, England\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two8\' WHERE joinkey = \'wm99ab141\' AND pap_author = \'Ahringer JA\" Affiliation_address \"Wellcome CRC Institute, University of Cambridge, Tennis Court Road, Cambridge CB2 1QR, England\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:21:16.556406-08\' WHERE joinkey = \'wm99ab20\' AND pap_author = \'Ahringer JA\" Affiliation_address \"Wellcome/CRC Institute, Cambridge, UK.\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two8\' WHERE joinkey = \'wm99ab20\' AND pap_author = \'Ahringer JA\" Affiliation_address \"Wellcome/CRC Institute, Cambridge, UK.\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:21:16.579168-08\' WHERE joinkey = \'wm99ab348\' AND pap_author = \'Ahringer JA\" Affiliation_address \"Wellcome/CRC Institute, Tennis Court Road, Cambridge CB2 1QR, United Kingdom\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two8\' WHERE joinkey = \'wm99ab348\' AND pap_author = \'Ahringer JA\" Affiliation_address \"Wellcome/CRC Institute, Tennis Court Road, Cambridge CB2 1QR, United Kingdom\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:21:16.598929-08\' WHERE joinkey = \'wm99ab791\' AND pap_author = \'Ahringer JA\" Affiliation_address \"Wellcome CRC Institute, Tennis Court Road, Cambridge CB2 1QR, and The Sanger Centre, Wellcome Trust Genome Campus, Hinxton, Cambridge CB10 1SA, ENGLAND.\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two8\' WHERE joinkey = \'wm99ab791\' AND pap_author = \'Ahringer JA\" Affiliation_address \"Wellcome CRC Institute, Tennis Court Road, Cambridge CB2 1QR, and The Sanger Centre, Wellcome Trust Genome Campus, Hinxton, Cambridge CB10 1SA, ENGLAND.\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:21:16.623289-08\' WHERE joinkey = \'wm99ab844\' AND pap_author = \'Ahringer JA\" Affiliation_address \"Wellcome CRC Institute, University of Cambridge, Cambridge.\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two8\' WHERE joinkey = \'wm99ab844\' AND pap_author = \'Ahringer JA\" Affiliation_address \"Wellcome CRC Institute, University of Cambridge, Cambridge.\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:25:31.380634-08\' WHERE joinkey = \'cgc3568\' AND pap_author = \'Ailion EMM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two9\' WHERE joinkey = \'cgc3568\' AND pap_author = \'Ailion EMM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:25:31.412044-08\' WHERE joinkey = \'cgc3572\' AND pap_author = \'Ailion EMM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two9\' WHERE joinkey = \'cgc3572\' AND pap_author = \'Ailion EMM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:25:31.435347-08\' WHERE joinkey = \'cgc3687\' AND pap_author = \'Ailion EMM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two9\' WHERE joinkey = \'cgc3687\' AND pap_author = \'Ailion EMM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:25:31.453823-08\' WHERE joinkey = \'cgc4310\' AND pap_author = \'Ailion EMM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two9\' WHERE joinkey = \'cgc4310\' AND pap_author = \'Ailion EMM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:25:31.485088-08\' WHERE joinkey = \'cgc4405\' AND pap_author = \'Ailion EMM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two9\' WHERE joinkey = \'cgc4405\' AND pap_author = \'Ailion EMM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:25:31.498774-08\' WHERE joinkey = \'wbg13.5p45\' AND pap_author = \'Ailion EMM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two9\' WHERE joinkey = \'wbg13.5p45\' AND pap_author = \'Ailion EMM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:25:31.516452-08\' WHERE joinkey = \'wbg14.5p57\' AND pap_author = \'Ailion EMM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two9\' WHERE joinkey = \'wbg14.5p57\' AND pap_author = \'Ailion EMM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:25:31.537482-08\' WHERE joinkey = \'wbg16.1p54\' AND pap_author = \'Ailion EMM\" Affiliation_address \"Department of Genetics, University of Washington, Seattle, WA 98195\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two9\' WHERE joinkey = \'wbg16.1p54\' AND pap_author = \'Ailion EMM\" Affiliation_address \"Department of Genetics, University of Washington, Seattle, WA 98195\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:25:31.555002-08\' WHERE joinkey = \'wbg16.5p41\' AND pap_author = \'Michael Ailion\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two9\' WHERE joinkey = \'wbg16.5p41\' AND pap_author = \'Michael Ailion\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:25:31.56813-08\' WHERE joinkey = \'wbg17.1p39\' AND pap_author = \'Michael Ailion\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two9\' WHERE joinkey = \'wbg17.1p39\' AND pap_author = \'Michael Ailion\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:27:03.006877-08\' WHERE joinkey = \'wcwm2000ab44\' AND pap_author = \'Ailion EMM\" Affiliation_address \"Molecular and Cellular Biology Program, University of Washington, Seattle, WA 98195\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two9\' WHERE joinkey = \'wcwm2000ab44\' AND pap_author = \'Ailion EMM\" Affiliation_address \"Molecular and Cellular Biology Program, University of Washington, Seattle, WA 98195\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:27:03.029809-08\' WHERE joinkey = \'wcwm96ab1\' AND pap_author = \'Ailion EMM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two9\' WHERE joinkey = \'wcwm96ab1\' AND pap_author = \'Ailion EMM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:27:03.048944-08\' WHERE joinkey = \'wcwm98ab1\' AND pap_author = \'Ailion EMM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two9\' WHERE joinkey = \'wcwm98ab1\' AND pap_author = \'Ailion EMM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:27:03.063261-08\' WHERE joinkey = \'wcwm98ab2\' AND pap_author = \'Ailion EMM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two9\' WHERE joinkey = \'wcwm98ab2\' AND pap_author = \'Ailion EMM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:27:03.082184-08\' WHERE joinkey = \'wm2001p344\' AND pap_author = \'Ailion EMM\" Affiliation_address \"Department of Genetics, University of Washington, Seattle WA 98195\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two9\' WHERE joinkey = \'wm2001p344\' AND pap_author = \'Ailion EMM\" Affiliation_address \"Department of Genetics, University of Washington, Seattle WA 98195\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:27:03.112519-08\' WHERE joinkey = \'wm2001p347\' AND pap_author = \'Ailion EMM\" Affiliation_address \"Department of Genetics, University of Washington, Seattle, WA\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two9\' WHERE joinkey = \'wm2001p347\' AND pap_author = \'Ailion EMM\" Affiliation_address \"Department of Genetics, University of Washington, Seattle, WA\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:27:03.125179-08\' WHERE joinkey = \'wm97ab8\' AND pap_author = \'Ailion EMM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two9\' WHERE joinkey = \'wm97ab8\' AND pap_author = \'Ailion EMM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:27:03.142137-08\' WHERE joinkey = \'wm99ab143\' AND pap_author = \'Ailion EMM\" Affiliation_address \"Program in Molecular and Cellular Biology, Univ. of Washington, Seattle, WA 98195.\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two9\' WHERE joinkey = \'wm99ab143\' AND pap_author = \'Ailion EMM\" Affiliation_address \"Program in Molecular and Cellular Biology, Univ. of Washington, Seattle, WA 98195.\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:31:05.2045-08\' WHERE joinkey = \'cgc1035\' AND pap_author = \'Albert PS\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two10\' WHERE joinkey = \'cgc1035\' AND pap_author = \'Albert PS\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:31:05.226755-08\' WHERE joinkey = \'cgc1101\' AND pap_author = \'Albert PS\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two10\' WHERE joinkey = \'cgc1101\' AND pap_author = \'Albert PS\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:31:05.276949-08\' WHERE joinkey = \'cgc1271\' AND pap_author = \'Albert PS\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two10\' WHERE joinkey = \'cgc1271\' AND pap_author = \'Albert PS\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:32:47.988912-08\' WHERE joinkey = \'cgc1819\' AND pap_author = \'Albert PS\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two10\' WHERE joinkey = \'cgc1819\' AND pap_author = \'Albert PS\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:32:48.028897-08\' WHERE joinkey = \'cgc2149\' AND pap_author = \'Albert PS\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two10\' WHERE joinkey = \'cgc2149\' AND pap_author = \'Albert PS\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:32:48.089072-08\' WHERE joinkey = \'cgc2589\' AND pap_author = \'Albert PS\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two10\' WHERE joinkey = \'cgc2589\' AND pap_author = \'Albert PS\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:35:11.068522-08\' WHERE joinkey = \'cgc2600\' AND pap_author = \'Albert PS\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two10\' WHERE joinkey = \'cgc2600\' AND pap_author = \'Albert PS\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:35:11.102205-08\' WHERE joinkey = \'cgc2690\' AND pap_author = \'Albert PS\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two10\' WHERE joinkey = \'cgc2690\' AND pap_author = \'Albert PS\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:35:11.13581-08\' WHERE joinkey = \'cgc3179\' AND pap_author = \'Albert PS\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two10\' WHERE joinkey = \'cgc3179\' AND pap_author = \'Albert PS\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:35:11.177019-08\' WHERE joinkey = \'cgc503\' AND pap_author = \'Albert PS\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two10\' WHERE joinkey = \'cgc503\' AND pap_author = \'Albert PS\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:35:11.191536-08\' WHERE joinkey = \'cgc504\' AND pap_author = \'Albert PS\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two10\' WHERE joinkey = \'cgc504\' AND pap_author = \'Albert PS\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:37:56.832473-08\' WHERE joinkey = \'cgc5086\' AND pap_author = \'Albert PS\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two10\' WHERE joinkey = \'cgc5086\' AND pap_author = \'Albert PS\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:37:56.853558-08\' WHERE joinkey = \'cgc596\' AND pap_author = \'Albert PS\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two10\' WHERE joinkey = \'cgc596\' AND pap_author = \'Albert PS\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:37:56.87198-08\' WHERE joinkey = \'cgc650\' AND pap_author = \'Albert PS\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two10\' WHERE joinkey = \'cgc650\' AND pap_author = \'Albert PS\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:40:03.374954-08\' WHERE joinkey = \'cgc993\' AND pap_author = \'Albert PS\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two10\' WHERE joinkey = \'cgc993\' AND pap_author = \'Albert PS\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:42:48.011656-08\' WHERE joinkey = \'mwwm2000ab13\' AND pap_author = \'Albert PS\" Affiliation_address \"310 Tucker Hall, University of Missouri, Columbia, MO 65211-7400\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two10\' WHERE joinkey = \'mwwm2000ab13\' AND pap_author = \'Albert PS\" Affiliation_address \"310 Tucker Hall, University of Missouri, Columbia, MO 65211-7400\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:42:48.075551-08\' WHERE joinkey = \'mwwm96ab23\' AND pap_author = \'Albert PS\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two10\' WHERE joinkey = \'mwwm96ab23\' AND pap_author = \'Albert PS\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:42:48.09429-08\' WHERE joinkey = \'mwwm96ab74\' AND pap_author = \'Albert PS\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two10\' WHERE joinkey = \'mwwm96ab74\' AND pap_author = \'Albert PS\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:44:13.677726-08\' WHERE joinkey = \'wbg10.1p18\' AND pap_author = \'Albert PS\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two10\' WHERE joinkey = \'wbg10.1p18\' AND pap_author = \'Albert PS\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:44:13.709034-08\' WHERE joinkey = \'wbg10.1p32\' AND pap_author = \'Albert PS\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two10\' WHERE joinkey = \'wbg10.1p32\' AND pap_author = \'Albert PS\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:44:13.732555-08\' WHERE joinkey = \'wbg10.2p77\' AND pap_author = \'Albert PS\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two10\' WHERE joinkey = \'wbg10.2p77\' AND pap_author = \'Albert PS\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:46:18.166107-08\' WHERE joinkey = \'wbg11.3p34\' AND pap_author = \'Albert PS\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two10\' WHERE joinkey = \'wbg11.3p34\' AND pap_author = \'Albert PS\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:46:18.188537-08\' WHERE joinkey = \'wbg11.4p51\' AND pap_author = \'Albert PS\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two10\' WHERE joinkey = \'wbg11.4p51\' AND pap_author = \'Albert PS\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:46:18.206407-08\' WHERE joinkey = \'wbg12.2p55\' AND pap_author = \'Albert PS\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two10\' WHERE joinkey = \'wbg12.2p55\' AND pap_author = \'Albert PS\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:47:52.72065-08\' WHERE joinkey = \'wbg14.2p36\' AND pap_author = \'Albert PS\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two10\' WHERE joinkey = \'wbg14.2p36\' AND pap_author = \'Albert PS\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:47:52.742847-08\' WHERE joinkey = \'wbg14.3p32\' AND pap_author = \'Albert PS\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two10\' WHERE joinkey = \'wbg14.3p32\' AND pap_author = \'Albert PS\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:47:52.760787-08\' WHERE joinkey = \'wbg14.4p47\' AND pap_author = \'Albert PS\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two10\' WHERE joinkey = \'wbg14.4p47\' AND pap_author = \'Albert PS\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:49:31.05365-08\' WHERE joinkey = \'wbg5.1p21\' AND pap_author = \'Albert PS\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two10\' WHERE joinkey = \'wbg5.1p21\' AND pap_author = \'Albert PS\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:49:31.075318-08\' WHERE joinkey = \'wbg5.1p21a\' AND pap_author = \'Albert PS\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two10\' WHERE joinkey = \'wbg5.1p21a\' AND pap_author = \'Albert PS\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:49:31.08552-08\' WHERE joinkey = \'wbg5.2p25\' AND pap_author = \'Albert PS\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two10\' WHERE joinkey = \'wbg5.2p25\' AND pap_author = \'Albert PS\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:51:38.019797-08\' WHERE joinkey = \'wbg7.1p95\' AND pap_author = \'Albert PS\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two10\' WHERE joinkey = \'wbg7.1p95\' AND pap_author = \'Albert PS\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:51:38.047984-08\' WHERE joinkey = \'wbg8.3p20\' AND pap_author = \'Albert PS\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two10\' WHERE joinkey = \'wbg8.3p20\' AND pap_author = \'Albert PS\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 13:51:38.08859-08\' WHERE joinkey = \'wbg9.3p28\' AND pap_author = \'Albert PS\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two10\' WHERE joinkey = \'wbg9.3p28\' AND pap_author = \'Albert PS\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 14:01:35.488954-08\' WHERE joinkey = \'wm2001p312\' AND pap_author = \'Albert PS\" Affiliation_address \"Division of Biological Sciences and Molecular Biology Program, University of Missouri, Columbia, MO 65211-7400, U.S.A\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two10\' WHERE joinkey = \'wm2001p312\' AND pap_author = \'Albert PS\" Affiliation_address \"Division of Biological Sciences and Molecular Biology Program, University of Missouri, Columbia, MO 65211-7400, U.S.A\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 14:05:29.629674-08\' WHERE joinkey = \'wm2001p86\' AND pap_author = \'Albert PS\" Affiliation_address \"Division of Biological Science, University of Missouri, Columbia, MO  65211\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two10\' WHERE joinkey = \'wm2001p86\' AND pap_author = \'Albert PS\" Affiliation_address \"Division of Biological Science, University of Missouri, Columbia, MO  65211\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 14:05:29.724948-08\' WHERE joinkey = \'wm79p43\' AND pap_author = \'Albert PS\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two10\' WHERE joinkey = \'wm79p43\' AND pap_author = \'Albert PS\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 14:07:00.834665-08\' WHERE joinkey = \'wm85p21\' AND pap_author = \'Albert PS\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two10\' WHERE joinkey = \'wm85p21\' AND pap_author = \'Albert PS\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 14:07:00.877648-08\' WHERE joinkey = \'wm87p169\' AND pap_author = \'Albert PS\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two10\' WHERE joinkey = \'wm87p169\' AND pap_author = \'Albert PS\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 14:11:18.663978-08\' WHERE joinkey = \'wm99ab437\' AND pap_author = \'Albert PS\" Affiliation_address \"University of Missouri, Columbia, MO 65211, USA\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two10\' WHERE joinkey = \'wm99ab437\' AND pap_author = \'Albert PS\" Affiliation_address \"University of Missouri, Columbia, MO 65211, USA\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 14:20:46.648258-08\' WHERE joinkey = \'wm93p121\' AND pap_author = \'Albert PS\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two10\' WHERE joinkey = \'wm93p121\' AND pap_author = \'Albert PS\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 14:20:46.674798-08\' WHERE joinkey = \'wm93p14\' AND pap_author = \'Albert PS\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two10\' WHERE joinkey = \'wm93p14\' AND pap_author = \'Albert PS\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 14:20:46.703006-08\' WHERE joinkey = \'wm95p206\' AND pap_author = \'Albert PS\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two10\' WHERE joinkey = \'wm95p206\' AND pap_author = \'Albert PS\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 14:20:46.737679-08\' WHERE joinkey = \'wm95p312\' AND pap_author = \'Albert PS\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two10\' WHERE joinkey = \'wm95p312\' AND pap_author = \'Albert PS\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 14:20:46.755741-08\' WHERE joinkey = \'wm95p423\' AND pap_author = \'Albert PS\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two10\' WHERE joinkey = \'wm95p423\' AND pap_author = \'Albert PS\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 14:20:46.772703-08\' WHERE joinkey = \'wm95p91\' AND pap_author = \'Albert PS\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two10\' WHERE joinkey = \'wm95p91\' AND pap_author = \'Albert PS\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 14:22:30.139309-08\' WHERE joinkey = \'wm89p27\' AND pap_author = \'Albert PS\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two10\' WHERE joinkey = \'wm89p27\' AND pap_author = \'Albert PS\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 14:22:30.175168-08\' WHERE joinkey = \'wm91p256\' AND pap_author = \'Albert PS\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two10\' WHERE joinkey = \'wm91p256\' AND pap_author = \'Albert PS\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 14:22:30.191099-08\' WHERE joinkey = \'wm91p270\' AND pap_author = \'Albert PS\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two10\' WHERE joinkey = \'wm91p270\' AND pap_author = \'Albert PS\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 14:22:30.209205-08\' WHERE joinkey = \'wm91p32\' AND pap_author = \'Albert PS\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two10\' WHERE joinkey = \'wm91p32\' AND pap_author = \'Albert PS\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 14:22:30.228581-08\' WHERE joinkey = \'wm93p120\' AND pap_author = \'Albert PS\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two10\' WHERE joinkey = \'wm93p120\' AND pap_author = \'Albert PS\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 15:04:54.719325-08\' WHERE joinkey = \'cgc1770\' AND pap_author = \'Alfonso A\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two12\' WHERE joinkey = \'cgc1770\' AND pap_author = \'Alfonso A\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 15:04:54.746297-08\' WHERE joinkey = \'cgc1938\' AND pap_author = \'Alfonso A\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two12\' WHERE joinkey = \'cgc1938\' AND pap_author = \'Alfonso A\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 15:04:54.764144-08\' WHERE joinkey = \'cgc2015\' AND pap_author = \'Alfonso A\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two12\' WHERE joinkey = \'cgc2015\' AND pap_author = \'Alfonso A\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 15:04:54.779868-08\' WHERE joinkey = \'cgc2195\' AND pap_author = \'Alfonso A\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two12\' WHERE joinkey = \'cgc2195\' AND pap_author = \'Alfonso A\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 15:04:54.79991-08\' WHERE joinkey = \'cgc2590\' AND pap_author = \'Alfonso A\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two12\' WHERE joinkey = \'cgc2590\' AND pap_author = \'Alfonso A\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 15:04:54.818014-08\' WHERE joinkey = \'cgc3600\' AND pap_author = \'Alfonso A\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two12\' WHERE joinkey = \'cgc3600\' AND pap_author = \'Alfonso A\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 15:04:54.868729-08\' WHERE joinkey = \'cgc3871\' AND pap_author = \'Alfonso A\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two12\' WHERE joinkey = \'cgc3871\' AND pap_author = \'Alfonso A\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 15:04:54.887988-08\' WHERE joinkey = \'med94210062\' AND pap_author = \'Alfonso A\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two12\' WHERE joinkey = \'med94210062\' AND pap_author = \'Alfonso A\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 15:04:54.906281-08\' WHERE joinkey = \'med94335008\' AND pap_author = \'Alfonso A\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two12\' WHERE joinkey = \'med94335008\' AND pap_author = \'Alfonso A\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 15:04:54.918972-08\' WHERE joinkey = \'wbg10.3p48\' AND pap_author = \'Alfonso A\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two12\' WHERE joinkey = \'wbg10.3p48\' AND pap_author = \'Alfonso A\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 15:06:45.375871-08\' WHERE joinkey = \'wbg11.4p26\' AND pap_author = \'Alfonso A\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two12\' WHERE joinkey = \'wbg11.4p26\' AND pap_author = \'Alfonso A\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 15:06:45.401742-08\' WHERE joinkey = \'wm2001p935\' AND pap_author = \'Alfonso A\" Affiliation_address \"Dept. of Biological Sciences and The Laboratory of Integrative Neuroscience, University of Illinois at Chicago, Chicago, IL 60607\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two12\' WHERE joinkey = \'wm2001p935\' AND pap_author = \'Alfonso A\" Affiliation_address \"Dept. of Biological Sciences and The Laboratory of Integrative Neuroscience, University of Illinois at Chicago, Chicago, IL 60607\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 15:06:45.445005-08\' WHERE joinkey = \'wm2001p938\' AND pap_author = \'Alfonso A\" Affiliation_address \"Dept. of Biological Sciences and The Laboratory of Integrative Neuroscience, University of Illinois at Chicago, Chicago IL 60607\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two12\' WHERE joinkey = \'wm2001p938\' AND pap_author = \'Alfonso A\" Affiliation_address \"Dept. of Biological Sciences and The Laboratory of Integrative Neuroscience, University of Illinois at Chicago, Chicago IL 60607\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 15:06:45.486213-08\' WHERE joinkey = \'wm89p28\' AND pap_author = \'Alfonso A\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two12\' WHERE joinkey = \'wm89p28\' AND pap_author = \'Alfonso A\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 15:06:45.501397-08\' WHERE joinkey = \'wm89p29\' AND pap_author = \'Alfonso A\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two12\' WHERE joinkey = \'wm89p29\' AND pap_author = \'Alfonso A\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 15:06:45.517073-08\' WHERE joinkey = \'wm91p11\' AND pap_author = \'Alfonso A\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two12\' WHERE joinkey = \'wm91p11\' AND pap_author = \'Alfonso A\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 15:06:45.532249-08\' WHERE joinkey = \'wm91p224\' AND pap_author = \'Alfonso A\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two12\' WHERE joinkey = \'wm91p224\' AND pap_author = \'Alfonso A\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 15:06:45.548847-08\' WHERE joinkey = \'wm91p33\' AND pap_author = \'Alfonso A\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two12\' WHERE joinkey = \'wm91p33\' AND pap_author = \'Alfonso A\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 15:06:45.563848-08\' WHERE joinkey = \'wm93p158\' AND pap_author = \'Alfonso A\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two12\' WHERE joinkey = \'wm93p158\' AND pap_author = \'Alfonso A\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 15:06:45.589821-08\' WHERE joinkey = \'wm93p30\' AND pap_author = \'Alfonso A\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two12\' WHERE joinkey = \'wm93p30\' AND pap_author = \'Alfonso A\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 15:07:45.167238-08\' WHERE joinkey = \'wm95p93\' AND pap_author = \'Alfonso A\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two12\' WHERE joinkey = \'wm95p93\' AND pap_author = \'Alfonso A\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 15:07:45.198244-08\' WHERE joinkey = \'wm97ab10\' AND pap_author = \'Alfonso A\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two12\' WHERE joinkey = \'wm97ab10\' AND pap_author = \'Alfonso A\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 15:07:45.229614-08\' WHERE joinkey = \'wm99ab404\' AND pap_author = \'Alfonso A\" Affiliation_address \"Department of Biological Sciences, University of Illinois at Chicago.\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two12\' WHERE joinkey = \'wm99ab404\' AND pap_author = \'Alfonso A\" Affiliation_address \"Department of Biological Sciences, University of Illinois at Chicago.\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 15:07:45.254227-08\' WHERE joinkey = \'wm99ab547\' AND pap_author = \'Alfonso A\" Affiliation_address \"Department of Biological Sciences, University of Illinois at Chicago, M/C 066, 845 W. Taylor Street, Chicago, IL 60607\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two12\' WHERE joinkey = \'wm99ab547\' AND pap_author = \'Alfonso A\" Affiliation_address \"Department of Biological Sciences, University of Illinois at Chicago, M/C 066, 845 W. Taylor Street, Chicago, IL 60607\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 15:09:17.484215-08\' WHERE joinkey = \'ecwm2000ab65\' AND pap_author = \'Alkema M\" Affiliation_address \"HHMI, Dept. Biology, MIT, Cambridge, MA 02139\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two13\' WHERE joinkey = \'ecwm2000ab65\' AND pap_author = \'Alkema M\" Affiliation_address \"HHMI, Dept. Biology, MIT, Cambridge, MA 02139\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 15:09:17.508289-08\' WHERE joinkey = \'ecwm98ab2\' AND pap_author = \'Alkema M\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two13\' WHERE joinkey = \'ecwm98ab2\' AND pap_author = \'Alkema M\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 15:09:17.524258-08\' WHERE joinkey = \'wm2001p341\' AND pap_author = \'Alkema M\" Affiliation_address \"HHMI, Dept. Biology, MIT, Cambridge, MA 02139, USA\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two13\' WHERE joinkey = \'wm2001p341\' AND pap_author = \'Alkema M\" Affiliation_address \"HHMI, Dept. Biology, MIT, Cambridge, MA 02139, USA\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 15:09:17.537375-08\' WHERE joinkey = \'wm97ab14\' AND pap_author = \'Alkema M\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two13\' WHERE joinkey = \'wm97ab14\' AND pap_author = \'Alkema M\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 15:09:17.558561-08\' WHERE joinkey = \'wm99ab148\' AND pap_author = \'Alkema M\" Affiliation_address \"HHMI, Dept. Biology, MIT, Cambridge, MA 02139, USA\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two13\' WHERE joinkey = \'wm99ab148\' AND pap_author = \'Alkema M\" Affiliation_address \"HHMI, Dept. Biology, MIT, Cambridge, MA 02139, USA\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 09:06:28.864521-08\' WHERE joinkey = \'wbg16.3p15\' AND pap_author = \'Allan RJ\" Affiliation_address \"Department of Molecular Biology and Biochemistry, University of British Columbia, Vancouver, BC, Canada\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two14\' WHERE joinkey = \'wbg16.3p15\' AND pap_author = \'Allan RJ\" Affiliation_address \"Department of Molecular Biology and Biochemistry, University of British Columbia, Vancouver, BC, Canada\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 09:11:04.874125-08\' WHERE joinkey = \'cgc2414\' AND pap_author = \'Allen TS\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two15\' WHERE joinkey = \'cgc2414\' AND pap_author = \'Allen TS\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 09:11:04.908343-08\' WHERE joinkey = \'cgc3294\' AND pap_author = \'Allen TS\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two15\' WHERE joinkey = \'cgc3294\' AND pap_author = \'Allen TS\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 09:11:04.949778-08\' WHERE joinkey = \'cgc3940\' AND pap_author = \'Allen TS\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two15\' WHERE joinkey = \'cgc3940\' AND pap_author = \'Allen TS\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 09:15:14.572254-08\' WHERE joinkey = \'ecwm2000ab66\' AND pap_author = \'Allen TS\" Affiliation_address \"Biology Department, Oberlin College, Oberlin, OH 44074\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two15\' WHERE joinkey = \'ecwm2000ab66\' AND pap_author = \'Allen TS\" Affiliation_address \"Biology Department, Oberlin College, Oberlin, OH 44074\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 09:15:14.602649-08\' WHERE joinkey = \'ecwm96ab1\' AND pap_author = \'Allen TS\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two15\' WHERE joinkey = \'ecwm96ab1\' AND pap_author = \'Allen TS\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 09:15:14.626583-08\' WHERE joinkey = \'mwwm2000ab53\' AND pap_author = \'Allen TS\" Affiliation_address \"Biology Department, Oberlin College, Oberlin, OH 44074.\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two15\' WHERE joinkey = \'mwwm2000ab53\' AND pap_author = \'Allen TS\" Affiliation_address \"Biology Department, Oberlin College, Oberlin, OH 44074.\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 09:18:22.708585-08\' WHERE joinkey = \'wm2001p600\' AND pap_author = \'Allen TS\" Affiliation_address \"Biology, Oberlin College, Oberlin, OH 44074-1082\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two15\' WHERE joinkey = \'wm2001p600\' AND pap_author = \'Allen TS\" Affiliation_address \"Biology, Oberlin College, Oberlin, OH 44074-1082\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 09:18:22.745331-08\' WHERE joinkey = \'wm2001p824\' AND pap_author = \'Allen TS\" Affiliation_address \"Biology, Oberlin College, Oberlin, OH 44074-1082\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two15\' WHERE joinkey = \'wm2001p824\' AND pap_author = \'Allen TS\" Affiliation_address \"Biology, Oberlin College, Oberlin, OH 44074-1082\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 09:18:22.80404-08\' WHERE joinkey = \'wm93p31\' AND pap_author = \'Allen TS\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two15\' WHERE joinkey = \'wm93p31\' AND pap_author = \'Allen TS\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 09:18:22.826387-08\' WHERE joinkey = \'wm95p135\' AND pap_author = \'Allen TS\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two15\' WHERE joinkey = \'wm95p135\' AND pap_author = \'Allen TS\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 09:18:22.852091-08\' WHERE joinkey = \'wm97ab15\' AND pap_author = \'Allen TS\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two15\' WHERE joinkey = \'wm97ab15\' AND pap_author = \'Allen TS\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 09:20:52.875383-08\' WHERE joinkey = \'wm99ab135\' AND pap_author = \'Allen TS\" Affiliation_address \"Biology Dept, Oberlin College, Oberlin, OH 44074\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two15\' WHERE joinkey = \'wm99ab135\' AND pap_author = \'Allen TS\" Affiliation_address \"Biology Dept, Oberlin College, Oberlin, OH 44074\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 09:20:52.91361-08\' WHERE joinkey = \'wm99ab149\' AND pap_author = \'Allen TS\" Affiliation_address \"Biology Dept, Oberlin College, Oberlin, OH 44074.\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two15\' WHERE joinkey = \'wm99ab149\' AND pap_author = \'Allen TS\" Affiliation_address \"Biology Dept, Oberlin College, Oberlin, OH 44074.\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 09:20:52.935274-08\' WHERE joinkey = \'wm99ab213\' AND pap_author = \'Allen TS\" Affiliation_address \"Biol. Dept, Oberlin College, Oberlin, OH 44074.\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two15\' WHERE joinkey = \'wm99ab213\' AND pap_author = \'Allen TS\" Affiliation_address \"Biol. Dept, Oberlin College, Oberlin, OH 44074.\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 09:54:05.148154-08\' WHERE joinkey = \'cgc4710\' AND pap_author = \'Alper S\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two16\' WHERE joinkey = \'cgc4710\' AND pap_author = \'Alper S\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 09:54:05.166413-08\' WHERE joinkey = \'cgc5355\' AND pap_author = \'Alper S\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two16\' WHERE joinkey = \'cgc5355\' AND pap_author = \'Alper S\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 09:54:05.176539-08\' WHERE joinkey = \'wcwm2000ab14\' AND pap_author = \'Alper SD\" Affiliation_address \"University of California, San Francisco\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two16\' WHERE joinkey = \'wcwm2000ab14\' AND pap_author = \'Alper SD\" Affiliation_address \"University of California, San Francisco\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 09:54:05.21862-08\' WHERE joinkey = \'wcwm98ab6\' AND pap_author = \'Alper SD\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two16\' WHERE joinkey = \'wcwm98ab6\' AND pap_author = \'Alper SD\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 09:54:05.236325-08\' WHERE joinkey = \'wm2001p174\' AND pap_author = \'Alper SD\" Affiliation_address \"University of California, San Francisco\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two16\' WHERE joinkey = \'wm2001p174\' AND pap_author = \'Alper SD\" Affiliation_address \"University of California, San Francisco\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 09:54:05.248003-08\' WHERE joinkey = \'wm97ab16\' AND pap_author = \'Alper SD\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two16\' WHERE joinkey = \'wm97ab16\' AND pap_author = \'Alper SD\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 09:54:05.259149-08\' WHERE joinkey = \'wm99ab151\' AND pap_author = \'Alper SD\" Affiliation_address \"University of California, San Francisco\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two16\' WHERE joinkey = \'wm99ab151\' AND pap_author = \'Alper SD\" Affiliation_address \"University of California, San Francisco\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 09:58:25.921213-08\' WHERE joinkey = \'cgc4727\' AND pap_author = \'Altun-Gultekin ZF\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two17\' WHERE joinkey = \'cgc4727\' AND pap_author = \'Altun-Gultekin ZF\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 09:58:25.947835-08\' WHERE joinkey = \'ecwm2000ab57\' AND pap_author = \'Altun-Gultekin ZF\" Affiliation_address \"Department of Pathology, University of Medicine and Dentistry of New Jersey - Robert Wood Johnson Medical School, 675 Hoes Lane, Piscataway, NJ 08854, USA\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two17\' WHERE joinkey = \'ecwm2000ab57\' AND pap_author = \'Altun-Gultekin ZF\" Affiliation_address \"Department of Pathology, University of Medicine and Dentistry of New Jersey - Robert Wood Johnson Medical School, 675 Hoes Lane, Piscataway, NJ 08854, USA\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 09:58:25.993281-08\' WHERE joinkey = \'ecwm98ab4\' AND pap_author = \'Altun-Gultekin ZF\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two17\' WHERE joinkey = \'ecwm98ab4\' AND pap_author = \'Altun-Gultekin ZF\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 09:58:26.004536-08\' WHERE joinkey = \'wbg16.3p25\' AND pap_author = \'Altun-Gultekin ZF\" Affiliation_address \"Columbia University, College of Physicians & Surgeons, Center for Neurobiology and Behavior, New York, NY 10032\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two17\' WHERE joinkey = \'wbg16.3p25\' AND pap_author = \'Altun-Gultekin ZF\" Affiliation_address \"Columbia University, College of Physicians & Surgeons, Center for Neurobiology and Behavior, New York, NY 10032\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 09:58:26.028732-08\' WHERE joinkey = \'wcwm2000ab90\' AND pap_author = \'Altun-Gultekin ZF\" Affiliation_address \"Columbia University, College of Physicians & Surgeons, Center for Neurobiology and Behavior, New York, NY 10032\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two17\' WHERE joinkey = \'wcwm2000ab90\' AND pap_author = \'Altun-Gultekin ZF\" Affiliation_address \"Columbia University, College of Physicians & Surgeons, Center for Neurobiology and Behavior, New York, NY 10032\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 09:58:26.072195-08\' WHERE joinkey = \'wm99ab397\' AND pap_author = \'Altun-Gultekin ZF\" Affiliation_address \"Columbia University, College of Physicians & Surgeons, New York, NY10032.\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two17\' WHERE joinkey = \'wm99ab397\' AND pap_author = \'Altun-Gultekin ZF\" Affiliation_address \"Columbia University, College of Physicians & Surgeons, New York, NY10032.\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 09:58:26.099602-08\' WHERE joinkey = \'wm99ab830\' AND pap_author = \'Altun-Gultekin ZF\" Affiliation_address \"Dept. of Pharmacology and Pathology, UMDNJ-R.W. Johnson Medical School, Piscataway, NJ.\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two17\' WHERE joinkey = \'wm99ab830\' AND pap_author = \'Altun-Gultekin ZF\" Affiliation_address \"Dept. of Pharmacology and Pathology, UMDNJ-R.W. Johnson Medical School, Piscataway, NJ.\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:09:44.578588-08\' WHERE joinkey = \'cgc1128\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'cgc1128\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:09:44.605039-08\' WHERE joinkey = \'cgc1144\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'cgc1144\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:09:44.633004-08\' WHERE joinkey = \'cgc1244\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'cgc1244\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:09:44.642895-08\' WHERE joinkey = \'cgc1396\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'cgc1396\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:09:44.654912-08\' WHERE joinkey = \'cgc1397\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'cgc1397\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:09:44.664151-08\' WHERE joinkey = \'cgc1479\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'cgc1479\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:09:44.678521-08\' WHERE joinkey = \'cgc1848\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'cgc1848\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:09:44.696205-08\' WHERE joinkey = \'cgc1953\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'cgc1953\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:09:44.706997-08\' WHERE joinkey = \'cgc2222\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'cgc2222\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:23:15.936023-08\' WHERE joinkey = \'cgc2223\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'cgc2223\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:23:15.959619-08\' WHERE joinkey = \'cgc2412\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'cgc2412\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:23:15.975091-08\' WHERE joinkey = \'cgc2520\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'cgc2520\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:23:15.989682-08\' WHERE joinkey = \'cgc2682\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'cgc2682\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:23:16.002356-08\' WHERE joinkey = \'cgc2728\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'cgc2728\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:23:16.017756-08\' WHERE joinkey = \'cgc3201\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'cgc3201\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:23:16.036145-08\' WHERE joinkey = \'cgc3522\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'cgc3522\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:23:16.048314-08\' WHERE joinkey = \'cgc3583\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'cgc3583\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:23:16.071276-08\' WHERE joinkey = \'cgc3838\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'cgc3838\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:23:16.085496-08\' WHERE joinkey = \'cgc3931\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'cgc3931\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:27:58.612737-08\' WHERE joinkey = \'cgc4231\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'cgc4231\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:27:58.650382-08\' WHERE joinkey = \'cgc4774\' AND pap_author = \'Ambros V\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'cgc4774\' AND pap_author = \'Ambros V\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:27:58.663035-08\' WHERE joinkey = \'cgc4847\' AND pap_author = \'Ambros V\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'cgc4847\' AND pap_author = \'Ambros V\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:27:58.675022-08\' WHERE joinkey = \'cgc4928\' AND pap_author = \'Ambros V\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'cgc4928\' AND pap_author = \'Ambros V\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:27:58.69109-08\' WHERE joinkey = \'cgc5043\' AND pap_author = \'Ambros V\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'cgc5043\' AND pap_author = \'Ambros V\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:27:58.704571-08\' WHERE joinkey = \'cgc620\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'cgc620\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:27:58.716175-08\' WHERE joinkey = \'cgc966\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'cgc966\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:31:48.490754-08\' WHERE joinkey = \'cgc991\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'cgc991\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:31:48.516822-08\' WHERE joinkey = \'ecwm2000ab114\' AND pap_author = \'Ambros VR\" Affiliation_address \"Department of Biology, Rm 318, Dartmouth College, Hanover, NH 03755\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'ecwm2000ab114\' AND pap_author = \'Ambros VR\" Affiliation_address \"Department of Biology, Rm 318, Dartmouth College, Hanover, NH 03755\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:31:48.538356-08\' WHERE joinkey = \'ecwm2000ab139\' AND pap_author = \'Ambros VR\" Affiliation_address \"Department of Biological Science, Dartmouth College, Hanover, NH, USA\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'ecwm2000ab139\' AND pap_author = \'Ambros VR\" Affiliation_address \"Department of Biological Science, Dartmouth College, Hanover, NH, USA\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:31:48.556198-08\' WHERE joinkey = \'ecwm2000ab161\' AND pap_author = \'Ambros VR\" Affiliation_address \"Department of Biological Science, Dartmouth College, Hanover, NH, USA\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'ecwm2000ab161\' AND pap_author = \'Ambros VR\" Affiliation_address \"Department of Biological Science, Dartmouth College, Hanover, NH, USA\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:31:48.573905-08\' WHERE joinkey = \'ecwm96ab106\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'ecwm96ab106\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:31:48.589795-08\' WHERE joinkey = \'ecwm96ab122\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'ecwm96ab122\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:31:48.603911-08\' WHERE joinkey = \'ecwm96ab2\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'ecwm96ab2\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:31:48.616796-08\' WHERE joinkey = \'ecwm96ab55\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'ecwm96ab55\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:31:48.632347-08\' WHERE joinkey = \'ecwm96ab56\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'ecwm96ab56\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:31:48.644735-08\' WHERE joinkey = \'ecwm98ab108\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'ecwm98ab108\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:34:31.859812-08\' WHERE joinkey = \'ecwm98ab134\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'ecwm98ab134\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:34:31.888337-08\' WHERE joinkey = \'ecwm98ab160\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'ecwm98ab160\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:34:31.906745-08\' WHERE joinkey = \'ecwm98ab5\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'ecwm98ab5\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:34:31.918282-08\' WHERE joinkey = \'ecwm98ab71\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'ecwm98ab71\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:34:31.936151-08\' WHERE joinkey = \'ecwm98ab73\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'ecwm98ab73\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:34:31.950365-08\' WHERE joinkey = \'med94302674\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'med94302674\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:34:31.964299-08\' WHERE joinkey = \'medline16\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'medline16\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:34:31.983127-08\' WHERE joinkey = \'wbg10.1p109\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'wbg10.1p109\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:34:31.997582-08\' WHERE joinkey = \'wbg10.1p112\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'wbg10.1p112\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:34:32.018935-08\' WHERE joinkey = \'wbg10.3p119\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'wbg10.3p119\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:36:07.889879-08\' WHERE joinkey = \'wbg10.3p124\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'wbg10.3p124\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:36:07.909396-08\' WHERE joinkey = \'wbg10.3p125\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'wbg10.3p125\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:36:07.925728-08\' WHERE joinkey = \'wbg11.1p18\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'wbg11.1p18\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:36:07.943638-08\' WHERE joinkey = \'wbg11.2p100\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'wbg11.2p100\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:36:07.959616-08\' WHERE joinkey = \'wbg11.2p27\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'wbg11.2p27\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:36:07.976539-08\' WHERE joinkey = \'wbg11.2p28\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'wbg11.2p28\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:36:07.991507-08\' WHERE joinkey = \'wbg11.2p39\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'wbg11.2p39\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:36:08.008484-08\' WHERE joinkey = \'wbg11.2p99\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'wbg11.2p99\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:36:08.02601-08\' WHERE joinkey = \'wbg11.3p12\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'wbg11.3p12\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:36:08.037288-08\' WHERE joinkey = \'wbg11.3p37\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'wbg11.3p37\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:37:45.44998-08\' WHERE joinkey = \'wbg11.4p61\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'wbg11.4p61\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:37:45.472828-08\' WHERE joinkey = \'wbg11.4p7\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'wbg11.4p7\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:37:45.487463-08\' WHERE joinkey = \'wbg11.5p22\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'wbg11.5p22\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:37:45.507606-08\' WHERE joinkey = \'wbg11.5p76\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'wbg11.5p76\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:37:45.524729-08\' WHERE joinkey = \'wbg12.2p52\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'wbg12.2p52\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:37:45.545942-08\' WHERE joinkey = \'wbg12.4p37\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'wbg12.4p37\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:37:45.558403-08\' WHERE joinkey = \'wbg13.5p57\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'wbg13.5p57\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:37:45.581614-08\' WHERE joinkey = \'wbg13.5p58\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'wbg13.5p58\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:37:45.593659-08\' WHERE joinkey = \'wbg14.5p54\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'wbg14.5p54\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:37:45.609865-08\' WHERE joinkey = \'wbg14.5p55\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'wbg14.5p55\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:40:31.663266-08\' WHERE joinkey = \'wbg14.5p56\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'wbg14.5p56\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:40:31.695378-08\' WHERE joinkey = \'wbg15.2p35\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'wbg15.2p35\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:40:31.711867-08\' WHERE joinkey = \'wbg15.2p36\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'wbg15.2p36\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:40:31.721721-08\' WHERE joinkey = \'wbg15.2p49\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'wbg15.2p49\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:40:31.736709-08\' WHERE joinkey = \'wbg5.2p41\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'wbg5.2p41\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:40:31.753578-08\' WHERE joinkey = \'wbg6.1p41\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'wbg6.1p41\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:40:31.7663-08\' WHERE joinkey = \'wbg7.1p45\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'wbg7.1p45\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:40:31.780005-08\' WHERE joinkey = \'wbg7.2p43\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'wbg7.2p43\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:40:31.805856-08\' WHERE joinkey = \'wbg8.1p40\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'wbg8.1p40\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:40:31.82265-08\' WHERE joinkey = \'wbg8.3p80\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'wbg8.3p80\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:42:37.089547-08\' WHERE joinkey = \'wbg9.2p45\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'wbg9.2p45\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:42:37.115283-08\' WHERE joinkey = \'wcwm2000ab91\' AND pap_author = \'Ambros VR\" Affiliation_address \"Department of Biology, Dartmouth College, Hanover, NH 03755\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'wcwm2000ab91\' AND pap_author = \'Ambros VR\" Affiliation_address \"Department of Biology, Dartmouth College, Hanover, NH 03755\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:42:37.136823-08\' WHERE joinkey = \'wm2001p802\' AND pap_author = \'Ambros VR\" Affiliation_address \"Department of Biological Sciences Dartmouth College Hanover, NH 03755\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'wm2001p802\' AND pap_author = \'Ambros VR\" Affiliation_address \"Department of Biological Sciences Dartmouth College Hanover, NH 03755\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:42:37.15392-08\' WHERE joinkey = \'wm2001p803\' AND pap_author = \'Ambros VR\" Affiliation_address \"Department of Biological Sciences, Dartmouth College, Hanover, NH 03755\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'wm2001p803\' AND pap_author = \'Ambros VR\" Affiliation_address \"Department of Biological Sciences, Dartmouth College, Hanover, NH 03755\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:42:37.168927-08\' WHERE joinkey = \'wm81p49\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'wm81p49\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:42:37.183173-08\' WHERE joinkey = \'wm83p47\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'wm83p47\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:42:37.198644-08\' WHERE joinkey = \'wm85p4\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'wm85p4\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:42:37.215614-08\' WHERE joinkey = \'wm85p62\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'wm85p62\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:42:37.228955-08\' WHERE joinkey = \'wm87p127\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'wm87p127\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:42:37.242908-08\' WHERE joinkey = \'wm87p84\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'wm87p84\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:44:42.076629-08\' WHERE joinkey = \'wm89p160\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'wm89p160\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:44:42.099719-08\' WHERE joinkey = \'wm89p168\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'wm89p168\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:44:42.114438-08\' WHERE joinkey = \'wm89p202\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'wm89p202\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:44:42.130961-08\' WHERE joinkey = \'wm89p210\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'wm89p210\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:44:42.156345-08\' WHERE joinkey = \'wm89p94\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'wm89p94\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:44:42.169084-08\' WHERE joinkey = \'wm89p95\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'wm89p95\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:44:42.179225-08\' WHERE joinkey = \'wm91p102\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'wm91p102\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:44:42.193457-08\' WHERE joinkey = \'wm91p189\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'wm91p189\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:44:42.211784-08\' WHERE joinkey = \'wm91p198\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'wm91p198\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:44:42.224173-08\' WHERE joinkey = \'wm91p215\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'wm91p215\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:46:43.368451-08\' WHERE joinkey = \'wm91p253\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'wm91p253\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:46:43.389339-08\' WHERE joinkey = \'wm91p98\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'wm91p98\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:46:43.404307-08\' WHERE joinkey = \'wm93p16\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'wm93p16\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:46:43.42318-08\' WHERE joinkey = \'wm93p23\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'wm93p23\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:46:43.436493-08\' WHERE joinkey = \'wm93p323\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'wm93p323\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:46:43.45056-08\' WHERE joinkey = \'wm95p211\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'wm95p211\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:46:43.464304-08\' WHERE joinkey = \'wm95p272\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'wm95p272\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:46:43.477876-08\' WHERE joinkey = \'wm95p402\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'wm95p402\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:46:43.495075-08\' WHERE joinkey = \'wm95p57\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'wm95p57\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:46:43.509197-08\' WHERE joinkey = \'wm95p58\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'wm95p58\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:50:05.86284-08\' WHERE joinkey = \'wm95p95\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'wm95p95\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:50:05.901652-08\' WHERE joinkey = \'wm97ab249\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'wm97ab249\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:50:05.922962-08\' WHERE joinkey = \'wm97ab426\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'wm97ab426\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:50:05.949378-08\' WHERE joinkey = \'wm97ab460\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'wm97ab460\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:50:05.9749-08\' WHERE joinkey = \'wm97ab515\' AND pap_author = \'Ambros VR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'wm97ab515\' AND pap_author = \'Ambros VR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:50:05.994625-08\' WHERE joinkey = \'wm99ab152\' AND pap_author = \'Ambros VR\" Affiliation_address \"Department of Biological Sciences, Dartmouth College, Hanover NH 03755.\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'wm99ab152\' AND pap_author = \'Ambros VR\" Affiliation_address \"Department of Biological Sciences, Dartmouth College, Hanover NH 03755.\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:50:06.021566-08\' WHERE joinkey = \'wm99ab414\' AND pap_author = \'Ambros VR\" Affiliation_address \"Department of Biological Sciences, Dartmouth College, Hanover, NH 03755\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'wm99ab414\' AND pap_author = \'Ambros VR\" Affiliation_address \"Department of Biological Sciences, Dartmouth College, Hanover, NH 03755\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:50:06.047977-08\' WHERE joinkey = \'wm99ab608\' AND pap_author = \'Ambros VR\" Affiliation_address \"Dept. of Biology, Dartmouth College, Hanover, NH 03755.\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'wm99ab608\' AND pap_author = \'Ambros VR\" Affiliation_address \"Dept. of Biology, Dartmouth College, Hanover, NH 03755.\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:50:06.082929-08\' WHERE joinkey = \'wm99ab646\' AND pap_author = \'Ambros VR\" Affiliation_address \"Dartmouth College Department of Biology Hanover NH 03755.\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'wm99ab646\' AND pap_author = \'Ambros VR\" Affiliation_address \"Dartmouth College Department of Biology Hanover NH 03755.\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-22 10:50:06.117072-08\' WHERE joinkey = \'wm99ab725\' AND pap_author = \'Ambros VR\" Affiliation_address \"Department of Biological Sciences, Dartmouth College, Hanover NH, 037552.\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two18\' WHERE joinkey = \'wm99ab725\' AND pap_author = \'Ambros VR\" Affiliation_address \"Department of Biological Sciences, Dartmouth College, Hanover NH, 037552.\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-24 09:51:36.656255-08\' WHERE joinkey = \'cgc2021\' AND pap_author = \'Andachi Y\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two20\' WHERE joinkey = \'cgc2021\' AND pap_author = \'Andachi Y\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-24 09:51:36.868485-08\' WHERE joinkey = \'cgc3981\' AND pap_author = \'Andachi Y\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two20\' WHERE joinkey = \'cgc3981\' AND pap_author = \'Andachi Y\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-24 09:51:36.894066-08\' WHERE joinkey = \'cgc4727\' AND pap_author = \'Andachi Y\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two20\' WHERE joinkey = \'cgc4727\' AND pap_author = \'Andachi Y\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-24 09:51:36.908506-08\' WHERE joinkey = \'wbg12.5p21\' AND pap_author = \'Andachi Y\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two20\' WHERE joinkey = \'wbg12.5p21\' AND pap_author = \'Andachi Y\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-24 09:51:36.923719-08\' WHERE joinkey = \'wbg13.1p56\' AND pap_author = \'Andachi Y\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two20\' WHERE joinkey = \'wbg13.1p56\' AND pap_author = \'Andachi Y\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-24 09:51:36.966331-08\' WHERE joinkey = \'wm2001p738\' AND pap_author = \'Andachi Y\" Affiliation_address \"Genome Biology Lab, National Institute of Genetics, Mishima 411-8540, Japan\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two20\' WHERE joinkey = \'wm2001p738\' AND pap_author = \'Andachi Y\" Affiliation_address \"Genome Biology Lab, National Institute of Genetics, Mishima 411-8540, Japan\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-24 09:51:36.979282-08\' WHERE joinkey = \'wm93p33\' AND pap_author = \'Andachi Y\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two20\' WHERE joinkey = \'wm93p33\' AND pap_author = \'Andachi Y\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-24 09:51:36.994936-08\' WHERE joinkey = \'wm97ab17\' AND pap_author = \'Andachi Y\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two20\' WHERE joinkey = \'wm97ab17\' AND pap_author = \'Andachi Y\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-24 09:51:37.010592-08\' WHERE joinkey = \'wm99ab153\' AND pap_author = \'Andachi Y\" Affiliation_address \"Genome Biology Lab., National Institute of Genetics, Mishima 411-8540, Japan\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two20\' WHERE joinkey = \'wm99ab153\' AND pap_author = \'Andachi Y\" Affiliation_address \"Genome Biology Lab., National Institute of Genetics, Mishima 411-8540, Japan\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-24 10:13:54.41252-08\' WHERE joinkey = \'cgc1027\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'cgc1027\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-24 10:13:54.493854-08\' WHERE joinkey = \'cgc1065\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'cgc1065\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-24 10:13:54.506244-08\' WHERE joinkey = \'cgc1091\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'cgc1091\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-24 10:13:54.52141-08\' WHERE joinkey = \'cgc1094\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'cgc1094\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-24 10:13:54.538032-08\' WHERE joinkey = \'cgc1114\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'cgc1114\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-24 10:13:54.554235-08\' WHERE joinkey = \'cgc1192\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'cgc1192\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-24 10:13:54.578024-08\' WHERE joinkey = \'cgc1230\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'cgc1230\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 10:38:41.046216-08\' WHERE joinkey = \'cgc1234\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'cgc1234\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 10:38:41.197946-08\' WHERE joinkey = \'cgc1238\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'cgc1238\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 10:38:41.211375-08\' WHERE joinkey = \'cgc1539\' AND pap_author = \'Aldous P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'cgc1539\' AND pap_author = \'Aldous P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 10:38:41.227002-08\' WHERE joinkey = \'cgc1646\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'cgc1646\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 10:38:41.249756-08\' WHERE joinkey = \'cgc1658\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'cgc1658\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 10:38:41.272186-08\' WHERE joinkey = \'cgc1672\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'cgc1672\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 10:38:41.288862-08\' WHERE joinkey = \'cgc1813\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'cgc1813\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 10:38:41.422715-08\' WHERE joinkey = \'cgc1939\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'cgc1939\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 10:38:41.435602-08\' WHERE joinkey = \'cgc1958\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'cgc1958\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 10:42:38.537582-08\' WHERE joinkey = \'cgc2245\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'cgc2245\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 10:42:38.561528-08\' WHERE joinkey = \'cgc2354\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'cgc2354\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 10:42:38.588511-08\' WHERE joinkey = \'cgc2525\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'cgc2525\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 10:42:38.604537-08\' WHERE joinkey = \'cgc2536\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'cgc2536\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 10:42:38.62297-08\' WHERE joinkey = \'cgc2672\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'cgc2672\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 10:42:38.646081-08\' WHERE joinkey = \'cgc2781\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'cgc2781\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 10:42:38.666075-08\' WHERE joinkey = \'cgc3239\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'cgc3239\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 10:48:24.145022-08\' WHERE joinkey = \'cgc3259\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'cgc3259\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 10:48:24.17814-08\' WHERE joinkey = \'cgc3303\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'cgc3303\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 10:48:24.199671-08\' WHERE joinkey = \'cgc3389\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'cgc3389\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 10:48:24.2225-08\' WHERE joinkey = \'cgc3648\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'cgc3648\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 10:48:24.271904-08\' WHERE joinkey = \'cgc4313\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'cgc4313\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 10:50:20.659233-08\' WHERE joinkey = \'cgc710\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'cgc710\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 10:50:20.682836-08\' WHERE joinkey = \'cgc732\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'cgc732\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 10:50:20.694706-08\' WHERE joinkey = \'cgc738\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'cgc738\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 10:50:20.706216-08\' WHERE joinkey = \'cgc755\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'cgc755\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 10:50:20.718289-08\' WHERE joinkey = \'cgc799\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'cgc799\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 10:53:18.034033-08\' WHERE joinkey = \'cgc974\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'cgc974\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 10:53:18.059072-08\' WHERE joinkey = \'cgc983\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'cgc983\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 10:53:18.108243-08\' WHERE joinkey = \'euwm96ab43\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'euwm96ab43\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 10:53:18.129356-08\' WHERE joinkey = \'med94217737\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'med94217737\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 10:53:18.179471-08\' WHERE joinkey = \'mwwm96ab2\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'mwwm96ab2\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 10:55:02.323625-08\' WHERE joinkey = \'mwwm96ab54\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'mwwm96ab54\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 10:55:02.345185-08\' WHERE joinkey = \'mwwm96ab61\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'mwwm96ab61\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 10:55:02.358207-08\' WHERE joinkey = \'mwwm96ab67\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'mwwm96ab67\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 10:55:02.421859-08\' WHERE joinkey = \'mwwm96ab70\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'mwwm96ab70\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 10:55:02.435653-08\' WHERE joinkey = \'mwwm98ab57\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'mwwm98ab57\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 10:55:02.449934-08\' WHERE joinkey = \'mwwm98ab63\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'mwwm98ab63\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 10:55:02.4674-08\' WHERE joinkey = \'wbg10.1p38\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wbg10.1p38\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 10:55:02.486926-08\' WHERE joinkey = \'wbg10.1p48\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wbg10.1p48\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 10:55:02.503119-08\' WHERE joinkey = \'wbg10.1p69\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wbg10.1p69\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 10:55:02.51446-08\' WHERE joinkey = \'wbg10.1p70\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wbg10.1p70\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 10:57:23.751813-08\' WHERE joinkey = \'wbg10.2p30\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wbg10.2p30\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 10:57:23.775798-08\' WHERE joinkey = \'wbg10.2p31\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wbg10.2p31\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 10:57:23.787885-08\' WHERE joinkey = \'wbg10.2p32\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wbg10.2p32\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 10:57:23.808227-08\' WHERE joinkey = \'wbg11.1p54\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wbg11.1p54\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 10:57:23.825532-08\' WHERE joinkey = \'wbg11.5p65\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wbg11.5p65\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 10:57:23.842995-08\' WHERE joinkey = \'wbg11.5p90\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wbg11.5p90\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 10:57:23.854124-08\' WHERE joinkey = \'wbg11.5p91\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wbg11.5p91\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 10:57:23.869354-08\' WHERE joinkey = \'wbg12.1p24\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wbg12.1p24\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 10:57:23.885054-08\' WHERE joinkey = \'wbg12.1p27\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wbg12.1p27\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 10:57:23.89755-08\' WHERE joinkey = \'wbg12.2p59\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wbg12.2p59\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:01:05.713272-08\' WHERE joinkey = \'wbg12.2p98\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wbg12.2p98\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:01:05.732703-08\' WHERE joinkey = \'wbg12.3p42\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wbg12.3p42\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:01:05.747192-08\' WHERE joinkey = \'wbg12.3p59\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wbg12.3p59\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:01:05.762273-08\' WHERE joinkey = \'wbg12.4p14\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wbg12.4p14\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:01:05.781175-08\' WHERE joinkey = \'wbg12.4p69\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wbg12.4p69\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:01:05.803521-08\' WHERE joinkey = \'wbg12.5p25\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wbg12.5p25\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:01:05.81514-08\' WHERE joinkey = \'wbg12.5p26\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wbg12.5p26\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:01:05.825502-08\' WHERE joinkey = \'wbg13.4p74\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wbg13.4p74\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:01:05.838869-08\' WHERE joinkey = \'wbg14.1p90\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wbg14.1p90\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:01:05.857233-08\' WHERE joinkey = \'wbg14.3p11\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wbg14.3p11\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:05:32.453894-08\' WHERE joinkey = \'wbg15.2p43\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wbg15.2p43\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:05:32.493476-08\' WHERE joinkey = \'wbg5.2p26\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wbg5.2p26\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:05:32.505191-08\' WHERE joinkey = \'wbg8.1p49\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wbg8.1p49\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:05:32.522959-08\' WHERE joinkey = \'wbg8.1p8\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wbg8.1p8\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:05:32.535447-08\' WHERE joinkey = \'wbg8.2p49\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wbg8.2p49\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:05:32.548417-08\' WHERE joinkey = \'wbg8.2p53\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wbg8.2p53\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:07:48.472784-08\' WHERE joinkey = \'wbg8.2p56\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wbg8.2p56\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:07:48.494866-08\' WHERE joinkey = \'wbg8.3p85\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wbg8.3p85\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:07:48.508938-08\' WHERE joinkey = \'wbg9.1p20\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wbg9.1p20\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:07:48.522697-08\' WHERE joinkey = \'wbg9.1p27\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wbg9.1p27\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:07:48.53791-08\' WHERE joinkey = \'wbg9.1p29\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wbg9.1p29\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:07:48.548431-08\' WHERE joinkey = \'wbg9.2p40\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wbg9.2p40\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:07:48.567501-08\' WHERE joinkey = \'wbg9.3p14\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wbg9.3p14\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:07:48.58217-08\' WHERE joinkey = \'wbg9.3p16\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wbg9.3p16\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:07:48.595559-08\' WHERE joinkey = \'wbg9.3p40\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wbg9.3p40\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:11:07.023919-08\' WHERE joinkey = \'wm2001p561\' AND pap_author = \'Anderson P\" Affiliation_address \"UW-Madison, Department of Genetics, 445 Henry Mall, Madison, WI  53706\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wm2001p561\' AND pap_author = \'Anderson P\" Affiliation_address \"UW-Madison, Department of Genetics, 445 Henry Mall, Madison, WI  53706\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:11:07.05251-08\' WHERE joinkey = \'wm2001p564\' AND pap_author = \'Anderson P\" Affiliation_address \"Department of Genetics, University of Wisconsin-Madison\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wm2001p564\' AND pap_author = \'Anderson P\" Affiliation_address \"Department of Genetics, University of Wisconsin-Madison\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:11:07.065887-08\' WHERE joinkey = \'wm2001p7\' AND pap_author = \'Anderson P\" Affiliation_address \"Department Of Genetics, University of Wisconsin, Madison, WI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wm2001p7\' AND pap_author = \'Anderson P\" Affiliation_address \"Department Of Genetics, University of Wisconsin, Madison, WI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:11:07.120521-08\' WHERE joinkey = \'wm2001p823\' AND pap_author = \'Anderson P\" Affiliation_address \"Dept. of Genetics, UW-Madison, Madison WI, 53706.\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wm2001p823\' AND pap_author = \'Anderson P\" Affiliation_address \"Dept. of Genetics, UW-Madison, Madison WI, 53706.\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:14:48.8419-08\' WHERE joinkey = \'wm79p72\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wm79p72\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:14:48.873268-08\' WHERE joinkey = \'wm81p6\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wm81p6\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:14:48.887063-08\' WHERE joinkey = \'wm83p72\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wm83p72\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:14:48.901295-08\' WHERE joinkey = \'wm83p98\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wm83p98\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:14:48.913886-08\' WHERE joinkey = \'wm85p157\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wm85p157\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:16:32.485045-08\' WHERE joinkey = \'wm85p158\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wm85p158\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:16:32.506867-08\' WHERE joinkey = \'wm85p35\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wm85p35\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:16:32.519186-08\' WHERE joinkey = \'wm85p51\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wm85p51\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:16:32.534808-08\' WHERE joinkey = \'wm87p132\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wm87p132\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:16:32.549172-08\' WHERE joinkey = \'wm87p135\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wm87p135\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:16:32.567072-08\' WHERE joinkey = \'wm87p139\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wm87p139\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:16:32.579387-08\' WHERE joinkey = \'wm87p154\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wm87p154\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:16:32.598826-08\' WHERE joinkey = \'wm87p171\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wm87p171\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:16:32.610999-08\' WHERE joinkey = \'wm89p201\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wm89p201\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:16:32.624328-08\' WHERE joinkey = \'wm89p21\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wm89p21\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:18:34.077345-08\' WHERE joinkey = \'wm89p223\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wm89p223\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:18:34.099199-08\' WHERE joinkey = \'wm89p23\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wm89p23\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:18:34.117413-08\' WHERE joinkey = \'wm89p235\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wm89p235\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:18:34.138549-08\' WHERE joinkey = \'wm89p50\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wm89p50\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:18:34.153242-08\' WHERE joinkey = \'wm91p134\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wm91p134\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:18:34.167713-08\' WHERE joinkey = \'wm91p19\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wm91p19\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:18:34.183936-08\' WHERE joinkey = \'wm91p300\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wm91p300\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:18:34.196653-08\' WHERE joinkey = \'wm91p36\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wm91p36\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:18:34.217734-08\' WHERE joinkey = \'wm91p70\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wm91p70\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:20:50.459845-08\' WHERE joinkey = \'wm91p71\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wm91p71\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:20:50.484559-08\' WHERE joinkey = \'wm91p84\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wm91p84\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:20:50.495971-08\' WHERE joinkey = \'wm91p89\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wm91p89\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:20:50.508428-08\' WHERE joinkey = \'wm93p181\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wm93p181\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:20:50.528244-08\' WHERE joinkey = \'wm93p256\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wm93p256\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:20:50.543311-08\' WHERE joinkey = \'wm93p304\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wm93p304\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:20:50.556021-08\' WHERE joinkey = \'wm93p339\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wm93p339\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:20:50.569883-08\' WHERE joinkey = \'wm93p34\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wm93p34\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:20:50.669166-08\' WHERE joinkey = \'wm93p360\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wm93p360\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:22:57.507126-08\' WHERE joinkey = \'wm93p387\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wm93p387\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:22:57.527607-08\' WHERE joinkey = \'wm93p419\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wm93p419\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:22:57.543205-08\' WHERE joinkey = \'wm93p70\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wm93p70\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:22:57.581161-08\' WHERE joinkey = \'wm93p71\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wm93p71\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:22:57.608128-08\' WHERE joinkey = \'wm93p97\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wm93p97\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:22:57.622608-08\' WHERE joinkey = \'wm95p142\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wm95p142\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:22:57.636806-08\' WHERE joinkey = \'wm95p401\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wm95p401\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:22:57.661569-08\' WHERE joinkey = \'wm95p539\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wm95p539\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:22:57.676426-08\' WHERE joinkey = \'wm95p77\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wm95p77\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:22:57.688851-08\' WHERE joinkey = \'wm95p97\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wm95p97\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:25:19.819056-08\' WHERE joinkey = \'wm97ab18\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wm97ab18\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:25:19.861931-08\' WHERE joinkey = \'wm97ab331\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wm97ab331\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:25:19.877292-08\' WHERE joinkey = \'wm97ab390\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wm97ab390\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:25:19.89321-08\' WHERE joinkey = \'wm97ab412\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wm97ab412\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:25:19.907247-08\' WHERE joinkey = \'wm97ab454\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wm97ab454\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:25:19.926428-08\' WHERE joinkey = \'wm97ab455\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wm97ab455\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:25:19.936483-08\' WHERE joinkey = \'wm97ab463\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wm97ab463\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:25:19.952326-08\' WHERE joinkey = \'wm97ab632\' AND pap_author = \'Anderson P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wm97ab632\' AND pap_author = \'Anderson P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:25:19.971738-08\' WHERE joinkey = \'wm99ab10\' AND pap_author = \'Anderson P\" Affiliation_address \"Department of Genetics, University of Wisconsin, 445 Henry Mall, Madison, WI 53706\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wm99ab10\' AND pap_author = \'Anderson P\" Affiliation_address \"Department of Genetics, University of Wisconsin, 445 Henry Mall, Madison, WI 53706\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:25:19.993511-08\' WHERE joinkey = \'wm99ab226\' AND pap_author = \'Anderson P\" Affiliation_address \"Dept of Genetics, UW Madison, Madison WI 53706.\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wm99ab226\' AND pap_author = \'Anderson P\" Affiliation_address \"Dept of Genetics, UW Madison, Madison WI 53706.\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:27:29.31471-08\' WHERE joinkey = \'wm99ab353\' AND pap_author = \'Anderson P\" Affiliation_address \"Laboratory of Genetics, UW Madison, Madison, WI 53706\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wm99ab353\' AND pap_author = \'Anderson P\" Affiliation_address \"Laboratory of Genetics, UW Madison, Madison, WI 53706\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:27:29.344769-08\' WHERE joinkey = \'wm99ab501\' AND pap_author = \'Anderson P\" Affiliation_address \"Department of Genetics, University of Wisconsin, Madison, WI 53706.\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wm99ab501\' AND pap_author = \'Anderson P\" Affiliation_address \"Department of Genetics, University of Wisconsin, Madison, WI 53706.\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:27:29.365267-08\' WHERE joinkey = \'wm99ab570\' AND pap_author = \'Anderson P\" Affiliation_address \"Dept. of Genetics, UW-Madison, Madison WI, 53706.\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wm99ab570\' AND pap_author = \'Anderson P\" Affiliation_address \"Dept. of Genetics, UW-Madison, Madison WI, 53706.\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:27:29.388179-08\' WHERE joinkey = \'wm99ab766\' AND pap_author = \'Anderson P\" Affiliation_address \"Department of Genetics, University of Wisconsin-Madison\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two21\' WHERE joinkey = \'wm99ab766\' AND pap_author = \'Anderson P\" Affiliation_address \"Department of Genetics, University of Wisconsin-Madison\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:30:45.872922-08\' WHERE joinkey = \'cgc5256\' AND pap_author = \'Antoshechkin I\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two22\' WHERE joinkey = \'cgc5256\' AND pap_author = \'Antoshechkin I\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:30:45.916391-08\' WHERE joinkey = \'wcwm2000ab92\' AND pap_author = \'Antoshechkin I\" Affiliation_address \"Department of MCD Biology, University of Colorado, Boulder, CO 80309\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two22\' WHERE joinkey = \'wcwm2000ab92\' AND pap_author = \'Antoshechkin I\" Affiliation_address \"Department of MCD Biology, University of Colorado, Boulder, CO 80309\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:30:45.959244-08\' WHERE joinkey = \'wcwm98ab194\' AND pap_author = \'Antoshechkin I\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two22\' WHERE joinkey = \'wcwm98ab194\' AND pap_author = \'Antoshechkin I\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:30:45.978298-08\' WHERE joinkey = \'wm2001p1030\' AND pap_author = \'Antoshechkin I\" Affiliation_address \"HHMI, Department of MCDB, University of Colorado, Boulder, CO 80309, USA\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two22\' WHERE joinkey = \'wm2001p1030\' AND pap_author = \'Antoshechkin I\" Affiliation_address \"HHMI, Department of MCDB, University of Colorado, Boulder, CO 80309, USA\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:30:46.000355-08\' WHERE joinkey = \'wm2001p187\' AND pap_author = \'Antoshechkin I\" Affiliation_address \"Howard Hughes Medical Institute and Department of Molecular, Cellular and Developmental Biology, University of Colorado, Boulder, CO 80309-0347, USA\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two22\' WHERE joinkey = \'wm2001p187\' AND pap_author = \'Antoshechkin I\" Affiliation_address \"Howard Hughes Medical Institute and Department of Molecular, Cellular and Developmental Biology, University of Colorado, Boulder, CO 80309-0347, USA\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:30:46.016265-08\' WHERE joinkey = \'wm99ab155\' AND pap_author = \'Antoshechkin I\" Affiliation_address \"HHMI, Department of MCDB, University of colorado, Boulder, CO 80309\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two22\' WHERE joinkey = \'wm99ab155\' AND pap_author = \'Antoshechkin I\" Affiliation_address \"HHMI, Department of MCDB, University of colorado, Boulder, CO 80309\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:34:47.065518-08\' WHERE joinkey = \'cgc3244\' AND pap_author = \'Apfeld J\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two23\' WHERE joinkey = \'cgc3244\' AND pap_author = \'Apfeld J\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:34:47.084777-08\' WHERE joinkey = \'cgc3835\' AND pap_author = \'Apfeld J\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two23\' WHERE joinkey = \'cgc3835\' AND pap_author = \'Apfeld J\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:34:47.134928-08\' WHERE joinkey = \'cgc5065\' AND pap_author = \'Apfeld J\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two23\' WHERE joinkey = \'cgc5065\' AND pap_author = \'Apfeld J\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:34:47.19402-08\' WHERE joinkey = \'cgc5374\' AND pap_author = \'Apfeld J\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two23\' WHERE joinkey = \'cgc5374\' AND pap_author = \'Apfeld J\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:34:47.217426-08\' WHERE joinkey = \'wbg14.4p48\' AND pap_author = \'Apfeld J\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two23\' WHERE joinkey = \'wbg14.4p48\' AND pap_author = \'Apfeld J\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:34:47.231799-08\' WHERE joinkey = \'wbg15.5p30\' AND pap_author = \'Apfeld J\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two23\' WHERE joinkey = \'wbg15.5p30\' AND pap_author = \'Apfeld J\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:34:47.248826-08\' WHERE joinkey = \'wcwm2000ab47\' AND pap_author = \'Apfeld J\" Affiliation_address \"Department of Biochemistry and Biophysics, University of California San Francisco\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two23\' WHERE joinkey = \'wcwm2000ab47\' AND pap_author = \'Apfeld J\" Affiliation_address \"Department of Biochemistry and Biophysics, University of California San Francisco\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:34:47.289315-08\' WHERE joinkey = \'wcwm2000ab89\' AND pap_author = \'Apfeld J\" Affiliation_address \"Department of Biochemistry and Biophysics, UCSF, San Francisco, CA 94143\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two23\' WHERE joinkey = \'wcwm2000ab89\' AND pap_author = \'Apfeld J\" Affiliation_address \"Department of Biochemistry and Biophysics, UCSF, San Francisco, CA 94143\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:34:47.313866-08\' WHERE joinkey = \'wcwm96ab5\' AND pap_author = \'Apfeld J\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two23\' WHERE joinkey = \'wcwm96ab5\' AND pap_author = \'Apfeld J\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:34:47.327355-08\' WHERE joinkey = \'wcwm98ab8\' AND pap_author = \'Apfeld J\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two23\' WHERE joinkey = \'wcwm98ab8\' AND pap_author = \'Apfeld J\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:36:26.040355-08\' WHERE joinkey = \'wm2001p244\' AND pap_author = \'Apfeld J\" Affiliation_address \"Dept. of Biochemistry and Biophysics, University of California San Francisco\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two23\' WHERE joinkey = \'wm2001p244\' AND pap_author = \'Apfeld J\" Affiliation_address \"Dept. of Biochemistry and Biophysics, University of California San Francisco\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:36:26.093849-08\' WHERE joinkey = \'wm2001p328\' AND pap_author = \'Apfeld J\" Affiliation_address \"Department of Biochemistry and Biophysics, UCSF, San Francisco, CA 94143\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two23\' WHERE joinkey = \'wm2001p328\' AND pap_author = \'Apfeld J\" Affiliation_address \"Department of Biochemistry and Biophysics, UCSF, San Francisco, CA 94143\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:36:26.106919-08\' WHERE joinkey = \'wm97ab22\' AND pap_author = \'Apfeld J\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two23\' WHERE joinkey = \'wm97ab22\' AND pap_author = \'Apfeld J\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:36:26.123016-08\' WHERE joinkey = \'wm99ab119\' AND pap_author = \'Apfeld J\" Affiliation_address \"University of California, San Francisco, CA 94143-0448\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two23\' WHERE joinkey = \'wm99ab119\' AND pap_author = \'Apfeld J\" Affiliation_address \"University of California, San Francisco, CA 94143-0448\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:36:26.248409-08\' WHERE joinkey = \'wm99ab144\' AND pap_author = \'Apfeld J\" Affiliation_address \"Dept. of Biochemistry and Biophysics, University of California San Francisco, 513 Parnassus Ave., San Francisco, CA 94143-0448\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two23\' WHERE joinkey = \'wm99ab144\' AND pap_author = \'Apfeld J\" Affiliation_address \"Dept. of Biochemistry and Biophysics, University of California San Francisco, 513 Parnassus Ave., San Francisco, CA 94143-0448\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:38:37.909969-08\' WHERE joinkey = \'cgc1446\' AND pap_author = \'Arasu P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two24\' WHERE joinkey = \'cgc1446\' AND pap_author = \'Arasu P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:38:37.937403-08\' WHERE joinkey = \'cgc1467\' AND pap_author = \'Arasu P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two24\' WHERE joinkey = \'cgc1467\' AND pap_author = \'Arasu P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:38:37.967418-08\' WHERE joinkey = \'cgc1468\' AND pap_author = \'Arasu P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two24\' WHERE joinkey = \'cgc1468\' AND pap_author = \'Arasu P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:38:37.980846-08\' WHERE joinkey = \'wbg11.3p46\' AND pap_author = \'Arasu P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two24\' WHERE joinkey = \'wbg11.3p46\' AND pap_author = \'Arasu P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:38:37.994291-08\' WHERE joinkey = \'wbg11.3p47\' AND pap_author = \'Arasu P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two24\' WHERE joinkey = \'wbg11.3p47\' AND pap_author = \'Arasu P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:38:38.007511-08\' WHERE joinkey = \'wm87p178\' AND pap_author = \'Arasu P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two24\' WHERE joinkey = \'wm87p178\' AND pap_author = \'Arasu P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:38:38.053524-08\' WHERE joinkey = \'wm89p31\' AND pap_author = \'Arasu P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two24\' WHERE joinkey = \'wm89p31\' AND pap_author = \'Arasu P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:38:38.066054-08\' WHERE joinkey = \'wm89p96\' AND pap_author = \'Arasu P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two24\' WHERE joinkey = \'wm89p96\' AND pap_author = \'Arasu P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:38:38.088509-08\' WHERE joinkey = \'wm91p252\' AND pap_author = \'Arasu P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two24\' WHERE joinkey = \'wm91p252\' AND pap_author = \'Arasu P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:52:31.370292-08\' WHERE joinkey = \'cgc1612\' AND pap_author = \'Arduengo PM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two25\' WHERE joinkey = \'cgc1612\' AND pap_author = \'Arduengo PM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:52:31.395611-08\' WHERE joinkey = \'cgc3351\' AND pap_author = \'Arduengo PM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two25\' WHERE joinkey = \'cgc3351\' AND pap_author = \'Arduengo PM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:52:31.409976-08\' WHERE joinkey = \'ecwm96ab5\' AND pap_author = \'Arduengo PM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two25\' WHERE joinkey = \'ecwm96ab5\' AND pap_author = \'Arduengo PM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:52:31.42279-08\' WHERE joinkey = \'wbg11.4p22\' AND pap_author = \'Arduengo PM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two25\' WHERE joinkey = \'wbg11.4p22\' AND pap_author = \'Arduengo PM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:52:31.435474-08\' WHERE joinkey = \'wm91p366\' AND pap_author = \'Arduengo PM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two25\' WHERE joinkey = \'wm91p366\' AND pap_author = \'Arduengo PM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:52:31.452977-08\' WHERE joinkey = \'wm93p36\' AND pap_author = \'Arduengo PM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two25\' WHERE joinkey = \'wm93p36\' AND pap_author = \'Arduengo PM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:52:31.465745-08\' WHERE joinkey = \'wm93p53\' AND pap_author = \'Arduengo PM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two25\' WHERE joinkey = \'wm93p53\' AND pap_author = \'Arduengo PM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:52:31.479855-08\' WHERE joinkey = \'wm95p100\' AND pap_author = \'Arduengo PM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two25\' WHERE joinkey = \'wm95p100\' AND pap_author = \'Arduengo PM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:52:31.494978-08\' WHERE joinkey = \'wm97ab23\' AND pap_author = \'Arduengo PM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two25\' WHERE joinkey = \'wm97ab23\' AND pap_author = \'Arduengo PM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:56:08.077061-08\' WHERE joinkey = \'cgc1293\' AND pap_author = \'Aroian RV\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two26\' WHERE joinkey = \'cgc1293\' AND pap_author = \'Aroian RV\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:56:08.107348-08\' WHERE joinkey = \'cgc1355\' AND pap_author = \'Aroian RV\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two26\' WHERE joinkey = \'cgc1355\' AND pap_author = \'Aroian RV\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:56:08.125466-08\' WHERE joinkey = \'cgc1367\' AND pap_author = \'Aroian RV\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two26\' WHERE joinkey = \'cgc1367\' AND pap_author = \'Aroian RV\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:56:08.139624-08\' WHERE joinkey = \'cgc1404\' AND pap_author = \'Aroian RV\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two26\' WHERE joinkey = \'cgc1404\' AND pap_author = \'Aroian RV\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:56:08.158723-08\' WHERE joinkey = \'cgc1667\' AND pap_author = \'Aroian RV\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two26\' WHERE joinkey = \'cgc1667\' AND pap_author = \'Aroian RV\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:56:08.175784-08\' WHERE joinkey = \'cgc1917\' AND pap_author = \'Aroian RV\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two26\' WHERE joinkey = \'cgc1917\' AND pap_author = \'Aroian RV\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:56:08.199078-08\' WHERE joinkey = \'cgc2796\' AND pap_author = \'Aroian RV\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two26\' WHERE joinkey = \'cgc2796\' AND pap_author = \'Aroian RV\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:56:08.212456-08\' WHERE joinkey = \'cgc3758\' AND pap_author = \'Aroian RV\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two26\' WHERE joinkey = \'cgc3758\' AND pap_author = \'Aroian RV\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:56:08.234906-08\' WHERE joinkey = \'cgc4264\' AND pap_author = \'Aroian RV\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two26\' WHERE joinkey = \'cgc4264\' AND pap_author = \'Aroian RV\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:56:08.254957-08\' WHERE joinkey = \'cgc4706\' AND pap_author = \'Aroian RV\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two26\' WHERE joinkey = \'cgc4706\' AND pap_author = \'Aroian RV\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:59:22.190971-08\' WHERE joinkey = \'cgc4776\' AND pap_author = \'Aroian RV\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two26\' WHERE joinkey = \'cgc4776\' AND pap_author = \'Aroian RV\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:59:22.216027-08\' WHERE joinkey = \'cgc4916\' AND pap_author = \'Aroian RV\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two26\' WHERE joinkey = \'cgc4916\' AND pap_author = \'Aroian RV\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:59:22.238301-08\' WHERE joinkey = \'cgc5095\' AND pap_author = \'Aroian RV\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two26\' WHERE joinkey = \'cgc5095\' AND pap_author = \'Aroian RV\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:59:22.262292-08\' WHERE joinkey = \'med94147981\' AND pap_author = \'Aroian RV\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two26\' WHERE joinkey = \'med94147981\' AND pap_author = \'Aroian RV\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:59:22.275071-08\' WHERE joinkey = \'wbg10.2p81\' AND pap_author = \'Aroian RV\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two26\' WHERE joinkey = \'wbg10.2p81\' AND pap_author = \'Aroian RV\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:59:22.294462-08\' WHERE joinkey = \'wbg10.3p132\' AND pap_author = \'Aroian RV\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two26\' WHERE joinkey = \'wbg10.3p132\' AND pap_author = \'Aroian RV\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:59:22.308585-08\' WHERE joinkey = \'wbg11.2p105\' AND pap_author = \'Aroian RV\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two26\' WHERE joinkey = \'wbg11.2p105\' AND pap_author = \'Aroian RV\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:59:22.325314-08\' WHERE joinkey = \'wbg11.2p67\' AND pap_author = \'Aroian RV\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two26\' WHERE joinkey = \'wbg11.2p67\' AND pap_author = \'Aroian RV\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:59:22.349129-08\' WHERE joinkey = \'wbg11.4p65\' AND pap_author = \'Aroian RV\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two26\' WHERE joinkey = \'wbg11.4p65\' AND pap_author = \'Aroian RV\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 11:59:22.369154-08\' WHERE joinkey = \'wbg12.2p57\' AND pap_author = \'Aroian RV\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two26\' WHERE joinkey = \'wbg12.2p57\' AND pap_author = \'Aroian RV\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 12:01:17.024254-08\' WHERE joinkey = \'wbg12.4p25\' AND pap_author = \'Aroian RV\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two26\' WHERE joinkey = \'wbg12.4p25\' AND pap_author = \'Aroian RV\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 12:01:17.047363-08\' WHERE joinkey = \'wcwm2000ab139\' AND pap_author = \'Aroian RV\" Affiliation_address \"UC San Diego, Department of Biology\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two26\' WHERE joinkey = \'wcwm2000ab139\' AND pap_author = \'Aroian RV\" Affiliation_address \"UC San Diego, Department of Biology\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 12:01:17.069281-08\' WHERE joinkey = \'wcwm2000ab194\' AND pap_author = \'Aroian RV\" Affiliation_address \"Dept. of Biology, UC San Diego\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two26\' WHERE joinkey = \'wcwm2000ab194\' AND pap_author = \'Aroian RV\" Affiliation_address \"Dept. of Biology, UC San Diego\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 12:01:17.113193-08\' WHERE joinkey = \'wcwm2000ab206\' AND pap_author = \'Aroian RV\" Affiliation_address \"University of California, San Diego, La Jolla, CA 92093\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two26\' WHERE joinkey = \'wcwm2000ab206\' AND pap_author = \'Aroian RV\" Affiliation_address \"University of California, San Diego, La Jolla, CA 92093\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 12:01:17.141949-08\' WHERE joinkey = \'wcwm2000ab213\' AND pap_author = \'Aroian RV\" Affiliation_address \"University of California, San Diego, La Jolla, CA 92093\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two26\' WHERE joinkey = \'wcwm2000ab213\' AND pap_author = \'Aroian RV\" Affiliation_address \"University of California, San Diego, La Jolla, CA 92093\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 12:01:17.162842-08\' WHERE joinkey = \'wcwm2000ab43\' AND pap_author = \'Aroian RV\" Affiliation_address \"U.C. San Diego\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two26\' WHERE joinkey = \'wcwm2000ab43\' AND pap_author = \'Aroian RV\" Affiliation_address \"U.C. San Diego\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 12:01:17.183413-08\' WHERE joinkey = \'wcwm2000ab54\' AND pap_author = \'Aroian RV\" Affiliation_address \"University of California, San Diego. La Jolla, CA 92093-0349\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two26\' WHERE joinkey = \'wcwm2000ab54\' AND pap_author = \'Aroian RV\" Affiliation_address \"University of California, San Diego. La Jolla, CA 92093-0349\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 12:01:17.199097-08\' WHERE joinkey = \'wcwm96ab6\' AND pap_author = \'Aroian RV\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two26\' WHERE joinkey = \'wcwm96ab6\' AND pap_author = \'Aroian RV\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 12:01:17.211744-08\' WHERE joinkey = \'wcwm98ab128\' AND pap_author = \'Aroian RV\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two26\' WHERE joinkey = \'wcwm98ab128\' AND pap_author = \'Aroian RV\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 12:01:17.23397-08\' WHERE joinkey = \'wcwm98ab140\' AND pap_author = \'Aroian RV\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two26\' WHERE joinkey = \'wcwm98ab140\' AND pap_author = \'Aroian RV\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 12:03:50.511797-08\' WHERE joinkey = \'wcwm98ab166\' AND pap_author = \'Aroian RV\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two26\' WHERE joinkey = \'wcwm98ab166\' AND pap_author = \'Aroian RV\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 12:03:50.538318-08\' WHERE joinkey = \'wm2001p1074\' AND pap_author = \'Aroian RV\" Affiliation_address \"Section of Cell and Developmental Biology, Division of Biology, University of California, San Diego, La Jolla, CA 92093-0349\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two26\' WHERE joinkey = \'wm2001p1074\' AND pap_author = \'Aroian RV\" Affiliation_address \"Section of Cell and Developmental Biology, Division of Biology, University of California, San Diego, La Jolla, CA 92093-0349\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 12:03:50.559589-08\' WHERE joinkey = \'wm2001p279\' AND pap_author = \'Aroian RV\" Affiliation_address \"University of California, San Diego, La Jolla, CA 92093-0439\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two26\' WHERE joinkey = \'wm2001p279\' AND pap_author = \'Aroian RV\" Affiliation_address \"University of California, San Diego, La Jolla, CA 92093-0439\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 12:03:50.578168-08\' WHERE joinkey = \'wm2001p36\' AND pap_author = \'Aroian RV\" Affiliation_address \"University of California, San Diego, La Jolla, CA 92093\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two26\' WHERE joinkey = \'wm2001p36\' AND pap_author = \'Aroian RV\" Affiliation_address \"University of California, San Diego, La Jolla, CA 92093\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 12:03:50.601297-08\' WHERE joinkey = \'wm2001p610\' AND pap_author = \'Aroian RV\" Affiliation_address \"University of California, San Diego, La Jolla, CA 92093-0349\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two26\' WHERE joinkey = \'wm2001p610\' AND pap_author = \'Aroian RV\" Affiliation_address \"University of California, San Diego, La Jolla, CA 92093-0349\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 12:03:50.619906-08\' WHERE joinkey = \'wm2001p736\' AND pap_author = \'Aroian RV\" Affiliation_address \"Section of Cell and Developmental Biology, Division of Biology, University of California, San Diego, La Jolla, CA 92093-0349\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two26\' WHERE joinkey = \'wm2001p736\' AND pap_author = \'Aroian RV\" Affiliation_address \"Section of Cell and Developmental Biology, Division of Biology, University of California, San Diego, La Jolla, CA 92093-0349\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 12:03:50.653145-08\' WHERE joinkey = \'wm2001p961\' AND pap_author = \'Aroian RV\" Affiliation_address \"Dept. of Biology, University of California-San Diego, La Jolla, CA  92093-0349\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two26\' WHERE joinkey = \'wm2001p961\' AND pap_author = \'Aroian RV\" Affiliation_address \"Dept. of Biology, University of California-San Diego, La Jolla, CA  92093-0349\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 12:03:50.681929-08\' WHERE joinkey = \'wm89p108\' AND pap_author = \'Aroian RV\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two26\' WHERE joinkey = \'wm89p108\' AND pap_author = \'Aroian RV\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 12:03:50.699237-08\' WHERE joinkey = \'wm89p92\' AND pap_author = \'Aroian RV\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two26\' WHERE joinkey = \'wm89p92\' AND pap_author = \'Aroian RV\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 12:03:50.718014-08\' WHERE joinkey = \'wm91p244\' AND pap_author = \'Aroian RV\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two26\' WHERE joinkey = \'wm91p244\' AND pap_author = \'Aroian RV\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 12:38:58.273741-08\' WHERE joinkey = \'wm91p40\' AND pap_author = \'Aroian RV\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two26\' WHERE joinkey = \'wm91p40\' AND pap_author = \'Aroian RV\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 12:38:58.302868-08\' WHERE joinkey = \'wm93p270\' AND pap_author = \'Aroian RV\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two26\' WHERE joinkey = \'wm93p270\' AND pap_author = \'Aroian RV\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 12:38:58.327737-08\' WHERE joinkey = \'wm95p28\' AND pap_author = \'Aroian RV\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two26\' WHERE joinkey = \'wm95p28\' AND pap_author = \'Aroian RV\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 12:38:58.341768-08\' WHERE joinkey = \'wm97ab24\' AND pap_author = \'Aroian RV\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two26\' WHERE joinkey = \'wm97ab24\' AND pap_author = \'Aroian RV\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 12:38:58.359597-08\' WHERE joinkey = \'wm99ab127\' AND pap_author = \'Aroian RV\" Affiliation_address \"U.California San Diego\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two26\' WHERE joinkey = \'wm99ab127\' AND pap_author = \'Aroian RV\" Affiliation_address \"U.California San Diego\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 12:38:58.43186-08\' WHERE joinkey = \'wm99ab80\' AND pap_author = \'Aroian RV\" Affiliation_address \"U.C. San Diego.\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two26\' WHERE joinkey = \'wm99ab80\' AND pap_author = \'Aroian RV\" Affiliation_address \"U.C. San Diego.\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 12:56:30.610563-08\' WHERE joinkey = \'cgc1972\' AND pap_author = \'Aronoff R\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two27\' WHERE joinkey = \'cgc1972\' AND pap_author = \'Aronoff R\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 12:56:30.657654-08\' WHERE joinkey = \'cgc4529\' AND pap_author = \'Aronoff R\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two27\' WHERE joinkey = \'cgc4529\' AND pap_author = \'Aronoff R\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 12:56:30.694603-08\' WHERE joinkey = \'med94340822\' AND pap_author = \'Aronoff R\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two27\' WHERE joinkey = \'med94340822\' AND pap_author = \'Aronoff R\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 12:56:30.709674-08\' WHERE joinkey = \'wbg13.2p93\' AND pap_author = \'Aronoff R\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two27\' WHERE joinkey = \'wbg13.2p93\' AND pap_author = \'Aronoff R\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 12:56:30.722965-08\' WHERE joinkey = \'wbg17.2p24\' AND pap_author = \'Rachel Aronoff\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two27\' WHERE joinkey = \'wbg17.2p24\' AND pap_author = \'Rachel Aronoff\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 12:56:30.78617-08\' WHERE joinkey = \'wm2001p688\' AND pap_author = \'Aronoff R\" Affiliation_address \"Max-Planck Institute for Medical Research, Molecular Neurobiology, Jahnstrasse 29, Heidelberg, 69120 Germany\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two27\' WHERE joinkey = \'wm2001p688\' AND pap_author = \'Aronoff R\" Affiliation_address \"Max-Planck Institute for Medical Research, Molecular Neurobiology, Jahnstrasse 29, Heidelberg, 69120 Germany\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 12:57:52.194024-08\' WHERE joinkey = \'wm93p37\' AND pap_author = \'Aronoff R\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two27\' WHERE joinkey = \'wm93p37\' AND pap_author = \'Aronoff R\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 12:57:52.212298-08\' WHERE joinkey = \'wm95p103\' AND pap_author = \'Aronoff R\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two27\' WHERE joinkey = \'wm95p103\' AND pap_author = \'Aronoff R\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 12:57:52.227279-08\' WHERE joinkey = \'wm97ab101\' AND pap_author = \'Aronoff R\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two27\' WHERE joinkey = \'wm97ab101\' AND pap_author = \'Aronoff R\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 12:57:52.285084-08\' WHERE joinkey = \'wm99ab160\' AND pap_author = \'Aronoff R\" Affiliation_address \"Max-Planck Institute for Medical Research, Molecular Neurobiology, Jahnstrasse 29, D-69120, Heidelberg, Germany.\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two27\' WHERE joinkey = \'wm99ab160\' AND pap_author = \'Aronoff R\" Affiliation_address \"Max-Planck Institute for Medical Research, Molecular Neurobiology, Jahnstrasse 29, D-69120, Heidelberg, Germany.\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:00:40.239706-08\' WHERE joinkey = \'cgc1808\' AND pap_author = \'Arpagaus M\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two28\' WHERE joinkey = \'cgc1808\' AND pap_author = \'Arpagaus M\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:00:40.259396-08\' WHERE joinkey = \'cgc1887\' AND pap_author = \'Arpagaus M\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two28\' WHERE joinkey = \'cgc1887\' AND pap_author = \'Arpagaus M\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:00:40.293181-08\' WHERE joinkey = \'cgc1929\' AND pap_author = \'Arpagaus M\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two28\' WHERE joinkey = \'cgc1929\' AND pap_author = \'Arpagaus M\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:00:40.304644-08\' WHERE joinkey = \'cgc2110\' AND pap_author = \'Arpagaus M\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two28\' WHERE joinkey = \'cgc2110\' AND pap_author = \'Arpagaus M\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:00:40.325164-08\' WHERE joinkey = \'cgc2557\' AND pap_author = \'Arpagaus M\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two28\' WHERE joinkey = \'cgc2557\' AND pap_author = \'Arpagaus M\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:00:40.349465-08\' WHERE joinkey = \'cgc3034\' AND pap_author = \'Arpagaus M\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two28\' WHERE joinkey = \'cgc3034\' AND pap_author = \'Arpagaus M\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:00:40.377501-08\' WHERE joinkey = \'cgc3218\' AND pap_author = \'Arpagaus M\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two28\' WHERE joinkey = \'cgc3218\' AND pap_author = \'Arpagaus M\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:00:40.388925-08\' WHERE joinkey = \'cgc3620\' AND pap_author = \'Arpagaus M\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two28\' WHERE joinkey = \'cgc3620\' AND pap_author = \'Arpagaus M\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:00:40.421699-08\' WHERE joinkey = \'cgc3867\' AND pap_author = \'Arpagaus M\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two28\' WHERE joinkey = \'cgc3867\' AND pap_author = \'Arpagaus M\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:00:40.437579-08\' WHERE joinkey = \'cgc4251\' AND pap_author = \'Arpagaus M\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two28\' WHERE joinkey = \'cgc4251\' AND pap_author = \'Arpagaus M\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:03:08.637043-08\' WHERE joinkey = \'cgc4932\' AND pap_author = \'Arpagaus M\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two28\' WHERE joinkey = \'cgc4932\' AND pap_author = \'Arpagaus M\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:03:08.665669-08\' WHERE joinkey = \'euwm98ab21\' AND pap_author = \'Arpagaus M\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two28\' WHERE joinkey = \'euwm98ab21\' AND pap_author = \'Arpagaus M\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:03:08.694573-08\' WHERE joinkey = \'wbg13.5p43\' AND pap_author = \'Arpagaus M\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two28\' WHERE joinkey = \'wbg13.5p43\' AND pap_author = \'Arpagaus M\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:03:08.717811-08\' WHERE joinkey = \'wm91p41\' AND pap_author = \'Arpagaus M\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two28\' WHERE joinkey = \'wm91p41\' AND pap_author = \'Arpagaus M\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:03:08.735749-08\' WHERE joinkey = \'wm93p38\' AND pap_author = \'Arpagaus M\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two28\' WHERE joinkey = \'wm93p38\' AND pap_author = \'Arpagaus M\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:03:08.754353-08\' WHERE joinkey = \'wm95p104\' AND pap_author = \'Arpagaus M\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two28\' WHERE joinkey = \'wm95p104\' AND pap_author = \'Arpagaus M\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:03:08.772925-08\' WHERE joinkey = \'wm97ab109\' AND pap_author = \'Arpagaus M\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two28\' WHERE joinkey = \'wm97ab109\' AND pap_author = \'Arpagaus M\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:03:08.78968-08\' WHERE joinkey = \'wm97ab194\' AND pap_author = \'Arpagaus M\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two28\' WHERE joinkey = \'wm97ab194\' AND pap_author = \'Arpagaus M\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:03:08.831056-08\' WHERE joinkey = \'wm99ab243\' AND pap_author = \'Arpagaus M\" Affiliation_address \"Diffrenciation cellulaire, INRA, Montpellier, France\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two28\' WHERE joinkey = \'wm99ab243\' AND pap_author = \'Arpagaus M\" Affiliation_address \"Diffrenciation cellulaire, INRA, Montpellier, France\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:03:08.853714-08\' WHERE joinkey = \'wm99ab244\' AND pap_author = \'Arpagaus M\" Affiliation_address \"Diffrenciation cellulaire, INRA, Montpellier, France\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two28\' WHERE joinkey = \'wm99ab244\' AND pap_author = \'Arpagaus M\" Affiliation_address \"Diffrenciation cellulaire, INRA, Montpellier, France\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:05:29.077478-08\' WHERE joinkey = \'cgc4329\' AND pap_author = \'Asahina M\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two29\' WHERE joinkey = \'cgc4329\' AND pap_author = \'Asahina M\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:05:29.107913-08\' WHERE joinkey = \'euwm2000ab29\' AND pap_author = \'Asahina M\" Affiliation_address \"Address unknown\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two29\' WHERE joinkey = \'euwm2000ab29\' AND pap_author = \'Asahina M\" Affiliation_address \"Address unknown\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:07:28.252348-08\' WHERE joinkey = \'cgc3164\' AND pap_author = \'Ashcroft NR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two30\' WHERE joinkey = \'cgc3164\' AND pap_author = \'Ashcroft NR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:07:28.281468-08\' WHERE joinkey = \'cgc3325\' AND pap_author = \'Ashcroft NR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two30\' WHERE joinkey = \'cgc3325\' AND pap_author = \'Ashcroft NR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:07:28.301512-08\' WHERE joinkey = \'cgc3402\' AND pap_author = \'Ashcroft NR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two30\' WHERE joinkey = \'cgc3402\' AND pap_author = \'Ashcroft NR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:07:28.316447-08\' WHERE joinkey = \'cgc3510\' AND pap_author = \'Ashcroft NR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two30\' WHERE joinkey = \'cgc3510\' AND pap_author = \'Ashcroft NR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:07:28.357076-08\' WHERE joinkey = \'cgc4215\' AND pap_author = \'Ashcroft NR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two30\' WHERE joinkey = \'cgc4215\' AND pap_author = \'Ashcroft NR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:07:28.377221-08\' WHERE joinkey = \'cgc5294\' AND pap_author = \'Ashcroft N\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two30\' WHERE joinkey = \'cgc5294\' AND pap_author = \'Ashcroft N\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:07:28.405199-08\' WHERE joinkey = \'ecwm98ab31\' AND pap_author = \'Ashcroft NR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two30\' WHERE joinkey = \'ecwm98ab31\' AND pap_author = \'Ashcroft NR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:07:28.428242-08\' WHERE joinkey = \'ecwm98ab6\' AND pap_author = \'Ashcroft NR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two30\' WHERE joinkey = \'ecwm98ab6\' AND pap_author = \'Ashcroft NR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:07:28.442447-08\' WHERE joinkey = \'ecwm98ab91\' AND pap_author = \'Ashcroft NR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two30\' WHERE joinkey = \'ecwm98ab91\' AND pap_author = \'Ashcroft NR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:07:28.466774-08\' WHERE joinkey = \'euwm2000ab52\' AND pap_author = \'Ashcroft NR\" Affiliation_address \"Address unknown\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two30\' WHERE joinkey = \'euwm2000ab52\' AND pap_author = \'Ashcroft NR\" Affiliation_address \"Address unknown\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:08:47.173338-08\' WHERE joinkey = \'wbg15.1p62\' AND pap_author = \'Ashcroft NR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two30\' WHERE joinkey = \'wbg15.1p62\' AND pap_author = \'Ashcroft NR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:08:47.195126-08\' WHERE joinkey = \'wbg15.1p63\' AND pap_author = \'Ashcroft NR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two30\' WHERE joinkey = \'wbg15.1p63\' AND pap_author = \'Ashcroft NR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:08:47.217968-08\' WHERE joinkey = \'wm2001p975\' AND pap_author = \'Ashcroft NR\" Affiliation_address \"MRC Cell Mutation Unit, University of Sussex, Falmer, Brighton, BN1 9RR, UK\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two30\' WHERE joinkey = \'wm2001p975\' AND pap_author = \'Ashcroft NR\" Affiliation_address \"MRC Cell Mutation Unit, University of Sussex, Falmer, Brighton, BN1 9RR, UK\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:08:47.230943-08\' WHERE joinkey = \'wm97ab243\' AND pap_author = \'Ashcroft NR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two30\' WHERE joinkey = \'wm97ab243\' AND pap_author = \'Ashcroft NR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:08:47.249389-08\' WHERE joinkey = \'wm97ab25\' AND pap_author = \'Ashcroft NR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two30\' WHERE joinkey = \'wm97ab25\' AND pap_author = \'Ashcroft NR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:08:47.263692-08\' WHERE joinkey = \'wm99ab162\' AND pap_author = \'Ashcroft NR\" Affiliation_address \"ABL-Basic Research Program, FCRDC, Frederick, MD 21702\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two30\' WHERE joinkey = \'wm99ab162\' AND pap_author = \'Ashcroft NR\" Affiliation_address \"ABL-Basic Research Program, FCRDC, Frederick, MD 21702\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:12:39.947514-08\' WHERE joinkey = \'wm97ab26\' AND pap_author = \'Ashraf S\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two31\' WHERE joinkey = \'wm97ab26\' AND pap_author = \'Ashraf S\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:12:39.973113-08\' WHERE joinkey = \'wm97ab544\' AND pap_author = \'Ashraf S\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two31\' WHERE joinkey = \'wm97ab544\' AND pap_author = \'Ashraf S\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:16:46.288002-08\' WHERE joinkey = \'cgc1016\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'cgc1016\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:16:46.311616-08\' WHERE joinkey = \'cgc1197\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'cgc1197\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:16:46.324812-08\' WHERE joinkey = \'cgc1285\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'cgc1285\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:16:46.33914-08\' WHERE joinkey = \'cgc1578\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'cgc1578\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:16:46.358858-08\' WHERE joinkey = \'cgc1696\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'cgc1696\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:16:46.37188-08\' WHERE joinkey = \'cgc1709\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'cgc1709\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:16:46.396319-08\' WHERE joinkey = \'cgc1920\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'cgc1920\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:16:46.435545-08\' WHERE joinkey = \'cgc2254\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'cgc2254\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:24:57.444878-08\' WHERE joinkey = \'cgc2341\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'cgc2341\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:24:57.469927-08\' WHERE joinkey = \'cgc2371\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'cgc2371\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:24:57.506574-08\' WHERE joinkey = \'cgc2466\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'cgc2466\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:24:57.522328-08\' WHERE joinkey = \'cgc2505\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'cgc2505\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:24:57.54156-08\' WHERE joinkey = \'cgc2688\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'cgc2688\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:24:57.557183-08\' WHERE joinkey = \'cgc2789\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'cgc2789\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:24:57.582385-08\' WHERE joinkey = \'cgc2839\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'cgc2839\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:24:57.597743-08\' WHERE joinkey = \'cgc2912\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'cgc2912\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:24:57.61806-08\' WHERE joinkey = \'cgc2920\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'cgc2920\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:24:57.639508-08\' WHERE joinkey = \'cgc3059\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'cgc3059\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:26:54.846176-08\' WHERE joinkey = \'cgc3349\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'cgc3349\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:26:54.873628-08\' WHERE joinkey = \'cgc3763\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'cgc3763\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:26:54.88721-08\' WHERE joinkey = \'cgc3840\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'cgc3840\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:26:54.908118-08\' WHERE joinkey = \'cgc3890\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'cgc3890\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:26:54.928023-08\' WHERE joinkey = \'cgc3954\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'cgc3954\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:26:54.949107-08\' WHERE joinkey = \'cgc4381\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'cgc4381\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:26:54.969227-08\' WHERE joinkey = \'cgc4714\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'cgc4714\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:26:54.988858-08\' WHERE joinkey = \'cgc5033\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'cgc5033\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:26:55.051184-08\' WHERE joinkey = \'cgc5203\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'cgc5203\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:28:36.996066-08\' WHERE joinkey = \'ecwm98ab99\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'ecwm98ab99\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:28:37.041342-08\' WHERE joinkey = \'jwm2000ab77\' AND pap_author = \'Avery L\" Affiliation_address \"Department of Biochemistry, University of Texas Southwestern Medical Center, 6000 Harry Hines Blvd, Dallas, TX 75390-9148, USA\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'jwm2000ab77\' AND pap_author = \'Avery L\" Affiliation_address \"Department of Biochemistry, University of Texas Southwestern Medical Center, 6000 Harry Hines Blvd, Dallas, TX 75390-9148, USA\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:28:37.061615-08\' WHERE joinkey = \'med94206530\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'med94206530\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:28:37.078878-08\' WHERE joinkey = \'mwwm96ab20\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'mwwm96ab20\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:28:37.105331-08\' WHERE joinkey = \'mwwm96ab21\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'mwwm96ab21\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:28:37.118563-08\' WHERE joinkey = \'mwwm96ab57\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'mwwm96ab57\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:28:37.132602-08\' WHERE joinkey = \'wbg10.1p139\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wbg10.1p139\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:28:37.146441-08\' WHERE joinkey = \'wbg10.1p91\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wbg10.1p91\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:28:37.169095-08\' WHERE joinkey = \'wbg10.2p39\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wbg10.2p39\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:28:37.182763-08\' WHERE joinkey = \'wbg10.3p154\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wbg10.3p154\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:30:06.721253-08\' WHERE joinkey = \'wbg10.3p67\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wbg10.3p67\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:30:06.749637-08\' WHERE joinkey = \'wbg11.1p61\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wbg11.1p61\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:30:06.770776-08\' WHERE joinkey = \'wbg11.1p62\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wbg11.1p62\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:30:06.781558-08\' WHERE joinkey = \'wbg11.1p68\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wbg11.1p68\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:30:06.791638-08\' WHERE joinkey = \'wbg11.5p69\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wbg11.5p69\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:30:06.80743-08\' WHERE joinkey = \'wbg12.2p18\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wbg12.2p18\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:30:06.819397-08\' WHERE joinkey = \'wbg12.2p21\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wbg12.2p21\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:30:06.845874-08\' WHERE joinkey = \'wbg12.2p87\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wbg12.2p87\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:30:06.856961-08\' WHERE joinkey = \'wbg12.3p10\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wbg12.3p10\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:30:06.868503-08\' WHERE joinkey = \'wbg12.4p54\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wbg12.4p54\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:37:20.177134-08\' WHERE joinkey = \'wbg12.5p11\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wbg12.5p11\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:37:20.19862-08\' WHERE joinkey = \'wbg12.5p62\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wbg12.5p62\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:37:20.221326-08\' WHERE joinkey = \'wbg12.5p64\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wbg12.5p64\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:37:20.233416-08\' WHERE joinkey = \'wbg12.5p65\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wbg12.5p65\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:37:20.244619-08\' WHERE joinkey = \'wbg13.1p42\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wbg13.1p42\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:37:20.257475-08\' WHERE joinkey = \'wbg13.1p44\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wbg13.1p44\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:37:20.296297-08\' WHERE joinkey = \'wbg13.1p45\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wbg13.1p45\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:37:20.337055-08\' WHERE joinkey = \'wbg13.2p50\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wbg13.2p50\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:37:20.358838-08\' WHERE joinkey = \'wbg13.2p52\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wbg13.2p52\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:37:20.371891-08\' WHERE joinkey = \'wbg13.2p53\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wbg13.2p53\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:39:01.379649-08\' WHERE joinkey = \'wbg13.2p71\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wbg13.2p71\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:39:01.411248-08\' WHERE joinkey = \'wbg13.4p24\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wbg13.4p24\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:39:01.42658-08\' WHERE joinkey = \'wbg13.4p71\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wbg13.4p71\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:39:01.447393-08\' WHERE joinkey = \'wbg13.4p72\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wbg13.4p72\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:39:01.458074-08\' WHERE joinkey = \'wbg13.5p34\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wbg13.5p34\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:39:01.479056-08\' WHERE joinkey = \'wbg13.5p35\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wbg13.5p35\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:39:01.490462-08\' WHERE joinkey = \'wbg13.5p36\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wbg13.5p36\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:39:01.502483-08\' WHERE joinkey = \'wbg13.5p3a\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wbg13.5p3a\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:39:01.513288-08\' WHERE joinkey = \'wbg13.5p76\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wbg13.5p76\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:39:01.526922-08\' WHERE joinkey = \'wbg14.1p41\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wbg14.1p41\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:41:24.485748-08\' WHERE joinkey = \'wbg14.1p42\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wbg14.1p42\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:41:24.508772-08\' WHERE joinkey = \'wbg14.1p46\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wbg14.1p46\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:41:24.536461-08\' WHERE joinkey = \'wbg14.2p72\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wbg14.2p72\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:41:24.577023-08\' WHERE joinkey = \'wbg14.3p49\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wbg14.3p49\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:41:24.589928-08\' WHERE joinkey = \'wbg14.3p50\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wbg14.3p50\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:41:24.614227-08\' WHERE joinkey = \'wbg14.4p72\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wbg14.4p72\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:41:24.628685-08\' WHERE joinkey = \'wbg15.1p33\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wbg15.1p33\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:41:24.643369-08\' WHERE joinkey = \'wbg15.2p16\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wbg15.2p16\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:41:24.656576-08\' WHERE joinkey = \'wbg15.2p17\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wbg15.2p17\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:41:24.678354-08\' WHERE joinkey = \'wbg15.2p20\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wbg15.2p20\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:43:09.18673-08\' WHERE joinkey = \'wbg15.3p36\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wbg15.3p36\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:43:09.231426-08\' WHERE joinkey = \'wbg15.4p24\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wbg15.4p24\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:43:09.243635-08\' WHERE joinkey = \'wbg15.5p32\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wbg15.5p32\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:43:09.271192-08\' WHERE joinkey = \'wbg16.1p47\' AND pap_author = \'Avery L\" Affiliation_address \"Department of Molecular Biology, University of Texas Southwestern Medical Center, 6000 Harry Hines Blvd, Dallas, TX 75235-9148\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wbg16.1p47\' AND pap_author = \'Avery L\" Affiliation_address \"Department of Molecular Biology, University of Texas Southwestern Medical Center, 6000 Harry Hines Blvd, Dallas, TX 75235-9148\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:43:09.287046-08\' WHERE joinkey = \'wbg17.1p1a\' AND pap_author = \'Leon Avery\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wbg17.1p1a\' AND pap_author = \'Leon Avery\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:43:09.298409-08\' WHERE joinkey = \'wbg17.1p52\' AND pap_author = \'Leon Avery\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wbg17.1p52\' AND pap_author = \'Leon Avery\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:43:09.312299-08\' WHERE joinkey = \'wbg17.1p54\' AND pap_author = \'Leon Avery\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wbg17.1p54\' AND pap_author = \'Leon Avery\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:43:09.323079-08\' WHERE joinkey = \'wbg17.2p26\' AND pap_author = \'Leon Avery\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wbg17.2p26\' AND pap_author = \'Leon Avery\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:43:09.343397-08\' WHERE joinkey = \'wbg9.1p80\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wbg9.1p80\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:43:09.355103-08\' WHERE joinkey = \'wbg9.1p88\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wbg9.1p88\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:45:50.364017-08\' WHERE joinkey = \'wbg9.2p110\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wbg9.2p110\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:45:50.381616-08\' WHERE joinkey = \'wbg9.2p57\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wbg9.2p57\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:45:50.401166-08\' WHERE joinkey = \'wbg9.3p102\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wbg9.3p102\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:45:50.415908-08\' WHERE joinkey = \'wbg9.3p11\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wbg9.3p11\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:45:50.433635-08\' WHERE joinkey = \'wcwm2000ab167\' AND pap_author = \'Avery L\" Affiliation_address \"University of Texas Southwestern Medical Center, Department of Molecular Biology, Dallas, TX 75390-9148, USA\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wcwm2000ab167\' AND pap_author = \'Avery L\" Affiliation_address \"University of Texas Southwestern Medical Center, Department of Molecular Biology, Dallas, TX 75390-9148, USA\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:45:50.453319-08\' WHERE joinkey = \'wcwm2000ab197\' AND pap_author = \'Avery L\" Affiliation_address \"Department of Molecular Biology. University of Texas Southwestern Medical Center. Dallas, Texas 75390-6148\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wcwm2000ab197\' AND pap_author = \'Avery L\" Affiliation_address \"Department of Molecular Biology. University of Texas Southwestern Medical Center. Dallas, Texas 75390-6148\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:45:50.476542-08\' WHERE joinkey = \'wcwm2000ab28\' AND pap_author = \'Avery L\" Affiliation_address \"University of Texas Southwestern Medical Center, Department of Molecular Biology, Dallas, TX 75390-9148\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wcwm2000ab28\' AND pap_author = \'Avery L\" Affiliation_address \"University of Texas Southwestern Medical Center, Department of Molecular Biology, Dallas, TX 75390-9148\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:45:50.493553-08\' WHERE joinkey = \'wcwm2000ab29\' AND pap_author = \'Avery L\" Affiliation_address \"Department of Molecular Biology, UT Southwestern Medical Center. 6000 Harry Hines Blvd. Dallas, TX\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wcwm2000ab29\' AND pap_author = \'Avery L\" Affiliation_address \"Department of Molecular Biology, UT Southwestern Medical Center. 6000 Harry Hines Blvd. Dallas, TX\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:45:50.514454-08\' WHERE joinkey = \'wcwm96ab16\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wcwm96ab16\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:45:50.52854-08\' WHERE joinkey = \'wcwm98ab116\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wcwm98ab116\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:47:45.171739-08\' WHERE joinkey = \'wcwm98ab122\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wcwm98ab122\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:47:45.19488-08\' WHERE joinkey = \'wcwm98ab193\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wcwm98ab193\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:47:45.209921-08\' WHERE joinkey = \'wcwm98ab40\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wcwm98ab40\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:47:45.233673-08\' WHERE joinkey = \'wcwm98ab84\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wcwm98ab84\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:47:45.253455-08\' WHERE joinkey = \'wm2001p107\' AND pap_author = \'Avery L\" Affiliation_address \"Department of Molecular Biology, University of Texas Southwestern Medical Center, 6000 Harry Hines Blvd, Dallas, TX 75390-9148, USA\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wm2001p107\' AND pap_author = \'Avery L\" Affiliation_address \"Department of Molecular Biology, University of Texas Southwestern Medical Center, 6000 Harry Hines Blvd, Dallas, TX 75390-9148, USA\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:47:45.268631-08\' WHERE joinkey = \'wm2001p13\' AND pap_author = \'Avery L\" Affiliation_address \"University of Texas Southwestern Medical Center, Dallas, TX 75390-9148 USA\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wm2001p13\' AND pap_author = \'Avery L\" Affiliation_address \"University of Texas Southwestern Medical Center, Dallas, TX 75390-9148 USA\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:47:45.299616-08\' WHERE joinkey = \'wm2001p26\' AND pap_author = \'Avery L\" Affiliation_address \"Department of Molecular Biology, UT Southwestern Medical Center, Dallas, TX 75390\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wm2001p26\' AND pap_author = \'Avery L\" Affiliation_address \"Department of Molecular Biology, UT Southwestern Medical Center, Dallas, TX 75390\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:47:45.322818-08\' WHERE joinkey = \'wm2001p377\' AND pap_author = \'Avery L\" Affiliation_address \"Department of Molecular Biology, UT Southwestern Medical Center, 6000 Harry Hines Blvd, Dallas, TX 75390\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wm2001p377\' AND pap_author = \'Avery L\" Affiliation_address \"Department of Molecular Biology, UT Southwestern Medical Center, 6000 Harry Hines Blvd, Dallas, TX 75390\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:47:45.341718-08\' WHERE joinkey = \'wm2001p389\' AND pap_author = \'Avery L\" Affiliation_address \"Department of Molecular Biology, University of Texas Southwestern Medical Center, 6000 Harry Hines Blvd., Dallas, TX 75390\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wm2001p389\' AND pap_author = \'Avery L\" Affiliation_address \"Department of Molecular Biology, University of Texas Southwestern Medical Center, 6000 Harry Hines Blvd., Dallas, TX 75390\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:47:45.368055-08\' WHERE joinkey = \'wm2001p692\' AND pap_author = \'Avery L\" Affiliation_address \"Department of Molecular Biology, UT Southwestern Medical Center, Dallas Texas 75390-9148\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wm2001p692\' AND pap_author = \'Avery L\" Affiliation_address \"Department of Molecular Biology, UT Southwestern Medical Center, Dallas Texas 75390-9148\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:49:30.588697-08\' WHERE joinkey = \'wm2001p791\' AND pap_author = \'Avery L\" Affiliation_address \"6000 Harry Hines Blvd, Dallas, Tx 75390-9148\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wm2001p791\' AND pap_author = \'Avery L\" Affiliation_address \"6000 Harry Hines Blvd, Dallas, Tx 75390-9148\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:49:30.61479-08\' WHERE joinkey = \'wm2001p94\' AND pap_author = \'Avery L\" Affiliation_address \"University of Texas Southwestern Medical Center, 6000 Harry Hines Blvd, Dallas, TX 75390-9148\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wm2001p94\' AND pap_author = \'Avery L\" Affiliation_address \"University of Texas Southwestern Medical Center, 6000 Harry Hines Blvd, Dallas, TX 75390-9148\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:49:30.640497-08\' WHERE joinkey = \'wm85p24\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wm85p24\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:49:30.654474-08\' WHERE joinkey = \'wm87p177\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wm87p177\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:49:30.668954-08\' WHERE joinkey = \'wm87p82\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wm87p82\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:49:30.681855-08\' WHERE joinkey = \'wm91p3\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wm91p3\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:49:30.695973-08\' WHERE joinkey = \'wm93p103\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wm93p103\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:49:30.721125-08\' WHERE joinkey = \'wm93p175\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wm93p175\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:49:30.734501-08\' WHERE joinkey = \'wm93p268\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wm93p268\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:49:30.749637-08\' WHERE joinkey = \'wm93p40\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wm93p40\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:51:29.342123-08\' WHERE joinkey = \'wm95p106\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wm95p106\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:51:29.378909-08\' WHERE joinkey = \'wm95p132\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wm95p132\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:51:29.396222-08\' WHERE joinkey = \'wm95p179\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wm95p179\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:51:29.416091-08\' WHERE joinkey = \'wm95p337\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wm95p337\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:51:29.430403-08\' WHERE joinkey = \'wm95p429\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wm95p429\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:51:29.451608-08\' WHERE joinkey = \'wm95p487\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wm95p487\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:51:29.46712-08\' WHERE joinkey = \'wm95p69\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wm95p69\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:51:29.482262-08\' WHERE joinkey = \'wm95p72\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wm95p72\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:51:29.49332-08\' WHERE joinkey = \'wm97ab117\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wm97ab117\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:51:29.509665-08\' WHERE joinkey = \'wm97ab126\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wm97ab126\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:53:39.499885-08\' WHERE joinkey = \'wm97ab29\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wm97ab29\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:53:39.531978-08\' WHERE joinkey = \'wm97ab319\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wm97ab319\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:53:39.54605-08\' WHERE joinkey = \'wm97ab688\' AND pap_author = \'Avery L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wm97ab688\' AND pap_author = \'Avery L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:53:39.570244-08\' WHERE joinkey = \'wm99ab466\' AND pap_author = \'Avery L\" Affiliation_address \"Dept. of Molecular Biology and Oncology, UT Southwestern Med. Center, 6000 Harry Hines Blvd, Dallas, TX, 75235-9148\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wm99ab466\' AND pap_author = \'Avery L\" Affiliation_address \"Dept. of Molecular Biology and Oncology, UT Southwestern Med. Center, 6000 Harry Hines Blvd, Dallas, TX, 75235-9148\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:53:39.597004-08\' WHERE joinkey = \'wm99ab628\' AND pap_author = \'Avery L\" Affiliation_address \"University of Texas Southwestern Medical Center\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wm99ab628\' AND pap_author = \'Avery L\" Affiliation_address \"University of Texas Southwestern Medical Center\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:53:39.616053-08\' WHERE joinkey = \'wm99ab63\' AND pap_author = \'Avery L\" Affiliation_address \"University of Texas Southwestern Medical School, Dallas, TX 75235.\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wm99ab63\' AND pap_author = \'Avery L\" Affiliation_address \"University of Texas Southwestern Medical School, Dallas, TX 75235.\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:53:39.644749-08\' WHERE joinkey = \'wm99ab73\' AND pap_author = \'Avery L\" Affiliation_address \"Department of Molecular Biology and Oncology, University of Texas Southwestern Med. Center, Dallas TX 75235-9148.\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wm99ab73\' AND pap_author = \'Avery L\" Affiliation_address \"Department of Molecular Biology and Oncology, University of Texas Southwestern Med. Center, Dallas TX 75235-9148.\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:53:39.675214-08\' WHERE joinkey = \'wm99ab74\' AND pap_author = \'Avery L\" Affiliation_address \"UT Southwestern Medical Center 5323 Harry Hines Blvd. Dallas Texas 75235\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wm99ab74\' AND pap_author = \'Avery L\" Affiliation_address \"UT Southwestern Medical Center 5323 Harry Hines Blvd. Dallas Texas 75235\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:53:39.698745-08\' WHERE joinkey = \'wm99ab76\' AND pap_author = \'Avery L\" Affiliation_address \"Department of Molecular Biology and Oncology, UT Southwestern Medical Center, Dallas, TX 75235-9148.\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wm99ab76\' AND pap_author = \'Avery L\" Affiliation_address \"Department of Molecular Biology and Oncology, UT Southwestern Medical Center, Dallas, TX 75235-9148.\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:53:39.722938-08\' WHERE joinkey = \'wm99ab805\' AND pap_author = \'Avery L\" Affiliation_address \"Univ. of Texas Southwestern Medical Center, 5323 Harry Hines Blvd Dallas, TX 75235-9148\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two32\' WHERE joinkey = \'wm99ab805\' AND pap_author = \'Avery L\" Affiliation_address \"Univ. of Texas Southwestern Medical Center, 5323 Harry Hines Blvd Dallas, TX 75235-9148\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:58:39.305473-08\' WHERE joinkey = \'cgc3766\' AND pap_author = \'Azevedo RBR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two33\' WHERE joinkey = \'cgc3766\' AND pap_author = \'Azevedo RBR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:58:39.33841-08\' WHERE joinkey = \'cgc4292\' AND pap_author = \'Azevedo RBR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two33\' WHERE joinkey = \'cgc4292\' AND pap_author = \'Azevedo RBR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:58:39.351687-08\' WHERE joinkey = \'cgc4934\' AND pap_author = \'Azevedo RBR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two33\' WHERE joinkey = \'cgc4934\' AND pap_author = \'Azevedo RBR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:58:39.368423-08\' WHERE joinkey = \'cgc5174\' AND pap_author = \'Azevedo RBR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two33\' WHERE joinkey = \'cgc5174\' AND pap_author = \'Azevedo RBR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 13:58:39.3846-08\' WHERE joinkey = \'euwm98ab56\' AND pap_author = \'Azevedo RBR\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two33\' WHERE joinkey = \'euwm98ab56\' AND pap_author = \'Azevedo RBR\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 14:01:55.50715-08\' WHERE joinkey = \'cgc16\' AND pap_author = \'Babu P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two34\' WHERE joinkey = \'cgc16\' AND pap_author = \'Babu P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 14:01:55.528756-08\' WHERE joinkey = \'cgc470\' AND pap_author = \'Babu P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two34\' WHERE joinkey = \'cgc470\' AND pap_author = \'Babu P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 14:01:55.549657-08\' WHERE joinkey = \'cgc493\' AND pap_author = \'Babu P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two34\' WHERE joinkey = \'cgc493\' AND pap_author = \'Babu P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 14:01:55.565848-08\' WHERE joinkey = \'cgc518\' AND pap_author = \'Babu P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two34\' WHERE joinkey = \'cgc518\' AND pap_author = \'Babu P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 14:01:55.577166-08\' WHERE joinkey = \'cgc533\' AND pap_author = \'Babu P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two34\' WHERE joinkey = \'cgc533\' AND pap_author = \'Babu P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 14:01:55.591965-08\' WHERE joinkey = \'wbg1.2p10\' AND pap_author = \'Babu P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two34\' WHERE joinkey = \'wbg1.2p10\' AND pap_author = \'Babu P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 14:01:55.612995-08\' WHERE joinkey = \'wbg1.2p19\' AND pap_author = \'Babu P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two34\' WHERE joinkey = \'wbg1.2p19\' AND pap_author = \'Babu P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 14:01:55.624518-08\' WHERE joinkey = \'wbg1.2p19a\' AND pap_author = \'Babu P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two34\' WHERE joinkey = \'wbg1.2p19a\' AND pap_author = \'Babu P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 14:01:55.635343-08\' WHERE joinkey = \'wbg1.2p19b\' AND pap_author = \'Babu P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two34\' WHERE joinkey = \'wbg1.2p19b\' AND pap_author = \'Babu P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 14:01:55.647732-08\' WHERE joinkey = \'wbg4.1p29\' AND pap_author = \'Babu P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two34\' WHERE joinkey = \'wbg4.1p29\' AND pap_author = \'Babu P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 14:02:45.37638-08\' WHERE joinkey = \'wm79p49\' AND pap_author = \'Babu P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two34\' WHERE joinkey = \'wm79p49\' AND pap_author = \'Babu P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 14:02:45.40437-08\' WHERE joinkey = \'wm79p50\' AND pap_author = \'Babu P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two34\' WHERE joinkey = \'wm79p50\' AND pap_author = \'Babu P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 14:54:29.652033-08\' WHERE joinkey = \'cgc1018\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'cgc1018\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 14:54:29.677302-08\' WHERE joinkey = \'cgc1040\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'cgc1040\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 14:54:29.69477-08\' WHERE joinkey = \'cgc1048\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'cgc1048\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 14:54:29.709423-08\' WHERE joinkey = \'cgc1055\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'cgc1055\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 14:54:29.727848-08\' WHERE joinkey = \'cgc1071\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'cgc1071\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 14:54:29.742196-08\' WHERE joinkey = \'cgc1108\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'cgc1108\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 14:54:29.757659-08\' WHERE joinkey = \'cgc1136\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'cgc1136\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 14:54:29.769628-08\' WHERE joinkey = \'cgc1159\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'cgc1159\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 14:54:29.789269-08\' WHERE joinkey = \'cgc1177\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'cgc1177\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 14:54:29.803793-08\' WHERE joinkey = \'cgc1252\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'cgc1252\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 14:56:42.050856-08\' WHERE joinkey = \'cgc1268\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'cgc1268\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 14:56:42.085239-08\' WHERE joinkey = \'cgc1303\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'cgc1303\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 14:56:42.102456-08\' WHERE joinkey = \'cgc1312\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'cgc1312\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 14:56:42.114738-08\' WHERE joinkey = \'cgc1320\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'cgc1320\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 14:56:42.128431-08\' WHERE joinkey = \'cgc1402\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'cgc1402\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 14:56:42.14462-08\' WHERE joinkey = \'cgc1425\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'cgc1425\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 14:56:42.166931-08\' WHERE joinkey = \'cgc1474\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'cgc1474\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 14:56:42.180453-08\' WHERE joinkey = \'cgc1522\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'cgc1522\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 14:56:42.194896-08\' WHERE joinkey = \'cgc1689\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'cgc1689\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 14:56:42.208962-08\' WHERE joinkey = \'cgc1805\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'cgc1805\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 14:59:20.207939-08\' WHERE joinkey = \'cgc1853\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'cgc1853\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 14:59:20.230784-08\' WHERE joinkey = \'cgc1891\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'cgc1891\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 14:59:20.249094-08\' WHERE joinkey = \'cgc1892\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'cgc1892\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 14:59:20.26745-08\' WHERE joinkey = \'cgc1912\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'cgc1912\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 14:59:20.285961-08\' WHERE joinkey = \'cgc2024\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'cgc2024\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 14:59:20.299103-08\' WHERE joinkey = \'cgc2054\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'cgc2054\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 14:59:20.315482-08\' WHERE joinkey = \'cgc2182\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'cgc2182\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 14:59:20.34297-08\' WHERE joinkey = \'cgc2250\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'cgc2250\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 14:59:20.357363-08\' WHERE joinkey = \'cgc2328\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'cgc2328\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 14:59:20.372151-08\' WHERE joinkey = \'cgc245\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'cgc245\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:01:34.026622-08\' WHERE joinkey = \'cgc2501\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'cgc2501\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:01:34.053013-08\' WHERE joinkey = \'cgc2668\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'cgc2668\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:01:34.067659-08\' WHERE joinkey = \'cgc2901\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'cgc2901\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:01:34.166179-08\' WHERE joinkey = \'cgc2924\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'cgc2924\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:01:34.185452-08\' WHERE joinkey = \'cgc3021\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'cgc3021\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:01:34.206741-08\' WHERE joinkey = \'cgc320\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'cgc320\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:01:34.219433-08\' WHERE joinkey = \'cgc321\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'cgc321\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:01:34.244902-08\' WHERE joinkey = \'cgc3507\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'cgc3507\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:01:34.26269-08\' WHERE joinkey = \'cgc3513\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'cgc3513\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:03:48.342545-08\' WHERE joinkey = \'cgc3745\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'cgc3745\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:03:48.369016-08\' WHERE joinkey = \'cgc3796\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'cgc3796\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:03:48.404517-08\' WHERE joinkey = \'cgc4214\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'cgc4214\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:03:48.424548-08\' WHERE joinkey = \'cgc427\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'cgc427\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:03:48.447263-08\' WHERE joinkey = \'cgc4287\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'cgc4287\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:03:48.464341-08\' WHERE joinkey = \'cgc4772\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'cgc4772\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:03:48.489851-08\' WHERE joinkey = \'cgc4798\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'cgc4798\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:03:48.522445-08\' WHERE joinkey = \'cgc4805\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'cgc4805\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:03:48.545518-08\' WHERE joinkey = \'cgc499\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'cgc499\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:03:48.559786-08\' WHERE joinkey = \'cgc554\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'cgc554\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:05:32.634511-08\' WHERE joinkey = \'cgc571\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'cgc571\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:05:32.658346-08\' WHERE joinkey = \'cgc575\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'cgc575\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:05:32.681508-08\' WHERE joinkey = \'cgc592\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'cgc592\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:05:32.69912-08\' WHERE joinkey = \'cgc601\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'cgc601\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:05:32.71248-08\' WHERE joinkey = \'cgc619\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'cgc619\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:05:32.728562-08\' WHERE joinkey = \'cgc639\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'cgc639\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:05:32.751458-08\' WHERE joinkey = \'cgc699\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'cgc699\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:05:32.765381-08\' WHERE joinkey = \'cgc700\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'cgc700\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:05:32.775936-08\' WHERE joinkey = \'cgc750\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'cgc750\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:05:32.791927-08\' WHERE joinkey = \'cgc760\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'cgc760\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:08:46.827137-08\' WHERE joinkey = \'cgc784\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'cgc784\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:08:46.854679-08\' WHERE joinkey = \'cgc813\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'cgc813\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:08:46.872055-08\' WHERE joinkey = \'euwm2000ab117\' AND pap_author = \'Baillie DL\" Affiliation_address \"Address unknown\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'euwm2000ab117\' AND pap_author = \'Baillie DL\" Affiliation_address \"Address unknown\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:08:46.897247-08\' WHERE joinkey = \'euwm2000ab16\' AND pap_author = \'Baillie DL\" Affiliation_address \"Institute of Molecular Biology & Biochemistry,   Department of Biological Sciences, Simon Fraser University, Burnaby, British   Columbia, CANADA  V5A 1S6\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'euwm2000ab16\' AND pap_author = \'Baillie DL\" Affiliation_address \"Institute of Molecular Biology & Biochemistry,   Department of Biological Sciences, Simon Fraser University, Burnaby, British   Columbia, CANADA  V5A 1S6\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:08:46.918379-08\' WHERE joinkey = \'med94119712\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'med94119712\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:08:46.932538-08\' WHERE joinkey = \'med94150469\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'med94150469\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:08:46.97092-08\' WHERE joinkey = \'med94186038\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'med94186038\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:08:46.993989-08\' WHERE joinkey = \'mwwm98ab3\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'mwwm98ab3\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:08:47.021227-08\' WHERE joinkey = \'wbg1.2p25b\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wbg1.2p25b\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:13:05.655965-08\' WHERE joinkey = \'wbg1.2p6\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wbg1.2p6\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:13:05.675819-08\' WHERE joinkey = \'wbg10.1p46\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wbg10.1p46\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:13:05.691628-08\' WHERE joinkey = \'wbg10.1p56\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wbg10.1p56\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:13:05.708031-08\' WHERE joinkey = \'wbg10.1p79\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wbg10.1p79\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:13:05.731808-08\' WHERE joinkey = \'wbg10.1p81\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wbg10.1p81\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:13:05.836873-08\' WHERE joinkey = \'wbg10.1p98\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wbg10.1p98\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:13:05.862888-08\' WHERE joinkey = \'wbg10.2p102\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wbg10.2p102\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:13:05.876696-08\' WHERE joinkey = \'wbg10.2p137\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wbg10.2p137\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:13:05.888426-08\' WHERE joinkey = \'wbg10.2p138\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wbg10.2p138\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:13:05.90204-08\' WHERE joinkey = \'wbg10.2p139\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wbg10.2p139\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:15:04.586508-08\' WHERE joinkey = \'wbg10.2p142\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wbg10.2p142\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:15:04.608107-08\' WHERE joinkey = \'wbg10.3p141\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wbg10.3p141\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:15:04.622446-08\' WHERE joinkey = \'wbg10.3p94\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wbg10.3p94\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:15:04.642567-08\' WHERE joinkey = \'wbg11.1p21\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wbg11.1p21\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:15:04.654415-08\' WHERE joinkey = \'wbg11.1p55\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wbg11.1p55\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:15:04.668084-08\' WHERE joinkey = \'wbg11.1p66\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wbg11.1p66\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:15:04.682376-08\' WHERE joinkey = \'wbg11.2p38\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wbg11.2p38\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:15:04.696649-08\' WHERE joinkey = \'wbg11.2p60\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wbg11.2p60\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:15:04.717567-08\' WHERE joinkey = \'wbg11.2p80\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wbg11.2p80\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:15:04.72923-08\' WHERE joinkey = \'wbg11.2p86\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wbg11.2p86\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:36:20.014027-08\' WHERE joinkey = \'wbg11.4p17\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wbg11.4p17\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:36:20.085152-08\' WHERE joinkey = \'wbg11.4p25\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wbg11.4p25\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:36:20.130638-08\' WHERE joinkey = \'wbg11.4p72\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wbg11.4p72\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:36:20.146465-08\' WHERE joinkey = \'wbg11.4p85\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wbg11.4p85\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:36:20.162223-08\' WHERE joinkey = \'wbg12.1p18\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wbg12.1p18\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:36:20.190236-08\' WHERE joinkey = \'wbg12.1p22\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wbg12.1p22\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:36:20.209174-08\' WHERE joinkey = \'wbg12.1p46\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wbg12.1p46\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:36:20.349442-08\' WHERE joinkey = \'wbg12.3p106\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wbg12.3p106\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:36:20.448678-08\' WHERE joinkey = \'wbg12.3p44\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wbg12.3p44\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:37:59.565901-08\' WHERE joinkey = \'wbg12.3p45\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wbg12.3p45\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:37:59.618142-08\' WHERE joinkey = \'wbg12.3p46\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wbg12.3p46\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:37:59.63304-08\' WHERE joinkey = \'wbg12.3p49\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wbg12.3p49\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:37:59.662496-08\' WHERE joinkey = \'wbg12.3p94\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wbg12.3p94\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:37:59.692941-08\' WHERE joinkey = \'wbg12.5p17\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wbg12.5p17\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:37:59.715785-08\' WHERE joinkey = \'wbg12.5p88\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wbg12.5p88\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:37:59.733594-08\' WHERE joinkey = \'wbg13.1p50\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wbg13.1p50\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:37:59.754437-08\' WHERE joinkey = \'wbg13.2p66\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wbg13.2p66\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:37:59.779265-08\' WHERE joinkey = \'wbg13.4p94\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wbg13.4p94\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:37:59.797292-08\' WHERE joinkey = \'wbg13.4p95\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wbg13.4p95\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:42:04.77196-08\' WHERE joinkey = \'wbg13.5p70\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wbg13.5p70\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:42:04.795367-08\' WHERE joinkey = \'wbg13.5p71\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wbg13.5p71\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:42:04.815504-08\' WHERE joinkey = \'wbg13.5p78\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wbg13.5p78\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:42:04.828764-08\' WHERE joinkey = \'wbg14.2p23\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wbg14.2p23\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:42:04.848903-08\' WHERE joinkey = \'wbg14.2p60\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wbg14.2p60\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:42:04.877155-08\' WHERE joinkey = \'wbg14.3p14\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wbg14.3p14\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:42:04.892747-08\' WHERE joinkey = \'wbg14.4p55\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wbg14.4p55\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:42:04.914848-08\' WHERE joinkey = \'wbg14.5p24\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wbg14.5p24\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:42:04.944132-08\' WHERE joinkey = \'wbg14.5p25\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wbg14.5p25\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:44:01.143976-08\' WHERE joinkey = \'wbg15.2p51\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wbg15.2p51\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:44:01.177095-08\' WHERE joinkey = \'wbg15.3p24\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wbg15.3p24\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:44:01.192466-08\' WHERE joinkey = \'wbg15.3p34\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wbg15.3p34\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:44:01.209087-08\' WHERE joinkey = \'wbg16.3p14\' AND pap_author = \'Baillie DL\" Affiliation_address \"Simon Fraser University\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wbg16.3p14\' AND pap_author = \'Baillie DL\" Affiliation_address \"Simon Fraser University\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:44:01.249754-08\' WHERE joinkey = \'wbg2.1p6\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wbg2.1p6\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:44:01.264259-08\' WHERE joinkey = \'wbg2.2p20\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wbg2.2p20\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:44:01.277724-08\' WHERE joinkey = \'wbg2.2p20b\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wbg2.2p20b\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:44:01.28767-08\' WHERE joinkey = \'wbg2.2p21\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wbg2.2p21\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:44:01.322588-08\' WHERE joinkey = \'wbg2.2p22\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wbg2.2p22\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:46:04.455295-08\' WHERE joinkey = \'wbg2.2p22a\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wbg2.2p22a\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:46:04.486464-08\' WHERE joinkey = \'wbg2.2p22b\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wbg2.2p22b\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:46:04.497701-08\' WHERE joinkey = \'wbg5.1p11\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wbg5.1p11\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:46:04.50989-08\' WHERE joinkey = \'wbg5.2p29\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wbg5.2p29\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:46:04.525655-08\' WHERE joinkey = \'wbg6.1p35\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wbg6.1p35\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:46:04.539961-08\' WHERE joinkey = \'wbg7.1p89\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wbg7.1p89\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:46:04.559268-08\' WHERE joinkey = \'wbg7.1p91\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wbg7.1p91\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:46:04.571864-08\' WHERE joinkey = \'wbg7.2p12\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wbg7.2p12\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:46:04.589432-08\' WHERE joinkey = \'wbg8.1p34\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wbg8.1p34\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:46:04.603495-08\' WHERE joinkey = \'wbg8.2p3\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wbg8.2p3\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:48:07.767714-08\' WHERE joinkey = \'wbg8.3p66\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wbg8.3p66\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:48:07.790588-08\' WHERE joinkey = \'wbg8.3p7\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wbg8.3p7\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:48:07.818687-08\' WHERE joinkey = \'wbg8.3p84\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wbg8.3p84\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:48:07.841075-08\' WHERE joinkey = \'wbg8.3p91\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wbg8.3p91\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:48:07.86824-08\' WHERE joinkey = \'wbg9.1p15\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wbg9.1p15\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:48:07.888133-08\' WHERE joinkey = \'wbg9.1p16\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wbg9.1p16\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:48:07.903146-08\' WHERE joinkey = \'wbg9.1p40\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wbg9.1p40\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:48:07.930283-08\' WHERE joinkey = \'wbg9.2p114\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wbg9.2p114\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:48:07.943554-08\' WHERE joinkey = \'wbg9.2p80\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wbg9.2p80\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:48:07.955074-08\' WHERE joinkey = \'wbg9.2p81\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wbg9.2p81\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:49:53.955488-08\' WHERE joinkey = \'wbg9.2p82\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wbg9.2p82\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:49:53.97611-08\' WHERE joinkey = \'wbg9.2p83\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wbg9.2p83\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:49:53.991578-08\' WHERE joinkey = \'wbg9.2p84\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wbg9.2p84\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:49:54.012154-08\' WHERE joinkey = \'wbg9.3p31\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wbg9.3p31\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:49:54.026882-08\' WHERE joinkey = \'wbg9.3p35\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wbg9.3p35\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:49:54.045871-08\' WHERE joinkey = \'wbg9.3p36\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wbg9.3p36\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:49:54.058864-08\' WHERE joinkey = \'wbg9.3p37\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wbg9.3p37\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:49:54.086-08\' WHERE joinkey = \'wbg9.3p38\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wbg9.3p38\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:49:54.097534-08\' WHERE joinkey = \'wbg9.3p72\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wbg9.3p72\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:49:54.115694-08\' WHERE joinkey = \'wcwm2000ab150\' AND pap_author = \'Baillie DL\" Affiliation_address \"IMBB, Simon Fraser University, Burnaby, B.C, V5A 1S6, Canada\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wcwm2000ab150\' AND pap_author = \'Baillie DL\" Affiliation_address \"IMBB, Simon Fraser University, Burnaby, B.C, V5A 1S6, Canada\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:52:57.498451-08\' WHERE joinkey = \'wcwm2000ab161\' AND pap_author = \'Baillie DL\" Affiliation_address \"Simon Fraser University\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wcwm2000ab161\' AND pap_author = \'Baillie DL\" Affiliation_address \"Simon Fraser University\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:52:57.545809-08\' WHERE joinkey = \'wcwm2000ab224\' AND pap_author = \'Baillie DL\" Affiliation_address \"Simon Fraser University, Burnaby, B.C. CANADA V5A 1S6\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wcwm2000ab224\' AND pap_author = \'Baillie DL\" Affiliation_address \"Simon Fraser University, Burnaby, B.C. CANADA V5A 1S6\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:52:57.561685-08\' WHERE joinkey = \'wcwm96ab10\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wcwm96ab10\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:52:57.577818-08\' WHERE joinkey = \'wcwm96ab116\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wcwm96ab116\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:52:57.593027-08\' WHERE joinkey = \'wcwm96ab135\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wcwm96ab135\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:52:57.625031-08\' WHERE joinkey = \'wcwm96ab148\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wcwm96ab148\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:52:57.642721-08\' WHERE joinkey = \'wcwm96ab149\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wcwm96ab149\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:52:57.664531-08\' WHERE joinkey = \'wcwm96ab164\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wcwm96ab164\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:52:57.678911-08\' WHERE joinkey = \'wcwm96ab19\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wcwm96ab19\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:52:57.774753-08\' WHERE joinkey = \'wcwm96ab4\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wcwm96ab4\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:55:03.47929-08\' WHERE joinkey = \'wcwm96ab48\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wcwm96ab48\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:55:03.507871-08\' WHERE joinkey = \'wcwm96ab71\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wcwm96ab71\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:55:03.540847-08\' WHERE joinkey = \'wcwm98ab125\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wcwm98ab125\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:55:03.569187-08\' WHERE joinkey = \'wcwm98ab175\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wcwm98ab175\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:55:03.591997-08\' WHERE joinkey = \'wcwm98ab95\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wcwm98ab95\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:55:03.606495-08\' WHERE joinkey = \'wm2001p1000\' AND pap_author = \'Baillie DL\" Affiliation_address \"Department of Molecular Biology and Biochemistry, Simon Fraser University, Burnaby, B.C. V5A 1S6 CANADA\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wm2001p1000\' AND pap_author = \'Baillie DL\" Affiliation_address \"Department of Molecular Biology and Biochemistry, Simon Fraser University, Burnaby, B.C. V5A 1S6 CANADA\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:55:03.622467-08\' WHERE joinkey = \'wm2001p1091\' AND pap_author = \'Baillie DL\" Affiliation_address \"Molecular Biology and Biochemistry, Simon Fraser University, Burnaby BC, Canada, V5A 1S6\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wm2001p1091\' AND pap_author = \'Baillie DL\" Affiliation_address \"Molecular Biology and Biochemistry, Simon Fraser University, Burnaby BC, Canada, V5A 1S6\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:55:03.653775-08\' WHERE joinkey = \'wm2001p240\' AND pap_author = \'Baillie DL\" Affiliation_address \"Institute of Molecular Biology and Biochemistry, Simon Fraser University, Burnaby, B.C., V5A 1S6, Canada\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wm2001p240\' AND pap_author = \'Baillie DL\" Affiliation_address \"Institute of Molecular Biology and Biochemistry, Simon Fraser University, Burnaby, B.C., V5A 1S6, Canada\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:55:03.696214-08\' WHERE joinkey = \'wm2001p470\' AND pap_author = \'Baillie DL\" Affiliation_address \"Department of Molecular Biology and Biochemistry, Simon Fraser University, Burnaby, B.C. V5A 1S6\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wm2001p470\' AND pap_author = \'Baillie DL\" Affiliation_address \"Department of Molecular Biology and Biochemistry, Simon Fraser University, Burnaby, B.C. V5A 1S6\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:56:57.998865-08\' WHERE joinkey = \'wm2001p746\' AND pap_author = \'Baillie DL\" Affiliation_address \"Department of Molecular Biology and Biochemistry, Simon Fraser University, Burnaby, B. C. V5A 1S6, Canada\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wm2001p746\' AND pap_author = \'Baillie DL\" Affiliation_address \"Department of Molecular Biology and Biochemistry, Simon Fraser University, Burnaby, B. C. V5A 1S6, Canada\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:56:58.029888-08\' WHERE joinkey = \'wm2001p769\' AND pap_author = \'Baillie DL\" Affiliation_address \"Dep of Molecular Biology and Biochemistry, Simon Fraser University, Burnaby, B.C, V5A 1S6, Canada\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wm2001p769\' AND pap_author = \'Baillie DL\" Affiliation_address \"Dep of Molecular Biology and Biochemistry, Simon Fraser University, Burnaby, B.C, V5A 1S6, Canada\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:56:58.049519-08\' WHERE joinkey = \'wm2001p943\' AND pap_author = \'Baillie DL\" Affiliation_address \"Department of Molecular Biology and Biochemistry, Simon Fraser University, Burnaby, B.C., Canada, V5A 1S6\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wm2001p943\' AND pap_author = \'Baillie DL\" Affiliation_address \"Department of Molecular Biology and Biochemistry, Simon Fraser University, Burnaby, B.C., Canada, V5A 1S6\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:56:58.076086-08\' WHERE joinkey = \'wm77p20\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wm77p20\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:56:58.089796-08\' WHERE joinkey = \'wm77p21\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wm77p21\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:56:58.103987-08\' WHERE joinkey = \'wm77p22\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wm77p22\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:56:58.122619-08\' WHERE joinkey = \'wm79p14\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wm79p14\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:56:58.139773-08\' WHERE joinkey = \'wm79p73\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wm79p73\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:56:58.154811-08\' WHERE joinkey = \'wm79p74\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wm79p74\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:56:58.170317-08\' WHERE joinkey = \'wm81p16\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wm81p16\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:58:47.155492-08\' WHERE joinkey = \'wm81p51\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wm81p51\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:58:47.185467-08\' WHERE joinkey = \'wm81p76\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wm81p76\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:58:47.200407-08\' WHERE joinkey = \'wm81p77\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wm81p77\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:58:47.214601-08\' WHERE joinkey = \'wm83p102\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wm83p102\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:58:47.224391-08\' WHERE joinkey = \'wm83p51\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wm83p51\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:58:47.244351-08\' WHERE joinkey = \'wm83p60\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wm83p60\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:58:47.264426-08\' WHERE joinkey = \'wm83p62\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wm83p62\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:58:47.276276-08\' WHERE joinkey = \'wm83p81\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wm83p81\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:58:47.289871-08\' WHERE joinkey = \'wm83p99\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wm83p99\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 15:58:47.303541-08\' WHERE joinkey = \'wm85p118\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wm85p118\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:00:57.346354-08\' WHERE joinkey = \'wm85p124\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wm85p124\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:00:57.372323-08\' WHERE joinkey = \'wm85p135\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wm85p135\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:00:57.388715-08\' WHERE joinkey = \'wm85p3\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wm85p3\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:00:57.407079-08\' WHERE joinkey = \'wm85p38\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wm85p38\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:00:57.422503-08\' WHERE joinkey = \'wm85p72\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wm85p72\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:00:57.444533-08\' WHERE joinkey = \'wm85p77\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wm85p77\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:00:57.481445-08\' WHERE joinkey = \'wm87p106\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wm87p106\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:00:57.49341-08\' WHERE joinkey = \'wm87p112\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wm87p112\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:00:57.505238-08\' WHERE joinkey = \'wm87p146\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wm87p146\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:00:57.518982-08\' WHERE joinkey = \'wm87p159\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wm87p159\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:03:45.414966-08\' WHERE joinkey = \'wm87p22\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wm87p22\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:03:45.447399-08\' WHERE joinkey = \'wm87p30\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wm87p30\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:03:45.460612-08\' WHERE joinkey = \'wm87p38\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wm87p38\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:03:45.494242-08\' WHERE joinkey = \'wm87p57\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wm87p57\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:03:45.506975-08\' WHERE joinkey = \'wm87p98\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wm87p98\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:03:45.527556-08\' WHERE joinkey = \'wm89p121\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wm89p121\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:03:45.545266-08\' WHERE joinkey = \'wm89p134\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wm89p134\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:03:45.594305-08\' WHERE joinkey = \'wm89p166\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wm89p166\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:03:45.619342-08\' WHERE joinkey = \'wm89p198\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wm89p198\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:03:45.653915-08\' WHERE joinkey = \'wm89p214\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wm89p214\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:05:39.004845-08\' WHERE joinkey = \'wm89p220\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wm89p220\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:05:39.026636-08\' WHERE joinkey = \'wm89p257\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wm89p257\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:05:39.042444-08\' WHERE joinkey = \'wm89p57\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wm89p57\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:05:39.056261-08\' WHERE joinkey = \'wm91p171\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wm91p171\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:05:39.077148-08\' WHERE joinkey = \'wm91p207\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wm91p207\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:05:39.093975-08\' WHERE joinkey = \'wm91p208\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wm91p208\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:05:39.108196-08\' WHERE joinkey = \'wm91p333\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wm91p333\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:05:39.131935-08\' WHERE joinkey = \'wm91p35\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wm91p35\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:05:39.145475-08\' WHERE joinkey = \'wm91p46\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wm91p46\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:05:39.163642-08\' WHERE joinkey = \'wm93p115\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wm93p115\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:07:27.238082-08\' WHERE joinkey = \'wm93p116\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wm93p116\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:07:27.269942-08\' WHERE joinkey = \'wm93p223\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wm93p223\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:07:27.295487-08\' WHERE joinkey = \'wm93p228\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wm93p228\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:07:27.307933-08\' WHERE joinkey = \'wm93p302\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wm93p302\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:07:27.324016-08\' WHERE joinkey = \'wm93p397\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wm93p397\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:07:27.339207-08\' WHERE joinkey = \'wm93p427\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wm93p427\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:07:27.366392-08\' WHERE joinkey = \'wm93p428\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wm93p428\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:07:27.378097-08\' WHERE joinkey = \'wm93p434\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wm93p434\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:07:27.392392-08\' WHERE joinkey = \'wm93p63\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wm93p63\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:07:27.4073-08\' WHERE joinkey = \'wm95p113\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wm95p113\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:09:26.65634-08\' WHERE joinkey = \'wm95p134\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wm95p134\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:09:26.708201-08\' WHERE joinkey = \'wm95p149\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wm95p149\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:09:26.742771-08\' WHERE joinkey = \'wm95p161\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wm95p161\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:09:26.768962-08\' WHERE joinkey = \'wm95p199\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wm95p199\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:09:26.787271-08\' WHERE joinkey = \'wm95p233\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wm95p233\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:09:26.800835-08\' WHERE joinkey = \'wm95p458\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wm95p458\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:09:26.814571-08\' WHERE joinkey = \'wm95p491\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wm95p491\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:09:26.839693-08\' WHERE joinkey = \'wm97ab272\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wm97ab272\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:09:26.866331-08\' WHERE joinkey = \'wm97ab456\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wm97ab456\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:09:26.882532-08\' WHERE joinkey = \'wm97ab513\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wm97ab513\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:12:04.872289-08\' WHERE joinkey = \'wm97ab528\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wm97ab528\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:12:04.912664-08\' WHERE joinkey = \'wm97ab571\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wm97ab571\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:12:04.962695-08\' WHERE joinkey = \'wm97ab616\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wm97ab616\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:12:04.981096-08\' WHERE joinkey = \'wm97ab617\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wm97ab617\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:12:04.998329-08\' WHERE joinkey = \'wm97ab72\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wm97ab72\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:12:05.013976-08\' WHERE joinkey = \'wm97ab83\' AND pap_author = \'Baillie DL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wm97ab83\' AND pap_author = \'Baillie DL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:12:05.041352-08\' WHERE joinkey = \'wm99ab386\' AND pap_author = \'Baillie DL\" Affiliation_address \"IMBB, Simon Fraser University, Burnaby, B.C, V5A 1S6, Canada\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wm99ab386\' AND pap_author = \'Baillie DL\" Affiliation_address \"IMBB, Simon Fraser University, Burnaby, B.C, V5A 1S6, Canada\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:12:05.062402-08\' WHERE joinkey = \'wm99ab502\' AND pap_author = \'Baillie DL\" Affiliation_address \"Simon Fraser University Burnaby, B.C. Canada\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wm99ab502\' AND pap_author = \'Baillie DL\" Affiliation_address \"Simon Fraser University Burnaby, B.C. Canada\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:12:05.111595-08\' WHERE joinkey = \'wm99ab525\' AND pap_author = \'Baillie DL\" Affiliation_address \"Dept of Biological Sciences, Simon Fraser University, Burnaby, British Columbia, Canada.\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wm99ab525\' AND pap_author = \'Baillie DL\" Affiliation_address \"Dept of Biological Sciences, Simon Fraser University, Burnaby, British Columbia, Canada.\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:14:08.161709-08\' WHERE joinkey = \'wm99ab636\' AND pap_author = \'Baillie DL\" Affiliation_address \"Institute of Molecular Biology and Biochemistry, Simon Fraser University, Burnaby, B.C., Canada, V5A 1S6.\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wm99ab636\' AND pap_author = \'Baillie DL\" Affiliation_address \"Institute of Molecular Biology and Biochemistry, Simon Fraser University, Burnaby, B.C., Canada, V5A 1S6.\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:14:08.217883-08\' WHERE joinkey = \'wm99ab640\' AND pap_author = \'Baillie DL\" Affiliation_address \"Institute of Molecular Biology and Biochemistry, Simon Fraser University, Burnaby, BC, V5A 1S6, Canada\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wm99ab640\' AND pap_author = \'Baillie DL\" Affiliation_address \"Institute of Molecular Biology and Biochemistry, Simon Fraser University, Burnaby, BC, V5A 1S6, Canada\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:14:08.267489-08\' WHERE joinkey = \'wm99ab760\' AND pap_author = \'Baillie DL\" Affiliation_address \"Simon Fraser University, Burnaby, B.C., Canada.\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wm99ab760\' AND pap_author = \'Baillie DL\" Affiliation_address \"Simon Fraser University, Burnaby, B.C., Canada.\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:14:08.286608-08\' WHERE joinkey = \'wm99ab770\' AND pap_author = \'Baillie DL\" Affiliation_address \"Insitiute of Molecular Biology and Biochemistry, Simon Fraser University, Burnaby, BC, Canada.\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wm99ab770\' AND pap_author = \'Baillie DL\" Affiliation_address \"Insitiute of Molecular Biology and Biochemistry, Simon Fraser University, Burnaby, BC, Canada.\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:14:08.306912-08\' WHERE joinkey = \'wm99ab835\' AND pap_author = \'Baillie DL\" Affiliation_address \"Simon Fraser University.\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wm99ab835\' AND pap_author = \'Baillie DL\" Affiliation_address \"Simon Fraser University.\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:14:08.336481-08\' WHERE joinkey = \'wm99ab868\' AND pap_author = \'Baillie DL\" Affiliation_address \"Institute of Molecular Biology and Biochemistry, Simon Fraser University, Vancouver, B.C. V5Z 1S6, Canada\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two36\' WHERE joinkey = \'wm99ab868\' AND pap_author = \'Baillie DL\" Affiliation_address \"Institute of Molecular Biology and Biochemistry, Simon Fraser University, Vancouver, B.C. V5Z 1S6, Canada\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:25:14.335726-08\' WHERE joinkey = \'cgc1328\' AND pap_author = \'Baird SE\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two37\' WHERE joinkey = \'cgc1328\' AND pap_author = \'Baird SE\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:25:14.359571-08\' WHERE joinkey = \'cgc1471\' AND pap_author = \'Baird SE\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two37\' WHERE joinkey = \'cgc1471\' AND pap_author = \'Baird SE\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:25:14.375109-08\' WHERE joinkey = \'cgc1580\' AND pap_author = \'Baird SE\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two37\' WHERE joinkey = \'cgc1580\' AND pap_author = \'Baird SE\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:25:14.389864-08\' WHERE joinkey = \'cgc1874\' AND pap_author = \'Baird SE\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two37\' WHERE joinkey = \'cgc1874\' AND pap_author = \'Baird SE\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:25:14.411749-08\' WHERE joinkey = \'cgc2374\' AND pap_author = \'Baird SE\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two37\' WHERE joinkey = \'cgc2374\' AND pap_author = \'Baird SE\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:25:14.436336-08\' WHERE joinkey = \'cgc3626\' AND pap_author = \'Baird SE\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two37\' WHERE joinkey = \'cgc3626\' AND pap_author = \'Baird SE\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:25:14.448561-08\' WHERE joinkey = \'cgc3847\' AND pap_author = \'Baird SE\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two37\' WHERE joinkey = \'cgc3847\' AND pap_author = \'Baird SE\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:25:14.470916-08\' WHERE joinkey = \'cgc3916\' AND pap_author = \'Baird SE\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two37\' WHERE joinkey = \'cgc3916\' AND pap_author = \'Baird SE\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:25:14.493409-08\' WHERE joinkey = \'cgc4930\' AND pap_author = \'Baird SE\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two37\' WHERE joinkey = \'cgc4930\' AND pap_author = \'Baird SE\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:26:55.636402-08\' WHERE joinkey = \'cgc5396\' AND pap_author = \'Baird SE\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two37\' WHERE joinkey = \'cgc5396\' AND pap_author = \'Baird SE\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:26:55.815045-08\' WHERE joinkey = \'ecwm2000ab28\' AND pap_author = \'Baird SE\" Affiliation_address \"Department of Biological Sciences, Wright State University, Dayton OH 45435.\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two37\' WHERE joinkey = \'ecwm2000ab28\' AND pap_author = \'Baird SE\" Affiliation_address \"Department of Biological Sciences, Wright State University, Dayton OH 45435.\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:26:55.827487-08\' WHERE joinkey = \'ecwm96ab102\' AND pap_author = \'Baird SE\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two37\' WHERE joinkey = \'ecwm96ab102\' AND pap_author = \'Baird SE\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:26:55.869556-08\' WHERE joinkey = \'wbg10.3p88\' AND pap_author = \'Baird SE\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two37\' WHERE joinkey = \'wbg10.3p88\' AND pap_author = \'Baird SE\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:26:55.892181-08\' WHERE joinkey = \'wbg10.3p90\' AND pap_author = \'Baird SE\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two37\' WHERE joinkey = \'wbg10.3p90\' AND pap_author = \'Baird SE\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:26:55.903765-08\' WHERE joinkey = \'wbg11.2p116\' AND pap_author = \'Baird SE\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two37\' WHERE joinkey = \'wbg11.2p116\' AND pap_author = \'Baird SE\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:26:55.917854-08\' WHERE joinkey = \'wbg11.4p87\' AND pap_author = \'Baird SE\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two37\' WHERE joinkey = \'wbg11.4p87\' AND pap_author = \'Baird SE\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:26:56.12361-08\' WHERE joinkey = \'wbg11.4p89\' AND pap_author = \'Baird SE\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two37\' WHERE joinkey = \'wbg11.4p89\' AND pap_author = \'Baird SE\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:26:56.167173-08\' WHERE joinkey = \'wbg12.2p14\' AND pap_author = \'Baird SE\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two37\' WHERE joinkey = \'wbg12.2p14\' AND pap_author = \'Baird SE\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:26:56.183973-08\' WHERE joinkey = \'wbg13.2p38\' AND pap_author = \'Baird SE\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two37\' WHERE joinkey = \'wbg13.2p38\' AND pap_author = \'Baird SE\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:31:08.466473-08\' WHERE joinkey = \'wbg13.2p39\' AND pap_author = \'Baird SE\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two37\' WHERE joinkey = \'wbg13.2p39\' AND pap_author = \'Baird SE\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:31:08.488422-08\' WHERE joinkey = \'wbg13.4p63\' AND pap_author = \'Baird SE\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two37\' WHERE joinkey = \'wbg13.4p63\' AND pap_author = \'Baird SE\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:31:08.515418-08\' WHERE joinkey = \'wm2001p585\' AND pap_author = \'Baird SE\" Affiliation_address \"Department of Biological Sciences, Wright State University, Dayton OH 45435, scott.baird@wright.edu\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two37\' WHERE joinkey = \'wm2001p585\' AND pap_author = \'Baird SE\" Affiliation_address \"Department of Biological Sciences, Wright State University, Dayton OH 45435, scott.baird@wright.edu\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:31:08.530958-08\' WHERE joinkey = \'wm2001p80\' AND pap_author = \'Baird SE\" Affiliation_address \"Department of Biological Sciences, Wright State University, Dayton OH 45435\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two37\' WHERE joinkey = \'wm2001p80\' AND pap_author = \'Baird SE\" Affiliation_address \"Department of Biological Sciences, Wright State University, Dayton OH 45435\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:31:08.549617-08\' WHERE joinkey = \'wm89p112\' AND pap_author = \'Baird SE\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two37\' WHERE joinkey = \'wm89p112\' AND pap_author = \'Baird SE\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:31:08.564653-08\' WHERE joinkey = \'wm89p241\' AND pap_author = \'Baird SE\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two37\' WHERE joinkey = \'wm89p241\' AND pap_author = \'Baird SE\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:31:08.582664-08\' WHERE joinkey = \'wm91p364\' AND pap_author = \'Baird SE\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two37\' WHERE joinkey = \'wm91p364\' AND pap_author = \'Baird SE\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:31:08.59721-08\' WHERE joinkey = \'wm91p45\' AND pap_author = \'Baird SE\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two37\' WHERE joinkey = \'wm91p45\' AND pap_author = \'Baird SE\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:31:08.608363-08\' WHERE joinkey = \'wm93p42\' AND pap_author = \'Baird SE\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two37\' WHERE joinkey = \'wm93p42\' AND pap_author = \'Baird SE\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:31:08.627677-08\' WHERE joinkey = \'wm93p43\' AND pap_author = \'Baird SE\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two37\' WHERE joinkey = \'wm93p43\' AND pap_author = \'Baird SE\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:33:04.322238-08\' WHERE joinkey = \'wm93p44\' AND pap_author = \'Baird SE\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two37\' WHERE joinkey = \'wm93p44\' AND pap_author = \'Baird SE\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:33:04.347529-08\' WHERE joinkey = \'wm95p109\' AND pap_author = \'Baird SE\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two37\' WHERE joinkey = \'wm95p109\' AND pap_author = \'Baird SE\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:33:04.358829-08\' WHERE joinkey = \'wm97ab148\' AND pap_author = \'Baird SE\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two37\' WHERE joinkey = \'wm97ab148\' AND pap_author = \'Baird SE\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:33:04.378925-08\' WHERE joinkey = \'wm97ab307\' AND pap_author = \'Baird SE\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two37\' WHERE joinkey = \'wm97ab307\' AND pap_author = \'Baird SE\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:33:04.395241-08\' WHERE joinkey = \'wm97ab578\' AND pap_author = \'Baird SE\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two37\' WHERE joinkey = \'wm97ab578\' AND pap_author = \'Baird SE\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:33:04.427529-08\' WHERE joinkey = \'wm99ab172\' AND pap_author = \'Baird SE\" Affiliation_address \"Department of Biological Sciences, Wright State University, Dayton OH\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two37\' WHERE joinkey = \'wm99ab172\' AND pap_author = \'Baird SE\" Affiliation_address \"Department of Biological Sciences, Wright State University, Dayton OH\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:33:04.443415-08\' WHERE joinkey = \'wm99ab765\' AND pap_author = \'Baird SE\" Affiliation_address \"Department of Biological Sciences, Wright State University\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two37\' WHERE joinkey = \'wm99ab765\' AND pap_author = \'Baird SE\" Affiliation_address \"Department of Biological Sciences, Wright State University\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-25 16:33:04.458198-08\' WHERE joinkey = \'wm99ab929\' AND pap_author = \'Baird SE\" Affiliation_address \"Department of Biological Sciences, Wright State University\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two37\' WHERE joinkey = \'wm99ab929\' AND pap_author = \'Baird SE\" Affiliation_address \"Department of Biological Sciences, Wright State University\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 09:01:14.354693-08\' WHERE joinkey = \'cgc2817\' AND pap_author = \'Baldwin JG\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two38\' WHERE joinkey = \'cgc2817\' AND pap_author = \'Baldwin JG\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 09:01:14.526278-08\' WHERE joinkey = \'cgc2883\' AND pap_author = \'Baldwin JG\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two38\' WHERE joinkey = \'cgc2883\' AND pap_author = \'Baldwin JG\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 09:01:14.537855-08\' WHERE joinkey = \'cgc3272\' AND pap_author = \'Baldwin JG\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two38\' WHERE joinkey = \'cgc3272\' AND pap_author = \'Baldwin JG\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 09:01:14.555534-08\' WHERE joinkey = \'cgc3879\' AND pap_author = \'Baldwin JG\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two38\' WHERE joinkey = \'cgc3879\' AND pap_author = \'Baldwin JG\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 09:01:14.568858-08\' WHERE joinkey = \'cgc4186\' AND pap_author = \'Baldwin JG\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two38\' WHERE joinkey = \'cgc4186\' AND pap_author = \'Baldwin JG\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 09:01:14.584697-08\' WHERE joinkey = \'cgc4590\' AND pap_author = \'Baldwin JG\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two38\' WHERE joinkey = \'cgc4590\' AND pap_author = \'Baldwin JG\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 09:03:07.062915-08\' WHERE joinkey = \'wm2001p837\' AND pap_author = \'Baldwin JG\" Affiliation_address \"University of California Riverside. Riverside, CA 92521\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two38\' WHERE joinkey = \'wm2001p837\' AND pap_author = \'Baldwin JG\" Affiliation_address \"University of California Riverside. Riverside, CA 92521\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 09:03:07.128053-08\' WHERE joinkey = \'wm95p516\' AND pap_author = \'Baldwin JG\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two38\' WHERE joinkey = \'wm95p516\' AND pap_author = \'Baldwin JG\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 09:03:07.146902-08\' WHERE joinkey = \'wm97ab131\' AND pap_author = \'Baldwin JG\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two38\' WHERE joinkey = \'wm97ab131\' AND pap_author = \'Baldwin JG\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 09:13:47.793817-08\' WHERE joinkey = \'cgc4146\' AND pap_author = \'Bamber BA\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two39\' WHERE joinkey = \'cgc4146\' AND pap_author = \'Bamber BA\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 09:13:47.810248-08\' WHERE joinkey = \'wcwm2000ab73\' AND pap_author = \'Bamber BA\" Affiliation_address \"Department of Biology, University of Utah, Salt Lake City, UT 84112\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two39\' WHERE joinkey = \'wcwm2000ab73\' AND pap_author = \'Bamber BA\" Affiliation_address \"Department of Biology, University of Utah, Salt Lake City, UT 84112\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 09:13:47.84492-08\' WHERE joinkey = \'wcwm2000ab96\' AND pap_author = \'Bamber BA\" Affiliation_address \"Department of Pharmacology and Toxicology, University of Utah, Salt Lake City, UT, 84112\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two39\' WHERE joinkey = \'wcwm2000ab96\' AND pap_author = \'Bamber BA\" Affiliation_address \"Department of Pharmacology and Toxicology, University of Utah, Salt Lake City, UT, 84112\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 09:13:47.861624-08\' WHERE joinkey = \'wcwm96ab8\' AND pap_author = \'Bamber BA\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two39\' WHERE joinkey = \'wcwm96ab8\' AND pap_author = \'Bamber BA\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 09:13:47.879793-08\' WHERE joinkey = \'wcwm98ab10\' AND pap_author = \'Bamber BA\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two39\' WHERE joinkey = \'wcwm98ab10\' AND pap_author = \'Bamber BA\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 09:13:47.898255-08\' WHERE joinkey = \'wm2001p908\' AND pap_author = \'Bamber BA\" Affiliation_address \"Department of Pharmacology and Toxicology, University of Utah, Salt Lake City, UT 84112\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two39\' WHERE joinkey = \'wm2001p908\' AND pap_author = \'Bamber BA\" Affiliation_address \"Department of Pharmacology and Toxicology, University of Utah, Salt Lake City, UT 84112\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 09:13:47.92567-08\' WHERE joinkey = \'wm95p111\' AND pap_author = \'Bamber BA\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two39\' WHERE joinkey = \'wm95p111\' AND pap_author = \'Bamber BA\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 09:13:47.939059-08\' WHERE joinkey = \'wm97ab32\' AND pap_author = \'Bamber BA\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two39\' WHERE joinkey = \'wm97ab32\' AND pap_author = \'Bamber BA\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 09:13:47.981484-08\' WHERE joinkey = \'wm99ab173\' AND pap_author = \'Bamber BA\" Affiliation_address \"Dept. Biol., Univ. of Utah, Salt Lake City, UT 84112.\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two39\' WHERE joinkey = \'wm99ab173\' AND pap_author = \'Bamber BA\" Affiliation_address \"Dept. Biol., Univ. of Utah, Salt Lake City, UT 84112.\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 09:15:11.473571-08\' WHERE joinkey = \'wm99ab75\' AND pap_author = \'Bamber BA\" Affiliation_address \"Dept. Biol., Univ. of Utah, Salt Lake City, UT 84112.\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two39\' WHERE joinkey = \'wm99ab75\' AND pap_author = \'Bamber BA\" Affiliation_address \"Dept. Biol., Univ. of Utah, Salt Lake City, UT 84112.\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 09:20:01.544053-08\' WHERE joinkey = \'ecwm2000ab69\' AND pap_author = \'Bany IA\" Affiliation_address \"Yale University\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two40\' WHERE joinkey = \'ecwm2000ab69\' AND pap_author = \'Bany IA\" Affiliation_address \"Yale University\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 09:20:01.563545-08\' WHERE joinkey = \'wm2001p383\' AND pap_author = \'Bany IA\" Affiliation_address \"Yale University\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two40\' WHERE joinkey = \'wm2001p383\' AND pap_author = \'Bany IA\" Affiliation_address \"Yale University\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 09:20:01.575442-08\' WHERE joinkey = \'wm99ab176\' AND pap_author = \'Bany IA\" Affiliation_address \"Yale University\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two40\' WHERE joinkey = \'wm99ab176\' AND pap_author = \'Bany IA\" Affiliation_address \"Yale University\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 09:23:04.806167-08\' WHERE joinkey = \'cgc2837\' AND pap_author = \'Baran R\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two41\' WHERE joinkey = \'cgc2837\' AND pap_author = \'Baran R\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 09:23:04.836123-08\' WHERE joinkey = \'cgc3555\' AND pap_author = \'Baran R\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two41\' WHERE joinkey = \'cgc3555\' AND pap_author = \'Baran R\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 09:23:04.857428-08\' WHERE joinkey = \'cgc4705\' AND pap_author = \'Baran R\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two41\' WHERE joinkey = \'cgc4705\' AND pap_author = \'Baran R\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 09:23:04.874361-08\' WHERE joinkey = \'wcwm2000ab97\' AND pap_author = \'Baran R\" Affiliation_address \"Department of Biology, Sinsheimer Labs, University of California, Santa Cruz, CA 95064\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two41\' WHERE joinkey = \'wcwm2000ab97\' AND pap_author = \'Baran R\" Affiliation_address \"Department of Biology, Sinsheimer Labs, University of California, Santa Cruz, CA 95064\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 09:23:04.904157-08\' WHERE joinkey = \'wcwm96ab7\' AND pap_author = \'Baran R\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two41\' WHERE joinkey = \'wcwm96ab7\' AND pap_author = \'Baran R\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 09:23:04.932505-08\' WHERE joinkey = \'wcwm96ab9\' AND pap_author = \'Baran R\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two41\' WHERE joinkey = \'wcwm96ab9\' AND pap_author = \'Baran R\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 09:23:04.948656-08\' WHERE joinkey = \'wm2001p412\' AND pap_author = \'Baran R\" Affiliation_address \"HHMI and Dept. of MCD Biology, Sinsheimer Labs, University of California, Santa Cruz, CA 95064.\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two41\' WHERE joinkey = \'wm2001p412\' AND pap_author = \'Baran R\" Affiliation_address \"HHMI and Dept. of MCD Biology, Sinsheimer Labs, University of California, Santa Cruz, CA 95064.\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 09:23:04.962924-08\' WHERE joinkey = \'wm93p170\' AND pap_author = \'Baran R\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two41\' WHERE joinkey = \'wm93p170\' AND pap_author = \'Baran R\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 09:23:04.976928-08\' WHERE joinkey = \'wm95p112\' AND pap_author = \'Baran R\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two41\' WHERE joinkey = \'wm95p112\' AND pap_author = \'Baran R\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 09:23:05.004452-08\' WHERE joinkey = \'wm97ab34\' AND pap_author = \'Baran R\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two41\' WHERE joinkey = \'wm97ab34\' AND pap_author = \'Baran R\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 09:24:13.204141-08\' WHERE joinkey = \'wm99ab159\' AND pap_author = \'Baran R\" Affiliation_address \"Dept. of Biology, Sinsheimer Laboratories, UCSC, Santa Cruz, CA 95064, USA.\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two41\' WHERE joinkey = \'wm99ab159\' AND pap_author = \'Baran R\" Affiliation_address \"Dept. of Biology, Sinsheimer Laboratories, UCSC, Santa Cruz, CA 95064, USA.\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 09:24:13.238999-08\' WHERE joinkey = \'wm99ab177\' AND pap_author = \'Baran R\" Affiliation_address \"University of California, Santa Cruz\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two41\' WHERE joinkey = \'wm99ab177\' AND pap_author = \'Baran R\" Affiliation_address \"University of California, Santa Cruz\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:01:02.625127-08\' WHERE joinkey = \'cgc1374\' AND pap_author = \'Bargmann CI\" -C \"et\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'cgc1374\' AND pap_author = \'Bargmann CI\" -C \"et\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:01:02.687396-08\' WHERE joinkey = \'cgc1393\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'cgc1393\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:01:02.699112-08\' WHERE joinkey = \'cgc1481\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'cgc1481\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:01:02.712858-08\' WHERE joinkey = \'cgc1579\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'cgc1579\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:01:02.725308-08\' WHERE joinkey = \'cgc1704\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'cgc1704\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:01:02.737174-08\' WHERE joinkey = \'cgc1727\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'cgc1727\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:01:02.753598-08\' WHERE joinkey = \'cgc1728\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'cgc1728\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:01:02.775236-08\' WHERE joinkey = \'cgc1733\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'cgc1733\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:01:02.789628-08\' WHERE joinkey = \'cgc1786\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'cgc1786\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:01:02.80239-08\' WHERE joinkey = \'cgc1856\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'cgc1856\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:03:03.305678-08\' WHERE joinkey = \'cgc2031\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'cgc2031\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:03:03.325347-08\' WHERE joinkey = \'cgc2090\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'cgc2090\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:03:03.348235-08\' WHERE joinkey = \'cgc2166\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'cgc2166\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:03:03.371261-08\' WHERE joinkey = \'cgc2253\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'cgc2253\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:03:03.382398-08\' WHERE joinkey = \'cgc2308\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'cgc2308\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:03:03.399686-08\' WHERE joinkey = \'cgc2314\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'cgc2314\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:03:03.419168-08\' WHERE joinkey = \'cgc2403\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'cgc2403\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:03:03.439713-08\' WHERE joinkey = \'cgc2404\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'cgc2404\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:03:03.459755-08\' WHERE joinkey = \'cgc2421\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'cgc2421\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:03:03.474808-08\' WHERE joinkey = \'cgc2584\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'cgc2584\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:05:05.590999-08\' WHERE joinkey = \'cgc2689\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'cgc2689\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:05:05.610915-08\' WHERE joinkey = \'cgc2810\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'cgc2810\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:05:05.649688-08\' WHERE joinkey = \'cgc2858\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'cgc2858\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:05:05.66572-08\' WHERE joinkey = \'cgc2892\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'cgc2892\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:05:05.683351-08\' WHERE joinkey = \'cgc2917\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'cgc2917\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:05:05.695883-08\' WHERE joinkey = \'cgc2930\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'cgc2930\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:05:05.713104-08\' WHERE joinkey = \'cgc2931\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'cgc2931\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:05:05.728624-08\' WHERE joinkey = \'cgc2996\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'cgc2996\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:05:05.755063-08\' WHERE joinkey = \'cgc2997\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'cgc2997\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:05:05.768686-08\' WHERE joinkey = \'cgc3016\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'cgc3016\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:07:03.217009-08\' WHERE joinkey = \'cgc3024\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'cgc3024\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:07:03.262504-08\' WHERE joinkey = \'cgc3063\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'cgc3063\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:07:03.293278-08\' WHERE joinkey = \'cgc3187\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'cgc3187\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:07:03.312352-08\' WHERE joinkey = \'cgc3196\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'cgc3196\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:07:03.337299-08\' WHERE joinkey = \'cgc3300\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'cgc3300\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:07:03.387042-08\' WHERE joinkey = \'cgc3430\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'cgc3430\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:07:03.42768-08\' WHERE joinkey = \'cgc3521\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'cgc3521\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:07:03.453263-08\' WHERE joinkey = \'cgc3593\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'cgc3593\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:07:03.494222-08\' WHERE joinkey = \'cgc3665\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'cgc3665\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:07:03.518677-08\' WHERE joinkey = \'cgc3751\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'cgc3751\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:09:45.548375-08\' WHERE joinkey = \'cgc3760\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'cgc3760\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:09:45.593011-08\' WHERE joinkey = \'cgc3980\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'cgc3980\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:09:45.631179-08\' WHERE joinkey = \'cgc4340\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'cgc4340\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:09:45.666102-08\' WHERE joinkey = \'cgc4498\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'cgc4498\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:09:45.683948-08\' WHERE joinkey = \'cgc4523\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'cgc4523\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:09:45.706103-08\' WHERE joinkey = \'cgc4610\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'cgc4610\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:09:45.746542-08\' WHERE joinkey = \'cgc4666\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'cgc4666\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:09:45.782404-08\' WHERE joinkey = \'cgc4669\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'cgc4669\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:09:45.817443-08\' WHERE joinkey = \'cgc4806\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'cgc4806\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:13:41.442635-08\' WHERE joinkey = \'cgc4878\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'cgc4878\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:13:41.534375-08\' WHERE joinkey = \'cgc5004\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'cgc5004\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:13:41.556197-08\' WHERE joinkey = \'cgc5061\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'cgc5061\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:13:41.575708-08\' WHERE joinkey = \'cgc5102\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'cgc5102\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:13:41.623352-08\' WHERE joinkey = \'cgc5226\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'cgc5226\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:13:41.693116-08\' WHERE joinkey = \'cgc5363\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'cgc5363\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:13:41.72895-08\' WHERE joinkey = \'ecwm2000ab173\' AND pap_author = \'Bargmann CI\" Affiliation_address \"HHMI, UCSF, San Francisco, CA 94143\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'ecwm2000ab173\' AND pap_author = \'Bargmann CI\" Affiliation_address \"HHMI, UCSF, San Francisco, CA 94143\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:16:09.147751-08\' WHERE joinkey = \'euwm2000ab54\' AND pap_author = \'Bargmann CI\" Affiliation_address \"HHMI/UCSF, San Francisco, CA 94143 USA\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'euwm2000ab54\' AND pap_author = \'Bargmann CI\" Affiliation_address \"HHMI/UCSF, San Francisco, CA 94143 USA\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:16:09.195652-08\' WHERE joinkey = \'med94221915\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'med94221915\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:16:09.229463-08\' WHERE joinkey = \'mwwm2000ab21\' AND pap_author = \'Bargmann CI\" Affiliation_address \"HHMI, UCSF, San Francisco, CA 94143\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'mwwm2000ab21\' AND pap_author = \'Bargmann CI\" Affiliation_address \"HHMI, UCSF, San Francisco, CA 94143\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:16:09.248511-08\' WHERE joinkey = \'wbg10.2p42\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wbg10.2p42\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:16:09.259577-08\' WHERE joinkey = \'wbg11.1p52\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wbg11.1p52\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:16:09.276448-08\' WHERE joinkey = \'wbg11.4p107\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wbg11.4p107\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:16:09.293267-08\' WHERE joinkey = \'wbg13.3p89\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wbg13.3p89\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:16:09.340255-08\' WHERE joinkey = \'wcwm2000ab115\' AND pap_author = \'Bargmann CI\" Affiliation_address \"Howard Hughes Medical Institute and Department of Anatomy, University of California, San Francisco, CA 94143-0452 USA\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wcwm2000ab115\' AND pap_author = \'Bargmann CI\" Affiliation_address \"Howard Hughes Medical Institute and Department of Anatomy, University of California, San Francisco, CA 94143-0452 USA\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:16:09.353704-08\' WHERE joinkey = \'wcwm2000ab132\' AND pap_author = \'Bargmann CI\" Affiliation_address \"HHMI, Dept. of Anatomy, UCSF, San Francisco, CA 94143\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wcwm2000ab132\' AND pap_author = \'Bargmann CI\" Affiliation_address \"HHMI, Dept. of Anatomy, UCSF, San Francisco, CA 94143\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:18:26.27152-08\' WHERE joinkey = \'wcwm2000ab138\' AND pap_author = \'Bargmann CI\" Affiliation_address \"UCSF and HHMI, San Francisco, CA 94143\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wcwm2000ab138\' AND pap_author = \'Bargmann CI\" Affiliation_address \"UCSF and HHMI, San Francisco, CA 94143\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:18:26.297422-08\' WHERE joinkey = \'wcwm2000ab163\' AND pap_author = \'Bargmann CI\" Affiliation_address \"UCSF, 513 Parnassus Ave, San Francisco, CA 94143-0452\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wcwm2000ab163\' AND pap_author = \'Bargmann CI\" Affiliation_address \"UCSF, 513 Parnassus Ave, San Francisco, CA 94143-0452\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:18:26.315902-08\' WHERE joinkey = \'wcwm2000ab172\' AND pap_author = \'Bargmann CI\" Affiliation_address \"HHMI and Department of Anatomy; UCSF; San Francisco, CA 94131\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wcwm2000ab172\' AND pap_author = \'Bargmann CI\" Affiliation_address \"HHMI and Department of Anatomy; UCSF; San Francisco, CA 94131\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:18:26.331808-08\' WHERE joinkey = \'wcwm2000ab177\' AND pap_author = \'Bargmann CI\" Affiliation_address \"HHMI/Dept. Anatomy, UCSF, San Francisco, CA 94143\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wcwm2000ab177\' AND pap_author = \'Bargmann CI\" Affiliation_address \"HHMI/Dept. Anatomy, UCSF, San Francisco, CA 94143\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:18:26.356011-08\' WHERE joinkey = \'wcwm2000ab19\' AND pap_author = \'Bargmann CI\" Affiliation_address \"HHMI and Department of Anatomy. University of California, San Francisco, CA 94143-0452\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wcwm2000ab19\' AND pap_author = \'Bargmann CI\" Affiliation_address \"HHMI and Department of Anatomy. University of California, San Francisco, CA 94143-0452\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:18:26.373715-08\' WHERE joinkey = \'wcwm2000ab193\' AND pap_author = \'Bargmann CI\" Affiliation_address \"U.C. San Francisco\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wcwm2000ab193\' AND pap_author = \'Bargmann CI\" Affiliation_address \"U.C. San Francisco\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:18:26.413377-08\' WHERE joinkey = \'wcwm2000ab50\' AND pap_author = \'Bargmann CI\" Affiliation_address \"Dept. of Anatomy, UCSF\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wcwm2000ab50\' AND pap_author = \'Bargmann CI\" Affiliation_address \"Dept. of Anatomy, UCSF\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:18:26.433376-08\' WHERE joinkey = \'wcwm2000ab68\' AND pap_author = \'Bargmann CI\" Affiliation_address \"HHMI, UCSF, San Francisco, CA 94143-0452\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wcwm2000ab68\' AND pap_author = \'Bargmann CI\" Affiliation_address \"HHMI, UCSF, San Francisco, CA 94143-0452\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:18:26.459513-08\' WHERE joinkey = \'wcwm2000ab69\' AND pap_author = \'Bargmann CI\" Affiliation_address \"Department of Anatomy and HHMI, UCSF, San Francisco, CA 94143-0452, USA\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wcwm2000ab69\' AND pap_author = \'Bargmann CI\" Affiliation_address \"Department of Anatomy and HHMI, UCSF, San Francisco, CA 94143-0452, USA\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:20:18.005934-08\' WHERE joinkey = \'wcwm2000ab80\' AND pap_author = \'Bargmann CI\" Affiliation_address \"UCSF and HHMI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wcwm2000ab80\' AND pap_author = \'Bargmann CI\" Affiliation_address \"UCSF and HHMI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:20:18.026149-08\' WHERE joinkey = \'wcwm2000ab88\' AND pap_author = \'Bargmann CI\" Affiliation_address \"Department of Anatomy, UCSF, San Francisco, CA 94143\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wcwm2000ab88\' AND pap_author = \'Bargmann CI\" Affiliation_address \"Department of Anatomy, UCSF, San Francisco, CA 94143\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:20:18.038809-08\' WHERE joinkey = \'wcwm96ab121\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wcwm96ab121\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:20:18.053297-08\' WHERE joinkey = \'wcwm96ab130\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wcwm96ab130\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:20:18.068735-08\' WHERE joinkey = \'wcwm96ab161\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wcwm96ab161\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:20:18.083203-08\' WHERE joinkey = \'wcwm96ab162\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wcwm96ab162\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:20:18.098746-08\' WHERE joinkey = \'wcwm96ab185\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wcwm96ab185\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:20:18.122698-08\' WHERE joinkey = \'wcwm96ab25\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wcwm96ab25\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:20:18.14855-08\' WHERE joinkey = \'wcwm96ab27\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wcwm96ab27\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:20:18.193623-08\' WHERE joinkey = \'wcwm96ab28\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wcwm96ab28\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:22:09.907705-08\' WHERE joinkey = \'wcwm96ab32\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wcwm96ab32\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:22:09.992596-08\' WHERE joinkey = \'wcwm96ab37\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wcwm96ab37\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:22:10.005623-08\' WHERE joinkey = \'wcwm96ab40\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wcwm96ab40\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:22:10.022935-08\' WHERE joinkey = \'wcwm96ab89\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wcwm96ab89\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:22:10.034731-08\' WHERE joinkey = \'wcwm96ab97\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wcwm96ab97\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:22:10.053187-08\' WHERE joinkey = \'wcwm98ab106\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wcwm98ab106\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:22:10.08755-08\' WHERE joinkey = \'wcwm98ab131\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wcwm98ab131\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:22:10.119163-08\' WHERE joinkey = \'wcwm98ab146\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wcwm98ab146\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:22:10.131657-08\' WHERE joinkey = \'wcwm98ab16\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wcwm98ab16\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:22:10.145197-08\' WHERE joinkey = \'wcwm98ab171\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wcwm98ab171\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:24:22.441338-08\' WHERE joinkey = \'wcwm98ab172\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wcwm98ab172\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:24:22.464239-08\' WHERE joinkey = \'wcwm98ab188\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wcwm98ab188\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:24:22.483385-08\' WHERE joinkey = \'wcwm98ab191\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wcwm98ab191\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:24:22.497324-08\' WHERE joinkey = \'wcwm98ab204\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wcwm98ab204\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:24:22.509745-08\' WHERE joinkey = \'wcwm98ab34\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wcwm98ab34\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:24:22.524493-08\' WHERE joinkey = \'wcwm98ab43\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wcwm98ab43\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:24:22.536886-08\' WHERE joinkey = \'wcwm98ab59\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wcwm98ab59\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:24:22.555992-08\' WHERE joinkey = \'wcwm98ab89\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wcwm98ab89\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:24:22.578761-08\' WHERE joinkey = \'wm2001p100\' AND pap_author = \'Bargmann CI\" Affiliation_address \"HHMI/Dept. Anatomy, UCSF, San Francisco, CA 94143\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wm2001p100\' AND pap_author = \'Bargmann CI\" Affiliation_address \"HHMI/Dept. Anatomy, UCSF, San Francisco, CA 94143\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:24:22.626134-08\' WHERE joinkey = \'wm2001p116\' AND pap_author = \'Bargmann CI\" Affiliation_address \"Anatomy/HHMI, UCSF, San Francisco, U.S.A.\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wm2001p116\' AND pap_author = \'Bargmann CI\" Affiliation_address \"Anatomy/HHMI, UCSF, San Francisco, U.S.A.\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:27:11.985427-08\' WHERE joinkey = \'wm2001p122\' AND pap_author = \'Bargmann CI\" Affiliation_address \"UCSF, Dept. of Anatomy, 513 Parnassus Avenue, San Francisco, CA 94143-0452\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wm2001p122\' AND pap_author = \'Bargmann CI\" Affiliation_address \"UCSF, Dept. of Anatomy, 513 Parnassus Avenue, San Francisco, CA 94143-0452\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:27:12.007948-08\' WHERE joinkey = \'wm2001p142\' AND pap_author = \'Bargmann CI\" Affiliation_address \"HHMI, UCSF, 513 Parnassus Ave, San Francisco, CA 94143-0452\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wm2001p142\' AND pap_author = \'Bargmann CI\" Affiliation_address \"HHMI, UCSF, 513 Parnassus Ave, San Francisco, CA 94143-0452\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:27:12.0363-08\' WHERE joinkey = \'wm2001p143\' AND pap_author = \'Bargmann CI\" Affiliation_address \"HHMI and Department of Anatomy; UCSF; San Francisco, CA 94143\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wm2001p143\' AND pap_author = \'Bargmann CI\" Affiliation_address \"HHMI and Department of Anatomy; UCSF; San Francisco, CA 94143\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:27:12.109029-08\' WHERE joinkey = \'wm2001p392\' AND pap_author = \'Bargmann CI\" Affiliation_address \"HHMI and Department of Anatomy. University of California, San Francisco, CA 94143-0452.\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wm2001p392\' AND pap_author = \'Bargmann CI\" Affiliation_address \"HHMI and Department of Anatomy. University of California, San Francisco, CA 94143-0452.\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:27:12.129416-08\' WHERE joinkey = \'wm2001p395\' AND pap_author = \'Bargmann CI\" Affiliation_address \"UCSF and\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wm2001p395\' AND pap_author = \'Bargmann CI\" Affiliation_address \"UCSF and\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:27:12.151187-08\' WHERE joinkey = \'wm2001p401\' AND pap_author = \'Bargmann CI\" Affiliation_address \"HHMI and Dept. of Anatomy, UCSF, San Francisco, CA 94143-0452\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wm2001p401\' AND pap_author = \'Bargmann CI\" Affiliation_address \"HHMI and Dept. of Anatomy, UCSF, San Francisco, CA 94143-0452\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:27:12.182429-08\' WHERE joinkey = \'wm2001p406\' AND pap_author = \'Bargmann CI\" Affiliation_address \"HHMI and UCSF, 513 Parnassus Ave, Rm S-1471, San Francisco, CA 94143-0452\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wm2001p406\' AND pap_author = \'Bargmann CI\" Affiliation_address \"HHMI and UCSF, 513 Parnassus Ave, Rm S-1471, San Francisco, CA 94143-0452\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:27:12.199918-08\' WHERE joinkey = \'wm2001p582\' AND pap_author = \'Bargmann CI\" Affiliation_address \"U.C. San Francisco and HHMI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wm2001p582\' AND pap_author = \'Bargmann CI\" Affiliation_address \"U.C. San Francisco and HHMI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:29:15.890699-08\' WHERE joinkey = \'wm2001p59\' AND pap_author = \'Bargmann CI\" Affiliation_address \"Howard Hughes Medical Institute, Programs in Developmental Biology, Neurosiences, and Genetics, Department of Anatomy and Department of Biochemistry and Biophysics, The University of California, San Francisco, California 94143-9452, USA\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wm2001p59\' AND pap_author = \'Bargmann CI\" Affiliation_address \"Howard Hughes Medical Institute, Programs in Developmental Biology, Neurosiences, and Genetics, Department of Anatomy and Department of Biochemistry and Biophysics, The University of California, San Francisco, California 94143-9452, USA\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:29:15.951739-08\' WHERE joinkey = \'wm2001p61\' AND pap_author = \'Bargmann CI\" Affiliation_address \"HHMI, Departments of Anatomy and Physiology UCSF, San Francisco, CA 94143\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wm2001p61\' AND pap_author = \'Bargmann CI\" Affiliation_address \"HHMI, Departments of Anatomy and Physiology UCSF, San Francisco, CA 94143\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:29:15.968523-08\' WHERE joinkey = \'wm2001p704\' AND pap_author = \'Bargmann CI\" Affiliation_address \"HHMI and Department of Anatomy; UCSF; San Francisco, CA  94131\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wm2001p704\' AND pap_author = \'Bargmann CI\" Affiliation_address \"HHMI and Department of Anatomy; UCSF; San Francisco, CA  94131\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:29:15.988625-08\' WHERE joinkey = \'wm2001p92\' AND pap_author = \'Bargmann CI\" Affiliation_address \"HHMI, Dept. of Anatomy, UCSF, San Francisco, CA 94143\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wm2001p92\' AND pap_author = \'Bargmann CI\" Affiliation_address \"HHMI, Dept. of Anatomy, UCSF, San Francisco, CA 94143\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:29:16.014549-08\' WHERE joinkey = \'wm2001p930\' AND pap_author = \'Bargmann CI\" Affiliation_address \"HHMI, UCSF, San Francisco, CA 94143 USA\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wm2001p930\' AND pap_author = \'Bargmann CI\" Affiliation_address \"HHMI, UCSF, San Francisco, CA 94143 USA\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:29:16.083442-08\' WHERE joinkey = \'wm2001p931\' AND pap_author = \'Bargmann CI\" Affiliation_address \"HHMI and UCSF, Dept. of Anatomy, San Francisco, CA 94143-0452\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wm2001p931\' AND pap_author = \'Bargmann CI\" Affiliation_address \"HHMI and UCSF, Dept. of Anatomy, San Francisco, CA 94143-0452\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:29:16.100433-08\' WHERE joinkey = \'wm89p181\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wm89p181\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:29:16.11594-08\' WHERE joinkey = \'wm91p1\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wm91p1\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:29:16.128147-08\' WHERE joinkey = \'wm93p110\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wm93p110\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:29:16.157064-08\' WHERE joinkey = \'wm93p243\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wm93p243\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:32:07.014221-08\' WHERE joinkey = \'wm93p301\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wm93p301\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:32:07.051955-08\' WHERE joinkey = \'wm93p403\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wm93p403\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:32:07.067158-08\' WHERE joinkey = \'wm93p90\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wm93p90\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:32:07.08166-08\' WHERE joinkey = \'wm93p91\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wm93p91\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:32:07.103068-08\' WHERE joinkey = \'wm95p152\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wm95p152\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:32:07.119592-08\' WHERE joinkey = \'wm95p155\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wm95p155\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:32:07.132856-08\' WHERE joinkey = \'wm95p158\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wm95p158\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:32:07.156012-08\' WHERE joinkey = \'wm95p18\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wm95p18\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:32:07.17866-08\' WHERE joinkey = \'wm95p195\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wm95p195\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:32:07.196343-08\' WHERE joinkey = \'wm95p363\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wm95p363\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:34:11.828973-08\' WHERE joinkey = \'wm95p411\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wm95p411\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:34:11.854305-08\' WHERE joinkey = \'wm95p464\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wm95p464\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:34:11.876742-08\' WHERE joinkey = \'wm95p520\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wm95p520\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:34:11.889636-08\' WHERE joinkey = \'wm95p562\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wm95p562\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:34:11.903816-08\' WHERE joinkey = \'wm95p70\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wm95p70\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:34:11.921521-08\' WHERE joinkey = \'wm95p81\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wm95p81\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:34:11.938348-08\' WHERE joinkey = \'wm97ab108\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wm97ab108\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:34:11.953192-08\' WHERE joinkey = \'wm97ab120\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wm97ab120\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:34:11.964621-08\' WHERE joinkey = \'wm97ab121\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wm97ab121\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:34:11.985093-08\' WHERE joinkey = \'wm97ab335\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wm97ab335\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:36:13.186114-08\' WHERE joinkey = \'wm97ab374\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wm97ab374\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:36:13.211774-08\' WHERE joinkey = \'wm97ab473\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wm97ab473\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:36:13.227334-08\' WHERE joinkey = \'wm97ab556\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wm97ab556\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:36:13.245272-08\' WHERE joinkey = \'wm97ab605\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wm97ab605\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:36:13.257385-08\' WHERE joinkey = \'wm97ab606\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wm97ab606\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:36:13.269967-08\' WHERE joinkey = \'wm97ab675\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wm97ab675\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:36:13.286573-08\' WHERE joinkey = \'wm97ab677\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wm97ab677\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:36:13.297478-08\' WHERE joinkey = \'wm97ab95\' AND pap_author = \'Bargmann CI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wm97ab95\' AND pap_author = \'Bargmann CI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:36:13.311925-08\' WHERE joinkey = \'wm99ab22\' AND pap_author = \'Bargmann CI\" Affiliation_address \"Dept. Anatomy and HHMI, UCSF\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wm99ab22\' AND pap_author = \'Bargmann CI\" Affiliation_address \"Dept. Anatomy and HHMI, UCSF\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:36:13.334089-08\' WHERE joinkey = \'wm99ab23\' AND pap_author = \'Bargmann CI\" Affiliation_address \"UCSF and HHMI, San Francisco, CA 94143.\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wm99ab23\' AND pap_author = \'Bargmann CI\" Affiliation_address \"UCSF and HHMI, San Francisco, CA 94143.\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:38:12.949444-08\' WHERE joinkey = \'wm99ab250\' AND pap_author = \'Bargmann CI\" Affiliation_address \"HHMI and UCSF, Box 0452, San Francisco, CA 94143 U.S.A.\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wm99ab250\' AND pap_author = \'Bargmann CI\" Affiliation_address \"HHMI and UCSF, Box 0452, San Francisco, CA 94143 U.S.A.\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:38:12.981924-08\' WHERE joinkey = \'wm99ab264\' AND pap_author = \'Bargmann CI\" Affiliation_address \"HHMI/Dept. of Anatomy, UCSF, San Francisco CA 94143, USA\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wm99ab264\' AND pap_author = \'Bargmann CI\" Affiliation_address \"HHMI/Dept. of Anatomy, UCSF, San Francisco CA 94143, USA\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:38:13.004335-08\' WHERE joinkey = \'wm99ab27\' AND pap_author = \'Bargmann CI\" Affiliation_address \"UCSF, San Francisco, CA 94143.\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wm99ab27\' AND pap_author = \'Bargmann CI\" Affiliation_address \"UCSF, San Francisco, CA 94143.\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:38:13.028225-08\' WHERE joinkey = \'wm99ab339\' AND pap_author = \'Bargmann CI\" Affiliation_address \"Dept. of Biochemistry and HHMI, UCSF, San Francisco, CA 94143-0452\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wm99ab339\' AND pap_author = \'Bargmann CI\" Affiliation_address \"Dept. of Biochemistry and HHMI, UCSF, San Francisco, CA 94143-0452\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:38:13.047619-08\' WHERE joinkey = \'wm99ab373\' AND pap_author = \'Bargmann CI\" Affiliation_address \"Department of Anatomy and HHMI, UCSF, San Francisco, CA 94143-0452, USA\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wm99ab373\' AND pap_author = \'Bargmann CI\" Affiliation_address \"Department of Anatomy and HHMI, UCSF, San Francisco, CA 94143-0452, USA\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:38:13.063675-08\' WHERE joinkey = \'wm99ab448\' AND pap_author = \'Bargmann CI\" Affiliation_address \"Howard Hughes Medical Institute and University of California, San Francisco. 513 Parnassus Avenue, San Francisco, CA 94143-0452.\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wm99ab448\' AND pap_author = \'Bargmann CI\" Affiliation_address \"Howard Hughes Medical Institute and University of California, San Francisco. 513 Parnassus Avenue, San Francisco, CA 94143-0452.\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:38:13.092542-08\' WHERE joinkey = \'wm99ab479\' AND pap_author = \'Bargmann CI\" Affiliation_address \"HHMI and Department of Anatomy; UCSF; San Francisco, CA 94143\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wm99ab479\' AND pap_author = \'Bargmann CI\" Affiliation_address \"HHMI and Department of Anatomy; UCSF; San Francisco, CA 94143\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:38:13.10874-08\' WHERE joinkey = \'wm99ab555\' AND pap_author = \'Bargmann CI\" Affiliation_address \"University of California-San Francisco\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wm99ab555\' AND pap_author = \'Bargmann CI\" Affiliation_address \"University of California-San Francisco\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:38:13.128661-08\' WHERE joinkey = \'wm99ab574\' AND pap_author = \'Bargmann CI\" Affiliation_address \"U.C. San Francisco and Howard Hughes Medical Institute\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wm99ab574\' AND pap_author = \'Bargmann CI\" Affiliation_address \"U.C. San Francisco and Howard Hughes Medical Institute\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:38:13.142508-08\' WHERE joinkey = \'wm99ab629\' AND pap_author = \'Bargmann CI\" Affiliation_address \"The University of California, San Francisco, California.\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wm99ab629\' AND pap_author = \'Bargmann CI\" Affiliation_address \"The University of California, San Francisco, California.\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:40:02.765176-08\' WHERE joinkey = \'wm99ab730\' AND pap_author = \'Bargmann CI\" Affiliation_address \"Department of Anatomy, UCSF and HHMI, 94143-0452\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wm99ab730\' AND pap_author = \'Bargmann CI\" Affiliation_address \"Department of Anatomy, UCSF and HHMI, 94143-0452\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:40:02.793505-08\' WHERE joinkey = \'wm99ab763\' AND pap_author = \'Bargmann CI\" Affiliation_address \"UCSF, 513 Parnassus Avenue, San Francisco, CA 94143\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wm99ab763\' AND pap_author = \'Bargmann CI\" Affiliation_address \"UCSF, 513 Parnassus Avenue, San Francisco, CA 94143\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:40:02.81169-08\' WHERE joinkey = \'wm99ab764\' AND pap_author = \'Bargmann CI\" Affiliation_address \"UCSF, 513 Parnassus Avenue, San Francisco, CA 94143\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wm99ab764\' AND pap_author = \'Bargmann CI\" Affiliation_address \"UCSF, 513 Parnassus Avenue, San Francisco, CA 94143\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:40:02.851807-08\' WHERE joinkey = \'wm99ab853\' AND pap_author = \'Bargmann CI\" Affiliation_address \"HHMI and UCSF\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wm99ab853\' AND pap_author = \'Bargmann CI\" Affiliation_address \"HHMI and UCSF\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:40:02.867955-08\' WHERE joinkey = \'wm99ab900\' AND pap_author = \'Bargmann CI\" Affiliation_address \"HHMI and Department of Anatomy. University of California, San Francisco, CA 94143-0452\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wm99ab900\' AND pap_author = \'Bargmann CI\" Affiliation_address \"HHMI and Department of Anatomy. University of California, San Francisco, CA 94143-0452\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:40:02.882316-08\' WHERE joinkey = \'wm99ab940\' AND pap_author = \'Bargmann CI\" Affiliation_address \"HHMI and UCSF, San Francisco, CA 94143\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'wm99ab940\' AND pap_author = \'Bargmann CI\" Affiliation_address \"HHMI and UCSF, San Francisco, CA 94143\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:46:50.838897-08\' WHERE joinkey = \'cgc1475\' AND pap_author = \'Barnes TM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two43\' WHERE joinkey = \'cgc1475\' AND pap_author = \'Barnes TM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:46:50.87201-08\' WHERE joinkey = \'cgc2020\' AND pap_author = \'Barnes TM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two43\' WHERE joinkey = \'cgc2020\' AND pap_author = \'Barnes TM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:46:50.88918-08\' WHERE joinkey = \'cgc2238\' AND pap_author = \'Barnes TM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two43\' WHERE joinkey = \'cgc2238\' AND pap_author = \'Barnes TM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:46:50.908795-08\' WHERE joinkey = \'cgc2474\' AND pap_author = \'Barnes TM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two43\' WHERE joinkey = \'cgc2474\' AND pap_author = \'Barnes TM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:46:50.924309-08\' WHERE joinkey = \'cgc2548\' AND pap_author = \'Barnes TM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two43\' WHERE joinkey = \'cgc2548\' AND pap_author = \'Barnes TM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:46:50.945633-08\' WHERE joinkey = \'cgc2658\' AND pap_author = \'Barnes TM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two43\' WHERE joinkey = \'cgc2658\' AND pap_author = \'Barnes TM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:46:50.962239-08\' WHERE joinkey = \'cgc2798\' AND pap_author = \'Barnes TM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two43\' WHERE joinkey = \'cgc2798\' AND pap_author = \'Barnes TM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:46:50.989612-08\' WHERE joinkey = \'cgc2845\' AND pap_author = \'Barnes TM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two43\' WHERE joinkey = \'cgc2845\' AND pap_author = \'Barnes TM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:46:51.02291-08\' WHERE joinkey = \'cgc2860\' AND pap_author = \'Barnes TM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two43\' WHERE joinkey = \'cgc2860\' AND pap_author = \'Barnes TM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:46:51.037759-08\' WHERE joinkey = \'cgc2950\' AND pap_author = \'Barnes TM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two43\' WHERE joinkey = \'cgc2950\' AND pap_author = \'Barnes TM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:50:12.434688-08\' WHERE joinkey = \'cgc2975\' AND pap_author = \'Barnes TM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two43\' WHERE joinkey = \'cgc2975\' AND pap_author = \'Barnes TM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:50:12.514174-08\' WHERE joinkey = \'cgc3184\' AND pap_author = \'Barnes TM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two43\' WHERE joinkey = \'cgc3184\' AND pap_author = \'Barnes TM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:50:12.541437-08\' WHERE joinkey = \'cgc3566\' AND pap_author = \'Barnes TM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two43\' WHERE joinkey = \'cgc3566\' AND pap_author = \'Barnes TM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:50:12.573247-08\' WHERE joinkey = \'cgc4884\' AND pap_author = \'Barnes T\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two43\' WHERE joinkey = \'cgc4884\' AND pap_author = \'Barnes T\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:50:12.598523-08\' WHERE joinkey = \'ecwm96ab9\' AND pap_author = \'Barnes TM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two43\' WHERE joinkey = \'ecwm96ab9\' AND pap_author = \'Barnes TM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:50:12.625558-08\' WHERE joinkey = \'ecwm96ab94\' AND pap_author = \'Barnes TM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two43\' WHERE joinkey = \'ecwm96ab94\' AND pap_author = \'Barnes TM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:50:12.642509-08\' WHERE joinkey = \'ecwm98ab9\' AND pap_author = \'Barnes TM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two43\' WHERE joinkey = \'ecwm98ab9\' AND pap_author = \'Barnes TM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:50:12.658933-08\' WHERE joinkey = \'wbg11.2p47\' AND pap_author = \'Barnes TM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two43\' WHERE joinkey = \'wbg11.2p47\' AND pap_author = \'Barnes TM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:50:12.679069-08\' WHERE joinkey = \'wbg11.4p27a\' AND pap_author = \'Barnes TM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two43\' WHERE joinkey = \'wbg11.4p27a\' AND pap_author = \'Barnes TM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:52:07.921709-08\' WHERE joinkey = \'wbg11.4p27b\' AND pap_author = \'Barnes TM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two43\' WHERE joinkey = \'wbg11.4p27b\' AND pap_author = \'Barnes TM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:52:07.941021-08\' WHERE joinkey = \'wbg11.4p71\' AND pap_author = \'Barnes TM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two43\' WHERE joinkey = \'wbg11.4p71\' AND pap_author = \'Barnes TM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:52:07.953443-08\' WHERE joinkey = \'wbg11.5p66\' AND pap_author = \'Barnes TM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two43\' WHERE joinkey = \'wbg11.5p66\' AND pap_author = \'Barnes TM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:52:07.975927-08\' WHERE joinkey = \'wbg12.1p35\' AND pap_author = \'Barnes TM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two43\' WHERE joinkey = \'wbg12.1p35\' AND pap_author = \'Barnes TM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:52:07.987129-08\' WHERE joinkey = \'wbg12.1p36\' AND pap_author = \'Barnes TM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two43\' WHERE joinkey = \'wbg12.1p36\' AND pap_author = \'Barnes TM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:52:08.00837-08\' WHERE joinkey = \'wbg12.3p24\' AND pap_author = \'Barnes TM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two43\' WHERE joinkey = \'wbg12.3p24\' AND pap_author = \'Barnes TM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:52:08.022008-08\' WHERE joinkey = \'wbg12.3p30\' AND pap_author = \'Barnes TM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two43\' WHERE joinkey = \'wbg12.3p30\' AND pap_author = \'Barnes TM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:52:08.034502-08\' WHERE joinkey = \'wbg12.5p72\' AND pap_author = \'Barnes TM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two43\' WHERE joinkey = \'wbg12.5p72\' AND pap_author = \'Barnes TM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:52:08.046533-08\' WHERE joinkey = \'wbg13.3p18\' AND pap_author = \'Barnes TM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two43\' WHERE joinkey = \'wbg13.3p18\' AND pap_author = \'Barnes TM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:52:08.076171-08\' WHERE joinkey = \'wbg13.3p19\' AND pap_author = \'Barnes TM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two43\' WHERE joinkey = \'wbg13.3p19\' AND pap_author = \'Barnes TM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:53:47.867593-08\' WHERE joinkey = \'wbg14.1p85\' AND pap_author = \'Barnes TM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two43\' WHERE joinkey = \'wbg14.1p85\' AND pap_author = \'Barnes TM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:53:47.899436-08\' WHERE joinkey = \'wbg14.1p86\' AND pap_author = \'Barnes TM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two43\' WHERE joinkey = \'wbg14.1p86\' AND pap_author = \'Barnes TM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:53:47.913352-08\' WHERE joinkey = \'wbg14.2p26\' AND pap_author = \'Barnes TM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two43\' WHERE joinkey = \'wbg14.2p26\' AND pap_author = \'Barnes TM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:53:47.928735-08\' WHERE joinkey = \'wbg14.2p27\' AND pap_author = \'Barnes TM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two43\' WHERE joinkey = \'wbg14.2p27\' AND pap_author = \'Barnes TM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:53:47.943168-08\' WHERE joinkey = \'wbg14.3p57\' AND pap_author = \'Barnes TM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two43\' WHERE joinkey = \'wbg14.3p57\' AND pap_author = \'Barnes TM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:53:47.961183-08\' WHERE joinkey = \'wbg15.1p45\' AND pap_author = \'Barnes TM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two43\' WHERE joinkey = \'wbg15.1p45\' AND pap_author = \'Barnes TM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:53:47.993248-08\' WHERE joinkey = \'wcwm98ab218\' AND pap_author = \'Barnes TM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two43\' WHERE joinkey = \'wcwm98ab218\' AND pap_author = \'Barnes TM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:53:48.008281-08\' WHERE joinkey = \'wm89p34\' AND pap_author = \'Barnes TM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two43\' WHERE joinkey = \'wm89p34\' AND pap_author = \'Barnes TM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:53:48.026665-08\' WHERE joinkey = \'wm91p10\' AND pap_author = \'Barnes TM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two43\' WHERE joinkey = \'wm91p10\' AND pap_author = \'Barnes TM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:53:48.041703-08\' WHERE joinkey = \'wm91p47\' AND pap_author = \'Barnes TM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two43\' WHERE joinkey = \'wm91p47\' AND pap_author = \'Barnes TM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:55:40.703296-08\' WHERE joinkey = \'wm93p45\' AND pap_author = \'Barnes TM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two43\' WHERE joinkey = \'wm93p45\' AND pap_author = \'Barnes TM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:55:40.724197-08\' WHERE joinkey = \'wm95p108\' AND pap_author = \'Barnes TM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two43\' WHERE joinkey = \'wm95p108\' AND pap_author = \'Barnes TM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:55:40.742976-08\' WHERE joinkey = \'wm95p114\' AND pap_author = \'Barnes TM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two43\' WHERE joinkey = \'wm95p114\' AND pap_author = \'Barnes TM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:55:40.757561-08\' WHERE joinkey = \'wm95p115\' AND pap_author = \'Barnes TM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two43\' WHERE joinkey = \'wm95p115\' AND pap_author = \'Barnes TM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:55:40.778607-08\' WHERE joinkey = \'wm95p121\' AND pap_author = \'Barnes TM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two43\' WHERE joinkey = \'wm95p121\' AND pap_author = \'Barnes TM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:55:40.794517-08\' WHERE joinkey = \'wm95p209\' AND pap_author = \'Barnes TM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two43\' WHERE joinkey = \'wm95p209\' AND pap_author = \'Barnes TM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:55:40.813454-08\' WHERE joinkey = \'wm95p378\' AND pap_author = \'Barnes TM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two43\' WHERE joinkey = \'wm95p378\' AND pap_author = \'Barnes TM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:55:40.843456-08\' WHERE joinkey = \'wm95p8\' AND pap_author = \'Barnes TM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two43\' WHERE joinkey = \'wm95p8\' AND pap_author = \'Barnes TM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:55:40.85817-08\' WHERE joinkey = \'wm97ab349\' AND pap_author = \'Barnes TM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two43\' WHERE joinkey = \'wm97ab349\' AND pap_author = \'Barnes TM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:55:40.875277-08\' WHERE joinkey = \'wm97ab35\' AND pap_author = \'Barnes TM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two43\' WHERE joinkey = \'wm97ab35\' AND pap_author = \'Barnes TM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:57:01.613633-08\' WHERE joinkey = \'wm97ab458\' AND pap_author = \'Barnes TM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two43\' WHERE joinkey = \'wm97ab458\' AND pap_author = \'Barnes TM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:57:01.635001-08\' WHERE joinkey = \'wm97ab47\' AND pap_author = \'Barnes TM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two43\' WHERE joinkey = \'wm97ab47\' AND pap_author = \'Barnes TM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 12:57:01.658259-08\' WHERE joinkey = \'wm97ab640\' AND pap_author = \'Barnes TM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two43\' WHERE joinkey = \'wm97ab640\' AND pap_author = \'Barnes TM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 13:05:10.113603-08\' WHERE joinkey = \'cgc3680\' AND pap_author = \'Barr MM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two44\' WHERE joinkey = \'cgc3680\' AND pap_author = \'Barr MM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 13:07:30.769683-08\' WHERE joinkey = \'cgc4715\' AND pap_author = \'Barr MM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two44\' WHERE joinkey = \'cgc4715\' AND pap_author = \'Barr MM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 13:07:30.802503-08\' WHERE joinkey = \'cgc4854\' AND pap_author = \'Barr MM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two44\' WHERE joinkey = \'cgc4854\' AND pap_author = \'Barr MM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 13:09:33.5378-08\' WHERE joinkey = \'mwwm2000ab20\' AND pap_author = \'Barr MM\" Affiliation_address \"School of Pharmacy, University of Wisconsin-Madison, 425 N. Charter St., Madison, WI 53706\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two44\' WHERE joinkey = \'mwwm2000ab20\' AND pap_author = \'Barr MM\" Affiliation_address \"School of Pharmacy, University of Wisconsin-Madison, 425 N. Charter St., Madison, WI 53706\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 13:09:33.624988-08\' WHERE joinkey = \'wcwm96ab11\' AND pap_author = \'Barr MM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two44\' WHERE joinkey = \'wcwm96ab11\' AND pap_author = \'Barr MM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 13:09:33.679725-08\' WHERE joinkey = \'wcwm98ab11\' AND pap_author = \'Barr MM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two44\' WHERE joinkey = \'wcwm98ab11\' AND pap_author = \'Barr MM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 13:09:33.734109-08\' WHERE joinkey = \'wm2001p303\' AND pap_author = \'Barr MM\" Affiliation_address \"University of Wisconsin, School of Pharmacy, Madison, WI 53705\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two44\' WHERE joinkey = \'wm2001p303\' AND pap_author = \'Barr MM\" Affiliation_address \"University of Wisconsin, School of Pharmacy, Madison, WI 53705\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 13:12:25.032332-08\' WHERE joinkey = \'wm2001p63\' AND pap_author = \'Barr MM\" Affiliation_address \"Division of Pharmaceutical Sciences, School of Pharmacy, University of Wisconsin Madison, Madison, Wisconsin 53706, USA.\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two44\' WHERE joinkey = \'wm2001p63\' AND pap_author = \'Barr MM\" Affiliation_address \"Division of Pharmaceutical Sciences, School of Pharmacy, University of Wisconsin Madison, Madison, Wisconsin 53706, USA.\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 13:12:25.055737-08\' WHERE joinkey = \'wm2001p653\' AND pap_author = \'Barr MM\" Affiliation_address \"University of Wisconsin, School of Pharmacy, Madison, WI 53705\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two44\' WHERE joinkey = \'wm2001p653\' AND pap_author = \'Barr MM\" Affiliation_address \"University of Wisconsin, School of Pharmacy, Madison, WI 53705\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 13:12:25.069804-08\' WHERE joinkey = \'wm2001p655\' AND pap_author = \'Barr MM\" Affiliation_address \"School of Pharmacy, University of Wisconsin, 425 Charter Street, Madison, WI   53706\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two44\' WHERE joinkey = \'wm2001p655\' AND pap_author = \'Barr MM\" Affiliation_address \"School of Pharmacy, University of Wisconsin, 425 Charter Street, Madison, WI   53706\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 13:12:25.126808-08\' WHERE joinkey = \'wm2001p689\' AND pap_author = \'Barr MM\" Affiliation_address \"University of Wisconsin, School of Pharmacy, Madison, WI 53706\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two44\' WHERE joinkey = \'wm2001p689\' AND pap_author = \'Barr MM\" Affiliation_address \"University of Wisconsin, School of Pharmacy, Madison, WI 53706\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 13:14:44.476007-08\' WHERE joinkey = \'wm97ab36\' AND pap_author = \'Barr MM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two44\' WHERE joinkey = \'wm97ab36\' AND pap_author = \'Barr MM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 13:14:44.524646-08\' WHERE joinkey = \'wm99ab37\' AND pap_author = \'Barr MM\" Affiliation_address \"California Institute of Technology, HHMI\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two44\' WHERE joinkey = \'wm99ab37\' AND pap_author = \'Barr MM\" Affiliation_address \"California Institute of Technology, HHMI\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 13:21:09.960492-08\' WHERE joinkey = \'ecwm96ab7\' AND pap_author = \'Barrett P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two45\' WHERE joinkey = \'ecwm96ab7\' AND pap_author = \'Barrett P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 13:21:10.015126-08\' WHERE joinkey = \'wm2001p441\' AND pap_author = \'Barrett P\" Affiliation_address \"Massachusetts General Hospital, Jackson 14, 55 Fruit Street, Boston, MA 02114\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two45\' WHERE joinkey = \'wm2001p441\' AND pap_author = \'Barrett P\" Affiliation_address \"Massachusetts General Hospital, Jackson 14, 55 Fruit Street, Boston, MA 02114\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 13:21:10.049919-08\' WHERE joinkey = \'wm2001p444\' AND pap_author = \'Barrett P\" Affiliation_address \"Massachusetts General Hospital, Jackson 14, 55 Fruitstreet, Boston, MA 02114\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two45\' WHERE joinkey = \'wm2001p444\' AND pap_author = \'Barrett P\" Affiliation_address \"Massachusetts General Hospital, Jackson 14, 55 Fruitstreet, Boston, MA 02114\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 14:04:13.493491-08\' WHERE joinkey = \'cgc4633\' AND pap_author = \'Bargmann C\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two42\' WHERE joinkey = \'cgc4633\' AND pap_author = \'Bargmann C\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 14:32:27.377716-08\' WHERE joinkey = \'cgc1031\' AND pap_author = \'Barstead RJ\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two46\' WHERE joinkey = \'cgc1031\' AND pap_author = \'Barstead RJ\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 14:32:27.531965-08\' WHERE joinkey = \'cgc1140\' AND pap_author = \'Barstead RJ\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two46\' WHERE joinkey = \'cgc1140\' AND pap_author = \'Barstead RJ\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 14:32:27.546699-08\' WHERE joinkey = \'cgc1160\' AND pap_author = \'Barstead RJ\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two46\' WHERE joinkey = \'cgc1160\' AND pap_author = \'Barstead RJ\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 14:32:27.56488-08\' WHERE joinkey = \'cgc1458\' AND pap_author = \'Barstead RJ\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two46\' WHERE joinkey = \'cgc1458\' AND pap_author = \'Barstead RJ\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 14:32:27.58095-08\' WHERE joinkey = \'cgc1459\' AND pap_author = \'Barstead RJ\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two46\' WHERE joinkey = \'cgc1459\' AND pap_author = \'Barstead RJ\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 14:32:27.611656-08\' WHERE joinkey = \'cgc2431\' AND pap_author = \'Barstead RJ\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two46\' WHERE joinkey = \'cgc2431\' AND pap_author = \'Barstead RJ\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 14:32:27.626229-08\' WHERE joinkey = \'cgc2523\' AND pap_author = \'Barstead RJ\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two46\' WHERE joinkey = \'cgc2523\' AND pap_author = \'Barstead RJ\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 14:32:27.647938-08\' WHERE joinkey = \'cgc3166\' AND pap_author = \'Barstead RJ\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two46\' WHERE joinkey = \'cgc3166\' AND pap_author = \'Barstead RJ\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 14:32:27.669371-08\' WHERE joinkey = \'cgc3692\' AND pap_author = \'Barstead RJ\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two46\' WHERE joinkey = \'cgc3692\' AND pap_author = \'Barstead RJ\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 14:32:27.689421-08\' WHERE joinkey = \'cgc3808\' AND pap_author = \'Barstead RJ\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two46\' WHERE joinkey = \'cgc3808\' AND pap_author = \'Barstead RJ\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 14:38:39.699917-08\' WHERE joinkey = \'cgc4110\' AND pap_author = \'Barstead RJ\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two46\' WHERE joinkey = \'cgc4110\' AND pap_author = \'Barstead RJ\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 14:38:39.729054-08\' WHERE joinkey = \'cgc4155\' AND pap_author = \'Barstead RJ\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two46\' WHERE joinkey = \'cgc4155\' AND pap_author = \'Barstead RJ\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 14:38:39.755967-08\' WHERE joinkey = \'cgc4345\' AND pap_author = \'Barstead RJ\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two46\' WHERE joinkey = \'cgc4345\' AND pap_author = \'Barstead RJ\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 14:38:39.774527-08\' WHERE joinkey = \'cgc4372\' AND pap_author = \'Barstead RJ\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two46\' WHERE joinkey = \'cgc4372\' AND pap_author = \'Barstead RJ\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 14:38:39.802874-08\' WHERE joinkey = \'cgc4464\' AND pap_author = \'Barstead RJ\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two46\' WHERE joinkey = \'cgc4464\' AND pap_author = \'Barstead RJ\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 14:38:39.823036-08\' WHERE joinkey = \'cgc4563\' AND pap_author = \'Barstead RJ\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two46\' WHERE joinkey = \'cgc4563\' AND pap_author = \'Barstead RJ\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 14:38:39.856806-08\' WHERE joinkey = \'cgc4898\' AND pap_author = \'Barstead R\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two46\' WHERE joinkey = \'cgc4898\' AND pap_author = \'Barstead R\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 14:38:39.90555-08\' WHERE joinkey = \'cgc4900\' AND pap_author = \'Barstead R\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two46\' WHERE joinkey = \'cgc4900\' AND pap_author = \'Barstead R\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 14:38:39.932296-08\' WHERE joinkey = \'cgc5265\' AND pap_author = \'Barstead R\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two46\' WHERE joinkey = \'cgc5265\' AND pap_author = \'Barstead R\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 14:38:39.965444-08\' WHERE joinkey = \'cgc5314\' AND pap_author = \'Barstead R\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two46\' WHERE joinkey = \'cgc5314\' AND pap_author = \'Barstead R\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 14:41:02.269873-08\' WHERE joinkey = \'cgc5338\' AND pap_author = \'Barstead R\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two46\' WHERE joinkey = \'cgc5338\' AND pap_author = \'Barstead R\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 14:41:02.328855-08\' WHERE joinkey = \'cgc5350\' AND pap_author = \'Barstead R\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two46\' WHERE joinkey = \'cgc5350\' AND pap_author = \'Barstead R\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 14:41:02.355494-08\' WHERE joinkey = \'cgc893\' AND pap_author = \'Barstead RJ\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two46\' WHERE joinkey = \'cgc893\' AND pap_author = \'Barstead RJ\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 14:41:02.384317-08\' WHERE joinkey = \'ecwm2000ab130\' AND pap_author = \'Barstead RJ\" Affiliation_address \"Oklahoma Medical Research Foundation, Oklahoma City, OK\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two46\' WHERE joinkey = \'ecwm2000ab130\' AND pap_author = \'Barstead RJ\" Affiliation_address \"Oklahoma Medical Research Foundation, Oklahoma City, OK\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 14:41:02.406948-08\' WHERE joinkey = \'euwm2000ab49\' AND pap_author = \'Barstead RJ\" Affiliation_address \"Address unknown\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two46\' WHERE joinkey = \'euwm2000ab49\' AND pap_author = \'Barstead RJ\" Affiliation_address \"Address unknown\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 14:41:02.455671-08\' WHERE joinkey = \'mwwm2000ab24\' AND pap_author = \'Barstead RJ\" Affiliation_address \"Oklahoma Medical Research Foundation, Oklahoma City, OK\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two46\' WHERE joinkey = \'mwwm2000ab24\' AND pap_author = \'Barstead RJ\" Affiliation_address \"Oklahoma Medical Research Foundation, Oklahoma City, OK\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 14:41:02.477317-08\' WHERE joinkey = \'mwwm2000ab28\' AND pap_author = \'Barstead RJ\" Affiliation_address \"Oklahoma Medical Research Foundation, Oklahoma City, OK\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two46\' WHERE joinkey = \'mwwm2000ab28\' AND pap_author = \'Barstead RJ\" Affiliation_address \"Oklahoma Medical Research Foundation, Oklahoma City, OK\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 14:41:02.509063-08\' WHERE joinkey = \'mwwm2000ab59\' AND pap_author = \'Barstead RJ\" Affiliation_address \"Oklahoma Medical Research Foundation, Oklahoma City, OK 73104\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two46\' WHERE joinkey = \'mwwm2000ab59\' AND pap_author = \'Barstead RJ\" Affiliation_address \"Oklahoma Medical Research Foundation, Oklahoma City, OK 73104\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 14:41:02.552965-08\' WHERE joinkey = \'mwwm2000ab61\' AND pap_author = \'Barstead RJ\" Affiliation_address \"Department of Molecular and Cell Biology, OMRF, Oklahoma   City, Oklahoma, U.S. A.\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two46\' WHERE joinkey = \'mwwm2000ab61\' AND pap_author = \'Barstead RJ\" Affiliation_address \"Department of Molecular and Cell Biology, OMRF, Oklahoma   City, Oklahoma, U.S. A.\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 14:41:02.584581-08\' WHERE joinkey = \'mwwm96ab42\' AND pap_author = \'Barstead RJ\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two46\' WHERE joinkey = \'mwwm96ab42\' AND pap_author = \'Barstead RJ\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 14:43:10.887441-08\' WHERE joinkey = \'mwwm96ab64\' AND pap_author = \'Barstead RJ\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two46\' WHERE joinkey = \'mwwm96ab64\' AND pap_author = \'Barstead RJ\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 14:43:10.922069-08\' WHERE joinkey = \'mwwm98ab29\' AND pap_author = \'Barstead RJ\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two46\' WHERE joinkey = \'mwwm98ab29\' AND pap_author = \'Barstead RJ\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 14:43:10.944575-08\' WHERE joinkey = \'mwwm98ab60\' AND pap_author = \'Barstead RJ\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two46\' WHERE joinkey = \'mwwm98ab60\' AND pap_author = \'Barstead RJ\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 14:43:10.964221-08\' WHERE joinkey = \'wbg10.2p104\' AND pap_author = \'Barstead RJ\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two46\' WHERE joinkey = \'wbg10.2p104\' AND pap_author = \'Barstead RJ\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 14:43:10.978801-08\' WHERE joinkey = \'wbg10.3p109\' AND pap_author = \'Barstead RJ\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two46\' WHERE joinkey = \'wbg10.3p109\' AND pap_author = \'Barstead RJ\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 14:43:10.994332-08\' WHERE joinkey = \'wbg11.1p32\' AND pap_author = \'Barstead RJ\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two46\' WHERE joinkey = \'wbg11.1p32\' AND pap_author = \'Barstead RJ\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 14:43:11.008598-08\' WHERE joinkey = \'wbg11.2p35\' AND pap_author = \'Barstead RJ\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two46\' WHERE joinkey = \'wbg11.2p35\' AND pap_author = \'Barstead RJ\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 14:43:11.031739-08\' WHERE joinkey = \'wbg13.2p80\' AND pap_author = \'Barstead RJ\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two46\' WHERE joinkey = \'wbg13.2p80\' AND pap_author = \'Barstead RJ\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 14:43:11.048172-08\' WHERE joinkey = \'wbg14.5p34\' AND pap_author = \'Barstead RJ\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two46\' WHERE joinkey = \'wbg14.5p34\' AND pap_author = \'Barstead RJ\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 14:43:11.072215-08\' WHERE joinkey = \'wbg17.1p59\' AND pap_author = \'Robert Barstead\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two46\' WHERE joinkey = \'wbg17.1p59\' AND pap_author = \'Robert Barstead\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 14:46:31.338558-08\' WHERE joinkey = \'wbg9.1p24\' AND pap_author = \'Barstead RJ\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two46\' WHERE joinkey = \'wbg9.1p24\' AND pap_author = \'Barstead RJ\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 14:46:31.357249-08\' WHERE joinkey = \'wbg9.3p60\' AND pap_author = \'Barstead RJ\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two46\' WHERE joinkey = \'wbg9.3p60\' AND pap_author = \'Barstead RJ\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 14:46:31.377709-08\' WHERE joinkey = \'wcwm2000ab124\' AND pap_author = \'Barstead RJ\" Affiliation_address \"Department of Molecular and Cell Biology, OMRF, Oklahoma City, Oklahoma\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two46\' WHERE joinkey = \'wcwm2000ab124\' AND pap_author = \'Barstead RJ\" Affiliation_address \"Department of Molecular and Cell Biology, OMRF, Oklahoma City, Oklahoma\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 14:46:31.43529-08\' WHERE joinkey = \'wcwm2000ab20\' AND pap_author = \'Barstead RJ\" Affiliation_address \"Oklahoma Medical Research Foundation\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two46\' WHERE joinkey = \'wcwm2000ab20\' AND pap_author = \'Barstead RJ\" Affiliation_address \"Oklahoma Medical Research Foundation\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 14:46:31.462188-08\' WHERE joinkey = \'wcwm98ab199\' AND pap_author = \'Barstead RJ\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two46\' WHERE joinkey = \'wcwm98ab199\' AND pap_author = \'Barstead RJ\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 14:46:31.497908-08\' WHERE joinkey = \'wcwm98ab45\' AND pap_author = \'Barstead RJ\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two46\' WHERE joinkey = \'wcwm98ab45\' AND pap_author = \'Barstead RJ\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 14:46:31.51796-08\' WHERE joinkey = \'wm2001p1092\' AND pap_author = \'Barstead RJ\" Affiliation_address \"Oklahoma Medical Research Foundation\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two46\' WHERE joinkey = \'wm2001p1092\' AND pap_author = \'Barstead RJ\" Affiliation_address \"Oklahoma Medical Research Foundation\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 14:46:31.538255-08\' WHERE joinkey = \'wm2001p1095\' AND pap_author = \'Barstead RJ\" Affiliation_address \"Department of Molecular and Cell Biology, OMRF, Oklahoma City, Oklahoma, U.S.A.\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two46\' WHERE joinkey = \'wm2001p1095\' AND pap_author = \'Barstead RJ\" Affiliation_address \"Department of Molecular and Cell Biology, OMRF, Oklahoma City, Oklahoma, U.S.A.\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 14:46:31.608903-08\' WHERE joinkey = \'wm2001p14\' AND pap_author = \'Barstead RJ\" Affiliation_address \"Department of Molecular and Cell Biology, OMRF, Oklahoma City, Oklahoma, U.S.A.\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two46\' WHERE joinkey = \'wm2001p14\' AND pap_author = \'Barstead RJ\" Affiliation_address \"Department of Molecular and Cell Biology, OMRF, Oklahoma City, Oklahoma, U.S.A.\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 14:46:31.635098-08\' WHERE joinkey = \'wm2001p162\' AND pap_author = \'Barstead RJ\" Affiliation_address \"Oklahoma Medical Research Foundation, 825 NE 13th Street, Oklahoma City, OK 73104\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two46\' WHERE joinkey = \'wm2001p162\' AND pap_author = \'Barstead RJ\" Affiliation_address \"Oklahoma Medical Research Foundation, 825 NE 13th Street, Oklahoma City, OK 73104\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 14:48:53.48669-08\' WHERE joinkey = \'wm2001p204\' AND pap_author = \'Barstead RJ\" Affiliation_address \"Oklahoma Medical Research Foundation, Oklahoma City, OK 73104\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two46\' WHERE joinkey = \'wm2001p204\' AND pap_author = \'Barstead RJ\" Affiliation_address \"Oklahoma Medical Research Foundation, Oklahoma City, OK 73104\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 14:48:53.515489-08\' WHERE joinkey = \'wm2001p680\' AND pap_author = \'Barstead RJ\" Affiliation_address \"Program in Molecular and Cell Biology, Oklahoma Medical Research Foundation, Oklahoma City, OK  73104  USA.\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two46\' WHERE joinkey = \'wm2001p680\' AND pap_author = \'Barstead RJ\" Affiliation_address \"Program in Molecular and Cell Biology, Oklahoma Medical Research Foundation, Oklahoma City, OK  73104  USA.\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 14:48:53.559482-08\' WHERE joinkey = \'wm2001p682\' AND pap_author = \'Barstead RJ\" Affiliation_address \"Program in Molecular and Cell Biology, Oklahoma Medical Research Foundation, Oklahoma City, OK, 73104, U.S.A.\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two46\' WHERE joinkey = \'wm2001p682\' AND pap_author = \'Barstead RJ\" Affiliation_address \"Program in Molecular and Cell Biology, Oklahoma Medical Research Foundation, Oklahoma City, OK, 73104, U.S.A.\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 14:48:53.585839-08\' WHERE joinkey = \'wm2001p753\' AND pap_author = \'Barstead RJ\" Affiliation_address \"Oklahoma Medical Research Foundation, 825 NE 13th Street, Oklahoma City, OK  73104\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two46\' WHERE joinkey = \'wm2001p753\' AND pap_author = \'Barstead RJ\" Affiliation_address \"Oklahoma Medical Research Foundation, 825 NE 13th Street, Oklahoma City, OK  73104\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 14:48:53.646772-08\' WHERE joinkey = \'wm2001p76\' AND pap_author = \'Barstead RJ\" Affiliation_address \"Oklahoma Medical Research Foundation, Oklahoma City, OK 73104, USA.\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two46\' WHERE joinkey = \'wm2001p76\' AND pap_author = \'Barstead RJ\" Affiliation_address \"Oklahoma Medical Research Foundation, Oklahoma City, OK 73104, USA.\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 14:48:53.66942-08\' WHERE joinkey = \'wm2001p894\' AND pap_author = \'Barstead RJ\" Affiliation_address \"Oklahoma Medical Research Foundation, 825 N.E. 13th Street, Oklahoma City, OK 73104\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two46\' WHERE joinkey = \'wm2001p894\' AND pap_author = \'Barstead RJ\" Affiliation_address \"Oklahoma Medical Research Foundation, 825 N.E. 13th Street, Oklahoma City, OK 73104\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 14:48:53.754607-08\' WHERE joinkey = \'wm87p186\' AND pap_author = \'Barstead RJ\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two46\' WHERE joinkey = \'wm87p186\' AND pap_author = \'Barstead RJ\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 14:48:53.766542-08\' WHERE joinkey = \'wm89p143\' AND pap_author = \'Barstead RJ\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two46\' WHERE joinkey = \'wm89p143\' AND pap_author = \'Barstead RJ\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 14:48:53.783274-08\' WHERE joinkey = \'wm89p24\' AND pap_author = \'Barstead RJ\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two46\' WHERE joinkey = \'wm89p24\' AND pap_author = \'Barstead RJ\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 14:50:51.013035-08\' WHERE joinkey = \'wm89p35\' AND pap_author = \'Barstead RJ\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two46\' WHERE joinkey = \'wm89p35\' AND pap_author = \'Barstead RJ\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 14:50:51.066119-08\' WHERE joinkey = \'wm91p48\' AND pap_author = \'Barstead RJ\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two46\' WHERE joinkey = \'wm91p48\' AND pap_author = \'Barstead RJ\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 14:50:51.077948-08\' WHERE joinkey = \'wm93p46\' AND pap_author = \'Barstead RJ\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two46\' WHERE joinkey = \'wm93p46\' AND pap_author = \'Barstead RJ\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 14:50:51.089863-08\' WHERE joinkey = \'wm95p386\' AND pap_author = \'Barstead RJ\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two46\' WHERE joinkey = \'wm95p386\' AND pap_author = \'Barstead RJ\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 14:50:51.106949-08\' WHERE joinkey = \'wm97ab258\' AND pap_author = \'Barstead RJ\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two46\' WHERE joinkey = \'wm97ab258\' AND pap_author = \'Barstead RJ\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 14:50:51.119529-08\' WHERE joinkey = \'wm97ab429\' AND pap_author = \'Barstead RJ\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two46\' WHERE joinkey = \'wm97ab429\' AND pap_author = \'Barstead RJ\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 14:50:51.155715-08\' WHERE joinkey = \'wm97ab430\' AND pap_author = \'Barstead RJ\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two46\' WHERE joinkey = \'wm97ab430\' AND pap_author = \'Barstead RJ\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 14:50:51.173672-08\' WHERE joinkey = \'wm99ab305\' AND pap_author = \'Barstead RJ\" Affiliation_address \"Oklahoma Medical Research Foundation, Oklahoma City, OK 73104.\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two46\' WHERE joinkey = \'wm99ab305\' AND pap_author = \'Barstead RJ\" Affiliation_address \"Oklahoma Medical Research Foundation, Oklahoma City, OK 73104.\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 14:50:51.199846-08\' WHERE joinkey = \'wm99ab41\' AND pap_author = \'Barstead RJ\" Affiliation_address \"Oklahoma Medical Research Foundation, Oklahoma City, OK 73104.\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two46\' WHERE joinkey = \'wm99ab41\' AND pap_author = \'Barstead RJ\" Affiliation_address \"Oklahoma Medical Research Foundation, Oklahoma City, OK 73104.\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 14:50:51.227942-08\' WHERE joinkey = \'wm99ab468\' AND pap_author = \'Barstead RJ\" Affiliation_address \"Oklahoma Medical Research Foundation, Oklahoma City, OK.\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two46\' WHERE joinkey = \'wm99ab468\' AND pap_author = \'Barstead RJ\" Affiliation_address \"Oklahoma Medical Research Foundation, Oklahoma City, OK.\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 14:52:29.691297-08\' WHERE joinkey = \'wm99ab492\' AND pap_author = \'Barstead RJ\" Affiliation_address \"Oklahoma Medical Research Foundation, Oklahoma City, OK 73104.\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two46\' WHERE joinkey = \'wm99ab492\' AND pap_author = \'Barstead RJ\" Affiliation_address \"Oklahoma Medical Research Foundation, Oklahoma City, OK 73104.\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 14:52:29.791519-08\' WHERE joinkey = \'wm99ab610\' AND pap_author = \'Barstead RJ\" Affiliation_address \"Oklahoma Medical Research Foundation, Oklahoma City, Oklahoma\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two46\' WHERE joinkey = \'wm99ab610\' AND pap_author = \'Barstead RJ\" Affiliation_address \"Oklahoma Medical Research Foundation, Oklahoma City, Oklahoma\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 14:52:29.825539-08\' WHERE joinkey = \'wm99ab849\' AND pap_author = \'Barstead RJ\" Affiliation_address \"Oklahoma Medical Research Foundation, Oklahoma City, OK 73104.\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two46\' WHERE joinkey = \'wm99ab849\' AND pap_author = \'Barstead RJ\" Affiliation_address \"Oklahoma Medical Research Foundation, Oklahoma City, OK 73104.\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 15:04:58.620534-08\' WHERE joinkey = \'cgc2518\' AND pap_author = \'Basson M\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two47\' WHERE joinkey = \'cgc2518\' AND pap_author = \'Basson M\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 15:04:58.643931-08\' WHERE joinkey = \'cgc3421\' AND pap_author = \'Basson M\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two47\' WHERE joinkey = \'cgc3421\' AND pap_author = \'Basson M\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 15:04:58.664092-08\' WHERE joinkey = \'cgc3705\' AND pap_author = \'Basson M\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two47\' WHERE joinkey = \'cgc3705\' AND pap_author = \'Basson M\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 15:04:58.716836-08\' WHERE joinkey = \'cgc3929\' AND pap_author = \'Basson M\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two47\' WHERE joinkey = \'cgc3929\' AND pap_author = \'Basson M\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 15:04:58.747156-08\' WHERE joinkey = \'cgc4111\' AND pap_author = \'Basson M\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two47\' WHERE joinkey = \'cgc4111\' AND pap_author = \'Basson M\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 15:04:58.761765-08\' WHERE joinkey = \'cgc4161\' AND pap_author = \'Basson M\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two47\' WHERE joinkey = \'cgc4161\' AND pap_author = \'Basson M\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 15:04:58.776463-08\' WHERE joinkey = \'wbg14.4p62\' AND pap_author = \'Basson M\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two47\' WHERE joinkey = \'wbg14.4p62\' AND pap_author = \'Basson M\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 15:04:58.789388-08\' WHERE joinkey = \'wcwm98ab32\' AND pap_author = \'Basson M\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two47\' WHERE joinkey = \'wcwm98ab32\' AND pap_author = \'Basson M\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 15:04:58.819212-08\' WHERE joinkey = \'wm89p37\' AND pap_author = \'Basson M\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two47\' WHERE joinkey = \'wm89p37\' AND pap_author = \'Basson M\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 15:04:58.833459-08\' WHERE joinkey = \'wm91p49\' AND pap_author = \'Basson M\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two47\' WHERE joinkey = \'wm91p49\' AND pap_author = \'Basson M\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 15:06:25.856561-08\' WHERE joinkey = \'wm93p508\' AND pap_author = \'Basson M\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two47\' WHERE joinkey = \'wm93p508\' AND pap_author = \'Basson M\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 15:06:25.912428-08\' WHERE joinkey = \'wm95p116\' AND pap_author = \'Basson M\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two47\' WHERE joinkey = \'wm95p116\' AND pap_author = \'Basson M\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 15:06:25.932628-08\' WHERE joinkey = \'wm97ab39\' AND pap_author = \'Basson M\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two47\' WHERE joinkey = \'wm97ab39\' AND pap_author = \'Basson M\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 15:06:25.945694-08\' WHERE joinkey = \'wm97ab638\' AND pap_author = \'Basson M\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two47\' WHERE joinkey = \'wm97ab638\' AND pap_author = \'Basson M\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 15:06:25.976759-08\' WHERE joinkey = \'wm99ab820\' AND pap_author = \'Basson M\" Affiliation_address \"Axys Pharmaceuticals, NemaPharm Group, 100 Kimball Way, South San Francisco, CA 9408\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two47\' WHERE joinkey = \'wm99ab820\' AND pap_author = \'Basson M\" Affiliation_address \"Axys Pharmaceuticals, NemaPharm Group, 100 Kimball Way, South San Francisco, CA 9408\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 15:06:25.995831-08\' WHERE joinkey = \'wm99ab821\' AND pap_author = \'Basson M\" Affiliation_address \"Axys Pharmaceuticals, NemaPharm Group, 100 Kimball Way, South San Francisco, CA 9408\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two47\' WHERE joinkey = \'wm99ab821\' AND pap_author = \'Basson M\" Affiliation_address \"Axys Pharmaceuticals, NemaPharm Group, 100 Kimball Way, South San Francisco, CA 9408\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 15:13:48.093703-08\' WHERE joinkey = \'wcwm2000ab78\' AND pap_author = \'Bastiani CA\" Affiliation_address \"Division of Biology, California Institue of Technology, Pasadena, CA 91125\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two48\' WHERE joinkey = \'wcwm2000ab78\' AND pap_author = \'Bastiani CA\" Affiliation_address \"Division of Biology, California Institue of Technology, Pasadena, CA 91125\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 15:13:48.127379-08\' WHERE joinkey = \'wcwm96ab12\' AND pap_author = \'Bastiani CA\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two48\' WHERE joinkey = \'wcwm96ab12\' AND pap_author = \'Bastiani CA\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 15:13:48.149389-08\' WHERE joinkey = \'wcwm98ab13\' AND pap_author = \'Bastiani CA\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two48\' WHERE joinkey = \'wcwm98ab13\' AND pap_author = \'Bastiani CA\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 15:13:48.172533-08\' WHERE joinkey = \'wm2001p649\' AND pap_author = \'Bastiani CA\" Affiliation_address \"Howard Hughes Medical Institute (HHMI) and Division of Biology, California Institute of Technology, Pasadena, California 91125 USA\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two48\' WHERE joinkey = \'wm2001p649\' AND pap_author = \'Bastiani CA\" Affiliation_address \"Howard Hughes Medical Institute (HHMI) and Division of Biology, California Institute of Technology, Pasadena, California 91125 USA\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 15:15:55.238919-08\' WHERE joinkey = \'wm97ab40\' AND pap_author = \'Bastiani CA\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two48\' WHERE joinkey = \'wm97ab40\' AND pap_author = \'Bastiani CA\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 15:15:55.27082-08\' WHERE joinkey = \'wm99ab180\' AND pap_author = \'Bastiani CA\" Affiliation_address \"Division of Biology, California Institute of Technology, Pasadena, CA 91125 U.S.A.\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two48\' WHERE joinkey = \'wm99ab180\' AND pap_author = \'Bastiani CA\" Affiliation_address \"Division of Biology, California Institute of Technology, Pasadena, CA 91125 U.S.A.\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 15:19:15.312063-08\' WHERE joinkey = \'wm2001p11\' AND pap_author = \'Baugh LR\" Affiliation_address \"Department of Molecular and Cellular Biology, Harvard University, 16 Divinity Ave, Cambridge, MA  02138, USA\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two49\' WHERE joinkey = \'wm2001p11\' AND pap_author = \'Baugh LR\" Affiliation_address \"Department of Molecular and Cellular Biology, Harvard University, 16 Divinity Ave, Cambridge, MA  02138, USA\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 15:19:15.33496-08\' WHERE joinkey = \'wm99ab182\' AND pap_author = \'Baugh LR\" Affiliation_address \"Department of Molecular and Cellular Biology, Harvard University, Cambridge, MA 02138\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two49\' WHERE joinkey = \'wm99ab182\' AND pap_author = \'Baugh LR\" Affiliation_address \"Department of Molecular and Cellular Biology, Harvard University, Cambridge, MA 02138\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 15:35:55.719447-08\' WHERE joinkey = \'cgc2475\' AND pap_author = \'Baumeister R\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two50\' WHERE joinkey = \'cgc2475\' AND pap_author = \'Baumeister R\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 15:35:55.75198-08\' WHERE joinkey = \'cgc2934\' AND pap_author = \'Baumeister R\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two50\' WHERE joinkey = \'cgc2934\' AND pap_author = \'Baumeister R\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 15:35:55.77534-08\' WHERE joinkey = \'cgc3103\' AND pap_author = \'Baumeister R\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two50\' WHERE joinkey = \'cgc3103\' AND pap_author = \'Baumeister R\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 15:35:55.796859-08\' WHERE joinkey = \'cgc3661\' AND pap_author = \'Baumeister R\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two50\' WHERE joinkey = \'cgc3661\' AND pap_author = \'Baumeister R\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 15:35:55.809885-08\' WHERE joinkey = \'cgc4107\' AND pap_author = \'Baumeister R\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two50\' WHERE joinkey = \'cgc4107\' AND pap_author = \'Baumeister R\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 15:35:55.822803-08\' WHERE joinkey = \'cgc4163\' AND pap_author = \'Baumeister R\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two50\' WHERE joinkey = \'cgc4163\' AND pap_author = \'Baumeister R\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 15:35:55.848996-08\' WHERE joinkey = \'cgc4201\' AND pap_author = \'Baumeister R\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two50\' WHERE joinkey = \'cgc4201\' AND pap_author = \'Baumeister R\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 15:35:55.869578-08\' WHERE joinkey = \'cgc4243\' AND pap_author = \'Baumeister R\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two50\' WHERE joinkey = \'cgc4243\' AND pap_author = \'Baumeister R\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 15:35:55.887399-08\' WHERE joinkey = \'cgc4360\' AND pap_author = \'Baumeister R\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two50\' WHERE joinkey = \'cgc4360\' AND pap_author = \'Baumeister R\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 15:35:55.925754-08\' WHERE joinkey = \'cgc4487\' AND pap_author = \'Baumeister R\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two50\' WHERE joinkey = \'cgc4487\' AND pap_author = \'Baumeister R\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 15:41:49.131176-08\' WHERE joinkey = \'cgc5179\' AND pap_author = \'Baumeister R\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two50\' WHERE joinkey = \'cgc5179\' AND pap_author = \'Baumeister R\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 15:41:49.161459-08\' WHERE joinkey = \'euwm2000ab128\' AND pap_author = \'Baumeister R\" Affiliation_address \"Address unknown\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two50\' WHERE joinkey = \'euwm2000ab128\' AND pap_author = \'Baumeister R\" Affiliation_address \"Address unknown\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 15:41:49.183853-08\' WHERE joinkey = \'euwm2000ab22\' AND pap_author = \'Baumeister R\" Affiliation_address \"Address unknown\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two50\' WHERE joinkey = \'euwm2000ab22\' AND pap_author = \'Baumeister R\" Affiliation_address \"Address unknown\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 15:41:49.218249-08\' WHERE joinkey = \'euwm2000ab37\' AND pap_author = \'Baumeister R\" Affiliation_address \"Gene   Center, Ludwig-Maximilians-Universitt, Feodor-Lynen-Str. 25, D-817 Munich,   Germany\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two50\' WHERE joinkey = \'euwm2000ab37\' AND pap_author = \'Baumeister R\" Affiliation_address \"Gene   Center, Ludwig-Maximilians-Universitt, Feodor-Lynen-Str. 25, D-817 Munich,   Germany\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 15:41:49.229137-08\' WHERE joinkey = \'euwm98ab109\' AND pap_author = \'Baumeister R\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two50\' WHERE joinkey = \'euwm98ab109\' AND pap_author = \'Baumeister R\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 15:41:49.246127-08\' WHERE joinkey = \'euwm98ab31\' AND pap_author = \'Baumeister R\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two50\' WHERE joinkey = \'euwm98ab31\' AND pap_author = \'Baumeister R\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 15:41:49.264112-08\' WHERE joinkey = \'euwm98ab88\' AND pap_author = \'Baumeister R\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two50\' WHERE joinkey = \'euwm98ab88\' AND pap_author = \'Baumeister R\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 15:41:49.279802-08\' WHERE joinkey = \'wbg15.2p24\' AND pap_author = \'Baumeister R\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two50\' WHERE joinkey = \'wbg15.2p24\' AND pap_author = \'Baumeister R\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 15:41:49.295895-08\' WHERE joinkey = \'wm2001p1086\' AND pap_author = \'Baumeister R\" Affiliation_address \"Genzentrum, University of Munich, Feodor-Lynen Str. 25, 81377 Munich\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two50\' WHERE joinkey = \'wm2001p1086\' AND pap_author = \'Baumeister R\" Affiliation_address \"Genzentrum, University of Munich, Feodor-Lynen Str. 25, 81377 Munich\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 15:41:49.319959-08\' WHERE joinkey = \'wm2001p271\' AND pap_author = \'Baumeister R\" Affiliation_address \"Genzentrum/LMU, Feodor-Lynen-Strasse 25, D-81377 Munich, Germany\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two50\' WHERE joinkey = \'wm2001p271\' AND pap_author = \'Baumeister R\" Affiliation_address \"Genzentrum/LMU, Feodor-Lynen-Strasse 25, D-81377 Munich, Germany\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 15:44:07.2423-08\' WHERE joinkey = \'wm2001p274\' AND pap_author = \'Baumeister R\" Affiliation_address \"Genzentrum, Ludwig-Maximilians University,Feodor-Lynen Str. 25, 81377 Munich, Germany\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two50\' WHERE joinkey = \'wm2001p274\' AND pap_author = \'Baumeister R\" Affiliation_address \"Genzentrum, Ludwig-Maximilians University,Feodor-Lynen Str. 25, 81377 Munich, Germany\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 15:44:07.313684-08\' WHERE joinkey = \'wm2001p860\' AND pap_author = \'Baumeister R\" Affiliation_address \"Genecenter, LMU Munich, 81377 Grohadern-Munich\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two50\' WHERE joinkey = \'wm2001p860\' AND pap_author = \'Baumeister R\" Affiliation_address \"Genecenter, LMU Munich, 81377 Grohadern-Munich\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 15:44:07.346569-08\' WHERE joinkey = \'wm2001p879\' AND pap_author = \'Baumeister R\" Affiliation_address \"Genzentrum, Ludwig-Maximilians-University, Munich, Germany\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two50\' WHERE joinkey = \'wm2001p879\' AND pap_author = \'Baumeister R\" Affiliation_address \"Genzentrum, Ludwig-Maximilians-University, Munich, Germany\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 15:44:07.377774-08\' WHERE joinkey = \'wm93p47\' AND pap_author = \'Baumeister R\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two50\' WHERE joinkey = \'wm93p47\' AND pap_author = \'Baumeister R\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 15:44:07.392494-08\' WHERE joinkey = \'wm95p10\' AND pap_author = \'Baumeister R\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two50\' WHERE joinkey = \'wm95p10\' AND pap_author = \'Baumeister R\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 15:44:07.406352-08\' WHERE joinkey = \'wm95p119\' AND pap_author = \'Baumeister R\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two50\' WHERE joinkey = \'wm95p119\' AND pap_author = \'Baumeister R\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 15:44:07.418872-08\' WHERE joinkey = \'wm95p501\' AND pap_author = \'Baumeister R\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two50\' WHERE joinkey = \'wm95p501\' AND pap_author = \'Baumeister R\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 15:44:07.434993-08\' WHERE joinkey = \'wm97ab44\' AND pap_author = \'Baumeister R\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two50\' WHERE joinkey = \'wm97ab44\' AND pap_author = \'Baumeister R\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 15:44:07.514645-08\' WHERE joinkey = \'wm99ab5\' AND pap_author = \'Baumeister R\" Affiliation_address \"LMB/Genzentrum, Munich, Germany.\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two50\' WHERE joinkey = \'wm99ab5\' AND pap_author = \'Baumeister R\" Affiliation_address \"LMB/Genzentrum, Munich, Germany.\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 15:44:07.536269-08\' WHERE joinkey = \'wm99ab715\' AND pap_author = \'Baumeister R\" Affiliation_address \"Genzentrum, Feodor-Lynen-Str. 25, 81377 Munich, Germany\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two50\' WHERE joinkey = \'wm99ab715\' AND pap_author = \'Baumeister R\" Affiliation_address \"Genzentrum, Feodor-Lynen-Str. 25, 81377 Munich, Germany\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-26 15:44:50.090825-08\' WHERE joinkey = \'wm99ab914\' AND pap_author = \'Baumeister R\" Affiliation_address \"Genzentrum/LMU, Feodor-Lynen-Str. 25, 81377 Mnchen, Germany\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two50\' WHERE joinkey = \'wm99ab914\' AND pap_author = \'Baumeister R\" Affiliation_address \"Genzentrum/LMU, Feodor-Lynen-Str. 25, 81377 Mnchen, Germany\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-27 11:54:14.598167-08\' WHERE joinkey = \'wm99ab139\' AND pap_author = \'Adachi R\" Affiliation_address \"Department of Biology, Faculty of Science, Okayama University, Okayama 700-8530, JAPAN\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two5\' WHERE joinkey = \'wm99ab139\' AND pap_author = \'Adachi R\" Affiliation_address \"Department of Biology, Faculty of Science, Okayama University, Okayama 700-8530, JAPAN\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 09:58:53.203419-08\' WHERE joinkey = \'cgc2294\' AND pap_author = \'Baylis HA\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two51\' WHERE joinkey = \'cgc2294\' AND pap_author = \'Baylis HA\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 09:58:53.443681-08\' WHERE joinkey = \'cgc2641\' AND pap_author = \'Baylis HA\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two51\' WHERE joinkey = \'cgc2641\' AND pap_author = \'Baylis HA\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 09:58:53.489402-08\' WHERE joinkey = \'cgc2724\' AND pap_author = \'Baylis HA\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two51\' WHERE joinkey = \'cgc2724\' AND pap_author = \'Baylis HA\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 09:58:53.511571-08\' WHERE joinkey = \'cgc3080\' AND pap_author = \'Baylis HA\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two51\' WHERE joinkey = \'cgc3080\' AND pap_author = \'Baylis HA\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 09:58:53.530058-08\' WHERE joinkey = \'cgc3425\' AND pap_author = \'Baylis HA\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two51\' WHERE joinkey = \'cgc3425\' AND pap_author = \'Baylis HA\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 09:58:53.546591-08\' WHERE joinkey = \'cgc3775\' AND pap_author = \'Baylis HA\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two51\' WHERE joinkey = \'cgc3775\' AND pap_author = \'Baylis HA\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 09:58:53.575767-08\' WHERE joinkey = \'cgc3819\' AND pap_author = \'Baylis HA\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two51\' WHERE joinkey = \'cgc3819\' AND pap_author = \'Baylis HA\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 09:58:53.587221-08\' WHERE joinkey = \'cgc4568\' AND pap_author = \'Baylis HA\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two51\' WHERE joinkey = \'cgc4568\' AND pap_author = \'Baylis HA\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 09:58:53.606759-08\' WHERE joinkey = \'cgc5235\' AND pap_author = \'Baylis HA\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two51\' WHERE joinkey = \'cgc5235\' AND pap_author = \'Baylis HA\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 09:58:53.625061-08\' WHERE joinkey = \'cgc5299\' AND pap_author = \'Baylis HA\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two51\' WHERE joinkey = \'cgc5299\' AND pap_author = \'Baylis HA\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 10:00:54.897193-08\' WHERE joinkey = \'euwm2000ab142\' AND pap_author = \'Baylis HA\" Affiliation_address \"Department of Zoology, , University of   Cambridge, Downing Street, Cambridge, CB2 3EJ, UK\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two51\' WHERE joinkey = \'euwm2000ab142\' AND pap_author = \'Baylis HA\" Affiliation_address \"Department of Zoology, , University of   Cambridge, Downing Street, Cambridge, CB2 3EJ, UK\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 10:00:54.942008-08\' WHERE joinkey = \'euwm2000ab18\' AND pap_author = \'Baylis HA\" Affiliation_address \"Department of Zoology, University of Cambridge,   Downing Street, CB2 3EJ, UK\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two51\' WHERE joinkey = \'euwm2000ab18\' AND pap_author = \'Baylis HA\" Affiliation_address \"Department of Zoology, University of Cambridge,   Downing Street, CB2 3EJ, UK\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 10:00:54.988669-08\' WHERE joinkey = \'euwm2000ab89\' AND pap_author = \'Baylis HA\" Affiliation_address \"Department Zoology, Uni of Cambridge,   Downing Street, Cambridge, CB2 3EJ\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two51\' WHERE joinkey = \'euwm2000ab89\' AND pap_author = \'Baylis HA\" Affiliation_address \"Department Zoology, Uni of Cambridge,   Downing Street, Cambridge, CB2 3EJ\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 10:00:55.008964-08\' WHERE joinkey = \'euwm2000ab92\' AND pap_author = \'Baylis HA\" Affiliation_address \"Department of   Zoology, Downing Street, Cambridge, CB2 3EJ, UK\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two51\' WHERE joinkey = \'euwm2000ab92\' AND pap_author = \'Baylis HA\" Affiliation_address \"Department of   Zoology, Downing Street, Cambridge, CB2 3EJ, UK\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 10:00:55.023072-08\' WHERE joinkey = \'euwm2000ab99\' AND pap_author = \'Baylis HA\" Affiliation_address \"Address unknown\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two51\' WHERE joinkey = \'euwm2000ab99\' AND pap_author = \'Baylis HA\" Affiliation_address \"Address unknown\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 10:00:55.039597-08\' WHERE joinkey = \'euwm98ab44\' AND pap_author = \'Baylis HA\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two51\' WHERE joinkey = \'euwm98ab44\' AND pap_author = \'Baylis HA\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 10:00:55.061575-08\' WHERE joinkey = \'euwm98ab8\' AND pap_author = \'Baylis HA\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two51\' WHERE joinkey = \'euwm98ab8\' AND pap_author = \'Baylis HA\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 10:00:55.107912-08\' WHERE joinkey = \'euwm98ab94\' AND pap_author = \'Baylis HA\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two51\' WHERE joinkey = \'euwm98ab94\' AND pap_author = \'Baylis HA\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 10:00:55.121967-08\' WHERE joinkey = \'wbg13.4p68\' AND pap_author = \'Baylis HA\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two51\' WHERE joinkey = \'wbg13.4p68\' AND pap_author = \'Baylis HA\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 10:00:55.136545-08\' WHERE joinkey = \'wbg13.4p78\' AND pap_author = \'Baylis HA\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two51\' WHERE joinkey = \'wbg13.4p78\' AND pap_author = \'Baylis HA\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 10:02:45.757937-08\' WHERE joinkey = \'wbg14.3p42\' AND pap_author = \'Baylis HA\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two51\' WHERE joinkey = \'wbg14.3p42\' AND pap_author = \'Baylis HA\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 10:02:45.779212-08\' WHERE joinkey = \'wbg14.3p43\' AND pap_author = \'Baylis HA\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two51\' WHERE joinkey = \'wbg14.3p43\' AND pap_author = \'Baylis HA\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 10:02:45.796826-08\' WHERE joinkey = \'wbg14.3p44\' AND pap_author = \'Baylis HA\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two51\' WHERE joinkey = \'wbg14.3p44\' AND pap_author = \'Baylis HA\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 10:02:45.813525-08\' WHERE joinkey = \'wbg14.3p45\' AND pap_author = \'Baylis HA\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two51\' WHERE joinkey = \'wbg14.3p45\' AND pap_author = \'Baylis HA\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 10:02:45.826789-08\' WHERE joinkey = \'wm2001p1022\' AND pap_author = \'Baylis HA\" Affiliation_address \"Department of Zoology, Downing Street, Cambridge, CE2 3EJ, UK\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two51\' WHERE joinkey = \'wm2001p1022\' AND pap_author = \'Baylis HA\" Affiliation_address \"Department of Zoology, Downing Street, Cambridge, CE2 3EJ, UK\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 10:02:45.853211-08\' WHERE joinkey = \'wm2001p407\' AND pap_author = \'Baylis HA\" Affiliation_address \"University of Cambridge, Department of Zoology, Downing Street, Cambridge, CB2 3EJ, UK.\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two51\' WHERE joinkey = \'wm2001p407\' AND pap_author = \'Baylis HA\" Affiliation_address \"University of Cambridge, Department of Zoology, Downing Street, Cambridge, CB2 3EJ, UK.\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 10:02:45.874176-08\' WHERE joinkey = \'wm2001p693\' AND pap_author = \'Baylis HA\" Affiliation_address \"University of Cambridge, Department of Zoology, Downing Street, Cambridge, CB2 3EJ.\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two51\' WHERE joinkey = \'wm2001p693\' AND pap_author = \'Baylis HA\" Affiliation_address \"University of Cambridge, Department of Zoology, Downing Street, Cambridge, CB2 3EJ.\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 10:02:45.909558-08\' WHERE joinkey = \'wm2001p694\' AND pap_author = \'Baylis HA\" Affiliation_address \"Department of Zoology, University of Cambridge, UK\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two51\' WHERE joinkey = \'wm2001p694\' AND pap_author = \'Baylis HA\" Affiliation_address \"Department of Zoology, University of Cambridge, UK\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 10:02:45.923481-08\' WHERE joinkey = \'wm97ab416\' AND pap_author = \'Baylis HA\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two51\' WHERE joinkey = \'wm97ab416\' AND pap_author = \'Baylis HA\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 10:02:45.943402-08\' WHERE joinkey = \'wm97ab45\' AND pap_author = \'Baylis HA\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two51\' WHERE joinkey = \'wm97ab45\' AND pap_author = \'Baylis HA\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 10:04:40.722878-08\' WHERE joinkey = \'wm99ab248\' AND pap_author = \'Baylis HA\" Affiliation_address \"Laboratory of Molecular Signalling, Department of Zoology, University of Cambridge, Cambridge CB2 3EJ, UK\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two51\' WHERE joinkey = \'wm99ab248\' AND pap_author = \'Baylis HA\" Affiliation_address \"Laboratory of Molecular Signalling, Department of Zoology, University of Cambridge, Cambridge CB2 3EJ, UK\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 10:04:40.759223-08\' WHERE joinkey = \'wm99ab377\' AND pap_author = \'Baylis HA\" Affiliation_address \"Laboratory of Molecular Signalling, Department of Zoology, Downing Street, Cambridge, CB2 3EJ, UK.\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two51\' WHERE joinkey = \'wm99ab377\' AND pap_author = \'Baylis HA\" Affiliation_address \"Laboratory of Molecular Signalling, Department of Zoology, Downing Street, Cambridge, CB2 3EJ, UK.\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 10:04:40.778577-08\' WHERE joinkey = \'wm99ab585\' AND pap_author = \'Baylis HA\" Affiliation_address \"Department of Zoology, University of Cambridge, UK.\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two51\' WHERE joinkey = \'wm99ab585\' AND pap_author = \'Baylis HA\" Affiliation_address \"Department of Zoology, University of Cambridge, UK.\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 10:04:40.803908-08\' WHERE joinkey = \'wm99ab696\' AND pap_author = \'Baylis HA\" Affiliation_address \"Department of Zoology, University of Cambridge, Downing Street, Cambridge, CB2 3EJ, UK\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two51\' WHERE joinkey = \'wm99ab696\' AND pap_author = \'Baylis HA\" Affiliation_address \"Department of Zoology, University of Cambridge, Downing Street, Cambridge, CB2 3EJ, UK\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 10:04:40.829256-08\' WHERE joinkey = \'wm99ab744\' AND pap_author = \'Baylis HA\" Affiliation_address \"The Babraham Institute, Laboratory of Molecular Signalling, Department of Zoology, University of Cambridge, UK.\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two51\' WHERE joinkey = \'wm99ab744\' AND pap_author = \'Baylis HA\" Affiliation_address \"The Babraham Institute, Laboratory of Molecular Signalling, Department of Zoology, University of Cambridge, UK.\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 10:04:40.85845-08\' WHERE joinkey = \'wm99ab882\' AND pap_author = \'Baylis HA\" Affiliation_address \"Department of Zoology, University of Cambridge, Downing Street, Cambridge, CB2 3EJ, UK\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two51\' WHERE joinkey = \'wm99ab882\' AND pap_author = \'Baylis HA\" Affiliation_address \"Department of Zoology, University of Cambridge, Downing Street, Cambridge, CB2 3EJ, UK\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 10:23:01.294041-08\' WHERE joinkey = \'cgc1088\' AND pap_author = \'Bazzicalupo P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two52\' WHERE joinkey = \'cgc1088\' AND pap_author = \'Bazzicalupo P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 10:23:01.316882-08\' WHERE joinkey = \'cgc1456\' AND pap_author = \'Bazzicalupo P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two52\' WHERE joinkey = \'cgc1456\' AND pap_author = \'Bazzicalupo P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 10:23:01.331704-08\' WHERE joinkey = \'cgc1986\' AND pap_author = \'Bazzicalupo P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two52\' WHERE joinkey = \'cgc1986\' AND pap_author = \'Bazzicalupo P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 10:23:01.349035-08\' WHERE joinkey = \'cgc2005\' AND pap_author = \'Bazzicalupo P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two52\' WHERE joinkey = \'cgc2005\' AND pap_author = \'Bazzicalupo P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 10:23:01.379647-08\' WHERE joinkey = \'cgc2017\' AND pap_author = \'Bazzicalupo P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two52\' WHERE joinkey = \'cgc2017\' AND pap_author = \'Bazzicalupo P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 10:23:01.40614-08\' WHERE joinkey = \'cgc2032\' AND pap_author = \'Bazzicalupo P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two52\' WHERE joinkey = \'cgc2032\' AND pap_author = \'Bazzicalupo P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 10:23:01.418817-08\' WHERE joinkey = \'cgc2135\' AND pap_author = \'Bazzicalupo P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two52\' WHERE joinkey = \'cgc2135\' AND pap_author = \'Bazzicalupo P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 10:23:01.43006-08\' WHERE joinkey = \'cgc2218\' AND pap_author = \'Bazzicalupo P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two52\' WHERE joinkey = \'cgc2218\' AND pap_author = \'Bazzicalupo P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 10:23:01.460578-08\' WHERE joinkey = \'cgc2705\' AND pap_author = \'Bazzicalupo P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two52\' WHERE joinkey = \'cgc2705\' AND pap_author = \'Bazzicalupo P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 10:23:01.473646-08\' WHERE joinkey = \'cgc3242\' AND pap_author = \'Bazzicalupo P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two52\' WHERE joinkey = \'cgc3242\' AND pap_author = \'Bazzicalupo P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 10:25:18.806309-08\' WHERE joinkey = \'cgc450\' AND pap_author = \'Bazzicalupo P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two52\' WHERE joinkey = \'cgc450\' AND pap_author = \'Bazzicalupo P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 10:25:18.832785-08\' WHERE joinkey = \'cgc4881\' AND pap_author = \'Bazzicalupo P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two52\' WHERE joinkey = \'cgc4881\' AND pap_author = \'Bazzicalupo P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 10:25:18.860393-08\' WHERE joinkey = \'cgc5134\' AND pap_author = \'Bazzicalupo P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two52\' WHERE joinkey = \'cgc5134\' AND pap_author = \'Bazzicalupo P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 10:25:18.8738-08\' WHERE joinkey = \'cgc5138\' AND pap_author = \'Bazzicalupo P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two52\' WHERE joinkey = \'cgc5138\' AND pap_author = \'Bazzicalupo P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 10:25:18.898523-08\' WHERE joinkey = \'cgc5169\' AND pap_author = \'Bazzicalupo P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two52\' WHERE joinkey = \'cgc5169\' AND pap_author = \'Bazzicalupo P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 10:25:18.9419-08\' WHERE joinkey = \'cgc5242\' AND pap_author = \'Bazzicalupo P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two52\' WHERE joinkey = \'cgc5242\' AND pap_author = \'Bazzicalupo P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 10:25:18.954856-08\' WHERE joinkey = \'cgc626\' AND pap_author = \'Bazzicalupo P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two52\' WHERE joinkey = \'cgc626\' AND pap_author = \'Bazzicalupo P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 10:25:18.967592-08\' WHERE joinkey = \'cgc862\' AND pap_author = \'Bazzicalupo P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two52\' WHERE joinkey = \'cgc862\' AND pap_author = \'Bazzicalupo P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 10:25:18.987063-08\' WHERE joinkey = \'euwm2000ab124\' AND pap_author = \'Bazzicalupo P\" Affiliation_address \"IIGB - CNR, - 10,   Via Marconi - 80125 Naples, Italy\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two52\' WHERE joinkey = \'euwm2000ab124\' AND pap_author = \'Bazzicalupo P\" Affiliation_address \"IIGB - CNR, - 10,   Via Marconi - 80125 Naples, Italy\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 10:25:19.023024-08\' WHERE joinkey = \'euwm2000ab41\' AND pap_author = \'Bazzicalupo P\" Affiliation_address \"International   Institute of Genetics and Biophysics, Via G. Marconi 10, 80125, Napoli,   Italy. (2) Telethon Institute of Genetics and Medicine, TIGEM, via Olgettina   58, 20132, Milano, Italy\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two52\' WHERE joinkey = \'euwm2000ab41\' AND pap_author = \'Bazzicalupo P\" Affiliation_address \"International   Institute of Genetics and Biophysics, Via G. Marconi 10, 80125, Napoli,   Italy. (2) Telethon Institute of Genetics and Medicine, TIGEM, via Olgettina   58, 20132, Milano, Italy\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 10:27:33.933377-08\' WHERE joinkey = \'euwm2000ab42\' AND pap_author = \'Bazzicalupo P\" Affiliation_address \"International   Institute of Genetics and Biophysics, C.N.R. Naples, Italy\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two52\' WHERE joinkey = \'euwm2000ab42\' AND pap_author = \'Bazzicalupo P\" Affiliation_address \"International   Institute of Genetics and Biophysics, C.N.R. Naples, Italy\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 10:27:33.975637-08\' WHERE joinkey = \'euwm2000ab56\' AND pap_author = \'Bazzicalupo P\" Affiliation_address \"International   Institute of Genetics and Biophysics, C.N.R. Naples, Italy\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two52\' WHERE joinkey = \'euwm2000ab56\' AND pap_author = \'Bazzicalupo P\" Affiliation_address \"International   Institute of Genetics and Biophysics, C.N.R. Naples, Italy\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 10:27:33.993404-08\' WHERE joinkey = \'euwm2000ab67\' AND pap_author = \'Bazzicalupo P\" Affiliation_address \"Address unknown\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two52\' WHERE joinkey = \'euwm2000ab67\' AND pap_author = \'Bazzicalupo P\" Affiliation_address \"Address unknown\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 10:27:34.009911-08\' WHERE joinkey = \'euwm98ab29\' AND pap_author = \'Bazzicalupo P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two52\' WHERE joinkey = \'euwm98ab29\' AND pap_author = \'Bazzicalupo P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 10:27:34.029697-08\' WHERE joinkey = \'euwm98ab45\' AND pap_author = \'Bazzicalupo P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two52\' WHERE joinkey = \'euwm98ab45\' AND pap_author = \'Bazzicalupo P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 10:27:34.055156-08\' WHERE joinkey = \'euwm98ab92\' AND pap_author = \'Bazzicalupo P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two52\' WHERE joinkey = \'euwm98ab92\' AND pap_author = \'Bazzicalupo P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 10:27:34.074497-08\' WHERE joinkey = \'med94373771\' AND pap_author = \'Bazzicalupo P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two52\' WHERE joinkey = \'med94373771\' AND pap_author = \'Bazzicalupo P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 10:27:34.091801-08\' WHERE joinkey = \'med95021520\' AND pap_author = \'Bazzicalupo P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two52\' WHERE joinkey = \'med95021520\' AND pap_author = \'Bazzicalupo P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 10:27:34.111257-08\' WHERE joinkey = \'wbg14.4p40\' AND pap_author = \'Bazzicalupo P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two52\' WHERE joinkey = \'wbg14.4p40\' AND pap_author = \'Bazzicalupo P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 10:27:34.142738-08\' WHERE joinkey = \'wbg16.2p36\' AND pap_author = \'Bazzicalupo P\" Affiliation_address \"International Institute of Genetics and Biophysics, Naples, ITALY\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two52\' WHERE joinkey = \'wbg16.2p36\' AND pap_author = \'Bazzicalupo P\" Affiliation_address \"International Institute of Genetics and Biophysics, Naples, ITALY\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 10:30:29.627958-08\' WHERE joinkey = \'wbg16.2p38\' AND pap_author = \'Bazzicalupo P\" Affiliation_address \"International Institute of genetics and Biophysics -CNR - 10, Via Marconi 80125 Naples Italy\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two52\' WHERE joinkey = \'wbg16.2p38\' AND pap_author = \'Bazzicalupo P\" Affiliation_address \"International Institute of genetics and Biophysics -CNR - 10, Via Marconi 80125 Naples Italy\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 10:30:29.661324-08\' WHERE joinkey = \'wbg16.5p43\' AND pap_author = \'Paolo Bazzicalupo\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two52\' WHERE joinkey = \'wbg16.5p43\' AND pap_author = \'Paolo Bazzicalupo\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 10:30:29.68115-08\' WHERE joinkey = \'wbg17.1p43\' AND pap_author = \'Paolo Bazzicalupo\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two52\' WHERE joinkey = \'wbg17.1p43\' AND pap_author = \'Paolo Bazzicalupo\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 10:30:29.69849-08\' WHERE joinkey = \'wbg3.2p20\' AND pap_author = \'Bazzicalupo P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two52\' WHERE joinkey = \'wbg3.2p20\' AND pap_author = \'Bazzicalupo P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 10:30:29.714426-08\' WHERE joinkey = \'wbg5.1p29\' AND pap_author = \'Bazzicalupo P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two52\' WHERE joinkey = \'wbg5.1p29\' AND pap_author = \'Bazzicalupo P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 10:30:29.732338-08\' WHERE joinkey = \'wbg5.1p36\' AND pap_author = \'Bazzicalupo P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two52\' WHERE joinkey = \'wbg5.1p36\' AND pap_author = \'Bazzicalupo P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 10:30:29.74382-08\' WHERE joinkey = \'wbg9.2p32\' AND pap_author = \'Bazzicalupo P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two52\' WHERE joinkey = \'wbg9.2p32\' AND pap_author = \'Bazzicalupo P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 10:30:29.784113-08\' WHERE joinkey = \'wm2001p167\' AND pap_author = \'Bazzicalupo P\" Affiliation_address \"International Institute of Genetics and Biophysics (IIGB), CNR, Naples, Italy\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two52\' WHERE joinkey = \'wm2001p167\' AND pap_author = \'Bazzicalupo P\" Affiliation_address \"International Institute of Genetics and Biophysics (IIGB), CNR, Naples, Italy\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 10:30:29.840151-08\' WHERE joinkey = \'wm2001p206\' AND pap_author = \'Bazzicalupo P\" Affiliation_address \"International Institute of Genetics and Biophysics, C.N.R. Naples, Italy\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two52\' WHERE joinkey = \'wm2001p206\' AND pap_author = \'Bazzicalupo P\" Affiliation_address \"International Institute of Genetics and Biophysics, C.N.R. Naples, Italy\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 10:30:29.859081-08\' WHERE joinkey = \'wm2001p373\' AND pap_author = \'Bazzicalupo P\" Affiliation_address \"International Institute of Genetics and Biophysics, C.N.R., Naples, Italy\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two52\' WHERE joinkey = \'wm2001p373\' AND pap_author = \'Bazzicalupo P\" Affiliation_address \"International Institute of Genetics and Biophysics, C.N.R., Naples, Italy\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 10:33:39.250331-08\' WHERE joinkey = \'wm2001p476\' AND pap_author = \'Bazzicalupo P\" Affiliation_address \"International Institute of Genetics and Biophysics -CNR- 10, Via Marconi 80125 Naples, Italy\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two52\' WHERE joinkey = \'wm2001p476\' AND pap_author = \'Bazzicalupo P\" Affiliation_address \"International Institute of Genetics and Biophysics -CNR- 10, Via Marconi 80125 Naples, Italy\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 10:33:39.278434-08\' WHERE joinkey = \'wm2001p65\' AND pap_author = \'Bazzicalupo P\" Affiliation_address \"International Institute of Genetics and Biophysics -CNR- 10, Via Marconi 80125 Naples, Italy\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two52\' WHERE joinkey = \'wm2001p65\' AND pap_author = \'Bazzicalupo P\" Affiliation_address \"International Institute of Genetics and Biophysics -CNR- 10, Via Marconi 80125 Naples, Italy\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 10:33:39.305168-08\' WHERE joinkey = \'wm2001p711\' AND pap_author = \'Bazzicalupo P\" Affiliation_address \"International Institute of Genetics and Biophysics, Naples, Italy\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two52\' WHERE joinkey = \'wm2001p711\' AND pap_author = \'Bazzicalupo P\" Affiliation_address \"International Institute of Genetics and Biophysics, Naples, Italy\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 10:33:39.329768-08\' WHERE joinkey = \'wm2001p89\' AND pap_author = \'Bazzicalupo P\" Affiliation_address \"International Institute of Genetics and Biophysics,  C.N.R. Naples, Italy\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two52\' WHERE joinkey = \'wm2001p89\' AND pap_author = \'Bazzicalupo P\" Affiliation_address \"International Institute of Genetics and Biophysics,  C.N.R. Naples, Italy\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 10:33:39.355057-08\' WHERE joinkey = \'wm2001p945\' AND pap_author = \'Bazzicalupo P\" Affiliation_address \"International Institute of Genetics and Biophysics, C.N.R. Naples, Italy.\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two52\' WHERE joinkey = \'wm2001p945\' AND pap_author = \'Bazzicalupo P\" Affiliation_address \"International Institute of Genetics and Biophysics, C.N.R. Naples, Italy.\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 10:33:39.381457-08\' WHERE joinkey = \'wm79p4\' AND pap_author = \'Bazzicalupo P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two52\' WHERE joinkey = \'wm79p4\' AND pap_author = \'Bazzicalupo P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 10:33:39.396438-08\' WHERE joinkey = \'wm81p71\' AND pap_author = \'Bazzicalupo P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two52\' WHERE joinkey = \'wm81p71\' AND pap_author = \'Bazzicalupo P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 10:33:39.420297-08\' WHERE joinkey = \'wm87p102\' AND pap_author = \'Bazzicalupo P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two52\' WHERE joinkey = \'wm87p102\' AND pap_author = \'Bazzicalupo P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 10:33:39.431888-08\' WHERE joinkey = \'wm87p45\' AND pap_author = \'Bazzicalupo P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two52\' WHERE joinkey = \'wm87p45\' AND pap_author = \'Bazzicalupo P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 10:33:39.444926-08\' WHERE joinkey = \'wm89p226\' AND pap_author = \'Bazzicalupo P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two52\' WHERE joinkey = \'wm89p226\' AND pap_author = \'Bazzicalupo P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 10:36:34.919752-08\' WHERE joinkey = \'wm91p287\' AND pap_author = \'Bazzicalupo P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two52\' WHERE joinkey = \'wm91p287\' AND pap_author = \'Bazzicalupo P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 10:36:34.942494-08\' WHERE joinkey = \'wm93p272\' AND pap_author = \'Bazzicalupo P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two52\' WHERE joinkey = \'wm93p272\' AND pap_author = \'Bazzicalupo P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 10:36:34.956399-08\' WHERE joinkey = \'wm95p335\' AND pap_author = \'Bazzicalupo P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two52\' WHERE joinkey = \'wm95p335\' AND pap_author = \'Bazzicalupo P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 10:36:34.969356-08\' WHERE joinkey = \'wm97ab237\' AND pap_author = \'Bazzicalupo P\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two52\' WHERE joinkey = \'wm97ab237\' AND pap_author = \'Bazzicalupo P\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 10:36:34.998168-08\' WHERE joinkey = \'wm99ab183\' AND pap_author = \'Bazzicalupo P\" Affiliation_address \"International Institute of Genetics and Biophysics, Via G. Marconi 10, 80125, Napoli, Italy.\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two52\' WHERE joinkey = \'wm99ab183\' AND pap_author = \'Bazzicalupo P\" Affiliation_address \"International Institute of Genetics and Biophysics, Via G. Marconi 10, 80125, Napoli, Italy.\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 10:36:35.013174-08\' WHERE joinkey = \'wm99ab392\' AND pap_author = \'Bazzicalupo P\" Affiliation_address \"International Institute of Genetics and Biophysics, Naples, Italy.\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two52\' WHERE joinkey = \'wm99ab392\' AND pap_author = \'Bazzicalupo P\" Affiliation_address \"International Institute of Genetics and Biophysics, Naples, Italy.\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 10:36:35.026597-08\' WHERE joinkey = \'wm99ab709\' AND pap_author = \'Bazzicalupo P\" Affiliation_address \"IIGB - CNR, - 10, Via Marconi - 80125 Naples, Italy.\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two52\' WHERE joinkey = \'wm99ab709\' AND pap_author = \'Bazzicalupo P\" Affiliation_address \"IIGB - CNR, - 10, Via Marconi - 80125 Naples, Italy.\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 10:36:35.049818-08\' WHERE joinkey = \'wm99ab739\' AND pap_author = \'Bazzicalupo P\" Affiliation_address \"Istituto Internazionale di Genetica e Biofisica, CNR, 80125 Naples, Italy.\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two52\' WHERE joinkey = \'wm99ab739\' AND pap_author = \'Bazzicalupo P\" Affiliation_address \"Istituto Internazionale di Genetica e Biofisica, CNR, 80125 Naples, Italy.\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 10:42:23.990601-08\' WHERE joinkey = \'wcwm2000ab98\' AND pap_author = \'Bednarek EM\" Affiliation_address \"Department of Biology, University of Utah, Salt Lake City, UT 84112, USA\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two53\' WHERE joinkey = \'wcwm2000ab98\' AND pap_author = \'Bednarek EM\" Affiliation_address \"Department of Biology, University of Utah, Salt Lake City, UT 84112, USA\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 10:42:24.014223-08\' WHERE joinkey = \'wm2001p699\' AND pap_author = \'Bednarek EM\" Affiliation_address \"Department of Biology, University of Utah, Salt Lake City, UT 84112\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two53\' WHERE joinkey = \'wm2001p699\' AND pap_author = \'Bednarek EM\" Affiliation_address \"Department of Biology, University of Utah, Salt Lake City, UT 84112\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 10:46:49.177531-08\' WHERE joinkey = \'cgc3576\' AND pap_author = \'Beg AA\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two54\' WHERE joinkey = \'cgc3576\' AND pap_author = \'Beg AA\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 10:49:15.328061-08\' WHERE joinkey = \'wcwm2000ab99\' AND pap_author = \'Beg AA\" Affiliation_address \"Dept. of Biology, University of Utah 257 South 1400 East Salt Lake City, UT 84112\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two54\' WHERE joinkey = \'wcwm2000ab99\' AND pap_author = \'Beg AA\" Affiliation_address \"Dept. of Biology, University of Utah 257 South 1400 East Salt Lake City, UT 84112\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 10:49:15.354156-08\' WHERE joinkey = \'wm2001p684\' AND pap_author = \'Beg AA\" Affiliation_address \"Interdepartmental Program In Neuroscience and Department of Biology, University of Utah,      257 South 1400 East, Salt Lake City, UT 84112\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two54\' WHERE joinkey = \'wm2001p684\' AND pap_author = \'Beg AA\" Affiliation_address \"Interdepartmental Program In Neuroscience and Department of Biology, University of Utah,      257 South 1400 East, Salt Lake City, UT 84112\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:13:48.45577-08\' WHERE joinkey = \'wm2001p1075\' AND pap_author = \'Behm CA\" Affiliation_address \"School of Biochemistry and Molecular Biology, Faculty of Science, Australian National University, Canberra, Australia   0200\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two55\' WHERE joinkey = \'wm2001p1075\' AND pap_author = \'Behm CA\" Affiliation_address \"School of Biochemistry and Molecular Biology, Faculty of Science, Australian National University, Canberra, Australia   0200\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:18:20.684052-08\' WHERE joinkey = \'cgc1026\' AND pap_author = \'Benian GM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two56\' WHERE joinkey = \'cgc1026\' AND pap_author = \'Benian GM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:18:20.711459-08\' WHERE joinkey = \'cgc1031\' AND pap_author = \'Benian GM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two56\' WHERE joinkey = \'cgc1031\' AND pap_author = \'Benian GM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:18:20.728817-08\' WHERE joinkey = \'cgc1203\' AND pap_author = \'Benian GM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two56\' WHERE joinkey = \'cgc1203\' AND pap_author = \'Benian GM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:18:20.743047-08\' WHERE joinkey = \'cgc1748\' AND pap_author = \'Benian GM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two56\' WHERE joinkey = \'cgc1748\' AND pap_author = \'Benian GM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:18:20.756733-08\' WHERE joinkey = \'cgc1773\' AND pap_author = \'Benian GM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two56\' WHERE joinkey = \'cgc1773\' AND pap_author = \'Benian GM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:18:20.770877-08\' WHERE joinkey = \'cgc1891\' AND pap_author = \'Benian GM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two56\' WHERE joinkey = \'cgc1891\' AND pap_author = \'Benian GM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:18:20.795023-08\' WHERE joinkey = \'cgc1934\' AND pap_author = \'Benian GM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two56\' WHERE joinkey = \'cgc1934\' AND pap_author = \'Benian GM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:18:20.813477-08\' WHERE joinkey = \'cgc1995\' AND pap_author = \'Benian GM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two56\' WHERE joinkey = \'cgc1995\' AND pap_author = \'Benian GM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:18:20.830592-08\' WHERE joinkey = \'cgc2014\' AND pap_author = \'Benian GM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two56\' WHERE joinkey = \'cgc2014\' AND pap_author = \'Benian GM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:18:20.852519-08\' WHERE joinkey = \'cgc2411\' AND pap_author = \'Benian GM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two56\' WHERE joinkey = \'cgc2411\' AND pap_author = \'Benian GM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:24:08.224595-08\' WHERE joinkey = \'cgc2558\' AND pap_author = \'Benian GM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two56\' WHERE joinkey = \'cgc2558\' AND pap_author = \'Benian GM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:24:08.249958-08\' WHERE joinkey = \'cgc2620\' AND pap_author = \'Benian GM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two56\' WHERE joinkey = \'cgc2620\' AND pap_author = \'Benian GM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:24:08.268865-08\' WHERE joinkey = \'cgc2642\' AND pap_author = \'Benian GM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two56\' WHERE joinkey = \'cgc2642\' AND pap_author = \'Benian GM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:24:08.292022-08\' WHERE joinkey = \'cgc2643\' AND pap_author = \'Benian GM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two56\' WHERE joinkey = \'cgc2643\' AND pap_author = \'Benian GM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:24:08.313853-08\' WHERE joinkey = \'cgc3001\' AND pap_author = \'Benian GM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two56\' WHERE joinkey = \'cgc3001\' AND pap_author = \'Benian GM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:24:08.339352-08\' WHERE joinkey = \'cgc3529\' AND pap_author = \'Benian GM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two56\' WHERE joinkey = \'cgc3529\' AND pap_author = \'Benian GM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:24:08.350971-08\' WHERE joinkey = \'cgc4410\' AND pap_author = \'Benian GM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two56\' WHERE joinkey = \'cgc4410\' AND pap_author = \'Benian GM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:24:08.367774-08\' WHERE joinkey = \'cgc4569\' AND pap_author = \'Benian GM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two56\' WHERE joinkey = \'cgc4569\' AND pap_author = \'Benian GM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:24:08.390561-08\' WHERE joinkey = \'cgc4841\' AND pap_author = \'Benian GM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two56\' WHERE joinkey = \'cgc4841\' AND pap_author = \'Benian GM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:24:08.419906-08\' WHERE joinkey = \'cgc877\' AND pap_author = \'Benian GM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two56\' WHERE joinkey = \'cgc877\' AND pap_author = \'Benian GM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:26:33.362479-08\' WHERE joinkey = \'cgc893\' AND pap_author = \'Benian GM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two56\' WHERE joinkey = \'cgc893\' AND pap_author = \'Benian GM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:26:33.393022-08\' WHERE joinkey = \'ecwm2000ab200\' AND pap_author = \'Benian GM\" Affiliation_address \"Exelixis, San Francisco, CA, and Pathology, Emory Univ., Atlanta, GA\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two56\' WHERE joinkey = \'ecwm2000ab200\' AND pap_author = \'Benian GM\" Affiliation_address \"Exelixis, San Francisco, CA, and Pathology, Emory Univ., Atlanta, GA\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:26:33.420942-08\' WHERE joinkey = \'ecwm2000ab201\' AND pap_author = \'Benian GM\" Affiliation_address \"Dept. of Pathology, Emory Univ., Atlanta, GA\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two56\' WHERE joinkey = \'ecwm2000ab201\' AND pap_author = \'Benian GM\" Affiliation_address \"Dept. of Pathology, Emory Univ., Atlanta, GA\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:26:33.437541-08\' WHERE joinkey = \'ecwm2000ab52\' AND pap_author = \'Benian GM\" Affiliation_address \"Dept of Pathology, Emory Univ, Atlanta, GA 30322\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two56\' WHERE joinkey = \'ecwm2000ab52\' AND pap_author = \'Benian GM\" Affiliation_address \"Dept of Pathology, Emory Univ, Atlanta, GA 30322\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:26:33.46212-08\' WHERE joinkey = \'med94156167\' AND pap_author = \'Benian GM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two56\' WHERE joinkey = \'med94156167\' AND pap_author = \'Benian GM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:26:33.477173-08\' WHERE joinkey = \'mwwm96ab34\' AND pap_author = \'Benian GM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two56\' WHERE joinkey = \'mwwm96ab34\' AND pap_author = \'Benian GM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:26:33.496134-08\' WHERE joinkey = \'wbg11.4p42\' AND pap_author = \'Benian GM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two56\' WHERE joinkey = \'wbg11.4p42\' AND pap_author = \'Benian GM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:26:33.51905-08\' WHERE joinkey = \'wbg11.4p43\' AND pap_author = \'Benian GM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two56\' WHERE joinkey = \'wbg11.4p43\' AND pap_author = \'Benian GM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:26:33.531754-08\' WHERE joinkey = \'wbg11.4p45\' AND pap_author = \'Benian GM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two56\' WHERE joinkey = \'wbg11.4p45\' AND pap_author = \'Benian GM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:26:33.553391-08\' WHERE joinkey = \'wbg14.5p44\' AND pap_author = \'Benian GM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two56\' WHERE joinkey = \'wbg14.5p44\' AND pap_author = \'Benian GM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:28:51.735963-08\' WHERE joinkey = \'wbg15.1p70\' AND pap_author = \'Benian GM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two56\' WHERE joinkey = \'wbg15.1p70\' AND pap_author = \'Benian GM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:28:51.751872-08\' WHERE joinkey = \'wbg8.2p47\' AND pap_author = \'Benian GM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two56\' WHERE joinkey = \'wbg8.2p47\' AND pap_author = \'Benian GM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:28:51.766519-08\' WHERE joinkey = \'wbg8.3p87\' AND pap_author = \'Benian GM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two56\' WHERE joinkey = \'wbg8.3p87\' AND pap_author = \'Benian GM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:28:51.782521-08\' WHERE joinkey = \'wbg8.3p88\' AND pap_author = \'Benian GM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two56\' WHERE joinkey = \'wbg8.3p88\' AND pap_author = \'Benian GM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:28:51.79472-08\' WHERE joinkey = \'wbg8.3p89\' AND pap_author = \'Benian GM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two56\' WHERE joinkey = \'wbg8.3p89\' AND pap_author = \'Benian GM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:28:51.807904-08\' WHERE joinkey = \'wbg9.1p25\' AND pap_author = \'Benian GM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two56\' WHERE joinkey = \'wbg9.1p25\' AND pap_author = \'Benian GM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:28:51.8234-08\' WHERE joinkey = \'wbg9.2p16\' AND pap_author = \'Benian GM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two56\' WHERE joinkey = \'wbg9.2p16\' AND pap_author = \'Benian GM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:28:51.836735-08\' WHERE joinkey = \'wbg9.2p38\' AND pap_author = \'Benian GM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two56\' WHERE joinkey = \'wbg9.2p38\' AND pap_author = \'Benian GM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:28:51.848453-08\' WHERE joinkey = \'wcwm96ab157\' AND pap_author = \'Benian GM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two56\' WHERE joinkey = \'wcwm96ab157\' AND pap_author = \'Benian GM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:28:51.870425-08\' WHERE joinkey = \'wcwm96ab160\' AND pap_author = \'Benian GM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two56\' WHERE joinkey = \'wcwm96ab160\' AND pap_author = \'Benian GM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:32:14.972498-08\' WHERE joinkey = \'wcwm98ab126\' AND pap_author = \'Benian GM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two56\' WHERE joinkey = \'wcwm98ab126\' AND pap_author = \'Benian GM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:32:15.018548-08\' WHERE joinkey = \'wcwm98ab170\' AND pap_author = \'Benian GM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two56\' WHERE joinkey = \'wcwm98ab170\' AND pap_author = \'Benian GM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:32:15.042-08\' WHERE joinkey = \'wcwm98ab215\' AND pap_author = \'Benian GM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two56\' WHERE joinkey = \'wcwm98ab215\' AND pap_author = \'Benian GM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:32:15.061674-08\' WHERE joinkey = \'wm83p97\' AND pap_author = \'Benian GM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two56\' WHERE joinkey = \'wm83p97\' AND pap_author = \'Benian GM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:32:15.077613-08\' WHERE joinkey = \'wm85p156\' AND pap_author = \'Benian GM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two56\' WHERE joinkey = \'wm85p156\' AND pap_author = \'Benian GM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:32:15.102393-08\' WHERE joinkey = \'wm85p25\' AND pap_author = \'Benian GM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two56\' WHERE joinkey = \'wm85p25\' AND pap_author = \'Benian GM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:32:15.118327-08\' WHERE joinkey = \'wm85p52\' AND pap_author = \'Benian GM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two56\' WHERE joinkey = \'wm85p52\' AND pap_author = \'Benian GM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:32:15.133335-08\' WHERE joinkey = \'wm87p181\' AND pap_author = \'Benian GM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two56\' WHERE joinkey = \'wm87p181\' AND pap_author = \'Benian GM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:32:15.154883-08\' WHERE joinkey = \'wm89p22\' AND pap_author = \'Benian GM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two56\' WHERE joinkey = \'wm89p22\' AND pap_author = \'Benian GM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:32:15.166264-08\' WHERE joinkey = \'wm91p191\' AND pap_author = \'Benian GM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two56\' WHERE joinkey = \'wm91p191\' AND pap_author = \'Benian GM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:34:20.657771-08\' WHERE joinkey = \'wm91p193\' AND pap_author = \'Benian GM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two56\' WHERE joinkey = \'wm91p193\' AND pap_author = \'Benian GM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:34:20.674872-08\' WHERE joinkey = \'wm91p322\' AND pap_author = \'Benian GM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two56\' WHERE joinkey = \'wm91p322\' AND pap_author = \'Benian GM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:34:20.688211-08\' WHERE joinkey = \'wm93p102\' AND pap_author = \'Benian GM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two56\' WHERE joinkey = \'wm93p102\' AND pap_author = \'Benian GM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:34:20.70321-08\' WHERE joinkey = \'wm93p269\' AND pap_author = \'Benian GM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two56\' WHERE joinkey = \'wm93p269\' AND pap_author = \'Benian GM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:34:20.717775-08\' WHERE joinkey = \'wm93p452\' AND pap_author = \'Benian GM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two56\' WHERE joinkey = \'wm93p452\' AND pap_author = \'Benian GM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:34:20.741895-08\' WHERE joinkey = \'wm95p123\' AND pap_author = \'Benian GM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two56\' WHERE joinkey = \'wm95p123\' AND pap_author = \'Benian GM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:34:20.753532-08\' WHERE joinkey = \'wm95p518\' AND pap_author = \'Benian GM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two56\' WHERE joinkey = \'wm95p518\' AND pap_author = \'Benian GM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:34:20.767158-08\' WHERE joinkey = \'wm97ab591\' AND pap_author = \'Benian GM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two56\' WHERE joinkey = \'wm97ab591\' AND pap_author = \'Benian GM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:34:20.793961-08\' WHERE joinkey = \'wm97ab604\' AND pap_author = \'Benian GM\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two56\' WHERE joinkey = \'wm97ab604\' AND pap_author = \'Benian GM\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:34:20.85371-08\' WHERE joinkey = \'wm99ab651\' AND pap_author = \'Benian GM\" Affiliation_address \"Depts of Pathology and Cell Biology, Emory Univ., Atlanta, GA 30322, USA.\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two56\' WHERE joinkey = \'wm99ab651\' AND pap_author = \'Benian GM\" Affiliation_address \"Depts of Pathology and Cell Biology, Emory Univ., Atlanta, GA 30322, USA.\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:35:18.607553-08\' WHERE joinkey = \'wm99ab846\' AND pap_author = \'Benian GM\" Affiliation_address \"Depts. of Path. and Cell Biol., Emory University, Atlanta, GA 30322 USA\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two56\' WHERE joinkey = \'wm99ab846\' AND pap_author = \'Benian GM\" Affiliation_address \"Depts. of Path. and Cell Biol., Emory University, Atlanta, GA 30322 USA\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:35:18.671094-08\' WHERE joinkey = \'wm99ab847\' AND pap_author = \'Benian GM\" Affiliation_address \"Depts. of Path. and Cell Biol., Emory Univ., Atlanta, GA 30322.\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two56\' WHERE joinkey = \'wm99ab847\' AND pap_author = \'Benian GM\" Affiliation_address \"Depts. of Path. and Cell Biol., Emory Univ., Atlanta, GA 30322.\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:40:29.132319-08\' WHERE joinkey = \'cgc1161\' AND pap_author = \'Bennett KL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two57\' WHERE joinkey = \'cgc1161\' AND pap_author = \'Bennett KL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:40:29.156142-08\' WHERE joinkey = \'cgc1176\' AND pap_author = \'Bennett KL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two57\' WHERE joinkey = \'cgc1176\' AND pap_author = \'Bennett KL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:40:29.175956-08\' WHERE joinkey = \'cgc1585\' AND pap_author = \'Bennett KL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two57\' WHERE joinkey = \'cgc1585\' AND pap_author = \'Bennett KL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:40:29.190171-08\' WHERE joinkey = \'cgc1822\' AND pap_author = \'Bennett KL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two57\' WHERE joinkey = \'cgc1822\' AND pap_author = \'Bennett KL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:40:29.202964-08\' WHERE joinkey = \'cgc1916\' AND pap_author = \'Bennett KL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two57\' WHERE joinkey = \'cgc1916\' AND pap_author = \'Bennett KL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:40:29.217921-08\' WHERE joinkey = \'cgc2206\' AND pap_author = \'Bennett KL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two57\' WHERE joinkey = \'cgc2206\' AND pap_author = \'Bennett KL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:40:29.239906-08\' WHERE joinkey = \'cgc2611\' AND pap_author = \'Bennett KL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two57\' WHERE joinkey = \'cgc2611\' AND pap_author = \'Bennett KL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:40:29.268172-08\' WHERE joinkey = \'cgc4229\' AND pap_author = \'Bennett KL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two57\' WHERE joinkey = \'cgc4229\' AND pap_author = \'Bennett KL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:42:48.167277-08\' WHERE joinkey = \'cgc955\' AND pap_author = \'Bennett KL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two57\' WHERE joinkey = \'cgc955\' AND pap_author = \'Bennett KL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:42:48.188321-08\' WHERE joinkey = \'cgc956\' AND pap_author = \'Bennett KL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two57\' WHERE joinkey = \'cgc956\' AND pap_author = \'Bennett KL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:42:48.199497-08\' WHERE joinkey = \'ecwm2000ab145\' AND pap_author = \'Bennett KL\" Affiliation_address \"Dept. of Molecular Microbiology/Immunology, University of Missouri, Columbia, MO 65212\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two57\' WHERE joinkey = \'ecwm2000ab145\' AND pap_author = \'Bennett KL\" Affiliation_address \"Dept. of Molecular Microbiology/Immunology, University of Missouri, Columbia, MO 65212\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:42:48.233177-08\' WHERE joinkey = \'mwwm2000ab46\' AND pap_author = \'Bennett KL\" Affiliation_address \"Molecular Microbiology and Immunology Department, University of Missouri, Columbia, MO 65212\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two57\' WHERE joinkey = \'mwwm2000ab46\' AND pap_author = \'Bennett KL\" Affiliation_address \"Molecular Microbiology and Immunology Department, University of Missouri, Columbia, MO 65212\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:42:48.253218-08\' WHERE joinkey = \'mwwm96ab53\' AND pap_author = \'Bennett KL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two57\' WHERE joinkey = \'mwwm96ab53\' AND pap_author = \'Bennett KL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:42:48.266991-08\' WHERE joinkey = \'mwwm96ab76\' AND pap_author = \'Bennett KL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two57\' WHERE joinkey = \'mwwm96ab76\' AND pap_author = \'Bennett KL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:42:48.321933-08\' WHERE joinkey = \'mwwm98ab39\' AND pap_author = \'Bennett KL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two57\' WHERE joinkey = \'mwwm98ab39\' AND pap_author = \'Bennett KL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:44:25.835621-08\' WHERE joinkey = \'mwwm98ab43\' AND pap_author = \'Bennett KL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two57\' WHERE joinkey = \'mwwm98ab43\' AND pap_author = \'Bennett KL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:44:25.896313-08\' WHERE joinkey = \'mwwm98ab80\' AND pap_author = \'Bennett KL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two57\' WHERE joinkey = \'mwwm98ab80\' AND pap_author = \'Bennett KL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:44:25.910799-08\' WHERE joinkey = \'wbg10.1p76\' AND pap_author = \'Bennett KL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two57\' WHERE joinkey = \'wbg10.1p76\' AND pap_author = \'Bennett KL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:44:25.926171-08\' WHERE joinkey = \'wbg10.2p66\' AND pap_author = \'Bennett KL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two57\' WHERE joinkey = \'wbg10.2p66\' AND pap_author = \'Bennett KL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:44:25.937916-08\' WHERE joinkey = \'wbg10.2p67\' AND pap_author = \'Bennett KL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two57\' WHERE joinkey = \'wbg10.2p67\' AND pap_author = \'Bennett KL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:44:25.951561-08\' WHERE joinkey = \'wbg10.3p77\' AND pap_author = \'Bennett KL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two57\' WHERE joinkey = \'wbg10.3p77\' AND pap_author = \'Bennett KL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:44:25.963943-08\' WHERE joinkey = \'wbg10.3p78\' AND pap_author = \'Bennett KL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two57\' WHERE joinkey = \'wbg10.3p78\' AND pap_author = \'Bennett KL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:44:25.998112-08\' WHERE joinkey = \'wbg11.5p20\' AND pap_author = \'Bennett KL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two57\' WHERE joinkey = \'wbg11.5p20\' AND pap_author = \'Bennett KL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:44:26.014176-08\' WHERE joinkey = \'wbg11.5p25\' AND pap_author = \'Bennett KL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two57\' WHERE joinkey = \'wbg11.5p25\' AND pap_author = \'Bennett KL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:44:26.026967-08\' WHERE joinkey = \'wbg11.5p26\' AND pap_author = \'Bennett KL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two57\' WHERE joinkey = \'wbg11.5p26\' AND pap_author = \'Bennett KL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:46:25.065126-08\' WHERE joinkey = \'wbg12.5p83\' AND pap_author = \'Bennett KL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two57\' WHERE joinkey = \'wbg12.5p83\' AND pap_author = \'Bennett KL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:46:25.089662-08\' WHERE joinkey = \'wbg12.5p84\' AND pap_author = \'Bennett KL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two57\' WHERE joinkey = \'wbg12.5p84\' AND pap_author = \'Bennett KL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:46:25.099261-08\' WHERE joinkey = \'wbg13.1p22\' AND pap_author = \'Bennett KL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two57\' WHERE joinkey = \'wbg13.1p22\' AND pap_author = \'Bennett KL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:46:25.109295-08\' WHERE joinkey = \'wbg13.3p63\' AND pap_author = \'Bennett KL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two57\' WHERE joinkey = \'wbg13.3p63\' AND pap_author = \'Bennett KL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:46:25.122841-08\' WHERE joinkey = \'wbg13.5p69\' AND pap_author = \'Bennett KL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two57\' WHERE joinkey = \'wbg13.5p69\' AND pap_author = \'Bennett KL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:46:25.151548-08\' WHERE joinkey = \'wbg9.1p55\' AND pap_author = \'Bennett KL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two57\' WHERE joinkey = \'wbg9.1p55\' AND pap_author = \'Bennett KL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:46:25.180866-08\' WHERE joinkey = \'wm2001p252\' AND pap_author = \'Bennett KL\" Affiliation_address \"Molecular Microbiology and Immunology Dept., University of Missouri, Columbia MO 65212\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two57\' WHERE joinkey = \'wm2001p252\' AND pap_author = \'Bennett KL\" Affiliation_address \"Molecular Microbiology and Immunology Dept., University of Missouri, Columbia MO 65212\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:47:51.944051-08\' WHERE joinkey = \'wm85p27\' AND pap_author = \'Bennett KL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two57\' WHERE joinkey = \'wm85p27\' AND pap_author = \'Bennett KL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:47:51.962414-08\' WHERE joinkey = \'wm87p92\' AND pap_author = \'Bennett KL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two57\' WHERE joinkey = \'wm87p92\' AND pap_author = \'Bennett KL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:47:51.977768-08\' WHERE joinkey = \'wm89p208\' AND pap_author = \'Bennett KL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two57\' WHERE joinkey = \'wm89p208\' AND pap_author = \'Bennett KL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:47:51.997988-08\' WHERE joinkey = \'wm89p216\' AND pap_author = \'Bennett KL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two57\' WHERE joinkey = \'wm89p216\' AND pap_author = \'Bennett KL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:47:52.018001-08\' WHERE joinkey = \'wm89p58\' AND pap_author = \'Bennett KL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two57\' WHERE joinkey = \'wm89p58\' AND pap_author = \'Bennett KL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:47:52.031468-08\' WHERE joinkey = \'wm91p240\' AND pap_author = \'Bennett KL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two57\' WHERE joinkey = \'wm91p240\' AND pap_author = \'Bennett KL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:47:52.048027-08\' WHERE joinkey = \'wm91p274\' AND pap_author = \'Bennett KL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two57\' WHERE joinkey = \'wm91p274\' AND pap_author = \'Bennett KL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:47:52.06342-08\' WHERE joinkey = \'wm91p275\' AND pap_author = \'Bennett KL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two57\' WHERE joinkey = \'wm91p275\' AND pap_author = \'Bennett KL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:47:52.075878-08\' WHERE joinkey = \'wm93p149\' AND pap_author = \'Bennett KL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two57\' WHERE joinkey = \'wm93p149\' AND pap_author = \'Bennett KL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:47:52.090134-08\' WHERE joinkey = \'wm93p255\' AND pap_author = \'Bennett KL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two57\' WHERE joinkey = \'wm93p255\' AND pap_author = \'Bennett KL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:49:49.561958-08\' WHERE joinkey = \'wm93p384\' AND pap_author = \'Bennett KL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two57\' WHERE joinkey = \'wm93p384\' AND pap_author = \'Bennett KL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:49:49.583854-08\' WHERE joinkey = \'wm93p49\' AND pap_author = \'Bennett KL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two57\' WHERE joinkey = \'wm93p49\' AND pap_author = \'Bennett KL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:49:49.595805-08\' WHERE joinkey = \'wm95p12\' AND pap_author = \'Bennett KL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two57\' WHERE joinkey = \'wm95p12\' AND pap_author = \'Bennett KL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:49:49.614636-08\' WHERE joinkey = \'wm95p322\' AND pap_author = \'Bennett KL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two57\' WHERE joinkey = \'wm95p322\' AND pap_author = \'Bennett KL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:49:49.6306-08\' WHERE joinkey = \'wm95p481\' AND pap_author = \'Bennett KL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two57\' WHERE joinkey = \'wm95p481\' AND pap_author = \'Bennett KL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:49:49.648321-08\' WHERE joinkey = \'wm97ab311\' AND pap_author = \'Bennett KL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two57\' WHERE joinkey = \'wm97ab311\' AND pap_author = \'Bennett KL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:49:49.662873-08\' WHERE joinkey = \'wm97ab334\' AND pap_author = \'Bennett KL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two57\' WHERE joinkey = \'wm97ab334\' AND pap_author = \'Bennett KL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:51:02.953036-08\' WHERE joinkey = \'wm99ab480\' AND pap_author = \'Bennett KL\" Affiliation_address \"MMI Dept. University of Missouri, Columbia, MO, 65203.\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two57\' WHERE joinkey = \'wm99ab480\' AND pap_author = \'Bennett KL\" Affiliation_address \"MMI Dept. University of Missouri, Columbia, MO, 65203.\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:51:02.990304-08\' WHERE joinkey = \'wm99ab506\' AND pap_author = \'Bennett KL\" Affiliation_address \"University of Missouri, Columbia, MO 65212.\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two57\' WHERE joinkey = \'wm99ab506\' AND pap_author = \'Bennett KL\" Affiliation_address \"University of Missouri, Columbia, MO 65212.\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:51:03.022661-08\' WHERE joinkey = \'wm99ab788\' AND pap_author = \'Bennett KL\" Affiliation_address \"Department of Molecular Microbiology and Immunology, University of Missouri, Columbia, MO 65212\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two57\' WHERE joinkey = \'wm99ab788\' AND pap_author = \'Bennett KL\" Affiliation_address \"Department of Molecular Microbiology and Immunology, University of Missouri, Columbia, MO 65212\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:55:41.84786-08\' WHERE joinkey = \'cgc2561\' AND pap_author = \'Berkowitz LA\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two58\' WHERE joinkey = \'cgc2561\' AND pap_author = \'Berkowitz LA\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:55:41.866819-08\' WHERE joinkey = \'cgc4323\' AND pap_author = \'Berkowitz LA\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two58\' WHERE joinkey = \'cgc4323\' AND pap_author = \'Berkowitz LA\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:55:41.883719-08\' WHERE joinkey = \'cgc5375\' AND pap_author = \'Berkowitz LA\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two58\' WHERE joinkey = \'cgc5375\' AND pap_author = \'Berkowitz LA\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:55:41.900361-08\' WHERE joinkey = \'mwwm96ab6\' AND pap_author = \'Berkowitz LA\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two58\' WHERE joinkey = \'mwwm96ab6\' AND pap_author = \'Berkowitz LA\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:55:41.910852-08\' WHERE joinkey = \'mwwm98ab5\' AND pap_author = \'Berkowitz LA\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two58\' WHERE joinkey = \'mwwm98ab5\' AND pap_author = \'Berkowitz LA\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:55:41.920114-08\' WHERE joinkey = \'wm2001p963\' AND pap_author = \'Berkowitz LA\" Affiliation_address \"University of Tulsa   Tulsa, OK  74104\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two58\' WHERE joinkey = \'wm2001p963\' AND pap_author = \'Berkowitz LA\" Affiliation_address \"University of Tulsa   Tulsa, OK  74104\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:55:41.931111-08\' WHERE joinkey = \'wm93p50\' AND pap_author = \'Berkowitz LA\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two58\' WHERE joinkey = \'wm93p50\' AND pap_author = \'Berkowitz LA\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:55:41.942197-08\' WHERE joinkey = \'wm95p125\' AND pap_author = \'Berkowitz LA\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two58\' WHERE joinkey = \'wm95p125\' AND pap_author = \'Berkowitz LA\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 11:55:41.952246-08\' WHERE joinkey = \'wm99ab81\' AND pap_author = \'Berkowitz LA\" Affiliation_address \"Indiana University Bloomington, IN 47405\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two58\' WHERE joinkey = \'wm99ab81\' AND pap_author = \'Berkowitz LA\" Affiliation_address \"Indiana University Bloomington, IN 47405\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 12:06:28.772145-08\' WHERE joinkey = \'cgc1503\' AND pap_author = \'Berks M\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two59\' WHERE joinkey = \'cgc1503\' AND pap_author = \'Berks M\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 12:06:28.920918-08\' WHERE joinkey = \'cgc1902\' AND pap_author = \'Berks M\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two59\' WHERE joinkey = \'cgc1902\' AND pap_author = \'Berks M\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 12:06:28.952803-08\' WHERE joinkey = \'cgc1976\' AND pap_author = \'Berks M\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two59\' WHERE joinkey = \'cgc1976\' AND pap_author = \'Berks M\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 12:06:28.970526-08\' WHERE joinkey = \'cgc2327\' AND pap_author = \'Berks M\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two59\' WHERE joinkey = \'cgc2327\' AND pap_author = \'Berks M\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 12:06:29.010228-08\' WHERE joinkey = \'wbg12.3p22\' AND pap_author = \'Berks M\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two59\' WHERE joinkey = \'wbg12.3p22\' AND pap_author = \'Berks M\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-30 12:08:37.889961-08\' WHERE joinkey = \'wm93p340\' AND pap_author = \'Berks M\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two59\' WHERE joinkey = \'wm93p340\' AND pap_author = \'Berks M\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-12-02 15:54:00.558569-08\' WHERE joinkey = \'cgc5236\' AND pap_author = \'Berry KL\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two60\' WHERE joinkey = \'cgc5236\' AND pap_author = \'Berry KL\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-12-02 15:54:00.694031-08\' WHERE joinkey = \'wbg16.4p28\' AND pap_author = \'Berry KL\" Affiliation_address \"Columbia University, College of Physicians and Surgeons, Dept. of Biochem. & Mol. Biophysics, New York, NY 10032, U.S.A. \'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two60\' WHERE joinkey = \'wbg16.4p28\' AND pap_author = \'Berry KL\" Affiliation_address \"Columbia University, College of Physicians and Surgeons, Dept. of Biochem. & Mol. Biophysics, New York, NY 10032, U.S.A. \'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-12-02 15:54:00.724047-08\' WHERE joinkey = \'wm2001p136\' AND pap_author = \'Berry KL\" Affiliation_address \"Columbia University, College of Physicians and Surgeons, Dept. Biochemistry, 10032 New York\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two60\' WHERE joinkey = \'wm2001p136\' AND pap_author = \'Berry KL\" Affiliation_address \"Columbia University, College of Physicians and Surgeons, Dept. Biochemistry, 10032 New York\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-12-02 15:54:00.746931-08\' WHERE joinkey = \'wm2001p929\' AND pap_author = \'Berry KL\" Affiliation_address \"Columbia University, College of Physicians and Surgeons, Dept. Biochemistry, New York 10032\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two60\' WHERE joinkey = \'wm2001p929\' AND pap_author = \'Berry KL\" Affiliation_address \"Columbia University, College of Physicians and Surgeons, Dept. Biochemistry, New York 10032\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-12-02 15:58:54.402151-08\' WHERE joinkey = \'cgc4837\' AND pap_author = \'Bessereau J-L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two61\' WHERE joinkey = \'cgc4837\' AND pap_author = \'Bessereau J-L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-12-02 15:58:54.429218-08\' WHERE joinkey = \'euwm2000ab4\' AND pap_author = \'Bessereau J-L\" Affiliation_address \"INSERM, Biologie Cellulaire de la Synapse, U 97,   Ecole Normale Suprieure, 6, rue dUlm, 75005 Paris, France\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two61\' WHERE joinkey = \'euwm2000ab4\' AND pap_author = \'Bessereau J-L\" Affiliation_address \"INSERM, Biologie Cellulaire de la Synapse, U 97,   Ecole Normale Suprieure, 6, rue dUlm, 75005 Paris, France\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-12-02 15:58:54.451238-08\' WHERE joinkey = \'wcwm2000ab36\' AND pap_author = \'Bessereau J-L\" Affiliation_address \"Department of Biology, University of Utah, Salt Lake City, UT, 84112\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two61\' WHERE joinkey = \'wcwm2000ab36\' AND pap_author = \'Bessereau J-L\" Affiliation_address \"Department of Biology, University of Utah, Salt Lake City, UT, 84112\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-12-02 15:58:54.46421-08\' WHERE joinkey = \'wcwm98ab15\' AND pap_author = \'Bessereau J-L\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two61\' WHERE joinkey = \'wcwm98ab15\' AND pap_author = \'Bessereau J-L\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-12-02 15:58:54.480873-08\' WHERE joinkey = \'wm99ab191\' AND pap_author = \'Bessereau J-L\" Affiliation_address \"Dept. Biology, University of Utah, Salt Lake City, UT 84112\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two61\' WHERE joinkey = \'wm99ab191\' AND pap_author = \'Bessereau J-L\" Affiliation_address \"Dept. Biology, University of Utah, Salt Lake City, UT 84112\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-12-02 15:58:54.501123-08\' WHERE joinkey = \'wm99ab192\' AND pap_author = \'Bessereau J-L\" Affiliation_address \"Dept. Biology, University of Utah, Salt Lake City, UT 84112\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two61\' WHERE joinkey = \'wm99ab192\' AND pap_author = \'Bessereau J-L\" Affiliation_address \"Dept. Biology, University of Utah, Salt Lake City, UT 84112\'; " );

$result = $conn->exec( "UPDATE pap_author SET pap_timestamp = \'2002-11-21 10:20:00.522274-08\' WHERE joinkey = \'cgc1138\' AND pap_author = \'Aamodt EJ\'; " );
$result = $conn->exec( "UPDATE pap_author SET pap_person = \'two2\' WHERE joinkey = \'cgc1138\' AND pap_author = \'Aamodt EJ\'; " );

