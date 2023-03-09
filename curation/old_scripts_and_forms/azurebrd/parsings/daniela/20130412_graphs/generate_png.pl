#!/usr/bin/perl

# from a tab-delimited file, generate images for each gene, mapping to locus / seqname
# for Daniela.  2013 05 12

use strict;
use DBI;
use Encode qw( from_to is_utf8 );

use GD::Graph::bars; # generate statistics graphs
# use GD::Graph::lines; # generate statistics graphs
# use GD::Graph::area;    # generate statistics graphs

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my %loci;
my $result = $dbh->prepare( "SELECT * FROM gin_seqname" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $loci{"WBGene$row[0]"} = $row[1]; } }
$result = $dbh->prepare( "SELECT * FROM gin_locus" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $loci{"WBGene$row[0]"} = $row[1]; } }

my @x = qw( 0 23 41 53 66 83 101 122 143 );

my $xlabel = 'Time (min)';
my $ylabel = 'Expression level (log 2 ratio)';
my $ptitle = 'Early embryonic development expression profile of';

my $infile = '00005767ExprGraph.csv';
open (IN, "<$infile") or die "Cannot open $infile : $!";
my $headers = <IN>;
while (my $line = <IN>) {
  chomp $line;
  my (@array) = split/\t/, $line;
  my $gene = shift @array;
  my $locus = $gene;
  if ($loci{$gene}) { $locus = $loci{$gene}; }
  my $title = $ptitle . " " . $locus;				# can't have multiline title for some reason
  my @data = (\@x, \@array);
#   my $xsize = scalar(@x) * 60;				# to scale by amount of points
  my $xsize = 700;
  my $mygraph = GD::Graph::bars->new($xsize, 700);
  $mygraph->set(
    x_label     => $xlabel,
    x_label_position     => 1/2,
    y_label     => $ylabel,
#     y2_label    => $locus,					# probably only works if there were two sets of data
    y_min_value => 0,
    line_width  => 3,
    title       => $title,
    dclrs => [ qw(green pink blue cyan) ],			# set colors for datasets 1-4 (only 1 now)
  ) or warn $mygraph->error;
#   $mygraph->set_legend(qw($gene)); 				# gives an actual legend
  my $myimage = $mygraph->plot(\@data) or warn $mygraph->error;
  my $outfile = $gene . '.png';
  open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
#   print "Content-type: image/png\n\n";			# to generate on webserver on the fly
  print OUT $myimage->png;
#   print OUT $myimage->jpeg;					# to generate a jpg (rename outfile), haven't tested it
  close (OUT) or die "Cannot close $outfile : $!";
  last;								# comment out to generate all
} # while (my $line = <IN>)
close (IN) or die "Cannot close $infile : $!";

