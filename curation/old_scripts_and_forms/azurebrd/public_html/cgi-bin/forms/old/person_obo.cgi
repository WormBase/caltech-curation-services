#!/usr/bin/perl

# display WBPerson's obo
# for Carol  2007 04 11
#
# added email addresses for Karen  2008 02 21
#
# added akas for Arun.  2010 01 22
#
# removed emails because anyone can see this data.  2010 05 21





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


my %curator;
$curator{'two557'}{'allele'}++;
$curator{'two2021'}{'allele'}++;
$curator{'two712'}{'allele'}++;
$curator{'two324'}{'allele'}++;
$curator{'two567'}{'allele'}++;
$curator{'two1843'}{'allele'}++;
$curator{'two22'}{'allele'}++;
$curator{'two363'}{'allele'}++;
$curator{'two101'}{'allele'}++;
$curator{'two480'}{'allele'}++;
$curator{'two625'}{'allele'}++;
$curator{'two1823'}{'allele'}++;
$curator{'two48'}{'allele'}++;
$curator{'two1847'}{'allele'}++;
$curator{'two1971'}{'allele'}++;
$curator{'two2970'}{'allele'}++;
$curator{'two1250'}{'allele'}++;
$curator{'two557'}{'go'}++;
$curator{'two2021'}{'go'}++;
$curator{'two712'}{'go'}++;
$curator{'two324'}{'go'}++;
$curator{'two567'}{'go'}++;
$curator{'two1843'}{'go'}++;
$curator{'two22'}{'go'}++;
$curator{'two363'}{'go'}++;
$curator{'two101'}{'go'}++;
$curator{'two480'}{'go'}++;
$curator{'two625'}{'go'}++;
$curator{'two1823'}{'go'}++;
$curator{'two48'}{'go'}++;
$curator{'two5196'}{'go'}++;
$curator{'two557'}{'interaction'}++;
$curator{'two2021'}{'interaction'}++;
$curator{'two712'}{'interaction'}++;
$curator{'two324'}{'interaction'}++;
$curator{'two567'}{'interaction'}++;
$curator{'two1843'}{'interaction'}++;
$curator{'two22'}{'interaction'}++;
$curator{'two363'}{'interaction'}++;
$curator{'two101'}{'interaction'}++;
$curator{'two480'}{'interaction'}++;
$curator{'two625'}{'interaction'}++;
$curator{'two1823'}{'interaction'}++;
$curator{'two48'}{'interaction'}++;


my %aka;
my $result = $dbh->prepare( "SELECT * FROM two_aka_lastname WHERE two_aka_lastname != 'NULL' ORDER BY two_timestamp;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[2] =~ s///g;
    my $id = $row[0]; my $join = $row[1]; my $name = $row[2];
    $aka{$id}{exists}{$join}++;
    $aka{$id}{last}{$join} = $name; } }
$result = $dbh->prepare( "SELECT * FROM two_aka_firstname WHERE two_aka_firstname != 'NULL' ORDER BY two_timestamp;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[2] =~ s///g;
    my $id = $row[0]; my $join = $row[1]; my $name = $row[2];
    $aka{$id}{first}{$join} = $name; } }
$result = $dbh->prepare( "SELECT * FROM two_aka_middlename WHERE two_aka_middlename != 'NULL' ORDER BY two_timestamp;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[2] =~ s///g;
    my $id = $row[0]; my $join = $row[1]; my $name = $row[2];
    $aka{$id}{middle}{$join} = $name; } }

$result = $dbh->prepare( "SELECT * FROM two_standardname ORDER BY two_timestamp;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
my %persons;
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[2] =~ s///g;
    my $id = $row[0]; my $name = $row[2];
    $persons{$id}{name} = $name; } }


$result = $dbh->prepare( "SELECT * FROM two_email ORDER BY two_timestamp;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[2] =~ s///g;
    my $id = $row[0]; my $email = $row[2];
    $persons{$id}{email}{$email}++; } }

$result = $dbh->prepare( "SELECT two_timestamp FROM two_standardname ORDER BY two_timestamp DESC;" );
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


print "default-namespace: wbperson\n";
$obo_date = &getOboDate();
print "subsetdef: curator_slim_allele \"Curator slim Allele\"\n";
print "subsetdef: curator_slim_go \"Curator slim GO\"\n";
print "subsetdef: curator_slim_interaction \"Curator slim Interaction\"\n";
print "date: $obo_date\n\n";


my ($var, $short) = &getHtmlVar($query, 'short');
if ($short) { if ($short =~ m/(\d+)/) { $short = $1; } else { $short = 10; } }
my $count = 0;


foreach my $id (sort keys %persons) {
  my $name = $persons{$id}{name};
  my $wbperson = $id;
  $wbperson =~ s/two/WBPerson/g;
  unless ($name) { $name = $wbperson; }
  print "[Term]\nid: $wbperson\nname: $name\n";
#   foreach my $email (sort keys %{ $persons{$id}{email} }) { print "email: $email\n"; }	# removed emails since it's a public form.  2010 05 21
  if ($curator{$id}) { foreach my $type (sort keys %{ $curator{$id} }) { print "subset: curator_slim_$type\n"; } }
  if ($short) { $count++; }
  last if ( defined ($short) && ($short <= $count) );
  my @joins = sort keys %{ $aka{$id}{exists} };
  if ( scalar(@joins) > 0) {
    foreach my $join (@joins) {
      my @name;
      if ($aka{$id}{first}{$join}) { push @name, $aka{$id}{first}{$join}; }
      if ($aka{$id}{middle}{$join}) { push @name, $aka{$id}{middle}{$join}; }
      if ($aka{$id}{last}{$join}) { push @name, $aka{$id}{last}{$join}; }
      my $aka = join" ", @name;
      print "aka: $aka\n"; 
    }
  }
  print "\n";
} # foreach my $id (sort keys %persons)

__END__



__END__

my $directory = '/home/postgres/work/citace_upload/allele_phenotype/temp';
chdir($directory) or die "Cannot go to $directory ($!)";
`cvs -d /var/lib/cvsroot checkout PhenOnt`;
my $file = $directory . '/PhenOnt/PhenOnt.obo';
$/ = "";
open (IN, "<$file") or die "Cannot open $file : $!";
while (my $para = <IN>) { print "$para\n"; }
close (IN) or die "Cannot close $file : $!";
$directory .= '/PhenOnt';
`rm -rf $directory`;

