#!/usr/bin/perl

# everyday (since I don't know when the aceserver gets updated)
# check the Life_stage and Strain objects for the allele_phenotype_curation.cgi
# 2007 08 23
#
# 0 3 * * tue,wed,thu,fri,sat /home/azurebrd/public_html/sanger/alp_class/update_class.pl


use strict;
use Ace;

my $dir = '/home/azurebrd/public_html/sanger/alp_class/';
chdir($dir) or die "Cannot switch to $dir : $!";

my @classes = qw( Life_stage Strain );

foreach my $class (@classes) {
  use constant HOST => $ENV{ACEDB_HOST} || 'aceserver.cshl.org';
  use constant PORT => $ENV{ACEDB_PORT} || 2005;
  my $db = Ace->connect(-host=>HOST,-port=>PORT) or warn "Connection failure: ",Ace->error;
  my $query = "find $class";
  my @class = $db->fetch(-query=>$query);
  if ($class[0]) {
    my $outfile = $dir . $class;
    open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
    foreach my $obj (@class) { print OUT "$obj\n"; }
    close (OUT) or die "Cannot close $outfile : $!"; }
} # foreach my $class (@classes)

