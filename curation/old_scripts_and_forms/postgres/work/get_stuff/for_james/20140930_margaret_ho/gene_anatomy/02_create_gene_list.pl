#!/usr/bin/env perl
use warnings;
use strict;
use diagnostics;
# use DBI;
use POSIX qw/strftime/;
use TextpressoGeneralTasks;
use TextpressoGeneralGlobals;
use LWP::Simple;

# my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb;host=131.215.52.76", "acedb", "") or die "Cannot connect to database!\n"; 


print STDERR "Processing gin_synonyms...\n";
my %gin_synonyms = ();
my %gin_syntype = ();
# my $result = $dbh->prepare("SELECT * FROM gin_synonyms WHERE gin_synonyms IS NOT NULL");
# $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
# while (my @row = $result->fetchrow) {
#     if ($row[1]) {
# 	$gin_synonyms{$row[0]}{$row[1]} = 1;
#     }
#     if ($row[2]) {
# 	$gin_syntype{$row[0]}{$row[2]} = 1;
#     }
# }
my $baseUrl = 'http://tazendra.caltech.edu/~postgres/cgi-bin/referenceform.cgi';
my $pgquery = qq(SELECT * FROM gin_synonyms WHERE gin_synonyms IS NOT NULL);
my $url = $baseUrl . '?action=Pg+!&perpage=all&pgcommand=' . $pgquery;
my $urlData = get $url;
my ($table) = $urlData =~ m/<TABLE border=1 cellspacing=5>\n<TR>(.*?)\n<\/TR>\n<\/TABLE>/ms;
my (@tableRows) = split/<\/TR>\n<TR>/, $table;
foreach my $row (@tableRows) {
  $row =~ s/^<TD>//; $row =~ s/<\/TD>$//;
  my (@row) = split/<\/TD>\n<TD>/, $row;
  if ($row[1]) { $gin_synonyms{$row[0]}{$row[1]} = 1; }
  if ($row[2]) { $gin_syntype{$row[0]}{$row[2]}  = 1; }
}



print STDERR "Processing gin_locus...\n";
my %gin_locus = ();
# $result = $dbh->prepare("SELECT * FROM gin_locus WHERE gin_locus IS NOT NULL");
# $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
# while (my @row = $result->fetchrow) {
#     if ($row[1]) {
# 	$gin_locus{$row[0]}{$row[1]} = 1;
#     }
# }
$pgquery = qq(SELECT * FROM gin_locus WHERE gin_locus IS NOT NULL);
$url = $baseUrl . '?action=Pg+!&perpage=all&pgcommand=' . $pgquery;
$urlData = get $url;
($table) = $urlData =~ m/<TABLE border=1 cellspacing=5>\n<TR>(.*?)\n<\/TR>\n<\/TABLE>/ms;
(@tableRows) = split/<\/TR>\n<TR>/, $table;
foreach my $row (@tableRows) {
  $row =~ s/^<TD>//; $row =~ s/<\/TD>$//;
  my (@row) = split/<\/TD>\n<TD>/, $row;
  if ($row[1]) { $gin_locus{$row[0]}{$row[1]} = 1; }
}


print STDERR "Processing gin_wbgene...\n";
my %gin_wbgene = ();
# $result = $dbh->prepare("SELECT * FROM gin_wbgene WHERE gin_wbgene IS NOT NULL");
# $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
# while (my @row = $result->fetchrow) {
#     if ($row[1]) {
# 	$gin_wbgene{$row[0]}{$row[1]} = 1;
#     }
# }
$pgquery = qq(SELECT * FROM gin_wbgene WHERE gin_wbgene IS NOT NULL);
$url = $baseUrl . '?action=Pg+!&perpage=all&pgcommand=' . $pgquery;
$urlData = get $url;
($table) = $urlData =~ m/<TABLE border=1 cellspacing=5>\n<TR>(.*?)\n<\/TR>\n<\/TABLE>/ms;
(@tableRows) = split/<\/TR>\n<TR>/, $table;
foreach my $row (@tableRows) {
  $row =~ s/^<TD>//; $row =~ s/<\/TD>$//;
  my (@row) = split/<\/TD>\n<TD>/, $row;
  if ($row[1]) { $gin_wbgene{$row[0]}{$row[1]} = 1; }
}

foreach my $jk (keys % gin_synonyms) {
    my @locus = keys % {$gin_locus{$jk}};
    if (scalar (@locus) == 1) {
#	my @aux = (keys % {$gin_wbgene{$jk}}, $locus[0], keys % {$gin_synonyms{$jk}});
	my @aux = (keys % {$gin_wbgene{$jk}}, $locus[0]);
	if (is_celegans_gene($locus[0])) {
	    print join (",", @aux), "\n";
#            print "$aux[0]\n";
	}
    }
}

# $dbh->disconnect;

sub is_celegans_gene {
    my $s = shift;
    if ($s =~ /^(WBGene|GENEPREDICTION|Cr|Cbr|Cbg|Cbn|Cjp|Hpa|Oti|Ppa|Cja)/i) {
	return 0;
    }
    return 1;
}
