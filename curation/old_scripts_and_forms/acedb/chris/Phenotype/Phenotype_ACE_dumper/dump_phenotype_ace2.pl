#!/usr/bin/perl

# Checkout PhenOnt.obo and process for .ace output
# For Carol.  2006 01 11
#
# Check for obsoletes and put in Remark tag if so, with comment data.
# For Carol.  2006 08 07
#
# Get rid of OBSOLETE in Remark.  If alt_id put under Remark, and for the
# alt_id entry only write the Dead tag.  2006 11 03
#
# Some changes for Carol regarding Dead and Remark  2006 11 08
#
# Added : for new WBPhenotype:\d+ format.  2008 06 23
#
# name: field in .obo no longer has underscores, now it has space.  2010 05 26
#
# use cvs from cgi from spica instead of local (tazendra) cvs  2010 06 23
#
# updated for pap_ vs old wpa_ and gop_ vs old got_ pgtables.  2011 05 18
#
# no longer dump obsolete terms, for Gary and Chris.  2015 10 07


use strict;
use diagnostics;
use LWP::Simple;
# use Pg;
use DBI;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

# my $conn = Pg::connectdb("dbname=testdb");
# die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my %all_evi;

my %paperid;
my %phenotypeTerms;
my $error_file = 'errorfile';
open (ERR, ">$error_file") or die "Cannot create $error_file : $!";
my $outfile = 'phenotype_from_obo.ace';
open (OUT, ">$outfile") or die "Cannot create $outfile : $!";


my %existing_evidence;                          # existing wbpersons and wbpapers and go_terms
&populateExistingEvidence();

&populateXref();
&readCvs;

sub populateXref {
  my $result = $dbh->prepare( "SELECT * FROM pap_identifier ;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { $paperid{$row[1]} = $row[0]; }
#   my $result = $dbh->prepare( "SELECT * FROM wpa_identifier ORDER BY wpa_timestamp;" );
#   $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
#   while (my @row = $result->fetchrow) {
#     next unless $row[1];
#     if ($row[0]) { 
#       $row[0] =~ s///g;
#       $row[1] =~ s///g;
#       if ($row[3] eq 'valid') { $paperid{$row[1]} = $row[0]; }
#         else { if ($paperid{$row[1]}) { delete $paperid{$row[1]}; } } } }
} # sub populateXref


sub readCvs {
  my $directory = '/home/acedb/carol/dump_phenotype_ace';
  chdir($directory) or die "Cannot go to $directory ($!)";

# use cvs from cgi from spica instead of local cvs  2010 06 23
#   `cvs -d /var/lib/cvsroot checkout PhenOnt`;
#   my $file = $directory . '/PhenOnt/PhenOnt.obo';
# #   my $file = $directory . '/PhenOnt.obo.3';
#   $/ = "";
#   open (IN, "<$file") or die "Cannot open $file : $!";
#   while (my $para = <IN>) { # }

#   my $obofile = get "http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/phenotype_ontology_obo.cgi";
#   my $obofile = get "http://purl.obolibrary.org/obo/wbphenotype/releases/2019-01-29/wbphenotype-merged.obo";	# updated url 2019 02 27
#   my $obofile = get "https://www.dropbox.com/s/1glm0lamc78clce/wbphenotype.obo?dl=0";	# updated url 2019 02 28
#  my $obofile = get "http://tazendra.caltech.edu/~azurebrd/var/work/chris/wbphenotype.obo";	# temp testing 2019 02 28
  my $obofile = get "https://github.com/obophenotype/c-elegans-phenotype-ontology/raw/vWS288/wbphenotype.obo";
  my (@entries) = split/\n\n/, $obofile;
  foreach my $para (@entries) {
    next unless ($para =~ m/id:/);
#     next if ($para =~ m/is_obsolete: true/);					# no longer skip obsoletes for Chris 2019 02 27

#     if ($para =~ m/id: WBPhenotype:(\d+).*?\bname: ([\w\- ]+)/s)
    if ($para =~ m/id: WBPhenotype:(\d+)/) {
      my $number = 'WBPhenotype:' . $1;
#  if ($number eq 'WBPhenotype:0001976') { print qq(NAME $name PARA $para); }
      my (@all_lines) = split/\n/, $para;
      foreach my $line (@all_lines) {
        if ($line =~ m/^name: ([\w\- ]*)/) { $phenotypeTerms{$number}{name} = $1; }
        if ($line =~ m/^def: "(.*?)" \[(.*?)\]/) {
          my $description = $1; my $evi_long = $2;
          if ($description =~ m/\\n/) { $description =~ s/\\n//g; }
          my $outline = "Description\t\"$description\"";
          if ($evi_long) { $phenotypeTerms{$number}{desc} = &attachEvi($outline, $evi_long); } 
            else { $phenotypeTerms{$number}{desc} = "$outline\n"; }
          $phenotypeTerms{$number}{evi} = $evi_long;
        }
        if ($line =~ m/^synonym:\s+\"([^"]+)\".*?\[(.*?)\]/) {
          my $syn = $1; my $evi_long = $2;
#             if ($number eq 'WBPhenotype0000038') { print "LIN $syn_line AT\n"; }
          next unless ($syn);
          my $outline = '';
          if ($line =~ m/three_letter_name/) {
              if ($evi_long) { $outline = &attachEvi("Short_name\t\"$syn\"", $evi_long); }
                else { $outline = "Short_name\t\"$syn\"\t$evi_long\n"; } }
            else {
              if ($evi_long) { $outline = &attachEvi("Synonym\t\"$syn\"", $evi_long); }
                else { $outline = "Synonym\t\"$syn\"\t$evi_long\n"; } }
#           if ($number eq 'WBPhenotype0000038') { print "AT $outline AT\n"; }
          $phenotypeTerms{$number}{syn} .= $outline;
        }
        if ($line =~ m/^replaced_by: (.*)/ ) { $phenotypeTerms{$number}{replaced_by} .= "Replaced_by\t\"$1\"\n"; }
        if ($line =~ m/^is_a: WBPhenotype:(\d{7})/) {
          my $num = "WBPhenotype:" . $1;
          $phenotypeTerms{$number}{specof} .= "Specialisation_of\t\"$num\"\n";
          $phenotypeTerms{$num}{genof} .= "Generalisation_of\t\"$number\"\n"; }
        if ($line =~ m/^part_of WBPhenotype:(\d{7})/) {
          my $num = "WBPhenotype:" . $1;
          $phenotypeTerms{$number}{specof} .= "Specialisation_of\t\"$num\"\n";
          $phenotypeTerms{$num}{genof} .= "Generalisation_of\t\"$number\"\n"; }
        if ($line =~ m/^alt_id: (WBPhenotype:\d+)/) {
          my $other_num = $1;
          $phenotypeTerms{$number}{remark} .= "Remark\t\"Alternate_ID: $other_num\"\n";
          $phenotypeTerms{$other_num}{dead} .= "Dead\tAlternate_phenotype\t\"$number\"\n"; }
        if ($line =~ m/^consider: (WBPhenotype:\d+)/ ) {
            my $other_num = $1;
            $phenotypeTerms{$number}{dead} .= "Dead\tAlternate_phenotype\t\"$other_num\"\n"; }
        if ($line =~ m/^is_obsolete: true/) { $phenotypeTerms{$number}{dead} .= "Dead\n"; }	# 2006 11 08
        if ($line =~ m/^comment: (.*?)$/) {
          my $comment = $1;
          if ($comment =~ m/\"/) { $comment =~ s/\"/\'/g; }
          if ($para =~ m/is_obsolete: true/) {
#               $phenotypeTerms{$number}{remark} .= "Remark\t\"OBSOLETE.  $comment\"\n";	# no longer say OBSOLETE for Carol 2006 11 03
#               $phenotypeTerms{$number}{remark} .= "Remark\t\"$comment\"\n"; 	# no longer dump remarks for obsolete for Chris  2019 02 27
            }
            else { 					# go to assay if not obsolete and no alt_id 2006 11 08
              unless ($para =~ m/alt_id: WBPhenotype:\d+/) { $phenotypeTerms{$number}{assay} .= "Assay\t\"$comment\"\n"; } } }
    } }
  }
#   close (IN) or die "Cannot close $file : $!";	# use cvs from cgi from spica
  $directory .= '/PhenOnt';
  `rm -rf $directory`; 
} # sub readCvs 

foreach my $num (sort keys %phenotypeTerms) {
  print OUT "\nPhenotype : \"$num\"\n";
  if ($phenotypeTerms{$num}{dead}) { 
      print OUT "$phenotypeTerms{$num}{dead}"; 
#       next if ($phenotypeTerms{$num}{dead} =~ m/Alternate_phenotype/); 	# stop if it's an alt for something else 2006 11 08	# no longer skip 2019 02 28
  }
  if ($phenotypeTerms{$num}{name}) { 	# no longer attach all evidence to Primary_name  for Carol / Anthony  2006 05 02
    print OUT "Primary_name\t\"$phenotypeTerms{$num}{name}\"\n"; } 
#       if ($phenotypeTerms{$num}{evi}) { 
#           my $line = &attachEvi("Primary_name\t\"$phenotypeTerms{$num}{name}\"", $phenotypeTerms{$num}{evi}); 
#           if ($line) { print OUT "$line"; }
#             else { print ERR "BAD EVIDENCE $phenotypeTerms{$num}{evi}\n"; } }
#         else { print OUT "Primary_name\t\"$phenotypeTerms{$num}{name}\"\n"; } }
#     else { print ERR "ERROR $num HAS NO NAME\n"; }
  if ($phenotypeTerms{$num}{desc}) { 
      print OUT "$phenotypeTerms{$num}{desc}"; }
  if ($phenotypeTerms{$num}{syn}) { 
      print OUT "$phenotypeTerms{$num}{syn}"; }
  if ($phenotypeTerms{$num}{specof}) { 
      print OUT "$phenotypeTerms{$num}{specof}"; }
  if ($phenotypeTerms{$num}{genof}) { 
      print OUT "$phenotypeTerms{$num}{genof}"; }
  if ($phenotypeTerms{$num}{assay}) { 
      print OUT "$phenotypeTerms{$num}{assay}"; }
  if ($phenotypeTerms{$num}{remark}) { 
      print OUT "$phenotypeTerms{$num}{remark}"; }
  if ($phenotypeTerms{$num}{replaced_by}) { 
      print OUT "$phenotypeTerms{$num}{replaced_by}"; }
} # foreach my $num (sort keys %phenotypeTerms)

# foreach my $evi (sort keys %all_evi) { print ERR "$evi\n"; }

close (ERR) or die "Cannot close $error_file : $!";
close (OUT) or die "Cannot close $outfile : $!";

sub attachEvi {
    # Also check papers and people and go terms to see if they are valid
  my ($line, $evi) = @_;
  my $lines = '';
  my @evi; my @tran_evi;
  if ($evi =~ m/, /) { @evi = split/, /, $evi; } else { push @evi, $evi; }
  foreach my $evi (@evi) { $all_evi{$evi}++; }
  foreach my $evi (@evi) {
    if ($evi =~ m/WB:WBPerson(\d+)/) { 	# check WBPerson but only skip if bad, print it out later if it matches after potential conversions below
      unless ($existing_evidence{person}{$1}) { print ERR "LINE $line HAS BAD WBPERSON WBPerson$1\n"; next; } }

    if ($evi =~ m/WB:WBPaper(\d+)/) { 
      if ($existing_evidence{paper}{$1}) { push @tran_evi, "Paper_evidence\t\"WBPaper$1\""; }
        else { print ERR "LINE $line HAS BAD WBPAPER WBPaper$1\n"; } }
    elsif ($evi =~ m/WB:WBperson557/) { push @tran_evi, "Curator_confirmed\t\"WBPerson557\""; }
    elsif ($evi =~ m/WB:WBPerson557/) { push @tran_evi, "Curator_confirmed\t\"WBPerson557\""; }
    elsif ($evi =~ m/WB:(WBPerson\d+)/) { push @tran_evi, "Person_evidence\t\"$1\""; }
    elsif ($evi =~ m/WB:WBperson(\d+)/) { push @tran_evi, "Person_evidence\t\"WBPerson$1\""; }
    elsif ($evi =~ m/WB:cab/) { push @tran_evi, "Curator_confirmed\t\"WBPerson48\""; }
    elsif ($evi =~ m/WB:kmva/) { push @tran_evi, "Curator_confirmed\t\"WBPerson1843\""; }
    elsif ($evi =~ m/WB:rk/) { push @tran_evi, "Curator_confirmed\t\"WBPerson324\""; }
    elsif ($evi =~ m/WB:IA/) { push @tran_evi, "Curator_confirmed\t\"WBPerson22\""; }
    elsif ($evi =~ m/WB:ia/) { push @tran_evi, "Curator_confirmed\t\"WBPerson22\""; }
    elsif ($evi =~ m/WB:(cgc\d+)/) { 
      if ($paperid{$1}) { push @tran_evi, "Paper_evidence\t\"WBPaper$paperid{$1}\""; } }
    elsif ($evi =~ m/cgc:(\d+)/) { my $cgc = 'cgc' . $1; 
      if ($paperid{$cgc}) { push @tran_evi, "Paper_evidence\t\"WBPaper$paperid{$cgc}\""; } }
    elsif ($evi =~ m/pmid:(\d+)/) { my $pmid = 'pmid' . $1; 
      if ($paperid{$pmid}) { push @tran_evi, "Paper_evidence\t\"WBPaper$paperid{$pmid}\""; } }
    elsif ($evi =~ m/(GO:\d+)/) { 
      if ($existing_evidence{goterm}{$1}) { push @tran_evi, "GO_term_evidence\t\"$1\""; }
        else { print ERR "LINE $line HAS BAD GOTERM $1\n"; } }
    elsif ($evi =~ m/XX:/) { 1; }		# ignore placeholder
    else { print ERR "NOT a convertible evidence $evi in line $line\n"; }
  }
  foreach my $evi (@tran_evi) { $lines .= "$line\t$evi\n"; }
  return $lines;
} # sub attachEvi


sub populateExistingEvidence {          # get hash of valid wbpersons and wbpapers and go_terms
  my $result = $dbh->prepare( "SELECT * FROM two ORDER BY two" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    $existing_evidence{person}{$row[1]}++; } 
  $result = $dbh->prepare( "SELECT * FROM pap_status WHERE pap_status = 'valid'" );  
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { $existing_evidence{paper}{$row[0]}++; }
#   $result = $dbh->prepare( "SELECT * FROM gop_goid" );
#   $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
#   while (my @row = $result->fetchrow) {
#     $existing_evidence{goterm}{$row[1]}++; } 
  $result = $dbh->prepare( "SELECT * FROM obo_name_goid" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    $existing_evidence{goterm}{$row[0]}++; } 
#   $result = $dbh->prepare( "SELECT * FROM wpa ORDER BY wpa_timestamp" );  
#   $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
#   while (my @row = $result->fetchrow) {
#     if ($row[3] eq 'valid') { $existing_evidence{paper}{$row[0]}++; }
#       else { delete $existing_evidence{paper}{$row[0]}; } }
#   $result = $dbh->prepare( "SELECT * FROM got_goterm" );
#   $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
#   while (my @row = $result->fetchrow) {
#     $existing_evidence{goterm}{$row[0]}++; } 
} # sub populateExistingEvidence



__END__

format-version: 1.2
date: 02:11:2006 10:39
saved-by: carolbas
auto-generated-by: OBO-Edit 1.002
subsetdef: phenotype_slim_wb "WB phenotype slim"
synonymtypedef: three_letter_name "Short_name" BROAD
default-namespace: C_elegans_phenotype_ontology

[Term]
id: WBPhenotype0000000
name: chromosome_instability
is_a: WBPhenotype0000585 ! cell_homeostasis_metabolism_abnormal

