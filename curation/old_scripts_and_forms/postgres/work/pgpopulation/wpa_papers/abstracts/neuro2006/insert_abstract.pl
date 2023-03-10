#!/usr/bin/perl

# Wrote a script to deal with the output of the other script because Andrei hand
# edited the results instead of the source file.  2006 07 28
#
# Entered Neuro data.  2006 07 29

use strict;
use diagnostics;

use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $current_wpa = '';
my $current_aid = '';
my $result = $conn->exec( "SELECT wpa FROM wpa ORDER BY joinkey DESC;" );
my @row = $result->fetchrow;
if ($row[0]) { $current_wpa = $row[0]; }
$result = $conn->exec( "SELECT author_id FROM wpa_author_index ORDER BY author_id DESC;" );
@row = $result->fetchrow;
if ($row[0]) { $current_aid = $row[0]; } 



# unless ($ARGV[0]) { die "Need an inputfile ./parse_abstract.pl inputfile\n"; }

# my $infile = 'access_abstract.xml.out';
my $infile = 'Neuro_Meeting_Abstracts_2006.xml';
my $outfile = $infile . '.postgres';

$/ = undef;
open (IN, "<$infile") or die "Cannot open $infile : $!";
my $all_abstracts = <IN>;
close (IN) or die "Cannot close $infile : $!";

open (OUT, ">$outfile") or die "Cannot create $outfile : $!";

my (@abstracts) = split/\nPaper : "WBPaper000#####"/, $all_abstracts;
my %ids;
foreach my $atext (@abstracts) {
  $current_wpa++;
  my $joinkey = '000' . $current_wpa;
  my ($title, $authors, $body, $id);
  my $command = "INSERT INTO wpa VALUES ('$joinkey', '$current_wpa', NULL, 'valid', 'two480', CURRENT_TIMESTAMP);";
  print OUT "$command\n";
#   my $result2 = $conn->exec( $command );
  if ($atext =~ m/Meeting_abstract\t\"(neubehwm06abs\d+)\"/) { $id = $1; }
  $command = "INSERT INTO wpa_identifier VALUES ('$joinkey', '$id', NULL, 'valid', 'two480', CURRENT_TIMESTAMP);";
  print OUT "$command\n";
#   $result2 = $conn->exec( $command );
  $command = "INSERT INTO wpa_type VALUES ('$joinkey', '3', NULL, 'valid', 'two480', CURRENT_TIMESTAMP);";
  print OUT "$command\n";
#   $result2 = $conn->exec( $command );
  $command = "INSERT INTO wpa_year VALUES ('$joinkey', '2006', NULL, 'valid', 'two480', CURRENT_TIMESTAMP);";
  print OUT "$command\n";
#   $result2 = $conn->exec( $command );
  $command = "INSERT INTO wpa_journal VALUES ('$joinkey', 'Neuronal Development, Synaptic Function, and Behavior Meeting', NULL, 'valid', 'two480', CURRENT_TIMESTAMP);";
  print OUT "$command\n";
#   $result2 = $conn->exec( $command );
  if ($atext =~ m/Title\t\"(.*?)\"\n/s) { $title = $1; }
  if ($title =~ m/\n/) { $title =~ s/\n/ /sg; }
  if ($title =~ m/^\s+/) { $title =~ s/^\s+//; } 
  if ($title =~ m/\s+$/) { $title =~ s/\s+$//; } 
  if ($title =~ m/\'/) { $title =~ s/\'/''/g; }
  $command = "INSERT INTO wpa_title VALUES ('$joinkey', '$title', NULL, 'valid', 'two480', CURRENT_TIMESTAMP);";
  print OUT "$command\n";
#   $result2 = $conn->exec( $command );
  if ($atext =~ m/Author\t\"(.*?)\"\n/) { 
    my (@authors) = $atext =~ m/Author\t\"(.*?)\"\n/g; 
    my $aut_count = 0;
    foreach my $author (@authors) { 
      $aut_count++;
      $current_aid++; if ($author =~ m/\'/) { $author =~ s/\'/''/g; }
      $command = "INSERT INTO wpa_author VALUES ('$joinkey', '$current_aid', '$aut_count', 'valid', 'two480', CURRENT_TIMESTAMP);";
      print OUT "$command\n";
#       $result2 = $conn->exec( $command );
      $command = "INSERT INTO wpa_author_index VALUES ('$current_aid', '$author', NULL, 'valid', 'two480', CURRENT_TIMESTAMP);";
      print OUT "$command\n";
#       $result2 = $conn->exec( $command );
    }
  }
  if ($atext =~ m/Abstract\t\"(.*?)\"\n$/s) { $body = $1; }
  if ($body =~ m/\'/) { $body =~ s/\'/''/g; }
  if ($body =~ m/^\s+/) { $body =~ s/^\s+//; } 
  if ($body =~ m/\s+$/) { $body =~ s/\s+$//; } 
  $command = "INSERT INTO wpa_abstract VALUES ('$joinkey', '$body', NULL, 'valid', 'two480', CURRENT_TIMESTAMP);";
  print OUT "$command\n";
#   $result2 = $conn->exec( $command );
  print OUT "\n";
} # foreach my $atext (@abstracts)



close (OUT) or die "Cannot close $outfile : $!";

__END__

