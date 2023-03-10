#!/usr/bin/perl -w

# populate exp_ tables based on .ace file
#
# ran on tazendra  2011 05 31

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my $pgid = 0;
my @pgcommands;
my %hash;

my %remap;
&populateRemap();
sub populateRemap {
  $remap{'anatomy'}{'WBbt000:6748'} = 'WBbt:0006748';
  $remap{'anatomy'}{'WBbt:0003852'} = 'WBbt:0003851';
  $remap{'anatomy'}{'WBbt:0004397'} = 'WBbt:0008116';
  $remap{'anatomy'}{'WBbt:0004398'} = 'WBbt:0008111';
  $remap{'anatomy'}{'WBbt:0004401'} = 'WBbt:0004392';
  $remap{'anatomy'}{'WBbt:0004459'} = 'WBbt:0003664';
  $remap{'anatomy'}{'WBbt:0004514'} = 'WBbt:0008052';
  $remap{'anatomy'}{'WBbt:0004515'} = 'WBbt:0008050';
  $remap{'anatomy'}{'WBbt:0004717'} = 'WBbt:0008046';
  $remap{'anatomy'}{'WBbt:0004718'} = 'WBbt:0008051';
  $remap{'anatomy'}{'WBbt:0004719'} = 'WBbt:0008049';
  $remap{'anatomy'}{'WBbt:0004720'} = 'WBbt:0008047';
  $remap{'anatomy'}{'WBbt:0004721'} = 'WBbt:0008045';
  $remap{'anatomy'}{'WBbt:0004722'} = 'WBbt:0008044';
  $remap{'anatomy'}{'WBbt:0005099'} = 'WBbt:0005830';
  $remap{'anatomy'}{'WBbt:0005211'} = 'WBbt:0005801';
  $remap{'anatomy'}{'WBbt:0005228'} = 'WBbt:0005214';
  $remap{'anatomy'}{'WBbt:0005323'} = 'WBbt:0005831';
  $remap{'anatomy'}{'WBbt:0005814'} = 'WBbt:0006909';
  $remap{'anatomy'}{'WBbt:6789'}    = 'WBbt:0006789';
} # sub populateRemap

my %ignoreThisData;
&populateIgnoreThisData();
sub populateIgnoreThisData {		# this entries has no proper mapping
$ignoreThisData{'antibody'}{'[WBPaper00032450]:capg-1'}++;
$ignoreThisData{'antibody'}{'[cgc3002]:beta-filagenin'}++;
$ignoreThisData{'antibody'}{'[cgc4387]:hsp-16.2'}++;
$ignoreThisData{'antibody'}{'[cgc6057]:daf-21'}++;
$ignoreThisData{'goid'}{'GO:0000141'}++;
$ignoreThisData{'goid'}{'GO:0008221'}++;
$ignoreThisData{'transgene'}{'Is001'}++;
$ignoreThisData{'transgene'}{'Is007'}++;
$ignoreThisData{'transgene'}{'leals30'}++;
$ignoreThisData{'transgene'}{'pZMI.1In1'}++;
$ignoreThisData{'transgene'}{'pZMI.1In2'}++;
# FIX ignore these when reading and populating
} # sub populateIgnoreThisData


my %tags;
$tags{Reference}{table} = 'paper';
$tags{paper}{type} = 'single';	# ont
$tags{paper}{ont}++;
$tags{Gene}{table} = 'gene';
$tags{gene}{type} = 'single';	# ont
$tags{gene}{ont}++;
$tags{Anatomy_term}{table} = 'anatomy';
$tags{anatomy}{type} = 'multi';	# ont
$tags{anatomy}{ont}++;
$tags{GO_term}{table} = 'goid';
$tags{goid}{type} = 'multi';	# ont
$tags{goid}{ont}++;
$tags{Subcellular_localization}{table} = 'subcellloc';
$tags{subcellloc}{type} = 'single';
$tags{Life_stage}{table} = 'lifestage';
$tags{lifestage}{type} = 'multi';	# ont
$tags{lifestage}{ont}++;
$tags{exprtype}{ont}++;				# ont but not a normal tag
$tags{Antibody}{table} = 'antibodytext';
$tags{antibodytext}{type} = 'single';
$tags{Reporter_gene}{table} = 'reportergene';
$tags{reportergene}{type} = 'single';
$tags{In_Situ}{table} = 'insitu';
$tags{insitu}{type} = 'single';
$tags{RT_PCR}{table} = 'rtpcr';
$tags{rtpcr}{type} = 'single';
$tags{Northern}{table} = 'northern';
$tags{northern}{type} = 'single';
$tags{Western}{table} = 'western';
$tags{western}{type} = 'single';
# $tags{Picture}{table} = 'picture';
# $tags{picture}{type} = 'multi';	# ont
# $tags{picture}{ont}++;
$tags{Antibody_info}{table} = 'antibody';
$tags{antibody}{type} = 'multi';	# ont
$tags{antibody}{ont}++;
$tags{Pattern}{table} = 'pattern';
$tags{pattern}{type} = 'single';
$tags{Remark}{table} = 'remark';
$tags{remark}{type} = 'single';
$tags{Transgene}{table} = 'transgene';
$tags{transgene}{type} = 'multi';	# ont
$tags{transgene}{ont}++;
$tags{Protein_description}{table} = 'protein';
$tags{protein}{type} = 'single';
$tags{Clone}{table} = 'clone';
$tags{clone}{type} = 'multi';	# ont
$tags{clone}{ont}++;
$tags{Strain}{table} = 'strain';
$tags{strain}{type} = 'single';
$tags{strain}{ont}++;
$tags{Sequence}{table} = 'sequence';
$tags{sequence}{type} = 'single';
$tags{MovieURL}{table} = 'movieurl';
$tags{movieurl}{type} = 'single';
$tags{Laboratory}{table} = 'laboratory';
$tags{laboratory}{type} = 'multi';	# ont
$tags{laboratory}{ont}++;

$tags{Picture}{ignore}++;
$tags{Cell}{ignore}++;
$tags{Author}{ignore}++;
$tags{Date}{ignore}++;
$tags{Curated_by}{ignore}++;
$tags{Expressed_in}{ignore}++;
$tags{Pseudogene}{ignore}++;
$tags{Protein}{ignore}++;

# reference gene picture antibody transgene strain clone

my %lifestageToId;
$result = $dbh->prepare( "SELECT joinkey, obo_name_lifestage FROM obo_name_lifestage ;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $lifestageToId{$row[1]} = $row[0]; }

my %ontology;
my @obo_tables = qw( anatomy clone goid lifestage laboratory strain );
foreach my $table (@obo_tables) {
  $result = $dbh->prepare( "SELECT joinkey FROM obo_name_$table ;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { $ontology{$table}{$row[0]}++; }
} # foreach my $table (@obo_tables)

$result = $dbh->prepare( "SELECT joinkey FROM pap_status WHERE pap_status = 'valid' ;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $ontology{'reference'}{"WBPaper$row[0]"}++; }

$result = $dbh->prepare( "SELECT gin_wbgene FROM gin_wbgene ;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $ontology{'gene'}{$row[0]}++; }

# $result = $dbh->prepare( "SELECT pic_name FROM pic_name ;" );
# $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
# while (my @row = $result->fetchrow) { $ontology{'picture'}{$row[0]}++; }

$result = $dbh->prepare( "SELECT abp_name FROM abp_name ;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $ontology{'antibody'}{$row[0]}++; }

$result = $dbh->prepare( "SELECT trp_name FROM trp_name ;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $ontology{'transgene'}{$row[0]}++; }

my %invalidData;


# my %anatomy_text;
my %anatomy_data;

$/ = "";
# my $infile = 'ExprWS221.ace';
my $infile = 'ExprWS226.ace';
open (IN, "<$infile") or die "Cannot open $infile : $!";
my $junk = <IN>;		# skip non-entry
while (my $para = <IN>) {
  my (@lines) = split/\n/, $para;
  my $header = shift @lines;
  my ($id) = $header =~ m/Expr_pattern : \"(.*?)\"/;
  unless ($id) { print "ERR NO ID $para\n"; }
#   $pgid++;

#   my @data;
  foreach my $line (@lines) {
    if ($line =~ m/\\\//) { $line =~ s|\\\/|/|g; }			# strip acedb escape backslashes
    if ($line =~ m/\\;/) { $line =~ s/\\;/;/g; }			# strip acedb escape backslashes
    if ($line =~ m/ \-C \".*?\"$/) { $line =~ s/ \-C \".*?\"$//; }	# strip end comments
    if ($line =~ m/DOUBLEQUOTE/) { print "Warning DOUBLEQUOTE in original data\n"; }
    if ($line =~ m/\\"/) { $line =~ s/\\"/DOUBLEQUOTE/g; }		# temporarily replace backslash-" with temp
    if ($line =~ m/^([\w]+)\s*$/) {
      my ($tag) = $1;
      if ($tags{$tag}) {
        next if ($tags{$tag}{ignore});
        my $table = $tags{$tag}{table}; my $data = '';
        if ( ($tag eq 'Antibody') || ($tag eq 'Reporter_gene') || ($tag eq 'In_Situ') || ($tag eq 'RT_PCR') || ($tag eq 'Northern') || ($tag eq 'Western') ) { $hash{$id}{'exprtype'}{$tag}++; }
          else { print "Unmatched data single tag for $id $tag $line\n"; } }
      else { print "Unexpected tag $tag\n"; }
    }
    elsif ($line =~ m/^([\w]+)\s+(.*)$/) {
      my ($tag) = $1; my $rest_of_line = $2;
      if ($tags{$tag}) {
        next if ($tags{$tag}{ignore});
        my $table = $tags{$tag}{table}; my $data = '';
        if ($tag eq 'Anatomy_term') {
          my $text = ''; my $qualifier = ''; my $anatid = '';
# get anat_term #qualifier text
#           if ($line =~ m/$tag\s+\"(.*?)\"\s+(\w+)\s+(.*?)$/) { 
#             $anatomy_text{$3}{$id}{$1}++;	# text exprId anatId
#             print "$id Extra data after Anatomy flag $line\n"; 
#           }
          if ($line =~ m/$tag\s+\"([^"]*?)\"\s+(\w+)\s+\"([^"]*?)\"\s*?$/) { $anatid = $1; $qualifier = $2; $text = $3; }
          elsif ($line =~ m/$tag\s+\"([^"]*?)\"\s+(\w+)\s*?$/) { $anatid = $1; $qualifier = $2; }
          elsif ($line =~ m/$tag\s+\"([^"]*?)\"\s*?$/) { $anatid = $1; }
          else { print "BAD Anatomy flag $id\t$line\n"; }
          $anatomy_data{$id}{$text}{$qualifier}{$anatid}++;
#           if ($line =~ m/$tag\s+\"(.*?)\"\s+Certain/) { $table = 'certain'; $data = $1; }
#           elsif ($line =~ m/$tag\s+\"(.*?)\"\s+Partial/) { $table = 'partial'; $data = $1; }
#           elsif ($line =~ m/$tag\s+\"(.*?)\"\s+Uncertain/) { $table = 'uncertain'; $data = $1; }
#           else { print "NO Anatomy flag $id\t$line\n"; }		# anat term without #qualifier
#           $hash{$table}{$id}{$data}++;
        } elsif ( ($tag eq 'Antibody') || ($tag eq 'Reporter_gene') || ($tag eq 'In_Situ') || ($tag eq 'RT_PCR') || ($tag eq 'Northern') || ($tag eq 'Western') ) {
          $hash{$id}{'exprtype'}{$tag}++;
# print "ADDED $id exprtype $tag\n";
          if ($line eq $tag) { next; }			# flag only
            elsif ($line =~ m/$tag\s+\"(.*?)\"/) { $data = $1; }
            else { print "Unmatched data type/exprtype for $id $tag $line\n"; }
          if ($table eq 'anatomy') { if ($remap{'anatomy'}{$data}) { $data = $remap{'anatomy'}{$data}; } }
#           if ($ignoreThisData{$table}{$data}) { print "\nSKIP $table D $data\n"; }
          next if $ignoreThisData{$table}{$data};
          $hash{$id}{$table}{$data}++;
        } else {
          if ($line =~ m/$tag\s+\"([^\"]*?)\"$/) { $data = $1; }
            elsif ($line =~ m/\\n\\$/) {
              $line =~ s/\\n\\$//;
              $line .= shift @lines;
              if ($line =~ m/$tag\s+\"([^\"]*?)\"$/) { $data = $1; } }
            elsif ($line =~ m/Life_stage\s+\"([^\"]+?)\"\s+Certain$/) { $data = $1; }	# skip #Qualifier Certain in Life_stage
            else { print "Unmatched data normal for $id $tag $line\n"; }
          if ($table eq 'anatomy') { if ($remap{'anatomy'}{$data}) { $data = $remap{'anatomy'}{$data}; } }
          if ($ignoreThisData{$table}{$data}) { print "\nSKIP $table D $data\n"; }
          next if $ignoreThisData{$table}{$data};
          $hash{$id}{$table}{$data}++;
        }
      } # if ($tags{$tag})
      else { print "Unexpected tag $tag\n"; }
    } # elsif ($line =~ m/^([\w]+)\s+(.*)$/)
    else { print "NO MATCH $line LINE\n"; }
  } # foreach my $line (@lines)
} # while (my $para = <IN>)
close (IN) or die "Cannot close $infile : $!";
$/ = "\n";


# To get sorted Anatomy_term #Qualifier text
#             $anatomy_text{$3}{$id}{$1}++;	# text exprId anatId
# foreach my $anat_text (sort keys %anatomy_text) {
#   foreach my $expr (sort keys %{ $anatomy_text{$anat_text} }) {
#     my $ids = join", ", sort keys %{ $anatomy_text{$anat_text}{$expr} };
#     print "$anat_text\t$expr\t$ids\n";
#   } # foreach my $expr (sort keys %{ $anatomy_text{$anat_text} })
# } # foreach my $anat_text (sort keys %anatomy_text)


#           $anatomy_data{$id}{$text}{$qualifier}{$anatid}++;
foreach my $id ( sort keys %hash ) {
  my @expr_pgids;		# get list of pgids generated for each Expr_pattern object because of different Qualifier and Qualifier_text
  foreach my $text (sort keys %{ $anatomy_data{$id} }) {
    foreach my $qualifier (sort keys %{ $anatomy_data{$id}{$text} }) {
      foreach my $anat_id (sort keys %{ $anatomy_data{$id}{$text}{$qualifier} }) {
        unless ($ontology{'anatomy'}{$anat_id}) { 
          next if ($remap{'anatomy'}{$anat_id});
          $invalidData{'anatomy'}{$anat_id}{$id}++; }
      } # foreach my $anat_id (sort keys %{ $anatomy_data{$id}{$text}{$qualifier} })
      $pgid++; push @expr_pgids, $pgid;
      my $anat_ids = join"\",\"", sort keys %{ $anatomy_data{$id}{$text}{$qualifier} };		# note that all values are going in, not only valid ones
      &addToPg($pgid, 'anatomy', "\"$anat_ids\"");
      if ($qualifier) { 
        if ($qualifier =~ m/\\"/) { $qualifier =~ s/DOUBLEQUOTE/\\"/g; }	# put back escaped-"
        &addToPg($pgid, 'qualifier', $qualifier); }
      if ($text) { 
        if ($text =~ m/\\"/) { $text =~ s/DOUBLEQUOTE/\\"/g; }	# put back escaped-"
        &addToPg($pgid, 'qualifiertext', $text); }
    } # foreach my $qualifier (sort keys %{ $anatomy_data{$id}{$text} })
  } # foreach my $text (sort keys %{ $anatomy_data{$id} })

  unless ($expr_pgids[0]) { $pgid++; push @expr_pgids, $pgid; }	# some entries have no Anatomy / Qualifer / QText, they still need a pgid
  foreach my $pgid (@expr_pgids) {				# add all other table data for each pgid
    &addToPg($pgid, 'name', $id);
    &addToPg($pgid, 'curator', 'WBPerson101');			# Add Wen as curator (fixed)
    foreach my $table (sort keys %{ $hash{$id} } ) {
      my $data = '';
      if ($tags{$table}{ont}) {
        foreach my $data (sort keys %{ $hash{$id}{$table} } ) {
          if ($ontology{$table}) { 
# while (my @row = $result->fetchrow) { $lifestageToId{$row[1]} = $row[0]; }
            if ($lifestageToId{$data}) { delete $hash{$id}{$table}{$data}; $data = $lifestageToId{$data}; $hash{$id}{$table}{$data}++; }
            if ($ontology{$table}{$data}) { 1; }
              else { 
                if ( ($table eq 'picture') && ($data !~ m/^WBPicture/) ) { next; }	# skip non-WBPicture objects	# this is unnecessary 2011 05 13
                else { 
                  next if ($remap{'anatomy'}{$data});
                  $invalidData{$table}{$data}{$id}++; } } } }
        $data = join'","', keys %{ $hash{$id}{$table} }; if ($data) { $data = '"' . $data . '"'; } # note that all values are going in, not only valid ones
      } else {
#         if (scalar keys %{ $hash{$id}{$table} } > 1) { print "This data will be joined with | $id $table\n"; }
        $data = join"|", keys %{ $hash{$id}{$table} };
      }
      if ($data =~ m/DOUBLEQUOTE/) { $data =~ s/DOUBLEQUOTE/\\"/g; }	# put back escaped-"
      if ($data) {
        &addToPg($pgid, $table, $data); }
    } # foreach my $table (sort keys %{ $hash{$id} } )
  } # foreach my $pgid (@pgids)
} # foreach my $id ( sort keys %hash )

foreach my $table (sort keys %invalidData) {
  foreach my $data (sort keys %{ $invalidData{$table} }) {
    my $ids = join", ", keys %{ $invalidData{$table}{$data} };
#     print "INVALID DATA $table $data $ids\n";
  } # foreach my $data (sort keys %{ $invalidData{$table} })
} # foreach my $table (sort keys %invalidData)

foreach my $pgcommand (@pgcommands) {
  print "$pgcommand\n";
# UNCOMMENT TO POPULATE
#   $result = $dbh->do( $pgcommand );
} # foreach my $pgcommand (@pgcommands)

sub addToPg {
  my ($pgid, $table, $data) = @_;
  if ($data =~ m/\'/) { $data =~ s/\'/''/g; }
  push @pgcommands, "INSERT INTO exp_${table} VALUES ('$pgid', E'$data')";
# FIX  uncomment for history
  push @pgcommands, "INSERT INTO exp_${table}_hst VALUES ('$pgid', E'$data')";
} # sub addToPg



__END__




my @pgcommands;
push @pgcommands, "DELETE FROM obo_name_pic_exprpattern ;";
push @pgcommands, "DELETE FROM obo_data_pic_exprpattern ;";

my %anat_to_name;

my $result = $dbh->prepare( "SELECT * FROM obo_name_app_anat_term ;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $anat_to_name{$row[0]} = "$row[1] is $row[0]"; }


$/ = "";
my $infile = 'ExprWS221.ace';
open (IN, "<$infile") or die "Cannot open $infile : $!";
my $junk = <IN>;		# skip non-entry
while (my $para = <IN>) {
  my (@lines) = split/\n/, $para;
  my $header = shift @lines;
  my ($id) = $header =~ m/Expr_pattern : \"(.*?)\"/;
  unless ($id) { print "ERR NO ID $para\n"; }
  push @pgcommands, "INSERT INTO obo_name_pic_exprpattern VALUES ( '$id', '$id' );";
  my @data;
  push @data, "id : $id";
  foreach my $line (@lines) {  
    if ($line =~ m/^([\w]+)\s+\"/) { 
      my ($tag) = $1;
      if ($tags{$tag}) { 
        $line =~ s/\t / : /;
        if ($tag eq 'Anatomy_term') {
          my ($value) = $line =~ m/(WBbt:\d+)/;
          if ($anat_to_name{$value}) { my $new_value = $anat_to_name{$value}; $line =~ s/$value/$new_value/; } }
        push @data, "$line"; }
    }
#     else { print "NO MATCH $line LINE\n"; }
  }
  my $data = join"\n", @data;
  $data =~ s/\'/''/g;
  push @pgcommands, "INSERT INTO obo_data_pic_exprpattern VALUES ( '$id', '$data' );";
} # while (my $para = <IN>)
close (IN) or die "Cannot close $infile : $!";
$/ = "\n";

foreach my $command (@pgcommands) {
  print "$command\n";
# UNCOMMENT TO POPULATE, looks like it has errors, but reads in okay  2010 10 29
#   my $result = $dbh->do( $command );
}

__END__

my $result = $dbh->prepare( "SELECT * FROM two_comment WHERE two_comment ~ ?" );
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

Expr_pattern : "Expr1"
Gene     "WBGene00001386"
Clone    "UL#4F5"
Life_stage       "adult hermaphrodite"
Anatomy_term     "WBbt:0005821" Certain
Anatomy_term     "WBbt:0005813" Certain
Reporter_gene    "Partial Sau3A restriction enzyme fragment of C.elegans genomic  DNA cloned into the BamHI site of pPD22.11, creating a lacZ  translational fusion."
Reporter_gene    "The sequence of the point of fusion to lacZ is -- TAAAATATTGCAGTAATGAGATC\/lacZ"
Pattern  "Body wall muscle cells and vulval muscle cells of adult  hermaphrodites. Beta-galactosidase is nuclear localized"
Picture  "ul3_bwm.jpeg"
Picture  "ul3_vm.jpeg"
Author   "Hope IA"
Date     1990-04
Strain   "UL3"
Reference        "WBPaper00001469"
Curated_by       "HX"


