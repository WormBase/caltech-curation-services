#!/usr/bin/perl
#
# This takes in the wbg.txt and the author_contact.ace file, comparing them to check possible
# entries with BOTH entries, those with no corresponding ACE, those with no corresponding WBG.
#
# Updating to use wbg-tabbed data instead of WBG data.  Now satisfied that it does a similar job.
# Ace wasn't capturing the last line because was reading to < scalar (@lines) - 1 instead of to 
# < scalar (@lines).  &readWBG() had the same error, fixed.

use strict;
use diagnostics;

my $acefile = "/home/azurebrd/work/parsings/authorperson/filesources/author_contact.ace";
				# parsed file with only authors that have contact info
my $wbgfile = "/home/azurebrd/work/parsings/authorperson/filesources/wbg.txt";
my $wbgtabfile = "/home/azurebrd/work/parsings/authorperson/filesources/wbg-tabbed.txt";
my $errorfile = "/home/azurebrd/work/parsings/authorperson/errors/errorfile.comparecontactvswbg";

my %wbg;
my %ace;

open (ACE, "<$acefile") or die "Cannot open $acefile : $!";
open (WBG, "<$wbgfile") or die "Cannot open $wbgfile : $!";
open (TAB, "<$wbgtabfile") or die "Cannot open $wbgtabfile : $!";
open (ERR, ">$errorfile") or die "Cannot open $errorfile : $!";

# &readWBG();
&readACE();
&readWBGtab();



close (ACE) or die "Cannot close $acefile : $!";
close (WBG) or die "Cannot close $wbgfile : $!";
close (TAB) or die "Cannot close $wbgtabfile : $!";
close (ERR) or die "Cannot close $errorfile : $!";


my $wbg_key = '';
my $ace_key = '';
my %notinacedb;

foreach $wbg_key ( sort keys %wbg ) {
  if ( $ace{$wbg_key} ) {		# key for wbg is also an ace
    print "GOOD (MAYBE) $wbg_key\n";	# 780
    delete $ace{$wbg_key};
  } # if ( $ace{$wbg_key} ) 		# key for wbg is also an ace
  else {
    $notinacedb{$wbg_key}++;
#     print "$wbg_key NOT in ACEDB\n";
  }
} # foreach $wbg_key ( sort keys %wbg )

print "\nDIVIDER\n";

foreach ( sort keys %notinacedb ) { 	# 162
  print "$_ NOT in ACE\n";
} # foreach ( sort keys %notinacedb )

print "\nDIVIDER\n";

foreach $ace_key ( sort keys %ace ) { 	# 887
  print "$ace_key NOT in WBG\n";
} # foreach $ace_key ( sort keys %ace )

# &outputAceHash();
# &outputWbgHash();


sub readACE {
  local $/ = "";
  my %key_counter;
  while (<ACE>) { 
    my @lines = split/\n/, $_;
    my $line;			# initialize
    my $author = $lines[0];
    unless ($author =~ m/\"[\w\-\']+\s+[\w\-\'][\w\-\']*\"/) { 
      print ERR "ERROR : unsplittable author : $author in authors_contact.ace\n";
    } else { 			# splittable, do stuff
      my ($last, $firstinit) = $author =~ m/\"([\w\-\']+)\s+([\w\-\'])[\w\-\']*\"/;
      my $key = $last . "_" . $firstinit;
      $key_counter{$key}++;
      push @{ $ace{$key}[$key_counter{$key}-1]{author} }, $lines[0];
      for ($line = 1; $line < scalar(@lines); $line++) {
        if ($lines[$line] =~ m/^Also_known/) { push @{ $ace{$key}[$key_counter{$key}-1]{name} }, $lines[$line]; }
        elsif ($lines[$line] =~ m/^Full_name/) { push @{ $ace{$key}[$key_counter{$key}-1]{name} }, $lines[$line]; }
        elsif ($lines[$line] =~ m/^Labora/) { push @{ $ace{$key}[$key_counter{$key}-1]{lab} }, $lines[$line]; }
        elsif ($lines[$line] =~ m/^Old_l/) { push @{ $ace{$key}[$key_counter{$key}-1]{old_lab} }, $lines[$line]; }
        elsif ($lines[$line] =~ m/^Mail/) { push @{ $ace{$key}[$key_counter{$key}-1]{address} }, $lines[$line]; }
        elsif ($lines[$line] =~ m/^E_mail/) { push @{ $ace{$key}[$key_counter{$key}-1]{email} }, $lines[$line]; }
        elsif ($lines[$line] =~ m/^Phone/) { push @{ $ace{$key}[$key_counter{$key}-1]{phone} }, $lines[$line]; }
        elsif ($lines[$line] =~ m/^Fax/) { push @{ $ace{$key}[$key_counter{$key}-1]{fax} }, $lines[$line]; }
        else { print ERR "ERROR : unaccounted line $lines[$line] $line reading authors_contact.ace\n"; }
      } # for ($line = 1; $line < scalar(@lines); $line++) 
    } # else # unless ($author =~ m/\"\S\s+\S\"/)
  } # while (<ACE>)
} # sub readACE 

sub readWBGtab {
  my %key_counter;		# use this to keep track of how many different times a key has been
				# used for different people with the same name.
  $_ = <TAB>; $_ = <TAB>; $_ = <TAB>; $_ = <TAB>; $_ = <TAB>; $_ = <TAB>; $_ = <TAB>; $_ = <TAB>; 
  while (<TAB>) { 
    $_ =~ s///g;
    chomp;
    my ($title, $firstname, $middlename, $lastname, $suffix, $busstreet, $buscity, $busstate,
      $buspost, $buscountry, $mainphone, $labphone, $officephone, $fax, $email1, $email2, $lastchange,
      $labhead, $labcode, $listed, $papercopy, $paytype, $ponumber, $poposition) = split/\t/, $_;
    my (@array) = split /\t/, $_;

    my $name = '';
    unless ($lastname) { 	# if no name, don't process, print error
      print ERR "wbg-tabbed entry has no name : $_\n"; 
    } else { 			# if name, process
      $name = $firstname . " " . $middlename . " " . $lastname; 

      my $firstinitial = '';
      if ($firstname) { $firstinitial = substr($firstname, 0, 1); }
  
      my $address = '';
      if ($busstreet) { $address .= $busstreet . "\n"; }
      if ($buscity) { $address .= $buscity; }
      if ($busstate) { $address .= ", " . $busstate; }
      if ($buspost) { $address .= " " . $buspost; }
      if ($buscountry) { $address .= " " . $buscountry; }
  #     my $address = $busstreet . "\n" . $buscity . ", " . $busstate . " " . $buspost . " " .  $buscountry;
  
      my $extra = '';
      if ($lastchange) { $extra .= $lastchange . "\t"; }
      if ($labhead) { $extra .= $labhead . "\t"; }
      if ($ponumber) { $extra .= $ponumber . "\t"; }
      if ($poposition) { $extra .= $poposition; }
  #     my $extra = $lastchange . "\t" . $labhead . "\t" . $ponumber . "\t" . $poposition;
  
      my $key = $lastname . "_" . $firstinitial;		# make key using last and initial
      $key_counter{$key}++;	# add to counter, so that we can keep track of those with same name
				  # with this number
  
      push @{ $wbg{$key}[$key_counter{$key}-1]{name} }, $name;
				  # use %key_counter value minus one because we don't need to make the
				  # array unnecessarily bigger
      if ($labphone) { push @{ $wbg{$key}[$key_counter{$key}-1]{lab} }, $labphone; }
      if ($fax) { push @{ $wbg{$key}[$key_counter{$key}-1]{fax} }, $fax; }
      if ($officephone) { push @{ $wbg{$key}[$key_counter{$key}-1]{office} }, $officephone; }
      if ($mainphone) { push @{ $wbg{$key}[$key_counter{$key}-1]{phone} }, $mainphone; }
      if ($email1) { push @{ $wbg{$key}[$key_counter{$key}-1]{email} }, $email1; }
      if ($email2) { push @{ $wbg{$key}[$key_counter{$key}-1]{email} }, $email2; }
      if ($labcode) { push @{ $wbg{$key}[$key_counter{$key}-1]{lab} }, $labcode; }
      if ($address) { push @{$wbg{$key}[$key_counter{$key}-1]{address} }, $address; }
      if ($extra) { push @{$wbg{$key}[$key_counter{$key}-1]{extra} }, $extra; }
    } # else # unless ($lastname)
#     for (my $i = 0; $i < $#array; $i++) { print "$i : $array[$i]\n"; }
#     print "ponumber : $_" if $ponumber;
#     print "listed : $_" if $listed;
  } # while (<TAB>)
} # sub readWBGtab

sub readWBG { 
  local $/ = "";
  my %key_counter;		# use this to keep track of how many different times a key has been
				# used for different people with the same name.
  while (<WBG>) {		# for each wbg entry
    my @lines = split/\n/, $_;	# split into lines
    my $line;			# initialize
    my $name = $lines[0]; 	# get the name
    unless ($name =~ m/(.*)\s+([\S]+)/) { 			# check if splittable
      print ERR "ERROR : unsplittable name : $name in wbg.txt\n";
    } else { # unless ($name =~ m/(.*)\s+([\S]+)/) 		# if it is splittable do stuff
      my ($firstname, $lastname) = $name =~ m/(.*)\s+([\S]+)/;	# get the first and last names
      my $firstinitial = '';	# initialize
      if ($firstname) { 	# for some reason splits on line 487 of wbg.txt (?)
			  	# if i don't check for a firsname
        $firstinitial = substr($firstname, 0, 1); 
				# makes a fuzz about not having something to substr on line 487
      } else {			# but doesn't if i try to catch it here.  i don't get it.
        print ERR "ERROR : $name doesn't have a firstname\n"; 	
      } # else # if ($firstname) 
      my $key = $lastname . "_" . $firstinitial;		# make key using last and initial
      $key_counter{$key}++;	# add to counter, so that we can keep track of those with same name
				# with this number
      push @{ $wbg{$key}[$key_counter{$key}-1]{name} }, $lines[0];
				# use %key_counter value minus one because we don't need to make the
				# array unnecessarily bigger
      for ($line = 1; $line < scalar(@lines); $line++) {
				# for each line, check appropriateness, and push into HoHoAoHoA
        if ($lines[$line] =~ m/LAB/) { push @{ $wbg{$key}[$key_counter{$key}-1]{lab} }, $lines[$line]; }
        elsif ($lines[$line] =~ m/FAX/) { push @{ $wbg{$key}[$key_counter{$key}-1]{fax} }, $lines[$line]; }
        elsif ($lines[$line] =~ m/OFFICE/) { push @{ $wbg{$key}[$key_counter{$key}-1]{office} }, $lines[$line]; }
        elsif ($lines[$line] =~ m/PHONE/) { push @{ $wbg{$key}[$key_counter{$key}-1]{phone} }, $lines[$line]; }
        elsif ($lines[$line] =~ m/^\S+@\S+$/) { push @{ $wbg{$key}[$key_counter{$key}-1]{email} }, $lines[$line]; }
        elsif ($lines[$line] =~ m/\w/) { push @{$wbg{$key}[$key_counter{$key}-1]{address} }, $lines[$line]; }
        else { print ERR "ERROR : unaccounted line $lines[$line] $line reading wbg.txt\n"; }
      } # for ($line = 1; $line < scalar(@lines); $line++) 
    } # else # unless ($name =~ m/(.*)\s+([\S]+)/) 
  } # while (<WBG>)
  print ERR "\nDIVIDER\n";
} # sub readWBG 


sub outputAceHash {		# show that ace hash has been properly populated
  my ($entry, $counter, $type, $i); 				# initialize counters
  for $entry ( sort keys %ace ) {				# get keys of HoH
    for $counter ( 0 .. scalar( @{ $ace{$entry} } )-1 ) {	# get numbers of HoHoA
      for $type ( sort keys %{ $ace{$entry}[$counter] } ) {	# get keys of HoHoAoH
        for $i ( 0 .. $#{ $ace{$entry}[$counter]{$type} } ) {	# get numbers of HoHoAoHoA
          print "$entry : $counter : $type : $ace{$entry}[$counter]{$type}[$i]\n";
								# print the values
        } # for $i ( 0 .. $#{ $ace{$entry}[$counter]{$type} } )
      } # for $type ( sort keys $ace{$entry}[$counter] )
      print "\n";						# newline divides each entry
    } # for $counter ( 1 .. $# { $ace{$entry} } ) 
  } # for $entry ( sort keys %ace )
} # sub outputWbgHash

sub outputWbgHash {		# show that wbg hash has been properly populated
  my ($entry, $counter, $type, $i); 				# initialize counters
  for $entry ( sort keys %wbg ) {				# get keys of HoH
#     print "$entry : ";
#         print "entry : $wbg{$entry}[1]{address}[0]\n";
#         print "Lee_R : $wbg{Lee_R}[1]{address}[0]\n";
# print "scalar " . scalar @{ $wbg{$entry} } . "\n";
    for $counter ( 0 .. scalar( @{ $wbg{$entry} } )-1 ) {	# get numbers of HoHoA
#     for $counter ( 0 .. $# { $wbg{$entry} } ) 	# no idea why this doesn't work..
#         print "counter : $wbg{$entry}[$counter]{address}[0]\n";
#         print "1 : $wbg{$entry}[1]{address}[0]\n";
      for $type ( sort keys %{ $wbg{$entry}[$counter] } ) {	# get keys of HoHoAoH
#       print "$type : ";
#         print "type : $wbg{$entry}[$counter]{$type}[0]\n";
#         print "address : $wbg{$entry}[$counter]{address}[0]\n";
        for $i ( 0 .. $#{ $wbg{$entry}[$counter]{$type} } ) {	# get numbers of HoHoAoHoA
          print "$entry : $counter : $type : $wbg{$entry}[$counter]{$type}[$i]\n";
								# print the values
        } # for $i ( 0 .. $#{ $wbg{$entry}[$counter]{$type} } )
      } # for $type ( sort keys $wbg{$entry}[$counter] )
# print "counter : $counter";
      print "\n";						# newline divides each entry
    } # for $counter ( 1 .. $# { $wbg{$entry} } ) 
  } # for $entry ( sort keys %wbg )
} # sub outputWbgHash



