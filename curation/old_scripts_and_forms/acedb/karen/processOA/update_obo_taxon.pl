#!/usr/bin/perl -w

# Populate obo_{name|syn|data}_taxon tables based on wbspecies.txt  2011 09 26
#
# skip entries without NCBI IDs (second column) for Karen.  2012 01 11
#
# make the number IDs be the postgres IDs as well since that's what gets dumped.  2012 01 12


use strict;
use diagnostics;
use DBI;
use LWP::Simple;
use LWP;


my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

# need a directory to store previous results so a cronjob only updates tables when the data is new
my $directory = '/home/postgres/public_html/cgi-bin/oa/scripts/obo_oa_ontologies/';
chdir ($directory) or die "Cannot chdir to $directory : $!";


# put postgres users that should have 'all' access to the table.
my @users_all = ('apache', 'azurebrd', 'cecilia', '"www-data"');

# put postgres users that should have 'select' access to the table.  mainly so they can log on and see the data from a shell, but would probably work if you set the webserver to have select access, it would just give error messages if someone tried to update data.
my @users_select = ('acedb');

my @pgcommands;
push @pgcommands, "DELETE FROM obo_name_taxon;";
push @pgcommands, "DELETE FROM obo_data_taxon;";
push @pgcommands, "DELETE FROM obo_syn_taxon;";

my $infile = '/home/acedb/karen/processOA/species_taxon.txt';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) {
  chomp $line;
  $line =~ s/\"//g;
  $line =~ s/\\//g;
  $line =~ s/'/''/g;
  my ($name, $id) = split/\t/, $line;
  my $info = '';
  next unless $name;
  next unless $id;
  $info .= "id: $id\n";
  if ($name) { $info .= "name: $name\n"; }
  push @pgcommands, "INSERT INTO obo_name_taxon VALUES( '$id', '$name')";
  push @pgcommands, "INSERT INTO obo_data_taxon VALUES( '$id', '$info')";
  if ($id) { push @pgcommands, "INSERT INTO obo_syn_taxon VALUES( '$name', '$id')"; }
} # while (my $line = <IN>)
close (IN) or die "Cannot close $infile : $!";

foreach my $pgcommand (@pgcommands) {
#   print "$pgcommand\n";
  $result = $dbh->do( $pgcommand );
} # foreach my $pgcommand (@pgcommands)
