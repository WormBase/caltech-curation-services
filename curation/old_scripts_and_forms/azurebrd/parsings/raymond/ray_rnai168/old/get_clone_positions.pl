#!/usr/bin/perl

use lib "$ENV{HOME}/bioperl-live";
use strict;
use Bio::DB::GFF;
use Getopt::Long;

# my $DSN = 'dbi:mysql:elegans;host=brie3.cshl.org';
my $DSN = 'dbi:mysql:dicty;host=minerva.caltech.edu';

GetOptions("dsn=s"    => \$DSN) or die <<USAGE;
Usage: $0 [options] <clone_names_file>

Use EST end mapping data to derive positions of cDNA clones listed in
indicated file.  File contains one clone name per line.

 Options:
      -dsn  <dsn> DSN of Bio::DB::GFF containing end mapping positions
                  (default $DSN)
USAGE
;

print "START\n";
# my $db =  Bio::DB::GFF->new(-dsn=>$DSN) or die "Can't open database: $@";
my $db = Bio::DB::GFF->new(	-adaptor => 'dbi::mysql',
				-dsn => 'dbi:mysql:dicty',
 				-user => 'azurebrd'
			  ) or die "Can't open database : $@";
$db->absolute(1);
print "CONNECTED\n";

foreach (<>) {
print "HERE\n";
  chomp;
  my $clone = $_;
print "CLONE $clone\n";
  my @left  = $db->segment("$clone.5");  # 5' end
  my @right = $db->segment("$clone.3");  # 3' end
  my ($ref,$start,$end);
 LEFT:
  for my $left (@left) {
    for my $right (@right) {
      if ($left->ref eq $right->ref && abs($left->start-$right->end) < 50_000) {
	$ref   = $left->ref;
	$start = $left->start < $right->start ? $left->start : $right->start;
	$end   = $left->end   > $right->end   ? $left->end   : $right->end;
	last LEFT;
      }
    }
  }

  # Oops, didn't get one.  Probably because one or the other ends are missing.
  # Choose the first one that contains a BLAT_EST_BEST feature.
  unless ($ref) {
    for my $e (@left,@right) {
      next unless $e->length < 2000;  # sanity check
      my @similarities = grep {$_->name =~ /$clone/} $e->features('similarity:BLAT_EST_BEST','similarity:BLAT_EST_OTHER');
      if (@similarities) {
	($ref,$start,$end) = ($e->ref,$e->start,$e->end);
	last;
      }
    }
  }

  unless ($ref) {
    print STDERR "$clone: not found\n";
    next;
  }

  my $full_segment = $db->segment($ref,$start,$end);
  my @canonical = $full_segment->features('Sequence:Genomic_canonical','Sequence:Link');
  my $shortest_canonical;
  for my $c (@canonical) {
    next unless $c->contains($full_segment);  # must contain segment completely
    $shortest_canonical = $c if !defined($shortest_canonical) || $c->length < $shortest_canonical->length;
  }

  $full_segment->ref($shortest_canonical);
  print join("\t",$clone,$shortest_canonical->name,$full_segment->start,$full_segment->stop),"\n";

}

print "THERE\n";
1;
