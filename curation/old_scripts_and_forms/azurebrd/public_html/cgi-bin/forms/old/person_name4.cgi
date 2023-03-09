#!/usr/bin/perl

# Search names to find WBPerson Number

# Take a flatfile.ace of WBPerson numbers with possible
# first middle and last names.  Put into a hash of possible
# combinations of valid names (lowercased).  Get input from
# user and see which WBPerson Numbers match that input.
# 2003 03 17

use Jex;			# untaint, getHtmlVar, cshlNew
use strict;
use CGI;
use Ace;
# use ElegansSubs qw(:DEFAULT PrintRefs);

my $query = new CGI;
my $firstflag = 1;
my $DB = Ace->connect(-path  =>  '/home/acedb/ts',
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

  my %aka_hash = &getAkaHash();

  &getAkaAce();

  if ($action eq 'Submit') {
    (my $oop, my $name) = &getHtmlVar($query, 'name');
    if ($name =~ /\d/) { 
      &processNumber($name);
    } elsif ($name =~ m/\*/) { 	# if it has a *
      &processWild($name);
    } else { 			# if it doesn't do simple aka hash thing
      my $search_name = lc($name);
      &processAkaSearch($search_name, $name, %aka_hash);
    }

  } # if ($action eq 'Submit') 
} # sub process


sub processWild {
  my $input_name = shift;
  print "<TABLE>\n";
  print "<TR><TD>INPUT</TD><TD>$input_name</TD></TR>\n";
  my @people_ids;
  my $flag_real_name;
  my @input_parts = split/\s+/, $input_name;
  my %input_parts;
  my %matches;	# keys = wbid, value = amount of matches

  $flag_real_name=1;

  foreach my $input_part (@input_parts) {
    my $ace_query = "Find Person first = $input_part | Middle = $input_part | last = $input_part";
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
#     $search_name =~ s/\s+/\* \*/g;
#     $search_name = '*' . $search_name . '*';
    &processWild($search_name);
  } else { 
    my @stuff = keys %{ $aka_hash{$search_name} };
    foreach (@stuff) { 		# add url link
      my $person = 'WBPerson'.$_;
      $_ = "<A HREF=http://www.wormbase.org/db/misc/etree?name=${person};class=Person>$person</A>";
    }
#     my $stuff = join", WBPerson", @stuff;
#     $stuff = 'WBPerson' . $stuff;
    my $stuff = join", ", @stuff;
    print "<TR><TD>NAME <FONT COLOR=red>$name</FONT> could be : $stuff </TD></TR>\n";
  }
  print "</TABLE>\n";
} # sub processAkaSearch


sub display {			# show form as appropriate
    print <<"EndOfText";
<FORM METHOD="POST" ACTION="person_name4.cgi">
 
  <TABLE ALIGN="center"> 
    <TR><TD>Please enter the name you would like to search for :</TD>
        <TD><Input Type="Text" Name="name" Size="20"></TD></TR>
    <TR>
      <TD> </TD>
      <TD><INPUT TYPE="submit" NAME="action" VALUE="Submit"></TD>
    </TR>
  </TABLE>

</FORM>

EndOfText

} # sub display

sub getAkaAce {
#   my $ace_query = "Find Person first = $input_part | Middle = $input_part | last = $input_part";
#   print "<TR><TD>Query : </TD><TD>$ace_query</TD></TR>\n";
# 
#   my @count = split//, $input_part;
#   my $count = scalar(@count);
# 
#   (@people_ids) = $DB->fetch(	-query=> $ace_query,
# 				-fill => 1) if $input_part;
#   foreach my $person (@people_ids) { 
#     $matches{$person}++; 
#     unless ($input_parts{$person} > $count) { $input_parts{$person} = $count; }
#   }

  my @people_first = $DB->list('Person');
  my $firsts = $people_first[0]->First_name->fetch->asString;
  print "EEP $firsts<BR>\n";
#   foreach (@firsts) { print "EEP $_->fetch->asString<BR>\n"; }
#   print "EEP $people_first[0]->first <BR>\n";
#   if ($people_first[0]->first) { print "$people_first[0] HAS $people_first[0]->first(1) <BR>\n"; }	
  
} # sub getAkaAce

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

