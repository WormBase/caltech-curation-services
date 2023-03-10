#!/usr/bin/perl -w

# found that  confirm_paper.cgi  was not using the pap_ tables and there was a fair bit of data
# connected there.  this script tries to find the correct wpa_join and pap_join by looking at the
# wpa_author_possible values + timestamps and the pap_author_possible values + timestamps (because
# the joins got flattenned in the transfer, so they no longer match).  after comparing values, it
# seems that almost everything is the same in both tables, with the main difference being who
# verified the connections.  2011 06 11

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my $result;

my %wpa;
$result = $dbh->prepare( "SELECT * FROM wpa_author_verified ORDER BY wpa_timestamp" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  my $key = "$row[0]\t$row[2]";
  if ($row[3] eq 'valid') { 
    if ($row[1]) {
      if ($row[1] eq 'YES  ') { $row[1] = 'YES'; }
      elsif ($row[1] eq 'NO  ') { $row[1] = 'NO'; } }
    $wpa{$key}{value} = $row[1];
    $wpa{$key}{curator} = $row[4];
    ($row[5]) = $row[5] =~ m/^(\d{4}\-\d{2}\-\d{2} \d{2}:\d{2}:\d{2})/;
    $wpa{$key}{timestamp} = $row[5];
  } else { delete $wpa{$key}; }
} # while (@row = $result->fetchrow)

my %wpa_pos_aj; my %wpa_pos_pt;
$result = $dbh->prepare( "SELECT * FROM wpa_author_possible ORDER BY wpa_timestamp" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  my $aid_join = "$row[0]\t$row[2]";
  if ($row[3] eq 'valid') { 
    $wpa_pos_aj{$aid_join}{aid} = $row[0];
    $wpa_pos_aj{$aid_join}{value} = $row[1];
    $wpa_pos_aj{$aid_join}{join} = $row[2];
    $wpa_pos_aj{$aid_join}{curator} = $row[4];
    ($row[5]) = $row[5] =~ m/^(\d{4}\-\d{2}\-\d{2} \d{2}:\d{2}:\d{2})/;
    $wpa_pos_aj{$aid_join}{timestamp} = $row[5];
  } else { delete $wpa_pos_aj{$aid_join}; }
} # while (my @row = $result->fetchrow)
foreach my $aid_join (sort keys %wpa_pos_aj) {
  my $aid = $wpa_pos_aj{$aid_join}{aid};
  next unless $wpa_pos_aj{$aid_join}{value};
  my $wpa_pos = $wpa_pos_aj{$aid_join}{value};
  my $join = $wpa_pos_aj{$aid_join}{join};
  my $cur = $wpa_pos_aj{$aid_join}{curator};
  my $time = $wpa_pos_aj{$aid_join}{timestamp};
  my $pos_time = "$wpa_pos\t$time";
  $wpa_pos_pt{$aid}{$pos_time}{aid} = $aid;
  $wpa_pos_pt{$aid}{$pos_time}{wpa_pos} = $wpa_pos;
  $wpa_pos_pt{$aid}{$pos_time}{join} = $join;
  $wpa_pos_pt{$aid}{$pos_time}{curator} = $cur;
  $wpa_pos_pt{$aid}{$pos_time}{time} = $time;
} # while (@row = $result->fetchrow)

my %pap;
$result = $dbh->prepare( "SELECT * FROM pap_author_verified ORDER BY pap_timestamp" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  my $key = "$row[0]\t$row[2]";
  $pap{$key}{value} = $row[1];
  $pap{$key}{curator} = $row[3];
  ($row[4]) = $row[4] =~ m/^(\d{4}\-\d{2}\-\d{2} \d{2}:\d{2}:\d{2})/;
  $pap{$key}{timestamp} = $row[4];
} # while (@row = $result->fetchrow)

my %pap_pos;
$result = $dbh->prepare( "SELECT * FROM pap_author_possible ORDER BY pap_timestamp" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  my $key = "$row[0]\t$row[2]";
  my $aid = $row[0];
  ($row[4]) = $row[4] =~ m/^(\d{4}\-\d{2}\-\d{2} \d{2}:\d{2}:\d{2})/;
  my $pos_time = "$row[1]\t$row[4]";
  $pap_pos{$aid}{$pos_time}{value} = $row[1];
  $pap_pos{$aid}{$pos_time}{join} = $row[2];
  $pap_pos{$aid}{$pos_time}{curator} = $row[3];
  $pap_pos{$aid}{$pos_time}{timestamp} = $row[4];
#   $pap_pos{$key}{value} = $row[1];
#   $pap_pos{$key}{curator} = $row[3];
#   $pap_pos{$key}{timestamp} = $row[4];
} # while (@row = $result->fetchrow)

foreach my $aid (sort keys %wpa_pos_pt) {
  foreach my $pos_time (sort keys %{ $wpa_pos_pt{$aid} }) {
#     unless ($pap_pos{$aid}{$pos_time}) { print "NO pap_possible for AID $aid PT $pos_time\n"; }	# 41 values here, some in history, don't seem so important
    next unless ($pap_pos{$aid}{$pos_time});
    my $wpa_join = $wpa_pos_pt{$aid}{$pos_time}{join}; 
    my $pap_join = $pap_pos{$aid}{$pos_time}{join}; 
    my $wpa_key = "$aid\t$wpa_join";
    next unless $wpa{$wpa_key}{value};		# only look at values that have a wpa_author_verified
    my $wpa_ver = $wpa{$wpa_key}{value};
    my $pap_key = "$aid\t$pap_join";
    if ($pap{$pap_key}{value}) {
      my $pap_ver = $pap{$pap_key}{value};
      unless ($pap_ver eq $wpa_ver) { print "DIFF $aid PT $pos_time W $wpa_ver P $pap_ver E\n"; }
    } else {
      print "NO PAP $aid PT $pos_time W $wpa_ver E\n";
    } 
  } # foreach my $pos_time (sort keys %{ $wpa_pos{$aid} })
} # foreach my $aid (sort keys %wpa_pos)

# foreach my $key (sort keys %wpa) {
#   next unless ($wpa{$key}{value});
#   next if ($pap{$key});
#   my $wpa_value = $wpa{$key}{value};
#   my $pos_value = $pos{$key}{value};
#   print "$key\t$wpa_value\t$pos_value\n";
# } # foreach my $key (sort keys %wpa)

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

