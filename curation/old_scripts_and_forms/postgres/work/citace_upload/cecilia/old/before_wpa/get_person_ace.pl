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
#
#######
#
# Took original Person dumpers from 
# /home/postgres/work/citace_upload/cecilia/compare_citace_vs_pg_dump/
# /home/postgres/work/citace_upload/cecilia/compare_citace_vs_pg_dump/person_paper_author_for_now
# /home/postgres/work/citace_upload/cecilia/compare_citace_vs_pg_dump/Lineage_temp
# and combined into this script to dump data that all 3 scripts would dump separetly.
#
# usage ./get_person_ace.pl > Juancarlos_date.ace
# then diff with the ./find_diff.pl old.ace new.ace > Cecilia_date.ace 
#
# Cleaned up lots of errors from bad timestamp data or missing data causing 
# concatenations errors.  Deleted all stuff relating to .ace -O timestamp.
# 2004 05 19
#
# Changed to have WBPaper instead of paper.  Only error from 
# ERROR No conversion for wm7710a on two521   which already exists as 
# wm77p10a, so everything seems ok.  2004 09 02
#
# It was dumping affiliation address data which is not in the model.  2004 12 29 
#
# Changed some tabs to spaces, added spaces after tabs, took out "s
# to make the dump match a citace dump for diff'ing.  2005 03 15
#
# Temporarily ignore list of stuff from Eimear because these WBPapers have 
# been merged with others and are no longer the correct WBPaper.  2005 05 26
#
# Changed to add papers to a sorting hash to sort papers.  unnecessary, but
# tried to keep the old find_diff.pl ;  eventually fixed that to not sort 
# unordered tags instead.  2005 07 16




use strict;
use diagnostics;
use Pg;
use Jex;
use LWP;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my @two_tables = qw(two_firstname two_middlename two_lastname two_street two_city two_state two_post two_country two_institution two_mainphone two_labphone two_officephone two_otherphone two_fax two_email two_old_email two_lab two_oldlab two_left_field two_unable_to_contact two_privacy two_aka_firstname two_aka_middlename two_aka_lastname two_apu_firstname two_apu_middlename two_apu_lastname two_webpage);

my $highest_two_val = '4000';
my $lowest_two_val = '0';

my $result;
my @dates = ();

my $error_file = 'errors_in_person.ace';

open (ERR, ">$error_file") or die "Cannot create $error_file : $!"; 

my %paperHash;
&populatePaperHash;

my %convertToWBPaper;	# key cgc or pmid or whatever, value WBPaper
&readConvertions();


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
      &lineagePrint($joinkey);
      &paperPrint($joinkey);
      &last_verifiedPrint();
      print "\n";  				# divider between Persons
    }
  }
} # for (my $i = 0; $i < $highest_two_val; $i++)

close (ERR) or die "Cannot close $error_file : $!";

sub lineagePrint {
  my $joinkey = shift;
  my $result = $conn->exec( "SELECT * FROM two_lineage WHERE joinkey = '$joinkey' AND two_number ~ 'two'; " );
  my $stuff = '';
  while (my @row = $result->fetchrow) {
    my $num = $row[3]; $num =~ s/two//g;
    my $role = $row[4];
    if ($row[5]) { $role .= " $row[5]"; }
    if ($row[6]) { $role .= " $row[6]"; }
    if ($role =~ m/^Collaborated/) {
      $stuff .= "Worked_with\t \"WBPerson$num\" $role\n"; }
    elsif ($role =~ m/^with/) {
      $role =~ s/with//g;
      $stuff .= "Supervised_by\t \"WBPerson$num\" $role\n"; }
    else {
      $stuff .= "Supervised\t \"WBPerson$num\" $role\n"; }
  } # while (my @row = $result->fetchrow)

  if ($stuff) {
      # Ridiculously overcomplicated way to prevent Role Unknown to appear if already
      # have data under a different Role for that Tag and WBPerson  2004 01 13
    my @stuff = split/\n/, $stuff;
    my %filter;
    foreach my $line (@stuff) {
      my ($front, $role) = $line =~ m/^(.*?\t \"WB.*?) (.*?)$/;
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
    print $stuff;
  } # if ($stuff)
} # sub lineagePrint



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
    unless ($time_temp) { $time_temp = '1970-01-01'; }
    if ($time_temp =~ m/\D/) { $time_temp =~ s/\D//g; }
    if ($time_temp > $highest) {
      $highest = $time_temp;
      $date = $time;
    } # if ($time_temp > $highest)
  } # foreach my $time (@dates)
  my ($date_type) = $date =~ m/^(\d\d\d\d\-\d\d\-\d\d)/;
  print "Last_verified\t $date_type\n";
} # sub last_verifiedPrint

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
        print "Last_attempt_to_contact\t $date_type \"$unable_to_contact\"\n";
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
          print "Comment\t \"$comment\"\n";
          push @dates, $comment_time;
        }
      }
    } # if ($row[2])
  } # while ( my @row = $result->fetchrow )
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
        print "Old_laboratory\t \"$oldlab\"\n"; 
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
        print "Old_address\t $date_type Email \"$old_email\"\n"; 
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
        print "Address\t Fax \"$fax\"\n"; 
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
        print "Address\t Other_phone \"$otherphone\"\n"; 
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
        print "Address\t Office_phone \"$officephone\"\n"; 
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
        print "Address\t Lab_phone \"$labphone\"\n"; 
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
        print "Address\t Main_phone \"$mainphone\"\n"; 
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
        print "Address\t Email \"$email\"\n"; 
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
        print "Address\t Country \"$country\"\n"; 
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
        if ($row[1] == 1) {			# put first thing in Address
          print "Address\t Institution \"$institution\"\n";  }
        else {					# put other things in Old_address
          my ($date_type) = $row[3] =~ m/^(\d\d\d\d\-\d\d\-\d\d)/;
          print "Old_address\t $date_type Institution \"$institution\"\n";  }
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
            print "Address\t Street_address \"$street\"\n";
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
        if ($lab !~ m/[A-Z][A-Z]/) { print ERR "ERROR $joinkey LAB $lab\n"; }
          else { 
	    print "Laboratory\t \"$lab\"\n"; 
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
      if ($row[2]) { $aka_hash{$row[1]}{$table}{val} = $row[2]; } else { $aka_hash{$row[1]}{$table}{val} = ' '; }
      if ($row[3]) { $aka_hash{$row[1]}{$table}{time} = $row[3]; } else { $aka_hash{$row[1]}{$table}{time} = ' '; }
    }
  } # foreach my $table (@tables)

  foreach my $aka_entry (sort keys %aka_hash) {
    my $aka_name; my $aka_time = 0; my $aka_time_temp = 0; my $time_temp = 0;
  
    foreach my $table (@tables) { 
      if ($aka_hash{$aka_entry}{$table}{time}) {
        $time_temp = $aka_hash{$aka_entry}{$table}{time};
        ($time_temp) = $time_temp =~ m/^(\d\d\d\d\-\d\d\-\d\d \d\d)/;
        unless ($time_temp) { $time_temp = '1970-01-01'; }
        if ($time_temp =~ m/\D/) { $time_temp =~ s/\D//g; }
        if ($time_temp > $aka_time_temp) { 
          $aka_time_temp = $time_temp;
          $aka_time = $aka_hash{$aka_entry}{$table}{time}; 
        }
      } # if ($aka_hash{$aka_entry}{$table}{time})
    } # foreach my $table (@tables)
    
    unless ($aka_hash{$aka_entry}{middle}{val}) { 
      unless ($aka_hash{$aka_entry}{first}{val}) { $aka_hash{$aka_entry}{first}{val} = ' '; }
      unless ($aka_hash{$aka_entry}{last}{val}) { $aka_hash{$aka_entry}{last}{val} = ' '; }
      $aka_name = $aka_hash{$aka_entry}{first}{val} . " " . $aka_hash{$aka_entry}{last}{val};
      $aka_name =~ s/\s+/ /g; 
    } else {
      unless ($aka_hash{$aka_entry}{middle}{val}) { $aka_hash{$aka_entry}{middle}{val} = ''; }
      unless ($aka_hash{$aka_entry}{middle}{val} !~ m/NULL/) { 
        unless ($aka_hash{$aka_entry}{first}{val}) { $aka_hash{$aka_entry}{first}{val} = ' '; }
        unless ($aka_hash{$aka_entry}{last}{val}) { $aka_hash{$aka_entry}{last}{val} = ' '; }
        $aka_name = $aka_hash{$aka_entry}{first}{val} . " " . $aka_hash{$aka_entry}{last}{val}; 
        $aka_name =~ s/\s+/ /g; }
      else {
        $aka_name = $aka_hash{$aka_entry}{first}{val} . " " . $aka_hash{$aka_entry}{middle}{val} . " " . $aka_hash{$aka_entry}{last}{val}; $aka_name =~ s/\s+/ /g; }
    }
    $aka_name =~ s/\s+/ /g; $aka_name =~ s/^\s+//g; $aka_name =~ s/\s+$//g;
    $aka_name =~ s/\//\\\//g;
    if ($aka_name !~ m/NULL/) { 
      $aka_name =~ s/\.//g; $aka_name =~ s/\,//g;
      print "Also_known_as\t \"$aka_name\"\n";
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
      $firstname =~ s/\.//g; $firstname =~ s/\,//g;
      print "First_name\t \"$firstname\"\n";
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
      $middlename =~ s/\.//g; $middlename =~ s/\,//g;
      print "Middle_name\t \"$middlename\"\n";
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
      $lastname =~ s/\.//g; $lastname =~ s/\,//g;
      print "Last_name\t \"$lastname\"\n";
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
    } else { print "ERROR no standardname for $joinkey : $standardname\n"; }
    print "Standard_name\t \"$standardname\"\n";
  }
  unless ($full_name) { $full_name = ''; }
  if ($full_name !~ m/NULL/) {
    $full_name =~ s/\s+/ /g; $full_name =~ s/^\s+//g; $full_name =~ s/\s+$//g;
    print "Full_name\t \"$full_name\"\n";
    push @dates, $timestamp; }
  else { print ERR "ERROR no full_name for $joinkey : $full_name\n"; }
} # sub namePrint	


sub populatePaperHash {
  my $result = $conn->exec( "SELECT * FROM pap_view WHERE pap_verified ~ 'YES';");
  while (my @row = $result->fetchrow) {
    if ($row[0]) { 
      my ($joinkey, $author, $person);
      if ($row[0]) { if ($row[0] =~ m//) { $row[0] =~ s///g; } $joinkey = $row[0]; }
      if ($row[1]) { if ($row[1] =~ m//) { $row[1] =~ s///g; } $author = $row[1]; }
      if ($row[2]) { if ($row[2] =~ m//) { $row[2] =~ s///g; } $person = $row[2]; }
      unless ($person) { $person = ' '; }
      unless ($joinkey) { $joinkey = ' '; }
      $paperHash{$person}{paper}{$joinkey}++; 
    } # if ($row[0])
  } # while (my @row = $result->fetchrow)
  
  $result = $conn->exec( "SELECT * FROM pap_possible WHERE pap_possible IS NOT NULL;");
  while (my @row = $result->fetchrow) {
    if ($row[0]) {
      $row[1] =~ s///g; my $author = $row[1];
      $row[2] =~ s///g; my $person = $row[2];
      if ($author =~ m/^[\-\w\s]+"/) { $author =~ m/^([\-\w\s]+)\"/; $author = $1; }
      $paperHash{$person}{author}{$author}++;
    } # if ($row[0])
  } # while (my @row = $result->fetchrow)
} # sub populatePaperHash

sub paperPrint {
  my $joinkey = shift;
  my %sortingHash = (); my $line;
#   my $result = $conn->exec( "SELECT * FROM two_lineage WHERE joinkey = '$joinkey' AND two_number ~ 'two'; " );
    # changed to add papers to a sorting hash to sort papers.  unnecessary, but
    # tried to keep the old find_diff.pl ;  eventually fixed that to not sort unordered tags instead  2005 07 16
  foreach my $paper (sort keys %{$paperHash{$joinkey}{paper}}) {
    $paper =~ s/\.$//g;					# take out dots at the end that are typos
    if ($paper =~ m/WBPaper/) { 
        # take out .1, .2 for Erratum and In_Book because the model is a hash, so can't xref into it
        # perhaps should dump these through Paper instead of Person, but this will do for now.  
        # .1 and .2 are not paper objects, so linking them to main paper
      if ($paper =~ m/\..*$/) { $paper =~ s/\..*$//g; }	
      $line = "Paper\t \"$paper\"\n"; 
      $sortingHash{$line}++; }
    elsif ($convertToWBPaper{$paper}) {			# convert to WBPaper or print ERROR
        # take out .1, .2 for Erratum and In_Book (see above)
      if ($convertToWBPaper{$paper} =~ m/\..*$/) { $convertToWBPaper{$paper} =~ s/\..*$//g; }
      $line = "Paper\t \"$convertToWBPaper{$paper}\"\n"; 
      $sortingHash{$line}++; }
    else { print STDERR "ERROR No conversion for $paper on $joinkey\n"; }
  } # foreach my $paper (sort keys %{$paperHash{$joinkey}})
  foreach my $line (sort keys %sortingHash) { print $line; }
  foreach my $author (sort keys %{$paperHash{$joinkey}{author}}) {
    $author =~ s/\.//g; $author =~ s/,//g;
    if ($author =~ m/\" Affiliation_address/) { $author =~ s/\" Affiliation_address.*$//g; }
      # 2004 12 29 -- was dumping affiliation address data which is not in the model
    print "Possibly_publishes_as\t \"$author\"\n";
  } # foreach my $paper (sort keys %{$paperHash{$joinkey}})
} # sub paperPrint
  
sub readConvertions {
  my %ignoreHash;	# temporarily ignore list of stuff from Eimear because these WBPapers have been merged with others 
			# and are no longer the correct WBPaper 	2005 05 26
  my $eimearFileToIgnore = '/home/azurebrd/work/parsings/eimear/fixingEimearsPaper2WBPaperTable/Papers_with_only_Person_data.txt';
  open (IN, "<$eimearFileToIgnore") or die "Cannot open $eimearFileToIgnore : $!";
  while (<IN>) {
    my ($ignore) = $_ =~ m/^\"(.*?)\"\t/;
    $ignoreHash{$ignore}++;
  } # while (<IN>)

  my $u = "http://minerva.caltech.edu/~acedb/paper2wbpaper.txt";
  my $ua = LWP::UserAgent->new(timeout => 30); #instantiates a new user agent
  my $request = HTTP::Request->new(GET => $u); #grabs url
  my $response = $ua->request($request);       #checks url, dies if not valid.
  die "Error while getting ", $response->request->uri," -- ", $response->status_line, "\nAborting" unless $response-> is_success;
  my @tmp = split /\n/, $response->content;    #splits by line
  foreach (@tmp) {
    if ($_ =~m/^(.*?)\t(.*?)$/) {
      unless ($ignoreHash{$2}) {		# temporarily ignore list of stuff from Eimear  2005 05 26
      $convertToWBPaper{$1} = $2; } }
      }
} # sub readConvertions

