#!/usr/bin/perl


################################################################################
#
# Pre-processing Instructions
# 
# Open a browser to http://www.ncbi.nlm.nih.gov:80/entrez/query.fcgi and
# search for ``elegans''.  Set the Display (button next to it) to MEDLINE,
# click DISPLAY again to reload.  Click the Save button (not the text
# button, since that only shows the first page of all the matches).
# Ask Wen for the latest version of gophbib.endnote or download from
# http://vermicelli.caltech.edu/~wen/gophbib.endnote
#
#
# About the code
#
# Read both CGCs (endnote) and PMs (pubmed.medline) into hashes keying off
# of Volume Page Author.  If a key is not well-formed, store separetly to
# output as error.  If no entry, store separetly for output as error.  Count 
# number of time a key is used.  (Print out if more than once for each file).  
# Foreach PM key, if both PM and CGC, print; if not, store as missing CGC 
# counterpart.  Same foreach CGC key.  Foreach missing counterpart CGC, print 
# it.  Same foreach missing counterpart PM.			- 08 11 01
#
# If a key has more than one entry, output summary to double, full entries to
# double_full.  If good, output summary to good_output, .ace entry to acefile.
# If a PM has no matching CGC entry, output to pm_nocgc.  If a CGC has no 
# matching PM, output to cgc_nopm.  If a PM key is not complete, output to 
# pm_badkey1.  If a CGC key is not complete output to cgc_badkey1.  Later try 
# to process cgc_nopm with pm_badkey1 and pm_nocgc to try to find further 
# matches.  Also manually check double_full for good PM entries.
#
# Secondpass takes the remaining PM entries that didn't match CGC entries, and
# the remaining CGC entries that didn't match PM entries, and processes them
# by replacing C. with Caenorhabditis, and removing all but letters and digits
# from the titles to make a new key for the hashes of the second pass.  Keying
# off of the title, the full values, IDs, and a counter hash (for each title)
# is made for CGCs and PMs.  Foreach of these keys, then, if both a PM and CGC
# have an entry, that is outputted to good_output_2 (summary), and the acefile.
# Likewise, multiple keys are stored into the similar double_two; however,
# entries here have already been screened in double, so only in the case
# that a new match is found (Unlikely since only 30 additional matches are 
# accomplished this way), does a WARN get printed to check if it's the proper
# entry.  The remaining unmatched entries are passed on to a set of third 
# hashes for possible future processing.			- 08 15 01 
#
# Potential need to manually check double (double_full), for possible good 
# matches.  Also pm_badkey1 to see if those entries could have matched some 
# cgc entries.
#
# Note : If revised, put data for each key into a Hash or Arrays, instead of
# a plain Hash; that way we can keep all data instead of making second hashes
# that Count the amount of times a key has been used (and lose the previous
# value)
#
################################################################################


  # Processing
&set_files();			# set input and output files
&getpm();			# process pm 
&getcgc();			# process cgc
&firstpass();			# control output by first pass
&secondpass();			# control output by second pass
&close_files();			# close filehandles



  # Subroutines

sub getpm {			# process pm
  $/ = "";			# reset $/ just in case
  open (PM, "$pmfile") or die "Cannot open $pmfile : $!";
  while ($frompm = <PM>) {
    $keypm = "";
    $volnum = $pgnum = $authorpm = "";
    $volumeflag = $pageflag = $authorflag = 0;
    if ($frompm =~ m/VI  - \d+/) {$volumeflag = 1;}
    if ($frompm =~ m/PG  - \d+/) {$pageflag = 2;}
    if ($frompm =~ m/AU  - \w+/) {$authorflag = 4;}
    unless ( ($volumeflag == "1") && ($pageflag == "2") && ($authorflag == "4") ) {
	# handle BAD KEYS
      $keypm = &pmkey($frompm);		# set the pmkey
      $titlepm = &pmtitle($frompm);	# set the pmtitle
      # push @badpubentries, $keypm;	# old way
      $BadPMfirstCounter{$keypm}++;	# count of each bad pm entry keypm
      if ($BadPMfirstCounter{$keypm} > 1) { 
					# if already used that key
	$keypm .= " $BadPMfirstCounter{$keypm}" 
					# alter key to include the count
      } # if ($BadPMfirstCounter{$keypm} > 1) 
      $BadPMfirst{$keypm} = $frompm;	# store bad pm entries
      &pmid($frompm, $keypm);		# grab PMID
    } else { # unless ( ($volume == "1") ...
	# work with GOOD KEYS
      $keypm = &pmkey($frompm);		# set the pmkey
      $titlepm = &pmtitle($frompm);	# set the pmtitle
      $PMTitle{$keypm} = $titlepm;	# store title by keypm
      $PMCounter{$keypm}++;		# count of each good pm entry keypm
      $PMHash{$keypm} = $frompm;	# store good pm entry
      &pmid($frompm, $keypm);		# grab PMID
    } # else # unless ( ($volume == "1") ...
  } # while (<PM>) 
  close (PM) or die "Cannot close $pmfile : $!";
} # sub getpm 


sub getcgc { 
  $/ = "\n";
  open (CGC, "$cgcfile") or die "Cannot open $cgcfile : $!";
  while ($fromcgc = <CGC>) {
    chomp;
    @stuff = split("\t", $fromcgc);
    if ($stuff[5]) { $volumeflag = 1; }
    if ($stuff[6]) { $pageflag = 2; }
    if ($stuff[2]) { $authorflag = 4; }
    unless ($fromcgc =~ m/^\d/) { 		# if an entry
      # NOT ENTRY
      &cgckey();				# get cgc key
      &cgctitle();				# get cgc title
      $NotCGCEntry{$keycgc} = $fromcgc;
    } else {
      # ENTRY
      unless ( ($volumeflag == "1") && ($pageflag == "2") && ($authorflag == "4") ) {
	  # handle BAD KEYS
        &cgckey();				# get cgc key
        &cgctitle();				# get cgc title
	$BadCGCfirst{$keycgc} = $fromcgc;	# store bad cgc entries
	$BadCGCfirstCounter{$keycgc}++;		# count of each bad cgc keycgc
      } else { # unless ( ($volume == "1") ...
	  # work with GOOD KEYS
        &cgckey();				# get cgc key
	&cgctitle();				# get cgc title
	$CGCTitle{$keycgc} = $titlecgc;		# put title in hash
        $CGCCounter{$keycgc}++;			# count of each good cgc entry keycgc
	$CGCHash{$keycgc} = $fromcgc;		# store good cgc entry
	# &oldprocessing();
      } # unless ( ($volumeflag == "1") ... 
    } # unless ($fromcgc =~ m/^\d/) 
  } # while (<CGC>) 
  $/ = "";					# restore $/
} # sub getcgc 



sub firstpass {				# process first pass by author/vol/pg num

  foreach $_ (sort keys %PMHash) {	# capture unmatched PMs
# print "PMID : $_\n";
    if ($PMCounter{$_} > 1) { 		# if too many with same key
      print DBL "PMCount : $PMCounter{$_}\t KEY : $_\tPMID : $PMIDHash{$_}\t";
      print DBL "CGC : $CGCNumberHash{$_}\n";			 
					# summary
    } else {				# good so process it
      if ( ($PMHash{$_}) && ($CGCHash{$_}) ) { 	# if both entries
        print GOO "PMID : $PMIDHash{$_}\t CGC : $CGCNumberHash{$_}\n";
        print ACE "Paper : [cgc$CGCNumberHash{$_}]\n";
        print ACE "PMID\t$PMIDHash{$_}\n\n";
      } else {				# if there is a PM entry, but no CGC entry
        $PMHashSecond{$_} = $PMHash{$_};
      } # else # if ( ($PMHash{$_}) && ...
    } # else # if ($PMCounter{$_} > 1)
  } # foreach $_ (sort keys %PMHash)

  foreach $_ (sort keys %CGCHash) {	# capture unmatched CGCs
# print "CGC : $_\n";
    if ($CGCCounter{$_} > 1) { 		# if too many with same key
      print DBL "CGCCount : $CGCCounter{$_}\t KEY : $_\tPMID : $PMIDHash{$_}\t";
      print DBL "CGC : $CGCNumberHash{$_}\n"; 			 
					# summary
    } else {				# good so process it
      if ( ($PMHash{$_}) && ($CGCHash{$_}) ) { 	# if both entries
	  # useless, repeats above
        # print "PMID : $PMIDHash{$_}\t CGC : $CGCNumberHash{$_}\n";
        # print "CGC : $CGCNumberHash{$_}\t PMID : $PMIDHash{$_}\n";
      } else {				# if there is a CGC entry, but no PM entry
        $CGCHashSecond{$_} = $CGCHash{$_};
      } # else # if ( ($PMHash{$_}) && ...
    } # else # if ($CGCCounter{$_} > 1)
  } # foreach $_ (sort keys %GCCHash) 

  print "After First processing, there are " . scalar(keys %PMHashSecond) . " ";
  print "PMs with No_matching_cgcs\n";
  print PM2 "After First processing, there are " . scalar(keys %PMHashSecond) . " ";
  print PM2 "PMs with No_matching_cgcs\n";
  foreach $_ (sort keys %PMHashSecond) {
    print PM2 "NO MATCHING CGC : \t$PMIDHash{$_}\t KEY : $_\t$PMTitle{$_}\n";
    print P2F "$PMHash{$_}\n";
    $SecondPMPass{$_} = $PMTitle{$_};
  } # foreach $_ (sort keys %PMHashSecond) 

  print "After First processing, there are " . scalar(keys %CGCHashSecond) . " ";
  print "CGCs with No_matching_pms\n";
  print CG2 "After First processing, there are " . scalar(keys %CGCHashSecond) . " ";
  print CG2 "CGCs with No_matching_pms\n";
  foreach $_ (sort keys %CGCHashSecond) {
    print CG2 "NO MATCHING PM : \t$CGCNumberHash{$_}\t KEY : $_\t$CGCTitle{$_}\n";
    print C2F "$CGCHash{$_}\n";
    $SecondCGCPass{$_} = $CGCTitle{$_};
  } # foreach $_ (sort keys %CGCHashSecond) 

  foreach $_ (sort keys %NotCGCEntry) {
    # print "NO CGC ENTRY : $NotCGCEntry{$_}\n";
      # Commented out due to all CGC entries being good
  } # foreach $_ (sort keys %NotCGCEntry) 

  print "There are " . scalar(keys %BadPMfirst) . " bad_pm_keys for the first pass\n";
  foreach $_ (sort keys %BadPMfirst) {
    $SecondPMPass{$_} = $PMTitle{$_};	# put title to match 
    print KPM "BAD PM : $PMIDHash{$_}\tKEY : $_\tCOUNT : $BadPMfirstCounter{$_}\n"; 
  } # foreach $_ (sort keys %BadPMfirst) 

  print "There are " . scalar(keys %BadCGCfirst) . " bad_cgc_keys for the first pass\n";
  foreach $_ (sort keys %BadCGCfirst) {
    print KCG "BAD CGC : $BadCGCfirst{$_}\n"; 
  } # foreach $_ (sort keys %BadCGCfirst) 

} # sub firstpass 



sub secondpass {			# process second pass by Title

  foreach $secondpmkey (sort keys %SecondPMPass) {
    $TweakedPMTitle = $PMTitle{$secondpmkey};		# get the title
    $TweakedPMTitle =~ s/\bC\.\b/Caenorhabditis/g;	# filter abbreviation
    $TweakedPMTitle =~ s/[^A-Za-z0-9]//g;		# filter for simple key
    $SecondPMCounter{$TweakedPMTitle}++;		# count how many with title
    $SecondPMIDHash{$TweakedPMTitle} = $PMIDHash{$secondpmkey};
							# get the PMIDHash
    $SecondPMHash{$TweakedPMTitle} = $PMHash{$secondpmkey};
							# get the PMHash
    $SecondPMTitle{$TweakedPMTitle} = $PMTitle{$secondpmkey};
							# get the PMTitle
    $SecondPMfirstkey{$TweakedPMTitle} = $secondpmkey;	# get the pmkey
						# in case we need to backtrack
  } # foreach $_ (sort keys %SecondPMPass) 
    
  foreach $secondcgckey (sort keys %SecondCGCPass) {
    $TweakedCGCTitle = $CGCTitle{$secondcgckey};	# get the title
    $TweakedCGCTitle =~ s/\bC\.\b/Caenorhabditis/g;	# filter abbreviation
    $TweakedCGCTitle =~ s/[^A-Za-z0-9]//g;		# filter for simple key
    $SecondCGCCounter{$TweakedCGCTitle}++;		# count how many with title
    $SecondCGCNumberHash{$TweakedCGCTitle} = $CGCNumberHash{$secondcgckey};
							# get the CGCNumberHash
    $SecondCGCHash{$TweakedCGCTitle} = $CGCHash{$secondcgckey};
							# get the CGCHash
    $SecondCGCTitle{$TweakedCGCTitle} = $CGCTitle{$secondcgckey};
							# get the CGCTitle
    $SecondCGCfirstkey{$TweakedCGCTitle} = $secondcgckey;
						# get the cgckey
						# in case we need to backtrack
  } # foreach $secondcgckey (sort keys %SecondCGCPass) 

  foreach $_ (sort keys %SecondCGCHash) {	# capture unmatched CGCs
    if ($SecondCGCCounter{$_} > 1) { 		# if too many with same key
      print D2L "CGCCount : $SecondCGCCounter{$_}\t KEY : $_\t";
      print D2L "PMID : $SecondPMIDHash{$_}\tCGC : $SecondCGCNumberHash{$_}\n";
						# summary
      if ( ($SecondCGCHash{$_}) && ($SecondPMHash{$_}) ) { 		
						# if too many with same key
        print D2L "WARN : CGCCount : $SecondCGCCounter{$_}\t KEY : $_\t";
        print D2L "PMID : $SecondPMIDHash{$_}\tCGC : $SecondCGCNumberHash{$_}\n";
      } # if ( ($SecondCGCHash{$_}) && ($SecondPMHash{$_}) ) 
    } else {					# good so process it
      if ( ($SecondCGCHash{$_}) && ($SecondPMHash{$_}) ) { 	
						# if both entries
        print GO2 "PMID : $SecondPMIDHash{$_}\t CGC : $SecondCGCNumberHash{$_}\n";
        print ACE "Paper : [cgc$SecondCGCNumberHash{$_}]\n";
        print ACE "PMID\t$SecondPMIDHash{$_}\n\n";
      } else {					# if a PM entry, but no CGC entry
        $CGCHashThird{$_} = $SecondCGCHash{$_};	# store for third pass if necessary
      } # else # if ( ($SecondCGCHash{$_} && ...
    } # else # if ($SecondCGCCounter{$_} > 1)
  } # foreach $_ (sort keys %SecondPMTitle)

  foreach $_ (sort keys %SecondPMHash) {	# capture unmatched PMs
    if ($SecondPMCounter{$_} > 1) { 		# if too many with same key
      print D2L "PMCount : $SecondPMCounter{$_}\t KEY : $_\t";
      print D2L "PMID : $SecondPMIDHash{$_}\tCGC : $SecondCGCNumberHash{$_}\n";
				 	 	# summary
    } else {					# good so process it
      if ( ($SecondPMHash{$_}) && ($SecondCGCHash{$_}) ) { 	
						# if both entries already covered 
      } else {					# if a CGC entry, but no PM entry
        $PMHashThird{$_} = $SecondPMHash{$_};	# store for third pass if necessary
      } # else # if ( ($SecondPMHash{$_}) && ...
    } # else # if ($SecondPMCounter{$_} > 1)
  } # foreach $_ (sort keys %SecondCGCTitle) 

  print "After Second processing, there are " . scalar(keys %PMHashThird) . " ";
  print "PMs with No_matching_cgcs\n";
  print PM3 "After Second processing there are " . scalar(keys %PMHashThird) . " ";
  print PM3 "PMs with No_matching_cgcs\n";
  foreach $_ (sort keys %PMHashThird) {
    print PM3 "NO MATCHING CGC : \t$SecondPMIDHash{$_}\t KEY : $_\t";
    print PM3 "Title : $SecondPMTitle{$_}\n";
    print P3F "$SecondPMHash{$_}\n";
    $ThirdPMPass{$_} = $PMTitle{$_};
  } # foreach $_ (sort keys %PMHashThird) 

  print "After Second processing, there are " . scalar(keys %CGCHashThird) . " ";
  print "CGCs with No_matching_pms\n";
  print CG3 "After Second processing, there are " . scalar(keys %CGCHashThird) . " ";
  print CG3 "CGCs with No_matching_pms\n";
  foreach $_ (sort keys %CGCHashThird) {
    print CG3 "NO MATCHING PM : \t$SecondCGCNumberHash{$_}\t KEY : $_\t";
    print CG3 "Title : $SecondCGCTitle{$_}\n";
    print C3F "$SecondCGCHash{$_}\n";
    $ThirdCGCPass{$_} = $CGCTitle{$_};
  } # foreach $_ (sort keys %CGCHashThird) 

} # sub secondpass 



sub set_files {
    # Input files
  $cgcfile = '/home/azurebrd/work/endnotes/gophbib.endnote';
  # $cgcfile = '/home/postgres/work/pgpopulation/cgc_pmid_correlations/gophbib.test';
  $pmfile = '/home/postgres/work/pgpopulation/cgc_pmid_correlations/pubmed.medline';
  # $pmfile = '/home/postgres/work/pgpopulation/cgc_pmid_correlations/pubmed.test';
    
    # Output files, 1st pass
  $double = "/home/postgres/work/pgpopulation/cgc_pmid_correlations/one_double";
  open (DBL, ">$double") or die "Cannot create $double : $!";
  $double_full = "/home/postgres/work/pgpopulation/cgc_pmid_correlations/one_double_full";
  open (DBF, ">$double_full") or die "Cannot create $double_full : $!";
  $good_output = "/home/postgres/work/pgpopulation/cgc_pmid_correlations/one_good_output";
  open (GOO, ">$good_output") or die "Cannot create $good_output : $!";
  $acefile = "/home/postgres/work/pgpopulation/cgc_pmid_correlations/one_acefile";
  open (ACE, ">$acefile") or die "Cannot create $acefile : $!";
  $pm_nocgc = "/home/postgres/work/pgpopulation/cgc_pmid_correlations/one_pm_nocgc";
  open (PM2, ">$pm_nocgc") or die "Cannot create $pm_nocgc : $!";
  $pm_nocgc_full = "/home/postgres/work/pgpopulation/cgc_pmid_correlations/one_pm_nocgc_full";
  open (P2F, ">$pm_nocgc_full") or die "Cannot create $pm_nocgc_full : $!";
  $cgc_nopm = "/home/postgres/work/pgpopulation/cgc_pmid_correlations/one_cgc_nopm";
  open (CG2, ">$cgc_nopm") or die "Cannot create $cgc_nopm : $!";
  $cgc_nopm_full = "/home/postgres/work/pgpopulation/cgc_pmid_correlations/one_cgc_nopm_full";
  open (C2F, ">$cgc_nopm_full") or die "Cannot create $cgc_nopm_full : $!";
  $pm_badkey1 = "/home/postgres/work/pgpopulation/cgc_pmid_correlations/one_pm_badkey1";
  open (KPM, ">$pm_badkey1") or die "Cannot create $pm_badkey1 : $!";
  $cgc_badkey1 = "/home/postgres/work/pgpopulation/cgc_pmid_correlations/one_cgc_badkey1";
  open (KCG, ">$cgc_badkey1") or die "Cannot create $cgc_badkey1 : $!";

    # Output files, 2nd pass
  $double_two = "/home/postgres/work/pgpopulation/cgc_pmid_correlations/two_double_two";
  open (D2L, ">$double_two") or die "Cannot create $double_two : $!";
  $good_output_two = "/home/postgres/work/pgpopulation/cgc_pmid_correlations/two_good_output_two";
  open (GO2, ">$good_output_two") or die "Cannot create $good_output_two : $!";
  $pm_nocgc_two = "/home/postgres/work/pgpopulation/cgc_pmid_correlations/two_pm_nocgc_two";
  open (PM3, ">$pm_nocgc_two") or die "Cannot create $pm_nocgc_two : $!";
  $pm_nocgc_full_two = "/home/postgres/work/pgpopulation/cgc_pmid_correlations/two_pm_nocgc_full_two";
  open (P3F, ">$pm_nocgc_full_two") or die "Cannot create $pm_nocgc_full_two : $!";
  $cgc_nopm_two = "/home/postgres/work/pgpopulation/cgc_pmid_correlations/two_cgc_nopm_two";
  open (CG3, ">$cgc_nopm_two") or die "Cannot create $cgc_nopm_two : $!";
  $cgc_nopm_full_two = "/home/postgres/work/pgpopulation/cgc_pmid_correlations/two_cgc_nopm_full_two";
  open (C3F, ">$cgc_nopm_full_two") or die "Cannot create $cgc_nopm_full_two : $!";
} # sub set_files 


sub close_files {
  close DBL or die "Cannot close $double : $!";
  close DBF or die "Cannot close $double_full : $!";
  close GOO or die "Cannot close $good_output : $!";
  close ACE or die "Cannot close $acefile : $!";
  close PM2 or die "Cannot close $pm_nocgc : $!";
  close P2F or die "Cannot close $pm_nocgc_full : $!";
  close CG2 or die "Cannot close $cgc_nopm : $!";
  close C2F or die "Cannot close $cgc_nopm_full : $!";
  close KPM or die "Cannot close $pm_badkey1 : $!";
  close KCG or die "Cannot close $cgc_badkey1 : $!";
  close D2L or die "Cannot close $double_two : $!";
  close GO2 or die "Cannot close $good_output_two : $!";
  close PM3 or die "Cannot close $pm_nocgc_two : $!";
  close P3F or die "Cannot close $pm_nocgc_full_two : $!";
  close CG3 or die "Cannot close $cgc_nopm_two : $!";
  close C3F or die "Cannot close $cgc_nopm_full_two : $!";
} # sub close_files 


sub pmkey {
  my $frompm = shift;
  $frompm =~ m/VI  - (\d+)/;
  $volnum = $1;
  $frompm =~ m/PG  - (\d+)/;
  $pgnum = $1;
  $frompm =~ m/AU  - (\w+)/;
  $authorpm = $1;
  $keypm = $volnum . " " . $pgnum . " " . $authorpm;
    # process title, by getting rid off linebreaks and putting into single line
  if ($PMCounter{$keypm}) {
    print DBF "$PMHash{$keypm}\n";	# old
    print DBF "$frompm\n";		# current
  } # if ($PMCounter{$keypm}) 
  return $keypm;
} # sub pmkey 

sub pmid {
  my ($frompm, $keypm) = @_;
  $frompm =~ m/PMID- (\d+)\n/;
  $pmid = $1;
  $PMIDHash{$keypm} = $pmid;
} # sub pmid

sub pmtitle {
  my $frompm = shift;
  $frompm =~ m/TI  - (.*?)\n....\-/s;
  $titlepm = $1;
  @titlepm = split/\n/, $titlepm;
  $titlepm = join(" " , @titlepm);
  $titlepm =~ s/  //g;
  return $titlepm;
} # sub pmtitle 

sub cgckey {
  $cgcnumber = $stuff[0];
  $authors = $stuff[2];
  $title = $stuff[3];
  $journal = $stuff[4];
  $volcgc = $stuff[5];
  $volcgc =~ s/[^\d]//g;
  $pagescgc = $stuff[6];
  $pagescgc =~ m/^.*?(\d+)/;
  $pgcgc = $1;
  $authors =~ m/^\w+?\. (\w+)/;
  $authorcgc = $1;
  $keycgc = $volcgc . " " . $pgcgc . " " . $authorcgc;
  if ($CGCCounter{$keycgc}) {
    print DBF "$CGCHash{$keycgc}\n";	# old
    print DBF "$fromcgc\n";		# current
  } # if ($CGCCounter{$keycgc}) 
  $CGCNumberHash{$keycgc} = $cgcnumber;
} # sub cgckey 

sub cgctitle {
  $titlecgc = $stuff[3];
} # sub cgctitle 
