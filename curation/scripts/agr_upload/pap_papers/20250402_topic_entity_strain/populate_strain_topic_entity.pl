#!/usr/bin/env perl

# modify populate_transgene_topic_entity.pl to work with strains  2025 04 02
#
# Populate afpContributor from pap_species and pap_gene too, even though we don't know if that help.  2025 06 04
# Skip if no lasttouched when reading afp_otherstrain.  2025 06 04
# output negative data processing all negative data.  skip strains without a taxon.  2025 06 04


# If reloading, drop all TET from WB sources manually (don't have an API for delete with sql), make sure it's the correct database.

# delete command
# DELETE FROM topic_entity_tag WHERE topic = 'ATP:0000027' AND topic_entity_tag_source_id IN ( SELECT topic_entity_tag_source_id FROM topic_entity_tag_source WHERE secondary_data_provider_id = ( SELECT mod_id FROM mod WHERE abbreviation = 'WB' ));

# select command if wanting to check
# SELECT * FROM topic_entity_tag WHERE topic = 'ATP:0000027' AND topic_entity_tag_source_id IN (
#   SELECT topic_entity_tag_source_id FROM topic_entity_tag_source WHERE secondary_data_provider_id = (
#   SELECT mod_id FROM mod WHERE abbreviation = 'WB' ));


use strict;
use diagnostics;
use DBI;
use JSON;
use Jex;
use Encode qw( from_to is_utf8 );
use Dotenv -load => '/usr/lib/.env';

use constant FALSE => \0;
use constant TRUE => \1;

my $start_time = time;

my $dbh = DBI->connect ( "dbi:Pg:dbname=$ENV{PSQL_DATABASE};host=$ENV{PSQL_HOST};port=$ENV{PSQL_PORT}", "$ENV{PSQL_USERNAME}", "$ENV{PSQL_PASSWORD}") or die "Cannot connect to database!\n";
my $result;

my $output_format = 'json';
# my $output_format = 'api';
my $tag_counter = 0;
my $retry_counter = 0;

my @output_json;

my $pgDate = &getPgDate();

my $mod = 'WB';
# my $baseUrl = 'https://stage-literature-rest.alliancegenome.org/';
my $baseUrl = 'https://dev4002-literature-rest.alliancegenome.org/';
my $okta_token = &generateOktaToken();

my %strain;
my %strainTaxon;

my %theHash;
my %afpToEmail;
my %emailToWbperson;
my %afpContributor;
my %afpLasttouched;
my %afpOtherstrain;
my %afpStrain;
my %tfpStrain;
my %wbpToAgr;
my %papValid;
my %papMerge;
my %afpNeg;
my %ackNeg;
my $abc_location = 'stage';
if ($baseUrl =~ m/dev4002/) { $abc_location = '4002'; }
elsif ($baseUrl =~ m/prod/) { $abc_location = 'prod'; }

my $date = &getSimpleSecDate();
my $outfile = 'populate_strain_topic_entity.' . $date . '.' . $output_format . '.' . $abc_location;
open (OUT, ">$outfile") or die "Cannot create $outfile : $!";

my $perrfile = 'populate_strain_topic_entity.' . $date . '.err.processing';
open (PERR, ">$perrfile") or die "Cannot create $perrfile : $!";

my $errfile = 'populate_strain_topic_entity.' . $date . '.err.' . $abc_location;
if ($output_format eq 'api') {
  open (ERR, ">$errfile") or die "Cannot create $outfile : $!";
}

&populateAbcXref();
&populatePapValid();
&populatePapMerge(); 
&populateAfpContributor();
&populateAfpLasttouched();
&populateStrain();
&populateAfpEmail();
&populateEmailToWbperson();
&populateAfpStrain();
&populateAfpOtherstrain();
&populateTfpStrain();


# &outputAfpData();
# &outputTfpData();
&outputNegData();

if ($output_format eq 'json') {
  # to print to screen
  #   my $json = encode_json \@output_json;         # for single json file output
  #   print qq($json\n);                            # for single json file output
  my $json = to_json( \@output_json, { pretty => 1 } );
  print OUT qq($json);                            # for single json file output
}

close (OUT) or die "Cannot close $outfile : $!";
close (PERR) or die "Cannot close $errfile : $!";
if ($output_format eq 'api') {
  close (ERR) or die "Cannot close $errfile : $!";
}


sub populateStrain {
  my %allSpecies;
  my %strainToSpecies;
  my $result = $dbh->prepare( "SELECT * FROM obo_data_strain;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
    my ($wbstrain, $data, $ts) = @row;
    next unless $data;
    my (@species) = $data =~ m/species: "(.*?)"/g;
    my (@names) = $data =~ m/name: "(.*?)"/g;
    if (scalar @names > 1) { print PERR qq($wbstrain has multiple names @names\n); }
    if (scalar @species > 1) { print PERR qq($wbstrain has multiple species @species\n); }
    if ($species[0]) { 
      $strainToSpecies{"WB:$wbstrain"} = $species[0];
      $allSpecies{$species[0]}++; }
    $strain{$names[0]} = $wbstrain;
  }

  my $allSpecies = join"', '", sort keys %allSpecies;
  my %speciesToTaxon;
#   $result = $dbh->prepare( "SELECT * FROM obo_name_ncbitaxonid WHERE obo_name_ncbitaxonid IN ( '$allSpecies' ); " );
  $result = $dbh->prepare( "SELECT * FROM pap_species_index WHERE pap_species_index IN ( '$allSpecies' ); " );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) { $speciesToTaxon{$row[1]} = 'NCBITaxon:' . $row[0]; }

  foreach my $strain (sort keys %strainToSpecies) {
    if ($strainToSpecies{$strain}) { 
      $strainTaxon{$strain} = $speciesToTaxon{$strainToSpecies{$strain}}; 
    }
  } # foreach my $strain (sort keys %strainToSpecies)
} # sub populateStrain

sub populateAfpEmail {
  my $result = $dbh->prepare( "SELECT * FROM afp_email;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
    $afpToEmail{$row[0]} = $row[1]; 
  }
}

sub populateEmailToWbperson {
  my $result = $dbh->prepare( "SELECT * FROM two_email;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
    my $lcemail = lc($row[2]);
    my $who = $row[0]; $who =~ s/two/WBPerson/;
    $emailToWbperson{$lcemail} = $who; 
  }
}

sub populateAfpContributor {
  my $result = $dbh->prepare( "SELECT joinkey, pap_curator, pap_timestamp FROM pap_species WHERE pap_evidence ~ 'from author first pass'" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
#     next unless ($chosenPapers{$row[0]} || $chosenPapers{all});
    next unless ($row[1]);
    my $who = $row[1]; $who =~ s/two/WBPerson/;
    $afpContributor{$row[0]}{$who} = $row[2]; }
  $result = $dbh->prepare( "SELECT joinkey, pap_curator, pap_timestamp FROM pap_gene WHERE pap_evidence ~ 'from author first pass'" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
#     next unless ($chosenPapers{$row[0]} || $chosenPapers{all});
    next unless ($row[1]);
    my $who = $row[1]; $who =~ s/two/WBPerson/;
    $afpContributor{$row[0]}{$who} = $row[2]; }
  $result = $dbh->prepare( "SELECT joinkey, afp_contributor, afp_timestamp FROM afp_contributor ORDER BY afp_timestamp" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
#     next unless ($chosenPapers{$row[0]} || $chosenPapers{all});
    next unless ($row[1]);
    my $who = $row[1]; $who =~ s/two/WBPerson/;
    $afpContributor{$row[0]}{$who} = $row[2];
} }

sub populateAfpLasttouched {
  my $result = $dbh->prepare( "SELECT joinkey, afp_timestamp FROM afp_lasttouched" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
#     next unless ($chosenPapers{$row[0]} || $chosenPapers{all});
    next unless ($row[1]);
    my $who = $row[1]; $who =~ s/two/WBPerson/;
    $afpLasttouched{$row[0]} = $row[1];
} }

sub populateAfpOtherstrain {
  my $result = $dbh->prepare( "SELECT * FROM afp_otherstrain" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
#     next unless ($chosenPapers{$row[0]} || $chosenPapers{all});
    next unless ($row[1]);
    next if ($row[1] eq '[{"id":1,"name":""}]');
    my $joinkey = $row[0];
    ($joinkey) = &deriveValidPap($joinkey);
    next unless $papValid{$joinkey};
    next unless ($afpLasttouched{$joinkey});
    $afpOtherstrain{$joinkey} = $row[1];
    my @auts;
    if ($afpContributor{$joinkey}) { foreach my $who (sort keys %{ $afpContributor{$joinkey} }) { push @auts, $who; } }
    if (scalar @auts < 1) { push @auts, 'unknown_author'; }
    foreach my $aut (@auts) {
      my $obj = 'NOENTITY';
      if ($afpContributor{$joinkey}{$aut}) {
        $theHash{'ack'}{$joinkey}{$obj}{$aut}{timestamp} = $afpContributor{$joinkey}{$aut}; }
      else {
        $theHash{'ack'}{$joinkey}{$obj}{$aut}{timestamp} = $row[2]; }
      $theHash{'ack'}{$joinkey}{$obj}{$aut}{newToDatabase} = 'true';
      push @{ $theHash{'ack'}{$joinkey}{$obj}{$aut}{note} }, $row[1];
    }
  }
}

sub deriveValidPap {
  my ($joinkey) = @_;
  if ($papValid{$joinkey}) { return $joinkey; }
    elsif ($papMerge{$joinkey}) {
      ($joinkey) = &deriveValidPap($papMerge{$joinkey});
      return $joinkey; }
    else { return 'NOTVALID'; }
} # sub deriveValidPap

sub populateTfpStrain {
  my $result = $dbh->prepare( "SELECT * FROM tfp_strain WHERE tfp_timestamp > '2019-03-22 00:00';" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
    my ($joinkey, $trText, $ts) = @row;
    ($joinkey) = &deriveValidPap($joinkey);
    next unless $papValid{$joinkey};
    $tfpStrain{$joinkey}{data} = $trText;
    $tfpStrain{$joinkey}{timestamp} = $ts; } }

sub populateAfpStrain {
#   my $result = $dbh->prepare( "SELECT * FROM afp_transgene WHERE afp_timestamp < '2019-03-22 00:00';" );
  my $result = $dbh->prepare( "SELECT * FROM afp_strain;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
    my ($joinkey, $trText, $ts) = @row;
    ($joinkey) = &deriveValidPap($joinkey);
    $afpStrain{$joinkey}{data} = $trText;
    $afpStrain{$joinkey}{timestamp} = $ts;
    next unless $papValid{$joinkey};
    next unless $trText;
#     my $tsdigits = &tsToDigits($ts);
    next unless ($afpLasttouched{$joinkey});
    my @wbstrains = ();
    if ($trText =~ m/WBStrain/) {
      (@wbstrains) = $trText =~ m/(WBStrain\d+)/g; }
    else {
      my (@words) = split/ \| /, $trText;
      foreach my $word (@words) {
        if ($strain{$word}) { push @wbstrains, $strain{$word}; }
        else {
          $word =~ s/\s+//g;
          if ($strain{$word}) { push @wbstrains, $strain{$word}; }
          else { print PERR qq($joinkey $word not a WBStrain ID\n); } } } }
    my @auts;
    if ($afpContributor{$joinkey}) { foreach my $who (sort keys %{ $afpContributor{$joinkey} }) { push @auts, $who; } }
    if (scalar @auts < 1) { push @auts, 'unknown_author'; }
    foreach my $aut (@auts) {
      foreach my $wbstrain (@wbstrains) {
        my $obj = 'WB:' . $wbstrain;
        if ($afpContributor{$joinkey}{$aut}) {
          $theHash{'ack'}{$joinkey}{$obj}{$aut}{timestamp} = $afpContributor{$joinkey}{$aut}; }
        else {
          $theHash{'ack'}{$joinkey}{$obj}{$aut}{timestamp} = $ts; }
        push @{ $theHash{'ack'}{$joinkey}{$obj}{$aut}{note} }, $trText;
    } }
  }
} # sub populateAfpStrain



sub outputNegData {
  my $data_provider = $mod;
  my $secondary_data_provider = $mod;
  my $source_evidence_assertion = 'ATP:0000035';
  my $source_method = 'author_first_pass';
  my $source_id_afp = &getSourceId($source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider);
  unless ($source_id_afp) {
    print PERR qq(ERROR no source_id for $source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider);
    return;
  }

  $source_evidence_assertion = 'ATP:0000035';
  $source_method = 'ACKnowledge_form';
  my $source_id_ack = &getSourceId($source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider);
  unless ($source_id_ack) {
    print PERR qq(ERROR no source_id for $source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider);
    return;
  }

  $source_evidence_assertion = 'ECO:0008021';
  $source_method = 'ACKnowledge_pipeline';
  my $source_id_tfp = &getSourceId($source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider);
  unless ($source_id_tfp) {
    print PERR qq(ERROR no source_id for $source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider);
    return;
  }

  # this is negative ack topic data, no longer doing negative afp topic data
  foreach my $joinkey (sort keys %afpLasttouched) {
    ($joinkey) = &deriveValidPap($joinkey);
    next unless $papValid{$joinkey};
    unless ($wbpToAgr{$joinkey}) { print PERR qq(ERROR paper $joinkey NOT AGRKB\n); next; }
    my %object;
    $object{'force_insertion'}              = TRUE;
    $object{'negated'}                      = TRUE;
    $object{'reference_curie'}              = $wbpToAgr{$joinkey};
#     $object{'wbpaper_id'}                   = $joinkey;		# for debugging
    $object{'topic'}                        = 'ATP:0000027';
# Do not want negative topic data for old afp, because of how that form worked.  2025 06 02
#     if ( (!exists $afpStrain{$joinkey}) && (!exists $afpOtherstrain{$joinkey}) ) {
#       my $email = $afpToEmail{$joinkey};
#       my $lcemail = '';
#       if ($email) { $lcemail = lc($email); }
#       my $wbperson = 'unknown_author';
#       if ($emailToWbperson{$lcemail}) { $wbperson = $emailToWbperson{$lcemail}; }
# #       $object{'BLAH'}  		      = 'afp';
#       $object{'created_by'}  		      = $wbperson;
#       $object{'updated_by'}  		      = $wbperson;
#       $object{'date_updated'}                 = $afpLasttouched{$joinkey};
#       $object{'date_created'}                 = $afpLasttouched{$joinkey};
#       $object{'topic_entity_tag_source_id'}   = $source_id_afp;
#       if ($output_format eq 'json') {
#         push @output_json, \%object; }
#       else {
#         my $object_json = encode_json \%object;
#         &createTag($object_json); }
#       }
    next if ( (!exists $afpStrain{$joinkey}) && (!exists $afpOtherstrain{$joinkey}) );	#  old afp, pre-acknowledge
    if ( ($afpStrain{$joinkey}{data} eq '') && ($afpOtherstrain{$joinkey} eq '[{"id":1,"name":""}]') ) {	# acknowledge
      $object{'topic_entity_tag_source_id'}   = $source_id_ack;
      my @auts;
      if ($afpContributor{$joinkey}) { foreach my $who (sort keys %{ $afpContributor{$joinkey} }) { push @auts, $who; } }
      if (scalar @auts < 1) { push @auts, 'unknown_author'; }
      foreach my $aut (@auts) {
        $object{'created_by'}   = $aut;
        $object{'updated_by'}   = $aut;
#         $object{'BLAH'}  		      = 'ACK';
        if ($afpContributor{$joinkey}{$aut}) {
          $object{'date_updated'} = $afpContributor{$joinkey}{$aut};
          $object{'date_created'} = $afpContributor{$joinkey}{$aut}; }
        else {
          $object{'date_updated'} = $afpStrain{$joinkey}{timestamp};
          $object{'date_created'} = $afpStrain{$joinkey}{timestamp}; }
        if ($output_format eq 'json') {
          push @output_json, \%object; }
        else {
          my $object_json = encode_json \%object;
          &createTag($object_json); }
      }
    }
  }

  # This is negative tfp topic data where tfp is empty
  foreach my $joinkey (sort keys %tfpStrain) {
    ($joinkey) = &deriveValidPap($joinkey);
    next unless $papValid{$joinkey};
    unless ($wbpToAgr{$joinkey}) { print PERR qq(ERROR paper $joinkey NOT AGRKB tfpNegGeneTopic\n); next; }
    next unless ($tfpStrain{$joinkey}{data} eq '');
    my $ts = $tfpStrain{$joinkey}{timestamp};
    my %object;
    $object{'topic_entity_tag_source_id'}   = $source_id_tfp;
    $object{'force_insertion'}              = TRUE;
    $object{'negated'}                      = TRUE;
    $object{'reference_curie'}              = $wbpToAgr{$joinkey};
#     $object{'wbpaper_id'}                   = $joinkey;               # for debugging
    $object{'date_updated'}                 = $ts;
    $object{'date_created'}                 = $ts;
    $object{'created_by'}                   = 'ACKnowledge_pipeline';
    $object{'updated_by'}                   = 'ACKnowledge_pipeline';
    $object{'topic'}                        = 'ATP:0000110';
    if ($output_format eq 'json') {
      push @output_json, \%object; }
    else {
      my $object_json = encode_json \%object;
      &createTag($object_json); }
  }


  # This is negative ack data where author removed something that tfp said
  foreach my $joinkey (sort keys %tfpStrain) {
    next unless ($afpLasttouched{$joinkey});    # must be a final author submission
    ($joinkey) = &deriveValidPap($joinkey);
    next unless $papValid{$joinkey};
    unless ($wbpToAgr{$joinkey}) { print PERR qq(ERROR paper $joinkey NOT AGRKB\n); next; }
    next if (exists $theHash{'ack'}{$joinkey} && keys %{ $theHash{'ack'}{$joinkey} });  # if author sent nothing, don't create a negative entity
#     my (@tfpStrains) = $tfpStrain{$joinkey}{data} =~ m/(WBStrain\d+)/g;
    my %tfpStrains;
    my (@words) = split/ \| /, $tfpStrain{$joinkey}{data};
    foreach my $word (@words) {
      my $obj = ''; my $name = '';
      if ($word =~ m/WBStrain/) {
        (my $wbstrain, $name) = split(/;%;/, $word);
        $tfpStrains{$wbstrain}++; }
      else {
        if ($strain{$word}) { $tfpStrains{$strain{$word}}++; }
        else {
          $word =~ s/\s+//g;
          if ($strain{$word}) { $tfpStrains{$strain{$word}}++; }
          else { print PERR qq($joinkey $word not a WBStrain ID\n); } } } }
    my (@tfpStrains) = sort keys %tfpStrains;
    foreach my $wbstrain (@tfpStrains) {
      next unless ($wbstrain);  				# must have a wbstrain
      my $obj = 'WB:' . $wbstrain;
      next if ($theHash{'ack'}{$joinkey}{$obj});		# if author sent this entity, don't create a negative entity
      unless ($strainTaxon{$obj}) { print qq(ERROR paper $joinkey negative ack strain $obj has no taxon\n); next; }
      my @auts;
      if ($afpContributor{$joinkey}) { foreach my $who (sort keys %{ $afpContributor{$joinkey} }) { push @auts, $who; } }
      if (scalar @auts < 1) { push @auts, 'unknown_author'; }
      foreach my $aut (@auts) {
        my %object;
        $object{'negated'}                    = TRUE;
        $object{'force_insertion'}            = TRUE;
        $object{'reference_curie'}            = $wbpToAgr{$joinkey};
#         $object{'wbpaper_id'}                 = $joinkey;             # for debugging
        $object{'topic'}                      = 'ATP:0000110';
        $object{'entity_type'}                = 'ATP:0000110';
        $object{'entity_id_validation'}       = 'alliance';
        $object{'topic_entity_tag_source_id'} = $source_id_ack;
        $object{'created_by'}                 = $aut;
        $object{'updated_by'}                 = $aut;
        my $ts = $theHash{'ack'}{$joinkey}{$obj}{$aut}{timestamp};
        if ( $afpContributor{$joinkey}{$aut} ) { $ts = $afpContributor{$joinkey}{$aut}; }
        $object{'date_created'}               = $ts;
        $object{'date_updated'}               = $ts;
        # $object{'datatype'}                 = 'ack neg entity data';  # for debugging
        $object{'entity'}                     = $obj;
        $object{'species'}                    = 'NCBITaxon:6239';
        if ($strainTaxon{$obj}) {
          $object{'species'}                  = $strainTaxon{$obj}; }
        if ($output_format eq 'json') {
          push @output_json, \%object; }
        else {
          my $object_json = encode_json \%object;
          &createTag($object_json); }
  } } }
} # sub outputNegData

sub outputTfpData {
  my $data_provider = $mod;
  my $secondary_data_provider = $mod;
  my $source_evidence_assertion = 'ECO:0008021';
  my $source_method = 'ACKnowledge_pipeline';
  my $source_id_tfp = &getSourceId($source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider);
  unless ($source_id_tfp) {
    print PERR qq(ERROR no source_id for $source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider);
    return;
  }
  foreach my $joinkey (sort keys %tfpStrain) {
    unless ($wbpToAgr{$joinkey}) { print PERR qq(ERROR paper $joinkey NOT AGRKB\n); next; }
    my $data = $tfpStrain{$joinkey}{data};
    my %object;
    $object{'topic_entity_tag_source_id'}   = $source_id_tfp;
    $object{'force_insertion'}              = TRUE;
    $object{'negated'}                      = FALSE;
    $object{'reference_curie'}              = $wbpToAgr{$joinkey};
#     $object{'wbpaper_id'}                   = $joinkey;		# for debugging
    $object{'date_updated'}		    = $tfpStrain{$joinkey}{timestamp};
    $object{'date_created'}		    = $tfpStrain{$joinkey}{timestamp};
    $object{'created_by'}                   = 'ACKnowledge_pipeline';
    $object{'updated_by'}                   = 'ACKnowledge_pipeline';
    $object{'topic'}                        = 'ATP:0000027';
    if ($data eq '') {
      $object{'negated'}                    = TRUE;
#       $object{'BLAH'}                       = 'TFP neg';
      if ($output_format eq 'json') {
        push @output_json, \%object; }
      else {
        my $object_json = encode_json \%object;
        &createTag($object_json); } }
    else {
      my (@words) = split/ \| /, $data;
      foreach my $word (@words) {
        my $obj = ''; my $name = '';
        if ($word =~ m/WBStrain/) {
          (my $wbstrain, $name) = split(/;%;/, $word);
          $obj = 'WB:' . $wbstrain; }
        else {
          if ($strain{$word}) { $obj = 'WB:' . $strain{$word}; }
          else {
            $word =~ s/\s+//g;
            if ($strain{$word}) { $obj = 'WB:' . $strain{$word}; }
            else { print PERR qq($joinkey $word not a WBStrain ID\n); } } }
        next unless ($obj);
        unless ($strainTaxon{$obj}) { print qq(ERROR paper $joinkey tfpStrain $obj has no taxon\n); next; }
        $object{'entity_type'}               = 'ATP:0000027';
        $object{'entity_id_validation'}      = 'alliance';
        $object{'entity'}                    = $obj;
        if ($name) {
          $object{'entity_published_as'}     = $name; }
        if ($strainTaxon{$obj}) {
          $object{'species'}                 = $strainTaxon{$obj}; }
        else {
          print PERR qq(ERROR no taxon for WBPaper$joinkey Strain $obj\n);
          next; }
        if ($output_format eq 'json') {
          push @output_json, { %object }; }
        else {
          my $object_json = encode_json { %object };
          &createTag($object_json); }
    } }
  }
} # sub outputTfpData

sub outputAfpData {
  my $data_provider = $mod;
  my $secondary_data_provider = $mod;
  my $source_evidence_assertion = 'ATP:0000035';
  my $source_method = 'author_first_pass';
  my $source_id_afp = &getSourceId($source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider);
  unless ($source_id_afp) {
    print PERR qq(ERROR no source_id for $source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider);
    return;
  }

  $source_evidence_assertion = 'ATP:0000035';
  $source_method = 'ACKnowledge_form';
  my $source_id_ack = &getSourceId($source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider);
  unless ($source_id_ack) {
    print PERR qq(ERROR no source_id for $source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider);
    return;
  }

  $source_evidence_assertion = 'ECO:0008021';
  $source_method = 'free_text_to_entity_id_script';
  my $source_id_afpx = &getSourceId($source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider);
  unless ($source_id_afpx) {
    print PERR qq(ERROR no source_id for $source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider);
    return;
  }

  foreach my $datatype (sort keys %theHash) {
    foreach my $joinkey (sort keys %{ $theHash{$datatype} }) {
      unless ($wbpToAgr{$joinkey}) { print PERR qq(ERROR paper $joinkey NOT AGRKB\n); next; }
#       next unless ($chosenPapers{$joinkey} || $chosenPapers{all});
      foreach my $obj (sort keys %{ $theHash{$datatype}{$joinkey} }) {
        unless ($strainTaxon{$obj}) { print qq(ERROR paper $joinkey $datatype strain $obj has no taxon\n); next; }
        if ($obj ne 'NOENTITY') {
          unless ($strainTaxon{$obj}) { print PERR qq(ERROR paper $joinkey strain $obj has no taxon\n); next; } }
        foreach my $curator (sort keys %{ $theHash{$datatype}{$joinkey}{$obj} }) {
          my %object;
          $object{'topic_entity_tag_source_id'}   = $source_id_ack;
          if ($datatype eq 'afp') {
            $object{'topic_entity_tag_source_id'} = $source_id_afp; }
          if ($datatype eq 'afpx') {
            $object{'entity_published_as'}	  = $theHash{$datatype}{$joinkey}{$obj}{$curator}{published_as};
            $object{'topic_entity_tag_source_id'} = $source_id_afpx; }
          $object{'force_insertion'}              = TRUE;
          $object{'negated'}                      = FALSE;
          $object{'reference_curie'}              = $wbpToAgr{$joinkey};
#           $object{'wbpaper_id'}                   = $joinkey;		# for debugging
          $object{'topic'}                        = 'ATP:0000027';

          $object{'entity_type'}                  = 'ATP:0000027';
          $object{'entity_id_validation'}         = 'alliance';
          $object{'entity'}                       = $obj;
#           $object{'species'}                      = 'NCBITaxon:6239';	# used to have a default, now skip if no taxon
          if ($strainTaxon{$obj}) { 		# if there's a strain taxon, go with that value instead of default
            $object{'species'}                    = $strainTaxon{$obj}; }
          if ($obj eq 'NOENTITY') {
# TODO   future self add ATP that means it's new to database
            if ($theHash{$datatype}{$joinkey}{$obj}{$curator}{newToDatabase} eq 'true') { 1; }	# use atp that means newToDatabase
#             $object{'NOENTITY'} = $theHash{$datatype}{$joinkey}{$obj}{$curator}{newToDatabase};
            delete $object{'entity_type'};
            delete $object{'entity_id_validation'};
            delete $object{'entity'};
            delete $object{'species'}; }

          if ($theHash{$datatype}{$joinkey}{$obj}{$curator}{note}) {
            my $note = join' | ', @{ $theHash{$datatype}{$joinkey}{$obj}{$curator}{note} };
            $object{'note'}                     = $note; }
          $object{'created_by'}                 = $curator;
          $object{'updated_by'}                 = $curator;
          $object{'date_created'}               = $theHash{$datatype}{$joinkey}{$obj}{$curator}{timestamp};
          $object{'date_updated'}               = $theHash{$datatype}{$joinkey}{$obj}{$curator}{timestamp};
          if ($output_format eq 'json') {
            push @output_json, \%object; }
          else {
            my $object_json = encode_json \%object;
            &createTag($object_json); }
  } } } }
} # sub outputAfpData


sub tsToDigits {
  my $timestamp = shift;
  my $tsdigits = '';
  if ($timestamp =~ m/^(\d{4})\-(\d{2})\-(\d{2})/) { $tsdigits = $1 . $2 . $3; }
  return $tsdigits;
}

sub generateOktaToken {
#   my $okta_token = `curl -s --request POST --url https://$ENV{OKTA_DOMAIN}/v1/token \    --header 'accept: application/json' \    --header 'cache-control: no-cache' \    --header 'content-type: application/x-www-form-urlencoded' \    --data "grant_type=client_credentials&scope=admin&client_id=$ENV{OKTA_CLIENT_ID}&client_secret=$ENV{OKTA_CLIENT_SECRET}" \      | jq '.access_token' | tr -d '"'`;
  my $okta_result = `curl -s --request POST --url https://$ENV{OKTA_DOMAIN}/v1/token \    --header 'accept: application/json' \    --header 'cache-control: no-cache' \    --header 'content-type: application/x-www-form-urlencoded' \    --data "grant_type=client_credentials&scope=admin&client_id=$ENV{OKTA_CLIENT_ID}&client_secret=$ENV{OKTA_CLIENT_SECRET}"`;
  my $hash_ref = decode_json $okta_result;
  my $okta_token = $$hash_ref{'access_token'};
#   print $okta_token;
  return $okta_token;
}

sub createTag {
  my ($object_json) = @_;
  $tag_counter++;
  if ($tag_counter % 1000 == 0) {
    my $date = &getSimpleSecDate();
    print qq(counter\t$tag_counter\t$date\n);
    my $now = time;
    if ($now - $start_time > 82800) {           # if 23 hours went by, update okta token
      $okta_token = &generateOktaToken();
      $start_time = $now;
    }
  }
  my $url = $baseUrl . 'topic_entity_tag/';
#   my $api_json = `curl -X 'POST' $url -H 'accept: application/json' -H 'Authorization: Bearer $okta_token' -H 'Content-Type: application/json' --data '$object_json'`;	# this has issues with how the shell interprets special characters like parentheses ( and ) when passed directly in the command line.  instead avoid the shell and run the command through a pipe like  open my $fh, "-|", @args

  my @curl_cmd = (
    "curl", "-X", "POST", $url,
    "-H", "accept: application/json",
    "-H", "Authorization: Bearer $okta_token",
    "-H", "Content-Type: application/json",
    "--data", $object_json,
  );
  my $api_json = '';
  open my $fh, "-|", @curl_cmd or die "Could not run curl: $!";
  while (my $line = <$fh>) {
    $api_json .= $line;
  }
  close $fh;
  if ($? != 0 || $api_json !~ /success/) {
    print ERR qq(create $object_json\n);
    print ERR qq($api_json\n);
  }
  print OUT qq(create $object_json\n);
  print OUT qq($api_json\n);
  # $? is the exit status of the last command (0 is success).
  unless ($api_json) {
    $retry_counter++;
    if ($retry_counter > 4) {
      print ERR qq(api failed without response $retry_counter times, giving up\n);
      $retry_counter = 0; }
    else {
      print ERR qq(api failed $retry_counter times, retrying\n);
      my $sleep_amount = 4 ** $retry_counter;
      sleep $sleep_amount;
      &createTag($object_json); } }
}

sub getSourceId {
  my ($source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider) = @_;
  my $url = $baseUrl . 'topic_entity_tag/source/' . $source_evidence_assertion . '/' . $source_method . '/' . $data_provider . '/' . $secondary_data_provider;
#   my ($source_type, $source_method) = @_;
#   my $url = $baseUrl . 'topic_entity_tag/source/' . $source_type . '/' . $source_method . '/' . $mod;
  # print qq($url\n);
  my $api_json = `curl -X 'GET' $url -H 'accept: application/json' -H 'Authorization: Bearer $okta_token' -H 'Content-Type: application/json'`;
  my $hash_ref = decode_json $api_json;
  if ($$hash_ref{'topic_entity_tag_source_id'}) {
    my $source_id = $$hash_ref{'topic_entity_tag_source_id'};
    # print qq($source_id\n);
    return $source_id; }
  else { return ''; }
}

sub populatePapValid {
  $result = $dbh->prepare( "SELECT * FROM pap_status WHERE pap_status = 'valid';" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) { 
    $papValid{$row[0]}++; }
}

sub populatePapMerge {
  $result = $dbh->prepare( "SELECT * FROM pap_identifier WHERE pap_identifier ~ '^[0-9]{8}\$';" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) { 
    $papMerge{$row[1]} = $row[0]; }
}

sub populateAbcXref {
  $result = $dbh->prepare( "SELECT * FROM pap_identifier WHERE pap_identifier ~ 'AGRKB';" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) { 
#     next unless ($chosenPapers{$row[0]} || $chosenPapers{all});
    $wbpToAgr{$row[0]} = $row[1]; }
} # sub populateAbcXref


