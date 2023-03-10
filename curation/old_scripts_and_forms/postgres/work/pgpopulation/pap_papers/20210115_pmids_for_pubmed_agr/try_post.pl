#!/usr/bin/perl

# https://www.ncbi.nlm.nih.gov/books/NBK25498/#chapter3.Application_4_Finding_unique_se
# https://www.ncbi.nlm.nih.gov/books/NBK25498/#chapter3.Application_3_Retrieving_large

use LWP::Simple;
use LWP::UserAgent;

# my $outfile = 'snp_table';
#
# $query = 'human[orgn]+AND+20[chr]+AND+alive[prop]';
# $db1 = 'gene';
# $db2 = 'snp';
# $linkname = 'gene_snp';
# 
# #assemble the esearch URL
# $base = 'https://eutils.ncbi.nlm.nih.gov/entrez/eutils/';
# $url = $base . "esearch.fcgi?db=$db1&term=$query&usehistory=y&retmax=5";
# 
# #post the esearch URL
# $output = get($url);
# 
# #parse IDs retrieved
# while ($output =~ /<Id>(\d+?)<\/Id>/sg) {
#    push(@ids, $1);
# }
# 
# #assemble  the elink URL as an HTTP POST call
# $url = $base . "elink.fcgi";

# $url_params = "dbfrom=$db1&db=$db2&linkname=$linkname";
# foreach $id (@ids) {      
#    $url_params .= "&id=$id";
# }


$base = 'https://eutils.ncbi.nlm.nih.gov/entrez/eutils/';
# $url = $base . "elink.fcgi";
$url = $base . "efetch.fcgi";

# my @ids = qw( 33397278 33398823 33403278 33444416 33444761 33408224 33410237 33438773 33440146 );

my @ids;
my $infile = 'pmids_short';
# my $infile = 'pmids_3';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) {
  chomp $line;
  push @ids, $line;
} # while (my $line = <IN>)
close (IN) or die "Cannot close $infile : $!";


# $url_params = "dbfrom=pubmed&retmode=xml";
# foreach $id (@ids) {      
#    $url_params .= "&id=$id";
# }

my $ids = join",", @ids;
$url_params = "db=pubmed&retmode=xml&id=$ids";

my $outfile = 'xmlpmids';
# my $outfile = 'xmlpmids_all';
# my $outfile = 'xmlpmids_3';

#create HTTP user agent
$ua = new LWP::UserAgent;
$ua->agent("elink/1.0 " . $ua->agent);

#create HTTP request object
$req = new HTTP::Request POST => "$url";
$req->content_type('application/x-www-form-urlencoded');
$req->content("$url_params");

#post the HTTP request
$response = $ua->request($req); 
$output = $response->content;

open (OUT, ">$outfile") || die "Can't open file!\n";

print OUT "$output";
# while ($output =~ /<LinkSet>(.*?)<\/LinkSet>/sg) {
# 
#    $linkset = $1;
#    if ($linkset =~ /<IdList>(.*?)<\/IdList>/sg) {
#       $input = $1;
#       $input_id = $1 if ($input =~ /<Id>(\d+)<\/Id>/sg); 
#    }
# 
#    while ($linkset =~ /<Link>(.*?)<\/Link>/sg) {
#       $link = $1;
#       push (@output, $1) if ($link =~ /<Id>(\d+)<\/Id>/);
#    }
#       
#    print OUT "$input_id:" . join(',', @output) . "\n";
#   
# }

close OUT;
