#!/usr/bin/perl

use strict;
use diagnostics;

# our %stuff;
# our %tags;
# our $count = 0;

my $oldrayinsert = "/home/postgres/work/pgpopulation/datafromoldform/oldrayinsert.pl";
open (OUT, ">$oldrayinsert") or die "Cannot create $oldrayinsert : $!";


print OUT "#!\/usr\/bin\/perl5.6.0\n";
print OUT "\n";
print OUT "use lib qw( \/usr\/lib/perl5\/site_perl\/5.6.1\/i686-linux\/ );\n";
print OUT "use Pg;\n";
print OUT "\n";
print OUT "\$conn = Pg::connectdb(\"dbname=testdb\");\n";
print OUT "die \$conn->errorMessage unless PGRES_CONNECTION_OK eq \$conn->status ;\n\n";

my $raymond_file = "/home/postgres/work/pgpopulation/datafromoldform/raymond.txt";
# my $all_file;
open (RAY, "<$raymond_file") or die "Cannot open $raymond_file : $!";
{
  local $/;
  my $all_file = <RAY>;
  $all_file =~ s/\n//g;
  $all_file =~ s/Association : \t "equivalent : /associationequiv : "/g;
  $all_file =~ s/Association : \t "new : /associationnew : "/g;
  $all_file =~ s/Ablation Data : /ablationdata : /g;
  $all_file =~ s/Cell Function : /cellfunction : /g;
  $all_file =~ s/Cell Name : /cellname : /g;
  $all_file =~ s/Comments : /comment : /g;
  $all_file =~ s/Expression : /expression : /g;
  $all_file =~ s/Extract Antibody : /antibody : /g;
  $all_file =~ s/Extracted Allele : /extractedallelenew : /g;
  $all_file =~ s/Gene Function : /genefunction : /g;
  $all_file =~ s/Gene Product : /geneproduct : /g;
  $all_file =~ s/Gene Symbols : /genesymbols : /g;
  $all_file =~ s/Good Photo : /goodphoto : /g;
  $all_file =~ s/Mapping Data : /mappingdata : /g;
  $all_file =~ s/Mosaic Analysis : /mosaic : /g;
  $all_file =~ s/New Mutant : /newmutant : /g;
  $all_file =~ s/New Symbol : /newsymbol : /g;
  $all_file =~ s/Overexpression : /overexpression : /g;
  $all_file =~ s/RNAi : /rnai : /g;
  $all_file =~ s/Sequence Change : /sequencechange : /g;
  $all_file =~ s/Sequence Features : /sequencefeatures : /g;
  $all_file =~ s/St Louis SNP : /stlouissnp : /g;
  $all_file =~ s/Structure Correction : /structurecorrection : /g;
  $all_file =~ s/Synonym : /synonym : /g;
  $all_file =~ s/Transgene : /transgene : /g;

  $all_file =~ s/antibody1 :\t/NONONO : /g;
  $all_file =~ s/antibody2 :\t/antibody : /g;
  $all_file =~ s/association1 :\t/NONONO : /g;
  $all_file =~ s/association2 :\t/association : /g;
  $all_file =~ s/expression1 :\t/NONONO : /g;
  $all_file =~ s/expression2 :\t/expression : /g;
  $all_file =~ s/expression1 :\t/NONONO : /g;
  $all_file =~ s/expression2 :\t/expression : /g;
  $all_file =~ s/extractedallele3 :\t/NONONO : /g;
  $all_file =~ s/extractedallele4 :\t/extractedallele : /g;
  $all_file =~ s/extractedallele3 :\t/NONONO : /g;
  $all_file =~ s/extractedallele4 :\t/extractedallele : /g;
  $all_file =~ s/genefunction1 :\t/NONONO : /g;
  $all_file =~ s/genefunction2 :\t/genefunction : /g;
  $all_file =~ s/geneproduct1 :\t/NONONO : /g;
  $all_file =~ s/geneproduct2 :\t/geneproduct : /g;
  $all_file =~ s/mappingdata1 :\t/NONONO : /g;
  $all_file =~ s/mappingdata2 :\t/mappingdata : /g;
  $all_file =~ s/newmutant1 :\t/NONONO : /g;
  $all_file =~ s/newmutant2 :\t/newmutant1 : /g;
  $all_file =~ s/newsymbol1 :\t/NONONO : /g;
  $all_file =~ s/newsymbol2 :\t/newsymbol : /g;
  $all_file =~ s/overexpression1 :\t/NONONO : /g;
  $all_file =~ s/overexpression2 :\t/overexpression : /g;
  $all_file =~ s/rnai1 :\t/NONONO : /g;
  $all_file =~ s/rnai2 :\t/rnai : /g;
  $all_file =~ s/sequencechange1 :\t/NONONO : /g;
  $all_file =~ s/sequencechange2 :\t/sequencechange : /g;
  $all_file =~ s/sequencefeatures1 :\t/NONONO : /g;
  $all_file =~ s/sequencefeatures2 :\t/sequencefeatures : /g;
  $all_file =~ s/pdffilename :\t/NONONO : /g;
  $all_file =~ s/structurecorrection1 :\t/NONONO : /g;
  $all_file =~ s/structurecorrection2 :\t/structurecorrection : /g;
  $all_file =~ s/synonym1 :\t/NONONO : /g;
  $all_file =~ s/synonym2 :\t/synonym : /g;
  $all_file =~ s/transgene1 :\t/NONONO : /g;
  $all_file =~ s/transgene2 :\t/transgene : /g;

#   print $all_file . "\n";
  my @all_entries = split /\n\n/, $all_file; 
  foreach my $each_entry (@all_entries) {
#       print "\n\n";
# print "ENTRY : $each_entry\n\n\n";
    $each_entry =~ m/pubID :[ \t]+"(.*)"/;
    my $joinkey = $1;
    $joinkey =~ s/://g;
    $joinkey =~ s/ //g;
    $joinkey =~ s/_//g;
    $joinkey = lc($joinkey);
#     print "$joinkey\n";
    my @individual_entries = split /\n/, $each_entry;
    foreach my $entry_line (@individual_entries) {

      unless ($entry_line !~ /:/) {
        my @colon_array = split / :\s+"/, $entry_line;
        my $tag = $colon_array[0];
        unless ( ($tag eq "pubID") || ($tag eq "wormID") || ($tag eq "Curator") || ($tag eq "Date") || ($tag eq "Reference") || ($tag eq "NONONO") || ($tag eq "curator") || ($tag eq "reference") ) {
#           print "TAG : " . $colon_array[0] . "\tINFO : " . $colon_array[1] . "\t" . $joinkey . "\n";
#           unless ($colon_array[1]) { print "BAD BAD $entry_line\n"; }
#            $tags{$colon_array[0]}++;
          $colon_array[1] =~ s/"\s+$//g;
          $colon_array[1] =~ s/'/\\'/g;
          $colon_array[1] =~ s/"/\\"/g;
          $colon_array[1] =~ s/@/\\@/g;
          $colon_array[1] =~ s//\n/g;
# THINK ABOUT ^M or \n in postgres.  sub out possible bad things for postgres
          print OUT "\$result = \$conn->exec( \"INSERT INTO $colon_array[0] VALUES ('$joinkey', '$colon_array[1]')\")\n";
        } # unless ( ($tag eq "pubID") || ($tag eq "wormID") || ($tag eq "Curator") || ($tag eq "Date") || ($tag eq "Reference") || ($tag eq "NONONO) ) 
      } # unless ($entry_line !~ /:/) 

# This doesn't match for some reason
#       if ($entry_line =~ m/^(.*) :[ \t]+"(.*)"$/) {
#         $entry_line =~ m/^(.*) :[ \t]+"(.*)"$/;
#         my $tag = $1;
#         my $info = $2;
# # print "TAG : $tag\tINFO : $info\n";
#         $tags{$tag}++;
#   #       $stuff{$joinkey} = [ $tag, $info ];
#       } else { # if ($entry_line =~ m/^(.*) :\s+"(.*)"$/) 
#         $count++;
# #         print "WHAT ? -=${entry_line}=-$count;\n"; 
#         $entry_line =~ m/^(.*) :\s+"(.*)"$/;
#         my $tag = $1;
# #         my $info = $2;
# # print "WHAT TAG : -=${tag}=-$count;\n"; # \tINFO : $info\n";
#       } # else # if ($entry_line =~ m/^(.*) :\s+"(.*)"$/) 

    } # foreach my $entry_line (@individual_entries) 
  } # foreach $_ (@all_entries) 
}

# foreach $_ (sort keys %tags) {
#   print $_ . " : " . $tags{$_} . "\n";
# } # foreach $_ (sort keys %tags) 


