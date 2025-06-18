#!/usr/bin/env perl

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
# Removed mh6/ from path for Paul Davis.  2020 06 11
#
# Updated to no longer get genes.json, instead get directly from nameserver with aws and
# get_nameserver_genes.sh   2020 07 02
#
# Got new wb-names-export.jar, updated to have species.  2020 07 03
#
# Getting genes from nameserver directly broke 2023 03 19 when aws keys were committed to github
# Paulo added a cronjob to generate genes.csv into s3 on 2023 06 23 and can now
# wget http://namesoutput.s3-website-us-east-1.amazonaws.com/genes.csv
# 2023 06 23
#
# This was dockerized when tazendra switched, but was never connected in
# /usr/lib/scripts/pgpopulation/obo_oa_ontologies/update_obo_oa_ontologies.pl until now.
# 2025 06 17


# gets called by cronjob
# 0 20 * * * /usr/lib/scripts/pgpopulation/obo_oa_ontologies/update_obo_oa_ontologies.pl


use strict;
use diagnostics;
use Jex;
# use Pg;
use DBI;
use LWP::UserAgent;
use LWP::Simple;
use Dotenv -load => '/usr/lib/.env';

my $dbh = DBI->connect ( "dbi:Pg:dbname=$ENV{PSQL_DATABASE};host=$ENV{PSQL_HOST};port=$ENV{PSQL_PORT}", "$ENV{PSQL_USERNAME}", "$ENV{PSQL_PASSWORD}") or die "Cannot connect to database!\n";
# my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
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
# my $directory = '/home/postgres/work/pgpopulation/obo_oa_ontologies/geneace';
my $directory =  $ENV{CALTECH_CURATION_FILES_INTERNAL_PATH} . '/cronjobs/obo_oa_ontologies/geneace/';
chdir($directory) or die "Cannot go to $directory ($!)";
print qq(DIR $directory DIR\n);

my $timestamp = &getPgDate();


my %wbgene; my %synonyms; my %locus; my %seqname; my %dead; my %species;
my @pgcommands;

# my $hinxton_files_dir = '/home/postgres/work/pgpopulation/obo_oa_ontologies/geneace/';
my $hinxton_files_dir = $ENV{CALTECH_CURATION_FILES_INTERNAL_PATH} . '/cronjobs/obo_oa_ontologies/geneace/';

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


# get genes from nameserver
# `/home/postgres/work/pgpopulation/obo_oa_ontologies/geneace/get_nameserver_genes.sh`;	# this broke 2023 03 19 when aws keys were committed to github
`rm genes.csv`;		# wget will make a .1 file if not removing the previous file
`wget http://namesoutput.s3-website-us-east-1.amazonaws.com/genes.csv`;	# paulo added a cronjob to generate into s3 on 2023 06 23


# get genes from .json dump that's no longer happening  2020 07 02
# my $ua = LWP::UserAgent->new;
# # $ua->timeout(10);	# maybe this is causing timeout on cronjob
# # $ua->env_proxy;
# 
# # my $response = $ua->get("http://www.sanger.ac.uk/tmp/Projects/C_elegans/LOCI/genes2molecularnamestest.txt");
# # my $response = $ua->get("http://www.sanger.ac.uk/cgi-bin/Projects/C_elegans/nameserver_json.pl?domain=Gene");
# # my $url = "http://www.sanger.ac.uk/cgi-bin/Projects/C_elegans/nameserver_json.pl?domain=Gene";
# # my $url = "ftp://ftp.sanger.ac.uk/pub2/wormbase/STAFF/mh6/nightly_geneace/genes.json";
# # my $url = "ftp://ftp.sanger.ac.uk/pub/consortia/wormbase/STAFF/mh6/nightly_geneace/genes.json";
# my $url = "ftp://ftp.sanger.ac.uk/pub/consortia/wormbase/STAFF/nightly_geneace/genes.json";
# my $request = HTTP::Request->new(GET => $url);	#grabs url
# my $response = $ua->request($request);		#checks url, dies if not valid.
# 
# # my $response = $ua->get("http://tazendra.caltech.edu/~azurebrd/sanger/gene_postgres/nameserverGene");
# my $sanger = '';
# if ($response->is_success) { $sanger = $response->content; $sanger .= "\n"; }
#   else { die $response->status_line; }
# 
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

my $infile = $hinxton_files_dir . 'genes.csv';
open (IN, "<$infile") or die "Cannot open $infile : $!";
my $skip_header = <IN>;
while (my $line = <IN>) {
  chomp $line;
  my ($gene, $locus, $sequence, $dead_live_suppressed, $biotype, $species) = split/,/, $line;
  my ($joinkey) = $gene =~ m/WBGene(\d+)/;
  $wbgene{$joinkey} = "WBGene$joinkey";	
  if ($locus) { $locus{$joinkey} = $locus; }
  if ($sequence) { $seqname{$joinkey}{$sequence}++; }
  if ($species) { $species{$joinkey} = $species; }
  if ($dead_live_suppressed) {
    if ($dead_live_suppressed eq 'dead') { $dead{$joinkey}{"Dead"}++; }
    elsif ($dead_live_suppressed eq 'suppressed') { $dead{$joinkey}{"Suppressed"}++; } }
} # while (my $line = <IN>)
close (IN) or die "Cannot close $infile : $!";

foreach my $joinkey (sort keys %wbgene) {
#   $wbgene{$joinkey} = "WBGene$joinkey";			# this used to only happen once if it's any of the 3 valid types, but we want it for all genes in case they have merged/split info
#   push @pgcommands, "INSERT INTO gin_wbgene VALUES ('$joinkey', 'WBGene$joinkey')";
  if ($locus{$joinkey}) {
    if ($pg_locus{$joinkey}) {						# if there is an old locus value to transfer
      if ($pg_locus{$joinkey} ne $locus{$joinkey}) {			# if the old locus is different from the new locus
        unless ($pg_syns{$joinkey}{$pg_locus{$joinkey}}) {		# and the old locus is not already a synonym
          $synonyms{$joinkey}{$pg_locus{$joinkey}}++;			# add to list of new synonyms to add
#           push @pgcommands, "INSERT INTO gin_synonyms VALUES ('$joinkey', '$pg_locus{$joinkey}')";
      } } }	# add old locus to synonyms
#     push @pgcommands, "INSERT INTO gin_locus VALUES ('$joinkey', '$gene{$joinkey}{locus}')"; 
  }
#   if ($gene{$joinkey}{seqname}) { push @pgcommands, "INSERT INTO gin_seqname VALUES ('$joinkey', '$gene{$joinkey}{seqname}')"; }
#   if ($gene{$joinkey}{dead}) { push @pgcommands, "INSERT INTO gin_dead VALUES ('$joinkey', '$gene{$joinkey}{dead}')"; }
} # foreach my $joinkey (sort keys %wbgene)


# my $geneace_genes_file = 'ftp://ftp.sanger.ac.uk/pub2/wormbase/STAFF/mh6/nightly_geneace/genes.ace.gz';
# my $geneace_genes_file = 'ftp://ftp.sanger.ac.uk/pub/consortia/wormbase/STAFF/mh6/nightly_geneace/genes.ace.gz';
# my $geneace_genes_file = 'ftp://ftp.sanger.ac.uk/pub/consortia/wormbase/STAFF/nightly_geneace/genes.ace.gz';	# obsolete 2021 01 25 by Paul Davis
my $geneace_genes_file = 'ftp://ftp.ebi.ac.uk/pub/databases/wormbase/STAFF/nightly_geneace/genes.ace.gz';	# updated 2021 01 25 by Paul Davis
my $ftpdata = get $geneace_genes_file;                               # this automatically gunzips the file, doesn't need UserAgent
my (@entries) = split/\n\n/, $ftpdata;
foreach my $entry (@entries) {
  my ($joinkey) = $entry =~ m/Gene : \"WBGene(\d+)\"/;
  next unless $joinkey;
#   my $suppressed = ''; if ($entry =~ m/Suppressed/) { $dead{$joinkey}{"Suppressed"}++; }	# always get Suppressed tag if it exists	# now coming from genes.csv
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
#   if ($entry =~ m/Species\s+"(.*?)"/) { $species{$joinkey} = $1; }	# now coming from genes.csv
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

# my $count = scalar(keys %wbgene);
# print qq(GENE COUNT $count C\n);

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
    my $result = $dbh->do( $pgcommand );
  }
} else {
  my $user = 'populate_gin_nightly.pl';
  my $email = 'vanauken@its.caltech.edu';
#   my $email = 'azurebrd@tazendra.caltech.edu';
  my $subject = 'populate_gin_nightly.pl did not have enough genes';
  my $body = "populate_gin_nightly.pl was not updated";
  &mailer($user, $email, $subject, $body);
}

__END__

# this was to only process if the nameserver file was new.  Since we're processing from nameserver + geneace dump, we'll assume there's always a change, and since we're doing this from postgres account by wiping and copying the postgres table, it's fast enough not to matter too much.  2013 10 18
# my $nameserverGeneFile = $directory . '/nameserverGene.txt';
# $/ = undef;
# open (IN, "<$nameserverGeneFile") or die "Cannot open $nameserverGeneFile : $!";
# my $lastFileContent = <IN>;
# close (IN) or die "Cannot close $nameserverGeneFile : $!";
# $/ = "\n";
# if ($lastFileContent eq $sanger) { exit 1; }	# last downloaded file is the same, don't do anything
# open (OUT, ">$nameserverGeneFile") or die "Cannot open $nameserverGeneFile : $!";
# print OUT $sanger; 
# close (OUT) or die "Cannot close $nameserverGeneFile : $!";


G WBGene00023220 T Sequence V ZK994.t1 D 1 E
G WBGene00023221 T Sequence V ZK994.t2 D 1 E
G WBGene00023222 T Sequence V ZK994.t3 D 1 E
G WBGene00006987 T CGC V zmp-1 D 1 E
G WBGene00013683 T CGC V zoo-1 D 1 E



my (@text) = split/./, $sanger;
my $textsize = scalar(@text);
if ( ($textsize < 10000) || ($sanger =~ m/Error 404/) ) {
    my $user = 'populate_gin_locus.pl';
    my $email = 'vanauken@its.caltech.edu';
#     my $email = 'azurebrd@tazendra.caltech.edu';
    my $subject = 'didn\'t update sanger file because of small file size';
    if ($sanger =~ m/Error 404/) { $subject = 'didn\'t update sanger file because file was not found'; }
    my $body = "genes2molecular_names.txt only has $textsize characters";
    &mailer($user, $email, $subject, $body); }

  else {  
#   my $start = &getSimpleSecDate();
    my $outfile = $directory . '/genes2molecular_names.txt';
    open (OUT, ">$outfile") or die "Cannot open $outfile : $!";
    print OUT "$sanger\n"; 
    close (OUT) or die "Cannot close $outfile : $!";

    $outfile = $directory . '/old/sanger_genes2molecular_names.txt.' . $start;
    open (OUT, ">$outfile") or die "Cannot open $outfile : $!";
    print OUT "$sanger\n"; 
    close (OUT) or die "Cannot close $outfile : $!"; 

    $outfile = $directory . '/old/' . 'gin_locus.' . $start . '.pg';
    open (PG, ">$outfile") or die "Cannot create $outfile : $!";
    print PG "-- $start\n\n";

    my $result = $dbh->do( "DELETE FROM gin_locus;" );
    $result = $dbh->do( "DELETE FROM gin_wbgene;" );
    my (@lines) = split/\n/, $sanger;
    foreach my $line (@lines) {
      next unless $line;
      my ($wbg, $loc, $junk) = split/\t/, $line;
      unless ($loc) { print PG "ERR NO locus $line\n"; next; }
      my ($joinkey) = $wbg =~ m/(\d+)/;
      my $command = "INSERT INTO gin_wbgene VALUES ('$joinkey', '$wbg');";
      print PG "$command\n";
      my $result = $dbh->do( $command );
      if ($loc =~ m/\w{3,4}\-\d+/) {
        my $command = "INSERT INTO gin_locus VALUES ('$joinkey', '$loc');";
        print PG "$command\n";
        my $result = $dbh->do( $command );
      }
    } # foreach my $line (@lines)
    my $end = &getSimpleSecDate();
    print PG "\n-- $end\n";
    close (PG) or die "Cannot create $outfile : $!";
}

