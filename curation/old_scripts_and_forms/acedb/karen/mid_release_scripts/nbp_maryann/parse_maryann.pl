#!/usr/bin/perl -w

# update NBP data if the allele already exists, otherwise create a new
# character.  2008 05 01
#
# update NBP timestamp when doing udpates.  grant access to acedb account on
# these tables.  2008 05 02
#
# add filereaddate for Jolene.
# add filereaddate updates if $found, for Jolene.  2010 04 07
#
# changed for DBI.pm  2010 08 11
#
# add curator as Mary Ann  2010 08 27
#
# change from app_tempname to app_variation tables, for Karen.  
# get highest from app_curator instead of app_tempname nor app_variation.
# update app_curator to mary ann for anything being updated.  2010 11 18
#
# removed app_type table, not being used anymore.  2011 05 03
#
# get all app_paper app_person app_nbp, skip updating data if that pgid
# has any paper or person, or if nbp is the same as before.  no longer 
# always update the app_nbp, only update if the previous skips don't 
# apply.  2013 07 11
#
# added a section to look at allele names and WBVar IDs, and try to create
# them through the generic.cgi  with  action=AddTempVariationObo
# this should only create ones that don't already exist, and add them to
# obo_*_variation so they show in the OA.  To make it server independent
# kludging it by having a 'thismachineis' file in the same directory, 
# that tells it the name of the machine.  for Karen.  2013 11 21
#
# got rid of kludge and using Net::Domain  2013 11 25
#
# try removing all \ from input.  2015 10 13



use strict;
use diagnostics;
use Jex;
use Encode qw( from_to is_utf8 );
use LWP::Simple;
use Net::Domain qw(hostname hostfqdn hostdomain);	# only using hostname


use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my $domain = 'caltech.edu';
my $path = '~azurebrd/cgi-bin/forms/generic.cgi';
my $subdomain = '';
my $baseUrl = '';

my %allowedSubdomains;
my @allowedSubdomains = qw( mangolassi tazendra );
foreach (@allowedSubdomains) { $allowedSubdomains{$_}++; }
my $subDomains = join" | ", @allowedSubdomains;

# my $thismachineis_file = 'thismachineis';
# open (IN, "<$thismachineis_file") or die "Cannot open $thismachineis_file which is necessary : $!";
# my $thismachineis = <IN>; chomp $thismachineis; 
# close (IN) or die "Cannot close $thismachineis_file : $!";
my $thismachineis = hostname();
if ($allowedSubdomains{$thismachineis}) {
    $subdomain = $thismachineis;
    $baseUrl = 'http://' . $subdomain . '.' . $domain . '/' . $path; }
  else { print qq($thismachineis not a valid server, need : $subDomains\n); die; }

my $date = &getPgDate();

my %paper; my %person; my %nbp;
my $result = $dbh->prepare( "SELECT * FROM app_paper;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { if ($row[0]) { $paper{$row[0]} = $row[1]; } }
$result = $dbh->prepare( "SELECT * FROM app_person;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { if ($row[0]) { $person{$row[0]} = $row[1]; } }
$result = $dbh->prepare( "SELECT * FROM app_nbp;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { if ($row[0]) { $nbp{$row[0]} = $row[1]; } }

my $infile = 'NBP_latest';

open (IN, "<$infile") or die "Cannot open $infile : $!";	# read file once for adding to obo_*_variation through generic.cgi
while (my $line = <IN>) {
  my $pubname = ''; my $varid = '';
  if ($line =~ m/\/\/Allele ([a-z]{2,3}\d+) /) { 	# matches an allele name
    $pubname = $1;
    my $nextline = <IN>;							# on the next line match for the WBVar ID
    if ($nextline =~ m/Variation : (WBVar\d+) \"(.*?)\"/) { $varid = $1; }
    if ($pubname && $varid) { 
      my $url = $baseUrl . '?action=AddTempVariationObo&varid=' . $varid . '&pubname=' . $pubname;
#       print "$url\n";
      my $pageTryToAddVariation = get $url; 
# print "$varid $pubname : $pageTryToAddVariation\n\n";
    } # if ($pubname && $varid)
  } # if ($line =~ m/\/\/Allele ([a-z]{2,3}\d+) /)
} # while (my $line = <IN>)
close (IN) or die "Cannot close $infile : $!";

open (IN, "<$infile") or die "Cannot open $infile : $!";	# read file again to write to app_ tables for OA curation
while (my $line = <IN>) {
  if ($line =~ m/Variation : (\w+) \"(.*?)\"/) { 
    my $allele = $1; my $remark = $2;
    if ($remark =~ m/\\/) { $remark =~ s/\\//g; }
    &check($allele, $remark);
  }
} # while (my $line = <IN>)
close (IN) or die "Cannot close $infile : $!";

sub check {
  my ($allele, $remark) = @_;  my %joinkeys;  my $found = 0;
  unless (is_utf8($remark)) { from_to($remark, "iso-8859-1", "utf8"); }
  if ($remark =~ m/\'/) { $remark =~ s/\'/''/g; }
  $result = $dbh->prepare( "SELECT * FROM app_variation WHERE app_variation = '$allele';" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { if ($row[0]) { $joinkeys{$row[0]}++; $found++; } }
  my @commands; my $command;
  if ($found) {
# Don't do this for all matches anymore
#       my $command = "UPDATE app_nbp SET app_timestamp = CURRENT_TIMESTAMP WHERE joinkey IN (SELECT joinkey FROM app_variation WHERE app_variation = '$allele');";
#       push @commands, $command;
#       $command = "UPDATE app_nbp SET app_nbp = '$remark' WHERE joinkey IN (SELECT joinkey FROM app_variation WHERE app_variation = '$allele');";
#       push @commands, $command;
      foreach my $joinkey (sort keys %joinkeys) {
        my ($pgnbp, $pgpaper, $pgperson) = ('', '', '');
        if ($paper{$joinkey})  { $pgpaper  = $paper{$joinkey}; }
        if ($person{$joinkey}) { $pgperson = $person{$joinkey}; }
        if ($nbp{$joinkey}) { $pgnbp = $nbp{$joinkey}; }
        next if ($pgpaper || $pgperson || ($pgnbp eq $remark));
        $command = "UPDATE app_nbp SET app_timestamp = CURRENT_TIMESTAMP WHERE joinkey = '$joinkey';";
        push @commands, $command;
        $command = "UPDATE app_nbp SET app_nbp = '$remark' WHERE joinkey = '$joinkey';";
        push @commands, $command;
        $command = "UPDATE app_filereaddate SET app_timestamp = CURRENT_TIMESTAMP WHERE joinkey = '$joinkey';";
        push @commands, $command;
        $command = "UPDATE app_filereaddate SET app_filereaddate = '$date' WHERE joinkey = '$joinkey';";
        push @commands, $command;
        $command = "UPDATE app_curator SET app_curator = 'WBPerson2970' WHERE joinkey = '$joinkey';";
        push @commands, $command;
        $command = "INSERT INTO app_filereaddate_hst VALUES ('$joinkey', '$date');";
        push @commands, $command;
        $command = "INSERT INTO app_curator_hst VALUES ('$joinkey', 'WBPerson2970');";
        push @commands, $command;
        $command = "INSERT INTO app_nbp_hst VALUES ('$joinkey', '$remark');";
        push @commands, $command; } }
    else {
      my $latest = 0;
      $result = $dbh->prepare( "SELECT joinkey FROM app_curator;" );
      $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
      while (my @row = $result->fetchrow) { if ($row[0] > $latest) { $latest = $row[0]; } }
#       $result = $dbh->prepare( "SELECT joinkey FROM app_type;" );
#       $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
#       while (my @row = $result->fetchrow) { if ($row[0] > $latest) { $latest = $row[0]; } }
      $latest++; 
#       my $command = "INSERT INTO app_type_hst VALUES ('$latest', 'Allele');";
#       push @commands, $command;
      my $command = "INSERT INTO app_variation_hst VALUES ('$latest', '$allele');";
      push @commands, $command;
      $command = "INSERT INTO app_nbp_hst VALUES ('$latest', '$remark');";
      push @commands, $command;
      $command = "INSERT INTO app_filereaddate_hst VALUES ('$latest', '$date');";
      push @commands, $command;
      $command = "INSERT INTO app_curator_hst VALUES ('$latest', 'WBPerson2970');";
      push @commands, $command;
#       $command = "INSERT INTO app_type VALUES ('$latest', 'Allele');";
#       push @commands, $command;
      $command = "INSERT INTO app_variation VALUES ('$latest', '$allele');";
      push @commands, $command;
      $command = "INSERT INTO app_nbp VALUES ('$latest', '$remark');";
      push @commands, $command;
      $command = "INSERT INTO app_filereaddate VALUES ('$latest', '$date');";
      push @commands, $command;
      $command = "INSERT INTO app_curator VALUES ('$latest', 'WBPerson2970');";
      push @commands, $command; }
  foreach my $command (@commands) {
    print "$command\n";
    my $result2 = $dbh->prepare( $command );
    $result2->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  } # foreach my $command (@commands)
} # sub check

__END__

