#!/usr/bin/perl -w

# update cur_transgene based on textpresso data for Andrei.
#
# run every sunday after Arun runs his script on Saturday.  2008 06 27
#
# run every day after Arun runs his script on Saturday.  for Karen.  2009 02 20
#
# 0 4 * * * /home/postgres/work/pgpopulation/textpresso/transgene/update_textpreso_cur_transgene.pl

use strict;
use diagnostics;
use Pg;
use LWP::Simple;
use Jex;

my $date = &getSimpleDate();
my $timestamp = &getSimpleSecDate();

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $directory = '/home/postgres/work/pgpopulation/textpresso/transgene';
chdir($directory) or die "Cannot go to $directory ($!)";

my %full_lines;
my $full_file = 'full_transgenes_textpresso';
open (IN, "<$full_file") or die "Cannot open $full_file : $!";
while (my $line = <IN>) { chomp $line; $full_lines{$line}++; } 
close (IN) or die "Cannot close $full_file : $!";

open (OUT, ">>$full_file") or die "Cannot open $full_file : $!";

my $log_file = "logfile.$timestamp";
open (LOG, ">$log_file") or die "Cannot create $log_file : $!";

my $tfile = get "http://textpresso-dev.caltech.edu/wen/transgenes_in_regular_papers.out";
my %tdata;
my (@tlines) = split/\n/, $tfile;
foreach my $line (@tlines) {
  next if ($full_lines{$line});
  print OUT "$line\n";
  my ($paper, @transgene) = split/\s+/, $line;
  if ($paper =~ m/(WBPaper\d+)/) { $paper = $1; }
  my ($joinkey) = $paper =~ m/WBPaper(\d+)/;
  &append($joinkey, $line);
#   foreach my $tran (@transgene) {
#     next if ($obs{$paper}{$tran});			# do this for Wen, not Andrei
#     if ($syn{$tran}) { $tran = $syn{$tran}; }		# do this for Wen, not Andrei
#     $tdata{$paper}{$tran}++;
#   } # foreach my $tran (@transgene)
} # foreach my $line (@tlines)

close (OUT) or die "Cannot close $full_file : $!";
close (LOG) or die "Cannot close $log_file : $!";

sub append {
  my ($joinkey, $line) = @_;
  print LOG "Add $joinkey $line\n";
  my $result = $conn->exec( "SELECT * FROM cur_transgene WHERE joinkey = '$joinkey';" );
  my @row = $result->fetchrow();
  $line = "Textpresso : $line -- $date ...";
  my $command = '';
  if ($row[0]) {		# line exists in postgres
    my $data = $row[1]; 
    if ($data) { $data .= "\n"; }
    $data .= $line;
    $command = "UPDATE cur_transgene SET cur_transgene = '$data' WHERE joinkey = '$joinkey';";
  } else {			# new line in postgres
    $command = "INSERT INTO cur_transgene VALUES ('$joinkey', '$line');";
  }
  print LOG "$command\n";
  $result = $conn->exec( $command );
} # sub append


__END__

