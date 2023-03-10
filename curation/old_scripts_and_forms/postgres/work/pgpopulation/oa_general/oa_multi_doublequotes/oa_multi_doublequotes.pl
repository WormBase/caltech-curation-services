#!/usr/bin/perl -w

# fix oa multidropdown / multiontology tables where they don't have the doublequotes they should.
# Decided to ignore history tables, because some of them have old-style objects (like variation 
# names vs. WBVarIDs, or | separated objects instead of ",") and shouldn't have their format 
# arbitrarily changed.  2011 04 03


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
    if ($type =~ m/^multi/) { 
#       print "$datatype $field $type\n"; 
      my @tables = ();
      my $table = $datatype . '_' . $field;
      push @tables, $table;
# Decided to ignore history tables, because some of them have old-style objects (like variation names vs. WBVarIDs, or | separated objects instead of ",") and shouldn't have their format arbitrarily changed.
#       $table = $datatype . '_' . $field . '_hst';
#       push @tables, $table;
      foreach my $table (@tables) {
        my $pgquery = "SELECT DISTINCT($table) FROM $table WHERE $table IS NOT NULL AND $table != '' AND $table !~ '\"'";
#         print "$pgquery\n";
        my $result = $dbh->prepare( $pgquery );
        $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
        while (my @row = $result->fetchrow) {
          if ($row[0]) { 
            my $newValue = $row[0];
            if ($row[0] =~ m/,/) { my (@objs) = split',', $row[0]; $newValue = join'","', @objs; }
            $newValue = '"' . $newValue . '"';
            my $pgcommand = "UPDATE $table SET $table = '$newValue' WHERE $table = '$row[0]';";
#             print "$table\t@row\n";
            print "$pgcommand\n";
# UNCOMMENT to update values
#             my $result2 = $dbh->do( $pgcommand );
      } } }
    }
  }
}





__END__

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

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

__END__

my $result = $dbh->prepare( 'SELECT * FROM two_comment WHERE two_comment ~ ?' );
$result->execute('elegans') or die "Cannot prepare statement: $DBI::errstr\n"; 

$result->execute("doesn't") or die "Cannot prepare statement: $DBI::errstr\n"; 
my $var = "doesn't";
$result->execute($var) or die "Cannot prepare statement: $DBI::errstr\n"; 

my $data = 'data';
unless (is_utf8($data)) { from_to($data, "iso-8859-1", "utf8"); }

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

to concatenate string to query result :
  SELECT 'WBPaper' || joinkey FROM pap_identifier WHERE pap_identifier ~ 'pmid';
to get :
  SELECT DISTINCT(gop_paper_evidence) FROM gop_paper_evidence WHERE gop_paper_evidence NOT IN (SELECT 'WBPaper' || joinkey FROM pap_identifier WHERE pap_identifier ~ 'pmid') AND gop_paper_evidence != '';

