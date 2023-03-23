#!/usr/bin/perl -w

# Email Daniela if anyone other than herself is a curator in the Picture OA in the last day.
#
# Set to run every day at 1am	2015 01 05
# 0 1 * * * /home/acedb/draciti/cronjobs/daily_pictures_curator.pl



use strict;
use diagnostics;
use Jex;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 



my $user = 'daily_pictures_curator.pl';

my $body = '';

my %hash;
my $result = $dbh->prepare( "SELECT * FROM pic_curator WHERE pic_curator != 'WBPerson12028' AND pic_timestamp > now() - interval '1 day';" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { if ($row[0]) { $hash{$row[0]}{curator} = $row[1]; $hash{$row[0]}{timestamp} = $row[2]; } }

my $joinkeys = join"','", sort {$a<=>$b} keys %hash;
$result = $dbh->prepare( " SELECT * FROM pic_name WHERE joinkey IN ('$joinkeys');" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { if ($row[0]) { $hash{$row[0]}{name} = $row[1]; } } 

foreach my $pgid (sort {$a<=>$b} keys %hash) {
  my $name      = $hash{$pgid}{name};
  my $curator   = $hash{$pgid}{curator};
  my $timestamp = $hash{$pgid}{timestamp};
  $body .= qq($pgid\t$name\t$curator\t$timestamp\n);
} # foreach my $pgid (sort {$a<=>$b} keys %hash)

# print "BODY $body\n";

# my $email = 'closertothewake@gmail.com';
my $email = 'draciti@its.caltech.edu';	
my $subject = "There are new pictures objects by someone else";
if ($body) {
  &mailer($user, $email, $subject, $body);  
}

