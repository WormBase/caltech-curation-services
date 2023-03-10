#!/usr/bin/perl

# or use this from shell instead :
# minerva-..o_update-65: lwp-request -C wormbase:EmqssK17n http://elegans.swmed.edu/CeRD/database/listed.shtml > file

use LWP::UserAgent;
use Jex;	# getSimpleDate

my $browser = LWP::UserAgent->new;

# $browser->credentials(  # add this to our $browser 's "key ring"
#   'www.unicode.org:80',
#   'Unicode-MailList-Archives',
#   'unicode-ml' => 'unicode'
# );

$browser->credentials(
  'elegans.swmed.edu:80',
#   'CeRD/database/listed.shtml',
  'C elegans Researcher Directory',
  'wormbase' => 'EmqssK17n'
);



# my $url = 'http://www.unicode.org/mail-arch/unicode-ml/y2002-m08/0067.html';
my $url = 'http://elegans.swmed.edu/CeRD/database/listed.shtml';
my $response = $browser->get($url);

die "Error: ", $response->header('WWW-Authenticate') || 
  'Error accessing',
  #  ('WWW-Authenticate' is the realm-name)
  "\n ", $response->status_line, "\n at $url\n Aborting"
 unless $response->is_success;

# print "Whee, it worked!  I got that ", $response->content, " document!\n";

my $date = &getSimpleDate();
my $file = 'file' . $date;
open (OUT, ">$file") or die "Cannot create $file : $!";
print OUT $response->content;
close (OUT) or die "Cannot close $file : $!";


