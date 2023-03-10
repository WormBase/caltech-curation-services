#! /usr/bin/perl -w

use Ace;

$|=1;  # forces output buffer to flush after every print statement!

my (%Paper);
my $dateShort;

# path to citace
my $path = "/home2/eimear/acedb/Citace";
my $excl_file = "exclusion_genes.out";
&getDate;
&readCitaceGenes($path);
&readExclusionList($excl_file, \%Paper);

sub readCitaceGenes{
    my $path = shift;

    print "Opening the database....";
    my $db = Ace->connect(-path => $path);
    print "done\n";

    @papers = $db->fetch(Paper=>'*');
    foreach $paper (@papers){
	next unless ($paper->Locus);
	@locus = $paper->Locus;
	my ($num) = $paper =~ /\[(\w+\d+)\]/;
	$Paper{$num} = [ @locus ];
    }
    return %Paper;
}



sub readExclusionList{
    my ($ex, $Pap) = @_;
    &getDate;
    open (IN, "<$ex") or die": $!";
    undef $/; 				# read the whole thing
    my $wholefile = <IN>;
    close(IN);
    $/ = "\n";
    @cgc = split(/\n/, $wholefile);
    open (OUT, ">exclude_genes_$dateShort.ace");
    for (@cgc){
	my ($pap,$gene) = (split /\t/, $_);
	if ($$Pap{$pap}){
	    if ($$Pap{$pap}[$gene]){
		print OUT "Paper [$pap]\n";
		print OUT "-D Locus \"$gene\"\n\n";
		
	    }
	}
	
    }
    close (OUT);
}

sub getDate{
    my $time_zone = 0;
    my $time = time() + ($time_zone * 3600);
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time);
    $year += ($year < 90) ? 2000 : 1900;
    $dateShort = sprintf("%04d-%02d-%02d",$year,$mon+1,$mday);
    return $dateShort;
}
