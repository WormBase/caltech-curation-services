#!/usr/bin/perl

# Take result of :
# grep @ WBPaper0003[12]* 
# in textpresso-dev@textpresso.org at 
# /data2/data-processing/data/celegans/Data/processedfiles/body/ 
# and process to find email addresses.  2008 08 08
#
# Use the textpresso cronjob output (everyday 2 am) instead of the static file.
# 2008 10 17
#
# Changed to print to textpresso_emails file, periods no longer tokenized.  2009 04 23
#
# Added extra code to check journal names (BMC journals) and treat those differently to
# get the corresponding author.  2009 06 19
#
# Updated from wpa to pap tables, even though they're not live yet.  2010 06 23
#
# Script last updated 2011 06 03, was part of /home/postgres/work/pgpopulation/textpresso/wrapper.sh
# The file it generates seems to only be used by  /home/postgres/work/pgpopulation/afp_papers/assign_passwd.pl
# which is no longer used since Valerio took over AFP a while ago.  2021 01 27
#
#
# put in 
# 0 4 * * * /home/postgres/work/pgpopulation/textpresso/wrapper.sh
# 2009 04 23



use strict;
use diagnostics;
use LWP::Simple;
use DBI;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my %journals; my %bmc;
# my $result = $dbh->prepare( "SELECT * FROM wpa_journal ORDER BY wpa_timestamp;" );
my $result = $dbh->prepare( "SELECT * FROM pap_journal ORDER BY pap_timestamp;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  $journals{$row[0]}{$row[1]}++; }
#   if ($row[3] eq 'valid') { $journals{$row[0]}{$row[1]}++; } # {
#     else { delete $journals{$row[0]}{$row[1]}; } }
foreach my $joinkey (sort keys %journals) {
  foreach my $name (sort keys %{ $journals{$joinkey} }) {
    if ($name =~ m/^BMC/) { $bmc{$joinkey}++; } } }

my %emails;

# my $infile = 'textpresso_grep_@';
# my $infile = 'grep_output';
# open (IN, "<$infile") or die "Cannot open $infile : $!";
# while (my $line = <IN>) { 
my $infile = get "http://textpresso-dev.caltech.edu/azurebrd/grep_output";
my (@lines) = split/\n/, $infile;
foreach my $line (@lines) {
#   my ($paper) = $line =~ m/^WBPaper(\d+):/;
  my ($paper) = $line =~ m/^\/data2\/data-processing\/data\/celegans\/Data\/processedfiles\/body\/WBPaper(\d+):/;
  next unless $paper;
  next if ($emails{$paper});
#   my ($email) = $line =~ m/((?:[\w\-]+ \. )*[\w\-]+\s*\@\s*[\w\-]+(?: \. [\w\-]+)+) \S/;	# for when dots were tokenized   2009 04 23
  my ($email) = $line =~ m/\b([\w\-\.]+\@[\w\-\.]+)\b/;
  if ($bmc{$paper}) { if ($line =~ m/\* \- ([\w\-\.]+\@[\w\-\.]+)\b/) { $email = $1; } }
# print "EMAIL $email P $paper\n";
  if ($email) {
    $email =~ s/\s+//g;
    $emails{$paper} = $email; }
} # while (my $line = <IN>)
# close (IN) or die "Cannot close $infile : $!";

my $outfile = '/home/postgres/work/pgpopulation/afp_papers/textpresso_emails';
open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
foreach my $paper (sort {$a<=>$b} keys %emails) {
  print OUT "$paper\t";
  if ($emails{$paper}) { print OUT "$emails{$paper}"; }
  print OUT "\n";
} # foreach my $paper (sort {$a<=>$b} keys %emails)
close (OUT) or die "Cannot close $outfile : $!";


__END__ 

WBPaper00031000:In addition , mutations in unc-80 *Correspondence : schuske@biology . utah . edu suppressed both a hypomorphic allele of unc-26 ( e314 ) and , to a lesser degree , a null allele of unc-26 ( s1710 ) . 
WBPaper00031001:A critical component of the timekeeping mechanism of this rhythm is the inositol-1 , 4 , 5 *Correspondence : jorgensen@biology . utah . edu trisphosphate ( IP3 ) receptor [ 4 , 5 ] . 
