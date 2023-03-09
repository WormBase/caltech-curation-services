#!/usr/bin/perl

use Bio::DB::GFF;

my $db = Bio::DB::GFF->new(-dsn   => 'dbi:mysql:dicty',
                           -fasta => '/net/share/elegans-fasta',
                           -user  => 'root',
                           -pass  => 'elegans');

my $segment = $db->segment('CHROMOSOME_I',50000=>60000);

my $gene1 = $db->segment(Sequence => 'M7.1');
my $gene2 = $db->segment(Sequence => 'M7.5');

print "GEN $gene1 $gene2 GEN\n";

# $gene2->ref($gene1);
# 
# print $gene2->start,"\n";
# print $gene2->end,"\n";


# print "DNA" . $segment->dna . "DNA\n";
# 
# my @features = $segment->features;
# 
# my @introns  = $segment->features('intron');
# my @inexon   = $segment->features('intron','exon','CDS');
# 
# my @curated  = $segment->features('intron:curated','exon:curated');
# 
# foreach (@introns) {
#    print "REF : ",$_->ref,"\n";
#    print "STA : ",$_->start,"\n";
#    print "STO : ",$_->stop,"\n";
#    print "NAM : ",$_->name,"\n";
#    print "DNA : ",$_->dna,"\n";
# }


my $length      = $segment->length;
my $start       = $segment->start;
my $end         = $segment->end;
my @features    = $segment->features;
my $dna         = $segment->dna;
my @types       = $segment->types;
my @things      = $segment->features('intron','exon');
my @curated     = $segment->features('curated:intron','curated:exon');
my @transcripts = $segment->features('transcript');

# print "LEN $length LEN\n";
# print "START $start START\n";
# print "END $end END\n";
# foreach $_ (@features) { print "FEA $_ FEA\n"; }
# print "DNA $dna DNA\n";
# foreach $_ (@types) { print "TYPE $_ TYPE\n"; }
# foreach $_ (@things) { print "THING $_ THING\n"; }
# foreach $_ (@curated) { print "CUR $_ CUR\n"; }
# foreach $_ (@transcripts) { print "TRAN $_ TRAN\n"; }
