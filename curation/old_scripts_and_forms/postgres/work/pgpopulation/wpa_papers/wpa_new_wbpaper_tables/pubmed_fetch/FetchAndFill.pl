#!/usr/bin/perl -w
#
# Purpose: Read in PubMed identifiers. Generate url link to XML 
#          abstract page on PubMed website, download page and extract the PubMed 
#          citation info for each paper. Split citation info by type and output 
#          to corresponding directory. Download online text if available.
# Author:  Eimear Kenny and Hans-Michael Muller
# Date:    April 2005 / June 2005

if (@ARGV < 4) { die "

USAGE: $0 <file with current pmids> <output directory> <reference subdirectory> (pubmed | online | all)



SAMPLE INPUT:  $0 elegans.pmid elegans/ author/ pubmed
\n
";}
##############################################################################
use strict;
use File::Basename;
#use File::Find;
use HTTP::Request;
use LWP::UserAgent;
#my $agent = new LWP::UserAgent;
#$agent->timeout(20);

# globals
my $pmidlist = $ARGV[0]; # Pubmed identifiers
my $outdir = $ARGV[1];   # outpath
my $refdir = $ARGV[2];   # reference dir
my $cmd = $ARGV[3];      # what to download
my %directories = ("abs" => "abstract/", "aut" => "author/", "bod" => "body/", "cit" => "citation/",
		   "jou" => "journal/",  "tit" => "title/",  "typ" => "type/", "yea" => "year/");

##MAIN

my @aux = getpmidlist($pmidlist);
my %ai = alreadyin("$outdir/$refdir/");
my @pmids = ();
foreach my $id (@aux) {
    push @pmids, $id unless ($ai{$id});
}

foreach my $id (@pmids) {
    # comply with NCBI's requirement of doing it at night
    my @lc = localtime;
    while ($lc[2] < 18) {
	sleep 600;
	@lc = localtime;
	
    }
    if (($cmd eq 'pubmed') || ($cmd || 'all')) {
	my $url = "http\:\/\/eutils\.ncbi\.nlm\.nih\.gov\/entrez\/eutils\/efetch\.fcgi\?db\=pubmed\&id\=$id\&retmode\=xml";
	my $page = getwebpage($url);
	dumppubmedinfo($outdir, \%directories, $page, $id);
    }
    if (($cmd eq 'online') || ($cmd || 'all')) {
	my $url = "http\:\/\/eutils\.ncbi\.nlm\.nih\.gov\/entrez\/eutils\/elink\.fcgi\?dbfrom\=pubmed\&id\=$id\&retmode\=ref\&cmd\=prlinks";
	my $page = getwebpage($url);
	dumponlinetext($outdir, \%directories, $page, $id);
    }
}


exit(0);

###SUBROUTINES

sub getpmidlist {
    
    my $fn = shift;
    my @ret = ();

    open (IN, "<$fn");
    while (my $line = <IN>) {
	chomp($line);
	push @ret, $line;
    }
    close (IN);
    return @ret;

}

sub alreadyin {

    my $fd = shift;
    my %ret = ();
    my @aux = glob("$fd/*");
    for (@aux) {
	my $f = basename($_, ''); 
	$ret{$f} = 1;
    }
    return %ret;

}

sub dumponlinetext {
    my $outdir = shift;
    my $pDir = shift; 
    my $page = shift;
    my $pmid = shift;

    $page =~ s/\<script.*?\>.+\<\/script\>//sgi;
    $page =~ s/\<style.*?\>.+\<\/style\>//sgi;
    $page =~ s/\<\!\-\- .*? \-\-\>//sgi;
    $page =~ s/\<.*?\>//sgi;
    $page =~ s/\<\/.*?\>//sgi;
    $page =~ s/\&.+?\;//sgi;
    $page =~ s/\n\n+/\n/gi;
    $page =~ s/\t\t+/\t/gi;

#    print "BODY:\n $page\n";
    open (BOD, ">$outdir/$$pDir{bod}/$pmid");
    print BOD $page;
    close (BOD);

}

sub dumppubmedinfo {

    my $outdir = shift;
    my $pDir = shift; 
    my $page = shift;
    my $pmid = shift;

    $page =~ s/\n//g;
    return if $page =~ /\<Error\>.+?\<\/Error\>/i;
    
#    print "PMID:\n $pmid\n";

    ### Get year
    my ($PubDate) = $page =~ /\<PubDate\>(.+?)\<\/PubDate\>/i;
    my ($pubyear) = $PubDate =~ /\<Year\>(.+?)\<\/Year\>/i;
#    print "YEAR:\n $pubyear\n";
    open (PUB, ">$outdir/$$pDir{yea}/$pmid");
    print PUB "$pubyear\n";
    close (PUB);

    ## Get title
    my ($title) = $page =~ /\<ArticleTitle\>(.+?)\<\/ArticleTitle\>/i;   
#    print "TITLE:\t$title\n";
    open (TITLE, ">$outdir/$$pDir{tit}/$pmid");
    print TITLE "$title\n";
    close (TITLE);
    
    ## Get volume
    my ($volume) = $page =~ /\<Volume\>(.+?)\<\/Volume\>/i;   
#    print "VOLUME:\t$volume\n";
    
    ## Get page info
    my ($pagenum) = $page =~ /\<MedlinePgn\>(.+?)\<\/MedlinePgn\>/i;   
#    print "PAGE:\t$pagenum\n";
    
    open (CIT, ">$outdir/$$pDir{cit}/$pmid");
    print CIT "V: $volume\nP: $pagenum\n";
    close (CIT);
    
    ## Get Abstract 
    my ($abstract) = $page =~ /\<AbstractText\>(.+?)\<\/AbstractText\>/i;
#    print "ABSTRACT:\n$abstract\n";
    
    open (ABS, ">$outdir/$$pDir{abs}/$pmid");
    print ABS "$abstract";
    close (ABS);
	
    ## Get Authors
    my @authors = $page =~ /\<Author.*?\>(.+?)\<\/Author\>/ig;
	
    my $authors = "";
    foreach (@authors){
	my ($lastname, $initials) = $_ =~ /\<LastName\>(.+?)\<\/LastName\>.+\<Initials\>(.+?)\<\/Initials\>/i;
	$authors .= $lastname . " " . $initials . "\n";
    }
      
#    print "AUTHORS:\n$authors\n";
    
    open (AUT, ">$outdir/$$pDir{aut}/$pmid");
    print AUT "$authors";
    close (AUT);
        
    ## Get pub type
    my ($type) = $page =~ /\<PublicationType\>(.+?)\<\/PublicationType\>/i;
#    print "PUB TYPE:\t$type\n";

    open (TYP, ">$outdir/$$pDir{typ}/$pmid");
    print TYP "$type";
    close (TYP);

    ## Get Journal
    my ($journal) = $page =~ /<MedlineTA>(.+?)\<\/MedlineTA\>/i;
#    print "JOURNAL:\t$journal\n";
    
    open (JOU, ">$outdir/$$pDir{jou}/$pmid");
    print JOU "$journal";
    close (JOU);
    
#    print "\n";
    
}


sub getwebpage{

    my $u = shift;
    my $page = "";
    
    my $ua = LWP::UserAgent->new(timeout => 30); # instantiates a new user agent
    my $request = HTTP::Request->new(GET => $u); # grabs url
    my $response = $ua->request($request);       # checks url, dies if not valid.
#    die "Error while getting ", $response->request->uri," -- ", $response->status_line, "\nAborting" unless $response-> is_success;
    
    $page = $response->content;    #splits by line
    slp();
    return $page;
}

sub slp {
    
    my $rand = int(rand 15) + 5;
    print "Sleeping for $rand seconds...";
    sleep $rand;
    print "done.\n";

}

