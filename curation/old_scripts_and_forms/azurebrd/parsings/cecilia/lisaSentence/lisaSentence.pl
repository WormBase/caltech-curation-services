#!/usr/bin/perl

# take in a .txt file and emphasize genes, single-lowercase-letter-and-4-digits,
# C. elegans, briggsae, etc.  Add stuff to top and bottom of file.  Put stuff at
# front and end of lines.  output to a file with .parsed at the end.  2005 05 06
#
# genes are only lower case.  2005 05 13
#
# added a few more words, took out briggsae since wrapping around C. briggsae,
# etc.  added extra newline after each line, change greek letters to hex with
# emphasis.  2005 05 18
#
# usage : ./lisaSentence.pl file.txt

my $infile = $ARGV[0];
my $outfile = $infile . '.xml';
if ($infile =~ m/^(.*)\.txt/) { $outfile = $1 . '.xml'; }

$/ = undef;
open (IN, "<$infile") or die "Cannot open $infile : $!";
my $file = <IN>;
close (IN) or die "Cannot close $infile : $!";

if ($file =~ m/Caenorhabidtis elegans/) { $file =~ s/Caenorhabidtis elegans/Caenorhabditis elegans/g; }
if ($file =~ m/Caenorhaditis elegans/) { $file =~ s/Caenorhaditis elegans/Caenorhabditis elegans/g; }


my (@genes) = $file =~ m/([a-z][a-z][a-z]\-\d+)/g;
my (@otherthing) = $file =~ m/([a-z]\d{4})/g;
if ($file =~ m/C\. elegans/) { push @genes, 'C. elegans'; }
if ($file =~ m/C elegans/) { push @genes, 'C. elegans'; }
if ($file =~ m/Caenorhabditis elegans/) { push @genes, 'Caenorhabditis elegans'; }
if ($file =~ m/Caenorhabditis briggsae/) { push @genes, 'Caenorhabditis briggsae'; }
if ($file =~ m/C\. briggsae/) { push @genes, 'C. briggsae'; }
if ($file =~ m/C briggsae/) { push @genes, 'C. briggsae'; }
if ($file =~ m/Pristionchus/) { push @genes, 'Pristionchus'; }
if ($file =~ m/suum/) { push @genes, 'suum'; }
# if ($file =~ m/briggsae/) { push @genes, 'briggsae'; }

my %genes;	# filter doubles
foreach my $other (@otherthing) { $genes{$other}++; }
foreach my $gene (@genes) { $genes{$gene}++; }
foreach my $gene (sort keys %genes) {
  print "$gene\n";
  $file =~ s/$gene/<emphasis>$gene<\/emphasis>/g;
} # foreach my $gene (@genes)

if ($file =~ m/\bAlpha\b/) { $file =~ s/\bAlpha\b/<emphasis>[x0391]<\/emphasis>/g; }
if ($file =~ m/\bBeta\b/) { $file =~ s/\bBeta\b/<emphasis>[x0392]<\/emphasis>/g; }
if ($file =~ m/\bGamma\b/) { $file =~ s/\bGamma\b/<emphasis>[x0393]<\/emphasis>/g; }
if ($file =~ m/\bDelta\b/) { $file =~ s/\bDelta\b/<emphasis>[x0394]<\/emphasis>/g; }
if ($file =~ m/\bEpsilon\b/) { $file =~ s/\bEpsilon\b/<emphasis>[x0395]<\/emphasis>/g; }
if ($file =~ m/\bZeta\b/) { $file =~ s/\bZeta\b/<emphasis>[x0396]<\/emphasis>/g; }
if ($file =~ m/\bEta\b/) { $file =~ s/\bEta\b/<emphasis>[x0397]<\/emphasis>/g; }
if ($file =~ m/\bTheta\b/) { $file =~ s/\bTheta\b/<emphasis>[x0398]<\/emphasis>/g; }
if ($file =~ m/\bIota\b/) { $file =~ s/\bIota\b/<emphasis>[x0399]<\/emphasis>/g; }
if ($file =~ m/\bKappa\b/) { $file =~ s/\bKappa\b/<emphasis>[x039A]<\/emphasis>/g; }
if ($file =~ m/\bLambda\b/) { $file =~ s/\bLambda\b/<emphasis>[x039B]<\/emphasis>/g; }
if ($file =~ m/\bMu\b/) { $file =~ s/\bMu\b/<emphasis>[x039C]<\/emphasis>/g; }
if ($file =~ m/\bNu\b/) { $file =~ s/\bNu\b/<emphasis>[x039D]<\/emphasis>/g; }
if ($file =~ m/\bXi\b/) { $file =~ s/\bXi\b/<emphasis>[x039E]<\/emphasis>/g; }
if ($file =~ m/\bOmicron\b/) { $file =~ s/\bOmicron\b/<emphasis>[x039F]<\/emphasis>/g; }
if ($file =~ m/\bPi\b/) { $file =~ s/\bPi\b/<emphasis>[x03A0]<\/emphasis>/g; }
if ($file =~ m/\bRho\b/) { $file =~ s/\bRho\b/<emphasis>[x03A1]<\/emphasis>/g; }
if ($file =~ m/\bSigma\b/) { $file =~ s/\bSigma\b/<emphasis>[x03A3]<\/emphasis>/g; }
if ($file =~ m/\bTau\b/) { $file =~ s/\bTau\b/<emphasis>[x03A4]<\/emphasis>/g; }
if ($file =~ m/\bUpsilon\b/) { $file =~ s/\bUpsilon\b/<emphasis>[x03A5]<\/emphasis>/g; }
if ($file =~ m/\bPhi\b/) { $file =~ s/\bPhi\b/<emphasis>[x03A6]<\/emphasis>/g; }
if ($file =~ m/\bChi\b/) { $file =~ s/\bChi\b/<emphasis>[x03A7]<\/emphasis>/g; }
if ($file =~ m/\bPsi\b/) { $file =~ s/\bPsi\b/<emphasis>[x03A8]<\/emphasis>/g; }
if ($file =~ m/\bOmega\b/) { $file =~ s/\bOmega\b/<emphasis>[x03A9]<\/emphasis>/g; }
if ($file =~ m/\balpha\b/) { $file =~ s/\balpha\b/<emphasis>[x03B1]<\/emphasis>/g; }
if ($file =~ m/\bbeta\b/) { $file =~ s/\bbeta\b/<emphasis>[x03B2]<\/emphasis>/g; }
if ($file =~ m/\bgamma\b/) { $file =~ s/\bgamma\b/<emphasis>[x03B3]<\/emphasis>/g; }
if ($file =~ m/\bdelta\b/) { $file =~ s/\bdelta\b/<emphasis>[x03B4]<\/emphasis>/g; }
if ($file =~ m/\bepsilon\b/) { $file =~ s/\bepsilon\b/<emphasis>[x03B5]<\/emphasis>/g; }
if ($file =~ m/\bzeta\b/) { $file =~ s/\bzeta\b/<emphasis>[x03B6]<\/emphasis>/g; }
if ($file =~ m/\beta\b/) { $file =~ s/\beta\b/<emphasis>[x03B7]<\/emphasis>/g; }
if ($file =~ m/\btheta\b/) { $file =~ s/\btheta\b/<emphasis>[x03B8]<\/emphasis>/g; }
if ($file =~ m/\biota\b/) { $file =~ s/\biota\b/<emphasis>[x03B9]<\/emphasis>/g; }
if ($file =~ m/\bkappa\b/) { $file =~ s/\bkappa\b/<emphasis>[x03BA]<\/emphasis>/g; }
if ($file =~ m/\blambda\b/) { $file =~ s/\blambda\b/<emphasis>[x03BB]<\/emphasis>/g; }
if ($file =~ m/\bmu\b/) { $file =~ s/\bmu\b/<emphasis>[x03BC]<\/emphasis>/g; }
if ($file =~ m/\bnu\b/) { $file =~ s/\bnu\b/<emphasis>[x03BD]<\/emphasis>/g; }
if ($file =~ m/\bxi\b/) { $file =~ s/\bxi\b/<emphasis>[x03BE]<\/emphasis>/g; }
if ($file =~ m/\bomicron\b/) { $file =~ s/\bomicron\b/<emphasis>[x03BF]<\/emphasis>/g; }
if ($file =~ m/\bpi\b/) { $file =~ s/\bpi\b/<emphasis>[x03C0]<\/emphasis>/g; }
if ($file =~ m/\brho\b/) { $file =~ s/\brho\b/<emphasis>[x03C1]<\/emphasis>/g; }
if ($file =~ m/\bsigma1\b/) { $file =~ s/\bsigma1\b/<emphasis>[x03C2]<\/emphasis>/g; }
if ($file =~ m/\bsigma\b/) { $file =~ s/\bsigma\b/<emphasis>[x03C3]<\/emphasis>/g; }
if ($file =~ m/\btau\b/) { $file =~ s/\btau\b/<emphasis>[x03C4]<\/emphasis>/g; }
if ($file =~ m/\bupsilon\b/) { $file =~ s/\bupsilon\b/<emphasis>[x03C5]<\/emphasis>/g; }
if ($file =~ m/\bphi\b/) { $file =~ s/\bphi\b/<emphasis>[x03C6]<\/emphasis>/g; }
if ($file =~ m/\bchi\b/) { $file =~ s/\bchi\b/<emphasis>[x03C7]<\/emphasis>/g; }
if ($file =~ m/\bpsi\b/) { $file =~ s/\bpsi\b/<emphasis>[x03C8]<\/emphasis>/g; }
if ($file =~ m/\bomega\b/) { $file =~ s/\bomega\b/<emphasis>[x03C9]<\/emphasis>/g; }
if ($file =~ m/\btheta1\b/) { $file =~ s/\btheta1\b/<emphasis>[x03D1]<\/emphasis>/g; }
if ($file =~ m/\bUpsilon1\b/) { $file =~ s/\bUpsilon1\b/<emphasis>[x03D2]<\/emphasis>/g; }
if ($file =~ m/\bphi1\b/) { $file =~ s/\bphi1\b/<emphasis>[x03D5]<\/emphasis>/g; }
if ($file =~ m/\bomega1\b/) { $file =~ s/\bomega1\b/<emphasis>[x03D6]<\/emphasis>/g; }


my @lines = split/\n/, $file;
$file = "<bibliography>\n\n    <title>References</title>\n\n";
foreach my $line (@lines) {
  if ($line =~ m/\w/) { $line = '<bibliomixed><bibliomisc>' . $line .  '</bibliomisc></bibliomixed>'; }
  $file .= $line . "\n\n"; 
}
$file .= "\n\n</bibliography>";

open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
print OUT $file;
close (OUT) or die "Cannot close $outfile : $!";
