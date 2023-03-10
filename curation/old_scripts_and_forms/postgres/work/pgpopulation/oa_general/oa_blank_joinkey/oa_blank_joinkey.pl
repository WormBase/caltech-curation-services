#!/usr/bin/perl -w

# bug in OA allowed dataTable entries without pgids, changing an entry would then create a postgres entry with a blank joinkey.
# this finds or deletes entries without joinkeys created by bug.  2011 04 04

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

use lib qw( /home/postgres/public_html/cgi-bin/oa );
use wormOA;                             # config-specific perl module for WormBase MOD

my %fields;                             # tied for order   $fields{app}{id} = 'text';

my @datatypes = qw( abp app gop grg int mop pic ptg trp );

foreach my $datatype (@datatypes) {
  my ($fieldsRef, $datatypesRef) = &initWormFields($datatype, 'two1823');
  %fields = %$fieldsRef;
  foreach my $field (sort keys %{ $fields{$datatype} }) {
    my $type = $fields{$datatype}{$field}{type};
    next if ($field eq 'id');
#     print "$datatype $field $type\n"; 
    my @tables = ();
    my $table = $datatype . '_' . $field;
    push @tables, $table;
# Deded to ignore history tables, because some of them have old-style objects (like variation names vs. WBVarIDs, or | separated objects instead of ",") and shouldn't have their format arbitrarily changed.
    $table = $datatype . '_' . $field . '_hst';
    push @tables, $table;
    foreach my $table (@tables) {
      my $pgquery = "SELECT * FROM $table WHERE joinkey IS NULL OR joinkey = ''";
#       print "$pgquery\n";
      my $result = $dbh->prepare( $pgquery );
      $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
      while (my @row = $result->fetchrow) {
# FIND entries without joinkey
        print "$table\t@row\n";
      }
      $pgquery = "DELETE FROM $table WHERE joinkey IS NULL OR joinkey = ''";
# DELETE entries without joinkey
#       print "$pgquery\n";
# UNCOMMENT TO DELETE entries with blank joinkeys
#       my $result = $dbh->do( $pgquery );
    }
  }
}





__END__

