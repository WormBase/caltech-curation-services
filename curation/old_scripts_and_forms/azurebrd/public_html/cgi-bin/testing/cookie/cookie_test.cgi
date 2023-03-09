#!/usr/bin/perl -T

use strict;
use CGI;

use constant SOURCE_CGI => "/~azurebrd/cgi-bin/testing/cookie_lot.cgi";

my $q = new CGI;
my $cookie = new $q->cookie( -name => "third");

if (defined $cookie) {
  print $q->redirect( SOURCE_CGI );
} else {
  print $q->header( -type => "text/html", -expires => "-1d" ),
	$q->start_html( "Cookies Disabled" ),
	$q->h1( "Cookies Disabled" ),
	$q->p( "Your browser is not accepting cookies, please upgrade or enable
		cookies in your preference and", 
		$q->a( { -href => SOURCE_CGI }, "return"), "."
	),
	$q->end_html;
}
