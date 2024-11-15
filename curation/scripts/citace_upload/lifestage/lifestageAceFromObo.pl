#!/usr/bin/env perl

# for Daniela to download a Lifestage .obo file and generate a .ace file.  2013 06 17
#
# added part_of and starts_at_end_of.  2014 03 27
#
# modified to suppress additional synonym junk, and print paper_evidence of definition.  2019 02 05
#
# modified to allow WS### as command line parameter for chris_one_button.pl dumper script.  2024 10 07
#
# generate obo file that was downloaded for one button script to transfer to Data_for_Ontology.  2024 11 15


use strict;
use LWP::Simple;

# my $url = 'https://github.com/obophenotype/c-elegans-development-ontology/raw/vWS288/wbls.obo';

my $url = '';
if ($ARGV[0]) {
  # chris_one_button.pl passing WS as parameter to construct url
  $url = 'https://github.com/obophenotype/c-elegans-development-ontology/raw/v' . $ARGV[0] . '/wbls.obo'; }
else {
  # Chris needs to be able to change the url, so using an external file for it
  my $infile = 'obo_url';
  open (IN, "<$infile") or die "Cannot open $infile : $!";
  my $url = <IN>;
  chomp $url;
  close (IN) or die "Cannot open $infile : $!"; }

print qq(using url $url\n);

my $page = get $url;
my $obofile = 'development_ontology.' . $ARGV[0] . '.obo';
open (OBO, ">$obofile") or die "Cannot create $obofile : $!";
print OBO $page;
close (OBO) or die "Cannot close $obofile : $!";

my @objects = split/\n\n/, $page;

my $header = shift @objects;

my $outfile = 'lifestage.ace';
open (OUT, ">$outfile") or die "Cannot create $outfile : $!";

foreach my $obj (@objects) {
  my ($id, $name, $def, $isa, $rel) = ('', '', '', '', '');
  if ($obj =~ m/id: (WBls:\d+)/) {
    my $ace;
    $id = $1;
    $ace .= qq(Life_stage : "$id"\n);
    if ($obj =~ m/name: (.*)/) { $ace .= qq(Public_name\t"$1"\n); }
    if ($obj =~ m/def: "(.*)"(.*)/) { 
      my $def = $1;
      my (@paps) = $2 =~ m/(WBPaper\d+)/g;
      if (scalar @paps > 1) { print qq(ERROR $id has multiple papers @paps\n); }
        elsif (scalar @paps < 1) { $ace .= qq(Definition\t"$def"\n); }
        else {
          foreach my $pap (@paps) {
            $ace .= qq(Definition\t"$def"\tPaper_evidence\t\"$pap\"\n); } }
    }
    if ($obj =~ m/is_a: (WBls:\d+)/) { $ace .= qq(Contained_in\t"$1"\n); }
    if ($obj =~ m/relationship: preceded_by (WBls:\d+)/) { $ace .= qq(Preceded_by\t"$1"\n); }
#     if ($obj =~ m/relationship: part_of (WBls:\d+)/) { $ace .= qq(part_of\t"$1"\n); }
#     if ($obj =~ m/part_of: (WBls:\d+)/) { $ace .= qq(Contained_in\t"$1"\n); }
    if ($obj =~ m/relationship: part_of (WBls:\d+)/) { $ace .= qq(Contained_in\t"$1"\n); }
#     if ($obj =~ m/relationship: starts_at_end_of (WBls:\d+)/) { $ace .= qq(starts_at_end_of\t"$1"\n); }
    if ($obj =~ m/relationship: starts_at_end_of (WBls:\d+)/) { $ace .= qq(Preceded_by\t"$1"\n); }
    if ($obj =~ m/synonym: "(.*)"/) { $ace .= qq(Other_name\t"$1"\n); }
    if ($obj =~ m/comment: (.*)/) { $ace .= qq(Remark\t"$1"\n); }
    $ace .= qq(\n);
    print OUT qq($ace);
  }
} # foreach my $obj (@objects)

close (OUT) or die "Cannot close $outfile : $!";


__END__


OBO
id: WBls:0000007
name: 2-cell embryo
def: "0-20min after first cleavage at 20 Centigrade.  Contains 2 cells." [wb:wjc]
is_a: WBls:0000005 ! blastula embryo
relationship: preceded_by WBls:0000006 ! 1-cell embryo

and should be converted in .ace so that it becomes

.ace
Life_stage : "WBls:0000007"
Public_name	"2-cell embryo"
Definition	"0-20min after first cleavage at 20 Centigrade.  Contains 2 cells."
Contained_in	"WBls:0000005"
Preceded_by	"WBls:0000006"


the conversions are
id: -> Life_stage :
name: -> Public_name
def: -> Definition
is_a: -> Contained_in
relationship: -> Preceded_by


