#!/usr/bin/env perl

# assign IDs to interaction objects that were created without them.  2010 12 07
# 
# 1. Curator exists and it's anyone besides Arun
# 2. False Positive is not ON
# 3. Interaction ID field is BLANK
# 4. Interaction Type field OR Nondirectional field has a value	# Chris says these are okay for now and will be filtered out at moment of dump.  2012 08 15
# 5. There's an (Effector Gene OR Effector Variation OR Effector Transgene) AND (Effected Gene OR Effected Variation OR Effected Transgene)	# Chris says these are okay for now and will be filtered out at moment of dump.  2012 08 15
#
# some tables don't exist anymore, removed them from table list since they were breaking script.  2014 05 15
#
# on tazendra run every day at 4am  2011 01 06
#  0 4 * * * /home/acedb/xiaodong/assigning_interaction_ids/assign_interaction_ids.pl
#
# Dockerized.  used by Jae, possibly Chris, maybe to give Gary stuff.  2023 03 20
 
# cronjob on dockerized
# 0 4 * * * /usr/lib/scripts/pgpopulation/interaction/assigning_interaction_ids/assign_interaction_ids.pl




use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );
use LWP::Simple;
use Dotenv -load => '/usr/lib/.env';

my $dbh = DBI->connect ( "dbi:Pg:dbname=$ENV{PSQL_DATABASE};host=$ENV{PSQL_HOST};port=$ENV{PSQL_PORT}", "$ENV{PSQL_USERNAME}", "$ENV{PSQL_PASSWORD}") or die "Cannot connect to database!\n";
# my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %hash;
my @tables = qw( int_name int_type int_geneone int_genetwo int_variationone int_variationtwo int_falsepositive );	# int_nondirectional int_transgeneone int_transgenetwo don't exist and were making script break  2014 05 15
# my @tables = qw( int_name int_nondirectional int_type int_geneone int_genetwo int_variationone int_variationtwo int_transgeneone int_transgenetwo int_falsepositive );
foreach my $table (@tables) {
  $result = $dbh->prepare( "SELECT * FROM $table WHERE $table IS NOT NULL AND $table != ''" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { $hash{$table}{$row[0]} = $row[1]; }
} # foreach my $table (@tables)

my %needIDs;

  # curator exists and it's no Arun
$result = $dbh->prepare( "SELECT * FROM int_curator WHERE int_curator IS NOT NULL AND int_curator != '' AND int_curator != 'WBPerson4793';" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { 
  my $pgid = $row[0];
  next if ($hash{int_name}{$pgid});			# already has ID
  next if ($hash{int_falsepositive}{$pgid});		# is false positive
#   next unless ( $hash{int_type}{$pgid} || $hash{int_nondirectional}{$pgid} );			# missing type and nondirectional
#   next unless ( ( $hash{int_geneone}{$pgid} || $hash{int_transgeneone}{$pgid} || $hash{int_variationone}{$pgid} ) && ( $hash{int_genetwo}{$pgid} || $hash{int_transgenetwo}{$pgid} || $hash{int_variationtwo}{$pgid} ) ); 
#   if ( $hash{int_geneone}{$pgid} && $hash{int_genetwo}{$pgid} ) { 1; }
#   elsif ( $hash{int_transgeneone}{$pgid} && $hash{int_transgenetwo}{$pgid} ) { 1; }
#   elsif ( $hash{int_variationone}{$pgid} && $hash{int_variationtwo}{$pgid} ) { 1; }
#   else { next; }					# missing some kind of effector / effected pair
  $needIDs{$pgid}++;
  $hash{int_curator}{$pgid} = $row[1];
}

my @pgcommands;
my (@needIDs) = sort keys %needIDs;
foreach my $pgid (@needIDs) {
  my $curator = $hash{int_curator}{$pgid};
  my $twonum = $curator; $twonum =~ s/WBPerson/two/;
  my ($ticketpage) = get( "$ENV{THIS_HOST}/priv/cgi-bin/interaction_ticket.cgi?action=Ticket+%21&tickets=1&curator=$twonum");
  # my ($ticketpage) = get( "http://tazendra.caltech.edu/~postgres/cgi-bin/interaction_ticket.cgi?action=Ticket+%21&tickets=1&curator=$twonum");
  my ($intId) = $ticketpage =~ m/(WBInteraction\d+)/;
#   my $intId = 'test';
  push @pgcommands, "DELETE FROM int_name WHERE joinkey = '$pgid';";
  push @pgcommands, "INSERT INTO int_name VALUES ( '$pgid', '$intId' );";
  push @pgcommands, "INSERT INTO int_name_hst VALUES ( '$pgid', '$intId' );";
#   print "$pgid\n";
}

foreach my $pgcommand (@pgcommands) {
#   print "$pgcommand\n";
  $dbh->do( $pgcommand );
} # foreach my $pgcommand (@pgcommands)

__END__

my $result = $dbh->prepare( 'SELECT * FROM two_comment WHERE two_comment ~ ?' );
$result->execute('elegans') or die "Cannot prepare statement: $DBI::errstr\n"; 

$result->execute("doesn't") or die "Cannot prepare statement: $DBI::errstr\n"; 
my $var = "doesn't";
$result->execute($var) or die "Cannot prepare statement: $DBI::errstr\n"; 

my $data = 'data';
unless (is_utf8($data)) { from_to($data, "iso-8859-1", "utf8"); }

my $result = $dbh->do( "DELETE FROM friend WHERE firstname = 'bl\"ah'" );
(also do for INSERT and UPDATE if don't have a variable to interpolate with ? )

can cache prepared SELECTs with $dbh->prepare_cached( &c. );

if ($result->rows == 0) { print "No names matched.\n\n"; }	# test if no return

$result->finish;	# allow reinitializing of statement handle (done with query)
$dbh->disconnect;	# disconnect from DB

http://209.85.173.132/search?q=cache:5CFTbTlhBGMJ:www.perl.com/pub/1999/10/DBI.html+dbi+prepare+execute&cd=4&hl=en&ct=clnk&gl=us

interval stuff : 
SELECT * FROM afp_passwd WHERE joinkey NOT IN (SELECT joinkey FROM afp_lasttouched) AND joinkey NOT IN (SELECT joinkey FROM cfp_curator) AND afp_timestamp < CURRENT_TIMESTAMP - interval '21 days' AND afp_timestamp > CURRENT_TIMESTAMP - interval '28 days';

casting stuff to substring on other types :
SELECT * FROM afp_passwd WHERE CAST (afp_timestamp AS TEXT) ~ '2009-05-14';

to concatenate string to query result :
  SELECT 'WBPaper' || joinkey FROM pap_identifier WHERE pap_identifier ~ 'pmid';
to get :
  SELECT DISTINCT(gop_paper_evidence) FROM gop_paper_evidence WHERE gop_paper_evidence NOT IN (SELECT 'WBPaper' || joinkey FROM pap_identifier WHERE pap_identifier ~ 'pmid') AND gop_paper_evidence != '';

