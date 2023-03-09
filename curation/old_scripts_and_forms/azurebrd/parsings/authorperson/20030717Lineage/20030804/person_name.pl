#!/usr/bin/perl

# Search names to find WBPerson Number

# Take a flatfile.ace of WBPerson numbers with possible
# first middle and last names.  Put into a hash of possible
# combinations of valid names (lowercased).  Get input from
# user and see which WBPerson Numbers match that input.
# 2003 03 17
#
# Changed to use PG for all searches.  Number search gets
# the Standardname.  AkaSearch creates the aka_hash from
# postgres.  PgWild does ~ match using lower() to make the
# search case insensitive.  Implemented priority of search
# paramters (length) for PgWild.  2003 03 25
#
# Added if ($name !~ /\w/) in case name not valid, don't
# display anything (for case of first loading page having
# no default search)  2003 06 20

use Jex;			# untaint, getHtmlVar, cshlNew
use strict;
use CGI;
use Ace;
# use ElegansSubs qw(:DEFAULT PrintRefs);

use Pg;
my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;


my $query = new CGI;
my $firstflag = 1;
my $DB = Ace->connect(-path  =>  '/home/acedb/ts',
                      -program => '/home/acedb/bin/tace') || die "Connection failure: ",Ace->error;


&process();			# see if anything clicked
# &display();			# show form as appropriate

sub process {			# see if anything clicked
  my $infile = 'test_names';
  open (IN, "<$infile") or die "Cannot open $infile : $!";
  my %name;			# hash of names to check
  while (<IN>) {
    chomp;
    my ($name, $stuff) = split/\t/, $_;
    $name =~ s/\s+/ /g;
    if ($name =~ m/^(Trained\w+) (.*)$/) {
#       print "$1 ";
      $name{$2}++;
    } else { $name{$_}++; }
  } # while (<IN>)

  my $not_found = 'not_found';
  open (NOT, ">$not_found") or die "Cannot create $not_found : $!";
  foreach my $name (sort keys %name) {
    if ($name !~ /\w/) { 	# if not a valid name, don't search
    } elsif ($name =~ /\d/) { 
      &processPgNumber($name);
#       &processNumber($name);
    } elsif ($name =~ m/[\*\?]/) { 	# if it has a * or ?
      &processPgWild($name);
#       &processWild($name);
    } else { 			# if it doesn't do simple aka hash thing
      my %aka_hash = &getPgHash();
      &processAkaSearch($name, $name, %aka_hash);
    }
  } # foreach my $name (sort keys %name)
  close (NOT) or die "Cannot close $not_found : $!";
} # sub process

sub processPgWild {
  my $input_name = shift;
  print NOT "INPUT\t$input_name\n";
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
  
  print NOT "There are " . scalar(keys %matches) . " match(es).\n";
  foreach my $person (sort {$matches{$b}<=>$matches{$a} || $input_parts{$b} <=> $input_parts{$a}} keys %matches) { 
    print NOT "$person\t";
    print NOT "has $matches{$person} match(es)\tpriority $input_parts{$person}\n";
  } 
  print NOT "\n";
  
  unless (%matches) {
    print NOT "Sorry, no person named '$input_name', please try again\n" if $input_name;
  }
} # sub processPgWild


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



sub processAkaSearch {			# get generated aka's and try to find exact match
  my ($name, $name, %aka_hash) = @_;
  my $search_name = lc($name);
  unless ($aka_hash{$search_name}) { 
    print NOT "$name NOT FOUND\n";
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

    print "$name shows\t";
    my @stuff = sort {$a <=> $b} keys %{ $aka_hash{$search_name} };
    foreach $_ (@stuff) { 		# add url link
      my $joinkey = 'two'.$_;
      my $person = 'WBPerson'.$_;
      print "$standard_name{$joinkey}\t$person\t";
    }
    print "\n";

#     my @stuff = keys %{ $aka_hash{$search_name} };
#     foreach (@stuff) { 		# add url link
#       $_ =~ s/two//g;
#       my $person = 'WBPerson'.$_;
#       $_ = "<A HREF=http://www.wormbase.org/db/misc/etree?name=${person};class=Person>$person</A>";
#     }
#     my $stuff = join", ", @stuff;
#     print "<TR><TD>NAME <FONT COLOR=red>$name</FONT> could be : $stuff </TD></TR>\n";
  }
} # sub processAkaSearch


sub display {			# show form as appropriate
    print <<"EndOfText";
<FORM METHOD="POST" ACTION="person_name.cgi">
 
  <TABLE ALIGN="center"> 
    <TR><TD>Please enter the name you would like to search for :</TD>
        <TD><Input Type="Text" Name="name" Size="20"></TD></TR>
    <TR>
      <TD> </TD>
<!--      <TD><INPUT TYPE="submit" NAME="action" VALUE="Submit"></TD>-->
    </TR>
  </TABLE>

</FORM>

EndOfText

} # sub display


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



### DEPRECATED ###

sub getAkaHash {
  my $infile = '/home/postgres/work/get_stuff/person_ace/get_aka/filtered_akas2.ace';
  my %aka_hash;		# filter output of name compinations
  $/ = "";
  open (IN, "<$infile") or die "Cannot open $infile : $!";
  while (my $entry = <IN>) {
    my %last; my %first; my %middle;
  
    my ($person) = $entry =~ m/^Person\tWBPerson(\d+)/;
    my @lines = split/\n/, $entry;
    foreach my $line (@lines) {
      if ($line =~ m/first/) { 
        my ($value) = $line =~ m/first\t(.*) -O /;
        $value = lc($value);
        $first{$value}++;
        my ($init) = $value =~ m/^(\w)/;
        $init = lc($init);
        $first{$init}++;
      }
      if ($line =~ m/middle/) { 
        my ($value) = $line =~ m/middle\t(.*) -O /;
        $value = lc($value);
        $middle{$value}++;
        my ($init) = $value =~ m/^(\w)/;
        $init = lc($init);
        $middle{$init}++;
      }
      if ($line =~ m/last/) { 
        my ($value) = $line =~ m/last\t(.*) -O /;
        $value = lc($value);
        $last{$value}++;
      }
    } # foreach my $line (@lines)
    my $possible = '';
    foreach my $last (sort keys %last) {
      foreach my $first (sort keys %first) {
        if (%middle) { 
          foreach my $middle (sort keys %middle) {
            $possible = "$first"; $aka_hash{$possible}{$person}++;
            $possible = "$middle"; $aka_hash{$possible}{$person}++;
            $possible = "$last"; $aka_hash{$possible}{$person}++;
            $possible = "$last $first"; $aka_hash{$possible}{$person}++;
            $possible = "$last $middle"; $aka_hash{$possible}{$person}++;
            $possible = "$last $first $middle"; $aka_hash{$possible}{$person}++;
            $possible = "$last $middle $first"; $aka_hash{$possible}{$person}++;
            $possible = "$first $last"; $aka_hash{$possible}{$person}++;
            $possible = "$middle $last"; $aka_hash{$possible}{$person}++;
            $possible = "$first $middle $last"; $aka_hash{$possible}{$person}++;
            $possible = "$middle $first $last"; $aka_hash{$possible}{$person}++;
          } # foreach my $middle (sort keys %middle)
        } else { 
          $possible = "$first"; $aka_hash{$possible}{$person}++;
          $possible = "$last"; $aka_hash{$possible}{$person}++;
          $possible = "$last $first"; $aka_hash{$possible}{$person}++;
          $possible = "$first $last"; $aka_hash{$possible}{$person}++;
        }
      } # foreach my $first (sort keys %first)
    }
  } # while (<IN>)
  $/ = "\n";
  return %aka_hash;
} # sub getAkaHash

sub processWild {
  my $input_name = shift;
  print NOT "$input_name\n";
  my @people_ids;
  my @input_parts = split/\s+/, $input_name;
  my %input_parts;
  my %matches;	# keys = wbid, value = amount of matches

  foreach my $input_part (@input_parts) {
    my $ace_query = "Find Person first = $input_part | Middle = $input_part | last = $input_part";
    print NOT "Query : $ace_query\n";

    my @count = split//, $input_part;
    my $count = scalar(@count);

    (@people_ids) = $DB->fetch(	-query=> $ace_query,
				-fill => 1) if $input_part;
    foreach my $person (@people_ids) { 
      $matches{$person}++; 
      unless ($input_parts{$person} > $count) { $input_parts{$person} = $count; }
    }
  }
  print NOT "There are " . scalar(keys %matches) . " match(es).\n";
  foreach my $person (sort {$matches{$b}<=>$matches{$a} || $input_parts{$b} <=> $input_parts{$a}} keys %matches) { 
    print NOT "$person\t";
    print NOT "has $matches{$person} match(es)\tpriority $input_parts{$person}\n";
  } 
  
  unless (@people_ids) {
    print NOT "Sorry, no person named '$input_name', please try again\n" if $input_name;
  }
} # sub processWild

sub processNumber {
  my $input_name = shift;
  my @people;
  my $flag_real_name;
  if ($input_name =~ /(\d*)/) {   # and search just for number
    my $num = "WBPerson".$1;


    @people = $DB->fetch(-class =>'person',
                         -name  => $num,
                         -fill  => 1
                        ) if $input_name;
    $flag_real_name = 0;			# redundant while display routine is copied
  }
  if (@people) { my $count = $#people+1; print "Your search had $count hit(s).<BR>\n"; }

   foreach (sort {$a->Last_name cmp $b->Last_name ||
                   $a->First_name cmp $b->First_name
                 } @people) {
     my ($person) = $flag_real_name ? $DB->fetch(-class =>'person', -name=> $_, -fill=> 1 ) : $_;
     print_report($person);
   }
   unless (@people) {
     print "<FONT COLOR=red>Sorry, no person named '$input_name', please try again</FONT><P>\n" if $input_name;
   }
} # sub processNumber

sub print_report {
  my $person =shift;
  my $unique_link = $person->Standard_name ? $person->Standard_name : $person->Last_name;
  print "PERSON <FONT COLOR=red>$unique_link</FONT> has \n";
  print "ID <A HREF=http://www.wormbase.org/db/misc/etree?name=${person};class=Person>$person</A>.<BR>\n";
} # sub print_report




# sub print_report {
#   my $person =shift;
#   my $unique_link = $person->Standard_name ? $person->Standard_name : $person->Last_name;
# 
#   print start_table({-border=>1,-width=>'80%'});
#   print TR(th({-colspan=>3,-class=>'searchtitle'},a({-href=>"person_name?name=".$unique_link},
# $person->Last_name.", ".$person->First_name)));
# 
#   my @person_headers = $person->col;
#   for my $header(@person_headers) {
#     StartSection($header);
# 
#     my @subheader = $header->col;  # IF IUT IS FROM TRACKING ADD OLD
#     for my $subheader (@subheader) {
#       if (my @details = $subheader->col) {
#         my $flag =0;
#         for (@details) {  # if have several lines for one of the subheaders
#           SubSection($subheader, $_) unless $flag;
#           SubSection($_->right, $_->right->right) if $_->right;
#           SubSection("", $_) if $flag;
#           $flag=1;
#         }                    # end of for details
#       }                      # end of if
#       else {
#         SubSection("",$header->right);
#       }                      # end of else
#     }                        # end of for subheader
#     EndSection();
#   }                          # end for my $header
# 
#   print end_table(),p();
# }                            # end sub print_report
