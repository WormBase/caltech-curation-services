#!/usr/bin/perl -w

# find invalid Transgene objects and remove them if there's a corresponding construct.  2014 07 16
#
# live run  2014 07 17

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %transgene;
$result = $dbh->prepare( "SELECT * FROM trp_name " );	# not excluding Fail because those refer to Papers, but could be valid Transgenes
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $transgene{$row[1]}++; } }

my %exp;
my @tables = qw( transgene construct );
foreach my $table (@tables) {
  $result = $dbh->prepare( "SELECT * FROM exp_${table} " );	# not excluding Fail because those refer to Papers, but could be valid Transgenes
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    if ($row[0]) { $exp{$table}{$row[0]} = $row[1]; } } }

my @pgcommands;
foreach my $pgid (sort {$a<=>$b} keys %{ $exp{transgene} }) {
  my (@transgenes) = $exp{transgene}{$pgid} =~ m/(WBTransgene\d+)/g; 
  my %hasFail; my %goodTransgene;
  foreach my $transgene (@transgenes) {
    if ($transgene{$transgene}) { $goodTransgene{$transgene}++; }
      else { $hasFail{$transgene}++; }
  } # foreach my $transgene (@transgenes)
  if (keys %hasFail > 0) {
    my $amountTransgene = scalar @transgenes;
    my (@constructs) = $exp{construct}{$pgid} =~ m/(WBCnstr\d+)/g; 
    my $amountConstruct = scalar @constructs;
    unless ($amountConstruct == $amountTransgene) { print "ERR $pgid has $amountTransgene transgenes and $amountConstruct constructs : @transgenes -- @constructs\n"; }
    foreach my $failTransgene (sort keys %hasFail) {
      print "$pgid invalid transgene $failTransgene\n"; 
    }
    my $goodTransgenes = join'","', sort keys %goodTransgene;
    push @pgcommands, qq(DELETE FROM exp_transgene WHERE joinkey = '$pgid';);
    if ($goodTransgenes) {
        push @pgcommands, qq(INSERT INTO exp_transgene VALUES ('$pgid', '"$goodTransgenes"'););
        push @pgcommands, qq(INSERT INTO exp_transgene_hst VALUES ('$pgid', '"$goodTransgenes"');); }
      else {
        push @pgcommands, qq(INSERT INTO exp_transgene_hst VALUES ('$pgid', NULL);); }
  } # if ($hasFail > 0)
} # foreach my $pgid (sort keys %{ $exp{transgene} })

foreach my $pgcommand (@pgcommands) {
  print "$pgcommand\n";
# UNCOMMENT TO POPULATE
#   $dbh->do( $pgcommand );
} # foreach my $pgcommand (@pgcommands)
