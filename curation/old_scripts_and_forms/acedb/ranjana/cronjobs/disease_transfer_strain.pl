#!/usr/bin/perl -w

# transfer dis_ OA strains from suggested to strain if allowed in ontology.  For Ranjana 2017 10 25
#
# 0 1 * * * /home/acedb/ranjana/cronjobs/disease_transfer_strain.pl



use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );
use Jex;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %data;
$result = $dbh->prepare( "SELECT * FROM dis_suggested_strain;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $data{suggested}{$row[0]} = $row[1]; } }
$result = $dbh->prepare( "SELECT * FROM dis_strain WHERE dis_strain IS NOT NULL AND dis_strain != '';" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $data{strain}{$row[0]} = $row[1]; } }
$result = $dbh->prepare( "SELECT * FROM obo_name_strain;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $data{valid}{$row[0]} = $row[1]; } }

my $toEmail = '';
my @pgcommands;
foreach my $pgid (sort keys %{ $data{suggested} }) {
  my $suggested = $data{suggested}{$pgid};
  if ($data{strain}{$pgid}) { 
      $toEmail .= qq(ERROR $pgid has values in both fields "$suggested" and "$data{strain}{$pgid}i"\n); }
    elsif ($data{valid}{$suggested}) {
      push @pgcommands, qq(INSERT INTO dis_strain VALUES ('$pgid', '$suggested'););
      push @pgcommands, qq(INSERT INTO dis_suggested_strain_hst VALUES ('$pgid', NULL););
      push @pgcommands, qq(DELETE FROM dis_suggested_strain WHERE joinkey = '$pgid';);
#       print qq(MOVE $pgid $suggested\n); 
    }
} # foreach my $suggested (sort keys %{ $data{suggested} })

foreach my $pgcommand (@pgcommands) {
#   print qq($pgcommand\n);
# UNCOMMENT TO UPDATE POSTGRES
  $dbh->do( $pgcommand );
} # foreach my $pgcommand (@pgcommands)

if ($toEmail) { 
  my $user = 'cronjob';
  my $email = 'ranjana@caltech.edu';
  my $subject = qq(disease_transfer_strain.pl errors);
  &mailer($user, $email, $subject, $toEmail); }

__END__
