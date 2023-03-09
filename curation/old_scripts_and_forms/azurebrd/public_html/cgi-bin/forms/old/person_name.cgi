#!/usr/bin/perl

# Trying to get a Person Report (doesn't work yet)

# -*- Mode: perl -*-
# file: person
# C.elegans person report
# Author: Fiona Cunningham Jan 03

use strict;
use lib '../lib';
use vars '$DB';
# use Ace::Browser::AceSubs;    # Need to open db
use Ace;
# use ElegansSubs qw(:DEFAULT PrintRefs); # Need to PrintBottom
use CGI qw(:standard *table escape);

# $DB    = OpenDatabase() || AceError("Couldn't open database.");

my $DB = Ace->connect(-path  =>  '/home/acedb/WS_current',
                      -program => '/home/acedb/bin/tace') || die "Connection failure: ",Ace->error;


my $input_name    = param('name');
my @people;
my $flag_real_name;

if ($input_name =~ /WBPerson(\d*)/i) {   # and search just for number
  my $num = "WBPerson".$1;
  @people = $DB->fetch(-class =>'person',
		       -name  => $num,,
		       -fill  => 1
		      ) if $input_name;
  $flag_real_name =0;
#   PrintTop($people[0], 'Person_name', "Person Report: $people[0]" );
}
else {
  $flag_real_name=1;
  my ($person_name) = $DB->fetch(-class =>'person_name',
				 -name  => $input_name,
				 -fill  => 1
				) if $input_name;


  # http://www.ncbi.nlm.nih.gov/htbin-post/Entrez/query?db=m&form=4&term=May+ST
  # search for pub med references by May ST

  # Uniquify the people returned
  my %seen;
  @people = grep {!$seen{$_}++} $person_name->at('Name[2]') if $person_name;
#  PrintTop($person_name);
#   PrintTop($person_name, 'Person_name', "Person Report: $person_name");
}


print_prompt();
print h3("Your search had", $#people+1,"hit(s).") if @people;
 foreach (sort {$a->Last_name cmp $b->Last_name ||
 		 $a->First_name cmp $b->First_name
 	       } @people) {
   my ($person) = 
     $flag_real_name ? $DB->fetch(-class =>'person', -name=> $_, -fill=> 1 ) : $_;
   print_report($person);
 }

 unless (@people) {
   print p(font({-color=>'red'},
 	       "Sorry, no person named '$input_name', please try again"))
     if $input_name;
 }
# PrintBottom();

exit;


###############################################################################
sub print_prompt {
  print
    start_form({-name=>'form1',-action=>Url(url(-relative=>"/misc/person"))}),
      p("Name in format",i(qq("Last_name")),
	textfield(-name=>'name')
       ),
	 end_form;
}


sub print_report {
  my $person =shift;  
  my $unique_link = $person->Standard_name ? $person->Standard_name : $person->Last_name;

  print start_table({-border=>1,-width=>'80%'});
  print TR(th({-colspan=>3,-class=>'searchtitle'},a({-href=>"person_name?name=".$unique_link}, $person->Last_name.", ".$person->First_name)));

  my @person_headers = $person->col; 
  for my $header(@person_headers) {
    StartSection($header);

    my @subheader = $header->col;  # IF IUT IS FROM TRACKING ADD OLD
    for my $subheader (@subheader) {
      if (my @details = $subheader->col) {
	my $flag =0;
	for (@details) {  # if have several lines for one of the subheaders
	  SubSection($subheader, $_) unless $flag;
	  SubSection($_->right, $_->right->right) if $_->right;
	  SubSection("", $_) if $flag;
	  $flag=1;
	}                    # end of for details
      }                      # end of if
      else {
	SubSection("",$header->right);
      }                      # end of else
    }                        # end of for subheader
    EndSection();
  }                          # end for my $header

  print end_table(),p();
}                            # end sub print_report



