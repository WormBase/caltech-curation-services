#!/usr/bin/perl -w

# seems out of use
# -rwxr-xr-x  1 postgres postgres  19573 Mar 24  2005 check_go_ace.pl*
# loci_all.txt no longer updated, probably not working as it should.  2006 12 15



# Check some stuff for Ranjana
# check that wbgene has 8 digits and exists in current sanger file.
# check that goid is ``GO:7digits''
# check evidence in list of IMP, etc.
# check paper is ``WBPaper8digits''     2005 02 09


use strict;
use diagnostics;
use Pg;
use Jex; 	# mailer
use LWP;
 
my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my @choices = ('IDA','IEA','IEP','IGI','IMP','IPI','ISS','NAS','ND','IC','TAS', 'RCA');
my %choices;
foreach (@choices) { $choices{$_}++; }

my %existingWBGene;
my $url_locus = "http://www.sanger.ac.uk/Projects/C_elegans/LOCI/loci_all.txt";
&readCurrentLocus($url_locus);

$/ = '';
# my $infile = 'go_dump.ace.latest';
my $infile = 'go_dump_latest.ace';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $entry = <IN>) {
  if ($entry =~ m/WBGene/) {
    unless ($entry =~ m/WBGene\d{8}/) { print "ERROR WBGene has wrong number of digits $entry\n"; } }
  my @lines = split/\n/, $entry;
  foreach my $line (@lines) {
    if ($line =~ m/WBGene/) {
      my ($wbgene) = $line =~ m/(WBGene\d{8})/;
      unless ($existingWBGene{$wbgene}) { print "ERROR WBGene $wbgene not in Sanger file $entry\n"; } }
    elsif ($line =~ m/GO_Term/) {
      $line =~ s/\"//g;
      my ($a, $goterm, $inference, $ev_type, $ev_value) = split/\t/, $line;
      unless ($goterm =~ m/GO:\d{7}/) { print "ERROR GO_term $goterm has wrong number of digits $entry\n"; }
      unless ($choices{$inference}) { print "ERROR Inference $inference not valid in $entry\n"; }
      if ($ev_type =~ m/Paper/) {
        unless ($ev_value =~ m/WBPaper\d{8}/) { print "ERROR Paper $ev_value has wrong number of digits $entry\n"; } }
    }
  } # foreach my $line (@lines)
} # while (my $entry = <IN>)
close (IN) or die "Cannot close $infile : $!";


sub readCurrentLocus{
    my $u = shift;
    
    my $ua = LWP::UserAgent->new(timeout => 30); #instantiates a new user agent
    my $request = HTTP::Request->new(GET => $u); #grabs url
    my $response = $ua->request($request);       #checks url, dies if not valid.
    die "Error while getting ", $response->request->uri," -- ", $response->status_line, "\nAborting" unless $response-> is_success;
    
    my @tmp = split /\n/, $response->content;    #splits by line
    foreach (@tmp) {
        my ($three, $wb) = $_ =~ m/^(.*?),(.*?),/;	# added to convert genes
        $existingWBGene{$wb}++;
    }
}

__END__

my %theHash;

my %cgcHash;            # hash of cgcs, values pmids
my %pmHash;             # hash of pmids, values cgcs

my %convertToWBPaper;   # key cgc or pmid or whatever, value WBPaper

# my @PGparameters = qw(curator locus sequence synonym protein wbgene);	# array of names of pg values for html, pg, and theHash
# my @column_types = qw( goterm goid paper_evidence person_evidence goinference dbtype with qualifier goinference_two dbtype_two with_two qualifier_two comment );

my @PGparameters = qw(locus wbgene);	# array of names of pg values for html, pg, and theHash
my @ontology = qw( bio cell mol );
my @column_types = qw( goid paper_evidence person_evidence goinference goinference_two );

my $max_columns = 3;	# query each of the groups for highest to set how many columns to loop through
foreach my $ontology (@ontology) {
  my $result = $conn->exec ( "SELECT * FROM got_${ontology}_goid ORDER BY got_order DESC;");
  my @row = $result->fetchrow;
  if ($row[1] > $max_columns) { $max_columns = $row[1]; }
}



&populateXref(); 
&readConvertions();


my $directory = '/home/postgres/work/citace_upload/go_curation/old';
my $date = &getSimpleSecDate();
# $date = '20041022';
print "DATE $date\n";

my $outfile = $directory . '/go_dump.ace.' . $date;
open (OUT, ">$outfile") or die "Cannot create $outfile : $!";


my %loci;
my $result = $conn->exec ( "SELECT * FROM got_curator WHERE got_curator !~ 'Juancarlos' AND joinkey !~ '^[0-9]' AND joinkey != 'abcd';" );
# my $result = $conn->exec ( "SELECT * FROM got_curator WHERE got_curator !~ 'Juancarlos' AND joinkey !~ '^[0-9]' AND joinkey != 'abcd' AND joinkey = 'daf-28';" );
while ( my @row = $result->fetchrow ) { $loci{$row[0]}++; }

foreach my $locus (sort keys %loci) {
# print "LOCUS $locus\n";
  my $oldAce = &createOldAce($locus);
  if ($oldAce =~ m/GO_term/) { print OUT "${oldAce}"; }	# if makeAce has an error, it returns 1
  else { print STDERR "NO Terms for $oldAce\n"; }
} # foreach my $locus (sort keys %loci)


close (OUT) or die "Cannot close $outfile : $!";
my $location_of_latest = '/home/postgres/work/citace_upload/go_curation/go_dump.ace.latest';
unlink ("$location_of_latest") or die "Cannot unlink : $!";
# unlink symlink to latest
symlink("$outfile", "$location_of_latest") or warn "cannot symlink : $!";
# link newest dump to latest



sub createOldAce {
  my $joinkey = shift;
  foreach my $type (@PGparameters) {			# temporarily populate the hash with old values
    my $result = $conn->exec( "SELECT * FROM got_$type WHERE joinkey = '$joinkey' ORDER BY got_timestamp DESC;" );
    my @row = $result->fetchrow;
#       my $val = &filterToPrintHtml("$row[1]");	# turn value to Html
    my $val = $row[1];
# if ($type eq 'sequence') { print "$joinkey TRUSEQ $val\n"; }
    $theHash{$joinkey}{$type}{value} = $val;	# put value in %theHash
  } # foreach my $type (@PGparameters)
  my @allparameters; 
  foreach my $ontology (@ontology) {			# loop through each of three ontology types
    foreach my $column_type (@column_types) {
        my $field = $ontology . '_' . $column_type;
        push @allparameters, $field } }
  foreach my $type (@allparameters) {			# temporarily populate the hash with old values
    my $result = $conn->exec( "SELECT * FROM got_$type WHERE joinkey = '$joinkey' ORDER BY got_timestamp DESC;" );
    while (my @row = $result->fetchrow) { 
#       my $val = &filterToPrintHtml("$row[2]");	# turn value to Html
      my $val = $row[2];
      my $temp_type = $type . $row[1];
      $theHash{$joinkey}{$temp_type}{value} = $val;	# put value in %theHash
      if ($row[1] == 1) { last; }		# stop if get to first column, don't want to get all data, just latest
    } # while (my @row = $result->fetchrow) 
  } # foreach my $type (@PGparameters)
  my $oldAce = &makeAce($joinkey);				# create ace entry with old values
  return $oldAce;
} # sub createOldAce

sub makeAce {
  my $joinkey = shift;
    my $ace_entry = '';                                 # initialize entry
    for my $ontology (@ontology) {                      # for each of the three ontologies
      for my $i (1 .. $max_columns) {                              # for each of the three possible entries
        my $goid_tag = $ontology . '_goid' . $i;
        if ($theHash{$joinkey}{$goid_tag}{value}) {
        if ($theHash{$joinkey}{$goid_tag}{value} ne 'NULL') {
          my $goid = $theHash{$joinkey}{$goid_tag}{value};
          $goid =~ s/^\s+//g; $goid =~ s/\s+$//g;

          my $inference = '';
          my %inferences;
          my @evidence_tags = qw( _goinference _goinference_two );      # the inference types
          foreach my $ev_tag (@evidence_tags) {                 # for each of the inference types
            my $evidence_tag = $ontology . $ev_tag . $i;        # get evidence tag
            if ($theHash{$joinkey}{$evidence_tag}{value}) {
            if ( ($theHash{$joinkey}{$evidence_tag}{value} ne 'NULL')  && ($theHash{$joinkey}{$evidence_tag}{value} ne '') ) {
              my $inference = $theHash{$joinkey}{$evidence_tag}{value};   # the inference type
              $inference =~ s/ --.*$//g;
              $inferences{$inference}++;
            }
            }
          } # foreach my $ev_tag (@evidence_tags) 

          my %papers = ();
          my $tag = $ontology . '_paper_evidence' . $i;
          my $db_reference = '';				# paper id number
          if ($theHash{$joinkey}{$tag}{value}) {
          if ( ($theHash{$joinkey}{$tag}{value} ne 'NULL') && ($theHash{$joinkey}{$tag}{value} ne '') ) {
            my @papers = ();
            $theHash{$joinkey}{$tag}{value} =~ s/\s+//g;	# get rid of spaces
            if ($theHash{$joinkey}{$tag}{value} =~ m/,/) {	# split papers
              @papers = split /,/, $theHash{$joinkey}{$tag}{value}; }
            else { push @papers, $theHash{$joinkey}{$tag}{value}; }	# get single paper
            foreach my $paper (@papers) {			# print separate papers
              $db_reference = $paper;
              my ($number) = $db_reference =~ m/(\d+)/;
              if ($number > 10000) {
                my $key = 'pmid' . $number;
	        if ($pmHash{$key}) { $db_reference = $pmHash{$key}; }	# if there's a cgc, write cgc else leave the same
              }
	      $db_reference =~ s/\[//g;		# take out brackets so that they are not entered twice
	      $db_reference =~ s/\]//g;		# take out brackets so that they are not entered twice
              if ($db_reference =~ m/\s+/) { $db_reference =~ s/\s+//g; }
              if ($db_reference =~ m/\[/) { $db_reference =~ s/\[//g; }
              if ($db_reference =~ m/\]/) { $db_reference =~ s/\]//g; }
              if ($db_reference =~ m/:/) { $db_reference =~ s/://g; }
              if ($db_reference =~ m/PMID/) { $db_reference =~ s/PMID/pmid/g; }
              if ($db_reference =~ m/WBPaper/) { $papers{$db_reference}++; }
              elsif ($convertToWBPaper{$db_reference}) { $papers{$db_reference}++; }
              else { print STDERR "NO Convertion $joinkey for $db_reference\n"; }
            } # foreach my $paper (@papers)
          } # if ( ($theHash{$joinkey}{$tag}{value} ne 'NULL') && ($theHash{$joinkey}{$tag}{value} ne '') )
          } # if ($theHash{$joinkey}{$tag}{value})
# $ace_entry .= "GO_term\t\"$goid\"\t\"$inference\"\tPaper_evidence\t\"$db_reference\"\n";
    
          my %persons;
          $tag = $ontology . '_person_evidence' . $i;
          if ($theHash{$joinkey}{$tag}{value}) {
          if ( ($theHash{$joinkey}{$tag}{value} ne 'NULL') && ($theHash{$joinkey}{$tag}{value} ne '') ) {
            if ($theHash{$joinkey}{$tag}{value} =~ m/ishore/) {
#               $ace_entry .= "GO_term\t\"$goid\"\t\"$inference\"\tPerson_evidence\t\"WBPerson324\"\n";
              $persons{WBPerson324}++; 
            } elsif ($theHash{$joinkey}{$tag}{value} =~ m/chwarz/) {
              $persons{WBPerson567}++; 
#               $ace_entry .= "GO_term\t\"$goid\"\t\"$inference\"\tPerson_evidence\t\"WBPerson567\"\n";
            } else {
              $persons{$theHash{$joinkey}{$tag}{value}}++; 
            }
          } # if ($theHash{$joinkey}{$tag}{value})
          } # if ($theHash{$joinkey}{$tag}{value})

          foreach my $inference (sort keys %inferences) {
            foreach my $paper (sort keys %papers) {
              $ace_entry .= "GO_term\t\"$goid\"\t\"$inference\"\tPaper_evidence\t\"$paper\"\n";
            } # foreach my $paper (sort keys %papers)
            foreach my $person (sort keys %persons) {
              $ace_entry .= "GO_term\t\"$goid\"\t\"$inference\"\tPerson_evidence\t\"$person\"\n";
            } # foreach my $person (sort keys %persons)
          } # foreach my $inference (sort keys %inferences)
    
        } # if ($theHash{$joinkey}{$goid_tag}{value} ne 'NULL')
        } # if ($theHash{$joinkey}{$goid_tag}{value})
      } # for my $i (1 .. $max_columns)
    } # for my $ontology (@ontology)
    $ace_entry .= "\n";                                 # add separator

    if ($theHash{$joinkey}{wbgene}{value} =~ m/WBGene\d{8}/) {		# if wbgene entry, use the WBGene
      $ace_entry = "Gene : \"$theHash{$joinkey}{wbgene}{value}\"\n$ace_entry"; }
    else { print "ERROR $joinkey BAD WBGENE $theHash{$joinkey}{wbgene}{value}\n"; }
    return $ace_entry;
} # sub makeAce

sub populateXref {              # if not found, get ref_xref data to try to find alternate
  my $result = $conn->exec( "SELECT * FROM ref_xref;" );
  while (my @row = $result->fetchrow) { # loop through all rows returned
    $cgcHash{$row[0]} = $row[1];        # hash of cgcs, values pmids
    $pmHash{$row[1]} = $row[0];         # hash of pmids, values cgcs
  } # while (my @row = $result->fetchrow)
} # sub populateXref

sub readConvertions {
  my $u = "http://tazendra.caltech.edu/~acedb/paper2wbpaper.txt";
  my $ua = LWP::UserAgent->new(timeout => 30); #instantiates a new user agent
  my $request = HTTP::Request->new(GET => $u); #grabs url
  my $response = $ua->request($request);       #checks url, dies if not valid.
  die "Error while getting ", $response->request->uri," -- ", $response->status_line, "\nAborting" unless $response-> is_success;
  my @tmp = split /\n/, $response->content;    #splits by line
  foreach (@tmp) {
    if ($_ =~m/^(.*?)\t(.*?)$/) {
      $convertToWBPaper{$1} = $2; } }
} # sub readConvertions


__END__

### CODE FOR DIFFERENT SCRIPT ###
#
# use HTTP::Request;
# use LWP::UserAgent;
# 
# use strict;
# use diagnostics;
# use Pg;
# use Jex; 	# mailer
# 
# my %hash;	# key paper, value lines of Locus and Sequence
# 
# my %convertToWBPaper;	# key cgc or pmid or whatever, value WBPaper
# 
# 
# # url of current cgc approved gene names
# my $url_locus = "http://www.sanger.ac.uk/Projects/C_elegans/LOCI/loci_all.txt";
# 
# my %valid_locus;				# valid locus from sanger
# my %excluded_locus;				# invalid locus excluded from emailing sanger
# 
#   # List of excluded locus not to email sanger
# $excluded_locus{'mir-68'}++;
# $excluded_locus{'mir-69'}++;
# $excluded_locus{'mir-89'}++;
# 
# my %conversionHash;
# &readCurrentLocus($url_locus);
# &readConvertions();
# 
# sub readCurrentLocus{
# 
#     my $u = shift;
#     
#     my $ua = LWP::UserAgent->new(timeout => 30); #instantiates a new user agent
#     my $request = HTTP::Request->new(GET => $u); #grabs url
#     my $response = $ua->request($request);       #checks url, dies if not valid.
#     die "Error while getting ", $response->request->uri," -- ", $response->status_line, "\nAborting" unless $response-> is_success;
#     
#     my @tmp = split /\n/, $response->content;    #splits by line
#     foreach (@tmp){
#         my ($three, $wb) = $_ =~ m/^(.*?),(.*?),/;	# added to convert genes
#         $conversionHash{$three} = $wb;			# from 3-letter to WBGene type
#         if ($_ =~ m/,([^,]*?) ,CGC approved$/) { 	# 2004 05 05
#           my @things = split/ /, $1;
#           foreach my $thing (@things) {
#             if ($thing =~ m/[a-zA-Z][a-zA-Z][a-zA-Z]\-\d+/) { $conversionHash{$thing} = $wb; } } }
# 
# 	$_ =~ s/CGC approved//g;                 #gets rid of CGC approved
# 	$_ =~ s/\,/ /g;                          #replaces commas with spaces
# 	my @Genes = split /\s+/, $_;                # splits on one or more space
# 	for (@Genes){ next if (length($_) <= 2); $valid_locus{$_}++ }  # gets rid of dubious genes
#     }
# }
# 
# sub readConvertions {
#   my $u = "http://minerva.caltech.edu/~acedb/paper2wbpaper.txt";
#   my $ua = LWP::UserAgent->new(timeout => 30); #instantiates a new user agent
#   my $request = HTTP::Request->new(GET => $u); #grabs url
#   my $response = $ua->request($request);       #checks url, dies if not valid.
#   die "Error while getting ", $response->request->uri," -- ", $response->status_line, "\nAborting" unless $response-> is_success;
#   my @tmp = split /\n/, $response->content;    #splits by line
#   foreach (@tmp) {
#     if ($_ =~m/^(.*?)\t(.*?)$/) {
#       $convertToWBPaper{$1} = $2; } }
# } # sub readConvertions
# 
# 
# # foreach my $locus (sort keys %valid_locus) {
# #   print "$locus\t$valid_locus{$locus}\n";
# # } # foreach my $locus (sort keys %valid_locus)
# 
# 
# my $conn = Pg::connectdb("dbname=testdb");
# die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;
# 
# my $bad_stuff = "\/\/ Paper\tLocus\tPerson_evidence\tCurator_confirmed\n";
# 
# my $result = $conn->exec ( "SELECT * FROM kim_paperlocus WHERE kim_person != 'WBPerson1823';" );
# while ( my @row = $result->fetchrow ) {
#   my ($paper, $data, $timestamp, $person, $curator) = @row;
# #   print "Paper\t\[$paper\]\n";
#   my @loci = split/\n/, $data;
#   foreach my $locus (@loci) {
#     $locus =~ s/^\s+//g; $locus =~ s/\s+$//g;
#     unless ($conversionHash{$locus}) { print STDERR "No WBGene Match for $locus\n"; next; }
# 	# skip things without WBGene match	# 2004 05 05
#     unless ($valid_locus{$locus}) { 			# email invalid locus
#       unless ($excluded_locus{$locus}) { 		# but not excluded locus
#         $bad_stuff .= "\/\/ $paper\t$locus\t$person\t$curator\n"; 
# #         $bad_stuff .= "Locus : \"$locus\"\n";
#         $bad_stuff .= "Gene : \"$conversionHash{$locus}\"\n";
#         $bad_stuff .= "Non_CGC_name\t\"$locus\"\n";
#         $bad_stuff .= "Evidence\t\"$person\"\n";
#         $bad_stuff .= "Species\t\"Caenorhabditis elegans\"\nGene\n\n"; } }
#     else { 
# #       $hash{$paper} .= "Locus\t\"$locus\"\tPerson_evidence\t\"$person\"\n";
#       $hash{$paper} .= "Gene\t\"$conversionHash{$locus}\"\tPerson_evidence\t\"$person\"\n";
# #       print "Locus\t\"$locus\"\tPerson_evidence\t\"$person\"\n";
#       if ($person ne $curator) { 
# #         print "Locus\t\"$locus\"\tCurator_confirmed\t\"$curator\"\n";  
# #         $hash{$paper} .= "Locus\t\"$locus\"\tCurator_confirmed\t\"$curator\"\n";
#         $hash{$paper} .= "Gene\t\"$conversionHash{$locus}\"\tCurator_confirmed\t\"$curator\"\n"; 
#     } }
#   } # foreach my $locus (@loci)
# #   print "\n";
# #   print "DAT $data\n";
# #   print "TIM $timestamp\n";
# #   print "PER $person\n";
# #   print "CUR $curator\n";
# } # while ( my @row = $result->fetchrow )
# 
# $result = $conn->exec ( "SELECT * FROM kim_papersequence WHERE kim_person != 'WBPerson1823' AND kim_papersequence != '';" );
# while ( my @row = $result->fetchrow ) {
#   my ($paper, $data, $timestamp, $person, $curator) = @row;
# #   print "Paper\t\[$paper\]\n";
#   my @sequences = split/\n/, $data;
#   foreach my $sequence (@sequences) {
#     $sequence =~ s/^\s+//g; $sequence =~ s/\s+$//g;
# #     print "Sequence\t\"$sequence\"\tPerson_evidence\t\"$person\"\n";
# #     $hash{$paper} .= "Sequence\t\"$sequence\"\tPerson_evidence\t\"$person\"\n";
#     $hash{$paper} .= "CDS\t\"$sequence\"\tPerson_evidence\t\"$person\"\n";
#     if ($person ne $curator) { 
# #       print "Sequence\t\"$sequence\"\tCurator_confirmed\t\"$curator\"\n"; 
# #       $hash{$paper} .= "Sequence\t\"$sequence\"\tCurator_confirmed\t\"$curator\"\n"; }
#       $hash{$paper} .= "CDS\t\"$sequence\"\tCurator_confirmed\t\"$curator\"\n"; }
#   } # foreach my $sequence (@sequences)
# #   print "\n";
# #   print "DAT $data\n";
# #   print "TIM $timestamp\n";
# #   print "PER $person\n";
# #   print "CUR $curator\n";
# } # while ( my @row = $result->fetchrow )
# 
# foreach my $paper (sort keys %hash) {
#   $paper =~ s/\.$//g;                               # take out dots at the end that are typos
#   if ($paper =~ m/WBPaper/) { 
#     print "Paper\t$paper\n";
#     print "$hash{$paper}\n"; }
#   elsif ($convertToWBPaper{$paper}) {                  # conver to WBPaper or print ERROR
#     print "Paper\t$convertToWBPaper{$paper}\n";
#     print "$hash{$paper}\n";
#   } else { print STDERR "ERROR No conversion for $paper on $hash{$paper}\n"; }
# } # foreach my $paper (sort keys %hash)
# 
# print "BAD\n$bad_stuff\n";
# 
# my $user = 'Paper_Locus_Curator';
# # my $email = 'cgc@wormbase.org';
# my $email = 'azurebrd@minerva.caltech.edu';
# my $subject = 'Missing Loci in Paper->Locus connection';
# if ($bad_stuff ne "\/\/ Paper\tLocus\tPerson_evidence\tCurator_confirmed\n") {
#   &mailer($user, $email, $subject, $bad_stuff); }



