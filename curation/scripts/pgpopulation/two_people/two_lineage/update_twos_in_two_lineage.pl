#!/usr/bin/env perl

# Usage ./update_twos_in_two_lineage.pl > out
# out is record of what sent to postgres.
#
# Program to check names without numbers in postgres and assign them.  
# if no match check if should be ignored (trainer or collaborator) and
# set joinkey and two_number to NO if should have match output to
# not_found and email Cecilia.  2003 10 29

# Switched output to lineage_psql_commands, appending date and time to end of
# file.  set crontab -e to run this at 3am mon-fri   2003 10 31
#
# Updated to email Cecilia regardless of whether there's info so she knows
# that there is nothing to do.  2003 11 07
#
# Update to send Cecilia people where two_number is ``NO''.  2005 07 25
#
# Update to send Cecilia people where two_number is ``NO''.
# This time just querying and sending the results directly.  2005 11 16
#
# Multiple people who had the same name match were giving the two# of the one
# that went into the hash last.  2007 07 05
#
# Moved from azurebrd to postgres.  2011 06 03
#
# no longer output to flatfiles in dockerized, okayed by Cecilia  2023 03 14
#
# # 0 3 * * tue,wed,thu,fri,sat /home/postgres/work/pgpopulation/two_people/two_lineage/update_twos_in_two_lineage.pl
# 0 3 * * tue,wed,thu,fri,sat /usr/lib/scripts/pgpopulation/two_people/two_lineage/update_twos_in_two_lineage.pl




use strict;
use Jex;	# mailer, getDate
use DBI;
use Dotenv -load => '/usr/lib/.env';

my $dbh = DBI->connect ( "dbi:Pg:dbname=$ENV{PSQL_DATABASE};host=$ENV{PSQL_HOST};port=$ENV{PSQL_PORT}", "$ENV{PSQL_USERNAME}", "$ENV{PSQL_PASSWORD}") or die "Cannot connect to database!\n";
# my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n";


# print STDERR "TIME before read Hash\n";
my %aka_hash = &getPgHash();	# read from postgres
# print STDERR "TIME after read Hash\n";
my %hash;		# key supervisor, key supervisee, value role
my %hash_collab;	# key collaborator1, key collaborator2, value role
my %names;		# key name, value WBPerson#

my $too_many_matches;	# global (I'm being lazy) for people whose name has too many matches

    my %standard_name;
    my $result = $dbh->prepare ( "SELECT * FROM two_standardname;" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
    while (my @row = $result->fetchrow ) {
      $standard_name{$row[0]} = $row[2];
    } # while (my @row = $result->fetchrow )

&process();

sub process {
#   my $result = $dbh->prepare( "SELECT two_othername FROM two_lineage WHERE two_number IS NULL;" );
  my $result = $dbh->prepare( "SELECT two_othername FROM two_lineage WHERE two_number IS NULL or two_number = 'NO';" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while ( my @row = $result->fetchrow ) { 
    my $main = $row[0];
    $names{$main}++; }
#   $result = $dbh->prepare( "SELECT two_sentname FROM two_lineage WHERE joinkey IS NULL;" );
  $result = $dbh->prepare( "SELECT two_sentname FROM two_lineage WHERE joinkey IS NULL OR two_number = 'NO';" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while ( my @row = $result->fetchrow ) { 
    my $main = $row[0];
    $names{$main}++; }
#   $names{'Xiaodong Wang'}++;

  # get WBPerson# into %names hash from postgres
# no longer output to flatfiles in dockerized, okayed by Cecilia  2023 03 14
# #   my $outfile = '/home/azurebrd/work/parsings/authorperson/citaceLineage/lineage_psql_commands';
#   my $outfile = '/home/postgres/work/pgpopulation/two_people/two_lineage/lineage_psql_commands';
#   open (OUT, ">> $outfile") or die "Cannot append to $outfile : $!";
# #   my $not_found = 'not_found';	# don't want that in homedir 2008 11 13
# #   my $not_found = '/home/azurebrd/work/parsings/authorperson/citaceLineage/not_found';
#   my $not_found = '/home/postgres/work/pgpopulation/two_people/two_lineage/not_found';
#   open (NOT, ">$not_found") or die "Cannot create $not_found : $!";
  my $date = &getDate();
#   print OUT "\n$date\n";
  foreach my $name (sort keys %names) {
# print "LOOKING AT $name\n";
    if ($name !~ /\w/) { 	# if not a valid name, don't search
    } elsif ($name =~ /(\d+)/) {
      $names{$name} = 'WBPerson' . $1;
    } else { 			# if it doesn't do simple aka hash thing
      &processAkaSearch($name, %aka_hash);
    }
  } # foreach my $name (sort keys %names)

  my $cecilia_mail = '';
  foreach my $name (sort keys %names) { 
    if ($names{$name} =~ m/^\d+/) { 	# if only a number (no match) check it and email Cecilia if needed
      $cecilia_mail = &checkIfBadEntry($name, $cecilia_mail);
    } else { 				# if entry, change joinkey and two_number (forward and reverse)
      $names{$name} =~ s/WBPerson/two/g;
#       print OUT "NAME : $name\t$names{$name}\n"; 
      if ($name =~ m/\'/) { $name =~ s/\'/''/g; }
#       print OUT "UPDATE two_lineage SET two_number = '$names{$name}' WHERE two_othername = '$name' AND two_number IS NULL;\n";
#       print OUT "UPDATE two_lineage SET joinkey = '$names{$name}' WHERE two_sentname = '$name' AND joinkey IS NULL;\n";
      my $result = $dbh->do( "UPDATE two_lineage SET two_number = '$names{$name}' WHERE two_othername = '$name' AND two_number IS NULL;" );
      $result = $dbh->do( "UPDATE two_lineage SET joinkey = '$names{$name}' WHERE two_sentname = '$name' AND joinkey IS NULL;" );
    }
  } # foreach my $name (sort keys %names)

    # Show Cecilia all NO data  2005 11 16
  my $command = "SELECT * FROM two_lineage WHERE two_number = 'NO' ";
  my $result2 = $dbh->prepare( " $command " );
  $result2->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  $cecilia_mail .= "This command $command returns :\n";
  while (my @row = $result2->fetchrow) {
    my $line = join"\t", @row;			# can't just .= @row  that doesn't work  2005 11 22
    $cecilia_mail .= "$line\n"; }

  unless ($cecilia_mail) { $cecilia_mail = 'Nobody sent any data today'; }
  if ($cecilia_mail) {			# if there's data to mail, mail to Cecilia
    if ($too_many_matches) { $cecilia_mail .= "\n\n$too_many_matches"; }
    my $user = 'updating_lineage_missing_people';
    my $email = 'cecnak@wormbase.org';
#     my $email = 'cecilia@tazendra.caltech.edu';
#     my $email = 'azurebrd@minerva.caltech.edu';
    my $subject = 'Update Lineage.  List of missing people';
    &mailer($user, $email, $subject, $cecilia_mail);
  }
#   close (NOT) or die "Cannot close $not_found : $!";
#   close (OUT) or die "Cannot close $outfile : $!";
} # sub process

sub checkIfBadEntry {
	# if entry is a Trainer or Collaborator, set joinkey/two_number to ``NO'' (forward and reverse)
	# otherwise email Cecilia and output to ``not_found''
  my ($name, $cecilia_mail) = @_;
    # Need to get all info for each missing entry regardless of good or bad
  my $result = $dbh->prepare( "SELECT * FROM two_lineage WHERE two_sentname = '$name';" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
    my $joinkey = $row[0];
    my $sentname = $row[1];
    my $othername = $row[2];
    my $othernum = $row[3];
    my $role = $row[4];
    my $sender = $row[7];
    if ($name =~ m/\'/) { $name =~ s/\'/''/g; }
    if ($othername =~ m/\'/) { $othername =~ s/\'/''/g; }

    if ($sender !~ m/^REV -/) { 	# TO CECILIA because no joinkey from sender
#       print NOT "NAME : $name\t$names{$name}\n"; 
      $cecilia_mail .= "$name with $othername ($othernum) role $role sent by $sender\n\n";
    } elsif ( $role =~ m/^Collaborated/ ) {	# Collaboration, probably not in worms
        # fix this entry (Reversed)
#       print OUT "IGNORE $name\n";
#       print OUT "UPDATE two_lineage SET joinkey = 'NO' WHERE two_sentname = '$name' AND two_othername = '$othername' AND two_role = '$role' AND two_sender = '$sender';\n"; 
      my $result2 = $dbh->do( "UPDATE two_lineage SET joinkey = 'NO' WHERE two_sentname = '$name' AND two_othername = '$othername' AND two_role = '$role' AND two_sender = '$sender';" ); 
      $sender =~ s/REV - //g;		# fix sender to non-reversed
        # fix non-reversed entry
#       print OUT "UPDATE two_lineage SET two_number = 'NO' WHERE two_othername = '$name' AND two_sentname = '$othername' AND two_role = '$role' AND two_sender = '$sender';\n"; 
      $result2 = $dbh->do( "UPDATE two_lineage SET two_number = 'NO' WHERE two_othername = '$name' AND two_sentname = '$othername' AND two_role = '$role' AND two_sender = '$sender';" ); 
    } elsif ( $role !~ m/^with/ ) {		# Trainer, probably not in worms
#       print OUT "IGNORE $name\n";
#       print OUT "UPDATE two_lineage SET joinkey = 'NO' WHERE two_sentname = '$name' AND two_othername = '$othername' AND two_role = '$role' AND two_sender = '$sender';\n"; 
      my $result2 = $dbh->do( "UPDATE two_lineage SET joinkey = 'NO' WHERE two_sentname = '$name' AND two_othername = '$othername' AND two_role = '$role' AND two_sender = '$sender';" ); 
      $role = "with$role";
      $sender =~ s/REV - //g;		# fix sender to non-reversed
        # fix non-reversed entry
#       print OUT "UPDATE two_lineage SET two_number = 'NO' WHERE two_othername = '$name' AND two_sentname = '$othername' AND two_role = '$role' AND two_sender = '$sender';\n"; 
      my $result2 = $dbh->do( "UPDATE two_lineage SET two_number = 'NO' WHERE two_othername = '$name' AND two_sentname = '$othername' AND two_role = '$role' AND two_sender = '$sender';" ); 
    } else {					# Trainee, need WBPerson entry
#       print NOT "NAME : $name\t$names{$name}\n"; 
      $cecilia_mail .= "$name with $othername ($othernum) role $role sent by $sender\n\n";
    }
  } # while (my @row = $result->fetchrow)
  return $cecilia_mail;
} # sub checkIfBadEntry

sub fixRole {		# role needs to fit acedb models #Role value
  my $role = shift;
  if ($role eq 'highschool') { $role = 'Highschool'; }
  elsif ($role eq 'visitedlab') { $role = 'Lab_visitor'; }
  elsif ($role eq 'masters') { $role = 'Masters'; }
  elsif ($role eq 'phd') { $role = 'Phd'; }
  elsif ($role eq 'postdoc') { $role = 'Postdoc'; }
  elsif ($role eq 'staff') { $role = 'Research_staff'; }
  elsif ($role eq 'sabbatical') { $role = 'Sabbatical'; }
  elsif ($role eq 'undergrad') { $role = 'Undergrad'; }
  elsif ($role eq 'unknown') { $role = 'Unknown'; }
  elsif ($role eq 'collaborated') { $role = 'Collaborated'; }
  else { print STDERR "ERROR : ROLE $role Invalid\n"; }
  return $role;
} # sub fixRole








sub processAkaSearch {			# get generated aka's and try to find exact match
  my ($name, %aka_hash) = @_;
  my $name_backup = $name;
  $name =~ s/^\s+//g; $name =~ s/\s+$//g; $name =~ s/\.//g; $name =~ s/\s+/ /g;
  $name =~ s/,.*$//g;
  my $search_name = lc($name);
  unless ($aka_hash{$search_name}) { 
    my @names = split/\s+/, $search_name; $search_name = '';
    foreach my $name (@names) {
      if ($name =~ m/^[a-zA-Z]$/) { $search_name .= "$name "; }
      else { $search_name .= '*' . $name . '* '; }
    }
#     &processPgWild($name);
  } else { 
# put this at front
#     my %standard_name;
#     my $result = $dbh->prepare ( "SELECT * FROM two_standardname;" );
#     $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
#     while (my @row = $result->fetchrow ) {
#       $standard_name{$row[0]} = $row[2];
#     } # while (my @row = $result->fetchrow )

#     print "$name shows\t";
    my @stuff = sort {$a <=> $b} keys %{ $aka_hash{$search_name} };
    if (scalar(@stuff) > 1) { 
      my $twos = join", ", @stuff;
#       print OUT "TOO MANY $search_name matches : $twos\n";
      $too_many_matches .= "TOO MANY $search_name matches : $twos\n"; }
    else {
      foreach $_ (@stuff) { 		# add url link
        next if ($_ =~ m/\D/);		# skip stuff without numbers
        my $joinkey = 'two'.$_;
        my $person = 'WBPerson'.$_;
        $names{$name_backup} = $person;
#         print "$standard_name{$joinkey}\t$person\t";
    } }
#     print "\n";
  }
} # sub processAkaSearch



sub getPgHash {				# get akaHash from postgres instead of flatfile
  my $result;
  my %filter;
  my %aka_hash;
  
  my @tables = qw (first middle last);
  foreach my $table (@tables) { 
    $result = $dbh->prepare ( "SELECT * FROM two_aka_${table}name WHERE two_aka_${table}name IS NOT NULL AND two_aka_${table}name != 'NULL' AND two_aka_${table}name != '';" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
    while ( my @row = $result->fetchrow ) {
      if ($row[3]) { 					# if there's a curator
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
    $result = $dbh->prepare ( "SELECT * FROM two_${table}name WHERE two_${table}name IS NOT NULL AND two_${table}name != 'NULL' AND two_${table}name != '';" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
    while ( my @row = $result->fetchrow ) {
      if ($row[3]) { 					# if there's a curator
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

  my $result = $dbh->prepare ( "SELECT * FROM two_standardname;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow ) {
    $row[2] =~ s/^\s+//g; $row[2] =~ s/\s+$//g;		# take out spaces in front and back
    $row[2] =~ s/[\,\.]//g;				# take out commas and dots
    $row[2] =~ s/_/ /g;					# replace underscores for spaces
    $row[2] = lc($row[2]);				# for full values (lowercase it)
    $row[0] =~ s/two//g;				# take out the 'two' from the joinkey
    $aka_hash{$row[2]}{$row[0]}++;
  } # while (my @row = $result->fetchrow )

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


### NOT USING THIS ###

sub processPgNumber {
  my $input_name = shift;
  if ($input_name =~ /(\d*)/) {   # and search just for number
    my $person = "WBPerson".$1;
    my $joinkey = "two".$1;
    my $result = $dbh->prepare ( "SELECT * FROM two_standardname WHERE joinkey = '$joinkey';" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
    my @row = $result->fetchrow; 
    print "PERSON <FONT COLOR=red>$row[2]</FONT> has \n";
    print "ID <A HREF=http://www.wormbase.org/db/misc/etree?name=${person};class=Person>$person</A>.<BR>\n";
  } # if ($input_name =~ /(\d*)/)
}

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
#       my $result = $dbh->prepare ( "SELECT * FROM two_aka_${table}name WHERE two_aka_${table}name ~ '$input_part';" );
      my $result = $dbh->prepare ( "SELECT * FROM two_aka_${table}name WHERE lower(two_aka_${table}name) ~ lower('$input_part');" );
      $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
      while ( my @row = $result->fetchrow ) { $filter{$row[0]}{$input_part}++; }
#       $result = $dbh->prepare ( "SELECT * FROM two_${table}name WHERE two_${table}name ~ '$input_part';" );
      $result = $dbh->prepare ( "SELECT * FROM two_${table}name WHERE lower(two_${table}name) ~ lower('$input_part');" );
      $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
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

