#!/usr/bin/perl -w

# PDF Indexer
# AUTHOR: Eimear Kenny @ Wormbase 2004-07-01
# UPDATE: 2005-0207: updated directory paths for tazendra - eek
# UPDATE: 2005-0207: print stats to log.txt - eek
# USAGE: ./pdf2postgres.pl http://tazendra.caltech.edu/~acedb/paper2wbpaper.txt

use strict;
use diagnostics;
use HTTP::Request;
use LWP::UserAgent;
use File::Find;
use File::Basename;

my $log = "log.txt";
my $url_xref = $ARGV[0];
my @files;
my %Xref;
my %WBPaper;
my $serial = 0;
my $page;

my $i = 0;      # total number of pdf files
my $j = 0;      # total non text convertable files
my $k = 0;      # total text convertable files

my $dateShort = getDate();

# list of directory paths for all pdf files

### NB DO NOT CHANGE THE ORDER OF THESE DIRECTORIES!!!
my @directories = qw(
		     /home/acedb/daniel/Reference/cgc/libpdf
		     /home/acedb/daniel/Reference/cgc/tifpdf
		     /home/acedb/daniel/Reference/cgc/pdf
		     /home/acedb/daniel/Reference/printpdf		     
		     /home/acedb/daniel/Reference/pubmed/libpdf
		     /home/acedb/daniel/Reference/pubmed/tifpdf
		     /home/acedb/daniel/Reference/pubmed/pdf
		     );

#fetch all pdf files

for (@directories){find(\&allPDFs,  "$_")}

#sort into text convertable ($print_tc) and non-text convertible ($print_ntc)

my ($print_tc) = &sortPDFS(\@files);



# print wbp_paper

open (OUT, ">wbp_paper") or die "Cannot create wbp_paper : $!";
for my $family (sort {$a <=> $b} keys % WBPaper){
    print OUT "$family\t", join(", ", sort @{ $WBPaper{$family} }), "\t$dateShort\ttwo123\t\\N\t\\N\n";
}
close (OUT) or die "Cannot close wbp_paper : $!";

# print wbp_electronic_status_idx

open (OUT, ">wbp_electronic_status_idx") or die "Cannot create wbp_electronic_status_idx : $!";
print OUT "$print_tc\n";
close (OUT) or die "Cannot close wbp_electronic_status_idx : $!";


############# SUBROUTINES

sub allPDFs {
    return unless (-f && (/\.pdf$/));
    push @files, $File::Find::name;
}

sub sortPDFS{
    my $files = @_;

    my (%CGC, %PMID, %Ignore);
    
    my %Xref = &readCurrentXREF($url_xref);
    foreach my $file (@files) {
	$i++;
	my $filename = basename($file);
	my ($num) = $filename =~ /^(\d+)_/g;
	if ($num > 9999){
	    my $f = "pmid".$num;
	    $CGC{$file} = $f;
	}elsif ($num <= 9999){
	    my $f = "cgc".$num;
	    $CGC{$file} = $f;
	}
    }
    
    for (sort keys %CGC){&checkTextConvertable($_, $CGC{ $_ })}

    return ($print_tc);
}

sub checkTextConvertable{
    my ($file, $f) = @_;

    next unless $Xref{$f};
    $Xref{$f} =~ s/WBPaper0*//;  #strip WBPaper and padding 0
    $file =~ s/(\')/\\$1/;
    my $output = `md5sum $file`;    # get md5sum
    print "FILE:$file\n";
    my ($md5sum) = $output =~ /(\w+)/;
    print "MD5SUM:$md5sum\n";
    $print_tc .= "$serial\t$file\t$md5sum\t$dateShort\ttwo123\t\\N\t\\N\t";

    my $value = "";

    print "XREF: $Xref{$f} = $serial\n";
    push @{ $WBPaper{$Xref{$f}} }, "$serial";
    
    my $filename = basename($file);
    
    if ($filename =~ /_lib\.pdf/){
	$print_tc .= "2\t$dateShort\ttwo123\t\\N\t\\N\t";
    }elsif($filename =~ /_tiff?\.pdf/){
	$print_tc .= "3\t$dateShort\ttwo123\t\\N\t\\N\t";
    }elsif($filename =~ /_html?\.pdf/){
	$print_tc .= "4\t$dateShort\ttwo123\t\\N\t\\N\t";
    }elsif($filename =~ /_ocr\.pdf/){
	$print_tc .= "5\t$dateShort\ttwo123\t\\N\t\\N\t";
    }elsif($filename =~ /_aut\.pdf/){
	$print_tc .= "6\t$dateShort\ttwo123\t\\N\t\\N\t";
    }elsif($filename =~ /_temp\.pdf/){
	$print_tc .= "7\t$dateShort\ttwo123\t\\N\t\\N\t";
    }else{
	$print_tc .= "1\t$dateShort\ttwo123\t\\N\t\\N\t";
    }
    
    if (($file =~ /\/pdf\//) || ($file =~ /\/printpdf\//)){
	$print_tc .= "t\t$dateShort\ttwo123\t\\N\t\\N\n";
	$k++;
    }elsif (($file =~ /\/libpdf\// ) || ($file =~ /\/tifpdf\//)){
	$print_tc .= "f\t$dateShort\ttwo123\t\\N\t\\N\n";
 	$j++;
    }else {
	print "FILE: $f\t$file\n";
    }
    print "DATE: $dateShort\n";
    
    $serial++;
    
    return ($print_tc);
}

sub readCurrentXREF{
    my $u = shift;
    print "Getting web page ...";
    my $page = &getWebPage($u);
    print "done.\n";
    my @tmp = split /\n/, $page;    #splits by line
    #pushes cgc and pmid values into a hash
    foreach (@tmp){my ($old, $new) = split /\t/, $_; $Xref{$old} = $new} 
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
    $dateShort .= " ";
    $dateShort .= sprintf("%02d:%02d:%02d",$hour,$min,$sec);
    $dateShort .= "-04";
    return $dateShort;
}
