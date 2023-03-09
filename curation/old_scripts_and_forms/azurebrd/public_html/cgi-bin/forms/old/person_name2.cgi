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

  if ($action eq 'Submit') {
    (my $oop, my $name) = &getHtmlVar($query, 'name');
    if ($name =~ m/\*/) { 	# if it has a *
      &processFiona($name);
    } else { 			# if it doesn't do simple aka hash thing
      my $search_name = lc($name);
      &processAkaSearch($search_name, $name, %aka_hash);
    }

  } # if ($action eq 'Submit') 
} # sub process

sub processFiona {
  my $input_name = shift;
  my @people;
  my @people_ids;
  my $flag_real_name;
print "INPUT $input_name<BR>\n";
  if ($input_name =~ /WBPerson(\d*)/i) {   # and search just for number
    my $num = "WBPerson".$1;


    @people = $DB->fetch(-class =>'person',
                         -name  => $num,
                         -fill  => 1
                        ) if $input_name;
    $flag_real_name =0;
  #   PrintTop($people[0], 'Person_name', "Person Report: $people[0]" );
  } else {
    $flag_real_name=1;

# print "GBLAH<BR>\n";
    $input_name = "\*$input_name\*";
#     my $ace_query = "Find Person Also_known_as = $input_name";
    my $ace_query = "Find Person first = $input_name | Middle = $input_name | last = $input_name";
#     my @ready_names= $DB->fetch(-query=>$ace_query);
#     foreach (@ready_names) { print "NAME $_<BR>\n"; }
# print "GBLAH<BR>\n";
print "Query : $ace_query<BR>\n";

#     my ($person_name) = $DB->fetch(-class =>'person_name',
#                                    -name  => $input_name,
#                                    -fill  => 1
#                                   ) if $input_name;

#     my ($person_name) = $DB->fetch(	-query=> $ace_query,
# 					-fill => 1) if $input_name;
    (@people_ids) = $DB->fetch(	-query=> $ace_query,
					-fill => 1) if $input_name;

    foreach my $person (@people_ids) { 
      print_report($person);
      print "ID <A HREF=http://www.wormbase.org/db/misc/etree?name=${person};class=Person>$person</A>.<BR>\n";
    } 
#     print STDERR $person_name;

#     # http://www.ncbi.nlm.nih.gov/htbin-post/Entrez/query?db=m&form=4&term=May+ST
#     # search for pub med references by May ST
#   
#     # Uniquify the people returned
#     my %seen;
#     @people = grep {!$seen{$_}++} $person_name->at('Name[2]') if $person_name;
#   #   PrintTop($person_name, 'Person_name', "Person Report: $person_name");
  }


#   print_prompt();
#   print h3("Your search had", $#people+1,"hit(s).") if @people;
  if (@people) { my $count = $#people+1; print "Your search had $count hit(s).<BR>\n"; }

   foreach (sort {$a->Last_name cmp $b->Last_name ||
                   $a->First_name cmp $b->First_name
                 } @people) {
# print "Person $people[0]<BR>\n";
     my ($person) =
       $flag_real_name ? $DB->fetch(-class =>'person', -name=> $_, -fill=> 1 ) : $_;
     print_report($person);
     
   }
  
   unless ((@people) || (@people_ids)) {
     print "<FONT COLOR=red>Sorry, no person named '$input_name', please try again</FONT><P>\n" if $input_name;
#      print p(font({-color=>'red'},
#                  "Sorry, no person named '$input_name', please try again"))
#        if $input_name;
   }
} # sub processFiona

sub print_report {
  my $person =shift;
  my $unique_link = $person->Standard_name ? $person->Standard_name : $person->Last_name;
  print "PERSON <FONT COLOR=red>$unique_link</FONT> has \n";
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
  } else { 
    my @stuff = keys %{ $aka_hash{$search_name} };
    my $stuff = join", WBPerson", @stuff;
    $stuff = 'WBPerson' . $stuff;
    print "<TR><TD>NAME <FONT COLOR=blue>$name</FONT> could be : $stuff </TD></TR>\n";
  }
  print "</TABLE>\n";
} # sub processAkaSearch


sub display {			# show form as appropriate
    print <<"EndOfText";
<FORM METHOD="POST" ACTION="person_name2.cgi">
 
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

