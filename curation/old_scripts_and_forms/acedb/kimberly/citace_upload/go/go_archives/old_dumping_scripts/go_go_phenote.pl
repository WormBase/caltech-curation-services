#!/usr/bin/perl

# Based on go_curation_go_dumper.pl.20060209
# Now using the go_curation_go.pm   2006 08 03
# Updated for phenote  2008 04 22


use strict;
use Jex;

use lib qw( /home/acedb/ranjana/citace_upload/go_curation/ );
use go_go_phenote;

&get_go('all');
# my $entry = &get_go('WBGene00000011');
# my $entry = &get_go('WBGene00003418');
# print "E $entry E\n";

# my $date = &getSimpleSecDate();
# my $start_time = time;
# my $estimate_time = time + 157;
# my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime($estimate_time);             # get time
# if ($sec < 10) { $sec = "0$sec"; }    # add a zero if needed
# print "START $date -> Estimate $hour:$min:$sec\n";
# 
# $date = &getSimpleDate();



# my ($all_entry, $long_text, $err_text) = &getPaper('00000003');
# my ($all_entry, $long_text, $err_text) = &getPaper('valid');
# my ($all_entry, $long_text, $err_text) = &getPaper('all');

# my ($out) = &get_go('WBGene00000001');
# print "$out\n";
# 
# 
# $date = &getSimpleSecDate();
# my $end_time = time;
# my $diff_time = $end_time - $start_time;
# print "DIFF $diff_time\n";
# print "END $date\n";

