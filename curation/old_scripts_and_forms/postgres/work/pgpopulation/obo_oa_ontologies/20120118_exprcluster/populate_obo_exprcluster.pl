#!/usr/bin/perl -w

# populate obo tables for exprcluster  2012 01 17

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %good;
my %ignore;
$good{Description}++;
$good{Reference }++;
$good{Remark}++;
$ignore{Microarray_results}++;
$ignore{Algorithm}++;
my @bad_lines;
my %bad_tags;

my @pgcommands;

$/ = "";
my $infile = 'WS230ExprCluster.ace';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $entry = <IN>) {
  my (@lines) = split/\n/, $entry;
  my $header = shift @lines;
  next unless ( $header =~ m/Expression_cluster : "([^"]+)"/);
  my ($name) = $header =~ m/Expression_cluster : "([^"]+)"/;
  my @term_info = ();
  push @term_info, qq(<span style="font-weight: bold">id : </span> $name);
  foreach my $line (@lines) {
    my ($tag, $data) = ('', '');
    if ($line =~ m/^(.*?)\t\s*\"(.*?)\"/) { ($tag, $data) = $line =~ m/^(.*?)\t\s*\"(.*?)\"/; }
      elsif ($line =~ m/^(.*?)\t\s*(.*?)/) { ($tag, $data) = $line =~ m/^(.*?)\t\s*(.*?)/; }
      else { $tag = $line; }
    next if ($ignore{$tag});
    if ($good{$tag}) { 
        if ($data =~ m/\'/) { $data =~ s/\'/''/g; }
        push @term_info, qq(<span style="font-weight: bold">$tag : </span> $data); }
      else { push @bad_lines, "ERR invalid tag $tag in $name : $line\n"; $bad_tags{$tag}++; }
  } # foreach my $line (@lines)
  my $term_info = join"\n", @term_info;
  push @pgcommands, "INSERT INTO obo_name_exprcluster VALUES ('$name', '$name')";
  push @pgcommands, "INSERT INTO obo_data_exprcluster VALUES ('$name', E'$term_info')";
} # while (my $entry = <IN>)
close (IN) or die "Cannot close $infile : $!";
$/ = "\n";

foreach my $command (@pgcommands) {
  print "$command\n";
# UNCOMMENT TO POPULATE
#   $dbh->do( $command );
}

# uncomment to find bad tags and lines
# foreach my $tag (sort keys %bad_tags) { print "BAD TAG $tag\n"; }
# foreach my $line (@bad_lines) { print $line; }

__END__

DELETE FROM obo_name_exprcluster ;
DELETE FROM obo_data_exprcluster ;

$result = $dbh->prepare( "SELECT * FROM two_comment" );
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

