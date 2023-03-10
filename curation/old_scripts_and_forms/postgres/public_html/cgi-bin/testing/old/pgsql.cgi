#!/usr/bin/perl5.6.0

use lib qw( /usr/lib/perl5/site_perl/5.6.1/i686-linux/ );
use CGI;
use Pg;

$query = new CGI;

$conn = Pg::connectdb("dbname=testdb");               # connect to the database 

die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status; 

&OpenHTML();
&EvalAction();
&PrintSimple();
&DisplayForm();
&CloseHTML();

sub EvalAction {
  unless ($action = $query->param('action')) {
    $action = 'none';
  }

  if ($action eq 'Add !') {
    $firstname = $query->param('firstname');
    $lastname = $query->param('lastname');
    $city = $query->param('city');
    $state = $query->param('state');
    $age = $query->param('age');
    print "$firstname $city<BR>\n";
    if ($firstname) {
      $result = $conn->exec( "INSERT INTO friend VALUES ('$firstname', '$lastname', '$city', '$state', '$age' );" );
    } # if ($firstname) 
  } # if ($action eq 'Add !') 

  if ($action eq 'Remove !') {
    $removefirstname = $query->param('removefirstname');
    $removelastname = $query->param('removelastname');
    $removecity = $query->param('removecity');
    $removestate = $query->param('removestate');
    $removeage = $query->param('removeage');
    if ($removefirstname) {
      $result = $conn->exec( "DELETE FROM friend WHERE firstname = '$removefirstname';" );
    }
    if ($removelastname) {
      $result = $conn->exec( "DELETE FROM friend WHERE lastname = '$removelastname';" );
    }
    if ($removecity) {
      $result = $conn->exec( "DELETE FROM friend WHERE city = '$removecity';" );
    }
    if ($removestate) {
      $result = $conn->exec( "DELETE FROM friend WHERE state = '$removestate';" );
    }
    if ($removeage) {
      $result = $conn->exec( "DELETE FROM friend WHERE age = '$removeage';" );
    }
  } # if ($action eq 'Remove !') 
} # sub EvalAction 

sub DisplayForm {
print <<"EndOfText";

<FORM METHOD="POST" ACTION="pgsql.cgi">
<TABLE>
<TR><TD><A NAME="form"><H2>Add your entry :</H2></A></TD></TR>

<TR>
<TD ALIGN="right"><STRONG>First Name :</STRONG></TD>
<TD><INPUT NAME="firstname" SIZE=30></TD>
</TR>

<TR>
<TD ALIGN="right"><STRONG>Last Name :</STRONG></TD>
<TD><INPUT NAME="lastname" SIZE=30></TD>
</TR>

<TR>
<TD ALIGN="right"><STRONG>City :</STRONG></TD>
<TD><INPUT NAME="city" SIZE=30></TD>
</TR>

<TR>
<TD ALIGN="right"><STRONG>State :</STRONG></TD>
<TD><INPUT NAME="state" SIZE=30></TD>
</TR>

<TR>
<TD ALIGN="right"><STRONG>Age :</STRONG></TD>
<TD><INPUT NAME="age" SIZE=30></TD>
</TR>


<TR><TD COLSPAN=2> </TD></TR>
<TR>
<TD> </TD>
<TD><INPUT TYPE="submit" NAME="action" VALUE="Add !"></TD>
</TR>

<TR><TD><A NAME="form"><H2>Remove an entry :</H2></A></TD></TR>

<TR>
<TD ALIGN="right"><STRONG>First Name :</STRONG></TD>
<TD><INPUT NAME="removefirstname" SIZE=30></TD>
<TD><INPUT TYPE="submit" NAME="action" VALUE="Remove !"></TD>
</TR>

<TR>
<TD ALIGN="right"><STRONG>Last Name :</STRONG></TD>
<TD><INPUT NAME="removelastname" SIZE=30></TD>
<TD><INPUT TYPE="submit" NAME="action" VALUE="Remove !"></TD>
</TR>

<TR>
<TD ALIGN="right"><STRONG>City :</STRONG></TD>
<TD><INPUT NAME="removecity" SIZE=30></TD>
<TD><INPUT TYPE="submit" NAME="action" VALUE="Remove !"></TD>
</TR>

<TR>
<TD ALIGN="right"><STRONG>State :</STRONG></TD>
<TD><INPUT NAME="removestate" SIZE=30></TD>
<TD><INPUT TYPE="submit" NAME="action" VALUE="Remove !"></TD>
</TR>

<TR>
<TD ALIGN="right"><STRONG>Age :</STRONG></TD>
<TD><INPUT NAME="removeage" SIZE=30></TD>
<TD><INPUT TYPE="submit" NAME="action" VALUE="Remove !"></TD>
</TR>
</TABLE>
EndOfText

} # sub DisplayForm


sub PrintSimple {

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

  $result = $conn->exec( "DELETE FROM friend WHERE state = 'TX';" );
  $result = $conn->exec( "INSERT INTO friend VALUES ('Bob', 'Smith', 'Pasadena', 'TX', 22 );" );

#   Pg::doQuery($conn, "select firstname, lastname from friend", \@ary);
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
} # sub PrintSimple 


sub OpenHTML {

print <<"EndOfText";
Content-type: text/html\n\n

<HTML>
<!--<LINK rel="stylesheet" type="text/css" href="http://www.wormbase.org/stylesheets/wormdb.css">-->
<HEAD>
<TITLE>PGSQL display Minerva</TITLE>
</HEAD>
<BODY bgcolor=#000000 text=#aaaaaa link=#cccccc>
EndOfText

} # sub OpenHTML 


sub CloseHTML {
  print <<"EndOfText";
<BR>
</BODY>
EndOfText
} # sub CloseHTML 
