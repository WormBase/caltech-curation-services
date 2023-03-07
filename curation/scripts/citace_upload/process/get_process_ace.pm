package get_process_ace;
require Exporter;

# module to dump prt_ process term objects.  2012 07 17
#
# added goid table.  2013 09 19
#
# removed addEvi for goid => paper for Karen.  2013 09 20
#
# Karen doesn't want to dump paper anymore.  2013 11 01
#
# nodump added.  also relprocess should get valid terms that are not 'NO DUMP'.  2014 01 29
#
# get rid of Related_process, add Specialisation_of and Generalisation_of.  2014 03 26

our @ISA	= qw(Exporter);
our @EXPORT	= qw(getProcess );
our $VERSION	= 1.00;



use strict;
use diagnostics;
use DBI;

use Dotenv -load => '/usr/lib/.env';


my $dbh = DBI->connect ( "dbi:Pg:dbname=$ENV{PSQL_DATABASE};host=$ENV{PSQL_HOST};port=$ENV{PSQL_PORT}", "$ENV{PSQL_USERNAME}", "$ENV{PSQL_PASSWORD}") or die "Cannot connect to database!\n";
# my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my $result;

my %theHash;
# my @tables = qw( processid processname summary othername relprocess remark paper goid );
# my @tables = qw( processid processname summary othername relprocess remark goid nodump );	# karen doesn't want paper anymore 2013 11 01
my @tables = qw( processid processname summary othername specialisationof generalisationof remark goid nodump );	# replace relprocess with specialisationof generalisationof 2014 03 26

my %tableToTag;
# $tableToTag{"processid"}         = 'WBProcess';
$tableToTag{"processname"}       = 'Public_name';
$tableToTag{"summary"}           = 'Summary';
$tableToTag{"othername"}         = 'Other_name';
# $tableToTag{"relprocess"}        = 'Related_process';
$tableToTag{"specialisationof"}  = 'Specialisation_of';
$tableToTag{"generalisationof"}  = 'Generalisation_of';
$tableToTag{"remark"}            = 'Remark';
$tableToTag{"paper"}             = 'Reference';
$tableToTag{"goid"}              = 'GO_term';


my %tableType;
$tableType{"processname"}       = 'text';
$tableType{"summary"}           = 'text';
$tableType{"othername"}         = 'pipe';
# $tableType{"relprocess"}        = 'multi';
$tableType{"specialisationof"}  = 'multi';
$tableType{"generalisationof"}  = 'multi';
$tableType{"remark"}            = 'text';
$tableType{"paper"}             = 'multi';
$tableType{"goid"}              = 'multi';


my %addEvi;			# pg tables that need to have evidence appended to it
# $addEvi{"goid"}        = 'paper';	# paper evidence made sense in pro, but not in prt, Karen 2013 09 20


my $all_entry = '';
# my $allmolecule_entry = '';
my $err_text = '';

my %existing_evidence;				# existing wbpersons and wbpapers
&populateExistingEvidence();

my %dropdown;
&populateDropdown();

my %nameToIDs;							# type -> name -> ids -> count
my %ids;


sub getProcess {
  my ($flag) = shift;

  if ( $flag eq 'all' ) { $result = $dbh->prepare( "SELECT * FROM prt_processid;" ); }				# get all entries 
    else {  $result = $dbh->prepare( "SELECT * FROM prt_processid WHERE prt_processid ~ '$flag';" ); }		# get all entries that match the name
  $result->execute();	
  while (my @row = $result->fetchrow) { $theHash{'processid'}{$row[0]} = $row[1]; $nameToIDs{'processid'}{$row[1]}{$row[0]}++; $ids{$row[0]}++; }
  my $ids = ''; my $qualifier = '';
  if ($flag ne 'all') { $ids = join"','", sort keys %ids; $qualifier = "WHERE joinkey IN ('$ids')"; }
  foreach my $table (@tables) {
    $result = $dbh->prepare( "SELECT * FROM prt_$table $qualifier;" );		# get data for table with qualifier (or not if not)
    $result->execute();	
    while (my @row = $result->fetchrow) { $theHash{$table}{$row[0]} = $row[1]; }
  } # foreach my $table (@tables)

  foreach my $name (sort keys %{ $nameToIDs{'processid'} }) {
    my $entry = '';
    foreach my $joinkey (sort {$a<=>$b} keys %{ $nameToIDs{'processid'}{$name} }) {
      next if ($theHash{'nodump'}{$joinkey});				# added nodump for Karen  2014 01 29
      my $cur_entry = '';
      my $evidence = ''; ($evidence) = &getEvidence($joinkey);	# get the evidence multi-line for the joinkey and box

      foreach my $table (@tables) {
        next unless $tableToTag{$table};
        my $tag = $tableToTag{$table};
        my $dataRef = &getData($table, $joinkey);
        my @data = @$dataRef;
        foreach my $data (@data) {
          if ($data) {
            if ($addEvi{$table}) { $cur_entry .= &addEvi($evidence, "$tag\t$data"); }
              else { $cur_entry .= "$tag\t$data\n"; } } }
      }
      if ($cur_entry) { $entry .= $cur_entry; }		# create the ace entry
    }

    if ($entry) { 					# only if there's an entry, add the object name
      $entry = "WBProcess : \"$name\"\n" . $entry;
      $all_entry .= "$entry\n"; 
    }                  # if .ace object requires a tag, add check here
  } # foreach my $name (sort keys %{ $nameToIDs{'processid'} })

  return( $all_entry, $err_text );
} # sub getProcess


sub getData {
  my ($table, $joinkey) = @_;
  my $data = '';
  my @return_vals; 
  if ($theHash{$table}{$joinkey}) {
    $data = $theHash{$table}{$joinkey};
      if ($tableType{$table} eq 'multi' ) {
        if ($data =~ m/^\"/) { $data =~ s/^\"//; } if ($data =~ m/\"$/) { $data =~ s/\"$//; }
        if ($data =~ m/\",\"/) { 
          my @data = split/\",\"/, $data; 
          foreach my $data (@data) {
            ($data) = &stripForAce($data);
            if ( $dropdown{$table}{$data} ) { 
                if ($table eq 'lifestage') { $data = $dropdown{$table}{$data}; }
                push @return_vals, '"' . $data . '"'; }
              else { $err_text .= '//// ' . "$data in ID $joinkey and table $table not a valid term in obo\n"; } } }
          else { push @return_vals, '"' . $data . '"'; } }
      elsif ($tableType{$table} eq 'pipe' ) {
        my @data = split/\|/, $data; 
        foreach my $data (@data) { 
          ($data) = &stripForAce($data);
          push @return_vals, '"' . $data . '"'; } }
      else  { 
        ($data) = &stripForAce($data);
        push @return_vals, '"' . $data . '"'; } 
  }
  return \@return_vals;
} # sub getData

sub stripForAce {
  my ($data) = @_;
  if ($data =~ m//) { $data =~ s///g; }
  if ($data =~ m/\n/) { $data =~ s/\n/  /g; }
  if ($data =~ m/^\s+/) { $data =~ s/^\s+//g; } if ($data =~ m/\s+$/) { $data =~ s/\s+$//g; }
  if ($data =~ m/\"/) { $data =~ s/\"/\\\"/g; }
  return $data;
} # sub stripForAce


sub addEvi {				# append evidence hash to a line, making it a multi-line line
  my ($evidence, $line) = @_; my $tag_data;
  chomp $line;
  my $line_ts = 0;
  if ($line =~ m/\-O \"[\d]{4}/) { 		# if the line has acedb timestamps
    $tag_data .= "$line\n";			# always print it without evidence (as well as with matching evidence later)
    $line_ts++; }				# flag it to have timestamp
  if ($evidence) {
      my @evidences = split/\n/, $evidence;			# break multi-line evidence into evidence array
      foreach my $evi (@evidences) { 
#         $tag_data .= "$line\t$evi\n"; 
        if ($evi =~ m/Curator_confirmed/) { 	# if curator evidence, check that their acedb timestamp state matches
            my $evi_ts = 0; 
            if ($evi =~ m/\-O\s+\"[\d]{4}/) { $evi_ts++; }			# flag if evidence has timestamp
            if ($evi_ts && $line_ts) { $tag_data .= "$line\t$evi\n"; }		# append lines without timestamp if evidence is without timestamp 
            if (!$evi_ts && !$line_ts) { $tag_data .= "$line\t$evi\n"; }	# append lines with timestamp if evidence is with timestamp 
          }
          else { $tag_data .= "$line\t$evi\n"; }				# always append person and paper evidence
      }
      return $tag_data; }
    else { return "$line\n"; }
} # sub addEvi


sub getEvidence {
  my ($joinkey) = @_; my $evidence;
  if ($theHash{curator}{$joinkey}) { 
    $evidence .= "Curator_confirmed\t\"$theHash{curator}{$joinkey}\"\n"; }
  if ($theHash{person}{$joinkey}) { 
    my @people = split/,/, $theHash{person}{$joinkey};				# break up into people if more than one person
    foreach my $person (@people) { 
      my ($check_evi) = $person =~ m/WBPerson(\d+)/; 
      unless ($check_evi) { $evidence .= "//// ERROR Person $person NOT a valid person\n"; next ; }
      unless ($existing_evidence{person}{$check_evi}) { $evidence .= "//// ERROR Person $person NOT a valid person\n"; next ; }
      $person =~ s/^\s+//g; $evidence .= "Person_evidence\t$person\n"; } }	# already has doublequotes in DB because of phenote 2008 01 30
  if ($theHash{paper}{$joinkey}) {
    if ($theHash{paper}{$joinkey} =~ m/WBPaper\d+/) { 
        my ($check_evi) = $theHash{paper}{$joinkey} =~ m/WBPaper(\d+)/;
        if ($existing_evidence{paper}{$check_evi}) {
            $evidence .= "Paper_evidence\t\"WBPaper$check_evi\"\n"; } 	# 2006 08 23 get the WBPaper, not the data with comments
          else { $evidence .= "//// ERROR Paper $theHash{paper}{$joinkey} NOT a valid paper\n"; } }
      else { $err_text .= '//// ' . "$joinkey has bad paper data $theHash{paper}{$joinkey}\n"; return "ERROR"; } }
  if ($evidence) { return $evidence; }
} # sub getEvidence

sub populateExistingEvidence {		# get hash of valid wbpersons and wbpapers
  my $result = $dbh->prepare( "SELECT * FROM two ORDER BY two" );
  $result->execute();
  while (my @row = $result->fetchrow) {
    $existing_evidence{person}{$row[1]}++; }
  $result = $dbh->prepare( "SELECT * FROM pap_status WHERE pap_status = 'valid'" );
  $result->execute();			# papers now in pap tables, not wpa  2010 08 25
  while (my @row = $result->fetchrow) {
    if ($row[0]) { $existing_evidence{paper}{$row[0]}++; } }
} # sub populateExistingEvidence




sub populateDropdown {
  $result = $dbh->prepare( "SELECT * FROM obo_name_lifestage" );
  $result->execute();			# get from obo_ table instead of obsolete .obo file
  while (my @row = $result->fetchrow) {
    if ($row[0]) { $dropdown{lifestage}{$row[0]} = $row[1]; } }

  $result = $dbh->prepare( "SELECT * FROM obo_name_anatomy" );
  $result->execute();			# get from obo_ table instead of obsolete .obo file
  while (my @row = $result->fetchrow) {
    if ($row[0]) { $dropdown{anatomy}{$row[0]} = $row[1]; } }

  $result = $dbh->prepare( "SELECT * FROM mop_molecule" );
  $result->execute();			# papers now in pap tables, not wpa  2010 08 25
  while (my @row = $result->fetchrow) {
    if ($row[0]) { $dropdown{molecule}{$row[0]} = $row[1]; } }

  $result = $dbh->prepare( "SELECT * FROM obo_name_phenotype" );
  $result->execute();
  while (my @row = $result->fetchrow) {
    if ($row[0]) { $dropdown{phenotype}{$row[0]} = $row[1]; } }

  $result = $dbh->prepare( "SELECT * FROM obo_name_goid" );
  $result->execute();
  while (my @row = $result->fetchrow) {
    if ($row[0]) { $dropdown{goid}{$row[0]} = $row[1]; } }

  $result = $dbh->prepare( "SELECT * FROM obo_name_taxon" );
  $result->execute();
  while (my @row = $result->fetchrow) {
    if ($row[0]) { $dropdown{taxon}{$row[0]} = $row[1]; } }

  $result = $dbh->prepare( "SELECT * FROM obo_name_exprcluster" );
  $result->execute();
  while (my @row = $result->fetchrow) {
    if ($row[0]) { $dropdown{exprcluster}{$row[0]} = $row[1]; } }

  $result = $dbh->prepare( "SELECT * FROM pic_name" );
  $result->execute();
  while (my @row = $result->fetchrow) {
    if ($row[0]) { $dropdown{picture}{$row[1]} = $row[1]; } }

  $result = $dbh->prepare( "SELECT * FROM prt_processid WHERE joinkey NOT IN (SELECT joinkey FROM prt_nodump WHERE prt_nodump = 'NO DUMP')" );
  $result->execute();
  while (my @row = $result->fetchrow) {
    if ($row[0]) { 
#       $dropdown{relprocess}{$row[1]} = "$row[1]";
      $dropdown{specialisationof}{$row[1]} = "$row[1]";
      $dropdown{generalisationof}{$row[1]} = "$row[1]"; } }

  $result = $dbh->prepare( "SELECT * FROM pap_status WHERE pap_status = 'valid'" );
  $result->execute();
  while (my @row = $result->fetchrow) {
    if ($row[0]) { $dropdown{paper}{"WBPaper$row[0]"} = "WBPaper$row[0]"; } }

  $result = $dbh->prepare( "SELECT * FROM gin_wbgene" );
  $result->execute();
  while (my @row = $result->fetchrow) {
    if ($row[0]) { $dropdown{wbgene}{"WBGene$row[0]"} = $row[1]; } }

} # sub populateDropdown



sub filterAce {
  my $identifier = shift;
  if ($identifier =~ m/\//) { $identifier =~ s/\//\\\//g; }
  if ($identifier =~ m/\\/) { $identifier =~ s/\\/\\\\/g; }
  if ($identifier =~ m/\"/) { $identifier =~ s/\"/\\\"/g; }
  if ($identifier =~ m/\s+$/) { $identifier =~ s/\s+$//; }
  if ($identifier =~ m/:/) { $identifier =~ s/:/\\:/g; }
  if ($identifier =~ m/;/) { $identifier =~ s/;/\\;/g; }
  if ($identifier =~ m/,/) { $identifier =~ s/,/\\,/g; }
  if ($identifier =~ m/-/) { $identifier =~ s/-/\\-/g; }
  if ($identifier =~ m/%/) { $identifier =~ s/%/\\%/g; }
  return $identifier;
} # sub filterAce


1;


__END__

