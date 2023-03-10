#!/usr/bin/perl -w

# populate trp_objpap_falsepos based on ObsoleteTg.txt ;  new script that populates
# based on textpresso will be ignoring name-paper pairs based on Fail in 
# trp_objpap_falsepos.   2010 08 24
#
# real run.  2010 08 26


use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %obs;
my $infile = '/home/acedb/wen/phenote_transgene/ObsoleteTg.txt';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) {
  chomp $line;
  next unless $line;
  next if ($line =~ m/^\/\//);
  my ($tg, $paper);
  if ($line =~ m/^(\S+)\s+(\S+)/) { $tg = $1; $paper = $2; }
  my $remark = ''; if ($line =~ m/\/\/(.*)/) { $remark = $1; $remark =~ s/\s+$//; $remark =~ s/^\s+//; unless ($remark =~ m/\.$/) { $remark .= '.'; } }
  $tg =~ s/\s+//g;
  unless ($paper) { $paper = 'all'; }
  next unless ($paper =~ m/^WBPaper/);
  next if ($tg eq 'hIn1');
  next if ($tg eq 'mIn1');
  $obs{$tg}{paper}{$paper}++;
  if ($remark) { $obs{$tg}{remark}{$remark}++; }
#   print "OBS $tg PAP $paper E\n";
} # while (my $line = <IN>) {
close (IN) or die "Cannot close $infile : $!";


my $highest = 0;
$result = $dbh->prepare( "SELECT joinkey FROM trp_name ORDER BY CAST (joinkey AS integer) DESC" );	# every real annotation should have a tempname
$result->execute(); my @row = $result->fetchrow(); if ($row[0] > $highest) { $highest = $row[0]; }
$result = $dbh->prepare( "SELECT joinkey FROM trp_curator ORDER BY CAST (joinkey AS integer) DESC" );	# new annotations that were just created will have an ID and a curator, but may not have a tempname yet
$result->execute(); @row = $result->fetchrow(); if ($row[0] > $highest) { $highest = $row[0]; }

my @pgcommands;

&createEntry('hIn1', 'WBPerson712', '');
&createEntry('mIn1', 'WBPerson712', '');

foreach my $tg (sort keys %obs) {
  my (@papers) = sort keys %{ $obs{$tg}{paper} };
  my $papers = '';
  my $remarks = '';
  if (scalar(@papers) > 0) {
    $papers = join"\",\"", @papers; $papers = '"' . $papers . '"'; }
  my (@remarks) = sort keys %{ $obs{$tg}{remark} };
  if (scalar(@remarks) > 0) {
    $remarks = join"  ", @remarks;
    if ($remarks =~ m/\'/) { $remarks =~ s/\'/''/g; } }
  &createEntry($tg, 'WBPerson712', $papers, $remarks);
} # foreach my $tg (sort keys %obs)

foreach my $pgcommand (@pgcommands) {
  print "$pgcommand\n";
# UNCOMMENT TO POPULATE
#   $result = $dbh->do($pgcommand);
} # foreach my $pgcommand (@pgcommands)


sub createEntry {
  my ($name, $curator, $papers, $remarks) = @_;
  $highest++;
  print "$name\t$papers\n";
  push @pgcommands, "INSERT INTO trp_name VALUES ('$highest', '$name')";
  push @pgcommands, "INSERT INTO trp_curator VALUES ('$highest', '$curator')";
  push @pgcommands, "INSERT INTO trp_objpap_falsepos VALUES ('$highest', 'Fail')";
  push @pgcommands, "INSERT INTO trp_name_hst VALUES ('$highest', '$name')";
  push @pgcommands, "INSERT INTO trp_curator_hst VALUES ('$highest', '$curator')";
  push @pgcommands, "INSERT INTO trp_objpap_falsepos_hst VALUES ('$highest', 'Fail')";
  if ($papers) { push @pgcommands, "INSERT INTO trp_reference VALUES ('$highest', '$papers')"; }
  if ($remarks) { push @pgcommands, "INSERT INTO trp_remark VALUES ('$highest', '$remarks')"; }
  if ($papers) { push @pgcommands, "INSERT INTO trp_reference_hst VALUES ('$highest', '$papers')"; }
  if ($remarks) { push @pgcommands, "INSERT INTO trp_remark_hst VALUES ('$highest', '$remarks')"; }
} # sub createEntry


__END__

