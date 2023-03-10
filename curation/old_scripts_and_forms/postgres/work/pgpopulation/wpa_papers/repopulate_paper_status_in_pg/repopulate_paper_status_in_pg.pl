#!/usr/bin/perl
#
# repopulate paper status (non-hardcopy) of all cgcs and pmids by looking at an
# scp'ed file from athena, and the files in /home3/allpdfs/*.
#
# get the list of files into hashes by type and number.  for each of the cgcs
# (and then pmids) : check if each paper type exists, if so, populate, if not, 
# populate as NULL.  check if a hardcopy entry already exists, if not, populate
# as NULL.  2002 07 08
#
# added checks for other ref_tables, so if something isn't there, it inserts a NULL.
# run through an insertfile.pl which DELETE FROMs all the other tables.  2002 07 11

use strict;
use diagnostics;
use Pg;

my $outfile = "insertfile.pl";
open (OUT, ">$outfile") or die "Cannot open $outfile : $!";

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my %cgc;		# read in cgcs to compare all papers to full list
my $result = $conn->exec( "SELECT ref_cgc FROM ref_cgc" );
while (my @row = $result->fetchrow) { if ($row[0]) { $cgc{$row[0]}++; } }

my %pmid;		# read in pmids to compare all papers to full list
$result = $conn->exec( "SELECT ref_pmid FROM ref_pmid" );
while (my @row = $result->fetchrow) { if ($row[0]) { $pmid{$row[0]}++; } }

my %extras;
my @extras = qw( hardcopy abstract author checked_out comment journal pages title volume year );
foreach my $extra (@extras) {
  $result = $conn->exec( "SELECT joinkey FROM ref_$extra" );
  while (my @row = $result->fetchrow) { 
    my $hc = $row[0]; $hc =~ s/cgc//g; $hc =~ s/pmid//g;
    $extras{$extra}{$hc}++; 
  }
} # foreach my $extra (@extras)

my %reference_by;
$result = $conn->exec( "SELECT joinkey FROM ref_reference_by" );
while (my @row = $result->fetchrow) { 
  my $hc = $row[0]; $hc =~ s/cgc//g; $hc =~ s/pmid//g;
  $reference_by{$hc}++; 
}

# my %hardcopy;		# read in hardcopies to populate missing hardcopies
# $result = $conn->exec( "SELECT joinkey FROM ref_hardcopy" );
# while (my @row = $result->fetchrow) { 
#   my $hc = $row[0]; $hc =~ s/cgc//g; $hc =~ s/pmid//g;
#   $hardcopy{$hc}++; 
# }


# $result = $conn->exec( "CREATE TABLE one ( joinkey TEXT, one INTEGER, one_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP )");

my %tif;
my %tif_pdf;
my %lib_pdf;
my %pdf;
my %html;

my @Reference = </home3/allpdfs/*>;

foreach my $file (@Reference) {
  if ($file =~ m/^.*\/(\d+)/) {
    my $number = $1;
    $number =~ s/^0+//g;
    if ($file =~ m/tif$/) { $tif{$number}++; }
    elsif ($file =~ m/tiff$/) { $tif{$number}++; }
    elsif ($file =~ m/tif.pdf$/) { $tif_pdf{$number}++; }
    elsif ($file =~ m/lib.pdf$/) { $lib_pdf{$number}++; }
    elsif ($file =~ m/.pdf$/) { $pdf{$number}++; }
#     elsif ($file =~ m/.lib$/) { $lib{$number}++; }
    elsif ($file =~ m/htm/) { $html{$number}++; }
    else { print "$file\t$number\n"; }
  } # if ($_ =~ m/^\d/)
} # foreach $_ (@filelist)

my $infile = 'pop_tif_pg.data';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (<IN>) {
  chomp;
  my ($number, $type) = split/\t/, $_;
  if ($type eq 'TIF') { $tif{$number}++; }
  elsif ($type eq 'TIF_PDF') { $tif_pdf{$number}++; }
  elsif ($type eq 'PDF') { $pdf{$number}++; }
  else { print "ERROR $_ not a valid type\n"; }
} # while (<IN>)
close (IN) or die "Cannot close $infile : $!";

print OUT "#!\/usr\/bin\/perl\n";
print OUT "\n";
print OUT "use Pg;\n";
print OUT "\n";
print OUT "\$conn = Pg::connectdb(\"dbname=testdb\");\n";
print OUT "die \$conn->errorMessage unless PGRES_CONNECTION_OK eq \$conn->status;\n\n";

print OUT "\$result = \$conn->exec( \"DELETE FROM ref_tif\");\n";
print OUT "\$result = \$conn->exec( \"DELETE FROM ref_tif_pdf\");\n";
print OUT "\$result = \$conn->exec( \"DELETE FROM ref_lib_pdf\");\n";
print OUT "\$result = \$conn->exec( \"DELETE FROM ref_pdf\");\n";
# print OUT "\$result = \$conn->exec( \"DELETE FROM ref_lib\");\n";
print OUT "\$result = \$conn->exec( \"DELETE FROM ref_html\");\n";

foreach my $cgc (sort keys %cgc) { 
  if ($tif{$cgc}) { print OUT "\$result = \$conn->exec( \"INSERT INTO ref_tif VALUES ( 'cgc$cgc', 1 )\");\n";
  } else { print OUT "\$result = \$conn->exec( \"INSERT INTO ref_tif VALUES ( 'cgc$cgc', NULL )\");\n";
  }

  if ($tif_pdf{$cgc}) { print OUT "\$result = \$conn->exec( \"INSERT INTO ref_tif_pdf VALUES ( 'cgc$cgc', 1 )\");\n";
  } else { print OUT "\$result = \$conn->exec( \"INSERT INTO ref_tif_pdf VALUES ( 'cgc$cgc', NULL )\"); \n";}

  if ($lib_pdf{$cgc}) { print OUT "\$result = \$conn->exec( \"INSERT INTO ref_lib_pdf VALUES ( 'cgc$cgc', 1 )\");\n";
  } else { print OUT "\$result = \$conn->exec( \"INSERT INTO ref_lib_pdf VALUES ( 'cgc$cgc', NULL )\"); \n";}

  if ($pdf{$cgc}) { print OUT "\$result = \$conn->exec( \"INSERT INTO ref_pdf VALUES ( 'cgc$cgc', 1 )\");\n";
  } else { print OUT "\$result = \$conn->exec( \"INSERT INTO ref_pdf VALUES ( 'cgc$cgc', NULL )\"); \n";}

#   if ($lib{$cgc}) { print OUT "\$result = \$conn->exec( \"INSERT INTO ref_lib VALUES ( 'cgc$cgc', 1 )\");\n";
#   } else { print OUT "\$result = \$conn->exec( \"INSERT INTO ref_lib VALUES ( 'cgc$cgc', NULL )\"); \n";}

  if ($html{$cgc}) { print OUT "\$result = \$conn->exec( \"INSERT INTO ref_html VALUES ( 'cgc$cgc', 1 )\");\n";
  } else { print OUT "\$result = \$conn->exec( \"INSERT INTO ref_html VALUES ( 'cgc$cgc', NULL )\"); \n";}

  foreach my $extra (@extras) {
    unless ($extras{$extra}{$cgc}) { 
      print OUT "\$result = \$conn->exec( \"INSERT INTO ref_$extra VALUES ( 'cgc$cgc', NULL )\"); \n"; }
  } # foreach my $extra (@extras)

  unless ($reference_by{$cgc}) { 
    print OUT "\$result = \$conn->exec( \"INSERT INTO ref_reference_by VALUES ( 'cgc$cgc', 'postgres' )\"); \n"; }
} # foreach my $cgc (sort keys %cgc)

foreach my $pmid (sort keys %pmid) { 
  if ($tif{$pmid}) { print OUT "\$result = \$conn->exec( \"INSERT INTO ref_tif VALUES ( 'pmid$pmid', 1 )\");\n";
  } else { print OUT "\$result = \$conn->exec( \"INSERT INTO ref_tif VALUES ( 'pmid$pmid', NULL )\");\n";
  }

  if ($tif_pdf{$pmid}) { print OUT "\$result = \$conn->exec( \"INSERT INTO ref_tif_pdf VALUES ( 'pmid$pmid', 1 )\");\n";
  } else { print OUT "\$result = \$conn->exec( \"INSERT INTO ref_tif_pdf VALUES ( 'pmid$pmid', NULL )\"); \n";}

  if ($lib_pdf{$pmid}) { print OUT "\$result = \$conn->exec( \"INSERT INTO ref_lib_pdf VALUES ( 'pmid$pmid', 1 )\");\n";
  } else { print OUT "\$result = \$conn->exec( \"INSERT INTO ref_lib_pdf VALUES ( 'pmid$pmid', NULL )\"); \n";}

  if ($pdf{$pmid}) { print OUT "\$result = \$conn->exec( \"INSERT INTO ref_pdf VALUES ( 'pmid$pmid', 1 )\");\n";
  } else { print OUT "\$result = \$conn->exec( \"INSERT INTO ref_pdf VALUES ( 'pmid$pmid', NULL )\"); \n";}

#   if ($lib{$pmid}) { print OUT "\$result = \$conn->exec( \"INSERT INTO ref_lib VALUES ( 'pmid$pmid', 1 )\");\n";
#   } else { print OUT "\$result = \$conn->exec( \"INSERT INTO ref_lib VALUES ( 'pmid$pmid', NULL )\"); \n";}

  if ($html{$pmid}) { print OUT "\$result = \$conn->exec( \"INSERT INTO ref_html VALUES ( 'pmid$pmid', 1 )\");\n";
  } else { print OUT "\$result = \$conn->exec( \"INSERT INTO ref_html VALUES ( 'pmid$pmid', NULL )\"); \n";}

  foreach my $extra (@extras) {
    unless ($extras{$extra}{$pmid}) { 
      print OUT "\$result = \$conn->exec( \"INSERT INTO ref_$extra VALUES ( 'pmid$pmid', NULL )\"); \n"; }
  } # foreach my $extra (@extras)

  unless ($reference_by{$pmid}) { 
    print OUT "\$result = \$conn->exec( \"INSERT INTO ref_reference_by VALUES ( 'pmid$pmid', 'postgres' )\"); \n"; }

} # foreach my $pmid (sort keys %pmid)

close (OUT) or die "Cannot close $outfile : $!";
