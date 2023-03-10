#!/usr/bin/perl -w

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
# /home/postgres/work/get_stuff/for_cecilia/authors_ver_or_notconnected/using_labs/get_recent.pl
# /home/postgres/work/get_stuff/for_cecilia/authors_ver_or_notconnected/using_lineage/get_recent.pl
# 
# The lab program should only need to be ran once, and should be ran
# first.  The lineage program could create more possible connections
# after it's ran once, so it should be ran over and over until it 
# creates no new connections.
# 
# Output writes to the screen, so redirect to a file
#   ./get_recent.pl > outfile
# So far logging test runs to huh# and real runs to log.date.time
# 
# To test comment out the postgres INSERT command
# To run and make verified connections uncomment the INSERT command
# 
# The lineage based says ``YES Raymond Lee''
# The lab based says ``YES  Raymond Lee'' (with an extra space)
# to tell apart which script it used.  The date from the logfile
# as well as the connection existing in the logfile should properly tell
# what's what though.  2007 03 16
#
# Convert from Pg.pm to DBI.pm  2009 04 17


use strict;
use diagnostics;
# use Pg;
use DBI;

# my $conn = Pg::connectdb("dbname=testdb");
# die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "");
if ( !defined $dbh ) { die "Cannot connect to database!\n"; }

my %hash;

my %invalid_papers;

# my $result = $conn->exec( " SELECT * FROM wpa ORDER BY wpa_timestamp; " );
my $result = $dbh->prepare( " SELECT * FROM wpa ORDER BY wpa_timestamp; " );
$result->execute;
while (my @row = $result->fetchrow) {
  if ($row[3] ne 'valid') { $invalid_papers{$row[0]}++; }
    else { if ($invalid_papers{$row[0]}) { delete $invalid_papers{$row[0]}; } } }

my %have_email;
# $result = $conn->exec( "SELECT * FROM two_email WHERE two_email IS NOT NULL;" );
$result = $dbh->prepare( "SELECT * FROM two_email WHERE two_email IS NOT NULL;" );
$result->execute;
while (my @row = $result->fetchrow) { $have_email{$row[0]}++; }

  # get the pis (or all standardnames if want to do it that way) and their lineage info
my %pis;	# exist/two ;  assoc/two/other_two (for associations to other twos)
# $result = $conn->exec( "SELECT * FROM two_pis ;" );			# USE THIS TO CONNECT PEOPLE JUST OFF PIS
# $result = $conn->exec( "SELECT * FROM two_standardname ;" );		# USE THIS TO GET ALL PEOPLE INSTEAD OF JUST PIs
$result = $dbh->prepare( "SELECT * FROM two_standardname ;" );		# USE THIS TO GET ALL PEOPLE INSTEAD OF JUST PIs
$result->execute;
while (my @row = $result->fetchrow) { $pis{exist}{$row[0]}++; }

# $result = $conn->exec( "SELECT joinkey, two_number FROM two_lineage WHERE joinkey IS NOT NULL AND two_number IS NOT NULL;" );
$result = $dbh->prepare( "SELECT joinkey, two_number FROM two_lineage WHERE joinkey IS NOT NULL AND two_number IS NOT NULL;" );
$result->execute;
while (my @row = $result->fetchrow) { $pis{assoc}{$row[0]}{$row[1]}++; }

my %std;	# get a hash of standardnames to output instead of two#
# $result = $conn->exec( "SELECT * FROM two_standardname ;" );
$result = $dbh->prepare( "SELECT * FROM two_standardname ;" );
$result->execute;
while (my @row = $result->fetchrow) { $std{$row[0]} = $row[2]; }


# $result = $conn->exec( "SELECT * FROM wpa_author ORDER BY wpa_timestamp;" );
$result = $dbh->prepare( "SELECT * FROM wpa_author ORDER BY wpa_timestamp;" );
$result->execute;
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    next if ($invalid_papers{$row[0]});
    $row[0] =~ s///g;
    $row[2] =~ s///g;
    if ($row[3] eq 'valid') { $hash{aid}{$row[1]} = $row[0]; }
      else { delete $hash{aid}{$row[1]}; }
  } # if ($row[0])
} # while (@row = $result->fetchrow)

# $result = $conn->exec( "SELECT * FROM wpa_author_possible ORDER BY wpa_timestamp;" );
$result = $dbh->prepare( "SELECT * FROM wpa_author_possible ORDER BY wpa_timestamp;" );
$result->execute;
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    if ($row[3] eq 'valid') { $hash{pos}{$row[0]}{$row[2]} = $row[1]; }
      else { delete $hash{pos}{$row[0]}{$row[2]}; }
  } # if ($row[0])
} # while (@row = $result->fetchrow)

# $result = $conn->exec( "SELECT * FROM wpa_author_verified ORDER BY wpa_timestamp;" );
$result = $dbh->prepare( "SELECT * FROM wpa_author_verified ORDER BY wpa_timestamp;" );
$result->execute;
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    if ($row[3] eq 'valid') { $hash{ver}{$row[0]}{$row[2]} = $row[1]; }
      else { delete $hash{ver}{$row[0]}{$row[2]}; }
  } # if ($row[0])
} # while (@row = $result->fetchrow)


my %people_in_paper;		# people verified to be in a paper
foreach my $aid (sort keys %{ $hash{ver} }) {
  foreach my $join (sort keys %{ $hash{ver}{$aid} }) {
    next unless ($hash{ver}{$aid}{$join});
    my $paper = $hash{aid}{$aid};
    next unless ($paper);	# some papers are not valid, so they're not in %hash{aid} 
    my $two = $hash{pos}{$aid}{$join};
    next unless ($two);
    $people_in_paper{$paper}{$two}++;
} }

my %unver;	# people with possible but without verification
foreach my $aid (sort keys %{ $hash{pos} }) {
  foreach my $join (sort keys %{ $hash{pos}{$aid} }) {
    unless ($hash{ver}{$aid}{$join}) { $unver{$aid}{$join} = $hash{pos}{$aid}{$join}; } } }	
 # put in %unver :  unverified aid/join -> two

my %sort;	# find matches, put them in here to sort by paper
my %execs;
foreach my $aid (sort keys %unver) {
  foreach my $join (sort keys %{ $unver{$aid} }) {
    my $two = $unver{$aid}{$join};	# get each unverified two#
    if ($two) { 
      my $paper = $hash{aid}{$aid};	# get the paper for that author_id
      next unless ($paper);		# some papers are not valid, so they're not in %hash{aid} 
      foreach my $pi (sort keys %{ $people_in_paper{$paper} }) {
        if ($pis{exist}{$pi}) { 	# if there's a pi in the list of people verified to be in that paper
#           print "PI $pi PI "; 
#           print "A $aid J $join T $two P $paper E\n"; 
          if ($pis{assoc}{$pi}{$two}) { 	# if the two# of the possible matches an association in that pi's lineage
            my $command = "INSERT INTO wpa_author_verified VALUES ('$aid', 'YES Raymond Lee', '$join', 'valid', 'two363', CURRENT_TIMESTAMP)";
	      # raymond verifies these connections are probably good
            $execs{$command}++;
            my $line = "$paper\t$std{$two} ($two)\tPI $std{$pi} ($pi)\tA $aid J $join T $two E"; $sort{$two}{$line}++; }	# put in a sorting hash by possible two#
      } }
} } }

foreach my $command (sort keys %execs) {
  print "$command\n";
#   $result = $conn->exec( $command );
# UNCOMMENT THIS TO INSERT CONNECTIONS
  $result = $dbh->prepare( $command ); $result->execute;
} # foreach my $command (sort keys %execs)

my $two_count = 0;
foreach my $two (sort keys %sort) {
  $two_count++;
  foreach my $line (sort keys %{ $sort{$two}}) {
    print "$line\n"; } }
print "There are $two_count Persons\n";


__END__

my $aidc = 0;
my $posc = 0;
my $verc = 0;

foreach my $aid (sort keys %{ $hash{aid} }) {
  $aidc++;
  if ($hash{pos}{$aid}) {
    foreach my $join (sort keys %{ $hash{pos}{$aid}}) {
      next unless ($hash{pos}{$aid}{$join});
      $posc++;
      if ($hash{ver}{$aid}{$join}) { $verc++; }
    } # foreach my $join (sort keys %{ $hash{pos}{$aid}})
  } # if ($hash{pos}{$aid})
} # foreach my $aid (sort keys %{ $hash{aid} })

print "A $aidc\tP $posc\tV $verc\n";

my %unver_two;
my %some_ver_two;
foreach my $aid (sort keys %{ $hash{aid} }) {
  if ($hash{pos}{$aid}) {
    foreach my $join (sort keys %{ $hash{pos}{$aid}}) {
      next unless ($hash{pos}{$aid}{$join});
      my $two = $hash{pos}{$aid}{$join};
      unless ($two) { print "A $aid J $join E\n"; }
      if ($hash{ver}{$aid}{$join}) { $some_ver_two{ $two }++; }		# something verified
        else { $unver_two{ $two }++; }					# something not verified
    } # foreach my $join (sort keys %{ $hash{pos}{$aid}})
  } # if ($hash{pos}{$aid})
} # foreach my $aid (sort keys %{ $hash{aid} })

foreach my $two (sort keys %unver_two) {
  if ($have_email{$two}) {
    print "Some Unver $two T\n"; 
    unless ($some_ver_two{$two}) { print "Never Ver $two T\n"; }
  }
}

