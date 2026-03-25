#!/usr/bin/env perl

# there are afp tables with cfp columns, find out what data is there and compare it to the cfp equivalent
# there are 111 afp entries rejected by a curator, we'll ignore these
# there are 1368 entried in afp_ that don't have an entry in cfp_  this script will populate those in cfp_
# with the afp_curator and afp_cur_timestamp, so this will be hard to undo.
# ran on prod   2026 03 25


use strict;
use diagnostics;
use DBI;
use Dotenv -load => '/usr/lib/.env';

my $dbh = DBI->connect ( "dbi:Pg:dbname=$ENV{PSQL_DATABASE};host=$ENV{PSQL_HOST};port=$ENV{PSQL_PORT}", "$ENV{PSQL_USERNAME}", "$ENV{PSQL_PASSWORD}") or die "Cannot connect to database!\n";
# my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my $result;

# probable tables, not used
# my @tables = qw( ablationdata antibody catalyticact celegans cellfunc chemicals chemphen cnonbristol comment covalent domanal envpheno expression extvariation funccomp genefunc geneint geneprod genereg genestudied genesymbol humdis invitro lsrnai mappingdata marker massspec matrices microarray mosaic nematode newmutant newsnp nocuratable nonnematode otherantibody otherexpr othersilico otherstrain othertransgene othervariation overexpr phylogenetic rnai rnaseq seqchange seqfeat siteaction species strain structcorr structinfo supplemental timeaction transgene variation version );



# --------------------------
# 1) AFP tables (filtered)
# --------------------------
my %afp_tables;

my $afp_sth = $dbh->prepare(q{
    SELECT table_name
    FROM information_schema.tables t
    WHERE t.table_schema = 'public'
      AND t.table_name LIKE 'afp_%'
      AND t.table_name NOT LIKE '%_hst'
      AND t.table_name NOT LIKE '%_idx'
      AND EXISTS (
          SELECT 1
          FROM information_schema.columns c
          WHERE c.table_schema = 'public'
            AND c.table_name = t.table_name
            AND c.column_name = 'afp_curator'
      )
});
$afp_sth->execute();

while (my ($table) = $afp_sth->fetchrow_array) {
    (my $base = $table) =~ s/^afp_//;
    $afp_tables{$base} = 1;
}

# --------------------------
# 2) CFP tables
# --------------------------
my %cfp_tables;

my $cfp_sth = $dbh->prepare(q{
    SELECT table_name
    FROM information_schema.tables
    WHERE table_schema = 'public'
      AND table_name LIKE 'cfp_%'
      AND table_name NOT LIKE '%_hst'
      AND table_name NOT LIKE '%_idx'
});
$cfp_sth->execute();

while (my ($table) = $cfp_sth->fetchrow_array) {
    (my $base = $table) =~ s/^cfp_//;
    $cfp_tables{$base} = 1;
}

# --------------------------
# 3) Compare sets
# --------------------------
my (@only_afp, @only_cfp, @both);

# AFP side
foreach my $base (keys %afp_tables) {
    if ($cfp_tables{$base}) {
        push @both, $base;
    } else {
        push @only_afp, $base;
    }
}

# CFP-only
foreach my $base (keys %cfp_tables) {
    unless ($afp_tables{$base}) {
        push @only_cfp, $base;
    }
}

# --------------------------
# 4) Output
# --------------------------
# print "\n=== In BOTH ===\n";
# print join("\n", sort @both), "\n";
# 
# print "\n=== Only AFP ===\n";
# print join("\n", sort @only_afp), "\n";
# 
# print "\n=== Only CFP ===\n";
# print join("\n", sort @only_cfp), "\n";

# Data hashes
my (%cfp_data, %afp_data);

foreach my $base (@both) {

    my $afp_table = "afp_$base";
    my $cfp_table = "cfp_$base";

    # --------------------------
    # 1) Query CFP table
    # --------------------------
    my $cfp_col_sth = $dbh->prepare("SELECT column_name FROM information_schema.columns WHERE table_name = ? AND table_schema = 'public'");
    $cfp_col_sth->execute($cfp_table);
    my @cfp_cols = map { $_->[0] } @{ $cfp_col_sth->fetchall_arrayref };
    my ($cfp_value_col) = grep { /^cfp_/ } @cfp_cols;

    my $cfp_sth = $dbh->prepare("SELECT joinkey, $cfp_value_col FROM $cfp_table");
    $cfp_sth->execute();

    while (my $row = $cfp_sth->fetchrow_hashref) {
        $cfp_data{$base}{$row->{joinkey}} = $row->{$cfp_value_col};
    }

    # --------------------------
    # 2) Query AFP table
    # --------------------------
    my $afp_col_sth = $dbh->prepare("SELECT column_name FROM information_schema.columns WHERE table_name = ? AND table_schema = 'public'");
    $afp_col_sth->execute($afp_table);
    my @afp_cols = map { $_->[0] } @{ $afp_col_sth->fetchall_arrayref };
    my ($afp_value_col) = grep { /^afp_/ && $_ ne 'afp_curator' && $_ ne 'afp_approve' && $_ ne 'afp_cur_timestamp' } @afp_cols;

    print qq(SELECT joinkey, $afp_value_col, afp_curator, afp_approve, afp_cur_timestamp FROM $afp_table\n);
    my $afp_sth = $dbh->prepare("SELECT joinkey, $afp_value_col, afp_curator, afp_approve, afp_cur_timestamp FROM $afp_table");
    $afp_sth->execute();

    while (my $row = $afp_sth->fetchrow_hashref) {
        $afp_data{$base}{$row->{joinkey}} = {
            value     => $row->{$afp_value_col},
            curator   => $row->{afp_curator},
            approve   => $row->{afp_approve},
            timestamp => $row->{afp_cur_timestamp},
        };
    }
}

# --------------------------
# 3) Compare and output
# --------------------------

my @pgcommands;

foreach my $base (@both) {
    print "\n=== DATA TYPE: $base ===\n";

    foreach my $joinkey (keys %{ $afp_data{$base} }) {

        my $afp_row = $afp_data{$base}{$joinkey};
        my $cfp_value = $cfp_data{$base}{$joinkey} // '<MISSING>';

        my $afp_value_short = substr($afp_row->{value} // '', 0, 80);
        # replace any type of line break (\n, \r, or \r\n) with a single space
        $afp_value_short =~ s/[\r\n]+/ /g;

        my $cfp_value_short = substr($cfp_value // '', 0, 80);
        # replace any type of line break (\n, \r, or \r\n) with a single space
        $cfp_value_short =~ s/[\r\n]+/ /g;

        if ($afp_row->{approve} && $afp_row->{approve} eq 'rejected') {
            # there are 111 entries, we'll ignore these
            # print "REJECTED: $base | $joinkey | AFP_APPROVE=rejected | CFP=$cfp_value_short | AFP=$afp_value_short\n";
        }
        elsif ($afp_row->{approve} && $afp_row->{approve} eq 'approved') {
            my $afp_value_pg = $afp_row->{value};
            $afp_value_pg =~ s/\'/''/g;

            # Case: AFP has value, but CFP is missing
            if (!defined $cfp_value || $cfp_value eq '<MISSING>') {
                print "APPROVED-NEW: $base | $joinkey | AFP=$afp_value_short\n";
                push @pgcommands, qq(INSERT INTO cfp_$base VALUES ('$joinkey', '$afp_value_pg', '$afp_row->{curator}', '$afp_row->{timestamp}'););
                push @pgcommands, qq(INSERT INTO cfp_${base}_hst VALUES ('$joinkey', '$afp_value_pg', '$afp_row->{curator}', '$afp_row->{timestamp}'););
            }
            elsif ($afp_row->{value} eq $cfp_value) {
                print "APPROVED-SAME: $base | $joinkey | VALUE=$afp_value_short\n";
            }
            else {
                print "APPROVED-DIFF: $base | $joinkey | CFP=$cfp_value_short | AFP=$afp_value_short | CURATOR=$afp_row->{curator} | AFP_CFP_TS=$afp_row->{timestamp}\n";
            }
        }
    }
}

  foreach my $pgcommand (@pgcommands) {
    print qq($pgcommand\n);
# UNCOMMENT TO POPULATE
#     $dbh->do($pgcommand);
  } # foreach my $pgcommand (@pgcommands)


__END__

# Dockerized postgres doesn't have any users besides postgres
# put postgres users that should have 'all' access to the table.
# my @users_all = ('apache', 'azurebrd', 'cecilia', '"www-data"', 'acedb', 'valerio');    # ok on tazendra now
my @users_all = ();    # Dockerized postgres doesn't have any users besides postgres

# put postgres users that should have 'select' access to the table.  mainly so they can log on and see the data from a shell, but would probably work if you set the webserver to have select access, it would just give error messages if someone tried to update data.
# my @users_select = ('acedb');
my @users_select = ();

# the code for the datatype, by convention all datatypes have three letters.
my $datatype = 'afp';

# put tables here for each OA field.  Skip field 'id', fields of type 'queryonly', and any other fields that should not have a corresponding postgres table.
my @tables = qw( communitycontact );


# create afp/cfp/tfp : but show up in curation status form
# rnaseq chemphen envpheno 

# create afp/tfp/tfp : do not show up in curation status form
# variation othervariation strain otherstrain otherantibody species othertransgene version 


foreach my $table (@tables) {
#   $dbh->do( "DELETE FROM oac_column_width    WHERE oac_datatype = '$datatype';" );
#   $dbh->do( "DELETE FROM oac_column_order    WHERE oac_datatype = '$datatype';" );
#   $dbh->do( "DELETE FROM oac_column_showhide WHERE oac_datatype = '$datatype';" );
  &dropTable($table); 
  &createTable($table); 
}


sub dropTable {
  my $table = shift;
  my $result;
  $result = $dbh->do( "DROP TABLE IF EXISTS ${datatype}_${table}_hst;" );
  $result = $dbh->do( "DROP TABLE IF EXISTS ${datatype}_$table;" );
}

sub createTable {
  my $table = shift;
  my $result;
  $result = $dbh->do( "CREATE TABLE ${datatype}_${table}_hst (
                         joinkey text, 
                         ${datatype}_${table}_hst text,
                         ${datatype}_timestamp timestamp with time zone DEFAULT \"timestamp\"('now'::text)); " );
  $result = $dbh->do( "REVOKE ALL ON TABLE ${datatype}_${table}_hst FROM PUBLIC; ");
  foreach my $user (@users_select) { 
    $result = $dbh->do( "GRANT SELECT ON TABLE ${datatype}_${table}_hst TO $user; "); }
  foreach my $user (@users_all) { 
    $result = $dbh->do( "GRANT ALL ON TABLE ${datatype}_${table}_hst TO $user; "); }
  $result = $dbh->do( "CREATE INDEX ${datatype}_${table}_hst_idx ON ${datatype}_${table}_hst USING btree (joinkey); ");

  $result = $dbh->do( "CREATE TABLE ${datatype}_$table (
                         joinkey text, 
                         ${datatype}_$table text,
                         ${datatype}_timestamp timestamp with time zone DEFAULT \"timestamp\"('now'::text)); " );
  $result = $dbh->do( "REVOKE ALL ON TABLE ${datatype}_$table FROM PUBLIC; ");
  foreach my $user (@users_select) { 
    $result = $dbh->do( "GRANT SELECT ON TABLE ${datatype}_${table} TO $user; "); }
  foreach my $user (@users_all) { 
    $result = $dbh->do( "GRANT ALL ON TABLE ${datatype}_${table} TO $user; "); }
  $result = $dbh->do( "CREATE INDEX ${datatype}_${table}_idx ON ${datatype}_$table USING btree (joinkey); ");
} # sub createTable


__END__


=head1 NAME

create_datatype_tables.pl - script to create postgres data tables and history tables for ontology annotator datatype-field tables.


=head1 SYNOPSIS

Edit the arrays of users to grant permission to (both 'select' and 'all'), edit the datatype, edit the array of tables that list the table values, then run with

  ./create_datatype_tables.pl


=head1 DESCRIPTION

The ontology_annotator.cgi requires some postgres data tables and postgres history tables for almost all fields.  The 'id' field is required and doesn't have a corresponding set of postgres tables.  Fields of type 'queryonly' also don't have a corresponding set of postgres tables.  The tables have columns:

=over 4 

=item * joinkey  a text field that corresponds to the ontology annotator's pgid.

=item * <datatype>_<table>  a text field that stores the corresponding data.

=item * <datatype>_timestamp  a timestamp field with default 'now'.

=back

History tables are the same as normal tables with '_hst' appended to the table name, the second column name, and the index name.

For each table, the postgres table is '<datatype>_<table>', the history table is '<datatype>_<table>_hst' ;  the indices are '<datatype>_<table>_idx' and '<datatype>_<table>_hst_idx', indexing on the data column.  Tables are dropped in case they already exist and are then re-created, access is granted to postgres users, indices are created.

Edit the arrays of postgres database users to grant permission to (both 'select' and 'all'), edit the datatype, edit the array of tables that list the table values, then run with

  ./create_datatype_tables.pl
