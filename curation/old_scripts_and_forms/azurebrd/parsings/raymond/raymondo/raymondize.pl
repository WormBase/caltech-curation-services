#!/usr/bin/perl -w
#
# Compare stuff like raymond wanted it (don't know, ask him)

use strict;
use diagnostics;

# my $file1 = "/home/azurebrd/work/parsings/raymondo/TH_wt_primers.csv2";
# my $file2 = "/home/azurebrd/work/parsings/raymondo/mapping";
# my $matches = "/home/azurebrd/work/parsings/raymondo/matches";
# my $rem_file1 = "/home/azurebrd/work/parsings/raymondo/rem_TH_wt_primers.csv2";
# my $rem_file2 = "/home/azurebrd/work/parsings/raymondo/rem_mapping";
# my $errorfile = "/home/azurebrd/work/parsings/raymondo/errorfile";

my $file1 = "/home/azurebrd/work/parsings/raymondo/TH_wt_primers_supplement";
my $file2 = "/home/azurebrd/work/parsings/raymondo/mapping_supplement";
my $matches = "/home/azurebrd/work/parsings/raymondo/matches_supplement";
my $rem_file1 = "/home/azurebrd/work/parsings/raymondo/rem_TH_wt_primers_supplement";
my $rem_file2 = "/home/azurebrd/work/parsings/raymondo/rem_mapping_supplement";
my $errorfile = "/home/azurebrd/work/parsings/raymondo/errorfile_supplement";

open (ONE, "<$file1") or die "Cannot open $file1 : $!";
open (TWO, "<$file2") or die "Cannot open $file2 : $!";
open (MAT, ">$matches") or die "Cannot create $matches : $!";
open (ERR, ">$errorfile") or die "Cannot create $errorfile : $!";
open (RON, ">$rem_file1") or die "Cannot create $rem_file1 : $!";
open (RTW, ">$rem_file2") or die "Cannot create $rem_file2 : $!";

my %one;			# HoAoA
my %two;			# HoAoA
my %temp_hash;			# hash to read in only unique
my %bad_one;			# sequences with multiple primer pairs
my %counter;			# count how many times we are using a given
				# sequence identifier
my $output_count = 0;		# how many entries printed out (each block)

$_ = <ONE>;			# skip first line
while (<ONE>) {
  chomp;
  $temp_hash{$_}++;
} # while (<ONE>)
foreach $_ (sort keys %temp_hash) {
  my @one = split/\t/, $_;

    # if double, put in hash to ignore later
  if ($one{$one[0]}) { $bad_one{$one[0]}++; }

  $counter{$one[0]}++;
  $one{$one[0]}[$counter{$one[0]}] = [ $one[1], $one[2] ];
} # foreach $_ (sort keys %temp_hash)

%temp_hash = ();		# clear the unique-ing hash
%counter = ();			# clear the counting hash

while (<TWO>) {
  chomp;
  $temp_hash{$_}++;
} # while (<TWO>)
foreach $_ (sort keys %temp_hash) {
  my @two = split/ /, $_;
  $counter{$two[0]}++;
  $two{$two[0]}[$counter{$two[0]}] = [ $two[1], $two[2], $two[3] ];
} # foreach $_ (sort keys %temp_hash)

for my $seq_id (sort keys %one) {
  if ($two{$seq_id}) {
    if ($bad_one{$seq_id}) { 		# sequence has multiple primer pairs
      print ERR "MANUAL : $seq_id : $bad_one{$seq_id}\n";
    } else { # if ($bad_one{$seq_id}) 	# good stuff
      &output($seq_id);
    } # else # if ($bad_one{$seq_id}) 	# good stuff
    delete $one{$seq_id};
    delete $two{$seq_id};
  } # if ($two{$seq_id})
} # for $_ (sort keys %one)
print "OUT : $output_count\n";

for my $seq_id (sort keys %one) {
  for my $i ( 1 .. $#{ $one{$seq_id} } ) {	# starting with one, not zero
						# because of counter++
    print RON "ONE : $seq_id\t$one{$seq_id}[$i][0]\t";
    print RON "$one{$seq_id}[$i][1]\n";
  } # for my $i ( 1 .. $#{ $one{$seq_id} } )
} # for $_ (sort keys %one)

for my $seq_id (sort keys %two) {
  for my $i ( 1 .. $#{ $two{$seq_id} } ) {	# starting with one, not zero
						# because of counter++
    print RTW "TWO : $seq_id\t$two{$seq_id}[$i][0]\t";
    print RTW "$two{$seq_id}[$i][1]\t";
    print RTW "$two{$seq_id}[$i][2]\n";
  } # for my $i ( 1 .. $#{ $two{$seq_id} } )
} # for $_ (sort keys %two)

sub output {
  my $seq_id = shift;
  for my $i ( 1 .. $#{ $one{$seq_id} } ) {	# starting with one, not zero
						# because of counter++
    for my $j ( 1 .. $#{ $two{$seq_id} } ) {
      my $seq_id_print = $seq_id;		# get value to print
# to print _1
      if ( scalar(@{$two{$seq_id} }) > 2) {
# to not print _1
#       if ( ( scalar(@{$two{$seq_id} }) > 2) && ($j > 1) ) 
        $seq_id_print = $seq_id . "_" . $j;
      } # if ( scalar(@{$two{$seq_id} }) > 2)

      $output_count++;

      print MAT "Oligo :\tTH:$seq_id_print-F\n";
      print MAT "Sequence\t$one{$seq_id}[$i][0]\n";
      my @array = split//, $one{$seq_id}[$i][0];
      my $oligo_length_F = scalar(@array);
      print MAT "Length\t" . scalar(@array) . "\n";
      print MAT "In_sequence\t$two{$seq_id}[$j][0]\n";
      print MAT "\n";
      print MAT "Oligo :\tTH:$seq_id_print-R\n";
      print MAT "Sequence\t$one{$seq_id}[$i][1]\n";
      @array = split//, $one{$seq_id}[$i][1];
      my $oligo_length_R = scalar(@array);
      print MAT "Length\t" . scalar(@array) . "\n";
      print MAT "In_sequence\t$two{$seq_id}[$j][0]\n";
      print MAT "\n";
      my $size_of_product = $two{$seq_id}[$j][2] - $two{$seq_id}[$j][1] + 1;
      print MAT "PCR_product :\tTH:$seq_id_print\n";
      print MAT "RNAi\tTH:$seq_id_print 1 $size_of_product\n";
      print MAT "Method\tGenePairs\n";
      print MAT "Oligo\tTH:$seq_id_print-F\n";
      print MAT "Oligo\tTH:$seq_id_print-R\n";
      print MAT "Remark\t\"PCR fragment for TH:$seq_id_print RNAi\"\n";
      print MAT "\n";
      print MAT "Sequence :\t$two{$seq_id}[$j][0]\n";
      print MAT "PCR_product :\tTH:$seq_id_print $two{$seq_id}[$j][1] $two{$seq_id}[$j][2]\n";
      my $start_pos = $two{$seq_id}[$j][1];
      my $end_pos = $start_pos + $oligo_length_F - 1;
      print MAT "Oligo :\tTH:$seq_id_print-F $start_pos $end_pos\n";
      $end_pos = $two{$seq_id}[$j][2];
      $start_pos = $end_pos - $oligo_length_R + 1;
      print MAT "Oligo\tTH:$seq_id_print-R $end_pos $start_pos\n";
      print MAT "\n";
      print MAT "RNAi :\tTH:$seq_id_print\n";
      print MAT "Method\tRNAi\n";
      print MAT "Laboratory\tTH\n";
      print MAT "Author \"Gonczy P\"\n";
      print MAT "Author \"Echeverri C\"\n";
      print MAT "Author \"Oegema K\"\n";
      print MAT "Author \"Coulson AR\"\n";
      print MAT "Author \"Jones SJ\"\n";
      print MAT "Author \"Copley RR\"\n";
      print MAT "Author \"Duperon J\"\n";
      print MAT "Author \"Oegema J\"\n";
      print MAT "Author \"Brehm M\"\n";
      print MAT "Author \"Cassin E\"\n";
      print MAT "Author \"Hannak E\"\n";
      print MAT "Author \"Kirkham M\"\n";
      print MAT "Author \"Pichler SC\"\n";
      print MAT "Author \"Flohrs K\"\n";
      print MAT "Author \"Go essen A\"\n";
      print MAT "Author \"Leidel S\"\n"; 
      print MAT "Author \"Alleaume AM\"\n";
      print MAT "Author \"Martin C\"\n"; 
      print MAT "Author \"Ozlu N\"\n";
      print MAT "Author \"Bork P\"\n";
      print MAT "Author \"Hyman AA\"\n";
      print MAT "Date\t2000-11-16\n";
      print MAT "Delivered_by\tInjection\n";
      print MAT "Reference\t[cgc4403]\n";
      print MAT "Phenotype\tWT\tRemark\t\"DIC phenotype -- Embryonic development normal\"\n";

      if ( scalar(@{$two{$seq_id} }) > 2) {
        my @remark_seq_id;
	for my $k ( 1 .. $#{ $two{$seq_id} } ) {
          unless ($k == $j) {
            my $value = "TH:" . $seq_id . "_" . $k;
            push @remark_seq_id, $value;
          } # unless ($k == $j)
	} # for my $k ( 1 .. $#{ $two{$seq_id} } )
        my $remark_seq_id = join "\t", @remark_seq_id;
        print MAT "Remark\t\"This RNAi has multiple targets in the genome, see also RNAi: $remark_seq_id\"\n"; 

#         print MAT "Remark\t\"This RNAi has multiple targets in the genome, see also RNAi: "; 
#         for my $k ( 1 .. $#{ $two{$seq_id} } ) {
#           if ($k != $j) {
#             print MAT "$two{$seq_id}[$k][0]\t";
#           } # if ($k != $j)
#         } # for my $k ( 1 .. $#{ $two{$seq_id} } )
#         print MAT "\"\n";
      } # if ( scalar(@{$two{$seq_id} }) > 2) 

      print MAT "\n";
      print MAT "\n";
    } # for my $j ( 1 .. $#{ $two{$seq_id} } )
  } # for my $i ( 1 .. $#{ $two{$seq_id} } )
} # sub output
