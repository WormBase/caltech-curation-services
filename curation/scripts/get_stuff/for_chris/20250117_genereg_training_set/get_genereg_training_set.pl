#!/usr/bin/env perl

# get expression training set data for ABC, for Daniela and Valerio.  https://agr-jira.atlassian.net/browse/SCRUM-4151
# output at https://docs.google.com/spreadsheets/d/1dInUAzeFUrk1vC7YcM7LZOw1d5cc4J9IzpBWCEDv6pE/edit?gid=1344280547#gid=1344280547
# 2024 10 10
#
# modified for chris for genereg.  https://agr-jira.atlassian.net/browse/SCRUM-4593


use strict;
use LWP::Simple;
use Jex;
use DBI;
use Dotenv -load => '/usr/lib/.env';

my $dbh = DBI->connect ( "dbi:Pg:dbname=$ENV{PSQL_DATABASE};host=$ENV{PSQL_HOST};port=$ENV{PSQL_PORT}", "$ENV{PSQL_USERNAME}", "$ENV{PSQL_PASSWORD}") or die "Cannot connect to database!\n";
my $result;

my $date = &getSimpleDate();

my $url = $ENV{THIS_HOST} . 'priv/cgi-bin/curation_status.cgi?action=listCurationStatisticsPapersPage&select_datatypesource=caltech&select_curator=two1823&listDatatype=genereg&method=allval%20pos&checkbox_cfp=on&checkbox_afp=on&checkbox_str=on&checkbox_nnc=on&checkbox_svm=on';

my $positiveAref = &getJoinkeysFromUrl($url);
my @positive = @$positiveAref;
# print qq(@positive\n);

my $url = $ENV{THIS_HOST} . 'priv/cgi-bin/curation_status.cgi?action=listCurationStatisticsPapersPage&select_datatypesource=caltech&select_curator=two1823&listDatatype=genereg&method=allval%20neg&checkbox_cfp=on&checkbox_afp=on&checkbox_str=on&checkbox_nnc=on&checkbox_svm=on';

my $negativeAref = &getJoinkeysFromUrl($url);
my @negative = @$negativeAref;
# print qq(@negative\n);

my %toAgr;
&getJoinkeyToAgrkb();

my %any; my %pos; my %neg;
foreach my $pos (@positive) { $any{$pos}++; $pos{$pos}++; }
foreach my $neg (@negative) { $any{$neg}++; $neg{$neg}++; }
my $any = join"', '", sort keys %any;

foreach my $joinkey (sort keys %any) {
  my $val = 0;
  if ($pos{$joinkey}) { $val = 1; }
  my $agr = $toAgr{$joinkey};
  print qq($agr\tWB:WBPaper$joinkey\t$val\n);
}

sub getJoinkeyToAgrkb {
  my $result = $dbh->prepare( "SELECT joinkey, pap_identifier FROM pap_identifier WHERE pap_identifier ~ 'AGRKB';" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
    $toAgr{$row[0]} = $row[1]; } }

sub getJoinkeysFromUrl {
  my $url = shift;
  my $pageData = get $url;
  my ($joinkeys) = $pageData =~ m/<textarea.*?>(.*)<\/textarea>/;
  my (@joinkeys) = split/\s+/, $joinkeys;
  my $count = scalar @joinkeys;
#   print qq($count\n);
  return \@joinkeys;
} # sub getJoinkeysFromUrl

# print qq($joinkeys\n);

# my $outfile = $ENV{CALTECH_CURATION_FILES_INTERNAL_PATH} . '/cronjobs/curation_stats/files/curation_status.' . $date . '.html';
# my $outfile = '/home/acedb/cron/curation_stats/files/curation_status.' . $date . '.html';

# open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
# print OUT $pageData;
# close (OUT) or die "Cannot close $outfile : $!";

