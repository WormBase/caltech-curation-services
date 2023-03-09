#!/usr/bin/perl -w

# nematode mitomapper for Robin Gasser   

# 2009 01 15
#
# use Aaron's layout.  2009 01 21
#
# add md5_hex for creating ftp and web subdirectories to put the result file in.  add ross to email.  2009 01 28


use strict;
use CGI;
use Jex;
use Digest::MD5 qw(md5_hex);


my $query = new CGI;

print "Content-type: text/html\n\n";

# &printHeader("Nematode-Mitomapper");			# print the HTML header
# &javascriptHash();	# UNCOMMENT

print "<HEAD><TITLE>Nematode-Mitomapper</TITLE></HEAD>\n";
# &printHeader();			
# &initHash();
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
<FORM enctype="multipart/form-data" METHOD="POST" ACTION="http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/mitomapper/mitomapper.cgi">
<table cellpadding="0" cellspacing="0">
 <tr>
  <td width="424" height="140" style="vertical-align:top">
  <div style="padding:2.88pt 2.88pt 2.88pt 2.88pt">
  <p><span style="font-size:28.0pt">NemMitoMapper</span><span style="font-size:18.0pt"></span></p>
  <p><span style="font-size:16.0pt">An automated, heuristic, annotation tool for the complete mitochondrial genomes of Nematodes</span></p>
  <p><span> </span></p>

  <p><span style="font-size:12.0pt">Aaron Jex, Ross Hall, Juancarlos Chan, Paul Sternberg, Robin Gasser</span></p>
  <p><span> </span></p>
  </div>
  </td>
  <td>
<a href="http://www.unimelb.edu.au/" target="_blank"><img border="0" width="139" height="140" src="http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/mitomapper/NemMitoMapper_files/image008.jpg"></a><a href="http://www.caltech.edu/" target="_blank"><img border="0" width="138" height="138" src="http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/mitomapper/NemMitoMapper_files/image010.jpg"></a>
  </td>
 </tr>
</table>

<table cellpadding="0" cellspacing="0">

 <tr>
  <td width="704" height="552" style="vertical-align:top">
  <div style="padding:2.88pt 2.88pt 2.88pt 2.88pt">
  <p style="text-align:justify;text-justify:newspaper;text-kashida-space:50%;text-align:justify;text-justify:newspaper;text-kashida-space:50%"><span style="font-size:11.0pt">NemMitoMapper is an automated annotation tool for mitochondrial genomes of Nematodes.<span>  </span>NemMitoMapper uses a number of search parameters to accurately and rapidly determine the identity, position and boundaries of all protein coding, ribosomal and transfer rRNA genes.<span>  </span></span></p>
  <p style="text-align:justify;text-justify:newspaper;text-kashida-space:50%;text-align:justify;text-justify:newspaper;text-kashida-space:50%"><span style="font-size:11.0pt"> </span></p>
  <p style="text-align:justify;text-justify:newspaper;text-kashida-space:50%;text-align:justify;text-justify:newspaper;text-kashida-space:50%"><span style="font-size:11.0pt">The boundaries for coding genes are determined by comparative linear alignment using a reference sequence representing the a published mitochondrial genome for one of the species listed below.<span>  </span>Each coding gene is located using the inferred amino acid sequence of the corresponding gene from the reference species, and step-wise alignment searching of the queried genome in all six reading frames (3 forward and 3 reverse).<span>  </span>Identity is determined by BLOSSUM identity score, and boundaries are determined initially by peptide length and then refined by identification of known Nematode mitochondrial genomic start and stop codons. Ribosomal RNA genes are identified using a similar approach, using nucleotide sequences only. Please note that the closer the evolutionary relationship is between the species from which the queried genome has been derived and the species used as a reference the more accurate the annotation is likely to be.<span>   </span></span></p>

  <p style="text-align:justify;text-justify:newspaper;text-kashida-space:50%;text-align:justify;text-justify:newspaper;text-kashida-space:50%"><span style="font-size:11.0pt"> </span></p>
  <p style="text-align:justify;text-justify:newspaper;text-kashida-space:50%;text-align:justify;text-justify:newspaper;text-kashida-space:50%"><span style="font-size:11.0pt">Transfer rRNA genes are determined by a three part process, combining predicted secondary structure, anti-codon identity and comparative alignment against a database representing all published nematode tRNA genes.</span></p>
  <p style="text-align:justify;text-justify:newspaper;text-kashida-space:50%;text-align:justify;text-justify:newspaper;text-kashida-space:50%"><span style="font-size:11.0pt"> </span></p>
  <p style="text-align:justify;text-justify:newspaper;text-kashida-space:50%;text-align:justify;text-justify:newspaper;text-kashida-space:50%"><span style="font-size:11.0pt">Sequences may be loaded (in FASTA format) into NemMitoMapper either using the text window below (copy and paste), or uploaded as a plain text file from the user’s computer. Presently NemMitoMapper can analyse up to 200 mt genomes per job. Analysis time will be dependent upon the number of sequences.<span>  </span>An average analysis time of approximately 2 minutes per genome should be expected.</span></p>
  <p style="text-align:justify;text-justify:newspaper;text-kashida-space:50%;text-align:justify;text-justify:newspaper;text-kashida-space:50%"><span style="font-size:11.0pt"> </span></p>

  <p style="text-align:justify;text-justify:newspaper;text-kashida-space:50%;text-align:justify;text-justify:newspaper;text-kashida-space:50%"><span style="font-size:11.0pt">Notification of a completed analysis will be sent to the user-specified email address.<span>  </span>Results will be obtainable from a use-specific ftp site (assigned upon completion of the analysis).<span>  </span>All data will be stored on a secure server for 48 hours.</span></p>
  <p style="text-align:justify;text-justify:newspaper;text-kashida-space:50%;text-align:justify;text-justify:newspaper;text-kashida-space:50%"><span style="font-size:11.0pt"> </span></p>
  <p style="text-align:justify;text-justify:newspaper;text-kashida-space:50%;text-align:justify;text-justify:newspaper;text-kashida-space:50%"><span style="font-size:11.0pt">Data output includes a FASTA sequence (rotated to cox1) of the queried mt genome, a SEQUIN table containing all gene boundaries, and graphic files for showing the secondary structure of each identified tRNA gene (in scalable vector graphics (.svg) and published document file (.pdf) format).<span>  </span>Data output will also include a ‘Readme.text’ file with more detailed instructions.</span></p>
  <p style="text-align:justify;text-justify:newspaper;text-kashida-space:50%;text-align:justify;text-justify:newspaper;text-kashida-space:50%"><span style="font-size:11.0pt"> </span></p>

  <p style="text-align:justify;text-justify:newspaper;text-kashida-space:50%;text-align:justify;text-justify:newspaper;text-kashida-space:50%"><span style="font-size:11.0pt">To view and manipulate .svg files, users are directed to the free-ware program </span><span style="font-size:11.0pt"><a href="http://www.inkscape.org/" target="_blank">InkScape</a></span><span style="font-size:11.0pt">. </span><span style="font-size:11.0pt"></span></p>
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

  <p><span style="font-size:11.0pt">Please select the most appropriate reference sequence from the list below (scroll down menu)</span></p>
EndOfText

# &javascriptShow();	# UNCOMMENT

  print <<"EndOfText";
  <SELECT NAME="source" SIZE=1>";
<OPTION>Agamermis sp. BH-2006</OPTION>
<OPTION>Ancylostoma duodenale</OPTION>
<OPTION>Anisakis simplex</OPTION>
<OPTION>Ascaris suum</OPTION>
<OPTION>Brugia malayi</OPTION>
<OPTION>Caenorhabditis briggsae</OPTION>
<OPTION>Caenorhabditis elegans</OPTION>
<OPTION>Cooperia oncophora</OPTION>
<OPTION>Dirofilaria immitis</OPTION>
<OPTION>Haemonchus contortus</OPTION>
<OPTION>Heterorhabditis bacteriophora</OPTION>
<OPTION>Hexamermis agrotis</OPTION>
<OPTION>Necator americanus</OPTION>
<OPTION>Onchocerca volvulus</OPTION>
<OPTION>Romanomermis culicivorax</OPTION>
<OPTION>Romanomermis iyengari</OPTION>
<OPTION>Romanomermis nielseni</OPTION>
<OPTION>Steinernema carpocapsae</OPTION>
<OPTION>Strelkovimermis spiculatus</OPTION>
<OPTION>Strongyloides stercoralis</OPTION>
<OPTION>Thaumamermis cosgrovei</OPTION>
<OPTION>Toxocara canis</OPTION>
<OPTION>Toxocara malaysiensis</OPTION>
<OPTION>Trichinella spiralis</OPTION>
<OPTION>Xiphinema americanum</OPTION>
  </SELECT>

  <P><INPUT TYPE="submit" NAME="action" VALUE="Submit sequence(s)">

  <p><BR></p>
  <p><span style="font-size:11.0pt">Thank you for using NemMitoMapper.<span>  </span>You will be notified when you analysis is complete.</span></p>
  <p><span style="font-size:11.0pt"> </span></p>
  <p><span style="font-size:11.0pt">In publications using NemMitoMapper, please cite:<br>
  </span></p>
  <p><span style="font-size:11.0pt">Aaron Jex, Ross Hall, Juancarlos Chan, Paul Sternberg, Robin Gasser (2010). “NemMitoMapper: an accurate and rapid heuristic annotation tool for the mitochondrial genomes of Nematodes. </span><span style="font-size:11.0pt;font-style:italic">Some Bioinformatic Journal, xxx-xxx.</span></p>

  <p><span style="font-size:11.0pt;font-style:italic"> </span></p>
  <p><span style="font-size:11.0pt;font-style:italic">For technical support, please contact <a href="mailto:ajex\@unimelb.edu.au" target="_blank">ajex\@unimelb.edu.au</a></span><span style="font-size:11.0pt;font-style:italic"></span></p>
  </div>
  </td>
 </tr>
 </FORM>
</table>
EndOfText



#   <BR>
#   <FONT COLOR=RED SIZE=20>TESTING</FONT><BR>
#   Please enter your choice of a raw sequence or FASTA sequence.<BR>
#   Paste your sequence or submit a file<BR>
#   The source currently is only Nematode tRNA<BR>
#   Enter an email to get a link emailed to you when the results are ready, or leave blank to get an ftp URL to check back later.<P>
#   <BR><HR>
#   <P><BR>
#   <FORM enctype="multipart/form-data" METHOD="POST" ACTION="http://tazendra.caltech.edu/cgi-bin/mitomapper.cgi">
#   <TABLE>
#   <TR><TD>FASTA <INPUT TYPE=radio NAME=raw_or_fasta VALUE=fasta></TD></TR>
#   <TR><TD>Raw <INPUT TYPE=radio NAME=raw_or_fasta VALUE=raw CHECKED></TD></TR>
#   <TR><TD>&nbsp; &nbsp; Optional Sequence Name</TD><TD> <INPUT NAME="sequence_name" VALUE=""></TD></TR>
# 
#   <TR><TD>Paste your sequence here :</TD></TR>
#   <TR><TD COLSPAN=2><TEXTAREA NAME="textsequence" ROWS=5 COLS=80></TEXTAREA></TD></TR>
#   <TR><TD>Submit a file :</TD><TD><INPUT NAME="file_input" TYPE="FILE"></TD></TR>
# 
#   <TR><TD>Source</TD><TD><SELECT NAME="source" SIZE=1>";
#       <OPTION VALUE="Nematode tRNA">Nematode tRNA</OPTION>";
#       </SELECT></TD></TR>
# 
# 
#   <TR><TD>Email address </TD><TD><INPUT NAME="email" VALUE=""></TD></TR>
#   <TR><TD><INPUT TYPE="submit" NAME="action" VALUE="Run tRNAscan"></TD></TR>
#   </TABLE>
#   </FORM>
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
    while (<$filename>) { $filedata .= $_; }
#     ($var, my $seqname) = &getHtmlVar($query, "sequence_name");
    ($var, my $source) = &getHtmlVar($query, "source");
    ($var, my $useremail) = &getHtmlVar($query, "email");

    my $output = '';  my $error_flag = 0;
    unless ($sequence or $filedata) { print "<FONT COLOR=RED>Error, you need to type a sequence or submit a file.</FONT><BR>\n "; $error_flag++; }
    unless ($useremail) { print "<FONT COLOR=RED>Error, we need your email to notify you of results.</FONT><BR>\n "; $error_flag++; }
    if ($error_flag) { return; }

    my $md5sum = '';			# get md5sum of sequence and filedata to use as subdirectory for results in ftp and web servers
    if ($sequence) { 
      my $hash_thing = "$sequence $source";
      $md5sum = &md5_hex($hash_thing);
      $output .= "You've sent us sequence \"$sequence\" in $format format with source $source\n"; }
    if ($filedata) { 
      my $hash_thing = "$filedata $source";
      $md5sum = &md5_hex($hash_thing);
      $output .= "You've sent us a file \"$filedata\" in $format format with source $source\n"; }

#     if ($seqname) { $output .= "The optional name is \"$seqname\"\n"; }
    if ($useremail) { $output .= "We will email you when we have results to $useremail\n"; }
    my $location = "http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/mitomapper/results/$md5sum/result_file";
    `mkdir /home/azurebrd/public_html/cgi-bin/forms/mitomapper/results/$md5sum`;	# create a web directory for these results
    `mkdir /var/ftp/uploads/$md5sum`;						# create an ftp directory for these results
    `chmod 777 /var/ftp/uploads/$md5sum`;					# make it readable and writable
#     symlink("/var/ftp/uploads/$md5sum/result_file", "/home/azurebrd/public_html/cgi-bin/forms/mitomapper/results/$md5sum/");
       # symlink where the results will be to the web server (broken until Ross puts result_file there)
    `ln -s "/var/ftp/uploads/$md5sum/result_file" "/home/azurebrd/public_html/cgi-bin/forms/mitomapper/results/$md5sum/"`;
    $output .= "The results will show at <A HREF=\"$location\">$location</A> after X minutes\n";
    my $html_out = $output;
    $html_out =~ s/\n/<BR>\n/g;
    print $html_out;
    my $user = 'nematode_mito_mapper';
#     my $email = 'azurebrd@tazendra.caltech.edu';
    my $email = 'robinbg@unimelb.edu.au, aaronrjex@hotmail.com, rossh@unimelb.edu.au';
    my $subject = 'Nematode-Mitomapper request';
    my $body = $output;
    &mailer($user, $email, $subject, $body);
  } # if ($action eq 'Run tRNAscan')
  else {
    &ShowPgQuery();
  }
#     my $oop;
#     if ( $query->param("pgcommand") ) { $oop = $query->param("pgcommand"); }
#     else { $oop = "nodatahere"; }
#     $oop =~ s/</&lt;/g; $oop =~ s/>/&gt;/g;
#     my $pgcommand = &Untaint($oop);
#     $pgcommand =~ s/&lt;/</g; $pgcommand =~ s/&gt;/>/g;
#     if ( $query->param("perpage") ) { $oop = $query->param("perpage"); }
#       else { $oop = "nodatahere"; }
#     $oop =~ s/</&lt;/g; $oop =~ s/>/&gt;/g;
#     my $perpage = &Untaint($oop);
#     if ($perpage) { 
#       if ($perpage =~ m/(\d+)/) { $MaxEntries = $1; } 
#       elsif ($perpage =~ m/all/i) { $MaxEntries = 'all'; } }
#     if ( $query->param("page") ) { $oop = $query->param("page"); }
#     else { $oop = "1"; }
#     my $page = &Untaint($oop);
#     if ($pgcommand eq "nodatahere") { 
#       print "You must enter a valid PG command<BR>\n"; 
#     } else { # if ($pgcommand eq "nodatahere") 
#       my $result = $conn->exec( "$pgcommand" ); 
#       if ( $pgcommand !~ m/select/i ) {
#         print "PostgreSQL has processed it.<BR>\n";
#         &ShowPgQuery();
#       } else { # if ( $pgcommand !~ m/select/i ) 
# #         &PrintTableLabels();
#         &ProcessTable($page, $pgcommand);
#       } # else # if ( $pgcommand !~ m/select/i ) 
#     } # else # if ($pgcommand eq "nodatahere") 


} # sub Process


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
    </script>
EndOfText
} # sub javascriptHash
    
sub javascriptShow {
  print <<"EndOfText";
    <script language="JavaScript1.1">
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
} # sub javascriptShow


__END__


ACANTHOCEPHALA (1) Hide genomes
Leptorhynchoides thecatus   

 ANNELIDA (5) Hide genomes
Clymenella torquata      Lumbricus terrestris      Orbinia latreillii      Perionyx excavatus      Platynereis dumerilii      

  ARTHROPODA
CHELICERATA (31) Hide genomes
Achelia bituberculata      Amblyomma triguttatum      Ascoschoengastia sp. TATW-1      Carios capensis      Centruroides limpidus      Habronattus oregonensis      Haemaphysalis flava      Heptathela hangzhouensis      Ixodes hexagonus      Ixodes holocyclus      Ixodes persulcatus      Ixodes uriae      Leptotrombidium akamushi      Leptotrombidium deliense      Leptotrombidium pallidum      Limulus polyphemus      Mastigoproctus giganteus      Mesobuthus gibbosus      Mesobuthus martensii      Metaseiulus occidentalis      Nephila clavata      Nymphon gracile      Oltacola gomezi      Ornithoctonus huwena      Ornithodoros moubata      Ornithodoros porcinus      Pseudocellus pearsei      Rhipicephalus sanguineus      Tetranychus urticae      Varroa destructor      Walchia hayashii      
COLLEMBOLA (8) Hide genomes
Cryptopygus antarcticus      Friesea grisea      Gomphiocephalus hodgsoni      Onychiurus orientalis      Orchesella villosa      Podura aquatica      Sminthurus viridis      Tetrodontophora bielanensis  
CRUSTACEA (36) Hide genomes
Argulus americanus      Armillifer armillatus      Artemia franciscana      Callinectes sapidus      Cherax destructor      Daphnia pulex      Eriocheir sinensis      Fenneropenaeus chinensis      Geothelphusa dehaani      Gonodactylus chiragra      Halocaridina rubra      Harpiosquilla harpax      Hutchinsoniella macracantha      Lepeophtheirus salmonis      Ligia oceanica      Litopenaeus vannamei      Lysiosquillina maculata      Macrobrachium rosenbergii      Marsupenaeus japonicus      Megabalanus volcano      Pagurus longicarpus      Panulirus japonicus      Penaeus monodon      Pollicipes mitella      Pollicipes polymerus      Portunus trituberculatus      Pseudocarcinus gigas      Speleonectes tulumensis      Squilla empusa      Squilla mantis      Tetraclita japonica      Tigriopus californicus      Tigriopus japonicus      Triops cancriformis      Triops longicaudatus      Vargula hilgendorfii      
 DIPLURA (3) Hide genomes
Campodea fragilis      Campodea lubbocki      Japyx solifugus
INSECTA (78) Hide genomes
Adoxophyes honmai      Aedes aegypti      Aedes albopictus      Aleurochiton aceris      Aleurodicus dugesii      Anabrus simplex      Anopheles funestus      Anopheles gambiae      Anoplophora glabripennis      Anopheles quadrimaculatus A      Antheraea pernyi      Apis mellifera ligustica      Artogeia melete      Bactrocera carambolae      Bactrocera dorsalis      Bactrocera oleae      Bactrocera papayae      Bactrocera philippinensis      Bemisia tabaci      Campanulotes bidentatus compar      Bombyx mandarina      Bombyx mori      Bothriometopus macrocnemis      Ceratitis capitata      Chrysomya putoria      Cochliomyia hominivorax      Coreana raphaelis      Crioceris duodecimpunctata      Culicoides arakawae      Cydistomyia duplonotata      Dermatobia hominis      Drosophila mauritiana      Drosophila melanogaster      Drosophila sechellia      Drosophila simulans      Drosophila yakuba      Gryllotalpa orientalis      Heterodoxus macropus      Homalodisca coagulata      Haematobia irritans irritans      Lepidopsocid RS-2001      Locusta migratoria      Lucilia sericata      Manduca sexta      Melipona bicolor      Neomaskellia andropogonis      Nesomachilis australica      Ostrinia furnacalis      Ostrinia nubilalis      Oxya chinensis      Pachypsylla venusta      Periplaneta fuliginosa      Petrobius brevistylis      Philaenus spumarius      Phthonandria atrilineata      Pteronarcys princeps      Pyrophorus divergens      Pyrocoelia rufa      Reticulitermes flavipes      Reticulitermes hageni      Reticulitermes santonensis      Reticulitermes virginicus      Ruspolia dubia      Saturnia boisduvalii      Schizaphis graminum      Sclerophasma paresisensis      Simosyrphus grandicornis      Tamolanica tamolana      Tetraleurodes acaciae      Thermobia domestica      Thrips imaginis      Trigoniophthalmus alternatus      Tribolium castaneum      Triatoma dimidiata      Tricholepidion gertschi      Trichophthalma punctata      Trialeurodes vaporariorum      Vanhornia eucnemidarum      
MYRIAPODA (7) Hide genomes
Antrokoreana gracilipes      Bothropolys sp. SP-2004      Lithobius forficatus      Narceus annularus      Scutigerella causeyae      Scutigera coleoptrata      Thyropygus sp. DVL-2001      

 BRACHIOPODA (3) Hide genomes
Laqueus rubellus      Terebratulina retusa      Terebratalia transversa     
 BRYOZOA (2) Hide genomes
Bugula neritina      Flustrellidra hispida       
CHAETOGNATHA (2) Hide genomes
Paraspadella gotoi      Spadella cephaloptera    

  CHORDATA
CEPHALOCHORDATA (8) Hide genomes
Asymmetron inferum      Asymmetron sp. A TK-2007      Branchiostoma belcheri      Branchiostoma floridae      Branchiostoma japonicum      Branchiostoma lanceolatum      Epigonichthys lucayanus      Epigonichthys maldivensis      
HYPEROTRETI (2) Hide genomes
Eptatretus burgeri      Myxine glutinosa      
UROCHORDATA (6) Hide genomes
Ciona intestinalis      Ciona savignyi      Doliolum nationalis      Halocynthia roretzi      Phallusia fumigata      Phallusia mammilata      
VERTEBRATA 

CNIDARIA (28) Hide genomes
Acropora tenuis      Agaricia humilis      Anacropora matthai      Astrangia sp. JVK-2006      Aurelia aurita      Briareum asbestinum      Discosoma sp. CASIZ 168916      Discosoma sp. CASIZ 168915      Rhodactis sp. CASIZ 171755      Chrysopathes formosa      Colpophyllia natans      Metridium senile      Montastraea annularis      Montipora cactus      Montastraea faveolata      Montastraea franksi      Mussa angulosa      Nematostella sp. JVK-2006      Pavona clavus      Pocillopora damicornis      Pocillopora eydouxi      Porites porites      Pseudopterogorgia bipinnata      Ricordea florida      Savalia savaglia      Seriatopora caliendrum      Seriatopora hystrix      Siderastrea radians      

ECHINODERMATA (20) Hide genomes
Acanthaster brevispinus      Acanthaster planci      Antedon mediterranea      Arbacia lixula      Asterias amurensis      Asterina pectinifera      Astropecten polyacanthus      Cucumaria miniata      Florometra serratissima      Gymnocrinus richeri      Luidia quinalia      Ophiopholis aculeata      Ophiura albida      Ophiura lutkeni      Paracentrotus lividus      Phanogenia gracilis      Pisaster ochraceus      Strongylocentrotus droebachiensis      Strongylocentrotus pallidus      Strongylocentrotus purpuratus      

ECHIURA (1) Hide genomes
Urechis caupo      

ENTOPROCTA (2) Hide genomes
Loxocorone allax      Loxosomella aloxiata  

HEMICHORDATA (2) Hide genomes
Balanoglossus carnosus      Saccoglossus kowalevskii      

MOLLUSCA (41) Hide genomes
Acanthocardia tuberculata      Albinaria coerulea      Aplysia californica      Argopecten irradians      Biomphalaria glabrata      Biomphalaria tenagophila      Cepaea nemoralis      Conus textile      Crassostrea gigas      Crassostrea virginica      Dosidicus gigas      Elysia chlorotica      Graptacme eborea      Haliotis rubra      Hiatella arctica      Ilyanassa obsoleta      Katharina tunicata      Lampsilis ornata      Loligo bleekeri      Lophiotoma cerithiformis      Lottia digitalis      Mizuhopecten yessoensis      Mytilus edulis      Mytilus galloprovincialis      Mytilus trossulus      Nautilus macromphalus      Octopus ocellatus      Octopus vulgaris      Placopecten magellanicus      Pupa strigosa      Roboastra europaea      Sepia esculenta      Sepioteuthis lessoniana      Sepia officinalis      Siphonodentalium lobatum      Sthenoteuthis oualaniensis      Thais clavigera      Todarodes pacificus      Vampyroteuthis infernalis      Venerupis philippinarum      Watasenia scintillans      

NEMATODA (25) Hide genomes
Agamermis sp. BH-2006      Ancylostoma duodenale      Anisakis simplex      Ascaris suum      Brugia malayi      Caenorhabditis briggsae      Caenorhabditis elegans      Cooperia oncophora      Dirofilaria immitis      Haemonchus contortus      Heterorhabditis bacteriophora      Hexamermis agrotis      Necator americanus      Onchocerca volvulus      Romanomermis culicivorax      Romanomermis iyengari      Romanomermis nielseni      Steinernema carpocapsae      Strelkovimermis spiculatus      Strongyloides stercoralis      Thaumamermis cosgrovei      Toxocara canis      Toxocara malaysiensis      Trichinella spiralis      Xiphinema americanum      

ONYCHOPHORA (1) Hide genomes
Epiperipatus biolleyi      

PLACOZOA (4) Hide genomes
Placozoan sp. BZ10101      Placozoan sp. BZ49      Placozoan sp. BZ2423      Trichoplax adhaerens      

PLATYHELMINTHES (23) Hide genomes
Diphyllobothrium latum      Diphyllobothrium nihonkaiense      Echinococcus granulosus      Echinococcus multilocularis      Echinococcus oligarthrus      Echinococcus shiquicus      Echinococcus vogeli      Fasciola hepatica      Gyrodactylus salaris      Gyrodactylus thymalli      Hymenolepis diminuta      Microcotyle sebastis      Paragonimus westermani      Schistosoma haematobium      Schistosoma japonicum      Schistosoma mansoni      Schistosoma mekongi      Schistosoma spindale      Taenia asiatica      Taenia crassiceps      Taenia saginata      Taenia solium      Trichobilharzia regenti      

PORIFERA (21) Hide genomes
Acanthascus dawsoni      Amphimedon compressa      Amphimedon queenslandica      Aplysina fulva      Axinella corrugata      Callyspongia plicifera      Ephydatia muelleri      Geodia neptuni      Halisarca dujardini      Hippospongia lachne      Igernella notabilis      Iotrochota birotulata      Negombata magnifica      Chondrilla aff. nucula CHOND      Oscarella carmela      Plakortis angulospiculatus      Suberites domuncula      Tethya actinia      Topsentia ophiraphidites      Vaceletia sp. GW948      Xestospongia muta    

PRIAPULIDA (1) Hide genomes
Priapulus caudatus      

ROTIFERA (2) Hide genomes
Brachionus plicatilis      Brachionus plicatilis      

XENOTURBELLIDA (1) Hide genomes
Xenoturbella bocki      




#!/usr/bin/perl -T

use strict;
use CGI;
use Jex;			# untaint, getHtmlVar, cshlNew

my ($header, $footer) = &cshlNew();

my $query = new CGI;
my $firstflag = '1';

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
