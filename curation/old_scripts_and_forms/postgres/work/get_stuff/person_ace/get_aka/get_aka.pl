#!/usr/bin/perl -w

# To create full data set ./get_person_ace.pl > full_person.ace
# fixed Fax entries that had an extra \tOther_phone in them
# added &left_fieldPrint(); for those who have left the field
# added ``AND two IS NOT NULL'' to filter those that do not
# wish to be in wormbase.   2002 12 19
#
# Updated to have a delete_Person.ace file to append to beginning
# of file for next time, to delete entries before inserting new
# ones.  Fixed spaces at end or beginning of entries.  Fixed
# middlename problem that wasn't outputting some standard_names
# because they contained the word NULL.  2003 02 20
#
# Added two_wormbase_comment for comments that go to wormbase.
# 2003 02 28

use strict;
use diagnostics;
use Pg;
use Jex;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my @two_tables = qw(two_firstname two_middlename two_lastname two_street two_city two_state two_post two_country two_mainphone two_labphone two_officephone two_otherphone two_fax two_email two_old_email two_lab two_oldlab two_left_field two_unable_to_contact two_privacy two_aka_firstname two_aka_middlename two_aka_lastname two_apu_firstname two_apu_middlename two_apu_lastname two_webpage);

my $highest_two_val = '3000';
my $lowest_two_val = '0';

my $result;
my @dates = ();

my $error_file = 'errors_in_person.ace';
my $delete_file = 'delete_Person.ace';

# open (ERR, ">$error_file") or die "Cannot create $error_file : $!"; 
open (DEL, ">$delete_file") or die "Cannot create $delete_file : $!"; 

for (my $i = $lowest_two_val; $i < $highest_two_val; $i++) {
  my $joinkey = 'two' . $i;
    # added two IS NOT NULL because there are three people that do not want to be displayed
  $result = $conn->exec( "SELECT * FROM two WHERE joinkey = '$joinkey' AND two IS NOT NULL;" );
  while ( my @row = $result->fetchrow ) {
    if ($row[2]) { 				# if two exists
      @dates = ();
      print DEL "-D Person\tWBPerson$i\n\n"; 		# delete old entry
      print "Person\tWBPerson$i -O \"$row[2]\"\n"; 
      &akaPrint($joinkey);
      print "\n";  				# divider between Persons
    }
  }
} # for (my $i = 0; $i < $highest_two_val; $i++)

sub akaPrint {
  my $joinkey = shift;
  my @row;
  my %aka_hash;
  my @tables = qw (first middle last);
  foreach my $table (@tables) { 
    $result = $conn->exec ( "SELECT * FROM two_aka_${table}name WHERE joinkey = '$joinkey' AND two_aka_${table}name IS NOT NULL AND two_aka_${table}name != 'NULL' AND two_aka_${table}name != '';" );
    while ( @row = $result->fetchrow ) {
      if ($row[3]) { 					# if there's a time
# commented out because some entries are just an initial without a matching full entry for that initial
#         unless ($row[2] =~ m/^\w[^\w]*$/) { 		# if entry isn't just an initial
          $row[2] =~ s/^\s+//g; $row[2] =~ s/\s+$//g;	# take out spaces in front and back
          if ($aka_hash{$table}{$row[2]}) {	# if specific name-type has a time, compare them and update with latest
            (my $now_time) = $row[3] =~ m/^(\d\d\d\d\-\d\d\-\d\d \d\d)/;
            (my $high_time) = $aka_hash{$table}{$row[2]} =~ m/^(\d\d\d\d\-\d\d\-\d\d \d\d)/;
            $now_time =~ s/\D//g; $high_time =~ s/\D//g;
            if ($now_time > $high_time) { $aka_hash{$table}{$row[2]} = $row[3]; }
          } else { $aka_hash{$table}{$row[2]} = $row[3]; }	# if not, then assign time
#         }
      }
    }
    $result = $conn->exec ( "SELECT * FROM two_${table}name WHERE joinkey = '$joinkey' AND two_${table}name IS NOT NULL AND two_${table}name != 'NULL' AND two_${table}name != '';" );
    while ( @row = $result->fetchrow ) {
      if ($row[3]) { 					# if there's a time
# commented out because some entries are just an initial without a matching full entry for that initial
#         unless ($row[2] =~ m/^\w[^\w]*$/) { 		# if entry isn't just an initial
          $row[2] =~ s/^\s+//g; $row[2] =~ s/\s+$//g;	# take out spaces in front and back
          if ($aka_hash{$table}{$row[2]}) {	# if specific name-type has a time, compare them and update with latest
            (my $now_time) = $row[3] =~ m/^(\d\d\d\d\-\d\d\-\d\d \d\d)/;
            (my $high_time) = $aka_hash{$table}{$row[2]} =~ m/^(\d\d\d\d\-\d\d\-\d\d \d\d)/;
            $now_time =~ s/\D//g; $high_time =~ s/\D//g;
            if ($now_time > $high_time) { $aka_hash{$table}{$row[2]} = $row[3]; }
          } else { $aka_hash{$table}{$row[2]} = $row[3]; }	# if not, then assign time
#         }
      }
    }
  } # foreach my $table (@tables)

#   foreach my $aka_entry (sort keys %aka_hash) {
#     my $aka_name; my $aka_time = 0; my $aka_time_temp = 0; my $time_temp = 0;
  
    foreach my $table (@tables) {
      foreach my $aka_value (sort keys %{ $aka_hash{$table} }) {
        print "$table\t\"$aka_value\" -O \"$aka_hash{$table}{$aka_value}\"\n";
      } # foreach my $aka_value (sort keys %{ $aka_hash{$table} })
    } # foreach my $table (@tables)
    
#   } # foreach my $aka_entry (sort keys %aka_hash)

} # sub akaPrint

#   foreach my $aka_entry (sort keys %aka_hash) {
#     my $aka_name; my $aka_time = 0; my $aka_time_temp = 0; my $time_temp = 0;
#   
#     foreach my $table (@tables) { 
#       if ($aka_hash{$aka_entry}{$table}{time}) {
#         $time_temp = $aka_hash{$aka_entry}{$table}{time};
#         ($time_temp) = $time_temp =~ m/^(\d\d\d\d\-\d\d\-\d\d \d\d)/;
#         $time_temp =~ s/\D//g;
#         if ($time_temp > $aka_time_temp) { 
#           $aka_time_temp = $time_temp;
#           $aka_time = $aka_hash{$aka_entry}{$table}{time}; 
#         }
#       } # if ($aka_hash{$aka_entry}{$table}{time})
#     } # foreach my $table (@tables)
#     
#     unless ($aka_hash{$aka_entry}{middle}{val}) { 
#       $aka_name = $aka_hash{$aka_entry}{first}{val} . " " . $aka_hash{$aka_entry}{last}{val};
#     } else {
#       unless ($aka_hash{$aka_entry}{middle}{val} !~ m/NULL/) { 
#         $aka_name = $aka_hash{$aka_entry}{first}{val} . " " . $aka_hash{$aka_entry}{last}{val};
#       } else {
#         $aka_name = $aka_hash{$aka_entry}{first}{val} . " " . $aka_hash{$aka_entry}{middle}{val} . " " . $aka_hash{$aka_entry}{last}{val};
#       }
#   }
#     $aka_name =~ s/\s+/ /g; $aka_name =~ s/^\s+//g; $aka_name =~ s/\s+$//g;
#     if ($aka_name !~ m/NULL/) { 
#       my $otime = &otime($aka_time);
#       print "Also_known_as\t\"$aka_name\" -O \"$otime\"\n";
# #       print "Also_known_as\t\"$aka_name\" -O \"$aka_time\"\n";
#       push @dates, $aka_time;
#     }
#   } # foreach my $aka_entry (sort keys %aka_hash)
