#!/usr/bin/perl


use CGI;
use Pg;


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
