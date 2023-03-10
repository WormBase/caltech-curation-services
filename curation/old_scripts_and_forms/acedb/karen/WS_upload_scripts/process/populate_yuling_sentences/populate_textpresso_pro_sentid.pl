#!/usr/bin/perl -w

# populate sentid tables for process curation.  obo_name_prosentid, obo_data_prosentid, obo_syn_prosentid,
# pro_curator, pro_sentid from yuling's file at http://131.215.52.209/karen/rank_paper_fullpaper_filtered.
# 2012 09 21


use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );
use LWP::Simple;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

# my $directory = '/home/postgres/work/pgpopulation/pro_process/20120921_sentid_falsepositive_oboprosentid';
# chdir($directory) or die "Cannot go to $directory ($!)";

my @del_pgcommands;
my @obo_pgcommands;
my @pro_pgcommands;

my %obo_sentid;

$result = $dbh->prepare( " SELECT * FROM obo_name_prosentid; " );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { if ($row[1]) { $obo_sentid{$row[1]}++; } }

my $joinkey = '1';
$result = $dbh->prepare( " SELECT * FROM pro_curator ORDER BY joinkey::integer DESC; " );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
my @row = $result->fetchrow();
if ($row[0]) { $joinkey = $row[0]; } 
  else { die "ERROR no starting joinkey from pro_curator to populate pro_ tables\n"; }

# uncomment to delete data entered after timestamp to those tables
# push @del_pgcommands, "DELETE FROM obo_name_prosentid WHERE obo_timestamp > '2012-09-21';";
# push @del_pgcommands, "DELETE FROM obo_data_prosentid WHERE obo_timestamp > '2012-09-21';";
# push @del_pgcommands, "DELETE FROM obo_syn_prosentid  WHERE obo_timestamp > '2012-09-21';";
# push @del_pgcommands, "DELETE FROM pro_sentid         WHERE pro_timestamp > '2012-09-21';";
# push @del_pgcommands, "DELETE FROM pro_curator        WHERE pro_timestamp > '2012-09-21';";
# push @del_pgcommands, "DELETE FROM pro_paper          WHERE pro_timestamp > '2012-09-21';";

my $url = 'http://131.215.52.209/karen/rank_paper_fullpaper_filtered';
my $data = get $url;

my %fileData;
my (@lines) = split/\n/, $data;
foreach my $line (@lines) {
  my ($papId, $molId, $molname, $section, $sent) = split/\t/, $line;
  my $key = $molId . ':' . $papId;
  next if ($obo_sentid{$key});
  $fileData{$key}{syn} = lc($molname);
  my $line = "$section : $sent";
  $fileData{$key}{lines}{$line}++;
}

foreach my $key (sort keys %fileData) {
  my $sentences = join"\n", sort keys %{ $fileData{$key}{lines} };
  my $paper = '';
  if ($key =~ m/(WBPaper\d+)/) { $paper = $1; }
  my $termInfo  = "sentence ID : $key\n";
  $termInfo    .= "synonym : $fileData{$key}{syn}\n";
  $termInfo    .= "$sentences";
#   print "$key -- $termInfo\n\n";
  $termInfo =~ s/\'/''/g;
  push @obo_pgcommands, "INSERT INTO obo_name_prosentid VALUES ('$key', '$key');";
  push @obo_pgcommands, "INSERT INTO obo_syn_prosentid  VALUES ('$key', '$fileData{$key}{syn}');";
  push @obo_pgcommands, "INSERT INTO obo_data_prosentid VALUES ('$key', E'$termInfo');";
  $joinkey++;
    # pro_ data goes in in reverse so that when queried by reverse timestamp they'll be in order.  joinkeys are still assigned in sentence order so that later queries by pgid would have them in order.
  if ($paper) { 
    unshift @pro_pgcommands, "INSERT INTO pro_paper VALUES ('$joinkey', '$paper');";
    unshift @pro_pgcommands, "INSERT INTO pro_paper_hst VALUES ('$joinkey', '$paper');"; }
  unshift @pro_pgcommands, "INSERT INTO pro_curator VALUES ('$joinkey', 'WBPerson11187');";
  unshift @pro_pgcommands, "INSERT INTO pro_curator_hst VALUES ('$joinkey', 'WBPerson11187');";
  unshift @pro_pgcommands, "INSERT INTO pro_sentid VALUES ('$joinkey', '$key');";
  unshift @pro_pgcommands, "INSERT INTO pro_sentid_hst VALUES ('$joinkey', '$key');";
} # foreach my $key (reverse sort keys %fileData)

foreach my $command (@del_pgcommands, @obo_pgcommands, @pro_pgcommands) {
  print "$command\n";
# UNCOMMENT TO POPULATE
  $dbh->do( $command );
}

__END__

open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) {
  chomp $line;
  my ($a, $sid, $b, $c, $sentence) = split/\t/, $line;
  unless ($sid) { print "ERROR, no sentence ID for $line\n"; }
  unless ($sentence) { print "ERROR, no sentence data for $line\n"; }
  next unless ($sid || $sentence);
  if ($sid =~ m/\'/) { $sid =~ s/\'//g; }			# strip any ' from sentence ID (shouldn't be any)
  next if ($obo_sentid{$sid});					# skip sentence IDs that have already been read
  if ($sentence =~ m/\'/) { $sentence =~ s/\'/''/g; }		# escape ' from sentence
  foreach my $tag (sort keys %colorMap) {
    if ($sentence =~ m/<$tag>/) { 
      $sentence =~ s/<$tag>/<span style=\"color: $colorMap{$tag};\">/g;
      $sentence =~ s/<\/$tag>/<\/span>/g; } }
  push @obo_pgcommands, "INSERT INTO obo_name_int_sentid VALUES ('$sid', '$sid');";
  push @obo_pgcommands, "INSERT INTO obo_data_int_sentid VALUES ('$sid', 'sentence ID : $sid\nsentence data : $sentence');";
  $joinkey++;
    # int_ data goes in in reverse so that when queried by reverse timestamp they'll be in order.  joinkeys are still assigned in sentence order so that later queries by pgid would have them in order.
  unshift @int_pgcommands, "INSERT INTO int_sentid VALUES ('$joinkey', '$sid');";
  unshift @int_pgcommands, "INSERT INTO int_curator VALUES ('$joinkey', 'WBPerson4793');";
} # while (my $line = <IN>)
close (IN) or die "Cannot close $infile : $!";

foreach my $command (@del_pgcommands, @obo_pgcommands, @int_pgcommands) {
  print "$command\n";
  $dbh->do( $command );
}


__END__

WBPaper00038322	D009638	norepinephrine	body	Amino acids arginine histidine lysine aspartic acid glutamic acid serine threonine asparagine glutamine alanine isoleucine leucine methionine phenylalanine tryptophan tyrosine valine cysteine glycine proline Neurotransmitters acetylcholine GABA nitric oxide serotonin dopamine glutamic acid octapamine tyramine epinephrine norepinephrine histamine neuropeptides[b]C.elegans E E E NE NE NE E NE NE NE E E E E E NE E NE NE NE Used in C.elegans?
WBPaper00038322	D008795	metric	body	Metabolic rate is an important physiological metric.
WBPaper00038322	D002241	sugars	body	Over time,the modified sugars are incorporated into glycoproteins.
WBPaper00038322	D002241	sugars	body	The work of Bertozzi and coworkers using a combination of modified sugars and click chemistry to label glycans is an excellent example of how chemistry can be utilized for worm biology.
