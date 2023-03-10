#!/usr/bin/perl -w

# get pmids's xml from ncbi for papers with ``other'' for type.  2009 07 07

use strict;
use diagnostics;
use DBI;
use LWP::UserAgent;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my %hash;

my %pmids;

my $result = $dbh->prepare( "SELECT * FROM wpa ORDER BY wpa_timestamp" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[3] eq 'valid') { $hash{valid}{$row[0]}++; }
    else { delete $hash{valid}{$row[0]}; }
} # while (@row = $result->fetchrow)

$result = $dbh->prepare( "SELECT * FROM wpa_identifier ORDER BY wpa_timestamp" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[3] eq 'valid') { $hash{ident}{$row[0]}{$row[1]}++; }
    else { delete $hash{ident}{$row[0]}{$row[1]}; }
} # while (@row = $result->fetchrow)

$result = $dbh->prepare( "SELECT * FROM wpa_type ORDER BY wpa_timestamp" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[3] eq 'valid') { $hash{type}{$row[0]} = $row[1]; }
    else { delete $hash{type}{$row[0]}; }
} # while (@row = $result->fetchrow)

foreach my $paper (sort keys %{ $hash{type} }) {
  next unless $hash{type}{$paper} eq '17';
  next unless $hash{valid}{$paper};
  foreach my $ident (sort keys %{ $hash{ident}{$paper} }) {
    if ($ident =~ m/^pmid/) {
#       print "$paper\t$ident\n";
      $ident =~ s/pmid//; $pmids{$ident}++;
    }
  } # foreach my $ident (sort keys %{ $hash{ident}{$paper} })
} # foreach my $paper (sort keys %{ $hash{type} })

my $sleep = 0;
foreach my $pmid (sort keys %pmids) {
#   print "$pmid\n"; next;		# uncomment to see which ones have type 17
  if ($sleep) { &slp(); }			# if flagged to sleep, wait
  unless ($sleep) { $sleep++; }		# first time through don't sleep
  last if ($sleep > 3);
#       my @lc = localtime;			# comply with NCBI's requirement of doing it at night
#       while ($lc[2] < 18) {
#         sleep 600;
#         @lc = localtime; }
  my $url = "http\:\/\/eutils\.ncbi\.nlm\.nih\.gov\/entrez\/eutils\/efetch\.fcgi\?db\=pubmed\&id\=$pmid\&retmode\=xml";
  my $page = getPubmedPage($url);
  my $outfile = '/home/postgres/work/pgpopulation/wpa_papers/type_other/xml/' . $pmid;
  open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
  print OUT $page;
  close (OUT) or die "Cannot close $outfile : $!";
#   $link_text .= &processPubmedPage($page, $pmid, $two_number, $not_first_pass);
#   print STDERR "no error : $pmid\n";
} # foreach my $pmid (sort keys %pmids)

sub getPubmedPage {
    my $u = shift;
    my $page = "";
    my $ua = LWP::UserAgent->new(timeout => 30); # instantiates a new user agent
    my $request = HTTP::Request->new(GET => $u); # grabs url
    my $response = $ua->request($request);       # checks url, dies if not valid.
#    die "Error while getting ", $response->request->uri," -- ", $response->status_line, "\nAborting" unless $response-> is_success;
    $page = $response->content;    #splits by line
    $page = &filterForeign($page);
    return $page;
} # sub getPubmedPage


sub filterForeign {		# take out foreign characters before they can get into postgres  for Cecilia  2006 05 04
  my $change = shift;
  if ($change =~ m/[‚„…ˆŠ‹ŒŽ‘’“”—˜š›œžŸª«­¯±·»¼½¾ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüý]/) {
    if ($change =~ m/‚/) { $change =~ s/‚/,/g; }
    if ($change =~ m/„/) { $change =~ s/„/"/g; }
    if ($change =~ m/…/) { $change =~ s/…/.../g; }
    if ($change =~ m/ˆ/) { $change =~ s/ˆ/^/g; }
    if ($change =~ m/Š/) { $change =~ s/Š/S/g; }
    if ($change =~ m/‹/) { $change =~ s/‹/</g; }
    if ($change =~ m/Œ/) { $change =~ s/Œ/OE/g; }
    if ($change =~ m/Ž/) { $change =~ s/Ž/Z/g; }
    if ($change =~ m/‘/) { $change =~ s/‘/'/g; }
    if ($change =~ m/’/) { $change =~ s/’/'/g; }
    if ($change =~ m/“/) { $change =~ s/“/"/g; }
    if ($change =~ m/”/) { $change =~ s/”/"/g; }
    if ($change =~ m/—/) { $change =~ s/—/-/g; }
    if ($change =~ m/˜/) { $change =~ s/˜/~/g; }
    if ($change =~ m/š/) { $change =~ s/š/s/g; }
    if ($change =~ m/›/) { $change =~ s/›/>/g; }
    if ($change =~ m/œ/) { $change =~ s/œ/oe/g; }
    if ($change =~ m/ž/) { $change =~ s/ž/z/g; }
    if ($change =~ m/Ÿ/) { $change =~ s/Ÿ/y/g; }
    if ($change =~ m/ª/) { $change =~ s/ª/a/g; }
    if ($change =~ m/«/) { $change =~ s/«/"/g; }
    if ($change =~ m/­/) { $change =~ s/­/-/g; }
    if ($change =~ m/¯/) { $change =~ s/¯/-/g; }
    if ($change =~ m/±/) { $change =~ s/±/+\/-/g; }
    if ($change =~ m/·/) { $change =~ s/·/-/g; }
    if ($change =~ m/»/) { $change =~ s/»/"/g; }
    if ($change =~ m/¼/) { $change =~ s/¼/1\/4/g; }
    if ($change =~ m/½/) { $change =~ s/½/1\/2/g; }
    if ($change =~ m/¾/) { $change =~ s/¾/3\/4/g; }
    if ($change =~ m/À/) { $change =~ s/À/A/g; }
    if ($change =~ m/Á/) { $change =~ s/Á/A/g; }
    if ($change =~ m/Â/) { $change =~ s/Â/A/g; }
    if ($change =~ m/Ã/) { $change =~ s/Ã/A/g; }
    if ($change =~ m/Ä/) { $change =~ s/Ä/A/g; }
    if ($change =~ m/Å/) { $change =~ s/Å/A/g; }
    if ($change =~ m/Æ/) { $change =~ s/Æ/AE/g; }
    if ($change =~ m/Ç/) { $change =~ s/Ç/C/g; }
    if ($change =~ m/È/) { $change =~ s/È/E/g; }
    if ($change =~ m/É/) { $change =~ s/É/E/g; }
    if ($change =~ m/Ê/) { $change =~ s/Ê/E/g; }
    if ($change =~ m/Ë/) { $change =~ s/Ë/E/g; }
    if ($change =~ m/Ì/) { $change =~ s/Ì/I/g; }
    if ($change =~ m/Í/) { $change =~ s/Í/I/g; }
    if ($change =~ m/Î/) { $change =~ s/Î/I/g; }
    if ($change =~ m/Ï/) { $change =~ s/Ï/I/g; }
    if ($change =~ m/Ð/) { $change =~ s/Ð/D/g; }
    if ($change =~ m/Ñ/) { $change =~ s/Ñ/N/g; }
    if ($change =~ m/Ò/) { $change =~ s/Ò/O/g; }
    if ($change =~ m/Ó/) { $change =~ s/Ó/O/g; }
    if ($change =~ m/Ô/) { $change =~ s/Ô/O/g; }
    if ($change =~ m/Õ/) { $change =~ s/Õ/O/g; }
    if ($change =~ m/Ö/) { $change =~ s/Ö/O/g; }
    if ($change =~ m/×/) { $change =~ s/×/x/g; }
    if ($change =~ m/Ø/) { $change =~ s/Ø/O/g; }
    if ($change =~ m/Ù/) { $change =~ s/Ù/U/g; }
    if ($change =~ m/Ú/) { $change =~ s/Ú/U/g; }
    if ($change =~ m/Û/) { $change =~ s/Û/U/g; }
    if ($change =~ m/Ü/) { $change =~ s/Ü/U/g; }
    if ($change =~ m/Ý/) { $change =~ s/Ý/Y/g; }
    if ($change =~ m/ß/) { $change =~ s/ß/B/g; }
    if ($change =~ m/à/) { $change =~ s/à/a/g; }
    if ($change =~ m/á/) { $change =~ s/á/a/g; }
    if ($change =~ m/â/) { $change =~ s/â/a/g; }
    if ($change =~ m/ã/) { $change =~ s/ã/a/g; }
    if ($change =~ m/ä/) { $change =~ s/ä/a/g; }
    if ($change =~ m/å/) { $change =~ s/å/a/g; }
    if ($change =~ m/æ/) { $change =~ s/æ/ae/g; }
    if ($change =~ m/ç/) { $change =~ s/ç/c/g; }
    if ($change =~ m/è/) { $change =~ s/è/e/g; }
    if ($change =~ m/é/) { $change =~ s/é/e/g; }
    if ($change =~ m/ê/) { $change =~ s/ê/e/g; }
    if ($change =~ m/ë/) { $change =~ s/ë/e/g; }
    if ($change =~ m/ì/) { $change =~ s/ì/i/g; }
    if ($change =~ m/í/) { $change =~ s/í/i/g; }
    if ($change =~ m/î/) { $change =~ s/î/i/g; }
    if ($change =~ m/ï/) { $change =~ s/ï/i/g; }
    if ($change =~ m/ð/) { $change =~ s/ð/o/g; }
    if ($change =~ m/ñ/) { $change =~ s/ñ/n/g; }
    if ($change =~ m/ò/) { $change =~ s/ò/o/g; }
    if ($change =~ m/ó/) { $change =~ s/ó/o/g; }
    if ($change =~ m/ô/) { $change =~ s/ô/o/g; }
    if ($change =~ m/õ/) { $change =~ s/õ/o/g; }
    if ($change =~ m/ö/) { $change =~ s/ö/o/g; }
    if ($change =~ m/÷/) { $change =~ s/÷/\//g; }
    if ($change =~ m/ø/) { $change =~ s/ø/o/g; }
    if ($change =~ m/ù/) { $change =~ s/ù/u/g; }
    if ($change =~ m/ú/) { $change =~ s/ú/u/g; }
    if ($change =~ m/û/) { $change =~ s/û/u/g; }
    if ($change =~ m/ü/) { $change =~ s/ü/u/g; }
    if ($change =~ m/ý/) { $change =~ s/ý/y/g; }
  }
  if ($change =~ m/[€ƒ†‡‰•™¡¢£¤¥¦§¨©¬®°²³´µ¶¹º¿þÞ]/) { $change =~ s/[€ƒ†‡‰•™¡¢£¤¥¦§¨©¬®°²³´µ¶¹º¿þÞ]//g; }
  return $change;
} # sub filterForeign

sub slp {
#     my $rand = int(rand 15) + 5;	# random 5-20 seconds
    my $rand = 5;			# just 5 seconds
#     print LOG "Sleeping for $rand seconds...\n";
    sleep $rand;
#     print LOG "done.\n";
} # sub slp


__END__

package wpa_match;
require Exporter;

our @ISA        = qw(Exporter);
our @EXPORT     = qw( processEndnote processPubmed processLocal processForm processWormbook );
our $VERSION    = 1.00;

use strict;
use diagnostics;
use LWP::UserAgent;
use Jex;
use DBI;


# cur_ tables replaced by cfp_ tables  2009 04 06
#
# switched to DBI  2009 05 27


my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 


my %keys_wpa; 

my %cdsToGene;


1;


sub processEndnote {
  my $infile = shift;
  &getWpa();
  &getLoci();
  my $result = $dbh->prepare( "SELECT * FROM wpa_identifier WHERE wpa_identifier ~ 'cgc' ORDER BY wpa_timestamp;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { 
    $row[1] =~ s/cgc//; 
    if ($row[3] eq 'valid') { $keys_wpa{cgc}{$row[1]}++; }
      else { delete $keys_wpa{cgc}{$row[1]}; } }

  my $link_text = '';
  my $date = &getSimpleSecDate;
  my $pgfile = '/home/postgres/work/pgpopulation/wpa_papers/wpa_new_wbpaper_tables/perl_wpa_match/pgfile.pg.cgc.' . $date;
  open (PG, ">$pgfile") or die "Cannot create $pgfile : $!";
  my $logfile = '/home/postgres/work/pgpopulation/wpa_papers/wpa_new_wbpaper_tables/perl_wpa_match/logfile.cgc.' . $date;
  open (LOG, ">$logfile") or die "Cannot open $logfile : $!";
  open (IN, "<$infile") or die "Cannot open $infile : $!";
  while (my $line = <IN>) {
    chomp($line);
    my ($cgc) = $line =~ m/^(\d+)/;
    unless ($keys_wpa{cgc}{$cgc}) { 	# is new if not in wpa_identifier
      if ($line =~ m/'/) { $line =~ s/'/''/g; }  if ($line =~ m/"/) { $line =~ s/"/\\"/g; }
      $line .= "\t";	# add another tab for non-existing type data in endnote file
      my ($log_text) = &matchLine('cgc', $line);
      if ($log_text) {
        my $temp_text = '';
        if ($log_text =~ m/(TOO MANY.*?)\n/) { $temp_text = "$1"; }
        if ($log_text =~ m/(MERGE WITH.*?)\n/) { $temp_text = "$1"; }
        if ($log_text =~ m/(FLAG.*?)\n/) { $temp_text = "$1"; }
        if ($log_text =~ m/(LOW.*?)\n/) { $temp_text = "$1"; }
        if ($temp_text) { $link_text .= "$cgc $temp_text .<BR>\n"; } }
      print LOG $log_text; 
    } # unless ($keys_wpa{cgc}{$cgc}) 
  } # while (<IN>)
  close (IN) or die "Cannot close $infile : $!";
  close (LOG) or die "Cannot close $logfile : $!";
  close (PG) or die "Cannot close $pgfile : $!";

  if ($link_text) {
    my $user = 'automatic_cgc_script';
    my $email = 'qwang@its.caltech.edu, spamanet@gmail.com, cecilia@tazendra.caltech.edu';
#     my $email = 'qwang@its.caltech.edu, spamanet@gmail.com';
#     my $email = 'qwang@its.caltech.edu, ranjana@its.caltech.edu';
#     my $email = 'azurebrd@tazendra.caltech.edu';
    my $subject = 'cgcs entered from automatic script';
    &mailer($user, $email, $subject, $link_text); }
} # sub processEndnote


sub getWpa {
  my %got_joinkey;
  my $result = $dbh->prepare( "SELECT joinkey, wpa_title FROM wpa_title WHERE wpa_title IS NOT NULL AND wpa_valid = 'valid' ORDER BY wpa_timestamp DESC;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    if ($got_joinkey{title}{$row[0]}) { next; }
    if ($row[1]) {
      my $key_title = $row[1];
      if ($key_title =~ m/C\.? ?[Ee]legans\b/) { $key_title =~ s/C\.?  ?[Ee]legans\b/Caenorhabditis elegans/g; }
      $key_title = substr($key_title, 0, 20);		# get just 20 chars
      $key_title = lc($key_title);
      $keys_wpa{title}{$key_title}{$row[0]}++; 
      $got_joinkey{title}{$row[0]}++; } }

  $result = $dbh->prepare( "SELECT joinkey, wpa_abstract FROM wpa_abstract WHERE wpa_abstract IS NOT NULL AND wpa_valid = 'valid' ORDER BY wpa_timestamp DESC;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    if ($got_joinkey{abstract}{$row[0]}) { next; }
    if ($row[1]) {
      my $key_abstract = $row[1];
      if ($key_abstract =~ m/C\.? ?[Ee]legans\b/) { $key_abstract =~ s/C\.?  ?[Ee]legans\b/Caenorhabditis elegans/g; }
      $key_abstract = lc($key_abstract);
      if ($key_abstract =~ m/\W/) { $key_abstract =~ s/\W//g; }
      my $key_abstract_front = substr($key_abstract, 0, 20);		# get just 20 chars
      my $key_abstract_end = substr($key_abstract, -20);		# get just 20 chars
      $key_abstract = "$key_abstract_front\t$key_abstract_end";
      $keys_wpa{abstract}{$key_abstract}{$row[0]}++; 
      $got_joinkey{abstract}{$row[0]}++; } }

  $result = $dbh->prepare( "SELECT joinkey, wpa_volume FROM wpa_volume WHERE wpa_volume IS NOT NULL AND wpa_valid = 'valid' ORDER BY wpa_timestamp DESC;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    if ($got_joinkey{volume}{$row[0]}) { next; }
    if ($row[1]) {
      my $key_volume = $row[1];
      if ($key_volume =~ m/^\s+/) { $key_volume =~ s/^\s+//g; }
      if ($key_volume =~ m/^\-COMMENT.*$/) { $key_volume =~ s/^\-COMMENT.*$//g; }
      if ($key_volume =~ m/^(\w+)/) { $key_volume = $1; } # else { print STDERR "ODD VOLUME $row[0] -= $row[1] =-\n"; }
      $keys_wpa{volume}{$key_volume}{$row[0]}++;
      $got_joinkey{volume}{$row[0]}++; } }

  $result = $dbh->prepare( "SELECT joinkey, wpa_pages FROM wpa_pages WHERE wpa_pages IS NOT NULL AND wpa_valid = 'valid' ORDER BY wpa_timestamp DESC;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    if ($got_joinkey{pages}{$row[0]}) { next; }
    if ($row[1]) { 
      my $key_pages = $row[1];
      if ($key_pages =~ m/^\s+/) { $key_pages =~ s/^\s+//g; }
      if ($key_pages =~ m/^\-COMMENT.*$/) { $key_pages =~ s/^\-COMMENT.*$//g; }
      if ($key_pages =~ m/^(\w+)/) { $key_pages = $1; } # else { print STDERR "ODD PAGES $row[0] -= $row[1] =-\n"; }
      $keys_wpa{pages}{$key_pages}{$row[0]}++;
      $got_joinkey{pages}{$row[0]}++; } }

  $result = $dbh->prepare( "SELECT author_id, wpa_author_index FROM wpa_author_index WHERE wpa_author_index IS NOT NULL AND wpa_valid = 'valid' ORDER BY wpa_timestamp DESC;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {		# store author_id -> author_name mappings in  $keys_wpa{author_id}{ a_id } = a_name
    if ($row[1] =~ m/^\s+/) { $row[1] =~ s/^\s+//g; }
    if ($row[1] =~ m/^\-COMMENT.*$/) { $row[1] =~ s/^\-COMMENT.*$//g; }
    if ($row[1]) { $keys_wpa{author_id}{$row[0]} = $row[1]; } }

  $result = $dbh->prepare( "SELECT joinkey, wpa_author, wpa_order, wpa_valid FROM wpa_author ORDER BY wpa_order, wpa_timestamp;" ); 
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  my %temp_hash; my $current_order = 0; my $flag_valid = 0; my $author_id = 0; my $joinkey = 0;
  while (my @row = $result->fetchrow) {
    if ($row[0] > $joinkey) {		# if new joinkey
      unless ($joinkey) { $joinkey = $row[0]; next; }	# skip first entry when there is no joinkey
      my $key_author_name = '';				# init they key for author names, if a_name for a_id, grab the a_name
      if ($keys_wpa{author_id}{$author_id}) { $key_author_name = $keys_wpa{author_id}{$author_id}; }
      if ($key_author_name =~ m/(\w+)/) { 				# if the name matches words
        my (@author_parts) = $key_author_name =~ m/(\w+)/g; 		# get parts of author since could be first last or last first
        foreach my $key_author_part (@author_parts) {			# take each author part
          $keys_wpa{author}{$key_author_part}{$joinkey}++; } } 		# store previous author name part and joinkey
      $flag_valid = 0; $current_order = 0; $author_id = 0; $joinkey = $row[0]; }	# reset flags and get new joinkey

    if ($row[2]) {
      if ( ($row[2] > $current_order) && ($flag_valid) ) { next; }	# if done with current order and is valid, done with this joinkey
      if ($row[2] > $current_order) { $current_order = $row[2]; } }	# if done with current order but not valid, switch order

    if ($row[3] eq 'valid') { $author_id = $row[1]; $flag_valid = 1; }	# if valid, save the id and set valid
      else { $author_id = 0; $flag_valid = 0; } }					# if not valid clear the id and set invalid
} # sub getWpa


  
sub matchLine {		# match endnote line to wpa_ data
  my ($flag, $line, $two_number, $not_first_pass) = @_;
  unless ($two_number) { $two_number = 'two1823'; }
  my ($cgc, $pmid, $authors, $title, $journal, $volume, $pages, $year, $abstract, $genes, $type, $editor, $fulltext_url);
  $volume = ''; $authors = ''; $pages = ''; $title = '';
  my $log_text = ''; my $manual_text = '';
  my $manual_checkfile = '/home/postgres/work/pgpopulation/wpa_papers/wpa_new_wbpaper_tables/perl_wpa_match/manual_check_file.endnote';
  open (CHE, ">>$manual_checkfile") or die "Cannot open $manual_checkfile : $!";

  if ($flag eq 'cgc') {
    ($cgc, $authors, $title, $journal, $volume, $pages, $year, $abstract, $genes, $type, $editor, $fulltext_url) = split/\t/, $line; }
  if ($flag eq 'pmid') {
    ($pmid, $authors, $title, $journal, $volume, $pages, $year, $abstract, $genes, $type, $editor, $fulltext_url) = split/\t/, $line; }

  my $key_author = ''; my $key_volume = ''; my $key_pages = ''; my $key_title = '';
  if ($authors) { if ($authors =~ m/^(\w+)/) { $key_author = $1; } }
  if ($volume) { if ($volume =~ m/^(\w+)/) { $key_volume = $1; } }
  if ($pages) { if ($pages =~ m/^(\w+)/) { $key_pages = $1; } }
  if ($title) { $key_title = $title;  }
  if ($key_title =~ m/C\.? ?[Ee]legans\b/) { $key_title =~ s/C\.?  ?[Ee]legans\b/Caenorhabditis elegans/g; }
  $key_title = substr($key_title, 0, 20);		# get just 20 chars
  $key_title = lc($key_title);
  $log_text .= "$line\n";
  unless ($key_author) { $key_author = ''; } unless ($key_volume) { $key_volume = ''; }
  unless ($key_pages) { $key_pages = ''; } unless ($key_title) { $key_title = ''; }
  $log_text .= "A : $key_author . V : $key_volume . P : $key_pages . T : $key_title\n"; 

  my %matching_joinkeys;
  if ($key_title) { if ( $keys_wpa{title}{$key_title} ) {
    foreach my $joinkey (sort keys %{ $keys_wpa{title}{$key_title} }) { $matching_joinkeys{$joinkey}++; } } }
  if ($key_author) { if ( $keys_wpa{author}{$key_author} ) { 
    foreach my $joinkey (sort keys %{ $keys_wpa{author}{$key_author} }) { $matching_joinkeys{$joinkey}++; } } }
  if ($key_volume) { if ( $keys_wpa{volume}{$key_volume} ) { 
    foreach my $joinkey (sort keys %{ $keys_wpa{volume}{$key_volume} }) { $matching_joinkeys{$joinkey}++; } } }
  if ($key_pages) { if ( $keys_wpa{pages}{$key_pages} ) { 
    foreach my $joinkey (sort keys %{ $keys_wpa{pages}{$key_pages} }) { $matching_joinkeys{$joinkey}++; } } }
  my $full_match = 0; 
  my @four_matches; my @three_matches; my @two_matches;		# joinkeys that match four and three and two fields
  foreach my $joinkey (sort { $matching_joinkeys{$b} <=> $matching_joinkeys{$a} || $a cmp $b } keys %matching_joinkeys) {
    if ($matching_joinkeys{$joinkey} == 4) { 
      push @four_matches, $joinkey;
      $full_match++; }
    if ($matching_joinkeys{$joinkey} == 3) { push @three_matches, $joinkey; }
    if ($matching_joinkeys{$joinkey} == 2) { push @two_matches, $joinkey; }
  } # foreach my $joinkey (sort { $matching_joinkeys{$b} <=> $matching_joinkeys{$a} || $a cmp $b } keys %matching_joinkeys)
  if ($full_match) {
    if (scalar(@four_matches) > 1) { 
      my $joins = join", ", @four_matches; 
      $log_text .= "TOO MANY wbpapers match four fields $joins\n\n"; 
      my $date = &getSimpleSecDate();
      $manual_text .= "many\t$joins\t$flag\t$line\t$two_number\t$date\n"; }
    else { 
      &mergeEntry($two_number, $four_matches[0], $flag, $line);
      $log_text .= "MERGE WITH $four_matches[0]\n\n"; } }
  elsif ($three_matches[0]) {
      my $joins = join", ", @three_matches; 
      $log_text .= "FLAG three fields : $joins\n\n";
      my $date = &getSimpleSecDate();
      $manual_text .= "possible three\t$joins\t$flag\t$line\t$two_number\t$date\n"; }
  elsif ($two_matches[0]) {
    if ($abstract) {
      if ($abstract =~ m/C\.? ?[Ee]legans\b/) { $abstract =~ s/C\.?  ?[Ee]legans\b/Caenorhabditis elegans/g; }
      $abstract = lc($abstract);
      if ($abstract =~ m/\W/) { $abstract =~ s/\W//g; }
      my $abstract_front = substr($abstract, 0, 20);		# get just 20 chars
      my $abstract_end = substr($abstract, -20);		# get just 20 chars
      $abstract = "$abstract_front\t$abstract_end";
      my @possible_matches;
      foreach my $possible_joinkey (@two_matches) {
        if ($keys_wpa{abstract}{$abstract}{$possible_joinkey}) { push @possible_matches, $possible_joinkey; } }
      my $date = &getSimpleSecDate();
      if ($possible_matches[0]) {
          my $joins = join", ", @possible_matches; 
          $log_text .= "FLAG two fields plus abstract : $joins\n\n";
          $manual_text .= "possible two plus abstract\t$joins\t$flag\t$line\t$two_number\t$date\n"; } 
        else {
          my $joinkey = &createEntry($two_number, $flag, $line, '', $not_first_pass);
          $log_text .= "LOW matching, two matches, no abstract create entry $joinkey\n\n"; } }
    else { 
      my $joinkey = &createEntry($two_number, $flag, $line, '', $not_first_pass);
      $log_text .= "LOW matching, two matches, no abstract create entry $joinkey\n\n"; } }
  else {
      my $joinkey = &createEntry($two_number, $flag, $line, '', $not_first_pass);
      $log_text .= "LOW matching, one or less matches, create entry $joinkey\n\n"; }
  print CHE $manual_text;
  close (CHE) or die "Cannot close $manual_checkfile : $!";
  return ($log_text);
} # sub matchLine

sub mergeEntry {
  my ($two_number, $joinkey, $flag, $line) = @_;
  my ($cgc, $pmid, $authors, $title, $journal, $volume, $pages, $year, $abstract, $genes, $type, $editor, $fulltext_url);
  if ($flag eq 'cgc') {
    ($cgc, $authors, $title, $journal, $volume, $pages, $year, $abstract, $genes, $type, $editor, $fulltext_url) = split/\t/, $line; }
  if ($flag eq 'pmid') {
    ($pmid, $authors, $title, $journal, $volume, $pages, $year, $abstract, $genes, $type, $editor, $fulltext_url) = split/\t/, $line; }
  if ($cgc) { &addPg($two_number, $joinkey, 'wpa_identifier', "cgc$cgc"); }
  if ($pmid) { &addPg($two_number, $joinkey, 'wpa_identifier', "pmid$pmid"); }

  if ($title) { &checkPg($two_number, $joinkey, 'title', 'wpa_title', $title); }
  if ($journal) { &checkPg($two_number, $joinkey, 'journal', 'wpa_journal', $journal); }
  if ($volume) { &checkPg($two_number, $joinkey, 'volume', 'wpa_volume', $volume); }
  if ($pages) { &checkPg($two_number, $joinkey, 'pages', 'wpa_pages', $pages); }
  if ($year) { &checkPg($two_number, $joinkey, 'year', 'wpa_year', $year); }
  if ($type) { &checkPg($two_number, $joinkey, 'type', 'wpa_type', $type); }
  if ($abstract) { &checkPg($two_number, $joinkey, 'abstract', 'wpa_abstract', $abstract); }
  if ($authors) { &checkPg($two_number, $joinkey, 'authors', 'wpa_author', $authors); }
  if ($genes) { &checkPg($two_number, $joinkey, 'genes_theresa', 'wpa_gene', $genes); }
  if ($editor) { &checkPg($two_number, $joinkey, 'editor', 'wpa_editor', $editor); }
  if ($fulltext_url) { &checkPg($two_number, $joinkey, 'fulltext_url', 'wpa_fulltext_url', $fulltext_url); }
} # sub mergeEntry

sub createEntry {
  my ($two_number, $flag, $line, $wpa, $not_first_pass) = @_;		# allow wpa input for ease of in_book without creating it
  my ($cgc, $pmid, $wormbook, $authors, $title, $journal, $volume, $pages, $year, $abstract, $genes, $type, $editor, $fulltext_url);
  if ($flag eq 'cgc') {
    ($cgc, $authors, $title, $journal, $volume, $pages, $year, $abstract, $genes, $type, $editor, $fulltext_url) = split/\t/, $line; }
  if ($flag eq 'pmid') {
    ($pmid, $authors, $title, $journal, $volume, $pages, $year, $abstract, $genes, $type, $editor, $fulltext_url) = split/\t/, $line; }
  if ($flag eq 'wormbook') {
    ($wormbook, $authors, $title, $journal, $volume, $pages, $year, $abstract, $genes, $type, $editor, $fulltext_url) = split/\t/, $line; }

  unless ($wpa) {			# if no joinkey was given, get next highest one
    my $result = $dbh->prepare( "SELECT * FROM wpa ORDER BY joinkey DESC;" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    my @row = $result->fetchrow; 
    $wpa = $row[0] + 1; }

  my $joinkey = &padZeros($wpa); 
  if ($joinkey =~ m/^(\d+)\.2$/) { 				# if it's in_book
      my $main = $1;						# add in_book to main joinkey
      &addPg($two_number, $main, 'wpa_in_book', $joinkey); }
    else { &addPg($two_number, $joinkey, 'wpa', $wpa); }	# otherwise create wpa entry

  if ($cgc) { &addPg($two_number, $joinkey, 'wpa_identifier', "cgc$cgc"); }
  if ($pmid) { &addPg($two_number, $joinkey, 'wpa_identifier', "pmid$pmid"); }
  if ($wormbook) { &addPg($two_number, $joinkey, 'wpa_identifier', "$wormbook"); }
  if ($title) { &addPg($two_number, $joinkey, 'wpa_title', $title); }
  if ($journal) { &addPg($two_number, $joinkey, 'wpa_journal', $journal); }
  if ($volume) { &addPg($two_number, $joinkey, 'wpa_volume', $volume); }
  if ($pages) { &addPg($two_number, $joinkey, 'wpa_pages', $pages); }
  if ($year) { &addPg($two_number, $joinkey, 'wpa_year', $year); }
  if ($type) { &addPg($two_number, $joinkey, 'wpa_type', $type); }
  if ($abstract) { &addPg($two_number, $joinkey, 'wpa_abstract', $abstract); }
  if ($authors) { &addPg($two_number, $joinkey, 'wpa_author', $authors); }
  if ($genes) { &addPg($two_number, $joinkey, 'add_gene_theresa', $genes); }
  if ($editor) { &addPg($two_number, $joinkey, 'wpa_editor', $editor); }			# for wormbook / igor 2006 04 28
  if ($fulltext_url) { &addPg($two_number, $joinkey, 'wpa_fulltext_url', $fulltext_url); }	# for wormbook / igor 2006 04 28

  if ($not_first_pass) { if ($not_first_pass eq 'functional_annotation') {
      # label stuff with the checkbox for functional_annotation comment, to be checked out and curated and to have a comment for Andrei  2006 08 24
    &checkPg($two_number, $joinkey, 'checked_out', 'wpa_checked_out', $two_number);		# update to be wpa_checked_out
# cur_ tables replaced by cfp_ tables  2009 04 06
#     my $pg_command2 = "INSERT INTO cur_curator VALUES ('$joinkey', '$two_number', CURRENT_TIMESTAMP);"; 
#     my $result2 = $conn->exec( $pg_command2 );
#     print PG "$pg_command2\n"; 
#     $pg_command2 = "INSERT INTO cur_comment VALUES ('$joinkey', 'the paper is used for functional annotations', CURRENT_TIMESTAMP);"; 
    my $pg_command2 = "INSERT INTO cfp_comment VALUES ('$joinkey', 'the paper is used for functional annotations', '$two_number', CURRENT_TIMESTAMP);"; 
    my $result = $dbh->do( $pg_command2 );
    print PG "$pg_command2\n";  
    $pg_command2 = "INSERT INTO wpa_ignore VALUES ('$joinkey', 'functional annotation only', NULL, 'valid', '$two_number');"; 
    $result = $dbh->do( $pg_command2 );
    print PG "$pg_command2\n";  
# cur_ tables replaced by cfp_ tables  2009 04 06
#     my $infile = '/home/postgres/public_html/cgi-bin/curation.cgi';
#     open (IN, "<$infile") or die "Cannot open $infile : $!"; 
#     $/ = undef; my $all_file = <IN>; $/ = "\n";
#     close (IN) or die "Cannot close $infile : $!"; 
#     my $params = '';
#     if ($all_file =~ m/my \@PGparameters \= qw\((.*?)\)\;/ms) { $params = $1; }
#     unless ($params) { print "ERROR can't find postgres tables cur_ paramters from curation.cgi so postgres not properly populated<BR>\n"; }
#     if ($params) {
#       my @params = split/\s+/, $params; 
#       foreach my $pgparam (@params) { 
#         next if ($pgparam eq 'curator');
#         next if ($pgparam eq 'comment');
#         next if ($pgparam eq 'pubID');
#         next if ($pgparam eq 'pdffilename');
#         next if ($pgparam eq 'reference');
#         next if ($pgparam eq 'fullauthorname');
#         my $pg_command2 = "INSERT INTO cur_$pgparam VALUES ('$joinkey', NULL, CURRENT_TIMESTAMP);"; 
#         my $result2 = $conn->exec( $pg_command2 );
#         print PG "$pg_command2\n"; } }
  } } 

  return ($joinkey);
} # sub createEntry

sub padZeros {
  my $joinkey = shift;
  if ($joinkey < 10) { $joinkey = '0000000' . $joinkey; }
  elsif ($joinkey < 100) { $joinkey = '000000' . $joinkey; }
  elsif ($joinkey < 1000) { $joinkey = '00000' . $joinkey; }
  elsif ($joinkey < 10000) { $joinkey = '0000' . $joinkey; }
  elsif ($joinkey < 100000) { $joinkey = '000' . $joinkey; }
  elsif ($joinkey < 1000000) { $joinkey = '00' . $joinkey; }
  elsif ($joinkey < 10000000) { $joinkey = '0' . $joinkey; }
  return $joinkey;
} # sub padZeros



sub processForm {
  my ($two_number, $joinkey, $flag, $merge_or_create, $line) = @_;
  my $date = &getSimpleDate();
  my $pgfile = '/home/postgres/work/pgpopulation/wpa_papers/wpa_new_wbpaper_tables/perl_wpa_match/pgfile.pg.form.' . $date;
  open (PG, ">>$pgfile") or die "Cannot create $pgfile : $!";
  my $logfile = '/home/postgres/work/pgpopulation/wpa_papers/wpa_new_wbpaper_tables/perl_wpa_match/logfile.form.' . $date;
  open (LOG, ">>$logfile") or die "Cannot create $logfile : $!";
  if ($merge_or_create eq 'merge') { 
#       print "MERGE TWO $two_number JOIN $joinkey FLAG $flag LINE $line<BR>\n"; 
      &mergeEntry($two_number, $joinkey, $flag, $line); 
    }
  elsif ($merge_or_create eq 'create') { 
#       print "CREATE TWO $two_number JOIN $joinkey FLAG $flag LINE $line<BR>\n"; 
      &createEntry($two_number, $flag, $line); 
    }
  else { print "<FONT COLOR=red>ERROR Form should either CREATE or MERGE</FONT><BR>\n"; }
  close (LOG) or die "Cannot close $logfile : $!";
  close (PG) or die "Cannot close $pgfile : $!";
} # sub processForm 


sub processWormbook {
  my ($two_number, $flag, $line, $joinkey) = @_;
  &getLoci();		# need to get loci to populate wbgenes 2007 09 05
  my $date = &getSimpleDate();
  my $pgfile = '/home/postgres/work/pgpopulation/wpa_papers/wpa_new_wbpaper_tables/perl_wpa_match/pgfile.pg.wormbook.' . $date;
  open (PG, ">>$pgfile") or die "Cannot create $pgfile : $!";
  my $logfile = '/home/postgres/work/pgpopulation/wpa_papers/wpa_new_wbpaper_tables/perl_wpa_match/logfile.wormbook.' . $date;
  open (LOG, ">>$logfile") or die "Cannot create $logfile : $!";
  &createEntry($two_number, $flag, $line, $joinkey); 
  close (LOG) or die "Cannot close $logfile : $!";
  close (PG) or die "Cannot close $pgfile : $!";
} # sub processForm 



sub processLocal {		# for paper editor confirmation of abstracts pre-downloaded from pubmed  2009 02 18
  my ($pmid_list, $two_number, $not_first_pass) = @_;
  my @pmids = split/\t/, $pmid_list;
  &getWpa();
  &getLoci();
  my $link_text = '';

  my $date = &getSimpleSecDate();
  my $pgfile = '/home/postgres/work/pgpopulation/wpa_papers/wpa_new_wbpaper_tables/perl_wpa_match/pgfile.pg.local.' . $date;
  open (PG, ">$pgfile") or die "Cannot create $pgfile : $!";
  my $logfile = '/home/postgres/work/pgpopulation/wpa_papers/wpa_new_wbpaper_tables/perl_wpa_match/logfile.local.' . $date;
  open (LOG, ">$logfile") or die "Cannot create $logfile : $!";
  
  my $sleep = 0;
  foreach my $pmid (@pmids) {
    my $page_loc = "/home/postgres/work/pgpopulation/wpa_papers/pmid_downloads/xml/$pmid";
    $/ = undef;
    open (IN, "<$page_loc") or die "Cannot open $page_loc : $!";
    my $page = <IN>;
    close (IN) or die "Cannot close $page_loc : $!";
    $link_text .= &processPubmedPage($page, $pmid, $two_number, $not_first_pass);
    print STDERR "no error : $pmid\n";
  } # foreach my $pmid (sort keys %pmids)

  close (LOG) or die "Cannot close $logfile : $!";
  close (PG) or die "Cannot close $pgfile : $!";

  if ($link_text) { 
    my $user = 'wbpaper_editor_form';
    my $email = 'qwang@its.caltech.edu, spamanet@gmail.com, cecilia@tazendra.caltech.edu';
#     my $email = 'qwang@its.caltech.edu, spamanet@gmail.com';
#     my $email = 'qwang@its.caltech.edu, ranjana@its.caltech.edu';
#     my $email = 'azurebrd@tazendra.caltech.edu';
    my $subject = 'pmids entered through form';
    &mailer($user, $email, $subject, $link_text); }
  return $link_text;
} # processPubmed

sub processPubmed {
  my ($pmid_list, $two_number, $not_first_pass) = @_;
  my @pmids = split/\t/, $pmid_list;
  &getWpa();
  &getLoci();
  my $link_text = '';

  my $date = &getSimpleSecDate();
  my $pgfile = '/home/postgres/work/pgpopulation/wpa_papers/wpa_new_wbpaper_tables/perl_wpa_match/pgfile.pg.pubmed.' . $date;
  open (PG, ">$pgfile") or die "Cannot create $pgfile : $!";
  my $logfile = '/home/postgres/work/pgpopulation/wpa_papers/wpa_new_wbpaper_tables/perl_wpa_match/logfile.pubmed.' . $date;
  open (LOG, ">$logfile") or die "Cannot create $logfile : $!";
  
  my $sleep = 0;
  foreach my $pmid (@pmids) {
    if ($sleep) { &slp(); }			# if flagged to sleep, wait
    unless ($sleep) { $sleep++; }		# first time through don't sleep
#       my @lc = localtime;			# comply with NCBI's requirement of doing it at night
#       while ($lc[2] < 18) {
#         sleep 600;
#         @lc = localtime; }
    my $url = "http\:\/\/eutils\.ncbi\.nlm\.nih\.gov\/entrez\/eutils\/efetch\.fcgi\?db\=pubmed\&id\=$pmid\&retmode\=xml";
    my $page = getPubmedPage($url);
    $link_text .= &processPubmedPage($page, $pmid, $two_number, $not_first_pass);
    print STDERR "no error : $pmid\n";
  } # foreach my $pmid (sort keys %pmids)

  close (LOG) or die "Cannot close $logfile : $!";
  close (PG) or die "Cannot close $pgfile : $!";

  if ($link_text) { 
    my $user = 'wbpaper_editor_form';
    my $email = 'qwang@its.caltech.edu, spamanet@gmail.com, cecilia@tazendra.caltech.edu';
#     my $email = 'qwang@its.caltech.edu, spamanet@gmail.com';
#     my $email = 'qwang@its.caltech.edu, ranjana@its.caltech.edu';
#     my $email = 'azurebrd@tazendra.caltech.edu';
    my $subject = 'pmids entered through form';
    &mailer($user, $email, $subject, $link_text); }
  return $link_text;
} # processPubmed


sub processPubmedPage {
  my $page = shift; my $pmid = shift; my $two_number = shift; my $not_first_pass = shift;
  $page =~ s/\n//g;
  return if $page =~ /\<Error\>.+?\<\/Error\>/i;
  
  print LOG "PMID : $pmid ";
  my $link_text = '';

  my ($title) = $page =~ /\<ArticleTitle\>(.+?)\<\/ArticleTitle\>/i;   
  my ($journal) = $page =~ /<MedlineTA>(.+?)\<\/MedlineTA\>/i;
  my ($volume) = $page =~ /\<Volume\>(.+?)\<\/Volume\>/i;   
  my ($pages) = $page =~ /\<MedlinePgn\>(.+?)\<\/MedlinePgn\>/i;   
  my ($PubDate) = $page =~ /\<PubDate\>(.+?)\<\/PubDate\>/i;
  my ($year) = $PubDate =~ /\<Year\>(.+?)\<\/Year\>/i;
  my ($type) = $page =~ /\<PublicationType\>(.+?)\<\/PublicationType\>/i;
  my ($abstract) = $page =~ /\<AbstractText\>(.+?)\<\/AbstractText\>/i;
  my $editor = '';
  my $fulltext_url = '';
  
  my @authors = $page =~ /\<Author.*?\>(.+?)\<\/Author\>/ig;
  my $authors = "";
  foreach (@authors){
      my ($lastname, $initials) = $_ =~ /\<LastName\>(.+?)\<\/LastName\>.+\<Initials\>(.+?)\<\/Initials\>/i;
      $authors .= $lastname . " " . $initials . '//'; }
  if ($authors =~ m/\/\/$/) { $authors =~ s/\/\/$//; }

  my $joinkey = '';

  my $result = $dbh->prepare( "SELECT * FROM wpa_identifier WHERE wpa_identifier = 'pmid$pmid' ORDER BY wpa_timestamp;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    if ($row[0]) { if ($row[3] eq 'valid') { $joinkey = $row[0]; } else { $joinkey = ''; } } }
  if ($joinkey) { 
      print LOG "matches WBPaper$joinkey\n"; 
      $link_text .= "$pmid existed as <A HREF=http://tazendra.caltech.edu/~postgres/cgi-bin/wbpaper_display.cgi?action=Number+%21&number=$joinkey TARGET=NEW>WBPaper$joinkey</A><BR>\n";
      if ($title) { &checkPg($two_number, $joinkey, 'title', 'wpa_title', $title); }
      if ($journal) { &checkPg($two_number, $joinkey, 'journal', 'wpa_journal', $journal); }
      if ($volume) { &checkPg($two_number, $joinkey, 'volume', 'wpa_volume', $volume); }
      if ($pages) { &checkPg($two_number, $joinkey, 'pages', 'wpa_pages', $pages); }
      if ($year) { &checkPg($two_number, $joinkey, 'year', 'wpa_year', $year); }
      if ($type) { &checkPg($two_number, $joinkey, 'type', 'wpa_type', $type); }
      if ($abstract) { &checkPg($two_number, $joinkey, 'abstract', 'wpa_abstract', $abstract); }
      if ($authors) { &checkPg($two_number, $joinkey, 'authors', 'wpa_author', $authors); } }
    else {
      print LOG "does not match in wpa_identifier\n"; 
      unless ($title) { $title = ''; } unless ($authors) { $authors = ''; } unless ($journal) { $journal = ''; }
      unless ($volume) { $volume = ''; } unless ($pages) { $pages = ''; } unless ($year) { $year = ''; }
      unless ($abstract) { $abstract = ''; } unless ($type) { $type = ''; }
      my $line = "$pmid\t$authors\t$title\t$journal\t$volume\t$pages\t$year\t$abstract\t\t$type\t$editor\t$fulltext_url";
      my ($log_text) = &matchLine('pmid', $line, $two_number, $not_first_pass);
      if ($log_text) {
        my $temp_text = '';
        if ($log_text =~ m/(TOO MANY.*?)\n/) { $temp_text = "$1"; }
        if ($log_text =~ m/(MERGE WITH.*?)\n/) { $temp_text = "$1"; }
        if ($log_text =~ m/(FLAG.*?)\n/) { $temp_text = "$1"; }
        if ($log_text =~ m/(LOW.*?)\n/) { $temp_text = "$1"; }
        if ($temp_text) { 
          if ($temp_text =~ m/\d+/) { $temp_text =~ s/(\d+)/<A HREF=http:\/\/tazendra.caltech.edu\/~postgres\/cgi-bin\/wbpaper_display.cgi?action=Number+%21&number=$1 TARGET=NEW>WBPaper$1<\/A>/g; }
          $link_text .= "$pmid $temp_text .<BR>\n"; } }
      print LOG $log_text; }
  print LOG "\n";
  return $link_text;
} # sub processPubmedPage

  # changed checkPg to always add genes with merging.  2005 09 07  
sub checkPg {
  my ($two_number, $joinkey, $type, $pgtable, $pm_value) = @_;
  my $result = $dbh->prepare( "SELECT * FROM $pgtable WHERE joinkey = '$joinkey' ORDER BY wpa_timestamp DESC;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  my @row = $result->fetchrow;
  if ($pgtable eq 'wpa_gene') { 				# always add genes
    $pgtable = 'add_gene_theresa'; 
    &addPg($two_number, $joinkey, $pgtable, $pm_value); }	# don't add genes directly, process in addPg
  elsif ($row[0]) {						# if there's already data
    if ($row[3] eq 'valid') { 					# and it's valid
        print LOG "$type value -= $row[1] =- already in, ignoring -= $pm_value =-.\n"; }	# don't add it
      else { &addPg($two_number, $joinkey, $pgtable, $pm_value); } }				# if it's not valid, add it
  else { &addPg($two_number, $joinkey, $pgtable, $pm_value); }	# if there's no data add it
} # sub checkPg

sub addPg {
  my ($two_number, $joinkey, $pgtable, $pm_value, $evidence) = @_;
  unless ($evidence) { $evidence = 'NULL'; }
  unless ($two_number) { $two_number = 'two1823'; }
  my $pg_command = '';
  if ($pgtable eq 'wpa_author') {
    my (@authors) = split/\/\//, $pm_value;
    my $result = $dbh->prepare( "SELECT wpa_order FROM wpa_author WHERE joinkey = '$joinkey' ORDER BY wpa_order DESC; " );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    my @row = $result->fetchrow; my $author_rank = $row[0];	# get highest author_rank
#       $result = $conn->exec( "SELECT last_value FROM wpa_author_index_author_id_seq;");	# wbpaper_editor.cgi doesn't use sequence, we don't either
    $result = $dbh->prepare( "SELECT author_id FROM wpa_author_index ORDER BY author_id DESC;");
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    @row = $result->fetchrow; my $auth_joinkey = $row[0];	# get highest author_id
    foreach my $author (@authors) {
      $auth_joinkey++; $author_rank++;
      if ($author =~ m/\'/) { $author =~ s/\'/''/g; }
#       my $result = $conn->exec( "SELECT author_id FROM wpa_author_index ORDER BY author_id DESC;");	# shouldn't be here 2009 05 27
      $result = $dbh->do( "INSERT INTO wpa_author_index VALUES ($auth_joinkey, '$author', NULL, 'valid', '$two_number', CURRENT_TIMESTAMP);");
      print PG "INSERT INTO wpa_author_index VALUES ($auth_joinkey, '$author', NULL, 'valid', '$two_number', CURRENT_TIMESTAMP);\n";
      $result = $dbh->do( "INSERT INTO wpa_author VALUES ('$joinkey', '$auth_joinkey', $author_rank, 'valid', '$two_number', CURRENT_TIMESTAMP);");
      print PG "INSERT INTO wpa_author VALUES ('$joinkey', '$auth_joinkey', $author_rank, 'valid', '$two_number', CURRENT_TIMESTAMP);\n";

      print LOG "add author $joinkey $pgtable $auth_joinkey $author\n"; } }
  elsif ($pgtable eq 'add_gene_theresa') {
    my @genes = split/\s+/, $pm_value; my %filtered_loci;
    foreach my $gene (@genes) { if ($cdsToGene{locus}{$gene}) { foreach my $wbgene (@{ $cdsToGene{locus}{$gene} }) { $filtered_loci{$wbgene}++; } } }
    foreach my $word (sort keys %filtered_loci) { &addPg($two_number, $joinkey, 'wpa_gene', $word, 'theresa'); } }
  elsif ($pgtable eq 'wpa_gene') {
    if ($evidence eq 'theresa') { 
        $evidence = "'Curator_confirmed\t\"WBPerson627\"'"; }
      else { 
        $evidence = "'Inferred_automatically\t\"Abstract read $pm_value\"'"; }
    my %filtered_gene;
    foreach my $wbgene (@{ $cdsToGene{locus}{$pm_value} }) {	# each possible wbgene that matches that word
      $filtered_gene{$wbgene}++ }
    foreach my $wbgene (sort keys %filtered_gene) {
      my $pm_gene_value = $wbgene . "($pm_value)"; 			# wbgene(word)
      if ($pm_gene_value =~ m/\'/) { $pm_gene_value =~ s/\'/''/g; }
      $pg_command = "INSERT INTO $pgtable VALUES ('$joinkey', '$pm_gene_value', $evidence, 'valid', '$two_number', CURRENT_TIMESTAMP);"; 
      my $result = $dbh->do( $pg_command );
      print PG "$pg_command\n"; 
      print LOG "add $joinkey $pgtable $pm_value\n"; } }
  else {
    if ( ($pgtable eq 'wpa_year') || ($pgtable eq 'wpa_title') || ($pgtable eq
'wpa_journal') || ($pgtable eq 'wpa_editor') || ($pgtable eq 'wpa_in_book') || ($pgtable eq 'wpa_fulltext_url') ) { 1; }
    elsif ($pgtable eq 'wpa_volume') {
      if ($pm_value =~ m/(\d+)\s+(Suppl)\s+(\d+)/) { $pm_value = "$1 ${2}${3}"; }	# deal with Suppl data differently. for Ranjana / Andrei didn't say anything  2005 12 20
      if ($pm_value =~ m/\-/) { $pm_value =~ s/\-+/\/\//g; } if ($pm_value =~ m/\s+/) { $pm_value =~ s/\s+/\/\//; } }	# only change the first space to // for doublequotes in .ace output
    elsif ($pgtable eq 'wpa_pages') {
      if ($pm_value =~ m/^(\d+)[\s\-]+(\d+)/) { 
        my $first = $1; my $second = $2;
        if ($second < $first) {
          my @second = split//, $second ; my $count = scalar( @second );
          my @first = split//, $first; for (1 .. $count) { pop @first; }
          my $full_second = join"", @first; $second = $full_second . $second; }
        $pm_value = $first . '//' . $second; } }
    elsif ($pgtable eq 'wpa_abstract') {
      if ($pm_value =~ m/\n/) { $pm_value =~ s/\n/ /g; }
      if ($pm_value =~ m/\s+$/) { $pm_value =~ s/\s+$//; }
      if ($pm_value =~ m/\s+/) { $pm_value =~ s/\s+/ /g; }
      &parseGenes($two_number, $joinkey, $pm_value);
      if ($pm_value =~ m/\\/) { $pm_value =~ s/\\//g; }             # get rid of all backslashes
      if ($pm_value =~ m/^\"\s*(.*?)\s*\"$/) { $pm_value = $1; }    # get rid of surrounding doublequotes
      if ($pm_value =~ m/\'/) { $pm_value =~ s/\'/''/g; } }
    elsif ($pgtable eq 'wpa_type') {
      ($pm_value) = lc($pm_value);					# make matches case insensitive  2009 06 30
      if ($pm_value eq 'comment') { $pm_value = '10'; }			# comment
      elsif ($pm_value eq 'editorial') { $pm_value = '13'; }		# editorial
      elsif ($pm_value eq 'journal article') { $pm_value = '1'; }	# article
      elsif ($pm_value eq 'newspaper article') { $pm_value = '1'; }	# article
      elsif ($pm_value eq 'letter') { $pm_value = '11'; }		# letter
      elsif ($pm_value eq 'news') { $pm_value = '6'; }			# news
      elsif ($pm_value eq 'published erratum') { $pm_value = '15'; }	# erratum
      elsif ($pm_value =~ m/review/) { $pm_value = '2'; }		# review
      elsif ($pm_value =~ m/book_chapter/) { $pm_value = '5'; }		# book chapter (for wormbook / igor  2006 04 28)
      elsif ($pm_value =~ m/meeting abstract/) { $pm_value = '3'; }	# Meeting abstract   2006 05 04
      elsif ($pm_value =~ m/wormbook/) { $pm_value = '18'; }		# WormBook   2007 02 06
      else { $pm_value = '17'; } }					# other
    else { 1; }
    if ($pm_value =~ m/\'/) { $pm_value =~ s/\'/''/g; }
    $pg_command = "INSERT INTO $pgtable VALUES ('$joinkey', '$pm_value', $evidence, 'valid', '$two_number', CURRENT_TIMESTAMP);"; 
    my $result = $dbh->do( $pg_command );
    print PG "$pg_command\n"; 
    print LOG "add $joinkey $pgtable $pm_value\n";
  }
} # sub addPg

sub parseGenes {
  my ($two_number, $joinkey, $abstract) = @_;
  if ($abstract =~ m/,/) { $abstract =~ s/,//g; }
  if ($abstract =~ m/\(/) { $abstract =~ s/\(//g; }
  if ($abstract =~ m/\)/) { $abstract =~ s/\)//g; }
  if ($abstract =~ m/;/) { $abstract =~ s/;//g; }
  my %filtered_loci;
  my (@words) = split/\s+/, $abstract;
  foreach my $word (@words) {
    if ($cdsToGene{locus}{$word}) { $filtered_loci{$word}++; } }
#   foreach my $word (@words) { if ($cdsToGene{locus}{$word}) { foreach my $wbgene (@{ $cdsToGene{locus}{$word} }) { $filtered_loci{$wbgene}++; } } }	# this seems wrong 2006 10 10
  foreach my $word (sort keys %filtered_loci) { &addPg($two_number, $joinkey, 'wpa_gene', $word); }
} # sub parseGenes

sub getPubmedPage {
    my $u = shift;
    my $page = "";
    my $ua = LWP::UserAgent->new(timeout => 30); # instantiates a new user agent
    my $request = HTTP::Request->new(GET => $u); # grabs url
    my $response = $ua->request($request);       # checks url, dies if not valid.
#    die "Error while getting ", $response->request->uri," -- ", $response->status_line, "\nAborting" unless $response-> is_success;
    $page = $response->content;    #splits by line
    $page = &filterForeign($page);
    return $page;
} # sub getPubmedPage

sub getLoci {			# genes to all other possible names
  my @pgtables = qw( gin_locus gin_molname gin_protein gin_seqname gin_sequence gin_synonyms );
  foreach my $table (@pgtables) {					# updated to get values from postgres 2006 12 19
    my $result = $dbh->prepare( "SELECT * FROM $table;" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) { 
      my $wbgene = 'WBGene' . $row[0];
      push @{ $cdsToGene{locus}{$row[1]} }, $wbgene; } }

  if ($cdsToGene{locus}{run}) { delete $cdsToGene{locus}{run}; }	# Andrei's exclusion list 2006 07 15
  if ($cdsToGene{locus}{SC}) { delete $cdsToGene{locus}{SC}; }
  if ($cdsToGene{locus}{GATA}) { delete $cdsToGene{locus}{GATA}; }
  if ($cdsToGene{locus}{eT1}) { delete $cdsToGene{locus}{eT1}; }
  if ($cdsToGene{locus}{RhoA}) { delete $cdsToGene{locus}{RhoA}; }
  if ($cdsToGene{locus}{TBP}) { delete $cdsToGene{locus}{TBP}; }
  if ($cdsToGene{locus}{syn}) { delete $cdsToGene{locus}{syn}; }
  if ($cdsToGene{locus}{TRAP240}) { delete $cdsToGene{locus}{TRAP240}; }
  if ($cdsToGene{locus}{'AP-1'}) { delete $cdsToGene{locus}{'AP-1'}; }
} # sub getLoci

sub filterForeign {		# take out foreign characters before they can get into postgres  for Cecilia  2006 05 04
  my $change = shift;
  if ($change =~ m/[‚„…ˆŠ‹ŒŽ‘’“”—˜š›œžŸª«­¯±·»¼½¾ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüý]/) {
    if ($change =~ m/‚/) { $change =~ s/‚/,/g; }
    if ($change =~ m/„/) { $change =~ s/„/"/g; }
    if ($change =~ m/…/) { $change =~ s/…/.../g; }
    if ($change =~ m/ˆ/) { $change =~ s/ˆ/^/g; }
    if ($change =~ m/Š/) { $change =~ s/Š/S/g; }
    if ($change =~ m/‹/) { $change =~ s/‹/</g; }
    if ($change =~ m/Œ/) { $change =~ s/Œ/OE/g; }
    if ($change =~ m/Ž/) { $change =~ s/Ž/Z/g; }
    if ($change =~ m/‘/) { $change =~ s/‘/'/g; }
    if ($change =~ m/’/) { $change =~ s/’/'/g; }
    if ($change =~ m/“/) { $change =~ s/“/"/g; }
    if ($change =~ m/”/) { $change =~ s/”/"/g; }
    if ($change =~ m/—/) { $change =~ s/—/-/g; }
    if ($change =~ m/˜/) { $change =~ s/˜/~/g; }
    if ($change =~ m/š/) { $change =~ s/š/s/g; }
    if ($change =~ m/›/) { $change =~ s/›/>/g; }
    if ($change =~ m/œ/) { $change =~ s/œ/oe/g; }
    if ($change =~ m/ž/) { $change =~ s/ž/z/g; }
    if ($change =~ m/Ÿ/) { $change =~ s/Ÿ/y/g; }
    if ($change =~ m/ª/) { $change =~ s/ª/a/g; }
    if ($change =~ m/«/) { $change =~ s/«/"/g; }
    if ($change =~ m/­/) { $change =~ s/­/-/g; }
    if ($change =~ m/¯/) { $change =~ s/¯/-/g; }
    if ($change =~ m/±/) { $change =~ s/±/+\/-/g; }
    if ($change =~ m/·/) { $change =~ s/·/-/g; }
    if ($change =~ m/»/) { $change =~ s/»/"/g; }
    if ($change =~ m/¼/) { $change =~ s/¼/1\/4/g; }
    if ($change =~ m/½/) { $change =~ s/½/1\/2/g; }
    if ($change =~ m/¾/) { $change =~ s/¾/3\/4/g; }
    if ($change =~ m/À/) { $change =~ s/À/A/g; }
    if ($change =~ m/Á/) { $change =~ s/Á/A/g; }
    if ($change =~ m/Â/) { $change =~ s/Â/A/g; }
    if ($change =~ m/Ã/) { $change =~ s/Ã/A/g; }
    if ($change =~ m/Ä/) { $change =~ s/Ä/A/g; }
    if ($change =~ m/Å/) { $change =~ s/Å/A/g; }
    if ($change =~ m/Æ/) { $change =~ s/Æ/AE/g; }
    if ($change =~ m/Ç/) { $change =~ s/Ç/C/g; }
    if ($change =~ m/È/) { $change =~ s/È/E/g; }
    if ($change =~ m/É/) { $change =~ s/É/E/g; }
    if ($change =~ m/Ê/) { $change =~ s/Ê/E/g; }
    if ($change =~ m/Ë/) { $change =~ s/Ë/E/g; }
    if ($change =~ m/Ì/) { $change =~ s/Ì/I/g; }
    if ($change =~ m/Í/) { $change =~ s/Í/I/g; }
    if ($change =~ m/Î/) { $change =~ s/Î/I/g; }
    if ($change =~ m/Ï/) { $change =~ s/Ï/I/g; }
    if ($change =~ m/Ð/) { $change =~ s/Ð/D/g; }
    if ($change =~ m/Ñ/) { $change =~ s/Ñ/N/g; }
    if ($change =~ m/Ò/) { $change =~ s/Ò/O/g; }
    if ($change =~ m/Ó/) { $change =~ s/Ó/O/g; }
    if ($change =~ m/Ô/) { $change =~ s/Ô/O/g; }
    if ($change =~ m/Õ/) { $change =~ s/Õ/O/g; }
    if ($change =~ m/Ö/) { $change =~ s/Ö/O/g; }
    if ($change =~ m/×/) { $change =~ s/×/x/g; }
    if ($change =~ m/Ø/) { $change =~ s/Ø/O/g; }
    if ($change =~ m/Ù/) { $change =~ s/Ù/U/g; }
    if ($change =~ m/Ú/) { $change =~ s/Ú/U/g; }
    if ($change =~ m/Û/) { $change =~ s/Û/U/g; }
    if ($change =~ m/Ü/) { $change =~ s/Ü/U/g; }
    if ($change =~ m/Ý/) { $change =~ s/Ý/Y/g; }
    if ($change =~ m/ß/) { $change =~ s/ß/B/g; }
    if ($change =~ m/à/) { $change =~ s/à/a/g; }
    if ($change =~ m/á/) { $change =~ s/á/a/g; }
    if ($change =~ m/â/) { $change =~ s/â/a/g; }
    if ($change =~ m/ã/) { $change =~ s/ã/a/g; }
    if ($change =~ m/ä/) { $change =~ s/ä/a/g; }
    if ($change =~ m/å/) { $change =~ s/å/a/g; }
    if ($change =~ m/æ/) { $change =~ s/æ/ae/g; }
    if ($change =~ m/ç/) { $change =~ s/ç/c/g; }
    if ($change =~ m/è/) { $change =~ s/è/e/g; }
    if ($change =~ m/é/) { $change =~ s/é/e/g; }
    if ($change =~ m/ê/) { $change =~ s/ê/e/g; }
    if ($change =~ m/ë/) { $change =~ s/ë/e/g; }
    if ($change =~ m/ì/) { $change =~ s/ì/i/g; }
    if ($change =~ m/í/) { $change =~ s/í/i/g; }
    if ($change =~ m/î/) { $change =~ s/î/i/g; }
    if ($change =~ m/ï/) { $change =~ s/ï/i/g; }
    if ($change =~ m/ð/) { $change =~ s/ð/o/g; }
    if ($change =~ m/ñ/) { $change =~ s/ñ/n/g; }
    if ($change =~ m/ò/) { $change =~ s/ò/o/g; }
    if ($change =~ m/ó/) { $change =~ s/ó/o/g; }
    if ($change =~ m/ô/) { $change =~ s/ô/o/g; }
    if ($change =~ m/õ/) { $change =~ s/õ/o/g; }
    if ($change =~ m/ö/) { $change =~ s/ö/o/g; }
    if ($change =~ m/÷/) { $change =~ s/÷/\//g; }
    if ($change =~ m/ø/) { $change =~ s/ø/o/g; }
    if ($change =~ m/ù/) { $change =~ s/ù/u/g; }
    if ($change =~ m/ú/) { $change =~ s/ú/u/g; }
    if ($change =~ m/û/) { $change =~ s/û/u/g; }
    if ($change =~ m/ü/) { $change =~ s/ü/u/g; }
    if ($change =~ m/ý/) { $change =~ s/ý/y/g; }
  }
  if ($change =~ m/[€ƒ†‡‰•™¡¢£¤¥¦§¨©¬®°²³´µ¶¹º¿þÞ]/) { $change =~ s/[€ƒ†‡‰•™¡¢£¤¥¦§¨©¬®°²³´µ¶¹º¿þÞ]//g; }
  return $change;
} # sub filterForeign

sub slp {
#     my $rand = int(rand 15) + 5;	# random 5-20 seconds
    my $rand = 5;			# just 5 seconds
    print LOG "Sleeping for $rand seconds...\n";
    sleep $rand;
    print LOG "done.\n";
} # sub slp


__END__

# SELECT * FROM wpa_author_index_author_id_seq;
# SELECT setval('wpa_author_index_author_id_seq', 74426);

pg_deleting :	# CHANGE DATE IF USING THIS !
SELECT * FROM wpa WHERE wpa_timestamp > '2005-08-17 15:30:00';
SELECT * FROM wpa_identifier WHERE wpa_timestamp > '2005-08-17 15:30:00';
SELECT * FROM wpa_title WHERE wpa_timestamp > '2005-08-17 15:30:00';
SELECT * FROM wpa_journal WHERE wpa_timestamp > '2005-08-17 15:30:00';
SELECT * FROM wpa_volume WHERE wpa_timestamp > '2005-08-17 15:30:00';
SELECT * FROM wpa_pages WHERE wpa_timestamp > '2005-08-17 15:30:00';
SELECT * FROM wpa_year WHERE wpa_timestamp > '2005-08-17 15:30:00';
SELECT * FROM wpa_type WHERE wpa_timestamp > '2005-08-17 15:30:00';
SELECT * FROM wpa_abstract WHERE wpa_timestamp > '2005-08-17 15:30:00';
SELECT * FROM wpa_author WHERE wpa_timestamp > '2005-08-17 15:30:00';
SELECT * FROM wpa_author_index WHERE wpa_timestamp > '2005-08-17 15:30:00';
SELECT * FROM wpa_gene WHERE wpa_timestamp > '2005-08-17 15:30:00';


sub getLociObsolete {			# updated to use full list of words that could match multiple wbgenes in @{ %cdsToGene{locus}{word} }, wbgenes  2006 06 08
  my $u = "http://tazendra.caltech.edu/~azurebrd/sanger/loci_all.txt";
  my $ua = LWP::UserAgent->new(timeout => 30); #instantiates a new user agent
  my $request = HTTP::Request->new(GET => $u); #grabs url
  my $response = $ua->request($request);       #checks url, dies if not valid.
  die "Error while getting ", $response->request->uri," -- ",
  $response->status_line, "\nAborting" unless $response-> is_success;
  my @tmp = split /\n/, $response->content;    #splits by line
  foreach my $line (@tmp) {
    my ($three, $wb, $useful) = $line =~ m/^(.*?),(.*?),.*?,(.*?),/;      # added to convert genes
    if ($useful) {
      $useful =~ s/\([^\)]*\)//g;
      if ($useful =~ m/\s+$/) { $useful =~ s/\s+$//g; }
      my (@cds) = split/\s+/, $useful;
# NOT USING CDS
#       foreach my $cds (@cds) {
#         $cdsToGene{cds}{$cds} = $wb;
#         if ($cds =~ m/[a-zA-Z]+$/) { $cds =~ s/[a-zA-Z]+$//g; }
#         $cdsToGene{cds}{$cds} = $wb; }
      push @{ $cdsToGene{locus}{$three} }, $wb;		# push 3-letter into array 
#       $cdsToGene{locus}{$three} = $wb;		# using array since a word could have multiple wbgene values
      if ($line =~ m/,([^,]*?) ,approved$/) {            # 2005 06 08
        my @things = split/ /, $1;
        foreach my $thing (@things) {
          if ($thing =~ m/[a-zA-Z][a-zA-Z][a-zA-Z]\-\d+/) {
#             $cdsToGene{locus}{$thing} = $wb; 		# put cds stuff in array since a word could have multiple wbgenes
            push @{ $cdsToGene{locus}{$thing} }, $wb; } } }	# still called locus but really any of multiple things
  } }
  $u = "http://tazendra.caltech.edu/~azurebrd/sanger/wbgenes_to_words.txt";
  $ua = LWP::UserAgent->new(timeout => 30); #instantiates a new user agent
  $request = HTTP::Request->new(GET => $u); #grabs url
  $response = $ua->request($request);       #checks url, dies if not valid.
  die "Error while getting ", $response->request->uri," -- ",
  $response->status_line, "\nAborting" unless $response-> is_success;
  @tmp = split /\n/, $response->content;    #splits by line
  foreach my $line (@tmp) {
    next unless($line);
    my ($gene, $other) = split/\t/, $line;
    push @{ $cdsToGene{locus}{$other} }, $gene; }
  if ($cdsToGene{locus}{run}) { delete $cdsToGene{locus}{run}; }	# Andrei's exclusion list 2006 07 15
  if ($cdsToGene{locus}{SC}) { delete $cdsToGene{locus}{SC}; }
  if ($cdsToGene{locus}{GATA}) { delete $cdsToGene{locus}{GATA}; }
  if ($cdsToGene{locus}{eT1}) { delete $cdsToGene{locus}{eT1}; }
  if ($cdsToGene{locus}{RhoA}) { delete $cdsToGene{locus}{RhoA}; }
  if ($cdsToGene{locus}{TBP}) { delete $cdsToGene{locus}{TBP}; }
  if ($cdsToGene{locus}{syn}) { delete $cdsToGene{locus}{syn}; }
  if ($cdsToGene{locus}{TRAP240}) { delete $cdsToGene{locus}{TRAP240}; }
  if ($cdsToGene{locus}{'AP-1'}) { delete $cdsToGene{locus}{'AP-1'}; }
} # sub getLociObsolete 

