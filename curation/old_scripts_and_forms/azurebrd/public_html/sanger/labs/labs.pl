#!/usr/bin/perl -w

# Regenerate Lab data.  2006 12 05
#
# Set cronjob
# 0 4 * * * /home/azurebrd/public_html/sanger/labs.pl

use strict;
use Ace;
use Jex;
use Pg;


my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my %std_name;
my $result = $conn->exec( "SELECT * FROM two_standardname;" );
while (my @row = $result->fetchrow) { $row[0] =~ s/two/WBPerson/; $std_name{$row[0]} = $row[2]; }

my $all_stuff;

my $database_path = "/home/acedb/WS_current/";     # full path to local AceDB database; change as appropriate
my $program = "/home/acedb/bin/tace";  # full path to tace; change as appropriate


# print "Connecting to database...";

my $db = Ace->connect('sace://aceserver.cshl.org:2005') || die "Connection failure: ", Ace->error;                      # uncomment to use aceserver.cshl.org - may be slow
# my $db = Ace->connect(-path => $database_path,  -program => $program) || die print "Connection failure: ", Ace->error;   # local database

# print "done.\n";

my $query="find Laboratory";
my @tags = qw( Mail Representative Registered_lab_members );

my @objs=$db->fetch(-query=>$query);

if (! @objs) {
    print "no objects found.\n";
    exit;
}

foreach my $obj (@objs) {
  $all_stuff .= "Lab designation : $obj\n";
#   print "Lab designation : $obj\n";
  foreach my $tag (@tags) {
    foreach ($obj->$tag(1)) {
      if ($std_name{$_}) { $all_stuff .= "$tag\t$std_name{$_} ($_)\n"; }
        else { $all_stuff .= "$tag\t$_\n"; }
    }
  } # foreach my $tag (@tags)
  $all_stuff .= "\n";
}

my (@length) = split/./, $all_stuff;
if (scalar(@length) > 1000) {
  my $outfile = '/home/azurebrd/public_html/sanger/labs/labs.ace';
  open (OUT, ">$outfile") or die "Cannot open $outfile : $!";
  print OUT "$all_stuff";
  close (OUT) or die "Cannot close $outfile : $!";
}
  
