#!/usr/bin/env perl

# Populate obo_{name|syn|data}_<datatype>_<field> tables in postgres based off
# webpages where the obos are stored.  For ontology_annotator.cgi 
# needs a cronjob (probably every day).  2009 10 04
#
# Populate obo_data_app_term  with pre-populated parent/child relationships.  2009 10 13
#
# Added alt_id to app & anat_term to obo_data_app_anat_term and obo_name_app_anat_term 
# so that terms that existed before can be queried for replacing.  2010 04 21
#
# No longer update app_tempname (variations + transgene + rearrangement) from ws_current.obo
# instead use 
# http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/generic.cgi?action=UpdateVariationObo
# which will look at 4 files in /home/acedb/jolene/WS_AQL_queries/ and nameserver data.
# 2010 06 10
#
# update app term data from sanger, which takes some 30 mins by calling 
# /home/acedb/jolene/WS_AQL_queries/update_variation_obo.pl
# 2010 07 22
#
# do full update of variation obo data only on 1st of month (it takes 55 minutes)
# do incremental update other days (takes 30 secs to download file and a few seconds to
# add a small number of new entries)  2010 08 23
#
#
# Added to cron every day at 3am  2010 01 22
# 0 3 * * * /home/postgres/work/pgpopulation/obo_oa_ontologies/update_obo_oa_ontologies.pl

# updated to use obo_<tabletype>_<obotable> instead of obo_<tabletype>_<threetype>_<field>
# updated to have full processing of obo data for term info here, instead of on the fly in
# the cgi.  2011 02 22

# updated tazendra with this script, when live replace update_obo_oa_ontologies.pl with this.
# 2011 02 23
#
# LWP can't get https from github, so need SSL package. 
#
# is_obsolete: true  now made bold for Xiaodong.  2012 06 13
#
# added human disease ontology for Ranjana.  2013 01 12
# 
# No longer using updateVariationObo nor addToVariationObo, now using nightly_geneace.pl  
# get the nightly data from geneace.  2013 10 24
#
# added topicrelations obo_ tables for Karen.  She'll edit the .obo file, so it's on 
# tazendra.  2014 05 01
#
# added soid for soterm in sqf sequence features.  2014 09 25
#
# added  /home/postgres/work/pgpopulation/sqf_sequencefeature/populate_from_geneace/parse_seqfeat.pl
# to parse sequence features into OA sqf_ tables.  
# changed  nightly_geneace.pl  to no longer populate data from  features.ace.gz 
# for Daniela  2014 10 01
#
# Processing goid data 3 more times separately to get  process  function  component  into separate 
# tables.  For Chris.  2015 08 25
#
# skip obsolete phenotype terms for Chris and Gary.  2015 10 07
#
# goid no longer has a date field, uses data-version.  2017 10 31
#
# changed humando .obo url for Ranjana.  2018 08 29
#
# changed phenotype URL for Chris.  2018 11 15
#
# phenotype also uses data-version, but has extra stuff.  2019 08 18
#
# phenotype now also allows is_obsolete: true  terms.  2019 08 22
#
# raymond has new anatomy url.  2019 08 26
#
# added eco ontology for ranjana.  2020 10 28
#
# updated urls for anatomy, quality, 4x go, removed entity.  2021 05 20
#
# dockerized and cronjob.  Still needs nightly_geneace.pl populate_gin_nightly.pl
# parse_seqfeat.pl  2023 03 19

# 0 20 * * * /usr/lib/scripts/pgpopulation/obo_oa_ontologies/update_obo_oa_ontologies.pl


use strict;
use diagnostics;
use DBI;
use LWP::Simple;
use LWP;
use LWP::Protocol::https;			# for LWP to get https
# use Crypt::SSLeay;				# for LWP to get https - not in dockerized

use Dotenv -load => '/usr/lib/.env';

my $dbh = DBI->connect ( "dbi:Pg:dbname=$ENV{PSQL_DATABASE};host=$ENV{PSQL_HOST};port=$ENV{PSQL_PORT}", "$ENV{PSQL_USERNAME}", "$ENV{PSQL_PASSWORD}") or die "Cannot connect to database!\n";
# my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my $directory =  $ENV{CALTECH_CURATION_FILES_INTERNAL_PATH} . '/cronjobs/obo_oa_ontologies/';
# my $directory = '/home/postgres/work/pgpopulation/obo_oa_ontologies/';
chdir ($directory) or die "Cannot chdir to $directory : $!";


my %obos;
# $obos{anatomy} = 'http://brebiou.cshl.edu/viewcvs/*checkout*/Wao/WBbt.obo';	# daniela wants it from cshl until the site goes down from lack of maintenance  2011 02 10
# $obos{anatomy} = 'https://github.com/raymond91125/Wao/raw/master/WBbt.obo';    # daniela wants it from raymond's new cvs location  2011 04 12
# $obos{anatomy} = 'https://github.com/obophenotype/c-elegans-gross-anatomy-ontology/raw/master/wbbt.obo';    # raymond points at new location  2019 08 26
$obos{anatomy} = 'https://raw.githubusercontent.com/obophenotype/c-elegans-gross-anatomy-ontology/master/wbbt.obo';    # raymond points at new location  2021 05 19
# $obos{entity} = 'http://www.berkeleybop.org/ontologies/obo-all/rex/rex.obo';	# not used by any oa datatype anymore  2021 05 20
# $obos{lifestage} = 'http://www.berkeleybop.org/ontologies/obo-all/worm_development/worm_development.obo';
# $obos{lifestage} = 'https://raw.github.com/draciti/Life-stage-obo/master/worm_development.obo';	# daniela wants it from github 2012 05 02
$obos{lifestage} = 'https://raw.githubusercontent.com/obophenotype/c-elegans-development-ontology/master/wbls.obo'; # chris wants it from here  2020 08 10
# $obos{quality} = 'http://www.berkeleybop.org/ontologies/obo-all/quality/quality.obo';
$obos{quality} = 'https://raw.githubusercontent.com/pato-ontology/pato/master/pato.obo';		# chris new url 2021 05 20 redirect from http://purl.obolibrary.org/obo/pato.obo
$obos{phenotype} = 'https://raw.githubusercontent.com/obophenotype/c-elegans-phenotype-ontology/master/wbphenotype.obo';	# new file for Chris  2019 05 14
# $obos{phenotype} = 'https://raw.githubusercontent.com/obophenotype/c-elegans-phenotype-ontology/master/wbphenotype-merged.obo';	# gets from github for Chris  2019 03 12
# $obos{phenotype} = 'https://raw.githubusercontent.com/obophenotype/c-elegans-phenotype-ontology/master/src/ontology/wbphenotype-merged.obo';	# gets from github for Chris  2018 11 15
# $obos{phenotype} = 'http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/phenotype_ontology_obo.cgi';	# gets from cvs from spica	# removed for Chris 2018 11 15
# owl https://raw.githubusercontent.com/obophenotype/c-elegans-phenotype-ontology/master/wbphenotype.owl
# $obos{goid} = 'http://www.geneontology.org/ontology/obo_format_1_2/gene_ontology_ext.obo';	# replaced 2010 10 28
# $obos{goidfunction} = 'http://www.geneontology.org/ontology/obo_format_1_2/gene_ontology_ext.obo';	# copied 2015 08 25
# $obos{goidcomponent} = 'http://www.geneontology.org/ontology/obo_format_1_2/gene_ontology_ext.obo';	# copied 2015 08 25
# $obos{goidprocess} = 'http://www.geneontology.org/ontology/obo_format_1_2/gene_ontology_ext.obo';	# copied 2015 08 25
$obos{goid} = 'http://snapshot.geneontology.org/ontology/go.obo';					# kimberly 2021 05 20
$obos{goidfunction}  = 'http://snapshot.geneontology.org/ontology/go.obo';	# copied 2015 08 25	# kimberly 2021 05 20
$obos{goidcomponent} = 'http://snapshot.geneontology.org/ontology/go.obo';	# copied 2015 08 25	# kimberly 2021 05 20
$obos{goidprocess}   = 'http://snapshot.geneontology.org/ontology/go.obo';	# copied 2015 08 25	# kimberly 2021 05 20
# $obos{soid} = 'http://sourceforge.net/p/song/svn/HEAD/tree/trunk/so-xp-simple.obo?format=raw';
$obos{soid} = 'https://raw.githubusercontent.com/The-Sequence-Ontology/SO-Ontologies/master/Ontology_Files/so.obo';	# raymond new url 2021 05 19 redirected from http://purl.obolibrary.org/obo/so.obo
$obos{chebi} = 'ftp://ftp.ebi.ac.uk/pub/databases/chebi/ontology/chebi.obo';
# $obos{humando} = 'https://diseaseontology.svn.sourceforge.net/svnroot/diseaseontology/trunk/HumanDO.obo';	# for disease OA 2013 01 12
# $obos{humando} = 'http://www.berkeleybop.org/ontologies/doid.obo';	# new url Ranjana 2013 08 08
$obos{humando} = 'http://purl.obolibrary.org/obo/doid.obo';	# new url Ranjana 2018 08 29
$obos{topicrelations} = 'http://tazendra.caltech.edu/~acedb/karen/topic_relations.obo';	# Karen wants relations ontology for process term, will edit her own copy to make a slim.  2014 05 01
$obos{eco} = 'https://raw.githubusercontent.com/evidenceontology/evidenceontology/master/eco.obo';	# Ranjana wants it, Kimberly uses for .ace upload

# need  app_rearrangement  app_variation  int_sentid  pic_exprpattern  trp_clone  trp_location   pic_picturesource




$/ = undef;
foreach my $obotable (sort keys %obos) {
#   &createTable($obotable);				# only create table once
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
    if ($new_date > $file_date) {
      &updateData($obotable, $file_name, $new_data);
    } # if ($new_date > $file_date)
  } # if ($new_data =~ m/date: (\d+):(\d+):(\d+) (\d+):(\d+)/)
} # foreach my $obotable (sort keys %obos) 
$/ = "\n";

# TODO
# # get the nightly data from geneace  2013 10 24
# `/home/postgres/work/pgpopulation/obo_oa_ontologies/geneace/nightly_geneace.pl`;
# 
# # get nightly gin_ data from geneace and nightly nameserver json dump  2013 10 25
# `/home/postgres/work/pgpopulation/obo_oa_ontologies/geneace/populate_gin_nightly.pl`;
# 
# # get new sequence features data and email Daniela and Xiaodong about new objects or added/changed papers.  2014 10 01
# `/home/postgres/work/pgpopulation/sqf_sequencefeature/populate_from_geneace/parse_seqfeat.pl`;


# update app term data from sanger, which takes some 30 mins  2010 07 22
# `/home/acedb/jolene/WS_AQL_queries/update_variation_obo.pl`;	# no longer update everyday, do full update on first of month by calling webpage script

# No longer using updateVariationObo nor addToVariationObo, now using nightly_geneace.pl  2013 10 24
# my $start_time = time;
# my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime($start_time);
# my $full_run_file = '/home/acedb/jolene/WS_AQL_queries/full_run';
# my $yes_or_no = 'no';
# open (IN, "<$full_run_file") or warn "Cannot open $full_run_file : $!";
# $yes_or_no = <IN>; chomp $yes_or_no;
# close (IN) or warn "Cannot close $full_run_file : $!";
# # if ($mday eq '1') { # }			# do full wipe and repopulate on 1st of month
# if ($yes_or_no =~ m/YES/i) {			# do full wipe and repopulate if karen file is set to yes
# #   `wget "http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/generic.cgi?action=UpdateVariationObo"`;
#   my $u = "http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/generic.cgi?action=UpdateVariationObo";
#   my $ua = LWP::UserAgent->new(timeout => 99999); #instantiates a new user agent
#   $ua->timeout( 999999 );			# this is still getting an Uncaught exception from user code: Error while getting http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/generic.cgi?action=UpdateVariationObo -- 504 Gateway Time-out
#   my $request = HTTP::Request->new(GET => $u); #grabs url
#   my $response = $ua->request($request);       #checks url, dies if not valid.
#   die "Error while getting ", $response->request->uri," -- ", $response->status_line, "\nAborting" unless $response-> is_success;
#   open (OUT, "<$full_run_file") or die "Cannot open $full_run_file : $!";
#   print OUT "NO\n";				# set karen file to NO for next time cronjob runs
#   close (OUT) or die "Cannot close $full_run_file : $!";
# #   `wget "http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/generic.cgi?action=UpdateVariationObo"`;		# this times out
# } else {				# do incremental additions other days  2010 08 23
#   get "http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/generic.cgi?action=AddToVariationObo";
# }




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
      else { $name = ''; }
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
    $result = $dbh->do("INSERT INTO $table VALUES( '$id', '$name') ");
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
  print OUT "$new_data";
  close (OUT) or die "Cannot close $file_name : $!"; 
} # sub updateData


sub createTable {
  my ($obotable) = @_;
  my @tables = qw( name syn data );
  foreach my $table_type (@tables) {
    my $table = 'obo_' . $table_type . '_' . $obotable;
    $result = $dbh->do("DROP TABLE $table; ");
    $result = $dbh->do( "CREATE TABLE $table ( joinkey text, $table text, obo_timestamp timestamp with time zone DEFAULT \"timestamp\"('now'::text) );" );
    $result = $dbh->do( "CREATE INDEX ${table}_idx ON $table USING btree (joinkey);" );
    $result = $dbh->do("REVOKE ALL ON TABLE $table FROM PUBLIC; ");
    $result = $dbh->do("GRANT ALL ON TABLE $table TO postgres; ");
    $result = $dbh->do("GRANT ALL ON TABLE $table TO acedb; ");
    $result = $dbh->do("GRANT ALL ON TABLE $table TO apache; ");
    $result = $dbh->do("GRANT ALL ON TABLE $table TO azurebrd; ");
    $result = $dbh->do("GRANT ALL ON TABLE $table TO cecilia; ");
    $result = $dbh->do( qq(GRANT ALL ON TABLE $table TO "www-data";) );
  }
} # sub createTable


__END__

my $result = $dbh->prepare( "SELECT * FROM two_comment WHERE two_comment ~ ?" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[1] =~ s///g;
    $row[2] =~ s///g;
    print "$row[0]\t$row[1]\t$row[2]\n";
  } # if ($row[0])
} # while (@row = $result->fetchrow)

__END__

