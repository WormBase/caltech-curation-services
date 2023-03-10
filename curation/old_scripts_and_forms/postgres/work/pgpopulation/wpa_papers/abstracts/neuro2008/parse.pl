#!/usr/bin/perl

# Enter IWM 2007 data.  Parse out some Author's names that had accents  2007 06 07
#
# Changed for Neuro meeting 2008.  processWormbook runs really slowly, probably because it keeps getting postgres data into a hash each time it gets called.  2009 02 05

use lib qw( /home/postgres/work/pgpopulation/wpa_papers/wpa_new_wbpaper_tables/perl_wpa_match );
use wpa_match qw ( processWormbook );

use strict;


my ($wormbook, $authors, $title, $journal, $volume, $pages, $year, $abstract, $genes, $type, $editor, $fulltext_url);

$journal = 'C.elegans Aging, Stress, Pathogenesis, and Heterochrony Meeting';
$year = '2008';
$type = 'Meeting Abstract';

$/ = undef;

my $infile = 'CE_Aging_Meeting.txt';
# my $infile = 'CE_Neuro_Meeting.txt';
open (IN, "<$infile") or die "Cannot open $infile : $!"; 
my $file = <IN>;
close (IN) or die "Cannot close $infile : $!"; 
my (@lines) = split/\n/, $file;
my $entry = ''; my @entries;
foreach my $line (@lines) {
  if ($line =~ m/^\d+\t/) { push @entries, $entry; $entry = $line; }
    else { $entry .= " $line"; }
} # foreach my $line (@lines)
push @entries, $entry;

foreach my $entry (@entries) {
  ($entry) = &cleanFile($entry);
  my (@data) = split/\t/, $entry;
  foreach (@data) { if ($_ =~ m/^\"/) { $_ =~ s/^\"//g; } if ($_ =~ m/\"$/) { $_ =~ s/\"$//g; } }
  next unless ($data[0]);
  my $identifier = "neuro2008aging$data[0]";
  my $title = $data[12];
  my $authors = &processAuthors($data[13]);
  my $abst = $data[15];

  my $line = "$identifier\t$authors\t$title\t$journal\t$volume\t$pages\t$year\t$abst\t$genes\t$type\t$editor\t$fulltext_url";
  
  print "$line\n";
# UNCOMMENT THIS TO PUT DATA IN
#   &processWormbook( 'two480', 'wormbook', $line );	# 480 is Tuco
#   print "ID $identifier TITLE $title AUT $authors ABS $abst END\n";
  
} # foreach my $entry (@entries)

$journal = 'C.elegans Neuronal Development Meeting';

$infile = 'CE_Neuro_Meeting.txt';
open (IN, "<$infile") or die "Cannot open $infile : $!"; 
$file = <IN>;
close (IN) or die "Cannot close $infile : $!"; 
(@lines) = split/\n/, $file;
$entry = ''; @entries = ();
foreach my $line (@lines) {
  if ($line =~ m/^\d+\t/) { push @entries, $entry; $entry = $line; }
    else { $entry .= " $line"; }
} # foreach my $line (@lines)
push @entries, $entry;

foreach my $entry (@entries) {
  ($entry) = &cleanFile($entry);
  my (@data) = split/\t/, $entry;
  foreach (@data) { if ($_ =~ m/^\"/) { $_ =~ s/^\"//g; } if ($_ =~ m/\"$/) { $_ =~ s/\"$//g; } }
  next unless ($data[0]);
  my $identifier = "neuro2008neuro$data[0]";
  my $title = $data[23];
  my $authors = &processAuthors($data[24]);
  my $abst = $data[26];

  my $line = "$identifier\t$authors\t$title\t$journal\t$volume\t$pages\t$year\t$abst\t$genes\t$type\t$editor\t$fulltext_url";
  
  print "$line\n";
# UNCOMMENT THIS TO PUT DATA IN
#   &processWormbook( 'two480', 'wormbook', $line );	# 480 is Tuco
#   print "ID $identifier TITLE $title AUT $authors ABS $abst END\n";
  
} # foreach my $entry (@entries)


sub processAuthors {
  my $authors = shift;
  my (@authors) = split/,/, $authors; my @clean_auths;
  foreach my $auth (@authors) { 
    $auth =~ s/<[^>]*?>//g;
    $auth =~ s/\?//g;
    $auth =~ s/\*//g;
    $auth =~ s/\.//g;
    $auth =~ s/\d//g;
    $auth =~ s/^\s+//g;
    $auth =~ s/\s+$//g;
    if ($auth =~ m/\S/) { push @clean_auths, $auth; }
  }
  foreach my $auth (@clean_auths) {
    if ($auth =~ m/[^a-zA-Z\'\- ]/) { print "BAD AUTH $auth EB\n"; }
  } # foreach my $auth (@clean_auths)
  $authors = join"\/\/", @clean_auths;
  return $authors;
}

# 14552	"Johnson"	"Brandon E"	""	"Stanford University, Stanford, CA"	""	""	""	""	""	""	"bejohnson@stanford.edu"	""	""	"Johnson"	"Brandon"	"Goodman"	"Miriam"	"01 Neural Circuits and Behavior"	"0101 Ion channel function"	""	""	"Poster"	"The Ensemble of BK Channel Splice Variants in <i style=''>Caenorhabditis elegans</i>"	"<u>Brandon Johnson</u><sup>1</sup>, Richard Aldrich<sup>2</sup>, Miriam Goodman<sup>1</sup>"	"<sup>1</sup>Stanford University, Stanford, CA, <sup>2</sup>University of Texas, Austin, TX"	"Large-conductance, Ca<sup>2+</sup>- and voltage-activated potassium (BK) channels regulate many functions including neurotransmitter release at the neuromuscular junction (NMJ).<span style="""">&nbsp; </span>The pore-forming subunit of BK channels is transcribed from a single gene, <i>slo-1</i>, which encodes multiple isoforms through alternative splicing.<span style="""">&nbsp; </span>To better understand how splicing affects BK channel function, we sought to identify and characterize all <i>slo-1</i> splice variants from a single organism.<span style="""">&nbsp; </span>As the number of potential splice variants exceeds 1,000 for flies and mammals, we focused on <i>C. elegans</i> in which <i>slo-1</i> contains three splice sites and only 12 possible splice variants.<span style="""">&nbsp; </span>Using standard techniques in RT-PCR and restriction digestion, we developed a novel method to determine which of the possible combinations of alternative exons are expressed as unique splice variants.<span style="""">&nbsp; </span>We identified all twelve predicted <i>slo-1</i> splice variants; this set includes three previously reported variants and nine new ones.</p> <p>To determine how alternative splicing affects BK channel function, we are measuring the Ca<sup>2+</sup>- and voltage-dependence of each splice variant expressed in heterologous cells.<span style="""">&nbsp; </span>These isoforms show a range of apparent Ca<sup>2+</sup> and voltage sensitivities, supporting the idea that alternative splicing is a mechanism to regulate BK channel activation in diverse cell types.</p> <p> We identified a <i>slo-1</i> allele (<i>pg34</i>) that encodes a single amino acid substitution in an alternatively spliced exon, which affects eight of the 12 <i>slo-1</i> splice variants. Intriguingly, we find that this mutation has a minor effect on channel function in one isoform, while significantly altering channel activity in another isoform.<span style="""">&nbsp; </span><i>pg34</i> mutants are hypersensitive to paralysis induced by an acetylcholine esterase inhibitor (aldicarb), but show wild-type sensitivity to an acetylcholine receptor agonist, levamisole.<span style="""">&nbsp; </span>Thus, <i>pg34</i> is likely to act presynaptically at the NMJ.<span style="""">&nbsp; </span>Together, these data suggest that <i>pg34</i> reduces but does not eliminate channel activity in <i>slo-1 </i>splice variants needed for proper BK channel function at the neuromuscular junction.</p>"	60	""	"The Ensemble of BK Channe"	114	""	"mbgoodman@stanford.edu"	"315244"	"Johnson B E:Aldrich R W:Goodman M B"	""	""	""	""	""	""	""	""	""	""	""	""	""	""	""	""	""	""	""	"mbgoodman@stanford.edu" 

# 14756	"Reynolds"	"Rose M"	"University of Oregon, Eugene, Oregon, USA"	"reynolds@uoregon.edu"	"Reynolds"	"Rose"	"Phillips"	"Patrick"	"01 Aging"	"0101 Genetic Screens"	"Poster"	"<i>Caenorhabditis remanei </i>As</span> The Perfect &ldquo;Aging&rdquo; Organism? Genetic Variation For Lifespan, Oxidative Stress Response, And In The Insulin Signaling Pathway</span>"	"<u>Rose Reynolds</u>, Richard Jovelin, Jennifer Comstock, Tyrel Love, Patrick Phillips"	"University of Oregon, Eugene, Oregon, USA"	"There is a growing consensus that one of the most promising methods for advancing our understanding of complex biological processes will be to examine how those processes function in a natural system. For the genetic basis of longevity and human disease, this understanding may be particularly advantageous, yielding information on natural allelic or gene expression differences that produce individuals that are healthier longer, without negative pleiotropic effects. The model nematode<i> Caenorhabditis elegans</i> has served as one of the most powerful systems for uncovering conserved mechanisms through which the aging process can be manipulated in the laboratory. Although<i> C. elegans</i> is a well developed model system with flexible genetic and genomic tools, recent studies have shown it is conspicuously lacking in natural genetic diversity on local and world-wide scales<i>,</i> suggesting that it will serve as a poor model for studying variation in aging within natural populations. T<span>he closely related soil nematode<i> C. remanei</i>, which is dioecious (outcrossing) and readily collected in nature, is an ideal complement to<i> C. elegans </i>as a natural system.</span> The<i> C. remanei</i> genome has been sequenced and is awaiting assembly. Its genome is comparable in size to <i>C. elegans</i>, but experiences levels of linkage disequilibrium comparable to <i>Drosophila melanogaster</i>. Significantly, <i>C. remanei</i> is amenable to the same laboratory and genetic manipulations as<i> C. elegans.</i> In addition, this species has both males and females, making it a better model for human aging. We have found significant within-population genetic variation for lifespan and oxidative stress. In addition, we have found significant levels of molecular genetic variation within a known aging pathway, the insulin and insulin-like growth factor signaling (IIS) pathway. This variation, and the tractability of<i> Caenorhabditis</i> systems, makes <i>C. remanei</i> the ideal model system for studying the genetic complexities likely to characterize naturally existing individual differences in aging."	62	"<i>Caenorhabditis remanei"	""	"pphil@uoregon.edu"	"317723"	""	""	""	""	""	""	""	""	""	""	""	""	""	""	""	""	""	""



sub cleanFile {
  my $file = shift;
#   $file =~ s/<span.*?<\/span>//ig;
  $file =~ s/<sup.*?<\/sup>//g;
  $file =~ s/<sub.*?<\/sub>//g;
  $file =~ s/<[a-z] style.*?>//g;
  $file =~ s/<font.*?<\/font>//g;
  $file =~ s/<o:p>/  /gi;
  $file =~ s/<\/o:p>/  /gi;
  $file =~ s/<p>/  /gi;
  $file =~ s/<\/p>/  /gi;
  $file =~ s/&rsquo;/\'/g;
  $file =~ s/&ldquo;/\'/g;
  $file =~ s/&rdquo;/\'/g;
  $file =~ s/&beta;/beta/gi;
  $file =~ s/&delta;/delta/gi;
  $file =~ s/&gamma;/gamma/gi;
  $file =~ s/&alpha;/alpha/gi;
  $file =~ s/&theta;/theta/gi;
  $file =~ s/&mu;/mu/gi;
  $file =~ s/&sigma;/sigma/gi;
  $file =~ s/&micro;/micro/gi;
  $file =~ s/&plusmn;/+\/-/gi;
  $file =~ s/&lt;/</gi;
  $file =~ s/&gt;/>/gi;
  $file =~ s/&deg;/deg/gi;
  $file =~ s/&szlig;/s/g;
  $file =~ s/&#176;//g;
  $file =~ s/&#146;//g;
  $file =~ s/&#147;//g;
  $file =~ s/&#148;//g;
  $file =~ s/&#150;//g;
  $file =~ s/&#151;//g;
  $file =~ s/&#946;//g;
  $file =~ s/&#945;//g;
  $file =~ s/&reg;//g;
  $file =~ s/\&\#;//g;
  $file =~ s/G.nczy/Gonczy/g;
  $file =~ s/Thomas B.rglin/Thomas Burglin/g;
  $file =~ s/Vanessa Gonz.lez-P.rez/Vanessa Gonzalez-Perez/g;
  $file =~ s/Erika Fr.hli-Hoier/Erika Frohli-Hoier/g;
  $file =~ s/Jemma Alarc.n/Jemma Alarcon/g;
  $file =~ s/Anders N..r/Anders Naar/g;
  $file =~ s/Lydia Th./Lydia The/g;
  $file =~ s/QueeLim Ch\'ng/QueeLim Ching/g;
  $file =~ s/J.r.me Reboul/Jerome Reboul/g;
  $file =~ s/J.r.me Belougne/Jerome Belougne/g;
  $file =~ s/S.bastien Dubleumortier/Sebastien Dubleumortier/g;
  $file =~ s/M.rton L/Marton L/g;
  $file =~ s/M.d.ric J/Mederic J/g;
  $file =~ s/H.l.ne Catoire/Helene Catoire/g;
  $file =~ s/L.etitia Chotard/Laetitia Chotard/g;
  $file =~ s/Marc-Andr. Sylvain/Marc-Andre Sylvain/g;
  $file =~ s/Mait. Carre-Pierrat/Maite Carre-Pierrat/g;
  $file =~ s/.agdas Tazearslan/Cagdas Tazearslan/g;
  $file =~ s/M.d.ric Diard/Mederic Diard/g;
  $file =~ s/Fran.ois Taddei/Francois Taddei/g;
  $file =~ s/Ana-Jo.o Rodrigues/Ana-Joao Rodrigues/g;
  $file =~ s/V.ronique De Vaux/Veronique De Vaux/g;
  $file =~ s/Fritz M.ller/Fritz Muller/g;
  $file =~ s/Juan Carlos Fierro-Gonz.lez/Juan Carlos Fierro-Gonzalez/g;
  $file =~ s/Stephen R St.rzenbaum/Stephen R Sturzenbaum/g;
  $file =~ s/Rene. Miller/Renee Miller/g;
  $file =~ s/.zg.r Karakuzu/Ozgur Karakuzu/g;
  $file =~ s/Daniel Col.n-Ramos/Daniel Colon-Ramos/g;
  $file =~ s/Claire B.nard/Claire Benard/g;
  $file =~ s/Hannes B.low/Hannes Bulow/g;
  $file =~ s/Catarina M.rck/Catarina Morck/g;
  $file =~ s/Claes Ax.ng/Claes Axang/g;
  $file =~ s/J.r.me Teuli.re/Jerome Teuliere/g;
  $file =~ s/Luis Brise.o-Roa/Luis Briseno-Roa/g;
  $file =~ s/G.raldine Maro/Geraldine Maro/g;
  $file =~ s/Filip Ystr.m/Filip Ystrom/g;
  $file =~ s/Borja P.rez Mansilla/Borja Perez Mansilla/g;
  $file =~ s/S.rgio M Pinto/Sergio M Pinto/g;
  $file =~ s/Jean-Fran.ois Rual/Jean-Francois Rual/g;
  $file =~ s/Am.lie Dricot/Amelie Dricot/g;
  $file =~ s/Eva Krpelanov./Eva Krpelanova/g;
  $file =~ s/Christian Fr.kj.r-Jensen/Christian Frokjar-Jensen/g;
  $file =~ s/S.ren-Peter Olesen/Soren-Peter Olesen/g;
  $file =~ s/C.sar Hidalgo/Cesar Hidalgo/g;
  $file =~ s/Albert-L.szl. Barab.si/Albert-Laszlo Barabasi/g;
  $file =~ s/Emilie Jaqui.ry/Emilie Jaquiery/g;
  $file =~ s/Verena G.bel/Verena Gobel/g;
  $file =~ s/Katrin H.sken/Katrin Husken/g;
  $file =~ s/Christophe Lef.bvre/Christophe Lefebvre/g;
  $file =~ s/Claes Ax.ng/Claes Axang/g;
  $file =~ s/Mo.se Pinto/Moise Pinto/g;
  $file =~ s/Leticia S.nchez Alvarez/Leticia Sanchez Alvarez/g;
  $file =~ s/Val.rie/Valerie/g;
  $file =~ s/Claude Labb./Claude Labbe/g;
  $file =~ s/Anne F.lix/Anne Felix/g;
  $file =~ s/S.galat/Segalat/g;
  $file =~ s/&uuml;/u/gi;
  $file =~ s/<i>//gi;
  $file =~ s/<\/i >//gi;
  $file =~ s/<i.*?>//gi;
  $file =~ s/<br>//g;
  $file =~ s/<\/i>//gi;
  $file =~ s/<p .*?>/ /gi;
  $file =~ s/<br \/>/ /ig;
  $file =~ s/Â//g;
  $file =~ s///g;
  $file =~ s/&nbsp;/ /g;
  $file =~ s/<b>//g;
  $file =~ s/<\/b>//g;
  $file =~ s/<u>//ig;
  $file =~ s/<\/u>//ig;
  $file =~ s/<em.*?>//ig;
  $file =~ s/<\/em>//ig;
  $file =~ s/<span.*?>//ig;
  $file =~ s/<\/span>//ig;
  $file =~ s/<st1.*?>//ig;
  $file =~ s/<\/st1.*?>//ig;
  $file =~ s/<pre.*?>//ig;
  $file =~ s/<\/pre.*?>//ig;
  $file =~ s/<font.*?>//ig;
  $file =~ s/<\/font.*?>//ig;
  $file =~ s/<a href.*?<\/a>//g;
  $file =~ s/<a name.*?>//g;
  $file =~ s/<\?xml.*?>//g;
  $file =~ s/<\/div>//g;
  $file =~ s/<\/a>//g;
  $file =~ s/<strong.*?>//g;
  $file =~ s/<\/strong>//g;
  $file =~ s/<\/font>//g;
  $file =~ s/&amp;/ and /gi;
  if ($file =~ m/[^\w\d\s\`\~\'\-\?\(\)\[\]\{\}\!\@\#\$\%\^\&\*\,\.\/\;\:\_\+\=\|]/) { 
    $file =~ s/[^\w\d\s\`\~\'\-\?\(\)\[\]\{\}\!\@\#\$\%\^\&\*\,\.\/\;\:\_\+\=\|]//g;  } 
  return $file;
} # sub cleanFile

__END__

$/ = undef;
my (@files) = </home/postgres/work/pgpopulation/wpa_papers/abstracts/iwm2007/AbsFiles/*.htm>;
foreach my $infile (@files) {
  open (IN, "<$infile") or die "Cannot open $infile : $!";
  my ($abs_num) = $infile =~ m/\/(\d+).*?htm$/;
  my $identifier = 'wm2007ab' . $abs_num;
  my $file = <IN>;
  $file =~ s/&#176;//g;
  $file =~ s/&#146;//g;
  $file =~ s/&#147;//g;
  $file =~ s/&#148;//g;
  $file =~ s/\&\#;//g;
  $file =~ s/G.nczy/Gonczy/g;
  $file =~ s/Thomas B.rglin/Thomas Burglin/g;
  $file =~ s/Vanessa Gonz.lez-P.rez/Vanessa Gonzalez-Perez/g;
  $file =~ s/Erika Fr.hli-Hoier/Erika Frohli-Hoier/g;
  $file =~ s/Jemma Alarc.n/Jemma Alarcon/g;
  $file =~ s/Anders N..r/Anders Naar/g;
  $file =~ s/Lydia Th./Lydia The/g;
  $file =~ s/QueeLim Ch\'ng/QueeLim Ching/g;
  $file =~ s/J.r.me Reboul/Jerome Reboul/g;
  $file =~ s/J.r.me Belougne/Jerome Belougne/g;
  $file =~ s/S.bastien Dubleumortier/Sebastien Dubleumortier/g;
  $file =~ s/M.rton L/Marton L/g;
  $file =~ s/M.d.ric J/Mederic J/g;
  $file =~ s/H.l.ne Catoire/Helene Catoire/g;
  $file =~ s/L.etitia Chotard/Laetitia Chotard/g;
  $file =~ s/Marc-Andr. Sylvain/Marc-Andre Sylvain/g;
  $file =~ s/Mait. Carre-Pierrat/Maite Carre-Pierrat/g;
  $file =~ s/.agdas Tazearslan/Cagdas Tazearslan/g;
  $file =~ s/M.d.ric Diard/Mederic Diard/g;
  $file =~ s/Fran.ois Taddei/Francois Taddei/g;
  $file =~ s/Ana-Jo.o Rodrigues/Ana-Joao Rodrigues/g;
  $file =~ s/V.ronique De Vaux/Veronique De Vaux/g;
  $file =~ s/Fritz M.ller/Fritz Muller/g;
  $file =~ s/Juan Carlos Fierro-Gonz.lez/Juan Carlos Fierro-Gonzalez/g;
  $file =~ s/Stephen R St.rzenbaum/Stephen R Sturzenbaum/g;
  $file =~ s/Rene. Miller/Renee Miller/g;
  $file =~ s/.zg.r Karakuzu/Ozgur Karakuzu/g;
  $file =~ s/Daniel Col.n-Ramos/Daniel Colon-Ramos/g;
  $file =~ s/Claire B.nard/Claire Benard/g;
  $file =~ s/Hannes B.low/Hannes Bulow/g;
  $file =~ s/Catarina M.rck/Catarina Morck/g;
  $file =~ s/Claes Ax.ng/Claes Axang/g;
  $file =~ s/J.r.me Teuli.re/Jerome Teuliere/g;
  $file =~ s/Luis Brise.o-Roa/Luis Briseno-Roa/g;
  $file =~ s/G.raldine Maro/Geraldine Maro/g;
  $file =~ s/Filip Ystr.m/Filip Ystrom/g;
  $file =~ s/Borja P.rez Mansilla/Borja Perez Mansilla/g;
  $file =~ s/S.rgio M Pinto/Sergio M Pinto/g;
  $file =~ s/Jean-Fran.ois Rual/Jean-Francois Rual/g;
  $file =~ s/Am.lie Dricot/Amelie Dricot/g;
  $file =~ s/Eva Krpelanov./Eva Krpelanova/g;
  $file =~ s/Christian Fr.kj.r-Jensen/Christian Frokjar-Jensen/g;
  $file =~ s/S.ren-Peter Olesen/Soren-Peter Olesen/g;
  $file =~ s/C.sar Hidalgo/Cesar Hidalgo/g;
  $file =~ s/Albert-L.szl. Barab.si/Albert-Laszlo Barabasi/g;
  $file =~ s/Emilie Jaqui.ry/Emilie Jaquiery/g;
  $file =~ s/Verena G.bel/Verena Gobel/g;
  $file =~ s/Katrin H.sken/Katrin Husken/g;
  $file =~ s/Christophe Lef.bvre/Christophe Lefebvre/g;
  $file =~ s/Claes Ax.ng/Claes Axang/g;
  $file =~ s/Mo.se Pinto/Moise Pinto/g;
  $file =~ s/Leticia S.nchez Alvarez/Leticia Sanchez Alvarez/g;
  $file =~ s/Val.rie/Valerie/g;
  $file =~ s/Claude Labb./Claude Labbe/g;
  $file =~ s/Anne F.lix/Anne Felix/g;
  $file =~ s/S.galat/Segalat/g;
  
  my ($title) = $file =~ m/<title>(.*?)<\/title>/ms;
  $title =~ s/<i>//g;
  $title =~ s/<br>//g;
  $title =~ s/<\/i>//g;
  my ($body) = $file =~ m/<body>(.*?)<\/body>/ms;
  $body =~ s/<p>/\n/g;
  $body =~ s/<br>/\n/g;
  $body =~ s///g;
  $body =~ s/&nbsp;/ /g;
  $body =~ s/<b>//g;
  $body =~ s/<\/b>//g;
  $body =~ s/<u>//g;
  $body =~ s/<\/u>//g;
  $body =~ s/<i>//g;
  $body =~ s/<\/i>//g;
#   print "B $body B\n";
  my ($first, $abst) = $body =~ m/^\s+(.*?)\n(.*)$/sm;
#   print "PREFIRST $first END\n";
  my $title_parent = $title; 
  $title_parent =~ s/\-/\\-/g;
  $title_parent =~ s/\+/\\+/g;
  $title_parent =~ s/\?/\\?/g;
  $title_parent =~ s/\(/\\(/g;
  $title_parent =~ s/\)/\\)/g;
  $first =~ s/$title_parent//g;
# Tried to find out how many things had too many periods, but this was no good,
# too many states with periods, emails, and who knows what else in there.  2007 08 09
#   $first =~ s/Univ\./University/g;
#   $first =~ s/Dept\./Department/g;
#   $first =~ s/Dep\./Department/g;
#   $first =~ s/Inst\./Institute/g;
#   my (@dots) = $first =~ m/(\.)/g;
#   if (scalar(@dots) > 2) { print "Too many authors " . scalar(@dots) . " $identifier $first E\n"; }
# This parses $first down to the actual authors
# print "F $first F\n";
#   $first =~ s/\.[^\.]*$//g;
# print "S $first F\n";
#   $first =~ s/\.[^\.]*$/./g;
# print "T $first F\n";
  my ($authors) = $first =~ m/^\.?(.*?)\./;
  $authors =~ s/<sup>\d+<\/sup>//g;
  my (@authors) = split/,/, $authors;
  $abst =~ s/<sup>//g;
  $abst =~ s/<\/sup>//g;
  my @clean_auths;
  foreach my $auth (@authors) { 
    $auth =~ s/<[^>]*?>//g;
    $auth =~ s/\?//g;
    $auth =~ s/\d//g;
    $auth =~ s/^\s+//g;
    $auth =~ s/\s+$//g;
    if ($auth =~ m/\S/) { push @clean_auths, $auth; }
  }
  foreach my $auth (@clean_auths) {
    if ($auth =~ m/[^a-zA-Z\'\- ]/) { print "BAD AUTH $auth EB\n"; }
#     print "AUT $auth EAUT\n"; 
  } # foreach my $auth (@clean_auths)
  $authors = join"\/\/", @clean_auths;
#   print "FILE $infile TITLE $title AUTH $authors FIRST $first ABS $abst END\n";
#   print "FILE $infile\nTITLE $title\nABS $abst END\n";
  my $line = "$identifier\t$authors\t$title\t$journal\t$volume\t$pages\t$year\t$abst\t$genes\t$type\t$editor\t$fulltext_url";
#   print "$line\n";
# UNCOMMENT THIS TO PUT DATA IN
#   &processWormbook( 'two480', 'wormbook', $line );	# 480 is Tuco
  close (IN) or die "Cannot close $infile : $!";
} # foreach my $infile (@files)



__END__


DELETE FROM wpa WHERE wpa_timestamp > '2009-02-04 14:45:00';
DELETE FROM wpa_title WHERE wpa_timestamp > '2009-02-04 14:45:00';
DELETE FROM wpa_identifier WHERE wpa_timestamp > '2009-02-04 14:45:00';
DELETE FROM wpa_year WHERE wpa_timestamp > '2009-02-04 14:45:00';
DELETE FROM wpa_journal WHERE wpa_timestamp > '2009-02-04 14:45:00';
DELETE FROM wpa_volume WHERE wpa_timestamp > '2009-02-04 14:45:00';
DELETE FROM wpa_abstract WHERE wpa_timestamp > '2009-02-04 14:45:00';
DELETE FROM wpa_type WHERE wpa_timestamp > '2009-02-04 14:45:00';
DELETE FROM wpa_author WHERE wpa_timestamp > '2009-02-04 14:45:00';
DELETE FROM wpa_fulltext_url WHERE wpa_timestamp > '2009-02-04 14:45:00';
DELETE FROM wpa_in_book WHERE wpa_timestamp > '2009-02-04 14:45:00';
DELETE FROM wpa_editor WHERE wpa_timestamp > '2009-02-04 14:45:00';
DELETE FROM wpa_author_index WHERE wpa_timestamp > '2009-02-04 14:45:00';


