#!/usr/bin/perl -w

# repopulate abp_name with IDs WBAntibody0000000n

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my @others = qw( exp_antibody grg_antibody int_antibody );


my %nameToId;
$result = $dbh->prepare( "SELECT abp_publicname.abp_publicname, abp_name.abp_name FROM abp_name, abp_publicname WHERE abp_name.joinkey = abp_publicname.joinkey" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { 
  my (@split) = split/:/, $row[0];
  my $paper = shift @split;
  $paper = lc($paper);
  my $protein = pop @split;
  $protein = lc($protein);
  if ($protein =~ m/anti\-/) { $protein =~ s/anti\-//; }
#   print qq(P $paper P $protein E\n);
  $nameToId{"${paper}:$protein"} = $row[1]; 
  $nameToId{"${paper}::$protein"} = $row[1]; 
  $nameToId{"${paper}:anti-$protein"} = $row[1]; 
  $nameToId{"${paper}::anti-$protein"} = $row[1]; 
#   $nameToId{$row[0]} = $row[1]; 
}

my @pgcommands;
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

