#!/usr/bin/perl -w

# get svm results for rnai and add new high/medium to cfp_rnai, and add new lows to a file.
# 2009 09 24

# run every monday at 2am.
# 0 2 * * mon /home/postgres/work/pgpopulation/svm/gary_rnai/parse_rnai_svm.pl


use strict;
use diagnostics;
use LWP::Simple;
use DBI;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my %low;
my $lowfile = '/home/postgres/work/pgpopulation/svm/gary_rnai/low';

open (IN, "+>>", $lowfile) or die "Cannot edit $lowfile : $!";
seek IN, 0, 0;						# go to beginning of file to read
while (my $line = <IN>) { 
  if ($line =~ m/WBPaper(\d+)/) { $low{$1}++; }
}							# end of file, will now append when printing to it


my %data;
my $svmrnai = get 'http://caprica.caltech.edu/celegans/svm_results/Juancarlos/rnai';
my (@lines) = split/\n/, $svmrnai;
shift @lines;
foreach my $line (@lines) {
  my ($paper, $confidence) = $line =~ m/WBPaper(\d+).*?(high|medium|low)/;
  if ( $data{$paper} ) {
    if ( $data{$paper} eq 'high' ) { next; }	# was high, leave alone
    elsif ( $data{$paper} eq 'medium' ) { 		# was medium, change if now high
      if ( $confidence eq 'high' ) { $data{$paper} = $confidence; } }
    else {							# was low, change if now medium or high
      if ( ( $confidence eq 'high' ) || ( $confidence eq 'medium' ) ) { $data{$paper} = $confidence; } }
  } else {
    $data{$paper} = $confidence;
  }
}
foreach my $paper (sort keys %data) {
  if ($data{$paper} eq 'low') { 
    unless ($low{$paper}) { print IN "WBPaper$paper\n"; } }
  else {
    my $result = $dbh->prepare( "SELECT * FROM cfp_rnai WHERE joinkey = '$paper'" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    my @row = $result->fetchrow();
    unless ($row[0]) {
      my $command = "INSERT INTO cfp_rnai VALUES('$paper', '$data{$paper}', 'two557')";
#       print "$command\n";
      $result = $dbh->do( $command );
    }
  }
}
close (IN) or die "Cannot close $lowfile : $!";

__END__


use DBI;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my $result = $dbh->prepare( "SELECT * FROM two_comment WHERE two_comment ~ ?" );
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
