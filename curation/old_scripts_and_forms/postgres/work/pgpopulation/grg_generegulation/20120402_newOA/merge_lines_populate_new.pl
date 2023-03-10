#!/usr/bin/perl -w

# look at grg tables to try to merge lines with the same grg_name into one pgid line.
# foreach grg_name, get the pgids, then look at all table data and compare to see if anything
# is different. %ignore_field tables are supposed to be different among different pgids.  
# multiontology fields with the same data in different order show as different.  2012 04 02
#
# does not delete superfluous merged rows, just changes the curator to Juancarlos WBPerson1823
# so someone can check it and delete them through the OA.
# live run  2012 04 18


use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;
my @pgcommands;

my %fields;
$fields{grg}{curator}{type}                        = 'dropdown';
$fields{grg}{paper}{type}                          = 'ontology';
$fields{grg}{intid}{type}                          = 'ontology';
$fields{grg}{name}{type}                           = 'text';
$fields{grg}{summary}{type}                        = 'bigtext';
$fields{grg}{antibody}{type}                       = 'multiontology';
$fields{grg}{antibodyremark}{type}                 = 'text';
$fields{grg}{reportergene}{type}                   = 'text';
$fields{grg}{transgene}{type}                      = 'multiontology';
$fields{grg}{insitu}{type}                         = 'toggle_text';
$fields{grg}{insitu_text}{type}                    = 'text';
$fields{grg}{northern}{type}                       = 'toggle_text';
$fields{grg}{northern_text}{type}                  = 'text';
$fields{grg}{western}{type}                        = 'toggle_text';
$fields{grg}{western_text}{type}                   = 'text';
$fields{grg}{rtpcr}{type}                          = 'toggle_text';
$fields{grg}{rtpcr_text}{type}                     = 'text';
$fields{grg}{othermethod}{type}                    = 'toggle_text';
$fields{grg}{othermethod_text}{type}               = 'text';
$fields{grg}{allele}{type}                         = 'multiontology';
$fields{grg}{rnai}{type}                           = 'text';
$fields{grg}{fromrnai}{type}                       = 'toggle';
$fields{grg}{nodump}{type}                         = 'toggle';
$fields{grg}{type}{type}                           = 'multidropdown';
$fields{grg}{regulationlevel}{type}                = 'multidropdown';
$fields{grg}{transregulator}{type}                 = 'multiontology';
$fields{grg}{moleculeregulator}{type}              = 'multiontology';
$fields{grg}{transregulatorseq}{type}              = 'multiontology';
$fields{grg}{otherregulator}{type}                 = 'text';
$fields{grg}{transregulated}{type}                 = 'multiontology';
$fields{grg}{transregulatedseq}{type}              = 'multiontology';
$fields{grg}{otherregulated}{type}                 = 'text';
$fields{grg}{exprpattern}{type}                    = 'multiontology';
$fields{grg}{result}{type}                         = 'dropdown';
$fields{grg}{anat_term}{type}                      = 'multiontology';
$fields{grg}{lifestage}{type}                      = 'multiontology';
$fields{grg}{subcellloc}{type}                     = 'toggle_text';
$fields{grg}{subcellloc_text}{type}                = 'text';
$fields{grg}{remark}{type}                         = 'bigtext';

# my %ignore_field; 				# uncomment to find multilines that should have same data, ignore fields that validly have different data
# $ignore_field{result}++;
# $ignore_field{anat_term}++;
# $ignore_field{lifestage}++;
# $ignore_field{subcellloc}++;
# # $ignore_field{subcellloc_text}++;

my %subtype_field;				# fields that have a subtype
$subtype_field{anat_term}++;
$subtype_field{lifestage}++;
$subtype_field{subcellloc}++;
$subtype_field{subcellloc_text}++;

my %old_table_to_new;
$old_table_to_new{anat_term}       = 'anatomy';
$old_table_to_new{lifestage}       = 'lifestage';
$old_table_to_new{subcellloc}      = 'scl';
$old_table_to_new{subcellloc_text} = 'scltext';

my %newTables;
$newTables{pos_anatomy}++;
$newTables{pos_lifestage}++;
$newTables{pos_scl}++;
$newTables{pos_scltext}++;
$newTables{neg_anatomy}++;
$newTables{neg_lifestage}++;
$newTables{neg_scl}++;
$newTables{neg_scltext}++;
$newTables{not_anatomy}++;
$newTables{not_lifestage}++;
$newTables{not_scl}++;
$newTables{not_scltext}++;

my @names; my %names;			# array to keep it ordered, hash to keep out duplicates
# $result = $dbh->prepare( "SELECT grg_name, COUNT(*) AS count FROM grg_name GROUP BY grg_name HAVING COUNT(*) > 1 ORDER BY COUNT(*) DESC;" );
# $result = $dbh->prepare( "SELECT grg_name, COUNT(*) AS count FROM grg_name GROUP BY grg_name HAVING COUNT(*) = 2 ORDER BY grg_name;" );
$result = $dbh->prepare( "SELECT grg_name FROM grg_name ORDER BY grg_name;" );
# $result = $dbh->prepare( "SELECT grg_name FROM grg_name WHERE joinkey::INTEGER < 10 ORDER BY grg_name;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { if ($row[0]) { 
  unless ($names{$row[0]}) { $names{$row[0]}++; push @names, $row[0]; } } }

foreach my $name (@names) {
  my %lines;
  my @pgids;
  $result = $dbh->prepare( "SELECT * FROM grg_name WHERE grg_name = '$name' ORDER BY joinkey;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { if ($row[0]) { push @pgids, $row[0]; } }
  foreach my $pgid (@pgids) {
    my %data;
    my $result_type = 'NORESULT';
    $result = $dbh->prepare( "SELECT * FROM grg_result WHERE joinkey = '$pgid';" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    my @row = $result->fetchrow();
    if ($row[1]) { 
      if ($row[1] eq 'Does_not_regulate') { $result_type = 'not_'; }
        elsif ($row[1] eq 'Negative_regulate') { $result_type = 'neg_'; }
        elsif ($row[1] eq 'Positive_regulate') { $result_type = 'pos_'; }
        else { print "ERR not a valid result type $row[1] in pgid $pgid\n"; } }
    my @line;
    foreach my $table (sort keys %{ $fields{grg} }) {
#       next if ($ignore_field{$table});		# uncomment to find multilines that should have same data, ignore fields that validly have different data
      $result = $dbh->prepare( "SELECT * FROM grg_$table WHERE joinkey = '$pgid';" );
      $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
      my @row = $result->fetchrow();
      my $data = 'NOTHING'; if ($row[1]) { $data = $row[1]; }
      if ( ($subtype_field{$table}) && ($row[1]) ) {			# field has a subtype and data
        if ($result_type eq 'NORESULT') { print "ERR no result type in $name for $table with $data\n"; }
          else { $table = $result_type . $old_table_to_new{$table}; } }			# change the table
      push @line, "${table}SPAIR\tEPAIR$data";
    } # foreach my $table (sort keys %{ $fields{$grg} })
    my $line = join"SDIV\tEDIV", @line;
    $lines{$line}{$pgid}++;
  } # foreach my $pgid (@pgids)
  my @lines = sort keys %lines;
  my $count = scalar @lines;
  if ($count < 1) { print "NO DATA $name\n"; }
#     elsif ($count == 1) { print "GOOD $name\n"; } 
#     else { print "BAD $name\n"; }
    elsif ($count == 1) { &transferLines(\%lines, $name); }
    else { &transferLines(\%lines, $name); }
#     else { &findDifferenceLines(\@lines, $name); }

} # foreach my $name (@names)

foreach my $pgcommand (@pgcommands) {
#   print "$pgcommand\n";
#   $dbh->do( $pgcommand );		# UNCOMMENT TO POPULATE
} # foreach my $pgcommand (@pgcommands)

sub addToPg {
  my ($name, $pgid, $table, $data) = @_;
#   print "$name\t$pgid\t$table\t$data\n";
  push @pgcommands, "INSERT INTO grg_$table VALUES ('$pgid', '$data');";
  push @pgcommands, "INSERT INTO grg_${table}_hst VALUES ('$pgid', '$data');";
} # sub addToPg

sub deleteRow {
  my ($pgid) = @_;
#   print "DELETE $pgid\n";
  push @pgcommands, "DELETE FROM grg_curator WHERE joinkey = '$pgid';";
  push @pgcommands, "INSERT INTO grg_curator VALUES ('$pgid', 'WBPerson1823');";
  push @pgcommands, "INSERT INTO grg_curator_hst VALUES ('$pgid', 'WBPerson1823');";
}

sub transferLines {
  my ($hash_ref, $name) = @_;
  my %pgids;
  my %hash = %$hash_ref;
  my %data;
  foreach my $line (sort keys %hash) {
    my (@pairs) = split/SDIV\tEDIV/, $line;
    foreach my $pair (@pairs) {
      my ($table, $data) = split/SPAIR\tEPAIR/, $pair;
      next unless ($newTables{$table});
      next if ($data eq 'NOTHING');
# print "T $table D $data\n";
      if ( ($table =~ m/lifestage/) || ($table =~ m/anatomy/) ) { 
          $data =~ s/^\"//; $data =~ s/\"$//;
          my @data = split/","/, $data;
          foreach (@data) { $data{$table}{$_}++; } }
        elsif ($table =~ m/_scltext$/) { $data{$table}{$data}++; }
        elsif ($table eq 'pos_scl') { $data = 'Positive SCL'; $data{$table}{$data}++; }
        elsif ($table eq 'neg_scl') { $data = 'Negative SCL'; $data{$table}{$data}++; }
        elsif ($table eq 'not_scl') { $data = 'Does Not SCL'; $data{$table}{$data}++; }
        else { print "ERR unaccounted table $table in $name with data $data\n"; }
    } # foreach my $pair (@pairs)
    foreach my $pgid (sort keys %{ $hash{$line} }) {
      $pgids{$pgid}++;
    } # foreach my $pgid (sort keys %{ $hash{$pgid} })
  } # foreach my $line (sort keys %hash)

  my @pgids = sort keys %pgids;
  if (scalar @pgids > 2)       { print "ERR $name has more lines than expected @pgids\n"; } 
    elsif (scalar @pgids == 2) { &deleteRow($pgids[1]); }
    elsif (scalar @pgids == 1) { 1; }
    elsif (scalar @pgids < 1)  { print "ERR $name has no pgids to transfer data\n"; }
  my $pgid = $pgids[0];				# transfer to the first pgid

  foreach my $table (sort keys %data) {
    my $data = '';
    if ( ($table =~ m/lifestage/) || ($table =~ m/anatomy/) ) { 
        $data = join'","', sort keys %{ $data{$table} };
        $data = '"' . $data . '"'; }
      else { $data = join'SHOULDNOTHAVEmultipleDATA', sort keys %{ $data{$table} }; }
    &addToPg($name, $pgid, $table, $data);
  } # foreach my $table (sort keys %data)

#   print "$name\t@pgids\n";
} # sub transferLines


sub findDifferenceLines {
  my ($array_ref, $name) = @_;
  my @array = @$array_ref;
  my %data;
  foreach my $line (@array) {
    my (@pairs) = split/SDIV\tEDIV/, $line;
    foreach my $pair (@pairs) {
      my ($table, $data) = split/SPAIR\tEPAIR/, $pair;
      $data{$table}{$data}++; } }
  foreach my $table (sort keys %data) {
    my @data = sort keys %{ $data{$table} };
    my $count = scalar(@data);
    if ($count > 1) { my $data = join" <=> ", @data; print "$name $table HAS $data\n"; } }
} # sub findDifferenceLines

# foreach my $line (@lines) { print "BAD $name\t$line\n"; } }


__END__

  $fields{grg}{id}{type}                             = 'text';
  $fields{grg}{id}{label}                            = 'pgid';
  $fields{grg}{id}{tab}                              = 'tab1';
  $fields{grg}{curator}{type}                        = 'dropdown';
  $fields{grg}{curator}{label}                       = 'Curator';
  $fields{grg}{curator}{tab}                         = 'tab1';
  $fields{grg}{curator}{dropdown_type}               = 'curator';
  $fields{grg}{paper}{type}                          = 'ontology';
  $fields{grg}{paper}{label}                         = 'Reference';
  $fields{grg}{paper}{tab}                           = 'tab1';
  $fields{grg}{paper}{ontology_type}                 = 'WBPaper';
  $fields{grg}{intid}{type}                          = 'ontology';
  $fields{grg}{intid}{label}                         = 'Interaction ID';
  $fields{grg}{intid}{tab}                           = 'tab1';
  $fields{grg}{intid}{ontology_type}                 = 'WBInteraction';
  $fields{grg}{name}{type}                           = 'text';
  $fields{grg}{name}{label}                          = 'Name';
  $fields{grg}{name}{tab}                            = 'tab1';
  $fields{grg}{summary}{type}                        = 'bigtext';
  $fields{grg}{summary}{label}                       = 'Summary';
  $fields{grg}{summary}{tab}                         = 'tab1';
  $fields{grg}{antibody}{type}                       = 'multiontology';
  $fields{grg}{antibody}{label}                      = 'Antibody Info';
  $fields{grg}{antibody}{tab}                        = 'tab1';
  $fields{grg}{antibody}{ontology_type}              = 'Antibody';
  $fields{grg}{antibodyremark}{type}                 = 'text';
  $fields{grg}{antibodyremark}{label}                = 'Antibody Remark';
  $fields{grg}{antibodyremark}{tab}                  = 'tab1';
  $fields{grg}{reportergene}{type}                   = 'text';
  $fields{grg}{reportergene}{label}                  = 'Reporter Gene';
  $fields{grg}{reportergene}{tab}                    = 'tab1';
  $fields{grg}{transgene}{type}                      = 'multiontology';
  $fields{grg}{transgene}{label}                     = 'Transgene';
  $fields{grg}{transgene}{tab}                       = 'tab1';
  $fields{grg}{transgene}{ontology_type}             = 'Transgene';
  $fields{grg}{insitu}{type}                         = 'toggle_text';
  $fields{grg}{insitu}{label}                        = 'In Situ';
  $fields{grg}{insitu}{tab}                          = 'tab1';
  $fields{grg}{insitu}{inline}                       = 'insitu_text';
  $fields{grg}{insitu_text}{type}                    = 'text';
  $fields{grg}{insitu_text}{label}                   = 'IS Text';
  $fields{grg}{insitu_text}{tab}                     = 'tab1';
  $fields{grg}{insitu_text}{inline}                  = 'INSIDE_insitu_text';
  $fields{grg}{northern}{type}                       = 'toggle_text';
  $fields{grg}{northern}{label}                      = 'Northern';
  $fields{grg}{northern}{tab}                        = 'tab1';
  $fields{grg}{northern}{inline}                     = 'northern_text';
  $fields{grg}{northern_text}{type}                  = 'text';
  $fields{grg}{northern_text}{label}                 = 'N Text';
  $fields{grg}{northern_text}{tab}                   = 'tab1';
  $fields{grg}{northern_text}{inline}                = 'INSIDE_northern_text';
  $fields{grg}{western}{type}                        = 'toggle_text';
  $fields{grg}{western}{label}                       = 'Western';
  $fields{grg}{western}{tab}                         = 'tab1';
  $fields{grg}{western}{inline}                      = 'western_text';
  $fields{grg}{western_text}{type}                   = 'text';
  $fields{grg}{western_text}{label}                  = 'W Text';
  $fields{grg}{western_text}{tab}                    = 'tab1';
  $fields{grg}{western_text}{inline}                 = 'INSIDE_western_text';
  $fields{grg}{rtpcr}{type}                          = 'toggle_text';
  $fields{grg}{rtpcr}{label}                         = 'RT PCR';
  $fields{grg}{rtpcr}{tab}                           = 'tab1';
  $fields{grg}{rtpcr}{inline}                        = 'rtpcr_text';
  $fields{grg}{rtpcr_text}{type}                     = 'text';
  $fields{grg}{rtpcr_text}{label}                    = 'RP Text';
  $fields{grg}{rtpcr_text}{tab}                      = 'tab1';
  $fields{grg}{rtpcr_text}{inline}                   = 'INSIDE_rtpcr_text';
  $fields{grg}{othermethod}{type}                    = 'toggle_text';
  $fields{grg}{othermethod}{label}                   = 'Other Method';
  $fields{grg}{othermethod}{tab}                     = 'tab1';
  $fields{grg}{othermethod}{inline}                  = 'othermethod_text';
  $fields{grg}{othermethod_text}{type}               = 'text';
  $fields{grg}{othermethod_text}{label}              = 'OM Text';
  $fields{grg}{othermethod_text}{tab}                = 'tab1';
  $fields{grg}{othermethod_text}{inline}             = 'INSIDE_othermethod_text';
  $fields{grg}{allele}{type}                         = 'multiontology';
  $fields{grg}{allele}{label}                        = 'Allele';
  $fields{grg}{allele}{tab}                          = 'tab1';
  $fields{grg}{allele}{ontology_type}                = 'obo';
  $fields{grg}{allele}{ontology_table}               = 'variation';
  $fields{grg}{rnai}{type}                           = 'text';
  $fields{grg}{rnai}{label}                          = 'RNAi';
  $fields{grg}{rnai}{tab}                            = 'tab1';
  $fields{grg}{fromrnai}{type}                       = 'toggle';
  $fields{grg}{fromrnai}{label}                      = 'From RNAi';
  $fields{grg}{fromrnai}{tab}                        = 'tab1';
  $fields{grg}{nodump}{type}                         = 'toggle';
  $fields{grg}{nodump}{label}                        = 'NO DUMP';
  $fields{grg}{nodump}{tab}                          = 'tab1';
  $fields{grg}{type}{type}                           = 'multidropdown';
  $fields{grg}{type}{label}                          = 'Type';
  $fields{grg}{type}{tab}                            = 'tab2';
  $fields{grg}{type}{dropdown_type}                  = 'grgtype';
  $fields{grg}{regulationlevel}{type}                = 'multidropdown';
  $fields{grg}{regulationlevel}{label}               = 'Regulation Level';
  $fields{grg}{regulationlevel}{tab}                 = 'tab2';
  $fields{grg}{regulationlevel}{dropdown_type}       = 'regulationlevel';
  $fields{grg}{transregulator}{type}                 = 'multiontology';
  $fields{grg}{transregulator}{label}                = 'Trans Regulator Gene';
  $fields{grg}{transregulator}{tab}                  = 'tab2';
  $fields{grg}{transregulator}{ontology_type}        = 'WBGene';
  $fields{grg}{moleculeregulator}{type}              = 'multiontology';
  $fields{grg}{moleculeregulator}{label}             = 'Molecule Regulator';
  $fields{grg}{moleculeregulator}{tab}               = 'tab2';
  $fields{grg}{moleculeregulator}{ontology_type}     = 'Molecule';
  $fields{grg}{transregulatorseq}{type}              = 'multiontology';	# x wants text instead of gin_sequence 2011 03 16 # want multiontology 2012 03 28
  $fields{grg}{transregulatorseq}{label}             = 'Trans Regulator Seq';
  $fields{grg}{transregulatorseq}{tab}               = 'tab2';
  $fields{grg}{transregulatorseq}{ontology_type}     = 'WBSequence';
  $fields{grg}{otherregulator}{type}                 = 'text';
  $fields{grg}{otherregulator}{label}                = 'Other Regulator';
  $fields{grg}{otherregulator}{tab}                  = 'tab2';
  $fields{grg}{transregulated}{type}                 = 'multiontology';
  $fields{grg}{transregulated}{label}                = 'Trans Regulated Gene';
  $fields{grg}{transregulated}{tab}                  = 'tab2';
  $fields{grg}{transregulated}{ontology_type}        = 'WBGene';
  $fields{grg}{transregulatedseq}{type}              = 'multiontology';	# x wants text instead of gin_sequence 2011 03 16 # want multiontology 2012 03 28
  $fields{grg}{transregulatedseq}{label}             = 'Trans Regulated Seq';
  $fields{grg}{transregulatedseq}{tab}               = 'tab2';
  $fields{grg}{transregulatedseq}{ontology_type}     = 'WBSequence';
  $fields{grg}{otherregulated}{type}                 = 'text';
  $fields{grg}{otherregulated}{label}                = 'Other Regulated';
  $fields{grg}{otherregulated}{tab}                  = 'tab2';
  $fields{grg}{exprpattern}{type}                    = 'multiontology';
  $fields{grg}{exprpattern}{label}                   = 'Expression Pattern';
  $fields{grg}{exprpattern}{tab}                     = 'tab2';
  $fields{grg}{exprpattern}{ontology_type}           = 'Expr';
  $fields{grg}{result}{type}                         = 'dropdown';
  $fields{grg}{result}{label}                        = 'Result';
  $fields{grg}{result}{tab}                          = 'tab3';
  $fields{grg}{result}{dropdown_type}                = 'regulates';
  $fields{grg}{anat_term}{type}                      = 'multiontology';
  $fields{grg}{anat_term}{label}                     = 'Anatomy Term';
  $fields{grg}{anat_term}{tab}                       = 'tab3';
  $fields{grg}{anat_term}{ontology_type}             = 'obo';
  $fields{grg}{anat_term}{ontology_table}            = 'anatomy';
  $fields{grg}{lifestage}{type}                      = 'multiontology';
  $fields{grg}{lifestage}{label}                     = 'Life Stage';
  $fields{grg}{lifestage}{tab}                       = 'tab3';
  $fields{grg}{lifestage}{ontology_type}             = 'obo';
  $fields{grg}{lifestage}{ontology_table}            = 'lifestage';
  $fields{grg}{subcellloc}{type}                     = 'toggle_text';
  $fields{grg}{subcellloc}{label}                    = 'Subcellular Localization';
  $fields{grg}{subcellloc}{tab}                      = 'tab3';
  $fields{grg}{subcellloc}{inline}                   = 'subcellloc_text';
  $fields{grg}{subcellloc_text}{type}                = 'text';
  $fields{grg}{subcellloc_text}{label}               = 'SCL Text';
  $fields{grg}{subcellloc_text}{tab}                 = 'tab3';
  $fields{grg}{subcellloc_text}{inline}              = 'INSIDE_subcellloc_text';
  $fields{grg}{remark}{type}                         = 'bigtext';
  $fields{grg}{remark}{label}                        = 'Remark';
  $fields{grg}{remark}{tab}                          = 'tab3';
  @{ $datatypes{grg}{constraintTablesHaveData} }     = qw( paper name summary );
  @{ $datatypes{grg}{highestPgidTables} }            = qw( name curator );
  $datatypes{grg}{newRowSub}                         = \&newRowGrg;
  $datatypes{grg}{label}                             = 'genereg';
