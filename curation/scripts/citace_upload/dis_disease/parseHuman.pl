#!/usr/bin/env perl

# download obo file from sourceforge and generate HumanDO.ace for Ranjana  2012 12 05
#
# skip obsolete terms for Ranjana 2013 03 22
#
# changed .obo url 2013 08 08
#
# changed .obo url 2017 02 24
#
# changed .obo url 2018 08 29
#
# output to .ace file like before, but also to files/HumanDO.ace.<date>  2023 03 27


use strict;
use warnings;
use LWP::Simple;
use Jex;

  # get obo file each time
# my $url = 'http://diseaseontology.svn.sourceforge.net/viewvc/diseaseontology/trunk/HumanDO.obo';
# my $url = 'http://www.berkeleybop.org/ontologies/doid.obo';	# changed URL for Ranjana 2013 08 08
# my $url = 'https://raw.githubusercontent.com/DiseaseOntology/HumanDiseaseOntology/master/src/ontology/doid-non-classified.obo';	# changed URL for Ranjana 2017 02 24
my $url = 'http://purl.obolibrary.org/obo/doid.obo';	# changed URL for Ranjana 2018 08 29
my $all_file = get $url;

  # use the obo file that was pre-downloaded to the directory
# my $infile = 'HumanDO.obo';
# $/ = undef;
# open (IN, "<$infile") or die "Cannot open $infile : $!";
# my $all_file = <IN>;
# close (IN) or die "Cannot close $infile : $!";

  # Ranjana wants tags to be dumped in a certain order, so only dump the ones that are ordered.  If any 
my @orderedTags = qw( Name Status Alternate_id Definition Comment Broad Exact Narrow Related Is_a Type );
push @orderedTags, 'Database	"OMIM"	"Disease"';

my $date = &getSimpleDate();

my $outfile = 'HumanDO.ace';
my $outfile2 = 'files/HumanDO.ace.' . $date;
open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
open (OU2, ">$outfile2") or die "Cannot create $outfile2 : $!";

# my (@objs) = split/\n\[Term\]\n/, $all_file;	# there are some non-[Term] paragraphs, so don't do it like this
my (@objs) = split/\n\n/, $all_file;

my %hash;
foreach my $obj (@objs) {
#   next unless ($obj =~ m/^id:/);				# not splitting on [Term] so first line now has [<whatever>]
  next if ($obj =~ m/is_obsolete: true/);		# skip obsolete terms for Ranjana 2013 03 22
  my @lines = split/\n/, $obj;
  my $id = ''; my $name = ''; my $status = '';
  my $is_term = shift @lines;
  next unless ($is_term =~ m/^\[Term\]/);
  my $id_line = shift @lines;
  if ($id_line =~ m/id: (DOID:\d+)$/) { $id = $1; }
    else { print "ERR : no id for $obj\n"; next; }
  my $name_line = shift @lines;
  if ($name_line =~ m/name: (.*)$/) {            my $val = '"'.$1.'"'; $hash{$id}{'Name'}{$val}++; }
    else { print "ERR : no name for $obj\n"; next; }
  if ($obj =~ m/is_obsolete/) { $status = 'Obsolete'; } else { $status = 'Valid'; }
  $hash{$id}{'Status'}{$status}++;
  foreach my $line (@lines) {
    if ($line =~ m/alt_id: (.*)$/) {          my $val = '"'.$1.'"'; $hash{$id}{'Alternate_id'}{$val}++; }   
    if ($line =~ m/def: \"(.*?)\"/) {         my $val = '"'.$1.'"'; $hash{$id}{'Definition'}{$val}++; }   
    if ($line =~ m/comment: (.*?\.)/) {       my $val = '"'.$1.'"'; $hash{$id}{'Comment'}{$val}++; }   
    if ($line =~ m/synonym: (.*?) BROAD/) {   my $val = $1;         $hash{$id}{'Broad'}{$val}++; }   
    if ($line =~ m/synonym: (.*?) EXACT/) {   my $val = $1;         $hash{$id}{'Exact'}{$val}++; }   
    if ($line =~ m/synonym: (.*?) NARROW/) {  my $val = $1;         $hash{$id}{'Narrow'}{$val}++; }   
    if ($line =~ m/synonym: (.*?) RELATED/) { my $val = $1;         $hash{$id}{'Related'}{$val}++; }   
    if ($line =~ m/is_a: (DOID:\d+)/) {       my $val = '"'.$1.'"'; $hash{$id}{'Is_a'}{$val}++; }   
    if ($line =~ m/xref: OMIM:(\d+)/) {       my $val = '"'.$1.'"'; $hash{$id}{'Database	"OMIM"	"Disease"'}{$val}++; }   
    if ($line =~ m/subset: (GOLD)/) {         $hash{$id}{'Type'}{$1}++; }   
    if ($line =~ m/subset: (gram-negative_bacterial_infectious_disease)/) {         $hash{$id}{'Type'}{'Gram_negative_bacterial_infectious_disease'}++; }  
    if ($line =~ m/subset: (gram-positive_bacterial_infectious_disease)/) {         $hash{$id}{'Type'}{'Gram_positive_bacterial_infectious_disease'}++; }  
    if ($line =~ m/subset: (sexually_transmitted_infectious_disease sexually_transmitted_infectious_disease)/) { $hash{$id}{'Type'}{'Sexually_transmitted_infectious_disease sexually_transmitted_infectious_disease'}++; }   
    if ($line =~ m/subset: (tick-borne_infectious_disease)/) { $hash{$id}{'Type'}{'Tick_borne_infectious_disease'}++; }   
    if ($line =~ m/subset: (zoonotic_infectious_disease)/) {   $hash{$id}{'Type'}{'Zoonotic_infectious_disease'}++; }   
  } # foreach my $line (@lines)
} # foreach my $obj (@objs)

foreach my $id (sort keys %hash) {
  print OUT qq(DO_term : "$id"\n);
  print OU2 qq(DO_term : "$id"\n);
  foreach my $tag (@orderedTags) {						# only dump tags that have been ordered
    next unless ($hash{$id}{$tag});
    foreach my $value (sort keys %{ $hash{$id}{$tag} }) {
      $value =~ s/[^[:ascii:]]+//g;						# strip out non-ascii characters
      print OUT qq($tag\t$value\n);
      print OU2 qq($tag\t$value\n);
    } # foreach my $value (sort keys %{ $hash{$id}{$tag} })
  } # foreach my $tag (@orderedTags)
  print OUT qq(\n);
  print OU2 qq(\n);
} # foreach my $id (sort keys %hash)

close (OUT) or die "Cannot close $outfile : $!";
close (OU2) or die "Cannot close $outfile : $!";

__END__

