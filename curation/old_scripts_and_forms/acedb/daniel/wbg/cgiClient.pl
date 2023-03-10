#!/usr/bin/perl -w
#
# Client for link web service - input file is a C.elegans text file
# Web service returns text with data objects linked to wormbase resource pages
#
# Arun Rangarajan, Caltech, 2009.
#
use SOAP::Lite;

if (@ARGV < 2) {
	die "Usage: $0 <input dir> <output dir>\n";
}
my $indir = $ARGV[0];
my $outdir = $ARGV[1];

my @files = <$indir/*>;

my $server_url = "http://dev.textpresso.org";

for my $fn (@files) {
	print "Linking $fn ...\n";
	my $txt = readFromFile($fn);
	$txt = doEntityReferencing($txt);

	my $client = SOAP::Lite->new();
	my $linked_txt = $client->service($server_url . '/wb/webservice/wsdl/link_cgi.wsdl')->LinkWebService($txt);
	$linked_txt = doEntityDereferencing($linked_txt);

	my $filename = $outdir . '/' . getFilename($fn);
	open (OUT, ">$filename") or die ("could not open $filename for writing\n");
	print OUT $linked_txt;
	close OUT;
	print "Linked file available at $filename.\n";
}
print "Results are stored in $outdir.\n";

sub getFilename {
	my $f = shift;
	my @e = split (/\//, $f);
	return (pop @e);
}

sub readFromFile {
	my $fn = shift;
	open (IN, "<$fn") or die ("died: cannot open $fn for reading");
	my $s = "";
	while (<IN>) {
		$s .= $_;
	}
	return $s;
}

sub doEntityDereferencing {
	my $s = shift;

	$s =~ s/\&amp\;/\&/g;
	$s =~ s/\&lt\;/\</g;
	$s =~ s/\&gt\;/\>/g;
	$s =~ s/\&quot\;/\"/g;
	$s =~ s/\&apos\;/\'/g;

	return $s;
}

sub doEntityReferencing {
	my $s = shift;

	$s =~ s/\&/\&amp\;/g;
	$s =~ s/\</\&lt\;/g;
	$s =~ s/\>/\&gt\;/g;
	$s =~ s/\"/\&quot\;/g;
	$s =~ s/\'/\&apos\;/g;

	return $s;
}
