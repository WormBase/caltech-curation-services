#!/usr/bin/perl

use strict;

my $inputfile = 'index.html';
if ($ARGV[0]) { $inputfile = $ARGV[0]; }
print "Using $inputfile for input\n";
my $outputfile = $inputfile . '.paste';

open (IN, "<$inputfile") or die "Cannot open $inputfile : $!";
open (OUT, ">$outputfile") or die "Cannot create $outputfile : $!";
my $text = ''; my $capture = 0;
while (my $line = <IN>) {
  if ($line =~ m/^<!-- End Body Text -->/) { $capture = 0; }
  if ($capture) { $text .= $line; }
  if ($line =~ m/^<!-- Begin Body Text -->/) { $capture = 1; }
} # while (<IN>) {

if ($text =~ m/<p>/) { $text =~ s/<p>/\n\n/g; }
if ($text =~ m/<P>/) { $text =~ s/<P>/\n\n/g; }

  # lowercase a href
if ($text =~ m/[Aa]\s+[Hh][Rr][Ee][Ff]/) { $text =~ s/[Aa]\s+[Hh][Rr][Ee][Ff]/a href/g; }
if ($text =~ m/<\/A>/) { $text =~ s/<\/A>/<\/a>/g; }

  # change .. to base dir
if ($text =~ m/\"\.\.\//) { $text =~ s/\"\.\.\//"http:\/\/www.its.caltech.edu\/~wormbase\/userguide\//g; }

  # take out <a name> from <h3> headers
if ($text =~ m/<h3><[aA]\s+[nN][aA][mM][eE][^>]+>([^<]+)<\/[aA]>/) {
  $text =~ s/<h3><[aA]\s+[nN][aA][mM][eE][^>]+>([^<]+)<\/[aA]>/<h3>$1/g; }

  # lowercase html://
if ($text =~ m/[hH][tT][mM][lL]:\/\//) { $text =~ s/([hH][tT][mM][lL]:\/\/)/html:\/\//g; }

  # if href doesn't start with html, stick in base dir
  # FIX THIS to disallow html insead of h t m l (makes ``simple'' fail)
while ($text =~ m/\<a href\=\"([^h][^t][^m][^l][^\"]+)\"\>/) {
  if ($text =~ m/\<a href\=\"([^h][^t][^m][^l][^\"]+)\"\>/) { print "BAD $1 BAD\n"; }
  $text =~ s/\<a href\=\"([^h][^t][^m][^l][^\"]+)\"\>/<a href=\"http:\/\/www.its.caltech.edu\/~wormbase\/userguide\/$1\">/g; }
# while ($text =~ m/\<a href\=\"([^h][^t][^m][^l][^\"]+)\"\>/) {
#   if ($text =~ m/\<a href\=\"([^h][^t][^m][^l][^\"]+)\"\>/) { print "BAD $1 BAD\n"; }
#   $text =~ s/\<a href\=\"([^h][^t][^m][^l][^\"]+)\"\>/<a href=\"http:\/\/www.its.caltech.edu\/~wormbase\/userguide\/$1\">/g; }

  # switch href to wiki markup
while ($text =~ m/\<a href\=\"([^\"]+)\"\>([^\<]+)\<\/a\>/) {
  $text =~ s/<a href\=\"([^"]+)\">([^<]+)<\/a>/[$1 $2]/g; }

  # switch out img src for wiki
if ($text =~ m/<[iI][mM][gG]\s+[sS][rR][cC]=\"([^\"]+)\">/) {
  $text =~ s/<[iI][mM][gG]\s+[sS][rR][cC]=\"([^\"]+)\">/$1/g; }

print OUT $text;
close (IN) or die "Cannot close $inputfile : $!";
close (OUT) or die "Cannot close $outputfile : $!";


__END__
<p><a href="Simple/index.html">See more details on the explanation of Quick Search tool.</a>

<p>Sometimes a submenu will appear when you search for certain items such as genetic map, sequence report or cell lineage. The submenu usually is for different displays of information, for example, "Tree display" versus "Graphic display", etc. For more information, please read the help page for <a href="Submenu/index.html">Sub Menu</a>.

http://www.its.caltech.edu/~wormbase/userguide/
<p align=center><img SRC="../wb_index.jpg"> 


<!doctype html public "-//w3c//dtd html 4.0 transitional//en">
<html>
<body  bgcolor="FFFFFF">
<!-- Insert Wormbase Header -->
<!-- Begin Userguide Style sheet -->
<head>
   <link rel="stylesheet" href="http://www.wormbase.org/stylesheets/wormbase.css"> 
   <title>WormBase Userguide </title>
</head>


<body>
  <script type="text/javascript">
<!--
function c(p){location.href=p;return false;}
// -->
</script>

<table border="0" cellpadding="4" cellspacing="1" width="100%">
<tr>
<td bgcolor="#b4cbdb" align="center" nowrap style="cursor:hand;" onClick="c('/')">
                          <a href="http://www.wormbase.org/" class="bactive"><font color="#FFFF99"><b>Home</b></font></a>
<td bgcolor="#5870a3" align="center" nowrap style="cursor:hand;" onClick="c('/db/seq/gbrowse?source=wormbase')">
                          <a href="/db/seq/gbrowse?source=wormbase" class="binactive"><font
color="#FFFFFF">Genome</font></a></td>
<td bgcolor="#5870a3" align="center" nowrap style="cursor:hand;" onClick="c('/db/searches/blat')">
                          <a href="/db/searches/blat" class="binactive"><font color="#FFFFFF">Blast / Blat</font></a></td>
<td bgcolor="#5870a3" align="center" nowrap style="cursor:hand;" onClick="c('/db/searches/info_dump')">
                          <a href="/db/searches/info_dump" class="binactive"><font color="#FFFFFF">Batch
Genes</font></a></td>
<td bgcolor="#5870a3" align="center" nowrap style="cursor:hand;" onClick="c('/db/searches/advanced/dumper')">
                          <a href="/db/searches/advanced/dumper" class="binactive"><font color="#FFFFFF">Batch
Sequences</font></a></td>
<td bgcolor="#5870a3" align="center" nowrap style="cursor:hand;" onClick="c('/db/searches/strains')">
                          <a href="/db/searches/strains" class="binactive"><font color="#FFFFFF">Markers</font></a></td>
<td bgcolor="#5870a3" align="center" nowrap style="cursor:hand;" onClick="c('/db/gene/gmap')">
                          <a href="/db/gene/gmap" class="binactive"><font color="#FFFFFF">Genetic Maps</font></a></td>
<td bgcolor="#5870a3" align="center" nowrap style="cursor:hand;" onClick="c('/db/curate/base')">
                          <a href="/db/curate/base" class="binactive"><font color="#FFFFFF">Submit</font></a></td>
<td bgcolor="#5870a3" align="center" nowrap style="cursor:hand;" onClick="c('/db/searches/search_index')">
                          <a href="/db/searches/search_index" class="binactive"><font color="#FFFFFF"><b>More
Searches</b></font></a></td>
</tr>
</table>

<table cellpadding="0" width="100%" nowrap="1" cellspacing="1" border="0"><tr valign="top" class="white" nowrap="1"><td align="right" cellspacing="1"><a
href="http://www.wormbase.org/"><img alt border="0" src="http://www.wormbase.org/images/image_new_colour.jpg" /></a></td></tr></table><hr><p>


<!-- End of Wormbase Header -->

<!-- -------*-------*--------*-------*--------*-------*---- -->

<!-- Begin User Guide Title -->
<p align=center><b><font color="#000000"><font size=+3><a NAME="TOP">User's Guide for WormBase</a></font></b>
<table width=100%><tr>
<td align=left><h2><a href="../sitemap.html">Prev</a></h2></td>

<!-- Insert Layer 1 Menu bar --> 
<!-- Begin Layer 1 Menu bar -->
<td align=center><b>
     [ <a href="../sitemap.html">Index</a> ]
     [ <a href="../General/index.html">Summary</a> ]
     [ <a href="../Menu/index.html">Menu</a> ]
     [ <a href="../General/Submenu/index.html">Submenu</a> ]
     [ <a href="../FAQ/index.html">FAQ</a> ]</b>
</td>

<!-- End of Layer 1 Menu bar -->

<td align=right><h2><a href="Release/index.html">Next</a></h2></td></tr>
</table>

<hr WIDTH="100%">
<!-- End User Guide Title -->

<!-- -------*-------*--------*-------*--------*-------*---- -->

<!-- Begin Body Text -->
<h1 align=center><font color="#2F8B20">An Overview of The WormBase Homepage</font></h1>

<!-- General Documentation  -->
<p><h3>GENERAL DOCUMENTATION</h3>
<p>CAVEAT: ALWAYS UNDER CONSTRUCTION
<p>At this writing, Wormbase is very much a dynamic, ongoing project.  A good consequence of this is that new features and options are added and old ones are removed at a noticeable rate.  A draw back, however, is that documentation written for a given feature of the WormBase Web interface may be obsolete by the time you are reading this text.
<p>Therefore, this documentation is based upon the main WormBase web site at Cold Spring Harbor Laboratories (<a href="http://wormbase.org">http://wormbase.org</a>). The Greek mirror (<a href="http://worm.imbb.forth.gr/">http://worm.imbb.forth.gr/</a>), at this writing, has many of the same features as the main site but lags behind the main site in some respects; that is because the Greek mirror represents the last version of the WormBase web site that was stable enough to be ported by non-WormBase staff.
<p>
<p align=center><img SRC="../wb_index.jpg"> 

<br><br><br>

<!-- New Release  -->
<h3>NEW RELEASE AND RELEASE NOTES</h3>
<p>WormBase is updated every two weeks, with each release assigned a new version number (for example: WS10, ... WS51, ... WS97). Release notes can be accessed directly from the WormBase home page: see <a href="Release/index.html">the help page for Release notes</a>.  
<br><br><br>

<!-- Quick Search Box help  -->

<h3><a NAME="Q2">QUICK SEARCH</a>:</h3>

<p>Select a class from the pull-down menu to "Search for", and then type key words in the box.
<br>If you leave the search box blank, everything from the selected class will appear as the search result. For
example: if you select class "Cell", and type nothing in search box, all <i>C. elegans</i> cells will appear in the search result.
<br>For anything you are not sure of, try using * as the wild card insertion; it can be placed anywhere in the keyword. Example: if you type "ad*", all data that begin with "ad" will appear in
the search result.

<p><i>What can be typed into the "Quick
Search" box?</i>
<br>The following objects can be entered in the search box, which is case sensitive and space sensitive. You can search for a certain class such as "Any Gene" or "Author", or search for "Anything", which will return related objects from all classes.

<ul>
<li><font color="#FF7518">Any Gene </font>Example: lin-3</li>
<li><font color="#FF7518">Author </font>Example: Lee RYN</li>
<li><font color="#FF7518">Cell </font>Example: ADFL</li>
<li><font color="#FF7518">Genbank Accession Number</font> Example: AL032609</li>
</ul>

<p><a href="Simple/index.html">See more details on the explanation of Quick Search tool.</a>

<br><br><br>

<!--  Menu Help  -->
 
<h3>MENU FOR WORMBASE</h3>
<p>The WormBase menu includes five basic options on the top of the WormBase homepage. More advanced search tools can be found under the "More Searches" option. 

<p>To learn how to use these search tools, <font color="000000">please read the User's Guide help pages for <a href="../Menu/index.html">Basic Search Tools</a> and <a href="../MoreSearches/index.html">Advanced Search Tools</a>.

<p>Sometimes a submenu will appear when you search for certain items such as genetic map, sequence report or cell lineage. The submenu usually is for different displays of information, for example, "Tree display" versus "Graphic display", etc. For more information, please read the help page for <a href="Submenu/index.html">Sub Menu</a>.

<p>
<hr WIDTH="100%">
<!-- End Body Text -->

<!-- -------*-------*--------*-------*--------*-------*---- -->

<!-- Begin Userguide footer -->
<table width=100%><tr>
<td align=left><h2><a href="../sitemap.html">Prev</a></h2></td>

<!-- Insert Layer 1 Footer bar --> 
<!-- Begin Layer 1 Foot Menu bar -->
<td align=center><b>
     [ <a href="../index.html">User Guide Home</a> ]
     [ <a href="#TOP">Page Top</a> ]</b>
</td>

<!-- End of Layer 1 Footer bar -->

<td align=right><h2><a href="Release/index.html">Next</a></h2></td></tr>
</table>

<!-- Insert General User Guide Footer -->
<!-- Begin General Userguide Footer -->
<hr WIDTH="100%">
<table width=100%><tr>
<td align=left  class="small">Page maintained by <a
href="mailto:wchen@its.caltech.edu">Wen J. Chen</a></td>
<td align=right  class="small">Documentation by <a
href="mailto:wchen@its.caltech.edu">Wen J. Chen</a></td></tr><tr>
<td align=left  class="small"><a
href="http://www.wormbase.org/db/misc/feedback">Send comments or questions to WormBase</a></td>
<td align=right  class="small">Graphics by <a
href="mailto:wchen@its.caltech.edu">Wen J. Chen</a></td></td></tr>
</table>

<!-- End of General User Guide Footer -->

<!-- End User Guide Footer -->

</body>
</html>

<!-- End of this page -->

