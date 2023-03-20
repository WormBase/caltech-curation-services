#!/usr/bin/env perl 

# Form to sign up for 2020-2021 webinars

# Added links to slides and video for first webinar.  2020 10 29
#
# Option to send emails locally from 'wormbase-webinar@mangolassi.caltech.edu'
# which forwards to the outreach@wormbase.org account.  Because a mass mailing
# to all PIs might have too many people signing up for the webinar.  
# Grey out text of past webinars, and replace checkbox with hidden input.
# 2020 11 03
#
# Change attendance maximum to 400 from 300.  2020 11 16
#
# Password file set at $ENV{CALTECH_CURATION_FILES_INTERNAL_PATH} . '/insecure/outreachwormbase';
# 2023 03 19

# http://mangolassi.caltech.edu/~azurebrd/cgi-bin/forms/webinar.cgi
# http://mangolassi.caltech.edu/~azurebrd/cgi-bin/forms/webinar.cgi?action=registeredCount



use Jex;			# untaint, getHtmlVar, cshlNew
use strict;
use CGI;
use Fcntl;
use DBI;
use Tie::IxHash;
use LWP::Simple;
use File::Basename;		# fileparse
# use Mail::Sendmail;
use Email::Send;
use Email::Send::Gmail;
use Email::Simple::Creator;
use Net::Domain qw(hostname hostfqdn hostdomain);
use Dotenv -load => '/usr/lib/.env';


my $hostfqdn = hostfqdn();

# my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n";
my $dbh = DBI->connect ( "dbi:Pg:dbname=$ENV{PSQL_DATABASE};host=$ENV{PSQL_HOST};port=$ENV{PSQL_PORT}", "$ENV{PSQL_USERNAME}", "$ENV{PSQL_PASSWORD}") or die "Cannot connect to database!\n";
my $result;




my $query = new CGI;
my %fields;
tie %fields, "Tie::IxHash";
my %dropdown;
tie %dropdown, "Tie::IxHash";
my %webinars;
tie %webinars, "Tie::IxHash";



my %mandatoryToLabel;
# $mandatoryToLabel{'mandatory'}  = '<span style="color: red">M</span>';
# $mandatoryToLabel{'anyanatomy'} = '<span style="color: #06C729">A</span>';
# $mandatoryToLabel{'internal'}   = '<span style="color: grey">I</span>';
# $mandatoryToLabel{'optional'}   = '';
# $mandatoryToLabel{'transgene'}  = '';
# $mandatoryToLabel{'construct'}  = '';
# # $mandatoryToLabel{'optional'}   = '<span style="color: black">O</span>';
# # $mandatoryToLabel{'transgene'}  = '<span style="color: brown">T</span>';
# # $mandatoryToLabel{'construct'}  = '<span style="color: orange">C</span>';
my %mandatoryToClass;
# $mandatoryToClass{'transgene'}  = 'mandatory_method mandatory_method_transgene';
# $mandatoryToClass{'construct'}  = 'mandatory_method mandatory_method_construct';
my %fieldToClass;
# $fieldToClass{'transgene'}  = 'field_method field_method_transgene';
# $fieldToClass{'construct'}  = 'field_method field_method_construct';

my $title = 'WormBase Webinar sign up form';
my ($header, $footer) = &cshlNew($title);
# $header = "<html><head></head>";
# $header .= qq(<img src="/~acedb/draciti/Micropublication/uP_logo.png"><br/>\n);		# logo for Daniela
# $footer = "</body></html>";
&addJavascriptCssToHeader();


my $var;
($var, my $action) = &getHtmlVar($query, 'action');
unless ($action) { $action = 'showStart'; }			# by default show the start of the form

if ($action) {
  &initWebinarInfo();
  &initFields();
  if ($action eq 'showStart') {                              &showStart();            }
    elsif ($action eq 'updateRegistration') {                &updateRegistration();   }
    elsif ($action eq 'registeredCount') {                   &registeredCount();      }
    elsif ($action eq 'registeredWebinar') {                 &registeredWebinar();    }
    elsif ($action eq 'autocompleteXHR') {                   &autocompleteXHR();      }
    elsif ($action eq 'asyncTermInfo') {                     &asyncTermInfo();        }
    elsif ($action eq 'Submit') {                            &submit('submit');       }
#     elsif ($action eq 'Preview') {                           &submit('preview');      }
#     elsif ($action eq 'Save for Later') {                    &submit('save');         }
#     elsif ($action eq 'Load') {                              &load();                 }
#     elsif ($action eq 'pmidToTitle') {                       &pmidToTitle();          }
#     elsif ($action eq 'asyncFieldCheck') {                   &asyncFieldCheck();      }
#     elsif ($action eq 'preexistingData') {                   &preexistingData();      }
#     elsif ($action eq 'personPublication') {                 &personPublication();    }
#     elsif ($action eq 'emailFlagFirstpass') {                &emailFlagFirstpass();   }
#     elsif ($action eq 'noNematodePhenotypes') {              &noNematodePhenotypes(); }
#     elsif ($action eq 'bogusSubmission') {                   &bogusSubmission();      }
    else {                                                   &showStart();            }
}

sub tableDisplayArray {
  my (@fields) = @_;
  my $formdata = '';
  my $amount      = $fields{$fields[0]}{multi};
  for my $i (1 .. $amount) {
    my $trHasvalue = 0; my $trData = '';
    foreach my $field (@fields) {
      my $label       = $fields{$field}{label};
      my $inputvalue  = $fields{$field}{inputvalue}{$i};
      my $termidvalue = $fields{$field}{termidvalue}{$i};
      my @inputtermidvalue;
      if ($inputvalue) {  push @inputtermidvalue, $inputvalue;  }
      if ($termidvalue) { push @inputtermidvalue, $termidvalue; }
      my $inputtermidvalue = join" -- ", @inputtermidvalue; 
      if ($fields{$field}{type} eq 'radio') {			# radio buttons should use button label
        $inputtermidvalue = $fields{$field}{values}{$inputvalue}; }
#       if ($label) { $trData .= qq(<td>$label</td><td>$inputtermidvalue</td>\n); }	# if wanted to always add labels without data, sometimes personal communication is confusing.
      if ($inputtermidvalue) { $trData .= qq(<td>$label</td><td style ="overflow: hidden; text-overflow:ellipsis; max-width: 500px;">$inputtermidvalue</td>\n); }	# only add to table row if there's data, to keep confusion between labels and data
      if ($inputtermidvalue) { $trHasvalue++; }	# if input or termid of any field in the field, row has data
    } # foreach my $field (@fields)
      if ($trHasvalue) { $formdata .= qq(<tr>$trData</tr>\n); }
  } # for my $i (1 .. $amount)
  return $formdata;
} # sub tableDisplayArray

sub submit {
  my ($submit_flag) = @_;
  print "Content-type: text/html\n\n";
  print $header;
  print qq(<span style="font-size: 24pt;">Registration for 2020 - 2021 WormBase Webinars</span><br/><br/>\n);

  foreach my $field (keys %fields) {
    my $amount = $fields{$field}{multi};
    for my $i (1 .. $amount) {
      my ($var, $inputvalue)  = &getHtmlVar($query, "input_${i}_$field");
      ($var, my $termidvalue) = &getHtmlVar($query, "termid_${i}_$field");
      if ($inputvalue) { 
        $fields{$field}{inputvalue}{$i} = $inputvalue;
        if ($i > $fields{$field}{hasdata}) { $fields{$field}{hasdata} = $i; }
      }
      if ($termidvalue) { 
        $fields{$field}{termidvalue}{$i} = $termidvalue;
        if ($i > $fields{$field}{hasdata}) { $fields{$field}{hasdata} = $i; }
      } # if ($termidvalue) 
    } # for my $i (1 .. $amount)
  } # foreach my $field (keys %fields)
#   if ($fields{allele}{inputvalue}{1}) {			# sometimes allele names are typed without selecting a wbvariation, but they map to wbvariation
#     unless ($fields{allele}{termidvalue}{1}) {
#       $result = $dbh->prepare( "SELECT * FROM obo_name_variation WHERE obo_name_variation = '$fields{allele}{inputvalue}{1}';" );
#       $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; my @row = $result->fetchrow();
#       if ($row[0]) { $fields{allele}{termidvalue}{1} = $row[0]; } } }
#   for my $i (1 .. $fields{cloneseqgene}{multi}) {
#     unless ($fields{cloneseqgene}{inputvalue}{$i}) {		# if there is no rnai, its species should be blank (not generalized for other fields) 2016 02 18
#       $fields{cloneseqspecies}{inputvalue}{$i} = ''; $fields{cloneseqspecies}{termidvalue}{$i} = ''; } }

#   my @webinarKeys = reverse sort keys %webinars;
#   my $webinarAmount = shift @webinarKeys;

#   my $webinarAmount = $fields{webinars}{multi};
#   my %attending;
#   for my $j (1 .. $webinarAmount) {
#     my ($var, $inputvalue)  = &getHtmlVar($query, "input_${j}_webinars");
#     $fields{webinars}{inputvalue}{$j} = $inputvalue;
#     if ($inputvalue) { $attending{$j}++; }
#   }
#   my $attending = join", ", sort keys %attending;
# #   print qq(Attending $attending<br>);
    
  my $form_data  = qq(<table border="1" cellpadding="5">);
  $form_data    .= &tableDisplayArray('person'); 
  $form_data    .= &tableDisplayArray('email');  

#   foreach my $j (sort keys %attending) {
  foreach my $j (sort keys %{ $fields{webinars}{inputvalue} }) {
    next unless $fields{webinars}{inputvalue}{$j};
    my $color = 'black'; my $disabled = '';
    if ($webinars{$j}{'disabled'} eq 'disabled') { $color = 'grey'; $disabled = 'disabled="disabled"'; }
    $form_data .= qq(<tr><td>Webinar $j</td>);
    $form_data .= qq(<td colspan="1" style="width: 175px; max-width: 175px; min-width: 175px;">$webinars{$j}{'date'}</td>);
    $form_data .= qq(<td colspan="1" style="width: 175px; max-width: 175px; min-width: 175px;">$webinars{$j}{'time'}</td>);
    $form_data .= qq(<td colspan="1" style="width: 175px; max-width: 450px; min-width: 450px;">$webinars{$j}{'topic'}</td>);
    $form_data .= qq(<td colspan="1" style="width: 175px; max-width: 400px; min-width: 275px;">$webinars{$j}{'speaker'}</td>);
    $form_data .= qq(<td colspan="1" style="width: 175px; max-width: 175px; min-width: 175px;">$webinars{$j}{'slides'}</td>);
    $form_data .= qq(<td colspan="1" style="width: 175px; max-width: 175px; min-width: 175px;">$webinars{$j}{'video'}</td>);
    $form_data .= qq(</tr>);
  }
  $form_data    .= qq(</table><br/><br/>);

    # on any submission action, update the person / email for the user's IP address
  &updateUserIp( $fields{person}{termidvalue}{1}, $fields{email}{inputvalue}{1} );
    # if the form has no person id, try to load from postgres by ip address.  removed 2018 10 18 for Chris
#   unless ($fields{person}{termidvalue}{1}) {
#     ( $fields{person}{termidvalue}{1}, $fields{person}{inputvalue}{1}, $fields{email}{termidvalue}{1} ) = &getUserByIp(); }

  if ($submit_flag eq 'submit') { 
      my $mandatoryFail = &checkMandatoryFields();
      if ($mandatoryFail) { 
          print $form_data;
          &showForm(); }
        else {
#           &deletePg($fields{origip}{inputvalue}{1}, $fields{origtime}{inputvalue}{1});	# if had save files, this would delete
          my $messageToUser = qq(Dear $fields{person}{inputvalue}{1}, you are successfully registered for the following WormBase Webinars.<br/>);
#           my $updateUrl = 'http://' . $hostfqdn . "/~azurebrd/cgi-bin/forms/webinar.cgi?action=updateRegistration&email=$fields{email}{inputvalue}{1}";
          my $updateUrl = $ENV{THIS_HOST} . "pub/cgi-bin/forms/webinar.cgi?action=updateRegistration&email=$fields{email}{inputvalue}{1}";
          $messageToUser .= qq(We will send you virtual meeting information 48 hours before the meeting time.<br/>);
          $messageToUser .= qq(To update your registration choices, click <a href="$updateUrl">here</a>.<br/>);
          print qq($messageToUser<br/>);
#           print qq(<br/>Return to the <a href="phenotype.cgi">Phenotype Form</a>.<br/>\n);
#           print qq(<br/>To pre-populate the form with entries from this submission, <a href="javascript:history.back()">click here</a>.<br/>\n);
# TODO ADD THIS
          my ($form_data, $messageChanges) = &writePgOaAndEmail($messageToUser, $form_data);
          print qq(<br/>$messageChanges);
          print qq(<br/>$form_data);
          print qq(An email has been sent to you, should you wish to change your registration.<br/>If you do not get a confirmation email within 15 minutes, please contact <a href="mailto:outreach\@wormbase.org">outreach\@wormbase.org</a><br/>);
        }
    }
#     elsif ($submit_flag eq 'preview') { 
#       my $mandatoryFail = &checkMandatoryFields();
# #       print qq(<br/><b>Preview -</b> scroll down to continue filling out the form<br/><br/>\n);
#       print $form_data;
#       print qq(<br/><b>Preview -</b> Please review the data for your submission above. If you would like to make edits, please do so in the form below. If you are finished adding data to the form, please click Submit.<br/><br/>\n);
#       &showForm();
#     }
} # sub submit

sub writePgOaAndEmail {		# tacking on email here since need pgids from pg before emailing
  my ($messageToUser, $form_data)   = @_;
  my $ip            = &getIp();
  my $timestamp     = &getPgDate();
  my $person        = $fields{person}{termidvalue}{1};
  my $personName    = $fields{person}{inputvalue}{1};
  if ($personName =~ m/\'/) { $personName =~ s/\'/''/g; }                 # escape singlequotes
  my $email         = $fields{email}{inputvalue}{1};
  unless ($person) { $person = ''; }

  my %oaSeminarCount;
  $result = $dbh->prepare( "SELECT seminar, COUNT(*) AS count FROM sem_data WHERE going = 'going' GROUP BY seminar HAVING COUNT(*) > 0;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) { $oaSeminarCount{$row[0]} = $row[1]; }

  my %oaPreviousPlacement;
  foreach my $j (1 ..  $fields{webinars}{multi}) {
    if ($fields{webinars}{inputvalue}{$j} == $j) {
      my $timestamp = 0;
      $result = $dbh->prepare( "SELECT sem_timestamp FROM sem_data WHERE email = '$email' AND going = 'going' AND seminar = '$j';" );
      $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
      my @row = $result->fetchrow();
      if ($row[0]) { $timestamp = $row[0]; }
      if ($timestamp) {						# person had registered before
#         print qq( "SELECT COUNT(*) FROM sem_data WHERE going = 'going' AND seminar = '$j' AND sem_timestamp < '$timestamp';" <br>);
        $result = $dbh->prepare( "SELECT COUNT(*) FROM sem_data WHERE going = 'going' AND seminar = '$j' AND sem_timestamp < '$timestamp';" );
        $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
        my $previousPlacement = 1;				# placement was at least 1
        my @row = $result->fetchrow();
        if ($row[0]) { $previousPlacement = $row[0] + 1; }	# this many people before them + 1 for new placement
        $oaPreviousPlacement{$j} = $previousPlacement;
      } # if ($timestamp)
    }
  }

  my %oaRegistered;
  $result = $dbh->prepare( "SELECT * FROM sem_data WHERE email = '$email'" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) { $oaRegistered{$row[3]} = $row[4]; }

  my $maxPerSeminar = 400;
  my $messageChanges = '';
  my @pgcommands;
  foreach my $j (1 ..  $fields{webinars}{multi}) {
    my $going = 0; my $wasGoing = 0;
    if ($fields{webinars}{inputvalue}{$j} == $j) { $going = 1; }
    if ($oaRegistered{$j} eq 'going') { $wasGoing = 1; }
#     $messageChanges .= qq(J $j G $going WG $wasGoing  E<br>);
    if ($going == 1) {		# Add to list
      my $currentPlacement = $oaSeminarCount{$j} + 1;
      if ($oaPreviousPlacement{$j}) { $currentPlacement = $oaPreviousPlacement{$j}; }
# print qq(J $j currentPlacement $currentPlacement oaPreviousPlacement $oaPreviousPlacement{$j} E<br>);
      if ($currentPlacement <= $maxPerSeminar) {
          $form_data =~ s/Webinar $j/<span style='color: green'>Attending<\/span>/; }
        else {
          my $waitListCount = $currentPlacement - $maxPerSeminar;
          $form_data =~ s/Webinar $j/<span style='color: red'>#$waitListCount on the waitlist<\/span>/; }
      if ($wasGoing == 0) { 
        push @pgcommands, qq(INSERT INTO sem_data     VALUES ('$email', '$personName', '$person', '$j', 'going', '$ip', '$timestamp'););
        push @pgcommands, qq(INSERT INTO sem_data_hst VALUES ('$email', '$personName', '$person', '$j', 'going', '$ip', '$timestamp'););
      }
    } # if ( ($going == 1) && ($wasGoing == 0) )
    if ( ($going == 0) && ($wasGoing == 1) ) {		# Remove from list
      $messageChanges .= qq(<span style='color: red'>No longer attending</span> Webinar $j : $webinars{$j}{'topic'}<br/>);
      push @pgcommands, qq(DELETE FROM sem_data WHERE email = '$email' AND seminar = '$j';);
      push @pgcommands, qq(INSERT INTO sem_data_hst VALUES ('$email', '$personName', '$person', '$j', 'not_going', '$ip', '$timestamp'););
    } # if ( ($going == 1) && ($wasGoing == 0) )
  } # foreach my $j (1 ..  $fields{webinars}{multi})

  foreach my $pgcommand (@pgcommands) {
#     print qq($pgcommand<br>);
    $result = $dbh->do( $pgcommand );
  }



  my $user = 'outreach@wormbase.org';
  my $subject = 'WormBase Webinar Confirmation';		# subject of mail
  my $body = $messageToUser;					# message to user shown on form
  $body .= qq($messageChanges<br/>\n);	# additional link to report false data
  $body .= $form_data;						# form data
# UNCOMMENT send general emails
  my $cc = '';
  &mailSendmail($user, $email, $subject, $body);
  return ($form_data, $messageChanges);
} # sub writePgOaAndEmail


# CREATE TABLE sem_data ( email text, name text, wbperson text, seminar text, going text, ip text, sem_timestamp timestamp with time zone DEFAULT "timestamp"('now'::text));
# CREATE INDEX sem_data_idx ON sem_data USING btree (seminar);
# CREATE TABLE sem_data_hst ( email text, name text, wbperson text, seminar text, going text, ip text, sem_timestamp timestamp with time zone DEFAULT "timestamp"('now'::text));
# CREATE INDEX sem_data_hst_idx ON sem_data USING btree (seminar);
# GRANT ALL ON TABLE sem_data TO azurebrd;
# GRANT ALL ON TABLE sem_data TO apache;
# GRANT ALL ON TABLE sem_data TO "www-data";
# GRANT ALL ON TABLE sem_data_hst TO azurebrd;
# GRANT ALL ON TABLE sem_data_hst TO apache;
# GRANT ALL ON TABLE sem_data_hst TO "www-data";

# INSERT INTO sem_data VALUES ('azurebrd@tazendra.caltech.edu', 'Juancarlos', NULL, '9', 'going', '131.215.52.76');
# INSERT INTO sem_data VALUES ('bob@oop.com', 'bob', NULL, '9', 'going', '131.215.52.76');
# INSERT INTO sem_data VALUES ('boa@oop.com', 'bob', NULL, '9', 'going', '131.215.52.76');
# INSERT INTO sem_data VALUES ('boo@oop.com', 'bob', NULL, '9', 'not_going', '131.215.52.76');
# INSERT INTO sem_data VALUES ('boc@oop.com', 'bob', NULL, '9', 'going', '131.215.52.76');
# INSERT INTO sem_data VALUES ('bod@oop.com', 'bob', NULL, '9', 'going', '131.215.52.76');

# DROP TABLE sem_data;
# DROP TABLE sem_data_hst;


sub registeredWebinar {
  print "Content-type: text/html\n\n";
  print $header;
  print qq(<span style="font-size: 24pt;">Registration for 2020 - 2021 WormBase Webinars</span><br/><br/>\n);

  ($var, my $seminar)  = &getHtmlVar($query, "seminar");	
  print qq(<table border="1"><tr><th>Date</th><th>Time</th><th>Topic</th><th>Speaker</th></tr>);
  print qq(<td style="width: 175px; max-width: 175px; min-width: 175px;">$webinars{$seminar}{'date'}</td>);
  print qq(<td style="width: 100px; max-width: 100px; min-width: 100px;">$webinars{$seminar}{'time'}</td>);
  print qq(<td style="width: 175px; max-width: 450px; min-width: 450px;">$webinars{$seminar}{'topic'}</td>);
  print qq(<td style="width: 175px; max-width: 400px; min-width: 275px;">$webinars{$seminar}{'speaker'}</td>);
  print qq(<td style="width: 100px; max-width: 100px; min-width: 100px;">$webinars{$seminar}{'slides'}</td>);
  print qq(<td style="width: 100px; max-width: 100px; min-width: 100px;">$webinars{$seminar}{'video'}</td>);
  print qq(</table><br/><br/>);

  $result = $dbh->prepare( "SELECT * FROM sem_data WHERE seminar = '$seminar' AND going = 'going' ORDER BY sem_timestamp" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  print qq(<table border="1"><tr><th>Count</th><th>Email</th><th>Name</th><th>WBPerson</th><th>Seminar</th><th>Going</th><th>IP</th><th>Timestamp</th></tr>);
  my $count = 0;
  while (my @row = $result->fetchrow) {
#     my ($email, $name, $wbperson, $seminar, $going, $ip, $timestamp) = @row;
    my $htmlRow = join"</td><td>", @row;
    $count++;
    print qq(<tr><td>$count</td><td>$htmlRow</td></tr>);
  }
  print qq(</table>);
  print $footer;
} # sub registeredWebinar {

sub registeredCount {
  print "Content-type: text/html\n\n";
  print $header;
  print qq(<span style="font-size: 24pt;">Registration for 2020 - 2021 WormBase Webinars</span><br/><br/>\n);
  my $webinarAmount = $fields{webinars}{multi};
  print qq(<table border="0"><tr><th>Registered</th><th>Date</th><th>Time</th><th>Topic</th><th>Speaker</th></tr>);
  for my $j (1 .. $webinarAmount) {
    my $count = 0;
    $result = $dbh->prepare( "SELECT COUNT(*) FROM sem_data WHERE going = 'going' AND seminar = '$j'" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
    my @row = $result->fetchrow(); 
    if ($row[0]) { $count = $row[0]; }
    print qq(<tr>);
    # my $url = 'http://' . $hostfqdn .  "/~azurebrd/cgi-bin/forms/webinar.cgi?action=registeredWebinar&seminar=$j";
    my $url = $ENV{THIS_HOST} . "pub/cgi-bin/forms/webinar.cgi?action=registeredWebinar&seminar=$j";
    print qq(<td align="center"><a href="$url">$count</a></td>);
    print qq(<td style="width: 175px; max-width: 175px; min-width: 175px;">$webinars{$j}{'date'}</td>);
    print qq(<td style="width: 100px; max-width: 100px; min-width: 100px;">$webinars{$j}{'time'}</td>);
    print qq(<td style="width: 175px; max-width: 450px; min-width: 450px;">$webinars{$j}{'topic'}</td>);
    print qq(<td style="width: 175px; max-width: 400px; min-width: 275px;">$webinars{$j}{'speaker'}</td>);
    print qq(<td style="width: 100px; max-width: 100px; min-width: 100px;">$webinars{$j}{'slides'}</td>);
    print qq(<td style="width: 100px; max-width: 100px; min-width: 100px;">$webinars{$j}{'video'}</td>);
    print qq(</tr>);
  }
  print qq(</table>);
  print $footer;
} # sub registeredCount

sub updateRegistration {
  ($var, my $email)  = &getHtmlVar($query, "email");	
  $result = $dbh->prepare( "SELECT * FROM sem_data WHERE email = '$email'" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
    my ($email, $name, $wbperson, $seminar, $going, $ip, $timestamp) = @row;
    $fields{person}{termidvalue}{1} = $wbperson;
    $fields{person}{inputvalue}{1}  = $name;
    $fields{email}{inputvalue}{1}   = $email;
    if ($going eq 'going') { 
      $fields{webinars}{inputvalue}{$seminar} = $seminar; }
  } # while (my @row = $result->fetchrow)
  &showStart();
}

sub showStart {
  print "Content-type: text/html\n\n";
  print $header;
  print qq(<span style="font-size: 24pt;">Registration for 2020 - 2021 WormBase Webinars</span><br/><br/>\n);
#   print qq(<span>We would appreciate your help in adding phenotype data from published papers to WormBase.<br/>Please fill out the form below. <b>Watch a short video tutorial <a style='font-weight: bold; text-decoration: underline;' href="https://www.youtube.com/watch?v=_gd87S1h3zg&feature=youtu.be" target="_blank">here</a> or read the user guide <a style='font-weight: bold; text-decoration: underline;' href="http://wiki.wormbase.org/index.php/Contributing_Phenotype_Connections" target="_blank">here</a></b>.<br/>If you would prefer to fill out a spreadsheet with this information, please download and fill out our<br/><a href="https://dl.dropboxusercontent.com/u/4290782/WormBase_Phenotype_Worksheet.xlsx" target="_blank">WormBase Phenotype Worksheet</a> and e-mail as an attachment to <a href="mailto:curation\@wormbase.org">curation\@wormbase.org</a><br/>If you have any questions, please do not hesitate to contact WormBase at <a href="mailto:help\@wormbase.org">help\@wormbase.org</a></span><br/><br/>\n);
#   print qq(<span>We would appreciate your help in adding phenotype data from published papers to WormBase.<br/>Please fill out the form below. <b>Read the user guide <a style='font-weight: bold; text-decoration: underline;' href="http://wiki.wormbase.org/index.php/Contributing_Phenotype_Connections" target="_blank">here</a></b>.<br/>If you would prefer to fill out a spreadsheet with this information, please download and fill out our<br/><a href="http://tazendra.caltech.edu/~acedb/chris/WormBase_Phenotype_Worksheet.xlsx" target="_blank">WormBase Phenotype Worksheet</a> and e-mail as an attachment to <a href="mailto:curation\@wormbase.org">curation\@wormbase.org</a><br/>If you have any questions, please do not hesitate to contact WormBase at <a href="mailto:help\@wormbase.org">help\@wormbase.org</a></span><br/><br/>\n);

#   print qq(<span>We will send you virtual meeting information 48 hours before the meeting time. For more information about the webinars, please contact <a href="mailto:outreach\@wormbase.org">outreach\@wormbase.org</a></span><br/><br/>\n);
  print qq(<span>Each webinar is one hour long, including Q&amp;A.  We can only accommodate 400 attendees, so please sign up only for those you intend to attend. Webinars will be recorded and published on the <a href="https://www.youtube.com/user/WormBaseHD">WormBase YouTube</a> channel.</span><br/>\n);
  print qq(Start typing and select your name from the list of registered WormBase persons and IDs. If you do not have a WBPerson ID, we encourage you to fill out our <a href="http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/person.cgi" target="new">Person Update Form</a>.<br/>\n);
  my $browser = $ENV{HTTP_USER_AGENT};
  if ($browser =~ m/safari/i) { 
    unless ( ($browser =~ m/chrome/i) || ($browser =~ m/firefox/i) ) {
      print qq(Safari users please note: Safari's 'Autofill' feature may not properly populate the name field in this form.<br/><br/>\n); } }
    # initialize originalIP + originalTime, processing uploads requires them. %fields processing will replace with form values from 'hidden' group before upload field(s).
  unless ($fields{hidden}{field}{origip}{inputvalue}{1}) {     $fields{hidden}{field}{origip}{inputvalue}{1}   = $query->remote_host(); }
  unless ($fields{hidden}{field}{origtime}{inputvalue}{1}) {   $fields{hidden}{field}{origtime}{inputvalue}{1} = time;                  }
    # if IP corresponds to an existing user, get person and email data.  removed 2018 10 18 for Chris
#   unless ($fields{person}{termidvalue}{1}) {
#     ( $fields{person}{termidvalue}{1}, $fields{person}{inputvalue}{1}, $fields{email}{inputvalue}{1} ) = &getUserByIp(); }
#   ($var, my $pmid)        = &getHtmlVar($query, "input_1_pmid");	# if linking here from personPublication table
  ($var, my $personName)  = &getHtmlVar($query, "input_1_person");	# if linking here from personPublication table
  ($var, my $personId)    = &getHtmlVar($query, "termid_1_person");	# if linking here from personPublication table
  ($var, my $personEmail) = &getHtmlVar($query, "input_1_email");	# if linking here from personPublication table
#   if ($pmid) {        $fields{pmid}{inputvalue}{1}    = $pmid;        }
  if ($personName) {  $fields{person}{inputvalue}{1}  = $personName;  }
  if ($personId) {    $fields{person}{termidvalue}{1} = $personId;    }
  if ($personEmail) { $fields{email}{inputvalue}{1}   = $personEmail; }
  &showForm();
  print $footer;
} # sub showStart

sub showEditorActions {
#   print qq(<input type="submit" name="action" value="Preview" >&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;\n);
  print qq(<input type="submit" name="action" value="Submit">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;\n);
#   print qq(<button onclick="location.href = 'webinar.cgi';">Reset</button>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;\n);
} # sub showEditorActions


sub printPersonField {         printArrayEditorNested('person');    }
sub printEmailField {          printArrayEditorNested('email');     }
sub printWebinarsField {
  # $fields{$fields[0]}{multi}; has the amount of webinars, but it would print one of each group if going through printArrayEditorNested
  my $i = 1; my $field = 'webinars';
  my $trToPrint = qq(<tr id="group_${i}_${field}">\n);
#   my $td_label .= &printEditorLabel($i, $field);
  my $colspan = 2; my $td_indent = ''; # if ($j > 0) { $td_indent .= qq(<td></td>); $colspan = 2; }
  my $td_text = &printEditorCheckboxTable($field, $colspan);
  $trToPrint .= qq(<tr><td>&nbsp;</td></tr>\n);
  $trToPrint .= $td_indent; 
#   $trToPrint .= $td_label; 
  $trToPrint .= $td_text; 
  $trToPrint    .= qq(</tr>\n);
  print $trToPrint;
}

sub printArrayEditorNested {
  my (@fields) = @_;
  my $amount      = $fields{$fields[0]}{multi};
  for my $i (1 .. $amount) {
    my $showAmount  = 1;
    if ($fields{$fields[0]}{startHidden} eq 'startHidden') { $showAmount = 0; }	# if main field in group starts hidden, whole group starts hidden
#     foreach my $field (@fields)
    foreach my $j (0 .. $#fields) {
      my $fieldLeader = $fields[0];				# the first field determines whether to show indented fields
      my $field       = $fields[$j];
      if ($fields{$field}{startHidden} eq 'startHidden') { $showAmount = 0; }	# if sub field in group starts hidden, only sub field starts hidden
      my $group_style = ''; if ($i > $showAmount) { $group_style = 'display: none'; }
      my $showThreshold = $fields{$fieldLeader}{hasdata} + 0 + $showAmount; 	# threshold is amount that have data + 1 + amount to show
      if ($fields{$fieldLeader}{hasdata}) { $showThreshold += 1; }		# if field has data, show one more blank one
      if ($i < $showThreshold) { $group_style = ''; }
      my $trToPrint = qq(<tr id="group_${i}_${field}" style="$group_style">\n);
#       my $trToPrint = qq(<tr id="group_${i}_${field}" ><td>I $i FL $fieldLeader HD $fields{$fieldLeader}{hasdata} SA $showAmount ST $showThreshold GS $group_style</td>\n);
#       my $trToPrint = qq(<tr id="group_${i}_${field}" ><td>I $i HD $fields{$fieldLeader}{hasdata} SA $showAmount ST $showThreshold </td>\n);
      if ($i == 1) {						# on the first row, show the field information for javascript
          $trToPrint .= qq(<input type="hidden" class="fields" value="$field" />\n);
          my $data = '{ ';                                                    # data is { 'tag' : 'value', 'tag2' : 'value2' } format javascript stuff
          foreach my $tag (sort keys %{ $fields{$field} }) {
            my $tag_value = $fields{$field}{$tag};
# print qq(J $j I $i FIELD $field TAG $tag TV $tag_value E<br>);
            next if ($tag eq 'pg');				# hash 
            next if ($tag eq 'terminfo');			# has commas and other bad characters
            if ($tag eq 'radio') { $tag_value = join" ", sort keys %{ $fields{$field}{$tag} }; }
            $data .= "'$tag' : '$tag_value' -DIVIDER- "; }
          $data .= "'multi' : '$amount', ";
          $data =~ s/ -DIVIDER- $/ }/;
          $trToPrint .= qq(<input type="hidden" id="data_$field" value="$data" />\n); 
      } # if ($i == 1)
      my $td_label .= &printEditorLabel($i, $field);
      my $colspan = 2; my $td_indent = ''; if ($j > 0) { $td_indent .= qq(<td></td>); $colspan = 2; }
      my $td_text = '';
      if ($fields{$field}{type} eq 'text') {                $td_text .= &printEditorText($i, $field, $colspan);     }
        elsif ($fields{$field}{type} eq 'ontology') {       $td_text .= &printEditorOntology($i, $field, $colspan); }
        elsif ($fields{$field}{type} eq 'checkbox_table') { $td_text .= &printEditorCheckboxTable($field, $colspan); }
#         elsif ($fields{$field}{type} eq 'bigtext') {  $td_text .= &printEditorBigtext($i, $field, $colspan);  }
#         elsif ($fields{$field}{type} eq 'textarea') { $td_text .= &printEditorTextarea($i, $field, $colspan); }
#         elsif ($fields{$field}{type} eq 'dropdown') { $td_text .= &printEditorDropdown($i, $field, $colspan); }
#         elsif ($fields{$field}{type} eq 'checkbox') { $td_text .= &printEditorCheckbox($i, $field, $colspan); }
#         elsif ($fields{$field}{type} eq 'message') {  $td_text .= &printEditorMessage($i, $field);            }
      my $td_warnings .= &printEditorWarnings($i, $field);
      $trToPrint .= $td_indent; 
      $trToPrint .= $td_label; 
      $trToPrint .= $td_text; 
      $trToPrint .= $td_warnings; 
      $trToPrint    .= qq(</tr>\n);
    print $trToPrint;
    } # foreach my $field (@fields)
  } # for my $i (1 .. $amount)
} # sub printArrayEditorNested

sub showForm {
  my $ip = &getIp();
  my ($goodOrBad) = &checkIpBlock($ip);
  return if $goodOrBad;
#   return if ($ip eq '46.161.41.199');			# spammed 2015 09 01
#   return if ($ip eq '188.143.232.32');                  # spammed 2016 03 19
  print qq(<form method="post" action="webinar.cgi" enctype="multipart/form-data">);
  print qq(<div id="term_info_box" style="border: solid; position: fixed; top: 95px; right: 20px; width: 350px; z-index:2; background-color: white;">\n);
#   print qq(<div id="clear_term_info" style="position: fixed; z-index: 3; top: 102px; right: 30px";>&#10008;</div>\n);
#   print qq(<div id="clear_term_info" align="right" onclick="document.getElementById('term_info').innerHTML = '';">clear &#10008;</div>\n);
  print qq(<div id="clear_term_info" align="right" onclick="document.getElementById('term_info_box').style.display = 'none';"><img id="close_term_info_image" src="images/x_plain.png" onmouseover="document.getElementById('close_term_info_image').src='images/x_reversed.png';" onmouseout="document.getElementById('close_term_info_image').src='images/x_plain.png';"></div>\n);
  print qq(<div id="term_info" style="margin: 5px 5px 5px 5px;">Click on green question marks <span style="color: #06C729; font-weight: bold;">?</span> or start typing in a specific field to see more information here.</div>\n);
  print qq(</div>\n);
#   &showEditorActions();
  print "<br/><br/>\n";
  print qq(<table border="0"><tr><td style="padding: 0 50px 0 0;">);	# extra table to have some padding to the right of the main table inside
#   print qq(<table border="1" style="border-spacing: 0 50px; padding: 0 50px 0 50px; table-layout: fixed;">);
# HIDE
  print qq(<table border="0">);

  print qq(<tr>);
  print qq(<td colspan="1" style="width: 175px; max-width: 175px; min-width: 175px;">&nbsp;</td>);
  print qq(<td colspan="1" style="width: 175px; max-width: 175px; min-width: 175px;">&nbsp;</td>);
  print qq(<td colspan="1" style="width: 125px; max-width: 125px; min-width: 125px;">&nbsp;</td>);
#   print qq(<td colspan="1">&nbsp;</td>);
#   print qq(<td colspan="1">&nbsp;</td>);
  print qq(<td colspan="1" style="width: 100px;">&nbsp;</td>);
  print qq(<td colspan="1" style="width: 100px;">&nbsp;</td>);
  print qq(<td colspan="1" style="width: 100px;">&nbsp;</td>);
  print qq(<td colspan="1">&nbsp;</td>);
  print qq(</tr>);


  &printPersonField();
  &printEmailField();
  &printWebinarsField();
#   &printPmidField();
#   &printTrSpacer();
#   &printTrHeader('Genetic Perturbation(s)', '20', '18px', "(one required)", '#ff0000', '13px');
#   &printCloneSeqField();
#   &printAlleleField();
#   &printTransgeneField();
#   &printSingleMultiField();
#   &printTrSpacer();
#   &printTrHeader('<b>!! PLEASE NOTE</b>: All genetic perturbations above will be annotated to all phenotypes entered below. <b>For separate perturbation-phenotype annotations, please perform separate submissions, or use the WormBase Phenotype Worksheet (linked above).</b>', '20', '13px', "", '#ff0000', '13px');	# for Chris 2016 06 21
#   &printTrSpacer();
#   &printTrHeader('Phenotype(s)', '20', '18px', "(one required)", '#ff0000', '13px');
#   &printObsPhenotypeField();
#   &printPhenontLink();
#   &printShowObsSuggestLink();
#   &printObsSuggestField();
#   &printNotPhenotypeField();
#   &printPhenontLink();
#   &printShowNotSuggestLink();
#   &printNotSuggestField();
#   &printTrSpacer();
#   &printTrSpacer();
#   &printTrHeader('Optional', '20', '18px', "(inheritance pattern, mutation effect, penetrance, temperature sensitivity, genetic background and general comments)", '#aaaaaa', '12px');
#   &printOptionalExplanation();
#   &printAlleleNatureField();
#   &printAlleleFunctionField();
#   &printPenetranceField();
#   &printTempSensField();
#   &printGenotypeField();
#   &printStrainField();
#   &printCommentField();
#   &printLinkToOtherForm();
# #   &printOffset();

#   print qq(<tr><td>&nbsp;</td></tr>\n);
  print qq(</table>);
  print qq(</td></tr></table>);
  print "<br/><br/>\n";
  &showEditorActions();
  print qq(</form>);
} # sub showForm

sub printEditorLabel {
  my ($i, $field) = @_;
  my $label          = $fields{$field}{label};
  my $labelTdColspan = qq(colspan="1"); 
  my $minwidth       = '176px'; if ($fields{$field}{minwidth}) { $minwidth = $fields{$field}{minwidth}; }
  my $fontsize       = ''; if ($fields{$field}{fontsize}) { $fontsize = qq(font-size: $fields{$field}{fontsize};); }
#   my $labelTdStyle   = qq(style="min-width: $minwidth; border-style: solid; border-color: #000000; $fontsize");
  my $labelTdStyle   = qq(style="min-width: $minwidth; $fontsize padding: 0 5px 0 0;");
  my $terminfo       = '';
  if ($fields{$field}{terminfo}) {    
    my $terminfo_text = $fields{$field}{terminfo}; my $terminfo_title = $fields{$field}{terminfo};
    $terminfo_text  =~ s/'/&#8217;/g; $terminfo_text  =~ s/"/&quot;/g; 
    $terminfo_title =~ s/'/&#8217;/g; $terminfo_title =~ s/"/&quot;/g; $terminfo_title =~ s/<.*?>//g;
    $terminfo = qq(<span style="color: #06C729; font-weight: bold;" title="$terminfo_title" onmouseover="this.style.cursor='pointer'" onclick="document.getElementById('term_info_box').style.display = ''; document.getElementById('term_info').innerHTML = '$terminfo_text';">?</span>); }
  return qq(<td align="right" $labelTdColspan $labelTdStyle>&nbsp;&nbsp;$label $terminfo</td>);
} # sub printEditorLabel

sub printEditorWarnings {
  my ($i, $field) = @_;
  ($var, my $warningvalue)  = &getHtmlVar($query, "input_warnings_${i}_$field");
  if ($field eq 'person') {				# person field has a notice linking to their publications
    if ($fields{person}{termidvalue}{1}) { 
      my $person_id = $fields{person}{termidvalue}{1}; my $person_name = ''; my $person_email = '';
      if ($fields{person}{inputvalue}{1}) { $person_name  = $fields{person}{inputvalue}{1}; }
      if ($fields{email}{inputvalue}{1})  { $person_email = $fields{email}{inputvalue}{1};  }
#       $warningvalue = qq(Click <a href='phenotype.cgi?action=personPublication&personId=${person_id}&personName=${person_name}&personEmail=${person_email}' target='new' style='font-weight: bold; text-decoration: underline;'>here</a> to review your publications and see which are in need of phenotype curation<br/>\n);
  } }
  my $labelTdColspan = qq(colspan="4"); 
  my $minwidth       = '200px'; if ($fields{$field}{minwidth}) { $minwidth = $fields{$field}{minwidth}; }
#   my $labelTdStyle   = qq(style="display: none; min-width: $minwidth; border-style: solid; border-color: #000000;");
  my $labelTdStyle   = qq(style="display: none; min-width: $minwidth;");
  if ($warningvalue) { $labelTdStyle   = qq(style="min-width: $minwidth;"); }
#   return qq(<td id="tdwarnings_${i}_$field" $labelTdColspan $labelTdStyle>warninggoeshere</td>);
#   return qq(<td id="tdwarnings_${i}_$field" $labelTdColspan $labelTdStyle>$warningvalue</td><input type="hidden" id="input_warnings_${i}_$field" name="input_warnings_${i}_$field" value="$warningvalue">);
  my $toReturn = '';
  $toReturn .= qq(<td id="tdwarnings_${i}_$field" $labelTdColspan $labelTdStyle>$warningvalue</td>);
  $toReturn .= qq(<input type="hidden" id="input_warnings_${i}_$field" size=200 name="input_warnings_${i}_$field" value="$warningvalue">);
#   if ( ($field eq 'pmid') || ($field eq 'allele') ) {
#       $toReturn .= qq(FIELD $field $i<input id="input_warnings_${i}_$field" size=200 name="input_warnings_${i}_$field" value="$warningvalue">); }
#     else {
#       $toReturn .= qq(<input type="hidden" id="input_warnings_${i}_$field" size=200 name="input_warnings_${i}_$field" value="$warningvalue">); }
  return $toReturn;
} # sub printEditorWarnings

sub printEditorText {
#   my ($i, $field, $group, $inputvalue, $termidvalue, $input_size, $colspan, $fieldclass, $placeholder, $freeForced) = @_;
  my ($i, $field, $colspan) = @_;
  my $inputvalue  = ''; my $termidvalue = ''; my $placeholder = ''; my $readonly = ''; 
  if ($fields{$field}{inputvalue}{$i})     { 
    $inputvalue     = $fields{$field}{inputvalue}{$i}; 		 # previous form value
    if ($inputvalue =~ m/"/) { $inputvalue =~ s/\"/&quot;/g; } } # if it had doublequotes, escape of they'll become part of the html
  if ($fields{$field}{termidvalue}{$i})    { $termidvalue = $fields{$field}{termidvalue}{$i}; }
  if ($fields{$field}{example})            { $placeholder = qq(placeholder="$fields{$field}{example}"); }
  if ($fields{$field}{type} eq 'readonly') { $readonly    = qq(readonly="readonly"); }
#   return qq(<td style="min-width: 300px; border-style: solid; border-color: #000000;"><input name="input_${i}_$field" id="input_${i}_$field" style="width: 97%;" $readonly $placeholder value="$inputvalue"></td>\n);
  return qq(<td style="min-width: 300px; max-width: 300px;" colspan="$colspan"><input name="input_${i}_$field" id="input_${i}_$field" style="max-width: 300px; width: 97%; background-color: #E1F1FF;" $readonly $placeholder value="$inputvalue"></td>\n);
} # printEditorText

sub printEditorOntology {
  my ($i, $field, $colspan) = @_;
  my $inputvalue  = ''; my $termidvalue = ''; my $placeholder = ''; my $readonly = ''; my $freeForced = 'free';
  if ($fields{$field}{inputvalue}{$i})     { $inputvalue  = $fields{$field}{inputvalue}{$i}; }	# previous form value
  if ($fields{$field}{termidvalue}{$i})    { $termidvalue = $fields{$field}{termidvalue}{$i}; }
  if ($fields{$field}{example})            { $placeholder = qq(placeholder="$fields{$field}{example}"); }
  if ($fields{$field}{type} eq 'readonly') { $readonly    = qq(readonly="readonly"); }
  if ($fields{$field}{freeForced})         { $freeForced  = $fields{$field}{freeForced}; }

  my $table_to_print = qq(<td style="min-width: 300px; max-width: 300px;" colspan="$colspan">\n);     # there's some weird auto-sizing of the field where it shrinks to nothing if the td doesn't have a size, so min size is 300
  $table_to_print .= qq(<span id="container${freeForced}${i}${field}AutoComplete">\n);
  $table_to_print .= qq(<div id="${freeForced}${i}${field}AutoComplete" class="div-autocomplete">\n);
    # when blurring ontology fields, if it's been deleted by user, make the corresponding termid field also blank.
  my $onBlur = qq(if (document.getElementById('input_${i}_$field').value === '') { document.getElementById('termid_${i}_$field').value = ''; });
  $table_to_print .= qq(<input id="input_${i}_$field"  name="input_${i}_$field" value="$inputvalue"  style="max-width: 300px; width: 97%; background-color: #E1F1FF;" $placeholder onBlur="$onBlur">\n);
# HIDE
#   $table_to_print .= qq(<input id="termid_${i}_$field" name="termid_${i}_$field" value="$termidvalue" size="40"          readonly="readonly">\n);
  $table_to_print .= qq(<input type="hidden" id="termid_${i}_$field" name="termid_${i}_$field" value="$termidvalue" size="40"          readonly="readonly">\n);
    # ontology fields have html values in input_i_field but are not from autocomplete object, so selectionenforce clears them.  store this parallel value, so if it gets cleared, it gets reloaded
#   $table_to_print .= qq(<input id="loaded_${i}_$field" name="loaded_${i}_$field" value="$inputvalue" size="40"          readonly="readonly">\n);
  $table_to_print .= qq(<input type="hidden" id="loaded_${i}_$field" name="loaded_${i}_$field" value="$inputvalue" size="40"          readonly="readonly">\n);
  $table_to_print .= qq(<div id="${freeForced}${i}${field}Container"></div></div></span>\n);
  $table_to_print .= qq(</td>\n);
  return $table_to_print;
} # sub printEditorOntology

sub printEditorCheckboxTable {
#   my ($i, $field, $group, $inputvalue, $termidvalue, $input_size, $colspan, $fieldclass, $placeholder, $freeForced) = @_;
  my ($field, $colspan) = @_;

#   my $inputvalue  = ''; my $termidvalue = ''; my $placeholder = ''; my $readonly = ''; 
#   if ($fields{$field}{inputvalue}{$i})     { 
#     $inputvalue     = $fields{$field}{inputvalue}{$i}; 		 # previous form value
#     if ($inputvalue =~ m/"/) { $inputvalue =~ s/\"/&quot;/g; } } # if it had doublequotes, escape of they'll become part of the html

#   my @webinarKeys = reverse sort keys %webinars;
#   my $webinarAmount = shift @webinarKeys;
  my $webinarAmount = $fields{webinars}{multi};
  my $toReturn = '';
  my $td = qq(td style="font-weight: bold");
  $toReturn .= qq(<table border="0"><tr><$td>Attending</td><$td>Date</td><$td>Time</td><$td>Topic</td><$td>Speaker</td><$td>Slides</td><$td>Video</td></tr>);
  for my $j (1 .. $webinarAmount) {
    my $checked = ''; my $color = 'black';
    if ($webinars{$j}{'disabled'} eq 'disabled') { 
      $color = 'grey'; 
    }
    if ($fields{$field}{inputvalue}{$j} == $j) { $checked = qq(checked="checked"); }
    $toReturn .= qq(<tr>);
    $toReturn .= qq(<td align="center">);
    if ($webinars{$j}{'disabled'} eq 'disabled') { 
        $toReturn .= qq(<input type="hidden" id="input_${j}_${field}" name="input_${j}_${field}" value="$j" >); }
      else {
        $toReturn .= qq(<input type="checkbox" id="input_${j}_${field}" name="input_${j}_${field}" value="$j" $checked >); }
    $toReturn .= qq(</td>);
    $toReturn .= qq(<td colspan="1" style="width: 175px; max-width: 175px; min-width: 175px; color: $color;">$webinars{$j}{'date'}</td>);
    $toReturn .= qq(<td colspan="1" style="width: 100px; max-width: 100px; min-width: 100px; color: $color;">$webinars{$j}{'time'}</td>);
    $toReturn .= qq(<td colspan="1" style="width: 175px; max-width: 450px; min-width: 450px; color: $color;">$webinars{$j}{'topic'}</td>);
    $toReturn .= qq(<td colspan="1" style="width: 175px; max-width: 400px; min-width: 275px; color: $color;">$webinars{$j}{'speaker'}</td>);
    $toReturn .= qq(<td colspan="1" style="width: 100px; max-width: 100px; min-width: 100px; color: $color;">$webinars{$j}{'slides'}</td>);
    $toReturn .= qq(<td colspan="1" style="width: 100px; max-width: 100px; min-width: 100px; color: $color;">$webinars{$j}{'video'}</td>);
    $toReturn .= qq(</tr>);
  }
  $toReturn .= '</table>';

  return qq(<td style="min-width: 300px; max-width: 300px;" colspan="$colspan">$toReturn</td>\n);

#     my $checked = '';
#     if ($fields{$field}{inputvalue}{$i} eq $fields{$field}{label}) { $checked = qq(checked="checked"); }
# #     $toReturn = qq(&nbsp;&nbsp;<input type="checkbox" id="input_${i}_$field" name="input_${i}_$field" value="$fields{$field}{label}" $checked>&nbsp; $fields{$field}{label}<br/>\n);
#     $toReturn = qq(&nbsp;<input type="checkbox" id="input_${i}_$field" name="input_${i}_$field" value="$fields{$field}{label}" $checked>&nbsp; \n); }

#   if ($fields{$field}{termidvalue}{$i})    { $termidvalue = $fields{$field}{termidvalue}{$i}; }
#   if ($fields{$field}{example})            { $placeholder = qq(placeholder="$fields{$field}{example}"); }
#   if ($fields{$field}{type} eq 'readonly') { $readonly    = qq(readonly="readonly"); }
#   return qq(<td style="min-width: 300px; border-style: solid; border-color: #000000;"><input name="input_${i}_$field" id="input_${i}_$field" style="width: 97%;" $readonly $placeholder value="$inputvalue"></td>\n);

#   return qq(<td style="min-width: 300px; max-width: 300px;" colspan="$colspan"><input name="input_${i}_$field" id="input_${i}_$field" style="max-width: 300px; width: 97%; background-color: #E1F1FF;" $readonly $placeholder value="$inputvalue"></td>\n);
} # sub printEditorCheckboxTable

sub initWebinarInfo {
  $webinars{1}{'date'}          = 'Oct. 29, 2020 (Thu.)';
  $webinars{2}{'date'}          = 'Nov. 9, 2020 (Mon.)';
  $webinars{3}{'date'}          = 'Nov. 20, 2020 (Fri.)';
  $webinars{4}{'date'}          = 'Dec. 18, 2020 (Fri.)';
  $webinars{5}{'date'}          = 'Jan. 11, 2021 (Mon.)';
  $webinars{6}{'date'}          = 'Feb. 22, 2021 (Mon.)';
  $webinars{7}{'date'}          = 'Feb. 26, 2021 (Fri.)';
  $webinars{8}{'date'}          = 'March 8, 2021 (Mon.)';
  $webinars{9}{'date'}          = 'March 22, 2021 (Mon.)';

  $webinars{1}{'time'}          = '9am PDT';
  $webinars{2}{'time'}          = '9am PST';
  $webinars{3}{'time'}          = '10am PST';
  $webinars{4}{'time'}          = '10am PST';
  $webinars{5}{'time'}          = '8am PST';
  $webinars{6}{'time'}          = '10am PST';
  $webinars{7}{'time'}          = '10am PST';
  $webinars{8}{'time'}          = '10am PST';
  $webinars{9}{'time'}          = '10am PDT';

  $webinars{1}{'topic'}         = 'An Overview of WormBase Data and Tools';
  $webinars{2}{'topic'}         = 'microPublication';
  $webinars{3}{'topic'}         = 'JBrowse';
  $webinars{4}{'topic'}         = 'WormMine';
  $webinars{5}{'topic'}         = 'Parasite BioMart';
  $webinars{6}{'topic'}         = 'Data mining strategies and workflows';
  $webinars{7}{'topic'}         = 'Author First Pass & Textpresso';
  $webinars{8}{'topic'}         = 'Gene Function Graphs and Gene Set Enrichment Analysis';
  $webinars{9}{'topic'}         = 'High-throughput Expression: WormBase SPELL & RNASeq related tools';

  $webinars{1}{'speaker'}       = 'Wen Chen';
  $webinars{2}{'speaker'}       = 'Tim Schedl & Paul Sternberg';
  $webinars{3}{'speaker'}       = 'Scott Cain';
  $webinars{4}{'speaker'}       = 'Chris Grove';
  $webinars{5}{'speaker'}       = 'Faye Rodgers';
  $webinars{6}{'speaker'}       = 'Todd Harris';
  $webinars{7}{'speaker'}       = 'Kimberly Van Auken & Daniela Raciti';
  $webinars{8}{'speaker'}       = 'Raymond Lee';
  $webinars{9}{'speaker'}       = 'Wen Chen';

  $webinars{1}{'slides'}        = '<a href="https://docs.google.com/presentation/d/12Bf6ZQ8J1PIIMN0GXC91pmNhwDTh6XOH0wIDXJpJMbc/edit?usp=sharing" target="new">slides</a>';
  $webinars{2}{'slides'}        = '<a href="http://tazendra.caltech.edu/~azurebrd/var/work/for_wen/webinars/webinar02_micropub_20201109.pdf" target="new">slides</a>';
  $webinars{3}{'slides'}        = '<a href="https://docs.google.com/presentation/d/1a3rAOod4khVOCcRV3hn_3lmOyXDZrgyOKPvd85uLiEA/edit?usp=sharing" target="new">slides</a>';
  $webinars{4}{'slides'}        = '<a href="https://docs.google.com/presentation/d/1xU7jSlBr_bQowwY0K_Uaew66WbpWsjAr11z3cf2cHuE/edit?usp=sharing" target="new">slides</a>';
  $webinars{5}{'slides'}        = '<a href="https://docs.google.com/presentation/d/18g5UVbAlv6o8xK2B5Go6avoKvSvtz3z8Lnb2yo59J-g/edit?usp=sharing" target="new">slides</a>';
  $webinars{6}{'slides'}        = '<a href=" https://docs.google.com/presentation/d/1ZR2yfGtHHulhbNtKU5WIQM5Hr2POEUkPc646VCYyNSA/edit?usp=sharing" target="new">slides</a>';
  $webinars{7}{'slides'}        = '<a href="https://docs.google.com/presentation/d/16k71xEOMJN8G8QZZuAZ6gFgY-JIuLDi4vV6x9fqT2u0/edit?usp=sharing" target="new">slides</a>';
  $webinars{8}{'slides'}        = '<a href="https://drive.google.com/file/d/1rRoTHEQdN9cDSfPSy3Ryo_aCmaUb9x-t/view?usp=sharing" target="new">slides</a>';
  $webinars{9}{'slides'}        = '<a href="https://drive.google.com/file/d/15wNgIfJlnF5sNhb3erzik5S1IYzEIPGm/view?usp=sharing" target="new">slides</a>';

  $webinars{1}{'video'}         = '<a href="https://www.youtube.com/watch?v=I0-R_nplBao&t=1s" target="new">video</a>';
  $webinars{2}{'video'}         = '<a href="https://www.youtube.com/watch?v=OhqM0NSF_sY" target="new">video</a>';
  $webinars{3}{'video'}         = '<a href="https://www.youtube.com/watch?v=65HXts1wWmE" target="new">video</a>';
  $webinars{4}{'video'}         = '<a href="https://www.youtube.com/watch?v=rMDYRqFASok" target="new">video</a>';
  $webinars{5}{'video'}         = '<a href="https://www.youtube.com/watch?v=IM2j7-OPmtQ" target="new">video</a>';
#   $webinars{6}{'video'}         = '<a href="https://www.youtube.com/watch?v=S6abw0lb6ic" target="new">video</a>';
  $webinars{6}{'video'}         = '';
  $webinars{7}{'video'}         = '<a href="https://youtu.be/ZONK4qe_-w8" target="new">video</a>';
  $webinars{8}{'video'}         = '<a href="https://youtu.be/tWrm-bRXYcY" target="new">video</a>';
  $webinars{9}{'video'}         = '<a href="https://youtu.be/TymnrF_b59A" target="new">video</a>';

  $webinars{1}{'disabled'}      = 'disabled';
  $webinars{2}{'disabled'}      = 'disabled';
  $webinars{3}{'disabled'}      = 'disabled';
  $webinars{4}{'disabled'}      = 'disabled';
  $webinars{5}{'disabled'}      = 'disabled';
  $webinars{6}{'disabled'}      = 'disabled';
  $webinars{7}{'disabled'}      = 'disabled';
  $webinars{8}{'disabled'}      = 'disabled';
  $webinars{9}{'disabled'}      = 'disabled';
} # sub initWebinarInfo

sub initFields {
#   tie %{ $fields{person}{field} }, "Tie::IxHash";
  $fields{person}{multi}                                      = '1';
  $fields{person}{type}                                       = 'ontology';
  $fields{person}{label}                                      = 'Your Name';
  $fields{person}{ontology_type}                              = 'WBPerson';
  $fields{person}{freeForced}                                 = 'free';
#   $fields{person}{haschecks}                                  = 'person';
  $fields{person}{terminfo}                                   = qq(Start typing and select your name from the list of registered WormBase persons and IDs. If you do not have a WBPerson ID, fill out our <a href="http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/person.cgi" target="new">Person Update Form</a>.);
  $fields{person}{example}                                    = 'e.g. Bob Horvitz';
  $fields{person}{mandatory}                                  = 'mandatory';
#   tie %{ $fields{email}{field} }, "Tie::IxHash";
  $fields{email}{multi}                                       = '1';
  $fields{email}{type}                                        = 'text';
  $fields{email}{label}                                       = 'Your E-mail Address';
  $fields{email}{terminfo}                                    = qq(Enter your preferred e-mail address. A confirmation e-mail will be sent to this address upon data submission. If you selected your name from the registered WormBase Persons list in the previous field, your e-mail on file would have been used to populate this field. Feel free to correct this to a different, preferred e-mail address. You will need to update your contact information using the <a href="http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/person.cgi" target="new">Person Update Form</a> if you want us to store this new e-mail address for you.);
  $fields{email}{example}                                     = 'e.g. help@wormbase.org';
  $fields{email}{mandatory}                                   = 'mandatory';

  my @webinarKeys = reverse sort keys %webinars;
  my $webinarAmount = shift @webinarKeys;
  $fields{webinars}{multi}                                    = $webinarAmount;
  $fields{webinars}{type}                                     = 'checkbox_table';
  $fields{webinars}{label}                                    = 'Webinars';
  $fields{webinars}{terminfo}                                 = qq(Select the webinars you will attend);
  $fields{webinars}{example}                                  = '';
#   $fields{webinars}{mandatory}                                = 'mandatory';
} # sub initFields

sub checkMandatoryFields {
  my $mandatoryFail        = 0;
#   my $aphenotypeExists     = 0;
#   my $hasAnyPrimaryData    = 0;
#   my $amountPerturbations  = 0;
  foreach my $field (keys %fields) {
    if ($field eq 'person') { 
      if ($fields{$field}{termidvalue}{1}) {
          unless ($fields{$field}{termidvalue}{1} =~ m/WBPerson/) { $mandatoryFail++; print qq(<span style="color:red">FAIL name has input but no TermID.</span>); } }
#         else { $mandatoryFail++; print qq(<span style="color:red">FAIL</span>); }	# this error message part of regular 'mandatory' check below
    }
    if ($fields{$field}{'mandatory'} eq 'mandatory') {
      unless ($fields{$field}{hasdata}) {
        $mandatoryFail++;
        print qq(<span style="color:red">$fields{$field}{label} is required.</span><br/>\n); } }
#     if ($fields{$field}{'mandatory'} eq 'anyprimarydata') {
#       my $amount = $fields{$field}{multi};
#       for my $i (1 .. $amount) {
#         my ($var, $inputvalue)  = &getHtmlVar($query, "input_${i}_$field");
#         if ($inputvalue) { $amountPerturbations++; } }
#       if ($fields{$field}{hasdata}) { $hasAnyPrimaryData++; }
#     }
  }
#   unless ($hasAnyPrimaryData) {					# one of the primary data fields must have something : allele / transgene / rnai
#     $mandatoryFail++;
#     print qq(<span style="color:red">At least one genetic perturbation (Allele, Transgene or RNAi Clone / Sequence) is required.</span><br/>\n); }
#   if ($amountPerturbations > 1) {				# multiple perturbations require a radio button option
#     unless ( $fields{pertsinglemulti}{hasdata} ) { 
#       print qq(<span style="color:red">Please indicate if the multiple perturbations entered indicate multiple individual experiments or a single complex experiment.</span><br/>\n); } }
#   unless ( $fields{pmid}{inputvalue}{1} ) {			# if there's no pmid, check all phenotype fields for corresponding personal communication checkbox on
#     my @phenFields = qw( obsphenotype obssuggested notphenotype notsuggested );
#     my $pmidPersonalFail = 0;
#     foreach my $shortfield (@phenFields) {
#       my $termField = $shortfield . 'term';
#       my $persField = $shortfield . 'personal';
#       my $amount    = $fields{$termField}{multi};
#       for my $i (1 .. $amount) {
#         if ($fields{$termField}{inputvalue}{$i}) { 
#           unless ($fields{$persField}{inputvalue}{$i}) { $pmidPersonalFail++; } } } }
#     if ($pmidPersonalFail) {
#       $mandatoryFail++;
#       print qq(<span style="color:red">PMID is required, or all phenotype fields must have the Personal Communication checkbox selected.</span><br/>\n); } }
#   unless ( ($fields{obsphenotypeterm}{hasdata}) || ($fields{obssuggestedterm}{hasdata}) || ($fields{notphenotypeterm}{hasdata}) || ($fields{notsuggestedterm}{hasdata}) ) {
#     $mandatoryFail++;
#     print qq(<span style="color:red">At least one phenotype is required.</span><br/>\n); }
  if ($mandatoryFail > 0) { print qq(<br/><br/>\n); }
  return $mandatoryFail;
} # sub checkMandatoryFields

# <link rel="stylesheet" type="text/css" href="http://yui.yahooapis.com/2.7.0/build/autocomplete/assets/skins/sam/autocomplete.css" />
sub addJavascriptCssToHeader {
  # my $baseUrl = 'https://' . $hostfqdn . "/~azurebrd/cgi-bin/forms";
  my $baseUrl = $ENV{THIS_HOST} . "pub/cgi-bin/forms";
  my $extra_stuff = << "EndOfText";
<link rel="stylesheet" type="text/css" href="$baseUrl/stylesheets/jex.css" />
<link rel="stylesheet" type="text/css" href="$baseUrl/stylesheets/yui_edited_autocomplete.css" />
<link rel="stylesheet" type="text/css" href="https://cdnjs.cloudflare.com/ajax/libs/yui/2.7.0/fonts/fonts-min.css" />
<!--
# <link rel="stylesheet" type="text/css" href="http://yui.yahooapis.com/2.7.0/build/fonts/fonts-min.css" />
# <script type="text/javascript" src="http://yui.yahooapis.com/2.7.0/build/yahoo-dom-event/yahoo-dom-event.js"></script>
# <script type="text/javascript" src="http://yui.yahooapis.com/2.7.0/build/connection/connection-min.js"></script>
# <script type="text/javascript" src="http://yui.yahooapis.com/2.7.0/build/datasource/datasource-min.js"></script>
# <script type="text/javascript" src="http://yui.yahooapis.com/2.7.0/build/autocomplete/autocomplete-min.js"></script>
# <script type="text/javascript" src="http://yui.yahooapis.com/2.7.0/build/json/json-min.js"></script>
-->
<script type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/yui/2.7.0/yahoo-dom-event/yahoo-dom-event.js"></script>
<script type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/yui/2.7.0/connection/connection-min.js"></script>
<script type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/yui/2.7.0/datasource/datasource-min.js"></script>
<script type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/yui/2.7.0/autocomplete/autocomplete-min.js"></script>
<script type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/yui/2.7.0/json/json-min.js"></script>
<script type="text/javascript" src="$baseUrl/javascript/webinar.js"></script>
<script type="text/JavaScript">
<!--Your browser is not set to be Javascript enabled
//-->
</script>

<!--// this javascript disables the return key to prevent form submission if someone presses return on an input field
// http://74.125.155.132/search?q=cache:FhzD9ine5fQJ:www.webcheatsheet.com/javascript/disable_enter_key.php+disable+return+on+input+submits+form&cd=6&hl=en&ct=clnk&gl=us
// 2009 12 14-->
<script type="text/javascript">
function stopRKey(evt) {
  var evt = (evt) ? evt : ((event) ? event : null);
  var node = (evt.target) ? evt.target : ((evt.srcElement) ? evt.srcElement : null);
  if ((evt.keyCode == 13) && (node.type=="text"))  {return false;}
}
document.onkeypress = stopRKey;
</script>

EndOfText
  $header =~ s/<\/head>/$extra_stuff\n<\/head>/;
  $header =~ s/<body>/<body class="yui-skin-sam">/;
} # sub addJavascriptCssToHeader

sub getIp {
  my $ip            = $query->remote_host();			# get value for current user IP, not (potentially) loaded IP 
  my %headers = map { $_ => $query->http($_) } $query->http();
  if ($headers{HTTP_X_REAL_IP}) { $ip = $headers{HTTP_X_REAL_IP}; }
  return $ip;
} # sub getIp

sub checkIpBlock {
  my ($ip) = @_;
  $result = $dbh->prepare( "SELECT * FROM frm_ip_block WHERE frm_ip_block = '$ip';" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; my @row = $result->fetchrow();
  if ($row[0]) { return 1; } else { return 0; }
} # sub checkIpBlock

sub updateUserIp {
  my ($wbperson, $submitter_email) = @_;
  my $ip = &getIp();
  my $twonum = $wbperson; $twonum =~ s/WBPerson/two/;
  $result = $dbh->do( "DELETE FROM two_user_ip WHERE two_user_ip = '$ip' ;" );
  $result = $dbh->do( "INSERT INTO two_user_ip VALUES ('$twonum', '$ip', '$submitter_email')" ); 
} # sub updateUserIp

sub getUserByIp {
  my $ip = &getIp();
  my $twonum = ''; my $standardname = ''; my $email = ''; my $wbperson = '';
  $result = $dbh->prepare( "SELECT * FROM two_user_ip WHERE two_user_ip = '$ip';" ); 
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; my @row = $result->fetchrow();
  if ($row[0]) { $twonum = $row[0]; $email = $row[2]; $wbperson = $row[0]; $wbperson =~ s/two/WBPerson/; }
  $result = $dbh->prepare( "SELECT * FROM two_standardname WHERE joinkey = '$twonum';" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; my @row = $result->fetchrow();
  if ($row[2]) { $standardname = $row[2]; }
  return ($wbperson, $standardname, $email);
} # sub getUserByIp

sub mailSendmail {
  my ($user, $email, $subject, $body) = @_;

# EMAIL locally
#   $user = 'wormbase-webinar@mangolassi.caltech.edu';
#   my %mail;
#   $mail{from}           = $user;
#   $mail{to}             = $email;
#   $mail{subject}        = $subject;
#   $mail{body}           = $body;
#   $mail{'content-type'} = 'text/html; charset="iso-8859-1"';
# # UNCOMMENT TO SEND EMAIL
#   sendmail(%mail) || print qq(<span style="color:red">Error, confirmation email failed</span> : $Mail::Sendmail::error<br/>\n);

# GMAIL way 
  my $emailaddress = $email;
#   ($var, my $emailaddress)   = &getHtmlVar($query, 'email');
#   ($var, my $subject)        = &getHtmlVar($query, 'subject');
#   ($var, my $body)           = &getHtmlVar($query, 'body');
  my $sender = 'outreach@wormbase.org';
#   my $replyto = 'curation@wormbase.org';
#   print qq(send email to $emailaddress<br/>from $sender<br/>replyto $replyto<br/>subject $subject<br/>body $body<br/>);
#   print qq(send email to $emailaddress<br/>from $sender<br/>subject $subject<br/>body $body<br/>);
  my $email = Email::Simple->create(
    header => [
        From       => 'outreach@wormbase.org',
        To         => "$emailaddress",
        Subject    => "$subject",
        'Content-Type' => 'text/html',
    ],
    body => "$body",
  );

  my $passfile = $ENV{CALTECH_CURATION_FILES_INTERNAL_PATH} . '/insecure/outreachwormbase';
  # my $passfile = '/home/postgres/insecure/outreachwormbase';
  open (IN, "<$passfile") or die "Cannot open $passfile : $!";
  my $password = <IN>; chomp $password;
  close (IN) or die "Cannot close $passfile : $!";
  my $sender = Email::Send->new(
    {   mailer      => 'Gmail',
        mailer_args => [
           username => 'outreach@wormbase.org',
           password => "$password",
        ]
    }
  );
  eval { $sender->send($email) };
  die "Error sending email: $@" if $@;

} # sub mailSendmail

sub autocompleteXHR {                                           # when typing in an autocomplete field xhr call to this CGI for values
  print "Content-type: text/plain\n\n";
  ($var, my $words) = &getHtmlVar($query, 'query');
  ($var, my $field) = &getHtmlVar($query, 'field');
  my $matches;
  if ( $fields{$field}{type} eq 'ontology' ) {
    if ($fields{$field}{ontology_type} eq 'obo') { ($matches) = &getGenericOboAutocomplete($field, $words); }
      else {
        my $ontology_type = $fields{$field}{ontology_type};
        ($matches) = &getAnySpecificAutocomplete($ontology_type, $words); } }
  print $matches;
} # sub autocompleteXHR

sub getGenericOboAutocomplete {
  my ($field, $words) = @_;
  my $ontology_table  = $fields{$field}{ontology_table};
  my $max_results     = 20;
  # if ($words =~ m/^.{5,}/) { $max_results = 500; }		# Chris doesn't find this useful
  my $limit           = $max_results + 1;
  my $oboname_table   =  'obo_name_' . $ontology_table;
  my $obodata_table   =  'obo_data_' . $ontology_table;
  my $query_modifier  = qq(AND joinkey NOT IN (SELECT joinkey FROM $obodata_table WHERE $obodata_table ~ 'is_obsolete') ); 
  if ($field eq 'goidcc') { $query_modifier .= qq(AND joinkey IN (SELECT joinkey FROM obo_data_goid WHERE obo_data_goid ~ 'cellular_component') ); }
  if ($words =~ m/\'/) { $words =~ s/\'/''/g; }
  if ($words =~ m/\(/) { $words =~ s/\(/\\\(/g; }
  if ($words =~ m/\)/) { $words =~ s/\)/\\\)/g; }
  my $lcwords = lc($words);
  my @tabletypes = qw( name syn data );
  my %matches; my $t = tie %matches, "Tie::IxHash";     # sorted hash to filter results
  foreach my $tabletype (@tabletypes) {			# first match all types as exact match (case insensitive)
    my $obotable = 'obo_' . $tabletype . '_' . $ontology_table;
    my $column   = $obotable; if ($tabletype eq 'data') { $column = 'joinkey'; }          # use joinkey for ID instead of data
    $result = $dbh->prepare( "SELECT * FROM $obotable WHERE LOWER($column) = '$lcwords' $query_modifier ORDER BY $column LIMIT $limit;" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
    while ( (my @row = $result->fetchrow()) && (scalar(keys %matches) < $max_results) ) {
      my $elementText = qq($row[1] <span style='font-size:.75em'>( $row[0] )</span>);
      my $matchData = qq({ "eltext": "$elementText", "name": "$row[1]", "id": "$row[0]" });
      if ( ($tabletype eq 'syn') || ($tabletype eq 'data') ) {
        my $result2 = $dbh->prepare( "SELECT * FROM $oboname_table WHERE joinkey = '$row[0]' LIMIT $max_results;" ); 
        $result2->execute() or die "Cannot prepare statement: $DBI::errstr\n";
        my @row2 = $result2->fetchrow(); my $name = $row2[1];
        if ($tabletype eq 'syn') { 
          $elementText = qq($row[1] <span style='font-size:.75em'>( $name )</span>);
          $matchData = qq({ "eltext": "$elementText", "name": "$name", "id": "$row[0]" }); }
        elsif ($tabletype eq 'data') { 
          $elementText = qq($name <span style='font-size:.75em'>( $row[0] )</span>);
          $matchData = qq({ "eltext": "$elementText", "name": "$name", "id": "$row[0]" }); } }
      $matches{$matchData}++; }
  } # foreach my $tabletype (@tabletypes)
  foreach my $tabletype (@tabletypes) {			# first match all types at the beginning
    my $obotable = 'obo_' . $tabletype . '_' . $ontology_table;
    my $column   = $obotable; if ($tabletype eq 'data') { $column = 'joinkey'; }          # use joinkey for ID instead of data
    $result = $dbh->prepare( "SELECT * FROM $obotable WHERE LOWER($column) ~ '^$lcwords' $query_modifier ORDER BY $column LIMIT $limit;" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
    while ( (my @row = $result->fetchrow()) && (scalar(keys %matches) < $max_results) ) {
      my $elementText = qq($row[1] <span style='font-size:.75em'>( $row[0] )</span>);
      my $matchData = qq({ "eltext": "$elementText", "name": "$row[1]", "id": "$row[0]" });
      if ( ($tabletype eq 'syn') || ($tabletype eq 'data') ) {
        my $result2 = $dbh->prepare( "SELECT * FROM $oboname_table WHERE joinkey = '$row[0]' LIMIT $max_results;" ); 
        $result2->execute() or die "Cannot prepare statement: $DBI::errstr\n";
        my @row2 = $result2->fetchrow(); my $name = $row2[1];
        if ($tabletype eq 'syn') { 
          $elementText = qq($row[1] <span style='font-size:.75em'>( $name )</span>);
          $matchData = qq({ "eltext": "$elementText", "name": "$name", "id": "$row[0]" }); }
        elsif ($tabletype eq 'data') { 
          $elementText = qq($name <span style='font-size:.75em'>( $row[0] )</span>);
          $matchData = qq({ "eltext": "$elementText", "name": "$name", "id": "$row[0]" }); } }
      $matches{$matchData}++; }
  } # foreach my $tabletype (@tabletypes)
  foreach my $tabletype (@tabletypes) {			# then match all types at the middle
    next if ( $fields{$field}{matchstartonly} eq 'matchstartonly' );	# some fields should only match at the beginning
    my $obotable = 'obo_' . $tabletype . '_' . $ontology_table;
    my $column   = $obotable; if ($tabletype eq 'data') { $column = 'joinkey'; }          # use joinkey for ID instead of data
    $result = $dbh->prepare( "SELECT * FROM $obotable WHERE LOWER($column) ~ '$lcwords' AND LOWER($column) !~ '^$lcwords' $query_modifier ORDER BY $column LIMIT $limit;" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
    while ( (my @row = $result->fetchrow()) && (scalar(keys %matches) < $max_results) ) {
      my $elementText = qq($row[1] <span style='font-size:.75em'>( $row[0] )</span>);
      my $matchData = qq({ "eltext": "$elementText", "name": "$row[1]", "id": "$row[0]" });
      if ( ($tabletype eq 'syn') || ($tabletype eq 'data') ) {
        my $result2 = $dbh->prepare( "SELECT * FROM $oboname_table WHERE joinkey = '$row[0]' LIMIT $max_results;" );
        $result2->execute() or die "Cannot prepare statement: $DBI::errstr\n";
        my @row2 = $result2->fetchrow(); my $name = $row2[1];
        if ($tabletype eq 'syn') { 
          $elementText = qq($row[1] <span style='font-size:.75em'>( $name )</span>);
          $matchData = qq({ "eltext": "$elementText", "name": "$name", "id": "$row[0]" }); }
        elsif ($tabletype eq 'data') { 
          $elementText = qq($name <span style='font-size:.75em'>( $row[0] )</span>);
          $matchData = qq({ "eltext": "$elementText", "name": "$name", "id": "$row[0]" }); } }
      $matches{$matchData}++; }
    last if (scalar(keys %matches) >= $max_results);
  } # foreach my $tabletype (@tabletypes)
  if (scalar keys %matches >= $max_results) { 
    my $matchData = qq({ "eltext": "<span style='font-style: italic; background-color: yellow;'>More matches exist; please be more specific</span>", "name": "", "id": "invalid value" }); 
    $t->Replace($max_results - 1, 'no value', $matchData); }
  my $matches = join", ", keys %matches;
  $matches = qq({ "results": [ $matches ] });
  return $matches;
} # sub getGenericOboAutocomplete

sub getAnySpecificAutocomplete {
  my ($ontology_type, $words) = @_; my $matches = '';
  if ($ontology_type eq 'WBPerson') {             ($matches) = &getAnyWBPersonAutocomplete($words);    }
  return $matches;
} # sub getAnySpecificAutocomplete

sub getAnyWBPersonAutocomplete {
  my ($words) = @_;
  my $max_results     = 20;
  # if ($words =~ m/^.{5,}/) { $max_results = 500; }		# Chris doesn't find this useful
  my $lcwords = lc($words);
  my $limit       = $max_results + 1;
  my %matches; my $t = tie %matches, "Tie::IxHash";     # sorted hash to filter results
  my @tables = qw( two_standardname );
  foreach my $table (@tables) {
    $result = $dbh->prepare( "SELECT * FROM $table WHERE LOWER($table) ~ '^$lcwords' AND joinkey NOT IN (SELECT joinkey FROM two_status WHERE two_status = 'Invalid') ORDER BY $table LIMIT $limit;" );      # match by start of name
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
    while ( (my @row = $result->fetchrow()) && (scalar keys %matches < $max_results) ) {
      my $id = $row[0]; $id =~ s/two/WBPerson/;
      my $elementText = qq($row[2] <span style='font-size:.75em'>( $id )</span>);
      my $matchData = qq({ "eltext": "$elementText", "name": "$row[2]", "id": "$id" }); $matches{$matchData}++; 
    }
    $result = $dbh->prepare( "SELECT * FROM $table WHERE LOWER($table) ~ '$lcwords' AND joinkey NOT IN (SELECT joinkey FROM two_status WHERE two_status = 'Invalid') ORDER BY $table LIMIT $limit;" );          # then match anywhere in the name
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
    while ( (my @row = $result->fetchrow()) && (scalar keys %matches < $max_results) ) {
      my $id = $row[0]; $id =~ s/two/WBPerson/;
      my $elementText = qq($row[2] <span style='font-size:.75em'>( $id )</span>);
      my $matchData = qq({ "eltext": "$elementText", "name": "$row[2]", "id": "$id" }); $matches{$matchData}++; 
    }
    $result = $dbh->prepare( "SELECT * FROM $table WHERE joinkey ~ '$lcwords' AND joinkey NOT IN (SELECT joinkey FROM two_status WHERE two_status = 'Invalid') ORDER BY joinkey LIMIT $limit;" );               # then match by WBPerson number
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
    while ( (my @row = $result->fetchrow()) && (scalar keys %matches < $max_results) ) {
      my $id = $row[0]; $id =~ s/two/WBPerson/;
      my $elementText = qq($row[2] <span style='font-size:.75em'>( $id )</span>);
      my $matchData = qq({ "eltext": "$elementText", "name": "$row[2]", "id": "$id" }); $matches{$matchData}++; 
    }
    last if (scalar keys %matches >= $max_results);
  }
  if (scalar keys %matches >= $max_results) { 
    my $matchData = qq({ "eltext": "<span style='font-style: italic; background-color: yellow;'>More matches exist; please be more specific</span>", "name": "", "id": "invalid value" }); 
    $t->Replace($max_results - 1, 'no value', $matchData); }
  my $matches = join", ", keys %matches;
  $matches = qq({ "results": [ $matches ] });
  return $matches;
} # sub getAnyWBPersonAutocomplete


sub asyncTermInfo {
  print "Content-type: text/plain\n\n";
  ($var, my $field)   = &getHtmlVar($query, 'field');
  ($var, my $termid)  = &getHtmlVar($query, 'termid');
  my $matches;

  if ( $fields{$field}{type} eq 'ontology' ) {
      ($matches) = &getAnyTermInfo($field, $termid); }      # generic obo and specific are different
    elsif ($field eq 'pmid') { $matches = &getPmidTermInfo($termid); }

  print "$matches\n";
} # sub asyncTermInfo

sub getAnyTermInfo {                                                    # call  &getAnySpecificTermInfo  or  &getGenericOboTermInfo  as appropriate
  my ($field, $termid) = @_; my $return_value = '';
  if ($fields{$field}{ontology_type} eq 'obo') {
      ($return_value) = &getGenericOboTermInfo($field, $termid); }
    else {
      my $ontology_type = $fields{$field}{ontology_type};
      ($return_value) = &getAnySpecificTermInfo($ontology_type, $termid); }
  return $return_value;
} # sub getAnyTermInfo

sub getGenericOboTermInfo {
  my ($field, $termid) = @_;
  my $obotable = $fields{$field}{ontology_table};
  if ($termid =~ m/\[.*?\]$/) { $termid =~ s/\[.*?\]$//; }
  unless ($termid) { return ''; }
  my $joinkey = $termid;
  if ($joinkey) {
    my $data_table =  'obo_data_' . $obotable;
    $result = $dbh->prepare( "SELECT * FROM $data_table WHERE joinkey = '$joinkey';" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; my @row = $result->fetchrow();
    unless ($row[1]) {
      my $name_table = 'obo_name_' . $obotable;
      $result = $dbh->prepare( "SELECT * FROM $data_table WHERE joinkey IN (SELECT joinkey FROM $name_table WHERE $name_table = '$joinkey');" );
      $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; my @row = $result->fetchrow(); }
#     unless ($row[1]) { return ''; }
    unless ($row[1]) { return qq(Term '$termid' is not recognized.); }
    my (@data) = split/\n/, $row[1];
    foreach my $data_line (@data) { 
      if ($data_line =~ /id: WBVar\d+/) {                  $data_line =~ s/(WBVar\d+)/<a href=\"http:\/\/www.wormbase.org\/species\/c_elegans\/variation\/${1}#065--10\" target=\"new\">$1<\/a>/; }
      if ($data_line =~ /gene: "WBGene\d+ /) {             $data_line =~ s/(WBGene\d+)/<a href=\"http:\/\/www.wormbase.org\/db\/get?name=${1};class=Gene\" target=\"new\">$1<\/a>/; }
      if ($data_line =~ /id : <\/span> WBPhenotype:\d+/) { $data_line =~ s/(WBPhenotype:\d+)/<a href=\"http:\/\/www.wormbase.org\/species\/all\/phenotype\/${1}#06453--10\" target=\"new\">$1<\/a>/; }
      if ( ($field eq 'strain') && ($data_line =~ /id: [A-Z]+\d+/) ) {               $data_line =~ s/id: ([A-Z]+\d+)/id: <a href=\"http:\/\/www.wormbase.org\/species\/c_elegans\/strain\/${1}#03214--10\" target=\"new\">$1<\/a>/; }
      if ($data_line =~ /^(.*?(?:child|parent) : <\/span> )<a href.*?>(.*?)<\/a>/) { $data_line =~ s/^(.*?(?:child|parent) : <\/span> )<a href.*?>(.*?)<\/a>/${1}${2}/; }	# remove hyperlinks for parent + child (for phenotype)
      next if ($data_line =~ m/<span/);			# some already have bold span in the data
      $data_line =~ s/^(.*?):/<span style=\"font-weight: bold\">$1 : <\/span>/; }
    my $data = join"<br />\n", @data;
    if ($field eq 'allele') { 
      my ($wbvarid) = $row[1] =~ m/id: (WBVar\d+)/; 
      my $wbvar_link = qq(<a href="http://www.wormbase.org/species/c_elegans/variation/${wbvarid}#065--10" target="new" style="font-weight: bold; text-decoration: underline;">here</a>);
      $data = qq(Click $wbvar_link to see known phenotypes for this allele<br/>\n) . $data; }
    return $data;
  } # if ($joinkey)
} # sub getGenericOboTermInfo

sub getAnySpecificTermInfo {
  my ($ontology_type, $userValue) = @_; my $matches = '';
  if ($ontology_type eq 'WBPerson') {          ($matches) = &getAnyWBPersonTermInfo($userValue); }
  return $matches;
} # sub getAnySpecificTermInfo

sub getAnyWBPersonTermInfo {
  my ($userValue) = @_;
  my $person_id = $userValue; my $standard_name; my $to_print;
#   my $standard_name = $userValue; my $person_id; my $to_print;
#   if ($userValue =~ m/(.*?) \( (.*?) \)/) { $standard_name = $1; $person_id = $2; } else { $person_id = $userValue; }
  my $joinkey = $person_id; $joinkey =~ s/WBPerson/two/g;
  $result = $dbh->prepare( "SELECT * FROM two_standardname WHERE joinkey = '$joinkey' ORDER BY two_timestamp DESC;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; my @row = $result->fetchrow();
  my %emails; if ($row[2]) { $standard_name = $row[2]; }
  $result = $dbh->prepare( "SELECT * FROM two_email WHERE joinkey = '$joinkey';" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { if ($row[2]) { $emails{$row[2]}++; } }
  ($joinkey) = $joinkey =~ m/(\d+)/;
  my $id = 'WBPerson' . $joinkey;
  if ($id) { $to_print .= qq(id: <a href="http://www.wormbase.org/resources/person/${person_id}#03--10" target="new">$id</a><br />\n); }
  if ($standard_name) { $to_print .= "name: $standard_name<br />\n"; }
  my $first_email = '';
  foreach my $email (sort keys %emails ) {
    unless ($first_email) { $first_email = $email; }
    $to_print .= "email: <a href=\"javascript:void(0)\" onClick=\"window.open('mailto:$email')\">$email</a><br />\n"; }
  my %picturesource;
  $result = $dbh->prepare( "SELECT obo_data_picturesource FROM obo_data_picturesource WHERE joinkey = '$id' ;" ); 
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { if ($row[0]) { $picturesource{$joinkey}{$row[0]}++; } }
  foreach my $picturesource (sort keys %{ $picturesource{$joinkey}}) {  # all this obo data is in one entry, so split and print with <br /> 2010 12 06
    my (@lines) = split/\n/, $picturesource; foreach my $line (@lines) { $to_print .= "$line<br />\n"; } }
  my (@data) = split/\n/, $to_print;
  foreach my $data_line (@data) { $data_line =~ s/^(.*?):/<span style=\"font-weight: bold\">$1 : <\/span>/; }
  $to_print = join"\n", @data;
#   $to_print = qq(Click <a href="phenotype.cgi?action=personPublication&personId=${person_id}&personName=${standard_name}&personEmail=${first_email}" target="new" style="font-weight: bold; text-decoration: underline;">here</a> to review your publications and see which are in need of phenotype curation<br/>\n) . $to_print;

#   ($var, $personId)      = &getHtmlVar($query, 'personId');		# WBPerson ID
#   ($var, $personName)    = &getHtmlVar($query, 'personName');		# WBPerson Name
#   ($var, $personEmail)   = &getHtmlVar($query, 'personEmail');		# email address
  return $to_print;
} # sub getAnyWBPersonTermInfo


__END__

