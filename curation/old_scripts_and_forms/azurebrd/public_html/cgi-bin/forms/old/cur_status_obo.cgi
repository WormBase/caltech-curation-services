#!/usr/bin/perl

# display WBPerson's obo
# for Carol  2007 04 11
#
# added email addresses for Karen  2008 02 21





use strict;
use CGI;
use Jex;		# printHeader printFooter getHtmlVar getDate getSimpleDate
use DBI;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n";



my $query = new CGI;	# new CGI form

print "Content-type: text/plain\n\n";

# my $obo_date = &getOboDate();
my $obo_date = '';
my $datenumber;


my %status;
$status{happy} = 0;
$status{not_happy} = 0;
$status{down_right_disgusted} = 0;
my $result = $dbh->prepare( "SELECT * FROM app_curation_status ;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) { if ($row[0]) { $status{$row[1]}++; } }


$result = $dbh->prepare( "SELECT app_timestamp FROM app_curation_status ORDER BY app_timestamp DESC;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
my @row = $result->fetchrow();
&getLateDate($row[0]);

sub getLateDate {
  my $date = shift;
  my ($short) = $date =~ m/^(\d\d\d\d\-\d\d\-\d\d \d\d:\d\d:\d\d)/;
  my $number = $short;
  $number =~ s/\D//g;
  if ($number > $datenumber)  { $datenumber = $number; $obo_date = $short; }
} # sub getLateDate

$obo_date = &convertDateObo($obo_date);

sub convertDateObo {
  my $bad_date = shift;
  my ($year, $month, $day, $hour, $minute) = $bad_date =~ m/^(\d\d\d\d)\-(\d\d)\-(\d\d) (\d\d):(\d\d)/;
  my $good_date = "${day}:${month}:${year} ${hour}:${minute}";
  return $good_date;
} # sub convertDateObo

print "default-namespace: curation_status\n";
# $obo_date = &getOboDate();	# use latest pg date, not current date
print "date: $obo_date\n\n";

print << "EndOfText"
[Term]
id: happy
name: happy
count: $status{happy}
Definition: record is complete and the world loves us, XXOO

[Term]
id: not_happy
name: not_happy
count: $status{not_happy}
Definition: the world loves us but we know better, xoo

[Term]
id: down_right_disgusted
name: down_right_disgusted
count: $status{down_right_disgusted}
Definition: the world will hate us if we don't fix this ASAP! (angry face)

EndOfText

__END__

default-namespace: WBcuration_status
date: 21:02:2008 13:43

[Term]
id: happy
name: happy
definition: record is complete and the world loves us, XXOO

[Term]
id: not_happy
name: not_happy
definition: the world loves us but we know better, xoo

[Term]
id: down_right_disgusted
name: down_right_disgusted
definition: the world will hate us if we don't fix this ASAP! (angry face)




__END__

print "default-namespace: wbperson\n";
$obo_date = &getOboDate();
print "date: $obo_date\n\n";

$result = $dbh->prepare( "SELECT * FROM two_email ORDER BY two_timestamp;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[2] =~ s///g;
    my $id = $row[0]; my $email = $row[2];
    $persons{$id}{email}{$email}++; } }

foreach my $id (sort keys %persons) {
  my $name = $persons{$id}{name};
  my $wbperson = $id;
  $wbperson =~ s/two/WBPerson/g;
  unless ($name) { $name = $wbperson; }
  print "[Term]\nid: $wbperson\nname: $name\n";
  foreach my $email (sort keys %{ $persons{$id}{email} }) { print "email: $email\n"; }
  print "\n";
} # foreach my $id (sort keys %persons)

