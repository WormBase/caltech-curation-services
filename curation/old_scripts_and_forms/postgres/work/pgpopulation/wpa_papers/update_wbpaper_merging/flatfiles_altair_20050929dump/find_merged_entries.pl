#!/usr/bin/perl

# get the invalid wbpapers and the new papers from tazendra,
# then look at a filtered .ace from the citace dump that only
# shows tags with WBPaper data.  Match tags to invalid WBPapers
# and sort in hash by curator from timestamp.  2005 09 15
#
# Skip Author objects since they should be created by the new WBPaper.
# Skip Paper's Old_WBPaper tag since changing it would make it refer to itself.
# Skip Objects where the WBPaper is in the object since it should be created
# by the other WBPaper.  e.g. LongText, Paper_name, Paper.  2005 09 28
#
# Usage : ./find_merged_entries.pl
# creates :  merged_papers.ace and merged_paper.cgi.date which are later 
# moved to a sorting directory.  2005 09 28


`wget http://tazendra.caltech.edu/~postgres/cgi-bin/merged_papers.cgi`;
my %invalid_map;
my $invalid_file = 'merged_papers.cgi';
open (IN, "<$invalid_file") or die "Cannot open $invalid_file : $!";
while (my $line = <IN>) {
  if ($line =~ m/^(\d{8})\tis now\t(.*)<BR>/) {
    $invalid_map{$1} = $2; }
} # while (<IN>)
close (IN) or die "Cannot close $infile : $!";


my $infile = 'wbpaper.ace';
open (IN, "<$infile") or die "Cannot open $infile : $!";
my $outfile = 'merged_papers.ace';
open (OUT, ">$outfile") or die "cannot create $outfile : $!";

my $start = &getSimpleSecDate();
my $stime = time;
print OUT "// START $start $stime START\n";
print STDERR "START $start estimate + 4mins, 20sec\n";

my %data_hash;

$/ = "";
while (my $paragraph = <IN>) {
  foreach my $inv_paper (sort keys %invalid_map) {
#     $inv_paper = 'WBPaper' . $inv_paper;
    if ($paragraph =~ m/WBPaper$inv_paper/) { 
      my @lines = split/\n/, $paragraph;
      my $header = shift @lines;
      my $curator = '';
      if ($header =~ m/WBPaper$inv_paper/) {
        if ($header =~ m/_([^_]*?)\"$/) { $curator = $1; }
#         print OUT "$curator\t$header KEY $inv_paper NOW $invalid_map{$inv_paper}\n\n"; 
#        push @{ $data_hash{$curator} }, "$header HEADER KEY $inv_paper NOW $invalid_map{$inv_paper}\n\n"; 	# skip Object with WBPaper in header since it should be already moved
      }
      else {
# Abstract         -O "2005-02-11_14:19:12_eimear" "WBPaper00024932" -O "2005-02-11_14:19:12_eimear"
#         print OUT "$header\n";
        foreach my $line (@lines) {
          if ($line =~ m/WBPaper$inv_paper/) { 
            if ($line =~ m/_([^_]*?)\"$/) { $curator = $1; }
            if ($line =~ m/Old_WBPaper/) { next; }					# skip Old_WBPaper since it refers to itself
            if ($header =~ m/Author/) { next; }						# skip Author since new paper already has authors 
#             print OUT "$curator\t$line NOW $invalid_map{$inv_paper}\n"; 
            if ($header =~ m/\-O \"[^\"]*\"/) { $header =~ s/\-O \"[^\"]*\"//g; }		# filter out timestamps
            if ($line =~ m/\-O \"[^\"]*\"/) { $line =~ s/\-O \"[^\"]*\"//g; }		# filter out timestamps
#             push @{ $data_hash{$curator} }, "$header\n$line KEY $inv_paper NOW $invalid_map{$inv_paper}\n\n";	# show message of what's there and what should change
            push @{ $data_hash{$curator} }, "$header\n-D $line\n\n";  			# show message of what's there and what should change
            $line =~ s/$inv_paper/$invalid_map{$inv_paper}/g;				# switch papers
            push @{ $data_hash{$curator} }, "$header\n$line\n\n";  			# show message of what's there and what should change
          } # if ($line =~ m/WBPaper$inv_paper/) 
        } # foreach my $line (@lines)
#         print OUT "\n";
      }
    } # if ($paragraph =~ m/WBPaper/) 
  } # foreach my $file (@flatfiles)
} # while (my $paragraph = <IN>)
close (IN) or die "Cannot close $infile : $!";


foreach my $curator (sort keys %data_hash) {
  print OUT "// START $curator\n";
  foreach my $line (@{ $data_hash{$curator} }) {
    print OUT $line;
  } # foreach my $line (@{ $data_hash{$curator} })
  print OUT "\n";
} # foreach my $curator (sort keys %data_hash)

my $end = &getSimpleSecDate();
my $etime = time;
my $diff = $etime - $stime;
print OUT "// END $end $etime $diff END\n";

close (OUT) or die "Cannot close $outfile : $!";

`mv merged_papers.cgi merged_papers.cgi.$start`;

sub getSimpleSecDate {                  # begin getSimpleDate
  my $time = time;                      # set time
  my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) =
          localtime($time);             # get time
  my $sam = $mon+1;                     # get right month
  $year = 1900+$year;                   # get right year in 4 digit form
  if ($sam < 10) { $sam = "0$sam"; }    # add a zero if needed
  if ($mday < 10) { $mday = "0$mday"; } # add a zero if needed
  if ($sec < 10) { $sec = "0$sec"; } # add a zero if needed
  if ($min < 10) { $min = "0$min"; } # add a zero if needed
  if ($hour < 10) { $hour = "0$hour"; } # add a zero if needed
  my $shortdate = "${year}${sam}${mday}.${hour}${min}${sec}";   # get final date
  return $shortdate;
} # sub getSimpleSecDate
