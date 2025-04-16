#!/usr/bin/env perl

# map paper author orcid to orcid person, to see if we can do automatic connections through orcid when papers come in
#
# use person_editor.cgi searchPaper code as starting point.  Always using two_possible two_verified order 1, which is 
# wrong, but simpler for now.  Needs fixing.  For Cecilia to look over to see how it looks, will need to decide whether
# to implement on form, or cronjob to automatically make connections, and if automatic, figure out how.  2025 04 15


use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );
use Dotenv -load => '/usr/lib/.env';

my $dbh = DBI->connect ( "dbi:Pg:dbname=$ENV{PSQL_DATABASE};host=$ENV{PSQL_HOST};port=$ENV{PSQL_PORT}", "$ENV{PSQL_USERNAME}", "$ENV{PSQL_PASSWORD}") or die "Cannot connect to database!\n";
# my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %orcidToTwo;
$result = $dbh->prepare( "SELECT joinkey, two_orcid FROM two_orcid;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  $orcidToTwo{$row[1]} = $row[0];
}


my %papPmid;
$result = $dbh->prepare( "SELECT joinkey, pap_identifier FROM pap_identifier WHERE pap_identifier ~ 'pmid';" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  $row[1] =~ s/pmid//g;
  $papPmid{$row[0]} = $row[1];
}

my @wbpapers = qw( 00067850 00068000 00068005 00068008 00068014 00068015 00068016 00068017 00068022 00068023 00068026 00068028 );

my %papAids;
my %pg_aid;
foreach my $joinkey (@wbpapers) {
  my @aids;
  $result = $dbh->prepare( "SELECT pap_author FROM pap_author WHERE joinkey = '$joinkey' ORDER BY pap_order" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) { push @aids, $row[0]; }
  my $aids = join"','", @aids;
  $papAids{$joinkey} = $aids;
  my @aut_tables = qw( index possible sent verified );
  foreach my $table (@aut_tables) {
    $result = $dbh->prepare( "SELECT * FROM pap_author_$table WHERE author_id IN ('$aids')" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
    while (my @row = $result->fetchrow) { unless ($row[2]) { $row[2] = 1; } $pg_aid{$row[0]}{$table}{$row[2]} = $row[1]; } }
}


foreach my $joinkey (@wbpapers) {
  print qq(\n$joinkey\t$papPmid{$joinkey}\n);
  my %xml_authors;
  if ($papPmid{$joinkey}) {
    my $pmid = $papPmid{$joinkey};
    $/ = undef;
    # my @xml_paths = qw( /home/postgres/work/pgpopulation/wpa_papers/pmid_downloads/done/ /home/postgres/work/pgpopulation/wpa_papers/wpa_pubmed_final/xml/ );
    my @xml_paths = qw( $ENV{CALTECH_CURATION_FILES_INTERNAL_PATH}/postgres/pgpopulation/pap_papers/pmid_downloads/done/ $ENV{CALTECH_CURATION_FILES_INTERNAL_PATH}/postgres/pgpopulation/pap_papers/wpa_pubmed_final/xml/ );
    my $xmlfile = '';
    foreach my $path (@xml_paths) {
      # my $file = '/home/postgres/work/pgpopulation/wpa_papers/pmid_downloads/done/' . $pmid;
      my $file = $ENV{CALTECH_CURATION_FILES_INTERNAL_PATH}. '/postgres/pgpopulation/pap_papers/pmid_downloads/done/' . $pmid;
      if (-e $file) { $xmlfile = $file; }
    }
    if ($xmlfile) {
      print "pmid $pmid xml found\n";
      open (IN, "<$xmlfile") or die "Cannot open $xmlfile : $!";
      my $xmldata = <IN>;
      close (IN) or die "Cannot close $xmlfile : $!";
      $/ = "\n";
      my %xml_authors_found;                # names found, to print ones not found
      %xml_authors = &getXmlAuthors($xmldata);
      my (@aids) = split/','/, $papAids{$joinkey};
      foreach my $i (0 .. $#aids) {
        my $aid = $aids[$i]; my $aname = $pg_aid{$aid}{index}{'1'};
        $aname =~ s/[\,\.]//g;                         # take out commas and dots
        $aname =~ s/_/ /g;                             # replace underscores for spaces
        my ($firstname, $middlename, $lastname, $standardname, $affiliation, $orcid, $possible, $verified, $orcidPerson) = ('','','','','', '', 'no_possible', 'not_verified', 'no_orcid_person');
        if ($xml_authors{$aname}{affiliation}) {  $affiliation  = shift @{ $xml_authors{$aname}{affiliation} };  $xml_authors_found{$aname}++; }
        if ($xml_authors{$aname}{lastname}) {     $lastname     = shift @{ $xml_authors{$aname}{lastname} };     $xml_authors_found{$aname}++; }
        if ($xml_authors{$aname}{firstname}) {    $firstname    = shift @{ $xml_authors{$aname}{firstname} };    $xml_authors_found{$aname}++; }
        if ($xml_authors{$aname}{orcid}) {        $orcid        = shift @{ $xml_authors{$aname}{orcid} };        $xml_authors_found{$aname}++; 
          if ($orcidToTwo{$orcid}) { $orcidPerson = $orcidToTwo{$orcid}; } }
        if ($xml_authors{$aname}{standardname}) { $standardname = shift @{ $xml_authors{$aname}{standardname} }; $xml_authors_found{$aname}++; }
        if ($pg_aid{$aid}{possible}{'1'}) { $possible = $pg_aid{$aid}{possible}{'1'}; }	# FIX always using one, but might not be right
        if ($pg_aid{$aid}{verified}{'1'}) { $verified = $pg_aid{$aid}{verified}{'1'}; }	# FIX always using one, but might not be right
        unless ($orcid) { $orcid = 'no_orcid'; }
        print qq($aid\t$aname\t$standardname\t$orcid\t$possible\t$verified\t$orcidPerson\n);
      }
    }
    else { print "NO XML for $pmid\n"; } }
  else { print "<br />No PMID found for WBPaper$joinkey\n"; }
} # foreach my $joinkey (@wbpapers)




sub getXmlAuthors {
  my ($xmldata) = @_; my %xml_authors;
  my @xml_authors = $xmldata =~ /\<Author.*?\>(.+?)\<\/Author\>/sig;
  foreach my $author_xml (@xml_authors) {
    my ($affiliation) = $author_xml =~ /\<Affiliation\>(.+?)\<\/Affiliation\>/i;
    my ($lastname) = $author_xml =~ /\<LastName\>(.+?)\<\/LastName\>/i;
    my ($initials) = $author_xml =~ /\<Initials\>(.+?)\<\/Initials\>/i;
    my ($forename) = $author_xml =~ /\<ForeName\>(.+?)\<\/ForeName\>/i;
    my $orcid = '';
    if ($author_xml =~ /\<Identifier Source="ORCID"\>(.+?)\<\/Identifier\>/i) { $orcid = $1; }
    my $author = $lastname . " " . $initials;
#     $xml_authors{$author}{affiliation} = $affiliation;
#     $xml_authors{$author}{lastname} = $lastname;
#     $xml_authors{$author}{firstname} = $forename;
#     $xml_authors{$author}{initials} = $initials;
#     $xml_authors{$author}{standardname} = "$forename $lastname"; }
    push @{ $xml_authors{$author}{affiliation} },  $affiliation;
    push @{ $xml_authors{$author}{lastname} },     $lastname;
    push @{ $xml_authors{$author}{firstname} },    $forename;
    push @{ $xml_authors{$author}{initials} },     $initials;
    push @{ $xml_authors{$author}{orcid} },        $orcid;
    push @{ $xml_authors{$author}{standardname} }, "$forename $lastname"; }
  return %xml_authors;
} # sub getXmlAuthors

__END__

