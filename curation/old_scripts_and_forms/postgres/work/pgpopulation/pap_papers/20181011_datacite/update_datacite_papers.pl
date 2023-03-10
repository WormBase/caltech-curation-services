#!/usr/bin/perl -w

# update papers from Datacite XML, which have micropublication biology, have a DOI, but don't have a title.  For Daniela.  2018 10 11
#
# also give it type Journal_article. for Daniela  2020 01 24

# 0 20 * * * /home/postgres/work/pgpopulation/pap_papers/20181011_datacite/update_datacite_papers.pl      # daniela




use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );
use LWP;
use URI::Escape;
use Net::Domain qw(hostname hostfqdn hostdomain);
use Jex;

my $hostname    = hostname();
my $hostdomain  = hostdomain();  unless ($hostdomain) { $hostdomain = 'caltech.edu'; }  # tazendra doesn't have dnsdomainname set
my $hostfqdn    = $hostname . '.' . $hostdomain;

 
my $user = "caltech.micropub";
my $pass = "mP8_>microZC";
 
my $ua = LWP::UserAgent->new;
my $ub = LWP::UserAgent->new;

# my $curator = 'two1823';
my $curator = 'two12028';
#   my $email = 'closertothewake@gmail.com';
my $email = 'daniela.raciti@micropublication.org';

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %journal;
my %title;
my %doi;

$result = $dbh->prepare( "SELECT * FROM pap_journal WHERE pap_journal ~ 'microPublication Biology'" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $journal{$row[0]} = $row[1]; } }

$result = $dbh->prepare( "SELECT * FROM pap_title" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $title{$row[0]} = $row[1]; } }

$result = $dbh->prepare( "SELECT * FROM pap_identifier WHERE pap_identifier ~ '^doi'" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $doi{$row[0]} = $row[1]; } }

my $body = '';
foreach my $paper (sort keys %journal) {
  next if ($title{$paper});
  next unless ($doi{$paper});
#   print qq($paper\t$doi{$paper}\n);
  my $doiId = $doi{$paper}; $doiId =~ s/^doi//g;

  my $edit_url = 'http://' . $hostfqdn . '/~postgres/cgi-bin/paper_editor.cgi?action=Search&data_number=' . $paper . '&curator_id=' . $curator;
  $body .= qq($edit_url\n);

#   my $login_url = "https://api.datacite.org/application/vnd.datacite.datacite+xml/10.17912/2jgw-fj52";
#   my $login_url = "https://api.datacite.org/application/vnd.datacite.datacite+xml/$doiId";
  my $login_url = "https://data.datacite.org/application/vnd.datacite.datacite+xml/$doiId";	# new url 2019 01 04
#   print qq(URL $login_url\n);
  $ua->credentials( $login_url, 'PAUSE', $user, $pass);
  my $resp = $ua->get( $login_url);
#   print $resp->status_line;
#   print $resp->content;
  my $all_text = $resp->content;
  my ($title, $abstract, $year) = ('', '', '');
  if ($all_text =~ m/<title[^>]*>(.*?)<\/title>/) { $title = $1; }	# extra junk in now.  2019 06 13
  if ($all_text =~ m/<description descriptionType="Abstract">(.*?)<\/description>/s) { $abstract = $1; }
#   if ($all_text =~ m/<date dateType="Issued">(.*?)<\/date>/) { $year = $1; }
  if ($all_text =~ m/<publicationYear>(.*?)<\/publicationYear>/) { $year = $1; }	# new field.  2019 06 13
  &updateData($paper, 'type', 1, '26');				# make them Micropublication
  &updateData($paper, 'type', 2, '1');				# make them Journal_article
  &updateData($paper, 'curation_flags', 1, 'author_person');
  &updateData($paper, 'primary_data', 1, 'primary');
  &updateData($paper, 'title', 1, $title);
  &updateData($paper, 'year', 1, $year);
  &updateData($paper, 'abstract', 1, $abstract);
#   print qq(T $title\n);
#   print qq(Y $year\n);
#   print qq(A $abstract\n);
#   my (@authors) = $all_text =~ m/<creatorName>(.*?)<\/creatorName>/g; 
  my (@authors) = $all_text =~ m/<creatorName[^>]*>(.*?)<\/creatorName>/g; 	# extra junk in now.  2019 06 13
  my $autCount = 0;
  foreach my $author (@authors) {
    $autCount++;
    &updateData($paper, 'author_new', $autCount, $author);
#     print qq(AUT $author\n);
  }
} # foreach my $paper (sort keys %journal)

if ($body) { 
  my $user = 'update_datacite_papers';
  my $subject = 'New bibliographic info added for WBPaperID for microPublication Biology';
  &mailer($user, $email, $subject, $body); }


sub updateData {
  my ($paper, $table, $order, $data) = @_;
  my $uriData = uri_escape($data);
  my $url = 'http://' . $hostfqdn . '/~postgres/cgi-bin/paper_editor.cgi?action=updatePostgresTableField&field=' . $table . '&joinkey=' . $paper . '&order=' . $order . '&curator=' . $curator . '&newValue=' . $uriData;
# UNCOMMENT TO POPULATE
  my $resp = $ub->get( $url );
#   print qq(URL $url URL\n);
}

__END__

curation_flags -> author_person
primary_data -> primary
type -> Micropublication

/~postgres/cgi-bin/paper_editor.cgi?action=updatePostgresTableField&field=author_new&joinkey=00055322&order=1&curator=two1823&newValue=a%20name

/~postgres/cgi-bin/paper_editor.cgi?action=updatePostgresTableField&field=type&joinkey=00055322&order=1&curator=two1823&newValue=26
/~postgres/cgi-bin/paper_editor.cgi?action=updatePostgresTableField&field=curation_flags&joinkey=00055322&order=1&curator=two1823&newValue=author_person
/~postgres/cgi-bin/paper_editor.cgi?action=updatePostgresTableField&field=primary_data&joinkey=00055322&order=1&curator=two1823&newValue=primary
/~postgres/cgi-bin/paper_editor.cgi?action=updatePostgresTableField&field=editor&joinkey=00055322&order=1&curator=two1823&newValue=someone 



00055322	doi10.17912/YHG7-JE66
URL https://api.datacite.org/application/vnd.datacite.datacite+xml/10.17912/YHG7-JE66
200 OK<?xml version="1.0" encoding="UTF-8"?>
<resource xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://datacite.org/schema/kernel-4" xsi:schemaLocation="http://datacite.org/schema/kernel-4 http://schema.datacite.org/meta/kernel-4/metadata.xsd">
  <identifier identifierType="DOI">10.17912/YHG7-JE66</identifier>
  <creators>
    <creator>
      <creatorName>Takashi Koyama</creatorName>
    </creator>
    <creator>
      <creatorName>Chisato Ushida</creatorName>
    </creator>
  </creators>
  <titles>
    <title>Nuclear localization of a C. elegans CCCH-type zinc finger protein encoded by T26A8.4</title>
  </titles>
  <publisher>microPublication Biology</publisher>
  <publicationYear>2018</publicationYear>
  <resourceType resourceTypeGeneral="DataPaper">Journal article</resourceType>
  <dates>
    <date dateType="Issued">2018</date>
  </dates>
  <version/>
  <descriptions>
    <description descriptionType="Abstract">T26A8.4 encodes a CCCH-type zinc finger protein. The amino acid sequence of this protein is partially similar to that of S. cerevisiae Caf120p, which has no zinc finger domain. T26A8.4-encoded RNA was detected more abundantly in germ cells than in other tissues of L4-adult worms according to the NEXTDB data. When expressed specifically in the germline under control of the mex-5 promoter, the T26A8.4-encoded protein localized to germ cell nuclei in the adult hermaphrodite and can be seen in foci (arrowheads in the insets of panels A and C). During germline development, gene expression is primarily regulated posttranscriptionally by the mRNA stability and/or translation with the 3’UTRs (Merritt et al. 2008). To test the post-transcriptional regulation of T26A8.4 expression, T26A8.4::GFP with its own 3’UTR and that with tbb-2 3’UTR were compared. The results showed that T26A8.4 is expressed throughout the germline with both 3’UTRs, indicating that T26A8.4 does not appear to be post-transcriptionally regulated by its 3’UTR.

pTKD841 was made by cloning a fusion of PCR fragments of genomic mex-5 promoter with mex-5 5’UTR (523 bp), genomic T26A8.4 (2068 bp), a linker amino acid (Gly-Gly-Gly-Gly-Gly-Ala) coding sequence (18 bp), gfp (870 bp) and genomic T26A8.4 3’UTR (459 bp) with its downstream sequence (144 bp) into the Sbf1 site of a plasmid vector pCFJ151 (Zeiser et al. 2011). pTKD842 was made as pTKD841 except for the 3’UTR. Genomic tbb-2 3’UTR (297 bp) with its downstream sequence (32 bp) was fused to gfp in pTKD842. These plasmids were introduced into C. elegans EG4322 with plasmids pRF4 and pCFJ601 to make strains HUJ0001 and HUJ0002, respectively, by a MosSCI method (Frøkjær-Jensen et al. 2008; Frøkjær-Jensen et al. 2012). GFP signal was detected in the germ cell nuclei in both strains. Panels A) and C) show GFP signal from live imaging of HUJ0001 and HUJ0002, respectively. The inset of each panel shows the magnified image of an oocyte (dashed square) in an adult hermaphrodite. The foci were observed in the nucleus of diplotene stage to that of -1 oocyte. Some pachytene stage nuclei also exhibited the foci. Scale bars, 20 μm. Panels B) and D) show GFP signal with DAPI staining image of the fixed specimens of HUJ0001 and HUJ0002, respectively. The foci observed from the live imaging could not be detected. GFP, T26A8.4::GFP; DAPI, DAPI staining image; merged, merged image of GFP and DAPI. Scale bars, 100 μm.</description>
  </descriptions>
</resource>
