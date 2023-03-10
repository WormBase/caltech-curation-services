#!/usr/bin/perl -w

# backup Andrei's cur_ tables to make way for new svmdata + curator data  2012 07 09

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my $dir = '/home/postgres/work/pgpopulation/cur_curation/backup_of_2009_tables/';

my @cur_tables = qw( cur_ablationdata cur_expression cur_genesymbols cur_newmutant cur_structurecorrection cur_antibody cur_extractedallelename cur_goodphoto cur_newsnp cur_structurecorrectionsanger cur_associationequiv cur_extractedallelenew cur_humandiseases cur_newsymbol cur_structurecorrectionstlouis cur_associationnew cur_fullauthorname cur_invitro cur_nonntwo cur_structureinformation cur_cellfunction cur_functionalcomplementation cur_lsrnai cur_overexpression cur_supplemental cur_cellname cur_genefunction cur_mappingdata cur_rnai cur_synonym cur_chemicals cur_geneinteractions cur_marker cur_sequencechange cur_transgene cur_comment cur_geneproduct cur_massspec cur_sequencefeatures cur_covalent cur_generegulation cur_microarray cur_site cur_curator cur_genesymbol cur_mosaic cur_stlouissnp );

foreach my $table (@cur_tables) {
  my $outfile = $dir . $table;
  my $result = $dbh->do( "COPY $table TO '$outfile'" );
} # foreach my $table (@cur_tables)

__END__

testdb=# \d cur_ablationdata;
                                 Table "public.cur_ablationdata"
      Column      |           Type           |                     Modifiers                      
------------------+--------------------------+----------------------------------------------------
 joinkey          | text                     | 
 cur_ablationdata | text                     | 
 cur_timestamp    | timestamp with time zone | default ('now'::text)::timestamp without time zone
Indexes:
    "cur_ablationdata_idx" UNIQUE, btree (joinkey)

testdb=# \d cur_comment
                                  Table "public.cur_comment"
    Column     |           Type           |                     Modifiers                      
---------------+--------------------------+----------------------------------------------------
 joinkey       | text                     | 
 cur_comment   | text                     | 
 cur_timestamp | timestamp with time zone | default ('now'::text)::timestamp without time zone
Indexes:
    "cur_comment_idx" UNIQUE, btree (joinkey)

testdb=# \d cur_curator
                                  Table "public.cur_curator"
    Column     |           Type           |                     Modifiers                      
---------------+--------------------------+----------------------------------------------------
 joinkey       | text                     | 
 cur_curator   | text                     | 
 cur_timestamp | timestamp with time zone | default ('now'::text)::timestamp without time zone
Indexes:
    "cur_curator_idx" btree (joinkey)

