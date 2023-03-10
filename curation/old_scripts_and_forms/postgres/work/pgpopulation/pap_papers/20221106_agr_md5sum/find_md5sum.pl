#!/usr/bin/perl -w

# process files for agr to get md5sum and metadata

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );
use Digest::MD5::File qw( file_md5_hex );

# my $some_file_name = 'test_md5.pl';
# my $md5 = file_md5_hex( $some_file_name );
# print qq($md5\n);

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %convertToWBPaper;
my %backwards;
# &readConversions;

my %inDir;      # paths in tazendra, not in pg
my @Reference; my @Reference2;
my @directory; my @file;

my $dir_root = '/home/acedb/daniel/Reference/';

@Reference = <${dir_root}cgc/*>;
foreach (@Reference) {
  if (-d $_) { push @directory, $_; }
  if (-f $_) { push @file, $_; }
} # foreach (@Reference)
# foreach (@directory) {
#   my @array = <$_/*>;
#   foreach (@array) {
#     if (-d $_) { push @directory, $_; }
#     if (-f $_) { push @file, $_; } } }

@Reference = <${dir_root}pubmed/*>;
foreach (@Reference) {
  if (-d $_) { push @directory, $_; }
  if (-f $_) { push @file, $_; }
} # foreach (@Reference)
foreach (@directory) {
  my @array = <$_/*>;
  foreach (@array) {
    if (-d $_) { push @directory, $_; }
    if (-f $_) { push @file, $_; } } }

@Reference = <${dir_root}wb/libpdf/*>;
foreach (@Reference) {
  if (-d $_) { push @directory, $_; }
  if (-f $_) { push @file, $_; }
} # foreach (@Reference)
@Reference = <${dir_root}wb/pdf/*>;
foreach (@Reference) {
  if (-d $_) { push @directory, $_; }
  if (-f $_) { push @file, $_; }
} # foreach (@Reference)
# foreach (@directory) {
#   my @array = <$_/*>;
#   foreach (@array) {
#     if (-d $_) { push @directory, $_; }
#     if (-f $_) { push @file, $_; }
#   } # foreach (@array)
# }

# supplemental files don't match regex below
@Reference = <${dir_root}wb/supplemental/*>;
foreach (@Reference) {
  if (-d $_) { push @directory, $_; }
  if (-f $_) { push @file, $_; }
} # foreach (@Reference)
# foreach (@directory) {
#   my @array = <$_/*>;
#   foreach (@array) {
#     if (-d $_) { push @directory, $_; }
#     if (-f $_) { push @file, $_; } } }


# Kimberly : 
# Which directories should allow only PDFs ?
# Can we rename files to not have apostrophes ?
# Need to have all md5sum only refer to one file, otherwise we don't know what to connect it to, or we can't tell if something got renamed, we'd just add an additional connection to the same file.  But ABC can only have 1 metadata for each md5sum



my %types;
my $count = 0;

# generate md5sum mapping to path_file
# foreach my $file (@file) {
# #   $count++; last if ($count > 5);
#   my $md5 = file_md5_hex( $file );
#   print qq($md5\t$file\n);
# }

# find files that don't match expected naming pattern
# foreach my $file (@file) {
#   $file =~ s/$dir_root//;
#   my ($path, $file_name) = $file =~ m/^(.*\/)(.*?)$/;
#   if ($file !~ m/supplement/) {
#     if ($file_name !~ m/\.pdf$/i) { print qq(NOT PDF $file\n); }
#     if ($file_name !~ m/\.pdf$/i) { next; }               # skip non-pdfs
#     if ($file =~ m/^wb\/[a-z]+\/(\d{8})[^\d]/) { 
#         if ($file_name !~ m/^\d{8}_[\-A-Za-z]+\d{2}(_[A-Za-z]+)?\.pdf$/i) { print qq(NOT REGEX $file\n); } }
#       elsif ( ($file =~ m/^pubmed/) || ($file =~ m/^cgc/) ) {
#         if ($file_name !~ m/^\d+_[\-A-Za-z]+\d{2}(_[A-Za-z]+)?\.pdf$/i) { print qq(NOT REGEX $file\n); } }
#   }
#   # print qq(P $path F $file_name\n);
# }

# wb files have 8 digits
#   if ($file_name !~ m/^\d{8}_[\-A-Za-z]+\d{2}(_[A-Za-z]+)?\.pdf$/i) { print qq(NOT REGEX $file\n); }
# cgc + pubmed files have various amount of digits
#   if ($file_name !~ m/^\d+_[\-A-Za-z]+\d{2}(_[A-Za-z]+)?\.pdf$/i) { print qq(NOT REGEX $file\n); }


foreach my $file (@file) {
#   $count++; last if ($count > 5);
#   my $md5 = file_md5_hex( $file );
#   print qq($md5\t$file\n);
#   next;
  my $md5 = '';

  $file =~ s/$dir_root//;
  my ($path, $file_name) = $file =~ m/^(.*\/)(.*?)$/;
  if ($file !~ m/supplement/) {
    if ($file_name !~ m/\.pdf$/i) { print qq(NOT PDF $file\n); }
    if ($file_name !~ m/\.pdf$/i) { next; }               # skip non-pdfs
  }
  # print qq(P $path F $file_name\n);

#   my $papid = 0;
#   my $wbp = '';
#   if ($file =~ m/supplement/) { $wb_class = 'supplement'; }
#   if ($file =~ m/^wb\/[a-z]+\/(\d{8})[^\d]/) { $papid = $1; }
#     elsif ($file =~ m/^pubmed/) { $papid = &getPapJoinkeyFromPmid($file); }
#     elsif ($file =~ m/^cgc/) { $papid = &getPapJoinkeyFromCgc($file); }
#     if ($papid > 0) {
#       my $wbp = 'WB:WBPaper' . $papid; }

  # this is not the right way to find names, use code from below later
  my ($wb) = $file_name =~ m/^_*(\d+).*/;       # some files start with _ for some reason
  my $wbid = '';
  if ($wb) { ($wbid) = &padZeros($wb); }

  my $ext = '';
  my $file_wo_ext = '';
  if ($file_name =~ m/^(.*)\.(\w+)$/) { $file_wo_ext = $1; $ext = lc($2); }
  my $type = '';
  if ($ext eq 'pdf') { $type = 'pdf'; }
  if ($file !~ m/supplement/) {
    if ($file_name =~ m/[a-z][0-9][0-9]_(.*?)\.pdf/) { $type = $1; push @{ $types{$type} }, $file; }
  }
#   if ($file_name =~ m/lib\.pdf/) { $type = 'lib'; }
#   elsif ($file_name =~ m/tif\.pdf/) { $type = 'tif'; }
#   elsif ($file_name =~ m/html\.pdf/) { $type = 'html'; }
#   elsif ($file_name =~ m/ocr\.pdf/) { $type = 'ocr'; }
#   elsif ($file_name =~ m/temp\.pdf/) { $type = 'temp'; }
#   elsif ($file_name =~ m/aut\.pdf/) { $type = 'aut'; }
#   elsif ($file_name =~ m/proof\.pdf/) { $type = 'proof'; }
#   else { $type = 'pdf'; }
#   if ($file =~ m/\'/) { $file =~ s/\'/''/g; }
#   print qq(F\t$path\t$file_wo_ext\t$ext\t$type\t$md5\n);
  $inDir{$file}{joinkey} = $wbid;
}

# output main file types
# foreach my $type (sort keys %types) { 
#   my @list = @{ $types{$type} };
#   my $count = scalar @list;
#   print qq($type\t$count\n);
# #   print qq($type\t$types{$type}\n);
# }
# 
# print qq(\n);
# foreach my $type (sort keys %types) { 
#   my @list = @{ $types{$type} };
#   my $count = scalar @list;
#   if ($count < 300) {
#     print qq($type\t$count\n);
#     foreach my $file (@list) {
#       print qq($file\n);
#     }
#     print qq(\n);
#   }
# #   print qq($type\t$types{$type}\n);
# }



# PUT THIS BACK LATER
#
# my %inPg;
# my $previous_entry_file = 'md5_all';
# open (IN, "<$previous_entry_file") or die "Cannot open $previous_entry_file : $!";
# while (my $line = <IN>) {
#   chomp $line;
#   my ($md5sum, $path) = split/\t/, $line;
#   $inPg{path}{$path} = $md5sum; 
#   $inPg{md5}{$md5sum} = $path; 
# }
# close (IN) or die "Cannot close $previous_entry_file : $!";
# 
# my %new_md5;
# foreach my $path (sort keys %inDir) {
#   unless ($inPg{path}{$path}) { 
#     print qq(not in pg\t$path\n);
#     my $full_file_path = $dir_root . $path;
#     my $md5 = file_md5_hex( $full_file_path );
#     $new_md5{$md5} = $path;
#     if ($inPg{md5}{$md5}) { 
# # maybe when reading from md5_all, skip cgc that are not .pdf ?
# # FIX handling this twice
# # add to PG, change inPg{md5} and inPg{path}
#       my $oldPgPath = $inPg{md5}{$md5};
#       delete $inPg{path}{$oldPgPath};
#       $inPg{md5}{$md5} = $path;
#       $inPg{path}{$path} = $md5;
#       print qq(renamed inDir\t$md5\t$path\n); }
#     else {
# # add to PG
#       $inPg{md5}{$md5} = $path;
#       $inPg{path}{$path} = $md5;
#       print qq(new\t$md5\n); }
#   }
# } # foreach my $path (sort keys %inPg)
# 
# foreach my $path (sort keys %{ $inPg{path} }) {
#   unless ($inDir{$path}) { 
#     print qq(not in filesystem\t$path\n);
#     my $pg_md5 = $inPg{path}{$path};
#     if ($new_md5{$pg_md5}) {
# # FIX handling this twice.  This still happens because the same md5sum exists for different files in directories
#       print qq(CANT renamed inPg\t$pg_md5\t$new_md5{$pg_md5}\n); }
#     else {
#       print qq(deleted\t$pg_md5\tDELETE\n); }
#   }
# } # foreach my $path (sort keys %inPg)


sub getPapJoinkeyFromPmid {
  my $file = shift;
  my ($file_name) = $file =~ m/.*\/(.*?)$/;
  if ($file_name !~ m/\.pdf$/i) { next; }               # skip non-pdfs
  my ($pmid) = $file_name =~ m/(\d+).*/;
  $pmid = 'pmid' . $pmid;
  my $wbid = 0;
  if ($convertToWBPaper{$pmid}) {
    $wbid = $convertToWBPaper{$pmid};
    $wbid =~ s/WBPaper//g;
    return $wbid;
} }

sub getPapJoinkeyFromCgc {
  my $file = shift;
  my ($file_name) = $file =~ m/.*\/(.*?)$/;
  if ($file_name !~ m/\.pdf$/i) { next; }               # skip non-pdfs
  my ($cgc) = $file_name =~ m/^_*(\d+).*/;      # some files start with _ for some reason
  $cgc = 'cgc' . $cgc;
  my $wbid = 0;
  if ($convertToWBPaper{$cgc}) {
    $wbid = $convertToWBPaper{$cgc};
    $wbid =~ s/WBPaper//g;
    return $wbid;
} }

sub readConversions {
#   my $u = "http://tazendra.caltech.edu/~postgres/cgi-bin/wpa_xref_backwards.cgi";
  my $u = "http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/generic.cgi?action=WpaXrefBackwards";
  my $ua = LWP::UserAgent->new(timeout => 30); #instantiates a new user agent
  my $request = HTTP::Request->new(GET => $u); #grabs url
  my $response = $ua->request($request);       #checks url, dies if not valid.
  die "Error while getting ", $response->request->uri," -- ", $response->status_line, "\nAborting" unless $response-> is_success;
  my @tmp = split /\n/, $response->content;    #splits by line
  foreach (@tmp) {
    if ($_ =~m/^(.*?)\t(.*?)$/) {
      my $other = $1; my $wbid = $2;
      unless ($backwards{$wbid}) { $backwards{$wbid} = $other; }
      $convertToWBPaper{$other} = $wbid; } }
} # sub readConversions

sub padZeros {
  my $joinkey = shift;
  if ($joinkey =~ m/^0+/) { $joinkey =~ s/^0+//g; }
  if ($joinkey < 10) { $joinkey = '0000000' . $joinkey; }
  elsif ($joinkey < 100) { $joinkey = '000000' . $joinkey; }
  elsif ($joinkey < 1000) { $joinkey = '00000' . $joinkey; }
  elsif ($joinkey < 10000) { $joinkey = '0000' . $joinkey; }
  elsif ($joinkey < 100000) { $joinkey = '000' . $joinkey; }
  elsif ($joinkey < 1000000) { $joinkey = '00' . $joinkey; }
  elsif ($joinkey < 10000000) { $joinkey = '0' . $joinkey; }
  return $joinkey;
} # sub padZeros

__END__

$result = $dbh->prepare( "SELECT * FROM two_comment" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[1] =~ s///g;
    $row[2] =~ s///g;
    print "$row[0]\t$row[1]\t$row[2]\n";
  } # if ($row[0])
} # while (@row = $result->fetchrow)

__END__

