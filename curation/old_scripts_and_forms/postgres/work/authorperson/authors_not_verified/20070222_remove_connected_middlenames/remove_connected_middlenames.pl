#!/usr/bin/perl -w

# Find for each unconnected or unverified author the amount of possible people
# it could connect to.  Then connect those with only one match if the line for
# it is uncommented.  2006 07 11

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my %authors;

my $outfile = "connect_authors.outfile";
open(OUT, ">$outfile") or die "Cannot create $outfile : $!";

my %aka_hash = &getPgHash();
my %aka_hash_good = &getPgHashGood();

my %histogram;
my $total_authors;
my %auth_name;			# key name, value aid


my %author_possible;            # keys author_id, wpa_join, value possible two#
my %author_verified;            # keys author_id, wpa_join, value YES / NO / NULL (no answer) 

# my $result = $conn->exec( "SELECT * FROM wpa_author_possible ORDER BY wpa_timestamp;" );
# while (my @row = $result->fetchrow) {
#   next unless $row[1];
#   if ($row[3] eq 'valid') { $author_possible{$row[0]}{$row[2]} = $row[1]; }
#     else { delete $author_possible{$row[0]}{$row[2]}; } }

my $result = $conn->exec( "SELECT * FROM wpa_author_possible WHERE wpa_curator = 'two1823' ORDER BY wpa_timestamp;" );
while (my @row = $result->fetchrow) {
  next unless $row[1];
  if ($row[3] eq 'valid') { $author_possible{$row[0]}{$row[2]} = $row[1]; }
    else { delete $author_possible{$row[0]}{$row[2]}; } }

$result = $conn->exec( "SELECT * FROM wpa_author_verified ORDER BY wpa_timestamp;" );
while (my @row = $result->fetchrow) {
  next unless $row[1];
  if ($row[3] eq 'valid') { $author_verified{$row[0]}{$row[2]} = $row[1]; }
    else { delete $author_verified{$row[0]}{$row[2]}; } }

  # Delete from twos those who are not correct leaving in %author_possible authors that don't need to be connected
foreach my $aid (sort keys %author_verified) {
  foreach my $wpa_join (sort keys %{ $author_verified{$aid} }) {
    if ($author_verified{$aid}{$wpa_join} =~ m/NO/) { delete $author_possible{$aid}{$wpa_join}; } } }

my %paper_by_aid;
$result = $conn->exec( "SELECT * FROM wpa_author ORDER BY wpa_timestamp; " );
while (my @row = $result->fetchrow) { if ($row[1]) { if ($row[3] eq 'valid') { $paper_by_aid{$row[1]} = $row[0]; } else { delete $paper_by_aid{$row[1]}; } } }


$result = $conn->exec( "SELECT wpa_author_index, author_id, wpa_valid FROM wpa_author_index ORDER BY author_id, wpa_timestamp;" );
my $curr_auth = ''; my %auth_filter;
while (my @row = $result->fetchrow) {
  next unless ($author_possible{$row[1]});
  if ($curr_auth ne $row[1]) { 
    $curr_auth = $row[1];
    foreach my $auth (sort keys %auth_filter) { $authors{$auth}++; }
    %auth_filter = (); }
  if ($row[0]) { 
    if ($row[0] =~ m/,/) { $row[0] =~ s/,//g; }
    if ($row[0] =~ m/\./) { $row[0] =~ s/\.//g; }
    if ($row[2] eq 'valid') { $auth_filter{$row[0]}++; push @{$auth_name{$row[0]}} , $row[1]; }
      else { delete $auth_filter{$row[0]}; }
  }
}

my %auts;
my $dubious_authors = '';
foreach my $author (sort keys %authors) {
  $total_authors++;
  my $line = "$author";
  my $twos = ''; my $aids = '';
  my $orig_author = $author;
  $author = lc($author); 
  my $count = 0;
  my $next = 0;				# skip flag if there are too many two matches for that author
  if ($aka_hash{$author}) {
      next if ($aka_hash_good{$author});		# skip those that should be connected (last first ;  first last)
      my @twos = keys %{ $aka_hash{$author} };
      $count = scalar(@twos);
      $histogram{count}{$count}++;
      if ($count > 20) { $dubious_authors .= "Author $orig_author AIDs @{ $auth_name{$orig_author} }\n"; $next++; }
      $twos = join", ", @twos; }
    else { $histogram{count}{0}++; }
  next if $next;
  foreach my $aid (@{ $auth_name{$orig_author} }) { if ($paper_by_aid{$aid}) { $aids .= "${aid}($paper_by_aid{$aid}) "; } else { $aids .= "$aid "; } }
  $line .= "\t$count\t$twos\t$aids"; 
  push @{ $auts{$count} }, $line;
} # foreach my $author (sort keys %authors)

if ($dubious_authors) { print "\n\nPossibly not real authors :\n$dubious_authors\n\n"; }

foreach my $count (reverse sort {$a <=> $b} keys %auts) {
  foreach my $line (@{ $auts{$count} }) { 
    print OUT "$line\n"; } }

print OUT "\n\nDIVIDER\n\n\n";

print OUT "There are $total_authors different Author names\n";
print OUT "# of Hits\tInstances with # of Hits\n";
foreach my $count (reverse sort {$a<=>$b} keys %{ $histogram{count} }) {
  print OUT "$count\t$histogram{count}{$count}\n";
} # foreach my $count (reverse sort keys %{ $histogram{count} })

print OUT "\n\n";

foreach my $line (@{ $auts{'1'} }) { 
  my ($aname, $count, $two, $aids) = split/\t/, $line;
  my (@stuff) = split/\s+/, $aids;
  my $too_many = 0;
  foreach my $stuff (@stuff) { 
    my ($aid, $wbpaper) = $stuff =~ m/(\d+)\((\d+)\)/g;
    unless ($wbpaper) { print OUT "SKIPPING $stuff NO wbpaper\n"; next; }
      # GET HIGHEST wpa_join FOR ALL AUTHORS IN A WBPAPER
    $result = $conn->exec( "SELECT * FROM wpa_author_possible WHERE author_id IN (SELECT wpa_author FROM wpa_author WHERE joinkey = '$wbpaper') ORDER BY wpa_join DESC; " );
    print OUT "SELECT * FROM wpa_author_possible WHERE author_id IN (SELECT wpa_author FROM wpa_author WHERE joinkey = '$wbpaper') ORDER BY wpa_join DESC; \n" ;
    while ( my @row = $result->fetchrow) {
      my $wpa_join = $row[2]; 
      if ( ($row[1] eq "two$two") && ($row[0] eq $aid) ) {
        print OUT "Connect JOIN $wbpaper AID $aid TWO $two JOIN $wpa_join END\n";
    } }
# THIS WAS TO ADD NEW MIDDLENAME MATCHES, NOT REMOVE, SO DON'T RUN THIS
#     my $command = "INSERT INTO wpa_author_possible VALUES ('$aid', 'two$two', '$wpa_join', 'valid', 'two1823', CURRENT_TIMESTAMP)";
#     print OUT "AID $aid PAPER $wbpaper : $command\n";
# UNCOMMENT THIS TO RUN IT
#     $result = $conn->exec( $command );
  }
  print OUT "$line\n"; 
} # foreach my $line (@{ $auts{'1'} })


close (OUT) or die "Cannot close $outfile : $!";


sub getPgHash {				# get akaHash from postgres instead of flatfile
  my $result;
  my %filter;
  my %aka_hash;
  
  my @tables = qw (first middle last);
  foreach my $table (@tables) { 
    $result = $conn->exec ( "SELECT * FROM two_aka_${table}name WHERE two_aka_${table}name IS NOT NULL AND two_aka_${table}name != 'NULL' AND two_aka_${table}name != '';" );
    while ( my @row = $result->fetchrow ) {
      if ($row[3]) { 					# if there's a time
        my $joinkey = $row[0];
        $row[2] =~ s/^\s+//g; $row[2] =~ s/\s+$//g;	# take out spaces in front and back
        $row[2] =~ s/[\,\.]//g;				# take out commas and dots
        $row[2] =~ s/_/ /g;				# replace underscores for spaces
        $row[2] = lc($row[2]);				# for full values (lowercase it)
        $row[0] =~ s/two//g;				# take out the 'two' from the joinkey
        $filter{$row[0]}{$table}{$row[2]}++;
        my ($init) = $row[2] =~ m/^(\w)/;		# for initials
        $filter{$row[0]}{$table}{$init}++;
      }
    }
    $result = $conn->exec ( "SELECT * FROM two_${table}name WHERE two_${table}name IS NOT NULL AND two_${table}name != 'NULL' AND two_${table}name != '';" );
    while ( my @row = $result->fetchrow ) {
      if ($row[3]) { 					# if there's a time
        my $joinkey = $row[0];
        $row[2] =~ s/^\s+//g; $row[2] =~ s/\s+$//g;	# take out spaces in front and back
        $row[2] =~ s/[\,\.]//g;				# take out commas and dots
        $row[2] =~ s/_/ /g;				# replace underscores for spaces
        $row[2] = lc($row[2]);				# for full values (lowercase it)
        $row[0] =~ s/two//g;				# take out the 'two' from the joinkey
        $filter{$row[0]}{$table}{$row[2]}++;
        my ($init) = $row[2] =~ m/^(\w)/;		# for initials
        $filter{$row[0]}{$table}{$init}++;
      }
    }
  } # foreach my $table (@tables)

  my $possible;
  foreach my $person (sort keys %filter) { 
    foreach my $last (sort keys %{ $filter{$person}{last}} ) {
      foreach my $first (sort keys %{ $filter{$person}{first}} ) {
        $possible = "$first"; $aka_hash{$possible}{$person}++;
        $possible = "$last"; $aka_hash{$possible}{$person}++;
        $possible = "$last $first"; $aka_hash{$possible}{$person}++;
        $possible = "$first $last"; $aka_hash{$possible}{$person}++;
        if ( $filter{$person}{middle} ) {			# Cecilia want no middle name matches  2006 11 20
          foreach my $middle (sort keys %{ $filter{$person}{middle}} ) {
              $possible = "$middle"; $aka_hash{$possible}{$person}++;
              $possible = "$first $middle"; $aka_hash{$possible}{$person}++;
              $possible = "$middle $first"; $aka_hash{$possible}{$person}++;
            $possible = "$last $middle"; $aka_hash{$possible}{$person}++;
            $possible = "$last $first $middle"; $aka_hash{$possible}{$person}++;
            $possible = "$last $middle $first"; $aka_hash{$possible}{$person}++;
              $possible = "$middle $last"; $aka_hash{$possible}{$person}++;
            $possible = "$first $middle $last"; $aka_hash{$possible}{$person}++;
              $possible = "$middle $first $last"; $aka_hash{$possible}{$person}++;
          } # foreach my $middle (sort keys %{ $filter{$person}{middle}} )
        }
      } # foreach my $first (sort keys %{ $filter{$person}{first}} )
    } # foreach my $last (sort keys %{ $filter{$person}{last}} )
  } # foreach my $person (sort keys %filter) 

  return %aka_hash;
} # sub getPgHash

sub getPgHashGood {				# get akaHash from postgres instead of flatfile
  my $result;
  my %filter;
  my %aka_hash_good;
  
  my @tables = qw (first middle last);
  foreach my $table (@tables) { 
    $result = $conn->exec ( "SELECT * FROM two_aka_${table}name WHERE two_aka_${table}name IS NOT NULL AND two_aka_${table}name != 'NULL' AND two_aka_${table}name != '';" );
    while ( my @row = $result->fetchrow ) {
      if ($row[3]) { 					# if there's a time
        my $joinkey = $row[0];
        $row[2] =~ s/^\s+//g; $row[2] =~ s/\s+$//g;	# take out spaces in front and back
        $row[2] =~ s/[\,\.]//g;				# take out commas and dots
        $row[2] =~ s/_/ /g;				# replace underscores for spaces
        $row[2] = lc($row[2]);				# for full values (lowercase it)
        $row[0] =~ s/two//g;				# take out the 'two' from the joinkey
        $filter{$row[0]}{$table}{$row[2]}++;
        unless ($table eq 'last') {                     # look at initials for first and middle but not last name
          my ($init) = $row[2] =~ m/^(\w)/;		# for initials
          $filter{$row[0]}{$table}{$init}++; }
      }
    }
    $result = $conn->exec ( "SELECT * FROM two_${table}name WHERE two_${table}name IS NOT NULL AND two_${table}name != 'NULL' AND two_${table}name != '';" );
    while ( my @row = $result->fetchrow ) {
      if ($row[3]) { 					# if there's a time
        my $joinkey = $row[0];
        $row[2] =~ s/^\s+//g; $row[2] =~ s/\s+$//g;	# take out spaces in front and back
        $row[2] =~ s/[\,\.]//g;				# take out commas and dots
        $row[2] =~ s/_/ /g;				# replace underscores for spaces
        $row[2] = lc($row[2]);				# for full values (lowercase it)
        $row[0] =~ s/two//g;				# take out the 'two' from the joinkey
        $filter{$row[0]}{$table}{$row[2]}++;
        unless ($table eq 'last') {                     # look at initials for first and middle but not last name
          my ($init) = $row[2] =~ m/^(\w)/;		# for initials
          $filter{$row[0]}{$table}{$init}++; }
      }
    }
  } # foreach my $table (@tables)

  my $possible;
  foreach my $person (sort keys %filter) { 
    foreach my $last (sort keys %{ $filter{$person}{last}} ) {
      foreach my $first (sort keys %{ $filter{$person}{first}} ) {
#         $possible = "$first"; $aka_hash_good{$possible}{$person}++;
#         $possible = "$last"; $aka_hash_good{$possible}{$person}++;
        $possible = "$last $first"; $aka_hash_good{$possible}{$person}++;
        $possible = "$first $last"; $aka_hash_good{$possible}{$person}++;
        if ( $filter{$person}{middle} ) {			# Cecilia want no middle name matches  2006 11 20
								# Middle names okay if first and last two in specific ways   2007 02 22
          foreach my $middle (sort keys %{ $filter{$person}{middle}} ) {
# #            $possible = "$middle"; $aka_hash_good{$possible}{$person}++;
# #            $possible = "$first $middle"; $aka_hash_good{$possible}{$person}++;
# #            $possible = "$middle $first"; $aka_hash_good{$possible}{$person}++;
#             $possible = "$last $middle"; $aka_hash_good{$possible}{$person}++;
            $possible = "$last $first $middle"; $aka_hash_good{$possible}{$person}++;
#             $possible = "$last $middle $first"; $aka_hash_good{$possible}{$person}++;
# #            $possible = "$middle $last"; $aka_hash_good{$possible}{$person}++;
            $possible = "$first $middle $last"; $aka_hash_good{$possible}{$person}++;
# #            $possible = "$middle $first $last"; $aka_hash_good{$possible}{$person}++;
          } # foreach my $middle (sort keys %{ $filter{$person}{middle}} )
        }
      } # foreach my $first (sort keys %{ $filter{$person}{first}} )
    } # foreach my $last (sort keys %{ $filter{$person}{last}} )
  } # foreach my $person (sort keys %filter) 

  return %aka_hash_good;
} # sub getPgHashGood

