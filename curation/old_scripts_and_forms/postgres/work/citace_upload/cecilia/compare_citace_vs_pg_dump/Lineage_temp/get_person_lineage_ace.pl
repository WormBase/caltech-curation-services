#!/usr/bin/perl -w

# Get Person Lineage data from two_lineage from postgres and output in .ace format.
# Don't get data unless there are twonumbers on both sides.  2003 10 27
#
# Added a check that if there's an Unknown #Role, it won't print it if there's
# already a different (more useful) #Role for that Tag and WBPerson.  2004 01 13
#
# Usage ./get_person_lineage_ace.pl > Person_lineage_date.ace

use strict;
use diagnostics;
use Pg;
use Jex;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $highest_two_val = '4000';
my $lowest_two_val = '0';

for (my $i = $lowest_two_val; $i < $highest_two_val; $i++) {
  my $joinkey = 'two' . $i;
  my $result = $conn->exec( "SELECT * FROM two_lineage WHERE joinkey = '$joinkey' AND two_number ~ 'two'; " );
#   my $result = $conn->exec( "SELECT * FROM two_lineage WHERE joinkey = '$joinkey' AND two_number ~
#   'two' AND two_sender != 'Jonathan Hodgkin' ; " );	# don't get Jonathan's stuff, which is bad
#   on 2004 01 05
  my $stuff = '';
  while (my @row = $result->fetchrow) {
    my $num = $row[3]; $num =~ s/two//g;
    my $role = $row[4];
# Uncomment this when model supports dates
    if ($row[5]) { $role .= "\t$row[5]"; }
    if ($row[6]) { $role .= "\t$row[6]"; }
# Uncomment this when model supports dates
    if ($role =~ m/^Collaborated/) {
      $stuff .= "Worked_with\tWBPerson$num\t$role\n"; }
    elsif ($role =~ m/^with/) {
      $role =~ s/with//g;
      $stuff .= "Supervised_by\tWBPerson$num\t$role\n"; }
    else {
      $stuff .= "Supervised\tWBPerson$num\t$role\n"; }
  } # while (my @row = $result->fetchrow)

  if ($stuff) {
      # Ridiculously overcomplicated way to prevent Role Unknown to appear if already
      # have data under a different Role for that Tag and WBPerson  2004 01 13
    my @stuff = split/\n/, $stuff;
    my %filter;
    foreach my $line (@stuff) {
      my ($front, $role) = $line =~ m/^(.*?\tWB.*?)\t(.*?)$/;
      $filter{$front}{$role}++;
    } # foreach my $line (@stuff)
    foreach my $key (sort keys %filter) {
      my $not_unknown_flag = 0; my $unknown_flag = 0;
      foreach my $role (sort keys %{ $filter{$key} }) {
        if ($role !~ m/^Unknown/) { $not_unknown_flag++; }
        if ($role =~ m/^Unknown/) { $unknown_flag++; }
      } # foreach my $role (sort keys %{ $filter{$key} })
      if ( ($not_unknown_flag > 0) && ($unknown_flag > 0) ) {
        my $take_out = "$key\tUnknown";
        # print "TAKE OUT $take_out\n";
        $stuff =~ s/$take_out.*\n//g;
      } # if ( ($not_unknown_flag > 0) && ($unknown_flag > 0) )
    } # foreach my $key (sort keys %filter)

    print "Person : WBPerson$i\n$stuff\n"; 
  } # if ($stuff)
} # for (my $i = $lowest_two_val; $i < $highest_two_val; $i++)
