#!/usr/bin/perl

# Get the invalid wbpapers and the new papers from tazendra.
# Look at go_curation data and find outdated lines in postgres,
# to print to screen.  Look at concise_description data for
# outdated lines in postgres, to print to screen, but these 
# don't matter since they get converted at .ace dump time.
# 2005 09 30
#
# Add alp_paper list.  
# Set to update values.  
# Added to cronjob weekly on Wednesdays at 3am    2005 11 10
#
# use app_paper instead of alp_paper.  2009 04 00
#
#
# Usage : ./find_merged_entries.pl
# Ouputs to logs/outfile.date  2005 11 10
#
# 0 3 * * wed /home/postgres/work/pgpopulation/update_wbpaper_merging/postgres_fixing/find_merged_entries.pl



use Jex;
use strict;
use LWP::Simple;
use DBI;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n";


my $date = &getSimpleSecDate();
my $outfile = '/home/postgres/work/pgpopulation/wpa_papers/update_wbpaper_merging/postgres_fixing/logs/outfile.' . $date;
open (OUT, ">$outfile") or die "Cannot create $outfile : $!";


my $file = get "http://tazendra.caltech.edu/~postgres/cgi-bin/merged_papers.cgi";
my %invalid_map;
my @lines = split/\n/, $file;
foreach my $line (@lines) {
  if ($line =~ m/^(\d{8})\tis now\t(.*)<BR>/) {
    my $old = 'WBPaper' . $1; my $new = 'WBPaper' . $2;
    $invalid_map{$old} = $new; }
} # foreach my $line (@lines)

# Uncomment these to test those tables
# $invalid_map{WBPaper00005937} = 'test_got_bio_paper_evidence_data';
# $invalid_map{WBPaper00001064} = 'test_car_seq_ref_reference_data';
# $invalid_map{WBPaper00025054} = 'test_car_con_ref_reference_data';


  # Concise description section, but don't need to update since they get
  # converted at .ace dump based on http://tazendra.caltech.edu/~acedb/paper2wbpaper.txt
my $car_no_order = 'car_con_ref_reference';
my $result = $dbh->prepare( "SELECT * FROM $car_no_order;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) { 
  if ($row[2]) {
    my @words = split/,\s+/, $row[1];
    foreach my $word (@words) {
      if ($invalid_map{$word}) { 
        my $new_row = $row[2]; $new_row =~ s/$word/$invalid_map{$word}/g;
        my $pgcommand = "UPDATE $car_no_order SET $car_no_order = '$new_row' WHERE $car_no_order = '$row[2]';";
        print OUT "$pgcommand\n";
        my $result2 = $dbh->do( "$pgcommand" );
        print OUT "$car_no_order\t$row[0]\t$row[1]\t$row[2]\t$invalid_map{$word}\n";
  } } }
} # while (my @row = $result->fetchrow) 
my @car_order_tables = qw( seq fpa fpi bio mol exp oth phe );
foreach my $car_order_table (@car_order_tables) {
  my $car_table = 'car_' . $car_order_table . '_ref_reference';
  my $result = $dbh->prepare( "SELECT * FROM $car_table;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) { 
    if ($row[2]) {
      my @words = split/,\s+/, $row[2];
      foreach my $word (@words) {
        if ($invalid_map{$word}) { 
          my $new_row = $row[2]; $new_row =~ s/$word/$invalid_map{$word}/g;
          my $pgcommand = "UPDATE $car_table SET $car_table = '$new_row' WHERE $car_table = '$row[2]';";
          print OUT "$pgcommand\n";
          my $result2 = $dbh->do( "$pgcommand" );
          print OUT "$car_table\t$row[0]\t$row[1]\t$row[2]\t$row[3]\t$invalid_map{$word}\n";
    } } }
  } # while (my @row = $result->fetchrow) 
} # foreach my $car_table (@car_order_tables)


  # Go curation section, finds but does not convert
my @got_tables = qw(bio mol cell);
foreach my $got_table (@got_tables) {
  $got_table = 'got_' . $got_table . '_paper_evidence';
  my $result = $dbh->prepare( "SELECT * FROM $got_table;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) { 
    if ($row[2]) {
      my @words = split/\s+/, $row[2];
      foreach my $word (@words) {
        if ($invalid_map{$word}) { 
          my $new_row = $row[2]; $new_row =~ s/$word/$invalid_map{$word}/g;
          my $pgcommand = "UPDATE $got_table SET $got_table = '$new_row' WHERE $got_table = '$row[2]';";
          print OUT "$pgcommand\n";
          my $result2 = $dbh->do( "$pgcommand" );
          print OUT "$got_table\t$row[0]\t$row[1]\t$row[2]\t$row[3]\t$invalid_map{$word}\n";
    } } }
  } # while (my @row = $result->fetchrow) 
} # foreach my $got_table (@got_tables)

  # Allele phenotype form
# my @alp_tables = qw(alp_paper);
# foreach my $alp_table (@alp_tables) {
#   my $result = $dbh->prepare( "SELECT * FROM $alp_table;" );
#   $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
#   while (my @row = $result->fetchrow) { 
#     if ($row[2]) {
#       my @words = split/\s+/, $row[2];
#       foreach my $word (@words) {
#         if ($invalid_map{$word}) { 
#           my $new_row = $row[2]; $new_row =~ s/$word/$invalid_map{$word}/g;
#           my $pgcommand = "UPDATE $alp_table SET $alp_table = '$new_row' WHERE $alp_table = '$row[2]';";
#           print OUT "$pgcommand\n";
#           my $result2 = $dbh->do( "$pgcommand" );
#           print OUT "$alp_table\t$row[0]\t$row[1]\t$row[2]\t$row[3]\t$invalid_map{$word}\n"; } } } } 
# } # foreach my $alp_table (@alp_tables)
my @app_tables = qw(app_paper);		# using app_ tables, haven't tested this change  2009 04 09
foreach my $app_table (@app_tables) {
  my $result = $dbh->prepare( "SELECT * FROM $app_table;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) { 
    if ($row[2]) {
      my @words = split/\s+/, $row[2];
      foreach my $word (@words) {
        if ($invalid_map{$word}) { 
          my $new_row = $row[2]; $new_row =~ s/$word/$invalid_map{$word}/g;
          my $pgcommand = "UPDATE $app_table SET $app_table = '$new_row' WHERE $app_table = '$row[2]';";
          print OUT "$pgcommand\n";
          my $result2 = $dbh->do( "$pgcommand" );
          print OUT "$app_table\t$row[0]\t$row[1]\t$row[2]\t$row[3]\t$invalid_map{$word}\n"; } } } } 
} # foreach my $app_table (@app_tables)

close (OUT) or die "Cannot close $outfile : $!";

__END__

my $infile = 'wbpaper.ace';
open (IN, "<$infile") or die "Cannot open $infile : $!";
my $outfile = 'merged_papers.ace';
open (OUT, ">$outfile") or die "cannot create $outfile : $!";

my $start = &getSimpleSecDate();
my $stime = time;
print OUT "// START $start $stime START\n";
print STDERR "START $start estimate + 4mins, 20sec\n";

my %data_hash;

$/ = "";
while (my $paragraph = <IN>) {
  foreach my $inv_paper (sort keys %invalid_map) {
#     $inv_paper = 'WBPaper' . $inv_paper;
    if ($paragraph =~ m/WBPaper$inv_paper/) { 
      my @lines = split/\n/, $paragraph;
      my $header = shift @lines;
      my $curator = '';
      if ($header =~ m/WBPaper$inv_paper/) {
        if ($header =~ m/_([^_]*?)\"$/) { $curator = $1; }
#         print OUT "$curator\t$header KEY $inv_paper NOW $invalid_map{$inv_paper}\n\n"; 
#        push @{ $data_hash{$curator} }, "$header HEADER KEY $inv_paper NOW $invalid_map{$inv_paper}\n\n"; 	# skip Object with WBPaper in header since it should be already moved
      }
      else {
# Abstract         -O "2005-02-11_14:19:12_eimear" "WBPaper00024932" -O "2005-02-11_14:19:12_eimear"
#         print OUT "$header\n";
        foreach my $line (@lines) {
          if ($line =~ m/WBPaper$inv_paper/) { 
            if ($line =~ m/_([^_]*?)\"$/) { $curator = $1; }
            if ($line =~ m/Old_WBPaper/) { next; }					# skip Old_WBPaper since it refers to itself
            if ($header =~ m/Author/) { next; }						# skip Author since new paper already has authors 
#             print OUT "$curator\t$line NOW $invalid_map{$inv_paper}\n"; 
            if ($header =~ m/\-O \"[^\"]*\"/) { $header =~ s/\-O \"[^\"]*\"//g; }		# filter out timestamps
            if ($line =~ m/\-O \"[^\"]*\"/) { $line =~ s/\-O \"[^\"]*\"//g; }		# filter out timestamps
#             push @{ $data_hash{$curator} }, "$header\n$line KEY $inv_paper NOW $invalid_map{$inv_paper}\n\n";	# show message of what's there and what should change
            push @{ $data_hash{$curator} }, "$header\n-D $line\n\n";  			# show message of what's there and what should change
            $line =~ s/$inv_paper/$invalid_map{$inv_paper}/g;				# switch papers
            push @{ $data_hash{$curator} }, "$header\n$line\n\n";  			# show message of what's there and what should change
          } # if ($line =~ m/WBPaper$inv_paper/) 
        } # foreach my $line (@lines)
#         print OUT "\n";
      }
    } # if ($paragraph =~ m/WBPaper/) 
  } # foreach my $file (@flatfiles)
} # while (my $paragraph = <IN>)
close (IN) or die "Cannot close $infile : $!";


foreach my $curator (sort keys %data_hash) {
  print OUT "// START $curator\n";
  foreach my $line (@{ $data_hash{$curator} }) {
    print OUT $line;
  } # foreach my $line (@{ $data_hash{$curator} })
  print OUT "\n";
} # foreach my $curator (sort keys %data_hash)

my $end = &getSimpleSecDate();
my $etime = time;
my $diff = $etime - $stime;
print OUT "// END $end $etime $diff END\n";

close (OUT) or die "Cannot close $outfile : $!";

`mv merged_papers.cgi merged_papers.cgi.$start`;

