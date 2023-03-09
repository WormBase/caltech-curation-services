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

# 0 3 * * * /home/azurebrd/public_html/sanger/gene_postgres/populate_gin_locus.pl



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

# my %dead_in_pg;
# my $result = $dbh->prepare( "SELECT * FROM gin_dead" );
# $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
# while (my @row = $result->fetchrow) { $dead_in_pg{$row[0]} = $row[1]; }



my $directory = '/home/azurebrd/public_html/sanger/gene_postgres';
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
if ($response->is_success) { $sanger = $response->content;  }
  else { die $response->status_line; }

my @pgcommands; my %gene; 
my $outfile = $directory . '/nameserverGene.txt';
open (OUT, ">$outfile") or die "Cannot open $outfile : $!";
print OUT "$sanger\n"; 
close (OUT) or die "Cannot close $outfile : $!";
my (@entries) = split/\n   \],\n   \[\n/, $sanger;
foreach my $entry (@entries) {
  my ($gene, $type, $value, $dead) = $entry =~ m/\"([^\"]+)\"/g;
  next if ($type eq 'Public_name');
  my ($joinkey) = $gene =~ m/WBGene(\d+)/;
  if ($type eq 'CGC') { $gene{$joinkey}{locus} = $value; }
  elsif ($type eq 'Sequence') { $gene{$joinkey}{seqname} = $value; }
  if ($dead == 0) { $gene{$joinkey}{dead} = 'Dead'; }
#   print "G $gene T $type V $value D $dead E\n";
} # foreach my $entry (@entries)

foreach my $joinkey (sort keys %gene) {
  push @pgcommands, "INSERT INTO gin_wbgene VALUES ('$joinkey', 'WBGene$joinkey')";
  if ($gene{$joinkey}{locus}) { 
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

