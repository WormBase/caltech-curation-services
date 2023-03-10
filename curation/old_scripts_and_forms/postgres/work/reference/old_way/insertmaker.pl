#!/usr/bin/perl5.6.0 -w
#
# Take the result of the diff, (diffend_20011129_20020108, which is the diff of
# /home/azurebrd/work/endnotes/gophbib.endnote.20020108 and 
# /home/azurebrd/work/endnotes/gophbib.endnote.20011129) and for that which is
# different, update entries.
# look at < entries, put in %update hash, to update instead of insert.  get all
# > entries, if exists in %update, write UPDATEs instead of INSERTs.
#
# Updated to work under /home/postgres/work/reference/, called by wrapper to
# create a time-specific (passed in by wrapper) insertfile.time.pl using the
# diffend file (result of doing a diff between the last parsed set of data and
# the new one created by wrapper (cgc_to_endnote.pl).  Wrapper then calls the 
# insertfile.time.pl this creates to insert/update the data, the time-varied 
# files are moved to done/ and the current (last parsed set of data file) is 
# relinked.  2002 01 26
#
# This version writes to the old pg tables. (not the ref_ tables) 2002 01 29
# This version has been updated to write to the new pg tables (the ref_ tables)
# 2002 01 29
# Updated the insertmaker.pl to email daniel if the diffend file is nonzero size
# (has data, which is written into postgreSQL)  2002 01 30

use lib qw( /usr/lib/perl5/site_perl/5.6.1/i686-linux/ );
use Pg;
use diagnostics;
use Mail::Mailer;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

chdir("/home/postgres/work/reference") || die "Cannot go to /home/postgres/work/reference ($!)";


my %cgc; 		# not a real hash, but could be used to store cgcs
my %author;		# authors, use cgc as key
my %title;		# title, use cgc as key
my %journal;		# journal, use cgc as key
my %volume;		# volume, use cgc as key
my %pages;		# pages, use cgc as key
my %year;		# year, use cgc as key
my %abstract;		# abstract, use cgc as key

my %update;

my $time = $ARGV[0];

# my $infile = "/home/postgres/work/pgpopulation/finalcgc.txt";
my $infile = "/home/postgres/work/reference/diffend";
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
    my ($cgc, $author, $title, $journal, $volume, $pages, $year, $abstract) = split/\t/;
    $cgc =~ s/[^\d]//g;
    $author{$cgc} = $author;
    $title{$cgc} = $title;
    $journal{$cgc} = $journal;
    $volume{$cgc} = $volume;
    $pages{$cgc} = $pages;
    $year{$cgc} = $year;
    $abstract{$cgc} = $abstract;
  } # if ($_ =~ m/\d+/) 
}

if (-s $infile) {	# if file has non-zero size
  my $user = 'azurebrd@minerva.caltech.edu';
  my $email = 'qhw980806@yahoo.com';
  my $subject = 'Updated CGC data from Theresa in PostgreSQL';
  my $body = 'See http://minerva.caltech.edu/~postgres/cgi-bin/endnoter.cgi';
  &Mailer($user, $email, $subject, $body);
} # if (-s $infile)

my $insertfile = "/home/postgres/work/reference/insertfile" . $time . ".pl";
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
    print OUT "\$result = \$conn\->exec( \"INSERT INTO ref_cgc VALUES (\'cgc$_\', \'$_\')\");\n";
  
    print OUT "\$result = \$conn\->exec( \"INSERT INTO ref_reference_by VALUES (\'cgc$_\', \'postgres\')\");\n";
    print OUT "\$result = \$conn\->exec( \"INSERT INTO ref_checked_out VALUES (\'cgc$_\', NULL )\");\n";
  
    if ($author{$_}) { print OUT "\$result = \$conn\->exec( \"INSERT INTO ref_author VALUES (\'cgc$_\', \'$author{$_}\')\");\n"; }
  
    if ($title{$_}) { 
      print OUT "\$result = \$conn\->exec( \"INSERT INTO ref_title VALUES (\'cgc$_\', \'$title{$_}\')\");\n";
    } else {
      print OUT "\$result = \$conn\->exec( \"INSERT INTO ref_title VALUES ( \'cgc$_\', NULL )\");\n"; 
    }
  
    if ($journal{$_}) { 
      print OUT "\$result = \$conn\->exec( \"INSERT INTO ref_journal VALUES (\'cgc$_\', \'$journal{$_}\')\");\n";
    } else {
      print OUT "\$result = \$conn\->exec( \"INSERT INTO ref_journal VALUES ( \'cgc$_\', NULL )\");\n"; 
    }
  
    if ($volume{$_}) { 
      print OUT "\$result = \$conn\->exec( \"INSERT INTO ref_volume VALUES (\'cgc$_\', \'$volume{$_}\')\");\n";
    } else {
      print OUT "\$result = \$conn\->exec( \"INSERT INTO ref_volume VALUES ( \'cgc$_\', NULL )\");\n"; 
    }
  
    if ($pages{$_}) { 
      print OUT "\$result = \$conn\->exec( \"INSERT INTO ref_pages VALUES (\'cgc$_\', \'$pages{$_}\')\");\n";
    } else {
      print OUT "\$result = \$conn\->exec( \"INSERT INTO ref_pages VALUES ( \'cgc$_\', NULL )\");\n"; 
    }
  
    if ($year{$_}) { 
      print OUT "\$result = \$conn\->exec( \"INSERT INTO ref_year VALUES (\'cgc$_\', \'$year{$_}\')\");\n";
    } else {
      print OUT "\$result = \$conn\->exec( \"INSERT INTO ref_year VALUES ( \'cgc$_\', NULL )\");\n"; 
    }
  
    if ($abstract{$_}) { 
      print OUT "\$result = \$conn\->exec( \"INSERT INTO ref_abstract VALUES (\'cgc$_\', \'$abstract{$_}\')\");\n";
    } else {
      print OUT "\$result = \$conn\->exec( \"INSERT INTO ref_abstract VALUES ( \'cgc$_\', NULL )\");\n"; 
    }
  
    if ($hardcopy{$_}) { 
      print OUT "\$result = \$conn\->exec( \"INSERT INTO ref_hardcopy VALUES (\'cgc$_\', \'$hardcopy{$_}\')\");\n"; 
    } else {
      print OUT "\$result = \$conn\->exec( \"INSERT INTO ref_hardcopy VALUES ( \'cgc$_\', NULL )\");\n"; 
    }
  
    if ($pdf{$_}) { 
      print OUT "\$result = \$conn\->exec( \"INSERT INTO ref_pdf VALUES (\'cgc$_\', \'$pdf{$_}\')\");\n"; 
    } else {
      print OUT "\$result = \$conn\->exec( \"INSERT INTO ref_pdf VALUES ( \'cgc$_\', NULL )\");\n"; 
    }
  
    if ($html{$_}) { 
      print OUT "\$result = \$conn\->exec( \"INSERT INTO ref_html VALUES (\'cgc$_\', \'$html{$_}\')\");\n"; 
    } else {
      print OUT "\$result = \$conn\->exec( \"INSERT INTO ref_html VALUES ( \'cgc$_\', NULL )\");\n"; 
    }
  
    if ($tif{$_}) { 
      print OUT "\$result = \$conn\->exec( \"INSERT INTO ref_tif VALUES (\'cgc$_\', \'$tif{$_}\')\");\n"; 
    } else {
      print OUT "\$result = \$conn\->exec( \"INSERT INTO ref_tif VALUES ( \'cgc$_\', NULL )\");\n"; 
    }
  
    if ($lib{$_}) { 
      print OUT "\$result = \$conn\->exec( \"INSERT INTO ref_lib VALUES (\'cgc$_\', \'$lib{$_}\')\");\n";
    } else {
      print OUT "\$result = \$conn\->exec( \"INSERT INTO ref_lib VALUES ( \'cgc$_\', NULL )\");\n"; 
    }
  } else { # unless ($update{$_}) 		# already exists, meant to update.
    print OUT "\$result = \$conn\->exec( \"UPDATE ref_cgc SET ref_timestamp = CURRENT_TIMESTAMP WHERE joinkey =\'cgc$_\';\");\n"; 

    if ($author{$_}) { print OUT "\$result = \$conn\->exec( \"UPDATE ref_author SET ref_author = \'$author{$_}\' WHERE joinkey = \'cgc$_\';\");\n"; }
  
    if ($title{$_}) { 
      print OUT "\$result = \$conn\->exec( \"UPDATE ref_title SET ref_title = \'$title{$_}\' WHERE joinkey = \'cgc$_\';\");\n";
    } else {
      1;
    }
  
    if ($journal{$_}) { 
      print OUT "\$result = \$conn\->exec( \"UPDATE ref_journal SET ref_journal = \'$journal{$_}\' WHERE joinkey = \'cgc$_\';\");\n";
    } else {
      1;
    }
  
    if ($volume{$_}) { 
      print OUT "\$result = \$conn\->exec( \"UPDATE ref_volume SET ref_volume = \'$volume{$_}\' WHERE joinkey = \'cgc$_\';\");\n";
    } else {
      1;
    }
  
    if ($pages{$_}) { 
      print OUT "\$result = \$conn\->exec( \"UPDATE ref_pages SET ref_pages = \'$pages{$_}\' WHERE joinkey = \'cgc$_\';\");\n";
    } else {
      1;
    }
  
    if ($year{$_}) { 
      print OUT "\$result = \$conn\->exec( \"UPDATE ref_year SET ref_year = \'$year{$_}\' WHERE joinkey = \'cgc$_\';\");\n";
    } else {
      1;
    }
  
    if ($abstract{$_}) { 
      print OUT "\$result = \$conn\->exec( \"UPDATE ref_abstract SET ref_abstract = \'$abstract{$_}\' WHERE joinkey = \'cgc$_\';\");\n";
    } else {
      1;
    }
  
    if ($hardcopy{$_}) { 
      print OUT "\$result = \$conn\->exec( \"UPDATE ref_hardcopy SET ref_hardcopy = \'$hardcopy{$_}\' WHERE joinkey = \'cgc$_\';\");\n";
    } else {
      1;
    }
  
    if ($pdf{$_}) { 
      print OUT "\$result = \$conn\->exec( \"UPDATE ref_pdf SET ref_pdf = \'$pdf{$_}\' WHERE joinkey = \'cgc$_\';\");\n";
    } else {
      1;
    }
  
    if ($html{$_}) { 
      print OUT "\$result = \$conn\->exec( \"UPDATE ref_html SET ref_html = \'$html{$_}\' WHERE joinkey = \'cgc$_\';\");\n";
    } else {
      1;
    }
  
    if ($tif{$_}) { 
      print OUT "\$result = \$conn\->exec( \"UPDATE ref_tif SET ref_tif = \'$tif{$_}\' WHERE joinkey = \'cgc$_\';\");\n";
    } else {
      1;
    }
  
    if ($lib{$_}) { 
      print OUT "\$result = \$conn\->exec( \"UPDATE ref_lib SET ref_lib = \'$lib{$_}\' WHERE joinkey = \'cgc$_\';\");\n";
    } else {
      1;
    }
  } # else # unless ($update{$_}) 
} # foreach $_ (sort keys %author)

close IN or die "Cannot close $infile : $!";
close OUT or die "Cannot close $insertfile : $!";

sub numerically { $a <=> $b }                   # sort numerically

sub Mailer {            # send non-attachment mail
  my ($user, $email, $subject, $body) = @_;
  my $command = 'sendmail';
  my $mailer = Mail::Mailer->new($command) ;
  $mailer->open({ From    => $user,
                  To      => $email,
                  Cc      => $ccemail,
                  Subject => $subject,
                })
      or die "Can't open: $!\n";
  print $mailer $body;
  $mailer->close();
} # sub Mailer

