#!/usr/bin/perl 

use CGI;
use strict;
use Jex;

my ($header, $footer) = &cshlNew();

my $query = new CGI;

print "Content-type: text/html\n\n";

$header =~ s/<\/head>/<script type="text\/javascript" src="http:\/\/tazendra.caltech.edu\/~azurebrd\/cgi-bin\/testing\/javascript\/dynamic_text\/test.js"><\/script>\n<\/head>/;

print "$header\n";


print "BODY HERE<BR>\n";

print << "EndOfText";
<form name="hideOrShow">
<input type="text" id="txtToHide" onfocus="hide(this.form,1)"/>
<textArea id="txtArea" style="overflow:auto;" onblur="hide(this.form,2)"></textArea>
</form>
EndOfText

print "$footer\n";

__END__

print "Content-type: text/html\n\n";
print "$header";

<style type="text/css">
	.inv{
		display:none;
	}
</style>
<script type="text/JavaScript"> 

	window.onload = function() {
		document.getElementById('txtArea').className = 'inv';
	}

	function hide(f,hideWhich){
		var toHide,toShow;

		if(hideWhich == 1){
			toHide = 'txtToHide';
			toShow = 'txtArea';
		}else{
			toHide = 'txtArea';
			toShow = 'txtToHide';
		}

		document.getElementById(toHide).className = 'inv';
		document.getElementById(toShow).className = '';
		document.getElementById(toShow).value = document.getElementById(toHide).value;
		if(hideWhich == 1){ document.getElementById(toShow).focus(); }
	}
</script> 
</head>
<body>
<form name="hideOrShow">
<input type="text" id="txtToHide" onfocus="hide(this.form,1)"/>
<textArea id="txtArea" style="overflow:auto;" onblur="hide(this.form,2)"></textArea>
</form>
</body>
</html>
