#!/usr/bin/perl -w

# sample PG query

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my %aka_hash = &getPgHash();

my %two_aid; my %two_name;
my %hash;

my $result = $conn->exec( "SELECT * FROM wpa_author ORDER BY wpa_timestamp" );
while (my @row = $result->fetchrow) { if ($row[3] eq 'valid') { $hash{paper}{$row[1]} = $row[0]; } else { delete $hash{paper}{$row[1]}; } }

# $result = $conn->exec( " SELECT wpa_author_possible.author_id, wpa_author_index.wpa_author_index, wpa_author_possible.wpa_author_possible, wpa_author_verified.wpa_author_verified FROM wpa_author_index, wpa_author_possible, wpa_author_verified WHERE wpa_author_verified.wpa_join = wpa_author_possible.wpa_join AND wpa_author_possible.author_id = wpa_author_verified.author_id AND wpa_author_verified ~ 'YES' AND wpa_author_possible.author_id = wpa_author_index.author_id ORDER BY wpa_author_verified.wpa_timestamp;" );
# 
# while (my @row = $result->fetchrow) {
#   next unless ($row[2]);
#   next unless ($row[2] =~ m/\d/);
#   if ($row[1]) { 
#     next unless ($row[1] =~ m/\w/);
#     $row[1] =~ s/\.//g;
#     $row[1] =~ s/\,//g;
#     $row[2] =~ s/two//g;				# take out the 'two' from the joinkey
# if ($row[2] =~ m/M-BM- /) { print "ROW @row ROW\n"; }
#     my $two = $row[2];
#     my $name = lc($row[1]);
#     $hash{name}{$name}{$row[0]}++;
#     unless ($aka_hash{$two}{$name}) { $filter{$two}{$name}++; }
#     
# #     $row[0] =~ s///g;
# #     $row[1] =~ s///g;
# #     $row[2] =~ s///g;
# #     print "$row[0]\t$row[1]\t$row[2]\n";
#   } # if ($row[0])
# } # while (@row = $result->fetchrow)

my %authors;
$result = $conn->exec( "SELECT * FROM wpa_author_verified WHERE wpa_author_verified ~ 'YES' ORDER BY wpa_timestamp" );
while (my @row = $result->fetchrow ) {
  if ($row[3] eq 'valid') { $authors{verified}{$row[0]}++; }
    else { delete $authors{verified}{$row[0]}; } }
$result = $conn->exec( "SELECT * FROM wpa_author_possible WHERE wpa_author_possible ~ 'two' ORDER BY wpa_timestamp" );
while (my @row = $result->fetchrow ) {
  if ($row[3] eq 'valid') { $authors{possible}{$row[0]} = $row[1]; }
    else { delete $authors{possible}{$row[0]}; } }
$result = $conn->exec( "SELECT * FROM wpa_author_index WHERE wpa_author_index IS NOT NULL ORDER BY wpa_timestamp" );
while (my @row = $result->fetchrow ) {
  if ($row[3] eq 'valid') { $authors{name}{$row[0]} = $row[1]; }
    else { delete $authors{name}{$row[0]}; } }

foreach my $aid (sort keys %{ $authors{verified} }) {
  my $name = $authors{name}{$aid};
  my $two = $authors{possible}{$aid};
  next unless $name;
  next unless $two;
  $name =~ s/\.//g; $name =~ s/\,//g; $name = lc($name); $name =~ s/ +/ /g;
  $two =~ s/two//g;				# take out the 'two' from the joinkey
# if ($two eq '2554') { print "TWO $two NAME $name AID $aid END\n"; }
  $hash{name}{$name}{$aid}++;					# associate the name with the aid
  unless ($aka_hash{$two}{$name}) { 				# if it's not in the aka list, associate the two with the name and the aid
    $two_name{$two}{$name}++;
    $two_aid{$two}{$aid}++; } }

foreach my $two (sort {$a<=>$b} keys %two_aid) {
  foreach my $name (sort keys %{ $two_name{$two} }) {		# want to sort by names that are the same for a given two#
    print "two$two\t$name\t";
    foreach my $aid (sort keys %{ $hash{name}{$name} }) { 	# get the aids
      next unless ($two_aid{$two}{$aid});			# skip the aid if it's not associated with this two# (sorting by names means other twos appear for that name)
      print "$aid ($hash{paper}{$aid})  "; }
    print "\n"; } }


#   unless ($aka_hash{$two}{$name}) { $filter{$two}{$name}++; } # { # }
# 
# foreach my $two (sort {$a<=>$b} keys %filter) {
# # foreach my $two (sort keys %filter) {
#   foreach my $name (sort keys %{ $filter{$two} }) {
#     print "two$two\t$name\t";
#     foreach my $aid (sort keys %{ $hash{name}{$name} }) { 
#       print "$aid ($hash{paper}{$aid})  "; }
#     print "\n"; } }
  


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
        unless ($table eq 'last') {			# look at initials for first and middle but not last name
          my ($init) = $row[2] =~ m/^(\w)/;		# for initials
          $filter{$row[0]}{$table}{$init}++; }
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
        unless ($table eq 'last') {
          my ($init) = $row[2] =~ m/^(\w)/;		# for initials
          $filter{$row[0]}{$table}{$init}++; }
      }
    }
  } # foreach my $table (@tables)

  my %invalid_two;
  $result = $conn->exec( "SELECT * FROM two_status ORDER BY two_timestamp;" );
  while (my @row = $result->fetchrow) {
    if ($row[2] eq 'Invalid') { $invalid_two{$row[0]}++; }
      else { delete $invalid_two{$row[0]}; }
  } # while (my @row = $result->fetchrow)
  foreach my $two (sort keys %invalid_two) { 
    $two =~ s/two//g;				# take out the 'two' from the joinkey
    delete $filter{$two}; }

  my $possible;
  foreach my $person (sort keys %filter) { 
    foreach my $last (sort keys %{ $filter{$person}{last}} ) {
      foreach my $first (sort keys %{ $filter{$person}{first}} ) {
#         $possible = "$last $first"; $aka_hash{$possible}{$person}++;
#         $possible = "$first $last"; $aka_hash{$possible}{$person}++;
        $possible = "$last $first"; $aka_hash{$person}{$possible}++;
        $possible = "$first $last"; $aka_hash{$person}{$possible}++;
        if ( $filter{$person}{middle} ) {			# Cecilia want no middle name matches  2006 11 20
								# Middle name okay if last first middle or first middle last  2007 02 22
          foreach my $middle (sort keys %{ $filter{$person}{middle}} ) {
#             $possible = "$last $first $middle"; $aka_hash{$possible}{$person}++;
#             $possible = "$first $middle $last"; $aka_hash{$possible}{$person}++;
            $possible = "$last $first $middle"; $aka_hash{$person}{$possible}++;
            $possible = "$first $middle $last"; $aka_hash{$person}{$possible}++;
          } # foreach my $middle (sort keys %{ $filter{$person}{middle}} )
        }
      } # foreach my $first (sort keys %{ $filter{$person}{first}} )
    } # foreach my $last (sort keys %{ $filter{$person}{last}} )
  } # foreach my $person (sort keys %filter) 

  return %aka_hash;
} # sub getPgHash


__END__

