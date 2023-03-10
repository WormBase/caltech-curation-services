#!/usr/bin/perl -w

# Create obo_{name|syn|data}_taxon tables in postgres.  2011 09 26


use strict;
use diagnostics;
use DBI;
use LWP::Simple;
use LWP;


my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

# need a directory to store previous results so a cronjob only updates tables when the data is new
my $directory = '/home/postgres/public_html/cgi-bin/oa/scripts/obo_oa_ontologies/';
chdir ($directory) or die "Cannot chdir to $directory : $!";


# put postgres users that should have 'all' access to the table.
my @users_all = ('apache', 'azurebrd', 'cecilia', '"www-data"', 'acedb');

# put postgres users that should have 'select' access to the table.  mainly so they can log on and see the data from a shell, but would probably work if you set the webserver to have select access, it would just give error messages if someone tried to update data.
my @users_select = ('acedb');


# enter obotable - URL hash entries here
my %obos;
$obos{taxon} = '/home/acedb/karen/processOA/wbspecies.txt';


# uncomment and run only once for each obotable to create the related tables 
foreach my $obotable (sort keys %obos) { &createTable($obotable); }


sub createTable {							# create postgres tables for a given obotable
  my ($obotable) = @_;
  my @tables = qw( name syn data );
  foreach my $table_type (@tables) {
    my $table = 'obo_' . $table_type . '_' . $obotable;
    $result = $dbh->do("DROP TABLE $table; ");
    $result = $dbh->do( "CREATE TABLE $table ( joinkey text, $table text, obo_timestamp timestamp with time zone DEFAULT \"timestamp\"('now'::text) );" );
    $result = $dbh->do( "CREATE INDEX ${table}_idx ON $table USING btree (joinkey);" );
    $result = $dbh->do("REVOKE ALL ON TABLE $table FROM PUBLIC; ");
#     foreach my $user (@users_select) {
#       $result = $dbh->do( "GRANT SELECT ON TABLE $table TO $user; "); }
    foreach my $user (@users_all) {
      $result = $dbh->do( "GRANT ALL ON TABLE $table TO $user; "); }
  } # foreach my $table_type (@tables)
} # sub createTable


__END__


=head1 NAME

update_obo_oa_ontologies.pl - script to create, populate, or update postgres tables for ontology annotator obotables.


=head1 SYNOPSIS

Edit the array of users to grant permission to (both 'select' and 'all'), edit obotable to URL hash entries in %obos hash, add optional code for specific obotable types, then run with

  ./update_obo_oa_ontologies.pl


=head1 DESCRIPTION

The ontology_annotator.cgi allows .obo files to be generically parsed into postgres tables for obotables used in fields of type 'ontology' or 'multiontology'.

.obo data changes routinely, so this script can run on a cronjob to update data when the obo files's 'date:' line has changed.


=head2 SCRIPT REQUIREMENTS

Create a directory to store the last version of each obo file.  Change the path to it in the $directory variable.

Edit array of postgres database users to grant permission to (both 'select' and 'all').

Edit %obos hash for mappings of obotable to URL of .obo file.


=head2 CREATE TABLES

If creating an obotable type for the first time:

=over 4 

=item * comment out all %obos entries that already have tables.

=item * uncomment the lines to  &createTable  for the datatype .

=item * run with

  ./update_obo_oa_ontologies.pl

=item * put the script back the way it was.

=back


=head2 TERM INFO OBO TREE BROWSING

The script can be edited to add custom changes for specific obotables, such as parsing names, IDs, adding URL links in term information, creating obo tree links to browse the term info obo structure.  

When creating obo tree links to browse the term info obo structure:

=over 4 

=item * add conditional to populate %children and change the ID matching.

=item * add conditional to process each term and change the ID matching.

=back

%children are populated by matching on 'is_a:' and 'relationship: part_of' tags in .obo file


=head2 SCRIPT FUNCTION

For each obotable .obo file compare date of downloaded .obo file with date of last .obo file used to populate postgres tables ;  if the date is more recent, delete all data from tables, populate from new file, and write file to flatfile for future comparison.

The downloaded data file is split on '[Term]'.  Id is a match on 'id: ' to the newline.  Name is a match on 'name: ' to the newline.  Synonyms are matches on 'synonym: "<match>"'.  Data is the whole entry.  Data lines are split, for each line the tag is anything up to the first colon, and it has a span html element tag added to bold it.  There is a single entry for a given term id for name and data, but there can be multiple entries for synonyms, one for each synonym.


