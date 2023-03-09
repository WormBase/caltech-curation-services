#!/usr/bin/perl -T

use strict;
use CGI;
use Jex;			# untaint, getHtmlVar, cshlNew

my $htmltitle = 'thing';
# my ($header, $footer) = &cshlNew($htmltitle);
my ($header, $footer) = &getHeaderNFooter($htmltitle);

my $query = new CGI;
my $firstflag = '1';

print "Content-type: text/html\n\n";
print "$header\n";		# make beginning of HTML page

&javascriptHash();
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
      this.sub=new Array();

      // this.cnt=0;
      // this.l=null;
      // this.i=null;
    }
 
    bob = ' oop ';

    mymenu  = new dynoMenu(null,null);
    mymenu.sub[0] = new dynoMenu("Category 1",null);
    mymenu.sub[0].sub[0] = new dynoMenu("Sub 1-1",null);
    mymenu.sub[0].sub[0].sub[0] = new dynoMenu("Sub 1-1-1","file111.html");
    mymenu.sub[0].sub[0].sub[1] = new dynoMenu("Sub 1-1-2","file112.html");
    mymenu.sub[0].sub[1] = new dynoMenu("Sub 1-2","file12x.html");
    mymenu.sub[0].sub[1].sub[0] = new dynoMenu("Sub 1-2-1","file121.html");
    mymenu.sub[0].sub[1].sub[1] = new dynoMenu("Sub 1-2-2","kaka.html");
    mymenu.sub[0].sub[2] = new dynoMenu("file 1-3-1","file131.html");

    mymenu.sub[1] = new dynoMenu("Category 2",null);
    mymenu.sub[1].sub[0] = new dynoMenu("Sub 2-1",null);
    mymenu.sub[1].sub[0].sub[0] = new dynoMenu("Sub 2-1-1","file211.html");
    mymenu.sub[1].sub[0].sub[1] = new dynoMenu("Sub 2-1-2","file212.html");
    mymenu.sub[1].sub[1] = new dynoMenu("Sub 2-2",null);
    mymenu.sub[1].sub[1].sub[0] = new dynoMenu("Sub 2-2-1","file221.html");
    mymenu.sub[1].sub[1].sub[1] = new dynoMenu("Sub 2-2-2","file222.html");

    mymenu.sub[2] = new dynoMenu("Category 3",null);
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
      options = m.options;
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
//         setmenu(sel,mmm.sub);
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
        if(urrl!='null') {
          bob = urrl;
          openwin(urrl);
          return bob;
        }
      }
    }

    function openwin(url) {
      if(url!=null) window.open(url,"_blank"); }
    
    var depth=3;
    var d=document;
    
    
    d.writeln("<FORM name='mm' METHOD='POST' ACTION='javaform.cgi'>");
    for(i=0;i<depth;i++) {
      d.writeln("<SELECT name='m"+i+"' onChange='setitems("+i+")'>");
      for(j=0;j<5;j++) d.writeln("<option >----Please, select-----");
      d.writeln("</select><BR>");
      d.writeln("HELLO " + i + " THINGIE<BR>");
      if (bob != '') { d.writeln("BOB IN " + bob + " IS BOB<BR>"); }
    }
    d.writeln("<INPUT TYPE='submit' value='Go !' name='action'>");
    d.writeln("HELLO THINGIE<BR>");
    d.writeln("</form>");
    bob = setitems(0,0);
    if (bob != '') { d.writeln("BOB " + bob + " IS BOB<BR>"); }
    </script>

EndOfText
} # sub javascriptHash

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
    
  } # if (firstflag) show form 
} # sub display

sub getHeaderNFooter {
  my $title = shift;
  my $header = "<HTML><HEAD><TITLE>$title</TITLE></HEAD><BODY>Start<BR>\n";
  my $footer = "Footer<BR></HTML>\n";
  return ($header, $footer);
} # sub getHeaderNFooter
