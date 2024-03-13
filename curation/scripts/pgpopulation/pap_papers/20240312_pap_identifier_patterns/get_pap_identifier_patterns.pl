#!/usr/bin/env perl

# figure out pap identifier patterns that Kimberly cares about here   2024 03 12
# https://agr-jira.atlassian.net/browse/SCRUM-3662?page=com.atlassian.jira.plugin.system.issuetabpanels%3Aall-tabpanel
#
# better WM wm pattern, but eventually won't use anything for WM at ABC.  2024 03 13


use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );
# use JSON::Parse 'parse_json';
# use JSON::XS;
use JSON;
use Jex;
use Text::Unaccent;
use Dotenv -load => '/usr/lib/.env';
use utf8;

binmode STDOUT, ':utf8';

my $dbh = DBI->connect ( "dbi:Pg:dbname=$ENV{PSQL_DATABASE};host=$ENV{PSQL_HOST};port=$ENV{PSQL_PORT}", "$ENV{PSQL_USERNAME}", "$ENV{PSQL_PASSWORD}") or die "Cannot connect to database!\n";
my $result;

my %prefix;

# check some subset of WM, but not all of it, full wm doesn't require 'wm' in the identifier.  see dump_agr_literature.pl for correct code.
$result = $dbh->prepare( "SELECT * FROM pap_identifier WHERE joinkey IN (SELECT joinkey FROM pap_type WHERE pap_type = '3') ORDER BY joinkey, pap_order" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[1] =~ m/wm/) {
#     unless ($row[1] =~ m/^[A-Za-z0-9]{6,13}$/) { print qq(@row\n); }
    unless ($row[1] =~ m/^\w*wm[0-9]{1,4}[A-Za-z0-9_\-]*[0-9]{1,4}[a-zA-Z]*$/) { print qq(@row\n); }
# don't know why this fails to match  wm2009ab1174A, but we decided with Ian it was so loose as not to mean anything, and we'll have no restriction on WM xrefs.
  }
}

# check wbg pattern
$result = $dbh->prepare( "SELECT * FROM pap_identifier WHERE pap_identifier ~ '^wbg' ORDER BY joinkey, pap_order" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  unless ($row[1] =~ m/^wbg\d{1,2}\.[A-Za-z0-9\.]{1,6}$/) { print qq(@row\n); }
}

# check cgc pattern
$result = $dbh->prepare( "SELECT * FROM pap_identifier WHERE pap_identifier ~ '^cgc' ORDER BY joinkey, pap_order" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  unless ($row[1] =~ m/^cgc\d{1,4}$/) { print qq(@row\n); }
}

# Find prefixes
# 
# $result = $dbh->prepare( "SELECT * FROM pap_identifier ORDER BY joinkey, pap_order" );
# $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
# while (my @row = $result->fetchrow) {
# #   if ($row[0] % 1000 == 0) { print qq(@row\n); }
#   next if ($row[1] =~ m/^\d{8}$/);
#   my ($prefix) = $row[1] =~ m/^([A-Za-z]+)/;
#   if ($prefix) { $prefix{$prefix}++; }
#     else { print qq(NO PREFIX $row[1]\n); }
# }
# 
# foreach my $prefix (sort keys %prefix) {
#   print qq($prefix\t$prefix{$prefix}\n);
# }


