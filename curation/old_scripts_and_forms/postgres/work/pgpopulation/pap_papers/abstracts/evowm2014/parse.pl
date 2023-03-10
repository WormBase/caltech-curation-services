#!/usr/bin/perl

# for Daniel / Jane.  Daniel sent a dos file, so reading by paragraphs didn't work, use
# dos2unix wbg_18.1.txt  
# to convert to good format
# Entered data  2010 01 20
#
# converted for pap_ tables's pap_match.pm  &processArrayOfHashes  2010 04 13
#
# read in 18.2 and 18.3  2011 01 18
#
# for iwm using processArrayOfHashes  2011 06 17
#
# converted for IWM2013, now using unaccent.pl to convert most bad character to unaccented
# characters, but still have some (like x) that have been converted manually at the source
# instead of through the &fixHtml routine.  Still using &findJunk to check for bad 
# characters.  2013 07 10
#
# updated for  evowm2014 .  need to comment out print statements.  Kimberly manaully fixing
# some characters that  Text::Unaccent  doesn't deal with.  2015 01 05
#
# live on tazendra.  2015 01 06


use lib qw( /home/postgres/work/pgpopulation/pap_papers/new_papers );
use pap_match qw ( processArrayOfHashes );

use strict;

my @array_of_hashes;
my %badChars;

$/ = undef;
my (@files) = </home/postgres/work/pgpopulation/pap_papers/abstracts/evowm2014/AbsFiles/*.txt>;
my $count = 0;
foreach my $infile (@files) { 
  $count++;
#   last if ($count > 1);
  &processFile($infile); }
$/ = "\n";

my $curator_id = 'two1843';
my $timestamp = "CURRENT_TIMESTAMP";
# my $timestamp = "'2010-04-12 12:00'";		# alternate format
  
  # UNCOMMENT TO RUN
# &processArrayOfHashes($curator_id, $timestamp, \@array_of_hashes);

foreach my $char (sort keys %badChars) { print "BAD $char BAD\n"; } 

sub processFile {
  my ($infile) = @_;

  open (IN, "<$infile") or die "Cannot open $infile : $!";
  my $file = <IN>;
  ($file) = &fixHtml($file);
  ($file) = &findJunk($file, $infile);


  my %hash;
  $hash{'year'} = 2014;
  $hash{'journal'} = "Evolutionary Biology of Caenorhabditis and Other Nematodes";
  $hash{'status'} = 'valid';
  $hash{'primary_data'} = 'not_designated';
  my @curation_flags = qw( author_person );
  $hash{'curation_flags'} = \@curation_flags;
  my @type = (); push @type, 'Meeting_abstract'; $hash{'type'} = \@type;

  if ($file =~ m/AbstractNo : (\d+)/) {
       my ($abs_num) = $file =~ m/AbstractNo : (\d+)/;
       my $identifier = 'evowm2014ab' . $abs_num;
print "ID $identifier\n";
       my @identifier; push @identifier, $identifier; $hash{'identifier'} = \@identifier; }
    else { print "ERR NO ABSTRACT number $infile\n"; }

  my ($title) = $file =~ m/Title : (.+)/;
  $title =~ s/<br>//g;
  if ($title) { 
print "TITLE $title\n";
    $hash{'title'} = $title; }

  if ( $file =~ m/Body of Abstract : (.+)/) {
    my ($abstract) = $file =~ m/Body of Abstract : (.+)/;
    $abstract =~ s/<p>/\n/g;
    $abstract =~ s/<br>/\n/g;
    $abstract =~ s/<ol>//g;
    $abstract =~ s/<\/ol>//g;
    $abstract =~ s/<li>//g;
    $abstract =~ s/<\/li>//g;
    $abstract =~ s/&#60;/</g;
    $abstract =~ s/&#62;/>/g;
print "ABS $abstract\n";
    $hash{'abstract'} = $abstract; }


# print "FILE $file FILE\n";
  my (@auths) = $file =~ m/\nAuthor \d+ : (.+)/g;
  if (scalar(@auths) > 0) { $hash{'author'} = \@auths; }
foreach my $auth (@auths) { print "AU $auth TH\n"; }
  my (@insts) = $file =~ m/Institution (.+)/g;
  my %institution; my %authors; my @affiliation;
  foreach my $inst (@insts) { 
    my ($num, $val) = $inst =~ m/^(\d+) : (.*?)$/;
    unless ($val) { print "ERR NO INST VALUE $inst $infile\n"; }
    $val =~ s/<i>//g; $val =~ s/<\/i>//g;
    $institution{$num} = $val;
    push @affiliation, $val;
  }
  if (scalar(@affiliation) > 0) { 
print "AFF @affiliation\n";
    $hash{'affiliation'} = \@affiliation; }

#   my (@auths) = $file =~ m/\nAuthor (.+)/g;
#   foreach my $auth (@auths) { 
#     next unless ($auth);
#     if ($auth =~ m/(\d+) Affiliation : (\d+)/) { $authors{$1}{aff} = $institution{$2}; }
#     else { 
#       my ($num, $name) = $auth =~ m/(\d+) : (.+)/; 
#       $name =~ s/<i>//g; $name =~ s/<\/i>//g;
#       $authors{$num}{name} = $name; }
#   } # foreach my $auth (@auths)

  push @array_of_hashes, \%hash;
} # sub processFile




sub padZeros {
  my $joinkey = shift;
  if ($joinkey =~ m/^0+/) { $joinkey =~ s/^0+//g; }
  if ($joinkey < 10) { $joinkey = '000' . $joinkey; }
  elsif ($joinkey < 100) { $joinkey = '00' . $joinkey; }
  elsif ($joinkey < 1000) { $joinkey = '0' . $joinkey; }
  return $joinkey;
} # sub padZeros

my %single;
$single{'status'}++;
$single{'title'}++;
$single{'journal'}++;
$single{'publisher'}++;
$single{'volume'}++;
$single{'pages'}++;
$single{'year'}++;
$single{'month'}++;
$single{'day'}++;
$single{'pubmed_final'}++;
$single{'primary_data'}++;
$single{'abstract'}++;

my %multi;
$multi{'editor'}++;
$multi{'type'}++;
$multi{'author'}++;
$multi{'affiliation'}++;
$multi{'fulltext_url'}++;
$multi{'contained_in'}++;
$multi{'gene'}++;
$multi{'identifier'}++;
$multi{'ignore'}++;
$multi{'remark'}++;
$multi{'erratum_in'}++;
$multi{'internal_comment'}++;
$multi{'curation_flags'}++;
$multi{'electronic_path'}++;
$multi{'author_possible'}++;
$multi{'author_sent'}++;
$multi{'author_verified'}++;


# foreach my $hash_ref (@array_of_hashes) {
#   my %hash = %$hash_ref;
#   foreach my $table (sort keys %hash) {
#     if ($multi{$table}) {  
#         my $array_ref = $hash{$table};
#         my @array = @$array_ref;
#         foreach my $data (@array) {
#           print "MULTI pap_$table $data\n"; } }
#       else {
#         my $data = $hash{$table};
#         print "SINGLE pap_$table $data\n"; }
#   } # foreach my $table (sort keys %hash)
# } # foreach my $hash_ref (@array_of_hashes)
 
sub fixHtml {
  my $file = shift;
  $file =~ s/<b>//g;
  $file =~ s/<\/b>//g;
  $file =~ s/<u>//g;
  $file =~ s/<\/u>//g;
  $file =~ s/<i>//ig;
  $file =~ s/<\/i>//ig;
  $file =~ s/<font.*?>(.*?)<\/font>/$1/g;
  $file =~ s/<sup>(.*?)<\/sup>/$1/g;
  $file =~ s/<sub>(.*?)<\/sub>/$1/g;
  $file =~ s///g;
  $file =~ s/&nbsp;/ /g;
  $file =~ s/&ndash;/-/g;
  $file =~ s/&#37;/%/g;
  $file =~ s/&#145;/'/g;
  $file =~ s/&#146;/'/g;
  $file =~ s/&#147;/"/g;
  $file =~ s/&#148;/"/g;
  $file =~ s/&#149;//g;
  $file =~ s/&#151;/-/g;
  $file =~ s/&#153;//g;
  $file =~ s/&#163;//g;
  $file =~ s/&#171;//g;
  $file =~ s/&#174;//g;
  $file =~ s/&#176;/ deg /g;
  $file =~ s/&#177;/ plus or minus /g;
  $file =~ s/&#187;//g;
  $file =~ s/&#224;/a/g;
  $file =~ s/&#225;/a/g;
  $file =~ s/&#226;/a/g;
  $file =~ s/&#227;/a/g;
  $file =~ s/&#228;/a/g;
  $file =~ s/&#229;/a/g;
  $file =~ s/&#230;/ae/g;
  $file =~ s/&#231;/c/g;
  $file =~ s/&#232;/e/g;
  $file =~ s/&#233;/e/g;
  $file =~ s/&#234;/e/g;
  $file =~ s/&#235;/e/g;
  $file =~ s/&#236;/i/g;
  $file =~ s/&#237;/i/g;
  $file =~ s/&#238;/i/g;
  $file =~ s/&#239;/i/g;
  $file =~ s/&#240;/o/g;
  $file =~ s/&#241;/n/g;
  $file =~ s/&#242;/o/g;
  $file =~ s/&#243;/o/g;
  $file =~ s/&#244;/o/g;
  $file =~ s/&#245;/o/g;
  $file =~ s/&#246;/o/g;
  $file =~ s/&#247;//g;
  $file =~ s/&#248;/o/g;
  $file =~ s/&#249;/u/g;
  $file =~ s/&#250;/u/g;
  $file =~ s/&#251;/u/g;
  $file =~ s/&#252;/u/g;
  $file =~ s/&#253;/y/g;
  $file =~ s/&#254;//g;
  $file =~ s/&#255;/y/g;
  $file =~ s/\&\#;//g;
  return $file;
} # sub fixHtml

sub findJunk {
  my ($para, $infile) = @_;
  ($para) = &filterJunk($para);
#   my (@words) = split/\s+/, $para;
#   foreach my $word (@words) {
    if ($para =~ m/[^\s\w\~\`\!\@\#\$\%\^\&\*\(\)\-\=\+\[\]\{\}\;\:\'\"\,\<\.\>\/\?\\\|]/) {
#       my (@bad) = $para =~ m/\b(.*?[^\s\w\!\@\#\$\%\^\&\*\(\)\-\=\+\[\]\{\}\;\:\'\"\,\<\.\>\/\?\\\|].*?)\b/g;
      my (@bad) = $para =~ m/(.{0,8}[^\s\w\~\`\!\@\#\$\%\^\&\*\(\)\-\=\+\[\]\{\}\;\:\'\"\,\<\.\>\/\?\\\|].{0,8})/g;
#       foreach (@bad) { $badChars{$_}++; print "$_ : $para\n"; }
#       foreach (@bad) { $badChars{$_}++; }
      foreach (@bad) { $badChars{$_}++; print "$_ IN $infile\n"; }	 # To show what file has the bad characters
    }
#   }
  return $para;
} # sub findJunk

sub filterJunk {
  my $para = shift;

  $para =~ s/  \(A\) Fr.kj.r-Jen/  \(A\) Frokjaer-Jen/g;
  $para =~ s/  2. Ozl. et al. /  2. Ozlu et al. /g;
  $para =~ s/ 2 : Col.n-Ramos,/ 2 : Colon-Ramos,/g;
  $para =~ s/ 2 : Mor.n, Tom.s/ 2 : Moran, Tomas/g;
  $para =~ s/ 2 : Ume. Center / 2 : Umea Center /g;
  $para =~ s/ 3 : Col.n-Ramos,/ 3 : Colon-Ramos,/g;
  $para =~ s/ 4 : Col.n-Ramos,/ 4 : Colon-Ramos,/g;
  $para =~ s/ 7 : Col.n-Ramos,/ 7 : Colon-Ramos,/g;
  $para =~ s/ 8 : Cer.n, Juli./ 8 : Ceron, Julia/g;
  $para =~ s/ 9 : Cer.n, Juli./ 9 : Ceron, Julia/g;
  $para =~ s/e \(Frokj.r-Jensen/e \(Frokjaer-Jensen/g;
  $para =~ s/r 2 : Fr.kj.r Jen/r 2 : Frokjaer Jen/g;
  $para =~ s/r 6 : Fr.kj.r-Jen/r 6 : Frokjaer-Jen/g;
  $para =~ s/ : Kampk.tter, A./ : Kampkotter, A./g;
  $para =~ s/ : Nystr.m-Friber/ : Nystrom-Friber/g;
  $para =~ s/ Aristiz.bal, Dav/ Aristizabal, Dav/g;
  $para =~ s/ GH Piti.-Salp.tr/ GH Pitie-Salpetr/g;
  $para =~ s/ Quebec . Montr.a/ Quebec a Montrea/g;
  $para =~ s/ San Jos. State U/ San Jose State U/g;
  $para =~ s/ San Jos., Califo/ San Jose, Califo/g;
  $para =~ s/ cell \(B.rglin et/ cell \(Burglin et/g;
  $para =~ s/ deg C 6.9cm agar/ deg C 6x9cm agar/g;
  $para =~ s/ et de D.veloppem/ et de Developpem/g;
  $para =~ s/ on La R.union, a/ on La Reunion, a/g;
  $para =~ s/, 8057 Z.rich, Sw/, 8057 Zurich, Sw/g;
  $para =~ s/, Charit.-Univers/, Charite-Univers/g;
  $para =~ s/. About . of thes/. About 1\/4 of thes/g;
  $para =~ s/. U. Cat.lica de /. U. Catolica de /g;
  $para =~ s/., Barri.re, A., /., Barriere, A., /g;
  $para =~ s/1 : Lain., Vivian/1 : Laine, Vivian/g;
  $para =~ s/3 : Mart.nez, Alf/3 : Martinez, Alf/g;
  $para =~ s/3 or 7.5.C rise i/3 or 7.5degC rise i/g;
  $para =~ s/4 : Garc.a, L. Re/4 : Garcia, L. Re/g;
  $para =~ s/73, La R.union\). /73, La Ruunion\). /g;
  $para =~ s/9\), Piti.-Salp.tr/9\), Pitie-Salpetr/g;
  $para =~ s/94000 Cr.teil and/94000 Creteil and/g;
  $para =~ s/94000 Cr.teil, Fr/94000 Creteil, Fr/g;
  $para =~ s/: Facult. de Phar/: Faculte de Phar/g;
  $para =~ s/: Louren.o, Guine/: Lourenco, Guine/g;
  $para =~ s/>   1. G.nczy et />   1. Gonczy et /g;
  $para =~ s/C. At 25. C, ther/C. At 25deg C, ther/g;
  $para =~ s/Fisiolog.a Celula/Fisiologia Celula/g;
  $para =~ s/C, Montr.al, Cana/C, Montreal, Cana/g;
  $para =~ s/III, Sch.nzlestr./III, Schanzlestr./g;
  $para =~ s/Nuez & F.lix\).<br/Nuez & Felix\).<br/g;
  $para =~ s/Ole Maal.es Vej 5/Ole Maaloes Vej 5/g;
  $para =~ s/Ole Maal.esvej 5,/Ole Maaloesvej 5,/g;
  $para =~ s/Ole Mall.s vej 5,/Ole Mallos vej 5,/g;
  $para =~ s/S\), Unit. de Rech/S\), Unite de Rech/g;
  $para =~ s/Senior-L.ken synd/Senior-Loken synd/g;
  $para =~ s/Thomas S.dhof \(St/Thomas Sudhof \(St/g;
  $para =~ s/U1264 \(F.lix & al/U1264 \(Felix & al/g;
  $para =~ s/UCPQ, Qu.bec, Qc,/UCPQ, Quebec, Qc,/g;
  $para =~ s/a, Logro.o, Spain/a, Logrono, Spain/g;
  $para =~ s/ad de Qu.mica-Uni/ad de Quimica-Uni/g;
  $para =~ s/an de Ci.ncia, Oe/an de Ciencia, Oe/g;
  $para =~ s/d, Logro.o, La Ri/d, Logrono, La Ri/g;
  $para =~ s/de Montr.al - IRI/de Montreal - IRI/g;
  $para =~ s/e Associ.e CEA-CN/e Associee CEA-CN/g;
  $para =~ s/e to 0.3.C increa/e to 0.3degC increa/g;
  $para =~ s/e-Anne F.lix \(str/e-Anne Felix \(str/g;
  $para =~ s/ea and M.nster \(R/ea and Munster \(R/g;
  $para =~ s/ed by na.ve C. el/ed by naive C. el/g;
  $para =~ s/ed to na.ve C. el/ed to naive C. el/g;
  $para =~ s/elle, Cr.teil, Fr/elle, Creteil, Fr/g;
  $para =~ s/ences, Z.rich, Sw/ences, Zurich, Sw/g;
  $para =~ s/epken, J.licher, /epken, Julicher, /g;
  $para =~ s/er of Kr.ppel-lik/er of Kruppel-lik/g;
  $para =~ s/fense \(F.lix & al/fense \(Felix & al/g;
  $para =~ s/gy and Z.rich Cen/gy and Zurich Cen/g;
  $para =~ s/hnique F.d.rale d/hnique Federale d/g;
  $para =~ s/horts na.ve to ni/horts naive to ni/g;
  $para =~ s/in the B.rglin la/in the Burglin la/g;
  $para =~ s/inas Vel.zquez, L/inas Velazquez, L/g;
  $para =~ s/ition, H.lsov.gen/ition, Halsovagen/g;
  $para =~ s/itute, G.ttingen,/itute, Gottingen,/g;
  $para =~ s/ity of Z.rich UZH/ity of Zurich UZH/g;
  $para =~ s/ity of Z.rich, In/ity of Zurich, In/g;
  $para =~ s/l, E., F.lix, M.-/l, E., Felix, M.-/g;
  $para =~ s/l. In na.ve anima/l. In naive anima/g;
  $para =~ s/logne, Z.lpicher /logne, Zulpicher /g;
  $para =~ s/logy, U.. of Brit/logy, U.o of Brit/g;
  $para =~ s/lva-Garc.a, Carlo/lva-Garcia, Carlo/g;
  $para =~ s/n ORF \(F.lix & al/n ORF \(Felix & al/g;
  $para =~ s/ne, Fran.ois-Xavi/ne, Francois-Xavi/g;
  $para =~ s/niversit.t Frankf/niversitat Frankf/g;
  $para =~ s/niversit.t, Frank/niversitat, Frank/g;
  $para =~ s/niversit. Laval, /niversite Laval, /g;
  $para =~ s/niversit. Lyon 1,/niversite Lyon 1,/g;
  $para =~ s/niversit. Paris 7/niversite Paris 7/g;
  $para =~ s/niversit. de Bord/niversite de Bord/g;
  $para =~ s/ns of na.ve, adap/ns of naive, adap/g;
  $para =~ s/ntana-Nu.ez, Dian/ntana-Nunez, Dian/g;
  $para =~ s/ogie mol.culaire /ogie moleculaire /g;
  $para =~ s/olate \(F.lix et a/olate \(Felix et a/g;
  $para =~ s/on at 25. C. Elim/on at 25deg C. Elim/g;
  $para =~ s/onal Aut.noma de /onal Autonoma de /g;
  $para =~ s/or 1 : B.licard, /or 1 : Belicard, /g;
  $para =~ s/or 1 : C.ceres, I/or 1 : Caceres, I/g;
  $para =~ s/or 1 : F.lix, Mar/or 1 : Felix, Mar/g;
  $para =~ s/or 1 : M.ller, Ti/or 1 : Moller, Ti/g;
  $para =~ s/or 1 : M.ller, Mi/or 1 : Muller, Mi/g;
  $para =~ s/or 1 : S.enz-Narc/or 1 : Saenz-Narc/g;
  $para =~ s/or 1 : W.hlby, Ca/or 1 : Wahlby, Ca/g;
  $para =~ s/or 2 : B.nard, Cl/or 2 : Benard, Cl/g;
  $para =~ s/or 2 : B.chter, C/or 2 : Buchter, C/g;
  $para =~ s/or 2 : C.ceras, I/or 2 : Caceras, I/g;
  $para =~ s/or 2 : G.mez-Orte/or 2 : Gomez-Orte/g;
  $para =~ s/or 2 : J.ntti, Ju/or 2 : Jantti, Ju/g;
  $para =~ s/or 3 : B.hler, Al/or 3 : Buhler, Al/g;
  $para =~ s/or 3 : B.rglin, T/or 3 : Burglin, T/g;
  $para =~ s/or 3 : W.hlby, Ca/or 3 : Wahlby, Ca/g;
  $para =~ s/or 4 : D.az, Mòni/or 4 : Diaz, Mòni/g;
  $para =~ s/or 4 : G.mez-Orte/or 4 : Gomez-Orte/g;
  $para =~ s/or 4 : M.ller-Rei/or 4 : Muller-Rei/g;
  $para =~ s/or 5 : P.nigault,/or 5 : Penigault,/g;
  $para =~ s/or 6 : B.licard, /or 6 : Belicard, /g;
  $para =~ s/or 6 : B.rglin, T/or 6 : Burglin, T/g;
  $para =~ s/or 6 : D.valos, V/or 6 : Davalos, V/g;
  $para =~ s/or 6 : D.glon, Ni/or 6 : Deglon, Ni/g;
  $para =~ s/or 6 : K.nzler, M/or 6 : Kunzler, M/g;
  $para =~ s/or 6 : N.ri, Chri/or 6 : Neri, Chri/g;
  $para =~ s/or 7 : F.lix, Mar/or 7 : Felix, Mar/g;
  $para =~ s/or 7 : N..r, Ande/or 7 : Naar, Ande/g;
  $para =~ s/or 9 : B.rglin, T/or 9 : Burglin, T/g;
  $para =~ s/pment \(B.low and /pment \(Bulow and /g;
  $para =~ s/r 13 : F.lix, M.A/r 13 : Felix, M.A/g;
  $para =~ s/r 2 : Gr.n, Domin/r 2 : Grun, Domin/g;
  $para =~ s/r 2 : Mu.oz, Javi/r 2 : Munoz, Javi/g;
  $para =~ s/r 3 : Kn.lker, Ha/r 3 : Knolker, Ha/g;
  $para =~ s/r 5 : Fr.hli, Eri/r 5 : Frohli, Eri/g;
  $para =~ s/r 5 : Su.rez-L.pe/r 5 : Suarez-Lope/g;
  $para =~ s/r 9 : Gr.newald, /r 9 : Grunewald, /g;
  $para =~ s/rc Cient.fic de B/rc Cientific de B/g;
  $para =~ s/receptor. ITR-1. /receptor ITR-1. /g;
  $para =~ s/rie Biom.dicale \(/rie Biomedicale \(/g;
  $para =~ s/robiolog.a, Insti/robiologia, Insti/g;
  $para =~ s/rom La R.union, C/rom La Reunion, C/g;
  $para =~ s/rom La R.union. T/rom La Reunion. T/g;
  $para =~ s/rom the . Old wor/rom the Old wor/g;
  $para =~ s/rs at 20.C and ha/rs at 20degC and ha/g;
  $para =~ s/s for na.ve, afte/s for naive, afte/g;
  $para =~ s/sis, Ume. Univers/sis, Umea Univers/g;
  $para =~ s/ssariat . l'Energ/ssariat a l'Energ/g;
  $para =~ s/t-7 and .mir-35 a/t-7 and mir-35 a/g;
  $para =~ s/try, Ume. Univers/try, Umea Univers/g;
  $para =~ s/ty at 15. and 20./ty at 15deg and 20deg/g;
  $para =~ s/ual's na.ve level/ual's naive level/g;
  $para =~ s/us. La R.union re/us. La Reunion re/g;
  $para =~ s/ut Europ.en de Ch/ut Europeen de Ch/g;
  $para =~ s/y 2.5 k . 2 k\), t/y 2.5 k x 2 k\), t/g;
  $para =~ s/y. In na.ve anima/y. In naive anima/g;
  $para =~ s/ : Sorka., Altar/ : Sorkac, Altar/g;
  $para =~ s/1 : Dalf., Diana/1 : Dalfo, Diana/g;
  $para =~ s/2 : Teot.nio, H./2 : Teotonio, H./g;
  $para =~ s/3 : Schr.der, V./3 : Schroder, V./g;
  $para =~ s/cas, Mar.a Pilar/cas, Maria Pilar/g;
  $para =~ s/ Aydin, .zge Z./ Aydin, Ozge Z./g;
  $para =~ s/iard, St.phanie/iard, Stephanie/g;
  $para =~ s/ondeau, .velyne/ondeau, Evelyne/g;
  $para =~ s/ Piti.-Salp.tr/ Pitie-Salpetr/g;
  $para =~ s/ San Jos., CA./ San Jose, CA./g;
  $para =~ s/haux, Gr.goire/haux, Gregoire/g;
  $para =~ s/nchen, M.nchen/nchen, Munchen/g;
  $para =~ s/tier, Fr.d.ric/tier, Frederic/g;
  $para =~ s/radin, H.l.ne/radin, Helene/g;
  $para =~ s/ller, Cl.ment/ller, Clement/g;
  $para =~ s/Hench, J.rgen/Hench, Jurgen/g;
  $para =~ s/Bicep, C.dric/Bicep, Cedric/g;
  $para =~ s/, Z.rich, Sw/, Zurich, Sw/g;
  $para =~ s/ois, Aur.lie/ois, Aurelie/g;
  $para =~ s/spin, Ma.lle/spin, Maelle/g;
  $para =~ s/ld . are sen/ld are sen/g;
  $para =~ s/ea, Andr.s G/ea, Andres G/g;
  $para =~ s/ernet, R.mi/ernet, Remi/g;
  $para =~ s/Qu.bec, Qc,/Quebec, Qc,/g;
  $para =~ s/M.xico, M./Mexico, Me/g;
  $para =~ s/gnard, L.o/gnard, Leo/g;
  $para =~ s/i.re Hospi/iere Hospi/g;
  $para =~ s/i.re, Depa/iere, Depa/g;
  $para =~ s/ncarnaci.n/ncarnacion/g;
  $para =~ s/n, Shant./n, Shante/g;
  $para =~ s/obs, Ren./obs, Rene/g;
  $para =~ s/AT, Mait./AT, Maite/g;
  $para =~ s/Jr., Sim./Jr., Simo/g;
  $para =~ s/arc-Andr./arc-Andre/g;
  $para =~ s/z, Luc.a/z, Lucia/g;
  $para =~ s/er.nica/eronica/g;

  $para =~ s/ Quebec . Montr.a/ Quebec a Montrea/g;
  $para =~ s/or 4 : D.az, M.ni/or 4 : Diaz, Moni/g;
  $para =~ s/2 : Dalf., Diana/2 : Dalfo, Diana/g;
  $para =~ s/card, Fr.d.ric/card, Frederic/g;
  $para =~ s/, L. Ren./, L. Rene/g;


  $para =~ s/H.ken, K/Huken, K/g;
  $para =~ s/H.ken et al/Huken et al/g;
  $para =~ s/D.seldorf/Duseldorf/g;
  $para =~ s/H.sken, K/Husken, K/g;
  $para =~ s/H.sken et al/Husken et al/g;
  $para =~ s/D.sseldorf/Dusseldorf/g;
  $para =~ s/1 : Ume. Center /1 : Umea Center /g;
  $para =~ s/2 : Mel.ndez, Al/2 : Melendez, Al/g;
  $para =~ s/2 : Ram.rez, Jor/2 : Ramirez, Jor/g;
  $para =~ s/2 : Sch.fer, Pat/2 : Schafer, Pat/g;
  $para =~ s/2 : Sch.ler, Lon/2 : Scholer, Lon/g;
  $para =~ s/2004; B.low et a/2004; Bulow et a/g;
  $para =~ s/3 : Mel.ndez, A./3 : Melendez, A./g;
  $para =~ s/4 : Cer.n, Juli./4 : Ceron, Julia/g;
  $para =~ s/4 : Mel.ndez, Al/4 : Melendez, Al/g;
  $para =~ s/5 : Mel.ndez, Al/5 : Melendez, Al/g;
  $para =~ s/: Barri.re, Anto/: Barriere, Anto/g;
  $para =~ s/: Colai.covo, Mo/: Colaiacovo, Mo/g;
  $para =~ s/: Monta.ana Sanc/: Montanana Sanc/g;
  $para =~ s/Inst, T.bingen, /Inst, Tubingen, /g;
  $para =~ s/PharmaQ.M, BioMe/PharmaQaM, BioMe/g;
  $para =~ s/PharmaQ.M, Biome/PharmaQaM, Biome/g;
  $para =~ s/St-Fran.ois, Chr/St-Francois, Chr/g;
  $para =~ s/UNAM, M.xico, D./UNAM, Mexico, D./g;
  $para =~ s/. Montr.al, Mont/a Montreal, Mont/g;
  $para =~ s/, Montr.al, Qu.b/, Montreal, Queb/g;
  $para =~ s/ Robe R.ssle-Str/ Robe Rossle-Str/g;
  $para =~ s/ at 25 .C they a/ at 25 degC they a/g;
  $para =~ s/97082 W.rzburg, /97082 Wurzburg, /g;
  $para =~ s/UNAM, M.xico D.F/UNAM, Mexico D.F/g;
  $para =~ s/ \[1\] Ol.hov. M, / [1] Olahova M, /g;
  $para =~ s/ du Mus.e 10, 17/ du Musee 10, 17/g;
  $para =~ s/sup> Fr.kjaer-Je/sup> Frokjaer-Je/g;
  $para =~ s/ : Boss., Gabrie/ : Bosse, Gabrie/g;
  $para =~ s/ : Gonz.lez-P.re/ : Gonzalez-Pere/g;
  $para =~ s/ : Labb., Jean-C/ : Labbe, Jean-C/g;
  $para =~ s/ : Coll.ge de Fr/ : College de Fr/g;
  $para =~ s/3 2. Fr.kj.r-Jen/3 2. Frokjaer-Jen/g;
  $para =~ s/ Osnabr.ck, Germ/ Osnabruck, Germ/g;
  $para =~ s/\/i> \(Fr.kj.r-Jen/\/i> (Frokjaer-Jen/g;
  $para =~ s/iversit. Cellula/iversite Cellula/g;
  $para =~ s/obert-R.ssle-Str/obert-Rossle-Str/g;
  $para =~ s/. Tavar. and P. /. Tavare and P. /g;
  $para =~ s/enior-L.ken \(SLS/enior-Loken (SLS/g;
  $para =~ s/nne, Rh.ne-Alpes/nne, Rhone-Alpes/g;
  $para =~ s/tory, M.ggelseed/tory, Muggelseed/g;
  $para =~ s/x Delbr.ck Cente/x Delbruck Cente/g;
  $para =~ s/x Delbr.ck Centr/x Delbruck Centr/g;
  $para =~ s/ryos \(G.nczy et /ryos (Gonczy et /g;
  $para =~ s/k at 33. for 2 h/k at 33deg for 2 h/g;
  $para =~ s/iterran.e, Franc/iterranee, Franc/g;
  $para =~ s/ \(Barri.re and F/ (Barriere and F/g;
  $para =~ s/ Biolog.a Celula/ Biologia Celula/g;
  $para =~ s/ at 25 .C but no/ at 25 degC but no/g;
  $para =~ s/ at 25 .C. While/ at 25 degC. While/g;
  $para =~ s/c Montr.al \(UQ.M/c Montreal (UQÀM/g;
  $para =~ s/nces, S.dert.rn /nces, Sodertorn /g;
  $para =~ s/nces, S.rdert.rn/nces, Sordertorn/g;
  $para =~ s/ntrum f.r Medizi/ntrum fur Medizi/g;
  $para =~ s/rsity W.rzburg, /rsity Wurzburg, /g;
  $para =~ s/t and S.dert.rn /t and Sodertorn /g;
  $para =~ s/tics, K.ln, Germ/tics, Koln, Germ/g;
  $para =~ s/ Osnabr.ck, Fach/ Osnabruck, Fach/g;
  $para =~ s/. 1. Fr.kj.r-Jen/. 1. Frokjaer-Jen/g;
  $para =~ s/ne, Ume. Univers/ne, Umea Univers/g;
  $para =~ s/que Mol.culaire /que Moleculaire /g;
  $para =~ s/tion, S.dert.rn /tion, Sodertorn /g;
  $para =~ s/ty of Z.rich, Sw/ty of Zurich, Sw/g;
  $para =~ s/ty, Ume., Sweden/ty, Umea, Sweden/g;
  $para =~ s/, Montr.al, Qu.b/, Montreal, Queb/g;
  $para =~ s/esen, S.ren-Pete/esen, Soren-Pete/g;
  $para =~ s/ogy, Sp.thstr. 8/ogy, Spathstr. 8/g;
  $para =~ s/y of Kr.ppel-lik/y of Kruppel-lik/g;
  $para =~ s/ale Sup.rieure L/ale Superieure L/g;
  $para =~ s/ale Sup.rieure, /ale Superieure, /g;
  $para =~ s/es, Jos.-Eduardo/es, Jose-Eduardo/g;
  $para =~ s/ches \(B.low <i>e/ches (Bulow <i>e/g;
  $para =~ s/iversit.t Duisbu/iversitat Duisbu/g;
  $para =~ s/iversit.t M.nche/iversitat Munche/g;
  $para =~ s/iversit.t zu Ber/iversitat zu Ber/g;
  $para =~ s/iversit.tsstr. 5/iversitatsstr. 5/g;
  $para =~ s/iversit. Claude /iversite Claude /g;
  $para =~ s/iversit. Montpel/iversite Montpel/g;
  $para =~ s/iversit. Paris D/iversite Paris D/g;
  $para =~ s/iversit. Paris-S/iversite Paris-S/g;
  $para =~ s/iversit. de Lyon/iversite de Lyon/g;
  $para =~ s/iversit. de Mont/iversite de Mont/g;
  $para =~ s/iversit. de Stra/iversite de Stra/g;
  $para =~ s/iversit. de la M/iversite de la M/g;
  $para =~ s/iversit. du Q.éb/iversite du Queb/g;
  $para =~ s/tre, Qu.bec, Qu./tre, Quebec, Que/g;
  $para =~ s/gie Mol.culaire /gie Moleculaire /g;
  $para =~ s/gie mol.culaire,/gie moleculaire,/g;
  $para =~ s/logy, T.bingen, /logy, Tubingen, /g;
  $para =~ s/mes \(Li.geois et/mes (Liegeois et/g;
  $para =~ s/n 2 : D.partemen/n 2 : Départemen/g;
  $para =~ s/n 2 : S.dert.rns/n 2 : Sodertorns/g;
  $para =~ s/ndeau, .velyne L/ndeau, Evelyne L/g;
  $para =~ s/r 1 : B.nard, Cl/r 1 : Benard, Cl/g;
  $para =~ s/r 1 : L.scarez, /r 1 : Lascarez, /g;
  $para =~ s/r 1 : M.ller, Ma/r 1 : Muller, Ma/g;
  $para =~ s/r 1 : N.nez, Liz/r 1 : Nunez, Liz/g;
  $para =~ s/r 1 : S.nchez-Bl/r 1 : Sanchez-Bl/g;
  $para =~ s/r 2 : D.clais, A/r 2 : Declais, A/g;
  $para =~ s/r 2 : F.lix, Mar/r 2 : Felix, Mar/g;
  $para =~ s/r 2 : G.nczy, Pi/r 2 : Gonczy, Pi/g;
  $para =~ s/r 2 : K.nzler, M/r 2 : Kunzler, M/g;
  $para =~ s/r 2 : M.ller-Jen/r 2 : Moller-Jen/g;
  $para =~ s/r 2 : M.ller-Rei/r 2 : Muller-Rei/g;
  $para =~ s/r 3 : B.low, Han/r 3 : Bulow, Han/g;
  $para =~ s/r 3 : F.lix, Mar/r 3 : Felix, Mar/g;
  $para =~ s/r 3 : G.nczy, Pi/r 3 : Gonczy, Pi/g;
  $para =~ s/r 3 : L.ppert, M/r 3 : Luppert, M/g;
  $para =~ s/r 4 : N..r, Ande/r 4 : Naar, Ande/g;
  $para =~ s/r 5 : J.licher, /r 5 : Julicher, /g;
  $para =~ s/r 5 : M.ller, Fr/r 5 : Muller, Fr/g;
  $para =~ s/r 5 : N..r, Ande/r 5 : Naar, Ande/g;
  $para =~ s/r 5 : S.galat, L/r 5 : Segalat, L/g;
  $para =~ s/r 6 : S.nchez-Bl/r 6 : Sanchez-Bl/g;
  $para =~ s/e at 27.C <i>\(2\)/e at 27degC <i>(2)/g;
  $para =~ s/hatidyl..inosito/hatidyl--inosito/g;
  $para =~ s/ 1 : Fr.kj.r-Jen/ 1 : Frokjaer-Jen/g;
  $para =~ s/ 1 : Ol.hov., Mo/ 1 : Olahova, Mo/g;
  $para =~ s/ 1 : Vi.uela, A./ 1 : Vinuela, A./g;
  $para =~ s/ 10 : N..r, Ande/ 10 : Naar, Ande/g;
  $para =~ s/ 2 : Fr.kj.r-Jen/ 2 : Frokjaer-Jen/g;
  $para =~ s/ 2 : Ib..ez-Vent/ 2 : Ibanez-Vent/g;
  $para =~ s/ 2 : Ol.hov., Mo/ 2 : Olahova, Mo/g;
  $para =~ s/ 2 : St.rzenbaum/ 2 : Sturzenbaum/g;
  $para =~ s/ 2 : Vi.uela, An/ 2 : Vinuela, An/g;
  $para =~ s/ 3 : Kr.ger, Ang/ 3 : Kruger, Ang/g;
  $para =~ s/ 4 : Ch.teau, Ma/ 4 : Chateau, Ma/g;
  $para =~ s/ 9 : Kn.lker, Ha/ 9 : Knolker, Ha/g;
  $para =~ s/obiolog.a del De/obiologia del De/g;
  $para =~ s/oles \(B.low and /oles (Bulow and /g;
  $para =~ s/éal, Qu.bec, Can/éal, Quebec, Can/g;
  $para =~ s/ at 20 .C contai/ at 20 degC contai/g;
  $para =~ s/<\/i> Kr.ppel-lik/<\/i> Kruppel-lik/g;
  $para =~ s/cher, B.le, Swit/cher, Bale, Swit/g;
  $para =~ s/is \(Col.n-Ramos /is (Colon-Ramos /g;
  $para =~ s/titut f.r Geneti/titut fur Geneti/g;
  $para =~ s/ial \(na.ve\) sens/ial (naive) sens/g;
  $para =~ s/ions \(B.low and /ions (Bulow and /g;
  $para =~ s/o de Ci.ncias Bi/o de Ciencias Bi/g;
  $para =~ s/ure \(30.C\) or ox/ure (30 degC) or ox/g;
  $para =~ s/ut de G.n.tique /ut de Genetique /g;
  $para =~ s/re \(0.2.C\) above/re (0.2 degC) above/g;
  $para =~ s/rg, Sch.nzlestr./rg, Schanzlestr./g;
  $para =~ s/, Montr.al, Qu.b/, Montreal, Queb/g;
  $para =~ s/s at 20.C, indic/s at 20 degC, indic/g;
  $para =~ s/ de la M.diterran/ de la Mediterran/g;
  $para =~ s/ not 20 .C. Consi/ not 20 degC. Consi/g;
  $para =~ s/de Montr.al, Qu.b/de Montreal, Queb/g;
  $para =~ s/entrum f.r Moleku/entrum fur Moleku/g;
  $para =~ s/ias Biol.gicas, U/ias Biologicas, U/g;
  $para =~ s/niversit. da Mont/niversite da Mont/g;
  $para =~ s/niversit. du Qu.b/niversite du Queb/g;
  $para =~ s/on 2 : D..parteme/on 2 : Departeme/g;
  $para =~ s/pe at 27.C <i>\(2\)/pe at 27 degC <i>(2)/g;
  $para =~ s/re and F.lix, Gen/re and Felix, Gen/g;
  $para =~ s/real \(UQ..M\), Mon/real (UQM), Mon/g;
  $para =~ s/rtorns h.gskola, /rtorns hogskola, /g;

  $para =~ s/ D.F., M.xico/D.F., Mexico/g;
  $para =~ s/ Jr, Sim./ Jr, Simo/g;
  $para =~ s/ Vaux, V.ronique/ Vaux, Veronique/g;
  $para =~ s/, Anne-C.cile/, Anne-Cecile/g;
  $para =~ s/6-1073. ../6-1073. A./g;
  $para =~ s/D. F., M.xico/D. F., Mexico/g;
  $para =~ s/D. F., M.xico./D. F., Mexico./g;
  $para =~ s/MPS, Nad.ge/MPS, Nadege/g;
  $para =~ s/Marie-Th.r.se/Marie-Therese/g;
  $para =~ s/Rafael S.nos/Rafael Senos/g;
  $para =~ s/chis, Fr.d.ric/chis, Frederic/g;
  $para =~ s/de Montr.al,/de Montreal,/g;
  $para =~ s/de, Labb./de, Labbe/g;
  $para =~ s/egans Kr.ppel-lik/egans Kruppel-lik/g;
  $para =~ s/er, Fran.oise/er, Francoise/g;
  $para =~ s/er, Marl.ne/er, Marlene/g;
  $para =~ s/errer, M.nica/errer, Monica/g;
  $para =~ s/ert, Val.rie/ert, Valerie/g;
  $para =~ s/ert, Val.rie J P/ert, Valerie J P/g;
  $para =~ s/gans \(Fr.kj.r-Jen/gans (Frokjaer-Jen/g;
  $para =~ s/hel, Agn.s/hel, Agnes/g;
  $para =~ s/mann, Fr.d.ric/mann, Frederic/g;
  $para =~ s/nches \(B.low et a/nches (Bulow et a/g;
  $para =~ s/oin, Aur.lien/oin, Aurelien/g;
  $para =~ s/onnet, G.raldine/onnet, Geraldine/g;
  $para =~ s/or 4 : B.low, H./or 4 : Bulow, H./g;
  $para =~ s/ougne, J.r.me/ougne, Jerome/g;
  $para =~ s/pe at 27.C \(2\). I/pe at 27 degC (2). I/g;
  $para =~ s/r 13 : B.low, H./r 13 : Bulow, H./g;
  $para =~ s/rera, In.s/rera, Ines/g;
  $para =~ s/s.. 1 Fr.kjaer-Je/s.. 1 Frokjaer-Je/g;
  $para =~ s/szki, Gy.rgyi/szki, Gyorgyi/g;
  $para =~ s/tin, Ren./tin, Rene/g;
  $para =~ s/udeau, B.n.dicte/udeau, Benedicte/g;
  $para =~ s/ville, R.mi/ville, Remi/g;

#   $para =~ s/¬//g;  		# }if ($para =~ m/¬/) { 	# all this stuff doesn't work
#   $para =~ s/º//g;  		# }if ($para =~ m/º/) { 
#   $para =~ s/À/e/g; 		# }if ($para =~ m/À/) { 
#   $para =~ s/Ã/e/g; 		# }if ($para =~ m/Ã/) { 
#   $para =~ s/É/e/g; 		# }if ($para =~ m/É/) { 
#   $para =~ s/à/a/g; 		# }if ($para =~ m/à/) { 
#   $para =~ s/á/a/g; 		# }if ($para =~ m/á/) { 
#   $para =~ s/â/a/g; 		# }if ($para =~ m/â/) { 
#   $para =~ s/ä/a/g; 		# }if ($para =~ m/ä/) { 
#   $para =~ s/å/a/g; 		# }if ($para =~ m/å/) { 
#   $para =~ s/æ/ae/g;		# }if ($para =~ m/æ/) { 
#   $para =~ s/ç/c/g; 		# }if ($para =~ m/ç/) { 
#   $para =~ s/è/e/g; 		# }if ($para =~ m/è/) { 
#   $para =~ s/é/e/g; 		# }if ($para =~ m/é/) { 
#   $para =~ s/ê/e/g; 		# }if ($para =~ m/ê/) { 
#   $para =~ s/í/i/g; 		# }if ($para =~ m/í/) { 
#   $para =~ s/ï/i/g; 		# }if ($para =~ m/ï/) { 
#   $para =~ s/ñ/n/g; 		# }if ($para =~ m/ñ/) { 
#   $para =~ s/ó/o/g; 		# }if ($para =~ m/ó/) { 
#   $para =~ s/ô/o/g; 		# }if ($para =~ m/ô/) { 
#   $para =~ s/ö/o/g; 		# }if ($para =~ m/ö/) { 
#   $para =~ s/ø/o/g; 		# }if ($para =~ m/ø/) { 
#   $para =~ s/ú/u/g; 		# }if ($para =~ m/ú/) { 
  $para =~ s/ü/u/g; 		# }if ($para =~ m/ü/) { 
  return $para;
}



__END__

