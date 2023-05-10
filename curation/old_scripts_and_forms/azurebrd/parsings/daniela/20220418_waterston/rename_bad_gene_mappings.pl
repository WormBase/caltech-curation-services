#!/usr/bin/perl -w

# WBPerson1562 sent bad data, files were named with <gin_name>_<wbgene_id>_<stuff>.jpg but the gin_name
# was correct and the wbgene_id was sometimes wrong.  This maps gin_name to correct WBGeneID, then 
# compares to file wbgene_id and outputs what needs renaming.  pals-35 doesn't map to a WBGene in postgres.
# Later can create a -D for Name from paker.ace for the Picture objects to replace the -D Name with the 
# correct Name.  Then on canopus /home/daniela/OICR/Pictures/WBPerson1562/ rename the .jpg files.
# for Daniela.  2023 04 27 


use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

$/ = "";
my %nameToExpr;
my %nameToPic;
my $source_ace = 'paker.ace';
open (IN, "<$source_ace") or die "Cannot open $source_ace : $!";
while (my $para = <IN>) {
  my (@lines) = split/\n/, $para;
  my ($picId) = $lines[0] =~ m/Picture : (WBPicture\d+)/;
  my $name = ''; my $expr = '';
  foreach my $line (@lines) {
    if ($line =~ m/Name\s+"(.*?)"/) { $name = $1; }
    if ($line =~ m/Expr_pattern\s+"(.*?)"/) { $expr = $1; }
  } # foreach my $line (@lines)
  if ($picId) {
    if ($name) { $nameToPic{$name} = $picId; }
      else { print qq($picId has no name\n); }
    if ($name) { $nameToExpr{$name} = $expr; }
      else { print qq($picId has no expr\n); } }
} # while (my $para = <IN>)
close (IN) or die "Cannot close $source_ace : $!";
$/ = "\n";

# foreach my $name (sort keys %nameToPic) {
#   my $picId = $nameToPic{$name};
#   print qq($name\t$picId\n);
# }
# foreach my $name (sort keys %nameToExpr) {
#   my $expr = $nameToExpr{$name};
#   print qq($name\t$expr\n);
# }


my %ginNames;
my @tables = qw( gin_seqname gin_synonyms gin_locus );	# loop through all prioritize gin_name by putting last
foreach my $table (@tables) {
  my $result = $dbh->prepare( "SELECT * FROM $table" );
  $result->execute();
  while (my @row = $result->fetchrow) { $ginNames{$row[1]} = "WBGene$row[0]"; } }

my @names;
my @infiles = qw( embryolist lineagelist );
foreach my $infile (@infiles) {
  open (IN, "<$infile") or die "Cannot open $infile : $!";
  while (my $line = <IN>) {
    chomp $line;
    push @names, $line;
  }
  close (IN) or die "Cannot close $infile : $!";
} # foreach my $infile (@infiles)

my $output_move = 'move_script.sh';	# run in canopus at /home/daniela/OICR/Pictures/WBPerson1562/ to rename files
my $output_ace = 'fix_genes.ace';
open (MVE, ">$output_move") or die "Cannot create $output_move : $!";
open (ACE, ">$output_ace") or die "Cannot create $output_ace : $!";
foreach my $name (@names) {
  # 2L52.1_WBGene00007063_embryo_terminal.jpg
  my ($gin, $wbg) = $name =~ m/^(.+)_(WBGene[^_]+)_/;
  print qq($gin\t$wbg\n);
  if ($ginNames{$gin}) {
      my $correctWbg = $ginNames{$gin};
      if ($correctWbg ne $wbg) {
        print qq(RENAME\t$name\t$gin\t$wbg\tTO\t$correctWbg\n);
        my $newName = $name;
        $newName =~ s/$wbg/$correctWbg/;
        print MVE qq(mv $name $newName\n);
        print ACE qq(Picture : $nameToPic{$name}\n);
        print ACE qq(-D Name\t"$name"\n);
        print ACE qq(Name\t"$newName"\n);
        print ACE qq(\n);
        print ACE qq(Expr_pattern : $nameToExpr{$name}\n);
        print ACE qq(-D Gene\t"$wbg"\n);
        print ACE qq(-D Reflects_endogenous_expression_of\t"$wbg"\n);
        print ACE qq(Gene\t"$correctWbg"\n);
        print ACE qq(Reflects_endogenous_expression_of\t"$correctWbg"\n);
        print ACE qq(\n);
# RENAME  ztf-1_WBGene00020763_embryo_lineage.jpg ztf-1   WBGene00020763  TO      WBGene00018833
      }
    }
    else { print qq($gin\t$wbg\tDOES NOT MATCH postgres $name\n); }

}
close (ACE) or die "Cannot close $output_ace : $!";
close (MVE) or die "Cannot close $output_move : $!";

__END__

$result = $dbh->prepare( "SELECT * FROM two_comment" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[1] =~ s///g;
    $row[2] =~ s///g;
    print "$row[0]\t$row[1]\t$row[2]\n";
  } # if ($row[0])
} # while (@row = $result->fetchrow)

__END__

