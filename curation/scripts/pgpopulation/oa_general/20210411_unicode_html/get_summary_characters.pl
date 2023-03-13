#!/usr/bin/env perl

# query a datatype or a datatype-field (pgtable) for characters outside of (ascii?) range  2021 04 15

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 decode encode );
use HTML::Entities;

use Dotenv -load => '/usr/lib/.env';

use lib qw( /usr/lib/priv/cgi-bin/oa/ );
# use lib qw( /home/postgres/public_html/cgi-bin/oa/ );           # to get tables/fields and which ones to split as multivalue
use wormOA;


my $dbh = DBI->connect ( "dbi:Pg:dbname=$ENV{PSQL_DATABASE};host=$ENV{PSQL_HOST};port=$ENV{PSQL_PORT}", "$ENV{PSQL_USERNAME}", "$ENV{PSQL_PASSWORD}") or die "Cannot connect to database!\n";
# my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my $datatype_list_href = &populateWormDatatypeList();
my %datatypes = %$datatype_list_href;

my $table = '';
my $datatype = '';
if ($ARGV[0]) { 
  my $user_input = $ARGV[0];
  if ($user_input =~ m/^[a-zA-Z]{3}$/) { 
      if ($datatypes{$user_input}) { $datatype = $user_input; }
        else { die qq(ERROR $user_input is not a valid datatype\n); } }
    elsif ($user_input =~ m/^[a-zA-Z]{3}_[a-zA-Z]+$/) {
      my ($datatype, $field) = &getDatatypeAndField($user_input);
      if ($datatypes{$datatype}) {
          my ($fieldsRef, $datatypesRef) = &initModFields($datatype, 'two1823');
          my %fields = %$fieldsRef;
          if ($fields{$datatype}{$field}) { $table = $user_input; }
            else { die qq(ERROR $user_input has valid datatype $datatype but invalid field $field\n); } }
        else { die qq(ERROR $user_input has invalid datatype $datatype\n); } }
    else { die qq(ERROR $user_input is not a table or datatype\n); }
}

if ($datatype) { 
  my ($fieldsRef, $datatypesRef) = &initModFields($datatype, 'two1823');
  my %fields = %$fieldsRef;
  foreach my $field (sort keys %{ $fields{$datatype} }) {
    next if ($field eq 'id');             # skip pgid column
    my $table = $datatype . '_' . $field;
    &processTable($table);
  }
} 

if ($table) { &processTable($table); }

sub processTable {
  my $table = shift;
  my $outfile = $table;
  my %badChar;
  my %badSummary;
  $result = $dbh->prepare( "SELECT * FROM $table" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    if ($row[1]) { 
      if ($row[1] =~ m/([^\x00-\x7F])/g) { 
        $badSummary{$row[1]}{$row[0]}++;
  #       my $before = $row[1];
  # #       $row[1] = decode('utf-8', $row[1]);
  #       $row[1] = &utf8ToHtml($row[1]);
  #       my $after = $row[1];
  #       print qq($row[0]\t$before\t$after\t<br>\n);
        my (@nonascii) = $row[1] =~ m/([^\x00-\x7F])/g;
        foreach my $nonascii (@nonascii) {
          $badChar{$nonascii}{$row[0]}++;
        }
      }
    } # if ($row[0])
  } # while (@row = $result->fetchrow)

  my $output = '';
  foreach my $badChar (sort keys %badChar) {
    my $pgids = join",", sort keys %{ $badChar{$badChar} };
    $output .= qq($badChar\t$pgids\n);
  } # foreach my $badChar (sort keys %badChar)
  
  foreach my $badSummary (sort keys %badSummary) {
    my $pgids = join",", sort keys %{ $badSummary{$badSummary} };
    $output .= qq($badSummary\t$pgids\n);
  } # foreach my $badSummary (sort keys %badSummary)

  if ($output) {
    open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
    print OUT $output;
    close (OUT) or die "Cannot close $outfile : $!";
  }
}

sub utf8ToHtml {
  my $value = shift;
  return encode_entities(decode('utf-8', $value));
} # sub utf8ToHtml

sub getDatatypeAndField {
  my $input = shift;
  my ($datatype, $field) = split/_/, $input;
  return ($datatype, $field);
} # sub getDatatypeAndField

