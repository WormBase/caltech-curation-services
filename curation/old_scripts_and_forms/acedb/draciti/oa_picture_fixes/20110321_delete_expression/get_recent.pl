#!/usr/bin/perl -w

# query expr_pattern objects from picture objects that are cropped_from in other picture objects.
# Daniela wants to delete these, this is a backup.  2011 03 21

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my $result = $dbh->prepare( "SELECT * FROM pic_exprpattern WHERE pic_exprpattern IS NOT NULL AND joinkey IN (SELECT joinkey FROM pic_name WHERE pic_name IN (SELECT pic_croppedfrom FROM pic_croppedfrom) );" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  my $row = join"\t", @row;
  print "$row\n";
} # while (@row = $result->fetchrow)

