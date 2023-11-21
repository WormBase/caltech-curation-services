#!/usr/bin/env perl

# CGI to receive nameserver posting data of new objects, replacing new_objects.cgi

use diagnostics;
use strict;
use CGI;
use JSON;

my $cgi = CGI->new;

my $postData = $cgi->param("POSTDATA");

print $cgi->header(-type => "application/json", -charset => "utf-8");

if ($postData) {
  print qq(postData\n);
  print qq($postData\n);
  my $dataHashRef = decode_json($postData);
  my %dataHash = %$dataHashRef;
  print qq(dataHash\n);
  print qq(%dataHash\n);
  foreach my $field (sort keys %dataHash) {
    print qq($field : $dataHash{$field}\n);
  }
}


__END__

Test this with

curl -X 'POST' \
  'http://caltech-curation-dev.textpressolab.com/priv/cgi-bin/nameserver_api.cgi' \
  -u '<user>:<pass>' \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -d '{"action":"blah","searchFilters":{"nameFilter":{"name":{"queryString":"Drosophila neomorpha Stigeoclonium\\ helveticum","tokenOperator":"OR"}}}}

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
