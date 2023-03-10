#!/usr/bin/perl

# make a hash for each of the possible fields (postgres tables)  write out the
# start of the inserter script (open to OUT).  read raymond.txt.  make a naked
# block for $/ to read all file into a single var.  switch the ^M\n into just ^M
# for ease of parsing.  switch out the tags for the name of the pg tables.  
# get separate entries by splitting on double newlines.  from each of the
# entries, grab the joinkey and clean it up (pubID).  for each of the fields
# split on / :\s+"/, go through each of the tags (first part) to see if matches,
# if so, clean up the field value (second part) and stick in like hash with 
# key==joinkey, value==field value.  if no match, put in bad hash.  go though
# each joinkey, and foreach joinkey, go through all hashes, and if hash has
# entry, print postgreSQL INSERT with value, else print with NULL.

# print out bad hash to test that no tags have been overlooked.

use strict;
use diagnostics;

# our %stuff;
# our %tags;
# our $count = 0;

my %joinkey;
my %pubID;
my %pdffilename;
my %curator;
my %reference;
my %newsymbol;
my %synonym;
my %mappingdata;
my %genefunction;
my %associationequiv;
my %associationnew;
my %expression;
my %rnai;
my %transgene;
my %overexpression;
my %mosaic;
my %antibody;
my %extractedallelename;
my %extractedallelenew;
my %newmutant;
my %sequencechange;
my %genesymbols;
my %geneproduct;
my %structurecorrection;
my %sequencefeatures;
my %cellname;
my %cellfunction;
my %ablationdata;
my %newsnp;
my %stlouissnp;
my %goodphoto;
my %comment;

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

  $all_file =~ s/overexpression1 :\t/NONONO : /g;
  $all_file =~ s/overexpression2 :\t/overexpression : /g;
		# skip the queue because of expression1234 later on
  $all_file =~ s/antibody1 :\t/NONONO : /g;
  $all_file =~ s/antibody2 :\t/antibody : /g;
  $all_file =~ s/association1 :\t/NONONO : /g;
  $all_file =~ s/association2 :\t/associationequiv : /g;
  $all_file =~ s/expression1 :\t/NONONO : /g;
  $all_file =~ s/expression2 :\t/expression : /g;
  $all_file =~ s/expression1 :\t/NONONO : /g;
  $all_file =~ s/expression2 :\t/expression : /g;
  $all_file =~ s/extractedallele3 :\t/NONONO : /g;
  $all_file =~ s/extractedallele4 :\t/extractedallelenew : /g;
  $all_file =~ s/extractedallele3 :\t/NONONO : /g;
  $all_file =~ s/extractedallele4 :\t/extractedallelenew : /g;
  $all_file =~ s/genefunction1 :\t/NONONO : /g;
  $all_file =~ s/genefunction2 :\t/genefunction : /g;
  $all_file =~ s/geneproduct1 :\t/NONONO : /g;
  $all_file =~ s/geneproduct2 :\t/geneproduct : /g;
  $all_file =~ s/mappingdata1 :\t/NONONO : /g;
  $all_file =~ s/mappingdata2 :\t/mappingdata : /g;
  $all_file =~ s/newmutant1 :\t/NONONO : /g;
  $all_file =~ s/newmutant2 :\t/newmutant : /g;
  $all_file =~ s/newsymbol1 :\t/NONONO : /g;
  $all_file =~ s/newsymbol2 :\t/newsymbol : /g;
#   $all_file =~ s/overexpression1 :\t/NONONO : /g;
#   $all_file =~ s/overexpression2 :\t/overexpression : /g;
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
          $joinkey{$joinkey} = $joinkey;
          if ($colon_array[0] eq "newsymbol") { $newsymbol{$joinkey} = $colon_array[1]; }
          elsif ($colon_array[0] eq "synonym") { $synonym{$joinkey} = $colon_array[1]; }
          elsif ($colon_array[0] eq "mappingdata") { $mappingdata{$joinkey} = $colon_array[1]; }
          elsif ($colon_array[0] eq "genefunction") { $genefunction{$joinkey} = $colon_array[1]; }
          elsif ($colon_array[0] eq "associationequiv") { $associationequiv{$joinkey} = $colon_array[1]; }
          elsif ($colon_array[0] eq "associationnew") { $associationnew{$joinkey} = $colon_array[1]; }
          elsif ($colon_array[0] eq "expression") { $expression{$joinkey} = $colon_array[1]; }
          elsif ($colon_array[0] eq "rnai") { $rnai{$joinkey} = $colon_array[1]; }
          elsif ($colon_array[0] eq "transgene") { $transgene{$joinkey} = $colon_array[1]; }
          elsif ($colon_array[0] eq "overexpression") { $overexpression{$joinkey} = $colon_array[1]; }
          elsif ($colon_array[0] eq "mosaic") { $mosaic{$joinkey} = $colon_array[1]; }
          elsif ($colon_array[0] eq "antibody") { $antibody{$joinkey} = $colon_array[1]; }
          elsif ($colon_array[0] eq "extractedallelename") { $extractedallelename{$joinkey} = $colon_array[1]; }
          elsif ($colon_array[0] eq "extractedallelenew") { $extractedallelenew{$joinkey} = $colon_array[1]; }
          elsif ($colon_array[0] eq "newmutant") { $newmutant{$joinkey} = $colon_array[1]; }
          elsif ($colon_array[0] eq "sequencechange") { $sequencechange{$joinkey} = $colon_array[1]; }
          elsif ($colon_array[0] eq "genesymbols") { $genesymbols{$joinkey} = $colon_array[1]; }
          elsif ($colon_array[0] eq "geneproduct") { $geneproduct{$joinkey} = $colon_array[1]; }
          elsif ($colon_array[0] eq "structurecorrection") { $structurecorrection{$joinkey} = $colon_array[1]; }
          elsif ($colon_array[0] eq "sequencefeatures") { $sequencefeatures{$joinkey} = $colon_array[1]; }
          elsif ($colon_array[0] eq "cellname") { $cellname{$joinkey} = $colon_array[1]; }
          elsif ($colon_array[0] eq "cellfunction") { $cellfunction{$joinkey} = $colon_array[1]; }
          elsif ($colon_array[0] eq "ablationdata") { $ablationdata{$joinkey} = $colon_array[1]; }
          elsif ($colon_array[0] eq "newsnp") { $newsnp{$joinkey} = $colon_array[1]; }
          elsif ($colon_array[0] eq "stlouissnp") { $stlouissnp{$joinkey} = $colon_array[1]; }
          elsif ($colon_array[0] eq "goodphoto") { $goodphoto{$joinkey} = $colon_array[1]; }
          elsif ($colon_array[0] eq "comment") { $comment{$joinkey} = $colon_array[1]; }
          else { print "WARN : $colon_array[0] not a valid entry\n"; }
#           print OUT "\$result = \$conn->exec( \"INSERT INTO $colon_array[0] VALUES ('$joinkey', '$colon_array[1]')\")\n";
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

	# for each of the keys, i.e. pubID, print out stuff for postgres
foreach $_ (sort keys %joinkey) {
#   my $key = ""; my $keyvalue = "";
  if ($_ =~ m/cgc(\d+)/) { 
#     print OUT "\$result = \$conn->exec( \"INSERT INTO cgc VALUES ('$_', '$1')\");\n";
	# $key = 'cgc'; $keyvalue = $1; 
  } elsif ($_ =~ m/pmid(\d+)/) { 
    print OUT "\$result = \$conn->exec( \"INSERT INTO pmid VALUES ('$_', '$1')\");\n";
	# $key = 'pmid'; $keyvalue = $1; 
  } else { print "WARN : not cgc nor pmid : $_;\n"; next; }

  print OUT "\$result = \$conn->exec( \"INSERT INTO curator VALUES ('$_', 'Raymond Lee')\");\n";

  if ($newsymbol{$_}) {
    print OUT "\$result = \$conn->exec( \"INSERT INTO newsymbol VALUES ('$_', '$newsymbol{$_}')\");\n";
  } else {
    print OUT "\$result = \$conn->exec( \"INSERT INTO newsymbol VALUES ('$_', NULL)\");\n";
  }

  if ($synonym{$_}) {
    print OUT "\$result = \$conn->exec( \"INSERT INTO synonym VALUES ('$_', '$synonym{$_}')\");\n";
  } else {
    print OUT "\$result = \$conn->exec( \"INSERT INTO synonym VALUES ('$_', NULL)\");\n";
  }

  if ($mappingdata{$_}) {
    print OUT "\$result = \$conn->exec( \"INSERT INTO mappingdata VALUES ('$_', '$mappingdata{$_}')\");\n";
  } else {
    print OUT "\$result = \$conn->exec( \"INSERT INTO mappingdata VALUES ('$_', NULL)\");\n";
  }

  if ($genefunction{$_}) {
    print OUT "\$result = \$conn->exec( \"INSERT INTO genefunction VALUES ('$_', '$genefunction{$_}')\");\n";
  } else {
    print OUT "\$result = \$conn->exec( \"INSERT INTO genefunction VALUES ('$_', NULL)\");\n";
  }

  if ($associationequiv{$_}) {
    print OUT "\$result = \$conn->exec( \"INSERT INTO associationequiv VALUES ('$_', '$associationequiv{$_}')\");\n";
  } else {
    print OUT "\$result = \$conn->exec( \"INSERT INTO associationequiv VALUES ('$_', NULL)\");\n";
  }

  if ($associationnew{$_}) {
    print OUT "\$result = \$conn->exec( \"INSERT INTO associationnew VALUES ('$_', '$associationnew{$_}')\");\n";
  } else {
    print OUT "\$result = \$conn->exec( \"INSERT INTO associationnew VALUES ('$_', NULL)\");\n";
  }

  if ($expression{$_}) {
    print OUT "\$result = \$conn->exec( \"INSERT INTO expression VALUES ('$_', '$expression{$_}')\");\n";
  } else {
    print OUT "\$result = \$conn->exec( \"INSERT INTO expression VALUES ('$_', NULL)\");\n";
  }

  if ($rnai{$_}) {
    print OUT "\$result = \$conn->exec( \"INSERT INTO rnai VALUES ('$_', '$rnai{$_}')\");\n";
  } else {
    print OUT "\$result = \$conn->exec( \"INSERT INTO rnai VALUES ('$_', NULL)\");\n";
  }

  if ($transgene{$_}) {
    print OUT "\$result = \$conn->exec( \"INSERT INTO transgene VALUES ('$_', '$transgene{$_}')\");\n";
  } else {
    print OUT "\$result = \$conn->exec( \"INSERT INTO transgene VALUES ('$_', NULL)\");\n";
  }

  if ($overexpression{$_}) {
    print OUT "\$result = \$conn->exec( \"INSERT INTO overexpression VALUES ('$_', '$overexpression{$_}')\");\n";
  } else {
    print OUT "\$result = \$conn->exec( \"INSERT INTO overexpression VALUES ('$_', NULL)\");\n";
  }

  if ($mosaic{$_}) {
    print OUT "\$result = \$conn->exec( \"INSERT INTO mosaic VALUES ('$_', '$mosaic{$_}')\");\n";
  } else {
    print OUT "\$result = \$conn->exec( \"INSERT INTO mosaic VALUES ('$_', NULL)\");\n";
  }

  if ($antibody{$_}) {
    print OUT "\$result = \$conn->exec( \"INSERT INTO antibody VALUES ('$_', '$antibody{$_}')\");\n";
  } else {
    print OUT "\$result = \$conn->exec( \"INSERT INTO antibody VALUES ('$_', NULL)\");\n";
  }

  if ($extractedallelename{$_}) {
    print OUT "\$result = \$conn->exec( \"INSERT INTO extractedallelename VALUES ('$_', '$extractedallelename{$_}')\");\n";
  } else {
    print OUT "\$result = \$conn->exec( \"INSERT INTO extractedallelename VALUES ('$_', NULL)\");\n";
  }

  if ($extractedallelenew{$_}) {
    print OUT "\$result = \$conn->exec( \"INSERT INTO extractedallelenew VALUES ('$_', '$extractedallelenew{$_}')\");\n";
  } else {
    print OUT "\$result = \$conn->exec( \"INSERT INTO extractedallelenew VALUES ('$_', NULL)\");\n";
  }

  if ($newmutant{$_}) {
    print OUT "\$result = \$conn->exec( \"INSERT INTO newmutant VALUES ('$_', '$newmutant{$_}')\");\n";
  } else {
    print OUT "\$result = \$conn->exec( \"INSERT INTO newmutant VALUES ('$_', NULL)\");\n";
  }

  if ($sequencechange{$_}) {
    print OUT "\$result = \$conn->exec( \"INSERT INTO sequencechange VALUES ('$_', '$sequencechange{$_}')\");\n";
  } else {
    print OUT "\$result = \$conn->exec( \"INSERT INTO sequencechange VALUES ('$_', NULL)\");\n";
  }

  if ($genesymbols{$_}) {
    print OUT "\$result = \$conn->exec( \"INSERT INTO genesymbols VALUES ('$_', '$genesymbols{$_}')\");\n";
  } else {
    print OUT "\$result = \$conn->exec( \"INSERT INTO genesymbols VALUES ('$_', NULL)\");\n";
  }

  if ($geneproduct{$_}) {
    print OUT "\$result = \$conn->exec( \"INSERT INTO geneproduct VALUES ('$_', '$geneproduct{$_}')\");\n";
  } else {
    print OUT "\$result = \$conn->exec( \"INSERT INTO geneproduct VALUES ('$_', NULL)\");\n";
  }

  if ($structurecorrection{$_}) {
    print OUT "\$result = \$conn->exec( \"INSERT INTO structurecorrection VALUES ('$_', '$structurecorrection{$_}')\");\n";
  } else {
    print OUT "\$result = \$conn->exec( \"INSERT INTO structurecorrection VALUES ('$_', NULL)\");\n";
  }

  if ($sequencefeatures{$_}) {
    print OUT "\$result = \$conn->exec( \"INSERT INTO sequencefeatures VALUES ('$_', '$sequencefeatures{$_}')\");\n";
  } else {
    print OUT "\$result = \$conn->exec( \"INSERT INTO sequencefeatures VALUES ('$_', NULL)\");\n";
  }

  if ($cellname{$_}) {
    print OUT "\$result = \$conn->exec( \"INSERT INTO cellname VALUES ('$_', '$cellname{$_}')\");\n";
  } else {
    print OUT "\$result = \$conn->exec( \"INSERT INTO cellname VALUES ('$_', NULL)\");\n";
  }

  if ($cellfunction{$_}) {
    print OUT "\$result = \$conn->exec( \"INSERT INTO cellfunction VALUES ('$_', '$cellfunction{$_}')\");\n";
  } else {
    print OUT "\$result = \$conn->exec( \"INSERT INTO cellfunction VALUES ('$_', NULL)\");\n";
  }

  if ($ablationdata{$_}) {
    print OUT "\$result = \$conn->exec( \"INSERT INTO ablationdata VALUES ('$_', '$ablationdata{$_}')\");\n";
  } else {
    print OUT "\$result = \$conn->exec( \"INSERT INTO ablationdata VALUES ('$_', NULL)\");\n";
  }

  if ($newsnp{$_}) {
    print OUT "\$result = \$conn->exec( \"INSERT INTO newsnp VALUES ('$_', '$newsnp{$_}')\");\n";
  } else {
    print OUT "\$result = \$conn->exec( \"INSERT INTO newsnp VALUES ('$_', NULL)\");\n";
  }

  if ($stlouissnp{$_}) {
    print OUT "\$result = \$conn->exec( \"INSERT INTO stlouissnp VALUES ('$_', '$stlouissnp{$_}')\");\n";
  } else {
    print OUT "\$result = \$conn->exec( \"INSERT INTO stlouissnp VALUES ('$_', NULL)\");\n";
  }

  if ($goodphoto{$_}) {
    print OUT "\$result = \$conn->exec( \"INSERT INTO goodphoto VALUES ('$_', '$goodphoto{$_}')\");\n";
  } else {
    print OUT "\$result = \$conn->exec( \"INSERT INTO goodphoto VALUES ('$_', NULL)\");\n";
  }

  if ($comment{$_}) {
    print OUT "\$result = \$conn->exec( \"INSERT INTO comment VALUES ('$_', '$comment{$_}')\");\n";
  } else {
    print OUT "\$result = \$conn->exec( \"INSERT INTO comment VALUES ('$_', NULL)\");\n";
  }

} # foreach $_ (sort keys %joinkey) 


# foreach $_ (sort keys %tags) {
#   print $_ . " : " . $tags{$_} . "\n";
# } # foreach $_ (sort keys %tags) 


