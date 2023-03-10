#!/usr/bin/perl


################################################################################
#
# Pre-processing Instructions
# 
# Open a browser to http://www.ncbi.nlm.nih.gov:80/entrez/query.fcgi and
# search for ``elegans''.  Set the Display (button next to it) to MEDLINE,
# click DISPLAY again to reload.  Click the Save button (not the text
# button, since that only shows the first page of all the matches).
# Ask Wen for the latest version of gophbib.endnote or download from
# http://vermicelli.caltech.edu/~wen/gophbib.endnote
#
#
# About the code
#
# Read both CGCs (endnote) and PMs (pubmed.medline) into hashes keying off
# of Volume Page Author.  If a key is not well-formed, store separetly to
# output as error.  If no entry, store separetly for output as error.  Count 
# number of time a key is used.  (Print out if more than once for each file).  
# Foreach PM key, if both PM and CGC, print; if not, store as missing CGC 
# counterpart.  Same foreach CGC key.  Foreach missing counterpart CGC, print 
# it.  Same foreach missing counterpart PM.			- 08 11 01
#
# If a key has more than one entry, output summary to double, full entries to
# double_full.  If good, output summary to good_output, .ace entry to acefile.
# If a PM has no matching CGC entry, output to pm_nocgc.  If a CGC has no 
# matching PM, output to cgc_nopm.  If a PM key is not complete, output to 
# pm_badkey1.  If a CGC key is not complete output to cgc_badkey1.  Later try 
# to process cgc_nopm with pm_badkey1 and pm_nocgc to try to find further 
# matches.  Also manually check double_full for good PM entries.
#
# Secondpass takes the remaining PM entries that didn't match CGC entries, and
# the remaining CGC entries that didn't match PM entries, and processes them
# by replacing C. with Caenorhabditis, and removing all but letters and digits
# from the titles to make a new key for the hashes of the second pass.  Keying
# off of the title, the full values, IDs, and a counter hash (for each title)
# is made for CGCs and PMs.  Foreach of these keys, then, if both a PM and CGC
# have an entry, that is outputted to good_output_2 (summary), and the acefile.
# Likewise, multiple keys are stored into the similar double_two; however,
# entries here have already been screened in double, so only in the case
# that a new match is found (Unlikely since only 30 additional matches are 
# accomplished this way), does a WARN get printed to check if it's the proper
# entry.  The remaining unmatched entries are passed on to a set of third 
# hashes for possible future processing.			- 08 15 01 
#
# Potential need to manually check double (double_full), for possible good 
# matches.  Also pm_badkey1 to see if those entries could have matched some 
# cgc entries.
#
# Note : If revised, put data for each key into a Hash of Arrays, instead of
# a plain Hash; that way we can keep all data instead of making second hashes
# that Count the amount of times a key has been used (and lose the previous
# value)
#
################################################################################
#
# Preprocessing step added to pre-process pubmed entries into a set of good
# tab-delimited entries.  &pm_preprocess needs be run only once each time a new
# set is downloaded.  This step is useful because it cuts down time in testing
# the parsing and comparsion by not having to re-parse all data every time.
# 2002 03 25
#
# Two comparison methods.  Two sets of hashes.  %cgc_key %pm_key and
# %cgc_full_key %pm_full_key.  The first two search on volume, page, and author,
# the last two search on those and the first 10 letters of title.  There are 
# currently 3524 matches the first way (with 3 extras, 2 of which are pubmed
# repeats) and 3358 matches the second way (with 2 extras, 2 of which are the 
# same pubmed repeats).  A possible way to do this later on # is when Theresa 
# re-releases the gophbib.endnote file do a search by the second tab field, 
# which is the pubmed UI field.  As it is, I think the first # method gives 
# good enough results for now, so will use &pm_vs_cgc_probable();   2002 03 29  
#
# Updated &pm_vs_cgc_probable(); to print out to an insertfile for dropping
# and recreating the ref_xref table and indices, which is a 1 to 1 table of 
# cgcs and pmids.  Updating this table should be a matter of downloading the
# latest pubmed.medline, uncommenting the &pm_preprocess(); running this script,
# checking the insertfile.pl and running that script (or a wrapper)  2002 03 30
#
################################################################################
#
# Updated to add &getpmfrompg(); which checks the pms that are in postgres 
# through Andrei.  These are added to the %pm_key for &pm_vs_cgc_probable();
# to find matches, but only added if not already in there through &getpm();.
# 2002 12 16
#
# Added &printTxtXref(); for Eimear to have a txt output of cgc-pmid connections
# after each update.  Same for /home/postgres/work/pgpopulation/cgc_pmid_automatic
# version because used by Daniel/Theresa cronjob.  2003 06 05
#
# Created table ref_xrefpmidforced for manually forced cgc-pmid connections instead
# of using script.  2004 01 08





  # New Way
use strict;
use diagnostics;
use lib qw( /usr/lib/perl5/site_perl/5.6.1/i686-linux/ );
use Pg;
use Jex; # getSimpleDate

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

# globals
my %cgc_author;
my %cgc_volume;
my %cgc_pages;
my %cgc_title;
my %cgc_key;		# HoA
my %cgc_full_key;	# HoA
my %pm_author;
my %pm_volume;
my %pm_pages;
my %pm_title;
my %pm_key;
my %pm_full_key;

my $insertfile = 'insertfile.pl';
open (INS, ">$insertfile") or die "Cannot create $insertfile : $!";
&getcgc();
# &pm_preprocess();
&getpm();
&getpmfrompg();		# add to hash from those pmids that have been added to postgres
# &pm_vs_cgc(); 
&pm_vs_cgc_probable(); 

# &force_xref();	# no longer needed since there is a ref_xrefpmidforced table for that
close (INS) or die "Cannot close $insertfile : $!";

&printTxtXref();

sub printTxtXref {
  my $textfile = '/home/postgres/public_html/cgc_pmid_xref.txt';
  open (TXT, ">$textfile") or die "Cannot update $textfile : $!";
  my $date = &getSimpleDate();
  print TXT "// $date\n";
  my $result = $conn->exec( "SELECT * FROM ref_xref ORDER by ref_cgc;" );
  while (my @row = $result->fetchrow) {
    print TXT "$row[0]\t$row[1]\n";
  } # while (my @row = $result->fetchrow)
  close (TXT) or die "Cannot close $textfile : $!";
} # sub printTxtXref



sub force_xref {
  print INS "\$result = \$conn\->exec( \"INSERT INTO ref_xref VALUES ('cgc5369', 'pmid12097347');\");\n";
  print INS "\$result = \$conn\->exec( \"INSERT INTO ref_xref VALUES ('cgc5346', 'pmid12095617');\");\n";
  print INS "\$result = \$conn\->exec( \"INSERT INTO ref_xref VALUES ('cgc5345', 'pmid12084813');\");\n";
  print INS "\$result = \$conn\->exec( \"INSERT INTO ref_xref VALUES ('cgc5845', 'pmid12576476');\");\n";
  print INS "\$result = \$conn\->exec( \"INSERT INTO ref_xref VALUES ('cgc5844', 'pmid12576475');\");\n";
  print INS "\$result = \$conn\->exec( \"INSERT INTO ref_xref VALUES ('cgc5825', 'pmid12672692');\");\n";
  print INS "\$result = \$conn\->exec( \"INSERT INTO ref_xref VALUES ('cgc5944', 'pmid12702662');\");\n";
  print INS "\$result = \$conn\->exec( \"INSERT INTO ref_xref VALUES ('cgc5929', 'pmid12597772');\");\n";
  print INS "\$result = \$conn\->exec( \"INSERT INTO ref_xref VALUES ('cgc5889', 'pmid12603202');\");\n";
  print INS "\$result = \$conn\->exec( \"INSERT INTO ref_xref VALUES ('cgc5845', 'pmid12576476');\");\n";
  print INS "\$result = \$conn\->exec( \"INSERT INTO ref_xref VALUES ('cgc5844', 'pmid12576475');\");\n";
  print INS "\$result = \$conn\->exec( \"INSERT INTO ref_xref VALUES ('cgc5825', 'pmid12672692');\");\n";
  print INS "\$result = \$conn\->exec( \"INSERT INTO ref_xref VALUES ('cgc5944', 'pmid12702662');\");\n";
  print INS "\$result = \$conn\->exec( \"INSERT INTO ref_xref VALUES ('cgc5929', 'pmid12597772');\");\n";
  print INS "\$result = \$conn\->exec( \"INSERT INTO ref_xref VALUES ('cgc5889', 'pmid12603202');\");\n";
  print INS "\$result = \$conn\->exec( \"INSERT INTO ref_xref VALUES ('cgc5920', 'pmid12672828');\");\n";
  print INS "\$result = \$conn\->exec( \"INSERT INTO ref_xref VALUES ('cgc5826', 'pmid12672694');\");\n";
  print INS "\$result = \$conn\->exec( \"INSERT INTO ref_xref VALUES ('cgc5800', 'pmid12584198');\");\n";
  print INS "\$result = \$conn\->exec( \"INSERT INTO ref_xref VALUES ('cgc5769', 'pmid12595721');\");\n";
  print INS "\$result = \$conn\->exec( \"INSERT INTO ref_xref VALUES ('cgc5941', 'pmid12682045');\");\n";
  print INS "\$result = \$conn\->exec( \"INSERT INTO ref_xref VALUES ('cgc5852', 'pmid12696058');\");\n";
  print INS "\$result = \$conn\->exec( \"INSERT INTO ref_xref VALUES ('cgc6000', 'pmid12711598');\");\n";
  print INS "\$result = \$conn\->exec( \"INSERT INTO ref_xref VALUES ('cgc5694', 'pmid14516686');\");\n";
  print INS "\$result = \$conn\->exec( \"INSERT INTO ref_xref VALUES ('cgc3608', 'pmid10421575');\");\n";
} # sub force_xref

sub getcgc {
  my $result = $conn->exec( "SELECT * FROM ref_author WHERE joinkey ~ \'cgc\' AND ref_author IS NOT NULL;" );
  while (my @row = $result->fetchrow) {
    $cgc_author{$row[0]} = $row[1];
    $cgc_author{$row[0]} =~ s/^(\w+).*$/$1/;
  } # while (my @row = $result->fetchrow)
  $result = $conn->exec( "SELECT * FROM ref_pages WHERE joinkey ~ \'cgc\' AND ref_pages IS NOT NULL;" );
  while (my @row = $result->fetchrow) {
    $cgc_pages{$row[0]} = $row[1];
    $cgc_pages{$row[0]} =~ s/^(\d+).*$/$1/;
  } # while (my @row = $result->fetchrow)
  $result = $conn->exec( "SELECT * FROM ref_volume WHERE joinkey ~ \'cgc\' AND ref_volume IS NOT NULL;" );
  while (my @row = $result->fetchrow) {
    $cgc_volume{$row[0]} = $row[1];
  } # while (my @row = $result->fetchrow)
  $result = $conn->exec( "SELECT * FROM ref_title WHERE joinkey ~ \'cgc\' AND ref_title IS NOT NULL;" );
  while (my @row = $result->fetchrow) {
    $cgc_title{$row[0]} = $row[1];
    $cgc_title{$row[0]} =~ s/C\.? ?[Ee]legans\b/Caenorhabditis elegans/g;
					# filter abbreviation
  } # while (my @row = $result->fetchrow)

    # make keys and hash by keys
  for (my $i = 1; $i < 10000; $i++) { 
    my $cgc_key = 'cgc' . $i;
    if ( ($cgc_author{$cgc_key}) && ($cgc_pages{$cgc_key}) && ($cgc_volume{$cgc_key}) ) {
      my $comp_key = $cgc_volume{$cgc_key} . " " . $cgc_pages{$cgc_key} . " " . $cgc_author{$cgc_key};
      push @{ $cgc_key{$comp_key} }, $cgc_key;
      if ($cgc_title{$cgc_key}) {
        $cgc_title{$cgc_key} = substr($cgc_title{$cgc_key}, 0, 10);	# get just 10 chars
        my $full_comp_key = $cgc_volume{$cgc_key} . " " . $cgc_pages{$cgc_key} . " " . $cgc_author{$cgc_key} . " " .  $cgc_title{$cgc_key};
        push @{ $cgc_full_key{$full_comp_key} }, $cgc_key;
      } # if ($cgc_title)
    } # if ( ($cgc_author{$key}) & ($cgc_pages{$key}) & ($cgc_volume))
  } # for (my $i = 1; $i < 10000; $i++)
} # sub getcgc

sub pm_preprocess {
  $/ = "";			# reset $/ just in case
  my $pmfile = '/home/postgres/work/pgpopulation/cgc_pmid_automatic/pubmed.medline';
  my $pm_parsed = '/home/postgres/work/pgpopulation/cgc_pmid_automatic/pubmed.parsed';
  my $pm_error = '/home/postgres/work/pgpopulation/cgc_pmid_automatic/pubmed.medline.error';
  open (PM, "<$pmfile") or die "Cannot open $pmfile : $!";
  open (PP, ">$pm_parsed") or die "Cannot open $pm_parsed : $!";
  open (PERR, ">$pm_error") or die "Cannot open $pm_error : $!";
  my $err_count = 0; my $full_count = 0;
  while (my $frompm = <PM>) {
    $full_count++;
    my ($pmid, $vol, $pag, $aut, $titlepm) = qw(- - - - -);
    if ($frompm =~ m/PMID- (\d+)/) { $pmid = $1; }
    if ($frompm =~ m/VI  - (\d+)/) { $vol = $1; }
    if ($frompm =~ m/PG  - (\d+)/) { $pag = $1; }
    if ($frompm =~ m/AU  - (\w+)/) { $aut = $1; }
    if ($frompm =~ m/TI  - (.*?)\n....\-/s) {
      $titlepm = &pmtitle($frompm);	# set the pmtitle
      $titlepm =~ s/C\.? ?[Ee]legans\b/Caenorhabditis elegans/g;	# filter abbreviation
      $titlepm =~ s/\n//g;		# take out newlines
    } # if ($frompm =~ m/TI  - (.*?)\n....\-/s)
    unless ( ($pmid ne '-') & ($vol ne '-') & ($pag ne '-') & ($aut ne '-') & ($titlepm ne '-') ) {
      print PERR "$frompm\n"; $err_count++;
    } else {
      print PP "$pmid\t$vol\t$pag\t$aut\t$titlepm\n";
    } # else # unless ( $pmid & $vol & $pag & $aut & $titlepm )
  } # while (my $frompm = <PM>)
  print PERR "ERROR COUNT : $err_count out of $full_count\n";
  $/ = "\n";			# put $/ back to normal
} # sub pm_preprocess

sub getpmfrompg {			# add to hash from those pmids that have been added to postgres
  my $result = $conn->exec( "SELECT * FROM ref_author WHERE joinkey ~ \'pmid\' AND ref_author IS NOT NULL;" );
  my %pmids;
  while (my @row = $result->fetchrow) {
    $pm_author{$row[0]} = $row[1];
    $pm_author{$row[0]} =~ s/^(\w+).*$/$1/;
    $pmids{$row[0]}++;
  } # while (my @row = $result->fetchrow)
  $result = $conn->exec( "SELECT * FROM ref_pages WHERE joinkey ~ \'pmid\' AND ref_pages IS NOT NULL;" );
  while (my @row = $result->fetchrow) {
    $pm_pages{$row[0]} = $row[1];
    $pm_pages{$row[0]} =~ s/^(\d+).*$/$1/;
    $pmids{$row[0]}++;
  } # while (my @row = $result->fetchrow)
  $result = $conn->exec( "SELECT * FROM ref_volume WHERE joinkey ~ \'pmid\' AND ref_volume IS NOT NULL;" );
  while (my @row = $result->fetchrow) {
    $pm_volume{$row[0]} = $row[1];
    $pmids{$row[0]}++;
  } # while (my @row = $result->fetchrow)
  $result = $conn->exec( "SELECT * FROM ref_title WHERE joinkey ~ \'pmid\' AND ref_title IS NOT NULL;" );
  while (my @row = $result->fetchrow) {
    $pm_title{$row[0]} = $row[1];
    $pm_title{$row[0]} =~ s/C\.? ?[Ee]legans\b/Caenorhabditis elegans/g;
					# filter abbreviation
    $pmids{$row[0]}++;
  } # while (my @row = $result->fetchrow)

  foreach my $pmid (sort keys %pmids) {
    my $id = $pmid; 
    $id =~ s/pmid//g;
    # make keys and hash by keys
#   for (my $i = 1; $i < 10000; $i++) 
    if ( ($pm_author{$pmid}) && ($pm_pages{$pmid}) && ($pm_volume{$pmid}) ) {
      my $comp_key = $pm_volume{$pmid} . " " . $pm_pages{$pmid} . " " . $pm_author{$pmid};
        # if not already in from the main &getpm(), add it in
      unless ($pm_key{$comp_key}) { push @{ $pm_key{$comp_key} }, $id; }	
      if ($pm_title{$pmid}) {
        $pm_title{$pmid} = substr($pm_title{$pmid}, 0, 10);	# get just 10 chars
        my $full_comp_key = $pm_volume{$pmid} . " " . $pm_pages{$pmid} . " " . $pm_author{$pmid} . " " .  $pm_title{$pmid};
        push @{ $pm_full_key{$full_comp_key} }, $pmid;
      } # if ($pm_title)
    } # if ( ($pm_author{$key}) & ($pm_pages{$key}) & ($pm_volume))
  } 
} # sub getpmfrompg

sub getpm {			# process pm
  my $pmfile = '/home/postgres/work/pgpopulation/cgc_pmid_automatic/pubmed.parsed';
  open (PM, "$pmfile") or die "Cannot open $pmfile : $!";
  while (<PM>) {
    chomp;
    my ($pmid, $vol, $pag, $aut, $title) = split/\t/, $_;
    $pm_author{$pmid} = $aut;
    $pm_volume{$pmid} = $vol;
    $pm_pages{$pmid} = $pag;
    $pm_title{$pmid} = $title;
    my $key = $pm_volume{$pmid} . " " . $pm_pages{$pmid} . " " . $pm_author{$pmid}; 
if ($pmid eq '12154385') { print "KEY $key\n"; }
    push @{ $pm_key{$key} }, $pmid;
    $pm_title{$pmid} = substr($pm_title{$pmid}, 0, 10);	# get just 10 chars
    $key = $pm_volume{$pmid} . " " . $pm_pages{$pmid} . " " . $pm_author{$pmid} . " " .  $pm_title{$pmid};
    push @{ $pm_full_key{$key} }, $pmid;
  } # while (my $frompm = <PM>)
  close (PM) or die "Cannot close $pmfile : $!";
} # sub getpm 

sub pm_vs_cgc_probable {
    # create insertfile to call insertfile.pl to recreate and populate ref_xref pg table
  my @files = qw($insertfile);
  print INS "#!\/usr\/bin\/perl\n";
  print INS "\n";
  print INS "use Pg;\n";
  print INS "\n";
  print INS "\$conn = Pg::connectdb(\"dbname=testdb\");\n";
  print INS "die \$conn->errorMessage unless PGRES_CONNECTION_OK eq \$conn->status;\n\n";
  
  print INS "\$result = \$conn\->exec( \"DELETE FROM ref_xref \");\n";
#   print INS "\$result = \$conn\->exec( \"DROP TABLE ref_xref \");\n";
#   print INS "\$result = \$conn\->exec( \"CREATE TABLE ref_xref ( ref_cgc TEXT, ref_pmid TEXT, ref_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP ) \");\n";
#   print INS "\$result = \$conn\->exec( \"GRANT ALL ON ref_xref TO nobody \");\n";
#   print INS "\$result = \$conn\->exec( \"GRANT ALL ON ref_xref TO acedb \");\n";
#   print INS "\$result = \$conn\->exec( \"CREATE UNIQUE INDEX ref_xref_cgc_idx ON ref_xref ( ref_cgc )\");\n";
#   print INS "\$result = \$conn\->exec( \"CREATE UNIQUE INDEX ref_xref_pmid_idx ON ref_xref ( ref_pmid )\");\n";

  foreach my $comp_key (sort keys %pm_key) {
# if ($comp_key eq '3 622-630 Rankin, CH') { print "$pm_key{$comp_key}\n"; }
    if ($cgc_key{$comp_key}) { 		# probable match
# warnings
#       if (scalar (@{ $pm_key{$comp_key} }) > 1) { print "Too many PM\n"; }
#       if (scalar (@{ $cgc_key{$comp_key} }) > 1) { print "Too many CGC\n"; }
#       print "MATCH : $comp_key\t";
# simple display, tab delimitted
      unless ( (scalar (@{ $pm_key{$comp_key} }) > 1) || (scalar (@{$cgc_key{$comp_key}}) > 1) ) {
        print INS "\$result = \$conn\->exec( \"INSERT INTO ref_xref VALUES (\'$cgc_key{$comp_key}[0]\', \'pmid$pm_key{$comp_key}[0]\') \");\n";
      } else { 
        print "ERROR :\t"; 
        foreach (@{ $pm_key{$comp_key} }) {	# print the pms
          print "pm : $_\t";
        } # foreach (@{ $pm_key{$comp_key} })
        foreach (@{ $cgc_key{$comp_key} }) {	# print the cgcs
          print "cgc : $_\t";
        } # foreach (@{ $cgc_key{$comp_key} })
        print "\n";
      } # else # unless ( (scalar (@{ $pm_key{$comp_key} }) > 1) || (scalar (@{$cgc_key{$comp_key}}) > 1) )
# full display with extras
#       foreach (@{ $pm_key{$comp_key} }) {	# print the pms
#         print "pm : $_\t";
#       } # foreach (@{ $pm_key{$comp_key} })
#       foreach (@{ $cgc_key{$comp_key} }) {	# print the cgcs
#         print "cgc : $_\t";
#       } # foreach (@{ $cgc_key{$comp_key} })
#       print "\n";
    } # if ($cgc_key{$comp_key}) 
  } # foreach my $comp_key (sort keys %pm_key)
  my $whatever = chmod 0755, $insertfile;
  print "Chmod : $whatever\n";
# why this don't work, i have no idea (says no such file or directory)
#   unless (-e $insertfile) { print "No $insertfile\n"; }
#   else {
#     print "Yes $insertfile\n";
#     chmod (0755, @files) == scalar(@files) or die "Cannot chmod $insertfile : $!";
#   }
} # sub pm_vs_cgc_probable

sub pm_vs_cgc {
  foreach my $comp_key (sort keys %pm_full_key) {
    if ($comp_key eq '241 247 Hanna The Caenorhabditis elegans EGL-26 protein mediates vulval cell morphogenesis.') { print "YES, "; }
    if ($cgc_full_key{$comp_key}) { 		# definite match
# warnings
#       if (scalar (@{ $pm_full_key{$comp_key} }) > 1) { print "Too many PM\n"; }
#       if (scalar (@{ $cgc_full_key{$comp_key} }) > 1) { print "Too many CGC\n"; }
#       print "MATCH : $comp_key\t";
      foreach (@{ $pm_full_key{$comp_key} }) {	# print the pms
        print "pm : $_\t";
      } # foreach (@{ $pm_full_key{$comp_key} })
      foreach (@{ $cgc_full_key{$comp_key} }) {	# print the cgcs
        print "cgc : $_\t";
      } # foreach (@{ $cgc_full_key{$comp_key} })
      print "\n";
    } # if ($cgc_full_key{$comp_key}) 
  } # foreach my $comp_key (sort keys %pm_full_key)
} # sub pm_vs_cgc



sub pmtitle {
  my $frompm = shift;
  $frompm =~ m/TI  - (.*?)\n....\-/s;
  my $titlepm = $1;
  my @titlepm = split/\n/, $titlepm;
  $titlepm = join(" " , @titlepm);
  $titlepm =~ s/  //g;
  return $titlepm;
} # sub pmtitle 

