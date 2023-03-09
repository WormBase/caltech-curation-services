#!/usr/bin/perl 

use strict;
use CGI;
use Jex;

my $query = new CGI;
my $htmltitle = 'Trying JavaScript Form';
my ($header, $footer) = &cshlNew($htmltitle);

&startHtml();
&process();
&printHtmlForm();
&endHtml();

sub process {
  my $action;                   # what user clicked
  unless ($action = $query->param('action')) { $action = 'none'; }

  if ($action eq 'Go !') { 
    my @vars = qw( username password textarea file peripherals browser hobbies color );
    foreach $_ (@vars) {
      my ($var, $val) = &getHtmlVar($query, $_);
      if ($val =~ m/\S/) {				# if value entered
        print "$_ : $val<BR>\n";
      } # if ($val =~ m/\S/)
    } # foreach $_ (@vars)
  } # if ($action eq 'Go !')

} # sub process

sub startHtml {
  print "Content-type: text/html\n\n";
  print "$header\n";
#   print <<"EndOfText";
# <HTML>
#   <HEAD><TITLE>Trying JavaScript Form</TITLE></HEAD>
#   <BODY>
# EndOfText
} # sub startHtml

sub endHtml {
  print "$footer\n";
} # sub endHtml

sub printHtmlForm {
  print <<"EndOfText";
    <FORM name "everything">
      <TABLE border = "border" cellpadding="5">
        <TR>
          <TD>Username<BR>[1]<input type="text" name="username" size="15"></TD>
          <TD>Password<BR>[2]<input type="password" name="password" size="15"></TD>
          <TD rowspan="4">Input Events[3]<BR>
            <TEXTAREA name="textarea" rows="20" cols="28"></TEXTAREA></TD>
          <TD rowspan="4" align="center" valign="center">
            [9]<INPUT TYPE="button" value="Clear" name="clearbutton"><BR>
            [10]<INPUT TYPE="submit" value="Go !" name="action"><BR>
            [11]<INPUT TYPE="reset" value="Reset" name="resetbutton"><BR></TD>
        </TR>
        <TR>
          <TD colspan="2">
            Filename : [4]<INPUT TYPE="file" name="file" size="15"></TD>
        </TR>
        <TR>
          <TD>My Computer Peripherals :<BR>
            [5]<INPUT TYPE="checkbox" name="peripherals" value="modem">56k Modem<BR>
            [5]<INPUT TYPE="checkbox" name="peripherals" value="printer">Printer<BR>
            [5]<INPUT TYPE="checkbox" name="peripherals" value="tape">Tape Backup<BR></TD>
          <TD>My Web Browser :<BR>
            [6]<INPUT TYPE="radio" name="browser" value="nn">Netscape<BR>
            [6]<INPUT TYPE="radio" name="browser" value="ie">Internet Explorer<BR>
            [6]<INPUT TYPE="radio" name="browser" value="other">Other<BR></TD>
        </TR>
        <TR>
          <TD>My hobbies : [7]<BR>
            <SELECT MULTIPLE="multiple" name="hobbies" size="4">
              <OPTION VALUE="programming">Code
              <OPTION VALUE="surfing">Browse
              <OPTION VALUE="caffine">Yuck
              <OPTION VALUE="annoying">Yuck II
            </SELECT></TD>
          <TD align="center" valign="center">Fav Color :<br>[8]
            <SELECT NAME="color">
              <OPTION VALUE="red">Red		<OPTION VALUE="green">Green		
              <OPTION VALUE="blue">Blue		<OPTION VALUE="white">White		
              <OPTION VALUE="violet">Violet	<OPTION VALUE="black">Black		
            </SELECT></TD>
        </TR>
      </TABLE>
    </FORM>

    <DIV ALIGN="center">
      <TABLE border="4" bgcolor="pink" cellspacing="1" cellpadding="4">
        <TR>
          <TD ALIGN="center"><B>Form Elements</B></TD>
          <TD>[1] Text</TD> <TD>[2] Password</TD> <TD>[3] Textarea</TD>
          <TD>[4] FileUpload</TD> <TD>[5] Checkbox</TD>
        </TR>
        <TR>
          <TD>[6] Radio</TD> <TD>[7] Select (list)</TD>
          <TD>[8] Select (menu)</TD> <TD>[9] Button</TD>
          <TD>[10] Submit</TD> <TD>[11] Reset</TD>
        </TR>
      </TABLE>
    </DIV>

    <SCRIPT>
    function report(element, event) {
      var elmtname = element.name;
      if ((element.type == "select-one") || (element.type == "select-multiple")) {
        value = " ";
        for(var i=0; i<element.options.length; i++)
          if (element.options[i].selected) 
            value += element.options[i].value + " ";
      } 
      else if (element.type = "textarea") value = "...";
      else value = element.value
      var msg = event + ": " + elmtname + ' (' + value + ')\n';
      var t = element.form.textarea;
      t.value = t.value + msg;
    }

    function addhandlers(f) {
      for (var i=0; i < f.elements.length; i++) {
        var e = f.elements[i];
        e.onclick = function() { report(this, 'Click'); }
        e.onchange = function() { report(this, 'Change'); }
        e.onfocus = function() { report(this, 'Focus'); }
        e.onblue = function() { report(this, 'Blur'); }
        e.onselect = function() { report(this, 'Select'); }
      }
      f.clearbutton.onclick = function() {
        this.form.textarea.value=''; report(this,'Click');
      }
      f.submitbutton.onclick = function() {
        report(this,'Click'); return false;
      }
      f.resetbutton.onclick = function() {
        this.form.reset(); report(this,'Click'); return false;
      }
    }
    
    addhandlers(document.everything);
    </SCRIPT>

  </BODY>
</HTML>
EndOfText
} # sub printHtmlForm
