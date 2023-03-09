#!/usr/bin/perl


use CGI;
use Pg;
use Jex;

my $var;
my $query = new CGI;

print "Content-type: text/html\n\n";

($var, my $frame_type) = &getHtmlVar($query, 'frame_type');

if ($frame_type eq 'top') { &showTop(); }
elsif ($frame_type eq 'left') { &showLeft(); }
elsif ($frame_type eq 'right') { &showRight(); }
elsif ($frame_type eq 'bottom') { &showBottom(); }
else { &showMain(); }

sub showMain {
  print "<html>\n";
  print "<frameset rows=\"50%,50%\">\n";
#   print "  <frame name=\"top\" src=\"frames.cgi?frame_type=top\">\n";
  print "  <frameset cols=\"50%,50%\">\n";
  print "    <frame name=\"left\" src=\"frames.cgi?frame_type=left\">\n";
  print "    <frame name=\"right\" src=\"frames.cgi?frame_type=right\">\n";
  print "  </frameset>\n";
  print "  <frame name=\"bottom\" src=\"frames.cgi?frame_type=bottom\">\n";
  print "</frameset>\n";
  print "</html>\n";
} # sub showMain

sub showTop {
  print "<html>\n";
  print "<frameset cols=\"50%,50%\">\n";
  print "  <frame name=\"left\" src=\"frames.cgi?frame_type=left\">\n";
  print "  <frame name=\"right\" src=\"frames.cgi?frame_type=right\">\n";
  print "</frameset>\n";
  print "</html>\n";
} # sub showTop

sub showLeft {
  print "<html>\n";
  print "<script type=\"text/javascript\" src=\"http://tazendra.caltech.edu/~azurebrd/cgi-bin/testing/frames/frames.js\"></script>\n";
  print "<body bgcolor=\"#8F8FBD\">\n";
  print "<h3>Editor</h3>\n";
  print "<a href=\"frames.cgi?frame_type=right&text=text\" target=\"right\">link</a><br />\n";
  print "<input id=\"right_link\" name=\"right_link\" size=\"20\"><br />\n";
  print "<button onclick=\"top.frames['right'].document.getElementById('right_text').value = document.getElementById('right_link').value; \">put on right</button><br />\n";
#   print "<button onclick=\"popRight('right_text', 'right_link');\">act on right</button><br />\n";
  print "</body>\n";
  print "</html>\n";
}

sub showRight {
  ($var, my $text) = &getHtmlVar($query, 'text');
  print "<html>\n";
  print "<body bgcolor=\"cyan\">\n";
  print "<h3>Obo</h3>\n";
  print "$text<br />\n";
  print "<input id=\"right_text\" name=\"right_text\" value=\"default right\" size=\"20\">\n";
  print "</body>\n";
  print "</html>\n";
}

sub showBottom {
  print "<html>\n";
  print "<body bgcolor=\"yellow\">\n";
  print "<h3>Table</h3>\n";
  print "</body>\n";
  print "</html>\n";
}

__END__

$conn = Pg::connectdb("dbname=testdb");               # connect to the database 

die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status; 

$result = $conn->exec(
        "SELECT firstname \
         FROM friend ");


print <<"EndOfText";
Content-type: text/html\n\n

<HTML>
<!--<LINK rel="stylesheet" type="text/css" href="http://www.wormbase.org/stylesheets/wormdb.css">-->
<HEAD>
<TITLE>PGSQL display thing</TITLE>
</HEAD>
<BODY>
EndOfText

print "1<BR>\n";
# @row = qw(lalala oop coo);
# print "ROW -=$row[0]=- ROW<BR>\n";
# foreach $_ (@row) {
#   print "ROW -=$_=- ROW<BR>\n";
# }
# @row = $result->fetchrow;
# @row = $result->fetchrow;
# @row = $result->fetchrow;
# if (scalar(@row)) { print "lala " . scalar(@row) . "<BR>\n"; }
#   foreach $_ (@row) {
#     push @row2, $_; print $_ . "<BR>\n";
#   }
# print "row2 ", @row2, "<BR>\n";
#   print "lala<BR>\n";
#   foreach $_ (@row2) {
#     print @row, "ROW -=$_=- ROW<BR>\n";
#   }
# print "asdf<BR>\n";
# while (@row = $result->fetchrow) {                      # loop through all rows returned 
#   @row2 = @row;
#   foreach $_ (@row) {
#     push @row2, $_;
#   }
#   print "lala<BR>\n";
#   foreach $_ (@row2) {
#     print @row, "ROW -=$_=- ROW<BR>\n";
#   }
# }

# print "\n\nWHILE : \n";
while (@row = $result->fetchrow) {                      # loop through all rows returned 
 # print @row;
# print "lalala\n";
 print "@row<BR>\n";                       # print the value returned 
} 
print "3<BR>\n";

print <<"EndOfText";
<BR>
</BODY>
EndOfText
