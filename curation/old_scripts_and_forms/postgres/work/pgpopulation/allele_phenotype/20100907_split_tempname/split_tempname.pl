#!/usr/bin/perl -w

# split data from app_type + app_tempname into app_strain, app_variation, app_rearrangement, app_transgene.  2010 09 07
#
# live run 2010 09 15

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my @pgcommands;
push @pgcommands, "DELETE FROM app_variation;";
push @pgcommands, "DELETE FROM app_variation_hst;";
push @pgcommands, "DELETE FROM app_strain;";
push @pgcommands, "DELETE FROM app_strain_hst;";
push @pgcommands, "DELETE FROM app_transgene;";
push @pgcommands, "DELETE FROM app_transgene_hst;";
push @pgcommands, "DELETE FROM app_rearrangement;";
push @pgcommands, "DELETE FROM app_rearrangement_hst;";

my %hash;
my $result = $dbh->prepare( "SELECT * FROM app_type" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { 
  next unless $row[1];
  if ($row[1] eq 'Allele') { $hash{$row[0]}{type} = 'variation'; }
  elsif ($row[1] eq 'Rearrangement') { $hash{$row[0]}{type} = 'rearrangement'; }
  elsif ($row[1] eq 'Strain') { $hash{$row[0]}{type} = 'strain'; }
  elsif ($row[1] eq 'Transgene') { $hash{$row[0]}{type} = 'transgene'; }
  else { print "NO TYPE for @row\n"; }
} # while (@row = $result->fetchrow)

$result = $dbh->prepare( "SELECT * FROM app_tempname" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { 
  next unless $row[1];
  $hash{$row[0]}{tempname} = $row[1];
  $hash{$row[0]}{time} = $row[2];
} # while (@row = $result->fetchrow)

foreach my $pgid (sort { $a<=>$b } keys %hash) {
  my $name = $hash{$pgid}{tempname};
  my $type = $hash{$pgid}{type};
  if ($type && !($name)) { print "NO NAME $pgid $type\n"; }
  if (!$type && ($name)) { print "NO TYPE $pgid $name\n"; }
  next unless ($type && $name);
  my $time = $hash{$pgid}{time};
  my $command = "INSERT INTO app_$type VALUES ('$pgid', '$name', '$time');";
  push @pgcommands, $command;
  $command = "INSERT INTO app_${type}_hst VALUES ('$pgid', '$name', '$time');";
  push @pgcommands, $command;
} # foreach my $pgid (sort { $a<=>$b } keys %hash)

foreach my $command (@pgcommands) {
  print "$command\n";
# UNCOMMENT to transfer all data
#   $result = $dbh->do( $command );
}

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

