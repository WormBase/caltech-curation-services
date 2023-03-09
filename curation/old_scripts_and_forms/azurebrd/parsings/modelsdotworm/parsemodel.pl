#!/usr/bin/perl
#
# Parse the models.wrm.  Take out the comments.  Take out the tabs and replace
# with appropriate number of spaces.
# Read the whole file.  Take out comments.  Break file into models by \n?.
# For each model, take out the \n# models.  Break model into lines, and take out
# empty lines.  Replace the lost ? that indicates the beginning of a model.
# For each line : Read chars into an @eight eight-char array unless a tab is
# read, in which case fill up the array with blanks.  Print the array members, 
# and then move on to the next 8-block, restarting the @eight array.  Print a 
# newline.  (Then print a newline for ending the model).  2002 07 02

use strict;
use diagnostics;

my $outfile = 'models.wrm.parsed';	# parsed without comments or tabs
open (OUT, ">$outfile") or die "Cannot create $outfile : $!";

my $infile = 'models.wrm';	# unparsed from acedb install
open (MOD, "<$infile") or die "Cannot open $infile : $!";
undef $/;
my $file = <MOD>;
close (MOD) or die "Cannot close $infile : $!";

$file =~ s/\/\/.*\n/\n/g;	# take out comments

my @models = split/\n[\?]/, $file;	# split by ?, ignore #entries

foreach my $model (@models) {
  if ($model =~ m/\n\#/ms) { 	# if it has a hash model
    $model =~ s/\n\#.*$//ms;	# remove the hash model
  } # if ($model =~ m/\n\#/ms)
  
  my @lines = split/\n/, $model;# take out empty lines
  my @goodlines;		# temp array of non-empty lines
  foreach $_ (@lines) { 
    if ($_ =~ m/\S/) { push @goodlines, $_; }	# if not empty, push it
  } # foreach $_ (@lines)
  @lines = @goodlines;		# put back to @lines
  
  unless (@lines) { next; }	# skip ``models'' with no data (blocks of
				# comment at beginning)
  
  $lines[0] = "?" . $lines[0];	# put back the ? that was lost while splitting models
				# at the beginning of the first line
  
  foreach my $line (@lines) {	# deal with lines separetly
    my @chars = split//, $line;	# break line into characters
    my $char = '';		# character being read
    my $i = 0;			# count of character being read (up to 8)
    my @eight;			# 8-character array to deal with 8-character blocks
    while (@chars) {		# while there's a line
      LABEL: while ($i < 8) {	# up to 8 characters 
        $char = shift(@chars); 	# read a character
        $i++; 			# count characters read
        unless ($char eq "\t") {	# if not a tab, add to array @eight
          push @eight, $char;
        } else {			# for tabs
          for (my $j = $i-1; $j < 8; $j++) {
            $eight[$j] = ' ';	# fill the remainder with blanks
          } # for (my $j = 8 - $i; $j < 8; $j++)
          last LABEL;		# exit this block of 8-characters
        } # else # unless ($char eq '\t')
      } # while ( ($i < 8) && ($char ne '\t') )
      foreach $_ (@eight) { print OUT "$_"; }	# output
      $i = 0; @eight = ();	# re-initialize count and 8-char array block
    } # while (@chars)
    print OUT "\n";		# print newline for next line
  } # foreach my $line (@lines)
  
  print OUT "\n";		# print newline to separate models
} # foreach my $model (@models)

close (OUT) or die "Cannot close $outfile : $!";
