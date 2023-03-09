#!/usr/bin/perl

# Take output from person_lineage.cgi, put names into %names hash; 
# connect people into %hash of supervisor, supervisee, role; or
# %hash_collab of collaborator, collaborator, role.  Find WBPerson#
# from postgres for each %names name (put into %names value).
# Go through %hash to output Supervised (printing to not_found for
# those not found).  Go through %hash to output Supervised_by 
# (likewise).  Go through %hash_collab to output Worked_with 
# (likewise).   2003 10 12
#
# Fixed Worked_with that was outputting to not_found sometimes by
# mistake (all entries after a non-match would go there).  2003 10 21
#
# Edited to deal with Hodgkin's .doc file (antiword and vim parsed
# into a .ace like file) which has Last, First format.  Some people
# don't match for some reason, like Chip Ferguson or Ichi Maruyama,
# I don't understand why.  Leon Nawrocki is the only one with no match.
# 2003 10 22


use strict;

use Pg;
my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my %aka_hash = &getPgHash();	# read from postgres
my %hash;		# key supervisor, key supervisee, value role
my %names;		# key name, value WBPerson#

&process();

sub process {
#   my $infile = 'person_lineage.ace';
  my $infile = $ARGV[0];
  $/ = "";
  open (IN, "<$infile") or die "Cannot open $infile : $!";
  my %name;			# hash of names to check
  while (my $entry = <IN>) {
    my ($main) = $entry =~ m/Person\t(.*)/;
    $main =~ s/^\s+//g; $main =~ s/\s+$//g; $main =~ s/\.//g; $main =~ s/\s+/ /g;
# print "MAIN $main\n";
    my ($last, $first) = $main =~ m/([\'\w \-]+),\s*([\'\w \-]+)/;
    $main = "$first $last";
# if ($main eq ' ') { print "$entry\n"; }
    $names{$main} = '';
    my (@supervised) = $entry =~ m/(Supervised\t.*)/g;
    foreach my $line (@supervised) {		# get trained_ into %hash
      my ($person) = $line =~ m/Supervised\t(.*)/;
# print "LINE $line\n";
# print "PERSON $person\n";
      $person =~ s/^\s+//g; $person =~ s/\s+$//g; $person =~ s/\.//g; $person =~ s/\s+/ /g;
      my ($last, $first) = $person =~ m/([\'\w \-]+),\s*([\'\w \-]+)/;
# print "F $first\n";
# print "L $last\n";
      $person = "$first $last";
# if ($person eq ' ') { print "PERSON BAD $entry\n"; }
      $hash{$main}{$person} = 'Unknown';
      $names{$person} = '';
    } # foreach my $line (@supervised)
  } # while (<IN>)
  $/ = "\n";

  # get WBPerson# into %names hash from postgres
  my $not_found = 'not_found';
  open (NOT, ">$not_found") or die "Cannot create $not_found : $!";
  foreach my $name (sort keys %names) {
    if ($name !~ /\w/) { 	# if not a valid name, don't search
    } elsif ($name =~ /(\d+)/) {
      $names{$name} = 'WBPerson' . $1;
    } else { 			# if it doesn't do simple aka hash thing
      &processAkaSearch($name, $name, %aka_hash);
    }
  } # foreach my $name (sort keys %names)

  # deal with Supervised
  foreach my $supor (sort keys %hash) {
    if ($names{$supor}) { 	# main is found, print
      print "Person\t$names{$supor}\n"; 
      foreach my $supee (sort keys %{ $hash{$supor} }) {
        if ($names{$supee}) { print "Supervised\t$names{$supee}\t$hash{$supor}{$supee}\n"; }
          else { 
            print NOT "Person\t$names{$supor}\n"; 
            print NOT "Supervised\t$supee\t$hash{$supor}{$supee}\n\n"; }
      } # foreach my $supee (sort keys %{ $hash{$supor} })
      print "\n";
    } else { 			# main is not found, print to not found file
      print NOT "Person\t$supor\n"; 
      foreach my $supee (sort keys %{ $hash{$supor} }) {
        if ($names{$supee}) { print NOT "Supervised\t$names{$supee}\t$hash{$supor}{$supee}\n"; }
          else { print NOT "Supervised\t$supee\t$hash{$supor}{$supee}\n"; }
      } # foreach my $supee (sort keys %{ $hash{$supor} })
      print NOT "\n";
    }
  } # foreach my $supor (sort keys %hash)
  close (NOT) or die "Cannot close $not_found : $!";
} # sub process



sub processPgWild {
  my $input_name = shift;
#   print NOT "INPUT\t$input_name\n";
  my @people_ids;
  $input_name =~ s/\*/.*/g;
  $input_name =~ s/\?/./g;
  my @input_parts = split/\s+/, $input_name;
  my %input_parts;
  my %matches;				# keys = wbid, value = amount of matches
  my %filter;
  foreach my $input_part (@input_parts) {
    my @tables = qw (first middle last);
    foreach my $table (@tables) { 
#       my $result = $conn->exec ( "SELECT * FROM two_aka_${table}name WHERE two_aka_${table}name ~ '$input_part';" );
      my $result = $conn->exec ( "SELECT * FROM two_aka_${table}name WHERE lower(two_aka_${table}name) ~ lower('$input_part');" );
      while ( my @row = $result->fetchrow ) { $filter{$row[0]}{$input_part}++; }
#       $result = $conn->exec ( "SELECT * FROM two_${table}name WHERE two_${table}name ~ '$input_part';" );
      $result = $conn->exec ( "SELECT * FROM two_${table}name WHERE lower(two_${table}name) ~ lower('$input_part');" );
      while ( my @row = $result->fetchrow ) { $filter{$row[0]}{$input_part}++; }
    } # foreach my $table (@tables)
  } # foreach my $input_part (@input_parts)

  foreach my $number (sort keys %filter) {
    foreach my $input_part (@input_parts) {
      if ($filter{$number}{$input_part}) { 
        my $temp = $number; $temp =~ s/two/WBPerson/g; $matches{$temp}++; 
        my $count = length($input_part);
        unless ($input_parts{$temp} > $count) { $input_parts{$temp} = $count; }
      }
    } # foreach my $input_part (@input_parts)
  } # foreach my $number (sort keys %filter)
} # sub processPgWild




sub processAkaSearch {			# get generated aka's and try to find exact match
  my ($name, $name, %aka_hash) = @_;
  my $search_name = lc($name);
  unless ($aka_hash{$search_name}) { 
#     print NOT "$name NOT FOUND\n";
    my @names = split/\s+/, $search_name; $search_name = '';
    foreach my $name (@names) {
      if ($name =~ m/^[a-zA-Z]$/) { $search_name .= "$name "; }
      else { $search_name .= '*' . $name . '* '; }
    }
    &processPgWild($name);
  } else { 
    my %standard_name;
    my $result = $conn->exec ( "SELECT * FROM two_standardname;" );
    while (my @row = $result->fetchrow ) {
      $standard_name{$row[0]} = $row[2];
    } # while (my @row = $result->fetchrow )

#     print "$name shows\t";
    my @stuff = sort {$a <=> $b} keys %{ $aka_hash{$search_name} };
    foreach $_ (@stuff) { 		# add url link
      my $joinkey = 'two'.$_;
      my $person = 'WBPerson'.$_;
      $names{$name} = $person;
#       print "$standard_name{$joinkey}\t$person\t";
    }
#     print "\n";
  }
} # sub processAkaSearch



sub getPgHash {				# get akaHash from postgres instead of flatfile
  my $result;
  my %filter;
  my %aka_hash;
  
  my @tables = qw (first middle last);
  foreach my $table (@tables) { 
    $result = $conn->exec ( "SELECT * FROM two_aka_${table}name WHERE two_aka_${table}name IS NOT NULL AND two_aka_${table}name != 'NULL' AND two_aka_${table}name != '';" );
    while ( my @row = $result->fetchrow ) {
      if ($row[3]) { 					# if there's a time
        my $joinkey = $row[0];
        $row[2] =~ s/^\s+//g; $row[2] =~ s/\s+$//g;	# take out spaces in front and back
        $row[2] =~ s/[\,\.]//g;				# take out commas and dots
        $row[2] =~ s/_/ /g;				# replace underscores for spaces
        $row[2] = lc($row[2]);				# for full values (lowercase it)
        $row[0] =~ s/two//g;				# take out the 'two' from the joinkey
        $filter{$row[0]}{$table}{$row[2]}++;
        my ($init) = $row[2] =~ m/^(\w)/;		# for initials
        $filter{$row[0]}{$table}{$init}++;
      }
    }
    $result = $conn->exec ( "SELECT * FROM two_${table}name WHERE two_${table}name IS NOT NULL AND two_${table}name != 'NULL' AND two_${table}name != '';" );
    while ( my @row = $result->fetchrow ) {
      if ($row[3]) { 					# if there's a time
        my $joinkey = $row[0];
        $row[2] =~ s/^\s+//g; $row[2] =~ s/\s+$//g;	# take out spaces in front and back
        $row[2] =~ s/[\,\.]//g;				# take out commas and dots
        $row[2] =~ s/_/ /g;				# replace underscores for spaces
        $row[2] = lc($row[2]);				# for full values (lowercase it)
        $row[0] =~ s/two//g;				# take out the 'two' from the joinkey
        $filter{$row[0]}{$table}{$row[2]}++;
        my ($init) = $row[2] =~ m/^(\w)/;		# for initials
        $filter{$row[0]}{$table}{$init}++;
      }
    }
  } # foreach my $table (@tables)

  my $possible;
  foreach my $person (sort keys %filter) { 
    foreach my $last (sort keys %{ $filter{$person}{last}} ) {
      foreach my $first (sort keys %{ $filter{$person}{first}} ) {
        $possible = "$first"; $aka_hash{$possible}{$person}++;
        $possible = "$last"; $aka_hash{$possible}{$person}++;
        $possible = "$last $first"; $aka_hash{$possible}{$person}++;
        $possible = "$first $last"; $aka_hash{$possible}{$person}++;
        if ( $filter{$person}{middle} ) {
          foreach my $middle (sort keys %{ $filter{$person}{middle}} ) {
#             $possible = "$first"; $aka_hash{$possible}{$person}++;
            $possible = "$middle"; $aka_hash{$possible}{$person}++;
            $possible = "$first $middle"; $aka_hash{$possible}{$person}++;
            $possible = "$middle $first"; $aka_hash{$possible}{$person}++;
#             $possible = "$last"; $aka_hash{$possible}{$person}++;
#             $possible = "$last $first"; $aka_hash{$possible}{$person}++;
            $possible = "$last $middle"; $aka_hash{$possible}{$person}++;
            $possible = "$last $first $middle"; $aka_hash{$possible}{$person}++;
            $possible = "$last $middle $first"; $aka_hash{$possible}{$person}++;
#             $possible = "$first $last"; $aka_hash{$possible}{$person}++;
            $possible = "$middle $last"; $aka_hash{$possible}{$person}++;
            $possible = "$first $middle $last"; $aka_hash{$possible}{$person}++;
            $possible = "$middle $first $last"; $aka_hash{$possible}{$person}++;
          } # foreach my $middle (sort keys %{ $filter{$person}{middle}} )
        }
      } # foreach my $first (sort keys %{ $filter{$person}{first}} )
    } # foreach my $last (sort keys %{ $filter{$person}{last}} )
  } # foreach my $person (sort keys %filter) 

  return %aka_hash;
} # sub getPgHash

