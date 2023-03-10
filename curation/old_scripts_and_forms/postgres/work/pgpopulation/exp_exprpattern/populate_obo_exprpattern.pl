#!/usr/bin/perl -w

# populate obo_name_pic_exprpattern and obo_data_pic_exprpattern. 
# this is temporary until expr pattern OA is live.  then delete these tables.
# looks like it has errors, but reads in okay  2010 10 29

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my %tags;
my @tags = qw( Gene Pattern Reference Reporter_gene Life_stage Anatomy_term GO_term );
foreach my $tag (@tags) { $tags{$tag}++; }

my @pgcommands;
push @pgcommands, "DELETE FROM obo_name_pic_exprpattern ;";
push @pgcommands, "DELETE FROM obo_data_pic_exprpattern ;";

my %anat_to_name;

my $result = $dbh->prepare( "SELECT * FROM obo_name_app_anat_term ;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $anat_to_name{$row[0]} = "$row[1] is $row[0]"; }


$/ = "";
my $infile = 'ExprWS221.ace';
open (IN, "<$infile") or die "Cannot open $infile : $!";
my $junk = <IN>;		# skip non-entry
while (my $para = <IN>) {
  my (@lines) = split/\n/, $para;
  my $header = shift @lines;
  my ($id) = $header =~ m/Expr_pattern : \"(.*?)\"/;
  unless ($id) { print "ERR NO ID $para\n"; }
  push @pgcommands, "INSERT INTO obo_name_pic_exprpattern VALUES ( '$id', '$id' );";
  my @data;
  push @data, "id : $id";
  foreach my $line (@lines) {  
    if ($line =~ m/^([\w]+)\s+\"/) { 
      my ($tag) = $1;
      if ($tags{$tag}) { 
        $line =~ s/\t / : /;
        if ($tag eq 'Anatomy_term') {
          my ($value) = $line =~ m/(WBbt:\d+)/;
          if ($anat_to_name{$value}) { my $new_value = $anat_to_name{$value}; $line =~ s/$value/$new_value/; } }
        push @data, "$line"; }
    }
#     else { print "NO MATCH $line LINE\n"; }
  }
  my $data = join"\n", @data;
  $data =~ s/\'/''/g;
  push @pgcommands, "INSERT INTO obo_data_pic_exprpattern VALUES ( '$id', '$data' );";
} # while (my $para = <IN>)
close (IN) or die "Cannot close $infile : $!";
$/ = "\n";

foreach my $command (@pgcommands) {
  print "$command\n";
# UNCOMMENT TO POPULATE, looks like it has errors, but reads in okay  2010 10 29
#   my $result = $dbh->do( $command );
}

__END__

my $result = $dbh->prepare( "SELECT * FROM two_comment WHERE two_comment ~ ?" );
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

Expr_pattern : "Expr1"
Gene     "WBGene00001386"
Clone    "UL#4F5"
Life_stage       "adult hermaphrodite"
Anatomy_term     "WBbt:0005821" Certain
Anatomy_term     "WBbt:0005813" Certain
Reporter_gene    "Partial Sau3A restriction enzyme fragment of C.elegans genomic  DNA cloned into the BamHI site of pPD22.11, creating a lacZ  translational fusion."
Reporter_gene    "The sequence of the point of fusion to lacZ is -- TAAAATATTGCAGTAATGAGATC\/lacZ"
Pattern  "Body wall muscle cells and vulval muscle cells of adult  hermaphrodites. Beta-galactosidase is nuclear localized"
Picture  "ul3_bwm.jpeg"
Picture  "ul3_vm.jpeg"
Author   "Hope IA"
Date     1990-04
Strain   "UL3"
Reference        "WBPaper00001469"
Curated_by       "HX"

