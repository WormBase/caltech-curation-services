#!/usr/bin/perl

# create wbpapers for euwm 2008.  
# ran out of memory after first ~120, hopefully because of old pg.pm instead of DBI.pm
# when running again, be careful of ordering the files in case they need to be entered 
# in batches, and also reset the $count not to start at zero.  2009 05 27


use strict;

use lib qw( /home/postgres/work/pgpopulation/wpa_papers/wpa_new_wbpaper_tables/perl_wpa_match );
use wpa_match qw ( processWormbook );

my ($wormbook, $authors, $title, $journal, $volume, $pages, $year, $abstract, $genes, $type, $editor, $fulltext_url);

$journal = 'European Worm Meeting';
$year = '2008';
$type = 'Meeting Abstract';


my (@files) = </home/postgres/work/pgpopulation/wpa_papers/abstracts/euwm2008/source/*.txt>;

my %badChars;

my $counter = 0;
$/ = "";
foreach my $file (@files) {
  open (IN, "<$file") or die "Cannot open $file : $!";
  my @paras;
  while (my $para = <IN>) {
    $para =~ s/^\s+//sg;
    $para =~ s/\s+$//sg;
    next if ($para =~ m/^CONTRIBUTION TO EWM2008/);
    next if ($para =~ m/^CONTRIBUTION TO EWM 2008/);
    next if ($para =~ m/^Indicate your presentation/); 
    $para =~ s/^\s*Type your Title here\s*//s;
    $para =~ s/^\s*Type Authors here\s*//s;
    $para =~ s/^\s*Type Affiliations here\s*//s;
    $para =~ s/^\s*Type Body text here\s*//s;
    $para =~ s/\s*\(note\: Make presenting author’s name BOLD\)\s*//s;
    if ($para) { push @paras, $para; }
  } # while (my $para = <IN>)
  close (IN) or die "Cannot close $file : $!";
  $title = shift @paras;
  $authors = shift @paras;
  my $junk = shift @paras;
  $abstract = join"\n", @paras;
  unless ($abstract) { $abstract = $junk; }

  ($title) = &findJunk($title);
  $title =~ s/\n/ /g;
  ($authors) = &findJunk($authors);
  $authors =~ s/\n/ /g;
  ($authors) = &processAuthors($authors);
  ($abstract) = &findJunk($abstract);
  $abstract = &filterSpaces($abstract);

#   print "FILE\t$file\n";
#   print "TITLE\t$title\n";
  my (@authors) = split/, /, $authors;
  $authors = join"//", @authors;
#   print "AUTHORS\t$authors\n";
#   foreach my $author (@authors) { $author =~ s/,\s*//g; print "AUTHOR\t$author\n"; }
#   print "ABSTRACT\t$abstract\n";
  $counter++;
  my $identifier = 'euwm2008abs' . $counter;
  my $line = "$identifier\t$authors\t$title\t$journal\t$volume\t$pages\t$year\t$abstract\t$genes\t$type\t$editor\t$fulltext_url";
  print "$line\n";
# UNCOMMENT TO CREATE PAPERS
#   &processWormbook( 'two1', 'wormbook', $line );    # 1 is Cecilia
#   print "\n";
} # foreach my $file (@files)
$/ = "\n";

foreach (keys %badChars) {
  print "BAD $_ EB\n";
}

sub processAuthors {
  my ($authors) = @_;
  $authors =~ s/\&/, /g;
  $authors =~ s/ and /, /g;
  $authors =~ s/\([^\)]*\)//g;
  $authors =~ s/\[[^\]]*\]//g;
  $authors =~ s/[^[a-zA-Z\ \-\,]//g;				# take out periods too

  my (@authors) = split/, /, $authors;				# take out extra authors and spaces
  my @good;  foreach (@authors) { $_ =~ s/^\s*//; $_ =~ s/\s*$//; if ($_) { push @good, $_; } }
  $authors = join", ", @good;
  $authors =~ s/,+/,/g;

  @good = (); my (@words) = split/ /, $authors;			# lc and ucfirst words with more than 3 chars
  foreach my $word (@words) { if ($word =~ m/..../) { ($word) = lc($word); ($word) = ucfirst($word); } push @good, $word; }
  $authors = join" ", @good; 
  my (@change) = $authors =~ m/(\-.)/g;
  foreach my $change (@change) { my ($upchange) = uc($change); $authors =~ s/$change/$upchange/g; }

  $authors =~ s/,+/,/g;
  return $authors;
} # sub processAuthors

sub findJunk {
  my $para = shift;
  ($para) = &filterJunk($para);
#   my (@words) = split/\s+/, $para;
#   foreach my $word (@words) {
    if ($para =~ m/[^\s\w\~\`\!\@\#\$\%\^\&\*\(\)\-\=\+\[\]\{\}\;\:\'\"\,\<\.\>\/\?\\\|]/) {
#       my (@bad) = $para =~ m/\b(.*?[^\s\w\!\@\#\$\%\^\&\*\(\)\-\=\+\[\]\{\}\;\:\'\"\,\<\.\>\/\?\\\|].*?)\b/g;
      my (@bad) = $para =~ m/([^\s\w\~\`\!\@\#\$\%\^\&\*\(\)\-\=\+\[\]\{\}\;\:\'\"\,\<\.\>\/\?\\\|])/g;
      foreach (@bad) { $badChars{$_}++; }
    }
#   }
  return $para;
} # sub findJunk

sub filterSpaces {
  my $entry = shift;
  if ($entry =~ m/\n+/m) { $entry =~ s/\n+/. /mg; }
  if ($entry =~ m/\t+/m) { $entry =~ s/\t+/. /mg; }
  if ($entry =~ m/\s+\.\s+/m) { $entry =~ s/\s+\.\s+/ /mg; }
  if ($entry =~ m/^\n+/m) { $entry =~ s/^\n+//mg; }
  if ($entry =~ m/\n+$/m) { $entry =~ s/\n+$//mg; }
  if ($entry =~ m/^\r+/m) { $entry =~ s/^\r+//mg; }
  if ($entry =~ m/\r+$/m) { $entry =~ s/\r+$//mg; }
  if ($entry =~ m/^\f+/m) { $entry =~ s/^\f+//mg; }
  if ($entry =~ m/\f+$/m) { $entry =~ s/\f+$//mg; }
  if ($entry =~ m/^\.\s+/) { $entry =~ s/^\.\s+//g; }
  if ($entry =~ m/^\s+/) { $entry =~ s/^\s+//g; }
  if ($entry =~ m/\s+$/) { $entry =~ s/\s+$//g; }
  return $entry;
} # sub filterSpaces


sub filterJunk {
  my $thing = shift;
  $thing =~ s/Â/a/g;
  $thing =~ s/â/a/g;	# doesn't work
  $thing =~ s/ä/a/g;
  $thing =~ s/á/a/g;
  $thing =~ s/à/a/g;
  $thing =~ s/α/a/g;
  $thing =~ s/¢/c/g;
  $thing =~ s/è/e/g;
  $thing =~ s/è/e/g;
  $thing =~ s/é/e/g;
  $thing =~ s/ë/e/g;
  $thing =~ s/¡/i/g;
  $thing =~ s/Ï/i/g;
  $thing =~ s/Ï/i/g;	# doesn't work
  $thing =~ s/í/i/g;
  $thing =~ s/Í/i/g;
  $thing =~ s/ï/i/g;
  $thing =~ s/¡/i/g;
  $thing =~ s/ø/o/g;
  $thing =~ s/ö/o/g;
  $thing =~ s/Ö/o/g;
  $thing =~ s/ó/o/g;
  $thing =~ s/ô/o/g;
  $thing =~ s/ü/u/g;
  $thing =~ s/ñ/n/g;
  $thing =~ s/γ/v/g;
  $thing =~ s/‘/'/g;
  $thing =~ s/`/'/g;
  $thing =~ s/´/'/g;
  $thing =~ s/’/'/g;
  $thing =~ s/“/"/g;
  $thing =~ s/”/"/g;
  $thing =~ s/±/plus or minus/g;
  $thing =~ s/-/-/g;
  $thing =~ s/–/-/g;
  $thing =~ s/β/beta/g;
  $thing =~ s/μ/micro/g;
  $thing =~ s/µ/micro/g;
  $thing =~ s/ε/epsilon/g;
  $thing =~ s/ß/beta/g;
  $thing =~ s/²/2/g;
  $thing =~ s/³/3 /g;
  $thing =~ s/º/degrees/g;
  $thing =~ s/°/degrees/g;
  $thing =~ s/§//g;
  $thing =~ s/¶//g;
  $thing =~ s/†//g;
  $thing =~ s///g;
  $thing =~ s///g;
  $thing =~ s///g;
  $thing =~ s///g;
  $thing =~ s/ / /g;
  $thing =~ s///g;
  $thing =~ s/‡//g;
  $thing =~ s/•//g;
  $thing =~ s/ +/ /g;
  my (@chars) = split//, $thing;
  $thing = '';
  foreach (@chars) { if ($_ =~ m/[\s\w\~\`\!\@\#\$\%\^\&\*\(\)\-\=\+\[\]\{\}\;\:\'\"\,\<\.\>\/\?\\\|]/) { $thing .= $_; } }
  return $thing;
}

__END__

These are still there somehow

BAD  EB
BAD  EB
BAD  EB
BAD Ï EB
BAD ¢ EB
BAD ¡ EB
BAD  EB
BAD â EB
BAD  EB

