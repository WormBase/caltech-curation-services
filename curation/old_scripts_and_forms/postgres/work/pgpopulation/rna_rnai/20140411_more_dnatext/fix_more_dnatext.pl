#!/usr/bin/perl -w

# look at rna_dnatext, split on pipes, find associated pcr_product and sequence in the text for each entry, then if they exist in corresponding rna_pcrproduct or rna_sequence, remove them from rna_dnatext (aggregating what is still left over and keeping that).  also, if any rna_dnatext names match in the obo_name_pcrproduct table, add them to rna_pcrproduct and likewise remove from rna_dnatext (again aggregating with existing rna_pcrproduct and keeping that).  for Chris  2014 04 11
#
# live run on tazendra 2014 04 11


use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;
my @pgcommands;

my %hash;

my %pgids;

$result = $dbh->prepare( "SELECT * FROM rna_dnatext" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  my $data = $row[1];
  my @data = split/\|/, $data;
  foreach my $data (@data) {
    if ($data =~ m/^\s+/) { $data =~ s/^\s+//; }
    if ($data =~ m/\s+$/) { $data =~ s/\s+$//; }
    if ($data =~ m/^ ?([ATCGNatcgn]+) (.+) ?$/) { 	# if there's literal atcgn and a name, capture what maps to the name
      my ($text, $name) = ($1, $2);
      if ($name =~ m/^\s+/) { $name =~ s/^\s+//; }
      if ($name =~ m/\s+$/) { $name =~ s/\s+$//; }
#       unless ($name) { print "NO NAME MATCH $row[0] -- $data -- $row[1]\n"; }
      $hash{$row[0]}{dnatext}{name}{$name} = $data; 
      $pgids{$row[0]}++;
    } else {
      push @{ $hash{$row[0]}{dnatext}{other} }, $data; 
    }
  } # foreach my $data (@data)
}
my $pgids = join"','", sort {$a<=>$b} keys %pgids;

my %changedPgids;
$result = $dbh->prepare( "SELECT * FROM rna_sequence WHERE joinkey IN ('$pgids')" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  my $pgid = $row[0];
  my $data = $row[1];
  my @data = split/\|/, $data;
  foreach my $sequence (@data) {
    if ($sequence =~ m/^\s+/) { $sequence =~ s/^\s+//; }
    if ($sequence =~ m/\s+$/) { $sequence =~ s/\s+$//; }
    if ($hash{$pgid}{dnatext}{name}{$sequence}) {
      print "Remove sequence $sequence from pgid $pgid with text $hash{$pgid}{dnatext}{name}{$sequence}\n";
      delete $hash{$pgid}{dnatext}{name}{$sequence};
      $changedPgids{$pgid}++;
    } # if ($hash{$pgid}{dnatext}{name}{$sequence})
  } # foreach my $data (@data)
} # while (my @row = $result->fetchrow)
  
print "\n\n";

my %pgPcrproducts;
$result = $dbh->prepare( "SELECT * FROM rna_pcrproduct WHERE joinkey IN ('$pgids')" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  my $pgid = $row[0];
  my $data = $row[1];
  if ($data =~ m/^"/) { $data =~ s/^"//; }
  if ($data =~ m/"$/) { $data =~ s/"$//; }
  my @data = split/","/, $data;
  foreach my $pcrproduct (@data) {
    $pgPcrproducts{$pgid}{$pcrproduct}++;
# if ($pgid eq '35951') { print "HERE 35951 $pcrproduct\n"; }
    if ($hash{$pgid}{dnatext}{name}{$pcrproduct}) {
# if ($pgid eq '35951') { print "HERE REMOVE 35951 $pcrproduct\n"; }
      print "Remove pcrproduct $pcrproduct from pgid $pgid with text $hash{$pgid}{dnatext}{name}{$pcrproduct}\n";
      delete $hash{$pgid}{dnatext}{name}{$pcrproduct};
      $changedPgids{$pgid}++;
    } # if ($hash{$pgid}{dnatext}{name}{$pcrproduct})
  } # foreach my $data (@data)
} # while (my @row = $result->fetchrow)

print "\n\n";

my %pcrproducts;
$result = $dbh->prepare( "SELECT obo_name_pcrproduct FROM obo_name_pcrproduct " );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $pcrproducts{$row[0]}++; }

foreach my $pgid (sort {$a<=>$b} keys %pgids) {
  my $addPcrproduct = 0;
  if (scalar keys %{ $hash{$pgid}{dnatext}{name} } > 0) {
    foreach my $name (sort keys %{ $hash{$pgid}{dnatext}{name} }) { 
      if ($pcrproducts{$name}) { 
        print "IS PCRPRODUCT : $pgid\t$name\t$hash{$pgid}{dnatext}{name}{$name}\n"; 
        delete $hash{$pgid}{dnatext}{name}{$name};
        $changedPgids{$pgid}++;
        $pgPcrproducts{$pgid}{$name}++; 
        $addPcrproduct++; 
      } else {
        print "STILL HAS NAME : $pgid\t$name\t$hash{$pgid}{dnatext}{name}{$name}\n";
      } 
    } # foreach my $name (sort keys %{ $hash{$pgid}{dnatext}{name} })
  } # if (scalar keys %{ $hash{$pgid}{dnatext}{name} } > 0)
  if ($addPcrproduct) {
    my $newPcrproduct = join'","', sort keys %{ $pgPcrproducts{$pgid} };
    print qq(CHANGE rna_pcrproduct TO $pgid\t"$newPcrproduct"\n);
    push @pgcommands, qq(DELETE FROM rna_pcrproduct WHERE joinkey = '$pgid';);
    push @pgcommands, qq(INSERT INTO rna_pcrproduct VALUES ('$pgid', '"$newPcrproduct"'););
    push @pgcommands, qq(INSERT INTO rna_pcrproduct_hst VALUES ('$pgid', '"$newPcrproduct"'););
  }
} # foreach my $pgid (sort {$a<=>$b} keys %pgids)

print "\n\n";

foreach my $pgid (sort {$a<=>$b} keys %changedPgids) {
  my @entries;
  foreach my $name (sort keys %{ $hash{$pgid}{dnatext}{name} }) { push @entries, $hash{$pgid}{dnatext}{name}{$name}; }
  foreach my $entry (@{ $hash{$pgid}{dnatext}{other} }) { push @entries, $entry; }
  my $entry = join" | ", @entries;
  print "NEW DATA $pgid\t$entry\n";
  push @pgcommands, qq(DELETE FROM rna_dnatext WHERE joinkey = '$pgid';);
  if ($entry) { 
      $entry = "'" . $entry . "'";
      push @pgcommands, qq(INSERT INTO rna_dnatext VALUES ('$pgid', $entry);); }
    else { $entry = 'NULL'; }
  push @pgcommands, qq(INSERT INTO rna_dnatext_hst VALUES ('$pgid', $entry););
} # foreach my $pgid (sort {$a<=>$b} keys %changedPgids)


# foreach my $pgid (sort keys %hash) {
#   foreach my $name (sort keys %{ $hash{$pgid}{dnatext} }) {
#     my $text = $hash{$pgid}{dnatext}{$name};
#     print "$pgid\t$name\t$text\n";
#   } # foreach my $name (sort keys %{ $hash{$pgid}{dnatext} })
# } # foreach my $pgid (sort keys %hash)

foreach my $pgcommand (@pgcommands) {
  print "$pgcommand\n";
# UNCOMMENT TO POPULATE
#   $dbh->do( $pgcommand );
} # foreach my $pgcommand (@pgcommands)


__END__

test set of pgids for just rna_pcrproduct, we didn't use this and instead used the whole rna_dnatext set.
26816,26817,26818,26819,26820,26821,26822,26839,26852,26856,27162,27177,27180,27181,27182,27183,27184,27447,27545,27546,27547,27548,27551,27573,27633,27634,27647,27712,27922,27927,27928,27929,27932,27933,27934,27935,27936,27937,27938,27939,27940,27941,27942,27943,27945,27947,27949,27952,27953,27954,27955,27958,27960,28011,28158,28160,28165,28166,28168,28169,28170,28180,28347,28348,30292,30293,30294,30295,30296,30297,32167,32168,32169,32170,32171,32172,32173,32174,32175,32176,32481,32482,32483,32484,32485,32634,32635,32636,32684,32685,32686,32687,32864,32865,32866,32867,32868,33285,33286,33287,33288,33289,33290,33291,33292,33380,33381,33382,33383,33384,33385,33386,33387,33388,33389,33729,33731,33733,33735,33737,34133,34134,34135,34136,34137,34138,34139,34140,34141,34142,34143,34144,34145,34146,34147,34148,34149,34150,34151,34152,34153,34154,34159,34160,34165,34166,34171,34172,34177,34178,34183,34184,34189,34190,34195,34196,34201,34202,34205,34206,34209,34210,34211,34212,34213,34214,34219,34220,34224,34225,34226,34227,34228,34229,34230,34231,34232,34233,34234,34235,34236,34237,34238,34239,34240,34241,34242,34243,34244,34245,34246,34247,34248,34249,34250,34251,34252,34253,34258,34263,34267,34271,34276,34280,34281,34286,34290,34291,34296,34297,34302,34303,34308,34309,34314,34315,34319,34320,34323,34324,34328,34329,34333,34334,34384,34386,34388,34391,34392,34393,34513,34514,34515,34551,34560,34606,34613,34888,34898,35431,35432,35433,35434,35435,35436,35437,35438,35439,35440,35441,35442,35443,35444,35445,35446,35951

