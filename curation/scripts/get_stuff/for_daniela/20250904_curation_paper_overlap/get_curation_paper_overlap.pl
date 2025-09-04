#!/usr/bin/env perl

# get curated papers from 5 datatypes from curation status form, see which ones have the most overlap.  2025 09 04


use strict;
use LWP::Simple;
use Jex;
use DBI;
use Dotenv -load => '/usr/lib/.env';

my $dbh = DBI->connect ( "dbi:Pg:dbname=$ENV{PSQL_DATABASE};host=$ENV{PSQL_HOST};port=$ENV{PSQL_PORT}", "$ENV{PSQL_USERNAME}", "$ENV{PSQL_PASSWORD}") or die "Cannot connect to database!\n";
my $result;

my $date = &getSimpleDate();

# my $url = $ENV{THIS_HOST} . 'priv/cgi-bin/curation_status.cgi?select_curator=two1823&action=Curation+Statistics+Page&checkbox_all_datatypes=all&checkbox_all_flagging_methods=all';
# my $url = $ENV{THIS_HOST} . 'priv/cgi-bin/curation_status.cgi?action=listCurationStatisticsPapersPage&select_datatypesource=caltech&select_curator=two1823&listDatatype=otherexpr&method=allval pos cur&checkbox_cfp=on&checkbox_afp=on&checkbox_str=on&checkbox_nnc=on&checkbox_svm=on';

my %url;
$url{'geneprod'} = 'priv/cgi-bin/curation_status.cgi?action=listCurationStatisticsPapersPage&select_datatypesource=caltech&select_curator=two1823&listDatatype=geneprod&method=allcur&checkbox_cfp=on&checkbox_afp=on&checkbox_str=on&checkbox_nnc=on&checkbox_svm=on';
$url{'geneint'} = 'priv/cgi-bin/curation_status.cgi?action=listCurationStatisticsPapersPage&select_datatypesource=caltech&select_curator=two1823&listDatatype=geneint&method=allcur&checkbox_cfp=on&checkbox_afp=on&checkbox_str=on&checkbox_nnc=on&checkbox_svm=on';
$url{'newmutant'} = 'priv/cgi-bin/curation_status.cgi?action=listCurationStatisticsPapersPage&select_datatypesource=caltech&select_curator=two1823&listDatatype=newmutant&method=allcur&checkbox_cfp=on&checkbox_afp=on&checkbox_str=on&checkbox_nnc=on&checkbox_svm=on';
$url{'otherexpr'} = 'priv/cgi-bin/curation_status.cgi?action=listCurationStatisticsPapersPage&select_datatypesource=caltech&select_curator=two1823&listDatatype=otherexpr&method=allcur&checkbox_cfp=on&checkbox_afp=on&checkbox_str=on&checkbox_nnc=on&checkbox_svm=on';
$url{'rnai'} = 'priv/cgi-bin/curation_status.cgi?action=listCurationStatisticsPapersPage&select_datatypesource=caltech&select_curator=two1823&listDatatype=rnai&method=allcur&checkbox_cfp=on&checkbox_afp=on&checkbox_str=on&checkbox_nnc=on&checkbox_svm=on';

my %paps;
foreach my $datatype (sort keys %url) {
  my $url = $ENV{THIS_HOST} . $url{$datatype};
#   my $url = 'https://caltech-curation.textpressolab.com/' . $url{$datatype};
#   print qq(URL $url\n);
  my $pageData = get $url;
# print qq($pageData\n);
  my ($joinkeys) = $pageData =~ m/<textarea.*?>(.*)<\/textarea>/;
  my (@joinkeys) = split/\s+/, $joinkeys;
  foreach my $joinkey (@joinkeys) {
    $paps{$joinkey}++;
  }
}

my $max_count = 0;
foreach my $key (keys %paps) {
  $max_count = $paps{$key} if $paps{$key} > $max_count;
}

# Print all keys with that maximum count
print qq(entries with $max_count datatypes\n);
foreach my $key (keys %paps) {
  if ($paps{$key} == $max_count) {
    print "$key ";
  }
}

