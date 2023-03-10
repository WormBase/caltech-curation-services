#!/usr/bin/perl -w

# transfer expr data to transgene  2012 01 28

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %data;
my %dumpable;

$result = $dbh->prepare( "SELECT * FROM trp_name WHERE trp_name ~ 'Expr.*_Ex' AND joinkey NOT IN (SELECT joinkey FROM trp_objpap_falsepos);" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
# while (my @row = $result->fetchrow) { if ($row[0]) { $row[1] =~ s/^"//; $row[1] =~ s/"$//; $dumpable{$row[1]}++; } }
while (my @row = $result->fetchrow) { if ($row[0]) { $dumpable{$row[1]}++; } }

my @pgcommands;
$result = $dbh->prepare( "SELECT * FROM exp_transgene WHERE exp_transgene ~ '\"Expr.*_Ex\"' AND joinkey IN (SELECT joinkey FROM  exp_reportergene);" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { if ($row[0]) { 
  my $bad = 0;
  $row[1] =~ s/^"//; $row[1] =~ s/"$//; 
  my (@transgenes) = split/","/, $row[1];
  foreach my $transgene (@transgenes) { if ($transgene !~ m/^Expr.*_Ex$/) { $bad++; } }
  if ($bad) { print "ERR non Expr#_Ex transgene in $row[1]\n"; next; }
  foreach my $transgene (@transgenes) { 			# daniela only cares that they're all dumpable, if any are not dumpable she doesn't want a message
    unless ($dumpable{$transgene}) { $bad++; } }
  unless ($bad) {
    push @pgcommands, "INSERT INTO exp_reportergene_hst VALUES ('$row[0]', NULL)";
    push @pgcommands, "DELETE FROM exp_reportergene WHERE joinkey = '$row[0]'";
#   print "DELETE $row[0] $transgene\n"; 
  } 
} }

foreach my $command (@pgcommands) {
  print "$command\n";
# UNCOMMENT TO DELETE
  my $result2 = $dbh->do( $command );
} # foreach my $command (@pgcommands)
      

__END__

my $pgid = &getHighestPgid();


# $result = $dbh->prepare( "SELECT exp_name.exp_name, exp_reportergene.exp_reportergene, exp_paper.exp_paper FROM exp_name, exp_reportergene, exp_paper WHERE exp_name.joinkey NOT IN (SELECT joinkey FROM exp_transgene) AND exp_name.joinkey = exp_reportergene.joinkey AND exp_name.joinkey = exp_paper.joinkey;" );	# this probably gets everything, but if something lacks a name or paper or reportergene it won't work.
$result = $dbh->prepare( "SELECT * FROM exp_reportergene WHERE joinkey NOT IN (SELECT joinkey FROM exp_transgene);" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { if ($row[0]) { $data{rep}{$row[0]} = $row[1]; } }

my $pgids = join"','", sort {$a<=>$b} keys %{ $data{rep} };
$result = $dbh->prepare( "SELECT * FROM exp_name WHERE joinkey IN ('$pgids');" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { if ($row[0]) { $data{name}{$row[0]} = $row[1]; } }
$result = $dbh->prepare( "SELECT * FROM exp_paper WHERE joinkey IN ('$pgids');" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { if ($row[0]) { $data{paper}{$row[0]} = $row[1]; } }

my @pgcommands;

foreach my $pgid  (sort {$a<=>$b} keys %{ $data{rep} }) {
  my $name = ''; my $paper = ''; my $rep = $data{rep}{$pgid};
  if ($data{paper}{$pgid}) { $paper = $data{paper}{$pgid}; } 	# else { print "ERR NO PAPER $pgid\n"; }
  if ($data{name}{$pgid}) { $name = $data{name}{$pgid}; } 	# else { print "ERR NO NAME $pgid\n"; }
  my $transgene = "${name}_Ex"; 
  push @pgcommands, "INSERT INTO exp_transgene VALUES ('$pgid', '$transgene')";
  push @pgcommands, "INSERT INTO exp_transgene_hst VALUES ('$pgid', '$transgene')";
  &addToExpr($transgene, $paper, $rep);
#   print "$pgid\t$name\t$paper\t$rep\n";
} # foreach my $pgid  (sort keys %{ $data{rep} })

foreach my $command (@pgcommands) {
  print "$command\n";
# UNCOMMENT TO TRANSFER DATA
#   my $result2 = $dbh->do( $command );
} # foreach my $command (@pgcommands)

sub addToExpr {
  my ($name, $paper, $remark) = @_;
  if ($remark =~ m/\'/) { $remark =~ s/\'/''/g; }
  my $curator = 'WBPerson12028';
  my $fail = 'Fail';
  $pgid++;
  push @pgcommands, "INSERT INTO trp_name VALUES ('$pgid', '$name')";
  push @pgcommands, "INSERT INTO trp_name_hst VALUES ('$pgid', '$name')";
  push @pgcommands, "INSERT INTO trp_curator VALUES ('$pgid', '$curator')";
  push @pgcommands, "INSERT INTO trp_curator_hst VALUES ('$pgid', '$curator')";
  push @pgcommands, "INSERT INTO trp_objpap_falsepos VALUES ('$pgid', '$fail')";
  push @pgcommands, "INSERT INTO trp_objpap_falsepos_hst VALUES ('$pgid', '$fail')";
  push @pgcommands, "INSERT INTO trp_remark VALUES ('$pgid', '$remark')";
  push @pgcommands, "INSERT INTO trp_remark_hst VALUES ('$pgid', '$remark')";
  if ($paper) {
    push @pgcommands, "INSERT INTO trp_paper VALUES ('$pgid', '$paper')";
    push @pgcommands, "INSERT INTO trp_paper_hst VALUES ('$pgid', '$paper')"; }
} # sub addToExpr

sub getHighestPgid {                                    # get the highest joinkey from the primary tables
  my @highestPgidTables            = qw( name curator );
  my $datatype = 'trp';
  my $pgUnionQuery = "SELECT MAX(joinkey::integer) FROM ${datatype}_" . join" UNION SELECT MAX(joinkey::integer) FROM ${datatype}_", @highestPgidTables;
  my $result = $dbh->prepare( "SELECT max(max) FROM ( $pgUnionQuery ) AS max; " );
  $result->execute(); my @row = $result->fetchrow(); my $highest = $row[0];
  return $highest;
} # sub getHighestPgid




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

