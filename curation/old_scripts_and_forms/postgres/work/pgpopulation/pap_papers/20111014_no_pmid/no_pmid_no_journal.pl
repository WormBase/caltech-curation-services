#!/usr/bin/perl -w

# find papers without a PMID and without a journal and sort by type   2011 10 27

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %valid;
my %pmid;
my %journal;
my %type;
my %typeIndex;

$result = $dbh->prepare( "SELECT * FROM pap_status WHERE pap_status = 'valid'" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $valid{$row[0]}++; }

$result = $dbh->prepare( "SELECT * FROM pap_journal" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $journal{$row[0]}++; }

$result = $dbh->prepare( "SELECT * FROM pap_identifier WHERE pap_identifier ~ '^pmid'" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $pmid{$row[0]}{$row[1]}++; }

$result = $dbh->prepare( "SELECT * FROM pap_type" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $type{$row[0]}{$row[1]}++; }

$result = $dbh->prepare( "SELECT * FROM pap_type_index" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $typeIndex{$row[0]} = $row[1]; }

my %byType;
foreach my $paper (sort keys %valid) {
  next if $journal{$paper};
  next if $pmid{$paper};
  my @types;
  foreach my $type (keys %{ $type{$paper} }) {
    my $typeName = $typeIndex{$type};
    push @types, $typeName; }
  my $types = join", ", @types;
  $byType{$types}{$paper}++;
} # foreach my $paper (sort keys %valid)

foreach my $type (sort keys %byType) {
  foreach my $paper (sort keys %{ $byType{$type} }) {
    print "$type\t$paper\n"; } }


__END__

my $infile = 'nlmcatalog_result.xml';
$/ = undef;
open (IN, "<$infile") or die "Cannot open $infile : $!";
my $all_file = <IN>;
close (IN) or die "Cannot close $infile : $!";
$/ = "\n";

my %journals;
my (@titles) = $all_file =~ m/<Title>(.*?)<\/Title>/g;
foreach my $title (@titles) { $journals{$title}++; }
(@titles) = $all_file =~ m/<MedlineTA>(.*?)<\/MedlineTA>/g;
foreach my $title (@titles) { $journals{$title}++; }
(@titles) = $all_file =~ m/<TitleAlternate>(.*?)<\/TitleAlternate>/g;
foreach my $title (@titles) { $journals{$title}++; }

my $result = $dbh->prepare( "SELECT * FROM pap_journal WHERE joinkey NOT IN (SELECT joinkey FROM pap_identifier WHERE pap_identifier ~ 'pmid') ORDER BY pap_journal, joinkey" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($journals{$row[1]}) { print "$row[0]\t$row[1]\n"; }
}

__END__

# <NLMCatalogRecord Owner="NLM" Status="Completed">
# 
# <TitleMain Sort="0">
#        <Title>20 century British history.</Title>
#    </TitleMain>
#    <MedlineTA>20 Century Br Hist</MedlineTA>
#    <TitleOther Sort="N" Owner="NCBI" TitleType="OtherTA">
#        <TitleAlternate>20 Century Br Hist</TitleAlternate>
#    </TitleOther>
#    <TitleOther Sort="N" Owner="NLM" TitleType="Other">
#        <TitleAlternate>Twentieth century British history</TitleAlternate>
#    </TitleOther>
# 
# </NLMCatalogRecord>


my $result = $dbh->prepare( "SELECT * FROM two_comment" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[1] =~ s///g;
    $row[2] =~ s///g;
    print "$row[0]\t$row[1]\t$row[2]\n";
  } # if ($row[0])
} # while (@row = $result->fetchrow)

