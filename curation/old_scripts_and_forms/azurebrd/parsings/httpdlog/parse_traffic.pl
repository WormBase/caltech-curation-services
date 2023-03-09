#!/usr/bin/perl 

# parse access.log* for form stats  2012 01 26

use strict;

my @list = ();
my $file = 'list';
open (IN, "$file") or die "Cannot open $file : $!";
while (my $line = <IN>) { 
  chomp $line; 
  next if ($line =~ m/# remove/);
  if ($line =~ m/\t# remove/) { $line =~ s/\t# remove//; }
  push @list, $line; }
close (IN) or die "Cannot close $file : $!";

foreach my $cgi (@list) { print "$cgi\n"; }

my %stats;

my %ips;
my %referrers;
my (@files) = </var/log/httpd/access.log*>;
foreach my $cgi (@list) {
  foreach my $file (@files) {
  #   print "F $file\n";
    if ($file =~ /\.gz$/) { open (IN, "gunzip -c $file |") or die "can't open pipe to $file"; }
      else { open (IN, "<$file") or die "Cannot open $file : $!"; }
    while ( my $line = <IN> ) {
      chomp $line;
      my ($host, $ident_user, $auth_user, $something, $date, $time, $time_zone, $method, $url, $protocol, $status, $bytes, $referrer, $browser) = $line =~ /^(\S+) (\S+) (\S+) (\S+) \[([^:]+):(\d+:\d+:\d+) ([^\]]+)\] "(\S+) (.+?) (\S+)" (\S+) (\S+) "([^"]*)" "([^"]*)"$/;
      next if ( ($line =~ m/jex.css/) || ($line =~ m/wormbase.css/) );
      next if ( ($line =~ m/"Sogou/) || ($line =~ m/"Python/) || ($line =~ m/"Jakarta/) );
      next if ( ($line =~ m/autocomplete/) );
      if ($line =~ m/$cgi/) { $stats{$cgi}{$file}{$line}++; }
      next unless ($host =~ m/infinityfamily.org/);
      $ips{$ident_user}++;
      unless ($referrer =~ m/infinityfamily.org/) { $referrers{$referrer}++; }
  #     print "$line";
    } # while ( my $line = <IN> )
    close (IN) or die "Cannot close $file : $!";
  #   print "END $file\n\n";
  } # foreach my $file (@files)
} # foreach my $cgi (@list)

foreach my $cgi (sort keys %stats) {
  my $count = 0;
  foreach my $file (sort keys %{ $stats{$cgi}} ) {
    foreach my $line (sort keys %{ $stats{$cgi}{$file}} ) {
      $count++;
#       print "CGI $cgi FILE $file LINE $line\n";
    } # foreach my $line (sort keys %{ $stats{$cgi}{$file}} )
  } # foreach my $file (sort keys %{ $stats{$cgi}} )
  print "$cgi $count\n";
} # foreach my $cgi (sort keys %stats)
  
# foreach my $ip (sort {$ips{$b} <=> $ips{$a}} keys %ips) {
#   print "$ip\t$ips{$ip}\n";
# } # foreach my $ip (sort {$ips{$a} <=> $ips{$b}} keys %ips)
# print "\n";
# 
# foreach my $referrer (sort {$referrers{$b} <=> $referrers{$a}} keys %referrers) {
#   print "$referrer\t$referrers{$referrer}\n";
# } # foreach my $referrer (sort {$referrers{$a} <=> $referrers{$b}} keys %referrers)
# print "\n";
