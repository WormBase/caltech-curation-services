#!/usr/bin/perl -w

# update tfp_extvariation based on textpresso data for Jolene.  2009 05 04
#
# wrapped in 
# 0 4 * * * /home/postgres/work/pgpopulation/textpresso/wrapper.sh



use strict;
use diagnostics;
use DBI;
use LWP::Simple;
use Jex;

my $date = &getSimpleDate();
my $timestamp = &getSimpleSecDate();


my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

# my $result = $dbh->prepare( 'SELECT * FROM two_comment WHERE two_comment ~ ?' );
# $result->execute('elegans') or die "Cannot prepare statement: $DBI::errstr\n"; 

my $result;

my $directory = '/home/postgres/work/pgpopulation/textpresso/extvariation';
chdir($directory) or die "Cannot go to $directory ($!)";


$/ = undef;
my $full_file = 'extvariation_textpresso';
open (IN, "<$full_file") or die "Cannot open $full_file : $!";
my $last_data = <IN>;
close (IN) or die "Cannot close $full_file : $!";

my $new_data = get "http://textpresso-dev.caltech.edu/Alleles/alleles.html";
exit if ($last_data eq $new_data);

my $logfile = $directory . '/logfile.pg';
open (LOG, ">$logfile") or die "Cannot rewrite $logfile : $!";

open (OUT, ">$full_file") or die "Cannot rewrite $full_file : $!";
print OUT $new_data;
close (OUT) or die "Cannot close $full_file : $!";

my (@tlines) = split/WBPaper/, $new_data;
my @pgcommands;

my %hash;
push @pgcommands, "DELETE FROM tfp_extvariation;";
foreach my $line (@tlines) {
  my ($joinkey) = $line =~ m/^(\d+(?:\.sup\.\d+)?)/;
  next unless ($joinkey); 
  my (@red) = $line =~ m/<font size=\"3\" color=\"red\">(.*?)<\/font>/g;
  my (@magenta) = $line =~ m/<font size=\"3\" color=\"magenta\">(.*?)<\/font>/g;
  foreach (@red) { $_ =~ s/\(.*\)//g; }
  foreach (@magenta) { $_ =~ s/\(.*\)//g; }
  my $true = join" ", @red;
  my $maybe = join" ", @magenta;
  my $data = '';
  if ($true) { $data .= "WBPaper$joinkey  true  $true"; }
  if ($maybe) { 
    if ($data) { $data .= "\n"; }
    $data .= "WBPaper$joinkey  maybe  $maybe"; }
  ($joinkey) = $joinkey =~ m/(\d{8})/;
  my ($num_joinkey) = $joinkey; $num_joinkey =~ s/^0+//;
  next if ($num_joinkey < 31470);
  if ($data) { 
    if ($hash{$joinkey}) { $hash{$joinkey} .= "\n"; }
    $hash{$joinkey} .= $data;
#     print $data; 
  }
} # foreach my $line (@tlines)

foreach my $joinkey (sort keys %hash) {
  my $data = $hash{$joinkey};
  push @pgcommands, "INSERT INTO tfp_extvariation VALUES ('$joinkey', '$data');";
} # foreach my $joinkey (sort keys %hash)

foreach my $command (@pgcommands) {
  print LOG "$command\n";
  $result = $dbh->do( $command );
} # foreach my $command (@pgcommands)


close (LOG) or die "Cannot close $logfile : $!";

