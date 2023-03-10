#!/usr/bin/perl

# Get list of wbpaper to other connection from Eimears paper2wbpaper.txt file.
# get connections from ref_xref and ref_xrefmed (the other ref_xref tables 
# don't have data)  Connect all possible WBPapers to all other connections
# a WBPaper it's connected to can connect to.  Filter itself out.  Insert into
# wpa_xref table.  Log output to outfile.  2005 06 10


use strict;
use diagnostics;
use Pg;

my %badWBID;
$badWBID{WBPaper00000938}++;
$badWBID{WBPaper00013006}++;
$badWBID{WBPaper00013326}++;
$badWBID{WBPaper00013339}++;
$badWBID{WBPaper00024181}++;

my %xref;
my %cgcXref;

my $old_xref_file = '/home/acedb/public_html/paper2wbpaper.txt';
open (IN, "<$old_xref_file") or die "Cannot open $old_xref_file : $!";
my $junk = <IN>;
# my $count = 0;
while (my $line = <IN>) {
#   $count++; if ($count > 1000) { last; }
  chomp($line);
  unless ($line =~ m/.+\t.+/) { print "BAD LINE $line\n"; next; }
  my ($other, $wb) = split/\t/, $line;
#   push @{ $xref{$wb} }, $other;
  $xref{$wb}{$other}++;
  if ($other =~ m/cgc/) { $cgcXref{$other}{$wb}++; }	# put wbs in cgc hash
}
close (IN) or die "Cannot close $old_xref_file : $!";

  # print out which ones are bad and what they correspond to.  result is :
# BAD WBPaper00013006     pmid11858839
# BAD WBPaper00013326     pmid14565976
# BAD WBPaper00013339     pmid14612577
# BAD WBPaper00024181     pmid15282161
# foreach my $badxref (sort keys %badWBID) {
#   if ($xref{$badxref}) {
#     my $bad = join", ", @{ $xref{$badxref} };
#     print "BAD $badxref\t$bad\n"; 
#   } # if ($xref{$badxref})
# } # foreach my $badxref (sort keys %badWBID)
# push @{ $xref{"WBPaper00013006"} }, "WBPaper00006101";
# push @{ $xref{"WBPaper00006101"} }, "WBPaper00013006";
# push @{ $xref{"WBPaper00006101"} }, "pmid11858839";
# push @{ $xref{"WBPaper00013326"} }, "WBPaper00006305";
# push @{ $xref{"WBPaper00006305"} }, "WBPaper00013326";
# push @{ $xref{"WBPaper00006305"} }, "pmid14565976";
# push @{ $xref{"WBPaper00013339"} }, "WBPaper00006234";
# push @{ $xref{"WBPaper00006234"} }, "WBPaper00013339";
# push @{ $xref{"WBPaper00006234"} }, "pmid14612577";
# push @{ $xref{"WBPaper00024181"} }, "WBPaper00024330";
# push @{ $xref{"WBPaper00024330"} }, "WBPaper00024181";
# push @{ $xref{"WBPaper00024330"} }, "pmid15282161";

$xref{"WBPaper00013006"}{"WBPaper00006101"}++;
$xref{"WBPaper00006101"}{"WBPaper00013006"}++;
$xref{"WBPaper00006101"}{"pmid11858839"}++;

$xref{"WBPaper00013326"}{"WBPaper00006305"}++;
$xref{"WBPaper00006305"}{"WBPaper00013326"}++;
$xref{"WBPaper00006305"}{"pmid14565976"}++;

$xref{"WBPaper00013339"}{"WBPaper00006234"}++;
$xref{"WBPaper00006234"}{"WBPaper00013339"}++;
$xref{"WBPaper00006234"}{"pmid14612577"}++;

$xref{"WBPaper00024181"}{"WBPaper00024330"}++;
$xref{"WBPaper00024330"}{"WBPaper00024181"}++;
$xref{"WBPaper00024330"}{"pmid15282161"}++;

# $xref{"WBPaper00024186"}{"cgc6593"}++;	# added manually to paper2wbpaper.txt file



my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $outfile = "outfile";
open(OUT, ">$outfile") or die "Cannot create $outfile : $!";

my $result = $conn->exec( "SELECT * FROM ref_xref;" );
while (my @row = $result->fetchrow) {
#   if ($row[0]) { print "$row[0]\n";}
#   if ($other =~ m/cgc/) { $cgcXref{$other}{$wb}++; }	# put wbs in cgc hash
  my $cgc = $row[0]; my $pmid = $row[1];
  if ($cgcXref{$cgc}) {
    foreach my $wb (sort keys %{ $cgcXref{$cgc} }) {
      $xref{$wb}{$pmid}++;
    } # foreach my $wb (sort keys %{ $xref{$cgc} })
  } # if ($cgcXref{$cgc})
  else { print "BAD CGC $cgc Has no WBPaper\n"; }
}

$result = $conn->exec( "SELECT * FROM ref_xrefmed;" );
while (my @row = $result->fetchrow) {
#   if ($row[0]) { print "$row[0]\n";}
#   if ($other =~ m/cgc/) { $cgcXref{$other}{$wb}++; }	# put wbs in cgc hash
  my $cgc = $row[0]; my $med = $row[1];
  if ($cgcXref{$cgc}) {
    foreach my $wb (sort keys %{ $cgcXref{$cgc} }) {
      $xref{$wb}{$med}++;
    } # foreach my $wb (sort keys %{ $xref{$cgc} })
  } # if ($cgcXref{$cgc})
  else { print "BAD CGC $cgc Has no WBPaper\n"; }
}


foreach my $wbpaper (sort keys %xref) {				# for each paper in xref hash
  foreach my $other (sort keys %{ $xref{$wbpaper} }) {		# look at ``other'' connections (cgc, pmid, etc.)
    if ($other =~ m/WBPaper/) {					# if it's another wbpaper
      $xref{$other}{$wbpaper}++;				# connect that other wbpaper to this one
      foreach my $extra (sort keys %{ $xref{$wbpaper} }) {	# for each ``other'' connection to main paper
        $xref{$other}{$extra}++;				# connect it to the ``other'' wbpaper
      } # foreach my $extra (sort keys %{ $xref{$wbpaper} }) 
    } # if ($other =~ m/WBPaper/)
  } # foreach my $other (sort keys %{ $xref{$wbpaper} }) {	
} # foreach my $wbpaper (sort keys %xref)

foreach my $wbpaper (sort keys %xref) {					# for each paper in xref hash
  if ($xref{$wbpaper}{$wbpaper}) { delete $xref{$wbpaper}{$wbpaper}; }	# delete reference to itself
} # foreach my $wbpaper (sort keys %xref)

foreach my $wbpaper (sort keys %xref) {	# for each paper in xref hash
  my $xrefs = join", ", keys %{ $xref{$wbpaper} };
  print OUT "$wbpaper\t$xrefs\n";
  foreach my $other (sort keys %{ $xref{$wbpaper} }) {
    $result = $conn->exec( "INSERT INTO wpa_xref VALUES ('$wbpaper', '$other'); " );
  } # foreach my $other (sort keys %{ $xref{$wbpaper} })
} # foreach my $wbpaper (sort keys %xref)

close (OUT) or die "Cannot close $outfile : $!";


