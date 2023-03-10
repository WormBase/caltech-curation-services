#!/usr/bin/perl -w

# for exp_ constructs that are not in trp_construct, create new trp_ entries and copy data from cns_ OA.  2021 03 16
# for exp_ constructs that are no longer valid in cns_name, remove them from exp_construct.    2021 03 18
#
# originally at /home/postgres/work/pgpopulation/exp_exprpattern/20210316_construct_to_transgene/copy_construct_to_transgene.pl
# 
# https://wiki.wormbase.org/index.php/Expression_Pattern#Populating_exp_transgene_based_on_exp_construct




use strict;
use diagnostics;
use DBI;
use Jex;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my @pgcommands;

my %expTransgene;
$result = $dbh->prepare( "SELECT * FROM exp_transgene;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) {
  if ($row[0]) { $expTransgene{$row[0]} = $row[1]; }
} # while (@row = $result->fetchrow)

my %expCns;
my %expCnsByPgid;
my %trpCns;

$result = $dbh->prepare( "SELECT * FROM trp_construct;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) {
  if ($row[0]) {
    my (@constructs) = $row[1] =~ m/(WBCnstr\d+)/g;
    foreach my $cns (@constructs) {
      $trpCns{$cns}{$row[0]}++;
    }
  } # if ($row[0])
} # while (@row = $result->fetchrow)

$result = $dbh->prepare( "SELECT * FROM exp_construct;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) {
  if ($row[0]) {
    $expCnsByPgid{$row[0]} = $row[1];
    my (@constructs) = $row[1] =~ m/(WBCnstr\d+)/g;
    foreach my $cns (@constructs) {
      $expCns{$cns}{$row[0]}++;
    }
  } # if ($row[0])
} # while (@row = $result->fetchrow)

my %cnsToPg;
$result = $dbh->prepare( "SELECT * FROM cns_name;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) {
  if ($row[0]) { $cnsToPg{$row[1]} = $row[0]; }
}

my @cns_tables = qw( summary name paper );
my %cns;
foreach my $table (@cns_tables) {
  $result = $dbh->prepare( "SELECT * FROM cns_$table;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
    if ($row[0]) { $cns{$table}{$row[0]} = $row[1]; }
  }
} # foreach my $table (@cns_tables)

my ($pgid) = &getHighestTrpPgid();
print qq(HIGHEST $pgid\n);
my %addTransgeneToExpConstruct;

my %removeCnsFromExpConstruct;

my $count = 0;
foreach my $cns (sort keys %expCns) {
  next if ($trpCns{$cns});
  if ($cnsToPg{$cns}) {
#     $count++; last if ($count > 4);
    $pgid++;
#     print qq($cns\n);

    my $trpId = 'WBTransgene' . &pad8Zeros($pgid);
    foreach my $otherpgid (sort keys %{ $expCns{$cns}}) {
      $addTransgeneToExpConstruct{$otherpgid}{$trpId}++;
    }
    &addToPg($pgid, $trpId, 'trp_name');

    my $cnsPgid = $cnsToPg{$cns};
    print qq(CREATE trp_ $cns with pgid $pgid, from exp_construct $cnsPgid data\n);
#     print qq(cnsPgid $cnsPgid\n);
    if ($cns{'name'}{$cnsPgid}) {
      my $data = '"' . $cns{'name'}{$cnsPgid} . '"';
      &addToPg($pgid, $data, 'trp_construct');
    }
    if ($cns{'summary'}{$cnsPgid}) {
      my $data = $cns{'summary'}{$cnsPgid};
      &addToPg($pgid, $data, 'trp_summary');
    }
    if ($cns{'paper'}{$cnsPgid}) {
      my $data = $cns{'paper'}{$cnsPgid};
      &addToPg($pgid, $data, 'trp_paper');
    }
    &addToPg($pgid, 'WBPerson12028', 'trp_curator');
# TODO transfer to exp_construct
  } else {
    foreach my $otherpgid (sort keys %{ $expCns{$cns}}) {
      $removeCnsFromExpConstruct{$otherpgid}{$cns}++; 
#       print qq($cns in exp_construct $otherpgid does not exist in Construct OA\n);
    }
  }
} # foreach my $cns (sort keys %expCns)


foreach my $pgid (sort {$a<=>$b} keys %addTransgeneToExpConstruct) {
  my @transgenes = ();
  my $before = '';
  if ($expTransgene{$pgid}) {
    $before = $expTransgene{$pgid};
    (@transgenes) = $expTransgene{$pgid} =~ m/(WBTransgene\d+)/g;
  }
  foreach my $trpId (sort keys %{ $addTransgeneToExpConstruct{$pgid} }) {
    push @transgenes, $trpId;
  }
  my $transgenes = join'","', @transgenes;
  my $data = '"' . $transgenes . '"';
  print qq($pgid BEFORE $before AFTER $data END\n);
  if ($before) {
    &deletePg($pgid, 'exp_transgene'); }
  &addToPg($pgid, $data, 'exp_transgene');
}

foreach my $pgid (sort {$a<=>$b} keys %removeCnsFromExpConstruct) {
  my $oldData = $expCnsByPgid{$pgid};
  my $cnsToRemove = join", ", sort keys %{ $removeCnsFromExpConstruct{$pgid} };
  my (@constructs) = $oldData =~ m/(WBCnstr\d+)/g;
  my %goodConstructs;
  foreach (@constructs) { $goodConstructs{$_}++; }
  foreach my $cns (sort keys %{ $removeCnsFromExpConstruct{$pgid} }) {
    if ($goodConstructs{$cns}) { delete $goodConstructs{$cns}; }
  }
  print qq(exp_construct $pgid from $oldData remove $cnsToRemove\n);
  &deletePg($pgid, 'exp_construct');
  if (scalar keys %goodConstructs > 0) {
    my $constructs = join'","', sort keys %goodConstructs;
    my $data = '"' . $constructs . '"';
    &addToPg($pgid, $data, 'exp_construct');
  } else {
    push @pgcommands, qq(INSERT INTO exp_construct_hst VALUES ('$pgid', NULL););
  }
}



foreach my $pgcommand (@pgcommands) {
  print qq($pgcommand\n);
# UNCOMMENT TO POPULATE
  $dbh->do( $pgcommand );
}



sub deletePg {
  my ($pgid, $table) = @_;
  push @pgcommands, qq(DELETE FROM $table WHERE joinkey = '$pgid';);
}

sub addToPg {
  my ($pgid, $data, $table) = @_;
  ($data) = &filterForPg($data);
  push @pgcommands, qq(INSERT INTO $table VALUES ('$pgid', E'$data'););
  push @pgcommands, qq(INSERT INTO ${table}_hst VALUES ('$pgid', E'$data'););
}

sub getHighestTrpPgid {
  my $highest = 0;
  my @tables = qw( trp_name trp_curator );
  foreach my $table (@tables) {
    $result = $dbh->prepare( "SELECT joinkey FROM $table ORDER BY joinkey::INTEGER DESC LIMIT 1;" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
    my @row = $result->fetchrow();
    if ($row[0]) { if ($row[0] > $highest) { $highest = $row[0]; } }
  }
  return $highest;
} # sub getHighestTrpPgid

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

# backup data that's getting updated by this
#
# COPY exp_transgene TO '/home/postgres/work/pgpopulation/exp_exprpattern/20210316_construct_to_transgene/backup/exp_transgene.pg';
# COPY exp_construct TO '/home/postgres/work/pgpopulation/exp_exprpattern/20210316_construct_to_transgene/backup/exp_construct.pg';
# COPY trp_name      TO '/home/postgres/work/pgpopulation/exp_exprpattern/20210316_construct_to_transgene/backup/trp_name.pg';
# COPY trp_construct TO '/home/postgres/work/pgpopulation/exp_exprpattern/20210316_construct_to_transgene/backup/trp_construct.pg';
# COPY trp_summary   TO '/home/postgres/work/pgpopulation/exp_exprpattern/20210316_construct_to_transgene/backup/trp_summary.pg';
# COPY trp_paper     TO '/home/postgres/work/pgpopulation/exp_exprpattern/20210316_construct_to_transgene/backup/trp_paper.pg';
# COPY trp_curator   TO '/home/postgres/work/pgpopulation/exp_exprpattern/20210316_construct_to_transgene/backup/trp_curator.pg';
# 
# COPY exp_transgene_hst TO '/home/postgres/work/pgpopulation/exp_exprpattern/20210316_construct_to_transgene/backup/exp_transgene_hst.pg';
# COPY exp_construct_hst TO '/home/postgres/work/pgpopulation/exp_exprpattern/20210316_construct_to_transgene/backup/exp_construct_hst.pg';
# COPY trp_name_hst      TO '/home/postgres/work/pgpopulation/exp_exprpattern/20210316_construct_to_transgene/backup/trp_name_hst.pg';
# COPY trp_construct_hst TO '/home/postgres/work/pgpopulation/exp_exprpattern/20210316_construct_to_transgene/backup/trp_construct_hst.pg';
# COPY trp_summary_hst   TO '/home/postgres/work/pgpopulation/exp_exprpattern/20210316_construct_to_transgene/backup/trp_summary_hst.pg';
# COPY trp_paper_hst     TO '/home/postgres/work/pgpopulation/exp_exprpattern/20210316_construct_to_transgene/backup/trp_paper_hst.pg';
# COPY trp_curator_hst   TO '/home/postgres/work/pgpopulation/exp_exprpattern/20210316_construct_to_transgene/backup/trp_curator_hst.pg';

# DELETE FROM exp_transgene;
# DELETE FROM exp_construct;
# DELETE FROM trp_name     ;
# DELETE FROM trp_construct;
# DELETE FROM trp_summary  ;
# DELETE FROM trp_paper    ;
# DELETE FROM trp_curator  ;
# 
# DELETE FROM exp_transgene_hst;
# DELETE FROM exp_construct_hst;
# DELETE FROM trp_name_hst     ;
# DELETE FROM trp_construct_hst;
# DELETE FROM trp_summary_hst  ;
# DELETE FROM trp_paper_hst    ;
# DELETE FROM trp_curator_hst  ;

# COPY exp_transgene FROM '/home/postgres/work/pgpopulation/exp_exprpattern/20210316_construct_to_transgene/backup/exp_transgene.pg';
# COPY exp_construct FROM '/home/postgres/work/pgpopulation/exp_exprpattern/20210316_construct_to_transgene/backup/exp_construct.pg';
# COPY trp_name      FROM '/home/postgres/work/pgpopulation/exp_exprpattern/20210316_construct_to_transgene/backup/trp_name.pg';
# COPY trp_construct FROM '/home/postgres/work/pgpopulation/exp_exprpattern/20210316_construct_to_transgene/backup/trp_construct.pg';
# COPY trp_summary   FROM '/home/postgres/work/pgpopulation/exp_exprpattern/20210316_construct_to_transgene/backup/trp_summary.pg';
# COPY trp_paper     FROM '/home/postgres/work/pgpopulation/exp_exprpattern/20210316_construct_to_transgene/backup/trp_paper.pg';
# COPY trp_curator   FROM '/home/postgres/work/pgpopulation/exp_exprpattern/20210316_construct_to_transgene/backup/trp_curator.pg';
# 
# COPY exp_transgene_hst FROM '/home/postgres/work/pgpopulation/exp_exprpattern/20210316_construct_to_transgene/backup/exp_transgene_hst.pg';
# COPY exp_construct_hst FROM '/home/postgres/work/pgpopulation/exp_exprpattern/20210316_construct_to_transgene/backup/exp_construct_hst.pg';
# COPY trp_name_hst      FROM '/home/postgres/work/pgpopulation/exp_exprpattern/20210316_construct_to_transgene/backup/trp_name_hst.pg';
# COPY trp_construct_hst FROM '/home/postgres/work/pgpopulation/exp_exprpattern/20210316_construct_to_transgene/backup/trp_construct_hst.pg';
# COPY trp_summary_hst   FROM '/home/postgres/work/pgpopulation/exp_exprpattern/20210316_construct_to_transgene/backup/trp_summary_hst.pg';
# COPY trp_paper_hst     FROM '/home/postgres/work/pgpopulation/exp_exprpattern/20210316_construct_to_transgene/backup/trp_paper_hst.pg';
# COPY trp_curator_hst   FROM '/home/postgres/work/pgpopulation/exp_exprpattern/20210316_construct_to_transgene/backup/trp_curator_hst.pg';

