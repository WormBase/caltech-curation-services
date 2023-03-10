#!/usr/bin/perl -w
use strict;

if (@ARGV < 3) { die "

USAGE: $0 <old_pdf_dir> <newly_downloaded_pdf_dir> <update_dir>


SAMPLE INPUT:   $0 ~/daniel/Reference/pubmed/pdf ~/arun/elegans/pdf ~/daniel/Reference/pubmed/newpdf

\n";}

my $old_dir = $ARGV[0];
my $new_dir = $ARGV[1];
my $update_dir = $ARGV[2];

my @old_pdfs = <$old_dir/*.pdf>;
my $count = 0;
foreach my $oldpdf (@old_pdfs)
{
	my @e = split /\//, $oldpdf;
	my $filename = pop @e;
	$filename =~ /(.*)\.pdf/;
	my $name = $1;
	$name =~ /(\d+)_(.*)/;
	(my $pmid, my $rest) = ($1, $2);
	if ($rest =~ /temp$/)
	{
		my $newpdf = $new_dir . "/" . $pmid . ".pdf";
		if (-e $newpdf)
		{
			my @args = ("diff", $oldpdf, $newpdf);
			my $x = system (@args);
			if ($x != 0)
			{
				@args = ("cp", $newpdf, $update_dir);
				my $x1 = system (@args);
				if ($x1 != 0)
				{
					print "Copying $newpdf to $update_dir failed.\n";
				}
				$count++;
			}
			else
			{
				print "Same old PDF. No update required.\n";
			}
		}
		else
		{
			print "New PDF could not be downloaded by the current script.\n";
		}
	}
}
print "Number of new PDF files = $count.\n";
