#!/usr/bin/perl

# test parse the mapping of gpi file to yuling's ccc output to make sure every matched gene has a uniprot id.
# 2013 04 26
#
# populate ccc_componentindex and ccc_geneprodindex with files that haven't already been indexed for each 
# of the listed mods from the source/ directory.  based on ws234_gpi file (will need to change that to some 
# generic that Kimberly can update).  2013 05 03
#
# changed worm files to ws238_gpi from ws234_gpi  2013 08 07

use strict;
use DBI;
use Encode qw( from_to is_utf8 );
use LWP::Simple;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %accession_map;      # mapping of paper accession IDs pmid to modid
&populateTextpressoAccession(); 

my %textpresso_chars;   # textpresso characters that got converted to underscored codes
&popTextpressoChars();


my %alreadyIndexed;
$result = $dbh->prepare( "SELECT DISTINCT(ccc_file) FROM ccc_geneprodindex" );
# COMMENT OUT TO ALWAYS POPULATE ALL FILES
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $alreadyIndexed{$row[0]}++; }

my $root_dir = '/home/acedb/kimberly/ccc/';
chdir($root_dir) or die "Cannot chdir to $root_dir : $!";

my %geneprodToGroup;
# my %nameToGene;
# my %nameToUni;			# multiple values possible 
my %gpi_files;
# $gpi_files{'tair'} = 'TAIR1_gpi';
# $gpi_files{'worm'} = 'ws234_gpi';
# $gpi_files{'worm'} = 'ws238_gpi';
$gpi_files{'tair'}  = 'tair_gpi';
$gpi_files{'worm'}  = 'worm_gpi';
$gpi_files{'dicty'} = 'dicty_gpi';
foreach my $mod (sort keys %gpi_files) {
  my $infile = 'ccc_gpi/' . $mod . '/' . $gpi_files{$mod};
  open (IN, "<$infile") or die "Cannot open $infile : $!";
  while (my $line = <IN>) {
    chomp $line;
    my ($dbObjId, $dbObjSym, $dbObjName, $dbObjSyn, $dbObjType, $taxon, $parObjId, $dbXref, $geneProdProp) = split/\t/, $line;
    my @uni;
    if ($dbXref =~ m/(UniProtKB:\w+)/) { (@uni) = $dbXref =~ m/(UniProtKB:\w+)/g; }
    my $pairName = $dbObjSym;
    $pairName = uc($pairName);
    my $uni = join"&", @uni;
    my @group; push @group, $pairName; push @group, $dbObjId; push @group, $uni;
    my $group = join"|", @group;
    my $lc_dbObjSym = $dbObjSym; $lc_dbObjSym = lc($lc_dbObjSym);
    $geneprodToGroup{$mod}{$lc_dbObjSym}{$group}++;
  #   foreach my $uni (@uni) {
  #     my @group; push @group, $pairName; push @group, $dbObjId; push @group, $uni;
  #     my $group = join"|", @group;
  #     $geneprodToGroup{$mod}{$dbObjSym}{$group}++; }
  
    if ($dbObjSyn) {
      my (@syns) = split/\|/, $dbObjSyn;
      foreach my $syn (@syns) {
        my $pairName = $dbObjSym . '(' . $syn . ')'; 
        my $lc_syn = $syn; $lc_syn = lc($lc_syn);
        $pairName = uc($pairName);
  # print "SYN $syn PAIR $pairName E\n";
        foreach my $uni (@uni) {
          my @group; push @group, $pairName; push @group, $dbObjId; push @group, $uni;
          my $group = join"|", @group;
          $geneprodToGroup{$mod}{$lc_syn}{$group}++; } } }
  #   my @group; push @group, $dbObjSym; push @group, $dbObjId; push @group, $uni;
  # add dbObjSyn mapping, split on |
  #   my $group = join"|", @group;
  #   $nameToGene{$dbObjSym} = $group;
  #   if (scalar @uni > 0) {
  #     foreach my $uni (@uni) { 
  #       $nameToUni{$dbObjSym}{$uni}++; } }
  } # while (my $line = <IN>)
  close (IN) or die "Cannot close $infile : $!";
} # foreach my $mod (sort keys %gpi_files)


# uppercase all symbol/synonyms to display as proteins


my @pgcommands;
my @mods = qw( dicty worm tair );
my %byIdent;
# my @infiles = qw( ccc_celegans_2013only );
foreach my $mod (@mods) {
  my $outfile = 'gene_index_file_' . $mod;
#   open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
#   my (@infiles) = <../source/${mod}/*>;
  my (@infiles) = <ccc_source/${mod}/*>;
  foreach my $infile (@infiles) {
#   $infile = 'ccc_celegans_2013only';
#     my $filename = $infile; $filename =~ s/..\/source\/${mod}\///g; 
    my $filename = $infile; $filename =~ s/ccc_source\/${mod}\///g; 
    next if ($filename =~ m/^pmid_data/);					# UNTESTED, skip if file is the pmid_data file
    next if ($alreadyIndexed{$filename});				# skip files already indexed in postgres
    open (IN, "<$infile") or die "Cannot open $infile : $!";
    while (my $line = <IN>) {
      chomp $line;
      my ($score, $ident, $geneprods, $component, $sentence) = split/\t/, $line;
      $byIdent{$mod}{$filename}{$ident}{componentindex}{$component}++;
      my (@geneprods) = split/\|/, $geneprods;
      my %bad; my %good;
      foreach my $source (@geneprods) {
        my $geneprod = $source; $geneprod = lc($geneprod);
        if ($geneprodToGroup{$mod}{$geneprod}) { 
            foreach my $group (sort keys %{ $geneprodToGroup{$mod}{$geneprod} }) { 
              $byIdent{$mod}{$filename}{$ident}{geneprodindex}{$group}++;
#               print OUT "$geneprod\t$group\t$filename\t$ident\n";
              $good{$group}++; } }
          else { $bad{$geneprod}++; }
      } # foreach my $source (@geneprods)
      my @bad = sort keys %bad;
# UNCOMMENT TO SHOW ERRORS
#       if (scalar @bad > 0) { print "BAD $mod $infile @bad LINE $line\n"; }
    } # while (my $line = <IN>)
    close (IN) or die "Cannot close $infile : $!";
  } # foreach my $infile (@infiles)
#   close (OUT) or die "Cannot close $outfile : $!";
} # foreach my $mod (@mods)

my %papers;
my @pgcommands;
foreach my $mod (sort keys %byIdent) {
  foreach my $filename (sort keys %{ $byIdent{$mod} }) {
    foreach my $ident (sort keys %{ $byIdent{$mod}{$filename} }) {
      foreach my $pgtable (sort keys %{ $byIdent{$mod}{$filename}{$ident} }) {
        my ($paper, $section, $sentnum);
        my @blah = split/:/, $ident;
        $sentnum = pop @blah;
        $section = pop @blah;
        $paper = join":", @blah;
        my @groups = sort keys %{ $byIdent{$mod}{$filename}{$ident}{$pgtable} };
        my $groups = join"\t", @groups;
        if ($groups =~ m/\'/) { $groups =~ s/\'/''/g; }
        $papers{$mod}{$paper}++;
#         print "$mod\t$filename\t$paper\t$section\t$sentnum\t$groups\n";
        my $pgcommand = qq(INSERT INTO ccc_$pgtable VALUES ('$mod', '$filename', '$paper', '$section', '$sentnum', E'$groups'););
        push @pgcommands, $pgcommand;
      } # foreach my $pgtable (sort keys %{ $byIdent{$mod}{$filename}{$ident} })
    } # foreach my $filename (sort keys %{ $byIdent{$mod}{$filename} })
  } # foreach my $filename (sort keys %{ $byIdent{$mod} })
} # foreach my $mod (sort keys %byIdent)

foreach my $pgcommand (@pgcommands) {
  print "$pgcommand\n";
# UNCOMMENT TO POPULATE
  $dbh->do( $pgcommand );
} # foreach my $pgcommand (@pgcommands)

foreach my $mod (sort keys %papers) {
#   my $modfile = '../source/' . $mod . '/pmid_data.' . $mod;
  my $modfile = 'ccc_source/' . $mod . '/pmid_data.' . $mod;
  my %already_in_paper_info;
  open (IN, "<$modfile") or die "Cannot open $modfile : $!";
  while (<IN>) { chomp; my ($pmid, $modid, $title, $abstract) = split/\t/, $_; $already_in_paper_info{$pmid}++; }
  close (IN) or die "Cannot close $modfile : $!";
  open (OUT, ">>$modfile") or die "Cannot open $modfile : $!";
  foreach my $pmid (sort keys %{ $papers{$mod} }) {
    next if ($already_in_paper_info{$pmid});
    my $modid = $pmid;							# by default modid is pmid (dicty)
    if ($accession_map{$pmid}) { $modid = $accession_map{$pmid}; }	# most mods map to a modid (tair, worm)
    my ($title, $abstract) = &getTextpressoTitleAbstract($modid, $mod);
    if ($title && $abstract) {
      print OUT qq($pmid\t$modid\t$title\t$abstract\n); }
  } # foreach my $pmid (sort keys %{ $papers{$mod} })
  close (OUT) or die "Cannot close $modfile : $!";
} # foreach my $mod (sort keys %mod)

sub getTextpressoTitleAbstract {        # for a given mod ID and selected form mod, get paper title and abstract by URL
  my ($modid, $formMod) = @_;
  my ($title, $abstract) = ('', '');
  my $modsDontMatch = 0;
  my ($urlMod, $num) = split/:/, $modid;
  if ($urlMod eq 'PMID') { $urlMod = 'dicty25'; unless ($formMod eq 'dicty') { $modsDontMatch++; } }
    elsif ($urlMod eq 'TAIR') { $urlMod = 'arabidopsis'; unless ($formMod eq 'tair') { $modsDontMatch++; } }
    elsif ($urlMod eq 'celegans') { unless ($formMod eq 'worm') { $modsDontMatch++; } }
  unless ($modsDontMatch) {
    my $url = 'http://textpresso-dev.caltech.edu/' . $urlMod . '/tdb/' . $urlMod . '/txt/bib-all/' . $num;
#     print "URL $url URL\n";
    my ($tdata) = get $url;
    my (@lines) = split/\n/, $tdata;
    my @abstract; my @title;
    foreach my $line (@lines) {
      if ($line =~ m/^abstract_#(.*)$/) { my ($sentence) = &convertTextpressoSentence($1); push @abstract, $sentence; }
        elsif ($line =~ m/^title_#(.*)$/) { my ($sentence) = &convertTextpressoSentence($1); push @title, $sentence; } }
    $abstract = join" ", @abstract;
    $title = join" ", @title; }
#   unless ($title) {    $title    = 'cannot find title from textpresso'; }	# if want a text message for this
#   unless ($abstract) { $abstract = 'cannot find abstract from textpresso'; }	# if want a text message for this
# http://textpresso-dev.caltech.edu/celegans/tdb/celegans/txt/bib-all/WBPaper00037556	# sample URLs
# http://textpresso-dev.caltech.edu/dicty25/tdb/dicty25/txt/bib-all/19692569
# http://textpresso-dev.caltech.edu/arabidopsis/tdb/arabidopsis/txt/bib-all/11042
  return ($title, $abstract);
} # sub getTextpressoTitleAbstract

sub convertTextpressoSentence {         # convert underscore coded textpresso sentence to human readable sentence
  my ($origSentence) = @_; my @sentence;
  my (@words) = split/\s+/, $origSentence;
  foreach my $word (@words) {
    if ($textpresso_chars{$word}) { $word = $textpresso_chars{$word}; }
    push @sentence, $word; }
  my $sentence = join" ", @sentence;
  return $sentence;
} # sub convertTextpressoSentence

sub popTextpressoChars {                        # to convert textpresso underscore codes to punctuation
# my %textpresso_chars; # textpresso characters that got converted to underscored codes
  $textpresso_chars{"_DQ_"}   =  '"' ;
  $textpresso_chars{"_SQ_"}   =  "'" ;
  $textpresso_chars{"_LT_"}   =  '<' ;
  $textpresso_chars{"_GT_"}   =  '>' ;
  $textpresso_chars{"_EQ_"}   =  '=' ;
  $textpresso_chars{"_AND_"}  =  '&' ;
  $textpresso_chars{"_AT_"}   =  '@' ;
  $textpresso_chars{"_SLH_"}  =  '/' ;
  $textpresso_chars{"_DLR_"}  =  '$' ;
  $textpresso_chars{"_PCT_"}  =  '%' ;
  $textpresso_chars{"_CRT_"}  =  '^' ;
  $textpresso_chars{"_STR_"}  =  '*' ;
  $textpresso_chars{"_PLS_"}  =  '+' ;
  $textpresso_chars{"_VRT_"}  =  '|' ;
  $textpresso_chars{"_BSL_"}  =  '\\' ;
  $textpresso_chars{"_HSH_"}  =  '#' ;
  $textpresso_chars{"_PRD_"}  =  '.' ;
  $textpresso_chars{"_QMK_"}  =  '?' ;
  $textpresso_chars{"_EMK_"}  =  '!' ;
  $textpresso_chars{"_CMM_"}  =  ',' ;
  $textpresso_chars{"_SCL_"}  =  ';' ;
  $textpresso_chars{"_CLN_"}  =  ':' ;
  $textpresso_chars{"_OSB_"}  =  '[' ;
  $textpresso_chars{"_CSB_"}  =  ']' ;
  $textpresso_chars{"_ORB_"}  =  '(' ;
  $textpresso_chars{"_CRB_"}  =  ')' ;
  $textpresso_chars{"_OCB_"}  =  '{' ;
  $textpresso_chars{"_CCB_"}  =  '}' ;
} # sub popTextpressoChars


sub populateTextpressoAccession {			# get mapping of PMIDs to ModIDs for textpresso title and abstract
  my $url = 'http://textpresso-dev.caltech.edu/ccc_results/accession';        # to get accession dynamically
  my ($accession_data) = get $url;
  my (@lines) = split/\n/, $accession_data;
  foreach my $line (@lines) {
    my ($pmid, $modid) = split/\s+/, $line;
    $accession_map{$pmid} = $modid;
  }
#   my $infile = 'accession';                                             # use flatfile from a cronjob
#   open (IN, "<$infile") or warn "Cannot open $infile : $!";
#   while (my $line = <IN>) {
#     chomp $line;
#     my ($pmid, $modid) = split/\s+/, $line;
#     $accession_map{$pmid} = $modid;
#   } # while (my $line = <IN>)
#   close (IN) or warn "Cannot close $infile : $!";
#   print "AC $accession_data AC";
} # sub populateTextpressoAccession


__END__

# WBGene00000390	cdc-42	R07G3.1|WP:CE02020	gene	taxon:6239	WB:WBGene00000390	CCD:CCD70511|UniProtKB:Q05062
#   get :
# CCD:CCD70511|UniProtKB:Q05062
#   map this into column 1 of form (yuling, col1, col8 uniprot part)
# CDC-42:WBGene00000390:UniProtKB:Q05062



total 12792
-rw-r--r-- 1 azurebrd azurebrd 1083310 2013-04-25 16:09 
-rwxr-xr-x 1 azurebrd azurebrd   40320 2013-04-26 11:55 ccc.cgi*
-rw-r--r-- 1 azurebrd azurebrd 3701928 2013-04-05 14:24 c_elegans.WS234.xrefs.txt
-rw-r--r-- 1 azurebrd azurebrd 3547627 2013-04-02 12:58 c_elegans.WS236.xrefs.txt
-rwxr-xr-x 1 azurebrd azurebrd    2876 2013-04-08 16:13 generate_gpi.pl*
-rw-r--r-- 1 azurebrd azurebrd     194 2013-04-02 13:50 gpi_file
-rwxr-xr-x 1 azurebrd azurebrd       0 2013-04-26 12:26 map_sent_to_gpi.pl*
-rw-r--r-- 1 azurebrd azurebrd     112 2013-04-26 11:56 todo
-rw-r--r-- 1 azurebrd azurebrd 4701208 2013-04-08 16:12 
lrwxrwxrwx 1 azurebrd azurebrd      60 2013-04-05 13:02 ws234_tablemaker_info.txt -> /home/acedb/kimberly/ccc_2_testing/ws234_tablemaker_info.txt
#!/usr/bin/perl -w

# sample PG query

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

$result = $dbh->prepare( "SELECT * FROM two_comment" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[1] =~ s///g;
    $row[2] =~ s///g;
    print "$row[0]\t$row[1]\t$row[2]\n";
  } # if ($row[0])
} # while (@row = $result->fetchrow)

__END__

my $result = $dbh->prepare( 'SELECT * FROM two_comment WHERE two_comment ~ ?' );
$result->execute('elegans') or die "Cannot prepare statement: $DBI::errstr\n"; 

$result->execute("doesn't") or die "Cannot prepare statement: $DBI::errstr\n"; 
my $var = "doesn't";
$result->execute($var) or die "Cannot prepare statement: $DBI::errstr\n"; 

my $data = 'data';
unless (is_utf8($data)) { from_to($data, "iso-8859-1", "utf8"); }

my $result = $dbh->do( "DELETE FROM friend WHERE firstname = 'bl\"ah'" );
(also do for INSERT and UPDATE if don't have a variable to interpolate with ? )

can cache prepared SELECTs with $dbh->prepare_cached( &c. );

if ($result->rows == 0) { print "No names matched.\n\n"; }	# test if no return

$result->finish;	# allow reinitializing of statement handle (done with query)
$dbh->disconnect;	# disconnect from DB

http://209.85.173.132/search?q=cache:5CFTbTlhBGMJ:www.perl.com/pub/1999/10/DBI.html+dbi+prepare+execute&cd=4&hl=en&ct=clnk&gl=us

interval stuff : 
SELECT * FROM afp_passwd WHERE joinkey NOT IN (SELECT joinkey FROM afp_lasttouched) AND joinkey NOT IN (SELECT joinkey FROM cfp_curator) AND afp_timestamp < CURRENT_TIMESTAMP - interval '21 days' AND afp_timestamp > CURRENT_TIMESTAMP - interval '28 days';

casting stuff to substring on other types :
SELECT * FROM afp_passwd WHERE CAST (afp_timestamp AS TEXT) ~ '2009-05-14';

to concatenate string to query result :
  SELECT 'WBPaper' || joinkey FROM pap_identifier WHERE pap_identifier ~ 'pmid';
to get :
  SELECT DISTINCT(gop_paper_evidence) FROM gop_paper_evidence WHERE gop_paper_evidence NOT IN (SELECT 'WBPaper' || joinkey FROM pap_identifier WHERE pap_identifier ~ 'pmid') AND gop_paper_evidence != '';

