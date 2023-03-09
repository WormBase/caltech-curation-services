#!/usr/bin/perl

use strict;
use Jex;
use CGI;

my $query = new CGI;


print "Content-type: text/html\n\n";
my $title = 'Blih CGI';
# my ($header, $footer) = &cshlNew($title);
# print "$header\n";              # make beginning of HTML page
my $menu2 = &readVals();	# read menu from file
# my @names = &readDtd();	# read menu from michael dtd
my $menu = &readDtd2();		# read menu for this from dtd
&process();
&display($menu, $menu2);
# print "$footer\n";

sub process {
  my $action = 'NO ACTION';                   # what user clicked
  unless ($action = $query->param('action')) { $action = 'none'; }

  print "ACTION : $action<P>\n";

  if ($action eq 'Submit') {
    my $oop; my $val;
    print "<TABLE border=2>\n";
    ($oop, $val) = &getHtmlVar($query, 'thingie');
    print "<TR><TD>thingie</TD><TD>$val</TD></TR>\n";
    ($oop, $val) = &getHtmlVar($query, 'doohey');
    print "<TR><TD>doohey</TD><TD>$val</TD></TR>\n";
    ($oop, $val) = &getHtmlVar($query, 'm0');
    print "<TR><TD>m0</TD><TD>$val</TD></TR>\n";
    ($oop, $val) = &getHtmlVar($query, 'm1');
    print "<TR><TD>m1</TD><TD>$val</TD></TR>\n";
    ($oop, $val) = &getHtmlVar($query, 'm2');
    print "<TR><TD>m2</TD><TD>$val</TD></TR>\n";
    print "</TABLE>\n";
  }

  else { 1; }

} # sub process

sub readDtd2 {
  my $dtdfile = 'janus.dtd';
  $/ = '';				# set <> to paragraph mode
  open (DTD, "$dtdfile") or die "Can't open DTD file $dtdfile.";
  my $menu = 'mymenu = new dynoMenu(null,null);' . "\n";	
					# init menu
  my $count1 = 0;			# count of first submenu
  while (my $entry = <DTD>) {		# while there are paragraphs in dtd
    next unless ($entry =~ m/ELEMENT.*!--/); 	# skip non-data lines
    my @lines = split /\n/, $entry;	# break paragraphs into lines
    my ($main_key, $main_name) = $lines[0] =~ m/ELEMENT\s+(\w\w)\w*? .*!-- (.*?) --/;
    $menu .= "mymenu.sub[$count1] = new dynoMenu(\"$main_name\", \"$main_key\");\n";
					# insert first column value
    foreach my $line (@lines) {		# check each line for implied attributes for second column
      if ($line =~ /<!ATTLIST\s+(\w+)\s+(\w+)\s+\(((\w|\s|\|)+)\)\s+\#IMPLIED> <!--\s+\(((-|\w|\s|\|)+)\)\s+((\w|\s|\,)+)\s-->/) {
        my $official = $2;
        my $label = $7;
        my @values = split(/\s\|\s/, $5);
        my $count2 = 0;			# count of second submenu
        foreach my $value (@values) {
          $value =~ s/^\w+\-//g;	# take out the first 2 letters and hyphen
          $menu .= "mymenu.sub[$count1].sub[$count2] = new dynoMenu(\"$value\", \"$value\");\n";
					# insert second column values (if any)
          $count2++;			# add to counter
        } # foreach my $value (@values)
      } # if ..
    } # foreach my $line (@lines)
    $count1++;				# add to counter
  } # while (my $line = <DTD>)
  close (DTD);
  $/ = "\n";				# reset <> to line at a time
  return $menu;
} # sub readDtd2

sub readDtd {
  my $dtdfile = 'janus.dtd';
  my @names_codes_and_attributes = ();
  open (DTD, "$dtdfile") or die "Can't open DTD file $dtdfile.";
  while (my $line = <DTD>) {
    chomp ($line);
    if ($line =~ /<!ATTLIST\s+(\w+)\s+(\w+)\s+\(((\w|\s|\|)+)\)\s+\#IMPLIED> <!--\s+\(((-|\w|\s|\|)+)\)\s+((\w|\s|\,)+)\s-->/) {
      my $official_attribute_name = $2;
      my $label = $7;
      my @values = split(/\s\|\s/, $5);
      foreach my $value (@values) {
        my $key = $official_attribute_name . " " . $value . " (" .  $label . ")";
print "KEY $key : OFF $official_attribute_name : VAL $value : LAB $label<BR>\n";
        push @names_codes_and_attributes, $key;
      } # foreach my $value (@values)
    } # if ..
  } # while (my $line = <DTD>)
  close (DTD);
  return (@names_codes_and_attributes);
} # sub readDtd

sub readVals {			# get menu data from .dat file
  my %hash;
  my $file = 'blih.dat';	# dat file with data for javascript menu
  my $menu = 'mymenu2 = new dynoMenu(null,null);' . "\n";	# init menu
  open (IN, "<$file") or die "Cannot open $file : $!";
  while (<IN>) {
    chomp;
    my ($coord, $vals) = split/\t/, $_;
    my @coords = split//, $coord;
    $menu .= 'mymenu2';
    foreach (@coords) { $menu .= ".sub[$_]"; }
    $menu .= "= new dynoMenu($vals);\n";
  } # while (<IN>)
  close (IN) or die "Cannot close $file : $!";
  return $menu;
} # sub readVals

sub display {			# display page
#   my $menu = shift;		# the defined menu from dtd file
  my ($menu, $menu2) = @_;	# the defined menu from .dat and dtd files
#   my $moo = 'dynoMenu("ooM", "oom");';	# sample val to pass
#   // mymenu.sub[0].sub[0] = new $moo;

  print <<"EndOfText";
<html>
<body>

<script language="JavaScript1.1">

//---==+0+==--- USER DEFINABLE SECTION ---==+0+==---

$menu		// define menu

$menu2

// mymenu  = new dynoMenu(null,null);
// mymenu.sub[0] = new dynoMenu("Cows", null);
// mymenu.sub[0].sub[0] = new 'dynoMenu("Moo", "moo");';
// mymenu.sub[0].sub[0].sub[0] = new dynoMenu("Ride", "ride");
// mymenu.sub[0].sub[0].sub[1] = new dynoMenu("Dance", "dance");
// mymenu.sub[0].sub[1] = new dynoMenu("Wanda", null);
// mymenu.sub[0].sub[1].sub[0] = new dynoMenu("Stare","stare");
// mymenu.sub[0].sub[1].sub[1] = new dynoMenu("Sit","sit");
// 
// mymenu.sub[1] = new dynoMenu("Guys",null);
// mymenu.sub[1].sub[0] = new dynoMenu("Sheep", null);
// mymenu.sub[1].sub[0].sub[0] = new dynoMenu("Fly"," fly");
// mymenu.sub[1].sub[0].sub[1] = new dynoMenu("Poke"," poke");
// mymenu.sub[1].sub[1] = new dynoMenu("Shark", null);
// mymenu.sub[1].sub[1].sub[0] = new dynoMenu("Munch", "munch");
// mymenu.sub[1].sub[1].sub[1] = new dynoMenu("Swim", "swim");

//---==+0+==---END OF USER DEFINABLE SECTION ---==+0+==---

function dynoMenu(txt,url) {
  this.txt=txt;
  this.url=url;
  this.sub=new Array();
}

function clearmenu(m) {
  options  = m.options;
  for (var i=options.length; i>=1; i--) options[i] = null;  
  options[0].selected = true;
}

function setmenu2(m,optArray) {
  options  = m.options;
  clearmenu(m);
  if(optArray!=null) {
  for (var i = 0; i < optArray.length; i++)
    options[i+1]=new Option(optArray[i].txt, optArray[i].url);
    document.forms[0].thingie.value = options[i+1] + ' ';
    // document.forms[0].thingie.value += options[i+1] + ' ';
  }
  options[0].selected = true;
}

function setmenu(m,optArray) {
  options  = m.options;
  clearmenu(m);
  if(optArray!=null) {
  for (var i = 0; i < optArray.length; i++)
    options[i+1]=new Option(optArray[i].txt, optArray[i].url);
    document.forms[1].thingie.value = options[i+1] + ' ';
    // document.forms[0].thingie.value += options[i+1] + ' ';
  }
  options[0].selected = true;
}

function setitems2(N) {
  clr=false;
  if(N<depth2-1) {
    mmm = mymenu2;
    for(i=0;i<=N;i++) {
      sel = eval("document.nn.m"+i);
      selinx = sel.selectedIndex-1;
      document.forms[0].doohey.value = sel.selectedIndex;
      if(selinx<0) break;
      mmm=mmm.sub[selinx];
    }
    sel = eval("document.nn.m"+(i));
    setmenu2(sel,mmm.sub);
//     options[2] = new Option("BOO", "boo");
//     document.forms[0].thingie.value += 'boo ';
    i++;
    while(i<depth2) {
      sel = eval("document.nn.m"+(i));
      clearmenu(sel);
      i++;
    }
  }

  sel = eval("document.nn.m"+N);
  selinx = sel.selectedIndex;
  if(selinx>0) {
    urrl=sel.options[selinx].value;
    if(urrl!='null')
    document.forms[0].thingie.value = urrl;
  }
}

function setitems(N) {
  clr=false;
  if(N<depth-1) {
    mmm = mymenu;
    for(i=0;i<=N;i++) {
      sel = eval("document.mm.m"+i);
      selinx = sel.selectedIndex-1;
      document.forms[1].doohey.value = sel.selectedIndex;
      if(selinx<0) break;
      mmm=mmm.sub[selinx];
    }
    sel = eval("document.mm.m"+(i));
    setmenu(sel,mmm.sub);
//     options[2] = new Option("BOO", "boo");
//     document.forms[0].thingie.value += 'boo ';
    i++;
    while(i<depth) {
      sel = eval("document.mm.m"+(i));
      clearmenu(sel);
      i++;
    }
  }

  sel = eval("document.mm.m"+N);
  selinx = sel.selectedIndex;
  if(selinx>0) {
    urrl=sel.options[selinx].value;
    if(urrl!='null')
    document.forms[1].thingie.value = urrl;
  }
}



var depth=2;
var depth2=3;
var d=document;

d.writeln("<FORM name='nn'>");
for(i=0;i<depth2;i++) {
  d.writeln("<SELECT size=5 name='m"+i+"' onChange='setitems2("+i+")'>");
  for(j=0;j<5;j++) d.writeln("<option >----Please, select-----");
  d.writeln("</select>");
}
d.writeln("<br><input type='text' name='thingie' size='50' onchange='setitems(1);'>");
d.writeln("<br><input type='text' name='doohey' size='50' onchange='setitems(1);'>");
d.writeln("<br><input type='submit' name='action' value='Submit'>");
d.writeln("</form>");
setitems2(0);

d.writeln("<FORM name='mm'>");
for(i=0;i<depth;i++) {
  d.writeln("<SELECT size=5 name='m"+i+"' onChange='setitems("+i+")'>");
  for(j=0;j<5;j++) d.writeln("<option >----Please, select-----");
  d.writeln("</select>");
}
d.writeln("<br><input type='text' name='thingie' size='50' onchange='setitems(1);'>");
d.writeln("<br><input type='text' name='doohey' size='50' onchange='setitems(1);'>");
d.writeln("<br><input type='submit' name='action' value='Submit'>");
d.writeln("</form>");

setitems(0);
</script>



</body>
</html>

EndOfText
} # sub display
