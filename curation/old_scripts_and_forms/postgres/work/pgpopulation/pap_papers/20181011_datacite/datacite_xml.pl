#!/usr/bin/perl

use strict;
use LWP;
 
my $login_url = "https://api.datacite.org/application/vnd.datacite.datacite+xml/10.17912/2jgw-fj52";
my $user = "caltech.micropub";
my $pass = "mP8_>microZC";
 
my $ua = LWP::UserAgent->new;

$ua->credentials( $login_url, 'PAUSE', $user, $pass);

my $resp = $ua->get( $login_url);
print $resp->status_line;
print $resp->content;
