#!/usr/bin/perl -w

# look at all data that the first pass form would return as not-found (based on
# cur_curator) and set all values in the form to NULL (as opposed to nothing
# being there for that joinkey, which would lead to postgres not updating)
# 2006 10 02

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my @tables = qw( cur_ablationdata cur_antibody cur_associationequiv cur_associationnew cur_cellfunction cur_cellname cur_comment cur_covalent cur_curator cur_expression cur_extractedallelename cur_extractedallelenew cur_fullauthorname cur_functionalcomplementation cur_genefunction cur_geneinteractions cur_geneproduct cur_generegulation cur_genesymbol cur_genesymbols cur_goodphoto cur_invitro cur_lsrnai cur_mappingdata cur_microarray cur_mosaic cur_newmutant cur_newsnp cur_newsymbol cur_overexpression cur_rnai cur_sequencechange cur_sequencefeatures cur_site cur_stlouissnp cur_structurecorrection cur_structurecorrectionsanger cur_structurecorrectionstlouis cur_structureinformation cur_supplemental cur_synonym cur_transgene );


my %wpas;
my $result = $conn->exec( "SELECT * FROM cur_curator WHERE joinkey ~ '^000'" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $wpas{$row[0]}++; 
  } # if ($row[0])
} # while (@row = $result->fetchrow)

foreach my $wpa ( sort keys %wpas ) {
  foreach my $table ( @tables ) {
    my $result = $conn->exec( "SELECT * FROM $table WHERE joinkey = '$wpa';" );
    my @row = $result->fetchrow;
    unless ($row[0]) { 
      my $command = "INSERT INTO $table VALUES ('$wpa', NULL, CURRENT_TIMESTAMP);";
# UNCOMMENT THIS TO MAKE IT DO SOMETHING
#       my $result2 = $conn->exec( "$command" );
      print "$command\n";
    }
  } # foreach my $table ( @tables )
} # foreach my $wpa ( sort keys %wpas )

__END__

