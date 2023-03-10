#!/usr/bin/perl -w

# assign intIDs to YH objects.  2012 02 24
# live run on tazendra.  2012 02 24
# this script is bad because it shifts the first line from @lines, but then replaces $lines[0] which refers to the second line.  2012 02 25

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );
use LWP::Simple;

# remove this __END__ line for script to run.  also uncomment section to get group ids.
__END__

my %name;
my %intid;
my %curator;
my %nameToIntid;

my $counter = 0;
my @pgcommands;
my @intIDs;
my $yh_amount = 0;


$/ = "";
my $infile = 'Object_source_files/Citace_Minus_YH_objects.ace';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $obj = <IN>) {
  next unless ($obj =~ m/YH : /);
  my (@lines) = split/\n/, $obj;
  my $header = shift @lines;
  my ($yh) = $header =~ m/YH : \"(.*?)\"/;
  $yh_amount++;
} # while (my $obj = <IN>)
close (IN) or die "Cannot open $infile : $!";

# UNCOMMENT TO GET IDs
# &getGroupIntId($yh_amount);

# print "\nfinished getting all tickets\n\n";

my $outfile = 'Object_source_files/Interaction_YH_objects.ace';
open (OUT, ">$outfile") or die "Cannot open $outfile : $!";
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $obj = <IN>) {
  next unless ($obj =~ m/YH : /);
  my (@lines) = split/\n/, $obj;
  my $header = shift @lines;
  my ($yh) = $header =~ m/YH : \"(.*?)\"/;
  my ($intid) = &getNewIntId(); 		# get new intid from array that came from interaction ticket.cgi
  print "$yh\t$intid\n";
  $lines[0] = qq(Interaction : "$intid");
  $obj = join"\n", @lines;
  print OUT "$obj\n\n";
} # while (my $obj = <IN>)
close (IN) or die "Cannot open $infile : $!";
close (OUT) or die "Cannot open $outfile : $!";

sub getGroupIntId {
  my ($yh_amount) = @_;
  my $twonum = 'two2987';
# UNCOMMENT TO GET REAL IDs
  my ($ticketpage) = get( "http://tazendra.caltech.edu/~postgres/cgi-bin/interaction_ticket.cgi?action=Ticket+%21&tickets=${yh_amount}&curator=$twonum");
  (@intIDs) = $ticketpage =~ m/(WBInteraction\d+)/g;
# COMMENT OUT TO GET REAL IDs
#   $counter++;
#   my $intId = "WBInteraction$counter";
#   return $intId;
}

sub getNewIntId {
  my $intId = shift @intIDs;
#   my $twonum = 'two2987';
# # UNCOMMENT TO GET REAL IDs
#   my ($ticketpage) = get( "http://mangolassi.caltech.edu/~postgres/cgi-bin/interaction_ticket.cgi?action=Ticket+%21&tickets=1&curator=$twonum");
#   my ($intId) = $ticketpage =~ m/(WBInteraction\d+)/;
# # COMMENT OUT TO GET REAL IDs
# #   $counter++;
# #   my $intId = "WBInteraction$counter";
  return $intId;
}

sub getNewIntIdOneByOne {
  my $twonum = 'two2987';
# UNCOMMENT TO GET REAL IDs
  my ($ticketpage) = get( "http://tazendra.caltech.edu/~postgres/cgi-bin/interaction_ticket.cgi?action=Ticket+%21&tickets=1&curator=$twonum");
  my ($intId) = $ticketpage =~ m/(WBInteraction\d+)/;
# COMMENT OUT TO GET REAL IDs
#   $counter++;
#   my $intId = "WBInteraction$counter";
  return $intId;
}

__END__


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
#   $dbh->do($command);
} # foreach my $command (@pgcommands)


