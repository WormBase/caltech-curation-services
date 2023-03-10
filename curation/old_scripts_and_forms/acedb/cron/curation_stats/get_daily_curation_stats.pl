#!/usr/bin/perl

# for Paul and group for quarterly reports, get daily page view of curation status.  2013 08 01
#
# cronjob
# 0 5 * * * /home/acedb/cron/curation_stats/get_daily_curation_stats.pl


use strict;
use LWP::Simple;
use Jex;

my $date = &getSimpleDate();
my $url = 'http://tazendra.caltech.edu/~postgres/cgi-bin/curation_status.cgi?select_curator=two1823&action=Curation+Statistics+Page&checkbox_all_datatypes=all&checkbox_all_flagging_methods=all';
my $pageData = get $url;
my $outfile = '/home/acedb/cron/curation_stats/files/curation_status.' . $date . '.html';
open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
print OUT $pageData;
close (OUT) or die "Cannot close $outfile : $!";

