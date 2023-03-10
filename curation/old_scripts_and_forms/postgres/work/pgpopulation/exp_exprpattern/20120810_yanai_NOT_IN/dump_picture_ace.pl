#!/usr/bin/perl -w

# dump pic_ data for pictures.ace  2010 11 16
#
# give errors if object name has leading or trailing spaces, and if the number doesn't match the pgid.  2010 10 21
#
# give errors for multiple pgids with the same source value  2011 01 13
#
# added  &filterAce();  for Daniela to filter some characters.  Only using them on description, source, remark, 
# and urlaccession  since the others are contolled vocabulary.  2011 01 25
#
# no longer dump Database object (WBPaper_URL) for each Picture object.  Changed Database object from 
# Mappings.txt for the stripped_jourfull.  2011 02 10
#
# strip doublequotes from template, so that it can be printed later.  2011 02 24
#
# added some extra characters, not sure they copied properly.
# reads picture_source file to get mapping or urlaccession for the Article_URL line if there's not urlaccession
# data in postgres.  2011 03 02
#
# give errors for multiple pgids with the same paper-source value.  2011 02 22


use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

use lib qw( /home/postgres/work/citace_upload/papers/ );	# to generate brief citation
use get_brief_citation;


my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my $outfile = 'pictures.ace';
my $errfile = 'pictures.err';
open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
open (ERR, ">$errfile") or die "Cannot create $errfile : $!";

my @tables = qw( anat_term goid nodump persontext urlaccession chris description lifestage paper remark croppedfrom exprpattern name person source contact );

my %database_entries;

my %urlacc;
&readUrlacc();
sub readUrlacc {
  my $infile = '/home/acedb/draciti/picture_source/picture_source';
  open (IN, "<$infile") or die "Cannot open $infile : $!";
  while (my $line = <IN>) {
    my ($paper, $filename, $urlaccession) = split/\t/, $line;
    if ($urlaccession) { $urlacc{$paper} = $urlaccession; }
  } # while (my $line = <IN>)
  close (IN) or die "Cannot close $infile : $!";
} # sub readUrlacc


my %mappings;
my $mappingfile = 'Mappings.txt';
open (IN, "<$mappingfile") or die "Cannot open $mappingfile : $!";
my $junk_header_line = <IN>;		# always skip headers
while (my $line = <IN>) {
  chomp $line;
  next unless $line;
  my ($pubname, $puburl, $journame, $jourfull, $joururl, $arturl, $template) = split/\t/, $line;
  unless ($journame) { print ERR "there is no journal name in the 3rd column in the mapping file in $line\n"; } 
  next unless $journame;

  if ( $puburl ) { $puburl =~ s/\//\\\//g; }	# escape for .ace file for daniela  2010 12 15
  if ( $joururl ) { $joururl =~ s/\//\\\//g; }
  if ( $arturl ) { $arturl =~ s/\//\\\//g; }

  $mappings{pubname}{$journame} = $pubname;
  my $stripped_pubname = $pubname; $stripped_pubname =~ s/\s//g; 
  $mappings{strippedpubname}{$journame} = $stripped_pubname;
  $mappings{puburl}{$journame} = $puburl;
  $mappings{journame}{$journame} = $journame;
  my $stripped_jourfull = $jourfull; $stripped_jourfull =~ s/\s//g; 
  $mappings{jourfull}{$journame} = $jourfull;
  $mappings{strippedjourfull}{$journame} = $stripped_jourfull;
  $mappings{joururl}{$journame} = $joururl;
  $mappings{arturl}{$journame} = $arturl;
  if ($template =~ m/^\"/) { $template =~ s/^\"//; }	# sometimes the excel file saves with doublequotes, other times it doesn't, so always strip them and then print them 
  if ($template =~ m/\"$/) { $template =~ s/\"$//; }
  $mappings{template}{$journame} = $template;
  
  unless ($pubname) { print ERR "no Publisher_name for $line\n"; $pubname = 'BLANK'; }
  unless ($puburl) { print ERR "no Publisher_URL for $line\n"; $puburl = 'BLANK'; }
  unless ($journame) { print ERR "no Journal Name for $line\n"; $journame = 'BLANK'; }
  unless ($jourfull) { print ERR "no Full Journal Name for $line\n"; $jourfull = 'BLANK'; }
  unless ($joururl) { print ERR "no Journal_URL for $line\n"; $joururl = 'BLANK'; }
  unless ($arturl) { print ERR "no Article_URL for $line\n"; $arturl = 'BLANK'; }
  unless ($template) { print ERR "no Template Text for $line\n"; $template = 'BLANK'; }
  my $entry = '';
  $entry .= "Database : \"$stripped_pubname\"\n";
  $entry .= "Name\t\"$pubname\"\n";
  $entry .= "URL_constructor\t\"$puburl\"\n";
  $entry .= "\n";
  $database_entries{$entry}++;
  $entry = '';
  $entry .= "Database : \"$stripped_jourfull\"\n";
  $entry .= "Name\t\"$jourfull\"\n";
  $entry .= "URL\t\"$joururl\"\n";
  $entry .= "URL_constructor\t\"$arturl\"\n";
  $entry .= "\n";
  $database_entries{$entry}++;
} # while (my $line = <IN>)
close (IN) or die "Cannot close $mappingfile : $!";

foreach my $entry (sort keys %database_entries) {
  print OUT $entry;
}

my %data;
foreach my $table (@tables) {
  $result = $dbh->prepare( "SELECT * FROM pic_$table WHERE pic_$table IS NOT NULL;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { 
    if ($row[1] =~ m/\n/) { $row[1] =~ s/\n/ /g; }
    $data{$table}{$row[0]} = $row[1]; }
}

my %hash;
my %temp;
foreach my $pgid (keys %{ $data{person} }) { 
  my ($data) = $data{person}{$pgid} =~ m/^\"(.*)\"$/;
  my (@data) = split/\",\"/, $data;
  foreach my $person (@data) { $person =~ s/WBPerson/two/; $temp{$person}++; } }
my $person_joinkeys = join"','", keys %temp; %temp = ();
$result = $dbh->prepare( "SELECT * FROM two_standardname WHERE joinkey IN ('$person_joinkeys') ;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $hash{person}{$row[0]} = $row[2]; }
# print "$person_joinkeys\n";

foreach my $pgid (keys %{ $data{paper} }) { 
  my ($paper) = $data{paper}{$pgid} =~ m/WBPaper(\d+)/;
  $temp{$paper}++; }
my $paper_joinkeys = join"','", keys %temp; %temp = ();
$result = $dbh->prepare( "SELECT * FROM pap_journal WHERE joinkey IN ('$paper_joinkeys') ;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $hash{journal}{$row[0]} = $row[1]; }
$result = $dbh->prepare( "SELECT * FROM pap_year WHERE joinkey IN ('$paper_joinkeys') ;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $hash{year}{$row[0]} = $row[1]; }
$result = $dbh->prepare( "SELECT * FROM pap_title WHERE joinkey IN ('$paper_joinkeys') ;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $hash{title}{$row[0]} = $row[1]; }
$result = $dbh->prepare( "SELECT pap_author.joinkey, pap_author.pap_author, pap_author_index.pap_author_index, pap_author.pap_order FROM  pap_author, pap_author_index WHERE pap_author.joinkey IN ('$paper_joinkeys') AND pap_author.pap_author = pap_author_index.author_id ORDER BY pap_author.joinkey, pap_author.pap_order::integer DESC;" );
# print "SELECT pap_author.joinkey, pap_author.pap_author, pap_author_index.pap_author_index, pap_author.pap_order FROM  pap_author, pap_author_index WHERE pap_author.joinkey IN ('$paper_joinkeys') AND pap_author.pap_author = pap_author_index.author_id ORDER BY pap_author.joinkey, pap_author.pap_order::integer DESC; \n" ;
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { 
  if ($hash{firstauthor}{$row[0]}) { $hash{firstauthor}{$row[0]} = "$row[2] et al."; }	# if already have more authors, author + et al.
    else { $hash{firstauthor}{$row[0]} = $row[2]; } }					# if only author, just the author


# my %source;	# give errors for multiple pgids with the same source value  2011 01 13	# some source names exist in different papers, so do separately below  2011 03 22

foreach my $pgid (sort {$a<=>$b} keys %{ $data{name} }) {
  next if ($data{nodump}{$pgid});
  my $entry = '';
  my $database_entry = '';
  if ($data{name}{$pgid} =~ m/^\s+/) { print ERR "$pgid $data{name}{$pgid} has leading spaces\n"; }
  if ($data{name}{$pgid} =~ m/\s+$/) { print ERR "$pgid $data{name}{$pgid} has trailing spaces\n"; }
  my ($num) = $data{name}{$pgid} =~ m/(\d+)/; $num =~ s/^0+//g; 
  if ($num != $pgid) { print ERR "$pgid $data{name}{$pgid} is not the same number\n"; }
  $entry .= "Picture : \"$data{name}{$pgid}\"\n";

  if ($data{description}{$pgid}) { 
    my ($data) = &filterAce($data{description}{$pgid});
    $data =~ s/\n/ /g; $data =~ s/ +/ /g;	# daniela wants no linebreaks dumped, and multiple spaces converted to a single space 2011 02 09
    my (@data) = split/ \| /, $data;		# daniela wants description split on pipes
    foreach my $data (@data) { $entry .= "Description\t\"$data\"\n"; } }
  if ($data{source}{$pgid}) { 
    my ($data) = &filterAce($data{source}{$pgid});
    $entry .= "Name\t\"$data{source}{$pgid}\"\n"; } # $source{$data}{$pgid}++;
  if ($data{croppedfrom}{$pgid}) { $entry .= "Cropped_from\t\"$data{croppedfrom}{$pgid}\"\n"; }
  if ($data{remark}{$pgid}) {
    my ($data) = &filterAce($data{remark}{$pgid});
    $entry .= "Remark\t\"$data\"\n"; }
  if ($data{exprpattern}{$pgid}) { 
    my ($data) = $data{exprpattern}{$pgid} =~ m/^\"(.*)\"$/;
    my (@data) = split/\",\"/, $data;
    foreach my $data (@data) { $entry .= "Expr_pattern\t\"$data\"\n"; } }
  if ($data{goid}{$pgid}) { 
    my ($data) = $data{goid}{$pgid} =~ m/^\"(.*)\"$/;
    my (@data) = split/\",\"/, $data;
    foreach my $data (@data) { $entry .= "Cellular_component\t\"$data\"\n"; } }
  if ($data{anat_term}{$pgid}) { 
    my ($data) = $data{anat_term}{$pgid} =~ m/^\"(.*)\"$/;
    my (@data) = split/\",\"/, $data;
    foreach my $data (@data) { $entry .= "Anatomy\t\"$data\"\n"; } }
  if ($data{contact}{$pgid}) { 
    my ($data) = $data{contact}{$pgid} =~ m/^\"(.*)\"$/;
    my (@data) = split/\",\"/, $data;
    $entry .= "Template\t\"WormBase thanks <Person_name> for providing the pictures.\"\n";
#     if ($data{source}{$pgid}) { $entry .= "Name\t\"$data[0]_$data{source}{$pgid}\"\n"; }
    foreach my $data (@data) { $entry .= "Contact\t\"$data\"\n"; } }
  if ($data{person}{$pgid} && $data{persontext}{$pgid}) {
      my ($data) = $data{person}{$pgid} =~ m/^\"(.*)\"$/;
      my (@data) = split/\",\"/, $data; my @persons;
      foreach my $person (@data) {
        $person =~ s/WBPerson/two/;
        if ($hash{person}{$person}) { push @persons, $hash{person}{$person}; }
          else { print ERR "$pgid $person not a valid person\n"; } }
      $data = join", ", @persons; $data .= ', ' . $data{persontext}{$pgid};
      $entry .= "Person_name\t\"$data\"\n"; }
    elsif ($data{person}{$pgid}) {
      my ($data) = $data{person}{$pgid} =~ m/^\"(.*)\"$/;
      my (@data) = split/\",\"/, $data; my @persons;
      foreach my $person (@data) {
        $person =~ s/WBPerson/two/;
        if ($hash{person}{$person}) { push @persons, $hash{person}{$person}; }
          else { print ERR "$pgid $person not a valid person\n"; } }
      if (scalar @persons == 1) { $entry .= "Person_name\t\"$persons[0]\"\n"; }
        elsif (scalar @persons == 2) { $entry .= "Person_name\t\"$persons[0] and $persons[1]\"\n"; }
        else {
          my $last_person = pop @persons;
          my $persons = join", ", @persons; 
          $persons .= ", and $last_person";
          $entry .= "Person_name\t\"$persons\"\n"; } }
    elsif ($data{persontext}{$pgid}) { $entry .= "Person_name\t\"$data{persontext}{$pgid}\"\n"; }
  if ($data{paper}{$pgid}) { 
    my $wbpaper = $data{paper}{$pgid};
    $entry .= "Reference\t\"$wbpaper\"\n"; 
#     if ($data{source}{$pgid}) { $entry .= "Name\t\"${wbpaper}_$data{source}{$pgid}\"\n"; }
    my ($joinkey) = $wbpaper =~ m/WBPaper(\d+)/;
    my $year = 'BLANK';
    if ($hash{year}{$joinkey}) { 
        $year = $hash{year}{$joinkey};
        $entry .= "Publication_year\t\"$hash{year}{$joinkey}\"\n"; 
      }
      else { print ERR "$pgid no year for $wbpaper\n"; }
    if ($hash{journal}{$joinkey}) { 
#         print "journal : $hash{journal}{$joinkey}\n"; 
        my $journal = $hash{journal}{$joinkey};
        if ($mappings{journame}{$journal}) {
            if ($mappings{strippedjourfull}{$journal}) { 
                if ($data{urlaccession}{$pgid}) {		# new output line for Daniela  2011 02 22
                    my ($urlaccession) = &filterAce($data{urlaccession}{$pgid});
                    $entry .= "Article_URL\t\"$mappings{strippedjourfull}{$journal}\" \"id\" \"$urlaccession\"\n"; }
                elsif ($urlacc{$wbpaper}) {
                    my ($urlaccession) = &filterAce($urlacc{$wbpaper});
                    $entry .= "Article_URL\t\"$mappings{strippedjourfull}{$journal}\" \"id\" \"$urlaccession\"\n"; }
                  else { print ERR "$pgid no urlaccession for $wbpaper\n"; }
                $entry .= "Journal_URL\t\"$mappings{strippedjourfull}{$journal}\"\n"; }
              else { print ERR "$pgid no stripped Full Journal Name for $journal\n"; }
            if ($mappings{strippedpubname}{$journal}) { $entry .= "Publisher_URL\t\"$mappings{strippedpubname}{$journal}\"\n"; }
              else { print ERR "$pgid no stripped Publisher_name journal for $journal\n"; }
#             if ($data{urlaccession}{$pgid}) {		# Daniela never wants the Database object WBPaper_URL anymore  2011 02 10
#                 my ($urlaccession) = &filterAce($data{urlaccession}{$pgid});
#                 $database_entry .= "Database : ${wbpaper}_URL\n";
#                 my ($firstauthor, $title);
#                 if ($hash{firstauthor}{$joinkey}) { $firstauthor = $hash{firstauthor}{$joinkey}; }
#                 if ($hash{title}{$joinkey}) { $title = $hash{title}{$joinkey}; }
#                 my ($brief_citation) = &getBriefCitation( $firstauthor, $year, $journal, $title ); # from package
#                 $database_entry .= "Name\t\"$brief_citation\"\n";
#                 $database_entry .= "URL_constructor\t\"$mappings{arturl}{$journal}\"\n";
#                 $database_entry .= "\n";
#                 $entry .= "Article_URL\t${wbpaper}_URL id $urlaccession\n"; }
#               else { print ERR "$pgid no urlaccession for $wbpaper\n"; }
            if ($mappings{template}{$journal}) { 
                my $template = $mappings{template}{$journal};
# don't actually want to replace stuff in angle brackets, for Daniela.  2010 11 17 
#                 if ($mappings{joururl}{$journal}) { $template =~ s/<Journal_URL>/$mappings{joururl}{$journal}/g; }
#                   else { print ERR "$pgid no Journal URL for $journal\n"; }
#                 if ($mappings{arturl}{$journal}) { $template =~ s/<Article_URL>/$mappings{arturl}{$journal}/g; }
#                   else { print ERR "$pgid no Article URL for $journal\n"; }
#                 if ($mappings{puburl}{$journal}) { $template =~ s/<Publisher_URL>/$mappings{puburl}{$journal}/g; }
#                   else { print ERR "$pgid no Publisher URL for $journal\n"; }
#                 if ($year) { $template =~ s/<Publication_year>/$year/g; }
                $entry .= "Template\t\"$template\"\n"; }
              else { print ERR "$pgid no Template Text journal for $journal\n"; }
          }
          else { print ERR "$pgid no mapping file entry for $journal in paper $wbpaper\n"; }
      }
      else { print ERR "$pgid no journal for $wbpaper\n"; }
  }
  $entry .= "\n";
  print OUT $entry;
  if ($database_entry) { print OUT $database_entry; }
} # foreach my $pgid (sort {$a<=>$b} keys %{ $data{name} })
#   $mappings{pubname}{$journame} = $pubname;
#   $mappings{puburl}{$journame} = $puburl;
#   $mappings{journame}{$journame} = $journame;
#   $mappings{jourfull}{$journame} = $jourfull;
#   $mappings{joururl}{$journame} = $joururl;
#   $mappings{arturl}{$journame} = $arturl;
#   $mappings{template}{$journame} = $template;

# foreach my $source (sort keys %source) {	# give errors for multiple pgids with the same source value  2011 01 13
#   my (@pgids) = keys %{ $source{$source} };
#   if (scalar(@pgids) > 1) { print ERR "Multiple pgids @pgids with source $source\n"; }
# } # foreach my $source (sort keys %source)

my %paper_source;
$result = $dbh->prepare( " SELECT pic_source.pic_source, pic_paper.pic_paper, pic_source.joinkey FROM pic_source, pic_paper WHERE pic_source.joinkey = pic_paper.joinkey ; " );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) {
  my $key = "$row[1]\t$row[0]";
  $paper_source{$key}{$row[2]}++; }
foreach my $paper_source (sort keys %paper_source) {	# give errors for multiple pgids with the same paper-source value  2011 02 22
  my (@pgids) = keys %{ $paper_source{$paper_source} };
  if (scalar(@pgids) > 1) { print ERR "Multiple pgids @pgids with paper-source $paper_source\n"; } }



close (OUT) or die "Cannot close $outfile : $!";
close (ERR) or die "Cannot close $errfile : $!";


sub filterAce {
  my $data = shift;
  if ($data =~ m/\//) { $data =~ s/\//\\\//g; }
  if ($data =~ m/\"/) { $data =~ s/\"/\\\"/g; }
  if ($data =~ m/\s+$/) { $data =~ s/\s+$//; }
  if ($data =~ m/µ/) { $data =~ s/µ/u/g; }
  if ($data =~ m/¬±/) { $data =~ s/¬±/+\/-/g; }
  if ($data =~ m/±/) { $data =~ s/±/+\/-/g; }
  if ($data =~ m/â€²/) { $data =~ s/â€²/'/g; }
  if ($data =~ m/ââ¬²/) { $data =~ s/ââ¬²/'/g; }
  if ($data =~ m/â¬/) { $data =~ s/â¬/pi/g; }
  if ($data =~ m/âË¼/) { $data =~ s/âË¼/~/g; }
  if ($data =~ m/ââ°¥/) { $data =~ s/ââ°¥/≥/g; }
  if ($data =~ m/Ãâ/) { $data =~ s/Ãâ/x/g; }
  if ($data =~ m/â/) { $data =~ s/â/'/g; }
  if ($data =~ m/ÂÎ¼/) { $data =~ s/ÂÎ¼/u/g; }
  if ($data =~ m/Â¼/) { $data =~ s/Â¼/u/g; }
  if ($data =~ m/Î¼/) { $data =~ s/Î¼/u/g; }
  if ($data =~ m/¼/) { $data =~ s/¼/u/g; }
  if ($data =~ m/Î±/) { $data =~ s/Î±/alpha/g; }
  if ($data =~ m/Â±/) { $data =~ s/Â±/alpha/g; }
  if ($data =~ m/β/) { $data =~ s/β/beta/g; }
  if ($data =~ m/Î²/) { $data =~ s/Î²/beta/g; }
  if ($data =~ m/²/) { $data =~ s/²/beta/g; }
  if ($data =~ m/¡C/) { $data =~ s/¡C/C/g; }
  if ($data =~ m/Â°/) { $data =~ s/Â°/°/g; }
  if ($data =~ m/°/) { $data =~ s/°/°/g; }
  if ($data =~ m/Ð/) { $data =~ s/Ð/- /g; }
  if ($data =~ m/&lt;/) { $data =~ s/&lt;/</g; }
  if ($data =~ m/&gt;/) { $data =~ s/&gt;/>/g; }
  return $data;
} # sub filterAce

# Daniela, to copy-paste a line, do 'yy' for yank line, then 'p' for paste
# 'x' to delete characters
# 'h' 'j' 'k' 'l' to move around like arrows
# type 'vimtutor' on shell for tutorial on how to use vim

__END__

my $result = $dbh->prepare( "SELECT * FROM two_comment WHERE two_comment ~ ?" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
} # while (@row = $result->fetchrow)

__END__

