#!/usr/bin/perl -w

# Find Papers that do not have PDFs for Daniel (and cc Eimear) 
# can't get format to print to outfile (can't figure out how to use write)
# 2004 04 06

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $outfile = "outfile";
open(OUT, ">$outfile") or die "Cannot create $outfile : $!";

my %pdfs;
my %y2000;

my $result = $conn->exec( "SELECT ref_journal.joinkey, ref_journal.ref_journal, ref_year.ref_year, ref_volume.ref_volume, ref_pages.ref_pages FROM ref_journal, ref_pdf, ref_year, ref_volume, ref_pages WHERE ref_year.joinkey = ref_journal.joinkey AND ref_volume.joinkey = ref_journal.joinkey AND ref_pdf.joinkey = ref_journal.joinkey AND ref_pages.joinkey = ref_journal.joinkey AND ref_pdf.ref_pdf IS NULL ORDER BY ref_journal, ref_year, ref_volume; ");
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
format STDOUT_TOP =
                        Papers without PDF from ref_pdf
paper ID       Year          Volume        Pages           Journal Name
--------------------------------------------------------------------------------------------------------------------------------------------------------
.
format STDOUT =
@<<<<<<<<<<<<< @<<<<<<<<<<<< @<<<<<<<<<<<< @<<<<<<<<<<<<<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$row[0],       $row[2],      $row[3],      $row[4],        $row[1]
.
    write;
#     print "$row[0],$row[2],$row[3],$row[4],$row[1]\n"; 
#     print OUT "$row[0]\t$row[2]\t$row[3]\t$row[4]\t$row[1]\n"; 
#     $row[0] =~ s///g;
#     $pdfs{$row[0]}++;
  } # if ($row[0])
} # while (@row = $result->fetchrow)



close (OUT) or die "Cannot close $outfile : $!";
