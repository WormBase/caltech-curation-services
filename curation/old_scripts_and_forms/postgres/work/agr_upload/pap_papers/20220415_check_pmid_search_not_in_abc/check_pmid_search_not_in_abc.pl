#!/usr/bin/perl -w

# AGR ABC was first loaded on 2021 11 04 with WB data.  On 2022 04 15 we're running a pubmed search like 
# we do at wormbase, subtracting the false positives from remove/rejected, and also removing the 1086 
# paper pending sorting at WB, and ending up with 650 PMIDs to create.  Check they're already in WB.
# 2022 04 15

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my @pmids_in_abc_from_other_mods = qw( 34572100 34502375 34493287 34541157 );
my @pmids_not_in_abc = qw( 32550561 33993517 34250202 34252074 34252079 34259623 34440735 34443430 34462400 34473622 34474090 34476533 34496610 34513830 34532534 34537465 34541042 34541064 34541104 34541200 34545217 34558629 34564452 34567639 34568776 34572007 34572130 34573064 34575973 34576719 34611259 34616504 34633391 34634942 34637983 34639082 34641508 34641727 34652546 34654821 34655094 34655615 34656087 34657571 34661238 34663906 34664387 34666007 34673249 34673804 34675482 34697631 34698395 34699807 34700171 34703208 34703987 34704733 34704753 34718030 34718610 34718716 34720872 34722333 34722339 34722524 34722532 34722819 34722829 34723146 34723150 34723151 34723951 34723964 34724562 34730513 34731674 34732580 34732711 34733055 34734636 34735554 34735889 34736685 34737442 34738904 34739028 34739033 34739048 34740241 34740245 34740247 34740248 34740505 34741504 34741804 34744196 34744409 34744980 34746681 34746683 34746684 34747520 34748534 34748554 34749053 34751671 34752447 34753064 34754139 34755252 34756961 34756991 34759317 34759956 34761061 34761227 34761228 34761293 34761564 34762642 34762652 34764277 34764949 34766550 34766905 34767311 34769047 34771018 34772788 34773966 34774904 34777551 34777768 34778725 34780472 34780740 34785759 34786930 34787570 34787618 34787995 34788833 34791426 34792019 34793277 34793939 34795288 34797853 34798124 34798183 34798755 34799450 34799570 34801608 34803606 34804026 34805162 34806037 34812833 34813661 34815991 34816431 34817059 34818334 34818537 34818546 34818698 34818820 34819841 34820764 34822679 34823984 34824369 34824371 34826343 34826420 34828257 34829568 34829615 34829814 34830158 34830338 34836223 34836956 34837071 34837316 34838796 34841276 34843089 34843219 34843479 34843919 34844120 34846063 34849777 34849789 34849797 34849800 34849851 34849855 34849856 34849872 34849877 34849888 34849889 34850872 34854469 34854875 34856917 34857359 34860542 34861150 34862181 34862187 34863891 34864060 34865044 34866619 34866634 34867289 34868727 34870110 34874004 34875684 34876343 34879088 34879267 34880204 34882258 34882769 34884761 34885907 34889959 34890717 34890989 34893559 34894022 34894114 34894199 34895149 34896182 34896225 34897509 34901019 34902447 34903234 34905692 34906353 34906999 34908132 34908528 34909608 34909687 34913112 34917983 34917984 34918460 34918745 34919931 34921763 34924939 34926464 34926819 34927095 34927098 34927654 34929275 34930663 34933938 34934910 34935822 34938411 34940611 34941747 34941962 34942757 34943966 34944537 34944987 34946833 34947663 34949740 34950447 34951426 34952153 34953889 34957049 34957538 34959730 34959950 34962293 34962383 34964473 34965433 34971598 34972943 34973159 34976860 34977999 34978135 34978283 34981652 34982028 34982771 34982813 34983389 34984305 34985705 34986795 34987416 34988490 34990707 34994051 34994366 34994689 34994802 35005481 35011544 35011662 35013162 35013237 35013421 35015055 35016885 35016908 35017476 35017611 35021096 35022236 35022507 35022791 35027085 35027448 35027456 35030161 35032420 35032657 35035788 35036864 35037068 35038442 35038872 35041685 35042676 35044707 35044945 35045304 35045336 35046576 35046825 35047088 35047763 35047764 35052664 35053361 35065051 35065714 35074444 35074859 35076532 35077157 35077678 35077699 35079060 35081133 35081350 35087668 35088845 35088854 35089376 35089912 35089916 35089924 35092591 35094084 35094091 35098051 35098926 35100258 35100345 35100350 35100363 35100381 35100402 35100990 35101447 35102319 35102684 35107130 35108272 35110557 35110654 35112996 35114355 35115503 35115609 35115715 35118165 35118355 35119366 35119932 35121658 35121747 35124023 35124155 35127981 35128345 35130128 35130129 35132225 35132256 35134179 35134193 35134197 35134340 35134343 35134929 35136057 35136857 35137058 35137093 35138935 35139369 35139370 35139379 35139855 35140229 35140621 35141505 35141506 35142872 35143478 35143646 35143653 35145075 35146399 35146893 35147496 35147953 35148188 35148861 35149688 35156660 35157717 35157921 35158305 35159211 35163796 35165413 35167162 35169683 35170035 35170608 35171008 35171669 35171671 35172320 35173578 35174100 35176147 35176489 35178571 35181336 35181679 35183877 35185414 35188063 35191950 35192599 35192608 35192842 35196311 35197494 35197629 35198555 35198862 35199034 35201867 35201977 35203497 35203579 35205128 35208251 35209312 35215369 35216508 35217630 35218961 35219257 35221123 35223994 35223999 35224462 35224463 35224464 35224786 35226663 35228529 35228596 35229457 35233004 35233102 35234904 35234908 35235368 35235784 35237385 35239681 35239965 35242276 35243236 35244146 35247383 35247454 35252801 35252815 35253240 35254908 35255825 35256540 35256938 35259017 35259092 35259340 35259341 35259831 35259924 35261124 35262739 35263226 35263319 35263583 35266450 35269246 35273616 35274966 35275914 35283340 35283408 35285794 35285800 35286669 35288336 35289422 35294233 35297148 35297663 35298121 35298637 35303431 35306452 35310333 35311461 35311532 35311808 35311815 35311992 35316559 35316617 35317792 35319987 35320557 35320558 35320559 35320560 35320562 35320563 35320564 35320565 35320566 35320567 35320568 35320569 35320570 35320571 35320572 35320573 35320574 35320575 35320576 35320577 35321480 35321659 35322206 35323213 35323874 35323946 35324425 35324758 35334227 35337632 35340273 35344539 35346033 35348662 35348689 35349396 35349791 35349795 35353567 35354038 35360860 35361121 35361529 35362532 35363276 35367457 35368038 35370545 35372802 35373417 35377419 35377421 35377871 35378039 35380658 35380660 35383317 35385645 35388108 35388610 35389463 35390927 35394007 35394033 35394881 35395006 35398354 35399287 35399537 35403008 35403847 35404452 35405114 35411365 35412238 35412295 35413150 35413239 35413267 35413535 35417689 35417695 35418624 35421092 );

my %pmids_to_find;
foreach my $pmid (@pmids_in_abc_from_other_mods, @pmids_not_in_abc) {
  $pmids_to_find{"pmid$pmid"}++;
}
my $pmids_to_find = join"','", sort keys %pmids_to_find;

my %pmids_in_db;
$result = $dbh->prepare( "SELECT * FROM pap_identifier WHERE pap_identifier IN ('$pmids_to_find');" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $pmids_in_db{$row[1]}++;
  } # if ($row[0])
} # while (@row = $result->fetchrow)

foreach my $pmid (sort keys %pmids_to_find) {
  unless ($pmids_in_db{$pmid}) {
    print qq($pmid not in db\n);
  }
  unless ($pmids_in_db{$pmid}) {
    print qq($pmid not in db\n);
  }
} # foreach my $pmid (sort keys %pmids_to_find)

__END__
