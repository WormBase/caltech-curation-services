#!/usr/bin/perl -w

# Leon_lab-url	-> Labcode : url
# 		-> url in person page (check not already in)
# Leon_Researcher-Profiles	-> url in person page (check not already in)

# two sections : &dealResearch(); which looks at one file and updates personal
# webpages ;  &dealUrl(); which looks at the other file, updates lab urls, and 
# gives a list for Mary Ann.  Some entries don't match, so Cecilia can look at
# the output and deal with Zeros and Multiples manually.  Outputs renamed to :
# lab-researcher_inserstions.pg
# lab-url_insertions.pg
# 2005 11 15


use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;


my $outfile = 'outfile';
open(OUT, ">$outfile") or die "Cannot create $outfile : $!";

&dealResearch();
&dealUrl();

sub dealResearch {
  $/ = undef;
  my $infile = 'Leon_Researcher-Profiles';
  open (IN, "<$infile") or die "Cannot open $infile : $!";
  my $wholefile = <IN>;
  close (IN) or die "Cannot close $infile : $!";
#   my (@labs) = $wholefile =~ m/href=\"(.*?)\">The\s+(.*?)\s+Lab,\s+(.*?)<\/a>/msg;
  my (@labs) = $wholefile =~ m/href=\"(.*?)\">(\S+)[^,]*?(\S+),(.*?)<\/a>/msg;
  my $zero; my $multiple; my $good;
  while (@labs) {
    my $url = shift @labs; my $first = shift @labs; my $last = shift @labs; my $location = shift @labs;
    if ($first =~ m/\s+/) { $first =~ s/\s+/ /g; }
    if ($last =~ m/\s+/) { $last =~ s/\s+/ /g; }
    if ($location =~ m/\s+/) { $location =~ s/\s+/ /g; }
    if ($url =~ m/\s+/) { $url =~ s/\s+/ /g; }
    my $result = $conn->exec( "SELECT * FROM two_lastname WHERE two_lastname ~ '$last' AND joinkey IN ( SELECT joinkey FROM two_firstname WHERE two_firstname ~ '$first') " );
    my %joins;
    while (my @row = $result->fetchrow) { $joins{$row[0]}++; }
    if (scalar(keys %joins) < 1) { $zero .= "$last\t$first\t$url\n"; }
      elsif (scalar(keys %joins) == 1) {
        foreach my $join (sort keys %joins) { 
          &insertUrl($join, $url);
          $good .= "$join\t$url\t$last\t$first\n"; } }
      else {
        foreach my $join (sort keys %joins) { 
          $multiple .= "$url\t$last\t$first\t$join\n"; } }
  } # while (@labs)
  print OUT "\n\n";
  if ($zero) { print OUT "Zero :\n$zero\n\n"; }
  if ($multiple) { print OUT "Multiple :\n$multiple\n\n"; }
  if ($good) { print OUT "Good :\n$good\n\n"; }
} # sub dealResearch

sub dealUrl {
  $/ = undef;
  my $infile = 'Leon_lab-url';
  open (IN, "<$infile") or die "Cannot open $infile : $!";
  my $wholefile = <IN>;
  close (IN) or die "Cannot close $infile : $!";
  my (@labs) = $wholefile =~ m/href=\"(.*?)\">The\s+(.*?)\s+Lab,\s+(.*?)<\/a>/msg;
  my $good; my $multiple; my $zeropi; my $zerostreet;
  my $maryann;
  while (@labs) {
    my $url = shift @labs; my $name = shift @labs; my $location = shift @labs;
    if ($name =~ m/\s+/) { $name =~ s/\s+/ /g; }
    if ($location =~ m/\s+/) { $location =~ s/\s+/ /g; }
    if ($url =~ m/\s+/) { $url =~ s/\s+/ /g; }
    my $header = "$name\t$location\t$url\t";
    my $result = $conn->exec( "SELECT * FROM two_pis WHERE joinkey IN ( SELECT joinkey FROM two_standardname WHERE two_standardname ~ '$name') " );
    my %lab;
    while (my @row = $result->fetchrow) { $lab{$row[0]} = $row[2]; }
    if (scalar(keys %lab) < 1) { $zeropi .= "$header\n"; }
      elsif (scalar(keys %lab) == 1) {
        $good .= "$header";
        foreach my $join (sort keys %lab) { 
          $maryann .= "Laboratory : \"$lab{$join}\"\nWebpage\t\"$url\"\n\n";
          &insertUrl($join, $url);
          $good .= "$join\t$lab{$join}\n"; } }
      else {
        my $joins = join"', '", keys %lab; 
        my $result2 = $conn->exec( "SELECT * FROM two_street WHERE two_street ~ '$location' AND joinkey IN ( '$joins' ); " );
        my %joins;
        while (my @row2 = $result2->fetchrow) { $joins{$row2[0]}++; }
        if (scalar(keys %joins) < 1) { 
          $zerostreet .= $header;
          foreach my $join (sort keys %lab) { $zerostreet .= "$join\t$lab{$join}\t"; } 
          $zerostreet .= "\n"; }
        elsif (scalar(keys %joins) == 1) { 
          $good .= $header;
          foreach my $join (sort keys %joins) { 
            $maryann .= "Laboratory : \"$lab{$join}\"\nWebpage\t\"$url\"\n\n";
            &insertUrl($join, $url);
            $good .= "$join\t$lab{$join}\n"; } }
        else { 
          $multiple .= $header;
          foreach my $join (sort keys %joins) { $multiple .= "$join\t$lab{$join}\n"; } } }
  } # while (@labs)
  
  print OUT "$maryann\n\n";
  
  print OUT "Zero PIs :\n$zeropi\n\n";
  print OUT "Zero Street :\n$zerostreet\n\n";
  if ($multiple) { print OUT "Multiple Street :\n$multiple\n\n"; }
  print OUT "Good :\n$good\n\n";
} # sub dealUrl

# my $result = $conn->exec( "SELECT * FROM one_groups;" );
# while (my @row = $result->fetchrow) {
#   if ($row[0]) { 
#     $row[0] =~ s///g;
#     $row[1] =~ s///g;
#     $row[2] =~ s///g;
#   } # if ($row[0])
# } # while (@row = $result->fetchrow)

close (OUT) or die "Cannot close $outfile : $!";


sub insertUrl {
  my ($join, $url) = @_;
  print OUT "$join\t$url\n";
  my $result = $conn->exec( "SELECT * FROM two_webpage WHERE joinkey = '$join' AND two_webpage ~ '$url'; " );
  my $is_lab = 0;
  while (my @row = $result->fetchrow) { 
    if ($row[0]) { print OUT "There is a match @row\n"; $is_lab++; }
  } # while (my @row = $result->fetchrow) 
  unless ($is_lab) {
    $result = $conn->exec( "SELECT * FROM two_webpage WHERE joinkey = '$join' ORDER BY two_order DESC; " );
    my @row = $result->fetchrow;
    my $order = $row[1];
    $order++;
    my $command = "INSERT INTO two_webpage VALUES ('$join', $order, '$url', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP); ";
# UNCOMMENT THIS TO MAKE IT INSERT INTO POSTGRES
#     $result = $conn->exec( "$command" );
    print OUT "$command\n";
  } # unless ($is_lab)
} # sub insertUrl
