#!/usr/bin/perl -w

use strict;
use Ace;


# if ($#ARGV < 1) {
#     print "usage: $0 object_type tag [position]\n";
#     exit;
# }

my $database_path = "/home/acedb/WS_current/";     # full path to local AceDB database; change as appropriate
my $program = "/home/acedb/bin/tace";  # full path to tace; change as appropriate


print "Connecting to database...";

my $db = Ace->connect('sace://aceserver.cshl.org:2005') || die "Connection failure: ", Ace->error;                      # uncomment to use aceserver.cshl.org - may be slow
# my $db = Ace->connect(-path => $database_path,  -program => $program) || die print "Connection failure: ", Ace->error;   # local database

print "done.\n";

$db->timestamps(1); # have to call this to use timestamp method later

# ./timestamp.pl Paper Gene
# my $obj_type=$ARGV[0];
# my $tag=$ARGV[1];
# my $pos;
# if ($ARGV[2]) {
#     $pos=$ARGV[2];
# }
# else {
#     $pos=1;
# }
# 
# my $query="find $obj_type $tag ";

my $query="find Paper Gene | Locus | Allele | Rearrangement | Sequence | CDS | Transcript | Pseudogene | Strain | Clone | Protein | Expr_pattern | Expr_profile | Cell | Cell_group | Life_stage | RNAi | Transgene | GO_term | Operon | Expression_cluster | Feature | Gene_regulation | Microarray_experiment | Anatomy_term | Antibody | SAGE_experiment | Y2H | Interaction";
# my $query="find Paper Gene | Locus | Allele | Rearrangement | Sequence | CDS | Transcript | Pseudogene | Strain | Clone | Protein | Expr_pattern | Expr_profile | Cell | Cell_group | Life_stage | RNAi | Transgene | GO_term | Operon | Feature | Gene_regulation | Microarray_experiment | Anatomy_term | Antibody | SAGE_experiment | Y2H | Interaction";

my @tags = qw( Gene Locus Allele Rearrangement Sequence CDS Transcript Pseudogene Strain Clone Protein Expr_pattern Expr_profile Cell Cell_group Life_stage RNAi Transgene GO_term Operon Feature Gene_regulation Microarray_experiment Anatomy_term Antibody SAGE_experiment Y2H Interaction );
# my @tags = qw( Gene Locus Allele Rearrangement Sequence CDS Transcript Pseudogene Strain Clone Protein Expr_pattern Expr_profile Cell Cell_group Life_stage RNAi Transgene GO_term Operon Expression_cluster Feature Gene_regulation Microarray_experiment Anatomy_term Antibody SAGE_experiment Y2H Interaction );

my @objs=$db->fetch(-query=>$query);

if (! @objs) {
#     print "no $obj_type objects with $tag tag found.\n";
    print "no objects found.\n";
    exit;
}

foreach my $obj (@objs) {
    print "$obj\t", $obj->timestamp, "\n";
#     foreach ($obj->$tag($pos)) {
# 	print "$_\t", $_->timestamp, "\n";
#     }
  foreach my $tag (@tags) {
    foreach ($obj->$tag(1)) {
	print "$_\t", $_->timestamp, "\n";
    }
  } # foreach my $tag (@tags)
  print "\n";
}
