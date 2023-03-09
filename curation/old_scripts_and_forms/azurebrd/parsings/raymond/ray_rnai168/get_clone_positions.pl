#!/usr/bin/perl

use strict;
use Bio::DB::GFF;
use Getopt::Long;

# my $DSN = 'dbi:mysql:elegans;host=minerva.caltech.edu';
# my $DSN = 'dbi:mysql:dicty;host=minerva.caltech.edu';
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


# my $db =  Bio::DB::GFF->new(-dsn=>$DSN) or die "Can't open database: $@";
# my $db =  Bio::DB::GFF->new(	-dsn	=>	$DSN,
# 				-user	=>	'azurebrd'
# 			   ) or die "Can't open database: $@";
my $db =  Bio::DB::GFF->new(	-dsn	=>	'dbi:mysql:elegans',
				-user	=>	'root',
				-pass   =>	'elegans'
			   ) or die "Can't open database: $@";

$db->absolute(1);

foreach (<>) {
  chomp;
  my $clone = $_;
# print "CLONE $clone\n";
# my @thing = $db->get_feature_by_name("$clone.5");	# 5' end
# foreach my $thing (@thing) { print "THING $thing\n"; }
# @thing = $db->get_feature_by_name("$clone.3");		# 3' end
# foreach my $thing (@thing) { print "OTHING $thing\n"; }
  my @left  = grep {/BLAT_EST_BEST/} $db->get_feature_by_name("$clone.5");  # 5' end
  my @right = grep {/BLAT_EST_BEST/} $db->get_feature_by_name("$clone.3");  # 3' end
# foreach my $left (@left) { print "LEFT : $left\n"; }
# foreach my $right (@right) { print "RIGHT : $right\n"; }
# print "SKIP $clone\n" unless @left || @right;
  next unless @left || @right;
  my ($ref,$start,$end);
 LEFT:
  for my $left (@left) {
    next if $left->length > 5000;
    for my $right (@right) {
      next if $right->length > 5000;
      if ($left->ref eq $right->ref && abs($left->start-$right->end) < 50_000) {
	$ref   = $left->ref;
	$start = $left->low    < $right->low  ? $left->low    : $right->low;
	$end   = $left->high   > $right->high ? $left->high   : $right->high;
# print "GOT STUFF : REF $ref : START $start : END $end\n";
	last LEFT;
      }
    }
  }

  # Oops, didn't get one.  Probably because one or the other ends are missing.
  # choose one
  unless ($ref) {
    my $e = $left[0] || $right[0];
    ($ref,$start,$end) = ($e->ref,$e->start,$e->end);
    ($start,$end)      = ($end,$start) if $start < $end;
  }

  unless ($ref) {
    print STDERR "$clone: not found\n";
    next;
  }

# print "REF $ref : START $start : END $end\n";

  my $full_segment = $db->segment($ref,$start,$end);
  my @canonical = $full_segment->features('Sequence:Genomic_canonical','Sequence:Link');
  my $shortest_canonical;
  for my $c (@canonical) {
    next unless $c->contains($full_segment);  # must contain segment completely
    $shortest_canonical = $c if !defined($shortest_canonical) || $c->length < $shortest_canonical->length;
  }
  my @genes = map {$_->name} $full_segment->features('Sequence:curated','transcript:RNA');

  $full_segment->ref($shortest_canonical);
  print join("\t",$clone,$shortest_canonical->name,$full_segment->low,$full_segment->high,$full_segment->length,@genes),"\n";

}

1;
