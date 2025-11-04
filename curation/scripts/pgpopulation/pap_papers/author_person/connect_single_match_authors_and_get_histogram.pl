#!/usr/bin/env perl

# Find for each unconnected or unverified author the amount of possible people
# it could connect to.  Then connect those with only one match if the line for
# it is uncommented.  2006 07 11

# Prevent invalid wpas and twos from being mentioned.  2007 10 11
#
# Use wpa_ignore instead of cur_comment for ignoring functional annotations
# and not worm.  2008 10 08
#
# explicitly reject twos from aids that have been rejected.  this seems to 
# make no difference in results  2009 04 07
#
# convert from Pg.pm to DBI.pm  2009 04 17
#
# add matches in %aka_hash of '<last> <first><middle>' and '<first><middle> <last>'
# 2011 04 20
#
# got rid of pap_ignore , it no longer exists.  2011 06 04
#
# Changed 'functional_annotation' to 'non_nematode' to match change to postgres.  2013 12 05
#
# Cecilia wants this on a cronjob that runs every day and keeps a log.  2025 10 03


# 0 5 * * tue,wed,thu,fri,sat /usr/caltech_curation_files/cecilia/new-upload/connect_single_match_authors_and_get_histogram.pl


use strict;
use diagnostics;
use DBI;
use Jex;
use Dotenv -load => '/usr/lib/.env';

# die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $dbh = DBI->connect ( "dbi:Pg:dbname=$ENV{PSQL_DATABASE};host=$ENV{PSQL_HOST};port=$ENV{PSQL_PORT}", "$ENV{PSQL_USERNAME}", "$ENV{PSQL_PASSWORD}") or die "Cannot connect to database!\n";
# my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

# my $conn = Pg::connectdb("dbname=testdb");


my %authors;

my $date = &getSimpleSecDate();

my $outfile = $ENV{CALTECH_CURATION_FILES_INTERNAL_PATH} . "/cecilia/new-upload/logs/connect_authors.outfile.$date";
# my $outfile = "connect_authors.outfile";
open(OUT, ">$outfile") or die "Cannot create $outfile : $!";


my %aka_hash = &getPgHash();

my %pap_author;			# aid => paperID
my %pap_functional;		# paperID
my %pmid;			# paperID => pmid
my %aid_done;			# aid, two#
my %aid_person_ver_no;		# aid, two#
# my %aid_person_need_response;
my %aid_possible;		# aid, pap_join => two#	originally all under possible, after verified deletions, only those needing response
my %aid_verified;		# aid, pap_join => verification
my %aid_name;			# aid => author name

my %histogram;			# stat of how many authors have n-matches with names/akas

my $temp_counter = 0;


my $result = $dbh->prepare( "SELECT * FROM pap_identifier WHERE pap_identifier ~ 'pmid'; " ); $result->execute;
while (my @row = $result->fetchrow) { $pmid{$row[0]} = $row[1]; }

# TODO this table is going to get deleted, remove after that
# $result = $dbh->prepare( "SELECT * FROM pap_ignore; " ); $result->execute;
# while (my @row = $result->fetchrow) { $pap_functional{$row[0]}++; }

$result = $dbh->prepare( "SELECT * FROM pap_curation_flags WHERE pap_curation_flags = 'non_nematode'; " ); $result->execute;
while (my @row = $result->fetchrow) { $pap_functional{$row[0]}++; }

$result = $dbh->prepare( "SELECT * FROM pap_author; " ); $result->execute;
while (my @row = $result->fetchrow) { $pap_author{$row[1]} = $row[0]; }

$result = $dbh->prepare( "SELECT * FROM pap_author_index;" ); $result->execute;
while (my @row = $result->fetchrow) { $aid_name{$row[0]} = $row[1]; }

$result = $dbh->prepare( "SELECT * FROM pap_author_possible;" ); $result->execute;
while (my @row = $result->fetchrow) { $aid_possible{$row[0]}{$row[2]} = $row[1]; }

$result = $dbh->prepare( "SELECT * FROM pap_author_verified WHERE pap_author_verified ~ 'YES';" ); $result->execute;
while (my @row = $result->fetchrow) { 
  $aid_verified{$row[0]}{$row[2]} = $row[1]; 
  $aid_done{$row[0]}{$aid_possible{$row[0]}{$row[2]}}++;		# store who said yes
  delete $aid_name{$row[0]};			# verified YES no need to find him
  delete $aid_possible{$row[0]}{$row[2]};	# verified YES don't need to track this person
  my @keys = keys %{ $aid_possible{$row[0]} };
  if (scalar(@keys) < 1) { delete $aid_possible{$row[0]}; }	# no join left, aid is unconnected
}

$result = $dbh->prepare( "SELECT * FROM pap_author_verified WHERE pap_author_verified ~ 'NO';" ); $result->execute;
while (my @row = $result->fetchrow) { 
  $aid_verified{$row[0]}{$row[2]} = $row[1]; 
#   unless ($aid_possible{$row[0]}{$row[2]}) { print "DELETED $row[0] AID $row[2] pap_join\n"; }	# this should be fixed after some manual changes to mis-invalidated wpa_author_possible entries and repopulating  2010 04 13no longer shows 2010 06 07

  $aid_person_ver_no{$row[0]}{$aid_possible{$row[0]}{$row[2]}}++;	# store who said no
  delete $aid_possible{$row[0]}{$row[2]};	# verified NO don't need to track this person
  my @keys = keys %{ $aid_possible{$row[0]} };
  if (scalar(@keys) < 1) { delete $aid_possible{$row[0]}; }	# no join left, aid is unconnected
}

foreach my $aid (keys %aid_name) {
  next unless ($pap_author{$aid});
  my $joinkey = $pap_author{$aid};
  next if ($pap_functional{$joinkey});		# skip if functional annotation
  if ($aid_possible{$aid}) { 1; }		# these possibles have not verified, wait until they do
    else {					# no possible, need to find a match 
      my $aname = $aid_name{$aid};
      my $matchname = $aname;
      $matchname = lc($matchname);
      if ($matchname =~ m/,/) { $matchname =~ s/,//g; }
      if ($matchname =~ m/\./) { $matchname =~ s/\.//g; }
      if ($aka_hash{$matchname}) {
          my @temp = keys %{ $aka_hash{$matchname} }; my @twos;	# temp has all twos, twos will have those that haven't already verified no
          foreach my $two (@temp) { unless ($aid_person_ver_no{$aid}{"two$two"}) { push @twos, $two; } }	# unless that aid has verified no, add to list
          my $count = scalar(@twos);
# TODO make below make actual connections, figure out next pap_join and INSERT	# done at some point before 2010 06 07
          if ($count == 1) { &connectAidToTwo($aid, "two$twos[0]", $pap_author{$aid}, $aname); }
          my $twos = join", ", @twos; 
          $histogram{count}{$count}{$aid}{$twos}++; }
#         else { $histogram{count}{0}{$aid}{''}++; } 	# cecilia doesn't care about zero matches  2010 04 14
    }
} # foreach my $aid (keys %aid_name)



foreach my $count (reverse sort {$a<=>$b} keys %{ $histogram{count} }) {
  next if ($count == 1);
  print OUT "\n\n$count number of matches :\n";
  foreach my $aid (sort {$a<=>$b} keys %{ $histogram{count}{$count} }) {
    foreach my $twos (sort keys %{ $histogram{count}{$count}{$aid} }) {
      my $pmid = ''; if ($pmid{$pap_author{$aid}}) { $pmid = $pmid{$pap_author{$aid}}; }
      print OUT "$aid $aid_name{$aid}\tWBPaper$pap_author{$aid} $pmid\t$twos\n";
    } # foreach my $twos (sort keys %{ $histogram{count}{$count}{$aid} })
  } # foreach my $aid (sort keys %{ $histogram{count}{$count} })
} # foreach my $count (reverse sort keys %{ $histogram{count} })


close (OUT) or die "Cannot close $outfile : $!";

sub connectAidToTwo {
  my ($aid, $two, $joinkey, $aname) = @_;
  $temp_counter++;
#   return if ($temp_counter > 4);
  print OUT "author_id $aid WBPaper$joinkey $aname connect to $two\n";
  my $result = $dbh->prepare( "SELECT * FROM pap_author_possible WHERE author_id = '$aid' ORDER BY pap_join DESC;" ); $result->execute;
  my @row = $result->fetchrow();
  my $join = 1; if ($row[2]) { $join = $row[2] + 1; }
  my $command = "INSERT INTO pap_author_possible VALUES ('$aid', '$two', $join, 'two1823', CURRENT_TIMESTAMP);";
  print OUT "$command\n";
# UNCOMMENT THIS TO MAKE CONNECTIONS
  $result = $dbh->do( $command );  
} 



sub getPgHash {				# get akaHash from postgres instead of flatfile
  my $result;
  my %filter;
  my %aka_hash;
  
  my @tables = qw (first middle last);
  foreach my $table (@tables) { 
#     $result = $conn->exec ( "SELECT * FROM two_aka_${table}name WHERE two_aka_${table}name IS NOT NULL AND two_aka_${table}name != 'NULL' AND two_aka_${table}name != '';" );
    $result = $dbh->prepare ( "SELECT * FROM two_aka_${table}name WHERE two_aka_${table}name IS NOT NULL AND two_aka_${table}name != 'NULL' AND two_aka_${table}name != '' AND joinkey IN (SELECT joinkey FROM two_status WHERE two_status = 'Valid');" );
    $result->execute;
    while ( my @row = $result->fetchrow ) {
      if ($row[3]) { 					# if there's a curator
        my $joinkey = $row[0];
        $row[2] =~ s/^\s+//g; $row[2] =~ s/\s+$//g;	# take out spaces in front and back
        $row[2] =~ s/[\,\.]//g;				# take out commas and dots
        $row[2] =~ s/_/ /g;				# replace underscores for spaces
        $row[2] = lc($row[2]);				# for full values (lowercase it)
        $row[0] =~ s/two//g;				# take out the 'two' from the joinkey
        $filter{$row[0]}{$table}{$row[2]}++;
        unless ($table eq 'last') {			# look at initials for first and middle but not last name
          my ($init) = $row[2] =~ m/^(\w)/;		# for initials
          $filter{$row[0]}{$table}{$init}++; }
      }
    }
#     $result = $conn->exec ( "SELECT * FROM two_${table}name WHERE two_${table}name IS NOT NULL AND two_${table}name != 'NULL' AND two_${table}name != '';" );
    $result = $dbh->prepare ( "SELECT * FROM two_${table}name WHERE two_${table}name IS NOT NULL AND two_${table}name != 'NULL' AND two_${table}name != '' AND joinkey IN (SELECT joinkey FROM two_status WHERE two_status = 'Valid');" );
    $result->execute;
    while ( my @row = $result->fetchrow ) {
      if ($row[3]) { 					# if there's a curator
        my $joinkey = $row[0];
        $row[2] =~ s/^\s+//g; $row[2] =~ s/\s+$//g;	# take out spaces in front and back
        $row[2] =~ s/[\,\.]//g;				# take out commas and dots
        $row[2] =~ s/_/ /g;				# replace underscores for spaces
        $row[2] = lc($row[2]);				# for full values (lowercase it)
        $row[0] =~ s/two//g;				# take out the 'two' from the joinkey
        $filter{$row[0]}{$table}{$row[2]}++;
        unless ($table eq 'last') {
          my ($init) = $row[2] =~ m/^(\w)/;		# for initials
          $filter{$row[0]}{$table}{$init}++; }
      }
    }
  } # foreach my $table (@tables)

# Not needed, using restriction in query instead
#   my %invalid_two;
# #   $result = $conn->exec( "SELECT * FROM two_status ORDER BY two_timestamp;" );
#   $result = $dbh->prepare( "SELECT * FROM two_status ORDER BY two_timestamp;" );
#   $result->execute;
#   while (my @row = $result->fetchrow) {
#     if ($row[2] eq 'Invalid') { $invalid_two{$row[0]}++; }
#       else { delete $invalid_two{$row[0]}; }
#   } # while (my @row = $result->fetchrow)
#   foreach my $two (sort keys %invalid_two) { 
#     $two =~ s/two//g;				# take out the 'two' from the joinkey
#     delete $filter{$two}; }

  my $possible;
  foreach my $person (sort keys %filter) { 
    foreach my $last (sort keys %{ $filter{$person}{last}} ) {
      foreach my $first (sort keys %{ $filter{$person}{first}} ) {
#         $possible = "$first"; $aka_hash{$possible}{$person}++;
#         $possible = "$last"; $aka_hash{$possible}{$person}++;
        $possible = "$last $first"; $aka_hash{$possible}{$person}++;
        $possible = "$first $last"; $aka_hash{$possible}{$person}++;
        if ( $filter{$person}{middle} ) {			# Cecilia want no middle name matches  2006 11 20
								# Middle name okay if last first middle or first middle last  2007 02 22
          foreach my $middle (sort keys %{ $filter{$person}{middle}} ) {
# #            $possible = "$middle"; $aka_hash{$possible}{$person}++;
# #            $possible = "$first $middle"; $aka_hash{$possible}{$person}++;
# #            $possible = "$middle $first"; $aka_hash{$possible}{$person}++;
#             $possible = "$last $middle"; $aka_hash{$possible}{$person}++;
            $possible = "$last $first $middle"; $aka_hash{$possible}{$person}++;
            $possible = "$last ${first}$middle"; $aka_hash{$possible}{$person}++;
#             $possible = "$last $middle $first"; $aka_hash{$possible}{$person}++;
# #            $possible = "$middle $last"; $aka_hash{$possible}{$person}++;
            $possible = "$first $middle $last"; $aka_hash{$possible}{$person}++;
            $possible = "${first}$middle $last"; $aka_hash{$possible}{$person}++;
# #            $possible = "$middle $first $last"; $aka_hash{$possible}{$person}++;
          } # foreach my $middle (sort keys %{ $filter{$person}{middle}} )
        }
      } # foreach my $first (sort keys %{ $filter{$person}{first}} )
    } # foreach my $last (sort keys %{ $filter{$person}{last}} )
  } # foreach my $person (sort keys %filter) 

  return %aka_hash;
} # sub getPgHash



