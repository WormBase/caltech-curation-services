#!/usr/bin/perl -w

# move data from old obo_<tabletype>_<threetype>_<obotable> to new obo_<tabletype>_<ontologytype>  2011 02 22
#
# populated tazendra data, but rearrangement / variation / picturesource have other source of population.  2011 02 23

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

# app_rearrangement  app_variation  int_sentid  pic_exprpattern  trp_clone  trp_location   pic_picturesource

my %hash;
$hash{app_rearrangement} = 'rearrangement';
$hash{app_variation} = 'variation';
$hash{int_sentid} = 'intsentid';
$hash{pic_exprpattern} = 'exprpattern';
$hash{trp_clone} = 'clone';
$hash{trp_location} = 'laboratory';
$hash{pic_picturesource} = 'picturesource';

my @tables = qw( name syn data );
foreach my $table_type (@tables) {
  foreach my $old_table (sort keys %hash) {
    my $new_table = 'obo_' . $table_type . '_' . $hash{$old_table};
    my $result2 = $dbh->do( "DELETE FROM $new_table" );
    my $table = 'obo_' . $table_type . '_' . $old_table;
    $result2 = $dbh->do( "COPY $table TO '/home/postgres/tempdata.pg';" );
    $result2 = $dbh->do( "COPY $new_table FROM '/home/postgres/tempdata.pg';" );
    
#     my $result = $dbh->prepare( "SELECT * FROM $table" );
#     $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
#     while (my @row = $result->fetchrow) {
#       foreach (@row) { $_ =~ s/\'/''/g; }
#       my $values = join"', '", @row;
#       my $result2 = $dbh->do( "INSERT INTO $new_table VALUES ('$values')" );
# #       print "INSERT INTO $new_table VALUES ('$values')\n";
#     }
  }
}


__END__

