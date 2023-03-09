#!/usr/bin/perl

my $match_file = 'match_file';
my $phen_file = 'phenotype_count_WS183.csv';

my %hash;

$/ = "MATCH";
open (IN, "<$match_file") or die "Cannot open $match_file : $!";
while (my $group = <IN>) {
  my ($phen) = $group =~ m/\n(WBPhenotype\d{7}) /;
  $group =~ s/\s+MATCH\s*$//;
  $group =~ s/\n/<BR>/g;
  $group =~ s/Ê/ /g;
  $group =~ s/ +/ /g;
  $hash{$phen} = $group;
} # while (my $group = <IN>)
close (IN) or die "Cannot close $match_file : $!";

print "<HTML><BODY><TABLE border=2>\n";
$/ = "\n";
open (IN, "<$phen_file") or die "Cannot open $phen_file : $!";
<IN>;
while (my $line = <IN>) {
  chomp $line;
  my ($id, $an, $gene) = split/\t/, $line;
  print "<TR><TD>$id</TD><TD>$an</TD><TD>$gene</TD><TD>$hash{$id}</TD></TR>\n";
} # while (my $line = <IN>)
close (IN) or die "Cannot close $phen_file : $!";
print "</TABLE></BODY></HTML>\n";
