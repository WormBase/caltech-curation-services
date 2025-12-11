package AgrTetUtils;
use strict;
use diagnostics;
use Exporter 'import';
use DBI;
use JSON;
use Encode qw( from_to is_utf8 );
use Storable qw(dclone);
use Dotenv -load => '/usr/lib/.env';

# this package might work, but changing all the scripts to use this format for parameters from subroutines would be a big pain to change.
# we're pretty close to done, so will just copy-paste changes for now, and not use this.  2025 12 11


use constant FALSE => \0;
use constant TRUE => \1;

our @EXPORT_OK = qw(
    createSource
    tsToDigits
    generateCognitoToken
    generateOktaToken
    retryCreateTag
    createTag
    getSourceId
);

my $cognito_token = &generateCognitoToken();
my $start_time = time;
my $tag_counter = 0;
my $success_counter = 0;
my $exists_counter = 0;
my $invalid_counter = 0;
my $unexpected_counter = 0;
my $failure_counter = 0;
my $retry_counter = 0;


sub createSource {
  my ($baseUrl, $source_json) = @_;
  my $url = $baseUrl . 'topic_entity_tag/source';
  my $api_json = `curl -X 'POST' $url -H 'accept: application/json' -H 'Authorization: Bearer $cognito_token' -H 'Content-Type: application/json' --data '$source_json'`;
#   print qq(create $source_json\n);
#   print qq($api_json\n);
}

sub tsToDigits {
  my $timestamp = shift;
  my $tsdigits = '';
  if ($timestamp =~ m/^(\d{4})\-(\d{2})\-(\d{2})/) { $tsdigits = $1 . $2 . $3; }
  return $tsdigits;
}

sub generateCognitoToken {
  my $cognito_result = `curl -X POST "$ENV{COGNITO_TOKEN_URL}" \ -H "Content-Type: application/x-www-form-urlencoded" \ -d "grant_type=client_credentials" \ -d "client_id=$ENV{COGNITO_ADMIN_CLIENT_ID}" \ -d "client_secret=$ENV{COGNITO_ADMIN_CLIENT_SECRET}"`;
  my $hash_ref = decode_json $cognito_result;
  my $cognito_token = $$hash_ref{'access_token'};
#   print $cognito_token;
  return $cognito_token;
}

sub generateOktaToken {
#   my $okta_token = `curl -s --request POST --url https://$ENV{OKTA_DOMAIN}/v1/token \    --header 'accept: application/json' \    --header 'cache-control: no-cache' \    --header 'content-type: application/x-www-form-urlencoded' \    --data "grant_type=client_credentials&scope=admin&client_id=$ENV{OKTA_CLIENT_ID}&client_secret=$ENV{OKTA_CLIENT_SECRET}" \      | jq '.access_token' | tr -d '"'`;
  my $okta_result = `curl -s --request POST --url https://$ENV{OKTA_DOMAIN}/v1/token \    --header 'accept: application/json' \    --header 'cache-control: no-cache' \    --header 'content-type: application/x-www-form-urlencoded' \    --data "grant_type=client_credentials&scope=admin&client_id=$ENV{OKTA_CLIENT_ID}&client_secret=$ENV{OKTA_CLIENT_SECRET}"`;
  my $hash_ref = decode_json $okta_result;
  my $okta_token = $$hash_ref{'access_token'};
#   print $okta_token;
  return $okta_token;
}

sub retryCreateTag {
  my ($object_json) = @_;
  $retry_counter++;
  if ($retry_counter > 4) {
    print ERR qq(api failed without response $retry_counter times, giving up\n);
    print OUT qq(api failed without response $retry_counter times, giving up\n);
    $retry_counter = 0; }
  else {
    print ERR qq(api failed $retry_counter times, retrying\n);
    print OUT qq(api failed $retry_counter times, retrying\n);
    my $sleep_amount = 4 ** $retry_counter;
    sleep $sleep_amount;
    &createTag($object_json); }
} # sub retryCreateTag

sub createTag {
  my ($baseUrl, $object_json) = @_;
  $tag_counter++;
  if ($tag_counter % 1000 == 0) {
    my $date = &getSimpleSecDate();
    print qq(counter\t$tag_counter\t$date\n);
    my $now = time;
    if ($now - $start_time > 82800) {           # if 23 hours went by, update cognito token
      $cognito_token = &generateCognitoToken();
      $start_time = $now;
    }
  }
  my $url = $baseUrl . 'topic_entity_tag/';
#   my $api_json = `curl -X 'POST' $url -H 'accept: application/json' -H 'Authorization: Bearer $cognito_token' -H 'Content-Type: application/json' --data '$object_json'`;	# this has issues with how the shell interprets special characters like parentheses ( and ) when passed directly in the command line.  instead avoid the shell and run the command through a pipe like  open my $fh, "-|", @args

  my $ua = LWP::UserAgent->new;
  my $req = HTTP::Request->new(POST => $url);
  $req->header('accept' => 'application/json');
  $req->header('Authorization' => "Bearer $cognito_token");
  $req->header('Content-Type' => 'application/json');
  $req->content($object_json);
  my $res = $ua->request($req);

  print OUT qq(create $object_json\n);
  my $api_json = $res->decoded_content;
  print OUT qq($api_json\n);
  if ($res->is_success) {
    if ($api_json =~ /"status":"success"/) {
      $success_counter++;
      $retry_counter = 0;
    }
    elsif ($api_json =~ /"status":"exists"/) {
      $exists_counter++;
      print ERR qq(create $object_json\n);
      print ERR qq(EXISTS	$api_json\n);
      $retry_counter = 0;
    }
    elsif ($api_json =~ /"detail":"invalid request"/) {
      $invalid_counter++;
      print ERR qq(create $object_json\n);
      print ERR qq(INVALID	$api_json\n);
      $retry_counter = 0;
    }
    else {
      $unexpected_counter++;
      print ERR qq(create $object_json\n);
      print ERR qq(UNEXPECTED	$api_json\n);
      &retryCreateTag($object_json);
    }
  } else {
    $failure_counter++;
    print ERR qq(create $object_json\n);
    print ERR "HTTP Error: ", $res->status_line, "\n", $api_json, "\n";
    &retryCreateTag($object_json);
  }
  
# no longer having api retry failures, trying to standardize with other scripts using LWP::UserAgent HTTP::Request
#   my @curl_cmd = (
#     "curl", "-X", "POST", $url,
#     "-H", "accept: application/json",
#     "-H", "Authorization: Bearer $cognito_token",
#     "-H", "Content-Type: application/json",
#     "--data", $object_json,
#   );
#   my $api_json = '';
#   open my $fh, "-|", @curl_cmd or die "Could not run curl: $!";
#   while (my $line = <$fh>) {
#     $api_json .= $line;
#   }
#   close $fh;
#   if ($? != 0 || $api_json !~ /success/) {
#     print ERR qq(create $object_json\n);
#     print ERR qq($api_json\n);
#   }
#   print OUT qq(create $object_json\n);
#   print OUT qq($api_json\n);
#   # $? is the exit status of the last command (0 is success).
#   unless ($api_json) {
#     $retry_counter++;
#     if ($retry_counter > 4) {
#       print ERR qq(api failed without response $retry_counter times, giving up\n);
#       $retry_counter = 0; }
#     else {
#       print ERR qq(api failed $retry_counter times, retrying\n);
#       my $sleep_amount = 4 ** $retry_counter;
#       sleep $sleep_amount;
#       &createTag($object_json); } }
}

sub getSourceId {
  my ($baseUrl, $source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider) = @_;
  my $url = $baseUrl . 'topic_entity_tag/source/' . $source_evidence_assertion . '/' . $source_method . '/' . $data_provider . '/' . $secondary_data_provider;
#   my ($source_type, $source_method) = @_;
#   my $url = $baseUrl . 'topic_entity_tag/source/' . $source_type . '/' . $source_method . '/' . $mod;
  # print qq($url\n);
  my $api_json = `curl -X 'GET' $url -H 'accept: application/json' -H 'Authorization: Bearer $cognito_token' -H 'Content-Type: application/json'`;
  my $hash_ref = decode_json $api_json;
  if ($$hash_ref{'topic_entity_tag_source_id'}) {
    my $source_id = $$hash_ref{'topic_entity_tag_source_id'};
    # print qq($source_id\n);
    return $source_id; }
  else { return ''; }
}

1;
