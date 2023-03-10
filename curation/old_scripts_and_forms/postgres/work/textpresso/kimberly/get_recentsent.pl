#!/usr/bin/perl

# take the newest and the previous set of good_sentences_file and get only the
# recent sentences and put them in a recent_sentences_file.date.time  2007 07 18

use strict;

# my @good_sentence_file = </home/azurebrd/work/get_kimberly_go_gene_component_verb_localization/ccc_datafiles/good_sentences_file.*>;
my @good_sentence_file = </var/www/html/azurebrd/ccc_datafiles/good_sentences_file.*>;

my $new_file = pop @good_sentence_file;
my $last_file = pop @good_sentence_file;

# temporary for testing rearranging by paper -> sentence -> score instead of paper -> score -> sentence
# $last_file = '/var/www/html/azurebrd/ccc_datafiles/good_sentences_file.20071126.0200';
# $new_file = 'out_pap_sent_score';
# my $outfile = 'recent_out_now';
# my $filename = 'thefilename';

my %last;
open (LAS, "<$last_file") or die "Cannot open $last_file : $!";
while (my $line = <LAS>) {
  chomp $line;
  $line =~ s/^\d+\t//g;
  $last{$line}++;
} # while (my $line = <LAS>)
close (LAS) or die "Cannot close $new_file : $!";

my $outfile = $new_file; 
$outfile =~ s/good_sentences_file/recent_sentences_file/;
my ($filename) = $outfile =~ m/(recent_sentences_file\.[\d\.]{13})/;

# my $recent_file = '/home/azurebrd/work/get_kimberly_go_gene_component_verb_localization/ccc_datafiles/recent_cccfile';
my $recent_file = '/var/www/html/azurebrd/ccc_datafiles/recent_cccfile';
open (OUT, ">$recent_file") or die "Cannot create $recent_file : $!";
print OUT "$filename\n";
close (OUT) or die "Cannot close $recent_file : $!";


open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
my $count = 0;

my $to_out; my $title_abs;	# put titles and abstracts at the end

open (NEW, "<$new_file") or die "Cannot open $new_file : $!";
while (my $line = <NEW>) {
  chomp $line;
  $line =~ s/^\d+\t//g;
  next if ($line =~ m/^Time/);
  unless ($last{$line}) {
    if ( ($line =~ m/^TITLE/) || ( $line =~ m/^ABSTRACT/) ) { $title_abs .= "$filename\t$line\n"; }
      else {
        $count++;
        $to_out .= "$filename\t$count\t$line\n"; } }
} # while (my $line = <NEW>)
close (NEW) or die "Cannot close $new_file : $!";

if ($to_out) { print OUT $to_out; print OUT "$title_abs"; }
  else { print OUT "No data for $filename\n"; }
close (OUT) or die "Cannot close $outfile : $!";

