#!/usr/bin/env perl

# check how many author <-> paper connections there, how many have been assigned
# to possible persons, and how many have been verified  2007 02 27
#
# figure out how many people are not verifying their data.  2007 03 01
#
# Edited to get a list of PIs and their lineage associations.
# Look at each author->person that has not verified.  Find the Paper,
# find any PI that _has_ verified, and if the possible person is in the
# PI's lineage, print it out.  Sort by two# needing verification.
# 2007 03 08
#
# try to match by Lab and Oldlab instead of PI.  2007 03 08
#
# This program is a lot faster than the lineage program.  2007 03 16
#
# Converted from Pg.pm to DBI.pm  2009 04 17
#
# Converted for pap_ tables from wpa_
# Now does lineage and labs at the same time
# Also works recursively while there's data to connect.  2010 06 21
#
# Cecilia wants this to generate a log, and run every day on cronjob after the 
# connect_single_match_authors_and_get_histogram.pl  2025 10 03


# 15 5 * * tue,wed,thu,fri,sat /usr/caltech_curation_files/cecilia/new-upload/verify_by_labs_or_lineage.pl



use strict;
use diagnostics;
use Jex;
use DBI;
use Dotenv -load => '/usr/lib/.env';


my $dbh = DBI->connect ( "dbi:Pg:dbname=$ENV{PSQL_DATABASE};host=$ENV{PSQL_HOST};port=$ENV{PSQL_PORT}", "$ENV{PSQL_USERNAME}", "$ENV{PSQL_PASSWORD}") or die "Cannot connect to database!\n";
# my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "");
if ( !defined $dbh ) { die "Cannot connect to database!\n"; }

my %hash;

my $result;

my $date = &getSimpleSecDate();

my $outfile = $ENV{CALTECH_CURATION_FILES_INTERNAL_PATH} . "/cecilia/new-upload/logs/verify_by_labs_or_lineage.outfile.$date";
# my $outfile = "connect_authors.outfile";
open(OUT, ">$outfile") or die "Cannot create $outfile : $!";



my %labs;
# $result = $conn->exec( "SELECT * FROM two_lab ;" );
$result = $dbh->prepare( "SELECT * FROM two_lab ;" );
$result->execute;
while (my @row = $result->fetchrow) { 
  $labs{lab}{$row[2]}{$row[0]}++; 	# labs lab lab_code two#
  $labs{two}{$row[0]}{$row[2]}++; }	# labs lab two# lab_code 
$result = $dbh->prepare( "SELECT * FROM two_oldlab ;" );
$result->execute;
while (my @row = $result->fetchrow) { 
  $labs{lab}{$row[2]}{$row[0]}++; 	# labs lab lab_code two#
  $labs{two}{$row[0]}{$row[2]}++; }	# labs lab two# lab_code 

my %pis;
$result = $dbh->prepare( "SELECT joinkey, two_number FROM two_lineage WHERE joinkey IS NOT NULL AND two_number IS NOT NULL;" );
$result->execute;
while (my @row = $result->fetchrow) { $pis{assoc}{$row[0]}{$row[1]}++; }


my %std;	# get a hash of standardnames to output instead of two#
$result = $dbh->prepare( "SELECT * FROM two_standardname ;" );
$result->execute;
while (my @row = $result->fetchrow) { $std{$row[0]} = $row[2]; }



$result = $dbh->prepare( "SELECT * FROM pap_author;" );
$result->execute;
while (my @row = $result->fetchrow) {
  if ( ($row[1]) && ($row[0]) ) { $hash{aid}{$row[1]} = $row[0]; } }

$result = $dbh->prepare( "SELECT * FROM pap_author_possible;" );
$result->execute;
while (my @row = $result->fetchrow) {
  if ( ($row[2]) && ($row[1]) && ($row[0]) ) { $hash{pos}{$row[0]}{$row[2]} = $row[1]; } }

$result = $dbh->prepare( "SELECT * FROM pap_author_verified;" );
$result->execute;
while (my @row = $result->fetchrow) {
  if ( ($row[2]) && ($row[1]) && ($row[0]) ) { $hash{ver}{$row[0]}{$row[2]} = $row[1]; } }
  

my %people_in_paper;		# people verified to be in a paper
my %unver;			# people with possible but without verification

foreach my $aid (sort keys %{ $hash{pos} }) {
  my $paper = $hash{aid}{$aid};
  next unless ($paper);	# some papers are not valid, so they're not in %hash{aid} 
  foreach my $join (sort keys %{ $hash{pos}{$aid} }) {
    my $two = $hash{pos}{$aid}{$join};
    if ($hash{ver}{$aid}{$join}) { 	# verified, add to people_in_paper paper/two
        $people_in_paper{$paper}{$two}++; }
      else {				# put in %unver :  unverified aid/join -> two
        $unver{$aid}{$join} = $hash{pos}{$aid}{$join}; } } }	


my %sort;			# find matches, put them in here to sort by two person that has become verified
my $depth = 0;			# recursive depth of searching (keep looping until no new results)
&processByLab($depth);		# start at depth 0


sub processByLab {
  my ($depth) = @_;
  $depth++;
  print OUT "recursive depth $depth\n";
  my %pgcommands;	
  foreach my $aid (sort keys %unver) {
    foreach my $join (sort keys %{ $unver{$aid} }) {
      my $two = $unver{$aid}{$join};	# get each unverified two#
      if ($two) {
        my $paper = $hash{aid}{$aid};	# get the paper for that author_id
        next unless ($paper);		# some papers are not valid, so they're not in %hash{aid} 
        next unless ($labs{two}{$two});	# some people don't have labs
        foreach my $tip (sort keys %{ $people_in_paper{$paper} }) {	# tip == two in paper
          if ($labs{two}{$tip}) {	# if that person has a lab
            foreach my $labcode (sort keys %{ $labs{two}{$tip} }) {
              if ($labs{two}{$two}{$labcode}) {		# if they ever shared a lab
                next unless $unver{$aid}{$join};	# skip if already became verified earlier in $tip loop
                $people_in_paper{$paper}{$two}++;	# now possible two will be in paper
                delete $unver{$aid}{$join};		# no longer unverified
                my $command = "INSERT INTO pap_author_verified VALUES ('$aid', 'YES  Raymond Lee', '$join', 'two363', CURRENT_TIMESTAMP)";
                $pgcommands{$command}++;
                $command = "INSERT INTO h_pap_author_verified VALUES ('$aid', 'YES  Raymond Lee', '$join', 'two363', CURRENT_TIMESTAMP)";
                $pgcommands{$command}++;
                my $line = "$two A$depth\t$paper\t$aid\t$std{$two} ($two)\tOTHER $std{$tip} ($tip)\tLAB $labcode"; $sort{$two}{$line}++; }	# put in a sorting hash by possible two#
          elsif ($pis{assoc}{$tip}{$two}) { 	# if the two# of the possible matches an association in that person's lineage
            next unless $unver{$aid}{$join};	# skip if already became verified 
            $people_in_paper{$paper}{$two}++;	# now possible two will be in paper
            delete $unver{$aid}{$join};		# no longer unverified
            my $command = "INSERT INTO pap_author_verified VALUES ('$aid', 'YES Raymond Lee', '$join', 'two363', CURRENT_TIMESTAMP)";
            $pgcommands{$command}++;
            $command = "INSERT INTO h_pap_author_verified VALUES ('$aid', 'YES Raymond Lee', '$join', 'two363', CURRENT_TIMESTAMP)";
            $pgcommands{$command}++;
            my $line = "$two I$depth\t$paper\t$std{$two} ($two)\tPI $std{$tip} ($tip)\tA $aid J $join T $two E"; $sort{$two}{$line}++; }	# put in a sorting hash by possible two#

        } } }
  } } }

  my $again_flag = 0;

  foreach my $command (sort keys %pgcommands) {
    $again_flag++;
    print OUT "$command\n";
# UNCOMMENT THIS TO INSERT CONNECTIONS
    $result = $dbh->do( $command ); 
  } # foreach my $command (sort keys %pgcommands)
  
  %pgcommands = ();

  if ($again_flag > 0) { &processByLab($depth); }	# recurse this if there's data

} # sub processByLab

print OUT "\n\n";
my $two_count = 0;
foreach my $two (sort keys %sort) {
  $two_count++;
  foreach my $line (sort keys %{ $sort{$two}}) {
    print OUT "$line\n"; } }
print OUT "There are $two_count Person\n";



close(OUT) or die "Cannot close $outfile : $!";

