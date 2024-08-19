#!/usr/bin/env perl

# Looking at afp_transgene from old afp, before 2019-03-22
# Stripping out anything in square brackets (sometimes they put things in parenthesis or mismatch, so it fails)
# Replacing ~~ with space
# Replacing multispace with single space
# Getting rid of anything that isn't a letter number or space
# Splitting words by spaces
# Looking for [a-z]+(Ex|Is)\d+   lowercase letters, Ex or Is, digits
# If it matches the pattern, and in trp_name + trp_publicname, then it's a YESMATCH.  If not in trp tables it's a NOMATCH
# Otherwise checked is getting ignored, any other string is a BAD
# 53 entries have YESMATCH
# 15 entries have NOMATCH
# 37 entries have BAD
# Some entries could have multiple.   File is broken up in paragraphs with the WBPaper ID, types of matches, and ORIG for original entry.
#
# For Kimberly to transfer old afp to abc TET.  Analysis of data first.  2024 06 30
#
# Update script to fix afp_transgene data if it has mappings.
# Convert to acknowledge format   WBTransgene00020977;%;ltSi560 | WBTransgene00014794;%;oxEx1578 | WBTransgene00025194;%;bsSi28 | WBTransgene00001903;%;qIs51
# but add  | ORIGINAL COMMENT <comment>
# 2024 07 22
#
# Updating to just populate the normal afp and ack, but not convert the old afp into WB:WBTransgene yet.  2024 07 24
#
# Derive merged papers from pap_identifier.  2024 07 26
#
# Was only grabbing the first transgene from ACK note, now grabbing all.  2024 07 29
#
# Extract word strings to WBTransgene from afp and send to API.  2024 07 31
#
# for extracted afp curies, don't add published_as, don't add note, use current timestamp, use 'caltech_pipeline' for who did it.  2024 08 01
#
# skip ACK data that doesn't have an afp_lasttouched entry.  map trp_name to trp_species to obo_name_ncbitaxonid to derive species.
# if ACK has afp_contributor use that timestamp, otherwise afp_transgene timestamp.  generate sql for deleting data for this script.  2024 08 14
#
# process negatives for old afp and ack, but not sending to abc yet.  have a few questions on ticket.  2024 08 15
#
# If no taxon in OA, default to 6239, that's what wb does for acedb.
# In processing negatives, derived valid wbpaper, and if invalid skip.
# Output tfp data for ABC.  2024 08 16
#
# Use afp_lasttouched timestamp for ABC date for negate old afp.
# Generate logs based on abc api, json or api output, generate error log for api responses that are not success.  2024 08 19


# If reloading, drop all TET from WB sources manually (don't have an API for delete with sql), make sure it's the correct database.

# delete command
# DELETE FROM topic_entity_tag WHERE topic = 'ATP:0000110' AND topic_entity_tag_source_id IN ( SELECT topic_entity_tag_source_id FROM topic_entity_tag_source WHERE secondary_data_provider_id = ( SELECT mod_id FROM mod WHERE abbreviation = 'WB' ));

# select command if wanting to check
# SELECT * FROM topic_entity_tag WHERE topic = 'ATP:0000110' AND topic_entity_tag_source_id IN (
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

my @output_json;

my $pgDate = &getPgDate();

my $mod = 'WB';
my $baseUrl = 'https://stage-literature-rest.alliancegenome.org/';
# my $baseUrl = 'https://dev4002-literature-rest.alliancegenome.org/';
my $okta_token = &generateOktaToken();

my %trp;
my %trpTaxon;

my %theHash;
my %afpToEmail;
my %emailToWbperson;
my %afpContributor;
my %afpLasttouched;
my %afpOthertransgene;
my %afpTransgene;
my %tfpTransgene;
my %wbpToAgr;
my %papValid;
my %papMerge;
my %afpNeg;
my %ackNeg;

&populateAbcXref();
&populatePapValid();
&populatePapMerge(); 
&populateTrp();
&populateAfpEmail();
&populateEmailToWbperson();
&populateAfpContributor();
&populateAfpTransgene();
&populateAfpLasttouched();
&populateAfpOthertransgene();
&populateTfpTransgene();

my $abc_location = 'stage';
if ($baseUrl =~ m/dev4002/) { $abc_location = '4002'; }
elsif ($baseUrl =~ m/prod/) { $abc_location = 'prod'; }

my $date = &getSimpleSecDate();
my $outfile = 'populate_transgene_topic_entity.' . $date . '.' . $output_format . '.' . $abc_location;
open (OUT, ">$outfile") or die "Cannot create $outfile : $!";

my $errfile = 'populate_transgene_topic_entity.' . $date . '.err.' . $abc_location;
if ($output_format eq 'api') {
  open (ERR, ">$errfile") or die "Cannot create $outfile : $!";
}

&outputAfpData();
&outputNegData();
&outputTfpData();

if ($output_format eq 'json') {
  # to print to screen
  #   my $json = encode_json \@output_json;         # for single json file output
  #   print qq($json\n);                            # for single json file output
  my $json = to_json( \@output_json, { pretty => 1 } );
  print OUT qq($json);                            # for single json file output
}

close (OUT) or die "Cannot close $outfile : $!";
if ($output_format eq 'api') {
  close (ERR) or die "Cannot close $errfile : $!";
}


sub populateTrp {
  my $result = $dbh->prepare( "SELECT trp_name, trp_publicname FROM trp_name, trp_publicname WHERE trp_name.joinkey = trp_publicname.joinkey;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
    $trp{$row[1]} = $row[0];
  }

  my %speciesToTaxon;
  $result = $dbh->prepare( " SELECT * FROM obo_name_ncbitaxonid WHERE obo_name_ncbitaxonid IN ( SELECT DISTINCT(trp_species) FROM trp_species ); " );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
    $speciesToTaxon{$row[1]} = 'NCBITaxon:' . $row[0];
  }

  $result = $dbh->prepare( "SELECT trp_name, trp_species FROM trp_name, trp_species WHERE trp_name.joinkey = trp_species.joinkey;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
    $trpTaxon{"WB:$row[0]"} = $speciesToTaxon{$row[1]};
  }
} # sub populateTrp

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
  my $result = $dbh->prepare( "SELECT joinkey, afp_contributor, afp_timestamp FROM afp_contributor ORDER BY afp_timestamp" );
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

sub populateAfpOthertransgene {
  my $result = $dbh->prepare( "SELECT joinkey, afp_othertransgene FROM afp_othertransgene" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
#     next unless ($chosenPapers{$row[0]} || $chosenPapers{all});
    next unless ($row[1]);
    my $who = $row[1]; $who =~ s/two/WBPerson/;
    $afpOthertransgene{$row[0]} = $row[1];
} }

sub deriveValidPap {
  my ($joinkey) = @_;
  if ($papValid{$joinkey}) { return $joinkey; }
    elsif ($papMerge{$joinkey}) {
      ($joinkey) = &deriveValidPap($papMerge{$joinkey});
      return $joinkey; }
    else { return 'NOTVALID'; }
} # sub deriveValidPap

sub populateTfpTransgene {
  my $result = $dbh->prepare( "SELECT * FROM tfp_transgene;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
    my ($joinkey, $trText, $ts) = @row;
    ($joinkey) = &deriveValidPap($joinkey);
    next unless $papValid{$joinkey};
    $tfpTransgene{$joinkey}{data} = $trText;
    $tfpTransgene{$joinkey}{timestamp} = $ts; } }

sub populateAfpTransgene {
#   my $result = $dbh->prepare( "SELECT * FROM afp_transgene WHERE afp_timestamp < '2019-03-22 00:00';" );
  my $result = $dbh->prepare( "SELECT * FROM afp_transgene;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
    my ($joinkey, $trText, $ts, $curator, $approve, $curts) = @row;
    ($joinkey) = &deriveValidPap($joinkey);
    $afpTransgene{$joinkey}{data} = $trText;
    $afpTransgene{$joinkey}{timestamp} = $ts;
    next unless $papValid{$joinkey};
    next unless $trText;
    my $tsdigits = &tsToDigits($ts);
    if ($tsdigits < '20190322') {
      my $email = $afpToEmail{$joinkey};
      my $lcemail = '';
      if ($email) { $lcemail = lc($email); }
      my $wbperson = 'unknown_author';
      if ($emailToWbperson{$lcemail}) { $wbperson = $emailToWbperson{$lcemail}; }
#       if ($wbperson) { 
#         print qq(YES PERSON for paper : $joinkey\temail : $email\tperson $wbperson\n); }
#       else { 
#         unless ($email) { $email = 'NOEMAIL'; }
#         print qq(NO PERSON for paper : $joinkey\temail : $email\n); }
      $theHash{'afp'}{$joinkey}{'NOENTITY'}{$wbperson}{timestamp} = $ts;
      push @{ $theHash{'afp'}{$joinkey}{'NOENTITY'}{$wbperson}{note} }, $trText;

      $trText =~ s/\[[^\]]*\]//g;
      $trText =~ s/~~/ /g;
      $trText =~ s/\s+/ /g;
      $trText =~ s/[^A-Za-z0-9 ]//g;
      my (@words) = split/\s+/, $trText;
      my %match;
      foreach my $word (@words) {
        $word =~ s/\s+//g;
        if ($word =~ m/[a-z]+(Ex|Is)\d+/) { 
          if ($trp{$word}) { 
            my $obj = 'WB:' . $trp{$word};
            $theHash{'afpx'}{$joinkey}{$obj}{'caltech_pipeline'}{timestamp} = $pgDate;	# use caltech_pipeline and current date
#             $theHash{'afpx'}{$joinkey}{$obj}{$wbperson}{timestamp} = $ts;		# don't use wbperson, use caltech_pipeline
#             $theHash{'afpx'}{$joinkey}{$obj}{$wbperson}{published_as} = $word;	# don't get published_as 2024 08 01
#             push @{ $theHash{'afpx'}{$joinkey}{$obj}{$wbperson}{note} }, $trText;	# don't get note 2024 08 01
      } } }
    }
    else {
      next unless ($afpLasttouched{$joinkey});
      my (@wbtransgenes) = $trText =~ m/(WBTransgene\d+)/g;
      my @auts;
      if ($afpContributor{$joinkey}) { foreach my $who (sort keys %{ $afpContributor{$joinkey} }) { push @auts, $who; } }
      if (scalar @auts < 1) { push @auts, 'unknown_author'; }
      foreach my $aut (@auts) {
        foreach my $wbtr (@wbtransgenes) {
          my $obj = 'WB:' . $wbtr;
          if ($afpContributor{$joinkey}{$aut}) {
            $theHash{'ack'}{$joinkey}{$obj}{$aut}{timestamp} = $afpContributor{$joinkey}{$aut}; }
          else {
            $theHash{'ack'}{$joinkey}{$obj}{$aut}{timestamp} = $ts; }
          push @{ $theHash{'ack'}{$joinkey}{$obj}{$aut}{note} }, $trText;
    } } }
  }
} # sub populateAfpTransgene

# Done but not tested
# # ack
# # if there is afp_lasttouched + afp_transgene is empty + afp_othertransgene = '[{"id":1,"name":""}]'
# # then created negated topic only
# 
# # old afp
# # if there is afp_lasttouched + NO afp_transgene + NO afp_othertransgene
# # then created negated topic only
#
# # check tfp_transgene - if empty, make negated, if data, send the data.  source ECO:0008021 + ACKnoweldge_pipeline

# TODO
# output an error log if running against API.


sub outputNegData {
  my $data_provider = $mod;
  my $secondary_data_provider = $mod;
  my $source_evidence_assertion = 'ATP:0000035';
  my $source_method = 'author_first_pass';
  my $source_id_afp = &getSourceId($source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider);
  unless ($source_id_afp) {
    print STDERR qq(ERROR no source_id for $source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider);
    return;
  }

  $source_evidence_assertion = 'ATP:0000035';
  $source_method = 'ACKnowledge_form';
  my $source_id_ack = &getSourceId($source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider);
  unless ($source_id_ack) {
    print STDERR qq(ERROR no source_id for $source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider);
    return;
  }


  foreach my $joinkey (sort keys %afpLasttouched) {
    ($joinkey) = &deriveValidPap($joinkey);
    next unless $papValid{$joinkey};
    unless ($wbpToAgr{$joinkey}) { print STDERR qq(ERROR paper $joinkey NOT AGRKB\n); next; }
    my %object;
    $object{'force_insertion'}              = TRUE;
    $object{'negated'}                      = TRUE;
    $object{'reference_curie'}              = $wbpToAgr{$joinkey};
#     $object{'wbpaper_id'}                   = $joinkey;		# for debugging
    $object{'topic'}                        = 'ATP:0000110';
    if ( (!exists $afpTransgene{$joinkey}) && (!exists $afpOthertransgene{$joinkey}) ) {
      my $email = $afpToEmail{$joinkey};
      my $lcemail = '';
      if ($email) { $lcemail = lc($email); }
      my $wbperson = 'unknown_author';
      if ($emailToWbperson{$lcemail}) { $wbperson = $emailToWbperson{$lcemail}; }
#       $object{'BLAH'}  		      = 'afp';
      $object{'created_by'}  		      = $wbperson;
      $object{'updated_by'}  		      = $wbperson;
      $object{'date_updated'}                 = $afpLasttouched{$joinkey};
      $object{'date_created'}                 = $afpLasttouched{$joinkey};
      $object{'topic_entity_tag_source_id'}   = $source_id_afp;
      if ($output_format eq 'json') {
        push @output_json, \%object; }
      else {
        my $object_json = encode_json \%object;
        &createTag($object_json); }
      }
    elsif ( ($afpTransgene{$joinkey}{data} eq '') && ($afpOthertransgene{$joinkey} eq '[{"id":1,"name":""}]') ) {
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
          $object{'date_updated'} = $afpTransgene{$joinkey}{timestamp};
          $object{'date_created'} = $afpTransgene{$joinkey}{timestamp}; }
        if ($output_format eq 'json') {
          push @output_json, \%object; }
        else {
          my $object_json = encode_json \%object;
          &createTag($object_json); }
      }
    }
  }
} # sub outputNegData

sub outputTfpData {
  my $data_provider = $mod;
  my $secondary_data_provider = $mod;
  my $source_evidence_assertion = 'ECO:0008021';
  my $source_method = 'ACKnowledge_pipeline';
  my $source_id_tfp = &getSourceId($source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider);
  unless ($source_id_tfp) {
    print STDERR qq(ERROR no source_id for $source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider);
    return;
  }
  foreach my $joinkey (sort keys %tfpTransgene) {
    unless ($wbpToAgr{$joinkey}) { print STDERR qq(ERROR paper $joinkey NOT AGRKB\n); next; }
    my $data = $tfpTransgene{$joinkey}{data};
    my %object;
    $object{'topic_entity_tag_source_id'}   = $source_id_tfp;
    $object{'force_insertion'}              = TRUE;
    $object{'negated'}                      = FALSE;
    $object{'reference_curie'}              = $wbpToAgr{$joinkey};
#     $object{'wbpaper_id'}                   = $joinkey;		# for debugging
    $object{'date_updated'}		    = $tfpTransgene{$joinkey}{timestamp};
    $object{'date_created'}		    = $tfpTransgene{$joinkey}{timestamp};
    $object{'created_by'}                   = 'ACKnowledge_pipeline';
    $object{'updated_by'}                   = 'ACKnowledge_pipeline';
    $object{'topic'}                        = 'ATP:0000110';
    if ($data eq '') {
      $object{'negated'}                    = TRUE;
#       $object{'BLAH'}                       = 'TFP neg';
      if ($output_format eq 'json') {
        push @output_json, \%object; }
      else {
        my $object_json = encode_json \%object;
        &createTag($object_json); } }
    else {
      my (@wbtransgenes) = $data =~ m/(WBTransgene\d+)/g;
      foreach my $wbtr (@wbtransgenes) {
        my $obj = 'WB:' . $wbtr;
#         $object{'BLAH'}                      = 'TFP yes';
        $object{'entity_type'}               = 'ATP:0000110';
        $object{'entity_id_validation'}      = 'alliance';
        $object{'entity'}                    = $obj;
        $object{'species'}                   = 'NCBITaxon:6239';
        if ($trpTaxon{$obj}) { 		     # if there's a trp taxon, go with that value instead of default
          $object{'species'}                 = $trpTaxon{$obj}; }
        if ($output_format eq 'json') {
          push @output_json, \%object; }
        else {
          my $object_json = encode_json \%object;
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
    print STDERR qq(ERROR no source_id for $source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider);
    return;
  }

  $source_evidence_assertion = 'ATP:0000035';
  $source_method = 'ACKnowledge_form';
  my $source_id_ack = &getSourceId($source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider);

  unless ($source_id_ack) {
    print STDERR qq(ERROR no source_id for $source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider);
    return;
  }

  $source_evidence_assertion = 'ECO:0008021';
  $source_method = 'free_text_to_entity_id_script';
  my $source_id_afpx = &getSourceId($source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider);

  unless ($source_id_afpx) {
    print STDERR qq(ERROR no source_id for $source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider);
    return;
  }

  foreach my $datatype (sort keys %theHash) {
    foreach my $joinkey (sort keys %{ $theHash{$datatype} }) {
      unless ($wbpToAgr{$joinkey}) { print STDERR qq(ERROR paper $joinkey NOT AGRKB\n); next; }
#       next unless ($chosenPapers{$joinkey} || $chosenPapers{all});
      foreach my $obj (sort keys %{ $theHash{$datatype}{$joinkey} }) {
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
          $object{'topic'}                        = 'ATP:0000110';

          $object{'entity_type'}                  = 'ATP:0000110';
          $object{'entity_id_validation'}         = 'alliance';
          $object{'entity'}                       = $obj;
          $object{'species'}                      = 'NCBITaxon:6239';
          if ($trpTaxon{$obj}) { 			# if there's a trp taxon, go with that value instead of default
            $object{'species'}                    = $trpTaxon{$obj}; }
          if ($obj eq 'NOENTITY') {
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


#   { "source_type": "professional_biocurator", "source_method": "wormbase_curation_status", "evidence": "eco_string", "description": "cur_curdata", "mod_abbreviation": "WB" }
#   foreach my $datatype (sort keys %afpAutData) {
#     unless ($datatypes{$datatype}) {
#       print ERR qq(no topic for afpAutData $datatype\n);
#       next;
#     }
#     foreach my $joinkey (sort keys %{ $afpAutData{$datatype} }) {
#       my @auts;
#       if ($afpContributor{$joinkey}) { foreach my $who (sort keys %{ $afpContributor{$joinkey} }) { push @auts, $who; } }
#       if (scalar @auts < 1) { push @auts, 'unknown_author'; }
#       foreach my $aut (@auts) {
#         my %object;
#         my $negated = FALSE;
#         if ($afpAutData{$datatype}{$joinkey}{negated}) { $negated = TRUE; }
#         my $source_id = $source_id_afp;
#         if ($afpAutData{$datatype}{$joinkey}{source} eq 'ack') { $source_id = $source_id_ack; }
#         if ($afpAutData{$datatype}{$joinkey}{note}) {
#           $object{'note'}                     = $afpAutData{$datatype}{$joinkey}{note}; }
#         $object{'negated'}                    = $negated;
#         $object{'force_insertion'}            = TRUE;
#         $object{'reference_curie'}            = $wbpToAgr{$joinkey};
#         $object{'topic'}                      = $datatypes{$datatype};
#         $object{'topic_entity_tag_source_id'} = $source_id;
#         $object{'created_by'}                 = $aut;
#         $object{'updated_by'}                 = $aut;
#         $object{'date_created'}               = $afpAutData{$datatype}{$joinkey}{timestamp};
#         $object{'date_updated'}               = $afpAutData{$datatype}{$joinkey}{timestamp};
#         # $object{'datatype'}                 = $datatype;              # for debugging
#         if ($output_format eq 'json') {
#           push @output_json, \%object; }
#         else {
#           my $object_json = encode_json \%object;
#           &createTag($object_json); }
#   } } }
}


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
# PUT THIS BACK
  my $api_json = `curl -X 'POST' $url -H 'accept: application/json' -H 'Authorization: Bearer $okta_token' -H 'Content-Type: application/json' --data '$object_json'`;
  print OUT qq(create $object_json\n);
  print OUT qq($api_json\n);
  if ($api_json !~ /success/) {
    print ERR qq(create $object_json\n);
    print ERR qq($api_json\n);
  }
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


