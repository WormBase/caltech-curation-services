#!/usr/bin/perl

# This form is an example of working javascript to disable (grey-out) fields.
# This form allows SELECT fields to enable other SELECT fields and write their
# values to a TEXT field.  This form updates onchange instead of every 100ms.
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
    my @vars = qw( thingie1 thingie2 thingie3 doohey group1 group2 group3 group4 );
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
var select1='selectone';
var select2='selecttwo';
var select3='selectthree';
var select4='selectfour';

d.writeln("<FORM method='post' name='form1'>");
d.writeln("<TABLE>");
d.writeln("<TR><TD>mandatory : </TD><TD colspan=2><input type='text' name='thingie1' size='50'></TD></TR>");
d.writeln("<TR><TD>mandatory : </TD><TD colspan=2><input type='text' name='thingie2' size='50'></TD></TR>");
d.writeln("<TR><TD>mandatory : </TD><TD colspan=2><input type='text' name='thingie3' size='50'></TD></TR>");
d.writeln("<TR><TD>optional : </TD><TD colspan=2><input type='text' name='doohey' size='50'></TD></TR>");
d.writeln("<TR><TD></TD></TR>");
d.writeln("<TR><TD><SELECT size=5 name='group1' onchange='checkifempty();'>");
d.writeln("<option value='none'>none</option>");
for(j=0;j<4;j++) d.writeln("<option value='one"+j+" '>"+select1+" "+j+"</option>");
d.writeln("</select></TD>");
d.writeln("<TD><SELECT size=5 name='group2' onchange='checkifempty();'>");
d.writeln("<option value='none'>none</option>");
for(j=0;j<4;j++) d.writeln("<option value='two"+j+" '>"+select2+" "+j+"</option>");
d.writeln("</select></TD>");
d.writeln("<TD><SELECT size=5 name='group3' onchange='checkifempty();'>");
d.writeln("<option value='none'>none</option>");
for(j=0;j<4;j++) d.writeln("<option value='three"+j+" '>"+select3+" "+j+"</option>");
d.writeln("</select></TD>");
d.writeln("<TD><SELECT size=5 name='group4' onchange='checkifempty();'>");
d.writeln("<option value='none'>none</option>");
for(j=0;j<4;j++) d.writeln("<option value='four"+j+" '>"+select4+" "+j+"</option>");
d.writeln("</select></TD></TR>");

d.writeln("<TR><TD></TD></TR>");
d.writeln("<TR><TD><input type='submit' name='action' value='Submit'></TD>");
d.writeln("<TD><input type='reset' name='reset' value='Reset'></TD></TR>");
d.writeln("</TABLE>");
d.writeln("</FORM>");

function checkifempty(){
    // check if anything chosen on group1 to enable group2
  document.form1.group2.disabled=true;		// initialize group2 as disabled
  for (k=0; k<5; k++) {				// check values 0-4
    if (document.form1.group1.options[k].selected == true) { 			// if specific chosen
      document.form1.thingie1.value= document.form1.group1.options[k].value;	// set text field to value
      if (k>0) { document.form1.group2.disabled=false; }			// if valid, enable group2
    } // if (document.form1.group1.options[k].selected == true) 
  } // for (k=0; k<5; k++)

    // same for group2
  document.form1.group3.disabled=true;		// initialize group3 as disabled
  for (k=0; k<5; k++) {
    if (document.form1.group2.options[k].selected == true) { 
      if (k>0) { document.form1.group3.disabled=false; }
      document.form1.thingie2.value= document.form1.group2.options[k].value;
    }
  }

    // if a value chosen in group3 set text field
  for (k=0; k<5; k++) {
    if (document.form1.group3.options[k].selected == true) { 
      document.form1.thingie3.value= document.form1.group3.options[k].value;
    }
  }

    // check if something in mandatory field 1 to allow 4th group
  if (document.form1.thingie1.value=='') { document.form1.group4.disabled=true }
    else { document.form1.group4.disabled=false }
}
checkifempty();					// initialize values
// if (document.all) { setInterval("checkifempty()",100); }	// check values every 100 ms

// function checkifempty()
//   if ( (document.form1.thingie1.value=='') || (document.form1.thingie2.value=='') || 
//        (document.form1.thingie3.value=='')) {
//     document.form1.action.disabled=true
//   } else {
//     document.form1.action.disabled=false
//   }
// } function checkifempty()

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
