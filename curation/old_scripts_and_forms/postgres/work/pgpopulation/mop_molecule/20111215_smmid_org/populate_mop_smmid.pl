#!/usr/bin/perl -w

# parse smmid.org stuff for Karen, later will parse into postgres.  2011 12 15
# 
# ran on tazendra.  2011 12 20

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %pmidToPap;
$result = $dbh->prepare( "SELECT * FROM pap_identifier WHERE pap_identifier ~ '^pmid'" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $pmidToPap{$row[1]} = "WBPaper$row[0]"; }

my %smmid;
$result = $dbh->prepare( "SELECT * FROM mop_smmid" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $smmid{$row[1]}++; }

my $curator = 'WBPerson712';
my $remark = 'See SMMID DB for more details: http://smmid.org/browse';
my $pgid = 0;

$result = $dbh->prepare( "SELECT * FROM mop_curator ORDER BY joinkey::INTEGER DESC" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
my @row = $result->fetchrow(); if ($row[0] > $pgid) { $pgid = $row[0]; }
$result = $dbh->prepare( "SELECT * FROM mop_molecule ORDER BY joinkey::INTEGER DESC" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
@row = $result->fetchrow(); if ($row[0] > $pgid) { $pgid = $row[0]; }

# print "MOLID\tSMMID\tCHEM-SYN\tCAS\tREMARK\tREF\n";
my $count = 0;
my @files = </home/postgres/work/pgpopulation/mop_molecule/20111215_smmid_org/files/index.*>;
$/ = undef;
foreach my $file (@files) {
#   $count++; last if ($count > 2);
  my ($smmid, $chem, $syn, $cas, $remark, $ref); my %refs; my %pmids;
  open (IN, "<$file") or die "Cannot open $file : $!";
  my $allfile = <IN>;
  $allfile =~ s///g;
  if ($allfile =~ m/SMID ID: <b>(.*?)<\/b>/) { $smmid = $1; } else { print "NO SMID $file\n"; }
#   if ($smmid{$smmid}) { print "SKIPPING $smmid ALREADY IN PG\n"; }
  next if ($smmid{$smmid});
  $pgid++;
  my $molId = &pad8Zeros($pgid); $molId = "WBMol:$molId";
  $remark = "See SMMID DB for more details: http://smmid.org/browse";
  if ($allfile =~ m/CHEMICAL NAME: (.*?)<br \/>/) { $chem = $1; } else { print "NO CHEMICAL NAME $file\n"; }
  if ($allfile =~ m/SYNONYMS: (.*?)<br \/>/) { $syn = $1; if ($syn eq 'none') { $syn = ''; } } else { print "NO SYNONYMS $file\n"; }
  if ($allfile =~ m/CAS: (.*?)<br \/>/) { $cas = $1; if ($cas eq 'tbd') { $cas = ''; } } else { print "NO CAS $file\n"; }
  if ($allfile =~ m/CONCISE SUMMARY: (.*?)<br \/>/) { 
      $remark = $1 . '|' . $remark; 
      if ($remark =~ m/<i>/) { $remark =~ s/<i>//g; }
      if ($remark =~ m/<\/i>/) { $remark =~ s/<\/i>//g; } }
    else { print "NO CONCISE SUMMARY $file\n"; }
  if ($allfile =~ m/www.ncbi.nlm.nih.gov\/pubmed\/(\d+)/) {
      my (@pmids) = $allfile =~ m/www.ncbi.nlm.nih.gov\/pubmed\/(\d+)/g;
      foreach my $pmid (@pmids) { 
        if ($pmidToPap{"pmid$pmid"}) { $refs{ $pmidToPap{"pmid$pmid"} }++; } } }
  if ($allfile =~ m/www.wormbase.org\/db\/misc\/paper\?name=WBPaper\d+;/) {
      my (@paps) = $allfile =~ m/www.wormbase.org\/db\/misc\/paper\?name=(WBPaper\d+);/g;
      foreach my $pap (@paps) { $refs{$pap}++; } }
  my (@paps) = sort keys %refs;
  if ($paps[0]) { $ref = join"\",\"", @paps; $ref = '"' . $ref . '"'; }
#     else { $ref = "NO REFERENCE $file"; }
    else { $ref = ''; }
  if ($chem && $syn) { $chem = $chem . '|' . $syn; }
    elsif ($syn) { $chem = $syn; }
  &addToPg($pgid, 'mop_molecule', $molId);
  &addToPg($pgid, 'mop_curator', "WBPerson712");
  &addToPg($pgid, 'mop_smmid', $smmid);
  &addToPg($pgid, 'mop_publicname', $smmid);
  &addToPg($pgid, 'mop_chemi', $cas);
  &addToPg($pgid, 'mop_paper', $ref);
  &addToPg($pgid, 'mop_synonym', $chem);
  &addToPg($pgid, 'mop_remark', $remark);
# moleculeuse / remark / other remark ?
#   print "$molId\t$smmid\t$chem\t$cas\t$remark\t$ref\n";
  close (IN) or die "Cannot open $file : $!";
} # foreach my $file (@files)
$/ = "\n";

sub addToPg {
  my ($pgid, $table, $data) = @_;
  return unless $data;
  ($data) = &filterForPg($data);
  my @pgcommands;
  my $pgcommand = "INSERT INTO $table VALUES ('$pgid', '$data');";
  push @pgcommands, $pgcommand;
  $pgcommand = "INSERT INTO ${table}_hst VALUES ('$pgid', '$data');";
  push @pgcommands, $pgcommand;
  foreach my $command (@pgcommands) {
    print "$command\n";
# UNCOMMENT TO POPULATE
#     $dbh->do( $command );
  } # foreach my $command (@pgcommands)
} # sub addToPg

# mop_smmid mop_publicname	$smmid
# mop_chemi	$cas
# mop_moleculeuse	$remark
# mop_paper	$ref
# mop_molecule	$molId
# mop_curator	WBPerson712
# mop_remark	"See SMMID DB for more details: http://smmid.org/browse"

sub filterForPg {
  my ($blah) = @_;
  $blah =~ s/'/''/g;
  return $blah;
} # sub filterForPg

sub pad8Zeros {         # take a number and pad to 8 digits
  my $number = shift;
  if ($number =~ m/^0+/) { $number =~ s/^0+//g; }               # strip leading zeros
  if ($number < 10) { $number = '0000000' . $number; }
  elsif ($number < 100) { $number = '000000' . $number; }
  elsif ($number < 1000) { $number = '00000' . $number; }
  elsif ($number < 10000) { $number = '0000' . $number; }
  elsif ($number < 100000) { $number = '000' . $number; }
  elsif ($number < 1000000) { $number = '00' . $number; }
  elsif ($number < 10000000) { $number = '0' . $number; }
  return $number;
} # sub pad8Zeros


__END__

my $result = $dbh->prepare( "SELECT * FROM two_comment WHERE two_comment ~ ?" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[1] =~ s///g;
    $row[2] =~ s///g;
    print "$row[0]\t$row[1]\t$row[2]\n";
  } # if ($row[0])
} # while (@row = $result->fetchrow)

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

