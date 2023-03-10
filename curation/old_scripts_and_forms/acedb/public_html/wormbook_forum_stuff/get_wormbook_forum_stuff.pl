#!/usr/bin/perl 

# Get the number of comments and last postdate for each wormbook chapter comment and write to a flatfile.
# 2009 10 08
#
# Updated for link change  2010 06 26

# # update every day at 2am.  2009 10 08
# # 0 2 * * * /home/acedb/public_html/wormbook_forum_stuff/get_wormbook_forum_stuff.pl

# Last modified 2010 Jun 26, stopped working 2011 06 11, disabled from cron 2023 03 03



use LWP::Simple;

use Jex;			# untaint, getHtmlVar, cshlNew
use strict;
use CGI;

my $query = new CGI;

my $page = get "http://www.wormbase.org/forums/index.php?board=31.0";
# my (@section_links) = $page =~ m/<a href=\"(http:\/\/www.wormbase.org\/forums\/index.php\?board=\d+\.0)\" name=\"b\d+\">/g;	# format changed sometimes after 2010-05-10
my (@section_links) = $page =~ m/<a href=\"(http:\/\/forums.wormbase.org\/index.php\?board=\d+\.0)\" name=\"b\d+\">/g;		# to accomodate for format change  2010-06-26

foreach my $section_link (@section_links) {
  $page = get "$section_link";
  my (@trs) = $page =~ m/<tr class=\"windowbg2\">(.*?)<\/tr>/sg;
  foreach my $tr (@trs) {
    my $name = 'unknown';
    my $posts = 0;
    my $comment = 'N/A';
    if ($tr =~ m/name=\"b\d+\">(.*?)<\/a><\/b>.*?(\d+) Posts in.*?Last post on (.*? \d{4}),/sg) { $name = $1; $posts = $2; $comment = $3; }
    elsif ($tr =~ m/name=\"b\d+\">(.*?)<\/a><\/b>.*?(\d+) Posts in/sg) { $name = $1; $posts = $2; }
#     print "NAME $name\tPOSTS $posts\tCOMMENT $comment END\n";
    $name =~ s/\s+/_/g;
    $name =~ s/\//__SLASH__/g;
    my $outfile = '/home/acedb/public_html/wormbook_forum_stuff/' . $name;
    open (OUT, ">$outfile") or die "Cannot open $outfile : $!";
    print OUT "<font face=\"sans-serif\", size=\"2\">\n";
    print OUT "Previous comments: <FONT COLOR=purple>$posts</FONT><BR>\n";
    print OUT "Last : <FONT COLOR=purple>$comment</FONT><BR>\n";
    print OUT "</P>";
    print OUT "</FONT>\n";
    close (OUT) or die "Cannot close $outfile : $!";
  }

# <tr class="windowbg2">
# 
# 				<td class="windowbg" width="6%" align="center" valign="top"><a href="http://www.wormbase.org/forums/index.php?action=unread;board=276.0"><img src="http://www.wormbase.org/forums/Themes/wormbase/images/off.gif" alt="No New Posts" title="No New Posts" border="0" /></a></td>
# 				<td align="left">
# 					<b><a href="http://www.wormbase.org/forums/index.php?board=276.0" name="b276">Mechanosensation</a></b><br />
# 			
# 				</td>
# 				<td class="windowbg" valign="middle" align="center" style="width: 12ex;"><span class="smalltext">
# 					6 Posts in<br />
# 					1 Topics
# 				</span></td>
# 
# 				<td class="smalltext" valign="middle" width="22%">
# 					Last post on May 28, 2008, 01:05 PM<br />
# 					in <a href="http://www.wormbase.org/forums/index.php?topic=514.new#new" title="Re: what is trpa-2  ?">Re: what is trpa-2  ?</a> by <a href="http://www.wormbase.org/forums/index.php?action=profile;u=40">mh6</a>
# 				</td>
# 			</tr>

}


__END__

print "Content-type: text/html\n\n";

my ($var, $name) = &getHtmlVar($query, 'name');
# print "$name<BR>\n";

# print "<link rel=\"stylesheet\" href=\"http://dev.wormbook.org/css/article.css\">\n";

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
