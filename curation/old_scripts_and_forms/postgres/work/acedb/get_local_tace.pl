#!/usr/bin/perl -w

# Query acedb by building TACE queries.
#
# In this case, get all the Sequence -> From_laboratory data 
# and print to the screen.   2009 03 20


use strict;
use diagnostics;
use Ace;

# my $class_name = 'Person';

my $ace_query = "Find Sequence; follow From_laboratory; ";

# use constant HOST => $ENV{ACEDB_HOST} || 'aceserver.cshl.org';
# use constant PORT => $ENV{ACEDB_PORT} || 2005;
# use constant HOST => $ENV{ACEDB_HOST} || 'elbrus.caltech.edu';
# use constant PORT => $ENV{ACEDB_PORT} || 40004;
# my $db = Ace->connect(-host=>HOST,-port=>PORT) or warn "Connection failure: ",Ace->error;


# my $db = Ace->connect(-path  =>  '/home/citace/WS/WS_current/acedb',
# my $db = Ace->connect(-path  =>  '/home/ws/AceDB/acedb',
my $db = Ace->connect(-path  =>  '/home2/acedb/ws/acedb',
                      -program => '/home/acedb/bin/tace') || die "Connection failure: ",Ace->error;

my @sequences = $db->list('Sequence', '*');

foreach my $object (@sequences) {
  my @a = $object->From_laboratory;
  my $labs = join"\t", @a;
  if ($labs) {
    print "$object\t$labs\n";
  }
}


# my @ready_names= $db->fetch(-query=>$ace_query);
# 
# foreach my $name (@ready_names) { 
#   print "$name\n";
# }

