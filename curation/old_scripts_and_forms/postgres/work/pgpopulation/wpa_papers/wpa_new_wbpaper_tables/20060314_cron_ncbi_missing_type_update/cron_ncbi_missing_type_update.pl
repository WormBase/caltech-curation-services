#!/usr/bin/perl -w

# Fetch pmid papers without Type data and try to update them from ncbi.  Run
# every Monday at 1 am   2006 03 15
# 0 1 * * sun /home/postgres/work/pgpopulation/wpa_new_wbpaper_tables/20060314_cron_ncbi_missing_type_update/cron_ncbi_missing_type_update.pl

# TODO check if there's no type, or no year, or no title, or no pages   2009 06 30
#
# disabled from cron.  will either replaced with pap_ script that does the same, or
# that only looks for status=medline  2010 06 23


use strict;
use CGI;
use Jex;
use LWP::UserAgent;
use LWP::Simple;
use DBI;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 


use lib qw( /home/postgres/work/pgpopulation/wpa_papers/wpa_new_wbpaper_tables/perl_wpa_match );
use wpa_match qw( processPubmed processForm );
use Jex;	# mailer

my %hash;

my %pmids;
my $result;

$result = $dbh->prepare( "SELECT * FROM wpa ORDER BY wpa_timestamp;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { 
  if ($row[3] eq 'valid') { $hash{valid}{$row[0]}++; }
    else { delete $hash{valid}{$row[0]}; } }

$result = $dbh->prepare( "SELECT * FROM wpa_identifier WHERE wpa_identifier ~ 'pmid' ORDER BY wpa_timestamp;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { 
  $row[1] =~ s/pmid//g;
  if ($row[3] eq 'valid') { 
      if ($hash{valid}{$row[0]}) { $hash{allpmids}{$row[1]}{$row[0]}++; }
        else { delete $hash{allpmids}{$row[1]}; }
      $hash{pmid}{$row[0]}{$row[1]}++; }
    else { delete $hash{pmid}{$row[0]}{$row[1]}; } }

$result = $dbh->prepare( "SELECT * FROM wpa_type ORDER BY wpa_timestamp;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { 
  if ($row[3] eq 'valid') { $hash{type}{$row[0]}{$row[1]}++; }
    else { delete $hash{type}{$row[0]}{$row[1]}; } }

$result = $dbh->prepare( "SELECT * FROM wpa_year ORDER BY wpa_timestamp;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { 
  if ($row[3] eq 'valid') { $hash{year}{$row[0]}{$row[1]}++; }
    else { delete $hash{year}{$row[0]}{$row[1]}; } }

$result = $dbh->prepare( "SELECT * FROM wpa_title ORDER BY wpa_timestamp;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { 
  if ($row[3] eq 'valid') { $hash{title}{$row[0]}{$row[1]}++; }
    else { delete $hash{title}{$row[0]}{$row[1]}; } }

$result = $dbh->prepare( "SELECT * FROM wpa_pages ORDER BY wpa_timestamp;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { 
  if ($row[3] eq 'valid') { $hash{pages}{$row[0]}{$row[1]}++; }
    else { delete $hash{pages}{$row[0]}{$row[1]}; } }

my $bad_pmids = '';
my $invalidpmids = get( "ftp://ftp.ncbi.nlm.nih.gov/pubmed/deleted_pmids.txt" );
my (@invalidpmids) = split/\n/, $invalidpmids;
foreach my $pmid (@invalidpmids) { if ($hash{allpmids}{$pmid}) { my $bad = join", ", sort keys %{ $hash{allpmids}{$pmid} }; $bad_pmids .= "$pmid\t$bad\n"; } }
if ($bad_pmids) {
  my $user = 'cron_ncbi_missing_type_update.pl';
  my $email = 'vanauken@its.caltech.edu';
  my $subject = 'deleted PMIDs';
  &mailer($user, $email, $subject, $bad_pmids); }
  

foreach my $paper (sort keys %{ $hash{pmid} }) {
  next unless $hash{valid}{$paper};
  foreach my $pmid (sort keys %{ $hash{pmid}{$paper} }) {
    unless ($hash{type}{$paper}) { $pmids{$pmid}++; }
    unless ($hash{year}{$paper}) { $pmids{$pmid}++; }
    unless ($hash{title}{$paper}) { $pmids{$pmid}++; }
    unless ($hash{pages}{$paper}) { $pmids{$pmid}++; }
  } # foreach my $pmid (sort keys %{ $hash{pmid}{$paper} })
#   my $pmid = join", ", sort keys %{ $hash{pmid}{$paper} };
#   unless ($hash{pages}{$paper}) { print "NO PAGES $paper : $pmid\n"; }
} # foreach my $paper (sort keys %{ $hash{pmid} })

my $count = scalar( keys %pmids );
my $pmid_list = join"\t", sort keys %pmids;
print "Processing $count : $pmid_list.<BR><BR>\n";

# UNCOMMENT TO RUN
my ($link_text) = &processPubmed($pmid_list, 'two1823');
print "$link_text\n";



__END__

# old way :

&enterPmids();

sub enterPmids {
  my @pmids;
  my $count = 0;
  my $result = $dbh->prepare( "SELECT wpa_identifier FROM wpa_identifier WHERE wpa_identifier ~ 'pmid' AND joinkey NOT IN (SELECT joinkey FROM wpa_type);" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { 
    $count++; 
#     if ($count > 4) { last; }
    $row[0] =~ s/pmid//g;
    push @pmids, $row[0]; }
  my $pmid_list = join"\t", @pmids;
  print "Processing $pmid_list.<BR><BR>\n";
#   my ($link_text) = &processPubmed($pmid_list, 'two1823');
#   print "$link_text\n";
} # sub enterPmids

