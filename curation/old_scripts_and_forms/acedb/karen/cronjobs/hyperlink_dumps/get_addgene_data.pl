#!/usr/bin/perl -w

# query cns_ data for Karen
#
# cronjob to 8pm for Karen.  2018 02 22

# 0 20 * * * /home/acedb/karen/cronjobs/hyperlink_dumps/get_trp_data.pl


use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my @tables = qw( addgene publicname  summary name );

my $outfile = '/home/acedb/public_html/karen/hyperlink_dumps/cns_addgene_data.txt';
open (OUT, ">$outfile") or die "Cannot create $outfile : $!";

my $header = join"\t", @tables;
print OUT qq($header\n);

my %data;

foreach my $table (@tables) {
 $result = $dbh->prepare( "SELECT * FROM cns_$table" );
 $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
 while (my @row = $result->fetchrow) {
   if ($row[0]) { 
     $row[0] =~ s///g;
     $row[1] =~ s///g;
     $data{$row[0]}{$table} = $row[1];
   } # if ($row[0])
 } # while (@row = $result->fetchrow)
}

foreach my $pgid (sort { $a <=> $b } keys %data) {
  my @line;
  foreach my $table (@tables) { 
    my $data = '';
    if ($data{$pgid}{$table}) { $data = $data{$pgid}{$table}; }
    push @line, $data; }
  my $line = join"\t", @line;
  print OUT qq($line\n);
}

close (OUT) or die "Cannot close $outfile : $!";
 
