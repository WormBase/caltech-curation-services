#!/usr/bin/perl 

$predlist = "/home2/azurebrd/Predicted_gene_WS31.txt";

open (IN, "$predlist") or die "cannot open $predlist : $!";

while (<IN>) {
  if ($_ =~ m/^Sequence/) { 
  ($a, $b) = split ("\"");
#  if ($b =~ m/^\d+/) {
#    push @numeric, $b;
#  } els
  if ($b =~ m/^A[CH]\d+/) {
    push @AC, $b;
  } elsif ($b =~ m/^B0\d+/) {
    push @B0, $b;
  } elsif ($b =~ m/^C0\d+/) {
    push @C0, $b;
  } elsif ($b =~ m/^C1\d+/) {
    push @C1, $b;
  } elsif ($b =~ m/^C2\d+/) {
    push @C2, $b;
  } elsif ($b =~ m/^C3\d+/) {
    push @C3, $b;
  } elsif ($b =~ m/^C4\d+/) {
    push @C4, $b;
  } elsif ($b =~ m/^C5\d+/) {
    push @C5, $b;
  } elsif ($b =~ m/^D[12]\d+/) {
    push @D1, $b;
  } elsif ($b =~ m/^E0\d+/) {
    push @E0, $b;
  } elsif ($b =~ m/^F0\d+/) {
    push @F0, $b;
  } elsif ($b =~ m/^F1\d+/) {
    push @F1, $b;
  } elsif ($b =~ m/^F2\d+/) {
    push @F2, $b;
  } elsif ($b =~ m/^F3\d+/) {
    push @F3, $b;
  } elsif ($b =~ m/^F4\d+/) {
    push @F4, $b;
  } elsif ($b =~ m/^F5\d+/) {
    push @F5, $b;
  } elsif ($b =~ m/^H0\d+/) {
    push @H0, $b;
  } elsif ($b =~ m/^H1\d+/) {
    push @H1, $b;
  } elsif ($b =~ m/^H2\d+/) {
    push @H2, $b;
  } elsif ($b =~ m/^H[34]\d+/) {
    push @H3, $b;
  } elsif ($b =~ m/^K0\d+/) {
    push @K0, $b;
  } elsif ($b =~ m/^K1\d+/) {
    push @K1, $b;
  } elsif ($b =~ m/^M\d{2,}/) {
    push @Md, $b;
  } elsif ($b =~ m/^R0\d+/) {
    push @R0, $b;
  } elsif ($b =~ m/^R1\d+/) {
    push @R1, $b;
  } elsif ($b =~ m/^T0\d+/) {
    push @T0, $b;
  } elsif ($b =~ m/^T1\d+/) {
    push @T1, $b;
  } elsif ($b =~ m/^T2\d+/) {
    push @T2, $b;
  } elsif ($b =~ m/^V[A-Z]/) {
    push @VA, $b;
  } elsif ($b =~ m/^W[01]\d[A-Z]/) {
    push @W0, $b;
  } elsif ($b =~ m/^Y1\d+/) {
    push @Y1, $b;
  } elsif ($b =~ m/^Y2\d+/) {
    push @Y2, $b;
  } elsif ($b =~ m/^Y3\d+/) {
    push @Y3, $b;
  } elsif ($b =~ m/^Y4\d+/) {
    push @Y4, $b;
  } elsif ($b =~ m/^Y5\d+/) {
    push @Y5, $b;
  } elsif ($b =~ m/^Y6\d+/) {
    push @Y6, $b;
  } elsif ($b =~ m/^Y7\d+/) {
    push @Y7, $b;
  } elsif ($b =~ m/^Y[89]\d+/) {
    push @Y8, $b;
  } elsif ($b =~ m/^ZC\d+/) {
    push @ZC, $b;
  } elsif ($b =~ m/^ZK\d+/) {
    push @ZK, $b;
  } else {
    push @remainder, $b;
  }
  } # if ($_ =~ m/^Sequence/)  
} # while (<IN>) 

# foreach $_ (@numeric) {print "$_\n"}
# foreach $_ (@AC) {print "$_\n"}
# foreach $_ (@B0) {print "$_\n"}

# $numeric = join ("\$|\^", @numeric);
# print "\t if (\$whatever =~ m/^$numeric\$/) { \$compute } \n";

$AC = join ("\$|\^", @AC);
print "\t if (\$whatever =~ m/\\sA[CH]\d+/) { \n";
print "\t\t if (\$whatever =~ m/^$AC\$/) { \$compute } \n \t } \n";

$B0 = join ("\$|\^", @B0);
print "\t elsif (\$whatever =~ m/\\sB0\d+/) { \n";
print "\t\t if (\$whatever =~ m/^$B0\$/) { \$compute } \n \t } \n";

$C0 = join ("\$|\^", @C0);
print "\t elsif (\$whatever =~ m/\\sC0\d+/) { \n";
print "\t\t if (\$whatever =~ m/^$C0\$/) { \$compute } \n \t } \n";

$C1 = join ("\$|\^", @C1);
print "\t elsif (\$whatever =~ m/\\sC1\d+/) { \n";
print "\t\t if (\$whatever =~ m/^$C1\$/) { \$compute } \n \t } \n";

$C2 = join ("\$|\^", @C2);
print "\t elsif (\$whatever =~ m/\\sC2\d+/) { \n";
print "\t\t if (\$whatever =~ m/^$C2\$/) { \$compute } \n \t } \n";

$C3 = join ("\$|\^", @C3);
print "\t elsif (\$whatever =~ m/\\sC3\d+/) { \n";
print "\t\t if (\$whatever =~ m/^$C3\$/) { \$compute } \n \t } \n";

$C4 = join ("\$|\^", @C4);
print "\t elsif (\$whatever =~ m/\\sC4\d+/) { \n";
print "\t\t if (\$whatever =~ m/^$C4\$/) { \$compute } \n \t } \n";

$C5 = join ("\$|\^", @C5);
print "\t elsif (\$whatever =~ m/\\sC5\d+/) { \n";
print "\t\t if (\$whatever =~ m/^$C5\$/) { \$compute } \n \t } \n";

$D1 = join ("\$|\^", @D1);
print "\t elsif (\$whatever =~ m/\\sD[12]\d+/) { \n";
print "\t\t if (\$whatever =~ m/^$D1\$/) { \$compute } \n \t } \n";

$E0 = join ("\$|\^", @E0);
print "\t elsif (\$whatever =~ m/\\sE0\d+/) { \n";
print "\t\t if (\$whatever =~ m/^$E0\$/) { \$compute } \n \t } \n";

$F0 = join ("\$|\^", @F0);
print "\t elsif (\$whatever =~ m/\\sF0\d+/) { \n";
print "\t\t if (\$whatever =~ m/^$F0\$/) { \$compute } \n \t } \n";

$F1 = join ("\$|\^", @F1);
print "\t elsif (\$whatever =~ m/\\sF1\d+/) { \n";
print "\t\t if (\$whatever =~ m/^$F1\$/) { \$compute } \n \t } \n";

$F2 = join ("\$|\^", @F2);
print "\t elsif (\$whatever =~ m/\\sF2\d+/) { \n";
print "\t\t if (\$whatever =~ m/^$F2\$/) { \$compute } \n \t } \n";

$F3 = join ("\$|\^", @F3);
print "\t elsif (\$whatever =~ m/\\sF3\d+/) { \n";
print "\t\t if (\$whatever =~ m/^$F3\$/) { \$compute } \n \t } \n";

$F4 = join ("\$|\^", @F4);
print "\t elsif (\$whatever =~ m/\\sF4\d+/) { \n";
print "\t\t if (\$whatever =~ m/^$F4\$/) { \$compute } \n \t } \n";

$F5 = join ("\$|\^", @F5);
print "\t elsif (\$whatever =~ m/\\sF5\d+/) { \n";
print "\t\t if (\$whatever =~ m/^$F5\$/) { \$compute } \n \t } \n";

$H0 = join ("\$|\^", @H0);
print "\t elsif (\$whatever =~ m/\\sH0\d+/) { \n";
print "\t\t if (\$whatever =~ m/^$H0\$/) { \$compute } \n \t } \n";

$H1 = join ("\$|\^", @H1);
print "\t elsif (\$whatever =~ m/\\sH1\d+/) { \n";
print "\t\t if (\$whatever =~ m/^$H1\$/) { \$compute } \n \t } \n";

$H2 = join ("\$|\^", @H2);
print "\t elsif (\$whatever =~ m/\\sH2\d+/) { \n";
print "\t\t if (\$whatever =~ m/^$H2\$/) { \$compute } \n \t } \n";

$H3 = join ("\$|\^", @H3);
print "\t elsif (\$whatever =~ m/\\sH[34]\d+/) { \n";
print "\t\t if (\$whatever =~ m/^$H3\$/) { \$compute } \n \t } \n";

$K0 = join ("\$|\^", @K0);
print "\t elsif (\$whatever =~ m/\\sK0\d+/) { \n";
print "\t\t if (\$whatever =~ m/^$K0\$/) { \$compute } \n \t } \n";

$K1 = join ("\$|\^", @K1);
print "\t elsif (\$whatever =~ m/\\sK1\d+/) { \n";
print "\t\t if (\$whatever =~ m/^$K1\$/) { \$compute } \n \t } \n";

$Md = join ("\$|\^", @Md);
print "\t elsif (\$whatever =~ m/\\sM\d{2,}/) { \n";
print "\t\t if (\$whatever =~ m/^$Md\$/) { \$compute } \n \t } \n";

$R0 = join ("\$|\^", @R0);
print "\t elsif (\$whatever =~ m/\\sR0\d+/) { \n";
print "\t\t if (\$whatever =~ m/^$R0\$/) { \$compute } \n \t } \n";

$R1 = join ("\$|\^", @R1);
print "\t elsif (\$whatever =~ m/\\sR1\d+/) { \n";
print "\t\t if (\$whatever =~ m/^$R1\$/) { \$compute } \n \t } \n";

$T0 = join ("\$|\^", @T0);
print "\t elsif (\$whatever =~ m/\\sT0\d+/) { \n";
print "\t\t if (\$whatever =~ m/^$T0\$/) { \$compute } \n \t } \n";

$T1 = join ("\$|\^", @T1);
print "\t elsif (\$whatever =~ m/\\sT1\d+/) { \n";
print "\t\t if (\$whatever =~ m/^$T1\$/) { \$compute } \n \t } \n";

$T2 = join ("\$|\^", @T2);
print "\t elsif (\$whatever =~ m/\\sT2\d+/) { \n";
print "\t\t if (\$whatever =~ m/^$T2\$/) { \$compute } \n \t } \n";

$VA = join ("\$|\^", @VA);
print "\t elsif (\$whatever =~ m/\\sV[A-Z]/) { \n";
print "\t\t if (\$whatever =~ m/^$VA\$/) { \$compute } \n \t } \n";

$W0 = join ("\$|\^", @W0);
print "\t elsif (\$whatever =~ m/\\sW[01]\d[A-Z]/) { \n";
print "\t\t if (\$whatever =~ m/^$W0\$/) { \$compute } \n \t } \n";

$Y1 = join ("\$|\^", @Y1);
print "\t elsif (\$whatever =~ m/\\sY1\d+/) { \n";
print "\t\t if (\$whatever =~ m/^$Y1\$/) { \$compute } \n \t } \n";

$Y2 = join ("\$|\^", @Y2);
print "\t elsif (\$whatever =~ m/\\sY2\d+/) { \n";
print "\t\t if (\$whatever =~ m/^$Y2\$/) { \$compute } \n \t } \n";

$Y3 = join ("\$|\^", @Y3);
print "\t elsif (\$whatever =~ m/\\sY3\d+/) { \n";
print "\t\t if (\$whatever =~ m/^$Y3\$/) { \$compute } \n \t } \n";

$Y4 = join ("\$|\^", @Y4);
print "\t elsif (\$whatever =~ m/\\sY4\d+/) { \n";
print "\t\t if (\$whatever =~ m/^$Y4\$/) { \$compute } \n \t } \n";

$Y5 = join ("\$|\^", @Y5);
print "\t elsif (\$whatever =~ m/\\sY5\d+/) { \n";
print "\t\t if (\$whatever =~ m/^$Y5\$/) { \$compute } \n \t } \n";

$Y6 = join ("\$|\^", @Y6);
print "\t elsif (\$whatever =~ m/\\sY6\d+/) { \n";
print "\t\t if (\$whatever =~ m/^$Y6\$/) { \$compute } \n \t } \n";

$Y7 = join ("\$|\^", @Y7);
print "\t elsif (\$whatever =~ m/\\sY7\d+/) { \n";
print "\t\t if (\$whatever =~ m/^$Y7\$/) { \$compute } \n \t } \n";

$Y8 = join ("\$|\^", @Y8);
print "\t elsif (\$whatever =~ m/\\sY[89]\d+/) { \n";
print "\t\t if (\$whatever =~ m/^$Y8\$/) { \$compute } \n \t } \n";

$ZC = join ("\$|\^", @ZC);
print "\t elsif (\$whatever =~ m/\\sZC\d+/) { \n";
print "\t\t if (\$whatever =~ m/^$ZC\$/) { \$compute } \n \t } \n";

$ZK = join ("\$|\^", @ZK);
print "\t elsif (\$whatever =~ m/\\sZK\d+/) { \n";
print "\t\t if (\$whatever =~ m/^$ZK\$/) { \$compute } \n \t } \n";

$remainder = join ("\$|\^", @remainder);
print "\t elsif (\$whatever =~ m/^$remainder\$/) { \$compute } \n \n";

close (IN) or die "cannot close $predlist : $!";
