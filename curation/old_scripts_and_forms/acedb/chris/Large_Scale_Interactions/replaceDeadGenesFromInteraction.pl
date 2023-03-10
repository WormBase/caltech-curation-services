#!/usr/bin/perl -w

# take LargeScaleInteraction ace file, look for dead genes, and replace them if possible or warn if no replacement.
# break it up line-by-line to ignore Remark lines from gene replacements.  2011 12 15

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my $infile = 'Original_Large_Scale_Interactions_new_format.ace';
my $outfile = 'Large_scale_interactions_WS239.ace';

my %dead; my %mapTo;
my $result = $dbh->prepare( "SELECT * FROM gin_dead" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[1] =~ m/merged_into WBGene(\d+)/) { $mapTo{$row[0]} = $1; }
    else { $dead{$row[0]}++; }
} # while (my @row = $result->fetchrow)

$/ = "";
open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
open (IN, "<$infile") or die "Cannot open $infile : $!";
my %dead_errors;
while (my $para = <IN>) {
  next unless ($para =~ m/Interaction : /);
  my $intObject = '';
  if ($para =~ m/Interaction : \"(WBInteraction\d+)\"/) { $intObject = $1; }
  my (@genes) = $para =~ m/WBGene(\d+)/g;
  my %genes; foreach my $gene (@genes) { $genes{$gene}++; }
  my (@lines) = split/\n/, $para;
  my $new_para = '';
  my $somethingDead = 0;
  foreach my $line (@lines) {
    if ($line =~ m/Remark\t/) { $new_para .= "$line\n"; }	# don't replace anything from Remark tags, just add to output paragraph
      else {												# if not a remark tag, replace genes, or find dead genes
        foreach my $gene (sort keys %genes) {
          if ($dead{$gene}) { $dead_errors{"DEAD\t$intObject\t$gene\n"}++; $somethingDead++; }
          if ($mapTo{$gene}) { $line =~ s/WBGene$gene/WBGene$mapTo{$gene}/g; } }
        $new_para .= "$line\n"; }							# add line to output paragraph
  } # foreach my $line (@lines)
  unless ($somethingDead) { print OUT "$new_para\n"; }		# unless there was a dead gene, print the output paragraph
} # while (my $para = <IN>)
close (IN) or die "Cannot close $infile : $!";
close (OUT) or die "Cannot close $outfile : $!";

foreach my $dead_line (sort keys %dead_errors) { print $dead_line; }

__END__



my $result = $dbh->prepare( "SELECT * FROM two_comment" );
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

