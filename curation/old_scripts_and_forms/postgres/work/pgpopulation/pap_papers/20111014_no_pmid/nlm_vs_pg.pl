#!/usr/bin/perl -w

# take Kimberly's pubmed journal list and match to papers in postgres without a pmid.  2011 10 14

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

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

