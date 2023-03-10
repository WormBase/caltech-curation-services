#!/usr/bin/perl -w

# append other_animal and possible_pseudonym into abp_remark

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

# my %name;
# my %other_animal;
# my %possible_pseudonym
# my %remark;
my %data;

my @tables = qw( name other_animal possible_pseudonym remark );

foreach my $table (@tables) {
  $result = $dbh->prepare( "SELECT * FROM abp_$table" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { $data{$table}{$row[0]} = $row[1]; }
}

my @pgcommands;
foreach my $pgid (sort keys %{ $data{name} }) {
  my @data;
  my $update = 0;
  my $delete = 0;
  if ($data{'remark'}{$pgid}) { 
    $delete++;
    my $remark = $data{'remark'}{$pgid};
    unless ($remark =~ m/\.$/) { $remark .= '.'; }
    push @data, $remark; }
  if ($data{'other_animal'}{$pgid}) { 
    my $other_animal = $data{'other_animal'}{$pgid};
    unless ($other_animal =~ m/\.$/) { $other_animal .= '.'; }
    $update++;
    push @data, qq(Other animal: $other_animal); }
  if ($data{'possible_pseudonym'}{$pgid}) { 
    my $possible_pseudonym = $data{'possible_pseudonym'}{$pgid};
    if ($possible_pseudonym  =~ m/ \| /) { $possible_pseudonym  =~ s/ \| /; /g; }
    $update++;
    push @data, qq(Possible pseudonym: $possible_pseudonym); }
  if ($update) {
    my $newRemark = join" ", @data;
    print qq($pgid\t$newRemark\n);
    $newRemark =~ s/\'/''/g;
    if ($delete) {
      push @pgcommands, qq(DELETE FROM abp_remark WHERE joinkey = '$pgid';); }
    push @pgcommands, qq(INSERT INTO abp_remark VALUES ('$pgid', '$newRemark'););
    push @pgcommands, qq(INSERT INTO abp_remark_hst VALUES ('$pgid', '$newRemark'););
  }
}
foreach my $pgcommand (@pgcommands) {
  print qq($pgcommand\n);
# UNCOMMENT TO POPULATE
#   $dbh->do($pgcommand);
} # foreach my $pgcommand (@pgcommands)

__END__

COPY abp_remark TO '/home/postgres/work/pgpopulation/antibody/20210414_object_ids/backup_tazendra/abp_remark.pg';
COPY abp_remark_hst TO '/home/postgres/work/pgpopulation/antibody/20210414_object_ids/backup_tazendra/abp_remark_hst.pg';
COPY abp_other_animal TO '/home/postgres/work/pgpopulation/antibody/20210414_object_ids/backup_tazendra/abp_other_animal.pg';
COPY abp_other_animal_hst TO '/home/postgres/work/pgpopulation/antibody/20210414_object_ids/backup_tazendra/abp_other_animal_hst.pg';
COPY abp_possible_pseudonym TO '/home/postgres/work/pgpopulation/antibody/20210414_object_ids/backup_tazendra/abp_possible_pseudonym.pg';
COPY abp_possible_pseudonym_hst TO '/home/postgres/work/pgpopulation/antibody/20210414_object_ids/backup_tazendra/abp_possible_pseudonym_hst.pg';

DELETE FROM abp_remark;
DELETE FROM abp_remark_hst;
DELETE FROM abp_other_animal;
DELETE FROM abp_other_animal_hst;
DELETE FROM abp_possible_pseudonym;
DELETE FROM abp_possible_pseudonym_hst;
COPY abp_remark FROM '/home/postgres/work/pgpopulation/antibody/20210414_object_ids/backup_tazendra/abp_remark.pg';
COPY abp_remark_hst FROM '/home/postgres/work/pgpopulation/antibody/20210414_object_ids/backup_tazendra/abp_remark_hst.pg';
COPY abp_other_animal FROM '/home/postgres/work/pgpopulation/antibody/20210414_object_ids/backup_tazendra/abp_other_animal.pg';
COPY abp_other_animal_hst FROM '/home/postgres/work/pgpopulation/antibody/20210414_object_ids/backup_tazendra/abp_other_animal_hst.pg';
COPY abp_possible_pseudonym FROM '/home/postgres/work/pgpopulation/antibody/20210414_object_ids/backup_tazendra/abp_possible_pseudonym.pg';
COPY abp_possible_pseudonym_hst FROM '/home/postgres/work/pgpopulation/antibody/20210414_object_ids/backup_tazendra/abp_possible_pseudonym_hst.pg';


foreach my $table (@others) {
  $result = $dbh->prepare( "SELECT * FROM $table WHERE $table IS NOT NULL" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    $row[1] =~ s///g;
    my $pgid = $row[0];
    my $data = $row[1];
    $data =~ s/^\"//;
    $data =~ s/\"$//;
    my (@data) = split/\",\"/, $data;
    my %new;
    foreach my $name (@data) {
      next unless ($name);
# next unless ($row[0] eq '12879');
      $name = lc($name);
      if ($nameToId{$name}) { $new{$nameToId{$name}}++; }
      else { print qq($table\t$pgid\t$name\tnot found\n); }
    }
    my $newData = join'","', sort keys %new;
    if ($newData) {
      push @pgcommands, qq(DELETE FROM $table WHERE joinkey = '$pgid';);
      push @pgcommands, qq(INSERT INTO $table VALUES ('$pgid', '"$newData"'););
      push @pgcommands, qq(INSERT INTO ${table}_hst VALUES ('$pgid', '"$newData"'););
    }
  } # while (my @row = $result->fetchrow)
}

foreach my $pgcommand (@pgcommands) {
  print qq($pgcommand\n);
# UNCOMMENT TO POPULATE
#   $dbh->do($pgcommand);
} # foreach my $pgcommand (@pgcommands)

__END__

foreach my $pgid (sort {$a<=>$b} keys %pgids) {
  my $name = 'WBAntibody' . &pad8Zeros($pgid);
#   print qq($pgid\t$name\n);
  push @pgcommands, qq(DELETE FROM abp_name WHERE joinkey = '$pgid';);
  push @pgcommands, qq(INSERT INTO abp_name VALUES ('$pgid', '$name'););
  push @pgcommands, qq(INSERT INTO abp_name_hst VALUES ('$pgid', '$name'););
} # foreach my $pgid (sort {$a<=>$b} keys %pgids)

foreach my $pgcommand (@pgcommands) {
  print qq($pgcommand\n);
# UNCOMMENT TO POPULATE
#   $dbh->do($pgcommand);
} # foreach my $pgcommand (@pgcommands)


sub pad8Zeros {         # take a number and pad to 8 digits
  my $number = shift;
  if ($number =~ m/^0+/) { $number =~ s/^0+//g; }               # strip leading zeros
  if ($number < 10) { $number = '0000000' . $number; }
  elsif ($number < 100) { $number = '000000' . $number; }
  elsif ($number < 1000) { $number = '00000' . $number; }
  elsif ($number < 10000) { $number = '0000' . $number; }
  elsif ($number < 100000) { $number = '000' . $number; }
  elsif ($number < 1000000) { $number = '00' . $number; }
  elsif ($number < 10000000) { $number = '0' . $number; }
  return $number;
} # sub pad8Zeros

__END__

$result = $dbh->prepare( "SELECT * FROM two_comment LIMIT 5" );
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

