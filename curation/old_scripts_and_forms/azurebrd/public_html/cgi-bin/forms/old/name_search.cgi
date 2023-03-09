#!/usr/bin/perl

# Search names to find WBPerson Number

# Take a flatfile.ace of WBPerson numbers with possible
# first middle and last names.  Put into a hash of possible
# combinations of valid names (lowercased).  Get input from
# user and see which WBPerson Numbers match that input.
# 2003 03 17
#
# NO CHANGE.  This form matches exact matches from PG only
# Doesn't find partial matches.  (K Brad fails)  2003 06 20

use Jex;			# untaint, getHtmlVar, cshlNew
use strict;
use CGI;

my $query = new CGI;
my $firstflag = 1;

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

  my %aka_hash = &getAkaHash();

# my $name = 'Keith Bradnam';
# 
# my @names = ('Keith Bradnam', 'R Lee', 'Bob');
# 
# foreach my $name (@names) {
#   unless ($aka_hash{$name}) { 
#     print "$name NOT FOUND\n"; 
#   } else { 
#     foreach my $id (sort keys %{ $aka_hash{$name}}) {
#       print "$name could be WBPerson$id\n"; 
#     }
#   }
# }


  if ($action eq 'Submit') {
    (my $oop, my $name) = &getHtmlVar($query, 'name');
    my $search_name = lc($name);
    print "<TABLE ALIGN=center>\n";
    unless ($aka_hash{$search_name}) { 
#       print "$name NOT FOUND\n"; 
      print "<TR><TD>NAME <FONT COLOR=red>$name</FONT> NOT FOUND</TD></TR>\n";
    } else { 
      my @stuff = keys %{ $aka_hash{$search_name} };
      my $stuff = join", WBPerson", @stuff;
      $stuff = 'WBPerson' . $stuff;
      print "<TR><TD>NAME <FONT COLOR=blue>$name</FONT> could be : $stuff </TD></TR>\n";
    }
    print "</TABLE>\n";
  } # if ($action eq 'Submit') 
} # sub process



sub display {			# show form as appropriate
    print <<"EndOfText";
<FORM METHOD="POST" ACTION="name_search.cgi">
 
  <TABLE ALIGN="center"> 
    <TR><TD>Please enter the name you would like to search for :</TD>
        <TD><Input Type="Text" Name="name" Size="20"></TD></TR>
    <TR>
      <TD> </TD>
      <TD><INPUT TYPE="submit" NAME="action" VALUE="Submit">
        <INPUT TYPE="reset"></TD>
    </TR>
  </TABLE>

</FORM>

EndOfText

} # sub display

sub getAkaHash {
  my $infile = '/home/postgres/work/get_stuff/person_ace/get_aka/filtered_akas.ace';
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

