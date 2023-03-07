package get_movie_ace;
require Exporter;

# module to dump mov_ movie objects.  2012 10 15
#
# changed source to dump as Public_name instead of Name.  2013 06 21
#
# changed source back to dump as Name instead of Public_name.  2013 07 02
#
# added mov_dbinfo as a text_text_text, and started dumping mov_paper.  2013 10 10
#
# changed the way database was dumping to have escaped backslashes.  2013 10 14
#
# changed source from Name to Public_name for Daniela, from Paul D change because
# Abby said there was a problem (according to Daniela)  2014 03 12
#
# rewritten for unicode changes  2021 05 16


our @ISA	= qw(Exporter);
our @EXPORT	= qw(getMovie );
our $VERSION	= 1.00;



use strict;
use diagnostics;
use DBI;


use lib qw(  /usr/lib/scripts/perl_modules/ );                      # for general ace dumping functions
# use lib qw( /home/postgres/work/citace_upload/ );               # for general ace dumping functions
use ace_dumper;

use lib qw( /usr/lib/priv/cgi-bin/oa/ );
# use lib qw( /home/postgres/public_html/cgi-bin/oa/ );           # to get tables/fields and which ones to split as multivalue
use wormOA;

my $datatype = 'mov';
my ($fieldsRef, $datatypesRef) = &initModFields($datatype, 'two1823');
my %fields = %$fieldsRef;
my %datatypes = %$datatypesRef;

my $simpleRemapHashRef = &populateSimpleRemap();

my $deadObjectsHashRef = &populateDeadObjects();
my %deadObjects = %$deadObjectsHashRef;


my $dbh = DBI->connect ( "dbi:Pg:dbname=$ENV{PSQL_DATABASE};host=$ENV{PSQL_HOST};port=$ENV{PSQL_PORT}", "$ENV{PSQL_USERNAME}", "$ENV{PSQL_PASSWORD}") or die "Cannot connect to database!\n";
# my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my $result;

my %theHash;
# my @tables = qw( name paper source description rnai exprpattern dbinfo variation remark );

my %tableToTag;
# $tableToTag{"name"}         = "WBMovie";
$tableToTag{"source"}       = "Public_name";
$tableToTag{"paper"}        = "Reference";
$tableToTag{"description"}  = "Description";
$tableToTag{"rnai"}         = "RNAi";
$tableToTag{"exprpattern"}  = "Expr_pattern";
$tableToTag{"dbinfo"}       = "DB_INFO";
$tableToTag{"variation"}    = "Variation";
$tableToTag{"remark"}       = "Remark";

my %ontologyIdToName;

my %tableToOntology;		 # put stuff here if the postgres table doesn't match the deadObjects ontology name

my %pipeSplit;
# $pipeSplit{"rnai"}++;		# daniela doesn't need this anymore  2021 05 19

my %justTag;


# my %addEvi;			# pg tables that need to have evidence appended to it

my $all_entry = '';

$all_entry .= 'Database : "RNAi"' . "\n";
$all_entry .= 'Name "RNAiDB"' . "\n";
$all_entry .= 'URL "http:\/\/www.rnai.org"' . "\n";
$all_entry .= 'URL_constructor "http:\/\/www.rnai.org\/movies\/%s"' . "\n\n";

my $err_text = '';

# DELETE LATER
# my %tableType;
# # $tableType{"name"}          = "text";
# $tableType{"source"}        = "text";
# $tableType{"paper"}         = "ontology";
# $tableType{"description"}   = "text";
# $tableType{"rnai"}          = "pipe";
# $tableType{"exprpattern"}   = "multi";
# $tableType{"dbinfo"}        = "text_text_text";
# $tableType{"variation"}     = "multi";
# $tableType{"remark"}        = "text";
# 
# my %existing_evidence;				# existing wbpersons and wbpapers
# &populateExistingEvidence();
# 
# my %dropdown;
# &populateDropdown();
# END DELETE LATER


my %nameToIDs;							# type -> name -> ids -> count
my %ids;


sub getMovie {
  my ($flag) = shift;

  if ( $flag eq 'all' ) { $result = $dbh->prepare( "SELECT * FROM ${datatype}_name;" ); }				# get all entries 
    else {  $result = $dbh->prepare( "SELECT * FROM ${datatype}_name WHERE ${datatype}_name ~ '$flag';" ); }		# get all entries that match the name
  $result->execute();	
  while (my @row = $result->fetchrow) { $theHash{object}{$row[0]} = $row[1]; $nameToIDs{object}{$row[1]}{$row[0]}++; $ids{$row[0]}++; }
  my $ids = ''; my $qualifier = '';
  if ($flag ne 'all') { $ids = join"','", sort keys %ids; $qualifier = "WHERE joinkey IN ('$ids')"; }

# DELETE LATER
#   foreach my $table (@tables) {
#     $result = $dbh->prepare( "SELECT * FROM mov_$table $qualifier;" );		# get data for table with qualifier (or not if not)
#     $result->execute();	
#     while (my @row = $result->fetchrow) { $theHash{$table}{$row[0]} = $row[1]; }
#   } # foreach my $table (@tables)
#
#   foreach my $name (sort keys %{ $nameToIDs{'name'} }) {
#     my $entry = '';
#     $entry .= "Movie : \"$name\"\n";				# added pgid for debugging  2010 08 25
# 
#     foreach my $joinkey (sort {$a<=>$b} keys %{ $nameToIDs{'name'}{$name} }) {
#       my $cur_entry = '';
#       my $evidence = ''; ($evidence) = &getEvidence($joinkey);	# get the evidence multi-line for the joinkey and box
# 
#       foreach my $table (@tables) {
#         next unless $tableToTag{$table};
#         my $tag = $tableToTag{$table};
#         my $dataRef = &getData($table, $joinkey);
#         my @data = @$dataRef;
#         foreach my $data (@data) {
#           if ($data) {
#             if ($addEvi{$table}) { $cur_entry .= &addEvi($evidence, "$tag\t$data"); }
#               else { $cur_entry .= "$tag\t$data\n"; } } }
#       }
#       if ($cur_entry) { $entry .= $cur_entry; }		# create the ace entry
#     }
# 
#     if ($entry) { $all_entry .= "$entry\n"; }                  # if .ace object requires a tag, add check here
#   } # foreach my $name (sort keys %{ $nameToIDs{'name'} })


  # generic way to query postgres for all OA fields for the datatype, and store in arrays of html encoded entities
  foreach my $table (sort keys %{ $fields{$datatype} }) {
    next if ($table eq 'id');             # skip pgid column
  #   print qq(F $table F\n);
  #   $result = $dbh->prepare( "SELECT * FROM ${datatype}_$table WHERE ${datatype}_$table IS NOT NULL AND joinkey IN ('1', '2', '3');" );
#     $result = $dbh->prepare( "SELECT * FROM ${datatype}_$table WHERE ${datatype}_$table IS NOT NULL;" );
    $result = $dbh->prepare( "SELECT * FROM ${datatype}_$table $qualifier;" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
    while (my @row = $result->fetchrow) {
      next unless $row[1];
      if ($row[1] =~ m/\n/) { $row[1] =~ s/\n/ /g; }
      if ( ($fields{$datatype}{$table}{type} eq 'multiontology') || ($fields{$datatype}{$table}{type} eq 'multidropdown') ) {
        my ($data) = $row[1] =~ m/^\"(.*)\"$/;
        my (@data) = split/\",\"/, $data;
        foreach my $entry (@data) {
          $entry = &utf8ToHtml($simpleRemapHashRef, $entry);
          if ($entry) {
            push @{ $theHash{$table}{$row[0]} }, $entry; } }
      }
      elsif ($pipeSplit{$table}) {
        my (@data) = split/\|/, $row[1];
        foreach my $entry (@data) {
          $entry = &utf8ToHtml($simpleRemapHashRef, $entry);
          if ($entry) {
            push @{ $theHash{$table}{$row[0]} }, $entry; } }
      }
      else {
        my $entry = &utf8ToHtml($simpleRemapHashRef, $row[1]);
        if ($entry) {
          push @{ $theHash{$table}{$row[0]} }, $entry; }
      }
    } # while (my @row = $result->fetchrow)
  } # foreach my $table (sort keys %{ $fields{$datatype} })

  foreach my $name (sort keys %{ $nameToIDs{object} }) {
    my $entry = '';
# my $has_data;
#     $entry .= "\nMovie : \"$name\"\n";

    my %cur_entry;
    foreach my $joinkey (sort {$a<=>$b} keys %{ $nameToIDs{object}{$name} }) {
# print qq(J $joinkey J\n);
      next if ($theHash{nodump}{$joinkey});

      foreach my $field (sort keys %justTag) {
        foreach my $data (@{ $theHash{$field}{$joinkey} }) {
          $cur_entry{qq($data\n)}++; } }

      foreach my $field (sort keys %tableToTag) {
        foreach my $data (@{ $theHash{$field}{$joinkey} }) {
          $data =~ s/\n/ /g; $data =~ s/ +/ /g;     # daniela wants no linebreaks dumped, and multiple spaces converted to a single space 2011 02 09
          ($data) = &filterAce($data);
          if ($data) {
            my $ontology = $field;
            if ($tableToOntology{$field}) { $ontology = $tableToOntology{$field}; }
            my $isGood = 0;
            if ($deadObjects{$ontology}{$data}) {
                $err_text .= "$name has dead $field $data $deadObjects{$ontology}{$data}\n"; }
              elsif ($field eq 'dbinfo') {
                $data =~ s/ /\" \"/g; 			# these dividers need doublequotes in .ace
                $isGood = 1; }
              else { $isGood = 1; }
            if ($isGood) {
              if ($ontologyIdToName{$field}{$data}) { $data = $ontologyIdToName{$field}{$data}; }       # convert ontology ids to names.
              $cur_entry{qq($tableToTag{$field}\t"$data"\n)}++; } } } }

    } # foreach my $joinkey (sort {$a<=>$b} keys %{ $nameToIDs{$type}{$name} })

#     foreach my $line (sort keys %cur_entry) { $entry .= $line; $has_data++; }
#     if ($has_data) { $all_entry .= $entry; }
    foreach my $line (sort keys %cur_entry) { $entry .= $line; }
    if ($entry) {
       $all_entry .= qq(\nMovie : "$name"\n);
       $all_entry .= $entry; }
  } # foreach my $name (sort keys %{ $nameToIDs{$type} })


  return( $all_entry, $err_text );
} # sub getMovie


# DELETE LATER
# sub getData {
#   my ($table, $joinkey) = @_;
#   my $data = '';
#   my @return_vals; 
#   if ($theHash{$table}{$joinkey}) {
#     $data = $theHash{$table}{$joinkey};
#       if ($tableType{$table} eq 'multi' ) {
#         if ($data =~ m/^\"/) { $data =~ s/^\"//; } if ($data =~ m/\"$/) { $data =~ s/\"$//; }
#         if ($data =~ m/\",\"/) { 
#           my @data = split/\",\"/, $data; 
#           foreach my $data (@data) {
#             ($data) = &stripForAce($data);
#             if ( $dropdown{$table}{$data} ) {
#                 if ($table eq 'lifestage') { $data = $dropdown{$table}{$data}; }
#                 push @return_vals, '"' . $data . '"'; }
#               else { $err_text .= '//// ' . "$data in ID $joinkey and table $table not a valid term in obo\n"; } } }
#           else { push @return_vals, '"' . $data . '"'; } }
#       elsif ($tableType{$table} eq 'pipe' ) {
#         my @data = split/\|/, $data; 
#         foreach my $data (@data) { 
#           ($data) = &stripForAce($data);
#           push @return_vals, '"' . $data . '"'; } }
#       elsif ($tableType{$table} eq 'text_text_text' ) {
#         ($data) = &stripForAce($data);
#         $data =~ s/ /\" \"/g; 				# these dividers need doublequotes in .ace
#         push @return_vals, '"' . $data . '"'; } 
#       else  { 
#         ($data) = &stripForAce($data);
#         push @return_vals, '"' . $data . '"'; } 
#   }
#   return \@return_vals;
# } # sub getData
# 
# sub stripForAce {
#   my ($data) = @_;
#   if ($data =~ m//) { $data =~ s///g; }
#   if ($data =~ m/\n/) { $data =~ s/\n/  /g; }
#   if ($data =~ m/^\s+/) { $data =~ s/^\s+//g; } if ($data =~ m/\s+$/) { $data =~ s/\s+$//g; }
#   if ($data =~ m/\"/) { $data =~ s/\"/\\\"/g; }
#   return $data;
# } # sub stripForAce
# 
# 
# sub addEvi {				# append evidence hash to a line, making it a multi-line line
#   my ($evidence, $line) = @_; my $tag_data;
#   chomp $line;
#   my $line_ts = 0;
#   if ($line =~ m/\-O \"[\d]{4}/) { 		# if the line has acedb timestamps
#     $tag_data .= "$line\n";			# always print it without evidence (as well as with matching evidence later)
#     $line_ts++; }				# flag it to have timestamp
#   if ($evidence) {
#       my @evidences = split/\n/, $evidence;			# break multi-line evidence into evidence array
#       foreach my $evi (@evidences) { 
# #         $tag_data .= "$line\t$evi\n"; 
#         if ($evi =~ m/Curator_confirmed/) { 	# if curator evidence, check that their acedb timestamp state matches
#             my $evi_ts = 0; 
#             if ($evi =~ m/\-O\s+\"[\d]{4}/) { $evi_ts++; }			# flag if evidence has timestamp
#             if ($evi_ts && $line_ts) { $tag_data .= "$line\t$evi\n"; }		# append lines without timestamp if evidence is without timestamp 
#             if (!$evi_ts && !$line_ts) { $tag_data .= "$line\t$evi\n"; }	# append lines with timestamp if evidence is with timestamp 
#           }
#           else { $tag_data .= "$line\t$evi\n"; }				# always append person and paper evidence
#       }
#       return $tag_data; }
#     else { return "$line\n"; }
# } # sub addEvi
# 
# 
# sub getEvidence {
#   my ($joinkey) = @_; my $evidence;
#   if ($theHash{curator}{$joinkey}) { 
#     $evidence .= "Curator_confirmed\t\"$theHash{curator}{$joinkey}\"\n"; }
#   if ($theHash{person}{$joinkey}) { 
#     my @people = split/,/, $theHash{person}{$joinkey};				# break up into people if more than one person
#     foreach my $person (@people) { 
#       my ($check_evi) = $person =~ m/WBPerson(\d+)/; 
#       unless ($check_evi) { $evidence .= "//// ERROR Person $person NOT a valid person\n"; next ; }
#       unless ($existing_evidence{person}{$check_evi}) { $evidence .= "//// ERROR Person $person NOT a valid person\n"; next ; }
#       $person =~ s/^\s+//g; $evidence .= "Person_evidence\t$person\n"; } }	# already has doublequotes in DB because of phenote 2008 01 30
#   if ($theHash{paper}{$joinkey}) {
#     if ($theHash{paper}{$joinkey} =~ m/WBPaper\d+/) { 
#         my ($check_evi) = $theHash{paper}{$joinkey} =~ m/WBPaper(\d+)/;
#         if ($existing_evidence{paper}{$check_evi}) {
#             $evidence .= "Paper_evidence\t\"WBPaper$check_evi\"\n"; } 	# 2006 08 23 get the WBPaper, not the data with comments
#           else { $evidence .= "//// ERROR Paper $theHash{paper}{$joinkey} NOT a valid paper\n"; } }
#       else { $err_text .= '//// ' . "$joinkey has bad paper data $theHash{paper}{$joinkey}\n"; return "ERROR"; } }
#   if ($evidence) { return $evidence; }
# } # sub getEvidence



# sub populateExistingEvidence {		# get hash of valid wbpersons and wbpapers
#   my $result = $dbh->prepare( "SELECT * FROM two ORDER BY two" );
#   $result->execute();
#   while (my @row = $result->fetchrow) {
#     $existing_evidence{person}{$row[1]}++; }
#   $result = $dbh->prepare( "SELECT * FROM pap_status WHERE pap_status = 'valid'" );
#   $result->execute();			# papers now in pap tables, not wpa  2010 08 25
#   while (my @row = $result->fetchrow) {
#     if ($row[0]) { $existing_evidence{paper}{$row[0]}++; } }
# } # sub populateExistingEvidence




# sub populateDropdown {
#   $result = $dbh->prepare( "SELECT * FROM obo_name_lifestage" );
#   $result->execute();			# get from obo_ table instead of obsolete .obo file
#   while (my @row = $result->fetchrow) {
#     if ($row[0]) { $dropdown{lifestage}{$row[0]} = $row[1]; } }
# 
#   $result = $dbh->prepare( "SELECT * FROM obo_name_anatomy" );
#   $result->execute();			# get from obo_ table instead of obsolete .obo file
#   while (my @row = $result->fetchrow) {
#     if ($row[0]) { $dropdown{anatomy}{$row[0]} = $row[1]; } }
# 
#   $result = $dbh->prepare( "SELECT * FROM mop_molecule" );
#   $result->execute();			# papers now in pap tables, not wpa  2010 08 25
#   while (my @row = $result->fetchrow) {
#     if ($row[0]) { $dropdown{molecule}{$row[0]} = $row[1]; } }
# 
#   $result = $dbh->prepare( "SELECT * FROM obo_name_phenotype" );
#   $result->execute();
#   while (my @row = $result->fetchrow) {
#     if ($row[0]) { $dropdown{phenotype}{$row[0]} = $row[1]; } }
# 
#   $result = $dbh->prepare( "SELECT * FROM obo_name_goid" );
#   $result->execute();
#   while (my @row = $result->fetchrow) {
#     if ($row[0]) { $dropdown{goid}{$row[0]} = $row[1]; } }
# 
#   $result = $dbh->prepare( "SELECT * FROM obo_name_taxon" );
#   $result->execute();
#   while (my @row = $result->fetchrow) {
#     if ($row[0]) { $dropdown{taxon}{$row[0]} = $row[1]; } }
# 
#   $result = $dbh->prepare( "SELECT * FROM obo_name_exprcluster" );
#   $result->execute();
#   while (my @row = $result->fetchrow) {
#     if ($row[0]) { $dropdown{exprcluster}{$row[0]} = $row[1]; } }
# 
#   $result = $dbh->prepare( "SELECT * FROM pic_name" );
#   $result->execute();
#   while (my @row = $result->fetchrow) {
#     if ($row[0]) { $dropdown{picture}{$row[1]} = $row[1]; } }
# 
#   $result = $dbh->prepare( "SELECT * FROM prt_processid" );
#   $result->execute();
#   while (my @row = $result->fetchrow) {
#     if ($row[0]) { $dropdown{relprocess}{$row[1]} = "$row[1]"; } }
# 
#   $result = $dbh->prepare( "SELECT * FROM pap_status WHERE pap_status = 'valid'" );
#   $result->execute();
#   while (my @row = $result->fetchrow) {
#     if ($row[0]) { $dropdown{paper}{"WBPaper$row[0]"} = "WBPaper$row[0]"; } }
# 
#   $result = $dbh->prepare( "SELECT * FROM gin_wbgene" );
#   $result->execute();
#   while (my @row = $result->fetchrow) {
#     if ($row[0]) { $dropdown{wbgene}{"WBGene$row[0]"} = $row[1]; } }
# 
# } # sub populateDropdown



# sub filterAce {
#   my $identifier = shift;
#   if ($identifier =~ m/\//) { $identifier =~ s/\//\\\//g; }
#   if ($identifier =~ m/\\/) { $identifier =~ s/\\/\\\\/g; }
#   if ($identifier =~ m/\"/) { $identifier =~ s/\"/\\\"/g; }
#   if ($identifier =~ m/\s+$/) { $identifier =~ s/\s+$//; }
#   if ($identifier =~ m/:/) { $identifier =~ s/:/\\:/g; }
#   if ($identifier =~ m/;/) { $identifier =~ s/;/\\;/g; }
#   if ($identifier =~ m/,/) { $identifier =~ s/,/\\,/g; }
#   if ($identifier =~ m/-/) { $identifier =~ s/-/\\-/g; }
#   if ($identifier =~ m/%/) { $identifier =~ s/%/\\%/g; }
#   return $identifier;
# } # sub filterAce


1;


__END__

