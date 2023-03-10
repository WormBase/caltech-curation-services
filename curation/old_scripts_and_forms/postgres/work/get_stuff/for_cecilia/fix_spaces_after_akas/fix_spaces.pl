#!/usr/bin/perl -w
#
# fix extra spaces that were added at end (or beginning or in middle) or a name.  2003 06 13

use strict;
use diagnostics;
use lib qw( /usr/lib/perl5/site_perl/5.6.1/i686-linux/ );
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

# my $outfile = "/home/postgres/work/get_stuff/for_cecilia_person_wbg/outfile";
# open(OUT, ">$outfile") or die "Cannot create $outfile : $!";

my @stuff = qw(firstname middlename lastname aka_firstname aka_middlename aka_lastname);

foreach my $table (@stuff) { 
  print "TABLE $table\n";
  my $result = $conn->exec( "SELECT * FROM two_$table;");
  while (my @row = $result->fetchrow) {
    if ($row[0]) { 
      $row[0] =~ s///g;
      my $joinkey = $row[0];
      $row[1] =~ s///g;
      my $order = $row[1];
      $row[2] =~ s///g;
      my $value = $row[2];
      my $new = $value;
      $new =~ s/\s+/ /g;
      $new =~ s/^\s+//g;
      $new =~ s/\s+$//g;
      if ($value ne $new) { 
        print "V $value NE $new\n"; 
        my $result2 = $conn->exec( "UPDATE two_$table SET two_$table = '$new' WHERE two_$table = '$value' AND joinkey = '$joinkey' AND two_order = '$order';");
      }
    } # if ($row[0])
  } # while (my @row = $result->fetchrow)
} # foreach my $table (@stuff)

# foreach my $wbg (@wbg) {
#   my $result = $conn->exec( "SELECT joinkey, wbg_lastname FROM wbg_lastname WHERE joinkey = '$wbg';");
#   while (my @row = $result->fetchrow) {
#     if ($row[0]) { 
#       $row[0] =~ s///g;
#       $row[1] =~ s///g;
#       $row[2] =~ s///g;
#       print OUT "$row[0]\t$row[1]\t";
#     } # if ($row[0])
#   } # while (my @row = $result->fetchrow)
#   $result = $conn->exec( "SELECT joinkey, wbg_email FROM wbg_email WHERE joinkey = '$wbg';");
#   while (my @row = $result->fetchrow) {
#     if ($row[0]) { 
#       $row[0] =~ s///g;
#       $row[1] =~ s///g;
#       $row[2] =~ s///g;
#       print OUT "$row[1]\n";
#     } # if ($row[0])
#   } # while (my @row = $result->fetchrow)
# } # foreach my $wbg (@wbg)

# close (OUT) or die "Cannot close $outfile : $!";
