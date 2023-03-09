#!/usr/bin/perl

# generate set of genes exclusively annotated to anatomy terms.
# http://wormbase.caltech.edu:8080/wormbase/manual/wobr/genes-exclusively-annotated-to

use strict;
use LWP::Simple;
use JSON;
# use DBI;

my $json = JSON->new->allow_nonref;

# my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n";
# my $result;

my %anatName;

# $result = $dbh->prepare( "SELECT * FROM obo_name_anatomy" );
# $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
# while (my @row = $result->fetchrow) { $anatName{$row[0]} = $row[1]; }


my $base_solr_url = 'http://131.215.12.204:8080/solr/anatomy/';

# my $q0 = 'select?qt=standard&fl=id&version=2.2&wt=json&indent=on&rows=100000&q=document_category:%22ontology_class%22';
# my $q0 = 'select?qt=standard&fl=id&version=2.2&wt=json&indent=on&rows=100000&q=document_category:%22ontology_class%22&fq=id:WBbt*&fq=-is_obsolete:true';
my $q0 = 'select?qt=standard&fl=id,annotation_class_label&version=2.2&wt=json&indent=on&rows=100000&q=document_category:"ontology_class"&fq=id:WBbt*&fq=-is_obsolete:true';	# with anatomy names

my $url = $base_solr_url . $q0;
my $page_data = get $url;
my $perl_scalar = $json->decode( $page_data );                        # get the solr data
my %jsonHash = %$perl_scalar;

# my $topoArrayref  = $json->decode( $jsonHash{"response"}{"docs"}[0] );
# my @array = @$topoArrayref;
# foreach my $entry (@array) { 
#   print "$entry : $array[$entry]\n";
# } 

my %anatomy;
foreach my $hashRef (@{ $jsonHash{"response"}{"docs"} }) {
  my $id   = $$hashRef{'id'};
  $anatomy{exists}{$id}++;
  my $name = $$hashRef{'annotation_class_label'};
  $anatName{$id} = $name;
}

my $testAnat = 'WBbt:0005237';
my $testGene = 'WBGene00044330';
my %anatToGeneCount;
my %allGenes;

foreach my $anatomyFocus (sort keys %{ $anatomy{exists} }) {
  next unless ($anatomyFocus =~ m/^WBbt/);
#   next unless ($anatomyFocus eq $testAnat);
#   print "$anatomyFocus\n";
  my %q1;
  my $q1 = $base_solr_url . "select?qt=standard&fl=id&version=2.2&wt=json&indent=on&rows=100000&q=isa_partof_closure:%22" . $anatomyFocus . "%22&fq=document_category:%22ontology_class%22";
#   print "Q1 $q1 URL\n";
  my $page_data = get $q1;
  my $perl_scalar = $json->decode( $page_data );                        # get the solr data
  my %jsonHash = %$perl_scalar;
  foreach my $otheranat (@{ $jsonHash{"response"}{"docs"} }) {
#     print "$$otheranat{'id'}\n";
    my $anatId = $$otheranat{'id'};
    $anatomy{q1}{$anatomyFocus}{$anatId}++;
    $q1{$anatId}++;
  }

  my %q2;
  my $q2 = $base_solr_url . 'select?qt=standard&indent=on&wt=json&version=2.2&fl=id,bioentity_label&start=0&rows=10000000&q=document_category:bioentity&fq=source:%22WB%22&fq=%7B!cache=false%7Dregulates_closure:%22' . $anatomyFocus . '%22';
#   print "Q2 $q2 URL\n";
  my $page_data = get $q2;
  my $perl_scalar = $json->decode( $page_data );                        # get the solr data
  my %jsonHash = %$perl_scalar;
  foreach my $genes (@{ $jsonHash{"response"}{"docs"} }) {
#     print "$$genes{'id'}\n";
    my $wbgene   = $$genes{'id'};
    my $genename = $$genes{'bioentity_label'};
    if ($wbgene =~ m/^WB:/) { $wbgene =~ s/^WB://; }
    $q2{$wbgene}++;
    $anatomy{q2}{$anatomyFocus}{$wbgene}++;
    $allGenes{$wbgene} = $genename;
  }
  my $geneCount = scalar keys %q2;
  $anatToGeneCount{$anatomyFocus} = $geneCount;
  
#   foreach my $q1 (sort keys %q1) { print qq($q1\n); }
#   foreach my $q2 (sort keys %q2) { print qq($q2\n); }
} # foreach my $anatomyFocus (sort keys %{ $anatomy{exists} })

# foreach my $anatomy (sort {$anatToGeneCount{$b}<=>$anatToGeneCount{$a}} keys %anatToGeneCount) { print qq($anatomy\t$anatToGeneCount{$anatomy}\n); }

my $allGeneCount = scalar keys %allGenes;
# print qq(Total genes seen in q3s $allGeneCount\n);

my %geneToAnat;
foreach my $wbgene (sort keys %allGenes) {
#   print qq(Existing gene $gene\n);
#   next unless ($wbgene eq $testGene);
  my $q3 = $base_solr_url . 'select?qt=standard&indent=on&wt=json&version=2.2&fl=annotation_class_list&start=0&rows=10000000&q=document_category:bioentity&fq=source:%22WB%22&fq=id:%22WB:' . $wbgene . '%22';
#   print "Q3 $q3 URL\n";
  my $page_data = get $q3;
  my $perl_scalar = $json->decode( $page_data );                        # get the solr data
  my %jsonHash = %$perl_scalar;
  foreach my $wbbt (@{ $jsonHash{"response"}{"docs"}[0]{"annotation_class_list"} }) {
    $geneToAnat{$wbgene}{$wbbt}++;
#     print qq(WBBT $wbbt E\n);
  }
} # foreach my $gene (sort keys %allGenes)

# for each anatomy term ; for each gene from q2, get list of wbbt from q3, if any wbbt are not in q1, skip from output gene list.
foreach my $anatomyFocus (sort keys %{ $anatomy{exists} }) {
  next unless ($anatomyFocus =~ m/^WBbt/);
#   next unless ($anatomyFocus eq $testAnat);
  my @geneList; 
  foreach my $wbgene ( sort keys %{ $anatomy{q2}{$anatomyFocus} } ) {
    my $skipGene = 0;
    foreach my $wbbt (sort keys %{ $geneToAnat{$wbgene} }) {
      unless ( $anatomy{q1}{$anatomyFocus}{$wbbt} ) { $skipGene++; }
    }
    unless ($skipGene) { push @geneList, qq($wbgene - $allGenes{$wbgene}); }
  } # foreach my $gene (sort keys %geneToAnat)
  my $anatName = $anatName{$anatomyFocus};
  my $geneList = join", ", @geneList;
#   print qq($anatomyFocus\t$anatName\t$geneList\n);
  my $countGenes = scalar @geneList;
  if ($countGenes) { print qq($anatomyFocus\t$anatName\t$countGenes\t$geneList\n); }
}


# q1 "select?qt=standard&fl=id&version=2.2&wt=json&indent=on&rows=100000&q=isa_partof_closure:%22" . $focusTermId . "%22&fq=document_category:%22ontology_class%22"
# 
# q2 "select?qt=standard&indent=on&wt=json&version=2.2&fl=id,bioentity_label&start=0&rows=10000000&q=document_category:bioentity&fq=source:%22WB%22&fq=%7B!cache=false%7Dregulates_closure:%22' . $focusTermId . '%22'"
# 
# q3 "select?qt=standard&indent=on&wt=json&version=2.2&fl=annotation_class_list&start=0&rows=10000000&q=document_category:bioentity&fq=source:%22WB%22&fq=id:%22' . $gene_id . '%22'"

