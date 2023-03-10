#!/usr/bin/perl -w

# query constructs made by karen with papers, to papers in trp_paper without construct in trp_construct nor trp_coinjectionconstruct  2014 11 06

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my $count = 0;
$result = $dbh->prepare( "SELECT cns_name.joinkey, cns_name.cns_name, cns_paper.cns_paper FROM cns_name, cns_paper WHERE cns_name.joinkey = cns_paper.joinkey AND cns_name.joinkey IN (SELECT joinkey FROM cns_curator WHERE cns_curator ~ '712')" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
#   $count++; last if ($count > 10);
  my $cnsPgid   = $row[0];
  my $construct = $row[1];
  my (@papers)  = $row[2] =~ m/(WBPaper\d+)/g;
  my $isGood = 0;
  foreach my $paper (@papers) {
    last if ($isGood > 0);
    my $result2 = $dbh->prepare( "SELECT * FROM trp_coinjectionconstruct WHERE joinkey IN (SELECT joinkey FROM trp_paper WHERE trp_paper ~ '$paper')" );
    $result2->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row2 = $result2->fetchrow) {
# print "@row2\n";
      if ($row2[1] =~ m/$construct/) { $isGood++; last; }
    } # while (my @row2 = $result2->fetchrow)
    last if ($isGood > 0);
    $result2 = $dbh->prepare( "SELECT * FROM trp_construct WHERE joinkey IN (SELECT joinkey FROM trp_paper WHERE trp_paper ~ '$paper')" );
    $result2->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row2 = $result2->fetchrow) {
# print "@row2\n";
      if ($row2[1] =~ m/$construct/) { $isGood++; last; }
    } # while (my @row2 = $result2->fetchrow)
    last if ($isGood > 0);
  } # foreach my $paper (@papers)
  unless ($isGood) { 
    print qq($cnsPgid\t$construct\t$row[2] not in trp_ tables\n);
  }
}

__END__

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

