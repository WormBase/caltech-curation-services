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

foreach my $name (@names) {
  # 2L52.1_WBGene00007063_embryo_terminal.jpg
  my ($gin, $wbg) = $name =~ m/^(.+)_(WBGene[^_]+)_/;
  print qq($gin\t$wbg\n);
  if ($ginNames{$gin}) {
      my $correctWbg = $ginNames{$gin};
      if ($correctWbg ne $wbg) {
        print qq(RENAME\t$name\t$gin\t$wbg\tTO\t$correctWbg\n);
      }
    }
    else { print qq($gin\t$wbg\tDOES NOT MATCH postgres $name\n); }

}

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

