#!/usr/bin/perl -w

# PDF Collector

# USAGE: ./pdf_collector.pl

use strict;
#use diagnostics;
use HTTP::Request;
use LWP::UserAgent;
use File::Copy;

my $outfile = "/home/acedb/eimear/PDF_sorter/eimear.txt";
my $outdir = "/home/acedb/eimear/PDF_sorter/Papers/";
my $cfolder = "/home2/wen/Reference/cgc/pdf";
my $pfolder = "/home2/wen/Reference/pubmed/pdf";
# url of list of cgc's mapped to pmid's
my $url_xref = "http://minerva.caltech.edu/~postgres/cgc_pmid_xref.txt";
my @file;
my %Xref;
my $page;
my $print;
my %CGC;
my %Ignore;


&readCurrentXREF($url_xref);

&recursiveFileSearch(my @directory = <$cfolder/*>);
my $i = 0;
my $j = 0;
my $k = 0;

foreach my $file (@file) {
    my $out = "";
    $i++;
    my @path = split /\//, $file;
    my $filename = pop(@path);
    my ($num) = $filename =~ /(\d+)_/g;
    my $f = "cgc".$num;
    $print .= "$f\n";
    $out = "$outdir/$f";
    print "moving $f ...";
    &copyFilestoDifferentDirectories($file, $out);
    print "done\n";
    $CGC{$f} = $f;
}

foreach (sort keys %Xref){
    if ($CGC{$_}){
	my $p = $Xref{$_};
	$Ignore{$p}++;     # list of pmid's to ignore coz already have cgc
    }
}

@file = ();

&recursiveFileSearch(@directory = <$pfolder/*>);

foreach my $file (@file) {
    my $out = "";
    $j++;
    my @path = split /\//, $file;
    my $filename = pop(@path);
    my ($num) = $filename =~ /(\d+)_/g;
    my $f = "pmid".$num;
    next if $Ignore{$f};
    $print .= "$f\n";
    $out = "$outdir/$f";
    print "moving $f ...";
    &copyFilestoDifferentDirectories($file, $out);
    print "done\n";
    $k++;
}

open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
print OUT "$print\n";
close (OUT) or die "Cannot close $outfile : $!";

print "\n\nThere are $i cgc pdf files and $k extra pmids out of $j total pmids\n\n"; 



sub recursiveFileSearch{
    my (@directory) = @_;

    foreach (@directory) {
	if ((-f $_) && ($_ =~ m/\.pdf$/)) { push @file, $_; }
	else {
	    my @array = <$_/*>;
	    for (@array){
		if (-d $_) { push @directory, $_;} 
		if ((-f $_) && ($_ =~ m/\.pdf$/)) { push @file, $_; }
	    }
	}
    }
    return @file;
}



sub readCurrentXREF{
    my $u = shift;
    print "Getting web page ...";
    &getWebPage($u);
    print "done.\n";
    my @tmp = split /\n/, $page;    #splits by line
    #pushes cgc and pmid values into a hash
    foreach (@tmp){my ($cgc, $pmid) = split /\t/, $_; $Xref{$cgc} = $pmid} 
    return %Xref;                                #returns hash
}

sub getWebPage{
    my $u = shift;
    $page = "";
    
    my $ua = LWP::UserAgent->new(timeout => 30); #instantiates a new user agent
    my $request = HTTP::Request->new(GET => $u); #grabs url
    my $response = $ua->request($request);       #checks url, dies if not valid.
    die "Error while getting ", $response->request->uri," -- ", $response->status_line, "\nAborting" unless $response-> is_success;
    
    $page = $response->content;    #splits by line
    return $page;
}


