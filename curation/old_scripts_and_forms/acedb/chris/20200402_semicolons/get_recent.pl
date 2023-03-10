#!/usr/bin/perl -w

# query for OA objects whose names or synonyms could have a ; or &

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my @obo_tables = qw( anatomy feature integrationmethod picturesource taxon chebi geneclass intsentid prosentid topicrelations clone goid laboratory quality variation cnsconstructtype goidcomponent lifestage rearrangement cnsreporter goidfunction ncbitaxonid soid entity goidprocess pcrproduct species exprcluster humando phenotype strain );

my @chars = qw( ; & );
my @types = qw( name syn );

foreach my $obo (@obo_tables) {
  foreach my $type (@types) {
    my $table = 'obo_' . $type . '_' . $obo;
    my $output = '';
    foreach my $char (@chars) {
      $result = $dbh->prepare( "SELECT * FROM $table WHERE $table ~ '$char'" );
      $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
      while (my @row = $result->fetchrow) {
        if ($row[0]) { $output .= qq($table\t@row\n); }
      }
    }
   if ($output) {
     open (OUT, ">$table") or die "Cannot open $table : $!";
     print OUT $output;
     close (OUT) or die "Cannot close $table : $!";
   }
  } # while (@row = $result->fetchrow)
} # foreach my $obo (@obo_tables)

my @object_tables = qw( abp_name con_curator dis_curator dit_curator exp_name lab_name mop_publicname mop_molecule mop_synonym gin_protein trp_publicname trp_synonym cns_name cns_publicname cns_othername cns_summary gin_locus gin_synonyms gin_seqname gin_wbgene gno_identifier gno_name gno_synonym pap_species_index pap_status two_standardname pic_source prt_processid prt_processname prt_othername rna_name sqf_publicname sqf_othername gin_sequence );
foreach my $table (@object_tables) {
  my $output = '';
  foreach my $char (@chars) {
    $result = $dbh->prepare( "SELECT * FROM $table WHERE $table ~ '$char'" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) {
      if ($row[0]) { $output .= qq($table\t@row\n); }
    }
  }
  if ($output) {
    open (OUT, ">$table") or die "Cannot open $table : $!";
    print OUT $output;
    close (OUT) or die "Cannot close $table : $!";
  }
}

__END__

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb;host=131.215.52.76", "", "") or die "Cannot connect to database!\n";	# for remote access

my $result = $dbh->prepare( 'SELECT * FROM two_comment WHERE two_comment ~ ?' );
$result->execute('elegans') or die "Cannot prepare statement: $DBI::errstr\n"; 

$result->execute("doesn't") or die "Cannot prepare statement: $DBI::errstr\n"; 
my $var = "doesn't";
$result->execute($var) or die "Cannot prepare statement: $DBI::errstr\n"; 

my $data = 'data';
unless (is_utf8($data)) { from_to($data, "iso-8859-1", "utf8"); }

my $result = $dbh->do( "DELETE FROM friend WHERE firstname = 'bl\"ah'" );
(also do for INSERT and UPDATE if don't have a variable to interpolate with ? )

can cache prepared SELECTs with $dbh->prepare_cached( &c. );

if ($result->rows == 0) { print "No names matched.\n\n"; }	# test if no return

$result->finish;	# allow reinitializing of statement handle (done with query)
$dbh->disconnect;	# disconnect from DB

http://209.85.173.132/search?q=cache:5CFTbTlhBGMJ:www.perl.com/pub/1999/10/DBI.html+dbi+prepare+execute&cd=4&hl=en&ct=clnk&gl=us

interval stuff : 
SELECT * FROM afp_passwd WHERE joinkey NOT IN (SELECT joinkey FROM afp_lasttouched) AND joinkey NOT IN (SELECT joinkey FROM cfp_curator) AND afp_timestamp < CURRENT_TIMESTAMP - interval '21 days' AND afp_timestamp > CURRENT_TIMESTAMP - interval '28 days';

casting stuff to substring on other types :
SELECT * FROM afp_passwd WHERE CAST (afp_timestamp AS TEXT) ~ '2009-05-14';

to concatenate string to query result :
  SELECT 'WBPaper' || joinkey FROM pap_identifier WHERE pap_identifier ~ 'pmid';
to get :
  SELECT DISTINCT(gop_paper_evidence) FROM gop_paper_evidence WHERE gop_paper_evidence NOT IN (SELECT 'WBPaper' || joinkey FROM pap_identifier WHERE pap_identifier ~ 'pmid') AND gop_paper_evidence != '';

