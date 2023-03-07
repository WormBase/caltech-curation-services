package get_transgene_ace;
require Exporter;


our @ISA	= qw(Exporter);
our @EXPORT	= qw( getTransgene );
our $VERSION	= 1.00;

# dump transgene data.  for Karen.  2012 06 22
#
# added historical gene stuff, and also added invalid papers while was doing that.  2013 05 22
#
# added coinjection and constructionsummary, changed constraint for constructionsummary.  2013 07 17
#
# tables reporter_product and other_reporter dump to .ace tag Reporter_product, but reporter_product is
# multiontology that should split on "," while other_reporter is text that should split on |  so changed
# &printTag  to include the table name for those two tables, and basing it off the table instead of the 
# tag just for this case.  2013 09 13
#
# changed gin_dead to not have just "Dead" or "split_into / merged_into", now it has Dead / Suppressed / merged_into / split_into independent of
# each other (all merged / split must be dead though), so Chris has made a precedece for how to treat them (split > merged > suppressed > dead),
# and the dumper makes the Historical_gene comments appropriately.  2013 10 21
#
# removed from dumping : driven_by_gene reporter_product other_reporter gene threeutr reporter_type driven_by_construct
# would have removed : clone  but it's not being dumped.
# have not removed the tables, needs to be done later.  2014 07 08
#
# removed particle bombardment  2016 02 16
#
# split Coinjection because it's multivalue.  2016 03 14
#
# chris wants leading  doublequotes dumped  2016 08 13
#
# changed strains to multiontology field.  2019 09 23
#
# strip leading and trailing whitespace from data before output.  2019 09 30
#
# set array_state if some conditions are true, otherwise set to Not_Reported.  for Karen.  2020 03 30
#
# add to err.out : all duplicated WBTransgeneIDs (trp_name) + all duplicated public_names (trp_publicname).  2020 05 04
#
# always skip trp_objpap_falsepos when getting data from db.  2022 10 15





use strict;
use diagnostics;
use LWP;
use LWP::Simple;
use DBI;

use Dotenv -load => '/usr/lib/.env';


my $dbh = DBI->connect ( "dbi:Pg:dbname=$ENV{PSQL_DATABASE};host=$ENV{PSQL_HOST};port=$ENV{PSQL_PORT}", "$ENV{PSQL_USERNAME}", "$ENV{PSQL_PASSWORD}") or die "Cannot connect to database!\n";
# my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my $result;

# my @tables = qw( name publicname summary driven_by_gene reporter_product other_reporter gene threeutr integration_method particle_bombardment strain map map_paper map_person marker_for marker_for_paper paper person reporter_type remark species synonym driven_by_construct laboratory objpap_falsepos mergedinto coinjection constructionsummary );	# these were valid 2013 10 21, some moved to construct 2014 07 08
# my @tables = qw( name publicname summary construct coinjectionconstruct integratedfrom integration_method variation particle_bombardment strain map map_paper map_person marker_for marker_for_paper paper person remark species synonym laboratory objpap_falsepos mergedinto coinjection constructionsummary );
my @tables = qw( name publicname summary construct coinjectionconstruct integratedfrom integration_method variation strain map map_paper map_person marker_for marker_for_paper paper person remark species synonym laboratory objpap_falsepos mergedinto coinjection constructionsummary );

my %hash;

my $all_entry = '';
my $err_text = '';

my %deadObjects;

my %allele_to_lab;			# get mapping of allele codes to lab codes from obo table

sub getAlleleToLab {
  $result = $dbh->prepare( "SELECT * FROM obo_data_laboratory WHERE obo_data_laboratory ~ 'Allele_designation: ';" );
  $result->execute();	
  while (my @row = $result->fetchrow) { 
    my ($alleleDesignation) = $row[1] =~ m/Allele_designation: (\S+)/;
#     unless ($alleleDesignation) { print "MISS: $row[1]\n"; }
    $allele_to_lab{$alleleDesignation} = $row[0]; }
} # sub getAlleleToLab


1;

sub getTransgene {
  my ($flag) = shift;

#   &updateAlleleToLab();
  &getAlleleToLab();

  my %nameToIDs;							# type -> name -> ids -> count
  my %ids;
  &populateDeadObjects();

  my %byTableData;

  if ( $flag eq 'all' ) { $result = $dbh->prepare( "SELECT * FROM trp_name WHERE joinkey NOT IN (SELECT joinkey FROM trp_objpap_falsepos WHERE trp_objpap_falsepos = 'Fail'); " ); }		# get all entries for type
    else { $result = $dbh->prepare( "SELECT * FROM trp_name WHERE trp_name = '$flag' AND joinkey NOT IN (SELECT joinkey FROM trp_objpap_falsepos WHERE trp_objpap_falsepos = 'Fail');" ); }	# get all entries for type of object name
  $result->execute();	
  while (my @row = $result->fetchrow) { $hash{object}{$row[0]} = $row[1]; $nameToIDs{object}{$row[1]}{$row[0]}++; $ids{$row[0]}++; }
  my $ids = ''; my $qualifier = '';
  if ($flag ne 'all') { $ids = join"','", sort keys %ids; $qualifier = "AND joinkey IN ('$ids')"; }
  foreach my $table (@tables) {
    $result = $dbh->prepare( "SELECT * FROM trp_$table WHERE joinkey NOT IN (SELECT joinkey FROM trp_objpap_falsepos WHERE trp_objpap_falsepos = 'Fail') $qualifier ;" );		# get data for table with qualifier (or not if not)
    $result->execute();	
    while (my @row = $result->fetchrow) { 
      $byTableData{$table}{$row[1]}{$row[0]}++;
      $hash{$table}{$row[0]} = $row[1]; }
  } # foreach my $table (@tables)

  foreach my $name (sort keys %{ $nameToIDs{object} }) {
    foreach my $joinkey (sort {$a<=>$b} keys %{ $nameToIDs{object}{$name} }) {
      next if ($hash{objpap_falsepos}{$joinkey});	# skip fail entries  2010 08 26
      next if ($hash{mergedinto}{$joinkey});		# skip merged entries  2012 08 29
      next unless ($hash{name}{$joinkey});		# skip deleted ones without name  2008 10 30
#       next unless ( ($hash{summary}{$joinkey}) || ($hash{remark}{$joinkey}) );	# skip unless it has either summary or remark (for Karen) 2010 08 26
      next unless ( ($hash{summary}{$joinkey}) || ($hash{constructionsummary}{$joinkey}) );	# skip unless it has either summary or constructionsummary (for Karen) 2013 07 17
      $all_entry .= "\nTransgene : \"$name\"\n";

      my $array_state = '';				# set if some conditions are true, otherwise set to Not_Reported.  for Karen.  2020 03 30
      if ($hash{publicname}{$joinkey}) {
# if ($joinkey eq '10128') { print qq(J $joinkey J $hash{publicname}{$joinkey} E\n); }
#         if ( ($hash{publicname}{$joinkey} =~ m/[a-z]+Ex\d+/) || ($hash{publicname}{$joinkey} =~ m/WBPaper\d+Ex\d+/) ) { 
# if ($hash{publicname}{$joinkey} eq 'WBPaper00035430Ex7') {
#  print qq(MATCH $hash{publicname}{$joinkey} set array_state\n);
# if ($joinkey eq '10128') { print qq(J $joinkey SET STATE $hash{publicname}{$joinkey} J\n); }
# }
# #           &printTag('Extrachromosomal'); 
#             $array_state = 'Extrachromosomal'; }
#           elsif ( ($hash{publicname}{$joinkey} =~ m/[a-z]+Ti\d+/) || ($hash{publicname}{$joinkey} =~ m/WBPaper\d+Ti\d+/) ||
#              ($hash{publicname}{$joinkey} =~ m/[a-z]+In\d+/) || ($hash{publicname}{$joinkey} =~ m/WBPaper\d+In\d+/) ||
#              ($hash{publicname}{$joinkey} =~ m/[a-z]+Is\d+/) || ($hash{publicname}{$joinkey} =~ m/WBPaper\d+Is\d+/) ||
#              ($hash{publicname}{$joinkey} =~ m/[a-z]+Si\d+/) || ($hash{publicname}{$joinkey} =~ m/WBPaper\d+Si\d+/) ) { 
#             $array_state = 'Integrated'; }
        if ($hash{publicname}{$joinkey} =~ m/Ex/) { $array_state = 'Extrachromosomal'; }
          elsif ( ($hash{publicname}{$joinkey} =~ m/Ti/) || ($hash{publicname}{$joinkey} =~ m/In/) || 
                  ($hash{publicname}{$joinkey} =~ m/Is/) || ($hash{publicname}{$joinkey} =~ m/Si/) ) {
            $array_state = 'Integrated'; } 
          else { $err_text .= qq($joinkey\t$name\tInvalid publicname\t$hash{publicname}{$joinkey}\n); } }
      if ($hash{publicname}{$joinkey}) { &printTag('Public_name', $hash{publicname}{$joinkey}); }
      if ($hash{summary}{$joinkey}) { &printTag('Summary', $hash{summary}{$joinkey}); }
      if ($hash{construct}{$joinkey}) { &printTag('Construct', $hash{construct}{$joinkey}); }
      if ($hash{coinjectionconstruct}{$joinkey}) { &printTag('Coinjection', $hash{coinjectionconstruct}{$joinkey}); }
      if ($hash{coinjection}{$joinkey}) { &printTag('Coinjection_other', $hash{coinjection}{$joinkey}); }
      if ($hash{integratedfrom}{$joinkey}) { &printTag('Integrated_from', $hash{integratedfrom}{$joinkey}); }
      if ($hash{constructionsummary}{$joinkey}) { &printTag('Construction_summary', $hash{constructionsummary}{$joinkey}); }
#       if ($hash{reporter_product}{$joinkey}) { &printTag('Reporter_product', $hash{reporter_product}{$joinkey}, $joinkey, 'reporter_product'); }	# removed 2014 07 18
#       if ($hash{other_reporter}{$joinkey}) { &printTag('Reporter_product', $hash{other_reporter}{$joinkey}, $joinkey, 'other_reporter'); }	# removed 2014 07 18
#       if ($hash{driven_by_gene}{$joinkey}) { &printTag('Driven_by_gene', $hash{driven_by_gene}{$joinkey}, $joinkey); }	# removed 2014 07 08
#       if ($hash{gene}{$joinkey}) { &printTag('Gene', $hash{gene}{$joinkey}, $joinkey); }	# removed 2014 07 08
#       if ($hash{threeutr}{$joinkey}) { &printTag('3_UTR', $hash{threeutr}{$joinkey}, $joinkey); }	# removed 2014 07 08
      if ($hash{integration_method}{$joinkey}) { 
        &printTag('Integration_method', $hash{integration_method}{$joinkey}); 
#         &printTag('Integrated'); 
        unless ($array_state) {
          if ($hash{integration_method}{$joinkey} ne 'Particle_bombardment') {
            $array_state = 'Integrated'; } }
      }
      if ($hash{variation}{$joinkey}) { &printTag('Corresponding_variation', $hash{variation}{$joinkey}); }
#       if ($hash{particle_bombardment}{$joinkey}) { &printTag('Particle_bombardment', $hash{particle_bombardment}{$joinkey}); }
      if ($hash{strain}{$joinkey}) { &printTag('Strain', $hash{strain}{$joinkey}); }
      if ($hash{map}{$joinkey}) { &printTag('Map', $hash{map}{$joinkey}); }
      if ($hash{map_person}{$joinkey}) { &printTag("Map_evidence\tPerson_evidence", $hash{map_person}{$joinkey}); }
      if ($hash{map_paper}{$joinkey}) { &printTag("Map_evidence\tPaper_evidence", $hash{map_paper}{$joinkey}, $joinkey); }
#       if ($hash{map_paper}{$joinkey}) { my $value = $hash{paper}{$joinkey};
#         if ($deadObjects{paper}{$value}) { $err_text .= qq($name\tInvalid map_paper\t"$value"\t$deadObjects{paper}{$value}\n); }
#           else { &printTag("Map_evidence\tPaper_evidence", $hash{map_paper}{$joinkey}); } }
      if ($hash{marker_for}{$joinkey}) { &printTag('Marker_for', $hash{marker_for}{$joinkey}, $joinkey); }
      if ($hash{paper}{$joinkey}) { &printTag('Reference', $hash{paper}{$joinkey}, $joinkey); }
#       if ($hash{paper}{$joinkey}) { my $value = $hash{paper}{$joinkey};
#         if ($deadObjects{paper}{$value}) { $err_text .= qq($name\tInvalid paper\t"$value"\t$deadObjects{paper}{$value}\n); }
#           else { &printTag('Reference', $hash{paper}{$joinkey}); } }
#       if ($hash{person}{$joinkey}) { &printTag('Person', $hash{person}{$joinkey}); }	# tag not in model yet
#       if ($hash{reporter_type}{$joinkey}) { &printTag('Reporter_type', $hash{reporter_type}{$joinkey}); }	# removed 2014 07 08
#       if ($hash{rescues}{$joinkey}) { &printTag('Rescue', $hash{rescues}{$joinkey}); }
      if ($hash{remark}{$joinkey}) { &printTag('Remark', $hash{remark}{$joinkey}); }
      if ($hash{species}{$joinkey}) { &printTag('Species', $hash{species}{$joinkey}); }
      if ($hash{synonym}{$joinkey}) { &printTag('Synonym', $hash{synonym}{$joinkey}); }
#       if ($hash{driven_by_construct}{$joinkey}) { &printTag('Driven_by_construct', $hash{driven_by_construct}{$joinkey}); }	# removed 2014 07 08
#       if ($hash{movie}{$joinkey}) { &printTag('Movie', $hash{movie}{$joinkey}); }
#       if ($hash{picture}{$joinkey}) { &printTag('Picture', $hash{picture}{$joinkey}); }
      if ($hash{laboratory}{$joinkey}) { &printTag('Laboratory', $hash{laboratory}{$joinkey}); }			# normal case
        else {
          if ($hash{name}{$joinkey} =~ m/^([a-z]+)[A-Z]/) { my $allele_name = $1;				# get allele code from transgene name
            if ($allele_to_lab{$allele_name}) { &printTag('Laboratory', $allele_to_lab{$allele_name}); }	# get laboratory from mapping if exists
               else { $err_text .= "$hash{name}{$joinkey} has neither laboratory nor allele to lab mapping\n"; } } }	# warn if there's no laboratory
#       unless ($array_state) { $array_state = 'Not_Reported'; }	# put this back when it's in the model 2020 03 30
      if ($array_state) { &printTag($array_state); }
      $all_entry .= "\n";
    } # foreach my $joinkey (sort {$a<=>$b} keys %{ $nameToIDs{object}{$name} })
  } # foreach my $name (sort keys %{ $nameToIDs{object} })

  my @check_duplicates = qw( name publicname );		# Karen wants list of duplicate pgids of these entries  2020 05 04
  foreach my $table (@check_duplicates) {
    foreach my $data (sort keys %{ $byTableData{$table} }) {
      my (@pgids) = sort keys %{ $byTableData{$table}{$data} };
      my $pgids = join", ", @pgids;
      if (scalar @pgids > 1) { $err_text .= qq(Multiple entries in $table for $data : $pgids\n); }
    } # foreach my $data (sort keys %{ $byTableData{$table} })
  } # foreach my $table (@check_duplicates)

  return( $all_entry, $err_text );
} # sub getTransgene


sub printTag {
  my ($tag, $data, $joinkey, $table) = @_;
  unless ($table) { $table = ''; }
  my @data = ();
  if ($data) {
#       if ( ($table eq 'reporter_product') || ($tag eq 'Gene') || ($tag eq '3_UTR') || ($tag eq 'Driven_by_gene') || ($tag eq 'Map') || ($tag eq "Map_evidence\tPerson_evidence") || ($tag eq "Map_evidence\tPaper_evidence") || ($tag eq 'Laboratory') || ($tag eq 'Reference') || ($tag eq 'Person') ) { $data =~ s/^"//; $data =~ s/"$//; (@data) = split/\",\"/, $data; }	# reporter_product and other_reporter have the same tag, but rep is multiontology and other is pipe text	# removed reporter_product, gene, threeutr, driven_by_gene  2014 07 08
#       if ( ($tag eq 'Coinjection') || ($tag eq 'Construct') || ($tag eq 'Map') || ($tag eq "Map_evidence\tPerson_evidence") || ($tag eq "Map_evidence\tPaper_evidence") || ($tag eq 'Laboratory') || ($tag eq 'Reference') || ($tag eq 'Person') ) { $data =~ s/^"//; $data =~ s/"$//; (@data) = split/\",\"/, $data; }	# reporter_product and other_reporter have the same tag, but rep is multiontology and other is pipe text
      if ( ($tag eq 'Coinjection') || ($tag eq 'Construct') || ($tag eq 'Map') || ($tag =~ m/Person_evidence/) || ($tag =~ m/Paper_evidence/) || ($tag eq 'Laboratory') || ($tag eq 'Reference') || ($tag eq 'Person') || ($tag eq 'Strain') ) { $data =~ s/^"//; $data =~ s/"$//; (@data) = split/\",\"/, $data; }	# reporter_product and other_reporter have the same tag, but rep is multiontology and other is pipe text
        else { (@data) = split/ \| /, $data; }
      foreach my $data (@data) { 
#         $data =~ s/\"//g;		# chris wants leading  doublequotes dumped  2016 07 28
        if ($data =~ m/\"/) { $data =~ s/\"/\\\"/g; }
        $data =~ s/\n/ /g;		# replace all newlines with spaces  2010 10 29
        $data =~ s/  / /g;		# replace all double spaces with single spaces  2010 10 29
        if ($data =~ m/^\s+/) { $data =~ s/^\s+//; }
        if ($data =~ m/\s+$/) { $data =~ s/\s+$//; }
        next unless $data;
# removed Gene, 3_UTR, Driven_by_gene  2014 07 08
#         if ( ($tag eq 'Gene') || ($tag eq '3_UTR') || ($tag eq 'Driven_by_gene') ) {
#             if ($deadObjects{gene}{"split"}{$data}) {  # anything with a split gene is an error
#                 $all_entry .= qq(Historical_gene\t"$data" Remark  "Note: This object originally referred to a gene ($data) that is now considered dead. Please interpret with discretion."\n);
#                 $err_text .= "$joinkey\tnodump\tThis pgid contains a gene that has been split $data in $tag.\n"; }
#               elsif ($deadObjects{gene}{"mapto"}{$data}) {       # if gene maps to another gene, add the mapped version
#                 $all_entry .= qq(Historical_gene  "$data"  Remark  "Note: This object originally referred to $data.  $data is now considered dead and has been merged into $deadObjects{gene}{"mapto"}{$data}. $deadObjects{gene}{"mapto"}{$data} has replaced $data accordingly."\n);
#                 my $mappedGene = $deadObjects{gene}{"mapto"}{$data};        # convert to new gene
#                 $all_entry .= qq($tag\t"$mappedGene" Inferred_automatically\n); }
#               elsif ($deadObjects{gene}{"suppressed"}{$data}) {
#                 $all_entry .= qq(Historical_gene\t"$data" Remark  "Note: This object originally referred to a gene ($data) that has been suppressed. Please interpret with discretion."\n); }
#               elsif ($deadObjects{gene}{"dead"}{$data}) {
#                 $all_entry .= qq(Historical_gene\t"$data" Remark  "Note: This object originally referred to a gene ($data) that is now considered dead. Please interpret with discretion."\n); }
#               else {
#                 $all_entry .= "$tag\t\"$data\"\n"; } }
        if ( ($tag eq 'Reference') || ($tag eq "Map_evidence\tPerson_evidence") ) {
            if ($deadObjects{paper}{$data}) { $err_text .= qq($joinkey\tInvalid $tag\t"$data"\t$deadObjects{paper}{$data}\n); }
              else { $all_entry .= "$tag\t\"$data\"\n"; } }
          else {
            $all_entry .= "$tag\t\"$data\"\n"; }
        if ($tag eq 'Marker_for') { if ($hash{marker_for_paper}{$joinkey}) { 
          my $paper = $hash{marker_for_paper}{$joinkey};
          if ($deadObjects{paper}{$paper}) { $err_text .= qq($joinkey\tInvalid marker_for_paper\t"$paper"\t$deadObjects{paper}{$paper}\n); } 
            else { &printTag( "Marker_for\t\"$data\"\tPaper_evidence\t", $hash{marker_for_paper}{$joinkey}) ; } } } } }
    else {
      $all_entry .= "$tag\n"; }
} # sub printTag



sub populateDeadObjects {
  $result = $dbh->prepare( "SELECT * FROM pap_status WHERE pap_status = 'invalid';" ); $result->execute();
  while (my @row = $result->fetchrow) { $deadObjects{paper}{"WBPaper$row[0]"} = $row[1]; }
  $result = $dbh->prepare( "SELECT * FROM gin_dead;" ); $result->execute();
#   while (my @row = $result->fetchrow) { $deadObjects{gene}{"WBGene$row[0]"} = $row[1]; }
  while (my @row = $result->fetchrow) {                 # Chris sets precedence of split before merged before suppressed before dead, and a gene can only have one value, referring to the highest priority (only 1 value per gene in gin_dead table)  2013 10 21
    if ($row[1] =~ m/split_into (WBGene\d+)/) {       $deadObjects{gene}{"split"}{"WBGene$row[0]"} = $1; }
      elsif ($row[1] =~ m/merged_into (WBGene\d+)/) { $deadObjects{gene}{"mapto"}{"WBGene$row[0]"} = $1; }
      elsif ($row[1] =~ m/Suppressed/) {              $deadObjects{gene}{"suppressed"}{"WBGene$row[0]"} = $row[1]; }
      elsif ($row[1] =~ m/Dead/) {                    $deadObjects{gene}{"dead"}{"WBGene$row[0]"} = $row[1]; } }
#   while (my @row = $result->fetchrow) {               # previously gin_dead only had "Dead" or "merged_into / split_into", now it can have all 3 plus Suppressed, so redoing it based on priorities set by Chris
#     if ($row[1] =~ m/Dead/) { $deadObjects{gene}{"dead"}{"WBGene$row[0]"} = $row[1]; }
#       else {
#         if ($row[1] =~ m/merged_into (WBGene\d+)/) { $deadObjects{gene}{"mapto"}{"WBGene$row[0]"} = $1; }
#         if ($row[1] =~ m/split_into (WBGene\d+)/) { $deadObjects{gene}{"split"}{"WBGene$row[0]"} = $1; } } }
  my $doAgain = 1;                                    # if a mapped gene maps to another gene, loop through all again
  while ($doAgain > 0) {
    $doAgain = 0;                                     # stop if no genes map to other genes
    foreach my $gene (sort keys %{ $deadObjects{gene}{mapto} }) {
      next unless ( $deadObjects{gene}{mapTo}{$gene} );
      my $mappedGene = $deadObjects{gene}{mapTo}{$gene};
      if ($deadObjects{gene}{mapTo}{$mappedGene}) {
        $deadObjects{gene}{mapTo}{$gene} = $deadObjects{gene}{mapTo}{$mappedGene};          # set mapping of original gene to 2nd degree mapped gene
        $doAgain++; } } }                             # loop again in case a mapped gene maps to yet another gene
} # sub populateDeadObjects


# this was to get the lab-allele mappings from a place that doesn't update them much, using obo_data_laboratory now  2012 06 28
# sub updateAlleleToLab {
#   my $url = 'http://www.cbs.umn.edu/cgc/lab-allele';
#   my $url_data = get $url;
#   my $local_file = 'allele_to_lab';
#   my $local_data = '';
#   if (-e $local_file) {
#     $/ = undef;
#     open (IN, "<$local_file") or die "Cannot open $local_file : $!";
#     my $local_data = <IN>;
#     close (IN) or die "Cannot close $local_file : $!";
#     $/ = "\n";
#   } # if (-e $local_file)
#   my $urlIsParsable = &parseLabAllele($url_data);
#   
#   if ($urlIsParsable eq 'good') {			# good data from url
#     if ($local_data ne $url_data) { 			# url has different data, update local file
#       open (OUT, ">$local_file") or die "Cannot write to $local_file : $!";
#       print OUT $url_data; 
#       close (OUT) or die "Cannot close $local_file : $!";
#     } # if ($local_data ne $url_data)
#   } 
#   else { 
#     $err_text .= "ERROR $url cannot be parsed to get allele to lab mappings\n\n"; 
#     my $localIsParsable = &parseLabAllele($local_data);
#   }
# } # sub updateAlleleToLab
# 
# sub parseLabAllele {
#   my ($html_data) = @_;
#   unless ($html_data =~ m/\n([^\n]*?Strain[^\n]*Allele[^\n]*?)\n/ms) { return "bad"; }
#   my $line = $1;
#   my (@entries) = split/<\/p>/, $line;
#   foreach my $entry (@entries) {
#     $entry =~ s/<p>//g;
#     next unless ($entry =~ m/^(.*?)(?:&nbsp;)+(.*?)(?:&nbsp;)+(.*?)$/);
#     my ($strain, $allele, $address) = ($1, $2, $3);
#     if ($strain && $allele) { 
#       if ($strain =~ m/\s/) { $strain =~ s/\s//g; }
#       if ($allele =~ m/\s/) { $allele =~ s/\s//g; }
#       if ($allele =~ m/^[a-z]+$/) { $allele_to_lab{$allele} = $strain; } }
#   } # foreach my $entry (@entries)
#   my @data = sort keys %allele_to_lab;
#   if (scalar( keys %allele_to_lab ) > 5) { return "good"; } else { return "bad"; }
# } # sub parseLabAllele

