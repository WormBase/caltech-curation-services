#!/usr/bin/perl -w

# pared down version of 
# /home/postgres/work/pgpopulation/obo_oa_ontologies/update_obo_oa_ontologies.pl



use strict;
use diagnostics;
use DBI;
use LWP::Simple;
use LWP;
use Crypt::SSLeay;				# for LWP to get https


my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my $directory = '/home/acedb/chris/Phenotype/oa_phenotype_update/';
chdir ($directory) or die "Cannot chdir to $directory : $!";


my %obos;
$obos{phenotype} = 'https://raw.githubusercontent.com/obophenotype/c-elegans-phenotype-ontology/master/wbphenotype.obo';	# new file for Chris  2019 05 14
$obos{lifestage} = 'https://raw.githubusercontent.com/obophenotype/c-elegans-development-ontology/master/wbls.obo';
# $obos{phenotype} = 'https://raw.githubusercontent.com/obophenotype/c-elegans-phenotype-ontology/master/wbphenotype-merged.obo';	# gets from github for Chris  2019 03 12
# $obos{phenotype} = 'https://raw.githubusercontent.com/obophenotype/c-elegans-phenotype-ontology/master/src/ontology/wbphenotype-merged.obo';	# gets from github for Chris  2018 11 15
# $obos{phenotype} = 'http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/phenotype_ontology_obo.cgi';	# gets from cvs from spica	# removed for Chris 2018 11 15
# owl https://raw.githubusercontent.com/obophenotype/c-elegans-phenotype-ontology/master/wbphenotype.owl


$/ = undef;
foreach my $obotable (sort keys %obos) {
  print "getting $obotable\n";
  my $new_data = get $obos{$obotable};
  print "got $obotable\n";
  my $file_name = $directory . 'obo_' . $obotable;
  my $file_data = ""; my $file_date = 0;
  if (-r $file_name) {
    open (IN, "<$file_name") or die "Cannot open $file_name : $!";
    $file_data = <IN>;
    close (IN) or die "Cannot close $file_name : $!";
    if ( $file_data =~ m/date: (\d+):(\d+):(\d+).(\d+):(\d+)/ ) {
        my ($day, $month, $year, $hour, $minute) = $file_data =~ m/date: (\d+):(\d+):(\d+).(\d+):(\d+)/;
        $file_date = $year . $month . $day . $hour . $minute; }
      elsif ( $file_data =~ m/data-version: .*?releases\/(\d+)-(\d+)-(\d+)/ ) {
        my ($year, $month, $day) = $file_data =~ m/data-version: .*?releases\/(\d+)-(\d+)-(\d+)/;
        $file_date = $year . $month . $day . '0000'; }
  }
  my $new_date = 0;
  if ($new_data =~ m/date: (\d+):(\d+):(\d+).(\d+):(\d+)/) {
      my ($day, $month, $year, $hour, $minute) = $new_data =~ m/date: (\d+):(\d+):(\d+).(\d+):(\d+)/;
      $new_date = $year . $month . $day . $hour . $minute; }
    elsif ( $new_data =~ m/data-version: .*?releases\/(\d+)-(\d+)-(\d+)/ ) {
      my ($year, $month, $day) = $new_data =~ m/data-version: .*?releases\/(\d+)-(\d+)-(\d+)/;
      $new_date = $year . $month . $day . '0000'; }
  if ($new_date) {
#     if ($new_date > $file_date) {
      &updateData($obotable, $file_name, $new_data);
#     } # if ($new_date > $file_date)
  } # if ($new_data =~ m/date: (\d+):(\d+):(\d+) (\d+):(\d+)/)
} # foreach my $obotable (sort keys %obos) 
$/ = "\n";


sub updateData {
  my ($obotable, $file_name, $new_data) = @_;
  my @tables = qw( name syn data );
  foreach my $table_type (@tables) {
    my $table = 'obo_' . $table_type . '_' . $obotable;
    print "DELETE FROM $table; \n";
    $result = $dbh->do("DELETE FROM $table; ");
  }
  my (@terms) = split/\[Term\]/, $new_data;
  my $term = shift @terms;	# junk header
  my %children; my %names;
  if ($obotable eq 'phenotype') {
    foreach $term (@terms) {
      my ($id) = $term =~ m/\nid: (.*?)\n/;
      my ($name) = $term =~ m/\nname: (.*?)\n/;
      $names{$id} = $name;
      my (@parents) = $term =~ m/is_a: (WBPhenotype:\d+)/g;
      foreach my $parent (@parents) { $children{$parent}{"$id \! $name"}++; }
      (@parents) = $term =~ m/relationship: part_of (WBPhenotype:\d+)/g;
      foreach my $parent (@parents) { $children{$parent}{"$id \! $name"}++; }
    }
  }
  foreach $term (@terms) {
    my $skipTerm = 0;
    $term =~ s/\\//g;		# strip \ escaped data
# print "1TERM $term 1END\n\n";
    my @syns = ();
    my ($id) = $term =~ m/\nid: (.*?)\n/;
    if ($obotable eq 'chebi') { $id =~ s/CHEBI://; }
    my ($name) = $term =~ m/\nname: (.*?)\n/;
    if ($name) { $name =~ s/\"//g; $name =~ s/\'/''/g; }
    if ($term =~ m/\nsynonym: \"(.*?)\"/) {
      (@syns) = $term =~ m/\nsynonym: \"(.*?)\"/g; }
    $term =~ s/^\s+//sg; $term =~ s/\s+$//sg; $term =~ s/\'/''/g; 
    if ($obotable eq 'chebi') { 
      $term = 'chebi link: <a href="http://www.ebi.ac.uk/chebi/" target="new">http://www.ebi.ac.uk/chebi/</a>' . "<br />\n" . $term;
      if ($term =~ m/name: (.*)\n/) {
        $term =~ s/name: (.*)\n/name: <a href=\"http:\/\/www.ebi.ac.uk\/chebi\/advancedSearchFT.do?searchString=$1&queryBean.stars=-1\" target=\"new\">$1<\/a>\n/g; } }
    elsif ($obotable =~ m/^goid/) {
      if ($term =~ m/(GO:\d+)/) {
#         $term =~ s/(GO:\d+)/<a href=\"http:\/\/amigo.geneontology.org\/cgi-bin\/amigo\/term-details.cgi?term=$1\" target=\"new\">$1<\/a>/g; 	# karen said this link is obsolete, changed from term-details.cgi to term_details  2013 09 20
        $term =~ s/(GO:\d+)/<a href=\"http:\/\/amigo.geneontology.org\/cgi-bin\/amigo\/term_details?term=$1\" target=\"new\">$1<\/a>/g; } 
      if ($obotable eq 'goidfunction') {   unless ($term =~ m/namespace: molecular_function/) { $skipTerm++; } }	# skip terms in different namespace
      if ($obotable eq 'goidcomponent') {  unless ($term =~ m/namespace: cellular_component/) { $skipTerm++; } }	# skip terms in different namespace
      if ($obotable eq 'goidprocess') {    unless ($term =~ m/namespace: biological_process/) { $skipTerm++; } }	# skip terms in different namespace
    }
    elsif ($obotable eq 'phenotype') {
#       if ($term =~ m/is_obsolete: true/) { $skipTerm++; }	# gary and chris want obsolete phenotype terms excluded	# allow obsolete terms now for Chris 2019 08 22
      if ($id !~ m/WBPhenotype/) { $skipTerm++; }		# only read in WBPhenotype terms
      $term =~ s/is_a:/parent:/g;
      $term =~ s/relationship: part_of/parent:/g;
      $term =~ s/\nparent/\n<hr>parent/;
      foreach my $child_term (sort keys %{ $children{$id} }) { $term .= "\nchild: $child_term"; } 
      my $url = "ontology_annotator.cgi?action=oboFrame&obotable=$obotable&term_id=";
      $term =~ s/(WBPhenotype:\d+) \! ([\w ]+)/<a href=\"${url}$1\">$2<\/a>/g;
    }
    elsif ($obotable eq 'anatomy') {
      if ($term =~ m/alt_id: (WBbt:\d+)/) {
        my (@alt) = $term =~ m/alt_id: (WBbt:\d+)/g;
#         foreach my $alt_id (@alt) {		# these don't seem to work
#           my $table = 'obo_name_anatomy';
#           $result = $dbh->do("INSERT INTO $table VALUES( '$alt_id', 'alt_id for $id') ");
#           $table = 'obo_data_anatomy';
#           $result = $dbh->do("INSERT INTO $table VALUES( '$alt_id', 'alt_id for $id') "); } 
      } }
    next if ($skipTerm);		# skip terms
    my $table = 'obo_name_' . $obotable;
    if ($name) { $result = $dbh->do("INSERT INTO $table VALUES( '$id', '$name') "); }
    $table = 'obo_data_' . $obotable;
    my (@term) = split/\n/, $term;
    foreach my $term_line (@term) { 
      if ($term_line =~ m/^is_obsolete: true/) {
        $term_line =~ s/is_obsolete: true/<span style=\"font-weight: bold; color:red\">is_obsolete: true<\/span>/g; }
      else {
        $term_line =~ s/^(.*?):/<span style=\"font-weight: bold\">$1 : <\/span>/; } }
    $term = join"\n", @term;
    $result = $dbh->do("INSERT INTO $table VALUES( '$id', '$term') ");
    $table = 'obo_syn_' . $obotable;
    foreach my $syn (@syns) { $syn =~ s/\'/''/g; 
      $result = $dbh->do("INSERT INTO $table VALUES( '$id', '$syn') "); }
  } # foreach $term (@terms)
  open (OUT, ">$file_name") or die "Cannot write to $file_name : $!"; 
  binmode OUT, ':utf8';
  print OUT "$new_data";
  close (OUT) or die "Cannot close $file_name : $!"; 
} # sub updateData


__END__

