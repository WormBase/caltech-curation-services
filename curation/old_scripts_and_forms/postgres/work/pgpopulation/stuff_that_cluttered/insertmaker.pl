#!/usr/bin/perl5.6.0 -w
#
# This takes the file finalcgc.txt from postgres's directory, grabs different
# fields and makes another file, insertfile.pl which creates Tables, and
# populates them with the data from finalcgc.txt, as well as NULL in
# table::checked_out, and ``postgres'' in table::reference_by. 

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

my $infile = "/home/postgres/work/pgpopulation/finalcgc.txt";
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (<IN>) {
  chomp;
  $_ =~ s/'/\\'/g;
  $_ =~ s/"/\\"/g;
  $_ =~ s/@/\\@/g;
  if ($_ =~ m/\d+/) {
    my ($cgc, $shirin, $hardcopy, $accnum, $author, $title, $journal, $volume,
$pages, $year, $abstract) = split/\t/;
#     push @{ $shirin{$shirin} }, $cgc;
#     push @{ $hardcopy{$hardcopy} }, $cgc;
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

# foreach $_ (sort keys %shirin) {
#   print "Shirin : " . $_ . " : " . scalar (@{ $shirin{$_} }) . "\n";
# } # foreach $_ (sort keys %shirin)
# 
# foreach $_ (sort keys %hardcopy) {
#   print "Hard Copy : " . $_ . " : " . scalar (@{ $hardcopy{$_} }) . "\n";
# } # foreach $_ (sort keys %hardcopy)

my $insertfile = "/home/postgres/work/pgpopulation/insertfile.pl";
open (OUT, ">$insertfile") or die "Cannot create $insertfile : $!";


print OUT "#!\/usr\/bin\/perl5.6.0\n";
print OUT "\n";
print OUT "use lib qw( \/usr\/lib/perl5\/site_perl\/5.6.1\/i686-linux\/ );\n";
print OUT "use Pg;\n";
print OUT "\n";
print OUT "\$conn = Pg::connectdb(\"dbname=testdb\");\n";
print OUT "die \$conn->errorMessage unless PGRES_CONNECTION_OK eq \$conn->status;\n\n";

print OUT "\$result = \$conn\->exec( \"CREATE TABLE reference_by ( joinkey TEXT, reference_by TEXT )\");\n";
print OUT "\$result = \$conn\->exec( \"CREATE TABLE checked_out ( joinkey TEXT, checked_out TEXT )\");\n";
# print OUT "\$result = \$conn\->exec( \"CREATE TABLE cgc ( joinkey TEXT, cgc INTEGER )\");\n";
# print OUT "\$result = \$conn\->exec( \"CREATE TABLE pmid ( joinkey TEXT, pmid INTEGER )\");\n";
# print OUT "\$result = \$conn\->exec( \"CREATE TABLE med ( joinkey TEXT, med INTEGER )\");\n";
# print OUT "\$result = \$conn\->exec( \"CREATE TABLE author ( joinkey TEXT, author TEXT )\");\n";
# print OUT "\$result = \$conn\->exec( \"CREATE TABLE title ( joinkey TEXT, title TEXT )\");\n";
# print OUT "\$result = \$conn\->exec( \"CREATE TABLE journal ( joinkey TEXT, journal TEXT )\");\n";
# print OUT "\$result = \$conn\->exec( \"CREATE TABLE volume ( joinkey TEXT, volume INTEGER )\");\n";
# print OUT "\$result = \$conn\->exec( \"CREATE TABLE pages ( joinkey TEXT, pages TEXT )\");\n";
# print OUT "\$result = \$conn\->exec( \"CREATE TABLE year ( joinkey TEXT, year INTEGER )\");\n";
# print OUT "\$result = \$conn\->exec( \"CREATE TABLE abstract ( joinkey TEXT, abstract TEXT )\");\n";
# print OUT "\$result = \$conn\->exec( \"CREATE TABLE hardcopy ( joinkey TEXT, hardcopy TEXT )\");\n";
# print OUT "\$result = \$conn\->exec( \"CREATE TABLE pdf ( joinkey TEXT, pdf TEXT )\");\n";
# print OUT "\$result = \$conn\->exec( \"CREATE TABLE html ( joinkey TEXT, html TEXT )\");\n";
# print OUT "\$result = \$conn\->exec( \"CREATE TABLE tif ( joinkey TEXT, tif TEXT )\");\n";
# print OUT "\$result = \$conn\->exec( \"CREATE TABLE lib ( joinkey TEXT, lib TEXT )\");\n";

# print OUT "\$result = \$conn\->exec( \"CREATE UNIQUE INDEX reference_by_idx ON reference_by ( joinkey )\");\n";
# print OUT "\$result = \$conn\->exec( \"CREATE UNIQUE INDEX cgc_idx ON cgc ( joinkey )\");\n";
# print OUT "\$result = \$conn\->exec( \"CREATE UNIQUE INDEX pmid_idx ON pmid ( joinkey )\");\n";
# print OUT "\$result = \$conn\->exec( \"CREATE UNIQUE INDEX med_idx ON med ( joinkey )\");\n";
# print OUT "\$result = \$conn\->exec( \"CREATE UNIQUE INDEX author_idx ON author ( joinkey )\");\n";
# print OUT "\$result = \$conn\->exec( \"CREATE UNIQUE INDEX title_idx ON title ( joinkey )\");\n";
# print OUT "\$result = \$conn\->exec( \"CREATE UNIQUE INDEX journal_idx ON journal ( joinkey )\");\n";
# print OUT "\$result = \$conn\->exec( \"CREATE UNIQUE INDEX volume_idx ON volume ( joinkey )\");\n";
# print OUT "\$result = \$conn\->exec( \"CREATE UNIQUE INDEX pages_idx ON pages ( joinkey )\");\n";
# print OUT "\$result = \$conn\->exec( \"CREATE UNIQUE INDEX year_idx ON year ( joinkey )\");\n";
# print OUT "\$result = \$conn\->exec( \"CREATE UNIQUE INDEX abstract_idx ON abstract ( joinkey )\");\n";
# print OUT "\$result = \$conn\->exec( \"CREATE UNIQUE INDEX hardcopy_idx ON hardcopy ( joinkey )\");\n";
# print OUT "\$result = \$conn\->exec( \"CREATE UNIQUE INDEX pdf_idx ON pdf ( joinkey )\");\n";
# print OUT "\$result = \$conn\->exec( \"CREATE UNIQUE INDEX html_idx ON html ( joinkey )\");\n";
# print OUT "\$result = \$conn\->exec( \"CREATE UNIQUE INDEX tif_idx ON tif ( joinkey )\");\n";
# print OUT "\$result = \$conn\->exec( \"CREATE UNIQUE INDEX lib_idx ON lib ( joinkey )\");\n";

# print OUT "\$result = \$conn\->exec( \"GRANT ALL ON reference_by TO nobody\");\n";
# print OUT "\$result = \$conn\->exec( \"GRANT ALL ON checked_out TO nobody\");\n";
# print OUT "\$result = \$conn\->exec( \"GRANT ALL ON cgc TO nobody\");\n";
# print OUT "\$result = \$conn\->exec( \"GRANT ALL ON pmid TO nobody\");\n";
# print OUT "\$result = \$conn\->exec( \"GRANT ALL ON med TO nobody\");\n";
# print OUT "\$result = \$conn\->exec( \"GRANT ALL ON author TO nobody\");\n";
# print OUT "\$result = \$conn\->exec( \"GRANT ALL ON title TO nobody\");\n";
# print OUT "\$result = \$conn\->exec( \"GRANT ALL ON journal TO nobody\");\n";
# print OUT "\$result = \$conn\->exec( \"GRANT ALL ON volume TO nobody\");\n";
# print OUT "\$result = \$conn\->exec( \"GRANT ALL ON pages TO nobody\");\n";
# print OUT "\$result = \$conn\->exec( \"GRANT ALL ON year TO nobody\");\n";
# print OUT "\$result = \$conn\->exec( \"GRANT ALL ON abstract TO nobody\");\n";
# print OUT "\$result = \$conn\->exec( \"GRANT ALL ON hardcopy TO nobody\");\n";
# print OUT "\$result = \$conn\->exec( \"GRANT ALL ON html TO nobody\");\n";
# print OUT "\$result = \$conn\->exec( \"GRANT ALL ON tif TO nobody\");\n";
# print OUT "\$result = \$conn\->exec( \"GRANT ALL ON lib TO nobody\");\n";

foreach $_ (sort keys %author) {

  print OUT "\$result = \$conn\->exec( \"INSERT INTO reference_by VALUES (\'cgc$_\', \'postgres\')\");\n";
  print OUT "\$result = \$conn\->exec( \"INSERT INTO checked_out VALUES (\'cgc$_\', NULL )\");\n";
#   if ($author{$_}) { print OUT "\$result = \$conn\->exec( \"INSERT INTO author VALUES (\'cgc$_\', \'$author{$_}\')\");\n"; }
#   if ($title{$_}) { 
#     print OUT "\$result = \$conn\->exec( \"INSERT INTO title VALUES (\'cgc$_\', \'$title{$_}\')\");\n";
#   } else {
#     print OUT "\$result = \$conn\->exec( \"INSERT INTO title VALUES ( \'cgc$_\', NULL )\");\n"; 
#   }
#   if ($journal{$_}) { 
#     print OUT "\$result = \$conn\->exec( \"INSERT INTO journal VALUES (\'cgc$_\', \'$journal{$_}\')\");\n";
#   } else {
#     print OUT "\$result = \$conn\->exec( \"INSERT INTO journal VALUES ( \'cgc$_\', NULL )\");\n"; 
#   }
#   if ($volume{$_}) { 
#     print OUT "\$result = \$conn\->exec( \"INSERT INTO volume VALUES (\'cgc$_\', \'$volume{$_}\')\");\n";
#   } else {
#     print OUT "\$result = \$conn\->exec( \"INSERT INTO volume VALUES ( \'cgc$_\', NULL )\");\n"; 
#   }
#   if ($pages{$_}) { 
#     print OUT "\$result = \$conn\->exec( \"INSERT INTO pages VALUES (\'cgc$_\', \'$pages{$_}\')\");\n";
#   } else {
#     print OUT "\$result = \$conn\->exec( \"INSERT INTO pages VALUES ( \'cgc$_\', NULL )\");\n"; 
#   }
#   if ($year{$_}) { 
#     print OUT "\$result = \$conn\->exec( \"INSERT INTO year VALUES (\'cgc$_\', \'$year{$_}\')\");\n";
#   } else {
#     print OUT "\$result = \$conn\->exec( \"INSERT INTO year VALUES ( \'cgc$_\', NULL )\");\n"; 
#   }
#   if ($abstract{$_}) { 
#     print OUT "\$result = \$conn\->exec( \"INSERT INTO abstract VALUES (\'cgc$_\', \'$abstract{$_}\')\");\n";
#   } else {
#     print OUT "\$result = \$conn\->exec( \"INSERT INTO abstract VALUES ( \'cgc$_\', NULL )\");\n"; 
#   }
#   if ($hardcopy{$_}) { 
#     print OUT "\$result = \$conn\->exec( \"INSERT INTO hardcopy VALUES (\'cgc$_\', \'$hardcopy{$_}\')\");\n"; 
#   } else {
#     print OUT "\$result = \$conn\->exec( \"INSERT INTO hardcopy VALUES ( \'cgc$_\', NULL )\");\n"; 
#   }
#   if ($pdf{$_}) { 
#     print OUT "\$result = \$conn\->exec( \"INSERT INTO pdf VALUES (\'cgc$_\', \'$pdf{$_}\')\");\n"; 
#   } else {
#     print OUT "\$result = \$conn\->exec( \"INSERT INTO pdf VALUES ( \'cgc$_\', NULL )\");\n"; 
#   }
#   if ($html{$_}) { 
#     print OUT "\$result = \$conn\->exec( \"INSERT INTO html VALUES (\'cgc$_\', \'$html{$_}\')\");\n"; 
#   } else {
#     print OUT "\$result = \$conn\->exec( \"INSERT INTO html VALUES ( \'cgc$_\', NULL )\");\n"; 
#   }
#   if ($tif{$_}) { 
#     print OUT "\$result = \$conn\->exec( \"INSERT INTO tif VALUES (\'cgc$_\', \'$tif{$_}\')\");\n"; 
#   } else {
#     print OUT "\$result = \$conn\->exec( \"INSERT INTO tif VALUES ( \'cgc$_\', NULL )\");\n"; 
#   }
#   if ($lib{$_}) { 
#     print OUT "\$result = \$conn\->exec( \"INSERT INTO lib VALUES (\'cgc$_\', \'$lib{$_}\')\");\n";
#   } else {
#     print OUT "\$result = \$conn\->exec( \"INSERT INTO lib VALUES ( \'cgc$_\', NULL )\");\n"; 
#   }
} # foreach $_ (sort keys %author)

# Giant table with all Reference info :
#   print OUT "\$result = \$conn\->exec( \"INSERT INTO testreference VALUES (\'cgc$_\', \'$author{$_}\', \'$title{$_}\', \'$journal{$_}\', \'$volume{$_}\', \'$pages{$_}\', \'$year{$_}\', \'$abstract{$_}\', ";
#   if ($hardcopy{$_}) { print OUT "\'$hardcopy{$_}\', "; } else { print OUT " NULL, "; }
#   if ($pdf{$_}) { print OUT "\'$pdf{$_}\', "; } else { print OUT " NULL, "; }
#   if ($html{$_}) { print OUT "\'$html{$_}\', "; } else { print OUT " NULL, "; }
#   if ($tif{$_}) { print OUT "\'$tif{$_}\', "; } else { print OUT " NULL, "; }
#   if ($lib{$_}) { print OUT "\'$lib{$_}\' "; } else { print OUT " NULL "; }
#   print OUT ")\");\n";
  


# testdb=# CREATE TABLE testreference (
# testdb(#   cgc TEXT,
# testdb(#   author TEXT,
# testdb(#   title TEXT,
# testdb(#   journal TEXT,
# testdb(#   volume TEXT,
# testdb(#   pages TEXT,
# testdb(#   year TEXT,
# testdb(#   abstract TEXT,
# testdb(#   hardcopy TEXT,
# testdb(#   pdf TEXT,
# testdb(#   html TEXT,
# testdb(#   tif TEXT,
# testdb(#   lib TEXT
# testdb(# );

# } # What is this for ?


# print "1\n";
# $result = $conn->exec(
  # "INSERT INTO friend VALUES ('Sam', 'Jackson', 'Allentown', 'PA', 22)");
# print "2\n";

close IN or die "Cannot close $infile : $!";
close OUT or die "Cannot close $insertfile : $!";
