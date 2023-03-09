#!/usr/bin/perl

# for peter frommolt, trying to get PMIDs 3rd in Database tag in Paper model.  2010 10 19

use Ace;
$db=Ace->connect(-host=>'aceserver.cshl.org',-port=>'2005');

# my $aql_injectors = 'select a,b,c,d from a in class Gene where a.name like (...), b in a->Interaction, c in b->Paper, d in c->PMID';
# my $aql_injectors = 'select a from a in class Gene where a.name like "WBGene00003003"';
# my $aql_injectors = 'select a, b from a in class Gene where b in a->Interaction';
# my $aql_injectors = 'select a, b, c from a in class Gene where b in a->Interaction, c in b->Interactor';
# my $aql_injectors = 'select a, b, c from a in class Gene where a.name like "WBGene00003003", b in a->Interaction, c in b->Interactor';
my $aql_injectors = 'select a, b, c, d from a in class Gene where a.name like "WBGene00003003", b in a->Interaction, c in b->Paper, d in c->Database[3], c->Database = "PMID"';
my @objects = $db->aql($aql_injectors);
foreach my $object (@objects) {
  print "OBJ $object OBJ\n";
  my $text = join"\t", @$object;
#   $hash{$$object[2]}++;
  print "$text\n";
}


__END__

$paper=$db->fetch(Paper=>'WBPaper00030003');
# @pages=$paper->Page->asString;
# $pages = join", ", @pages;
# print "$paper : $pages\n";
@authors=$paper->Author;
foreach my $author (@authors) {
  my $adata = $author->asString;
  print "$paper : $author : $adata\n";
}
# $pages = join", ", @pages;
# print "$paper : $pages\n";

# foreach my $int (@expinfo) {
#   my (@interactors) = $int->Interactor;
#   my $interactors = join", ", @interactors;
#   print "$int\t$interactors\n";
# #   my @int_type = $int->Interaction_type;
# #   my $int_types = join", ", @int_type;
# #   my (@papers) = $int->Paper;
# #   my $papers = join", ", @papers;
# #   print "$int\t$int_types\t$papers\n";
# #   print "$string\n";
# }

# my $aql_interactors = 'select a, b, c from a in class Gene where a.name like "WBGene00003003", b in a->Interaction, c in b->Interactor';
# my @objects = $db->aql($aql_interactors);
# foreach my $object (@objects) {
#   my $text = join"\t", @$object;
#   $hash{$$object[2]}++;
# #   print "$text\n";
# }
# foreach (sort keys %hash) { print "$_\n"; }

# $mygene=$db->fetch(Gene=>'WBGene00003003');
# @expinfo=$mygene->Interaction;
# 
# foreach my $int (@expinfo) {
#   my (@interactors) = $int->Interactor;
#   foreach (@interactors) { $hash{$_}++; }
# }
# foreach (sort keys %hash) { print "$_\n"; }

