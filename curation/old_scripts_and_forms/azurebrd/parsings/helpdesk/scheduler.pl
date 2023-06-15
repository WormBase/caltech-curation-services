#!/usr/bin/perl

# take a queue of help desk people and print them out from date to date with 14 day increments
# 2009 01 05
#
# added abigail, switched from midnight to noon to avoid daylight savings time issue.  2009 09 08
#
# added shi xiaoqi, bill nash, chris grove ;  removed michael mueller.  2009 10 01
#
# added ruihua fang.  2010 01 11
#
# added Kevin Howe, Paul Kersey, and Matt Berriman.  2010 08 20
#
# added Daniela Raciti, removed Jolene Fernandes.  2010 09 08
#
# removed Paul Kersey and Matt Berrima.  2010 12 07
#
# added Arun Rangarajan and Yuling Li.  Xiaodong served three weeks while we sorted it out, she 
# wanted the dates shifted by a week instead of Arun serving 1 week now and 3 weeks next time.
# 2010 12 09
#
# removed Norie.  2011 10 19
#
# removed Ruihua, Arun, and Xiaoqi  2012 01 04
#
# remove Bill Nash, added James Done  2012 04 19
#
# add JD Wong  2012 11 01
#
# add Joachim Baran  2013 04 22
#
# remove Joachim Baran  2014 01 24
#
# add Eleanor Stanley  2014 03 06
#
# add Bruce Bolt and Alessandra Traini	2014 03 13
#
# removed JD Wong, added Scott Cain  2014 04 30
#
# added Sibyl Gao  2014 06 05
#
# removed Eleanor Stanley  2014 06 19
#
# added Thomas Down  2014 08 08
# removed Abigail Cabunoc  2014 08 15
#
# removed Alessandra Traini  2014 10 15
#
# added Jane Lomax  2015 03 04
#
# added Myriam Shafie, Matthew Russell, Adam Wright. removed James Done, Thomas Down.  2016 03 15
#
# removed Jane Lomax  2016 07 20
#
# added Marie-Claire Harrison	2018 09 10  
#
# removed Kevin Howe  2019 02 13
#
# removed Marie-Claire Harrison	(late) 2020 01 15  
#
# removed Nick Stiffler, removed Matthew Russell, removed Gary Williams, added Mark Quinton-Tulloch  2020 06 01
# 
# removed Matej Vucak, not around anymore.  2023 04 03
#
# added Steph Brown, parasite.  2023 06 15


# current queue :
# Raymond Lee, Steph Brown, Scott Cain, Karen Yook, Wen Chen, Mark Quinton-Tulloch, Dionysis Grigoriadis, Adam Wright, Juancarlos Chan, Cecilia Nakamura, Stavros Diamantakis, Gary Schindelman, Daniel Wang, Todd Harris, Ranjana Kishore, Paul Davis, Kimberly Van Auken, Chris Grove, Daniela Raciti, Valerio Arnaboldi, Jae Cho. 

use strict;
use Time::Local;

my @ppl;

push @ppl, "Chris Grove";		# 2010 01 04  new person	(message 2009 09 30)
push @ppl, "Daniela Raciti";		# 2010 09 08  new person
push @ppl, "Valerio Arnaboldi";		# 2017 09 06  new person
push @ppl, "Jae Cho";			# 2017 09 06  new person
push @ppl, "Raymond Lee";
push @ppl, "Steph Brown";		# 2023 06 16  new person parasite
push @ppl, "Scott Cain";		# 2014 04 30  added to list
# push @ppl, "Manuel Luypaert";		# 2020 06 01  added to list	# don't add yet by Kevin  2020 06 01	# don't add at all 2020 09 04
# push @ppl, "Magdalena Zarowieki";	# 2020 09 04  added to list	# removed 2023 01 19
push @ppl, "Karen Yook";
push @ppl, "Wen Chen";
push @ppl, "Mark Quinton-Tulloch";	# 2020 05 07  added to list	# don't add yet by Kevin  2020 06 01	# don't add at all 2020 09 04	# 2021 05 50 Magada says to add
push @ppl, "Dionysis Grigoriadis";	# 2021 04 19  not added to list until 2021 05 20 when Magda approved it
# push @ppl, "Adam Wright";		# 2016 03 15			# removed by Todd due to low percentage for WB sometime before 2022 07 21
# push @ppl, "Sibyl Gao";		# 2014 06 05  added to list	# left 2021 08
push @ppl, "Juancarlos Chan";
push @ppl, "Cecilia Nakamura";
push @ppl, "Stavros Diamantakis";	# 2020 09 04  added to list
# push @ppl, "Andres Becerra";		# 2021 06 17  not added to list, Magda says full time alliance
# push @ppl, "Faye Rodgers";		# 2017 01 04  added to list by Kevin Howe on wiki	# left 2021 09 02
push @ppl, "Gary Schindelman";
push @ppl, "Daniel Wang";
push @ppl, "Todd Harris";
push @ppl, "Ranjana Kishore";
# push @ppl, "Paul Davis";		# 2022 07 21  left sometime before
# push @ppl, "Matej Vucak";		# 2022 07 21  added to list	# removed 2023 04 03, not sure when he left
push @ppl, "Kimberly Van Auken";

# push @ppl, "Matthew Russell";		# 2016 03 15			(removed 2020 06 01)
# push @ppl, "Marie-Claire Harrison";	# 2018 09 10  new person	(removed late 2020 01 15)
# push @ppl, "Gary Williams";		# will leave 2020 11 01		(removed 2020 06 01)
# push @ppl, "Nick Stiffler";		# 2019 11 12  added to list	(removed 2020 01 15, microPub employee)
# push @ppl, "Michael Paulini";		# will leave 2020 11 01		(removed 2020 09 04)
# push @ppl, "Kevin Howe";		# 2010 08 20  new person	# 2019 02 13 PI
# push @ppl, "April Jauhal";		# 2018 02 22	# removed 2018 11 20
# push @ppl, "Mary Ann Tuli";		# 2009 06 23 # left 2017 at some point
# push @ppl, "JD Wong";			# 2012 11 01  added to list	# removed 2014 04 30 (left before this)
# push @ppl, "Jolene Fernandes";	# 2010 09 08  she's gone
# push @ppl, "Hans-Michael Mueller";	# removed at Karen's request  2009 10 01
# push @ppl, "Xiaodong Wang";		# removed 2016 04 07
# push @ppl, "Arun Rangarajan";		# 2012 01 04 last day in December
# push @ppl, "Tamberlyn Bieri";		# removed 2014 01 24
# push @ppl, "Thomas Down";		# 2014 08 08 started 2014 08 01  removed 2016 03 15
# push @ppl, "Sheldon McKay";
# push @ppl, "Norie de la Cruz";	# 2011 10 19 left WB sometime ago
# push @ppl, "Will Spooner";
# push @ppl, "Darin Blasiar";		# 2009 06 23  left WB weeks ago
# push @ppl, "James Done";		# 2012 04 19  removed 2016 03 15
# push @ppl, "Anthony Rogers";		# 2010 04 26  left WB
# push @ppl, "Abigail Cabunoc";		# 2009 09 08  new person		# left 2014 08 15
# push @ppl, "Shi Xiaoqi";		# 2009 09 17  new person		# 2012 01 04 last day in Jan 13
# push @ppl, "Bill Nash";		# 2009 10 01  new person		# he left sometime before 2012 04 
# push @ppl, "Ruihua Fang";		# switched away from textpresso at some point  2010 01 11
# push @ppl, "Joachim Baran";		# 2013 04 22  new person	# left 2014 01 24
# push @ppl, "Phil Ozersky";		# removed 2014 01 24
# push @ppl, "Eleanor Stanley";		# added 2014 03 06		# left 2014 06 19
# push @ppl, "Bruce Bolt";		# added 2014 03 13		# left 2017 07 17
# push @ppl, "Alessandra Traini";		# added 2014 03 13	# left 2014 10 15
# push @ppl, "Paul Kersey";		# 2010 08 20  new person	# PI  2010 12 07
# push @ppl, "Matt Berrima";		# 2010 08 20  new person	# PI  2010 12 07
# push @ppl, "Yuling Li";			# 2010 12 09  added to list	# left 2016 or 2017
# push @ppl, "Erich Schwarz";		# 2010 04 26  left WB
# push @ppl, "Jane Lomax";		# 2015 03 04  new person	# left 2016 07 20
# push @ppl, "Andrei Petcherski";
# push @ppl, "Igor Antoshechkin";
# push @ppl, "Myriam Shafie";		# 2016 03 15		# left 2017 07 17



# my $date = '20090817:12';		# losing an hour / day if midnight to daylight savings, use noon
# my $date = '20100426:12';		# losing an hour / day if midnight to daylight savings, use noon
# my $date = '20100802:12';		# losing an hour / day if midnight to daylight savings, use noon
# my $date = '20101129:12';		# losing an hour / day if midnight to daylight savings, use noon
# my $date = '20120109:12';		# losing an hour / day if midnight to daylight savings, use noon
# my $date = '20120402:12';		# losing an hour / day if midnight to daylight savings, use noon
# my $date = '20121015:12';		# losing an hour / day if midnight to daylight savings, use noon
# my $date = '20130401:12';		# losing an hour / day if midnight to daylight savings, use noon
# my $date = '20140217:12';		# losing an hour / day if midnight to daylight savings, use noon
# my $date = '20140414:12';		# losing an hour / day if midnight to daylight savings, use noon
# my $date = '20140526:12';		# losing an hour / day if midnight to daylight savings, use noon
# my $date = '20140721:12';		# losing an hour / day if midnight to daylight savings, use noon
# my $date = '20150202:12';		# losing an hour / day if midnight to daylight savings, use noon
# my $date = '20150202:12';		# losing an hour / day if midnight to daylight savings, use noon
# my $date = '20160229:12';		# losing an hour / day if midnight to daylight savings, use noon
# my $date = '20170814:12';		# losing an hour / day if midnight to daylight savings, use noon
# my $date = '20180618:12';		# losing an hour / day if midnight to daylight savings, use noon
# my $date = '20190211:12';		# losing an hour / day if midnight to daylight savings, use noon
# my $date = '20191104:12';		# losing an hour / day if midnight to daylight savings, use noon
# my $date = '20200518:12';		# losing an hour / day if midnight to daylight savings, use noon
# my $date = '20200824:12';		# losing an hour / day if midnight to daylight savings, use noon
# my $date = '20210419:12';		# losing an hour / day if midnight to daylight savings, use noon
# my $date = '20220627:12';		# losing an hour / day if midnight to daylight savings, use noon
# my $date = '20230109:12';		# losing an hour / day if midnight to daylight savings, use noon
my $date = '20231211:12';		# losing an hour / day if midnight to daylight savings, use noon
my $secs = &toSeconds($date);
my $timePeriod = 86400 * 14;
while ($date < '20250101') {
  $secs += $timePeriod;
  $date = &toDate($secs);
  my ($year, $mon, $day) = $date =~ m/(\d{4})(\d{2})(\d{2})/;
  my $person = shift @ppl; push @ppl, $person;
#   print "$year-$mon-$day $person\n\n";
  print "|-\n|$year-$mon-$day\n|$person\n|\n";
} # while ($date < '20100101')

sub toSeconds {
  my $date = shift;
  my ($year, $mon, $day, $hour) = $date =~ m/^(\d\d\d\d)(\d\d)(\d\d):(\d\d)/;
  $mon -= 1;
  my $now = &timelocal(0,0,$hour,$day,$mon,$year);
  return $now;
}

sub toDate {
  my $time = shift;                     # set time
  my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) =
          localtime($time);             # get time
  my $sam = $mon+1;                     # get right month
  $year = 1900+$year;                   # get right year in 4 digit form
  if ($sam < 10) { $sam = "0$sam"; }    # add a zero if needed
  if ($mday < 10) { $mday = "0$mday"; } # add a zero if needed
  my $shortdate = "${year}${sam}${mday}";   # get final date
  return $shortdate;
}

