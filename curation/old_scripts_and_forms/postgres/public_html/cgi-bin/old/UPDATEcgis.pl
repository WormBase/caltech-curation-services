#!/usr/bin/perl -w
#
# This script takes curation_azurebrd.cgi, reads it to $file, changes the email
# addresses to the proper ones, and changes the $user and $User to the different
# $user and $User for the 5 other real curation forms.
#
# Added $bak file with time stamp.  (sheesh, lost data, had to rewrite some
# subroutines.  dummy.)  2001-12-12
#
# Changed curationforms.cgi to have a $ccemail field for Mail::Mailer
# (&Mailer();); changed this script to send cc to appropriate curators.
# 2001-12-14

use strict;
use diagnostics;

  # the different forms
my $azurebrd = "/home/postgres/public_html/cgi-bin/curation_azurebrd.cgi";
my $andrei = "/home/postgres/public_html/cgi-bin/curation_andrei.cgi";
my $ranjana = "/home/postgres/public_html/cgi-bin/curation_ranjana.cgi";
my $erich = "/home/postgres/public_html/cgi-bin/curation_erich.cgi";
my $raymond = "/home/postgres/public_html/cgi-bin/curation_raymond.cgi";
my $wen = "/home/postgres/public_html/cgi-bin/curation_wen.cgi";
my $paul = "/home/postgres/public_html/cgi-bin/curation_paul.cgi";
my $bak = "/home/postgres/public_html/cgi-bin/curation_bak.cgi." . time;

  # init file (that will have all the curation form)
my $file = "";

open(AZU, "<$azurebrd") or die "Cannot open $azurebrd : $!";
open(BAK, ">$bak") or die "Cannot create $bak : $!";
{ 
  local $/;
    # read file into one var
  $file = <AZU>;
  print BAK $file;
    # change user and User
  $file =~ s/(my \$user = ')azurebrd(';\n)/$1andrei$2/;
  $file =~ s/(my \$User = ')Juancarlos Chan(';\n)/$1Andrei Petcherski$2/;
    # change emails's comment status
  $file =~ s/(my \$raymond = 'azurebrd\@minerva.caltech.edu';\n)/# $1/;
  $file =~ s/(my \$erich = 'azurebrd\@minerva.caltech.edu';\n)/# $1/;
  $file =~ s/(my \$raneri = 'azurebrd\@minerva.caltech.edu';\n)/# $1/;
  $file =~ s/(my \$wen = 'azurebrd\@minerva.caltech.edu';\n)/# $1/;
  $file =~ s/(my \$rec_cgc = 'azurebrd\@minerva.caltech.edu';\n)/# $1/;
  $file =~ s/(my \$rec_worm = 'azurebrd\@minerva.caltech.edu';\n)/# $1/;
  $file =~ s/(my \$rec_syl = 'azurebrd\@minerva.caltech.edu';\n)/# $1/;
  $file =~ s/(my \$rec_wormerich = 'azurebrd\@minerva.caltech.edu';\n)/# $1/;
  $file =~ s/(my \$rec_john = 'azurebrd\@minerva.caltech.edu';\n)/# $1/;
  $file =~ s/(my \$ccemail = '';\n)/# $1/;
  $file =~ s/# (my \$raymond = 'raymond\@its.caltech.edu';\n)/$1/;
  $file =~ s/# (my \$erich = 'emsch\@its.caltech.edu';\n)/$1/;
  $file =~ s/# (my \$raneri = 'ranjana\@eysturoy.caltech.edu, emsch\@its.caltech.edu';\n)/$1/;
  $file =~ s/# (my \$wen = 'wchen\@its.caltech.edu';\n)/$1/;
  $file =~ s/# (my \$rec_cgc = 'cgc\@wormbase.org';\n)/$1/;
  $file =~ s/# (my \$rec_worm = 'worm\@sanger.ac.uk';\n)/$1/;
  $file =~ s/# (my \$rec_syl = 'jonathan.hodgkin\@bioch.ox.ac.uk';\n)/$1/;

  $file =~ s/# (my \$rec_wormerich = 'worm\@sanger.ac.uk, emsch\@its.caltech.edu';\n)/$1/;
  $file =~ s/# (my \$rec_john = 'jspieth\@watson.wustl.edu';\n)/$1/;
  $file =~ s/# (my \$ccemail = 'curationmail\@minerva.caltech.edu';\n)/$1/;
} # close naked block

close (AZU) or die "Cannot close $azurebrd : $!";
close (BAK) or die "Cannot close $bak : $!";

  # write to andrei
my $and_file = $file;
$and_file =~ s/(my \$ccemail = 'curationmail\@minerva.caltech.edu)/$1/;
open(AND, ">$andrei") or die "Cannot rewrite $andrei : $!";
print AND $and_file;
close (AND) or die "Cannot close $andrei : $!";

  # change and write to erich
my $eri_file = $file;
$eri_file =~ s/(my \$ccemail = 'curationmail\@minerva.caltech.edu)/$1, emsch\@its.caltech.edu/;
$eri_file =~ s/(my \$user = ')andrei(';\n)/$1erich$2/;
$eri_file =~ s/(my \$User = ')Andrei Petcherski(';\n)/$1Erich Schwarz$2/;
open(ERI, ">$erich") or die "Cannot rewrite $erich : $!";
print ERI $eri_file;
close (ERI) or die "Cannot close $erich : $!";

  # change and write to raymond
my $ray_file = $file;
$ray_file =~ s/(my \$ccemail = 'curationmail\@minerva.caltech.edu)/$1, curator\@whitney.caltech.edu/;
$ray_file =~ s/(my \$user = ')andrei(';\n)/$1raymond$2/;
$ray_file =~ s/(my \$User = ')Andrei Petcherski(';\n)/$1Raymond Lee$2/;
open(RAY, ">$raymond") or die "Cannot rewrite $raymond : $!";
print RAY $ray_file;
close (RAY) or die "Cannot close $raymond : $!";

  # change and write to wen
my $wen_file = $file;
$wen_file =~ s/(my \$ccemail = 'curationmail\@minerva.caltech.edu)/$1, wchen\@its.caltech.edu/;
$wen_file =~ s/(my \$user = ')andrei(';\n)/$1wen$2/;
$wen_file =~ s/(my \$User = ')Andrei Petcherski(';\n)/$1Wen Chen$2/;
open(WEN, ">$wen") or die "Cannot rewrite $wen : $!";
print WEN $wen_file;
close (WEN) or die "Cannot close $wen : $!";

  # change and write to paul
my $paul_file = $file;
$paul_file =~ s/(my \$ccemail = 'curationmail\@minerva.caltech.edu)/$1, pws\@its.caltech.edu/;
$paul_file =~ s/(my \$user = ')andrei(';\n)/$1paul$2/;
$paul_file =~ s/(my \$User = ')Andrei Petcherski(';\n)/$1Paul Sternberg$2/;
open(PAU, ">$paul") or die "Cannot rewrite $paul : $!";
print PAU $paul_file;
close (PAU) or die "Cannot close $paul : $!";

  # change and write to ranjana
my $ranjana_file = $file;
$ranjana_file =~ s/(my \$ccemail = 'curationmail\@minerva.caltech.edu)/$1, pws\@its.caltech.edu/;
$ranjana_file =~ s/(my \$user = ')andrei(';\n)/$1ranjana$2/;
$ranjana_file =~ s/(my \$User = ')Andrei Petcherski(';\n)/$1Ranjana Kishore$2/;
open(PAU, ">$ranjana") or die "Cannot rewrite $ranjana : $!";
print PAU $ranjana_file;
close (PAU) or die "Cannot close $ranjana : $!";






