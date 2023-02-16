package Jex;
require Exporter;

use LWP::Simple;
use Mail::Mailer;

our @ISA	= qw(Exporter);
our @EXPORT	= qw(untaint filterForPg getDate getHeader printHeader printFooter getPgDate cshlNew caltechOld getHtmlSelectVars getHtmlVar getHtmlVarFree mailer getSimpleSecDate getSimpleDate filterToPrintHtml getOboDate );
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
<LINK rel="stylesheet" type="text/css" href="http://tazendra.caltech.edu/~azurebrd/stylesheets/wormbase.css">

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
<LINK rel="stylesheet" type="text/css" href="http://tazendra.caltech.edu/~azurebrd/stylesheets/wormbase.css">
<!--<LINK rel="stylesheet" type="text/css" href="http://www.wormbase.org/stylesheets/wormbase.css">-->

<HEAD>
EndOfText
  print "<TITLE>$title</TITLE>";
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
  my $page = get "http://tazendra.caltech.edu/~azurebrd/sanger/wormbaseheader/WB_header_footer.html";
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

sub mailer {            	# send non-attachment mail
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
