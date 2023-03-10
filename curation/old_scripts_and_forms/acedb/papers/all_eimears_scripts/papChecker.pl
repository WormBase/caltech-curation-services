#! /usr/bin/perl -w

#$wb = "/home/eimear/abstracts/WBAbs"; 
$pap = "/home/eimear/abstracts/WBPapers/Paper.dump"; 
$cgc_file = "/home/eimear/abstracts/CGCbigfile"; 

#parse pap abs file:
open (IN, "<$pap") or die "Cannot open $pap: $!";
undef $/;
my $papfile = <IN>;
close (IN) or die "Cannot close $pap : $!";
$/ = "\n";
@pap = split(/\[/, $papfile);

for (@pap){
    next if ($_ !~ /^cgc\d+]/);
#if ($_ !~ /Reference/)
    ($cgc_no) = $_ =~ /\[cgc(\d+)\]/;
$CGC{$cgc_no}++;
}


for (sort keys %CGC){print "KEY: $_\n"}

open (IN2, "<$cgc_file") or die "Cannot open $cgc_file: $!";
print "loading $cgc_file ....\n";
undef $/;
my $wholefile = <IN2>;
close (IN2) or die "Cannot close $cgc_file : $!";
$/ = "\n";
@cgc = split(/\s+--+\s*\n/, $wholefile);
open (OUT, ">outfile") or die "Cannot open outfile: $!";
LINE: foreach (@cgc){
    $_ =~ m/Key:\s+(\d+)/s; $abs = $1;
	unless (defined $CGC{$abs}) {
	    if ($_ =~ /Abstract: \w+/){
		$_ =~ m/Abstract: ((.+)\n?)+/xs; $abstract = $1;
		$abstract =~ s/\n+/ /g;		# take out newlines, put in a space
		$abstract =~ s/ +/ /g;		# replace extra spaces put in when taking out html
		print OUT "Paper \[cgc$abs\]\n";
		print OUT "Abstract \"\[cgc$abs\]\"\n";
		print OUT "\n";
	    } else {next LINE}   
	    printFormat($abstract);
	}

}
close(OUT);
sub printFormat{
    my $a = shift;
    $a =~ s/\\"/"/g;		# take out the escapes for directly quoted longtext
    @chars = split //, $a;		# split into characters
   
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
    } # while (scalar(@chars) > 0)
    
    print OUT "LongText\t:\t\"\[cgc$abs\]\"\n";
    print OUT $newword . "\n";		# output the value
    print OUT "***LongTextEnd***\n";
    
    
    print OUT "\n";
    
}

