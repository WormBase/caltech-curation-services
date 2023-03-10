#!/usr/bin/perl -w

# transfer transgene data to construct OA, from http://wiki.wormbase.org/index.php/All_OA_tables#cns_tables_Construct
# 2014 06 05
#
# changes to constructionsummary, remark, threeutr, publicname  2014 06 30
#
# live on tazendra.  2014 07 15

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my @pgcommands;

my %purification;
$purification{'His-tag'}++; 
$purification{'FLAG'}++; 
$purification{'HA-tag'}++; 
$purification{'MYC/c-myc'}++; 
$purification{'Stag'}++; 
$purification{'Histone H2B'}++;

my %reporterproduct;
$reporterproduct{"GFP"}                       = "GFP";
$reporterproduct{"GFP(S65C)"}                 = "GFP(S65C)";
$reporterproduct{"EGFP"}                      = "EGFP";
$reporterproduct{"pGFP(photoactivated GFP)"}  = "pGFP(photoactivated GFP)";
$reporterproduct{"YFP"}                       = "YFP";
$reporterproduct{"EYFP"}                      = "EYFP";
$reporterproduct{"BFP"}                       = "BFP";
$reporterproduct{"CFP"}                       = "CFP";
$reporterproduct{"Cerulian"}                  = "Cerulian";
$reporterproduct{"RFP"}                       = "RFP";
$reporterproduct{"mRFP"}                      = "mRFP";
$reporterproduct{"tagRFP"}                    = "tagRFP";
$reporterproduct{"mCherry"}                   = "mCherry";
$reporterproduct{"wCherry"}                   = "wCherry";
$reporterproduct{"tdTomato"}                  = "tdTomato";
$reporterproduct{"mStrawberry"}               = "mStrawberry";
$reporterproduct{"DsRed"}                     = "DsRed";
$reporterproduct{"DsRed2"}                    = "DsRed2";
$reporterproduct{"Venus"}                     = "Venus";
$reporterproduct{"YC2.1 (yellow cameleon)"}   = "YC2.1 (yellow cameleon)";
$reporterproduct{"YC12.12 (yellow cameleon)"} = "YC12.12 (yellow cameleon)";
$reporterproduct{"YC3.60 (yellow cameleon)"}  = "YC3.60 (yellow cameleon)";
$reporterproduct{"Yellow cameleon"}           = "Yellow cameleon";
$reporterproduct{"Dendra"}                    = "Dendra";
$reporterproduct{"Dendra2"}                   = "Dendra2";
$reporterproduct{"tdimer2(12)/dimer2"}        = "tdimer2(12)/dimer2";
$reporterproduct{"GCaMP"}                     = "GCaMP";
$reporterproduct{"mkate2"}                    = "mkate2";
$reporterproduct{"Luciferase"}                = "Luciferase";
$reporterproduct{"LacI"}                      = "LacI";
$reporterproduct{"LacO"}                      = "LacO";
$reporterproduct{"LacZ"}                      = "LacZ";

# synonyms was missing in live run, so that part failed.  2014 07 16
my @trp = qw( curator publicname name paper person summary driven_by_gene driven_by_construct gene reporter_product other_reporter reporter_type constructionsummary remark threeutr laboratory );
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

my $cnsPgid = 0;
foreach my $trpPgid (sort {$a<=>$b} keys %{ $trp{curator} }) {
  $cnsPgid++;
  my $constructId = 'WBCnstr' . &pad8Zeros($cnsPgid);
#   print qq($trpPgid\t$cnsPgid\t$constructId\n);
  &addToPg($trpPgid, 'trp_construct', $constructId);
  &addToPg($cnsPgid, 'cns_name', $constructId);
  if ($trp{"curator"}{$trpPgid}) { &addToPg($cnsPgid, 'cns_curator', $trp{"curator"}{$trpPgid}); }
  if ($trp{"paper"}{$trpPgid}) { &addToPg($cnsPgid, 'cns_paper', $trp{"paper"}{$trpPgid}); }
  if ($trp{"person"}{$trpPgid}) { &addToPg($cnsPgid, 'cns_person', $trp{"person"}{$trpPgid}); }
  if ($trp{"summary"}{$trpPgid}) { &addToPg($cnsPgid, 'cns_summary', $trp{"summary"}{$trpPgid}); }
  if ($trp{"driven_by_gene"}{$trpPgid}) { &addToPg($cnsPgid, 'cns_drivenbygene', $trp{"driven_by_gene"}{$trpPgid}); }
  if ($trp{"gene"}{$trpPgid}) { &addToPg($cnsPgid, 'cns_gene', $trp{"gene"}{$trpPgid}); }
  if ($trp{"other_reporter"}{$trpPgid}) { &addToPg($cnsPgid, 'cns_otherreporter', $trp{"other_reporter"}{$trpPgid}); }
  if ($trp{"reporter_type"}{$trpPgid}) { 
    my $constructtype = $trp{"reporter_type"}{$trpPgid};
    if ($constructtype =~ m/ /) { $constructtype =~ s/ /_/g; }
    &addToPg($cnsPgid, 'cns_constructtype', $constructtype); }
  if ($trp{"laboratory"}{$trpPgid}) { &addToPg($cnsPgid, 'cns_laboratory', $trp{"laboratory"}{$trpPgid}); }
  if ($trp{"threeutr"}{$trpPgid}) { &addToPg($cnsPgid, 'cns_threeutr', $trp{"threeutr"}{$trpPgid}); }
#   if ($trp{"threeutr"}{$trpPgid}) { &addToPg($cnsPgid, 'cns_genewithfeature', $trp{"threeutr"}{$trpPgid}); }
#   if ($trp{"threeutr"}{$trpPgid}) { &addToPg($cnsPgid, 'cns_proposedfeature', "3'UTR"); }
  if ($trp{"reporter_product"}{$trpPgid}) {
    my %purificationtag; my %reporter; my %unaccounted;
    $trp{"reporter_product"}{$trpPgid} =~ s/^"//; $trp{"reporter_product"}{$trpPgid} =~ s/"$//;
    my (@list) = split/","/, $trp{"reporter_product"}{$trpPgid};
    foreach my $item (@list) {
      if ($reporterproduct{$item}) { $reporter{$item}++; }
        elsif ($purification{$item}) { $purificationtag{$item}++; }
        else { $unaccounted{$item}++; } }
    my $unaccounted = join'","', sort keys %unaccounted;
    my $purificationtag = join'","', sort keys %purificationtag;
    my $reporter = join'","', sort keys %reporter;
    if ($unaccounted) { print "ERR $unaccounted UNACCOUNTED $trpPgid trp_reporter_product\n"; }
    if ($purificationtag) { 
      $purificationtag = '"' . $purificationtag . '"';
      &addToPg($cnsPgid, 'cns_purificationtag', $purificationtag); }
    if ($reporter) { 
      $reporter = '"' . $reporter . '"';
      &addToPg($cnsPgid, 'cns_reporter', $reporter); }
  } # if ($trp{"reporter_product"}{$trpPgid})

  my @othername;
  if ($trp{"publicname"}{$trpPgid}) {
    if ($trp{"publicname"}{$trpPgid} =~ m/^Expr/) { push @othername, $trp{"publicname"}{$trpPgid}; } }
  if ($trp{"synonym"}{$trpPgid}) {
    if ($trp{"synonym"}{$trpPgid} =~ m/^Expr/) { push @othername, $trp{"synonym"}{$trpPgid}; } }
  if (scalar @othername > 0) { 
    my $othername = join" | ", @othername;
    &addToPg($cnsPgid, 'cns_othername', $othername); }

  my @constructionsummary;
  my $isIsFlag = 0;					# if there's no publicname OR publicname is _not_ Is, transfer construction summary and remark
  if ($trp{"publicname"}{$trpPgid}) {			# if there is a publicname and it is Is, flag it
    if ( ($trp{"publicname"}{$trpPgid} =~ m/[a-z]{2,3}Is\d+/) || ($trp{"publicname"}{$trpPgid} =~ m/WBPaper\d+Is/) ) { $isIsFlag++; } }
  unless ($isIsFlag) {					# is _not_ Is, transfer construction summary and remark
    if ($trp{"constructionsummary"}{$trpPgid}) { push @constructionsummary, $trp{"constructionsummary"}{$trpPgid}; }	
    if ($trp{"remark"}{$trpPgid}) { &addToPg($cnsPgid, 'cns_remark', $trp{"remark"}{$trpPgid}); }
  }
  if ($trp{"driven_by_construct"}{$trpPgid}) { push @constructionsummary, $trp{"driven_by_construct"}{$trpPgid}; }
  if (scalar @constructionsummary > 0) { 
    my $constructionsummary = join" | ", @constructionsummary;
    &addToPg($cnsPgid, 'cns_constructionsummary', $constructionsummary); }
  if ($trp{"constructionsummary"}{$trpPgid}) { 
    if ($trp{"constructionsummary"}{$trpPgid} =~ m/Clone(.*?)$/) { 
      my $clone_stuff = $1;
      if ($clone_stuff =~ m/[\.|].*/) { $clone_stuff =~ s/[\.|].*//; } 
      if ($clone_stuff =~ m/^\s?=\s?/) { $clone_stuff =~ s/^\s?=\s?//; } 
      if ($clone_stuff =~ m/^\s?:\s?/) { $clone_stuff =~ s/^\s?:\s?//; } 
      if ($clone_stuff =~ m/^\s+/) { $clone_stuff =~ s/^\s+//; } 
      if ($clone_stuff =~ m/\s+$/) { $clone_stuff =~ s/\s+$//; } 
#       print "$trpPgid : CLONE $clone_stuff CLONE\n";		# try to extract clone name for cns_publicname  2014 06 10
      &addToPg($cnsPgid, 'cns_publicname', $clone_stuff);
    }
  }
} # foreach my $trpPgid (sort {$a<=>$b} %{ $trp{curator} })

foreach my $command (@pgcommands) {
  print qq($command\n);
# UNCOMMENT TO POPULATE	# 34 minutes to populate
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

