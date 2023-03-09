#!/usr/bin/perl -T

# use strict;
use diagnostics;
use lib '../blib/lib','../blib/arch';
use Ace;

my $db = Ace->connect(-port=>2005,-host=>'brie.cshl.org');
my $counter = 0;
my $acedbemails = "/home/azurebrd/work/newsletter/acedbemails";
open (AEM, ">$acedbemails") or die "Cannot create $acedbemails : $!";

my @letters = qw(n o p q r s t u v w x y z);
foreach my $letter (@letters) {
  my @authors = $db->list('Author',"$letter*");	# get authors
  for (my $i = 0; $i < scalar(@authors); $i++) {
    $counter++;
    print "$counter\n";
    my $object = $db->fetch('Author', "$authors[$i]");	# get author
    my @email_lines =  ($object->at('Address.E_mail'));	# same for email
    for my $j ( 0 .. scalar(@email_lines)-1 ) {
      # print "E_mail \t $email_lines[$j] <BR>\n";
      # $add2[$j] = $AoH[$entry]{add2}[$j] = $email_lines[$j];
      print AEM "Author\t$authors[$i]\nEmail\t$email_lines[$j]\n\n";		# show author entry found
      print "Author\t$authors[$i]\nEmail\t$email_lines[$j]\n\n";		# show author entry found
    }
  } # for (my $i = 0; $i < scalar(@authors); $i++) 
} # foreach my $letter (@letters) 
