#!/usr/bin/perl5.6.0
#
# hack to fix entries which where improperly set with \' instead of \\'

use lib qw( /usr/lib/perl5/site_perl/5.6.1/i686-linux/ );
use Pg;

$conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

$result = $conn->exec( "INSERT INTO ace_address VALUES ('ace115', '46, rue d\\'Ulm')");
$result = $conn->exec( "INSERT INTO ace_address VALUES ('ace127', 'Laboratoire d\\'Oncologie Moleculaire')");
$result = $conn->exec( "INSERT INTO ace_address VALUES ('ace224', 'PEOPLE\\'S REPUBLIC OF CHINA')");
$result = $conn->exec( "INSERT INTO ace_address VALUES ('ace228', 'Department of Biology, Queen\\'s University')");
$result = $conn->exec( "INSERT INTO ace_address VALUES ('ace394', 'Centre d\\'Immunologie de Marseille-Luminy')");
$result = $conn->exec( "INSERT INTO ace_address VALUES ('ace453', '1 King\\'s College Circle')");
$result = $conn->exec( "INSERT INTO ace_address VALUES ('ace460', 'Tokyo Women\\'s Medical College')");
$result = $conn->exec( "INSERT INTO ace_address VALUES ('ace658', 'Ashworth Laboratories\/King\\'s Buildings')");
$result = $conn->exec( "INSERT INTO ace_address VALUES ('ace658', 'Univ. of Edinburgh, Ashworth Labs, King\\'s Building')");
$result = $conn->exec( "INSERT INTO ace_email VALUES ('ace761', 'didn\\'t work july99')");
$result = $conn->exec( "INSERT INTO ace_address VALUES ('ace829', 'Centre D\\'Immunologie de Marseille-Luminy')");
$result = $conn->exec( "INSERT INTO ace_address VALUES ('ace833', 'Centre d\\'Immunologie Marseille-Luminy')");
$result = $conn->exec( "INSERT INTO ace_address VALUES ('ace1012', 'Tokyo Women\\'s Medical College')");
$result = $conn->exec( "INSERT INTO ace_address VALUES ('ace1128', '46, allée d\\'Italie ')");
$result = $conn->exec( "INSERT INTO ace_address VALUES ('ace1154', '1 King\\'s College Circle')");
$result = $conn->exec( "INSERT INTO ace_address VALUES ('ace1156', 'Department of Pharmacy, King\\'s College London')");
$result = $conn->exec( "INSERT INTO ace_address VALUES ('ace1243', 'Jealott\\'s Hill Research Station')");
$result = $conn->exec( "INSERT INTO ace_address VALUES ('ace1382', 'Children\\'s Hospital')");
$result = $conn->exec( "INSERT INTO ace_address VALUES ('ace1418', '1 King\\'s College Circle')");
$result = $conn->exec( "INSERT INTO ace_address VALUES ('ace1562', '1 King\\'s College Circle')");
$result = $conn->exec( "INSERT INTO ace_address VALUES ('ace1653', '46 rue d\\'Ulm')");
$result = $conn->exec( "INSERT INTO ace_address VALUES ('ace1669', 'Jealott\\'s Hill Research Station')");
$result = $conn->exec( "INSERT INTO wbg_street VALUES ('wbg23', '\"Division of Newborn Medicine Children\\'s Hospital 300 Longwood Avenue, Enders 970\"')");
$result = $conn->exec( "INSERT INTO wbg_lastname VALUES ('wbg218', 'L\\'Hernault')");
$result = $conn->exec( "INSERT INTO wbg_lastname VALUES ('wbg258', 'O\\'Connell')");
$result = $conn->exec( "INSERT INTO wbg_street VALUES ('wbg341', 'University of Arkansas for Medical Sciences Central Arkansas Veterans\\' Health Care System Medical Research (LR-151) 4300 West 7th Street')");
$result = $conn->exec( "INSERT INTO wbg_lastname VALUES ('wbg466', 'Ch\\'ng')");
$result = $conn->exec( "INSERT INTO wbg_street VALUES ('wbg566', '\"Ecole Normale Superieure Biologie Cellulaire de la Synapse 46, rue d\\'Ulm\"')");
$result = $conn->exec( "INSERT INTO wbg_street VALUES ('wbg568', '\"Laboratoire d\\'Oncologie Moleculaire U.119 Inserm, IFR 57 27 Blvd. Lei Roure\"')");
$result = $conn->exec( "INSERT INTO wbg_street VALUES ('wbg581', 'Department of Biology Room 2509 Biosciences Complex Queen\\'s University')");
$result = $conn->exec( "INSERT INTO wbg_street VALUES ('wbg602', 'Centre d\\'Immunologie de Marseille-Luminy 163 Avenne de Luminy Case 906')");
$result = $conn->exec( "INSERT INTO wbg_street VALUES ('wbg610', '\"Department of Physiology Tokyo Women\\'s Medical University School of Medicine 8-1 Kawada-cho, Shinjuku-ku\"')");
$result = $conn->exec( "INSERT INTO wbg_street VALUES ('wbg666', 'Centre D\\'Immunologie de Marseille-Luminy 163 Avenne De Luminy Case 906')");
$result = $conn->exec( "INSERT INTO wbg_street VALUES ('wbg670', 'Centre D\\'Immunologie de Marseille-Luminy 163 Avenne De Luminy Case 906')");
$result = $conn->exec( "INSERT INTO wbg_street VALUES ('wbg672', 'Molecular Neuropathobiology Laboratory Imperial Cancer Research Fund 44 Lincoln\\'s Inn Fields')");
$result = $conn->exec( "INSERT INTO wbg_street VALUES ('wbg683', '\"Department of Physiology Tokyo Women\\'s Medical University School of Medicine 8-1 Kawada-cho, Shinjuku-ku\"')");
$result = $conn->exec( "INSERT INTO wbg_lastname VALUES ('wbg706', 'O\\'Neil')");
$result = $conn->exec( "INSERT INTO wbg_street VALUES ('wbg869', '\"1 King\\'s College Circle Room 4282, Medical Sciences Bldg.\"')");
$result = $conn->exec( "INSERT INTO wbg_lastname VALUES ('wbg874', 'L\\'Etoile')");
$result = $conn->exec( "INSERT INTO wbg_lastname VALUES ('wbg881', 'O\\'Rourke')");
$result = $conn->exec( "INSERT INTO wbg_street VALUES ('wbg882', 'Department of Anatomy and Cell Biology University of Toronto 1 King\\'s College Circle')");
