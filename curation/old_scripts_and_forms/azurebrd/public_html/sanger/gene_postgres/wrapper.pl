#!/usr/bin/perl -w

# running populate_gin.pl on all genes fails around 30000 (varies randomly)
# so trying multiple scripts getting them 1000 at a time.  2007 01 03

# cronjob set every thursday at 3am.  possibly not the right day of the week
# to coincide with new build, but not sure what day it should be.  2007 01 23
# 0 3 * * thu /home/azurebrd/public_html/sanger/gene_postgres/wrapper.pl


use Jex;

my $directory = '/home/azurebrd/public_html/sanger/gene_postgres';
chdir($directory) or die "Cannot go to $directory ($!)";

my $start = &getSimpleSecDate();

# my $outfile = 'gin_main.20070829.135730.pg';
my $outfile = 'gin_main.' . $start . '.pg';

 
open (PG, ">$outfile") or die "Cannot create $outfile : $!";
print PG "-- $start\n\n";

print PG "DELETE FROM gin_sequence;\n";
print PG "DELETE FROM gin_protein;\n";
print PG "DELETE FROM gin_seqprot;\n";
print PG "DELETE FROM gin_synonyms;\n";
print PG "DELETE FROM gin_seqname;\n";
print PG "DELETE FROM gin_molname;\n\n";

close (PG) or die "Cannot close $outfile : $!";


system(`/home/azurebrd/public_html/sanger/gene_postgres/populate_gin.pl 0000 $outfile`);
system(`/home/azurebrd/public_html/sanger/gene_postgres/populate_gin.pl 0001 $outfile`);
system(`/home/azurebrd/public_html/sanger/gene_postgres/populate_gin.pl 0002 $outfile`);
system(`/home/azurebrd/public_html/sanger/gene_postgres/populate_gin.pl 0003 $outfile`);
system(`/home/azurebrd/public_html/sanger/gene_postgres/populate_gin.pl 0004 $outfile`);
system(`/home/azurebrd/public_html/sanger/gene_postgres/populate_gin.pl 0005 $outfile`);
system(`/home/azurebrd/public_html/sanger/gene_postgres/populate_gin.pl 0006 $outfile`);
system(`/home/azurebrd/public_html/sanger/gene_postgres/populate_gin.pl 0007 $outfile`);
system(`/home/azurebrd/public_html/sanger/gene_postgres/populate_gin.pl 0008 $outfile`);
system(`/home/azurebrd/public_html/sanger/gene_postgres/populate_gin.pl 0009 $outfile`);

# $outfile = 'gin_main.20080407.113941.pg';
# $outfile = 'test';

open (IN, "<$outfile") or die "Cannot open $outfile : $!";
for (1 .. 100) { <IN>; }	# skip 100 lines
my $is_there_insert = '';
for (1 .. 100) { 
  my $line = <IN>; 
$is_there_insert .= $line; }
close (IN) or die "Cannot close $outfile : $!";

if ($is_there_insert =~ m/INSERT INTO/) {	# delete and insert only if there are inserts
						# to avoid wiping out tables if they're empty  2007 08 29
#   system(`psql -e testdb < $outfile`);	# this gives an error after doing everything Can't exec "DELETE FROM gin_sequence; ": No such file or directory at ./wrapper.pl line 59.
  `psql -e testdb < $outfile`;
}
