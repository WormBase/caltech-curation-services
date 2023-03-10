#!/usr/bin/perl

use Ace;

my @classes = qw( Variation Transgene Clone Rearrangement Strain );

print "Getting acedb connection...\n";
my $database_path = "/home3/acedb/ws/acedb";    # full path to local AceDB database; change as appropriate
my $program = "/home/acedb/bin/tace";           # full path to tace; change as appropriate
my $db = Ace->connect(-path => $database_path,  -program => $program) || die print "Connection failure: ", Ace->error;  # local database
print "Got connection!\n";

foreach my $class (@classes) {
	print "Getting class \'$class\'\n";
    my $query = "find $class";
    my @class = $db->fetch(-query=>$query);
    if ($class[0]) {
		my $outfile = "./known_objects/" . $class;
		open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
		foreach my $obj (@class) { print OUT "$obj\n"; }
		close (OUT) or die "Cannot close $outfile : $!"; 
	}
	else {
		print "Sorry, $class not found\n";
	}
} # foreach my $class (@classes)
print "Got: @classes and stored in ./known_objects/\n\n";
