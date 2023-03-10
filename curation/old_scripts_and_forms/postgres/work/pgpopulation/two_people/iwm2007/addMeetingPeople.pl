#!/usr/bin/perl

# Create new meeting people from parsed file made by Cecilia.  This is only the
# first part, she hasn't gone through all the people yet.  Ran
# iwm2007forLito1.txt  2007 08 13
#
# Modified for second run.  2007 09 18
#
# Modified for third run.  2007 09 27
#
# Modified for fourth run.  2007 10 18
#
# Modified for fifth run.  2007 11 06
#
# Modified for sixth run.  2008 01 03

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my %entries;

# my $infile = 'iwm2007forLito1.txt';
# my $infile = 'iwm2007-2ndGroupForLito.txt';
# my $infile = 'iwm2007-3rdGroupForLito.txt';
# my $infile = 'iwm2007-3rdG-R-forLito.txt';
# my $infile = 'IWM2007-4thG-forLito.txt';
# my $infile = 'iwm2007-5thForLito.txt';
my $infile = 'iwm2007-6th-forLito.txt';
$/ = undef;
open (IN, "<$infile") or die "Cannot open $infile : $!"; 
my $all_file = <IN>;
close (IN) or die "Cannot close $infile : $!"; 
my (@entries) = split/\n\n/, $all_file;
foreach my $entry (@entries) {
#   unless ($entry =~ m/City:/) { print "E $entry E\n\n\n"; }
  my (@lines) = split/\n/, $entry;
  my ($fname, $mname, $lname);
  my $name = shift @lines;
  if ($name =~ m/^(\S+) (\S+) (\S+)$/) { $fname = $1; $mname = $2; $lname = $3; }
    elsif ($name =~ m/^(\S+) (\S+)$/) { $fname = $1; $lname = $2; }
    else { print "WEIRD NAME $name NAME\n"; }
  my @street; my $line = '';
  my ($city, $state, $post, $country);
  if ($entry =~ m/City:/) { 
      while ($line !~ m/City:/) { 
        $line = shift @lines; push @street, $line; }
      if ($line =~ m/^City: ([\.\-\w]+) (\w+) ([\_\-\w]+) ?$/) { $city = $1; $state = $2; $post = $3; }
        elsif ($line =~ m/^City: ([\.\-\w]+) ([\_\-\w]+) ?$/) { $city = $1; $post = $2; }
        else { print "WEIRD LINE $line LINE\n"; }
      $country = shift @lines; }
    else { print "WARNING $name doesn't have a city\n"; }
  my %aka;
  my ($phone, $fax, $email, $inst, $inst2, $lab, $webpage, $akaf, $akam, $akal, $comment);
  foreach my $line (@lines) {
    if ($line =~ m/Phone: (.*)/) { $phone = $1; }
    elsif ($line =~ m/Fax: (.*)/) { $fax = $1; }
    elsif ($line =~ m/Email: (.*)/) { $email = $1; }
    elsif ($line =~ m/Inst: (.*)/) { $inst = $1; }
    elsif ($line =~ m/Inst 1: (.*)/) { $inst = $1; }
    elsif ($line =~ m/Inst 2: (.*)/) { $inst2 = $1; }
    elsif ($line =~ m/[lL]ab: (.*)/) { $lab = $1; }
    elsif ($line =~ m/webpage: (.*)/) { $webpage = $1; }
    elsif ($line =~ m/two_aka_firstname: (.*)/) { $akaf = $1; $aka{f}{1} = $1; }
    elsif ($line =~ m/two_aka_middlename: (.*)/) { $akam = $1; $aka{m}{1} = $1; }
    elsif ($line =~ m/two_aka_lastname: (.*)/) { $akal = $1; $aka{l}{1} = $1; }
    elsif ($line =~ m/two_aka_firstname (\d+): (.*)/) { $akaf = $2; $aka{f}{$1} = $2; }
    elsif ($line =~ m/two_aka_middlename (\d+): (.*)/) { $akam = $2; $aka{m}{$1} = $2; }
    elsif ($line =~ m/two_aka_lastname (\d+): (.*)/) { $akal = $2; $aka{l}{$1} = $2; }
    elsif ($line =~ m/two_comment: (.*)/) { $comment = $1;}
    else { print "ERR $line NOT $entry VALID\n"; }
  } # foreach my $line (@lines)
  my $result = $conn->exec( "SELECT two FROM two ORDER BY two DESC;" );
  my @row = $result->fetchrow;
  my $joinkey = $row[0]; $joinkey++; 
  my $command = "INSERT INTO two VALUES ('two$joinkey', '$joinkey', CURRENT_TIMESTAMP);";
  print "$command\n"; 
# UNCOMMENT THIS TO RUN
#   $result = $conn->exec( $command );
  &putPg($joinkey, 'status', 'Valid');
  if ($name) { $name =~ s/_/ /g; &putPg($joinkey, 'standardname', $name); } 
  if ($fname) { $fname =~ s/_/ /g; &putPg($joinkey, 'firstname', $fname); }
  if ($mname) { $mname =~ s/_/ /g; &putPg($joinkey, 'middlename', $mname); }
  if ($lname) { $lname =~ s/_/ /g; &putPg($joinkey, 'lastname', $lname); }
  if ($street[0]) {
    pop @street;
    my $count = 0;
    foreach my $line (@street) { $count++;
      &putPg($joinkey, 'street', $line, $count); } }
  if ($city) { $city =~ s/_/ /g; &putPg($joinkey, 'city', $city); } 
  if ($state) { $state =~ s/_/ /g; &putPg($joinkey, 'state', $state); } 
  if ($post) { $post =~ s/_/ /g; &putPg($joinkey, 'post', $post); } 
  if ($country) { &putPg($joinkey, 'country', $country); } 
  if ($phone) { &putPg($joinkey, 'mainphone', $phone); } 
  if ($fax) { &putPg($joinkey, 'fax', $fax); } 
  if ($email) { &putPg($joinkey, 'email', $email); } 
  if ($inst) { &putPg($joinkey, 'institution', $inst); } 
  if ($inst2) { &putPg($joinkey, 'institution', $inst2, 2); } 
  if ($lab) { &putPg($joinkey, 'lab', $lab); } 
  if ($webpage) { &putPg($joinkey, 'webpage', $webpage); } 
  if ($akaf) { foreach my $order (sort keys %{ $aka{f}}) { my $akaf = $aka{f}{$order}; &putPg($joinkey, 'aka_firstname', $akaf, $order) } }
  if ($akam) { foreach my $order (sort keys %{ $aka{m}}) { my $akam = $aka{m}{$order}; &putPg($joinkey, 'aka_middlename', $akam, $order) } }
  if ($akal) { foreach my $order (sort keys %{ $aka{l}}) { my $akal = $aka{l}{$order}; &putPg($joinkey, 'aka_lastname', $akal, $order) } }
#   if ($akaf) { &putPg($joinkey, 'aka_firstname', $akaf); } 
#   if ($akam) { &putPg($joinkey, 'aka_middlename', $akam); } 
#   if ($akal) { &putPg($joinkey, 'aka_lastname', $akal); } 
  if ($comment) { &putPg($joinkey, 'comment', $comment); } 
  print "\n";
} # foreach my $entry (@entries)

sub putPg {
  my ($joinkey, $table, $value, $order) = @_;
  $joinkey = 'two' . $joinkey;
  unless ($order) { $order = 1; }
  $table = 'two_' . $table;
  my $command = "INSERT INTO $table VALUES ('$joinkey', '$order', '$value', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);";
  if ($table eq 'two_comment') { $command = "INSERT INTO $table VALUES ('$joinkey', '$value', CURRENT_TIMESTAMP );"; }
  print "$command\n";
# UNCOMMENT THIS TO RUN
#   my $result = $conn->exec( $command );
} # sub putPg


__END__ 

DELETE FROM two WHERE two_timestamp > '2007-10-18 11:50';
DELETE FROM two_status WHERE two_timestamp > '2007-10-18 11:50';
DELETE FROM two_standardname WHERE two_timestamp > '2007-10-18 11:50';
DELETE FROM two_firstname WHERE two_timestamp > '2007-10-18 11:50';
DELETE FROM two_lastname WHERE two_timestamp > '2007-10-18 11:50';
DELETE FROM two_middlename WHERE two_timestamp > '2007-10-18 11:50';
DELETE FROM two_street WHERE two_timestamp > '2007-10-18 11:50';
DELETE FROM two_state WHERE two_timestamp > '2007-10-18 11:50';
DELETE FROM two_city WHERE two_timestamp > '2007-10-18 11:50';
DELETE FROM two_post WHERE two_timestamp > '2007-10-18 11:50';
DELETE FROM two_country WHERE two_timestamp > '2007-10-18 11:50';
DELETE FROM two_lab WHERE two_timestamp > '2007-10-18 11:50';
DELETE FROM two_mainphone WHERE two_timestamp > '2007-10-18 11:50';
DELETE FROM two_fax WHERE two_timestamp > '2007-10-18 11:50';
DELETE FROM two_email WHERE two_timestamp > '2007-10-18 11:50';
DELETE FROM two_institution WHERE two_timestamp > '2007-10-18 11:50';
DELETE FROM two_webpage WHERE two_timestamp > '2007-10-18 11:50';
DELETE FROM two_comment WHERE two_timestamp > '2007-10-18 11:50';
DELETE FROM two_aka_firstname WHERE two_timestamp > '2007-10-18 11:50';
DELETE FROM two_aka_lastname WHERE two_timestamp > '2007-10-18 11:50';
DELETE FROM two_aka_middlename WHERE two_timestamp > '2007-10-18 11:50';

