#!/usr/bin/env perl

# Generate all Chris .ace files and place where necessary, based on this document
# https://docs.google.com/document/d/1m5ZY52OGhGjOcnTmQ4vq9TE9LFnSoZiq0bMDJHcAfrM/edit?tab=t.0
#
# Still needs tace testing.  For Chris  2024 10 07
#
# Generate tace file to connect with tace and parse the files, sending output to screen.  2024 10 14


use strict;
use Jex;
use File::Path;


unless ($ARGV[0]) { print qq(Usage ./chris_one_button.pl WS###\n); die; }
my $ws = $ARGV[0];

my $output_dir = $ENV{CALTECH_CURATION_FILES_INTERNAL_PATH} . "/chris/" . $ws . "_Upload/";

if (-e $output_dir) { print qq($output_dir already exists, will overwrite files\n); }
  else { mkdir($output_dir, 0755); }

my $date = &getSimpleDate();
print qq($date\n);
my $directory = '';

my $tace_file = $ENV{CALTECH_CURATION_FILES_INTERNAL_PATH} . "/chris/test_read_chris.sh";
open (OUT, ">$tace_file") or die "Cannot create $tace_file : $!\n";
print OUT <<END_OUT;
cd /usr/caltech_curation_files/wdemo
export ACEDB=/usr/caltech_curation_files/wdemo
#Start reading files
/acedb/bin.LINUX_64/tace -tsuser 'chris' <<END_TACE
Read-models
y
END_OUT

print qq(Starting Gene Regulation\n);
$directory = $ENV{CALTECH_CURATION_FILES_INTERNAL_PATH} . "/chris/GeneReg_OA_Dumper/";
chdir ($directory) or die "Cannot chdir to $directory : $!";
`./use_package.pl`;
`cp ${directory}/files/*${date}* $output_dir`;
chdir ($output_dir) or die "Cannot chdir to $output_dir : $!";
`mv err.out.* ${ws}_grg_err.out`;
`mv gene_regulation* ${ws}_gene_regulation.ace`;
print OUT qq(Parse ${output_dir}${ws}_gene_regulation.ace\n);

print qq(Starting Life Stage\n);
$directory = $ENV{CALTECH_CURATION_FILES_INTERNAL_PATH} . "/chris/LifeStageOntology/";
chdir ($directory) or die "Cannot chdir to $directory : $!";
`./lifestageAceFromObo.pl $ws`;
`cp ${directory}/lifestage.ace ${output_dir}/${ws}_lifestage.ace`;
print OUT qq(Parse ${output_dir}${ws}_lifestage.ace\n);

print qq(Starting Phenotype\n);
$directory = $ENV{CALTECH_CURATION_FILES_INTERNAL_PATH} . "/chris/Phenotype_ACE_dumper/";
chdir ($directory) or die "Cannot chdir to $directory : $!";
`./dump_phenotype_ace2.pl $ws`;
`mv ${directory}/errorfile ${output_dir}/${ws}_phenotype_from_obo_errorfile`;
`cp ${directory}/phenotype_from_obo.ace ${output_dir}/${ws}_phenotype_from_obo.ace`;
print OUT qq(Parse ${output_dir}${ws}_phenotype_from_obo.ace\n);

print qq(Starting Pato OBO\n);
$directory = $ENV{CALTECH_CURATION_FILES_INTERNAL_PATH} . "/chris/Pato_OBO_Parsing/";
chdir ($directory) or die "Cannot chdir to $directory : $!";
`./parse_pato_obo_ace.pl`;
`cp ${directory}/pato.ace ${output_dir}/${ws}_pato.ace`;
print OUT qq(Parse ${output_dir}${ws}_pato.ace\n);

print qq(Starting RNAi\n);
$directory = $ENV{CALTECH_CURATION_FILES_INTERNAL_PATH} . "/chris/RNAi_OA_Dumper/";
chdir ($directory) or die "Cannot chdir to $directory : $!";
`./use_package.pl`;
`cp ${directory}/files/*${date}* $output_dir`;
chdir ($output_dir) or die "Cannot chdir to $output_dir : $!";
`mv err.out.* ${ws}_rnai_err.out`;
`mv rnai.ace.* ${ws}_rnai.ace`;
print OUT qq(Parse ${output_dir}${ws}_rnai.ace\n);

print qq(Starting Interaction\n);
$directory = $ENV{CALTECH_CURATION_FILES_INTERNAL_PATH} . "/chris/Interaction_OA_Dumper/";
chdir ($directory) or die "Cannot chdir to $directory : $!";
`./use_package.pl`;
`cp ${directory}/files/*${date}* $output_dir`;
chdir ($output_dir) or die "Cannot chdir to $output_dir : $!";
`mv err.out.* ${ws}_int_err.out`;
`mv interaction.ace.* ${ws}_interaction.ace`;
print OUT qq(Parse ${output_dir}${ws}_interaction.ace\n);

print qq(Starting Large scale Interaction\n);
$directory = $ENV{CALTECH_CURATION_FILES_INTERNAL_PATH} . "/chris/Interaction_OA_Dumper/Large_scale_interactions/";
chdir ($directory) or die "Cannot chdir to $directory : $!";
`./historicGeneReplacementLSInteraction.pl`;
`cp ${directory}/Large_scale_interactions.ace ${output_dir}/${ws}_Large_scale_interactions.ace`;
`cp ${directory}/ls_dead_genes.txt ${output_dir}/${ws}_ls_dead_genes.txt`;

my $ws_dir = $ENV{CALTECH_CURATION_FILES_INTERNAL_PATH} . "/Data_for_citace/Data_from_Chris/";
`cp ${output_dir}/*ace* $ws_dir`;


print OUT <<END_OUT;
quit
n
END_TACE
#End reading files.
END_OUT

close (OUT) or die "Cannot close $tace_file : $!";
chmod 0755, $tace_file;
my $ace_output = `$tace_file`;
print qq($ace_output\n);

__END__


binmode STDOUT, ':utf8';

my $date = &getSimpleSecDate();
my $start_time = time;
my $estimate_time = time + 697;
my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime($estimate_time);             # get time
if ($sec < 10) { $sec = "0$sec"; }    # add a zero if needed
print "START $date -> Estimate $hour:$min:$sec\n";

$date = &getSimpleDate();

use lib qw( /usr/lib/scripts/citace_upload/gene_regulation/ );
# use lib qw( /home/postgres/work/citace_upload/gene_regulation/ );
# use get_allele_phenotype_ace;
use get_gene_regulation_ace;

my $outfile = 'files/gene_regulation.ace.' . $date;
my $errfile = 'files/err.out.' . $date;

open (OUT, ">$outfile") or die "Cannot create $outfile : $!\n";
open (ERR, ">$errfile") or die "Cannot create $errfile : $!\n";

binmode OUT, ':utf8';

my ($all_entry, $err_text) = &getGeneRegulation('all');

# my ($all_entry, $err_text) = &getGeneRegulation('WBPaper00036358_lin-11');
# my ($all_entry, $err_text) = &getGeneRegulation('cgc2583_par');

print OUT "$all_entry\n";
if ($err_text) { print ERR "$err_text"; }

close (OUT) or die "Cannot close $outfile : $!";
close (ERR) or die "Cannot close $errfile : $!";

$date = &getSimpleSecDate();
my $end_time = time;
my $diff_time = $end_time - $start_time;
print "DIFF $diff_time\n";
print "END $date\n";

