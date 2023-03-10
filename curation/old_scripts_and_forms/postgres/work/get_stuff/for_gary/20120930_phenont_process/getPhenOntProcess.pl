#!/usr/bin/perl -w

# Match existing Process Terms to PhenOnt.obo for Gary  2012 09 30

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );
use LWP::Simple;


my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my %process;
my $result = $dbh->prepare( "SELECT prt_processid.prt_processid, prt_processname.prt_processname FROM prt_processid, prt_processname WHERE prt_processid.joinkey = prt_processname.joinkey" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $process{$row[1]} = $row[0]; }

my $file = get "http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/phenotype_ontology_obo.cgi";
my (@paras) = split/\n\n/, $file;

my @good_paras;
foreach (@paras) { 
  next unless ($_ =~ m/Term/);
  $_ =~ s/\[Term\]\n//g;
  push @good_paras, $_;
}

my %matches;
foreach my $process (sort keys %process) {
  my $key = lc($process);
  foreach my $para (@good_paras) {
    if ($para =~ m/$key/i) { $matches{$process}{$para}++; }
  } # foreach my $para (@good_paras)
} 

foreach my $process (sort keys %matches) {
  foreach my $para (sort keys %{ $matches{$process} }) {
    print "$process\t$para\n";
  }
  print "\n";
} # foreach my $process (sort keys %matches)

__END__
