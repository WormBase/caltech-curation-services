#!/usr/bin/perl -w

# move data from two_ tables to new two_ tables with different column for two_curator instead of old_timestamp.  2011 05 15
#
# real run.  2011 06 16

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my @users_all = ('apache', 'azurebrd', 'cecilia', '"www-data"');
my @users_select = ('acedb');


my @two_old_tables = qw(two_firstname two_middlename two_lastname two_standardname two_street two_city two_state two_post two_country two_institution two_old_institution two_mainphone two_labphone two_officephone two_otherphone two_fax two_email two_old_email two_pis two_lab two_oldlab two_left_field two_unable_to_contact two_privacy two_aka_firstname two_aka_middlename two_aka_lastname two_apu_firstname two_apu_middlename two_apu_lastname two_webpage two_wormbase_comment two_hide two_status two_mergedinto two_acqmerge );
my @two_simpler = qw(two_comment two_groups);

my @two_tables = qw( two_firstname two_middlename two_lastname two_standardname two_street two_city two_state two_post two_country two_institution two_old_institution two_old_inst_date two_mainphone two_labphone two_officephone two_otherphone two_fax two_email two_old_email two_old_email_date two_pis two_lab two_oldlab two_left_field two_unable_to_contact two_privacy two_aka_firstname two_aka_middlename two_aka_lastname two_webpage two_wormbase_comment two_hide two_status two_mergedinto two_acqmerge two_comment two_usefulwebpage );
# my @two_tables = qw( two_middlename );	# to only repopulate one table because two_middlename had some blank entries

my $dir = '/home/postgres/work/pgpopulation/two_people/20110515_person_retable/';
chdir($dir) or die "Cannot chdir to $dir : $!";

# UNCOMMENT TO BACKUP old two tables
# &backupOldTables();

# UNCOMMENT TO DROP old two tables
# &dropOldTablesAndView();
 
# UNCOMMENT TO REPOPULATE from backup
# &reCreateNewTablesAndView();
# 
# &repopulateNewTablesFromBackup();


sub repopulateNewTablesFromBackup {
  my @pgcommands;
  foreach my $table (@two_tables) {
    my $infile = $dir . "two_tables_backup/$table";
    next unless -e $infile;
    open (IN, "<$infile") or die "Cannot open $infile : $!";
    while (my $line = <IN>) {
      chomp $line;
      my ($joinkey, $order, $data, $oldt, $timestamp) = split/\t/, $line;
      if ($table eq 'two_comment') { $timestamp = $data; $data = $order; $order = '1'; }
      unless ($data) { 				# FIX check that cecilia fixed this
#         print "NO $table DATA $line\n"; 
        $data = 'NULL'; }
      if ($data =~ m/\'/) { $data =~ s/\'/''/g; }
#       if ( ($table eq 'two_middlename') && ($order = '\N') ) { $order = '1', $data = 'NULL'; }	# FIX check that cecilia fixed this
#       if ($timestamp eq '\N') { print "$table, $joinkey, $timestamp\n"; }
      if ( ($table eq 'two_old_institution') || ($table eq 'two_old_email') ) { 
        my $date_table = $table; 
        if ($table eq 'two_old_institution') { $date_table = 'two_old_inst_date'; }
        elsif ($table eq 'two_old_email') { $date_table = 'two_old_email_date'; }
        push @pgcommands, "INSERT INTO $date_table VALUES ('$joinkey', '$order', E'$oldt', 'two1', '$timestamp');";
        push @pgcommands, "INSERT INTO h_$date_table VALUES ('$joinkey', '$order', E'$oldt', 'two1', '$timestamp');"; }
      push @pgcommands, "INSERT INTO $table VALUES ('$joinkey', '$order', E'$data', 'two1', '$timestamp');";
      push @pgcommands, "INSERT INTO h_$table VALUES ('$joinkey', '$order', E'$data', 'two1', '$timestamp');";
    } # while (my $line = <IN>)
    close (IN) or die "Cannot open $infile : $!";
  } # foreach my $table (@two_tables)
  foreach my $command (@pgcommands) {
# UNCOMMENT TO populate based on backup data
    $dbh->do( $command );
    print "$command\n";
  } # foreach my $command (@pgcommands)
} # sub repopulateNewTablesFromBackup


sub reCreateNewTablesAndView {
  &dropViews();
  &dropNewTables();
  &createNewTables();
  &createNewViews();
} # sub reCreateNewTablesAndView

sub backupOldTables { foreach my $table (@two_old_tables, @two_simpler) { $result = $dbh->do( "COPY $table TO '${dir}two_tables_backup/$table'" ); } }

sub dropOldTablesAndView { foreach my $table (@two_old_tables, @two_simpler) { $result = $dbh->do( "DROP TABLE $table" ); } &dropViews(); }

sub dropViews { $result = $dbh->do( "DROP VIEW two_fullname" ); }

sub createNewViews {
    $result = $dbh->do( "CREATE VIEW two_fullname AS SELECT two_lastname.joinkey, two_lastname.two_lastname, two_firstname.two_firstname, two_middlename.two_middlename FROM two_lastname, two_firstname, two_middlename WHERE ((two_lastname.joinkey = two_firstname.joinkey) AND (two_lastname.joinkey = two_middlename.joinkey))" );
    foreach my $user (@users_select) { $result = $dbh->do( "GRANT SELECT ON TABLE two_fullname TO $user; "); }
    foreach my $user (@users_all) {    $result = $dbh->do( "GRANT ALL    ON TABLE two_fullname TO $user; "); }
} # createNewViews

sub dropNewTables {
  foreach my $table (@two_tables ) {
    $result = $dbh->do( "DROP TABLE h_${table};" );
    $result = $dbh->do( "DROP TABLE $table;" ); }
} # sub dropNewTables

sub createNewTables {
  foreach my $table (@two_tables ) {
    $result = $dbh->do( "CREATE TABLE h_${table} (
                           joinkey text,
                           two_order integer,
                           ${table} text,
                           two_curator text,
                           two_timestamp timestamp with time zone DEFAULT \"timestamp\"('now'::text)); " );
    $result = $dbh->do( "REVOKE ALL ON TABLE h_${table} FROM PUBLIC; ");
    foreach my $user (@users_select) { $result = $dbh->do( "GRANT SELECT ON TABLE h_${table} TO $user; "); }
    foreach my $user (@users_all) {    $result = $dbh->do( "GRANT ALL    ON TABLE h_${table} TO $user; "); }
    $result = $dbh->do( "CREATE INDEX h_${table}_idx ON h_${table} USING btree (joinkey); ");
  
    $result = $dbh->do( "CREATE TABLE $table (
                           joinkey text,
                           two_order integer,
                           ${table} text,
                           two_curator text,
                           two_timestamp timestamp with time zone DEFAULT \"timestamp\"('now'::text)); " );
    $result = $dbh->do( "REVOKE ALL ON TABLE $table FROM PUBLIC; ");
    foreach my $user (@users_select) { $result = $dbh->do( "GRANT SELECT ON TABLE ${table} TO $user; "); }
    foreach my $user (@users_all) {    $result = $dbh->do( "GRANT ALL    ON TABLE ${table} TO $user; "); }
    $result = $dbh->do( "CREATE INDEX ${table}_idx ON $table USING btree (joinkey); ");
  } # foreach my $table (@two_tables )
} # sub createNewTables


__END__

#     View "public.two_fullname"
#      Column     | Type | Modifiers 
# ----------------+------+-----------
#  joinkey        | text | 
#  two_lastname   | text | 
#  two_firstname  | text | 
#  two_middlename | text | 
# View definition:
#  SELECT two_lastname.joinkey, two_lastname.two_lastname, two_firstname.two_firstname, two_middlename.two_middlename
#    FROM two_lastname, two_firstname, two_middlename
#   WHERE two_lastname.joinkey = two_firstname.joinkey AND two_lastname.joinkey = two_middlename.joinkey;

my $result = $dbh->prepare( "SELECT * FROM two_comment WHERE two_comment ~ ?" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[1] =~ s///g;
    $row[2] =~ s///g;
    print "$row[0]\t$row[1]\t$row[2]\n";
  } # if ($row[0])
} # while (@row = $result->fetchrow)


