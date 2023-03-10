#!/usr/bin/perl -w

# Look at dead genes from gin_dead in pap_gene, and make all mention of them invalid in wpa_gene 
# Then repopulate pap_gene separately through /home/postgres/work/pgpopulation/pap_papers/create_table.pl

# I'm not sure why this took 3 takes.  Between the 2nd and 3rd, it was the 2nd making connections to yet more dead genes.  
# Not sure about the first and second.  Possibly some were new entries, but I don't think that account for all those 
# entries in the second batch.  2010 04 14

use strict;
use diagnostics;
use DBI;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my %pgcommands;

my $result = $dbh->prepare( "SELECT gin_dead.gin_dead, pap_gene.joinkey, pap_gene.pap_gene, pap_gene.pap_evidence, pap_gene.pap_curator FROM pap_gene, gin_dead WHERE pap_gene.pap_gene = gin_dead.joinkey;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  my ($merge_to, $joinkey, $wbgeneid, $evi, $curator_id) = @row;
  my $new_gene = '';
  if ($merge_to =~ m/WBGene(\d+)/) { $new_gene = $1; }
  my %hash;
  my $result2 = $dbh->prepare( "SELECT * FROM wpa_gene WHERE joinkey = '$joinkey' AND wpa_gene ~ '$wbgeneid'");
  $result2->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row2 = $result2->fetchrow) {
    my $evi = ''; if ($row2[2]) { $evi = $row2[2]; }
    if ($row2[3] eq 'valid') { $hash{$row2[0]}{$row2[1]}{$evi}++; }
      else { delete $hash{$row2[0]}{$row2[1]}{$evi}; } }
  foreach my $gene_data (sort keys %{ $hash{$joinkey} }) {
    foreach my $evi (sort keys %{ $hash{$joinkey}{$gene_data} }) {
      if ($evi) { $evi = "'$evi'"; } else { $evi = 'NULL'; }
      my $command = "INSERT INTO wpa_gene VALUES ('$joinkey', '$gene_data', $evi, 'invalid', 'two1843', CURRENT_TIMESTAMP);";
      $pgcommands{$command}++;
      if ($new_gene) {
        $command = "INSERT INTO wpa_gene VALUES ('$joinkey', 'WBGene$new_gene', 'Inferred_automatically\t\"fix_dead_genes.pl\"', 'valid', 'two1843', CURRENT_TIMESTAMP);";
        $pgcommands{$command}++; }
    } # foreach my $evi (sort keys %{ $hash{$joinkey}{$gene_data} })
  } # foreach my $gene_data (sort keys %{ $hash{$joinkey} })
} # while (@row = $result->fetchrow)

foreach my $pgcommand (keys %pgcommands) {
  print "$pgcommand\n";
  my $result3 = $dbh->do( $pgcommand );
} # foreach my $pgcommand (keys %pgcommands)

__END__

my $result = $dbh->prepare( 'SELECT * FROM two_comment WHERE two_comment ~ ?' );
$result->execute('elegans') or die "Cannot prepare statement: $DBI::errstr\n"; 

$result->execute("doesn't") or die "Cannot prepare statement: $DBI::errstr\n"; 
my $var = "doesn't";
$result->execute($var) or die "Cannot prepare statement: $DBI::errstr\n"; 

my $result = $dbh->do( "DELETE FROM friend WHERE firstname = 'bl\"ah'" );
(also do for INSERT and UPDATE if don't have a variable to interpolate with ? )

can cache prepared SELECTs with $dbh->prepare_cached( &c. );

if ($result->rows == 0) { print "No names matched.\n\n"; }	# test if no return

$result->finish;	# allow reinitializing of statement handle (done with query)
$dbh->disconnect;	# disconnect from DB

http://209.85.173.132/search?q=cache:5CFTbTlhBGMJ:www.perl.com/pub/1999/10/DBI.html+dbi+prepare+execute&cd=4&hl=en&ct=clnk&gl=us

interval stuff : 
SELECT * FROM afp_passwd WHERE joinkey NOT IN (SELECT joinkey FROM afp_lasttouched) AND joinkey NOT IN (SELECT joinkey FROM cfp_curator) AND afp_timestamp < CURRENT_TIMESTAMP - interval '21 days' AND afp_timestamp > CURRENT_TIMESTAMP - interval '28 days';

casting stuff to substring on other types :
SELECT * FROM afp_passwd WHERE CAST (afp_timestamp AS TEXT) ~ '2009-05-14';
