#!/usr/bin/perl -w

# backup tables that will have data change.  2012 05 18

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my $dir = '/home/postgres/work/pgpopulation/transgene/20120517_underscore_ExIs/backup/';

my @pgtables = qw( app_transgene app_rescuedby exp_transgene grg_transgene int_transgeneone int_transgenetwo app_transgene_hst app_rescuedby_hst exp_transgene_hst grg_transgene_hst int_transgeneone_hst int_transgenetwo_hst trp_name trp_name_hst trp_synonym trp_synonym_hst );
foreach my $pgtable (@pgtables) {
  my $file = $dir . $pgtable . '.pg';
#   $result = $dbh->do( "COPY $pgtable TO '$file'" );  	# TO BACKUP
  # UNCOMMENT TO RECOVER
#   $result = $dbh->do( "DELETE FROM $pgtable" );     	# TO RECOVER
#   $result = $dbh->do( "COPY $pgtable FROM '$file'" );	# TO RECOVER
} # foreach my $pgtable (@pgtables)

