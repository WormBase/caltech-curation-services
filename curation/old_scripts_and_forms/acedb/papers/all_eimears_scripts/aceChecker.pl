#!/usr/bin/perl -w

#-------------------Print out the purpose of the script-------------
#You should change to words so that the purpose of the script
#will appear when you run it.

print "-*-------------*--------------*--------------*----------\n\n";
print "This program checks the object values in the new paper objects\n";
print "to check whether they exist in Wormbase.\n";
print "-*-------------*--------------*--------------*----------\n\n";


#------------------Make dictionaries------------------------------
#This section makes a dictionary for each class of data you want to check. 

my @all_classes = qw(
		   Rearrangement
 		   );



for $file (@all_classes){
    $i = 1;
    print "Make $file dictionary ...";
#    @locus = MakeDictionary ("/home/temp/abstracts/ACEDUMPS/$_.dump");
    open (FILE, "</home/temp/abstracts/ACEDUMPS/$file.dump") || die "Cannot open $file : $!";
    while (<FILE>) {
	chomp;
	s/\t//;
	$Hash{$file}{$_} = $_;
	$i++;
    }
    print "There are $i terms in $file!\n";
}
print "Done.\n";

#-----------Dictionaries made, now check .ace files--------------
#Here the script asks users to enter the name of input files and output files.

print "What .ace file do you want to check? ";
chomp($Ace_name=<stdin>);
print "What do you want to call the output file? ";
chomp($Out_name=<stdin>);

print "Start checking ... \n\n";
open (IN, "$Ace_name") || die "can't open $!";	#Open input file
open (OUT, ">$Out_name") || die "can't open $!";#Open output file
$l=1;
while ($Line=<IN>) { # Read another line from input file.
    $word[0] = ""; $word[1] = "";
    $l++; # Remember which line the script is working on.
    chomp ($Line);
	@word = split ('"', $Line);
	$length = @word;
	if ($length >= 2) { # Means there are two words in the line.
	    @w = split (' ', $word[0]);
	    $word[0] = $w[0];  #First word extracted, should be tag
	    $word[1] = "\"$word[1]\"";
	    $word[1] =~ s/"//g; #"	    
	    if ($word[0] =~ /Paper/){
		$tmp = $word[1];
		if ($word[1] !~ /WBPaper\d{8}/){
		    print OUT "PAPER: In line $l of $Ace_name, in $tmp the $word[0] tag value, $word[1] is a SUSPECT paper name, please check\n";
		}
	    }
	    if ($word[0] =~ /Author/){
		if ((length($word[1]) > 40) || (length($word[1]) < 5) || ($word[1] !~ /\s+/) || ($word[1] =~ /\s\s+/)){
#		    print OUT "AUTHOR: In line $l of $Ace_name, in $tmp the $word[0] tag value, $word[1] is a SUSPECT author name, please check\n";
		    print OUT "AUTHOR: $tmp : $word[1] is a SUSPECT\n";
		}
		$test = $word[1];
		$test =~ s/[\n\s\-\']//g;
		print OUT "AUTHOR: $tmp : $word[1] contains non word characters.\n" if $test =~ /[\W]/;
	    }
	    if ($word[0] =~ /Abstract/){
		if ($word[1] !~ /WBPaper[0-9]+/){
		    print OUT "Abstract: In line $l of $Ace_name, in $tmp the $word[0] tag value, $word[1] is a SUSPECT paper name, please check\n";
		}
	    }
	    $tag = "";
	    for my $tag (sort keys %Hash ){
 		if ($word[0] =~ /$tag/){
		    unless (defined $Hash{$tag}{$word[1]}){
			print OUT "In line $l of $Ace_name, in $tmp the $word[0] tag value, $word[1] DOES NOT exist in Wormbase\n";
		    }		
		}
	    } 
	}  
}	


close (IN);
close (OUT);
print "\n";
print "Totally $l lines read. Thank you for using aceChecker!\n";
