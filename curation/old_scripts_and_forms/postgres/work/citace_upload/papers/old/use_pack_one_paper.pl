#!/usr/bin/perl

# use the get_paper_ace.pm module from /home/postgres/work/citace_upload/papers/ 
# to dump the papers, abstracts (LongText objects), and errors associated with
# them.  2005 07 13
#
# Change to default get all papers, not just valid ones.  2005 11 10
#
# Change to default get only valid papers to -D merged papers from citace.  
# For Andrei.  2006 05 24

use strict;
use Jex;

my $date = &getSimpleSecDate();
my $start_time = time;
my $estimate_time = time + 197;
my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime($estimate_time);             # get time
if ($sec < 10) { $sec = "0$sec"; }    # add a zero if needed
if ($min < 10) { $min = "0$min"; }    # add a zero if needed
print "START $date -> Estimate $hour:$min:$sec\n";

$date = &getSimpleDate();

use lib qw( /home/postgres/work/citace_upload/papers/ );
use get_paper_ace;

# my ($all_entry, $long_text, $err_text) = &getPaper('00026991');
# my ($all_entry, $long_text, $err_text) = &getPaper('00024414');	# 2008 06 04
my ($all_entry, $long_text, $err_text) = &getPaper('00003425');		# 2010 03 26
print "$all_entry\n";

__END__


my $outfile = 'papers.ace.' . $date;
my $outlong = 'abstracts.ace.' . $date;
my $errfile = 'err.out.' . $date;
open (OUT, ">$outfile") or die "Cannot create $outfile : $!\n";
open (LON, ">$outlong") or die "Cannot create $outlong : $!\n";
open (ERR, ">$errfile") or die "Cannot create $errfile : $!\n";


# my ($all_entry, $long_text, $err_text) = &getPaper('00000003');
my ($all_entry, $long_text, $err_text) = &getPaper('valid');
# my ($all_entry, $long_text, $err_text) = &getPaper('all');

print OUT "$all_entry\n";
print LON "$long_text\n";
print ERR "$err_text\n";

close (OUT) or die "Cannot close $outfile : $!";
close (LON) or die "Cannot close $outlong : $!";
close (ERR) or die "Cannot close $errfile : $!";

$date = &getSimpleSecDate();
my $end_time = time;
my $diff_time = $end_time - $start_time;
print "DIFF $diff_time\n";
print "END $date\n";

