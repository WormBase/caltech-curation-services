#!/usr/bin/perl5.6.0 -w
#
# Take the result of the diff, (diffend_20011129_20020108, which is the diff of
# /home/azurebrd/work/endnotes/gophbib.endnote.20020108 and 
# /home/azurebrd/work/endnotes/gophbib.endnote.20011129) and for that which is
# different, update entries.
# look at < entries, put in %update hash, to update instead of insert.  get all
# > entries, if exists in %update, write UPDATEs instead of INSERTs.

use lib qw( /usr/lib/perl5/site_perl/5.6.1/i686-linux/ );
use Pg;
use diagnostics;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my %cgc; 		# not a real hash, but could be used to store cgcs
my %shirin; 		# not a real hash, but was used to determine shirin vars
my %html;		# shirin - html.  cgc has html ?  use cgc as key
my %lib;		# shirin - lib.  cgc has lib ?  use cgc as key
my %tif;		# shirin - tif.  cgc has tif ?  use cgc as key
my %pdf;		# shirin - pdf.  cgc has pdf ?  use cgc as key
my %hardcopy; 		# hardcopy.  cgc has hardcopy ?  use cgc as key
my %author;		# authors, use cgc as key
my %title;		# title, use cgc as key
my %journal;		# journal, use cgc as key
my %volume;		# volume, use cgc as key
my %pages;		# pages, use cgc as key
my %year;		# year, use cgc as key
my %abstract;		# abstract, use cgc as key

my %update;

# my $infile = "/home/postgres/work/pgpopulation/finalcgc.txt";
my $infile = "/home/postgres/work/pgpopulation/endnotes/diffend_20011129_20020108";
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (<IN>) {
  if ($_ =~ m/^< (\d+)/) { $update{$1}++; }
} # while (<IN>)
close IN or die "Cannot close $infile : $!";

open (IN, "<$infile") or die "Cannot open $infile : $!";
while (<IN>) {
  chomp;
  $_ =~ s/'/\\'/g;
  $_ =~ s/"/\\"/g;
  $_ =~ s/@/\\@/g;
  if ($_ =~ m/> \d+/) {
    my ($cgc, $accnum, $author, $title, $journal, $volume, $pages, $year, $abstract, $shirin, $extra, $hardcopy, $extra2) = split/\t/;
    $cgc =~ s/[^\d]//g;
    if ($shirin =~ m/htm/i) { $html{$cgc}++; }
    if ($shirin =~ m/lib/i) { $lib{$cgc}++; }
    if ($shirin =~ m/tif/i) { $tif{$cgc}++; }
    if ($shirin =~ m/pdf/i) { $pdf{$cgc}++; }
    if ($hardcopy =~ m/yes/) { $hardcopy{$cgc}++; }
    $author{$cgc} = $author;
    $title{$cgc} = $title;
    $journal{$cgc} = $journal;
    $volume{$cgc} = $volume;
    $pages{$cgc} = $pages;
    $year{$cgc} = $year;
    $abstract{$cgc} = $abstract;
  } # if ($_ =~ m/\d+/) 
}

my $insertfile = "/home/postgres/work/pgpopulation/endnotes/insertfile20020108.pl";
open (OUT, ">$insertfile") or die "Cannot create $insertfile : $!";


print OUT "#!\/usr\/bin\/perl5.6.0\n";
print OUT "\n";
print OUT "use lib qw( \/usr\/lib/perl5\/site_perl\/5.6.1\/i686-linux\/ );\n";
print OUT "use Pg;\n";
print OUT "\n";
print OUT "\$conn = Pg::connectdb(\"dbname=testdb\");\n";
print OUT "die \$conn->errorMessage unless PGRES_CONNECTION_OK eq \$conn->status;\n\n";

foreach $_ (sort numerically keys %author) {
  unless ($update{$_}) {			# if not meant to update (no prev entry)
    print OUT "\$result = \$conn\->exec( \"INSERT INTO cgc VALUES (\'cgc$_\', \'$_\')\");\n";
  
    print OUT "\$result = \$conn\->exec( \"INSERT INTO reference_by VALUES (\'cgc$_\', \'postgres\')\");\n";
    print OUT "\$result = \$conn\->exec( \"INSERT INTO checked_out VALUES (\'cgc$_\', NULL )\");\n";
  
    if ($author{$_}) { print OUT "\$result = \$conn\->exec( \"INSERT INTO author VALUES (\'cgc$_\', \'$author{$_}\')\");\n"; }
  
    if ($title{$_}) { 
      print OUT "\$result = \$conn\->exec( \"INSERT INTO title VALUES (\'cgc$_\', \'$title{$_}\')\");\n";
    } else {
      print OUT "\$result = \$conn\->exec( \"INSERT INTO title VALUES ( \'cgc$_\', NULL )\");\n"; 
    }
  
    if ($journal{$_}) { 
      print OUT "\$result = \$conn\->exec( \"INSERT INTO journal VALUES (\'cgc$_\', \'$journal{$_}\')\");\n";
    } else {
      print OUT "\$result = \$conn\->exec( \"INSERT INTO journal VALUES ( \'cgc$_\', NULL )\");\n"; 
    }
  
    if ($volume{$_}) { 
      print OUT "\$result = \$conn\->exec( \"INSERT INTO volume VALUES (\'cgc$_\', \'$volume{$_}\')\");\n";
    } else {
      print OUT "\$result = \$conn\->exec( \"INSERT INTO volume VALUES ( \'cgc$_\', NULL )\");\n"; 
    }
  
    if ($pages{$_}) { 
      print OUT "\$result = \$conn\->exec( \"INSERT INTO pages VALUES (\'cgc$_\', \'$pages{$_}\')\");\n";
    } else {
      print OUT "\$result = \$conn\->exec( \"INSERT INTO pages VALUES ( \'cgc$_\', NULL )\");\n"; 
    }
  
    if ($year{$_}) { 
      print OUT "\$result = \$conn\->exec( \"INSERT INTO year VALUES (\'cgc$_\', \'$year{$_}\')\");\n";
    } else {
      print OUT "\$result = \$conn\->exec( \"INSERT INTO year VALUES ( \'cgc$_\', NULL )\");\n"; 
    }
  
    if ($abstract{$_}) { 
      print OUT "\$result = \$conn\->exec( \"INSERT INTO abstract VALUES (\'cgc$_\', \'$abstract{$_}\')\");\n";
    } else {
      print OUT "\$result = \$conn\->exec( \"INSERT INTO abstract VALUES ( \'cgc$_\', NULL )\");\n"; 
    }
  
    if ($hardcopy{$_}) { 
      print OUT "\$result = \$conn\->exec( \"INSERT INTO hardcopy VALUES (\'cgc$_\', \'$hardcopy{$_}\')\");\n"; 
    } else {
      print OUT "\$result = \$conn\->exec( \"INSERT INTO hardcopy VALUES ( \'cgc$_\', NULL )\");\n"; 
    }
  
    if ($pdf{$_}) { 
      print OUT "\$result = \$conn\->exec( \"INSERT INTO pdf VALUES (\'cgc$_\', \'$pdf{$_}\')\");\n"; 
    } else {
      print OUT "\$result = \$conn\->exec( \"INSERT INTO pdf VALUES ( \'cgc$_\', NULL )\");\n"; 
    }
  
    if ($html{$_}) { 
      print OUT "\$result = \$conn\->exec( \"INSERT INTO html VALUES (\'cgc$_\', \'$html{$_}\')\");\n"; 
    } else {
      print OUT "\$result = \$conn\->exec( \"INSERT INTO html VALUES ( \'cgc$_\', NULL )\");\n"; 
    }
  
    if ($tif{$_}) { 
      print OUT "\$result = \$conn\->exec( \"INSERT INTO tif VALUES (\'cgc$_\', \'$tif{$_}\')\");\n"; 
    } else {
      print OUT "\$result = \$conn\->exec( \"INSERT INTO tif VALUES ( \'cgc$_\', NULL )\");\n"; 
    }
  
    if ($lib{$_}) { 
      print OUT "\$result = \$conn\->exec( \"INSERT INTO lib VALUES (\'cgc$_\', \'$lib{$_}\')\");\n";
    } else {
      print OUT "\$result = \$conn\->exec( \"INSERT INTO lib VALUES ( \'cgc$_\', NULL )\");\n"; 
    }
  } else { # unless ($update{$_}) 		# already exists, meant to update.
    if ($author{$_}) { print OUT "\$result = \$conn\->exec( \"UPDATE author SET author = \'$author{$_}\' WHERE joinkey = \'cgc$_\';\");\n"; }
  
    if ($title{$_}) { 
      print OUT "\$result = \$conn\->exec( \"UPDATE title SET title = \'$title{$_}\' WHERE joinkey = \'cgc$_\';\");\n";
    } else {
      1;
    }
  
    if ($journal{$_}) { 
      print OUT "\$result = \$conn\->exec( \"UPDATE journal SET journal = \'$journal{$_}\' WHERE joinkey = \'cgc$_\';\");\n";
    } else {
      1;
    }
  
    if ($volume{$_}) { 
      print OUT "\$result = \$conn\->exec( \"UPDATE journal SET journal = \'$journal{$_}\' WHERE joinkey = \'cgc$_\';\");\n";
    } else {
      1;
    }
  
    if ($pages{$_}) { 
      print OUT "\$result = \$conn\->exec( \"UPDATE pages SET pages = \'$pages{$_}\' WHERE joinkey = \'cgc$_\';\");\n";
    } else {
      1;
    }
  
    if ($year{$_}) { 
      print OUT "\$result = \$conn\->exec( \"UPDATE year SET year = \'$year{$_}\' WHERE joinkey = \'cgc$_\';\");\n";
    } else {
      1;
    }
  
    if ($abstract{$_}) { 
      print OUT "\$result = \$conn\->exec( \"UPDATE abstract SET abstract = \'$abstract{$_}\' WHERE joinkey = \'cgc$_\';\");\n";
    } else {
      1;
    }
  
    if ($hardcopy{$_}) { 
      print OUT "\$result = \$conn\->exec( \"UPDATE hardcopy SET hardcopy = \'$hardcopy{$_}\' WHERE joinkey = \'cgc$_\';\");\n";
    } else {
      1;
    }
  
    if ($pdf{$_}) { 
      print OUT "\$result = \$conn\->exec( \"UPDATE pdf SET pdf = \'$pdf{$_}\' WHERE joinkey = \'cgc$_\';\");\n";
    } else {
      1;
    }
  
    if ($html{$_}) { 
      print OUT "\$result = \$conn\->exec( \"UPDATE html SET html = \'$html{$_}\' WHERE joinkey = \'cgc$_\';\");\n";
    } else {
      1;
    }
  
    if ($tif{$_}) { 
      print OUT "\$result = \$conn\->exec( \"UPDATE tif SET tif = \'$tif{$_}\' WHERE joinkey = \'cgc$_\';\");\n";
    } else {
      1;
    }
  
    if ($lib{$_}) { 
      print OUT "\$result = \$conn\->exec( \"UPDATE lib SET lib = \'$lib{$_}\' WHERE joinkey = \'cgc$_\';\");\n";
    } else {
      1;
    }
  } # else # unless ($update{$_}) 
} # foreach $_ (sort keys %author)

close IN or die "Cannot close $infile : $!";
close OUT or die "Cannot close $insertfile : $!";

sub numerically { $a <=> $b }                   # sort numerically

