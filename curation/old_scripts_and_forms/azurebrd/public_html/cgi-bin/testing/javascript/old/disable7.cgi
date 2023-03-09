#!/usr/bin/perl -w

# This form is an example of working javascript to disable (grey-out) fields.
# This form allows SELECT fields to enable other SELECT fields and write their
# values to a TEXT field.  This form updates onchange instead of every 100ms.
# This form allows a variable number of rows of SELECT fields by using eval()
# on the document.
# This form allows a menu[][] to be written for the form to load values from.
# 2003 02 09
# This form allows a menu[][] to be written with an arbitrary amount of
# arbitrary values.   2003 02 10
# This form reads in the dtd, puts it in a perl variable and prints the 
# variable into the javascript definition.   2003 02 10
# This form is the same as disable6, but without commented-out junk.  Also
# requires data in 3 mandatory fields.   2003 02 10

use strict;
use Jex;
use CGI;

my $query = new CGI;

my $rows = 2;			# amount of rows of select fields


print "Content-type: text/html\n\n";
my $title = 'Disable CGI';
my $menu = &readDtd();				# get javascript menu from dtd

my ($header, $footer) = &cshlNew($title);
print "$header\n";              # make beginning of HTML page
&process();
&display();
print "$footer\n";

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

$menu		// pass dtd menu to javascript

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
  
    // check if anything chosen on group01 to enable group02
  for (row = 0; row<$rows; row++) {				// for each of the rows
    eval("document.form1.group"+row+"2.disabled=true");	// initialize group02 as disabled	
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
        }
        eval("document.form1.group"+row+"1.options[0] = new Option('none', 'none');" );

        for (z = eval("document.form1.group"+row+"1.options.length"); z>=1; z--) {
          eval("document.form1.group"+row+"1.options[z] = null;"); 
        }
        for (org=0; org<orig_menu_name.length; org++) {	// reset menu options for group N1
          eval("document.form1.group"+row+"1.options[org] = new Option(orig_menu_name[org], orig_menu_val[org]);" );
        } // for (org=0; org<orig_menu_name.length; org++)

        for (indC2=1; indC2<eval("document.form1.group"+row+"3.options.length"); indC2++) {	// reset options in group N3
          eval("document.form1.group"+row+"3.options[indC2] = new Option('select '+row+' 1 '+indC2, 'new '+indC1+' '+indC2);" );
            // set options of groupN1 from the menu array
        }
        len = eval("document.form1.group"+row+"1.options.length");
        eval("document.form1.group"+row+"1.options[len] = new Option(orig_menu_name[indC1], orig_menu_val[indC1]);" );
          // create last option of groupN1 to be like the selected option
        eval("document.form1.group"+row+"1.options[len].selected = true;");
          // set group N1 to have the last option selected 
	  // (can't be the selected or it will loop, can't be 0 because it will grey out)
      }
    }
  } // for (row = 0; row<$rows; row++)

  checkmandatory();
} // function checkifempty()
checkifempty();					// initialize values

function checkmandatory() {			// for no real reason make 3 mandatory fields necessary
  if ( (document.form1.thingie1.value=='') ||
       (document.form1.thingie2.value=='') ||
       (document.form1.thingie3.value=='')) {
    document.form1.action.disabled=true
  } else {
    document.form1.action.disabled=false
  }
} // function checkifempty()


</script>



</body>
</html>

EndOfText
} # sub display



sub readDtd {
  my $dtdfile = 'janus.dtd';
  $/ = '';                              # set <> to paragraph mode
  open (DTD, "$dtdfile") or die "Can't open DTD file $dtdfile.";
  my $menu1 = '';					# parts of array
  my $menu2 = 'var menu = new Array();' . "\n";		# full array or arrays
  my @orig_menu_name = ('none');
  my @orig_menu_val = ('none');
                                        # init menu
  my $count1 = 1;                       # count of first submenu
  while (my $entry = <DTD>) {           # while there are paragraphs in dtd
    next unless ($entry =~ m/ELEMENT.*!--/);    # skip non-data lines
    my @lines = split /\n/, $entry;     # break paragraphs into lines
    my ($main_val, $main_name) = $lines[0] =~ m/ELEMENT\s+(\w\w)\w*? .*!-- (.*?) --/;
    push @orig_menu_name, $main_name;
    push @orig_menu_val, $main_val;
    my @groupN2_vals = qw();		# array of values for menu$count1
    foreach my $line (@lines) {         # check each line for implied attributes for second column
      if ($line =~ /<!ATTLIST\s+(\w+)\s+(\w+)\s+\(((\w|\s|\|)+)\)\s+\#IMPLIED> <!--\s+\(((-|\w|\s|\|)+)\)\s+((\w|\s|\,)+)\s-->/) {
        my @values = split(/\s\|\s/, $5);
        foreach my $value (@values) {
          $value =~ s/^\w+\-//g;        # take out the first 2 letters and hyphen
          push @groupN2_vals, $value;
        } # foreach my $value (@values)
      } # if ..
    } # foreach my $line (@lines)
    my $groupN2_vals = join"', '", @groupN2_vals;
    $menu1 .= 'var menu' . $count1 . '= new Array(\'' . $groupN2_vals .  '\');' . "\n";
    $menu2 .= 'menu[' . $count1 . '] = menu' . $count1 . ";\n";
    $count1++;                          # add to counter
  } # while (my $line = <DTD>)
  close (DTD);
  $/ = "\n";                            # reset <> to line at a time
  my $orig_menu_name = join"', '", @orig_menu_name;
  my $orig_menu_val = join"', '", @orig_menu_val;
  my $menu3 = 'var orig_menu_name = new Array(\'' . $orig_menu_name .  '\');' . "\n";
  my $menu4 = 'var orig_menu_val = new Array(\'' . $orig_menu_val .  '\');' . "\n";
  $menu = $menu1 . $menu2 . $menu3 . $menu4;
  return $menu;
} # sub readDtd


