#!/usr/bin/env perl

# CGI to receive nameserver posting data of new objects, replacing new_objects.cgi

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

print $cgi->header(-type => "application/json", -charset => "utf-8");

if ($postData) {
#   print qq(postData\n);
#   print qq($postData\n);
  my $dataHashRef = decode_json($postData);
  my %dataHash = %$dataHashRef;
#   print qq(dataHash\n);
#   print qq(%dataHash\n);
#   foreach my $field (sort keys %dataHash) { print qq($field : $dataHash{$field}\n); }
  my $datatype = '';
  my $objId = '';
  my $objName = '';
  if ($dataHash{datatype}) { $datatype = $dataHash{datatype}; }
  if ($dataHash{objId}) { $objId = $dataHash{objId}; }
  if ($dataHash{objName}) { $objName = $dataHash{objName}; }
  my @errMessage = ();
  unless ($objId) { push @errMessage, "Must have an objId value." }
  unless ($objName) { push @errMessage, "Must have an objName value." }
# print qq(D $datatype\n);
  if ( ($datatype eq 'strain') || ($datatype eq 'variation') ) {
    if (scalar @errMessage < 1) {
      my $entry_error = &addTempObjectObo($datatype, $objId, $objName); 
      if ($entry_error) { push @errMessage, $entry_error; }
    }
  } else {
    push @errMessage, "datatype must be variation or strain."
  }
  my $message = join"  ", @errMessage;
  unless ($message) { $message = 'no status message, something probably went wrong'; }
#   print qq($message\n);
  my %hash = ();
  $hash{message} = $message;
  my $json_message = encode_json( \%hash );
  print qq($json_message);
}


sub addTempObjectObo {
  my ($datatype, $objId, $objName) = @_;
  my $result = $dbh->prepare( "SELECT * FROM obo_name_$datatype WHERE joinkey = '$objId';" ); $result->execute;
  my @row = $result->fetchrow();
  my $entry_error = '';
  if ($row[0]) { $entry_error .= qq($objId already exists associated to $row[1].  ); }
  $result = $dbh->prepare( "SELECT * FROM obo_name_$datatype WHERE obo_name_$datatype = '$objName';" ); $result->execute;
  @row = $result->fetchrow();
  if ($row[0]) { $entry_error .= qq($objName already exists associated to $row[0].  ); }
  if ($entry_error) { 
#     print $entry_error; 
    return $entry_error; }
  my $pgDate = &getPgDate();
  my $comment = qq(added through temp_objects.cgi, not updated by geneace yet);
  my $terminfo = qq(id: $objId\nname: "$objName"\ntimestamp: "$pgDate"\ncomment: "$comment");
  $result = $dbh->do( "INSERT INTO obo_name_$datatype VALUES('$objId', '$objName');" );
  $result = $dbh->do( "INSERT INTO obo_data_$datatype VALUES('$objId', '$terminfo');" );
  my $success_message = "Added $pgDate $objId $objName to obo_name_$datatype and obo_data_$datatype .";
  my $obotempfile = $filesPath . 'obo_tempfile_' . $datatype;
  # my $obotempfile = '/home/azurebrd/public_html/cgi-bin/data/obo_tempfile_' . $datatype;
  unless (-e $obotempfile) { $entry_error = "ERROR no obo_tempfile_$datatype to write to at $obotempfile . Contact Juancarlos because $objName + $objId got created in the names service, but it's not in tempfile to update postgres"; return $entry_error; }
  open (OUT, ">>$obotempfile") or die "Cannot append to $obotempfile : $!";
  print OUT qq($objId\t$objName\t$pgDate\t$comment\n);
  close (OUT) or die "Cannot append to $obotempfile : $!";
  return $success_message;
} # sub addTempObjectObo



__END__

Test this with

curl -X 'POST' \
  'http://caltech-curation-dev.textpressolab.com/priv/cgi-bin/nameserver_api.cgi' \
  -u '<user>:<pass>' \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -d '{"datatype":"strain","objId":"WBStrain00100001","objName":"tempStrain"}'

  -d '{"datatype":"variation","objId":"WBVar03000001","objName":"tempVariation"}'



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

