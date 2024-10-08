#!/usr/bin/perl -w

# populate pap_species from flatfiles generated by  populate_pap_species_from_abstract_species.pl  and  populate_pap_species_from_gene_species.pl
# 2016 05 19

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %pg;
my %pgOrder;
my %files;
$result = $dbh->prepare( "SELECT * FROM pap_species" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $pg{$row[0]}{$row[1]}++; 
    my $highest = $pgOrder{$row[0]} || 0;
    if ($row[2] > $highest) { $pgOrder{$row[0]} = $row[2]; }
} }

my @files = qw( abstract_species.out gene_species.out );
foreach my $file (@files) {
  open (IN, "<$file") or die "Cannot open $file : $!";
  while (my $line = <IN>) {
    chomp $line;
    my ($joinkey, $species, $taxon, @junk) = split/\t/, $line;
    next unless ($joinkey);	# some have abstract split in multiple lines 
#     if ($pg{$joinkey}) { 
#       my $pgdata = join", ", sort keys %{ $pg{$joinkey} };
#       print qq($joinkey has data in postgres $pgdata and in file $file $taxon\n); }
    next unless $taxon;
    my (@taxons) = split/, /, $taxon;
    foreach my $taxon (@taxons) { 
      next unless ($taxon =~ m/^\d+$/);
      $files{$joinkey}{$taxon}++; }
  } # while (my $line = <IN>)
  close (IN) or die "Cannot close $file : $!";
} # foreach my $file (@files)

my @pgcommands;
foreach my $joinkey (sort keys %files) {
  foreach my $taxon (sort keys %{ $files{$joinkey} }) {
    next if ($pg{$joinkey}{$taxon});
    if ($pgOrder{$joinkey}) { $pgOrder{$joinkey}++; } else { $pgOrder{$joinkey} = 1; }
    print qq(new\t$joinkey\t$pgOrder{$joinkey}\t$taxon\n);
    push @pgcommands, qq(INSERT INTO   pap_species VALUES ('$joinkey', '$taxon', '$pgOrder{$joinkey}', 'two1843'););
    push @pgcommands, qq(INSERT INTO h_pap_species VALUES ('$joinkey', '$taxon', '$pgOrder{$joinkey}', 'two1843'););
  } # foreach my $taxon (sort keys %{ $files{$joinkey} })
} # foreach my $joinkey (sort keys %files)

foreach my $joinkey (sort keys %pg) {
  foreach my $taxon (sort keys %{ $pg{$joinkey} }) {
    next if ($files{$joinkey}{$taxon});
    print qq(already in postgres, not in files\t$joinkey\t$taxon\n);
  } # foreach my $taxon (sort keys %{ $pg{$joinkey} })
} # foreach my $joinkey (sort keys %pg)

foreach my $pgcommand (@pgcommands) {
  print qq($pgcommand\n);
# UNCOMMENT TO POPULATE
#   $dbh->do($pgcommand);
} # foreach my $pgcommand (@pgcommands)
