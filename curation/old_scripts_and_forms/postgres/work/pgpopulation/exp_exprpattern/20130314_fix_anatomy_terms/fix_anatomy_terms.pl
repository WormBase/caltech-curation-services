#!/usr/bin/perl -w

# fix anatomy terms for Daniela.  2013 03 14
#
# changed to update postgres for each value as it rotates, because we're not setting all values at once for each pgid 
# (which I think would be slower, although would only have a single update for all of it.)  2013 03 21
#
# live run on tazendra  2013 03 21

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %map;
$map{"WBbt:0005143"} = 'WBbt:0004381","WBbt:0004380';
$map{"WBbt:0005160"} = 'WBbt:0004679';
$map{"WBbt:0005161"} = 'WBbt:0004685';
$map{"WBbt:0005162"} = 'WBbt:0004687';
$map{"WBbt:0005163"} = 'WBbt:0004690';
$map{"WBbt:0005164"} = 'WBbt:0004692';
$map{"WBbt:0005166"} = 'WBbt:0004694';

foreach my $map (sort keys %map) { 
  my @pgcommands;
  $result = $dbh->prepare( "SELECT * FROM exp_anatomy WHERE exp_anatomy ~ '$map';" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { 
    my $old = $row[1];
    my $new = $row[1]; $new =~ s/$map/$map{$map}/g;
    print "anatomy\t$map TO $map{$map}\t$row[0]\t$old\tTO\t$new\n";
    my $pgcommand = qq(UPDATE exp_anatomy SET exp_anatomy = '$new' WHERE joinkey = '$row[0]' AND exp_anatomy = '$old');
    push @pgcommands, $pgcommand;
  } # while (my @row = $result->fetchrow)
  $result = $dbh->prepare( "SELECT * FROM exp_anatomy_hst WHERE exp_anatomy_hst ~ '$map';" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { 
    my $old = $row[1];
    my $new = $row[1]; $new =~ s/$map/$map{$map}/g;
    print "anatomy_hst\t$row[0]\t$old\tTO\t$new\n";
    my $pgcommand = qq(UPDATE exp_anatomy_hst SET exp_anatomy_hst = '$new' WHERE joinkey = '$row[0]' AND exp_anatomy_hst = '$old');
    push @pgcommands, $pgcommand;
  } # while (my @row = $result->fetchrow)

  foreach my $pgcommand (@pgcommands) {		# have to execute here because it's updating values one value at a time across data+history tables.
    print "$pgcommand\n";
#   UNCOMMENT TO UPDATE TABLES
#     $dbh->do( $pgcommand );
  }
} # foreach my $map (sort keys %map)


__END__

my %anat;
$result = $dbh->prepare( "SELECT * FROM obo_name_anatomy" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $anat{$row[0]}++; }

my %bad;
$result = $dbh->prepare( "SELECT * FROM exp_anatomy;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { 
  my $full = $row[1]; my $pgid = $row[0];
  $full =~ s/^\"//; $full =~ s/\"$//;
  my (@terms) = split/","/, $full;
  foreach my $term (@terms) {
    unless ($anat{$term}) { print "BAD $pgid $term $row[1]\n"; }
  }
} # while (my @row = $result->fetchrow)
