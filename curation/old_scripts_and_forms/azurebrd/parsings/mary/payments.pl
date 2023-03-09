#!/usr/bin/perl

$infile = "final_check_recipients.txt";

open (IN, "$infile") or die "Cannot open $infile : $!";

while (<IN>) {
  ($name, $amount, $socsec, $visa, $address1, $address2, $country) = split("\t", $_); #   print "$name\n";
  $name =~ s/\"//g; # print "$name\n";
  $address1 =~ s/\"//g;
  $address2 =~ s/\"//g;
  $country =~ s/\"//g;
  $counter++;
  if ($counter < 10) { $value = "00" . $counter; }
  elsif ($counter < 100) { $value = "0" . $counter; }
  else { $value = $counter; }
  ($lastname, $firstname) = split(",", $name);
  $lastname =~ s/\s//g;
  $filename = $value . $lastname . ".xls";
#   print "$filename\n";

  open (OUT, ">$filename") or die "Cannot create $filename : $!";
  print OUT "\n";
  print OUT "\t\t\t\t\t\t\tDate :\t7/17/01\n";
  print OUT "\n";
  print OUT "\n";
  print OUT "TYPE APPROPRIATE PAYEE INFORMATION IN THE BLOCKS BELOW.\n";
  print OUT "PAYEE INFORMATION\t\t\tFOR PAYABLES USE ONLY\t\t\tCITIZENSHIP, CALTECH EMPLOYMENT AND TAX ID.\n";
  print OUT "\t\t\t\t\t\t\t\tYES\tNO\n";
  print OUT "PAYEE NAME (LAST, FIRST)\t\tSUPPLIER NUMBER\tAPPROVED BY\t\t\tIs payee a U.S. Citizen?\n";
  print OUT "$name\n";
  print OUT "REMITTANCE ADDRESS\t\t\tPROCESSOR NAME\t\t\tIs payee a California Resident ?\n";
  print OUT "$address1\n";
  print OUT "ADDRESS CONT'D\t\t\tCHECK No.\t\t\tIs payee a CALTECH Employee ?\n";
  print OUT "$address2\n";
  if ($socsec) {
    print OUT "City\tSTATE\tZIP + 4\tTaxpayer ID No/Social Security No.  (Required):\t\t$socsec\n";
  } else {
    print OUT "City\tSTATE\tZIP + 4\tTaxpayer ID No/Social Security No.  (Required):\t\t$visa\n";
  }
  print OUT "$country\n";
  print OUT "ENTER DESCRIPTION FOR CHECK STUB (23 CHARACTERS)\n";
  print OUT "financial aid\n";
  print OUT "\n";
  print OUT "PROJECT\tORGANIZATION\tEXPENDITURE TYPE\tTASK\tAWARD\tDOCUMENT NUMBER\tDOCUMENT DATE\tDOCUMENT AMOUNT\n";
  print OUT "\n";
  print OUT "PWS.00012\tCaltech\ttravel-participant support\t\t1\tNIH.000087\t\t\t$amount\n";
  print OUT "\tCaltech\n";
  print OUT "\tCaltech\n";
  print OUT "\tCaltech\n";
  print OUT "\tCaltech\n";
  print OUT "\tCaltech\n";
  print OUT "\tCaltech\t\t\t\t\t\t\tPAYMENT TOTAL\n";
  print OUT "Complete Payment Description or Justification if Required\t\t\t\t\t\t\t\t$amount\n";
  print OUT "financial aid support for participation in the 2001 International C. elegans Meeting\n";
  print OUT "Prepared by\tMary Alvarez\t\tExt.\t3990\t\tPayment Approval (Signature)\n";
  print OUT "Department Name\tBiology\t\t\t\t\tName (typed)   Paul W.  Sternberg\n";
  print OUT "Mail Code\t156-29\t\t\t\t\tTitle\tProfessor\n";
  close (OUT) or die "Cannot close $filename : $!";
}
