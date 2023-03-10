#!/usr/bin/perl -w

# take iwm2009 and group things into matches with two in postgres by  last only, last + first, email, last + first + email.
# 2009 07 13


use strict;
use diagnostics;
use DBI;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my @types = qw( code lastname firstname dept inst street mailstop city state zip country email );

my %data;
my $result = $dbh->prepare( "SELECT * FROM two_email" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $data{email}{$row[2]}{$row[0]}++; }

$result = $dbh->prepare( "SELECT * FROM two_lastname" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $data{last}{$row[2]}{$row[0]}++; } 
$result = $dbh->prepare( "SELECT * FROM two_aka_lastname" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $data{last}{$row[2]}{$row[0]}++; } 

$result = $dbh->prepare( "SELECT * FROM two_firstname" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { 
  $data{first}{$row[2]}{$row[0]}++; 
  my ($firstI) = $row[2] =~ m/^(.)/;
  $data{firstI}{$firstI}{$row[0]}++; } 
$result = $dbh->prepare( "SELECT * FROM two_aka_firstname" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { 
  $data{first}{$row[2]}{$row[0]}++; 
  my ($firstI) = $row[2] =~ m/^(.)/;
  $data{firstI}{$firstI}{$row[0]}++; } 

my $infile = 'iwm2009';

my @persons;
my $person;
open (IN, "<$infile") or die "Cannot open $infile : $!";
# while (my $line = <IN>) { chomp $line; push @lines, $line; }
while (my $line = <IN>) {
  chomp $line;
  if ($line =~ m/^96\d{4}$/) { push @persons, $person; $person = ''; }
    else { $person .= "$line\n"; }
} # while (my $line = <IN>)
close (IN) or die "Cannot close $infile : $!";

my %cats;
my @cats = qw( all email names last nomatch );

foreach my $person (@persons) {
  my @lines = split/\n/, $person;
  my $last = shift @lines;
  my $first = shift @lines;
  my $email = pop @lines;
  unless ($email) { print "NO EMAIL $person END\n"; next; }

#   my $code = shift @lines;
#   my $last = shift @lines;
#   my $first = shift @lines;
#   my $dept = shift @lines;
#   my $inst = shift @lines;
#   my $street = shift @lines;
#   my $mailstop = shift @lines;
#   my $city = shift @lines;
#   my $state = shift @lines;
#   my $zip = shift @lines;
#   my $country = shift @lines;
#   my $email = shift @lines;

  my %matches;

#   print "Person $last $first $email\n";
  if ($data{email}{$email}) { 
    foreach my $two ( sort keys %{ $data{email}{$email} } ) { $matches{email}{$two}++; $matches{any}{$two}++; }
#     my $twos = join(", ", sort keys %{ $data{email}{$email} } );
#     print "email matches $twos\n"; 
  }
  my ($firstI) = $first =~ m/^(.)/;
  if ($data{last}{$last}) { 
    foreach my $two ( sort keys %{ $data{firstI}{$firstI} } ) { $matches{firstI}{$two}++; $matches{any}{$two}++; }
#     my $twos = join(", ", sort keys %{ $data{last}{$last} } );
#     print "last matches $twos\n"; 
  }
  if ($data{first}{$first}) { 
    foreach my $two ( sort keys %{ $data{last}{$last} } ) { $matches{last}{$two}++; $matches{any}{$two}++; }
#     my $twos = join(", ", sort keys %{ $data{first}{$first} } );
#     print "first matches $twos\n"; 
  }
#   print "\n";

  my %two;
  foreach my $two (sort keys %{ $matches{any} }) {
    if ( ($matches{email}{$two}) && ($matches{last}{$two}) && ($matches{firstI}{$two}) ) { $two{all}{$two}++; }
    elsif ( ($matches{email}{$two}) ) { $two{email}{$two}++; }
    elsif ( ($matches{last}{$two}) && ($matches{firstI}{$two}) ) { $two{names}{$two}++; }
    elsif ( ($matches{last}{$two}) ) { $two{last}{$two}++; }
  } # foreach my $two (sort keys %{ $matches{any} })

  if ($two{all}) { foreach my $two (keys %{ $two{all} }) { $cats{all}{$person}{$two}++; } }
  elsif ($two{email}) { foreach my $two (keys %{ $two{email} }) { $cats{email}{$person}{$two}++; } }
  elsif ($two{names}) { foreach my $two (keys %{ $two{names} }) { $cats{names}{$person}{$two}++; } }
  elsif ($two{last}) { foreach my $two (keys %{ $two{last} }) { $cats{last}{$person}{$two}++; } }
  else  { $cats{nomatch}{$person}{noone}++; }
} # foreach my $person (@persons)

foreach my $cat (@cats) {
  print "\nCATEGORY $cat :\n";
  foreach my $person (sort keys %{ $cats{$cat} }) {
    my $twos = join(", ", sort keys %{ $cats{$cat}{$person} } );
    print "${person}TWOS : $twos\n\n";  
  }
  print "\n";
} # foreach my $cat (@cats)

__END__

code
lastname
firstname
dept
inst
street
mailstop
city
City/Province
Zipcode
Country
email

960985
Abbott
Allison
Dept Biological Sci
Marquette Univ
PO Box 1881

Milwaukee
WI
53201

allison.abbott@marquette.edu
961234
Abdus-Saboor
Ishmail
Genetics
University of Pennsylvania
415 Curie Blvd; CRB 445
Philadelphia
PA
19101

ishmail84@yahoo.com
960419
Abraham
Linu
Cell Biology and Anatomy
Rosalind Franklin University
3333 Green Bay Road
North Chicago
IL
60064

linu.abraham@rosalindfranklin.edu
960641
Achilleos
Annita
Dept Developmental Genetics
New York Univ Medical Ctr
540 First Ave

New York
NY
10016

Annita.Achilleos@med.nyu.edu
961175
Ackley
Brian
Molecular Biosciences
The University of Kansas
1200 Sunnyside Avenue
Lawrence
KS
66045

bdackley@ku.edu
961096
Ada-Nguema
Aude
Dept Biol
Univ Utah
257 South 1400 East, Rm 201
Salt Lake City
UT
84112

adanguema@biology.utah.edu
960789
Aguirre-Chen
Cristina
Neuroscience
Albert Einstein College of Med
1410 Pelham Pkwy South, Rm 616
Bronx
NY
10461

caguirre@aecom.yu.edu
960267
Ai
Erkang
Dept Genetics
Univ Wisconsin, Madison
425-G Henry Mall
Madison
WI
53706

ai@wisc.edu
961092
Ailion
Michael
Biol
Univ Utah
257 S 1400 E, Rm 201
Salt Lake City
UT
84112

ailion@biology.utah.edu
960820
ajredini
ramadan

university of florida
1600 sw archer rd
gainesville
fl
32610

rbioman@ufl.edu
960320
Aklilu
Segen
Chemistry
Agnes Scott College
141 E. College Ave.
ASC Box 7
Decatur
GA
30030

saklilu@agnesscott.edu
961518
Alam
Hena

Life Sciences Inst
210 Washtenaw
Ann Arbor
MI
48109

henaa@umich.edu
960346
Alavez
Silvestre

Buck Inst
8001 Redwood Blvd
Novato
CA
94945

salavez@buckinstitute.org
961076
Alessi
Amelia

Life Sciences Institute
210 washtenaw ave
Ann Arbor
MI
48109

aalessi@umich.edu
960632
Alfonso
Aixa
Dept Biological Sci, 3067 SEL
Univ Illinois, Chicago
845 W Taylor St, M/C 067
Chicago
IL
60607

aalfonso@uic.edu
960713
Alker
Ashley
Biology
Central Michigan University
1333 E Gaylord ST APT 5H
Mount Pleasant
MI
48858

alker1ae@cmich.edu
960561
Allard
Patrick
Dept Gen
Harvard Med Sch
77 Ave Louis Pasteur, NRB-334
Boston
MA
2115

pallard@genetics.med.harvard.edu
961158
Allen
Taylor
Dept Biol
Oberlin Col
119 Woodland St
Oberlin
OH
44074-1097

taylor.allen@oberlin.edu
961043
Allman
Erik

University of Rochester
52 Raleigh Street
Rochester
NY
14620

erik_allman@urmc.rochester.edu
960629
Alper
Scott
Immunology
National Jewish Health
1400 Jackson St., A640
Denver
CO
80206

alpers@njhealth.org
961164
Alvares
Stacy
Biology
Univ of NC
216 Fordham Hall
Chapel Hill
NC
27599

salvares@email.unc.edu
961358
Alvaro
Christopher
Biology Dept
Muhlenberg College
2400 Chew St
Allentown
PA
18104

ca235106@gws1.muhlenberg.edu
960587
Anastasiades
Daphne
Biochem & Molec Biophysics
Columbia Univ
West 168th St HHSC 505
New York
NY
10032

dca2106@columbia.edu
960441
Andersen
Erik
Lewis-Sigler Institute
Princeton University
Washington Rd
Princeton
NJ
8544

erik.andersen@gmail.com
960473
Anderson
Dorian
Dept Developmental Genetics
Skirball Inst/NYU SOM
540 First Ave

New York
NY
10016

dca232@med.nyu.edu
960628
Angelo
Giana
Basic Sci Div
FHCRC
1100 Fairview Ave N
Seattle
WA
98109

gangelo@fhcrc.org
961504
Anthony
Sarah
Dept Cell & Developmental Biol
Vanderbilt Univ
465 21st Ave S
Nashville
TN
37232

sarah.anthony@vanderbilt.edu
961312
Apfeld
Javier
Dept Systems Biol
Harvard Med Sch
200 Longwood Ave, Alpert 513
Boston
MA
2115

javier_apfeld@hms.harvard.edu
961063
Arda
H
Dept PGFE
Univ Massachusetts Med Sch
364 Plantation
Worcester
MA
1605

efsun.arda@umassmed.edu
961298
Arur
Swathi


4444 Westpine Blvd, Apt 102
St Louis
MO
63108

sarur@genetics.wustl.edu
961075
Ash
Peter
Dept Neuroscience
Mayo Clinic Florida
4500 San Pablo Rd
Jacksonville
FL
32224

ash.peter@mayo.edu
960745
Attreed
Matthew
Dept Gen
AECOM
1300 Morris Park Ave
Bronx
NY
10461

mattreed@aecom.yu.edu
961393
Austin
Misa
Biological Sciences
Cal Poly Pomona
12448 Kentucky Derby Court
Rancho Cucamonga
CA
91739

Misa.Austin@gmail.com
961265
Avery
Jason

University of Tulsa
800 S. Tucker Dr
Tulsa
ok
74104

jason-avery@sbcglobal.net
960198
Avery
Leon
Dept Molecular Biol
Univ Texas SW Medical Ctr
6000 Harry Hines Blvd
Dallas
TX
75390-9148

leon@eatworms.swmed.edu
960275
Avila
Felipe
Biology
University of Texas at Arlington
501 S. Nedderman Drive 337 Life Science
Arlington
TX
76010

avilafelipe@uta.edu
961136
Ayyadevara
Srinivas
Dept Geriatrics
Univ Arkansas Medical Sci
2300 Stoney Creek Dr
Little Rock
AR
72211

srini54@hotmail.com
960265
Babu
Kavita
Dept Molecular Biol
Massachusetts General Hosp
185 Cambridge St, CPZN-725
Boston
MA
2114

kavita@molbio.mgh.harvard.edu
961544
Bae
Weon

Union Biometrica
84 October Hill Rd
Holliston
MA
1746

wbae@unionbio.com
961530
Baer
Charles
Dept Biol
Univ Florida
223 Bartram Hall
Gainesville
FL
32611-8525

cbaer@ufl.edu
961036
Bageshwar
Suparna
Molecular and cellular Medicin
Texas A&M Health Science cente
University Drive
College Station
TX
77843

SBageshwar@medicine.tamhsc.edu
961372
Bahrami
Adam
Organismic & Evolutionary Biol
Harvard Univ
52 Oxford St, Room 254
Cambridge
MA
2138

bahrami@fas.harvard.edu
960255
Bai
Jihong
Dept Molecular Biol
Massachusetts General Hosp
185 Cambridge St
Boston
MA
2114

bai@molbio.mgh.harvard.edu
960390
Baldi
Christopher
Dept Molecular Biol
UMDNJ
2 Medical Center Dr
Stratford
NJ
8084

baldicc@umdnj.edu
960624
Bamber
Bruce
Biol Sci
Univ Toledo
2801 W Bancroft St
Toledo
OH
43606

bruce.bamber@utoledo.edu
960208
Banerjee
Diya
Biological Sciences
Virginia Tech University
1981 Kraft Drive, ILSB 2021
Blacksburg
VA
24061

dibaner@vt.edu
961176
Bao
Zhirong
Developmental Biology
Sloan-Kettering Institute
1275 York Ave, Box 416
New York
NY
10065

baoz@mskcc.org
961263
Baran
Renee
Dept Biol
Occidental Col
1600 Campus Rd
Los Angeles
CA
90041

baran@oxy.edu
960775
Bargonetti
Jill
Biological Sciences
695 Park Ave Rm 942N
New York
NY
10065

bargonetti@genectr.hunter.cuny.edu
960782
Barnhart
Kathleen

Union Biometrica
84 October Hill Rd
Holliston
MA
1746

kbarnhart@unionbio.com
960534
Barr
Maureen
Dept Gen
Rutgers, The State Univ
145 Bevier Rd
Piscataway
NJ
8854

barr@biology.rutgers.edu
961525
Barrett
Peter
Dept. of Biology
Xavier University of Louisiana
One Drexel Dr
NCF 401-G
New Orleans
LA
70125

pbarrett@xula.edu
960559
Barrios
Arantza
Dept Genetics
Rutgers University
145 Bevier Rd
Piscataway
NY
10461

barrios@dls.rutgers.edu
960246
Bashllari
Enkelejda
Biochem & Mol. Biophysics
Columbia University
701 West 168th St
HHSC/7th Floor
New York
NY
10032

eb2277@gmail.com
961069
Batista
Pedro
Program Molecular Medicine
Univ Massachusetts Med Sch
373 Plantation St, S219
Worcester
MA
1604

pedro.batista@umassmed.edu
960664
Baugh
Ryan
Dept Biol
Duke University
Box 90338

Durham
NC
27708

ryan.baugh@duke.edu
961078
Bazopoulou
Daphne
Mechanical Engineering
University of Michigan
3112 G.G. Brown, 2350 Hayward Street
Ann Arbor
MI
48109-2125

dafbaz@umich.edu
961494
Beatty
Alexander
Dept MGB
Cornell Univ
433 Biotechnology
Ithaca
NY
14852

acb48@cornell.edu
960824
Bellier
Audrey
Dept Cell & Developmental Biol
Univ California, San Diego
9500 Gilman Dr
San Diego
CA
92093-0349

abellier@ucsd.edu
960248
Benard
Claire
Dept Biochem
Columbia Univ
701 W 168th St
New York
NY
10032

cb2213@columbia.edu
960514
Benian
Guy
Dept Pathology
Emory Univ
615 Michael St, WBRB 165
Atlanta
GA
30322

pathgb@emory.edu
961324
Benirschke
Ingrid

Cold Spring Harbor Lab. Press
500 Sunnyside Road
Woodbury
NY
11797

cshpress@cshl.edu
961289
Berkowitz
Laura
Dept Biological Sci
Univ Alabama
411 Hackberry Lane Box 870344
Tuscaloosa
AL
35487

laberkowitz@bama.ua.edu
961012
Berkseth
Matthew
Gen, Cell Biol, & Development
Univ Minnesota
420 Delaware St
Minneapolis
MN
55455

mattberkseth@hotmail.com
961066
Bernadskaya
Yelena
Dept Pathology & Lab Medicine
UMDNJ/RWJMS
675 Hoes Lane, Res Tower R
Piscataway
NJ
8854

patelfb@umdnj.edu
961163
Bernstein
Max

AECOM, Ullmann 703
1300 Morris Park Ave
Bronx
NY
10461

mrbernst@aecom.yu.edu
960381
Bessler
Jessica
Dept Dev Biol
Stanford Univ
279 Campus Dr
Stanford
CA
94305

jbessler@stanford.edu
960752
Bethke
Axel
Huffington Ctr Aging
Baylor Col Med
One Baylor Plaza
Houston
TX
77030

abethke@bcm.tmc.edu
961483
Bettinger
Jill
Dept Pharmacology/Toxicology
Virginia Commonwealth
410 N 12th St, Box 980613
Richmond
VA
23298

jcbettinger@vcu.edu
961010
Beverly
Matthew
Dept Biol
Brandeis Univ
415 South St

Waltham
MA
2454

bev@brandeis.edu
961132
Bharill
Puneet
Biochem & Molec Bio
UAMS
4300 W Markham St
Little Rock
AR
72202

pbharill@uams.edu
961042
Bhatla
Nikhil

MIT
31 Ames St

Cambridge
MA
2144

nbhatla@mit.edu
960744
Bhattacharya
Raja
Dept Molec Gen
Albert Einstein Col Med
1300 Morris Park Ave
Bronx
NY
10461

rajabhattacharya8@gmail.com
960251
Bhaumik
Dipa

Buck Institute
8001 Redwood Blvd
Novato
CA
94945

dbhaumik@buckinstitute.org
960894
Bianchi
Laura
Dept Physiology & Biophysics
Univ Miami
1600 NW 10th Ave
Miami
FL
33136

lbianchi@med.miami.edu
960293
Bieri
Tamberlyn
Gen/Genome Sequencing Ctr
Washington Univ Sch Medicine
4444 Forest Park Blvd
St Louis
MO
63108

tbieri@watson.wustl.edu
960567
Billi
Allison
Human Genetics
University of Michigan
210 Washtenaw Ave
Ann Arbor
MI
48109

acbilli@umich.edu
961549
Bird
David
Plant Pathology
NC State University
840 Main Campus Drive
1400, Partners II
Raleigh
NC
27608

david_bird@ncsu.edu
960012
Biron
David
Physics, JFI
University of Chicago
929 E. 57th St.
GCIS E139F
Chicago
IL
60637

dbiron@uchicago.edu
960921
Birsoy
Bilge
Dept MCDB, NRI
Univ California, Santa Barbara
Bldg 571, Rm 6129
Santa Barbara
CA
93106

birsoy@lifesci.ucsb.edu
961155
Bishop
Nicholas
Pathology
Harvard Medical School
77 Avenue Louis Pasteur
NRB-858
Boston
MA
2115

nicholas_bishop@hms.harvard.edu
961499
Black
Joshua
Tumor Biology
MGH
103 Ninth St. Apt. 130
Charlestown
MA
2129

blackjc@gmail.com
960416
Blackwell
T

Joslin Diabetes Ctr
One Joslin Place
Boston
MA
2115

keith.blackwell@joslin.harvard.edu
961479
Blick
Dan

University of Washington
1705 NE Pacific St
Foege Building S-250, Box 355065
Seattle
WA
98195

blick@u.washington.edu
960278
Blum
Elyse
Shaham Lab
Rockefeller Univ
1230 York Ave #233
New York
NY
10065

blume@mail.rockefeller.edu
960107
Blumenthal
Tom
Dept Molec, Cellular, Dev Biol
Univ Colorado
347 UCB

Boulder
CO
80309-0347

tom.blumenthal@colorado.edu
961481
Boeck
Max
Dept Genome Sci
Univ Washington
1705 NE Pacific St
Seattle
WA
98103

maxboeck@u.washington.edu
960360
Bostelen
Ivo
Dept. of Genetics
Harvard Medical School
77 Ave Louis Pasteur, NRB-334
Boston
MA
2115

Ivo_VanBostelen@hms.harvard.edu
960967
Boulias
Konstantinos
Dept Biol
MIT
31 Ames St

Cambridge
MA
2139

boulias@mit.edu
960788
Brejc
Katjusa
MCB
UC Berkeley/HHMI
131 Koshland Hall
Berkeley
CA
94720-3204

kbrejc@berkeley.edu
961168
Brenner
John
Dept Biological Sci
Marquette Univ
530 N 15th St
Milwaukee
WI
53201

john..brenner@marquette.edu
960359
Breving
Kimberly
Microbiology/Molecular Cell Biol
Eastern Virginia Medical School
700 W. Olney Road LH3055
Norfolk
VA
23507

brevinka@evms.edu
960344
Brodigan
Thomas

LMB/NIDDK/NIH
5 Center Dr

Bethesda
MD
20892

thomasbr@intra.niddk.nih.gov
960654
Brooks
Alison
Basic Sciences
Fred Hutchinson Cancer Res Ctr
1100 Fairview Ave N
B2-152
Seattle
WA
98109

anbrooks@u.washington.edu
960358
Brooks
Jacqueline
Dept Molec & Cellular Biol
Harvard Univ
16 Divinity Ave
Cambridge
MA
2138

jbrooks@mcb.harvard.edu
961074
Buckley
Beth
Genetics
Univ Wisconsin-Madison
425G Henry Mall, Room 2476
Madison
WI
53706

babuckley@wisc.edu
961388
Budovskaya
Yelena
Dept Dev Biol
Stanford Univ
279 Campus Dr, Beckman Ctr
Stanford
CA
94305

yelenab@stanford.edu
961245
Buechner
Matthew
Dept Molec Biosci
Univ Kansas
1200 Sunnyside Dr,Haworth Hall
Lawrence
KS
66045-7534

buechner@ku.edu
960742
Buelow
Hannes
Genetics
Albert Einstein/Yeshiva Univ
1300 Morris Park Ave
Bronx
NY
10461

hbuelow@aecom.yu.edu
961072
Burkhart
Kirk
Genetics
Univ Wisconsin
425G Henry Mall, Room 2476
Madison
WI
537061580

kburkhart@wisc.edu
960963
Butcher
Rebecca
Dept Biol Chem & Molec Pharm
Harvard Medical Sch
240 Longwood Ave
Boston
MA
2115

rebecca_butcher@hms.harvard.edu
960639
Caldwell
Guy
Dept Biological Sciences
The University of Alabama
411 Hackberry Lane
Tuscaloosa
AL
35487-0344

gcaldwel@bama.ua.edu
960640
Caldwell
Kim
Dept Biological Sciences
The University of Alabama
411 Hackberry Lane
Tuscaloosa
AL
35487-0344

kcaldwel@biology.as.ua.edu
960017
Canavello
Peter
Pharmacology
Tulane University
1430 Tulane Avenue
New Orleans
LA
70122

pcanavel@tulane.edu
961515
Candera
Leon
Biology
Cal.State Univ. San Bernardino
5500 University Pkwy
San Bernardino
CA
92407

lcandera@csusb.edu
960314
Canman
Julie
CMM East, Rm 3071 G
Ludwig Inst Cancer Res
9500 Gilman Dr
La Jolla
CA
92093

jcanman@ucsd.edu
960452
Cannataro
Vincent
Biology
SUNY College at Geneseo
1 College Circle
332 Integrated Science Center
Geneseo
NY
14454

vlc2@geneseo.edu
961276
Cao
Pengxiu
Pharmacology
Case Western Reserve Uni.
10900 Euclid Ave
Cleveland
OH
44106

cao.pengxiu@case.edu
961174
Capua
Yossi

NYU
540 First Avenue
New York
ny
10016

josef.capua@med.nyu.edu
960229
Carey
James
Molecular Medicine
Univ Massachusetts Med School
377 Plantation St
Worcester
MA
1605

james.carey@umassmed.edu
960575
Carmona
Juan
Pathology
Harvard Med School
77 Ave Louis Pasteur
Boston
MA
2115

carmona@fas.harvard.edu
960100
Carnell
Lucinda
Dept Biological Sci
Central Washington
400 E. University Way
7537
Ellensburg
WA
98926

carnelll@cwu.edu
960082
Carrera
Ines
Biochem and Mol Biophys
701 W 168th St HHSC room 726
New York
NY
10032

ic2255@columbia.edu
960598
Carter
Luke
Institute of Molecular Biology
University of Oregon
1370 Franklin Blvd
Eugene
OR
97403

rapter987@hotmail.com
960942
Cary
Michael
BMI
UCSF
788 Harrison Street
414
San Francisco
CA
94107

michael.cary@uscf.edu
960821
Castro
Ian

University of Florida
1600 sw archer rd
Gainesville
Fl
32610

castro@iq.unesp.br
961442
Caylor
Raymond


1200 Sunnyside Ave
Lawrence
KS
66045

raycay3@ku.edu
960594
Cecere
Germano
Biochemistry
Columbia University
701 West 168th
New York
NY
10032

gc2352@columbia.edu
961118
Chalasani
Sreekanth
Laboratory Neural Circuits
Rockefeller Univ
1201 York Ave, Box 204
New York
NY
10065

schalasani@mail.rockefeller.edu
960029
Chalfie
Martin
Dept Biol
Columbia Univ
1212 Amsterdam St
New York
NY
10027

mc21@columbia.edu
960482
Chan
Emily

New York University SOM
540 1st Avenue Lab 4-17
New York
NY
10016

ec1214@med.nyu.edu
960997
Chan
Jason
Zilkha Neurogenetic Inst
Univ So California
1501 San Pablo St
Los Angeles
CA
90033

jasonpch@usc.edu
960910
Chan
Shih-Peng
Dept Molec Cell, Dev Biol
Yale Univ
PO Box 208103
New Haven
CT
6520

shih-peng.chan@yale.edu
961119
Chang
Howard
Biology
MIT
77 Mass Ave
68-440
Cambridge
MA
2139

hcchang@mit.edu
960623
Chang
Yu-Tai
Molec & Cellular Biol
Univ California, Davis
139 Briggs Hall
Davis
CA
95616

ytchang@ucdavis.edu
961146
Chao
Lucy Fang-I

UMass Medical School
377 Plantation Street
Worcester
MA
1605

Lucy.Chao@umassmed.edu
961512
Chao
Michael
Dept Biol
California State Univ
5500 University Pkwy
San Bernardino
CA
92407

mchao@csusb.edu
960129
Chapman
Jamie
Dept Molecular Biosci
Univ Kansas
5049 Haworth Hall
Lawrence
KS
66045

chapman@ku.edu
960948
Chatterjee
Indrani
Genetics
Waksman Institute, Rutgers
Frelinghuysen Road
Piscataway
NJ
8854

icchatterjee@gmail.com
960190
Chaves
Daniel
Prog Molec Med/Univ Lisbon
Univ Massachusetts Med Sch
373 Plantation St
Worcester
MA
1605

daniel.chaves@umassmed.edu
960408
Chen
Bojun
Dep Neuroscience
Univ Connecticut Health Ctr
263 Farmington Ave
Farmington
CT
6030

bochen@uchc.edu
961102
Chen
Di

Buck Inst
8001 Redwood Blvd
Novato
CA
94945

dchen@buckinstitute.org
960634
Chen
Grace
Developmental Biology/Genetics
Stanford University
279 Campus Dr, B300 Beckman
Stanford
CA
94305

glin1@stanford.edu
960938
Chen
Kan
Biochem & Biophys
UCSF
600 16th Street
S314
San Francisco
CA
94158

kan.chen@uscf.edu
960929
Chen
Ling
Neuroscience Res Inst
Univ California, Santa Barbara
Santa Barbara
CA
93106

l_chen@lifesci.ucsb.edu
960622
Chen
Lizhen
Biology
UCSD
9500 Gilman Drive #0368
La Jolla
CA
92093

lizhen@ucsd.edu
961433
Chen
Lu
Dept Molec Pharmacology
Albert Einstein Col Medicine
1300 Morris Park Ave
Bronx
NY
10461

luchen@aecom.yu.edu
960644
Chen
Pan
Biology
The University of Alabama
411 Hackberry Lane
Tuscaloosa
AL
35487

pchen3@bamamail.ua.edu
960494
Chen
Wen
Div Biol
California Inst Technology
1200 E California Blvd
156-29
Pasadena
CA
91125

wchen@cco.caltech.edu
960373
Chen
Xiangmei
Dept Molecular Biol
Univ Med & Dentistry of NJ
2 Medical Dr

Stratford
NJ
8084

chenx4@umdnj.edu
961474
chen
Xiaoyin

columbia University
1212 Amsterdam Ave
NY NY
nY
10027

xc2123@columbia.edu
961470
Chen
Yushu

Columbia University
1212 Amsterdam Ave
NY NY
NY
10027

yc2332@columbia.edu
961562
Chen
Zhunan
Organismic and Evolutionary Bio.
Harvard University
Oxford St. 52

Cambridge
MA
2138

zachen86@yahoo.com
961508
Chia
Poh Hui
Biology
Stanford
1 Comstock Circle, Apt103
Stanford
CA
94305

pchia@stanford.edu
961261
Chiang
Michael
Development & Cell Biol
UC Irvine
McGaugh Hall

Irvine
Ca
92697

mcah5a@gmail.com
961437
Chiang
Wei-Chung
Internal Med.-Geriatric Med
University of Michigan
109 Zina Pitcher Pl, Rm 2248
Ann Arbor
MI
48109-2200

weichun@umich.edu
961139
Chien
Shih-Chieh
Dept Molecular & Cell Biol
Univ California, Berkeley
16 Barker Hall
Berkeley
CA
94720

scchien@berkeley.edu
960197
Chihara
Daisuke
Skirball Institute
NYU
540 First Ave., SK4-17
New York
NY
10016

Daisuke.Chihara@nyumc.org
961035
Chin
Randall

UC Los Angeles
650 Charles E Young Drive South
Los Angeles
CA
90095

randallc@ucla.edu
960903
Chiorazzi
Michael

Rockefeller Univ
1230 York Ave
New York
NY
10065

mchiorazzi@rockefeller.edu
960631
Chisholm
Andrew
Dept Biological Sci, #0368
Univ California, San Diego
9500 Gilman Dr,2402Bonner Hall
La Jolla
CA
92093-0368

chisholm@ucsd.edu
960136
Cho
Julie
Biology
Calif Institute of Technology
1200 E. California Blvd
156-29
Pasadena
CA
91125

juliec@caltech.edu
960500
Choe
Andrea
Dept Biol
Caltech
1200 E California Blvd
Pasadena
CA
91125

ac@caltech.edu
960264
Choi
Seungwon
Molecular Biology
Massachusetts General Hospital
185 Cambridge St.
Simches building 7th floor
Boston
MA
2114

choi11@fas.harvard.edu
960922
Choi
Shin
NRI
Univ California, Santa Barbara
Bldg 571, Rm 6129
Santa Barbara
CA
93106-5060

choi@lifesci.ucsb.edu
961180
Chokshi
Trushal
EECS
Univ Michigan
1807 Willowtree lane, Apt#7B
Ann Arbor
MI
48109

tchokshi@umich.edu
960153
Chrisman
Steven
Biological Sciences
Central Washington University
400 East University Way
7537
Ellensburg
WA
98926

chrismans@cwu.edu
960750
Chronis
Nikos
Dept Mechanical Engineering
Univ Michigan
2350 Hayward
Ann Arbor
MI
48109

chronis@umich.edu
961400
Chu
Diana
Dept Biol
San Francisco State Univ
1600 Holloway Ave
San Francisco
CA
94132

chud@sfsu.edu
961337
Chung
Kwanghun
Chemical & Biomolecular Engine
Georgia Institute of Technolog
311 Ferst Dr

Atlanta
GA
30332-0100

kwanghun.chung@chbe.gatech.edu
960992
Cinar
Hediye
Div Virulence Assessment
Food & Drug Admin
8301 Muirkirk Rd
Laurel
MD
20708

hediye.cinar@fda.hhs.gov
961260
Cinquin
Olivier
Development & Cell Biol
UC Irvine
4103 Mcgaugh Hall
Irvine
CA
92697

ocinquin@uci.edu
960366
Cintra
Thais
Biolgoy/SEO
San Francisco State University
1600 Holloway Ave.
San Francisco
CA
94132

thais_gc@hotmail.com
961496
Cipriani
Patricia
Dept Biol
New York Univ
100 Washington Square St
New York
NY
7071

pgc212@nyu.edu
961367
Clark
Scott
Biology
University of Nevada, Reno
1664 North Virginia Street
314
Reno
NV
89557

sgclark@unr.edu
960647
Claycomb
Julie
Program Molecular Medicine
Univ Massachusetts Med Sch
373 Plantation St, BT II 217
Worcester
MA
1605

julie.claycomb@umassmed.edu
961491
Coblitz
Brian
Biological Sci
Columbia Univ
1212 Amsterdam Ave, Rm 1012
New York
NY
10027

bcoblitz@columbia.edu
960793
Cohen
Alysse
MCDB
University of Michigan
830 North University
Ann Arbor
MI
48109

alysse@umich.edu
960683
Cohen
Max

University of Colorado
Campus Box 0347
Boulder
CO
80309-0347

max.cohen@colorado.edu
960357
Colaiacovo
Monica
Dept Genetics
Harvard Medical Sch
77 Ave Louis Pasteur, NRB-334
Boston
MA
2115

colaiaco@receptor.med.harvard.edu
961258
Collette
Karishma
Dept MCDB
Univ Michigan
830 North University
Ann Arbor
MI
48103

karishms@umich.edu
961114
Collier
Sara
Developmental Biology
Washington University of STL
660 S. Euclid

St. Louis
mo
63110

CollierS@Wustl.edu
960044
Colon-Ramos
Daniel
Dept Cell Biol
Yale Sch Med
295 Congress Ave, BCMM 436B
New Haven
CT
6510

daniel.colon-ramos@yale.edu
960897
Conery
Annie
Molecular Biology Department
Massachusetts General Hospital
185 Cambridge St. CPZN-7250
Boston
MA
2114

aconery@molbio.mgh.harvard.edu
961033
Conine
Colin
Molecular Medicine
Umass Medical School
55 Lake Ave.

Worcester
MA
1545

colinconine@gmail.com
960310
Contreras
Vince
Dept Biochem
East Carolina Univ
600 Moye Blvd
Greenville
NC
27834

vc0307@ecu.edu
960308
Corkins
Mark

MGH/HMS
149 13th st rm7103
Charlestown
Ma
2129

mcorkins@partners.org
961262
Correa
Paola

Texas A&M
1101 Southwest Parkway
College Station
TX
77840

pcorrea@bio.tamu.edu
961126
Cottee
Pauline
Dept Cell Biol
Univ Alabama at Birmingham
THT 958, 1900 Univ Blvd
Birmingham
AL
35294

pcottee@uab.edu
960653
Cox
Elisabeth
Biology
SUNY Geneseo
1 College Circle
337 ISC
Geneseo
NY
14454

coxe@geneseo.edu
960960
Cram
Erin
Dept Biol
Northeastern Univ
360 Huntington Ave
Boston
MA
2115

e.cram@neu.edu
960729
Crane
Emily
MCB Dept, HHMI
Univ California, Berkeley
16 Barker Hall
Berkeley
CA
94720

emily@crane.net
961390
Crane
Matthew


936 White St SW
Atlanta
GA
30310

n.omadcrane@gmail.com
960606
Cregg
James
Dept Biological Sci
Univ California, San Diego
9500 Gilman Dr, Dept 0634
La Jolla
CA
92093

jcregg@ucsd.edu
961014
Crittenden
Sarah
Dept Biochemistry, HHMI
Univ Wisconsin, Madison
433 Babcock Dr
Madison
WI
53706-5144

slcritte@wisc.edu
961469
Crossgrove
Kirsten
Dept Biological Sci
Univ Wisconsin, Whitewater
800 W Main St
Whitewater
WI
53190

crossgrk@uww.edu
961283
Crum
Tanya
Dept Biological Sci
Univ Illinois
900 S Ashland Ave
567
Chicago
IL
60607

tcrum2@uic.edu
960904
Cui
Mingxue
Dept MCDB
Univ Colorado

Boulder
CO
80302

cuim@colorado.edu
960527
Curran
Sean
Dept Molecular Biol
Massachusetts General Hosp
185 Cambridge St, CPZN7250
Boston
MA
2114

curran@molbio.mgh.harvard.edu
960619
Czyz
Daniel


851 Blossom Ln, Apt. 307
Prospect Heights
IL
60070

d-czyz@northwestern.edu
960807
Dabbish
Nooreen
Neuroscience
University of Pennsylvania
125 S. 31st Street
Philadelphia
PA
19104

nooreen@mail.med.upenn.edu
960345
Dach
Neal
Cancer Ctr
Massachusetts Gen Hosp
452 Hanover St Apt 301
Boston
MA
2113

nealdach@yahoo.com
960838
Dahlberg
Caroline
Cellular & Molecular Physiology
Tufts University

Boston
WA
98105

lina.l.dahlberg@gmail.com
960179
Dalfo
Diana
Department of Phatology
Skirball Institute, NYU
540 First Ave

New York
NY
10016

dalfod01@med.nyu.edu
961355
Dasgupta
Krishnakali
Zilkha Neurogenetic Institute
Univ. of Southern California
1501 San Pablo St.
Los Angeles
CA
90033

kdasgupt@usc.edu
960834
Davey
Lisa

NYU
100 Washington Square Park E
New York
NY
10009

lisa.m.davey@gmail.com
960489
day
Amanda
Human Genetics
University of Michigan
210 washtenaw ave
Ann Arbor
MI
48109

dayama@umich.edu
960712
De Jong
Deborah
Dept Molec & Cell Biol
Harvard Univ
16 Divinity Ave, BL3050
Cambridge
MA
2138

dejong@mcb.harvard.edu
961328
de la Cova
Claire
Biochemistry
Columbia University
701 West 168th Street
New York
NY
10032

ccd24@columbia.edu
960896
de la Cruz
Norberto

WormBase - OICR
711 Robertson
Wauwatosa
WI
53213

noriedlc3@gmail.com
961333
de Lencastre
Alexandre

Yale University
219 Prospect St
New Haven
CT
6511

alexandre.delencastre@yale.edu
960762
De Orbeta
Jessica
Dept Gen
UT MD Anderson Cancer Ctr
1515 Holcombe Blvd Unit 1006
Houston
TX
77098

jdeorbe@mdanderson.org
960418
Decker
Johannes

Rockefeller Univ

New York
NY
10065

hdecker@rockefeller.edu
961038
DeGenova
Sarah

College New Jersey
Pennington

Ewing
NJ
8628

degenov2@tcnj.edu
960234
Demarco
Rafael
Molecular Biosciences
University of Kansas
951 Arkansas St apt L5
Lawrence
KS
66044

rafael@ku.edu
960497
DeModena
John
Div Biol, 156-29
California Inst Technology
1200 E California Blvd
156-29
Pasadena
CA
91125

demoj@caltech.edu
960986
Deng
Xinzhu
Dept Molecular Pharmacology
Sloan-Kettering Inst
415 68th St, ZRC-1819
New York
NY
10028

x-deng@ski.mskcc.org
960673
Dennis
Shannon

FHCRC
1100 Fairview Ave N
A3-013
Seattle
WA
98144

smm04@u.washington.edu
961193
DePellegrin Connelly
Tracey
Mellon Inst
Carnegie Mellon Univ
Box 1, 4400 Fifth Ave
Pittsburgh
PA
15213

td2p@andrew.cmu.edu
960420
DePina
Ana
Laboratory of Neurosciences
Biomedical Research Center/NIA
251 Bayview Blvd
Baltimore
MD
21224

depinaa@grc.nia.nih.gov
961274
Depper
Micah

Lewis & Clark College
0615 SW Palatine Hill Rd
Portland
OR
97219

mdepper@lclark.edu
960970
Dernburg
Abby

Univ California, Berkeley
470 Stanley Hall, MC 3220
Berkeley
CA
94720-3220

afdernburg@lbl.gov
960304
Deshmukh
Krupa
Developmental biology
Washinton university St.Louis
660 S.Euclid Avenue
Saint Louis
MO
63112

kdeshmukh@wustl.edu
960491
Dillman
Adler
Biology
California Inst Tech
1200 E California Blvd
156-29
Pasadena
CA
91125

adlerd@caltech.edu
960312
Dimitriadi
Maria

MGH Cancer Center
13th Street

Charlestown
MA
2129

mdimitriadi@hotmail.com
961362
Dimitrov
Ivan
Developmental Biology
Washington University in St. Lou
440 S. Euclid Ave
St. Louis
MO
63110

dimitrovi@wustl.edu
960932
Djabrayan
Nareg
NRI
UCSB
Bldg 571, rm 6129
Santa Barbara
CA
93106

djabrayan@lifesci.ucsb.edu
960905
Doh
Jung

University at Albany
1400 Washington Ave.
Albany
NY
12222

jd885462@albany.edu
960078
Doitsidou
Maria
Dept Biochemistry
Columbia Univ
701 W 168th St, HHSC 710
New York
NY
10032

md2398@columbia.edu
960508
Doma
Meenakshi
Dept Biol
California Inst Technology
1200 East California Blvd
156-29
Pasadena
CA
91125

mkdoma@caltech.edu
960607
Dong
Yongming
Life Science Institute
University of Michigan
210 Washtenaw Avenue
Ann Arbor
MI
48109

ymdong@umich.edu
960330
Doroquez
David
Dept Biol
Brandeis Univ
415 South St, MS008
Waltham
MA
2454

doroquez@brandeis.edu
960755
Doty
Alana
BEES Program
Univ Maryland College Park
1210 Biol-Psychology Bldg
College Park
MD
20742

adoty@umd.edu
960736
Douglas
Kristin
Dept Biol
Augustana Col
639 38th St

Rock Island
IL
61201

kristindouglas@augustana.edu
960024
Drace
Kevin
Biology
Mercer University
1400 Coleman Avenue
Macon
GA
31207

drace_km@mercer.edu
961445
Driscoll
Monica
Dept Molec Biol/Biochem
Rutgers Univ
604 Allison Rd, Nelson LabA232
Piscataway
NJ
8854

driscoll@waksman.rutgers.edu
960920
Dudley
Nate
Dept MCDB/NRI
Univ California, Santa Barbara
Bldg 571, rm 6129, Biol II
Santa Barbara
CA
93106

ndudley@lifesci.ucsb.edu
960823
Dumas
Kathleen
Cellular and Molecular Biology
LSI, University of Michigan
210 Washtenaw Ave
Ann Arbor
MI
48105

kjdumas@umich.edu
960315
Dunn
Cory
HHMI
Columbia Univ
701 W 168th St
HHSC 720
New York
NY
10032

cd2282@columbia.edu
961564
Durak
Omer
Biology
Calif Institute of Technology
1200 E. California Blvd.
MC 156-29
Pasadena
CA
91125

omerdrk@caltech.edu
960840
Eastwood
Amy
Mol and Cell Physiol
Stanford University
279 Campus Drive
Stanford
CA
94305

aeastwood@stanford.edu
960873
Edelman
Theresa
Genetics, Cell Biology & Devel
1025 29th Ave SE Apt F
Minneapolis
MN
55414

brixx001@umn.edu
960646
Edison
Arthur
BIOCHEMISTRY & MOLE. BIOLO
UNIVERSITY OF FLORIDA
1600 SW Archer Road
P.O. Box 100245
Gainesville
Fl
32610

art@mbi.ufl.edu
961128
Edmonds
Wes
Cell Biol
Univ Alabama at Birmigham
Birmingham
AL
35294

edmondsw@uab.edu
961082
Edwards
Tyson
Genetics
Yale University
295 Congress, BCMM Rm. 437
New Haven
CT
6511

tyson.edwards@yale.edu
960446
Eisenmann
David
Dept Biological Sci
Univ Maryland, Baltimore Cty
1000 Hilltop Circle
Baltimore
MD
21250

eisenman@umbc.edu
960827
El Bejjani
Rachid
Department of genetics
Yale University
295 congress st Rm 0437
New Haven
CT
6511

rachid.elbejjani@yale.edu
960387
Ellis
Ronald
Dept Molecular Biol
UMDNJ-SOM
2 Medical Center Dr
Stratford
NJ
8084

ron.ellis@umdnj.edu
961065
Engebrecht
JoAnne
Molec & Cellular Biol
Univ California, Davis
One Shields Ave, Briggs Hl 130
Davis
CA
95616

jengebrecht@ucdavis.edu
961279
Ernstrom
Glen
Dept Biol
Univ Utah
257 South 1400 East
Salt Lake City
UT
84112

glen.ernstrom@gmail.com
960715
Estes
Kathleen
Biology
UC San Diego
9500 Gilman Dr
349
La Jolla
CA
92093-0349

esteskt@gmail.com
961369
Ewald
Collin
Biology
City University of New York
160 Convent Ave; Marshek J-526
New York
NY
10031

cewald@gc.cuny.edu
960600
Fabritius
Amy

UC Davis
1959 Lake Boulevard, 233
Davis
CA
95616

asfabritius@ucdavis.edu
960507
Fang
Ruihua
Biology
Calif Inst of Technology
1200 E. California Blvd
156-29
Pasadena
CA
91125

rfang@caltech.edu
960956
Fang-Yen
Chris
Physics
Harvard University
17 Oxford Street
Cambridge
MA
2138

cfangyen@gmail.com
960074
Fantz
Douglas
Dept Chemistry
Agnes Scott Col
141 E College Ave
Decatur
GA
30030

dfantz@agnesscott.edu
961235
Farley
Brian
Biochem & Molec Pharm
Univ Massachusetts Med Sch
364 Plantation St
Worcester
MA
1605

brian.farley@umassmed.edu
961560
Fay
David
Dept Molec Biol
Univ Wyoming
1000 E. University Ave. Dept. 3944
Laramie
WY
82071-3944

davidfay@uwyo.edu
960783
Fazzio
Michael

Union Biometrica
84 October Hill Road
Holliston
MA
1746

mfazzio@unionbio.com
960983
Fedotov
Alexander
Biology
Emory University
1510 Clifton Rd, Rm 2074
Atlanta
GA
30322

afedoto@emory.edu
960882
Feldman
Jessica
Basic Sciences
Fred Hutchinson Cancer Res Ctr
1100 Fairview Ave N
A3-013
Seattle
WA
98109

jlfeldma@fhcrc.org
960273
Feliu-Mojer
Monica
Molecular Biology
Mass General Hospital
185 Cambridge St
Boston
MA
2130

feliu-mojer@molbio.mgh.harvard.edu
960240
Felton
Terry
Biochem & Biophysics
Columbia University
701 West 168Tth ST
HHSC/7th Floor
New York
NY
10032

terryfltn@gmail.com
961086
Feng
Dingxia
GDCB
Iowa State University
2132 MBB

Ames
IA
50010

fengdxia@iastate.edu
960037
Ferkey
Denise
Biological Sciences
University at Buffalo, SUNY

Buffalo
NY
14260

dmferkey@bio.buffalo.edu
961016
Fernandez
Anita
Dept Biol
Fairfield Univ
1370 N Benson Rd
Fairfield
CT
6824

afernandez@mail.fairfield.edu
961039
Fiaschi
Michela

College New Jersey

Ewing
NJ
8628

fiaschi2@tcnj.edu
961357
Firnhaber
Christopher

Yale University
295 Congress Ave
New Haven
CT
6510

christopher.firnhaber@yale.edu
960984
Fischer
Sylvia
Dept Molecular Biol
Massachusetts General Hosp
185 Cambridge St
Boston
MA
2114

fischer@molbio.mgh.harvard.edu
960902
Fitch
David
Biology
NYU- Silver 1009
100 Washington Square East
New York
NY
10003

david.fitch@nyu.edu
960081
Flames
Nuria
Dept Biochem/Molec Biophysics
Columbia Univ
701 W 168th St, HHSC 710
New York
NY
10032

nf2171@columbia.edu
960678
Forbes
Emily

MGH/ HMS
149 13th street
7.103
Charlestown
MA
2129

emma244@gmail.com
960753
Ford
Jason
Gen, Unit 1010
UT MD Anderson Cancer Ctr
1515 Holcombe Blvd
Houston
TX
77030

jford@mdanderson.org
960138
Foss
Eric
Biological Science
Central Washington Univ.
400 E University Way
7537
Ellensburg
WA
98926

fosse@cwu.edu
961340
Fox
Paul
Genetics
Washington Univ, Sch Medicine
4566 Scott Ave
St Louis
MO
63110

pmfox@wustl.edu
961277
Fraire-Zamora
Juan
Dept Biol
Univ California
3401 Watkins dr
Riverside
CA
92507

jfrai001@student.ucr.edu
960214
Frand
Alison
David Geffen Medical School
UCLA
650 Charles Young Drive
Los Angeles
CA
90025

afrand@mednet.ucla.edu
960674
Fridolfsson
Heidi
Molec & Cellular Biol
Univ California, Davis

Davis
CA
95616

hnpetersen@ucdavis.edu
961116
Frokjaer-Jensen
Christian
HHMI, Dept Biol
Univ Utah
257 South 1400 East
Salt Lake City
UT
84103

christianfj@gmail.com
961278
Fry
Amanda
Ctr Cell Biol & Cancer Res
Albany Med College

Albany
NY
12208

frya@mail.amc.edu
961352
Fu
Ya
Dept Molecular Pharmacology
Albert Einstein Col Medicine
1300 Morris Park Ave
Bronx
NY
10461

yfu@aecom.yu.edu
960844
Furukawa
Miho
Dept Pathology
Emory Univ
615 Michael St
Atlanta
GA
30322

miho.furukawa@gmail.com
961308
Gabel
Christopher
Dept Physics
Harvard Univ
17 Oxford st

Cambridge
MA
2138

gabel@fas.harvard.edu
961519
Gallagher
Johnie
Molecular Biosci
Univ Kansas
5004 Haworth Hall
Lawrence
KS
66045

meercat515@hotmail.com
961453
Gallegos
Maria
Dept Biol
Cal State Univ, East Bay
25800 Carlos Bee Blvd
Hayward
CA
94542

maria.gallegos@csueastbay.edu
961349
Gallo
Christopher
Dept Molecular Biol & Genetics
Johns Hopkins Univ
725 N Wolfe St, 706 PCTB
Baltimore
MD
21205

cgallo2@jhmi.edu
960350
Gao
Jingwei

Life Sciences Institute
210 Washtenaw Avenue
Ann Arbor
MI
48109

jwgao@umich.edu
960466
Garcia
L
Dept Biol
Texas A&M Univ
3258 TAMU
3258
College Station
TX
77843

rgarcia@mail.bio.tamu.edu
960913
Garcia
Susana
Dept Molec Biol
Massachusetts Gen Hosp
185 Cambridge St, CPZN-7250
Boston
MA
2114

garcia@molbio.mgh.harvard.edu
960733
Gargus
John
Human Genetic/ Peds/Physiology
Univ California, Irvine
328 Sprague Hall
Irvine
CA
92697-4034

jjgargus@uci.edu
961533
Garrigues
Jacob
MCD Biology
UC Santa Cruz
1156 High St./329 Sinsheimer Labs
Santa Cruz
CA
95064

garrigues@biology.ucsc.edu
960492
Gaydos
Laura
MCD Biol
UC Santa Cruz
1156 High St

Santa Cruz
CA
95064

ljgaydos@biology.ucsc.edu
960407
Ge
Qian
Dept Neuroscience
Univ Connecticut Health Ctr
263 Farmington Ave
Farmington
CT
6032

qge@uchc.edu
960849
Gelino
Sara
Development & Aging
Burnham Institiute Med Res
10901 North Torrey Pines Rd
La Jolla
CA
92037

sgelino@burnham.org
961514
Genovez
Marx
Biology
Cal.State Univ. San Bernardino
5500 University Pkwy
San Bernardino
CA
92407

mgenovez@gmail.com
960964
Gerke
Justin
Genomics
Princeton University
114 Carl Icahn Lab
Princeton
NJ
8544

jgerke@princeton.edu
960941
Ghazi
Arjumand
Dept Biochem & Biophysics
Univ California, San Francisco
600 16th St, Rm S314
San Francisco
CA
94158

arjumandg@gmail.com
960537
Ghose
Piya
Neuroscience
Rutgers Univ


Piscataway
NJ
8854

piyag@waksman.rutgers.edu
960995
Ghosh
Rajarshi
Ecology and Evolutionary Biology
Princeton University
110 Carl Icahn Building
Princeton
NJ
8540

rajarshi@princeton.edu
960914
Ghosh Roy
Anindya
Div Biological Sci
UCSD, Room2429, Bonner Hall
9500 Gilman Dr
La Jolla
CA
92093-0368

aghoshroy@ucsd.edu
960770
Gill
Matthew

Buck Institute
8001 Redwood Blvd
Novato
CA
94945

mgill@buckinstitute.org
960955
Gissendanner
Chris
Dept Biol
Univ Louisiana, Monroe
700 Univ Ave

Monroe
LA
71209

gissendanner@ulm.edu
961454
Glover-Cutter
Kira
Developmental/Stem Cell Bio
Harvard, Joslin Diabetes Cntr
1 Joslin Place, room 665
Boston
MA
2215

kira.glover-cutter@joslin.harvard.edu
960238
Go
Aiza Cathe
Biology
San Francisco State University
1600 Holloway Avenue
San Francisco
CA
94132

aizacathe@gmail.com
961067
Golden
Andy
Lab Biochem & Gen
NIDDK/NIH
8 Ctr Dr, Bldg 8/Rm 323
Bethesda
MD
20892-0830

andyg@mail.nih.gov
960241
Goldsmith
Andrew
Genetics & Development
Columbia University
701 West 168th ST
HHSC/7th Floor
New York
NY
10032

adg2110@columbia.edu
960734
Goodman
Miriam
Dept Molec, Cell Physiology
Stanford Univ
279 Campus Dr
Stanford
CA
94305

mbgoodman@stanford.edu
960186
Goodwin
Patricia
Dept Physiology
Tufts Univ
150 Harrison Ave
Boston
MA
2111

patricia.goodwin@tufts.edu
960780
Gopinath
Vidya

Haverford College
Lancaster Avenue
Haverford
PA
19041

pmeneely@haverford.edu
961125
Gordus
Andrew
Bargmann Lab
The Rockefeller University
1230 York Ave
New York
NY
10065

agordus@rockefeller.edu
960426
Gorrepati
Lakshmi
Biological Sci
UMBC
1000 Hilltop Circle
Baltimore
MD
21250

lakshmi2@umbc.edu
960837
Gotenstein
Jennifer
Div Biological Sci
Univ California, San Diego
9500 Gilman Dr
Bonner Hall 2401
La Jolla
CA
92093

jgotenst@ucsd.edu
960194
Govindan
J
Dept Gen, Cell Biol & Dev
Univ Minnesota
420 Washington Ave, SE
Minneapolis
MN
55455

govin017@umn.edu
960812
Govorunova
Elena

Albert Einstein College of Medic
1300 Morris Park Ave
Bronx
NY
10461

egovorun@aecom.yu.edu
960247
Gowtham
Sriharsh
Biochemistry
Columbia University
701 West 168th ST
HHSC/7th Floor
New York
NY
10032

smg2110@columbia.edu
960385
Goy
Jo
Biological Sci
Univ North Texas
1155 Union Circle, #305220
Denton
TX
76203

jmgoy@harding.edu
961296
Greaver
Liane
Biology
CSU San Bernardino
5500 University Parkway
San Bernardino
CA
92407

greaverl@csusb.edu
961527
Green
Rebecca
Dept Cell/Molec Med, 3071G
LICR - UCSD
9500 Gilman Dr, CMME
La Jolla
CA
92093

regreen@ucsd.edu
960774
Greenstein
David
GCD Dept, 4-208 MCB
Univ Minnesota
420 Washington Ave SE
Minneapolis
MN
55455

green959@umn.edu
961532
Griffen
Trevor
Dept Neuroscience
USC, Keck Sch Medicine
1501 San Pablo St.
Los Angeles
CA
90089

trevor.griffen@alumni.brown.edu
960842
Grossman
Emily

Univ California: San Diego
9500 Gilman Drive
La Jolla
CA
92093

egrossma@ucsd.edu
961341
Grussendorf
Kelly
Molecular Biosciences
University of Kansas
8035 Haworth 1200 Sunnyside Av
Lawrence
KS
66045

grusseke@ku.edu
960994
Gu
Weifeng
Program Molecular Medicine
Univ Massachusetts Medical Sch
373 Plantation St
Worcester
MA
1605

weifeng.gu@umassmed.edu
960202
Guang
Shouhong
Dept Genetics
Univ Wisconsin, Madison

Madison
WI
53706

sguang@wisc.edu
961083
Gumienny
Tina
Molec & Cellular Med
Texas A&M HSC
446 Joe H Reynolds Med Bldg
College Station
TX
77843-1114

gumienny@medicine.tamhsc.edu
961477
Gunsalus
Kristin
Dept Biol, 1009 Silver Bldg
New York Univ
100 Washington Square E
New York
NY
10003

kcg1@nyu.edu
960881
Guo
Xiaoyan
Biol
Texas A&M Universtiy
Texas A&M Universtiy
College Station
TX
77843

xguo@mail.bio.tamu.edu
960372
Guo
Yiqing
Dept Molecular Biol
UMDNJ
2 Medical Center Dr
Stratford
NJ
8084

guoyi@umdnj.edu
960701
Guo
Zengcai

Harvard Univ
52 Oxford ST

Cambridge
MA
2138

zguo@fas.harvard.edu
961141
Gurling
Mark
Molecular and Cell Biol
UC-Berkeley
16 Barker Hall
Berkeley
CA
94720

mgurling@berkeley.edu
960979
Guthrie
Chris

VA Puget Sound Hlth Care Sys
1660 S Columbian Way
S-182
Seattle
WA
98108

cguthrie@u.washington.edu
961440
Haag
Eric
Dept of Biology
Univ Maryland
Bldg #144

College Park
MD
20742

ehaag@umd.edu
960535
Haas
Leonard
Genetics
Rutgers, The State University NJ
145 Bevier Road
Piscataway
NJ
8854

lenhaas@eden.rutgers.edu
961505
Hacker
Mallory
Cell & Dev Biol
Vanderbilt Univ
465 21st Ave.
Nashville
TN
37232

mallory.l.hacker@vanderbilt.edu
961395
Hacopian
Gizelle
Biological Sciences
Cal Poly Pomona
1109 W Francis St. unit C
Ontario
CA
91762

ghacopian1@gmail.com
961421
Hagstrom
Kirsten
Program Molec Med
Univ Massachusetts Med Sch
377 Plantation St
Worcester
MA
1605

kirsten.hagstrom@umassmed.edu
961438
Hailemariam
Tiruneh

New York Blood Center
310 E 67th St

New York
NY
10065

thailemariam@nybloodcenter.org
960369
Hall
David
Ctr C Elegans Anatomy
Albert Einstein Col Med
1410 Pelham Pkwy,Dept Neurosci
KC 601
Bronx
NY
10461

hall@aecom.yu.edu
961373
Hall
Erica
Zoology
University of Wisconsin
1117 W. Johnson St.
Madison
WI
53706

eurekamarie@gmail.com
960237
Hall
Julie
Laboratory of Molecular Toxicology
National Institute of Environmental Health Science
111 TW Alexander Dr
Research Triangle Park
NC
27709

hallj2@niehs.nih.gov
960061
Hall
Sarah
Dept Biol
Brandeis Univ
415 South St

Waltham
MA
2454

sehall@brandeis.edu
960506
Hallem
Elissa
Div Biol 156-29
California Inst Technology
1200 E California Blvd
156-29
Pasadena
CA
91125

ehallem@caltech.edu
960228
Hamill
Danielle
Dept Zoology
Ohio Wesleyan Univ
61 S Sandusky
Delaware
OH
43015

drhamill@owu.edu
961462
Hamilton
Scott
Center for Neuroscience
University of California, Davis
1544 Newton Court
Davis
CA
95618

oshamilton@ucdavis.edu
960785
Hammarlund
Marc
CNNR/Genetics
Yale University
BCMM 436E, 295 Congress Ave.
New Haven
CT
6510

marc.hammarlund@yale.edu
961329
Han
Lu
Physiology/Biophysics
University of Miami
1600 NW 10 Avenue
Room 5130
Miami
FL
33136

lhan@med.miami.edu
960649
Han
Suhao
Div Biol
Kansas State Univ

Manhattan
KS
66506

hanmouse@ksu.edu
961127
Han
Sungmin
Dept Biol
Univ Alabama, Birmingham
1900 University Blvd, THT958
Birmingham
AL
35294

han@uab.edu
960485
Han
Ting
Life Sci Inst, Kim Lab, 6183
Univ Michigan
210 Washtenaw Ave
Ann Arbor
MI
48109-2216

tinghan@umich.edu
960519
Hanna-Rose
Wendy
Dept Biochem & Molec Biol
Pennsylvania State Univ
104D Life Sci Bldg
University Park
PA
16802

wxh21@psu.edu
960845
Hansen
Malene
Development & Aging
Burnham Institiute Med Res
10901 North Torrey Pines Rd
La Jolla
CA
92037

mhansen@burnham.org
961338
Hanson
Mariah

Central Michigan University
1240 E. Broomfield #NN-4
Mt. Pleasant
MI
48858

hanso1ml@cmich.edu
960328
Hao
Yan
Mak Lab
Stowers Inst
1000 E 50th St
Kansas City
MO
64110

yah@stowers.org
960457
Hapiak
Vera
Dept of Biological Sciences
Univ Toledo
2801 W Bancroft St
Toledo
OH
43606

hapiakv@yahoo.com
960779
Harkar
Rutwik

Haverford College
Lancaster Avenue
Haverford
PA
19041

pmeneely@haverford.edu
960642
Harrington
Adam
Dept Biol
Univ Alabama
411 Hackberry Lane
Tuscaloosa
AL
35487

ajharrington@bama.ua.edu
961094
Harris
David
Dept Biol
MIT
77 Massachusetts Ave
Cambridge
MA
2139

dtharris@mit.edu
960458
Harris
Gareth
Dept Biological Sciences
University of Toledo
2801 W Bancroft St
Toledo
OH
43606

gazalad2@hotmail.com
960305
Hart
Anne
Ctr Cancer Res
Massachusetts Gen Hosp
149-7202 13th St
Charlestown
MA
2129

hart@helix.mgh.harvard.edu
961024
Hartin
Samantha
Molecular Biosciences
University of Kansas
1200 Sunnyside Ave.
Lawrence
KS
66046

shartin@ku.edu
961221
Hashmi
Sarwar
Dev Biol Lab
New York Blood Ctr
310 E 67th St

New York
NY
10065

shashmi@nybloodcenter.org
960526
Haspel
Gal
NINDS
NIH
35 Convent Dr
Bethesda
MD
21892

haspelg@ninds.nih.gov
961272
He
Bin
Dept Biochem & Molec Biol
Baylor Col Medicine
One Baylor Plaza
Houston
TX
77030

bh147985@bcm.tmc.edu
961568
Head
Brian
Dept Biological Chemistry
Univ California, Los Angeles
615 Charles E Young Drive S
Los Angeles
CA
90095-1737

bhead@mednet.ucla.edu
960879
Heatherly
Jessica
Dept Neuroscience
OUHSC
1100 N. Lindsay
Oklahoma City
OK
73112

jessica-heatherly@ouhsc.edu
960757
Heestand
Bree
Huffington Ctr on Aging
Baylor College Med
One Baylor Plaza
Houston
TX
77030

bheestand@bcm.tmc.edu
961376
Heighington
Cassandra


2165 S Milledge Ave B7
Athens
GA
30605

cassington2@hotmail.com
960711
Heiman
Maxwell

Rockefeller Univ
1230 York Ave, Box 46
New York
NY
10065

heiman@rockefeller.edu
961522
Hellman
Andrew
Dept Biological Sci
Stanford Univ
385 Serra Mall
Stanford
CA
94305

abhellman@hotmail.com
961342
Hendricks
Michael

Harvard University
52 Oxford St, Rm 254
Cambridge
MA
2138

s.michael.hendricks@gmail.com
960643
Herman
Michael
Div Biol
Kansas State Univ
266 Chalmers Hall
Manhattan
KS
66506-4901

mherman@ksu.edu
961266
Hermann
Greg
Dept Biol
Lewis & Clark College
0615 SW Palatine Hill Rd
Portland
OR
97219

hermann@lclark.edu
960826
Herndon
Laura
Ctr C elegans Anatomy
AECOM
1410 Pelham Parkway, Room 612
Bronx
NY
10461

lherndon@aecom.yu.edu
960900
Herrera
Ramon
Biology
New York University
100 Washington Square E
New York
NY
10003

rantonio.herrera@gmail.com
961246
Hildebrand
Karanda
Molec Biosci
Univ Kansas
231 West Essie St
Bern
KS
66408

karanda@ku.edu
960174
Hinas
Andrea
Molecular and Cellular Biology
Harvard Univ
16 Divinity Ave, BL3050
Cambridge
MA
2138

hinas@mcb.harvard.edu
960832
Hirose
Takashi
Department of Biology
MIT
77 Massachusetts Avenue
Room 68-441
Cambridge
MA
2139

thirose@MIT.EDU
960340
Hobert
Oliver
Dept Biochem
Columbia Univ
701 W 168th St
New York
NY
10032

or38@columbia.edu
961178
Hobson
Robert
Dept Biol, HHMI
Univ Utah
257 South 1400 East
Salt Lake City
UT
84112-0840

hobson@biology.utah.edu
960769
Hom
Sabrina
Dept Molec Biol
Massachusetts Gen Hosp
185 Cambridge St
Boston
MA
2114

sabrina.hom@molbio.mgh.harvard.edu
960021
Hong
Ray
Dept Biol
California State Univ
18111 Nordhoff St
Northridge
CA
91330-8303

ray.hong@csun.edu
960215
Hoppe
Pamela
Dept Biological Sci, Wood Hall
Western Michigan Univ
1903 W Michigan Ave
Kalamazoo
MI
490085410

pamela.hoppe@wmich.edu
961060
Howell
Kelly
Dept Genetics
Univ Pennsylvania
415Curie Blvd,445 Clin Res Bld
Philadelphia
PA
19104

kehowell@mail.med.upenn.edu
960474
Hresko
Michelle

Divergence, Inc.
893 N Warson Rd
St Louis
MO
63141

hresko@divergence.com
961435
Hsu
Ao-Lin
Internal Med, Geriatric Med
University of Michigan
109 Zina Pitcher, BSRB 2027
Ann Arbor
MI
48109-2200

aolinhsu@umich.edu
960274
Hu
Jinghua
Department of Medicine
Mayo Clinic
200 First St.

Rochester
MN
55905

jhu@pharmacy.wisc.edu
960718
Hu
Patrick
Life Sci Inst
Univ Michigan
210 Washtenaw Ave
Ann Arbor
MI
48109

pathu@umich.edu
960590
Hu
Shuang
Department of Biological Sciences
University of Toledo
2801 W. Bancroft
Toledo
OH
43606-3390

shuang.hu@utoledo.edu
960671
Hu
Yan
Div Biological Sci
Univ California, San Diego
9500 Gilman Dr
San Diego
CA
92093-0322

yahu@ucsd.edu
960289
Hu
zhitao

Massachusetts General Hosp
Boston
MA
2114

huz@molbio.mgh.harvard.edu
961183
Huang
Nancy
Biology Department
Colorado College
14 E Cache La Poudre St
Colorado Springs
CO
80903

nancy.huang@coloradocollege.edu
961354
Huarcaya Najarro
Elvis
Molec Biosci
Univ Kansas
1200 Sunnyside Ave
Lawrence
KS
66044

bioelvis@ku.edu
961275
Huber
Paul

UIC
1213 Chesham Ct
Woodridge
IL
60517

phuber2@uic.edu
960911
Hubert
Thomas

UCSD
Gilman Drive

La Jolla
CA
92093-0368

thubert@ucsd.edu
961498
hubstenberger
arnaud
CDB
UCHSC
12801 E. 17H AVE
Denver
CO
80045

ahubsten@yahoo.fr
961186
Hudson
Martin
Molec Biosci
Univ Kansas
1200 Sunnyside Ave
Lawrence
KS
66045

mlhudson@ku.edu
961064
Hulme
Elizabeth
Chemistry and Chemical Biology
Harvard University
12 Oxford Street
Cambridge
MA
2138

ehulme@gmwgroup.harvard.edu
960421
Hunt
Piper
Lab Neurosciences
National Inst on Aging
251 Bayview Blvd.
Baltimore
MD
21224

huntpr@mail.nih.gov
960737
Hunter
Craig
Dept Molecular & Cellular Biol
Harvard Univ
16 Divinity Ave
Cambridge
MA
02138-2020

hunter@mcb.harvard.edu
961468
Hunter
Jerrod
Dept GMD
OMRF
825 13th St

Oklahoma City
OK
73104

oumagicman@yahoo.de
960397
Hurd
Daryl
Dept Biol
St John Fisher Col
3690 East Ave
Rochester
NY
14618

dhurd@sjfc.edu
961343
Ibourk
Mouna
Biology
Northeastern University
360 Huntington Ave
Boston
MA
2115

ibourk645@yahoo.com
961247
Ihuegbu
Nnamdi
Genetics
Washington University
4444 FOREST PARK AVE, BOX 8510
SAINT LOUIS
MO
63108

nihuegbu@wustl.edu
961156
Inman
Annie
Biology
MIT
31 Ames St
Bldg, 68, Room 440D
Cambridge
MA
2139

ainman@mit.edu
960216
Irazoqui
Javier
Dept Molecular Biol
Massachusetts General Hosp
185 Cambridge St, CPZN 7250
Boston
MA
2114

javier@molbio.mgh.harvard.edu
961233
Ishidate
Takao
Program in Molec Med
Univ Massachusetts
373 Plantation St, Biotech2
Worcester
MA
1605

takao.ishidate@umassmed.edu
961449
Iwasa
Hiroaki
Dept Molec Biol & Biochemistry
Rutgers Univ
604 Allison Rd,Nelson Lab,A220
Piscataway
NJ
8854

iwasa@biology.rutgers.edu
961254
Izquierdo
Eduardo
Inst Neuroscience
University of Oregon
1254 University of Oregon
Eugene
OR
97403

eduardo@uoregon.edu
960797
Jackson
Belinda
Dept Biological Sci
Univ Maryland, Baltimore Cnty
1000 Hilltop Circle
Baltimore
MD
21250

bjacks1@umbc.edu
960209
James
Tracy
Biological Sciences
Virginia Tech University
1981 Kraft Drive, ILSB 2021
Blacksburg
VA
24061

tjames84@vt.edu
961162
Jarrell
Travis
Molec Gen
Albert Einstein College Med
1300 Morris Park Ave
Bronx
NY
10461

tjarrell@aecom.yu.edu
960532
Jauregui
Andrew
Genetics
Rutgers, The State Univ of NJ
145 Bevier Road
Piscataway
NJ
8854

jauregui@dls.rutgers.edu
960927
Jeong
Pan-Young
NRI
UCLA, Santa Barbara
Bldg 571, rm 6129
Santa Barbara
CA
93106

pyjeong@lifesci.ucsb.edu
960795
Jia
Kailiang
Dept Internal Med
Univ Texas SW Med Ctr
5323 Harry Hines Blvd
Dallas
TX
75390-9113

kailiang.jia@utsouthwestern.edu
960518
Jodlowski
Tomasz
Dept Pathology
Montefiore Medical Ctr
1635 poplar street
Bronx
NY
10461

tomaszjod@gmail.com
960756
Johnson
David
Dept Biochemistry
Univ Rochester
575 Elmwood Ave
Rochester
NY
14642

david_johnson@urmc.rochester.edu
961439
Jones
Brian
Med, Nephrology Unit
Univ Rochester Sch Med
601 Elmwood Ave
Rochester
NY
14642

brian_e_jones@urmc.rochester.edu
961093
Jones
Tamako
Radiobiology Program
Loma Linda Univ
11175 Campus St
Loma Linda
CA
92354

tjones@dominion.llumc.edu
960101
Jose
Antony
Dept Molec & Cell Biol
Harvard Univ
16 Divinity Ave
Cambridge
MA
2138

amjose@mcb.harvard.edu
960926
Joshi
Pradeep
Neurosci Res Inst/MCDB
Univ California
Bldg 571, rm 6129
Santa Barbara
CA
93106

joshi@lifesci.ucsb.edu
961553
Juang
Bi-Tzen
Center for Neuroscience
University of California,Davis
1544 Newton Court
Davis
CA
95618

bjuang@ucdavis.edu
960907
Jung
Yuchae

University at Albany
1400 Washington Ave
Albany
NY
12222

yj873452@albany.edu
961182
Kalb
John
Biology Department
Canisius College
2001 Main St

Buffalo
NY
14208

kalbj@canisius.edu
960626
Kalis
Andrea
Dept Gen, Cell Biol, Dev
Univ Minnesota
321 Church St SE
Minneapolis
MN
55455

horn0135@umn.edu
960016
Kalueff
Allan
Pharmacology
Tulane University
1430 Tulane Avenue
New Orleans
LA
70122

avkalueff@gmail.com
961452
Kamat
Shaunak
Molecular Biol & Biochem
Rutgers Univ
604 Allison Road
Piscataway
NJ
8854

kamata@eden.rutgers.edu
960183
Kang
Chanhee
Department of Molecular Biology
UT Southwestern Medical Center
6000 Harry Hines Blvd. NA5.300A
Dallas
TX
75390

chanhee.kang@utsouthwestern.edu
960608
Kang
Lijun


2013 medford Rd, H 163
Ann Arbor
MI
48104

lijun_kang@hotmail.com
960945
Kao
Aimee
Dept Neurology
Univ San Francisco
350 Parnassus, Ste 905
San Francisco
CA
94143-1207

akao@memory.ucsf.edu
960819
Kao
Cheng-Yuan
Section Cell & Dev Biol
Univ California, San Diego
9500 Gilman Dr, MC 0322
La Jolla
CA
92093

c2kao@ucsd.edu
960645
Kapahi
Pankaj
Dept Biol
Buck Inst
8001 Redwood Blvd
Novato
CA
94945

pkapahi@buckinstitute.org
960175
Kaplan
Fatma

USDA-ARS CMAVE
1700/1600 S.W. 23rd Drive
Gainesville
FL
32608

fatma.kaplan@ars.usda.gov
961486
Karimzadegan
Siavash

Columbia university
1212 Amsterdam Ave
NY
NY
10027

sk2188@columbia.edu
960054
Karpel
Jonathan
Joint Sci Dept
Claremont Colleges
925 N Mills Ave/Keck Sci Ctr
Claremont
CA
91711

jkarpel@jsd.claremont.edu
960973
Kasad
Roshni

Univ California, Berkeley
460 Stanley Hall MC 3220
Berkeley
CA
94720-3220

roshnik@berkeley.edu
961332
Kashyap
Luv
Med, Divison Geriatric Med
Univ Pittsburgh
3471 Fifth Avenue
Suite 500
Pittsburgh
PA
15213

vfa2@pitt.edu
960909
Kato
Masaomi
Dept MCD Biol
Yale Univ
266 Whitney Ave
New Haven
CT
6520

masaomi.kato@yale.edu
960499
Kato
Mihoko
Div Biol
California Inst Technology
1200 E California Blvd
156-29
Pasadena
CA
91125

mkato@caltech.edu
961570
Kato
Saul
Neurobiology
Columbia University
104 Wooster St 2N
New York
NY
10012

ssk2133@columbia.edu
960158
Katz
Menachem
Lab Developmental Genetics
Rockefeller Univ
1230 York Ave
New York
NY
10065

mkatz@rockefeller.edu
960256
Kauffman
Amanda
Molecular Biology
Princeton University

Princeton
NJ
8544

alpeters@princeton.edu
960835
Kaur
Taniya

NYU
100 Washington Square Park E
New York
NY
10009

tk966@nyu.edu
961404
Kawli
Trupti
Dept Genetics
Stanford Univ
300 Pasteur Dr, Rm M309
Stanford
CA
94305

trupti@stanford.edu
961374
Kelleher
Alan
Biology
UC, San Diego
9500 Gilman Dr
3022
San Diego
CA
92102

akelleher@ucsd.edu
960685
Kennedy
Lisa
Genetics and Development
Columbia University
701 West 168th Street
New York
NY
10032

lmk2146@columbia.edu
960935
Kenyon
Cynthia
Biochem/Biophy/Genentech Hl
Univ California, San Francisco
600 16th St, Rm S312D
San Francisco
CA
94143-2200

ckenyon@biochem.ucsf.edu
961379
Keowkase
Roongpetch
Pharmaceutical Sci
Univ Maryland Baltimore
20 N Pine St

Baltimore
MD
21201

rkeow001@umaryland.edu
961558
Kerr
Rex

Janelia Farm Research Campus
19700 Helix Dr
Asburn
VA
20147

kerrr@janelia.hhmi.org
960364
Kerscher
Aurora
Dept Micro & Molec Cell Bio
Eastern Virginia Medical School
700 West Olney Road, LH 3047
Norfolk
VA
23507

kerschae@evms.edu
960331
Kersey
Rossio
Molecular Biology
NIDDK/NIH
5 Center Dr, Bldg 5/B104
Bethesda
MD
20892

kerseyr@niddk.nih.gov
960586
Khan
Sana
Biology
Queens College
65-30 Kissena Blvd
Flushing
NY
11367

skhan119@qc.cuny.edu
960068
Khare
Shilpi
Dept Biochemistry & Molec Biol
Univ California, Los Angeles
607 Charles E Young Dr, E
Los Angeles
CA
90025

shilpik@ucla.edu
960484
Khivansara
Vishal
Dept Human Gen
Life Sci Inst
210 Washtenaw ave
Ann Arbor
MI
48109

kvishal@umich.edu
961482
Kiedrowski
Michael
Biology
Hofstra University
144 Butler St.
Westbury
NY
11590

mkiedr1@pride.hofstra.edu
961120
Kim
Dennis
Dept Biol
MIT
77 Massachusetts Ave
68-430-A
Cambridge
MA
2139

dhkim@mit.edu
960811
Kim
Grace
Neuroscience
Albert Einstein Col Med
1410 Pelham Pkwy
Bronx
NY
10461

gsykim@mit.edu
960593
Kim
Hongkyun
Cell Biology & Anatomy
Rosalind Franklin University
3333 Green Bay Road
North Chicago
IL
60064

hongkyun.kim@rosalindfranklin.edu
960633
Kim
Hyun-Min
Dept. of Genetics
Harvard Medical School
77 Ave. Louis Pasteur NRB 334
Boston
MA
2115

hkim@genetics.med.harvard.edu
960483
Kim
John
Human Genetics
Life Sciences Institute
210 washtenaw ave
Ann Arbor
MI
48109

jnkim@umich.edu
960127
Kim
Kyuhyung
Deptartment Biology
Brandeis University
415 South St

Waltham
MA
2454

khkim@brandeis.edu
960399
Kim
Rinho
Biology
Brandeis University
415 South St

Waltham
MA
2454

rkim08@brandeis.edu
960195
Kim
Seongseop
GCD
University of Minnesota
420 Washington Ave SE
Minneapolis
MN
55455

kimx1285@umn.edu
960901
Kim
Sunhong
Dept MCD Biol
Univ Colorado
UCB347

Boulder
CO
80302

sunhong@colorado.edu
960583
Kim
Yongsoon
Cancer Genomics
Nevada Cancer Inst
One Breakthrough Way
Las Vegas
NV
89135

ykim@nvcancer.org
961326
Kimura
Rob

Leica Microsystems
2345 Waukegan Road
Bannockburn
IL
60015

info@leica-microsystems.com
961192
Kinchen
Jason
Carter Immunology Ctr
Univ of Virginia
409 Lane Rd, MR-4, Rm 4062
Charlottsville
VA
22908

jmk8q@virginia.edu
961436
King Porter
Chelle
Biology
Truman State University
100 E. Normal
Kirksville
MO
63501

mdk908@truman.edu
960839
Kintzele
Jason
biological sciences
Western Michigan University
718 locust #4
kalamazoo
MI
49007

jason.a.kintzele@wmich.edu
961019
Kiontke
Karin
Biology
New York University
100 Washington Square E.
New York
NY
10003

kk52@nyu.edu
961041
Kipreos
Edward
Dept Cellular Biology
Univ Georgia
724 Biological Sci Bldg
Athens
GA
30602-2607

ekipreos@cb.uga.edu
960178
Kirienko
Natalia
Dept Molecular Biol
Univ Wyoming
Gibbon and 16
Laramie
WY
82072

kirienko@uwyo.edu
960496
Kishore
Ranjana
Dept Biol
California Inst Technology
1200 E California Blvd
156-29
Pasadena
CA
91125

ranjana@its.caltech.edu
960371
Klang
Ida

Buck Institute for Age Research
Redwood Blvd
Novato
CA
94945

iklang@buckinstitute.org
960370
Kleeman
Gunnar
Lewis Sigler Institute
Princeton University
Washington Road
160 Carl Icahn Lab
Bronx
NY
10461

kleeman@princeton.edu
961028
Klerkx
Elke
Cell and Developmental Biology
University of Michigan
109 Zina Pitcher Place
Ann Arbor
MI
48109

eklerkx@umich.edu
960965
Kleshayeva
Anna

Univ Louisiana at Monroe

Monroe
LA
71209

kleshaa@tribe.ulm.edu
961149
Klosterman
Susan
Biology
University of Illinois Chicago
840 W Taylor

Chicago
IL
60607

sklost2@uic.edu
961384
Knezevich
Phil
Biological Sciences
San Jose State University
1 Washington Square / DH-444
San Jose
CA
95192

Vonkonigsberg@yahoo.com
961528
Knight
Adam
Biological Sciences
The University of Alabama
301 Helen Keller Blvd Apt 306B
Tuscaloosa
AL
35404

alknight@crimson.ua.edu
960098
Knoefler
Daniela
MCDB
University of Michigan
830 N. University
Ann Arbor
MI
48109

knoefler@umich.edu
961292
Kocabas
Askin
Systems Biology
Harvard University
52 Oxford Street
Northwest Building Room 358.40
Cambridge
MA
2138

akocabas@cgr.harvard.edu
961365
Kolokotrones
Tom
Dept Systems Biol
Harvard Medical Sch
200 Longwood, Alpert 513C
Boston
MA
2115

thomas_kolokotrones@student.hms.harvard.edu
960456
Komuniecki
Richard
Biological Sciences
University of  Toledo
2801 W Bancroft
601
Toledo
OH
43606

rkomuni@uoft02.utoledo.edu
960796
Koo
Pamela
Dept Biol
Texas A & M
BSBW Bldg,  TAMU
3258
College Station
TX
77843

pkoo@mail.bio.tamu.edu
960766
Kornfeld
Kerry
Dev Biol
Washington Univ Med Sch
11 Sumac Lane
Ladue
MO
63124-1720

kornfeld@wustl.edu
960210
Korta
Dorota
Pathology
NYU School of Medicine
540 First Avenue, SKI 4th Floor Lab 7
New York
NY
10016

dk1197@nyumc.org
960971
Kotiwaliwale
Chitra

UC Berkeley
460 Stanley Hall MC 3220
Berkeley
CA
94720-3220

chitra.kot@gmail.com
961199
Kovacevic
Ismar
Dept Biol
Northeastern Univ
360 Huntington Ave
Boston
MA
2115

ismar.k@neu.edu
960799
Kowalski
Jennifer
Dept Physiology
Tufts Ch Medicine
150 Harrison Ave
Boston
MA
2111

jennifer.kowalski@tufts.edu
961237
Krajacic
Predrag
Physiology
University of Pennsylvania
3700 Hamilton Walk
Philadelphia
PA
19104

predrag@mail.med.upenn.edu
961488
Kratz
John

Columbia university
1212 Amsterdam Ave
NY
NY
10027

jek2006@columbia.edu
960719
Kroetz
Mary
Genetics, Cell Biology & Dev
University of Minnesota
321 Church St. SE
6-160 Jackson Hall
Minneapolis
MN
55455

kroet006@umn.edu
960722
Kruesi
William
Molec & Cell Biol
UC - Berkeley
1 Barker Hall

Berkeley
CA
94720

kruesiw@berkeley.edu
961089
Kudlow
Brian
MCD Biology
University of Colorado
Dept of MCD Biology
UCB 347
Boulder
CO
80309

brian.kudlow@colorado.edu
961285
Kuhn
Jeffrey
Biological Science
Virginia Tech
1981 Kraft Dr
913
Blacksburg
VA
24061

jrkuhn@vt.edu
960930
Kumar
Ashish
Molec Cellular & Dev Biol
Univ California, Santa Barbara
Bldg 571, rm 6129
Santa Barbara
CA
93106

kumar@lifesci.ucsb.edu
960498
Kuntz
Steven
Div Biol
California Inst Tech
1200 E California Blvd
Pasadena
CA
91125

kuntz@caltech.edu
960652
Kurumathurmadam Mony
Vinod
Div Biol
Kansas State Univ
116 Ackert Hall
Manhattan
KS
66506

vinodkm@ksu.edu
961366
Labiento
Robert


107 Cedar Point Drive
West Islip
NY
11795

rlabie1@pride.hofstra.edu
960383
Ladage
Mary


3314 Clydesdale Dr
Denton
TX
76210

mary.ladage@gmail.com
960146
Lam
Ngan
Department of Biochemistry
Univ of Wisconsin-Madison
433 Babcock Drive
Madison
WI
53706-1544

nganlam@wisc.edu
961484
Lamitina
Todd
Dept Physiology
Univ Pennsylvania
3700 Hamilton Walk, Rm A700
Philadelphia
PA
19104

lamitina@mail.med.upenn.edu
961396
Lamunyon
Craig
Dept Biological Sci
California State Polytech Univ
3801 W Temple Ave
Pomona
CA
91768

cwlamunyon@csupomona.edu
961402
Land
Marianne
Dept of Life Sciences
New York Institute of Tech
Northern Blvd.
PO Box 8000
Westbury
NY
11568

land@aecom.yu.edu
960206
Lange
Stephanie
BMB
Penn State University
103 Life Science Bldg
University Park
PA
16802

sel209@psu.edu
960846
Lapierre
Louis
Development & Aging
Burnham Institiute Med Res
10901 North Torrey Pines Rd
La Jolla
CA
92037

lapierre@burnham.org
961172
Larson
Renee
Biology
Canisius College
2001 Main Street
Buffalo
NY
14208

larsonr@canisius.edu
960382
LaRue
Bobby

Univ North Texas
617 Juno Lane
Denton
TX
76209

bobby.larue@gmail.com
960625
Layne
Robert
Department of Biology
University of Toledo
2801 W. Bancroft Street
MS-601
Toledo
OH
43606

robert.layne@utoledo.edu
960710
LeBlanc
Michelle

NYU
888 Main st, Apt 231
New York
NY
10044-0215

michelle.g.leblanc@gmail.com
960536
LeBoeuf
Brigitte
Dept Biol
Texas A&M Univ

College Station
TX
77843

bleboeuf@mail.bio.tamu.edu
960402
Lee
Brian
Dept Physiology
Univ California, San Francisco
600 16th St,Genentech Hl, N416
San Francisco
CA
94107

brianlee@alum.mit.edu
961227
Lee
KyungHwa
CNDD
Univ Rochester
601 Elmwood Ave, Box 645
Rochester
NY
14642

kyunghwa.lee@gmail.com
960871
Lee
Min-Ho
Dept Biological Sciences
Univ Albany, SUNY
1400 Washington Ave, Bio126
Albany
NY
12222

mhlee@albany.edu
960565
Lee
Myeongwoo
Dept Biol
Baylor Univ
One Bear Plaza, 97388
Waco
TX
76798

myeongwoo_lee@baylor.edu
960427
Lee
Myon-Hee
Dept Biochemistry
Univ Wisconsin, Madison
433 Babcock Dr
Madison
WI
53706-1544

myonheelee@wisc.edu
960509
Lee
Raymond
Div Biol
California Inst Technology
1200 E California Blvd
156-29
Pasadena
CA
91125

raymond@caltech.edu
960572
Lee
Siu
Dept Molec Biol & Gen
Cornell Univ
Tower Rd

Ithaca
NY
14850

ssl29@cornell.edu
960725
Lee
Teresa
Molecular Cell Biology
UC Berkeley
16 Barker Hall
Berkeley
CA
94720

teresalee@berkeley.edu
960333
Lei
Haiyan
LMB
NIH/NIDDK
9000 Rockville Pike
Bethesda
MD
20892

leihaiyan@niddk.nih.gov
960854
Leifer
Andrew
Biophysics
Harvard
72 Dimick St Apartment #2
Somerville
MA
2143

leifer@fas.harvard.edu
960126
Leopold
Luciana

UNC- Chapel Hill
216 Fordham Hall
Chapel HIll
NC
27599

lleopold@med.unc.edu
960201
Leung
Maxwell
Nicholas School of the Environment
Duke University
Rm A304, LSRC Bldg, Research Dr
Durham
NC
27705

maxwell.leung@duke.edu
961270
Levitte
Steven

Lewis & Clark College

Portland
OR
97219

slevitte@lclark.edu
960313
Lewellyn
Lindsay
Cellular & Molec Med
Univ California, San Diego
3071J CMME, 9500 Gilman Dr
La Jolla
CA
92037

llewellyn@ucsd.edu
961472
Li
Chris
Dept Biol
City Col New York
Convent Ave at 138th St
New York
NY
10031

cli@sci.ccny.cuny.edu
961034
Li
Haimin

university of colorado  boulder
1910 Athens St, Apt A
Boulder
CO
80302

Haimin.Li@colorado.edu
960650
Li
Ji
Dept Biological Sci
Columbia Univ

New York
NY
10027

jl2493@columbia.edu
960347
Li
Wei
Life Sci Inst
Univ Michigan
210 Washtenaw Ave
Ann Arbor
MI
48109

weilee@lsi.umich.edu
961523
Li
Weiqing
Dept Biological Structure
Univ Washington
1959 NE Pacific St
Seattle
WA
98195

weiqing@u.washington.edu
960475
Li
Xiangqian

Divergence, Inc.
893 North Warson Road
Saint Louis
MO
63141

li@divergence.com
960523
Li
Xuan
development and stem cell
joslin diabetes center
one joslin place
boston
MA
2215

xuan.li@joslin.harvard.edu
960144
Li
Yujie
Nephrology and Hypertension
Mayo Clinic
200 First Street SW
Rochester
MN
55905

li.yujie@mayo.edu
960349
Liachko
Nicole
GRECC
VA Puget Sound
1660 S. Columbian Way
S182
Seattle
WA
98108

nliachko@u.washington.edu
960668
Libuda
Diana
Dev Biol
Stanford Univ
279 Campus Dr
Stanford
CA
94305

dlibuda@stanford.edu
960989
Link
Chris
Inst Behavioral Genetics
Univ Colorado
Campus Box 447
Boulder
CO
80309

linkc@colorado.edu
960687
Lints
Robyn
Dept Biol
Texas A & M Univ
BSBW Bldg, 3258 TAMU
3258
College Station
TX
77843-3258

rlints@mail.bio.tamu.edu
961571
Lissemore
James
Dept Biol
John Carroll Univ
20700 N Park Blvd
Univ Heights
OH
44118

jlissemore@jcu.edu
961565
Lithgow
Gordon

Buck Inst
8001 Redwood Blvd
Novato
CA
94945

glithgow@buckinstitute.org
960384
Little
Brent


1429 Eagle Dr, Apt 109
Denton
TX
76201

brentlittle@mac.com
960478
Liu
Gang

Waksman Inst

Piscataway
NJ
8854

evaeva8099@gmail.com
960342
Liu
Haibo
Dept MCD Biol
Univ Colorado, Boulder
1350 20th St

Boulder
CO
80302

liuhb_raoyl@yahoo.com
960609
Liu
Jie
Life Sci Inst
Univ Michigan
2287 hemlock ct
Ann Arbor
MI
48109

jerryliu@umich.edu
960810
Liu
Jun
Dept Molec Biol & Gen
Cornell Univ
439/441 Biotech Bldg
Ithaca
NY
14853-2703

jl53@cornell.edu
961507
Liu
Oliver
Biology
Stanford University
1602A Treat Avenue
San Francisco
CA
94110

oliu@stanford.edu
960409
Liu
Ping
Department of Neuroscience
The Univ of CT Health Center
263 Farmington Avenue
Farmington
CT
6030

Liu@uchc.edu
960765
Liu
Qinwen
Department of Biology
University of Maryland
Route 1

College Park
MD
20742

qinwen@umd.edu
960425
Liu
Wan-Ju
Biological Sci
UMBC
1000 Hilltop Circle
Baltimore
MD
21250

wanju1@umbc.edu
960015
Liu
Xiao
Dept Developmental Biol
Stanford Univ
279 Campus Dr, B341
Stanford
CA
94305

xiaoliu2@stanford.edu
960579
Liu
Yishi
Dept Biol
Texas A&M Univ
3258 TAMU

College Station
TX
77840

yliu@mail.bio.tamu.edu
961448
Lizzio
Michael
Dept Molec Biol & Biochem
Rutgers Univ
604 Allison Rd,NelsonLabs,A220
Piscataway
NJ
8854

lizzio@biology.rutgers.edu
960727
Lo
Te-Wen
Dept MCB-Gen
UC Berkeley/HHMI
1 Barker Hall

Berkeley
CA
94720

te-wen.lo@berkeley.edu
960716
Locke
Cody
Physiology
Univ California San Francisco
1550 4th St, Box 2610
San Francisco
CA
94131

cody.locke@ucsf.edu
961378
Lockery
Shawn
Inst Neuroscience
Univ Oregon
1254 University of Oregon
Eugene
OR
97403-1254

shawn@uoregon.edu
960023
Loer
Curtis
Dept Biol
Univ San Diego
5998 Alcala Park
San Diego
CA
92110

cloer@sandiego.edu
960172
Logie
Anne
Laboratory of Neurosciences
National Institute on Aging
251 Bayview Boulevard
Baltimore
MD
21224

logieac@nia.nih.gov
961323
Long
Olivia

University of Pittsburgh
1132 North Negley Ave Apt 2
Pittsburgh
PA
15206

osl1@pitt.edu
960657
Los
Ferdinand
Dept Cell & Dev Biol
UC San Diego
9500 Gilman Dr
La Jolla
CA
92093

flos@ucsd.edu
961492
Lu
Hang
Chemical & Biomolec Eng
Georgia Inst Tech
311 Ferst Dr, NW
Atlanta
GA
30332-0100

hang.lu@chbe.gatech.edu
961555
Lucanic
Mark

Buck Inst
8001 Redwood Blvd
Novato
CA
94945

mlucanic@buckinstitute.org
960828
Ludewig
Andreas
Boyce Thompson Inst
Cornell Univ
1, Tower Rd

Ithaca
NY
14850

hal44@cornell.edu
960850
Lund
Jim
Dept Biol
Univ Kentucky
101 Morgan

Lexington
KY
40506

jiml@uky.edu
961133
Lundquist
Erik
Dept. of Molecular Biosciences
University of Kansas
1200 Sunnyside Ave
2045 haworth Hall
Lawrence
KS
66045

erikl@ku.edu
960257
Luo
Shijing
Dept Molecular Biol
Princeton Univ
Washington Rd
Princeton
NJ
8544

sluo@princeton.edu
960089
Lyczak
Rebecca
Biol Dept
Ursinus Col
Main St

Collegeville
PA
19426

rlyczak@ursinus.edu
961371
Lynch
Allison
Genetics
University of Wisconsin-Madison
1117 W Johnson St
Madison
WI
53706

amlynch2@wisc.edu
960080
Maduro
Morris
Dept Biol
Univ California, Riverside
3380 Spieth Hall
Riverside
CA
92508

maduro@citrus.ucr.edu
961535
Maduzia
Lisa
Parasitology
New England Biolabs
240 County Road
Ipswich
MA
1938

maduzia@neb.com
960414
Maeder
Celine
Biological Sciences
Stanford University
371 Serra Mall
Stanford
CA
94303

cmaeder@stanford.edu
960758
Magner
Daniel
Dept Molec & Cellular Biol
Baylor Col Medicine
One Baylor Plaza
Houston
TX
77030

dm692226@bcm.tmc.edu
960533
Maguire
Julie
Dept Gen
Rutgers, The State Univ NJ
145 Bevier Rd
Piscataway
NJ
8854

julimagu@eden.rutgers.edu
961080
Maher
Kathryn
Biochem & Molec Biol
Univ Massachusetts
710 N. Pleasant St.
Amherst
MA
1002

kmaher@mcb.umass.edu
960861
Mailler
Roger
Computer Science
University of Tulsa
800 S. Tucker Drive
Tulsa
OK
74104

mailler@utulsa.edu
961079
Maine
Eleanor
Dept Biol
Syracuse Univ
107 College Pl, Life Sci Comp
Syracuse
NY
13244-1270

emmaine@syr.edu
960801
Mair
Will
MCBL
Salk Institute
10010 N Torrey Pines Rd
La Jolla
CA
92109

mair@salk.edu
960325
Mak
HoYi
Mak Lab
Stowers Inst
1000 E 50th St
Kansas City
MO
64110

hym@stowers-institute.org
961387
Malik
Rabia
Chemistry and Chemical Biology
Boyce Thompson Institute
Tower Road

Ithaca
NY
14853

rm379@cornell.edu
961315
Mancuso
Vincent
Dept Genetics
Univ Pennsylvania
415 Curie Blvd
Philadelphi
PA
19104

vincent.mancuso@gmail.com
961456
Mangone
Marco
Dept Biol
New York Univ
100 Washington Square East
New York
NY
10003

mangone@nyu.edu
960200
Mani
Kumaran
Dept Molecular Biol
Univ Wyoming
1000 E University Ave
Laramie
WY
82071

kmani2@uwyo.edu
961550
Mann
Frederick
Developmental Biology
Stanford University
279 Campus Dr
Stanford
CA
94305

biffmann@stanford.edu
961524
Mano
Itzhak
Physiol & Pharm, Sophie Davis
City College, City Univ. of NY
Harris Hall, 160 Convent Ave.
New York
NY
10031

imano@ccny.cuny.edu
960524
Manoharan
Arun

Life Sciences Institute
210 washtenaw ave
Ann Arbor
MI
48109

arunpras@umich.edu
961232
Mao
Xianrong
Anesthesiology
Washington University
660 S Euclid Ave
Saint Louis
MO
63110

maox@morpheus.wustl.edu
961294
Maro
Geraldine
Dept Biological Sci
Stanford Univ
144 Herrin Labs,385 Serra Mall
Stanford
CA
94305

gmaro@stanford.edu
961150
Martin
Ashley
Biology
University of Illinois Chicago
840 W Taylor

Chicago
IL
60607

amarti7@uic.edu
961345
Marts
Sherry
Exective Director
GSA
9650 Rockville Pike
Bethesda
MD
20814-3998

smarts@genetics-gsa.org
960691
Martynovsky
Maria
Dept Molecular Biol
Princeton Univ
Washington Rd
Princeton
NJ
8544

mmartyno@princeton.edu
960263
Mason
D
Biol Dept
Siena College
515 Loudon Rd
Loudonville
NY
12211-1462

amason@siena.edu
961244
Mattingly
Brendan
Molec Biosci
Univ Kansas
1200 Sunnyside Dr
Lawrence
KS
66045-7534

bjayhawk@ku.edu
961088
McCloskey
Richard
Molecular Biology & Genetics
Cornell University
433 Biotechnology Building
Ithaca
NY
14850

rjm76@cornell.edu
960944
McCormick
Mark
Dept Biochem & Biophysics
Univ California, San Francisco
600 16th St, Rm S314
San Francisco
CA
94143-2200

mark.mccormick@ucsf.edu
960872
McCulloch
Katherine
GCD
Univ Minnesota
321 Church St
Minneapolis
MN
55455

mccu0201@umn.edu
960259
McEwen
Tamara
MMI
University of Missouri
1 Hospital Drive
Columbia
MO
65212

tjmx9c@mizzou.edu
960848
McQuary
Philip
Development & Aging
Burnham Institiute Med Res
10901 North Torrey Pines Rd
La Jolla
CA
92037

pmcquary@burnham.org
960627
Melendez
Alicia
Dept Biol
Queens Col - CUNY
65-30 Kissena Blvd
Flushing
NY
11367

alicia.melendez@qc.cuny.edu
961251
Meli
Vijaykumar
Biological Chemistry
UCLA
615 Charles E Young Dr
Los Angeles
CA
90095

vmeli@ucla.edu
961023
Melo
Justine
Dept Molecular Biol
Massachusetts General Hospital
185 Cambridge St, Simchez 7
Boston
MA
2114

jmelo@molbio.mgh.harvard.edu
960141
Mendel
Jane
Biology
California Inst Technology
1200 E California Blvd
156-29
Pasadena
CA
91125

mendelj@caltech.edu
960378
Mendenhall
Alexander
Integrative Physiology
Univ Colorado
1480 30th St, Boulder 80303
Boulder
CO
80303

alexander.mendenhall@gmail.com
960778
Meneely
Philip
Dept Biol
Haverford Col
370 Lancaster Ave
Haverford
PA
19041

pmeneely@haverford.edu
961351
Merritt
Chris
Dept Molec Biol & Genetics
Johns Hopkins Univ Sch Med
725 N Wolfe St
Baltimore
MD
21205

cmerritt@jhmi.edu
960030
Meyer
Barbara
Dept Molec/Cell Biol, HHMI
Univ California, Berkeley
16 Barker Hall, #3204
Berkeley
CA
94720-3204

bjmeyer@berkeley.edu
960651
Meyer
Joel
Nicholas Sch
Duke Univ


Durham
NC
27708-0328

joel.meyer@duke.edu
960806
Meyers
Stephany
Dept Biol
Catholic Univ of America
620 Michigan Ave
Washington
DC
20064

meyers@cua.edu
960176
Michaelson
David
Developmental Genetics
New York Univ Medical Center
540 First Avenue
New York
NY
10016

mole333@gmail.com
960730
Michel
Agnes
Dept Molec Cell Biol
HHMI/Univ California, Berkeley
16 Barker Hall MC 3202
Berkeley
CA
94720-3204

agnes_michel@berkeley.edu
961493
Michels
William

(unaffiliated)
PO Box 5505

Novato
CA
94948

biotica@sbcglobal.net
960951
Miliaras
Nicholas
Dept Biochemistry & Genetics
NIDDK/NIH
8 Center Dr

Bethesda
MD
20892

miliarasn@niddk.nih.gov
960720
Miller
Dana
Div Basic Sci
FHCRC
1100 Fairview Ave N
Seattle
WA
98109

dlmiller@fhcrc.org
961460
Miller
David
Dept Cell & Developmental Biol
Vanderbilt Univ Sch Medicine
465 21st Ave S, 3154 MRB II
Nashville
TN
37212-8240

david.m.miller@vanderbilt.edu
960128
Miller
Kenneth
Genetic Models of Disease
Oklahoma Med Res Fndn
825 NE 13th St
Oklahoma City
OK
73104

millerk@omrf.org
960220
Miller
Leilani
Dept Biol
Santa Clara Univ
500 El Camino Real
Santa Clara
CA
95053

lmiller@scu.edu
961130
Miller
Michael
Dept Cell Biol
Univ Alabama at Birmingham
1900 University Blvd
Birmingham
AL
35294-0006

mamiller@uab.edu
961259
Miller
Raymond
Dept Biological Sci & the LMB
Univ Illinois at Chicago
900 S Ashland Ave
Chicago
IL
60607

raym5678@uic.edu
960396
Miller
Renee
Dept CNDD
Univ Rochester
601 Elmwood Ave, Box 645
Rochester
NY
14642

renee_miller@urmc.rochester.edu
961228
Milton
Angenee
Dept Biological Sci
Univ Illinois at Chicago
900 S Ashland Ave
Chicago
IL
60607

amilto3@uic.edu
960493
Minor
Paul
Chemical Engineering
Caltech
1200 E California Blvd
156-29
Pasadena
CA
91106

minor@caltech.edu
960747
Mirina
Alexandra
Dept Gen
Albert Einstein Col Med
1300 Morris Park Ave
Bronx
NY
10461

alexandra.mirina@gmail.com
961455
Miskowski
Jennifer
Dept Biol
Univ Wisconsin, La Crosse
1725 State St
La Crosse
WI
54601

miskowsk.jenn@uwlax.edu
960957
Mizumoto
Kota
Biology
Stanford University
371 Serra Mall, Herin Labs 144
Stanford
CA
94305-5020

mizumoto@stanford.edu
960332
Mondoux
Michelle
Laboratory of Molecular Biolog
NIDDK/NIH
5 Center Drive
Bethesda
MD
20892

mondouxm@mail.nih.gov
961250
Monsalve
Gabriela
Biological Chemistry
Univ California, Los Angeles
615 Charles E Young Dr
Los Angeles
CA
90095

gmonsalve@ucla.edu
961135
Montgomery
Taiowa

Massachusetts General Hospital
185 Cambridge Street, CPZN-7250
Boston
OR
2114

montgomery@molbio.mgh.harvard.edu
961545
Moore
Christopher
Medicine
University of Virginia
121 Oak Forest Circle
Charlottesville
VA
22901

cmmoore@virginia.edu
961185
Moore
Julia

Sloan Kettering
420 E 70th St

New York
NY
10021

moorej@mskcc.org
960577
Moroz
Natalie

Harvard University
24 Taft St.

Marblehead
MA
1945

natalie.moroz@gmail.com
960529
Morsci
Natalia
Dept Gen
Rutgers, The State Univ NJ
145 Bevier Rd
Piscataway
NJ
8854

morsci@dls.rutgers.edu
960143
Mortazavi
Ali
Biology
Caltech
1201 East California Blvd
MC 156-29
Pasadena
CA
91125

alim@caltech.edu
961471
Moss
Eric
Dept Molecular Biol
UMDNJ
2 Medical Center Dr
Stratford
NJ
8084

mosseg@umdnj.edu
961348
Motegi
Fumio
MBG
Johns Hopkins University
725 N. Wolfe
706/PCTB
Baltimore
MD
21205

fmotegi1@jhmi.edu
961015
Moussaif
Mustapha
Dept Mol Pharm
Albert Einstein Col Med
202 GB Morris Park Ave
Bronx
NY
10461

mmoussai@aecom.yu.edu
961282
Murakami
Shin
Basic Sciences
Touro University-California
1310 Johnson Lane
Vallejo
CA
94592

shin.murakami@touro.edu
960368
Murphy
Coleen
Dept Mol Biol
Princeton Univ
148 Carl Icahn Lab
Princeton
NJ
8540

ctmurphy@princeton.edu
961547
Murphy
John
Developmental Biology
Washington Univ
660 S Euclid

St Louis
MO
63110

murphyjt@wustl.edu
961441
Muskus
Michael
Development
Washington University
660 S. Euclid Ave.
Saint Louis
MO
63110

muskusm@wusm.wustl.edu
961281
Nabeshima
Kentaro
Dept Cell & Dev Biol
Univ Michigan
109 Zina Pitcher Pl, BSRB 3029
Ann Arbor
MI
48109-2200

knabe@umich.edu
960188
Nadarajan
Priah
Dept Genetics, Cell Biol & Dev
Univ Minnesota
420 Washington Ave, SE
Minneapolis
MN
55455

nada0010@umn.edu
960751
Nakagawa
Akihisa
Dept MCD Biol
Univ Colorado
Campus Box 347
Boulder
CO
80309-0347

akihisa.nakagawa@colorado.edu
960696
Nakamura
Ayumi

UCSF
600 16th Street
San Francisco
CA
94158

ayumi.nakamura@ucsf.edu
960841
Nakano
Shunji
Dept Biol
MIT
77 Massachusetts Ave
Cambridge
MA
2138

shunji@mit.edu
960135
Nakashima
Aisa
Genetics
University of North Carolina
216 Fordham Hall
Chapel Hill
NC
27599-3280

aisanaka@email.unc.edu
961403
Nandakumar
Madhumitha
Dept Immunology, Rm M309
Stanford Univ
300 Pasteur Dr, Alway Bldg
Stanford
CA
94305

madhun@stanford.edu
960268
Narasimhan
Sri Devi
gene function & expression
UMASS Medical School
364 Plantation St. LRB 670S
Worcester
MA
1604

sridevi.narasimhan@umassmed.edu
960502
Narayan
Anusha
Div Biol, 156-29
Caltech
1200 E California Blvd
Pasadena
CA
91125

anusha@caltech.edu
961001
Neal
Scott
Dept Biol
Brandeis Univ
415 South St
MS 008
Waltham
MA
2454

sjneal@brandeis.edu
961291
Negrete
Oscar
Biosystems Research
Sandia National Labs
7011 East Ave
MS 9292
Livermore
CA
94550

onegret@sandia.gov
960487
Nehme
Ralda
Dept Genetics
Dartmouth Col
Vail 601

Hanover
NH
3755

ralda@dartmouth.edu
961081
Nelson
Gregory
Dept Radiation Med
Loma Linda Univ
11175 Campus St, CSP A1010
Loma Linda
CA
92354

gnelson@dominion.llumc.edu
961177
Nelson
Matthew
Biology
NYU
100 Washington Sq E Silver1009
New York
NY
10003

mdn233@nyu.edu
960235
Nera
Bernadette
Biology
San Francisco State University
1600 Holloway
Biology/SEO
San Francisco
CA
94132

bnera226@gmail.com
961297
Nerkowski
Stacey
Biology
CSU San Bernardino
5500 University Parkway
San Bernardino
CA
92407

nerkowss@csusb.edu
961325
Nerpel
James

Leica Microsystems
2345 Waukegan Road
Bannockburn
IL
60015

infor@leica-microsystems.com
960656
Neto
Mario
Depart of Biochemistry, Molecular Biology, and Cel
Northwestern University
2205 Tech Drive
Evanston
IL
60208

mjneto@fc.ul.pt
960166
Nguyen
Anh
Biology
Texas Christian University
2900 South University Dr
Fort Worth
TX
76129

a.q.nguyen@tcu.edu
960898
Nimmo
Rachael
Dept of MCD Biology
Yale University
266 Whitney Ave
New Haven
CT
6511

rachael_nimmo@hotmail.com
961239
Nix
Paola
Biology
Univ Utah
257 South 1400 East
Salt Lake City
UT
84112

pnix@biology.utah.edu
961392
Noble
Scott
Dept Cell & Dev Biol
Univ Colorado Denver
PO Box 6511
8108
Aurora
CO
80045

scott.noble@uchsc.edu
961181
Norman
Ken
Cell Biol & Cancer Research
Albany Medical College
47 New Scotland Ave
MC-165
Albany
NY
12208

NormanK@mail.amc.edu
960140
Norris
Adam


505 Colorado apt 4
lawrence
KS
66044

razjericho@yahoo.com
960362
Nottke
Amanda
Dept Genetics
Harvard Medical Sch
77 Ave Louis Pasteur, NRB-334
Boston
MA
2115

anottke@fas.harvard.edu
961171
Nowak
Jessica
Biology
Canisius College
2001 Main Street
Buffalo
NY
14208

nowak9@canisius.edu
960573
Nunez
Lizbeth
Biology
Queens College of The City University of New York
1505 Greene Avenue
Brooklyn
NY
11237

lizng20@gmail.com
961248
O'Connell
Kevin
Dept LBG
NIDDK/NIH
8 Center Dr

Bethesda
MD
20892

kevino@intra.niddk.nih.gov
961047
O'Doherty
Inish
Chemistry & Chem Biol
Cornell Univ
Tower Rd

Ithaca
NY
14853

imo3@cornell.edu
960528
O'Hagan
Robert
Dept Gen
Rutgers, The State Univ NJ
145 Bevier Rd
Piscataway
NJ
8854

ohagan@biology.rutgers.edu
961293
O'Halloran
Damien
Neuroscience
UC Davis
1544 Newton Court
Davis
CA
95616

dmohalloran@ucdavis.edu
961385
O'Hanlon
Shante
Biological Sciences
San Jose State University
1 Washington Square / DH-444
San Jose
CA
95192

shante_ohanlon@yahoo.com
960243
O'Meara
Michelle
Genetics & Development
Columbia University
701 West 168th ST
HHSC/7th Floor
New York
NY
10032

mmo2104@columbia.edu
961426
O'Rourke
Eyleen
Dept Molecular Biol
Massachusetts General Hosp
185 Cambridge St, CPZN-7250
Boston
MA
2114

eorourke@molbio.mgh.harvard.edu
961511
O'Rourke
Sean
Inst Molec Biol
Univ Oregon
1229 Univ Oregon
Eugene
OR
97403-1229

seanor@molbio.uoregon.edu
960165
Ohlmeyer
Johanna
Dept.of Biochemistry, HHMI
Columbia University

New Yorkn
NY
10032

jo32@columbia.edu
960139
Oikonomou
Grigorios

Rockefeller Univ
1230 York Ave, Box 86
New York
NY
10065

goikonomou@rockefeller.edu
961223
Okkema
Peter
Dept Biological Sciences
Univ Illinois at Chicago
900 S Ashland Ave, MC 567
MC567
Chicago
IL
60607

okkema@uic.edu
960444
Olivier-Mason
Anique
Dept Molecular Cellular Biol
Brandeis Univ
415 South St

Waltham
MA
2453

aniqueom@brandeis.edu
960450
Olson
Sara
Ludwig Institute
UC San Diego
9500 Gilman Ave, CMME3071
La Jolla
CA
92093-0660

solson@ucsd.edu
960847
Ong
Binnan
Development & Aging
Burnham Institiute Med Res
10901 North Torrey Pines Rd
La Jolla
CA
92037

binnano@burnham.org
961451
Onken
Brian
Dept Molecular Biol & Biochem
Rutgers Univ
604 Allison Rd
Piscataway
NJ
8854

onken@biology.rutgers.edu
961040
Operana
Theresa
Dev & Stem Cell Biol
Joslin Diabetes Ctr
One Joslin Place
Boston
MA
2215

theresa.operana@joslin.harvard.edu
960223
Opperman
Laura
Genetics
University of Wisconsin-Madison
425 (G) Henry Mall
Madison
WI
53706

ljopperman@wisc.edu
961503
Ostroff
Rachel
Dept Cell/Developmental Biol
Vanderbilt Univ
465 21st Ave S
Nashville
TN
37232-8240

rachel.l.ostroff@vanderbilt.edu
960885
Ou
Guangshuo
MOLECULAR & CELLULAR PHARMACOLOG
Univ California, SAN FRANCISCO
600 16TH ST

SAN FRANCISCO
CA
94158

gou@cmp.ucsf.edu
960099
Owraghi
Melissa
Dept Biol
Univ California, Riverside
900 Univeristy Ave
Riverside
CA
92521

mowra001@student.ucr.edu
960294
Ozersky
Philip
Gen/Genome Sequencing Ctr
Washington Univ Sch Medicine
4444 Forest Park Blvd
St Louis
MO
63108

pozersky@watson.wustl.edu
960400
Padilla
Pamela
Dept Biological Sci
Univ North Texas
PO Box 305220
Denton
TX
76203-5220

ppadilla@unt.edu
961121
Pagano
Daniel
Dept Biol
MIT
31 Ames Street, 68-430
Cambridge
MA
2139

dpagano@mit.edu
961236
Pagano
John
Biochem & Molec Pharm
Univ Massachusetts Med Sch
364 Plantation St
Worcester
MA
1605

john.pagano@umassmed.edu
960203
Page
Kathryn
Lithgow Lab
Buck Institute
8001 Redwood Bvld.
Novato
CA
94945

kpage@buckinstitute.org
961290
Pak
Stephen
Dept Pediatrics
University of Pittsburgh
530 45th St, Rangos Bld Rm7131
Pittsburgh
PA
15201

scp10@pitt.edu
960875
Palchick
Zachary
Dept Biol
Carleton College
300 N College St
Northfield
MN
55057

palchicz@carleton.edu
960802
Palmitessa
Aimee


1600 N Curson Ave
Los Angeles
CA
90046

aimeep_72@yahoo.com
960931
Palter
Julia
MCDB/BMSE
Univ California, Santa Barbara
Bldg 571, rm 6129
Santa Barbara
CA
93106

palter@lifesci.ucsb.edu
961137
Pandey
Amita
Dept Plant & Microbial Biol
Univ California, Berkeley
16 Barker Hall
Berkeley
CA
94720

amita08@berkeley.edu
961406
Pant
Saumya
Dept Molecular Biol & Biochem
Rutgers Univ
604 Allison Rd
Piscataway
NJ
8854

spant@eden.rutgers.edu
961070
Paquin
Nicolas
Biology
MIT
31 Ames

Cambridge
MA
2139

npaquin@mit.edu
961551
Park
Joori

Stanford University / Biology
371 Serra Mall / Herrin Labs #144
Stanford
CA
94305-5020

parkjr@stanford.edu
960377
Park
Sang-Kyu
IBG
Univ Colorado at Boulder
1480 30th St

Boulder
CO
80303

sangkyu@colorado.edu
960934
Parrish
Angela
Biology
Univ of CA, San Diego
10010 N. Torrey Pines Road
CBPL-W
La Jolla
CA
92037

arparrish@ucsd.edu
961201
Patel
Dhaval
Dept Biol Structure
Univ Washington
1959 NE Pacific St
Seattle
WA
98195

dhavalsp@u.washington.edu
960288
Patel
Falshruti
Dept Pathology
UMDNJ/RWJMS
675 Hoes Lane, Res Tower, R232
Piscataway
NJ
8854

patelfb@umdnj.edu
960808
Patel
Risha
Molecular Pharmacology
Albert Einstein College of Medic
1300 Morris Park Ave.
Bronx
NY
10461

rpatel@aecom.yu.edu
960670
Pathare
Pranali
Dept Basic Sci
Fred Hutchinson Research Ctr
1100 Fairview Ave
Seattle
WA
98109

ppranali@hotmail.com
961073
Pavelec
Derek
Genetics
Univ Wisconsin
425G Henry Mall, Room 2476
Madison
WI
53706

pavelec@wisc.edu
961184
Pedone
Katherine
Dept Pharm
Univ North Carolina
450 West Dr
CB# 7295
Chapel Hill
NC
27599-7295

kpedone@med.unc.edu
960818
Peel
Nina
LBG, NIDDK
NIH
8 Center Drive
Bethesda
MD
20892

peeln@niddk.nih.gov
960338
Peliti
Margherita

Rockefeller Univ
1230 York Ave, Box 59
New York
NY
10065

pelitim@mail.rockefeller.edu
960334
Peters
Maureen
Dept Biol
Oberlin Col
119 Woodland St
Oberlin
OH
44074

maureen.peters@oberlin.edu
960490
Petrella
Lisa
MCD Biol
Univ California, Santa Cruz
1156 High St

Santa Cruz
CA
95060

petrella@biology.ucsc.edu
961257
Petty
Emily
Dept MCDB
Univ Michigan
830 North University
Ann Arbor
MI
48108

emilynnp@umich.edu
960728
Pferdehirt
Rebecca
Dept Molecular & Cellular Biol
Univ California, Berkeley
16 Barker Hall
Berkeley
CA
94720

beckyp@berkeley.edu
960912
Phillips
Carolyn
Molec Biol Dept
Massachusetts Gen Hosp
185 Cambridge St CPZN-7250
Boston
MA
2114

phillips@molbio.mgh.harvard.edu
961480
Piano
Fabio
Dept Biol
New York Univ
1009 Silver Ctr
New York
NY
10003

fp1@nyu.edu
960876
Pickett
Chris
Developmental Biology
Washington University
660 S Euclid Ave
Saint Louis
MO
63110

cpickett@wustl.edu
960212
Piggott
Beverly

Life Sciences Inst
210 Washtenaw Ave, Rm 6239
Ann Arbor
MI
48109

bpiggott@umich.edu
961447
Pinan-Lucarre
Berangere
Dept Molecular Biol & Biochem
Rutgers Univ
604 Allison Rd
Piscataway
NJ
8854

pinan@biology.rutgers.edu
960899
Pincus
Zachary
Molecular, Cellular, & Dev Bio
Yale University
266 Whitney Ave
New Haven
CT
06511-8902

zachary.pincus@yale.edu
960395
Pires da Silva
Andre
Dept Biol
Univ Texas, Arlington
501 S Nedderman Dr
Arlington
TX
76019

apires@uta.edu
961572
Pirri
Jennifer
Neurobiology
UMass Medical School
364 Plantation St
LRB 770R
Worcester
MA
1605

jennifer.pirri@umassmed.edu
960708
Plenefisch
John
Dept Biol Sci
Univ Toledo
2801 W Bancroft
601
Toledo
OH
43606

jplenef@uoft02.utoledo.edu
960079
Pocock
Roger
Dept Biochem/Molec Biophysics
Columbia Univ
701 W 168th St, HHSC 724
New York
NY
10032

rp2184@columbia.edu
960805
Politi
Kristin
Neuroscience
Albert Einstein Col Med
1410 Pelham Pkwy
Bronx
NY
10461

kpoliti@fandm.edu
961485
Politz
Samuel
Dept Biol/Biotech
Worcester Polytechnic Inst
100 Inst Rd

Worcester
MA
01609-2280

spolitz@wpi.edu
960833
Pollard
Daniel


14 Washington Place Apt 4H
New York
NY
10003

dpollard@gmail.com
960187
Polley
Stanley
Molecular Biology
University of Wyoming
16th & Gibbon
Laramie
WY
82071

spolley@uwyo.edu
960155
Pollok
Robert

UTSouthwestern Medical Center
4600 Harry Hines Blvd. NA5.504
Dallas
TX
75390

robert.pollok@utsouthwestern.edu
961394
Poole
Richard
Dept Biochem & Molec Physics
Columbia University
701 W 168th St
New York
NY
10032

rp2238@columbia.edu
961344
Porter
Aidan

Harvard University
189 Concord Ave
Cambridge
MA
2138

aporter@mcb.harvard.edu
960767
Porter Abate
Jess
Dev & Stem Cell Biol
Joslin Diabetes Ctr
1 Joslin Place

Boston
MA
2215

jess.porter@joslin.harvard.edu
960218
Portman
Douglas
Ctr Neural Dev & Disease
Univ Rochester Sch Med Dent
601 Elmwood Ave, Box 645
Rochester
NY
14642

douglas.portman@rochester.edu
960717
Powell
Jennifer
Dept Molecular Biol
Massachusetts General Hosp
50 Fruit St

Boston
MA
2114

jpowell@molbio.mgh.harvard.edu
961170
Powell-Coffman
Jo
Genetics, Dev, & Cell Biology
Iowa State Univ
2108 Molecular Biology Bldg
Ames
IA
50011

japc@iastate.edu
961140
Praitis
Vida
Dept Biol
Grinnell Col
1116 8th Ave

Grinnell
IA
50112

praitis@grinnell.edu
960599
Price
Meredith
Inst Molecular Biology
Univ Oregon
1370 Franklin Blvd
Eugene
OR
97403

mhprice@molbio.uoregon.edu
960290
Procko
Carl
Dept Dev Gen
Rockefeller Univ
1230 York Ave Box 46
New York
NY
10065

prockoc@mail.rockefeller.edu
961536
Pulak
Rock

Union Biometricia, Inc
84 October Hill Rd
Holliston
MA
01746-1371

rpulak@unionbio.com
961095
Pym
Edward


21 Eliot St

Jamaica Plain
MA
2130

pym@molbio.mgh.harvard.edu
960423
Qadota
Hiroshi
Dept Pathology
Emory Univ
615 Michael St,Whitehead 105P
Atlanta
GA
30322

hkadota@emory.edu
960163
Qi
Yingchuan
Biol/HHMI
UC San Diego
9500 Gilman Dr, Bonner 2429
La Jolla
CA
92093

billyqi@ucsd.edu
960476
Qin
Yuqi
OEB
Harvard University
52 Oxford Street
Cambridge
MA
2138

yqqinzju@gmail.com
960959
Raghavan
Prashant
Islet Cell Biology
Joslin Diabetes Centre
One Joslin Place
Boston
MA
2215

prashant.raghavan@joslin.harvard.edu
960680
Rahman
Mohammad
Genetics
University of Georgia
Davidson Life Sci Complex
Athens
GA
30602-7223

mrahman1@uga.edu
960831
Raizen
David
Ctr Sleep, 1400 TRL
Univ Pennsylvania
125 S 31st St

Philadelphia
PA
19104

raizen@mail.med.upenn.edu
960786
Ralston
Edward
MCB
Univ California, Berkley
131 Koshland Hall
Berkeley
CA
94720

eralston@uclink.berkeley.edu
960943
Ramaswamy
Priya
Biochem & Biophysics
UCSF
600 16th Street
S314 Genentech Hall
San Francisco
CA
94158

priya.ramaswamy@ucsf.edu
960226
Rand
James
Gen Models Disease Res Prog
Oklahoma Med Res Fndn
825 NE 13th St
Oklahoma City
OK
73104-5046

james-rand@omrf.org
960813
Randall
Catherine
MCD Biology
UC, Santa Cruz
1156 High Street
Sinsheimer Labs
Santa Cruz
CA
95064

randall@biology.ucsc.edu
960822
Rasheed
Hasan

University of Florida
1600 sw archer rd
Gainesville
Fl
32610

birdzo2k2@gmail.com
961022
Rasmussen
Jeffrey
Molec & Cellular Biol Program
FHCRC
1100 Fairview Ave N
Seattle
WA
98109

rasmuss@u.washington.edu
960522
Rauthan
Manish
Life Sciences Institute
Michigan University
210 Washtenaw Ave
ann arbor
MI
48109

mrauthan@umich.edu
961062
Reece-Hoyes
John
PGFE
UMass Medical School
364 Plantation Street
Worcester
MA
1605

john.reece-hoyes@umassmed.edu
961409
Ren
Min
Ben-May Dept Cancer Res
Univ Chicago
929 E 57th St

Chicago
IL
60637

mindyren@uchciago.edu
961122
Richardson
Claire
Biol
MIT
31 Ames St

Cambridge
MA
2139

clairer@mit.edu
960925
Riddle
Misty

Univ California, Santa Barbara
NRI, Bldg 571, Rm 6129
Santa Barbara
CA
93106-5060

riddle@lifesci.ucsb.edu
960777
Riedel
Christian
Dept. of Molecular Biology
Mass. General Hospital
185 Cambridge St, CPZN-7250
Boston
MA
2114

riedel@molbio.mgh.harvard.edu
960763
Riefler
Gary
Dept of Genetics
UT MD Anderson Cancer Center
1515 Holcombe Blvd, Unit 1010
Houston
TX
77030-4009

griefler@mdanderson.org
960974
Rillo
Regina

UC Berkeley
460 Stanley Hall MC 3220
Berkeley
CA
94720-3220

regrillo@berkeley.edu
961500
Ringstad
Niels
Dept Biol
MIT
77 Massachusetts Ave
Cambridge
MA
2139

ringstad@mit.edu
960585
Rizki
Gizem
Molec Biol & Gen
Cornell Univ
341 Biotechnology Building
Ithaca
NY
14850

gr64@cornell.edu
961443
Robertson
Dana
Biochem & Biophysics
UCSF
600 16th Street
Room S314, Box 2200
San Francisco
CA
94158

dana.robertson@ucsf.edu
960688
Rockman
Matthew
Dept Biol
New York Univ
100 Washington Square E, #1009
New York
NY
10003

mrockman@nyu.edu
960694
Rodrigues
Ana

Salk Institute
10010 N Torrey Pines Rd
La Jolla
CA
92037-1099

arodrigues@salk.edu
960968
Rodrigues
Pedro

Buck Inst
8001 Redwood blvd
Novato
CA
94945

prodrigues@buckinstitute.org
960768
Roehrig
Casey
Dept Molec & Cell Biol
Harvard Univ
16 Divinity Ave, BL3050
Cambridge
MA
2138

croehrig@mcb.harvard.edu
961189
Rogers
Aric
Gen Aging
Buck Inst Age Res
8001 Redwood Blvd
Novato
CA
94945

arogers@buckinstitute.org
961157
Rogers
Zoe
Biology
MIT
77 Massachusetts Ave
68-440
Cambridge
MA
2139

zoer@mit.edu
960874
Roh
Hyun
Dev Biol
Washington Univ in St Louis
Campus Box 8103,  4566 Scott Ave.
St. Louis
MO
63108

hcroh@wustl.edu
961249
Rohde
Christopher

MIT
77 Massachusetts Ave
Cambridge
MA
2139

crohde@mit.edu
961020
Rohlfing
Anne-Katrin
Physiology
University of Pennsylvania
3700 Hamilton Walk
Philadelphia
PA
19104

arohlf@mail.med.upenn.edu
960721
Rohrschneider
Monica
Dev Gen Program, Skirball Inst
New York Univ-Sch Med
540 1st Ave

New York
NY
10016

mrohrsch@saturn.med.nyu.edu
961408
Romero
Catalina
Systems Biology
Harvard Univeristy
200 longwood ave
Boston
MA
2115

cromero@fas.harvard.edu
961097
Rose
Lesilee
Dept Molec & Cellular Biol
Univ California, Davis
One Shields Ave
Davis
CA
95616

lsrose@ucdavis.edu
960676
Rosu
Simona
Dept Genetics
Stanford Univ
279 Campus Dr, Beckman B300
Stanford
CA
94305

srosu@stanford.edu
961077
Rothman
Jason
Biological Sciences
CA State Polytechnic Univ.
1190 Sequioa Glen
Pomona
CA
91766

jarothman@scupomona.edu
960923
Rothman
Joel
Dept NRI
Univ California
Bldg 571, rm 6129
Santa Barbara
CA
93106

rothman@lifesci.ucsb.edu
960307
Rottiers
Veerle
Cancer Ctr
Massachusetts Gen Hosp
149, 13th St
7103
Charlestown
MA
2129

veerle@libertsweb.com
960966
Rougvie
Ann
Dept Gen, Cell Biol & Dev
Univ Minnesota
321 Church St SE
Minneapolis
MN
55455

rougvie@umn.edu
961090
Rubin
Charles
Dept Molecular Pharmacology
Albert Einstein Col Medicine
1300 Morris Park Ave
Bronx
NY
10461

rubin@aecom.yu.edu
960468
Ruck
Alexander
Biol
Queens College
65-30 Kissena Blvd
Flushing
NY
11367

alexinstereo@gmail.com
961173
Russel
Sascha
Dept Mol. Biol-Simches
Harvard Univ/Mass Gen Hosp
185 Cambridge Street, CPZN-725
Boston
MA
02114-2790

russel@amber.mgh.harvard.edu
961195
Ruvinsky
Ilya
Ecology & Evolution
Univ Chicago
1101 east 57th St
Chicago
IL
60637

ruvinsky@uchicago.edu
961516
Sagi
Dror
Dept Developmental Biol
Stanford Univ
279 Campus Dr
Stanford
CA
94305

drorsagi@stanford.edu
961167
Sahu
Surasri
Div Virulence assessment
Food & Drug Administration
8301 Muirkirk Rd
Laurel
MD
20708

surasri.sahu@fda.hhs.gov
960309
Saito
Mako
Genetics
Dartmouth Medical School
601 Vail
HB 7400
Hanover
NH
3755

richard.m.saito@dartmouth.edu
960077
Saito
Takamune
Dept Genetics
Harvard Medical Sch
77 Ave Louis Pasteur
Boston
MA
2115

tsaito@genetics.med.harvard.edu
961427
Saldi
Tassa
Molecular, Cellular, Dev. Bio
University of Colorado, Boulder
304 Cherokee Ave
Superior
CO
80027

Tassa.Saldi@colorado.edu
961268
Salesky
Becca

Lewis & Clark College

Porltand
OR
97219

salesky@lclark.edu
961087
Salhanha
Jenifer
GDCB
Iowa State Univ
2132, MBB

Ames
IA
50011-3260

jenifers@iastate.edu
960245
Sallee
Maria
Genetics
Columbia University
701 West 168th ST
HHSC/7th Floor
New York
NY
10032

mds2178@columbia.edu
961179
Samara
Chrysanthi
Res Lab Electronics
Massachusetts Inst Tech
50 Vassar St

Cambridge
MA
2139

csamara@mit.edu
960800
Samidurai
Arun
TMB,NHLBI
NIH
9000,Rockville pike
Bethesda
MD
20892

samiduraia@mail.nih.gov
960798
Samuel
Buck
Molecular Biology
Mass General Hospital
185 Cambridge St.
Boston
MA
2114

bsamuel@molbio.mgh.harvard.edu
961147
Samuel
Tamika
Dept Animal & Avian
Univ Maryland
2410 ANSC, Bldg 142
College Park
MD
20742

tsamuel@umd.edu
960472
Samuelson
Andrew
Dept Molecular Biol
Massachusetts General Hosp
185 Cambridge St 7th FL
Boston
MA
2114

samuelso@molbio.mgh.harvard.edu
961154
Sancar
Feyza
Biology
University of Illinois Chicago
840 W Taylor

Chicago
IL
60607

sancar@uic.edu
961513
Sanchez-Blanco
Adolfo
Dev Biol
Stanford Univ Sch Med
279 Campus Dr
Stanford
CA
94305

asb123@stanford.edu
961361
Sanford
Brittany
Biology Department
Muhlenberg College
2400 Chew St
Allentown
PA
18104

bs236407@gws3.muhlenberg.edu
960388
Sann
Sharon
Neurobiology
UCSD
9500 Gilman Drive MC0368
La Jolla
CA
92037-0368

ssann@ucsd.edu
961318
Santella
Anthony
Dev Biol
Sloan Kettering Inst
430 e 67th st Rm 817a
NY
NY
10065

santella@mskcc.org
960503
Sapir
Amir
Divison Biol
California Inst Tech
1200 E California Blvd
156-29
Pasadena
CA
91125

amirsa@caltech.edu
960057
Sarin
Sumeet
Dept Genetics & Development
Columbia Univ
701 W 168th St, HHSC Rm 724
New York
NY
10032

ss2387@columbia.edu
960972
Sato
Aya

UC Berkeley
460 Stanley Hall MC 3220
Berkeley
CA
94720-3220

asato@lbl.edu
961267
Scavarda
Emily
Biochem
Lewis and Clark College

Portland
OR
97210

emilyas@lclark.edu
960133
Schaedel
Oren
Div Biol
Caltech
1200 E California Blvd
Pasadena
CA
91125

orens@caltech.edu
960302
Schedl
Tim
Dept Genetics, Medical Sch
Washington Univ
4566 Scott Ave,Campus Box 8232
St Louis
MO
63110

ts@genetics.wustl.edu
960045
Scheider
Meredith
Biological Science
Univ Buffalo (SUNY)
109 Cooke Hall
Buffalo
NY
14260

mjs32@buffalo.edu
961364
Schieltz
Jennifer
biological sciences
University of Alabama
411 Hackberry Lane
Tuscaloosa
AL
35487

jmschieltz@bama.ua.edu
960249
Schindelman
Gary
Div Biol
California Inst Technology
1200 E California Blvd
156-29
Pasadena
CA
91125

garys@caltech.edu
960697
Schisa
Jennifer
Dept Biol
Central Michigan Univ
Brooks Hall

Mount Pleasant
MI
48859

schis1j@cmich.edu
961473
Schneider
Judsen
Dept Cell & Developmental Biol
Vanderbilt Univ
3020 Brightwood Ave
Nashville
TN
37232

judsen.d.schneider@vanderbilt.edu
961331
Schott
Daniel
Molec & Cellular Biol
Harvard Univ
16 Divinity Ave
Cambridge
MA
2138

dhs@mcb.harvard.edu
960825
Schroeder
Frank
Boyce Thompson Inst
Cornell Univ
1 Tower Rd

Ithaca
NY
14853

fs31@cornell.edu
960530
Schroeder
Nathan
Dept Gen
Rutgers, The State Univ NJ
145 Bevier Rd
Piscataway
NJ
8854

schroeder@biology.rutgers.edu
961567
Schubert
Wayne

Jet Propulsion Lab
4800 Oak Grove Dr
Pasadena
CA
91109

wayne.w.schubert@jpl.nasa.gov
961458
Schultz
Robbie
Molecular & Cellular Medicine
Texas A&M University
446 Reynolds Medical Building
College Station
TX
77843

rdszpf@tamu.edu
960053
Schumacher
Jill
Genetics
Univ Texas MD Anderson CA Ctr
1515 Holcombe Blvd, Unit 1010
Houston
TX
77030

jschumac@mdanderson.org
960152
Schwarz
Erich
Div Biol
California Inst Technology
Biology, 156-29
Pasadena
CA
91125

emsch@its.caltech.edu
961256
Scrogham
Lynn
Dept Biological Sci
Univ Illinois, Chicago
900 S Ashland
Chicago
IL
60607

lscrogha@uic.edu
961510
Seidel
Hannah
EEB
Princeton Univ
106A Guyot Hall
Princeton
NJ
8544

hseidel@princeton.edu
960301
Sengupta
Piali
Dept Biol
Brandeis Univ
415 South St, MS 008
Waltham
MA
2454

sengupta@brandeis.edu
960239
Serrano
Esther
Biochemistry
Columbia University
701 West 168th ST
HHSC/7th Floor
New York
NY
10032

es2754@columbia.edu
961152
Severance
Scott
Animal & Avian Sciences
University of Maryland
Route 1, Bldg 142
College Park
MD
20742

severanc@umd.edu
960724
Severson
Aaron
Dept Molecular & Cell Biol
Univ California, Berkeley
16 Barker Hall, #3202
Berkeley
CA
94720-3204

afsevers@berkeley.edu
961334
Seydoux
Geraldine
Dept Molec Biol & Gen
Johns Hopkins Univ Sch Med
725 N Wolfe St, 706 PCTB
Baltimore
MD
21205

gseydoux@jhmi.edu
960589
Shah
Muazzum

University of Michigan
801 E Ann St Apt 1
Ann Arbor
MI
48104

muazzum@umich.edu
961561
Shaye
Daniel

HHMI
701 West 168th St.
New York
NY
10032

ds451@columbia.edu
961463
She
Xingyu
CBPL
The Salk Institute for Biologica
10010 N. Torrey Pines Road
La Jolla
CA
92037-1099

xshe@salk.edu
960422
Shemer
Gidi
Dept Biol
Univ North Carolina
Campus Box 3280, Coker Hall
Chapel Hill
NC
27599

bishemer@email.unc.edu
960759
Shen
Yidong


1 Baylor Plz. MS: 230
Houston
TX
77030

yidongs@bcm.tmc.edu
960512
Shen
Yu
OEB
Harvard University
Northwest Building RM253, 52 Oxford St.
Cambridge
MA
2138

shenyupku@gmail.com
961363
Sheth
Ujwal

FHCRC
1100 Fairview Ave N
Seattle
WA
98109

usheth@fhcrc.org
961207
Shi
Yong
Dept MCDB
Colorado Univ
1350 20th St #k11
Boulder
CO
80302

yong_shi1@yahoo.com
961539
Shi
Zhen
Molecular Biology
Mass General Hospital
185 Cambridge St, 7th Floor
Boston
MA
2114

shi@fas.harvard.edu
961542
Shinar
Tamar
Courant Institute
New York University
14 Washington Pl Apt 7L
New York
NY
10003

ttshinar@gmail.com
960232
Shivers
Robert
Department of Basic Sciences
Commonwealth Medical College
501 Madison Ave, RM 215
Scranton
PA
1850

rshivers@tcmedc.org
960471
Shore
David
Dept BBS Genetics
Harvard Medical Sch
220 Longwood Ave
Boston
MA
2115

david_shore@med.harvard.edu
960142
Shtessel
Ludmila
Genetics
UNC Chapel Hill
Medical Dr.

Chapel Hill
NC
27599

luda@email.unc.edu
960895
shu
Yilong
Dept Biological Sci
Univ Alabama
411 Hackberry Ln.
Tuscaloosa
AL
35487

yshu@bama.ua.edu
961534
Sieburth
Derek
Zilkha Neurogenetic Inst
Univ Southern California
1501 San Pablo St
Los Angeles
CA
90089

sieburth@usc.edu
960453
Silva
Malan
Biology
SUNY College at Geneseo
1 College Circle
332 Integrated Science Center
Geneseo
NY
14454

mss8@geneseo.edu
960173
Simmons
Alicia
Genetics
University of North Carolina at Chapel Hill
Chapel Hill
NC
27599

simmona@email.unc.edu
960282
Simske
Jeffrey

Rammelkamp Ctr
2500 MetroHealth Dr
Cleveland
OH
44109-1998

jsimske@metrohealth.org
961148
Sinclair
Jason
Animal & Avian Sci
Univ Maryland
Route 1

College Park
MD
20742

jsincla1@umd.edu
960949
Singaravelu
Gunasekaran

Waksman Institute of Microbiol
190 Frelinghuysen Road
Piscataway
NJ
8854

guna@waksman.rutgers.edu
961194
Singh
Komudi
Medicine
Massachusetts General Hospital
149-7103 13th St
Boston
MA
2129

ksingh3@partners.org
960803
Singh
Nirupama
Biology
Catholic University of America
620 Michigan Avenue N.E.
103 McCortWard Hall
Washington DC
DC
20064

50singh@cua.edu
960432
Singh
Sharda
Dept Pharm Tox
Univ Arkansas Med Sci
4301 West Markham
Little Rock
AR
72205

singhshardap@uams.edu
961517
Singh
Varsha
Dept Molec Genetics Microbiol
Duke Univ
Research Dr, #3580
Durham
NC
27710

varsha.singh@duke.edu
960947
Singson
Andrew
Waksman Inst
Rutgers Univ
190 Frelinghuysen Rd
Piscataway
NJ
08854-8020

singson@waksman.rutgers.edu
960056
Skop
Ahna
Gen & Med Gen,2426 Gen/Biotech
Univ Wisconsin, Madison
425-G Henry Mall
Madison
WI
53706

skop@wisc.edu
960726
Slaby
Todd
Dept Molecular & Cell Biol
Univ California, Berkeley
16 Barker Hall, #3202
Berkeley
CA
94720-3204

slaby@berkeley.edu
961030
Slightam
Cindie
Dev Bio
Stanford University
279 Campus Drive
Stanford
CA
94305

cindie@stanford.edu
961013
Sluder
Ann

Scynexis
PO Box 12878
Research Triangle Park
NC
27709

ann.sluder@scynexis.com
960196
Smith
Amanda
Nicholas School of the Environment
Duke University
Research Drive
A 304
Durham
NC
27705

ams66@duke.edu
961490
Smith
Cody
Cell and Developmental Biology
Vanderbilt University
2108 Hayes ST apt 12
Nashville
TN
37203

cssmity@hotmail.com
960735
Smith
Harold

NIH/NIDDK
8 Center Drive
Bethesda
MD
20892

harold.smith.tarheel@gmail.com
960242
Smith
Heidi
Biological Sciences
Columbia University
701 West 168th ST
HHSC/7th Floor
New York
NY
10032

hks2102@columbia.edu
960996
Smith
Joseph
Dept Human Gen
Univ Utah
15 North 2030 East, Rm 2100
Salt Lake City
UT
84112

jsmith@genetics.utah.edu
960363
Smolikov
Sarit
Genetics Department
Harvard Medical School
77 Ave Louis Pasteur, NRB-334
Boston
MA
2115

saritsmol@genetics.med.harvard.edu
960306
Somers
Gerard
Cancer Center
Massachusettus General Hospital
13th Street

Charlestown
MA
2129

upsgerardsomers@yahoo.com
960928
Sommermann
Erica
Dept Molec Cell, Dev Biol
Univ California, Santa Barbara
Bldg 571, rm 6129
Santa Barbara
CA
93106

sommerma@lifesci.ucsb.edu
960563
Song
Anren
Biochem & Mol. Biology
LSUHSC-S
1501 Kings Hwy
Shreveport
LA
71103

asong@lsuhsc.edu
960182
Song
Bo-mi
Department of molecular biology
UTsouthwestern Medical Center
6000 Harry Hines Blvd
Dallas
TX
75390-9148

bomi.song@gmail.com
960950
Song
Mi
Lab Biochem/Genetics, MSC 0830
NIDDK/NIH
9000 Rockville Pike, 8/2A07
Bethesda
MD
20892-0830

mihyesong@mail.nih.gov
960962
Soto
Martha
Dept Pathology/Lab Med
UMDNJ - RWJMS
675 Hoes Lane, R231
Piscataway
NJ
8854

sotomc@umdnj.edu
960525
Soukas
Alexander
Dept Molec Biol
Massachusetts Gen Hosp
185 Cambridge St, CPZN 7250
Boston
MA
2114

asoukas@partners.org
961466
Spencer
William
Dept Cell & Dev Biol
Vanderbilt Univ Sch Med
465 21st Ave S, 3154 MRBII
Nashville
TN
37232-8240

clay.spencer@vanderbilt.edu
961191
Spieth
John
Gen/Genome Sequencing Ctr
Washington Univ Sch Medicine
4444 Forest Park Blvd
Campus Box 8501
St Louis
MO
63108

jspieth@watson.wustl.edu
961225
Spooner
Patrick

Albany Medical Center
43 New Scotland Ave
165
Albany
NY
12208

patrickspoon@gmail.com
960039
Srinivasan
Jagan
Biology Division
Caltech
1200 E California Blvd
Pasadena
CA
91125

jsrini@caltech.edu
960365
Srinivasan
Supriya
Dept Physiology
Univ California, San Francisco
600 16th St, N416 Genentech Hl
San Francisco
CA
94107

supriya.srinivasan@ucsf.edu
961350
Staab
Trisha

Univ of Southern California
3844 Latrobe Street
Los Angeles
CA
90031

tstaab@usc.edu
961405
Staben
Stefan

SFSU
Holloway Drive
San Francisco
Ca
94115

staben@sfsu.edu
960976
Stamper
Ericca

UC Berkeley
460 Stanley Hall MC 3220
Berkeley
CA
94720-3220

ericca@berkeley.edu
960698
Stanfield
Gillian
Dept Human Gen
Univ Utah
15 North 2030 East Rm 2100
Salt Lake City
UT
84103

gillians@genetics.utah.edu
960877
Starr
Daniel
Mol & Cellular Biol
Univ California, Davis
1 Shields Ave

Davis
CA
95616

dastarr@ucdavis.edu
960145
Stawicki
Tamara

UCSD
9500 Gilman Dr., MC 0368
368
La Jolla
CA
92093-0368

tstawick@ucsd.edu
961434
Steven
Robert
Biological Sci
Univ Toledo
2801 W Bancroft St
Toledo
OH
43606

robert.steven2@utoledo.edu
961546
Stewart
Candace
Biological Sciences
University of North Texas
Department of Biological Sciences 1155 Union Circle #305220
Denton
TX
76203

candaces@unt.edu
961159
Stewart
Rachel
Biology
Oberlin College
119 Woodland Street
Oberlin
OH
44074

rstweart@oberlin.edu
960319
Stokes
Michelle
Chemistry
Agnes Scott College
141 E College Ave
Decatur
GA
30030

mstokes@agnesscott.edu
960836
Stout
Randy
Neurobiology
Univ Alabama at Birmingham
1825 University Blvd
Birmingham
AL
35294

rstout@nrc.uab.edu
960448
Strome
Susan
MCD Biol
U California, Santa Cruz
1156 High St

Santa Cruz
CA
95064

strome@biology.ucsc.edu
961381
Stroustrup
Nicholas
Systems Biology
Harvard Medical School
200 Longwood Ave
Boston
MA
2115

stroustr@fas.harvard.edu
960936
Suchanek
Monika
Dept Biochemistry/Biophysics
Univ California, San Francisco
600 16th St

San Francisco
CA
94158

monika.suchanek@ucsf.edu
960205
Sujkowski
Alyson
Biological Sciences
The University of Toledo
2801 W. Bancroft
601
Toledo
OH
43606

alyson.sujkowski@utoledo.edu
961253
Sullivan-Brown
Jessica
Biology
UNC-Chapel Hill
Medical Drive

Chapel Hill
NC
27599

sullivjl@email.unc.edu
961032
Sun
Chun-Ling
Dept MCD Biol
Univ Colorado
Campus Box 347
Boulder
CO
80303

chunling.sun@colorado.edu
961359
Sundaram
Meera
Dept Gen
Univ Pennsylvania Sch Med
415 Curie Blvd, 446A CRB
Philadelphia
PA
19104-6145

sundaram@mail.med.upenn.edu
961029
Sundararajan
Lakshmi
Molecular Biosciences
University of kansas
1301 W 24th street
Lawrence
KS
66046

lakshmisrajan@gmail.com
960924
Suzuki
Taiga
Dept NRI
Univ California
Bldg 571, rm 6129
Santa Barbara
CA
93106

suzuki@lifesci.ucsb.edu
961538
Sze
Ji
Dept Molec Pharm
Albert Einstein Col Med
1300 Morris Park Ave
Bronx
NY
10461

jsze@aecom.yu.edu
960222
Tabuchi
Tomoko
Program Molecular Medicine
Univ Massachusetts Medical
377 Plantation St, #334
Worcester
MA
1605

tomoko.tabuchi@umassmed.edu
960933
Takano
Syuichi
Dept Cellular/Structural Biol
UTHSCSA
7703 Floyd Curl Dr
San Antonio
TX
78240

takano@uthscsa.edu
961142
Talavera
Karla
Molec & Cell Biol
Univ California, Berkeley
16 Barker Hall
Berkeley
CA
94720

komarg@berkeley.edu
960667
Tam
Angela
Developmental Biology
Stanford University
279 Campus Drive West
Stanford
ca
94025

atytam@stanford.edu
960937
Tank
Elizabeth
Biochem and Biophys.
UCSF
600 16th Street
Genetech Hall S-314
San Francisco
CA
94143

elizabeth.tank@gmail.com
960746
Tecle
Eillen

Albert Einstein Col Med
1300 Morris Park Ave
Bronx
NY
10461

etecle@aecom.yu.edu
961138
Teuliere
Jerome
Molec & Cell Biol
Univ California, Berkeley
16 Barker Hall
Berkeley
CA
94720

jteuliere@berkeley.edu
960097
Thamsen
Maike
MCDB
University of Michigan
830 N. University
Ann Arbor
MI
48109

mthamsen@umich.edu
961264
Thomas
Emma

Buck Institute for Age Research
8001 Redwood Blvd.
Novato
CA
94945

ethomas@buckinstitute.org
960794
Thompson
Kenneth
Biological Sci
Univ MD Baltimore County
1000 Hilltop circle
Baltimore
MD
21250

kthomp1@umbc.edu
960261
Thompson-Peer
Katherine
Dept Molec Biol/ MGH
Harvard Medical Sch
185 Cambridge St, Simches 7
Boston
MA
2114

kpeer@hms.harvard.edu
960424
Tian
Chenxi
MBG
Cornell Univ


Ithaca
NY
14850

ct267@cornell.edu
960211
Timpano
Autumn
Biological Sciences
Virginia Tech University
1981 Kraft Drive, ILSB 2021
Blacksburg
VA
24061

aclapp@vt.edu
961540
Tiongson
Michael
Developmental Biology
Memorial Sloan-Kettering
430 East 67th Street
New York
NY
10065

tiongsom@mskcc.org
960714
Tissenbaum
Heidi
Prog Gene Function/Expression
Univ Massachusetts Med Sch
364 Plantation St, Lazare Bldg
Worcester
MA
1605

heidi.tissenbaum@umassmed.edu
961487
Topalidou
Irini

columbia university
1212 Amsterdam Ave
NY
NY
10027

it2117@columbia.edu
960743
Tornberg
Janne
Dept Molec Gen
Albert Einstein Col Med
1300 Morris Park Ave
Bronx
NY
10461

jtornber@aecom.yu.edu
960741
Townley
Robert
Genetics
Yeshiva University
1300 Morris Park Ave
New York
NY
10461

rtownley@aecom.yu.edu
960655
Troemel
Emily
Biol
UC-San Diego
9500 Gilman Dr
La Jolla
CA
92093-0349

etroemel@ucsd.edu
961556
Trzepacz
Chris
Dept Biological Sci
Murray State Univ
2112J Biology Bldg
Murray
KY
42071

chris.trzepacz@murraystate.edu
960147
Tsai
Hsin-Yue
Program in Molecular Medicine
University of Massachusetts Medical school
373 Plantation street
Worcester
MA
1605

HSINYUE.TSAI@umassmed.edu
960665
Tucci
Michelle
Dept Biological Sci
Univ Alabama
411 Hackberry Lane
Tuscaloosa
AL
35487

mtucci1@bama.ua.edu
960150
Tursun
Baris
Dept Biochemistry
Columbia Univ
701 W 168th St, HHSC 710
New York
NY
10032

bt2189@columbia.edu
961287
Twumasi-Boateng
Kwame
Graduate Group in Microbiology
UC Berkeley
Valley Life Sciences Bldg
Berkeley
CA
94720

kwametb@gmail.com
960784
Tzoneva
Monika
School of Molecular Biosciences
Washington State University
Pullman
WA
99164

mtzoneva@wsu.edu
960451
Tzur
Yonatan
Dept. of Genetics
Harvard Medical School
77 Ave Louis Pasteur, NRB-334
Boston
MA
2115

ytzur@genetics.med.harvard.edu
961160
Ulmschneider
Bryne
Biology
Oberlin College
119 Woodland Street
Oberlin
OH
44074

bryne.earthchild@gmail.com
960469
Updike
Dustin
MCD Biology
Univ California Santa Cruz
1156 High St

Santa Cruz
CA
95064

updike@biology.ucsc.edu
960787
Uzawa
Satoru
Dept MCB, HHMI
Univ California
16 Barker Hall, #3204
Berkeley
CA
94720-3204

satoru_u@berkeley.edu
961543
Vallier
Laura
Dept Biol
Hofstra Univ
114 Hofstra Univ
Hempstead
NY
11549

biolgv@hofstra.edu
960233
Van Auken
Kimberly
Div Biol, 156-29
California Inst Technology
1200 E California Blvd
Pasadena
CA
91125

vanauken@caltech.edu
960501
Van Buskirk
Cheryl
Div Biol
Caltech
1200 E California Blvd
156-29
Pasadena
CA
91125

cvb@caltech.edu
960296
van der Linden
Alexander
Dept Biol
Brandeis Univ
415 South St

Waltham
MA
2454

slinden@brandeis.edu
960958
Van Epps
Heather
Biology
Western Washington University
516 High St

Bellingham
WA
98225

heather.vanepps@wwu.edu
961520
Van Nostrand
Eric

Stanford University
437 Fremont Ave
Los Altos
CA
94024

ericvn@stanford.edu
961188
Van Wynsberghe
Priscilla
Dept Biol
UCSD
9500 Gilman Dr
La Jolla
CA
92093-0349

pvanwyns@ucsd.edu
960442
VanDuyn
Natalia
Pharmacology and Toxicology
Indiana Univ School of Medicin
635 Barnhill Drive, MS524
Indianapolis
IN
46202

nallee@iupui.edu
961380
VanHoven
Miri
Biological Sciences
San Jose State University
One Washington Square / DH-447
San Jose
CA
95192

miri.vanhoven@sjsu.edu
960295
Vantipalli
Maithili
Dept Research
Buck Inst
8001 Redwood Blvd
Novato
CA
94945

mvantipalli@buckinstitute.org
961187
Vargas
Marcus
Dept Genetics & Development
Columbia Univ
701 W 168th St
New York
NY
10032

mlv2101@columbia.edu
960648
Vasale
Jessica

University of  Massachusetts
373 Plantation St
Biotech 2, Suite 219
Worcester
MA
1605

jessica.vasale@umassmed.edu
960843
Vasquez
Valeria
Molecular and Cell Physiology
Stanford University
279 Campus Drive
Beckman Center B117
Stanford
CA
94305

vvr@stanford.edu
961009
Vatamaniuk
Olena
Dept Crop & Soil Sci
Cornell Univ
1028B Tower Rd
Ithaca
NY
14853

okv2@cornell.edu
961377
Venegas
Victor
Dept Biochem & Molec Biol
Baylor Col Medicine
One Baylor Plaza
Houston
TX
77030

vv139924@bcm.tmc.edu
961068
Venkatasamy
Balasubramani
Dept Biol
Uni California San Diego
9500 Gilman Dr
San Diego
CA
92093-0322

bvenkat@ucsd.edu
961411
Verheyden
Jamie

University of Wisconsin
433 Babcock

Madison
WI
53706

jmverhey@gmail.com
960386
Von Stetina
Stephen
Dept Oncology Sci
Huntsman Cancer Inst
2000 Circle Hope Dr
Salt Lake City
UT
84102

stephen.vonstetina@hci.utah.edu
961450
Vora
Mehul
Molecular Biol & Biochem
Rutgers Univ
604 Allison Road
Piscataway
NJ
8854

mehulv@dis.rutgers.edu
961346
Voronina
Ekaterina
Dept Molecular Biol & Genetics
Johns Hopkins SOM/HHMI
725 N Wolfe St, 706 PCTB
Baltimore
MD
21205

evoronina@jhmi.edu
960159
Vrablik
Tracy
Dept Biochemistry & Molec Biol
Pennsylvania State Univ
201 Life Sciences, 104D
University Park
PA
16802

tlv125@psu.edu
960217
Vuong
Edward

University of Rochester
601 Elmwood Ave
Rochester
NY
14623

edward_vuong@urmc.rochester.edu
960335
Wagner
Jamie

Oberlin College
135 W. Lorain St.
Oberlin
OH
44074

jamie.wagner@oberlin.edu
960236
Walker
Amy
Center for Cancer Research
MGH
149 13th St

Charlestown
MA
2129

amy_walker@mac.com
960343
Walston
Timothy
Dept Biol
Truman State Univ
100 E Normal St
Kirksville
MO
63501

tdwalston@truman.edu
960279
Walstrom
Katherine
Div Natural Sci
New Col Florida
5800 Bay Shore Rd
Sarasota
FL
34243-2109

kwalstrom@gmail.com
961269
Walton
Travis

Lewis & Clark College

Portland
OR
97219

walton@lclark.edu
960998
Wang
Han
GMCB
Zilkha Neurogenetic Institute
1501 San Pablo St ZNI321
Los Angeles
CA
90089

hanw@usc.edu
961353
Wang
Jennifer
Molec Biol & Gen
Johns Hopkins Univ / HHMI
725 N Wolfe St 706 PCTB
Baltimore
MD
21205

jwang110@jhmi.edu
960603
Wang
Jiou
Dept Genetics
Yale Sch Medicine
295 Congress Ave, BCMM 145
New Haven
CT
6511

jiou.wang@yale.edu
961420
Wang
John

University of Lausanne
5219 Redlands Drive
Hilliard
OH
43026

john.wang@unil.ch
961131
Wang
Meng
Molec Biol
Harvard Med Sch
185 Cambridge St CPZN-7250
Boston
MA
2114

mewang@molbio.mgh.harvard.edu
960324
Wang
Peng
NIDDK
NIH
8 Center Dr. B1-22
Bethesda
MD
20852

wangpeng@niddk.nih.gov
961475
Wang
Rencheng

MCDB Department
Univ. of Colorado at Boulder, MCDB, Han Lab, UCB 347
Boulder
CO
80309

rencheng.wang@colorado.edu
960227
Wang
Wenqing
BMB
Penn State University
103 Life Sciences Building
University Park
PA
16802

wzw111@psu.edu
960566
Wang
Xiaodong
Biol Div
Caltech
1200 E California Blvd
156-29
Pasadena
CA
91125

xdwang@caltech.edu
961124
Wang
Yi
Dept Gen
Albert Einstein College Med
1300 Morris Park Ullman 703
Bronx
NY
10461

yiwang@aecom.yu.edu
960398
Wang
Zhao-Wen
Dept Neuroscience
Univ Connecticut Health Ctr
263 Farmington Ave
Farmington
CT
06030-3401

zwwang@uchc.edu
960148
Wang
Zhiping
Division of Biological Science
UCSD
Rm 2429, 9500 Gilman Drive
La Jolla
CA
92093-0368

z4wang@ucsd.edu
961084
Wani
Khursheed
Biochemistry
Univ Massachusetts at Amherst
710 N. Pleasant St.
Amherst
MA
1002

kwani@mcb.umass.edu
960531
Warburton-Pitt
Simon
Dept Gen
Rutgers, The State Univ NJ
145 Bevier Rd
Piscataway
NJ
8854

swpitt@dls.rutgers.edu
960576
Ward
Alex
Dept Neuroscience
Univ Michigan
210 Washtenaw Ave
Ann Arbor
MI
48109

alexward@umich.edu
960434
Ward
Jordan

UCSF, Mission Bay Campus
600-16th St, Box 2280
San Francisco
CA
94158

jordan.ward@ucsf.edu
960311
Warnhoff
Kurt
Biol
Truman State Univ
100 East Normal St
Kirksville
MO
63501

kjw879@truman.edu
961559
Washington
Nicole
Dept Life Science
Lawrence Berkeley National Lab
1 Cyclotron Rd
MS64-121
Berkeley
CA
94720

nlwashington@lbl.gov
961521
Watkins
Kathie
Dept Cell & Developmental Biol
Vanderbilt Univ Sch Medicine
465 21st Ave S, 3154 MRBIII
Nashville
TN
37232-8240

kathie.l.watkins@vanderbilt.edu
960761
Watts
Jennifer
Sch Molec Biosci
Washington State Univ
Clark Hall 299
Pullman
WA
99164-6340

jwatts@wsu.edu
960809
Webster
Christopher

Washington State Univ
301 Abelson

Pullman
WA
99164

cwebster@wsu.edu
960481
Wehman
Ann
Skirball Inst
New York Univ
540 First Ave

New York
NY
10016

wehman@saturn.med.nyu.edu
960403
Wei
Qing
Molecular Biology
UMDNJ-SOM, GSBS
2 Medical Center Dr.
Stratford
NJ
8084

weiqi@umdnj.edu
960180
Wei
Qing
Department of Medicine
Mayo Clinic


Rochester
MN
55905

Wei.Qing@mayo.edu
960588
Wells
Michael
MCDB
University of  Michigan
830 N University
Ann Arbor
MI
48109

mbwells@umich.edu
961311
Whangbo
Jennifer
Pediatric Hematology/Oncology
Children's Hosp Boston
44 Binney St

Boston
MA
2115

jennifer.whangbo@childrens.harvard.edu
960224
Whetstine
Johnathan
Cancer Center and Medicine
Harvard and MGH
13th Street, Building 149, Rm-7103
Charlestown
MA
2129

jwhetstine@hms.harvard.edu
960505
Whittaker
Allyson
Dept Biol, HHMI
Caltech
1200 E California Blvd
156-29
Pasadena
CA
91125

awhitta@its.caltech.edu
961280
Wightman
Bruce
Biology Department
Muhlenberg College
2400 Chew St
Allentown
PA
18104

wightman@muhlenberg.edu
960610
Wignall
Sarah
Developmental Biology
Stanford University
279 Campus Drive
Stanford
CA
94305

swignall@stanford.edu
961252
Wilkinson
Deepti
MCB
BCM
1 Baylor Plz. Ms 230
Houston
TX
77030

deepti_srinivas@yahoo.com
961501
Williams
Corey
Dept Cell Biol
Univ Alabama at Birmingham
1918 MCLM, Rm 689
Birmingham
AL
35294

coreyw@uab.edu
960817
Williams
Daniel
Genetics
Yale University
295 Congress
New Haven
CT
6519

daniel.williams@yale.edu
961457
Williams
Travis
Life Sciences Institute
University of Michigan
210 Washtenaw Ave
Ann Arbor
MI
48109

twwillia@umich.edu
960830
Wilson
Kristy
Pathology
Emory University
615 Micheal St
Atlanta
GA
30322

kjwils2@emory.edu
960154
Winn
Jennifer


4600 Harry Hines  NA5.504
Dallas
TX
75390

jennifer.winn@utsouthwestern.edu
961134
Wojtyniak
Martin
Dept Molec & Cell Biol
Brandeis Univ
415 South St

Waltham
MA
2454

mwojtyni@brandeis.edu
960592
Wolff
Jennifer
BIology
Carleton College
1 N. College St.
Northfield
MN
55057

jwolff@carleton.edu
960666
Wolkow
Cathy
Lab Neurosciences
NIA, Biomedical Res Ctr
251 Bayview Blvd, #05C222
Baltimore
MD
21224

wolkowca@grc.nia.nih.gov
960754
Wollam
Joshua
Huffington Ctr Aging
Baylor Col Medicine
One Baylor Plaza
Houston
TX
77030

wollam@bcm.edu
960690
Wong
Ming-Ching
Dept Molec Biol
Princeton Univ
Washington Road
Princeton
NJ
8544

mingwong@princeton.edu
960732
Wood
Andrew
Molecular Cell Biology
UC Berkeley
16 Barker Hall
Berkeley
CA
94720

ajwood@berkeley.edu
960038
Wood
Jordan
Biological Sciences
University at Buffalo, SUNY

Buffalo
NY
14260

jfwood@buffalo.edu
960459
Wragg
Rachel
Dept Biological Sciences
Univ Toledo
2801 W Bancroft St
Toledo
OH
43606

rachelwragg@yahoo.co.uk
960940
Wu
Hsin-Yen
Biophys & Biochem
UCSF
600 16th Street
Room S314 Genentech Hall
San Francisco
CA
94158

hsinyenwu@gmail.com
960581
Wu
Jui-ching
Biology
San Francisco State Univ
1600 Holloway Ave
San Francisco
CA
94132

jcwu@sfsu.edu
960582
Wu
Tammy
Dept Biol
San Francisco State Univ
1600 Holloway Ave
San Francisco
CA
94132

tammy.wu.1@gmail.com
961231
Wu
Xiaoyun
Molecular Biology
Massachusetts General Hospital
185 Cambridge St.
CPZN-7250
Boston
MA
2114

wux@molbio.mgh.harvard.edu
960975
Wynne
David

Univ California, Berkeley
460 Stanley Hall MC 3220
Berkeley
CA
94720-3220

davewynne@berkeley.edu
960351
Xiao
Rui
Shawn Xu lab, Life Sci. Inst.
University of Michigan
210 Washtenaw Avenue
Ann Arbor
MI
48109

rxiao@umich.edu
961048
Xiong
Huajiang
Pathology
UMDNJ/RWJMS
675 Hoes Lane, Res Tower R
Piscataway
NJ
8854

xiongh1@umdnj.edu
961161
Xu
Meng
Dept Molec Gen
Albert Einstein Col Med
1300 Morris Park Ave, 703
Bronx
NY
10461

mxu@aecom.yu.edu
960326
Xu
Ningyi

Stowers Inst Med Res
1000 East 50th St
Kansas City
MO
64110

nxu@stowers.org
960560
Xu
Shawn
Life Sci Inst
Univ Michigan
210 Washtenaw Ave
Ann Arbor
MI
48109-2216

shawnxu@umich.edu
961509
Xu
Xiao
Dev Biol
Stanford Univ
279 Campus Dr
Stanford
CA
94305

xiaoxu@stanford.edu
961197
Xue
Ding
Dept MCD Biol
Univ Colorado
Campus Box 347
Boulder
CO
80309-0347

ding.xue@colorado.edu
960939
Yamawaki
Tracy
Dept Biochemistry
Univ California, San Francisco
600 16th St

San Francisco
CA
94143

tracy.yamawaki@ucsf.edu
960488
Yan
Bo
Genetics
Dartmouth College
7400 Remsen
Hanover
NH
3755

bo.yan@dartmouth.edu
960804
Yan
Dong


9505 Genesee Ave unit 511
San Diego
CA
92121

yandongdong@gmail.com
960771
Yan
Zhi

UCSD
9500 Gilman Dr. #0349
La Jolla
CA
92093

z2yan@ucsd.edu
960327
Yang
Huan

Stowers Inst Med Res
1000 East 50th St
Kansas City
MO
64110

huy@stowers.org
961129
Yang
Youfeng

Univ Alabama at Birmingham
Birmingham
AL
35205

yangyoufeng@gmail.com
961391
Yanik
Mehmet
EECS/RLE
MIT
77 Massachusetts Ave
36-834
Cambridge
MA
2139

yanik@mit.edu
961198
Yanowitz
Judith
Dept Embryology
Carnegie Inst Washington
3520 San Martin Dr
Baltimore
MD
21218

yanowitz@ciwemb.edu
960991
Yee
Michael
Biology
San Francisco State University
743 Gellert Blvd.
Daly City
CA
94015

mikecyee@gmail.com
960258
Yen
Kelvin
PGFE
UMass Med
45 E. Newton St #701
Boston
MA
2118

kelvin@kyen.org
960883
Yeshi
Tseten
Dept Biol
Univ Kentucky
Rose St

Lexington
KY
40506

tgyeshi@uky.edu
961497
Yin
Jianghua
Dept Biol
Queens Col, CUNY
65-30 Kissena Blvd
Flushing
NY
11367

jianghua.yin@qc.cuny.edu
960504
Yook
Karen
Div Biol, 156-29
California Inst Technology
1200 E California Blvd
15629
Pasadena
CA
91125

kyook@caltech.edu
960184
You
Young-jai
Dept Molecular Biol
Univ Texas SW Medical Ctr
6000 Harry Hines Blvd
Dallas
TX
75390

young@eatworms.swmed.edu
961123
Youngman
Matthew
Dept Biol
MIT
77 Massachusetts Ave, 68-430
Cambridge
MA
2139

mjyoungman@yahoo.com
961153
Yu
Szi-Chieh
Biology
University of Illinois Chicago
840 W Taylor

Chicago
IL
60607

syu27@uic.edu
960115
Yu
Weiqun
Physiology
University of Pennsylvania
3700 Hamilton Walk
Philadelphia
PA
19104

weiqunyu@mail.med.upenn.edu
961091
Yuan
Yiyuan
Pharmacology
school of medicine
10900 Euclid Ave
cleveland
OH
44106

yiyuan.yuan@case.edu
960361
Zaaijer
Sophie
Genetics Department
Harvard Medical School
77 Ave Louis Pasteur, NRB-334
Boston
MA
2115

szaaijer@genetics.med.harvard.edu
961240
Zand
Tanya
Dept Pharmacology
Univ North Carolina
CB #7295

Chapel Hill
NC
27599

tzand@med.unc.edu
960686
Zarkower
David
Dept GCD, 6-160 Jackson Hall
Univ Minnesota
321 Church St, SE
Minneapolis
MN
55455

zarko001@umn.edu
960134
Zaslaver
Alon
Dept Biol
Caltech
1200 E California Blvd
Pasadena
CA
91125

alonzo@caltech.edu
961360
Zehner
Tiffany
Biology Department
Muhlenberg College
2400 Chew St.
Allentown
PA
18104

TZ234481@gws3.muhlenberg.edu
960480
Zeiger
Danna
Biology
Brandeis University
12 Regent St. Apt 1F
Cambridge
MA
2140

danna@brandeis.edu
960323
Zhan
Haiying
Neuroscience
Univ Connecticut Hlth Ctr
263 Farmington Ave
Farmington
CT
6032

hzhan@student.uchc.edu
961375
Zhang
Chi
Dept Molec Biol
Massachusetts General Hosp
185 Cambridge St, CPZN 7250
Boston
MA
2114

czhang@molbio.mgh.harvard.edu
960853
Zhang
Donglei

Rutgers Univ
190 Frelinghuysen Road
Piscataway
NJ
8854

donglei@eden.rutgers.edu
960244
Zhang
Feifan
Biological Sciences
Columbia University
701 West 168th ST
HHSC/7th Floor
New York
NY
10032

fz2124@columbia.edu
960149
Zhang
Peichuan
Dept Biochem & Biophysics
Univ California, San Francisco
600 16th St.MBGH, Rm S314
San Francisco
CA
94158

peichuan.zhang@ucsf.edu
961284
Zhang
Sihui
Biological Sci
Virginia Polytechnic Inst
1981 Kraft Dr

Blacksburg
VA
24061

sihuiz07@vt.edu
960669
Zhang
Weibin

Stanford University
279 Campus Dr B311
Stanford
CA
94040

weibinz@stanford.edu
960510
Zhang
Xiaodong

Harvard University
52 Oxford St

Cambridge
MA
2138

xzhang@fas.harvard.edu
961529
Zhang
Yinhua

New England Biolabs
240 County Rd
Ipswich
MA
1938

zhangy@neb.com
960790
Zhao
Zhongying
Dept Genome Sci
Univ Washington
1705 Pacific St
355065
Seattle
WA
98195

zhao@gs.washington.edu
960454
Zheng
Genhua
cell biology and biochemistry
UT Southwestern Medical Center
5323 Harry Hines Blvd
Dallas
TX
75390

genhua.zheng@UTSouthwestern.edu
961143
Zheng
Qun
Anatomy & Neurobiology
Washington Univ
660 S Euclid Ave
Saint Louis
MO
63110

zheng@pcg.wustl.edu
961382
Zhong
Jing
CMDB Program
UC Riverside
APT 26, 200 W Big Springs Rd.
Riverside
CA
92507

jzhon002@student.ucr.edu
960495
Zhong
Weiwei
Biochem & Cell Biol
Rice Univ
6100 Main St.; MS140 GBH W200i
Houston
TX
77005

weiwei.zhong@rice.edu
961399
Zhou
Hongkang
Biology
San Francisco State University
1600 Holloway Avenue
San Francisco
CA
94132

zhk209@sfsu.edu
960213
Zhou
Kang
Biochemistry Molecular Biology
Pennsylvania State University
103 Life Science Building
University Park
PA
16802

kuz107@psu.edu
961071
Zhou
Qinghua
MCDB
Univ Colorado
MCDB UCB347
Boulder
CO
80309

zhouqh03@gmail.com
960401
Zhou
Shan

Univ Minnesota
321 Church St. SE
Minneapolis
MN
55108

zhoux095@umn.edu
960859
Zhou
Zheng
Dept Biochem & Molec Biol
Baylor Col Med
One Baylor Plaza
Houston
TX
77030

zhengz@bcm.tmc.edu
960219
Zisoulis
Dimitrios
Biology, MC 0349
UCSD
9500 Gilman Dr
La Jolla
CA
92093

dzisoulis@ucsd.edu
960131
Zonies
Seth
Dept Molecular Biol & Genetics
Johns Hopkins Medical Sch
725 N Wolfe St
Baltimore
MD
21205

zonies@jhmi.edu
960026
Behm
Carolyn
School of Biology
Australian National Univ
Bldg 41

Canberra
ACT
200
Australia
carolyn.behm@anu.edu.au
960858
Boag
Peter
Biochemistry & Molecular Biology
Monash University
Wellington Road
Clayton
Victoria
3800
Australia
peter.boag@med.monash.edu.au
961416
Ebert
Paul
Biological Sciences
University of Queensland
Chancellor's Place
St Lucia
Queensland
4072
Australia
p.ebert@uq.edu.au
960915
Fritz
Julie-Anne
Biology and Molecular Biology
Australian National University
Blg 41, Linnaeus Way, ACTON
Canberra

200
Australia
julie-anne.fritz@anu.edu.au
960547
Hilliard
Massimo
Queensland Brain Institute
The University of Queensland
Upland Rd, Bldg. #79
Brisbane

4072
Australia
m.hilliard@uq.edu.au
960604
Kirszenblat
Leonie

Queensland Brain Institute
Upland Road, St Lucia
Brisbane

4072
Australia
l.kirszenblat@uq.edu.au
960164
Neumann
Brent
Queensland Brain Institute
University of Queenland
Building 79, Upland Rd
St Lucia
Brisbane

4072
Australia
b.neumann@uq.edu.au
961002
Nicholas
Hannah
Sch MMB
Univ Sydney
Maze Cres

Sydney

2006
Australia
h.nicholas@usyd.edu.au
960863
Valmas
Nicholas

Queensland Brain Institute
Upland Road

Brisbane
Queensland
4072
Australia
nick.valmas@gmail.com
960069
Yucel
Duygu
School of Molecular and Microbial Biosciences
University of Sydney
Building G08

Sydney
NSW
2006
Australia
dyuc2466@usyd.edu.au
960317
Reiter
Silke

IMP
Dr. Bohr-Gasse
Vienna

1030
Austria
silke.reiter@imp.ac.at
960318
Sanegre Sans
Sabina

Res Inst Molec Pathology
Dr. Bohr-Gasse
Vienna

1030
Austria
sabina.sanegre@imp.ac.at
960092
Braeckman
Bart
Biology Department
Ghent University
K.L.Ledeganckstraat 35
Ghent

9000
Belgium
Bart.Braeckman@UGent.be
960090
De Henau
Sasha
Biology Department
Ghent University
K.L.Ledeganckstraat 35
Ghent

9000
Belgium
Sasha.DeHenau@UGent.be
960091
Depuydt
Geert
Biology Department
Ghent University
K.L.Ledeganckstraat 35
Ghent

9000
Belgium
Geert.Depuydt@UGent.be
960467
Husson
Steven

K.U.Leuven/Goethe-Univ Frankfurt
Leuven/Frankfurt
3000
Belgium
steven.husson@bio.kuleuven.be
960041
Meelkop
Ellen

K.U.Leuven
naamsestraat 59
leuven
vlaams-brabant
3000
Belgium
ellen.meelkop@bio.kuleuven.be
960040
Temmerman
Liesbet

K.U.Leuven
Naamsestraat 59
Leuven

3000
Belgium
liesbet.temmerman@bio.kuleuven.be
960280
Ardiel
Evan
Dept Psychology
Univ British Columbia
2136 West Mall
Vancouver
BC
V6T 1Z4
Canada
eardiel@interchange.ubc.ca
960702
Babadi
Nasrin
Dept Neuroscience
Univ Ottawa
451 Smyth Rd, Rm 1454
Ottawa
ON
K1H 8M5
Canada
nhabi102@uottawa.ca
960379
Bossé
Gabriel


9 rue McMahon
Québec
Québec
G1R 2J6
Canada
gabrielbosse@hotmail.com
961273
Brisbin
Sarah
Dept Biol
Queen's Univ
116 Barrie

Kingston
ON
K7L 3N6
Canada
sarah.brisbin@queensu.ca
960558
Chartier
Nicolas
Institute for Research in Immunology and Cancer
Université de Montréal
C.P 6128 succ. centre ville
Montréal
Québec
H3C 3J7
Canada
nicolas.chartier@umontreal.ca
960990
Chen
Nansheng
Dept Molec Biol, Biochem
Simon Fraser Univ
8888 Univ Dr

Burnaby
BC
V5A 1S6
Canada
chenn@sfu.ca
960574
Cheng
Phil
Experimental Medicine
McGill Univ
H7 67, 687 Pine Ave W
Montreal
PQ
H3A 1A1
Canada
phil.cheng@mail.mcgill.ca
961271
Chin-Sang
Ian
Dept Biol
Queen's Univ
116 Barrie St

Kingston
ON
K7L 3N6
Canada
chinsang@queensu.ca
960596
Chotard
Laetitia
Dept Medicine
McGill Univ
687 Pine Ave W
Montreal
PQ
H3A 1A1
Canada
laetitia.chotard@mail.mcgill.ca
960829
Chu
Jeffrey
Dept MBB
SFU
8888 University Dr
Burnaby
BC
V5A 1S6
Canada
jeff.sc.chu@gmail.com
960672
Croydon-Sugarman
Melanie

University of Toronto
133 HIGH PARK AVENUE
TORONTO
ONTARIO
M6P 2S3
Canada
m.croydon.sugarman@utoronto.ca
960443
Cumbo
Philip
Biology
McMaster University
1280 Main St. W
Hamilton
Ontario
L8S4K1
Canada
cumbop@mcmaster.ca
960479
Cutter
Asher
Dept Ecology/Evolutionary Biol
Univ Toronto
25 Willcocks St, Toronto
Toronto
ON
M5S 3B2
Canada
asher.cutter@utoronto.ca
961190
Dent
Joseph
Dept Biol
McGill Univ
1205 Dr Penfield Ave
Montreal
PQ
H3A 1B1
Canada
joseph.dent@mcgill.ca
961476
Duchaine
Thomas
Biochem./Goodman Cancer Centre
McGill University
1160 Avenue des pins West
Montreal
Qc
H3A 1A3
Canada
thomas.duchaine@mcgill.ca
960058
Edgley
Mark
Life Sci Ctr
Univ British Columbia
1340A-2350 Health Science Mall
Vancouver
BC
V6T 1Z3
Canada
edgley@interchange.ubc.ca
961563
Farris
Lily
Zoology/Ctr Applied Ethics
UBC
227-6356 Agricultural Rd
Vancouver
BC
V6T 1Z2
Canada
lfarris@interchange.ubc.ca
961196
Flibotte
Stephane
Genome Sciences Centre
BC Cancer Research Centre
570 West 7th Avenue
Vancouver
BC
V5Z 4S6
Canada
sflibotte@bcgsc.ca
960486
Frederic
Melissa
Mol Biology and Biochemistry
Simon Fraser University
8888 University Drive
Burnaby
B C
V5A 1S6
Canada
mfa34@sfu.ca
960906
Gallo
Marco
Medical Genetics
University of British Columbia
263-2185 East Mall
Vancouver
BC
V6T 1Z4
Canada
mgallo@interchange.ubc.ca
960618
Gao
Shangbang

Samuel Lunenfeld Research Inst.
30 Charles Street West
Toronto
ontario
M4Y 1R5
Canada
gao@mshri.on.ca
961389
Gaudet
Jeb
Dept Biochem & Molec Biol
Univ Calgary
3330 Hosp Dr, NW
Calgary
AB
T2N 4N1
Canada
gaudetj@ucalgary.ca
961151
Ghai
Vikas
Dept Genes & Development
Univ Calgary
3330 Hosp Dr NW
Calgary
AB
T2N 4N1
Canada
vghai@ucalgary.ca
960108
Han
Xue
Biological Sciences
Univ of Alberta
11455 Saskatchewan Drive
Edmonton
AB
T6G 2E9
Canada
xue.han@ualberta.ca
960380
Hansen
David
Dept Biological Sci
Univ Calgary


Calgary
AB
T2N 1N4
Canada
dhansen@ucalgary.ca
961025
Harel
Sharon
Chemistry
UQAM
POBOX8888, Succ. Centre-ville
Montreal
quebec
H3C 3P8
Canada
sharon.harel@gmail.com
961027
Hawkins
Nancy
Dept Molec Biol & Biochem
Simon Fraser Univ
8888 Univ Dr

Burnaby
BC
V5A 1S6
Canada
nhawkins@sfu.ca
961031
Hingwing
Kyla
Dept Molecular Biology & Biochem
Simon Fraser Univeristiy
8888 University Dr.
Burnaby
BC
V5A 1S6
Canada
krhingwi@sfu.ca
960908
Hutter
Harald
Biol Sci
Simon Fraser Univ
8888 University Dr
Burnaby
BC
V3B6L6
Canada
hutter@sfu.ca
961021
Jenna
Sarah
Chemistry
UQAM
PObox 8888, Succ. Centre ville
Montreal
quebec
H3C 3P8
Canada
jenna.sarah@uqam.ca
960675
Jensen
Victor
Dept Medical Genetics
Univ British Columbia
2185 East Mall, MSB Bldg
Vancouver
BC
V6T 1Z3
Canada
vjensen@interchange.ubc.ca
960597
Johnson
Cheryl
Dept Molecula Genetics
Univ Toronto
1 King's College Circle
Toronto
ON
M5S 1A8
Canada
cheryllynn.johnson@utoronto.ca
960595
Johnson
Jacque-Lynne
Dept Molec Biol & Biochem
Simon Fraser Univ
8888 Univ Dr

Burnaby
BC
V5A 1S6
Canada
jlfjohns@hotmail.com
961478
Kawano
Takehiro
Rm875/Research
Mount Sinai Hospital
600 University Ave
Toronto
ON
M5G 1X5
Canada
kawano@lunenfeld.ca
960207
Killeen
Marie
Dept Chemistry & Biol
Ryerson Univ
350 Victoria St
Toronto
ON
M5B 2K3
Canada
mkilleen@ryerson.ca
961465
Koon
Janet
Dept Biol
York Univ
4700 Keele St
Toronto
ON
M3J 1P3
Canada
jk_2002@yorku.ca
961461
Kubiseski
Terry
Biology
York University
4700 Keele St
Toronto
ON
M3J 1P3
Canada
tkubises@yorku.ca
961115
Labella
Sara
Biol
McGill Univ
1205 Ave Dr Penfield
Montreal
PQ
H3A1B1
Canada
sara.labella@mail.mcgill.ca
960555
Lamarche
Julie

CR-CHUM
Sherbrooke

Montreal
Quebec
H2L 4M1
Canada
julie.demers-lamarche@umontreal.ca
960106
Lange
Karen

University of Alberta
7238-112 Street NW
Edmonton
AB
T6G 1J3
Canada
klange@ualberta.ca
960266
Lao
Nhien

University of Calgary
2316, 9 Avenue NW, Calgary
Calgary
Alberta
T2N 1E7
Canada
laom@tcd.ie
961397
Lau
H.
Neuroscience
Univ British Columbia
5428 Monte Bre Place
Vancouver
BC
V7W3A8
Canada
leel@interchange.ubc.ca
961502
Law
Ka-Lun

McGill University
1205 Ave Dr Penfield
Montreal

H3A 1B1
Canada
ka.law@mail.mcgill.ca
960355
Lee
Anna
McGill Ctr Bioinformatics
McGill Univ
Bellini Building, Rm. 433, 3649 Promenade Sir William Osler
Montréal
Quebec
H3A 0B1
Canada
anna@mcb.mcgill.ca
960706
Leroux
Michel
Dept Molec Biol & Biochemistry
Simon Fraser Univ
8888 University Dr
Burnaby
BC
V5A 1S6
Canada
leroux@sfu.ca
960580
Lin
Conny
Brain Research Ctr
Univ British Columbia
2211 Wesbrook Mall
Vancouver
BC
V6T 2B5
Canada
conny@interchange.ubc.ca
960916
Logan
Brittany

University of Calgary
3330 Hospital Drive NW
Calgary
Alberta
T3L2P2
Canada
bclogan@ucalgary.ca
961335
Lu
Yu
Dept Biol
McGill Univ
Dr Penfield 1205
Montreal
PQ
H3A 1B1
Canada
yu.lu4@mail.mcgill.ca
960185
MacDonald
Lindsay
Dept Biological Sci
Univ Calgary
2500 University Dr
Calgary
AB
T2N 1N4
Canada
macdonld@ucalgary.ca
960433
Mains
Paul
Dept Biochem & Molec Biol
Univ Calgary
3330 Hosp Dr, NW
Calgary
AB
T2N 4N1
Canada
mains@ucalgary.ca
961336
Mantovani
Julie


1205 Dr Penfield Avenue
Montreal
Quebec
H3A1B1
Canada
julie.mantovani@mcgill.ca
960999
Marcus
Nancy
Dept Molec Biol & Biochemistry
Trinity Western Univ
7600 Glover Rd
Langley
BC
V2Y 1Y1
Canada
nmarcus@sfu.ca
960700
McGhee
James
Dept Biochemistry & Molec Biol
Univ Calgary
3330 Hospital Dr NW
Calgary
AB
T2N 4N1
Canada
jmcghee@ucalgary.ca
960689
Moerman
Donald
Zoology
University of British Columbia
2350 Health Sciences Mall
Vancouver
B.C.
V4K 2R3
Canada
moerman@zoology.ubc.ca
960961
Mok
Calvin
Prog Gen & Genome Biol
Sick Kids Hosp
101 College St, TMDT 15-601B
Toronto
ON
M5G 1L7
Canada
calvin.mok@utoronto.ca
960449
Nguyen
Phuong
MBB
SFU
8888 University Dr.
Burnaby
BC
V5A 1S6
Canada
tpn3@sfu.ca
960764
Park
Donha
Michael Smith Laboratories
Univ British Columbia
2185 East Mall
Vancouver
BC
V6T 1Z4
Canada
dhpark@interchange.ubc.ca
960447
Parker
Alex
Pathology and Cell Biology
CRCHUM, Univesite de Montreal
1560 rue Sherbrooke Est
M-5226
Montreal
QC
H2L 4M1
Canada
ja.parker@umontreal.ca
960731
Perkins
Jaryn
Michael Smith Laboratories
Univ British Columbia
2350 Health Sciences Mall
Vancouver
BC
V6T 1Z3
Canada
jaryn@interchange.ubc.ca
960611
Piekny
Alisa
Biology
Concordia University
7141 Sherbrooke St. W
SP-437.15
Montreal
Quebec
H4B 1R6
Canada
apiekny@alcor.concordia.ca
960658
Pilgrim
David
Dept Biological Sciences
University of Alberta
CW405 Biological Sci Bldg
Edmonton
AB
T6G 2E9
Canada
dave.pilgrim@ualberta.ca
961541
Plummer
Jasmine
Dept Molecular Genetics
Samuel Lunenfeld Res Inst
600 Univ Ave, Rm 875
Toronto
ON
M5G 1X5
Canada
jasmine.plummer@utoronto.ca
960659
Prasad
Anisha

University of Toronto
54 shadberry drive
Toronto

M2H 3C8
Canada
anisha.prasad@utoronto.ca
961113
Quan
Yvonne
Biology
McGill Univ
1205 Ave Dr Penfield
Montreal
PQ
H3A1B1
Canada
ton-yee.quan@mail.mcgill.ca
960564
Rabilotta
Alexia
Inst. Res. Immunol. Cancer
Universite de Montreal
C.P. 6128, Succ Centre-ville
Montreal
QC
H3C 3J7
Canada
alexia.rabilotta-faure@umontreal.ca
960102
Racher
Hilary
Biological Sciences
University of Calgary
2500 University Drive N.W.
Calgary
AB
T3B0C2
Canada
hleivo@ucalgary.ca
961000
Ramsay
Laura

Simon Fraser Univ

Burnaby
BC
V2Y 1Y1
Canada
lfr@sfu.ca
960225
Rankin
Catharine
Dept Psychology
Univ British Columbia
2136 West Mall
Vancouver
BC
V6T 1Z4
Canada
crankin@psych.ubc.ca
961383
Riddle
Donald
Michael Smith Lab
Univ British Columbia
2185 East Mall
Vancouver
BC
V6T 1Z4
Canada
driddle@msl.ubc.ca
960602
Rocheleau
Christian
Dept Med
McGill Univ
687 Pine Ave W
Montreal
PQ
H3A 1A1
Canada
christian.rocheleau@mcgill.ca
961464
Rocheleau
Simon

University of Calgary
Calla Donna pl.
Calgary
Alberta
t2v2r2
Canada
skrochel@ucalgary.ca
960635
Rohs
Patty

Univ Calgary
Maplecrest Rd.
Calgary
AB
T2J 1X9
Canada
prohs@ucalgary.ca
960018
Ross
Ashley
Molecular Genetics
University of Toronto
101 College Street
Toronto Medical Discovery Tower
Toronto
Ontario
M5G 1L7
Canada
ashley.ross@utoronto.ca
960562
Salazar
Diana
Inst. Res. Immunol. Cancer
Universite de Montreal
C.P. 6128, Succ Centre-ville
Montreal
QC
H3C3J7
Canada
dpauline00@yahoo.com
960093
Sanchez Alvarez
Leticia
Dept Neurosci
Univ Ottawa
451 Smyth Rd
Ottawa
ON
K1H 8M5
Canada
leticiasa@yahoo.com
961286
Shah
Sitar
Health Sciences
University of Calgary
#2210, 3330 Hospital Dr. NW
Calgary
AB
T2N 4N1
Canada
sshah@ucalgary.ca
960630
Simard
Martin
Cancer Res Ctr
Laval Univ
9 McMahon

Quebec City
PQ
G1R 2J6
Canada
martin.simard@crhdq.ulaval.ca
961026
Smit
Ryan
Dept Biochem & Molec Biol
Univ Calgary
3330 Hospital Dr NW
Calgary
AB
T2N 4N1
Canada
rbsmit@ucalgary.ca
961238
Spence
Andrew
Dept Molec Gen
Univ Toronto
1 King's College Circle
Toronto
ON
M5S 1A8
Canada
andrew.spence@utoronto.ca
960062
Srayko
Martin
Biological Sciences
University of Alberta
CW405 Biological Sciences Bldg
Edmonton
AB
T6G 2E9
Canada
srayko@ualberta.ca
961347
St-Francois
Christopher
Biology
Mcgill
1205 Dr.Penfield
montreal
Quebec
H3A1B1
Canada
christopher.st-francois@mail.mcgill.ca
960455
Steimel
Andreas
Biological Sciences
Simon Fraser University
8888 University Drive
Burnaby
BC
V5A1S6
Canada
andreass@sfu.ca
961444
Suo
Satoshi

Samuel Lunenfeld Res Inst
600 Univ Ave

Toronto
ON
M5G 1X5
Canada
satoshi.suo@utoronto.ca
960856
Tarailo
Sanja

Univ British Columbia
2125 East Mall
Vancouver
BC
V6T1Z4
Canada
sanjat@interchange.ubc.ca
960855
Tarailo-Graovac
Maja

Simon Fraser Univ
8888 University Drive
Burnaby

V5A1S6
Canada
mta57@sfu.ca
960151
Taubert
Stefan
Medical Genetics
UBC/CMMT
950 West 28th Ave, Room 3018
Vancouver
BC
V5Z 4H4
Canada
taubert@cmmt.ubc.ca
960878
Tauffenberger
Arnaud
Pathologie et Biol cellulaire
Univ de Montreal

Montreal
PQ
H2L 4M1
Canada
arnaud.tauffenberger@umontreal.ca
960161
Timbers
Tiffany
Brain Research Centre
University of British Columbia
2211 Wesbrook Mall
Vancouver
British Columbia
V6T2B5
Canada
ttimbers@interchange.ubc.ca
961288
Vanneste
Christopher
Dept BMB, HSC, Rm 2210
Univ Calgary
3330 Hospital Dr, NW
Calgary
AB
T2N 4N1
Canada
cavannes@ucalgary.ca
960880
Vergara
Ismael
Molec Biol & Biochem
Simon Fraser Univ
8888 University Drive
Burnaby
BC
V3J1W2
Canada
iav@sfu.ca
961169
Verster
Adrian
Molec Gen
Univ Toronto
160 College St.
Toronto
Ontario
M5S 3E1
Canada
adrian.verster@utoronto.ca
960693
Viveiros
Ryan
Dept Zoology
Univ British Columbia
2350 Health Sciences Mall
Vancouver
BC
V6T 1Z3
Canada
viveiros@interchange.ubc.ca
960047
Wang
Christopher
Dept Biological Sci
Univ Calgary
2500 University Dr, NW
Calgary
AB
T2N 1N4
Canada
clcwwang@ucalgary.ca
961242
Wannissorn
Nattha
Molec Gen
Univ Toronto
College St

Toronto
Toronto
M5S3E1
Canada
nattha.wannissorn@utoronto.ca
960692
Warner
Adam
Zoology - Moerman Lab
Univ British Columbia
2350 Health Sciences Mall
Vancouver
BC
V6T 1Z3
Canada
warner@zoology.ubc.ca
961330
Wendland
Emily
Biology
McGill University
1205 Dr. Penfield Ave
Montreal
Quebec
H3A1B1
Canada
emily-marie.wendland@mail.mcgill.ca
961255
Wever
Claudia

McGill University
1205 Dr. Penfield Ave
Montreal
Quebec
H3A 1B1
Canada
claudia.wever@mail.mcgill.ca
961101
Wu
Edlyn
Dept Biochem
McGill Univ
1160 Pine Ave West Room 403
Montreal
PQ
H3A 1A3
Canada
edlyn.wu@mail.mcgill.ca
960954
Zetka
Monique
Dept Biol
McGill Univ
1205 Ave Docteur Penfield
Montreal
PQ
H3A 1B1
Canada
monique.zetka@mcgill.ca
961495
Zhang
Yuqian
Dept Biol
York Univ
4700 Keele St
Toronto
ON
M3J 1P3
Canada
jyzhang@yorku.ca
960048
Zhao
Xuan
Dept. of Biological Sciences
University of Calgary
2500 University Drive
Calgary
AB
T2N 1N4
Canada
xuazhao@ucalgary.ca
960013
Chen
Didi

IGDB,CAS
Da Tun

Beijing

100101
China
ddchen@genetics.ac.cn
960578
Dong
Meng-Qiu

NIBS, Beijing
7 Science Park Road
Beijing

1022206
China
dongmengqiu@nibs.ac.cn
960738
Jiang
Xinnong
Biology
Huazhong Univ of Sci & Tech
1037 Luoyu Road
College of Life Sci & Tech Rm308
Wuhan
Hubei
430074
China
jiangxn88@mail.hust.edu.cn
960739
Liu
Jianfeng
Dept. of Biology
Huazhong Univ of Sci & Tech
1037 Luoyu Road
College of Life Sci & Tech Rm315
Wuhan
Hubei
430074
China
jfliu@mail.hust.edu.cn
960006
Wang
Xiaochen

NIBS
7 Sciences Park Rd
Beijing

102206
China
wangxiaochen@nibs.ac.cn
960009
Yang
Chonglin
Center for Developmental Biology
Inst. of Gen. and Dev., CAS
Datun Road, Chaoyang District
Beijing
Beijing
100101
China
clyang@genetics.ac.cn
960287
Zhang
Hong

NIBS, Beijing
No 7 Science Park Rd
Beijing

102206
China
zhanghong@nibs.ac.cn
961037
Asahina
Masako
Inst Parasitology
Biology Centre, ASCR
Branisovska 31
Ceske Budejovic
CZ-37005
Czech Republic
masako@paru.cas.cz
960543
Kostrouch
David
Inst Inherited Metab Disorders
Charles Univ
Ke Karlovu 2

Prague

12801
Czech Republic
david.kostrouch@lfl.cuni.cz
960464
Kostrouch
Zdenek
Inst Inherited Metab Disease
Charles Univ
Ke Karlovu 2

Prague 2

128 00
Czech Republic
zdenek.kostrouch@lf1.cuni.cz
960541
Kostrouchova
Marketa
Inst Inherited Metab Disorders
Charles Univ
Ke Karlovu 2

Prague

12801
Czech Republic
marketa.kostrouchova@lf1.cuni.cz
960463
Kostrouchova
Marta
Inst Inherited Metabolic Dis
Charles Univ
Ke Karlovu 2

Prague 2

128-01
Czech Republic
marta.kostrouchova@lf1.cuni.cz
960546
Machalova
Eliska

Inst Inherited Metab Disorders
Ke Karlovu 2

Prague

12801
Czech Republic
eliska.machalova@lf1.cuni.cz
960542
Mikolas
Pavol
Inst Inherited Metab Disorders
Charles Univ
Ke Karlovu 2

Prague

12801
Czech Republic
pavol.mikolas@lfl.cuni.cz
960545
Nakielna
Johana
Inst inherited metab disorders
Charles University
Ke Karlovu 2

Prague

12801
Czech Republic
johana.nakielna@lf1.cuni.cz
960544
Sebkova
Katerina
Inst Inherited Metab Disorders
First Fac Med, Charles Univ
Ke Karlovu 2

Prague 2

121 08
Czech Republic
katerina.sebkova@lf1.cuni.cz
960893
Vozdek
Roman
Inst Inherited Metab Disease
Charles Univ
Ke Karlovu 2

Prague 2

12808
Czech Republic
roman.vozdek@lf1.cuni.cz
961219
Brejning
Jeanette
Dep Molec Biol
Univ Aarhus
Gustav Wieds Vej 10
Aarhus C

8000
Denmark
jb@mb.au.dk
961215
Jakobsen
Helle
Molec Biol
Univ Aarhus
Gustav Wieds Vej 10
Aarhus C

8000
Denmark
hej@mb.au.dk
961220
Jensen
Louise
Dep Molec Biol
Aarhus Univ
Gustav Wieds Vej 10C
Aarhus C

8000
Denmark
ltj@mb.au.dk
961214
Olsen
Anders
Molec Biol
Univ Aarhus
Gustav Wieds Vej 10C
Aarhus

8000
Denmark
ano@mb.au.dk
961537
Salcini
Lisa

BRIC, University of Copenhagen
Ole Maaløes vej 5
Copenhagen
Copenhagen
2200
Denmark
lisa.salcini@bric.dk
961216
Scholer
Lone
Dept Molec Biol
Aarhus Univ
Gustav Wieds vej 10
Aarhus C

DK-8000
Denmark
lvs@mb.au.dk
960677
Simonsen
Karina
Dept BMB
Univ Southern Denmark
Campusvej 55
Odense M

5230
Denmark
karinats@bmb.sdu.dk
961218
Sivapatham
Renuka
Dept Molec Biol
Aarhus Univeristy
Gustav Wieds vej 10
Aarhus

DK/8000
Denmark
res@mb.au.dk
960584
Hamer
Geert
Molec & Cancer Biol Program
Inst BioMed, Univ Helsinki
Haartmaninkatu 8
Helsinki

FIN-00014
Finland
geert.hamer@helsinki.fi
960981
Jin
CongYu
Molec Cancer Biol Program
Univ Helsinki
Biomedicum Helsinki (Haartmaninkatu 8)
POB 63
Helsinki

FIN-00014
Finland
congyu.jin@helsinki.fi
961301
Wong
Garry
Dept Biosciences
Kuopio Univ
PO Box 1627

Kuopio

70211
Finland
garry.wong@uku.fi
960303
Bellanger
Jean-Michel

CRBM-CNRS
1919 Route de Mende
Montpellier

34293
France
jean-michel.bellanger@crbm.cnrs.fr
960773
Braendle
Christian
Inst Dev Biol & Cancer
CNRS, Univ Nice
Parc Valrose

Nice
NICE
6102
France
braendle@unice.fr
960430
Burger
Julien
Development
Institut Jacques Monod, CNRS
Bâtiment Buffon 15 rue Hélène
Paris

75205
France
burger.julien@ijm.jussieu.fr
960521
Culetto
Emmanuel
Ctr de Genetique Moleculair
Univ de Paris-Sud
Ave de la Terasse
Gif-sur-Yvette
91198
France
emmanuel.culetto@u-psud.fr
960059
Descamps
Simon
CRBM
CNRS UMR 5237
1919 Route De Mende
Montpellier

34293
France
simon.descamps@crbm.cnrs.fr
960394
Djeddi
Abderazak
CGM
CNRS
Bât 26 Ave DE LA TERRASSE
Gif-Sur-Yvette
91198
France
abderazak.djeddi@cgm.cnrs-gif.fr
960663
Dupuy
Denis
DFCI
IECB
2 rue Robert Escarpit
Pessac

33607
France
d.dupuy@iecb.u-bordeaux.fr
960284
Duveau
Fabien

Inst Jacques Monod - CNRS
15 rue Hélène Brion
Paris

75013
France
duveau.fabien@ijm.jussieu.fr
960445
Felix
Marie-Anne
Dept Developmental Biol
CNRS - Inst Jacques Monod
15 rue Hélène Brion
Paris cedex 13
75205
France
felix@ijm.jussieu.fr
960865
Gieseler
Kathrin
Dept CNRS
CGMC-UCBL
16 rue Dubois
69622
Villeurbanne Cedex
Villeurbanne
69622
France
gieseler@cgmc.univ-lyon1.fr
960709
Giordano
Rosina
Genome Regulation & Evolution
Inst Europeen Chimie et Biol
2, rue Robert Escarpit
Pessac

33607
France
rosina.giordano@inserm.fr
960760
Jarriault
Sophie
Dept Dev Biol
IGBMC
1 rue Laurent Fries, BP10142
Illkirch

67404
France
sophie@igbmc.u-strasbg.fr
960376
Jospin
Maelle
Biol
Univ de Lyon 1, UMR CNRS 5123
43 bd du 11 novembre 1918
Villeurbanne

69622
France
jospin@univ-lyon1.fr
961557
KAGIAS
KONSTANTINOS
DEVELOPMENT AND MOLECULAR BIOL
IGBMC - CERBM
1 Rue Laurent Fries
ILLKIRCH

67404
France
konstantinos.kagias@igbmc.fr
960393
Koloteuva
Irina
Cell & Dev Biol
IGBMC - CERBM
1 Rue Laurent Fries
Illkirch

67404
France
ert@igbmc.fr
960591
Labouesse
Michel
CELLULAR BIOLOGY AND DEVELOPMENT
IGBMC
BP 10141, Illkirch
ILLKIRCH

67400
France
lmichel@igbmc.u-strasbg.fr
961531
Lakowski
Bernard
Dept Neuroscience
Pasteur Inst
25 rue du Docteur Roux
Paris

75724
France
lakowski@pasteur.fr
960520
Legouis
Renaud
CGM
CNRS
Ave de la Terrasse
Gif-sur-Yvette
91198
France
renaud.legouis@cgm.cnrs-gif.fr
960431
Merlet
Jorge

Institut Jacques Monod, CNRS
Bat. Buffon 15 rue Hélène Brion
Paris

75205
France
merlet.jorge@ijm.jussieu.fr
960661
Michaux
Gregoire

IGDR
2 Ave du Prof Leon Bernard
Rennes

35043
France
gmichaux@univ-rennes1.fr
960341
Nuez
Isabelle

CNRS, Inst J Monod
15 rue Hélène Brion
Paris cedex 13
75205
France
nuez@ijm.jussieu.fr
960339
Palladino
Francesca
Dept Molecular & Cellular Biol
Ecole Normale Supériure de Lyon
46 allee d'Italie
Lyon

69006
France
francesca.palladino@ens-lyon.fr
960539
Pintard
Lionel
Dept Development
Inst Jacques Monod, CNRS
15 rue Helene Brion
Paris cedex 13
75205
France
pintard@ijm.jussieu.fr
960919
Pujol
Nathalie

INSERM CIML
CASE 906 - 163 Avenue de Luminy
Marseille

13288
France
pujol@ciml.univ-mrs.fr
961112
Rapti
Georgia
Dept Biol
ENS-INSERM
46 rue d'Ulm

Paris

75005
France
rapti@biologie.ens.fr
960707
Rebora
Karine
Genome Regulation & Evolution
Inst Europeen Chimie et Biol
2 rue Robert Escarpit
Pessac

33607
France
k.rebora@iecb.u-bordeaux.fr
961003
Reedy
April
CGMC CNRS
University of Claude Bernhard
Rue Raphael Dubois
CNRS-UMR 5534
Kalamazoo
Rhone-Alpes
69100
France
april.reedy@gmail.com
961489
Richard
Magali
Biol
Ecole Normale Superieure
46 rue d'Ulm

PARIS

75005
France
mrichard@biologie.ens.fr
960816
Robert
Valerie
ENS-Dept Biol
Inserm
46, Rue d'Ulm
Paris

75005
France
vrobert@biologie.ens.fr
960088
Schott
Sonia
LBMC - CNRS UMR5239
Ecole Normale Supérieure de Lyon
46, allée d'Italie
LYON Cedex 07
69364
France
Sonia.Schott@ens-lyon.fr
960662
Shafaq-zadah
Massi

IGDR
2 Ave du Prof Leon Bernard
Rennes

35043
France
massiullah.shafaq-zadah@univ-rennes1.fr
961117
Squiban
Barbara

CIML
Parc Scientifique & Tech de luminy
Case 906
Marseille

9543
France
squiban@ciml.univ-mrs.fr
960391
Zhang
Huimin
Cell&Dev Biol
IGBMC - CERBM
1 Rue Laurent Fries
ILLKIRCH

67404
France
zhangh3@igbmc.fr
960852
Zniber
Ilyass
Genome Regulation & evolution
Inst Europeen Chimie et Biol
2 rue Robert escarpit
33607
Pessac (Bordeaux)
33607
France
i.zniber@iecb.u-bordeaux.fr
960918
Zugasti
Olivier
Centre D'Immunologie
INSERM - CIML
163 Avenue de Luminy
Marseille

13288
France
zugasti@ciml.univ-mrs.fr
961106
Begasse
Maria

Max Planck Institute
Pfotenhauerstr 108
Dresden

1307
Germany
begasse@mpi-cbg.de
960953
Bois
Justin
Biological Physics
MPI-CBG
Pfotenhauerstr 108
Dresden

1307
Germany
bois@mpi-cbg.de
960132
Bossinger
Olaf
MOCA
RWTH Aachen University
Wendlingweg 2
Aachen
NRW
52074
Germany
bossinger@mac.com
960866
Dieterich
Christoph
Berlin Inst Med Systems Biol
Max Delbruck Ctr Molec Med
Robert-Rössle-Straße 10
Berlin

72072
Germany
chrisd@tuebingen.mpg.de
960022
Doering
Frank
Molecular Prevention
University of Kiel
Heinrich-Hecht-Platz 10
Kiel
Kiel
24118
Germany
sek@molprev.uni-kiel.de
960917
Ermolaeva
Maria
Institute for Genetics
University of Cologne
Zuelplicher Strasse 47
Cologne

50674
Germany
ermolaem@uni-koeln.de
961144
Gerisch
Birgit

MPI Biol Ageing
Gleueler Str 50a
Cologne

D-50931
Germany
gerisch@molgen.mpg.de
961386
Goehring
Nathan

Max Planck Institute for Cell Biology and Genetics
Pfotenhauerstrasse 108
Dresden

1307
Germany
goehring@mpi-cbg.de
961417
Grill
Stephan

MPI-CBG/MPI-PKS
Pfotenhauerstr 108
Dresden

1307
Germany
grill@mpi-cbg.de
960087
Heger
Peter
Zoological Institute
University of Cologne
Kerpener Strasse 15
Koeln
NRW
50937
Germany
peter.heger@uni-koeln.de
960019
Jedamzik
Britta

MPI-CBG
Pfotenhauerstrasse 108
Dresden
Sachsen
1099
Germany
jedamzik@mpi-cbg.de
961212
Kevei
Eva

University of Köln, CECAD
Zülpicher Str. 47
Köln

50674
Germany
keveie@uni-koeln.de
960952
Khuc Trong
Philipp
Biological Physics
MPI
Noethnitzer Strasse 38
Dresden

1187
Germany
khuc@pks.mpg.de
961305
Liewald
Jana
Inst Biochem
J W Goethe-Univ
Max-von-Laue-Str 9
Frankfurt

60438
Germany
j.liewald@biochem.uni-frankfurt.de
960028
Liu
Shu
Ralf Baumeister lab
Institute of Biology III
Schaenzle str. 1
Freiburg

79104
Germany
shu.liu@biologie.uni-freiburg.de
960548
Martin
Katharina
Inst fuer Genetik
TU Braunschweig
Spielmannstr 7
Braunschweig

38106
Germany
k.martin@tu-bs.de
960695
Mayer
Mirjam
Motor Sytems
MPI-CBG
Pfotenhauer Str. 108
Dresden
Saxony
1307
Germany
mayer@mpi-cbg.de
960549
Memar
Nadin
Inst Genetik
TU Braunschweig
Spielmannstr 7
Braunschweig
Lower Saxony
38106
Germany
n.memar@tu-bs.de
961208
Menzel
Ralph
Dep. Biol.,  Freshwater Ecology
Humboldt-University at Berlin
Spaethstr. 80/81
Berlin
Berlin
D-12437
Germany
ralph.menzel@biologie.hu-berlin.de
960120
Ogawa
Akira
Dept Evolutionary Biol
Max-Planck Inst
Spemannstrasse 37-39
Tuebingen

72076
Germany
akira.ogawa@tuebingen.mpg.de
961424
Preibisch
Stephan

MPI-CBG
Pfotenhauerstrasse 108
Dresden

1307
Germany
schneide@mpi-cbg.de
960254
Qi
Wenjing
Baumeister Lab
Biology 3
schänzlestr. 1
Freiburg (Breisgau)
BW
79104
Germany
wenjing.qi@biologie.uni-freiburg.de
961243
Sarov
Mihail
Transgeneomics
MPI-CBG
Pfotenhauerstrasse 108
Dresden

1307
Germany
sarov@mpi-cbg.de
960095
Sassen
Wiebke
Klopfenstein Lab
DFG Research Center CMPB
Humboldtallee 23
Goettingen
Niedersachsen
37073
Germany
wiebkeanna@googlemail.com
960204
Schaeffer
Ursula
ZBSA
University of Freiburg
Habsburger Str. 49
Freiburg

79104
Germany
ursula.schaeffer@biologie.uni-freiburg.de
960601
Schultheis
Christian

Goethe Univ Frankfurt
Max von Laue St 9
Frankfurt

60438
Germany
chrschultheis@web.de
960076
Schulze
Jens
Zoological Institute
University of Cologne
Kerpener Str. 15
Cologne

50923
Germany
JensSchulze@gmx.de
961211
Segref
Alexandra
CECAD
University of Cologne
Zuelpicher Strasse 47
Cologne

50674
Germany
asegref@uni-koeln.de
960055
Sommer
Ralf
Dept Evolutionary Biol
MPI Developmental Biology
Spemannstrasse 37
Tuebingen, Baden Württemberg
72076
Germany
ralf.sommer@tuebingen.mpg.de
960292
Streit
Adrian
Dept Evolutionary Biology
MPI Developmental Biology
Spemannstr 35
Tuebingen

72076
Germany
adrian.streit@tuebingen.mpg.de
960049
Wang
Xiaoyue
Evolutionary biology
Max-Planck Institute
Spemannstrasse 35
Tübingen

72076
Germany
xiaoyue.wang@tuebingen.mpg.de
960253
Wang
Yimin

Institute for Bio3, uni-Freiburg
Schaensle str.1
Freiburg
Freiburg
79104
Germany
wangyiminsibs@yahoo.com.cn
960550
Wiekenberg
Anne
Inst fuer Genetik
TU Braunschweig
Spielmannstr 7
Braunschweig

38106
Germany
a.wiekenberg@tu-bs.de
960429
Wiesenfahrt
Tobias

RWTH Aachen University
Wendlingweg 2
52074 Aachen
NRW
52074
Germany
tobias2278@gmx.de
960613
Kourtis
Nikos
IMBB
FORTH
Vassilika Vouton
Heraklion

71110
Greece
kourtis@imbb.forth.gr
960621
Rieckher
Matthias

Inst Molec Biol & Biotech
N. Plastira 100
Heraklion
Crete
70013
Greece
matthias@imbb.forth.gr
960462
Tavernarakis
Nektarios
IMBB
FORTH
Vassilika Vouton, Crete
Heraklion
Crete
71110
Greece
tavernarakis@imbb.forth.gr
960072
Chow
King-Lau
Dept Biol
Hong Kong Univ Sci & Technol
Clear Water Bay, Kowloon
Hong Kong

----
Hong Kong
bokchow@ust.hk
960085
Fan
Kei C.

HKUST
Clear Water Bay
Hong Kong

none
Hong Kong
timmysfxc@gmail.com
960411
Hui
Agnes
Biology
HKUST


Hong Kong
Hong Kong
852
Hong Kong
hkyaa@ust.hk
960084
Leung
Chi Kwan

HKUST
Clear Water Bay
HK

none
Hong Kong
leungchikwan@gmail.com
960086
Wong
Kwok H.

HKUST
Clear Water Bay
Hong Kong

none
Hong Kong
klab@ust.hk
960064
Zhou
Yuan
BIOL
HKUST
Clear Water Bay
Hong Kong

852
Hong Kong
simbada@ust.hk
960277
Papp
Diana

Semmelweis University
37-47 Tuzolto utca
Budapest

H-1094
Hungary
diana.papp@eok.sote.hu
961446
Toth
Marton
Med Chemistry
Semmelweis Univ
37-47 Tuzolto utca
Budapest

1094
Hungary
toth@biology.rutgers.edu
961299
Koushika
Sandhya
Dept Neurobiology
NCBS-TIFR
GKVK, Bellary Rd, Karnataka
Bangalore
Karnataka
560065
India
koushika@ncbs.res.in
960171
Mohd
Ariz
Biological Sciences & Bioeng.
IIT Kanpur
BSBE Building

Kanpur
Uttar Pradesh
208016
India
ariz@iitk.ac.in
961302
Blacque
Oliver
Biomed. and Biomolec. science
University College Dublin
Belfield

Dublin
Dublin
Dublin 4
Ireland
oliver.blacque@ucd.ie
961303
Cevik
Sebiha

University College Dublin
Belfield

Dublin
Dublin
Dublin 4
Ireland
sebiha.cevik@ucd.ie
960888
Avinoam
Ori
Dept Biol
Technion - ITT
Technion City

Haifa
Haifa
32000
Israel
ori@tx.technion.ac.il
960336
Broday
Limor
Dept Cell & Dev Biol
Tel Aviv Univ
Sackler Faculty Medicine
Tel Aviv

69978
Israel
broday@post.tau.ac.il
961319
Cohen
Merav
Genetics
Hebrew Univ
Institute of Life Sciences, Givat Ram
Jerusalem

91904
Israel
meravc@cc.huji.ac.il
961166
Friedlander
Lilach
Dept Biol
Technion-Israel Inst Tech
Technion city

Haifa

32000
Israel
lilachf@tx.technion.ac.il
960615
Hashimshony
Tamar
Biology
Technion
Technion city
Biology room 508
Haifa

32000
Israel
thashimi@tx.technion.ac.il
960571
Hryshkevich
Uladzislau
Biology
Technion Israel Inst Tech
Technion city

Haifa

32000
Israel
hryshkev@tx.technion.ac.il
960614
Levin
Michal
Biology
Technion - IIT
Technion City

Haifa

32000`
Israel
mlevin@tx.technion.ac.il
961165
Oreu-Suissa
Meital
Biology
Technion-Israel Inst. of Tech
Haifa

32000
Israel
meitals@tx.technion.ac.il
961111
Podbilewicz
Benjamin
Dept Biol
Technion-IIT
Kiryat Hatechnion
Haifa

32000
Israel
podbilew@tx.technion.ac.il
961104
Smurova
Ksenia
Dept Biol
Technion
Technion City

Haifa

34404
Israel
k.smurova@gmail.com
960612
Yanai
Itai
Department of Biology
Technion - IIT
Technion City

Haifa

32000
Israel
yanai@technion.ac.il
960679
Di Schiavi
Elia

IGB, CNR
Via P.Castellino 111
Naples
NA
80131
Italy
dischiav@igb.cnr.it
961213
Amano
Hisayuki
Molecular Neuroscience Group
OIST
2-Dec

Uruma city
Okinawa
904-2234
Japan
amano@oist.jp
961425
Andachi
Yoshiki
Genome Biol Lab
National Inst Genetics
1111 Yata

Mishima

411-8540
Japan
yandachi@lab.nig.ac.jp
960083
Arata
Yukinobu
Cell Fate Decision
RIKEN
2-2-3 Minatosima-Minamimati
Chuo-ku, Kobe
650-0047
Japan
arata@cdb.riken.go.jp
961107
Azuma
Yusuke

RIKEN
1-7-22 Suehiro-cho, Tsurumi
Yokohama

230-0045
Japan
yazuma@riken.jp
961414
Doi
Motomichi
Neuroscience Research Inst
AIST
Tsukuba Cent 6, 1-1-1 Higashi
Tsukuba
Ibaraki
305-8566
Japan
doi-m@aist.go.jp
960050
Eki
Toshihiko
Dept Ecological Engineering
Toyohashi Univ Tech
Hibarigaoka 1-1, Tempaku-cho
Toyohashi, Aichi
441-8580
Japan
eki@eco.tut.ac.jp
961423
Emmei
Taishi
Graduate Sch Sci
Nagoya Univ
Furo-cho, Chikusa-ku
Nagoya

466-8602
Japan
emmei.taishi@b.mbox.nagoya-u.ac.jp
961506
Fujiki
Kota
Div Biological Sci
Nagoya Univ
Chikusa-ku

Nagoya
Aichi
464-8602
Japan
bunnsidairoku@gmail.com
961100
Fujita
Masashi
Dev Systems Modeling Team
RIKEN ASI
1-7-22 Suehiro-cho, Tsurumi
Yokohama
Kanagawa
230-0045
Japan
m-fujita@riken.jp
961044
Fujiwara
Manabi
Dept Biol
Grad Sch Sci, Kyushu Univ
6-10-1 Hakozaki, Higashiku
Fukuoka

8128581
Japan
mfujiscb@mbox.nc.kyushu-u.ac.jp
960118
Fukuyama
Masamitsu
Dept Pharmaceutical Sci
Univ Tokyo
7-3-1 Hongo, Bunkyo
Tokyo

113-0033
Japan
mfukuyam@mol.f.u-tokyo.ac.jp
961429
Furuta
Tomoyuki

Nagoya Unisversity
tikusa-ku furo-cho
Nagoya

464-0814
Japan
tomoyuki.furuta@c.mbox.nagoya-u.ac.jp
961098
Hara
Yuki

Grad. Univ. Adv. Stud.
Yata 1111

Mishima, Sizuoka
411-8540
Japan
yukhara@lab.nig.ac.jp
960070
Hattori
Ayuna
Molec Biol
Nagoya Univ


Nagoya
Nagoya
488-0804
Japan
ayu00houei@yahoo.co.jp
961203
Hayakawa
Teruyuki
Pharmaceutical Sci
Univ Tokyo
7-3-1 Hongo Bunkyo-ku
Tokyo

113-0022
Japan
ff077215@mail.ecc.u-tokyo.ac.jp
960889
Hino
Shizuka
Bioinfomatics
Ritsumeikan Univ

Kusatsu

525-8577
Japan
cb005045@is.ritsumei.ac.jp
961108
Hiraki
Hideaki
Ctr Genetic Resource
National Inst Genetics
1111 Yata

Mishima

411-8540
Japan
hhiraki@lab.nig.ac.jp
960568
Hirotsu
Takaaki
Dept Biol, Grad Sch Sci
Kyushu Univ
6-10-1 Hakozaki, Higashi-ku
Fukuoka

812-8581
Japan
tahirscb@mbox.nc.kyushu-u.ac.jp
960353
Horikawa
Makoto

Univ Tsukuba
Tennodai 1-1-1
Tsukuba
Ibaraki
305-0821
Japan
mh.alkerus@gmail.com
961368
Iino
Yuichi
Biophysics and Biochemistry
Univ Tokyo
7-3-1 Hongo, Bunkyo-ku
Tokyo

113-0033
Japan
iino@biochem.s.u-tokyo.ac.jp
961053
Inoue
Akitoshi
Dept Biol
Kyushu Univ
6-10-1 Hakozaki, Higashi-ku
Hukuoka

812-8581
Japan
sl20054@s.kyushu-u.ac.jp
960230
Inoue
Takao

University of Tokyo
7-3-1, Hongo, Bunkyo-ku
Tokyo

113-0033
Japan
takao@mol.f.u-tokyo.ac.jp
960540
Ishihara
Takeshi
Dept Biol
Fac Sci, Kyushu Univ
Hakozaki 6-10-1, Higashiku
Fukuoka

8128581
Japan
takeiscb@mbox.nc.kyushu-u.ac.jp
960886
Ito
Masahiro
Bioinformatics
Ritsumeikan University
1-1-1 Nojihigashi
Kusatsu

411-8540
Japan
maito@sk.ritsumei.ac.jp
960406
Iwasaki
Yuishi
Dept. Intelligent System Eng.
Ibaraki University
4-12-1 Nakanarusawa
Hitachi
Ibaraki
316-8511
Japan
iwasaki@mx.ibaraki.ac.jp
961045
Iwata
Ryo
Dept Biophysics & Biochem
Univ Tokyo
7-3-1 Hongo, Bunkyo-ku
Tokyo

113-0033
Japan
ss077133@mail.ecc.u-tokyo.ac.jp
960094
Kagawa
Hiroaki
Biology
Okayama University
1-3-38 Fujiwara-nishi machi
Okayama
Okayama
703-8244
Japan
hiro6kgw@aioros.ocn.ne.jp
960316
Kage-Nakadai
Eriko
Department of Physiology
Tokyo Women's Medical University
Tokyo

162-8666
Japan
nakadaie@research.twmu.ac.jp
960276
Kagoshima
Hiroshi
Genome Biol Laboratory
National Inst Genetics
Yata 1111

Mishima
Shizuoka
411-8540
Japan
hkagoshi@lab.nig.ac.jp
960113
Karashima
Takeshi
Dept Biophys, Biochem
Tokyo Univ
7-3-1 Hongo, Bunkyo-ku
Tokyo

113-0033
Japan
karashima-tky@umin.ac.jp
960438
Kawano
Kayo

Tottori University
4-101, Minami, Koyama-chou
Tottori

680-0942
Japan
heart_beat135@yahoo.co.jp
960511
Kawano
Tsuyoshi
Dept Agriculture
Tottori Univ
Koyama

Tottori

680-8553
Japan
kawano@muses.tottori-u.ac.jp
960982
Kim
Hon-Song
Bioscience
Kwansei-Gakuin Univ
2-1 Gakuen

Sanda, Hyogo
669-1337
Japan
hskim@kwansei.ac.jp
960168
Kimata
Tsubasa
Science
Nagoya University
Furo-cho, Chikusa-ku
Nagoya
Aichi
4648602
Japan
kimata.tsubasa@a.mbox.nagoya-u.ac.jp
960978
Kimura
Kenji
Cell Arch Lab
National Inst Gen
Yata 1111

Mishima

411-8540
Japan
kekimura@lab.nig.ac.jp
960969
Kimura
Kotaro
Dept Biological Sci
Osaka Univ
1-1 Machikane-yama
Toyonaka
Osaka
560-0043
Japan
kokimura@bio.sci.osaka-u.ac.jp
961109
Kiriyama
Keisuke
Biol
Kyushu Univ
6-10-1 Hakozaki, Higashi-ku
Fukuoka

812-8581
Japan
3sl09037s@sls.kyushu-u.ac.jp
961428
Kobayashi
Kyogo

Nagoya Univ
Hurou-cho

Nagoya
Aichi-ken
464-8602
Japan
kobayashi.kyogo@d.mbox.nagoya-u.ac.jp
960892
Kobuna
Hiroyuki
Dept Physiology
TWMU, Tokyo, Japan
Kawada-cho, Shinjuku-ku
Tokyo

162-8666
Japan
kobuna@research.twmu.ac.jp
960437
Komatsu
Maki

tottori university
4-101,minami,koyama-chou
tottori

680-0941
Japan
makiron_bu319@yahoo.co.jp
960749
Konno
Hiroyuki
Genetics
Graduate Univ Adv Studies
Yata 1111

Mishima

411-0847
Japan
hkonno@lab.nig.ac.jp
960027
Kontani
Kenji
Dept. of Physiol. Chem.
University of Tokyo
7-3-1 Hongo

Bunkyo-ku
Tokyo
113-0033
Japan
kontani@mol.f.u-tokyo.ac.jp
961061
Koyama
Hiroshi
Cell Architecture Lab.
National institute of Genetics
Yata

Mishima-shi
Shizuoka-ken
411-8540
Japan
hkoyama@lab.nig.ac.jp
960167
Kuhara
Atsushi
Dept Molec Neuro-bio Sci
Nagoya Univ
Chikusa-Ku, Furo-co
Nagoya, Aichi

464-8602
Japan
atsushi_kuhara@cc.nagoya-u.ac.jp
961011
Kunitomo
Hirofumi
Dept. Biophys. Biochem.
University of Tokyo
7-3-1 Hongo, Bunkyo-ku
Tokyo

113-0033
Japan
kunitomo@biochem.s.u-tokyo.ac.jp
961566
Kuroyanagi
Hidehito
Grad Sch Biomed Sci
Tokyo Medical & Dental Univ
1-5-45 Yushima, Bunkyo-ku
Tokyo

113-8510
Japan
kuroyana.end@tmd.ac.jp
961202
Kyoda
Koji
Dev Systems Modeling Team
RIKEN ASI
1-7-22 Suehiro-cho, Tsurumi
Yokohama

230-0045
Japan
kkyoda@riken.jp
960269
Lee
Hyeon-Cheol
Graduate School of Pharmaceutica
University of Tokyo

Tokyo

113-0033
Japan
kentetsu@mol.f.u-tokyo.ac.jp
960890
Maeshiro
Tetsuya
SLIS
Univ Tsukuba
1-2 Kasuga

Tsukuba

305-8550
Japan
maeshiro@slis.tsukuba.ac.jp
961055
Maruyama
Ichiro
Molecular Neuroscience Group
Okinawa Inst of Sci & Technol
12-2 Suzaki, Uruma
Okinawa
Okinawa
904-2234
Japan
ichi@oist.jp
960270
Matsuda
Shinji
Graduate School of Pharmaceutica
University of Tokyo

Tokyo

113-0033
Japan
shinji@mol.f.u-tokyo.ac.jp
960436
Matsunaga
Yohei

Tottori Univ
4-101, Minami, Koyama-cho
Tottori

680-8553
Japan
youhei1614@yahoo.co.jp
960538
Miyara
Akiko
Div Biological Sci
Nagoya Univ
Furo-cho, Chikusa-ku, Aichi
Nagoya

464-8602
Japan
miyara.akiko@a.mbox.nagoya-u.ac.jp
960199
Mori
Akihiro
Dept Genetics
Graduate Univ Advanced Studies
Yata 1111, Shizuoka
Mishima

411-8540
Japan
akmori@lab.nig.ac.jp
960231
Murayama
Takashi
Molecular Neuroscience Unit
OIST
12-2 Suzaki, Uruma
Okinawa

904-2234
Japan
tmurayama@oist.jp
960103
Nakae
Isei
Dept. of Physiol. Chem.
The university of Tokyo
7-3-1 Hongo

Bunkyo-ku
Tokyo
113-0033
Japan
isei@seiri.f.u-tokyo.ac.jp
961422
Nishio
Nana
Div Biological Sci
Nagoya Univ
Furo-cho, Chikusa-ku, Aichi
Nagoya

464-8602
Japan
nishio.nana@d.mbox.nagoya-u.ac.jp
961105
Nishiwaki
Kiyoji
Dept Bioscience
Kwansei Gakuin Univ
2-1 Gakuen

Sanda

669-1337
Japan
nishiwaki@kwansei.ac.jp
960389
Niwa
Ryusuke
Grad School Life Environ Sci
University of Tsukuba
Tennoudai 1-1-1
Tsukuba
Ibaraki
305-8572
Japan
ryusuke-niwa@umin.ac.jp
961099
Noguchi
Kouki
Genome Biol Lab
Natl Inst Genetics
Yata1111

Mishima
Shizuoka
411-8540
Japan
konoguch@lab.nig.ac.jp
960252
Nukazuka
Akira

NIBB
Myodaiji-cho

Okazaki
Aichi
444-8585
Japan
nukazuka@nibb.ac.jp
960681
Oda
Shigekazu
Biophysics & Biochemistry
University of Tokyo

Tokyo

113-0033
Japan
rustc.sgkz@gmail.com
960404
Ogura
Ken-ichi
Dept Pharmacology
Yokohama City Univ

Yokohama

236-0004
Japan
kenogura@med.yokohama-cu.ac.jp
961008
Ohara
Yoshiyasu
molecular biology
hiroshima Univ
kagamiyama1-3-1
hiroshima
hiroshima
739-0036
Japan
m084549@hiroshima-u.ac.jp
961004
Ohno
Hayao
Dept Biophysics & Biochem
Univ Tokyo


Tokyo
Tokyo
113-0033
Japan
ohno@biochem.s.u-tokyo.ac.jp
960864
Ohshima
Yasumi
Dept Applied Life Sci
Sojo Univ
4-22-1, Ikeda
Kumamoto

860-0082
Japan
ohshima@life.sojo-u.ac.jp
960413
Okazaki
Ayako
Div Biological Sci
Nagoya Univ
Furo-cho,Chikusa-ku,Aichi
Nagoya

464-8602
Japan
okazaki.ayako@b.mbox.nagoya-u.ac.jp
961309
Onami
Shuichi
Advanced Computational Sciences
RIKEN ASI
1-7-22 Suehiro-cho, Tsurumi
Yokohama
Kanagawa
230-0045
Japan
sonami@riken.jp
960417
Sakamoto
Taro

Kitasato Univ


Tokyo

108-8641
Japan
sakamotot@pharm.kitasato-u.ac.jp
960569
Sanehisa
Shigeki
Molec Neuroscience Unit
OIST
12-2 Suzaki

Uruma

904-2234
Japan
ssanehis@oist.jp
960887
Sasahara
Dai
Bioinformatics
Ritsumeikan Univ

Kusatsu

525-8577
Japan
cb003041@is.ritsumei.ac.jp
961007
Sassa
Yutaro
Molec Biotech
Hiroshima Univ
kagamiyama1-3-1
Higashihiroshima
739-0035
Japan
m092390@hiroshima-u.ac.jp
961401
Sawa
Hitoshi
Laboratory for Cell Fate Decis
RIKEN Center for Developmenta
2-2-3 Minatojima-minamimachi
Kobe
Hyogo
650-0047
Japan
sawa@cdb.riken.jp
960862
Shin-i
Tadasu
Genome Biol Lab
National Inst Genetics
1,111 Yata, Shizuoka
Mishima

411-8540
Japan
tshini@genes.nig.ac.jp
961222
Shingai
Ryuzo
Dept Engineering
Iwate Univ
4 Ueda

Morioka, Iwate
020-8551
Japan
shingai@iwate-u.ac.jp
961200
Shinkai
Yoichi
Dept Biol, Fac Sci
Kyushu University
#3435 6-10-1 Hakozaki Higashi-ku
Fukuoka
Fukuoka
812-8581
Japan
sc307058@s.kyushu-u.ac.jp
960477
Shouyama
Tetsuji
Dept Biological Sci & Tech
Tokai Univ
317 Nishino

Numazu

410-0395
Japan
umebosi0601@hotmail.com
960884
So
Shuhei

Sojo Univ


Kumamoto
Kumamoto
860-0082
Japan
shuhei_so0812@yahoo.co.jp
960337
Suda
Hitoshi
Dept Biological Sci & Technol
Tokai Univ
317 Nishino

Numazu

410-0321
Japan
sudasai@wing.ncc.u-tokai.ac.jp
960105
Sugimoto
Asako
Dept Developmental Genomics
RIKEN CDB
2-2-3 Minatojima-minamimachi, Chuo-ku
Kobe

650-0047
Japan
sugimoto@cdb.riken.jp
961103
Sumiyoshi
Eisuke
Genome Biol Laboratory
National Inst Genetics
1111 Yata, Shizuoka
Mishima

411-8540
Japan
esumiyos@lab.nig.ac.jp
960460
Suzuki
Michiyo

Japan Atomic Energy Agency
Takasaki
Gunma
370-1292
Japan
suzuki.michiyo@jaea.go.jp
960405
Suzuki
Motoshi


Furo-cho, Chikusa-ku
Nagoya

464-8602
Japan
motoshi-suzuki@bio.nagoya-u.ac.jp
961415
Takagi
Shin
Dept Biol
Nagoya Univ Sch Sci
Furo-cho, Chikusa-ku, Aichi
Nagoya

464-8602
Japan
i45116a@nucc.cc.nagoya-u.ac.jp
960271
Tanji
Takahiro
Dept Immunobiology
Sch Pharmacy, Iwate Med Univ
2-1-1 Nishi-tokuta
Yahaba
Iwate
028-3694
Japan
ttanji@iwate-med.ac.jp
961314
Terasawa
Masahiro

RIKEN CDB
2-2-3 Minatojima-minamimachi, Chuo-ku
Kobe
Hyogo
650-0047
Japan
mterasw@cdb.riken.jp
961304
Tsukada
Yuki
Graduate Sch Sci
Nagoya Univ
Furo-cho, Chikusa-ku
Nagoya

464-8602
Japan
tsukada.yuki@b.mbox.nagoya-u.ac.jp
961310
Uno
Masaharu

Kyoto Univ
yoshida

Kyoto
kyoto
6068157
Japan
muno.m06@lif.kyoto-u.ac.jp
960297
Wakabayashi
Tokumitsu

Iwate Univ
4-3-5 Ueda,

Morioka

020-8551
Japan
wakat@iwate-u.ac.jp
961046
Yamada
Koji
Dept Molec Gen Research Lab
Univ Tokyo
2-11-16 Yayoi, Bunkyo-ku
Tokyo

113-0032
Japan
yamada@biochem.s.u-tokyo.ac.jp
960004
Yamaguchi
Atsushi
Dept. of Neurobiology, Graduate School of Med
Chiba University
1-8-1, Inohana, Chuo-ku
Chiba
Chiba
260-8670
Japan
atsyama@restaff.chiba-u.jp
961398
Yamakawa
Ayanori
Dept Material Sci
Wakayama National Col
77 Noshima Nada, Wakayama
Gobo

644-0023
Japan
yamakawa@wakayama-nct.ac.jp
960281
Yamamoto
Yuko
Dept Cell Fate Decision
CDB, RIKEN
2-2-3 Minatojima-mimamimachi C
Kobe

650-0047
Japan
yukoyamamoto@cdb.riken.jp
960005
Yanase
Sumino
Dept Health Sci
Daito Bunka Univ
Iwadono 560, Higasimatsuyama
Saitama

355-8501
Japan
syanase@ic.daito.ac.jp
961313
Yonetani
Masafumi

Osaka Univ
1-1 Machikaneyamamachi
Osaka

560-0043
Japan
masa-yone@cdb.riken.jp
961300
Yoshida
Kazushi
Dept. of Biophys. and Biochem.
University of Tokyo
7-3-1 Hongo, Bunkyo-ku
Tokyo

113-0032
Japan
kyoshida@biochem.s.u-tokyo.ac.jp
960065
Yuka
Shimizu
Biological Science and Technolog
Tokai University
317 Nishino

Numazu

410-0395
Japan
doki_doki_ys_happy@yahoo.co.jp
961321
Ahn
Byungchan
Dept Life Sci
Univ Ulsan
Nam-Ku Moogeo-Dong
Ulsan

680749
Korea
bbccahn@mail.ulsan.ac.kr
961412
Ahnn
Joohong
Dept Life Sci
Hanyang Univ
Hangdang-dong 17, Sungdong-gu
Seoul
Seoul
133-791
Korea
joohong@hanyang.ac.kr
961058
Cho
Cha-Sun

Hanyang University
17 Haengdang-dong, Seongdong-gu
Seoul

133-791
Korea
whck0715@hanmail.net
960112
Choi
Myung-gyu
Dept Biological Sci, Kwanak-gu
Seoul National Univ
San 56-1 Shillim-dong
Seoul

151-747
Korea
mgm9@naver.com
961057
Choi
Tae Woo

Hanyang Univerisity
17 Haengdang-dong, Seongdong-gu
Seoul
Seoul
133-791
Korea
ctw1983@naver.com
960283
Dwivedi
Meenakshi

Hanyang University
Haengdang-dong, Seongdong-gu
Seoul

133-791
Korea
meena.dwivedi@gmail.com
960415
Hahm
Jeong-Hoon
Biochem
Yonsei Univ
Shinchon-dong, Seodaemun-gu
Seoul
SEOUL
120-749
Korea
hahmjh@proteomix.org
961049
Hwang
Ara

POSTECH
Hyo-ja dong, Nam-gu
Pohang
kyungbuk
790-784
Korea
ara.hwang@postech.ac.kr
961327
Hyun
Moonjung
Dept Life Sci
Univ Ulsan
Nam-Ku Moogeo-Dong
Ulsan

680749
Korea
tkfmadl77@mail.ulsan.ac.kr
961050
Jeong
dahye

Postech
kyungbuk

pohang

790-784
Korea
sona0126@gmail.com
961205
Jeong
Myung-Hwan

Konkuk Univ
1,Hwayang-dong, Gwangjin-Gu
Seoul

143-701
Korea
jmh8022@naver.com
960428
Joo
Hyoe-Jin
Dept Biochemistry
Yonsei Univ
Shinchondong 134, Seodaemoongu
Seoul

120749
Korea
jjoopiter@yonsei.ac.kr
960375
Kalichamy
Karunambigai
Hanyang University
Haengdang-dong, Seongdong-gu
Seoul

133-791
Korea
karunakalichamy@yahoo.com
960814
Kang
Sang-Jo
Dept Biochem
Yonsei Univ
134 Shinchon-dong,Seodaemun-gu
Seoul

120-749
Korea
ksjojo602@hanmail.net
960791
Kawasaki
Ichiro
Dept Bioscience & Biotech
Konkuk Univ
#1, Hwayang-dong, Gwangjin-gu
Seoul

143-701
Korea
ikawasak@mac.com
960111
Kim
Chun-A
School of biological science
Seoul National university
building 105-319 sinlim 9 dong
Seoul

151-061
Korea
kimchuna@hotmail.com
961052
Kim
Jeongmin
Life Science
Hanyang University
17 Haengdang-dong, Seongdong-gu
Seoul
Seoul
133-791
Korea
innovatorjm@naver.com
960682
Kim
Sunhee
Dept Biochemistry
Yonsei Univ
Sinchon-Dong 134 Seodaemun-gu
Seoul

120-749
Korea
kimsh@proteomix.org
960374
Le
Son
Life Sci
College Natural Sci
Hanyang Univ
Seoul

133-791
Korea
lethoson@yahoo.com
960114
Lee
Hanee
Biological science
IMBG
105-319 IMBG SNU Seoul,Korea
Seoul

151-742
Korea
danji122@snu.ac.kr
961410
Lee
Insuk
Biotech
Yonsei Univ
134 Shinchon-dong
Seoul

120-749
Korea
insuklee@yonsei.ac.kr
961295
Lee
Jeeyong
Dept Biochemistry
Yonsei Univ
134 Sinchon-dong, Seodaemun-gu
Seoul

120-740
Korea
leejy@proteomix.org
960116
Lee
Jihyun
School of Biological Sciences
Seoul National University
San 56-1 Shillim-dong,105-319
Seoul

151-742
Korea
jlee00@snu.ac.kr
961322
Lee
Jin-A
Ulsan Univ

Moogeodong

Ulsan

680-749
Korea
lja0217a@hanmail.net
961059
Lee
Seung-Jae
Dept Life Science
POSTECH
San 31 Hyoja-Dong, Nam-Gu
Pohang
Gyeongbuk
790-784
Korea
seungjaelee1@gmail.com
961204
Lee
Yong-Uk

Konkuk Univ
1, Hwayang-dong, Gwangjin-gu
Seoul

143-701
Korea
soldier122@naver.com
960285
Li
Weixun

hanyang University
Haengdang-dong, Seongdong-gu
Seoul

133-791
Korea
weehoon@hanyang.ac.kr
960117
Moon
Hyungmin
School of biological science
Seoul National University
105-319 IMBG shillim9-dong
Seoul

151-719
Korea
moon84@snu.ac.kr
961051
Song
Hyun-ok
Dept Life Sci
GIST
1 Oryong-dong Buk-gu
Gwangju
Seoul
500-712
Korea
sea5328@gist.ac.kr
961054
Sung
Hyun

Hanyang University
17 Haengdang-dong, Seongdong-gu
Seoul

133-791
Korea
gyaooay@naver.com
960815
Yoo
Bum
Dept Biochem
Yonsei Univ
134 Shinchon-dong,Seodaemun-gu
Seoul

120-749
Korea
vdarios@naver.com
961056
Yun-Ki
Lim

Hanyang University
17 Haengdang-dong, Seongdong-gu
Seoul

133-791
Korea
337jjang@naver.com
960260
Lee
Song-Hua

Universiti Kebangsaan Malaysia
UKM-Bangi

Bangi
Selangor
43600
Malaysia
songhua82@yahoo.com
960162
Láscarez
Laura

IFC - UNAM
Circuito Exterior s/n Ciudad Universitaria
México
D. F.
4510
Mexico
lascarez@ifc.unam.mx
960250
Navarro
Rosa
Departamento de Biología Celular
IFC, UNAM
Circuito Exterior s/n
Mexico City
DF
4510
Mexico
rnavarro@ifc.unam.mx
960157
Paz-Gomez
Daniel
Departamento de Biologia Celular
IFC-UNAM
Circuito Exterior s/n Ciudad Universitaria
Mexico, D.F.

4510
Mexico
dpaz@ifc.unam.mx
960160
Silva
Carlos
Biología Celular
IFC - UNAM
Circuito Exterior s/n Ciudad Universitaria
México
D. F.
4510
Mexico
csilva@ifc.unam.mx
960122
Boxem
Mike
Ontwikkelingsbiologie
Utrecht University
Padualaan 8

Utrecht
Utrecht
3584CH
Netherlands
m.boxem@uu.nl
960513
Broekhuis
Joost
Dept Cell Biol
ErasmusMC
Dr Molewaterplein 50
Rotterdam

3015GE
Netherlands
j.broekhuis@erasmus.nl
960286
de Boer
Richard
Molecular Biology and Microbial Food Safety
Swammerdam Institute for Life Sciences
Nieuwe Achtergracht 166
Amsterdam

1018 WV
Netherlands
Richard.deboer@uva.nl
960189
Harterink
Martin
Korswagen group
Hubrecht Institute
Uppsalalaan 8
Utrecht
Utrecht
3584 CT
Netherlands
m.harterink@niob.knaw.nl
960119
Johnson
Nicholas
Tijsterman Group
Hubrecht Institute
Uppsalalaan 8
Utrecht
Utrecht
3584 CT
Netherlands
n.johnson@niob.knaw.nl
960192
Korswagen
Hendrik

Hubrecht Laboratory
Uppsalalaan 8
Utrecht

3584 CT
Netherlands
rkors@niob.knaw.nl
960988
Korzelius
Jerome
Dev Biol
Utrecht Univ
Padualaan 8

Utrecht

3584 CH
Netherlands
jkorzelius@gmail.com
960156
Krpelanova
Eva
Dept Cell Biol & Genetics
Erasmus MC
Dr Molewaterplein 50
Rotterdam

3015 GE
Netherlands
e.krpelanova@erasmusmc.nl
960356
Lemmens
Bennie
Genome dynamics & stability
Hubrecht Institute
Leuvenplein 184
Utrecht (NL)
Utrecht
3584 LJ
Netherlands
b.lemmens@hubrecht.com
960410
Leong
W.Y.
Cell Biol
Erasmus MC
Dr Molewaterplein 50
Rotterdam
South Holland
3015GE
Netherlands
w.leong@erasmusmc.nl
960052
Maia
Andre

University Medical Center Utrech
Universiteitsweg 100
Sratenum 2.118 / PO Box 85060
Utrecht

3508AB
Netherlands
A.F.Maia@umcutrecht.nl
960191
Middelkoop
Teije

Hubrecht Institute KNAW, University Medical Center
Uppsalalaan 8
Utrecht
Utrecht
3584 CT
Netherlands
t.middelkoop@hubrecht.com
960570
Roerink
Sophie
Tijsterman lab
Hubrecht Inst
Uppsalalaan 8
Utrecht

3584 CT
Netherlands
s.roerink@hubrecht.com
960299
Snoek
L.
Nematology
Wageningen Univ
Binnenhaven 5
Wageningen

6709 PD
Netherlands
basten.snoek@wur.nl
961413
Tijsterman
Marcel
Functional Genomics
Hubrecht Institute
Uppsalalaan 8
Utrecht

3584 CT
Netherlands
tijsterman@niob.knaw.nl
960073
Umuerri-Olusanya
Oluwatoroti
Cell Biology
Erasmus University MedicalCenter
DR. Molewaterplein 50
POB 2040
Rotterdam

3015 GE
Netherlands
o.olusanya@erasmusmc.nl
960440
Van Den Heuvel
Sander
Developmental Biology
Utrecht Univ
Padualaan 8, Kruyt Bldg O505
Utrecht

3584 CH
Netherlands
s.j.l.vandenheuvel@uu.nl
961432
van der Goot
Annemieke
Gen
Univ Med Ctr Groningen
Hanzeplein 1

Groningen

9700 RB
Netherlands
a.t.van.der.goot@medgen.umcg.nl
960636
van der Spek
Johannes
Molecular Biology
University of Amsterdam
Nieuwe Achtergracht 166
Amsterdam

1018WV
Netherlands
j.c.vanderspek@uva.nl
960298
Vinuela
Ana
Lab Nematology
Wageningen Univ
Binenhaven 5
Wageningen
Gederland
6709 PD
Netherlands
ana.vinuela@wur.nl
961320
Montalvo Katz
Sirena
UC Berkeley

PO Box 595

Boqueron

622
Puerto Rico
sirenamontalvo@gmail.com
961407
Inoue
Takao
Biochemistry
National University of Singapore
8 Medical Drive
Blk MD7, #02-03
Singapore

117597
Singapore
bchti@nus.edu.sg
961430
Askjaer
Peter
Dept CABD
CSIC-Uni Pablo de Olavide
Carretera de Utrera, km 1
Seville
Seville
E-41013
Spain
pask@upo.es
960987
Cabello
Juan

Centro Investigacion Cancer
Campus Miguel Unamuno
Salamanca

37007
Spain
juan.cabello@usal.es
960002
Cacho-Valadez
Briseida

Andalusian Center for Developmental Biology
Seville
Seville
41013
Spain
bbcacval@alumno.upo.es
960703
Ceron
Julian

FUNDACIO IDIBELL
GRAN VIA DE HOSPITALET, 199
H. LLOBREGAT (BARCELONA)
BARCELONA
8907
Spain
jceron@idibell.cat
960704
Fontrodona
Laura
Cancer & Human Molec Gen
FUNDACIO IDIBELL
GRAN VIA DE HOSPITALET, 199
H. LLOBREGAT (BARCELONA)
8907
Spain
lfontrodona@idibell.org
961431
Rodenas
Eduardo

Univ Pablo de Olavide-CSIC
Carretera de Utrera, km1
Seville
Andalucia
41089
Spain
erodmar@alumno.upo.es
961241
Burglin
Thomas
Biosciences and Nutrition
Karolinska Institutet
Halsovagen 7
Huddinge

SE-141 57
Sweden
thomas.burglin@ki.se
960130
Gaur
Rahul
UCMM
Umea University
Analysvagen 1
Umea

901 87
Sweden
rahul.gaur@ucmm.umu.se
961110
Henriksson
Johan
Dept Biosciences & Nutrition
Karolinska Inst
Alfred Nobels Ale 7, Huddinge
Stockholm
Huddinge
141 98
Sweden
johan.henriksson@ki.se
960125
Kao
Gautam
Surgery
Umea University
Analys vagen 1
Umea

S-90187
Sweden
gautam.kao@surgery.umu.se
961317
Tang
Lois
Dpt of Biosciences & Nutrition
Karolinska Institutet
Alfred Nobels Alle 7
Stockholm
Stockholm
SE-141 89
Sweden
lois.tang@ki.se
961548
Tuck
Simon
UCMM
Umea Univ
Bldg 6M, Analysvägen 1
Umea

SE 901 87
Sweden
simon.tuck@ucmm.umu.se
960620
Afshar
Katayoun
Life Science
ISREC
SV ISREC UPGON Station 19
Lausanne

1015
Switzerland
katayoun.afshar@epfl.ch
960616
Alcedo
Joy

Friedrich Miescher Institute
Maulbeerstrasse 66
Basel

CH-4058
Switzerland
joy.alcedo@fmi.ch
960605
Bezler
Alexandra
Sch Life Sci
Swiss Federal Inst Tech (EPFL)
Station 19

Lausanne

1015
Switzerland
alexandra.bezler@epfl.ch
960036
Buessing
Ingo

Friedrich-Miescher-Institute
Maulbeerstr. 66
WRO-1066.1.52
Basel

79379
Switzerland
ingo.buessing@fmi.ch
960891
Butschi
Alex
Inst Molec Biol
Univ Zurich
Winterthurerstrasse 190
Zurich

CH-8057
Switzerland
alex.butschi@molbio.uzh.ch
960465
Cornils
Astrid

Friedrich Miescher Inst
Maulbeerstrasse 66
Basel

4058
Switzerland
astrid.cornils@fmi.ch
960181
de Vaux
Véronique
of Biology
University of Fribourg
Chemin du Musée 10
Fribourg
Fribourg
1700
Switzerland
veronique.devaux@unifr.ch
960193
Eberhard
Ralf
Institute of Molecular Biology
University of Zurich
Winterthurerstrasse 190
Zurich
Zurich
8057
Switzerland
ralf.eberhard@molbio.uzh.ch
960123
Farooqui
Sarfarazhussain
Dept Zoology
Univ Zurich
Winterthrerstrasse 190
Zurich

8001
Switzerland
sarfarazhussain.farooqui@zool.unizh.ch
960321
Gotta
Monica
GEDEV
Geneva University
1, rue M. Servet
Geneva

1211
Switzerland
monica.gotta@unige.ch
960617
Gysi
Stephan
Inst Molecular Biol
Univ Zurich
Winterthurerstr 190
Zurich

8057
Switzerland
stephan.gysi@molbio.unizh.ch
960170
Herrmann
Christina

University of Zurich
Winterthurerstr. 190
Zurich

8057
Switzerland
christina.herrmann@zool.uzh.ch
960104
Kradolfer
David
Institute of Zoology
University of Zürich
Winterthurerstrasse 190
Zürich
Zürich
8057
Switzerland
david.kradolfer@zool.uzh.ch
960066
Kress
Elsa
GEDEV
University of Geneva
rue Michel Servet 1
Geneva

1211
Switzerland
elsa.kress@unige.ch
961206
Meister
Peter
Functional Implications
FMI-Novartis Research Fndn
Maulbeerstrasse 66
Basel

4058
Switzerland
peter.meister@fmi.ch
960322
Mueller
Fritz
Dept Biol
Univ Fribourg
Chemin du Musee 10
Fribourg
Fribourg
1700
Switzerland
fritz.mueller@unifr.ch
960031
Nakdimon
Itay
Dept Zoology
Zurich Univ
Winterthurerstrasse 190
Zurich

8057
Switzerland
itaynak@gmail.com
960705
Neukomm
Lukas
Inst Molec Biol
Univ Zurich
Winterthurerstrasse 190
Zurich
Zurich
8057
Switzerland
lukas.neukomm@molbio.uzh.ch
960470
Noatynska
Anna
GEDEV
Univ Geneva
rue Michel servet 1
Geneva

1211
Switzerland
anna.noatynska@unige.ch
960010
Nusser
Stefanie

University of Zurich
Winterthurerstrasse 190
Zurich
Zurich
8057
Switzerland
stefanie.nusser@zool.uzh.ch
960124
Pellegrino
Mark
University of Zurich
Institute of Zoology
Winterthurerstrasse 190
Zurich

8057
Switzerland
mark.pellegrino@zool.uzh.ch
960020
Schmid
Tobias
Institute of Zoology
University of Zurich
Winterthurerstrasse 190
Zurich

8057
Switzerland
tobias.schmid@zool.uzh.ch
960772
Senften
Mathias
Dept Epigenetics
Friedrich Miescher Inst
Maulbeerstrasse 66
Basel

4058
Switzerland
mathias.senften@fmi.ch
961018
Sonneville
Remi
Gonczy Lab
ISREC
chem des boveresses 155
Epalinges

1066
Switzerland
r.sonneville@dundee.ac.uk
960740
Susanne
Finger
Epigenetics
Friedrich Miescher Institute
Maulbeerstrasse 66
Basel

4058
Switzerland
susanne.finger@fmi.ch
960517
Topf
Ulrike

Friedrich Miescher Inst
Maulbeerstrasse 66
Basel

4058
Switzerland
ulrike.topf@fmi.ch
960776
Towbin
Benjamin
Epigenetics
Friedrich Miescher Institute
Maulbeerstrasse 66
Basel

4058
Switzerland
benjamin.towbin@fmi.ch
960011
Walser
Michael
Institute Zoology
University of Zurich
Winterthurerstr 190
Zurich

8057
Switzerland
michael.walser@zool.uzh.ch
960748
Wright
Jane

FMI
mAULBEERSTRASSE 66
BASEL

4058
Switzerland
jane.wright@fmi.ch
960792
Chen
Yi-Yin
Graduate Inst Biomedical Sci
Chang Gung Univ
259 Wen-Hwa 1st Rd
Taoyuan city

333
Taiwan
m9601216@stmail.cgu.edu.tw
960352
Lo
Szecheng
Dept Life Sci
Chang Gung Univ
259 Wen-Hwa 1st Rd
TaoYuan

333
Taiwan
losj@mail.cgu.edu.tw
960699
Moncaleano
Juan
Life Science
National Tsing Hua University
5F, No. 27, Bo Ai St
HsinChu City
HsinChu
NA
Taiwan
jdmoncaleanop@gmail.com
961418
Wu
Yi-Chun

National Taiwan University
No1 Sec4 Roosevelt Rd
Taipei, Taiwan
106
Taiwan
yichun@ntu.edu.tw
960367
Ackerman
Daniel
Gen, Environment & Evolution
Inst Healthy Ageing
Gower St

London

WC1E 6BT
United Kingdom
daniel.ackerman@ucl.ac.uk
960554
Bamps
Sophie
IICB-LC Miall Bldg
Leeds Univ
Clarendon Way
Leeds

LS2 9JT
United Kingdom
fbssb@leeds.ac.uk
960075
Barclay
Jeff
School of Biomedical Sciences
University of Liverpool
Crown Street

Liverpool

L69 3BX
United Kingdom
barclayj@liverpool.ac.uk
960392
Berri
Stefano
School of Computing
University of Leeds
University of Leeds
Leeds
West Yorkshire
LS2 9JT
United Kingdom
s.berri@leeds.ac.uk
960043
Boehnisch
Claudia

University of Birmingham
Edgbaston

Birmingham

B15 2TT
United Kingdom
c.m.boehnisch@bham.ac.uk
961356
Brabin
Charles
Biochemistry
University of Oxford
South Parks Road
Oxford
Oxfordshire
OX1 3QU
United Kingdom
charles.brabin@magd.ox.ac.uk
960993
Braun
Toby
Dept Biochem
Univ Oxford
South Parks Rd
Oxford

OX1 3QU
United Kingdom
toby.braun@bioch.ox.ac.uk
961316
Brooks
Darren
Environment & Life Sci
Univ Salford


Salford

M5 4WT
United Kingdom
d.r.brooks@salford.ac.uk
961006
Busch
Emanuel
Dept Cell Biol
LMB
Hills Rd

Cambridge

CB2 0QH
United Kingdom
busch@mrc-lmb.cam.ac.uk
961459
Butler
Victoria
Cell Biol
MRC Lab Molec Biol
Hills Rd

Cambridge

CB2 0QH
United Kingdom
vbutler@mrc-lmb.cam.ac.uk
960461
Cabreiro
Filipe
Inst healthy ageing & G.E.E
Univ College London
Gower St

London

WC1E 6BT
United Kingdom
f.cabreiro@ucl.ac.uk
960870
Ch'ng
QueeLim
MRC Centre for Dev Neurobiology
King's College London
4th Flr NHH, Guy's Campus
London

SE1 1UL
United Kingdom
queelim@kcl.ac.uk
960110
Chen
Ron
Gurdon Institute
University of Cambridge
Tennis Court Road
Cambridge

CB2 1QN
United Kingdom
rac83@cam.ac.uk
960552
Craig
Hannah
Fac Biological Sci
Univ Leeds
Miall Bldg, Clarendon Way
Leeds

LS2 9JT
United Kingdom
h.craig@leeds.ac.uk
960867
Crook
Helen
ICaMB
Newcastle Univ
Catherine Cookson Bldg
Newcastle

NE24HH
United Kingdom
h.m.crook@ncl.ac.uk
961017
Davies
Keith
Biochem
Univ Oxford


Oxford

OX1 3QU
United Kingdom
keith.davies@bioch.ox.ac.uk
960032
Davis
Paul
Dept Informatics
Wellcome Trust Sanger Inst
Wellcome Trust Genome Campus
Hinxton

CB10 1SA
United Kingdom
pad@sanger.ac.uk
960516
Dillon
James
Sch Biological Sci
Univ Southampton
Bassett Crescent East
Southampton

SO16 7PX
United Kingdom
jcd@soton.ac.uk
960638
Doonan
Ryan
Institute of Healthy Ageing
University College London
Darwin Building, Gower Street
London

WC1E 6BT
United Kingdom
r.doonan@ucl.ac.uk
961229
Elmi
Muna
MRC LMCB
Univ College
Gower Street

London

WC1E 6BT
United Kingdom
m.elmi@ucl.ac.uk
961467
Ezcurra
Marina
Cell Biol Div
MRC-LMB
Hills Rd

Cambridge

CB2 0QH
United Kingdom
marina@mrc-lmb.cam.ac.uk
960262
Feng
Huiyun
FBS, University of Leeds
Inst. of Integrat. & Comp. Bio.
Miall 8.09, Clarendon Way
Leeds LS2 9JT
West Yorkshire
LS2 9JT
United Kingdom
huiyunf@hotmail.com
961210
Fisher
Jasmin
Computational Biology
Microsoft Research Cambridge
7 JJ Thomson Ave.
Cambridge

CB3 0FB
United Kingdom
jasmin.fisher@microsoft.com
960060
Gandhi
Francis Amrit
School of Biosciences
University of Birmingham
Edgbaston

Birmingham
West Midlands
B15 2TT
United Kingdom
frg681@bham.ac.uk
960684
Gartner
Anton
Gene Regulation/Expression
Sch of Life Sciences
Dow St

Dundee

DD1 5EH
United Kingdom
a.gartner@dundee.ac.uk
960137
Gravato-Nobre
Maria
Dept Biochemistry
Univ Oxford
South Park Rd
Oxford

OX1 3QU
United Kingdom
maria.gravato-nobre@bioch.ox.ac.uk
960033
Han
Michael
Dept Informatics
Wellcome Trust Sanger Inst
Wellcome Trust Genome Campus
Cambridge

CB10 1HH
United Kingdom
mh6@sanger.ac.uk
960121
Hodgkin
Jonathan
Dept Biochem
Univ Oxford
South Parks Rd
Oxford

OX1 3QU
United Kingdom
jonathan.hodgkin@bioch.ox.ac.uk
960553
Hope
Ian
IICB
Univ Leeds
Clarendon Way
Leeds

LS2 9JT
United Kingdom
i.a.hope@leeds.ac.uk
960660
Hughes
Samantha
Dept Biochem
Oxford Univ
South Parks Rd
Oxford

OX1 3QU
United Kingdom
samantha.hughes@bioch.ox.ac.uk
961005
Isaac
Richard
Sch Biol
Univ Leeds
Miall Bldg, Clarendon Way
Leeds

LS2 9JT
United Kingdom
r.e.isaac@leeds.ac.uk
961552
Kinnunen
Tarja
School of Biological Sciences
University of Liverpool
Crown Street

Liverpool

L69 7ZB
United Kingdom
T.K.Kinnunen@liv.ac.uk
960857
Kolasinska-Zwierz
Paulina
Gurdon Inst
Univ Cambridge
Tennis Court Rd,Cambridgeshire
Cambridge

CB2 1QN
United Kingdom
pmk35@cam.ac.uk
961569
Kugler
Hillel
Computational Biology
Microsoft Research Cambridge
7 JJ Thomson Ave
Cambridge

CB3 0FB
United Kingdom
hkugler@microsoft.com
960851
Kumar
Sujai
Ashworth Laboratories
University of Edinburgh
West Mains Road
Edinburgh

EH9 1HY
United Kingdom
sujai.kumar@ed.ac.uk
960096
Kuwabara
Patricia
Dept Biochem
Univ Bristol
Univ Walk

Bristol

BS8 1TD
United Kingdom
p.kuwabara@bristol.ac.uk
961307
Lagido
Cristina
Sch Medical Sci
Univ Aberdeen
Foresterhill

Aberdeen

AB25 2ZD
United Kingdom
c.lagido@abdn.ac.uk
961526
Laurent
Patrick
Dept Cell Biol
MRC-LMB
Hills Rd

Cambridge

CB2 2QH
United Kingdom
patrick@mrc-lmb.cam.ac.uk
960556
Lehmann
Susann
Graduate Entry Medicine
University of Nottingham
Derby City General Hospital,
Derby

De22 3DT
United Kingdom
mzxsl@exmail.nottingham.ac.uk
960001
Lesa
Giovanni
MRC LMCB
UCL
Gower St

London

WC1E 6BT
United Kingdom
giovanni.lesa@ucl.ac.uk
960042
Marsh
Elizabeth
School of Biosciences
University of Birmingham
Edgbaston

Birmingham
West Midlands
B15 2TT
United Kingdom
EKM454@bham.ac.uk
960071
May
Robin
School of Biosciences
University of Birmingham
Edgbaston

Birmingham

B15 2TT
United Kingdom
r.c.may@bham.ac.uk
961306
McLaggan
Debbie
Inst Med Sci
Univ Aberdeen
Foresterhill, Aberdeen
Aberdeen

AB25 2ZD
United Kingdom
d.mclaggan@abdn.ac.uk
961554
McMullan
Rachel
MRC Cell Biology Unit
University College London
Gower Street

London

WC1E 6BT
United Kingdom
r.mcmullan@ucl.ac.uk
961230
Nurrish
Stephen
MRC LMCB
Univ Col London
Gower St

London

WC1E 6BT
United Kingdom
s.nurrish@ucl.ac.uk
960637
O'Rourke
Delia
Biochem
Univ Oxford
South Parks Rd
Oxford

OX1 3QU
United Kingdom
delia.orourke@bioch.ox.ac.uk
960868
Olahova
Monika
Dept Cell & Molec Biosci
Newcastle Univ
Framlington Place
Newcastle

NE2 4HH
United Kingdom
m.olahova@ncl.ac.uk
961339
Partridge
Frederick
Dept Biochemistry
Univ Oxford
South Parks Rd
Oxford

OX1 3QU
United Kingdom
frederick.partridge@bioch.ox.ac.uk
960177
Polanska
Urszula
Sch Biological Sci
Univ Liverpool
Crown St

Liverpool

L69 7ZB
United Kingdom
ump@liv.ac.uk
961224
Porter
Andrew
MRC Lab Molec Cell Biol
Univ College
Gower Street

London

WC1E 6BT
United Kingdom
a.porter@ucl.ac.uk
960035
Rogers
Anthony
Dept Informatics
Wellcome Trust Sanger Inst
Wellcome Trust Genome Campus
Hinxton

CB10 1SA
United Kingdom
ar2@sanger.ac.uk
960169
Sanders
Matthew
Institute of Healthy Ageing
University College London
Gower Street

London
London
WC1E 6BT
United Kingdom
matthew.sanders05@gmail.com
961217
Savory
Fiona
Biology
University of Leeds
Clarendon Road
Leeds
West Yorkshire
LS2 9JT
United Kingdom
bsfrs@leeds.ac.uk
961419
Schuster
Eugene
GEE
Institute of Healthy Ageing
Gower Street

London

WC1E 6BT
United Kingdom
e.schuster@ucl.ac.uk
960221
Shaw
William
WT CRUK Gurdon Institute
University of Cambridge
Tennis Court Rd
Cambridge

CB2 1QN
United Kingdom
r.shaw@gurdon.cam.ac.uk
960557
Shephard
Freya
Graduate Entry Medicine
University of Nottingham
Derby City General Hospital
Derby

S41 9QW
United Kingdom
freya.shephard@nottingham.ac.uk
960067
Soloviev
Alexander
Biochemistry
University of Bristol
University walk
Bristol

BS8 1TD
United Kingdom
a.soloviev@bristol.ac.uk
960439
Tanizawa
Yoshinori
Cell Biology
MRC Laboratory of Molecular Biol
Hills Road

Cambridge

Cb2 0QH
United Kingdom
tanizawa@mrc-lmb.cam.ac.uk
960300
Valentini
Sara

Univ College London

London
London
WC1E6BT
United Kingdom
s.valentini@ucl.ac.uk
960869
Veal
Elizabeth
Inst Cell & Molec Biosci
Newcastlevim Univ
Framlington Place
Newcastle Tyne
NE2 4HH
United Kingdom
e.a.veal@ncl.ac.uk
961226
Ward
Rachael
Cell Biol Unit
MRC Lab Molec Cell Biol, UCL
Gower St

London

WC1E 6BT
United Kingdom
rachael.ward@ucl.ac.uk
960034
Williams
Gareth
Dept Informatics
Wellcome Trust Sanger Inst
Hinxton

Cambridge

CB10 1SA
United Kingdom
gw3@sanger.ac.uk
960551
Wirtz
Julia
FBS_IICB
Leeds UNiversity
Clarendon Way
Leeds
West Yorkshire
LS2 9JT
United Kingdom
fbsjjw@leeds.ac.uk
960272
Woollard
Alison
Dept Biochemistry
Univ Oxford
South Parks Rd
Oxford

OX1 3QU
United Kingdom
alison.woollard@bioch.ox.ac.uk
961209
Zeiser
Eva
The Gurdon Institute
University of Cambridge
Tennis Court Road
Cambridge

CB2 1QN
United Kingdom
ez226@cam.ac.uk

