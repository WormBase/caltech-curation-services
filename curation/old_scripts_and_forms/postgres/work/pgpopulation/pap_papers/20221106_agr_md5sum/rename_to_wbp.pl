#!/usr/bin/perl -w

# process files for agr to get md5sum and metadata

# files have generated logs and .sh files, which have been executed in acedb account
# and all files have been moved except for conflicts that Daniel would resolve manually.
# don't run this again.  2022 12 09

__END__

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
&readConversions;


my $dir_root = '/home2/acedb/daniel/Reference/';

my $count = 0;


my %inPath;
my $previous_entry_file = 'md5_all';
open (IN, "<$previous_entry_file") or die "Cannot open $previous_entry_file : $!";
while (my $line = <IN>) {
  chomp $line;
#   $count++; last if ($count > 5);
  my ($md5sum, $fullpath) = split/\t/, $line;
  my $file = $fullpath;
  $file =~ s/$dir_root//;
  my ($path, $file_name) = $file =~ m/^(.*\/)(.*?)$/;

#   $inPath{$path} = $md5sum; 
#   print qq(F $file\n);

  my $type = 'no_type';
  if ($file_name =~ m/[a-z][0-9][0-9]_(.*?)\.pdf/) { $type = $1; }

  my $papid = 0;
  my $wbp = '';
#   if ($file =~ m/supplement/) { $wb_class = 'supplement'; }	# supplements filtered out of md5_all
  if ($file =~ m/^wb\/[a-z]+\/(\d{8})[^\d]/) { $papid = $1; }
    elsif ($file =~ m/^pubmed/) { $papid = &getPapJoinkeyFromPmid($file); }
    elsif ($file =~ m/^cgc/) { $papid = &getPapJoinkeyFromCgc($file); }
    if ($papid) {
      $wbp = 'WB:WBPaper' . $papid; }

  if ($wbp) { $inPath{$wbp}{$type}{$md5sum}{$file}++; }
    else { print qq(NO wbpaper for $fullpath\n); }

#   print qq($file_name\t$wbp\t$type\t$md5sum\t$file\n);
}
close (IN) or die "Cannot close $previous_entry_file : $!";

my $conflict_count = 0;
# my $move_one_file_log = 'log_one_file_move';
# my $move_one_md5_log = 'log_one_md5_move';
my $one_file_log = 'log_one_file';
my $one_md5_log = 'log_one_md5';
my $conflict_log = 'log_conflict';
# open (MONE, ">$move_one_file_log") or die "Cannot create $move_one_file_log : $!";
# open (MOMD, ">$move_one_md5_log") or die "Cannot create $move_one_md5_log : $!";
open (ONE, ">$one_file_log") or die "Cannot create $one_file_log : $!";
open (OMD, ">$one_md5_log") or die "Cannot create $one_md5_log : $!";
open (CON, ">$conflict_log") or die "Cannot create $conflict_log : $!";
foreach my $wbp (sort keys %inPath) {
  foreach my $type (sort keys %{ $inPath{$wbp} }) {
    my @any_files = ();
    foreach my $md5 (sort keys %{ $inPath{$wbp}{$type} }) {
      my @md5_files = ();
      foreach my $file (sort keys %{ $inPath{$wbp}{$type}{$md5} }) {
        push @any_files, $file;
#         push @md5_files, $file;
#         if (scalar @md5_files > 1) { 
#           my $files = join", ", @md5_files;
#           print qq(mergeable\t$wbp\t$type\t$md5\t$files\n);
#         }
      } # foreach my $file (sort keys %{ $inPath{$wbp}{$type}{$md5} })
    } # foreach my $md5 (sort keys %{ $inPath{$wbp}{$type} })
    my @md5s = sort keys %{ $inPath{$wbp}{$type} };
    if (scalar @any_files == 1) { 
      # uncomment to generate a log of file moving and a shell script to move files
      # &move_one_file($wbp, $type, $any_files[0]);
      print ONE qq(one file\t$wbp\t$type\t$any_files[0]\n); }
    else {
      if (scalar @md5s == 1) {
        my $files = join", ", sort keys %{ $inPath{$wbp}{$type}{$md5s[0]} };
        # uncomment to generate a log of file moving and a shell script to move files
        # &move_one_md5($wbp, $type, $files);
        print OMD qq(one md5\t$wbp\t$type\t$md5s[0]\t$files\n); }
      else {
#         print ONE qq(many md5\t$wbp\t$type\t$any_files[0]\n);
        $conflict_count++;
        print CON qq($wbp\t$type\n);
        foreach my $md5 (sort keys %{ $inPath{$wbp}{$type} }) {
          my $files = join", ", sort keys %{ $inPath{$wbp}{$type}{$md5} };
          print CON qq($md5\t$files\n); }
        &move_many_md5($wbp, $type, $inPath{$wbp}{$type});
        print CON qq(\n); 
      }
    }
  } # foreach my $type (sort keys %{ $inPath{$wbp} })
} # foreach my $wbp (sort keys %inPath)
print CON qq(\nThere are $conflict_count WBPapers with conflicts\n);
# close (MONE) or die "Cannot create $move_one_file_log : $!";
# close (MOMD) or die "Cannot create $move_one_md5_log : $!";
close (ONE) or die "Cannot close $one_file_log : $!";
close (OMD) or die "Cannot close $one_md5_log : $!";
close (CON) or die "Cannot close $conflict_log : $!";


sub move_many_md5 {
  # for now just figure out which one would be the winning file if there is one, and report conflicts
  my ($wbp, $type, $md5_ref) = @_;
  my %md5_hash = %$md5_ref;
  my %type = ();
  foreach my $md5 (sort keys %md5_hash) {
    foreach my $file (sort keys %{ $md5_hash{$md5} }) {
      # print qq($wbp\t$type\t$md5\t$file\n);
      if ($file =~ m/^wb\/[a-z]+\/(\d{8})[^\d]/) { $type{wb}{$file}++; }
        elsif ($file =~ m/^pubmed/) { $type{pubmed}{$file}++; }
        elsif ($file =~ m/^cgc/) { $type{cgc}{$file}++; }
    }
  }
#   foreach my $file (sort keys %{ $type{pubmed} }) { print qq(PUBMED\t$file\n); }
#   foreach my $file (sort keys %{ $type{cgc} }) { print qq(CGC\t$file\n); }


  my $joinkey = $wbp; $joinkey =~ s/WB:WBPaper//;
  my $new_path = '';
  my $is_ok = 0;
  my $is_not_done = 1;
  my $to_keep = '';
  my @to_move = ();
  if ($type{wb}) {
    if (scalar keys %{ $type{wb} } == 1) {
      my (@files) = keys %{ $type{wb} };
      print CON qq(WB okay\t$files[0]\n);
      my ($path, $file_name) = $files[0] =~ m/^(.*\/)(.*?)$/;
      my ($cgc, $rest_of_name) = $file_name =~ m/^_*(\d+)(.*)/;      # some files start with _ for some reason
      my $sub_dir = 'wb/pdf/';
      if ($type eq 'lib') { $sub_dir = 'wb/libpdf/'; }
      $to_keep = $files[0];
      my $old_path = $dir_root . $files[0];
      unless ($new_path) { $new_path = $dir_root . $sub_dir . $joinkey . $rest_of_name; }
      if ($old_path eq $new_path) { print CON qq(SAME file, nothing to move, $old_path\n); }
        else { 
          # to print things to move to .sh file
          # print qq(mv $old_path $new_path\n);
          print CON qq(mv $old_path $new_path\n); }
      $is_ok = 1;
    } else { 
      print CON qq(WB conflict\n);
    }
    $is_not_done = 0;
  }
  if ($is_not_done) {
    if ($type{pubmed}) {
      if (scalar keys %{ $type{pubmed} } == 1) {
        my (@files) = keys %{ $type{pubmed} };
        print CON qq(PUBMED okay\t$files[0]\n);
        my ($path, $file_name) = $files[0] =~ m/^(.*\/)(.*?)$/;
        my ($cgc, $rest_of_name) = $file_name =~ m/^_*(\d+)(.*)/;      # some files start with _ for some reason
        my $sub_dir = 'wb/pdf/';
        if ($type eq 'lib') { $sub_dir = 'wb/libpdf/'; }
        $to_keep = $files[0];
        my $old_path = $dir_root . $files[0];
        unless ($new_path) { $new_path = $dir_root . $sub_dir . $joinkey . $rest_of_name; }
        if ($old_path eq $new_path) { print CON qq(SAME file, nothing to move, $old_path\n); }
          else { 
            # to print things to move to .sh file
            # print qq(mv $old_path $new_path\n);
            print CON qq(mv $old_path $new_path\n); }
        $is_ok = 1;
      } else { 
        print CON qq(PUBMED conflict\n);
      }
      $is_not_done = 0;
    }
  }
  if ($is_not_done) {
    if ($type{cgc}) {
      if (scalar keys %{ $type{cgc} } == 1) {
        my (@files) = keys %{ $type{cgc} };
        print CON qq(CGC okay\t$files[0]\n);
        my ($path, $file_name) = $files[0] =~ m/^(.*\/)(.*?)$/;
        my ($cgc, $rest_of_name) = $file_name =~ m/^_*(\d+)(.*)/;      # some files start with _ for some reason
        my $sub_dir = 'wb/pdf/';
        if ($type eq 'lib') { $sub_dir = 'wb/libpdf/'; }
        $to_keep = $files[0];
        my $old_path = $dir_root . $files[0];
        unless ($new_path) { $new_path = $dir_root . $sub_dir . $joinkey . $rest_of_name; }
        if ($old_path eq $new_path) { print CON qq(SAME file, nothing to move, $old_path\n); }
          else { 
            # to print things to move to .sh file
            # print qq(mv $old_path $new_path\n);
            print CON qq(mv $old_path $new_path\n); }
        $is_ok = 1;
      } else { 
        print CON qq(CGC conflict\n);
      }
      $is_not_done = 0;
    }
  }
  if ($is_ok) {
      foreach my $type (sort keys %type) {
        foreach my $file (sort keys %{ $type{$type} }) {
          my $old_path = $dir_root . $file;
          unless ($file eq $to_keep) { 
            # to print things to remove to .sh file
            # print qq(rm $old_path\n);
            print CON qq(rm $old_path\n); } } } }
    else { print CON qq(NOT OK\n); }
#   print qq(\n);
} # sub move_many_md5


sub move_one_md5 {
  my ($wbp, $type, $files) = @_;
  my @files = split/, /, $files;
  my $joinkey = $wbp; $joinkey =~ s/WB:WBPaper//;
  my ($path, $file_name) = $files[0] =~ m/^(.*\/)(.*?)$/;
  my ($cgc, $rest_of_name) = $file_name =~ m/^_*(\d+)(.*)/;      # some files start with _ for some reason
  my $sub_dir = 'wb/pdf/';
  if ($type eq 'lib') { $sub_dir = 'wb/libpdf/'; }
  my $new_path = $dir_root . $sub_dir . $joinkey . $rest_of_name;
  # print qq(N $new_path\n);
  my $already_there = 0;
  my @to_move = ();
  foreach my $file (@files) {
    my $old_path = $dir_root . $file;
    print MOMD qq(WANT TO mv $old_path $new_path\n);
    if ($old_path eq $new_path) { print MOMD qq(SAME file, nothing to move, $old_path\n); $already_there++; }
      else { 
        print MOMD qq(ADD to move queue : $old_path\n);
        push @to_move, qq($old_path); }
  }
  unless ($already_there) { 
    my $first_to_move = shift @to_move;
    if (-e $new_path) { print MOMD qq(ERROR file exists at $new_path trying to move $first_to_move\n); }
      else { 
        print qq(mv $first_to_move $new_path\n);
        print MOMD qq(MOVE $first_to_move $new_path\n); }
  }
  foreach my $to_delete (@to_move) {
    print qq(rm $to_delete\n);
    print MOMD qq(DELETE $to_delete\n);
  }
  print MOMD qq(\n);
}

sub move_one_file {
  my ($wbp, $type, $file) = @_;
  my $joinkey = $wbp; $joinkey =~ s/WB:WBPaper//;
  my ($path, $file_name) = $file =~ m/^(.*\/)(.*?)$/;
  my ($cgc, $rest_of_name) = $file_name =~ m/^_*(\d+)(.*)/;      # some files start with _ for some reason
  my $sub_dir = 'wb/pdf/';
  if ($type eq 'lib') { $sub_dir = 'wb/libpdf/'; }
  my $old_path = $dir_root . $file;
  my $new_path = $dir_root . $sub_dir . $joinkey . $rest_of_name;
  if ($old_path eq $new_path) { print MONE qq(SAME file, nothing to move, $old_path\n); return; }
  if (-e $new_path) { print MONE qq(ERROR file exists at $new_path trying to move $old_path\n); }
#   print qq(move $old_path $new_path\n);
  print qq(mv $old_path $new_path\n);
}


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

