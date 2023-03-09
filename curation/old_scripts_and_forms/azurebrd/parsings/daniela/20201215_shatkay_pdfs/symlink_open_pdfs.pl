#!/usr/bin/perl -w

# take a sample of WBPaperIDs that should be open access, and symlink the most recent PDF to a directory for Shatkay's group to download.
# 2020 12 15


use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %pap;
$pap{'00059745'}{'pmc'}++;
$pap{'00059750'}{'pmc'}++;
$pap{'00059759'}{'pmc'}++;
$pap{'00059836'}{'pmc'}++;
$pap{'00059841'}{'pmc'}++;
$pap{'00059848'}{'pmc'}++;
$pap{'00059863'}{'pmc'}++;
$pap{'00059878'}{'pmc'}++;
$pap{'00059884'}{'pmc'}++;
$pap{'00059887'}{'pmc'}++;

my $infile = 'out_positives.csv';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) {
  chomp $line;
  my @line = split/,/, $line;
  if ($line[1] =~ m/^PMC\d+/) { $pap{'positive'}{"pmid$line[0]"}++; }
# 19667176,PMC2731839
# 19675127,PMC2730362
} # while (my $line = <IN>)
close (IN) or die "Cannot close $infile : $!";

$infile = 'out_negatives.csv';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) {
  chomp $line;
  my @line = split/,/, $line;
  if ($line[1] =~ m/^PMC\d+/) { $pap{'negative'}{"pmid$line[0]"}++; }
} # while (my $line = <IN>)
close (IN) or die "Cannot close $infile : $!";


$result = $dbh->prepare( "SELECT * FROM pap_identifier WHERE pap_identifier ~ 'pmid'" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
#   if ($row[0]) { if ($pap{$row[0]}{pmc}) { $pap{$row[0]}{pmid} = $row[1]; } } 
  if ($row[0]) { $pap{pmidToPap}{$row[1]} = $row[0]; }
}

$result = $dbh->prepare( "SELECT * FROM pap_electronic_path WHERE pap_electronic_path ~ 'pdf' ORDER BY pap_timestamp DESC;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $pap{path}{$row[0]} = $row[1]; }
}

my $folder = "/home/azurebrd/public_html/var/work/for_daniela/pdfs/";

foreach my $pmid (sort keys %{ $pap{'positive'} }) {
  my $joinkey = $pap{pmidToPap}{$pmid};
  my $path = $pap{path}{$joinkey};
  print qq($joinkey\t$pmid\t$path\n);
  my $html_path = $folder . 'positives/' . $pmid . '.pdf';
  unless (-l $html_path) {
    symlink($path, $html_path) or warn "cannot symlink $path to $html_path"; }
} # foreach my $joinkey (sort keys %pap)

foreach my $pmid (sort keys %{ $pap{'negative'} }) {
  my $joinkey = $pap{pmidToPap}{$pmid};
  my $path = $pap{path}{$joinkey};
  print qq($joinkey\t$pmid\t$path\n);
  my $html_path = $folder . 'negatives/' . $pmid . '.pdf';
  unless (-l $html_path) {
    symlink($path, $html_path) or warn "cannot symlink $path to $html_path"; }
} # foreach my $joinkey (sort keys %pap)


# foreach my $joinkey (sort keys %pap) {
#   if ($pap{$joinkey}{pmc}) {
#     my $pmid = $pap{$joinkey}{pmid};
#     my $path = $pap{$joinkey}{path};
#     print qq($joinkey\t$pmid\t$path\n);
#     my $html_path = $folder . $pmid . '.pdf';
#     unless (-l $html_path) {
#       symlink($path, $html_path) or warn "cannot symlink $path to $html_path"; }
#   }
# } # foreach my $joinkey (sort keys %pap)


__END__

59745	32467239
59750	32656508
59759	32490809
59836	32559444
59841	32555288
59848	32513699
59863	32518061
59878	32576621
59884	32587090
59887	32586975
