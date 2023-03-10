#!/usr/bin/perl -w

# Email Karen if anyone other than herself is a curator in the Transgene OA in the last day.
#
# Added cns_newtransgene when people make constructs to not-yet-existing transgenes.  For Karen.  2014 06 09
#
# Added trp_paper for Karen.  2014 11 03
#
# Get all trp_curator results, then for those pgids get the associated trp_paper to email.  
# no longer use cns_newtransgene.  2015 01 06

# Set to run every day at 1am	2013 05 17
# 0 1 * * * /home/acedb/karen/cronjobs/daily_transgene_curators.pl


use strict;
use diagnostics;
use Jex;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 



my $user = 'daily_transgene_curators.pl';

my $body = '';

my %hash;

my $result = $dbh->prepare( " SELECT * FROM trp_curator WHERE trp_curator != 'WBPerson712' AND trp_timestamp > now() - interval '1 day';" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[1] =~ s///g;
    $row[2] =~ s///g;
    $hash{$row[0]}{curator} = $row[1];
    $hash{$row[0]}{timestamp} = $row[2];
  } # if ($row[0])
} # while (@row = $result->fetchrow)

$result = $dbh->prepare( " SELECT * FROM trp_paper;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[1] =~ s///g;
    $row[2] =~ s///g;
    $hash{$row[0]}{paper} = $row[1];
  } # if ($row[0])
} # while (@row = $result->fetchrow)

# Karen doesn't want this anymore
# $result = $dbh->prepare( " SELECT * FROM cns_newtransgene WHERE cns_timestamp > now() - interval '1 day';" );
# $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
# while (my @row = $result->fetchrow) {
#   if ($row[0]) { 
#     $row[0] =~ s///g;
#     $row[1] =~ s///g;
#     $row[2] =~ s///g;
#     $body .= "cns_newtransgene\t$row[0]\t$row[1]\t$row[2]\n";
#   } # if ($row[0])
# } # while (@row = $result->fetchrow)

foreach my $pgid (sort keys %hash) {
  next unless ($hash{$pgid}{curator});
  my $paper = ''; if ($hash{$pgid}{paper}) { $paper = $hash{$pgid}{paper}; }
  $body .= qq(curator\t$hash{$pgid}{curator}\t$paper\t$hash{$pgid}{timestamp}\n);
} # foreach my $pgid (sort keys %hash)

# print "BODY $body\n";

# my $email = 'closertothewake@gmail.com';
my $email = 'kyook@its.caltech.edu';	
my $subject = "There are new transgene objects to check";
if ($body) {
  &mailer($user, $email, $subject, $body);  
}

