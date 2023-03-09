#!/usr/bin/perl

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

# use cecilia's edited files (edited for typos compared to postgres)
my $paul = "/home/cecilia/work/Paul_Meeting_People/Paul_1580";
my $eimear = "/home/cecilia/work/Paul_Meeting_People/Eimear_3450";

my %pg;
my %paul;
my %eimear;

&getFileData();
&getPgData();

# foreach my $pg_key (sort keys %pg) {
#   print "PG $pg_key $pg{$pg_key}\n";
# } # foreach my $pg_key (sort keys %pg)


# this block gets stuff that is totally new
# check p & e vs pg
foreach my $p_last (sort keys %paul) {
  unless ($pg{$p_last}) { 
    print "PAUL\t$p_last\t$paul{$p_last}\n"; 
#     &processPgWild($p_last);
  }
}
foreach my $e_last (sort keys %eimear) {
  if ($paul{$e_last}) { next; }
  unless ($pg{$e_last}) { 
    print "EIM\t$e_last\t$eimear{$e_last}\n"; 
#     &processPgWild($e_last);
  }
}



# # check p & e vs each other
# foreach my $e_last (sort keys %eimear) {
#   unless ($paul{$e_last}) { print "$e_last\t$eimear{$e_last}\n"; }
# }
# foreach my $p_last (sort keys %paul) {
#   unless ($eimear{$p_last}) { print "$p_last\t$paul{$p_last}\n"; }
# }




sub processPgWild {
  my $input_name = shift;
  my ($last_name) = $input_name =~ m/^(\S+)/g;
#   print "<TABLE>\n";
#   print "<TR><TD>INPUT</TD><TD>$last_name</TD></TR>\n";
  my @people_ids;
  $last_name =~ s/\*/.*/g;
  $last_name =~ s/\?/./g;
  my @last_parts = split/\s+/, $last_name;
  my %last_parts;
  my %matches;                          # keys = wbid, value = amount of matches
  my %filter;
  foreach my $last_part (@last_parts) {
    my @tables = qw (first middle last);
    foreach my $table (@tables) {
      my $result = $conn->exec ( "SELECT * FROM two_aka_${table}name WHERE lower(two_aka_${table}name) ~ lower('$last_part');" );
      while ( my @row = $result->fetchrow ) { $filter{$row[0]}{$last_part}++; }
      $result = $conn->exec ( "SELECT * FROM two_${table}name WHERE lower(two_${table}name) ~ lower('$last_part');" );
      while ( my @row = $result->fetchrow ) { $filter{$row[0]}{$last_part}++; }
    } # foreach my $table (@tables)
  } # foreach my $last_part (@last_parts)

  foreach my $number (sort keys %filter) {
    foreach my $last_part (@last_parts) {
      if ($filter{$number}{$last_part}) {
        my $temp = $number; $temp =~ s/two/WBPerson/g; $matches{$temp}++;
        my $count = length($last_part);
        unless ($last_parts{$temp} > $count) { $last_parts{$temp} = $count; }
      }
    } # foreach my $last_part (@last_parts)
  } # foreach my $number (sort keys %filter)

#   print "<TR><TD></TD><TD>There are " . scalar(keys %matches) . " match(es).</TD></TR>\n";
#   print "<TR></TR>\n";
#   print "</TABLE>\n";
#   print "<TABLE border=2 cellspacing=5>\n";
  foreach my $person (sort {$matches{$b}<=>$matches{$a} || $last_parts{$b} <=> $last_parts{$a}} keys %matches) {
#     print "<TR><TD><A HREF=http://www.wormbase.org/db/misc/etree?name=${person};class=Person>$person</A></TD>\n";
#     print "<TD>has $matches{$person} match(es)</TD><TD>priority $last_parts{$person}</TD></TR>\n";
    print "\t$person\thas $matches{$person} match(es)\tpriority $last_parts{$person}.\n";
  }
#   print "</TABLE>\n";

  unless (%matches) {
#     print "<FONT COLOR=red>Sorry, no person named '$last_name', please try again</FONT><P>\n" if $last_name;
  }
} # sub processPgWild


sub getPgData {
  my $result = $conn->exec( "SELECT * FROM two_firstname;");
  my %first; my %last; my %middle;
  my %aka_first; my %aka_last; my %aka_middle;
  while (my @row = $result->fetchrow) {
    if ($row[0]) { 
      unless ($row[2]) { $row[2] = ''; }
      $row[0] =~ s///g; $row[2] =~ s///g;
      $first{$row[0]} = $row[2]; } }
  $result = $conn->exec( "SELECT * FROM two_lastname;");
  while (my @row = $result->fetchrow) {
    if ($row[0]) { 
      $row[0] =~ s///g; $row[2] =~ s///g;
      $last{$row[0]} = $row[2]; } }
  $result = $conn->exec( "SELECT * FROM two_middlename;");
  while (my @row = $result->fetchrow) {
    if ($row[0]) { 
      unless ($row[2]) { $row[2] = ''; }
      $row[0] =~ s///g; $row[2] =~ s///g;
      $middle{$row[0]} = $row[2]; } }

  $result = $conn->exec( "SELECT * FROM two_aka_lastname;");
  while (my @row = $result->fetchrow) {
    if ($row[0]) { 
      $row[0] =~ s///g; $row[2] =~ s///g;
      unless ($row[2]) { $row[2] = ''; }
      $aka_last{$row[0]}{$row[1]} = $row[2]; } }
  $result = $conn->exec( "SELECT * FROM two_aka_firstname;");
  while (my @row = $result->fetchrow) {
    if ($row[0]) { 
      $row[0] =~ s///g; $row[2] =~ s///g;
      unless ($row[2]) { $row[2] = ''; }
      $aka_first{$row[0]}{$row[1]} = $row[2]; } }
  $result = $conn->exec( "SELECT * FROM two_aka_middlename;");
  while (my @row = $result->fetchrow) {
    if ($row[0]) { 
      $row[0] =~ s///g; $row[2] =~ s///g;
      unless ($row[2]) { $row[2] = ''; }
      $aka_middle{$row[0]}{$row[1]} = $row[2]; } } 

  foreach my $joinkey (sort keys %last) {
    unless ($first{$joinkey}) { $first{$joinkey} = ''; }
    unless ($middle{$joinkey}) { $middle{$joinkey} = ''; }
    my $key = "$last{$joinkey} $first{$joinkey}";
    $key = lc($key);
    $pg{$key} = "$first{$joinkey} $middle{$joinkey} $last{$joinkey}";

    if ($aka_last{$joinkey}) {
      foreach my $order (sort keys %{ $aka_last{$joinkey} }) {
        unless ($aka_first{$joinkey}{$order}) { $aka_first{$joinkey}{$order} = ''; }
        unless ($aka_middle{$joinkey}{$order}) { $aka_middle{$joinkey}{$order} = ''; }
        my $key = "$aka_last{$joinkey}{$order} $aka_first{$joinkey}{$order}";
        $key = lc($key);
        $pg{$key} = "$aka_first{$joinkey}{$order} $aka_middle{$joinkey}{$order} $aka_last{$joinkey}{$order}";
      } # foreach my $order (sort keys %{ $aka_last{$joinkey} })
    } # if ($aka_last{$joinkey})
  } # foreach my $joinkey (sort keys %last)
} # sub getPgData

sub getFileData {
  $/ = "";
  open (EIM, "<$eimear") or die "Cannot open $eimear : $!";
  while (<EIM>) {
    $_ =~ s/φ/o/g;
    $_ =~ s/ι/e/g;
    my ($first) = $_ =~ m/Presenter\t([ό\w\'\-]+)/g;
    my ($middle) = $_ =~ m/Presenter_Middle\t([\w\-]+)/g;
    my ($last) = $_ =~ m/Presenter_Last\t([ό\w\'\-\ ]+)/g;
    my $key = "$last $first";
    $key = lc($key);
    $eimear{$key} = "$first $middle $last";
  
  # used these 3 lines to check duplicates
  #   my $key = "$first $last";
  #   push @{ $eimear{$key}}, "$first $middle $last";
  
  } # while (<EIM>)
  close (EIM) or die "Cannot close $eimear : $!";
  
  # use this block to check duplicates
  # foreach my $e_key (sort keys %eimear) {
  #   if (scalar (@{ $eimear{$e_key}}) > 1) {
  #     foreach (@{ $eimear{$e_key}}) { print "$_\n"; }
  #   } # if (scalar (@{ $eimear{$e_key}}) > 1)
  # } # foreach my $e_key (sort keys %eimear)
  # my $num = scalar keys %eimear;
  # print "$num\n";
  
  
  open (PAU, "<$paul") or die "Cannot open $paul : $!";
  while (<PAU>) {
    my ($name, @stuff) = split/\n/, $_;
    $name =~ s/,.*//g;
    $name =~ s/\.//g;
    $name =~ s/ Dr$//g;		# Take out suffix
    $name =~ s/ Mr$//g;		# Take out suffix
    $name =~ s/ Mrs$//g;		# Take out suffix
    $name =~ s/ Jr$//g;		# Take out suffix
    $name =~ s/ Sr$//g;		# Take out suffix
    $name =~ s/ III$//g;		# Take out suffix
    $name =~ s/ Ms$//g;		# Take out suffix
    $name =~ s/φ/o/g;
    $name =~ s/ι/e/g;
  # Ginger Ruth Kelly Miley may be last name Kelly Miley, but capturing Miley so
  # as not to capture Kelly from people named Kelly Lastname, also matches Eim file
    my ($last) = $name =~ m/(( Pires)?( Shmookler)?( Roy)?( Le)?( [dD][aei]l?)?( [vV][ao]n( [dD][ea][rnl])?)?( [a-z]+)? ([ό\w\'\-]+))$/;
    my ($first) = $name =~ m/^([ιό\w\'\-]+) /;
    $last =~ s/^\s+//g;
    my $key =  "$last $first";
    $key = lc($key);
    $paul{$key} = $name;
  #   print "$name\n";
  } # while (<PAU>)
  close (PAU) or die "Cannot close $paul : $!";
  $/ = "\n";
  
} # sub getFileData

