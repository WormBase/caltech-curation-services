#!/usr/bin/perl

# get the new list of text files and repopulate missing authors and add
# affiliations.  2007 08 10

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;


my $highest_aid;
my $result3 = $conn->exec( "SELECT author_id FROM wpa_author_index ORDER BY author_id DESC;" );
my @row3 = $result3->fetchrow; $highest_aid = $row3[0];




my (@files) = </home/postgres/work/pgpopulation/wpa_papers/abstracts/iwm2007/AbsFiles/*>;
foreach my $infile (@files) {
  next if ($infile =~ m/AbsFiles.zip/);		# not a file
  next if ($infile =~ m/472B.txt/);		# didn't have an html file will be entered manually
  open (IN, "<$infile") or die "Cannot open $infile : $!";
  my $abs; my %auth; my %aff; my %aaf;
  while (my $line = <IN>) {
    if ($line =~ m/AbstractNo : (\d+)/) { $abs = $1; }
    if ($line =~ m/Author (\d+) : (.*)$/) { 
      my $order = $1; my $auth = $2;
      if ($auth =~ m/^(.*?), (.*?)$/) { $auth = "$2 $1"; }
      $auth =~ s///g; 
      $auth =~ s/&#176;//g;
      $auth =~ s/&#146;//g;
      $auth =~ s/&#147;//g;
      $auth =~ s/&#148;//g;
      $auth =~ s/\&\#;//g;
      $auth =~ s/G.nczy/Gonczy/g;
      $auth =~ s/Thomas B.rglin/Thomas Burglin/g;
      $auth =~ s/Vanessa Gonz.lez-P.rez/Vanessa Gonzalez-Perez/g;
      $auth =~ s/Erika Fr.hli-Hoier/Erika Frohli-Hoier/g;
      $auth =~ s/Jemma Alarc.n/Jemma Alarcon/g;
      $auth =~ s/Anders N..r/Anders Naar/g;
      $auth =~ s/Lydia Th./Lydia The/g;
      $auth =~ s/QueeLim Ch\'ng/QueeLim Ching/g;
      $auth =~ s/J.r.me Reboul/Jerome Reboul/g;
      $auth =~ s/J.r.me Belougne/Jerome Belougne/g;
      $auth =~ s/S.bastien Dubleumortier/Sebastien Dubleumortier/g;
      $auth =~ s/M.rton L/Marton L/g;
      $auth =~ s/M.d.ric J/Mederic J/g;
      $auth =~ s/H.l.ne Catoire/Helene Catoire/g;
      $auth =~ s/L.etitia Chotard/Laetitia Chotard/g;
      $auth =~ s/Marc-Andr. Sylvain/Marc-Andre Sylvain/g;
      $auth =~ s/Mait. Carre-Pierrat/Maite Carre-Pierrat/g;
      $auth =~ s/.agdas Tazearslan/Cagdas Tazearslan/g;
      $auth =~ s/M.d.ric Diard/Mederic Diard/g;
      $auth =~ s/Fran.ois Taddei/Francois Taddei/g;
      $auth =~ s/Ana-Jo.o Rodrigues/Ana-Joao Rodrigues/g;
      $auth =~ s/V.ronique De Vaux/Veronique De Vaux/g;
      $auth =~ s/Fritz M.ller/Fritz Muller/g;
      $auth =~ s/Juan Carlos Fierro-Gonz.lez/Juan Carlos Fierro-Gonzalez/g;
      $auth =~ s/Stephen R St.rzenbaum/Stephen R Sturzenbaum/g;
      $auth =~ s/Rene. Miller/Renee Miller/g;
      $auth =~ s/.zg.r Karakuzu/Ozgur Karakuzu/g;
      $auth =~ s/Daniel Col.n-Ramos/Daniel Colon-Ramos/g;
      $auth =~ s/Claire B.nard/Claire Benard/g;
      $auth =~ s/Hannes B.low/Hannes Bulow/g;
      $auth =~ s/Catarina M.rck/Catarina Morck/g;
      $auth =~ s/Claes Ax.ng/Claes Axang/g;
      $auth =~ s/J.r.me Teuli.re/Jerome Teuliere/g;
      $auth =~ s/Luis Brise.o-Roa/Luis Briseno-Roa/g;
      $auth =~ s/G.raldine Maro/Geraldine Maro/g;
      $auth =~ s/Filip Ystr.m/Filip Ystrom/g;
      $auth =~ s/Borja P.rez Mansilla/Borja Perez Mansilla/g;
      $auth =~ s/S.rgio M Pinto/Sergio M Pinto/g;
      $auth =~ s/Jean-Fran.ois Rual/Jean-Francois Rual/g;
      $auth =~ s/Am.lie Dricot/Amelie Dricot/g;
      $auth =~ s/Eva Krpelanov./Eva Krpelanova/g;
      $auth =~ s/Christian Fr.kj.r-Jensen/Christian Frokjar-Jensen/g;
      $auth =~ s/S.ren-Peter Olesen/Soren-Peter Olesen/g;
      $auth =~ s/C.sar Hidalgo/Cesar Hidalgo/g;
      $auth =~ s/Albert-L.szl. Barab.si/Albert-Laszlo Barabasi/g;
      $auth =~ s/Emilie Jaqui.ry/Emilie Jaquiery/g;
      $auth =~ s/Verena G.bel/Verena Gobel/g;
      $auth =~ s/Katrin H.sken/Katrin Husken/g;
      $auth =~ s/Christophe Lef.bvre/Christophe Lefebvre/g;
      $auth =~ s/Claes Ax.ng/Claes Axang/g;
      $auth =~ s/Mo.se Pinto/Moise Pinto/g;
      $auth =~ s/Leticia S.nchez Alvarez/Leticia Sanchez Alvarez/g;
      $auth =~ s/Val.rie/Valerie/g;
      $auth =~ s/Claude Labb./Claude Labbe/g;
      $auth =~ s/Anne F.lix/Anne Felix/g;
      $auth =~ s/S.galat/Segalat/g;
      $auth{$order} = $auth; }
    if ($line =~ m/Author (\d+) Affiliation : (\d+)/) { $aaf{$1} = $2; }
    if ($line =~ m/Institution (\d+) : (.*)$/) { my $order = $1; my $aff = $2; $aff =~ s///g; $aff{$order} = $aff; }
  } # while (my $line = <IN>)
  unless ($abs) { print "ERR no abs id $infile\n"; next; }
  my %pg_ordername; my %pg_orderaid; my %pg_orderchangename;
  my @joinkeys;
  my $result = $conn->exec( "SELECT joinkey FROM wpa_identifier WHERE wpa_identifier = 'wm2007ab$abs';" );
  while (my @row = $result->fetchrow) { if ($row[0]) { $row[0] =~ s///g; push @joinkeys, $row[0]; } }
  if (scalar(@joinkeys) > 1) { print "ERR too many joinkeys for abs $abs : @joinkeys\n"; }
  unless ($joinkeys[0]) { print "ERR no joinkey $abs\n"; }
  $result = $conn->exec( "SELECT * FROM wpa_author WHERE joinkey = '$joinkeys[0]';" );
  while (my @row = $result->fetchrow) { 
    my $order = $row[2]; my $aid = $row[1];
    $pg_orderaid{$order} = $aid;
    my $result2 = $conn->exec( "SELECT * FROM wpa_author_index WHERE author_id = '$aid';" );
    while (my @row2 = $result2->fetchrow) { 
      unless ($row2[1]) { print "ERR No wpa_author_index for aid $aid\n"; next; }
      unless ($auth{$order}) { print "ERR no auth{order} for $order on joinkey $joinkeys[0]\n"; next; }
      $pg_orderchangename{$order} = $row2[1];
      if ($row2[1] eq $auth{$order}) { $pg_ordername{$order} = 'nochange'; }	 # if they're the same, don't change them
#       if ($row2[1] eq $auth{$order}) { 1; }	# this is good
#         else { print "JOIN $joinkeys[0] AID $aid ORDER $order PG $row2[1] TXT $auth{$order} END\n"; }
    } # while (my @row2 = $result2->fetchrow) 
  } # while (my @row = $result->fetchrow)


  foreach my $order (sort {$a<=>$b} keys %auth) {
    my $affi = $aff{$aaf{$order}}; 
    my $aid = '';
    if ($pg_orderaid{$order}) { 	# already have the author in pg with an aid
      $aid = $pg_orderaid{$order}; 
      unless ($pg_ordername{$order}) {	# name is different, need to change it
        print "-- change $aid TO $auth{$order} FROM $pg_orderchangename{$order} END\n"; 
        my $command = "UPDATE wpa_author_index SET wpa_author_index = '$auth{$order}' WHERE author_id = '$aid' AND wpa_author_index = '$pg_orderchangename{$order}';";
        print "$command\n";
# UNCOMMENT to populate
#         my $result4 = $conn->exec($command);
      }
      print "-- add TO $aid AFFI $affi END\n"; 
      my $command = "UPDATE wpa_author_index SET wpa_affiliation = '$affi' WHERE author_id = '$aid';";
      print "$command\n";
# UNCOMMENT to populate
#       my $result4 = $conn->exec($command);
    } else {				# new author id to create
      $highest_aid++;			# get next highest aid;
      print "-- create $highest_aid AUTH $auth{$order} ORDER $order AFFI $affi END\n";
      my $command = "INSERT INTO wpa_author VALUES ('$joinkeys[0]', '$highest_aid', '$order', 'valid', 'two1823', CURRENT_TIMESTAMP);";
      print "$command\n";
# UNCOMMENT to populate
#       my $result4 = $conn->exec($command);
      $command = "INSERT INTO wpa_author_index VALUES ('$highest_aid', '$auth{$order}', '$affi', 'valid', 'two1823', CURRENT_TIMESTAMP);";
      print "$command\n";
# UNCOMMENT to populate
#       $result4 = $conn->exec($command);
    } 
  } # foreach my $order (sort {$a<=>$b} keys %auth)

  close (IN) or die "Cannot close $infile : $!";
} # foreach my $infile (@files)

__END__

# Enter IWM 2007 data.  Parse out some Author's names that had accents  2007 06 07

use lib qw( /home/postgres/work/pgpopulation/wpa_papers/wpa_new_wbpaper_tables/perl_wpa_match );
use wpa_match qw ( processWormbook );

use strict;

my ($wormbook, $authors, $title, $journal, $volume, $pages, $year, $abstract, $genes, $type, $editor, $fulltext_url);

$journal = 'International Worm Meeting';
$year = '2007';
$type = 'Meeting Abstract';

my $starttime = time;

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


DELETE FROM wpa WHERE wpa_timestamp > '2007-06-07 14:47:00';
DELETE FROM wpa_title WHERE wpa_timestamp > '2007-06-07 14:47:00';
DELETE FROM wpa_identifier WHERE wpa_timestamp > '2007-06-07 14:47:00';
DELETE FROM wpa_year WHERE wpa_timestamp > '2007-06-07 14:47:00';
DELETE FROM wpa_journal WHERE wpa_timestamp > '2007-06-07 14:47:00';
DELETE FROM wpa_volume WHERE wpa_timestamp > '2007-06-07 14:47:00';
DELETE FROM wpa_abstract WHERE wpa_timestamp > '2007-06-07 14:47:00';
DELETE FROM wpa_type WHERE wpa_timestamp > '2007-06-07 14:47:00';
DELETE FROM wpa_author WHERE wpa_timestamp > '2007-06-07 14:47:00';
DELETE FROM wpa_fulltext_url WHERE wpa_timestamp > '2007-06-07 14:47:00';
DELETE FROM wpa_in_book WHERE wpa_timestamp > '2007-06-07 14:47:00';
DELETE FROM wpa_editor WHERE wpa_timestamp > '2007-06-07 14:47:00';
DELETE FROM wpa_author_index WHERE wpa_timestamp > '2007-06-07 14:47:00';


