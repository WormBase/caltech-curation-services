#!/usr/bin/perl

# use the get_paper_ace.pm module from /home/postgres/work/citace_upload/papers/ 
# to dump the papers, abstracts (LongText objects), and errors associated with
# them.  2005 07 13
#
# adapted from use_package.pl  2005 07 20
#
# also dumping wbpapers.endnote file for daniel / todd / wormbase.  2009 05 21
#
# changed from wpa tables to pap tables, although pap tables aren't live yet.
# changed dumpers from get_paper_ace.pm to dumpPapAce.pl  2010 06 23
#
# running after every workday at 4 am
# 0 4 * * tue,wed,thu,fri,sat /home/postgres/public_html/michael/get_all_papers.pl
#
# moved to acedb account, taken off cron now  2011 06 22
# /home/acedb/mueller/get_papers/get_all_papers.pl



use strict;
use Jex;
use DBI;

# use lib qw( /home/postgres/work/citace_upload/papers/ );
# use get_paper_ace;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my $endfile = '/home2/postgres/public_html/michael/wbpapers.endnote';
open (OUT, ">$endfile") or die "Cannot close $endfile : $!";

my %theHash;
my @tables = qw( pap_status pap_author pap_author_index pap_title pap_journal pap_volume pap_pages pap_year pap_abstract );

foreach my $table (@tables) {
  my $result = $dbh->prepare( "SELECT * FROM $table ORDER BY pap_timestamp ;" );
  $result->execute();
  while (my @row = $result->fetchrow) {
    unless ($row[2]) { $row[2] = 1; }
    $theHash{$table}{$row[0]}{$row[2]} = $row[1];
#     if ($row[3] eq 'valid') { $theHash{$table}{$row[0]}{$row[2]} = $row[1]; }
#       else { delete $theHash{$table}{$row[0]}{$row[2]}; }
  } # while (my @row = $result->fetchrow)
}
foreach my $joinkey (sort keys %{ $theHash{pap_status} }) {		# if only want valid values and a value is not valid, skip it.  2005 11 10
  next if ($theHash{pap_status}{$joinkey}{1} ne 'valid');
  next if ($joinkey eq '00000001');
  my @authors;
  foreach my $order (sort {$a<=>$b} keys %{ $theHash{"pap_author"}{$joinkey} } ) { push @authors, $theHash{"pap_author_index"}{ $theHash{"pap_author"}{$joinkey}{$order} }{"1"}; }
  my @good_authors; foreach (@authors) { if ($_) { push @good_authors, $_; } }
  my $authors = join"//", @good_authors;
  my $title = $theHash{"pap_title"}{$joinkey}{"1"};
  my $journal = $theHash{"pap_journal"}{$joinkey}{"1"};
  my $volume = $theHash{"pap_volume"}{$joinkey}{"1"};
  my $pages = $theHash{"pap_pages"}{$joinkey}{"1"};
  my $year = $theHash{"pap_year"}{$joinkey}{"1"};
  my $abstract = $theHash{"pap_abstract"}{$joinkey}{"1"};
  unless ($title) { $title = ""; }
  unless ($journal) { $journal = ""; }
  unless ($volume) { $volume = ""; }
  unless ($pages) { $pages = ""; }
  unless ($year) { $year = ""; }
  unless ($abstract) { $abstract = ""; }
  print OUT "$joinkey\t$authors\t$title\t$journal\t$volume\t$pages\t$year\t$abstract\t\n";
} # foreach my $joinkey (sort keys %{ $theHash{valid} })

close (OUT) or die "Cannot close $endfile : $!";

`/home/postgres/work/citace_upload/papers/dumpPapAce.pl > /home2/postgres/public_html/michael/papers.ace`;


# my $outfile = '/home2/postgres/public_html/michael/papers.ace';
# my $outlong = '/home2/postgres/public_html/michael/abstracts.ace';
# my $errfile = '/home2/postgres/public_html/michael/err.out';
# open (OUT, ">$outfile") or die "Cannot create $outfile : $!\n";
# open (LON, ">$outlong") or die "Cannot create $outlong : $!\n";
# open (ERR, ">$errfile") or die "Cannot create $errfile : $!\n";
# 
# 
# my ($all_entry, $long_text, $err_text) = &getPaper('valid');
# 
# print OUT "$all_entry\n";
# print LON "$long_text\n";
# print ERR "$err_text\n";
# 
# close (OUT) or die "Cannot close $outfile : $!";
# close (LON) or die "Cannot close $outlong : $!";
# close (ERR) or die "Cannot close $errfile : $!";

