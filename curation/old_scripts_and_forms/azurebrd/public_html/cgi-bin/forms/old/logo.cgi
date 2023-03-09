#!/usr/bin/perl -T

# Form to submit Logo votes.
# Password checking, passwd mailed with 
# /home/azurebrd/public_html/cgi-bin/forms/logo/mailer.pl
# Checks that no multiple logos or banners have the same ranking.
# Output to /home/azurebrd/public_html/cgi-bin/data/logo
# include IP, email address, top 3 logos, top 3 banners.  2002 07 30
#
# Updated to use new index.html (take_two) for second part of voting.
# Updated to read in font_colored and font_colored_bold selections
# and highlight appropriately via hash (crumby code)  2002 08 05

my $acefile = "/home/azurebrd/public_html/cgi-bin/data/logo";

my $firstflag = 1;		# flag if first time around (show form for no data)

use LWP::Simple;
use Mail::Mailer;

my ($header, $footer) = &cshlNew();

use Jex;			# untaint, getHtmlVar, cshlNew
use strict;
use CGI;
use Fcntl;

my $query = new CGI;
my $user = 'logo_form';		# who sends mail
my $email = "wchen\@its.caltech.edu";		# to whom send mail
my $subject = 'logo vote';	# subject of mail
my $body = '';					# body of mail

my @logos;			# image files of logos
my @banners;			# image files of banners
my %logo_color;			# hash of logos with color
my %logo_bold;			# hash of logos with bold color
my %banner_color;		# hash of banners with color
my %banner_bold;		# hash of banners with bold color

my %passwd;			# email address keys, passwd values

print "Content-type: text/html\n\n";
print "$header\n";		# make beginning of HTML page

&populatePasswd();		# populate passwords
&process();			# see if anything clicked
&display();			# show form as appropriate
print "$footer"; 		# make end of HTML page

sub process {			# see if anything clicked
  my $action;			# what user clicked
  unless ($action = $query->param('action')) { $action = 'none'; }

  if ($action eq 'Vote !') { 
    my $host = $query->remote_host();
    $firstflag = "";		# reset flag to not display first page (form)
    open (OUT, ">>$acefile") or die "Cannot create $acefile : $!";

    my $errorflag = 0;		# errorflag is default to zero, if vote duplicated, flag
    my %votes;			# store votes

    my ($var, $passwd) = &getHtmlVar($query, 'passwd');
    my ($var, $email) = &getHtmlVar($query, 'email_address');
#     print "$email $passwd<BR>\n";
    unless ($passwd{$email} eq "$passwd") { 
      print "<FONT COLOR=\"red\" SIZE=+2><B>ERROR</B></FONT> : Password and Email don't match.<BR>\n";
      $errorflag++;
    }

    &getIndex();		# get @logos and @banners from index.html
    foreach my $logo (@logos) {
      my ($logo_name) = $logo =~ m/^(\w+)\.\w+$/;
      my ($var, $val) = &getHtmlVar($query, $logo_name);
      if ($val) {
        if ($val eq 'Favourite') { push @{ $votes{logo}{favourite} }, $var; }
        if ($val eq 'Second Favourite') { push @{ $votes{logo}{second} }, $var; }
        if ($val eq 'Third Favourite') { push @{ $votes{logo}{third} }, $var; }
      } # if ($val)
    } # foreach my $logo (@logos)
    foreach my $banner (@banners) {
      my ($banner_name) = $banner =~ m/^(\w+)\.\w+$/;
      my ($var, $val) = &getHtmlVar($query, $banner_name);
      if ($val) {
        if ($val eq 'Favourite') { push @{ $votes{banner}{favourite} }, $var; }
        if ($val eq 'Second Favourite') { push @{ $votes{banner}{second} }, $var; }
        if ($val eq 'Third Favourite') { push @{ $votes{banner}{third} }, $var; }
      } # if ($val)
    } # foreach my $banner (@banners)
 
    foreach my $icon_type ( sort keys %votes ) {
      foreach my $vote_type ( sort keys %{ $votes{$icon_type} } ) {
        if ( scalar ( @{ $votes{$icon_type}{$vote_type} } ) > 1 ) { 
          print "You've chosen $vote_type $icon_type @{ [scalar(@{ $votes{$icon_type}{$vote_type} })] } times : ";
          foreach $_ (@{ $votes{$icon_type}{$vote_type} } ) { print " $_ "; }
          print "<P>\n";
          $errorflag++;
          print "<FONT COLOR=\"red\" SIZE=+2><B>ERROR</B></FONT> : Please select only three choices.<BR>\n";
        } # if ( scalar ( @{ $votes{$icon_type}{$vote_type} } ) > 1 )
      } # foreach my $vote_type ( sort keys %{ $votes{$icon_type} } )
    } # foreach my $vote_type ( sort keys %votes )

    if ($errorflag) {
      $firstflag = 1;		# flag to show the form again
    } else { # unless ($errorflag)
#       &mailer($user, $email, $subject, $body);	# email wen the data
      print OUT "$host\t$email\t$votes{logo}{favourite}[0]\t$votes{logo}{second}[0]\t$votes{logo}{third}[0]";
      print OUT "\t$votes{banner}{favourite}[0]\t$votes{banner}{second}[0]\t$votes{banner}{third}[0]\n";
      print "<P><P><P><H1>Thank you $host, your vote has been recorded.</H1>\n";
      print "Logo : favourite is $votes{logo}{favourite}[0], second favourite is $votes{logo}{second}[0], and third favourite is $votes{logo}{third}[0] .<BR>\n";
      print "Banner : favourite is $votes{banner}{favourite}[0], second favourite is $votes{banner}{second}[0], and third favourite is $votes{banner}{third}[0] .<BR>\n";
    } # else # unless ($errorflag)
    close (OUT) || die "cannot close $acefile : $!";
  } # if ($action eq 'Vote !') 
} # sub process

sub formBox {
} # sub formBox

sub display {			# show form as appropriate
  if ($firstflag) { # if first or bad, show form 
    print "<A NAME\=\"form\"><H1>WormBase Logo Competition :</H1></A>\n";

    print <<"EndOfText";
Select only <B>three</B> (3 logos + 3 banners), ranking them as favourite, second favourite,
and third favourite, then click ``Vote !'' below.<BR><BR>
The <FONT COLOR="ff00aa">highlighted</FONT> logos are the top favourites from the first round.<BR><BR>
<HR>
<FORM METHOD="POST" ACTION="logo.cgi">
EndOfText

  &getIndex();			# get @logos and @banners from index.html

  print "Select your email address from the list below and type in the password emailed to you.<BR>\n";
  print "<SELECT NAME=\"email_address\" SIZE=1>\n";
  print "<OPTION> </OPTION>\n";
  foreach $_ (sort keys %passwd) { print "<OPTION>$_</OPTION>\n"; }
  print "</SELECT>\n";
  print "<INPUT NAME=\"passwd\" SIZE=20><P>\n";
  

  print "<TABLE border = 0><TR>\n";
  print "<TR><TD></TD><TD><B><FONT SIZE=+2>Logo Entries : </FONT></B></TD></TR>\n";

  foreach my $logo (@logos) { 
    my ($logo_name) = $logo =~ m/^(\w+)\.\w+$/;
    print "<TR>\n";
    if ($logo_color{$logo_name}) { print "<TD><FONT COLOR=\"ff00aa\">"; }
      elsif ($logo_bold{$logo_name}) { print "<TD><FONT COLOR=\"ff00aa\"><B>"; }
      else { print "<TD><FONT COLOR=\"000000\">"; }
    print "Code : $logo_name </B></TD></FONT><TD align = center><img SRC=\"logo/$logo\"><BR><HR><BR></TD>\n";
    print "<TD align = right><SELECT NAME=\"$logo_name\" SIZE=1>\n";
    my @options = ('', 'Favourite', 'Second Favourite', 'Third Favourite');
    foreach $_ (@options) { print "<OPTION>$_</OPTION>\n"; }
    print "</SELECT><BR></TD>\n";
    print "</TR><TR></TR>\n";
  } # foreach my $logo (@logos)

    print "<TR></TR><TR></TR><TR></TR><TR></TR>\n";
    print "<TR><TD></TD><TD><B><FONT SIZE=+2>Banner Entries : </FONT></B></TD></TR>\n";

  foreach my $banner (@banners) { 
    my ($banner_name) = $banner =~ m/^(\w+)\.\w+$/;
    print "<TR>\n";
    if ($banner_color{$banner_name}) { print "<TD><FONT COLOR=\"ff00aa\">"; }
      elsif ($banner_bold{$banner_name}) { print "<TD><FONT COLOR=\"ff00aa\"><B>"; }
      else { print "<TD><FONT COLOR=\"000000\">"; }
    print "Code : $banner_name </B></TD></FONT><TD align = center><img SRC=\"logo/$banner\"><BR><HR><BR></TD>\n";
    print "<TD align = right><SELECT NAME=\"$banner_name\" SIZE=1>\n";
    my @options = ('', 'Favourite', 'Second Favourite', 'Third Favourite');
    foreach $_ (@options) { print "<OPTION>$_</OPTION>\n"; }
    print "</SELECT><BR></TD>\n";
    print "</TR><TR></TR>\n";
  } # foreach my $banner (@banners)


  print <<"EndOfText";
  <TR></TR><TR></TR><TR></TR><TR></TR><TR></TR><TR></TR>
  <TR><TD></TD><TD>
  <H1><FONT SIZE=+4>VOTE : </FONT>
    <INPUT TYPE="submit" NAME="action" VALUE="Vote !">
    <INPUT TYPE="reset"></H1>
  </TD></TR>
EndOfText

  print "</TABLE></FORM>\n";

  } # if (firstflag) show form 
} # sub display

sub getIndex {
  my $index = '/home/azurebrd/public_html/cgi-bin/forms/logo/index.html';
  my @index; my @good;
  $/ = '';
  open (IND, "<$index") or die "Cannot open $index : $!";
  while (<IND>) { push @index, $_; }
  close (IND) or die "Cannot close $index : $!";
  $/ = "\n";
  foreach $_ (@index) { if ($_ =~ m/Code/) { push @good, $_; } }
  @logos = $good[0] =~ m/img SRC=\"([\w\.]+)\"/g;
  my @logo_color = $good[0] =~ m/ff00aa\">Code: (L_[A-Z]{2,3}\d{2})/g;
  foreach $_ (@logo_color) { $logo_color{$_}++; }
  my @logo_bold = $good[0] =~ m/ff00aa\"><b>Code: (L_[A-Z]{2,3}\d{2})/g;
  foreach $_ (@logo_bold) { $logo_bold{$_}++; }
  @banners = $good[1] =~ m/img SRC=\"([\w\.]+)\"/g;
  my @banner_color = $good[1] =~ m/ff00aa\">Code: (B_[A-Z]{2,3}\d{2})/g;
  foreach $_ (@banner_color) { $banner_color{$_}++; }
  my @banner_bold = $good[1] =~ m/ff00aa\"><b>Code: (B_[A-Z]{2,3}\d{2})/g;
  foreach $_ (@banner_bold) { $banner_bold{$_}++; }
} # sub getIndex

sub populatePasswd {
  $passwd{'lstein@cshl.org'} = 'NE&7=rep';
  $passwd{'jspieth@watson.wustl.edu'} = 'guw4boP+';
  $passwd{'pws@caltech.edu'} = 'Zo!1tHux';
  $passwd{'emsch@its.caltech.edu'} = 'ClImo5-7';
  $passwd{'rd@sanger.ac.uk'} = 'tr=TRa?i';
  $passwd{'mueller@its.caltech.edu'} = '6r#!ufAy';
  $passwd{'dl1@sanger.ac.uk'} = 'n7Jo$l=h';
  $passwd{'srk@sanger.ac.uk'} = '4op3ust*';
  $passwd{'dblasiar@watson.wustl.edu'} = 'tHilo1*a';
  $passwd{'todd.harris@cshl.org'} = 'p8*lIl_p';
  $passwd{'krb@sanger.ac.uk'} = '9#Uloy#4';
  $passwd{'tbieri@watson.wustl.edu'} = 'x83etru$';
  $passwd{'eimear@its.caltech.edu'} = 'SPI&ahe8';
  $passwd{'wen@athena.caltech.edu'} = 'h05r_sTI';
  $passwd{'raymond@caltech.edu'} = 'st0x@=ra';
  $passwd{'azurebrd@lek.ugcs.caltech.edu'} = 'qOyiW9o!';
  $passwd{'andrei@tuco.caltech.edu'} = '-to-o1aC';
  $passwd{'ar2@sanger.ac.uk'} = 'q=24briM';
  $passwd{'ranjana@its.caltech.edu'} = 'c#maBef3';
  $passwd{'ck1@sanger.ac.uk'} = '51&&ziPU';
  $passwd{'cunningh@cshl.edu'} = 'w8obI-8T';
  $passwd{'qwang@caltech.edu'} = '55*Nozac';
  $passwd{'cecilia@minerva.caltech.edu'} = '@1q+chIw';
  $passwd{''} = 'asdfasdfasdf@1q+chIw';
} # sub populatePasswd


