#!/usr/bin/perl -w

# sample PG query

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $result = $conn->exec( " SELECT app_paper.app_paper, app_tempname.app_tempname, app_phen_remark.app_phen_remark FROM app_phen_remark, app_paper, app_curator, app_tempname WHERE app_phen_remark.joinkey = app_paper.joinkey AND app_paper.joinkey = app_curator.joinkey AND  app_curator.app_curator = 'WBcurator2021' AND app_paper.joinkey = app_tempname.joinkey; " );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[1] =~ s///g;
    $row[2] =~ s///g;
    print "$row[0]\t$row[1]\t$row[2]\n";
  } # if ($row[0])
} # while (@row = $result->fetchrow)

__END__

