#!/usr/bin/perl 

# Site Map - redirect to this page.

use strict;
use CGI;

my $q = new CGI;
 
print $q->redirect( "http://tazendra.caltech.edu/~azurebrd/cgi-bin/index.cgi" );
