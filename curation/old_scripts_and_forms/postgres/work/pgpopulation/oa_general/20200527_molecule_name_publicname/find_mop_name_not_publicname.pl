#!/usr/bin/perl -w

# find mop_name entries that have multiple mop_publicname values.  2020 05 27

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %mop;
my %lcmop;

$result = $dbh->prepare( "SELECT mop_name.joinkey, mop_name.mop_name, mop_publicname.mop_publicname FROM mop_name, mop_publicname WHERE mop_name.joinkey = mop_publicname.joinkey" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    my $pgid = $row[0];
    my $id   = $row[1];
    my $pub  = $row[2];
    my $lcpub = lc($row[2]);
    $mop{$id}{$pub}{$pgid}++;
    $lcmop{$id}{$lcpub}{$pgid}++;
  } # if ($row[0])
} # while (@row = $result->fetchrow)

print "Different case-insensitive\n";
foreach my $id (sort keys %lcmop) {
  my (@names) = sort keys %{ $lcmop{$id} };
  if (scalar(@names) > 1) {  
    my $names = join'", "', @names;
    print qq($id\t"$names"\n);
  }
} # foreach my $id (sort keys %mop)

print "\nDifferent case-sensitive\n";
foreach my $id (sort keys %mop) {
  my (@names) = sort keys %{ $mop{$id} };
  if (scalar(@names) > 1) {  
    my $names = join'", "', @names;
    print qq($id\t"$names"\n);
  }
} # foreach my $id (sort keys %mop)
