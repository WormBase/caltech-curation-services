#!/usr/bin/perl -w

# MightyMapper for Robin Gasser   

# 2009 01 15
#
# use Aaron's layout.  2009 01 21
#
# add md5_hex for creating ftp and web subdirectories to put the result file in.  add ross to email.  2009 01 28
#
# add javascript dropdowns for all OGRe database organisms up to and excluding VERTEBRATA.  2009 01 31
#
# instead of emailing, write to hidden directory  2009 03 29
#
# changed to result_file.zip file name  2009 03 31
#
# added new fields for gap opening, gap extension (defaults 3.0 and 1.0)
# added new fields for reference sequence input, reference sequence file 
# these get appended to md5sum hash so if people with the same sequence / reference sequence (or files) get sent in, 
# they don't have to get reprocessed, and they won't overwrite someone else's value since we were using md5sum hash 
# for file name.
# these fields are labeled REFSEQUENCE REFFILEDATA GAPOPENING GAPEXTENSION
# reference sequence section is by default hidden and expands / collapses by clicking the ``here'' link.
# changed names from NemMitomapper to MightyMapper.
# added D Timothy J Littlewood and link to natural history museum with logo.   2009 08 03



use strict;
use CGI;
use Jex;
use Digest::MD5 qw(md5_hex);


my $query = new CGI;

print "Content-type: text/html\n\n";

print "<HEAD><TITLE>MightyMapper</TITLE></HEAD>\n";
# &printHeader();			
&Process();
# &printFooter();			# print the HTML footer


# sub printHeader {
#   print <<"EndOfText";
# Content-type: text/html\n\n
# EndOfText
# } # sub PrintHeader 




sub ShowPgQuery {
#   <FONT COLOR=RED SIZE=20>TESTING</FONT><BR>
  print <<"EndOfText";
<FORM NAME="mm" enctype="multipart/form-data" METHOD="POST" ACTION="http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/mitomapper/mitomapper2.cgi">
<table cellpadding="0" cellspacing="0" border=0>
 <tr>
  <td colspan="3">
<a href="http://www.unimelb.edu.au/" target="_blank"><img border="0" height="93" src="http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/mitomapper/MightyMapper_files/image008.jpg"></a>
<a href="http://www.caltech.edu/" target="_blank"><img border="0" height="93" src="http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/mitomapper/MightyMapper_files/image010.jpg"></a>
<a href="http://www.nhm.ac.uk/" target="_blank"><img border="0" src="http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/mitomapper/MightyMapper_files/nhmLobeliaLogo.jpg"></a>
  </td>
 </tr>
 <tr>
  <td >
  <div style="padding:2.88pt 2.88pt 2.88pt 2.88pt">
  <p><span style="font-size:28.0pt">MightyMapper</span><span style="font-size:18.0pt"></span></p>
  <p><span style="font-size:16.0pt">An automated, heuristic, annotation tool for the complete mitochondrial genomes</span></p>
  <p><span> </span></p>

  <p><span style="font-size:12.0pt">Aaron Jex, Ross Hall, Juancarlos Chan, Paul Sternberg, D Timothy J Littlewood, Robin Gasser</span></p>
  <p><span> </span></p>
  </div>
  </td>
 </tr>
</table>

<table cellpadding="0" cellspacing="0">

 <tr>
  <td width="704" height="552" style="vertical-align:top">
  <div style="padding:2.88pt 2.88pt 2.88pt 2.88pt">
  <p style="text-align:justify;text-justify:newspaper;text-kashida-space:50%;text-align:justify;text-justify:newspaper;text-kashida-space:50%"><span style="font-size:11.0pt">MightyMapper is an automated annotation tool for mitochondrial genomes.<span>  </span>MightyMapper uses a number of search parameters to accurately and rapidly determine the identity, position and boundaries of all protein coding, ribosomal and transfer rRNA genes.<span>  </span></span></p>
  <p style="text-align:justify;text-justify:newspaper;text-kashida-space:50%;text-align:justify;text-justify:newspaper;text-kashida-space:50%"><span style="font-size:11.0pt"> </span></p>
  <p style="text-align:justify;text-justify:newspaper;text-kashida-space:50%;text-align:justify;text-justify:newspaper;text-kashida-space:50%"><span style="font-size:11.0pt">The boundaries for coding genes are determined by comparative linear alignment using a reference sequence representing the a published mitochondrial genome for one of the species listed below.<span>  </span>Each coding gene is located using the inferred amino acid sequence of the corresponding gene from the reference species, and step-wise alignment searching of the queried genome in all six reading frames (3 forward and 3 reverse).<span>  </span>Identity is determined by BLOSSUM identity score, and boundaries are determined initially by peptide length and then refined by identification of known mitochondrial genomic start and stop codons. Ribosomal RNA genes are identified using a similar approach, using nucleotide sequences only. Please note that the closer the evolutionary relationship is between the species from which the queried genome has been derived and the species used as a reference the more accurate the annotation is likely to be.<span>   </span></span></p>

  <p style="text-align:justify;text-justify:newspaper;text-kashida-space:50%;text-align:justify;text-justify:newspaper;text-kashida-space:50%"><span style="font-size:11.0pt"> </span></p>
  <p style="text-align:justify;text-justify:newspaper;text-kashida-space:50%;text-align:justify;text-justify:newspaper;text-kashida-space:50%"><span style="font-size:11.0pt">Transfer rRNA genes are determined by a three part process, combining predicted secondary structure, anti-codon identity and comparative alignment against a database representing all published mitochondrial tRNA genes.</span></p>
  <p style="text-align:justify;text-justify:newspaper;text-kashida-space:50%;text-align:justify;text-justify:newspaper;text-kashida-space:50%"><span style="font-size:11.0pt"> </span></p>
  <p style="text-align:justify;text-justify:newspaper;text-kashida-space:50%;text-align:justify;text-justify:newspaper;text-kashida-space:50%"><span style="font-size:11.0pt">Sequences may be loaded (in FASTA format) into MightyMapper either using the text window below (copy and paste), or uploaded as a plain text file from the user’s computer. Presently MightyMapper can analyse up to 200 mt genomes per job. Analysis time will be dependent upon the number of sequences.<span>  </span>An average analysis time of approximately 2 minutes per genome should be expected.</span></p>
  <p style="text-align:justify;text-justify:newspaper;text-kashida-space:50%;text-align:justify;text-justify:newspaper;text-kashida-space:50%"><span style="font-size:11.0pt"> </span></p>

  <p style="text-align:justify;text-justify:newspaper;text-kashida-space:50%;text-align:justify;text-justify:newspaper;text-kashida-space:50%"><span style="font-size:11.0pt">Notification of a completed analysis will be sent to the user-specified email address.<span>  </span>Results will be obtainable from a use-specific ftp site (assigned upon completion of the analysis).<span>  </span>All data will be stored on a secure server for 48 hours.</span></p>
  <p style="text-align:justify;text-justify:newspaper;text-kashida-space:50%;text-align:justify;text-justify:newspaper;text-kashida-space:50%"><span style="font-size:11.0pt"> </span></p>
  <p style="text-align:justify;text-justify:newspaper;text-kashida-space:50%;text-align:justify;text-justify:newspaper;text-kashida-space:50%"><span style="font-size:11.0pt">Data output includes a FASTA sequence (rotated to cox1) of the queried mt genome, a SEQUIN table containing all gene boundaries, and graphic files for showing the secondary structure of each identified tRNA gene (in scalable vector graphics (.eps) and published document file (.pdf) format).<span>  </span>Data output will also include a ‘Readme.text’ file with more detailed instructions.</span></p>
  <p style="text-align:justify;text-justify:newspaper;text-kashida-space:50%;text-align:justify;text-justify:newspaper;text-kashida-space:50%"><span style="font-size:11.0pt"> </span></p>

  <p style="text-align:justify;text-justify:newspaper;text-kashida-space:50%;text-align:justify;text-justify:newspaper;text-kashida-space:50%"><span style="font-size:11.0pt">To view and manipulate .eps files, users are directed to the free-ware program </span><span style="font-size:11.0pt"><a href="http://www.inkscape.org/" target="_blank">InkScape</a></span><span style="font-size:11.0pt">. </span><span style="font-size:11.0pt"></span></p>
  </div>
  </td>
 </tr>
</table>

<table cellpadding="0" cellspacing="0">
 <tr>

  <td width="696" height="834" style="vertical-align:top">
  <div style="padding:2.88pt 2.88pt 2.88pt 2.88pt">
  <p><span style="font-size:11.0pt">Paste FASTA format sequence(s) here (Max 200).<span>  </span>Please ensure each sequence is labelled with a unique 10 character code.</span></p>
  <TEXTAREA NAME="textsequence" ROWS=15 COLS=80></TEXTAREA>

  <p><span style="font-size:11.0pt">Or upload FASTA format sequence(s) as a plain text file (Max 200 sequences per file) directly</span></p>
 <INPUT NAME="file_input" TYPE="FILE">

  <p><span style="font-size:11.0pt">Email address (Email address will exclusively be used to notify the user of the completion of their analysis)</span></p>
  <INPUT NAME="email" VALUE="">

  <p><span style="font-size:11.0pt">Please select the most appropriate reference sequence from the list below (scroll down menus) :</span>

 <BR>
EndOfText

&javascriptHash();

#   <SELECT NAME="source" SIZE=1>";
# <OPTION>Agamermis sp. BH-2006</OPTION>
# <OPTION>Ancylostoma duodenale</OPTION>
# <OPTION>Anisakis simplex</OPTION>
# <OPTION>Ascaris suum</OPTION>
# <OPTION>Brugia malayi</OPTION>
# <OPTION>Caenorhabditis briggsae</OPTION>
# <OPTION>Caenorhabditis elegans</OPTION>
# <OPTION>Cooperia oncophora</OPTION>
# <OPTION>Dirofilaria immitis</OPTION>
# <OPTION>Haemonchus contortus</OPTION>
# <OPTION>Heterorhabditis bacteriophora</OPTION>
# <OPTION>Hexamermis agrotis</OPTION>
# <OPTION>Necator americanus</OPTION>
# <OPTION>Onchocerca volvulus</OPTION>
# <OPTION>Romanomermis culicivorax</OPTION>
# <OPTION>Romanomermis iyengari</OPTION>
# <OPTION>Romanomermis nielseni</OPTION>
# <OPTION>Steinernema carpocapsae</OPTION>
# <OPTION>Strelkovimermis spiculatus</OPTION>
# <OPTION>Strongyloides stercoralis</OPTION>
# <OPTION>Thaumamermis cosgrovei</OPTION>
# <OPTION>Toxocara canis</OPTION>
# <OPTION>Toxocara malaysiensis</OPTION>
# <OPTION>Trichinella spiralis</OPTION>
# <OPTION>Xiphinema americanum</OPTION>
#   </SELECT>

  print <<"EndOfText";
  <p>Optional: to use your own reference sequence click <a href="javascript:ToggleDisplay('reference_section')">here</a>.<br /></p>
  <div id="reference_section" style="display: none">
  <p><span style="font-size:11.0pt">If there's no suitable organism in the available lists, you may provide your own sequence in GenBank format.  Paste your reference sequence in GenBank format here (Max 1 sequence).</span>  <span>Please ensure the sequence is labelled with a unique 10 character code.</span></p>
  <TEXTAREA NAME="referencesequence" ROWS=15 COLS=80></TEXTAREA>

  <p><span style="font-size:11.0pt">Or upload your reference sequence as a GenBank text file (Max 1 sequence).</span></p>
 <INPUT NAME="reference_file_input" TYPE="FILE">
  </div>


  <p>MightyMapper uses comparative local alignment algorithms to annotate many of the mitochondrial genes.  Depending upon the relationship between the template and query sequence, it may be necessary to adjust the alignment parameters used for these comparisons.  To adjust the gap penalties used in the alignment process, please enter the desired values in the windows provided below.<br /><br />
  Gap Opening value : <input name="gap_opening" size="1" value="3.0">
  Gap Extension value : <input name="gap_extension" size="1" value="1.0"></p>

  <P><INPUT TYPE="submit" NAME="action" VALUE="Submit sequence(s)">

  <p><BR></p>
  <p><span style="font-size:11.0pt">Thank you for using MightyMapper.<span>  </span>You will be notified when you analysis is complete.</span></p>
  <p><span style="font-size:11.0pt"> </span></p>
  <p><span style="font-size:11.0pt">In publications using MightyMapper, please cite:<br>
  </span></p>
  <p><span style="font-size:11.0pt">Aaron Jex, Ross Hall, Juancarlos Chan, Paul Sternberg, D Timothy J Littlewood, Robin Gasser (2010). “MightyMapper: an accurate and rapid heuristic annotation tool for the mitochondrial genomes. </span><span style="font-size:11.0pt;font-style:italic">Some Bioinformatic Journal, xxx-xxx.</span></p>

  <p><span style="font-size:11.0pt;font-style:italic"> </span></p>
  <p><span style="font-size:11.0pt;font-style:italic">For technical support, please contact <a href="mailto:ajex\@unimelb.edu.au" target="_blank">ajex\@unimelb.edu.au</a></span><span style="font-size:11.0pt;font-style:italic"></span></p>
  </div>
  </td>
 </tr>
 </FORM>
</table>
EndOfText

}


sub Process {			# Essentially do everything
  my $action;			# what user clicked
  unless ($action = $query->param('action')) {
    $action = 'none';
  }
  if ($action eq 'Submit sequence(s)') { 
    my ($var, $format) = &getHtmlVar($query, "raw_or_fasta");
    ($var, my $sequence) = &getHtmlVar($query, "textsequence");
#     ($var, my $file_input) = &getHtmlVar($query, "file_input");
    my $filename = $query->param("file_input");
    my $filedata = ''; 
    ($var, my $refsequence) = &getHtmlVar($query, "referencesequence");
    while (<$filename>) { $filedata .= $_; }
    my $reffilename = $query->param("reference_file_input");
    my $reffiledata = ''; 
    while (<$reffilename>) { $reffiledata .= $_; }
#     ($var, my $seqname) = &getHtmlVar($query, "sequence_name");
#     ($var, my $source) = &getHtmlVar($query, "source");
    ($var, my $gapopening) = &getHtmlVar($query, "gap_opening");
    ($var, my $gapextension) = &getHtmlVar($query, "gap_extension");
    ($var, my $useremail) = &getHtmlVar($query, "email");
    my $source = '';
    for (my $i = 0; $i < 4; $i++) {
      ($var, my $val) = &getHtmlVar($query, "m$i");
      if ($val) { if ($val ne "----Please, select-----") { $source = $val; } }
    } # for (my $i = 7; $i < 1; $i--)

    my $output = '';  my $error_flag = 0;
    unless ($sequence or $filedata) { print "<FONT COLOR=RED>Error, you need to type a sequence or submit a file.</FONT><BR>\n "; $error_flag++; }
    unless ($useremail) { print "<FONT COLOR=RED>Error, we need your email to notify you of results.</FONT><BR>\n "; $error_flag++; }
    if ($error_flag) { return; }

    my $hash_thing = $source;
    if ($sequence) {
      $hash_thing .= " $sequence";
      $output .= "You've sent us sequence \"$sequence\" in $format format with source $source\n"; }
    if ($filedata) {
      $hash_thing .= " $filedata";
      $output .= "You've sent us a file \"$filedata\" in $format format with source $source\n"; }
    if ($refsequence) {
      $hash_thing .= " $refsequence";
      $output .= "You've sent us reference sequence \"$refsequence\" in $format format with source $source\n"; }
    if ($reffiledata) {
      $hash_thing .= " $reffiledata";
      $output .= "You've sent us a reference file \"$reffiledata\" in $format format with source $source\n"; }
    if ($gapopening) {
      $hash_thing .= " $gapopening";
      $output .= "You've sent us gap opening \"$gapopening\" in $format format with source $source\n"; }
    if ($gapextension) {
      $hash_thing .= " $gapextension";
      $output .= "You've sent us gap extension \"$gapextension\" in $format format with source $source\n"; }
    my $md5sum = &md5_hex($hash_thing);		# get md5sum of sequence and filedata to use as subdirectory for results in ftp and web servers

    my $time = time;
    $md5sum = $time . '.' . $md5sum;

#     if ($seqname) { $output .= "The optional name is \"$seqname\"\n"; }
    if ($useremail) { $output .= "We will email you when we have results to $useremail\n"; }
    my $location = "http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/mitomapper/results/$md5sum/result_file.zip";
    `mkdir /home/azurebrd/public_html/cgi-bin/forms/mitomapper/results/$md5sum`;	# create a web directory for these results
    `mkdir /var/ftp/uploads/$md5sum`;						# create an ftp directory for these results
    `chmod 777 /var/ftp/uploads/$md5sum`;					# make it readable and writable
#     symlink("/var/ftp/uploads/$md5sum/result_file", "/home/azurebrd/public_html/cgi-bin/forms/mitomapper/results/$md5sum/");
       # symlink where the results will be to the web server (broken until Ross puts result_file.zip there)
    `ln -s "/var/ftp/uploads/$md5sum/result_file.zip" "/home/azurebrd/public_html/cgi-bin/forms/mitomapper/results/$md5sum/"`;
    $output .= "The results will show at <A HREF=\"$location\">$location</A> after X minutes\n";
    my $html_out = $output;
    $html_out =~ s/\n/<BR>\n/g;
    print $html_out;
    my $user = 'mighty_mapper';
#     my $email = 'azurebrd@tazendra.caltech.edu';
    my $email = 'robinbg@unimelb.edu.au, aaronrjex@hotmail.com, rossh@unimelb.edu.au';
    my $subject = 'MightyMapper request';
    my $body = $output;
    my $outfile = '/home2/azurebrd/public_html/hidden/mitomapper/swaquwrejevUhAyetedr/' . $md5sum;
#     &mailer($user, $email, $subject, $body);
      # instead of emailing, write to hidden directory  2009 03 29
    open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
    if ($sequence) { print OUT "SEQUENCE\t$sequence\n"; }
    if ($filedata) { print OUT "FILEDATA\t$filedata\n"; }
    if ($refsequence) { print OUT "REFSEQUENCE\t$refsequence\n"; }
    if ($reffiledata) { print OUT "REFFILEDATA\t$reffiledata\n"; }
    if ($gapopening) { print OUT "GAPOPENING\t$gapopening\n"; }
    if ($gapextension) { print OUT "GAPEXTENSION\t$gapextension\n"; }
    if ($useremail) { print OUT "USER\t$useremail\n"; }
    if ($location) { print OUT "LOCATION\t$location\n"; }
    if ($source) { print OUT "SOURCE\t$source\n"; }
    close (OUT) or die "Cannot close $outfile : $!";
  } # if ($action eq 'Run tRNAscan')
  else {
    &ShowPgQuery();
  }
} # sub Process


sub javascriptHash {
  print <<"EndOfText";
    <script language="JavaScript1.1">

    function ToggleDisplay(field) {
      if (document.getElementById(field).style.display == "none") {
         document.getElementById(field).style.display = ""; }
      else {
         document.getElementById(field).style.display = "none"; }
    }

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

    mymenu.sub[0] = new dynoMenu("ACANTHOCEPHALA", null);
    mymenu.sub[0].sub[0] = new dynoMenu("Leptorhynchoides thecatus", null);
    
    mymenu.sub[1] = new dynoMenu("ANNELIDA", null);
    mymenu.sub[1].sub[0] = new dynoMenu("Clymenella torquata", null);
    mymenu.sub[1].sub[1] = new dynoMenu("Lumbricus terrestris", null);
    mymenu.sub[1].sub[2] = new dynoMenu("Orbinia latreillii", null);
    mymenu.sub[1].sub[3] = new dynoMenu("Perionyx excavatus", null);
    mymenu.sub[1].sub[4] = new dynoMenu("Platynereis dumerilii", null);
    
    
    mymenu.sub[2] = new dynoMenu("ARTHROPODA", null);
    mymenu.sub[2].sub[0] = new dynoMenu("CHELICERATA", null);
    mymenu.sub[2].sub[0].sub[0] = new dynoMenu("Achelia bituberculata", null);
    mymenu.sub[2].sub[0].sub[1] = new dynoMenu("Amblyomma triguttatum", null);
    mymenu.sub[2].sub[0].sub[2] = new dynoMenu("Ascoschoengastia sp. TATW-1", null);
    mymenu.sub[2].sub[0].sub[3] = new dynoMenu("Carios capensis", null);
    mymenu.sub[2].sub[0].sub[4] = new dynoMenu("Centruroides limpidus", null);
    mymenu.sub[2].sub[0].sub[5] = new dynoMenu("Habronattus oregonensis", null);
    mymenu.sub[2].sub[0].sub[6] = new dynoMenu("Haemaphysalis flava", null);
    mymenu.sub[2].sub[0].sub[7] = new dynoMenu("Heptathela hangzhouensis", null);
    mymenu.sub[2].sub[0].sub[8] = new dynoMenu("Ixodes hexagonus", null);
    mymenu.sub[2].sub[0].sub[9] = new dynoMenu("Ixodes holocyclus", null);
    mymenu.sub[2].sub[0].sub[10] = new dynoMenu("Ixodes persulcatus", null);
    mymenu.sub[2].sub[0].sub[11] = new dynoMenu("Ixodes uriae", null);
    mymenu.sub[2].sub[0].sub[12] = new dynoMenu("Leptotrombidium akamushi", null);
    mymenu.sub[2].sub[0].sub[13] = new dynoMenu("Leptotrombidium deliense", null);
    mymenu.sub[2].sub[0].sub[14] = new dynoMenu("Leptotrombidium pallidum", null);
    mymenu.sub[2].sub[0].sub[15] = new dynoMenu("Limulus polyphemus", null);
    mymenu.sub[2].sub[0].sub[16] = new dynoMenu("Mastigoproctus giganteus", null);
    mymenu.sub[2].sub[0].sub[17] = new dynoMenu("Mesobuthus gibbosus", null);
    mymenu.sub[2].sub[0].sub[18] = new dynoMenu("Mesobuthus martensii", null);
    mymenu.sub[2].sub[0].sub[19] = new dynoMenu("Metaseiulus occidentalis", null);
    mymenu.sub[2].sub[0].sub[20] = new dynoMenu("Nephila clavata", null);
    mymenu.sub[2].sub[0].sub[21] = new dynoMenu("Nymphon gracile", null);
    mymenu.sub[2].sub[0].sub[22] = new dynoMenu("Oltacola gomezi", null);
    mymenu.sub[2].sub[0].sub[23] = new dynoMenu("Ornithoctonus huwena", null);
    mymenu.sub[2].sub[0].sub[24] = new dynoMenu("Ornithodoros moubata", null);
    mymenu.sub[2].sub[0].sub[25] = new dynoMenu("Ornithodoros porcinus", null);
    mymenu.sub[2].sub[0].sub[26] = new dynoMenu("Pseudocellus pearsei", null);
    mymenu.sub[2].sub[0].sub[27] = new dynoMenu("Rhipicephalus sanguineus", null);
    mymenu.sub[2].sub[0].sub[28] = new dynoMenu("Tetranychus urticae", null);
    mymenu.sub[2].sub[0].sub[29] = new dynoMenu("Varroa destructor", null);
    mymenu.sub[2].sub[0].sub[30] = new dynoMenu("Walchia hayashii", null);
    
    mymenu.sub[2].sub[1] = new dynoMenu("COLLEMBOLA", null);
    mymenu.sub[2].sub[1].sub[0] = new dynoMenu("Cryptopygus antarcticus", null);
    mymenu.sub[2].sub[1].sub[1] = new dynoMenu("Friesea grisea", null);
    mymenu.sub[2].sub[1].sub[2] = new dynoMenu("Gomphiocephalus hodgsoni", null);
    mymenu.sub[2].sub[1].sub[3] = new dynoMenu("Onychiurus orientalis", null);
    mymenu.sub[2].sub[1].sub[4] = new dynoMenu("Orchesella villosa", null);
    mymenu.sub[2].sub[1].sub[5] = new dynoMenu("Podura aquatica", null);
    mymenu.sub[2].sub[1].sub[6] = new dynoMenu("Sminthurus viridis", null);
    mymenu.sub[2].sub[1].sub[7] = new dynoMenu("Tetrodontophora bielanensis  ", null);
    
    mymenu.sub[2].sub[2] = new dynoMenu("CRUSTACEA", null);
    mymenu.sub[2].sub[2].sub[0] = new dynoMenu("Argulus americanus", null);
    mymenu.sub[2].sub[2].sub[1] = new dynoMenu("Armillifer armillatus", null);
    mymenu.sub[2].sub[2].sub[2] = new dynoMenu("Artemia franciscana", null);
    mymenu.sub[2].sub[2].sub[3] = new dynoMenu("Callinectes sapidus", null);
    mymenu.sub[2].sub[2].sub[4] = new dynoMenu("Cherax destructor", null);
    mymenu.sub[2].sub[2].sub[5] = new dynoMenu("Daphnia pulex", null);
    mymenu.sub[2].sub[2].sub[6] = new dynoMenu("Eriocheir sinensis", null);
    mymenu.sub[2].sub[2].sub[7] = new dynoMenu("Fenneropenaeus chinensis", null);
    mymenu.sub[2].sub[2].sub[8] = new dynoMenu("Geothelphusa dehaani", null);
    mymenu.sub[2].sub[2].sub[9] = new dynoMenu("Gonodactylus chiragra", null);
    mymenu.sub[2].sub[2].sub[10] = new dynoMenu("Halocaridina rubra", null);
    mymenu.sub[2].sub[2].sub[11] = new dynoMenu("Harpiosquilla harpax", null);
    mymenu.sub[2].sub[2].sub[12] = new dynoMenu("Hutchinsoniella macracantha", null);
    mymenu.sub[2].sub[2].sub[13] = new dynoMenu("Lepeophtheirus salmonis", null);
    mymenu.sub[2].sub[2].sub[14] = new dynoMenu("Ligia oceanica", null);
    mymenu.sub[2].sub[2].sub[15] = new dynoMenu("Litopenaeus vannamei", null);
    mymenu.sub[2].sub[2].sub[16] = new dynoMenu("Lysiosquillina maculata", null);
    mymenu.sub[2].sub[2].sub[17] = new dynoMenu("Macrobrachium rosenbergii", null);
    mymenu.sub[2].sub[2].sub[18] = new dynoMenu("Marsupenaeus japonicus", null);
    mymenu.sub[2].sub[2].sub[19] = new dynoMenu("Megabalanus volcano", null);
    mymenu.sub[2].sub[2].sub[20] = new dynoMenu("Pagurus longicarpus", null);
    mymenu.sub[2].sub[2].sub[21] = new dynoMenu("Panulirus japonicus", null);
    mymenu.sub[2].sub[2].sub[22] = new dynoMenu("Penaeus monodon", null);
    mymenu.sub[2].sub[2].sub[23] = new dynoMenu("Pollicipes mitella", null);
    mymenu.sub[2].sub[2].sub[24] = new dynoMenu("Pollicipes polymerus", null);
    mymenu.sub[2].sub[2].sub[25] = new dynoMenu("Portunus trituberculatus", null);
    mymenu.sub[2].sub[2].sub[26] = new dynoMenu("Pseudocarcinus gigas", null);
    mymenu.sub[2].sub[2].sub[27] = new dynoMenu("Speleonectes tulumensis", null);
    mymenu.sub[2].sub[2].sub[28] = new dynoMenu("Squilla empusa", null);
    mymenu.sub[2].sub[2].sub[29] = new dynoMenu("Squilla mantis", null);
    mymenu.sub[2].sub[2].sub[30] = new dynoMenu("Tetraclita japonica", null);
    mymenu.sub[2].sub[2].sub[31] = new dynoMenu("Tigriopus californicus", null);
    mymenu.sub[2].sub[2].sub[32] = new dynoMenu("Tigriopus japonicus", null);
    mymenu.sub[2].sub[2].sub[33] = new dynoMenu("Triops cancriformis", null);
    mymenu.sub[2].sub[2].sub[34] = new dynoMenu("Triops longicaudatus", null);
    mymenu.sub[2].sub[2].sub[35] = new dynoMenu("Vargula hilgendorfii", null);
                              
    mymenu.sub[2].sub[3] = new dynoMenu("DIPLURA", null);
    mymenu.sub[2].sub[3].sub[0] = new dynoMenu("Campodea fragilis", null);
    mymenu.sub[2].sub[3].sub[1] = new dynoMenu("Campodea lubbocki", null);
    mymenu.sub[2].sub[3].sub[2] = new dynoMenu("Japyx solifugus", null);
    
    mymenu.sub[2].sub[4] = new dynoMenu("INSECTA", null);
    mymenu.sub[2].sub[4].sub[0] = new dynoMenu(" Adoxophyes honmai", null);
    mymenu.sub[2].sub[4].sub[1] = new dynoMenu("Aedes aegypti", null);
    mymenu.sub[2].sub[4].sub[2] = new dynoMenu("Aedes albopictus", null);
    mymenu.sub[2].sub[4].sub[3] = new dynoMenu("Aleurochiton aceris", null);
    mymenu.sub[2].sub[4].sub[4] = new dynoMenu("Aleurodicus dugesii", null);
    mymenu.sub[2].sub[4].sub[5] = new dynoMenu("Anabrus simplex", null);
    mymenu.sub[2].sub[4].sub[6] = new dynoMenu("Anopheles funestus", null);
    mymenu.sub[2].sub[4].sub[7] = new dynoMenu("Anopheles gambiae", null);
    mymenu.sub[2].sub[4].sub[8] = new dynoMenu("Anoplophora glabripennis", null);
    mymenu.sub[2].sub[4].sub[9] = new dynoMenu("Anopheles quadrimaculatus A", null);
    mymenu.sub[2].sub[4].sub[10] = new dynoMenu("Antheraea pernyi", null);
    mymenu.sub[2].sub[4].sub[11] = new dynoMenu("Apis mellifera ligustica", null);
    mymenu.sub[2].sub[4].sub[12] = new dynoMenu("Artogeia melete", null);
    mymenu.sub[2].sub[4].sub[13] = new dynoMenu("Bactrocera carambolae", null);
    mymenu.sub[2].sub[4].sub[14] = new dynoMenu("Bactrocera dorsalis", null);
    mymenu.sub[2].sub[4].sub[15] = new dynoMenu("Bactrocera oleae", null);
    mymenu.sub[2].sub[4].sub[16] = new dynoMenu("Bactrocera papayae", null);
    mymenu.sub[2].sub[4].sub[17] = new dynoMenu("Bactrocera philippinensis", null);
    mymenu.sub[2].sub[4].sub[18] = new dynoMenu("Bemisia tabaci", null);
    mymenu.sub[2].sub[4].sub[19] = new dynoMenu("Campanulotes bidentatus compar", null);
    mymenu.sub[2].sub[4].sub[20] = new dynoMenu("Bombyx mandarina", null);
    mymenu.sub[2].sub[4].sub[21] = new dynoMenu("Bombyx mori", null);
    mymenu.sub[2].sub[4].sub[22] = new dynoMenu("Bothriometopus macrocnemis", null);
    mymenu.sub[2].sub[4].sub[23] = new dynoMenu("Ceratitis capitata", null);
    mymenu.sub[2].sub[4].sub[24] = new dynoMenu("Chrysomya putoria", null);
    mymenu.sub[2].sub[4].sub[25] = new dynoMenu("Cochliomyia hominivorax", null);
    mymenu.sub[2].sub[4].sub[26] = new dynoMenu("Coreana raphaelis", null);
    mymenu.sub[2].sub[4].sub[27] = new dynoMenu("Crioceris duodecimpunctata", null);
    mymenu.sub[2].sub[4].sub[28] = new dynoMenu("Culicoides arakawae", null);
    mymenu.sub[2].sub[4].sub[29] = new dynoMenu("Cydistomyia duplonotata", null);
    mymenu.sub[2].sub[4].sub[30] = new dynoMenu("Dermatobia hominis", null);
    mymenu.sub[2].sub[4].sub[31] = new dynoMenu("Drosophila mauritiana", null);
    mymenu.sub[2].sub[4].sub[32] = new dynoMenu("Drosophila melanogaster", null);
    mymenu.sub[2].sub[4].sub[33] = new dynoMenu("Drosophila sechellia", null);
    mymenu.sub[2].sub[4].sub[34] = new dynoMenu("Drosophila simulans", null);
    mymenu.sub[2].sub[4].sub[35] = new dynoMenu("Drosophila yakuba", null);
    mymenu.sub[2].sub[4].sub[36] = new dynoMenu("Gryllotalpa orientalis", null);
    mymenu.sub[2].sub[4].sub[37] = new dynoMenu("Heterodoxus macropus", null);
    mymenu.sub[2].sub[4].sub[38] = new dynoMenu("Homalodisca coagulata", null);
    mymenu.sub[2].sub[4].sub[39] = new dynoMenu("Haematobia irritans irritans", null);
    mymenu.sub[2].sub[4].sub[40] = new dynoMenu("Lepidopsocid RS-2001", null);
    mymenu.sub[2].sub[4].sub[41] = new dynoMenu("Locusta migratoria", null);
    mymenu.sub[2].sub[4].sub[42] = new dynoMenu("Lucilia sericata", null);
    mymenu.sub[2].sub[4].sub[43] = new dynoMenu("Manduca sexta", null);
    mymenu.sub[2].sub[4].sub[44] = new dynoMenu("Melipona bicolor", null);
    mymenu.sub[2].sub[4].sub[45] = new dynoMenu("Neomaskellia andropogonis", null);
    mymenu.sub[2].sub[4].sub[46] = new dynoMenu("Nesomachilis australica", null);
    mymenu.sub[2].sub[4].sub[47] = new dynoMenu("Ostrinia furnacalis", null);
    mymenu.sub[2].sub[4].sub[48] = new dynoMenu("Ostrinia nubilalis", null);
    mymenu.sub[2].sub[4].sub[49] = new dynoMenu("Oxya chinensis", null);
    mymenu.sub[2].sub[4].sub[50] = new dynoMenu("Pachypsylla venusta", null);
    mymenu.sub[2].sub[4].sub[51] = new dynoMenu("Periplaneta fuliginosa", null);
    mymenu.sub[2].sub[4].sub[52] = new dynoMenu("Petrobius brevistylis", null);
    mymenu.sub[2].sub[4].sub[53] = new dynoMenu("Philaenus spumarius", null);
    mymenu.sub[2].sub[4].sub[54] = new dynoMenu("Phthonandria atrilineata", null);
    mymenu.sub[2].sub[4].sub[55] = new dynoMenu("Pteronarcys princeps", null);
    mymenu.sub[2].sub[4].sub[56] = new dynoMenu("Pyrophorus divergens", null);
    mymenu.sub[2].sub[4].sub[57] = new dynoMenu("Pyrocoelia rufa", null);
    mymenu.sub[2].sub[4].sub[58] = new dynoMenu("Reticulitermes flavipes", null);
    mymenu.sub[2].sub[4].sub[59] = new dynoMenu("Reticulitermes hageni", null);
    mymenu.sub[2].sub[4].sub[60] = new dynoMenu("Reticulitermes santonensis", null);
    mymenu.sub[2].sub[4].sub[61] = new dynoMenu("Reticulitermes virginicus", null);
    mymenu.sub[2].sub[4].sub[62] = new dynoMenu("Ruspolia dubia", null);
    mymenu.sub[2].sub[4].sub[63] = new dynoMenu("Saturnia boisduvalii", null);
    mymenu.sub[2].sub[4].sub[64] = new dynoMenu("Schizaphis graminum", null);
    mymenu.sub[2].sub[4].sub[65] = new dynoMenu("Sclerophasma paresisensis", null);
    mymenu.sub[2].sub[4].sub[66] = new dynoMenu("Simosyrphus grandicornis", null);
    mymenu.sub[2].sub[4].sub[67] = new dynoMenu("Tamolanica tamolana", null);
    mymenu.sub[2].sub[4].sub[68] = new dynoMenu("Tetraleurodes acaciae", null);
    mymenu.sub[2].sub[4].sub[69] = new dynoMenu("Thermobia domestica", null);
    mymenu.sub[2].sub[4].sub[70] = new dynoMenu("Thrips imaginis", null);
    mymenu.sub[2].sub[4].sub[71] = new dynoMenu("Trigoniophthalmus alternatus", null);
    mymenu.sub[2].sub[4].sub[72] = new dynoMenu("Tribolium castaneum", null);
    mymenu.sub[2].sub[4].sub[73] = new dynoMenu("Triatoma dimidiata", null);
    mymenu.sub[2].sub[4].sub[74] = new dynoMenu("Tricholepidion gertschi", null);
    mymenu.sub[2].sub[4].sub[75] = new dynoMenu("Trichophthalma punctata", null);
    mymenu.sub[2].sub[4].sub[76] = new dynoMenu("Trialeurodes vaporariorum", null);
    mymenu.sub[2].sub[4].sub[77] = new dynoMenu("Vanhornia eucnemidarum", null);
                              
    mymenu.sub[2].sub[5] = new dynoMenu("MYRIAPODA", null);
    mymenu.sub[2].sub[5].sub[0] = new dynoMenu("Antrokoreana gracilipes", null);
    mymenu.sub[2].sub[5].sub[1] = new dynoMenu("Bothropolys sp. SP-2004", null);
    mymenu.sub[2].sub[5].sub[2] = new dynoMenu("Lithobius forficatus", null);
    mymenu.sub[2].sub[5].sub[3] = new dynoMenu("Narceus annularus", null);
    mymenu.sub[2].sub[5].sub[4] = new dynoMenu("Scutigerella causeyae", null);
    mymenu.sub[2].sub[5].sub[5] = new dynoMenu("Scutigera coleoptrata", null);
    mymenu.sub[2].sub[5].sub[6] = new dynoMenu("Thyropygus sp. DVL-2001", null);

    mymenu.sub[3] = new dynoMenu("BRACHIOPODA", null);
    mymenu.sub[3].sub[0] = new dynoMenu("Laqueus rubellus", null);
    mymenu.sub[3].sub[1] = new dynoMenu("Terebratulina retusa", null);
    mymenu.sub[3].sub[2] = new dynoMenu("Terebratalia transversa", null);

    mymenu.sub[4] = new dynoMenu("BRYOZOA", null);
    mymenu.sub[4].sub[0] = new dynoMenu("Bugula neritina", null);
    mymenu.sub[4].sub[1] = new dynoMenu("Flustrellidra hispida", null);

    mymenu.sub[5] = new dynoMenu("CHAETOGNATHA", null);
    mymenu.sub[5].sub[0] = new dynoMenu("Paraspadella gotoi", null);
    mymenu.sub[5].sub[1] = new dynoMenu("Spadella cephaloptera", null);

    mymenu.sub[6] = new dynoMenu("CHORDATA", null);
    mymenu.sub[6].sub[0] = new dynoMenu("CEPHALOCHORDATA", null);
    mymenu.sub[6].sub[0].sub[0] = new dynoMenu("Asymmetron inferum", null);
    mymenu.sub[6].sub[0].sub[1] = new dynoMenu("Asymmetron sp. A TK-2007", null);
    mymenu.sub[6].sub[0].sub[2] = new dynoMenu("Branchiostoma belcheri", null);
    mymenu.sub[6].sub[0].sub[3] = new dynoMenu("Branchiostoma floridae", null);
    mymenu.sub[6].sub[0].sub[4] = new dynoMenu("Branchiostoma japonicum", null);
    mymenu.sub[6].sub[0].sub[5] = new dynoMenu("Branchiostoma lanceolatum", null);
    mymenu.sub[6].sub[0].sub[6] = new dynoMenu("Epigonichthys lucayanus", null);
    mymenu.sub[6].sub[0].sub[7] = new dynoMenu("Epigonichthys maldivensis", null);
                              
    mymenu.sub[6].sub[1] = new dynoMenu("HYPEROTRETI", null);
    mymenu.sub[6].sub[1].sub[0] = new dynoMenu("Eptatretus burgeri", null);
    mymenu.sub[6].sub[1].sub[1] = new dynoMenu("Myxine glutinosa", null);
                 
    mymenu.sub[6].sub[2] = new dynoMenu("UROCHORDATA", null);
    mymenu.sub[6].sub[2].sub[0] = new dynoMenu("Ciona intestinalis", null);
    mymenu.sub[6].sub[2].sub[1] = new dynoMenu("Ciona savignyi", null);
    mymenu.sub[6].sub[2].sub[2] = new dynoMenu("Doliolum nationalis", null);
    mymenu.sub[6].sub[2].sub[3] = new dynoMenu("Halocynthia roretzi", null);
    mymenu.sub[6].sub[2].sub[4] = new dynoMenu("Phallusia fumigata", null);
    mymenu.sub[6].sub[2].sub[5] = new dynoMenu("Phallusia mammilata", null);

    mymenu.sub[6].sub[3] = new dynoMenu("VERTEBRATA", null);
    mymenu.sub[6].sub[3].sub[0] = new dynoMenu("ACTINOPTERYGII", null);
    mymenu.sub[6].sub[3].sub[1] = new dynoMenu("AMPHIBIA", null);
    mymenu.sub[6].sub[3].sub[2] = new dynoMenu("AVES", null);
    mymenu.sub[6].sub[3].sub[3] = new dynoMenu("CHONDRICHTHYES", null);
    mymenu.sub[6].sub[3].sub[4] = new dynoMenu("COELACANTHIFORMES", null);
    mymenu.sub[6].sub[3].sub[5] = new dynoMenu("CROCODYLIDAE", null);
    mymenu.sub[6].sub[3].sub[6] = new dynoMenu("DIPNOI", null);
    mymenu.sub[6].sub[3].sub[7] = new dynoMenu("HYPEROARTIA", null);
    mymenu.sub[6].sub[3].sub[8] = new dynoMenu("LEPIDOSAURIA", null);
    mymenu.sub[6].sub[3].sub[9] = new dynoMenu("MAMMALIA", null);
    mymenu.sub[6].sub[3].sub[10] = new dynoMenu("TESTUDINES", null);

    mymenu.sub[7] = new dynoMenu("CNIDARI", null);
    mymenu.sub[7].sub[0] = new dynoMenu("Acropora tenuis", null);
    mymenu.sub[7].sub[1] = new dynoMenu("Agaricia humilis", null);
    mymenu.sub[7].sub[2] = new dynoMenu("Anacropora matthai", null);
    mymenu.sub[7].sub[3] = new dynoMenu("Astrangia sp. JVK-2006", null);
    mymenu.sub[7].sub[4] = new dynoMenu("Aurelia aurita", null);
    mymenu.sub[7].sub[5] = new dynoMenu("Briareum asbestinum", null);
    mymenu.sub[7].sub[6] = new dynoMenu("Discosoma sp. CASIZ 168916", null);
    mymenu.sub[7].sub[7] = new dynoMenu("Discosoma sp. CASIZ 168915", null);
    mymenu.sub[7].sub[8] = new dynoMenu("Rhodactis sp. CASIZ 171755", null);
    mymenu.sub[7].sub[9] = new dynoMenu("Chrysopathes formosa", null);
    mymenu.sub[7].sub[10] = new dynoMenu("Colpophyllia natans", null);
    mymenu.sub[7].sub[11] = new dynoMenu("Metridium senile", null);
    mymenu.sub[7].sub[12] = new dynoMenu("Montastraea annularis", null);
    mymenu.sub[7].sub[13] = new dynoMenu("Montipora cactus", null);
    mymenu.sub[7].sub[14] = new dynoMenu("Montastraea faveolata", null);
    mymenu.sub[7].sub[15] = new dynoMenu("Montastraea franksi", null);
    mymenu.sub[7].sub[16] = new dynoMenu("Mussa angulosa", null);
    mymenu.sub[7].sub[17] = new dynoMenu("Nematostella sp. JVK-2006", null);
    mymenu.sub[7].sub[18] = new dynoMenu("Pavona clavus", null);
    mymenu.sub[7].sub[19] = new dynoMenu("Pocillopora damicornis", null);
    mymenu.sub[7].sub[20] = new dynoMenu("Pocillopora eydouxi", null);
    mymenu.sub[7].sub[21] = new dynoMenu("Porites porites", null);
    mymenu.sub[7].sub[22] = new dynoMenu("Pseudopterogorgia bipinnata", null);
    mymenu.sub[7].sub[23] = new dynoMenu("Ricordea florida", null);
    mymenu.sub[7].sub[24] = new dynoMenu("Savalia savaglia", null);
    mymenu.sub[7].sub[25] = new dynoMenu("Seriatopora caliendrum", null);
    mymenu.sub[7].sub[26] = new dynoMenu("Seriatopora hystrix", null);
    mymenu.sub[7].sub[27] = new dynoMenu("Siderastrea radians", null);
                       
    mymenu.sub[8] = new dynoMenu("ECHINODERMATA", null);
    mymenu.sub[8].sub[0] = new dynoMenu("Acanthaster brevispinus", null);
    mymenu.sub[8].sub[1] = new dynoMenu("Acanthaster planci", null);
    mymenu.sub[8].sub[2] = new dynoMenu("Antedon mediterranea", null);
    mymenu.sub[8].sub[3] = new dynoMenu("Arbacia lixula", null);
    mymenu.sub[8].sub[4] = new dynoMenu("Asterias amurensis", null);
    mymenu.sub[8].sub[5] = new dynoMenu("Asterina pectinifera", null);
    mymenu.sub[8].sub[6] = new dynoMenu("Astropecten polyacanthus", null);
    mymenu.sub[8].sub[7] = new dynoMenu("Cucumaria miniata", null);
    mymenu.sub[8].sub[8] = new dynoMenu("Florometra serratissima", null);
    mymenu.sub[8].sub[9] = new dynoMenu("Gymnocrinus richeri", null);
    mymenu.sub[8].sub[10] = new dynoMenu("Luidia quinalia", null);
    mymenu.sub[8].sub[11] = new dynoMenu("Ophiopholis aculeata", null);
    mymenu.sub[8].sub[12] = new dynoMenu("Ophiura albida", null);
    mymenu.sub[8].sub[13] = new dynoMenu("Ophiura lutkeni", null);
    mymenu.sub[8].sub[14] = new dynoMenu("Paracentrotus lividus", null);
    mymenu.sub[8].sub[15] = new dynoMenu("Phanogenia gracilis", null);
    mymenu.sub[8].sub[16] = new dynoMenu("Pisaster ochraceus", null);
    mymenu.sub[8].sub[17] = new dynoMenu("Strongylocentrotus droebachiensis", null);
    mymenu.sub[8].sub[18] = new dynoMenu("Strongylocentrotus pallidus", null);
    mymenu.sub[8].sub[19] = new dynoMenu("Strongylocentrotus purpuratus", null);

    mymenu.sub[9] = new dynoMenu("ECHIURA", null);
    mymenu.sub[9].sub[0] = new dynoMenu("Urechis caupo", null);

    mymenu.sub[10] = new dynoMenu("ENTOPROCTA", null);
    mymenu.sub[10].sub[0] = new dynoMenu("Loxocorone allax", null);
    mymenu.sub[10].sub[1] = new dynoMenu("Loxosomella aloxiata", null);

    mymenu.sub[11] = new dynoMenu("HEMICHORDATA", null);
    mymenu.sub[11].sub[0] = new dynoMenu("Balanoglossus carnosus", null);
    mymenu.sub[11].sub[1] = new dynoMenu("Saccoglossus kowalevskii", null);

    mymenu.sub[12] = new dynoMenu("MOLLUSCA", null);
    mymenu.sub[12].sub[0] = new dynoMenu("Acanthocardia tuberculata", null);
    mymenu.sub[12].sub[1] = new dynoMenu("Albinaria coerulea", null);
    mymenu.sub[12].sub[2] = new dynoMenu("Aplysia californica", null);
    mymenu.sub[12].sub[3] = new dynoMenu("Argopecten irradians", null);
    mymenu.sub[12].sub[4] = new dynoMenu("Biomphalaria glabrata", null);
    mymenu.sub[12].sub[5] = new dynoMenu("Biomphalaria tenagophila", null);
    mymenu.sub[12].sub[6] = new dynoMenu("Cepaea nemoralis", null);
    mymenu.sub[12].sub[7] = new dynoMenu("Conus textile", null);
    mymenu.sub[12].sub[8] = new dynoMenu("Crassostrea gigas", null);
    mymenu.sub[12].sub[9] = new dynoMenu("Crassostrea virginica", null);
    mymenu.sub[12].sub[10] = new dynoMenu("Dosidicus gigas", null);
    mymenu.sub[12].sub[11] = new dynoMenu("Elysia chlorotica", null);
    mymenu.sub[12].sub[12] = new dynoMenu("Graptacme eborea", null);
    mymenu.sub[12].sub[13] = new dynoMenu("Haliotis rubra", null);
    mymenu.sub[12].sub[14] = new dynoMenu("Hiatella arctica", null);
    mymenu.sub[12].sub[15] = new dynoMenu("Ilyanassa obsoleta", null);
    mymenu.sub[12].sub[16] = new dynoMenu("Katharina tunicata", null);
    mymenu.sub[12].sub[17] = new dynoMenu("Lampsilis ornata", null);
    mymenu.sub[12].sub[18] = new dynoMenu("Loligo bleekeri", null);
    mymenu.sub[12].sub[19] = new dynoMenu("Lophiotoma cerithiformis", null);
    mymenu.sub[12].sub[20] = new dynoMenu("Lottia digitalis", null);
    mymenu.sub[12].sub[21] = new dynoMenu("Mizuhopecten yessoensis", null);
    mymenu.sub[12].sub[22] = new dynoMenu("Mytilus edulis", null);
    mymenu.sub[12].sub[23] = new dynoMenu("Mytilus galloprovincialis", null);
    mymenu.sub[12].sub[24] = new dynoMenu("Mytilus trossulus", null);
    mymenu.sub[12].sub[25] = new dynoMenu("Nautilus macromphalus", null);
    mymenu.sub[12].sub[26] = new dynoMenu("Octopus ocellatus", null);
    mymenu.sub[12].sub[27] = new dynoMenu("Octopus vulgaris", null);
    mymenu.sub[12].sub[28] = new dynoMenu("Placopecten magellanicus", null);
    mymenu.sub[12].sub[29] = new dynoMenu("Pupa strigosa", null);
    mymenu.sub[12].sub[30] = new dynoMenu("Roboastra europaea", null);
    mymenu.sub[12].sub[31] = new dynoMenu("Sepia esculenta", null);
    mymenu.sub[12].sub[32] = new dynoMenu("Sepioteuthis lessoniana", null);
    mymenu.sub[12].sub[33] = new dynoMenu("Sepia officinalis", null);
    mymenu.sub[12].sub[34] = new dynoMenu("Siphonodentalium lobatum", null);
    mymenu.sub[12].sub[35] = new dynoMenu("Sthenoteuthis oualaniensis", null);
    mymenu.sub[12].sub[36] = new dynoMenu("Thais clavigera", null);
    mymenu.sub[12].sub[37] = new dynoMenu("Todarodes pacificus", null);
    mymenu.sub[12].sub[38] = new dynoMenu("Vampyroteuthis infernalis", null);
    mymenu.sub[12].sub[39] = new dynoMenu("Venerupis philippinarum", null);
    mymenu.sub[12].sub[40] = new dynoMenu("Watasenia scintillans", null);

    mymenu.sub[13] = new dynoMenu("NEMATODA", null);
    mymenu.sub[13].sub[0] = new dynoMenu("Ancylostoma duodenale", null);
    mymenu.sub[13].sub[1] = new dynoMenu("Anisakis simplex", null);
    mymenu.sub[13].sub[2] = new dynoMenu("Ascaris suum", null);
    mymenu.sub[13].sub[3] = new dynoMenu("Brugia malayi", null);
    mymenu.sub[13].sub[4] = new dynoMenu("Caenorhabditis briggsae", null);
    mymenu.sub[13].sub[5] = new dynoMenu("Caenorhabditis elegans", null);
    mymenu.sub[13].sub[6] = new dynoMenu("Cooperia oncophora", null);
    mymenu.sub[13].sub[7] = new dynoMenu("Dirofilaria immitis", null);
    mymenu.sub[13].sub[8] = new dynoMenu("Haemonchus contortus", null);
    mymenu.sub[13].sub[9] = new dynoMenu("Necator americanus", null);
    mymenu.sub[13].sub[10] = new dynoMenu("Onchocerca volvulus", null);
    mymenu.sub[13].sub[11] = new dynoMenu("Romanomermis culicivorax", null);
    mymenu.sub[13].sub[12] = new dynoMenu("Steinernema carpocapsae", null);
    mymenu.sub[13].sub[13] = new dynoMenu("Strongyloides stercoralis", null);
    mymenu.sub[13].sub[14] = new dynoMenu("Thaumamermis cosgrovei", null);
    mymenu.sub[13].sub[15] = new dynoMenu("Toxocara canis", null);
    mymenu.sub[13].sub[16] = new dynoMenu("Toxocara malaysiensis", null);
    mymenu.sub[13].sub[17] = new dynoMenu("Trichinella spiralis", null);
    mymenu.sub[13].sub[18] = new dynoMenu("Xiphinema americanum", null);
                        
//     mymenu.sub[13].sub[0] = new dynoMenu("Agamermis sp. BH-2006", null);
//     mymenu.sub[13].sub[1] = new dynoMenu("Ancylostoma duodenale", null);
//     mymenu.sub[13].sub[2] = new dynoMenu("Anisakis simplex", null);
//     mymenu.sub[13].sub[3] = new dynoMenu("Ascaris suum", null);
//     mymenu.sub[13].sub[4] = new dynoMenu("Brugia malayi", null);
//     mymenu.sub[13].sub[5] = new dynoMenu("Caenorhabditis briggsae", null);
//     mymenu.sub[13].sub[6] = new dynoMenu("Caenorhabditis elegans", null);
//     mymenu.sub[13].sub[7] = new dynoMenu("Cooperia oncophora", null);
//     mymenu.sub[13].sub[8] = new dynoMenu("Dirofilaria immitis", null);
//     mymenu.sub[13].sub[9] = new dynoMenu("Haemonchus contortus", null);
//     mymenu.sub[13].sub[10] = new dynoMenu("Heterorhabditis bacteriophora", null);
//     mymenu.sub[13].sub[11] = new dynoMenu("Hexamermis agrotis", null);
//     mymenu.sub[13].sub[12] = new dynoMenu("Necator americanus", null);
//     mymenu.sub[13].sub[13] = new dynoMenu("Onchocerca volvulus", null);
//     mymenu.sub[13].sub[14] = new dynoMenu("Romanomermis culicivorax", null);
//     mymenu.sub[13].sub[15] = new dynoMenu("Romanomermis iyengari", null);
//     mymenu.sub[13].sub[16] = new dynoMenu("Romanomermis nielseni", null);
//     mymenu.sub[13].sub[17] = new dynoMenu("Steinernema carpocapsae", null);
//     mymenu.sub[13].sub[18] = new dynoMenu("Strelkovimermis spiculatus", null);
//     mymenu.sub[13].sub[19] = new dynoMenu("Strongyloides stercoralis", null);
//     mymenu.sub[13].sub[20] = new dynoMenu("Thaumamermis cosgrovei", null);
//     mymenu.sub[13].sub[21] = new dynoMenu("Toxocara canis", null);
//     mymenu.sub[13].sub[22] = new dynoMenu("Toxocara malaysiensis", null);
//     mymenu.sub[13].sub[23] = new dynoMenu("Trichinella spiralis", null);
//     mymenu.sub[13].sub[24] = new dynoMenu("Xiphinema americanum", null);

    mymenu.sub[14] = new dynoMenu("ONYCHOPHORA", null);
    mymenu.sub[14].sub[0] = new dynoMenu("Epiperipatus biolleyi", null);

    mymenu.sub[15] = new dynoMenu("PLACOZOA", null);
    mymenu.sub[15].sub[0] = new dynoMenu("Placozoan sp. BZ10101", null);
    mymenu.sub[15].sub[1] = new dynoMenu("Placozoan sp. BZ49", null);
    mymenu.sub[15].sub[2] = new dynoMenu("Placozoan sp. BZ2423", null);
    mymenu.sub[15].sub[3] = new dynoMenu("Trichoplax adhaerens", null);

    mymenu.sub[16] = new dynoMenu("PLATYHELMINTHES", null);
    mymenu.sub[16].sub[0] = new dynoMenu("Diphyllobothrium latum", null);
    mymenu.sub[16].sub[1] = new dynoMenu("Diphyllobothrium nihonkaiense", null);
    mymenu.sub[16].sub[2] = new dynoMenu("Echinococcus granulosus", null);
    mymenu.sub[16].sub[3] = new dynoMenu("Echinococcus multilocularis", null);
    mymenu.sub[16].sub[4] = new dynoMenu("Echinococcus oligarthrus", null);
    mymenu.sub[16].sub[5] = new dynoMenu("Echinococcus shiquicus", null);
    mymenu.sub[16].sub[6] = new dynoMenu("Echinococcus vogeli", null);
    mymenu.sub[16].sub[7] = new dynoMenu("Fasciola hepatica", null);
    mymenu.sub[16].sub[8] = new dynoMenu("Gyrodactylus salaris", null);
    mymenu.sub[16].sub[9] = new dynoMenu("Gyrodactylus thymalli", null);
    mymenu.sub[16].sub[10] = new dynoMenu("Hymenolepis diminuta", null);
    mymenu.sub[16].sub[11] = new dynoMenu("Microcotyle sebastis", null);
    mymenu.sub[16].sub[12] = new dynoMenu("Paragonimus westermani", null);
    mymenu.sub[16].sub[13] = new dynoMenu("Schistosoma haematobium", null);
    mymenu.sub[16].sub[14] = new dynoMenu("Schistosoma japonicum", null);
    mymenu.sub[16].sub[15] = new dynoMenu("Schistosoma mansoni", null);
    mymenu.sub[16].sub[16] = new dynoMenu("Schistosoma mekongi", null);
    mymenu.sub[16].sub[17] = new dynoMenu("Schistosoma spindale", null);
    mymenu.sub[16].sub[18] = new dynoMenu("Taenia asiatica", null);
    mymenu.sub[16].sub[19] = new dynoMenu("Taenia crassiceps", null);
    mymenu.sub[16].sub[20] = new dynoMenu("Taenia saginata", null);
    mymenu.sub[16].sub[21] = new dynoMenu("Taenia solium", null);
    mymenu.sub[16].sub[22] = new dynoMenu("Trichobilharzia regenti", null);

    mymenu.sub[17] = new dynoMenu("PORIFERA", null);
    mymenu.sub[17].sub[00] = new dynoMenu("Acanthascus dawsoni", null);
    mymenu.sub[17].sub[01] = new dynoMenu("Amphimedon compressa", null);
    mymenu.sub[17].sub[02] = new dynoMenu("Amphimedon queenslandica", null);
    mymenu.sub[17].sub[03] = new dynoMenu("Aplysina fulva", null);
    mymenu.sub[17].sub[04] = new dynoMenu("Axinella corrugata", null);
    mymenu.sub[17].sub[05] = new dynoMenu("Callyspongia plicifera", null);
    mymenu.sub[17].sub[06] = new dynoMenu("Ephydatia muelleri", null);
    mymenu.sub[17].sub[07] = new dynoMenu("Geodia neptuni", null);
    mymenu.sub[17].sub[08] = new dynoMenu("Halisarca dujardini", null);
    mymenu.sub[17].sub[09] = new dynoMenu("Hippospongia lachne", null);
    mymenu.sub[17].sub[10] = new dynoMenu("Igernella notabilis", null);
    mymenu.sub[17].sub[11] = new dynoMenu("Iotrochota birotulata", null);
    mymenu.sub[17].sub[12] = new dynoMenu("Negombata magnifica", null);
    mymenu.sub[17].sub[13] = new dynoMenu("Chondrilla aff. nucula CHOND", null);
    mymenu.sub[17].sub[14] = new dynoMenu("Oscarella carmela", null);
    mymenu.sub[17].sub[15] = new dynoMenu("Plakortis angulospiculatus", null);
    mymenu.sub[17].sub[16] = new dynoMenu("Suberites domuncula", null);
    mymenu.sub[17].sub[17] = new dynoMenu("Tethya actinia", null);
    mymenu.sub[17].sub[18] = new dynoMenu("Topsentia ophiraphidites", null);
    mymenu.sub[17].sub[19] = new dynoMenu("Vaceletia sp. GW948", null);
    mymenu.sub[17].sub[20] = new dynoMenu("Xestospongia muta", null);

    mymenu.sub[18] = new dynoMenu("PRIAPULIDA", null);
    mymenu.sub[18].sub[0] = new dynoMenu("Priapulus caudatus", null);

    mymenu.sub[19] = new dynoMenu("ROTIFERA", null);
    mymenu.sub[19].sub[0] = new dynoMenu("Brachionus plicatilis", null);
    mymenu.sub[19].sub[1] = new dynoMenu("Brachionus plicatilis", null);

    mymenu.sub[20] = new dynoMenu("XENOTURBELLIDA", null);
    mymenu.sub[20].sub[0] = new dynoMenu("Xenoturbella bocki", null);

//    mymenu  = new dynoMenu(null,null);
//    mymenu.sub[0] = new dynoMenu("Category 1",null);
//    mymenu.sub[0].sub[0] = new dynoMenu("Sub 1-1",null);
//    mymenu.sub[0].sub[0].sub[0] = new dynoMenu("Sub 1-1-1","file111.html");
//    mymenu.sub[0].sub[0].sub[1] = new dynoMenu("Sub 1-1-2","file112.html");
//    mymenu.sub[0].sub[1] = new dynoMenu("Sub 1-2","file12x.html");
//    mymenu.sub[0].sub[1].sub[0] = new dynoMenu("Sub 1-2-1","file121.html");
//    mymenu.sub[0].sub[1].sub[1] = new dynoMenu("Sub 1-2-2","kaka.html");
//    mymenu.sub[0].sub[2] = new dynoMenu("file 1-3-1","file131.html");
//
//    mymenu.sub[1] = new dynoMenu("Category 2",null);
//    mymenu.sub[1].sub[0] = new dynoMenu("Sub 2-1",null);
//    mymenu.sub[1].sub[0].sub[0] = new dynoMenu("Sub 2-1-1","file211.html");
//    mymenu.sub[1].sub[0].sub[1] = new dynoMenu("Sub 2-1-2","file212.html");
//    mymenu.sub[1].sub[1] = new dynoMenu("Sub 2-2",null);
//    mymenu.sub[1].sub[1].sub[0] = new dynoMenu("Sub 2-2-1","file221.html");
//    mymenu.sub[1].sub[1].sub[1] = new dynoMenu("Sub 2-2-2","file222.html");
//
//    mymenu.sub[2] = new dynoMenu("Category 3",null);
//    mymenu.sub[2].sub[0] = new dynoMenu("Sub 3-1",null);
//    mymenu.sub[2].sub[0].sub[0] = new dynoMenu("Sub 3-1-1","file311.html");
//    mymenu.sub[2].sub[0].sub[1] = new dynoMenu("Sub 3-1-2","file312.html");
//    mymenu.sub[2].sub[1] = new dynoMenu("Sub 3-2",null);
//    mymenu.sub[2].sub[1].sub[0] = new dynoMenu("Sub 3-2-1","file321.html");
//    mymenu.sub[2].sub[1].sub[1] = new dynoMenu("Sub 3-2-2","file322.html");
//
//    mymenu.sub[3] = new dynoMenu("file 4-1-1","file411.html");

    function clearmenu(m) {
      options  = m.options;
      for (var i=options.length; i>=1; i--) options[i] = null;
      options[0].selected = true;
    }
    
    function setmenu(m,optArray) {
      options  = m.options;
      clearmenu(m);
      if(optArray!=null) {
        for (var i = 0; i < optArray.length; i++) {
          options[i+1]=new Option(optArray[i].txt,optArray[i].txt);
        }
      }
      options[0].selected = true;
    }
    
    function setitems(N, instance) {
      clr=false;
      if(N<depth-1) {
        mmm = mymenu;
        for(i=0;i<=N;i++) {
          sel = eval("document.mm.m"+i);
          selinx = sel.selectedIndex-1;
//      alert("instance "+instance+" i "+i+" selinx "+selinx+" Here<BR>");
          if(selinx<0) break;	
          mmm=mmm.sub[selinx];
        }
        sel = eval("document.mm.m"+i);  // i refers to deeper level of selection since it got i++ in loop, essentially N + 1
        setmenu(sel,mmm.sub);
        i++;
        while(i<depth) {
          sel = eval("document.mm.m"+i);
          clearmenu(sel);
          i++;
        }
      }
    }


    function openwin(url) {
      if(url!=null) window.open(url,"_blank"); }

    var depth=3;
    var d=document;
    for(i=0;i<depth;i++) {
      d.writeln("<SELECT name='m"+i+"' onChange='setitems("+i+")'>");
      for(j=0;j<5;j++) d.writeln("<option >----Please, select-----");
      d.writeln("</select>");
    }
    setitems(0,0);
    </script>
    <BR>
EndOfText
} # sub javascriptHash
    

