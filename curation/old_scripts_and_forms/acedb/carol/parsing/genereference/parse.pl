#!/usr/bin/perl

# generic parsing of stuff in one file, not in other  2007 01 05


  # file with stuff to check for
my $infile = 'genes_reference_count_more_20_phen_desc_sorted';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (<IN>) { 
  chomp; 			# take out newline at the end
  $_ =~ s/\s//g; 		# take out all space / tab / &c. characters
  $hash{$_}++; 			# put it in a hash
}
close (IN) or die "Cannot close $infile : $!";

  # file of data you want to check
$infile = 'gene_all_cgc_reference_allele_phen_desc_3';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) { 	# read one line at a time
  chomp $line;			# take out the newline at the end
  my @stuff = split/\t/, $line;		# break up by tabs into an array
  next unless ($hash{$stuff[0]});	# if the first item from the array (column 1)
					# is not in the hash from the other file, skip it
  print "$line\n";		# print the line (since it hasn't been skipped above)
}
close (IN) or die "Cannot close $infile : $!";
