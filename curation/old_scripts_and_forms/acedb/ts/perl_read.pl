#!/usr/bin/perl

# THIS DOESN'T WORK, won't create proper objects  2009 08 20

use Ace;

my $database_path = "/home/acedb/ts";    	# full path to local AceDB ts database; change as appropriate
my $program = "/home/acedb/bin/tace";           # full path to tace; change as appropriate

# print "Connecting to database...";

# $db=Ace->connect(-host=>'aceserver.cshl.org',-port=>'2005');
# my $db = Ace->connect('sace://aceserver.cshl.org:2005') || die "Connection failure: ", Ace->error;                      # uncomment to use aceserver.cshl.org - may be slow

# my $db = Ace->connect('tace:/home/acedb/ts') || die print "Connection failure: ", Ace->error;   # local database
# this won't read into the db at all

my $db = Ace->connect(-path => $database_path,  -program => $program) || die print "Connection failure: ", Ace->error;   # local database
# this reads an object, sort of, but doesn't create an object, it creates an xref type ghost
# never gives errors even if the file is wrong

my @objects = $db->parse_file('/home/acedb/ts/persons_20090731.ace');

foreach my $object (@objects) {
  print "SOBJ $object EOBJ\n\n";
} # foreach my $object (@objects)

my $errors = Ace->error(); 
print "ERR $errors\n";

__END__

$author = $db->parse(<<END);
Person : "WBPerson1"
Status	"Valid"
First_name	 "Cecilia"
Last_name	 "Nakamura"
Standard_name	 "Cecilia Nakamura"
Full_name	 "Cecilia Nakamura"
Also_known_as	 "C Nakamura"
Laboratory	 "PS"
Address	 Street_address "WormBase"
Address	 Street_address "California Institute of Technology"
Address	 Street_address "MC 156-29"
Address	 Street_address "1200 East California Blvd."
Address	 Street_address "Pasadena, CA 91125"
Address	 Country "USA"
Address	 Institution "WormBase, Caltech, Pasadena CA, USA"
Address	 Email "cecilia@tazendra.caltech.edu"
Address	 Office_phone "(626) 395-2688"
Old_address	 2004-12-07 Email "cecilia@minerva.caltech.edu"
Supervised_by	 "WBPerson625" Research_staff 2002
Possibly_publishes_as	 "Nakamura C"
Possibly_publishes_as	 "Tomonori Nakamura"
Paper	 "WBPaper00006329"
Paper	 "WBPaper00024658"
Paper	 "WBPaper00027011"
Paper	 "WBPaper00028793"
Paper	 "WBPaper00031189"
Not_paper	 "WBPaper00028655"
Not_paper	 "WBPaper00029488"
Not_paper	 "WBPaper00030522"
Not_paper	 "WBPaper00032343"
Last_verified	 2008-09-16
END

__END__

