#!/usr/bin/perl -w

use Ace;


######### WORMBASE
#use constant HOST => $ENV{ACEDB_HOST} || 'www.wormbase.org';
#use constant PORT => $ENV{ACEDB_PORT} || 2007;
#print "Opening the database....";
#my $db = Ace->connect(-host=>HOST,-port=>PORT) || die "Connection failure: ",Ace->error;
#print "done.\n";


######### ACEDB

#print "Opening the database....";
#my $db = Ace->connect(-path => '/home/eimear/acedb/WS_current');
#print "done\n";

print "\n\nWould you like to connect to [W]ormbase or [A]CeDB? ";
my $ans = <STDIN>;

my $db = "";
if ($ans =~ /[Ww]/){
############# WORMBASE
    use constant HOST => $ENV{ACEDB_HOST} || 'aceserver.cshl.org';
    use constant PORT => $ENV{ACEDB_PORT} || 2005;
    
    print "Opening the database....";
    $db = Ace->connect(-host=>HOST,-port=>PORT) || die "Connection failure: ",Ace->error;
    print "done.\n";
    } elsif ($ans =~ /[Aa]/){
 
######### ACEDB
# note: when wormbase server is down or super slow, you can use your local
# version of acedb ( as long as you have giface installed) by pointing this to 
# your current db and uncommentting the code below ( you will have to comment 
# the code marked #### wormbase above). 

	print "Opening the database....";
#my $db = Ace->connect(-path => '/home/eimear/acedb/WS_current');
# connects to wormbase using aceperl
	$db = Ace->connect(-path => '/home/acedb/WS_current');
	print "done\n";
    }else {exit}


open (OUT, "> Longtext.dump");
@papers = $db->fetch(-class => 'Paper');

foreach $paper (@papers){
    if (($paper =~ /cgc/) || ($paper =~ /pmid/)){
	print "PAPER: $paper\n";
	# Is there associated longtext?
	if($paper->Abstract){
	    # grab name of longtext object
	    $longtext = $paper->Abstract;
	    # use asAce() function to retrieve longtext object
	    $longtext_details = ($db->fetch(Longtext => "$longtext"))->asAce;
	    print OUT "$longtext_details\n";
	}	
    }
}    
close(OUT);

### this also works with a slightly different output format

#@papers = $db->fetch(Paper=>'*');
#foreach $paper (@papers){
#    next unless $paper->Abstract;
#    $longtext = $paper->Abstract->at;
#    print "$longtext\n\\\n";
#}
