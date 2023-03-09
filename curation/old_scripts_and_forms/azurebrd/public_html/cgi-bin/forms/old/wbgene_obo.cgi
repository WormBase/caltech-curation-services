#!/usr/bin/perl

# display WBGene's obo
# for Andrei phenote interaction  2008 03 26
#
# display sequence names as name if there's no locus, otherwise use locus and
# put sequence name as a synonym.  2008 06 26
#
# Add locus synonyms for Jolene.  2008 07 17





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

my %wbgHash;
my %syn;



my $result = $dbh->prepare( "SELECT * FROM gin_synonyms WHERE gin_syntype = 'locus' ORDER BY gin_timestamp;" ); 
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) {	# loop through all rows returned
  unless ($row[0]) { $row[0] = ''; }
  unless ($row[1]) { $row[1] = ''; }
#   $wbgHash{$row[1]}{$row[0]}++;
  $wbgHash{$row[0]} = $row[1];
  $syn{$row[0]}{$row[1]}++;		# add synonyms to obo file for Jolene 2008 07 17
} # while (my @row = $result->fetchrow) 
$result = $dbh->prepare( "SELECT * FROM gin_locus ORDER BY gin_timestamp;" ); 
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) {	# loop through all rows returned
  unless ($row[0]) { $row[0] = ''; }
  unless ($row[1]) { $row[1] = ''; }
#   $wbgHash{$row[1]}{$row[0]}++;
  $wbgHash{$row[0]} = $row[1];
  $syn{$row[0]}{$row[1]}++;		# add synonyms to obo file for Jolene 2008 07 17
} # while (my @row = $result->fetchrow) 

$result = $dbh->prepare( "SELECT * FROM gin_seqname ORDER BY gin_timestamp;" ); 
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) {	# loop through all rows returned
  if ($wbgHash{$row[0]}) { $syn{$row[0]}{$row[1]}++; }		# if already has a name make it a synonym
    else { $wbgHash{$row[0]} = $row[1]; }			# if no name, make the sequence name the name
} # while (my @row = $result->fetchrow) 

$result = $dbh->prepare( "SELECT gin_timestamp FROM gin_locus ORDER BY gin_timestamp DESC;" );
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


print "default-namespace: wbgene\n";
$obo_date = &getOboDate();
print "date: $obo_date\n\n";

my ($var, $short) = &getHtmlVar($query, 'short');
if ($short) { if ($short =~ m/(\d+)/) { $short = $1; } else { $short = 10; } }
my $count = 0;


foreach my $wbgene (sort keys %wbgHash) { 
  my $locus = $wbgHash{$wbgene};
  if ($short) { $count++; }
  last if ( defined ($short) && ($short < $count) );
  print "[Term]\nid: WBGene$wbgene\nname: $locus\nsynonym: \"WBGene$wbgene\" []\n"; 
  if ($syn{$wbgene}) { foreach my $syn (sort keys %{ $syn{$wbgene} }) { print "synonym: \"$syn\" []\n"; } }
  print "\n"; }

# foreach my $locus (sort keys %wbgHash) { 
#   foreach my $wbgene (sort keys %{ $wbgHash{$locus} }) { 
#     if ($short) { $count++; }
#     last if ( defined ($short) && ($short < $count) );
#     print "[Term]\nid: WBGene$wbgene\nname: $locus\nsynonym: \"WBGene$wbgene\" []\n\n"; } }


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

