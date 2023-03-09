#!/usr/bin/perl 

# All PDFs on Tazendra

# List & Link all PDFs On The Fly from /home3/allpdfs/ and Athena

# This cgi gets all the PDFs form /home3/allpdfs/ and makes a link to them.
#
# Updated to stop relying on wormbase connection being up   2002 04 29
#
# Updated to link to Athena PDFs  2002 05 16
#
# Updated to use shell's readlink to get the paper type for Michael.  2011 06 02
#       
# http://tazendra.caltech.edu/~azurebrd/cgi-bin/allpdfs.cgi?action=textpresso
# http://tazendra.caltech.edu/~azurebrd/cgi-bin/allpdfs.cgi?action=withSubdir
# http://tazendra.caltech.edu/~azurebrd/cgi-bin/allpdfs.cgi?action=normal
# Split into 3 actions, normal by default based on symlinks ;  withSubdir to
# slowly get subdirectories with readlink ;  textpresso  to loop through all
# subdirs and sub-subdirs to look for stuff for Michael.  2011 06 03



use LWP::Simple;
use Jex;
use CGI;
use Fcntl;

my $query = new CGI;

# make beginning of HTML page

print "Content-type: text/html\n\n";
# print "$header";

my ($var, $action) = &getHtmlVar($query, 'action');
unless ($action) { $action = 'normal'; }

if ($action eq 'normal') { &normalDisplay(); }
elsif ($action eq 'withSubdir') { &subdirDisplay(); }
elsif ($action eq 'textpresso') { &textpressoDisplay(); }

sub textpressoDisplay {
  my $url_root = 'http://tazendra.caltech.edu/~acedb/daniel';
  my $symlink_path = '/home/acedb/public_html/daniel';
  my @allpdfs = <${symlink_path}/*.pdf>;
  my %symlinks;
  foreach my $symlink (@allpdfs) { 
    chomp; 
    my ($filename) = $symlink =~ m/([^\/]*?)$/;
    $symlink =~ s/$symlink_path/$url_root/;
    $symlinks{$filename} = $symlink; }
  my $root_path = '/home/acedb/daniel/Reference/';
  my @sub1 = qw( wb cgc pubmed );
  my @sub2 = qw( pdf supplemental );
  foreach my $sub2 (@sub2) {
    foreach my $sub1 (@sub1) {
      my $path = $root_path . $sub1 . '/' . $sub2;
      my (@Reference) = <$path/*>;
      my @directory; my @file;
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
      } # foreach (@directory)
      foreach my $file (@file) {
        my ($filename) = $file =~ m/([^\/]*?)$/;
        next if ($filename =~ m/_lib.pdf/);	# 2022 12 09  libpdf/* is moving into pdf/ so exclude _lib.pdf for textpresso
        my $symlink = $file; $symlink =~ s/$path/$symlink_path/;
        my $url = '';
        if ($symlinks{$filename}) { 
            $url = $symlinks{$filename}; 
            $url =~ s/$path/$url_root/; }
          elsif (-e $symlink) { 	# this doesn't work for supplementals, they're not symlinked
            $url = $symlink;
            $url =~ s/$symlink_path/$url_root/; }
#         print "<A HREF=\"http://tazendra.caltech.edu/~acedb/daniel/$_\">$_</A> $paper_type<BR>\n";
        if ($url) { print "$sub2\t$sub1\t<a href=\"$url\">$url</a><br/>\n"; }
#         if ($url) { print "$sub2\t$sub1\t$url<br/>\n"; }
      } # foreach my $file (@file)
    } # foreach my $sub1 (@sub1)
  } # foreach my $sub2 (@sub2)
# /home/acedb/daniel/Reference/(wb|cgc|pubmed)/supplemental/
} # sub textpressoDisplay

sub subdirDisplay {
  print "Directory of Athena <A HREF=\"http://athena.caltech.edu/~daniel/tif_pdf/\">PDFs</A>. (Individually listed below)<BR><P><BR>\n";

  print "<P>Tazendra PDFs : <BR>\n";
  # my @allpdfs = </home3/allpdfs/*.pdf>;
  my @allpdfs = </home/acedb/public_html/daniel/*.pdf>;
  foreach $_ (@allpdfs) {
    chomp;
    my $symlink = `readlink $_`;
    my $paper_type = '';
    if ($symlink =~ m|/home/acedb/daniel/Reference/(.*?)/pdf/|) { $paper_type = $1; }
  #  $_ =~ m/\/home3\/allpdfs\/(.*)/;
    $_ =~ m/\/home\/acedb\/public_html\/daniel\/(.*)/;
    $_ = $1;
    print "<A HREF=\"http://tazendra.caltech.edu/~acedb/daniel/$_\">$_</A> $paper_type<BR>\n";
  } # foreach $_ (@allpdfs) 
  &displayAthena();
} # sub subdirDisplay

sub normalDisplay {
  print "Directory of Athena <A HREF=\"http://athena.caltech.edu/~daniel/tif_pdf/\">PDFs</A>. (Individually listed below)<BR><P><BR>\n";

  print "<P>Tazendra PDFs : <BR>\n";
  # my @allpdfs = </home3/allpdfs/*.pdf>;
  my @allpdfs = </home/acedb/public_html/daniel/*.pdf>;
  foreach $_ (@allpdfs) {
    chomp;
    $_ =~ m/\/home\/acedb\/public_html\/daniel\/(.*)/;
    $_ = $1;
    print "<A HREF=\"http://tazendra.caltech.edu/~acedb/daniel/$_\">$_</A><BR>\n";
  } # foreach $_ (@allpdfs) 
  &displayAthena();
} # sub normalDisplay

sub displayAthena {
  print "<P>Athena PDFs : <BR>\n";
  my @pdfathena;			# init list of athena pdfs
  &getAthenaPdfs();
  foreach my $pdfath (@pdfathena) {               # deal with athena pdfs
    $pdfath =~ m/(\d+).*/;
    print "<A HREF=\"http://athena.caltech.edu/~daniel/tif_pdf/$pdfath\">$pdfath</A><BR>\n"; # print the link
    print "<INPUT TYPE=\"HIDDEN\" NAME=\"pdf_name\" VALUE=\"$pdfath\">\n";
  } # foreach my $pdfath (@pdfathena)
} # sub displayAthena

# print "$footer";

sub getAthenaPdfs {                     # populate array of athena pdfs
    # use LWP::Simple to get the list of PDFs from Athena
  my $page = get "http://athena.caltech.edu/~daniel/tif_pdf/";
  @pdfathena = $page =~ m/href="(.*?tif\.pdf)"/g;       # get list of athena pdfs	# someone changed HREF to href 2004 01 14
#   @pdfathena = $page =~ m/HREF="(.*?tif\.pdf)"/g;       # get list of athena pdfs
} # sub getAthenaPdfs

