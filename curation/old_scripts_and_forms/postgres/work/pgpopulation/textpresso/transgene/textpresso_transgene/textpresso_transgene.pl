#!/usr/bin/perl -w

# look at textpresso transgene data and update postgres based on that.  
# 2008 10 07
#
# wasn't checking regular names, oops.  2008 10 20
#
#
# update postgres based on value, cron job 
# 0 2 * * mon /home/postgres/work/pgpopulation/transgene/textpresso_transgene/textpresso_transgene.pl
# 2008 10 14
#
# run every day  2009 02 23
# 0 2 * * * /home/postgres/work/pgpopulation/transgene/textpresso_transgene/textpresso_transgene.pl

use LWP::Simple;
use strict;
use diagnostics;
use Pg;
use Jex;

my $directory = '/home/postgres/work/pgpopulation/transgene/textpresso_transgene';
chdir($directory) or die "Cannot go to $directory ($!)";

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $date = &getSimpleSecDate();

my $outfile = 'transgene_textpresso';
my $outfile2 = 'new_transgene_textpresso';
my $outfile3 = 'transgene_textpresso.pg';
open (OUT, ">>$outfile") or die "Cannot create $outfile : $!";
open (OU2, ">>$outfile2") or die "Cannot create $outfile2 : $!";
open (OU3, ">>$outfile3") or die "Cannot create $outfile3 : $!";

my %syns;
my %valid;
my $result = $conn->exec( "SELECT trp_name.trp_name, trp_synonym.trp_synonym FROM trp_name, trp_synonym WHERE trp_name.joinkey = trp_synonym.joinkey;" );
while (my @row = $result->fetchrow) { 
  my (@syns) = split/ \| /, $row[1];
  $valid{$row[0]}++;
  foreach my $syn (@syns) {
    $valid{$syn}++;
    $syns{$syn} = $row[0]; } }
$result = $conn->exec( "SELECT trp_name FROM trp_name;" );
while (my @row = $result->fetchrow) { $valid{$row[0]}++; }

my %obs;
my $infile = '/home/acedb/wen/phenote_transgene/ObsoleteTg.txt';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) {
  chomp $line;
  next unless $line;
  next if ($line =~ m/^\/\//);
#   my ($tg, $paper, $comment) = split/\t/, $line;	# wen keeps forgetting tabs
  my ($tg, $paper);
  if ($line =~ m/^(\S+)\s+(\S+)/) { $tg = $1; $paper = $2; }
  $tg =~ s/\s+//g;
  unless ($paper) { $paper = 'all'; }
  $obs{$tg}{$paper}++;
#   print "OBS $tg PAP $paper E\n";
} # while (my $line = <IN>) {
close (IN) or die "Cannot close $infile : $!";

my %tdata;
my $tdata = get "http://textpresso-dev.caltech.edu/wen/transgenes_in_regular_papers.out";
my (@lines) = split/\n/, $tdata;
foreach my $line (@lines) {
  chomp $line;
  my ($paper, $tg) = split/  /, $line;
  ($paper) = $paper =~ m/(WBPaper\d+)/;
  unless ($tg) { print "NO TG $line\n"; }
  my (@tg) = split/\s/, $tg;
  foreach my $tg (@tg) { 
# this is wrong, I thought she wanted to create new synonym objects, which made no sense
#     if ($syns{$tg}) { foreach my $syn (keys %{ $syns{$tg} }) { $tdata{$syn}{$paper}++; } }
    if ($syns{$tg}) { $tg = $syns{$tg}; }
    next if ($obs{$tg}{'all'});
    next if ($obs{$tg}{$paper});
#     print "TG $tg PAP $paper E\n";
    $tdata{$tg}{$paper}++; 
  }
} # foreach my $line (@lines)

my %pdata;
$result = $conn->exec( "SELECT trp_name.trp_name, trp_reference.trp_reference FROM trp_name, trp_reference WHERE trp_name.joinkey = trp_reference.joinkey;" );
while (my @row = $result->fetchrow) { 
  my $tg = $row[0];
  my (@papers) = split/ | /, $row[1];
  foreach my $paper (@papers) { delete $tdata{$tg}{$paper}; } }

foreach my $tg (sort keys %tdata) {
  my (@papers) = sort keys %{ $tdata{$tg} };
  my $papers = join" | ", @papers;
  if ($papers) {
    if ($valid{$tg}) { &addToTg($tg, $papers, $date ); }
      elsif ($tg =~ m/In/) { print OU2 "$date new $tg in $papers\n"; }
      else { &newTg($tg, $papers, $date ); }
  } # if ($papers)
} # foreach my $paper (sort keys %tdata)

close (OU3) or die "Cannot close $outfile3 : $!";
close (OU2) or die "Cannot close $outfile2 : $!";
close (OUT) or die "Cannot close $outfile : $!";

sub addToTg {
  my ($tg, $papers, $date) = @_;
  print OUT "$date more papers $tg in $papers\n"; 
  my %joinkeys;					# get all joinkeys that refer to this Tg
  my $result = $conn->exec( "SELECT * FROM trp_name WHERE trp_name = '$tg';" );
  while (my @row = $result->fetchrow) { $joinkeys{$row[0]}++; }
  foreach my $joinkey (keys %joinkeys) {	# for all joinkeys of that Tg
    $result = $conn->exec( "SELECT trp_reference FROM trp_reference WHERE joinkey = '$joinkey';" );
    my @row = $result->fetchrow;
    if ($row[0]) { 				# if there's a reference, append it
      $papers = "$row[0] | $papers"; 
      my $command = "UPDATE trp_reference SET trp_reference = '$papers' WHERE joinkey = '$joinkey';";
      print OU3 "$command -- $date\n";
      my $result2 = $conn->exec( $command );
    } else {					# if new reference, add it
      my $command = "INSERT INTO trp_reference VALUES ('$joinkey', '$papers');";
      print OU3 "$command -- $date\n";
      my $result2 = $conn->exec( $command );
    }
    my $command = "INSERT INTO trp_reference_hst VALUES ('$joinkey', '$papers');";
    print OU3 "$command -- $date\n";
    my $result2 = $conn->exec( $command );
  } # foreach my $joinkey (keys %joinkeys)
} # sub addToTg

sub newTg {
  my ($tg, $papers, $date) = @_;
  my $joinkey = 0;
  my $result = $conn->exec( "SELECT * FROM trp_name;" );
  while (my @row = $result->fetchrow) { if ($row[0] > $joinkey) { $joinkey = $row[0]; } }
  $joinkey++;
  print OUT "$date new $tg in $papers\n"; 
  my $command = "INSERT INTO trp_name VALUES ('$joinkey', '$tg');";
  print OU3 "$command -- $date\n";
  my $result2 = $conn->exec( $command );
  $command = "INSERT INTO trp_name_hst VALUES ('$joinkey', '$tg');";
  print OU3 "$command -- $date\n";
  $result2 = $conn->exec( $command );
  $command = "INSERT INTO trp_reference VALUES ('$joinkey', '$papers');";
  print OU3 "$command -- $date\n";
  $result2 = $conn->exec( $command );
  $command = "INSERT INTO trp_reference_hst VALUES ('$joinkey', '$papers');";
  print OU3 "$command -- $date\n";
  $result2 = $conn->exec( $command );
} # sub newTg

__END__

