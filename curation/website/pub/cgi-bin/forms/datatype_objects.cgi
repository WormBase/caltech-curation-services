#!/usr/bin/perl 

# Query the OA for autocomplete, term info, validity

# For CoKo for Daniela + Karen + Todd.  2018 05 16
#
# Added phenotype for Valerio.  2020 07 13
#
# exp_laboratory doesn't exist anymore, switched to cns_laboratory.  2023 02 08


use strict;
use diagnostics;
use CGI;
use Jex;
use LWP::Simple;
use Net::Domain qw(hostname hostfqdn hostdomain);


my $hostfqdn = hostfqdn();

my $query = new CGI;
my $var;
($var, my $action)    = &getHtmlVar($query, 'action');
($var, my $userValue) = &getHtmlVar($query, 'userValue');
($var, my $objectType)  = &getHtmlVar($query, 'objectType');

# if not using forcedOAC.generateRequest in YUI
# ($var, my $queryValue) = &getHtmlVar($query, 'query');
# unless ($userValue) { $userValue = $queryValue; }

my %validActions;
$validActions{autocompleteXHR} = 'query';
$validActions{asyncTermInfo}   = 'userValue';
$validActions{asyncValidValue} = 'userValue';

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


print "Content-type: text/html\n\n";

if ($action && $userValue && $objectType) {
  unless ($validActions{$action}) { print qq($action is not a valid action, contact Juancarlos\n); next; }
  if ($objectMap{$objectType}) {
      $userValue =~ s/ /%20/g;
      my $field    = $objectMap{$objectType}{field};
      my $datatype = $objectMap{$objectType}{datatype};
#       my $url = "http://tazendra.caltech.edu/~postgres/cgi-bin/oa/ontology_annotator.cgi?action=" . $action . "&field=" . $field . "&datatype=" . $datatype . "&curator_two=two1823&" . $validActions{$action} . "=" . $userValue;
      my $url = "http://" . $hostfqdn . "/~postgres/cgi-bin/oa/ontology_annotator.cgi?action=" . $action . "&field=" . $field . "&datatype=" . $datatype . "&curator_two=two1823&" . $validActions{$action} . "=" . $userValue;
      my $data = get $url;
      print qq($data\n); }
    else { print qq(objectType $objectType doesn't map to fields and datatype, contact Juancarlos\n); }
} else { print qq(Action, objectType, and userValue required\n); }




# http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/datatype_objects.cgi?action=autocompleteXHR&objectType=gene&userValue=egl-
# http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/datatype_objects.cgi?action=asyncTermInfo&objectType=gene&userValue=egl-1%20(%20WBGene00001170%20)%20
# http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/datatype_objects.cgi?action=asyncValidValue&objectType=gene&userValue=egl-1%20(%20WBGene00001170%20)%20


