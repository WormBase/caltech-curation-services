#!/usr/bin/perl -w

# parse  data to populate OA transgene data.  trp_  name / reference / synonym  for Karen.  2010 06 16

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my $result = $dbh->prepare( "SELECT * FROM trp_name ORDER BY CAST (joinkey AS INTEGER ) DESC; " );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
my @row = $result->fetchrow();
my $pgid = $row[0];

$/ = undef;
my $infile = 'Ex_transgenes.txt';
open (IN, "<$infile") or die "Cannot open $infile : $!";
my $all_file = <IN>;
close (IN) or die "Cannot close $infile : $!";

my %hash;
my @pgcommands;
my (@entries) = split/\n----------\n/, $all_file;
foreach my $entry (@entries) {
  my (@lines) = split/\n/, $entry;
  my $name; 
  my @pairs;
  foreach my $line (@lines) {
    if ($line =~ m/^\| /) { 
      $line =~ s/^\| //; push @pairs, $line; } 
    elsif ($line =~ m/[a-zA-Z]/) { $name = $line; }
  }
  foreach my $pair (@pairs) {
    if ($pair =~ m/\'/) { $pair =~ s/\'/''/g; }
    my ($reference, @other) = split/\t/, $pair;
    my $synonym;
    if (scalar(@other) > 0) { $synonym = join" ", @other; }
    ($reference) = $reference =~ m/(WBPaper\d+)/;
    $hash{$name}{reference}{$reference}++;
    if ($synonym) { push @{ $hash{$name}{synonym} }, $synonym; }
#     $pgid++;
#     print "pgid : $pgid\n";
#     print "name : $name\n";
#     push @pgcommands, "INSERT INTO trp_name VALUES ('$pgid', '$name', CURRENT_TIMESTAMP);";
#     push @pgcommands, "INSERT INTO trp_name_hst VALUES ('$pgid', '$name', CURRENT_TIMESTAMP);";
#     print "reference : $reference\n";
#     push @pgcommands, "INSERT INTO trp_reference VALUES ('$pgid', '$reference', CURRENT_TIMESTAMP);";
#     push @pgcommands, "INSERT INTO trp_reference_hst VALUES ('$pgid', '$reference', CURRENT_TIMESTAMP);";
#     if ($synonym) { 
#       print "synonym : $synonym\n"; 
#       push @pgcommands, "INSERT INTO trp_synonym VALUES ('$pgid', '$synonym', CURRENT_TIMESTAMP);";
#       push @pgcommands, "INSERT INTO trp_synonym_hst VALUES ('$pgid', '$synonym', CURRENT_TIMESTAMP);";
#     }
#     print "\n";
  }
}

foreach my $name (sort keys %hash) {
  $pgid++;
  print "pgid : $pgid\n";
  print "name : $name\n";
  push @pgcommands, "INSERT INTO trp_name VALUES ('$pgid', '$name', CURRENT_TIMESTAMP);";
  push @pgcommands, "INSERT INTO trp_name_hst VALUES ('$pgid', '$name', CURRENT_TIMESTAMP);";
  my (@reference) = sort keys %{ $hash{$name}{reference} };
  my ($reference) = join" | ", @reference;
  print "reference : $reference\n";
  push @pgcommands, "INSERT INTO trp_reference VALUES ('$pgid', '$reference', CURRENT_TIMESTAMP);";
  push @pgcommands, "INSERT INTO trp_reference_hst VALUES ('$pgid', '$reference', CURRENT_TIMESTAMP);";
  if ($hash{$name}{synonym}) {
    my ($synonym) = join" | ", @{ $hash{$name}{synonym} };
    print "synonym : $synonym\n"; 
    push @pgcommands, "INSERT INTO trp_synonym VALUES ('$pgid', '$synonym', CURRENT_TIMESTAMP);";
    push @pgcommands, "INSERT INTO trp_synonym_hst VALUES ('$pgid', '$synonym', CURRENT_TIMESTAMP);";
  }
  print "\n";
} # foreach my $name (sort keys %hash)

foreach my $command (@pgcommands) {
  print "$command\n";
# UNCOMMENT TO enter data
#   $dbh->do( $command );
} # foreach my $command (@pgcommands)

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

