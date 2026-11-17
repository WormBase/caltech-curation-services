#!/usr/bin/env perl

# Cecilia wants person addresses in English place names ( Seville not Sevilla ), and the data errors
# found while looking fixed : html entities, postcodes / Cedex / district numbers in city, typos.
# These values were wrong, so the value is corrected in place in both the data table and the h_ table,
# keeping curator and timestamp, and no new rows are created.  Postcodes taken out of city are dropped,
# not moved to two_post, since that would make new rows.
#
# html entities ( &#305; etc. ) are decoded to plain ascii in city, state, country, institution, old_institution
#   and street, the way the rest of the data is written ( Wroclaw not Wroc\x{142}aw ).  Invisible characters
#   ( zero width space, direction marks, line separator ) are removed.
# two_city, two_state  : exact value mapping below, plus trimming leading / trailing spaces
# two_country          : Turkey -> Turkiye
# two_institution, two_old_institution : the city in the location part ( 'Name; City, Country; Dept' )
#   is mapped with the same city mapping.  Institution names themselves are proper names and stay.
#
# Decided with Cecilia 2026 11 17 : San Sebastian and A Coruna stay, Kiev becomes Kyiv, Turkiye not Turkey,
# proper institution names stay.  Entities in institution and street fixed too.  two2943 and two17777 had their
# postcode in two_city and something else in two_post, their two_post is fixed.  Beeevler is Ankara, Kyoyo is Kyoto.
# The rest of the uncertain values are in cecilia_review.tsv for Cecilia.
#
# dry run by default, prints every value that would change.  ./fix_place_names.pl apply  to update.
# run inside the curation container :
# docker exec caltech-curation-services-main-curation-1 bash -c 'cd /usr/lib/scripts/pgpopulation/two_people/20261117_english_place_names && ./fix_place_names.pl'
# 2026 11 17

use strict;
use warnings;
use DBI;
use Dotenv -load => '/usr/lib/.env';

my $dbh = DBI->connect ( "dbi:Pg:dbname=$ENV{PSQL_DATABASE};host=$ENV{PSQL_HOST};port=$ENV{PSQL_PORT}", "$ENV{PSQL_USERNAME}", "$ENV{PSQL_PASSWORD}", { AutoCommit => 0, RaiseError => 1 }) or die "Cannot connect to database!\n";

binmode STDOUT, ':utf8'; binmode STDERR, ':utf8';
my $apply = (@ARGV && $ARGV[0] eq 'apply') ? 1 : 0;

my %entity = (			# html entity code point => plain text
  305 => 'i', 304 => 'I', 322 => 'l', 263 => 'c', 371 => 'u',	# dotless i is a mangled i-acute here
  8208 => '-', 8209 => '-', 8722 => '-', 8201 => ' ', 65299 => '3',
  8203 => '', 8206 => '', 8232 => '' );				# zero width space, left to right mark, line separator
my $invisible = qr/[\x{200B}\x{200E}\x{200F}\x{2028}\x{FEFF}]/;

sub cleanText {			# decode entities, drop invisible characters, trim, collapse doubled spaces made by the decoding
  my $v = shift;
  my $had = ($v =~ m/&#\d+;|$invisible/) ? 1 : 0;
  $v =~ s/&#(\d+);/defined $entity{$1} ? $entity{$1} : die "no mapping for entity &#$1; in $v\n"/ge;
  $v =~ s/$invisible//g;
  $v =~ s/  +/ /g if $had;
  $v =~ s/^\s+|\s+$//g;
  return $v; }

my %map = ( city => {}, state => {}, country => {} );
foreach my $line (split /\n/, &mapText()) {
  next if ($line =~ m/^\s*(#|$)/);
  my ($table, $old, $new) = split /\t/, $line;
  die "bad mapping line : $line\n" unless (defined $new && $map{$table});
  $map{$table}{$old} = $new; }

my %change;				# table => old value => new value
my %rows;				# table => old value => rows in data table / h_ table

foreach my $table (qw( city state country )) {
  foreach my $old (&distinctValues("two_$table")) {
    my $new = &cleanText($old);
    $new = $map{$table}{$new} if (defined $map{$table}{$new});
    $change{$table}{$old} = $new unless ($new eq $old); } }

foreach my $table (qw( institution old_institution )) {
  foreach my $old (&distinctValues("two_$table")) {
    my $clean = ($old =~ m/&#\d+;|$invisible/) ? &cleanText($old) : $old;
    $change{$table}{$old} = $clean unless ($clean eq $old);
    my @parts = split /;/, $clean, -1;
    next unless (@parts > 1);
    my ($lead, $city, $rest) = $parts[1] =~ m/^(\s*)([^,]*?)(\s+[A-Z]{2}(?:,.*)?|,.*)?$/s;
    next unless (defined $city && defined $map{city}{$city});
    $parts[1] = $lead . $map{city}{$city} . (defined $rest ? $rest : '');
    my $new = join(';', @parts);
    $change{$table}{$old} = $new unless ($new eq $old); } }

foreach my $old (&distinctValues('two_street')) {		# street only for entities, not general trimming
  next unless ($old =~ m/&#\d+;|$invisible/);
  my $new = &cleanText($old);
  $change{street}{$old} = $new unless ($new eq $old); }

my %total;
print join("\t", qw( table old new rows h_rows )) . "\n";
foreach my $table (qw( city state country institution old_institution street )) {
  foreach my $old (sort keys %{ $change{$table} }) {
    my $new = $change{$table}{$old};
    my ($n)  = $dbh->selectrow_array( "SELECT count(*) FROM two_$table WHERE two_$table = ?", undef, $old );
    my ($hn) = $dbh->selectrow_array( "SELECT count(*) FROM h_two_$table WHERE two_$table = ?", undef, $old );
    print join("\t", "two_$table", $old, $new, $n, $hn) . "\n";
    $total{$table}{values}++; $total{$table}{rows} += $n; $total{$table}{h_rows} += $hn;
    if ($apply) {
      $dbh->do( "UPDATE two_$table SET two_$table = ? WHERE two_$table = ?", undef, $new, $old );
      $dbh->do( "UPDATE h_two_$table SET two_$table = ? WHERE two_$table = ?", undef, $new, $old ); } } }

my @postFix = (			# joinkey, wrong two_post, correct two_post : the postcode was in two_city
  [ 'two2943',  'Illkirch', '67404' ],
  [ 'two17777', '08854',    '901 87' ] );
foreach my $fix (@postFix) {
  my ($joinkey, $old, $new) = @$fix;
  my ($n)  = $dbh->selectrow_array( "SELECT count(*) FROM two_post WHERE joinkey = ? AND two_post = ?", undef, $joinkey, $old );
  my ($hn) = $dbh->selectrow_array( "SELECT count(*) FROM h_two_post WHERE joinkey = ? AND two_post = ?", undef, $joinkey, $old );
  print join("\t", "two_post $joinkey", $old, $new, $n, $hn) . "\n";
  $total{post}{values}++; $total{post}{rows} += $n; $total{post}{h_rows} += $hn;
  if ($apply) {
    $dbh->do( "UPDATE two_post SET two_post = ? WHERE joinkey = ? AND two_post = ?", undef, $new, $joinkey, $old );
    $dbh->do( "UPDATE h_two_post SET two_post = ? WHERE joinkey = ? AND two_post = ?", undef, $new, $joinkey, $old ); } }

foreach my $table (sort keys %total) {
  print STDERR "two_$table\t$total{$table}{values} values\t$total{$table}{rows} rows\t$total{$table}{h_rows} h_rows\n"; }
if ($apply) { $dbh->commit; print STDERR "applied\n"; }
  else { $dbh->rollback; print STDERR "dry run, nothing changed.  ./fix_place_names.pl apply  to update\n"; }
$dbh->disconnect;

sub distinctValues {		# values in the data table and the h_ table, so wrong values only left in history get fixed too
  my $table = shift;
  my $values = $dbh->selectcol_arrayref( "SELECT $table FROM $table WHERE $table IS NOT NULL UNION SELECT $table FROM h_$table WHERE $table IS NOT NULL" );
  return @$values; }

sub mapText {			# table <tab> wrong value <tab> correct value
  return <<'END';
# foreign names to English
city	Sevilla	Seville
city	Milano	Milan
city	20139 Milano IT	Milan
city	Napoli	Naples
city	Padova	Padua
city	Torino	Turin
city	Roma	Rome
city	Genova	Genoa
city	Firenze	Florence
city	Wien	Vienna
city	A-1190 Wien	Vienna
city	Koeln	Cologne
city	Koln	Cologne
city	50674 Koeln	Cologne
city	Munchen	Munich
city	Muenchen	Munich
city	Nuernberg	Nuremberg
city	Gent	Ghent
city	B-9000 Gent	Ghent
city	B-9052 Gent	Ghent
city	9052Gent	Ghent
city	Gent-Zwijnaarde	Ghent
city	Antwerpen	Antwerp
city	Bruxelles	Brussels
city	Brussel	Brussels
city	Geneve	Geneva
city	Geneve 4	Geneva
city	CH-8093 Zuerich	Zurich
city	Lisboa	Lisbon
city	Warszawa	Warsaw
city	Praha	Prague
city	128 44 Praha 2	Prague
city	Goteborg	Gothenburg
city	Goeteborg	Gothenburg
city	Kobenhavn	Copenhagen
city	2500 BJ Den Haag	The Hague
city	Ciudad de Mexico	Mexico City
city	Mexico D.F.	Mexico City
city	Mexico DF	Mexico City
city	Mexico, D.F.	Mexico City
city	D.F.	Mexico City
city	Ciudad Autonoma de Buenos Aires	Buenos Aires
city	Santiago de Chile	Santiago
city	Santiago de Cali	Cali
city	Habana	Havana
city	Istambul	Istanbul
city	Patra	Patras
city	Bolos	Volos
city	GR-71110 Heraklion/Creta	Heraklion
city	Logronyo	Logrono
city	Navarra	Navarre
city	Makkah	Mecca
city	Kiev	Kyiv
state	Milano	Milan
state	Lombardia	Lombardy
state	Catalunya	Catalonia
state	Navarra	Navarre
state	Illes Balears	Balearic Islands
state	Bayern	Bavaria
state	Hessen	Hesse
state	Niedersachsen	Lower Saxony
state	Noord-Holland	North Holland
state	Zuid-Holland	South Holland
state	Creta	Crete
state	Andalucia	Andalusia
state	Peking	Beijing
state	Bozen	Bolzano
state	Fyn	Funen
state	Region Hovedstaden	Capital Region of Denmark
state	Bizkaia	Biscay
state	Makkah	Mecca
state	Mekkah	Mecca
state	Ad Dawhah	Doha
state	La Habana	Havana
state	Wien	Vienna
country	Turkey	Turkiye
# html entities
city	Valpara&#305;so	Valparaiso
city	Wroc&#322;aw	Wroclaw
city	&#8206;Kingstown&#8206;	Kingstown
# postcodes, Cedex and district numbers in city
city	1105 AZ Amsterdam	Amsterdam
city	1211 Geneva 4	Geneva
city	Geneva 4	Geneva
city	CH-1211 Geneva 4	Geneva
city	12489 Berlin	Berlin
city	14195 Berlin	Berlin
city	128 08 Prague 2	Prague
city	Prague 2	Prague
city	Prague 4	Prague
city	Prague 6	Prague
city	13009 Marseille	Marseille
city	13288 Marseille Cedex 09	Marseille
city	13288 Marseille Cedex 9	Marseille
city	13288 Marseille cedex 9	Marseille
city	Marseille 13284 cedex 07	Marseille
city	Marseille Cedex 09	Marseille
city	Marseille Cedex 5	Marseille
city	Marseille Cedex 9	Marseille
city	Marseille cedex 05	Marseille
city	13115, Saint-Paul-lez-Durance Cedex	Saint-Paul-lez-Durance
city	1411 DD Naarden	Naarden
city	1700 Fribourg	Fribourg
city	CH-1700 Fribourg	Fribourg
city	2100 Copenhagen O	Copenhagen
city	DK-2200 Copenhagen N	Copenhagen
city	21000 Dijon	Dijon
city	22455 Hamburg	Hamburg
city	2300 RC Leiden	Leiden
city	2333 CB Leiden	Leiden
city	Leiden 2333 RC	Leiden
city	RC Leiden	Leiden
city	2800 Kgs. Lyngby	Kongens Lyngby
city	30-387 Krakow	Krakow
city	3000 CA Rotterdam	Rotterdam
city	3000 DR Rotterdam	Rotterdam
city	3015 GE Rotterdam	Rotterdam
city	31000Toulouse- Midi-Pyrenees	Toulouse
city	31059 Toulouse cedex 9	Toulouse
city	31062 Toulouse Cedex 9	Toulouse
city	31400 Toulouse	Toulouse
city	31432 Toulouse Cedex 4	Toulouse
city	Toulouse cedex 4	Toulouse
city	34033 Montpellier	Montpellier
city	34033 Montpellier Cede	Montpellier
city	34060 Montpellier Cedex	Montpellier
city	34095 Montpellier cedex O5	Montpellier
city	34293 Montpellier Cedex 5	Montpellier
city	F34293 Montpellier cedex 5	Montpellier
city	Montpellier Cedex 5	Montpellier
city	3584 CG Utrecht	Utrecht
city	3584 CH Utrecht	Utrecht
city	3584 CT Utrecht	Utrecht
city	3584CT Utrecht	Utrecht
city	Utrecht 3584 CT	Utrecht
city	4070 Basel	Basel
city	CH - 4056 Basel	Basel
city	CH-4056 Basel	Basel
city	46010 Valencia	Valencia
city	5000 Cordoba	Cordoba
city	56321 Lorient Cedex	Lorient
city	6039 Root Langenbold	Root
city	60550 Verneuil en Halatte	Verneuil-en-Halatte
city	6500 HB Nijmegen	Nijmegen
city	66123Saarbrucken	Saarbrucken
city	6700 AA Wageningen	Wageningen
city	6708 PW Wageningen	Wageningen
city	6709 PD Wageningen	Wageningen
city	PB Wageningen	Wageningen
city	67404	Illkirch
city	67404 Illkirch	Illkirch
city	67404 Illkirch CEDE	Illkirch
city	67404 Illkirch Cedex	Illkirch
city	F-67400 Illkirch	Illkirch
city	69007 Lyon	Lyon
city	Lyon 69364	Lyon
city	Lyon 69373 cedex 08	Lyon
city	Lyon Cedex 07	Lyon
city	69012 Heidelberg	Heidelberg
city	69117 Heidelberg	Heidelberg
city	D-69120 Heidelberg	Heidelberg
city	Heidelberg 69120	Heidelberg
city	W-6900 Heidelberg 1	Heidelberg
city	69622 Villeurbanne Cedex	Villeurbanne
city	F-69622 Villeurbanne Cedex	Villeurbanne
city	72076 Tubingen	Tubingen
city	75 005 Paris	Paris
city	75005 Paris	Paris
city	75018 Paris	Paris
city	75730 Paris Cedex 15	Paris
city	75743 Paris Cedex 15	Paris
city	Paris Cedex 05	Paris
city	Paris Cedex 15	Paris
city	Paris cedex 05	Paris
city	Paris cedex 13	Paris
city	901 87	Umea
city	SE-901 87 Umea	Umea
city	91198 Gif-sur Yvette	Gif-sur-Yvette
city	91440 Bures sur Yvette	Bures-sur-Yvette
city	94805 Villejuif Cedex	Villejuif
city	A-1030 Vienna	Vienna
city	AT.1190 Vienna	Vienna
city	B-2470 Retie	Retie
city	BE-3000 Leuven	Leuven
city	Bangalore 560 058	Bangalore
city	Bucharest 17	Bucharest
city	CH-8057 Zurich	Zurich
city	CH-8091 Zurich	Zurich
city	CP 6128 succursale Centre-ville	Montreal
city	Clayton South MDC 3169	Clayton South
city	D-01307 Dresden	Dresden
city	D-03048 Cottbus	Cottbus
city	D-30625 Hannover	Hannover
city	D-35392 Giessen	Giessen
city	D-44780 Bochum	Bochum
city	D-65926 Frankfurt	Frankfurt
city	D-79106 Freibur	Freiburg
city	D-79106 Freiburg	Freiburg
city	D-82152 Martinsried/Muenchen	Martinsried
city	D-85354 Freising	Freising
city	Dublin 4	Dublin
city	F-17000 La Rochelle	La Rochelle
city	F-35043 Rennes Cedex	Rennes
city	F-67083 Strasbourg Cedex	Strasbourg
city	G12 8QQ	Glasgow
city	Grenoble Cedex 09	Grenoble
city	Grenoble Cedex 9	Grenoble
city	H-4012 Dote	Dote
city	Huddinge 141 89	Huddinge
city	S-141152 Huddinge	Huddinge
city	S-14183 Huddinge	Huddinge
city	N-5009 Bergen	Bergen
city	Nice Cedex 2	Nice
city	Nimes Cedex 09	Nimes
city	Nimes Cedex 2	Nimes
city	Oxford OX1 3QU	Oxford
city	Oxford OX1 3QX	Oxford
city	S-171 77 Stockholm	Stockholm
city	SE-106 91 Stockholm	Stockholm
city	S-431 83 Molndal	Molndal
city	SE-751 24 Uppsala	Uppsala
city	St Lucia QLD 4072	St Lucia
city	GG Eindhoven	Eindhoven
# typos
city	Dueseldorf	Dusseldorf
city	Goetingen	Gottingen
city	Gttingen	Gottingen
city	Utrech	Utrecht
city	UtrechtUtrecht	Utrecht
city	Braslia	Brasilia
city	Seaul	Seoul
city	Cheougju	Cheongju
city	RomeRome	Rome
city	Ferrera	Ferrara
city	Frederksberg	Frederiksberg
city	rederiksberg C	Frederiksberg C
city	Unea	Umea
city	Umea state	Umea
city	Sao Carlo	Sao Carlos
city	Dresded	Dresden
city	Dresdenv	Dresden
city	Posnan	Poznan
city	Krakaw	Krakow
city	Cracow	Krakow
city	Ottowa	Ottawa
city	Vacouver	Vancouver
city	Tel Aiv	Tel Aviv
city	Thuwa	Thuwal
city	Hsinch	Hsinchu
city	Postdam-Golm	Potsdam-Golm
city	OberschleiBheim	Oberschleissheim
city	ParisParis	Paris
city	llkirch	Illkirch
city	ILLKIRCH	Illkirch
city	Gif-sur-Yvett	Gif-sur-Yvette
city	Gothenbur	Gothenburg
city	Hud	Huddinge
city	Tromsoe	Tromso
city	Loerenskog	Lorenskog
city	Maceilo	Maceio
city	Nata	Natal
city	Novo Hamburg	Novo Hamburgo
city	Serto	Sertao
city	Campinass-Sao Paulo	Campinas
city	HendersonHenderson	Henderson
city	La Angeles	Los Angeles
city	Nashille	Nashville
city	Nashiville	Nashville
city	Nasheille	Nashville
city	Nashvillen	Nashville
city	State Collage	State College
city	South SanFrancisco	South San Francisco
city	South San Fransisco	South San Francisco
city	Asutin	Austin
city	Eugen	Eugene
city	Gainsville	Gainesville
city	Ithica	Ithaca
city	Marina del Ray	Marina del Rey
city	Neward	Newark
city	Birrmingham	Birmingham
city	Palo Ato	Palo Alto
city	Betheada	Bethesda
city	Rego park	Rego Park
city	Rolling Hills E	Rolling Hills Estates
city	Sta Cruz	Santa Cruz
city	Saint-Louis	Saint Louis
city	Edinburg	Edinburgh
city	East Lothain	East Lothian
city	Newcastle Upon Tyne	Newcastle upon Tyne
city	Bejing	Beijing
city	Peking	Beijing
city	Chendu	Chengdu
city	Changsh	Changsha
city	Whenzhou	Wenzhou
city	Chong Qing	Chongqing
city	Shen Zhen	Shenzhen
city	KaiFeng	Kaifeng
city	Huhhot	Hohhot
city	Yaan	Ya'an
city	Xian	Xi'an
city	Taian	Tai'an
city	Fu Jian	Fujian
city	LiaoNing	Liaoning
city	New Delh	New Delhi
city	Andhrapredesh	Andhra Pradesh
city	Sewagram	Sevagram
city	St lucia	St Lucia
city	CapeTown	Cape Town
city	Kuala Lumpu	Kuala Lumpur
city	Gelugo	Gelugor
# decided 2026 11 17
city	Beeevler	Ankara
city	Kyoyo	Kyoto
END
}
