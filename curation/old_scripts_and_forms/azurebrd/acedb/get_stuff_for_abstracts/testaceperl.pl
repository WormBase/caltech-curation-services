#!/usr/bin/perl -w

use diagnostics;
use Ace;

$db = Ace->connect(-path  =>  '/home/acedb',
		   -program => '/home/acedb/bin/tace') || die "Connection failure: ",Ace->error;

# my @authors = $db->list('Author','Chan*');
# print "There are ",scalar(@authors)," Author objects matching the last name.\n";
# print "The first one's name is ",$authors[0],"\n";

#   my $outfile = "/home/azurebrd/work/acedb/get_stuff_for_abstracts/Sequence.dump";
#   open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
#   $query = <<END;
# Find Sequence
# END
# print "getting 'em\n";
#   @ready_names= $db->fetch(-query=>$query);
# print "got 'em\n";
# print "$ready_names[0]\n$ready_names[1]\n";
# print "huh ?\n";
#   foreach (@ready_names) { print "$_\n"; }
# print "nothing here\n";
#   close (OUT) or die "Cannot close $outfile : $!";
# print "nothing closing\n";

  # for some reason Sequence doesn't work
my @refers_to = qw(Locus Allele Rearrangement Sequence Strain Clone Protein Expr_pattern
Expr_profile Cell Cell_group Life_stage RNAi Transgene Gene GO_term Operon);

foreach my $term (@refers_to) {
  my $outfile = "/home/azurebrd/work/acedb/get_stuff_for_abstracts/${term}.dump";
  open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
  $query = <<END;
Find $term 
END
  @ready_names= $db->fetch(-query=>$query);
  foreach (@ready_names) { print OUT "$_\n"; }
  close (OUT) or die "Cannot close $outfile : $!";
} # foreach my $term (@refers_to)
