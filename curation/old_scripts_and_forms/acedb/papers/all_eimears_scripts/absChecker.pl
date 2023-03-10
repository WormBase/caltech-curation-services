#! /usr/bin/perl -w

use HTTP::Request;
use LWP::UserAgent;
use Ace;

my (%CGC, %Paper);
my $j = 0; #counter
my $dateShort;

# url of current cgc approved gene names
my $url = "http://biosci.umn.edu/CGC/Bibliography/gophbib";
# path to citace
my $path = "/home/acedb/citace";

print "Reading CGC bibliography .....\n";
&readCGCAbstracts($url);
print "done\n";
&readLongtext($path);
&updateAbstracts(\%CGC,\%Paper);
my $count_CGC = scalar(keys %CGC);
my $count_WB = scalar(keys %Paper);
print "\n\nThere are $count_CGC cgc abstracts, $count_WB of which were already in Wormbase.\n";
print "Therefore, $j abstracts were added to Wormbase\n\n";

sub readLongtext{
    my $path = shift;

    print "Opening the database....";
    my $db = Ace->connect(-path => $path);
    print "done\n";

    @papers = $db->fetch(Paper=>'*');
    foreach $paper (@papers){
	next unless ($paper->Abstract) && ($paper =~ /cgc/);
	my ($num) = $paper =~ /\[cgc(\d+)\]/;
	$Paper{$num}++;
    }
    return %Paper;

}

sub readCGCAbstracts{

    my $u = shift;
    
#    print "Reading CGC bibliography ......";
    my $ua = LWP::UserAgent->new(timeout => 30); #instantiates a new user agent
    my $request = HTTP::Request->new(GET => $u); #grabs url
    my $response = $ua->request($request);       #checks url, dies if not valid.
    die "Error while getting ", $response->request->uri," -- ", $response->status_line, "\nAborting" unless $response-> is_success;
#    print "done\n";

    my @cgc = split /\s+--+\s*\n/, $response->content;    #splits by line
    foreach (@cgc){
	my ($abs, $abstract) = "";             # initializes scalars
	($abs) = $_ =~ m/Key:\s+(\d+)/s;
#	$i++;
	if ($_ =~ /Abstract: \w+/){
	    ($abstract) = $_ =~ m/Abstract: ((.+)\n?)+/xs;
	    $abstract =~ s/\n+/ /g;		# take out newlines, put in a space
	    $abstract =~ s/ +/ /g;		# replace extra spaces put in when taking out html
	    $CGC{$abs} = $abstract;
	}
    }
    return %CGC;                               #returns hash
}


# check for incomplete abstracts:
#open (IN3, "<$wb") or die "Cannot open $wb: $!";
#print "loading $wb ....\n";
#undef $/;
#my $w = <IN3>;
#close (IN3) or die "Cannot close $wb : $!";
#$/ = "\n";
#@c = split(/LongText : /, $w);
#LINE: foreach (@c){
#    next unless $_ =~ /\[cgc/;
#    ($c_no) = $_ =~ /\[(cgc\d+)\]/;
#    $C{$c_no}++ if $_ !~ /\.(\n)+\"/;    
#}

#$j = 0;
#open (OUT2, ">incomplete_abstracts.ace") or die "Cannot open incomplete_abstracts.ace: $!";
#print OUT2 "//List of incomplete abstracts\n";
#foreach (sort {$b cmp $a} keys %C){
#    $j++;
#    print OUT2 "$_\n";
#}
#close(OUT2);
#print "There are $j incomplete abstracts!\n";

#for (sort keys %CGC){print "KEY: $_\n"}

sub updateAbstracts{
    my ($CGC, $WB) = @_;
    
    &getDate();
    open (OUT, ">missing_abstracts_$dateShort.ace") or die "Cannot open missing_abstracts_$dateShort.ace: $!";

  LINE: foreach (keys %$CGC){
      next LINE if (exists $$WB{$_});
      $j++;
      print OUT "Paper \[cgc$_\]\n";
      print OUT "Abstract \"\[cgc$_\]\"\n";
      print OUT "\n";
      &printFormat($$CGC{$_}, $_);
  }
close(OUT);
    return $j;
}

sub printFormat{
    my ($a, $abs) = @_;
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

sub getDate{
    my $time_zone = 0;
    my $time = time() + ($time_zone * 3600);
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time);
    $year += ($year < 90) ? 2000 : 1900;
    $dateShort = sprintf("%04d-%02d-%02d",$year,$mon+1,$mday);
    return $dateShort;
}
