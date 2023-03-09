#!/usr/bin/perl

# not sure whether parent is contains or contained_by, so ran it both ways into
# each output file.  2007 03 15

use strict;
use diagnostics;
use Pg;

my %hash;
my %name;

my $infile = 'phenotype_2_GO_group_edited.txt';
$/ = "";
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $para = <IN>) {
  if ($para =~ m/\nWBPhenotype(\d+) (.*?)\n/) { 
    my $phen = $1; 
    my $name = $2; $name =~ s/^\s+//g; $name =~ s/\s+$//g;
    $name{phen}{$phen} = $name;
    if ($para =~ m/\nGO:(\d+) (.*?)\n/) { 
      my $go = $1;
      my $name = $2; $name =~ s/^\s+//g; $name =~ s/\s+$//g;
      $name{go}{$go} = $name;
      $hash{$phen} = $go; }
  }
} # while (my $line = <IN>)
close (IN) or die "Cannot close $infile : $!";
$/ = "\n";

# foreach my $phen (sort keys %hash) {
#   if ($hash{$phen} > 1) { print "$phen has $hash{$phen} mentions\n"; }
# } # foreach my $phen (sort keys %hash)

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my %phens;
my $result = $conn->exec( "SELECT alp_term FROM alp_term WHERE alp_term IS NOT NULL;" );
while (my @row = $result->fetchrow) {
  if ($row[0] =~ m/(\d+)/) { $phens{$1}++; } }

my %phen;
&readObo('full');
my %sort;

sub testPhen {
  my ($phen, $orig_phen) = @_;
  my $parent_found = 0;
  foreach my $parent ( sort keys %{ $phen{$phen}{contained_by} } ) {  
    if ($hash{$parent}) { 
      $parent_found++; 
#       print "$orig_phen has parent $parent with GO $hash{$parent}\n"; 
      my $go = $hash{$parent};
      my $line = "WBPhenotype$orig_phen ($phen{$orig_phen}{name})\tGO:$go ($name{go}{$go})\tWBPhenotype$parent ($name{phen}{$parent})\n"; 
      $sort{$orig_phen}{$line}++;
    }
#       else { print "No parent match for $phen parent $parent\n"; }
  } # foreach my $parent ( sort keys %{ $phen{$phen}{contained_by} } )
  unless ($parent_found) { 
    foreach my $parent ( sort keys %{ $phen{$phen}{contained_by} } ) {  
#       print "orig $orig_phen has parent $parent which failed\n";
      &testPhen($parent, $orig_phen); 
  } }
} # sub testPhen

foreach my $phen (sort keys %phens) {
#   print "P $phen P\n";
  &testPhen($phen, $phen);
} # foreach my $phen (sort keys %phens)

foreach my $phen (sort keys %phens) {
  if ($sort{$phen}) { 
      foreach my $line (sort keys %{ $sort{$phen} }) { print $line; } }
    else { print "WBPhenotype$phen ($phen{$phen}{name})\t\t\n"; }
} # foreach my $phen (sort keys %phens)

sub readObo {
  my ($slim_or_full) = shift;
  my $directory = '/home/azurebrd/work/parsings/carol/phenotype_go_20070314';
  my $dir = $directory . '/temp';
  chdir($dir) or die "Cannot go to $dir($!)";
  `cvs -d /var/lib/cvsroot checkout PhenOnt`;
  my $obo_file = $dir. '/PhenOnt/PhenOnt.obo';
  $/ = "";
  open (IN, "<$obo_file") or die "Cannot open $obo_file : $!";
  while (my $para = <IN>) {
    my $id = ''; my $name = ''; my $isa = '';
    if ($slim_or_full eq 'slim') { next unless ($para =~ m/subset: phenotype_slim_wb/); }
    next unless ($para =~ m/\[Term\]/);
    if ($para =~ m/\nid: WBPhenotype(\d+)/) { $id = $1; }
    if ($para =~ m/\nname: (\w+)/) { $name = $1; $phen{$id}{name} = $name; }
    if ($para =~ m/\nis_a: WBPhenotype(\d+)/) {
      my (@isa) = $para =~ m/\nis_a: WBPhenotype(\d+)/g;
#       foreach my $isa (@isa) { $phen{$isa}{contains}{$id}++; }	# not using this
      foreach my $isa (@isa) { $phen{$id}{contained_by}{$isa}++; } }
  } # while (my $para = <IN>)
  close (IN) or die "Cannot close $obo_file : $!";
  $/ = "\n";
  my $rm_directory = $directory . '/temp/PhenOnt';
  `rm -rf $rm_directory`;
  chdir($directory) or die "Cannot go to $directory($!)";       # go back to default directory
} # sub readObo

__END__

