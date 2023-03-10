#!/usr/bin/perl -w

# migrate pos/neg/not lifestage/anatomy/scl/scltext into single tables + result  for Chris.  2018 12 10

# Also get rid of some old tables.
# DROP TABLE grg_transregulatorseq;
# DROP TABLE grg_transregulatorseq_hst;
# DROP TABLE grg_transregulatedseq;
# DROP TABLE grg_transregulatedseq_hst
# DELETE FROM oac_column_width    WHERE oac_datatype = 'grg';
# DELETE FROM oac_column_order    WHERE oac_datatype = 'grg';
# DELETE FROM oac_column_showhide WHERE oac_datatype = 'grg';




use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %subToRegulate;
$subToRegulate{'neg'} = 'Negative_regulate';
$subToRegulate{'not'} = 'Does_not_regulate';
$subToRegulate{'pos'} = 'Positive_regulate';


my %result;
my %data;
my %timestamp;
my %pgids;
$result = $dbh->prepare( "SELECT * FROM grg_result" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $result{$row[0]} = $row[1]; }
} # while (@row = $result->fetchrow)

my @subtype = qw( pos neg not );
my @types = qw( anatomy lifestage scl scltext );
foreach my $type (@types) {
  foreach my $subtype (@subtype) {
    my $table = 'grg_' . $subtype . '_' . $type;
    $result = $dbh->prepare( "SELECT * FROM $table" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) {
      if ($row[0]) {
#         next unless ($row[0] == 14);
#         print qq(T $type S $subtype R @row\n);
        $pgids{$row[0]}++;
        $timestamp{$type}{$row[0]}{$subtype} = $row[2]; 
        my $data = $row[1];
        if ($data eq 'Positive SCL') { $data = 'SCL'; }
          elsif ($data eq 'Negative SCL') { $data = 'SCL'; }
          elsif ($data eq 'Does Not SCL') { $data = 'SCL'; }
        $data{$type}{$row[0]}{$subtype} = $data; }
    } # while (@row = $result->fetchrow)
  } # foreach my $subtype (@subtype)
}

# error checking of data
foreach my $pgid (sort { $a<=>$b } keys %pgids) {
#   next unless ($pgid == 14);
  foreach my $type (@types) {
    my %hasType;
    foreach my $subtype (sort keys %{ $data{$type}{$pgid} }) {
#       print qq(SUB $subtype S\n);
      $hasType{$subtype}++;
    } # foreach my $subtype (sort keys %{ $data{$type}{$pgid} })
    my $subtypes = join", ", keys %hasType;
    if (scalar keys %hasType > 1) {
      print qq(TYPE $type PGID $pgid HAS $subtypes\n);
    } 
    elsif (scalar keys %hasType > 0) {
      if ($result{$pgid}) {
        if ($subToRegulate{$subtypes} ne $result{$pgid}) {
          print qq(ERROR TYPE $type PGID $pgid HAS $subtypes RESULT $result{$pgid}\n);
        }
      }
    }
  } # foreach my $type (@types)
}

my @pgcommands;
foreach my $pgid (sort { $a<=>$b } keys %pgids) {
  foreach my $type (@types) {
    foreach my $subtype (sort keys %{ $data{$type}{$pgid} }) {
      push @pgcommands, qq(INSERT INTO grg_$type VALUES ('$pgid', '$data{$type}{$pgid}{$subtype}', '$timestamp{$type}{$pgid}{$subtype}'));
      push @pgcommands, qq(INSERT INTO grg_${type}_hst VALUES ('$pgid', '$data{$type}{$pgid}{$subtype}', '$timestamp{$type}{$pgid}{$subtype}'));
      unless ($result{$pgid}) { 
        push @pgcommands, qq(INSERT INTO grg_result VALUES ('$pgid', '$subToRegulate{$subtype}', '$timestamp{$type}{$pgid}{$subtype}'));
        push @pgcommands, qq(INSERT INTO grg_result_hst VALUES ('$pgid', '$subToRegulate{$subtype}', '$timestamp{$type}{$pgid}{$subtype}'));
        $result{$pgid} = $subToRegulate{$subtype};
      } # unless ($result{$pgid}) 
    } # foreach my $subtype (sort keys %{ $data{$type}{$pgid} })
  } # foreach my $type (@types) 
} # foreach my $pgid (sort { $a<=>$b } keys %pgids) 

foreach my $pgcommand (@pgcommands) {
  print qq($pgcommand\n);
# UNCOMMENT TO POPULATE
#   $dbh->do($pgcommand);
} # foreach my $pgcommand (@pgcommands)

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

