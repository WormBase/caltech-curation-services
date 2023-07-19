#!/usr/bin/perl

# 2007 09 22 get and update the css as well

# add an invisible class to the .css  2009 02 26
# moved to jex.css  2009 02 27
# changed $user and $email  2011 02 04
#
# late update for WormBase 2.0 release.  2015 05 07
#
# hide the searchForm since it doesn't work.  2015 07 06
#
# added google analytics to header for Todd.  2016 04 27
#
# link to https://www.wormbase instead of just http.  2018 03 15
#
# potentially get header and footer from http://www.wormbase.org/header + http://www.wormbase.org/footer
# and tack on the .css and .js dependencies.  2018 03 16
#
# http not supported at wormbase anymore, https not accessible with curl nor LWP, because of some 
# TLS issue that Adam found https://github.com/curl/curl/issues/5496  Disabling emails until some
# software update somewhere hopefully fixes it.  2020 10 10
#
# wormbase header and footer at different URLs now.  ssl certificate expired requires
# using IO::Socket::SSL to prevent verification.  2023 07 19


# Set to cronjob to update everyday.  2007 11 20
# 0 4 * * * /home/azurebrd/public_html/sanger/wormbaseheader/update_wormbase_header.pl


use strict;
use diagnostics;
use LWP::Simple;
use Jex;
use LWP::UserAgent;
use Net::Domain qw(hostname hostfqdn hostdomain);
use IO::Socket::SSL qw();

my $hostfqdn = hostfqdn();

my $date = &getSimpleSecDate();
# my $ua = LWP::UserAgent->new;
my $ua = LWP::UserAgent->new(
    ssl_opts => {
        SSL_verify_mode => IO::Socket::SSL::SSL_VERIFY_NONE,
        verify_hostname => 0,
        # SSL_hostname => '',# Set SSL_hostname if you do want to verify the hostname
                            # (ie, when using SNI https://en.wikipedia.org/wiki/Server_Name_Indication)
    }
);

my $directory = '/home/azurebrd/public_html/sanger/wormbaseheader';
chdir($directory) or die "Cannot go to $directory ($!)";

# my $page = get "https://www.wormbase.org/stylesheets/wormbase.css";
my $response = $ua->get("https://www.wormbase.org/stylesheets/wormbase.css");
my $page = $response->content;
if ($page) { 
    my $outfile = $directory . '/wormbase.css';
    if ($page =~ m/\@import.*?\n/) { $page =~ s/\@import.*?\n//g; }	# can't import stuff I'm not accounting for 2010 08 20
#     my $edited_page = $page;
#     $edited_page =~ s/\n\.mism/\n.inv              \{ display : none; \}\n.mism/;	# add an invisible style

    open (OUT, ">$outfile") or die "Cannot open $outfile : $!";
    print OUT "$page";
    close (OUT) or die "Cannot close $outfile : $!"; }

  # .css and .js dependencies hardcoded in, will need updating if they ever change.  2018 03 16
my $dependencies  = qq(<link href="https://www.wormbase.org/static/css/main.min.css" rel="stylesheet">\n);
   $dependencies .= qq(<script src="https://code.jquery.com/jquery-1.9.1.min.js" integrity="sha256-wS9gmOZBqsqWxgIVgA8Y9WcQOa7PgSIX+rPA0VL2rbQ=" crossorigin="anonymous"></script>\n);
   $dependencies .= qq(<script src="https://code.jquery.com/ui/1.10.1/jquery-ui.min.js" integrity="sha256-Nnknf1LUP3GHdxjWQgga92LMdaU2+/gkzoIUO+gfy2M=" crossorigin="anonymous"></script>\n);
   $dependencies .= qq(<script src="https://www.wormbase.org/static/js/wormbase.min.js" type="text/javascript"></script>\n);
   $dependencies .= qq(<script>\n(function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){ (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o), m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m) })\n(window,document,'script','\/\/www.google-analytics.com\/analytics.js','ga');\nga('create', 'UA-16257183-1', {'cookieDomain': 'wormbase.org'});\nga('require', 'displayfeatures');\nga('send', 'pageview');\n<\/script>\n);

# my $header = get "https://www.wormbase.org/header";
# my $header = get "https://wormbase.org//header";
$response = $ua->get("https://wormbase.org//header");
my $header = $response->content;
   $header =~ s/href="\//href="https:\/\/www.wormbase.org\//g;
   $header =~ s/src="\//src="https:\/\/www.wormbase.org\//g;
# my $footer = get "https://www.wormbase.org/footer";
$response = $ua->get("https://wormbase.org//footer");
my $footer = $response->content;
   $footer =~ s/href="\//href="https:\/\/www.wormbase.org\//g;
   $footer =~ s/src="\//src="https:\/\/www.wormbase.org\//g;

my $outfile = $directory . '/header_absolute.html';
open (OUT, ">$outfile") or die "Cannot open $outfile : $!";
print OUT "$header";
close (OUT) or die "Cannot close $outfile : $!";

$outfile = $directory . '/footer_absolute.html';
open (OUT, ">$outfile") or die "Cannot open $outfile : $!";
print OUT "$footer";
close (OUT) or die "Cannot close $outfile : $!";

$outfile = $directory . '/dependencies_absolute.html';
open (OUT, ">$outfile") or die "Cannot open $outfile : $!";
print OUT "$dependencies";
close (OUT) or die "Cannot close $outfile : $!";

sub scrapingWay {
  $page = get "http://www.wormbase.org";
  $page =~ s/href="\//href="https:\/\/www.wormbase.org\//g;
  $page =~ s/src="\//src="https:\/\/www.wormbase.org\//g;
  $page =~ s/<div id="top-system-message".*?(<div id="operator-box-wrap">)/$1/s;
  # $page =~ s/http:\/\/www.wormbase.org\/stylesheets\/wormbase.css/http:\/\/tazendra.caltech.edu\/~azurebrd\/sanger\/wormbaseheader\/wormbase.css/g;				# 2007 09 22 get and update the css as well
  # my ($header) = $page =~ m/^(.*?)<!-- \$MTInclude module/s;       # 2006 11 20 # Todd keeps changing stuff
  # my ($header) = $page =~ m/^(.*?)<!-- required components for balloon tooltips/s;       # 2007 03 05 # Todd keeps changing stuff
  # my ($header) = $page =~ m/^(.*?)<!-- \$MTInclude module/s;       # 2007 03 27 # Todd keeps changing stuff
  # my ($header) = $page =~ m/^(.*?)<div class="news" id="mainSearch">/s; # 2007 06 15  2007 User Survey
  my ($header) = $page =~ m/^(.*?)<!-- END boilerplate\/banner -->/s; # 2015 05 07 divider
  $header =~ s/<body.*?>/<body>/;					# 2009 04 16  get rid of javascript on body
  $header =~ s/<script.*?<\/script>//smg;				# 2009 04 16  get rid of javascript on body
  $header =~ s/id="searchForm"/id="searchForm" style="display:none;"/;	# 2015 07 06 hide search form
  if ($header =~ m/<\/head>/) {
      # add google analytics for Todd
    $header =~ s/<\/head>/<script>\n(function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){ (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o), m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m) })\n(window,document,'script','\/\/www.google-analytics.com\/analytics.js','ga');\nga('create', 'UA-16257183-1', {'cookieDomain': 'wormbase.org'});\nga('require', 'displayfeatures');\nga('send', 'pageview');\n<\/script>\n  <\/head>/;
  }
  
  # my ($footer) = $page =~ m/.*(\<hr\>.*?)$/s;			# 2002 05 14
  my ($footer) = $page =~ m/.*<!-- begin boilerplate\/footer -->.*?<\/div>(.*?)$/s;			# 2015 05 07
  # $footer =~ s/<script.*?<\/script>//smg;			# 2009 04 16  get rid of javascript on body	# 2018 03 15 no longer get ride of javascript since it helps the menu mouseover to work
} # sub scrapingWay



# print "HEADER $header HEADER\n\nFOOTER $footer FOOTER";

if ($header && $footer) {
  my $response = $ua->get("http://$hostfqdn/~azurebrd/sanger/wormbaseheader/WB_header_footer.html");
  my $local = $response->content;
#   my $new_page = qq($header\n\n<div id="content" style="padding: 2em !important;">\n\nDIVIDER\n\n<\/div>\n<br/><br/>\n$footer);
  my $new_page = qq(<html><head>$dependencies\n$header\n</head>\n\n<body><div id="content" style="padding: 2em !important;">\n\nDIVIDER\n\n<\/div>\n<br/><br/>\n$footer\n</body></html>);
  
  if ($new_page eq $local) { 1; }	# nothing to be done
  else { 
    my $outfile = $directory . '/WB_header_footer.html';
    open (OUT, ">$outfile") or die "Cannot open $outfile : $!";
    print OUT "$new_page";
    close (OUT) or die "Cannot close $outfile : $!";
    
    $outfile = $directory . '/old/WB_header_footer.html.' . $date;
    open (OUT, ">$outfile") or die "Cannot open $outfile : $!";
    print OUT "$new_page";
    close (OUT) or die "Cannot close $outfile : $!"; } }
else { &sendErrorMessage('no header and footer'); }


sub sendErrorMessage {
  my $subject = shift;
  my $user = 'update_wormbase_header.pl';
  my $email = 'azurebrd@caltech.edu';
  my $body = "1";
#   &mailer($user, $email, $subject, $body); 	# while LWP and curl can't find the correct cert from https, don't bother with email
} # sub sendErrorMessage


