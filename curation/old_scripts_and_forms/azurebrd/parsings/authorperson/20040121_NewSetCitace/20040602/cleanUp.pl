#!/usr/bin/perl

# Read all pap_paper entries.  Read ref_xref to get cgc_pmid connections.
# Read .acefile (dump from citace of Paper objects), parse out papers that 
# don't have relevant data, parse out pmid papers that have a corresponding 
# CGC number (which is postgres but may not be in WormBase), insert entries
# into pap_ tables.  pap_author, pap_verified, pap_possible, and pap_email
# will not be easily recognizable by timestamp, all others should be.
#
# Just UNCOMMENT result lines for inserting to postgres, print lines for logfile.  
# Usage ./cleanUp.pl > cleanup.log 
# This will likely need to be rewritten once papers are stored by WBPaper
# sequence as joinkey instead of cgc/pmid/whatever.
# It took 2:05:37 to do 3251 papers.   2004 02 19
#
# It took 22mins to do the 2004 06 02 batch.  2004 06 02


use Pg;
use strict;
use diagnostics;


my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my %pg_papers;
my %pmid_xref;
my %cgc_xref;

my $result = $conn->exec( "SELECT * FROM pap_paper;");
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    my $paper = $row[0];
    $pg_papers{$paper}++;
#       if ($paper =~ m/cgc5717/) { print STDERR "cgc5717c\n"; }
  } # if ($row[0])
} # while (@row = $result->fetchrow)

$result = $conn->exec( "SELECT * FROM ref_xref;");
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[1] =~ s///g;
    my $pmid = $row[1];
    $pmid_xref{$pmid} = $row[0];
    $cgc_xref{$row[0]} = $pmid;
# if ($row[0] =~ m/cgc6314/) { print STDERR "cgc6314 $row[1]\n"; }
  } # if ($row[0])
} # while (@row = $result->fetchrow)

my $err = 'err';
open (ERR, ">$err") or die "Cannot create $err : $!";

$/ = "";
my $infile = 'citacePapers20040602.ace';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $entry = <IN>) {
  $entry =~ s/ \-. "[^"\\]*(\\.[^"\\]*)*"//g;	
	# take out space-hypen-something-space-
	# doublequote-anythingIncludingBackslashEscapedDoublequotes-doublequote
  my @entry = split/\n/, $entry;
  $entry = '';
  foreach my $ent (@entry) { 
    if ($ent =~ m/^Person/) { next; }
    elsif ($ent =~ m/^Keyword/) { next; }
    elsif ($ent =~ m/^Brief_citation/) { next; }
    elsif ($ent =~ m/^Publisher/) { next; }
    elsif ($ent =~ m/^Editor/) { next; }
    elsif ($ent =~ m/^Medline_acc/) { next; }
    elsif ($ent =~ m/^Abstract/) { next; }
    elsif ($ent =~ m/^Locus/) { next; }
    elsif ($ent =~ m/^Allele/) { next; }
    elsif ($ent =~ m/^Rearrangement/) { next; }
    elsif ($ent =~ m/^Sequence/) { next; }
    elsif ($ent =~ m/^CDS/) { next; }
    elsif ($ent =~ m/^Transcript/) { next; }
    elsif ($ent =~ m/^Pseudogene/) { next; }
    elsif ($ent =~ m/^Strain/) { next; }
    elsif ($ent =~ m/^Locus/) { next; }
    elsif ($ent =~ m/^Clone/) { next; }
    elsif ($ent =~ m/^Protein/) { next; }
    elsif ($ent =~ m/^Expr_pattern/) { next; }
    elsif ($ent =~ m/^Expr_profile/) { next; }
    elsif ($ent =~ m/^Cell/) { next; }
    elsif ($ent =~ m/^Cell_group/) { next; }
    elsif ($ent =~ m/^Life_stage/) { next; }
    elsif ($ent =~ m/^RNAi/) { next; }
    elsif ($ent =~ m/^Transgene/) { next; }
    elsif ($ent =~ m/^GO_term/) { next; }
    elsif ($ent =~ m/^Operon/) { next; }
    elsif ($ent =~ m/^Cluster/) { next; }
    elsif ($ent =~ m/^Feature/) { next; }
    elsif ($ent =~ m/^Gene_regulation/) { next; }
    elsif ($ent =~ m/^Microarray_experiment/) { next; }
    elsif ($ent =~ m/^Anatomy_term/) { next; }
    elsif ($ent =~ m/^Antibody/) { next; }
    elsif ($ent =~ m/^PMID/) { next; }
    else { $entry .= $ent . "\n"; }
  }
  $entry .= "\n";
#   $entry =~ s/\nLocus.*?//g;
#   $entry =~ s/\nStrain.*?//g;
#   $entry =~ s/\nRearrangement.*?//g;
#   $entry =~ s/\nPerson.*?//g;
#   $entry =~ s/\nKeyword.*?//g;
#   $entry =~ s/\nBrief_citation.*?//g;
#   $entry =~ s/\nPublisher.*?//g;
  if ($entry !~ m/^Paper.*?\n.*?\n.*?\n/) { $entry = ""; next; }	# get rid of single line entries
# print "$entry";	# print list of clean entries
  my ($paper) = $entry =~ m/Paper : "\[(.*)\]"/;
# print "PAP $paper\n";
  unless ($paper) {
    print "ERROR NO PAPER $entry\n"; }
  else {
#       if ($paper =~ m/cgc6314/) { print STDERR "cgc6314\n"; }
#       if ($paper =~ m/cgc5717/) { print STDERR "cgc5717a\n"; }
    if ($pmid_xref{$paper}) { print ERR "$paper not entered, $pmid_xref{$paper} EXISTS AS PMID XREF\n"; next; }
#     if ($cgc_xref{$paper}) { print ERR "$cgc_xref{$paper} EXISTS AS CGC XREF $paper\n"; next; }
    unless ($pg_papers{$paper}) { 
#       if ($paper =~ m/cgc5717/) { print STDERR "cgc5717b\n"; }
#       print "NEW PAPER $paper\n"; 
      &doPgStuff($paper, $entry) } }
} # while (<IN>)
close (IN) or die "Cannot close $infile : $!";
close (ERR) or die "Cannot close $err : $!";

sub doPgStuff {
  my ($paper, $entry) = @_;
#   print "Paper $paper\nEntry $entry\n";
  my @entry = split/\n/, $entry;
#       if ($paper =~ m/cgc5717/) { print STDERR "cgc5717\n"; }
  my $result;
# UNCOMMENT result lines for inserting to postgres, print lines for logfile
  print "\$result = \$conn->exec( \"INSERT INTO pap_paper VALUES ('$paper', '$paper');\" );\n";
  $result = $conn->exec( "INSERT INTO pap_paper VALUES ('$paper', '$paper');" );
#   print "$paper\tpaper $1\n"; 
  foreach my $ent (@entry) { 
#     $ent =~ s/\"/\\\"/g;i		# escape double quotes for postgres 
					# doesn't work for some reason, but already escape from acedb
    $ent =~ s/\'/''/g;			# escape single quotes for postgres 
    if ($ent =~ m/^Paper\s+\:\s+\"(.*)\"$/) { next; 
    } elsif ($ent =~ m/^Page\s+$/) { next; 
    } elsif ($ent =~ m/^Title\s+\"(.*)\"$/) { 
# UNCOMMENT result lines for inserting to postgres, print lines for logfile
      print "\$result = \$conn->exec( \"INSERT INTO pap_title VALUES ('$paper', '$1');\" );\n";
      $result = $conn->exec( "INSERT INTO pap_title VALUES ('$paper', '$1');" );
#       print "$paper\ttitle $1\n"; 
    } elsif ($ent =~ m/^In_book\s+(.*)$/) { next;
    } elsif ($ent =~ m/^Affiliation\s+\"(.*)\"$/) { 
      print "\$result = \$conn->exec( \"INSERT INTO pap_affiliation VALUES ('$paper', '$1');\" );\n";
      $result = $conn->exec( "INSERT INTO pap_affiliation VALUES ('$paper', '$1');" );
#       print "$paper\taffiliation $1\n"; 
    } elsif ($ent =~ m/^Journal\s+\"(.*)\"$/) {
      print "\$result = \$conn->exec( \"INSERT INTO pap_journal VALUES ('$paper', '$1');\" );\n";
      $result = $conn->exec( "INSERT INTO pap_journal VALUES ('$paper', '$1');" );
#       print "$paper\tjournal $1\n"; 
    } elsif ($ent =~ m/^Page\s+\"(.*)\"$/) { 
      my $page = $1; $page =~ s/\"//g;
      print "\$result = \$conn->exec( \"INSERT INTO pap_page VALUES ('$paper', '$page');\" );\n";
      $result = $conn->exec( "INSERT INTO pap_page VALUES ('$paper', '$page');" );
#       print "$paper\tpage $page\n"; 
    } elsif ($ent =~ m/^Volume\s+\"(.*)\"$/) { 
      print "\$result = \$conn->exec( \"INSERT INTO pap_volume VALUES ('$paper', '$1');\" );\n";
      $result = $conn->exec( "INSERT INTO pap_volume VALUES ('$paper', '$1');" );
#       print "$paper\tvolume $1\n"; 
    } elsif ($ent =~ m/^Year\s+\"?(.*)\"?$/) { 
      print "\$result = \$conn->exec( \"INSERT INTO pap_year VALUES ('$paper', '$1');\" );\n";
      $result = $conn->exec( "INSERT INTO pap_year VALUES ('$paper', '$1');" );
#       print "$paper\tyear $1\n"; 
    } elsif ($ent =~ m/^Type\s+\"(.*)\"$/) { 
      print "\$result = \$conn->exec( \"INSERT INTO pap_type VALUES ('$paper', '$1');\" );\n";
      $result = $conn->exec( "INSERT INTO pap_type VALUES ('$paper', '$1');" );
#       print "$paper\ttype $1\n"; 
    } elsif ($ent =~ m/^Author\s+\"(.*)\"$/) { 
      print "\$result = \$conn->exec( \"INSERT INTO pap_author VALUES ('$paper', '$1');\" );\n";
      $result = $conn->exec( "INSERT INTO pap_author VALUES ('$paper', '$1');" );
      print "\$result = \$conn->exec( \"INSERT INTO pap_possible VALUES ('$paper', '$1');\" );\n";
      $result = $conn->exec( "INSERT INTO pap_possible VALUES ('$paper', '$1');" );
      print "\$result = \$conn->exec( \"INSERT INTO pap_email VALUES ('$paper', '$1');\" );\n";
      $result = $conn->exec( "INSERT INTO pap_email VALUES ('$paper', '$1');" );
      print "\$result = \$conn->exec( \"INSERT INTO pap_verified VALUES ('$paper', '$1');\" );\n";
      $result = $conn->exec( "INSERT INTO pap_verified VALUES ('$paper', '$1');" );
#       print "$paper\tauthor $1\n"; 
    } else { print ERR "ERROR : Unknown Tag from ace dump $ent\n"; }
  }
  print "\n";

} # sub doPgStuff

# SELECT COUNT(*) FROM pap_paper WHERE pap_timestamp > '2004-02-18 18:00';
# SELECT COUNT(*) FROM pap_title WHERE pap_timestamp > '2004-02-18 18:00';
# SELECT COUNT(*) FROM pap_inbook WHERE pap_timestamp > '2004-02-18 18:00';
# SELECT COUNT(*) FROM pap_affiliation WHERE pap_timestamp > '2004-02-18 18:00';
# SELECT COUNT(*) FROM pap_journal WHERE pap_timestamp > '2004-02-18 18:00';
# SELECT COUNT(*) FROM pap_page WHERE pap_timestamp > '2004-02-18 18:00';
# SELECT COUNT(*) FROM pap_volume WHERE pap_timestamp > '2004-02-18 18:00';
# SELECT COUNT(*) FROM pap_year WHERE pap_timestamp > '2004-02-18 18:00';
# SELECT COUNT(*) FROM pap_type WHERE pap_timestamp > '2004-02-18 18:00';
# SELECT COUNT(*) FROM pap_author WHERE pap_timestamp > '2004-02-18 18:00';
# SELECT COUNT(*) FROM pap_possible WHERE pap_timestamp > '2004-02-18 18:00';
# SELECT COUNT(*) FROM pap_email WHERE pap_timestamp > '2004-02-18 18:00';
# SELECT COUNT(*) FROM pap_verified WHERE pap_timestamp > '2004-02-18 18:00';

# pap_paper
# pap_title
# pap_journal
# pap_page		# get rid of "s between numbers
# pap_volume
# pap_year
# pap_type
# pap_affiliation

# pap_author
# pap_possible
# pap_email
# pap_verified

# pap_inbook		# not using it
# pap_contained		# no entries
# pap_contains		# no entries
# pap_pmid		# not used
# pap_view		# not a table
