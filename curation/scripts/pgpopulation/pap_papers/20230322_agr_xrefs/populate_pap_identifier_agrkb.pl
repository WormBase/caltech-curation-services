#!/usr/bin/env perl

# read agr wb reference json and extract agr IDs to connect to existing WBPaper IDs.
# 60010 AGR IDs loaded into pap_identifier on dockerized on 2023 03 22, against postgres dump from 20230215.
# 2023 03 22
#
# generate xref json file to full path for cronjob to know what to use.  
# prioritize mapping based on pmid to abc pmid agrkb, then wbpaper at abc.  
# output conflicts to screen, later create email to Kimberly"
# 2023 08 04


use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );
# use JSON::Parse 'parse_json';
# use JSON::XS;
use JSON;
use Dotenv -load => '/usr/lib/.env';

my $dbh = DBI->connect ( "dbi:Pg:dbname=$ENV{PSQL_DATABASE};host=$ENV{PSQL_HOST};port=$ENV{PSQL_PORT}", "$ENV{PSQL_USERNAME}", "$ENV{PSQL_PASSWORD}") or die "Cannot connect to database!\n";
# my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n";
my $result;


my %abcWbps;
my %abcWbpToAgr;
my %abcPmids;
my %abcPmidToAgr;

my $xref_file_path = $ENV{CALTECH_CURATION_FILES_INTERNAL_PATH} . '/postgres/pgpopulation/pap_papers/20230322_agr_xrefs/files/ref_xref.json';

my @pgcommands;
my %highestPapIdent;

# &populateFromNightlyAbcWb();
&populateFromAbcXrefs();

sub generateOktaToken {
  my $okta_token = `curl -s --request POST --url https://$ENV{OKTA_DOMAIN}/v1/token \    --header 'accept: application/json' \    --header 'cache-control: no-cache' \    --header 'content-type: application/x-www-form-urlencoded' \    --data "grant_type=client_credentials&scope=admin&client_id=$ENV{OKTA_CLIENT_ID}&client_secret=$ENV{OKTA_CLIENT_SECRET}" \      | jq '.access_token' | tr -d '"'`;
  return $okta_token;
}

sub generateXrefJsonFile {
  my $okta_token = &generateOktaToken();
  `curl -X 'GET' 'https://stage-literature-rest.alliancegenome.org/bulk_download/references/external_ids/' -H 'accept: application/json' -H 'Authorization: Bearer $okta_token' -H 'Content-Type: application/json'  > $xref_file_path`;
#   `curl -X 'GET' 'https://stage-literature-rest.alliancegenome.org/bulk_download/references/external_ids/' -H 'accept: application/json' -H 'Authorization: Bearer $okta_token' -H 'Content-Type: application/json'  > files/ref_xref.json`;
}

sub populateFromAbcXrefs {
  # this requires getting the most recent cross_references from ABC, needs okta token
  #  %curl -X 'GET' \
  #    'https://stage-literature-rest.alliancegenome.org/bulk_download/references/external_ids/' \
  #    -H 'accept: application/json' \
  #    -H 'Authorization: Bearer eyJraWQiOiJNX1N0dWxfYlE5cEw1aHdLQ1hmN2hOSjcyYzJLYjl4SjhuYlQ3NjdPQzJzIiwiYWxnIjoiUlMyNTYifQ.eyJ2ZXIiOjEsImp0aSI6IkFULmlQMFp5NG9SYkdKZ0E3ZExnU2dSSmE5ZE45blhvR05VUm5nT2M1dnlBWnMiLCJpc3MiOiJodHRwczovL2Rldi0zMDQ1NjU4Ny5va3RhLmNvbS9vYXV0aDIvZGVmYXVsdCIsImF1ZCI6ImFwaTovL2RlZmF1bHQiLCJpYXQiOjE2NDc2NzQyODUsImV4cCI6MTY0Nzc2MDY4NSwiY2lkIjoiMG9hMWJuMXdqZFppSldhSmU1ZDciLCJ1aWQiOiIwMHUxY3R6dmpnTXBrODdRbTVkNyIsInNjcCI6WyJlbWFpbCIsIm9wZW5pZCJdLCJhdXRoX3RpbWUiOjE2NDc2NzQyODQsInN1YiI6Imp1YW5jYXJsb3NAd29ybWJhc2Uub3JnIn0.HlShhBK1tNyalpYGhDId_LbqaG2541E5yE9ErGWtBKOGtXJvS-ZEDrSM62Xq_0cbL_h85Icj7pWLtPTjcphGngT_9AQMeVMFLuGx9BIUdVhdXWS5uu8VRjhO-WVbHBQOopwUdMCILh9P5vkBax47_dzuwPUlaJboGtgnafNMNqZCJAmPqWpIepmsrjCEHoWRPJxWlor_fXQBvTcBxVWfa7_eN27-0TJP_YPA7rofl1FvVGGUDgornKLJCFbBvte13qgeOsVv8kPlPZHtJ46rV19OZ3LZSmTKFH1cxyviHgB51ACt2qWjDFA8qxiyBBTFyBsnly0ks93ygpsat8qj4Q' \
  #    -H 'Content-Type: application/json'  >  ref_xref.json
  # optionally to make more readable version
  #  % cat ref_xref.json | json_pp > ref_xref.json_pp

  # UNCOMMENT for live run with latest data
#   &generateXrefJsonFile();

  # my $xref_file_path = 'files/ref_xref.json';
  # my $xref_file_path = '/usr/lib/scripts/pgpopulation/pap_papers/20230322_agr_xrefs/files/ref_xref.json';

  $/ = undef;
  open (IN, "<$xref_file_path") or die "Cannot open $xref_file_path : $!";
  print "Start reading $xref_file_path\n";
  my $json_data = <IN>;
  print "Done reading $xref_file_path\n";
  close (IN) or die "Cannot open $xref_file_path : $!";

  print "Start decoding json\n";
  # my %perl = parse_json($json_data);	# JSON::Parse, not installed in dockerized
  my $perl = decode_json($json_data);	# JSON  very very slow on dockerized without JSON::XS, but fast on tazendra.  with JSON::XS installed is fast even without directly calling JSON::XS->new like below, and without use JSON::XS, just use JSON

  print "Done decoding json\n";
  my @agr = @$perl;
#   foreach my $key (sort keys %agr) {
#     print qq($key\n);
#   }

  my $count = 0;
  foreach my $papobj_href (@agr) {
  #   print qq(papobj_href\n);
    my %papobj = %$papobj_href;
#     $count++; last if ($count > 10);
    my $agr = $papobj{curie};
    my $pmid = '';
    my $wbp = '';
    print qq($agr\n);
    my %xrefs;
    foreach my $xref_href (@{ $papobj{cross_references} }) {
      my %xref = %$xref_href;
      next unless $xref{curie};
      if ($xref{curie} =~ m/^PMID:(\d+)/) { $pmid = 'pmid' . $1; }
      if ($xref{curie} =~ m/^WB:WBPaper(\d+)/) { $wbp = $1; }
  #     print qq($xref{curie}\n);
    }
  #   print qq(\n);
    if ($pmid) {
      $abcPmids{$pmid}++;
      print qq(ABC $pmid : $agr\n);
      $abcPmidToAgr{$pmid} = $agr;
    }
    if ($wbp) {
      $abcWbps{$wbp}++;
      print qq(ABC WBPaper$wbp : $agr\n);
      $abcWbpToAgr{$wbp} = $agr;
    }
  }

  foreach my $wbp (sort keys %abcWbps) {
    if ($abcWbps{$wbp} > 1) { print qq(ERR : Too many wbps at ABC $wbp $abcWbps{$wbp}\n); }
  }

  my %valid;
  $result = $dbh->prepare( "SELECT * FROM pap_status WHERE pap_status = 'valid'" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) { $valid{$row[0]}++; }

  my %pgWbpToAgr;
  my %pgWbpToPmid;
  $result = $dbh->prepare( "SELECT * FROM pap_identifier ORDER BY joinkey, pap_order" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
    $highestPapIdent{$row[0]} = $row[2];
    if ($row[1] =~ m/AGRKB:/) { $pgWbpToAgr{$row[0]} = $row[1]; }
    if ($row[1] =~ m/pmid/) { $pgWbpToPmid{$row[0]} = $row[1]; }
  }

  # Kimberly : if there's a PMID, use that preferentially, and if there's not a PMID, then map WBPaper IDs
  foreach my $joinkey (sort {$a<=>$b} keys %valid) {
    my $pgAgr = ''; my $agrFromPmid = ''; my $agrFromWbp = ''; my $pgPmid = '';
    if ($pgWbpToAgr{$joinkey}) { $pgAgr = $pgWbpToAgr{$joinkey}; }
    if ($pgWbpToPmid{$joinkey}) {
      $pgPmid = $pgWbpToPmid{$joinkey};
      if ($abcPmidToAgr{$pgPmid}) {
        $agrFromPmid = $abcPmidToAgr{$pgPmid}; } }
    if ($abcWbpToAgr{$joinkey}) {
      $agrFromWbp = $abcWbpToAgr{$joinkey}; }

#     if ( ($pgAgr ne '') && ($agrFromPmid ne '') && ($agrFromWbp ne '') )
    if ( ($agrFromPmid ne '') && ($agrFromWbp ne '') && ($agrFromPmid ne $agrFromWbp) ) {
      print qq(CONFLICT $joinkey at ABC is $agrFromWbp , $joinkey has pg pmid $pgPmid at ABC is $agrFromPmid , $joinkey in pg is $pgAgr\n); }
    elsif ( $agrFromPmid ne '') {
      if ($pgAgr ne $agrFromPmid) {
        if ($pgAgr eq '') {
          &createAgrXref($joinkey, $agrFromPmid);
          print qq(CREATE $joinkey to $agrFromPmid based on pmid $pgPmid at ABC\n); }
        else {
          &updateAgrXref($joinkey, $agrFromPmid, $pgAgr);
          print qq(UPDATE $joinkey to $agrFromPmid based on pmid $pgPmid at ABC, was $pgAgr\n); } } }
    elsif ( $agrFromWbp ne '') {
      if ($pgAgr ne $agrFromWbp) {
        if ($pgAgr eq '') {
          &createAgrXref($joinkey, $agrFromWbp);
          print qq(CREATE $joinkey to $agrFromWbp based wbp at ABC\n); }
        else {
          &updateAgrXref($joinkey, $agrFromWbp, $pgAgr);
          print qq(UPDATE $joinkey to $agrFromWbp based wbp at ABC, was $pgAgr\n); } } }
  }

  foreach my $pgcommand (@pgcommands) {
    print qq($pgcommand\n);
  # UNCOMMENT TO POPULATE
  #   $dbh->do($pgcommand);
  } # foreach my $pgcommand (@pgcommands)

} # sub populateFromAbcXrefs

sub updateAgrXref {
  my ($joinkey, $agr, $agrOld) = @_;
  print qq(WBPaper$joinkey\t$agr\twas\t$agrOld\n);
  push @pgcommands, qq(UPDATE pap_identifier SET pap_identifier = '$agr' WHERE joinkey = '$joinkey' AND pap_identifier = '$agr';);
}

sub createAgrXref {
  my ($joinkey, $agr) = @_;
#   print qq(WBPaper$joinkey\t$pgPmid\t$agr\n);
  print qq(WBPaper$joinkey\t$agr\n);
  my $order = 1;
  if ($highestPapIdent{$joinkey}) {
    $order = $highestPapIdent{$joinkey} + 1;
    # print qq(ERR : No order for $joinkey\n);
  }
  push @pgcommands, qq(INSERT INTO pap_identifier VALUES ('$joinkey', '$agr', $order, 'two1823'););
}

__END__

sub populateFromNightlyAbcWb {
  # this only populates AGR for papers that are in corpus at ABC, assuming that ABC is Biblio SoT, but for a while PDFs will be at ABC before switching SoT
  my $infile = 'files/reference_WB_nightly.json';
  # my $infile = '/usr/lib/scripts/pgpopulation/pap_papers/20230322_agr_xrefs/reference_WB_nightly.json';
  
  $/ = undef;
  open (IN, "<$infile") or die "Cannot open $infile : $!";
  print "Start reading $infile\n";
  my $json_data = <IN>;
  print "Done reading $infile\n";
  close (IN) or die "Cannot open $infile : $!";
  
  print "Start decoding json\n";
  # my %perl = parse_json($json_data);	# JSON::Parse, not installed in dockerized
  my $perl = decode_json($json_data);	# JSON  very very slow on dockerized without JSON::XS, but fast on tazendra.  with JSON::XS installed is fast even without directly calling JSON::XS->new like below, and without use JSON::XS, just use JSON
  # my $perl = JSON::XS->new->utf8->decode ($json_data);
  
  print "Done decoding json\n";
  my %agr = %$perl;
  foreach my $key (sort keys %agr) {
    print qq($key\n);
  }
  
  my $count = 0;
  foreach my $papobj_href (@{ $agr{data} }) {
  #   print qq(papobj_href\n);
    my %papobj = %$papobj_href;
  #   $count++; last if ($count > 10);
    my $agr = $papobj{curie};
    my $wbp = '';
  #   print qq($agr\n);
    my %xrefs;
    foreach my $xref_href (@{ $papobj{cross_references} }) {
      my %xref = %$xref_href;
      if ($xref{curie} =~ m/^WB:WBPaper(\d+)/) { $wbp = $1; }
  #     print qq($xref{curie}\n);
    }
  #   print qq(\n);
    if ($wbp) { 
      $wbps{$wbp}++;
      print qq($wbp : $agr\n);
      $wbpToAgr{$wbp} = $agr;
    }
  }

  foreach my $wbp (sort keys %wbps) {
    if ($wbps{$wbp} > 1) { print qq(ERR : Too many wbps $wbp $wbps{$wbp}\n); }
  }
  
  my %valid;
  $result = $dbh->prepare( "SELECT * FROM pap_status WHERE pap_status = 'valid'" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { $valid{$row[0]}++; }
  
  my %highestPapIdent;
  $result = $dbh->prepare( "SELECT * FROM pap_identifier ORDER BY joinkey, pap_order" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    $highestPapIdent{$row[0]} = $row[2];
  }
  
  my @pgcommands;
  foreach my $joinkey (sort keys %wbpToAgr) {
    next unless $valid{$joinkey};
    my $order = 1;
    if ($highestPapIdent{$joinkey}) {
      $order = $highestPapIdent{$joinkey} + 1;
      # print qq(ERR : No order for $joinkey\n);
    }
    push @pgcommands, qq(INSERT INTO pap_identifier VALUES ('$joinkey', '$wbpToAgr{$joinkey}', $order, 'two1823'););
  }
  
  foreach my $pgcommand (@pgcommands) {
    print qq($pgcommand\n);
  # UNCOMMENT TO POPULATE
  #   $dbh->do($pgcommand);
  } # foreach my $pgcommand (@pgcommands)

} # sub populateFromNightlyAbcWb

__END__

$result = $dbh->prepare( "SELECT * FROM two_comment LIMIT 5" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[1] =~ s///g;
    $row[2] =~ s///g;
    print "$row[0]\t$row[1]\t$row[2]\n";
  } # if ($row[0])
} # while (@row = $result->fetchrow)


how to set directory to output files at curator / web-accessible
  my $outDir = $ENV{CALTECH_CURATION_FILES_INTERNAL_PATH} . "/pub/citace_upload/karen/";

how to set base url for a form
  my $baseUrl = $ENV{THIS_HOST} . "pub/cgi-bin/forms";

how to import modules in dockerized system
  use lib qw(  /usr/lib/scripts/perl_modules/ );                  # for general ace dumping functions
  use ace_dumper;

how to queue a bunch of insertions
  my @pgcommands;
  push @pgcommands, qq(INSERT INTO obo_name_hgnc VALUES $name_commands;);
  foreach my $pgcommand (@pgcommands) {
    print qq($pgcommand\n);
# UNCOMMENT TO POPULATE
#     $dbh->do($pgcommand);
  } # foreach my $pgcommand (@pgcommands)


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

