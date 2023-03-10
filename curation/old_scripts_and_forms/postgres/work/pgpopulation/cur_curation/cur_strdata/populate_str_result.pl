#!/usr/bin/perl -w

# populate string match results based on textpresso data, into cur_strdata
# http://wiki.wormbase.org/index.php/New_2012_Curation_Status#Datatypes_for_Textpresso_String_Searches
# 
# http://textpresso-dev.caltech.edu/sequence_feature/fullcorpus_result
# http://textpresso-dev.caltech.edu/disease/all_papers_nonReview
# http://textpresso-dev.caltech.edu/azurebrd/wen/anti_protein_wen
#
# runs in less than a second.  still needs cronjob.  2014 11 04
#
# Ranjana getting human disease from NNC, no longer wants STR processing.  2021 01 26
# COPY cur_strdata TO '/home/postgres/work/pgpopulation/cur_curation/cur_strdata/cur_strdata.pg.20210126';
#
# Valerio said to remove getting antibody data  &processAntibody();  2021 06 08  
#
#
# every day at 4am.  2014 11 06
# 0 4 * * * /home/postgres/work/pgpopulation/cur_curation/cur_strdata/populate_str_result.pl



use strict;
use CGI;
use DBI;
use Jex;			# mailer
use LWP::Simple;

my $starttime = time;

my $query = new CGI;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n";
my $result;
my @pgcommands;
push @pgcommands, qq(DELETE FROM cur_strdata WHERE cur_datatype = 'seqfeature';);


my @datatypes = qw( antibody seqfeature humandisease );
my %datatypes; foreach (@datatypes) { $datatypes{$_}++; }

&processSeqfeature();
# &processHumandisease();		# 2021 01 26  Ranjana using NNC, does not want this
# &processAntibody();			# 2021 06 08  Valerio said to remove this

sub processAntibody {
  my %papers;
  my $url = 'http://textpresso-dev.caltech.edu/azurebrd/wen/anti_protein_wen';
  my $page = get $url;
  my (@lines) = split/\n/, $page;
  foreach my $line (@lines) {
    my ($where, $values) = split/\t/, $line;
    my ($paper) = $where =~ m/WBPaper(\d+)/;
    my (@values) = split/, /, $values;					# aggregate comma-separated values
    foreach my $value (@values) { $papers{$paper}{$value}++; }
  } # foreach my $line (@lines)
  my @groupvalues;
  foreach my $paper (sort keys %papers) {
    my $values = join", ", sort keys %{ $papers{$paper} };
    push @groupvalues, qq(('$paper', 'antibody', NULL, '$values', NULL)); 
  } # foreach my $paper (sort keys %papers)
  my $groupvalues = join", ", @groupvalues;
  push @pgcommands, qq(INSERT INTO cur_strdata VALUES $groupvalues;); 
} # sub processAntibody

sub processSeqfeature {
  my %papers;
  my $url = 'http://textpresso-dev.caltech.edu/sequence_feature/fullcorpus_result';
  my $page = get $url;
  my (@lines) = split/\n/, $page;
  foreach my $line (@lines) {
    my ($where, $score) = split/ /, $line;
    next unless ($score >= 25);						# only keep is score >= 25
    my ($paper) = $where =~ m/WBPaper(\d+)/;
    unless ($papers{$paper}) { $papers{$paper} = $score; }
  } # foreach my $line (@lines)
  my @groupvalues;
  foreach my $paper (sort keys %papers) {
    push @groupvalues, qq(('$paper', 'seqfeature', NULL, '$papers{$paper}', NULL)); 
  } # foreach my $paper (sort keys %papers)
  my $groupvalues = join", ", @groupvalues;
  push @pgcommands, qq(INSERT INTO cur_strdata VALUES $groupvalues;); 
} # sub processSeqfeature

sub processHumandisease {
  my %papers;
  my $url = 'http://textpresso-dev.caltech.edu/disease/all_papers_nonReview';
  my $page = get $url;
  my (@lines) = split/\n/, $page;
  foreach my $line (@lines) { my ($paper) = $line =~ m/WBPaper(\d+)/; $papers{$paper} = 'string'; }
  my @groupvalues;
  foreach my $paper (sort keys %papers) { 
    push @groupvalues, qq(('$paper', 'humandisease', NULL, '$papers{$paper}', NULL));  
  }
  my $groupvalues = join", ", @groupvalues;
  push @pgcommands, qq(INSERT INTO cur_strdata VALUES $groupvalues;); 
} # sub processHumandisease

foreach my $pgcommand (@pgcommands) {
#   print qq($pgcommand\n);
  $dbh->do($pgcommand);
} # foreach my $pgcommand (@pgcommands)

