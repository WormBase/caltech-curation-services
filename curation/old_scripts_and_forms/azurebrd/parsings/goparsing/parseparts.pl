#!/usr/bin/perl -w

use strict;		# be thorough
use diagnostics;	# tell you if you mess up

  # Define the location of the files into variables
my $partsfile = "/home/azurebrd/work/goparsing/parts.html";
my $fileone = "/home/azurebrd/work/goparsing/fileone";
my $filetwo = "/home/azurebrd/work/goparsing/filetwo";

  # Open filehandles to read from and write to files
  # < means read from, > means write to
  # the $! is the standard error output
open(IN, "<$partsfile") or die "Cannot open $partsfile : $!";
open(ONE, ">$fileone") or die "Cannot create $fileone : $!";
open(TWO, ">$filetwo") or die "Cannot create $filetwo : $!";

my $counter = 1;	# count the GO number, starting with one
print ONE "\$\\<all worm cells>; GO:000000" . $counter . "\n";
			# write the first line

while (<IN>) {		# start reading from the partsfile, line by line
			# the line read is default stored into variable $_
  chomp;		# take off the newline (\n)
  $counter++;		# add to counter, second line now
  my $gocount;		# make a new variable for the full 7 digit string 
			# and text GO: 
    # if/elsif/etc to make the counter the right length
    # given the number, it appends the actual count to standard text
  if ($counter < 10) { $gocount = "GO:000000" . $counter; }
  elsif ($counter < 100) { $gocount = "GO:00000" . $counter; }
  elsif ($counter < 1000) { $gocount = "GO:0000" . $counter; }
  else { $gocount = "GO:000" . $counter; }

  my @array = split //, $_ ;	# break up the line into characters
				# store into array called @array
  unless (scalar(@array) > 40) { 
			# the third field (description) starts at the 40th
			# character, so if the array has more than 40 characters
			# then there is a third field.  therefore, unless there
			# is a third field, do this (case for only 2 fields)
    # Only 2 fields
    my @one; my @two;	# assign arrays for the variables
    for (my $i = 0; $i < 17; $i++) {	# for the first 17 characters
      push @one, $array[$i];		# put them in the array called @one
    }
    for (my $i = 17; $i < scalar(@array); $i++) {
					# for characters 18 to the last
      push @two, $array[$i];		# put them in the array called @two
    }
    my $one = join('', @one);	# join the characters into a single variable
    my $two = join('', @two);	# join the characters into a single variable
    $one =~ s/\s+$//g;		# remove the spaces at the end of the variable
				# the $ means end of line
    $two =~ s/\s+$//g;		# remove the spaces at the end of the variable
    print ONE " <\\<" . $one . ">; " . $gocount . "; synonym:\\<lineage name: " . $two . ">\n";
				# print the stuff to fileone, \\ to print a \
				# because otherwise \ is an escape character
				# (like in \n to show end of line)
      # same for filetwo
    print TWO "term: <" . $one . ">\n";
    print TWO "goid: " . $gocount . "\n";
    print TWO "definition: NONE\n";
    print TWO "definition_reference: ISBN: 0-87969-307-X\n\n";

  } else { # unless (scalar(@array) > 40)	# else, not in the case of only
						# two fields, i.e. all 3 fields 
      # all same as above, but with extra step for the 40th character 
    my @one; my @two; my @three;
    for (my $i = 0; $i < 17; $i++) {
      push @one, $array[$i];
    }
    for (my $i = 17; $i < 39; $i++) {
      push @two, $array[$i];
    }
    for (my $i = 39; $i < scalar(@array); $i++) {
      push @three, $array[$i];
    }
    my $one = join('', @one);
    my $two = join('', @two);
    my $three = join('', @three);
    $one =~ s/\s+$//g;
    $two =~ s/\s+$//g;
    $three =~ s/\s+$//g;
    print ONE " <\\<" . $one . ">; " . $gocount . "; synonym:\\<lineage name: " . $two . ">\n";
    print TWO "term: <" . $one . ">\n";
    print TWO "goid: " . $gocount . "\n";
      # the following output line is also different
    print TWO "definition: " . $three . "\n";
    print TWO "definition_reference: ISBN: 0-87969-307-X\n\n";
  } # else # unless (scalar(@array) > 40)	# else, not in the case of only
} # while (<IN>) 

  # close all the filehandles
close(IN) or die "Cannot close $partsfile : $!";
close(ONE) or die "Cannot close $fileone : $!";
close(TWO) or die "Cannot close $filetwo : $!";
