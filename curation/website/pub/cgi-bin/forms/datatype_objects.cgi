#!/usr/bin/env perl 

# Query the OA for autocomplete, term info, validity

# For CoKo for Daniela + Karen + Todd.  2018 05 16
#
# Added phenotype for Valerio.  2020 07 13
#
# exp_laboratory doesn't exist anymore, switched to cns_laboratory.  2023 02 08
#
# new action multiValueValidValue used by paper_editor.js to replace ajax/gethint.cgi
# which served a similar purpose as this, but allowed a list of  genestudied  or 
# genecomparator  to make exact matches, instead or OA autocomplete/terminfo/validation 
# (of name + wbid).  maybe should have kept it as a different script.  2023 04 04


use strict;
use diagnostics;
use CGI;
use Jex;
use DBI;
use LWP::Simple;
# use Net::Domain qw(hostname hostfqdn hostdomain);
use Dotenv -load => '/usr/lib/.env';

my $dbh = DBI->connect ( "dbi:Pg:dbname=$ENV{PSQL_DATABASE};host=$ENV{PSQL_HOST};port=$ENV{PSQL_PORT}", "$ENV{PSQL_USERNAME}", "$ENV{PSQL_PASSWORD}") or die "Cannot connect to database!\n";


# my $hostfqdn = hostfqdn();
my $thisHost = $ENV{THIS_HOST};

my $query = new CGI;
my $var;
($var, my $action)    = &getHtmlVar($query, 'action');
($var, my $userValue) = &getHtmlVar($query, 'userValue');
($var, my $objectType)  = &getHtmlVar($query, 'objectType');

# if not using forcedOAC.generateRequest in YUI
# ($var, my $queryValue) = &getHtmlVar($query, 'query');
# unless ($userValue) { $userValue = $queryValue; }

my %validActions;
$validActions{autocompleteXHR}      = 'query';
$validActions{asyncTermInfo}        = 'userValue';
$validActions{asyncValidValue}      = 'userValue';
$validActions{multiValueValidValue} = 'userValue';

my %objectMap;
$objectMap{gene}{datatype}                 = 'exp';
$objectMap{gene}{field}                    = 'gene';
$objectMap{person}{datatype}               = 'app';
$objectMap{person}{field}                  = 'person';
$objectMap{laboratory}{datatype}           = 'cns';
$objectMap{laboratory}{field}              = 'laboratory';
$objectMap{species}{datatype}              = 'exp';
$objectMap{species}{field}                 = 'species';
$objectMap{taxonid}{datatype}              = 'mop';
$objectMap{taxonid}{field}                 = 'endogenousin';
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
$objectMap{phenotype}{field}               = 'term';
$objectMap{phenotype}{datatype}            = 'app';
$objectMap{humandoid}{field}               = 'humandoid';
$objectMap{humandoid}{datatype}            = 'dis';


print "Content-type: text/html\n\n";

if ($action && $userValue && $objectType) {
  unless ($validActions{$action}) { print qq($action is not a valid action, contact Juancarlos\n); next; }
  if ($action eq 'multiValueValidValue') { &getMultiValueValidValues(); }
  elsif ($objectMap{$objectType}) {
      $userValue =~ s/ /%20/g;
      my $field    = $objectMap{$objectType}{field};
      my $datatype = $objectMap{$objectType}{datatype};
      # my $url = "http://tazendra.caltech.edu/~postgres/cgi-bin/oa/ontology_annotator.cgi?action=" . $action . "&field=" . $field . "&datatype=" . $datatype . "&curator_two=two1823&" . $validActions{$action} . "=" . $userValue;
      # my $url = "http://" . $hostfqdn . "/~postgres/cgi-bin/oa/ontology_annotator.cgi?action=" . $action . "&field=" . $field . "&datatype=" . $datatype . "&curator_two=two1823&" . $validActions{$action} . "=" . $userValue;
      my $url = $thisHost . "priv/cgi-bin/oa/ontology_annotator.cgi?action=" . $action . "&field=" . $field . "&datatype=" . $datatype . "&curator_two=two1823&" . $validActions{$action} . "=" . $userValue;
      # print qq($url<br>\n);
      my $data = get $url;
      print qq($data\n); }
    else { print qq(objectType $objectType doesn't map to fields and datatype, contact Juancarlos\n); }
} else { print qq(Action, objectType, and userValue required\n); }


sub getMultiValueValidValues {
  my @matches;
  my @words = split/\s+/, $userValue;
  my $type = $objectType;
  foreach my $word (@words) {
    if ($word =~ m/,$/) { $word =~ s/,$//g; }             # strip commas at the end for Karen  2009 07 24
    my ($lcword) = lc($word);             # words on the table are lowercased for ease of matching
    if ($lcword =~ m/\'/) { $lcword =~ s/\'/''/g; }
    my $found = ""; my @tables = qw( gin_wbgene gin_locus gin_synonyms gin_sequence gin_seqname ); my $result = "";
    if ($type eq 'genecomparator') { @tables = qw( gic_wbgene gic_pubname gic_cds ); }
    while ( ($found eq "") && (scalar(@tables) > 0) ) {
      my $table = shift @tables;
      $result = $dbh->prepare( "SELECT * FROM $table WHERE LOWER($table) = '$lcword';" );
      $result->execute();
      my @row = $result->fetchrow;
      if ($row[0]) { $found = $row[0]; }                  # if a word matched
    }
    next unless ($found);
    if ( ($type eq 'structcorr') || ($type eq 'genecomparator') ) {
      push @matches, "$word \($found\)"; }                # structcorr returns lab
    elsif ( ($type eq 'genestudied') || ($type eq 'genesymbol') ) {
      push @matches, "$word \(WBGene$found\)"; }  # genestudied and genesymbol return wbgene
    else { push @matches, "error on type"; }              # other fields not allowed
  }
  my $matches = join", ", @matches;                       # comma separate results
  print "$matches\n";                                     # return by printing to screen
} # sub getMultiValueValidValues


# http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/datatype_objects.cgi?action=autocompleteXHR&objectType=gene&userValue=egl-
# http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/datatype_objects.cgi?action=asyncTermInfo&objectType=gene&userValue=egl-1%20(%20WBGene00001170%20)%20
# http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/datatype_objects.cgi?action=asyncValidValue&objectType=gene&userValue=egl-1%20(%20WBGene00001170%20)%20


