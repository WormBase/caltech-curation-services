#!/usr/bin/env perl 

# Site Map - redirect to this page.

use strict;
use CGI;

my $q = new CGI;
 
print $q->redirect( "index.cgi" );
