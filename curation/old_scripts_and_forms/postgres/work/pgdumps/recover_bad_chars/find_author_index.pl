#!/usr/bin/perl

# read the dump with all the data, then scan for lines that hold
# certain data to read it in again after stripping characters.
# 2007 03 02

my $infile = 'testdb.dump.200703020838';
my $count = 0;
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) {
  $count++;
#   if ( ($count > 1818645) && ($count < 1905791) ) { print "$line"; }	# author_index
#   if ( ($count > 1637081) && ($count < 1660420) ) { print "$line"; }	# abstracts
#   if ( ($count > 1530696) && ($count < 1556230) ) {			# titles
#   if ( ($count > 612761) && ($count < 626188) ) {			# street
#   if ( ($count > 626193) && ($count < 630841) ) {			# city
#   if ( ($count > 630839) && ($count < 634296) ) {			# state
#   if ( ($count > 1301035) && ($count < 1306881) ) {			# institution
#   if ( ($count > 1905811) && ($count < 1921117) ) {			# electronic_path_type
  if ( ($count > 423695) && ($count < 430749) ) {			# cur_rnai
    $line =~ s/[^\s\w\d\~\!\@\#\$\%\^\&\*\(\)\-\_\+\=\{\}\[\]\|\;\:\'\"\,\<\.\>\\\/\?]//g;
    print "$line";
  }
} # while (my $line = <IN>)
close (IN) or die "Cannot open $infile : $!";

