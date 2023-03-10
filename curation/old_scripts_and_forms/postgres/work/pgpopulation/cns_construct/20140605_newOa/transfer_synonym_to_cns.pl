#!/usr/bin/perl -w

# transfer transgene data to construct OA, from http://wiki.wormbase.org/index.php/All_OA_tables#cns_tables_Construct
# 2014 06 05
#
# changes to constructionsummary, remark, threeutr, publicname  2014 06 30
#
# synonyms did not get transferred by  transfer_trp_to_cns.pl  so doing this separately here.  
# manually delete  cns_othername + cns_othername_hst  before running this script live. 
# live on tazendra.  2014 07 16


use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my @pgcommands;
push @pgcommands, qq(DELETE FROM cns_othername;);
push @pgcommands, qq(DELETE FROM cns_othername_hst;);

my %pgidTransToPgidConst;
$result = $dbh->prepare( "SELECT trp_name.joinkey, trp_name.trp_name, trp_construct.trp_construct FROM trp_name, trp_construct WHERE trp_name.joinkey = trp_construct.joinkey;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) { 
  if ($row[0]) { 
    my ($cnsPgid) = $row[2] =~ m/WBCnstr0+(\d+)/;
    $pgidTransToPgidConst{$row[0]} = $cnsPgid; } }

my @trp = qw( curator publicname synonym );
my %trp;


foreach my $table (@trp) {
  $result = $dbh->prepare( "SELECT * FROM trp_$table WHERE joinkey NOT IN (SELECT joinkey FROM trp_objpap_falsepos WHERE trp_objpap_falsepos = 'Fail')" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    if ($row[0]) { 
      $trp{$table}{$row[0]} = $row[1];
    } # if ($row[0])
  } # while (@row = $result->fetchrow)
}

foreach my $trpPgid (sort {$a<=>$b} keys %{ $trp{curator} }) {
  my $cnsPgid = 0;
  if ($pgidTransToPgidConst{$trpPgid}) { $cnsPgid = $pgidTransToPgidConst{$trpPgid}; }
  my @othername;
  if ($trp{"publicname"}{$trpPgid}) {
    if ($trp{"publicname"}{$trpPgid} =~ m/^Expr/) { push @othername, $trp{"publicname"}{$trpPgid}; } }
  if ($trp{"synonym"}{$trpPgid}) {
    if ( ($trp{"synonym"}{$trpPgid} =~ m/^Expr/) || ($trp{"synonym"}{$trpPgid} =~ m/ Expr/) ) { push @othername, $trp{"synonym"}{$trpPgid}; } }
  if (scalar @othername > 0) { 
    my $othername = join" | ", @othername;
    &addToPg($cnsPgid, 'cns_othername', $othername); }
} # foreach my $trpPgid (sort {$a<=>$b} %{ $trp{curator} })

foreach my $command (@pgcommands) {
  print qq($command\n);
# UNCOMMENT TO POPULATE	
#   $dbh->do($command);
} # foreach my $command (@pgcommands)

sub addToPg {
  my ($pgid, $table, $data) = @_;
  if ($data =~ m/\'/) { $data =~ s/\'/''/g; }
  push @pgcommands, "INSERT INTO $table VALUES ('$pgid', E'$data');";
  push @pgcommands, "INSERT INTO ${table}_hst VALUES ('$pgid', E'$data');";
} # sub addToPg

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

