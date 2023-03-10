#!/usr/bin/perl -w

# compare trp_publicname with data from Mary Ann.  add to trp_ tables any new entries, 
# tell Karen about entries that already existed.
# live run on tazendra same day.  2013 02 07

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;


my %genes;
$result = $dbh->prepare( "SELECT * FROM gin_seqname" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) { $genes{$row[1]} = 'WBGene' . $row[0]; }
$result = $dbh->prepare( "SELECT * FROM gin_synonyms" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) { $genes{$row[1]} = 'WBGene' . $row[0]; }
$result = $dbh->prepare( "SELECT * FROM gin_locus " );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) { $genes{$row[1]} = 'WBGene' . $row[0]; }

$genes{"cat-4 | gcy-7"}  = 'WBGene00001534","WBGene00000298';
$genes{"ceh-36 | gcy-7"} = 'WBGene00000457","WBGene00001534';
$genes{"aex-3|tnt-4"}    = 'WBGene00000086","WBGene00006589';
$genes{"ast-1(+)"}       = 'WBGene00020368';
$genes{"C05D10.1B"}      = 'WBGene00015477';

my %chromosomes;
$chromosomes{"I"}   = "I";
$chromosomes{"II"}  = "II";
$chromosomes{"III"} = "III";
$chromosomes{"IV"}  = "IV";
$chromosomes{"V"}   = "V";
$chromosomes{"X"}   = "X";

my %repprod;
$repprod{"GFP"}           = "GFP";
$repprod{"YFP"}           = "YFP";
$repprod{"CFP"}           = "CFP";
$repprod{"LacZ"}          = "LacZ";
$repprod{"mCherry"}       = "mCherry";
$repprod{"DsRed"}         = "DsRed";
$repprod{"DsRed2"}        = "DsRed2";
$repprod{"Venus"}         = "Venus";
$repprod{"tdimer2(12)"}   = "tdimer2(12)";
$repprod{"RFP"}           = "RFP";



my %nameToPgid;
$result = $dbh->prepare( "SELECT * FROM trp_publicname" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $nameToPgid{$row[1]} = $row[0]; } }

my $pgid = 0;
my @highestPgidTables = qw( name curator );
foreach my $table (@highestPgidTables) { 
  $result = $dbh->prepare( "SELECT * FROM trp_$table ORDER BY joinkey::INTEGER DESC;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  my @row = $result->fetchrow();
  if ($row[0] > $pgid) { $pgid = $row[0]; } }
print "highest $pgid\n";

my @pgcommands;
my %lineToStrain;
my %pubToRest;
# my $infile = 'transgene_info_karen1.txt';
my $infile = 'transgene_info_karen2.txt';
open (IN, "<$infile") or die "Cannot open $infile : $!";
my $headers = <IN>;
while (my $line = <IN>) {
  chomp $line;
#   my ($strain, $public_name, $summary, $driven_by_gene, $reporter_product, $other_reporter, $gene, $threeutr, $map, $coinjection, $cgcremark) = split/\t/, $line;
  my (@line) = split/\t/, $line;
  $line[1] =~ s/\s//g;
  my $pubname = $line[1];
  if ($nameToPgid{$pubname}) { 
    print "EXISTS $pubname LINE $line\n"; 
    next; }
  my $strain = shift @line;
  my $reline = join"\t", @line;
  $lineToStrain{$reline}{$strain}++;
  $pubToRest{$pubname}{$reline}++;
} # while (my $line = <IN>)
close (IN) or die "Cannot close $infile : $!";

foreach my $pubname (sort keys %pubToRest) {
  if (scalar keys %{ $pubToRest{$pubname} } > 1) { 
    my $count = scalar keys %{ $pubToRest{$pubname} };
    foreach my $line (sort keys %{ $pubToRest{$pubname} }) {
      print "DIFF $count TRANSGENE $pubname\t$line\n";
    }
  }
} # foreach my $line (sort keys %pubToRest)

my $curator = 'WBPerson2970';	# Mary Ann

foreach my $line (sort keys %lineToStrain) {
#   if (scalar keys %{ $lineToStrain{$line} } > 1) { 
#     my $strains = join"|", sort keys %{ $lineToStrain{$line} };
#     print "STRAINS $strains\t$line\n";
#   }
  my $strain = join"|", sort keys %{ $lineToStrain{$line} };
  my ($publicname, $summary, $driven_by_gene, $reporter_product, $other_reporter, $gene, $threeutr, $map, $coinjection, $cgcremark) = split/\t/, $line;
  if ($cgcremark) { 
    if ($cgcremark =~ m/^\"\s*/) { $cgcremark =~ s/^\"\s*//; }
    if ($cgcremark =~ m/\s*\"$/) { $cgcremark =~ s/\s*\"$//; } }
  if ($threeutr) {
    if ($genes{$threeutr}) { $threeutr = '"' . $genes{$threeutr} . '"'; }
      elsif ($genes{lc($threeutr)}) { $threeutr = '"' . $genes{lc($threeutr)} . '"'; }
      else { print "$threeutr not a gene in $line\n"; } }
  if ($driven_by_gene) {
    if ($genes{$driven_by_gene}) { $driven_by_gene = '"' . $genes{$driven_by_gene} . '"'; }
      elsif ($genes{lc($driven_by_gene)}) { $driven_by_gene = '"' . $genes{lc($driven_by_gene)} . '"'; }
      else { print "$driven_by_gene not a gene in $line\n"; } }
  if ($gene) {
    if ($genes{$gene}) { $gene = '"' . $genes{$gene} . '"'; }
      elsif ($genes{lc($gene)}) { $gene = '"' . $genes{lc($gene)} . '"'; }
      else { print "$gene not a gene in $line\n"; } }
  if ($map) {
    if ($chromosomes{$map}) { $map = '"' . $chromosomes{$map} . '"'; }
      else { print "$map not a chromosome in $line\n"; } }
  if ($reporter_product) {
    if ($repprod{$reporter_product}) { $reporter_product = '"' . $repprod{$reporter_product} . '"'; }
      else { print "$reporter_product not a reporter_product in $line\n"; } }
# COMMENT OUT TO POPULATE
  next;

  $pgid++;
  my $trpId = &pad8Zeros($pgid);
  my $objId = 'WBTransgene'. $trpId;
  &insertToPostgresTableAndHistory('trp_name',    $pgid, $objId);
  &insertToPostgresTableAndHistory('trp_curator', $pgid, $curator);
  if ($strain)             { &insertToPostgresTableAndHistory('trp_strain',             $pgid, $strain); }
  if ($publicname)         { &insertToPostgresTableAndHistory('trp_publicname',         $pgid, $publicname); }
  if ($summary)            { &insertToPostgresTableAndHistory('trp_summary',            $pgid, $summary); }
  if ($driven_by_gene)     { &insertToPostgresTableAndHistory('trp_driven_by_gene',     $pgid, $driven_by_gene); }
  if ($reporter_product)   { &insertToPostgresTableAndHistory('trp_reporter_product',   $pgid, $reporter_product); }
  if ($other_reporter)     { &insertToPostgresTableAndHistory('trp_other_reporter',     $pgid, $other_reporter); }
  if ($gene)               { &insertToPostgresTableAndHistory('trp_gene',               $pgid, $gene); }
  if ($threeutr)           { &insertToPostgresTableAndHistory('trp_threeutr',           $pgid, $threeutr); }
  if ($map)                { &insertToPostgresTableAndHistory('trp_map',                $pgid, $map); }
  if ($coinjection)        { &insertToPostgresTableAndHistory('trp_coinjection',        $pgid, $coinjection); }
  if ($cgcremark)          { &insertToPostgresTableAndHistory('trp_cgcremark',          $pgid, $cgcremark); }

} # foreach my $line (sort keys %lineToStrain)

sub insertToPostgresTableAndHistory {
  my ($table, $joinkey, $newValue) = @_;
  if ($newValue =~ m/\'/) { $newValue =~ s/\'/''/g; }
#   unless (is_utf8($newValue)) { from_to($newValue, "iso-8859-1", "utf8"); }
  my $returnValue = '';
  print qq(INSERT INTO $table VALUES ('$joinkey', '$newValue')\n);
  my $result = $dbh->prepare( "INSERT INTO $table VALUES ('$joinkey', '$newValue')" );
  $result->execute() or $returnValue .= "ERROR, failed to insert to $table &insertToPostgresTableAndHistory\n";
  $result = $dbh->prepare( "INSERT INTO ${table}_hst VALUES ('$joinkey', '$newValue')" );
  $result->execute() or $returnValue .= "ERROR, failed to insert to ${table}_hst &insertToPostgresTableAndHistory\n";
  unless ($returnValue) { $returnValue = 'OK'; }
  return $returnValue;
} # sub insertToPostgresTableAndHistory



sub pad8Zeros {         # take a number and pad to 8 digits
  my $number = shift;
  if ($number =~ m/^0+/) { $number =~ s/^0+//g; }               # strip leading zeros
  if ($number < 10) { $number = '0000000' . $number; }
  elsif ($number < 100) { $number = '000000' . $number; }
  elsif ($number < 1000) { $number = '00000' . $number; }
  elsif ($number < 10000) { $number = '0000' . $number; }
  elsif ($number < 100000) { $number = '000' . $number; }
  elsif ($number < 1000000) { $number = '00' . $number; }
  elsif ($number < 10000000) { $number = '0' . $number; }
  return $number;
} # sub pad8Zeros

__END__

  @{ $datatypes{trp}{highestPgidTables} }            = qw( name curator );

    my $trpId = &pad8Zeros($newPgid);
    ($returnValue)  = &insertToPostgresTableAndHistory('trp_name', $newPgid, "WBTransgene$trpId"); }
  if ($returnValue eq 'OK') { $returnValue = $newPgid; }


DELETE FROM trp_name                   WHERE trp_timestamp > '2013-02-07 16:46';
DELETE FROM trp_paper                  WHERE trp_timestamp > '2013-02-07 16:46';
DELETE FROM trp_curator                WHERE trp_timestamp > '2013-02-07 16:46';
DELETE FROM trp_strain                 WHERE trp_timestamp > '2013-02-07 16:46';
DELETE FROM trp_publicname             WHERE trp_timestamp > '2013-02-07 16:46';
DELETE FROM trp_summary                WHERE trp_timestamp > '2013-02-07 16:46';
DELETE FROM trp_driven_by_gene         WHERE trp_timestamp > '2013-02-07 16:46';
DELETE FROM trp_reporter_product       WHERE trp_timestamp > '2013-02-07 16:46';
DELETE FROM trp_other_reporter         WHERE trp_timestamp > '2013-02-07 16:46';
DELETE FROM trp_gene                   WHERE trp_timestamp > '2013-02-07 16:46';
DELETE FROM trp_threeutr               WHERE trp_timestamp > '2013-02-07 16:46';
DELETE FROM trp_map                    WHERE trp_timestamp > '2013-02-07 16:46';
DELETE FROM trp_coinjection            WHERE trp_timestamp > '2013-02-07 16:46';
DELETE FROM trp_cgcremark              WHERE trp_timestamp > '2013-02-07 16:46';

DELETE FROM trp_name_hst               WHERE trp_timestamp > '2013-02-07 16:46';
DELETE FROM trp_paper_hst              WHERE trp_timestamp > '2013-02-07 16:46';
DELETE FROM trp_curator_hst            WHERE trp_timestamp > '2013-02-07 16:46';
DELETE FROM trp_strain_hst             WHERE trp_timestamp > '2013-02-07 16:46';
DELETE FROM trp_publicname_hst         WHERE trp_timestamp > '2013-02-07 16:46';
DELETE FROM trp_summary_hst            WHERE trp_timestamp > '2013-02-07 16:46';
DELETE FROM trp_driven_by_gene_hst     WHERE trp_timestamp > '2013-02-07 16:46';
DELETE FROM trp_reporter_product_hst   WHERE trp_timestamp > '2013-02-07 16:46';
DELETE FROM trp_other_reporter_hst     WHERE trp_timestamp > '2013-02-07 16:46';
DELETE FROM trp_gene_hst               WHERE trp_timestamp > '2013-02-07 16:46';
DELETE FROM trp_threeutr_hst           WHERE trp_timestamp > '2013-02-07 16:46';
DELETE FROM trp_map_hst                WHERE trp_timestamp > '2013-02-07 16:46';
DELETE FROM trp_coinjection_hst        WHERE trp_timestamp > '2013-02-07 16:46';
DELETE FROM trp_cgcremark_hst          WHERE trp_timestamp > '2013-02-07 16:46';
