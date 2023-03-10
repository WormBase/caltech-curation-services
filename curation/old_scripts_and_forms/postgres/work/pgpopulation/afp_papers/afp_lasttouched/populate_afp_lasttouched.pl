#!/usr/bin/perl -w

# populate afp_lasttouched based on latest timestamp from other tables (not passwd)  2009 04 23

use strict;
use diagnostics;
use DBI;
use Time::Local;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 


my @afp_tables = qw ( ablationdata nonnematode massspec genestudied seqfeat antibody otherexpr matrices genesymbol expression siteaction celegans othersilico microarray humdis extvariation structcorr cellfunc overexpr mosaic invitro funccomp structinfo chemicals nematode genefunc supplemental cnonbristol phylogenetic newmutant lsrnai geneint timeaction comment review newsnp mappingdata geneprod transgene covalent rnai nocuratable marker genereg domanal seqchange );

my %paps;
foreach my $table (@afp_tables) {
  my $latest_time = 0;
  my $result = $dbh->prepare( "SELECT * FROM afp_$table" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    if ($paps{$row[0]}{time}) { $latest_time = $paps{$row[0]}{time}; }
    my ($converted_time) = $row[2];
    $converted_time =~ s/\D//g;
    ($converted_time) = $converted_time =~ m/(\d{14})/;
#     print "$row[0]\t$table\t$converted_time\n";
    if ($converted_time > $latest_time) {
      $paps{$row[0]}{time} = $converted_time;
      $paps{$row[0]}{timestamp} = $row[2];
    }
  } # while (@row = $result->fetchrow)
}

my $result = $dbh->prepare( "INSERT INTO afp_lasttouched VALUES (?, ?, ?)" );
foreach my $paper (sort keys %paps) {
  my ($year, $month, $day, $hours, $min, $sec) = $paps{$paper}{timestamp} =~ m/^(\d{4})\-(\d{2})\-(\d{2}) (\d{2}):(\d{2}):(\d{2})/;
  $month--;
  my $time = timelocal($sec,$min,$hours,$day,$month,$year); 
#   $result->execute( $paper, $time, $paps{$paper}{timestamp} );
  print "$paper\t$time\t$paps{$paper}{timestamp}\n";
} # foreach my $paper (sort keys %paps)



__END__

$result->execute("doesn't") or die "Cannot prepare statement: $DBI::errstr\n"; 
my $var = "doesn't";
$result->execute($var) or die "Cannot prepare statement: $DBI::errstr\n"; 

my $result = $dbh->do( "DELETE FROM friend WHERE firstname = 'bl\"ah'" );
(also do for INSERT and UPDATE if don't have a variable to interpolate with ? )

can cache prepared SELECTs with $dbh->prepare_cached( &c. );

if ($result->rows == 0) { print "No names matched.\n\n"; }	# test if no return

$result->finish;	# allow reinitializing of statement handle (done with query)
$dbh->disconnect;	# disconnect from DB

http://209.85.173.132/search?q=cache:5CFTbTlhBGMJ:www.perl.com/pub/1999/10/DBI.html+dbi+prepare+execute&cd=4&hl=en&ct=clnk&gl=us
