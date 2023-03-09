#!/usr/bin/perl 
# This file gets the Predicted_gene list from stein.cshl.org and creates an
# index for another file to incorporate into a search.  
# This version grabs the Predicted_gene matched and stores into $1

use lib '../blib/lib','../blib/arch';
use Ace;

use constant HOST => $ENV{ACEDB_HOST} || 'stein.cshl.org';
use constant PORT => $ENV{ACEDB_PORT} || 200005;

$|=1;

$outfile = "/home/azurebrd/work/rnaifields/insertme2";

print "Opening the database....";
my $db = Ace->connect(-host=>HOST,-port=>PORT) || die "Connection failure:
",Ace->error;
print "done.\n";

my @sequence = $db->list('Predicted_gene','*');


foreach $_ (@sequence) {
  $b = $_;
  if ($b =~ m/\bA[CH]\d+/) {
    push @AC, $b;
  } elsif ($b =~ m/\bB0\d+/) {
    push @B0, $b;
  } elsif ($b =~ m/\bC0\d+/) {
    push @C0, $b;
  } elsif ($b =~ m/\bC1\d+/) {
    push @C1, $b;
  } elsif ($b =~ m/\bC2\d+/) {
    push @C2, $b;
  } elsif ($b =~ m/\bC3\d+/) {
    push @C3, $b;
  } elsif ($b =~ m/\bC4\d+/) {
    push @C4, $b;
  } elsif ($b =~ m/\bC5\d+/) {
    push @C5, $b;
  } elsif ($b =~ m/\bD[12]\d+/) {
    push @D1, $b;
  } elsif ($b =~ m/\bE0\d+/) {
    push @E0, $b;
  } elsif ($b =~ m/\bF0\d+/) {
    push @F0, $b;
  } elsif ($b =~ m/\bF1\d+/) {
    push @F1, $b;
  } elsif ($b =~ m/\bF2\d+/) {
    push @F2, $b;
  } elsif ($b =~ m/\bF3\d+/) {
    push @F3, $b;
  } elsif ($b =~ m/\bF4\d+/) {
    push @F4, $b;
  } elsif ($b =~ m/\bF5\d+/) {
    push @F5, $b;
  } elsif ($b =~ m/\bH0\d+/) {
    push @H0, $b;
  } elsif ($b =~ m/\bH1\d+/) {
    push @H1, $b;
  } elsif ($b =~ m/\bH2\d+/) {
    push @H2, $b;
  } elsif ($b =~ m/\bH[34]\d+/) {
    push @H3, $b;
  } elsif ($b =~ m/\bK0\d+/) {
    push @K0, $b;
  } elsif ($b =~ m/\bK1\d+/) {
    push @K1, $b;
  } elsif ($b =~ m/\bM\d{2,}/) {
    push @Md, $b;
  } elsif ($b =~ m/\bR0\d+/) {
    push @R0, $b;
  } elsif ($b =~ m/\bR1\d+/) {
    push @R1, $b;
  } elsif ($b =~ m/\bT0\d+/) {
    push @T0, $b;
  } elsif ($b =~ m/\bT1\d+/) {
    push @T1, $b;
  } elsif ($b =~ m/\bT2\d+/) {
    push @T2, $b;
  } elsif ($b =~ m/\bV[A-Z]/) {
    push @VA, $b;
  } elsif ($b =~ m/\bW[01]\d[A-Z]/) {
    push @W0, $b;
  } elsif ($b =~ m/\bY1\d+/) {
    push @Y1, $b;
  } elsif ($b =~ m/\bY2\d+/) {
    push @Y2, $b;
  } elsif ($b =~ m/\bY3\d+/) {
    push @Y3, $b;
  } elsif ($b =~ m/\bY4\d+/) {
    push @Y4, $b;
  } elsif ($b =~ m/\bY5\d+/) {
    push @Y5, $b;
  } elsif ($b =~ m/\bY6\d+/) {
    push @Y6, $b;
  } elsif ($b =~ m/\bY7\d+/) {
    push @Y7, $b;
  } elsif ($b =~ m/\bY[89]\d+/) {
    push @Y8, $b;
  } elsif ($b =~ m/\bZC\d+/) {
    push @ZC, $b;
  } elsif ($b =~ m/\bZK\d+/) {
    push @ZK, $b;
  } else {
    push @remainder, $b;
  }
} # foreach $_ (@sequence) 

open (OUT, ">>$outfile") or die "Cannot open $outfile : $!";


$AC = join ("\\b|\\b", @AC);
print OUT  "\t if (\$whatever =~ m/\\bA[CH]\\d+/) { \n";
print OUT  "\t\t if (\$whatever =~ m/(\\b$AC\\b)/) { &compute(); } \n \t } \n";

$B0 = join ("\\b|\\b", @B0);
print OUT  "\t elsif (\$whatever =~ m/\\bB0\\d+/) { \n";
print OUT  "\t\t if (\$whatever =~ m/(\\b$B0\\b)/) { &compute(); } \n \t } \n";

$C0 = join ("\\b|\\b", @C0);
print OUT  "\t elsif (\$whatever =~ m/\\bC0\\d+/) { \n";
print OUT  "\t\t if (\$whatever =~ m/(\\b$C0\\b)/) { &compute(); } \n \t } \n";

$C1 = join ("\\b|\\b", @C1);
print OUT  "\t elsif (\$whatever =~ m/\\bC1\\d+/) { \n";
print OUT  "\t\t if (\$whatever =~ m/(\\b$C1\\b)/) { &compute(); } \n \t } \n";

$C2 = join ("\\b|\\b", @C2);
print OUT  "\t elsif (\$whatever =~ m/\\bC2\\d+/) { \n";
print OUT  "\t\t if (\$whatever =~ m/(\\b$C2\\b)/) { &compute(); } \n \t } \n";

$C3 = join ("\\b|\\b", @C3);
print OUT  "\t elsif (\$whatever =~ m/\\bC3\\d+/) { \n";
print OUT  "\t\t if (\$whatever =~ m/(\\b$C3\\b)/) { &compute(); } \n \t } \n";

$C4 = join ("\\b|\\b", @C4);
print OUT  "\t elsif (\$whatever =~ m/\\bC4\\d+/) { \n";
print OUT  "\t\t if (\$whatever =~ m/(\\b$C4\\b)/) { &compute(); } \n \t } \n";

$C5 = join ("\\b|\\b", @C5);
print OUT  "\t elsif (\$whatever =~ m/\\bC5\\d+/) { \n";
print OUT  "\t\t if (\$whatever =~ m/(\\b$C5\\b)/) { &compute(); } \n \t } \n";

$D1 = join ("\\b|\\b", @D1);
print OUT  "\t elsif (\$whatever =~ m/\\bD[12]\\d+/) { \n";
print OUT  "\t\t if (\$whatever =~ m/(\\b$D1\\b)/) { &compute(); } \n \t } \n";

$E0 = join ("\\b|\\b", @E0);
print OUT  "\t elsif (\$whatever =~ m/\\bE0\\d+/) { \n";
print OUT  "\t\t if (\$whatever =~ m/(\\b$E0\\b)/) { &compute(); } \n \t } \n";

$F0 = join ("\\b|\\b", @F0);
print OUT  "\t elsif (\$whatever =~ m/\\bF0\\d+/) { \n";
print OUT  "\t\t if (\$whatever =~ m/(\\b$F0\\b)/) { &compute(); } \n \t } \n";

$F1 = join ("\\b|\\b", @F1);
print OUT  "\t elsif (\$whatever =~ m/\\bF1\\d+/) { \n";
print OUT  "\t\t if (\$whatever =~ m/(\\b$F1\\b)/) { &compute(); } \n \t } \n";

$F2 = join ("\\b|\\b", @F2);
print OUT  "\t elsif (\$whatever =~ m/\\bF2\\d+/) { \n";
print OUT  "\t\t if (\$whatever =~ m/(\\b$F2\\b)/) { &compute(); } \n \t } \n";

$F3 = join ("\\b|\\b", @F3);
print OUT  "\t elsif (\$whatever =~ m/\\bF3\\d+/) { \n";
print OUT  "\t\t if (\$whatever =~ m/(\\b$F3\\b)/) { &compute(); } \n \t } \n";

$F4 = join ("\\b|\\b", @F4);
print OUT  "\t elsif (\$whatever =~ m/\\bF4\\d+/) { \n";
print OUT  "\t\t if (\$whatever =~ m/(\\b$F4\\b)/) { &compute(); } \n \t } \n";

$F5 = join ("\\b|\\b", @F5);
print OUT  "\t elsif (\$whatever =~ m/\\bF5\\d+/) { \n";
print OUT  "\t\t if (\$whatever =~ m/(\\b$F5\\b)/) { &compute(); } \n \t } \n";

$H0 = join ("\\b|\\b", @H0);
print OUT  "\t elsif (\$whatever =~ m/\\bH0\\d+/) { \n";
print OUT  "\t\t if (\$whatever =~ m/(\\b$H0\\b)/) { &compute(); } \n \t } \n";

$H1 = join ("\\b|\\b", @H1);
print OUT  "\t elsif (\$whatever =~ m/\\bH1\\d+/) { \n";
print OUT  "\t\t if (\$whatever =~ m/(\\b$H1\\b)/) { &compute(); } \n \t } \n";

$H2 = join ("\\b|\\b", @H2);
print OUT  "\t elsif (\$whatever =~ m/\\bH2\\d+/) { \n";
print OUT  "\t\t if (\$whatever =~ m/(\\b$H2\\b)/) { &compute(); } \n \t } \n";

$H3 = join ("\\b|\\b", @H3);
print OUT  "\t elsif (\$whatever =~ m/\\bH[34]\\d+/) { \n";
print OUT  "\t\t if (\$whatever =~ m/(\\b$H3\\b)/) { &compute(); } \n \t } \n";

$K0 = join ("\\b|\\b", @K0);
print OUT  "\t elsif (\$whatever =~ m/\\bK0\\d+/) { \n";
print OUT  "\t\t if (\$whatever =~ m/(\\b$K0\\b)/) { &compute(); } \n \t } \n";

$K1 = join ("\\b|\\b", @K1);
print OUT  "\t elsif (\$whatever =~ m/\\bK1\\d+/) { \n";
print OUT  "\t\t if (\$whatever =~ m/(\\b$K1\\b)/) { &compute(); } \n \t } \n";

$Md = join ("\\b|\\b", @Md);
print OUT  "\t elsif (\$whatever =~ m/\\bM\\d{2,}/) { \n";
print OUT  "\t\t if (\$whatever =~ m/(\\b$Md\\b)/) { &compute(); } \n \t } \n";

$R0 = join ("\\b|\\b", @R0);
print OUT  "\t elsif (\$whatever =~ m/\\bR0\\d+/) { \n";
print OUT  "\t\t if (\$whatever =~ m/(\\b$R0\\b)/) { &compute(); } \n \t } \n";

$R1 = join ("\\b|\\b", @R1);
print OUT  "\t elsif (\$whatever =~ m/\\bR1\\d+/) { \n";
print OUT  "\t\t if (\$whatever =~ m/(\\b$R1\\b)/) { &compute(); } \n \t } \n";

$T0 = join ("\\b|\\b", @T0);
print OUT  "\t elsif (\$whatever =~ m/\\bT0\\d+/) { \n";
print OUT  "\t\t if (\$whatever =~ m/(\\b$T0\\b)/) { &compute(); } \n \t } \n";

$T1 = join ("\\b|\\b", @T1);
print OUT  "\t elsif (\$whatever =~ m/\\bT1\\d+/) { \n";
print OUT  "\t\t if (\$whatever =~ m/(\\b$T1\\b)/) { &compute(); } \n \t } \n";

$T2 = join ("\\b|\\b", @T2);
print OUT  "\t elsif (\$whatever =~ m/\\bT2\\d+/) { \n";
print OUT  "\t\t if (\$whatever =~ m/(\\b$T2\\b)/) { &compute(); } \n \t } \n";

$VA = join ("\\b|\\b", @VA);
print OUT  "\t elsif (\$whatever =~ m/\\bV[A-Z]/) { \n";
print OUT  "\t\t if (\$whatever =~ m/(\\b$VA\\b)/) { &compute(); } \n \t } \n";

$W0 = join ("\\b|\\b", @W0);
print OUT  "\t elsif (\$whatever =~ m/\\bW[01]\\d[A-Z]/) { \n";
print OUT  "\t\t if (\$whatever =~ m/(\\b$W0\\b)/) { &compute(); } \n \t } \n";

$Y1 = join ("\\b|\\b", @Y1);
print OUT  "\t elsif (\$whatever =~ m/\\bY1\\d+/) { \n";
print OUT  "\t\t if (\$whatever =~ m/(\\b$Y1\\b)/) { &compute(); } \n \t } \n";

$Y2 = join ("\\b|\\b", @Y2);
print OUT  "\t elsif (\$whatever =~ m/\\bY2\\d+/) { \n";
print OUT  "\t\t if (\$whatever =~ m/(\\b$Y2\\b)/) { &compute(); } \n \t } \n";

$Y3 = join ("\\b|\\b", @Y3);
print OUT  "\t elsif (\$whatever =~ m/\\bY3\\d+/) { \n";
print OUT  "\t\t if (\$whatever =~ m/(\\b$Y3\\b)/) { &compute(); } \n \t } \n";

$Y4 = join ("\\b|\\b", @Y4);
print OUT  "\t elsif (\$whatever =~ m/\\bY4\\d+/) { \n";
print OUT  "\t\t if (\$whatever =~ m/(\\b$Y4\\b)/) { &compute(); } \n \t } \n";

$Y5 = join ("\\b|\\b", @Y5);
print OUT  "\t elsif (\$whatever =~ m/\\bY5\\d+/) { \n";
print OUT  "\t\t if (\$whatever =~ m/(\\b$Y5\\b)/) { &compute(); } \n \t } \n";

$Y6 = join ("\\b|\\b", @Y6);
print OUT  "\t elsif (\$whatever =~ m/\\bY6\\d+/) { \n";
print OUT  "\t\t if (\$whatever =~ m/(\\b$Y6\\b)/) { &compute(); } \n \t } \n";

$Y7 = join ("\\b|\\b", @Y7);
print OUT  "\t elsif (\$whatever =~ m/\\bY7\\d+/) { \n";
print OUT  "\t\t if (\$whatever =~ m/(\\b$Y7\\b)/) { &compute(); } \n \t } \n";

$Y8 = join ("\\b|\\b", @Y8);
print OUT  "\t elsif (\$whatever =~ m/\\bY[89]\\d+/) { \n";
print OUT  "\t\t if (\$whatever =~ m/(\\b$Y8\\b)/) { &compute(); } \n \t } \n";

$ZC = join ("\\b|\\b", @ZC);
print OUT  "\t elsif (\$whatever =~ m/\\bZC\\d+/) { \n";
print OUT  "\t\t if (\$whatever =~ m/(\\b$ZC\\b)/) { &compute(); } \n \t } \n";

$ZK = join ("\\b|\\b", @ZK);
print OUT  "\t elsif (\$whatever =~ m/\\bZK\\d+/) { \n";
print OUT  "\t\t if (\$whatever =~ m/(\\b$ZK\\b)/) { &compute(); } \n \t } \n";

$remainder = join ("\\b|\\b", @remainder);
print OUT  "\t elsif (\$whatever =~ m/\\b$remainder\\b/) { &compute(); } \n \n";

close (OUT) or die "Cannot close $outfile : $!";
