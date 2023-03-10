#!/usr/bin/perl5.6.0 -w
#
# This takes the file finalcgc.txt from postgres's directory, grabs different
# fields and makes another file, insertfile.pl which creates Tables, and
# populates them with the data from finalcgc.txt, as well as NULL in
# table::checked_out, and ``postgres'' in table::reference_by. 
#
# updated to create new tables starting with ref_, will COPY table TO
# '/home/postgres/work/pgpopulation/endnotes/table.out'; then COPY ref_table
# FROM '/home/postgres/work/pgpopulation/endnotes/table.out'; then will 
# UPDATE ref_table SET ref_timestamp = CURRENT_TIMESTAMP WHERE ref_timestamp IS
# NULL;	 2002 01 27


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

# my $infile = "/home/postgres/work/pgpopulation/finalcgc.txt";
my $infile = "/home/postgres/work/pgpopulation/endnotes/CGC2001_11_09.txt";
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (<IN>) {
  chomp;
  $_ =~ s/'/\\'/g;
  $_ =~ s/"/\\"/g;
  $_ =~ s/@/\\@/g;
  if ($_ =~ m/\d+/) {
# *Journal Article
# Label   Accession Number        Author  Title   Journal Volume  Pages   Year
# Abstract        Shirin  Hard Copy       Abstract
    my ($cgc, $accnum, $author, $title, $journal, $volume, $pages, $year, $abstract, $shirin, $hardcopy, $extra) = split/\t/;
# *Journal Article
# Label   Shirin  Hard Copy       Accession Number        Author  Title   Journal
# Volume  Pages   Year    Abstract
#     my ($cgc, $shirin, $hardcopy, $accnum, $author, $title, $journal, $volume,
# $pages, $year, $abstract) = split/\t/;
# #     push @{ $shirin{$shirin} }, $cgc;
# #     push @{ $hardcopy{$hardcopy} }, $cgc;
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

my $insertfile = "/home/postgres/work/pgpopulation/endnotes/insertfile.pl";
open (OUT, ">$insertfile") or die "Cannot create $insertfile : $!";


print OUT "#!\/usr\/bin\/perl5.6.0\n";
print OUT "\n";
print OUT "use lib qw( \/usr\/lib/perl5\/site_perl\/5.6.1\/i686-linux\/ );\n";
print OUT "use Pg;\n";
print OUT "\n";
print OUT "\$conn = Pg::connectdb(\"dbname=testdb\");\n";
print OUT "die \$conn->errorMessage unless PGRES_CONNECTION_OK eq \$conn->status;\n\n";

print OUT "\$result = \$conn\->exec( \"CREATE TABLE ref_reference_by ( joinkey TEXT, ref_reference_by TEXT, ref_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP )\");\n";
print OUT "\$result = \$conn\->exec( \"CREATE TABLE ref_checked_out ( joinkey TEXT, ref_checked_out TEXT, ref_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP )\");\n";
print OUT "\$result = \$conn\->exec( \"CREATE TABLE ref_cgc ( joinkey TEXT, ref_cgc INTEGER, ref_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP )\");\n";
print OUT "\$result = \$conn\->exec( \"CREATE TABLE ref_pmid ( joinkey TEXT, ref_pmid INTEGER, ref_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP )\");\n";
print OUT "\$result = \$conn\->exec( \"CREATE TABLE ref_med ( joinkey TEXT, ref_med INTEGER, ref_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP )\");\n";
print OUT "\$result = \$conn\->exec( \"CREATE TABLE ref_author ( joinkey TEXT, ref_author TEXT, ref_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP )\");\n";
print OUT "\$result = \$conn\->exec( \"CREATE TABLE ref_title ( joinkey TEXT, ref_title TEXT, ref_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP )\");\n";
print OUT "\$result = \$conn\->exec( \"CREATE TABLE ref_journal ( joinkey TEXT, ref_journal TEXT, ref_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP )\");\n";
print OUT "\$result = \$conn\->exec( \"CREATE TABLE ref_volume ( joinkey TEXT, ref_volume INTEGER, ref_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP )\");\n";
print OUT "\$result = \$conn\->exec( \"CREATE TABLE ref_pages ( joinkey TEXT, ref_pages TEXT, ref_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP )\");\n";
print OUT "\$result = \$conn\->exec( \"CREATE TABLE ref_year ( joinkey TEXT, ref_year INTEGER, ref_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP )\");\n";
print OUT "\$result = \$conn\->exec( \"CREATE TABLE ref_abstract ( joinkey TEXT, ref_abstract TEXT, ref_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP )\");\n";
print OUT "\$result = \$conn\->exec( \"CREATE TABLE ref_hardcopy ( joinkey TEXT, ref_hardcopy TEXT, ref_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP )\");\n";
print OUT "\$result = \$conn\->exec( \"CREATE TABLE ref_pdf ( joinkey TEXT, ref_pdf TEXT, ref_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP )\");\n";
print OUT "\$result = \$conn\->exec( \"CREATE TABLE ref_html ( joinkey TEXT, ref_html TEXT, ref_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP )\");\n";
print OUT "\$result = \$conn\->exec( \"CREATE TABLE ref_tif ( joinkey TEXT, ref_tif TEXT, ref_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP )\");\n";
print OUT "\$result = \$conn\->exec( \"CREATE TABLE ref_lib ( joinkey TEXT, ref_lib TEXT, ref_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP )\");\n";
print OUT "\$result = \$conn\->exec( \"CREATE TABLE ref_comment ( joinkey TEXT, ref_comment TEXT, ref_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP )\");\n";

print OUT "\$result = \$conn\->exec( \"CREATE INDEX ref_reference_by_idx ON ref_reference_by ( joinkey )\");\n";
print OUT "\$result = \$conn\->exec( \"CREATE INDEX ref_checked_out_idx ON ref_checked_out ( joinkey )\");\n";
print OUT "\$result = \$conn\->exec( \"CREATE INDEX ref_cgc_idx ON ref_cgc ( joinkey )\");\n";
print OUT "\$result = \$conn\->exec( \"CREATE INDEX ref_pmid_idx ON ref_pmid ( joinkey )\");\n";
print OUT "\$result = \$conn\->exec( \"CREATE INDEX ref_med_idx ON ref_med ( joinkey )\");\n";
print OUT "\$result = \$conn\->exec( \"CREATE INDEX ref_author_idx ON ref_author ( joinkey )\");\n";
print OUT "\$result = \$conn\->exec( \"CREATE INDEX ref_title_idx ON ref_title ( joinkey )\");\n";
print OUT "\$result = \$conn\->exec( \"CREATE INDEX ref_journal_idx ON ref_journal ( joinkey )\");\n";
print OUT "\$result = \$conn\->exec( \"CREATE INDEX ref_volume_idx ON ref_volume ( joinkey )\");\n";
print OUT "\$result = \$conn\->exec( \"CREATE INDEX ref_pages_idx ON ref_pages ( joinkey )\");\n";
print OUT "\$result = \$conn\->exec( \"CREATE INDEX ref_year_idx ON ref_year ( joinkey )\");\n";
print OUT "\$result = \$conn\->exec( \"CREATE INDEX ref_abstract_idx ON ref_abstract ( joinkey )\");\n";
print OUT "\$result = \$conn\->exec( \"CREATE INDEX ref_hardcopy_idx ON ref_hardcopy ( joinkey )\");\n";
print OUT "\$result = \$conn\->exec( \"CREATE INDEX ref_pdf_idx ON ref_pdf ( joinkey )\");\n";
print OUT "\$result = \$conn\->exec( \"CREATE INDEX ref_html_idx ON ref_html ( joinkey )\");\n";
print OUT "\$result = \$conn\->exec( \"CREATE INDEX ref_tif_idx ON ref_tif ( joinkey )\");\n";
print OUT "\$result = \$conn\->exec( \"CREATE INDEX ref_lib_idx ON ref_lib ( joinkey )\");\n";
print OUT "\$result = \$conn\->exec( \"CREATE INDEX ref_comment_idx ON ref_comment ( joinkey )\");\n";

print OUT "\$result = \$conn\->exec( \"GRANT ALL ON ref_reference_by TO nobody\");\n";
print OUT "\$result = \$conn\->exec( \"GRANT ALL ON ref_checked_out TO nobody\");\n";
print OUT "\$result = \$conn\->exec( \"GRANT ALL ON ref_cgc TO nobody\");\n";
print OUT "\$result = \$conn\->exec( \"GRANT ALL ON ref_pmid TO nobody\");\n";
print OUT "\$result = \$conn\->exec( \"GRANT ALL ON ref_med TO nobody\");\n";
print OUT "\$result = \$conn\->exec( \"GRANT ALL ON ref_author TO nobody\");\n";
print OUT "\$result = \$conn\->exec( \"GRANT ALL ON ref_title TO nobody\");\n";
print OUT "\$result = \$conn\->exec( \"GRANT ALL ON ref_journal TO nobody\");\n";
print OUT "\$result = \$conn\->exec( \"GRANT ALL ON ref_volume TO nobody\");\n";
print OUT "\$result = \$conn\->exec( \"GRANT ALL ON ref_pages TO nobody\");\n";
print OUT "\$result = \$conn\->exec( \"GRANT ALL ON ref_year TO nobody\");\n";
print OUT "\$result = \$conn\->exec( \"GRANT ALL ON ref_abstract TO nobody\");\n";
print OUT "\$result = \$conn\->exec( \"GRANT ALL ON ref_hardcopy TO nobody\");\n";
print OUT "\$result = \$conn\->exec( \"GRANT ALL ON ref_pdf TO nobody\");\n";
print OUT "\$result = \$conn\->exec( \"GRANT ALL ON ref_html TO nobody\");\n";
print OUT "\$result = \$conn\->exec( \"GRANT ALL ON ref_tif TO nobody\");\n";
print OUT "\$result = \$conn\->exec( \"GRANT ALL ON ref_lib TO nobody\");\n";
print OUT "\$result = \$conn\->exec( \"GRANT ALL ON ref_comment TO nobody\");\n";

# foreach $_ (sort keys %author) {
#   print OUT "\$result = \$conn\->exec( \"INSERT INTO cgc VALUES (\'cgc$_\', \'$_\')\");\n";
# 
#   print OUT "\$result = \$conn\->exec( \"INSERT INTO reference_by VALUES (\'cgc$_\', \'postgres\')\");\n";
#   print OUT "\$result = \$conn\->exec( \"INSERT INTO checked_out VALUES (\'cgc$_\', NULL )\");\n";
# 
#   if ($author{$_}) { print OUT "\$result = \$conn\->exec( \"INSERT INTO author VALUES (\'cgc$_\', \'$author{$_}\')\");\n"; }
# 
#   if ($title{$_}) { 
#     print OUT "\$result = \$conn\->exec( \"INSERT INTO title VALUES (\'cgc$_\', \'$title{$_}\')\");\n";
#   } else {
#     print OUT "\$result = \$conn\->exec( \"INSERT INTO title VALUES ( \'cgc$_\', NULL )\");\n"; 
#   }
# 
#   if ($journal{$_}) { 
#     print OUT "\$result = \$conn\->exec( \"INSERT INTO journal VALUES (\'cgc$_\', \'$journal{$_}\')\");\n";
#   } else {
#     print OUT "\$result = \$conn\->exec( \"INSERT INTO journal VALUES ( \'cgc$_\', NULL )\");\n"; 
#   }
# 
#   if ($volume{$_}) { 
#     print OUT "\$result = \$conn\->exec( \"INSERT INTO volume VALUES (\'cgc$_\', \'$volume{$_}\')\");\n";
#   } else {
#     print OUT "\$result = \$conn\->exec( \"INSERT INTO volume VALUES ( \'cgc$_\', NULL )\");\n"; 
#   }
# 
#   if ($pages{$_}) { 
#     print OUT "\$result = \$conn\->exec( \"INSERT INTO pages VALUES (\'cgc$_\', \'$pages{$_}\')\");\n";
#   } else {
#     print OUT "\$result = \$conn\->exec( \"INSERT INTO pages VALUES ( \'cgc$_\', NULL )\");\n"; 
#   }
# 
#   if ($year{$_}) { 
#     print OUT "\$result = \$conn\->exec( \"INSERT INTO year VALUES (\'cgc$_\', \'$year{$_}\')\");\n";
#   } else {
#     print OUT "\$result = \$conn\->exec( \"INSERT INTO year VALUES ( \'cgc$_\', NULL )\");\n"; 
#   }
# 
#   if ($abstract{$_}) { 
#     print OUT "\$result = \$conn\->exec( \"INSERT INTO abstract VALUES (\'cgc$_\', \'$abstract{$_}\')\");\n";
#   } else {
#     print OUT "\$result = \$conn\->exec( \"INSERT INTO abstract VALUES ( \'cgc$_\', NULL )\");\n"; 
#   }
# 
#   if ($hardcopy{$_}) { 
#     print OUT "\$result = \$conn\->exec( \"INSERT INTO hardcopy VALUES (\'cgc$_\', \'$hardcopy{$_}\')\");\n"; 
#   } else {
#     print OUT "\$result = \$conn\->exec( \"INSERT INTO hardcopy VALUES ( \'cgc$_\', NULL )\");\n"; 
#   }
# 
#   if ($pdf{$_}) { 
#     print OUT "\$result = \$conn\->exec( \"INSERT INTO pdf VALUES (\'cgc$_\', \'$pdf{$_}\')\");\n"; 
#   } else {
#     print OUT "\$result = \$conn\->exec( \"INSERT INTO pdf VALUES ( \'cgc$_\', NULL )\");\n"; 
#   }
# 
#   if ($html{$_}) { 
#     print OUT "\$result = \$conn\->exec( \"INSERT INTO html VALUES (\'cgc$_\', \'$html{$_}\')\");\n"; 
#   } else {
#     print OUT "\$result = \$conn\->exec( \"INSERT INTO html VALUES ( \'cgc$_\', NULL )\");\n"; 
#   }
# 
#   if ($tif{$_}) { 
#     print OUT "\$result = \$conn\->exec( \"INSERT INTO tif VALUES (\'cgc$_\', \'$tif{$_}\')\");\n"; 
#   } else {
#     print OUT "\$result = \$conn\->exec( \"INSERT INTO tif VALUES ( \'cgc$_\', NULL )\");\n"; 
#   }
# 
#   if ($lib{$_}) { 
#     print OUT "\$result = \$conn\->exec( \"INSERT INTO lib VALUES (\'cgc$_\', \'$lib{$_}\')\");\n";
#   } else {
#     print OUT "\$result = \$conn\->exec( \"INSERT INTO lib VALUES ( \'cgc$_\', NULL )\");\n"; 
#   }
# } # foreach $_ (sort keys %author)

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
