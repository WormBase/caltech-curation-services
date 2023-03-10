#!/usr/bin/perl

# get wbbt.obo on a cronjob in case cshl is down sometimes.  2008 10 28
#
# changed to github, added SSLeay.  2011 06 27
# 
# updated to https://raw.githubusercontent.com/obophenotype/c-elegans-gross-anatomy-ontology/master/wbbt.obo  2020 04 24
#
# 0 2 * * mon,tue,wed,thu,fri,sat,sun /home/acedb/cron/get_wbbt_obo.pl


use strict;
use LWP::Simple;
use Jex;
use Crypt::SSLeay;                              # for LWP to get https


# my $file = get "http://brebiou.cshl.edu/viewcvs/*checkout*/Wao/WBbt.obo?rev=HEAD&content-type=text/plain";
# my $file = get "https://raw.github.com/raymond91125/Wao/master/WBbt.obo";
my $file = get "https://raw.githubusercontent.com/obophenotype/c-elegans-gross-anatomy-ontology/master/wbbt.obo";

if ($file =~ m/\[Term\].*?\nid: WBbt\:\d{7}/) {
  my $outfile = 'wbbt.obo';
  my $directory = '/home/acedb/cron';
  chdir ($directory) or die "Cannot switch to $directory : $!";
  open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
  print OUT $file;
  close (OUT) or die "Cannot close $outfile : $!";
} else {
#   my $email = 'azurebrd@tazendra.caltech.edu';
  my $email = 'raymond@caltech.edu';
  my $user = 'get_wbbt_obo.pl';
  my $subject = 'Failed wbbt update';
  my $body = '/home/acedb/cron/get_wbbt_obo.pl failed';
  &mailer($user, $email, $subject, $body);
}

