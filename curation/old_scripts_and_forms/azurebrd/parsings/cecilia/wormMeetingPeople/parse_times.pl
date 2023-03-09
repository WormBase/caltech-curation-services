#!/usr/bin/perl -w
#
# take ouput that cecilia edited to find the ones without any data, these 805
# needed to be parsed against the .htm files to find their location.
# 2003 06 24


use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my %hash;		# data for each of the names, key name, value data

my @files = qw(A B C D E F G H I J K L M N O P Q R S T U V W X Y Z);
# @files = qw(A);
foreach my $file (@files) {
  $file .= ".htm";
  $/ = undef;
  open (FIL, "<$file") or die "Cannot open $file : $!";
  my $alldata = <FIL>;
  close (FIL) or die "Cannot close $file : $!";
  $/ = "\n";
  my @entries = split/<TR><TD><FONT SIZE=-1>/, $alldata;
  foreach my $entry (@entries) {
    $entry =~ s/<\/TD>/\t/g;	# split columns by tabs
    $entry =~ s/<br>/ /g;
    $entry =~ s/&nbsp;/ /g;
    $entry =~ s/<[^>]*>//g;	# get rid of html
    $entry =~ s/\n//g;		# get rid of newlines
#     print "ENTRY $entry\n";
    my ($name) = $entry =~ m/^(.*?)\t/;	# get name
    $hash{$name} = $entry;
  } # foreach my $entry (@entries)
} # foreach my $file (@files)

my $infile = "cecilia_names";
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $name = <IN>) {
  chomp $name;
  if ($hash{$name}) { print "$hash{$name}\n"; }
  else { print "ERROR $name has no MATCH\n"; }
}
close (IN) or die "Cannot close $infile : $!";

