#!/usr/bin/perl -w

# Checkout genes for concise description

# Comments script :
# Search through all text of concise descriptions (main box) for the word ``uncloned'' and
# phrase ``molecular identity .* not .* known'' -> whatever genes match those,
# take the wbgene, and look in the loci_all.txt and see if that wbgene have an
# entry in the sequence name column (multiple values in column 4, labeled CDS
# name), if it does have a sequence name, then comment should say ``needs cloning
# update''.  Could be case sensitive, so get all and lower case. 
#
# Form working.  2005 11 25
#
# Get ref_count and store in cdc_ref_count.  ``Update Gene List !'' button now
# gets a list of all WBGenes from cdc_locus and cdc_cds, then queries aceserver
# and converts the Reference WBPapers into a count of  pmids (cgcs)  that it
# then stores in  cdc_ref_count.  Sorting by count now looks at these values,
# and &displayRow($gene); now gets the count from &getRefCountPostgres($gene);
# which is from cdc_ref_count.  For Kimberly.  2005 11 29
#
# &updateRefCount(); updates the count om  pmids (cgcs)  in cdc_ref_count, this
# takes 2 hours and 3 minutes to run on 21927 wbgenes.  2005 11 31
#
# &updateGeneList(); now also looks at loci_all.txt to find 3-letter loci that
# aren't already populated from genes2molecular_names.txt  2005 12 01
#
# Created cdc_2003_refs and set a cronjob to populate it every Monday at 3am
# based on wpa_gene data.  
# 0 3 * * mon /home/postgres/work/pgpopulation/concise_description/20060309_checkout_2003_table/populate_cdc_2003.pl
# Added a Ref Since 2003 column to show this data, and two new buttons to sort
# by them.  2006 03 10
#
# Added a new column for Curators to add themselves to a list of genes to be
# emailed if the gene is mentioned in the abstract of an Article.  2006 11 17
#
# Updated to use gin_ tables updated from nameserver and aceserver instead of
# loci_all and genes2molecular_names  2006 12 19
#
# Added Gary  2007 02 01
#
# Took out Carol
# Added a display of data currently checked out for Ranjana.  2009 01 02
#
# Only fetch genes from ace server if there's a connection made.  
# Don't look at ace server anymore, since it's flakey.  Not sure that anything 
# changed in the display.  For Kimberly.  2009 03 02
#
# Added Karen.  2010 05 22
#
# Changed from wpa to pap tables, even though they're not live.  2010 06 23
#
# added snehalvk@caltech.edu / Snehalata Kadam - WBPerson12884   2011 05 10
#
# Last timestamp change of file is 2011-05-10 15:24
# made Obsolete for Kimberly and Ranjana  2013 11 21



 
use strict;
use CGI;
use DBI;
use Jex;
use LWP::UserAgent;

use Ace;

my $query = new CGI;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n";


# use constant HOST => $ENV{ACEDB_HOST} || 'aceserver.cshl.org';
# use constant PORT => $ENV{ACEDB_PORT} || 2005;
# my $db = Ace->connect(-host=>HOST,-port=>PORT) or warn "Connection failure: ",Ace->error;

my $frontpage = 1;
my $blue = '#00ffcc';			# redefine blue to a mom-friendly color
my $red = '#ff00cc';			# redefine red to a mom-friendly color


my %theHash;

my %web;				# $web{$wbgene}{locus} , $web{$wbgene}{cds} 
my %curators;				# $curators{two}{two#} = std_name ; $curators{std}{std_name} = two#
my %paper_ids;				# $paper_ids{cgc}{cgc#} = wbpaper#; $paper_ids{wbp_cgc}{wbpaper#} = cgc#
					# $paper_ids{pmid}{pmid#} = wbpaper#; $paper_ids{wbp_pmid}{wbpaper#} = pmid#
my $curator;				# the curator_name


&printHeader('Concise Description Checkout');
&display();
&printFooter();


### DISPLAY ###

sub display {
  my $action;

  unless ($action = $query->param('action')) {
    $action = 'none';
    if ($frontpage) { &firstPage(); return; }
  } else { $frontpage = 0; }

  print "<FORM NAME='form1' METHOD=\"POST\" ACTION=\"http://tazendra.caltech.edu/~postgres/cgi-bin/concise_description_checkout.cgi\">\n";
  (my $oop, $curator) = &getHtmlVar($query, 'curator_name');
  if ($curator) { 
    $theHash{curator} = $curator;
    print "Curator : $curator<P>\n"; 
    print "<INPUT TYPE=\"HIDDEN\" NAME=\"curator_name\" VALUE=\"$theHash{curator}\">\n"; }
  else { print "<FONT COLOR='red'>ERROR : You must choose a curator.<BR>\n"; return; }

  if ($action eq 'Number !') { &pickNumber(); }
  elsif ($action eq 'Curator !') { &sortList('regex'); }
  elsif ($action eq 'Regex !') { &sortList('regex'); }
  elsif ($action eq 'Sort by Date Ascending !') { &sortList('date_asc'); }
  elsif ($action eq 'Sort by Date Descending !') { &sortList('date_desc'); }
  elsif ($action eq 'Sort by Reference Count Ascending !') { &sortList('count_asc'); }
  elsif ($action eq 'Sort by Reference Count Descending !') { &sortList('count_desc'); }
  elsif ($action eq 'Sort by Reference Since 2003 Ascending !') { &sortList('2003_asc'); }
  elsif ($action eq 'Sort by Reference Since 2003 Descending !') { &sortList('2003_desc'); }
  elsif ($action eq 'Search Genes !') { &sortList('search_genes'); }
  elsif ($action eq 'Update Gene List !') { &updateGeneList(); }
  elsif ($action eq 'Check Out and In !') { &checkOutAndIn(); }
  elsif ($action eq 'Currently Checked Out !') { &currentlyCheckedOut(); }
  elsif ($action eq 'Notify !') { &notify(); }
  else { 1; }
  print "</FORM>\n";
} # sub display

sub notify {			# if someone wants to be notified that a gene has been published in the abstract of an article add them to the list 2006 11 17
  my ($oop, $gene) = &getHtmlVar($query, 'html_value_gene');
  ($oop, my $notify) = &getHtmlVar($query, 'curator_name');
  if ($gene && $notify) {
    &populateCurators();
    my $two_num = $curators{std}{$curator};
    my $command = "INSERT INTO gen_notification VALUES ('$gene', '$notify', 'valid', '$two_num', CURRENT_TIMESTAMP);";
#     print "$command<BR>\n";
    my $result = $dbh->do( $command ); 
    print "$notify has been added to the list for $gene<BR>\n"; }
} # sub notify

sub checkOutAndIn {
  &populateCurators();
  my $two_num = $curators{std}{$curator};
  print "Curator $curator is $two_num .<BR>\n";
  my ($oop, $gene_list) = &getHtmlVar($query, 'html_value_gene_list');
  my (@list) = split/\t/, $gene_list;
  foreach my $gene (@list) { &updateGene($gene); }
} # sub checkOutAndIn

sub updateGene {			# update the grafitti and checked_out status of a given gene based on form and postgres
  my $gene = shift;
  my ($oop, $web_grafitti) = &getHtmlVar($query, "html_value_grafitti_$gene");
    my $result = $dbh->prepare( "SELECT cdc_grafitti FROM cdc_grafitti WHERE joinkey = '$gene' ORDER BY cdc_timestamp DESC;" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
    my @row = $result->fetchrow; my $insert = 0;
    if ($row[0]) { if ($row[0] ne $web_grafitti) { $insert++; } } 	# if there was a value in postgres and they're not the same, add it 
      else { if ($web_grafitti) { $insert++; } }			# if there was no value in postgres and there is a form value, add it
    if ($insert) {			# if proper, change the grafitti value
      my $command = "INSERT INTO cdc_grafitti VALUES ( '$gene', '$web_grafitti', CURRENT_TIMESTAMP );"; 
      $result = $dbh->do( $command ); print "<FONT COLOR=green>$command</FONT><BR>\n";
      print "Updating cdc_grafitti for $gene to say \`\`<FONT COLOR=blue>$web_grafitti</FONT>\'\'.<BR>\n"; } 
  ($oop, my $web_out) = &getHtmlVar($query, "html_box_out_$gene");	# get the out status of the gene
  if ($web_out) { if ($web_out eq 'yes') {				# if out, put the curators two number on the checked_out table
    my $command = "INSERT INTO cdc_checked_out VALUES ( '$gene', '$curators{std}{$curator}', CURRENT_TIMESTAMP );";
    my $result = $dbh->do( $command ); print "<FONT COLOR=green>$command</FONT><BR>\n";
    print "Updating cdc_checked_out for $gene to be checked out to you, \`\`<FONT COLOR=blue>$curators{std}{$curator}</FONT>\'\' ($curator).<BR>\n"; } }
  ($oop, my $web_in) = &getHtmlVar($query, "html_box_in_$gene");	# get the in status of the gene
  if ($web_in) { if ($web_in eq 'yes') {				# if in, put null on the checked_out table
    my $command = "INSERT INTO cdc_checked_out VALUES ( '$gene', NULL, CURRENT_TIMESTAMP );";
    my $result = $dbh->do( $command ); print "<FONT COLOR=red>$command</FONT><BR>\n";
    print "Updating cdc_checked_in for $gene to be checked in.<BR>\n"; } }
#   print "GENE $gene WEB $web_grafitti IN $web_in OUT $web_out .<BR>\n";
} # sub updateGene

sub populateWeb {
  my $result = $dbh->prepare( "SELECT * FROM gin_sequence;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) { 
    my $wbgene = 'WBGene' . $row[0];
    $web{$wbgene}{cds} = $row[1]; }
  my @pgtables = qw( gin_synonyms gin_locus );				# synonyms before locus since locus should overwrite synonyms
  foreach my $table (@pgtables) {					# updated to get values from postgres 2006 12 19
    $result = $dbh->prepare( "SELECT * FROM $table;" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
    while (my @row = $result->fetchrow) { 
      my $wbgene = 'WBGene' . $row[0];
      $web{$wbgene}{locus} = $row[1]; } }
} # sub populateWeb


sub updateGeneList {			# update cdc_locus and cdc_cds based on sanger's genes2molecular_names.txt
					# based on postgres values of aceserver and nameserver instead  2006 12 19
  &populateWeb();
  &populateCurators();
  my $two_num = $curators{std}{$curator};
  print "Curator $curator is $two_num .<BR>\n";

  my %pg;
  my $result = $dbh->prepare( "SELECT * FROM cdc_locus;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) { if ($row[1]) { $pg{$row[0]}{locus} = $row[1]; } }
  $result = $dbh->prepare( "SELECT * FROM cdc_cds;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) { if ($row[1]) { $pg{$row[0]}{cds} = $row[1]; } }

# OBSOLETE not update loci_all nor genes2molecular_names  2006 12 19
#   my $ua = LWP::UserAgent->new;
#   $ua->timeout(10);
#   $ua->env_proxy;
#   my $response = $ua->get("http://www.sanger.ac.uk/Projects/C_elegans/LOCI/genes2molecular_names.txt");
# #   my $response = $ua->get("http://tazendra.caltech.edu/~azurebrd/sanger/genes2molecular_names.txt");
#   my $sanger = '';
#   if ($response->is_success) { $sanger = $response->content;  }
#     else { die $response->status_line; }
#   print "Updating list of loci and cds based on http://www.sanger.ac.uk/Projects/C_elegans/LOCI/genes2molecular_names.txt<P>\n";
#   my (@lines) = split/\n/, $sanger;
#   foreach my $line (@lines) {
#     my ($gene, $cds) = split/\t/, $line;
#     my $locus = '';
#     if ($cds =~ m/\s+/) { ($cds, $locus) = $cds =~ m/^(.*?)\s+(.*?)$/; }
#     if ($cds) { $web{$gene}{cds} = $cds; }
#     if ($locus) { $web{$gene}{locus} = $locus; }
# #     print "GENE $gene CDS $cds LOCUS $locus<BR>\n"; 
#   } # foreach my $line (@lines)
# 
#   my $infile = '/home/azurebrd/public_html/sanger/loci_all.txt';		# look at loci_all.txt for 3-letter loci that aren't already in genes2molecular_names.txt
#   open (IN, "<$infile") or die "Cannot open $infile : $!";
#   while (my $line = <IN>) { 
#     my ($locus,$wbgene,$a,$cds,@junk) = split/,/, $line;
#     if ($wbgene && $locus) { 							# if there's a gene and a locus (should always be so)
#       unless ($web{$wbgene}{locus}) { $web{$wbgene}{locus} = $locus; } } }	# unless there's already a value, since genes2molecular_names takes precedence, assign it


  foreach my $gene (sort keys %pg) {
    if ($web{$gene}{cds} && $pg{$gene}{cds}) { 
      if ($web{$gene}{cds} eq $pg{$gene}{cds}) { delete $web{$gene}{cds}; delete $pg{$gene}{cds}; } }
    if ($web{$gene}{locus} && $pg{$gene}{locus}) { 
      if ($web{$gene}{locus} eq $pg{$gene}{locus}) { delete $web{$gene}{locus}; delete $pg{$gene}{locus}; } } }
  foreach my $gene (sort keys %web) {
    if ($web{$gene}{locus}) { 
      my $command = "INSERT INTO cdc_locus VALUES ('$gene', '$web{$gene}{locus}', CURRENT_TIMESTAMP);";
      print "$command<BR>\n";
      my $result = $dbh->do( "$command" );
      print "ADDING gene-locus connection $gene $web{$gene}{locus}<BR>\n"; } 
    if ($web{$gene}{cds}) { 
      my $command = "INSERT INTO cdc_cds VALUES ('$gene', '$web{$gene}{cds}', CURRENT_TIMESTAMP);";
      print "$command<BR>\n";
      my $result = $dbh->do( "$command" );
      print "ADDING gene-cds connection $gene $web{$gene}{cds}<BR>\n"; } }
  foreach my $gene (sort keys %pg) {
    if ($pg{$gene}{locus}) { 
      my $command = "DELETE FROM cdc_locus WHERE joinkey = '$gene' AND cdc_locus = '$pg{$gene}{locus}';";
      print "$command<BR>\n";
      my $result = $dbh->do( "$command" );
      print "DELETING gene-locus connection $gene $pg{$gene}{locus}<BR>\n"; } 
    if ($pg{$gene}{cds}) { 
      my $command = "DELETE FROM cdc_cds WHERE joinkey = '$gene' AND cdc_cds = '$pg{$gene}{cds}';";
      print "$command<BR>\n";
      my $result = $dbh->do( "$command" );
      print "DELETING gene-cds connection $gene $pg{$gene}{cds}<BR>\n"; } }
  my $command = "INSERT INTO cdc_updated_genelist VALUES ('$two_num', '$two_num', CURRENT_TIMESTAMP);";
  print "$command<BR>\n";
  $result = $dbh->do( "$command" );

  &updateComments();
  &updateRefCount();
} # sub updateGeneList

sub updateRefCount {				# get gene list from cdc_locus and cdc_cds, then get references from aceserver and count pmids (cgcs)
  &populateIdentifiers();			# put stuff in %paper_ids
  my %wbgenes; my %ace; my %pg;
  my $result = $dbh->prepare( "SELECT joinkey FROM cdc_locus;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) { $wbgenes{$row[0]}++; }
  $result = $dbh->prepare( "SELECT joinkey FROM cdc_cds;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) { $wbgenes{$row[0]}++; }
  my $count = 0;
#   my $outfile = '/home/postgres/public_html/cgi-bin/data/update_gene_info_read.txt';
#   open (OUT, ">$outfile") or die "Cannot open $outfile : $!";	# writing to a file doesn't work, i.e. it still gives a 500 Premature end of script header error.  Writing to STDERR keeps it from crashing
  my $date = &getSimpleSecDate();
  print "START $date<BR>\n";
#   print OUT "START $date\n";
  foreach my $gene (sort keys %wbgenes) {	# get aceserver counts of pmids (cgcs)
    $count++;
#   if ($count > 1000) { last; }
    unless ($gene) { next; }
# No longer looking at aceserver, since it's flakey  2009 03 02
    my $ref_count = 0; 
#     my $ref_count_cgc = 0;
#     my $query = "find Gene $gene";
#     if ($db) {
#       my @gene = $db->fetch(-query=>$query);
#       if ($gene[0]) { 
#         my (@references) = $gene[0]->Reference;
#         if ($references[0]) { 
#           foreach my $reference (@references) {
#             $reference =~ s/WBPaper//g; 
#             if ($paper_ids{wbp_pmid}{$reference}) { $ref_count++; }
#             elsif ($paper_ids{wbp_cgc}{$reference}) { $ref_count_cgc++; }
#             else { 1; } } } } }			# only count cgcs and pmids
#     if ($ref_count_cgc) { $ref_count .= ' (' . $ref_count_cgc . ')'; }
    
# if ( ($count % 10) == 0 ) { print "COUNT $count READ<BR>\n"; }
    print STDERR "GENE $gene REF $ref_count COUNT $count<BR>\n";
    $ace{$gene} = $ref_count; }
  $date = &getSimpleSecDate();
  print "END $date<BR>\n";
#   print OUT "END $date\nCount $count\n";
#   close (OUT) or die "Cannot close $outfile : $!";
  $result = $dbh->prepare( "SELECT joinkey, cdc_ref_count FROM cdc_ref_count;" );		# get postgres counts of pmids (cgcs)
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) { $pg{$row[0]} = $row[1]; }
  foreach my $gene (sort keys %pg) {
    my $ace_value = 0; my $pg_value = 0;
    if ($ace{$gene}) { $ace_value = $ace{$gene}; }
    if ($pg{$gene}) { $pg_value = $pg{$gene}; }
    if ($ace_value eq $pg_value) { delete $ace{$gene}; delete $pg{$gene}; } }		# ignore what is the same
  foreach my $gene (sort keys %ace) {		# add new values
    my $value = 0; if ($ace{$gene}) { $value = $ace{$gene}; }
    my $command = "INSERT INTO cdc_ref_count VALUES ('$gene', '$value', CURRENT_TIMESTAMP);";
    print "<FONT COLOR=green>$command</FONT><BR>\n";
    my $result = $dbh->do( "$command" );
    print "ADDING gene-ref_count connection $gene $value<BR>\n"; }
  foreach my $gene (sort keys %pg) {		# delete old values
    my $value = 0; if ($pg{$gene}) { $value = $pg{$gene}; }
    my $command = "DELETE FROM cdc_ref_count WHERE joinkey = '$gene' AND cdc_ref_count = '$value';";
    print "<FONT COLOR=red>$command</FONT><BR>\n";
    my $result = $dbh->do( "$command" );
    print "DELETING gene-ref_count connection $gene $value<BR>\n"; }
} # sub updateRefCount


sub updateComments {
# Comments script :
# Search through all text of concise descriptions (main box) for the word ``uncloned'' and
# phrase ``molecular identity .* not .* known'' -> whatever genes match those,
# take the wbgene, and look in the loci_all.txt and see if that wbgene have an
# entry in the sequence name column (multiple values in column 4, labeled CDS
# name), if it does have a sequence name, then comment should say ``needs cloning
# update''.  Could be case sensitive, so get all and lower case. 
  print "<P>Updating cdc_comments based on : car_con_maindata where it mentions a gene is uncloned or has molecular identity not known ;  nameserver and aceserver data in postgres mention that gene has a CDS ;  adds \`\`needs cloning update\'\' to cdc_comments for that gene.<P>\n";
#   print "<P>Updating cdc_comments based on : car_con_maindata where it mentions a gene is uncloned or has molecular identity not known ;  http://tazendra.caltech.edu/~azurebrd/sanger/loci_all.txt mentions that gene has a CDS ;  adds \`\`needs cloning update\'\' to cdc_comments for that gene.<P>\n";
  my %mainData; my %gene_list; my %comment_list; my %pg_comments;
  my $result = $dbh->prepare( "SELECT * FROM car_con_maindata WHERE joinkey ~ 'WBGene' ORDER BY car_timestamp;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) { $row[1] = lc($row[1]); $mainData{$row[0]} = $row[1]; }
  foreach my $gene (sort keys %mainData) {
    if ( ($mainData{$gene} =~ m/uncloned/) || ($mainData{$gene} =~ m/molecular identity.*not.*known/) ) { $gene_list{$gene}++; } }

# OBSOLETE not update loci_all nor genes2molecular_names  2006 12 19
#   my $infile = '/home/azurebrd/public_html/sanger/loci_all.txt';
#   open (IN, "<$infile") or die "Cannot open $infile : $!";
#   while (my $line = <IN>) { 
#     my ($locus,$wbgene,$a,$cds,@junk) = split/,/, $line;
#     if ($gene_list{$wbgene} && $cds) { $comment_list{$wbgene}++; } }
#   close (IN) or die "Cannot close $infile : $!";
  $result = $dbh->prepare( "SELECT * FROM gin_sequence;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) { 
    my $wbgene = 'WBGene' . $row[0];					# look at all wbgenes with sequences
    if ($row[1]) { 							# wbgene has a sequence
      if ($gene_list{$wbgene}) { $comment_list{$wbgene}++; } } }	# if it's in the list add to comment list

  my $message = 'needs cloning update';
  $result = $dbh->prepare( "SELECT * FROM cdc_comment WHERE cdc_comment = '$message' ORDER BY cdc_timestamp DESC;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) { $pg_comments{$row[0]} = $row[1]; }
  foreach my $gene (sort keys %comment_list) {				# for each gene with a comment that should be in postgres
    if ($pg_comments{$gene}) { delete $pg_comments{$gene}; } 		# if it's in postgres remove it from the postgres list and don't add it
    else {								# if it's not in postgres, add it in
      my $command = "INSERT INTO cdc_comment VALUES ('$gene', '$message', CURRENT_TIMESTAMP);";
      my $result = $dbh->do( "$command" );
      print "<FONT COLOR=green>$command</FONT><BR>\n";
      print "Inserted comment \`\`<FONT COLOR=blue>$message</FONT>\'\' for $gene<BR>\n"; } }
  foreach my $gene (sort keys %pg_comments) { 				# for each gene that is still in the postgres list and wasn't in the comment list
    my $command = "INSERT INTO cdc_comment VALUES ('$gene', NULL, CURRENT_TIMESTAMP);";		# remove it by adding a NULL
    my $result = $dbh->do( "$command" );
    print "<FONT COLOR=red>$command</FONT><BR>\n";
    print "Inserted comment \`\`<FONT COLOR=blue>$message</FONT>\'\' for $gene<BR>\n"; }
} # sub updateComments

sub sortList { 
  my $sort_type = shift;
  print "Sorting by $sort_type .<P>\n";
  &populateCurators();
  &populateIdentifiers();
  my $two_num = $curators{std}{$curator};
  print "Curator $curator is $two_num .<BR><BR>\n";
#   print "<INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Update Gene List !\"> Update postgres values of cdc_cds and cdc_locus based on genes2molecular_names.txt (primarily) and loci_all.txt (secondarily, only changing cdc_locus values for wbgenes that do not have a 3-letter name in genes2molecular_names.txt) ALSO update postgres values of cdc_commnts based on car_con_maindata and gene locus info from nameserver in postgres ALSO update postgres values of cdc_ref_count based on current wbgenes in cdc_locus and cdc_cds, and getting the pmid (cgc) count of papers from the aceserver <FONT COLOR=red>(this last part will take a ridiculously long time and may look like your browser is frozen)</FONT>.<BR><BR>\n";
  print "<INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Update Gene List !\"> Update postgres values of cdc_cds and cdc_locus based on gene info from nameserver and aceserver in postgres ALSO update postgres values of cdc_commnts based on car_con_maindata and loci_all.txt ALSO update postgres values of cdc_ref_count based on current wbgenes in cdc_locus and cdc_cds, and getting the pmid (cgc) count of papers from the aceserver <FONT COLOR=red>(this last part will take a ridiculously long time and may look like your browser is frozen)</FONT>.<BR><BR>\n";

  my ($oop, $regex) = &getHtmlVar($query, 'html_value_regex');
  unless ($regex) { $regex = ''; }
  print "<P><INPUT NAME=html_value_regex VALUE=$regex><INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Regex !\"> Postgres-style regular expression search on cds and locus names.<P>\n";
  unless ($regex) { $regex = '^aa'; }
  print "<P><INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Sort by Date Ascending !\"> Sort by Date Last Updated in Ascending order.\n";
  print "<P><INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Sort by Date Descending !\"> Sort by Date Last Updated in Descending order.\n";
  print "<P><INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Sort by Reference Count Ascending !\"> Sort by Reference Count in Ascending order.\n";
  print "<P><INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Sort by Reference Count Descending !\"> Sort by Reference Count in Descending order.\n";
  print "<P><INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Sort by Reference Since 2003 Ascending !\"> Sort by Reference Since 2003 in Ascending order.\n";
  print "<P><INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Sort by Reference Since 2003 Descending !\"> Sort by Reference Since 2003 in Descending order.\n";

  my @letters = qw( a b c d e f g h i j k l m n o p q r s t u v w x y z );
  my @cap_letters = qw( A B C D E F G H I J K L M N O P Q R S T U V W X Y Z );
  my $temp_curator = $curator; $temp_curator =~ s/\s+/+/g;
  print "<P>Letter-sorted list of loci / cds : \n";
  foreach my $letter ( @letters, @cap_letters ) { 
    print "<A HREF=http://tazendra.caltech.edu/~postgres/cgi-bin/concise_description_checkout.cgi?action=Regex+%21&curator_name=$temp_curator&html_value_regex=^$letter>$letter</A> \n"; }

#   print "<P>Looks at these urls http://tazendra.caltech.edu/~azurebrd/sanger/loci_all.txt  http://tazendra.caltech.edu/~azurebrd/sanger/genes2molecular_names.txt <BR>\n";
  print "<P>Looks at gene info data from nameserver and aceserver in postgres<BR>\n";
  print "to search for a list of genes by locus / cds / wbgene (enter WBGenes as \`\`WBGene00000001\'\', separate items with a space or newline not with commas nor semicolons):<BR>\n";
  print "<TEXTAREA NAME=\"html_value_search_list\" ROWS=5 COLS=80></TEXTAREA><BR>\n";
  print "<INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Search Genes !\">\n";

  my @list = (); delete $theHash{gene_locus}; delete $theHash{gene_cds};

  if ( $sort_type eq 'search_genes') {
    &populateFullyTheHashCdcLocusGene();						# populate theHash to get cds and locus names for row output
    my %cdsToGene;
# OBSOLETE not update loci_all nor genes2molecular_names  2006 12 19
# #     my $u = "http://www.sanger.ac.uk/Projects/C_elegans/LOCI/loci_all.txt";
#     my $u = "http://tazendra.caltech.edu/~azurebrd/sanger/loci_all.txt";		# this code lifted from wbpaper_editor.cgi
#     my $ua = LWP::UserAgent->new(timeout => 30);	#instantiates a new user agent
#     my $request = HTTP::Request->new(GET => $u);	#grabs url
#     my $response = $ua->request($request);		#checks url, dies if not valid.
#     die "Error while getting ", $response->request->uri," -- ", $response->status_line, "\nAborting" unless $response-> is_success;
#     my %temp;						# store main locus and back, to put in %cdsToGene later (since chs-1 would otherwise override)
#     my @tmp = split /\n/, $response->content;		#splits by line
#     foreach my $line (@tmp){
#         my ($three, $wb, $useful) = $line =~ m/^(.*?),(.*?),.*?,(.*?),/;      # added to convert genes
#         $useful =~ s/\([^\)]*\)//g; 
#         if ($useful =~ m/\s+$/) { $useful =~ s/\s+$//g; }
#         my (@cds) = split/\s+/, $useful;
#         foreach my $cds (@cds) {
#           $cdsToGene{cds}{$cds} = $wb; 
#           if ($cds =~ m/[a-zA-Z]+$/) { $cds =~ s/[a-zA-Z]+$//g; }
#           $cdsToGene{cds}{$cds} = $wb; }
#         $temp{locus}{$three} = $wb; 
#         $temp{back}{$wb} = $three;
#         if ($line =~ m/,([^,]*?) ,approved$/) {            # 2005 06 08
#           my @things = split/ /, $1;
#           foreach my $thing (@things) {
#             if ($thing =~ m/[a-zA-Z][a-zA-Z][a-zA-Z]\-\d+/) { $cdsToGene{locus}{$thing} = $wb; } } }
#     } # foreach my $line (@tmp)
#     foreach my $three (sort keys %{ $temp{locus} }) { $cdsToGene{locus}{$three} = $temp{locus}{$three}; }
#     foreach my $wb (sort keys %{ $temp{back} }) { $cdsToGene{back}{$wb} = $temp{back}{$wb}; }
# #     $u = 'http://www.sanger.ac.uk/Projects/C_elegans/LOCI/genes2molecular_names.txt';
#     $u = 'http://tazendra.caltech.edu/~azurebrd/sanger/genes2molecular_names.txt';
#     $request = HTTP::Request->new(GET => $u); #grabs url
#     $response = $ua->request($request);       #checks url, dies if not valid.
#     die "Error while getting ", $response->request->uri," -- ", $response->status_line, "\nAborting" unless $response-> is_success;
#     @tmp = split /\n/, $response->content;    #splits by line
#     foreach my $line (@tmp){
#       my ($wb, $cds, $three);
#       if ($line =~ m/^(.*?)\t(.*?)\s+(.*?)\s*$/) { $wb = $1; $cds = $2; $three = $3; }
#       elsif ($line =~ m/^(.*?)\t(.*?)\s+/) { $wb = $1; $cds = $2; }
#       if ($cds =~ m/\s+$/) { $cds =~ s/\s+$//g; }
#       my (@cds) = split/\s+/, $cds;
#       foreach my $cds (@cds) {
#         if ($cdsToGene{cds}{$cds}) { next; } 
#         $cdsToGene{cds}{$cds} = $wb;
#         if ($cds =~ m/[a-zA-Z]+$/) { $cds =~ s/[a-zA-Z]+$//g; }
#         $cdsToGene{cds}{$cds} = $wb; } }
    my @pgtables = qw( gin_protein gin_sequence gin_locus );
    foreach my $table (@pgtables) {                                       # updated to get values from postgres 2006 12 19
      my $result = $dbh->prepare( "SELECT * FROM $table;" );
      $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
      while (my @row = $result->fetchrow) {
        my $wbgene = 'WBGene' . $row[0];
        $cdsToGene{$row[1]} = $wbgene;
    } }
    my ($oop, $search_list) = &getHtmlVar($query, 'html_value_search_list');
    my @search_list = split/\s+/, $search_list;
    foreach my $gene (@search_list) {
      if ($gene =~ m/[Ww][Bb][Gg]ene/) { push @list, $gene; }
      elsif ($cdsToGene{$gene}) { push @list, $cdsToGene{$gene}; }
      elsif ($cdsToGene{$gene}) { push @list, $cdsToGene{$gene}; }
      else { print "$gene failed to match a WBGene<BR>\n"; } }
  }
  elsif ( ($sort_type eq 'date_asc') || ($sort_type eq 'date_desc') ) {
    &populateFullyTheHashCdcLocusGene();						# populate theHash to get cds and locus names for row output
    my %dateSort;									# get the list of last verified genes ordered by date
    my $result = $dbh->prepare( "SELECT * FROM car_con_last_verified WHERE joinkey ~ 'WBGene' ORDER BY car_timestamp; " ); 
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
    while (my @row = $result->fetchrow) { 
      my $date = $row[2]; $date =~ s/\D//g; ($date) = $date =~ m/(.{14})/;		# convert the date into a 14 digit number, some will share this number
      $dateSort{gene}{$row[0]} = $date; }						# store by the gene, value date
    foreach my $gene (sort keys %{ $dateSort{gene} }) {					# foreach of these genes
      push @{ $dateSort{date}{ $dateSort{gene}{$gene} } }, $gene; }			# store by the date, pushing genes with the same date into an array 
    foreach my $date (sort keys %{ $dateSort{date} }) {					# foreach of these dates
      foreach my $gene ( @{ $dateSort{date}{$date} } ) { push @list, $gene; } }		# add the gene to the list
    if ($sort_type eq 'date_desc') { @list = reverse @list; }				# if wanted in descending order, reverse the list
  }
  elsif ( ($sort_type eq '2003_asc') || ($sort_type eq '2003_desc') ) {
    &populateFullyTheHashCdcLocusGene();						# populate theHash to get cds and locus names for row output
    my %last_ver; my @ver_2003; my %ver_2003;
    my $result = $dbh->prepare( "SELECT * FROM car_con_last_verified ORDER BY car_timestamp; ");
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
    while (my @row = $result->fetchrow) { $last_ver{$row[0]} = $row[2]; }
    foreach my $gene (keys %last_ver) { if ($last_ver{$gene} =~ m/2004-06-17/) { push @ver_2003, $gene; } }
    my $ver_2003 = join"', '", @ver_2003;
    $result = $dbh->prepare( "SELECT * FROM cdc_2003_refs WHERE joinkey IN ( '$ver_2003' ) ORDER BY cdc_timestamp DESC; ");
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
    while (my @row = $result->fetchrow) {
      unless ($ver_2003{$row[0]}) { 
        if ($row[1] == 0) { $row[1] = 'zero'; } $ver_2003{$row[0]} = $row[1]; } }
    foreach my $gene (sort {$ver_2003{$a} <=> $ver_2003{$b}} keys %ver_2003) { push @list, $gene; }
    if ($sort_type eq '2003_desc') { @list = reverse @list; }				# if wanted in descending order, reverse the list
  }
  elsif ( ($sort_type eq 'count_asc') || ($sort_type eq 'count_desc') ) {
    &populateFullyTheHashCdcLocusGene();						# populate theHash to get cds and locus names for row output
    my %refCount;									# get the list of ref_reference genes with pmid / cgc data ordered by count of pmids
#       # look at car_con_ref_reference values for ref_count
#     my $result = $dbh->prepare( " SELECT * FROM car_con_ref_reference WHERE joinkey ~ 'WBGene' ORDER BY car_timestamp ; " );
#     $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
#     while (my @row = $result->fetchrow) { $refCount{gene}{$row[0]} = $row[1]; }		# filter through to get only latest values for a given gene
#     foreach my $gene (sort keys %{ $refCount{gene} }) {					# foreach of the genes get the references
#       my @references = split/, /, $refCount{gene}{$gene}; my $ref_count = 0; my $ref_count_cgc = 0;
#       foreach my $reference (@references) {						# foreach of those references
#         if ($reference =~ m/pmid/) { $ref_count++; next; }				# if it's a pmid, add to count
#         if ($reference =~ m/cgc/) { if ($paper_ids{cgc}{$reference}) { $reference = 'WBPaper' .  $paper_ids{cgc}{$reference}; } }	# if it's a cgc, convert to wbpaper
#         if ($reference =~ m/WBPaper/) {							# if it's a wbpaper
#           $reference =~ s/WBPaper//g; 							# take out the wbpaper from the front
#           if ($paper_ids{wbp_pmid}{$reference}) { $ref_count++; }			# add to count if it has a pmid
#           elsif ($paper_ids{wbp_cgc}{$reference}) { $ref_count_cgc++; }			# add to cgc count if it has a cgc
#           else { 1; } } }								# only count cgcs and pmids
#       if ($ref_count_cgc) { $ref_count_cgc *= .0001; $ref_count += $ref_count_cgc; }	# if it has a cgc turn cgc count into a decimal and add to pmid count to give some weight to cgc count
#       push @{ $refCount{count}{$ref_count} }, $gene; }					# store by the count, pushing genes with the same count into an array
      # look at cdc_ref_count for ref_count
    my $result = $dbh->prepare( " SELECT * FROM cdc_ref_count WHERE joinkey ~ 'WBGene' ORDER BY cdc_timestamp ; " );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
    while (my @row = $result->fetchrow) { $refCount{gene}{$row[0]} = $row[1]; }		# filter through to get only latest values for a given gene
    foreach my $gene (sort keys %{ $refCount{gene} }) {					# foreach of the genes get the references
      my $ref_count = 0; my $ref_count_cgc = 0;						# if there's a ref_count in postgres, get pmid and cgc counts
      if ($refCount{gene}{$gene}) { if ($refCount{gene}{$gene} =~ m/^(.*?) \((.*?)\)/) { $ref_count = $1; $ref_count_cgc = $2; } else { $ref_count = $refCount{gene}{$gene}; } }
      if ($ref_count_cgc) { $ref_count_cgc *= .0001; $ref_count += $ref_count_cgc; }	# if it has a cgc turn cgc count into a decimal and add to pmid count to give some weight to cgc count
      push @{ $refCount{count}{$ref_count} }, $gene; }					# store by the count, pushing genes with the same count into an array
    
    foreach my $ref_count (sort { $a <=> $b } keys %{ $refCount{count} }) {		# foreach of these counts
      foreach my $gene ( @{ $refCount{count}{$ref_count} } ) { push @list, $gene; } } 	# add to the gene list
    if ($sort_type eq 'count_desc') { @list = reverse @list; }				# if wanted in descending order, reverse the list
  }
  else {				# search by regex
    my $result = $dbh->prepare( "SELECT * FROM cdc_locus WHERE cdc_locus ~ '$regex' ORDER BY cdc_locus ;" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
    while (my @row = $result->fetchrow) { push @list, $row[0]; $theHash{gene_locus}{$row[0]} = $row[1]; }	# search list of loci
    $result = $dbh->prepare( "SELECT * FROM cdc_cds WHERE cdc_cds ~ '$regex' ORDER BY cdc_cds ;" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
    while (my @row = $result->fetchrow) { push @list, $row[0]; $theHash{gene_cds}{$row[0]} = $row[1]; } 	# search list of cds
  }

  print "<P>List contains " . scalar(@list) . " values.\n";
  
  print "<P>Explanation of table headers :<BR>\n";
  print "Date .- Date last updated based on car_con_last_verified<BR>\n";
  print "Gene .- Three (or four) letter locus, or cds with a link to WormBase page for the corresponding WBGene<BR>\n";
  print "Concise Description .- First 80 characters of the Concise description or ``NOT Curated'' if there is no data.<BR>\n";
  print "Ref # .- References based on aceserver by WBGene.  Number of pmid ( number of cgc ) .<BR>\n";
  print "Ref Since 2003 .- Amount of references since 2003 for Concise Descriptions last updated in 2004-06-17 based on wpa_gene.<BR>\n";
  print "Comment .- Comment based on cdc_comment.<BR>\n";
  print "Grafitti .- Grafitti based on cdc_grafitti.<BR>\n";
  print "Currently .- Currently checked out by this curator, based on cdc_checked_out.<BR>\n";
  print "Checkout .- Click to check Out.  Click to check In.  Puts your wbperson number into cdc_checked_out.<BR>\n";
  print "Link .- An html hyperlink to curated this in the Concise Description Form.<BR>\n";
  print "<P>\n";
  print "<INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Check Out and In !\"> Update postgres values of cdc_checked_out and cdc_grafitti based on your selections.<BR><BR>\n";
  print "<TABLE border = 1>\n";
  print "<TR><TD>Date</TD><TD>Gene</TD><TD>Concise description</TD><TD>Ref #</TD><TD>Ref Since 2003</TD><TD>Comment</TD><TD>Grafitti</TD><TD>Currently</TD><TD>Checkout</TD><TD>Link</TD><TD>Notify</TD></TR>\n";
#   print "<TR><TD>Date Last Updated<BR>based on<BR>car_con_last_verified</TD><TD>Gene</TD><TD>Concise description</TD><TD># References<BR>based on<BR>car_con_ref_reference<BR>pmid (cgc)</TD><TD>Comment<BR>based on<BR>cdc_comment</TD><TD>Grafitti</TD><TD>Currently<BR>Checked<BR>Out</TD><TD>Checkout</TD><TD>Link to<BR>Concise<BR>Form</TD></TR>\n";
#   my $count = 0;
#   foreach my $gene (@list) { &displayRow($gene); $count++; if ($count > 10) { last; } }
  foreach my $gene (@list) { &displayRow($gene); }
  my $gene_list = join"\t", @list;
  print "<INPUT TYPE=\"HIDDEN\" NAME=\"html_value_gene_list\" VALUE=\"$gene_list\">\n";		# pass gene list to query values
  print "<TR><TD>Date</TD><TD>Gene</TD><TD>Concise description</TD><TD>Ref #</TD><TD>Ref Since 2003</TD><TD>Comment</TD><TD>Grafitti</TD><TD>Currently</TD><TD>Checkout</TD><TD>Link</TD><TD>Notify</TD></TR>\n";
#   print "<TR><TD>Date</TD><TD>Gene</TD><TD>Concise description</TD><TD>Ref #</TD><TD>Comment</TD><TD>Grafitti</TD><TD>Currently</TD><TD>Checkout</TD><TD>Link</TD></TR>\n";
  print "</TABLE>\n";
  print "<INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Check Out and In !\"> Update postgres values of cdc_checked_out and cdc_grafitti based on your selections.<BR><BR>\n";
  print "Show list of currently checked out genes <INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Currently Checked Out !\"><BR><BR>\n";
} # sub sortList

sub currentlyCheckedOut {
  &populateWeb();
  &populateCurators();
  my %temp;
  my $result = $dbh->prepare( "SELECT * FROM cdc_checked_out ORDER BY cdc_timestamp;" );	# populate theHash to get cds and locus names for row output
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) { if ($row[1]) { $temp{"$web{$row[0]}{locus}\t($row[0])"} = $curators{two}{$row[1]}; } else { delete $temp{"$web{$row[0]}{locus}\t($row[0])"}; } }
  print "Currently checked out :<BR>\n";
  print "<TABLE>\n";
  foreach my $locus (sort keys %temp) {
    print "<TR><TD>$locus</TD><TD>$temp{$locus}</TD></TR>\n";
  }
  print "</TABLE>\n";
} # sub currentlyCheckedOut 

sub populateFullyTheHashCdcLocusGene {
  my $result = $dbh->prepare( "SELECT * FROM cdc_locus ORDER BY cdc_timestamp;" );	# populate theHash to get cds and locus names for row output
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) { $theHash{gene_locus}{$row[0]} = $row[1]; }
  $result = $dbh->prepare( "SELECT * FROM cdc_cds ORDER BY cdc_timestamp;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) { $theHash{gene_cds}{$row[0]} = $row[1]; }
} # sub populateFullyTheHashCdcLocusGene

sub displayRow {
  my $gene = shift;
  my $date_last_updated = 'No Date';
  my $concise_description = 'NOT Curated';
  my $comment = '&nbsp;';
  my $ref_2003 = '0';
  my $grafitti = '';
  my $checked_out = '&nbsp;';
  my $result = $dbh->prepare( " SELECT car_timestamp FROM car_con_last_verified WHERE joinkey = '$gene' ORDER BY car_timestamp DESC; " );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  my @row = $result->fetchrow; if ($row[0]) { $date_last_updated = $row[0]; $date_last_updated =~ s/:\d\d\.[\d\-]+//g; }
  $result = $dbh->prepare( " SELECT car_con_maindata FROM car_con_maindata WHERE joinkey = '$gene' ORDER BY car_timestamp DESC; " );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  @row = $result->fetchrow; if ($row[0]) { $concise_description = $row[0]; if ($concise_description =~ m/(.{80})./) { $concise_description = $1 . '...'; } }
  my ($ref_count) = &getRefCountPostgres($gene);
  my %notify; $result = $dbh->prepare( " SELECT * FROM gen_notification WHERE joinkey = '$gene' ORDER BY gen_timestamp; " );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) { if ($row[2] eq 'valid') { $notify{$row[1]}++; } else { delete $notify{$row[1]}; } }
  my $notify = '&nbsp;'; my @not = keys %notify; if ($not[0]) { $notify = join", ", @not; }
  $result = $dbh->prepare( " SELECT cdc_2003_refs FROM cdc_2003_refs WHERE joinkey = '$gene' ORDER BY cdc_timestamp DESC; " );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  @row = $result->fetchrow; if ($row[0]) { $ref_2003 = $row[0]; }
  $result = $dbh->prepare( " SELECT cdc_comment FROM cdc_comment WHERE joinkey = '$gene' ORDER BY cdc_timestamp DESC; " );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  @row = $result->fetchrow; if ($row[0]) { $comment = $row[0]; }
  $result = $dbh->prepare( " SELECT cdc_grafitti FROM cdc_grafitti WHERE joinkey = '$gene' ORDER BY cdc_timestamp DESC; " );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  @row = $result->fetchrow; if ($row[0]) { $grafitti = $row[0]; }
  $result = $dbh->prepare( " SELECT cdc_checked_out FROM cdc_checked_out WHERE joinkey = '$gene' ORDER BY cdc_timestamp DESC; " );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  @row = $result->fetchrow; if ($row[0]) { $checked_out = $row[0]; if ($curators{two}{$checked_out}) { $checked_out = $curators{two}{$checked_out}; } }
  print "<TR><TD>$date_last_updated</TD>\n";
  print "<TD>";
  if ($theHash{gene_locus}{$gene}) { print "<A HREF=http://www.wormbase.org/db/gene/gene?name=$gene>$theHash{gene_locus}{$gene}<BR></A>"; }
  if ($theHash{gene_cds}{$gene}) { print "<A HREF=http://www.wormbase.org/db/gene/gene?name=$gene>$theHash{gene_cds}{$gene}<BR></A>"; }
  unless ( ($theHash{gene_cds}{$gene}) || ($theHash{gene_locus}{$gene})) { print "<A HREF=http://www.wormbase.org/db/gene/gene?name=$gene>$gene<BR></A>"; }
  print "</TD>\n";
  print "<TD>$concise_description</TD><TD>$ref_count</TD><TD>$ref_2003</TD><TD>$comment</TD>\n";
  print "<TD><TEXTAREA NAME=\"html_value_grafitti_$gene\" ROWS=3 COLS=40>$grafitti</TEXTAREA></TD>\n";
  print "<TD>$checked_out</TD>\n";
  print "<TD><INPUT NAME=\"html_box_out_$gene\" TYPE=\"checkbox\" VALUE=\"yes\">Out<BR><INPUT NAME=\"html_box_in_$gene\" TYPE=\"checkbox\" VALUE=\"yes\">In</TD>\n";
  print "<TD><A HREF=\"http://tazendra.caltech.edu/~postgres/cgi-bin/concise_description_new.cgi?action=Query+%21&html_value_gene=$gene&curator_name=$theHash{curator}\">Link</A></TD>\n";
  print "<TD><A HREF=\"http://tazendra.caltech.edu/~postgres/cgi-bin/concise_description_checkout.cgi?action=Notify+%21&html_value_gene=$gene&curator_name=$theHash{curator}\">Add me to Notify list</A><BR>$notify</TD>\n";
  print "</TR>\n";
} # sub displayRow

sub getRefCountConcise {			# get count values based on concise description's car_con_ref_reference
  my $gene = shift; my $ref_count = 0; my $ref_count_cgc = 0; my @references = ();
  my $result = $dbh->prepare( " SELECT car_con_ref_reference FROM car_con_ref_reference WHERE joinkey = '$gene' ORDER BY car_timestamp DESC; " );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  my @row = $result->fetchrow; if ($row[0]) { @references = split/, /, $row[0]; }
  foreach my $reference (@references) {
    if ($reference =~ m/pmid/) { $ref_count++; next; }
    if ($reference =~ m/cgc/) { if ($paper_ids{cgc}{$reference}) { $reference = 'WBPaper' .  $paper_ids{cgc}{$reference}; } }
    if ($reference =~ m/WBPaper/) {
      $reference =~ s/WBPaper//g; 
      if ($paper_ids{wbp_pmid}{$reference}) { $ref_count++; }
      elsif ($paper_ids{wbp_cgc}{$reference}) { $ref_count_cgc++; }
      else { 1; } } }			# only count cgcs and pmids
  if ($ref_count_cgc) { $ref_count .= ' (' . $ref_count_cgc . ')'; }
  if ($ref_count) { return $ref_count; }
} # sub getRefCountConcise

sub getRefCountPostgres {			# get count based on postgres values which are based on aceserver values
  my $gene = shift; my $ref_count = 0;
  my $result = $dbh->prepare( "SELECT cdc_ref_count FROM cdc_ref_count WHERE joinkey = '$gene' ORDER BY cdc_timestamp DESC; " );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  my @row = $result->fetchrow; if ($row[0]) { $ref_count = $row[0]; }
  return $ref_count;
} # sub getRefCountPostgres

# sub populateIdentifiers {
#   my $result = $dbh->prepare( "SELECT * FROM wpa_identifier ORDER BY wpa_timestamp;" ); 
#   $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
#   while (my @row = $result->fetchrow) { 
#     if ($row[3] eq 'valid') { 
#         if ($row[1] =~ m/pmid/) { $paper_ids{pmid}{$row[1]} = $row[0]; $paper_ids{wbp_pmid}{$row[0]} = $row[1]; }
#         elsif ($row[1] =~ m/cgc/) { $paper_ids{cgc}{$row[1]} = $row[0]; $paper_ids{wbp_cgc}{$row[0]} = $row[1]; }
#         else { 1; } }			# only read in cgcs and pmid 
#       else {
#         if ($row[1] =~ m/pmid/) { delete $paper_ids{pmid}{$row[1]}; delete $paper_ids{wbp_pmid}{$row[0]}; }
#         elsif ($row[1] =~ m/cgc/) { delete $paper_ids{cgc}{$row[1]}; delete $paper_ids{wbp_cgc}{$row[0]}; }
#         else { 1; } }			# only read in cgcs and pmid 
#   } # while (my @row = $result->fetchrow) 
# } # sub populateIdentifiers

sub populateIdentifiers {
  my $result = $dbh->prepare( "SELECT * FROM pap_identifier ;" ); 
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) { 
        if ($row[1] =~ m/pmid/) { $paper_ids{pmid}{$row[1]} = $row[0]; $paper_ids{wbp_pmid}{$row[0]} = $row[1]; }
        elsif ($row[1] =~ m/cgc/) { $paper_ids{cgc}{$row[1]} = $row[0]; $paper_ids{wbp_cgc}{$row[0]} = $row[1]; }
        else { 1; } 			# only read in cgcs and pmid 
  } # while (my @row = $result->fetchrow) 
} # sub populateIdentifiers

sub populateCurators {
  my $result = $dbh->prepare( "SELECT * FROM two_standardname; " );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
    $curators{two}{$row[0]} = $row[2];
    $curators{std}{$row[2]} = $row[0]; 
  } # while (my @row = $result->fetchrow)
} # sub populateCurators

sub firstPage {
  my $date = &getDate();
  print "Value : $date<BR>\n";
  print "<FORM NAME='form1' METHOD=\"POST\" ACTION=\"http://tazendra.caltech.edu/~postgres/cgi-bin/concise_description_checkout.cgi\">\n";
  print "<TABLE>\n";
  print "<TR><TD>Select your Name among : </TD><TD><SELECT NAME=\"curator_name\" SIZE=7>\n";
#   print "<OPTION>Igor Antoshechkin</OPTION>\n";
#   print "<OPTION>Carol Bastiani</OPTION>\n";
  print "<OPTION>Juancarlos Chan</OPTION>\n";
#   print "<OPTION>Wen Chen</OPTION>\n";
  print "<OPTION>Snehalata Kadam</OPTION>\n";
#   print "<OPTION>Eimear Kenny</OPTION>\n";
  print "<OPTION>Ranjana Kishore</OPTION>\n";
#   print "<OPTION>Raymond Lee</OPTION>\n";
#   print "<OPTION>Cecilia Nakamura</OPTION>\n";
#   print "<OPTION>Andrei Petcherski</OPTION>\n";
#   print "<OPTION>Tuco</OPTION>\n";
  print "<OPTION>Gary C. Schindelman</OPTION>\n";
  print "<OPTION>Erich Schwarz</OPTION>\n";
#   print "<OPTION>Paul Sternberg</OPTION>\n";
#   print "<OPTION>Theresa Stiernagle</OPTION>\n";
#   print "<OPTION>Mary Ann Tuli</OPTION>\n";
  print "<OPTION>Kimberly Van Auken</OPTION>\n";
#   print "<OPTION>Qinghua Wang</OPTION>\n";
  print "<OPTION>Karen Yook</OPTION>\n";
#   print "<OPTION>Andrei Testing</OPTION>\n";
#   print "<OPTION>Juancarlos Testing</OPTION>\n";	# Not a valid two_standardname so won't work
  print "</SELECT></TD>\n";
  print "<TD><INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Curator !\"></TD></TR><BR><BR>\n";
  print "</TABLE>\n";
  print "</FORM>\n";
  print "</TABLE>\n";
} # sub firstPage


sub pickNumber {
  my ($oop, $number) = &getHtmlVar($query, 'number');
  unless ($number) { $number = 1; }	# sometimes no number or zero would cause a serverlog error on next line
  print "<INPUT TYPE=\"HIDDEN\" NAME=\"number\" VALUE=\"$number\">\n"; 		# pass number in case want to toggle to Show Valid or Show History
  print "NUMBER : $number\n";
  if ($number =~ m/^0+/) { $number =~ s/^0+//g; }
} # sub pickNumber


sub filterForPostgres {			# filter values for postgres
  my $value = shift;
  $value =~ s/\'/\\\'/g;
  return $value;
} # sub filterForPostgres



__END__

# DEPRECATED

sub getRefCountAceserver {			# get count values based on aceserver on the fly
  my $gene = shift; my $ref_count = 0; my $ref_count_cgc = 0;
  my $query = "find Gene $gene";
  my @gene = $db->fetch(-query=>$query);
  if ($gene[0]) { 
    my (@references) = $gene[0]->Reference;
    if ($references[0]) { 
      foreach my $reference (@references) {
        $reference =~ s/WBPaper//g; 
        if ($paper_ids{wbp_pmid}{$reference}) { $ref_count++; }
        elsif ($paper_ids{wbp_cgc}{$reference}) { $ref_count_cgc++; }
        else { 1; } } } }			# only count cgcs and pmids
  if ($ref_count_cgc) { $ref_count .= ' (' . $ref_count_cgc . ')'; }
  return $ref_count;
} # sub getRefCountAceserver

