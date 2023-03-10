#!/usr/bin/perl -w
#
# This takes in the volume and dot volume of the wbg stuff from the expanded 
# tar.gz (not really zipped, just tar xvf to expand) from 
# http://elegans.swmed.edu/WBG/tars/   set the volume, dot volume, year, number
# of columns in longtext, and you are good to go. 
#
# read all the stuff in the p/ directory, and recursively go through it to find
# all the directories with stuff.  go through all those @directory's and get 
# the abstract.wbg files.  for each of those @file's, get the name for the 
# [wbg$vol_n.$vol_d p $page_number], open, read into $wbg variable, take out 
# all the weird html except for the &lt; and &gt; (those go out later on).  Get
# the title, print most of the stuff, get the authors (@authors) into lastname,
# firstinit format, create the brief citation by limiting the title to 70 
# characters, and follow the format (following are samples).  Get the abstract
# and write the longtext format, put in 80 column paragraphs.
#
# brief citation : first author et al (year) WBG. "title ..." (67 ....)
# Pos-1 (=skn-2 ?), a gene which shows localization of its ....
# let-858 encodes a conserved nuclear protein that is essential in ....
# Oocyte Defects Prior to Nuclear Envelope Breakdown in ceh-18(mg57) ....
#
# 2002 02 28
#
# Added Eimear's tokenizer stuff as a subroutine to better deal with labeling
# tags from her exclusion list.  2002 04 04

use strict;
use diagnostics;

# change these values for each different release:

my $vol_n = 17;
my $vol_d = 2;
my $vol_y = 2002;

my $outfile = "/home/abstracts/wbg_abstract$vol_n.$vol_d.ace";
my $folder = "/home/abstracts/PAPERS/WBG/$vol_n.$vol_d/p/";
my @stuff = </home/abstracts/PAPERS/WBG/$vol_n.$vol_d/p/*>;
my @exclusion = </home/abstracts/ACEFILES/*.out>;
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

foreach (@stuff) {
  if (-d $_) { push @directory, $_; print $_; }
} # foreach (@stuff)

foreach (@directory) {
  my @array = <$_/*>;
  foreach (@array) {
    if (-d $_) { push @directory, $_; }
    if ((-f $_) && ($_ =~ m/abstract.wbg$/)) { push @file, $_; }
  } # foreach (@array)
}


open (OUT, ">$outfile") or die "Cannot create $outfile : $!";

foreach my $file (@file) {
    %print_hash = ();        # initializes %print_hash
  my ($title, $journal, $page, $volume, $year, $brief_citation, $abstract, $type);
  my @authors;

  my $abs = $file;
  $abs =~ s/^.*\/p\///g;		# take out stuff to the /p/
  $abs =~ s/A\/abstract.wbg$//g; 	# take out the stuff after the A
  $abs =~ s/\///g;			# take out extra slashes
  $page = $abs;				# get the page
  $abs = "[wbg$vol_n.${vol_d}p" . $abs . "]";
  print "FILE : $file\n";
  open (IN, "<$file") or die "Cannot open $file : $!";
  undef $/; 				# read the whole thing
  my $wbg = <IN>;
  $wbg =~ s/&uuml;/u/g;			# take out odd html
  $wbg =~ s/&ouml;/o/g;			# take out odd html
  $wbg =~ s/&aacute;/a/g;               # take out odd html
  $wbg =~ s/&agrave;/a/g;               # take out odd html
  $wbg =~ s/&eacute;/e/g;               # take out odd html
  $wbg =~ s/&egrave;/e/g;               # take out odd html
  $wbg =~ s/&ecirc;/e/g;                # take out odd html
  $wbg =~ s/&ccedil;/c/g;               # take out odd html
  $wbg =~ s/&nbsp;/ /g;                 # take out odd html
  $wbg =~ s/&rsquo;/'/g;                # take out odd html
  $wbg =~ s/&lsquo;/'/g;                # take out odd html
  $wbg =~ s/&rdquo;/'/g;                # take out odd html
  $wbg =~ s/&ldquo;/'/g;                # take out odd html
  $wbg =~ s/&#180;/'/g;                 # take out odd html
  $wbg =~ s/&quot;/\\"/g;               # take out odd html
  $wbg =~ s/&amp;/&/g;                  # take out odd html
  $wbg =~ s/&micro;/micro/g;            # take out odd html
  $wbg =~ s/&#186;/deg/g;		# take out odd html
  $wbg =~ s/&#176;/deg/g;		# take out odd html
  $wbg =~ s/&ordm;/deg/g;		# take out odd html
  $wbg =~ s/&deg;/deg/g;		# take out odd html
  $wbg =~ s/&frac12;/1\/2/g;		# take out odd html
  $wbg =~ s/&#82\d\d;//g;		# take out odd html
  $wbg =~ s/&#9;/\n/g;			# take out odd html
  $wbg =~ s/&#151;/--/g;		# take out odd html
  $wbg =~ s/&ndash;/-/g;		# take out odd html
  $wbg =~ s/&plusmn;/+\/-/g;		# take out odd html
  $wbg =~ s/&middot;//g;		# take out odd html

  close (IN) or die "Cannot close $file : $!";

  $wbg =~ m/<WBGTITLE>(.*?)<\/WBGTITLE>/s; $title = $1;
  $title =~ s/\n+/ - /g;		# take out newlines, put in -
  $title =~ s/<.*?>//g;			# take out html
  $title =~ s/&gt;/>/g;			# take out odd html
  $title =~ s/&lt;/</g;			# take out odd html
  print OUT "Paper\t\"$abs\"\n";
  print OUT "Title\t\"$title\"\n";

  print OUT "Journal\t\"Worm Breeder's Gazette\"\n";

  print OUT "Page\t\"$page\"\n";

  print OUT "Volume\t\"$vol_n\"\t\"$vol_d\"\n";

  print OUT "Year\t\"$vol_y\"\n";

  @authors = $wbg =~ m/<WBGNAME>(.*?)<\/WBGNAME>/gs;
  foreach (@authors) { 
    $_ =~ s/<.*?>//g; 
    $_ =~ s/\n+/ /g;		# take out newlines, put in
    print OUT "Author\t\"$_\"\n"; 
  } # foreach (@authors) 

  my $author = $authors[0];
  my ($init, $last) = $author =~ m/^(\w).* (\w+)/;
  my @chars = split //, $title;
  my $brief_title = '';			# brief title (70 chars or less)

  if ( scalar(@chars) < 70 ) { $brief_title = $title; 
  } else { 
    my $i = 0;				# letter counter (want less than 70)
    my $word = '';			# word to tack on (start empty, add characters)
    while ( (scalar(@chars) > 0) && ($i < 70) ) {
					# while there's characters, and less than 70 been read
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
  print OUT "Brief_citation\t\"$last $init ($vol_y) WBG. \\\"$brief_title\\\"\"\n";
  
  print OUT "Type\t\"GAZETTE_ABSTRACT\"\n";

  $wbg =~ m/<WBGTEXT>(.*?)<\/WBGTEXT>/s; $abstract = $1;
  $abstract =~ s/<P>//g;		# take out page breaks, and put in this escape (for our use)
  $abstract =~ s/<.*?>/ /g; 		# take out html
  $abstract =~ s/\n+/ /g;		# take out newlines, put in a space
  $abstract =~ s/ +/ /g;		# replace extra spaces put in when taking out html
  my $abs_token = &tokenize($abstract);
  my @abs_words = split / /, $abs_token;
  foreach my $abs_word (@abs_words) {
    if ($comparison_hash{$abs_word}) {
      $print_hash{$abs_word} = $comparison_hash{$abs_word};
    } # if ($comparison_hash{$abs_word})
  } # foreach my $abs_word (@abs_words)
  foreach my $abs_word (sort keys %print_hash) {
    print OUT "$print_hash{$abs_word}\t\"$abs_word\"\n";
  } # foreach my $abs_word (sort keys %print_hash)
  print OUT "Abstract\t\"$abs\"\n";
  print OUT "\n";

  $abstract =~ s/\\"/"/g;		# take out the escapes for directly quoted longtext
  print OUT "LongText\t:\t\"$abs\"\n";
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
#       print "C : $char\n";
      while ( (scalar(@chars) > 0) && ($char ne ' ') && ($char ne "") ) {
					# READ WORD
					# while not a space nor newline and still chars
        $word .= $char; $i++;		# build word, add to counter (less than $maxcolumns)
        $wordcount++;			# add to wordcount
        $char = shift @chars;		# read a character to check if space
        if ($char eq "") { 		# if it's a newline
          if ($i > $maxcolumns) { $word = "\n$word"; $char = ''; $i = $wordcount; }
					# if we're over the max, put a newline before the word,
					# reset the char, reset $i to the $wordcount
          else { $word .= "\n"; $char = ''; $i = 0; }
					# if we're not over the wordcount, add a newline, reset the
					# char, reset $i to 0 (a whole new line)
        } # if ($char eq "") 
#         print "D : $i : -=${char}=- : $word\n";
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
    if ($char eq "") { $i = 0; $char = shift @chars; $word .= $char; $i++; }
					# if we get a newline divider, reset the line counter, 
					# get a new character, add it, and count it
    if ($wordcount > $maxcolumns) { $wordcount = 0; }
					# if a word is longer than allowed, pretend it's 0
    unless (scalar(@chars) == 0) { 	# if we're still going and need to deal with the last word
      $newword .= "\n"; 		# add a newline because this line is done
      $i = $wordcount + 1;		# putting last word on next line, so pass the amount of chars
    } else {				# if we're completely done and need to deal with the last word
      if ($i > $maxcolumns) { $newword .= "\n$word"; }	
					# more than allowed ($maxcolumns), put newline first
      else { $newword .= "$word"; }	# fits, put it before newline
    } # else # unless (scalar(@chars) == 0)
  } # while (scalar(@chars) > 0)

  $newword =~ s/&gt;/>/g;		# take out odd html
  $newword =~ s/&lt;/</g;		# take out odd html
  print OUT $newword . "\n";		# output the value
  print OUT "***LongTextEnd***\n";


  print OUT "\n";
} # foreach my $file (@file)

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
        $line =~ s/'/_APOS_/g;

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










