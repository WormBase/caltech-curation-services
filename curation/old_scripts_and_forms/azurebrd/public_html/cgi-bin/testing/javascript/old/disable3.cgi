#!/usr/bin/perl

# This form is an example of working javascript to disable (grey-out) fields.
# This form allows SELECT fields to enable other SELECT fields and write their
# values to a TEXT field.  This form updates onchange instead of every 100ms.
# This form allows a variable number of rows of SELECT fields by using eval()
# on the document
# 2003 02 08

use strict;
use Jex;
use CGI;

my $query = new CGI;

my $rows = 2;			# amount of rows of select fields

print "Content-type: text/html\n\n";
my $title = 'Blih CGI';
&process();
&display();

sub process {
  my $action = 'NO ACTION';			# what user clicked
  unless ($action = $query->param('action')) { $action = 'none'; }

  print "ACTION : $action<P>\n";

  if ($action eq 'Submit') {
    my @vars = qw( thingie1 thingie2 thingie3 doohey );
    print "<TABLE border=2 cellspacing=5>\n";
    foreach my $var (@vars) {			# get text values
      my ($oop, $val) = &getHtmlVar($query, $var);
      print "<TD><TD>$var</TD><TD>$val</TD></TR>\n";
    } # foreach my $var (@vars)
    for (my $i = 0; $i<$rows; $i++) {		# get group values
      for (my $j = 1; $j<5; $j++) {
        my $var = 'group' . $i . $j;
        my ($oop, $val) = &getHtmlVar($query, $var);
        print "<TD><TD>$var</TD><TD>$val</TD></TR>\n";
      } # for (my $j = 0; $j<4; $j++)
    } # for (my $var = 0; $var<$rows; $var++)
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
d.writeln("<TR><TD>mandatory : </TD><TD colspan=3><input type='text' name='thingie1' size='50'></TD></TR>");
d.writeln("<TR><TD>mandatory : </TD><TD colspan=3><input type='text' name='thingie2' size='50'></TD></TR>");
d.writeln("<TR><TD>mandatory : </TD><TD colspan=3><input type='text' name='thingie3' size='50'></TD></TR>");
d.writeln("<TR><TD>optional : </TD><TD colspan=3><input type='text' name='doohey' size='50'></TD></TR>");

d.writeln("<TR></TR>");

for (i=0; i<$rows; i++) {		// for each of the rows 
  d.writeln("<TR>");			// start table row
  for (j=1; j<5; j++) {			// for columns 1 through 5
    d.writeln("<TD>group"+i+""+j+"<BR><SELECT size=5 name='group"+i+""+j+"' onchange='checkifempty();'>");
					// start the select naming the group by row and column
    d.writeln("<option value='none'>none</option>");	// initial none option
    for(k=0;k<4;k++) d.writeln("<option value='option "+i+" "+j+" "+k+" '>select "+i+" "+j+" "+k+"</option>");
					// for each of the valid 4 options, show option
    d.writeln("</select></TD>");	// close table select
  } // for (j=0; j<2; j++)
  d.writeln("</TR>");			// close table row
} // for (i=0; i<2; i++)

d.writeln("<TR></TR>");

d.writeln("<TR><TD><input type='submit' name='action' value='Submit'></TD>");
d.writeln("<TD><input type='reset' name='reset' value='Reset'></TD></TR>");
d.writeln("</TABLE>");
d.writeln("</FORM>");

function checkifempty() {
    // check if anything chosen on group01 to enable group02
  for (i = 0; i<$rows; i++) {
    eval("document.form1.group"+i+"2.disabled=true");	// initialize group02 as disabled	
    for (k=0; k<5; k++) {				// check values 0-4
      if ( eval("document.form1.group"+i+"1.options[k].selected") == true ) {	// if specific chosen
        document.form1.thingie1.value= eval("document.form1.group"+i+"1.options[k].value");
							// set text field to value
        if (k>0) { eval("document.form1.group"+i+"2.disabled=false"); }		// if valid, enable group02
      } // if (document.form1.group01.options[k].selected == true) 
    } // for (k=0; k<5; k++)
  
      // same for group02
    eval("document.form1.group"+i+"3.disabled=true");	// initialize group03 as disabled
    for (k=0; k<5; k++) {
      if ( eval("document.form1.group"+i+"2.options[k].selected") == true) { 
        document.form1.thingie2.value= eval("document.form1.group"+i+"2.options[k].value");
        if (k>0) { eval("document.form1.group"+i+"3.disabled=false"); }
      }
    }
  
      // if a value chosen in group03 set text field
    for (k=0; k<5; k++) {
      if (eval("document.form1.group"+i+"3.options[k].selected") == true) { 
        document.form1.thingie3.value= eval("document.form1.group"+i+"3.options[k].value");
      }
    }
  
      // check if something in mandatory field 1 to allow 4th group
    if (document.form1.thingie1.value=='') { eval("document.form1.group"+i+"4.disabled=true"); }
      else { eval("document.form1.group"+i+"4.disabled=false"); }
  } // for (i = 0; i<2; i++)
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

</script>



</body>
</html>

EndOfText
} # sub display
