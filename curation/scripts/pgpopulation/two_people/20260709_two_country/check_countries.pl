#!/usr/bin/env perl

# Check against state dept list that other entries are good
# https://2009-2017.state.gov/misc/list/index.htm
# but we found out this list does not have Turkiye nor United States of America
# list copy pasted below, wget not working on it.
#
# Ceci found a new list, copy pasted from that.  modified 'Turkey (Türkiye)' to 'Turkiye'
# https://www.state.gov/countries-and-areas-list
#
# Was going to update entries with Czech Republic to Czechia, but Ceci might do them manually, it's about 180
# 2026 07 09




use strict;
use Jex;	# mailer, getDate
use DBI;
use Dotenv -load => '/usr/lib/.env';

my $dbh = DBI->connect ( "dbi:Pg:dbname=$ENV{PSQL_DATABASE};host=$ENV{PSQL_HOST};port=$ENV{PSQL_PORT}", "$ENV{PSQL_USERNAME}", "$ENV{PSQL_PASSWORD}") or die "Cannot connect to database!\n";
# my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n";

my $result;

my %countries = %{ &getCountries() };
$countries{'United States of America'}++;
$countries{'Turkiye'}++;
$countries{'Czech Republic'}++;
# foreach my $country (sort keys %countries) { print qq($country\n); }

# $result = $dbh->prepare ( "SELECT DISTINCT(two_country) FROM two_country;" );
# $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
# while (my @row = $result->fetchrow ) {
#   unless ($countries{$row[0]}) { print qq(NO COUNTRY ${row[0]}--END\n); }
# } # while (my @row = $result->fetchrow )

$result = $dbh->prepare ( "SELECT * FROM two_country;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow ) {
  unless ($countries{$row[2]}) { print qq(NO COUNTRY @row\n); }
} # while (my @row = $result->fetchrow )


sub getCountries {
  # https://www.state.gov/countries-and-areas-list   2026 07 09
  my $country_text = <<'END';
Angola
Benin
Botswana
Burkina Faso
Burundi
Cabo Verde
Cameroon
Central African Republic
Chad
Comoros
Côte d’Ivoire
Democratic Republic of the Congo
Djibouti
Equatorial Guinea
Eritrea
Eswatini
Ethiopia
Gabon
The Gambia
Ghana
Guinea
Guinea-Bissau
Kenya
Lesotho
Liberia
Madagascar
Malawi
Mali
Mauritania
Mauritius
Mozambique
Namibia
Niger
Nigeria
Republic of the Congo
Rwanda
Sao Tome and Principe
Senegal
Seychelles
Sierra Leone
Somalia
South Africa
South Sudan
Sudan
Tanzania
Togo
Uganda
Zambia
Zimbabwe
    Australia
    Brunei
    Burma
    Cambodia
    China
    Cook Islands
    Fiji
    Indonesia
    Japan
    Kiribati
    Laos
    Malaysia
    Marshall Islands
    Micronesia
    Mongolia
    Nauru
    New Zealand
    Niue
    North Korea
    Palau
    Papua New Guinea
    Philippines
    Samoa
    Singapore
    Solomon Islands
    South Korea
    Taiwan
    Thailand
    Timor-Leste
    Tonga
    Tuvalu
    Vanuatu
    Vietnam
    Albania
    Andorra
    Armenia
    Austria
    Azerbaijan
    Belarus
    Belgium
    Bosnia and Herzegovina
    Bulgaria
    Croatia
    Cyprus
    Czechia
    Denmark
    Estonia
    Finland
    France
    Georgia
    Germany
    Greece
    Holy See
    Hungary
    Iceland
    Ireland
    Italy
    Kosovo
    Latvia
    Liechtenstein
    Lithuania
    Luxembourg
    Malta
    Moldova
    Monaco
    Montenegro
    Netherlands
    North Macedonia
    Norway
    Poland
    Portugal
    Romania
    Russia
    San Marino
    Serbia
    Slovakia
    Slovenia
    Spain
    Sweden
    Switzerland
    Turkiye
    Ukraine
    United Kingdom
    Algeria
    Bahrain
    Egypt
    Iran
    Iraq
    Israel
    Jordan
    Kuwait
    Lebanon
    Libya
    Morocco
    Oman
    Palestinian Territories
    Qatar
    Saudi Arabia
    Syria
    Tunisia
    United Arab Emirates
    Yemen
Afghanistan
Bangladesh
Bhutan
India
Kazakhstan
Kyrgyzstan
Maldives
Nepal
Pakistan
Sri Lanka
Tajikistan
Turkmenistan
Uzbekistan
Antigua and Barbuda
Argentina
The Bahamas
Barbados
Belize
Bolivia
Brazil
Canada
Chile
Colombia
Costa Rica
Cuba
Dominica
Dominican Republic
Ecuador
El Salvador
Grenada
Guatemala
Guyana
Haiti
Honduras
Jamaica
Mexico
Nicaragua
Panama
Paraguay
Peru
Saint Kitts and Nevis
Saint Lucia
Saint Vincent and the Grenadines
Suriname
Trinidad and Tobago
Uruguay
Venezuela
END

  my %countries = map { s/^\s+|\s+$//gr => 1 }
                  grep /\S/,
                  split /\n/, $country_text;
  return \%countries;
} # sub getCountries






sub getCountries2017 {
  # https://2009-2017.state.gov/misc/list/index.htm
  my $country_text = <<'END';
    Afghanistan
    Albania
    Algeria
    Andorra
    Angola
    Antigua and Barbuda
    Argentina
    Armenia
    Aruba
    Australia
    Austria
    Azerbaijan
    Bahamas, The
    Bahrain
    Bangladesh
    Barbados
    Belarus
    Belgium
    Belize
    Benin
    Bhutan
    Bolivia
    Bosnia and Herzegovina
    Botswana
    Brazil
    Brunei
    Bulgaria
    Burkina Faso
    Burma
    Burundi
    Cambodia
    Cameroon
    Canada
    Cabo Verde
    Central African Republic
    Chad
    Chile
    China
    Colombia
    Comoros
    Congo, Democratic Republic of the
    Congo, Republic of the
    Costa Rica
    Cote d'Ivoire
    Croatia
    Cuba
    Curacao
    Cyprus
    Czechia
    Denmark
    Djibouti
    Dominica
    Dominican Republic
    East Timor (see Timor-Leste)
    Ecuador
    Egypt
    El Salvador
    Equatorial Guinea
    Eritrea
    Estonia
    Ethiopia
    Fiji
    Finland
    France
    Gabon
    Gambia, The
    Georgia
    Germany
    Ghana
    Greece
    Grenada
    Guatemala
    Guinea
    Guinea-Bissau
    Guyana
    Haiti
    Holy See
    Honduras
    Hong Kong
    Hungary
    Iceland
    India
    Indonesia
    Iran
    Iraq
    Ireland
    Israel
    Italy
    Jamaica
    Japan
    Jordan
    Kazakhstan
    Kenya
    Kiribati
    Korea, North
    Korea, South
    Kosovo
    Kuwait
    Kyrgyzstan
    Laos
    Latvia
    Lebanon
    Lesotho
    Liberia
    Libya
    Liechtenstein
    Lithuania
    Luxembourg
    Macau
    Macedonia
    Madagascar
    Malawi
    Malaysia
    Maldives
    Mali
    Malta
    Marshall Islands
    Mauritania
    Mauritius
    Mexico
    Micronesia
    Moldova
    Monaco
    Mongolia
    Montenegro
    Morocco
    Mozambique
    Namibia
    Nauru
    Nepal
    Netherlands
    New Zealand
    Nicaragua
    Niger
    Nigeria
    North Korea
    Norway
    Oman
    Pakistan
    Palau
    Palestinian Territories
    Panama
    Papua New Guinea
    Paraguay
    Peru
    Philippines
    Poland
    Portugal
    Qatar
    Romania
    Russia
    Rwanda
    Saint Kitts and Nevis
    Saint Lucia
    Saint Vincent and the Grenadines
    Samoa
    San Marino
    Sao Tome and Principe
    Saudi Arabia
    Senegal
    Serbia
    Seychelles
    Sierra Leone
    Singapore
    Sint Maarten
    Slovakia
    Slovenia
    Solomon Islands
    Somalia
    South Africa
    South Korea
    South Sudan
    Spain
    Sri Lanka
    Sudan
    Suriname
    Swaziland
    Sweden
    Switzerland
    Syria
    Taiwan
    Tajikistan
    Tanzania
    Thailand
    Timor-Leste
    Togo
    Tonga
    Trinidad and Tobago
    Tunisia
    Turkey
    Turkmenistan
    Tuvalu
    Uganda
    Ukraine
    United Arab Emirates
    United Kingdom
    Uruguay
    Uzbekistan
    Vanuatu
    Venezuela
    Vietnam
    Yemen
    Zambia
    Zimbabwe
END

  my %countries = map { s/^\s+|\s+$//gr => 1 }
                  grep /\S/,
                  split /\n/, $country_text;
  return \%countries;
} # sub getCountries



__END__


