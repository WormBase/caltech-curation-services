#!/usr/bin/perl

# usage ./checker.pl inputfile.ace > logfile    2003 03 26
#
# parse models.wrm into %models hash : keys ?class names and tag names, values tag names
# and all possible value types.   
# parse entry .ace file break up into lines by newline (should be fixed to allow
# multiline tags).  for each line, get tag and break into words, check tag to see that
# the tag exists, then check each word with the corresponding word in %models{class}{tag} 
# to see that it fits.  2003 03 26
#
# Reading multi-line text now by using a while-shift(@lines) instead of foreach (@lines)
# and shifting another line if &testLineOdd($line) returns as odd (number of quotes).
# Testing if an entry has a name or prints first line of entry as error.
# Testing if there's a (necessary) space after tag or prints error (before it grabbed \w+
# to get the tag which allowed non-\w to follow being an error, this may need to change
# to allow \n directly after \w+ because some tags will be just that, tags)  2003 04 09
#
# Add checking object names that they could have no quotes as long as they have no space
# 2003 04 15
#
# Throws the first tag of each line into a %other_tags hash if it isn't in the %models
# hash for that class.  This is so that if that tag is used in the .ace file, a WARNING
# is printed to STDERR to warn that that line is not being checked.
# Filtering all timestamps from .ace file (-O "stuff")
# Changed capturing of first line to find name, so as to check that it finds a first line
# because it wasn't capturing when the entry was a single line.
# Changed capture of names from [\w\-\_]+ to [^"]+
# Filtering each entry to take out all blank lines at beginning of entry, end of entry, 
# and middle of entry.
# Added check that amount of ``words'' in .ace file aren't more than amount of ``words''
# in models file.  This means that since hashes aren't taken into account, this spits out
# a lot of errors.

use strict;
use diagnostics;

my $model_file = 'models.wrm';		# models file

my $error = 0;		# count of errors sent to STDERR

my %classes;		# key class name value class data
			# stuff that is a class could also be a valuetype if preceded by a ?
$classes{Text}++;	# add Text as a ``class'' in that it can be
			# preceded by a ? to be a valuetype

my %models;		# models of tags and valuetypes, key class
my %other_tags;		# models of tags not accounted for in full %models (first grouping tag)

$/ = "";		# read paragraphs from file
open (IN, "<$model_file") or die "Cannot open $model_file : $!";
while (my $class = <IN>) {	# add data to classes, key is class name
  if ($class =~ m/^\?(\w+)/) { $classes{$1} = $class; }
}
close (IN) or die "Cannot close $model_file : $!";

foreach my $class (sort keys %classes) {
#   print "\nCLASS $class\n";
  &filterClass($class);	# take out junk from class
  &getTags($class);	# get tags to put in %models
} # foreach my $class (sort keys %classes)


my $inputfile = $ARGV[0];		# get inputfile
open (IN, "<$inputfile") or die "Cannot open $inputfile : $!";
while (my $entry = <IN>) {
  $entry =~ s/\/\/.*$//mg;		# take out comments from entry
  $entry =~ s/^[\n\s]+//g; $entry =~ s/[\n\s]+$//g; $entry =~ s/[\n]{2,}/\n/g;	# filter blank lines
  $entry =~ s/\-O\s+?\"[^"]+\"//g;	# filter comments
# print "ENTRY $entry\n\n";
  if ($entry !~ m/\S/) { next; }	# skip entries without non-space
  my $name = '';			# init name of entry
  my $line1 = '';			# first line of entry
  unless ($entry =~ m/\n/) { $line1 = $entry; }	# if entry is one line, first line is whole entry
    else { ($line1) = $entry =~ m/^(.*?)\n/g; }	# otherwise get first line (should have name)
  unless ($line1) { print STDERR "NO LINE1 ENTRY $entry\n"; $error++; next; }
  if ($line1 =~ m/^\w+\s*?:\s+([^"]+?)\s+.+/) { $error++; }	# error if no "'s but with space in name
  elsif ($line1 =~ m/:\s+\"([^"]+?)\"/) { ($name) = $1; }	# get name
  elsif ($line1 =~ m/:\s+([^"].+?)\s*\n/) { $name = $1; } 	# get name
  else { $error++; }			# no name, following line will output error
  unless ($name) { 			# if there's no name
    print STDERR "NO NAME FOR $line1\n"; } 		# print error if no name found
  my ($class) = $entry =~ m/^(\w+) :/;	# get class name of entry
  my @lines = split/\n/, $entry;	# This doesn't account for multi-line tags
  shift @lines;				# ignore the class entry header
  my $quote_odd = 0;			# flag whether quotes are odd
  while (my $line = shift @lines) {	# for all the lines	
					# can't use foreach because will be shifting when quotes uneven
    if ($line !~ m/\S/) { next; }	# skip lines without non-space
    $quote_odd = &testLineOdd($line);	# test whether line has odd number of quotes
    while ($quote_odd == 1) {		# if the line has an odd number of quotes
      my $next_line = shift(@lines);	# get the next one
      $line .= "\n$next_line";		# append it
      $quote_odd = &testLineOdd($line);	# test again (and repeat until out of loop)
    } # while ($quote_odd == 1)
#     print "LINE $line\n";
    my ($tag) = $line =~ m/^(\w+)\s+/;	# get name of tag
    unless ($tag) { print STDERR "NO TAG : $line\n"; $error++; next; }	# print error if no tag found
    if ( $models{$class}{$tag} ) {	# if good, do stuff
      print "COMPARE $line WITH $models{$class}{$tag}\n";	# show line ace vs model
      &compareLineWithHash($name, $class, $tag, $line); }	# compare line ace vs model
    elsif ($other_tags{$class}{$tag}) {	# if not good, maybe in other tags
      print STDERR "WARNING : Grouping Tag $tag NOT BEING CHECKED in LINE $line\n"; }
    else { print STDERR "$name $tag IS NOT A VALID TAG\n"; $error++; }	# else error
  } # while (my $line = shift @lines)
} # while (my $entry = <IN>)
close (IN) or die "Cannot close $inputfile : $!";
$/ = "\n";		# reset to read lines from file

print STDERR "THERE WERE $error ERRORS\n";

sub testLineOdd {			# test whether line is odd
  my $line = shift;
  my $quote_odd = 0;			# default is not odd
  if ($line =~ m/\"/) {			# if it has quotes
    my @quotes = $line =~ m/(\")/g;	# get the quotes
    my $quote_amount = scalar(@quotes);	# get their count
    $quote_odd = $quote_amount % 2;	# get their evenness (modulus 2)
#     print "LINE $line QUOTES $quote_amount IS ODD $quote_odd\n";
  } # if ($line =~ m/\"/)
  return $quote_odd			# return 1 if odd, 0 if even
} # sub testLineOdd

sub compareLineWithHash {		# compare line ace vs model
  my ($name, $class, $tag, $line) = @_;
#   my ($tag, @words) = $line =~ m/^(\w+)\s+(\"([^\"]+)\")|(\s*(\S+)\s*)/;
  my @ace_words;			# array of words in a given line in .ace file
  my (@temp_words) = $line =~ m/(?:\s+(?:"([^"]+)"))|(?:\s+(\S+))/g;	# filter into valid words
  foreach my $temp_word (@temp_words) { if ($temp_word) { push @ace_words, $temp_word; } }
  foreach my $ace_word (@ace_words) { print "ACE_WORD $ace_word\n"; }

  my @models_words = split/\s+/, $models{$class}{$tag};		# filter into model words
  if (scalar(@ace_words) > scalar(@models_words)) { 		# if more ace values than in model
    print STDERR "More Values than allowed in model in Line : $line\n"; $error++; }
  shift @models_words;						# get rid of tag
  for (my $i = 0; $i < $#models_words+1; $i++) {
    &compareWords($name, $models_words[$i], $ace_words[$i]);	# compare each ace word with model
  } # for (my $i = 0; $i < $#models_words+1; $i++)
} # sub compareLineWithTags

sub compareWords {			# compare each ace word with model
  my ($name, $models_word, $ace_word) = @_;
  if ($ace_word) { 						# if there is a word
    print "MODELS $models_word\tACE $ace_word\n"; 		# show word model vs word
    if ($models_word eq 'Int') {				# for Ints, check stuff
      if ($ace_word =~ m/[^\-\d]/) { print STDERR "$name $ace_word NOT AN INT\n"; $error++; } }
    elsif ($models_word eq 'Float') {				# for Floats, check stuff
      if ($ace_word !~ m/\./) { print STDERR "$name $ace_word NOT A FLOAT\n"; $error++; } 
      if ($ace_word =~ m/[^\-\.\d]/) { print STDERR "$name $ace_word NOT A NUMBER\n"; $error++; } }
    elsif ($models_word eq 'DateType') {			# for DateTypes, check stuff
      if ($ace_word !~ m/\d\d\d\d\-\d\d\-\d\d/) { 
        print STDERR "$name $ace_word NOT A DATETYPE\n"; $error++; } }
    elsif ($ace_word eq 'Text') { 1; }				# for Text, don't do anything
    else { 1; }
  } # if ($ace_word)
} # sub compareWords

sub getTags {				# get tags to put in %models
  my $class = shift;
  $classes{$class} =~ s/^\?\w+//g;	# take out tag name
  $classes{$class} =~ s/XREF\s+\w+//g;	# take out XREF and word to right
  $classes{$class} =~ s/UNIQUE//g;	# take out UNIQUE
  $classes{$class} =~ s/\#\w+//g;	# take out Hashes (for now)
  my @lines = split/\n/, $classes{$class};	# get tags from model
  foreach my $line (@lines) {
    my (@groups) = $line =~ m/(\w+(\s+(DateType|Int|Float|Text|\?\w+))*)/g;
    if ($1) { 				# filter into tag and valuetypes
      my $value_line = $1;
      my ($tag) = $value_line =~ m/^(\w+)/g;
      $models{$class}{$tag} = $value_line;	# keys class and tag, value tag and valuetypes
#       print "$tag\t$value_line\n";
    } # if ($1)
    if ($line =~ m/^\s*?(\w+)\s+/) { 
      unless ($models{$class}{$1}) { $other_tags{$class}{$1} = $line; } }
  } # foreach my $line (@lines)
} # sub getTags

sub filterClass {			# take out junk from class
  my $class = shift;
  $classes{$class} =~ s/\/\/.*\n/\n/g;	# take out comments
  $classes{$class} =~ s/\n\s+\n/\n/g;	# take out blank lines
  $classes{$class} =~ s/\s+\n/\n/g;	# take out spaces after tags
} # sub filterClass
