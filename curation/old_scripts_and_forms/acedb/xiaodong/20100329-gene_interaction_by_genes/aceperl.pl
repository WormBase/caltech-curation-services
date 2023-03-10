#!/usr/bin/perl

# get interactions associated with genes for xiaodong.  2010 03 29

use strict;
use Ace;


my $database_path = "/home3/acedb/ws/acedb";    # full path to local AceDB database; change as appropriate
my $program = "/home/acedb/bin/tace";           # full path to tace; change as appropriate
my $db = Ace->connect(-path => $database_path,  -program => $program) || die print "Connecti on failure: ", Ace->error;  # local database

#   use constant HOST => $ENV{ACEDB_HOST} || 'aceserver.cshl.org';
#   use constant PORT => $ENV{ACEDB_PORT} || 2005;
#   my $db = Ace->connect(-host=>HOST,-port=>PORT) or warn "Connection failure: ",Ace->error;


if (Ace->error) { print "ERROR\n"; }
print "DB $db DB\n";

my $infile = 'genes';
open (IN, "<$infile" ) or die "Cannot open $infile : $!";
while (my $gene = <IN>) {
  chomp $gene;


  my $query="find Gene $gene";
  my @genes=$db->fetch(-query=>$query);
# 
#   my $mygene = $db->fetch(Gene=>'$gene');
  my $mygene = $genes[0];
  my @interactions = $mygene->Interaction; 
  my $interactions = join", ", @interactions;
  print "$gene\t$interactions\n";
} # while (my $line = <IN>)
close (IN ) or die "Cannot close $infile : $!";
