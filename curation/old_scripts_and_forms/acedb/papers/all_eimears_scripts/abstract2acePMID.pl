#!/usr/bin/perl -w
#
##### abstract2acePMID.pl ##########
#
# This program parses PMID citation info from Juancarlos's PostGres db and converts them to .ace format. 
# Written by Eimear Kenny @ Wormbase, Jan 2003
# 
# INPUT FILE : /home/abstracts/PAPERS/PMID/reffile
#                                                                             
# OUTPUT FILE: /home/abstracts/pmid_0208.ace
#                                                                                
#
#

# Please enter the list of acedb groups to crosscheck the abstracts with:

my @list = qw (Allele            
	       Cell              
	       Cell_group
	       Life_stage
	       Strain
	       Transgene
	       Locus
	       );

#################
# PROGRAM BEGINS
#################


# Global Variables

my $new = "/home/eimear/abstracts/PAPERS/PMID/tmp";
my $file = "/home/eimear/abstracts/PAPERS/PMID/reffile";
my $outfile = "/home/eimear/abstracts/pmid_030725.ace";
foreach $list (@list){                 # the @list array is specified in the comment section above
    push @exclusion, </home/eimear/abstracts/ACEDUMPS/$list.dump.out>;
}
my @directory;
my @file;
my %comparison_hash;			# hash of stuff to compare key : term, value : type
my %print_hash;				# hash of stuff to print




foreach my $file_name (@exclusion) { 
  my ($file_type) = ($file_name =~ m/.*\/(\w*).*$/);
   print "FILETYPE: $file_type\n";
   open (EXC, "<$file_name") or die "Cannot open $file_name : $!"; 
   while (<EXC>) {
     chomp;
     $comparison_hash{$_} = $file_type;
   } # while (<EXC>)
   close (EXC) or die "Cannot close $file_name : $!";
 } # foreach (@exclusion) 


open (OUT, ">$outfile") or die "Cannot create $outfile : $!";

%print_hash = ();        # initializes %print_hash

my $abs = $file;
print "FILE : $file\n";
open (IN, "<$file") or die "Cannot open $file : $!";
undef $/; 				# read the whole thing
my $wholefile = <IN>;
close (IN) or die "Cannot close $file : $!";
$/ = "\n";

@cgc = split(/\n/, $wholefile);

# new 030528: read in list of new pmids
my %newpmid;
open (NEW, "<$new") or die "Cannot open $new : $!";
while (my $line = <NEW>){
    (my $pmed) = $line =~ /(pmid\d+)\n/;
    $newpmid{$pmed}++;
    }
close (NEW) or die "Cannot close $new : $!";

CGC:foreach $cgc (@cgc){
# tests on PMID files to ensure there is no odd lines and that they all contain key, title and author info

    @tmp = ();
    if ($cgc =~ /"( \})? ,.+\t/) {print "WARNING: $key has funny looking lines!\n";} #"
	$cgc =~ s/"( \})? ,.+\t/\t/g; #"
	($key, $title, $author, $journal, $volume, $page, $year, $abstract) = split /\t/, $cgc;
	next CGC unless $newpmid{$key}; # only process if on list of new pmids
	push @tmp, ($key, $title, $author);
	for (@tmp){
	    if (length($_) == 0){
		print "WARN: Can't use $key as it is missing either pmid, author or title info.\n";
		next CGC;
	    }
	}
    
## END TEST

	print OUT "Paper\t\"\[$key\]\"\n";
	$title =~ s/""/\\"/g; # "
	print OUT "Title\t\"$title\"\n";
	print OUT "Journal\t\"$journal\"\n";

	if ((length($page) > 0) && ($page !~ /NULL/)) {                 # splits page range by hyphen (if the hyphen is there) and 
	    if ($page =~ /-/){             # prints out each number separated by a tab in ace file
		@pages = split (/-/, $page);	
		print OUT "Page";
		foreach (@pages){print OUT "\t\"$_\""}
		print OUT "\n";
	    } else {print OUT "Page\t\"$page\"\n"}
	}
	print OUT "Volume\t\"$volume\"\n" unless ((length($volume) == 0) || ($volume =~ /NULL/));
    
	print OUT "Year\t\"$year\"\n" unless ((length($year) == 0) || ($year =~ /NULL/));
    
	@authors = split(/\/\//, $author);
	foreach (@authors) { 
	    $_ =~ s/,//g;		# take out commas
	    $_ =~ s/\.//g;      # remove full stops - added 030218
	    $_ =~ s/\s+/ /g;   # squeezes multiple spaces down to one - added 030218
	    $_ =~ s/\n//g;   # gets rid of newline - added 030218
	    print OUT "Author\t\"$_\"\n"; 
	} 
	
	$aut = $authors[0];
	my @chars = split //, $title;
	my $brief_title = '';			# brief title (70 chars or less)
	
	if ( scalar(@chars) < 70 ) { 
	    $brief_title = $title; 
	} else { 
	    my $i = 0;				# letter counter (want less than 70)
	    my $word = '';			# word to tack on (start empty, add characters)
	    while ( (scalar(@chars) > 0) && ($i < 70) ) { # while there's characters, and less than 70 been read
		$brief_title .= $word;		# add the word, because still good (first time empty)
		$word = '';			# clear word for next time new word is used
		my $char = shift @chars;		# read a character to start / restart check
		while ( (scalar(@chars) > 0) && ($char ne ' ') ) {	# while not a space and still chars
		    $word .= $char; $i++;		# build word, add to counter (less than 70)
		    $char = shift @chars;		# read a character to check if space
		} # while ($_ ne '')		# if it's a space, exit loop
		$word .= ' ';			# add a space at the end of the word
	    } # while ( (scalar(@chars) > 0) && ($i < 70) )
	    $brief_title = $brief_title . "....";
	}
	
	print OUT "Brief_citation\t\"".$aut unless (length($aut) == 0);
        print OUT  " (".$year.") " unless (length($year) == 0);
        print OUT $journal." \\\"".$brief_title."\\\"\"\n";
	if ((length($abstract) > 0) && ($abstract !~ /NULL/)){
	    my $abs_token = &tokenize($abstract);
	    my @abs_words = split / /, $abs_token;
	    %print_hash = ();
	    foreach my $abs_word (@abs_words) {
		if ($comparison_hash{$abs_word}) {
		    $print_hash{$abs_word} = $comparison_hash{$abs_word};
		} # if ($comparison_hash{$abs_word})
	    } # foreach my $abs_word (@abs_words)
	    
	    
	    foreach my $abs_word (sort keys %print_hash) {
		print OUT "$print_hash{$abs_word}\t\"$abs_word\"\tInferred_automatically\t\"abstract2acePMID.pl script, 20030725 - Eimear Kenny\"\n";
	    } # foreach my $abs_word (sort keys %print_hash)
	    
	    
	    print OUT "Abstract\t\"\[$key\]\"\n";
	    print OUT "\n";
	    
	    $abstract =~ s/\\"/"/g;		# take out the escapes for directly quoted longtext
	    @chars = split //, $abstract;		# split into characters
	    
	    my $newword;				# the whole thing we're reading
	    my $i = 0;				# counter for newlines
	    my $maxcolumns = 80;			# characters per line to break at
	    my $word = '';			# word we're reading, as it's read it increases
	    my $char = '';			# the char we're reading to make the word
	    my $wordcount = 0;			# the length of the word, for the case that a word goes over
	    
	    # the maxcolumn break, we write the word on the next line
	    # and start the $i count at the lenght of the word added below
	    
	    while (scalar(@chars) > 0) {		# while there are characters that haven't been read
		while ( (scalar(@chars) > 0) && ($i < $maxcolumns) && ($char ne "") ) {
		    # READ LINE
		    # while there's characters, less than $maxcolumns been read,
		    # and we've not read a newline
		    $newword .= $word;		# add the word, because still good (first time empty)
		    # must go before, else it will print the word that overruns
		    # the $i limit
		    $word = '';			# clear word for next time new word is used
		    $wordcount = 0;			# empty the wordcount since word has been reinitialized
		    $char = shift @chars;		# read a character to start / restart check
		    while ( (scalar(@chars) > 0) && ($char ne ' ') && ($char ne "") ) {
			# READ WORD
			# while not a space nor newline and still chars
			$word .= $char; $i++;		# build word, add to counter (less than $maxcolumns)
			$wordcount++;			# add to wordcount
			$char = shift @chars;		# read a character to check if space
			if ($char eq "") { 		# if it's a newline
			    if ($i > $maxcolumns) { 
				$word = "\n$word"; $char = ''; $i = $wordcount; 
			    }
			    # if we're over the max, put a newline before the word,
			    # reset the char, reset $i to the $wordcount
			    else { 
				$word .= "\n"; $char = ''; $i = 0; 
			    }
			    # if we're not over the wordcount, add a newline, reset the
			    # char, reset $i to 0 (a whole new line)
			} # if ($char eq "") 
		    } # while ( (scalar(@chars) > 0) && ($char ne ' ') && ($char ne "") )
		    # if it's a space, newline, or done with chars : exit loop
		    # END READ WORD
		    unless ($char eq "") {		# unless we read a newline (before the while loop above)
			$word .= $char; $i++;		# add the dividing character, either the space checked for
			# or the last character that made scalar(@chars) == 0. count it
			# but don't add or count the newline divider
		    } # unless ($char eq "") 
		} # while ( (scalar(@chars) > 0) && ($i < $maxcolumns) )
		# END READ LINE
		if ($char eq "") { 
		    $i = 0; $char = shift @chars; $word .= $char; $i++;
		}
		# if we get a newline divider, reset the line counter, 
		# get a new character, add it, and count it
		if ($wordcount > $maxcolumns) { 
		    $wordcount = 0; 
		}
		# if a word is longer than allowed, pretend it's 0
		unless (scalar(@chars) == 0) { 	# if we're still going and need to deal with the last word
		    $newword .= "\n"; 		# add a newline because this line is done
		    $i = $wordcount + 1;		# putting last word on next line, so pass the amount of chars
		} else {				# if we're completely done and need to deal with the last word
		    if ($i > $maxcolumns) { 
			$newword .= "\n$word"; 
		    }	
		    # more than allowed ($maxcolumns), put newline first
		    else { 
			$newword .= "$word"; 
		    }	# fits, put it before newline
		} # else 
		$newword =~ s/""/\\"/g unless (length($newword) == 0);#"
		} # while (scalar(@chars) > 0)
	    print OUT "LongText\t:\t\"\[$key\]\"\n";
	    print OUT $newword . "\n";		# output the value
	    print OUT "***LongTextEnd***\n";
	}
	print OUT "\n";
    }
close (OUT) or die "Cannot close $outfile : $!";
    

sub tokenize {
    my $line = shift;
    $line =~ s/\b([A-Z])\. /$1 /g;	# gets rid of periods after single capital 
					# letters ( M. A. Young -> M A Young)
    $line =~ s/(ca)\. (\d+)/$1 $2/g;	# EXCEPTION; protect the "ca. <NUMBER>" notation!!!
    $line =~ s/e\.?g\.?/eg/g;		# gets rid of alot of extraneous periods within sentences ...                             
    $line =~ s/i\.?e\.?/ie/g;	
    $line =~ s/([Aa]l)\./$1/g;
  $line =~ s/([Ee]tc)\./$1/g;  
  $line =~ s/([Ee]x)\./$1/g;
  $line =~ s/([Vv]s)\./$1/g;
  $line =~ s/([Nn]o)\./$1/g;
  $line =~ s/([Vv]ol)\./$1/g;
  $line =~ s/([Ff]igs?)\./$1/g;
  $line =~ s/([Ss]t)\./$1/g;
  $line =~ s/([Cc]o)\./$1/g;
  $line =~ s/([Dd]r)\./$1/g;

  ### now get rid of any newline characters
  $line =~ s/\n/ /g;			# replaces new line character with a space
  

  ###### "protect" instances of periods that do not mark the end of a sentence by 
  # substituting an underscore for the following space i.e. ". " becomes "._" ######
  ##general rule..

  $line =~ s/\. ([a-z])/\._$1/g;	# protect any period followed by a space then a small letter

  ##special instances not caught by general rules...

  $line =~ s/\._([a-z]{3}-\d+)/\. $1/g;		# EXCEPTION; unprotect those sentences that begin 
						# with a small letter ie begin with a gene name!!!
  $line =~ s/ (\w+[A-Z]{2})\._/ $1\. /g;	# EXCEPTION; unprotect those sentences that end with a capitalized abreviation, eg RNA!!!

  #####reintroduce newline characters at ends of sentences only where there #####
  #####is a period followed by a space.########

  $line =~ s/(\]|\)|\d|[a-zA-Z])(\.|\?|!) /$1$2\n/g;	# reintroduces newlines
  #####reintroduce spaces following periods that do not mark the end of a #####
  #####sentence#####
  $line =~ s/\._([a-z])/\. $1/g;	# unprotects any period followed by a space and an small letter

  ##rules for converting abreviations to whole words....

	$line =~ s/([\w]+)'[Ll][Ll]/$1 will/g;          # eg i'll turns into i will
	$line =~ s/([\w]+)'[Rr][Ee]/$1 are/g;           # eg you're turns into you are
	$line =~ s/([\w]+)'[Vv][Ee]/$1 have/g;          # eg i've turns into i have
	$line =~ s/ ([Ww])on't/ $1ill not/g;            # eg won't turns into will not
	$line =~ s/ ([Dd])on't/ $1oes not/g;            # eg don't turns into does not
	$line =~ s/ ([Hh])aven't/ $1ave not/g;          # eg haven't turns into have not
	$line =~ s/ ([Cc])an't/ $1an not/g;             # eg can't turns into can not
	$line =~ s/ ([Cc])annot/ $1an not/g;            # eg cannot turns into can not
	$line =~ s/ ([Ss])houldn't/ $1hould not/g;      # eg shouldn't turns into should not
	$line =~ s/ ([Cc])ouldn't/ $1ould not/g;        # eg couldn't turns into could not
	$line =~ s/ ([Ww])ouldn't/ $1ould not/g;        # eg wouldn't turns into would not
	$line =~ s/ ([Mm])ayn't/ $1ay not/g;            # eg mayn't turns into may not
	$line =~ s/ ([Mm])ightn't/ $1ight not/g;        # eg mightn't turns into might not
	$line =~ s/ [Tt]is/ it is/g;                    # eg tis turns into it is
	$line =~ s/ [Tt]was/ it was/g;                  # eg twas turns into it was
	$line =~ s/ (\w+)'[sS]/ $1 is/g;                # eg it's turns into it is
        $line =~ s/ (\w+)'[dD]/ $1 would/g;             # eg it'd turns into it would
	$line =~ s/ (\w+)'[mM]/ $1 am/g;                # eg i'm turns into i am

  ##rules for replacing perl metacharacters with literal descriptions in text ...

	$line =~ s/\"/ DQ /g;                     # turns " into DQ
	$line =~ s/\</ LT /g;                     # turns < into LT
	$line =~ s/\>/ GT /g;                     # turns > into GT
	$line =~ s/\&/ AND /g;                    # turns & into AND
	$line =~ s/\@/ AT /g;                     # turns @ into AT
	$line =~ s/\./_PERIOD_/g;                 # including turning all punctuation into literals .....
	$line =~ s/,/_COMMA_/g;
	$line =~ s/;/_SEMICOLON_/g;
	$line =~ s/:/_COLON_/g;
	$line =~ s/\[/_OPENSB_/g;
	$line =~ s/\]/_CLOSESB_/g;
	$line =~ s/\(/_OPENRB_/g;
        $line =~ s/\)/_CLOSERB_/g;
	$line =~ s/\{/_OPENCB_/g;
	$line =~ s/\}/_CLOSECB_/g;
	$line =~ s/-/_HYPHEN_/g;
	$line =~ s/\n/_NLC_/g;
	$line =~ s/ /_SPACE_/g;
        $line =~ s/'/_APOS_/g; #'

  ##### now get fid of any non-literal characters...
	

	$line =~ s/\W//g;

  #### now replace all essential puncuation ...
	
	
	$line =~ s/_PERIOD_/\./g;
	$line =~ s/_COMMA_/,/g;
	$line =~ s/_SEMICOLON_/;/g;
	$line =~ s/_COLON_/:/g;
	$line =~ s/_OPENSB_/\[/g;
	$line =~ s/_CLOSESB_/\]/g;
        $line =~ s/_OPENRB_/\(/g;
	$line =~ s/_CLOSERB_/\)/g;
        $line =~ s/_OPENCB_/\{/g;
	$line =~ s/_CLOSECB_/\}/g;
	$line =~ s/_HYPHEN_/-/g;
	$line =~ s/_SPACE_/ /g;
	$line =~ s/_NLC_/\n/g;
        $line =~ s/_APOS_/'/g;

  ##rules for tokenizing punctuation marks in text (required by brill tagger)...

        $line =~ s/([\)\:;,\.'\(\[\{\}\]])/ $1 /g;     # places space in front of ();:,.[]{}

  #####finally, clean up any extra spaces####
	
        $line =~ s/\t/ /g;                           #gets rid of tabs
        $line =~ s/  +/ /g;                          #gets rid of extra space
	$line =~ s/\n\s+/\n/g;                       #gets rid of space after newline   
  $line =~ s/ \. /\./g;			# take out the spaces around a space period space (cell)
  $line =~ s/ : : /::/g;		# take out the spaces around a space colon space colon space 
					# (transgene)
  $line =~ s/ ' /' /g;
  return $line;
} # sub tokenize
