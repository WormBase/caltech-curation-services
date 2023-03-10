#!/usr/bin/perl

# update the genes2mol file from sanger's nameserver and populate the postgres
# table gin_locus based on it.  only store the loci, the sequences / what not
# come from the aceserver instead in the other script.  for Kimberly  2006 12 18
#
# cronjob set to update every day at 2am.  2007 01 23
# 0 2 * * * /home/azurebrd/public_html/sanger/gene_postgres/populate_gin_locus.pl
#
# cronjob was failing a lot, changed to run at 2pm and hope for the best.  2007 04 25
#
# get wbgene list from here too.  2008 05 31
#
# Converted from Pg.pm to DBI.pm  2009 04 17
# 
# updated to get data from nameserver JSON data here :
# http://www.sanger.ac.uk/cgi-bin/Projects/C_elegans/nameserver_json.pl?domain=Gene
# and to update  gin_seqname  and  gin_dead  as well as  gin_locus  and  gin_wbgene
# do full wipes and repopulates, except for  gin_dead  which has the merged / split
# data need to come from WS, so only make changes to it.  
# changed the cronjob back to 3am  2010 08 03
#
# keeps timing out at 3am, changed to 9am.  2010 08 08
#
# still times out, changed to remove the $ua->timeout(10) line, and using
# $url, HTTP::Request, and $ua->request  back to 3am
# Also, populating  gin_dead  completely and will move merge and split into
# gin_history.  2010 08 09
#
# 0 3 * * * /home/azurebrd/public_html/sanger/gene_postgres/populate_gin_locus.pl
# transfered to acedb account.  2011 06 03
#
# compare loci added to previous gin_locus value, if different and previous locus
# not in gin_synonyms, add to gin_synonyms.  To avoid problem of locus names being
# obsolete but not updated until the next WS.  Karen's idea, for Xiaodong's problem
# with Kimberly's oversight (sort of).  2011 07 28
#
# keep track of dead status in gin_dead in %dead_in_pg  when updating gin_dead 
# information put back that message if it existed.  always add to gin_wbgene even
# if it's a Public_name type of entry.  Only update postgres if the nameserver gene
# file has changed.  2011 12 13
#
# %pg_locus{$joinkey} was always getting move to gin_synonyms, possibly even when
# there was no value, creating blank synonyms for WBGenes, which was adding a lot of
# blank WBGenes for Inferred_automatically.  2012 03 01
# 
# moved to :
# 0 3 * * * /home/acedb/cron/populate_gin_locus.pl
# 
# updated to work off of both the nameserver nightly dump (need new ftp URL), and the 
# nightly geneace dump to get synonyms and suppressed/merged/split status.  2013 10 18
# 
# renamed to populate_gin_nightly.pl  documented, still not live on tazendra.  2013 10 21
#
# gets called by cronjob
# 0 20 * * * /home/postgres/work/pgpopulation/obo_oa_ontologies/update_obo_oa_ontologies.pl
# live on tazendra.  2013 10 25
#
# new ftp URL from Michael Paulini  2013 02 06
#
# added gin_species getting data from genes.ace.gz for Kimberly and Ranjana  2015 04 02
#
# Updated to work off of NS2 dump from Matt and Sibyl.  2019 08 31


# gets called by cronjob
# 0 20 * * * /home/postgres/work/pgpopulation/obo_oa_ontologies/update_obo_oa_ontologies.pl


use strict;
use diagnostics;
use Jex;
# use Pg;
use DBI;
use LWP::UserAgent;
use LWP::Simple;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

# track synonyms and loci in postgres to see if nameserver locus changed, in which case add to synonym.
my %pg_syns; my %pg_locus;
$result = $dbh->prepare( "SELECT * FROM gin_synonyms" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) { $pg_syns{$row[0]}{$row[1]} = $row[3]; }	# keep timestamp for repopulating gin_synonyms based on old values
$result = $dbh->prepare( "SELECT * FROM gin_locus" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) { $pg_locus{$row[0]} = $row[1]; }


# my $directory = '/home/azurebrd/public_html/sanger/gene_postgres';
# my $directory = '/home/acedb/cron';
my $directory = '/home/postgres/work/pgpopulation/obo_oa_ontologies/geneace/datomicNightly';
chdir($directory) or die "Cannot go to $directory ($!)";

# my $timestamp = &getPgDate();
my $timestamp = '2019-08-30 20:01:37';


my $ua = LWP::UserAgent->new;
# $ua->timeout(10);	# maybe this is causing timeout on cronjob
# $ua->env_proxy;

# my $response = $ua->get("http://www.sanger.ac.uk/tmp/Projects/C_elegans/LOCI/genes2molecularnamestest.txt");
# my $response = $ua->get("http://www.sanger.ac.uk/cgi-bin/Projects/C_elegans/nameserver_json.pl?domain=Gene");
# my $url = "http://www.sanger.ac.uk/cgi-bin/Projects/C_elegans/nameserver_json.pl?domain=Gene";
# my $url = "ftp://ftp.sanger.ac.uk/pub2/wormbase/STAFF/mh6/nightly_geneace/genes.json";
# my $url = "ftp://ftp.sanger.ac.uk/pub/consortia/wormbase/STAFF/mh6/nightly_geneace/genes.json";

my $url = "http://mangolassi.caltech.edu/~azurebrd/var/work/genes.csv";
my $request = HTTP::Request->new(GET => $url);	#grabs url
my $response = $ua->request($request);		#checks url, dies if not valid.

# my $response = $ua->get("http://tazendra.caltech.edu/~azurebrd/sanger/gene_postgres/nameserverGene");
my $sanger = '';
if ($response->is_success) { $sanger = $response->content; $sanger .= "\n"; }
  else { die $response->status_line; }

my @pgcommands;

my $hinxton_files_dir = '/home/postgres/work/pgpopulation/obo_oa_ontologies/geneace/datomicNightly/';

my $wbgenefile   = $hinxton_files_dir . 'gin_wbgene.pg';
my $locusfile    = $hinxton_files_dir . 'gin_locus.pg';
my $synonymsfile = $hinxton_files_dir . 'gin_synonyms.pg';
my $seqnamefile  = $hinxton_files_dir . 'gin_seqname.pg';
my $deadfile     = $hinxton_files_dir . 'gin_dead.pg';
my $speciesfile  = $hinxton_files_dir . 'gin_species.pg';
open (WBG, ">$wbgenefile")   or die "Cannot create $wbgenefile : $!";
open (LOC, ">$locusfile")    or die "Cannot create $locusfile : $!";
open (SYN, ">$synonymsfile") or die "Cannot create $synonymsfile : $!";
open (SEQ, ">$seqnamefile")  or die "Cannot create $seqnamefile : $!";
open (DEA, ">$deadfile")     or die "Cannot create $deadfile : $!";
open (SPE, ">$speciesfile")  or die "Cannot create $speciesfile : $!";

my %wbgene; my %synonyms; my %locus; my %seqname; my %dead; my %species;

my (@entries) = split/\n/, $sanger;
foreach my $entry (@entries) {
  next unless ($entry =~ m/^WBGene/);
  my ($wbg, $cgc, $seq, $status, $type) = split/,/, $entry;
  my ($joinkey) = $wbg =~ m/WBGene(\d+)/;
  $wbgene{$joinkey} = "WBGene$joinkey";				# always add the wbgene in case it has merged/split even if it doesn't have a valid type
  if ($cgc) { $locus{$joinkey} = $cgc; }
  if ($seq) { $seqname{$joinkey}{$seq}++; }
  if ($status) {
    if ($status eq 'dead') {
      $dead{$joinkey}{"Dead"}++; }
    if ($status eq 'suppressed') { 
      $dead{$joinkey}{"Dead"}++;
      $dead{$joinkey}{"Suppressed"}++; }
  } # if ($status)
} # foreach my $entry (@entries)

# my (@entries) = split/\n   \],\n   \[\n/, $sanger;
# foreach my $entry (@entries) {
#   my ($gene, $type, $value, $dead) = $entry =~ m/\"([^\"]+)\"/g;
#   my ($joinkey) = $gene =~ m/WBGene(\d+)/;
#   $wbgene{$joinkey} = "WBGene$joinkey";				# always add the wbgene in case it has merged/split even if it doesn't have a valid type
# #   if ($type eq 'CGC') { $gene{$joinkey}{locus} = $value; $locus{$joinkey}{$value}++; }
# #   elsif ($type eq 'Sequence') { $gene{$joinkey}{seqname} = $value; $seqname{$joinkey}{$value}++; }
# #   elsif ($type eq 'Public_name') { $gene{$joinkey}{wbgene} = $value; }	# store wbgene only, not name
#   if ($type eq 'CGC') { $locus{$joinkey} = $value; }
#   elsif ($type eq 'Sequence') { $seqname{$joinkey}{$value}++; }
#   unless ($dead) { $dead = 0; }
#   if ($dead == 0) { $dead{$joinkey}{"Dead"}++; }
# #   print "G $gene T $type V $value D $dead E\n";
# } # foreach my $entry (@entries)
 
 
foreach my $joinkey (sort keys %wbgene) {
  if ($locus{$joinkey}) {
    if ($pg_locus{$joinkey}) {						# if there is an old locus value to transfer
      if ($pg_locus{$joinkey} ne $locus{$joinkey}) {			# if the old locus is different from the new locus
        unless ($pg_syns{$joinkey}{$pg_locus{$joinkey}}) {		# and the old locus is not already a synonym
          $synonyms{$joinkey}{$pg_locus{$joinkey}}++;			# add to list of new synonyms to add
      } } }	# add old locus to synonyms
  }
} # foreach my $joinkey (sort keys %wbgene)


# my $geneace_genes_file = 'ftp://ftp.sanger.ac.uk/pub2/wormbase/STAFF/mh6/nightly_geneace/genes.ace.gz';
my $geneace_genes_file = 'ftp://ftp.sanger.ac.uk/pub/consortia/wormbase/STAFF/mh6/nightly_geneace/genes.ace.gz';
my $ftpdata = get $geneace_genes_file;                               # this automatically gunzips the file, doesn't need UserAgent
(@entries) = split/\n\n/, $ftpdata;
foreach my $entry (@entries) {
  my ($joinkey) = $entry =~ m/Gene : \"WBGene(\d+)\"/;
  next unless ($joinkey);
#   my $suppressed = ''; if ($entry =~ m/Suppressed/) { $dead{$joinkey}{"Suppressed"}++; }	# always get Suppressed tag if it exists
  if ($entry =~ m/Other_name\s+\"(.*?)\"/) {				# get synonyms from Other_name tag
    my (@syns) = $entry =~ m/Other_name\s+\"(.*?)\"/g;
    foreach my $syn (@syns) { 
      $syn =~ s|\\/|/|g;						# forward slashes are backslashed in the file, so remove the leading backslash
      unless ($pg_syns{$joinkey}{$syn}) {				# if it's not in the postgres list, add to list of synonyms to add
        $synonyms{$joinkey}{$syn}++; } } }
  if ($dead{$joinkey}{"Dead"}) {					# only record merged and split if Dead in nameserver
    if ($entry =~ m/Split_into\s+\"(WBGene.*?)\"/) {
      my (@split) = $entry =~ m/Split_into\s+\"(.*?)\"/g;
      foreach my $split (@split) { $dead{$joinkey}{"split_into $split"}++; } }
    if ($entry =~ m/Merged_into\s+\"(WBGene.*?)\"/) {
      if ($pg_syns{$joinkey}) { delete $pg_syns{$joinkey}; }		# if dead in nameserver and merged in geneace, remove all synonyms, for Kimberly 2013 10 21
      my (@split) = $entry =~ m/Merged_into\s+\"(.*?)\"/g;
      foreach my $split (@split) { $dead{$joinkey}{"merged_into $split"}++; } } }
  if ($entry =~ m/Species\s+"(.*?)"/) { $species{$joinkey} = $1; 
}
} # foreach my $entry (@entries)



foreach my $joinkey (sort keys %wbgene) {
  my $value = $wbgene{$joinkey};
  print WBG qq($joinkey\t$value\t$timestamp\n); }

foreach my $joinkey (sort keys %locus) { 
  print LOC qq($joinkey\t$locus{$joinkey}\t$timestamp\n); }

foreach my $joinkey (sort keys %pg_syns) { 
  foreach my $synonym (sort keys %{ $pg_syns{$joinkey} }) { 
    my $pgtimestamp = $pg_syns{$joinkey}{$synonym};
    my $syntype = 'other';
    if ($synonym =~ m/\w{3,4}\-\d+/) { $syntype = 'locus'; }
    print SYN qq($joinkey\t$synonym\t$syntype\t$pgtimestamp\n); } }

foreach my $joinkey (sort keys %synonyms) { 
  foreach my $synonym (sort keys %{ $synonyms{$joinkey} }) {
    my $syntype = 'other';
    if ($synonym =~ m/\w{3,4}\-\d+/) { $syntype = 'locus'; }
    print SYN qq($joinkey\t$synonym\t$syntype\t$timestamp\n); } }

foreach my $joinkey (sort keys %seqname) { 
  foreach my $seqname (sort keys %{ $seqname{$joinkey} }) {
    print SEQ qq($joinkey\t$seqname\t$timestamp\n); } }

foreach my $joinkey (sort keys %dead) { 
  my $dead = join", ", sort keys %{ $dead{$joinkey} };
  if ($dead) {
    print DEA qq($joinkey\t$dead\t$timestamp\n); } }

foreach my $joinkey (sort keys %species) { 
  print SPE qq($joinkey\t$species{$joinkey}\t$timestamp\n); }

close (WBG) or die "Cannot close $wbgenefile : $!";
close (LOC) or die "Cannot close $locusfile : $!";
close (SYN) or die "Cannot close $synonymsfile : $!";
close (SEQ) or die "Cannot close $seqnamefile : $!";
close (DEA) or die "Cannot close $deadfile : $!";
close (SPE) or die "Cannot close $speciesfile : $!";

if (scalar(keys %wbgene) > 20000) {	# if there are 20000 (arbitrary from Kimberly) genes, wipe and repopulate
  push @pgcommands, qq(DELETE FROM gin_wbgene;);
  push @pgcommands, qq(DELETE FROM gin_locus;);
  push @pgcommands, qq(DELETE FROM gin_synonyms;);
  push @pgcommands, qq(DELETE FROM gin_seqname;);
  push @pgcommands, qq(DELETE FROM gin_dead;);
  push @pgcommands, qq(DELETE FROM gin_species;);
  push @pgcommands, qq(COPY gin_wbgene   FROM '$wbgenefile';);
  push @pgcommands, qq(COPY gin_locus    FROM '$locusfile';);
  push @pgcommands, qq(COPY gin_synonyms FROM '$synonymsfile';);
  push @pgcommands, qq(COPY gin_seqname  FROM '$seqnamefile';);
  push @pgcommands, qq(COPY gin_dead     FROM '$deadfile';);
  push @pgcommands, qq(COPY gin_species  FROM '$speciesfile';);
  foreach my $pgcommand (@pgcommands) {
#     print "$pgcommand\n";
# UNCOMMENT TO MAKE LIVE
#     my $result = $dbh->do( $pgcommand );
  }
# UNCOMMENT TO MAKE LIVE
# } else {
#   my $user = 'populate_gin_datomic.pl';
#   my $email = 'vanauken@its.caltech.edu';
# #   my $email = 'azurebrd@tazendra.caltech.edu';
#   my $subject = 'populate_gin_datomic.pl did not have enough genes';
#   my $body = "populate_gin_datomic.pl was not updated";
#   &mailer($user, $email, $subject, $body);
}

__END__
