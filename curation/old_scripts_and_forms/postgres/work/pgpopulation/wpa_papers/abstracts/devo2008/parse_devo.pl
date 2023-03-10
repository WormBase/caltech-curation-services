#!/usr/bin/perl -w

# enter abstracts for devo evo 2008.  abstracts are getting crushed into one paragraph.  authors don't store affiliation
# 2009 07 29

use strict;
use diagnostics;
use DBI;
use Jex;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my $result = $dbh->prepare( "SELECT * FROM wpa ORDER BY joinkey DESC;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
my @row = $result->fetchrow;
my $wpa = $row[1];					# get highest wpa (need padding for joinkey)

$result = $dbh->prepare( "SELECT author_id FROM wpa_author_index ORDER BY author_id DESC;");
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
@row = $result->fetchrow; my $auth_joinkey = $row[0];	# get highest author_id


my %badChars;
my %cdsToGene;
&getLoci;

my $date = &getSimpleDate();
my $logfile = 'logfile.' . $date;
open (LOG, ">$logfile") or die "Cannot create $logfile : $!";
my $pgfile = 'pgfile.' . $date;
open (PG, ">$pgfile") or die "Cannot create $pgfile : $!";

# my $infile = 'Cecilia_DevoEvo_072309.txt';
# my $infile = 'Cecilia_DevoEvo_072309NewCopy';
my $infile = 'Cecilia_DevoEvo_072309New.txt';
$/ = undef;
open (IN, "<$infile") or die "Cannot open $infile : $!";
my $all_file = <IN>;
close (IN) or die "Cannot close $infile : $!";
$all_file =~ s///g;
$/ = "\n";
($all_file) = &fixHtml($all_file);

my $two_number = 'two1';				# cecilia
my $journal = 'Development & Evolution Meeting';
my $year = '2008';
my $type = 'Meeting Abstract';

$all_file =~ s/\t(\d{5})/\t\"$1\"/g;
my (@entries) = split/"\n"/, $all_file;
shift @entries;
foreach my $entry (@entries) {
#   ($entry) = &findJunk($entry);
  my ($title, $authors, $inst, $pif, $pil, $prf, $pfl, $pie, $email, $abstract, $id) = split/"\t"/, $entry;
  $authors =~ s/\d+//g;
  ($title) = &findJunk($title);
  ($authors) = &findJunk($authors);
  ($abstract) = &findJunk($abstract);
  $id =~ s/"//g; $id =~ s/\s+//g;
  $title =~ s/\n/  /g;
  next if ($title eq 'Abstract withdrawn');
  $wpa++; my $joinkey = &padZeros($wpa);		# get joinkey, up wpa counter
  my $identifier = 'devevowm08abs' . $id;
  print "ID\t$identifier\n";
  &addPg($two_number, $joinkey, 'wpa', $wpa);         				# create wpa entry
  if ($identifier) { &addPg($two_number, $joinkey, 'wpa_identifier', "$identifier"); } 		# create identifier
  print "TITLE\t$title\n";
  if ($title) { &addPg($two_number, $joinkey, 'wpa_title', $title); }
  if ($journal) { &addPg($two_number, $joinkey, 'wpa_journal', $journal); }
  if ($year) { &addPg($two_number, $joinkey, 'wpa_year', $year); }
  if ($type) { &addPg($two_number, $joinkey, 'wpa_type', $type); }
  my (@authors) = split/, /, $authors;
  my $author_rank = 0;
  foreach my $author (@authors) {
    $author =~ s/\s+/ /g;
    if ($author) {
      $author_rank++;
      print "AUTHOR\t$author_rank\t$author\n";
      &addPg($two_number, $joinkey, 'wpa_author', "$author_rank\t$author");
    }
  }
  $abstract =~ s/""/"/g;					# make all doubled doublequotes single doublequotes
  print "ABSTRACT\t$abstract\n";
  if ($abstract) { &addPg($two_number, $joinkey, 'wpa_abstract', $abstract); }
  print "\n";
#   print "START $id TIT $title AUT $authors ABSTRACT $abstract END\n";

} # foreach my $entry (@entries)

close (LOG) or die "Cannot close $logfile : $!";
close (PG) or die "Cannot close $pgfile : $!";

sub fixHtml {
  my $file = shift;
  $file =~ s/<b>//g;
  $file =~ s/<\/b>//g;
  $file =~ s/<u>//ig;
  $file =~ s/<\/u>//ig;
  $file =~ s/<i>//ig;
  $file =~ s/<i >//ig;
  $file =~ s/<\/i>//ig;
  $file =~ s/<font.*?>(.*?)<\/font>/$1/ig;
  $file =~ s/<em.*?>(.*?)<\/em>/$1/ig;
  $file =~ s/<del.*?>(.*?)<\/del>/$1/ig;
  $file =~ s/<ins.*?>(.*?)<\/ins>/$1/ig;
  $file =~ s/<strong.*?>(.*?)<\/strong>/$1/ig;
  $file =~ s/<st1:.*?>(.*?)<\/st1:.*?>/$1/ig;
  $file =~ s/<st1:.*?>(.*?)<\/st1:.*?>/$1/ig;	# looped inside itself
  $file =~ s/<span[^>]*?>\? ?<\/span>//isg;
  $file =~ s/<span.*?>(.*?)<\/span>/$1/isg;
  $file =~ s/<span.*?>//isg;
  $file =~ s/<\/span>//ig;
  $file =~ s/\.\?/./g;
  $file =~ s/<\?xml.*?>//ig;
  $file =~ s/<font.*?>//ig;
  $file =~ s/<\/font>//ig;
  $file =~ s/<\/p>/  /ig;
  $file =~ s/<p>/  /ig;
  $file =~ s/<p style.*?>//ig;
  $file =~ s/<p class.*?>//ig;
  $file =~ s/<p ?\n//ig;
  $file =~ s/<br>/  /ig;
  $file =~ s/<\/a>//ig;
  $file =~ s/<\/strong>//ig;
  $file =~ s/<o:p><\/o:p>//ig;
  $file =~ s/<i style.*?>//ig;
  $file =~ s/<sup>(.*?)<\/sup>/$1/ig;
  $file =~ s/<sub>(.*?)<\/sub>/$1/ig;
  $file =~ s///g;
  $file =~ s/&nbsp;/ /g;
  $file =~ s/&ndash;/-/g;
  $file =~ s/\?&alpha;/ alpha/ig;
  $file =~ s/&alpha;/alpha/ig;
  $file =~ s/\?&beta;/ beta/ig;
  $file =~ s/&beta;/beta/ig;
  $file =~ s/&gamma;/gamma/ig;
  $file =~ s/&delta;/delta/ig;
  $file =~ s/&amp;/&/g;
  $file =~ s/\?&phi;/ phi/g;
  $file =~ s/&middot;/ deg/g;
  $file =~ s/&deg;/ deg/g;
  $file =~ s/&plusmn;/ plus or minus /g;
  $file =~ s/&ldquo;/"/ig;
  $file =~ s/&rdquo;/"/ig;
  $file =~ s/&rsquo;/'/ig;
  $file =~ s/&ouml;/o/ig;
  $file =~ s/&egrave;/e/ig;
  $file =~ s/&eacute;/e/ig;
  $file =~ s/&nbsp;/ /ig;
  $file =~ s/&#37;/%/g;
  $file =~ s/&#145;/'/g;
  $file =~ s/&#146;/'/g;
  $file =~ s/&#147;/"/g;
  $file =~ s/&#148;/"/g;
  $file =~ s/&#149;//g;
  $file =~ s/&#150;/--/g;
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
  $file =~ s/&#945;/alpha/g;
  $file =~ s/&#966;/phi/g;
  $file =~ s/\&\#;//g;
  $file =~ s/&gt;/>/g;
  return $file;
} # sub fixHtml

sub findJunk {
  my $para = shift;
  ($para) = &filterJunk($para);
#   my (@words) = split/\s+/, $para;
#   foreach my $word (@words) {
    if ($para =~ m/[^\s\w\~\`\!\@\#\$\%\^\&\*\(\)\-\=\+\[\]\{\}\;\:\'\"\,\<\.\>\/\?\\\|]/) {
#       my (@bad) = $para =~ m/\b(.*?[^\s\w\!\@\#\$\%\^\&\*\(\)\-\=\+\[\]\{\}\;\:\'\"\,\<\.\>\/\?\\\|].*?)\b/g;
      my (@bad) = $para =~ m/(.{0,8}[^\s\w\~\`\!\@\#\$\%\^\&\*\(\)\-\=\+\[\]\{\}\;\:\'\"\,\<\.\>\/\?\\\|].{0,8})/g;
#       foreach (@bad) { $badChars{$_}++; print "$_\n"; }
      foreach (@bad) { $badChars{$_}++; print "$_\tEN :\t$para\n"; }
#       foreach (@bad) { $badChars{$_}++; }
    }
#   }
  return $para;
} # sub findJunk

sub filterJunk {
  my $para = shift;
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

  $para =~ s/Pierre G.nczy/Pierre Gonczy/g;

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

sub padZeros {
  my $joinkey = shift;
  if ($joinkey < 10) { $joinkey = '0000000' . $joinkey; }
  elsif ($joinkey < 100) { $joinkey = '000000' . $joinkey; }
  elsif ($joinkey < 1000) { $joinkey = '00000' . $joinkey; }
  elsif ($joinkey < 10000) { $joinkey = '0000' . $joinkey; }
  elsif ($joinkey < 100000) { $joinkey = '000' . $joinkey; }
  elsif ($joinkey < 1000000) { $joinkey = '00' . $joinkey; }
  elsif ($joinkey < 10000000) { $joinkey = '0' . $joinkey; }
  return $joinkey;
} # sub padZeros

sub getLoci {                   # genes to all other possible names
  my @pgtables = qw( gin_locus gin_molname gin_protein gin_seqname gin_sequence gin_synonyms );
  foreach my $table (@pgtables) {                                       # updated to get values from postgres 2006 12 19
    my $result = $dbh->prepare( "SELECT * FROM $table;" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
    while (my @row = $result->fetchrow) {
      my $wbgene = 'WBGene' . $row[0];
      push @{ $cdsToGene{locus}{$row[1]} }, $wbgene; } }

  if ($cdsToGene{locus}{run}) { delete $cdsToGene{locus}{run}; }        # Andrei's exclusion list 2006 07 15
  if ($cdsToGene{locus}{SC}) { delete $cdsToGene{locus}{SC}; }
  if ($cdsToGene{locus}{GATA}) { delete $cdsToGene{locus}{GATA}; }
  if ($cdsToGene{locus}{eT1}) { delete $cdsToGene{locus}{eT1}; }
  if ($cdsToGene{locus}{RhoA}) { delete $cdsToGene{locus}{RhoA}; }
  if ($cdsToGene{locus}{TBP}) { delete $cdsToGene{locus}{TBP}; }
  if ($cdsToGene{locus}{syn}) { delete $cdsToGene{locus}{syn}; }
  if ($cdsToGene{locus}{TRAP240}) { delete $cdsToGene{locus}{TRAP240}; }
  if ($cdsToGene{locus}{'AP-1'}) { delete $cdsToGene{locus}{'AP-1'}; }
} # sub getLoci

sub addPg {
  my ($two_number, $joinkey, $pgtable, $pm_value, $evidence) = @_;
  unless ($evidence) { $evidence = 'NULL'; }
  unless ($two_number) { $two_number = 'two1823'; }
  my $pg_command = '';
  if ($pgtable eq 'wpa_author') {
    my ($author_rank, $author) = $pm_value =~ m/^(.*?)\t(.*?)$/;
    $auth_joinkey++; 
    if ($author =~ m/\'/) { $author =~ s/\'/''/g; }
    $pg_command = "INSERT INTO wpa_author_index VALUES ($auth_joinkey, '$author', NULL, 'valid', '$two_number', CURRENT_TIMESTAMP);";
    print PG "$pg_command\n"; 
# UNCOMMENT
#     $result = $dbh->do( $pg_command );
    $pg_command = "INSERT INTO wpa_author VALUES ('$joinkey', '$auth_joinkey', $author_rank, 'valid', '$two_number', CURRENT_TIMESTAMP);";
    print PG "$pg_command\n"; 
# UNCOMMENT
#     $result = $dbh->do( $pg_command );
    print LOG "add author $joinkey $pgtable $auth_joinkey $author_rank $author\n";
  }
  elsif ($pgtable eq 'add_gene_theresa') {
    my @genes = split/\s+/, $pm_value; my %filtered_loci;
    foreach my $gene (@genes) { if ($cdsToGene{locus}{$gene}) { foreach my $wbgene (@{ $cdsToGene{locus}{$gene} }) { $filtered_loci{$wbgene}++; } } }
    foreach my $word (sort keys %filtered_loci) { &addPg($two_number, $joinkey, 'wpa_gene', $word, 'theresa'); } }
  elsif ($pgtable eq 'wpa_gene') {
    if ($evidence eq 'theresa') { 
        $evidence = "'Curator_confirmed\t\"WBPerson627\"'"; }
      else { 
        $evidence = "'Inferred_automatically\t\"Abstract read $pm_value\"'"; }
    my %filtered_gene;
    foreach my $wbgene (@{ $cdsToGene{locus}{$pm_value} }) {	# each possible wbgene that matches that word
      $filtered_gene{$wbgene}++ }
    foreach my $wbgene (sort keys %filtered_gene) {
      my $pm_gene_value = $wbgene . "($pm_value)"; 			# wbgene(word)
      if ($pm_gene_value =~ m/\'/) { $pm_gene_value =~ s/\'/''/g; }
      $pg_command = "INSERT INTO $pgtable VALUES ('$joinkey', '$pm_gene_value', $evidence, 'valid', '$two_number', CURRENT_TIMESTAMP);"; 
# UNCOMMENT
#       $result = $dbh->do( $pg_command );
      print PG "$pg_command\n"; 
      print LOG "add $joinkey $pgtable $pm_value\n"; } }
  else {
    if ( ($pgtable eq 'wpa_year') || ($pgtable eq 'wpa_title') || ($pgtable eq
'wpa_journal') || ($pgtable eq 'wpa_editor') || ($pgtable eq 'wpa_in_book') || ($pgtable eq 'wpa_fulltext_url') ) { 1; }
    elsif ($pgtable eq 'wpa_volume') {
      if ($pm_value =~ m/(\d+)\s+(Suppl)\s+(\d+)/) { $pm_value = "$1 ${2}${3}"; }	# deal with Suppl data differently. for Ranjana / Andrei didn't say anything  2005 12 20
      if ($pm_value =~ m/\-/) { $pm_value =~ s/\-+/\/\//g; } if ($pm_value =~ m/\s+/) { $pm_value =~ s/\s+/\/\//; } }	# only change the first space to // for doublequotes in .ace output
    elsif ($pgtable eq 'wpa_pages') {
      if ($pm_value =~ m/^(\d+)[\s\-]+(\d+)/) { 
        my $first = $1; my $second = $2;
        if ($second < $first) {
          my @second = split//, $second ; my $count = scalar( @second );
          my @first = split//, $first; for (1 .. $count) { pop @first; }
          my $full_second = join"", @first; $second = $full_second . $second; }
        $pm_value = $first . '//' . $second; } }
    elsif ($pgtable eq 'wpa_abstract') {
      if ($pm_value =~ m/\n/) { $pm_value =~ s/\n/ /g; }
      if ($pm_value =~ m/\s+$/) { $pm_value =~ s/\s+$//; }
      if ($pm_value =~ m/\s+/) { $pm_value =~ s/\s+/ /g; }
      &parseGenes($two_number, $joinkey, $pm_value);
      if ($pm_value =~ m/\\/) { $pm_value =~ s/\\//g; }             # get rid of all backslashes
      if ($pm_value =~ m/^\"\s*(.*?)\s*\"$/) { $pm_value = $1; }    # get rid of surrounding doublequotes
#       if ($pm_value =~ m/\'/) { $pm_value =~ s/\'/''/g; } 		# this happens for all below
    }
    elsif ($pgtable eq 'wpa_type') {
      if ($pm_value eq 'Comment') { $pm_value = '10'; }			# comment
      elsif ($pm_value eq 'Editorial') { $pm_value = '13'; }		# editorial
      elsif ($pm_value eq 'Journal Article') { $pm_value = '1'; }	# article
      elsif ($pm_value eq 'Newspaper Article') { $pm_value = '1'; }	# article
      elsif ($pm_value eq 'Letter') { $pm_value = '11'; }		# letter
      elsif ($pm_value eq 'News') { $pm_value = '6'; }			# news
      elsif ($pm_value eq 'Published Erratum') { $pm_value = '15'; }	# erratum
      elsif ($pm_value =~ m/Review/) { $pm_value = '2'; }		# review
      elsif ($pm_value =~ m/BOOK_CHAPTER/) { $pm_value = '5'; }		# book chapter (for wormbook / igor  2006 04 28)
      elsif ($pm_value =~ m/Meeting Abstract/) { $pm_value = '3'; }	# Meeting abstract   2006 05 04
      elsif ($pm_value =~ m/WormBook/) { $pm_value = '18'; }		# WormBook   2007 02 06
      else { $pm_value = '17'; } }					# other
    else { 1; }
    if ($pm_value =~ m/\'/) { $pm_value =~ s/\'/''/g; }
    $pg_command = "INSERT INTO $pgtable VALUES ('$joinkey', '$pm_value', $evidence, 'valid', '$two_number', CURRENT_TIMESTAMP);"; 
# UNCOMMENT
#     $result = $dbh->do( $pg_command );
    print PG "$pg_command\n"; 
    print LOG "add $joinkey $pgtable $pm_value\n";
  }
} # sub addPg

sub parseGenes {
  my ($two_number, $joinkey, $abstract) = @_;
  if ($abstract =~ m/,/) { $abstract =~ s/,//g; }
  if ($abstract =~ m/\(/) { $abstract =~ s/\(//g; }
  if ($abstract =~ m/\)/) { $abstract =~ s/\)//g; }
  if ($abstract =~ m/;/) { $abstract =~ s/;//g; }
  my %filtered_loci;
  my (@words) = split/\s+/, $abstract;
  foreach my $word (@words) {
    if ($cdsToGene{locus}{$word}) { $filtered_loci{$word}++; } }
#   foreach my $word (@words) { if ($cdsToGene{locus}{$word}) { foreach my $wbgene (@{ $cdsToGene{locus}{$word} }) { $filtered_loci{$wbgene}++; } } }	# this seems wrong 2006 10 10
  foreach my $word (sort keys %filtered_loci) { &addPg($two_number, $joinkey, 'wpa_gene', $word); }
} # sub parseGenes



__END__



DELETE FROM wpa WHERE wpa_timestamp > '2009-07-29 14:47:00';
DELETE FROM wpa_title WHERE wpa_timestamp > '2009-07-29 14:47:00';
DELETE FROM wpa_identifier WHERE wpa_timestamp > '2009-07-29 14:47:00';
DELETE FROM wpa_year WHERE wpa_timestamp > '2009-07-29 14:47:00';
DELETE FROM wpa_journal WHERE wpa_timestamp > '2009-07-29 14:47:00';
DELETE FROM wpa_volume WHERE wpa_timestamp > '2009-07-29 14:47:00';
DELETE FROM wpa_abstract WHERE wpa_timestamp > '2009-07-29 14:47:00';
DELETE FROM wpa_type WHERE wpa_timestamp > '2009-07-29 14:47:00';
DELETE FROM wpa_author WHERE wpa_timestamp > '2009-07-29 14:47:00';
DELETE FROM wpa_fulltext_url WHERE wpa_timestamp > '2009-07-29 14:47:00';
DELETE FROM wpa_in_book WHERE wpa_timestamp > '2009-07-29 14:47:00';
DELETE FROM wpa_editor WHERE wpa_timestamp > '2009-07-29 14:47:00';
DELETE FROM wpa_author_index WHERE wpa_timestamp > '2009-07-29 14:47:00';
DELETE FROM wpa_gene WHERE wpa_timestamp > '2009-07-29 14:47:00';


