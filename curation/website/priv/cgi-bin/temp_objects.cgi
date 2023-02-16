#!/usr/bin/env perl

# Create real objects on names service and temp objects in obo_ tables

# Create temp strain and variation objects through the names service via login in through google wormbase.org account.
# If successful add to obo_ tables and obo_tempfile_<datatype>  2020 03 13
# 
# https://names.wormbase.org/api-docs/index.html#/entity
# https://names.wormbase.org/strain/
# https://names.wormbase.org/variation/
#
# test-names.wormbase.org is now a thing, anything not on tazendra will always point to that instead of names.wormbase.org
# 2020 06 08
#
# add a banner div labeling as development site to front page and submit page
# use a json perl hash and JSON::encode_json(\%json) to escape characters to pass to names service
# 2020 06 11


use strict;
use CGI;
use Jex;		# printHeader printFooter getHtmlVar getDate getSimpleDate mailer
use HTTP::Request;
use LWP::UserAgent;	# getting sanger files for querying
use LWP::Simple;	# get the PhenOnt.obo from a cgi
use DBI;
use JSON;
use Dotenv -load => '/usr/lib/.env';

use Sys::Hostname;
my $host = hostname();



my $query = new CGI;	# new CGI form
# my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n";
my $dbh = DBI->connect ( "dbi:Pg:dbname=$ENV{PSQL_DATABASE};host=$ENV{PSQL_HOST};port=$ENV{PSQL_PORT}", "$ENV{PSQL_USERNAME}", "$ENV{PSQL_PASSWORD}") or die "Cannot connect to database!\n";

# &printHeader('New Objects Curation Form');	# normal form view
  print <<"EndOfText";
Content-type: text/html\n\n

<HTML>
<HEAD>
<LINK rel="stylesheet" type="text/css" href="http://minerva.caltech.edu/~azurebrd/stylesheets/wormbase.css">
<title>New Objects Curation Form</title>
  <script type="text/javascript" src="js/jquery-1.9.1.min.js"></script>
  <script type="text/javascript" src="js/jquery.tablesorter.min.js"></script>
  <script type="text/javascript">\$(function() { \$("table").tablesorter({widthFixed: true, widgets: ['zebra']}).tablesorterPager({container: \$("#pager")}); });</script>
</HEAD>

<BODY bgcolor=#aaaaaa text=#000000 link=cccccc alink=eeeeee vlink=bbbbbb>
<HR>
</body></html>

EndOfText

&process();
&printFooter();

sub process {
  my ($var, $action) = &getHtmlVar($query, 'action');
  unless ($action) { $action = ''; }
  if ($action eq '') { &printHtmlMenu(); }		# Display form, first time, no action
  else { 						# Form Button
    print "ACTION : $action : ACTION<BR><BR>\n"; 
    if ($action eq 'submit') {                    &submit(); }
      elsif ($action eq 'Front Page') {           &printHtmlMenu(); }
    print "ACTION : $action : ACTION<BR><br>\n"; 
  } # else # if ($action eq '') { &printHtmlForm(); }
} # sub process

sub submit {
  my ($oop, $datatype)   = &getHtmlVar($query, 'datatype');
  my ($oop, $tokenid)    = &getHtmlVar($query, 'tokenid');
  my ($oop, $email)      = &getHtmlVar($query, 'email');
  my ($oop, $objectname) = &getHtmlVar($query, 'objectname');
  my ($oop, $reason)     = &getHtmlVar($query, 'reason');
  unless ($reason) { $reason = "$email creating $datatype object $objectname from temp_objects.cgi"; }

  my $errorNeedsData = '';
  unless ($datatype) { $errorNeedsData .= qq(Datatype is required<br/>\n); }
  unless ($tokenid) { $errorNeedsData .= qq(Token ID is required \(make sure to login\)<br/>\n); }
  unless ($email) { $errorNeedsData .= qq(wormbase.org email is required \(make sure to login\)<br/>\n); }
  unless ($objectname) { $errorNeedsData .= qq(Object Name is required<br/>\n); }
  if ($errorNeedsData) {
    print $errorNeedsData;
    return;
  }
  my $dev_site = '';
  if ($host !~ m/tazendra/) { $dev_site = '<div style="background-color: red; text-align: center; color: white">development site</div><br/>'; }
  print qq($dev_site);
  print qq(<FORM METHOD="GET" ACTION="temp_objects.cgi">);
  print qq(<INPUT TYPE="submit" NAME="action" VALUE="Front Page">\n);
  print qq(</FORM>\n);

  my $ns_base_url = 'https://test-names.wormbase.org/';
  if ($host =~ m/tazendra/) { $ns_base_url = 'https://names.wormbase.org/'; }

#   my $ns_url = 'https://names.wormbase.org/api/entity/' . $datatype . '/' . $objectname;
  my $ns_url = $ns_base_url . 'api/entity/' . $datatype . '/';
  print qq(URL : $ns_url<br>\n);

#   my $ns_url = 'http://tazendra.caltech.edu/~azurebrd/var/out/';
  my $req = HTTP::Request->new( 'POST', $ns_url );
#   my $req = HTTP::Request->new( 'GET', $ns_url );
  $req->header( 'Content-Type' => 'application/json' );
  my $authorization = 'Token ' . $tokenid;
  $req->header( 'Authorization' => $authorization );
  my $json = '{"data": {"name":"zzfake1"}, "prov": {"why": "testing creating variation", "who": {"email": "juancarlos@wormbase.org"}}}';

# this doesn't escape characters, so fails on " / and other stuff.  Chris tested with WBPaper000XXXX; genotype: blah::' " ` / < > [ ] { } ? , . ( ) * ^ & % $ # @ ! \ | &alpha; &beta; Ω ≈ µ ≤ ≥ ÷ æ … ˚ ∆ ∂ ß œ ∑ † ¥ ¨ ü i î ø π “   ‘ « • – ≠ Å ´ ∏ » ± — ‚ °
#   my $json = { "data" : { "name" : $objectname }, "prov" : { "why" : $reason, "who" : { "email" : $email } } };
#   $req->content( $json );

  my %json;
  $json{"data"}{"name"} = $objectname;
  $json{"prov"}{"why"} = $reason;
  $json{"prov"}{"who"}{"email"} = $email;

  my $json_encoded = encode_json(\%json);

  print qq(JSON $json_encoded JSON<br>\n);
  
  $req->content( $json_encoded );
  my $lwp = LWP::UserAgent->new;
  my $response_href = $lwp->request( $req );
  my $content = $response_href->content;
  my $status = $response_href->status_line;
  print qq(STATUS : $status<br/><br/>\n);
#   my %response = %$response_href;
#   foreach my $key (sort keys %response) {
#     print qq($key : $response{$key}<br>\n);
#   } # foreach my $key (sort keys %response)
  print qq($content<br/><br/>\n);

  my $jsonHash = decode_json( $content );
  if ($status eq '409 Conflict') { 
    print qq(Object already existed, $status result from names service<br/>\n);
#     my $message = $jsonHash->message;
    my $message = $$jsonHash{'message'};
    my ($objId) = $message =~ m/already stored against (.*?)\./;
    print qq($message<br/>\n);
    print qq(Add to postgres, object name to $objId<br>\n);
    &addTempObjectObo($datatype, $objId, $objectname); 
  }
  elsif ($status eq '201 Created') {
    print qq(Created new object, $status result from names service<br/>\n);
#     my $objId = $jsonHash->created->id;
#     my $objName = $jsonHash->created->name;
    my $objId = $$jsonHash{'created'}{'id'};
    my $objName = $$jsonHash{'created'}{'name'};
    print qq(adding $objId + $objName to obo<br>\n);
    &addTempObjectObo($datatype, $objId, $objName); 
  }
  elsif ($status eq '400 Bad Request') { 
    print qq(Error, did not work.  Got back $status from names service<br>\n);
    print qq($content<br/><br/>\n);
  }
  else {
    print qq(Error, unexpected status.  Got back $status from names service<br>\n);
    print qq($content<br/><br/>\n);
  }
} # sub submit

sub addTempObjectObo {
  my ($datatype, $objId, $objName) = @_;
  my $result = $dbh->prepare( "SELECT * FROM obo_name_$datatype WHERE joinkey = '$objId';" ); $result->execute;
  my @row = $result->fetchrow();
  my $entry_error = '';
  if ($row[0]) { $entry_error .= qq($objId already exists associated to $row[1]<br/>\n); }
  $result = $dbh->prepare( "SELECT * FROM obo_name_$datatype WHERE obo_name_$datatype = '$objName';" ); $result->execute;
  @row = $result->fetchrow();
  if ($row[0]) { $entry_error .= qq($objName already exists associated to $row[0]<br/>\n); }
  if ($entry_error) { print $entry_error; next; }
  my $pgDate = &getPgDate();
  my $comment = qq(added through temp_objects.cgi, not updated by geneace yet);
  my $terminfo = qq(id: $objId\nname: "$objName"\ntimestamp: "$pgDate"\ncomment: "$comment");
  $result = $dbh->do( "INSERT INTO obo_name_$datatype VALUES('$objId', '$objName');" );
  $result = $dbh->do( "INSERT INTO obo_data_$datatype VALUES('$objId', '$terminfo');" );
  print "Added $pgDate $objId $objName to obo_name_$datatype and obo_data_$datatype<br/>\n";
  my $obotempfile = '/home/azurebrd/public_html/cgi-bin/data/obo_tempfile_' . $datatype;
  unless (-e $obotempfile) { print "ERROR no obo_tempfile_$datatype to write to at $obotempfile . Contact Juancarlos because $objName + $objId got created in the names service, but it's not in tempfile to update postgres<br/>"; return; }
  open (OUT, ">>$obotempfile") or die "Cannot append to $obotempfile : $!";
  print OUT qq($objId\t$objName\t$pgDate\t$comment\n);
  close (OUT) or die "Cannot append to $obotempfile : $!";
} # sub addTempObjectObo

sub printHtmlMenu {		# show main menu page
  my $dev_site = '';
  if ($host !~ m/tazendra/) { $dev_site = '<div style="background-color: red; text-align: center; color: white">development site</div><br/>'; }
    print <<"    EndOfText";
<html>
<head>
  <meta name="google-signin-scope" content="profile email">
  <meta name="google-signin-client_id" content="514830196757-8464k0qoaqlb4i238t8o6pc6t9hnevv0.apps.googleusercontent.com">
  <!--<meta name="google-signin-client_id" content="514830196757-pd3gel0f74pj3243joa1u63lvcdt2gnd.apps.googleusercontent.com">-->
  <script src="https://apis.google.com/js/platform.js" async defer></script>
</head>
<body>
    <script>
      function onSignIn(googleUser) {
        // Useful data for your client-side scripts:
        var profile = googleUser.getBasicProfile();
//         console.log("ID: " + profile.getId()); // Don't send this directly to your server!
//         console.log('Full Name: ' + profile.getName());
//         console.log('Given Name: ' + profile.getGivenName());
//         console.log('Family Name: ' + profile.getFamilyName());
//         console.log("Image URL: " + profile.getImageUrl());
//         console.log("Email: " + profile.getEmail());
        document.getElementById('email').value = profile.getEmail();
        // The ID token you need to pass to your backend:
        var id_token = googleUser.getAuthResponse().id_token;
        console.log("ID Token: " + id_token);
        document.getElementById('tokenid').value = id_token;
      }
    </script>
    <script src="https://apis.google.com/js/platform.js?onload=renderButton" async defer></script>
    <div class="g-signin2" data-onsuccess="onSignIn" data-theme="dark"></div>
    $dev_site
    <FORM METHOD="GET" ACTION="temp_objects.cgi">
    <TABLE border=0>
    <TR>
    <!--<TR><td>id token</td><td><input name="tokenid" id="tokenid" size="200"></td></tr>-->
    <input type="hidden" name="tokenid" id="tokenid">
    <!--<TR><td>datatype</td><td><input name="datatype" id="datatype" value="variation" size="50"></td></tr>-->
    <!--<TR><td>hostname</td><td>$host</td></tr>-->
    <TR><td>datatype</td><td><select name="datatype" id="datatype" size="2"><option>variation</option><option>strain</option></select></td></tr>
    <TR><TD>object name</td><td><INPUT NAME="objectname" VALUE="" SIZE="50"></TD></tr>
    <TR><TD>reason</td><td><TEXTAREA NAME="reason" VALUE="" ROWS="4" COLS="100"></TEXTAREA></TD></tr>
    <TR><TD>email</td><td><INPUT NAME="email" ID="email" VALUE="" SIZE="50"></TD></tr>
    <TR><TD><INPUT TYPE="submit" NAME="action" VALUE="submit"></TD></tr>
    </TR>
    </TABLE>
    </FORM>

</body>
</html>

    EndOfText
} # sub printHtmlMenu

__END__

<!--
  <div id="my-signin2"></div>
  <script>
    function onSuccess(googleUser) {
      console.log('Logged in as: ' + googleUser.getBasicProfile().getName());
    }
    function onFailure(error) {
      console.log(error);
    }
    function renderButton() {
      gapi.signin2.render('my-signin2', {
        'scope': 'profile email',
        'width': 240,
        'height': 50,
        'longtitle': true,
        'theme': 'dark',
        'onsuccess': onSuccess,
        'onfailure': onFailure
      });
    }
  </script>
-->

WBVar02152877
WBVar02152876
WBVar02152875
WBVar02152873

sub padZeros {
  my $joinkey = shift;
  if ($joinkey =~ m/^0+/) { $joinkey =~ s/^0+//g; }
  if ($joinkey < 10) { $joinkey = '0000000' . $joinkey; }
  elsif ($joinkey < 100) { $joinkey = '000000' . $joinkey; }
  elsif ($joinkey < 1000) { $joinkey = '00000' . $joinkey; }
  elsif ($joinkey < 10000) { $joinkey = '0000' . $joinkey; }
  elsif ($joinkey < 100000) { $joinkey = '000' . $joinkey; }
  elsif ($joinkey < 1000000) { $joinkey = '00' . $joinkey; }
  elsif ($joinkey < 10000000) { $joinkey = '0' . $joinkey; }
  return $joinkey;
} # sub padZeros

sub mail_simple {
  my ($user, $email, $subject, $body) = @_;
  my $command = 'sendmail';
  my $mailer = Mail::Mailer->new($command) ;
  $mailer->open({ From    => $user,
                  To      => $email,
                  Subject => $subject,
                  'MIME-Version' => '1.0',
                "Content-type" => 'text/html; charset=ISO-8859-1',
                })
      or die "Can't open: $!\n";
  print $mailer $body;
  $mailer->close();
} # sub mail_simple

