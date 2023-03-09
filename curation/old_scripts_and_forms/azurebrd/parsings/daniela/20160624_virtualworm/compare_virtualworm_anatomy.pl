#!/usr/bin/perl -w

# compare canopus files with obo_name_anatomy and obo_syn_anatomy for Daniela.  2016 06 24

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );
use LWP::Simple;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %anat;
$result = $dbh->prepare( "SELECT * FROM obo_syn_anatomy" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[1]) { 
    my $name = $row[1];
    if ($row[1] =~ m/lineage name: (.*)/) { $name = $1; }
    ($name) = lc($name);
    $anat{$name} = $row[0];
  } # if ($row[0])
} # while (@row = $result->fetchrow)
$result = $dbh->prepare( "SELECT * FROM obo_name_anatomy" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[1]) { 
    ($row[1]) = lc($row[1]);
    $anat{$row[1]} = $row[0];
  } # if ($row[0])
} # while (@row = $result->fetchrow)

my %files; my %dirs;
my @directories;
my $rootDir = 'http://canopus.caltech.edu/virtualworm/Anatomy_Images/';
$dirs{$rootDir}++;
push @directories, $rootDir;
while (my $curdir = shift @directories) { 
  my $data = get $curdir;
  my (@href) = $data =~ m/<a href=\"([^\/][^\"]*)\">/g;
  foreach my $href (@href) {
    next if ($href =~ m/\?/);
    if ($href =~ m/\/$/) { 
      my $newdir = $curdir . $href;
      unless ($dirs{$newdir}) {
        push @directories, $newdir;
        $dirs{$newdir}++;
      }
    } else { $files{$href} = $curdir; }
  }
#   print qq($data\n);
}

foreach my $dir (sort keys %dirs) { 
  print qq(DIR $dir\n);
}

foreach my $file (sort keys %files) { 
  my ($lcfile) = lc($file);
  $lcfile =~ s/\..*//;
  $lcfile =~ s/_/ /g;
  my $goodBad = 'bad';
  my $wbbt = '';
  if ($anat{$lcfile}) {
    $wbbt = $anat{$lcfile};
    $goodBad = 'good';
  }
  print qq(FILE $file\t$lcfile\t$goodBad\t$wbbt\t$files{$file}\n);
}

__END__


my $local_dir = '/home/acedb/daniel';
chdir($local_dir) or die "Cannot chdir to $local_dir : $!";


my %hardcopy;

my ($date) = &getSimpleSecDate();
my $start_time = time;
# my $estimate_time = time + 336;         # estimate 336 seconds
# my $estimate_time = time + 853;         # estimate 853 seconds
my $estimate_time = time + 683;         # estimate 683 seconds
my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) =
localtime($estimate_time);             # get time
if ($sec < 10) { $sec = "0$sec"; }    # add a zero if needed
if ($min < 10) { $min = "0$min"; }    # add a zero if needed
# print "START $date -> Estimate $hour:$min:$sec\n";


my $outfile = 'populate_electronic_path_type.out.' . $date;
open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
my $errfile = 'populate_electronic_path_type.err.' . $date;
open (ERR, ">$errfile") or die "Cannot create $errfile : $!";

my $body;


my $folder = "/home/acedb/public_html/daniel/";


my %convertToWBPaper;
my %backwards;
&readConversions;

my %validPap;
my $result = $dbh->prepare( "SELECT joinkey FROM pap_status WHERE pap_status = 'valid';" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) { $validPap{$row[0]}++; }

my %inPg;	# paths already in pg
# my $result = $dbh->prepare( "SELECT * FROM wpa_electronic_path_type ORDER BY wpa_timestamp DESC;" );
$result = $dbh->prepare( "SELECT * FROM pap_electronic_path WHERE joinkey IN (SELECT joinkey FROM pap_status WHERE pap_status = 'valid');" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) {
  my $joinkey = $row[0];
  my $path = $row[1];
  if ($path =~ m/\'/) { $path =~ s/\'/''/g; }
  my $order = $row[2];
  my $curator = $row[3];

#   my $type = $row[2];
#   my $valid = $row[3];
#   my $curator = $row[4];
  unless ($inPg{$path}) {
#     $inPg{$path}{valid} = $valid;
#     $inPg{$path}{type} = $type;
    $inPg{$path}{order} = $order;
    $inPg{$path}{joinkey} = $joinkey;
    $inPg{$path}{curator} = $curator;
  } # unless ($inPg{valid}{$path})
} # while (my @row = $result->fetchrow)


my @not_in_daniel;	# get paths that are not in Daniel's path
foreach my $path (sort keys %inPg) {
  if ( ($path !~ m/^\/home\/acedb\/daniel\/Reference\/cgc\//) && ($path !~ m/^\/home\/acedb\/daniel\/Reference\/pubmed\//) ) {
      push @not_in_daniel, $path; } 	# put non-daniel path in array @not_in_daniel
#   if ($inPg{$path}{valid} eq 'valid') {
#     if ( ($path !~ m/^\/home\/acedb\/daniel\/Reference\/cgc\//) && ($path !~ m/^\/home\/acedb\/daniel\/Reference\/pubmed\//) ) {
#       push @not_in_daniel, $path; } }	# put non-daniel path in array @not_in_daniel
#   else { delete $inPg{$path}; }		# get rid of non-valid paths
} # foreach my $path (sort keys %inPg)

foreach my $file (@not_in_daniel) {
  if (-e $file) { next; }	# file exists, let it be
  my $joinkey = $inPg{$file}{joinkey};
#   my $type = $inPg{$file}{type};
#   my $result = $dbh->do( "INSERT INTO wpa_electronic_path_type VALUES ('$joinkey', '$file', '$type', 'invalid', 'two736', CURRENT_TIMESTAMP); ");
#   print OUT "my \$result = \$dbh->do( \"INSERT INTO wpa_electronic_path_type VALUES ('$joinkey', '$file', '$type', 'invalid', 'two736', CURRENT_TIMESTAMP); \"); \n";

  my $order = $inPg{$file}{order};
# UNCOMMENT
  my $result = $dbh->do( "INSERT INTO h_pap_electronic_path VALUES ('$joinkey', NULL, '$order', 'two736', CURRENT_TIMESTAMP); ");
  print OUT "my \$result = \$dbh->do( \"INSERT INTO h_pap_electronic_path VALUES ('$joinkey', NULL, '$order', 'two736', CURRENT_TIMESTAMP); \"); \n";
# UNCOMMENT
  $result = $dbh->do( "DELETE FROM pap_electronic_path WHERE joinkey = '$joinkey' AND pap_order = '$order'; ");
  print OUT "my \$result = \$dbh->do( \"DELETE FROM pap_electronic_path WHERE joinkey = '$joinkey'AND pap_order = '$order'; \"); \n";
  $body .= "$file not found, made invalid WBPaper $joinkey \n";
#   $body .= "$file not found, made invalid WBPaper $joinkey  Type $type\n";
  delete $inPg{$file};
  my ($short_file) = $file =~ m/.*\/(.*?)/; 
  my $html_path = $folder . $short_file;
  if (-l $html_path) { unlink $html_path or warn "cannot unlink : $!"; }
}


my %inDir;	# paths in tazendra, not in pg

my @Reference; my @Reference2;
my @directory; my @file;

@Reference = </home/acedb/daniel/Reference/cgc/*>;
foreach (@Reference) {
  if (-d $_) { push @directory, $_; }
  if (-f $_) { push @file, $_; }
} # foreach (@Reference)
foreach (@directory) {
  my @array = <$_/*>;
  foreach (@array) {
    if (-d $_) { push @directory, $_; }
    if (-f $_) { push @file, $_; }
  } # foreach (@array)
}
foreach my $file (@file) {
  my ($file_name) = $file =~ m/.*\/(.*?)$/;
  if ($file_name !~ m/\.pdf$/i) { next; }		# skip non-pdfs
  my ($cgc) = $file_name =~ m/^_*(\d+).*/;	# some files start with _ for some reason
  $cgc = 'cgc' . $cgc;
  my $wbid = 0;
  if ($convertToWBPaper{$cgc}) {
    $wbid = $convertToWBPaper{$cgc};
    $wbid =~ s/WBPaper//g;
#     my $type = '1';
#     if ($file_name =~ m/lib\.pdf/) { $type = '2'; }
#     elsif ($file_name =~ m/tif\.pdf/) { $type = '3'; }
#     elsif ($file_name =~ m/html\.pdf/) { $type = '4'; }
#     elsif ($file_name =~ m/ocr\.pdf/) { $type = '5'; }
#     elsif ($file_name =~ m/temp\.pdf/) { $type = '7'; }
#     else { $type = '1'; }
    if ($file =~ m/\'/) { $file =~ s/\'/''/g; }
#     my $result = $dbh->do( "INSERT INTO wpa_electronic_path_type VALUES ('$wbid', '$file', '$type', 'valid', 'two736', CURRENT_TIMESTAMP); ");
#     print OUT "my \$result = \$dbh->do( \"INSERT INTO wpa_electronic_path_type VALUES ('$wbid', '$file', '$type', 'valid', 'two736', CURRENT_TIMESTAMP); \"); \n";
#     $inDir{$file}{type} = $type;
    $inDir{$file}{joinkey} = $wbid;
  }
  else { print ERR "NO NUM $cgc FILE $file\n"; }
}

@Reference = </home/acedb/daniel/Reference/wb/libpdf/*>;
foreach (@Reference) {
  if (-d $_) { push @directory, $_; }
  if (-f $_) { push @file, $_; }
} # foreach (@Reference)
@Reference = </home/acedb/daniel/Reference/wb/pdf/*>;
foreach (@Reference) {
  if (-d $_) { push @directory, $_; }
  if (-f $_) { push @file, $_; }
} # foreach (@Reference)
foreach (@directory) {
  my @array = <$_/*>;
  foreach (@array) {
    if (-d $_) { push @directory, $_; }
    if (-f $_) { push @file, $_; }
  } # foreach (@array)
}
foreach my $file (@file) {
  my ($file_name) = $file =~ m/.*\/(.*?)$/;
  if ($file_name !~ m/\.pdf$/i) { next; }		# skip non-pdfs
  my ($wb) = $file_name =~ m/^_*(\d+).*/;	# some files start with _ for some reason
  my ($wbid) = &padZeros($wb);
#   my $type = '1';
#   if ($file_name =~ m/lib\.pdf/) { $type = '2'; }
#   elsif ($file_name =~ m/tif\.pdf/) { $type = '3'; }
#   elsif ($file_name =~ m/html\.pdf/) { $type = '4'; }
#   elsif ($file_name =~ m/ocr\.pdf/) { $type = '5'; }
#   elsif ($file_name =~ m/temp\.pdf/) { $type = '7'; }
#   else { $type = '1'; }
  if ($file =~ m/\'/) { $file =~ s/\'/''/g; }
#   my $result = $dbh->do( "INSERT INTO wpa_electronic_path_type VALUES ('$wbid', '$file', '$type', 'valid', 'two736', CURRENT_TIMESTAMP); ");
#   print OUT "my \$result = \$dbh->do( \"INSERT INTO wpa_electronic_path_type VALUES ('$wbid', '$file', '$type', 'valid', 'two736', CURRENT_TIMESTAMP); \"); \n";
#   $inDir{$file}{type} = $type;
  $inDir{$file}{joinkey} = $wbid;
}


@directory = ();							# get supplemental directories from Path   2006 11 14
@Reference = </home/acedb/daniel/Reference/wb/supplemental/*>;
foreach (@Reference) { if (-d $_) { push @directory, $_; } }
foreach my $dir (@directory) {
#   my $type = '8';		# supplemental directory
  my ($file_name) = $dir =~ m/.*\/(.*?)$/;
  my ($wb) = $file_name =~ m/^(\d+).*/;
  my ($wbid) = &padZeros($wb);
#   $inDir{$dir}{type} = $type;
  $inDir{$dir}{joinkey} = $wbid;
}


@directory = ();
@file = ();
@Reference = </home/acedb/daniel/Reference/pubmed/*>;
foreach (@Reference) {
  if (-d $_) { push @directory, $_; }
  if (-f $_) { push @file, $_; }
} # foreach (@Reference)
foreach (@directory) {
  my @array = <$_/*>;
  foreach (@array) {
    if (-d $_) { push @directory, $_; }
    if (-f $_) { push @file, $_; } } }

foreach my $file (@file) {
  my ($file_name) = $file =~ m/.*\/(.*?)$/;
  if ($file_name !~ m/\.pdf$/i) { next; }		# skip non-pdfs
  my ($pmid) = $file_name =~ m/(\d+).*/;
  $pmid = 'pmid' . $pmid;
  my $wbid = 0;
  if ($convertToWBPaper{$pmid}) {
    $wbid = $convertToWBPaper{$pmid};
    $wbid =~ s/WBPaper//g;
#     my $type = '1';
#     if ($file_name =~ m/lib\.pdf/) { $type = '2'; }
#     elsif ($file_name =~ m/tif\.pdf/) { $type = '3'; }
#     elsif ($file_name =~ m/html\.pdf/) { $type = '4'; }
#     elsif ($file_name =~ m/ocr\.pdf/) { $type = '5'; }
#     elsif ($file_name =~ m/aut\.pdf/) { $type = '6'; }
#     elsif ($file_name =~ m/temp\.pdf/) { $type = '7'; }
#     else { $type = '1'; }
    if ($file =~ m/\'/) { $file =~ s/\'/''/g; }
#     my $result = $dbh->do( "INSERT INTO wpa_electronic_path_type VALUES ('$wbid', '$file', '$type', 'valid', 'two736', CURRENT_TIMESTAMP); ");
#     print OUT "my \$result = \$dbh->do( \"INSERT INTO wpa_electronic_path_type VALUES ('$wbid', '$file', '$type', 'valid', 'two736', CURRENT_TIMESTAMP); \"); \n";
#     $inDir{$file}{type} = $type;
    $inDir{$file}{joinkey} = $wbid;
  }
  else { print ERR "NO NUM $pmid FILE $file\n"; }
}

foreach my $path (sort keys %inDir) {
  if ($inPg{$path}) { delete $inPg{$path}; delete $inDir{$path}; }
} # foreach my $path (sort keys %inDir)

foreach my $path (sort keys %inDir) {
#   my $type = $inDir{$path}{type};
  my $joinkey = $inDir{$path}{joinkey};
  next unless $validPap{$joinkey};
  my $result = $dbh->prepare( "SELECT pap_order FROM pap_electronic_path WHERE joinkey = '$joinkey' ORDER BY pap_order DESC; "); 
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  my @row = $result->fetchrow();
  my $order = $row[0]; $order++;

# UNCOMMENT
  $result = $dbh->do( "INSERT INTO pap_electronic_path VALUES ('$joinkey', '$path', '$order', 'two736', CURRENT_TIMESTAMP); "); 
  print OUT "my \$result = \$dbh->do( \"INSERT INTO pap_electronic_path VALUES ('$joinkey', '$path', '$order', 'two736', CURRENT_TIMESTAMP); \"); \n"; 
# UNCOMMENT
  $result = $dbh->do( "INSERT INTO h_pap_electronic_path VALUES ('$joinkey', '$path', '$order', 'two736', CURRENT_TIMESTAMP); "); 
  print OUT "my \$result = \$dbh->do( \"INSERT INTO h_pap_electronic_path VALUES ('$joinkey', '$path', '$order', 'two736', CURRENT_TIMESTAMP); \"); \n"; 

#   my $result = $dbh->do( "INSERT INTO wpa_electronic_path_type VALUES ('$joinkey', '$path', '$type', 'valid', 'two736', CURRENT_TIMESTAMP); "); 
#   print OUT "my \$result = \$dbh->do( \"INSERT INTO wpa_electronic_path_type VALUES ('$joinkey', '$path', '$type', 'valid', 'two736', CURRENT_TIMESTAMP); \"); \n";
#   $body .= "$path new, made valid WBPaper $joinkey  Type $type\n";
  $body .= "$path new, made valid WBPaper $joinkey\n";
  my ($short_file) = $path =~ m/.*\/(.*?)$/; 
  my $html_path = $folder . $short_file;
  unless (-l $html_path) {
    symlink($path, $html_path) or warn "cannot symlink $path to $html_path"; }
}

foreach my $path (sort keys %inPg) {
#   my $type = $inPg{$path}{type};
  my $joinkey = $inPg{$path}{joinkey};
  next unless $validPap{$joinkey};
  my $order = $inPg{$path}{order};
#   my $result = $dbh->do( "INSERT INTO wpa_electronic_path_type VALUES ('$joinkey', '$path', '$type', 'invalid', 'two736', CURRENT_TIMESTAMP); "); 
#   print OUT "my \$result = \$dbh->do( \"INSERT INTO wpa_electronic_path_type VALUES ('$joinkey', '$path', '$type', 'invalid', 'two736', CURRENT_TIMESTAMP); \"); \n";

# UNCOMMENT
  my $result = $dbh->do( "INSERT INTO h_pap_electronic_path VALUES ('$joinkey', NULL, '$order', 'two736', CURRENT_TIMESTAMP); ");
  print OUT "my \$result = \$dbh->do( \"INSERT INTO h_pap_electronic_path VALUES ('$joinkey', NULL, '$order', 'two736', CURRENT_TIMESTAMP); \"); \n";
# UNCOMMENT
  $result = $dbh->do( "DELETE FROM pap_electronic_path WHERE joinkey = '$joinkey' AND pap_order = '$order'; ");
  print OUT "my \$result = \$dbh->do( \"DELETE FROM pap_electronic_path WHERE joinkey = '$joinkey'AND pap_order = '$order'; \"); \n";

#   $body .= "$path not found, made invalid WBPaper $joinkey  Type $type\n";
  $body .= "$path not found, made invalid WBPaper $joinkey\n";
  my ($short_file) = $path =~ m/.*\/(.*?)/; 
  my $html_path = $folder . $short_file;
  if (-l $html_path) { unlink $html_path or warn "cannot unlink : $!"; }
}

unless ($body) { $body = "linker script ran, no changes\n"; }
&mailer('linker_script', 'qwang@its.caltech.edu', 'linker script changes', $body);
# &mailer('linker_script', 'azurebrd@tazendra.caltech.edu', 'linker script changes', $body);



close (ERR) or die "Cannot close $errfile : $!";
close (OUT) or die "Cannot close $outfile : $!";




($date) = &getSimpleSecDate();
# print "END $date\n";
my $end_time = time;
my $diff_time = $end_time - $start_time;
# print "DIFF $diff_time seconds\n";



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

