#!/usr/bin/perl

# Get the invalid wbpapers and the new papers from tazendra.
# Look at go_curation data and find outdated lines in postgres,
# to print to screen.  Look at concise_description data for
# outdated lines in postgres, to print to screen, but these 
# don't matter since they get converted at .ace dump time.
# 2005 09 30
#
# Usage : ./find_merged_entries.pl > out.date.hourminsec
# Ouputs to screen.  2005 09 30
#
# Possibly need to add this to a cronjob or have the output
# email someone.  2005 10 04
#
# Added to cronjob every Wednesday at 3am, redirect output
# to log file in logs/outfile.date  2005 11 10
# 0 3 * * wed /home/postgres/work/pgpopulation/update_wbpaper_merging/postgres_gene_merging/find_merged_entries.pl
#
#
# No longer necessary, when papers are merged, the form can copy
# the data over to the new paper.  2010 06 23



use Jex;
use strict;
use LWP::Simple;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $date = &getSimpleSecDate();
my $outfile = '/home/postgres/work/pgpopulation/wpa_papers/update_wbpaper_merging/postgres_gene_merging/logs/outfile.' . $date;
open (OUT, ">$outfile") or die "Cannot create $outfile : $!";

my $file = get "http://tazendra.caltech.edu/~postgres/cgi-bin/merged_papers.cgi";
my %invalid_map;
my @lines = split/\n/, $file;
foreach my $line (@lines) {
  if ($line =~ m/^(\d{8})\tis now\t(.*)<BR>/) {
    my $old = 'WBPaper' . $1; my $new = 'WBPaper' . $2;
    $invalid_map{$old} = $new; }
} # foreach my $line (@lines)

# Uncomment these to test those tables  (not for this script 2005 10 04)
# $invalid_map{WBPaper00005937} = 'test_got_bio_paper_evidence_data';
# $invalid_map{WBPaper00001064} = 'test_car_seq_ref_reference_data';
# $invalid_map{WBPaper00025054} = 'test_car_con_ref_reference_data';

foreach my $old (sort keys %invalid_map) {
  my %old_data; my %new_data;
  unless ($invalid_map{$old}) { next; }		# skip if no new paper to move data to
  my $new = $invalid_map{$old};
  $new =~ s/WBPaper//g;
  my $result = $conn->exec( "SELECT * FROM wpa_gene WHERE joinkey = '$new' ORDER BY wpa_timestamp;" );
  while (my @row = $result->fetchrow) { 
    my ($gene) = $row[1] =~ m/(WBGene\d{8})/;
    if ($row[3] eq 'valid') { 
      my $evi = $row[2]; my $cur = $row[4]; my $time = $row[5];
      $new_data{$gene}{$evi}{$cur} = $time; }
    else { delete $new_data{$gene}; } }
  $old =~ s/WBPaper//g;
  $result = $conn->exec( "SELECT * FROM wpa_gene WHERE joinkey = '$old' ORDER BY wpa_timestamp;" );
  while (my @row = $result->fetchrow) { 
    my ($gene) = $row[1] =~ m/(WBGene\d{8})/;
    if ($row[3] eq 'valid') { 
      my $evi = $row[2]; my $cur = $row[4]; my $time = $row[5];
      $old_data{$gene}{$evi}{$cur} = $time; }
    else { delete $old_data{$gene}; } }
  foreach my $old_join (sort keys %old_data) {
    if ($new_data{$old_join}) { 		# gene exists
      foreach my $old_evi (sort keys %{ $old_data{$old_join} }) {
        if ($new_data{$old_join}{$old_evi}) { 	# evidence exists
            foreach my $old_cur (sort keys %{ $old_data{$old_join}{$old_evi} }) {
              if ($new_data{$old_join}{$old_evi}{$old_cur}) { 1; }	# curator put evidence 
                else { 				# new curator
                  # add curator and timestamp
                  my $old_tim = $old_data{$old_join}{$old_evi}{$old_cur};
                  if ($old_evi) { $old_evi = "'$old_evi'"; } else { $old_evi = 'NULL'; }
                  my $pgcommand = "INSERT INTO wpa_gene VALUES ('$new', '$old_join', $old_evi, 'valid', '$old_cur', '$old_tim');";
                  my $pgcommand = "INSERT INTO wpa_gene VALUES ('$new', '$old_join', $old_evi, 'valid', '$old_cur', CURRENT_TIMESTAMP);";
                  print OUT "$pgcommand\n";
                  my $result = $conn->exec( "$pgcommand" );
                  print OUT "CURATOR old paper $old new PAPER $new GENE $old_join EVI $old_evi CUR $old_cur TIME $old_tim\n"; } } }
          else {					# evidence needs to be copied completely
            # copy all data for this evidence
            foreach my $old_cur (sort keys %{ $old_data{$old_join}{$old_evi} }) {
              my $old_tim = $old_data{$old_join}{$old_evi}{$old_cur};
              if ($old_evi) { $old_evi = "'$old_evi'"; } else { $old_evi = 'NULL'; }
              my $pgcommand = "INSERT INTO wpa_gene VALUES ('$new', '$old_join', $old_evi, 'valid', '$old_cur', '$old_tim');";
              my $pgcommand = "INSERT INTO wpa_gene VALUES ('$new', '$old_join', $old_evi, 'valid', '$old_cur', CURRENT_TIMESTAMP);";
              print OUT "$pgcommand\n";
              my $result = $conn->exec( "$pgcommand" );
              print OUT "EVIDENCE old paper $old new PAPER $new GENE $old_join EVI $old_evi CUR $old_cur TIME $old_tim\n"; } } }
    } else {					# gene needs to be copied completely
      # copy all data for this gene
      foreach my $old_evi (sort keys %{ $old_data{$old_join} }) {
        foreach my $old_cur (sort keys %{ $old_data{$old_join}{$old_evi} }) {
          my $old_tim = $old_data{$old_join}{$old_evi}{$old_cur};
          if ($old_evi) { $old_evi = "'$old_evi'"; } else { $old_evi = 'NULL'; }
          my $pgcommand = "INSERT INTO wpa_gene VALUES ('$new', '$old_join', $old_evi, 'valid', '$old_cur', '$old_tim');";
#           my $pgcommand = "INSERT INTO wpa_gene VALUES ('$new', '$old_join', $old_evi, 'valid', '$old_cur', CURRENT_TIMESTAMP);";
          print OUT "$pgcommand\n";
          my $result = $conn->exec( "$pgcommand" );
          print OUT "GENE add to old paper $old new PAPER $new GENE $old_join EVI $old_evi CUR $old_cur TIME $old_tim\n"; } }
    }
  } # foreach my $old (sort keys %old_data)
} # foreach my $old (sort keys %invalid_map)

close (OUT) or die "Cannot close $outfile : $!";

#   This fail to check all curators
# foreach my $old (sort keys %invalid_map) {
#   my %old_data; my %new_data;
#   unless ($invalid_map{$old}) { next; }		# skip if no new paper to move data to
#   my $new = $invalid_map{$old};
#   $new =~ s/WBPaper//g;
#   my $result = $conn->exec( "SELECT * FROM wpa_gene WHERE joinkey = '$new' ORDER BY wpa_timestamp;" );
#   while (my @row = $result->fetchrow) { 
#     my ($gene) = $row[1] =~ m/(WBGene\d{8})/;
#     if ($row[3] eq 'valid') { 
#       $new_data{$gene}{$row[2]}{cur} = $row[4];
#       $new_data{$gene}{$row[2]}{tim} = $row[5]; }
#     else { delete $new_data{$gene}; } }
#   $old =~ s/WBPaper//g;
#   $result = $conn->exec( "SELECT * FROM wpa_gene WHERE joinkey = '$old' ORDER BY wpa_timestamp;" );
#   while (my @row = $result->fetchrow) { 
#     my ($gene) = $row[1] =~ m/(WBGene\d{8})/;
#     if ($row[3] eq 'valid') { 
#       $old_data{$gene}{$row[2]}{cur} = $row[4];
#       $old_data{$gene}{$row[2]}{tim} = $row[5]; }
#     else { delete $old_data{$gene}; } }
#   foreach my $old_join (sort keys %old_data) {
#     if ($new_data{$old_join}) { 		# gene exists
#       foreach my $old_evi (sort keys %{ $old_data{$old_join} }) {
#         my $old_cur = $old_data{$old_join}{$old_evi}{cur};
#         my $old_tim = $old_data{$old_join}{$old_evi}{tim};
#         if ($new_data{$old_join}{$old_evi}) { 	# evidence exists
#           unless ($old_cur eq $new_data{$old_join}{$old_evi}{cur}) {	# different curator put evidence 
#             # add curator and timestamp
#             print "CURATOR old paper $old new PAPER $new GENE $old_join EVI $old_evi CUR $old_cur TIME $old_tim\n"; 
#           }
#         } else {				# evidence needs to be copied completely
#           print "EVIDENCE old paper $old new PAPER $new GENE $old_join EVI $old_evi CUR $old_cur TIME $old_tim\n"; 
#           # copy all data for this evidence
#         }
#       } # foreach my $old_evi (sort keys %{ $old_data{$old_join} })
#     } else {					# gene needs to be copied completely
#       # copy all data for this gene
#       foreach my $old_evi (sort keys %{ $old_data{$old_join} }) {
#         my $old_cur = $old_data{$old_join}{$old_evi}{cur};
#         my $old_tim = $old_data{$old_join}{$old_evi}{tim};
#         print "GENE add to old paper $old new PAPER $new GENE $old_join EVI $old_evi CUR $old_cur TIME $old_tim\n"; 
#       }
#     }
#   } # foreach my $old (sort keys %old_data)
# } # foreach my $old (sort keys %invalid_map)

