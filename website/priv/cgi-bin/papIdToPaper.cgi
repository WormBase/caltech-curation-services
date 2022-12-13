#!/usr/bin/env perl

# js redirect to generic.cgi

use CGI;
use Dotenv -load => '/usr/lib/.env';

print <<"EndOfText";
Content-type: text/html

<html>
<script type="text/javascript">
window.location.replace("$ENV{GENERIC_CGI}?action=PapIdToWBPaper");
</script>
</html>
EndOfText
