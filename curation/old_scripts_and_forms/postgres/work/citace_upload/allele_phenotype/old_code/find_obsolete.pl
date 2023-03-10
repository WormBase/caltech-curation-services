#!/usr/bin/perl -w

# crontab set to every wednesday at 3am
# 0 3 * * wed /home/postgres/work/citace_upload/allele_phenotype/find_obsolete.pl
# find obsolete terms and email them to carol.  2005 12 29
#
# Wasn't matching because of the : between WBPhenotype and the digits no longer
# being there.  2006 08 07
#
# old way didn't deal with overwriting values on the same keys  2006 08 16
#
# was skipping alp_term that were empty, so was overwriting old values when
# there were new ones, but wasn't really overwriting old values when they were
# empty.  2007 02 21
#
# Added Gary to email recepients list.  For Carol  2007 04 13
#
# Added Karen to email list.  For Gary  2007 09 05
#
# Was getting all terms instead of current terms only in list of terms.  2008 01 23

use strict;
use diagnostics;
use Pg;
use Jex;

# print "pie\n";

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $body = '';
my %phenotypeTerms;
&readCvs();

my %terms;
my $result = $conn->exec( "SELECT * FROM alp_term ORDER BY alp_timestamp ;" );
while (my @row = $result->fetchrow) { 
  my $key = $row[0] . '_' . $row[1] . '_' . $row[2];
  if ($row[3]) { if ($row[3] =~ m/(WBPhenotype\d+)/) {
#       push @{ $terms{$1} }, $key; 		# old way didn't deal with overwriting values on the same keys
      $terms{key}{$key} = $1; } }
    else {
      delete $terms{key}{$key}; } }

foreach my $key (sort keys %{ $terms{key} }) {
  my $term = $terms{key}{$key};
  $terms{term}{$term}++;
  if ($phenotypeTerms{obs}{$term}) { 
    $body .= "Key $key has term $term which is obsolete\n"; } }

foreach my $term (sort keys %{ $terms{term}} ) {
  unless ($phenotypeTerms{exist}{$term}) {
    if ($phenotypeTerms{alt_id}{$term}) {
        my $new_term = shift(@{ $phenotypeTerms{alt_id}{$term} });
        my %annots; my @annots; my $annots;
        my $result = $conn->exec( "SELECT joinkey FROM alp_term WHERE alp_term ~ '$term';" );
        while (my @row = $result->fetchrow) { $annots{$row[0]}++; }
        @annots = keys %annots; $annots = join", ", @annots;
#         print "Term $term is now $new_term, replacing annotations $annots in Postgres with $new_term ($phenotypeTerms{exist}{$new_term})\n";
        $body .= "Term $term is now $new_term, replacing annotations $annots in Postgres with $new_term ($phenotypeTerms{exist}{$new_term})\n"; 
        my $command = "UPDATE alp_term SET alp_term = '$new_term ($phenotypeTerms{exist}{$new_term})' WHERE alp_term ~ '$term';";
#         print "$command\n";
        $result = $conn->exec( $command ); }
      else { $body .= "Term $term does not exist\n"; } } }

# old way didn't deal with overwriting values on the same keys
# foreach my $term (sort keys %terms) { 
#   if ($phenotypeTerms{obs}{$term}) { 
#     foreach my $key (@{ $terms{$term} }) {
#       $body .= "Key $key has term $term which is obsolete\n"; } } }

my $subject = 'obsolete allele phenotype terms';
unless ($body) { $subject = 'there are no obsolete allele phenotype terms'; }
my $user = 'find_obsolete.pl';
my $email = 'garys@its, kyook@its';
# my $email = 'bastiani@its, garys@its';
# my $email = 'azurebrd@tazendra';
&mailer($user, $email, $subject, $body);

sub readCvs { 
  my $directory = '/home/postgres/work/citace_upload/allele_phenotype/temp';
  chdir($directory) or die "Cannot go to $directory ($!)";
  `cvs -d /var/lib/cvsroot checkout PhenOnt`;
  my $file = $directory . '/PhenOnt/PhenOnt.obo';
  $/ = "";
  open (IN, "<$file") or die "Cannot open $file : $!";
  while (my $para = <IN>) { 
    my $number = '';
    if ($para =~ m/id: WBPhenotype(\d+).*?\bis_obsolete: true/s) {
      $number = 'WBPhenotype' . $1;
      $phenotypeTerms{obs}{$number}++; } 
    if ($para =~ m/id: WBPhenotype(\d+)/) {
      $number = 'WBPhenotype' . $1;
      if ($para =~ m/name: (\w+)/) { $phenotypeTerms{exist}{$number} = $1; }
        else { $phenotypeTerms{exist}{$number} = 'no_value'; } }
    if ($para =~ m/alt_id: WBPhenotype(\d+)/) { 
      my $oth_number = 'WBPhenotype' . $1;
      push @{ $phenotypeTerms{alt_id}{$oth_number}}, $number; }
  } # while (my $para = <IN>)
  close (IN) or die "Cannot close $file : $!";
  $directory .= '/PhenOnt';
  `rm -rf $directory`;
  foreach my $alt (sort keys %{ $phenotypeTerms{alt_id} }) {
    if (scalar (@{ $phenotypeTerms{alt_id}{$alt}}) > 1) { $body .= "$alt is an alt_id in multiple entries\n"; } }
} # sub readCvs

