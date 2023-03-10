#!/usr/bin/perl -w

# split jae's protein protein interactions.  2018 05 21
#
# live on tazendra.  2018 05 23



use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );
use LWP::Simple;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;


my $baseUrl = 'http://mangolassi.caltech.edu/~postgres/cgi-bin/oa/ontology_annotator.cgi?';
# replace to make live
# my $baseUrl = 'http://tazendra.caltech.edu/~postgres/cgi-bin/oa/ontology_annotator.cgi?';

my %pgids;
$result = $dbh->prepare( "SELECT * FROM int_detectionmethod WHERE int_detectionmethod ~ ',' AND joinkey IN (SELECT joinkey FROM int_type WHERE int_type = 'ProteinProtein') AND joinkey IN (SELECT joinkey FROM int_curator WHERE int_curator ~ 'WBPerson38423');" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $pgids{$row[0]} = $row[1]; } } 

my $keys = join",", sort {$a<=>$b} keys %pgids;
print qq($keys\n);

my $count = 0;
foreach my $key (sort {$a<=>$b} keys %pgids) {
#   last if ($count > 1);
  print qq($key\t$pgids{$key}\n); 
  my $value = $pgids{$key};
  $value =~ s/\"//g;
  my (@values) = split/,/, $value;
  my $amount = scalar @values - 1;
#   next unless ($amount > 1);
  $count++;
  my @pgids; push @pgids, $key;
  for (1 .. $amount) { 
    my $data = get "${baseUrl}action=duplicateByPgids&idsToDuplicate=$key&datatype=int&curator_two=two1823";
    if ($data =~ m/OK	 DIVIDER 	(\d+)/) { push @pgids, $1; }
      else { print qq(ERROR did not create a duplicate pgid for $key\n); }
  }
  unless ( (scalar @pgids) == (scalar @values) ) {
    print qq(ERROR $key : arrays mismatched @pgids - @values \n); }
  for my $i (0 .. $#pgids) { 
    my $pgid  = $pgids[$i];
    my $value = $values[$i];
    print qq(update $pgid to $value\n);
    my $blah = get "${baseUrl}action=updatePostgresTableField&pgid=$pgid&field=detectionmethod&newValue=%22$value%22&datatype=int&curator_two=two1823";
    if ($i != 0) {
      my $bleh = get "${baseUrl}action=updatePostgresTableField&pgid=$pgid&field=name&newValue=&datatype=int&curator_two=two1823"; }
  }
  
} # foreach my $key (sort {$a<=>$b} keys %pgids)

