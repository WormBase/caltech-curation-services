#!/usr/bin/perl 

use strict;
use Ace;

my $ace_query = 'Find Person_name';
my $db = Ace->connect(	-path => '/home/acedb/WS_current',
			-program => '/home/acedb/bin/tace') or die "Conn failure : ", Ace->error;
my @stuff = $db->fetch(-query => $ace_query);
foreach (@stuff) { print "$_\n"; }
