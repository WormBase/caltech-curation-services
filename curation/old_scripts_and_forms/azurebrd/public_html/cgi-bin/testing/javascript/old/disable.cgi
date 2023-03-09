#!/usr/bin/perl

# This form is an example of working javascript to disable (grey-out) fields.
# 2003 02 08

use strict;
use Jex;
use CGI;

my $query = new CGI;


print "Content-type: text/html\n\n";
my $title = 'Blih CGI';
&process();
&display();

sub process {
  my $action = 'NO ACTION';                   # what user clicked
  unless ($action = $query->param('action')) { $action = 'none'; }

  print "ACTION : $action<P>\n";

  if ($action eq 'Submit') {
    my @vars = qw( thingie thingie2 thingie3 doohey );
    print "<TABLE border=2 cellspacing=5>\n";
    foreach my $var (@vars) {
      my ($oop, $val) = &getHtmlVar($query, $var);
      print "<TD><TD>$var</TD><TD>$val</TD></TR>\n";
    } # foreach my $var (@vars)
    print "</TABLE>\n";
  }

  else { 1; }

} # sub process

sub display {			# display page

  print <<"EndOfText";
<html>
<body>

<script language="JavaScript1.1">

var d=document;

d.writeln("<FORM method='post' name='form1'>");
d.writeln("<TABLE>");
d.writeln("<TR><TD>mandatory : </TD><TD><input type='text' name='thingie' size='50'></TD></TR>");
d.writeln("<TR><TD>mandatory : </TD><TD><input type='text' name='thingie2' size='50'></TD></TR>");
d.writeln("<TR><TD>mandatory : </TD><TD><input type='text' name='thingie3' size='50'></TD></TR>");
d.writeln("<TR><TD>optional : </TD><TD><input type='text' name='doohey' size='50'></TD></TR>");
d.writeln("<TR><TD><input type='submit' name='action' value='Submit'></TD>");
d.writeln("<TD><input type='reset' name='reset' value='Reset'></TD></TR>");
d.writeln("</TABLE>");
d.writeln("</FORM>");

function checkifempty(){
  if ( (document.form1.thingie.value=='') || (document.form1.thingie2.value=='') || 
       (document.form1.thingie3.value=='')) {
    document.form1.action.disabled=true
  } else {
    document.form1.action.disabled=false
  }
}
if (document.all) { setInterval("checkifempty()",100) }


// d.writeln("<FORM name='nn'>");
// for(i=0;i<depth2;i++) {
//   d.writeln("<SELECT size=5 name='m"+i+"' onChange='setitems2("+i+")'>");
//   for(j=0;j<5;j++) d.writeln("<option >----Please, select-----");
//   d.writeln("</select>");
// }
// d.writeln("<br><input type='text' name='thingie' size='50' onchange='setitems(1);'>");
// d.writeln("<br><input type='text' name='doohey' size='50' onchange='setitems(1);'>");
// d.writeln("<br><input type='submit' name='action' value='Submit'>");
// d.writeln("</form>");
// setitems2(0);
// 
// d.writeln("<FORM name='mm'>");
// for(i=0;i<depth;i++) {
//   d.writeln("<SELECT size=5 name='m"+i+"' onChange='setitems("+i+")'>");
//   for(j=0;j<5;j++) d.writeln("<option >----Please, select-----");
//   d.writeln("</select>");
// }
// d.writeln("<br><input type='text' name='thingie' size='50' onchange='setitems(1);'>");
// d.writeln("<br><input type='text' name='doohey' size='50' onchange='setitems(1);'>");
// d.writeln("<br><input type='submit' name='action' value='Submit'>");
// d.writeln("</form>");
// 
// setitems(0);
</script>



</body>
</html>

EndOfText
} # sub display
