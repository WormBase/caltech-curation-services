#!/usr/bin/perl5.6.0

use lib qw( /usr/lib/perl5/site_perl/5.6.1/i686-linux/ );
use CGI;
use Pg;

$conn = Pg::connectdb("dbname=testdb");               # connect to the database 

die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status; 

print <<"EndOfText";
Content-type: text/html\n\n

<HTML>
<!--<LINK rel="stylesheet" type="text/css" href="http://www.wormbase.org/stylesheets/wormdb.css">-->
<HEAD>
<TITLE>PGSQL display Minerva</TITLE>
</HEAD>
<BODY bgcolor=#000000 text=#aaaaaa link=#cccccc>
EndOfText

print "1<BR>\n";
# $result = $conn->exec(
#         "SELECT * \
#          FROM friend ");
# print "<CENTER><TABLE>\n";
# while (@row = $result->fetchrow) {          # loop through all rows returned 
# # print "@row<BR>\n";                       # print the value returned 
#   print "<TR>";
#   foreach $_ (@row) {
#     print "<TD>$_<\TD>\n";         # print the value returned 
#   }
#   print "<\TR>\n";
# } 
# print "</TABLE></CENTER>\n";
print "3<BR>\n";

$result = $conn->exec( "DELETE FROM friend WHERE lastname = 'Smith';" );
while (@row = $result->fetchrow) {          # loop through all rows returned 
  print "ROW : @row<BR>\n";                       # print the value returned 
  print "<TR>";
  foreach $_ (@row) {
    print "<TD>$_<\TD>\n";         # print the value returned 
  }
  print "<\TR>\n";
} 
$result = $conn->exec( "INSERT INTO friend VALUES ('Bob', 'Smith', 'Pasadena', 'TX', 22 );" );
$result = $conn->exec( "SELECT * FROM friend ");
while (@row = $result->fetchrow) {          # loop through all rows returned 
  print "ROW : @row<BR>\n";                       # print the value returned 
  print "<TR>";
  foreach $_ (@row) {
    print "<TD>$_<\TD>\n";         # print the value returned 
  }
  print "<\TR>\n";
} 

print "4<BR>\n";

# Pg::doQuery($conn, "select firstname, lastname from friend", \@ary);
Pg::doQuery($conn, "select * from friend", \@ary);

print "<CENTER><TABLE>\n";
for $i ( 0 .. $#ary ) {
    print "<TR>";
    for $j ( 0 .. $#{$ary[$i]} ) {
        print "<TD>$ary[$i][$j]\t<\TD>";
    }
    print "<\TR>\n";
}
print "</TABLE></CENTER>\n";
print "5<BR>\n";


print <<"EndOfText";
<BR>
</BODY>
EndOfText
