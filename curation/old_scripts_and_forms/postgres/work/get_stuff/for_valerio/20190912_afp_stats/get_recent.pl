#!/usr/bin/perl -w

# todo
# times an author modified a submission for any given paper-table.
# times an author modified a whole submission across all tables.  look at history of lasttouched.
# average time between submissions or changes. 
# diffence in times for new pipeline across different tables.

# for any given datatype-paper, get the amount of different data, and the longest timespan across all timestamps.  2019 09 12

# For any paper, across all datatypes, the maximum time apart between first and last curation, and the gaps in seconds between any entries.  2019 09 13


use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );
use Time::Local;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my @datatypes = qw( ablationdata additionalexpr antibody authors catalyticact celegans cellfunc chemicals chemphen cnonbristol comment covalent domanal email envpheno expression extvariation funccomp genefunc geneint geneprod genereg genestudied genesymbol gocuration humdis invitro lasttouched lsrnai mappingdata marker massspec matrices microarray mosaic nematode newbalancers newcell newmutant newprotein newsnp newstrains nocuratable nonnematode otherantibody otherexpr othersilico otherstrain othertransgene othervariation overexpr passwd phylogenetic processed review rnai rnaseq seqchange seqfeat siteaction species strain structcorr structinfo supplemental timeaction transgene variation version );
# my @datatypes = qw( ablationdata  );

# SELECT joinkey, COUNT(*) AS count FROM afp_genestudied_hst  WHERE afp_approve IS NULL GROUP BY joinkey HAVING COUNT(*) > 1 ORDER BY count DESC;


my %hash;
foreach my $datatype (@datatypes) {
  next if ($datatype eq 'lasttouched');
  next if ($datatype eq 'email');
  next if ($datatype eq 'passwd');
  $result = $dbh->prepare( "SELECT * FROM afp_${datatype}_hst WHERE joinkey != '00000003'" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    if ($row[0]) { 
      next if ($row[4]);
      my ($year, $month, $day, $hour, $minute, $second) = $row[2] =~ m/^(\d+)\-(\d+)\-(\d+) (\d+):(\d+):(\d+)/;
      my $time = timelocal($second,$minute,$hour,$day,$month-1,$year);
      $hash{datatype}{$datatype}{$row[0]}{$row[1]}{$time}++;
# print qq(D $datatype P $row[0] D $row[1] T $time \n);
      $hash{paper}{$row[0]}{$datatype}{$row[1]}{$time}++;
# if ($row[0] eq '00032358') {
#         print "$row[0]\t$row[1]\t$time\n";
# }
    } # if ($row[0])
  } # while (@row = $result->fetchrow)
}

# for new afp version, for any given paper, get max time difference between entries and timestamp difference across all entries
  $result = $dbh->prepare( "SELECT * FROM afp_version WHERE afp_version = '2' ORDER BY joinkey" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
    my $paper = $row[0];
    my $lowest = 0;
    my $highest = 0;
    my %ts;
# if ($paper eq '00048862') { print qq(ONE\n); }
    foreach my $datatype (sort keys %{ $hash{paper}{$paper} }) {
# if ($paper eq '00048862') { print qq(TWO\n); }
      foreach my $data (sort keys %{ $hash{paper}{$paper}{$datatype} }) {
# if ($paper eq '00048862') { print qq(THR\n); }
        foreach my $ts (sort keys %{ $hash{paper}{$paper}{$datatype}{$data} }) {
# if ($paper eq '00048862') { print qq(FOUR\n); }
# if ($paper eq '00048862') { print qq(D $datatype D $data T $ts P $paper\n); }
# print qq(D $datatype D $data T $ts P $paper\n);
          $ts{$ts}++;
          if ($lowest == 0) { $lowest = $ts; }
          if ($ts < $lowest) { $lowest = $ts; }
          if ($ts > $highest) { $highest = $ts; }
# if ($paper eq '00048862') { print qq(lowest $lowest H $highest\n); }
        } # foreach my $ts (sort keys %{ $hash{paper}{$paper}{$datatype}{$data} })
      } # foreach my $data (sort keys %{ $hash{paper}{$paper}{$datatype} })
    } # foreach my $datatype (sort keys %{ $hash{paper}{$paper} })
    my $diffTime = $highest - $lowest;
    my @apart;
    foreach my $ts (sort keys %ts) {
      my $apart = $ts - $lowest; 
      if ($apart > 0) { push @apart, $apart; }
    } # foreach my $ts (sort keys %ts)
    my $apart = join" ", @apart;
    if ($diffTime > 0) {
      print qq($paper\t$diffTime seconds apart\t$apart\n);
    }
  }

__END__

# for each datatype-paper, get count of changes and largest time gap between them
foreach my $datatype (sort keys %{ $hash{datatype} }) {
  foreach my $paper (sort keys %{ $hash{datatype}{$datatype} }) {
    if (scalar keys %{ $hash{datatype}{$datatype}{$paper} } > 1) {
      my $count = scalar keys %{ $hash{datatype}{$datatype}{$paper} };
      my $lowest = 0;
      my $highest = 0;
      foreach my $data (sort keys %{ $hash{datatype}{$datatype}{$paper} }) {
        foreach my $ts (sort keys %{ $hash{datatype}{$datatype}{$paper}{$data} }) {
          if ($lowest == 0) { $lowest = $ts; }
          if ($ts < $lowest) { $lowest = $ts; }
          if ($ts > $highest) { $highest = $ts; }
        }
      }
      my $diffTime = $highest - $lowest;
      if ($diffTime > 0) {
        print qq($datatype\t$paper\t$count changes\t$diffTime seconds apart\n);
      }
} } } 
      

__END__
