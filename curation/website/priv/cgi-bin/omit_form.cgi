#!/usr/bin/env perl

# Track IPs, Persons, emails to omit / skip.
#
# for Chris, Valerio.  2020 03 23
#
# Cecilia wants descending timestamp order.  2025 04 28



use strict;
use CGI;
use Jex;		# printHeader printFooter getHtmlVar getDate getSimpleDate mailer
use LWP::UserAgent;	# getting sanger files for querying
use LWP::Simple;	# get the PhenOnt.obo from a cgi
use DBI;
use Email::Send;
use Email::Send::Gmail;
use Email::Simple::Creator;
use Tie::IxHash;
use Dotenv -load => '/usr/lib/.env';

my %curator;
my %curators;                           # $curators{two}{two#} = std_name ; $curators{std}{std_name} = two#

my $query = new CGI;	# new CGI form
my $result;
# my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n";
# my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb;host=131.215.52.76", "", "") or die "Cannot connect to database!\n";
my $dbh = DBI->connect ( "dbi:Pg:dbname=$ENV{PSQL_DATABASE};host=$ENV{PSQL_HOST};port=$ENV{PSQL_PORT}", "$ENV{PSQL_USERNAME}", "$ENV{PSQL_PASSWORD}") or die "Cannot connect to database!\n";

sub printHtmlFooter { print qq(</html>\n); }
sub printHtmlHeader {
  print <<"EndOfText";
Content-type: text/html\n\n

<HTML>
<HEAD>
<LINK rel="stylesheet" type="text/css" href="http://minerva.caltech.edu/~azurebrd/stylesheets/wormbase.css">
<title>Omit Form</title>
  <script type="text/javascript" src="js/jquery-1.9.1.min.js"></script>
  <script type="text/javascript" src="js/jquery.tablesorter.min.js"></script>
  <script type="text/javascript">\$(document).ready(function() { \$("#sortabletable").tablesorter(); } );</script>
  <script>
    function setCookie(name, value) { var expiry = new Date(); expiry.setFullYear(expiry.getFullYear() +10); document.cookie = name + "=" + escape(value) + "; path=/; expires=" + expiry.toGMTString(); }
    function saveCuratorIdInCookieFromSelect(selectElement) { var selectedValue = selectElement.value; setCookie("SAVED_CURATOR_ID", selectedValue); }
  </script>
</HEAD>

<BODY bgcolor=#aaaaaa text=#000000 link=cccccc alink=eeeeee vlink=bbbbbb>
<HR>
</body></html>

EndOfText
} # sub printHtmlHeader


# &printHeader('Community Curation Tracker');
&process();

sub process {
  my ($var, $action) = &getHtmlVar($query, 'action');
  unless ($action) { $action = ''; }
  if ($action eq '') { &printLoginPage(); }		# Display login page, first time, no action
  else { 						# Form Button
    ($var, my $curator_id) = &getHtmlVar($query, 'curator_id');
    if ($curator_id) {
      #&updateCurator($curator_id);
      1;
    } else { &printLoginPage(); return; }

    if ($action eq 'Login') {                 &printHtmlMenu();                         }
      elsif ($action eq 'Main Page') {        &printHtmlMenu();                         }
      elsif ($action eq 'Create Objects') {   &createObjectsPage();                     }
      elsif ($action eq 'View Persons') {     &displayObjectsPage('frm_wbperson_skip'); }
      elsif ($action eq 'View Emails') {      &displayObjectsPage('frm_email_skip');    }
      elsif ($action eq 'View IPs') {         &displayObjectsPage('frm_ip_block');      }
      elsif ($action eq 'Delete Object') {    &deleteObjectPage();      		}
  } # else # if ($action eq '') { &printHtmlForm(); }
  if ($action eq 'text_only_thing') { 1; }
    else { &printHtmlFooter(); }
} # sub process

sub deleteObjectPage {
  my ($var, $curator_id)       = &getHtmlVar($query, 'curator_id');
  ($var, my $table)            = &getHtmlVar($query, 'table');
  ($var, my $object_to_delete) = &getHtmlVar($query, 'object_to_delete');
  &printHtmlHeader();
  &populateCurators();
  print qq(Delete <span style="color: brown">$object_to_delete</span> from <span style="color: brown">$table</span><br/><br/>\n); 
  $result = $dbh->do( "DELETE FROM $table WHERE $table = '$object_to_delete'" );
  &backToMainPage();
  &displayObjects($table); 
  &backToMainPage();
} # sub deleteObjectPage

sub displayObjectsPage {
  my ($table) = @_;
  &printHtmlHeader();
  &populateCurators();
  &backToMainPage();
  &displayObjects($table); 
  &backToMainPage();
} # sub displayObjectsPage

sub backToMainPage {
  my ($var, $curator_id)       = &getHtmlVar($query, 'curator_id');
  print qq(<FORM METHOD="POST" ACTION="omit_form.cgi">\n);
  print qq(<INPUT TYPE=HIDDEN NAME="curator_id" VALUE="$curator_id">);
  print qq(<INPUT TYPE="submit" NAME="action" VALUE="Main Page"><br/>\n); 
  print qq(</FORM>\n);
} # sub backToMainPage

sub displayObjects {
  my ($table) = @_;
  my ($var, $curator_id)       = &getHtmlVar($query, 'curator_id');
  my $result = $dbh->prepare( "SELECT * FROM $table ORDER BY frm_timestamp DESC; " );
  $result->execute;
  print qq(<TABLE border=1>\n);
  while (my @row = $result->fetchrow) {
    my ($object, $curator, $comment, $full_timestamp) = @row;
    my ($timestamp) = $full_timestamp =~ m/^(.*?)\./;
    print qq(<FORM METHOD="POST" ACTION="omit_form.cgi">\n);
    print qq(<INPUT TYPE=HIDDEN NAME="curator_id" VALUE="$curator_id">);
    print qq(<INPUT TYPE=HIDDEN NAME="object_to_delete" VALUE="$object">);
    print qq(<INPUT TYPE=HIDDEN NAME="table" VALUE="$table">);
    print qq(<tr><td>$object</td><td>$comment</td><td>$timestamp</td><td>$curators{two}{$curator}</td>\n);
    print qq(<td><INPUT TYPE="submit" NAME="action" VALUE="Delete Object"></td></tr>\n); 
    print qq(</FORM>\n);
  } # while (my @row = $result->fetchrow)
  print qq(</TABLE>);
  print qq(<br>\n);
} # sub displayObjects

sub createObjectsPage {
  &printHtmlHeader();
  &backToMainPage();
  my ($var, $curator_id) = &getHtmlVar($query, 'curator_id');
  ($var, my $new_data) = &getHtmlVar($query, 'new_data');
  my (@lines) = split/\n/, $new_data;
  foreach my $line (@lines) {
    my ($object, $comment) = ('', '');
    if ($line =~ m/^(\S+)\s(.*)$/) { ($object, $comment) = $line =~ m/^(\S+)\s(.*?)\s*$/; }
      else { $object = $line; }
    my $table = '';
    if ($object =~ m/^WBPerson\d+$/) {                            $table = 'frm_wbperson_skip'; }
      elsif ($object =~ m/^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/) { $table = 'frm_ip_block'; }
      elsif ($object =~ m/@/) {                                   $table = 'frm_email_skip'; ($object) = lc($object); }
    unless ($table) { print qq(<span style="color: red">Skipping</span> because does not match object type : <span style="color: red">$line</span><br/>\n); next; }
    &createObject($table, $curator_id, $object, $comment);
  }
  print qq(<br>\n);
  &backToMainPage();
} # sub createObjectsPage

sub createObject {
  my ($table, $curator_id, $object, $comment) = @_;
  my $pgcomment = $comment;
  $pgcomment =~ s/\'/''/g;
  my $result = $dbh->prepare( "SELECT * FROM $table WHERE $table = '$object';" ); $result->execute; my @row = $result->fetchrow;
  if ($row[0]) { print qq(<span style="color: red">Skipping</span> <span style="color: brown">$object</span> already exists in <span style="color: brown">$table</span><br/>\n); return; }
  print qq(<span style="color: green">Creating</span> <span style="color: brown">$table</span> object <span style="color: brown">$object</span> with comment : <span style="color: brown">$comment</span><br/>); 
  $result = $dbh->do( "INSERT INTO $table VALUES ('$object', '$curator_id', '$pgcomment')" );
} # sub createObject

sub printHtmlMenu {		# show main menu page
  &printHtmlHeader();
  &populateCurators();

  print qq(<FORM METHOD="POST" ACTION="omit_form.cgi">\n);
  my ($var, $curator_id) = &getHtmlVar($query, 'curator_id');
  print qq(Logged in as $curators{two}{$curator_id}.<br/><br/>\n);
  print qq(<INPUT TYPE=HIDDEN NAME="curator_id" VALUE="$curator_id">);
  print qq(<TABLE border=0>\n);


  print <<"  EndOfText";
  <TR>
    <TD COLSPAN=3><B>New entries : </B></TD>
    <TD>Enter one object per line, followed by a space and a comment.<br/>Object in the format WBPerson1234, email address, IP address.<br/>
    <textarea name="new_data" rows="30" cols="90"></textarea><br/>
    <INPUT TYPE="submit" NAME="action" VALUE="Create Objects">
    </TD>
  </TR>
  <TR>
    <TD COLSPAN=3><B>View Persons : </B></TD>
    <TD><INPUT TYPE="submit" NAME="action" VALUE="View Persons"></TD>
  </TR>
  <TR>
    <TD COLSPAN=3><B>View Emails : </B></TD>
    <TD><INPUT TYPE="submit" NAME="action" VALUE="View Emails"></TD>
  </TR>
  <TR>
    <TD COLSPAN=3><B>View IPs : </B></TD>
    <TD><INPUT TYPE="submit" NAME="action" VALUE="View IPs"></TD>
  </TR>
  EndOfText
  print "</TABLE>\n";
  print "</FROM>\n";
} # sub printHtmlMenu

sub printLoginPage {
  &printHtmlHeader();
  print qq(<FORM METHOD="POST" ACTION="omit_form.cgi">\n);
  print qq(<TABLE border=0>\n);

  &populateCurators();

  my $saved_curator = &readSavedCuratorFromCookie();

#   my @curator_list = qw( two1823 two2987 two1 two1843 );	# Marie-Claire and Jane Mendel, removed 2020 03 20
  my @curator_list = qw( two1823 two2987 two1 two12028 two1843 );	# Daniela added, 2020 04 09
  my $select_size = scalar @curator_list + 1;
  print "<tr><td colspan=\"3\"><b>Select your Name : </b></td><td><select name=\"curator_id\" onChange=\"saveCuratorIdInCookieFromSelect(this)\" size=\"$select_size\">\n";
  print "<option value=\"\"></option>\n";
  foreach my $joinkey (@curator_list) {                         # display curators in alphabetical (array) order, if IP matches existing ip record, select it
    my $curator = 0;
    if ($curators{two}{$joinkey}) { $curator = $curators{two}{$joinkey}; }
    if ($joinkey eq $saved_curator) { print "<option value=\"$joinkey\" selected=\"selected\">$curator</option>\n"; }
      else { print "<option value=\"$joinkey\" >$curator</option>\n"; } }
  print "</select><br/>\n";
  print qq(<INPUT TYPE="submit" NAME="action" VALUE="Login">\n);
  print qq(</td></tr>);
  print "</table>\n";
  print "</form>\n";
} # sub printLoginPage


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


sub populateCurators {
  my $result = $dbh->prepare( "SELECT * FROM two_standardname; " );
  $result->execute;
  while (my @row = $result->fetchrow) {
    $curators{two}{$row[0]} = $row[2];
    $curators{std}{$row[2]} = $row[0];
  } # while (my @row = $result->fetchrow)
} # sub populateCurators

#sub updateCurator {
#  my ($joinkey) = @_;
#  my $ip = $query->remote_host();
#  my $result = $dbh->prepare( "SELECT * FROM two_curator_ip WHERE two_curator_ip = '$ip' AND joinkey = '$joinkey';" );
#  $result->execute;
#  my @row = $result->fetchrow;
#  unless ($row[0]) {
#    $result = $dbh->do( "DELETE FROM two_curator_ip WHERE two_curator_ip = '$ip' ;" );
#    $result = $dbh->do( "INSERT INTO two_curator_ip VALUES ('$joinkey', '$ip')" );
#     print "IP $ip updated for $joinkey<br />\n";
#  } }



