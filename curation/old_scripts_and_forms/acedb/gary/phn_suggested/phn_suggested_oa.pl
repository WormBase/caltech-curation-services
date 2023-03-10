#!/usr/bin/perl -w

# query for suggested terms from app_suggested and rna_suggested in the last week.
# to confirm/reject in new_objects.cgi  for Gary.  2014 09 18
#
# added Karen to emails.
# changed to daily for Gary + Karen.
# exclude those were <datatype>_suggested matches 'REJECTED'.  2014 10 31
#
# cronjob :
# 0 3 * * * /home/acedb/gary/phn_suggested/phn_suggested_oa.pl


use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );
use Jex;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my $body = '';
my @datatypes = qw( app rna );
foreach my $datatype (@datatypes) {
  my $result = $dbh->prepare( "SELECT * FROM ${datatype}_suggested WHERE ${datatype}_suggested !~ 'REJECTED' AND ${datatype}_timestamp >= current_date - interval '1 days' " );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    if ($row[0]) { 
      $body .= qq($datatype\t$row[0]\t$row[1]\t$row[2]\n);
    } # if ($row[0])
  } # while (@row = $result->fetchrow)
}

my $subject = "check new_objects.cgi";
my $user    = "phn_suggested_oa.pl";
my $email   = 'garys@caltech.edu, kyook@caltech.edu, cgrove@caltech.edu';
# my $email   = 'azurebrd@tazendra.caltech.edu';
if ($body) { 
  $body       = "http://tazendra.caltech.edu/~postgres/cgi-bin/new_objects.cgi\n\n" . $body;
  &mailer($user, $email, $subject, $body); }

