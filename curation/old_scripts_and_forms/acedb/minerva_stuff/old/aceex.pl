#!/usr/bin/perl

use Ace;
use strict vars;

#use constant HOST => $ENV{ACEDB_HOST} || 'www.wormbase.org';
#use constant PORT => $ENV{ACEDB_PORT} || 200005;

$|=1;

print "Opening the database....";
my $db = Ace->connect(-path => '/home/acedb/' -program => 'home/acedb/bin/tace')
    || die "Connection failure: ",Ace->error;
print "done.\n\n";
