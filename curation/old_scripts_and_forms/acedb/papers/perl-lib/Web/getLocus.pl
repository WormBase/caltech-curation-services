#!/usr/bin/perl -w

use strict;
use warnings;
use Carp;
use HTTP::Request;
use LWP::UserAgent;
use IO::Handle;
STDOUT->autoflush(1);


$|=1;  # forces output buffer to flush after every print statement!


## AUTHOR: Eimear Kenny @ Wormbase
## DATE:   07-08-2004


my $url_locus = $ARGV[0];

###MAIN####

print "Reading Locus names .....";
my %Locus = readCurrentLocus($url_locus);
print "done\n";

##print out
for my $cgc ( keys %Locus){
    print "$cgc : @{ $Locus{$cgc} }\n";
}

print "There are ". scalar (keys %Locus) . " cgc genes with synonyms\n";


###SUBROUTINES###

sub readCurrentLocus{

    my $u = shift;

    my @Locus=();
    my $page = getWebPage($u);
    my @lines = split /\n/, $page;
    my $first_line = shift @lines;   # 10-22-2004; gets rid of first line
    foreach (@lines){
        my @cols = split /,/, $_;
        my $cgcgenename = $cols[0];
        my $syn_list = $cols[-2];
	if ($syn_list ne ""){
	    my @syn = split / /, $syn_list;
	    $Locus{$cgcgenename} = [ @syn ];
	}
    }
    return %Locus;
}

sub getWebPage{
    my $u = shift;
    
    my $ua = LWP::UserAgent->new(timeout => 30); #instantiates a new user agent
    my $request = HTTP::Request->new(GET => $u); #grabs url
    my $response = $ua->request($request);       #checks url, dies if not valid.
    die "Error while getting ", $response->request->uri," -- ", $response->status_line, "\nAborting" unless $response-> is_success;
    my $page = $response->content;    #splits by line
    
    return $page;
}

exit(0);
