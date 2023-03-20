#!/usr/bin/perl

# For wen, look at apache logs for IP of users of simplemine.cgi and email her the IPs.
# Every first of the month at 1am.

# 0 1 1 * * /home/azurebrd/work/wen/apache_simplemine/check_apache_simplemine.pl



use strict;
use Jex;

my $dir = '/var/log/httpd/';

# my $file = $dir . 'access.log.2.gz';

my @files = ('access.log', 'access.log.1');

for (my $i = 2; $i < 5; $i++) {
  my $file = 'access.log.' . $i . '.gz';
  push @files, $file;
}

my %ips;
foreach my $file (@files) {
  $file = $dir . $file;
  if ($file =~ m/\.gz/) {
      open (IN, "gunzip -c $file |") or die "Cannot open pie to $file : $!"; }
    else {
      open (IN, "<$file") or die "Cannot open $file : $!"; }
  while (my $line = <IN>) {
    if ($line =~ m/simplemine.cgi/) { 
      my ($ip) = $line =~ m/^([\S]*)\s/;
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

