#!/usr/bin/perl -w

open (IN, "<listcgcmed") || die "can't open $!";	#Open input file
undef $/; 				# read the whole thing
my $wholefile = <IN>;
close (IN);
$/ = "\n";

@cgc = split(/\n\n/, $wholefile);

open (OUT, ">correctionsforWS119.ace") || die "can't open $!";#Open output file
for (@cgc){
    @lines = split /\n/, $_;
    print OUT "-D Paper [" . $lines[1] . "]\n\n";
    print OUT "-D Longtext [" . $lines[1] . "]\n\n";
}
close (OUT);
