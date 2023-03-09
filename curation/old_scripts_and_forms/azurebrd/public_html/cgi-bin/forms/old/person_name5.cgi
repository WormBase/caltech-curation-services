#!/usr/bin/perl

# Search names to find WBPerson Number

# Take a flatfile.ace of WBPerson numbers with possible
# first middle and last names.  Put into a hash of possible
# combinations of valid names (lowercased).  Get input from
# user and see which WBPerson Numbers match that input.
# 2003 03 17
#
# Cleaned up and using acedb for all searches.  The 
# &processAkaSearch is really really slow because it takes 
# about 15 seconds to load all values from acedb into a hash.
# There is probably a better way to do it since the postgres
# equivalent takes about 1 second. It doesn't look like this
# will ever be implemented, so I'm not looking into it.
#  2003 03 25

use Jex;			# untaint, getHtmlVar, cshlNew
use strict;
use CGI;
use Ace;

use Pg;
my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;


my $query = new CGI;
my $firstflag = 1;
my $DB = Ace->connect(-path  =>   '/home/acedb/ts2',
                      -program => '/home/acedb/bin/tace') || die "Connection failure: ",Ace->error;

print "Content-type: text/html\n\n";
my $title = 'Person Search Form';
my ($header, $footer) = &cshlNew($title);

print "$header\n";		# make beginning of HTML page
&process();			# see if anything clicked
&display();			# show form as appropriate
print "$footer"; 		# make end of HTML page

sub process {			# see if anything clicked
  my $action;			# what user clicked
  unless ($action = $query->param('action')) { $action = 'none'; }
  if ($action) { 
    (my $oop, my $name) = &getHtmlVar($query, 'name');
    unless ($name =~ m/\w/) {
      print "Please enter a search parameter.<BR>\n";
    } else { 
      if ($name =~ /\d/) { 
        &processNumber($name);
      } elsif ($name =~ m/[\*\?]/) { 	# if it has a * or ?
        &processWild($name);
      } else { 			# if it doesn't do simple aka hash thing
        my %aka_hash = &getAkaAce();
        my $search_name = lc($name);
        &processAkaSearch($search_name, $name, %aka_hash);
      }
    }
  } # if ($action eq 'Submit') 
} # sub process

sub getAkaAce {
  my @params = qw(last first middle);
  my @people = $DB->list('Person');
  my %aka_hash;
  foreach my $person (@people) {
    my %filter;
    my $lasts = $person->Aka_last->fetch->asString;
    foreach my $param (@params) {
      my $table = 'Aka_' . $param;
      if ($person->$table) { 
        my (@param_vals) = $person->$table;
        foreach my $param_val (@param_vals) {
          $param_val = lc($param_val);
          $filter{$param}{$param_val}++;
          my ($init) = $param_val =~ m/^(\w)/;
          $filter{$param}{$init}++;
        }
      }
    }
    my $possible;
    foreach my $last (sort keys %{ $filter{last}}) {
      foreach my $first (sort keys %{ $filter{first}}) {
        $possible = "$first"; $aka_hash{$possible}{$person}++;
        $possible = "$last"; $aka_hash{$possible}{$person}++;
        $possible = "$last $first"; $aka_hash{$possible}{$person}++;
        $possible = "$first $last"; $aka_hash{$possible}{$person}++;
        if ( $filter{middle}) { 
          foreach my $middle (sort keys %{ $filter{middle}}) {
            $possible = "$middle"; $aka_hash{$possible}{$person}++;
            $possible = "$first $middle"; $aka_hash{$possible}{$person}++;
            $possible = "$middle $first"; $aka_hash{$possible}{$person}++;
            $possible = "$last $middle"; $aka_hash{$possible}{$person}++;
            $possible = "$middle $last"; $aka_hash{$possible}{$person}++;
            $possible = "$last $first $middle"; $aka_hash{$possible}{$person}++;
            $possible = "$last $middle $first"; $aka_hash{$possible}{$person}++;
            $possible = "$first $middle $last"; $aka_hash{$possible}{$person}++;
            $possible = "$first $last $middle"; $aka_hash{$possible}{$person}++;
            $possible = "$middle $first $last"; $aka_hash{$possible}{$person}++;
            $possible = "$middle $last $first"; $aka_hash{$possible}{$person}++;
          } # foreach my $middle (@{ $filter{middle}})
        } # if (@{ $filter{middle}})
      } # foreach my $first (@{ $filter{first}})
    } # foreach my $last (@{ $filter{last}})
  } # foreach my $person (@people)
  return %aka_hash;
} # sub getAkaAce

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

sub processAkaSearch {
  my ($search_name, $name, %aka_hash) = @_;
  print "<TABLE ALIGN=center>\n";
  unless ($aka_hash{$search_name}) { 
    print "<TR><TD>NAME <FONT COLOR=red>$name</FONT> NOT FOUND</TD></TR>\n";
    my @names = split/\s+/, $search_name; $search_name = '';
    foreach my $name (@names) {
      if ($name =~ m/^[a-zA-Z]$/) { $search_name .= "$name "; }
      else { $search_name .= '*' . $name . '* '; }
    }
    &processWild($search_name);
  } else { 
    my @stuff = keys %{ $aka_hash{$search_name} };
    foreach (@stuff) { $_ = "<A HREF=http://www.wormbase.org/db/misc/etree?name=${_};class=Person>$_</A>"; }
      # add url link
    my $stuff = join", ", @stuff;
    print "<TR><TD>NAME <FONT COLOR=red>$name</FONT> could be : $stuff </TD></TR>\n";
  }
  print "</TABLE>\n";
} # sub processAkaSearch

sub processWild {
  my $input_name = shift;
  print "<TABLE>\n";
  print "<TR><TD>INPUT</TD><TD>$input_name</TD></TR>\n";
  my @people_ids;
  my @input_parts = split/\s+/, $input_name;
  my %input_parts;
  my %matches;	# keys = wbid, value = amount of matches

  foreach my $input_part (@input_parts) {
    my $ace_query = "Find Person Aka_first = $input_part | Aka_middle = $input_part | Aka_last = $input_part";
    print "<TR><TD>Query : </TD><TD>$ace_query</TD></TR>\n";

    my @count = split//, $input_part;
    my $count = scalar(@count);

    (@people_ids) = $DB->fetch(	-query=> $ace_query,
				-fill => 1) if $input_part;
    foreach my $person (@people_ids) { 
      $matches{$person}++; 
      unless ($input_parts{$person} > $count) { $input_parts{$person} = $count; }
    }
  }
  print "<TR><TD></TD><TD>There are " . scalar(keys %matches) . " match(es).</TD></TR>\n";
  print "<TR></TR>\n";
  print "</TABLE>\n";
  print "<TABLE border=2 cellspacing=5>\n";
  foreach my $person (sort {$matches{$b}<=>$matches{$a} || $input_parts{$b} <=> $input_parts{$a}} keys %matches) { 
    print "<TR><TD><A HREF=http://www.wormbase.org/db/misc/etree?name=${person};class=Person>$person</A></TD>\n";
    print "<TD>has $matches{$person} match(es)</TD><TD>priority $input_parts{$person}</TD></TR>\n";
  } 
  print "</TABLE>\n";
  
  unless (@people_ids) {
    print "<FONT COLOR=red>Sorry, no person named '$input_name', please try again</FONT><P>\n" if $input_name;
  }
} # sub processWild

sub display {			# show form as appropriate
    print <<"EndOfText";
<FORM METHOD="POST" ACTION="person_name5.cgi">
  <TABLE ALIGN="center"> 
    <TR><TD>Please enter the name you would like to search for :</TD>
        <TD><Input Type="Text" Name="name" Size="20"></TD></TR>
  </TABLE>
</FORM>
EndOfText
} # sub display

