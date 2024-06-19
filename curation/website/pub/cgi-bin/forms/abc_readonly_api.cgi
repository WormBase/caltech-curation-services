#!/usr/bin/env perl

# CGI API for ABC entity lookup

# Updated header to have status codes for Manuel.  2024 02 07
#
# Comment updated from being added by temp_objects.cgi to being created through nameserver.  2024 02 21
#
# Updated to be read only api for ABC.  2024 05 16


use diagnostics;
use strict;
use Jex;		# printHeader printFooter getHtmlVar getDate getSimpleDate mailer
use CGI;
use DBI;
use JSON;
use Dotenv -load => '/usr/lib/.env';

my $cgi = CGI->new;

my $dbh = DBI->connect ( "dbi:Pg:dbname=$ENV{PSQL_DATABASE};host=$ENV{PSQL_HOST};port=$ENV{PSQL_PORT}", "$ENV{PSQL_USERNAME}", "$ENV{PSQL_PASSWORD}") or die "Cannot connect to database!\n";

my $postData = $cgi->param("POSTDATA");

my $filesPath = $ENV{CALTECH_CURATION_FILES_INTERNAL_PATH} . '/pub/cgi-bin/data/';

my %validDatatypes;
$validDatatypes{'gene'}++;

if ($postData) {
#   print qq(postData\n);
#   print qq($postData\n);
  my $dataHashRef = decode_json($postData);
  my %dataHash = %$dataHashRef;
#   print qq(dataHash\n);
#   print qq(%dataHash\n);
#   foreach my $field (sort keys %dataHash) { print qq($field : $dataHash{$field}\n); }
  my $datatype = '';
  my $entities = '';
  if ($dataHash{datatype}) { $datatype = $dataHash{datatype}; }
  if ($dataHash{entities}) { $entities = $dataHash{entities}; }
  my @errMessage = ();
  my $outputMessage = '';
  my $status = 200;
  unless ($validDatatypes{$datatype}) { push @errMessage, "datatype $datatype not allowed."; $status = 400; }
  unless ($entities) { push @errMessage, "No entities to lookup."; $status = 400; }

  if (scalar @errMessage < 1) {
    if ($datatype eq 'gene') { 
#       $outputMessage = &lookupGenes('let-60|abc-1|WB:WBGene00001234');
      $outputMessage = &lookupGenes($entities);
  } }

  if ($status == 200) {      print $cgi->header(-type => "application/json", -charset => "utf-8", -status => "200 OK"); }
    elsif ($status == 201) { print $cgi->header(-type => "application/json", -charset => "utf-8", -status => "201 Created"); }
    elsif ($status == 400) { print $cgi->header(-type => "application/json", -charset => "utf-8", -status => "400 Bad Request"); }
    elsif ($status == 409) { print $cgi->header(-type => "application/json", -charset => "utf-8", -status => "409 Conflict"); }
    elsif ($status == 500) { print $cgi->header(-type => "application/json", -charset => "utf-8", -status => "500 Internal Server Error"); }
    else {                   print $cgi->header(-type => "application/json", -charset => "utf-8", -status => "500 Internal Server Error"); }
  my $errMessages = join"  ", @errMessage;
  if ($errMessages) {
    my %hash = ();
    $hash{message} = $errMessages;
    my $json_message = encode_json( \%hash );
    print qq($json_message); }
  if ($outputMessage) {
    print qq($outputMessage); }
}
elsif ($ENV{REQUEST_METHOD} eq 'OPTIONS') {
  print "Access-Control-Allow-Headers: Content-Type\n\n";
}
else {
  print $cgi->header(-type => "application/json", -charset => "utf-8", -status => "400 Bad Request");
}

sub lookupGenes {
  my ($genesInput) = @_;
  my (@genes) = split/\|/, $genesInput;
  my @locus; my @wbgene;
  foreach my $gene (@genes) {
    $gene =~ s/^\s+//; $gene =~ s/\s+$//;
    next unless $gene;
    if ($gene =~ m/WB:WBGene(\d+)/) { push @wbgene, $1; }
      else { push @locus, $gene; }
  }
  my $loci = join"','", @locus;
  my $joinkeys = join"','", @wbgene;
  my %output;
  my $result = $dbh->prepare( "SELECT * FROM gin_locus WHERE gin_locus IN ('$loci');" ); $result->execute;
  while (my @row = $result->fetchrow()) {
    $output{"WB:WBGene$row[0]"} = $row[1];
  }
  $result = $dbh->prepare( "SELECT * FROM gin_wbgene WHERE joinkey IN ('$joinkeys');" ); $result->execute;
  while (my @row = $result->fetchrow()) {
    $output{"WB:WBGene$row[0]"} = $row[1];
  }
  $result = $dbh->prepare( "SELECT * FROM gin_locus WHERE joinkey IN ('$joinkeys');" ); $result->execute;
  while (my @row = $result->fetchrow()) {
    $output{"WB:WBGene$row[0]"} = $row[1];
  }
  foreach my $wbgene (@wbgene) {
    unless ($output{"WB:WBGene$wbgene"}) {
      $output{"WB:WBGene$wbgene"} = 'not found at WB'; }
  }

  my $json_message = encode_json( \%output );
#   print qq($json_message\n);
  return $json_message;
}



__END__

Test this with

curl -X 'POST' \
  'http://caltech-curation.textpressolab.com/pub/cgi-bin/forms/abc_readonly_api.cgi' \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -d '{"datatype":"gene","entities":"let-60"}'

curl -X 'POST' \
  'http://caltech-curation.textpressolab.com/pub/cgi-bin/forms/abc_readonly_api.cgi' \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -d '{"datatype":"gene","entities":"let-60|abc-1|WB:WBGeneQUACK|WB:WBGene99901234|WB:WBGene00001234|quack"}'



__END__


curl -X 'POST' \
  'http://caltech-curation-dev.textpressolab.com/priv/cgi-bin/nameserver_api.cgi' \
  -u '<user>:<pass>' \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -d '{"datatype":"strain","objId":"WBStrain00100001","objName":"tempStrain"}'

  -d '{"datatype":"variation","objId":"WBVar03000001","objName":"tempVariation"}'


Look at status codes with

curl -X 'POST' 'http://caltech-curation-dev.textpressolab.com/priv/cgi-bin/nameserver_api.cgi'  -u '${USER}:${PWD}' -H 'accept: application/json' -H 'Content-Type: application/json' -d '{"datatype":"strain","objId":"WBStrain00048331"}' -D -

curl -v -X 'POST' \
  'http://caltech-curation-dev.textpressolab.com/priv/cgi-bin/nameserver_api.cgi' \
  -u '<user>:<pass>' \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -d '{"datatype":"strain","objId":"WBStrain00100001","objName":"tempStrain"}'


OR 

#!/usr/bin/env perl

use LWP::UserAgent;
use HTTP::Request::Common;

my $ua = LWP::UserAgent->new;

#         my $server_endpoint = "http://tazendra.caltech.edu/~azurebrd/cgi-bin/testing/post_json/post_json.cgi";
#         my $server_endpoint = "http://caltech-curation-dev.textpressolab.com/pub/cgi-bin/nameserver_api.cgi";
        my $server_endpoint = "http://caltech-curation-dev.textpressolab.com/priv/cgi-bin/nameserver_api.cgi";

# set custom HTTP request header fields
my $req = HTTP::Request->new(POST => $server_endpoint);
$req->header('content-type' => 'application/json');

my $usr = 'FILLTHIS';
my $pass = 'FILLTHIS';
$req->authorization_basic($usr, $pass);

# add POST data to HTTP request body
my $post_data = '{ "action": "action", "name": "Dan" }';
$req->content($post_data);

my $resp = $ua->request($req);
if ($resp->is_success) {
    my $message = $resp->decoded_content;
    print "Received reply: $message\n";
}
else {
    print "HTTP POST error code: ", $resp->code, "\n";
    print "HTTP POST error message: ", $resp->message, "\n";
}

__END__

