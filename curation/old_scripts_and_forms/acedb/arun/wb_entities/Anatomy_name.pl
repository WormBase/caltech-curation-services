#!/usr/bin/perl
use Ace;

my @classes = qw( Anatomy_name );

print "Getting acedb connection...\n";
my $database_path = "/home3/acedb/ws/acedb";    # full path to local AceDB database; change as appropriate
my $program = "/home/acedb/bin/tace";           # full path to tace; change as appropriate
my $db = Ace->connect(-path => $database_path,  -program => $program) 
			|| die print "Connection failure: ", Ace->error;  # local database
print "Got connection!\n";

my %exclusions = ();

foreach my $class (@classes) {
	print "Getting class \'$class\'\n";
    my $query = "find $class";
    my @class = $db->fetch(-query=>$query);

	# exclusions, given by Raymond
	$query = "find anatomy_name NOT (name_for_anatomy_term OR synonym_for_anatomy_term)";
	my @exc = $db->fetch(-query=>$query);
	if ($exc[0]) {
		for my $e (@exc) {
			$exclusions{$e} = 1;
		}
	}
	
    if ($class[0]) {
		my $outfile = "./known_objects/" . $class;
		open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
		foreach my $obj (@class) { 
			next if (defined($exclusions{$obj}));

			# exclusions given by Karen
			next if ($obj =~ /(hermaphrodite|male)s?$/i);
			next if ($obj =~ /^lineage name/i);
				
			print OUT "$obj\n"; 
		}
		close (OUT) or die "Cannot close $outfile : $!"; 
	}
	else {
		print "Sorry, $class not found\n";
	}
}

print "Got: @classes and stored in ./known_objects/\n\n";
