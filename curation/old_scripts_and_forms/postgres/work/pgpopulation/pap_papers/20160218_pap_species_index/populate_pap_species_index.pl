#!/usr/bin/perl -w

# populate taxons for the pap_species_index  2016 02 18

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my @pgcommands;
# my $infile = 'nematode_species_taxon.txt';
my $infile = 'short_species_list.txt';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) {
  chomp $line;
  my ($name, $taxonid) = split/\t/, $line;
  next unless ($taxonid =~ m/\d+/);
  if ($name =~ m/\'/) { $name =~ s/\'/''/g; }
  unless ($taxonid) { print qq(NO ID $line\n); next; }
  push @pgcommands, qq(INSERT INTO   pap_species_index VALUES \('$taxonid', '$name', NULL, 'two1843'\));
  push @pgcommands, qq(INSERT INTO h_pap_species_index VALUES \('$taxonid', '$name', NULL, 'two1843'\));
} # while (my $line = <IN>)
close (IN) or die "Cannot close $infile : $!";

# uncomment to wipe before populating
unshift @pgcommands, qq( DELETE FROM   pap_species_index; );
unshift @pgcommands, qq( DELETE FROM h_pap_species_index; );
foreach my $pgcommand (@pgcommands) {
  print qq($pgcommand\n);
# UNCOMMENT TO POPULATE
  $dbh->do( $pgcommand );
} # foreach my $pgcommand (@pgcommands)


__END__

Acanthocheilonema viteae	6277
Ancylostoma caninum	29170
Ancylostoma ceylanicum	53326
Ancylostoma duodenale	51022
Angiostrongylus cantonensis	6313
Angiostrongylus costaricensis	334426
Anisakis simplex	6269
Ascaris lumbricoides	6252
Ascaris suum	6253
Brugia malayi	6279
Brugia pahangi	6280
Brugia timori	42155
Bursaphelenchus xylophilus	6326
Caenorhabditis angaria	860376
Caenorhabditis brenneri	135651
Caenorhabditis briggsae	6238
Caenorhabditis elegans	6239
Caenorhabditis japonica	281687
Caenorhabditis nigoni	1611254
Caenorhabditis remanei	31234
Caenorhabditis sinica	497829
Caenorhabditis tropicalis	1561998
Cylicostephanus goldi	71465
Dictyocaulus viviparus	29172
Dirofilaria immitis	6287
Dracunculus medinensis	318479
Elaeophora elaphi	1147741
Enterobius vermicularis	51028
Globodera pallida	36090
Gongylonema pulchrum	637853
Haemonchus contortus	6289
Haemonchus placei	6290
Heligmosomoides polygyrus	375939
Heterorhabditis bacteriophora	37862
Heterorhabditis indica	51550
Litomosoides sigmodontis	42156
Loa loa	7209
Meloidogyne floridensis	298350
Meloidogyne hapla	6305
Meloidogyne incognita	6306
Necator americanus	51031
Nippostrongylus brasiliensis	27835
Oesophagostomum dentatum	61180
Onchocerca flexuosa	387005
Onchocerca ochengi	42157
Onchocerca volvulus	6282
Panagrellus redivivus	6233
Parascaris equorum	6256
Parastrongyloides trichosuri	131310
Pristionchus exspectatus	1195656
Pristionchus pacificus	54126
Rhabditophanes sp. KR3021	114890
Romanomermis culicivorax	13658
Soboliphyme baturini	241478
Steinernema carpocapsae	34508
Steinernema feltiae	52066
Steinernema glaseri	37863
Steinernema monticolum	90984
Steinernema scapterisci	90986
Strongyloides papillosus	174720
Strongyloides ratti	34506
Strongyloides stercoralis	6248
Strongyloides venezuelensis	75913
Strongylus vulgaris	40348
Syphacia muris	451379
Teladorsagia circumcincta	45464
Thelazia callipaeda	103827
Toxocara canis	6265
Trichinella nativa	6335
Trichinella spiralis	6334
Trichuris muris	70415
Trichuris suis	68888
Trichuris trichiura	36087
Wuchereria bancrofti	6293
Clonorchis sinensis	79923
Diphyllobothrium latum	60516
Echinococcus canadensis	519352
Echinococcus granulosus	6210
Echinococcus multilocularis	6211
Echinostoma caproni	27848
Fasciola hepatica	6192
Hydatigera taeniaeformis	6205
Hymenolepis diminuta	6216
Hymenolepis microstoma	85433
Hymenolepis nana	102285
Mesocestoides corti	53468
Opisthorchis viverrini	6198
Protopolystoma xenopodis	117903
Schistocephalus solidus	70667
Schistosoma curassoni	6186
Schistosoma haematobium	6185
Schistosoma japonicum	6182
Schistosoma mansoni	6183
Schistosoma margrebowiei	48269
Schistosoma mattheei	31246
Schistosoma rodhaini	6188
Schmidtea mediterranea	79327
Spirometra erinaceieuropaei	99802
Taenia asiatica	60517
Taenia solium	6204
Trichobilharzia regenti	157069
