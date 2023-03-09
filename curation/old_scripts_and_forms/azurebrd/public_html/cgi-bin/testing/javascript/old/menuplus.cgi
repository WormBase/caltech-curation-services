#!/usr/bin/perl

use strict;
use CGI;

sub untaint {
  my $tainted = shift;
  my $untainted;
  if ($tainted eq "") {
    $untainted = "";
  } else { # if ($tainted eq "")
    $tainted =~ s/[^\w\-.,;:?\/\\@#\$\%\^&*\>\<(){}[\]+=!~|' \t\n\r\f\"€‚ƒ„…†‡ˆ‰Š‹ŒŽ‘’“”•—˜™š›œžŸ¡¢£¤¥¦§¨©ª«¬­®¯°±²³´µ¶·¹º»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþ]//g;	# added \" for wbpaper_editor's gene evidence data 2005 07 14   added \> and \< for wbpaper_editor's abstract data  2005 12 13
    if ($tainted =~ m/^([\w\-.,;:?\/\\@#\$\%&\^*\>\<(){}[\]+=!~|' \t\n\r\f\"€‚ƒ„…†‡ˆ‰Š‹ŒŽ‘’“”•—˜™š›œžŸ¡¢£¤¥¦§¨©ª«¬­®¯°±²³´µ¶·¹º»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþ]+)$/) {
      $untainted = $1;
    } else {
      die "Bad data Tainted in $tainted";
    }
  } # else # if ($tainted eq "")
  return $untainted;
} # sub untaint

sub getHtmlVar {		# get variables from html form and untaint them
  no strict 'refs';		# need to disable refs to get the values
				# possibly a better way than this
  my ($query, $var, $err) = @_;	# get the CGI query val, 
				# get the name of the variable to query->param,
				# get whether to display and error if no such
				# variable found
  unless ($query->param("$var")) {		# if no such variable found
    if ($err) {			# if we want error displayed, display error
      print "<FONT COLOR=blue>ERROR : No such variable : $var</FONT><BR>\n";
    } # if ($err) 
  } else { # unless ($query->param("$var"))	# if we got a value
    my $oop = $query->param("$var");		# get the value
    $$var = &untaint($oop);			# untaint and put value under ref
    return ($var, $$var);			# return the variable and value
  } # else # unless ($query->param("$var"))
  # sample use
  # my @vars = qw(locus sequence clone);	# variables to get from html
  # foreach $_ (@vars) { my ($var, $val) = &getHtmlVar("$_"); }
				# get the value and set the variable and value
  # foreach $_ (@vars) { my ($var, $val) = &getHtmlVar("$_", 1); }
				# same, but with error display flag
} # sub getHtmlVar

my $query = new CGI;

print "Content-type: text/html\n\n";
print <<"EndOfText";
<HTML>
<LINK rel="stylesheet" type="text/css" href="http://tazendra.caltech.edu/~azurebrd/stylesheets/wormbase.css">
<HEAD>
<TITLE>Menu thing</TITLE>
</HEAD>
<BODY bgcolor=#000000 text=#000000 link=#cccccc>
EndOfText
&printHtmlForm();
print "after html form<BR>\n";


sub printHtmlForm {

print <<EndOfText;
<script language="JavaScript1.1">
function ExpandCollapse(item, flag) {
   obj=document.getElementById(item);
   image = document.getElementById("i" + item);

   document.forms[0].three.value = flag;

   if (obj.style.display=="none")
   {
       obj.style.display="block";
       image.src = 'http://dev.textpresso.org/worm/gif/minus.png';
       document.forms[0].one.value = 'plus';
       document.forms[0].two.value = '';
       document.forms[0].check.checked = true
       document.forms[0].checktwo.checked = true
   }
   else
   {
       obj.style.display="none";
       image.src = 'http://dev.textpresso.org/worm/gif/plus.png';
       document.forms[0].two.value = 'minus';
       document.forms[0].one.value = '';
       document.forms[0].check.checked = false
       document.forms[0].checktwo.checked = false
   }
}

</script>
EndOfText

  my $action = 'NO ACTION';                   # what user clicked
  unless ($action = $query->param('action')) { $action = 'none'; }

my $one = '';
my $two = '';

  print "ACTION : $action<P>\n";

  if ($action eq 'submit') {
    (my $var, $one) = &getHtmlVar($query, 'one');
    ($var, $two) = &getHtmlVar($query, 'two');
  }

print "ONE $one ONE<BR>\n";



print "<FORM>\n";
print "<INPUT TYPE='submit' NAME='action' value='submit'><BR>\n";
print "<INPUT NAME=one VALUE=\"$one\" SIZE=20><BR>\n";
print "<INPUT NAME=two VALUE=\"$two\" SIZE=20><BR>\n";
print "<INPUT NAME=three SIZE=20><BR>\n";
print "<INPUT NAME=four SIZE=20><BR>\n";
print "<INPUT TYPE=checkbox NAME=check><BR>\n";

   my $aux =   $query->a({href => "javascript:ExpandCollapse('moreOptions', '$one')"},
                           $query->img({-id => "imoreOptions", -src=>'http://dev.textpresso.org/worm/gif/plus.png'})).
               $query->b($query->span({-style => "color:#5870a3;"}," More search options "));

   $aux .= $query->div({-id => "moreOptions", -style => "display:none"},
                       $query->div({style => "margin-left:1em"}),
                       );
print $aux;


print "<INPUT TYPE=checkbox NAME=checktwo><BR>\n";

print "some text<br>\n";

print "</FORM>\n";

print "some more text<br>\n";

} # sub printHtmlForm


