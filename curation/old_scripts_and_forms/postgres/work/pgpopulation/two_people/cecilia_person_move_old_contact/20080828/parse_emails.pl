#!/usr/bin/perl -w

# sample PG query

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my %found;
my %emails;
my %pis;
my %check;
my %author;	# wpa_author_possible
my %authors;	# wpa_author where joinkey in wpa_year = 2008
my %recent;	# twos with recent author_possible

my $result = $conn->exec( "SELECT * FROM two_email" );
while (my @row = $result->fetchrow) {
  my ($email) = lc($row[2]);
  $row[0] =~ s/two//;
  $emails{two}{$row[0]}{$email}++;
  $emails{email}{$email} = $row[0];
} # while (my @row = $result->fetchrow)

$result = $conn->exec( "SELECT * FROM two_pis" );
while (my @row = $result->fetchrow) { $row[0] =~ s/two//; $pis{$row[0]}++; }

$result = $conn->exec( "SELECT * FROM wpa_author WHERE joinkey IN (SELECT joinkey FROM wpa_year WHERE wpa_year = '2008') ORDER BY wpa_timestamp");
while (my @row = $result->fetchrow) { if ($row[3] eq 'valid') { $authors{$row[1]}++; } else { delete $authors{$row[1]}; } }

$result = $conn->exec( "SELECT * FROM wpa_author_possible ORDER BY wpa_timestamp;" );
while (my @row = $result->fetchrow) {
  next unless ($authors{$row[0]});
  if ($row[3] eq 'valid') { $author{$row[0]}{$row[2]} = $row[1]; }
    else { delete $author{$row[0]}{$row[2]}; } 
} # while (my @row = $result->fetchrow)
foreach my $author (keys %author) {
  foreach my $join (keys %{ $author{$author} }) {
    my $two = $author{$author}{$join}; $two =~ s/two//; $recent{$two}++; } }

my $infile = 'BouncedOctober2008-forLito.txt';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) {
  next if ($line =~ m/^two\d+/);
  chomp $line;
  my ($email, $extra);
  if ($line =~ m/^(\S+)\s(.*)$/) { ($email, $extra) = $line =~ m/^(\S+)\s(.*)$/; } else { $email = $line; }
  ($email) = lc($email);
  if ($emails{email}{$email}) { $check{$emails{email}{$email}}{$email}++; }
    else { print "NO MATCH $line\n"; }
} # while (my $line = <IN>)
close (IN) or die "Cannot close $infile : $!";

foreach my $two (sort {$a<=>$b} keys %check) {
  foreach my $email (keys %{ $check{$two} }) { delete $emails{two}{$two}{$email}; } 
  my (@bad_emails) = keys %{ $check{$two} };
  my $bad_emails = join", ", @bad_emails;
  my (@good_emails) = keys %{ $emails{two}{$two} };
  if ($pis{$two}) { print "PI\t"; }
  if ($good_emails[0]) { print "two$two still has @good_emails while these are now bad $bad_emails\t"; }
    else { print "two$two only has bad emails $bad_emails\t"; }
  if ($recent{$two}) { print "has 2008 paper\n"; } else { print "doesn't have 2008 paper\n"; }
} # foreach my $two (sort keys %check)





__END__


my $result = $conn->exec( "SELECT * FROM two_comment WHERE two_comment ~ 'elegans';" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[1] =~ s///g;
    $row[2] =~ s///g;
    print "$row[0]\t$row[1]\t$row[2]\n";
  } # if ($row[0])
} # while (@row = $result->fetchrow)


two7017 <jmichas@unionbio.com>
two1932 <kmasescb@mbox.nc.kyushu-u.ac.jp>
two5568 <rmiyascb@mbox.nc.kyushu-u.ac.jp>
two6453 <weonbae@unionbio.com>
two7016 <wibke.meyer@unionbio.com>
two1930 <yuemoscb@mbox.nc.kyushu-u.ac.jp>
two4377 Aidong.Han@COLORADO.EDU
two4964 C.P.Wilkes@bristol.ac.uk
two2624 Caroline.Schmitz@mpimf-heidelberg.mpg.de
two2624 cschmitz@mpimf-heidelberg.mpg.de
two6982 Chris.Burrow@ims.mssm.edu
two2124 Claus.schertel@dartmouth.edu
two4884 David.Breckenridge@colorado.edu
two4114 ErbeE@ba.ars.usda.gov
two7738 FRG681@bham.ac.u
two2957 Fred.Gommers@wur.nl; fredgommers@medew.nema.wau.nl
two8412 Irene.Wacker@mpimf-heidelberg.mpg.de
two7140 Jason_Pfeiffer@URMC.Rochester.edu
two7140 Jason_Pfeiffer@urmc.rochester.edu
two4875 Jerry@po.mri.montana.edu
two4422 LISSL@mail.NSYSU.EDU.TW
two6513 lena.chang@fmi.ch Lena.Chang@fmi.ch
two6380 Lhong@x-marketing.com
two7059 MNiemczyk@uams.edu
two5383 Martijn.Holterman@wur.nl
two7059 MNiemczyk@uams.edu
two5383 Martijn.Holterman@wur.nl
two4983 Matthew.Crook@agresearch.co.nz
two7403 Meisterernst@gsf.de
two2388 Michelle.Boehm@yale.edu
two2699 Nathalie.Roudier@kb.inserm.fr
two7628 QingLu1@tufts-nemc.org
two2942 Remi.Sonneville@isrec.unil.ch
two1808 RichardZ@DEVGEN.com
two4065 Seth.Ziegler@dartmouth.edu
two4430 Songlin@uab.edu
two4079 Stuart.Archer@anu.edu.au
two4139 Tabler@imbb.forth.gr
two5667 Tu.Nguyen-Ngoc@isrec.ch
two3460 a.holmes@abdn.ac.uk
two4658 a.magalska@nencki.gov.pl
two3213 abouakr@iit.edu
two3213 akram.abouzied@biosci.ki.se
two3213 akram.abouzied@sh.se
two741 abra0065@gold.tc.umn.edu
two3287 achang@rockefeller.edu
two3610 aclee@amherst.edu
two3315 acooper@haverford.edu
two8645 acottage@rfcgr.mrc.ac.uk (Amanda Cottage)
two3904 agata.smialowska@biologie.uni-freiburg.de
aidyl@csupomona.edu
ajv@aber.ac.uk
alejandro.vasquez@tuebingen.mpg.de
alfchan@ust.hk
allanf@mit.edu
aluchin@interchange.ubc.ca
am1@u.washington.edu
am6@sanger.ac.uk
amounsey@central.murdoch.edu.au
ana.vaz.gomes@ki.se
anazir@mcg.edu
ande3252@umn.edu
andoh@brain.riken.jp
andrea.disanzaifom-ieo-campus.it
andrew.m.beld@Vanderbilt.Edu
annie.ali@yale.edu
annina.spilker@bc.biol.ethz.ch
apethegrape17@hotmail.com
aprilorsborn@mizzou.edu
apethegrape17@hotmail.com
aprilorsborn@mizzou.edu
arkidd@students.wisc.edu
armstrong_at_borcim.wustl.edu
artal@imbb.forth.gr
arturo.gutierrez@tuebingen.mpg.de
asaez_@_mncn.csic.es
aschaefer@molecool.wustl.edu
asinghvi@ocf.berkeley.edu
aspartz@biosci.cbs.umn.edu
assafrn@techunix.technion.ac.il
assunta.croceifom-ieo-campus.it
ayakoba@phs.osaka-u.ac.jp
b2516@columbia.edu
b90602035@ntu.edu.tw
bakermath@wisc.edu
barmadas@medicine.wustl.edu
bdatki@wm.edu
beibei.zhaomcgill.ca
bergd@lawrence.edu
bernd_fiebich@psyallg.ukl.uni-freiburg.de
bethompson@students.wisc.edu
bhaas@jcvi.ORG
bhaas@tigr.org
bheestand@bcm.tmc.edu
bhehli@hotmail.com
bmb9sjb@leeds.ac.uk
bmhersh@facstaff.wisc.edu
bmr@lclark.edu
bob-h@cbs.umn.edu
bobbyt@itsa.ucsf.edu
bolym@ust.hk
bonnaud@ccr.jussieu.fr
borlandc@msu.edu
brbill@medscape.com
bringman@mpi-cbg.de
brit.corneliussen@astrazeneca.com
bruinsma@wustl.edu
buttner@fas.harvard.edu
cadler@rockefeller.edu
calavin@fryerco.com
cannoncm@umdnj.edu
carolina@caltech.edu
caroline.bowen@linacre.oxford.ac.uk
cas292@nyu.edu
caroline.bowen@linacre.oxford.ac.uk
cas292@nyu.edu
catherine.lorin-nebel@Vanderbilt.Edu
catoire@broca.inserm.fr
cchi@fas.harvard.edu
cdempsey@uci.edu
ceb2002@columbia.edu
chand.desai@Vanderbilt.Edu
charles.claudianos@anu.edu.au
chedotal@infobiogen.fr
chen@lifesci.ucsb.edu
chenb@cshl.edu
chenwei_lin@dfci.harvard.edu
christina.dann@UTSouthwestern.edu
christina.dittrich@uzh.ch
christophe.thibaudeau.univ-nantes.fr (@)
cjoldfield@wisc.edu
cl4@sanger.ac.uk
claes.wahlestedt@cgr.ki.se
cmastroieni@scu.edu
csfogler@amherst.edu
csigris@gwdg.de
csmk2@cus.cam.ac.uk
cspecht@bu.edu
cstahl@princeton.edu
cyril@sp.edu.sg
d.c.williams@m.cc.utah.edu
d.gresham@natureny.com
dake@ust.hk
damien@niob.knaw.nl
daniel.brownell@umassmed.edu
daniel.motola@utsouthwestern.edu
daniel@wzw.tum.de
david.greenstein@vanderbilt.edu
davlum@itsa.ucsf.edu
dblanch1@stanford.edu
dcovey@molecool.wustl.edu
dd2239@columbia.edu
debg@hms.harvard.edu
delia@well.ox.ac.uk
dhuffman@biomail.ucsd.edu
dick@stripe.colorado.edu
diggins@envivopharma.com
dilair.baban@human-anatomy.oxford.ac.uk
dkchun@fas.harvard.edu
dilair.baban@human-anatomy.oxford.ac.uk
dkchun@fas.harvard.edu
dns17404@cc.okayama-u.ac.jp
dpw23@cam.ac.uk
dsw25@cam.ac.uk
dsw25@mole.bio.cam.ac.uk
dtaketa@scu.edu
dvandepeut@partners.org
dyau1@uic.edu
eacox@wisc.edu
eheon@camtwh.eric.on.ca
eimear@caltech.edu
eklerkx@pcb.ub.es
elbatchelder@wisc.edu
elena@biol.sc.edu
elewaa@hotmail.com
elf@cobra.simplecom.net
elizabeth.link@vanderbilt.edu
epmc@interchange.ubc.ca
erbay.yigit@umassmed.edu
ernstbernha.kayser@seattlechildrens.org
esexton78@comcast.net
esther.zanin@bc.biol.ethz.ch
estine@pob.huji.ac.il
evasonk@msnotes.wustl.edu
evgeni.efimenko@biosci.ki.se
exlee@amherst.edu
f040305d@mbox.nagoya-u.ac.jp
f050307m@mbox.nagoya-u.ac.jp
farber@fas.harvard.edu
fglazer@kean.edu
fieldss@cpu1.omrf.ouhsc.edu
fk21@le.ac.uk
flavia.pellerone@anu.edu.au
frances.cheng@yale.edu
fui@rpi.edu
g.de_voer@lumc.nl
gelgar@hgmp.mrc.ac.uk
gelgar@rfcgr.mrc.ac.uk
georg.wikman@shi.se
george.joshua@lshtm.ac.uk
gijs@niob.knaw.nl
gilchrist@gurdon.cam.ac.uk
gijs@niob.knaw.nl
gilchrist@gurdon.cam.ac.uk
gish@sapiens.wustl.edu
goodman@renovis.com
gopal.murti@stjude.org
gratia98@hanmail.net
grazia.malabarbaifom-ieo-campus.it
great_gazoo11@hotmail.com
gsarkis@454.com
gsc16129@cc.okayama-u.ac.jp
gsc17403@cc.okayama-u.ac.jp
gsc18409@cc.okayama-u.ac.jp
gscita@ieo.it
gtamar@techunix.technion.ac.il
guiscard.seebohm@uni-tuebingen.de
guschan@ust.hk
gvatcher@bccancer.bc.ca
gzhu@emory.edu
h-brignull@northwestern.edu
h29@kent.ac.uk
hainingzhang@wisc.edu
haiyuan.yu@yale.edu
handwerger@wi.mit.edu
hans.zauner@tuebingen.mpg.de
harigaya@stanford.edu
haycraft@uab.edu
he@uni-trier.de
hgardner@biosci.cbs.umn.edu
hhundley@genetics.utah.edu
hoepfner@mpi-cbg.de
holts@missouri.edu
hong.sun@yale.edu
hongzhan@aecom.yu.edu
horlee@ust.hk
hrb28@cam.ac.uk
hsu.hui-ting@hci.utah.edu
hu@medsch.ucl.ac.uk
hua.xiao@tuebingen.mpg.de
huayy@itsa.ucsf.edu
hugh.lapenotiere@amedd.army.mil
huiyu.tian@tuebingen.mpg.de
icarmi@cell.com
icheeseman@ucsd.edu
iharai@cdb.riken.jp
ikhan@pop.olemiss.edu
ikuko.yamamoto@vanderbilt.edu
ikhan@pop.olemiss.edu
ikuko.yamamoto@vanderbilt.edu
ilindb@lsuhsc.edu
irynaz@biochem.swmed.edu
j.brownlie@uq.edu.au
j.l.bos@med.uu.nl
j.tyson@bristol.ac.uk
jacopo.f.novelli@gmail.com
jaehyung.an@joslin.harvard.edu
jaonp@sfu.ca
jaruscav@genetics.utah.edu
jashcom@rcn.com
jasmin.fisher@weizmann.ac.il
jason.chan@tufts.edu
jbegun@student.hms.harvard.edu
jbell@med.uottawa.ca
jcl37@mole.bio.cam.ac.uk
jcrodagu@dex.upo.es
jdmce@uwyo.edu
jeanine.mohammed@yale.edu
jennifer.crew@rosalindfranklin.edu
jeolimpo@ursinus.edu
jforster@biochem.wisc.edu
jgoble@diamondv.com
jharris13@partners.org
jhowell@lhup.edu
jiamiao@ku.edu
jiayun.lu@joslin.harvard.edu
jim_kent@pacbell.net
jimmy.ouellet@mail.mcgill.ca
jing@monkeybiz.stanford.edu
jjcollins@wustl.edu
jkarpel@uwyo.edu
jkhattra@bcgsc.ca
jlin29@jesmail.johnshopkins.edu
joanne.stamford@durham.ac.uk
joe.bannister@um.edu.mt
johnsont@ibg.colorado.edu
johnyoder@wisc.edu
jonathan.rothblatt@aventis.com
joned@mri.sari.ac.uk
joseph.clayton@dartmouth.edu
jouell3@po-box.mcgill.ca
jparvin@rics.bwh.harvard.edu
jtuttle@ucsc.edu
jparvin@rics.bwh.harvard.edu
jtuttle@ucsc.edu
justin.white@ncf.edu
jvarner@mit.edu
k03ab02@kzoo.edu
kahnn@ibg.colorado.edu
kaj.grandien@aventis.com
kam@wisdom.weizmann.ac.il
kamata@eden.rutgers.edu
kaparkman@ursinus.edu
kdypsh@sympatico.ca
kelleher@wam.umd.edu
kes@sanger.ac.uk
kgood@fhcrc.org
khan@brain.riken.jp
kimxx232@umn.edu
kimyong@umich.edu
kjschmitt2@wisc.edu
kjverbrugghe@students.wisc.edu
kloek@divergence.com
kmc314@psu.edu
kmmorphy@unity.ncsu.edu
knakata@oist.jp
kohtaro.end@mri.tmd.ac.jp
kotulal@rcn.com
kozmar@gis.a-star.edu.sg
kr@uwyo.edu
krishanu.mukherjee@biosci.ki.se
krzysztof.drabikowski@biologie.uni-freiburg.de
ksha@stanford.edu
ktamai@cdb.riken.go.jp
kuma@lif.kyoto-u.ac.jp
kuoishi@cdb.riken.go.jp
kyogoody@freechal.com
l50174sakura.kudpc.kyoto-u.ac.jp
lara.appleby@yale.edu
lars.knoch@tuebingen.mpg.de
laurie.earls@vanderbilt.edu
lefebvre@broca.inserm.fr
lena.chang@fmi.ch
leonhak@rockefeller.edu
lfluo@mail.imu.edu.cn
liam.worrall@ed.ac.uk
lfluo@mail.imu.edu.cn
liam.worrall@ed.ac.uk
liatsara@wicc.weizmann.ac.il
likulovitz@ursinus.edu
linlin@kame.wel.iwate-u.ac.jp
lisun@waksman.rutgers.edu
liujh@helix.nih.gov
llamont@biochem.wisc.edu
lmit7870@itsa.ucsf.edu
lxoshe@itsa.ucsf.edu
m-casanueva@northwestern.edu
m.ashburner[at]gen.cam.ac.uk
m.clijsters@crucell.com
m.dekkers@erasmusmc.nl
macinnis@stanford.edu
magarini@watson.wustl.edu
mant0010@umn.edu
maren.hertweck@biologie.uni-freiburg.de
margherita@babel.rockefeller.edu
maria.demidova@hertford.oxford.ac.uk
maria.keating@yale.edu
mariaow@umich.edu
marris@mcmaster.ca
masaki@cdb.riken.go.jp
matija_dreze_at_dfci.harvard.edu
mcbride@duke.edu
mcbrides2@niehs.nih.gov
mcgene@arches.uga.edu
mchesney@biochem.wisc.edu
mckhyi@stanford.edu
mdbutler@fas.harvard.edu
mednet.ucla.edu
menachem.katz@weizmann.ac.il
mericb@u.washington
merrisma@umdnj.edu
merzd@ms.umanitoba.ca
mesheffield@wisc.edu
mhihi@chronogen-inc.com
michel_hamelin@merck.com
michelef@intra.niddk.nih.gov
michelle_chen@agilent.com
mikef@mjr.com
mitsushi@buffmail.colorado.edu
mmharris@mit.edu
mitsushi@buffmail.colorado.edu
mmharris@mit.edu
mmhuang@eden.rutgers.edu
mmunrui@dex.upo.es
mnasim@wisc.edu
monica.gotta@bc.biol.ethz.ch
moreirae@mail.nih.gov
morten.jensen@sainsbury-laboratory.ac.uk
morten.jensen@tsl.ac.uk
mountou@imbb.forth.gr
mpsmith1@dstl.gov.uk
mr142@nyu.edu
mreuben@hamon.swmed.edu
msjcgw@leeds.ac.uk
mslucanic@ucdavis.edu
mtrutsch@pilot.lsus.edu
mummi@cshl.edu
mw148507@bcm.tmc.edu
mwinn@umd.edu
mzulaicaijurco@mednet.ucla.edu
n.divecha@nki.nl
nabe@stanford.edu
nadia@cat.nyu.edu
napaiv@wm.edu
ncgo20@bath.ac.uk
nco@ku.edu
ndompe@stanford.edu
nenad_svrzikapa@dfci.harvard.edu
neteunhee@hanmail.net
nicolas_bertin@dfci.harvard.edu
nirada.koonrugsa@yale.edu
nnakatsufrontier.kyoto-u.ac.jp
nowak@photonic-instruments.com
nsuh@biochem.wisc.edu
oamb2@cam.ac.uk
oaurelio@fullerton.edu
ohnjo.koh@utsouthwestern.edu
oishi@salk.edu
outofoffice
ove@techunix.technion.ac.il
oyunbileg.nyamsuren@biologie.uni-freiburg.de
pagreene@ursinus.edu
parker@broca.inserm.fr
pascal.lescure@dpag.ox.ac.uk
patterson@waksman.rutgers.edu
pascal.lescure@dpag.ox.ac.uk
patterson@waksman.rutgers.edu
pawj@biology.queensu.ca
pchecch@LearnLink.Emory.Edu
pchecch@emory.edu
peg.macmorris@uchsc.edu
peles@wicc.weizmann.ac.il
petr.strnad@isrec.ch
phillip.h.grote@dartmouth.edu
pmcarlton@lbl.gov
pmckenna@soe.ucsc.edu
pmgb@rfc.ucl.ac.uk
pmhuettl@wisc.edu
po-1-@hanmail.net
popovici@marseille.inserm.fr
prasad.kasturi@unifr.ch
premnath.shetty@utsouthwestern.edu
ptyang@niob.knaw.nl
q.cheng@mailbox.uq.edu.au
qj20041243@yahoo.com..cn
rachael.nimmo@linacre.ox.ac.uk
raosh@grc.nia.nih.gov
ravi@tuebingen.mpg.de
rbhall@ucalgary.ca
rd2309@columbia.edu
reesek@mail.med.upenn.edu
reinbedf@umdnj.edu
remi.sonneville@isrec.ch
rfeng@genetics.wustl.edu
rfetter@rockefeller.edu
ris.Dinkelacker@tuebingen.mpg.de
rka24@cam.ac.uk
rlim@wi.mit.edu
roberto.testi@flashnet.it
ronald.heustis@wmich.edu
rossb@icpmr.wsahs.nsw.gov.au
rossben@mail.nih.gov
roussn@rpi.edu
royauty@yahoo.co.uk
rsantell@lorman.alcorn.edu
rvincent@pcg.wustl.edu
ryuji.minasaki@tuebingen.mpg.de
s-itakura@hiroshima-u.ac.jp
s.tokuoka@ucl.ac.uk
s-itakura@hiroshima-u.ac.jp
s.tokuoka@ucl.ac.uk
s4005676@student.uq.edu.au
s47520a[a]nucc.cc.nagoya-u.ac.jp
saamodt@pilot.lsus.edu
samara@imbb.forth.gr
saml@sfu.ca
sarah@ust.hk
sarahhunter123@btinternet.com
sashraf@fas.harvard.edu
sc205156@s.kyushu-u.ac.jp
schen@burnham.org
schuan@iastate.edu
scordes@OCF.Berkeley.EDU
scordes@berkeley.edu
scordes@ocf.berkeley.edu
scsontos@csupomona.edu
sdirienz@brynmawr.edu
sdunkelb@bio.indiana.edu
shaochun.ma@uci.edu
shaolin.li@mcgill.ca
sharon.clark1@mcgill.ca
shay.rotkopf@chello.at
shilan_wu@FMC.com
shilan_wu@fmc.com
shprasad@interchange.ubc.ca
shuang@rockefeller.edu
sibylle_jaeger@dfci.harvard.edu
simon004@umn.edu
sirina@t2.technion.ac.il
slm@itsa.ucsf.edu
smith@lakeforest.edu
smith@lfc.edu
sng@lunenfeld.ca
sng@mshri.on.ca
songlin@aru.uab.edu
sooi56@yahoo.com
spike001@umn.edu
stari001@umn.edu
stefanie.west@yale.edu
stephan.angermayr@stud.uni-graz.at
stier@biosci.cbs.umn.edu
stier@cbs.umn.edu
stuart_milstein@dfci.harvard.edu
sue.jinks-robertson@emory.edu
stuart_milstein@dfci.harvard.edu
sue.jinks-robertson@emory.edu
suetsugu@ims.u-tokyo.ac.jp
suzanne.paradis@childrens.harvard.edu
syokota@res.yamanashi-med.ac.jp
tb210@bath.ac.uk
tcnjoann@ust.hk
tdat@columbia.edu
tehirose@jbirc.aist.go.jp
tgruninger@bio.tamu.edu
tgruninger@mail.bio.tamu.edu
thomas.duchaine@mail.mcgill.ca
titia@niob.knaw.nl
titus@mail.cbri.umn.edu
todd@cbs.umn.edu
tracye@interchange.ubc.ca
trevor_griffen@brown.edu
tridoc@onebox.com
trm2001@columbia.edu
tsmith@bu.edu
ttian@fas.harvard.edu
turano@med.nagoya-u.ac.jp
tzimmerm@embl.de
uchida@cdb.riken.jp
ucvek@pilot.lsus.edu
ujendra.kumarmuhc.mcgill.ca
umcoudie@cc.umanitoba.ca
uodomen@cdb.riken.jp
uyendta@mail.med.upenn.edu
vaarnio@hytti.uku.fi
varg0026@umn.edu
vincent.coustham@ens-lyon.fr
visnja@uchicago.edu
voglis@imbb.forth.gr
w.mitchell@medsch.ucl.ac.uk
waasec@rockefeller.edu
wadim.kapulkin@yale.edu
wagmaist@umbc.edu
wangt1@umdnj.edu
wangyunling64@yahoo.com
wedrychowicz@alpha.sggw.waw.pl
weimercshl.edu
werner1@uchicago.edu
whlee@eden.rutgers.edu
werner1@uchicago.edu
whlee@eden.rutgers.edu
why@ems.hrbmu.edu.cn
whyard@cc.umanitoba.ca
wightman@hal.muhlberg.edu
wli@Princeton.EDU
wmorgan@acs.wooster.edu
wongls@comp.nus.edu.sg
woo.chi@yale.edu
wrenjf@cardiff.ac.uk
wtawe@licor.com
ww3@sanger.ac.uk
xiao.wan@yale.edu
xiaoyany@scripps.edu
xli6@mednet.swmed.edu
xou@email.unc.edu
xxzang@uclink4.berkeley.edu
xyu03@syr.edu
yinli@fas.harvard.edu
yixx0023@umn.edu
yjedward@rfcgr.mrc.ac.uk
yliu07@syr.edu
yt.chang@nyu.edu
zarkower@gene.med.umn.edu
zheliu@indiana.edu
ziaulban@cc.okayama-u.ac.jp
zstepa@mcgill.ca
zullo@purdue.edu
bounced from apc10-08
monica.gotta@bc.biol.ethz.ch
Erik.Sonnhammer@cgb.ki.se
j.l.bos@med.uu.nl
stuart_milstein@dfci.harvard.edu
jimmy.ouellet@mail.mcgill.ca  User unknown
g.de_voer@lumc.nl  (Gert de Voer)
uodomen@cdb.riken.jp (Nobuko Uodome)
kloek@divergence.com (Andrew Kloek)
annina.spilker@bc.biol.ethz.ch (Annina Spilker)
cschmitz@mpimf-heidelberg.mpg.de (Caroline Schmitz)
michelef@intra.niddk.nih.gov (Michele E Forsythe)
mdbutler@fas.harvard.edu (Maurice Butler)
scordes@ocf.berkeley.edu (Shaun Cordes)
ko129832@bcm.edu (BCM HUMAN RESOURCES)
liam.worrall@ed.ac.u (Liam Worrall)
dblanch1@stanford.edu (Daniel P Blanchard)
chen@lifesci.ucsb.edu (Ling Chen)
jjcollin@artsci.wustl.edu (James J Collins III)
tgruninger@bio.tamu.edu (Todd Ryan Gruninger)
iharai@cdb.riken.jp (Shinji Ihara)
saml@sfu.ca (Sam Chi-Hang Lee)
Akihisa.Nakagaw@colorado.edu (Akihisa Nakagawa)
bmr@lclark.edu (Beverley Rabbitts)
premnath.shetty@utsouthwestern.edu (Premnath Vithal Shetty)
esther.zanin@bc.biol.ethz.ch (Esther Zanin)
ErbeE@ba.ars.usda.gov (Eric F. Erbe)
LISSL@mail.NSYSU.EDU.TW (Steven S. L. Li)
bhaas@jcvi.ORG (Brian J. Haas)
shaolin.li@mcgill.ca (Shaolin Li)
jbegun@student.hms.harvard.edu (Jakob Begun)
Jerry@po.mri.montana.edu (Jerry E. Mellem Jr.)
mpsmith1@dstl.gov.uk (Martin Smith)
ww3@sanger.ac.uk (Wendy Wong)
oyunbileg.nyamsuren@biologie.uni-freiburg.de (Oyunbileg Nyamsuren)
krzysztof.drabikowski@biologie.uni-freiburg.de (Krzysztof Drabikowski)
charlien@omrf.ouhsc.edu (Nicole K. Charlie)
kaparkman@ursinus.edu (Kathleen Parkman)
b90602035@ntu.edu.tw (Chuan Cheng)
laurie.earls@vanderbilt.edu (Laurie R Earls)
pagreene@ursinus.edu (Pauline Greene)
aluchin@interchange.ubc.ca (Alexander Luchin)
neteunhee@hanmail.net (Eunhee Choi)
ncgo20@bath.ac.uk (Nicholas Ovenden)
Jason_Pfeiffer@urmc.rochester.edu (Jason R. Pfeiffer)
barsagi@pharm.som.sunysb.edu (Dafna Bar-Sagi)
dvandepeut@partners.org (Diederik van de Peut)
lfluo@mail.imu.edu.cn (Liaofu Luo)
jparvin@rics.bwh.harvard.edu (Jeffrey D. Parvin)
turano@med.nagoya-u.ac.jp (Takeshi Urano)
joanne.stamford@durham.ac.uk (Joanne Stamford)
uyendta@mail.med.upenn.edu (Uyen D. Ta)
hu@medsch.ucl.ac.uk (Youli Hu)
magarini@watson.wustl.edu (Vincent J Magrini)
wangt1@umdnj.edu (Tongsheng Wang)
rfetter@rockefeller.edu (Richard D. Fetter)
bennettD@qimr.edu.au
hong.sun@yale.edu (Hong Sun)
eheon@camtwh.eric.on.ca (Elise Heon)
diggins@envivopharma.com (Lenard T Diggins)
ris.Dinkelacker@tuebingen.mpg.de (Iris Dinkelacker)
k03ab02@kzoo.edu (Andrew Bayci)
Irene.Wacker@mpimf-heidelberg.mpg.de (Irene Wacker)
leonhak@rockefeller.edu (Klaus Leonhard)
georg.wikman@shi.se (Georg Wikman)
zoghbi@bcm.edu (BCM HUMAN RESOURCES)
n.divecha@nki.nl (Nullin Divecha)
mmp@kist.re.kr (Hyewhon Rhim)
hrb28@cam.ac.uk (Heeran R. Buhecha)
gilchrist@gurdon.cam.ac.uk (Michael J. Gilchrist)
rha@suiling.princeton.edu (Robert H. Austin)
bahadori@ams.com (Moslem Bahadori)
LEEHOD@il.ibm.com (Leehod Baruch)
lizi_wu@dfci.harvard.edu (Lizi Wu)
pnovak@biomed.cas.c (Petr Novak)
stefan.mikkat@med.uni (Stefan Mikkat)
Hanna.Harant@novartis.com ()
yjedward@rfcgr.mrc.ac.uk (Yvonne J. K. Edwards)
gelgar@rfcgr.mrc.ac.uk (Greg Elgar)
h29@kent.ac.uk (Rebecca A. Hall)
scozzafava@unifi.it (Andrea Scozzafava)
two8667 niels_klitgord@dfci.harvard.edu (Niels Klitgord)
wang0722@umn.edu (Xuelin Wang)
shin.murakami@rocky.edu (Shin Murakami)
thoe0004@umn.edu (Kara Thoemke)
kete0013@umn.edu (Carrie S. Ketel)
chee0035@umn.edu (Thomas Robert Cheever)
jli@ypharma.com (Jinhe Li)
koepp015@umn.edu (Deanna Koepp)
mccu0201@umn.edu (Kate A McCulloch)
ksung@comp.nus.edu.sg (Wing-Kin Sung)
filip.ystrom@biosci.ki.se (Filip Ystrom)
sunkim@bio.informatics.indiana.edu (Sun Kim)
