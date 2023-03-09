#!/usr/bin/perl

# Take output from person_lineage form(1).  Make lines of connection for 1-1
# mappings.  Get list of names.  Go through each 1-1 connection and if
# appropriate print out forward and reverse and insert into postgres.  
# 2003 10 27

use strict;

use Pg;
my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my %aka_hash = &getPgHash();	# read from postgres
my %hash;		# key supervisor, key supervisee, value role
my %hash_collab;	# key collaborator1, key collaborator2, value role
my %names;		# key name, value WBPerson#

my @unprocessed;	# lines of stuff to add to postgres, names not two numbers

&process();

sub process {
#   my $infile = 'person_lineage.ace';
  my $infile = $ARGV[0];
  $/ = "";
  open (IN, "<$infile") or die "Cannot open $infile : $!";
  my %name;			# hash of names to check
  while (my $entry = <IN>) {
    my ($main) = $entry =~ m/Person_lineage : (.*)/;
    $main =~ s/^\s+//g; $main =~ s/\s+$//g; $main =~ s/\.//g; $main =~ s/\s+/ /g;
    my ($sender) = $entry =~ m/email\t(.*)/;
    $sender =~ s/^\s+//g; $sender =~ s/\s+$//g; $sender =~ s/\.//g; $sender =~ s/\s+/ /g; $sender =~ s/^\"//; $sender =~ s/\"$//;
    $names{$main} = '';
    my (@supervised) = $entry =~ m/(trained_.*?\t\".*?\")/g;
    foreach my $line (@supervised) {		# get trained_ into %hash
      my ($role, $people) = $line =~ m/trained_(.*?)\t\"(.*?)\"/;
      $role = &fixRole($role);
      my @people = split/,/, $people;
      foreach (@people) { 
        $_ =~ s/^\s+//g; $_ =~ s/\s+$//g; $_ =~ s/\.//g; $_ =~ s/\s+/ /g;
        if ($_) { 
#           print "$main\t$_\t\t$role\t\t\t$sender\tCURRENT_TIMESTAMP\n"; 
          $names{$_} = '';
          push @unprocessed, "\t$main\t$_\t\t$role\t\t\t$sender\tCURRENT_TIMESTAMP"; }
#         if ($_) { $hash{$main}{$_} = "$role\t$sender"; $names{$_} = ''; }
      } # foreach (@people)
    } # foreach my $line (@supervised)
    my (@supervised_by) = $entry =~ m/(trainedwith_.*?\t\".*?\")/g;
    foreach my $line (@supervised_by) {		# get trainedwith_ into %hash
      my ($role, $people) = $line =~ m/trainedwith_(.*?)\t\"(.*?)\"/;
      $role = &fixRole($role);
      my @people = split/,/, $people;
      foreach (@people) { 
        $_ =~ s/^\s+//g; $_ =~ s/\s+$//g; $_ =~ s/\.//g; $_ =~ s/\s+/ /g;
#         if ($_) { $hash{$_}{$main} = "$role\t$sender"; $names{$_} = ''; }
        if ($_) { 
#           print "$main\t$_\t\twith$role\t\t\t$sender\tCURRENT_TIMESTAMP\n"; 
          $names{$_} = '';
          push @unprocessed, "\t$main\t$_\t\twith$role\t\t\t$sender\tCURRENT_TIMESTAMP"; }
      } # foreach (@people)
    } # foreach my $line (@supervised)
    my (@collaborated) = $entry =~ m/(collaborated\t\".*?\")/g;
    foreach my $line (@collaborated) {		# put collaborated into %hash_collab
      my ($role, $people) = $line =~ m/(collaborated)\t\"(.*?)\"/;
      $role = &fixRole($role);
      my @people = split/,/, $people;
      foreach (@people) { 
        $_ =~ s/^\s+//g; $_ =~ s/\s+$//g; $_ =~ s/\.//g; $_ =~ s/\s+/ /g;
        if ($_) { 
#           print "$main\t$_\t\t$role\t\t\t$sender\tCURRENT_TIMESTAMP\n";
          $names{$_} = '';
          push @unprocessed, "\t$main\t$_\t\t$role\t\t\t$sender\tCURRENT_TIMESTAMP"; }
#         if ($_) { $hash_collab{$main}{$_} = "$role\t$sender"; $names{$_} = ''; }
      } # foreach (@people)
    } # foreach my $line (@collaborated)
  } # while (<IN>)
  close (IN) or die "Cannot close $infile : $!";
  $/ = "\n";

  foreach my $name (sort keys %names) {
    if ($name !~ /\w/) { 	# if not a valid name, don't search
    } elsif ($name =~ /(\d+)/) {
      $names{$name} = 'WBPerson' . $1;
    } else { 			# if it doesn't do simple aka hash thing
      &processAkaSearch($name, $name, %aka_hash);
    }
  } # foreach my $name (sort keys %names)

  foreach my $line (@unprocessed) {
# print "LINE $line\n";
    my ($a, $main, $other, $b, $role, $c, $d, $sender, $time) = split /\t/, $line;
# print "MAIN $main\tOTHER $other\n";
    my $joinkey = 'NULL';
    my $two_number = 'NULL';
    if ($names{$main}) { $joinkey = "\'$names{$main}\'"; $joinkey =~ s/WBPerson/two/g; }
    if ($names{$other}) { $two_number = "\'$names{$other}\'"; $two_number =~ s/WBPerson/two/g; }
    $line = "$joinkey\t$main\t$other\t$two_number\t$role\tNULL\tNULL\t$sender\t$time";
# print "MAIN $main\tOTHER $other\n";
# print "LINE2 $line\n";
    if (($role =~ m/^with/) || ($role =~ m/Collaborated/)) { 		# ignore other
      if ($names{$other}) { 
#         print "$joinkey\t$main\t$other\t$two_number\t$role\tNULL\tNULL\t$sender\t$time\n";
        print "INSERT INTO two_lineage VALUES ($joinkey, '$main', '$other', $two_number, '$role', NULL, NULL, '$sender', $time);\n";
        my $result = $conn->exec( "INSERT INTO two_lineage VALUES ($joinkey, '$main', '$other', $two_number, '$role', NULL, NULL, '$sender', $time);" );
        $role =~ s/^with//g;
#         print "$two_number\t$other\t$main\t$joinkey\t$role\tNULL\tNULL\t$sender\t$time\n"; 
        print "INSERT INTO two_lineage VALUES ($two_number, '$other', '$main', $joinkey, '$role', NULL, NULL, '$sender', $time);\n"; 
        $result = $conn->exec( "INSERT INTO two_lineage VALUES ($two_number, '$other', '$main', $joinkey, '$role', NULL, NULL, '$sender', $time);" ); }
      else { print "IGNORE $line\n"; }
    } else {
#       print "$joinkey\t$main\t$other\t$two_number\t$role\tNULL\tNULL\t$sender\t$time\n";
      print "INSERT INTO two_lineage VALUES ($joinkey, '$main', '$other', $two_number, '$role', NULL, NULL, '$sender', $time);\n";
      my $result = $conn->exec( "INSERT INTO two_lineage VALUES ($joinkey, '$main', '$other', $two_number, '$role', NULL, NULL, '$sender', $time);" );
#       print "$two_number\t$other\t$main\t$joinkey\t$role\tNULL\tNULL\t$sender\t$time\n";
      print "INSERT INTO two_lineage VALUES ($two_number, '$other', '$main', $joinkey, 'with$role', NULL, NULL, '$sender', $time);\n";
      $result = $conn->exec( "INSERT INTO two_lineage VALUES ($two_number, '$other', '$main', $joinkey, 'with$role', NULL, NULL, '$sender', $time);" );
#       if ($names{$main}) { print "$line\n"; }
#       else { print "IGNORE $line\n"; }
    }
  } # foreach my $line (@unprocessed)
} # sub process


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
#     &processPgWild($name);
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


### NOT USING THIS ###

sub processPgNumber {
  my $input_name = shift;
  if ($input_name =~ /(\d*)/) {   # and search just for number
    my $person = "WBPerson".$1;
    my $joinkey = "two".$1;
    my $result = $conn->exec ( "SELECT * FROM two_standardname WHERE joinkey = '$joinkey';" );
    my @row = $result->fetchrow; 
    print "PERSON <FONT COLOR=red>$row[2]</FONT> has \n";
    print "ID <A HREF=http://www.wormbase.org/db/misc/etree?name=${person};class=Person>$person</A>.<BR>\n";
  } # if ($input_name =~ /(\d*)/)
}

