#!/usr/bin/perl

# Test querying acedb for genes and variations to get what we would normally get from 
# the aceserver.  2013 07 12



use Ace;
use strict;
use diagnostics;
use Jex;
use DBI;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n";


my $directory = '/home2/acedb/cron/';
chdir($directory) or die "Cannot go to $directory ($!)";

my $count_value = 0;
if ($ARGV[0]) { $count_value = $ARGV[0]; }

my $start = &getSimpleSecDate();

# use constant HOST => $ENV{ACEDB_HOST} || 'aceserver.cshl.org';
# use constant PORT => $ENV{ACEDB_PORT} || 2005;
# my $db = Ace->connect(-host=>HOST,-port=>PORT) or warn "Connection failure: ",Ace->error;

my $database_path = "/home3/acedb/ws/acedb";	# full path to local AceDB database; change as appropriate
my $program = "/home/acedb/bin/tace";		# full path to tace; change as appropriate
# my $program = "/bin/tace";		# full path to tace; change as appropriate
my $db = Ace->connect(-path => $database_path,  -program => $program) || die print "Connection failure: ", Ace->error;	# local database



my %hash;

my $genefile = 'nameserverGenes.txt';
open (OUT, ">$genefile") or die "Cannot create $genefile : $!";

my $query="find Gene WBGene00000*";
my @genes=$db->fetch(-query=>$query);
my @tags = qw( CGC_name Public_name Other_name Status );

foreach my $object (@genes) {
  my ($geneid) = $object =~ m/(\d+)/;
  foreach my $tag (@tags) {
    my @b = $object->$tag;
    foreach my $b (@b) { 
      $hash{$geneid}{$tag}{$b}++; } }
} # foreach my $object (@genes)

foreach my $geneid (sort keys %hash) {
  my @array = ("WBGene$geneid");
  foreach my $tag (@tags) {
    my $value = '';
    if ($hash{$geneid}{$tag}) { $value = join"|", keys %{ $hash{$geneid}{$tag} }; }
    push @array, $value; 
  }
  my $line = join"\t", @array;
  print OUT qq($line\n);
} # foreach my $geneid (sort keys %hash)
close (OUT, ">$genefile") or die "Cannot close $genefile : $!";


%hash = ();
$query="find Variation WBVar00000*";
my @vars=$db->fetch(-query=>$query);
@tags = qw( Public_name Status );

my $varfile = 'nameserverVars.txt';
open (OUT, ">$varfile") or die "Cannot create $varfile : $!";

foreach my $object (@vars) {
  my ($varid) = $object =~ m/(\d+)/;
  foreach my $tag (@tags) {
    my @b = $object->$tag;
    foreach my $b (@b) { 
      $hash{$varid}{$tag}{$b}++; } }
} # foreach my $object (@vars)

foreach my $varid (sort keys %hash) {
  my @array = ("WBVar$varid");
  foreach my $tag (@tags) {
    my $value = '';
    if ($hash{$varid}{$tag}) { $value = join"|", keys %{ $hash{$varid}{$tag} }; }
    push @array, $value; 
  }
  my $line = join"\t", @array;
  print qq($line\n);
} # foreach my $varid (sort keys %hash)

close (OUT, ">$varfile") or die "Cannot close $varfile : $!";

