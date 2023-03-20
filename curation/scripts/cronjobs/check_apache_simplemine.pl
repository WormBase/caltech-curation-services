#!/usr/bin/env perl

# For wen, look at apache logs for IP of users of simplemine.cgi and email her the IPs.
# Every first of the month at 1am.
# 
# 0 1 1 * * /home/azurebrd/work/wen/apache_simplemine/check_apache_simplemine.pl
#
# Dockerized cronjob, but access.log.1 might not exist, so checking that
# Location is apache2/other_vhosts_access.log instead of httpd/access.log
# The IP is not the first string, so parse differently.  2023 03 17

# 0 1 1 * * /usr/lib/scripts/cronjobs/check_apache_simplemine.pl



use strict;
use Jex;

my $dir = '/var/log/apache2/';
# my $dir = '/var/log/httpd/';	# on tazendra logs were here, on dockerized in apache2/

# my $file = $dir . 'access.log.2.gz';

my @files = ('other_vhosts_access.log', 'other_vhosts_access.log.1');
# my @files = ('access.log', 'access.log.1');	# on tazendra logs were here, on dockerized in other_vhosts_access.log

for (my $i = 2; $i < 5; $i++) {
  my $file = 'access.log.' . $i . '.gz';
  push @files, $file;
}

my %ips;
foreach my $file (@files) {
  $file = $dir . $file;
  next unless -e $file;
  if ($file =~ m/\.gz/) {
      open (IN, "gunzip -c $file |") or die "Cannot open pie to $file : $!"; }
    else {
      open (IN, "<$file") or die "Cannot open $file : $!"; }
  while (my $line = <IN>) {
    if ($line =~ m/simplemine.cgi/) { 
      my ($ip) = $line =~ m/^[\S]*\s([\S]*)\s/;
      # on dockerized logs are in this format
      # caltech-curation.textpressolab.com:443 71.84.234.79 - - [17/Mar/2023:21:11:03 +0000] "GET /pub/cgi-bin/forms/simplemine.cgi HTTP/1.1" 200 15291 "https://caltech-curation.textpressolab.com:4432/pub/cgi-bin/index.cgi" "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/111.0"
      # my ($ip) = $line =~ m/^([\S]*)\s/;
      # on tazendra logs were in this format
      # 50.19.229.229 - - [12/Mar/2023:08:56:37 -0700] "GET /~azurebrd/cgi-bin/forms//simplemine.cgi HTTP/1.1" 200 9957 "https://wormbase.org/" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.3.1 Safari/605.1.15"
      $ips{$ip}++;
    }
  }
  close (IN) or die "Cannot close $file : $!";
}

my $body = '';
foreach my $ip (sort keys %ips) {
  $body .= qq(IP $ip\n);
}

my $user = 'check_apache_simplemine';
# my $email = 'closertothewake@gmail.com';
my $email = 'wen@wormbase.org';
my $subject = 'simplemine apache log IPs for last 5 weeks';

&mailer($user, $email, $subject, $body);

