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

# moved to :
# 0 3 * * * /home/acedb/cron/populate_gin_locus.pl




use strict;
use diagnostics;
use Jex;
# use Pg;
use DBI;
use LWP::UserAgent;

# my $conn = Pg::connectdb("dbname=testdb");
# die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

# use constant HOST => $ENV{ACEDB_HOST} || 'aceserver.cshl.org';
# use constant PORT => $ENV{ACEDB_PORT} || 2005;

my %dead_in_pg;
my $result = $dbh->prepare( "SELECT * FROM gin_dead" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) { $dead_in_pg{$row[0]} = $row[1]; }

my %pg_syns; my %pg_locus;
$result = $dbh->prepare( "SELECT * FROM gin_synonyms" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) { $pg_syns{$row[0]}{$row[1]}++; }
$result = $dbh->prepare( "SELECT * FROM gin_locus" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) { $pg_locus{$row[0]} = $row[1]; }


# my $directory = '/home/azurebrd/public_html/sanger/gene_postgres';
my $directory = '/home/acedb/cron';
chdir($directory) or die "Cannot go to $directory ($!)";

my $start = &getSimpleSecDate();


my $ua = LWP::UserAgent->new;
# $ua->timeout(10);	# maybe this is causing timeout on cronjob
# $ua->env_proxy;

# my $response = $ua->get("http://www.sanger.ac.uk/tmp/Projects/C_elegans/LOCI/genes2molecularnamestest.txt");
# my $response = $ua->get("http://www.sanger.ac.uk/cgi-bin/Projects/C_elegans/nameserver_json.pl?domain=Gene");
my $url = "http://www.sanger.ac.uk/cgi-bin/Projects/C_elegans/nameserver_json.pl?domain=Gene";
my $request = HTTP::Request->new(GET => $url);	#grabs url
my $response = $ua->request($request);		#checks url, dies if not valid.

# my $response = $ua->get("http://tazendra.caltech.edu/~azurebrd/sanger/gene_postgres/nameserverGene");
my $sanger = '';
if ($response->is_success) { $sanger = $response->content; $sanger .= "\n"; }
  else { die $response->status_line; }

my @pgcommands; my %gene; 
my $nameserverGeneFile = $directory . '/nameserverGene.txt';
$/ = undef;
open (IN, "<$nameserverGeneFile") or die "Cannot open $nameserverGeneFile : $!";
my $lastFileContent = <IN>;
close (IN) or die "Cannot close $nameserverGeneFile : $!";
$/ = "\n";
if ($lastFileContent eq $sanger) { exit 1; }	# last downloaded file is the same, don't do anything

open (OUT, ">$nameserverGeneFile") or die "Cannot open $nameserverGeneFile : $!";
print OUT $sanger; 
close (OUT) or die "Cannot close $nameserverGeneFile : $!";
my (@entries) = split/\n   \],\n   \[\n/, $sanger;
foreach my $entry (@entries) {
  my ($gene, $type, $value, $dead) = $entry =~ m/\"([^\"]+)\"/g;
#   next if ($type eq 'Public_name');			# was skipping Public_name but some values need to be in gin_wbgene for the OA, so only adding to that and gin_dead 
  my ($joinkey) = $gene =~ m/WBGene(\d+)/;
  if ($type eq 'CGC') { $gene{$joinkey}{locus} = $value; }
  elsif ($type eq 'Sequence') { $gene{$joinkey}{seqname} = $value; }
  elsif ($type eq 'Public_name') { $gene{$joinkey}{wbgene} = $value; }	# store wbgene only, not name
  if ($dead == 0) {
    $gene{$joinkey}{dead} = 'Dead'; 
    if ( $dead_in_pg{$joinkey} ) { $gene{$joinkey}{dead} = $dead_in_pg{$joinkey}; } }
#   print "G $gene T $type V $value D $dead E\n";
} # foreach my $entry (@entries)

foreach my $joinkey (sort keys %gene) {
  push @pgcommands, "INSERT INTO gin_wbgene VALUES ('$joinkey', 'WBGene$joinkey')";
  if ($gene{$joinkey}{locus}) {
    if ($pg_locus{$joinkey}) {									# if there is an old locus value to transfer
      if ($pg_locus{$joinkey} ne $gene{$joinkey}{locus}) {		# if the old locus is different from the new locus
        unless ($pg_syns{$joinkey}{$pg_locus{$joinkey}}) {		# and the old locus is not already a synonym
          push @pgcommands, "INSERT INTO gin_synonyms VALUES ('$joinkey', '$pg_locus{$joinkey}')"; } } }	# add old locus to synonyms
    push @pgcommands, "INSERT INTO gin_locus VALUES ('$joinkey', '$gene{$joinkey}{locus}')"; }
  if ($gene{$joinkey}{seqname}) { 
    push @pgcommands, "INSERT INTO gin_seqname VALUES ('$joinkey', '$gene{$joinkey}{seqname}')"; }
  if ($gene{$joinkey}{dead}) { 
    push @pgcommands, "INSERT INTO gin_dead VALUES ('$joinkey', '$gene{$joinkey}{dead}')"; }
}

# foreach my $joinkey (sort keys %dead_in_ns) {
#   unless ($dead_in_pg{$joinkey}) { 
#     push @pgcommands, "INSERT INTO gin_dead VALUES ('$joinkey', '$dead_in_ns{$joinkey}')"; } }
# foreach my $joinkey (sort keys %dead_in_pg) {
#   unless ($dead_in_ns{$joinkey}) { 
#     push @pgcommands, "DELETE FROM gin_dead WHERE joinkey = '$joinkey' AND gin_dead = '$dead_in_pg{$joinkey}'"; } }

if (scalar(@pgcommands) > 1000) {	# since can't split whole file anymore, guessing that if there's 1000 entries, that it's a good set
  unshift @pgcommands, "DELETE FROM gin_wbgene";
  unshift @pgcommands, "DELETE FROM gin_locus";
  unshift @pgcommands, "DELETE FROM gin_seqname";
  unshift @pgcommands, "DELETE FROM gin_dead";
  foreach my $pgcommand (@pgcommands) {
#     print "$pgcommand\n";
# UNCOMMENT TO MAKE LIVE
    my $result = $dbh->do( $pgcommand );
  }
} else {
    my $user = 'populate_gin_locus.pl';
    my $email = 'vanauken@its.caltech.edu';
#     my $email = 'azurebrd@tazendra.caltech.edu';
    my $subject = 'didn\'t update nameserver Gene file because of small file size';
    my $body = "nameserver Gene file was not updated";
    &mailer($user, $email, $subject, $body);
}

__END__


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

