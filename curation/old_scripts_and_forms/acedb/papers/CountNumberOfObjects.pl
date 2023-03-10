#! /usr/bin/perl -w

print "What file would you like to check? ";
chomp($infile = <STDIN>);

open (IN, "<$infile") or die "Cannot open $infile: $!";
print "loading $infile ....\n";
undef $/;
my $wholefile = <IN>;
close (IN) or die "Cannot close $infile : $!";
$/ = "\n";
@path = split (/\//, $infile);
$filename = pop (@path);
@array = split (/Paper\t/, $wholefile);
$papercount = scalar @array - 1;
$i = 0;
for (@array){if ($_ =~ /LongText/s){$i++}}
$total = $papercount + $i;
$date = localtime;
print "### Message for $filename on $date:\n";
print "In the file $filename, there are $papercount paper objects,\n";
print "$i longtext objects and a total number of $total objects.\n";
print "##### END MESSAGE\n\n";

open (OUT, ">>MessageLog") or die "Cannot open MessageLog: $!";
print OUT "### Message for $filename on $date:\n";
print OUT "In the file $filename, there are $papercount paper objects,\n";
print OUT "$i longtext objects and a total number of $total objects.\n";
print OUT "##### END MESSAGE\n\n";
close (OUT) or die "Cannot close MessageLog: $!";
