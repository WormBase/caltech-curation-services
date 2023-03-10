#! /usr/bin/perl -w


$|=1;  # forces output buffer to flush after every print statement!

# path to citace
my $infile = "lin-15.ace";
&readExclusionList($infile);


sub readExclusionList{
    my ($ex) = @_;
    open (IN, "<$ex") or die": $!";
    undef $/; 				# read the whole thing
    my $wholefile = <IN>;
    close(IN);
    $/ = "\n";
    @cgc = split(/\n/, $wholefile);
    open (OUT, ">fixlin-15.ace");
    for (@cgc){
	print OUT "$_\n";
	print OUT "-D Gene\t\"WBGene00003004\"\n";
	print OUT "Gene\t\"WBGene00023498\"\n";
	print OUT "Gene\t\"WBGene00023497\"\n\n";
    }
    close (OUT);
}
