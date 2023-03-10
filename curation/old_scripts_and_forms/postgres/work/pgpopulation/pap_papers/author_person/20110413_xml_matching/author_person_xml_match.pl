#!/usr/bin/perl -w

# copied  /home/postgres/work/pgpopulation/pap_papers/author_person/connect_single_match_authors_and_get_histogram.pl*
# and modified to get authors without verified people, match those names with the corresponding pubmed XML, and try to get new person matches based on the '<forename><lastname>'.  2011 04 13
#
# modified to get more standard output.  2011 04 20


use strict;
use diagnostics;
use DBI;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my @paps = qw( 00036424 00036426 00036427 00036428 00036429 00036763 00038291 );

# get pmid
# get xml from /home/postgres/work/pgpopulation/wpa_papers/pmid_downloads/done
# get papers authors where verified is not 'YES'
# for those :
#   match paper's authors to xml's '<LastName> <Initials>'
#   get xml's '<ForeName> <LastName>'  match to person data

my %pg_pap;
my %pg_aid;

my %aka_hash = &getPgHash();

print "WBPaperId\tAID\tAName\tXML Name\tXML Forename\tXML Lastname\tXML Affiliation\t# matches\ttwo#\n";

foreach my $pap (@paps) {
  my $pmid; my @auts;
  $result = $dbh->prepare( "SELECT * FROM pap_identifier WHERE joinkey = '$pap' AND pap_identifier ~ 'pmid'" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    $row[1] =~ s/pmid//g;
    $pmid = $row[1];
    $pg_pap{$row[0]}{pmid} = $row[1]; }
  $result = $dbh->prepare( " SELECT pap_author.joinkey, pap_author.pap_author, pap_author_index.pap_author_index FROM pap_author, pap_author_index WHERE pap_author.pap_author = pap_author_index.author_id AND pap_author.joinkey = '$pap' AND pap_author.pap_author NOT IN (SELECT author_id FROM pap_author_verified WHERE pap_author_verified ~ 'YES') " );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    $pg_pap{$row[0]}{aut}{$row[2]} = $row[1]; }

  $/ = undef;
  my $xmlfile = '/home/postgres/work/pgpopulation/wpa_papers/pmid_downloads/done/' . $pmid;
  next unless -e $xmlfile;
  open (IN, "<$xmlfile") or die "Cannot open $xmlfile : $!";
  my $xmldata = <IN>;
  close (IN) or die "Cannot close $xmlfile : $!";

  my ($affiliation) = $xmldata =~ /\<Affiliation\>(.+?)\<\/Affiliation\>/ig;
  my @xml_authors = $xmldata =~ /\<Author.*?\>(.+?)\<\/Author\>/sig;
  my @authors;
  foreach (@xml_authors) {
#       my ($lastname, $initials) = $_ =~ /\<LastName\>(.+?)\<\/LastName\>.+\<Initials\>(.+?)\<\/Initials\>/i;
    my ($lastname) = $_ =~ /\<LastName\>(.+?)\<\/LastName\>/i;
    my ($initials) = $_ =~ /\<Initials\>(.+?)\<\/Initials\>/i;
    my ($forename) = $_ =~ /\<ForeName\>(.+?)\<\/ForeName\>/i;
    my $author = $lastname . " " . $initials;
    my $aid;
    if ($pg_pap{$pap}{aut}{$author}) { 
      $aid = $pg_pap{$pap}{aut}{$author};
      my $fullname = "$forename $lastname";

#       my $line = "paper $pap\taid $aid\tauthorname $author\txml fullname $fullname\tforename $forename\tlastname $lastname\taffiliation $affiliation";
      my $line = "$pap\t$aid\t$author\t$fullname\t$forename\t$lastname\t$affiliation";
      my $twos = ''; 
      my $orig_author = $fullname;
      $fullname = lc($fullname); 
      my $count = 0;
      my $next = 0;				# skip flag if there are too many two matches for that fullname
      if ($aka_hash{$fullname}) {
          my @twos = keys %{ $aka_hash{$fullname} };
          $count = scalar(@twos);
          if ($count > 20) { print "Author $orig_author @twos\n"; $next++; }
          $twos = join", ", @twos; }
      if ( ($count == 0) &&  ($forename =~ m/ \w$/) ) {
        $forename =~ s/ \w$//; $fullname = "$forename $lastname"; $fullname = lc($fullname); 
        if ($aka_hash{$fullname}) {
          my @twos = keys %{ $aka_hash{$fullname} };
          $count = scalar(@twos);
          if ($count > 20) { print "Author $orig_author @twos\n"; $next++; }
          $twos = join", ", @twos; } }
      next if $next;
#       foreach my $aid (@{ $auth_name{$orig_author} }) { 
#         if ($paper_by_aid{$aid}) { $aids .= "${aid}($paper_by_aid{$aid}) "; } else { $aids .= "$aid "; } }
#       $line .= "\thow many matches $count\tTWO $twos"; 
      $line .= "\t$count matches\t$twos"; 
      print "$line\n";
#       push @{ $auts{$count} }, $line;
  } }
  $/ = "\n";
} # foreach my $pap (@paps)


sub getPgHash {				# get akaHash from postgres instead of flatfile
  my $result;
  my %filter;
  my %aka_hash;
  
  my @tables = qw (first middle last);
  foreach my $table (@tables) { 
#     $result = $conn->exec ( "SELECT * FROM two_aka_${table}name WHERE two_aka_${table}name IS NOT NULL AND two_aka_${table}name != 'NULL' AND two_aka_${table}name != '';" );
    $result = $dbh->prepare ( "SELECT * FROM two_aka_${table}name WHERE two_aka_${table}name IS NOT NULL AND two_aka_${table}name != 'NULL' AND two_aka_${table}name != '';" );
    $result->execute;
    while ( my @row = $result->fetchrow ) {
      if ($row[3]) { 					# if there's a time
        my $joinkey = $row[0];
        $row[2] =~ s/^\s+//g; $row[2] =~ s/\s+$//g;	# take out spaces in front and back
        $row[2] =~ s/[\,\.]//g;				# take out commas and dots
        $row[2] =~ s/_/ /g;				# replace underscores for spaces
        $row[2] = lc($row[2]);				# for full values (lowercase it)
        $row[0] =~ s/two//g;				# take out the 'two' from the joinkey
        $filter{$row[0]}{$table}{$row[2]}++;
        unless ($table eq 'last') {			# look at initials for first and middle but not last name
          my ($init) = $row[2] =~ m/^(\w)/;		# for initials
          if ($init) { $filter{$row[0]}{$table}{$init}++; } }
      }
    }
#     $result = $conn->exec ( "SELECT * FROM two_${table}name WHERE two_${table}name IS NOT NULL AND two_${table}name != 'NULL' AND two_${table}name != '';" );
    $result = $dbh->prepare ( "SELECT * FROM two_${table}name WHERE two_${table}name IS NOT NULL AND two_${table}name != 'NULL' AND two_${table}name != '';" );
    $result->execute;
    while ( my @row = $result->fetchrow ) {
      if ($row[3]) { 					# if there's a time
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

  my %invalid_two;
#   $result = $conn->exec( "SELECT * FROM two_status ORDER BY two_timestamp;" );
  $result = $dbh->prepare( "SELECT * FROM two_status ORDER BY two_timestamp;" );
  $result->execute;
  while (my @row = $result->fetchrow) {
    if ($row[2] eq 'Invalid') { $invalid_two{$row[0]}++; }
      else { delete $invalid_two{$row[0]}; }
  } # while (my @row = $result->fetchrow)
  foreach my $two (sort keys %invalid_two) { 
    $two =~ s/two//g;				# take out the 'two' from the joinkey
    delete $filter{$two}; }

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

__END__


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

my %histogram;
my $total_authors;
my %auth_name;			# key name, value aid


my %author_possible;            # keys author_id, wpa_join, value possible two#
my %author_verified;            # keys author_id, wpa_join, value YES / NO / NULL (no answer) 

my $result = $conn->exec( "SELECT * FROM wpa_author_possible ORDER BY wpa_timestamp;" );
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
  next if ($author_possible{$row[1]});
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
    $result = $conn->exec( "SELECT wpa_join FROM wpa_author_possible WHERE author_id IN (SELECT wpa_author FROM wpa_author WHERE joinkey = '$wbpaper') ORDER BY wpa_join DESC; " );
    print OUT "SELECT wpa_join FROM wpa_author_possible WHERE author_id IN (SELECT wpa_author FROM wpa_author WHERE joinkey = '$wbpaper') ORDER BY wpa_join DESC; \n" ;
    my @row = $result->fetchrow; my $wpa_join = $row[0]; $wpa_join++;
    my $command = "INSERT INTO wpa_author_possible VALUES ('$aid', 'two$two', '$wpa_join', 'valid', 'two1823', CURRENT_TIMESTAMP)";
    print OUT "AID $aid PAPER $wbpaper : $command\n";
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
        if ( $filter{$person}{middle} ) {
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


__END__


#!/usr/bin/perl -w

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


use strict;
use diagnostics;
use DBI;
use Jex;

# my $conn = Pg::connectdb("dbname=testdb");
# die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 


my %authors;

my $date = &getSimpleSecDate();

# my $outfile = "connect_authors.outfile.$date";
my $outfile = "connect_authors.outfile";
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
$result = $dbh->prepare( "SELECT * FROM pap_ignore; " ); $result->execute;
while (my @row = $result->fetchrow) { $pap_functional{$row[0]}++; }

$result = $dbh->prepare( "SELECT * FROM pap_curation_flags WHERE pap_curation_flags = 'functional_annotation'; " ); $result->execute;
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
    $result = $dbh->prepare ( "SELECT * FROM two_aka_${table}name WHERE two_aka_${table}name IS NOT NULL AND two_aka_${table}name != 'NULL' AND two_aka_${table}name != '';" );
    $result->execute;
    while ( my @row = $result->fetchrow ) {
      if ($row[3]) { 					# if there's a time
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
    $result = $dbh->prepare ( "SELECT * FROM two_${table}name WHERE two_${table}name IS NOT NULL AND two_${table}name != 'NULL' AND two_${table}name != '';" );
    $result->execute;
    while ( my @row = $result->fetchrow ) {
      if ($row[3]) { 					# if there's a time
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

  my %invalid_two;
#   $result = $conn->exec( "SELECT * FROM two_status ORDER BY two_timestamp;" );
  $result = $dbh->prepare( "SELECT * FROM two_status ORDER BY two_timestamp;" );
  $result->execute;
  while (my @row = $result->fetchrow) {
    if ($row[2] eq 'Invalid') { $invalid_two{$row[0]}++; }
      else { delete $invalid_two{$row[0]}; }
  } # while (my @row = $result->fetchrow)
  foreach my $two (sort keys %invalid_two) { 
    $two =~ s/two//g;				# take out the 'two' from the joinkey
    delete $filter{$two}; }

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
#             $possible = "$last $middle $first"; $aka_hash{$possible}{$person}++;
# #            $possible = "$middle $last"; $aka_hash{$possible}{$person}++;
            $possible = "$first $middle $last"; $aka_hash{$possible}{$person}++;
# #            $possible = "$middle $first $last"; $aka_hash{$possible}{$person}++;
          } # foreach my $middle (sort keys %{ $filter{$person}{middle}} )
        }
      } # foreach my $first (sort keys %{ $filter{$person}{first}} )
    } # foreach my $last (sort keys %{ $filter{$person}{last}} )
  } # foreach my $person (sort keys %filter) 

  return %aka_hash;
} # sub getPgHash



