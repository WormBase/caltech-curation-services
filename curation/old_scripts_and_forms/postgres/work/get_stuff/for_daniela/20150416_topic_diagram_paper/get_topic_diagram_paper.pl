#!/usr/bin/perl -w

# get topic OA figure number and journal permission  2015 04 16



use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %journal_has_permission;                       # for image_overview below
my $infile = '/home/acedb/draciti/picture_curatable/journal_with_permission';
open (IN, "$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) { chomp $line; $journal_has_permission{$line}++; }
close (IN) or die "Cannot close $infile : $!";

my %pap_journal;
$result = $dbh->prepare( "SELECT * FROM pap_journal" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $pap_journal{$row[0]} = $row[1]; }

my @tables = qw( topicdiagram figurenumber paper );
my %hash;

foreach my $table (@tables) {
  $result = $dbh->prepare( "SELECT * FROM pro_$table WHERE joinkey IN (SELECT joinkey FROM pro_topicdiagram WHERE pro_topicdiagram = 'Topic Diagram')" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    if ($row[0]) { $hash{$table}{$row[0]} = $row[1]; } } }

foreach my $pgid (sort keys %{ $hash{topicdiagram} }) {
  my $fignum   = $hash{figurenumber}{$pgid};
  my (@papers) = $hash{paper}{$pgid} =~ m/WBPaper(\d+)/g;
  foreach my $paper (@papers) {
    my $journal = ''; 
    my $journal_has_permission = 'No';
    if ($pap_journal{$paper}) { $journal = $pap_journal{$paper}; }
    if ($journal_has_permission{$journal}) { $journal_has_permission = 'Yes'; }
    print qq($journal_has_permission\tWBPaper$paper\t$fignum\t$pgid\t$journal\n);
  } # foreach my $paper (@papers)
} # foreach my $pgid (sort keys %{ $hash{topicdiagram} })



__END__


