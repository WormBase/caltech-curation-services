#!/usr/bin/perl -w
#
# ASCII graphical representation of lineage

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my %name;
my %parent;
my %hash;

my $result = $conn->exec( "SELECT * FROM two_standardname;" );
while (my @row = $result->fetchrow) {
  $row[0] =~ s/two//;
  $name{$row[0]} = $row[2];
} # while (my @row = $result->fetchrow)

$result = $conn->exec ( "SELECT * FROM two_lineage WHERE two_role ~ 'with'; ");
while (my @row = $result->fetchrow) {
  push @{ $parent{$row[2]} }, $row[0];		# key trained value
  if ($row[2] eq 'two1157') { print STDERR "PARENT 1157 $row[0]\n"; }
#   print "PARENT $row[2]\tCHILD $row[0]\n";
} # while (my @row = $result->fetchrow)

my $first = 'two77';
# &recurse($first, $line);

sub testThing {
  foreach (@{ $parent{two1157}}) { print STDERR "TEST\t$_\n"; }
}

foreach my $child ( @{ $parent{$first} }) {
  if ( $parent{$child} ) {
  foreach my $k3 ( @{ $parent{$child} } ) { 
#       push @{ $hash{$first}{$child} }, $k3; 
#       $hash{$first}{$child}{$k3}++; 
    if ($parent{$k3}) {
    foreach my $k4 ( @{ $parent{$k3} } ) { 
print STDERR "LOOP $child $k3 $k4\n";
if ($child eq 'two1157') { print STDERR "1157\t$k3\t$k4\n"; }
#       &testThing();
      push @{ $hash{$first}{$child}{$k3} }, $k4; 
    } }
  }
  } # if ( $parent{$child} )
} # foreach my $child ( @{ $parent{$first} })

foreach my $k1 (sort keys %hash) {
  foreach my $k2 (sort keys %{ $hash{$k1} } ) {
    foreach my $k3 (sort keys %{ $hash{$k1}{$k2} } ) {
      foreach my $k4 (@{ $hash{$k1}{$k2}{$k3} } ) {
        print "$k1\t$k2\t$k3\t$k4\n";
      } # foreach my $k4 (@{ $hash{$k1}{$k2}{$k3} } )
    } # foreach my $k3 (sort keys %{ $hash{$k1}{$k2} } )
  } # foreach my $k2 (sort keys %{ $hash{$k1} } )
} # foreach my $key (sort keys %hash)

# foreach my $child ( @{ $parent{$first} }) {
#   my $line = "two77\t$child";
#   &recurse($child, $line);
# #   print "$line\n";
# } # foreach my $child ( @{ $parent{$first} })
# 
# sub recurse {
#   my ($first, $line) = @_;
#   unless ( $parent{$first} ) { print "$line\n"; return; }
#   foreach my $child (@{ $parent{$first} }) {
#     $line .= "\t$child";
#     &recurse($child, $line);
#   } # foreach my $child (@parent{$first})
# #   print "$line\n";
# } 

