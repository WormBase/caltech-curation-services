#!/usr/bin/perl

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


