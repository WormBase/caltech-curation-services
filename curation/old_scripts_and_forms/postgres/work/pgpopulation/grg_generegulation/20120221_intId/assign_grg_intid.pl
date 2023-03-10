#!/usr/bin/perl -w

# assign grg_intid to grg_name that have no grg_intid  2012 02 21
# real run on tazendra.  2012 02 24

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );
use LWP::Simple;

my %name;
my %intid;
my %curator;
my %nameToIntid;

my $counter = 0;
my @pgcommands;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

$result = $dbh->prepare( "SELECT * FROM grg_name" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { if ($row[0]) { $name{$row[0]} = $row[1]; } }

$result = $dbh->prepare( "SELECT * FROM grg_intid" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { if ($row[0]) { $intid{$row[0]} = $row[1]; } }

$result = $dbh->prepare( "SELECT * FROM grg_curator" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { if ($row[0]) { $curator{$row[0]} = $row[1]; } }

foreach my $pgid (sort keys %name) { if ($intid{$pgid}) { $nameToIntid{$name{$pgid}} = $intid{$pgid}; } }	# assign nameToIntid mappings
  
foreach my $pgid (sort {$a<=>$b} keys %name) {
  next if ($intid{$pgid});			# intid already exists for this name
  my $intid = ''; my $name = $name{$pgid};
  if ($nameToIntid{$name}) { $intid = $nameToIntid{$name}; }
    else { 
      ($intid) = &getNewIntId($pgid); 		# get new intid from ticket cgi
      $nameToIntid{$name} = $intid;		# store name to intid mapping for future pgids that may have the same grg name
    }
  push @pgcommands, "INSERT INTO grg_intid VALUES ('$pgid', '$intid')";
  push @pgcommands, "INSERT INTO grg_intid_hst VALUES ('$pgid', '$intid')";
} # foreach my $pgid (sort keys %name)

foreach my $command (@pgcommands) {
  print "$command\n";
# UNCOMMENT TO POPULATE
  $dbh->do($command);
} # foreach my $command (@pgcommands)


sub getNewIntId {
  my $pgid = shift;
  my $twonum = $curator{$pgid};
  $twonum =~ s/WBPerson/two/;
# UNCOMMENT TO GET REAL IDs
  my ($ticketpage) = get( "http://tazendra.caltech.edu/~postgres/cgi-bin/interaction_ticket.cgi?action=Ticket+%21&tickets=1&curator=$twonum");
  my ($intId) = $ticketpage =~ m/(WBInteraction\d+)/;
# COMMENT OUT TO GET REAL IDs
#   $counter++;
#   my $intId = "WBInteraction$counter";
  return $intId;
}

__END__


