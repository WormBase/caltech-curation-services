#!/usr/bin/perl
use strict;
#use lib "/usr/local/lib/textpresso/celegans/";
#use TextpressoDisplayTasks;

# my $cgc_name_location_page = "http://www.cbs.umn.edu/cgc/lab-code";	# used to work before 2020 12 14
# my $cgc_name_location_page = "https://cbs.umn.edu/cgc/lab-code";	# redirects here on 2020 12 14, but getwebpage doesn't work on it
my $cgc_name_location_page = "http://tazendra.caltech.edu/~azurebrd/var/work/kimberly/20201214_cgc_textpresso/lab-code";	# 2020 12 14 got a temp copy in here
#my $cgc_strain_list_page   = "https://www.cbs.umn.edu/sites/default/files/public/downloads/celelist2.txt";
#my $cgc_strain_list_page   = "https://www.cbs.umn.edu/sites/default/files/public/downloads/elegans_list.txt";
my $cgc_strain_list_page   = "http://cbs.umn.edu/sites/cbs.umn.edu/files/public/downloads/elegans_list.txt";
my $outfile1 = "cgc_name_locations.txt";
my $outfile2 = "cgc_strains.txt";

my $cgc_name_locations_ref = get_cgc_name_locations($cgc_name_location_page);
my $cgc_strains_ref        = get_cgc_strains($cgc_strain_list_page);

my %cgc_name_locations = %{$cgc_name_locations_ref};
my %cgc_strains        = %{$cgc_strains_ref};

open (OUT, ">$outfile1") or die $!;
for my $strain (keys %cgc_name_locations) {
    print OUT "$strain\t$cgc_name_locations{$strain}\n";
}
close (OUT);

open (OUT, ">$outfile2") or die $!;
for my $strain (sort keys %cgc_strains) {
    print OUT "$strain\n";
}
close (OUT);

print "Outputs available in $outfile1 and $outfile2\n";


sub get_cgc_strains {
    my $url = shift;
    print "Getting CGC strains from $url ...\n";
    my $contents = getwebpage($url);
    my @lines = split(/\n/, $contents);
    my %hash;
    for my $line (@lines) {
        if ($line =~ /Strain\:\s*([A-Z]+\d+)/) {
            $hash{$1} = 1;
        }
    }
    print "Got " . scalar (keys %hash) . " strains from CGC.\n\n";
    return \%hash;
}

sub get_cgc_name_locations {
    my $url = shift;
    my $indicator1 = "&nbsp;&nbsp;&nbsp;&nbsp;";
    print "\nGetting CGC lab designations from $url ... \n";
    my $contents = getwebpage($url);
    $contents =~ s/<\/p>/<\/p>\n/g;
    my @lines = split(/\n/, $contents);
    my %hash;
    my $flag = 0;
    foreach my $line (@lines) {
	$line =~s/\<p\>//g;
	$line =~s/\<\/p\>//g;
	$line =~ s/(\&nbsp\;)+ ?/\t/g;
	next if ($line !~ /\t/);
	my @aux = split (/\t/, $line);
	my $designation   = $aux[0];
	my $name_location = $aux[scalar(@aux) - 1];
	$name_location=~s/\t//g;
	$designation  =~s/\t//g;
	if (($designation !~ /[a-z]/) && ($designation =~ /\w/)) {
	    $hash{$designation} = $name_location;
	}
    }   
    print "Got " . scalar (keys %hash) . " lab designations from CGC.\n\n";
    return \%hash;
}

sub getwebpage{
    my $u = shift;
    my $page = "";
    use LWP::UserAgent;
	
    my $ua = LWP::UserAgent->new(timeout => 60); # instantiates a new user agent
       $ua->agent('Mozilla/5.0');
    my $request = HTTP::Request->new(GET => $u); # grabs url
    my $response = $ua->request($request);       # checks url, dies if not valid.
    if ($response->is_success) {
        $page = $response->content;    #splits by line
    } else {
        warn $response->status_line,"\n";
        $page = $response->status_line;
    }

    return $page;
}
