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
#
# Changed Standard_name to be Full_name.  Created Standard_name
# as a new table (two_thestandardname) and populated it.  
# 2003 03 22
#
# Changed two_standardname (view) to be two_fullname (view),
# copied two_thestandardname to two_standardname, and deleted
# two_thestandardname.  2003 03 24
#
# Changed to no longer print apu's because they were sent by people
# and that may have typos or not exactly match an acedb author or
# not be an elegans paper's author.  2003 04 10
#
# Deleting -O tags because Wen & Raymond don't want forced timestamp
# override, so will create dumps, and compare to previous to create
# -D and insertion lines in another .ace file.  2003 04 30
#
# Added two_hide, so check for existence, if so, skip the entry so
# as not to display on wormbase.  Filter .'s and ,'s from names and
# aka_names.  2003 05 13
#
# Last_verified should not be affected by last attempt to contact
# since that is not verification (for Cecilia)  2004 02 03
#
# Added Institution for Keith, Todd, Cecilia.  2004 03 31


use strict;
use diagnostics;
use Pg;
use Jex;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my @two_tables = qw(two_firstname two_middlename two_lastname two_street two_city two_state two_post two_country two_institution two_mainphone two_labphone two_officephone two_otherphone two_fax two_email two_old_email two_lab two_oldlab two_left_field two_unable_to_contact two_privacy two_aka_firstname two_aka_middlename two_aka_lastname two_apu_firstname two_apu_middlename two_apu_lastname two_webpage);

my $highest_two_val = '3000';
my $lowest_two_val = '0';

my $result;
my @dates = ();

my $error_file = 'errors_in_person.ace';
my $delete_file = 'delete_Person.ace';

open (ERR, ">$error_file") or die "Cannot create $error_file : $!"; 
open (DEL, ">$delete_file") or die "Cannot create $delete_file : $!"; 

for (my $i = $lowest_two_val; $i < $highest_two_val; $i++) {
  my $joinkey = 'two' . $i;
  $result = $conn->exec( "SELECT * FROM two_hide WHERE joinkey = '$joinkey' AND two_hide IS NOT NULL;" );
  my @row = $result->fetchrow;
  if ($row[2]) { next; }		# skip if meant to hide
    # added two IS NOT NULL because there are three people that do not want to be displayed
  $result = $conn->exec( "SELECT * FROM two WHERE joinkey = '$joinkey' AND two IS NOT NULL;" );
  while ( my @row = $result->fetchrow ) {
    if ($row[2]) { 				# if two exists
      @dates = ();
      print DEL "-D Person\tWBPerson$i\n\n"; 		# delete old entry
      print "Person : \"WBPerson$i\"\n"; 

      &namePrint($joinkey);
      &akaPrint($joinkey);
      &labPrint($joinkey);
      &streetPrint($joinkey);
      &countryPrint($joinkey);
      &institutionPrint($joinkey);
      &emailPrint($joinkey);
      &mainphonePrint($joinkey);
      &labphonePrint($joinkey);
      &officephonePrint($joinkey);
      &otherphonePrint($joinkey);
      &faxPrint($joinkey);
      &webpagePrint($joinkey);
      &old_emailPrint($joinkey);
      &last_attemptPrint($joinkey);
      &left_fieldPrint($joinkey);
      &oldlabPrint($joinkey);
#       &apuPrint($joinkey);		# don't print apu's because sent by person not actual acedb authors
#       &commentPrint($joinkey);	# don't print comments
      &wormbasecommentPrint($joinkey);	# don't print comments
      &last_verifiedPrint();
# missing two_left_field  Last_verified  Last_attempt_to_contact

      print "\n";  				# divider between Persons
    }
  }
} # for (my $i = 0; $i < $highest_two_val; $i++)

close (ERR) or die "Cannot close $error_file : $!";

sub left_fieldPrint {
  my $joinkey = shift;
  $result = $conn->exec ( "SELECT * FROM two_left_field WHERE joinkey = '$joinkey';" );
  while ( my @row = $result->fetchrow ) {
    if ($row[3]) { 
      my $left_field = $row[2];
      my $left_field_time = $row[3];
      my ($date_type) = $left_field_time =~ m/^(\d\d\d\d\-\d\d\-\d\d)/;
      if ($left_field !~ m/NULL/) { 
        $left_field =~ s/\s+/ /g; $left_field =~ s/^\s+//g; $left_field =~ s/\s+$//g;
        $left_field =~ s/\//\\\//g;
        my $otime = &otime($left_field_time);
#         print "Last_attempt_to_contact\t $date_type\t\"$unable_to_contact\"\n"; 
        print "Left_the_field\t \"$left_field\"\n"; 
        push @dates, $left_field_time;
      }
    } # if ($row[3])
  } # while ( my @row = $result->fetchrow )
} # sub left_fieldPrint

sub last_verifiedPrint {
  my $date = ''; my $time_temp = ''; my $highest = 0;
  foreach my $time (@dates) {
    $time_temp = $time;
    ($time_temp) = $time_temp =~ m/^(\d\d\d\d\-\d\d\-\d\d \d\d)/;
    $time_temp =~ s/\D//g;
    if ($time_temp > $highest) {
      $highest = $time_temp;
      $date = $time;
    } # if ($time_temp > $highest)
  } # foreach my $time (@dates)
  my ($date_type) = $date =~ m/^(\d\d\d\d\-\d\d\-\d\d)/;
  my $otime = &otime($date);
#   print "Last_verified\t $date_type\n";
  print "Last_verified\t $date_type\n";
} # sub last_verifiedPrint

sub otime {
  my $otime = shift;
  $otime =~ s/\-\d\d$/_cecilia/g;
  return $otime;
} # sub otime

sub last_attemptPrint {
  my $joinkey = shift;
  $result = $conn->exec ( "SELECT * FROM two_unable_to_contact WHERE joinkey = '$joinkey';" );
  while ( my @row = $result->fetchrow ) {
    if ($row[3]) { 
      my $unable_to_contact = $row[2];
      my $unable_to_contact_time = $row[3];
      my ($date_type) = $unable_to_contact_time =~ m/^(\d\d\d\d\-\d\d\-\d\d)/;
      if ($unable_to_contact !~ m/NULL/) { 
        $unable_to_contact =~ s/\s+/ /g; $unable_to_contact =~ s/^\s+//g; $unable_to_contact =~ s/\s+$//g;
        $unable_to_contact =~ s/\//\\\//g;
        $unable_to_contact =~ s/\;/\\\;/g;
        my $otime = &otime($unable_to_contact_time);
#         print "Last_attempt_to_contact\t $date_type \"$unable_to_contact\"\n";
        print "Last_attempt_to_contact\t $date_type \"$unable_to_contact\"\n";
#         push @dates, $unable_to_contact_time;		# don't include last attempt to contact for Last_verified
      }
    } # if ($row[3])
  } # while ( my @row = $result->fetchrow )
} # sub last_attemptPrint

sub wormbasecommentPrint {
  my $joinkey = shift;
  $result = $conn->exec ( "SELECT * FROM two_wormbase_comment WHERE joinkey = '$joinkey';" );
  while ( my @row = $result->fetchrow ) {
    if ($row[3]) { 
      my $wormbase_comment = $row[2];
      my $wormbase_comment_time = $row[3];
      if ( ($wormbase_comment !~ m/NULL/) && ($wormbase_comment !~ m/nodatahere/) ) { 
        $wormbase_comment =~ s/\n/ /sg;
        if ($wormbase_comment !~ m/NULL/) { 
	  $wormbase_comment =~ s/\s+/ /g; $wormbase_comment =~ s/^\s+//g; $wormbase_comment =~ s/\s+$//g;
          $wormbase_comment =~ s/\//\\\//g;
          my $otime = &otime($wormbase_comment_time);
          print "Comment\t \"$wormbase_comment\"\n"; 
          push @dates, $wormbase_comment_time;
        }
      }
    } # if ($row[2])
  } # while ( my @row = $result->fetchrow )
} # sub wormbasecommentPrint

sub commentPrint {
  my $joinkey = shift;
  $result = $conn->exec ( "SELECT * FROM two_comment WHERE joinkey = '$joinkey';" );
  while ( my @row = $result->fetchrow ) {
    if ($row[2]) { 
      my $comment = $row[1];
      my $comment_time = $row[2];
      if ( ($comment !~ m/NULL/) && ($comment !~ m/nodatahere/) ) { 
        $comment =~ s/\n/ /sg;
        if ($comment !~ m/NULL/) { 
	  $comment =~ s/\s+/ /g; $comment =~ s/^\s+//g; $comment =~ s/\s+$//g;
          $comment =~ s/\//\\\//g;
          my $otime = &otime($comment_time);
          print "Comment\t \"$comment\"\n";
          push @dates, $comment_time;
        }
      }
    } # if ($row[2])
  } # while ( my @row = $result->fetchrow )
# This seems unnecessary, why is it here ?
#   $result = $conn->exec ( "SELECT * FROM two_comment WHERE joinkey = '$joinkey';" );
#   while ( my @row = $result->fetchrow ) {
#     if ($row[3]) { 
#       my $comment = $row[2];
#       my $comment_time = $row[3];
#       $comment =~ s/\n/ /sg;
#       if ($comment !~ m/NULL/) { 
# 	$comment =~ s/\s+/ /g; $comment =~ s/^\s+//g; $comment =~ s/\s+$//g;
#       $comment =~ s/\//\\\//g;
#         my $otime = &otime($comment_time);
#         print "Comment\t \"$comment\"\n"; 
# #         print "Comment\t \"$comment\"\n"; 
#         push @dates, $comment_time;
#       }
#     } # if ($row[3])
#   } # while ( my @row = $result->fetchrow )
} # sub emailPrint

sub oldlabPrint {
  my $joinkey = shift;
  $result = $conn->exec ( "SELECT * FROM two_oldlab WHERE joinkey = '$joinkey';" );
  while ( my @row = $result->fetchrow ) {
    if ($row[3]) { 
      my $oldlab = $row[2];
      my $oldlab_time = $row[3];
      if ($oldlab !~ m/NULL/) { 
	$oldlab =~ s/\s+/ /g; $oldlab =~ s/^\s+//g; $oldlab =~ s/\s+$//g;
        $oldlab =~ s/\//\\\//g;
        my $otime = &otime($oldlab_time);
        print "Old_laboratory\t \"$oldlab\"\n"; 
#         print "Old_laboratory\t \"$oldlab\"\n"; 
        push @dates, $oldlab_time;
      }
    } # if ($row[3])
  } # while ( my @row = $result->fetchrow )
} # sub emailPrint

sub old_emailPrint {
  my $joinkey = shift;
  $result = $conn->exec ( "SELECT * FROM two_old_email WHERE joinkey = '$joinkey';" );
  while ( my @row = $result->fetchrow ) {
    if ($row[3]) { 
      my $old_email = $row[2];
      my $old_email_time = $row[3];
      my ($date_type) = $old_email_time =~ m/^(\d\d\d\d\-\d\d\-\d\d)/;
      if ($old_email !~ m/NULL/) { 
	$old_email =~ s/\s+/ /g; $old_email =~ s/^\s+//g; $old_email =~ s/\s+$//g;
        $old_email =~ s/\//\\\//g;
        $old_email =~ s/%/\\%/g;
        my $otime = &otime($old_email_time);
        print "Old_address\t $date_type Email \"$old_email\"\n"; 
#         print "Old_address\t $date_type Email \"$old_email\"\n"; 
        push @dates, $old_email_time;
      }
    } # if ($row[3])
  } # while ( my @row = $result->fetchrow )
} # sub emailPrint

sub webpagePrint {
  my $joinkey = shift;
  $result = $conn->exec ( "SELECT * FROM two_webpage WHERE joinkey = '$joinkey';" );
  while ( my @row = $result->fetchrow ) {
    if ($row[3]) { 
      my $webpage = $row[2];
      my $webpage_time = $row[3];
      if ($webpage !~ m/NULL/) { 
	$webpage =~ s/\s+/ /g; $webpage =~ s/^\s+//g; $webpage =~ s/\s+$//g;
        $webpage =~ s/\//\\\//g;
        $webpage =~ s/%/\\%/g;
        my $otime = &otime($webpage_time);
#         print "Address\t Web_page \"$webpage\"\n"; 
        print "Address\t Web_page \"$webpage\"\n"; 
        push @dates, $webpage_time;
      }
    } # if ($row[3])
  } # while ( my @row = $result->fetchrow )
} # sub emailPrint

sub faxPrint {
  my $joinkey = shift;
  $result = $conn->exec ( "SELECT * FROM two_fax WHERE joinkey = '$joinkey';" );
  while ( my @row = $result->fetchrow ) {
    if ($row[3]) { 
      my $fax = $row[2];
      my $fax_time = $row[3];
      if ($fax !~ m/NULL/) { 
	$fax =~ s/\s+/ /g; $fax =~ s/^\s+//g; $fax =~ s/\s+$//g;
        $fax =~ s/\//\\\//g;
        my $otime = &otime($fax_time);
        print "Address\t Fax \"$fax\"\n"; 
#         print "Address\t Fax \"$fax\"\n"; 
        push @dates, $fax_time;
      }
    } # if ($row[3])
  } # while ( my @row = $result->fetchrow )
} # sub emailPrint

sub otherphonePrint {
  my $joinkey = shift;
  $result = $conn->exec ( "SELECT * FROM two_otherphone WHERE joinkey = '$joinkey';" );
  while ( my @row = $result->fetchrow ) {
    if ($row[3]) { 
      my $otherphone = $row[2];
      my $otherphone_time = $row[3];
      if ($otherphone !~ m/NULL/) { 
	$otherphone =~ s/\s+/ /g; $otherphone =~ s/^\s+//g; $otherphone =~ s/\s+$//g;
        $otherphone =~ s/\//\\\//g;
        my $otime = &otime($otherphone_time);
        print "Address\t Other_phone \"$otherphone\"\n"; 
#         print "Address\t Other_phone \"$otherphone\"\n"; 
        push @dates, $otherphone_time;
      }
    } # if ($row[3])
  } # while ( my @row = $result->fetchrow )
} # sub emailPrint

sub officephonePrint {
  my $joinkey = shift;
  $result = $conn->exec ( "SELECT * FROM two_officephone WHERE joinkey = '$joinkey';" );
  while ( my @row = $result->fetchrow ) {
    if ($row[3]) { 
      my $officephone = $row[2];
      my $officephone_time = $row[3];
      if ($officephone !~ m/NULL/) { 
	$officephone =~ s/\s+/ /g; $officephone =~ s/^\s+//g; $officephone =~ s/\s+$//g;
        $officephone =~ s/\//\\\//g;
        my $otime = &otime($officephone_time);
        print "Address\t Office_phone \"$officephone\"\n"; 
#         print "Address\t Office_phone \"$officephone\"\n"; 
        push @dates, $officephone_time;
      }
    } # if ($row[3])
  } # while ( my @row = $result->fetchrow )
} # sub emailPrint

sub labphonePrint {
  my $joinkey = shift;
  $result = $conn->exec ( "SELECT * FROM two_labphone WHERE joinkey = '$joinkey';" );
  while ( my @row = $result->fetchrow ) {
    if ($row[3]) { 
      my $labphone = $row[2];
      my $labphone_time = $row[3];
      if ($labphone !~ m/NULL/) { 
	$labphone =~ s/\s+/ /g; $labphone =~ s/^\s+//g; $labphone =~ s/\s+$//g;
        $labphone =~ s/\//\\\//g;
        my $otime = &otime($labphone_time);
        print "Address\t Lab_phone \"$labphone\"\n"; 
#         print "Address\t Lab_phone \"$labphone\"\n"; 
        push @dates, $labphone_time;
      }
    } # if ($row[3])
  } # while ( my @row = $result->fetchrow )
} # sub emailPrint

sub mainphonePrint {
  my $joinkey = shift;
  $result = $conn->exec ( "SELECT * FROM two_mainphone WHERE joinkey = '$joinkey';" );
  while ( my @row = $result->fetchrow ) {
    if ($row[3]) { 
      my $mainphone = $row[2];
      my $mainphone_time = $row[3];
      if ($mainphone !~ m/NULL/) { 
	$mainphone =~ s/\s+/ /g; $mainphone =~ s/^\s+//g; $mainphone =~ s/\s+$//g;
        $mainphone =~ s/\//\\\//g;
        my $otime = &otime($mainphone_time);
        print "Address\t Main_phone \"$mainphone\"\n"; 
#         print "Address\t Main_phone \"$mainphone\"\n"; 
        push @dates, $mainphone_time;
      }
    } # if ($row[3])
  } # while ( my @row = $result->fetchrow )
} # sub emailPrint

sub emailPrint {
  my $joinkey = shift;
  $result = $conn->exec ( "SELECT * FROM two_email WHERE joinkey = '$joinkey';" );
  while ( my @row = $result->fetchrow ) {
    if ($row[3]) { 
      my $email = $row[2];
      my $email_time = $row[3];
      if ($email !~ m/NULL/) { 
	$email =~ s/\s+/ /g; $email =~ s/^\s+//g; $email =~ s/\s+$//g;
        $email =~ s/\//\\\//g;
        $email =~ s/%/\\%/g;
        my $otime = &otime($email_time);
        print "Address\t Email \"$email\"\n"; 
#         print "Address\t Email \"$email\"\n"; 
        push @dates, $email_time;
      }
    } # if ($row[3])
  } # while ( my @row = $result->fetchrow )
} # sub emailPrint

sub countryPrint {
  my $joinkey = shift;
  $result = $conn->exec ( "SELECT * FROM two_country WHERE joinkey = '$joinkey';" );
  while ( my @row = $result->fetchrow ) {
    if ($row[3]) { 
      my $country = $row[2];
      my $country_time = $row[3];
      if ($row[2] !~ m/NULL/) { 
        $country =~ s/\s+/ /g; $country =~ s/^\s+//g; $country =~ s/\s+$//g;
        $country =~ s/\//\\\//g;
        my $otime = &otime($country_time);
        print "Address\t Country \"$country\"\n"; 
#         print "Address\t Country \"$country\"\n"; 
        push @dates, $country_time;
      }
    } # if ($row[3])
  } # while ( my @row = $result->fetchrow )
} # sub countryPrint

sub institutionPrint {
  my $joinkey = shift;
  $result = $conn->exec ( "SELECT * FROM two_institution WHERE joinkey = '$joinkey';" );
  while ( my @row = $result->fetchrow ) {
    if ($row[3]) { 
      my $institution = $row[2];
      my $institution_time = $row[3];
      if ($row[2] !~ m/NULL/) { 
        $institution =~ s/\s+/ /g; $institution =~ s/^\s+//g; $institution =~ s/\s+$//g;
        $institution =~ s/\//\\\//g;
        my $otime = &otime($institution_time);
        print "Address\t Institution \"$institution\"\n"; 
#         print "Address\t Institution \"$institution\"\n"; 
        push @dates, $institution_time;
      }
    } # if ($row[3])
  } # while ( my @row = $result->fetchrow )
} # sub countryPrint

sub streetPrint {
  my $joinkey = shift;
  my %street_hash; my @row;
  my @tables = qw( two_street two_city two_state two_post );
  foreach my $table (@tables) { 
    $result = $conn->exec ( "SELECT * FROM ${table} WHERE joinkey = '$joinkey' ORDER BY two_order;" );
    while ( @row = $result->fetchrow ) {	# foreach line of data
      if ($row[3]) { 				# if there's data (date)
        if ($table eq 'two_street') { 		# street data print straight out
          my $street = $row[2];
          my $street_time = $row[3];
          if ($row[2] !~ m/NULL/) { 		# if there's data
            $street =~ s/\s+/ /g; $street =~ s/^\s+//g; $street =~ s/\s+$//g;
            $street =~ s/\//\\\//g;
            my $otime = &otime($street_time);
            print "Address\t Street_address \"$street\"\n";
#             print "Address\t Street_address \"$street\"\n";
            push @dates, $street_time;
          } # if ($row[2] !~ m/NULL/)
        } else { 				# city, state, and post preprocess
          if ($row[2] !~ m/NULL/) { 		# if there's data
            $row[2] =~ s/\s+/ /g;
            $row[2] =~ s/\//\\\//g;
            $street_hash{$row[1]}{$table}{val} = $row[2];
            $street_hash{$row[1]}{$table}{time} = $row[3];
          }
        } 
      } # if ($row[3])
    } # while ( @row = $result->fetchrow )
  } # foreach my $table (@tables)

  foreach my $street_entry (sort keys %street_hash) {
    my $street_name; my $street_time = 0; my $street_time_temp = 0; my $time_temp = 0;
  
    foreach my $table (@tables) { 
      if ($street_hash{$street_entry}{$table}{time}) {
        $time_temp = $street_hash{$street_entry}{$table}{time};
        ($time_temp) = $time_temp =~ m/^(\d\d\d\d\-\d\d\-\d\d \d\d)/;
        $time_temp =~ s/\D//g;
        if ($time_temp > $street_time_temp) { 
          $street_time_temp = $time_temp;
          $street_time = $street_hash{$street_entry}{$table}{time}; 
          push @dates, $street_time;
        }
      } # if ($street_hash{$street_entry}{$table}{time})
    } # foreach my $table (@tables)

    my $otime = &otime($street_time);
    my $city; my $state; my $post; 
    if ($street_hash{$street_entry}{two_city}{val}) { $city = $street_hash{$street_entry}{two_city}{val}; }
    if ($street_hash{$street_entry}{two_state}{val}) { $state = $street_hash{$street_entry}{two_state}{val}; }
    if ($street_hash{$street_entry}{two_post}{val}) { $post = $street_hash{$street_entry}{two_post}{val}; }

    if ($city) { $city =~ s/\s+/ /g; $city =~ s/^\s+//g; $city =~ s/\s+$//g; }
    if ($state) { $state =~ s/\s+/ /g; $state =~ s/^\s+//g; $state =~ s/\s+$//g; }
    if ($post) { $post =~ s/\s+/ /g; $post =~ s/^\s+//g; $post =~ s/\s+$//g; }

    if ( ($city) && ($state) && ($post) ) { print "Address\t Street_address \"$city, $state $post\"\n"; }
    elsif ( ($city) && ($state) ) { print "Address\t Street_address \"$city, $state\"\n"; }
    elsif ( ($city) && ($post) ) { print "Address\t Street_address \"$city, $post\"\n"; }
    elsif ( ($state) && ($post) ) { print "Address\t Street_address \"$state $post\"\n"; }
    elsif ($city) { print "Address\t Street_address \"$city\"\n"; }
    elsif ($state) { print "Address\t Street_address \"$state\"\n"; }
    elsif ($post) { print "Address\t Street_address \"$post\"\n"; }
    else { 1; }
  } # foreach my $street_entry (sort keys %street_hash)
} # sub streetPrint

sub labPrint {
  my $joinkey = shift;
  $result = $conn->exec ( "SELECT * FROM two_lab WHERE joinkey = '$joinkey';" );
  while ( my @row = $result->fetchrow ) {
    if ($row[3]) { 
      my $lab = $row[2];
      my $lab_time = $row[3];
      if ($row[2] !~ m/NULL/) { 
        $lab =~ s/\s+/ /g; $lab =~ s/^\s+//g; $lab =~ s/\s+$//g;
        $lab =~ s/\//\\\//g;
        if ($lab !~ m/[A-Z][A-Z]/) { print "ERROR $joinkey LAB $lab\n"; }
          else { 
    	    my $otime = &otime($lab_time);
	    print "Laboratory\t \"$lab\"\n"; 
# 	    print "Laboratory\t \"$lab\"\n"; 
	  }
        push @dates, $lab_time;
      }
    } # if ($row[3])
  } # while ( my @row = $result->fetchrow )
} # sub labPrint

sub apuPrint {
  my $joinkey = shift;
  my @row;
  my %apu_hash;
  my @tables = qw (first middle last);
  foreach my $table (@tables) { 
    $result = $conn->exec ( "SELECT * FROM two_apu_${table}name WHERE joinkey = '$joinkey';" );
    while ( @row = $result->fetchrow ) { 
      if ($row[3]) { 
        $apu_hash{$row[1]}{$table}{val} = $row[2];
        $apu_hash{$row[1]}{$table}{time} = $row[3];
      }
    }
  } # foreach my $table (@tables)

  foreach my $apu_entry (sort keys %apu_hash) {
    my $apu_name; my $apu_time = 0; my $apu_time_temp = 0; my $time_temp = 0;
  
    foreach my $table (@tables) { 
      if ($apu_hash{$apu_entry}{$table}{time}) {
        $time_temp = $apu_hash{$apu_entry}{$table}{time};
        ($time_temp) = $time_temp =~ m/^(\d\d\d\d\-\d\d\-\d\d \d\d)/;
        $time_temp =~ s/\D//g;
        if ($time_temp > $apu_time_temp) { 
          $apu_time_temp = $time_temp;
          $apu_time = $apu_hash{$apu_entry}{$table}{time}; 
        }
      } # if ($apu_hash{$apu_entry}{$table}{time})
    } # foreach my $table (@tables)
    
    unless ($apu_hash{$apu_entry}{middle}{val}) { 
      $apu_name = $apu_hash{$apu_entry}{first}{val} . " " . $apu_hash{$apu_entry}{last}{val};
    } else {
      unless ($apu_hash{$apu_entry}{middle}{val} !~ m/NULL/) { 
        $apu_name = $apu_hash{$apu_entry}{first}{val} . " " . $apu_hash{$apu_entry}{last}{val};
      } else {
        $apu_name = $apu_hash{$apu_entry}{first}{val} . " " . $apu_hash{$apu_entry}{middle}{val} . " " . $apu_hash{$apu_entry}{last}{val};
      }
    }
    $apu_name =~ s/\s+/ /g; $apu_name =~ s/^\s+//g; $apu_name =~ s/\s+$//g;
    $apu_name =~ s/\//\\\//g;
    if ($apu_name !~ m/NULL/) { 
      my $otime = &otime($apu_time);
# DON'T PUT IN BECAUSE PERSON SENDS STUFF AND IT MAY NOT BE ACEDB-FORMAT AUTHOR
#       print "Publishes_as\t \"$apu_name\"\n";	# confirmed 
#       print "Possibly_publishes_as\t \"$apu_name\"\n";	
#       print "Possibly_publishes_as\t \"$apu_name\"\n";
      push @dates, $apu_time;
    }
  } # foreach my $apu_entry (sort keys %apu_hash)
} # sub apuPrint

sub akaPrint {
  my $joinkey = shift;
  my @row;
  my %aka_hash;
  my @tables = qw (first middle last);
  foreach my $table (@tables) { 
    $result = $conn->exec ( "SELECT * FROM two_aka_${table}name WHERE joinkey = '$joinkey';" );
    while ( @row = $result->fetchrow ) { 
      if ($row[3]) { 
        $aka_hash{$row[1]}{$table}{val} = $row[2];
        $aka_hash{$row[1]}{$table}{time} = $row[3];
      }
    }
  } # foreach my $table (@tables)

  foreach my $aka_entry (sort keys %aka_hash) {
    my $aka_name; my $aka_time = 0; my $aka_time_temp = 0; my $time_temp = 0;
  
    foreach my $table (@tables) { 
      if ($aka_hash{$aka_entry}{$table}{time}) {
        $time_temp = $aka_hash{$aka_entry}{$table}{time};
        ($time_temp) = $time_temp =~ m/^(\d\d\d\d\-\d\d\-\d\d \d\d)/;
        $time_temp =~ s/\D//g;
        if ($time_temp > $aka_time_temp) { 
          $aka_time_temp = $time_temp;
          $aka_time = $aka_hash{$aka_entry}{$table}{time}; 
        }
      } # if ($aka_hash{$aka_entry}{$table}{time})
    } # foreach my $table (@tables)
    
    unless ($aka_hash{$aka_entry}{middle}{val}) { 
      $aka_name = $aka_hash{$aka_entry}{first}{val} . " " . $aka_hash{$aka_entry}{last}{val};
    } else {
      unless ($aka_hash{$aka_entry}{middle}{val}) { $aka_hash{$aka_entry}{middle}{val} = ''; }
      unless ($aka_hash{$aka_entry}{middle}{val} !~ m/NULL/) { 
        $aka_name = $aka_hash{$aka_entry}{first}{val} . " " . $aka_hash{$aka_entry}{last}{val}; }
      else {
        $aka_name = $aka_hash{$aka_entry}{first}{val} . " " . $aka_hash{$aka_entry}{middle}{val} . " " . $aka_hash{$aka_entry}{last}{val}; }
    }
    $aka_name =~ s/\s+/ /g; $aka_name =~ s/^\s+//g; $aka_name =~ s/\s+$//g;
    $aka_name =~ s/\//\\\//g;
    if ($aka_name !~ m/NULL/) { 
      my $otime = &otime($aka_time);
      $aka_name =~ s/\.//g; $aka_name =~ s/\,//g;
      print "Also_known_as\t \"$aka_name\"\n";
#       print "Also_known_as\t \"$aka_name\"\n";
      push @dates, $aka_time;
    }
  } # foreach my $aka_entry (sort keys %aka_hash)
} # sub akaPrint


sub namePrint	{	# name block
  my $joinkey = shift;
  my $firstname; my $middlename; my $lastname; my $standardname; my $timestamp; my $full_name;
  $result = $conn->exec ( "SELECT * FROM two_firstname WHERE joinkey = '$joinkey';" );
  my @row = $result->fetchrow;
  if ($row[3]) { 
    $firstname = $row[2];
    $timestamp = $row[3];
    if ($firstname !~ m/NULL/) { 
      $firstname =~ s/\s+/ /g; $firstname =~ s/^\s+//g; $firstname =~ s/\s+$//g;
      $firstname =~ s/\//\\\//g;
      my $otime = &otime($timestamp);
      $firstname =~ s/\.//g; $firstname =~ s/\,//g;
      print "First_name\t \"$firstname\"\n";
#       print "First_name\t \"$firstname\"\n";
    } else { print ERR "ERROR no firstname for $joinkey : $firstname\n"; }
  }
  $result = $conn->exec ( "SELECT * FROM two_middlename WHERE joinkey = '$joinkey';" );
  @row = $result->fetchrow;
  if ($row[3]) { 
    $middlename = $row[2];
    $timestamp = $row[3];
    if ($middlename !~ m/NULL/) { 
      $middlename =~ s/\s+/ /g; $middlename =~ s/^\s+//g; $middlename =~ s/\s+$//g;
      $middlename =~ s/\//\\\//g;
      my $otime = &otime($timestamp);
      $middlename =~ s/\.//g; $middlename =~ s/\,//g;
      print "Middle_name\t \"$middlename\"\n";
#       print "Middle_name\t \"$middlename\"\n";
    } else { print ERR "ERROR no middlename for $joinkey : $middlename\n"; }
  }
  $result = $conn->exec ( "SELECT * FROM two_lastname WHERE joinkey = '$joinkey';" );
  @row = $result->fetchrow;
  if ($row[3]) { 
    $lastname = $row[2];
    $timestamp = $row[3];
    if ($lastname !~ m/NULL/) { 
      $lastname =~ s/\s+/ /g; $lastname =~ s/^\s+//g; $lastname =~ s/\s+$//g;
      $lastname =~ s/\//\\\//g;
      my $otime = &otime($timestamp);
      $lastname =~ s/\.//g; $lastname =~ s/\,//g;
      print "Last_name\t \"$lastname\"\n";
#       print "Last_name\t \"$lastname\"\n";
    } else { print "ERROR no lastname for $joinkey : $lastname\n"; }
  }
  unless ($middlename) { $middlename = ''; }
  if ($middlename !~ m/NULL/) {
    $full_name = $firstname . " " . $middlename . " " . $lastname; }
  else {
    $full_name = $firstname . " " . $lastname; } 
  $standardname = $firstname . " " . $lastname;	# init as default first last
  $result = $conn->exec ( "SELECT * FROM two_standardname WHERE joinkey = '$joinkey';" );
  @row = $result->fetchrow;
  if ($row[3]) {
    $standardname = $row[2];
    $timestamp = $row[3];
    if ($standardname !~ m/NULL/) { 
      $standardname =~ s/\s+/ /g; $standardname =~ s/^\s+//g; $standardname =~ s/\s+$//g;
      $standardname =~ s/\//\\\//g;
      my $otime = &otime($timestamp);
#       print "Standard_name\t \"$standardname\"\n";
#       print "Standard_name\t \"$standardname\"\n";
    } else { print "ERROR no standardname for $joinkey : $standardname\n"; }
    print "Standard_name\t \"$standardname\"\n";
  }
  unless ($full_name) { $full_name = ''; }
  if ($full_name !~ m/NULL/) {
    $full_name =~ s/\s+/ /g; $full_name =~ s/^\s+//g; $full_name =~ s/\s+$//g;
    my $otime = &otime($timestamp);
    print "Full_name\t \"$full_name\"\n";
#     print "Full_name\t \"$full_name\"\n";
    push @dates, $timestamp; }
  else { print ERR "ERROR no full_name for $joinkey : $full_name\n"; }
} # sub namePrint	
