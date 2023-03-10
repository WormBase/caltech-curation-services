#!/usr/bin/perl -w
use strict;
use LWP::UserAgent;

my $pubmed_dir = "/home/acedb/daniel/Reference/pubmed/pdf";
my $cgc_dir    = "/home/acedb/daniel/Reference/cgc/pdf";
my $wb_dir     = "/home/acedb/daniel/Reference/wb/pdf";

my $tmp_dir    = "/home/acedb/arun";

# Pubmed
my @pdf_files = <$pubmed_dir/*.pdf>;
open (OUT, ">$tmp_dir/pmid/pubmed.pmid") or die ("Could not open pubmed.pmid for writing.\n");
foreach my $pdf (@pdf_files)
{
	my @e = split /\//, $pdf;
	my $file = pop @e;
	$file =~ /(.*)\.pdf/;
	my $name = $1;
	$name =~ /(\d+)_(.*)/;
	(my $pmid, my $rest) = ($1, $2);
	print OUT "$pmid\n" if ($rest =~ /temp$/);
}
close (OUT);

# cgc
# First get mapping between wbid and pmid & cgc and wbid
my $url = "http\:\/\/tazendra\.caltech\.edu\/\~postgres\/cgi-bin\/wpa_xref_backwards\.cgi";
my $string = &getWebPage($url);
my @lines = split /\n/, $string;
my $x = @lines;
my %wb_pmid;
my %cgc_wb;
foreach my $l (@lines)
{
	$l =~ /pmid(\d+)\s+WBPaper(\d+)/;
	if ( defined($1) && defined($2) )
	{
		$wb_pmid{$2} = $1;
	}
	$l =~ /cgc(\d+)\s+WBPaper(\d+)/;
	if ( defined($1) && defined($2) )
	{
		$cgc_wb{$1} = $2;
	}
}

# Acquire PMIDs corresponding to CGCs
my @dirs_1 = <$cgc_dir/*>;
open (OUT, ">$tmp_dir/pmid/cgc.pmid") or die ("Could not open cgc.pmid for writing.\n");
foreach my $dir_1 (@dirs_1)
{
	my @dirs_2 = <$dir_1/*>;
	
	my $dir_test = 0;
	$dir_test = 1 if (-d $dirs_2[0]);

	if ($dir_test == 0)
	{
		foreach my $pdf (@dirs_2)
		{
			my @e = split /\//, $pdf;
			my $file = pop @e;
			$file =~ /(.*)\.pdf/;
			my $name = $1;
			$name =~ /(\d+)_(.*)/;
			(my $cgc, my $rest) = ($1, $2);
			if ($rest =~ /temp$/)
			{
				my $pmid = $wb_pmid{$cgc_wb{$cgc}};
				print OUT "$pmid\n";
			}
		}
	}
	else
	{
		foreach my $d (@dirs_2)
		{
			my @pdf_files = <$d/*.pdf>;
			foreach my $pdf (@pdf_files)
			{
				my @e = split /\//, $pdf;
				my $file = pop @e;
				$file =~ /(.*)\.pdf/;
				my $name = $1;
				$name =~ /(\d+)_(.*)/;
				(my $cgc, my $rest) = ($1, $2);
				if ($rest =~ /temp$/)
				{
					my $pmid = $wb_pmid{$cgc_wb{$cgc}};
					print OUT "$pmid\n";
				}
			}
		}
	}
}
close (OUT);

# WormBase papers
@pdf_files = <$wb_dir/*.pdf>;
open (OUT, ">$tmp_dir/pmid/wb.pmid") or die ("Could not open wb.pmid for writing.\n");
foreach my $pdf (@pdf_files)
{
	my @e = split /\//, $pdf;
	my $file = pop @e;
	$file =~ /(.*)\.pdf/;
	my $name = $1;
	$name =~ /(\d+)_(.*)/;
	(my $wbid, my $rest) = ($1, $2);
	if ($rest =~ /temp$/)
	{
		my $pmid = $wb_pmid{$wbid};
		print OUT "$pmid\n";
	}
}
close (OUT);

# get pubmed PDFs
print "______________\n";
print "fetch and fill\n";
my @args = ("./02FetchAndFill.pl", "$tmp_dir/pmid/pubmed.pmid", "$tmp_dir/elegans/", "author", "pubmed");
system (@args);

@args = ("./03prepPDFdownload.pl", "$tmp_dir/elegans/year/", "$tmp_dir/elegans/citation/", "$tmp_dir/elegans/journal/", 
			"$tmp_dir/dat/pubmed.dat");
system (@args);

print "______________\n";
print "Downloading PDF\n";
@args = ("./04downloadPDF.pl", "$tmp_dir/dat/pubmed.dat", "$tmp_dir/elegans/pdf/", "$tmp_dir/elegans/tmp", "$tmp_dir/elegans/");
system (@args);

print "______________\n";
print "Copying new PDFs\n";
@args = ("./05copyNewPdf.pl", "/home/acedb/daniel/Reference/pubmed/pdf/", "/home/acedb/arun/elegans/pdf", 
			"/home/acedb/daniel/Reference/pubmed/newpdf");
system(@args);



#Todo: Clean up all directories in tmp_dir

sub getWebPage{
    my $u = shift;
    my $page = "";
    
    my $ua = LWP::UserAgent->new(timeout => 30); #instantiates a new user agent
    my $request = HTTP::Request->new(GET => $u); #grabs url
    my $response = $ua->request($request);       #checks url, dies if not valid.
    die "Error while getting ", $response->request->uri," -- ", $response->status_line, "\nAborting" unless $response-> is_success;
    
    $page = $response->content;    #splits by line
    return $page;
}
