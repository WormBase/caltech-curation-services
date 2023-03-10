#!/usr/bin/perl -w
#
# This program takes in the input from the command line the ace# and wbg# files
# that the user wants printed.  It reads the file /home/cecilia/carta-template,
# and prints it out to /home/postgres/work/authorperson/infobykey/mailingfile.
# It then looks at the table data from the postgreSQL tables and prints it out
# to the same /home/postgres/work/authorperson/infobykey/mailingfile.  This can
# be sent by doing something like : 
# echo '' | mutt -i '/home/postgres/work/authorperson/infobykey/mailingfile' -s
# 'Wormbase - Caltech Updating Database' cecilianakamura@excite.com
# anotheremail@domain.com
#
# updated to have a top and bottom carta-template to read the top, then get the
# key data and print it, then print the bottom template  2002-03-05
 
use strict;
use Fcntl;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my @ace_tables = qw(ace_author ace_name ace_lab ace_oldlab ace_address ace_email ace_phone ace_fax);
my @wbg_tables = qw(wbg_title wbg_firstname wbg_middlename wbg_lastname wbg_suffix wbg_street wbg_city wbg_state wbg_post wbg_country wbg_mainphone wbg_labphone wbg_officephone wbg_fax wbg_email);

my $outfile = "/home/postgres/work/authorperson/infobykey/mailingfile";
open (OUT, ">$outfile") or die "Cannot open $outfile : $!";

  # print top of letter template
my $carta_top = "/home/cecilia/carta-template-top";
open (CAR, "<$carta_top") or die "Cannot open $carta_top : $!";
undef $/;
$_ = <CAR>;
print OUT $_;
print OUT "\n\n";
close (CAR) or die "Cannot close $carta_top : $!";

  # get data from keys and print to letter
my @data = @ARGV;
foreach (@data) { 
  print "STUFF : $_\n"; 
  if ($_ =~ m/^ace/) { &displayAceDataFromKey($_); }
  elsif ($_ =~ m/^wbg/) { &displayWbgDataFromKey($_); }
  else { print "Not a valid file type\n"; }
} # foreach (@data)

  # print bottom of letter template
my $carta_bottom = "/home/cecilia/carta-template-bottom";
open (CAR, "<$carta_bottom") or die "Cannot open $carta_bottom : $!";
undef $/;
$_ = <CAR>;
print OUT $_;
print OUT "\n\n";
close (CAR) or die "Cannot close $carta_bottom : $!";

close (OUT) or die "Cannot close $outfile : $!";


sub displayAceDataFromKey {		# show all ace data from a given key in multiline table
  my ($ace_key) = @_;
  foreach my $ace_table (@ace_tables) {	# show the data
    my $result = $conn->exec( "SELECT * FROM $ace_table WHERE joinkey = '$ace_key';" );
    my @row;
    while (@row = $result->fetchrow) {
      if ($row[1]) {
        if ($row[2]) { 
          my $date = substr($row[2],0,10);
          print "$date\t$ace_key\t";
          print OUT "$date\t$ace_key\t";
        } # if ($row[2])
        my $print_table = $ace_table;
        $print_table =~ s/ace_//g; 
        print "$print_table\t";
        print OUT "$print_table\t";
        if ($row[1]) {
          print "$row[1]\n";
          print OUT "$row[1]\n";
        } # if ($row[1])
      } # if ($row[1])
    } # while (@row = $result->fetchrow)
  } # foreach (@ace_tables)
  print "\n";
  print OUT "\n";
} # sub displayAceDataFromKey

sub displayWbgDataFromKey {		# show all wbg data from a given key in multiline table
  my ($wbg_key) = @_;
  foreach my $wbg_table (@wbg_tables) {	# go through each table for the key
    my $result = $conn->exec( "SELECT * FROM $wbg_table WHERE joinkey = '$wbg_key';" );
    my @row;
    while (@row = $result->fetchrow) {
      if ($row[1]) { 
        if ($row[2]) { 
          my $date = substr($row[2],0,10);
          print "$date\t$wbg_key\t";
          print OUT "$date\t$wbg_key\t";
        } # if ($row[2])
        my $print_table = $wbg_table;
        $print_table =~ s/wbg_//g; 
        $print_table =~ s/name//g; 
        $print_table =~ s/mainphone/phone/g; 
        $print_table =~ s/labphone/lab/g; 
        $print_table =~ s/officephone/office/g; 
        print "$print_table\t";
        print OUT "$print_table\t";
        if ($row[1]) {
          print "$row[1]\n";
          print OUT "$row[1]\n";
        } # if ($row[1])

      } # if ($row[1])
    } # while (@row = $result->fetchrow)
  } # foreach my $wbg_table (@wbg_tables)
  print "\n";
  print OUT "\n";
} # sub displayWbgDataFromKey

####  display from key ####
