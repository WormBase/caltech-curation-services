#!/usr/bin/perl -w
#
# Get all joinkeys from all cur_tables, then add entries to cur_tables with NULL
# values if the numbers (joinkeys) for those cur_tables don't match that for all
# cur_tables.  Then check again that all numbers match.  2003 10 02

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $outfile = "outfile";
open(OUT, ">$outfile") or die "Cannot create $outfile : $!";

my %all_keys;		# all cur_tables joinkeys

my @PGparameters = qw(curator fullauthorname
                      genesymbol mappingdata genefunction
                      expression microarray rnai transgene overexpression
                      structureinformation functionalcomplementation
                      invitro mosaic site antibody covalent
                      extractedallelenew newmutant
                      sequencechange geneinteractions geneproduct
                      structurecorrectionsanger structurecorrectionstlouis
                      sequencefeatures cellname cellfunction ablationdata
                      newsnp stlouissnp goodphoto comment);        # vals for %theHash

foreach my $cur_table (@PGparameters) {
  my $result = $conn->exec( "SELECT joinkey FROM cur_$cur_table;");
  while (my @row = $result->fetchrow) {
    if ($row[0]) { 
      $row[0] =~ s///g;
      $all_keys{$row[0]}++;
#       my $locus = $row[0];
#       my $result2 = $conn->exec( "INSERT INTO got_provisional VALUES ('$locus', NULL);");
#       $result2 = $conn->exec( "INSERT INTO got_pro_paper_evidence VALUES ('$locus', NULL);");
    } # if ($row[0])
  } # while (@row = $result->fetchrow)
} # foreach my $cur_table (@PGparameters)

my $max_num = scalar keys (%all_keys);

print scalar keys (%all_keys) . "\n";


foreach my $cur_table (@PGparameters) {
  my %temp_hash = %all_keys;
  my $result = $conn->exec( "SELECT joinkey FROM cur_$cur_table;");
  while (my @row = $result->fetchrow) {
    if ($row[0]) { 
      $row[0] =~ s///g;
      delete $temp_hash{$row[0]};
    } # if ($row[0])
  } # while (@row = $result->fetchrow)
  foreach my $key (sort keys %temp_hash) {
#     print "$cur_table\t$key\n";
    $result = $conn->exec( "INSERT INTO cur_$cur_table VALUES ('$key', NULL);");
  } # foreach my $key (sort keys %temp_hash)
  $result = $conn->exec( "SELECT COUNT(*) FROM cur_$cur_table;" );
  my @row = $result->fetchrow;
  if ($row[0] != $max_num) { print "$cur_table $row[0]\n"; }
} # foreach my $cur_table (@PGparameters)



close (OUT) or die "Cannot close $outfile : $!";
