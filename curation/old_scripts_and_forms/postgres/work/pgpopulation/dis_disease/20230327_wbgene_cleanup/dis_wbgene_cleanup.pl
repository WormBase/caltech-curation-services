#!/usr/bin/perl -w

# for Ranjana.
# If dis_variation, remove wbgene, transfer to asserted_gene if not already there.
# If no dis_variation, but has wbgene, check if has asserted_gene and tell Ranjana,
# it might have a strain or something, and she'll fix it manually.  2023 03 27


use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %wbgene;
my %assertedgene;
my %variation;
$result = $dbh->prepare( "SELECT * FROM dis_variation" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { if ($row[0]) { $variation{$row[0]} = $row[1]; } }

$result = $dbh->prepare( "SELECT * FROM dis_wbgene" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { if ($row[0]) { $wbgene{$row[0]} = $row[1]; } }

$result = $dbh->prepare( "SELECT * FROM dis_assertedgene" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { if ($row[0]) { $assertedgene{$row[0]} = $row[1]; } }

my @pgcommands;
foreach my $joinkey (sort {$a<=>$b} keys %variation) {
  if ($wbgene{$joinkey} && $assertedgene{$joinkey}) {
    my $wbg = '"' . $wbgene{$joinkey} . '"';
    if ($wbg ne $assertedgene{$joinkey}) {
      print qq(HASVAR\tBAD\t$joinkey\t$wbg\t$assertedgene{$joinkey}\n);
    } else {
      print qq(HASVAR\tOK\t$joinkey\t$wbg\t$assertedgene{$joinkey}\n);
      push @pgcommands, qq(DELETE FROM dis_wbgene WHERE joinkey = '$joinkey';);
    }
  }
}

foreach my $joinkey (sort keys %wbgene) {
  next if $variation{$joinkey};
  next unless $assertedgene{$joinkey};
  my $wbg = '"' . $wbgene{$joinkey} . '"';
  if ($wbg ne $assertedgene{$joinkey}) {
    print qq(NOVAR\tBAD\t$joinkey\t$wbg\t$assertedgene{$joinkey}\n);
  } else {
    print qq(NOVAR\tOK\t$joinkey\t$wbg\t$assertedgene{$joinkey}\n);
    # push @pgcommands, qq(DELETE FROM dis_assertedgene WHERE joinkey = '$joinkey';); # don't delete, might have a Strain, it's only 11 + 2 from BAD
  }
}

foreach my $pgcommand (@pgcommands) {
  print qq($pgcommand\n);
# UNCOMMENT TO POPULATE
#   $dbh->do($pgcommand);
}

__END__

    $row[0] =~ s///g;

COPY dis_wbgene TO '/home/postgres/work/pgpopulation/dis_disease/20230327_wbgene_cleanup/pgbackup/dis_wbgene.pg';
COPY dis_wbgene_hst TO '/home/postgres/work/pgpopulation/dis_disease/20230327_wbgene_cleanup/pgbackup/dis_wbgene_hst.pg';
COPY dis_assertedgene TO '/home/postgres/work/pgpopulation/dis_disease/20230327_wbgene_cleanup/pgbackup/dis_assertedgene.pg';
COPY dis_assertedgene_hst TO '/home/postgres/work/pgpopulation/dis_disease/20230327_wbgene_cleanup/pgbackup/dis_assertedgene_hst.pg';
COPY dis_variation TO '/home/postgres/work/pgpopulation/dis_disease/20230327_wbgene_cleanup/pgbackup/dis_variation.pg';
COPY dis_variation_hst TO '/home/postgres/work/pgpopulation/dis_disease/20230327_wbgene_cleanup/pgbackup/dis_variation_hst.pg';

