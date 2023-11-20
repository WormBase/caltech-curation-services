#!/usr/bin/env perl 

# Query first pass tables for textpresso first pass form 
#
# added cur_nncdata and cur_blackbox to output for Valerio.  2021 02 02
#
# decode utf-8 data from postgres to avoid extra junk characters, for Valerio.  2021 04 19
#
# dockerized for Valerio and ACKnowledge.  2023 10 05

# http://mangolassi.caltech.edu/~azurebrd/cgi-bin/forms/textpresso/first_pass_api.cgi?action=jsonPaper&paper=00000003&passwd=1228446342.8668923



use strict;
use diagnostics;
use CGI;
use Jex;
use DBI;
use LWP::Simple;
use JSON;
use Encode qw( from_to is_utf8 decode encode );
use Dotenv -load => '/usr/lib/.env';

my $dbh = DBI->connect ( "dbi:Pg:dbname=$ENV{PSQL_DATABASE};host=$ENV{PSQL_HOST};port=$ENV{PSQL_PORT}", "$ENV{PSQL_USERNAME}", "$ENV{PSQL_PASSWORD}") or die "Cannot connect to database!\n";
# my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n";
my $result;

my $query = new CGI;
my $var;

my %datatypes;
$result = $dbh->prepare( "SELECT table_name FROM information_schema.tables WHERE table_schema='public' AND table_name ~ '^afp' AND table_name !~ '_hst\$';" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) { $row[0] =~ s/afp_//g; $datatypes{all}{$row[0]}++; $datatypes{afp}{$row[0]}++; }
$result = $dbh->prepare( "SELECT table_name FROM information_schema.tables WHERE table_schema='public' AND table_name ~ '^cfp' AND table_name !~ '_hst\$';" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) { $row[0] =~ s/cfp_//g; $datatypes{all}{$row[0]}++; $datatypes{cfp}{$row[0]}++; }
$result = $dbh->prepare( "SELECT table_name FROM information_schema.tables WHERE table_schema='public' AND table_name ~ '^tfp' AND table_name !~ '_hst\$';" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) { $row[0] =~ s/tfp_//g; $datatypes{all}{$row[0]}++; $datatypes{tfp}{$row[0]}++; }
# foreach my $datatype (sort keys %datatypes) {
#   if ($datatypes{$datatype} < 2) { delete $datatypes{$datatype}; } }

my ($paper, $passwd) = &checkPaperPasswd();
if ($paper ne 'bad') { &process(); }

sub process {
  ($var, my $action)    = &getHtmlVar($query, 'action');
  unless ($action) { $action = ''; }

  if ($action eq 'jsonPaper') {           &jsonPaper($paper); }
#     elsif ($action eq 'Flag') {         &meh(); }
      else {                              &jsonPaper($paper); }

#   ($var, my $userValue) = &getHtmlVar($query, 'userValue');
#   ($var, my $objectType)  = &getHtmlVar($query, 'objectType');
  
} # sub process

sub jsonPaper {
  my ($paper) = @_;
  my %data;
  print qq(Content-type: application/json\n\n);
  my @flagTypes = qw( afp cfp tfp );
  foreach my $datatype (sort keys %{ $datatypes{all} }) {
    foreach my $type (@flagTypes) { 
      next unless ($datatypes{$type}{$datatype});
      $result = $dbh->prepare( "SELECT * FROM ${type}_$datatype WHERE joinkey = '$paper';" );
      $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
      my @row = $result->fetchrow();
#       $data{$datatype}{$type} = decode('utf-8', $row[1]);	# causes Wide character failure on paper 00065682
      $data{$datatype}{$type} = $row[1];
  } }
  $result = $dbh->prepare( "SELECT * FROM cur_nncdata WHERE cur_paper = '$paper';" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) { $data{$row[1]}{nnc} = $row[3]; }
  $result = $dbh->prepare( "SELECT * FROM cur_svmdata WHERE cur_paper = '$paper';" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) { $data{$row[1]}{svm} = $row[3]; }
  $result = $dbh->prepare( "SELECT * FROM cur_strdata WHERE cur_paper = '$paper';" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) { $data{$row[1]}{str} = $row[3]; }
  $result = $dbh->prepare( "SELECT * FROM cur_blackbox WHERE cur_paper = '$paper' ORDER BY cur_timestamp;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) { $data{$row[1]}{blackbox} = $row[3]; }

  my $json = encode_json \%data;
  print qq($json);
} # sub jsonPaper



sub checkPaperPasswd {
#   my ($paper, $passwd) = ('00000003', '1228446342.8668923');
  ($var, my $paper)  = &getHtmlVar($query, 'paper');
  ($var, my $passwd) = &getHtmlVar($query, 'passwd');
  unless ($paper) {  $paper  = '00000003';           }
  unless ($passwd) { $passwd = '1228446342.8668923'; }
  $result = $dbh->prepare( "SELECT * FROM afp_passwd WHERE joinkey = '$paper' AND afp_passwd = '$passwd';" );
  $result->execute();
  my @row = $result->fetchrow;
# UNCOMMENT THIS TO PUT PASSWORD CHECKING BACK
  unless ($row[0]) { print "Invalid Password<BR>\n"; return "bad"; }
  my $time = time;
# print "TIME $time<BR>\n";
  my $timediff = $time - $passwd;
# UNCOMMENT THIS TO PUT PASSWORD EXPIRY BACK
#   if ($timediff > 604800) { print "Password has expired after 7 days, please email <A HREF=\"mailto:petcherski\@gmail.com\">Andrei</A> for renewal<BR>\n"; return "bad"; }
  return ($paper, $passwd);
} # sub checkPaperPasswd








__END__

my %validActions;
$validActions{autocompleteXHR} = 'query';
$validActions{asyncTermInfo}   = 'userValue';
$validActions{asyncValidValue} = 'userValue';

my %objectMap;
$objectMap{gene}{datatype}                 = 'exp';
$objectMap{gene}{field}                    = 'gene';
$objectMap{person}{datatype}               = 'exp';
$objectMap{person}{field}                  = 'contact';
$objectMap{laboratory}{datatype}           = 'exp';
$objectMap{laboratory}{field}              = 'laboratory';
$objectMap{species}{datatype}              = 'exp';
$objectMap{species}{field}                 = 'species';
$objectMap{transgene}{datatype}            = 'exp';
$objectMap{transgene}{field}               = 'transgene';
$objectMap{wbbt}{datatype}                 = 'exp';
$objectMap{wbbt}{field}                    = 'anatomy';
$objectMap{wbls}{datatype}                 = 'exp';
$objectMap{wbls}{field}                    = 'lifestage';
$objectMap{gocc}{datatype}                 = 'app';
$objectMap{gocc}{field}                    = 'gocomponent';
$objectMap{variation}{datatype}            = 'exp';
$objectMap{variation}{field}               = 'variation';
$objectMap{strain}{datatype}               = 'exp';
$objectMap{strain}{field}                  = 'strain';
$objectMap{reporter}{datatype}             = 'cns';
$objectMap{reporter}{field}                = 'reporter';
$objectMap{backbonevector}{datatype}       = 'cns';
$objectMap{backbonevector}{field}          = 'clone';
$objectMap{fusion}{datatype}               = 'cns';
$objectMap{fusion}{field}                  = 'constructtype';
$objectMap{integrationmethod}{datatype}    = 'cns';
$objectMap{integrationmethod}{field}       = 'integrationmethod';


print "Content-type: text/html\n\n";

if ($action && $userValue && $objectType) {
  unless ($validActions{$action}) { print qq($action is not a valid action, contact Juancarlos\n); next; }
  if ($objectMap{$objectType}) {
      $userValue =~ s/ /%20/g;
      my $field    = $objectMap{$objectType}{field};
      my $datatype = $objectMap{$objectType}{datatype};
      my $url = "http://tazendra.caltech.edu/~postgres/cgi-bin/oa/ontology_annotator.cgi?action=" . $action . "&field=" . $field . "&datatype=" . $datatype . "&curator_two=two1823&" . $validActions{$action} . "=" . $userValue;
      my $data = get $url;
      print qq($data\n); }
    else { print qq(objectType $objectType doesn't map to fields and datatype, contact Juancarlos\n); }
} else { print qq(Action, objectType, and userValue required\n); }




# http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/datatype_objects.cgi?action=autocompleteXHR&objectType=gene&userValue=egl-
# http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/datatype_objects.cgi?action=asyncTermInfo&objectType=gene&userValue=egl-1%20(%20WBGene00001170%20)%20
# http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/datatype_objects.cgi?action=asyncValidValue&objectType=gene&userValue=egl-1%20(%20WBGene00001170%20)%20


