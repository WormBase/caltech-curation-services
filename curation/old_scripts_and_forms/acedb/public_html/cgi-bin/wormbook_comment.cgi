#!/usr/bin/perl 

# Get the number of comments and last postdate for a given wormbook chapter comment 
#
# Updated to base off of flatfiles that are update by cronjob.  2009 10 08


use LWP::Simple;

use Jex;			# untaint, getHtmlVar, cshlNew
use strict;
use CGI;

my $query = new CGI;

print "Content-type: text/html\n\n";

my ($var, $name) = &getHtmlVar($query, 'name');
# print "$name<BR>\n";

# print "<link rel=\"stylesheet\" href=\"http://dev.wormbook.org/css/article.css\">\n";

$name =~ s/\s+/_/g;
$name =~ s/\//__SLASH__/g;

$/ = undef;
my $infile = '/home/acedb/public_html/wormbook_forum_stuff/' . $name;

# print "$infile<br>\n";
open (IN, "<$infile") or warn "Cannot open $infile : $!";
my $data = <IN>;
close (IN) or warn "Cannot close $infile : $!";
$/ = "\n";

print "$data\n";

__END__

# print "<FONT SIZE=0.8em >";
my $page = get"http://www.wormbase.org/forums/index.php?board=39.0";
my $posts = 0;
my $comment = 'N/A';
# if ($page =~ m/$name<\/a><\/b>.*?(\d+) Posts in.*?Last post on (.*?), \d{2}:\d{2}:\d{2} [AP]M<br \/>/sg) { $posts = $1; $comment = $2; }
if ($page =~ m/$name<\/a><\/b>.*?(\d+) Posts in.*?Last post on (.*? \d{4}),/sg) { $posts = $1; $comment = $2; }
elsif ($page =~ m/$name<\/a><\/b>.*?(\d+) Posts in.*?/msg) { $posts = $1; }
else { 1; } # print "NO MATCH<BR>\n"; 
# print "<p font size=\"0.8em\">\n";
print "<font face=\"sans-serif\", size=\"2\">\n";
# print "<P style=\"font-family: Verdana, sans-serif; text-align: left; text-decoration: none; float: middle; background: ;font-size: 0.6em; margin: 0px 0px 0px 0px\">\n";
# print "<P style=\"font-family: Verdana, sans-serif; \">\n";
# print "<DIV ID=\"section_locator\">\n";
print "Previous comments: <FONT COLOR=purple>$posts</FONT><BR>\n";
print "Last : <FONT COLOR=purple>$comment</FONT><BR>\n";
print "</P>";
# print "</DIV>\n";
print "</FONT>\n";
