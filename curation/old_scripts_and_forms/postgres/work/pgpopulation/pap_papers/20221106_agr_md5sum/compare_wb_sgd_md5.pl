#!/usr/bin/perl

# compare output from ABC referencefile.pg dump to md5sum generated at WB.
# 1603 files exist in both, but will need to map all the AGRKB values.

use strict;
use DBI;
use Jex;

my $dbhlit = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $dbh = DBI->connect ( "dbi:Pg:dbname=literature-4002;host=dev.alliancegenome.org;port=5432", "postgres", "postgres") or die "Cannot connect to database!\n"; 
my $result;


my %convertToWBPaper;
my %backwards;
&readConversions;


my %refid_to_agrkb;
my %agrkb_to_refid;
my %refid_to_xref;
my %xref_to_refid;

my $date = &getPgDate();
print qq($date\n);

# 5 seconds
$result = $dbh->prepare( "SELECT curie, reference_id FROM cross_reference WHERE reference_id IS NOT NULL AND is_obsolete = False" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) {
    $xref_to_refid{$row[0]} = $row[1];
    $refid_to_xref{$row[1]} = $row[0]; }
} # while (@row = $result->fetchrow)

$date = &getPgDate();
print qq($date\n);

# 4 seconds
$result = $dbh->prepare( "SELECT curie, reference_id FROM reference " );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $agrkb_to_refid{$row[0]} = $row[1];
    $refid_to_agrkb{$row[1]} = $row[0]; }
} # while (@row = $result->fetchrow)

$date = &getPgDate();
print qq($date\n);

my %sgd;
my $sgdfile = 'sgd_referencefile.pg';
open (IN, "<$sgdfile") or die "Cannot open $sgdfile : $!";
while (my $line = <IN>) {
  chomp $line;
  my @line = split/\t/, $line;
  $sgd{$line[9]}{refid} = $line[4];
  $sgd{$line[9]}{class} = $line[5];
}
close (IN) or die "Cannot close $sgdfile : $!";

my %wb;
my $wbfile = 'md5_all';
open (IN, "<$wbfile") or die "Cannot open $wbfile : $!";
while (my $line = <IN>) {
  chomp $line;
  my @line = split/\t/, $line;
  $wb{$line[0]} = $line[1];
}
close (IN) or die "Cannot close $wbfile : $!";

foreach my $md5 (sort keys %wb) {
  my $wb_loc = $wb{$md5};
  my $agrkb_wb = '';
  if ($sgd{$md5}) { 
    my $papid = 0;
    my $wb_class = 'main';
    if ($wb_loc =~ m/supplement/) { $wb_class = 'supplement'; }
    if ($wb_loc =~ m/^wb\/[a-z]+\/(\d{8})[^\d]/) { $papid = $1; }
      elsif ($wb_loc =~ m/^pubmed/) { $papid = &getPapJoinkeyFromPmid($wb_loc); }
      elsif ($wb_loc =~ m/^cgc/) { $papid = &getPapJoinkeyFromCgc($wb_loc); }
#     unless ($papid) { print qq($papid\t$wb_loc\n); }
    if ($papid > 0) {
      my $wbp = 'WB:WBPaper' . $papid;
      if ($xref_to_refid{$wbp}) { $agrkb_wb = $refid_to_agrkb{$xref_to_refid{$wbp}}; }
        else { $agrkb_wb = $wbp; } }
    my $match = 'no wbpaper';
    my $sgd_refid = $sgd{$md5}{refid};
    my $sgd_class = $sgd{$md5}{class};
    my $agrkb_sgd = $refid_to_agrkb{$sgd_refid};
    if ($agrkb_sgd == $agrkb_wb) { $match = 'same'; } else { $match = 'no match'; }
    if ($agrkb_wb eq '') { $match = 'no wbpaper'; }
    my $class_diff = 'same';
    if ($sgd_class ne $wb_class) { $class_diff = 'different'; }
    print qq($md5\t$match\t$agrkb_sgd\t$agrkb_wb\t$class_diff\t$sgd_class\t$wb_class\t$wb{$md5}\n);
  }
}

sub getPapJoinkeyFromPmid {
  my $file = shift;
  my ($file_name) = $file =~ m/.*\/(.*?)$/;
  if ($file_name !~ m/\.pdf$/i) { next; }               # skip non-pdfs
  my ($pmid) = $file_name =~ m/(\d+).*/;
  $pmid = 'pmid' . $pmid;
  my $wbid = 0;
  if ($convertToWBPaper{$pmid}) {
    $wbid = $convertToWBPaper{$pmid};
    $wbid =~ s/WBPaper//g;
    return $wbid;
} }

sub getPapJoinkeyFromCgc {
  my $file = shift;
  my ($file_name) = $file =~ m/.*\/(.*?)$/;
  if ($file_name !~ m/\.pdf$/i) { next; }               # skip non-pdfs
  my ($cgc) = $file_name =~ m/^_*(\d+).*/;      # some files start with _ for some reason
  $cgc = 'cgc' . $cgc;
  my $wbid = 0;
  if ($convertToWBPaper{$cgc}) {
    $wbid = $convertToWBPaper{$cgc};
    $wbid =~ s/WBPaper//g;
    return $wbid;
  }
}

sub readConversions {
#   my $u = "http://tazendra.caltech.edu/~postgres/cgi-bin/wpa_xref_backwards.cgi";
  my $u = "http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/generic.cgi?action=WpaXrefBackwards";
  my $ua = LWP::UserAgent->new(timeout => 30); #instantiates a new user agent
  my $request = HTTP::Request->new(GET => $u); #grabs url
  my $response = $ua->request($request);       #checks url, dies if not valid.
  die "Error while getting ", $response->request->uri," -- ", $response->status_line, "\nAborting" unless $response-> is_success;
  my @tmp = split /\n/, $response->content;    #splits by line
  foreach (@tmp) {
    if ($_ =~m/^(.*?)\t(.*?)$/) {
      my $other = $1; my $wbid = $2;
      unless ($backwards{$wbid}) { $backwards{$wbid} = $other; }
      $convertToWBPaper{$other} = $wbid; } }
} # sub readConversions



__END__

 psql -h dev.alliancegenome.org -p 5432 -U postgres literature-4002


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

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb;host=131.215.52.76", "", "") or die "Cannot connect to database!\n";	# for remote access

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

