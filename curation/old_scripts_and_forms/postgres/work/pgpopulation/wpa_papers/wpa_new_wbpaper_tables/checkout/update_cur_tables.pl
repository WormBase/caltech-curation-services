#!/usr/bin/perl -w

# update joinkeys of cur_ tables to use wbpapers, if multiple papers
# refer to the same wbpaper, merge them as
# joinkey\tdata\ttimestamp\tjoinkey\etc.  
#
# store copies of cur_ tables's data in 
# /home/postgres/work/pgpopulation/wpa_new_wbpaper_tables/checkout/20050822_non_converted_backup/$table.pg.20050822.094410
# 2005 08 22


use strict;
use diagnostics;
use Pg;
use Jex;


my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $outfile = "outfile.update_cur_tables";
open(OUT, ">$outfile") or die "Cannot create $outfile : $!";

my @cur_tables = qw( cur_ablationdata cur_antibody cur_associationequiv cur_associationnew cur_cellfunction cur_cellname cur_comment cur_covalent cur_curator cur_expression cur_extractedallelename cur_extractedallelenew cur_fullauthorname cur_functionalcomplementation cur_genefunction cur_geneinteractions cur_geneproduct cur_generegulation cur_genesymbol cur_genesymbols cur_goodphoto cur_invitro cur_mappingdata cur_microarray cur_mosaic cur_newmutant cur_newsnp cur_newsymbol cur_overexpression cur_rnai cur_sequencechange cur_sequencefeatures cur_site cur_stlouissnp cur_structurecorrection cur_structurecorrectionsanger cur_structurecorrectionstlouis cur_structureinformation cur_supplemental cur_synonym cur_transgene );

my %wbPaper;
my $result = $conn->exec( "SELECT * FROM wpa_identifier ORDER BY wpa_timestamp ;" );
while (my @row = $result->fetchrow) {
  if ($row[3] eq 'valid') { $wbPaper{$row[1]} = $row[0]; }
    else { delete $wbPaper{$row[1]}; }
} # while (my @row = $result->fetchrow) 

my %no_convertion;

# my $date = &getSimpleSecDate;
my %stored_data;

foreach my $table (@cur_tables) {
  my %used_wbpaper;
#   $result = $conn->exec( "COPY $table TO '/home/postgres/work/pgpopulation/wpa_new_wbpaper_tables/checkout/20050822_non_converted_backup/$table.pg.$date' ;" );
  $result = $conn->exec( "SELECT * FROM $table ;" );
  while (my @row = $result->fetchrow) {
    my $unconverted = ''; my $data = ''; my $timestamp = '';
    if ($row[0]) { $unconverted = $row[0]; }
    if ($row[1]) { $data = $row[1]; }
    if ($row[2]) { $timestamp = $row[2]; }
    my $two_number = '0';
    unless ($wbPaper{$unconverted}) {
      if ($row[1]) { $no_convertion{$row[0]}{$table} = $row[1]; }
      next; }			# skip if no wbpaper for that cgc / pmid
    unless ($data) { next; }	# skip if no data
    my $wbpaper = $wbPaper{$unconverted};
    if ($used_wbpaper{$wbpaper}) { $stored_data{$wbpaper} .= "\t$row[0]\t$data\t$timestamp"; }
      else { $stored_data{$wbpaper} = "$row[0]\t$data\t$timestamp"; }
    $used_wbpaper{$wbpaper}++;
  } # while (my @row = $result->fetchrow)
  foreach my $wbpaper (sort keys %used_wbpaper) {
#     if ($used_wbpaper{$wbpaper} > 1) { print "TOO MANY $table $wbpaper\n"; } 
    if ($used_wbpaper{$wbpaper} > 1) { 
        my @stuff = split"\t", $stored_data{$wbpaper};
        my $greatest_timestamp = 0; my $greatest_copy_timestamp = 0;
        while (@stuff) { 
          my $joinkey = shift @stuff;
          my $data = shift @stuff;
          my $timestamp = shift @stuff;
          my $pg_command = "DELETE FROM $table WHERE joinkey = '$joinkey'";
          my $result2 = $conn->exec( "$pg_command" ); 
          print OUT "$pg_command\n";
          my $copy_timestamp = $timestamp; $copy_timestamp =~ s/\D//g; $copy_timestamp =~ m/(\d{12})/; $copy_timestamp = $1;
          if ($copy_timestamp > $greatest_copy_timestamp) { $greatest_timestamp = $timestamp; $greatest_copy_timestamp = $copy_timestamp; }
        } # while (@stuff) 
        my $pg_command = "INSERT INTO $table VALUES ('$wbpaper', '$stored_data{$wbpaper}', '$greatest_timestamp')";
        my $result2 = $conn->exec( "$pg_command" ); 
        print OUT "$pg_command\n";
        print "MERGE $table $wbpaper\t$stored_data{$wbpaper}\t$greatest_timestamp\n"; }
      else {
        my ($joinkey, $data, $timestamp) = split"\t", $stored_data{$wbpaper};
        my $pg_command = "UPDATE $table SET joinkey = '$wbpaper' WHERE joinkey = '$joinkey'";
        my $result2 = $conn->exec( "$pg_command" ); 
        print OUT "$pg_command\n";
        print "$wbpaper\t$stored_data{$wbpaper}\n"; }
  } # foreach my $wbpaper (sort keys %used_wbpaper)
} # foreach my $table (@cur_tables)

foreach my $paper (sort keys %no_convertion) {
  foreach my $table (sort keys %{ $no_convertion{$paper} }) {
    print "No convertion for paper $paper in table $table with data $no_convertion{$paper}{$table}\n"; 
  } # foreach my $table (sort keys %{ $no_convertion{$table} })
} # foreach my $paper (sort keys %no_convertion)

#       if ($row[1] =~ m/Andrei/) { $data = 'two480'; }
#       elsif ($row[1] =~ m/Raymond/) { $data = 'two363'; }
#       elsif ($row[1] =~ m/Erich/) { $data = 'two567'; }
#       elsif ($row[1] =~ m/Ranjana/) { $data = 'two324'; }
#       elsif ($row[1] =~ m/Sternberg/) { $data = 'two625'; }
#       elsif ($row[1] =~ m/Wen/) { $data = 'two101'; }
#       elsif ($row[1] =~ m/Carol/) { $data = 'two48'; }
#       elsif ($row[1] =~ m/Kimberly/) { $data = 'two1843'; }
#       elsif ($row[1] =~ m/Igor/) { $data = 'two22'; }
#       else { 1; } 



close (OUT) or die "Cannot close $outfile : $!";


