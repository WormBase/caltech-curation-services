#!/usr/bin/perl -w

# get pictures that have expr pattern with northern | western | rtpcr  2018 06 14
#
# re-use for other types, but query exp_exprtype instead.  2018 10 31


use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %exprs;
# $result = $dbh->prepare( "SELECT exp_name FROM exp_name WHERE joinkey IN (SELECT joinkey FROM exp_insitu)" );
$result = $dbh->prepare( "SELECT exp_name FROM exp_name WHERE joinkey IN (SELECT joinkey FROM exp_exprtype WHERE exp_exprtype ~ 'In_Situ')" );
# $result = $dbh->prepare( "SELECT exp_name FROM exp_name WHERE joinkey IN (SELECT joinkey FROM exp_exprtype WHERE exp_exprtype ~ 'Reporter_gene')" );
# $result = $dbh->prepare( "SELECT exp_name FROM exp_name WHERE joinkey IN (SELECT joinkey FROM exp_exprtype WHERE exp_exprtype ~ 'Antibody')" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $exprs{$row[0]}++; } }

foreach my $expr (sort keys %exprs) {
  $result = $dbh->prepare( "SELECT pic_name.pic_name, pic_paper.pic_paper FROM pic_name, pic_paper WHERE pic_name.joinkey = pic_paper.joinkey AND pic_name.joinkey IN (SELECT joinkey FROM pic_exprpattern WHERE pic_exprpattern ~ '\"$expr\"')" );
#   $result = $dbh->prepare( "SELECT pic_name FROM pic_name WHERE joinkey IN (SELECT joinkey FROM pic_exprpattern WHERE pic_exprpattern ~ '\"$expr\"')" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    if ($row[0]) { 
      print qq($row[0]\t$row[1]\t$expr\n); 
#       print qq($row[0]\t$expr\n); 
} } }
