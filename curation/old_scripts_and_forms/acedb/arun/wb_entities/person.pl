#!/usr/bin/perl -w
use strict;

my $page = getwebpage("http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/person_obo.cgi");
my @lines = split(/\n/, $page);
my $outfile = "./known_objects/Person";
open (OUT, ">$outfile");
for (my $i=0; $i<@lines; $i++) {
	my $line = $lines[$i];
	chomp($line);
	if ($line eq "[Term]") {
		my $id = "";
		my @names = ();

		my $j = $i+1;
		my $line2 = $lines[$j];
		chomp($line2);
		while ($line2 ne "") {
			if ($line2 =~ /id: (\S+)/) {
				$id = $1;
			} elsif ( ($line2 =~ /name: (.+)/) || ($line2 =~ /aka: (.+)/) ) {
				push @names, $1;
			}
			$line2 = $lines[++$j];
		}

		for my $n (@names) {
			print OUT "$n\t$id\n";
		}
	}
}
close (OUT);
print "Output stored in $outfile\n"; 


sub getwebpage{
    my $u = shift;
    my $page = "";
	use LWP::UserAgent;
	use HTTP::Request;
	
    my $ua = LWP::UserAgent->new(timeout => 30); # instantiates a new user agent
    my $request = HTTP::Request->new(GET => $u); # grabs url
    my $response = $ua->request($request);       # checks url, dies if not valid.
    
    $page = $response->content;    #splits by line
    return $page;
}
