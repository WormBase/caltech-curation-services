#!/usr/bin/perl -w

# PDF Indexer
# AUTHOR: Eimear Kenny @ Wormbase 2004-07-01
# UPDATE: 2005-0207: updated directory paths for tazendra - eek
# UPDATE: 2005-0207: print stats to log.txt - eek
# UPDATE: 2008-06-10: Revamped major part of script to include supplementals,
# UPDATE: 2008-06-10: got rid of unstable programming - hmm
# USAGE: ./pdf_indexer.pl http://tazendra.caltech.edu/~postgres/cgc_pmid_xref.txt

use strict;
use diagnostics;
use HTTP::Request;
use LWP::UserAgent;
use File::Find;
use File::Basename;


my $txtconvtbl = "/home/acedb/eimear/Textpresso/TextConvertible.list";
my $log = "/home/acedb/eimear/Textpresso/log.txt";
# url of list of cgc's mapped to pmid's
my $url_xref = $ARGV[0];
my @files;
my %Xref;
my $page;

my $print_tc = "";

# list of directory paths for all pdf files

### NB DO NOT CHANGE THE ORDER OF THESE DIRECTORIES!!!
my @directories = qw(
		     /home/acedb/daniel/Reference/cgc/supplemental/
		     /home/acedb/daniel/Reference/cgc/pdf/
		     /home/acedb/daniel/Reference/pubmed/supplemental/
		     /home/acedb/daniel/Reference/pubmed/pdf/
		     /home/acedb/daniel/Reference/wb/supplemental/
		     /home/acedb/daniel/Reference/wb/pdf/
		     );

#fetch all pdf files

for (@directories){find(\&allPDFs,  "$_")}

#sort into text convertable ($print_tc) and non-text convertible ($print_ntc)

&sortPDFS(\@files);

# print text convertable to TextConvertible.list

open (OUT, ">$txtconvtbl") or die "Cannot create $txtconvtbl : $!";
print OUT "$print_tc\n";
close (OUT) or die "Cannot close $txtconvtbl : $!";

############# SUBROUTINES

sub allPDFs {
    return unless (-f && (/\.pdf$/));
    push @files, $File::Find::name;
}

sub sortPDFS{
    my $files = @_;

    my (%CGC, %PMID, %WBPaper, %Supplemental, %Ignore);
    

    # build the 'ignore' hash first
    foreach my $file (@files) {
	my $filename = basename($file);
	my ($num) = $filename =~ /^(\d+)_/g;
	if (defined($num)) {
	    if (($num <= 9999) && (substr($num, 0, 1) ne '0')) {
		my $f = "cgc" . $num;
		my $p = $Xref{$f};
		$Ignore{$p}++ if defined $p;     
	    }
	}
    }
    my %Xref = &readCurrentXREF($url_xref);
    foreach my $file (@files) {
	my $filename = basename($file);
	my ($num) = $filename =~ /^(\d+)_/g;
	if ($file =~ /\/wb\/supplemental\/(\d+)\/(.+)\.pdf/) {
 	    my $f = "WBPaper" . $1 . ".sup";
	    push @{$Supplemental{$f}}, $file;
	} elsif ($file =~ /\/cgc\/supplemental\/(\d+)_(.+)\.pdf/) {
	    my $f = "cgc" . $1 . ".sup";
	    push @{$Supplemental{$f}}, $file;
 	} elsif ($file =~ /\/pubmed\/supplemental\/(\d+)_(.+)\.pdf/) {
	    my $f = "pmid" . $1 . ".sup";
	    push @{$Supplemental{$f}}, $file;
	} elsif (($num > 9999) && (substr($num, 0, 1) ne '0')) {
	    my $f = "pmid".$num;
	    push @{$PMID{$f}}, $file unless $Ignore{$f};
	} elsif (($num > 0) && ($num <= 9999) && (substr($num, 0, 1) ne '0')) {
	    my $f = "cgc".$num;
	    push @{$CGC{$f}}, $file;
	} elsif (substr($num, 0, 1) eq '0') {
	    my $f = "WBPaper".$num;
	    push @{$WBPaper{$f}}, $file;
	}
    }

    # deal with multiple versions of papers and supplementals, but for each directory separately.
    # give priority to _txp files.
    for my $k (keys %CGC) {
	if (scalar (@{$CGC{$k}}) > 1) {
	    my $aux = "";
            my $txp = 0;
	    for (my $i = 0; $i < @{$CGC{$k}}; $i++) {
		my $file = $CGC{$k}[$i];
	        if ($file =~ /\_txp\.pdf/) {
	            $aux = $CGC{$k}[$i];
	            $txp = 1;
                }
		if ((!$txp) && ($file !~ /\_[a-z]+\.pdf/)) {
		    $aux = $CGC{$k}[$i];
		}
	    }
	    @{$CGC{$k}} = ($aux);
	}
    }
    for my $k (keys %PMID) {
	if (scalar (@{$PMID{$k}}) > 1) {
	   my $aux = "";
           my $txp = 0;
	   for (my $i = 0; $i < @{$PMID{$k}}; $i++) {
		my $file = $PMID{$k}[$i];
                if ($file =~ /\_txp\.pdf/) {
                    $aux = $PMID{$k}[$i];
                    $txp = 1;
                }
                if ((!$txp) && ($file !~ /\_[a-z]+\.pdf/)) {
		    $aux = $PMID{$k}[$i];
		}
	    }
	    @{$PMID{$k}} = ($aux);
	}
    }

    for my $k (keys %WBPaper) {
	if (scalar (@{$WBPaper{$k}}) > 1) {
	    my $aux = "";
            my $txp = 0;
	    for (my $i = 0; $i < @{$WBPaper{$k}}; $i++) {
		my $file = $WBPaper{$k}[$i];
	        if ($file =~ /\_txp\.pdf/) {
                    $aux = $WBPaper{$k}[$i];
                    $txp = 1;
                }
                if ((!$txp) && ($file !~ /\_[a-z]+\.pdf/)) {
		    $aux = $WBPaper{$k}[$i];
		}
	    }
	    @{$WBPaper{$k}} = ($aux);
	}
    }
    
    my %supaux = ();
    foreach my $k (keys %Supplemental) {
	for (my $i = 0; $i < @{$Supplemental{$k}}; $i++) {
	    my $file = $Supplemental{$k}[$i];
	    my $n = $i + 1;
	    $supaux{"$k.$n"} = $file;
	}
    }

    for (sort keys %CGC){
	my $f = "@{$CGC{$_}}";
	$f =~ s/\s//g;
	$print_tc .= "$_\t$f\n";
    }
    for (sort keys %PMID){
	my $f = "@{$PMID{$_}}";
	$f =~ s/\s//g;
	$print_tc .= "$_\t$f\n";
    }
    for (sort keys %WBPaper) {
	my $f = "@{$WBPaper{$_}}";
	$f =~ s/\s//g;
	$print_tc .= "$_\t$f\n";
    }
    for (sort keys %supaux) {
	my $f = $supaux{$_};
	$print_tc .= "$_\t$f\n";
    }
}

sub readCurrentXREF{
    my $u = shift;
    print "Getting web page ...";
    my $page = &getWebPage($u);
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

sub getDate{
    my $time_zone = 0;
    my $time = time() + ($time_zone * 3600);
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time);
    $year += ($year < 90) ? 2000 : 1900;
    my $dateShort = sprintf("%04d-%02d-%02d",$year,$mon+1,$mday);
    return $dateShort;
}
