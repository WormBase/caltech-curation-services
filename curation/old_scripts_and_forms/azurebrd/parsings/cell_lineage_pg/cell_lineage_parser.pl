#!/usr/bin/perl -w
#
# take raymond's parse_instructions and try to do what they say.
# grab lineages and parents.  filter lineages so only one shows up.  output
# as described for psql to read in.

use strict;
use diagnostics;

my $out = "/home/azurebrd/work/parsings/cell_lineage_pg/pg_commands";
my $source = "/home/azurebrd/work/parsings/cell_lineage_pg/cell_w_Parent_Lineage_nameWS73.ace"; 
my $errorfile = "/home/azurebrd/work/parsings/cell_lineage_pg/errorfile";

open (IN, "<$source") or die "Cannot open $source : $!";
open (OUT, ">$out") or die "Cannot create $out : $!";
open (ERR, ">$errorfile") or die "Cannot create $errorfile : $!";

my %parent;		# store the parent by count number
my %lineage;		# store the lineage by count number
my %parentcounter;	# count if it's been seen before
my %lineagecounter;	# count if it's been seen before
my $count = 0;

$/ = "";
while (<IN>) { 
  unless ( ($_ =~ m/^Lineage_name\t "/m) && ($_ =~ m/^Parent\t "/m) ) {
			# no lineage name or parent
    print ERR "No Lineage_name and/or Parent :\n$_";
  } else { 		# looks like good data
    $_ =~ m/^Lineage_name\t "(.*?)"/m;
    my $lineage = $1;
    $_ =~ m/^Parent\t "(.*?)"/m;
    my $parent = $1;
      # sub apostrophes for PG to read okay
    $lineage =~ s/'/''/g;
    $parent =~ s/'/''/g;

    if ($lineagecounter{$lineage}) {
			# if repeat, error
#         to output error for each
#       print ERR "lineage : $lineage{$lineage}\n";
#       print ERR "parent : $parent{$lineage}\n";
      print ERR "lineage : $lineage\n";
      print ERR "parent : $parent\n";
      print ERR "\n";
    } else {
			# if good, count it and put in hashes
      $count++;
      $lineage{$count} = $lineage;
      $parent{$count} = $parent;
    } # else # if ($lineagecounter{$lineage})
    $lineagecounter{$lineage}++;
    
# # used to count multiple lineages and parents (assumed okay now)
#     if ($lineage) { $lineagecounter{$lineage}++;
#     } else { print ERR "No Lineage : $_"; }
#     if ($parent) { $parentcounter{$parent}++;
#     } else { print ERR "No Parent : $_"; }
  } # unless ( ($_ =~ m/^Lineage_name\t "/m) && ($_ =~ m/^Parent\t "/m) )
} # while (<IN>)

  # insert raw stuff for each of the good stuff in hash
foreach (sort { $a <=> $b } keys %parent) { 
  my $number = 1000 + $_;
  $number = "000" . $number;
  print OUT "INSERT INTO term (id,name,term_type,acc_prefix,acc,is_obsolete,is_root) VALUES (nextval('term_pgindex'::text),'$lineage{$_}','Lineage_name','WBdag','$number',0,0);\n";
} # foreach (sort keys %parent)
print OUT "\n";

  # change stuff for each of the good stuff in hash
foreach (sort { $a <=> $b } keys %parent) { 
  print OUT "INSERT INTO term2term (id,relationship_type_id,term1_id,term2_id)\n";
  print OUT "VALUES (nextval('term2term_pgindex'::text),4,1,1);\n";
  print OUT "UPDATE term2term \n";
  print OUT "SET term1_id=term.id\n";
  print OUT "FROM term\n";
  print OUT "WHERE term.name = '$parent{$_}' AND term2term.id = currval('term2term_pgindex'::text);\n";
  print OUT "UPDATE term2term \n";
  print OUT "SET term2_id=term.id\n";
  print OUT "FROM term\n";
  print OUT "WHERE term.name = '$lineage{$_}' AND term2term.id = currval('term2term_pgindex'::text);\n";
  print OUT "\n";
} # foreach (sort keys %parent)


  # used to count multiple lineages and parents (assumed okay now)
  # extra lineages are not good
print ERR "Extra Lineage_name :\n";
foreach (sort keys %lineagecounter) {
  if ($lineagecounter{$_} > 1) { print ERR "extra $_ $lineagecounter{$_} times\n"; }
} # foreach (sort keys %lineagecounter)

  # don't care about extra parents (different things have same parent)
# print ERR "parent\n";
# foreach (sort keys %parentcounter) {
#   if ($parentcounter{$_} > 1) { print ERR "extra $_ $parentcounter{$_} times\n"; }
# } # foreach (sort keys %parentcounter)
