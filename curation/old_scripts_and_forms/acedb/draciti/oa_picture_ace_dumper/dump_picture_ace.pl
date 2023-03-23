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
#
# added pic_process to dump as WBProcess.  2014 10 22
#
# added pic_species to dump as Species.  2014 12 03
#
# dump process if there's a paper with journal, then error message if the journal does not have permission.  2014 12 12
#
# also dump Life_stage  2015 04 15
#
# Have changed OA to allow utf-8 characters to write to postgres.  Need to convert data read from postgres
# to html entities do they're not lost at acedb.  Using HTML::Entities encode_entities, and Encode decode.
# 2021 04 09
#
# rewritten to be more generalized, getting tables / fields from wormOA, and splitting multivalue data based 
# on the OA field's type.  2021 04 10
#
# Note that ' are getting converted to &#39;  If we don't want that, we'd have to add a conversion back to '
# in utf8ToHtml  2021 04 11


use strict;
use diagnostics;
use DBI;
use Jex;		# getSimpleDate

use lib qw( /home/postgres/work/citace_upload/papers/ );	# to generate brief citation
use get_brief_citation;

use lib qw( /home/postgres/work/citace_upload/ );               # for general ace dumping functions
use ace_dumper;

use lib qw( /home/postgres/public_html/cgi-bin/oa/ );		# to get tables/fields and which ones to split as multivalue
use wormOA;

my $datatype = 'pic';
my ($fieldsRef, $datatypesRef) = &initModFields($datatype, 'two1823');
my %fields = %$fieldsRef;
my %datatypes = %$datatypesRef;
my %theHash;


my $simpleRemapHashRef = &populateSimpleRemap();

my $deadObjectsHashRef = &populateDeadObjects();
my %deadObjects = %$deadObjectsHashRef;


my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my $date = &getSimpleDate();

# my $outfile = 'pictures.ace';
# my $errfile = 'pictures.err';
my $outfile = 'pictures.ace.' . $date;
my $errfile = 'pictures.err.' . $date;
open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
open (ERR, ">$errfile") or die "Cannot create $errfile : $!";

my %pipeSplit;
$pipeSplit{'description'}++;

my %aceTag;
$aceTag{'source'} = "Name";
$aceTag{'description'} = "Description";
$aceTag{'croppedfrom'} = "Cropped_from";
$aceTag{'remark'} = "Remark";
$aceTag{'species'} = "Species";
$aceTag{'exprpattern'} = "Expr_pattern";
$aceTag{'wbgene'} = "Gene";
$aceTag{'goid'} = "Cellular_component";
$aceTag{'anat_term'} = "Anatomy";
$aceTag{'lifestage'} = "Life_stage";
$aceTag{'contact'} = "Contact";

my %tableToOntology;
$tableToOntology{'anat_term'} = 'anatomy';

# generic way to query postgres for all OA fields for the datatype, and store in arrays of html encoded entities
foreach my $table (sort keys %{ $fields{$datatype} }) {
  next if ($table eq 'id');		# skip pgid column
#   print qq(F $table F\n);
#   $result = $dbh->prepare( "SELECT * FROM ${datatype}_$table WHERE ${datatype}_$table IS NOT NULL AND joinkey IN ('1', '2', '3');" );
  $result = $dbh->prepare( "SELECT * FROM ${datatype}_$table WHERE ${datatype}_$table IS NOT NULL;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { 
    next unless $row[1];
    if ($row[1] =~ m/\n/) { $row[1] =~ s/\n/ /g; }
    if ( ($fields{$datatype}{$table}{type} eq 'multiontology') || ($fields{$datatype}{$table}{type} eq 'multidropdown') ) {
      my ($data) = $row[1] =~ m/^\"(.*)\"$/;
      my (@data) = split/\",\"/, $data;
      foreach my $entry (@data) {
        $entry = &utf8ToHtml($simpleRemapHashRef, $entry);
        if ($entry) {
          push @{ $theHash{$table}{$row[0]} }, $entry; } }
    }
    elsif ($pipeSplit{$table}) {
      my (@data) = split/\|/, $row[1];
      foreach my $entry (@data) {
        $entry = &utf8ToHtml($simpleRemapHashRef, $entry);
        if ($entry) {
          push @{ $theHash{$table}{$row[0]} }, $entry; } }
    }
    else {
      my $entry = &utf8ToHtml($simpleRemapHashRef, $row[1]);
      if ($entry) { 
        push @{ $theHash{$table}{$row[0]} }, $entry; } 
    }
  } # while (my @row = $result->fetchrow)
} # foreach my $table (sort keys %{ $fields{$datatype} })

# test output of what gets stored in data hash
# foreach my $field (sort keys %theHash) {
#   foreach my $pgid (sort keys %{ $theHash{$field} }) {
#     print qq($pgid\t$field\t$theHash{$field}{$pgid}[0]\n); } }



# extra stuff for picture processing

my %hash;
my %temp;
foreach my $pgid (keys %{ $theHash{person} }) { 
  foreach my $entry (@{ $theHash{person}{$pgid} }) { my $person = $entry; $person =~ s/WBPerson/two/; $temp{$person}++; } }
my $person_joinkeys = join"','", keys %temp; %temp = ();
$result = $dbh->prepare( "SELECT * FROM two_standardname WHERE joinkey IN ('$person_joinkeys') ;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { 
  $row[2] = &utf8ToHtml($simpleRemapHashRef, $row[2]); 
#   print qq($row[0]\t$row[2]\n);
  $row[0] =~ s/two/WBPerson/;
  $hash{person}{$row[0]} = $row[2]; }
# print "$person_joinkeys\n";


# foreach my $pgid (keys %{ $theHash{paper} }) { 
#   my ($paper) = $theHash{paper}{$pgid} =~ m/WBPaper(\d+)/;
#   $temp{$paper}++; }
foreach my $pgid (keys %{ $theHash{paper} }) { 
  foreach my $entry (@{ $theHash{paper}{$pgid} }) { my $paper = $entry; $paper =~ s/WBPaper//; $temp{$paper}++; } }
my $paper_joinkeys = join"','", keys %temp; %temp = ();
$result = $dbh->prepare( "SELECT * FROM pap_journal WHERE joinkey IN ('$paper_joinkeys') ;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $hash{journal}{$row[0]} = &utf8ToHtml($simpleRemapHashRef, $row[1]); }
$result = $dbh->prepare( "SELECT * FROM pap_year WHERE joinkey IN ('$paper_joinkeys') ;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $hash{year}{$row[0]} = &utf8ToHtml($simpleRemapHashRef, $row[1]); }
$result = $dbh->prepare( "SELECT * FROM pap_title WHERE joinkey IN ('$paper_joinkeys') ;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $hash{title}{$row[0]} = &utf8ToHtml($simpleRemapHashRef, $row[1]); }
$result = $dbh->prepare( "SELECT pap_author.joinkey, pap_author.pap_author, pap_author_index.pap_author_index, pap_author.pap_order FROM  pap_author, pap_author_index WHERE pap_author.joinkey IN ('$paper_joinkeys') AND pap_author.pap_author = pap_author_index.author_id ORDER BY pap_author.joinkey, pap_author.pap_order::integer DESC;" );
# print "SELECT pap_author.joinkey, pap_author.pap_author, pap_author_index.pap_author_index, pap_author.pap_order FROM  pap_author, pap_author_index WHERE pap_author.joinkey IN ('$paper_joinkeys') AND pap_author.pap_author = pap_author_index.author_id ORDER BY pap_author.joinkey, pap_author.pap_order::integer DESC; \n" ;
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { 
  if ($hash{firstauthor}{$row[0]}) { $hash{firstauthor}{$row[0]} = &utf8ToHtml($simpleRemapHashRef, "$row[2] et al."); }	# if already have more authors, author + et al.
    else { $hash{firstauthor}{$row[0]} = &utf8ToHtml($simpleRemapHashRef, $row[2]); } }					# if only author, just the author


my %mappings;
my %database_entries;
&readMappings();
my %urlacc;
&readUrlacc();
my %journal_has_permission;                       # dump process (topic) only if the paper is from a journal with permission
&readJournalHasPermission();


foreach my $pgid (sort {$a<=>$b} keys %{ $theHash{name} }) {
  next if ($theHash{nodump}{$pgid});
  my $entry = '';
  if ($theHash{name}{$pgid}[0] =~ m/^\s+/) { print ERR "$pgid $theHash{name}{$pgid}[0] has leading spaces\n"; }
  if ($theHash{name}{$pgid}[0] =~ m/\s+$/) { print ERR "$pgid $theHash{name}{$pgid}[0] has trailing spaces\n"; }
  my ($num) = $theHash{name}{$pgid}[0] =~ m/(\d+)/; $num =~ s/^0+//g; 
  if ($num != $pgid) { print ERR "$pgid $theHash{name}{$pgid}[0] is not the same number\n"; }
  $entry .= qq(Picture : "$theHash{name}{$pgid}[0]"\n);

  # dump out generic simple ace tags
  foreach my $field (sort keys %aceTag) {
    foreach my $data (@{ $theHash{$field}{$pgid} }) {
      $data =~ s/\n/ /g; $data =~ s/ +/ /g;	# daniela wants no linebreaks dumped, and multiple spaces converted to a single space 2011 02 09
      ($data) = &filterAce($data);
      if ($data) {
        my $ontology = $field;
        if ($tableToOntology{$field}) { $ontology = $tableToOntology{$field}; }
        if ($deadObjects{$ontology}{$data}) { print ERR "$theHash{name}{$pgid}[0] has dead $field $data $deadObjects{$ontology}{$data}\n"; }
          else { $entry .= qq($aceTag{$field}\t"$data"\n); } } } }

  # this is fairly simplifed, original had different way of separating persons
  my @persons = ();
  if ($theHash{person}{$pgid}) {
    foreach my $person (@{ $theHash{person}{$pgid} }) {
#       print qq($pgid\t$person\n);
      if ($hash{person}{$person}) { push @persons, $hash{person}{$person}; } } }
  if ( ($theHash{person}{$pgid}) && ($theHash{persontext}{$pgid}[0]) ) {
    my $data = join", ", @persons;
    $data .= ', ' . $theHash{persontext}{$pgid}[0];
    $entry .= qq(Person_name\t"$data"\n); }
  elsif ($theHash{persontext}{$pgid}[0]) {
    $entry .= qq(Person_name\t"$theHash{persontext}{$pgid}[0]"\n); }
  elsif ($theHash{person}{$pgid}) {
    if (scalar @persons == 1) { $entry .= "Person_name\t\"$persons[0]\"\n"; }
      elsif (scalar @persons == 2) { $entry .= "Person_name\t\"$persons[0] and $persons[1]\"\n"; }
      else {
        my $last_person = pop @persons;
        my $persons = join", ", @persons; 
        $persons .= ", and $last_person";
        $entry .= "Person_name\t\"$persons\"\n"; } }


  if ($theHash{paper}{$pgid}[0]) { 
    my $wbpaper = $theHash{paper}{$pgid}[0];
    $entry .= qq(Reference\t"$wbpaper"\n); 
    my ($joinkey) = $wbpaper =~ m/WBPaper(\d+)/;
    if ($hash{year}{$joinkey}) { 
        $entry .= qq(Publication_year\t"$hash{year}{$joinkey}"\n); }
      else { print ERR "$pgid no year for $wbpaper\n"; }
    if ($hash{journal}{$joinkey}) {
        my $journal = $hash{journal}{$joinkey};
        if ($theHash{process}{$pgid}) {	# dump process if there's a paper with journal, then error message if the journal does not have permission.  2014 12 12
          foreach my $data (@{ $theHash{process}{$pgid} }) {
            ($data) = &filterAce($data);
            $entry .= qq(WBProcess\t"$data"\n); }
          unless ($journal_has_permission{$journal}) {	# only if journal has permission, dump process/topic objects
            print ERR qq($pgid has process but not permission for WBPaper$joinkey : $journal\n); } }
        if ($mappings{journame}{$journal}) {
            if ($mappings{strippedjourfull}{$journal}) {
                if ($theHash{urlaccession}{$pgid}[0]) {		# new output line for Daniela  2011 02 22
                    my ($urlaccession) = &filterAce($theHash{urlaccession}{$pgid}[0]);
                    $entry .= qq(Article_URL\t"$mappings{strippedjourfull}{$journal}" "id" "$urlaccession"\n); }
                  elsif ($urlacc{$wbpaper}) {
                    my ($urlaccession) = &filterAce($urlacc{$wbpaper});
                    $entry .= qq(Article_URL\t"$mappings{strippedjourfull}{$journal}" "id" "$urlaccession"\n); }
                  else { print ERR "$pgid no urlaccession for $wbpaper\n"; }
                $entry .= qq(Journal_URL\t"$mappings{strippedjourfull}{$journal}"\n); }
              else { print ERR "$pgid no stripped Full Journal Name for $journal\n"; }
            if ($mappings{strippedpubname}{$journal}) { $entry .= qq(Publisher_URL\t"$mappings{strippedpubname}{$journal}"\n); }
              else { print ERR "$pgid no stripped Publisher_name journal for $journal\n"; }
            if ($mappings{template}{$journal}) {
#                 my $template = $mappings{template}{$journal};
                my $template = &utf8ToHtmlWithoutDecode($simpleRemapHashRef, $mappings{template}{$journal});	# Daniela's file does no need to decode utf-8 for some reason
                $entry .= qq(Template\t"$template"\n); }
              else { print ERR "$pgid no Template Text journal for $journal\n"; }
          }
          else { print ERR "$pgid no mapping file entry for $journal in paper $wbpaper\n"; }
      }
#       else { print ERR "$pgid no journal for $wbpaper\n"; }
  }
  $entry .= "\n";
  print OUT $entry;
} # foreach my $pgid (sort {$a<=>$b} keys %{ $theHash{name} })

foreach my $entry (sort keys %database_entries) { print OUT $entry; }

close (OUT) or die "Cannot close $outfile : $!";
close (ERR) or die "Cannot close $errfile : $!";



sub readMappings {
  my $mappingfile = '/home/acedb/draciti/oa_picture_ace_dumper/Mappings.txt';
  open (IN, "<$mappingfile") or die "Cannot open $mappingfile : $!";
#   my $junk_header_line = <IN>;		# always skip headers
  my $all_data = <IN>;		# always skip headers
  close (IN) or die "Cannot close $mappingfile : $!";
  my (@lines) = split//, $all_data;
#   while (my $line = <IN>) {
  foreach my $line (@lines) {
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
} # sub readMappings

sub readJournalHasPermission {
  my $journalpermission_file = '/home/acedb/draciti/picture_curatable/journal_with_permission';
  open (IN, "$journalpermission_file") or die "Cannot open $journalpermission_file : $!";
  while (my $line = <IN>) { chomp $line; $journal_has_permission{$line}++; }
  close (IN) or die "Cannot close $journalpermission_file : $!";
} # sub readJournalHasPermission


sub readUrlacc {
  my $infile = '/home/acedb/draciti/picture_source/picture_source';
  open (IN, "<$infile") or die "Cannot open $infile : $!";
  while (my $line = <IN>) {
    chomp $line;
    my ($paper, $filename, $urlaccession) = split/\t/, $line;
    if ($urlaccession) { $urlacc{$paper} = $urlaccession; }
  } # while (my $line = <IN>)
  close (IN) or die "Cannot close $infile : $!";
} # sub readUrlacc


# sub utf8ToHtml {
#   my $value = shift;
#   my $return = encode_entities(decode('utf-8', $value));
#   ($return) = &filterSimpleCharacters($return);
#   return $return;
# } # sub utf8ToHtml
# 
# sub utf8ToHtmlWithoutDecode {
#   my $value = shift;
#   my $return = encode_entities($value);
#   ($return) = &filterSimpleCharacters($return);
#   return $return;
# } # sub utf8ToHtml
# 
# 
# sub filterAce {
#   my $data = shift;
#   if ($data =~ m/\//) { $data =~ s/\//\\\//g; }
#   if ($data =~ m/\"/) { $data =~ s/\"/\\\"/g; }
#   return $data;
# }
# 
# 
# sub populateSimpleRemap {
#   $simpleRemap{"&#x2010;"} = '-';
#   $simpleRemap{"&ndash;"} = '-';
#   $simpleRemap{"&mdash;"} = '-';
#   $simpleRemap{"&quot;"} = '"';
#   $simpleRemap{"&prime;"} = "'";
#   $simpleRemap{"&#39;"} = "'";
#   $simpleRemap{"&lt;"} = "<";
#   $simpleRemap{"&gt;"} = ">";
# } # sub populateSimpleRemap
# 
# sub filterSimpleCharacters {
#   my $value = shift;
#   if ($value =~ m/&\S+;/) {
#     foreach my $htmlChar (sort keys %simpleRemap) {
#       my $simpleChar = $simpleRemap{$htmlChar};
#       if ($value =~ m/$htmlChar/) { $value =~ s/$htmlChar/$simpleChar/g; }
#     }
#   }
#   return $value;
# }

__END__

my @tables = qw( anat_term goid nodump persontext urlaccession chris description lifestage paper remark croppedfrom exprpattern name person source contact process species wbgene );

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

foreach my $entry (sort keys %database_entries) {
  print OUT $entry;
}

my %journal_has_permission;                       # dump process (topic) only if the paper is from a journal with permission
my $journalpermission_file = '/home/acedb/draciti/picture_curatable/journal_with_permission';
open (IN, "$journalpermission_file") or die "Cannot open $journalpermission_file : $!";
while (my $line = <IN>) { chomp $line; $journal_has_permission{$line}++; }
close (IN) or die "Cannot close $journalpermission_file : $!";


my %data;
foreach my $table (@tables) {
#   $result = $dbh->prepare( "SELECT * FROM pic_$table WHERE joinkey = '1';" );
  $result = $dbh->prepare( "SELECT * FROM pic_$table WHERE pic_$table IS NOT NULL;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { 
    if ($row[1] =~ m/\n/) { $row[1] =~ s/\n/ /g; }
#     if ($row[1]) { $row[1] = &utf8ToHtml($row[1])); 
    $data{$table}{$row[0]} = $row[1]; }
}

my %hash;
my %temp;
foreach my $pgid (keys %{ $data{person} }) { 
  my ($data) = $data{person}{$pgid} =~ m/^\"(.*)\"$/;
  my (@data) = split/\",\"/, $data;
  foreach my $entry (@data) { $person =~ s/WBPerson/two/; $temp{$person}++; } }
my $person_joinkeys = join"','", keys %temp; %temp = ();
$result = $dbh->prepare( "SELECT * FROM two_standardname WHERE joinkey IN ('$person_joinkeys') ;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { 
  $row[2] = &utf8ToHtml($row[2])); 
  $hash{person}{$row[0]} = $row[2]; }
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

sub splitPipe {
  my @return; my $data = shift;
  my (@data) = split/ \| /, $data;
  foreach my $entry (@data) { 
    if ($entry) { 
      $entry = encode_entities(decode('utf-8', $entry)); 
      push @return, $entry; } }
  return \@return;
}
sub splitDquote {
  my @return; my $data = shift;
  my (@data) = split/\",\"/, $data;
  foreach my $entry (@data) { 
    if ($entry) { 
      $entry = encode_entities(decode('utf-8', $entry)); 
      push @return, $entry; } }
  return \@return;
}

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
#     my (@data) = split/ \| /, $data;		# daniela wants description split on pipes
#     foreach my $data (@data) { $entry .= "Description\t\"$data\"\n"; }
    my $dataArrayRef = &splitPipe($data);
    foreach my $data (@$dataArrayRef) { $entry .= "Description\t\"$data\"\n"; } }
  if ($data{source}{$pgid}) { 
    my ($data) = &filterAce($data{source}{$pgid});
    $entry .= "Name\t\"$data{source}{$pgid}\"\n"; } # $source{$data}{$pgid}++;
  if ($data{croppedfrom}{$pgid}) { $entry .= "Cropped_from\t\"$data{croppedfrom}{$pgid}\"\n"; }
  if ($data{remark}{$pgid}) {
    my ($data) = &filterAce($data{remark}{$pgid});
    $entry .= "Remark\t\"$data\"\n"; }
  if ($data{species}{$pgid}) {
    my ($data) = &filterAce($data{species}{$pgid});
    $entry .= "Species\t\"$data\"\n"; }
  if ($data{exprpattern}{$pgid}) { 
    my ($data) = $data{exprpattern}{$pgid} =~ m/^\"(.*)\"$/;
#     my (@data) = split/\",\"/, $data;
#     foreach my $data (@data) { $entry .= "Expr_pattern\t\"$data\"\n"; }
    my $dataArrayRef = &splitDquote($data);
    foreach my $data (@$dataArrayRef) { $entry .= "Expr_pattern\t\"$data\"\n"; } }
  if ($data{wbgene}{$pgid}) { 
    my ($data) = $data{wbgene}{$pgid} =~ m/^\"(.*)\"$/;
#     my (@data) = split/\",\"/, $data;
#     foreach my $data (@data) { $entry .= "Gene\t\"$data\"\n"; }
    my $dataArrayRef = &splitDquote($data);
    foreach my $data (@$dataArrayRef) { $entry .= "Gene\t\"$data\"\n"; } }
  if ($data{goid}{$pgid}) { 
    my ($data) = $data{goid}{$pgid} =~ m/^\"(.*)\"$/;
#     my (@data) = split/\",\"/, $data;
#     foreach my $data (@data) { $entry .= "Cellular_component\t\"$data\"\n"; }
    my $dataArrayRef = &splitDquote($data);
    foreach my $data (@$dataArrayRef) { $entry .= "Cellular_component\t\"$data\"\n"; } }
  if ($data{anat_term}{$pgid}) { 
    my ($data) = $data{anat_term}{$pgid} =~ m/^\"(.*)\"$/;
#     my (@data) = split/\",\"/, $data;
#     foreach my $data (@data) { $entry .= "Anatomy\t\"$data\"\n"; }
    my $dataArrayRef = &splitDquote($data);
    foreach my $data (@$dataArrayRef) { $entry .= "Anatomy\t\"$data\"\n"; } }
  if ($data{lifestage}{$pgid}) { 
    my ($data) = $data{lifestage}{$pgid} =~ m/^\"(.*)\"$/;
#     my (@data) = split/\",\"/, $data;
#     foreach my $data (@data) { $entry .= "Life_stage\t\"$data\"\n"; }
    my $dataArrayRef = &splitDquote($data);
    foreach my $data (@$dataArrayRef) { $entry .= "Life_stage\t\"$data\"\n"; } }
  if ($data{contact}{$pgid}) { 
#     my ($data) = $data{contact}{$pgid} =~ m/^\"(.*)\"$/;
#     my (@data) = split/\",\"/, $data;
#     $entry .= "Template\t\"WormBase thanks <Person_name> for providing the pictures.\"\n";
#     if ($data{source}{$pgid}) { $entry .= "Name\t\"$data[0]_$data{source}{$pgid}\"\n"; }
#     foreach my $data (@data) { $entry .= "Contact\t\"$data\"\n"; }
    $entry .= "Contact\t\"$data{contact}{$pgid}\"\n"; }
  if ($data{person}{$pgid} && $data{persontext}{$pgid}) {
      my ($data) = $data{person}{$pgid} =~ m/^\"(.*)\"$/;
      my (@data) = split/\",\"/, $data; my @persons;
      foreach my $person (@data) {
        $person =~ s/WBPerson/two/;
        if ($hash{person}{$person}) { push @persons, $hash{person}{$person}; }
          else { print ERR "$pgid $person not a valid person\n"; } }
      my $person_text = $data{persontext}{$pgid};
      $person_text = encode_entities(decode('utf-8', $person_text)); 
      $data = join", ", @persons; $data .= ', ' . $person_text;
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
        if ($data{process}{$pgid}) {	# dump process if there's a paper with journal, then error message if the journal does not have permission.  2014 12 12
          my ($data) = $data{process}{$pgid} =~ m/^\"(.*)\"$/;
#           my (@data) = split/\",\"/, $data;
#           foreach my $data (@data) { $entry .= "WBProcess\t\"$data\"\n"; }
          my $dataArrayRef = &splitDquote($data);
          foreach my $data (@$dataArrayRef) { $entry .= "WBProcess\t\"$data\"\n"; }
          unless ($journal_has_permission{$journal}) {	# only if journal has permission, dump process/topic objects
            print ERR qq($pgid has process but not permission for WBPaper$joinkey : $journal\n); } }
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

# sub filterAce {
#   my $data = shift;
#   if ($data =~ m/\//) { $data =~ s/\//\\\//g; }
#   if ($data =~ m/\"/) { $data =~ s/\"/\\\"/g; }
#   if ($data =~ m/\s+$/) { $data =~ s/\s+$//; }
#   if ($data =~ m/µ/) { $data =~ s/µ/u/g; }
#   if ($data =~ m/¬±/) { $data =~ s/¬±/+\/-/g; }
#   if ($data =~ m/±/) { $data =~ s/±/+\/-/g; }
#   if ($data =~ m/â€²/) { $data =~ s/â€²/'/g; }
#   if ($data =~ m/ââ¬²/) { $data =~ s/ââ¬²/'/g; }
#   if ($data =~ m/â¬/) { $data =~ s/â¬/pi/g; }
#   if ($data =~ m/âË¼/) { $data =~ s/âË¼/~/g; }
#   if ($data =~ m/ââ°¥/) { $data =~ s/ââ°¥/≥/g; }
#   if ($data =~ m/Ãâ/) { $data =~ s/Ãâ/x/g; }
#   if ($data =~ m/â/) { $data =~ s/â/'/g; }
#   if ($data =~ m/ÂÎ¼/) { $data =~ s/ÂÎ¼/u/g; }
#   if ($data =~ m/Â¼/) { $data =~ s/Â¼/u/g; }
#   if ($data =~ m/Î¼/) { $data =~ s/Î¼/u/g; }
#   if ($data =~ m/¼/) { $data =~ s/¼/u/g; }
#   if ($data =~ m/Î±/) { $data =~ s/Î±/alpha/g; }
#   if ($data =~ m/Â±/) { $data =~ s/Â±/alpha/g; }
#   if ($data =~ m/β/) { $data =~ s/β/beta/g; }
#   if ($data =~ m/Î²/) { $data =~ s/Î²/beta/g; }
#   if ($data =~ m/²/) { $data =~ s/²/beta/g; }
#   if ($data =~ m/¡C/) { $data =~ s/¡C/C/g; }
#   if ($data =~ m/Â°/) { $data =~ s/Â°/°/g; }
#   if ($data =~ m/°/) { $data =~ s/°/°/g; }
#   if ($data =~ m/Ð/) { $data =~ s/Ð/- /g; }
#   if ($data =~ m/&lt;/) { $data =~ s/&lt;/</g; }
#   if ($data =~ m/&gt;/) { $data =~ s/&gt;/>/g; }
#   return $data;
# } # sub filterAce

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

