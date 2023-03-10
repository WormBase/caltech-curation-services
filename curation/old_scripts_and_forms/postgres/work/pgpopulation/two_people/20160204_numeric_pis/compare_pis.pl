#!/usr/bin/perl -w

# take Aric's PI list, look at numeric lab codes, and see if we can match them to existing WBPersons in two_ tables.  2016 02 04

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %stdname;
$result = $dbh->prepare( "SELECT * FROM two_standardname" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $stdname{$row[0]} = $row[2]; } }

my %pis;
$result = $dbh->prepare( "SELECT * FROM two_pis" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  $pis{$row[2]} = $stdname{$row[0]};
} # while (@row = $result->fetchrow)

my %data;
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


my $fullfile      = 'fullmatch.out';
my $firstinitfile = 'firstinitmatch.out';
my $lastonlyfile  = 'lastonlymatch.out';
my $nomatchfile   = 'nomatch.out';
open (FUL, ">$fullfile") or die "Cannot create $fullfile : $!";
open (FIN, ">$firstinitfile") or die "Cannot create $firstinitfile : $!";
open (LAS, ">$lastonlyfile") or die "Cannot create $lastonlyfile : $!";
open (NOM, ">$nomatchfile") or die "Cannot create $nomatchfile : $!";

my $infile = 'PI_List_for_Todd.txt';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) {
  chomp $line;
  my ($a, $code, $b, $name, $c, $inst) = split/\|/, $line;
  $code =~ s/\s+//g;
  my ($last, $first) = split/, /, $name;
  unless ($first) { $first = ''; }
# next unless ($last eq 'Aamodt');
  if ($code =~ m/[a-zA-Z]/) { 
#     if ($pis{$code}) { print qq(CGC $pis{$code} is $line\n); }
#       else { print qq($code not in two_pis $line\n); }
  } else {
    my %matches; my %cats; my @cats = qw( names initial last);
    if ($data{last}{$last}) {
      foreach my $two ( sort keys %{ $data{last}{$last} } ) { $matches{last}{$two}++; $matches{any}{$two}++; } }
    if ($data{first}{$first}) {
      foreach my $two ( sort keys %{ $data{first}{$first} } ) { $matches{first}{$two}++; $matches{any}{$two}++; } }
    if ($data{firstI}{$first}) {
      foreach my $two ( sort keys %{ $data{firstI}{$first} } ) { $matches{firstI}{$two}++; $matches{any}{$two}++; } }
    my %two;
    foreach my $two (sort keys %{ $matches{any} }) {
      if ( ($matches{last}{$two}) && ($matches{first}{$two}) ) {           $two{names}{$two}++;   }
        elsif ( ($matches{last}{$two}) && ($matches{firstI}{$two}) ) {     $two{initial}{$two}++; }
        elsif ( ($matches{last}{$two}) ) {                                 $two{last}{$two}++;    }
    } # foreach my $two (sort keys %{ $matches{any} })
    if ($two{names}) { 
        my $twos = join(", ", sort keys %{ $two{names} } );
        my $count = scalar keys %{ $two{names} };
        print FUL qq($count\t$name\tTWOS : $twos\tCGC $code\tINST $inst\n);   }
      elsif ($two{initial}) { 
        my $twos = join(", ", sort keys %{ $two{initial} } );
        my $count = scalar keys %{ $two{initial} };
        print FIN qq($count\t$name\tTWOS : $twos\tCGC $code\tINST $inst\n);   }
      elsif ($two{last}) { 
        my $twos = join(", ", sort keys %{ $two{last} } );
        my $count = scalar keys %{ $two{last} };
        print LAS qq($count\t$name\tTWOS : $twos\tCGC $code\tINST $inst\n);   }
      else { print NOM qq(No match\tCGC $code\tINST $inst\n); }
  }
} # while (my $line = <IN>)
close (IN) or die "Cannot close $infile : $!";

close (NOM) or die "Cannot close $nomatchfile : $!";
close (LAS) or die "Cannot close $lastonlyfile : $!";
close (FIN) or die "Cannot close $firstinitfile : $!";
close (FUL) or die "Cannot close $fullfile : $!";

__END__

|EA|,|Aamodt, Eric|,|Lousiana State University Medical Center, Shreveport|
| 771|,|Aamodt, Stephanie|,|Louisiana State University, Shreveport, LA|
|PAB|,|Abad, Pierre|,|INRA LBI, Antibes, France|
|AY|,|Aballay, Alejandro|,|Duke University, Durham, NC|
|RF|,|Abbott, Allison|,|Marquette University, Milwaukee, WI|
|2569|,|Abdel-Rahman, Fawzia|,|Texas Southern University, Houston, TX|
|3235|,|Abe, Koichiro|,|Tokai University School of Medicine, Kanagawa, Japan|
|2433|,|Abel-Santos, Ernesto|,|University of Nevada, Las Vegas, Nevada, NV|
|1578|,|Abeliovich, Asa|,|Columbia University, New York, NY|
|3967|,|Abrahams, Jan Pieter|,|Leiden University, Leiden, The Netherlands|
|EVL|,|Ackley, Brian|,|University of Kansas, Lawrence, KS|
|2427|,|Actis, Luis|,|Miami University, Oxford, OH|
|QE|,|Adachi, Takeshi|,|Kanagawa University, Kanagawa, Japan|
|3309|,|Adam, Christelle|,|IRSN-SERIS-LECO, Cadarache, France|
|2469|,|Adam, G|,|University of Hamburg, Hamburg, Germany|
|ZE|,|Adam, Stephen|,|Northwestern University Medical School, Chicago, IL|
|4074|,|Adamec, Jiri|,|University of Nebraska, Lincoln, NE|
|BAD|,|Adams, Byron|,|Brigham Young University, Provo, UT|
| 580|,|Adams, Dany|,|Smith College, Northampton, MA|
|2030|,|Adams, David|,|Wellcome Trust Sanger Institute, Hinxton, Cambs, England, UK|
|3850|,|Adams, Mark|,|Rothamsted Research, Harpenden, UK|
| 941|,|Adams, Stephen|,|Northwestern University Medical School, Chicago, IL|
|4307|,|Adel, Barbara|,|German University, Cairo, Egypt|
|1865|,|Adelman, Zach|,|Virginia Polytechnic Institute and State University, Blacksburg, VA|
|2678|,|Ademola, IO|,|University of Ibadan, Ibadan, Nigeria|
| 343|,|Adler, Fred|,|University of Utah, Salt Lake City, UT|
|1557|,|Advanced BioNutrition, Inc.|,|Columbia, MD|
|AEB|,|Aebi, Markus|,|ETH Zurich, Zurich, Switzerland|
|3619|,|Aebi, Markus|,|Institute of Microbiology, Zuerich, Switzerland|
|SPU|,|Agapito, Maria|,|St. Peter's University, Jersey City, NJ|
|4135|,|Agastian, Paul|,|Loyola College, Nungambakkam, India|
|2735|,|Aghasadeqi, Mohamad|,|Pasteur Institute of Iran, Tehran, Iran|
| 741|,|Agostini, Elen|,|LNCIB, Trieste, Italy|
|2266|,|Agriculture & Agri-Food Canada|,|Guelph, Ontario, Canada|
| 608|,|Agrium, Inc.|,|Alberta, Canada|
| 848|,|Agudelo, Paula|,|Corporacion para Invest Biol, Medillin, Colombia, South America|
|HGA|,|Aguilaniu, Hugo|,|Ecole Normale Superieure, Lyon, France|
|GIN|,|Aguilera, Andres|,|CAMIMER, Sevilla, Spain|
| 604|,|Aguilera, Renato|,|University of California, Los Angeles, CA|
|3906|,|Agyare, Christian|,|Kwame Nkrumah University of Science and Technology, Kumasi, Ghana|
| 439|,|Ahlf, Dr. W.|,|Technical University Hamburg-Harburg, Hamburg, Germany|
|YA|,|Ahmed, Shawn|,|University of North Carolina, Chapel Hill, NC|
| 900|,|Ahn, Byungchan|,|University of Ulsan, Ulsan, South Korea|
|1863|,|Ahn, Jiyun|,|Korea Food Research Institute, Gyeonggi-do, South Korea|
|KJ|,|Ahnn, Joohong|,|Hanyang University, Seoul, Korea|
|JA|,|Ahringer, Julie|,|University of Cambridge, Cambridge, England|
|4186|,|Ahumada-Solorzano, Santiaga|,|Universidad Autonoma de Queretaro, Queretaro, Mexico|
| 854|,|Aikawa, Jun-ichi|,|RIKEN, Saitama, Japan|
|3273|,|Ailion, Michael|,|University of Washington, Seattle, WA|
|XZ|,|Ailion, Michael|,|University of Washington, Seattle, WA|
|3045|,|Akshatha, H.S.|,|Central Food Technology Research Inst, Mysore, India|
|1104|,|Aksoy, Serep|,|Yale Univesity, New Haven, CT|
|3148|,|Al Mumun, Abdullah|,|National University of Singapore, Singapore|
|3954|,|Al-Abed, Yousef|,|Feinstein Institute, Manhasset, NY|
|2907|,|Al-Banna, Luma|,|University of Jordan, Amman, Jordan|
|2932|,|Al-Mohanna, Futwan|,|King Faisal Specialist Hospital and Research Center, Riyadh, Saudi Arabia|
|3452|,|Al-Saif, Amr|,|King Faisal Specialist Hospital and Research Center, Riyadh, Saudi Arabia|
|2159|,|Alaeddine, Ferial|,|Vetsuisse-Fakultat Universitat Bern, Bern, Switzerland|
|JKA|,|Alan, Jamie|,|Central Michigan University, Mt. Pleasant MI|
|3998|,|Albeck, John|,|University of California, Davis, CA|
|3022|,|Alberts, Arland|,|University of North Texas, Denton, TX|
| 250|,|Alberts, Bruce|,|University of California, San Francisco|
|NZ|,|Albrecht, Dirk|,|Worcester Polytechnic Institute, Worcester MA|
|3702|,|Albuquerque, Patricia|,|Albert Einstein College of Medicine, Bronx, NY|
|QZ|,|Alcedo, Joy|,|Wayne State University, Detroit, MI|
|1380|,|Alexander-Bridges, Maria|,|Massachusetts General Hospital, Cambridge, MA|
|AL|,|Alfonso, Aixa|,|University of Illinois, Chicago, IL|
|QW|,|Alkema, Mark|,|University of Massachusetts, Worcester, MA|
|3770|,|Allan, Victoria|,|University of Manchester, Manchester, England|
|3593|,|Allard, Patrick|,|University of California, Los Angeles, CA|
|3942|,|Allbutt, Haydn|,|University of Sydney, Sydney, Australia|
|4012|,|Allen, Anna|,|Howard University, Washington, DC|
|TA|,|Allen, Taylor and Peters, Maureen|,|Oberlin College, Oberlin, OH|
|3965|,|Allendoerfer, Karen|,|The Innovation Institute, Newtonville, MA|
| 937|,|Allergan, Inc.|,|Irvine, CA|
| 568|,|Almeida, Craig|,|Stonehill College, Easton, MA|
|2074|,|Alonso, Cesar|,|Institut de Ciencies Fotoniques, Castelldefels, Barcelona, Spain|
|3019|,|Alonso, Isabel|,|Inst Biologia Molecular e Celular, Porto, Portugal|
|SAL|,|Alper, Scott|,|National Jewish Health, Denver, CO|
|2377|,|Alvarez, Ashley|,|California Baptist University, Riverside, CA|
|1331|,|Alverdy, J|,|University of Chicago Hospitals, Chicago, IL|
|VAG|,|Alves Gouveia, Viviane|,|Universidade Federal de Minas Gerais, Belo Horizonte, Brazil|
|4323|,|Alves Gouveia, Viviane|,|Universidade Federal de Minas Gerais, Belo Horizonte, Brasil|
|3426|,|Amador, Jose|,|University of Rhode Island, Kingston, RI|
|VT|,|Ambros, Victor|,|University of Massachusetts, Worcester, MA|
| 195|,|American Cyanamid Company|,|Princeton, NJ|
| 638|,|Amichot, Marcel|,|LBI-INRA, Antibes Cedex, France|
|3423|,|Amorepacific Corp.|,|Amorepacific Corp., South Korea|
|1528|,|Ananvoranich, Sirinart|,|University of Windsor, Winsor, Ontario, Canada|
|2771|,|Anbarasu, Kumar|,|Central Food Technological Research Inst, Karnataka, India|
|ECA|,|Andersen, Erik|,|Northwestern University, Evanston, IL|
|2239|,|Andersen, Janet|,|State University of New York, Stony Brook, NY|
|4147|,|Anderson, Jobriah|,|University of New Hampshire, Durham, NH|
| 388|,|Anderson, John|,|Purdue University, West Lafayette, IN|
|1598|,|Anderson, Lamont|,|Colorado College, Colorado Springs, CO|
|2891|,|Anderson, Marilyn|,|La Trobe University, Bundoora, Melbourne, VIC, Australia|
|4182|,|Anderson, Paul|,|Danforth Plant Science Center, St. Louis, MO|
|TR|,|Anderson, Phil|,|University of Wisconsin, Madison, WI|
|3262|,|Angelstorf, Judith|,|Hamburg University of Apllied Sciences, Hamburg, Germany|
|4289|,|Anitei, Mihaela|,|Dresden University of Technology, Dresden, Germany|
|1088|,|Ankri, Serge|,|Rappaport Institute of Medicine, Technion, Haifa, Israel|
|AA|,|Antebi, Adam|,|Max Planck Institute, Cologne, Germany|
|2725|,|Antebi, Adam|,|Baylor College, Houston, TX|
| 679|,|Aoki, Junken|,|University of Tokyo, Tokyo, Japan|
|4223|,|Aoki, Wataru|,|Kyoto University, Kyoto City, Japan|
|SAY|,|Apfeld, Javier|,|Northeastern University, Boston, MA|
|1951|,|Apkhazava, David|,|Iv. Beritashvili Institute of Physiology, Tbilisi, Georgia|
|1896|,|Aqua Bounty Pacific, Inc.|,|San Diego, CA|
|3635|,|Aragao, Francisco|,|Empresa Brasileira de Pesquisa Agropecuária, Brasília, Brasil|
|XH|,|Arai, Hiroyuki|,|University of Tokyo, Tokyo, Japan|
|2130|,|Araki, Isato|,|Iwate University, Iwate, Japan|
|3156|,|Araki, Norie|,|Kumamoto University, Kumamoto, Japan|
| 392|,|Arasu, Prema|,|North Carolina State University, Raleigh, NC|
|2915|,|Arata, Yoichiro|,|Josai University, Saitama, Japan|
|2868|,|Arata, Yukinobu|,|RIKEN Adv Science Inst, Wako, Japan|
|1603|,|Araujo, Adriana|,|Academy of Natural Sciences, Philadelphia, PA|
|3300|,|Archer School for Girls|,|Archer School for Girls, Los Angeles, CA|
|1580|,|Arctander, Peter|,|University of Copenhagen, Copenhagen, Denmark|
|2357|,|Ardehali, Hossein|,|Northwestern University Medical Center, Chicago, IL|
|2044|,|Ardelli, Bernadette|,|Brandon University, Brandon, Manitoba, Canada|
| 846|,|Ardizzi, Joseph|,|Bloomsburg University of Pennsylvania, Bloomsburg, PA|
|MA|,|Arduengo, Michele|,|Morningside College, IA|
|3798|,|Arellano-Carbajal, Fausto|,|Universidad Autonoma de Queretaro, Queretaro, Mexico|
|2199|,|Arenas-Menas, Cesar|,|San Diego State University, San Diego, CA|
|YAR|,|Argon, Yair|,|Children's Hospital of Philadelphia, Philadelphia, PA|
|3684|,|Arisaka, Katsushi|,|University of California, Los Angeles, CA|
|4103|,|Arisan, Elif Damla|,|Istanbul Kultur University, Istanbul, Turkey|
|1769|,|Arizono,|,|Prefectural University of Kumamoto, Kumamoto, City, Japan|
| 957|,|Arlt, John|,|Royal High School, Royal City, WA|
|3890|,|Armengod, M. Eugenia|,|Principe Felipe Research Center, Valencia, Spain|
|1576|,|Armstrong, David|,|National Institute of Environmental Health, Research Triangle Park, NC|
|2529|,|Arnold, Norbert|,|Leibniz Institute of Plant Biochemistry, Halle/Saale, Germany|
|HY|,|Aroian, Raffi|,|UCSD, La Jolla, CA|
| 736|,|Aronoff, Rachel|,|MPI, Heidelberg, Germany|
|3192|,|Aronson, Jessica|,|University of Washington, Seattle, WA|
| 559|,|Arpagaus, Martine|,|INRA DCC, Montpellier, France|
|2335|,|Arratia, Paulo|,|University of Pennsylvania, Philadelphia, PA|
|3933|,|Arriaga, Edgar|,|University of Minnesota, Minneapolis, MN|
|MRS|,|Artal-Sanz, Marta|,|CSIC-Universidad Pablo de Olavide, Sevilla, Spain|
|AUM|,|Arur, Swathi|,|MD Anderson Cancer Center - Univ of Texas, Houston, TX|
|4176|,|Asad, Nadeem|,|Forman Christian College, Lahore, Pakistan|
|HL|,|Asahina, Masako|,|Institute of Parasitology, Branisovska, Czech Republic|
|3709|,|Asami, Yukihiro|,|Kitasato University, Tokyo, Japan|
|MAB|,|Aschner, Michael|,|Albert Einstein College of Medicine, Bronx, NY|
|2411|,|Ashby, Michael|,|University of Oklahoma, Norman, OK|
|NV|,|Ashcroft, Neville|,|University of Sussex, Brighton, England|
|AKA|,|Ashe, Alyson|,|University of Sydney, Sydney, Australia|
|3736|,|Ashizawa, Tetsuo|,|University of Florida, Gainesville, FL|
|KQ|,|Ashrafi, Kaveh|,|University of California, San Francisco, CA|
|2646|,|Asis, Ramon|,|Universidad Nacional de Cordoba, Cordoba, Argentina|
|3252|,|Askew, David|,|University of Cincinnati, Cincinnati, OH|
|BN|,|Askjaer, Peter|,|CABD Universidad Pablo de Olavide, Seville, Spain|
| 328|,|Aso, Teijiro|,|Oklahoma Medical Research Foundation, Oklahoma City, OK|
|1013|,|Aspinwall, Craig|,|Iowa State University, USDOE, Ames, IA|
|2102|,|Atalay, Arzu|,|Ankara University, Anakra, Turkey|
|3783|,|Atighi, Mohammad Reza|,|Tarbiat Modares University, Tehran, Iran|
| 822|,|Atkins, Tim|,|CBD Porton Down, Wiltshire, UK|
|1359|,|Atwood, Craig|,|University of Wisconsin, Madison, WI|
|MSN|,|Audhya, Jon|,|University of Wisconsin, Madison, WI|
| 947|,|Auld, Dr.|,|University of British Columbia, Vancouver, BC, Canada|
|OA|,|Aurelio, Oscar|,|California State University, Fullerton, CA|
|2388|,|Aurora Flight Sciences|,|Cambridge, MA|
|2589|,|Austerberry, Charles|,|Creighton University, Omaha, NE|
|AZ|,|Austin, Judith|,|University of Chicago, IL|
|AU|,|Ausubel, Fred|,|Massachusetts General Hospital, Boston, MA|
|3025|,|Auwerx, Johan|,|Ecole Polytechnique Fédérale de Lausanne, Lausanne, Switzerland|
|1037|,|Aventis CropScience|,|Research Triangle Park, NC|
|1243|,|Avery, Brian|,|Westminster College, Salt Lake City, UT|
|DA|,|Avery, Leon|,|Virginia Commonwealth University, Richmond, VA|
|3095|,|Avila, Daiana|,|Universidade Federal do Pampa, Uruguaiana. Brazil|
|2035|,|Avruch,|,|Massachusetts General Hospital, Boston, MA|
|4056|,|Ayal,|,|Evogene Ltd., Rehovot, Israel|
|4309|,|Aye, Yimon|,|Cornell University, Ithaca, NY|
|4015|,|Ayme-Southgate, Agnes|,|College of Charleston, Charleston, SC|
|1708|,|Azcurra, Julio|,|Universidad de Buenos Aires, Buenos Aires, Argentina|
|ZV|,|Azevedo, Ricardo|,|University of Houston, Houston, TX|
|2232|,|Azim, Muhammad|,|University of Karashi, Karachi, Pakistan|
|2361|,|Azizbekyan, Rudolf|,|Institute of Genetics and Microorganisms, Moscow, Russia|
|1252|,|BASF Plant Science LLC|,|Research Triangle Park, NC|
|2316|,|Babu Y|,|Sri Ramachandra University, Channai, India|
|1770|,|Babu, Ganesh|,|Alagappa University, Tamil Nadu, India|
|BAB|,|Babu, Kavita|,|IISER, Mohali, India|
|4320|,|Bacher, Michael|,|Philipps University Marburg, Marburg, Germany|
|1180|,|Bachman, Eric|,|Harvard Medical School, Boston, MA|
|4020|,|Bachman, Nancy|,|SUNY, Oneonta, NY|
|2582|,|Baehr, Wolfgang|,|Moran Eye Center, Salt Lake City, UT|
|3920|,|Baek, Won-Ki|,|Keimyung University School of Medicine, Daegu, South Korea|
|CFB|,|Baer, Charles|,|University of Florida, Gainesville, FL|
|1442|,|Bahaji, Abdellatif|,|California State University, Fresno, CA|
|SBW|,|Bahmanyar, Shirin|,|Yale University, New Haven, CT|
|BJH|,|Bai, Jihong|,|FHCRC, Seattle, WA|
|1121|,|Baik, Suejeong|,|Kyunghee University, Seoul, Korea|
|BC|,|Baillie, Dave|,|Simon Fraser University, Vancouver, BC|
|3523|,|Baillie, Leslie|,|Cardiff University, Cardiff, United Kingdom|
|2576|,|Bainton, Roland|,|University of California, San Francisco, CA|
|PB|,|Baird, Scott|,|Wright State University, Dayton, OH|
|2025|,|Bais, Harsh|,|University of Delaware, Newark, DE|
|3790|,|Bajc, Gregor|,|University of Ljubljana, Ljubljana, Slovenia|
| 188|,|Bakaev, V|,||
|2209|,|Baker, Dianne|,|University of Mary Washington, Fredericksburg, VA|
|3485|,|Baker, Keith|,|Virginia Commonwealth University, Richmond, VA|
|2366|,|Baker, Kimberly|,|University of Wisconsin, Green Bay, WI|
|2943|,|Bakker, Hans|,|Hannover Medical School, Hannover, Germany|
|3221|,|Bakshi, Diprabhanu|,|Syngene International Ltd, Bangalore, India|
|3532|,|Balamurugan, K.|,|Alagappa University, Karaikudi, India|
| 623|,|Balanzino, Luis|,|INSERM, France|
|JB|,|Baldwin, James|,|UC Riverside, Riverside, CA|
|ZIB|,|Balklava, Zita|,|Aston University, Birmingham, UK|
|3677|,|Ball, Lori|,|University of Northern Colorado, Greeley, CO|
|1409|,|Ballard|,|University of Oklahoma, Norman, OK|
| 706|,|Ballweber, Lora|,|Mississippi State University, MS|
|1538|,|Balser, Jeff|,|Vanderbilt University, Nashville, TN|
|FY|,|Bamber, Bruce|,|University of Toledo, Toledo, OH|
|1124|,|Bamford, DH|,|University of Helsinki, Helsinki, Finland|
|3544|,|Bamps, Sophie|,|Culture in vivo ASBL, Nivelles, Belgium|
|1261|,|Banas, Jeff|,|Albany Medical College, Albany, NY|
|3268|,|Bandyopadhyay, Jaya|,|West Bengal University of Technology, Kolkata, India|
|2106|,|Banerjee, Diya|,|Virginia Tech, Blacksburg, VA|
|2167|,|Bankaitis, Vytas|,|University of North Carolina, Chapel Hill, NC|
|3198|,|Banks, Travis|,|Vineland Research & Innovation Centre, Vineland Station, ON, Canada|
|BAN|,|Bano, Daniele|,|German Centre Neurodegenerative Diseases (DZNE), Bonn, Germany|
| 489|,|Bany, Patricia|,|Islip Public Schools, Islip, NY|
|3398|,|Bao, Bin|,|Hefei University of Technology, Anhui, China|
|2513|,|Bao, Shorgan|,|Inner Mongolia University, Hohhot, China|
|BV|,|Bao, Zhirong|,|Memorial Sloan-Kettering Cancer Center, New York, NY|
|OY|,|Baran, Renee|,|Occidental College, Los Angeles, CA|
|4266|,|Baranova, Ancha|,|George Mason University, Manassas, VA|
|2092|,|Barbeau, Benoit|,|Ecole Polytechnique de Montreal, Montreal, Quebec, Canada|
|3802|,|Barea-Rodriguez, Edwin|,|University of Texas, San Antonio, TX|
|CX|,|Bargmann, Cori|,|Rockefeller University, New York, NY|
|JBC|,|Bargonetti, Jill|,|City University of New York, New York, NY|
|MBA|,|Barkoulas, Michalis|,|Imperial College, London, UK|
|1629|,|Barnes, Joni|,|Idaho National Laboratory, Idaho Falls, ID|
|PT|,|Barr, Maureen|,|Rutgers University, Piscataway, NJ|
|2279|,|Barrett, J|,|Aberystwyth University, Ceredigion, Wales, UK|
|XU|,|Barrett, Peter|,|Xavier University, New Orleans, LA|
|2148|,|Barrilleaux, Anne|,|Loyola University, New Orleans, LA|
|BAR|,|Barrios, Arantza|,|University College, London, UK|
| 471|,|Barroso, Margarida|,|University of Virginia, Charlottesville, VA|
|1698|,|Barsby, Todd|,|University of Ontario Institute of Technology, Oshawa, ON, Canada|
|RB|,|Barstead, Robert|,|Oklahoma Med Research Foundation, Oklahoma City, OK|
| 547|,|Barta, Terese|,|University of Wisconsin, Stevens Point, WI|
|DPB|,|Bartel, David|,|Whitehead Institute, Cambridge, MA|
|3351|,|Barton, Hazel|,|University of Akron, Akron, OH|
| 901|,|Bartram, Steve|,|Rancho Buena Vista High School, Vista, CA|
|2591|,|Baskerville, Karen|,|Lincoln University, Lincoln University, PA|
|BB|,|Bass, Brenda|,|University of Utah, Salt Lake City, UT|
| 323|,|Bass, Harry|,|Virginia Union University, Richmond, VA|
|2261|,|Bassler, Bonnie|,|Princeton University, Princeton, NJ|
|NS|,|Basson, Michael|,|Axys Pharmaceuticals, Inc., South San Francisco, CA|
|MJB|,|Bastiani, Michael|,|University of Utah, Salt Lake City, UT|
|3630|,|Batchelder, Ellen|,|Unity College, Unity, Maine|
|2253|,|Bates, Katherine|,|California State University Dominguez Hills, Carson, CA|
|1392|,|Batey, Robert|,|University of Colorado, Boulder, CO|
|4345|,|Batista Ferreira, Julio Cesar|,|University of Sao Paulo, Sao Paulo, Brazil|
| 765|,|Batten, Elizabeth|,|East Carolina University, Greenville, NC|
|3548|,|Bauer, April|,|Webster University, Webster Groves, MO|
|3545|,|Bauer, Deborah|,|Wellesley College, Wellesley, MA|
|2477|,|Bauer, Stefan|,|Philipps Universitat Marburg, Marburg, Germany|
|LRB|,|Baugh, Ryan|,|Duke University, Durham, NC|
|1996|,|Baulieu, Emile|,|Kremlin Bicetre Hospital, Kremlin-Bicetre Cedex, France|
| 411|,|Baum, Thomas|,|Iowa State University, Ames, IA|
|BR|,|Baumeister, Ralf|,|Albert-Ludwigs University, Freiburg, Germany|
|3253|,|Bavari, Sina|,|USAMRIID, Fort Detrick, Frederick, MD|
|3275|,|Bayele, Henry|,|University College London, London, UK|
|1666|,|Bayer Health Care|,|Wuppertal, Germany|
| 541|,|Bayer, Inc.|,|Davis, CA|
|HB|,|Baylis, Howard|,|University of Cambridge, U.K.|
|3666|,|Baynham, Patrica|,|St. Edward's University, Austin, TX|
|NA|,|Bazzicalupo, Paolo* & DiSchiavi, Elia|,|IBBR, Naples, Italy|
|1275|,|Bazzoni, Gianfranco|,|Istituto di Ricerche Farmacologiche Mario Negri, Milano, Italy|
|1522|,|Beale, Elmus|,|Texas Tech University, Lubbock, TX|
| 348|,|Beanan, Maureen|,|Spring Hill College, Mobile, AL|
|2054|,|Beaster-Jones, Laura|,|Augustana College, Sioux Falls, SD|
| 475|,|Beck, Barbara|,|Rochester Community and Technical College, Rochester, MN|
|UU|,|Beckerle, Mary|,|University of Utah, Salt Lake City, UT|
|1438|,|Beckman, Kenny|,|Children's Hospital Oakland Research Institute, Oakland, CA|
|3021|,|Beckman, Matthew|,|Augsburg College, Minneapolis, MN|
|2760|,|Becnel, James|,|USDA-ARS, Gainesville, FL|
| 282|,|Beebie, David|,|Beekmantown Central High School, Plattsburgh, NY|
|2628|,|Beech, Robin|,|McGill University, Ste. Anne de Bellevue, Quebec, Canada|
|1669|,|Beer, Mike|,|Johns Hopkins University, Baltimore, MD|
|2675|,|Beers, Melissa|,|Wellesley College, Wellesley, MA|
|BEG|,|Beg, Asim|,|University of Michigan, Ann Arbor, MI|
|3579|,|Beggs, John|,|Indiana University, Bloomington, IN|
| 502|,|Behe, Michael|,|Lehigh University, Bethlehem, PA|
|1797|,|Behl, Christian|,|University of Mainz, Mainz, Germany|
|WT|,|Behm, CA|,|The Australian National University, Canberra, Australia|
| 880|,|Beitel, Greg|,|Northwestern University, Evanston, IL|
|1513|,|Belas, Robert|,|University of Maryland Biotechnology Institute, Baltimore, MD|
|1427|,|Bell, David|,|University of Nottingham, Nottingham, UK|
|2558|,|Bellen, Hugo|,|Baylor College of Medicine, Houston, TX|
| 402|,|Bellman, B|,|College of Mt. St. Joseph, Cincinatti, OH|
|CPV|,|Bellotti, Vittorio & Stoppini, Monica|,|University of Pavia, Pavia, Italy|
| 535|,|Beloin, Nadine|,|University of Ottawa, Ontario, Canada|
|1066|,|Belostotsky, Dmitry|,|State University of New York, Albany, NY|
| 669|,|Belt, Angela|,|Sonora High School|
|4335|,|Beltz, Jason|,|Beaver Area High School, Beaver, PA|
|JAB|,|Bembenek, Joshua|,|University of Tennessee, Knoxville, TN|
|ABY|,|Ben-Yakar, Adela|,|University of Texas, Austin, TX|
|ABZ|,|Ben-Zvi, Anat|,|Ben Gurion University, Beer Sheva, Israel|
|VQ|,|Benard, Claire|,|University of Massachusetts Medical School, Worcester, MA|
|2535|,|Bendena, William|,|Queen's University, Kingston, Ontario, Canada|
|4070|,|Bender, Aaron|,|University of Kansas, Lawrence, KS|
|3191|,|Bendrick-Peart, Jamie|,|Novus Biologicals LLC, Littleton, CO|
|2482|,|Benedetti, Celso|,|Laboratorio Nacional de Luz Sincrotron, Campinas, SP, Brazil|
|GB|,|Benian, Guy|,|Emory University, Atlanta, GA|
|1786|,|Benin, Joseph|,|Madurai Kamaraj University, Tamilnadu, India|
| 245|,|Benner, Steven|,|Laboratory for Organic Chemistry, Zurich, Switzerland|
|KB|,|Bennett, Karen|,|University of Missouri, Columbia|
| 398|,|Bennett, Vann|,|Duke University Medical Center, Durham, NC|
|2312|,|Benovic, Jeffrey|,|Thomas Jeffeson University, Philadelphia, PA|
|4357|,|Benseny, Nuria|,|ALBA Synchrotron, Barcelona, Spain|
|3419|,|Benson, Fiona|,|Lancaster University, Lancaster, UK|
|1820|,|Benson, Tom|,|California State University, San Bernardino, CA|
|TMB|,|Benzing, Thomas|,|University of Cologne, Cologne, Germany|
|2733|,|Benzon, Gary|,|Benzon Research Inc., Carlisle, PA|
|BER|,|Berezikov, Eugene|,|Hubrecht Institute, Utrecht, The Netherlands|
|1647|,|Berger-Bachi, Brigitte|,|University of Zurich, Zurich, Switzerland|
|2465|,|Berghard, Anna|,|Umea University, Umea, Sweden|
|2889|,|Berghorn, Kathy|,|Agave BioSystems, Ithaca, NY|
|2021|,|Bergman, Jorieke|,|University Medical Center of Groningen, Groningen, The Netherlands|
|3099|,|Bergman, Molly|,|UTHSCSA, San Antonio, TX|
|1645|,|Berkes, Charlotte|,|Colorado College, Colorado Springs, CO|
|1304|,|Berkovits, Holly|,|Merrimack College, North Andover, MA|
| 870|,|Berkowitz, Laura|,|University of Tulsa, Tulsa, OK|
| 803|,|Berninsone, Patricia|,|University of Nevada, Reno, NV|
| 716|,|Bernstein, Alan|,|Samuel Lunenfeld Research Institute, Toronto, Ontario, Canada|
|MBM|,|Berriman, Matt|,|Wellcome Trust Sanger Institute, Cambridge, UK|
|1459|,|Bertozzi,|,|University of California, Berkeley, CA|
|VBS|,|Bertrand, Vincent|,|IBDML, Marseille, France|
|1853|,|Bertrandy, Solange|,|University of Paris-Sud, Orsay Cedex, France|
|EN|,|Bessereau, Jean-Louis|,|Universite Claude Bernard Lyon 1, Lyon, France|
|1318|,|Betschart, Bruno|,|University of Neuchatel, Neuchatel, Switzerland|
|JCB|,|Bettinger, Jill|,|Virginia Commonwealth University, Richmond, VA|
| 756|,|Bettler, Don|,|Berry College, Mount Berry, GA|
|2665|,|Betzig, Eric|,|HHMI-Janelia Farm Research Campus, Ashburn, VA|
|1033|,|Beuchat, Larry|,|University of Georgia, Griffin, GA|
|1306|,|Bhadra, Utpal|,|Center for Cellular and Molecular Biology, Hydrabad, India|
|BHL|,|Bhalla, Needhi|,|University of California, Santa Cruz, CA|
|3110|,|Bhat, Sarita|,|Cochin University of Science & Tech, Kerala, india|
|4166|,|Bialkowska, Kamilia|,|BioNanoPark, Lodz, Poland|
|3599|,|Bian, Po|,|CAS, Hefei Institutes of Physical Science, Hefei, Anhui, China|
|BLC|,|Bianchi, Laura|,|University of Miami, Miami, FL|
|1551|,|Bibb,|,|University of Texas Southwestern Medical Center, Dallas, TX|
| 409|,|Bierkens, Johan|,|VITO, Boeretang, Belgium|
| 812|,|Bignell, Colin|,|University of Birmingham, U.K.|
|1350|,|Bignone, Franco|,|IST National Cancer Institute, Genova, Italy|
|1308|,|Bills, Gerald|,|Merck Sharp & Dohme, Madrid, Spain|
|2965|,|Bin Liang|,|Kunming Institute of Zoology, CAS, Kunming, Yunnan, China|
| 329|,|Bingman, Ken|,|Shawnee Mission West High School, Shawnee Mission, KS|
| 589|,|Bio 101, Inc.|,|Vista, CA|
|3211|,|Bio-Rad Labs|,|Bio Ed, Bio-Rad Labs, Hercules, CA|
|3410|,|Biology Dept|,|University of the Fraser Valley, Abbotsford, BC, Canada|
|1397|,|Biomol International, LP|,|Plymouth Meeting, PA|
|1888|,|Biopolis, S.L.|,|Valencia, Spain|
| 842|,|Bioworld|,|Dublin, OH|
|AB|,|Bird, Alan|,|CSIRO Adelaide, Australia|
|DB|,|Bird, David|,|North Carolina State University, Raleigh, NC|
|INV|,|Biron, David|,|University of Chicago, Chicago, IL|
| 232|,|Bishop, John|,|University of Richmond, VA|
| 301|,|Bisset, Stewart|,|Wallaceville Animal Research Centre, Upper Hutt, New Zealand|
|3778|,|Bissoqui, Lucas Yamasaki|,|Federal University of Parana, Curitiba - PR, Brazil|
|2426|,|Bizat, Nicolas|,|University of Paris, Paris, France|
|2976|,|Bizat, Nicolas|,|INSERM Equipe Maladies d'Alzheimer et à prion, Paris, France|
|1604|,|Bjornlund, Lisa|,|Agricultural University of Denmark, Frederiksberg, Denmark|
|3781|,|Black, Bruce|,|FMC Corporation, Philadelphia, PA|
|2967|,|Blackmon, Ronald|,|Elizabeth City State University, Elizabeth City, NC|
|LD|,|Blackwell, Keith|,|Harvard Medical School, Boston, MA|
|OEB|,|Blacque, Oliver|,|University College, Dublin, Ireland|
|BY|,|Blakely, Randy|,|Vanderbilt University, Nashville, TN|
|3584|,|Blanar, Christopher|,|Nova Southeastern University, Fort Lauderdale FL|
|1411|,|Blaser, Martin|,|NYU Sacklers Institute, New York, NY|
|ED|,|Blaxter, Mark|,|University of Edinburgh, Edinburgh, Scotland|
|3621|,|Bloch Qazi, Margaret|,|Gustavus Adolphus College, Saint Peter, MN|
|1697|,|Bloomquist,|,|Virginia Tech, Blacksburg, VA|
|2153|,|Bloss, Tim|,|James Madison University, Harrisonburg, VA|
|2740|,|Blough, Eric|,|Marshall University, Huntington, WV|
|1193|,|Bluebaum-Gronau, Elke|,|Federal Institute of Hydrology, Koblenz, Germany|
|1490|,|Blumelhuber, Gerrit|,|Technical University Munich, Freising-Weihenstephan, Germany|
|BL|,|Blumenthal, Tom|,|University of Colorado, Boulder, CO|
| 433|,|Blystone, Robert|,|Trinity University, San Antonio, TX|
|PRB|,|Boag, Peter|,|Monash University, Clayton, VIC, Australia|
|4209|,|Boedeker, Betsy|,|St. Louis Community College, St. Louis, MO|
|2452|,|Boehmer, Christoph|,|University of Duisburg-Essen, Essen, Germany|
|UG|,|Bogaert, Thierry|,|DevGen NV, Zwijnaarde, Belgium|
|2191|,|Bohach, Gregory|,|University of Idaho, Moscow, ID|
|3815|,|Bohland, Cynthia|,|Roanoke Valley Governor's School for Science & Tech, Roanoke, VA|
|2137|,|Bolger, Molly|,|Center for Science Outreach, Vanderbilt University, Nashville, TN|
|2719|,|Bolhuis, Albert|,|University of Bath, Bath, UK|
| 391|,|Bollinger, John|,|Montana State University, Bozeman, MT|
|2383|,|Bonatto, Diego|,|Universidade de Caxias do Sul, Caxias Do Sul, Brazil|
|2555|,|Bonini, Nancy|,|University of Pennsylvania, Philadelphia, PA|
|3015|,|Bonner, Jennifer|,|Skidmore College, Saratoga Springs, NY|
|2843|,|Bonzom, Jean-Marc|,|Inst for Radioprotection & Nuclear Safety, St-Paul-lez-Durance, France|
|3134|,|Borghi, Elisa|,|Universita degli Studi di Milano, Milan, Italy|
|GBG|,|Borgonie, Gaetan|,|Gent University, Belgium|
|1383|,|Bories, Christian|,|CNRS, Chatenay-Malabry, France|
|FZ|,|Bos, JL|,|Utrecht University, Utrecht, The Netherlands|
| 950|,|Bosse, Carolyn|,|Grinnell College, Grinnell, IA|
|OLB|,|Bossinger, Olaf|,|Inst of Anatomy I, Molecular & Cellular Biology, Cologne, Germany|
|3515|,|Bott, Brenda|,|Shawnee Mission West High School, Overland Park, KS|
|3791|,|Bou Arevelo, German|,|Complexo Hospitalario Universitario de A Coruna, Coruna, Spain|
|2405|,|Bouarab, Kamal|,|University of Sherbrooke, Sherbrooke, Canada|
| 656|,|Bouchard, Joseph|,|Center for Advanced Biotechnology, Boston University, Boston,|
|3007|,|Boucias, Drion|,|University of Florida, Gainesville, FL|
|2882|,|Boudko, Dmitri|,|Rosalind Franklin University, Chicago, IL|
|JIP|,|Boulin, Thomas|,|Universite Claude Bernard, Lyon, France|
|DW|,|Boulton, Simon|,|ICRF Clare Hall, South Mimms, UK|
|1184|,|Bourgaize, David|,|Whittier College, Whittier, CA|
|3313|,|Boussard, Paule|,|Universite Libre de Bruxelles, Bruxelles, Belgium|
|4237|,|Bouvier, Jacque|,|Novartis Animal Health Inc., Basel, Switzerland|
|2457|,|Bouzat, Cecilia|,|Insituto de Investigaciones Bioquimicas, Bahia Blanca, Argentina|
| 327|,|Bowden, Bradley|,|Alfred University, Alfred, NY|
|EU|,|Bowerman, Bruce|,|University of Oregon, Eugene|
|4017|,|Bowman, Elizabeth|,|William Peace University, Raleigh, NC|
|BOX|,|Boxem, Mike|,|Utrecht Univeristy, Utrecht, The Netherlands|
|2885|,|Boyd, Fidelma|,|Univ of Delaware, Newark, DE|
| 520|,|Boyd, Lynn|,|Denison University, Granville, OH|
|LN|,|Boyd, Lynn|,|University of Alabama, Huntsville, AL|
|4028|,|Boyden, Ed|,|Massachusetts Institute of Technology, Cambridge, MA|
|1107|,|Boyle, Jon|,|University of Wisonsin, Madison, WI|
| 367|,|Bradley, Brian|,|University of Maryland, Baltimore, MD|
|3396|,|Bradley, W. Guy|,|Tampa Bay Research Institute, St. Petersburg, FL|
|2632|,|Bradon, Nicole|,|Stanford University, Stanford, CA|
|2571|,|Bradshaw, Patrick|,|University of South Florida, Tampa, FL|
|NIC|,|Braendle, Christian|,|University of Nice, Nice, France|
| 983|,|Brand, Debora|,|Universidad Federal do Parana, Parana, Brazil|
|2472|,|Brand, Martin|,|Buck Institute, Novato, CA|
|2223|,|Branda, Catherine|,|Sandia National Labs, Livermore, CA|
| 845|,|Brandl, Maria|,|USDA/ARS, Albany, CA|
|CPB|,|Brangwynne, Cliff|,|Princeton University, Princeton, NJ|
|2495|,|Brassinga, Ann Karen|,|University of Manitoba, Winnipeg, MB, Canada|
|2217|,|Bratanich, Ana|,|Universidad de Buenos Aires, Buenos Aires, Argentina|
| 432|,|Brault, Solange|,|UMass, Boston, MA|
|3919|,|Bravo, Alejandra|,|National Autonomous University of Mexico, Mexico City, Mexico|
|EAG|,|Breckenridge, David|,|Florida Institute of Technology, Melbourne, FL|
| 943|,|Breimer, Michael|,|Sahlgrenska University Hospital, Goteborg, Sweden|
|2989|,|Brenkman, Arjen|,|Wilhelmina Childrens Hospital, Utrecht, The Netherlands|
|2869|,|Brenner, Eric|,|New York Univ, New York, NY|
| 618|,|Brenner, Kerry|,|Princeton University, Princeton, NJ|
|RBW|,|Brent, Roger|,|Fred Hutchinson Cancer Research Center, Seattle, WA|
|1847|,|Bretscher, Anthony|,|Cornell University, Ithaca, NY|
|2975|,|Brey, Christopher|,|Marywood University, Scranton, PA|
|2588|,|Briceno, Lisett|,|Universidad de Los Andes, Merida, Venezuela|
|1683|,|Brickley, Mark|,|Oral Biology Research Group. Somerset, UK|
|1729|,|Brickman, Peggy|,|University of Georgia, Athens, GA|
| 929|,|Bridger, Joanna|,|Brunel University, Middlesex, U.K.|
|1944|,|Brignull, Heather|,|University of Wisonsin, Eau Claire, WI|
|HBR|,|Bringmann, Henrik|,|Max Planck Inst - Biophysical Chemistry, Gottingen, Germany|
|3902|,|Brinkhoff, Thorsten|,|University of Oldenburg, Oldenburg, Germany|
|1419|,|Brisch, Ellen|,|Minnesota State University, Moorhead, MN|
| 283|,|Bristol-Myers Squibb Co.|,|Pennington, NJ|
|3503|,|Britt, Jeremy|,|University of Iowa, Iowa City, IA|
|1975|,|Brittingham, Jacqueline|,|Simpson College, Indianola, IA|
|CLB|,|Britton, Collette|,|University of Glasgow, Glasgow, Scotland|
|1466|,|Broad, Sam|,|University of Leeds, Leeds, U.K.|
|1250|,|Broadaway, Susan|,|Montana State University, Bozeman, MT|
|4192|,|Brocco, Marcela|,|University of San Martin, Buenos Aires, Argentina|
|NX|,|Broday, Limor|,|Tel Aviv University, Tel Aviv, Israel|
| 365|,|Brodeur, Richard|,|West Texas A & M University, Amarillo, TX|
|2492|,|Brooker, Rob|,|University of Minnesota, Minneapolis, MN|
|1594|,|Brooks, Darren|,|University of Salford, Salford, UK|
|1214|,|Brophy, Peter|,|University of Liverpool, Liverpool, UK|
|3307|,|Brouhard, Gary|,|McGill University, Montreal, Quebec, Canada|
|1338|,|Broussard, Christine|,|University of La Verne, La Verne, CA|
|OMG|,|Brown, Andre|,|Imperial College, London, UK|
|2848|,|Brown, Frederico|,|Universidad de los Andes, Bogota, Colombia|
|3530|,|Brown, Heather|,|American River College, Sacramento, CA|
|2320|,|Brown, Jonathan|,|Grinnell College, Grinnell, IA|
|3049|,|Brown, Paul|,|University of the West Indies at Mona, Kingston, Jamaica|
| 516|,|Brown, Robert|,|The Rockefeller University, New York, NY|
| 227|,|Brown, Scott|,|San Diego, California|
|4220|,|Brown, Sigal|,|Plant Protection Institute, Beit Dagan, Israel|
| 639|,|Brownlie, Jeremy|,|CSIRO Div of Plant Indust, Canberra, ACT, Australia|
|BX|,|Browse, John|,|Washington State University, Pullman, WA|
|3536|,|Bruckbauer, Antje|,|NuSirt Sciences Inc., Knoxville, TN|
|1278|,|Bruick, Richard|,|University of Texas Southwestern Medical Center, Dallas, TX|
|FF*|,|Brun, J|,|Universite Claude Bernard (Lyon-I), Lyon, France|
|3233|,|Brundin, Patrik|,|Van Andel Institute, Grand Rapids, MI|
|ABR|,|Brunet, Anne|,|Stanford University, Stanford, CA|
|IB|,|Brunet, Jean-Francois|,|IBDM, Marseille, France|
| 317|,|Brunet, Pascale|,|IGBMC, France|
|2857|,|Brusco, Alfredo|,|University of Turin, Italy|
|2671|,|Bubeck Wardenburg, Juliane|,|University of Chicago, Chicago, IL|
|3948|,|Bubenko, Jennifer|,|MacEwan University, Edmonton, Alberta, Canada|
|EE|,|Bucher, Beth|,|University of Pennsylvania, Philadelphia|
|2382|,|Buck, Linda|,|Fred Hutchinson Cancer Research Center, Seattle, WA|
|2928|,|Buckling, Angus|,|University of Oxford, Oxford, UK|
|3699|,|Budge, Philip|,|Vanderbilt University Medical Center, Nashville, TN|
|3246|,|Budovskaya, Yelena|,|University of Amsterdam, Amsterdam, The Netherlands|
|BK|,|Buechner, Matthew|,|University of Kansas, Lawrence, KS|
|EB|,|Buelow, Hannes|,|Albert Einstein College of Medicine, Bronx, NY|
|4175|,|Bueno, Juan Gabriel|,|Anadolu University, Eskisehir, Turkey|
|3493|,|Buettner, Christopher|,|Mount Sinai School of Medicine, New York, NY|
|2556|,|Buford, TD|,|University of Southern Mississippi, Hattiesburg, MS|
|4035|,|Bukau, Bernd|,|Ruprecht-Karls-Universität Heidelberg, Heidelberg, Germany|
|2712|,|Bumgarner, Stacie|,|Suffolk University, Boston, MA|
|1795|,|Bun-Ya, Masanori|,|Tokushima Bunri University, Kagawa, Japan|
| 688|,|Bun-ya, Masanori|,|Hiroshima University, Hiroshima, Japan|
|3040|,|Bundy, Jake|,|Imperial College at Silwood Park, Ascot, Berks, UK|
| 932|,|Bunn, H. Franklin|,|Brigham and Women's Hospital, Boston, MA|
|1885|,|Burch Alden, April|,|Wadsworth Center for Laboratories and Research, Albany, NY|
|3484|,|Burch, April|,|Berkshire School, Sheffield, MA|
|1048|,|Bureau, Thomas|,|McGill University, Montreal, Quebec, Canada|
|3500|,|Buret, Andre|,|University of Calgary, Calgary, Canada|
|1329|,|Burger, Johan|,|Stellenbosch University, Matieland, South Africa|
|3824|,|Burger, Marcos|,|Universidade Federal do Rio Grande, Rio Grande, Brazil|
|TB|,|Burglin, Tom|,|Karolinksa Institute, Huddinge, Sweden|
|MB|,|Burnell, Ann|,|St. Patrick's College, Maynooth, Co. Kildare, Ireland, UK|
| 451|,|Burnison, B. Kent|,|National Water Research Institute, Burlington, Canada|
|1970|,|Burns, Roxanne|,|Kent State University, East Liverpool, OH|
|3269|,|Burt, Austin|,|Imperial College London, London, UK|
| 405|,|Burtis, Ken|,|University of Calfornia, Davis, CA|
| 252|,|Burton, Alice|,|Biology Department, St. Olaf College, Northfield, MN|
|4024|,|Burton, Gerardo|,|Universidad de Buenos Aires, Buenos Aires, Argentina|
|KL|,|Busch, Karl Emanuel|,|University of Edinburgh, Edinburgh, Scotland|
|1524|,|Bush, Jason|,|The Burnham Institute, La Jolla, CA|
|1702|,|Butala, Matej|,|University of Ljubljana, Ljubljana, Slovenia|
|RAB|,|Butcher, Rebecca|,|University of Florida, Gainesville, FL|
|1962|,|Butlin, Roger|,|University of Sheffield, Sheffield, U.K.|
|EAB|,|Buttner, Edgar|,|McLean Hospital, Belmont, MA|
|3496|,|Byers, Breck|,|University of Washington, Seattle, WA|
|2247|,|Bystrom, Anders|,|Umea University, Umea, Sweden|
|2394|,|Bystrom, Anders|,|Umea University, Sweden|
|IFM|,|C. elegans Facility of FMI|,|Friedrich Miescher Inst, Basel Switzerland|
|1991|,|CH2M Hill|,|Corvallis, OR|
|JCP|,|Cabello, Juan|,|Center for Biomedical Research of La Rioja, Logrono, Spain|
|4160|,|Cabreira Soares, Letiere|,|Universidade Federal da Fronteria Sul, Rodovia, Puerto Rico|
|4021|,|Cabreiro, Felipe|,|University College London, London, UK|
|3304|,|Cadigan, Ken|,|University of Michigan, Ann Arbor, MI|
|CGC|,|Caenorhabditis Genetics Center|,|University of Minnesota, Minneapolis, MN|
|2930|,|Cai, Dongsheng|,|Albert Einstein College of Medicine, Bronx, NY|
|1973|,|Cai, Jun|,|Nankai University, Tianjn, China|
|3372|,|Cai, Long|,|California Institute of Technology, Pasadena, CA|
|SQC|,|Cai, Shi-Qing|,|Shanghai Institutes for Biological Sciences, Shanghai, China|
|3460|,|Cai, Waijiao|,|Huashan Hospital, Fudan University, Shanghai, China|
|4341|,|Caiger, Steve|,|Sibelius Ltd., Oxford, UK|
|2916|,|Caillaud, Marina|,|Ithaca College, Ithaca, NY|
|3204|,|Cairl, Rob|,|University of Massachusetts, Amherst, MA|
|JAC|,|Calarco, John|,|Harvard University, Cambridge, MA|
| 739|,|Calderon-Urrea, Alejandro|,|California State University, Fresno, CA|
|SKC|,|Calderwood, Stuart|,|Harvard Medical School, Boston, MA|
|UA|,|Caldwell, Guy|,|University of Alabama, Tuscaloosa, AL|
|WCH|,|Calixto, Andrea|,|Universidad Mayor, Santiago, Chile|
|3323|,|Camacho, Susan & Le Coutre, Johannes|,|Nestle Research Center, Lausanne, Switzerland|
|4016|,|Camarena, Miguel|,|OpenWorm, Zapopan, Mexico|
|DL|,|Cameron, Scott|,|UT Southwestern Medical Center, Dallas, TX|
|2429|,|Cammer, Paul|,|Neuroscience Research Laboratory, Alexandria, VA|
|1718|,|Campanella, James|,|Montclair University, Montclair, NJ|
| 430|,|Campbell, Kevin|,|University of Iowa, Iowa City, IA|
|4295|,|Campbell, Zachary|,|University of Texas, Dallas, TX|
|1083|,|Candas, Mehmet|,|Universitiy of Texas, Dallas, TX|
|PC|,|Candido, Peter|,|University of British Columbia, Vancouver|
|JCC|,|Canman, Julie|,|Columbia University Medical Center, New York, NY|
|2923|,|Cao, Y Charles|,|University of Florida, Gainesville, FL|
| 781|,|Caplan, Allan|,|University of Idaho, Moscow, ID|
|1871|,|Cappello, Michael|,|Yale University, New Haven, CT|
|1949|,|Capra, Emanuele|,|Parco Tecnologico Padano, Lodi, Italy|
|1731|,|Cardinale, Jean|,|Alfred University, Alfred, NY|
|2255|,|Cardona, Silvia|,|University of Manitoba, Winnipeg, Canada|
|2063|,|Cardullo,|,|University of California, Riverside, CA|
|IP|,|Carlow, Tilde|,|New England Biolabs, Beverly, MA|
|3009|,|Carlson, Clay|,|Trinity Christian College, Palos Heights, IL|
|4285|,|Carlson, Kerri|,|University of St Thomas, St Paul,  MN|
|1794|,|Carlson, Sara|,|Ashland University, Ashland, OH|
|3576|,|Carlson, Steve|,|Iowa State University, Ames, IA|
|PMC|,|Carlton, Peter|,|University of Kyoto, Kyoto, Japan|
|1610|,|Carman, Kevin|,|Louisiana State University, Baton Rouge, LA|
|FAD|,|Carnell, Lucinda|,|Central Washington University, Ellensburg, WA|
| 515|,|Carolina Biological Supply Company|,|Burlington, NC|
|3568|,|Caron, Marc|,|Duke University, Durham, NC|
|2731|,|Carr, Angela Carr|,|Wyle Integrated Science and Engineering Group, Houston, TX|
| 659|,|Carr, Michael|,|ICMB, University of Edinburgh, Edinburgh, U.K.|
| 310|,|Carr, Pat|,|Shiloh High School, Lithonia, GA|
|MCP|,|Carre-Pierrat, Maite|,|Universite Lyon, Villeurbanne, France|
|3925|,|Carrico, Pauline|,|State University of New York at Albany, Albany, NY|
|2840|,|Carroll, Tanya|,|University of California, Merced, CA|
| 356|,|Carson, Craig|,|Duke University Medical School, Durham, NC|
|LKC|,|Carta, Lynn|,|Agricultural Research Service, USDA, Beltsville, MD|
|2208|,|Carthew, Richard|,|Northwestern University, Evanston IL|
|CEC|,|Carvalho, Carlos|,|University of Saskatchewan, Saskatoon, SK, Canada|
|3873|,|Carvell, William|,|Benedictine University, Lisle, IL|
|2658|,|Carvelli, Lucia|,|University of North Dakota, Grand Forks, ND|
|1808|,|Casadei, Gabriele|,|Northeastern University, Boston, MA|
|3228|,|Casadei, Gabriele|,|Istituto Zooprofilattico della Lombardia , Parma, Italy|
|3757|,|Casadevall i Solvas, Xavier|,|ETH-Zurich, Zurich, Switzerland|
|MOC|,|Casanueva, Olivia|,|The Babraham Institute, Cambridge, UK|
|3311|,|Cascella, Roberta|,|University of Florence, Florence, Italy|
|3522|,|Cascio, Janet|,|Stone Bridge High School, Ashburn VA|
|3728|,|Casey-Clukey, Louise|,|Lone Star College Montgomery, Conroe, TX|
|RC|,|Cassada, Randy|,|Universitat Freiburg, Freiburg, Germany|
|GU|,|Cassata, Giuseppe|,|IFOM, Milano, Italy|
|3785|,|Castorino, John|,|Hampshire College, Amherst, MA|
| 882|,|Caswell-Chen, Edward|,|University of California, Davis, CA|
|3751|,|Cavanagh, John|,|North Carolina State University, Raleigh, NC|
|4180|,|Cecconi, Francesco|,|Danish Cancer Society Research Center, Copenhagen, Denmark|
|1149|,|Cech, Tom|,|University of Colorado, Boulder, CO|
|2901|,|Cecile, Jennifer Perry|,|Appalachian St Univ, Boone, NC|
|2995|,|Cedergreen, Nina|,|University of Copenhagen, Frederiksberg, Denmark|
| 989|,|Celestar Lexico-Sciences, Inc.|,|Tsukuba, Ibaraki, Japan|
|1006|,|Cenix Bioscience GmbH|,|Dresden, Germany|
|2380|,|Centers for Disease Control|,|Chamblee, GA|
|CER|,|Ceron Madrigal, Julian|,|University Hospital, ICO - IDIBELL, Barcelona, Spain|
|3845|,|Cetin, Ali|,|Cumhuriyet University School of Medicine, Sivas, Turkey|
|3286|,|Cevik-Kaplan, Sebiha|,|Canik Basari University, Samsun, Turkey|
|QL|,|Ch'ng, Queelim|,|King's College, London, UK|
|1745|,|Cha'on, Ubon|,|Khon Kaen University, Khon Kaen, Thailand|
|3629|,|Cha, Dong Seok|,|Woosuk University, Jeonbuk, South Korea|
|4158|,|Chai, Yifeng|,|Second Military Medical University, Shanghai, China|
|4055|,|Chaiyasut, Chaiyavat|,|Chiang Mai University, Chiang Mai, Thailand|
|3502|,|Chakrabarti, Lisa|,|University of Nottingham, Leicestershire, UK|
|3734|,|Chakraborty, Kausik|,|CSIR-IGIB, New Delhi, India|
|2752|,|Chakraborty, Subhra|,|Nat Inst Plant Genome Research, New Delhi, India|
|IV|,|Chalasani, Sreekanth|,|The Salk Institute, La Jolla, CA|
|TU|,|Chalfie, Marty|,|Columbia University, New York, NY|
|CM|,|Chamberlin, Helen|,|Ohio State University, Columbus, OH|
|3220|,|Chambers, James|,|University of Massachusetts, Amherst, MA|
| 297|,|Chambon, P.|,|Lab de Genetique Moleculaire des Eucaryotes du CNRS, France|
|JPC|,|Chan, Jason|,|Juniata College, Huntingdon, PA|
|YE|,|Chan, Ray|,|University of Michigan, Ann Arbor, MI|
|SPN|,|Chan, Shih-Peng|,|National Taiwan University, Taipei, Taiwan|
|3909|,|Chance, Deborah|,|University of Missouri, Columbia, MO|
|2971|,|Chandel, Navdeep|,|Northwestern University, Chicago, IL|
| 229|,|Chandhoke, Vikas|,|George Mason University, Fairfax, VA|
|CHC|,|Chandler, Christopher|,|SUNY Oswego, Oswego, NY|
|2774|,|Chandrasekar, Arun|,|JSS College of Pharmacy, Tamil Nadu, India|
|1298|,|Chang, Caren|,|University of Maryland, College Park, MD|
|1977|,|Chang, Cheng|,|National Chung-Hsing University, Taichung, Taiwan|
|XN|,|Chang, Chieh|,|University of Illinois at Chicago, Chicago, IL|
|HCX|,|Chang, Howard|,|Binghamton University, Binghamton, NY|
|1746|,|Chang, Hsin-Hou|,|Tzu-Chi University, Hualien, Taiwan|
|3065|,|Chang, Leng Chee|,|University of Hawaii, Hilo, HI|
|3525|,|Chang, Matthew Wook|,|Nanyang Technological University, Nanyang Avenue, Singapore|
|1199|,|Chang, Ming-Shiou|,|RNA Virus Lab, Taipei, Taiwan|
|1694|,|Chang, Ya-Chung|,|National Taiwan University, Taipei, Taiwan|
|2169|,|Chang, Zengyi|,|Peking University, Beijing, China|
|ZY|,|Chao, Michael|,|California State University, San Bernardino, CA|
|1106|,|Chao, Moses|,|New York University, Skirball Institute, New York, NY|
|4346|,|Chapin, Hannah|,|Seattle Academy, Seattle, WA|
|1680|,|Charles, Jean-Francois|,|Institut Pasteur, Paris, France|
|1741|,|Charles, Trevor|,|University of Waterloo, Waterloo, ON, Canada|
|1563|,|Charlesworth, Deborah|,|University of Edinburgh, Edinburgh, UK|
|XP|,|Chase, Daniel|,|University of Massachusetts, Amherst, MA|
|4263|,|Chatterjee, Anushree|,|University of Colorado, Boulder, CO|
|4108|,|Chatterjee, Saibal|,|Indian Institute of Science, Bangalore, India|
|4310|,|Chauhan, Puneet Singh|,|CSIR-NBRI, Lucknow, India|
|4365|,|Chauhan, Veeren|,|University of Nottingham, Nottingham,  UK|
|4308|,|Chawla, Sangeeta|,|University of York, York, UK|
|3743|,|Checchi, Paula|,|Marist College, Poughkeepsie, NY|
|4178|,|Chelo, Ivo|,|Instituto Gulbenkian de Ciencia, Oeiras,  Portugal|
|2403|,|Chen, Casey|,|University of Southern California, Los Angeles, CA|
|2537|,|Chen, Chang|,|Chinese Academy of Sciences, Beijing, China|
|3443|,|Chen, Chang|,|Chinese Academy of Sciences, Guangzhou City, China|
|YQ|,|Chen, Chang-Shi|,|National Cheng Kung University, Tainan, Taiwan|
|3358|,|Chen, Chih-Shou|,|Chia-Yi Chang Gung Memorial Hospital, Taiwan|
|3616|,|Chen, Chunying|,|National Center for Nanoscience and Technology, Beijing, China|
|2583|,|Chen, Degui|,|Chinese Academy of Sciences, Shanghai, China|
|DCL|,|Chen, Di|,|Nanjing University, Nanjing, China|
|4290|,|Chen, Gen|,|Lanzhou University Lanzhou, China|
|4008|,|Chen, Hai-Lan|,|Old Dominion University, Norfolk, VA|
|JNC|,|Chen, Jack|,|Simon Fraser University, Burnaby, BC, Canada|
| 440|,|Chen, Lan Bo|,|Dana-Farber Cancer Institute, Boston, MA|
|2702|,|Chen, Liang|,|Otsuka Shanghai Research Insti, Shanghai, China|
|3088|,|Chen, Liang|,|Otsuka Shanghai Research Inst, Shanghai, China|
|LH|,|Chen, Lihsia|,|University of Minnesota, Minneapolis, MN|
|3008|,|Chen, Linda|,|Washington State University, Vancouver, WA|
|2095|,|Chen, Ming-Shun|,|Kansas State University, Manhattan, KS|
|RAC|,|Chen, Ron|,|University of Leeds, Leeds, UK|
|IBP|,|Chen, Runsheng|,|Chinese Academy of Sciences, Beijing, China|
| 850|,|Chen, Senyu|,|University of Minnesota, Waseca, MN|
|2230|,|Chen, Shu|,|Case Western Reserve University, Cleveland, OH|
|SGC|,|Chen, Shu|,|Case Western Reserve University, Cleveland, OH|
|2385|,|Chen, Wei|,|Arizona State University, Mesa, AZ|
|3103|,|Chen, Wei|,|Jiangnan University, Jiangsu, China|
| 256|,|Chen, Weining|,|National University of Singapore, Singapore|
|2705|,|Chen, Xiangmei|,|Kidney Center and Key Lab of PLA, Genreal Hospital, Beijing, China|
|JHU|,|Chen, Xin|,|Johns Hopkins University, Baltimore, MD|
|3646|,|Chen, Xu|,|Nanjing University, Nanjing, China|
|2958|,|Chen, Yan|,|Inst of Nutritional Sciences, Chinese Acad of Sciences, Shanghai, China|
|4261|,|Chen, Yin|,|University of Warwick, Coventry, UK|
|3537|,|Chen, Yu|,|University of Maryland, College Park, MD|
|3257|,|Chen, Yuqing (Eugene)|,|University of Michigan, Ann Arbor, MI|
|3119|,|Cheng, Guangjie|,|University of Alabama at Birmingham, Birmingham, AL|
|2682|,|Cheng, Hongmei|,|Chinese Academy of Agricultural Sciences, Beijing, China|
|HJ|,|Cheng, Hwai-Jong|,|University of California, Davis, CA|
|2518|,|Cheng, Ji-Xin|,|Purdue University, West Lafayette, IN|
|2603|,|Cheng, Shuk Han|,|City University of Hong Kong, Hong Kong|
|2640|,|Cheng, Zhe|,|Xiamen University, Xiamen, Fujian, China|
|2766|,|Chernenko, Susan|,|Loudoun County - Acad Science, Sterling, VA|
| 294|,|Cheung, Tak|,|Illinois State University, Normal, IL|
|1322|,|Chevet, Eric|,|INSERM, Bordeaux, France|
| 465|,|Cheville, Norman|,|Iowa State University, Ames, IA|
|1934|,|Chiesa, Ricardo|,|University of Puerto Rico, Cayey, Puerto Rico|
|3535|,|Chilvers, Martin|,|Michigan State University, East Lansing, MI|
|3389|,|Chin, Jason|,|MRC Laboratory of Molecular Biology, Cambridge, UK|
|2150|,|Chin, Khew-Voon|,|University of Toledo, Toledo, OH|
|IC|,|Chin-Sang, Ian|,|Queen's University, Kingston, ON, Canada|
|RU|,|Chiquet, Ruth|,|Friedrich Miescher Institute, Basel, Switzerland|
|2862|,|Chirikjian, Jack|,|Georgetown University|
|CZ|,|Chisholm, Andrew and Jin, Yishi|,|University of California, San Diego, CA|
|  45|,|Chitwood, David|,|USDA Nematology Lab, Beltsville, MD|
|1788|,|Chiu, Daniel|,|University of Washington, Seattle, WA|
|3146|,|Chklovskii, Dmitri|,|HHMI-Janelia Farm Research Campus, Ashburn, VA|
| 305|,|Cho, Nam Jeong|,|Chungbuk National University, Chungbuk, Korea|
|2883|,|Cho, Saeyoull|,|Kangwon National University, South Korea|
|1649|,|Cho, Wen-long|,|National Yang-Ming University, Taipei City, Taiwan|
|QV|,|Choe, Keith|,|University of Florida, Gainesville, FL|
|3079|,|Choffnes, Dan|,|Carthage College, Kenosha, WI|
|2129|,|Choi, Jinhee|,|University of Seoul, Seoul, South Korea|
|2430|,|Choi, Jinhee|,|University of Seoul, Seoul, South Korea|
|2776|,|Choi, Min-Ho|,|Seoul Nat Univ & Coll of Med, Seoul, South Korea|
|3141|,|Choi, Sin Ski|,|Myong Ji University, Korea|
|2267|,|Chong, Setareh|,|University of York, York, England, UK|
|2960|,|Chou, Hui-Hsien|,|Iowa State University, Ames, IA|
|1518|,|Choun, Se Young|,|Kyung Hee University, Seoul, Korea|
|2638|,|Chow, Chi-Wing|,|Albert Einstein College of Medicine, Bronx, NY|
|1487|,|Chow, Chit|,|Chinese University of Hong Kong, Shatin, NT, Hong Kong|
|KC|,|Chow, King L.|,|Hong Kong U of Sci & Tech, Clear Water Bay, Kowloon, Hong Kong|
|1316|,|Chow, Marie|,|University of Arkansas, Little Rock, AR|
| 749|,|Christensen, Michael|,|Vanderbilt University, Nashville, TN|
|2642|,|Christensen, Soren|,|University of Copenhagen, Copenhagen, Denmark|
|2123|,|Christie, Gail|,|Virginia Commonwealth University, Richmond, VA|
|3238|,|Christman, Rhonda|,|Vista Ridge High School, Cedar Park, TX|
|3123|,|Christoffersen, Rolf|,|University of California, Santa Barbara, CA|
|4359|,|Christopher, Kathryn (Kay)|,|University of Virginia, Charlottesville, VA|
|NKC|,|Chronis, Nikos|,|University of Michigan, Ann Arbor, MI|
|1467|,|Chronogen Inc.|,|Montreal, Quebec, Canada|
|XC|,|Chu, Diana|,|San Francisco State University, San Francisco, CA|
|2479|,|Chu, Hong Wei|,|National Jewish Health, Denver, CO|
|1515|,|Chua, Ashley|,|Republic Polytechnic, Singapore|
|2579|,|Chua, Katrin|,|Stanford University, Palo Alto, CA|
|IX|,|Chuang, Chiou-Fen|,|University of Illinois at Chicago, Chicago, IL|
|1291|,|Chugh, Neeraj|,|St. Mary's College, Moraga, CA|
|2595|,|Chumakov, Peter|,|Cleveland Clinic Foundation, Cleveland, OH|
|2395|,|Chung, Brian|,|Weber State University, Ogden, Utah|
|1076|,|Chung, Sambath|,|Maryknoll Sisters, Phnom Penh, Cambodia|
|1744|,|Ciche, Todd|,|Michigan State University, East Lansing, MI|
|3023|,|Cichewicz, Robert|,|University of Oklahoma, Norman, OK|
|HNC|,|Cinar, Hediye Nese|,|Food and Drug Administration, Laurel, MD|
|2010|,|Cinar, Hulusi|,|University of Maryland, Baltimore, MD|
|CNQ|,|Cinquin, Olivier|,|University of California, Irvine, CA|
|RAF|,|Ciosk, Rafal|,|Friedrich Miescher Institute, Basel, Switzerland|
|2306|,|Cipollo, John|,|FDA/CBER, Bethesda, MD|
|4061|,|Cipriano, Anthony|,|California State University Dominguez Hills, Carson, CA|
|1276|,|Cirillo, Jeff|,|Texas A&M HSC, Bryan, TX|
|3891|,|Cissell, Kyle|,|Saginaw Valley State University, Saginaw, MI|
|2775|,|Clagett-Dame, Margaret|,|University of Wisconsin, Madison, WI|
| 738|,|Clapham, David|,|Harvard Medical School, Boston, MA|
|2313|,|Clardy, Jon|,|Harvard Medical School, Boston, MA|
|3373|,|Clark, Denise|,|University of New Brunswick, Fredericton, NB, Canada|
|CLA|,|Clark, Nathan|,|University of Pittsburgh, Pittsburgh, PA|
|SK|,|Clark, Scott|,|University of Nevada, Reno, NV|
|4210|,|Clark, Shawn|,|National Research Council Canada, Saskatoon, SK, Canada|
|CFC|,|Clarke, Catherine|,|University of California, Los Angeles, CA|
| 746|,|Clarke, Margaret|,|Oklahoma Medical Research Foundation, Oklahoma City, OK|
|SCL|,|Clarke, Steven|,|Department of Chemistry & Biochemistry, UCLA|
|1236|,|Claus, Peter|,|Hannover Medical School, Hannover, Germany|
|JMC|,|Claycomb, Julie|,|University of Toronto, Toronto, Ontario, Canada|
|4314|,|Clemons, Bil|,|California Institute of Technology, Pasadena, CA|
| 750|,|Clevers, Hans|,|Department of Immunology, University Hospital, Utrecht, The Netherlands|
|1263|,|Clifton, Rick|,|Yale University, New Haven, CT|
| 896|,|Coates, David|,|University of Leeds, Leeds, U.K.|
|DJ|,|Cobb, Melanie|,|UT Southwestern Medical Center, Dallas, TX|
|MLC|,|Cochella, Luisa|,|Research Institute of Molecular Pathology, Vienna, Austria|
|SF|,|Coffino, Phillip|,|University of California, San Francisco, CA|
|1012|,|Cofield, Naressa|,|Purdue University, West Lafayette, IN|
|3016|,|Cohen, Adam|,|Harvard University, Cambridge, MA|
|EHC|,|Cohen, Ehud|,|Hebrew University, Jerusalem, Israel|
|NTC|,|Cohen, Netta|,|University of Leeds, Leeds, UK|
|3302|,|Cohen, Pinchas|,|University of California, Los Angeles, CA|
|OCF|,|Cohen-Fix, Orna|,|NIH, NIDDK, Bethesda, MD|
|1349|,|Coil, Rebecca|,|Cornell University, Ithaca, NY|
|CV|,|Colaiacovo, Monica|,|Harvard Medical School, Boston, MA|
|OU|,|Colavita, Antonio|,|University of Ottawa, Ottawa, Ontario, Canada|
| 247|,|Cole, Michael|,|Princeton University, Princeton NJ|
|3250|,|Cole, Robert|,|Johns Hopkins School of Medicine, Baltimore, MD|
|2504|,|Coleman, Melissa|,|Claremont College, Claremont, CA|
|4109|,|Collado, Amandine|,|Oxitec Limited, Abingdon, UK|
|8888|,|College Instructor, Multiple Users|,|Multiple Locations|
|3386|,|Collins, Jim|,|Boston University, Boston, MA|
|TW|,|Collins, John|,|University of New Hampshire, Durham|
|MIA|,|Collins, Kevin Michael|,|University of Miami, Miami, FL|
|2779|,|Collins, Victoria|,|Warren Wilson College, Asheville NC|
|4076|,|Colmer-Hamood, Jane|,|Texas Tech University Health Sciences Center, Lubbock, TX|
|3090|,|Colomin, Maria Teresa|,|University Rovira i Virgili, Tarragona, Spain|
|DCR|,|Colon-Ramos, Daniel|,|Yale University, New Haven, CT|
|1916|,|Combelles, Catherine|,|Middlebury College, Middlebury, VT|
|3264|,|Comeron, Josep|,|University of Iowa, Iowa City, IA|
|1660|,|Condie, Brian|,|University of Georgia, Athens, GA|
|2876|,|Condon, Mark|,|SUNY at Dutchess, Poughkeepsie, NY|
|3098|,|Cong|,|Shanghai Jiaotong University, Shanghai, China|
|CC*|,|Conley, Catharine|,|NASA Ames Research Center, Moffett Field, CA|
|1526|,|Conley, Terry|,|Oklahoma City University, Oklahoma City, OK|
|3505|,|Connelly, Jacob|,|American Heritage School, Plantation, FL|
|1776|,|Connerly, Pamela|,|Indiana University East, Richmond, IN|
| 674|,|Connolly, John|,|Foundation Jean Dausset - CEPH, Paris, France|
|3057|,|Connor, Ruth|,|Dartmouth-Hitchcock Medical Center, Lebanon, NH|
|MD|,|Conradt, Barbara|,|Ludwig-Maximilians-Universitat, Munich, Germany|
| 390|,|Consolie, Diana|,|Hobart and William Smith Colleges, Geneva, NY|
|4032|,|Cook Easterwood, Jennifer|,|Queens University of Charlotte, Charlotte, NC|
|1311|,|Cook, Bill|,|Midwestern State University, Wichita Falls, TX|
| 918|,|Cooper, Jon|,|Fred Hutchinson Cancer Research Center, Seattle, WA|
|1285|,|Cooper, Vaughn|,|University of Michigan, Ann Arbor, MI|
|2890|,|Copeland, Jeff|,|Eastern Mennonite University, Harrisonburg, VA|
|2931|,|Corbo, Christopher|,|Wagner College, Staten Island, NY|
| 561|,|Corby, Deb|,|Concordia University College of Alberta, Edmonton, Alberta, Canada|
|1541|,|Cordes, Volker|,|University of Heidelberg, Heidelberg, Germany|
| 550|,|Corey, David|,|Massachusetts General Hospital, Boston, MA|
|2696|,|Corkhill, Sue|,|University of Liverpool, Liverpool, UK|
|WL|,|Corneliussen, Brit|,|AstraZeneca, Molndal, Sweden|
|AK|,|Corsi, Ann|,|Catholic University of America, Washington, DC|
| 721|,|Coskun, Pinar|,|Emory University, Atlanta, GA|
|2280|,|Cossins, Andrew|,|Liverpool University, Liverpool, UK|
|4062|,|Costa, Gonzalo|,|Complutense University of Madrid, Madrid, Spain|
|4363|,|Cote, Rick|,|University of New Hampshire, Durham, NH|
|1189|,|Coulter, Douglas|,|Saint Louis University, St. Louis, MO|
| 518|,|Court, Don|,|NCI-FCRDC, Frederick, MD|
|WCH*|,|Court, Felipe|,|Universidad Católica de Chile, Santiago, Chile|
|3773|,|Courtney, Conor|,|Trinity College, Dublin, Ireland|
|UE|,|Cowan, Carrie|,|Cold Spring Harbor Laboratory, Cold Spring Harbor, NY|
|1238|,|Cowan, Nicholas|,|New York University Medical Center, New York, NY|
|2722|,|Cowen, Leah|,|University of Toronto, Toronto, ON, Canada|
|2422|,|Cox, Abbi|,|SUNY, Geneseo, NY|
|1858|,|Cox, Adrienne|,|University of North Carolina, Chapel Hill, NC|
|1225|,|Cox, Edward|,|Princeton University, Princeton, NJ|
|UN|,|Cram, Erin|,|Northeastern University, Boston, MA|
|3834|,|Cremer, Sylvia|,|Institute of Science & Technology, Klosterneuburg, Austria|
|2618|,|Crescenzi, Marco|,|National Insitute of Health, Rome, Italy|
| 228|,|Creutz, Carl|,|University of Virginia, Charlottesville, VA|
|3420|,|Crone, Donna|,|Rensselaer Polytechnic Institute, Troy, NY|
| 563|,|Cronkite, Donald|,|Hope College, Holland, MI|
|4216|,|Crook, Matt|,|Whitman College, Walla Walla, WA|
| 363|,|Cross, Helen|,|Liverpool School of Tropical Medicine, Liverpool, U.K.|
|KCG|,|Crossgrove, Kirsten|,|University of Wisconsin, Whitewater, WI|
|MC|,|Crowder, Mike|,|Washington Univ. School of Medicine, St. Louis, MO|
|3251|,|Cruickshank, Jennifer|,|State University of New York at Oswego, Oswego, NY|
|4339|,|Cruze, Lori|,|Wofford College, Spartanburg, SC|
|1608|,|Cruzen, Matt|,|Biola University, La Mirada, CA|
|EKM|,|Csankovszki, Gyorgyi|,|University of Michigan, Ann Arbor, MI|
|2564|,|Cubillos, Juan Manuel|,|Pontificia Universidad Javeriana, Bogota, Colombia|
|1937|,|Cucek, Petar|,|Vladimir Prelog Science School, Zagreb, Croatia|
|2183|,|Cuddington, Kim|,|University of Waterloo, Waterloo, Ontario, Canada|
|2237|,|Cude, Kelly|,|College of the Canyons, Santa Clarita, CA|
|2948|,|Cuevas, Raquel|,|Tec de Monterrey, Monterrey, Mexico|
|3446|,|Cui, Dongya|,|Chinese Academy of Science, Beijing, China|
|3111|,|Cui, Yufang|,|Beijing Inst of Radiation Medicine, Beijing, China|
|BF|,|Culetto, Emmanuel|,|Universite Paris, Orsay, France|
| 429|,|Culotta, Val|,|Johns Hopkins University, Baltimore, MD|
|NW|,|Culotti, Joe|,|Mt. Sinai Hospital Research Institute, Toronto, Ontario|
|2541|,|Cupp, Meghan|,|SRI International, Harrisonburg, VA|
|3029|,|Curis, Mindy|,|Keystone College, La Plume, PA|
| 236|,|Curley, D.|,|Long Island University, Brooklyn NY|
|SPC|,|Curran, Sean|,|University of Southern California, Los Angeles, CA|
|2536|,|Currie, Rob|,|University of Manitoba, Winnipeg, Manitoba, Canada|
|1622|,|Curtis, Patrick|,|University of Georgia, Athens, GA|
|1748|,|Curtis, Rosane|,|Rothamsted Research, Harpenden, Herts, UK|
| 876|,|Cutler, Roy|,|National Institute of Aging, NIH, Baltimore, MD|
|VX|,|Cutter, Asher|,|University of Toronto, Toronto, Ontario, Canada|
| 762|,|DNA Plant Technology|,|Oakland, CA|
|CLD|,|Dahlberg, Caroline|,|Western Washington University, Bellingham, WA|
|2871|,|Dai, Chensheng|,|Nanjing Agricultural Univ, Nanjing, China|
|1892|,|Dai, Zhong-Min|,|Zhejiang University, Zhejiang, China|
| 284|,|Dalbey, Mike|,|University of California, Santa Cruz|
|EDC|,|Dalfo, Esther|,|University Hospital, ICO - IDIBELL, Barcelona, Spain|
|2554|,|Dalski, Andreas|,|Medical University of Luebeck, Luebeck, Germany|
|2387|,|Dambacher, Corey|,|Scripps Research Institute, La Jolla, CA|
|1019|,|Damjanovski, Sashko|,|University of Western Ontario, London, Ontario, Canada|
|DAM|,|Dammermann, Alex|,|Max Perutz Laboratories, Vienna, Austria|
|3729|,|Danckwardt, Sven|,|Johannes Gutenberg University, Mainz, Germany|
|2549|,|Danelly, Kathleen|,|Indiana State University, Terre Haute, IN|
|4198|,|Dang, Weiwei|,|Baylor College of Medicine, Houston, TX|
|3871|,|Dannelly, Kathleen|,|Indiana State University, Terre Haute, IN|
|1532|,|Danner, Dean|,|Emory University School of Medicine, Atlanta, GA|
|TBD|,|Dansen, Tobias|,|UMCU, Utrecht, The Netherlands|
|2037|,|Dapp, Christoph|,|Gymnasium Interlaken, Gstaad, Switzerland|
|BJD|,|Darby, Brian|,|University of North Dakota, Grand Forks, ND|
|DC|,|Darby, Creg|,|University of California, San Francisco, CA|
| 904|,|Darling, Tina|,|Hunterdon Central Regional High School, Flemington, NJ|
|2451|,|Das, Bidyadhar|,|Manipal University, Manipal, Karnataka, India|
| 600|,|Das, U.N.|,|Webster, TX|
|2945|,|Daum, Julie|,|Bayer CropScience, Research Triangle Park, NC|
|3672|,|Daunert, Sylvia|,|University of Miami, Miami, FL|
|3696|,|Dave, Rajnish|,|Temple University School of Medicine, Philadelphia PA|
|2418|,|Davey, Mary|,|University of Technology, Sydney, Australia|
|DCD|,|David, Della|,|German Centre Neurodegenerative Diseases (DZNE), Tuebingen, Germany|
| 334|,|Davidson, Mary|,|Mississippi School for Math & Science, Columbus, MS|
|ZN|,|Davies, Andrew|,|Virginia Commonwealth University, Richmond, VA|
|2800|,|Davies, Daivd|,|Binghamton University, Vestal, NY|
| 385|,|Davies, Keith|,|IACR-Rothamsted, Hertfordshire, UK|
|4121|,|Davies, Kelvin|,|University of Southern California, Los Angeles, CA|
| 743|,|Davis, Bowman|,|Kennesaw State University, Kennesaw, GA|
|1566|,|Davis, Brad|,|University of British Columbia, Vancouver, BC, Canada|
|1011|,|Davis, Cynthia|,|Roberts Wesleyan College, Rochester, NY|
| 393|,|Davis, Eric|,|North Carolina State University, Raleigh, NC|
| 772|,|Davis, Lisa|,|University of South Carolina, Columbia, SC|
|RED|,|Davis, Richard|,|University of Colorado, Aurora, CO|
|2853|,|Davitaia, Gia|,|Iv Javakhishvili State Univ Tbilisi, Georgia|
|ATD|,|Dawes, Adriana|,|Ohio State University, Columbus, OH|
|4231|,|Dawson-Scully, Ken|,|Florida Atlantic University, Jupiter, FL|
|1249|,|Day, Anya|,|Beloit College, Beloit, WI|
|2014|,|Day, Tim|,|Iowa State University, Ames, IA|
|PDL|,|De Ley, Paul|,|University of California, Riverside, CA|
|1093|,|De Rosa, Andy|,|Louisianna State Universtiy, Baton Rouge, LA|
|2101|,|DeLisa, Matt|,|Cornell University, Ithaca, NY|
|4133|,|DeMaria, MaryAnn|,|Bancroft School, Worcester, MA|
|2568|,|DePaul, Andrew|,|Francis W Parker School, Chicago, IL|
|3876|,|DeSimone, Susan|,|Middlebury College, Middlebury, VT|
|LU|,|DeStasio, Elizabeth|,|Lawrence University, Appleton, Wisconsin|
| 648|,|Dean, Donald|,|Ohio State University, Columbus, OH|
|1613|,|Debant, Anne|,|CNRS, Montpellier, France|
|2952|,|Deisseroth, Karl|,|Stanford University, Palo Alto, CA|
|3312|,|Delahodde, Agnes|,|IGM Orsay, Paris, France|
|3988|,|Delaney, Kimberly|,|University of Southern Indiana, Evansville, IN|
| 322|,|Delannoy, Peter|,|Black Hills State University, Spearfish, ND|
|ANA|,|Delattre, Marie|,|LBMC-ENS, Lyon, France|
|3242|,|Delgado, Margarida|,|CBAA - Instituto Superior de Agronomia, Lisbon, Portugal|
|1922|,|Dempsey, Catherine|,|National University of Ireland, Maynooth, Ireland, UK|
|1974|,|Denegre, Edgardo|,|Universidad de Moron, Buenos Aires, Argentina|
|4081|,|Deng, Hongbing|,|Wuhan University, Wuhan, China|
|2730|,|Deng, Huizhong|,|Hunan Agriculture University, Changsha, Hunan, China|
|1641|,|Deng, Wei|,|Chinese Academy of Sciences, Beijing, China|
| 628|,|Dennehy, John|,|Clark University, Worcester, MA|
|DE|,|Dennis, James|,|Mount Sinai Hospital, Toronto, Ontario, Canada|
|JD|,|Dent, Joe|,|McGill University, Montreal, Canada|
|1869|,|Denton, Jerod|,|Vanderbilt University, Nashville, TN|
|1856|,|Denver, Dee|,|Oregon State University, Corvallis, OR|
|MSD|,|Denzel, Martin|,|Max Planck Institute, Cologne, Germany|
|CA|,|Dernburg, Abby|,|Lawrence Berkeley National Laboratory, Berkeley, CA|
|WD|,|Derry, Brent|,|University of Toronto, Toronto, Ontario, Canada|
|2062|,|Desai, Arshad|,|University of California, San Diego, CA|
| 783|,|Deshler, Jodie|,|University of Wisconsin, River Falls, WI|
|QB|,|Desnoyers, Serge|,|Centre de Recherche du CHUL, Sanite-Foy, Quebec, Canada|
|ECD|,|Devaney, Eileen|,|Glasgow University, Glasgow, Scotland|
|3310|,|Devor, Daniel|,|University of Pittsburgh, Pittsburgh, PA|
|1968|,|Dey, Satyahari|,|Indian Institute of Technology, Kharagpur, India|
|3031|,|Dharmasaroja, Permphan|,|Mahidol University, Bangkok, Thailand|
|HSD|,|Dhillon, Harbinder|,|Delaware State University, Dover, DE|
| 971|,|Di Carlo-Cohen, Andrea|,|Catholic University of America, Washington, DC|
|2256|,|Di Serio, Francesco|,|CNR, Bari, Italy|
|3102|,|Di, Rong|,|Rutgers University, New Brunswick, NJ|
| 351|,|DiBartolomeis, Susan|,|Millersville University, Millersville, PA|
|3872|,|DiFrancesca, Heidi|,|University of Mary Hardin Baylor, Belton, TX|
|2270|,|Diamond V|,|Cedar Rapids, IA|
|1707|,|Dian, G|,|Chinese Academy of Sciences, Hubei, China|
|3112|,|Diaz Ariza, Lucia Ana|,|Pontificia Universidad Javeriana, Bogota, Colombia|
|1988|,|Diaz, Sylvia|,|University of Glasgow, Glasgow, Scotland|
|2307|,|Dickson, Barry|,|Research Institute of Molecular Pathology, Vienna, Austria|
|4162|,|Dickson, Robert|,|University of Kentucky, Lexington, KY|
|1730|,|Didier Chatenay|,|ENS, Paris, France|
|3187|,|Dien, Nguyen|,|Research Institute for Aquaculture, Hochiminh City, Vietnam|
|3285|,|Dieterich, Christoph|,|Max-Delbrueck-Center for Molecular Medicine, Berlin, Germany|
|1695|,|Dietrich, Margaret|,|Grand Valley State University, Grand Rapids, MI|
|2367|,|Dileo, Caterina|,|University of Bari, Bari, Italy|
|AGD|,|Dillin, Andrew|,|University of California, Berkeley, CA|
|2925|,|Ding, Qiang (John)|,|University of Alabama, Birmingham, AL|
|2484|,|Ding, Qunxing|,|Kent State University, East Liverpool, OH|
|SWD|,|Ding, Shou-Wei|,|University of California, Riverside, CA|
|2276|,|Diomede, Luisa|,|Istituto di Ricerche Farmacologiche Mario Negri, Milano, Italy|
|JSD|,|Dittman, Jeremy|,|Cornell University Medical College, New York, NY|
| 974|,|Divecha, Nullin|,|Netherlands Cancer Institute, Amsterdam, The Netherlands|
|1003|,|Divergence LLC|,|St. Louis, MO|
|3608|,|Diwan, Abhinav|,|Washington University, St Louis, MO|
|1112|,|Dix, Ilona|,|National University of Ireland, Maynooth, Co. Kildare, Ireland, UK|
|3475|,|Dix, Randy|,|Olathe North High School, Olathe, KS|
|3604|,|Dixon, Jack|,|University of California, San Diego, CA|
|1476|,|Dmitrieva, Natalia|,|NHLBI/NIH, Bethesda, MD|
|4168|,|Dobson, Michael|,|University of Cambridge, Cambridge, UK|
|3431|,|Dodd, Celia|,|Fort Valley State University, Fort Valley, GA|
| 477|,|Dodge, Tony|,|Minneapolis Community Technical College, Minneapolis, MN|
|2994|,|Dodson, Mark|,|Sanofi-Aventis, Oro Valley, AZ|
|DK|,|Doi, Motomichi|,|AIST, Tsukuba, Ibaraki, Japan|
|MDH|,|Doitsidou, Maria|,|University of Edinburgh, Edinburgh, UK|
|CTD|,|Dolphin, Colin|,|King's College London, London, England|
| 505|,|Dombradi, Viktor|,|University Medical School of Debrecen, Hungary|
| 272|,|Domineau, Mrs.|,|Vero Beach Junior High School, Vero Beach, FL|
|SUN|,|Dominguez, Maria|,|CSIC-UMH, Alicante, Spain|
|3765|,|Donato, Veronica|,|Universidad Nacional de Rosario, Santa Fe, Argentina|
|MQD|,|Dong, Meng-Qiu|,|National Institute of Biological Sciences, Beijing, China|
|4234|,|Dong, Wen-xin|,|China State Inst of Pharm Industry, Shanghai, China|
|2447|,|Dong, Yuqing|,|Clemson University, Clemson, SC|
|1144|,|Donini, Pierluigi|,|Universita La Sapienze, Roma, Italia|
|1363|,|Donndelinger, T|,|Nampa, ID|
|3749|,|Donohue, Keri|,|US Army Corps of Engineers, Vicksburg, MS|
|4130|,|Donovan, Stacy|,|Maryville University, Saint Louis, MO|
| 347|,|Dooley, James|,|Adelphi University, Garden City, NY|
|RTD|,|Doonan, Ryan|,|CUNY, New York, NY|
|FED|,|Doring, Frank|,|University of Kiel, Kiel, Germany|
| 243|,|Doshi, Renu|,|University Hospital at Stonybrook, Stonybrook, NY|
|4226|,|Doshi, Shital|,|St. Xavier's College, Ahmedabad, India|
|3585|,|Doucet, Daniel|,|Great Lakes Forestry Centre, Sault Ste. Marie, Ontario, Canada|
|MED|,|Doucet, Marcelo|,|Centro de Zoologica Apl., Cordoba, Argentina|
|KRD|,|Douglas, Kristin|,|Augustana College, Rock Island, IL|
|PMD|,|Douglas, Peter|,|UT Southwestern Medical Center, Dallas, TX|
|2790|,|Dovel, Randy|,|Vanguard University, Costa Mesa, CA|
| 833|,|Drabikowski, Krzysztof|,|Friedrich Miescher Institute, Basel, Switzerland|
|3429|,|Drabikowski, Krzysztof|,|Polish Academy of Sciences, Warsaw, Poland|
|MCR|,|Drace, Kevin|,|Mercer University, Macon, GA|
|1807|,|Draganov, Marian|,|University of Plovdiv, Plovdiv, Bulgaria|
|2581|,|Drawbridge, Julie|,|Rider University, Lawrenceville, NJ|
|IY|,|Dreier, Lars|,|University of California, Los Angeles, CA|
|3124|,|Driscoll, Donna|,|Cleveland Clinic Foundation, Cleveland, OH|
|ZB|,|Driscoll, Monica|,|Rutgers University, Piscataway, NJ|
|2703|,|Drouin, Guy|,|University of Ottawa, Ottawa, Canada|
|3194|,|Du, Hua|,|Chinese Academy of Sciences, Beijing, China|
|3028|,|Du, Li-Lin|,|NIBS, Beijing, China|
|4170|,|Du, Libu|,|CAS, Institute of Chemistry, Beijing, China|
|SYS|,|Du, Zhuo|,|Chinese Academy of Sciences, Beijing, China|
|3884|,|Du, Zongjun|,|Shandong University, Weihai, China|
|SMD|,|Duan, Shuman|,|Zhejiang University, Hanzhou, China|
|FD|,|Duchaine, Thomas|,|McGill University, Montreal, Quebec, Canada|
|TCB|,|Dudley, Nate|,|TrySci Community Biolabs, Independence, MO|
|ATH|,|Duerr, Janet|,|Ohio University, Athens, OH|
|2120|,|Duez, Pierre|,|University of Brussels, Brussels, Belgium|
|4064|,|Duflo, Derek|,|Kennedy Space Center, FL|
|4238|,|Duman Scheel, Molly|,|Indiana University School of Medicine, South Bend, IN|
|JDU|,|Dumont, Julien|,|Institut Jacques Monod, Paris, France|
|2689|,|Duplicate entry|,||
|DUD|,|Dupuy, Denis|,|European Institute of Chemistry and Biology, Pessac, France|
|HX|,|Durbin, Richard|,|Sanger Centre, Hinxton, Cambridge, England|
|1158|,|Durocher, Daniel|,|S. Lunenfeld Institute, Mt Sinai Hosp, Toronto, Canada|
|GT*|,|Dusenbery, David*|,|Georgia Institute of Technology, Atlanta|
|3513|,|Dussan, Lucia|,|EDVOTEK, Washington, DC|
|1444|,|Dutcher, Susan|,|Washington University School of Medicine, St. Louis, MO|
|4048|,|Dutt, Manjul|,|University of Florida, Lake Alfred, FL|
| 335|,|Dvorak, Timothy|,|USDA-ARS, Peoria, IL|
|2909|,|Dwivedi, Meenakshi|,|University of Delhi, Delhi, India|
|JED|,|Dworkin, Jonathan|,|Columbia University, New York, NY|
|1305|,|Dwyer, Tim|,|Villa Julie College, Stevenson, MD|
|2756|,|Dye, Kathryn|,|Mount St. Mary's University, Emmitsburg, MD|
| 269|,|Dyer, Betsy|,|Biology Department, Wheaton College, Norton, MA|
|4140|,|Dyer, Jamie|,|Rockhurst University, Kansas City, MO|
|3996|,|Dymond, Jessica|,|Johns Hopkins University, Laurel, MD|
|3613|,|Dzhambazov, Balik|,|Plovdiv University, Plovdiv, Bulgaria|
|3289|,|Dziembowski, Andrzej|,|Warsaw University, Warsaw, Poland|
|2777|,|Eakanunkul, Suntara|,|Chiang Mai University, Chiang Mai, Thailand|
|4351|,|Earls, Laurie|,|Tulane University, New Orleans, LA|
|1396|,|Easton, Douglas|,|Buffalo State College, Buffalo, NY|
|2359|,|Eaton, John|,|University of Louisville, Louisville, KY|
|3760|,|Ebel, Greg|,|Colorado State University, Fort Collins, CO|
|2031|,|Ebert|,|Justus von Lieig Schule, Waldshut, Tiengen, Germany|
|UQ|,|Ebert, Paul|,|University of Queensland, Brisbane, Australia|
| 466|,|Ebina, Yoshio|,|Yamaguchi University, Yamaguchi, Japan|
|1686|,|Echenique, Jose|,|Universidad Nacional de Cordoba, Cordoba, Argentina|
|1796|,|Echeverria, Susana Rodriguez|,|Universidade de Coimbra, Coimbra, Portugal|
|1165|,|Eckdahl, Todd|,|Western Missouri State College, St. Joseph, MO|
|1976|,|Ecker, Joe|,|The Salk Institute, La Jolla, CA|
|EV|,|Eckmann, Christian|,|Martin Luther University, Halle-Wittenberg, Halle, Germany|
|SE|,|Eddy, Sean|,|JFRC, Ashburn, VA|
|2812|,|Edenborn, Sherie|,|Chatham University, Pittsburgh, PA|
|BE|,|Edgar, Bob|,|University of California, Santa Cruz|
|3862|,|Edgar, Michael|,|Milton Academy, Milton, MA|
| 711|,|Edgar, Paul|,|University of Auckland, Auckland, New Zealand|
|2575|,|Edgington, Nicholas|,|Southern Connecticut State University, New Haven, CT|
|1725|,|Edison, Arthur|,|University of Georgia, Athens, GA|
|4364|,|Edwards Canfield, Clare-Anne|,|Keiser University, Tampa, FL|
| 710|,|Edwards, Jessica|,|Kenyon College, Gambier, OH|
|KE|,|Edwards, Kaye|,|Haverford College, Haverford, PA|
|4283|,|Efferth, Thomas|,|Institute of Molecular Biology, Mainz, Germany|
|1430|,|Egan, Sean|,|The Hospital for Sick Children, Toronto, ON, Canada|
|2744|,|Egger, Bernhard|,|University of Innsbruck, Innsbruck, Austria|
|2337|,|Egland, Paul|,|Augustana College, Sioux Falls, SD|
|EY|,|Ehrenhofer-Murray, Ann|,|MPI of Molecular Genetics, Berlin, Germany|
|1455|,|Ehrhardt, Annette|,|University of British Columbia, Vancouver, BC, Canada|
|2434|,|Eijsink, Vincent|,|Norwegian University of Life Sciences, Aas, Norway|
|GQ|,|Eimer, Stefan|,|European Neuroscience Institute, Goettingen, Germany|
|3243|,|Eisenberg, David|,|University of California, Los Angeles, CA|
|EW|,|Eisenmann, David|,|UMBC, Baltimore, MD|
|1161|,|Eki, Toshihiko|,|Toyohashi University of Technology, Toyohashi, Aichi, Japan|
|3970|,|Ekker, Marc|,|University of Ottawa, Ottawa, ON, Canada|
|2926|,|El Ashry, Abd el naser|,|Universitat Bonn, Bonn, Germany|
|REB|,|El Bajjani, Rachid|,|Davidson College, Davidson, NC|
|2566|,|El-Dorry, Hamza|,|American University, Cairo, Egypt|
| 999|,|Elanco Animal Health|,|Greenfield, IN|
|1637|,|Elasri, Mohamed|,|University of Southern Mississippi, Hattiesburg, MS|
|2629|,|Elbaum, Danek|,|Polish Academy of Sciences, Warsaw, Poland|
| 714|,|Elde, Robert|,|University of Minnesota, St. Paul, MN|
| 843|,|EleGene GmbH|,|Martinsried, Germany|
|1049|,|Elewa, Ahmed|,|AGERI, Giza, Egypt|
|1484|,|Eli Lilly and Company|,|Greenfield, IN|
|EP|,|Elixir Pharmaceutical|,|Cambridge, MA|
|RE|,|Ellis, Ron|,|UMDNJ, Rutgers University, Stratford, NJ|
|3984|,|Elwess, Nancy|,|SUNY-Plattsburgh, Plattsburgh, NY|
|3511|,|Elzey, Dana|,|University of Virginia, Charlottesville, VA|
|1889|,|Emili, Andrew|,|University of Toronto, Toronto, Ontario, Canada|
|1798|,|Emmert, Elizabeth|,|Salisbury University, Salisbury, MD|
|EM|,|Emmons, Scott|,|Albert Einstein College of Medicine, Bronx, NY|
|1026|,|Emori, Y|,|Tokyo University, Tokyo, Japan|
|2379|,|Enan, Essam|,|Vanderbilt University, Nashville, TN|
|SEE|,|Encalada, Sandra|,|Scripps Research Institute, La Jolla, CA|
|4164|,|Endy, Drew|,|Stanford University, Stanford, CA|
|1531|,|Engebrecht, JoAnne|,|University of California, Davis, CA|
|2720|,|Engleman, Eric|,|Indiana University School of Medicine, Indianapolis, IN|
|2076|,|Eo, Jinu|,|National Agricultural Research Center, Tsukuba, Ibaraki, Japan|
|HE|,|Epstein, Henry|,|Baylor College of Medicine, Houston, TX|
|4088|,|Epureanu, Bogdan|,|University of Michigan, Ann Arbor, MI|
|ERC|,|Ercan, Sevinc|,|New York University, New York, NY|
| 571|,|Eremia, Dan|,|University of Medicine and Pharmacology, Bucharest, Romania|
|2711|,|Erickson, Patti|,|Salisbury University, Salisbury, MD|
|3227|,|Erickson, Patti|,|Salisbury University, Salisbury, MD|
|3380|,|Ericson, Henrik|,|University of Skovde, Skovde, Sweden|
|MAE|,|Ermolaeva, Maria|,|Leibniz Institute for Age Research, FLI, Jena, Germany|
|CBC|,|Ernstrom, Glen|,|Middlebury College, Middlebury, VT|
|2463|,|Eroshenko, Galina|,|Russian Anti-Plague Research Institute, Saratov, Russia|
| 614|,|Esko, Jeffrey|,|University of California, San Diego, CA|
| 829|,|Esnard, Joseph|,|Cornell University, Ithaca, NY|
|JES|,|Espeut, Julien|,|CNRS-CRBM, Montpellier, France|
|4306|,|Esser, Philipp|,|University Medical Center Freiburg, Freiburg, Germany|
|3159|,|Essig, David|,|Geneva College, Beaver Falls, PA|
|1766|,|Estes, Suzanne|,|Portland State University, Portland, OR|
|AYE|,|Estevez, Ana|,|St. Lawrence University, Canton, NY|
|OM|,|Estevez, Miguel|,|University of Arizona, Tuscon, AZ|
|KME|,|Esvelt, Kevin|,|Wyss Institute at Harvard Medical School, Boston MA|
| 261|,|Ettensohn, Charles|,|Carnegie Mellon University, Pittsburgh, PA|
|IE|,|Eurotag Consortium|,|IMBB, Heraklion, Crete, Greece|
|3321|,|Evans, James|,|Vala Sciences Inc., San Diego, CA|
|4086|,|Evans, Ronald|,|The Salk Institute, La Jolla, CA|
|TE|,|Evans, Tom|,|UCHSC, Denver, CO|
|IG|,|Ewbank, Jonathan|,|Centre d'Immunologie, Marseille, France|
|2375|,|Ewers, Christa|,|Free University Berlin, Berlin, Germany|
|CE|,|Exelixis Inc.|,|Exelixis Inc., San Francisco, CA|
|1690|,|Exil, Vernat|,|Vanderbilt University Medical Center, Nashville, TN|
|1523|,|Exiqon A/S|,|Vedbaek, Denmark|
|FE|,|Faergeman, Nils|,|University of Southern Denmark, Odense, Denmark|
|4256|,|Fagan, Troy|,|The University of Findlay, Findlay, OH|
|1022|,|Fagerholm, Hans-Peter|,|Huso Biologiska Station, Emkarby, Finland|
| 444|,|Fahey, Deb|,|Wheaton College, Norton, MA|
|2318|,|Fahey, Jed|,|Johns Hopkins School of Medicine, Baltimore, MD|
|RPF|,|Fairman, Robert|,|Haverford College, Haverford, PA|
|4202|,|Falciani, Francesco|,|University of Liverpool, Liverpool, UK|
|MJF|,|Falk, Marni|,|Children's Hospital of Philadelphia, Philadelphia, PA|
|2081|,|Falke, Scott|,|William Jewel College, Liberty, MO|
|3357|,|Fan, Heng-Yu|,|Zhejiang University, Hangzhou, China|
|PU|,|Fan, Qichang|,|Peking University, Beijing, China|
|3042|,|Fan, Sai-Jun|,|Soochow University, Soochow, China|
|1752|,|Fanelli, Elena|,|Bari University, Bari, Italy|
|2900|,|Fang, Chongye|,|Yunan Agriculture University, China|
|1958|,|Fang, Deyu|,|University of Missouri, Columbia, MO|
|YX|,|Fang-Yen, Christopher|,|University of Pennsylvania, Philadelphia, PA|
|LF|,|Fantz, Douglas|,|Agnes Scott College, Decatur, GA|
|NP|,|Fares, Johnny|,|University of Arizona, Tucson, AZ|
|1886|,|Farese, Bob|,|Harvard School of Public Health, Boston, MA|
|3732|,|Farmer, Mark|,|University of Georgia, Athens, GA|
|3467|,|Farone, Anthony|,|Middle Tennesee State University, Murfreesboro, TN|
|3731|,|Farris, Mindy|,|University of Central Arkansas, Conway, AR|
|1673|,|Farshchian, M|,|Tarbiat Modarres University, Tehran, Iran|
|3436|,|Fast, David|,|Analytical Sciences, AMWAY, Ada, MI|
|2951|,|Faupel. Michael|,|Bielefeld University, Bielefeld, Germany|
|WY|,|Fay, David|,|University of Wyoming, Laramie, WY|
|1082|,|Faye, Ingrid|,|University of Stockholm, Sweden|
|2908|,|Fazheng, Ren|,|Key Lab of Functional Dairy, China Agricultural Univ, China|
|2630|,|Fear, Mark|,|University of Western Australia, Crawley, Australia|
|3066|,|Featherston, Katie|,|Keane State College, Keene, NH|
| 778|,|Fehlhaber, Beate|,|Inst of Medical Microbiol, Medical Hochschule Hannover, Hannover, Germany|
|3202|,|Fehon, Rick|,|University of Chicago, Chicago, IL|
|2546|,|Fei, Jian|,|Tongji University, Shanghai, China|
|3030|,|Fei, Shi|,|Peking Union Medical College, Beijing, China|
| 441|,|Fei, You-Jun|,|Medical College of Georgia, Augusta, GA|
|1197|,|Feirer, Russ|,|St. Norbert College, De Pere, WI|
|JLF|,|Feldman, Jessica|,|Stanford University, Stanford, CA|
|JU|,|Felix, Marie-Anne|,|Inst Biology of the Ecole Normale Supérieure, Paris, France|
|1972|,|Femto, Adela|,|University of Texas, Austin, TX|
|1425|,|Feng, Jianying|,|MedStar Research Institute, Washington, DC|
|2626|,|Feng, Qili|,|South China Normal University, Guangzhou, China|
|JZF|,|Feng, Zhaoyang (John)|,|Case Western Reserve University, Cleveland, OH|
|1764|,|Fenster, Catherine|,|College of Wooster, Wooster, OH|
|EF|,|Ferguson, Chip|,|University of Chicago, IL|
| 511|,|Ferguson, Mike|,|Coastal Carolina University, Conway, SC|
|FG|,|Ferkey, Denise|,|State University of New York, Buffalo, NY|
|AGF|,|Fernandez, Anita|,|Fairfield University, Fairfield, CT|
|SVQ|,|Fernandez-Chacon, Rafael|,|University of Sevilla, Seville, Spain|
|2046|,|Fernandez-Robledo, Jose-Antonio|,|University of Maryland Biotechnology Institute, Baltimore, MD|
|3024|,|Ferrando, Sara|,|University of Genoa, Genoa, Italy|
|2949|,|Ferree, Patrick|,|Claremont McKenna, Pitzer and Scripps Colleges, Claremont, CA|
|HFW|,|Ferreira, Helder|,|University of St Andrews, Fife, Scotland|
|3455|,|Ferrer, LLuis Arola|,|CTNS University of Rovira i Virgili, Tarragona, Spain|
| 622|,|Ferris, Howard and Carey, James|,|University of California, Davis, CA|
| 278|,|Ferris, Judith|,|Schreiber High School, Fort Washington, NY|
| 231|,|Fesus, Laszlo|,|University Medical School of Debrecen, Hungary|
|2065|,|Feuiloley, Marc|,|University of Rouen, Evreux, France|
|2650|,|Fields, Stephen|,|East Central University, Ada, OK|
|4297|,|Fierst, Janna|,|University of Alabama, Tuscaloosa, AL|
|4143|,|Figueira, Antonio|,|Universidade de Sao Paulo, Sao Paulo, Brazil|
|3163|,|Filser, Julie|,|Bremen University, Bremen, Germany|
|FN|,|Finger, Fern|,|Rensselaer Polytechnic Institute, Troy, NY|
|3704|,|Fink, Ryan|,|University of Minnesota, St. Paul, MN|
|1601|,|Finkenstadt, Patricia|,|Ashland University, Ashland, OH|
|1422|,|Finlayson, Keith|,|University of Edinburgh, Edinburgh, Scotland|
|PD|,|Fire, Andy|,|Stanford University, Stanford, CA|
|1978|,|Firestein,|,|Columbia University, New York, NY|
|3182|,|First, Eric|,|Louisiana State University Health Sciences Center, Shreveport, LA|
|2322|,|Fischer, Antje|,|Charite-Universitatsmedicine, Berlin, Germany|
|3047|,|Fischer, Barbara|,|University of Innsbruck, Innsbruck, Austria|
|WFK|,|Fischle, Wolfgang|,|King Abdullah University of Science & Tech, Thuwal, Saudi Arabia|
|4082|,|Fishel, Barbara|,|The Hockaday School, Dallas, TX|
|2197|,|Fisher Scientific|,|Pttsburgh, PA|
|ALF|,|Fisher, Alfred|,|University of Texas Health Science Center, TX|
|1602|,|Fisher, Dane|,|Pfeiffer University, Misenheimer, NC|
|3897|,|Fisher, Nathan|,|North Dakota State University, Fargo, ND|
|DF|,|Fitch, David|,|New York University, New York|
|2059|,|Fitsanakis, Vanessa|,|King College, Bristol, TN|
| 378|,|Fitzgerald, Paul|,|LXR Biotechnology Inc, Richmond, CA|
| 476|,|Fitzpatrick, Patrick|,|The Westminster Schools, Atlanta, GA|
|2717|,|Fiumera, Anthony|,|Binghamton University, Binghamton, NY|
| 993|,|Flack, Earl|,|Pennsylvania Department of Agriculture, Harrisburg, PA|
|1880|,|Flaherty, Denise|,|Eckerd College, St. Petersburg, FL|
|NFB|,|Flames Bonilla, Nuria|,|Instituto de Biomedicina de Valencia (IBV-CSIC), Valencia, Spain|
| 263|,|Fleming, John|,|Massachusetts General Hospital, Boston, MA|
|1125|,|Flemming, Anthony|,|Syngenta, Bracknell, Berkshire, UK|
|1078|,|Fletcher, Jacqueline|,|Oklahoma State University, Stillwater, OK|
|3063|,|Flotow, Horst|,|Experimental Therapeutics Centre, Singapore|
|1833|,|Flynn, Daniel|,|West Virginia School of Medicine,|
|AF|,|Fodor, Andras|,|Hungarian Academy of Science, Szeged|
|2899|,|Foegen, Mary|,|Kimberly-Clark Corp, Neenah, WI|
|4292|,|Fong, Stephen|,|Virginia Commonwealth University, Richmond, VA|
|HD|,|Fontana, Walter|,|Harvard Medical School, Boston, MA|
|2524|,|Forbes, Mark|,|Carleton University, Ottawa, Ontario, Canada|
|2764|,|Ford, Rosemary|,|Washington College, Chestertown, MD|
|4051|,|Forrester, Sean|,|University of Ontario, Oshawa, Ontario, Canada|
|WF|,|Forrester, Wayne|,|Indiana University, Bloomington, IN|
|1801|,|Fort Dodge Animal Health|,|Monmouth Junction, NJ|
|1589|,|Forte, John|,|University of California, Berkeley, CA|
|1386|,|Fortin, Yves|,|National Research Council Canada, Montreal, Quebec, Canada|
|4356|,|Foster, Jan|,|North Greenville University, Tigerville, SC|
|1632|,|Foster, Lisa-Anne|,|Trinity College, Hartford, CT|
|3521|,|Foth, Heidi|,|Martin Luther University Halle-Wittenberg, Halle, Germany|
|IZ|,|Francis, Michael|,|University of Massachusetts, Worcester, MA|
|ARF|,|Frand, Alison|,|University of California, Los Angeles, CA|
|3168|,|Frank, Hans-Georg|,|Universitat Munchen, Munich, Germany|
|3557|,|Franke, Josef|,|University of Nebraska, Omaha, NE|
|3779|,|Frankel, Stewart|,|University of Hartford, West Hartford, CT|
|1623|,|Franklund, Clifton|,|Ferris State University, Big Rapids, MI|
|ANF|,|Fraser, Andrew|,|University of Toronto, Toronto, Ontario, Canada|
|4177|,|Fravalo, Philippe|,|University of Montreal, Quebec, Canada|
|DWF|,|Freckman, Diana|,|Colorado State University, Fort Collins, CO|
|2392|,|Frederic, Melissa|,|Universitaire de Recherche Clinique, Montpellier, France|
|JF|,|Freedman, Jonathan|,|University of Louisville School of Medicine, Louisville, KY|
|1364|,|Freeman, Fiona|,|Nottingham Trent University, Nottingham, UK|
|1155|,|Freeman, Mason|,|MGH-Harvard, Boston, MA|
|2859|,|Frenkiel-Krispin, Daphna|,|Sourasky Medical Center, Tel-Aviv, Israel|
|3859|,|Fretham, Stephanie|,|Luther College, Decorah, IA|
|3870|,|Frick, Julia-Stefanie|,|University of Tuebingen, Tuebingen, Germany|
|1527|,|Friedberg|,|University of Texas Southwestern, Dallas, TX|
|3414|,|Friesen, Mona|,|Universite de Saint-Boniface, Winnipeg, MB, Canada|
|4018|,|Frietas, Jason|,|Nabsys, Inc., Providence, RI|
|3809|,|Frisby, Dennis|,|Cameron University, Lawton, OK|
|2755|,|Frisen, Jonas|,|Karolinska Institute, Solna, Sweden|
|3125|,|Fritsch, Anja|,|CONFARMA France SARL,Hombourg, France|
|2075|,|Froebius, Andreas|,|Justus-Liebig-University, Giessen, Germany|
|1588|,|Frokjaer-Jensen, Christian|,|Panum Institute, Copenhagen, Denmark|
|WBF|,|Frommer, Wolf|,|Carnegie Institution for Science, Stanford, CA|
|3213|,|Fu, Ru-Huei|,|Inst Immunology & Neuropsych, China Medical Univ, Taichung, Taiwan|
|4196|,|Fu, Xin-Yuan|,|National University of Singapore, Singapore|
|3828|,|Fu, Zidong|,|Harbin Medical University, Harbin, China|
|2028|,|Fuchs, Thilo|,|Technical University of Munich, Freising, Germany|
|1485|,|Fuhrman, Juliet|,|Tufts University, Medford MA|
|3225|,|Fujii, Michihiko|,|Yokohama City University, Yokohama, Japan|
|2539|,|Fujiki, Yukio|,|Kyushu University, Fukuoka, Japan|
| 696|,|Fujisawa Pharmaceutical Company|,|Osaka, Japan|
|2761|,|Fujiwara, Toshinobu|,|Kobe University, Japan|
|TKB|,|Fukamizu, Akiyoshi|,|University of Tsukuba, Ibaraki, Japan|
| 787|,|Fukuda, Makoto|,|Kyoto University, Kyoto, Japan|
|2419|,|Fukuhara, Toshiyuki|,|Tokyo University of Agri. & Tech., Tokyo, Japan|
|2378|,|Fukushima, M|,|Kyoto University, Kyoto, Japan|
| 619|,|Fulcher, Kerry|,|Point Loma Nazarene University, San Diego, CA|
|2913|,|Funato, Yosuke|,|Institute for Protein Research, Osaka University, Osaka, Japan|
|AMF|,|Furger, Andre|,|University of Oxford, Oxford, England, UK|
|3130|,|Furrer, Jason|,|University of Missouri, Columbia MO|
|1326|,|Furukawa, Takahisa|,|Osaka Bioscience Institute, Osaka, Japan|
|4269|,|Furukawa, Yoshiaki|,|Keio University, Yokohama, Japan|
|3782|,|Fusco, Anthony|,|Firefly BioWorks, Cambridge, MA|
| 784|,|Futai, M|,|Osaka University, Osaka, Japan|
|2097|,|GE Healthcare|,|Piscataway, NJ|
|2921|,|Gabel, Christopher|,|Boston University, Boston, MA|
|2043|,|Gabriel, Dean|,|University of Florida, Gainesville, FL|
|4272|,|Gadekar, Sarang|,|Maharashtra Hybrid Seeds Company Pvt. Ltd., Jalna, India|
|2293|,|Gaestel,|,|Medizinische Hochschule, Hannover, Germany|
|2176|,|Gaestel, Matthias|,|Medizinishce Hochschule Hannover, Hannover, Germany|
|3068|,|Gaillard, Anne|,|Sam Houston State University, Huntsville, TX|
|IPE|,|Gainutdinov, Marat|,|Tatarstan Academy of Sciences, Kazan, Russia|
|3651|,|Gajdosik-Nivens, Delana|,|Armstrong Atlantic State University, Savannah, GA|
|2894|,|Galande, Sanjeev|,|Indian Inst Sci Educ Res, Pune, India|
|1412|,|Galas, Simon|,|CRBM-CNRS, Montpellier, France|
|3469|,|Galbraith, Elizabeth|,|DuPont Nutrition and Health, Waukesha, WI|
|2453|,|Galina, Eroshenko|,|Universitetskaya, Sartatov, Russia|
|4262|,|Gallant, Jason|,|Michigan State University, East Lansing, MI|
|DQ|,|Gallegos, Maria|,|California State University East Bay, Hayward, CA|
|3595|,|Galles, Celina|,|CST-Rosario Institute of Molecular & Cell Biology, Rosario, Argentina|
|2794|,|Galliot, Brigitte|,|University of Geneva, Switzerland|
|3367|,|Gallo, Carla|,|Universidad Peruana Cayetano Heredia, Lima, Peru|
|VIG|,|Galy, Vincent|,|Universite Pierre et Marie Curie, Paris, France|
|3378|,|Gamerdinger, Martin|,|University of Konstanz, Konstanz, Germany|
|3540|,|Ganesan, K|,|Institute of Microbial Technology, Chandigarh, India|
| 462|,|Ganetzky, Barry|,|University of Wisconsin, Madison, WI|
|3627|,|Ganji, Satish|,|Mississippi State University, Starkville, MS|
|4322|,|Ganley-Leal, Lisa|,|STC Biologics, Inc. Cambridge, MA|
|3018|,|Gao, Guifeng|,|Chinese Academy of Sciences, China|
|4184|,|Gao, Liang|,|Stony Brook University, Stony Brook, NY|
|1423|,|Gao, Qingshen|,|Northwestern University, Evanston, IL|
|1736|,|Gao, Yunfei|,|Yale School of Medicine, New Haven, CT|
|3708|,|Garber, John|,|Massachusetts General Hospital, Boston, MA|
|1679|,|Garcia, Christine|,|University of Texas Southwestern, Dallas, TX|
|1811|,|Garcia, Dana|,|Texas State University, San Marcos, TX|
|MEG|,|Garcia, Madeleine|,|INSERM, Marseille, France|
|CG|,|Garcia, Rene|,|Texas A&M University, College Station, TX|
|3470|,|Garcia, Solange Cristina|,|Federal University of Rio Grande do Sul UFRGS, Porto Alegre, Brazil|
|AJ|,|Garcia-Anoveros, Jamie|,|Northwestern University, Chicago, IL|
|2456|,|Garcia-Arraras, Jose|,|University of Puerto Rico, Rio Piedras, Puerto Rico|
|4169|,|Garcia-Herrero, Francisco|,|Universidad de Murcia, Espinardo, Murcia, Spain|
| 655|,|Gardner, Kathy|,|University of Pittsburgh, Pittsburgh, PA|
|2245|,|Gargus, J|,|University of California, Irvine, CA|
|2004|,|Garrett, Jinnie|,|Hamilton College, Clinton, NY|
|NG|,|Garriga, Gian|,|University of California, Berkeley, CA|
|2839|,|Garrigan, Daniel|,|University of Rochester, Rochester, NY|
|JAZ|,|Garrison, Jennifer|,|Buck Institute, Novato, CA|
|2363|,|Garrison, Nathan|,|Boston University, Boston, MA|
|2461|,|Garside, Christopher|,|University of Ontario, Ontario, Canada|
|GF|,|Garsin, Danielle|,|University of Texas, Houston, TX|
|TG|,|Gartner, Anton|,|University of Dundee, Dundee, UK|
|1314|,|Garvis, Steve|,|CNRS, Marseille, France|
|3254|,|Gasnier, Bruno|,|Université Paris Descartes, Paris, France|
|RBG|,|Gasser, Robin|,|University of Melbourne, Werribee, Victoria, Australia|
|GW|,|Gasser, Susan|,|Friedrich Miescher Institute, Basel, Switzerland|
|GCP|,|Gassmann, Reto & Carvalho, Ana|,|IBMC, Porto, Portugal|
|GD|,|Gaudet, Jeb|,|University of Calgary, Calgary, Alberta, Canada|
|2863|,|Gaugler, Randy|,|Rutgers University, New Brunswick, NJ|
| 757|,|Gazzotti, Paolo|,|ETH-Zentrum, Zurich, Switzerland|
|1749|,|Ge, Baoxue|,|Chinese Academy of Sciences, Shanghai, China|
|3089|,|Ge, Fang|,|Inst of Zoology, Chinese Academy of Sciences,|
|2177|,|Ge, Hui|,|Whitehead Institute, Cambridge, MA|
|2522|,|Geary, Tim|,|McGill University, Ste. Anne de Bellevue, Quebec, Canada|
|3375|,|Geib, Scott|,|USDA ARS PBARC, Hilo, HI|
| 467|,|Geier, Gebhard|,|University of Heidelberg, Germany|
|1781|,|Geisler, Matt|,|University of Western Ontario, London, Ontario, Canada|
|1348|,|Geiszt, Miklos|,|Semmel Weis University, Pudapest, Hungary|
|3427|,|Geldenhuys, Werner|,|Northeast Ohio Medical University, Rootstown OH|
|1619|,|Geldof, Peter|,|Moredun Research Institute, Edinburgh, UK|
|AVB|,|Geller, Bruce|,|AVI BioPharma, Corvalis, OR|
|GA|,|Gems, David|,|University College, London, England|
|2570|,|GenScript Corporation|,|Piscataway, NJ|
|GNW|,|Gene Names at WormBase -- Tim Schedl|,|Washington University, St. Louis MO|
| 344|,|Gengyo-Ando, Keiko|,|National Defense Medical College, Saitama, Japan|
|QJ|,|Gengyo-Ando, Keiko|,|Saitama University, Saitama, Japan|
| 331|,|Gennero, Don|,|University of San Diego, CA|
| 815|,|George, Al|,|Vanderbilt University, Nashville, TN|
| 719|,|Gerst, Jeffrey|,|Weizmann Institute of Science, Rehovot, Israel|
|1969|,|Geschwind,|,|University of California, Los Angeles, CA|
|AGP|,|Ghazi, Arjumand|,|University of Pittsburgh School of Medicine, Pittsburgh, PA|
|ELG|,|Ghedin, Elodie|,|University of Pittsburgh, Pittsburgh PA|
|NBR|,|Ghosh Roy, Anindya|,|National Brain Research Center (NBRC). Gurgaon, Haryana, India|
|3399|,|Gibert, Isidre|,|de Autonomous University of Barcelona, Barcelona, Spain|
|RGD|,|Giblin-Davis, Robin|,|University of Florida, Fort Lauderdale, FL|
| 665|,|Gibson, Greg|,|North Carolina State University, Raleigh, NC|
|TGF|,|Gidalevitz, Tali|,|Drexel University, Philadelphia, PA|
|KAG|,|Gieseler, Kathrin|,|Universite Claude Bernard, Lyon, France|
|3910|,|Gijs, Martin|,|EPFL, Lausanne, Switzerland|
|MGL|,|Gill, Matthew|,|Scripps Research Institute, Jupiter, FL|
|1740|,|Gill, Sarjeet|,|University of California, Riverside, CA|
|JG|,|Gilleard, John|,|University of Calgary, Calgary, Alberta, Canada|
|2606|,|Gilman, Sharon|,|Coastal Carolina University, Conway, SC|
| 785|,|Gilula,|,|Scripps Research Institute, La Jolla, CA|
|1521|,|Ginzton,|,|Stanford University, Stanford, CA|
|3325|,|Giorgetti, Sofia|,|University of Pavia , Pavia, Italy|
|2655|,|Giraldo, Adriana Jimena Bernal|,|Universidad de los Andes, Bogota, Colombia|
|DN|,|Gissendanner, Chris|,|University of Louisiana, Monroe, LA|
|4042|,|Gitai, Zemer|,|Princeton University, Princeton, NJ|
|2085|,|Gitlin,|,|Washington University, St. Louis, MO|
| 512|,|Gitschier, Jane|,|University of California, San Francisco, CA|
|EEG|,|Glater, Elizabeth|,|Pomona College, Claremont, CA|
|DAG|,|Glauser, Dominique|,|Université de Fribourg, Fribourg, Switzerland|
| 939|,|Glaxo SmithKline|,|Durham, NC|
|2544|,|GlaxoSmthKline R & D|,|Shanghai, China|
| 233|,|Glazer, Itamar|,|A.R.O. Volcani Center, Israel|
|1897|,|Gleason, Darius|,|University of California, Irvine, CA|
|1375|,|Glebov, Konstantin|,|Gottingen, Germany|
|3070|,|Gleicher, Ruth|,|Niles West High School, Skokie. IL|
|MG|,|Glotzer, Michael|,|University of Chicago, Chicago, IL|
|2343|,|Glover, Anne|,|University of Aberdeen, Aberdeen, Scotland|
|2500|,|Glover, Kathy|,|Science Museum of Minnesota, St. Paul, MN|
| 681|,|Glynn, Paul|,|MRC Toxicology Unit, Leicester, U.K.|
|3804|,|Gnarra, James|,|Thiel College, Greenville, PA|
|VJ|,|Gobel, Verena|,|Massachusetts General Hospital, Boston, MA|
| 369|,|Goday, Clara|,|Consejo Superior de Investigaciones Cientificas, Madrid, Spain|
|4044|,|Godbole, Ashwini|,|ITD-HST, Bangalore, India|
|2578|,|Goddard, Isobel|,|Defence Science and Technology Lab, Salisbury, Wilts, UK|
|3510|,|Godoy, Veronica|,|Northeaster University, Boston, MA|
|NWG|,|Goehring, Nathan|,|The Francis Crick Institute, London, UK|
|APD|,|Goetz, Jurgen|,|University of Sydney, Camperdown, Australia|
|MLG|,|Goldberg, Mike|,|Cornell University, Ithaca, NY|
|AG|,|Golden, Andy|,|NIDDK/NIH, Bethesda, MD|
| 601|,|Goldsbrough, Peter|,|Purdue University, West Lafayete, IN|
|LP|,|Goldstein, Bob|,|University of North Carolina, Chapel Hill, NC|
|2962|,|Goldstein, Daniel|,|Boston University, Boston, MA|
|1537|,|Goldstein, Jessica|,|Barnard College, New York, NY|
| 496|,|Golembiewski, Terre|,|University of Wisconsin, Whitewater, WI|
|1756|,|Golomb, Miriam|,|University of Missouri, Columbia, MO|
|1424|,|Golombek, D|,|Universidad Nacional de Quilmes, Buenos Aires, Argentina|
|2799|,|Goloubinoff, Pierre|,|University of Lausanne, Switzerland|
|WBX|,|Gomes, Jose-Eduardo|,|Universite Bordeaux Segalen, Bordeaux, France|
|4333|,|Gomez Rincon, Carlota|,|Universidad San Jorge, Villanueva de Gallego, Spain|
|2592|,|Gomez, Eduardo|,|Center for Disease Control, Atlanta, GA|
|1406|,|Gomez, Marie|,|University of Geneva, Geneva, Switzerland|
|1631|,|Goncalves Vieira, Jose|,|Universidade Federal de Goias, Goias, Brazil|
|GZ|,|Gonczy, Pierre|,|EPFL, Lausanne, Switzerland|
|3294|,|Gong, Joshua|,|Guelph Food Research Centre, Agri-Food Canada, Guelph, Canada|
|3459|,|Gonos, Efstathios|,|Institute of Biology, National Hellenic Research Foundation, Athens, Greece|
|3320|,|Gonzalez Navarro, Carlos Javier|,|National Centre for Technology and Food Safety (CNTA), San Adrian, Spain|
|3359|,|Gonzalez, Juan Carlos|,|Centro de Investigaciones Biologicas del Noroeste, La Paz. Mexico|
|4080|,|Gonzalez-Estevez, Cristina|,|FLI Leibniz-Institute for Age Research, Jena, Germany|
|1903|,|Gonzalez-Plaza, Roberto|,|Northwest Indian College, Bellingham, WA|
|3184|,|González-Estévez, Cristina|,|University of Nottingham, Nottingham, UK|
|2892|,|Good, Liam|,|Royal Veterinary College, London, UK|
|2978|,|Good, Theresa|,|University of Maryland - Baltimore County, Baltimore MD|
|1246|,|Goodall, Gordon|,|University of Otago, Dunedin, New Zealand|
|GN|,|Goodman, Miriam|,|Stanford University, Stanford, CA|
| 888|,|Goodner, Brad|,|University of Richmond, Richmond, VA|
|BG|,|Goodwin, Betsy|,|University of Wisconsin, Madison, WI|
|3861|,|Gordon, David|,|Beloit College, Beloit, WI|
|3650|,|Gore, Jeff|,|Massachusetts Institute of Technology, Cambridge, MA|
|1845|,|Gorlich,|,|University of Heidelberg, Heidelberg, Germany|
|YC|,|Goshima, Yoshio|,|Yokohama City University, Yokohama, Japan|
|ZU|,|Gotta, Monica|,|Universite de Geneve, Geneva Switzerland|
|ZX|,|Gottschalk, Alexander|,|University of Frankfurt, Frankfurt, Germany|
|1095|,|Gou, Xinghua|,|Chinese Academy of Sciences, Chengdu, Sichuan, PR China|
|1015|,|Gould, Meredith|,|Universidad Autonoma de Baja California, Ensenada, Mexico|
|3857|,|Goulding, Morgan|,|Bethel University, McKenzie, TN|
|AC|,|Goutte, Caroline|,|Amherst College, Amherst, MA|
|2573|,|Gow,|,|Anna Maria College, Paxton, MA|
|3272|,|Goyal, Ravi|,|Loma Linda University, Loma Linda, CA|
|1435|,|Gracey, Andrew|,|University of Southern California, Los Angeles, CA|
|4329|,|Gracie, Andrew|,|HostProds, Inc., Barcelona, Spain|
|1713|,|Graeme-Cook, Kate|,|University of Herfordshire, Hertfordshire, England|
|2490|,|Graff, Jonathan|,|University of Texas Southwestern Medical Center, Dallas, TX|
|4219|,|Graham, Andrea|,|Princeton University, Princeton, NJ|
|PG|,|Graham, Patricia|,|Carthage College, Kenosha, WI|
|3157|,|Gram, Lone|,|Technical University of Denmark, Lyngby, Denmark|
|1330|,|Grammer, Bob|,|Belmont University, Nashville, TN|
|TMG|,|Grana, Theresa|,|University of Mary Washington, Fredericksburg, VA|
|3928|,|Grane, Sergio|,|ETYCA Research, Barcelona, Spain|
|1060|,|Grant, Alastair|,|University of East Anglia, Norwich, U.K.|
|RT|,|Grant, Barth|,|Rutgers University, Piscataway, NJ|
|4003|,|Grant, Struan|,|Children's Hospital of Philadelphia, Philadelphia, PA|
|WG|,|Grant, Warwick|,|La Trobe University, Bundoora, Victoria, Australia|
|4304|,|Grau, Roberto|,|Rosario National University, Rosario,  Argentina|
|2523|,|Gravel, Roy|,|University of Calgary, Calgary, Alberta, Canada|
|GV|,|Graves, Barbara|,|University of Utah, Salt Lake City, UT|
|1354|,|Gravina, Marcelo|,|Universidade Federal do Rio Grande do Sul, Porto Alegre, Brazil|
|2860|,|Gravis, Demetrius|,|Beloit College, Beloit, WI|
|1620|,|Gray, Vince|,|University of the Witwatersrand, Johannesburg, South Africa|
|1000|,|Greberg, Marika Hellqvist|,|Goteborg University, Goteborg, Sweden|
| 753|,|Greenbaum, Nancy|,|Florida State University, Tallahassee, FL|
|1162|,|Greenberg|,|Children's Hospital, Boston, MA|
| 907|,|Greenberg, Ann|,|Woodbridge High School, Woodbridge, NJ|
|2743|,|Greenberg, Robert|,|University of Pennsylvania, Philadelphia, PA|
|4213|,|Greene, Annel|,|Clemson University, Clemson, SC|
|DG|,|Greenstein, David|,|University of Minnesota, Minneapolis, MN|
|GS|,|Greenwald, Iva|,|Columbia University, New York, NY|
|EZE|,|Greer, Eric|,|Children's Hospital Boston, Boston, MA|
|2274|,|Gregory, T. Ryan|,|University of Guelph, Guelph, ON, Canada|
|2250|,|Greider, Carol|,|Johns Hopkins University, Baltimore, MD|
|SGR|,|Greiss, Sebastian|,|University of Edinburgh, Edinburgh, Scotland|
|3331|,|Gribble, Suzanna|,|Grove City College, Grove City, PA|
|3457|,|Griffin, Erik|,|Dartmouth College, Hanover, NH|
|XMN|,|Grill, Brock|,|Scripps Research Institute, Jupiter, FL|
|SWG|,|Grill, Stephen|,|Technische Universitat Dresden, Dresden, Germany|
|2884|,|Grillari, Johannes|,|Vienna Institute of BioTechnology, Vienna, Austria|
|JGG|,|Grillari, Johannes|,|Institute of Applied Microbiology, Vienna, Austria|
|3830|,|Grimmelikhuijzen, Cornelus|,|University of Copenhagen, Copenhagen, Denmark|
|AGK|,|Grishok, Alla|,|Columbia University, New York, NY|
|1809|,|Groisman,|,|Washington University School of Medicine, St. Louis, MO|
|3997|,|Groneberg, David|,|Goethe-University of Frankfurt am Main, Frankfurt am Main, Germany|
| 456|,|Gronostajski, Richard|,|University at Buffalo, Buffalo, NY|
|1020|,|Groover, Robert|,|Bordertown High School, Bordertown, NJ|
|EVG|,|Gross, Einov|,|Hebrew University of Jerusalem, Jerusalem, Israel|
|2055|,|Gross, Jeff|,|University of Texas, Austin, TX|
|HW|,|Grosshans, Helge|,|Friedrich Miescher Institute, Basel, Switzerland|
|4117|,|Grossin, Nicolas|,|Centre de Recherche sur l'Inflammation, Lille, France|
|3801|,|Groth, Amy|,|Eastern Connecticut State University, Willimantic, CT|
|1289|,|Groussand, Pauline|,|Veterinary Laboratories Agency, Surrey, UK|
|4218|,|Gruber, Jan|,|Yale-NUS, Singapore|
|YG|,|Gruenbaum, Yosef|,|Hebrew University of Jerusalem, Jerusalem, Israel|
|3303|,|Grundler, F|,|Institute of Crop Science and Resource Conservation, Bonn, Germany|
|4104|,|Gruninger, Todd|,|Jesuit College Preparatory, Dallas, TX|
| 581|,|Grunstein, Michael|,|University of California, Los Angeles, CA|
|3711|,|Grussendorf, Kelly|,|Minnesota State University, Mankato, MN|
|CSS|,|Gu, Guoping (Sam)|,|Rutgers University, Piscataway, NJ|
|4010|,|Gu, Weifang|,|University of California, Riverside, CA|
|3916|,|Gu, Zhennan|,|Wake Forest University School of Medicine, Winston-Salem, NC|
|1910|,|Guan, Shuwen|,|Jinlin University, Changchun, China|
|SHG|,|Guang, Shouhong|,|USTC, Hefei, China|
|2244|,|Guangyue, Li|,|University of South China, Hunan Province, China|
|LG|,|Guarente, Leonard|,|MIT, Cambridge, MA|
| 383|,|Guerra, Catherine|,|Trinidad State Junior College|
|4009|,|Guha, Sujay|,|University of Bern, Bern, Switzerland|
|1609|,|Guilfoile, Patrick|,|Bemidji State University, Bemidji, MN|
|1642|,|Guinnee, Meghan|,|Buffalo State University, Buffalo, NY|
|4046|,|Guisbert, Eric|,|Florida Institute of Technology, Melbourne, FL|
|4271|,|Gulseren Cakmakci, Nihal|,|Koc University, Istanbul, Turkey|
|TLG|,|Gumienny, Tina|,|Texas Woman's University, Denton, TX|
|2887|,|Gunawan, Rudiyanto|,|National University of Singapore, Singapore|
|3807|,|Gunduz, Gulgun|,|Akdeniz Univerisity, Konyaalty, Turkey|
|2011|,|Gunn,|,|Cornell University, Ithaca, NY|
|GKC|,|Gunsalus, Kris|,|New York University, New York, NY|
|3397|,|Guo, Min|,|Wannan Medical College, Anhui, China|
|4161|,|Guo, Wei|,|Agriculture University of Hebei, Baoding, China|
|2672|,|Guo, Xiaokui|,|Shanghai Jiao Tong University, Shanghai, China|
|DY|,|Gupta, Bhagwati|,|McMaster University, Hamilton, Canada|
|2955|,|Gupta, KC|,|Indian Institute of Toxicology Research, Lucknow, India|
|1891|,|Gusarov, Ivan|,|New York University, New York, NY|
| 579|,|Gustafson, Jennifer|,|Northern Michigan University, Marquette, MI|
| 495|,|Gustine, David|,|USDA/ARS, Pasture Research Laboratory, University Park, PA|
|3299|,|Gutbrod, Philipp|,|INRES, University of Bonn, Germany|
| 423|,|Gutch, Michael|,|Cold Spring Harbor Laboratory, Cold Spring Harbor, NY|
|2811|,|Gutekunst, Claire-Anne|,|Emory University, Atlanta, GA|
|2842|,|Gutierrez-Trivino, Carolina|,|Pontificia Universidad Javeriana, Bogota, Colombia|
| 296|,|Gutkind, Silvio|,|NIH, National Institute of Dental Research, Bethesda, MD|
|1256|,|Guy, Hedeel|,|Wayne State University, Detroit, MI|
|3944|,|Gwinn, Kimberly|,|University of Tennessee, Knoxville, TN|
|3033|,|Gyenai, Kwaku|,|North Carolina A&T State University, Greensboro, NC|
|CP|,|Haag, Eric|,|University of Maryland, College Park, MD|
|1511|,|Haas, Christian|,|Ludwig Maximilians Univerisity, Munich, Germany|
|1087|,|Haase, Gerhard|,|University of Aachen, Aachen, Germany|
|1173|,|Haber, Daniel|,|Harvard Medical School, MGH, Charlestown, MA|
|2141|,|Haberman, Charlie|,|St. Edwards University, Austin, TX|
|3975|,|Haeberle, Henry|,|ThorLabs Inc., Sterling, VA|
|3752|,|Haefele, Mark|,|Community College of Denver, Denver, CO|
|GY|,|Hagen, Fred|,|University of Rochester, NY|
|1332|,|Hager, Steve|,|Augustana Collage, Rock Island, RI|
| 427|,|Hagiwara, Masatoshi|,|Nagoya University School of Medicine, Nagoya, Japan|
|KIR|,|Hagstrom, Kirsten|,|University of Massachusetts, Worcester, MA|
|1635|,|Hahn, Bum-Soo|,|National Institute of Agricultural Biotechnology, Suwon, Korea|
|3715|,|Haile, January|,|Centre College, Danville, KY|
| 504|,|Haitzer, Markus|,|Zoologisches Institut der LMU, Muenchen, Germany|
|1618|,|Hajela, Ravindra|,|Michigan State University, East Lansing, MI|
|AH|,|Hajnal, Alex|,|University of Zurich, Zurich, Switzerland|
| 488|,|Halbrendt, John|,|Pennsylvania State University, Biglerville, PA|
| 744|,|Hale, Larry|,|University of Prince Edward Island, P.E.I., Canada|
|MWP|,|Hall, David|,|Albert Einstein College of Medicine, Bronx, NY|
|2056|,|Hall, Jody|,|Brown University, Providence, RI|
|SEH|,|Hall, Sarah|,|Syracuse University, Syracuse, NY|
|EAH|,|Hallem, Elissa|,|University of California, Los Angeles, CA|
|1709|,|Halley, K.|,|University of Michigan, Ann Arbor, MI|
|1633|,|Halliday, Damien|,|CSIRO Sustainable Ecosystems, Canberra, Australia|
|1881|,|Halliwell, Barry|,|National University of Singapore, Singapore|
|3330|,|Hamacher-Brady, Anne|,|German Cancer Research Center, Heidelberg, Germany|
|MM|,|Hamelin, Michel|,|Merck Research Laboratories, Rahway, NJ|
|DX|,|Hamill, Danielle|,|Ohio Wesleyan University, Delaware, OH|
| 285|,|Hamill, Owen|,|University of Texas, Galveston, TX|
|XE|,|Hammarlund, Marc|,|Yale University School of Medicine, New Haven, CT|
|HML|,|Hammell, Chris|,|Cold Spring Harbor Laboratory, Cold Spring Harbor, NY|
|3404|,|Hammes, Hans Peter|,|Universitatsmedizin Mannheim, Mannheim, Germany|
|1755|,|Hammock,|,|University of California, Davis, CA|
|3206|,|Hammond, Adam|,|University of Chicago, Chicago, IL|
|2339|,|Hammond, Timothy|,|Durham VA Medical Center, Durham, NC|
|2607|,|Hampton, James|,|Buena Vista University, Storm Lake, IA|
| 927|,|Hamshere, Marion|,|University of Nottingham, Nottingham, England|
|IQ|,|Hamza, Iqbal|,|University of Maryland, College Park, MD|
|2278|,|Han, Chingtack|,|Sogang University, Seoul, South Korea|
|JDH|,|Han, Jackie|,|Shanghai Institutes of Biological Sciences, Shanghai, China|
|2803|,|Han, Jian|,|Pathogen Res Inst, Lanzhou University, China|
|MH|,|Han, Min|,|University of Colorado, Boulder|
|3121|,|Han, Yu|,|Northeast Petroleum University, Daqing, Heilongjiang, China|
|3001|,|Hang, Howard|,|Rockefeller University, New York, NY|
| 903|,|Hanigan, Marie|,|Oklahoma Med Research Foundation, Oklahoma City, OK|
|2309|,|Hanke, Viola|,|Federal Centre for Breeding Research on Cultivated Plants, Dresden, Germany|
|HV|,|Hanna-Rose, Wendy|,|Penn State, University Park, PA|
|GJH|,|Hannon, Gregory|,|Cold Spring Harbor Laboratory, Cold Spring Harbor, NY|
|3100|,|Hanover, John|,|NIH-NIDDK, Bethesda, MD|
|4284|,|Hansen, Allison|,|University of Illinois, Urbana, IL|
| 460|,|Hansen, Bente|,|University of Copenhagen, Copenhagen, Denmark|
|XB|,|Hansen, Dave|,|University of Calgary, Alberta, Canada|
|1605|,|Hansen, Dave|,|University of Calgary, Calgary, Alberta, Canada|
|2680|,|Hansen, Immo|,|New Mexico State University, Las Cruces, New Mexico|
|MAH|,|Hansen, Malene|,|Burnham Institute, La Jolla, CA|
|2283|,|Hanson, Barbara|,|Canisius College, Buffalo, NY|
|2846|,|Hanss, Basil|,|Mt Sinai School of Medicine, New York, NY|
|1222|,|Hanwha Chemical Company|,|Daejun, South Korea|
| 300|,|Hara, Mitsunobu|,|Tokyo Research Laboratories, Tokyo, Japan|
|2372|,|Harbour, Colin|,|University of Sydney, Sydney, Australia|
|SU|,|Hardin, Jeff|,|University of Wisconsin, Madison, WI|
|4058|,|Hardy, Don|,|Crown College, St Bonifacius, MN|
|1126|,|Harfe, Brian|,|Harvard Medical School, Boston, MA|
|1488|,|Harikrishna, Jenni|,|Malaysia University of Science & Technology, Selangor, Malaysia|
|3900|,|Harless, Meagan|,|Centenary College, Hackettstown, NJ|
| 264|,|Harlow, Ed|,|MGH Cancer Center, Charlestown, MA|
|1915|,|Harman, Amy|,|Frostburg State University, Frostburg, MD|
|3234|,|Harmon, Dan|,|Anoka-Ramsey Community College, Cambridge, MN|
|1689|,|Harmon, Sarah|,|University of South Carolina, Aiken, SC|
|3080|,|Harnett, William|,|University of Strathclyde, Glasgow, Scotland, UK|
|2496|,|Harper, Wade|,|Harvard Medical School, Boston, MA|
|1141|,|Harrington, Lea|,|Ontario Cancer Institute, University of Toronto, Toronto, Ontario, Canada|
| 276|,|Harris, Jack|,|Biology Department, Russell Sage College, Troy, NY|
|2511|,|Harris, Paul|,|AgResearch Limited, Hamilton, New Zealand|
|3116|,|Harrison, Dave|,|Jackson Laboratory, Bar Harbor, ME|
|HA|,|Hart, Anne|,|Brown University, Providence, RI|
|4208|,|Hartley, Louise|,|Liverpool John Moores University, Liverpool, England|
|PH|,|Hartman, Phil|,|Texas Christian University, Fort Worth, TX|
|4150|,|Hartmann, Alain|,|INRA Dijon, Dijon, France|
|1166|,|Hartmann, Susanne|,|Humboldt University at Berlin, Berlin, Germany|
|NPR|,|Harvey, Brandon|,|National Institute on Drug Abuse, Baltimore, MD|
|2514|,|Harvey, Simon|,|Canterbury Christ Church University, Canterbury, Kent, UK|
|KHA|,|Hasegawa, Koichi|,|Chubu University, Kasugai, Japan|
|2324|,|Hashmi, Sarwar|,|New York Blood Center, New York, NY|
|1489|,|Haslbeck, Martin|,|Technische Universitat Munchen, Garching, Germany|
|TOL|,|Haspel, Gal|,|New Jersey Institute of Technology, Newark, NJ|
|2704|,|Hass-Stapleton, Eric|,|California State University, Long Beach, CA|
|2874|,|Hata, Yutaka|,|Tokyo Medical & Dental Univ, Tokyo, Japan|
| 700|,|Hatahet, Zafer|,|University of Texas Health Center, Tyler, Texas|
|3947|,|Hattell, Emma|,|Prosetta Biosciences Inc., San Francisco, CA|
|1170|,|Hatten,|,|Rockefeller University, New York, NY|
|1560|,|Hattori, Kenji|,|Kyoritsu University of Pharmacy, Tokyo, Japan|
|CN|,|Haughn, George|,|University of British Columbia, Vancouver, Canada|
|3645|,|Hauser, Paul|,|San Francisco University High School, San Francisco, CA|
| 917|,|Hawdon, John|,|George Washington University Medical Center, Washington, DC|
| 869|,|Hawes, Martha|,|Dept of Plant Pathology, University of Arizona, Tucson, AZ|
|NN|,|Hawkins, Nancy|,|Simon Fraser University, Burnaby, BC, Canada|
|1726|,|Hay, Bruce|,|California Institute of Technology, Pasadena, CA|
|3352|,|Hay, Yuen Kah|,|Universiti Sains Malaysia, Pulau Pinang, Malaysia|
|UTK|,|Hayashi, Yu|,|Brain Science Inst RIKEN, Saitama, Japan|
|3889|,|Hayashi, Yu|,|University of Tsukuba, Ibaraki, Japan|
|CMH|,|Haynes, Cole|,|Memorial Sloan-Kettering Cancer Center, New York, NY|
| 745|,|Hayosh, Norma|,|University of Michigan, Ann Arbor, MI|
|1737|,|Hayward, Scott|,|University of Liverpool, Liverpool, UK|
|3822|,|He, DeFu|,|East China Normal Univeristy, Shanghai, China|
|2543|,|He, Guangcun|,|Wuhan University, Wuhan, China|
|4005|,|He, Jun & Emtage, Lesley|,|York College, CUNY, Jamaica, NY|
|1099|,|He, Xiaohua|,|University of Trier, Trier, Germany|
|4265|,|Heart, Emma|,|University of South Florida, Tampa, FL|
|HH|,|Hecht, Ralph|,|University of Houston, TX|
|2574|,|Heckel, David|,|MPI, Jena, Germany|
|3175|,|Heckeroth, Anja|,|MSD Animal Health, Schwabenheim, Germany|
|1758|,|Hedera, Peter|,|Vanderbilt University, Nashville, TN|
|NJ|,|Hedgecock, Ed|,|Johns Hopkins University, Baltimore, MD|
|3077|,|Hefner, Barbara|,|US Arid Land Agricultural Center, Maricopa, AZ|
| 852|,|Heger, Peter|,|Friedrich-Miescher Laboratory, Tuebingen, Germany|
| 879|,|Heid, Paul|,|Keck Dynamic Image Analysis Facility, University of Iowa, Iowa City, IA|
|CHB|,|Heiman, Max|,|Harvard Medical School - Children's Hospital, Boston, MA|
|4022|,|Heinemann, Udo|,|Max-Delbrück-Center for Molecular Medicine, Berlin, Germany|
|1300|,|Heinrichs, David|,|University of Western Ontario, London, Ontario, Canada|
|1268|,|Heints, Nat|,|Rockefeller University, New York, NY|
|3978|,|Heise, Susanne|,|Hamburg University of Applied Sciences, Hamburg, Germany|
|MQ|,|Hekimi, Siegfried|,|McGill University, Montreal, Quebec|
|3748|,|Held, Jason|,|Washington University School of Medicine, St. Louis, MO|
|IFP|,|Hench, Juergen|,|Institute of Pathology, Basel, Switzerland|
|3341|,|Henderson, Christopher|,|Columbia University, New York, NY|
|3583|,|Henderson, Melissa|,|Lincoln Memorial University, Harrogate, TN|
|XG|,|Henderson, Sam|,|GenoPlex Inc., Denver, CO|
|MMH|,|Hendricks, Michael|,|McGill University, Montreal, Quebec, Canada|
|2285|,|Hendriksen, Niels|,|University of Aarhus, Roskilde, Denmark|
|WS|,|Hengartner, Michael|,|University of Zurich, Zurich, Switzerland|
|1064|,|Henikoff, Steve|,|Fred Hutchinson Cancer Research Center, Seattle, WA|
|SHK|,|Henis-Korenblit, Sivan|,|Bar-Ilan University, Ramat-Gan, Israel|
|1100|,|Hennessey, Todd|,|State University of New York at Buffalo, Amherst, NY|
|2467|,|Herbert, DeBroski,|,|University of Cincinnati, Cincinnati, OH|
|SP|,|Herman, Bob|,|University of Minnesota, Minneapolis, MN|
|3034|,|Herman, Larry|,|University of California, Irvine, CA|
|KS|,|Herman, Mike|,|Kansas State University, Manhatten, KS|
|1728|,|Hermand, Damien|,|FUNDP-GEMO, Namur, Belgium|
|3062|,|Hermand, Damien|,|Academie Universitaire Louvain, Brussells, Belgium|
|GH|,|Hermann, Greg|,|Lewis and Clark College, Portland, OR|
|1061|,|Hernalsteens, Jean-Pierre|,|Vrije Universiteit Brussel, Belgium|
|2260|,|Hernandez, Leonardo|,|University of Guadalajara, Gauadalajara Jalisco, Mexico|
|3041|,|Herold-Mende, Christel|,|University of Heidelberg, Heidelberg, Germany|
|WHR|,|Herr, Winship|,|University of Lausanne, Lausanne, Switzerland|
| 415|,|Herschler, Michael|,|Otterbein College, Westerville, OH|
|2487|,|Hersen, Pascal|,|CNRS & University Paris Diderot, Paris, France|
|1002|,|Hertweck, Maren|,|Adolf-Butenandt-Institut, Muenchen, Germany|
| 509|,|Hess, George|,|Cornell University, Ithaca, NY|
|3326|,|Hesselberth, Jay|,|University of Colorado, Denver, CO|
|4102|,|Hewlett, Tom|,|Syngenta Crop Protection LLC, Alachua, FL|
|3518|,|Heymann, Jurgen|,|NIH/NIDDK, Bethesda, MD|
|4258|,|Hicks, Kiley|,|Newman University, Wichita, KS|
|3216|,|Hieter, Phil|,|University of British Columbia, Vancouver, BC, Canada|
| 615|,|Higashi, Naoki|,|Tokyo Metropolitan College, Tokyo, Japan|
|1416|,|Higashibata, Akira|,|Japan Aerospace Exploration Agency, Ibaraki, Japan|
| 454|,|Higashitani, Atsushi|,|National Institute of Genetics, Mishima, Japan|
|1057|,|High School Student, Multiple Users|,|Multiple Locations|
|4033|,|Hildreth, Michael|,|South Dakota State University, Brookings, SD|
|RCH|,|Hill, Robin Cook|,|University of Virginia College at Wise, Wise, VA|
|RH|,|Hill, Russell|,|Ohio State University, Columbus, OH|
|1878|,|Hillers, Ken|,|California Polytechnic State University, San Luis Obispo, CA|
|QH|,|Hilliard, Massimo|,|University of Queensland, St. Lucia, Queensland, Australia|
|1133|,|Hillyard, Luke|,|Food Science & Technology, UC Davis, Davis, CA|
|AHS|,|Hinas, Andrea|,|Uppsala University, Uppsala, Sweden|
|4214|,|Hines, Daniel|,|Gallaudet University, Washington, DC|
|4174|,|Hino, Akina|,|Tokyo Medical and Dental University, Tokyo, Japan|
|3504|,|Hinrichsen, Robert|,|Indiana University of Pennsylvania, Indiana, PA|
| 336|,|Hinson, Bobbie|,|Providence Day School, Charlotte, NC|
|3180|,|Hinterberger, Timothy|,|University of Alaska, Anchorge, AK|
|1579|,|Hirata, Taku|,|Kyorin Medical School, Tokyo, Japan|
|1799|,|Hirata, Taku|,|Kyorin Medical School, Mitaka City, Tokyo, Japan|
|HRT|,|Hirotsu, Takaaki|,|Kyushu University, Fukuoka, Japan|
|2186|,|Hirschberg, Carlos|,|Boston University, Boston, MA|
|DH|,|Hirsh, David|,|Columbia University, New York, NY|
|1913|,|Hoang, Quyen|,|Brandeis University, Waltham, MA|
|3276|,|Hoang, Tung|,|University of Hawaii, Manoa, HI|
|1458|,|Hobden, Jeffrey|,|Louisiana State University, New Orleans, LA|
|EPH|,|Hoberg, Eric|,|ARS, USDA, Beltsville, MD|
|OH|,|Hobert, Oliver|,|Columbia University, New York, NY|
|OTN|,|Hobert, Oliver|,|OTN, Columbia University, New York, NY|
|1229|,|Hobmayer, Bert|,|University of Innsbruck, Innsbruck, Austria|
|CB|,|Hodgkin, Jonathan|,|Oxford University, Oxford, England|
|PSY|,|Hodgkinson, Steve|,|University of Ulm, Germany|
| 646|,|Hoess, Sebastian|,|Zoologisches Inst der LMU Munchen, Muenchen, Germany|
| 838|,|Hoffman, David|,|NASA-Ames Research Center, Moffett Field, CA|
|1227|,|Hoffman, Peter|,|Notre Dame of Maryland University, Baltimore, MD|
|1174|,|Hoffman, Susan|,|Miami University, Oxford, OH|
| 680|,|Hoffmann-La Roche, Ltd.|,|Basel, Switzerland|
|3179|,|Hofmann, Randy|,|US Army, Aberdeen Proving Ground, MD|
| 435|,|Hofmann, Sandra|,|University of Texas Southwestern Medical Center, Dallas, TX|
|2218|,|Hofsteenge, Jan|,|Friedrich Miescher Institute, Basel, Switzerland|
|1652|,|Holbert, Sebastian|,|INRA, Nouzilly, France|
| 448|,|Holden-Dye, Lindy|,|University of Southampton, Southampton, UK|
|2127|,|Holdener, Bernadette|,|State University of New York, Stony Brook, NY|
|AMH|,|Holgado, Andrea|,|SWOSU, Weatherford, OK|
| 802|,|Hollar, David|,|Rockingham Community College, Wentworth, NC|
| 487|,|Holloway, Andrew|,|Peter MacCallum Cancer Institute, East Melbourne, Australia|
|3685|,|Hollywood, Mark|,|Dundalk Institute of Technology, Dundalk, Ireland|
|YD|,|Holmberg, Carina|,|University of Helsinki, Helsinki, Finland|
|4349|,|Holst, Charlie|,|Edison Pharmaceuticals Inc., Mountain View, CA|
|1434|,|Holt, Martha|,|Whitman College, Walla Walla, WA|
|1802|,|Holthaus, Kathryn|,|Boston College, Chestnut Hill, MA|
|2190|,|Holthuis, Joost|,|Utrecht University, Utrecht, The Netherlands|
|3135|,|Homma, Hiroshi|,|Kitasato University, Tokyo, Japan|
|BH|,|Honda, Barry|,|Simon Fraser University, Vancouver, BC|
|TM|,|Honda, Shuji|,|Tokyo Metropolitan Institute of Gerontology, Tokyo, Japan|
|2684|,|Hondo, Eiichi|,|Yamaguchi University, Yamaguchi, Japan|
|1478|,|Hong, Kyonsoo|,|NYU Medical Center, New York, NY|
|RLH|,|Hong, Ray|,|California State University, Northridge, CA|
|3797|,|Hong, Tung Chee|,|Next Gene Scientific Sdn Bhd, Puchong, Malaysia|
|1089|,|Hong, Young Seok|,|University of Notre Dame, Notre Dame, IN|
|3439|,|Honnen, Sebastian|,|Institute of Toxicology, Duesseldorf, Germany|
|STR|,|Hoogenraad, Casper|,|Utrecht University, Utrecht, The Netherlands|
|3754|,|Hoopengardner, Barry|,|Central Connecticut State University, New Britain, CT|
| 631|,|Hooper, N.M.|,|University of Leeds, Leeds, United Kingdom|
|UL|,|Hope, Ian|,|University of Leeds, Leeds, England|
|COP|,|Hopkins, Chris|,|Knudra Tech Transgenics, Salt Lake City, UT|
|PZ|,|Hoppe, Pamela|,|Western Michigan University, Kalamazoo, MI|
|PP|,|Hoppe, Thorsten|,|Inst for Genetics and CECAD, Univ of Cologne, Cologne, Germany|
|HP|,|Hopper, Neil|,|University of Southampton, Southampton, UK|
|3283|,|Hoppert, Michael|,|Georg-August-University, Goettingen, Germany|
|2715|,|Hori, Toshiyuki|,|Ritsumeikan University, Kusatsu, Japan|
| 960|,|Horikoshi, Masami|,|University of Tokyo, Tokyo, Japan|
| 660|,|Horvath|,|Immunology Center, Mt. Sinai Medical Center, New York, NY|
|MT|,|Horvitz, Bob|,|Massachusetts Institute of Technology, Cambridge, MA|
|1701|,|Horwich, Arthur|,|Yale University School of Medicine, New Haven, CT|
|1040|,|Hoshi, Hidenobu|,|Osaka Prefecture University, Osaka, Japan|
|2727|,|Hoskisson, Paul|,|University of Strathclyde, Glasgow, UK|
|TN|,|Hosono, Ryuji|,|Kanazawa University, Kanazawa, Ishikawa, Japan|
|3811|,|Hoss, Sebastian|,|ECOSSA, Starnberg, Germany|
|1358|,|Houston, Katrina|,|University of Strathclyde, Glasgow, Scotland|
|3564|,|Houtkooper, Riekelt|,|Academic Medical Center, Amsterdam, The Netherlands|
|3438|,|Howard, Christie|,|University of Nevada, Reno, NV|
| 279|,|Howard, Kathy|,|Hilton Head High School, Hilton Head Island, SC|
|1103|,|Howe, Mary|,|Bucknell University, Lewisburg, PA|
|LHU|,|Howell, James|,|Lock Haven University of Pennsylvania, Lock Haven, PA|
|3032|,|Hrabak, Estelle|,|University of New Hampshire, Durham, NH|
|2103|,|Hsaing-Yi, Sue|,|National Chiao Tung University, Hsinchu, Taiwan|
|4311|,|Hseuh, Yen-Ping|,|Academia Sinica, Taiwan|
|3918|,|Hsiao, Michael|,|Genomics Research Center, Academia Sinica, Taiwan|
|EQ|,|Hsu, Allen|,|University of Michigan, Ann Arbor, MI|
| 339|,|Hsu, Linda|,|Seton Hall University, South Orange, NJ|
|2298|,|Hsu, Pei Chi|,|Technical University Hamburg, Hamburg, Germany|
|TWN|,|Hsueh, Yi-Ping|,|Academia Sinica, Taipei, Taiwan|
|4254|,|Hu', Junjie|,|IBP-CAS Institute of Biophysic Chinese Academy of Sciences, Beijing, China|
|CDH|,|Hu, Chang-Deng|,|Purdue University, West Lafayette, IN|
|ZP|,|Hu, Jinghua|,|Mayo Clinic, Rochester, MN|
| 701|,|Hu, Keping|,|Peking University, Peking, China|
|2763|,|Hu, Mingying|,|South China Agricultural University, China|
|BQ|,|Hu, Patrick|,|University Michigan, Ann Arbor, MI|
|3775|,|Hu, Xu|,|DuPont Pioneer, Johnston, IA|
|4248|,|Hu, Zhitao|,|University of Queensland, St Lucia, QLD, Australia|
|3558|,|Huang, Bo|,|University of California, San Francisco, CA|
|2641|,|Huang, Jing|,|University of California, Los Angeles, CA|
|4073|,|Huang, Joseph Jen-Tse|,|Academia Sinica, Taiwan|
|2657|,|Huang, Jun-Yong|,|University of Newcastle, Newcastle Upon Tyne, UK|
|3346|,|Huang, Kun|,|Huazhong University of Science and Technology, Wuhan, China|
|2328|,|Huang, Lei|,|Dalian Maritime University, Dalian, China|
|HCC|,|Huang, Nancy|,|The Colorado College, Colorado Springs, CO|
|4078|,|Huang, Qichun|,|Guangxi Medical University, Nanning, Guangxi, China|
|3048|,|Huang, Shi|,|Central South University, Changsha, China|
|2233|,|Huang, Steve|,|National Chiao Tung University, Taiwan|
|1877|,|Huang, Taosheng|,|University of California, Irvine, CA|
|1884|,|Huang, Ting-Ting|,|Stanford University, Palo Alto, CA|
|XD|,|Huang, Xun and Ding, Mei|,|IGDB, Chinese Academy of Sciences, Beijing, China|
|3078|,|Huang, Yang|,|Lumigenex (Suzhou) Co Ltd, Jiangsu, China|
|2639|,|Huang, Zebo|,|Guangdong Pharmaceutical University, Guangzhou, China|
| 254|,|Huang, Zhen|,|Laboratory for Organic Chemistry, ETH, Zurich, Switzerland|
|GC|,|Hubbard, Jane|,|New York University, New York, NY|
|3713|,|Hubert, Amy|,|Southern Illinois University, Edwardsville, IL|
|ATL|,|Hudson, Martin|,|Kennesaw State University, Kennesaw, GA|
|4343|,|Huebert Lima, Dana|,|West Virginia University, Morgantown, WV|
|2610|,|Huggins, Luke|,|West Virginia Wesleyan College, Buckhannon, WV|
| 422|,|Hughes, Norman|,|Pepperdine University, Malibu, CA|
| 605|,|Hughes, Owen|,|MIT, Watertown, MA|
|4031|,|Hughes, William|,|University of Sussex, Brighton, UK|
|HAH|,|Hundley, Heather|,|Indiana University, Bloomington, IN|
| 497|,|Hung, Ming-Shiu|,|Academia Sinica, Taipei, Taiwan|
|1597|,|Hunt, John|,|Columbia University, New York, NY|
|2584|,|Hunter, Charles|,|Southwestern College, Winfield, KS|
|HC|,|Hunter, Craig|,|Harvard University, Cambridge, MA|
| 280|,|Hunter, Gary J.|,|University of Malta, Msida, Malta|
| 394|,|Huntley, Paula|,|Rockefeller University, NY, NY|
|4159|,|Huo, Yanwu|,|Chinese Academy of Sciences, Beijing, China|
|DDH|,|Hurd, Daryl|,|St. John Fisher College, Rochester, NY|
| 319|,|Hurley, Jim|,|Oklahoma Baptist University, Shawnee, OK|
| 987|,|Hurst, Mark|,|CEFAS, Burnham-on-Crouch, Essex, England|
|3027|,|Hurwitz, Michael|,|Yale University, New Haven, CT|
| 171|,|Hussey, Richard|,||
|BEL|,|Husson, Steven|,|University of Antwerp, Antwerp, Belgium|
|1333|,|Huston, Christopher|,|University of Vermont College of Medicine, Burlington, VT|
|1614|,|Hutson, Shane|,|Vanderbilt University, Nashville, TN|
|VH|,|Hutter, Harald|,|Simon Fraser University, Burnaby, BC, Canada|
|3476|,|Huwar, Theresa|,|Battelle, Columbus, OH|
|3267|,|Hwang, Eun Seong|,|University of Seoul, Seoul, Korea|
|2597|,|Hwang, Lucy Sun|,|National Taiwan University, Taipei, Taiwan|
|3342|,|Hyman, Bradley|,|University of California, Riverside, CA|
|TH|,|Hyman, Tony|,|MPI, Dresden, Germany|
|2748|,|INACTIVE|,||
|3139|,|Ibarra, Ana|,|Centro de Investigaciones Biológicas del Noroeste, La Paz, BCS, Mexico|
|2269|,|Ichijo, Hidenori|,|University of Tokyo, Tokyo, Japan|
|1258|,|Ichikawa, Shinichi|,|Niigata University of Pharmacy and Applied Life Sciences, Niigata, Japan|
|2898|,|Iglesias, Teresa|,|Inst Invest Biomed Alberto Sols (CSIC-UAM), Madrid, Spain|
|2896|,|Ignatova, Zoya|,|University of Potsdam, Potsdam-Golm, Germany|
|3565|,|Ii, Miki|,|University of Alaska, Anchorage, AK|
|JN|,|Iino, Yuichi|,|University of Tokyo, Tokyo, Japan|
|3087|,|Ilau, Birger|,|Tallinn University of Technology, Tallinn, Estonia|
|2389|,|Ilday, Fatih Omer|,|Bilkent University, Ankara, Turkey|
| 345|,|Ill, Moon Young|,|Seoul National University, Seoul, South Korea|
|4260|,|Imada, Chiaki|,|Tokyo University of Marine Sci & Tech, Tokyo, Japan|
|3385|,|Imamoto, Naoko|,|RIKEN BioResource Center, Saitama, Japan|
|3091|,|Imperiali, Barbara|,|MIT, Cambridge, MA|
|2652|,|Indracanti, PremKumar|,|Institute of Nuclear Medicine and Allied Sciences, Delhi, India|
|3959|,|Inoue, Hideki|,|Kanagawa Institute of Technology, Atsugi, Japan|
|1240|,|Inoue, Hideshi|,|Tokyo University of Pharmacy and Life Science, Tokyo, Japan|
|ZF|,|Inoue, Takao|,|National University of Singapore, Singapore|
|3354|,|Insulab International|,|Insulab International, Tucson, AZ|
|2415|,|Interprise USA Corp.|,|Doral, FL|
|1108|,|Intervet Innovation GmbH|,|Schwabenheim, Germany|
|3118|,|Ionita, Mihai|,||
|1839|,|Ippolito, Kimberly|,|Anderson University, Anderson, IN|
|JIN|,|Irazoqui, Javier|,|Massachusetts General Hospital, Boston, MA|
| 859|,|Irion, Van|,|Vacaville, CA|
|3259|,|Irwan Izzauddin Nik Him, Nik Ahmad|,|Universiti Sains Malaysia, Penang, Malaysia|
|1564|,|Isaac, Elwyn|,|University of Leeds, Leeds, UK|
| 953|,|Isermann, Kerstin|,|Bernhard Nocht Inst for Tropical Medicine, Hamburg, Germany|
|QD|,|Ishihara, Takeshi|,|Kyushu University, Fukuoka, Japan|
|TK|,|Ishii, Naoaki|,|Tokai University School of Medicine, Kanagawa, Japan|
|2757|,|Ishikawa, Takamasa|,|Human Metabolome Technologies Inc, Yamagata, Japan|
| 830|,|Ishiura|,|University of Tokyo, Tokyo, Japan|
|3662|,|Isla, Maria Ines|,|INQUINOA, Universidad Nacional de Tucuman, Tucuman, Argentina, San Lorenzo|
|1907|,|Ismagilov, Rustem|,|University of Chicago, Chicago, IL|
|3131|,|Ito, Masahiro|,|Ritsumeikan University, Kusatsu, Japan|
| 916|,|Ivacic, Lynn|,|Marshfield Medical Research Foundation, Marshfield, WI|
|3340|,|Ives, Ted|,|The Lawrenceville School, Lawrenceville, NJ|
|HIW|,|Iwasa, Hiroaki|,|Tokyo Medical and Dental University, Tokyo, Japan|
|KY|,|Iwasaki, Kouichi|,|Northwestern University, Chicago, IL|
|1117|,|Iwatsubo, Takeshi|,|University ofTokyo, Tokyo, Japan|
|2644|,|Izaguirre, Enrique|,|Washington University School of Medicine, St. Louis, MO|
|BIJ|,|Jaattela, Marja|,|Institute of Cancer Biology, Copenhagen, Denmark|
|3084|,|Jackson, Andrew|,|Wellcome Trust Sanger Institute, Cambridge, UK|
|3977|,|Jackson, Belinda|,|Uniformed Services University of the Health Sciences, Bethesda, MD|
|1451|,|Jackson, Carol|,|Kronos Longevity Research Institute, Phoenix, AZ|
|3245|,|Jacobs, Howard|,|University of Tampere, Tampere, Finland|
|PJ|,|Jacobson, Lew|,|University of Pittsburgh, PA|
|4156|,|Jacoby, Derek|,|Victoria Makerspace, Victoria, BC|
|2768|,|Jadubansa, Premroy|,|Natural History Museum, London, UK|
|1292|,|Jagadeeswaran, Pudur|,|University of Texas, San Antonio, TX|
|1242|,|Jagger, Kathleen|,|Transylvania University, Lexington, KY|
|4034|,|Jain, Mukesh|,|Case Western Reserve University, Cleveland, OH|
|1990|,|Jakob, U|,|University of Michigan, Ann Arbor, MI|
| 519|,|James, Eric|,|Medical University of South Carolina, Charleston, SC|
|1819|,|Jameson, Daniel|,|University of Manchester, Manchester, UK|
|2747|,|Jamison, Wendy|,|Chadron State College, Chadron, NE|
| 507|,|Jan, Lily|,|University of California, San Francisco, CA|
|3258|,|Jankiewicz, Urszula|,|Warsaw Uniwersity, Warsaw, Poland|
|GJ|,|Jansen, Gert|,|Erasmus University, Rotterdam, The Netherlands|
|1150|,|Jansen, Wouter|,|UMC, Utrecht, The Netherlands|
|2805|,|Jansen-Duerr, Pidder|,|Inst for Biomed Aging, Innsbruck, Austria|
| 224|,|Jansson, Hans-Borje|,|Lund University, Lund, Sweden|
|2089|,|Jansson, Hans-Borje|,|University of Alicante, Alicante, Spain|
|UV|,|Jantsch-Plunger, Verena|,|University of Vienna, Vienna, Austria|
|JJA|,|Jantti, Jussi|,|University of Helsinki, Helsinki, Finland|
|FJJ|,|Janzen, Fred|,|Iowa State University, Ames, IA|
|2819|,|Jaramillo, Alfonso|,|Genopole, CNRS, France|
|IS|,|Jarriault, Sophie|,|IGBMC, Strasbourg, France|
|2821|,|Jarvis, Erich|,|Duke University, Durham, NC|
| 788|,|Jasmer, Douglas|,|Washington State University, Pullman, WA|
|3981|,|Jayaraman, Arul|,|Texas A&M University, College Station, TX|
|2431|,|Jean-Pierre Mothet|,|Centre de Recherche, Bordeaux cedex, France|
| 791|,|Jeddeloh, Jeffrey|,|USAMRIID, Fort Detrick, MD|
|MAJ|,|Jedrusik-Bode, Monica|,|MPI, Goettingen, Germany|
|1248|,|Jeff Johnson|,|University of Wisconsin-Madison, Madison, WI|
|1486|,|Jeffery Stock|,|Princeton University, Princeton NJ|
| 760|,|Jeffrey, Keith|,|Sparsholt College, Hampshire, England|
|2258|,|Jehle, Robert|,|Bielefeld University, Bielefeld, Germany|
|3774|,|Jenkins, Sultan Ali|,|LaGuardia Community College, Long Island City, NY|
|UQM|,|Jenna, Sarah|,|University of Quebec in Montreal, Quebec, Canada|
|1443|,|Jensen, Laran|,|Johns Hopkins University, Baltimore, MD|
|3483|,|Jensen, Laran|,|Mahidol University, Bangkok, Thailand|
|2586|,|Jeyabalan, Santha|,|University of Michigan, Ann Arbor, MI|
|2471|,|Jez, Joseph|,|Donald Danforth Plant Science Center, St. Louis, MO|
|2781|,|Jezuit, Erin|,|Knox College, Galesburg, IL|
|2409|,|Ji, Chenbo|,|Nanjing Medical University, Nanjing, China|
|1615|,|Ji, Qiongmei|,|New York Blood Center, New York, NY|
|KLJ|,|Jia, Kailiang|,|Florida Atlantic University, Boca Raton, FL|
|1480|,|Jia, William|,|University of British Columbia, Vancouver, BC, Canada|
|2121|,|Jiang, Haobo|,|Oklahoma State University, Stillwater, OK|
|4298|,|Jiang, Hui Gong|,|University of Guam, Mangilao, Guam|
|3207|,|Jiangheng Ma, Michael|,|Pharmaron (Beijing)Co., Ltd, Beijing, China|
|3127|,|Jimenez, Jesus|,|Ingredients Biotech, Granada. Spain|
|1768|,|Jimenez, Martha|,|Universidad Nacional de Colombia, Sur America|
|2956|,|Jin, Tae-Won|,|Yonsei University, Seoul, South Korea|
|3855|,|Jin, Yan|,|4th Military Medical University, Xi'an, China|
|4257|,|Jin, Yang|,|Boston Universty School of Medicine, Boston, MA|
|4112|,|Jin, Yishi|,|University of California, San Diego, CA|
| 248|,|Jing, George|,|Pennsylvania State University, University Park, PA|
|4043|,|Jing, Pu|,|Shanghai Jiao Tong University, Shanghai, China|
|3445|,|Jinwal, Umesh|,|University of South Florida, Tampa, FL|
|3698|,|Jnda, Kim|,|Scripps Research Institute, La Jolla, CA|
|1854|,|Jochum, Christy|,|University of Nebraska, Lincoln, NE|
|3953|,|Johannes, Ludger|,|Curie Institute, Paris, France|
|3287|,|Johnsen, Steven|,|Georg-August-Universitat, Gottingen, Germany|
|CD|,|Johnson, Carl|,|Hereditary Disease Foundation, New York, NY|
|CMJ|,|Johnson, Casonya|,|Georgia State University, Atlanta, GA|
|1101|,|Johnson, Eric|,|University of Wisconsin, Madison, WI|
|4148|,|Johnson, Eric|,|USDA ARS, Peoria, IL|
|3776|,|Johnson, Keith|,|Bradley University, Peoria, IL|
|3799|,|Johnson, Matthew|,|Notre Dame College, South Euclid, OH|
|BYU|,|Johnson, Steven|,|Brigham Young University, Provo, UT|
| 371|,|Johnson, Terrence|,|Tennessee State University, Nashville, TN|
|TJ|,|Johnson, Tom|,|University of Colorado, Boulder, CO|
|3756|,|Johnston, Kimberly|,|Delaware Valley College, Doylestown, PA|
|1102|,|Johnston, Spencer|,|Texas A & M University, College Station, TX|
| 446|,|Johnstone, Brian|,|UCLA, Los Angeles, CA|
|IA|,|Johnstone, Iain|,|University of Glasgow, Scotland|
|3820|,|Jois, Markandeya|,|La Trobe University, Bundoora, VIC, Australia|
|1028|,|Jones, Audra|,|Staffordshire University, Stoke-on-Trent, U.K.|
|3854|,|Jones, Georgette|,|Hood College, Frederick, MD|
| 729|,|Jones, John|,|Nematology Department, SCRI, Dundee, Scotland|
| 976|,|Jones, Keith|,|University of Newcastle-upon-Tyne, Newcastle, U.K.|
|3827|,|Jones, Keith|,|University of Southampton, Southampton, UK|
|3588|,|Jones, Lynwen|,|Aberystwyth University, Aberystwyth, UK|
|2399|,|Jones, Peter|,|University of Illinois, Urbana-Champaign, IL|
|IF|,|Jongeward, Gregg|,|University of the Pacific, Stockton, CA|
|1612|,|Jonsson, Franziska|,|University of Witten/Herdecke, Witten, Germany|
|EG|,|Jorgensen, Erik|,|University of Utah, Salt Lake City|
|AMJ|,|Jose, Anthony|,|University of Maryland, College Park, MD|
|1534|,|Joseph, Sam|,|University of Maryland, College Park, MD|
|GWJ|,|Joshua, George|,|London School of Hygiene & Tropical Medicine, London, England|
|2066|,|Jospin, Maelle|,|UMR CNRS, Villeurbanne, France|
|2126|,|Jospin, Maelle|,|University of Lyon, Lyon, France|
|4065|,|Joubert, James|,|Photometrics and QImaging, Tucson, AZ|
|2446|,|Jousson, Olivier|,|University of Trento, Trento, Italy|
| 401|,|Joyce, Will|,|St. Lawrence University, Canton, NY|
|2940|,|Joyner-Matos, Joanna|,|Eastern Washington University, Cheney, WA|
|BTJ|,|Juang, Bi-Tzen|,|National Chiao Tung University, Hsinchu, Taiwan|
|2792|,|Jucker, Mathias|,|University of Tübingen. Tubingen, Germany|
| 773|,|Julian, David|,|University of Florida, Gainesville, FL|
|2875|,|Jumas, Estelle|,|University of Montpellier, Montpellier, France|
|FJ|,|Juo, Peter|,|Tufts University, Boston, MA|
|PJP|,|Jurado, Paola|,|University Hospital, ICO - IDIBELL, Barcelona, Spain|
|2152|,|Juszczak, Laura|,|Brooklyn College, City University of New York, Brooklyn, NY|
|4315|,|Jydstrup-McKinney, Andrea|,|West Career and Technical Academy, Las Vegas, NV|
|KAE|,|Kaeberlein, Matt|,|University of Washington, Seattle, WA|
|2858|,|Kaehr, Bryan|,|Sandia National Labs, Albuquerque, NM|
|HK|,|Kagawa, Hiroaki|,|Okayama University, Okayama, Japan|
|EKN|,|Kage-Nakadai, Eriko|,|Osaka City University, Osaka, Japan|
|2815|,|Kahn, C Ronald|,|Joslin Diabetes Center, Boston, MA|
|2627|,|Kai, Hirofumi|,|Kumamoto University, Kumamoto, Japan|
|NR|,|Kaibuchi, Kozo|,|NAIST, Nara, Japan|
|1836|,|Kaidi, Abderrahmane|,|University of Bristol, Bristol, England|
|2968|,|Kaiser, Chris|,|Massachusetts Institute of Technology, Cambridge, MA|
|3846|,|Kakouli-Duarte, Thomae|,|Institute of Technology Carlow, Carlow, Ireland|
|HQ|,|Kalb, John|,|Canisius College, Buffalo, NY|
|2531|,|Kalb, Robert|,|University of Pennsylvania, Philadelphia, PA|
|3995|,|Kalia, Lorraine|,|Toronto Western Hospital, Toronto, ON, Canada|
|1997|,|Kalinnikova, Tatyana|,|Russian Foundation for Basic Research, Kazan, Russia|
|2480|,|Kalman, Daniel|,|Emory University, Atlanta, GA|
|2966|,|Kaltreider, Ronald|,|York College, York, PA|
|2567|,|Kalueff, Allan|,|Tulane University Medical School, New Orleans, LA|
|WN|,|Kammenga, Jan|,|Wageningen Agricultural Univ, Wageningen, The Netherlands|
|2219|,|Kampkotter, Andreas|,|Heinrich-Heine University, Dusseldorf, Germany|
|1038|,|Kanai, Akio|,|Keio University, Yamagata, Japan|
|2189|,|Kanai, Yoshikatsu|,|Osaka University, Osaka, Japan|
|2164|,|Kanaki, Niranjan|,|B.V. Patel Pharmaceutical Education and Research Dev.(PERD), Gujarat, India|
|2552|,|Kanaki, Niranjan|,|K.B. Inst. of Pharmaceutical Edu. and Res., Gandhinagar, Gujarat, India|
|EK|,|Kandel, Eric|,|Columbia University, New York, NY|
|4252|,|Kang, David|,|University of South Florida, Tampa, FL|
|3549|,|Kang, Jing X|,|Massachusetts General Hospital, Boston, MA|
|4195|,|Kang, Kyungsu|,|Korea Institute of Science and Technology, Gangneung, South Korea|
|3249|,|Kang, Lijun|,|Zhejiang University, Hangzhou, China|
|3750|,|Kang, Yun Kyoung|,|Baylor College of Medicine, Houston, TX|
|2749|,|Kanki, Tomotake|,|Kyushu Univ Grad School of Med Sci, Fukuoka, Japan|
| 309|,|Kanost, Michael|,|Kansas State University, Manhattan, KS|
|2286|,|Kanuka, Hirotaka|,|Obihiro University, Obihiro, Hokkaido, Japan|
|NKZ|,|Kanzaki, Natsumi|,|Forestry and Forest Products Research Inst, Tsukuba, Japan|
|AWK|,|Kao, Aimee|,|University of California, San Francisco, CA|
|GOT|,|Kao, Gautam|,|University of Gothenburg, Goteborg, Sweden|
|PKL|,|Kapahi, Pankaj|,|Buck Institute, Novato, CA|
|KP|,|Kaplan, Josh|,|Massachusetts General Hospital, Boston, MA|
|4030|,|Kaplan, Oktay|,|Uskudar University, Istanbul, Turkey|
|4275|,|Kaplan, Sandra|,|Central Lakes College, Brainerd, MN|
|1565|,|Kappock, T|,|Washington University, St. Louis, MO|
|RZ|,|Kaprielian, Zaven|,|Albert Einstein College of Medicine, Bronx, NY|
|POL|,|Kapulkin, Wadim|,|MPI MCBG, Dresden, Germany|
|1344|,|Karabinos, Anton|,|MPI for Biophysics, Goettingen, Germany|
|3000|,|Karakuzu, Ozgur|,|Texas Inst of Biotech Education & Research, Houston, TX|
|KF|,|Kariya, Ken-ichi|,|University of the Ryukyus, Okinawa, Japan|
|2769|,|Karlseder, Jan|,|The Salk Institute, La Jolla, CA|
|XV|,|Karp, Xantha|,|Central Michigan University, Mount Pleasant, MI|
|JEK|,|Karpel, Jonathan|,|Southern Utah University, Cedar City, UT|
|1876|,|Karsten, Stanislav|,|University of California, Los Angeles, CA|
| 436|,|Kasai, Dr.|,|Teikyo University, Kanagawa, Japan|
|3868|,|Kasashima, Katsumi|,|Jichi Medical University, Shimotsuke, Japan|
|2746|,|Kass, Len|,|University of Maine, Orono, ME|
|1939|,|Katada, Toshiaki|,|University of Tokyo, Tokyo, Japan|
|2977|,|Katinakis, Panagiotis|,|Agricultural University of Athens, Athens, Greece|
|2416|,|Katju, Vaishali|,|University of New Mexico, Albuquerque, NM|
|4063|,|Katner, Simon|,|Indiana University School of Medicine, Indianapolis, IN|
| 821|,|Kato, Junichi|,|Hiroshima University, Hiroshima, Japan|
|MKC|,|Kato, Masaomi|,|Centenary Inst of Cancer Medicine & Cell Bio, Camperdown, NSW, Australia|
| 613|,|Kato, Yusuke|,|National Inst of Sericulture and Entomological Science, Tsukuba, Japan|
|JC|,|Katsura, Isao|,|National Institute of Genetics, Mishima, Japan|
|2953|,|Katz, David|,|Emory University, Atlanta, GA|
|WK|,|Katz, Wendy|,|University of Kentucky Medical Center, Lexington, KY|
| 837|,|Kauffman, Linda|,|Carnegie Mellon University, Pittsburgh, PA|
|1073|,|Kaufman, Nicole|,|Dana College, Blair, NE|
|1482|,|Kaufman, Randal|,|University of Michigan, Ann Arbor, MI|
|3960|,|Kautu, Bwarenaba|,|Greenville College, Greenville, IL|
|4352|,|Kawano, Moe|,|Kokusai Kinzoku Yakuhin Co Ltd, Tokyo, Japan|
| 288|,|Kawano, Tsuyoshi|,|Tottori University, Tittori City, Japan|
|1119|,|Kawata, Dr.|,|Tohoku University, Sendai, Japan|
|3692|,|Kawate, Toshi|,|Cornell University, Ithaca, NY|
|1643|,|Kearns, Katherine|,|Boston University, Boston, MA|
|2865|,|Keays, David|,|Institute of Moelcular Pathology, Vienna, Austria|
|1185|,|Kedes, Larry|,|University of Southern California, Los Angeles, CA|
|3687|,|Kee, Younghoon|,|University of South Florida, Tampa, Florida|
|KL*|,|Keightley, Peter|,|University of Edinburgh, Edinburgh, Scotland|
|KX|,|Keiper, Brett|,|East Carolina University, Greenville, NC|
|3814|,|Keller, Charles|,|LaGuardia Community College, Long Island City, NY|
|2115|,|Keller, Laurent|,|University of Lausanne, Lausanne, Switzerland|
|1449|,|Kelley, Carolyn|,|Seacoast School of Technology, Exeter, NH|
|3162|,|Kellum, Rebecca|,|University of Kentucky, Lexington, KY|
| 874|,|Kelly, Greg|,|University of Western Ontario, London, Ontario, Canada|
|2872|,|Kelly, Jeffrey|,|Scripps Research Inst, La Jolla, CA|
|KW|,|Kelly, William|,|Emory University, Atlanta, GA|
|KK|,|Kemphues, Ken|,|Cornell University, Ithaca, NY|
|3893|,|Kendall, Ron|,|Texas Tech University, Lubbock, TX|
|1832|,|Kennedy, Brian|,|Buck Insittute, Novato, CA|
|YY|,|Kennedy, Scott|,|Harvard Medical School, Boston, MA|
|2334|,|Kennett, Roger|,|Wheaton College, Wheaton, IL|
|CF|,|Kenyon, Cynthia|,|Calico Life Sciences, South San Francisco, CA|
|2175|,|Kenyon, William|,|University of West Georgia, Carrollton, GA|
|3566|,|Keowkase, Roongpetch|,|Srinakharinwirot University, Nakornayok, Thailand|
|3339|,|Kern, Tanja|,|Technical University of Munich, Germany|
|XJ|,|Kerr, Rex|,|HHMI-Janelia Farm Research Campus, Ashburn, VA|
| 566|,|Kerr, Sylvia|,|Hamline University, St. Paul, MN|
| 737|,|Kerrigan, Julia|,|Washington State University, Pullman, WA|
|1917|,|Kerry, Samantha|,|St. Mary's College, St. Mary's City, MD|
|AEK|,|Kerscher, Aurora|,|Eastern Virginia Medical School, Norfolk, VA|
| 593|,|Kerschmann, Russell|,|California Pacific Medical Center, Sacramento, CA|
|PJK|,|Kersey, Paul|,|EMBL-European Bioinformatics Institute, Cambridge, UK|
|RFK|,|Ketting, Rene|,|Institute of Molecular Biology, Mainz, Germany|
|2499|,|Khaled, Aan|,|Dubai Pharmacy College, Dubai|
|4326|,|Khalimonchuk, Oleh|,|University of Nebraska, Lincoln, NE|
|3980|,|Khayhan, Kantarawee|,|University of Phayao, Muang, Phayao, Thailand|
| 986|,|Khoo, Hong Woo|,|National University of Singapore, Singapore|
|1432|,|Kieke, Michele|,|Concordia University, St. Paul, MN|
| 663|,|Kieras, Fred|,|Institute for Basic Research, Staton Island, NY|
| 740|,|Kiessling, Laura|,|University of Wisconsin, Madison, WI|
|EAK|,|Kikis, Elise|,|University of the South, Sewanee, TN|
|3534|,|Kikkawa, Masahide|,|University of Tokyo, Tokyo, Japan|
|TSK|,|Kikuchi, Taisei|,|Forestery & Forest Products Research Inst, Tsukuba, Ibaraki, Japan|
|3658|,|Kikuchi, Taisei|,|University of Miyazaki, Miyazaki, Japan|
|4110|,|Kikuchi, Yoshitomo|,|Natl Inst of Advanced Industrial Science & Technology, Sapporo, Japan|
|2179|,|Kiley, Maureen|,|Navel Medical Research Center, Rockville, MD|
|YZ|,|Killeen, Marie|,|Ryerson University, Toronto, ON, Canada|
|DJK|,|Killian, Darrell|,|Colorado College, Colorado Springs, CO|
|1655|,|Kilvington, Simon|,|University of Leicester, Leicester, UK|
|3374|,|Kim, Byung-Eun|,|University of Maryland, College Park, MD|
|ZD|,|Kim, Dennis|,|MIT, Cambridge, MA|
|SBL|,|Kim, Do Han|,|Gwangju Inst of Sci & Tech|
|JFM|,|Kim, Doug|,|HHMI-Janelia Farm Research Campus, Ashburn, VA|
| 936|,|Kim, Eun Jin|,|GBF, Braunschweig, Germany|
|HKK|,|Kim, Hongkyun|,|Rosalind Franklin University, North Chicago, IL|
|3570|,|Kim, Jae-Ho|,|Rogers State University, Claremore, OK|
|2425|,|Kim, Jae-Ryong|,|Yeungnam University, South Korea|
|3943|,|Kim, Jeffrey|,|ADA Dr. Anthony Volpe Research Center, Gaithersburg, MD|
|1914|,|Kim, Jeongho|,|Inha University, Incheon, Korea|
|QK|,|Kim, John|,|Johns Hopkins University, Baltimore, MD|
|2083|,|Kim, Juewon|,|University of Tokyo, Chiba, Japan|
|1926|,|Kim, Ki Hong|,|Pukyong National University, Pusan, South Korea|
|KHK|,|Kim, Kyuhyung|,|DGIST, Daegu, South Korea|
|3074|,|Kim, Min Young|,|Gyeongsang National University School of Medicine, Jinju, South Korea|
|3833|,|Kim, Sang-Tae|,|Seoul National University, Seoul, South Korea|
|SD|,|Kim, Stuart|,|Stanford University Medical School, Stanford, CA|
|SKP|,|Kim, Sunhong|,|Korea Research Inst Biosci & Biotech, Daejeon, South Korea|
|3691|,|Kim, Sunmin|,|Inha University, Incheon, South Korea|
|3097|,|Kim, Young-Il|,|Korea Research Insti Biosci & Biotech, Daejeon, South Korea|
|3274|,|Kim, Younghoon|,|Kosin University College of Medicine, Seo-Gu, South Korea|
|JK|,|Kimble, Judith|,|University of Wisconsin, Madison|
|3152|,|Kimmel, Bruce|,|HHMI-Janelia Farm Research Campus, Ashburn, VA|
|CAL|,|Kimura, Akatsuki|,|National Institute of Genetics, Mishima, Shizuoka, Japan|
|KDK|,|Kimura, Kotaro|,|Osaka University, Osaka, Japan|
|YT|,|Kimura, Yoshishige|,|Mitsubishi Kagaku Institute of Life, Tokyo, Japan|
|3318|,|King, Kayla|,|University of Liverpool, Liverpool, England|
| 539|,|Kingsley, David|,|Stanford University, Stanford, CA|
|2205|,|Kinnunen, Tarja|,|University of Liverpool, Liverpool, England, UK|
|3520|,|Kinross, John|,|School of Life Sciences, Edinburgh, UK|
|2718|,|Kinsley, Craig|,|University of Richmond, Richmond, VA|
|1421|,|Kiontke, Karin|,|New York University, New York, NY|
|1646|,|Kipp, Brian|,|Grand Valley State University, Allendale, MI|
|1168|,|Kippert, Fred|,|University of Leicester, Leicester, U.K.|
|ET|,|Kipreos, Edward|,|University of Georgia, Athens, GA|
|1520|,|Kirchner, Jay|,|Cumberland College, Williamsburg, KY|
|1704|,|Kiriyama, Yoshimitsu|,|Tokushima Bunri University, Kagawa, Japan|
|1074|,|Kirk, Kevin|,|New Mexico Tech, Socorro, NM|
|2954|,|Kirkpatrick, Bridgette|,|Collin College, Plano, TX|
|1221|,|Kirkpatrick, Catherine|,|University of Minnesota, Minneapolis, MN|
|1681|,|Kirschner,|,|Harvard Medical School, Boston, MA|
|2096|,|Kirshenbaum, Kent|,|New York University, New York, NY|
|JKM|,|Kirstein-Miles, Janine|,|Leibniz Institute for Molecular Pharmacology, Berlin, Germany|
|3885|,|Kisan, Jadhav|,|University of Agricultural Sciences, Raichur, India|
|2406|,|Kita, Kiyoshi|,|University of Tokyo, Tokyo, Japan|
|DKT|,|Kitagawa, Daiju|,|National Institute of Genetics, Mishima, Japan|
|RQ|,|Kitagawa, Risa|,|Nationwide Children's Hospital, Columbus, OH|
| 330|,|Kitayama, Hitoshi|,|Kyoto University, Kyoto, Japan|
|3306|,|Kjelleberg, Staffan|,|University of New South Wales, Sydney, Australia|
|2969|,|Kjellerup, Birthe Veno|,|University of Maryland at College Park, College Park, MD|
|4354|,|Klaper, Rebecca|,|University of Wisconsin, Milwaukee, WI|
|1259|,|Klappa, Peter|,|University of Kent, Canterbury, UK|
|2474|,|Klapper, Maja|,|University of Kiel, Kiel, Germany|
|MK|,|Klass, Michael|,|Abbott Labs, Abbott Park, IL|
|1780|,|Klausmeyer, Heather|,|Mills College, Oakland, CA|
|4013|,|Kleckner, Nancy|,|Harvard University, Cambridge, MA|
|3952|,|Kleinschmit, Adam|,|Adams State University, Alamosa, CO|
| 994|,|Klenz, Jennifer|,|University of British Columbia, Vancouver, BC, Canada|
|3444|,|Kloog, Yoel|,|Tel-Aviv University, Tel-Aviv, Israel|
|DRK|,|Klopfenstein, Dieter|,|University of Gottingen, Gottingen, Germany|
|3881|,|Klotz, Lars-Oliver|,|Institute of Nutrition, Jena, Germany|
|2248|,|Kmiec, Eric|,|Marshall University, Huntington, WV|
|1535|,|Knight, Scott|,|University of Richmond, Richmond, VA|
|1226|,|Koehler|,|University of California, Los Angeles, CA|
|LX|,|Koelle, Michael|,|Yale University, New Haven, CT|
|2391|,|Koenig, Juergen|,|University of Vienna, Vienna, Austria|
|1254|,|Koenig, Renate|,|Biologische Bundesanstalt fur Land & Forstwirtschaft, Braunschweig, Germany|
| 908|,|Koepnick, Kevin|,|City High School, Iowa City, IA|
| 969|,|Koethe, Manuela|,|Technical University of Munich, Freising, Germany|
|YK|,|Kohara, Yuji|,|National Institute of Genetics, Mishima, Japan|
|3465|,|Kohlwein, Sepp|,|University of Graz, Graz, Austria|
|RK|,|Kohn, Rebecca|,|Ursinus College, Collegeville, PA|
|2633|,|Koivisto, Pertti|,|Evira, Helsinki, Finland|
|2866|,|Koji, Kakutani|,|Kinki University, Higashi-Osaka, Japan|
|2661|,|Kojima, Takuya|,|University of Tokyo, Tokyo, Japan|
|3874|,|Kolbe, Susan|,|Grinnell College, Grinnell, IA|
|1873|,|Kolesar, Janet|,|Ursuline College, Cleveland, OH|
|XR|,|Kolesnick, Richard|,|Memorial Sloan-Kettering Cancer Center, New York, NY|
|1110|,|Kolor, Katie|,|DePaul University, Chicago, IL|
|RWK|,|Komuniecki, Richard|,|University of Toledo, Toledo, OH|
|KZ|,|Kondo, Kazunori|,|Soka University, Tokyo, Japan|
|2878|,|Kong, Richard|,|City University of Hong Kong, Hong Kong|
|1529|,|Kongsuwan, Kritaya|,|University of Queensland, St. Lucia, Australia|
|YB|,|Kontani, Kenji|,|University of Tokyo, Toyko, Japan|
|3201|,|Kontoyiannis, Dimitros|,|MD Anderson Cancer Center - Univ of Texas, Houston, TX|
|1550|,|Konu, Ozlen|,|Bilkent University, Ankara, Turkey|
|3761|,|Konu, Ozlen|,|Bilkent University, Ankara, Turkey|
|NB|,|Koo, Hyeon-Sook|,|Yonsei University, Seoul, Korea|
|2723|,|Kopeny, Mark|,|University of Virginia, Charlottesville, VA|
|1352|,|Kopin, Alan|,|Tufts University, Boston, MA|
|1727|,|Kopp, Olga|,|Utah Valley State College, Orem, UT|
|2009|,|Koppert BV|,|The Netherlands|
|2793|,|Kores, Paul|,|Moorpark College, Moorpark, CA|
|JDK|,|Kormish, Jay|,|University of Manitoba, Winnipeg, Canada|
|WU|,|Kornfeld, Kerry|,|Washington University School of Medicine, St. Louis, MO|
|3490|,|Korstanje, Ron|,|Jackson Laboratory, Bar Harbor, ME|
|KN|,|Korswagen, Rik|,|Hubrecht Laboratory, Utrecht, The Netherlands|
|4141|,|Korte, Cassandra|,|Lynn University, Boca Raton, FL|
|2660|,|Kosak, Steve|,|Northwestern University, Chicago, IL|
|2470|,|Kosiyachinda, Pahol|,|Mahidol University, Nakorn Pathom, Bangkok, Thailand|
|KV|,|Kostrouchova, Marta|,|Charles University, Prague, Czech Republic|
|1840|,|Kot, Mary|,|Mercer University, Macon, GA|
|4332|,|Kotak, Sachin|,|Indian Institute of Science, Bangalore, India|
|1255|,|Koulen, Peter|,|University of North Texas Health Science Center, Fort Worth, TX|
|TT|,|Koushika, Sandhya and Babu, P|,|Tata Institute of Fundamental Research, Mumbai, India|
|1625|,|Koutsoudis, Maria|,|University of Connecticut, Storrs, CT|
| 963|,|Kovacs, Attila|,|ELTE University, Budapest, Hungary|
|3733|,|Kowalczyk, Pawel|,|Warsaw University of Life Sciences, Warsaw, Poland|
|JRK|,|Kowalski, Jennifer|,|Butler University, Indianapolis, IN|
|3878|,|Kowaltowski, Alicia Juliana|,|Universidade de Sao Paulo, Sao Paulo, Brazil|
|1960|,|Kozasa,|,|University of Illinois, Chicago, IL|
|3473|,|Kozich|,|Charles University, Prague, Czechoslovakia|
|1872|,|Kqueen, Cheah Yoke|,|Universiti Putra Malaysia, Selangor, Malaysia|
|CK|,|Kraemer, Brian|,|University of Washington, Seattle, WA|
| 373|,|Kraev, Alexander|,|Swiss Federal Institute of Technology, Zurich, Switzerland|
|1735|,|Krager, Kai Shyang|,|University of New South Wales, Sydney, Australia|
|PKR|,|Krajacic, Predrag|,|West Virginia School of Osteopathic Medicine, Lewisburg, WV|
|3454|,|Kramer Scientific LLC|,|Kramer Scientific LLC, Amesbury, MA|
|CH|,|Kramer, Jim|,|Northwestern University Medical School, Chicago, IL|
| 472|,|Krause, Kim|,|Purdue University, West Lafayette, IN|
|KM|,|Krause, Mike|,|NIH-Laboratory of Molecular Biology, Bethesda, MD|
|1346|,|Krek, Wilhelm|,|ETH Hoenggerberg, Zurich, Switzerland|
|3223|,|Krenn, Liselotte|,|University of Vienna, Vienna, Austria|
|3723|,|Krieser, Colleen|,|Pine Manor College, Chestnut Hill, MA|
|3538|,|Krieser, Ronald|,|Fitchburg State University, Fitchburg, MA|
|4125|,|Krishna, Vijay|,|Cleveland Clinic, Cleveland, OH|
|4137|,|Krishnan, Yamuna|,|University of Chicago, Chicago, Illinois|
|1034|,|Kristensen, Mette|,|University of Copenhagen, Denmark|
|XK|,|Kroft, Tim|,|Auburn University of Montgomery, Montgomery, AL|
|3219|,|Krolikowski, Katherine|,|Contra Costa College, San Pablo, CA|
|QX|,|Kruglyak, Leonid|,|University of California, Los Angeles, CA|
|2249|,|Krukonis, Eric|,|University of Michigan School of Dentistry, Ann Arbor, MI|
| 912|,|Krupanidhi, S|,|Sri Sathya Sai Institute of Higher Learning, Prasanthinilayam, India|
|3745|,|Kruppa, Michael|,|East Tennessee State University, Johnson City, TN|
|2970|,|Kubis, Karolina|,|Medical University of Lodz, Lodz, Poland|
|YF|,|Kubiseski, Terry|,|York University, Toronto, Ontario, Canada|
|1247|,|Kubo, Takeo|,|University of Tokyo, Tokyo, Japan|
|1670|,|Kudla, Urszula|,|Univeristy College Cork, Cork, Ireland, UK|
|3694|,|Kuemmerli, Rolf|,|University of Zurich, Zurich, Switzerland|
|3652|,|Kuhar, Daniel|,|USDA, ARS, Beltsville, MD|
|KHR|,|Kuhara, Atsushi|,|Konan University, Kobe, Japan|
|2210|,|Kuhn, Jeffrey|,|Virginia Tech, Blacksburg, VA|
|4098|,|Kujawa, Martyna|,|Institute of Biochemistry and Biophysics, Warsaw, Poland|
|2998|,|Kukreja, Rakesh|,|Virginia Commonwealth University, Richmond, VA|
|1148|,|Kumagai, Monto|,|University of Hawaii at Manoa, Honolulu, HI|
|2348|,|Kumar, Jainendra|,|College of Commerce, Patna, India|
|3104|,|Kumar, K. Sudesh|,|University Sciences Malaysia, Malaysia|
|1575|,|Kumm, Sandra|,|Martin-Luther-University Halle-Wittenberg, Halle/Saale, Germany|
|4301|,|Kung, Stephanie|,|Amyris Inc., Emeryville, CA|
|2155|,|Kuro-o, Makoto|,|University of Texas Southwestern, Dallas, TX|
| 758|,|Kuroda, Hideyo|,|Toyama University, Toyama, Japan|
|KH|,|Kuroyanagi, Hidehito|,|Tokyo Medical and Dental University, Tokyo, Japan|
| 473|,|Kurtz, Richard|,|Huntington High School, Huntington, NY|
| 796|,|Kurzchalia, Teymuras|,|MPI for Molecular Cell Biology and Genetics, Dresden, Germany|
|1085|,|Kusano, Kohji|,|Kyushu Institute of Technology, Kitakyushu, Japan|
|PK|,|Kuwabara, Patricia|,|University of Bristol, Bristol, England|
|1269|,|Kuzmin, Eugene|,|University of Missouri, Columbia, MO|
|3571|,|Kwon, Eunsoo|,|Korea Research Inst of Bioscience & Biotech, Daejeon, South Korea|
|2079|,|Kwon, Ho Jeong|,|Yonsei University, Seoul, South Korea|
|1901|,|Kyorin Pharmaceutical Co.|,|Tochigi, Japan|
|JZ|,|L'Etoile, Noelle|,|University of California, San Franciso, CA|
|SL|,|L'Hernault, Steve|,|Emory University, Atlanta, GA|
| 770|,|La Volpe, Adrianna|,|Int'l Inst of Genetics & Biophysics-CNR, Naples, Italy|
|ZQ|,|LaMunyon, Craig|,|California State Polytechnic University, Pomona, CA|
| 805|,|LaPenotiere, Hugh|,|USACEHR, Fort Detrick, MD|
|2119|,|Laakso, Jouni|,|University of Helsinki, Helsinki, Finland|
|UM|,|Labbe, Jean-Claude|,|University of Montreal, Montreal, Canada|
|ML|,|Labouesse, Michel|,|IGBMC, Strasbourg, France|
|3365|,|Laco, Gary|,|Roskamp Institute, Sarasota, FL|
|2736|,|Lacroix, Christophe|,|Institute of Food Science and Nutrition, Zurich, Switzerland|
|3094|,|Ladomery, Michael|,|University of the West of England, Bristol, UK|
|LA|,|Lakowski, Bernard|,|Manhattanville College, Purchase, NY|
|3046|,|Lambert, Kris|,|University of Illinois, Urbana, IL|
|EJ|,|Lambie, Eric|,|Dartmouth College, Hanover, NH|
|OG|,|Lamitina, Todd|,|Children's Hospital of Pittsburgh of UPMC, Pittsburgh, PA|
|ALM|,|Lamm, Ayelet|,|Technion-IIT, Haifa, Israel|
|3625|,|Lan, Ruiting|,|University of New South Wales, Sydney, Australia|
|JBL|,|Lanctot, Christian|,|Charles University in Prague, Czech Republic|
|3430|,|Landerholm, Thomas|,|California State University, Sacramento, CA|
|1353|,|Landweber, Laura|,|Princeton University, Princeton, NJ|
|1310|,|Lane, Daniel|,|Johns Hopkins University School of Medicine, Baltimore, MD|
|1904|,|Lange, Sascha|,|Universitaetsklinikum Hamburg-Eppendorf, Hamburg, Germany|
|3596|,|Langewald, Juergen|,|BASF-Chemical Company, Limburgerhof, Germany|
| 265|,|Langford, Phil|,|MBCI, Winnipeg, Manitoba, Canada|
| 825|,|Lanier, Stephen|,|Medical University of South Carolina, Charleston, SC|
| 375|,|Lanier, Wayne|,|San Francisco, CA|
|HAL|,|Lans, Hannes|,|Erasmus MC, Rotterdam, The Netherlands|
|1963|,|Lanzano, Luca|,|University of Catania, Catania, Italy|
|4004|,|Lanzer, Rosane|,|Universidade de Caxias do Sul, Caxias do Sul, Brazil|
|LRL|,|Lapierre, Louis|,|Brown University, Providence, RI|
|1955|,|Laplanche, Jean-Louis|,|University of Paris, Paris, France|
|4052|,|Lara, Joshua|,|University of Texas, Austin, TX|
|1382|,|Larochelle, Denis|,|Clark University, Worcester, MA|
|PL|,|Larsen, Pamela|,|University of Texas, San Antonio, TX|
|3990|,|Larson, Stephanie|,|Pacific Union College, Angwin, CA|
|OQ|,|Laurent, Patrick|,|ULB Neuroscience Institute (UNI), Brussels, Belgium|
|1266|,|Lauring, Brett|,|Columbia University, New York, NY|
|2003|,|Lauter, Adrienne|,|Iowa State University, Ames, IA|
|4206|,|Lawrence, Catharine|,|University of Strathclyde, Glasgow, Scotland, UK|
| 529|,|Lawrence, H. Marie|,|Cedar Crest College, Allentown, PA|
|3553|,|Laws, Tom|,|DSTL, Porton Down, UK|
|2163|,|Lawton, Michael|,|Rutgers University, New Brunswick,NJ|
|3939|,|Le Tho, Son|,|Vietnam Forestry Uiniversity, Hanoi, Vietnam|
|4327|,|LeBlanc, Gerald|,|North Carolina State University, Raleigh, NC|
|2174|,|LeClair, Elizabeth|,|DePaul University, Chicago, IL|
|1281|,|LeManski, Cheryl|,|Los Alamos National Lab, Los Alamos, NM|
|3591|,|LeMieux, Julianna|,|Mercy College, Dobbs Ferry, NY|
|3865|,|Leach, Megan|,|AgBiome, Research Triangle Park, NC|
|3716|,|Leacock, Stephanie|,|University of Texas, Austin, TX|
|1827|,|Leal, Sixto|,|Florida International University, Miami, FL|
| 257|,|Leatherman, Dennis|,|Department of Toxinology, USAMRIID, Fort Detricx, Frederick, MD|
|JX|,|Lechleiter, James|,|University of Texas, San Antonio, TX|
|1122|,|Lecuppre, Anita|,|Institut Pasteur, Lille, France|
| 606|,|Leder, Philip|,|Harvard Medical School, Boston, MA|
|2448|,|Lee, Cheng-Yu|,|University of Michigan, Ann Arbor, MI|
|1081|,|Lee, Chi-Chang|,|National Yang-Ming University, Taipei, Taiwan|
|2331|,|Lee, Chi-Ying|,|National Changhua University of Education, Taiwan|
|3609|,|Lee, Donghee|,|University of Seoul, Seoul, South Korea|
| 595|,|Lee, Dukgyu|,|Hanwha Chemical Company, Daejun, South Korea|
|3577|,|Lee, Elaine Choung-Hee|,|University of Connecticut, Storrs, CT|
|4344|,|Lee, Garrick|,|First Hospital Affiliated to Henan University, KaiFeng, Henan, China|
|3738|,|Lee, Hyung Ho|,|Pukyong National University, Busan, South Korea|
|2981|,|Lee, Insuk|,|Yonsei University, Seoul, South Korea|
|3903|,|Lee, Jeannie|,|Massachusetts General Hospital, Boston, MA|
|YUW|,|Lee, Jin Il|,|Yonsei University, Seoul, South Korea|
|1953|,|Lee, Jin-Sang|,|Wonkwang University, Chonbuk, South Korea|
|LJ|,|Lee, Junho|,|Yonsei University, Seoul, Korea|
|2708|,|Lee, Meng|,|Tianjin University, Tianjin, China|
|3405|,|Lee, Mi-Young|,|Korea Institute of Oriental Medicine, Daejeon, South Korea|
|YN|,|Lee, Min-Ho|,|SUNY, Albany, NY|
|BU|,|Lee, Myeongwoo|,|Baylor University, Waco, TX|
|MHL|,|Lee, Myon-Hee|,|East Carolina University, Greenville, NC|
|3848|,|Lee, Richard|,|Brigham and Women's Hospital, Cambridge, MA|
|3823|,|Lee, Samuel|,|New Mexico VA Health Care System, Albuquerque, NM|
|IJ|,|Lee, Seung-Jae|,|Postech, Pohang, South Korea|
|3151|,|Lee, Seung-Jae|,|Konkuk University, Seoul, South Korea|
|2613|,|Lee, Simon|,|University of Macau, Macau, China|
| 633|,|Lee, Soo-Ung|,|Hallym University, Chunchon, South Korea|
|3222|,|Lee, Suk Kyoo|,|Korea Science Academy of KAIST, Busan, South Korea|
|IU|,|Lee, Sylvia|,|Cornell University, Ithaca, NY|
|1465|,|Lee, Won-Jae|,|Ewha Womens University, Seoul, South Korea|
|2017|,|Lee, Ying-Hue|,|Academia Sinica, Taipei, Taiwan|
| 624|,|Lees, Jacqueline|,|MIT, Cambridge, MA|
|3334|,|Lefebvre, Daniel|,|Queen's University, Kingston, Ontario, Canada|
|RD|,|Legouis, Renaud|,|CNRS-CGM, Gif sur Yvette, France|
|3147|,|Lehmann, Ruth|,|NYU Medical Center, New York, NY|
|BCN|,|Lehner, Ben|,|Centre de Regulacio Genomica, Barcelona, Spain|
| 672|,|Lehtinen, Markku|,|Finnish Environment Institute, Helsinki, Finland|
|3940|,|Lei, Wu|,|Shanghai Insti f Microsystem & Info Tech, CAS, Shanghai, China|
|1128|,|Leibold, Elizabeth|,|University of Utah, Salt Lake City, UT|
|3926|,|Leidel, Sebastian|,|Max Planck Institute for Molecular Biomedicine, Muenster, Germany|
|AML|,|Leifer, Andrew|,|Princeton University, Princeton NJ|
|2478|,|Leippe, Matthias|,|Christian-Albrechts-Universitat, Kiel, Germany|
|1831|,|Leitao, Jorge|,|Portugal|
|3951|,|Leitao, Jorge|,|Instituto Superior Tecnico, Lisboa, Portugal|
|3875|,|Leite, Romario|,|Federal University of Minas Gerais, Belo Horizonte, Brazil|
|4036|,|Lemichez, Emmanuel|,|entre Méditerranéen de Médecine Moléculaire, INSERM, Nice, France|
|LB|,|Lemire, Bernard|,|University of Alberta, Edmonton, Canada|
|4207|,|Lemons, Michele|,|Assumption College, Worcester, MA|
|1147|,|Lenard, John|,|University of Medicine and Dentistry of New Jersey, Piscataway, NJ|
|3992|,|Lenard, Natalie|,|Our Lady of the Lake College, Baton Rouge, LA|
|4087|,|Lenox, Cheryl|,|Brophy College Preparatory, Phoenix, AZ|
|3296|,|Lentz, Susan|,|Lake Michigan College, Benton Harbor, MI|
|2512|,|Leonard, Sarah|,|North Carlina State University, Raleigh, NC|
|3550|,|Leonessa, Alexander|,|Virginia Tech, Blacksburg, VA|
|2384|,|Leonetti, Jean-Paul|,|CNRS, CPBS, Montpellier, France|
|3281|,|Lepenies, Bernd|,|MPI - Colloids and Interfaces, Berlin, Germany|
| 789|,|Lephoto, Catherine|,|University of the Witwatersrand, Johannesburg, Republic of South Africa|
|RX|,|Leroi, Armand|,|Imperial College at Silwood Park, Ascot, Berks, UK|
|MX|,|Leroux, Michel|,|Simon Fraser University, Burnaby, BC, Canada|
|LZ|,|Lesa, Giovanni|,|University College London, London, England|
|3200|,|Lesouhaitier, Olivier|,|Université de Rouen, Evroux, France|
|BJ|,|Leube, Rudolf|,|Johannes Gutenberg University, Mainz, Germany|
| 981|,|Lev, Sima|,|Weizmann Institute of Science, Rehovot, Israel|
|1320|,|Levery, Steven|,|University of New Hampshire, Durham, NH|
|1414|,|Levin, Michael|,|Tufts University, Medford, MA|
|1395|,|Levine, Alex|,|Hebrew University of Jerusalem, Jerusalem, Israel|
|1536|,|Levine, Beth|,|University of Texas Southwestern Medical Center, Dallas, TX|
|ERL|,|Levine, Erel|,|Harvard University, Cambridge, MA|
|SH|,|Levitan, Diane|,|Schering-Plough Research Institute, Kenilworth, NJ|
|3597|,|Levy, Nicholas|,|INSERM-DRMPS, Marseille, France|
|TD|,|Lew, Ken|,|Forsyth Dental Center, Boston, MA|
|1778|,|Lewis, Aaron|,|Hebrew University, Jerusalem, Israel|
|ZZ|,|Lewis, Jim|,|University of Texas, San Antonio|
| 883|,|Lewis, Stephen|,|Clemson University, Clemson, SC|
|4319|,|Li, An|,|Research Center of Agricultural Standards & Testing, Beijing, China|
|2211|,|Li, Chaojun|,|Nanjing Normal University, Nanjing, China|
|1206|,|Li, Chaoyue|,|Shangai Institute of Cell Biology, Shanghai, PR China|
|NY|,|Li, Chris|,|CUNY, New York, NY|
|1665|,|Li, Fie|,|Qingchun Cai|
|4270|,|Li, Haifeng|,|Guangdong Pharmaceutical University, Guangzhou, China|
|4259|,|Li, Hao|,|University of California, San Francisco, CA|
|2439|,|Li, Hongyu|,|Lanzhou University, Lanzhou, China|
|3561|,|Li, Huarong|,|Dow AgroSciences LLC, Indianapolis, IN|
|3413|,|Li, Huixin|,|Nanjing Agricultural University, Nanjing, China|
|1079|,|Li, Jianyong|,|University of Illinois, Urbana, IL|
|3381|,|Li, Long-Cheng|,|University of California, San Francisco, CA|
|2780|,|Li, PeiFang|,|Inst Zoology, Chinese Acad Science, China|
|4111|,|Li, Pengfei|,|Medical University of South Carolina, Charleston, SC|
|2690|,|Li, Qi|,|Chinese Academy of Sciences, Shenyang, China|
|3189|,|Li, Sam F.I.|,|National University of Singapore|
|4099|,|Li, Shao|,|Da Lian Medical University, Dalian, China|
|YV|,|Li, Wei|,|Tongji University, Shanghai, China|
|FW|,|Li, Weiqing|,|University of Washington, Seattle, WA|
|2294|,|Li, Wen-hong|,|University of Texas Southwestern, Dallas, TX|
|2450|,|Li, Xianchun|,|University of Arizon, Tucson, AZ|
|3527|,|Li, Xianchun|,|University of Arizona, Tucson, AZ|
|3968|,|Li, Xiao-Meng|,|Northeast Normal University, Changchun, China|
|2459|,|Li, Xiao-Ping|,|Rutgers University, New Brunswick, NJ|
|3082|,|Li, Xiaoxue|,|Northeast Normal University, China|
|YQL|,|Li, Yuqing|,|University of Alabama, Birmingham, AL|
|4193|,|Li, Zongjun|,|Hunan Agricultural University, Changsha, Hunan, China|
|2048|,|LiPuma, John|,|University of Michigan, Ann Arbor, MI|
|1825|,|Liakopoulos,|,|Heidelberg University, Heidelberg, Germany|
|LIB|,|Liang, Bin|,|Chinese Academy of Science, Kunming, China|
|3994|,|Liang, Jun|,|Borough of Manhattan Community College, CUNY, New York, NY|
|3260|,|Liang, Yan|,|Chinese Academy of Fishery Sciences, Qingdao, China|
|4204|,|Liao, Bin|,|Sun Yat-Sen University, Guangzhou, China|
|1143|,|Liao, Ching-Len|,|National Defense Medical Center, Taipei, Taiwan, ROC|
|1265|,|Liao, Vivian|,|National Taiwan University, Taipei, Taiwan|
|DLW|,|Libuda, Diana E.|,|University of Oregon, Eugene, OR|
|1127|,|Liddell, Malcolm|,|Univesity of Wales, Cardiff, UK|
|4247|,|Lieb, Jason|,|University of North Carolina, Chapel Hill, NC|
|3914|,|Lieb, Jason|,|Princeton University, Princeton NJ|
|JDL|,|Lieb, Jason|,|University of Chicago, Chicago, IL|
| 349|,|Lieb, Mark|,|Mount Sinai School of Medicine, New York, NY|
|1909|,|Liedtke, Wolfgang|,|Duke University, Durham, NC|
|1046|,|Lilley, Andrew|,|CEH Oxford, Oxford, England|
| 884|,|Lim, Chang-Su|,|Lawrence Berkeley National Laboratory, Berkeley, CA|
|1223|,|Lim, Rita|,|Whitehead Institute, Cambridge, MA|
|4105|,|Lim, Sa Rang|,|Chung-ang University, Seoul, South Korea|
|3805|,|Lim, Young-Hee|,|Korea University, Seoul, South Korea|
|4244|,|Lin, Chia Yu|,|California State University - Dominguez Hills, Carson, CA|
|2508|,|Lin, Chung-Chih|,|National Yang Ming University, Taipei, Taiwan|
|3441|,|Lin, Fangju|,|Coastal Carolina University, Conway, SC|
|2728|,|Lin, Hongli|,|Fujian Agriculture & Forestry University, Fujian, China|
|3835|,|Lin, Jintian|,|Zhongkai Univ of Ag & Eng, Guangzhou, Guangdong, China|
|3816|,|Lin, Kuangfei|,|East China University of Science and Technology, Shanghai, China|
|3086|,|Lin, Po-Chen|,|Gwoxi Stem Cell Applied Technology, Taiwan|
|TX|,|Lin, Rueyling|,|UTSW Medical Center, Dallas, TX|
|2295|,|Lin, Shuo|,|University of California, Los Angeles, CA|
|4227|,|Lin, Wei-Yong|,|China Medical University, Taiwan|
|2787|,|Lin, Wenhan|,|Peking University, Beijing, China|
|1295|,|Lin, Xinyi|,|CLSL Urbana, IL|
|OZ|,|Lindblom, Tim|,|Lyon College, Batesville, AR|
|1849|,|Linden, Karl|,|Duke University, Durham, NC|
|1297|,|Linder, Ewert|,|Swedish CDC, Solna, Sweden|
|2404|,|Lingaas, Egil|,|Oslo University, Oslo, Norway|
|CL|,|Link, Chris|,|University of Colorado, Boulder, CO|
|VU|,|Link, Elizabeth|,|Vanderbilt University Medical Center, Nashville, TN|
| 844|,|Link, Wolfgang|,|University of Munich, Germany|
|ZL|,|Lints, Robyn|,|Texas A & M University, College Station, TX|
| 793|,|Liou, Willisa|,|Chang Gung University, Taiwan|
|2964|,|Lipke, Peter|,|Brooklyn College, New York, NY|
|3128|,|Lipp, Erin|,|University of Georgia, Athens, GA|
|2988|,|Lipton, Stuart|,|Sanford-Burnham Med Research Inst, La Jolla, CA|
|JL|,|Lissemore, Jim|,|John Carroll University, University Heights, OH|
|GL|,|Lithgow, Gordon|,|Buck Institute, Novato, CA|
| 540|,|Little Rock High School, Little Rock, AR|,||
|3945|,|Littlefield, Ryan|,|University of South Alabama, Mobile, AL|
|3655|,|Liu, Ailin|,|Hua Zhong University of Science and Technology, Wuhan, China|
|2275|,|Liu, Bi-Feng|,|Huzzhong University of Science and Technology, Wuhan, China|
|PLD|,|Liu, Dong|,|Peking University, Beijing, China|
|4149|,|Liu, He|,|Gannon University, Erie, PA|
|3315|,|Liu, Jianfeng|,|Huazhong University of Science and Technology, Wuhan, China|
| 290|,|Liu, Jie|,|Institute of Parasitology, McGill University, Quebec, Canada|
|LW|,|Liu, Kelly|,|Cornell University, Ithaca, NY|
|3795|,|Liu, Lei|,|Peking University, Beijing, China|
|LL|,|Liu, Leo|,|Cambria Biosciences, Waltham, MA|
|LIU|,|Liu, Pingsheng|,|Chinese Academy of Sciences, Beijing, China|
|2134|,|Liu, Rihe|,|University of North Carolina, Chapel Hill, NC|
|3261|,|Liu, Ruixin|,|Shanghai Jiaotong University School of Medicine, Shanghai, China|
|3888|,|Liu, Shijie|,|State University of New York - ESF, Syracuse, NY|
|4225|,|Liu, Shushen|,|Tongji University, Shanghai, China|
|3368|,|Liu, Xianming|,|China Academy of Sciences, Dalian, China|
|XIL|,|Liu, Xiao|,|Tsinghua University, Beijing, China|
|4181|,|Liu, Xiaoyu|,|Shenyang Pharmaceutical University, Shenyang, Liaoning, China|
|3762|,|Liu, Xu|,|Inst of Agro-Products Processing Science & Tech CAAS, China|
|1848|,|Liu, Xuming|,|Kansas State University, Manhattan, KS|
|3356|,|Liu, Yang|,|Chinese Academy of Sciences, Beijing, China|
|3794|,|Liu, Ying|,|Peking University, Beijing, China|
|4136|,|Liu, Ying|,|Notre Dame de Namur University, Belmont, CA|
|3265|,|Liu, Zhonghua|,|Hunan Agriculture University, Chasha, Hunan, China|
|3929|,|Liubicich, Danielle|,|Los Medanos College, Pittsburg, CA|
|3898|,|Liudkovska, Vladyslava|,|University of Warsaw, Warsaw, Poland|
|3529|,|Liuzzi, Juan|,|Florida International University, Miami, FL|
|1337|,|Lively, Curt|,|Indiana University, Bloomington, IN|
| 573|,|Lixing, Weng|,|National University of Singapore|
|4037|,|Llinas, Rodolfo|,|Marine Biology Laboratory, Woods Hole, MA|
|2006|,|Lloyd, Christine|,|Dickinson College, Carlisle, PA|
|3155|,|Lloyd, R. Stephen|,|Oregon Health & Science University, Portland, OR|
|3766|,|Lo, Su Hao|,|University of California, Davis, CA|
|SJL|,|Lo, Szecheng|,|Chang Gung University, TaoYuan, Taiwan|
|TWL|,|Lo, Te-Wen|,|Ithaca College, Ithaca, NY|
|2353|,|Lobner-Olesen, Anders|,|Roskilde University, Roskilde, Denmark|
|2832|,|Lobocka, Malgorzata|,|Inst Biochem & Biophys - Polish Acad Sci, Warsaw, Poland|
|1094|,|Lochnit, Gunter|,|Justus-Liebig University, Giessen, Germany|
|XL|,|Lockery, Shawn|,|University of Oregon, Eugene, OR|
|1077|,|Lockheed Martin|,|Moffett Field, CA|
|3755|,|Locksley, Rich|,|University of California, San Francisco, CA|
|LC|,|Loer, Curtis|,|University of San Diego, San Diego, CA|
|1508|,|Logan, Darren|,|University of Edinburgh, Edinburgh, UK|
|UV*|,|Loidl, Josef|,|University of Vienna, Vienna, Austria|
|PV|,|Lok, James|,|University of Pennsylvania, Philadelphia, PA|
|1437|,|Lom, Barbara|,|Davidson College, Davidson, NC|
| 919|,|Lombardino, Anthony|,|Rockefeller University Field Research Center, Millbrook, NY|
|2824|,|Long, Chengzu|,|University of Texas Southwestern Medical Center, Dallas, TX|
|3727|,|Long, Olivia|,|University of Pittsburgh, Greensburg, PA|
|4288|,|Lopes Guimaraes, Luciana|,|Santa Cecilia University, Santos, SP, Brazil|
|3964|,|Lopez-Llorca, Luis Vicente|,|Universidad de Alicante, Alicante, Spain|
| 893|,|Lopez-Otin, Carlos|,|University of Oviedo, Oviedo, Spain|
|2924|,|Loric, Sylvain|,|Mondor University Hospital, Creteil, Frnace|
|1570|,|Lorson, Monique|,|University of Missouri, Columbia, MO|
|3278|,|Losick, Richard|,|Harvard University, Cambridge, MA|
|2143|,|Lostroh, Phoebe|,|Colorado College, Colorado Springs, CO|
|2162|,|Lowe, Mark|,|University of Pittsburgh, Pittsburgh, PA|
|3471|,|Lozano, Andres M|,|Toronto Western Research Institute, Toronto, ON, Canada|
|ENL|,|Lozano, Encarnacion|,|Instituto de Salud Carlos III, Majadahonda, Spa|
| 676|,|Lu, Bin|,|Academia Sinica, Beijing, China|
|4096|,|Lu, Han|,|University of California, Berkeley, CA|
|GT|,|Lu, Hang|,|Georgia Institute of Technology, Atlanta, GA|
|2631|,|Lu, Jianxin|,|Wenzhou Medical College, Wenzhou City, China|
|LSJ|,|Lu, Nancy|,|San Jose State University, San Jose, CA|
|3136|,|Lu, Rui|,|Louisiana State University, Baton Rouge, LA|
|3882|,|Lucas, Rob|,|University of Manchester, Manchester, UK|
|1959|,|Ludewig, Andreas|,|MPI for Molecular Genetics, Berling, Germany|
|3578|,|Ludrick, Brad|,|Southeastern Oklahoma State University, Durant, OK|
|KLU|,|Luersen, Kai|,|Christian-Albrechts-University of Kiel, Kiel, Germany|
|4129|,|Lugo-Radillo, Agustin|,|Catedras CONACYT, Villa De Alvarez, Colima, Mexico|
| 769|,|Luke, Cliff|,|Children's Hospital, Boston, MA|
|1682|,|Luke, Graham|,|University of Reading, Reading, UK|
|4187|,|Lumyong, Saisamorn|,|Chiang Mai University, Chiang Mai, Thailand|
|1510|,|Lun, Zhao-Rong|,|Zhongshan University, Guangzhou, China|
|1324|,|Lund, Diane|,|University of Great Falls, Great Falls, MT|
|1525|,|Lund, Jim|,|University of Kentucky, Lexington, KY|
|LE|,|Lundquist, Erik|,|University of Kansas, Lawrence, KS|
|2841|,|Luo, Huai-Rong|,|CAS - Kunming Institute of Botany, Yunnan, China|
|3415|,|Luo, Liulin|,|Tongji University, Shanghai, China|
|MLU|,|Luo, Ming|,|University of Alabama, Birmingham, AL|
|2485|,|Luo, Qingming|,|Huazhong University of Science & Technology, Wuhan, China|
|1971|,|Luo, Yuan|,|University of Maryland, Baltimore, MD|
|3408|,|Lutz, Kerry|,|Farmingdale State College, Farmingdale, NY|
|3869|,|Lvov, Yuri|,|Louisiana Tech University, Ruston, LA|
|US|,|Lyczak, Rebecca|,|Ursinus College, Collegeville, PA|
|JLG|,|Lyman Gingerich, Jamie|,|University of Wisconsin, Eau Claire, WI|
|3818|,|Lynbrook High School|,|Lynbrook High School, San Jose, CA|
|MLY|,|Lynch, Michael|,|Indiana University, Bloomington, IN|
|3563|,|Lynn, Holly|,|University of Oregon, Eugene, OR|
|2599|,|Lynne, Aaron|,|Sam Houston State University, Huntsville, TX|
|3105|,|Lyons, Barbara A.|,|New Mexico State University, Las Cruces, NM|
|4039|,|Ma, Cuiqing|,|CAS, Shandong University, Jinan, China|
|3432|,|Ma, Cuiyan|,|Chinese Academy of Fishery Sciences, Qingdao, Shandong, China|
|DMS|,|Ma, Dengke|,|University of California, San Francisco, CA|
|3892|,|Ma, Hongbo|,|University of Wisconsin, Milwaukee, WI|
|2855|,|Ma, Junfeng|,|Jiln University, Changchun, China|
|4050|,|Ma, Li-Jun|,|University of Massachusetts, Worcester, MA|
|2050|,|Ma, Lixin|,|Hubei University, WuHan, China|
|CSM|,|Ma, Long|,|Central South University, Changsha, China|
|1985|,|Ma, Wen Li|,|Southern Medical University, Guangzhou, China|
|4203|,|Ma, Zongyuan|,|Beijing Inst of Life Science, CAS, Beijing, China|
|3693|,|MacInnes, Alyson|,|Hubrecht Institute, Utrecht, The Netherlands|
|1998|,|MacKenzie, James|,|Oswego State University of New York, Oswego, NY|
|LMN|,|MacNeil, Lesley|,|McMaster University, Hamilton, ON, Canada|
|2693|,|Macaranas, Julie|,|University of Queensland, St. Lucia QLD, Australia|
|KAM|,|Machaca, Khaled|,|Weill Cornell Medical College, Doha, Qatar|
|2464|,|Machingo, Quentin|,|Manhattan College, Bronx, NY|
|MAC|,|Maciel, Patricia|,|Universidade do Minho, Braga, Portugal|
|4179|,|Mackereth, Cameron|,|Insitut Europeen de Chimie et Biologie, Bordeaux, France|
|1824|,|Mackey, Parijata|,|University of Chicago, Chicago, IL|
|CUP|,|Macurkova, Marie|,|Charles University, Prague, Czech Republic|
|2287|,|Madden, Robert|,|Fordham University, New York, NY|
|MDX|,|Maddox, Paul and Maddox, Amy|,|University of North Carolina, Chapel Hill, NC|
|3639|,|Madewell, Leigh|,|Lubbock Christian University, Lubbock, TX|
|3004|,|Madhyastha, Sri|,|Kane Biotech Inc., Winnipeg, MB, Canada|
|1009|,|Madi, Andras|,|University of Debrecen, Hungary|
|1450|,|Madou, Marc|,|University of California, Irvine, CA|
|MS|,|Maduro, Morris|,|University of California, Riverside, CA|
|2783|,|Magnusen, Joan|,|Keuka College, Keuka Park, NY|
| 325|,|Magrassi, Lorenzo|,|Florida State University, Tallahassee, FL|
|3093|,|Mahran, Amro|,|Canadian Food inspection Agency, Ottawa, ON, Canada|
|4293|,|Maiden, Stephanie|,|Truman State University, Kirksville, MO|
|1241|,|Maier, Ingo|,|University of Konstanz, Konstanz, Germany|
|2488|,|Mailler, Roger|,|University of Tulsa, Tulsa, OK|
|EL|,|Maine, Eleanor|,|Syracuse University, Syracuse, NY|
|HR|,|Mains, Paul|,|University of Calgary, Calgary, Alberta|
|WBM|,|Mair, William|,|Harvard School of Public Health, Boston, MA|
|1345|,|Maisnier-Patin, Sophie|,|Swedish Institute for Infectious Disease Control, Solna, Sweden|
|1379|,|Maiss, Edgar|,|Universitaet Hannover, Hannover, Germany|
|2986|,|Maistrellis, Nicholas|,|St. John's College, Annapolis, MD|
|VS|,|Mak, Ho Yi|,|Hong Kong U of Sci & Tech, Clear Water Bay, Kowloon, Hong Kong|
|2299|,|Makarevitch, Irina|,|Hamline University, St. Paul, MN|
|3353|,|Maklakov, Alexei|,|Uppsala University, Uppsala, Sweden|
|2252|,|Malabarba, Mariagrazia|,|IFOM Foundation, Milan, Italy|
|MRP*|,|Malik, Harmit|,|Fred Hutchinson Cancer Research Center, Seattle, WA|
|2402|,|Malladi, Shyamala|,|Stanford University, Stanford, CA|
|4011|,|Mallette, Frederick A.|,|Centre de Recherche de l'Hôpital Maisonneuve-Rosemont, Montreal, QC, Canada|
|FAM|,|Mallette, Frederick Antoine|,|Centre de Recherche de l'Hpital Maisonneuve-Rosemont, Montreal, Canada|
|2772|,|Mallucci, Giovanna|,|MRC Toxicology Unit, Leicester, UK|
|CJ|,|Malone, Chris|,|Penn State, University Park, PA|
|3961|,|Malotky, Michele|,|Guilford College, Greensboro, NC|
|UC|,|Mancillas, Jorge|,|Northwestern University, Chicago, IL|
|PIR|,|Mandelkow, Eckhard|,|DZNE, Bonn, Germany|
|4155|,|Mandino, Aniello|,|Fondazione Telethon, Rome, Italy|
|2502|,|Manganiello, Vincent|,|NIH, Bethesda, MD|
|1562|,|Mangelsdorf, David|,|University of Texas Southwestern, Dallas, TX|
|3730|,|Mangiamele, Lisa|,|State University of New York, Plattsburgh, NY|
|SM|,|Mango, Susan|,|Harvard University, Cambridge, MA|
|3270|,|Mangone, Marco|,|Arizona State University, Tempe, AZ|
|2557|,|Mania-Farnell, Barbara|,|Purdue University Calumet, Hammond, IN|
|1319|,|Maniatis|,|Harvard University, Cambridge, MA|
|2852|,|Manier, Nicolas|,|Laboratory EXES-INERIS, Verneuil-en-Halatte, France|
|GNE|,|Manning, Gerard|,|Genentech, South San Fransisco, CA|
|2807|,|Mano, Hiroshi|,|Josai University, Saitama, Japan|
|IMN|,|Mano, Itzik|,|City University of New York, New York, NY|
| 826|,|Manoil, Colin|,|University of Washington, Seattle, WA|
|LK|,|Manser, Jim|,|Harvey Mudd College, Claremont, CA|
| 949|,|Manwell, Anne|,|Stuyvesant High School, New York, NY|
|2407|,|Marc Meneghini|,|University of Toronto, Toronto, Ontario, Canada|
|MRM|,|Marcello. Matthew|,|Pace University, New York, NY|
|3586|,|Marcette, Jana Dorfmann|,|Harris-Stowe State University, St. Louis, MO|
|3763|,|March, John|,|Cornell University, Ithaca, NY|
|2060|,|Marchant, Jonathan|,|University of Minnesota, Minneapolis, MN|
|1855|,|Marcotte, Edward|,|University of Texas, Austin, TX|
|1208|,|Mardulyn, Patrick|,|Free University of Brussels, Gosselies, Belgium|
|1793|,|Margis, Rogerio|,|Universidade Federal do Rio Grande Do Sul, Porto Alegre, Brasil|
|1567|,|Marichal, Marisol|,|Universidad de La Laguna, Tenerife, Canary Islands, Spain|
|VM|,|Maricq, Villu|,|University of Utah, Salt Lake City, UT|
|3292|,|Marie, Nicolas|,|INSERM Laboratoire de neuropsychopharmacologie, Paris, France|
|3813|,|Marin de Evsikova, Caralina|,|University of South Florida, Tampa, FL|
|3605|,|Marin, Paula|,|Universitat de Barcelona, Barcelona, Spain|
|2024|,|Marin, Veronica|,|San Juan College, Farmington, NM|
| 647|,|Marine Biological Laboratory|,|Woods Hole, MA|
|3240|,|Marinus, Martin|,|UMass Medical School, Worchester, MA|
|3390|,|Marks, Andrew|,|Columbia University, New York, NY|
| 544|,|Marks, Sandy|,|State University of New York, Brockport, NY|
|2833|,|Markvardsen, Marianne|,|Novozymes A/S, Copenhagen, Denmark|
|1599|,|Markwardt, David|,|Ohio Wesleyan University, Delaware, OH|
| 794|,|Marletta, Michael|,|University of Michigan Medical School, Ann Arbor, MI|
|4212|,|Marques da Cunha, Fernanda|,|Escola Paulista de Medicina, Sao Paulo, Brazil|
|3012|,|Marquis, Bryce|,|University of Central Arkansas, Conway, AR|
|1561|,|Marr, Tom|,|University of Alaska, Fairbanks, AK|
|1280|,|Marsden, David|,|University of Southampton, Southampton, UK|
|3237|,|Marshall-Walker, Christine|,|Phillips Academy, Andover, MA|
|1005|,|Martens, Henrik|,|Kassel University, Kassel, Germany|
|JRM|,|Martens, Jeffrey|,|University of Michigan, Ann Arbor, MI|
|1031|,|Martens, Rob|,|Dickinson College, Carlisle, PA|
|2648|,|Martin, Katherine|,|University of Aberystwyth, Ceredigion, UK|
|4068|,|Martin, Margarita|,|Universidad Complutense de Madrid, Madrid, Spain|
| 863|,|Martin, Nancy|,|Queen's University, Kingston, Ontario, Canada|
|1549|,|Martin, Richard|,|Iowa State University, Ames, IA|
|3526|,|Martin, Richard|,|Iowa State University, Ames, IA|
| 543|,|Martin, Thomas|,|University of Wisconsin, Madison, WI|
|4154|,|Martinelli, Simone|,|Istituto Superiore di Sanita, Rome, Italy|
|2700|,|Martinez Acosta, Veronica|,|University of the Incarnate Word, San Antonio, TX|
|2996|,|Martinez, Antonio|,|Council of Scientifc Research (CSIC), Madrid, Spain|
|2067|,|Martinez, Aurora|,|University of Bergen, Bergen, Norway|
|1929|,|Martinez, Veronica|,|Southwestern University, Georgetown, TX|
|ATG|,|Martinez-Perez, Enrique|,|Imperial College, London, UK|
| 698|,|Martinez-Torres, Ataulfo|,|University of California, Irvine, CA|
|3661|,|Martinis, Susan|,|University of Illinois, Urbana, IL|
|1714|,|Martinou, J.|,|University of Geneva, Geneva, Switzerland|
|JCM|,|Martinou, Jean-Claude|,|University of Geneva, Geneva, Switzerland|
|3810|,|Marusich, Elena|,|BioPharmCluster, Moscow Inst of Physics & Tech, Moscow, Russia|
|2171|,|Maruta, Hiroshi,|,|University of Maryland, Baltimore, MD|
|OF|,|Maruyama, Ichiro|,|Okinawa Institute of Science and Technology, Okinawa, Japan|
| 797|,|Marykwas, Donna|,|University of Southern Mississippi, Hattiesburg, MS|
|2601|,|Maser, Pascal|,|University of Bern, Bern, Switzerland|
|2721|,|Mason, Adam|,|Siena College, Loudonville, NY|
| 306|,|Mason, Don|,|Buckhannon, WV|
| 374|,|Masumoto, Hiroshi|,|Nagoya University, Chikusa-ku, Nagoya, Japan|
|2401|,|Mathee, Kalai|,|Florida International University, Miami, FL|
|4221|,|Mathew, Layla|,|American Learning Systems, Plantation, FL|
|RA|,|Mathies, Laura|,|Virginia Commonwealth University, Richmond, VA|
|1426|,|Matsugi, Jitsuhiro|,|Jichi Medical School, Tochigi, Japan|
|1059|,|Matsumoto, Hiroshi|,|Sapporo Medical University, Sapporo, Japan|
|KU|,|Matsumoto, Kunihiro|,|Nagoya University, Nagoya, Japan|
| 780|,|Matsumoto, Shinya|,|Kyoto Women's University, Kyoto, Japan|
|3587|,|Matsunami, Katsuyoshi|,|Hiroshima University,  Hiroshima,  Japan|
| 642|,|Matsuo, Takashi|,|Toyohashi University of Technology, Toyohashi, Japan|
|2386|,|Matsuura, Tetsuya|,|Iwate University, Morioka, Japan|
|1164|,|Matsuzaki, Hiroaki|,|Fukuyama University, Hiroshima, Japan|
|IWM|,|Mattaj, Iain|,|EMBL, Heidelberg, Germany|
| 651|,|Matthews, H.M.|,||
| 258|,|Matthews, Terry|,|Millikin University, Decatur, IL|
| 839|,|Mattson, Mark|,|National Institute on Aging, Baltimore, MD|
|DQM|,|Matus, David|,|Stony Brook University, Stony Brook, NY|
|2902|,|Mavrodi, Dmitri|,|USDA-ARS, Wash St Univ, Pullman, WA|
|1585|,|Mawassi, Munir|,|ARO, The Volcani Center, Bet-Dagan, Israel|
| 722|,|Maxfield, Fred|,|Weill Medical College of Cornell Univ, Ithaca, NY|
|4185|,|May, Alfred|,|LMG/NIA/NIH, Baltimore, MD|
|FB|,|May, Robin|,|University of Birmingham, Birmingham, UK|
|1983|,|Mayda, Maria|,|Walter Reed Army Institute of Research, Silver Spring, MD|
|2625|,|Mazur, Eric|,|Harvard University, Cambridge, MA|
|2572|,|Mazzotta, Gabriella|,|University of Padova, Padova, Italy|
|DIV|,|McCarter, James|,|Divergence, St. Louis, MO|
|2022|,|McCaughan, Danny|,|Vanderbilt University, Nashville, TN|
|4331|,|McCaw, Allison|,|Mountain View High School, Mesa, AZ|
|3707|,|McClean, Siobhan|,|Institute of technology, Tallaght, Dublin, Ireland|
|2051|,|McClung, Keith|,|Wartburg College, Waverly, IA|
|GMC|,|McColl, Gawain|,|Mental Health Research Institute, Parkville, VIC, Australia|
|2397|,|McCutcheon, Suzanne|,|University of Illinois at Chicago, Chicago, IL|
| 798|,|McDonald, John|,|University of Georgia Genetics Department, Athens, GA|
|2991|,|McDonald, Matthew|,|Drexel University, Philadelphia, PA|
|1160|,|McDonough, Deb|,|University of New England, Biddeford, ME|
|4230|,|McFarland, Sherri|,|Acadia University, Wolfville, NS, Canada|
|1420|,|McGaw, Lyndy|,|University of Pretoria, Onderstepoort, South Africa|
|2000|,|McGee, Seth|,|University of Wisconsin, Madison, WI|
|2823|,|McGee, Seth|,|University of Wisconsin, Madison, WI|
|AMM|,|McGehee, Annette|,|Suffolk University, Boston, MA|
|JM|,|McGhee, Jim|,|University of Calgary, Alberta|
|PMG|,|McGlynn, Peter|,|University of York, York, UK|
|3109|,|McGowan, Frank|,|Medical University of South Carolina, Charleston, SC|
| 717|,|McGrath, Mitch|,|Michigan State University, East Lansing, MI|
|PTM|,|McGrath, Patrick|,|Georgia Institute of Technology, Atlanta GA|
|1688|,|McGrew, Lori|,|Belmont University, Nashville, TN|
|2358|,|McGuire, Jeanette|,|Michigan State University, East Lansing, MI|
|4358|,|McInerney, Miles|,|University of Technology, Sydney, Australia|
|BZ|,|McIntire, Steve|,|Gallo Center, UCSF, San Francisco, CA|
|4336|,|McIntyre, Cynthia|,|Everett High School, Everett, WA|
|4362|,|McLaughlin, Patrick|,|APSE Inc., St. Louis, MO|
|RJM|,|McMullan, Rachel|,|Imperial College London, London, UK|
|FM|,|McNally, Frank|,|University of California, Davis, CA|
|1870|,|McVeigh, Paul|,|Queen's University Belfast, Belfast, Ireland, UK|
|2444|,|Mcloughlin,|,|Trinity College, Dublin, Ireland|
|3362|,|Meacci, Elisabetta|,|Universita degli Studi di Firenze, Florence, Italy|
| 866|,|Means, Dr.|,|Duke University Medical Center, Durham, NC|
| 267|,|Mecca, Christyna|,|Department of Biology, Waynesburg College, Waynesburg, PA|
|3788|,|Medina, Paul Mark|,|University of the Philippines, Manila, Philippines|
|3451|,|Meemon, Krai|,|Mahidol University, Bangkok, Thailand|
|3288|,|Meewan, Maliwan|,|Anacor Pharmaceuticals, Palo Alto, CA|
| 287|,|Megason, Sean|,|University of Texas at Austin|
|3271|,|Meighan, Christopher|,|Christopher Newport University, Newport News, VA|
|2440|,|Meiler, Steffen|,|Medical College of Georgia, Augusta, GA|
|3117|,|Meister, Konrad|,|Ruhr University, Bochum, Germany|
|PMW|,|Meister, Peter|,|Inst of Cell Biology, Univ of Bern, Switzerland|
|OB|,|Mekada, Eisuke|,|Osaka University, Osaka, Japan|
|1293|,|Mekalanos, John|,|Harvard Medical School, Boston, MA|
|QU|,|Melendez, Alicia|,|Queens College, CUNY, Flushing, NY|
|1135|,|Mellies, Jay|,|Reed College, Portland, OR|
|4241|,|Mellin, JR|,|Zymergen, Emeryville, CA|
|WM|,|Mello, Craig|,|University of Massachusetts, Worcester, MA|
|2851|,|Mellor, Jane|,|University of Oxford, Oxford, England, UK|
|2231|,|Melloy, Patricia|,|Fairleigh Dickinson University, Teaneck, NJ|
| 524|,|Melov, Simon|,|Buck Center for Research in Aging, Novato, CA|
|1644|,|Melville, John|,|Wartburg College, Waverly, IA|
|3494|,|Melvin, Neal|,|Quest University, British Columbia, Canada|
|2724|,|Mena, Edward|,|University of Connecticut - Avery Point, Groton, CT|
|2441|,|Menard, Ray|,|St. Petersburg College, St. Petersburg, FL|
|FH|,|Meneely, Phil|,|Haverford College, Havorford, PA|
|2685|,|Menezes de Oliveira, Aleksandra|,|Universidade Federal do Rio de Janeiro, Rio de Janeiro, Brazil|
|3218|,|Mengistu, Tesfamariam|,|University of Florida, Gainesville, FL|
|2268|,|Menzel, Ralph|,|Humboldt University, Berlin, Germany|
|3634|,|Merkler, David|,|University of South Florida, Tampa, FL|
|1772|,|Merrow, Martha|,|University of Munich, Munich, Germany|
|2699|,|Mertens, Inge|,|University of Antwerp, Antwerp Belgium|
|WP|,|Merz, David|,|University of Manitoba, Winnipeg, Canada|
|TY|,|Meyer, Barbara|,|University of California, Berkeley, CA|
|1552|,|Meyer, Joel|,|Duke University, Durham, NC|
| 380|,|Meyers, Craig|,|University of Florida, Gainesville, FL|
|1639|,|Mi, Qing-Sheng|,|Medical College of Georgia, Augusta, GA|
|LMW|,|Miao, Long|,|IBP, Chinse Academy of Sciences, Beijing, China|
| 923|,|Michael, Matthew|,|University of Southern Californa, Los Angeles, CA|
|MLM|,|Michalski, Shelly|,|University of Wisconsin, Oshkosh WI|
|1859|,|Michaud, Edward|,|Oak Ridge National Laboratory, Oak Ridge, TN|
|FL|,|Michaux, Gregoire|,|Universite de Rennes, Rennes, France|
|1630|,|Michels, William|,|Biotica Research Corp, Berkeley, CA|
| 902|,|Mickey, Katie|,|BioLab, Seattle, WA|
|3137|,|Middleton, Kieron|,|Scarborough College, Scarborough, UK|
|2259|,|Migliori, Maria|,|Universidad Nacional de Quilmes, Buenos Aires, Argentina|
|2912|,|Mihajlovic, Luka|,|University of Belgrade, Belgrade, Serbia|
|TMD|,|Mikeladze-Dvali, Tamara|,|Biozentrum der LMU Mnchen, Planegg-Martinsried, Germany|
| 650|,|Mikitani, Kenichi|,|Karolinska Institute, Huddinge, Sweden|
|2466|,|Mikoshiba, Katsuhiko|,|Brain Science Institute RIKEN, Saitama, Japan|
|2886|,|Milan, David|,|Massachusetts General Hospital, Charlestown, MA|
|3559|,|Milani. Katharine|,|Burlington County College, Mt. Laurel, NJ|
|1918|,|Miledi, Ricardo|,|University of California, Irvine, CA|
|3209|,|Miles, Cecelia|,|Augustana College, Sioux Falls, SD|
|2038|,|Miller, Brian|,|University of Arizona, Tucson, AZ|
|DLM|,|Miller, Dana|,|University of Washington, Seattle, WA|
|NC|,|Miller, David|,|Vanderbilt University, Nashville, TN|
|1700|,|Miller, Joanna|,|North Carolina State University, Raleigh, NC|
|2605|,|Miller, Joanna|,|Drew University, Madison, NJ|
|KG|,|Miller, Ken|,|OMRF, Oklahoma City, OK|
|SC|,|Miller, Leilani|,|Santa Clara University, Santa Clara, CA|
|XM|,|Miller, Michael|,|University of Alabama, Birmingham, AL|
|4119|,|Miller, Renee|,|University of Rochester, Rochester, NY|
|3384|,|Millimaki, Bonnie|,|Lipscomb University, Nashville, TN|
|1257|,|Mills, Edward|,|University of Texas, Austin, TX|
| 508|,|Mills, Linda|,|Playfair Neuroscience Unit, U of Toronto, Ontario|
|3338|,|Min, Hu|,|Hua Zhong Agriculture University, China|
|2707|,|Minami, Yoshiko|,|Okayama University of Science, Okayama, Japan|
|ANM|,|Minniti, Alicica|,|Pontificia Universidad Catolica de Chile, Santiago, Chile|
|2045|,|Minsky,|,|Weizmann Institute of Science, Rehovot, Israel|
|VZ|,|Miranda-Vizuete, Antonio|,|Instituto de Biomedicina de Sevilla (IBiS), Sevilla, Spain|
|QM|,|Mishima, Masanori|,|University of Warwick, Coventry, UK|
|SX|,|Miska, Eric|,|University of Cambridge, Cambridge, England|
|1717|,|Miska, Eric|,|Wellcome Trust, University of Cambridge, Cambridge, UK|
|1142|,|Miskowski, Jennifer|,|University of Wisconsin-La Crosse, La Crosse, WI|
|FX|,|Mitani, Shohei|,|Tokyo Women's Medical University School of Medicine, Tokyo, Japan|
|3618|,|Mitchell, Bryan|,|Atlanta Metropolitan State College, Atlanta, GA|
|BM|,|Mitchell, David|,|Boston Biomedical Research Institute, Boston, MA|
|2068|,|Mitchum, Melissa|,|University of Missouri, Columbia, MO|
| 705|,|Mitokor, Inc.|,|San Diego, CA|
|1342|,|Mitreva, Makedonka|,|Washington University School of Medicine, St. Louis, MO|
|3239|,|Mitsutake, Susume|,|Hokkaido University, Sapporo, Japan|
|3524|,|Mitter, Neena|,|University of Queensland, Brisbane, Australia|
|4340|,|Miura, Norimasa|,|Tottori University, Tottori, Japan|
|2393|,|Miura, Toru|,|Hokkaido University, Sapporo, Japan|
|MJ|,|Miwa, Johji|,|Chubu University, Aichi, Japan|
|3333|,|Miyahara, Kohji|,|Sojo University, Kumamoto, Japan|
| 525|,|Miyamoto, Masaaki|,|Kobe University, Kobe, Japan|
|2854|,|Miyasaka, Tomohiro|,|Doshisha University, Kyoto, Japan|
|UJ|,|Mizumoto, Kota|,|University of British Columbia, Vancouver, BC, Canada|
|3067|,|Mizunuma, Masaki|,|Hiroshima University, Hiroshima, Japan|
|3849|,|Mo, Haiping|,|Tongji University, Shanghai, China|
|1720|,|Mobbs, Charles|,|Mt. Sinai School of Medicine, New York, NY|
|2560|,|Mobjerg-Kristensen, Reinhardt|,|Natural History Museum of Denmark, Copenhagen, Denmark|
|2674|,|Modi, Vishal S|,|SSR College of Pharmacy, UT of Dadra Nagar Haveli, Silvassa, India|
|4116|,|Modis, Yorgo|,|MRC Laboratory of Molecular Biology, Cambridge, UK|
|DM|,|Moerman, Don|,|University of British Columbia, Vancouver|
|VC|,|Moerman, Don|,|C. elegans Reverse Genetics Core Facility, Vancouver, B.C., Canada|
|4305|,|Moffat, Jennifer|,|SUNY Upstate Medical University, Syracuse, NY|
|ND|,|Moghal, Nadeem|,|University Health Network, Toronto, Canada|
|2973|,|Mogler, Mark|,|Harrisvaccines Inc, Ames, IA|
|FC|,|Mohler, William|,|University of Connecticut, Farmington, CT|
| 607|,|Mohsen, Walid|,|Mayo Clinic, Rochester, MN|
|3724|,|Moir, Robert|,|Harvard Medical School, Charlestown, MA|
|MN|,|Mole, Sara|,|University College London, London, England|
| 958|,|Molin, Laurent|,|Centre Leon Berard, INSERM, Lyon, France|
|3314|,|Mollinedo, Faustino|,|CSIC-Universidad de Salamanca, Salamanca, Spain|
| 858|,|Molnar, Attila|,|Agricultural Biotechnology Center, Godollo, Hungary|
|3411|,|Moloney, Aileen|,|University of Oxford, Oxford, UK|
|3140|,|Moloney, Daniel|,|Stony Brook University, Stony Brook, NY|
|3495|,|Monahan, Kim|,|North Carolina School of Science & Mathematics, Durham, NC|
|3167|,|Mondoux, Michelle|,|College of the Holy Cross, Worcester, MA|
|3753|,|Monen, Joost|,|Ramapo College of New Jersey, Mahwah, NJ|
| 362|,|Mongan, Nigel|,|The Babraham Institute, Cambridge, England|
| 170|,|Monsanto Company|,|Chesterfield, MO|
|1498|,|Monteiro, Mervyn|,|University of Maryland, Baltimore, MD|
|4093|,|Montero, Mayte|,|Universidad Valladolid, Valladolid, Spain|
|2834|,|Montgomery, David|,|University of Hawaii, Hilo, HI|
| 611|,|Montgomery, Mary|,|Macalaster College, St. Paul, MN|
|TAM|,|Montgomery, Taiowa|,|Colorado State University, Fort Collins, CO|
|2515|,|Moon, Randall|,|University of Washington School of Medicine, Seattle, WA|
|4139|,|Moon, Tae Seok|,|Washington University, St. Louis, MO|
|3617|,|Moon, Yuseok|,|Pusan National University, Yangsan, South Korea|
|IL|,|Moore, Landon|,|Oklahoma Christian University, Edmond, OK|
|1398|,|Moore, Steve|,|Harding University, Searcy, AR|
|1530|,|Moore, Susan|,|Shippensburg University, Shippensburg, PA|
|3819|,|Moorefield, Emily|,|Johnson C. Smith University, Charlotte, NC|
|1812|,|Moran, Mike|,|Mt. Sinai Hospital Research Institute, Toronto, Ontario|
|1950|,|Moran, Nancy|,|University of Arizona, Tucson, AZ|
|3447|,|Morck, Catarina|,|Goteborg University, Goteborg, Sweden|
|1044|,|Morcos, Michael|,|University of Heidelberg, Heidelberg, Germany|
|2002|,|Moreillon, Philippe|,|University of Lausanne, Lausanne, Switzerland|
|2332|,|Morel, Fabrice|,|Universite de Rennes 1, Rennes, France|
|4330|,|Moreno, Elizabeth|,|UGN-UNAM, Mexico City, Mexico|
|2142|,|Moreno, Sara|,|Instituto Nac'l de Invest y Tecn Agraria y Alim, Madrid, Spain|
|1964|,|Moreno, Sergio|,|Campus Miguel de Unamuno, Salamanca, Spain|
|3178|,|Moretto, Phillippe|,|Université Bordeaux, Gradignan, France|
|AMG|,|Morgan, Alan|,|University of Liverpool, Liverpool, U.K.|
|WR|,|Morgan, Bill|,|College of Wooster, Wooster, OH|
|DOM|,|Morgan, Dave|,|Department of Physiology, UCSF, San Francisco, CA|
|3533|,|Morgan, Lucille|,|Walter Reed Army Institute of Research, Silver Spring, MD|
|CW|,|Morgan, Phil|,|Case Western Reserve University, Cleveland OH|
|IK|,|Mori, Ikue|,|Nagoya University, Nagoya, Japan|
|MAM|,|Mori, Marcelo|,|Federal University of Sao Paulo, Sao Paolo, Brazil|
| 499|,|Morimitsu, Toshiharu|,|Nara Inst of Science & Technology, Nara, Japan|
|AM|,|Morimoto, Richard|,|Northwestern University, Evanston, IL|
|LTM|,|Morran, Levi|,|Emory University, Atlanta,  GA|
|1696|,|Morris, Gail|,|University of Tennessee-Battelle, Oak Ridge, TN|
|2013|,|Morrison, Michal|,|University of Puget Sound, Tacoma, WA|
|3899|,|Mortazavi, Ali|,|University of California, Irvine, CA|
| 776|,|Morton, David|,|Oregon Health Sciences University, Portland, OR|
| 564|,|Morville, Nancy|,|Florida Southern College, Lakeland, FL|
|ME|,|Moss, Eric|,|Rowan University, Stratford, NJ|
|1927|,|Moss, Robert|,|Wofford College, Spartanburg, SC|
|3817|,|Mossialos, Dimitris|,|University of Thessaly, Larissa, Greece|
| 637|,|Mota, Manuel|,|Universidade de Evora, Portugal|
|MOT|,|Motegi, Fumio|,|Temasek Lifesciences Lab, National Univ of Singapore, Singapore|
|3509|,|Motilva, Virginia|,|University of Seville, Seville, Spain|
|1205|,|Mounsey, Andy|,|Murdoch University, Murdoch, WA, Australia|
|2168|,|Mousley, Angela|,|Queen's University Belfast, Belfast, Ireland, UK|
|2201|,|Mousseau, Timothy|,|University of South Carolina, Columbia, SC|
|3392|,|Moylan, Jennifer|,|University of Kentucky, Lexington, KY|
|3150|,|Mpoloka, Sununguko|,|University of Botswana, Gaborone, Botswana|
| 434|,|Mr. Seymour|,||
|4201|,|Mueller, Henry|,|Graz University of Technology, Graz, Austria|
| 629|,|Mueller, Melinda|,|Seattle Academy, Seattle, WA|
| 861|,|Mueller-Reichert, Thomas|,|Electron Microscope Lab, Univ of California, Berkeley, CA|
|3173|,|Mueller-Reichert, Thomas|,|TU Dresden, Dresden, Germany|
|2929|,|Mukadam, Samee|,|Institute of Chemical Technology, Mumbai, India|
|2694|,|Mukhopadhyay, Arnab|,|National Institute of Immunology, New Delhi, India|
|2643|,|Mukku, Venugopal|,|University of Minnesota, Crookston, MN|
|FR|,|Muller, Fritz|,|University of Fribourg, Switzerland|
|1407|,|Mullican, John|,|Washburn University, Topeka, KS|
| 417|,|Mulligan, Evan|,|University of Massachusetts, Boston, MA|
|XA|,|Multiple users|,|CGC, Sanger Institute, Cambridge, England|
|3867|,|Munasinghe, D. H. H.|,|University of Sri Jayewardenepura, Nugegoda, Sri Lanka|
|2321|,|Mundy, John|,|Copenhagen University, Copenhagen, Denmark|
|GM|,|Munoz, Manuel|,|Universidad Pablo de Olavide, Sevilla, Spain|
|1186|,|Munro, Ed|,|University of Chicago, Chicago, IL|
|SN|,|Murakami, Shin|,|Touro University, Vallejo, CA|
|3934|,|Murata, Shigeo|,|University of Tokyo, Tokyo, Japan|
|1821|,|Murayama, Takashi|,|Okinawa Institute of Science and Technology, Uruma, Okinawa, Japan|
|1818|,|Murch-Shafer, Karen|,|Dana College, Blaire, NE|
|CQ|,|Murphy, Coleen|,|Princeton University, Princeton, NJ|
|JIM|,|Murray, John|,|University of Pennsylvania, Philadelphia, PA|
|1065|,|Murthy, Venkatesh|,|Cambridge, MA|
|3659|,|My, Xia|,|Shenyang Pharmaceutical University, Shenyang, China|
|EMM|,|Myers, Edith|,|Fairleigh Dickinson University, Madison, NJ|
|3256|,|Myers, Eugene|,|HHMI-Janelia Farm Research Campus, Ashburn, VA|
|3433|,|Myers, Richard|,|Boston University School of Medicine, Boston, MA|
|3832|,|Mylavarapu, Sivaram|,|Regional Centre for Biotechnology, Gurgaon Haryana, India|
|1403|,|Myles, E. Lewis|,|Tennessee State University, Nashville, TN|
|1586|,|Mylonakis, Eleftherios|,|Rhode Island Hospital, Providence, RI|
|3528|,|Ménez, Cécile|,|INRA ToxAlim, Toulouse, France|
|2789|,|NASA Ames Research Center|,|NASA Ames Research Center, Moffett Field, CA|
|2814|,|NEW USER|,|University of Copenhagen, Denmark|
|4188|,|NEW USER|,|Key Laboratory of Food Science and Biotechnology, Changsha, China|
|SCB|,|NEW USER|,|University of Bergen, Bergen, Norway|
|4366|,|NEW USER|,||
|4367|,|NEW USER|,||
|4368|,|NEW USER|,||
|4369|,|NEW USER|,||
|4370|,|NEW USER|,||
|4371|,|NEW USER|,||
|4372|,|NEW USER|,||
|4373|,|NEW USER|,||
|4374|,|NEW USER|,||
|4375|,|NEW USER|,||
|4376|,|NEW USER|,||
|4377|,|NEW USER|,||
|4378|,|NEW USER|,||
|4379|,|NEW USER|,||
|4380|,|NEW USER|,||
|4381|,|NEW USER|,||
|4384|,|NEW USER|,||
|4385|,|NEW USER|,||
|4386|,|NEW USER|,||
|4387|,|NEW USER|,||
|4388|,|NEW USER|,||
|4389|,|NEW USER|,||
|4390|,|NEW USER|,||
|4391|,|NEW USER|,||
|4392|,|NEW USER|,||
|4393|,|NEW USER|,||
|4394|,|NEW USER|,||
|4395|,|NEW USER|,||
|4396|,|NEW USER|,||
|4397|,|NEW USER|,||
|4398|,|NEW USER|,||
|4399|,|NEW USER|,||
|3852|,|Na, Hyo-Seok|,|Seoul National University, Seongnam. Gyeonggi, South Korea|
|NAA|,|Naar, Anders|,|Massachusetts General Hospital, Charlestown, MA|
|JQ|,|Nabeshima, Kentaro|,|University of Michigan, Ann Arbor, MI|
|2936|,|Nader, Helena Bonciani|,|Federal University of Sao Paulo, Brazil|
|3741|,|Nadiga, Mohan|,|Syngene International Ltd., Bangalore, India|
|SAN|,|Nadler, Steve|,|University of California, Davis, CA|
|3183|,|Nagal, Jenica|,|Univ of the Philippines Baguio, Baguio City, Benguet, Philippines|
|2091|,|Nagamatsu, Shinya|,|Kyorin University, Kyorin, Japan|
|1220|,|Nagata, Kazuhiro|,|Kyoto Sangyo University, Kyoto, Japan|
| 683|,|Nagata, Kyosuke|,|Tokyo Institute of Technology, Yokohama, Japan|
|3640|,|Nagata, T|,|Genomic Science Laboratories, Dainippon Sumitomo Pharma, Osaka, Japan|
|1711|,|Nah, Seung-Yeol|,|Konkok University, Seoul, Korea|
|1327|,|Nair, Sean|,|University College London, London, England|
|4348|,|Nakadera, Yasuhito|,|Toray Indsusties Inc., Tokyo, Japan|
| 587|,|Nakagawa, Terunaga|,|University of Tokyo, Japan|
|2212|,|Nakai, Masato|,|Osaka University, Suita, Japan|
|1109|,|Nakamura, Nobuya|,|Kyoto University, Kyoto, Japan|
|2432|,|Nakane, Akio|,|Hirosaki University, Aomori, Japan|
|NAM|,|Nam, Hong Gil|,|Daegu Gyeongbuk Inst of Science & Tech, Daegu, South Korea|
|FT|,|Nance, Jeremy|,|Skirball Institute, New York, NY|
|2920|,|Nanjundan, Meera|,|University of South Florida, Tampa, FL|
|2364|,|Narayanan, Ramesh|,|GTx, Inc., Memphis, TN|
|1495|,|Nascarella, Marc|,|Texas Tech University, Lubbock, TX|
|2412|,|Nascimento, Gisela|,|CIRN, Universidade dos Acores, Ponta Delgada, Portugal|
|1965|,|Nash, Bruce|,|Dolan DNA Learning Center, Cold Spring Harbor, NY|
|RJ|,|Nass, Richard|,|Indiana University, Indianapolis, IN|
|3800|,|Nath, Kim|,|Duquesne University, Pittsburgh, PA|
|3481|,|Nathan, Sheila|,|Universiti Kebangsaan Malaysia, Bangi, Malaysia|
|4321|,|Natori, Takamitsu|,|Yamanashi-Gakuin University, Kofu, Japan|
| 973|,|Natsuka, Shunji|,|Kyoto Institute of Technology, Kyoto, Japan|
| 836|,|Natural Remedies Private Limited|,|Bangalore, India|
|2437|,|Naumann, Muhammad|,|Government College University, Lahore, Pakistan|
|2796|,|Navarro, Ana Canuelo|,|University of Jaén, Spain|
|RN|,|Navarro, Rosa|,|UNAM, Mexico City, Mexico|
| 808|,|Navas, Alfonso|,|Museo Nacional de Ciencias Naturales, Madrid, Spain|
|PN|,|Navas, Placido|,|Universidad Pablo de Olavide, Seville, Spain|
|UK|,|Nawrocki, Leon|,|University College, London, England|
|SNK|,|Nayak, Sudhir|,|College of New Jersey, Ewing, NJ|
|2547|,|Nazir, Aamir|,|Central Drug Research Institute, Lucknow, India|
|DJN|,|Needleman, Daniel|,|Harvard University, Cambridge, MA|
|3864|,|Neela, Vasanthakumari|,|Universiti Putra Malaysia, Serdang, Malaysia|
| 997|,|Nef, Patrick|,|Hoffmann-La Roche, Basel, Switzerland|
| 899|,|Nefsky, Brad|,|University of Medicine and Dentistry of New Jersy, Piscataway, NJ|
|4236|,|Negi, Hema|,|CSIR-CIMAP, Lucknow, India|
|KWN|,|Nehrke, Keith|,|University of Rochester, Rochester, NY|
|2519|,|Neiker-Tecnalia Institute|,|Vitoria-Gasteiz, Spain|
|1743|,|Neira, Marco|,|University of Florida, St. Augustine, FL|
|3355|,|Neitzel, Jim|,|The Evergreen State College, Olympia, WA|
|3153|,|Nelms, Brian|,|Fisk University, Nashville, TN|
|JP|,|Nelson, Greg|,|Jet Propulsion Laboratory, Pasadena, CA|
|SJU|,|Nelson, Matthew D|,|Saint Joseph's University, PA|
|4199|,|Nelson, Ted|,|Georgetown University, Washington, DC|
|2128|,|NemaRx Pharmaceuticals, Inc.|,|Calgary, Alberta, Canada|
|ID|,|Neri, Christian|,|Centre Paul Broca, INSERM, Paris, France|
|2944|,|Nes, Ingolf|,|Norwegian University of Life Science, Aas, Norway|
|1399|,|Neufeld, Doug|,|Eastern Mennonite University, Harrisonburg, VA|
|BXN|,|Neumann, Brent|,|Monash University, Clayton, Victoria, Australia|
|3689|,|Neves, Nuno|,|New University of Lisbon, Lisbon, Portugal|
| 832|,|Nevid, Nick|,|Maritech, Inc, Vero Beach, FL|
|1895|,|New England Biolabs, Inc.|,|Ipswich, MA|
|3656|,|Newberry, Rodney|,|Washington University, St. Louis, MO|
|AN|,|Newman, Anna|,|Baylor College of Medicine, Houston, TX|
|3821|,|Newman, Dianne|,|California Institute of Technology, Pasadena, CA|
|3002|,|Newman, Michael|,|Vaxiion Therapeutics Inc., San Diego, CA|
|3987|,|Newton, Joe|,|Auburn University College of Vet Medicine, Auburn, AL|
| 759|,|Newton, Maria|,|Universidade de Coimbra, Coimbra, Portugal|
|3904|,|Ngsee, John|,|University of Ottawa, Ottawa, Canada|
| 662|,|Nguyen, Khuong|,|University of Florida, Gainesville, FL|
|3393|,|Nian, Xiong|,|Huazhong University of Science and Technology, Wuhan, Hubei, China|
|1080|,|Nic an Ultaigh, Sinead|,|University College, Dublin, Ireland, UK|
|HRN|,|Nicholas, Hannah|,|University of Sydney, Sydney, NSW, Australia|
|4278|,|Nichols, Scott|,|University of Denver, Denver, CO|
|2221|,|Nickel, Michael|,|Friedrich-Schiller-Universitaet, Jena, Germany|
|1232|,|Nickell, Tom|,|University of Cincinnati College of Medicine, Cincinnati, OH|
|2701|,|Nickerson, Cheryl|,|Arizona State University, Tempe, Arizona|
|3422|,|Nicolson, Teresa|,|Oregon Health & Science University, Portland, OR|
|2616|,|Nie, Guangjun|,|Key Laboratory  Beijing, China|
|3491|,|Niedziela, Linda|,|Elon University, Elon, NC|
|1946|,|Nieto-Fernandez, Fernando|,|SUNY College at Old Westbury, Old Westbury, NY|
| 886|,|Nigg Lab|,|MPI for Biochemistry, Martinsried, Germany|
|4132|,|Nightingale, Kendra|,|Texas Tech University, Lubbock, TX|
|3255|,|Niklason, Laura & Xu, Xiangru|,|Yale University School of Medicine, New Haven, CT|
|2023|,|Nilsen, Hilde|,|University of Oslo, Oslo, Norway|
|2204|,|Nilsson, Annika|,|Swedish University of Agricultural Sciences, Uppsala, Sweden|
|1505|,|Nippon Soda Co.|,|Kanagawa, Japan|
|NIS|,|Nishida, Eisuke|,|Kyoto University, Kyoto, Japan|
|1477|,|Nishikawa, Yoshikazu|,|Osaka City University, Osaka, Japan|
|HTN|,|Nishimura, Hitoshi|,|Setsunan University, Osaka, Japan|
|NF|,|Nishiwaki, Kyoji|,|Kwansei Gakuin University, Sanda, Japan|
| 933|,|Nissan Chemical Industries, Ltd|,|Saitama, Japan|
|1874|,|Nita-Farm|,|Saratov, Russia|
|MNN|,|Nitabach, Michael|,|Yale School of Medicine, New Haven, CT|
|1389|,|Niu, YanBing|,|Shanxi Agriculture University, Taigu, China|
|RSN|,|Niwa, Ryusuke|,|University of Tsukuba, Tsukuba, Japan|
|OTL|,|Niwa, Shinsuke|,|Tohoku University, Sendai, Japan|
| 382|,|Njoku, Chinedu|,|University of Nigeria, Nsukka, Nigeria|
|1129|,|Noack Lab. fur Angewandte Biol|,|Starstedt, Germany|
|4274|,|Noble, Talllie|,|MiraCosta College, Oceanside, CA|
|4172|,|Noda, Naomi|,|Life Science Laboratry Co. Ltd., Nerima, Tokyo, Japan|
|1803|,|Nofziger, Donna|,|Pepperdine University, Malibu, CA|
|1385|,|Noji, Sumihare|,|University of Tokushima, Tokushima City, Japan|
|3171|,|Nojima, Aika|,|Chiba University, Chuo-ku, Chiba, Japan|
|3349|,|Nolan, Kathleen|,|St. Francis College, Brooklyn, NY|
|OW|,|Nollen, Ellen|,|University of Groningen, Groningen, The Netherlands|
|GSX|,|Nomura, Kazuya|,|Kyushu University, Fukuoka, Japan|
|NM|,|Nonet, Mike|,|Washington University, St. Louis, MO|
|1183|,|Noralta Environmental Services|,|Edmonton, AB, Canada|
|3949|,|Norbeck, Lauri|,|Franklin and Marshall College, Lancaster, PA|
|1804|,|Norflus, Fran|,|Clayton State University, Morrow, GA|
|KRN|,|Norman, Kenneth|,|Albany Medical College, Albany, NY|
|3976|,|Norman, R Sean|,|University of South Carolina, Columbia, SC|
|1806|,|Norris, Andy|,|Lander University, Greenwood, SC|
| 726|,|Norris, Frank A.|,|Iowa State University, Ames, IA|
|3607|,|Nosjean, Olivier|,|Institut de Recherches Servier, Paris, France|
| 718|,|Novartis Inc.|,|Research Triangle Park, NC|
|1323|,|Novartis Research Foundation, Genomics Institute|,|San Diego, CA|
| 246|,|Novitski, Charles|,|Central Michigan University, Mt. Pleasant, MI  48859|
|3058|,|Nowicki, Julie|,|Biotechnology High School, Freehold, NJ|
| 849|,|Nozaki, Tetsuji|,|Center for Bioengineering, Univ of Washington, Seattle, WA|
|1098|,|Nukina, Nobuyuki|,|RIKEN-Brain Science Institute, Saitama, Japan|
|QT|,|Nurrish, Stephen|,|University College of London, London, England|
| 484|,|Nuttley, WM|,|University of Toronto, Ontario, Canada|
|2540|,|Nydegger, Jason|,|Keystone School, San Antonio, TX|
| 766|,|O'Brien, Thomas|,|University of Florida, Gainesville, FL|
|OC|,|O'Connell, Kevin|,|NIDDK/NIH, Bethesda, MD|
|1634|,|O'Connor, Willy|,|Institute of Technology, Carlow, Ireland, UK|
|3746|,|O'Donnell, Christopher|,|Jackson Laboratory, Bar Harbor, ME|
|TOL*|,|O'Donovan, Michael|,|NIH/NINDS, Bethesda, MD|
|1810|,|O'Gara, Bruce|,|Humboldt State University, Arcata, CA|
|DMH|,|O'Halloran, Damien|,|George Washington University, Washington, DC|
|1287|,|O'Leary, Fidelma|,|St. Edward's University, Austin, TX|
|1935|,|O'Malley, Kieran|,|University of the West of England, Bristol, England|
|1365|,|O'Neill, Erin|,|University of Newcastle, Callaghan, NSW, Australia|
|GMW|,|O'Rourke, Eyleen J|,|University of Virginia, Charlottesville, VA|
| 596|,|O'Shea, Michael|,|University of Sussex, Brighton, England|
| 506|,|Oates, Andy|,|Ludwig Institute for Cancer Research, Royal Melbourne Hospital, Victoria, A|
|2310|,|Obermann, Wolfgang|,|University of Texas Medical Branch, Galveston, TX|
|2759|,|Oberto, Paul|,|Hotchkiss School, Lakeville, CT|
|1584|,|Odani, Shoji|,|Niigata University, Niigata City, Japan|
| 816|,|Oeda, Tomoko|,|Kyoto University, Kyoto, Japan|
|OD|,|Oegema, Karen & Desai, Arshad|,|University of California, San Diego, CA|
|2026|,|Oegema, Theodore|,|Rush University, Chicago, IL|
|3514|,|Oehlmann, Jorg|,|Goethe University Frankfurt, Frankfurt, Germany|
|3424|,|Oelkers, Peter|,|University of Michigan, Dearborn, MI|
|3043|,|Ogawa, Takahiro|,|Wakunaga Pharmaceuticals Co, Akitakata-city, Japan|
|3808|,|Ogungbe, Ifedayo Victor|,|Jackson State University, Jackson, MS|
|3229|,|Ogura, Shun-ichiro|,|Tokyo Institute of Technology, Tokyo, Japan|
|1837|,|Ogura, Teru|,|Kumamoto University, Kumamoto, Japan|
|TOG|,|Ogurusu, Taro|,|Iwate University, Morioka, Iwate, Japan|
|4124|,|Oh, Won Keun|,|Seoul National University, Seoul, South Korea|
|1479|,|Ohashi-Kobayashi, Ayako|,|Iwate Medical University, Iwate, Japan|
|1410|,|Ohkuma, Shuji|,|Kanazawa University, Kanazawa, Japan|
| 897|,|Ohno, Shigeo|,|Yokohama City University School of Medicine, Yokohama, Japan|
|FK|,|Ohshima, Yasumi|,|Sojo University, Ikeda, Kumamoto, Japan|
|2374|,|Ohtsuki, Takashi|,|Okayama University, Okayama, Japan|
| 996|,|Oka, Kotaro|,|Keio University, Yokohama, Japan|
|1468|,|Oka, Toshihiko|,|Kyushu University, Fukuoka, Japan|
|3680|,|Okada, Kazuhisa|,|Osaka University, Osaka, Japan|
|OV|,|Okada, Masato|,|Osaka University, Osaka, Japan|
|1628|,|Okada, Masato|,|National Institute for Agro-Environmental Sciences, Ibaraki, Japan|
| 691|,|Okaichi, Kumio|,|Nagasaki University School of Medicine, Nagasaki, Japan|
|OK|,|Okkema, Pete|,|University of Illinois, Chicago, IL|
|3376|,|Okoli, Ikechukwu|,|Nnamdi Azikiwe University, Awka, Anambra, Nigeria|
|2272|,|Okuda, Takashi|,|National Institute of Agrobiological Sciences, Ibaraki, Japan|
|3612|,|Okumura, Fumihiko|,|Nagoya University, Nagoya, Japan|
|3541|,|Olafson, Pia|,|USDA-ARS, Kerrville, TX|
|3905|,|Olaleye, Omonike|,|Texas Southern University, Houston ,TX|
|HF|,|Olesen, Soren-Peter|,|University of Copenhagen, Copenhagen, Denmark|
| 894|,|Olgun, Abdullah|,|Istanbul Kemerburgaz University, Istanbul, Turkey|
|2635|,|Oliveira, Riva|,|University of Ouro Preto (UFOP), Ouro Preto, Brazil|
|4113|,|Olivera, Leticia|,|Cinvestav-IPN, Merida, Mexico|
|3580|,|Olivero-Verbel, Jesus|,|University of Cartagena, Cartagena, Colombia|
|3989|,|Olivier, Paul|,|Trillium Ag, Seattle, WA|
| 667|,|Oliw, Ernst|,|Uppsala Biomedical Center, Uppsala, Sweden|
|BOL|,|Olofsson, Birgitta|,|University of Cambridge, Cambridge, UK|
|OLS|,|Olsen, Anders|,|University of Aarhus, Aarhus, Denmark|
|3297|,|Olsen, Carissa|,|Fred Hutchinson Cancer Research Center, Seattle, WA|
| 720|,|Olson, Eric|,|UT Southwestern Medical Center, Dallas, TX|
|1339|,|Olson, Lisa|,|University of Redlands, Redlands, CA|
|3966|,|Olson, Rachel|,|University of Minnesota, Rochester, MN|
|POM|,|Olson, Sara|,|Pomona College, Claremont CA|
|3506|,|Omatsu, Masato|,|Ishihara Sangyo Kaisya, LTD., Shiga, Japan|
|ONA|,|Onami, Shuichi|,|RIKEN Advanced Sciences Institute, Kobe, Japan|
|2084|,|Oncotarget, Inc.|,|Albany, NY|
|ON|,|Ono, Shoichiro|,|Emory University, Atlanta, GA|
|2600|,|Onstine, Alison|,|Georgia Institute of Technology, Atlanta, GA|
|1299|,|Onuki, Reiko|,|University of Tokyo, Tokyo, Japan|
|3768|,|Ortega Oliva, Sandra Angelica|,|CINVESTAV del Instituto Politécnico Nacional, Mexico City, Mexico|
|2754|,|Ortega, Daniel|,|Unidad de Genetica de la Nutricion, Mexico|
|2170|,|Ortmann, Robert|,|University of Missouri, Columbia, MO|
|2088|,|Osgood, Christopher|,|Old Dominion University, Norfolk, VA|
|1051|,|Oshiumi, Hiroyuki|,|Osaka Medical Center for Cancer & Cardiovascular Diseases, Osaka, Japan|
|3332|,|Osovitz, Michelle|,|St. Petersburg College, St. Petersburg, FL|
|1302|,|Ostrow, Bruce|,|Grand Valley State University, Allendale, MI|
|DD|,|Otsuka, Tony|,|University of Hawaii, Hilo, HI|
|3407|,|Otto-Hitt, Stefanie|,|Carroll College, Helena, MT|
|OCY|,|Ou, Chan-Yen|,|Institute of Biochemistry and Molecular Biology, Taipei, Taiwan|
|GOU|,|Ou, Guangshuo|,|Tsinghua University, Beijing, China|
|3957|,|Ouano, Nelly Nonette M|,|University of San Carlos-Talamban Campus, Cebu City, Philippines|
|3170|,|Overholtzer, Michael|,|Memorial Sloan-Kettering Cancer Center, New York, NY|
|2831|,|Oviedo, Nestor|,|University of California, Merced, CA|
|1650|,|Owen, Patrick|,|Ohio State University, Lima, OH|
| 938|,|Ownby, David|,|Virginia Institute of Marine Science, Gloucester Point, VA|
|4144|,|Ozpinar, Necati|,|Cumhuriyet University, Sivas, Turkey|
|2340|,|P & G|,|Cincinnati, OH|
|QF|,|Paaby, Annalise|,|Georgia Institute of Technology, Atlanta, GA|
|3154|,|Paatero, Ilkka|,|University of Turku, Finland|
|LT|,|Padgett, Rick|,|Waksman Institute, Piscataway, NJ|
|PM|,|Padilla, Pamela|,|University of North Texas, Denton, TX|
|3474|,|Padmanabhan, Venkat|,|Indian Institute of Technology, West Bengal, India|
|1502|,|Padron-Perez, David|,|University of Texas Southwestern Medical Center, Dallas, TX|
|2997|,|Page, David|,|Whitehead Institute, Cambridge, MA|
|1587|,|Page, Kristen|,|Wheaton College, Wheaton, IL|
|4026|,|Page, Shallee|,|University of Maine, Machias, ME|
|TP|,|Page, Tony|,|University of Glasgow, Glasgow, Scotland|
|YP|,|Paik, Young-Ki|,|Yonsei University, Seoul, Korea|
|1481|,|Paillard, Luc|,|Universite de Rennes, Rennes Cedex, France|
|3129|,|Palacios, Jose Luis|,|Universidad de Santiago de Chile, Santiago, Chile|
|SMS|,|Palanisamy, Sundararaj|,|Bharathiar University, Coimbatore, India|
|FP|,|Palau, Francesc|,|Hospital Universitari La Fe, Valencia, Spain|
|PFR|,|Palladino, Francesca|,|Ecole Normale Superieure de Lyon, Lyon, France|
|2525|,|Palladino, Michael|,|University of Pittsburgh, Pittsburgh, PA|
|1687|,|Palleschi, Claudio|,|University of Rome, La Sapienza, Italy|
| 867|,|Palmitessa, Aimee|,|Thomas Jefferson University, Philadelphia, PA|
| 630|,|Palopoli, Mike|,|Bowdoin College, Brunswick, ME|
|BOP|,|Palsson, Bernhard|,|University of California, San Diego, CA|
|3806|,|Paluch, Elisabeth|,|University of Wisconsin, La Crosse, WI|
|CLP|,|Pan, Chun-Liang|,|National Taiwan University School of Medicine, Taiwan|
|3622|,|Pan, Duojia|,|Johns Hopkins University, Baltimore, MD|
|3923|,|Pan, Irvin|,|Stonehill College, Easton, MA|
|2649|,|Pan, Junmin|,|Tsinghua University, Beijing, China|
|2521|,|Pan, Shen|,|National University of Singapore, Singapore|
|3435|,|Pan, Xiaoping|,|East Carolina University, Greenville, NC|
|3912|,|Pan-Montojo, Francisco|,|Klinikum der Universitat Munchen, Germany|
| 820|,|Pandey, Akhilesh|,|Johns Hopkins University, Baltimore, MD|
|4006|,|Pandey, Amita|,|University of Delhi, New Delhi, India|
|1146|,|Pandey, Rakesh|,|CSIR-CIMAP, Lucknow, India|
|3138|,|Pandey, Santosh|,|Iowa State University, Ames, IA|
|2007|,|Pandian, Karutha|,|Alagappa University, Tamil Nadu, India|
|SSP|,|Pang, Shanshan|,|Chongqing University, Chongqing, China|
|1573|,|Papakonstantinopoulou, Anastasia|,|Queen Mary School of Medicine & Dentistry, London, England|
|1235|,|Pareek, Puneet|,|National Institute of Mental Health and Neurosciences, Bangalore, India|
|2222|,|Park, Byung-Jae|,|Hallym University, Gangwondo, South Korea|
|2667|,|Park, Chan Kyu|,|KAIST, Daejeon, South Korea|
|3350|,|Park, Houng|,|Gordon College, Barnesville, GA|
|3010|,|Park, Hyun|,|Wonkwang University School of Medicine, Iksan, South Korea|
|1540|,|Park, Ilwoon|,|University of Seoul, Seoul, Korea|
|MYP|,|Park, Mikyoung|,|Korea Inst of Science & Tech, Seoul, South Korea|
|1844|,|Park, Sang-Hyun|,|Seoul National University, Seoul, Korea|
|3477|,|Park, Sang-Kyu|,|Soonchunhyang University, Asan Chungnam, South Korea|
|3418|,|Park, Sunghyouk|,|Seoul National University, Seoul, South Korea|
|2420|,|Park, Sunsu|,|Ewha Womens University, Seoul, South Korea|
|3853|,|Park, Yeonhwa|,|University of Massachusetts, Amherst, MA|
|XQ|,|Parker, Alex|,|University of Montreal, Montreal, Quebec, Canada|
|1452|,|Parks, David|,|University of Ottawa, Ottawa, Ontario, Canada|
|ARP|,|Parodi, Armando|,|Fundacion Instituto Leloir, Buenos Aires, Argentina|
|VPR|,|Parpura, Vladimir|,|University of Alabama, Birmingham, AL|
|GCU|,|Parry, Jean Michele|,|Georgian Court University, Lakewood, NJ|
|3758|,|Parsons, Kirsten|,|SUNY Oswego, Oswego, NY|
| 670|,|Parsons, Ramon|,|Columbia University, New York, NY|
|PQ|,|Pasquinelli, Amy|,|University of California, San Diego, CA|
|2695|,|Pastok, Martyna|,|University of Liverpool, Liverpool, UK|
|1233|,|Patapoutian|,|Scripps Research Institute, La Jolla, CA|
| 554|,|Patel,|,|University of Chicago, Chicago, IL|
|2922|,|Patel, Anuradha|,|Smt BNB Swaminarayan Pharmacy College, Gujarat, India|
|3166|,|Patel, Hemal & Roth, David|,|University of California, San Diego, CA|
|MRP|,|Patel, Maulik|,|Vanderbilt University, Nashville, TN|
| 935|,|Patel, Mavji|,|Ohio State University, Wooster, OH|
|1401|,|Patel, Nipam|,|University of California, Berkeley, CA|
|4152|,|Patel, Rekha|,|University of South Carolina, Columbia, SC|
|3714|,|Pati, Uttam|,|Jawaharlal Nehru University, New Delhi, India|
|3610|,|Patrauchan, Marianna|,|Oklahoma State Univerity, Stillwater, OK|
|1816|,|Patrick, Hannah|,|University of Nottingham, Nottingham, UK|
|GP|,|Patterson, Garth|,|Rutgers University, Piscataway, NJ|
|2371|,|Patterson, Parrin|,|LSU Health Sciences Center, Baton Rouge, LA|
|1309|,|Patton, Jeff|,|University of South Carolina, Columbia, SC|
|3638|,|Pauchet, Yannick|,|Max Plank Institute for Chemical Ecology, Jena, Germany|
|1899|,|Paul, Praveen|,|King's College, London, England, UK|
|PRJ|,|Paul, Rudiger|,|Westfalische Wilhelms-Universitat Munster, Muenster, Germany|
| 634|,|Paulmichl, Marcus|,|University of Innsbruck, Austria|
|2974|,|Paulson, Henry|,|University of Michigan, Ann Arbor, MI|
|3236|,|Pause, Arnim|,|McGill University, Montreal, Quebec, Canada|
|2959|,|Pavlovic, Hrvoje|,|Faculty of Food Technology, Osijek, Croatia|
|3641|,|Pawar, Vijay|,|Unversity College London, London, UK|
| 877|,|Pawson, Tony|,|Samuel Lunenfeld Research Institute, Toronto, Ontario, Canada|
|3780|,|Payne, Shelley|,|University of Texas, Austin, TX|
| 697|,|Payvar, Farhang|,|Vanderbilt University, Nashville, TN|
|3784|,|Pazdro, Rob|,|University of Georgia, Athens, GA|
|1463|,|Peck, Melicent|,|Stanford University, Palo Alto, CA|
|JEP|,|Pecreaux, Jacques|,|IGDR, Rennes, France|
|1757|,|Pedra, Renan|,|University of Toronto, Toronto, Ontario, Canada|
| 346|,|Peebles, Patsye|,|LSU University Lab School, Baton Rouge, LA|
|NIN|,|Peel, Nina|,|The College of New Jersey, Ewing NJ|
|3831|,|Peeler, Margaret|,|Susquehanna University, Selinsgrove, PA|
| 291|,|Peixoto, Christina Alves|,|Universidade Federal Do Rio de Janeiro, Brasil|
|4240|,|Peixoto, Nathalia|,|George Mason University, Fairfax, VA|
|FGP|,|Pelisch, Federico & Hay, Ronald|,|University of Dundee, Dundee, UK|
| 735|,|Pelliccia, Joseph|,|Bates College, Lewiston, ME|
|2828|,|Pelzer, Lindsay|,|Phenomenome Discoveries Inc., Saskatoon, SK, Canada|
|1328|,|Pendergast, Ann Marie|,|Duke University, Durham, NC|
|1036|,|Penders, Jana|,|University of Rochester, Rochester, NY|
|2737|,|Peng, Har Hui|,|Hwa Chong Institution Science Research Centre, Singapore|
|2376|,|Peng, Hua-zheng|,|Zhejiang Forestry Academy, Zhejiang, China|
|3013|,|Peng, Xuanxian|,|University of Washington, Seattle, WA|
|4167|,|Peng, Zhenghua|,|CAS, Shandong University, Jinan, China|
|1388|,|Penninger, Josef|,|University of Vienna, Vienna, Austria|
|2330|,|Pentz, Lundy|,|Mary Baldwin College, Staunton, VA|
|1826|,|Pepe, Alicia|,|Center for Arts and Sciences, Denver, CO|
|2344|,|Perera, Anya|,|Writtle College, Chelmsford, UK|
|JPM|,|Perez-Martin, Jose|,|Instituto de Biologia Funcional y Genomica CSIC, Salamanca, Spain|
|3186|,|Periyanayagan, K|,|Madurai Medical College, Madurai, India|
|4138|,|Periyannan, Gopal|,|Eastern Illinois University, Charleston, IL|
| 707|,|Perkins, Ed|,|Waterways Experiment Station, Vicksburg, MS|
|2801|,|Perrine, Richard|,|Parish Episcopal School, Dallas, TX|
|NT|,|Perry, Marc|,|University of Toronto, Ontario, Canada|
|NE|,|Pertel, Ruth|,|FDA, Washington, D.C.|
|3644|,|Pestka, James|,|Michigan State University, East Lansing, MI|
|1307|,|Pestov, Nikolay|,|Russian Academy of Sciences, Moscow, Russia|
| 835|,|Petalcorin, Mark|,|King's College of London, London, England|
|1188|,|Peter, Matthias|,|University of Zurich, Zurich, Switzerland|
|EJP|,|Peterman, E.J.G.|,|VU University Amsterdam, Amsterdam, The Netherlands|
|1554|,|Peters, Andy|,|University of Wisconsin, Madison, WI|
|1592|,|Peters, Chris|,|Buena Vista University, Storm Lake, IA|
|1024|,|Peters, Lars|,|Universitat Bonn, Bonn, Germany|
|3611|,|Petersen, Elijah|,|National Institute of Standards and Technology, Gaithersburg, MD|
|1483|,|Petersen, Morten|,|Copenhagen University, Copenhagen, Denmark|
|2226|,|Petersen, Nancy Sue|,|University of Wyoming, Laramie, WY|
|2804|,|Peterson, Blake|,|Univ of Kansas, Lawrence, KS|
| 895|,|Peterson, Lynn|,|Carroll College, Waukesha, WI|
| 809|,|Petes, Tom|,|University of North Carolina, Chapel Hill, NC|
|VV|,|Petrascheck, Michael|,|Scripps Research Inst, La Jolla, CA|
|LNP|,|Petrella, Lisa|,|Marquette University, Milwaukee, WI|
|2111|,|Petrescu, Andrei-Jose|,|Romanian Academy, Bucharest, Romania|
| 959|,|Petri, William|,|University of Virginia, Charlottesville, VA|
|1662|,|Petriv, Oleh|,|Concordia University, Montreal, Quebec, Canada|
|LEN|,|Petrucelli, Leonard|,|Mayo Clinic, Jacksonville, FL|
|1940|,|Pettis, Gregg|,|Louisiana State University, Baton Rouge, LA|
|PE|,|Pettitt, Jonathan|,|University of Aberdeen, Aberdeen, Scotland|
|UGR|,|Pey, Angel|,|University of Grenada, Grenada, Spain|
|3614|,|Peyton, David|,|Morehead State University, Morehead, KY|
|2533|,|Pezzella, Mario|,|National Institute of Health & Safety at Work, Rome, Italy|
|1204|,|Pfeuty, A|,|CNRS-UMR, Paris, France|
| 479|,|Pfizer Limited|,|Sandwich, Kent, England|
|2246|,|Pfizer, Inc.|,|Groton, CT|
| 570|,|Pharmacia and Upjohn Company|,|Kalamazoo, MI|
|BTP|,|Phillips, Bryan|,|University of Iowa, Iowa City, IA|
| 340|,|Phillips, Carl|,|U.S. Army Edgewood Research, Aberdeen Proving Ground, MD|
|USC|,|Phillips, Carolyn|,|University of South California, Los Angeles, CA|
|1283|,|Phillips, Greg|,|Iowa State University, Ames, IA|
|PX|,|Phillips, Patrick|,|University of Oregon, Eugene, OR|
|1830|,|Physical Biosciences, Inc.|,|Andover, MA|
|PF|,|Piano, Fabio|,|New York University, New York, NY|
|2553|,|Picard, Frederic|,|University of Laval, Quebec City, Canada|
|4145|,|Picheth, Cyntia|,|Universidade Federal do Parana, Curitiba-Parana, Brazil|
|3737|,|Pickering-Brown, Stuart|,|University of Manchester, Manchester, UK|
|PVX|,|Pieczynski, Jay|,|Rollins College, Winter Park, FL|
|AJP|,|Piekny, Alisa|,|Concordia University, Montreal, Quebec, Canada|
|SBP|,|Pierce, Sarah|,|University of Washington, Seattle, WA|
|JPS|,|Pierce-Shimomura, Jon|,|University of Texas, Austin, TX|
| 235|,|Pierre, Abad|,|Institut National de la Recherche Agronomique, France|
|3615|,|Pieters, Luc|,|University of Antwerp, Antwerp, Belgium|
|3777|,|Pietrantonio, Patricia|,|Texas A&M University, College Station, TX|
|3562|,|Pihlajaniemi, Taina|,|University of Oulu, Oulu, Finland|
|DP|,|Pilgrim, Dave|,|University of Alberta, Edmonton, Canada|
| 274|,|Pilipenko, P.I.|,|Novosibirsk, USSR|
|QC|,|Pilon, Marc|,|Gveteborg University, Gveteborg, Sweden|
|ZPL|,|Pincus, Zachary|,|Washington University School of Medicine, St. Louis, MO|
|3247|,|Pineda, Victor|,|University of Washington, Seattle, WA|
|4120|,|Ping, Yang|,|Shanghai Research Center For Model Organisms, Shanghai, China|
|WLP|,|Pintard, Lionel|,|Paris-Diderot University, Paris, France|
|3574|,|Pio, Frederic|,|Simon Fraser University, Vancouver, Burnaby, BC|
|1992|,|Pioneer/Verdia|,|Redwood City, CA|
|APS|,|Pires da Silva, Andre|,|University of Warwick, Coventry, UK|
|2303|,|Pirola, Luciano|,|University of Lyon, Oullins, France|
|2647|,|Pitram, Suresh|,|Scripps Research Institute, La Jolla, CA|
|1007|,|Pittendrigh, Barry|,|Purdue University, West Lafayette, IN|
|3487|,|Pitula, Joseph|,|University of Maryland Eastern Shore, Princess Anne, MD|
|3569|,|Pizzo, Salvatore|,|Duke University, Durham, NC|
|3409|,|Planchon, Thomas|,|Delaware State University, Dover, DE|
|NL|,|Plasterk, Ronald|,|Hubrecht Laboratory, Utrecht, The Netherlands|
|JUP|,|Plastino, Julie|,|Institut Curie, Paris, France|
|  31|,|Platzer, Ed|,||
|2215|,|Playl, Lauren|,|University of Akron Wayne College, Orrville, OH|
|3560|,|Pleiss, Jeffrey|,|Cornell University, Ithaca, NY|
|OT|,|Plenefisch, John|,|University of Toledo, Toledo, OH|
|2236|,|Pletcher, Scott|,|Baylor College of Medicine, Houston, TX|
|2473|,|Plocke, Donald|,|Boston College, Chestnut Hill, MA|
| 527|,|Plummer, Patrick|,|Law Offices of Patrick Plummer, Phoenix, AZ|
|1021|,|Poa, Nicola|,|University of Otago, Christchurch School of Medicine, New Zealand|
|1408|,|Poccia, Dominic|,|Universidade Lusofona, Lisboa, Portugal|
|1516|,|Poch, Noemi Cabrera|,|Instituto de Investigaciones Biomedicas Alberto Sols, Madrid, Spain|
|RJP|,|Pocock, Roger|,|Monash University, Victoria, Australia|
|BP|,|Podbilewicz, Benjamin|,|Technion IIT, Haifa, Israel|
|CHP|,|Pohl, Christian|,|Goethe University Frankfurt, Frankfurt, Germany|
|2413|,|Pohlmann, Regina|,|University of Muenster, Muenster, Germany|
|NAV|,|Pokala, Navin|,|New York Institute of Technology, Old Westbury, NY|
|1159|,|Polack, Glenda|,|California State University, Fresno, CA|
|AT|,|Politz, Sam|,|Worcester Polytechnic Institute, Worcester, MA|
|4291|,|Polycarpo, Carla|,|Universidade Federal do Rio de Janeiro, Rio de Janeiro, Brazil|
|2436|,|Pomeroy-Black, Melinda|,|LaGrange College, LaGrange, GA|
|1447|,|Ponce, Ana Rita|,|Universidade Lusofona, Lisboa, Portugal|
|CHL|,|Poole, Richard|,|University College London, London, UK|
|4197|,|Poon, Pet|,|Lifelong Education Institute, San Francisco, CA|
|1234|,|Pootanakit, Kusol|,|Mahidol University, Nakorn Pathom, Thailand|
|3703|,|Porcar Miralles, Manuel|,|ICBBE, University of Valencia, Valencia, Spain|
|ICF|,|Porta-de-la-Riva, Montserrat|,|University Hospital, ICO - IDIBELL, Barcelona, Spain|
|2879|,|Porter, Andy|,|University  of Aberdeen, Aberdeen Scotland, UK|
|UR|,|Portman, Doug|,|University of Rochester Medical Center, Rochester, NY|
|1640|,|Potempa, Jan|,|Jagiellonian University, Cracow, Poland|
|1042|,|Potts, Malcolm|,|Virginia Tech, Blacksburg, VA|
|OL|,|Poulin, Gino|,|University of Manchenster, Manchester, England|
|JRP|,|Powell, Jennifer|,|Gettysburg College, Gettysburg, PA|
|ZG|,|Powell-Coffman, Jo Anne|,|Iowa State University, Ames, IA|
|2041|,|Prabhavathy, VR|,|MS Swaminathan Research Foundation, Chennai, India|
|3450|,|Prahlad, Veena|,|University of Iowa, Iowa City, IA|
|GRN|,|Praitis, Vida|,|Grinnell College, Grinnell, IA|
| 428|,|Pratap, Meera|,|UCLA, Los Angeles, CA|
|4255|,|Prehoda, Kenneth|,|University of Oregon, Eugene, OR|
| 397|,|Presutti, David|,|North Carolina State University, Raleigh, NC|
|3197|,|Pretsch, Alexander|,|SeaLife Pharma GmbH, Tulln, Austria|
|1179|,|Price, Neil|,|University of Rochester, Rochester, NY|
|JJ|,|Priess, Jim|,|Fred Hutchinson Cancer Research Center, Seattle, WA|
|1759|,|Prithiviraj, B|,|Nova Scotia Agricultural College, Truro, Nova Scotia, Canada|
|3298|,|Prober, David|,|California Institute of Technology, Pasadena|
|3316|,|Progulske-Fox, Ann|,|University of Florida, Gainesville, FL|
|3486|,|Proikas-Cezanne, Tassula|,|Eberhard Karls University, Tubingen, Germany|
|3958|,|Prokop, Zofia|,|Jagiellonian University, Krakow, Poland|
|APR|,|Promel, Simone|,|University of Leipzig, Leipzig, Germany|
|2623|,|Proteostasis Therapeutics, Inc.|,|Cambridge, MA|
|2849|,|Proudfoot, Lorna|,|Edinburgh Napier University. Scotland, UK|
|3858|,|Provchy, Matthew|,|Challenger School - Almaden, San Jose, CA|
|DWP|,|Pruyne, David|,|SUNY-UMU, Syracuse, NY|
|1471|,|Pu, Pu|,|Shanghai Institutes of Biological Sciences, Shanghai, China|
|4313|,|Pujol Onofre, Aurora|,|University Hospital, ICO - IDIBELL, Barcelona, Spain|
|RPW|,|Pukkila-Worley, Read|,|University of Massachusetts Medical School, Worcester, MA|
|UB|,|Pulak, Rock, Union Biometrica, Inc.|,|Union Biometrica, Inc., Somerville, MA|
| 598|,|Pulp and Paper Company|,|Pointe-Claire, Quebec, Canada|
|AP|,|Puoti, Alessandro|,|University of Fribourg, Switzerland|
|2972|,|Purugganan, Michael|,|New York University, New York, NY|
|3214|,|Puschner, Birgit|,|University of California, Davis, CA|
| 332|,|Putilina, Tatiana|,|National Eye Institute, NIH, Bethesda, MD|
|APP|,|Putzke, Aaron|,|Whitworth University, Spokane, WA|
|4251|,|Qi, Gaofu|,|Huazhong Agricultural University, Wuhan, Hubei, China|
|3059|,|Qi, Ling|,|Cornell University, Ithaca, NY|
|2867|,|Qi, Qingguo|,|Shandong University, China|
|3841|,|Qi, Yan|,|Amherst College, Amherst, MA|
|BLW|,|Qi, Yingchuan|,|Hangzhou Normal University, Hang'zhou, China|
|3406|,|Qian, Steven|,|North Dakota State University, Fargo, ND|
|1118|,|Qian, Zhikang|,|Fudan University, Shanghai, P.R. China|
|2315|,|Qin, Jianhua|,|Dalian Institute of Chemical Physics, Dalian, China|
|3442|,|Qin, Qiwei|,|Key Laboratory of Marine Bioresources, Guangzhou City, China|
|2458|,|Qin, Yan|,|Institute of Biophysics, Beijing, China|
|2061|,|Qiu, Liyou|,|Henan Agricultural University, Zhengzhou, Henan , China|
|3880|,|Qu, Rongda|,|North Carolina State University, Raleigh, NC|
|3319|,|Queitsch, Christine|,|University of Washington, Seattle WA|
|3126|,|Quindós, Guillermo|,|University of Basque Country, Leioa, Bizkaia, Spain|
|AGC|,|Quinn, Chris|,|University of Wisconsin, Milwaukee, WI|
|1138|,|Rachubinski, Richard|,|University of Alberta, Alberta, Canada|
| 266|,|Radice, Anthony|,|Lindsley F. Kimball Research Institute, New York, NY|
|1547|,|Radman, Miroslav|,|Mediterranean Institute For Life Sciences, Hrvatska, Croatia|
|EJR|,|Ragsdale, Erik|,|Indiana University, Bloomington, IN|
|1692|,|Ragsdale, Nick|,|Belmont University, Nashville, TN|
|1282|,|Raivio,|,|University of Alberta, Alberta, Edmonton, Canada|
|NQ|,|Raizen, David|,|University of Pennsylvania, Philadelphia, PA|
|2950|,|Raj, Arjun|,|University of Pennsylvania, Philadelphia, PA|
|2289|,|Rajakumar, Kumar|,|University of Leicester, Leicester, UK|
|NIK|,|Rajewsky, Nicholas|,|Berlin Institute for Medical Systems Biology, Berlin, Germany|
|1445|,|Rajini, P|,|Central Food Technological Research Institute, Mysore, India|
| 275|,|Rall, Joseph|,|National Institutes of Health, Bethesda, MD|
|1378|,|Raman, CS|,|University of Texas, Houston, TX|
|SRS|,|Ramanathan, Sharad|,|Harvard University, Cambridge, MA|
|4273|,|Ramic, Adriana|,|GenSpace, New York, NY|
|3631|,|Ramonida, Cathy Ruvidel|,|University of San Carlos, Cebu City, Philippines|
|3458|,|Ramos, Marco A.|,|Autonomous University of Baja California, Tijuana, B.C., Mexico|
| 338|,|Ramotar, Dindial|,|CHUL, Health and Environment, Quebec, Canada|
| 990|,|Ramotar, Dindial|,|Hospital Maisonneuve-Rosemont, Montreal, Quebec, Canada|
|2410|,|Rampersad, Joanne|,|University of Texas-Pan American, Edinburg, TX|
|RM|,|Rand, Jim|,|Oklahoma Medical Research Foundation, Oklahoma City|
|2934|,|Randall, Jennifer|,|New Mexico State University, Las Cruces, NM|
|4360|,|Rando, Oliver|,|UMass Medical School, Worcester, MA|
|4025|,|Ranjan, Akash|,|Centre for DNA Fingerprinting and Diagnostics, Hyderabad, India|
|VG|,|Rankin, Catherine|,|University of British Columbia, Vancouver, BC, Canada|
| 873|,|Rao, Rammohan|,|Buck Institute for Age Research, Novato, CA|
|2580|,|Rao, Reeta Prusty|,|Worcester Polytechnic Institutte, Worcester, MA|
|3581|,|Rartner, Adam|,|Columbia University, New York, NY|
| 551|,|Rasch, Jeff|,|Seattle Central Community College, Seattle, WA|
|3979|,|Raschke, Kristin|,|Bayer CropScience, Leverkusen, Germany|
| 360|,|Rasmussen, Karen|,|Bowdoin College, Brunswick, ME|
| 800|,|Ratcliffe, Peter|,|Wellcome Trust Centre for Human Genetics, Oxford, England|
|1503|,|Ravichandran|,|University of Virginia, Charlottesville, VA|
|1462|,|Rayes, Diego|,|INIBIBB, Argentina|
|3725|,|Rayes, Diego Hernan|,|Instituto de Investigaciones Bioquimicas, Bahia Blanca, Argentina|
|2918|,|Raymond, Brian|,|University of Kentucky, Lexington, KY|
|SLR|,|Rea, Shane|,|University of Texas, San Antonio, TX|
|3005|,|Reames, Spencer|,|Benjamin Logan High School|
|1751|,|Reaney, Martin|,|University of Saskatchewan, Saskatoon, Canada|
|2423|,|Rebbaa, Abdelhadi|,|Albany College of Pharmacy, Rensselaer, NY|
|3480|,|Rechavi, Oded|,|Tel Aviv University, Tel Aviv, Israel|
|1177|,|Reddien, Peter|,|Whitehead Insitute, Cambridge, MA|
|3956|,|Reddy, Akhilesh|,|University of Cambridge Metabolic Research Laboratories, Cambridge, UK|
|2449|,|Reece, Amber|,|Saint Louis University, Saint Louis, MO|
|RR|,|Reed, Randall|,|Johns Hopkins University, Baltimore, MD|
|  34|,|Rees, HH|,||
|3856|,|Reeve, Kern|,|Cornell University, Ithaca, NY|
|2077|,|Regenerative Sciences Institute|,|Mountain View, CA|
|3052|,|Reh, Thomas|,|University of Washington, Seattle, WA|
|1172|,|Reich|,|University of California, Santa Barbara, CA|
|1790|,|Reid, Suzanne|,|University of Auckland, New Zealand|
|DV|,|Reiner, Dave|,|Texas A&M Health Science Center, Houston TX|
|1923|,|Reinhold, Vernon|,|University of New Hampshire, Durham, NH|
|1754|,|Reinke, Catherine|,|Carlton College, Northfield, MN|
|YL|,|Reinke, Valerie|,|Yale University, New Haven, CT|
|OP|,|Reinke, Valerie|,|modENCODE, Yale University, New Haven, CT|
|SR|,|Reis, Robert|,|University of Arkansas, Little Rock, AR|
|1207|,|Reisner, Kaja|,|A.I. Virtanen Institute for Molecular Sciences, Kuopio, Finland|
| 437|,|Reiss, Rebecca|,|New Mexico Tech, Socorro, NM|
|4041|,|Remondi Souza, Ana Carolina|,|Universidade Federal de Sao Paulo, Sao Paulo, Brazil|
| 948|,|Remy, J.J.|,|UPR CNRS, Marseille, France|
|4083|,|Remy, Jean-Jacques|,|Institut Sophia Agrobiotech, Sophia Antipolis, France|
|1659|,|Ren, Shuang-Xi|,|National Chinese Human Genome Center, Shanghai, China|
| 768|,|Research Genetics|,|Huntsville, AL|
|4029|,|Reshetov, Denis|,|Moscow Center for Continuous Mathematical Education, Moscow, Russia|
|3337|,|Restif, Olivier|,|University of Cambridge, Cambridge, UK|
|4126|,|Rey, Felix|,|Institut Pasteur, Paris, France|
|3886|,|Reyes, Allen|,|Estrella Mountain Community College, Avondale, AZ|
|3973|,|Reyes, John Carlo|,|University of the Philippines, Manila, Philippines|
|RMR|,|Reynolds, Rose Mary|,|William Jewell College, Liberty, MO|
|RER|,|Rhoads, Robert|,|Louisiana State University, Shreveport, LA|
|3971|,|Rhode Ward, Jennifer|,|University of North Carolina, Asheville, NC|
| 241|,|Rhodes, Donald|,|Saint Anselm College, Manchester, NH|
|2145|,|Rhodes, Samuel|,|Franklin College, Franklin, IN|
| 368|,|Rhone-Poulenc Ag Company|,|Research Triangle Park, NC|
| 445|,|Ribeiro, Paula|,|McGill University, Quebec, Canada|
|1404|,|Ricci, Claudia|,|Milan University, Milano, Italy|
|2933|,|Rice, Jun Liang|,|Borough of Manhattan Community College, New York, NY|
|3142|,|Rice, Kelly C.|,|University of Florida, Gainesville, FL|
|3478|,|Richards, Stephanie|,|Bates College, Lewiston, ME|
|4286|,|Richardson, Jason|,|Northeast Ohio Medical University, Rootstown, OH|
|3825|,|Richaud, Myriam|,|Université Montpellier, Montpellier, France|
|3071|,|Richly, Holger|,|Institute of Molecular Biology, Mainz, Germany|
| 834|,|Richman, Adam|,|University of Maryland, College Park, MD|
|SY|,|Richmond, Janet|,|University of Illinois, Chicago, IL|
|2254|,|Richter, Klaus|,|Technical University Munchen, Munchen, Germany|
|4233|,|Ricketts, Marie-Louise|,|University of Nevada, Reno, NV|
|DR|,|Riddle, Don|,|Genome BC, Vancouver, BC, Canada|
| 293|,|Ridgewood High School, Ridgewood, NJ|,|Ridgewood, NJ|
|RIE|,|Riedel, Christian|,|Karolinska Institute, Stokholm, Sweden|
|2400|,|Riehn, Robert|,|North Carolina State University, Raleigh, NC|
|HRW|,|Riezman, Howard|,|University of Geneva, Geneva, Switzerland|
|QY|,|Rifkin, Scott|,|University of California, San Diego, CA|
| 851|,|Riga, Ekaterini|,|Southern Crop Protection & Food Research Ctr, London, Ontario, Canada|
|2903|,|Righini, Stacy|,|Colorado Stat Univ, Pueblo, CO|
| 731|,|Riihimaa, Paivi|,|University of Oulu, Oulu, Finland|
|1194|,|Rijsmus, Annemarie|,|Vrije University, Amsterdam, The Netherlands|
| 831|,|Riksen, Joost|,|Wageningen University, Wageningen, The Netherlands|
|FQ|,|Ringstad, Niels|,|NYU Medical Center, New York, NY|
|3344|,|Riordan, James|,|University of South Florida, Tampa, FL|
|3936|,|Rios, Juan Miranda|,|National Autonomous University of Mexico, Coyoacán, Mexico|
| 979|,|Rios, Marco|,|Mexico|
|MIR|,|Ristow, Michael|,|ETH Zurich, Schwerzenbach, Switzerland|
|3072|,|Rittman, Bruce|,|Arizona State University, Tempe, AZ|
|1091|,|Rivard, Laura|,|University of San Diego, San Diego, CA|
|4115|,|Rivas, Mariella|,|Universidad de Antofagasta, Antofagasta, Chile|
|DMR|,|Rivers, David|,|Syracuse University, Syracuse, NY|
|2370|,|Riviere, Johann|,|University of Geneva, Geneva, Switzerland|
|1747|,|Robert Sobkowiak|,|Adam Mickiewicz University, Poznan, Poland|
|FS|,|Roberts, Tom|,|Florida State University, Tallahassee|
|1762|,|Robertson, Alan|,|Iowa State University, Ames, IA|
|HM|,|Robertson, Hugh|,|University of Illinois, Urbana, IL|
|1664|,|Robeson, James|,|Pontificia Universidad Catolica de Valparaiso, Valparaiso, Chile|
|3539|,|Robin, Charles|,|University of Melbourne, Melbourne, Australia|
|2265|,|Robinson, Don|,|Neurosciences Institute, San Diego, CA|
|1838|,|Robinson, Gary|,|University of Kent, Kent, U.K.|
|3877|,|Robinson, Jacob|,|Rice University, Houston, TX|
|3927|,|Robinson, Kristin|,|NemaMetrix, Eugene, OR|
| 470|,|Robinson, Naomi|,|Texas Wesleyan University, Fort Worth, TX|
|1653|,|Robstem Ltd|,|Oxfordshire, U.K.|
|2528|,|Rocha, Joao Batista|,|Universidade Federal de Santa Maria, Rio Grande do Sul, Brazil|
|QR|,|Rocheleau, Christian|,|McGill University, Montreal, QC, Canada|
|QG|,|Rockman, Matthew|,|New York University, New York, NY|
|2669|,|Rodenbusch, Stacia|,|University of California, Berkeley, CA|
|1942|,|Rodriguez, Constantina|,|Universidad Nacional de Lujan, Capital Federal, Argentina|
|3946|,|Rodriguez, Mariana|,|Deretil Vitatech, Barcelona, Spain|
|4215|,|Rodriguez, Sofia|,|TECSIQUIM, Toluca de Lerdo, Mexico|
|2138|,|Rodriguez-Aguilera, Juan Carlos|,|Universidad Pablo de Olavide, Sevilla, Spain|
|3962|,|Rodriguez-Garcia, Ignacio|,|Universidad de Almeria, Almeria, Spain|
| 712|,|Roeder, Thomas|,|Universitat Hamburg, Germany|
|3293|,|Roehrig, Casey|,|Harvard University, Cambridge, MA|
| 811|,|Roemer, Martha|,|Northern Michigan University, Marquette, MI|
| 626|,|Roepke, Troy|,|San Francisco State University, Tiburon, CA|
|1120|,|Rogaev, Evgeny|,|University of Massachusetts Medical School, Worcester, MA|
|ANR|,|Rogers, Aric|,|Mt Desert Island Bio Lab, Salisbury Cove, ME|
|2659|,|Rogers, Sean|,|University of Calgary, Calgary, Alberta, Canada|
|3044|,|Rogoff, Harry|,|Boston Biomedical Inc, Boston, MA|
|1677|,|Rohleder, Kent|,|University of Kansas, Lawrence, KS|
|AKR|,|Rohlfing, Anne-Katrin|,|University of Potsdam, Golm, Germany|
| 459|,|Rohm and Haas Company|,|Rohm and Haas Company, Spring House, PA|
|4246|,|Rohozkova, Jana|,|Institute of Molecular Genetics, Prague, Czech Republic|
|3600|,|Rohr, Jason|,|University of South Florida, Tampa, FL|
|3606|,|Roig, Anna|,|ICMAB-CSIC, Barcelona, Spain|
|LR|,|Rokeach, Luis|,|University of Montreal, Quebec, Canada|
|2235|,|Rolke, Susan|,|Franklin Pierce University, Rindge,NH|
|2904|,|Romano, Frank|,|Jacksonville State University, Jacksonville, FL|
|2468|,|Romano-Silva, Marco Aurelio|,|Federal University of Minas Gerais, Belo Horizonte, Brazil|
|1658|,|Romero Tabarez, Magally|,|Biological Research Co - CIB, Medellin, Colombia|
|4300|,|Romero, Diego|,|University of Malaga, Malaga, Spain|
|3081|,|Romesberg, Floyd|,|Scripps Research Inst, La Jolla, CA|
|1822|,|Romling, Ute|,|Karolinska Institute, Stockholm, Sweden|
|SJ|,|Ron, David|,|Skirball Institute, New York, NY|
|WZ|,|Ronai, Ze'ev|,|Burnham Institute, La Jolla, CA|
|4171|,|Rong, Zeng|,|CAS, Shanghai Institutes for Biological Sciences, Shanghai, China|
|3937|,|Rongali, Sharath|,|Missouri State University. West Plains, MO|
|1980|,|Rongguang|,|Xinjiang Shihezi University, Xinjiang, China|
|OR|,|Rongo, Christopher|,|Rutgers University, Piscataway, NJ|
|3632|,|Rosa, Heitor|,|Universidade de Brasília, Brasília, Brazil|
|3363|,|Rosa-Molinar, Eduardo|,|University of Puerto Rico-Rio Piedras, San Juan, Puerto Rico|
|KR|,|Rose, Ann|,|University of British Columbia, Vancouver|
|2561|,|Rose, Jacqueline|,|Western Washington University, Bellingham, WA, USA|
|RL|,|Rose, Lesilee Simpson|,|University of California, Davis, CA|
|2810|,|Rosen, Stephen|,|University of California, San Francisco, CA|
| 799|,|Rosenbaum, Joel|,|Yale University, New Haven, CT|
|2893|,|Rosenblum, Erica Bree|,|University of Idaho, Moscow, ID|
|3230|,|Ross, Charles|,|Hampshire College, Amherst, MA|
|FV|,|Ross, Joseph|,|California State University, Fresno, CA|
| 686|,|Rossant, Janet|,|S Lunenfeld Research Inst, Mt Sinai Hosp, Toronto, Ontario, Canada|
|1239|,|Rossi, Leonardo|,|University of Pisa, Pisa, Italy|
|1372|,|Roszer, Tamas|,|University of Debrecen, Debrecen, Hungary|
| 693|,|Roth, Dagmar|,|Max-Planck-Inst fur Brain Research, Frankfurt, Germany|
|AR|,|Roth, Mark|,|Fred Hutchinson Cancer Research Center, Seattle, WA|
|1496|,|Roth, Michael|,|University of Texas Southwestern Medical Center, Dallas, TX|
| 350|,|Rothblatt, Jon|,|Aventis Pharma Deutschland GmbH, Martinsried, Germany|
|JR|,|Rothman, Joel|,|University of California, Santa Barbara|
|1191|,|Rotin, Daniela|,|The Hospital for Sick Children, Toronto, Ontario, Canada|
|RG|,|Rougvie, Ann|,|University of Minnesota,  Minneapolis, MN|
|2443|,|Routtenberg, Aryeh|,|Northwestern University, Evanston, IL|
|2656|,|Rowley, Gary|,|University of East Anglia, Norwich, UK|
| 517|,|Roy, J.K.|,|Banaras Hindu University, Varanasi, India|
|RP|,|Roy, Peter|,|University of Toronto, Toronto, ON, Canada|
|MR|,|Roy, Richard|,|McGill University, Montreal, Quebec, Canada|
| 255|,|Royal, Dewey|,|University of Iowa, Iowa City|
| 627|,|Rozek, Charles|,|Case Western Reserve University, Cleveland, OH|
|2873|,|Ru, Shaoguo|,|Marine Ecotox of Ocean Univ, Shandong, China|
|CR|,|Rubin, Charles|,|Albert Einstein College of Medicine, Bronx NY|
| 478|,|Rubin, Michael|,|Cayey University College, Cayey, Puerto Rico|
|4118|,|Rubinsky, Boris|,|University of California, Berkeley, CA|
|DJR|,|Rudel, David|,|East Carolina University, Greenville, NC|
|3938|,|Ruginis, Tom|,|Perlstein Lab, San Francisco, CA|
|3913|,|Rui, Xin|,|Nanjing Agricultural University, Jiangsu, China|
| 419|,|Ruiz, Lulio|,|Purdue University, West Lafayette, IN|
|CRR|,|Ruiz-Rubio, Manuel|,|Universidad de Cordoba, Cordoba, Spain|
|2773|,|Rumbold, Karl|,|University of the Witwatersrand, Johannesburg, South Africa|
| 298|,|Runciman, Susan|,|Department of Anatomy and Cell Biology, University of Toronto|
|APR*|,|Russ, Andreas|,|Oxford University, Oxford, England|
|PR*|,|Russell, Dick|,|University of Pittsburgh, PA|
| 449|,|Russo, Tom|,|Weehawken High School, Weehawken, NJ|
|4165|,|Ruthig, Gregory|,|North Central College, Naperville, IL|
|1418|,|Rutledge, Eric|,|Rensselaer Polytechnic Institute, Troy, NY|
|YR|,|Ruvinsky, Ilya|,|University of Chicago, Chicago, IL|
|GR|,|Ruvkun, Gary|,|Massachusetts General Hospital, Boston, MA|
|AGR|,|Ryazanov, Alexey|,|UMDNJ-RW Johnson Medical School, Piscataway, NJ|
|2786|,|Ryder, Andrew|,|Marist College, Poughkeepsie, NY|
|RY|,|Ryder, Liz|,|Worcester Polytechnic Institute, Worcester, MA|
|WRM|,|Ryder, Sean|,|University of Massachusetts Medical School, Worcester, MA|
|WSR|,|Ryu, William|,|University of Toronto, ON, Canada|
|3792|,|Saarberg, Werner|,|Dr. Willmar Schwabe GmbH & Co., Karlsruhe, Germany|
| 881|,|Saba, Dr.|,|Children's Hospital Oakland Research Institute, Oakland, CA|
|3453|,|Sabanayagam, Chandran|,|University of Delaware, Newark, DE|
|1967|,|Sabatier, Christelle|,|Santa Clara University, Santa Clara, CA|
|3986|,|Sabiniano, Eduardo|,|University of Washington, Seattle, WA|
|1815|,|Sadanandam, A|,|Kakatiya University, Warangal, India|
|3190|,|Sadhale, Parag|,|Indian Institute of Science, Bangalore, India|
|2888|,|Sadoul, Remy|,|INSERM Institut des Neurosciences, Grenoble, France|
| 108|,|Saeed, M|,||
| 453|,|Sager, Brian|,|Cambridge, MA|
|1685|,|Said, HM|,|University of California Irvine, VA Medical Center, Long Beach, CA|
|1115|,|Saigo, Kaoru|,|University of Tokyo, Tokyo, Japan|
|1052|,|Saikawa, Masatoshi|,|Tokyo Gakugei University, Tokyo, Japan|
|VW|,|Saito, Mako|,|Dartmouth Medical School, Hanover, NH|
|1908|,|Sajid, Muhammad|,|University of Karachi, Pakistan|
| 708|,|Sakamoto, Hiroshi|,|Dept of Biology, Kobe University, Kobe, Japan|
|1253|,|Sakamoto, Kazuichi|,|University of Tsukuba, Ibaraki, Japan|
|KJP|,|Sakamoto, Taro|,|Kitasato University, Tokyo, Japan|
|4302|,|Sakashita, Maya|,|Pharma Foods International Co., Ltd., Kyoto, Japan|
|1656|,|Sakashita, Tetsuya|,|Japan Atomic Energy Research Institute, Gunma, Japan|
|YAA|,|Sako, Yasushi|,|RIKEN, Wako, Japan|
|2486|,|Saksmerprome, Vanvimon|,|Mahidol University, Bangkok, Thailand|
|ZR|,|Salcini, Lisa|,|BRIC, University of Copenhagen, Copenhagen, Denmark|
|3176|,|Salgado, Vince|,|BASF, Research Park Triangle, NC|
|2304|,|Salgia, Ravi|,|University of Chicago, Chicago, IL|
|IH|,|Salinas, Gustavo|,|Instituto de Higiene, Montevideo, Uruguay|
|1775|,|Salisbury, Vyv|,|University of the West of England, Bristol, England|
|2202|,|Salisbury, Vyv|,|University of the West of England, Bristol, England, UK|
|LY|,|Salkoff, Larry|,|Washington University, St. Louis, MO|
|2778|,|Salmond, George|,|University of Cambridge, UK|
|1343|,|Salo, Emili|,|Universitat de Barcelona, Barcelona, Spain|
|2634|,|Salt, David|,|Purdue University, West Lafayette, IN|
|1556|,|Salter, Donald|,|University of West Alabama, Livingston, AL|
|3542|,|Salvador, Ricardo|,|IMYZA-INTA, Buenos Aires, Argentina|
| 387|,|Sambongi, Yoshihiro|,|ISIR, Osaka University, Osaka, Japan|
|WW|,|Samoiloff, Martin|,|University of Manitoba, Winnipeg|
|ADS|,|Samuel, Aravi|,|Harvard University, Cambridge, MA|
|BIG|,|Samuel, Buck|,|Baylor College of Medicine, Houston, TX|
|AVS|,|Samuelson, Andrew|,|University of Rochester, Rochester, NY|
|1843|,|San Francisco, Michael|,|Texas Tech University, Lubbock, TX|
|4355|,|San Miguel, Adriana|,|North Carolina State University, Raleigh, NC|
|2919|,|San-Blas, Ernesto|,|Inst Venezolano de Investigaciones Científicas, Maracaibo, Venezuela|
|3915|,|Sanchez Mora, Ruth Melida|,|University College of Cundinamarca, Bogota, Colombia|
| 584|,|Sanchez, Becky|,|Point Loma College, San Diego, CA|
|2864|,|Sanderson, CM|,|University of Liverpool, UK|
| 946|,|Sanford, Jack|,|Derryfild High School, Manchester, NH|
|3547|,|Sang Sun, Yoon|,|Yonsei University College of Medicine, Seoul, South Korea|
|1900|,|Sang, Chen|,|Beihang University, Beijing, Haidian, China|
|4075|,|Sanmartin, Isaias & Torres, Javier|,|Catholic University of Valencia, Valencia, Spain|
|4287|,|Santamaria, Abel|,|National Inst of Neurology & Neurosurgery, Mexico City, Mexico|
|2047|,|Santander, Javier|,|Arizona State University, Tempe, AZ|
|2001|,|Santas, Amy|,|Muskingum College, New Concord, OH|
|2242|,|Santiago, TC|,|Central Institute of Brackishwater Aquaculture, Chennai, India|
| 764|,|Santos, Claudia|,|UnIGENe/IMBC, Porto, Portugal|
|4217|,|Santos-Buelga, Celestino|,|Universidad de Salamanca, Salamanca, Spain|
|AMS|,|Sapir, Amir|,|University of Haifa at Oranim, Tivon, Israel|
|SAR|,|Sar, Funda|,|Koc University, Istanbul, Turkey|
|2160|,|Sarkar, Abhimanyu|,|Massey University, Palmerston North, New Zealand|
|TEE|,|Sarkies, Peter|,|Imperial College London, London, UK|
|TGR|,|Sarov, Mihail|,|MPI-CBG, Dresden, Germany|
|4191|,|Sarro, Emma|,|Dominican College, Orangeburg, NY|
|2263|,|Sasisekharan, Ram|,|MIT, Cambridge, MA|
|4361|,|Sathapondecha, Ponsit|,|Prince of Songkla University, Hat Yai, Thailand|
|1595|,|Satir, Birgit|,|Albert Einstein College of Medicine, Bronx, NY|
|3624|,|Sato, Brian|,|University of California, Irvine, CA|
|4239|,|Sato, Fumihiko|,|Kyoto University, Kyoto, Japan|
|GK|,|Sato, Ken|,|Gunma University, Gunma, Japan|
|1369|,|Sato, Masashi|,|Kagawa University, Kagawa, Japan|
|3348|,|Sato, Ryoichi|,|Tokyo University of Agriculture and Technology, Tokyo, Japan|
|4303|,|Satou, Shinichi|,|Takeda Pharmaceutical Co., Kanagawa, Japan|
|LM|,|Sattelle, David|,|University College London, London, UK|
|3590|,|Saumweber, Harald|,|Humboldt Universitat, Berlin, Germany|
|3695|,|Savage, David|,|University of California, Berkeley, CA|
|CS|,|Savage-Dunn, Cathy|,|Queens College/CUNY, Flushing, NY|
|3501|,|Savory, Andrew|,|Winchester College Science School, Winchester, UK|
|1027|,|Savu, Lorand|,|Bucharest University, Bucharest, Romania|
|HS|,|Sawa, Hitoshi|,|National Institute of Genetics, Mishima, Japan|
|2213|,|Scales, Jon|,|Midwestern State University, Wichita Falls, TX|
|2802|,|Scampavia, Deborah|,|Scripps Med Res Inst, Jupiter, FL|
|  38|,|Schachat, F|,||
|1231|,|Schachter, Harry|,|Hospital for Sick Children, Toronto, Ontario, Canada|
|AQ|,|Schafer, Bill|,|MRC-LMB, Cambridge, England|
|BS|,|Schedl, Tim|,|Washington University, St. Louis, MO|
|SG|,|Scheel, Jochen|,|Max-Planck-Institut for Developmental Biol, Tuebingen, Germany|
| 724|,|Schejter, Eyal|,|Weizmann Institute of Science, Rehovot, Israel|
|3908|,|Schellhorn, Herb|,|McMaster University, Hamilton, ON, Canada|
|2538|,|Scherer, Siegfried|,|Technische Universitaet Muenchen, Freising, Germany|
| 961|,|Schieffer, Steve|,|Amery High School, Amery, WI|
|ES|,|Schierenberg, Einhard|,|University of Cologne, Germany|
|1163|,|Schisa, Jennifer|,|Central Michigan University, Mount Pleasant, MI|
| 526|,|Schlegel, Robert|,|Pennsylvania State University, University Park, PA|
|3305|,|Schmid, Sandra|,|Scripps Research Institute, La Jolla, CA|
|3199|,|Schmidt, Kristina|,|University of South Florida, Tampa, FL|
|KLS|,|Schmidt, Kristopher|,|Goshen College, Goshen, IN|
|3863|,|Schmitt-Engel. Christian|,|University Erlangen-Nurnberg, Erlangen, Germany|
|GE|,|Schnabel, Ralf|,|TU Braunschweig, Braunschweig, Germany|
|2114|,|Schnoor, Jerald|,|University of Iowa, Iowa City, IA|
|1264|,|Schoen, Daniel|,|McGill University, Montreal, Quebec, Canada|
|2506|,|Schoetz,|,|Princeton University, Princeton, NJ|
|KD|,|Scholey, Jonathan|,|University of California, Davis, CA|
|1092|,|Schonbaum, Christopher|,|University of Chicago, Chicago, IL|
|3328|,|Schonfelder, Gilbert|,|Charite-Universitatsmedizin Berlin, Berlin, Germany|
|LSC|,|Schoofs, Liliane|,|KUL, Leuven, Belgium|
|2615|,|Schooler, Nason|,|Methuselah Foundation, Inst for Biological Gerontology, Tempe, AZ|
|1947|,|Schouest, Katherine|,|University College Cork, Cork, Ireland, UK|
|3507|,|Schramp, Mark|,|Benedictine College, Atchison, KS|
| 404|,|Schriever, Antje|,|Hamburg, Germany|
|FCS|,|Schroeder, Frank|,|Cornell University, Ithaca, NY|
|NES|,|Schroeder, Nate|,|University of Illinois Urbana-Champaign, Urbana IL|
|2939|,|Schroeppel, Klaus|,|Institute for Medical Microbiology, Tuebingen, Germany|
| 361|,|Schubert, Karel|,|University of Oklahoma, Norman, OK|
| 452|,|Schuemperli, Daniel|,|Abteilung fuer Entwicklungsbiologie, Bern, Switzerland|
|2713|,|Schuh, Melina|,|MRC-LMB, Cambridge, UK|
| 414|,|Schuh, Tim|,|St. Cloud State University, St. Cloud, MN|
|MY|,|Schulenberg, Hinrich|,|Christian-Albrechts-Univ zu Kiel, Germany|
|3623|,|Schulman, Gustavo|,|Pontificic Argentine Catholic University, Buenos Aries, Argentina|
|2797|,|Schultheis, Alicia|,|Stetson University, DeLand, FL|
|3203|,|Schultheis, Patrick|,|Northern Kentucky University, Highland Heights, KY|
|1684|,|Schulz, Tim|,|Friedrich-Schiller-University, Jena, Germany|
|EC|,|Schulze, Ekkehard|,|University of Gottingen, Germany|
|BJS|,|Schumacher, Bjoern|,|University of Cologne, Cologne, Germany|
|JS|,|Schumacher, Jill|,|University of Texas, Houston, TX|
|3463|,|Schurko, Andrew|,|Hendrix College, Conway, AR|
|EFS|,|Schuster, Eugene|,|University College London, London, England, UK|
|MSC|,|Schvarzstein, Mara|,|City University of New York, Brookyln, NY|
|JE|,|Schwarzbauer, Jean|,|Princeton University, Princeton, NJ|
| 998|,|Schweizer,|,|Institute of Botany, University of Vienna, Austria|
|3866|,|Schwerdtle, Tanja|,|University of Potsdam, Potsdam, Germany|
|2185|,|Scita, Giorgio|,|FIRC, IFOM, Milan, Italy|
|2336|,|Scott, Ian|,|University of Warwick, Wellesbourne, Warick, UK|
|UH|,|Scott, John|,|Macau, Macao SAR China|
| 645|,|Scott, Rod|,|Wheaton College, Wheaton, IL|
| 483|,|Scouras, Z.G.|,|Aristotle University of Thessaloniki, Greece|
|3295|,|Scouten, Alan|,|Gordon College, Barnesville, GA|
|1368|,|Scynexis, Inc|,|Durham, NC|
|4312|,|Seeram, Naindra|,|University of Rhode Island, Kingston, RI|
|2157|,|Segal, Scott|,|Winona State University, Winona, MN|
|LS|,|Segalat, Laurent|,|University of Lyon, Lyon, France|
|3573|,|Segui, Emilio Monsesinos|,|University of Girona, Girona, Spain|
|3003|,|Segun, Aderibigbe|,|University of Ibadan, Ibadan, Nigeria|
|2765|,|Seifert, Roland|,|Med School of Hannover - Inst Pharmacology, Hannover, Germany|
|4072|,|Seiml-Buchinger, Rene|,|Humboldt-Universität zu Berlin, Berlin, Germany|
|1919|,|Seipelt, Rebecca|,|Middle Tennessee State University, Murfreesboro, TN|
|3963|,|Sekowska, Agnieszka|,|AMAbiotics SAS, Evry, France|
|2830|,|Selbach, Matthias|,|Max Delbruck Centrum - Molekular Medizin, Berlin, Germany|
|3377|,|Seleem, Mohamed|,|Purdue University, West Lafayette, IN|
|1296|,|Selkirk, Murray|,|Imperial College London, London, UK|
|3036|,|Sem, Xiao-Hui|,|Karolinska Institutet, Stockholm, Sweden|
|PY|,|Sengupta, Piali|,|Brandeis University, Waltham, MA|
| 313|,|Seo, Sung-yum|,|Kongju National University, Chungnam-Do, Korea|
|3722|,|Sequeira, Andrea|,|Wellesley College, Wellesley, MA|
|2762|,|Sergere, Jean Christophe|,|SETUBIO, Hauterive, France|
|3860|,|Serrano, Luis|,|Centre de Regulacio Genomica, Barcelona, Spain|
|1577|,|Serror, Pascale|,|INRA, Jouy-en-Josas, France|
|FDX|,|Sesti, Federico|,|Rutgers University, Piscataway, NJ|
| 549|,|Sestier, Claude|,|Laboratoire de Parasitologie du CNEVA, France|
| 316|,|Setterquist, Robert|,|University of Houston, Houston, TX|
|AFS|,|Severson, Aaron|,|Cleveland State University, Cleveland, OH|
| 620|,|Seward, Julie|,|University of Tennessee, Knoxville, TN|
|JH|,|Seydoux, Geraldine|,|Johns Hopkins University, Baltimore, MD|
|OS|,|Shaham, Shai|,|Rockefeller University, New York, NY|
|DS|,|Shakes, Diane|,|College of William and Mary, Williamsburg, VA|
|3601|,|Shamieh, Lara|,|Regis University, Denver, CO|
|GSH|,|Shan, Ge|,|Hua Zhong Univ of Science and Technology, China|
|2257|,|Shanmugasundaram, S|,|Madurai Kamaraj University, Tamil Nadu, India|
|1519|,|Shao, Huang|,|University of Texas Medical Branch, Galveston, TX|
|FDU|,|Shao, Zhiyong|,|Fudan University Institutes of Brain Science, Shanghai, China|
|2317|,|Shapira, Michael|,|University of California, Berkeley, CA|
|2284|,|Shapiro, Paul|,|University of Maryland, Baltimore, MD|
|1062|,|Sharp, Phil|,|MIT Cancer Center, Cambridge, MA|
|WJ|,|Sharrock, Bill|,|University of Minnesota, St. Paul, MN|
|1667|,|Shatkin, Aaron|,|Rutgers University, Piscataway, NJ|
|3543|,|Shavit, Roee|,|FuturaGene Ltd, Rehovot, Israel|
|EH|,|Shaw, Jocelyn|,|University of Minnesota, Minneapolis, MN|
|1921|,|Sheehy, Robert|,|Radford University, Radford, VA|
|2745|,|Shelby, Kent|,|USDA, Columbia, MO|
|2881|,|Shelley, Mike & Zhang|,|Courant Inst Math Sci, New York, NY|
|GX|,|Shelton, Chris|,|SmithKline Beecham, Inc., King of Prussia, PA|
|3161|,|Shen, Amy|,|University of Washington, Seattle, WA|
|2726|,|Shen, Jingshi|,|University of Colorado, Boulder, CO|
|TV|,|Shen, Kang|,|Stanford University, Stanford, CA|
|3464|,|Shen, Lulu|,|Jiangsu Normal University, Xuzou Jiangsu Province, China|
|3950|,|Shen, Yaling|,|East China University of Science and Technology, Shanghai, China|
|SYD|,|Shen, Yidong|,|Shanghai Institutes for Biological Sciences, CAS, Shanghai, China|
|PTN|,|Sheng, Zu-Hang|,|NINDS-NIH, Bethesda, MD|
|4157|,|Shepard, John|,|Center for Vector Biology & Zoonotic Diseases, New Haven, CT|
|3572|,|Shepherd, Jennifer|,|Gonzaga University, Spokane, WA|
|3282|,|Sherratt, Tom|,|Carleton University, Ottawa, ON, Canada|
|4089|,|Sherriff, Julia|,|Chronos Therapeutics, Oxford, England, UK|
|NK|,|Sherwood, David|,|Duke University, Durham NC|
|HUS|,|Shi, Anbing|,|HUST, Wuhan, China|
|2414|,|Shi, T|,|Medical School of Hannover, Hannover, Germany|
|YS|,|Shi, Yang|,|Harvard Medical School, Boston, MA|
|1548|,|Shibuya, Hiroshi|,|Tokyo Medical and Dental University, Tokyo, Japan|
|3185|,|Shibuya, Toshiharu|,|Osaka University, Osaka, Japan|
|1493|,|Shieh, Bih-Hwa|,|Vanderbilt University, Nashville, TN|
|1192|,|Shiff, Clive|,|Bloomberg School of Public Health, Baltimore, MD|
|2082|,|Shih, Jean Chen|,|University of Southern California, Los Angeles, CA|
|1069|,|Shim, Eun Yong|,|University of Texas Health Science Center, San Antonio, TX|
|JAS|,|Shim, Jaegal|,|National Cancer Center, Goyang, South Korea|
|YHS|,|Shim, Yhong-Hee|,|Konkuk University, Seoul, South Korea|
| 352|,|Shima, Yukio|,|Kyorin University, Tokyo, Japan|
|3403|,|Shimabukuro, Katsuya|,|National College of Technology, Yamaguchi, Japan|
| 827|,|Shimada, Masumi|,|Japan Science & Technology Corp, Tsukuba, Ibaraki, Japan|
|3667|,|Shimizu, Miho|,|Tokyo University of Agriculture and Technology, Tokyo, Japan|
|2203|,|Shimizu, Takahiko|,|Tokyo Metropolitan Institute of Gerontology, Tokyo, Japan|
|1852|,|Shimuta, Ken|,|National Institute of Infectious Diseases, Tokyo, Japan|
|2750|,|Shin, Jennifer|,|Soft Biomechanics & Biomaterials Lab, KAIST, Daejeon, Korea|
|3642|,|Shin, Joo-Ho|,|Sungkyunkwan University School of Medicine, Suwon, South Korea|
|EX|,|Shin, Tae Ho|,|Baylor College of Medicine, Houston, TX|
|QS|,|Shingai, Ryuzo|,|Iwate University, Ueda, Iwate, Japan|
|3643|,|Shinkai, Tadashi|,|Shibaura Institute of Technology, Saitama, Japan|
|3726|,|Shinn-Thomas, Jessica|,|Utica College, Utica, NY|
|2927|,|Shintani, Tomoya|,|Matsutani Chemical Industry Co, Itami-city Hyogo, Japan|
|1400|,|Shirasawa, Takuji|,|Tokyo Metropolitan Institute of Gerontology, Tokyo, Japan|
|2782|,|Shirk, Paul|,|USDA-ARS, Gainesville, FL|
|2818|,|Shivers, Robert|,|Commonwealth Medical College, Scranton, PA|
|1196|,|Shober, Jana|,|California State University, Sacramento, CA|
| 658|,|Shompole, Patrick|,|Washington State University, Pullman, WA|
|3347|,|Showmaker, Kurt|,|Mississippi State University, MS|
|3665|,|Shrestha, Srijan|,|Makise Lifeup Laboratory Co. Ltd., Okinawa, Japan|
|SLS|,|Shroff, Hari|,|NIBIB/NIH, Bethesda, MD|
|1464|,|Shubert-Coleman, Jonathan|,|University of Connecticut, Farmington, CT|
|2184|,|Shuwen, Guan|,|Jinlin University, Changchun, China|
|3589|,|Shuzhen, Sim|,|Genome Institute of Singapore, Singapore|
|1954|,|Siciliano, Steve|,|University of Saskatchewan, Saskatoon, Saskatchewan, Canada|
|1288|,|Siddiqui, Afzal|,|Texas Tech University, Amarillo, TX|
|SQ|,|Siddiqui, Shahid|,|University of Illinois, Chicago, IL|
|4183|,|Siebel-Hunt, Beth|,|St. Paul Academy and Summit School, St. Paul, MN|
|OJ|,|Sieburth, Derek|,|University of Southern California, Los Angeles, CA|
|3133|,|Siegel, Dionicio|,|University of California, San Diego, CA|
| 602|,|Siegman, Marion|,|Jefferson Medical College, Philadelphia, PA|
|4001|,|Siekierka, John|,|Montclair State University, Montclair, NJ|
|VR|,|Sifri, Costi|,|University of Virginia, Charlottesville, VA|
|3437|,|Sikes, James|,|University of San Francisco, San Francisco, CA|
|2826|,|Silhankova, Marie|,|Charles University, Prague, Czech Republic|
|VK|,|Silverman, Gary|,|University of Pittsburgh, Pittsburgh, PA|
|3322|,|Silverman, Richard|,|Northwestern University, Evanston, IL|
|MJS|,|Simard, Martin|,|Laval University, Quebec City, Quebec, Canada|
| 480|,|Siminovitch, Kathy|,|Samuel Lunenfeld Institute, Mt Sinai Hospital, Toronto, Canada|
|1279|,|Simoes, Nelson|,|Rua da Mae de Deus, Acores, Portugal|
|1789|,|Simokat, Kristin|,|University of Idaho, Moscow, ID|
| 292|,|Simon, Mel|,|California Institute of Technology, Pasadena, CA|
|3069|,|Simonetta, Sergio|,|Fundación Instituto Leloir, Buenos Aires, Argentina|
|4060|,|Simonetti, Giovanna|,|Sapienza University, Rome, Italy|
|QQ|,|Simske, Jeff|,|Rammelkamp Center, Cleveland, OH|
|2012|,|Sinclair, David|,|Harvard Medical School, Boston, MA|
| 534|,|Singer, Sherry|,|Falls Church High School, Falls Church, VA|
|3676|,|Singh, Brahmanand|,|CSIR-National Botanical Research Inst, Lucknow, India|
| 732|,|Singh, Harbinder|,|Medical University, Charleston, SC|
|1428|,|Singh, Harpreet|,|University of Edinburgh. Scotland, UK|
|3335|,|Singh, Jagdeep|,|IISER Mohali, India|
|1294|,|Singh, Upinder|,|Stanford University School of Medicine, Stanford, CA|
|3628|,|Singh, Varsha|,|Indian Institute of Science, Bangalore, India|
|AD|,|Singson, Andrew|,|Waksman Institute, Piscataway, NJ|
| 965|,|Siomi, H|,|University of Tokushima, Tokushima, Japan|
|1151|,|Sixsmith, Danielle|,|DNA Learning Center, Lake Success, NY|
|4318|,|Skerrett, Ingrid Martha|,|Buffalo State College, Buffalo, NY|
|3847|,|Skirkanich, Jennifer|,|Bryn Mawr College, Bryn Mawr, PA|
|MAD|,|Skop, Ahna|,|University of Wisconsin, Madison, WI|
|CT|,|Slack, Frank|,|Harvard University, Boston, MA|
|3935|,|Sliwinski, Marek|,|University of Northern Iowa, Cedar Falls, IA|
|1943|,|Slock, Jim|,|King's College, Wilkes-Barre, PA|
| 545|,|Sloop, Gregory|,|Louisiana State University Medical Center, New Orleans, LA|
|AE|,|Sluder, Ann|,|Massachusetts General Hospital, Charlestown, MA|
|1654|,|Smith, Erica|,|University of Washington, Seattle, WA|
|3636|,|Smith, Geoffrey|,|New Mexico State University, Las Cruces, NM|
|RV|,|Smith, Harold|,|University of Maryland Biotechnology Institute, Rockville, MD|
|NNL|,|Smith, Jonathan|,|Lerner Research Institute, Cleveland, OH|
|4077|,|Smith, Latasha|,|Central Baptist College, Conway, AR|
| 855|,|Smith, Martin|,|CBD Porton Down, Wiltshire, England|
| 913|,|Smith, Paula|,|Harvard Medical School, Boston, MA|
|PAS|,|Smith, Pliny|,|Dominican Univeristy, River Forest, IL|
|1931|,|Smith, Robert|,|University of the Sciences in Philadelphia, Philadelphia, PA|
|1882|,|Smith, Stephen|,|Trinity College, Dublin, Ireland, UK|
|2462|,|Smith, Trenton|,|Simpson University, Redding, CA|
|SSM|,|Smolikove, Sarit|,|University of Iowa, Iowa City, IA|
|2346|,|Snell, Terry|,|Georgia Institute of Technology, Atlanta, GA|
|1539|,|Snider, Mark|,|College of Wooster, Wooster, OH|
|3035|,|Snow, Jonathan|,|Williams College, Williamstown, MA|
|3851|,|Snowflack, Danielle|,|EDVOTEK Biotechnology Education Company, Washington, DC|
|TS|,|Snutch, Terry|,|University of British Columbia, Vancouver, B.C., Canada|
|2530|,|Snyder, Michael|,|Yale University, New Haven, CT|
|3843|,|Soares Mendes Giannini, Maria Jose|,|Faculdade de Ciências Farmacêuticas de Araraquara, UNESP, Brazil|
|3195|,|Soares Netto, Luis Edwardo|,|Instituto de Biociências - USP, Sao Paolo, Brazil|
|3226|,|Soares, Felix|,|Universidade Federal de Santa Maria, Santa Maria, Brazil|
|2517|,|Soares, Rosangela Maria de Araujo|,|Universidade Federal de Rio de Janeiro, Rio de Janeiro, Brazil|
|SBG|,|Sobue, Gen|,|Nagoya University, Nagoya, Japan|
|4142|,|Soen, Yoav|,|Weizmann Institute of Science, Rehovot, Israel|
|BSS|,|Sohlenius, Bjorn|,|Naturhistorikiska Riksmuseet, Stockholm, Sweden|
| 810|,|Solari, Florence|,|University of Lyon, France|
|1405|,|Solomon, Aaron|,|Northwestern University, Evanston, IL|
|NOA|,|Solomon, Aaron|,|Northwestern University, Evanston, IL|
|4232|,|Solomon, Deepak|,|Neofluidics LLC, Carlsbad, CA|
|2983|,|Solon, Juan Antonio|,|University of Philippines, Manilla, Philippines|
|1710|,|Som, Tapan|,|Thomas Jefferson University, Philadelphia, PA|
|RS|,|Sommer, Ralf|,|MPI, Tubingen, Germany|
|1994|,|Song, Ciyu|,|Fudan University, Shanghai, China|
|3991|,|Song, Hyun-Ok|,|Wonkwang University School of Medicine, Iksan, Jeonbuk, South Korea|
|MTU|,|Song, Mi Hye|,|Oakland University, Rochester MI|
|2105|,|Song, Myung-Chul|,|Sogang University, Seoul, South Korea|
|3985|,|Song, Rafael|,|New York University Abu Dhabi, Abu Dhabi, UAE|
|3050|,|Sorensen, Poul|,|British Columbia Cancer Research Centre, Vancouver, BC, Canada|
| 603|,|Sorger, George|,|McMaster University, Hamilton, Ontario, Canada|
|SCS|,|Soti, Csaba|,|Semmelweis University, Budapest, Hungary|
|3120|,|Soto, Claudio|,|University of Texas Health Science Center, Houston, TX|
|OX|,|Soto, Martha|,|UMDNJ, Piscataway, NJ|
|4350|,|Soto, Sara|,|Fundacio Privada Instituto Global de Barcelona, Barcelona, Spain|
|MGH|,|Soukas, Alex|,|MGH-CHGR, Boston, MA|
|1130|,|Soultanas, Panos|,|University of Nottingham, Nottingham, UK|
|3735|,|Sowmiya Rani, KS|,|Inst of Forest Genetics & Tree Breeding, Coimbatore, India|
|FA|,|Spang, Anne|,|Biozentrum, Basel, Switzerland|
|1473|,|Spanier, Britta|,|Technical University Munich, Freising, Germany|
|1084|,|Spankuch-Schmitt, Birgit|,|JW Goethe University, Frankfurt/Main, Germany|
|AS|,|Spence, Andrew|,|University of Toronto, Ontario|
|1472|,|Spencer, James Vaughn|,|University of Pittsburgh, Pittsburgh, PA|
|3143|,|Spencer, Kylee|,|Heidelberg University, Tiffin, OH|
|1828|,|Sperling, Ruth|,|Hebrew University of Jerusalem, Jerusalem, Israel|
|WQ|,|Spieth, John|,|Washington University, St. Louis, MO|
|1136|,|Spikes, Deborah|,|SUNY Stony Brook, Stony Brook, NY|
|1362|,|Spillane, Charlie|,|University College Cork, Cork, Ireland, UK|
|1948|,|Sprando, Robert|,|Food and Drug Administration, Laurel, MD|
|2090|,|Springer, Wolfdieter|,|Mayo Clinic, Jacksonville, FL|
|2325|,|Spurgeon, David|,|Center for Ecology and Hydrology, Cambridgeshire, England|
| 286|,|Spychalla, James|,|Washington State University, Pullman, WA|
| 583|,|Squire, Michael|,|University of Cambridge, Cambridge, England|
|MAS|,|Srayko, Martin|,|University of Alberta, Edmonton, Alberta, Canada|
|1113|,|Srinivas, Leela|,|Adichunchanca Giuri Biotech & Cancer Res Inst, Karnataka, India|
|2225|,|Srinivasan, Chandra|,|California State University, Fullerton, CA|
|3551|,|Srinivasan, Dayalan|,|Rowan University, Glassboro, NJ|
|JSR|,|Srinivasan, Jagan|,|Worcester Polytechnic Institute, Worcester MA|
|1648|,|Srinivasan, Mandayam|,|MIT, Cambridge, MA|
|SSR|,|Srinivasan, Supriya|,|Scripps Research Inst, La Jolla, CA|
|4084|,|St Louis, Cathy|,|Nova Southeastern University, Fort Lauderdale, FL|
|SGP|,|St. George Hyslop, Peter|,|University of Toronto, Toronto, Ontario, Canada|
| 813|,|Stabler, Timothy|,|Indiana University Northwest, Gary, IN|
|3462|,|Stadler, Marc|,|Helmholtz Centre for Infection Research, Braunschweig, Germany|
|3417|,|Stamatiou, George|,|University of Ontario, Toronto, ON, Canada|
|3051|,|Stamm, Joyce|,|University of Evansville, Evansville, IN|
| 203|,|Standish, Timothy|,|Geoscience Reseach Institute, Loma Linda, CA|
|UX|,|Stanfield, Gillian|,|University of Utah, Salt Lake City, UT|
|UD|,|Starr, Dan|,|University of California, Davis, CA|
|2716|,|Staton, Pamela|,|Marshall University, Huntington, WV|
| 312|,|Stavredes, Tina|,|Normandale Community College, Bloomington, MN|
|2200|,|Stear, Jeffrey|,|Humboldt University, Berlin, Germany|
|1457|,|Stearns, Tim|,|Stanford University, Stanford, CA|
|4194|,|Steck, Todd|,|University of North Carolina, Charlotte, NC|
|4131|,|Steele, Louise|,|Kent State University, Salem, OH|
|3907|,|Stefani, Giovanni|,|University of Trento, Trento, Italy|
|2856|,|Stefani, Stefania|,|University of Catania, Italy|
|LQ|,|Stein, Lincoln|,|Cold Spring Harbor Laboratory, Cold Spring Harbor, NY|
|FAS|,|Steiner, Florian|,|University of Geneva, Geneva, Switzerland|
| 560|,|Steinmann|,|University of Zuerich, Switzerland|
|2251|,|Stemple, Derek|,|Wellcome Trust Sanger Institute, Hinxton, Cambridge, UK|
|4267|,|Stepanek, Laurie|,|American University, Washington, DC|
|NH|,|Stern, Michael|,|Northeastern Illinois University, Chicago, IL|
|PS|,|Sternberg, Paul|,|California Institute of Technology, Pasadena, CA|
|STA|,|Stetak, Attila|,|University of Basel, Basel, Switzerland|
|XS|,|Steven, Robert|,|University of Toledo, Toledo, OH|
| 977|,|Stevens|,|Scripps Research Institute, La Jolla, CA|
|3705|,|Steyen, Quintin|,|University of Lethbridge, Lethbridge, Alberta, Canada|
|BCW|,|Stigloher, Christian|,|Universitat Wurzburg, Wurzburg, Germany|
| 268|,|Stiller, Tammy|,|Biology Department, Westminster College, Fulton, MO|
|DT|,|Stinchcomb, Dan|,|Synergen, Inc., Boulder, CO|
| 727|,|Stock, Patricia|,|University of Arizona, Tucson, AZ|
|3336|,|Stockwell, Brent|,|Columbia University, New York, NY|
|3710|,|Stoltzfus, Jonathan|,|Hollins University, Roanoke, VA|
|3837|,|Stoltzfus, Jonathan|,|Hollins University, Roanoke, VA|
|2282|,|Stoorvogel, Willem|,|Utrecht University, Utrecht, The Netherlands|
|1453|,|Stormberg, Angela|,|Idaho National Engineering and Environmental Laboratory, Idaho Falls, ID|
|2688|,|Strands, Mike|,|University of Georgia, Athens, GA|
|1734|,|Straney, David|,|University of Maryland, College Park, MD|
|VP|,|Strange, Kevin|,|Mt Desert Island Bio Lab, Salisbury Cove, ME|
|3205|,|Strassmann, Joan  & Queller, David|,|Washington University, St. Louis, MO|
| 823|,|Stratagene, Inc.|,|Cedar Creek, TX|
|3085|,|Straud, Sarah|,|St. Augustine's College, Raleigh, NC|
|QA|,|Streit, Adrian|,|MPI for Developmental Biology, Tuebingen, Germany|
|2784|,|Strieter, Eric|,|University of Wisconsin, Madison, WI|
|VA|,|Stringham, Eve|,|Trinity Western University, Langley, BC, Canada|
| 675|,|Strippoli, Pierluigi|,|University of Bologna, Germany|
|2156|,|Strittmatter, Stephen|,|Yale University, New Haven, CT|
|1883|,|Stroedick, Martin|,|Max Delbruck Centrum, Berlin, Germany|
|SS|,|Strome, Susan|,|University of California, Santa Cruz, CA|
|2435|,|Stuart, Jeff|,|Brock University, St. Catharines, Ontario, Canada|
|2192|,|Stuart, Lynda|,|Massachusetts General Hospital, Boston, MA|
|ZS|,|Sturzenbaum, Stephen|,|King's College, London, England|
|2739|,|Su, Chih-Mao|,|National Defense Medical Center, Taipei, Taiwan|
|3160|,|Su, ZhengChang|,|University of North Carolina, Charlotte, NC|
|IT|,|Subramaniam, Kuppuswamy|,|Indian Institute of Technology, Kanpur, India|
|1703|,|Suda, Hitoshi|,|Tokai University, Shizuoka, Japan|
|SB|,|Sudhaus, Walter|,|Freie Universitaet Berlin, Berlin, Germany|
|2979|,|Sudhof, Tom|,|Stanford University, Palo Alto, CA|
|BD|,|Suetsugu, Shiro|,|University of Tokyo, Tokyo, Japan|
| 730|,|Sugahara, Kazuyuki|,|Dept of Biochemistry, Kobe Pharmaceutical University, Kobe, Japan|
|MSU|,|Suganuma, Masami|,|Research Inst for Clinical Oncology, Saitama, Japan|
|2820|,|Sugi, Masahito|,|Hokkaido Research Inst Nissei, Eniwa City, Japan|
|3556|,|Sugi, Takuma|,|Kyoto University, Kyoto, Japan|
|SA|,|Sugimoto, Asako|,|Tohoku University, Sendai, Japan|
|3690|,|Sugita, Shuzo|,|University of Toronto, Toronto, Canada|
|2094|,|Sugiyama, Tomoyasu|,|Tokyo University of Technology, Tokyo, Japan|
|3266|,|Suh, Jin Kyo|,|Simon Fraser University, Burnaby, BC, Canada|
|2509|,|Suhr, Timothy|,|University of Nebraska, Lincoln, NE|
|1906|,|Suk, Song Ha|,|Seoul City University, Seoul, South Korea|
|1325|,|Sukumaran, Sunil|,|Institute of Molecular and Cell Biology, Singapore|
|4189|,|Sulistiyani, Sapardi|,|Bogor Agricultural University, Bogor, Indonesia|
|2154|,|Sullivan, Chris|,|University of Texas, Austin, TX|
|2139|,|Sullivan, Ruth|,|University of Wisconsin, Madison, WI|
|4114|,|Sullivan-Brown, Jessica|,|West Chester University, West Chester, PA|
| 779|,|Sulston, Ingrid|,|New York Hall of Sciences, Corona, NY|
|1431|,|Suman, Deb|,|Harvard School of Public Health, Boston, MA|
|1893|,|Summers,|,|University of Utah, Salt Lake City, UT|
| 991|,|Sun, Gongqin|,|University of Rhode Island, Kingston, RI|
| 920|,|Sun, Hong|,|Nevada Cancer Institute, Las Vegas, NV|
|3440|,|Sun, Jinghua|,|Chinese Academy of Sciences, Beijing, China|
|JRS|,|Sun, Jingru|,|Washington State University, Spokane, WA|
|3767|,|Sun, Longmei|,|Southeast University, Nanjing, Jiangsu, China|
|2844|,|Sun, Ming|,|Huazhong Agricultural University, Wuhan, China|
|4276|,|Sun, Xiaojaun|,|Henan University School of Medicine, Kaifeng, Henan, China|
|4100|,|Sun, Yongxue|,|South China Agricultural University, Guangzhou, China|
|2577|,|Sunahara, Geoffrey|,|National Research Council Canada, Montreal, Quebec, Canada|
|UP|,|Sundaram, Meera|,|University of Pennsylvania, Philadelphia, PA|
|3682|,|Sundaram, Shobana|,|Virginia Commonwealth University, Richmond, VA|
|4038|,|Sundararaj, P|,|Bharathiar University, Tamilnadu, India|
|2173|,|Sunde, Roger|,|University of Wisconsin, Madison, WI|
|3681|,|Sung, Backil|,|Pacific Union College, Angwin, CA|
|3106|,|Suo, Satoshi|,|University of Tokyo at Komaba, Tokyo, Japan|
|1071|,|Supattapone, Surachai|,|Dartmouth Medical School, Hanover, NH|
|1501|,|SuperArray Bioscience Corporation|,|Frederick, MD|
|KA|,|Suprenant, Kathy|,|University of Kansas, Lawrence, KS|
| 521|,|Susman, Kate|,|Vassar College, Poughkeepsie, NY|
|4153|,|Suthammarak, Wichit|,|Mahidol University, Bangkok, Thailand|
|1616|,|Sutphin, Patrick|,|Stanford University, Stanford, CA|
|1671|,|Sutton, Dennis|,|New Mexico State University, Las Cruces, NM|
|HST|,|Suzuki, Hiroshi|,|University of Toronto, Toronto, Ontario, Canada|
|2808|,|Suzuki, Michiyo|,|Japan Atomic Energy Agency, Gunma, Japan|
| 575|,|Suzuki, Norio|,|Nagoya University, Nagoya-shi, Japan|
|2345|,|Suzuki, Takashi|,|Nagoya City University, Nagoya, Japan|
|4094|,|Swanwick, Catherine|,|Biomedical Research Academy in Neuroscience, Oakton, VA|
|2637|,|Swedlow, Jason|,|Unversity of Dundee, Dundee, Scotland, UK|
| 523|,|Sweet, Melody|,|Syracuse University, Syracuse, NY|
|OE|,|Swoboda, Peter|,|Karolinska Institute, Huddinge, Sweden|
|3400|,|Swope, Susan|,|Plymouth State University, Plymouth, NH|
|2614|,|Sylvean Biotech Ltd.|,|Pretoria, Gauteng, South Africa|
| 972|,|Syngenta Inc.|,|Research Triangle Park, NC|
|BRF|,|Syntichaki, Popi|,|Biomed Research Found, Academy of Athens, Greece|
|3248|,|Syosset HS|,|Syosset High School, Syosset, NY|
|2234|,|System Biosciences|,|Mountain View, CA|
|3107|,|Szabo, Csaba|,|University of Texas Medical Branch, Galveston, TX|
|JY|,|Sze, Ji Ying|,|Albert Einstein College of Medicine, Bronx, NY|
|CC|,|Szewczyk, Nathaniel|,|University of Nottingham, Derby, England|
|ESZ|,|Sztul, Elizabeth|,|University of Alabama, Birmingham, AL|
|4324|,|Tabach, Yuval|,|The Hebrew University-Hadassah Medical School, Jerusalem, Israel|
|ZT|,|Tabara, Hiroaki|,|University of Tsukuba, Tsukuba, Japan|
| 804|,|Tabish, M|,|University of Liverpool, Liverpool, U.K.|
|TF|,|Tabuse, Yo|,|NEC Fundamental Research Labs, Tsukuba, Japan|
|4066|,|Taghibiglou, Changiz|,|University of Saskatchewan, Saskatoon, Saskatchewan, Canada|
|ST|,|Takagi, Shin|,|Nagoya University, Nagoya, Japan|
|2798|,|Takahashi, Mayumi|,|Tokyo Metro Inst of Gerontology, Tokyo, Japan|
|1995|,|Takano, Syuichi|,|Kanazawa University, Kanazawa, Japan|
| 514|,|Takemoto, Tadashi|,|Shiga University of Medical Science, Shiga, Japan|
|3345|,|Takeshima, Hideo|,|Miyazaki University of Japan, Miyazake, Japan|
|3654|,|Talley, Jennell|,|Georgia Gwinnett College, Lawrenceville, GA|
|4228|,|Tan, Boon Khai|,|Universiti Sains Malaysia, Penang, Malaysia|
|3648|,|Tan, Boon-Khai|,|Malaysian Inst of Pharmaceuticals & Nutraceuticals, Penang, Malaysia|
|WE|,|Tan, Man-Wah|,|Stanford University School of Medicine, Stanford, CA|
|PW|,|Tan, Patrick|,|National Cancer Center, Singapore|
|1228|,|Tanabe, Hiroyuki|,|Kinki University, Nara, Japan|
| 763|,|Tanabe, Noriko|,|Daiichi Hoiku Junior College, Fukuoka, Japan|
|2620|,|Tanaka, Akiko|,|Yokohama Institute, RIKEN, Yokohama, Japan|
|3308|,|Tanaka, Masahiro|,|Daiichi Sankyo RD Novare Co., Ltd., Tokyo, Japan|
| 457|,|Tang, Liang|,|Heska Co., Fort Collins, CO|
|3675|,|Tang, Lili|,|University of Georgia, Athens, GA|
|4249|,|Tang, Wei|,|University of Wisconsin, Madison, WI|
|2476|,|Tang, Wei-Jen|,|University of Chicago, Chicago, IL|
|2144|,|Tanji, Takahiro|,|Iwate Medical University, Iwate, Japan|
|4205|,|Tanokura. Masaru|,|University of Tokyo, Tokyo, Japan|
| 962|,|Tarakhovsky,|,|The Rockefeller University, New York, NY|
|DET|,|Tarr, DE|,|Midwestern University, Glendale, AZ|
|ZJ|,|Taru, Hidenori|,|Hokkaido University, Japan|
|XT|,|Taschner, Peter|,|Leiden University, Leiden, The Netherlands|
|1393|,|Taub, Frieda|,|University of Washington, Seattle, WA|
|STE|,|Taubert, Stefan|,|Unviersity of British Columbia, Vancouver, BC, Canada|
|2118|,|Tavazoie,|,|Princeton University, Princeton, NJ|
|IR|,|Tavernarakis, Nektarios|,|IMBB, Heraklion, Crete, Greece|
| 491|,|Tavernier, Paul|,|Bethel College, St. Paul, MN|
|2877|,|Tawata, Shinkichi|,|University of the Ryukyus, Japan|
|1920|,|Tayco, Crimson|,|University of Philippines, Quezon City, Philippines|
|3279|,|Taylor, Barbara|,|University of Alaska, Fairbanks, AK|
|2099|,|Taylor, Chris|,|Donald Danforth Plant Science Center, St. Louis, MO|
|4342|,|Taylor, Jennifer|,|S Carolina Governor's School for Science & Math, Hartsville, SC|
| 792|,|Taylor, Kyle|,|Auburn University, Montgomery, AL|
|1317|,|Taylor, Rebecca|,|Trinity College, Dublin, Ireland, UK|
|RCT|,|Taylor, Rebecca|,|MRC - LMB, Cambridge, UK|
|2813|,|Taylor, Richard|,|Univ Texas, San Antonio, TX|
|1506|,|Tearle, Adam|,|Tearle A, Unviersity of California, San Diego, CA|
|1402|,|Teicher, Harald|,|Landesumweltamt NRW, Essen, Germany|
|2758|,|Tellez-Isaias, Guillermo|,|Univ of Arkansas, Fayetteville, AR|
|3901|,|Templeton, Dennis|,|University of Virginia Medical School, Charlottesville, VA|
| 891|,|Tendeng, Christian|,|University of Hong Kong, Hong Kong|
|2347|,|Teng, To|,|Queen Mary University of London, London, England|
|3554|,|Tenlen, Jenny|,|Seattle Pacific University, Seattle, WA|
|1494|,|Tenuta, Mario|,|University of Manitoba, Winnipeg, Manitoba, Canada|
|1846|,|Teo, Jeanette|,|National University Hospital, Singapore|
|EEV|,|Teotonio, Henrique|,|Institut de Biologie de l'Ecole Normale Superieure, Paris, France|
| 431|,|Tepass, Ulrich|,|University of Toronto, Ontario|
|2982|,|Teplitski, Max|,|University of Florida, Gainseville, FL|
| 641|,|Terasaki, Mark|,|Univ of Connecticut Health Center, Farmington, CT|
|TL|,|Tessier-Lavigne, Marc|,|University of California, San Francisco, CA|
|2333|,|Testi, Roberto|,|University of Rome Tor Vergata, Rome, Italy|
|UZ|,|Thacker, Colin|,|University of Utah, Salt Lake City, UT|
|3037|,|Thaler, Sarah|,|Schmahl Science Workshop, San Jose, CA|
|1572|,|Thanabalu, Thirumaran|,|Nanyang Technological University, Singapore|
| 926|,|Thatcher, Jack|,|West Virginia School of Osteopathic Medicine,|
|4122|,|Thekkuveettil, Anoop|,|Sree Chitra Tirunal Inst for Med Sci & Tech, Trivandrum, India|
|3829|,|Thibault, Guillaume|,|Nanyang Technological University, Singapore|
|4222|,|Thieringer, Heather|,|Princeton University, Princeton, NJ|
|FF|,|Thierry-Mieg, Danielle|,|NCBI, Bethesda, MD|
|2664|,|Thines, Marco|,|University of Hohenheim, Stuttgart, Germany|
|2454|,|Thoemke, Kara|,|College of St. Scholastica, Duluth, MN|
|JT|,|Thomas, Jim|,|University of Washington, Seattle|
|KT|,|Thomas, Kelley|,|University of New Hampshire, Durham, NH|
| 775|,|Thomas, Pam|,|Lubbock High School, Lubbock, TX|
|3747|,|Thomas, Renjan|,|Universiti Putra Malaysia, Putrajaya, Malaysia|
|3924|,|Thomas, William|,|Colby-Sawyer College, New London, NH|
|1661|,|Thompson, Eric|,|University of Bergen, Bergen, Norway|
|2131|,|Thompson, Henry|,|Colorado State University, Fort Collins, CO|
|2072|,|Thompson, Joseph|,|Franklin & Marshall College, Lancaster, PA|
|1067|,|Thomsen, Line|,|Royal Veterinary and Agricultural University, Frederiksberg, Denmark|
|1156|,|Thomson, Valeri|,|Bard College, Annandale-on-Hudson, NY|
|3603|,|Thonart, Philippe|,|University of Liege, Liege, Belgium|
|2198|,|Thorens, Bernard|,|University of Lausanne, Lausanne, Switzerland|
|3056|,|Thornton, Darlene|,|Assumption College, Worcester, MA|
|4095|,|Thurber, Carrie|,|Abraham Baldwin Agricultural College, Tifton, GA|
|3531|,|Tian, Hua|,|Ocean University of China, Qingdao, China|
| 616|,|Tianwei, Li|,|National University of Singapore, Singapore|
|XF|,|Tijsterman, Marcel|,|Hubrecht Laboratory, Utrecht, The Netherlands|
|WC|,|Tilmann, Christopher|,|Loyola College, Baltimore, MD|
|XX|,|Timmons, Lisa|,|University of Kansas, Lawrence, KS|
|1132|,|Tindale, Hal|,|Canberra, ACT, Australia|
|3592|,|Tinglu, Ning|,|CAS, Shanghai Jiao Tong University, Shanghai, China|
|1413|,|Tirasophon, Witoon|,|City of Hope Medical Center, Duarte, CA|
|4069|,|Tirrell, David|,|California Institute of Technology, Pasadena, CA|
|HT|,|Tissenbaum, Heidi|,|University of Massachusetts, Worcester, MA|
|1866|,|Titanji, Vincent|,|University of Buea, Buea, Cameroon|
|DU|,|Titus, Meg|,|University of Minnesota, Minneapolis, MN|
| 498|,|Todoriki, Masahiko|,|Osaka University, Osaka, Japan|
|3657|,|Toh, Shu Qin|,|Queensland Institute of Medical Research, Queensland, Australia|
|2271|,|Tokuoka, Suzumi|,|University of Tokyo, Tokyo, Japan|
|3280|,|Tollrian, Ralph|,|Ruhr University, Bochum, Germany|
|2073|,|Tomoyasu, Yoshinori|,|Kansas State University, Manhattan, KS|
|2835|,|Ton-That, Hung|,|Houston Medical School, Houston, TX|
|3894|,|Topf, Ulrike|,|Int'l Inst of Molecular & Cell Biology, Warsaw, Poland|
|2428|,|Topp, Ed|,|Agriculture & Agri-Food Canada, London, Ontario, Canada|
|1137|,|Torrey Mesa Research Institute|,|San Diego, CA|
|1514|,|Tort, Jose|,|Universidad de la Republica, Montevideo, Uruguay|
| 597|,|Tosi, Solveig|,|Universita di Pavia, Pavia, Italy|
|2460|,|Toth, Charles|,|Providence College, Providence, RI|
|4268|,|Toti, Luigi|,|Sanofi-Aventis Deutschland GmbH, Frankfurt am Main, Germany|
|XY|,|Tovar, Karlheinz|,|EleGene, Martinsried, Germany|
|2308|,|Tovmash, AV|,|Karpov Institute, Moscow, Russia|
|1178|,|Tran, Joseph|,|Indiana University of Pennsylvania, Indiana, PA|
|1898|,|Traunspurger, Walter|,|Bielefeld University, Bielefeld, Germany|
|MF|,|Treinin, Millet|,|The Hebrew University, Jerusalem, Israel|
|PA|,|Trent, Carol|,|Western Washington University, Bellingham, WA|
|3096|,|Tresser, Jason|,|Biola University, La Mirada, CA|
|4235|,|Trevisson, Eva|,|University of Padova, Padova, Italy|
|ATR|,|Trifunovic, Aleksandra|,|University of Cologne, Cologne, Germany|
|  77|,|Tripp, John|,||
|ERT|,|Troemel, Emily|,|University of California, San Diego, CA|
|2809|,|Troiano, Stephanie|,|South Conn St Univ, New Havan, CT|
|3932|,|Trott, Tim|,|Southern Adventist University, Collegedale, TN|
|TZ|,|Trowell, Stephen|,|CSIRO Entomology, Canberra, ACT, Australia|
|2611|,|Trowell, Stephen|,|CSIRO, Acton, Australia|
| 222|,|Trump, Benjamin|,|University of Maryland, Baltimore|
|TRZ|,|Trzepacz, Chris|,|Murray State University, Murray, KY|
|4054|,|Tsai, Francis|,|Baylor College of Medicine, Houston, TX|
|3075|,|Tsai, Lisa|,|Hong Jing Co. Ltd., Taipei, Taiwan|
|3670|,|Tse, Yu Chung|,|South University of Science and Technology of China, Shen Zhen, China|
|1010|,|Tseng, Jeannie|,|United Nations International School, New York, NY|
|2349|,|Tsou, Bryan|,|Memorial Sloan-Kettering Cancer Center, New York, NY|
|2686|,|Tsubaki, Motonari|,|Kobe University, Kobe, Japan|
|1460|,|Tsuchiya, Takahide|,|Sophia University, Tokyo, Japan|
|1553|,|Tsuda, Hiroshi|,|Baylor College of Medicine, Houston, TX|
| 723|,|Tsukita, Shoichiro|,|Kyoto University, Kyoto, Japan|
|3796|,|Tsutsui, Neil|,|University of California, Berkeley, CA|
|HTU|,|Tu, Haijun|,|Hunan University, Hunan, China|
|VB|,|Tuck, Simon|,|University of Umea, Sweden|
|3492|,|Tucker Mack, Jody|,|College of Charleston, Charlesdton, SC|
|JMT|,|Tullet, Jennifer|,|University of Kent, Kent, England|
|2653|,|Tumer, Nilgun|,|Rutgers University, New Brunswick, NJ|
| 699|,|Tunlid, Anders|,|Lund University, Lund, Sweden|
|TC|,|Turnbull, Jeremy and Kinnunen, Tarja|,|University of Birmingham, Birmingham, UK|
| 752|,|Turner, Helen|,|Harvard Medical School, Boston, MA|
|1245|,|Turner, James|,|Scripps Research Institute, La Jolla, CA|
|4023|,|Turner, Michael|,|Mount St. Mary's University, Emmitsburg, MD|
|1273|,|Turner, Paul|,|Yale University, New Haven, CT|
|1500|,|Turse, Carol|,|Texas A & M University, College Station, TX|
|BAT|,|Tursun, Baris|,|Berlin Institute for Medical Systems Biology (BIMSB), Berlin, Germany|
| 885|,|Tyers Lab|,|Mt Sinai Hospital, Lunenfeld Research Institute, Toronto, Ontario, Canada|
|2698|,|Tyler, Jessica|,|University of Colorado, Denver, CO|
| 358|,|Tylka, Greg|,|Iowa State University, Ames, IA|
|3149|,|Tyne, Bill|,|NERC Centre for Ecology and Hydrology, Wallingford, UK|
|3212|,|TyraTech, Inc.|,|TyraTech, Inc., Morrisville, NC|
|2087|,|Tyratech Laboratory|,|Melbourne, FL|
|YBT|,|Tzur, Yonathan|,|The Hebrew University of Jerusalem, Jerusalem, Israel|
|4328|,|Uddin, Shahab|,|Center for Cellular and Molecular Platforms, Bangalore, India|
|4163|,|Ueda, Mitsuhiro|,|Osaka Prefecture University, Sakai, Osaka, Japan|
|3244|,|Ueki, Tatsuya|,|Hiroshima University, Hiroshima, Japan|
|NU|,|Ueno, Naoto|,|National Institute for Basic Biology, Okazaki, Japan|
|2732|,|Unguez, Graciela|,|New Mexico State University, Las Cruces, NM|
|1347|,|UniCrop Ltd.|,|Finland|
|1032|,|Unnasch, Thomas|,|University of Alabama at Birmingham, AL|
|1203|,|Unni, CBA|,|Damodharan College of Science, Tamilnadu, India|
|2587|,|Unrine, Jason|,|University of Kentucky, Lexington, KY|
|3449|,|Upadhyay, Atul|,|Makise Lifeup Laboratory Co. Ltd., Okinawa, Japan|
|DUP|,|Updike, Dustin|,|Mt Desert Island Bio Lab, Salisbury Cove, ME|
| 985|,|Urushiyama, Seiichi|,|Tokyo Medical and Dental University, Tokyo, Japan|
|2677|,|Urwin, Peter|,|University of Leeds, Leeds, UK|
| 864|,|Ushida, Chisato|,|Hirosaki University, Hirosaki, Japan|
| 531|,|VWR Scientific|,|Bridgeport, NJ|
|1440|,|Vaca, Sergio|,|Universidad Nacional Autonoma de Mexico, Los Reyes Iztacala, Mexico|
|2049|,|Valdivieso, Alfonso|,|Public Health Agency of Canada, Guelph, ON, Canada|
|RDV|,|Vale, Ron|,|University of California, San Francisco, CA|
|2670|,|Valencia, Arnubio|,|University of Nebraska, Lincoln, NE|
|1068|,|Valentine, Joan|,|UCLA, Los Angeles, CA|
|2172|,|Valentine, Sonya|,|Pasadena City College, Pasadena, CA|
|1957|,|Valles, Steven|,|USDA-ARS, Gainesville, FL|
|HN|,|Vallier, Laura|,|Hofstra University, Hempstead, NY|
|1384|,|Valvano, Miguel|,|University of Western Ontario, London, Ontario, Canada|
|CVB|,|Van Buskirk, Cheryl|,|California State University Northridge, Northridge, CA|
|VD|,|Van Doren, Kevin|,|Syracuse University, Syracuse, NY|
|VWL|,|Van Epps, Heather|,|Western Washington University, Bellingham, WA|
|MVG|,|Van Gilst, Marc|,|Fred Hutchinson Cancer Research Center, Seattle, WA|
| 621|,|Van Laer, Lut|,|University of Antwerp, Belgium|
|2207|,|Van Oudenaarden, Alexander|,|MIT, Cambridge, MA|
|JVR|,|Van Raamsdonk, Jeremy|,|Van Andel Research Institute, Grand Rapids, MI|
|VN|,|Van Tol, Hubert|,|Clarke Division, Univ of Toronto, Toronto, Canada|
|WV|,|Van Voorhies, Wayne|,|New Mexico State University, Las Cruces, NM|
|3434|,|Van Wynsberghe, Priscilla|,|Colgate University, Hamilton, NY|
|4134|,|Van Wynsberghe, Priscilla|,|Colgate University, Hamilton, NY|
|MKV|,|VanHoven, Miri|,|San Jose State University, San Jose, CA|
|3567|,|Vanapalli, Siva|,|Texas Tech University, Lubbock, TX|
|3793|,|VandenHeuvel, Daniel|,|Wood River High School, Hailey, Idaho|
|1785|,|Vandenesch, Francois|,|University of Lyon, Lyon Cedex, France|
|JV|,|Vanfleteren, Jacques|,|University of Gent, Gent, Belgium|
|HU|,|Varkey, Jacob|,|Humboldt State University, Arcata, CA|
|2520|,|Vashlishan Murray, Amy|,|College of the Holy Cross, Worcester, MA|
|VVR|,|Vasquez, Valeria|,|University of Tennessee Health Science Center, Memphis, TN|
| 259|,|Vassilatis, Demetrios|,|Baylor College of Medicine, Houston, TX|
|2827|,|Vassilatis, Demetrios|,|Biomed Research Found, Academy of Athens, Greece|
| 357|,|Vassilieva, Larissa|,|University of Utah, Salt Lake City, UT|
|VF|,|Vatamaniuk, Olena|,|Cornell University, Ithaca, NY|
|3686|,|Vatolin, Sergei|,|Taussig Cancer Center, Cleveland Clinic Foundation, Cleveland, OH|
|2503|,|Vattam, Dhiraj|,|Texas State University, San Marcos, TX|
|1446|,|Vaughan, Martin|,|Unilever Research, Bedford, UK|
| 592|,|Vaz Gomes, Ana|,|Centre for Genomics Research, Stockholm, Sweden|
|RVM|,|Vazquez-Manrique, Rafael|,|IIS- La Fe, Valencia, Spain|
|VE|,|Veal, Elizabeth|,|Newcastle University, Newcastle upon Tyne, Newcastle, UK|
|2146|,|Vella, Monica|,|Eotvos Lorand University, Budapest, Hungary|
|TTV|,|Vellai, Tibor|,|Lorand University, Budapest, Hungary|
|1469|,|Vendetti, Charles|,|National Human Genome Research Institute, NIH, Bethesda, MD|
|1860|,|Venkatesh, B|,|Institute of Molecular and Cell Biology, Singapore|
|3669|,|Venkitanarayanan, Kumar|,|University of Connecticut, Storrs, CT|
|LV|,|Venolia, Lee|,|Williams College, Williamstown, MA|
|1517|,|Ventura, Natascia|,|University of Colorado, Boulder, CO|
|3555|,|Ventura, Natascia|,|Heinrich Heine University, Düsseldorf, Germany|
|2132|,|Vera, Diana|,|Instituto Geografico Agustin Codazzi, Bogota, Colombia|
|3896|,|Verdine, Gregory|,|Warp Drive Bio, LLC, Cambridge, MA|
|2070|,|Vergunst, Annette|,|INSERM, Nimes, France|
|PVX*|,|Verhey, Kristen|,|University of Michigan, Ann Arbor MI|
|2136|,|Vermeulen,|,|Erasmus MC, Rotterdam, The Netherlands|
|3895|,|Vermulst, Marc|,|University of Pennsylvania, Philadelphia, PA|
|3366|,|Vernon, Jeffrey|,|University of Westminster, London, UK|
|2609|,|Vetrone, Sylvia|,|Whittier College, Whittier, CA|
|1784|,|ViaLactia Biosciences|,|Auckland, New Zealand|
|MV|,|Vidal, Marc|,|Dana-Farber Cancer Institute, Harvard Medical School, Boston, MA|
|AVG|,|Vidal-Gadea, Andres Gabriel|,|Illinois State University, Illinois, IL|
|1216|,|Vielkind, Juergen|,|British Columbia Cancer Research Center, Vancouver, BC, Canada|
|1924|,|Vijayanandraj, VR|,|University of Madras, Chennai, India|
|1800|,|Vijayaratnam, Vijhee|,|Sri Sathya Sai Institute of Higher Learning, Andhrapredesh, India|
|DVG|,|Vilchez, David|,|CECAD-University of Cologne, Cologne, Germany|
|1583|,|Villaneuva, Alberto|,|Institu Catala d'Oncologia, Barcelona, Spain|
|1544|,|Villanueva, Alberto|,|Institut Catala d'Oncologia, Barcelona, Spain|
|3508|,|Villenave, Cecile|,|ELISOL Environnement, Montpellier, France|
|AV|,|Villeneuve, Anne|,|Stanford University Medical School, Stanford, CA|
|MEV|,|Viney, Mark|,|University of Bristol, UK|
|2100|,|Visser, Aline|,|Gent University, Merelbeke, Belgium|
|3759|,|Vita-More, Natasha|,|Alcor Life Extension, Fontana, CA|
|1370|,|Vivanco, Jorge|,|Colorado State University, Fort Collins, CO|
|1507|,|Vivanco, Jorge|,|Colorado State University, Fort Collins, CO|
|3789|,|Vizmanos, Jose Luis|,|University of Navarra, Pamplona, Spain|
|3379|,|Vocadlo, David|,|Simon Fraser University, Burnaby, BC, Canada|
|BT|,|Vogel, Bruce|,|University of Maryland, Baltimore, MD|
|3026|,|Vogel-Ciernia, Annie|,|University of California, Irvine, CA|
|4045|,|Vogt, Kimberly|,|Marian University, Indianapolis, IN|
|3519|,|Voigt, Kerstin|,|Friedrich Schiller University Jena, Jena, Germany|
|3633|,|Voigt, Oliver|,|Ludwig-Maximilians-Universität München, Munich, Germany|
|3787|,|Voisine, Cindy|,|Northeastern Illinois University, Chicago, IL|
|3700|,|Voller, Jiri|,|Palacky University, Olomouc, Czech Republic|
|1340|,|Voloudakis, Andreas|,|Agricultural University of Athens, Athens, Greece|
|2147|,|Vona-Davis, Linda|,|West Virginia University, Morgantown, WV|
|3637|,|Voronin, Denis|,|Liverpool School of Tropical Medicine, Liverpool, U.K.|
|UMT|,|Voronina, Ekaterina|,|University of Montana, Missoula, MT|
|3999|,|Vosshall, Leslie|,|Rockefeller University, New York, NY|
|3391|,|Vulpe, Chris|,|University of California, Berkeley, CA|
| 689|,|Wacker, Irene|,|MIP fur Medizinische Forschung, Heidelberg, Germany|
|IN|,|Waddle, Jim|,|UTSW Medical Center, Dallas, TX|
|1131|,|Wadsworth, Gregory|,|Buffalo State College, Buffalo, NY|
|IM|,|Wadsworth, William|,|UMDNJ, Piscataway, NJ|
|3241|,|Wager, Robert|,|Vancouver Island University, Nanaimo BC, Canada|
|2838|,|Wagner, Lansing|,|Harvard University, Cambridge, MA|
|OIW|,|Wagner, Oliver|,|National Tsing Hua University, Hsinchu, Taiwan|
|1624|,|Wahl, Christina|,|Wells College, Aurora, NY|
|1981|,|Waikel, Rebekah|,|Northeastern Illinois University, Chicago, IL|
|WKB|,|Wakabayashi, Tokumitsu|,|Iwate University, Japan|
|4047|,|Wakelam, Michael|,|The Babraham Institute, Cambridge, UK|
|1782|,|Wako Chemicals USA|,|Richmond, VA|
|1456|,|Walajtys-Rode, Elizabeth|,|Rzeszow Technical University, Rzeszow, Poland|
|3647|,|Walczynska, Marta|,|Lodz Uniwersity of Technology, Lodz, Poland|
|VL|,|Walhout, Marian|,|University of Massachusetts, Worcester, MA|
|WAL|,|Walker, Amy|,|UMass Medical School, Worcester, MA|
|2604|,|Walker, Larry|,|Oklahoma Baptist University, Shawnee, OK|
|2442|,|Wall, Diana|,|Colorado State University, Fort Collins, CO|
| 847|,|Wallace, Douglas|,|Emory University, Atlanta, GA|
|1753|,|Wallenfang, Matthew|,|Barnard College, New York, NY|
|2612|,|Wallingford, John|,|University of Texas, Austin, TX|
|4091|,|Walsh, Heidi|,|Wabash College, Crawfordsville, IN|
|YU|,|Walston, Tim|,|Truman State University, Kirksville, MO|
|KMW|,|Walstrom, Katherine|,|New College of USF, Sarasota, FL|
|ER|,|Walthall, Bill|,|Georgia State University, Atlanta|
|2058|,|Walz, G|,|University Hospital, Freiburg, Germany|
|1933|,|Wan, Daisy|,|University of Science and Arts of Oklahoma, Chickasha, OK|
|1139|,|Wan, David|,|The Chinese University of Hong Kong, Hong Kong, China|
|2373|,|Wander, Michelle|,|University of Illinois at Urbana-Champaign, Urbana, IL|
|1546|,|Wang, Aoxue|,|University of Guelph, Guelph, Ontario, Canada|
|1607|,|Wang, Bi Chen|,|University of Georgia, Athens, GA|
|3101|,|Wang, Changhai|,|Yantai University,Shandong Province, China|
|2542|,|Wang, Changlu|,|Tianjin University of Science & Technology, Tianjin, China|
|3983|,|Wang, Chao-Wen|,|Inst of Plant & Microbial Biology, Academia Sinica, Nankang, Taipei|
|2663|,|Wang, Danqiao|,|China Academy of Chinese Medical Sciences, Beijing, China|
|WUM|,|Wang, David|,|Washington University School of Medicine, St. Louis, MO|
|WDY|,|Wang, Dayong|,|Southeast University Medical School, Nanjing, China|
|4090|,|Wang, Degui|,|Lanzhou University Medical School, Lanzhou, China|
|3917|,|Wang, Fengzhong|,|Inst of Agro-Products Processing Science & Tech CAAS, Beijing, China|
|1676|,|Wang, Genhong|,|Southwest Agricultural University, Chingqing, China|
| 463|,|Wang, Grace|,|Ocean Township High School, Ocean, NJ|
|2845|,|Wang, Guan|,|Jinlin University, Changchun, China|
|GXW|,|Wang, Guo-Xiu (Julie)|,|Huazhong Normal University, Wuhan, China|
|4281|,|Wang, Hongbing|,|Tongji University, Shanghai, China|
|HDW|,|Wang, Horng-Dar|,|National Tsing Hua University, Hsinchu, Taiwan|
|3020|,|Wang, Jianxun|,|Chinese Academy of Sciences, Beijing, China|
|4338|,|Wang, Jin|,|Harbin Institute of Technology University, Weihai, China|
|IW|,|Wang, Jiou|,|Johns Hopkins University, Baltimore, MD|
|BRC|,|Wang, John|,|Academic Sinica, Taipei, Taiwan|
|LWA|,|Wang, Lei|,|The Salk Institute, La Jolla, CA|
|3210|,|Wang, Lishun|,|Shanghai Jiao-Tong University School of Medicine, Shanghai, China|
|MCW|,|Wang, Meng|,|Baylor College of Medicine, Houston, TX|
|3546|,|Wang, Ning|,|University of Virginia's College at Wise, Wise, VA|
|1509|,|Wang, Shiao|,|University of Southern Mississippi, Hattiesburg, MS|
|2619|,|Wang, Shunchang|,|Huainan Normal University, Huainan, Anhui, China|
|2180|,|Wang, WenJian|,|Fudan University, HuaSha Hospital, Shanghai, China|
|3402|,|Wang, X|,|Wuhan University, Wuhan, China|
|XW|,|Wang, Xiaochen|,|NIBS, Beijing, China|
|3921|,|Wang, Yali|,|Gansu University of Traditional Chinese Medicine, Gansu, China|
|4250|,|Wang, Ye|,|Lishui University, Zhejiang, China|
|YMW|,|Wang, Yumei|,|Xiamen University, Xiamen, Fujian, China|
|ZW|,|Wang, Zhao-Wen|,|University of Connecticut, Farmington, CT|
|LWZ|,|Wang, Zheng|,|Huazhong University of Science and Technology, Hubei, China|
|2489|,|Wang, Zhou|,|University of Pittsburgh Cancer Institute, Pittsburgh, PA|
|4002|,|Wang, Zhuanhua|,|Shanxi University, Shanxi, China|
|1303|,|Wang, Zuo-Zhong|,|University of Pittsburgh School of Medicine, Pittsburgh, PA|
|3054|,|Wangh, Lawrence|,|Brandeis University, Waltham, MA|
|2559|,|Warbritton, Ryan|,|United States Geological Survey, Columbia, MO|
| 230|,|Ward's Natural Science Establishment, Inc.|,|West Henrietta, NY|
|2590|,|Ward, Cliff|,|Mesa Community College, Mesa, AZ|
| 536|,|Ward, Clive|,|University of Dundee, Scotland|
|BA|,|Ward, Sam|,|University of Arizona, Tucson, AZ|
| 590|,|Warden, Dr.|,|Rowe Genetics Program, Univ of California, Davis, CA|
|2673|,|Wareham, David|,|London School of Medicine and Dentistry, London, UK|
|SW|,|Waring, David|,|FHCRC, Seattle, WA|
|WA|,|Warren, Charles|,|University of New Hampshire, Durham, NH|
|1224|,|Warrick, John|,|University of Richmond, Richmond, VA|
|4280|,|Waschk, Daniel|,|University Hospital of Munster, Munster, Germany|
|2822|,|Washington, Ilyas|,|Columbia University, New York, NY|
| 934|,|Watanabe, Masahito|,|Japan Institute of Pearl Science, Kanagawa, Japan|
|1394|,|Watanabe, Nobumasa|,|Tokyo Metropolitan Institute of Medical Sciences, Tokyo, Japan|
|RW|,|Waterston, Bob|,|University of Washington, Seattle, WA|
|3993|,|Watjen, Wim|,|Martin Luther University of Halle-Wittenberg, Halle, Germany|
|4092|,|Watkins, Jermel|,|Hampton University, Hampton, VA|
|2438|,|Watts, Carys|,|Newcastle University, Newcastle Upon Tyne, England|
|JW|,|Way, Jeff|,|Fuji ImmunoPharmaceuticals, Lexington, MA|
|3482|,|Weber, JFF|,|UiTM, Selangor, Malaysia|
|3277|,|Weber, James|,|University of Maine, Orono, ME|
|1574|,|Wedig, Cindy|,|University of Texas Pan-American, Edinburg, TX|
|1441|,|Weedman, Donna|,|Colorado State University, Fort Collins, CO|
|4200|,|Weeks, Katherine|,|Centenary College of Louisiana, Shreveport, LA|
|2917|,|Weerapana, Eranthie|,|Boston College, Chestnut Hill, MA|
|2108|,|Weerapreeyakul, Natthida|,|Khon Kaen University, Khon Kaen, Thailand|
|WEH|,|Wehman, Ann|,|University of Wurzburg, Wurzburg, Germany|
|1336|,|Wehrens, Xander|,|Columbia University, New York, NY|
|ZK|,|Wei, Aguan Daniel|,|Seattle Children's Hospital Research Institute, Seattle, WA|
|4325|,|Wei, Qing|,|Shanghai Institutes for Biological Sciences, CAS, China|
|1719|,|Weibel, Doug|,|Harvard University, Cambridge, MA|
|1956|,|Weidhaas, Joanne|,|Yale University, New Haven, CT|
|3498|,|Weihrauch, Dirk|,|University of Manitoba, Winnipeg, Canada|
|4067|,|Weil, Dominique|,|UPMC Univ Paris, Paris, France|
|4294|,|Weil, Miguel|,|Tel Aviv University, Ramat Aviv, Israel|
|1674|,|Weingart, Christine|,|Denison University, Granville, OH|
|3653|,|Weingart, Helge|,|Jacobs University Bremen, Bremen, Germany|
|UF|,|Weinkove, David|,|Durham University, Durham, England|
|4123|,|Weinstein, Michael|,|Loudoun County High School, Leesburg, VA|
|3064|,|Weisblum, Bernard|,|University of Wisconsin, Madison, WI|
|3361|,|Weiss, Matthias|,|University of Bayreuth, Bayreuth, Germany|
|2817|,|Weitz, David|,|Harvard University, Cambridge, MA|
|4347|,|Weixel, Kelly|,|Washington & Jefferson College, Washington, PA|
|2905|,|Welch, David Mark|,|Marine Biological Laboratory, Woods Hole, MA|
|1693|,|Wells, Lance|,|University of Georgia, Athens, GA|
|1072|,|Wells, Russell|,|University of Vermont, Burlington, VT|
| 872|,|Welsh, Michael|,|University of Iowa, Iowa City, IA|
|3712|,|Welsh, Molly|,|University of Colorado, Boulder, CO|
|4079|,|Wen, Chuanjun|,|Nanjing Normal University, Nanjing, China|
|3158|,|Wen, G.Y. Gary|,|New York State Institute for Basic Research (IBR), Staten Island, NY|
|WEN|,|Wen, Quan|,|University of Science and Technology of China, Hefei, China|
|2980|,|Wenzel, Phil|,|Stevenson School, Pebble Beach, CA|
|2069|,|Wenzel, Uwe|,|Justus-Liebig University, Giessen, Germany|
| 956|,|Werb, Zena|,|University of California, San Francisco, CA|
| 942|,|Werren, Jack|,|University of Rochester, Rochester, NY|
|1925|,|Wersing, Dagmar|,|Technical University of Dresden, Dresden, Germany|
|2622|,|West, James|,|The College of Wooster, Wooster, OH|
| 690|,|West, Morris|,|Alabama State University, Montgomery, AL|
|SDW|,|Westerheide, Sandy|,|University of South Florida, Tampa, FL|
|DAW|,|Wharton, David Alan|,|University of Otago, Dunedin, New Zealand|
| 244|,|Wharton, George|,|Delaware Valley Regional High School, Frenchtown NJ|
|1851|,|Wheeler, Aaron|,|University of Toronto, Toronto, Ontario, Canada|
|3468|,|Wheeler, Jill|,|University of Toronto Undergraduate Teaching Labs, Toronto, Canada|
|WHE|,|Whetstine, Johnathan|,|Massachusetts General Hospital, Charlestown, MA|
|3911|,|Whistler, Cheryl|,|University of New Hampshire, Durham, NH|
|2617|,|Whitchurch, Cynthia|,|University of Technology, Sydney, Australia|
|1284|,|White, Frank|,|Kansas State University, Manhattan, KS|
| 355|,|White, Glenn|,|Longwood University, Farmville, VA|
|1559|,|White, J|,|Rutgers University, New Brunswick, NJ|
|WH|,|White, John|,|University of Wisconsin, Madison, WI|
|3883|,|Whitehouse, Iestyn|,|Memorial Sloan-Kettering Cancer Center, New York, NY|
|1499|,|Whiteley, Marvin|,|University ofTexas, Austin, TX|
| 945|,|Whitesell, Dr.|,|University of Arizona, Tucson, AZ|
|2563|,|Whitesides, George|,|Harvard University, Cambridge, MA|
|2709|,|Whitfield, Charles|,|University of Illinois, Urbana, IL|
|2491|,|Whitlock, Michael|,|University of British Columbia, Vancouver, BC, Canada|
|3706|,|Whitmer, Shannon|,|Berry College, Mount Berry, GA|
|2277|,|Wick, Robert|,|University of Massachusetts, Amherst, MA|
|MW|,|Wickens, Marv|,|University of Wisconsin, Madison|
|WX|,|Wicks, Stephen|,|Boston College, Chestnut Hill, MA|
| 271|,|Widden, P.|,|Concordia University, Montreal, Quebec, Canada|
|1636|,|Wides, Ron|,|Bar-Ilan University, Ramat-Gan, Israel|
|4107|,|Wieber, Courtney|,|Science from Scientists, Bedford, MA|
|3582|,|Wiebrecht, Colin|,|Michigan State University, East Lansing, MI|
|1558|,|Wiedmann, Martin|,|Cornell University, Ithaca, NY|
|1055|,|Wieland, Patrick|,|Orlando High School, Orlando, FL|
|2133|,|Wiens, Brent|,|Brock University, St. Catharines, Ontario, Canada|
| 664|,|Wieringa, B.|,|University of Nijmegen, The Netherlands|
|MU|,|Wightman, Bruce|,|Muhlenberg College, Muhlenberg, PA|
| 644|,|Wigler, M|,|Cold Spring Harbor Laboratory, Cold Spring Harbor, NY|
|SMW|,|Wignall, Sadie|,|Northwestern University, Evanston, IL|
| 237|,|Wild, Gillian|,|Lawrence Berkeley Labs, Berkeley, CA|
|3301|,|Wildwater, Marjolein|,|HAN University of Applied Sciences, Nijmegen, The Netherlands|
| 578|,|Wilkin, Peter|,|Purdue University North Central, Westville, IN|
| 148|,|Willet, Jim|,|George Mason University, Manassas, VA|
|2999|,|Williams High School|,|Williams High School, Plano TX|
|2224|,|Williams, Amy|,|Penn State Erie, The Behrend College, Erie, PA|
|WB|,|Williams, Ben|,|University of Illinois, Urbana, IL|
|CCU|,|Williams, Daniel|,|Coastal Carolina University, Conway, SC|
|1879|,|Williams, David|,|University of California San Diego, La Jolla, CA|
|4253|,|Williams, Dwight|,|Kalamazoo College, Kalamazoo, MI|
|3718|,|Williams, Larissa|,|Bates College, Lewiston, ME|
| 868|,|Williams, Mr.|,|North Hollywood High School, North Hollywood, CA|
|1987|,|Williams, Paul|,|University of Nottingham, Nottingham, England|
| 320|,|Williams, Phil|,|University of Georgia, Athens, GA|
|3803|,|Williams, Steven|,|Smith College, Northampton, MA|
|3742|,|Williams, Suzanne|,|Northern Michigan University, Marquette, MI|
|1415|,|Willis, John|,|University of Georgia, Atlanta, GA|
|HG|,|Wilson, David|,|University of Miami, Coral Gables, FL|
|IBW|,|Wilson, Iain|,|Universitaet fuer Bodenkultur, Vienna, Austria|
| 728|,|Wilson, K|,|Johns Hopkins University, Baltimore, MD|
|MJW|,|Wilson, Michael|,|University of Aberdeen, Aberdeen, UK|
|1004|,|Wilt, Steven|,|Kentucky Wesleyan College, Owensboro, KY|
|3769|,|Win, Myat Thu Thu|,|Kanazawa University, Kanazawa City, Japan|
|4353|,|Wincker, Patrick|,|Institut de Genomique-Genoscope, Evry, France|
|1868|,|Wing, David|,|Shepherd University, Shepherdstown, WV|
| 767|,|Wingfield, Denise|,|Dominion High School, Sterling, VA|
|3764|,|Wingfield, Denise|,|James Madison University, Harrisonburg, VA|
|2194|,|Wink, M|,|University of Heidelberg, Heidelberg, Germany|
|1182|,|Winska, Patrycja|,|Nencki Institute of Experimental Biology, Warsaw, Poland|
|1779|,|Winstanley, Craig|,|University of Liverpool, Liverpool, England|
|1761|,|Winston, Eugenia|,|USDA-ARS, Crop Genetics Production Research Unit, Stoneville, MS|
|CEW|,|Winter, Carlos E.|,|Universidade De Sao Paulo, Brazil|
|1433|,|Wirtz, Denis|,|Johns Hopkins University, Baltimore, MD|
|MZ|,|Witkowski, Colette|,|Southwest Missouri State University, Springfield, MO|
|4242|,|Witting, Michael|,|HelmholtzZentrum Muenchen, Neuherberg, Germany|
|1047|,|Wizenburg, Andrea|,|University of Wuerzburg, Germany|
|3673|,|Wohlgemuth, Stephanie|,|University of Florida, Gainesville, FL|
|APW|,|Wojtovich, Andrew|,|University of Rochester Medical Center, Rochester, NY|
|JRW|,|Wolff, Jennifer|,|Carleton College, Northfield, MN|
|MP|,|Wolinsky, Eve|,|New York University Medical School, New York, NY|
|CY|,|Wolkow, Cathy|,|Gerontology Research Center, NIA, Baltimore, MD|
|4019|,|Wollenberg, Amanda|,|Kalamazoo College, Kalamazoo, MI|
|WLZ|,|Wolozin, Benjamin|,|Boston University, Boston, MA|
| 649|,|Wolski, Michelle|,|Arlington High School, Arlington, WA|
| 556|,|Wolstenholme, Adrian|,|University of Georgia, Athens, GA|
|DRW|,|Wolstenholme, David|,|University of Utah, Salt Lake City, UT|
|2837|,|Wong, CH|,|Academia Sinica, Taipei, Taiwan|
| 790|,|Wong, Garry|,|AI Virtanen Institute, University of Kuopio, Kuopio, Finland|
| 299|,|Wong, James|,|E.I. Du Pont De Nemours & Company, Inc., Newark, DE|
|1984|,|Wong, Kelvin|,|Genome Institute of Singapore, Genome, Singapore|
|4334|,|Wong, Wilson|,|Boston University, Boston, MA|
|BW|,|Wood, Bill|,|University of Colorado, Boulder|
| 450|,|Wood, Dr.|,|University of British Columbia, Vancouver, Canada|
|1267|,|Wood, Jason|,|Harvard Medical School, Boston, MA|
|2352|,|Woodcock-Mitchell, Janet|,|University of Vermont, Burlington, VT|
|3719|,|Woodfin, Layne|,|Cotyledon Consulting Inc., Victoria, BC, Canada|
|UW|,|Woods, Robin|,|University of Winnipeg, Manitoba|
|AW|,|Woollard, Alison|,|University of Oxford, Oxford, England|
|1606|,|Wopperer, Julia|,|University of Zurich, Zurich, Switzerland|
|2788|,|Woradulayapinij, Warunya|,|Mahidol University, Bangkok, Thailand|
|2666|,|Worku, Mulumebet|,|North Carolina A & T University, Greensboro, NC|
| 890|,|Wrana, Jeffrey|,|Mt. Sinai Hospital, Toronto, Ontario, Canada|
|1218|,|Wren, Jodie|,|Huntingdon, Cambridgeshire, UK|
|2861|,|Wu, Chao-ting|,|Harvard Medical School, Boston, MA|
|4264|,|Wu, Chung-I|,|Sun Yat-sen University, Guangzhou, China|
|3674|,|Wu, Hongmei|,||
|JCW|,|Wu, Jui-ching|,|National Taiwan University, Taipei, Taiwan|
|1738|,|Wu, Lijun|,|Chinese Academy of Sciences, Anhui, China|
|3826|,|Wu, Lindsay|,|University of New South Wales, Sydney, Australia|
|4296|,|Wu, Qiuli|,|Medical School of Southeast University, Nanjing, China|
|YW|,|Wu, Yi-Chun|,|National Taiwan University, Taipei, Taiwan|
|ZXW|,|Wu, Zheng-Xing|,|Huazhong University, Hubei, China|
|1153|,|Wu, Zhihong|,|Universitat zu Kiel, Kiel, Germany|
|2594|,|Xia, Jun|,|Hong Kong University of Science & Technology, Kowloon, Hong Kong|
|2356|,|Xiangqian, Guo|,|Academia Sinica, Beijing, China|
|2706|,|Xiao, Bang-Ding|,|Institute of Hydrobiology, Chinese Academy of Sciences, Wuhan, China|
|RUX|,|Xiao, Rui|,|University of Florida, Gainesville, FL|
|XWZ|,|Xiao, Wei|,|Capital Normal University, Beijing, China|
|2687|,|Xiaohong Wang|,|Procter & Gamble, Cincinnati, OH|
|2946|,|Xie, Fang|,|Harbin Medical University, Harbin, Heilongjiang, China|
|3744|,|Xie, Sunney|,|Harvard University, Cambridge, MA|
|2196|,|Xie, Zhi-Xiong|,|Wuhan University, Wuhan, China|
|3717|,|Xie, Zhongcong|,|Massachusetts General Hospital, Charlestown, MA|
|1439|,|Xiong, Chuan xi|,|HuaZhong Agricultural University, WuHan Hubei, China|
|DPX|,|Xirodimas, Dimitris|,|CNRS, Montpellier, France|
|3516|,|Xu, Jie|,|Washington State University, Vancouver, WA|
|1335|,|Xu, Rener|,|Fudan University, Shanghai, China|
|TQ|,|Xu, Shawn|,|University of Michigan, Ann Arbor, MI|
|2408|,|Xu, Shiqing|,|Soochow University, China|
|TXL|,|Xu, Tao|,|Chinese Academy of Sciences, Beijing, China|
|3772|,|Xu, Xiang|,|Hubei University of Chinese Medicine, Wuhan City, China|
|2149|,|Xu, Xiang-Xi|,|Fox Chase Cancer Center, Philadelphia, PA|
|4282|,|Xu, Xiaojun|,|China Pharmaceutical University, Nanjing, China|
|2362|,|Xu, Xizhen|,|Shantou University, Shantou City, China|
|CU|,|Xue, Ding|,|University of Colorado, Boulder, CO|
|1270|,|Yagi, Ken|,|Saitama Medical School, Saitama, Japan|
| 458|,|Yakovlev, Alexander|,|Georgetown University, Washington DC|
|2662|,|Yamada Apiculture Center, Inc.|,|Tomata-gun, Okayama-ken, Japan|
|3382|,|Yamada, Koji|,|RIKEN BioResource Center, Tsukuba, Japan|
|2110|,|Yamaguchi, Atsushi|,|Chiba University, Chiba, Japan|
| 513|,|Yamaguchi, Yasunori|,|Fukuyama University, Hiroshima, Japan|
|2040|,|Yamaguchi, Yoko|,|Tokai University, Kanagawa, Japan|
|KRY|,|Yamamoto, Keith|,|UCSF, San Francisco, CA|
|1864|,|Yamamoto, Kenji|,|Kyoto University, Sakyo-ku, Kyoto, Japan|
|YM|,|Yamamoto, Masayuki|,|University of Tokyo, Tokyo, Japan|
|3383|,|Yamamura, Hideki|,|University of Yamanashi, Kofu, Yamanashi, Japan|
| 975|,|Yamanaka, Kunitoshi|,|Kumamoto University, Kumamoto, Japan|
|1286|,|Yamanashi, Yuji|,|Tokyo Medical and Dental University, Tokyo, Japan|
|2264|,|Yamashita, Katsuko|,|Tokyo Institute of Technology, Yokohama, Japan|
|NYL|,|Yan, Dong|,|Duke University, Durham, NC|
|4317|,|Yan, Jin-Yuan|,|Kunming Medical College, Kunming, Yunnan|
|2355|,|Yanagi, Shigeru|,|Tokyo School of Pharmacy and Life Sciences, Tokyo, Japan|
|2562|,|Yanai, Itai|,|Israel Institute of Technology, Haifa, Israel|
|1555|,|Yanase, Sumino|,|Daito Bunka University, Saitama, Japan|
|2534|,|Yang, Changhuei|,|California Institute of Technology, Pasadena, CA|
|FU|,|Yang, Chonglin|,|Chinese Academy of Sciences, Beijing, China|
| 537|,|Yang, Eunice|,|Suffern High School, Suffern, NY|
|3620|,|Yang, Jinlong|,|Chongqing Academy of Animal Sciences, Chongqing, China|
|2501|,|Yang, Xiang-Jiao|,|McGill University, Montreal, Quebec, Canada|
|4279|,|Yang, Xiaojing|,|Nanjing Agricultural University, Nanjing, China|
|3324|,|Yang, Yanmin|,|Stanford School of Medicine, Stanford, CA|
|1202|,|Yang, Yurong|,|Xiamen University, Fujian, China|
|3394|,|Yang. Qing|,|Dalian University of Technology, Dalian, China|
|2182|,|Yanik, Mehmet|,|MIT, Cambridge, MA|
|BAY|,|Yankner, Bruce|,|Harvard Medical School, Boston, MA|
|QP|,|Yanowitz, Judith|,|Magee-Womens Research Inst., Pittsburgh, PA|
|1813|,|Yao, Yufeng|,|Johns Hopkins University, Baltimore, MD|
|2483|,|Yarzabal, Luis Andres|,|Universidad de Los Andes, Merida, Venezuela|
|YEW|,|Ye, Weimin|,|North Carolina Dept of Agriculture & Consumer Serv, Raleigh, NC|
|3839|,|Ye, Weiyuan|,|Central China Normal University, Wuhan, Hubei, China|
|1982|,|Ye, Yihong|,|NIDDK/NIH, Bethesda, MD|
| 251|,|Yeargers, Edward|,|Georgia Tech, Atlanta, GA|
|1050|,|Yeong, Foong May|,|National University of Singapore, Singapore|
|1723|,|Yildiz, Fitnat|,|University of California, Santa Cruz, CA|
|2365|,|Yin, Guo-hua|,|Shandong Agricultural University, Shandong Provence, China|
|3132|,|Yin, John|,|University of Wisconsin, Madison, WI|
|2636|,|Yin, Lihong|,|Southest University, Nanjing, China|
|YH|,|Yoder, Brad|,|University of Alabama, Birmingham, AL|
|2897|,|Yokoyama, Ken|,|Kyoto Sangyo University, Kyoto, Japan|
|1209|,|Yoneda, Takunari|,|Osaka University, Osaka, Japan|
| 522|,|Yonehara, Dr.|,|Kyoto University, Kyoto, Japan|
|3329|,|Yong, Cao|,|College of Food Science, SCAU, Guangzhou, China|
|1593|,|Yoo, Ook-Joon|,|KAIST, Taejon, South Korea|
|3836|,|Yoon, Yohan|,|Sookmyung Women's University, Seoul, South Korea|
|4337|,|Yoshida, Minoru|,|RIKEN Center for Sustainable Resource Science, Saitama, Japan|
|YOS|,|Yoshiga, Toyoshi|,|Saga Univeristy, Saga, Japan|
|1105|,|Yoshina, S|,|Tokyo University of Pharmacy and Life Science, Tokyo, Japan|
|4014|,|Yoshizawa, Yukio|,|Jikei University School of Medicine, Tokyo, Japan|
|4007|,|You, Chunping|,|State Key Laboratory of Dairy Biotech, Shanghai, China|
|1569|,|You, Guo|,|Chinese Academy of Science, Beijing, China|
|4211|,|You, Lingchong|,|Duke University, Durham, NC|
|YJ|,|You, Young-Jai|,|Virginia Commonwealth University, Richmond, VA|
|3842|,|Young, Diana|,|Purdue University Calumet, Hammond, IN|
|1902|,|Young, Jared|,|Mills College, Oakland, CA|
|2806|,|Young, Roger|,|Drury University, Springfield, MO|
|1638|,|Younger, John|,|University of Michigan, Ann Arbor, MI|
|3575|,|Youngman, Matt|,|Villanova University, Villanova, PA|
|4049|,|Yozu, Gakuto|,|Keio University, Tokyo, Japan|
|2596|,|Yu, Alice|,|Academia Sinica, Taipei, Taiwan|
| 828|,|Yu, Hongwei|,|Marshall University School of Medicine, Huntington, WV|
|3840|,|Yu, Jie|,|Shantou University, Shantou City, China|
|3649|,|Yu, Jun|,|University of Strathclyde, Glasgow, Scotland|
|3489|,|Yu, Liqing|,|University of Maryland, College Park, MD|
|1313|,|Yu, Qiang|,|National Center for Drug Screeing, Shanghai, China|
|4085|,|Yu, Siwang|,|Peking University, Beijing, China|
|2795|,|Yu, Xiao-Qiang|,|University of Missouri, Kansas City, MO|
|3930|,|Yu, Xiaozhong|,|University of Georgia, Athens, GA|
|DYG|,|Yucel, Duygu|,|Erciyes University, Kayseri, Turkey|
|WYY|,|Yuen, Karen WY|,|University of Hong Kong, Hong Kong, China|
|1678|,|Zabner, Joseph|,|University of Iowa, Iowa City, IA|
|1905|,|Zaborina, Olga|,|University of Chicago, Chicago, IL|
|2195|,|Zaccheo, Patrizia|,|University of Milan, Milan, Italy|
|1029|,|Zagrobelny, Mika|,|University of Copenhagen, Copenhagen, Denmark|
|SZ|,|Zahler, Alan|,|University of California, Santa Cruz, CA|
|2493|,|Zahorchak, Bob|,|HudsonAlpha Institute for Biotechnology Research, Huntsville, AL|
|2016|,|Zaia, Joseph|,|Boston University, Boston, MA|
|RZB|,|Zaidel-Bar, Ronen|,|National University of Singapore, Singapore|
|1237|,|Zampini, Charlotte|,|Framingham State College, Framingham, MA|
|DZ|,|Zarkower, David|,|University of Minnesota, Minneapolis, MN|
|3598|,|Zaslaver, Alon|,|The Hebrew University of Jerusalem, Jerusalem, Israel|
|1391|,|Zatylny, Celine|,|University of Caen, Caen, France|
|PAZ|,|Zegerman, Philip|,|University of Cambridge, Cambridge, UK|
|1774|,|Zelle, Christine|,|St. Louis University, St. Louis, MO|
| 640|,|Zeneca Agrochemicals|,|Bracknell, Berkshire, U.K.|
|3941|,|Zeng, Zhouhan|,|Sun Yet-Sen University, Guangzhou, China|
|MZE|,|Zerial, Marino|,|MPI for Molecular Cell Biology and Genetics, Dresden, Germany|
|EZ|,|Zetka, Monique|,|McGill University, Montreal, Canada|
|3327|,|Zhai, Shumei|,|Shandong University, Jinan, China|
|2961|,|Zhang,  Xin Guo|,|Lanzhou University of Technology, Lanzhou, Gansu, China|
|1938|,|Zhang, Chenggang|,|Beijing Institute of Radiation Medicine, Beijing, China|
|1989|,|Zhang, Deyong|,|Hunan Agricultural Academy of Sciences, Changsha, China|
|HZ|,|Zhang, Hong|,|Institute of Biophysics, Chinese Academy of Sciences, Beijing, China|
|2847|,|Zhang, Hongbin|,|Chinese Academy of Medical Sciences, Beijing, China|
|4173|,|Zhang, Hongjie|,|University of Macau, Macau, SAR, China|
|2692|,|Zhang, Hongyu|,|Huazhong Agricultural University, Wuhan, China|
|HMZ|,|Zhang, Huimin|,|IBMS, Soochow University, SuZhou, China|
|2151|,|Zhang, Jianzhi|,|University of Michigan, Ann Arbor, MI|
|YAN|,|Zhang, Ke-Qin & Zou, Cheng-Gang|,|Yunnan University, Yunnan, Kunming, China|
|3014|,|Zhang, Kunyan|,|University of Calgary, Calgary, AB, Canada|
|2548|,|Zhang, Liping|,|Hebei University, Hebei, China|
|4245|,|Zhang, Meng|,|Dalian Maritime University, Dalian, China|
|3720|,|Zhang, Rui|,|Louisiana State University, Baton Rouge, LA|
|SOZ|,|Zhang, Shaobin|,|Capital Normal University, Beijing, China|
|4316|,|Zhang, XiaoRui|,|Beijing Inst of Pharmacology and Toxicology, Beijing, China|
|1928|,|Zhang, Xiaoming|,|University of Kansas, Kansas City, KS|
|2938|,|Zhang, Xiaoping|,|Mt. Sinai School of Medicine, New York, NY|
|3370|,|Zhang, Xueyao|,|Applied Biology Institute, Shanxi, China|
|3697|,|Zhang, Xulang|,|Chinese Academy of Sciences, Beijing, China|
|4106|,|Zhang, Xumei|,|Tianjin Medical University, Tianjin, China|
|3922|,|Zhang, Yong|,|National University of Singapore, Singapore|
|3055|,|Zhang, Yong Mei|,|Medical University of South Carolina, Charleston, SC|
|3844|,|Zhang, Yong-Jun|,|China Jiliang University, Hangzhou, China|
|ZC|,|Zhang, Yun|,|Harvard University, Cambridge, MA|
|3974|,|Zhang, Yun|,|Kunming Institute of Zoology, CAS, Kunming, Yunnan, China|
|3931|,|Zhang, Zhizhou|,|Harbin Institute of Technology at Weihai, China|
|3172|,|Zhao, Feng-Qi|,|University of Vermont, Burlington, VT|
|1961|,|Zhao, Youfu|,|University of Illinois, Urbana, IL|
|1154|,|Zhao, Zhizhuang|,|Vanderbilt University, Nashville, TN|
|ZZY|,|Zhao, Zhongying|,|Hong Kong Baptist University, Hong Kong, China|
|2914|,|Zharov, Vladmir|,|Univ of Arkansas Medical Sciences, Little Rock, AR|
|ZM|,|Zhen, Mei|,|Samuel Lunenfeld Res Inst, Toronto, Ontario, Canada|
|3448|,|Zheng, Dong|,|Tenth People's Hospital, Shanghai, China|
|4277|,|Zheng, Hui|,|Baylor College of Medicine, Houston, TX|
|1875|,|Zheng, Huiming|,|Nanjing Agricultural University, Nanjing, China|
|2071|,|Zheng, Jolene|,|Louisiana State University, Baton Rouge, LA|
|FUH|,|Zheng, Min and Hartl, Franz-Ulrich|,|MPI for Cellular Biochemistry, Martinsried, Germany|
|JAB*|,|Zheng, Yixian|,|Carnegie Institution of Washington, Baltimore, MD|
|2319|,|Zhong, Guangyan|,|Chinese Academy of Agricultural Sciences, ChongQing, China|
|3114|,|Zhong, Pei|,|Sun Yat-Sen University, Guangzhou, China|
|WWZ|,|Zhong, Weiwei|,|Rice University, Houston TX|
|3208|,|Zhou, Bin (Andrew)|,|Scripps Research Inst, La Jolla, CA|
|3887|,|Zhou, Lijun|,|Tianjin University, Tianjin, China|
|3215|,|Zhou, Shaoyu|,|Indiana University, Bloomington, IN|
|ZH|,|Zhou, Zheng|,|Baylor College of Medicine, Houston, TX|
|3626|,|Zhou. Jinqui|,|Chinese Academy of Sciences, Shanghai, China|
| 657|,|Zhu, Hao|,|Brigham & Women's Hospital, Harvard Medical School, Boston, MA|
|1377|,|Zhu, Junhua|,|Shandong Agricultural University, Taiwan, China|
|3017|,|Zhu, Ling-Qiang|,|Huazhong University of Science and Tech, Wuhan, China|
|3122|,|Zhu, Shunyi|,|Chinese Academy of Sciences, Beijing, China|
|2941|,|Zhu, Xueliang|,|Shanghai Insti of Biochem & Cell Biology, CAS, Shanghai, China|
|2311|,|Zhu, Zhen|,|Chinese Academy of Sciences, Beijing, China|
|1045|,|Zhuang, Wei-Ping|,|Shanghai Institute of Organic Chemistry, Shangai, China|
|3317|,|Zhuang, Xiaowei|,|Harvard University, Cambridge, MA                                         `|
|1181|,|Ziemba, Rob|,|Centre College, Danville, KY|
|1857|,|Zigler, Kirk|,|University of the South, Sewanee, TN|
|3291|,|Zimmer, Christoph|,|Bayer CropScience, Dusseldorf, Germany|
|ZIM|,|Zimmer, Manuel|,|IMP - Research Inst Molecular Pathology, Vienna, Austria|
|2165|,|Zimniak, Piotr|,|University of Arkansas, Little Rock, AR|
|UY|,|Zinovyeva, Anna|,|Kansas State University, Manhattan, KS|
|3401|,|Ziquan, Yi|,|Hunan Normal University, Changsha, China|
|1381|,|Zoccola, Didier|,|Centre Scientifique de Monaco, Monaco|
|3683|,|Zolman, Bethany|,|University of Missouri, St. Louis, MO|
|1491|,|Zornig, Horst|,|University of Veterinary Medicine Vienna, Wien, Austria|
|1817|,|Zou, Ming|,|Tsinghua University, Beijing, China|
|2305|,|Zou, Sige|,|National Institute on Aging, Baltimore, MD|
|ZOU|,|Zou, Yan|,|ShanghaiTech University, Shanghai, China|
|2291|,|Zucchero, Theresa|,|Methodist University, Fayetteville, NC|
|  56|,|Zuckerman, Bert|,||
| 692|,|Zuiderveen, Jeffrey|,|Columbus State University, Columbus, GA|
| 725|,|Zuker, C|,|UCSD, La Jolla, CA|
|2990|,|Zurawski, Daniel|,|Walter Reed Army Institute of Research, Silver Spring, MD|
|SJZ|,|Zuryn, Steven|,|The University of Queensland, St Lucia, Australia|
| 911|,|Zwartkruis, Fried|,|Utrecht University, Utrecht, The Netherlands|
| 389|,|Zweiner, Carol|,|Kamiakin High School, Kennewick, WA|
|3083|,|d'Adda di Fagagna, Fabrizio|,|FIRC, IFOM, Milan, Italy|
|3879|,|da Cunha, Fernanda Marques|,|Universidade de Sao Paulo, Sao Paulo, Brazil|
|4071|,|de Araujo Soares, Rosangela Maria|,|Federal University of Rio de Janeiro, Rio de Janeiro, BrazilRio de Janeiro,|
|AX|,|de Bono, Mario|,|MRC-LMB, Cambridge, England|
|2742|,|de Fatima Grossi de Sa, Maria|,|Universidade Catolica de Brasilia, Brasilia, Brazil|
|4128|,|de Lencastre, Alexandre|,|Quinnipiac University, Hamden, CT|
|2381|,|de Lima, Silvana|,||
|3039|,|de Magalhaes, Joao Pedro|,|University of Liverpool, Liverpool, England|
|2741|,|de Oliviera Soares, Marta|,|CESPU-IPSN, Famalicao, Portugal|
|3668|,|de Pascale, Donatella|,|Institute of Protein Biochemistry, Naples, Italy|
|DDP|,|de Pomerai, David|,|University of Nottingham, Nottingham, UK|
| 139|,|de Sauza, W|,||
|1039|,|de Voer, Gert|,|Leiden University Medical Centre, Leiden, The Netherlands|
| 599|,|deVGen, Inc.|,|Gent, Belgium|
|3231|,|di Figueroa, Desiree|,|Stony Brook University, Stony Brook, NY|
| 984|,|di Fiore, Pier Paolo|,|IFOM, Milan, Italy|
|PVH|,|van Oosten-Hawle, Patricija|,|University of Leeds, Leeds, UK|
|3838|,|van Schaik, Willem|,|University Medical Center Utrecht, Utrecht, The Netherlands|
|3428|,|van Zon, Jeroen|,|FOM Institute AMOLF, Amsterdam, The Netherlands|
|1215|,|van Zwol, Nancy|,|Stanford University, Stanford, CA|
|1475|,|van den Ende, Oliver|,|Kennedy Space Center, FL|
|SV|,|van den Heuvel, Sander|,|Utrecht University, Utrecht, The Netherlands|
|ZA|,|van der Bliek, Alex|,|Department of Biological Chemistry, UCLA School of Medicine, Los Angeles CA|
|3955|,|van der Hoeven, Ransome|,|University of Texas, Houston, TX|
|UT|,|van der Kooy, Derek|,|University of Toronto, Ontario, Canada|
|VDL|,|van der Linden, Alexander|,|University of Nevada, Reno, NV|
|2445|,|van der Spek, Hans|,|University of Amsterdam, Amsterdam, The Netherlands|
|3092|,|van der Veken, Lieselot|,|Biobest Belgium NV, Westerlo, Belgium|
|GG|,|von Ehrenstein, G|,|Max-Planck Institut, Gottingen, Germany|
| 177|,|von Mende, N|,|Rothamsted Experimental Station, Harpenden, England|
|2870|,|von Mikecz, Anna|,|IUF, Heinrich Heine Univ, Duesseldorf, Germany|
|3461|,|von Reuss, Stephan H.|,|Max Plank Institute for Chemical Ecology, Jena, Germany|
|2421|,|von Samson-Himmelstjerna, Georg|,|Inst Parasitology & Tropical Vet Med, Berlin, Germany|
