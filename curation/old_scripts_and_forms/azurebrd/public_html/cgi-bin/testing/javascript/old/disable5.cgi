#!/usr/bin/perl

# This form is an example of working javascript to disable (grey-out) fields.
# This form allows SELECT fields to enable other SELECT fields and write their
# values to a TEXT field.  This form updates onchange instead of every 100ms.
# This form allows a variable number of rows of SELECT fields by using eval()
# on the document.
# This form allows a menu[][] to be written for the form to load values from.
# 2003 02 09
# This form allows a menu[][] to be written with an arbitrary amount of
# arbitrary values   2003 02 10

use strict;
use Jex;
use CGI;

my $query = new CGI;

my $rows = 2;			# amount of rows of select fields

print "Content-type: text/html\n\n";
my $title = 'Disable CGI';
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

var orig_menu_name = new Array('none', 'action', 'allele', 'association', 'cell or cell group', 'characterization', 'comparison', 'consort', 'component', 'drugs', 'descriptor', 'fake');	// menu items for group N1
var orig_menu_val = new Array('none', 'ac', 'al', 'as', 'ce', 'ch', 'cm', 'cn', 'co', 'dr', 'de', 'fa');	// menu values for group N1

// var menuInit = new Array();
// var menu0 = new Array('none', 'select 0 0 1', 'select 0 0 2');
// // var menu0 = new Array('none', 'select 0 0 1', 'select 0 0 2', 'select 0 0 3', 'select 0 0 4');
// var menu1 = new Array('action', 'allele', 'association', 'cell or cell group', 'characterization', 'comparison', 'consort', 'component', 'drugs', 'descriptor');
// // var menu1 = new Array('none', 'select 0 1 1', 'select 0 1 2', 'select 0 1 3', 'select 0 1 4');
// var menu2 = new Array('none', 'select 0 2 1', 'select 0 2 2', 'select 0 2 3', 'select 0 2 4');
// var menu3 = new Array('none', 'select 0 3 1', 'select 0 3 2', 'select 0 3 3', 'select 0 3 4');
// var menu4 = new Array('none', 'select 0 4 1', 'select 0 4 2', 'select 0 4 3', 'select 0 4 4');
// menuInit[0] = menu0;
// menuInit[1] = menu1;
// menuInit[2] = menu2;
// menuInit[3] = menu3;
// menuInit[4] = menu4;
// 
// for (i=0; i<$rows; i++) {		// for each of the rows 
//   d.writeln("<TR>");			// start table row
//   for (j=1; j<menuInit.length; j++) {
//     d.writeln("<TD>group"+i+""+j+"<BR><SELECT size=5 name='group"+i+""+j+"' onchange='checkifempty();'>");
// //     for (k=0; k<5; k++) d.writeln("<option value='option "+i+" "+j+" "+k+" '>select "+i+" "+j+" "+k+"</option>");
//     for (k=0; k<menuInit[j].length; k++) {	// check values in group N1, k is index
// //       d.writeln("<option value=menuInit[i][j]>"+j+" "+k+"</option>");
//        menutemp = eval("menuInit[j][k]");
//        d.writeln("<option value='"+menutemp+"'>"+menutemp+"</option>");
//     }
//     d.writeln("</select></TD>");	// close table select
//   } // for (j=0; j<2; j++)
//   d.writeln("</TR>");			// close table row
// } // for (i=0; i<$rows; i++)		// for each of the rows 

for (i=0; i<$rows; i++) {		// for each of the rows 
  d.writeln("<TR>");			// start table row
  for (j=1; j<5; j++) {			// for columns 1 through 5
    d.writeln("<TD>group"+i+""+j+"<BR><SELECT size=5 name='group"+i+""+j+"' onchange='checkifempty();'>");
					// start the select naming the group by row and column
    d.writeln("<option value='none'>none</option>");	// initial none option
    for(k=1;k<5;k++) d.writeln("<option value='option "+i+" "+j+" "+k+" '>select "+i+" "+j+" "+k+"</option>");
					// for each of the valid 4 options, show option
    d.writeln("</select></TD>");	// close table select
  } // for (j=0; j<2; j++)
  d.writeln("</TR>");			// close table row

  for (z = eval("document.form1.group"+i+"1.options.length"); z>=1; z--) {
    eval("document.form1.group"+i+"1.options[z] = null;"); 
  }
  for (org=0; org<orig_menu_name.length; org++) {	// reset menu options for group N1
    eval("document.form1.group"+i+"1.options[org] = new Option(orig_menu_name[org], orig_menu_val[org]);" );
  } // for (org=0; org<orig_menu_name.length; org++)

} // for (i=0; i<2; i++)

d.writeln("<TR></TR>");

d.writeln("<TR><TD><input type='submit' name='action' value='Submit'></TD>");
d.writeln("<TD><input type='reset' name='reset' value='Reset'></TD></TR>");
d.writeln("</TABLE>");
d.writeln("</FORM>");


function checkifempty() {

// mymenu.sub[0] = new dynoMenu("action", "ac");
// mymenu.sub[1] = new dynoMenu("allele", "al");
// mymenu.sub[2] = new dynoMenu("association", "as");
// mymenu.sub[3] = new dynoMenu("cell or cell group", "ce");
// mymenu.sub[3].sub[0] = new dynoMenu("name", "name");
// mymenu.sub[3].sub[1] = new dynoMenu("lineage", "lineage");
// mymenu.sub[3].sub[2] = new dynoMenu("group", "group");
// mymenu.sub[4] = new dynoMenu("characterization", "ch");
// mymenu.sub[5] = new dynoMenu("comparison", "cm");
// mymenu.sub[5].sub[0] = new dynoMenu("similar", "similar");
// mymenu.sub[5].sub[1] = new dynoMenu("identical", "identical");
// mymenu.sub[5].sub[2] = new dynoMenu("different", "different");
// mymenu.sub[6] = new dynoMenu("consort", "cn");
// mymenu.sub[6].sub[0] = new dynoMenu("positive", "positive");
// mymenu.sub[6].sub[1] = new dynoMenu("negative", "negative");
// mymenu.sub[7] = new dynoMenu("component", "co");
// mymenu.sub[7].sub[0] = new dynoMenu("go", "go");
// mymenu.sub[7].sub[1] = new dynoMenu("janus", "janus");
// mymenu.sub[8] = new dynoMenu("drugs", "dr");
// mymenu.sub[8].sub[0] = new dynoMenu("antibiotic", "antibiotic");
// mymenu.sub[9] = new dynoMenu("descriptor", "ds");

  var menu = new Array();					// array of values for groupN2
  var menu1 = new Array('EMPTY1');
//   var menu1 = new Array('bob 1 0', 'cod 1 1', 'dod 1 2', 'mod 1 3', 'wod 1 4');
    // values for groupN2 if choose first option of groupN1
  var menu2 = new Array('EMPTY2');
//   var menu2 = new Array('2 0', '2 1', '2 2', '2 3', '2 4', '2 5', '2 6', '2 7');
    // values for groupN2 if choose second option of groupN1
  var menu3 = new Array('EMPTY3');
//   var menu3 = new Array('3 0', '3 1', '3 2');
    // values for groupN2 if choose third option of groupN1
  var menu4 = new Array('name', 'lineage', 'group');
  var menu5 = new Array('EMPTY5');
  var menu6 = new Array('similar', 'identical', 'different');
  var menu7 = new Array('positive', 'negative');
  var menu8 = new Array('go', 'janus');
  var menu9 = new Array('antibiotic');
  var menu10 = new Array('EMPTY10');
  var menu11 = new Array('fake', 'EMPTY11');
  menu[1] = menu1;
  menu[2] = menu2;
  menu[3] = menu3;
  menu[4] = menu4;
  menu[5] = menu5;
  menu[6] = menu6;
  menu[7] = menu7;
  menu[8] = menu8;
  menu[9] = menu9;
  menu[10] = menu10;
  menu[11] = menu11;
  
    // check if anything chosen on group01 to enable group02
  for (row = 0; row<$rows; row++) {				// for each of the rows
    eval("document.form1.group"+row+"2.disabled=true");	// initialize group02 as disabled	
//     for (k=0; k<5; k++) 				// check values 0-4   k is the index
    for (k=0; k<eval("document.form1.group"+row+"1.options.length"); k++) {	// check values in group N1, k is index
      if ( eval("document.form1.group"+row+"1.options[k].selected") == true ) {	// if specific chosen
        document.form1.thingie1.value= eval("document.form1.group"+row+"1.options[k].value");
							// set text field to value
        if (k>0) { eval("document.form1.group"+row+"2.disabled=false"); }		// if valid, enable group02
      } // if (document.form1.group01.options[k].selected == true) 
    } // for (k=0; k<eval("document.form1.group"+row+"1.options.length"); k++)
  
      // same for group02
    eval("document.form1.group"+row+"3.disabled=true");	// initialize group03 as disabled
    for (k=0; k<eval("document.form1.group"+row+"2.options.length"); k++) {	// check values in group N2, k is index
      if ( eval("document.form1.group"+row+"2.options[k].selected") == true) { 
        document.form1.thingie2.value= eval("document.form1.group"+row+"2.options[k].value");
        if (k>0) { eval("document.form1.group"+row+"3.disabled=false"); }
      }
    }
  
      // if a value chosen in group03 set text field
//     for (k=0; k<5; k++) {
    for (k=0; k<eval("document.form1.group"+row+"3.options.length"); k++) {	// check all values in group N3
      if (eval("document.form1.group"+row+"3.options[k].selected") == true) { 
        document.form1.thingie3.value= eval("document.form1.group"+row+"3.options[k].value");
      }
    }
  
      // check if something in mandatory field 1 to allow 4th group
    if (document.form1.thingie1.value=='') { eval("document.form1.group"+row+"4.disabled=true"); }
      else { eval("document.form1.group"+row+"4.disabled=false"); }



    // check specific option in groupN1 to reset groupN2
    for (indC1=1; indC1<menu.length; indC1++) {	// make the 2-4 options reset group N2
				// for each of the action options in group N1
				// indC1 is the index of Column 1
      if ( eval("document.form1.group"+row+"1.options[indC1].selected") == true ) {	// if selected, do stuff
        for (z = eval("document.form1.group"+row+"2.options.length"); z>=1; z--) {
          eval("document.form1.group"+row+"2.options[z] = null;"); 
        }

        eval("document.form1.group"+row+"2.options[0] = new Option('none', 'none');" );	// add non option to group N2
        for (indC2=0; indC2<menu[indC1].length; indC2++) {	// reset all options in group N2
				// indC2 is the index of Column 2
          eval("document.form1.group"+row+"2.options[indC2+1] = new Option(menu[indC1][indC2], menu[indC1][indC2]);" );
            // set options of groupN2 from the menu array, move index of options up by one
//           eval("document.form1.group"+row+"2.options[k] = new Option('opt '+indC1+' '+k, 'baba '+indC1+' '+k);" );
        }
//       eval("document.form1.group"+row+"2.options[0].selected = true;");// unnecessary, sets groupN2 to have option0 selected
        eval("document.form1.group"+row+"1.options[0] = new Option('none', 'none');" );

        for (z = eval("document.form1.group"+row+"1.options.length"); z>=1; z--) {
          eval("document.form1.group"+row+"1.options[z] = null;"); 
        }
        for (org=0; org<orig_menu_name.length; org++) {	// reset menu options for group N1
          eval("document.form1.group"+row+"1.options[org] = new Option(orig_menu_name[org], orig_menu_val[org]);" );
//           eval("document.form1.group"+row+"1.options[org] = new Option(orig_menu_name[org], 'new '+indC1+' '+org);" );
        } // for (org=0; org<orig_menu_name.length; org++)

//         for (indC2=1; indC2<eval("document.form1.group"+row+"1.options.length"); indC2++) {	// reset options in group N1
// //         for (indC2=1; indC2<5; indC2++) 	// reset all 5 options in group N1
//           eval("document.form1.group"+row+"1.options[indC2] = new Option('select '+row+' 1 '+indC2, 'new '+indC1+' '+indC2);" );
//             // set options of groupN1 from the menu array
//         }
        for (indC2=1; indC2<eval("document.form1.group"+row+"3.options.length"); indC2++) {	// reset options in group N3
//         for (indC2=1; indC2<5; indC2++) 	// reset all 5 options in group N3
          eval("document.form1.group"+row+"3.options[indC2] = new Option('select '+row+' 1 '+indC2, 'new '+indC1+' '+indC2);" );
            // set options of groupN1 from the menu array
        }
//         eval("document.form1.group"+row+"1.options[11] = new Option('select '+row+' 1 '+indC1, 'new one '+row+' 1 '+indC1);" );
        len = eval("document.form1.group"+row+"1.options.length");
        eval("document.form1.group"+row+"1.options[len] = new Option(orig_menu_name[indC1], orig_menu_val[indC1]);" );
          // create option5 of groupN1 to be like the selected option
        eval("document.form1.group"+row+"1.options[len].selected = true;");
          // set group N1 to have option5 selected (can't be the selected or it will loop, can't be 0 because it will grey out)
      }
    }
  } // for (row = 0; row<$rows; row++)
} // function checkifempty()
checkifempty();					// initialize values
// if (document.all) { setInterval("checkifempty()",100); }	// check values every 100 ms

// function clearmenu(m) {
//   options = m.options;
//   document.forms[0].doohey.value += options.length;
//   for (var i=options.length; i>=1; i--) options[i] = null;
// }

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
