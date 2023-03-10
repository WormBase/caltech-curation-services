#!/usr/bin/perl -w

# update cns_ tables based on Daniela's instructions.  2014 11 10
#
# changed a bit of stuff, check if pg data was different, added clone matching.  2014 12 01
# live on tazendra.  2014 12 01


use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my $pgfile = 'update_cns_by_daniela.pg';
open (PG, ">$pgfile") or die "Cannot open $pgfile : $!";

my %gin;
my @gin_tables = qw( gin_seqname gin_synonyms gin_locus );
foreach my $table (@gin_tables) {
  $result = $dbh->prepare( "SELECT * FROM $table" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { if ($row[0]) { $gin{lc($row[1])} = "WBGene$row[0]"; } } }

my %clones;
$result = $dbh->prepare( "SELECT * FROM obo_name_clone" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { if ($row[0]) { $clones{lc($row[1])} = "$row[0]"; } }


my %hash;
my @tables = qw( remark constructionsummary gene drivenbygene reporter curator summary constructtype fwdprimer revprimer clone );

my @reporters = ( "GFP", "GFP(S65C)", "EGFP", "pGFP(photoactivated GFP)", "YFP", "EYFP", "BFP", "CFP", "Cerulian", "RFP", "mRFP", "tagRFP", "mCherry", "wCherry", "tdTomato", "mStrawberry", "DsRed", "DsRed2", "Venus", "YC2.1 (yellow cameleon)", "YC12.12 (yellow cameleon),YC3.60 (yellow cameleon)", "Yellow cameleon", "Dendra", "Dendra2", "tdimer2(12)/dimer2", "GCaMP", "mkate2", "Luciferase", "LacI", "LacO", "LacZ");
my %reporters; foreach (@reporters) { $reporters{lc($_)}++; }


foreach my $table (@tables) {
  $result = $dbh->prepare( "SELECT * FROM cns_$table" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { if ($row[0]) { $hash{$table}{$row[0]} = $row[1]; } } }

my %pgidsToProcess;

foreach my $pgid (sort {$a<=>$b} keys %{ $hash{'remark'} }) {
  next unless ($hash{'curator'}{$pgid} eq 'WBPerson12028');
  unless ($hash{'constructionsummary'}{$pgid}) {		# does not have construction summary
    $pgidsToProcess{$pgid}++;
    if ($hash{'remark'}{$pgid} =~ m/\t+$/) { $hash{'remark'}{$pgid} =~ s/\t+$//; }
    print qq(PUT $hash{'remark'}{$pgid} into $pgid cns_constructionsummary\n);
    &addToPg('cns_constructionsummary', $pgid, $hash{'remark'}{$pgid});
    # TODO put remark in constructionsummary
    $hash{'constructionsummary'}{$pgid} = $hash{'remark'}{$pgid};
  }
}

my %summaryNoGene;
foreach my $pgid (sort {$a<=>$b} keys %{ $hash{'constructionsummary'} }) {
  next unless ($hash{'curator'}{$pgid} eq 'WBPerson12028');
  next if ($hash{'drivenbygene'}{$pgid});
  next if ($hash{'gene'}{$pgid});
#   if ($hash{'reporter'}{$pgid}) { print "PGID $pgid has reporter $hash{'reporter'}{$pgid}\n"; }	# to manually fix some, only 1 left, should be skipped
  next if ($hash{'reporter'}{$pgid});
  $pgidsToProcess{$pgid}++;
  print "PROCESS $pgid\n";
  my $constructionsummary = $hash{'constructionsummary'}{$pgid};
  my $summary = '';
  my @constructtype;
  my @reporter;
  if ( $constructionsummary =~ m/\[(.*?)\]/ ) { $summary = $1; }
  if ( $constructionsummary =~ m/transcriptional fusion/i) { push @constructtype, "Transcriptional_fusion"; }
  if ( $constructionsummary =~ m/translational fusion/i) {   push @constructtype, "Translational_fusion"  ; }
  foreach my $rep (@reporters) {
    if ($constructionsummary =~ m/\W$rep\W/i) { push @reporter, $rep; } }
  my (@atcg) = $constructionsummary =~ m/[^atcg]([atcg]{10,})[^atcg]/gi;
  my (@allWords) = split/\s+/, $constructionsummary;
  
  if ($summary) {
      my $summaryData = '[' . $summary . ']'; my $summaryError = 0;
      if ($hash{'summary'}{$pgid}) { 
        if ($hash{'summary'}{$pgid} ne $summaryData) { 
          print qq(ERR $pgid OLD SUMMARY $hash{'summary'}{$pgid} now $summaryData\n); $summaryError++; } }
      unless ($summaryError) { 
        &addToPg('cns_summary', $pgid, $summaryData);
        print qq($pgid cns_summary $summaryData\n); }
      my @genes;
#       if ( ($summary =~ m/:/) && ($summary !~ m/::/) ) { print qq(FIX $pgid has : and not :: in summary $summary\n); }
      my (@words) = split/:/, $summary;				# typos have : instead of ::  would split on :: if it weren't for typos
      foreach my $origword (@words) {
        next unless ($origword);				# splitting on : instead of :: means a bunch of blanks
        my ($word) = lc($origword);
        if ($word =~ m/^\s+/) { $word =~ s/^\s+//; } if ($word =~ m/\s+$/) { $word =~ s/\s+$//; }
        if ($word =~ m/^gfp\-/) { $word =~ s/^gfp\-//; } if ($word =~ m/\-gfp$/) { $word =~ s/\-gfp$//; }
        if ($word =~ m/\d[a-z]$/) { $word =~ s/[a-z]$//; }
        if ( ($word =~ m/^p/) && ($word =~ m/[a-z]{4,}\-/) ) { $word =~ s/^[p]//; }
        next if ($reporters{$word});
        if ($gin{$word}) { push @genes, $gin{$word}; }
          else { print qq(ERR $pgid not a gene match in summary $word ORIGINALLY $origword SUMMARY $summary\n); }
      } # foreach my $word (@words) 
      if (scalar(@genes) > 1) { 
          my $drivenGene = shift @genes; $drivenGene = '"' . $drivenGene . '"';
          &addToPg('cns_drivenbygene', $pgid, $drivenGene);
          print qq(ADD $drivenGene TO cns_drivenbygene\n);
          my $otherGenes = join'","', @genes; $otherGenes = '"' . $otherGenes . '"';
          &addToPg('cns_gene', $pgid, $otherGenes);
          print qq(ADD $otherGenes TO cns_gene\n); }
        elsif (scalar(@genes) > 0) { 
          my $otherGenes = '"' . $genes[0] . '"'; 
          if ($constructtype[0]) { if ($constructtype[0] eq 'Translational_fusion') { 
            &addToPg('cns_gene', $pgid, $otherGenes);
            print qq(ADD $otherGenes TO cns_gene\n); } }
          &addToPg('cns_drivenbygene', $pgid, $otherGenes);
          print qq(ADD $otherGenes TO cns_drivenbygene\n); }
    }
    else { print qq(ERR $pgid no summary matched\n); }
  if (scalar @constructtype > 1) { print qq(ERR $pgid too many constructtype @constructtype\n); }
    elsif (scalar @constructtype == 1) { 
      my $constructtypeError = 0;
      if ($hash{'constructtype'}{$pgid}) {
#         print qq($pgid OLD CONSTRUCTTYPE $hash{'constructtype'}{$pgid} now $constructtype[0]\n); 
        if ($hash{'constructtype'}{$pgid} ne $constructtype[0]) {
          print qq(ERR $pgid OLD CONSTRUCTTYPE $hash{'constructtype'}{$pgid} now $constructtype[0]\n); $constructtypeError++; } }
      unless ($constructtypeError) { 
        &addToPg('cns_constructtype', $pgid, $constructtype[0]);
        print qq($pgid cns_constructtype $constructtype[0]\n); } }
  if (scalar @reporter > 0) {
    my $reporter = join'","', @reporter; $reporter = '"'. $reporter . '"';
    &addToPg('cns_reporter', $pgid, $reporter);
    print qq($pgid cns_reporter $reporter\n); }
  if (scalar @atcg > 2) { print qq(ERR $pgid too many atcg @atcg\n); }
    elsif (scalar @atcg > 1) {
      my $fwdprimer = $atcg[0];
      my $revprimer = $atcg[1];
      if ($hash{'fwdprimer'}{$pgid}) { 
        print qq(CHECK $pgid OLD fwdprimer $hash{'fwdprimer'}{$pgid} NOW $fwdprimer\n); }
      if ($hash{'revprimer'}{$pgid}) { 
        print qq(CHECK $pgid OLD revprimer $hash{'revprimer'}{$pgid} NOW $revprimer\n); }
      &addToPg('cns_fwdprimer', $pgid, $fwdprimer);
      &addToPg('cns_revprimer', $pgid, $revprimer);
      print qq($pgid fwdprimer $fwdprimer\n);
      print qq($pgid revprimer $revprimer\n); 
    }
    elsif (scalar @atcg > 0) {
      print qq(ERR $pgid only has one ATCG $atcg[0]\n); }
  
  my %cloneMatches;
  foreach my $origword (@allWords) {
    my $word = lc($origword);
    if ($word =~ m/,/) { $word =~ s/,//g; }
    if ($word =~ m/\(/) { $word =~ s/\(//g; }
    if ($word =~ m/\)/) { $word =~ s/\)//g; }
    if ($word =~ m/;/) { $word =~ s/;//g; }
    if ($clones{$word}) { $cloneMatches{$clones{$word}}++; }
  } # foreach my $word (@allWords)
  my $clones = join'","', sort keys %cloneMatches;
  if ($hash{'clone'}{$pgid}) {
    print qq(CHECK $pgid OLD clone $hash{'clone'}{$pgid} NOW "${clones}"\n); }
  if ($clones) { 
    $clones = '"' . $clones . '"';
    &addToPg('cns_clone', $pgid, $clones);
    print qq($pgid cns_clone $clones\n); }

} # foreach my $pgid (sort {$a<=>$b} keys %{ $hash{'constructionsummary'} })

close (PG) or die "Cannot close $pgfile : $!";

sub addToPg {
  my ($table, $pgid, $data) = @_;
  if ($data =~ m/\'/) { $data =~ s/\'/''/g; }
  my @pgcommands; my $pgcommand;
  $pgcommand = qq(DELETE FROM $table WHERE joinkey = '$pgid';);
  push @pgcommands, $pgcommand;
  $pgcommand = qq(INSERT INTO $table VALUES ('$pgid', '$data'););
  push @pgcommands, $pgcommand;
  $pgcommand = qq(INSERT INTO ${table}_hst VALUES ('$pgid', '$data'););
  push @pgcommands, $pgcommand;
#   print PG qq($pgid TO $table WITH $data\n);
  foreach my $pgcommand (@pgcommands) {
    print PG qq($pgcommand\n);
# UNCOMMENT TO POPULATE
#     $dbh->do( $pgcommand );
  } # foreach my $pgcommand (@pgcommands)
} # sub addToPg


__END__

Consider only entries that have Daniela -WBPerson12028- as curator

For entries that have text in the remark (cns_remark) and NO text in the Construction details (empty Construction Details)-cns_constructionsummary:
transfer the text from cns_remark to cns_constructionsummary and then follow the INSTRUCTIONS


For entries that have text in the cns_constructionsummary and empty Driven_by_gene (cns_drivenbygene) and Reporter (cns_reporter) fields. Leave the text in cns_constructionsummary and follow the INSTRUCTIONS


INSTRUCTIONS

-the text between square brackets should be copied to the Summary field -cns_summary

e.g.: [dlc-5::GFP] transcriptional fusion. Transcriptional GFP expression constructs were designed by inserting promoter regions and the first several codons of a gene of interest into the GFP expression vectors pPD95.75 or pPD95.77 (gift from A. Fire).

[dlc-5::GFP] should be copied into the Summary field


- transcriptional or translational fusion should populate cns_constructtype. If both transcriptional and translational fusions are mentioned can we populate with both and print out those objects so I will then evaluate manually?

- GFP, mcherry and so on should go populate the reporter field -cns_reporter

(controlled vocabulary on GFP, GFP(S65C), EGFP, pGFP(photoactivated GFP), YFP, EYFP, BFP, CFP, Cerulian, RFP, mRFP, tagRFP, mCherry, wCherry, tdTomato, mStrawberry, DsRed, DsRed2, Venus, YC2.1 (yellow cameleon), YC12.12 (yellow cameleon),YC3.60 (yellow cameleon), Yellow cameleon, Dendra, Dendra2, tdimer2(12)/dimer2, GCaMP, mkate2, Luciferase, LacI, LacO, LacZ) 

- whenever there is a >10 ATG DNA text, copy the first one in cns_fwdprimer and the second one in the  cns_revprimer. If there are 3 such DNAtext populate as above but print them so I can revise

- populate driven by gene (cns_drivenbygene) with the gene that is in the square brackets (3 letters hyphen). If the gene name is preceded by a p, ignore the p. Example pegl-1, ignore the p. there will be few cases in which the p is a fifth letter, e.g.: Pfaah-1. If 2 genes are mentioned the first should populate cns_drivenbygene and the second cns_gene. e.g. odr-3::unc-43::GFP odr-3 will go into cns_drivenbygene and unc-43 in cns_gene

- if only one gene is mentioned but there is the translational fusion text both cns_drivenbygene and cns_gene should both be populated with that gene. E.g.: [fln-1::GFP] translational fusion. fln-1 will go into cns_drivenbygene and in cns_gene

- if in the text there is mention of a clone, e.g. pPD95.75 (there is an ontology on clones) populate the cns_clone with those values



