#!/usr/bin/perl -w
#
# Oneify grouped data.  (two_ tables for full pass)
#
# Choose between Ace and Wbg.  Choose start date and end date (default time of
# script being run).  Choose full listings, or only those that have not been
# confirmed as oneified. (new listings take longer, as it runs through full,
# then checks each for unification).  Pick !
# Shows amount of entries in time range, then for each entry shows the key,
# author entry, names, if grouped (must be), what it's grouped with (if any),
# and if it's been oneified.   Match !
# Shows data in a table for each possible grouped key.  Parses as well as it can
# into firstname, middlename, lastname, lab, oldlab, street, city, state, post,
# country, email, mainphone, labphone, officephone, otherphone, fax.  For each
# line, it shows the type, number of times it matches as such, date it was last
# modified/verified as such (in ace or wbg), the value, and a checkbox to check
# if it's good data or not.  Shows extra lines for each field to enter
# potentially more new data.  Oneify !
# Shows the data that has been chosen for verification.  Confirm !
# Displays counter, which keys have been grouped, then for each table entry
# displays the counter, time of data verification, table name, and data.  Enters
# data to a flatfile /home/postgres/work/authorperson/oneifyfile as well as the
# postgreSQL tables.
#
# Added pgsql interaction.  Created pg tables 
# (/home/postgres/work/authorperson/pgtables/insertmaker.pl) and sequence.  
# 2002 01 24
#
# Minor change in &displayOneifyForm(); to : when reading ace_name, sub out the
# underscores (_) with spaces ( ) to take into account multiple last names in a
# last name that are now being separated with an underscore (_).  2002 01 24
#
# Now reads timestamp, tries to keep latest by taking out non-numbers and doing
# a straight > comparison with the old value.  Passes it along, and rewrote
# tables to have an old_timestamp column for each of the data tables to keep old
# data timestamps  2002 01 25
# 
# Fixed error with &getRecentWbgKeys(); was displaying what was found from 
# wbg_oneified, instead of the wbg_grouped  2002 02 11
#
# Made this cgi to replace grouper.cgi, as the grouping action was taking place
# in person.cgi, making things confusing.  2002 02 25
#
# TODO : change so that when it SELECTS what has been grouped, it checks what has 
# been grouped with that as well, so that it selects all groupings  a = b = c,
# not just a = b, or c = b when looking by a and c.
#
# Update to two-ify.  That is, use two_ tables instead of one_ tables.  two_
# tables have a two_order column for each table type, so when sorting by joinkey
# one can figure out the order in which things belong.  2002 05 23
#
# Add new fields : old_email left_field unable_to_contact  2002 06 12
#
# Added two_comment field.  2002 06 22
#
# Updated &formAceOfWbgDate(); by adding Specify ! button and radio fields of 
# ace and wbg in sets of 50 (vars : ace_num or wbg_num).  Added &getSpecify(); 
# to &pgShowSpecificAce($ace_num); or &pgShowSpecificWbg($wbg_num); to display
# list to Match ! by sets of 50.  2002 07 06
#
# Added two_privacy field.  2002 07 06
#
# Added two_aka_firstname two_aka_middlename two_aka_lastname two_apu_firstname
# two_apu_middlename two_apu_lastname two_webpage fields.  2002 07 15

 
use strict;
use CGI;
use Fcntl;
use Pg;
use Jex;

my $query = new CGI;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my @ace_tables = qw(ace_author ace_name ace_lab ace_oldlab ace_address ace_email ace_phone ace_fax);
my @wbg_tables = qw(wbg_title wbg_firstname wbg_middlename wbg_lastname wbg_suffix wbg_street wbg_city wbg_state wbg_post wbg_country wbg_mainphone wbg_labphone wbg_officephone wbg_fax wbg_email);

my $frontpage = 1;			# show the front page on first load
my $start_date = '2002-01-13';		# date to compare against to check recency
my $end_date = &getDate();		# last date to check, default to now

my %grouped_keys;			# keys in the grouped with table for the main key

&printHeader('Oneifier Form');
&printLinks();

&process();		# check button action and do as appropriate
&display();		# check display flags and show appropriate page

&printFooter();

sub display {
  if ($frontpage) {
    &formAceOrWbgDate();		# make the frontpage
  } # if ($frontpage) 
} # sub display

sub process {
  my $action;
  unless ($action = $query->param('action') ) { 
    $action = 'none';
  }

  if ($action eq 'Pick !') {
    $frontpage = 0;
    &getPick();				# make list by picked paramters
  } # if ($action eq 'Pick !')

  elsif ($action eq 'Specify !') {
    $frontpage = 0;
    &getSpecify();			# make list by specified paramters
  } # if ($action eq 'Specify !')

  elsif ($action eq 'Match !') {
    $frontpage = 0;
    &match();				# get stuff to select among to make groups
  } # if ($action eq 'Match !')

  elsif ($action eq 'Oneify !') {
    $frontpage = 0;
    &twoify();				# make groupings depending on clicked and data
  } # elsif ($action eq 'Oneify !')

  elsif ($action eq 'Confirm !') {
    $frontpage = 0;
    &confirm();				# make groupings depending on clicked and data
  } # elsif ($action eq 'Confirm !')

  elsif ($action eq 'none') { 1; }

  else { print "NOT A VALID ACTION : $action, contact the author.<BR>\n"; }
} # sub process

#### pick ####

sub getPick {
  my $oop;
  my ($ace_list, $wbg_list);
  my $full_or_new = 'full';
  if ( $query->param('full_or_new') ) {	# if full_or_new, overwrite default one
    $oop = $query->param('full_or_new');
    $full_or_new = &untaint($oop);
  } # if ( $query->param('full_or_new') )
  if ( $query->param('start_date') ) {	# if start_date, overwrite default one
    $oop = $query->param('start_date');
    $start_date = &untaint($oop);
  } # if ( $query->param('start_date') )
  if ( $query->param('end_date') ) {	# if end_date, overwrite default one
    $oop = $query->param('end_date');
    $end_date = &untaint($oop);
  } # if ( $query->param('end_date') )
  if ( $query->param('ace_list') ) { 	# if ace chosen, do all for ace
    $oop = $query->param('ace_list');
    $ace_list = &untaint($oop);
    &pgShowRecentAce($full_or_new);	# currently stored in depreciated DISPLAY section
  } # if ( $query->param('ace_list') )
  if ( $query->param('wbg_list') ) { 	# if wbg chosen, do all for wbg
    $oop = $query->param('wbg_list');
    $wbg_list = &untaint($oop);
    &pgShowRecentWbg($full_or_new);	# currently stored in depreciated DISPLAY section
  } # if ( $query->param('wbg_list') )
} # sub getPick

sub getSpecify {		# new sub to select in groups of 50 by ace or wbg to speed up loading
  my $oop;
  if ( $query->param('ace_num') ) {	# get the ace if an ace
    $oop = $query->param('ace_num');
    my $ace_num = &untaint($oop);
    &pgShowSpecificAce($ace_num);
  } # if ( $query->param('ace_num') )
  if ( $query->param('wbg_num') ) {	# get the wbg if a wbg
    $oop = $query->param('wbg_num');
    my $wbg_num = &untaint($oop);
    &pgShowSpecificWbg($wbg_num);
  } # if ( $query->param('wbg_num') )
} # sub getSpecify

#### pick ####


#### match ####

sub match {				# make comparisons to present to make groups
  my $oop;
  if ( $query->param('ace_key') ) { 
    $oop = $query->param('ace_key');
    my $main_ace_key = &untaint($oop);
    &matchAce($main_ace_key);		# find possible groupings to ace key and display them
  } # if ( $query->param('ace_key') )
  if ( $query->param('wbg_key') ) { 
    $oop = $query->param('wbg_key');
    my $main_wbg_key = &untaint($oop);
    &matchWbg($main_wbg_key);		# find possible groupings to wbg key and display them
  } # if ( $query->param('wbg_key') )
} # sub match

  # WBG #
sub matchWbg {				# make matches for main ace key, show in form
  my $main_wbg_key = shift;
  &printFormOpen();
  &printOneifyButton();

  $grouped_keys{$main_wbg_key}++;	# add main key to list of keys to put in fields for unifying
  &getWbgGroupedWith();			# get the other keys from the groupedwith table
  foreach my $wbg_key (sort keys %grouped_keys) {	# for each of the keys, display the data
    if ($wbg_key =~ m/^ace/) {
      &displayAceDataFromKey($wbg_key);	# diplay ace data if the wbg matcher is an ace key
    } elsif ($wbg_key =~ m/^wbg/) {
      &displayWbgDataFromKey($wbg_key);	# diplay wbg data if the wbg matcher is an ace key
    } else { print "<font color=blue>ERROR : No middle name matched for $wbg_key</font><BR>\n"; }
  } # foreach my $ace_key (sort keys %grouped_keys)
  &displayOneifyForm();			# display the form with fields for data for all keys
  &printOneifyButton();
  &printFormClose();
} # sub matchWbg

sub getWbgGroupedWith {			# get the other keys from the groupedwith table
  if ( $query->param('grouped_keys') ) { 	# if grouped keys
    my $oop = $query->param('grouped_keys');	# get the grouped keys
    my $grouped_keys = &untaint($oop);	# untaint them
    my @grouped_keys = split/\t/, $grouped_keys;	# put in array
    foreach (@grouped_keys) { $grouped_keys{$_}++; }
  } # if ( $query->param('grouped_keys') )
} # sub getWbgGroupedWith
  # WBG #

  # ACE #
sub matchAce {				# make matches for main ace key, show in form
  my $main_ace_key = shift;
  &printFormOpen();
  &printOneifyButton();

  $grouped_keys{$main_ace_key}++;	# add main key to list of keys to put in fields for unifying
  &getAceGroupedWith();			# get the other keys from the groupedwith table
  foreach my $ace_key (sort keys %grouped_keys) {	# for each of the keys, display the data
    if ($ace_key =~ m/^ace/) {
      &displayAceDataFromKey($ace_key);	# diplay ace data if the ace matcher is an ace key
    } elsif ($ace_key =~ m/^wbg/) {
      &displayWbgDataFromKey($ace_key);	# diplay wbg data if the ace matcher is an wbg key
    } else { print "<font color=blue>ERROR : No middle name matched for $ace_key</font><BR>\n"; }
  } # foreach my $ace_key (sort keys %grouped_keys)
  &displayOneifyForm();			# display the form with fields for data for all keys
  &printOneifyButton();
  &printFormClose();
} # sub matchAce

sub getAceGroupedWith {
  if ( $query->param('grouped_keys') ) { 	# if grouped keys
    my $oop = $query->param('grouped_keys');	# get the grouped keys
    my $grouped_keys = &untaint($oop);	# untaint them
    my @grouped_keys = split/\t/, $grouped_keys;	# put in array
    foreach (@grouped_keys) { $grouped_keys{$_}++; }
  } # if ( $query->param('grouped_keys') )
} # sub getAceGroupedWith
  # ACE #

  # twoify form #
sub displayOneifyForm {
    # data hashes for output
  my (%firstname, %middlename, %lastname, %title);
  my (%lab, %oldlab);
  my (%city, %state, %post, %street, %country);
  my (%email, %mainphone, %labphone, %officephone, %otherphone, %fax);
    # data hashes for timestamps
  my (%wbg_time, %ace_author_time, %ace_name_time, %ace_lab_time, %ace_oldlab_time, %ace_address_time,
      %ace_email_time, %ace_phone_time, %ace_fax_time);

  print "<TABLE border=1 cellspacing=2>\n";
  foreach my $grouped_key (sort keys %grouped_keys) {	# for each grouped key value
    if ($grouped_key =~ m/^ace/) {			# for the ace keys
      # my @ace_tables = qw(ace_author ace_name ace_lab ace_oldlab ace_address ace_email ace_phone ace_fax);
      foreach my $ace_table (@ace_tables) {		# look at each of the tables
        my $result = $conn->exec( "SELECT * FROM $ace_table WHERE joinkey = '$grouped_key';" );
							# get the table data
        while (my @row = $result->fetchrow) {		# for each line (multiple possible)
          if ($row[1]) {				# if has data
            $row[1] =~ s/"//g;
            my ($first, $mid, $last);			# initialize variables in parsings
            my ($city, $state, $post, $street, $country);
            my ($name_time, $address_time);		# timestamps

	      # parse as appropriate
            if ($ace_table eq 'ace_author') {
              ($last, $first, $mid) = $row[1] =~ m/^([A-Z][a-z]+) ([A-Z])([A-Z]*)$/;

            } elsif ($ace_table eq 'ace_name') {
              ($first, $mid, $last) = $row[1] =~ m/^(\S+) (.*?) ?(\S+)$/;
              if ($first) { 
                unless ($ace_name_time{$first}) {	# if no time data
                  $ace_name_time{$first} = $row[2]; 	# put time data
                } else { # unless ($ace_name_time{$first})	# if already time data
							# get time in format to compare with >
                  my $oldtime = $ace_name_time{$first}; $oldtime =~ s/[- :]//g;
                  my $newtime = $row[2]; $newtime =~ s/[- :]//g;
                  if ($newtime > $oldtime) { $ace_name_time{$first} = $row[2]; }
							# if more recent, replace
                } # else # unless ($ace_name_time{$first})
                $firstname{$first}++; 			# add data to hash
              } # if ($first) 
              if ($mid) { 
                unless ($ace_name_time{$mid}) {		# if no time data
                  $ace_name_time{$mid} = $row[2]; 	# put time data
                } else {
                  my $oldtime = $ace_name_time{$mid}; $oldtime =~ s/[- :]//g;
                  my $newtime = $row[2]; $newtime =~ s/[- :]//g;
                  if ($newtime > $oldtime) { $ace_name_time{$mid} = $row[2]; }
							# if more recent, replace
                } # else # unless ($ace_name_time{$mid})
                $middlename{$mid}++; 
              } # if ($mid)
              if ($last) { 
                $last =~ s/_/ /g; 
                unless ($ace_name_time{$last}) {	# if no time data
                  $ace_name_time{$last} = $row[2]; 	# put time data
                } else {
                  my $oldtime = $ace_name_time{$last}; $oldtime =~ s/[- :]//g;
                  my $newtime = $row[2]; $newtime =~ s/[- :]//g;
                  if ($newtime > $oldtime) { $ace_name_time{$last} = $row[2]; }
							# if more recent, replace
                } # else # unless ($ace_name_time{$last})
                $lastname{$last}++; 
              } # if ($last)

            } elsif ($ace_table eq 'ace_lab') {
              unless ($ace_lab_time{$row[1]}) {		# if no time data
                $ace_lab_time{$row[1]} = $row[2]; 		# put time data
              } else {					# if more recent, replace
                my $oldtime = $ace_lab_time{$row[1]}; $oldtime =~ s/[- :]//g;
                my $newtime = $row[2]; $newtime =~ s/[- :]//g;
                if ($newtime > $oldtime) { $ace_lab_time{$row[1]} = $row[2]; }
              } # else # unless ($ace_lab_time{$row[1]})
              $lab{$row[1]}++;
            } elsif ($ace_table eq 'ace_oldlab') {
              unless ($ace_oldlab_time{$row[1]}) {		# if no time data
                $ace_oldlab_time{$row[1]} = $row[2]; 		# put time data
              } else {					# if more recent, replace
                my $oldtime = $ace_oldlab_time{$row[1]}; $oldtime =~ s/[- :]//g;
                my $newtime = $row[2]; $newtime =~ s/[- :]//g;
                if ($newtime > $oldtime) { $ace_oldlab_time{$row[1]} = $row[2]; }
              } # else # unless ($ace_oldlab_time{$row[1]})
              $oldlab{$row[1]}++;

            } elsif ($ace_table eq 'ace_address') {
              if ($row[1] =~ m/^(.*?), ([A-Z]{2}) (.*)$/) {	# looks like multi
                ($city, $state, $post) = $row[1] =~ m/^(.*?), ([A-Z]{2}) (.*)$/;
              } elsif ($row[1] =~ m/\s/) {			# looks like street
                if ($row[1] =~ m/^United States/i) { $country = $row[1]; }
                elsif ($row[1] =~ m/^Great Britain/i) { $country = $row[1]; }
                elsif ($row[1] =~ m/^United Kingdom/i) { $country = $row[1]; }
                else { $street = $row[1]; }
              } else { $country = $row[1]; }			# looks like country
              if ($city) { 
                unless ($ace_address_time{$city}) {	# if no time data
                  $ace_address_time{$city} = $row[2]; 	# put time data
                } else { 				# if more recent, replace
                  my $oldtime = $ace_address_time{$row[1]}; $oldtime =~ s/[- :]//g;
                  my $newtime = $row[2]; $newtime =~ s/[- :]//g;
                  if ($newtime > $oldtime) { $ace_address_time{$city} = $row[2]; }
                } # else # unless ($ace_address_time{$city})
                $city{$city}++; 			# add data to hash
              } # if ($city) 
              if ($state) { 
                unless ($ace_address_time{$state}) {	# if no time data
                  $ace_address_time{$state} = $row[2]; 	# put time data
                } else { 				# if more recent, replace
                  my $oldtime = $ace_address_time{$row[1]}; $oldtime =~ s/[- :]//g;
                  my $newtime = $row[2]; $newtime =~ s/[- :]//g;
                  if ($newtime > $oldtime) { $ace_address_time{$state} = $row[2]; }
                } # else # unless ($ace_address_time{$state})
                $state{$state}++; 			# add data to hash
              } # if ($state) 
              if ($post) { 
                unless ($ace_address_time{$post}) {	# if no time data
                  $ace_address_time{$post} = $row[2]; 	# put time data
                } else { 				# if more recent, replace
                  my $oldtime = $ace_address_time{$row[1]}; $oldtime =~ s/[- :]//g;
                  my $newtime = $row[2]; $newtime =~ s/[- :]//g;
                  if ($newtime > $oldtime) { $ace_address_time{$post} = $row[2]; }
                } # else # unless ($ace_address_time{$post})
                $post{$post}++; 			# add data to hash
              } # if ($post) 
              if ($street) { 
                unless ($ace_address_time{$street}) {	# if no time data
                  $ace_address_time{$street} = $row[2]; 	# put time data
                } else { 				# if more recent, replace
                  my $oldtime = $ace_address_time{$row[1]}; $oldtime =~ s/[- :]//g;
                  my $newtime = $row[2]; $newtime =~ s/[- :]//g;
                  if ($newtime > $oldtime) { $ace_address_time{$street} = $row[2]; }
                } # else # unless ($ace_address_time{$street})
                $street{$street}++; 			# add data to hash
              } # if ($street) 
              if ($country) { 
                unless ($ace_address_time{$country}) {	# if no time data
                  $ace_address_time{$country} = $row[2]; 	# put time data
                } else { 				# if more recent, replace
                  my $oldtime = $ace_address_time{$row[1]}; $oldtime =~ s/[- :]//g;
                  my $newtime = $row[2]; $newtime =~ s/[- :]//g;
                  if ($newtime > $oldtime) { $ace_address_time{$country} = $row[2]; }
                } # else # unless ($ace_address_time{$country})
                $country{$country}++; 			# add data to hash
              } # if ($country) 

            } elsif ($ace_table eq 'ace_email') {
              unless ($ace_email_time{$row[1]}) {		# if no time data
                $ace_email_time{$row[1]} = $row[2]; 		# put time data
              } else {					# if more recent, replace
                my $oldtime = $ace_email_time{$row[1]}; $oldtime =~ s/[- :]//g;
                my $newtime = $row[2]; $newtime =~ s/[- :]//g;
                if ($newtime > $oldtime) { $ace_email_time{$row[1]} = $row[2]; }
              } # else # unless ($ace_email_time{$row[1]})
              $email{$row[1]}++;
            } elsif ($ace_table eq 'ace_phone') {
              unless ($ace_phone_time{$row[1]}) {		# if no time data
                $ace_phone_time{$row[1]} = $row[2]; 		# put time data
              } else {					# if more recent, replace
                my $oldtime = $ace_phone_time{$row[1]}; $oldtime =~ s/[- :]//g;
                my $newtime = $row[2]; $newtime =~ s/[- :]//g;
                if ($newtime > $oldtime) { $ace_phone_time{$row[1]} = $row[2]; }
              } # else # unless ($ace_phone_time{$row[1]})
              $otherphone{$row[1]}++;
            } elsif ($ace_table eq 'ace_fax') {
              unless ($ace_fax_time{$row[1]}) {		# if no time data
                $ace_fax_time{$row[1]} = $row[2]; 		# put time data
              } else {					# if more recent, replace
                my $oldtime = $ace_fax_time{$row[1]}; $oldtime =~ s/[- :]//g;
                my $newtime = $row[2]; $newtime =~ s/[- :]//g;
                if ($newtime > $oldtime) { $ace_fax_time{$row[1]} = $row[2]; }
              } # else # unless ($ace_fax_time{$row[1]})
              $fax{$row[1]}++;
            } else { print "<font color=blue>ERROR : $ace_table not accounted for</font><BR>\n"; }

          } # if ($row[1])
        } # while (@row = $result->fetchrow)
      } # foreach (@ace_tables)

    } elsif ($grouped_key =~ m/^wbg/) {			# for the wbg keys
      # my @wbg_tables = qw(wbg_title wbg_firstname wbg_middlename wbg_lastname wbg_suffix wbg_street wbg_city wbg_state wbg_post wbg_country wbg_mainphone wbg_labphone wbg_officephone wbg_fax wbg_email);
      foreach my $wbg_table (@wbg_tables) {		# look at each of the tables
        my $result = $conn->exec( "SELECT * FROM $wbg_table WHERE joinkey = '$grouped_key';" );
        while (my @row = $result->fetchrow) {		# for each line (multiple possible)
          if ($row[1]) {				# if has data put in appropriate hash
            $row[1] =~ s/"//g;
            if ($wbg_table eq 'wbg_title') { $title{$row[1]}++; }
            elsif ($wbg_table eq 'wbg_firstname') { 
              unless ($ace_name_time{$row[1]}) {	# if no time data
                $ace_name_time{$row[1]} = $row[2]; 	# put time data
              } else {					# if more recent, replace
							# get time in format to compare with >
                my $oldtime = $ace_name_time{$row[1]}; $oldtime =~ s/[- :]//g;
                my $newtime = $row[2]; $newtime =~ s/[- :]//g;
							# if more recent, replace
                if ($newtime > $oldtime) { $ace_name_time{$row[1]} = $row[2]; }
              } # else # unless ($ace_name_time{$row[1]})
              $firstname{$row[1]}++; 
            } elsif ($wbg_table eq 'wbg_middlename') { 
              unless ($ace_name_time{$row[1]}) {	# if no time data
                $ace_name_time{$row[1]} = $row[2]; 	# put time data
              } else {					# if more recent, replace
                my $oldtime = $ace_name_time{$row[1]}; $oldtime =~ s/[- :]//g;
                my $newtime = $row[2]; $newtime =~ s/[- :]//g;
                if ($newtime > $oldtime) { $ace_name_time{$row[1]} = $row[2]; }
              } # else # unless ($ace_name_time{$row[1]})
              $middlename{$row[1]}++; 
            } elsif ($wbg_table eq 'wbg_lastname') { 
              unless ($ace_name_time{$row[1]}) {	# if no time data
                $ace_name_time{$row[1]} = $row[2]; 	# put time data
              } else {					# if more recent, replace
                my $oldtime = $ace_name_time{$row[1]}; $oldtime =~ s/[- :]//g;
                my $newtime = $row[2]; $newtime =~ s/[- :]//g;
                if ($newtime > $oldtime) { $ace_name_time{$row[1]} = $row[2]; }
              } # else # unless ($ace_name_time{$row[1]})
              $lastname{$row[1]}++; 
            } elsif ($wbg_table eq 'wbg_street') { 
              unless ($ace_address_time{$row[1]}) {	# if no time data
                $ace_address_time{$row[1]} = $row[2]; 	# put time data
              } else {					# if more recent, replace
                my $oldtime = $ace_address_time{$row[1]}; $oldtime =~ s/[- :]//g;
                my $newtime = $row[2]; $newtime =~ s/[- :]//g;
                if ($newtime > $oldtime) { $ace_address_time{$row[1]} = $row[2]; }
              } # else # unless ($ace_address_time{$row[1]})
              $street{$row[1]}++; 
            } elsif ($wbg_table eq 'wbg_city') { 
              unless ($ace_address_time{$row[1]}) {	# if no time data
                $ace_address_time{$row[1]} = $row[2]; 	# put time data
              } else {					# if more recent, replace
                my $oldtime = $ace_address_time{$row[1]}; $oldtime =~ s/[- :]//g;
                my $newtime = $row[2]; $newtime =~ s/[- :]//g;
                if ($newtime > $oldtime) { $ace_address_time{$row[1]} = $row[2]; }
              } # else # unless ($ace_address_time{$row[1]})
              $city{$row[1]}++; 
            } elsif ($wbg_table eq 'wbg_state') { 
              unless ($ace_address_time{$row[1]}) {	# if no time data
                $ace_address_time{$row[1]} = $row[2]; 	# put time data
              } else {					# if more recent, replace
                my $oldtime = $ace_address_time{$row[1]}; $oldtime =~ s/[- :]//g;
                my $newtime = $row[2]; $newtime =~ s/[- :]//g;
                if ($newtime > $oldtime) { $ace_address_time{$row[1]} = $row[2]; }
              } # else # unless ($ace_address_time{$row[1]})
              $state{$row[1]}++; 
            } elsif ($wbg_table eq 'wbg_post') { 
              unless ($ace_address_time{$row[1]}) {	# if no time data
                $ace_address_time{$row[1]} = $row[2]; 	# put time data
              } else {					# if more recent, replace
                my $oldtime = $ace_address_time{$row[1]}; $oldtime =~ s/[- :]//g;
                my $newtime = $row[2]; $newtime =~ s/[- :]//g;
                if ($newtime > $oldtime) { $ace_address_time{$row[1]} = $row[2]; }
              } # else # unless ($ace_address_time{$row[1]})
              $post{$row[1]}++; 
            } elsif ($wbg_table eq 'wbg_country') { 
              unless ($ace_address_time{$row[1]}) {	# if no time data
                $ace_address_time{$row[1]} = $row[2]; 	# put time data
              } else {					# if more recent, replace
                my $oldtime = $ace_address_time{$row[1]}; $oldtime =~ s/[- :]//g;
                my $newtime = $row[2]; $newtime =~ s/[- :]//g;
                if ($newtime > $oldtime) { $ace_address_time{$row[1]} = $row[2]; }
              } # else # unless ($ace_address_time{$row[1]})
              $country{$row[1]}++; 
            } elsif ($wbg_table eq 'wbg_mainphone') { 
              unless ($wbg_time{$row[1]}) {	# if no time data
                $wbg_time{$row[1]} = $row[2]; 	# put time data
              } else {					# if more recent, replace
                my $oldtime = $wbg_time{$row[1]}; $oldtime =~ s/[- :]//g;
                my $newtime = $row[2]; $newtime =~ s/[- :]//g;
                if ($newtime > $oldtime) { $wbg_time{$row[1]} = $row[2]; }
              } # else # unless ($wbg_time{$row[1]})
              $mainphone{$row[1]}++; 
            } elsif ($wbg_table eq 'wbg_labphone') { 
              unless ($wbg_time{$row[1]}) {	# if no time data
                $wbg_time{$row[1]} = $row[2]; 	# put time data
              } else {					# if more recent, replace
                my $oldtime = $wbg_time{$row[1]}; $oldtime =~ s/[- :]//g;
                my $newtime = $row[2]; $newtime =~ s/[- :]//g;
                if ($newtime > $oldtime) { $wbg_time{$row[1]} = $row[2]; }
              } # else # unless ($wbg_time{$row[1]})
              $labphone{$row[1]}++; 
            } elsif ($wbg_table eq 'wbg_officephone') { 
              unless ($wbg_time{$row[1]}) {	# if no time data
                $wbg_time{$row[1]} = $row[2]; 	# put time data
              } else {					# if more recent, replace
                my $oldtime = $wbg_time{$row[1]}; $oldtime =~ s/[- :]//g;
                my $newtime = $row[2]; $newtime =~ s/[- :]//g;
                if ($newtime > $oldtime) { $wbg_time{$row[1]} = $row[2]; }
              } # else # unless ($wbg_time{$row[1]})
              $officephone{$row[1]}++; 
            } elsif ($wbg_table eq 'wbg_fax') { 
              unless ($ace_fax_time{$row[1]}) {	# if no time data
                $ace_fax_time{$row[1]} = $row[2]; 	# put time data
              } else {					# if more recent, replace
                if ($ace_fax_time{$row[1]} > $row[2]) { $ace_fax_time{$row[1]} = $row[2]; }
                my $oldtime = $ace_fax_time{$row[1]}; $oldtime =~ s/[- :]//g;
                my $newtime = $row[2]; $newtime =~ s/[- :]//g;
                if ($newtime > $oldtime) { $ace_fax_time{$row[1]} = $row[2]; }
              } # else # unless ($ace_fax_time{$row[1]})
              $fax{$row[1]}++; 
            } elsif ($wbg_table eq 'wbg_email') { 
              unless ($ace_email_time{$row[1]}) {	# if no time data
                $ace_email_time{$row[1]} = $row[2]; 	# put time data
              } else {					# if more recent, replace
                my $oldtime = $ace_email_time{$row[1]}; $oldtime =~ s/[- :]//g;
                my $newtime = $row[2]; $newtime =~ s/[- :]//g;
                if ($newtime > $oldtime) { $ace_email_time{$row[1]} = $row[2]; }
              } # else # unless ($ace_email_time{$row[1]})
              $email{$row[1]}++; 
            } else { print "<font color=blue>ERROR : $wbg_table not accounted for</font><BR>\n"; }
          } # if ($row[1])
        } # while (@row = $result->fetchrow)
      } # foreach (@wbg_tables)

    } else { 1; }
  } # foreach my $grouped_key (sort keys %grouped_keys)

    # the two_tables in pgsql, here the tags to display the html fields
  my @two_fields = qw( firstname middlename lastname lab oldlab street city state post country email old_email mainphone labphone officephone otherphone fax left_field unable_to_contact privacy aka_firstname aka_middlename aka_lastname apu_firstname apu_middlename apu_lastname webpage );

  my $field_counter = '0';			# we start with no fields to pass for the cgi to read
  foreach (sort keys %firstname) {		# output the firstname data
    $field_counter++;				# another field, add to counter
    print "<TR><TD>FIRSTNAME</TD><TD>$firstname{$_}</TD><TD><INPUT NAME=\"time_$field_counter\" ";
    print "VALUE=\"$ace_name_time{$_}\" SIZE=25></TD><TD><INPUT NAME=\"val_$field_counter\" ";
						# pass timestamp by counter
    print "VALUE=\"$_\" SIZE=55></TD><TD><INPUT NAME=\"check_$field_counter\" TYPE=\"checkbox\" ";
						# pass value by counter
    print "VALUE=\"yes\"</TD></TR>\n";		# pass whether it's checked to read value if so
    print "<INPUT TYPE=\"HIDDEN\" NAME=\"type_$field_counter\" VALUE=\"firstname\">\n";
						# pass the type of data by counter
  } # foreach (sort keys %firstname)
  my $name = shift @two_fields;			# get the type to print extra blank fields
  $field_counter = &makeExtraFields($name, $field_counter, 1);
					# make n+1 extra fields, add up counter and get back value 
    # same thing for all the other fields / hashes
  foreach (sort keys %middlename) {
    $field_counter++;
    print "<TR><TD>MIDDLENAME</TD><TD>$middlename{$_}</TD><TD><INPUT NAME=\"time_$field_counter\" ";
    print "VALUE=\"$ace_name_time{$_}\" SIZE=25></TD><TD><INPUT NAME=\"val_$field_counter\" ";
    print "VALUE=\"$_\" SIZE=55></TD><TD><INPUT NAME=\"check_$field_counter\" TYPE=\"checkbox\" ";
    print "VALUE=\"yes\"</TD></TR>\n";
    print "<INPUT TYPE=\"HIDDEN\" NAME=\"type_$field_counter\" VALUE=\"middlename\">\n";
  } # foreach (sort keys %middlename)
  $name = shift @two_fields;
  $field_counter = &makeExtraFields($name, $field_counter, 1);
  foreach (sort keys %lastname) {
    $field_counter++;
    print "<TR><TD>LASTNAME</TD><TD>$lastname{$_}</TD><TD><INPUT NAME=\"time_$field_counter\" ";
    print "VALUE=\"$ace_name_time{$_}\" SIZE=25></TD><TD><INPUT NAME=\"val_$field_counter\" ";
    print "VALUE=\"$_\" SIZE=55></TD><TD><INPUT NAME=\"check_$field_counter\" TYPE=\"checkbox\" ";
    print "VALUE=\"yes\"</TD></TR>\n";
    print "<INPUT TYPE=\"HIDDEN\" NAME=\"type_$field_counter\" VALUE=\"lastname\">\n";
  } # foreach (sort keys %lastname)
  $name = shift @two_fields;
  $field_counter = &makeExtraFields($name, $field_counter, 1);
  foreach (sort keys %lab) {
    $field_counter++;
    print "<TR><TD>LAB</TD><TD>$lab{$_}</TD><TD><INPUT NAME=\"time_$field_counter\" ";
    print "VALUE=\"$ace_lab_time{$_}\" SIZE=25></TD><TD><INPUT NAME=\"val_$field_counter\" ";
    print "VALUE=\"$_\" SIZE=55></TD><TD><INPUT NAME=\"check_$field_counter\" TYPE=\"checkbox\" ";
    print "VALUE=\"yes\"</TD></TR>\n";
    print "<INPUT TYPE=\"HIDDEN\" NAME=\"type_$field_counter\" VALUE=\"lab\">\n";
  } # foreach (sort keys %lab)
  $name = shift @two_fields;
  $field_counter = &makeExtraFields($name, $field_counter, 1);
  foreach (sort keys %oldlab) {
    $field_counter++;
    print "<TR><TD>OLD LAB</TD><TD>$oldlab{$_}</TD><TD><INPUT NAME=\"time_$field_counter\" ";
    print "VALUE=\"$ace_oldlab_time{$_}\" SIZE=25></TD><TD><INPUT NAME=\"val_$field_counter\" ";
    print "VALUE=\"$_\" SIZE=55></TD><TD><INPUT NAME=\"check_$field_counter\" TYPE=\"checkbox\" ";
    print "VALUE=\"yes\"</TD></TR>\n";
    print "<INPUT TYPE=\"HIDDEN\" NAME=\"type_$field_counter\" VALUE=\"oldlab\">\n";
  } # foreach (sort keys %oldlab)
  $name = shift @two_fields;
  $field_counter = &makeExtraFields($name, $field_counter, 1);
  foreach (sort keys %street) {
    $field_counter++;
    print "<TR><TD>STREET</TD><TD>$street{$_}</TD><TD><INPUT NAME=\"time_$field_counter\" ";
    print "VALUE=\"$ace_address_time{$_}\" SIZE=25></TD><TD><INPUT NAME=\"val_$field_counter\" ";
    print "VALUE=\"$_\" SIZE=55></TD><TD><INPUT NAME=\"check_$field_counter\" TYPE=\"checkbox\" ";
    print "VALUE=\"yes\"</TD></TR>\n";
    print "<INPUT TYPE=\"HIDDEN\" NAME=\"type_$field_counter\" VALUE=\"street\">\n";
  } # foreach (sort keys %street)
  $name = shift @two_fields;
  $field_counter = &makeExtraFields($name, $field_counter, 3);
  foreach (sort keys %city) {
    $field_counter++;
    print "<TR><TD>CITY</TD><TD>$city{$_}</TD><TD><INPUT NAME=\"time_$field_counter\" ";
    print "VALUE=\"$ace_address_time{$_}\" SIZE=25></TD><TD><INPUT NAME=\"val_$field_counter\" ";
    print "VALUE=\"$_\" SIZE=55></TD><TD><INPUT NAME=\"check_$field_counter\" TYPE=\"checkbox\" ";
    print "VALUE=\"yes\"</TD></TR>\n";
    print "<INPUT TYPE=\"HIDDEN\" NAME=\"type_$field_counter\" VALUE=\"city\">\n";
  } # foreach (sort keys %city)
  $name = shift @two_fields;
  $field_counter = &makeExtraFields($name, $field_counter, 1);
  foreach (sort keys %state) {
    $field_counter++;
    print "<TR><TD>STATE</TD><TD>$state{$_}</TD><TD><INPUT NAME=\"time_$field_counter\" ";
    print "VALUE=\"$ace_address_time{$_}\" SIZE=25></TD><TD><INPUT NAME=\"val_$field_counter\" ";
    print "VALUE=\"$_\" SIZE=55></TD><TD><INPUT NAME=\"check_$field_counter\" TYPE=\"checkbox\" ";
    print "VALUE=\"yes\"</TD></TR>\n";
    print "<INPUT TYPE=\"HIDDEN\" NAME=\"type_$field_counter\" VALUE=\"state\">\n";
  } # foreach (sort keys %state)
  $name = shift @two_fields;
  $field_counter = &makeExtraFields($name, $field_counter, 1);
  foreach (sort keys %post) {
    $field_counter++;
    print "<TR><TD>POST</TD><TD>$post{$_}</TD><TD><INPUT NAME=\"time_$field_counter\" ";
    print "VALUE=\"$ace_address_time{$_}\" SIZE=25></TD><TD><INPUT NAME=\"val_$field_counter\" ";
    print "VALUE=\"$_\" SIZE=55></TD><TD><INPUT NAME=\"check_$field_counter\" TYPE=\"checkbox\" ";
    print "VALUE=\"yes\"</TD></TR>\n";
    print "<INPUT TYPE=\"HIDDEN\" NAME=\"type_$field_counter\" VALUE=\"post\">\n";
  } # foreach (sort keys %post)
  $name = shift @two_fields;
  $field_counter = &makeExtraFields($name, $field_counter, 1);
  foreach (sort keys %country) {
    $field_counter++;
    print "<TR><TD>COUNTRY</TD><TD>$country{$_}</TD><TD><INPUT NAME=\"time_$field_counter\" ";
    print "VALUE=\"$ace_address_time{$_}\" SIZE=25></TD><TD><INPUT NAME=\"val_$field_counter\" ";
    print "VALUE=\"$_\" SIZE=55></TD><TD><INPUT NAME=\"check_$field_counter\" TYPE=\"checkbox\" ";
    print "VALUE=\"yes\"</TD></TR>\n";
    print "<INPUT TYPE=\"HIDDEN\" NAME=\"type_$field_counter\" VALUE=\"country\">\n";
  } # foreach (sort keys %country)
  $name = shift @two_fields;
  $field_counter = &makeExtraFields($name, $field_counter, 1);
  foreach (sort keys %email) {
    $field_counter++;
    print "<TR><TD>EMAIL</TD><TD>$email{$_}</TD><TD><INPUT NAME=\"time_$field_counter\" ";
    print "VALUE=\"$ace_email_time{$_}\" SIZE=25></TD><TD><INPUT NAME=\"val_$field_counter\" ";
    print "VALUE=\"$_\" SIZE=55></TD><TD><INPUT NAME=\"check_$field_counter\" TYPE=\"checkbox\" ";
    print "VALUE=\"yes\"</TD></TR>\n";
    print "<INPUT TYPE=\"HIDDEN\" NAME=\"type_$field_counter\" VALUE=\"email\">\n";
  } # foreach (sort keys %email)
  $name = shift @two_fields;
  $field_counter = &makeExtraFields($name, $field_counter, 3);
  $name = shift @two_fields;
  $field_counter = &makeExtraFields($name, $field_counter, 2);
  foreach (sort keys %mainphone) {
    $field_counter++;
    print "<TR><TD>MAINPHONE</TD><TD>$mainphone{$_}</TD><TD><INPUT NAME=\"time_$field_counter\" ";
    print "VALUE=\"$wbg_time{$_}\" SIZE=25></TD><TD><INPUT NAME=\"val_$field_counter\" ";
    print "VALUE=\"$_\" SIZE=55></TD><TD><INPUT NAME=\"check_$field_counter\" TYPE=\"checkbox\" ";
    print "VALUE=\"yes\"</TD></TR>\n";
    print "<INPUT TYPE=\"HIDDEN\" NAME=\"type_$field_counter\" VALUE=\"mainphone\">\n";
  } # foreach (sort keys %mainphone)
  $name = shift @two_fields;
  $field_counter = &makeExtraFields($name, $field_counter, 1);
  foreach (sort keys %labphone) {
    $field_counter++;
    print "<TR><TD>LABPHONE</TD><TD>$labphone{$_}</TD><TD><INPUT NAME=\"time_$field_counter\" ";
    print "VALUE=\"$wbg_time{$_}\" SIZE=25></TD><TD><INPUT NAME=\"val_$field_counter\" ";
    print "VALUE=\"$_\" SIZE=55></TD><TD><INPUT NAME=\"check_$field_counter\" TYPE=\"checkbox\" ";
    print "VALUE=\"yes\"</TD></TR>\n";
    print "<INPUT TYPE=\"HIDDEN\" NAME=\"type_$field_counter\" VALUE=\"labphone\">\n";
  } # foreach (sort keys %labphone)
  $name = shift @two_fields;
  $field_counter = &makeExtraFields($name, $field_counter, 1);
  foreach (sort keys %officephone) {
    $field_counter++;
    print "<TR><TD>OFFICEPHONE</TD><TD>$officephone{$_}</TD><TD><INPUT NAME=\"time_$field_counter\" ";
    print "VALUE=\"$wbg_time{$_}\" SIZE=25></TD><TD><INPUT NAME=\"val_$field_counter\" ";
    print "VALUE=\"$_\" SIZE=55></TD><TD><INPUT NAME=\"check_$field_counter\" TYPE=\"checkbox\" ";
    print "VALUE=\"yes\"</TD></TR>\n";
    print "<INPUT TYPE=\"HIDDEN\" NAME=\"type_$field_counter\" VALUE=\"officephone\">\n";
  } # foreach (sort keys %officephone)
  $name = shift @two_fields;
  $field_counter = &makeExtraFields($name, $field_counter, 1);
  foreach (sort keys %otherphone) {
    $field_counter++;
    print "<TR><TD>OTHERPHONE</TD><TD>$otherphone{$_}</TD><TD><INPUT NAME=\"time_$field_counter\" ";
    print "VALUE=\"$ace_phone_time{$_}\" SIZE=25></TD><TD><INPUT NAME=\"val_$field_counter\" ";
    print "VALUE=\"$_\" SIZE=55></TD><TD><INPUT NAME=\"check_$field_counter\" TYPE=\"checkbox\" ";
    print "VALUE=\"yes\"</TD></TR>\n";
    print "<INPUT TYPE=\"HIDDEN\" NAME=\"type_$field_counter\" VALUE=\"otherphone\">\n";
  } # foreach (sort keys %otherphone)
  $name = shift @two_fields;
  $field_counter = &makeExtraFields($name, $field_counter, 1);
  foreach (sort keys %fax) {
    $field_counter++;
    print "<TR><TD>FAX</TD><TD>$fax{$_}</TD><TD><INPUT NAME=\"time_$field_counter\" ";
    print "VALUE=\"$ace_fax_time{$_}\" SIZE=25></TD><TD><INPUT NAME=\"val_$field_counter\" ";
    print "VALUE=\"$_\" SIZE=55></TD><TD><INPUT NAME=\"check_$field_counter\" TYPE=\"checkbox\" ";
    print "VALUE=\"yes\"</TD></TR>\n";
    print "<INPUT TYPE=\"HIDDEN\" NAME=\"type_$field_counter\" VALUE=\"fax\">\n";
  } # foreach (sort keys %fax)
  $name = shift @two_fields;	# fax, part of above
  $field_counter = &makeExtraFields($name, $field_counter, 1);
  $name = shift @two_fields;	# left_field
  $field_counter = &makeExtraFields($name, $field_counter, 1);
  $name = shift @two_fields;	# unable_to_contact
  $field_counter = &makeExtraFields($name, $field_counter, 1);
  $name = shift @two_fields;	# privacy
  $field_counter = &makeExtraFields($name, $field_counter, 1);
  $name = shift @two_fields;	# aka_firstname
  $field_counter = &makeExtraFields($name, $field_counter, 2);
  $name = shift @two_fields;	# aka_middlename
  $field_counter = &makeExtraFields($name, $field_counter, 2);
  $name = shift @two_fields;	# aka_lastname
  $field_counter = &makeExtraFields($name, $field_counter, 2);
  $name = shift @two_fields;	# apu_firstname
  $field_counter = &makeExtraFields($name, $field_counter, 2);
  $name = shift @two_fields;	# apu_middlename
  $field_counter = &makeExtraFields($name, $field_counter, 2);
  $name = shift @two_fields;	# apu_lastname
  $field_counter = &makeExtraFields($name, $field_counter, 2);
  $name = shift @two_fields;	# webpage
  $field_counter = &makeExtraFields($name, $field_counter, 1);
  
    # comment field (single field)
  $field_counter = &makeExtraTextarea('comment', $field_counter, 0);

  my $grouped_keys = join("\t", sort keys %grouped_keys);
						# get the keys that have been grouped
  print "<INPUT TYPE=\"HIDDEN\" NAME=\"grouped_keys\" VALUE=\"$grouped_keys\">\n";
						# pass the grouped keys to the cgi
  print "<INPUT TYPE=\"HIDDEN\" NAME=\"field_counter\" VALUE=\"$field_counter\">\n";
						# pass the number of fields to read through
  print "</TABLE>\n";				# close the table
} # sub displayOneifyForm

sub makeExtraTextarea {
  my ($name, $field_counter, $amount) = @_;	# get the type of field, number of total fields, 
						# amount of new blank fields to make (-1)
  my $field_name = uc($name);			# upcase the name of the field
  for (0 .. $amount) {				# for the amount (+1) make fields
    $field_counter++;				# add up the counter
    print "<TR><TD>$field_name</TD><TD>&nbsp;</TD><TD>&nbsp;";
						# pass the time by counter
    print "</TD><TD><TEXTAREA NAME=\"val_$field_counter\" ";
						# pass the value by counter
    print "ROWS=5 COLS=55></TEXTAREA></TD><TD><INPUT NAME=\"check_$field_counter\" TYPE=\"checkbox\" ";
						# pass the checkbox by counter
    print "VALUE=\"yes\"</TD></TR>\n";
    print "<INPUT TYPE=\"HIDDEN\" NAME=\"type_$field_counter\" VALUE=\"$name\">\n";
						# pass the type by counter
  } # for (0 .. $amount)
  return $field_counter;			# return the counter to get passed here again for next 
} # sub makeExtraTextarea 

sub makeExtraFields {
  my ($name, $field_counter, $amount) = @_;	# get the type of field, number of total fields, 
						# amount of new blank fields to make (-1)
  my $field_name = uc($name);			# upcase the name of the field
  for (0 .. $amount) {				# for the amount (+1) make fields
    $field_counter++;				# add up the counter
    print "<TR><TD>$field_name</TD><TD>&nbsp;</TD><TD><INPUT NAME=\"time_$field_counter\" ";
						# pass the time by counter
    print "VALUE=\"\" SIZE=25></TD><TD><INPUT NAME=\"val_$field_counter\" ";
						# pass the value by counter
    print "VALUE=\"\" SIZE=55></TD><TD><INPUT NAME=\"check_$field_counter\" TYPE=\"checkbox\" ";
						# pass the checkbox by counter
    print "VALUE=\"yes\"</TD></TR>\n";
    print "<INPUT TYPE=\"HIDDEN\" NAME=\"type_$field_counter\" VALUE=\"$name\">\n";
						# pass the type by counter
  } # for (0 .. 2)
  return $field_counter;			# return the counter to get passed here again for next 
} # sub makeExtraFields
  # twoify form #

#### match ####


#### display ####

sub numerically { $a <=> $b }			# sort numerically

sub formAceOrWbgDate {			# make the frontpage
  &printFormOpen();			# original Pick ! by new or old, ace or wbg, by date
  print "<TABLE border=1 cellspacing=2>\n";
  print "<TR><TD>Ace Full</TD><TD><INPUT NAME=\"ace_list\" TYPE=\"checkbox\" VALUE=\"yes\"></TD></TR>\n";
  print "<TR><TD>Wbg Full</TD><TD><INPUT NAME=\"wbg_list\" TYPE=\"checkbox\" VALUE=\"yes\"></TD></TR>\n";
  print "<TR><TD>Start Date</TD><TD><INPUT NAME=\"start_date\" VALUE=\"$start_date\" SIZE=40></TD></TR>\n";
  print "<TR><TD>End Date</TD><TD><INPUT NAME=\"end_date\" VALUE=\"$end_date\" SIZE=40></TD></TR>\n";
  print "<TR>";
  print "<TR><TD><INPUT NAME=\"full_or_new\" TYPE=\"radio\" CHECKED VALUE=\"full\">full</TD>\n";
  print "<TD><INPUT NAME=\"full_or_new\" TYPE=\"radio\" VALUE=\"new\">new</TD></TR>\n";
  print "<TR><TD><INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Pick !\"></TD></TR>";
  print "</TABLE>\n";
  &printFormClose();

  &printFormOpen();			# new Specify show 1800 aces and 1000 wbgs in groups of 50
  print "<TABLE border=1 cellspacing=2>\n";
  my $counter = 1;
  for (my $i = 1; $i<1800; $i = $i+50) {
    if ($counter > 500) { $counter = 1; print "</TR><TR>\n"; }
    $counter += 50;  			# up the counter, must always be less than 500 for display
    my $j = $i + 49;			# j is just i + 49 for display
    print "<TD>Ace $i - $j</TD><TD><INPUT NAME=\"ace_num\" TYPE=\"radio\" VALUE=\"$i\"></TD>\n";
  } # for (my $i = 1; $i<2000; $i = $i+50)
  print "</TR><TR>\n";
  $counter = 1;
  for (my $i = 1; $i<1000; $i = $i+50) {
    if ($counter > 500) { $counter = 1; print "</TR><TR>\n"; }
    $counter += 50;  			# up the counter, must always be less than 500 for display
    my $j = $i + 49;			# j is just i + 49 for display
    print "<TD>Wbg $i - $j</TD><TD><INPUT NAME=\"wbg_num\" TYPE=\"radio\" VALUE=\"$i\"></TD>\n";
  } # for (my $i = 1; $i<1000; $i = $i+50)
  print "<TR><TD><INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Specify !\"></TD></TR>";
  print "</TABLE>\n";
  &printFormClose();
} # sub formAceOrWbgDate

  # WBG
sub pgShowSpecificWbg {		# make a listing and display wbg keys in sets of 50
  my $wbg_num = shift;		# get what number to start from 
  my @recent_wbg;		# array of numbers to use
  for (my $i = $wbg_num; $i < $wbg_num + 50; $i++) { push @recent_wbg, $i; }
  print "<TABLE border=1 cellspacing=2>\n";
  print "<TR><TD>joinkey</TD><TD>author</TD><TD>name</TD><TD>grouped</TD><TD>grouped with</TD><TD>twoified</TD><TD>Match</TD></TR>\n";
  foreach (@recent_wbg) { 
    &printFormOpen();
    my $wbg_key = 'wbg' . $_;
    print "<INPUT TYPE=\"HIDDEN\" NAME=\"wbg_key\" VALUE=\"$wbg_key\">\n";
    print "<TR><TD>$wbg_key</TD>";
    &pgShowHtmlWbgDataFromKey($wbg_key);
    &printMatchButton();
    print "</TR>\n";
    &printFormClose();
  } # foreach (@recent_wbg)
  print "</TABLE>\n";
} # sub pgShowSpecificWbg

sub pgShowRecentWbg {		# make a listing and display wbg keys changed since start_date
  my $full_or_new = shift;
  my @recent_wbg = &getRecentWbgKeys($full_or_new);
  print "<TABLE border=1 cellspacing=2>\n";
  print "<TR><TD>joinkey</TD><TD>author</TD><TD>name</TD><TD>grouped</TD><TD>grouped with</TD><TD>twoified</TD><TD>Match</TD></TR>\n";
  foreach (@recent_wbg) { 
    &printFormOpen();
    my $wbg_key = 'wbg' . $_;
    print "<INPUT TYPE=\"HIDDEN\" NAME=\"wbg_key\" VALUE=\"$wbg_key\">\n";
    print "<TR><TD>$wbg_key</TD>";
    &pgShowHtmlWbgDataFromKey($wbg_key);
    &printMatchButton();
    print "</TR>\n";
    &printFormClose();
  } # foreach (@recent_wbg)
  print "</TABLE>\n";
} # sub pgShowRecentWbg

sub getRecentWbgKeys {		# get wbg keys given date
  my $full_or_new = shift;
  my %recent_wbg;
  my $result = $conn->exec( "SELECT * FROM wbg_grouped WHERE wbg_timestamp > '$start_date' AND wbg_timestamp < '$end_date';" );
  while (my @row = $result->fetchrow) {
    my $push_flag = 1;	# push values by default
    my $wbg_key = $row[0];
    if ($full_or_new eq 'full') { 
      $push_flag = 1;	# if getting all values, push (not needed)
    } elsif ($full_or_new eq 'new') { 
      my $result = $conn->exec( "SELECT * FROM wbg_twoified WHERE joinkey = '$wbg_key';" );
		# this returns a value, but if no entry won't return something 
		# that will loop in the following while loop
      while (my @row = $result->fetchrow) {
        if ($row[1] eq 'YES') { $push_flag = 0; }	# if already twoified under new, don't push
        else { $push_flag = 1; }			# if not already twoified under new, push
      } # while (my @row = $result->fetchrow)
    } else { print "<font color=blue>ERROR : Not a valid choice for full or new</font><BR>\n"; }
    if ($push_flag) {	# if meant to push, push it
      $wbg_key =~ s/^wbg//;
      push @{ $recent_wbg{$wbg_key} }, $row[1];
    } # if ($push_flag)
  } # while (@row = $result->fetchrow)
  print scalar(keys %recent_wbg) . " wbg entries updated between $start_date and $end_date.<BR>\n";
  return sort numerically keys %recent_wbg;	# put in array to show a select number
} # sub getRecentWbgKeys

sub pgShowHtmlWbgDataFromKey {	# show in table form the data from a wbg key
  my $wbg_key = shift;
  my @wbg_html_table = qw(wbg_lastname wbg_firstname);
  foreach my $wbg_table (@wbg_html_table) {	# show the data
    my $result = $conn->exec( "SELECT * FROM $wbg_table WHERE joinkey = '$wbg_key';" );
    print "<TD>";
    while (my @row = $result->fetchrow) {
      if($row[1]) { print "$row[1]<BR>"; }
    } # while (@row = $result->fetchrow)
    print "</TD>";
  } # foreach (@wbg_html_table)
  my $result = $conn->exec( "SELECT * FROM wbg_grouped WHERE joinkey = '$wbg_key';" );
  print "<TD>";
  my @row = $result->fetchrow;
  if($row[1]) { print "$row[1]<BR>"; }
  print "</TD>";

  $result = $conn->exec( "SELECT * FROM wbg_groupedwith WHERE joinkey = '$wbg_key';" );
  print "<TD>";
  my %matches;			# hash of ace and wbg that match this wbg key
  my @to_check;			# array of ace and wbg that need to check
  while (my @row = $result->fetchrow) {	# while there are values
    if ($row[1]) { $matches{$row[1]}++; push @to_check, $row[1]; } 
				# if there's a value, put in matches (so as not to get doubles)
				# and push into @to_check, to shift values and not check twice
  } # while (my @row = $result->fetchrow) 
  foreach (@to_check) {		# foreach value to check
    if ($_ =~ m/ace/) { 	# use ace_groupedwith for ace
      $result = $conn->exec( "SELECT * FROM ace_groupedwith WHERE joinkey = '$_';" );
      while (my @row = $result->fetchrow) { 
        if ($row[1]) { unless($matches{$row[1]}) { $matches{$row[1]}++; push @to_check, $row[1]; } }
				# if value, not an old value, put in hash (to check later so
				# as not to repeat a value, add to array to shift new values
      } # while (my @row = $result->fetchrow) 
    } # if ($_ =~ m/ace/) 
    if ($_ =~ m/wbg/) { 	# use wbg_groupedwith for wbg
      $result = $conn->exec( "SELECT * FROM wbg_groupedwith WHERE joinkey = '$_';" );
      while (my @row = $result->fetchrow) { 
        if ($row[1]) { unless($matches{$row[1]}) { $matches{$row[1]}++; push @to_check, $row[1]; } }
      } # while (my @row = $result->fetchrow) 
    } # if ($_ =~ m/wbg/) 
  } # foreach (@to_check)
  foreach $_ (sort keys %matches) { print "$_<BR>\n"; }
  my $grouped_keys = join("\t", sort keys %matches);
						# get the keys that have been grouped
  print "<INPUT TYPE=\"HIDDEN\" NAME=\"grouped_keys\" VALUE=\"$grouped_keys\">\n";
  print "</TD>";

  $result = $conn->exec( "SELECT * FROM wbg_twoified WHERE joinkey = '$wbg_key';" );
  print "<TD>";
  while (my @row = $result->fetchrow) { if ($row[1]) { print "$row[1]<BR>" } }
  print "</TD>";
} # sub pgShowHtmlWbgDataFromKey
  # WBG 

  # ACE
sub pgShowSpecificAce {		# make a listing and display ace keys in groups of 50
  my $ace_num = shift;		# get what number to start from
  my @recent_ace;		# array of numbers to use
  for (my $i = $ace_num; $i < $ace_num + 50; $i++) { push @recent_ace, $i; }
  print "<TABLE border=1 cellspacing=2>\n";
  print "<TR><TD>joinkey</TD><TD>author</TD><TD>name</TD><TD>grouped</TD><TD>grouped with</TD><TD>twoified</TD><TD>Compare</TD></TR>\n";
  foreach (@recent_ace) { 
    &printFormOpen();
    my $ace_key = 'ace' . $_;
    print "<INPUT TYPE=\"HIDDEN\" NAME=\"ace_key\" VALUE=\"$ace_key\">\n";
    print "<TR><TD>$ace_key</TD>";
    &pgShowHtmlAceDataFromKey($ace_key);
    &printMatchButton();
    print "</TR>\n";
    &printFormClose();
  } # foreach (@recent_ace)
  print "</TABLE>\n";
} # sub pgShowSpecificAce

sub pgShowRecentAce {		# make a listing and display ace keys changed since start_date
  my $full_or_new = shift;
  my @recent_ace = &getRecentAceKeys($full_or_new);
  print "<TABLE border=1 cellspacing=2>\n";
  print "<TR><TD>joinkey</TD><TD>author</TD><TD>name</TD><TD>grouped</TD><TD>grouped with</TD><TD>twoified</TD><TD>Compare</TD></TR>\n";
  foreach (@recent_ace) { 
    &printFormOpen();
    my $ace_key = 'ace' . $_;
    print "<INPUT TYPE=\"HIDDEN\" NAME=\"ace_key\" VALUE=\"$ace_key\">\n";
    print "<TR><TD>$ace_key</TD>";
    &pgShowHtmlAceDataFromKey($ace_key);
    &printMatchButton();
    print "</TR>\n";
    &printFormClose();
  } # foreach (@recent_ace)
  print "</TABLE>\n";
} # sub pgShowRecentAce

sub getRecentAceKeys {		# get ace keys given date
  my $full_or_new = shift;
  my %recent_ace;
  my $result = $conn->exec( "SELECT * FROM ace_grouped WHERE ace_timestamp > '$start_date' AND ace_timestamp < '$end_date';" );
  my @row;
  while (@row = $result->fetchrow) {
    my $push_flag = 1;	# push values by default
    my $ace_key = $row[0];
    if ($full_or_new eq 'full') { 
      $push_flag = 1;	# if getting all values, push (not needed)
    } elsif ($full_or_new eq 'new') { 
      my $result = $conn->exec( "SELECT * FROM ace_twoified WHERE joinkey = '$ace_key';" );
				# this returns a value, but if no entry won't return something 
				# that will loop in the following while loop
      while (my @row = $result->fetchrow) {
        if ($row[1] eq 'YES') { $push_flag = 0; }	# if already twoified under new, don't push
        else { $push_flag = 1; }			# if not already twoified under new, push
      } # while (my @row = $result->fetchrow)
    } else { print "<font color=blue>ERROR : Not a valid choice for full or new</font><BR>\n"; }
    if ($push_flag) {	# if meant to push, push it
      $ace_key =~ s/^ace//;
      push @{ $recent_ace{$ace_key} }, $row[1];
    } # if ($push_flag)
  } # while (@row = $result->fetchrow)
  print scalar(keys %recent_ace) . " ace entries updated between $start_date and $end_date.<BR>\n";
  return sort numerically keys %recent_ace;	# put in array to show a select number
} # sub getRecentAceKeys

sub pgShowHtmlAceDataFromKey {			# show in table form the data from an ace key
  my $ace_key = shift;
  my @ace_html_table = qw(ace_author ace_name);
  foreach my $ace_table (@ace_html_table) {	# show the data
    my $result = $conn->exec( "SELECT * FROM $ace_table WHERE joinkey = '$ace_key';" );
    print "<TD>";
    while (my @row = $result->fetchrow) {
      if($row[1]) { print "$row[1]<BR>"; }
    } # while (@row = $result->fetchrow)
    print "</TD>";
  } # foreach (@ace_html_table)
  my $result = $conn->exec( "SELECT * FROM ace_grouped WHERE joinkey = '$ace_key';" );
  print "<TD>";
  my @row = $result->fetchrow;
  if($row[1]) { print "$row[1]<BR>"; }
  print "</TD>";

  $result = $conn->exec( "SELECT * FROM ace_groupedwith WHERE joinkey = '$ace_key';" );
  print "<TD>";
  my %matches;			# hash of ace and wbg that match this ace key
  my @to_check;			# array of ace and wbg that need to check
  while (my @row = $result->fetchrow) {	# while there are values
    if ($row[1]) { $matches{$row[1]}++; push @to_check, $row[1]; } 
					# if there's a value, put in matches (so as not to get doubles)
					# and push into @to_check, to shift values and not check twice
  } # while (my @row = $result->fetchrow) 
  foreach (@to_check) {		# foreach value to check
    if ($_ =~ m/ace/) { 	# use ace_groupedwith for ace
      $result = $conn->exec( "SELECT * FROM ace_groupedwith WHERE joinkey = '$_';" );
      while (my @row = $result->fetchrow) { 
        if ($row[1]) { unless($matches{$row[1]}) { $matches{$row[1]}++; push @to_check, $row[1]; } }
					# if value, not an old value, put in hash (to check later so
					# as not to repeat a value, add to array to shift new values
      } # while (my @row = $result->fetchrow) 
    } # if ($_ =~ m/ace/) 
    if ($_ =~ m/wbg/) { 	# use wbg_groupedwith for wbg
      $result = $conn->exec( "SELECT * FROM wbg_groupedwith WHERE joinkey = '$_';" );
      while (my @row = $result->fetchrow) { 
        if ($row[1]) { unless($matches{$row[1]}) { $matches{$row[1]}++; push @to_check, $row[1]; } }
      } # while (my @row = $result->fetchrow) 
    } # if ($_ =~ m/wbg/) 
  } # foreach (@to_check)
  foreach $_ (sort keys %matches) { print "$_<BR>\n"; }
  my $grouped_keys = join("\t", sort keys %matches);
						# get the keys that have been grouped
  print "<INPUT TYPE=\"HIDDEN\" NAME=\"grouped_keys\" VALUE=\"$grouped_keys\">\n";
  print "</TD>";

  $result = $conn->exec( "SELECT * FROM ace_twoified WHERE joinkey = '$ace_key';" );
  print "<TD>";
  while (my @row = $result->fetchrow) { if ($row[1]) { print "$row[1]<BR>" } }
  print "</TD>";
} # sub pgShowHtmlAceDataFromKey
  # ACE

#### display ####


####  display from key ####

sub displayAceDataFromKey {		# show all ace data from a given key in multiline table
  my ($ace_key) = @_;
  print "<TABLE border=1 cellspacing=2>\n";
  foreach my $ace_table (@ace_tables) {	# show the data
    my $result = $conn->exec( "SELECT * FROM $ace_table WHERE joinkey = '$ace_key';" );
    my @row;
    while (@row = $result->fetchrow) {
      if ($row[1]) {
        print "<TR><TD>$ace_table</TD>";
        foreach (@row) { print "<TD>$_</TD>"; }
        print "</TR>";
      } # if ($row[1])
    } # while (@row = $result->fetchrow)
  } # foreach (@ace_tables)
  print "</TABLE><BR><BR>\n";
} # sub displayAceDataFromKey

sub displayWbgDataFromKey {		# show all wbg data from a given key in multiline table
  my ($wbg_key) = @_;
  print "<TABLE border=1 cellspacing=2>\n";
  foreach my $wbg_table (@wbg_tables) {	# go through each table for the key
    my $result = $conn->exec( "SELECT * FROM $wbg_table WHERE joinkey = '$wbg_key';" );
    my @row;
    while (@row = $result->fetchrow) {
      if ($row[1]) { 
        print "<TR><TD>$wbg_table</TD>"; 
        foreach (@row) { print "<TD>$_</TD>"; }
        print "</TR>\n";
      } # if ($row[1])
    } # while (@row = $result->fetchrow)
  } # foreach my $wbg_table (@wbg_tables)
  print "</TABLE><BR><BR>\n";
} # sub displayWbgDataFromKey

####  display from key ####

#### confirm ####

sub confirm {					# show final values written to pgsql
  my $outfile = "/home/postgres/work/authorperson/twoifyfile";
  open(OUT, ">>$outfile") or die "Cannot open $outfile : $!";
  my $twoify_counter = '1';			# initialize number of fields to read
  my $pg_counter = '';				# initialize postgresql counter for joinkey
  if ( $query->param('twoify_counter') ) { 	# get how many parameters there are
    my $oop = $query->param('twoify_counter');	# get number of parameters
    $twoify_counter = &untaint($oop);
    my $result = $conn->exec( "SELECT nextval('two_sequence');" );
						# get next sequence value
    my @row = $result->fetchrow;		# get value
    if ($row[0]) { $pg_counter	= $row[0]; }	# get counter value
    print "PG COUNTER : $pg_counter<BR>\n";	# display the two sequence number (joinkey value)
    print OUT "PG COUNTER\t$pg_counter\n";	# flatfile the sequence number (joinkey value)
    $result = $conn->exec( "INSERT INTO two VALUES ('two$pg_counter', '$pg_counter');" );
# print "    \$result = \$conn->exec( \"INSERT INTO two VALUES ('two$pg_counter', '$pg_counter');\");<BR>\n";
						# write joinkey value to postgresql
    if ( $query->param('grouped_keys') ) { 	# if grouped keys
      my $oop = $query->param('grouped_keys');	# get the grouped keys
      my $grouped_keys = &untaint($oop);	# untaint them
      my @grouped_keys = split/\t/, $grouped_keys;	# put in array
      foreach (@grouped_keys) { 		# for each grouped key
        print "$pg_counter : groups : $_<BR>\n"; 	# display the grouped values
        print OUT "$pg_counter\tgroups\t$_\n"; 		# flatfile the grouped values
        $result = $conn->exec( "INSERT INTO two_groups VALUES ('two$pg_counter', '$_');" );
# print "        \$result = \$conn->exec( \"INSERT INTO two_groups VALUES ('two$pg_counter', '$_');\");<BR>";
						# insert the grouped keys into postgresql
        if ($_ =~ m/^ace/) {			# make the keys twoified
          $result = $conn->exec( "INSERT INTO ace_twoified VALUES ('$_', 'YES');" );
# print "           \$result = \$conn->exec( \"INSERT INTO ace_twoified VALUES ('$_', 'YES');\" );<BR>";
        } elsif ($_ =~ m/^wbg/) {		# make the keys twoified
          $result = $conn->exec( "INSERT INTO wbg_twoified VALUES ('$_', 'YES');" );
# print "           \$result = \$conn->exec( \"INSERT INTO wbg_twoified VALUES ('$_', 'YES');\" );<BR>";
        } else {
          print "<font color=blue>ERROR : Not a valid file type for grouping : $_</font><BR>\n";
        } # if ($_ =~ m/^ace/) 
      } # foreach (@grouped_keys) 
    } # if ( $query->param('grouped_keys') )
  } # if ( $query->param("type_$i") )
  unless ($pg_counter) {
    print "<font color=blue>ERROR : No sequence value in postgreSQL</font><BR>\n";
  } else { # unless ($pg_counter)		# if we got the next counter value
    my $pg_table_counter = 1;			# count how many entries (for order) of that type
    my $type_of_type = '';			# check to see if dealing with a new type, only
						# works because the types are read sequentially
    print "<TABLE border = 1>\n";
    for (my $i = 1; $i < $twoify_counter+1; $i++) { 	# for each of those parameters
      if ( $query->param("type_$i") ) { 		# get the main wbg key
        my $oop = $query->param("type_$i");	# get type
        my $type = "two_" . &untaint($oop);
        $oop = $query->param("val_$i");		# get value
        my $value = &untaint($oop);		
        $oop = $query->param("time_$i");	# get time
        my $time = &untaint($oop);		
        if ($type eq $type_of_type) { $pg_table_counter++; } 
          else { $pg_table_counter = 1; $type_of_type = $type; }
        print "<TR><TD>$pg_counter</TD><TD>$time</TD><TD>$pg_table_counter</TD><TD>$type : $value</TD>\n";
						# display the key value, table, and value
        print OUT "$pg_counter\t$time\t$type\t$value\n";	
						# flatfile the key value, time, table, and value
        $value =~ s/'/\\'/g;			# escape apostrophies
        $value =~ s/"/\\"/g;			# escape double quotes
        $value =~ s/@/\\@/g;			# escape @s
	  # insert joinkey, two_order, two_table, old_timestamp, two_timestamp
        if ($type eq 'two_comment') { 		# deal with comment separetly because it 
						# has less pg table columns (bad way to do it
						# since it should be outside of type completely)
          my $result = $conn->exec( "INSERT INTO $type VALUES ('two$pg_counter', '$value');" );
          print "<TD>my \$result = \$conn->exec( \"INSERT INTO $type VALUES ('two$pg_counter', '$value');\" );</TD></TR>";
        } else {				# deal with normal types
          my $result = $conn->exec( "INSERT INTO $type VALUES ('two$pg_counter', '$pg_table_counter', '$value', '$time');" );
          print "<TD>my \$result = \$conn->exec( \"INSERT INTO $type VALUES ('two$pg_counter', '$pg_table_counter', '$value', '$time');\" );</TD></TR>";
						# insert the key value, and value into postgresql table
        } # if ($type eq 'two_comment')
      } # if ( $query->param("wbg_key") )
    } # for (my $i = 1; $i < 20; $i++)
    print "</TABLE>\n";
  } # else # unless ($pg_counter)
  print OUT "\n"; 				# divider
  close (OUT) or die "Cannot close $outfile : $!";
} # sub confirm

#### confirm ####

#### twoify ####

sub twoify {					# show chosen values from form as final to confirm
  &printFormOpen();
  &printConfirmButton();
  my $field_counter = '1';			# default value of fields to read
  my $twoify_counter = '0';			# initialized value of fields to pass
  if ( $query->param('field_counter') ) { 	# get how many parameters there are
    my $oop = $query->param('field_counter');	# get number of parameters
    $field_counter = &untaint($oop);		# untaint it
  } # if ( $query->param('field_counter') )
  if ( $query->param('grouped_keys') ) { 	# get how many parameters there are
    my $oop = $query->param('grouped_keys');	# get number of parameters
    my $grouped_keys = &untaint($oop);		# untaint it
    print "<INPUT TYPE=\"HIDDEN\" NAME=\"grouped_keys\" VALUE=\"$grouped_keys\">\n";
  } # if ( $query->param('grouped_keys') )

  for (my $i = 1; $i < $field_counter+1; $i++) { 	# for each of those parameters
    if ( $query->param("check_$i") ) { 		# if it has been checked (the box)
      $twoify_counter++;			# add to counter to pass
      my $oop = $query->param("type_$i");	# get type
      my $type = &untaint($oop);
      $oop = $query->param("val_$i");		# get value
      my $value = &untaint($oop);		# 
      $oop = $query->param("time_$i");		# get time
      my $time = &untaint($oop);		# 
      print "TIME : $time : TYPE : $type : VALUE : $value<BR>\n";	# display it
      print "<INPUT TYPE=\"HIDDEN\" NAME=\"type_$twoify_counter\" VALUE=\"$type\">\n";
						# pass type to cgi form
      print "<INPUT TYPE=\"HIDDEN\" NAME=\"val_$twoify_counter\" VALUE=\"$value\">\n";
						# pass value to cgi form
      print "<INPUT TYPE=\"HIDDEN\" NAME=\"time_$twoify_counter\" VALUE=\"$time\">\n";
						# pass time to cgi form
    } # if ( $query->param("wbg_key") )
  } # for (my $i = 1; $i < 20; $i++)
  print "<INPUT TYPE=\"HIDDEN\" NAME=\"twoify_counter\" VALUE=\"$twoify_counter\">\n";
						# pass number of parameters to cgi
  &printConfirmButton();
  &printFormClose();
} # sub twoify

#### twoify ####


#### html stuff ####

sub printLinks {
  print "<CENTER><A HREF=\"http://minerva.caltech.edu/~azurebrd/cgi-bin/index.cgi\">Site Map</A></CENTER>";
  print "<CENTER><A HREF=\"http://minerva.caltech.edu/~postgres/cgi-bin/cecilia/oneifier.txt\">Documentation</A></CENTER>";
} # sub printLinks 

sub printFormOpen {			# compare form, encompass wbg, aces, and wbgs
  print "<FORM METHOD=\"POST\" ACTION=\"http://minerva.caltech.edu/~postgres/cgi-bin/cecilia/oneifier.cgi\">\n";
} # sub printFormOpen

sub printFormClose {
  print "</FORM>\n";			# close match form, encompass wbg, aces, and wbgs
} # sub printFormClose

sub printMatchButton {
  print "<TD><INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Match !\"></TD>\n";
} # sub printMatchButton

sub printOneifyButton {
  print "<INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Oneify !\"><BR><BR>\n";
} # sub printOneifyButton

sub printConfirmButton {		# button to confirm as final and commit to pgsql
  print "<INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Confirm !\"><BR><BR>\n";
} # sub printConfirmButton

#### html stuff ####
