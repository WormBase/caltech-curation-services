#!/usr/bin/perl -w

# populate con_ tables from car_ data.  2011 07 26
#
# live run 2011 09 26

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my @subtypes = qw( curator reference accession );     # changed boxes for carol 2005 05 12

my @maintypes = qw( con ext hum );

my @tables = qw( car_con_ref_reference car_hum_ref_reference );
my @special;

# my @PGsubparameters = qw( seq fpa fpi bio mol exp oth phe );
my @PGsubparameters = qw( seq fpa fpi bio mol exp oth );

foreach my $sub (@PGsubparameters) { 
  my $table = "car_" . $sub . "_ref_reference";
  push @special, $table;
}

my %dataToPap;
my $result = $dbh->prepare( "SELECT * FROM pap_identifier WHERE pap_identifier IS NOT NULL" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  $dataToPap{"WBPaper$row[0]"} = $row[0];
  $dataToPap{$row[1]} = $row[0]; }

my %validExpr;
$result = $dbh->prepare( "SELECT * FROM exp_name " );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  $validExpr{$row[1]}++; }

my $unknown_curator = 'WBPerson13481';

my %curatorToPerson;
$curatorToPerson{"Carol Bastiani"} = 'WBPerson48';
$curatorToPerson{"Erich Schwarz"} = 'WBPerson567';
$curatorToPerson{"Kimberly Van Auken"} = 'WBPerson1843';
$curatorToPerson{"Ranjana Kishore"} = 'WBPerson324';
$curatorToPerson{"Snehalata Kadam"} = 'WBPerson12884';
$curatorToPerson{"Juancarlos Chan"} = 'WBPerson1823';
$curatorToPerson{"Andrei Petcherski"} = 'WBPerson480';
$curatorToPerson{"Paul Sternberg"} = 'WBPerson625';
$curatorToPerson{"Karen Yook"} = 'WBPerson712';
$curatorToPerson{"Raymond Lee"} = 'WBPerson363';
$curatorToPerson{"James Kramer"} = 'WBPerson345';
$curatorToPerson{"Thomas Burglin"} = 'WBPerson83';
$curatorToPerson{"Alison Woollard"} = 'WBPerson699';
$result = $dbh->prepare( "SELECT * FROM two_standardname WHERE two_standardname IN ( 'Massimo Hilliard', 'Verena Gobel', 'James Kramer', 'Graham Goodwin', 'Thomas Burglin', 'Jonathan Hodgkin', 'Thomas Blumenthal', 'Mark Edgley', 'Marie Causey', 'Alison Woollard', 'Ian Hope', 'Geraldine Seydoux', 'Marta Kostrouchova', 'Malcolm Kennedy', 'Berndt Mueller', 'Steven Kleene', 'Michael Koelle', 'Giovanni Lesa', 'Benjamin Leung', 'Robyn Lints', 'Leo Liu', 'Margaret MacMorris' ) ORDER BY two_timestamp" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { my $person = $row[0]; $person =~ s/two/WBPerson/; $curatorToPerson{$row[2]} = $person; }

my %notCurators;
my @notCurators = ( 'Massimo Hilliard', 'Verena Gobel', 'James Kramer', 'Graham Goodwin', 'Thomas Burglin', 'Jonathan Hodgkin', 'Thomas Blumenthal', 'Mark Edgley', 'Marie Causey', 'Alison Woollard', 'Ian Hope', 'Geraldine Seydoux', 'Marta Kostrouchova', 'Malcolm Kennedy', 'Berndt Mueller', 'Steven Kleene', 'Michael Koelle', 'Giovanni Lesa', 'Benjamin Leung', 'Robyn Lints', 'Leo Liu', 'Margaret MacMorris' );
foreach (@notCurators) { $notCurators{$_}++; }

my %subToDesc;
$subToDesc{'con'} = 'Concise_description';
$subToDesc{'ext'} = 'Provisional_description';
$subToDesc{'hum'} = 'Human_disease_relevance';
$subToDesc{'seq'} = 'Sequence_features';
$subToDesc{'fpa'} = 'Functional_pathway';
$subToDesc{'fpi'} = 'Functional_physical_interaction';
$subToDesc{'bio'} = 'Biological_process';
$subToDesc{'mol'} = 'Molecular_function';
$subToDesc{'exp'} = 'Expression';
$subToDesc{'oth'} = 'Other_description';

my %validPerson;
$result = $dbh->prepare( "SELECT * FROM two_status WHERE two_status = 'Valid'" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  $row[0] =~ s/two/WBPerson/;
  $validPerson{$row[0]}++; }

my %geneToCurator;
foreach my $maintype (@maintypes) {
  my $table = "car_${maintype}_ref_reference";
  my $other = $table;
  $other =~ s/reference/curator/;
  my $result = $dbh->prepare( "SELECT * FROM $other WHERE $other IS NOT NULL AND joinkey ~ 'WBGene' AND joinkey != 'WBGene00000000' ORDER BY car_timestamp" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { $geneToCurator{$table}{$row[0]}{1} = $row[1]; }
}
foreach my $table (@special) {
  my $other = $table;
  $other =~ s/reference/curator/;
  my $result = $dbh->prepare( "SELECT * FROM $other WHERE $other IS NOT NULL AND joinkey ~ 'WBGene' AND joinkey != 'WBGene00000000' ORDER BY car_timestamp" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { $geneToCurator{$table}{$row[0]}{$row[1]} = $row[2]; }
}

my %data;

my %nodump;
$result = $dbh->prepare( "SELECT * FROM car_con_nodump WHERE joinkey ~ 'WBGene' AND joinkey != 'WBGene00000000' ORDER BY car_timestamp" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { 
  if ($row[1]) { $nodump{$row[0]} = $row[2]; }
    else { delete $nodump{$row[0]}; } }

my %filter;
foreach my $sub (@PGsubparameters) {
  my $table = "car_" . $sub . "_ref_reference";
# get rid of not null
  my $result = $dbh->prepare( "SELECT * FROM $table WHERE joinkey ~ 'WBGene' AND joinkey != 'WBGene00000000' ORDER BY car_timestamp" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  %filter = ();
  while (my @row = $result->fetchrow) { 
    if ($row[2]) { $filter{$row[0]}{$row[1]} = $row[2]; }
      else { delete $filter{$row[0]}{$row[1]}; } }
  &filterToData($sub, $table, \%filter);

  $table = "car_" . $sub . "_maindata";
  $result = $dbh->prepare( "SELECT * FROM $table WHERE joinkey ~ 'WBGene' AND joinkey != 'WBGene00000000' ORDER BY car_timestamp" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { 
    if ($row[3]) {
      my ($timestamp) = $row[3] =~ m/^(\d{4}\-\d{2}\-\d{2} \d{2}:\d{2}:\d{2})/; 
      unless ($timestamp) { print "NO TIMESTAMP match $row[3] on $row[0] $sub\n"; }
      $data{$row[0]}{$sub}{$row[1]}{lastupdate} = $timestamp; }
    if ($row[2]) { 
        ($row[2]) = &filterForPg($row[2]);
        $data{$row[0]}{$sub}{$row[1]}{desctext} = $row[2]; }
      else { delete $data{$row[0]}{$sub}{$row[1]}{desctext}; } }

  if ($sub eq 'seq') {
    $table = "car_" . $sub . "_ref_accession";
    $result = $dbh->prepare( "SELECT * FROM $table WHERE joinkey ~ 'WBGene' AND joinkey != 'WBGene00000000' ORDER BY car_timestamp" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) { 
      if ($row[2]) { 
          ($row[2]) = &filterForPg($row[2]);
          $data{$row[0]}{$sub}{$row[1]}{accession} = $row[2]; }
        else { delete $data{$row[0]}{$sub}{$row[1]}{accession}; } } }

  $table = "car_" . $sub . "_ref_curator";
  $result = $dbh->prepare( "SELECT * FROM $table WHERE $table IS NOT NULL AND joinkey ~ 'WBGene' AND joinkey != 'WBGene00000000' ORDER BY car_timestamp" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { 
    if ($curatorToPerson{$row[2]}) { 
        if ($notCurators{$row[2]}) { 
            $data{$row[0]}{$sub}{$row[1]}{curator}{$row[3]}{$unknown_curator}++;
            $data{$row[0]}{$sub}{$row[1]}{person}{$curatorToPerson{$row[2]}}++; }
          else { $data{$row[0]}{$sub}{$row[1]}{curator}{$row[3]}{$curatorToPerson{$row[2]}}++; } }
      else { print "$row[0] $sub NO CURATOR $row[2]\n"; } }
} # foreach my $sub (@PGsubparameters)

foreach my $maintype (@maintypes) {
  my $table = "car_" . $maintype . "_maindata";
  my $result = $dbh->prepare( "SELECT * FROM $table WHERE joinkey ~ 'WBGene' AND joinkey != 'WBGene00000000' ORDER BY car_timestamp" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { 
    if ($row[2]) {
      my ($timestamp) = $row[2] =~ m/^(\d{4}\-\d{2}\-\d{2} \d{2}:\d{2}:\d{2})/; 
      unless ($timestamp) { print "NO TIMESTAMP match $row[2] on $row[0] $maintype\n"; }
      $data{$row[0]}{$maintype}{1}{lastupdate} = $timestamp; }
    if ($row[1]) {
        ($row[1]) = &filterForPg($row[1]);
        $data{$row[0]}{$maintype}{1}{desctext} = $row[1]; }
      else { delete $data{$row[0]}{$maintype}{1}{desctext}; } }

  $table = "car_" . $maintype . "_ref_curator";
  $result = $dbh->prepare( "SELECT * FROM $table WHERE $table IS NOT NULL AND joinkey ~ 'WBGene' AND joinkey != 'WBGene00000000' ORDER BY car_timestamp" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { 
    if ($curatorToPerson{$row[1]}) { 
        if ($notCurators{$row[1]}) { 
            $data{$row[0]}{$maintype}{1}{curator}{$row[2]}{$unknown_curator}++;
            $data{$row[0]}{$maintype}{1}{person}{$curatorToPerson{$row[1]}}++; }
          else { $data{$row[0]}{$maintype}{1}{curator}{$row[2]}{$curatorToPerson{$row[1]}}++; } }
      else { print "$row[0] $maintype NO CURATOR $row[1]\n"; } }

  next if ($maintype eq 'ext');				# ext only has maindata and curator

  $table = "car_${maintype}_ref_reference";
  $result = $dbh->prepare( "SELECT * FROM $table WHERE joinkey ~ 'WBGene' ORDER BY car_timestamp" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  %filter = ();
  while (my @row = $result->fetchrow) {
    if ($row[0]) { $filter{$row[0]}{1} = $row[1]; }
      else { delete $filter{$row[0]}{1}; } }
  &filterToData($maintype, $table, \%filter);

  $table = "car_" . $maintype . "_ref_accession";
  $result = $dbh->prepare( "SELECT * FROM $table WHERE joinkey ~ 'WBGene' AND joinkey != 'WBGene00000000' ORDER BY car_timestamp" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { 
    if ($row[1]) { 
        ($row[1]) = &filterForPg($row[1]);
        $data{$row[0]}{$maintype}{1}{accession} = $row[1]; }
      else { delete $data{$row[0]}{$maintype}{1}{accession}; } }

  $table = "car_" . $maintype . "_last_verified";
  $result = $dbh->prepare( "SELECT * FROM $table WHERE joinkey ~ 'WBGene' AND joinkey != 'WBGene00000000' ORDER BY car_timestamp" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { 
    if ($row[2]) { 
        my ($timestamp) = $row[2] =~ m/^(\d{4}\-\d{2}\-\d{2} \d{2}:\d{2}:\d{2})/; 
        unless ($timestamp) { print "NO TIMESTAMP match $row[2] on $row[0] $maintype\n"; }
        $data{$row[0]}{$maintype}{1}{lastupdate} = $timestamp; }
      else { delete $data{$row[0]}{$maintype}{1}{lastupdate}; } }
} # foreach my $maintype (@maintypes)

my $pgid = 0;
foreach my $wbgene (sort keys %data) {
  ($wbgene) = &filterForPg($wbgene);
  foreach my $type (sort keys %{ $data{$wbgene} }) {
    foreach my $order (sort keys %{ $data{$wbgene}{$type} }) {
#       unless ($data{$wbgene}{$type}{$order}{desctext}) { print "NO DESC TEXT $wbgene $type $order\n"; }
      next unless ($data{$wbgene}{$type}{$order}{desctext});		# skip entries without description text
      $pgid++;
      if ($nodump{$wbgene}) { &addToPgAndHistory($wbgene, $type, $order, 'nodump', 'NO DUMP', $nodump{$wbgene}, $pgid); }
      if ($subToDesc{$type}) { &addToPgAndHistory($wbgene, $type, $order, 'desctype', $subToDesc{$type}, '', $pgid); }
        else { print "INVALID SUB/MAINDATA TYPE $type for $wbgene $order\n"; }
      &addToPgAndHistory($wbgene, $type, $order, 'wbgene', $wbgene, '', $pgid);
      &addToPgAndHistory($wbgene, $type, $order, 'curhistory', $pgid, '', $pgid);
      foreach my $table (sort keys %{ $data{$wbgene}{$type}{$order} }) {
        my $data = ''; my $timestamp = '';
        if ($table eq 'curator') {
            foreach $timestamp (sort keys %{ $data{$wbgene}{$type}{$order}{$table} }) {
              foreach $data (sort keys %{ $data{$wbgene}{$type}{$order}{$table}{$timestamp} }) {
                &addToPgAndHistory($wbgene, $type, $order, $table, $data, $timestamp, $pgid); } } }
          else {
            if ( ($table eq 'person') || ($table eq 'paper') ) {
                $data = join'","', sort keys %{ $data{$wbgene}{$type}{$order}{$table} }; $data = '"'. $data . '"'; } 
              elsif ( ($table eq 'exprtext') || ($table eq 'microarray') || ($table eq 'genereg') || ($table eq 'rnai') ) {
                 $data = join', ', sort keys %{ $data{$wbgene}{$type}{$order}{$table} }; }
              else {
                 $data = $data{$wbgene}{$type}{$order}{$table}; }
            &addToPgAndHistory($wbgene, $type, $order, $table, $data, $timestamp, $pgid); }
      } # foreach my $table (sort keys %{ $data{$wbgene}{$type}{$order} })
    } # foreach my $table (sort keys %{ $data{$wbgene}{$type} })
  } # foreach my $type (sort keys %{ $data{$wbgene} })
} # foreach my $wbgene (sort keys %data)

sub addToPgAndHistory {
  my ($wbgene, $type, $order, $table, $data, $timestamp, $pgid) = @_;
  print "$pgid\tW $wbgene\tT $type\tO $order\tT $table\tD $data\tT $timestamp\n";
  my @pgcommands;
  push @pgcommands, "DELETE FROM con_$table WHERE joinkey = '$pgid'";
  if ($timestamp) {
      push @pgcommands, "INSERT INTO con_$table VALUES ('$pgid', '$data', '$timestamp')";
      push @pgcommands, "INSERT INTO con_${table}_hst VALUES ('$pgid', '$data', '$timestamp')"; }
    else {
      push @pgcommands, "INSERT INTO con_$table VALUES ('$pgid', '$data')";
      push @pgcommands, "INSERT INTO con_${table}_hst VALUES ('$pgid', '$data')"; }
  foreach my $pgcommand (@pgcommands) {
    print "$pgcommand\n";
    my $result2 = $dbh->do( $pgcommand );
  }
} # sub addToPgAndHistory


sub filterForPg {
  my $data = shift;
  $data =~ s///g;
  if ($data =~ m/^\s+/) { $data =~ s/^\s+//; } if ($data =~ m/\s+$/) { $data =~ s/\s+$//; }
  if ($data =~ m/\'/) { $data =~ s/\'/''/g; }
  return $data;
} 

sub filterToData {
  my ($sub, $table, $filter_ref) = @_;
  my %filter = %$filter_ref;
  foreach my $joinkey (sort keys %filter) {
    next if ($joinkey eq 'WBGene00000000');
    foreach my $order (sort keys %{ $filter{$joinkey} }) {
      next unless $filter{$joinkey}{$order};
      my $data = $filter{$joinkey}{$order};
      my @data = split/,/, $data;
      my $curator = 'unknown';
      if ($geneToCurator{$table}{$joinkey}{$order}) { $curator = $geneToCurator{$table}{$joinkey}{$order}; }
      foreach my $data (@data) {
        ($data) = &filterForPg($data);
        next unless $data;
        if ($dataToPap{$data}) {                    $data{$joinkey}{$sub}{$order}{paper}{"WBPaper$dataToPap{$data}"}++;  }
          elsif ($validPerson{$data}) {             $data{$joinkey}{$sub}{$order}{person}{$data}++;                      }
#           elsif ($validExpr{$data}) {               $data{$joinkey}{$sub}{$order}{exprpattern}{$data}++;                 }
          elsif ($data =~ m/^Expr\d+$/) {           $data{$joinkey}{$sub}{$order}{exprtext}{$data}++;                    }
          elsif ($data =~ m/^WBRNAi\d+$/) {         $data{$joinkey}{$sub}{$order}{rnai}{$data}++;                        }
          elsif ($data eq 'cgc6432_F47G4.3') {      $data{$joinkey}{$sub}{$order}{genereg}{$data}++;                     }
          elsif ($data eq 'SMD_K07E3.3') {          $data{$joinkey}{$sub}{$order}{microarray}{$data}++;                  }
          else { print "TABLE $table\tCURATOR $curator\tGENE $joinkey\tORDER $order\tDATA $data\n"; }	# uncomment to see bad data from reference tables
      } # foreach my $data (@data)
    } # foreach my $order (sort keys %{ $filter{$joinkey} })
  } # foreach my $joinkey (sort keys %filter)
} # sub filterToData




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

