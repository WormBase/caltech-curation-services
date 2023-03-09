#!/usr/bin/perl -T

use strict;
use CGI;
use Jex;			# untaint, getHtmlVar, cshlNew

my ($header, $footer) = &cshlNew();

my $query = new CGI;
my $firstflag = '1';
my %hash;

print "Content-type: text/html\n\n";
print "$header\n";		# make beginning of HTML page

# print "<HTML><HEAD>\n";
#     print "<SCRIPT LANGUAGE\"JavaScript1.3\">\n";
#     print "<!-- document.write(\"Hello, net !\") -->\n";
#     print "function bar(widthPct) {\n";
#     print "  document.write("<HR ALIGN='left' WIDTH=" + widthPct + "%>")
#     print "}\n";
# 
# <INPUT TYPE="button" VALUE="Press Me" onClick="myfunc('astring')">
#     print "</SCRIPT>\n";
# print "</HEAD></BODY>\n";

&javascriptHash();
&initHash();
&process();			# see if anything clicked
&display();			# show form as appropriate
print "$footer"; 		# make end of HTML page

sub javascriptHash {
  print <<"EndOfText";
    <script language="JavaScript1.1">

    function dynoMenu(txt,url) {
      this.txt=txt;
      this.url=url;
      this.opened=false;
      this.cnt=0;
      this.sub=new Array();
      this.l=null;
      this.i=null;
    }

    mymenu  = new dynoMenu(null,null);
    mymenu.sub[0] = new dynoMenu("Cathegory 1",null);
    mymenu.sub[0].sub[0] = new dynoMenu("Sub 1-1",null);
    mymenu.sub[0].sub[0].sub[0] = new dynoMenu("Sub 1-1-1","file111.html");
    mymenu.sub[0].sub[0].sub[1] = new dynoMenu("Sub 1-1-2","file112.html");
    mymenu.sub[0].sub[1] = new dynoMenu("Sub 1-2","file12x.html");
    mymenu.sub[0].sub[1].sub[0] = new dynoMenu("Sub 1-2-1","file121.html");
    mymenu.sub[0].sub[1].sub[1] = new dynoMenu("Sub 1-2-2","kaka.html");
    mymenu.sub[0].sub[2] = new dynoMenu("file 1-3-1","file131.html");

    mymenu.sub[1] = new dynoMenu("Cathegory 2",null);
    mymenu.sub[1].sub[0] = new dynoMenu("Sub 2-1",null);
    mymenu.sub[1].sub[0].sub[0] = new dynoMenu("Sub 2-1-1","file211.html");
    mymenu.sub[1].sub[0].sub[1] = new dynoMenu("Sub 2-1-2","file212.html");
    mymenu.sub[1].sub[1] = new dynoMenu("Sub 2-2",null);
    mymenu.sub[1].sub[1].sub[0] = new dynoMenu("Sub 2-2-1","file221.html");
    mymenu.sub[1].sub[1].sub[1] = new dynoMenu("Sub 2-2-2","file222.html");

    mymenu.sub[2] = new dynoMenu("Cathegory 3",null);
    mymenu.sub[2].sub[0] = new dynoMenu("Sub 3-1",null);
    mymenu.sub[2].sub[0].sub[0] = new dynoMenu("Sub 3-1-1","file311.html");
    mymenu.sub[2].sub[0].sub[1] = new dynoMenu("Sub 3-1-2","file312.html");
    mymenu.sub[2].sub[1] = new dynoMenu("Sub 3-2",null);
    mymenu.sub[2].sub[1].sub[0] = new dynoMenu("Sub 3-2-1","file321.html");
    mymenu.sub[2].sub[1].sub[1] = new dynoMenu("Sub 3-2-2","file322.html");

    mymenu.sub[3] = new dynoMenu("file 4-1-1","file411.html");

    function clearmenu(m) {
      options  = m.options;
      for (var i=options.length; i>=1; i--) options[i] = null;
      options[0].selected = true;
    }
    
    function setmenu(m,optArray) {
      options  = m.options;
      clearmenu(m);
      if(optArray!=null) {
        for (var i = 0; i < optArray.length; i++)
          options[i+1]=new Option(optArray[i].txt,optArray[i].url);
        }
      options[0].selected = true;
    }
    
    function setitems(N) {
      clr=false;
      if(N<depth-1) {
        mmm = mymenu;
        for(i=0;i<=N;i++) {
          sel = eval("document.mm.m"+i);
          selinx = sel.selectedIndex-1;
          if(selinx<0) break;
          mmm=mmm.sub[selinx];
        }
        sel = eval("document.mm.m"+(i));
        setmenu(sel,mmm.sub);
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
        openwin(urrl);
      }
    }

    function openwin(url) {
      if(url!=null) window.open(url,"_blank"); }
    
    var depth=3;
    var d=document;
    
    
    d.writeln("<FORM name='mm'>");
    for(i=0;i<depth;i++) {
      d.writeln("<SELECT name='m"+i+"' onChange='setitems("+i+")'>");
      for(j=0;j<5;j++) d.writeln("<option >----Please, select-----");
      d.writeln("</select>");
    }
    d.writeln("</form>");
    setitems(0,0);
    </script>

EndOfText
} # sub javascriptHash

sub initHash {
  @{ $hash{bob} } = qw(dingo bobo wally);
  @{ $hash{tim} } = qw(reveka prodigal);
  foreach my $key (sort keys %hash) {
    print "KEY : $key<BR>\n";
    foreach ( @{ $hash{$key} }) { print "VAL : $_<BR>\n"; }
  } # foreach my $key (sort keys %hash)
} # sub initHash

sub process {			# see if anything clicked
  my $action;			# what user clicked
  unless ($action = $query->param('action')) { $action = 'none'; }

  if ($action eq 'Go !') { 
    

    my @vars = qw(sequence method laboratory author date strain delivered_by predicted_gene locus reference phenotype remark);
    foreach $_ (@vars) { 
      my ($var, $val) = &getHtmlVar($query, $_);
      if ($val =~ m/\S/) { 	# if value entered
        if ($_ eq 'sequence') {	# print main tag if sequence
          print "RNAi : [$val]<BR>\n";
        } # if ($_ eq 'sequence')
        print "@{[ucfirst($var)]} \"$val\" <BR>\n";
      } # if ($val) 
    } # foreach $_ (@vars) 
    print "<P><P><P><H1>Thank you, your info will be updated shortly.</H1>\n";
  } # if ($action eq 'Go !') 
} # sub process


sub display {			# show form as appropriate
  if ($firstflag) { # if first or bad, show form 
    
    print "<FORM METHOD=\"POST\" ACTION=\"javascript.cgi\">";
    print "<TABLE>\n";
    print "<TR>";

    print "<TD><SELECT NAME=\"elem\" SIZE=10>\n";
    foreach ( sort keys %hash ) { print "<OPTION>$_</OPTION>\n"; }
    print "</SELECT></TD>";

    print "<TD><SELECT NAME=\"attr\" SIZE=10>\n";
    foreach my $key (sort keys %hash) {
      foreach ( @{ $hash{$key} }) { print "<OPTION>$_</OPTION>\n"; }
    } # foreach my $key (sort keys %hash)
    print "</SELECT></TD>";

    print "</TR>";

    print "<TR><TD> </TD>\n";
    print "<TD><INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Go !\">\n";
    print "<INPUT TYPE=\"reset\"></TD>\n";
    print "</TR>\n";
    print "</TABLE>\n";
    print "</FORM>\n";

    print <<"EndOfText";


<A NAME="form"><H1>NEW RNAi SUBMISSION :</H1></A>

<FORM METHOD="POST" ACTION="javascript.cgi">
<TABLE>

<TR>
<TD ALIGN="right"><b>Locus : </b></TD>
<TD><TABLE><INPUT NAME="locus" VALUE="" SIZE=20></TABLE></TD>
</TR>

<TR>
<TD ALIGN="right"><b>Phenotype :</b></TD>
<TD><TABLE><INPUT NAME="phenotype" VALUE="" SIZE=30></TABLE></TD>
</TR>

<TR><TD COLSPAN=2> </TD></TR>
<TR>
<TD> </TD>
<TD><INPUT TYPE="submit" NAME="action" VALUE="Go !">
    <INPUT TYPE="reset"></TD>
</TR>
</TABLE>

</FORM>
If you have any problems, questions, or comments, please strain <A HREF=\"mailto:azurebrd\@minerva.caltech.edu\">azurebrd\@minerva.caltech.edu</A>
EndOfText

  } # if (firstflag) show form 
} # sub display
