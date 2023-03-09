#!/usr/bin/perl -w

# Get data from aceserver for Carol for Gene to RNAi / Variation / Transgene
# 0 4 * * tue,wed,thu,fri,sat /home/azurebrd/public_html/sanger/gene_rnai_variation_transgene/update_gene_rnai_variation_transgene.pl



use strict;
use diagnostics;

use Jex;
use Ace;

my $directory = '/home/azurebrd/public_html/sanger/gene_rnai_variation_transgene';
chdir($directory) or die "Cannot go to $directory ($!)";



use constant HOST => $ENV{ACEDB_HOST} || 'aceserver.cshl.org';
use constant PORT => $ENV{ACEDB_PORT} || 2005;

my $s_time = time;

my $db = Ace->connect(-host=>HOST,-port=>PORT) or warn "Connection failure: ",Ace->error;

# my $db = Ace->connect(-path=>'/home2/acedb/WS_current', -program=>'/home/acedb/bin/tace') or warn "Connection failure: ",Ace->error;

# my $aql_rnai_n = 'select a, b, c, d from a in class Gene, b in a ->cgc_name, c in a->RNAi_result, d in c ->Phenotype where not exists_tag d[Not]';
# my $aql_rnai = 'select a, b, c, d from a in class Gene, b in a ->cgc_name, c in a->RNAi_result, d in c ->Phenotype where exists_tag d[Not]';
# my $aql_variation_n = 'select a, b, c, d from a in class Gene, b in a ->cgc_name, c in a ->Allele, d in c ->Phenotype where not exists_tag d[Not]';
# my $aql_variation = 'select a, b, c, d from a in class Gene, b in a ->cgc_name, c in a ->Allele, d in c ->Phenotype where exists_tag d[Not]';
# my $aql_transgene_n = 'select a, b, c, d from a in class Gene, b in a ->cgc_name, c in a ->Transgene_product, d in c ->Phenotype where not exists_tag d[Not]';
# my $aql_transgene = 'select a, b, c, d from a in class Gene, b in a ->cgc_name, c in a ->Transgene_product, d in c ->Phenotype where exists_tag d[Not]';
my $aql_rnai = 'select a, b, c, d, e from a in class Gene, b in a->cgc_name, c in a -> Sequence_name, d in a->RNAi_result, e in d->Phenotype where d[2]="RNAi_primary" and not exists_tag e[Not]';
my $aql_rnai_n = 'select a, b, c, d, e from a in class Gene, b in a->cgc_name, c in a -> Sequence_name, d in a->RNAi_result, e in d->Phenotype where d[2]="RNAi_primary" and exists_tag e[Not]';
my $aql_transgene = 'select a, b, c, d, e from a in class Gene, b in a->cgc_name, c in a -> Sequence_name, d in a->Transgene_product, e in d->Phenotype where not exists_tag e[Not]';
my $aql_transgene_n = 'select a, b, c, d, e from a in class Gene, b in a->cgc_name, c in a -> Sequence_name, d in a->Transgene_product, e in d->Phenotype where exists_tag e[Not]';
my $aql_variation = 'select a, b, c, d, e from a in class Gene, b in a->cgc_name, c in a -> Sequence_name, d in a->Allele, e in d->Phenotype where not exists_tag e[Not]';
my $aql_variation_n = 'select a, b, c, d, e from a in class Gene, b in a->cgc_name, c in a -> Sequence_name, d in a->Allele, e in d->Phenotype where exists_tag e[Not]';


my $date = &getSimpleSecDate();

my @objects = $db->aql($aql_rnai);
my $data = '';
foreach my $object (@objects) {
  my $text = join"\t", @$object;
  $data .= "$text\n"; }
my $outfile = '/home/azurebrd/public_html/sanger/gene_rnai_variation_transgene/rnai_phenotypes';
$/ = undef;
open (IN, "<$outfile") or die "Cannot open $outfile : $!";
my $old_data = <IN>;
close (IN) or die "Cannot close $outfile : $!";
if ($data ne $old_data) {
  open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
  print OUT $data;
  close (OUT) or die "Cannot close $outfile : $!";
  $outfile = '/home/azurebrd/public_html/sanger/gene_rnai_variation_transgene/old/rnai_phenotypes.' . $date;
  open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
  print OUT $data;
  close (OUT) or die "Cannot close $outfile : $!";
}

@objects = $db->aql($aql_rnai_n);
$data = '';
foreach my $object (@objects) {
  my $text = join"\t", @$object;
  $data .= "$text\n"; }
$outfile = '/home/azurebrd/public_html/sanger/gene_rnai_variation_transgene/rnai_not_phenotypes';
open (IN, "<$outfile") or die "Cannot open $outfile : $!";
$old_data = <IN>;
close (IN) or die "Cannot close $outfile : $!";
if ($data ne $old_data) {
  open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
  print OUT $data;
  close (OUT) or die "Cannot close $outfile : $!";
  $outfile = '/home/azurebrd/public_html/sanger/gene_rnai_variation_transgene/old/rnai_not_phenotypes.' . $date;
  open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
  print OUT $data;
  close (OUT) or die "Cannot close $outfile : $!";
}

@objects = $db->aql($aql_variation);
$data = '';
foreach my $object (@objects) {
  my $text = join"\t", @$object;
  $data .= "$text\n"; }
$outfile = '/home/azurebrd/public_html/sanger/gene_rnai_variation_transgene/allele_phenotypes';
open (IN, "<$outfile") or die "Cannot open $outfile : $!";
$old_data = <IN>;
close (IN) or die "Cannot close $outfile : $!";
if ($data ne $old_data) {
  open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
  print OUT $data;
  close (OUT) or die "Cannot close $outfile : $!";
  $outfile = '/home/azurebrd/public_html/sanger/gene_rnai_variation_transgene/old/allele_phenotypes.' . $date;
  open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
  print OUT $data;
  close (OUT) or die "Cannot close $outfile : $!";
}
 
@objects = $db->aql($aql_variation_n);
$data = '';
foreach my $object (@objects) {
  my $text = join"\t", @$object;
  $data .= "$text\n"; }
$outfile = '/home/azurebrd/public_html/sanger/gene_rnai_variation_transgene/allele_not_phenotypes';
open (IN, "<$outfile") or die "Cannot open $outfile : $!";
$old_data = <IN>;
close (IN) or die "Cannot close $outfile : $!";
if ($data ne $old_data) {
  open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
  print OUT $data;
  close (OUT) or die "Cannot close $outfile : $!";
  $outfile = '/home/azurebrd/public_html/sanger/gene_rnai_variation_transgene/old/allele_not_phenotypes.' . $date;
  open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
  print OUT $data;
  close (OUT) or die "Cannot close $outfile : $!";
}

@objects = $db->aql($aql_transgene);
$data = '';
foreach my $object (@objects) {
  my $text = join"\t", @$object;
  $data .= "$text\n"; }
$outfile = '/home/azurebrd/public_html/sanger/gene_rnai_variation_transgene/transgene_phenotypes';
open (IN, "<$outfile") or die "Cannot open $outfile : $!";
$old_data = <IN>;
close (IN) or die "Cannot close $outfile : $!";
if ($data ne $old_data) {
  open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
  print OUT $data;
  close (OUT) or die "Cannot close $outfile : $!";
  $outfile = '/home/azurebrd/public_html/sanger/gene_rnai_variation_transgene/old/transgene_phenotypes.' . $date;
  open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
  print OUT $data;
  close (OUT) or die "Cannot close $outfile : $!";
}

@objects = $db->aql($aql_transgene_n);
$data = '';
foreach my $object (@objects) {
  my $text = join"\t", @$object;
  $data .= "$text\n"; }
$outfile = '/home/azurebrd/public_html/sanger/gene_rnai_variation_transgene/transgene_not_phenotypes';
open (IN, "<$outfile") or die "Cannot open $outfile : $!";
$old_data = <IN>;
close (IN) or die "Cannot close $outfile : $!";
if ($data ne $old_data) {
  open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
  print OUT $data;
  close (OUT) or die "Cannot close $outfile : $!";
  $outfile = '/home/azurebrd/public_html/sanger/gene_rnai_variation_transgene/old/transgene_not_phenotypes.' . $date;
  open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
  print OUT $data;
  close (OUT) or die "Cannot close $outfile : $!";
}





my $time = time;
my $diff = $time - $s_time;
# print "$diff\n";

__END__

my $query = "find Gene WBGene00001228";
my @genes = $db->fetch(-query=>$query);
foreach my $gene (@genes) {
  my @rnai = $gene->RNAi_result;
  foreach my $rnai (@rnai) { 
    print "aceserver found rnai $rnai gene $gene\n"; 
    my $query = "find RNAi $rnai";
    my @rnai = $db->fetch(-query=>$query);
    foreach my $rnai (@rnai) {
my $remark = $rnai->Phenotype->Remark;
print "BLAH $remark\n";
      my @phenotype = $rnai->Phenotype;
      foreach my $phen (@phenotype) { 
        print "aceserver found phen $phen rnai $rnai gene $gene\n"; 
        my $remark = $phen->Remark;
        if ($remark) { print "Rem $remark\n"; }
        if ($rnai->Remark) { print "Rem $rnai->Remark\n"; }
#         if ($rnai->Not) { print "Not $rnai->Not\n"; }
      }
    } # foreach my $rnai (@rnai)
  }
}
my $time = time;
my $diff = $time - $s_time;
print "$diff\n";

__END__

my $query = "find Gene";
my @genes = $db->fetch(-query=>$query);
foreach my $gene (@genes) {
  my @rnai = $gene->RNAi_result;
  foreach my $rnai (@rnai) { 
    print "aceserver found rnai $rnai gene $gene\n"; 
  }
  my @variation = $gene->Allele;
  foreach my $variation (@variation) {
    print "aceserver found variation $variation gene $gene\n"; 
  }
  my @transgene = $gene->Transgene_product;
  foreach my $transgene (@transgene) {
    print "aceserver found transgene $transgene gene $gene\n"; 
  }
} 
my $time = time;
my $diff = $time - $s_time;
print "$diff\n";

__END__

my $query = "find Gene RNAi_result";
my @genes = $db->fetch(-query=>$query);
foreach my $gene (@genes) {
  my @rnai = $gene->RNAi_result;
  foreach my $rnai (@rnai) { 
    print "aceserver found rnai $rnai gene $gene\n"; 
  }
} 
my $time = time;
my $diff = $time - $s_time;
print "$diff\n";

$query = "find Gene Allele";
@genes = $db->fetch(-query=>$query);
foreach my $gene (@genes) {
  my @variation = $gene->Allele;
  foreach my $variation (@variation) {
    print "aceserver found variation $variation gene $gene\n"; 
  }
} 
$time = time;
$diff = $time - $s_time;
print "$diff\n";

$query = "find Gene Transgene_product";
@genes = $db->fetch(-query=>$query);
foreach my $gene (@genes) {
  my $transgene = $gene->Transgene_product;
  print "aceserver found transgene $transgene gene $gene\n"; 
} 
$time = time;
$diff = $time - $s_time;
print "$diff\n";

# close (TRA) or die "Cannot close $t_outfile : $!";
# close (VAR) or die "Cannot close $v_outfile : $!";
# close (RNA) or die "Cannot close $r_outfile : $!";


# my $tempname = 'WBPaper00000003';
# my $query = "find Paper $tempname";
# my @rnai = $db->fetch(-query=>$query);
# if ($rnai[0]) { print "aceserver found $rnai[0]<BR>\n"; $found++; }
# if ($found) { print "Based on aceserver, finalname should be : $tempname ; RNAi does not query out wbgene.<BR>\n"; }


__END__

my @authors = $db->list('Author','Q*');
print "There are ",scalar(@authors)," Author objects starting with the letter \"S\".\n";
print "The first one's name is ",$authors[0],"\n";
print "His mailing address is ",join(',',$authors[0]->Mail),"\n";
my @papers = $authors[0]->Paper;
print "He has published ",scalar(@papers)," papers.\n";
my $paper = $papers[$#papers]->pick;
print "The title of his most recent paper is ",$paper->Title,"\n";
print "The coauthors were ",join(", ",$paper->Author->col),"\n";
print "Here is all the information on the first coauthor:\n";
print (($paper->Author)[0]->fetch->asString);
