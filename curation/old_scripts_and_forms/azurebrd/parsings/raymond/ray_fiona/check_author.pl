#!/usr/bin/perl -w

#This script is used to validate author names in the piano file 
#Date: Dec 14, 2002
#Author: Jack Chen

use strict;
use Ace;
use Ace::Object;

#database connection and query
my $DB = Ace->connect(-host => 'www.wormbase.org',
                   -port => 2005) or die "can't open database\n";

my @authors;
my $author_query;
my %au;

$author_query = qq(select a from a in class author);
@authors = $DB->aql($author_query);

foreach my $author (@authors){
  my @a = @$author;
  $au{$a[0]} = $a[0];
}

my $file = shift;
open (FH, "<$file");

while (<FH>){
  chomp;
  if ($_ =~ /^Author/){
    $_ =~ /.*"(.*)\"/;
    #print $1, "\n";
    
    if (!exists $au{$1}){
      print $1, " does not exist in acedb\n"; 
    }
  }
}
