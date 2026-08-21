package Jex;
require Exporter;

use LWP::Simple;
use Mail::Mailer;

use Email::Simple;
use Email::Sender::Simple qw(sendmail);
use Net::SMTP::SSL;
use Encode qw(encode);

use CGI::Cookie;

use Dotenv -load => '/usr/lib/.env';


our @ISA	= qw(Exporter);
our @EXPORT	= qw(untaint filterForPg getDate getHeader printHeader printFooter getPgDate cshlNew caltechOld getHtmlSelectVars getHtmlVar getHtmlVarFree mailer getSimpleSecDate getSimpleDate filterToPrintHtml getOboDate readSavedCuratorFromCookie readSavedUserFromCookie);
our $VERSION	= 1.00;

sub getPgDate {                         # begin getPgDate
  my $time = time;                      # set time
  my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) =
          localtime($time);             # get time
  if ($sec < 10) { $sec = "0$sec"; }    # add a zero if needed
  if ($min < 10) { $min = "0$min"; }    # add a zero if needed
  if ($mday < 10) { $mday = "0$mday"; } # add a zero if needed
  my $sam = $mon+1;                     # get right month
  if ($sam < 10) { $sam = "0$sam"; }    # add a zero if needed
  $year = 1900+$year;                   # get right year in 4 digit form
  my $todaydate = "${year}-${sam}-${mday}"; 
                                        # set current date
  my $date = $todaydate . " $hour\:$min\:$sec";
                                        # set final date
  return $date;
} # sub getPgDate                       # end getPgDate

sub getOboDate {			# begin getOboDate
  my $time = time;                      # set time
  my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) =
          localtime($time);             # get time
  my $sam = $mon+1;                     # get right month
  $year = 1900+$year;                   # get right year in 4 digit form
  if ($sam < 10) { $sam = "0$sam"; }    # add a zero if needed
  if ($mday < 10) { $mday = "0$mday"; } # add a zero if needed
  if ($sec < 10) { $sec = "0$sec"; } # add a zero if needed
  if ($min < 10) { $min = "0$min"; } # add a zero if needed
  if ($hour < 10) { $hour = "0$hour"; } # add a zero if needed
  my $shortdate = "${mday}:${sam}:${year} ${hour}:${min}";   # get final date
  return $shortdate;
} # sub getOboDate			# end getOboDate

sub getSimpleDate {			# begin getSimpleDate
  my $time = time;                      # set time
  my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) =
          localtime($time);             # get time
  my $sam = $mon+1;                     # get right month
  $year = 1900+$year;                   # get right year in 4 digit form
  if ($sam < 10) { $sam = "0$sam"; }    # add a zero if needed
  if ($mday < 10) { $mday = "0$mday"; } # add a zero if needed
  my $shortdate = "${year}${sam}${mday}";   # get final date
  return $shortdate;
} # sub getSimpleDate			# end getSimpleDate

sub getSimpleSecDate {			# begin getSimpleDate
  my $time = time;                      # set time
  my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) =
          localtime($time);             # get time
  my $sam = $mon+1;                     # get right month
  $year = 1900+$year;                   # get right year in 4 digit form
  if ($sam < 10) { $sam = "0$sam"; }    # add a zero if needed
  if ($mday < 10) { $mday = "0$mday"; } # add a zero if needed
  if ($sec < 10) { $sec = "0$sec"; } # add a zero if needed
  if ($min < 10) { $min = "0$min"; } # add a zero if needed
  if ($hour < 10) { $hour = "0$hour"; } # add a zero if needed
  my $shortdate = "${year}${sam}${mday}.${hour}${min}${sec}";   # get final date
  return $shortdate;
} # sub getSimpleSecDate			# end getSimpleDate

sub getDate {                           # begin getDate
  my @days = qw(Sunday Monday Tuesday Wednesday Thursday Friday Saturday);
                                        # set array of days
  my @months = qw(January February March April May June
          July August September October November December);
                                        # set array of months
  my $time = time;                      # set time
  my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) =
          localtime($time);             # get time
  my $sam = $mon+1;                     # get right month
  my $shortdate = "$mday/$sam/$year";   # get final date
  my $ampm = "AM";                      # fiddle with am or pm
  if ($hour eq 12) { $ampm = "PM"; }    # PM if noon
  if ($hour eq 0) { $hour = "12"; }     # AM if midnight
  if ($hour > 12) {                     # get hour right from 24
    $hour = ($hour - 12);
    $ampm = "PM";                       # reset PM if after noon
  }
  if ($min < 10) { $min = "0$min"; }    # add a zero if needed
  $year = 1900+$year;                   # get right year in 4 digit form
  my $todaydate = "$days[$wday], $mday $months[$mon] $year";
                                        # set current date
  my $date = $todaydate . " $hour\:$min $ampm";
                                        # set final date
  return $date;
} # sub getDate                         # end getDate


sub untaint {
  my $tainted = shift;
  my $untainted;
  if ($tainted eq "") {
    $untainted = "";
  } else { # if ($tainted eq "")
    $tainted =~ s/[^\w\-.,;:?\/\\@#\$\%\^&*\>\<(){}[\]+=!~|' \t\n\r\f\"€‚ƒ„…†‡ˆ‰Š‹ŒŽ‘’“”•–—˜™š›œžŸ¡¢£¤¥¦§¨©ª«¬­®¯°±²³´¶·¹º»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞΑαΒβΓγΔδΕεΖζΗηΘθΙιΚκΛλΜμΝνΞξΟοΠπΡρΣσΤτΥυΦφΧχΨψΩωàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþ]//g;	# added \" for wbpaper_editor's gene evidence data 2005 07 14   added \> and \< for wbpaper_editor's abstract data  2005 12 13
    if ($tainted =~ m/^([\w\-.,;:?\/\\@#\$\%&\^*\>\<(){}[\]+=!~|' \t\n\r\f\"€‚ƒ„…†‡ˆ‰Š‹ŒŽ‘’“”•–—˜™š›œžŸ¡¢£¤¥¦§¨©ª«¬­®¯°±²³´¶·¹º»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞΑαΒβΓγΔδΕεΖζΗηΘθΙιΚκΛλΜμΝνΞξΟοΠπΡρΣσΤτΥυΦφΧχΨψΩωàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþ]+)$/) {
      $untainted = $1;
    } else {
      die "Bad data Tainted in $tainted";
    }
  } # else # if ($tainted eq "")
  return $untainted;
} # sub untaint

sub getHeader {
  my ($title) = @_;
  my $header = <<"EndOfText";
Content-type: text/html\n\n

<HTML>
<LINK rel="stylesheet" type="text/css" href="$ENV{THIS_HOST_AS_BASE_URL}pub/stylesheets/wormbase.css">

<HEAD>
EndOfText
  $header .= "<TITLE>$title</TITLE>";
  $header .= <<"EndOfText";
</HEAD>

<BODY bgcolor=#aaaaaa text=#000000 link=cccccc alink=eeeeee vlink=bbbbbb>
<HR>
EndOfText
  return $header;
} # sub getHeader

sub printHeader {
  my ($title) = @_;
  print <<"EndOfText";
Content-type: text/html\n\n

<HTML>
<LINK rel="stylesheet" type="text/css" href="$ENV{THIS_HOST_AS_BASE_URL}pub/stylesheets/wormbase.css">
<!--<LINK rel="stylesheet" type="text/css" href="http://tazendra.caltech.edu/~azurebrd/stylesheets/wormbase.css">-->
<!--<LINK rel="stylesheet" type="text/css" href="http://www.wormbase.org/stylesheets/wormbase.css">-->

<HEAD>
EndOfText
  print "<TITLE>$title</TITLE>";
  print "<script>";
  print "function setCookie(name, value) { var expiry = new Date(); expiry.setFullYear(expiry.getFullYear() +10); document.cookie = name + '=' + escape(value) + '; path=/; expires=' + expiry.toGMTString(); }";
  print "function saveCuratorIdInCookieFromSelect(selectElement) { var selectedValue = selectElement.value; setCookie('SAVED_CURATOR_ID', selectedValue); }";
  print "function saveUserIdInCookieFromSelect(selectElement) { var selectedValue = selectElement.value; setCookie('SAVED_USER_ID', selectedValue); }";
  print "</script>";
  print <<"EndOfText";
</HEAD>

<BODY bgcolor=#ffffff text=#000000 link="blue" alink=eeeeee vlink=bbbbbb>
<HR>
EndOfText
} # sub printHeader

sub printFooter {
  print "</BODY>\n</HTML>\n";
} # sub printFooter


sub cshlNew {
  my $title = shift;
  unless ($title) { $title = ''; }	# init title in case blank
  my $page = get "$ENV{THIS_HOST_AS_BASE_URL}files/pub/wormbaseheader/WB_header_footer.html";
#   my $page = get "https://caltech-curation.textpressolab.com:4432/files/pub/wormbaseheader/WB_header_footer.html";
#   my $page = get "http://tazendra.caltech.edu/~azurebrd/sanger/wormbaseheader/WB_header_footer.html";
#  $page =~ s/href="\//href="http:\/\/www.wormbase.org\//g;
#  $page =~ s/src="/src="http:\/\/www.wormbase.org/g;
  ($header, $footer) = $page =~ m/^(.*?)\s+DIVIDER\s+(.*?)$/s;	# 2006 11 20	# get this from tazendra's script result.
  $header =~ s/<title>.*?<\/title>/<title>$title<\/title>/g;
  return ($header, $footer);
} # sub cshlNew

sub oldcshlNew {
  my $title = shift;
  unless ($title) { $title = ''; }	# init title in case blank
  my $page = get "http://www.wormbase.org";
  $page =~ s/href="\//href="http:\/\/www.wormbase.org\//g;
  $page =~ s/src="/src="http:\/\/www.wormbase.org/g;
#  ($header) = $page =~ m/^(.*?\<hr\>.*?\<hr\>)/s;
#  ($header) = $page =~ m/^(.*?\<hr \/\>\n<p\>)\n<table/s;	# 2002 05 14
#  ($header) = $page =~ m/^(.*?\<\/table\><p\>)\n<table/s;	# 2002 05 14
#  ($header) = $page =~ m/^(.*?\<\/head\>)/s;			# 2005 10 18
#  ($header) = $page =~ m/^(.*?\<\/table\><p\>)\n+(\<div.*?div\>)?\n*?<table/s;	# 2005 10 18	# someone added a user survey here
#  ($header) = $page =~ m/^(.*?\<\/table\>)\n<table/s;		# 2006 02 03	# survey gone, changed again
#  ($header) = $page =~ m/^(.*?\<\/div\>)\n\n<table/s;		# 2006 08 22	# survey back, changed again
#  ($header) = $page =~ m/^(.*?alt=\"WormBase Banner\" \/><\/a><\/td><\/tr><\/table>)/s;	# 2006 09 11	# survey gone, changed again
#  ($header) = $page =~ m/^(.*?alt=\"WormBase Banner\"><\/a><\/td><\/tr><\/table>)/s;	# 2006 09 19	# minor change, changed again
#  ($header) = $page =~ m/^(.*?alt=\"WormBase Banner\"[^>]{0,100}><\/a><\/td><\/tr><\/table>)/s;	# 2006 09 21	# minor change, changed again
#  ($header) = $page =~ m/^(.*?alt=\"WormBase Banner\"[^>]{0,100}>\n?<\/a><\/td><\/tr><\/table>)/s;	# 2006 10 07	# minor change, changed again
  ($header) = $page =~ m/^(.*?)<!-- \$MTInclude module/s;	# 2006 11 20	# Todd keeps changing stuff
  $header =~ s/WormBase - Home Page/$title/g;
  ($footer) = $page =~ m/.*(\<hr\>.*?)$/s;			# 2002 05 14
  return ($header, $footer);
} # sub oldcshlNew

sub caltechOld {
  $page = get "http://caltech.wormbase.org";            # get template
  $page =~ s/href="\//href="http:\/\/caltech.wormbase.org\//gi; # set references right
  $page =~ s/src="/src="http:\/\/caltech.wormbase.org/gi;       # set references right
  $page =~ s/Home Page/Expression Pattern Form/g;       # set references right
  @page = split("\n", $page);                   # break up to play with
  my $i = 0;                                    # counter
  while ($line !~ m/long-release-start/) {      # until what we don't want
    $line = $page[$i];                          # get line
    @header = (@header, $page[$i]);             # add to header
    $i++                                                # add to counter
  } # while ($line !~ ...
  $toomany = scalar(@header);                   # get last line to remove
  $header[$toomany-1] = "";                     # remove last line
  $header = join("\n", @header);                        # put header together
  while ($line !~ m/footer/) {                  # until we get to footer
    $line = $page[$i];                          # read lines
    $i++                                                # add to counter
  } # while ($line !~ ...
  for (my $j = $i; $j <= scalar(@page)-1; $j++) { # from here to out of lines
    @footer = (@footer, $page[$j]);             # add to footer
  } # for (my $j ...
  $footer = join("\n", @footer);                        # put footer together
} # sub caltechOld

sub getHtmlSelectVars {
  no strict 'refs';             # need to disable refs to get the values
                                # possibly a better way than this
  my ($query, $var, $err) = @_; # get the CGI query val,
                                # get the name of the variable to query->param,
                                # get whether to display and error if no such
                                # variable found
  my @oop = ();                 # initialize return
  if ($query->param("$var")) {  # if variable found
      @oop = $query->param("$var");         # get the array
      if (scalar @oop > 0) {    # if there are values
          foreach my $oop (@oop) { $oop = &untaint($oop); } }   # untaint each value
        else { @oop = (); }     # if no values, set to blank
      return @oop; }           # return the array
    else {                      # if no variable found
      if ($err) {               # if we want error displayed, display error
        print "<FONT COLOR=blue>ERROR : No such variable : $var</FONT><BR>\n"; }
      return @oop; }           # return empty array
  # sample use
  # my (@arrayName)        = &getHtmlSelectVars($query, 'variable');
} # sub getHtmlSelectVars

sub getHtmlVar {		# get variables from html form and untaint them
  no strict 'refs';		# need to disable refs to get the values
				# possibly a better way than this
  my ($query, $var, $err) = @_;	# get the CGI query val, 
				# get the name of the variable to query->param,
				# get whether to display and error if no such
				# variable found
  unless ($query->param("$var")) {		# if no such variable found
    if ($err) {			# if we want error displayed, display error
      print "<FONT COLOR=blue>ERROR : No such variable : $var</FONT><BR>\n";
    } # if ($err) 
  } else { # unless ($query->param("$var"))	# if we got a value
    my $oop = $query->param("$var");		# get the value
    $$var = &untaint($oop);			# untaint and put value under ref
    return ($var, $$var);			# return the variable and value
  } # else # unless ($query->param("$var"))
  # sample use
  # my @vars = qw(locus sequence clone);	# variables to get from html
  # foreach $_ (@vars) { my ($var, $val) = &getHtmlVar("$_"); }
				# get the value and set the variable and value
  # foreach $_ (@vars) { my ($var, $val) = &getHtmlVar("$_", 1); }
				# same, but with error display flag
} # sub getHtmlVar

sub getHtmlVarFree {            # get variables from html form and do not untaint them, to allow utf-8 through
  no strict 'refs';             # need to disable refs to get the values
  my ($query, $var, $err) = @_; # get the CGI query val, 
                                # get the name of the variable to query->param,
                                # get whether to display an error if no such variable found
  if ($query->param("$var")) {                  # if we got a value
    my $oop = $query->param("$var");            # get the value
#     $$var = &untaint($oop);                   # untaint and put value under ref       # do not untaint to allow any utf-8 characters through
#     return ($var, $$var);                     # return the variable and value
    return ($var, $oop);                        # return the variable and value
  } else { # if ($query->param("$var"))         # if no such variable found
    if ($err) {                                 # if we want error displayed, display error
      print "<FONT COLOR=blue>ERROR : No such variable : $var</FONT><BR>\n"; }
  } # else # if ($query->param("$var"))
} # sub getHtmlVarFree

# AWS SES SMTP settings.  Only EMAIL_SMTP_USER and EMAIL_PASSWD have to be set
# in /usr/lib/.env - the same two variables the ACKnowledge and barista backends
# read.  The other four are optional overrides.
# Gmail used to double as the sender address, but the SES SMTP username is an
# opaque credential rather than an address, so the visible sender now comes from
# EMAIL_FROM.  EMAIL_FROM has to be an SES-verified identity; textpressolab.com
# is verified as a parent domain, so any subdomain of it sends without further
# DNS setup.
my $DEFAULT_EMAIL_HOST = 'email-smtp.us-east-1.amazonaws.com';
my $DEFAULT_EMAIL_PORT = 465;
my $DEFAULT_EMAIL_FROM = 'WormBase Curation <no-reply@caltech-curation.textpressolab.com>';

sub bareEmailAddress {		# 'Some Name <a@b.org>' becomes 'a@b.org' for the smtp envelope
  my $address = shift;
  if ($address =~ m/<([^>]+)>/) { $address = $1; }
  $address =~ s/^\s+//; $address =~ s/\s+$//;
  return $address;
} # sub bareEmailAddress

sub mailer {                    # send non-attachment mail through AWS SES
  # $user is accepted but unused, so that the existing call sites keep working.
  # The visible sender must be an SES-verified identity now, it can no longer be
  # whatever address the caller happened to pass in.
  my ($user, $email, $subject, $body, $cc, $content_type, $reply_to) = @_;
  my $host = $ENV{EMAIL_HOST} || $DEFAULT_EMAIL_HOST;
  my $port = $ENV{EMAIL_PORT} || $DEFAULT_EMAIL_PORT;
  my $from = $ENV{EMAIL_FROM} || $DEFAULT_EMAIL_FROM;
  unless (defined $email)   { $email   = ''; }
  unless (defined $cc)      { $cc      = ''; }
  unless (defined $body)    { $body    = ''; }
  unless (defined $subject) { $subject = ''; }
  unless ($content_type)    { $content_type = 'text/plain'; }
  unless ($content_type =~ m/charset/i) { $content_type .= '; charset=UTF-8'; }
  $email =~ s/\s+//g;
  $cc    =~ s/\s+//g;
  my @recipients    = grep { m/\S/ } split/,/, $email;
  my @cc_recipients = grep { m/\S/ } split/,/, $cc;
  unless (@recipients || @cc_recipients) {
    warn qq(mailer: no recipients for "$subject", nothing sent\n); return 0; }
  # Reply-To defaults to everyone the message went to, so that a submitter
  # hitting reply reaches all the curators on the thread, which is how these
  # forms have always been read.  It cannot just be left off: the old From was
  # outreach@wormbase.org, a mailbox somebody watches, but EMAIL_FROM is a
  # no-reply address because SES will only sign for a domain it has verified, so
  # with no Reply-To a plain reply would go nowhere.  An explicit argument wins,
  # then EMAIL_REPLY_TO from .env when it is set to a fixed address on purpose.
  unless ($reply_to) { $reply_to = $ENV{EMAIL_REPLY_TO}; }
  if ($reply_to) {			# tidy a list that came in with stray spaces or a trailing comma
    my @replyToAddresses;
    foreach my $address (split/,/, $reply_to) {
      $address =~ s/^\s+//; $address =~ s/\s+$//;	# trim around only, a display name may contain spaces
      if ($address =~ m/\S/) { push @replyToAddresses, $address; }
    }
    $reply_to = join(', ', @replyToAddresses);
  }
  unless ($reply_to) { $reply_to = join(', ', @recipients, @cc_recipients); }
  if (utf8::is_utf8($body))    { $body    = encode('UTF-8', $body); }		# else Email::Simple warns 'Body with wide characters' and sends mangled bytes
  if (utf8::is_utf8($subject)) { $subject = encode('MIME-Header', $subject); }	# rfc 2047 for a non-ascii subject
  my @header = ( From => $from, To => join(', ', @recipients) );
  if (@cc_recipients) { push @header, ( Cc => join(', ', @cc_recipients) ); }
  if ($reply_to)      { push @header, ( 'Reply-To' => $reply_to ); }
  push @header, ( Subject        => $subject,
                  'MIME-Version' => '1.0',
                  'Content-Type' => $content_type );
  my $email_object = Email::Simple->create(
      header => \@header,
      body   => $body,
  );

  unless ($ENV{EMAIL_SMTP_USER} && $ENV{EMAIL_PASSWD}) {
    warn qq(mailer: EMAIL_SMTP_USER / EMAIL_PASSWD not set in .env, "$subject" not sent\n); return 0; }

  # Send failures are logged and returned, not fatal.  Form submissions are
  # already written to postgres by the time the confirmation mail goes out, so
  # dying here would show the submitter an error page for data that did save.
  # Callers that care can check the return value; every outcome lands in the
  # apache or cron log with a 'mailer:' prefix so an outage is visible.
  my $smtp = Net::SMTP::SSL->new( $host, Port => $port );
  unless ($smtp) {
    warn qq(mailer: cannot connect to $host:$port, "$subject" not sent\n); return 0; }
  unless ($smtp->auth($ENV{EMAIL_SMTP_USER}, $ENV{EMAIL_PASSWD})) {
    warn qq(mailer: smtp auth failed at $host, "$subject" not sent : ) . &smtpError($smtp);
    $smtp->quit; return 0; }
  unless ($smtp->mail(&bareEmailAddress($from))) {
    warn qq(mailer: sender $from rejected by $host, "$subject" not sent : ) . &smtpError($smtp);
    $smtp->quit; return 0; }
  # SkipBad, because Net::SMTP::recipient otherwise fails the whole call on the
  # first rejected address.  Forms put a submitter-typed address in To and the
  # curators in Cc, so one typo would drop the curators' copy too, which the
  # gmail code did deliver.  Only give up when nothing at all was accepted.
  my @allRecipients = (@recipients, @cc_recipients);
  my @accepted = $smtp->recipient(@allRecipients, { SkipBad => 1 });
  unless (@accepted) {
    warn qq(mailer: every recipient rejected by $host, "$subject" not sent : ) . &smtpError($smtp);
    $smtp->quit; return 0; }
  if (scalar(@accepted) < scalar(@allRecipients)) {
    my %isAccepted; foreach my $address (@accepted) { $isAccepted{$address}++; }
    my @rejected = grep { ! $isAccepted{$_} } @allRecipients;
    warn qq(mailer: $host rejected ) . join(', ', @rejected) . qq( for "$subject", sending to the others\n); }
  unless ($smtp->data()) {
    warn qq(mailer: $host refused DATA, "$subject" not sent : ) . &smtpError($smtp);
    $smtp->quit; return 0; }			# else datasend writes the body where the server expects commands
  $smtp->datasend($email_object->as_string);
  unless ($smtp->dataend()) {
    warn qq(mailer: $host refused the message, "$subject" not sent : ) . &smtpError($smtp);
    $smtp->quit; return 0; }
  $smtp->quit;
  warn qq(mailer: sent "$subject" to ) . join(', ', @accepted) . qq(\n);
  return 1;

  # sample use
  # if ( $send_email) { &mailer($user, $email, $subject, $body); }
  # html with a cc and a form specific reply-to :
  # &mailer($user, $email, $subject, $body, $cc, 'text/html', 'curation@wormbase.org');
} # sub mailer

sub smtpError {			# last response from the smtp server, for the log line
  my $smtp = shift;
  my $message = $smtp->message(); unless (defined $message) { $message = ''; }
  $message =~ s/\s+/ /g; $message =~ s/\s+$//;
  return $smtp->code() . qq( $message\n);
} # sub smtpError

sub old_tazendra_mailer {            	# send non-attachment mail
  my ($user, $email, $subject, $body) = @_;
  my $command = 'sendmail';
  my $mailer = Mail::Mailer->new($command) ;
  $mailer->open({ From    => $user,
                  To      => $email,
#                 Cc      => 'curationmail@minerva.caltech.edu, $user',
                  Subject => $subject,
                })
      or die "Can't open: $!\n";
  print $mailer $body;
  $mailer->close();
  # sample use
  # if ( $send_email) { &mailer($user, $email, $subject, $body); }
} # sub mailer

sub readSavedCuratorFromCookie {
  my %cookies = CGI::Cookie->fetch;
  my $saved_curator = $cookies{'SAVED_CURATOR_ID'} ? $cookies{'SAVED_CURATOR_ID'}->value : '';
  return $saved_curator;
}

sub readSavedUserFromCookie {
  my %cookies = CGI::Cookie->fetch;
  my $saved_user = $cookies{'SAVED_USER_ID'} ? $cookies{'SAVED_USER_ID'}->value : '';
  return $saved_user;
}

sub filterToPrintHtml {
  my $val = shift;
  $val =~ s/\&/&amp;/g;                         # filter out ampersands first
  $val =~ s/\"/&quot;/g;                        # filter out double quotes
  $val =~ s/\</&lt;/g;                          # filter out open angle brackets
  $val =~ s/\>/&gt;/g;                          # filter out close angle brackets
  # $val =~ s/\n/<BR>/g;
  return $val;
} # sub filterToPrintHtml

sub filterForPg {
  my $val = shift;
  if ($val) {
    if ($val =~ m/\'/) { $val =~ s/\'/''/g; }
#     if ($val =~ m/[^\w\-.,;:?\/\\@#\$\%\^&*\>\<(){}[\]+=!~|' \t\n\r\f\"]/) {		# allows utf-8, so do not filter on these
#       $val =~ s/[^\w\-.,;:?\/\\@#\$\%\^&*\>\<(){}[\]+=!~|' \t\n\r\f\"]//g; }    # based on untaint to strip non utf stuff : DBD::Pg::db do failed: ERROR:  invalid byte sequence for encoding "UTF8": 0xc561
    if ($val =~ m/\s+$/) { $val =~ s/\s+$//; }
    if ($val =~ m/^\s+/) { $val =~ s/^\s+//; }
  }
  return $val;
}



1;
