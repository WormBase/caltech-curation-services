#!/usr/bin/perl

# generate some lifestage objects for Daniela.  2014 04 24

use strict;

sub pad7Zeros {         # take a number and pad to 7 digits
  my $number = shift;
  if ($number =~ m/^0+/) { $number =~ s/^0+//g; }               # strip leading zeros
  if ($number < 10) { $number = '000000' . $number; }
  elsif ($number < 100) { $number = '00000' . $number; }
  elsif ($number < 1000) { $number = '0000' . $number; }
  elsif ($number < 10000) { $number = '000' . $number; }
  elsif ($number < 100000) { $number = '00' . $number; }
  elsif ($number < 1000000) { $number = '0' . $number; }
  return $number;
} # sub pad7Zeros

my $id = 111;
for my $min (1 .. 550) {
  print "[Term]\n";
  my $previousMin = $min - 1;
  my $previousId = 'WBls:' . &pad7Zeros($id);
  $id++; 
  my $objId = 'WBls:' . &pad7Zeros($id); 
  print "id: $objId\n";
  print "name: $min min post first-cleavage Ce\n";
  my $nth = $min;  
  if ($min =~ m/1$/) { $nth .= 'st'; }
    elsif ($min =~ m/2$/) { $nth .= 'nd'; }
    elsif ($min =~ m/3$/) { $nth .= 'rd'; }
    else { $nth .= 'th'; }
  print qq(def: "The time period encompassing the $nth minute post first cleavage at 20 Centigrade with respect to Sulston's lineage tree" [WB:dr, WB:WBPaper00000653]\n);
  print qq(relationship: part_of );
  if ($min < 101) { print qq(WBls:0000005 ! blastula embryo Ce\n); }
    elsif ($min < 291)  { print qq(WBls:0000010 ! gastrulating embryo Ce\n); }
    elsif ($min < 351)  { print qq(WBls:0000013 ! enclosing embryo Ce\n); }
    elsif ($min < 391)  { print qq(WBls:0000016 ! bean embryo Ce\n); }
    elsif ($min < 421)  { print qq(WBls:0000017 ! comma embryo Ce\n); }
    elsif ($min < 461)  { print qq(WBls:0000018 ! 1.5-fold embryo Ce\n); }
    elsif ($min < 521)  { print qq(WBls:0000019 ! 2-fold embryo Ce\n); }
    elsif ($min >= 521) { print qq(WBls:0000020 ! 3-fold embryo Ce\n); }
  if ($min > 1) { print qq(relationship: starts_at_end_of $previousId ! $previousMin min post first-cleavage Ce\n); }
  print qq(created_by: danielaraciti\n);
  print qq(creation_date: 2014-04-25T09:29:36Z\n);
  print "\n";
} # for my $min (1 .. 550)

__END__

1) [Term] #for all
2) id: from WBls:0000112 on
3) name: 1 min post first-cleavage Ce # progressive till 550 min post first-cleavage Ce

4) def: "The time period encompassing the first minute post first cleavage at 20 Centigrade with respect to Sulston's lineage tree [WB:dr]" # progressive till "The time period encompassing the 550th minute post first cleavage at 20 Centigrade with respect to Sulston's lineage tree [WB:dr]" what changes in the def is the numbering first second third, 4th, 5th, 6th. 

5) relationship: part_of

until 100 minutes the relationship should be: relationship: part_of WBls:0000005 ! blastula embryo Ce 
from 101 minutes till 290 minutes the relationship should be: relationship: part_of WBls:0000010 ! gastrulating embryo Ce 
from 291 minutes till 350 minutes the relationship should be: relationship: part_of WBls:0000013 ! enclosing embryo Ce  
from 351 minutes till 390 minutes the relationship should be: relationship: part_of WBls:0000016 ! bean embryo Ce  
from 391 minutes till 420 minutes the relationship should be: relationship: part_of WBls:0000017 ! comma embryo Ce  
from 421 minutes till 460 minutes the relationship should be: relationship: part_of WBls:0000018 ! 1.5-fold embryo Ce 
from 461 minutes till 520 minutes the relationship should be: relationship: part_of WBls:0000019 ! 2-fold embryo Ce  
from 521 minutes on the relationship should be: relationship: part_of WBls:0000020 ! 3-fold embryo Ce  



6) relationship: starts_at_end_of # this relationship should be in all terms from 2 min post first-cleavage Ce on -meaning NOT in  1 min post first-cleavage Ce. And the numbering of life stage is always the one that precedes e.g.:

id: WBls:0000113
name: 2 min post first-cleavage Ce
relationship: starts_at_end_of WBls:0000112 ! 1 min post first-cleavage Ce

id: WBls:0000114
name: 3 min post first-cleavage Ce
relationship: starts_at_end_of WBls:0000113 ! 2 min post first-cleavage Ce


7) created_by: danielaraciti # for all

8) creation_date: 2014-04-25T09:29:36Z # could have all the same creation date or spaced by 1 sec


there will be one more thing I need to add to all the stages which is a paper reference but i need more time to check other ontologies and see how the info is stored. we can add that later on as it will be identical for all.
thank you!


here are 3 example objects and below instructions to generate them all. Let me know if you need additional instructions.

[Term]
id: WBls:0000112
name: 1 min post first-cleavage Ce
def: "The time period encompassing the first minute post first cleavage at 20 Centigrade with respect to Sulston's lineage tree" [WB:dr]
relationship: part_of WBls:0000005 ! blastula embryo Ce
created_by: danielaraciti
creation_date: 2014-04-22T09:29:36Z

[Term]
id: WBls:0000113
name: 2 min post first-cleavage Ce
def: "The time period encompassing the second minute post first cleavage at 20 Centigrade with respect to Sulston's lineage tree" [WB:dr]
relationship: part_of WBls:0000005 ! blastula embryo Ce
relationship: starts_at_end_of WBls:0000112 ! 1 min post first-cleavage Ce
created_by: danielaraciti
creation_date: 2014-04-22T09:29:36Z


[Term]
id: WBls:0000114
name: 3 min post first-cleavage Ce
def: "The time period encompassing the third minute post first cleavage at 20 Centigrade with respect to Sulston's lineage tree" [WB:dr]
relationship: part_of WBls:0000005 ! blastula embryo Ce
relationship: starts_at_end_of WBls:0000113 ! 2 min post first-cleavage Ce
created_by: danielaraciti
creation_date: 2014-04-22T09:29:36Z


