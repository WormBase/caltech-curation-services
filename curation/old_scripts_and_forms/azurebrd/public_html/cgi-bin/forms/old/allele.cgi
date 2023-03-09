#!/usr/bin/perl 

# Form to submit Allele information.

# an allele form to make .ace files and email curator
# This version gets headers and footers off of www.wormbase.org with LWP / Jex,
# untaints and gets HTML values with CGI / Jex, sends mail with Mail::Mailer /
# Jex   2002 05 14
#
# Parses data and outputs names of html fields and values (placed in $body) and
# also tried to parse out .ace entries (place in $ace_body).  These are emailed
# and written to the flatfile, then the \n are parsed into <BR>\n for html
# display.  Some html fields don't have a corresponding .ace entry (NULL), so
# they are ignored in the .ace part.  Some are radio buttons that do have an
# entry, so these are part of an if/elsif/else statement that checks if it's one
# of those fields, and gets the appropriate .ace tag from the selected (radio)
# value.  Likewise for Flanking_sequences since they need to specify (left) or
# (right).   2002 11 04
#
# Have more meaningful names for the values of loss/gain_of_function.  Place
# them in Remark specifying loss/gain_of_function.   Parse Allelic_difference
# to [A\/G] format if possible.  2002 11 06
#
# Added penetrance radio and text field.  Added Species radio and text field.
# Added text field for Insertion and Deletion.  Added link to labcore.ace for
# Lab designation.  Rearranged form into Mandatory, Genetic, Physical, Personal
# 2002 11 07
#
# Recessive, Semi_dominant, Dominant, Heat_sensitive, Cold_sensitive no longer
# write vals to .ace file (just tags).  Allele tag no longer has square
# brackets.  2002 11 08
#
# Added Partial to the .ace file.  Parse out line breaks from input.  Put paper
# evidence into Remark for .ace file  2003 03 11
#
# Added Penetrance tag to .ace file if they clicked complete.  Added Reference
# tag if data matches cgc or pmid, otherwise puts it in Remark.  2003 03 12
#
# Added allele to subject line (made ``allele data'' in subject be ``Allele'')  
# 2003 04 15
#
# Changed C. to Caenorhabditis and P. to Pristionchus for Keith.
# Changed Uncharacterized loss_of_function to Uncharacterised_loss_of_function 
# for Keith.
# Added $keith_body variable for parts of body to email but not show on webpage.
# added &findName(); &processAkaSearch(); and &getPgHash(); to find possible
# name matches to the user-submitted name.  2003 08 08
#
# Changed Uncharacterized gain_of_function to Uncharacterised_gain_of_function 
# for Keith.   Added Method tag to be "Allele" unless Deletion or Transposon
# Insertion are chosen under Type of Alterations.  (see $keith_method).  2003 08 14
#
# Changed $keith_method to be "Allele" not "Method" by default, took out the
# words XREF $allele from the Reference tag output.  2003 08 18
#
# Added Mutagen and Isolation.  2004 01 23
#
# Added Chao-Kung's new form and changed the names as appropriate.  Created new
# tables in postgres, and commented out unnecessary parsing of non-used data
# fields.  2004 02 25
#
# Add some text for the Submit button for Mary Ann.  2005 06 13
#
# Take out non-words, spaces, etc. to keep search from tripping on commas.  2005 08 25
#
# Moved notes next to boxes to be below boxes.  Deleted ``Minimum'' from
# ``Minimum 30 bp upstream'' (and downstream) and added text from Mary Ann.
# For Mary Ann.  2006 01 11
#
# Started changing form and email output for Mary Ann.  2006 05 10
#
# Moved fields around, create ale_haploinsufficient, added Carol to the email
# list.  2006 12 11
#
# Added Gary to email recepients list.  For Carol  2007 04 13
#
# If it's spam skip doing anything  2007 08 24
#
# Switched Carol for Karen  2007 09 07
#
# Added Jolene  2007 09 10
#
# Changed help email to gnw@wormbase.org.
# Changed name of gene tag.  for Mary Ann  2007 09 27
#
# Take out Karen.  2009 03 03
#
# Changed help email to genenames@wormbase.org  for Mary Ann  
# Added javascript to disable the return key to prevent form submission if 
# someone presses return on an input field.  for Jolene / Mary Ann  2009 12 14
#
# Changed color of some text from #336699 to #3300000
# Changed color of tables from #DCDDE7 and #FFFF80 to #B0CFFA (more wormbase)
# Shrunk textarea and autocomplete css to fit better.
# Rebalanced sides from 40%/60% to 50%/50%.
# Added alert popup for instructions. (still need instruction)
# Changed /home/postgres/work/pgpopulation/phenont_obo/pop_phenont_obo.pl
#   to only show the tags Jo wants.  2009 12 15
#
# Added Jolene instructions as guessed at from .doc file.  2010 02 11
#
# Added Karen to email recepients.  2010 07 23
#
# changed ontology browser link from elbrus to wormbase
# changed instructions for phenotype section.
# note that this requires :
#   /home/azurebrd/public_html/cgi-bin/testing/javascript/autocomplete/get_phenont_obo.cgi
#   /home/azurebrd/public_html/cgi-bin/testing/javascript/autocomplete/phenont_autocomplete.cgi
# and that this and those have cross-server javascript problems, so change the $domain here 
# and in the  allele_submission.js  to match if wanting the javascript term info to work
# when doing a sync to tazendra, change the $domain.  2013 11 04
#
# yet more changes from Karen to the instructions, and unclear instructions about the term 
# info Gary says is unnecessary, so commenting it out.  making it live.  2013 11 05



my $domain = 'tazendra.caltech.edu';
# my $domain = 'mangolassi.caltech.edu';

my $acefile = "/home/azurebrd/public_html/cgi-bin/data/allele.ace";

my $firstflag = 1;		# flag if first time around (show form for no data)

# use LWP::Simple;
# use Mail::Mailer;

use Jex;			# untaint, getHtmlVar, cshlNew
use strict;
use CGI;
use Fcntl;
use DBI;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n";




my $query = new CGI;
my $user = 'allele_form';	# who sends mail
# my $email = 'ck1@sanger.ac.uk';	# to whom send mail
# my $email = 'cgc@wormbase.org, bastiani@its.caltech.edu';	# to whom send mail
# my $email = 'cgc@wormbase.org, bastiani@its.caltech.edu, garys@its.caltech.edu';	# to whom send mail
# my $email = 'cgc@wormbase.org, jolenef@its.caltech.edu, kyook@its.caltech.edu, garys@its.caltech.edu';	# to whom send mail
# my $email = 'genenames@wormbase.org, jolenef@its.caltech.edu, garys@its.caltech.edu';	# to whom send mail 2007 09 19
# my $email = 'genenames@wormbase.org, jolenef@its.caltech.edu, garys@its.caltech.edu, kyook@its.caltech.edu';	# to whom send mail 2010 07 23
my $email = 'genenames@wormbase.org, garys@its.caltech.edu, kyook@its.caltech.edu';	# to whom send mail 2010 09 09
# my $email = 'azurebrd@tazendra.caltech.edu';	# to whom send mail
my $subject = 'Allele';		# subject of mail
my $body = '';			# body of mail
my $ace_body = '';		# body of ace file
my $keith_body = '';		# body to mail but not show in form output
my $strain_body = '';		# body of strain file


  # point_mutation_gene, transposon_insertion, sequence_insertion, deletion are mututally 
  # exclusive, but all read and added to body, and only read to ace depending on
  # alteration_type
  # added mutagen 2004 01 23
      my @all_vars = qw ( person_evidence submitter_email pos_phenont not_phenont suggest_new gene nature_of_allele penetrance heat_sensitive cold_sensitive hot_temp cold_temp types_of_mutations mutation_info loss_of_function phenotypic_description sequence types_of_alteration alteration_text indel_seq upstream downstream strain species species_other genotype mutagen forward reverse comment );
#       my @all_vars = qw ( person_evidence submitter_email gene nature_of_allele penetrance heat_sensitive cold_sensitive hot_temp cold_temp types_of_mutations mutation_info loss_of_function gain_of_function phenotypic_description sequence types_of_alteration alteration_text indel_seq upstream downstream strain species species_other genotype mutagen forward reverse comment );
# too many vars      my @all_vars = qw ( person_evidence submitter_email gene nature_of_allele penetrance partial_penetrance temperature_sensitive hot_temp cold_temp types_of_mutations mutation_info species species_other loss_of_function gain_of_function paper_evidence lab phenotype phenotypic_description sequence indel_seq strain genomic assoc_strain species species_other alteration_type mutagen forward reverse point_mutation_gene transposon_insertion sequence_insertion deletion upstream downstream comment );
# old form       my @all_vars = qw ( person_evidence submitter_email gene nature_of_allele penetrance partial_penetrance temperature_sensitive loss_of_function gain_of_function paper_evidence lab phenotypic_description sequence genomic assoc_strain species species_other alteration_type mutagen point_mutation_gene transposon_insertion sequence_insertion deletion upstream downstream comment );
#       my @vars = qw( gene strain ref_point sequence start_base end_base upstream downstream alteration insertion person paper phenotypic laboratory );
#       my @nature = qw( recessive semidominant dominant lossoffunction hypomorph amorph unspecifiedloss gainoffunction unspecifiedgain hypermorph neomorph antimorph);
  

print "Content-type: text/html\n\n";
my $title = 'Allele Data Submission Form';
my ($header, $footer) = &cshlNew($title);

# $header = "<html><head></head>";

my $extra_stuff = << "EndOfText";
<style type="text/css">
body {
	margin:0;
	padding:0;
}
#forcedPhenontAutoComplete {
    width:30em; /* set width here or else widget will expand to fit its container */
    padding-bottom:2em;
}
#notPhenontAutoComplete {
    width:30em; /* set width here or else widget will expand to fit its container */
    padding-bottom:2em;
}
</style>
<link rel="stylesheet" type="text/css" href="http://tazendra.caltech.edu/~azurebrd/stylesheets/jex.css" />
<link rel="stylesheet" type="text/css" href="http://yui.yahooapis.com/2.7.0/build/fonts/fonts-min.css" />
<link rel="stylesheet" type="text/css" href="http://yui.yahooapis.com/2.7.0/build/autocomplete/assets/skins/sam/autocomplete.css" />
<script type="text/javascript" src="http://yui.yahooapis.com/2.7.0/build/yahoo-dom-event/yahoo-dom-event.js"></script>
<script type="text/javascript" src="http://yui.yahooapis.com/2.7.0/build/connection/connection-min.js"></script>
<script type="text/javascript" src="http://yui.yahooapis.com/2.7.0/build/datasource/datasource-min.js"></script>
<script type="text/javascript" src="http://yui.yahooapis.com/2.7.0/build/autocomplete/autocomplete-min.js"></script>
<script type="text/javascript" src="http://$domain/~azurebrd/javascript/allele_submission.js"></script>
<script type="text/JavaScript">
<!--Your browser is not set to be Javascript enabled 
function change_type_P(form) {
   var sel_idx = form.types_of_alteration.selectedIndex;
   if (sel_idx == 0){
      document.getElementById("seq_input").value="enter mutation details";
      document.getElementById("indel_input").type="text";
      document.getElementById("indel_input").value="do not use, for insertion + deletion only";
   }
   if (sel_idx == 1){
      document.getElementById("seq_input").value="eg, c to t OR c to ag";
      document.getElementById("indel_input").type="text";
      document.getElementById("indel_input").value="do not use, for insertion + deletion only";
   }
   if (sel_idx == 2){
      document.getElementById("seq_input").value="eg, Tc1";
      document.getElementById("indel_input").type="text";
      document.getElementById("indel_input").value="do not use, for insertion + deletion only";
   }   
   if (sel_idx == 3){
      document.getElementById("seq_input").value="enter inserted seq. or coordinates";
      document.getElementById("indel_input").type="text";
      document.getElementById("indel_input").value="do not use, for insertion + deletion only";
   }
   if (sel_idx == 4){
      document.getElementById("seq_input").value="enter deleted seq. or coordinates";
      document.getElementById("indel_input").type="text";
      document.getElementById("indel_input").value="do not use, for insertion + deletion only";
   }    
   if (sel_idx == 5){
      document.getElementById("seq_input").value="enter deleted seq. or coordinates";
	  document.getElementById("indel_input").type="text";
      document.getElementById("indel_input").value="enter inserted seq. or coordinates";
   }
   if (sel_idx == 6){
      document.getElementById("seq_input").value="copy your info here";
      document.getElementById("indel_input").type="text";
      document.getElementById("indel_input").value="do not use, for insertion + deletion only";
   }   
}
function rollback(){
     document.getElementById("seq_input").value="";
     document.getElementById("indel_input").type="text";
      document.getElementById("indel_input").value="do not use, for insertion + deletion only";
}
function change_type_G(form) {
   var sel_idx = form.types_of_mutations.selectedIndex;
   if (sel_idx == 0){
      document.getElementById("mutation").value="Enter mutation details";
   }
   if (sel_idx == 1){
      document.getElementById("mutation").value="eg, Q(200) to R";
   }
   if (sel_idx == 2){
      document.getElementById("mutation").value="eg, Q(200) -> Amber (Amber_UAG, Ochre_UAA, Opal_UGA)";
   }   
   if (sel_idx == 3){
      document.getElementById("mutation").value="eg, cag -> caa";
   }
   if (sel_idx == 4){
      document.getElementById("mutation").value="please specify";
   }    
   if (sel_idx == 5){
      document.getElementById("mutation").value="please specify";
   }    
}
//-->
</script>

<!--// this javascript disables the return key to prevent form submission if someone presses return on an input field  
// http://74.125.155.132/search?q=cache:FhzD9ine5fQJ:www.webcheatsheet.com/javascript/disable_enter_key.php+disable+return+on+input+submits+form&cd=6&hl=en&ct=clnk&gl=us
// 2009 12 14-->
<script type="text/javascript">
function stopRKey(evt) {
  var evt = (evt) ? evt : ((event) ? event : null);
  var node = (evt.target) ? evt.target : ((evt.srcElement) ? evt.srcElement : null);
  if ((evt.keyCode == 13) && (node.type=="text"))  {return false;}
}
document.onkeypress = stopRKey;
</script> 

</head>  
EndOfText
$header =~ s/<\/head>/$extra_stuff\n<\/head>/;




print "$header\n";		# make beginning of HTML page

&process();			# see if anything clicked
&display();			# show form as appropriate
# print "$footer"; 		# make end of HTML page

sub process {			# see if anything clicked
  my $action;			# what user clicked
  unless ($action = $query->param('action')) { $action = 'none'; }

  if ($action eq 'Submit') {
    $firstflag = "";				# reset flag to not display first page (form)

    my $mandatory_ok = 'ok';			# default mandatory is ok
    my $sender = '';
    my @mandatory = qw ( submitter_email allele person_evidence );
    my %mandatoryName;				# hash of field names to print warnings
    $mandatoryName{submitter_email} = "Submitter Email";
    $mandatoryName{allele} = "Allele";
    $mandatoryName{person_evidence} = "Personal Details";
 
    my $sender_name = '';
    foreach $_ (@mandatory) {			# check mandatory fields
      my ($var, $val) = &getHtmlVar($query, $_);
      if ($_ eq 'submitter_email') {		# check emails
        unless ($val =~ m/@.+\..+/) { 		# if email doesn't match, warn
          print "<FONT COLOR=red SIZE=+2>$val is not a valid email address.</FONT><BR>";
          $mandatory_ok = 'bad';		# mandatory not right, print to resubmit
        } else { $sender = $val; }
      } else { 					# check other mandatory fields
	unless ($val) { 			# if there's no value
          print "<FONT COLOR=red SIZE=+2>$mandatoryName{$_} is a mandatory field.</FONT><BR>";
          $mandatory_ok = 'bad';		# mandatory not right, print to resubmit
        }
        if ($_ eq 'person_evidence') { $sender_name = $val; }
      }
    } # foreach $_ (@mandatory)
# no longer require one of the 3 phenotype fields for Karen 2013 11 01
#     my @one_of_three = qw( pos_phenont not_phenont suggest_new );
#     my $one_of_three_flag = 0;
#     foreach $_ (@one_of_three) {			# check mandatory fields
#       my ($var, $val) = &getHtmlVar($query, $_);
#       if ($val =~ m/./) { $one_of_three_flag++; } }
#     unless ($one_of_three_flag > 0) { 
#       print "<FONT COLOR=red SIZE=+2>You must enter one of the three phenotype fields (see *).</FONT><BR>";
#       $mandatory_ok = 'bad'; }


    my $spam = 0;				# if it's spam skip doing anything  2007 08 24
    foreach $_ (@all_vars) { 			# for all fields, check for spam
      my ($var, $val) = &getHtmlVar($query, $_);
      if ($val =~ m/\S/) { 	# if value entered
        if ($val =~ m/a href/i) { 
          my (@spam) = $val =~ m/(a href)/gi;
          foreach my $sp (@spam) { $spam++; } } } }
#     print "SPAM $spam SPAM<BR>\n"; 
    if ($spam > 0) { print "Ignoring.  This is spam<BR>\n"; return; }

    if ($mandatory_ok eq 'bad') { 
      print "Please click back and resubmit.<P>";
    } else { 					# if email is good, process
      my $result;				# general pg stuff
      my $joinkey;				# the joinkey for pg
      open (OUT, ">>$acefile") or die "Cannot create $acefile : $!";
      my $host = $query->remote_host();		# get ip address
#       $body .= "$sender from ip $host sends :\n\n";	# Mary Ann doesn't want this 2006 05 10

      my %aceName;
      $aceName{allele} = 'Allele';
      $aceName{gene} = 'Gene';
      $aceName{sequence} = 'Sequence';
      $aceName{types_of_alteration} = 'NULL';
      $aceName{alteration_text} = 'NULL';
      $aceName{indel_seq} = 'NULL';
#       $aceName{genomic} = 'NULL';
      $aceName{genotype} = 'NULL';
      $aceName{strain} = 'Strain';
#       $aceName{assoc_strain} = 'NULL';
      $aceName{species} = 'NULL';		# check that species_other wasn't filled
      $aceName{species_other} = 'Species';
      $aceName{mutagen} = 'Mutagen';		# Mutagen  2004 01 23
#       $aceName{alteration_type} = 'NULL';	# Allelic_difference / Insertion / Deletion
#       $aceName{point_mutation_gene} = 'NULL';	# Allelic_difference (needs to be parsed)
#       $aceName{transposon_insertion} = 'NULL';	# Insertion
#       $aceName{sequence_insertion} = 'NULL';	# Insertion
#       $aceName{deletion} = 'NULL';		# Deletion
# # exclusive, so don't default add to .ace
# #       $aceName{transposon_insertion} = 'Transposon_insertion';	# Insertion
# #       $aceName{sequence_insertion} = 'Insertion';	# Insertion
# #       $aceName{deletion} = 'Deletion';		# Deletion
      $aceName{upstream} = 'NULL';		# Flanking_sequences (left)
      $aceName{downstream} = 'NULL';		# Flanking_sequences (right)
      $aceName{nature_of_allele} = 'NULL';	# Recessive / Semi_dominant / Dominant
      $aceName{penetrance} = 'NULL';
#       $aceName{partial_penetrance} = 'Partial';
      $aceName{heat_sensitive} = 'NULL';	# Heat_sensitive / Cold_sensitive
      $aceName{cold_sensitive} = 'NULL';	# Heat_sensitive / Cold_sensitive
      $aceName{hot_temp} = 'NULL';	
      $aceName{cold_temp} = 'NULL';
      $aceName{types_of_mutations} = 'NULL';
      $aceName{mutation_info} = 'NULL';
      $aceName{haploinsufficient} = 'NULL';	
      $aceName{loss_of_function} = 'NULL';	
      $aceName{gain_of_function} = 'NULL';
#       $aceName{loss_of_function} = 'Loss_of_function';	
#       $aceName{loss_of_function} = 'NULL';	# loss of function no longer in model ?
#       $aceName{gain_of_function} = 'Gain_of_function';
#       $aceName{paper_evidence} = 'NULL';	# put in Reference if good, else Remark
# #       $aceName{paper_evidence} = 'Remark';	# put paper evidence in remark for now
# #       $aceName{paper_evidence} = 'Reference';
#       $aceName{lab} = 'Location';
      $aceName{phenotypic_description} = 'Phenotype';
      $aceName{forward} = 'Forward_genetics';
      $aceName{reverse} = 'Reverse_genetics';
      $aceName{person_evidence} = 'NULL';
      $aceName{submitter_email} = 'NULL';
      $aceName{comment} = 'Remark';

      my ($var, $allele) = &getHtmlVar($query, 'allele');
      unless ($allele =~ m/\S/) {			# if there's no allele text
        print "<FONT COLOR='red'>Warning, you have not picked an Allele</FONT>.<P>\n";
      } else {					# if allele text, output
#         print OUT "Allele : [$allele] \n";
#         print "Allele : [$allele]<BR>\n";
        $result = $dbh->do( "INSERT INTO ale_allele (ale_allele) VALUES ('$allele');" );
						# this updated the pg sequence ale_seq to nextval
        $result = $dbh->prepare( "SELECT currval('ale_seq');" );	
        $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
        $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
						# can get currval because last line updated
        my @row = $result->fetchrow;
        $joinkey = $row[0];
        print "Allele entry number $joinkey<BR><BR>\n";
	$allele =~ s///g; $allele =~ s/\n//g; $allele = lc($allele);	# lowercase allele
        $body .= "allele\t$allele\n";
#         $ace_body .= "Allele : $allele\n";
        $ace_body .= "Variation\t$allele\n";	# for Mary Ann 2006 05 10
        $ace_body .= "Allele\n";		# for Mary Ann 2006 05 10
        $ace_body .= "Live\n";			# for Mary Ann 2006 05 10
# 	my $keith_method = 'Allele';
        $subject .= " : $allele";
#         $result = $dbh->do( "INSERT INTO ale_submitter_email VALUES ('$joinkey', '$sender');" );
        $result = $dbh->do( "INSERT INTO ale_ip VALUES ('$joinkey', '$host');" );
  
        foreach my $field (@all_vars) { 			# for all fields, check for data and output
          my ($var, $val) = &getHtmlVar($query, $field);
          if ($val =~ m/\S/) { 	# if value entered

              # $ace_body output varies by field
            if ($aceName{$var} ne 'NULL') {
              if ($var eq 'gene') { $val = lc($val); }		# lowercase gene
              elsif ($var eq 'strain') { $val = uc($val); }	# uppercase strain
              elsif ($var eq 'sequence') { 
                $val =~ s/\..*$//;				# take out anything after . (and .)
                $val = uc($val); }				# uppercase sequence
              else { 1; }
              if ($var eq 'gene') { $ace_body .= "$aceName{$var}\t\/\/\"$val\"\n"; }	# comment out genes for Mary Ann 2006 05 10
                else { $ace_body .= "$aceName{$var}\t\"$val\"\n"; }
            } # if ($aceName{$var} ne 'NULL')

 	    elsif ($var eq 'haploinsufficient') {		# haploinsufficient
              my ($var, $haploinsufficient) = &getHtmlVar($query, 'haploinsufficient');
              $ace_body .= "$haploinsufficient\n"; } 
 	    elsif ($var eq 'loss_of_function') {		# loss and gain only show value (which is tag)
              my ($var, $loss_of_function) = &getHtmlVar($query, 'mutation_info');
              $ace_body .= "$loss_of_function\n"; } 
 	    elsif ($var eq 'gain_of_function') {
              my ($var, $gain_of_function) = &getHtmlVar($query, 'mutation_info');
              $ace_body .= "$gain_of_function\n"; } 
 	    elsif ($var eq 'types_of_mutations') {
              my ($var, $mutation_info) = &getHtmlVar($query, 'mutation_info');
              if ( ($mutation_info =~ m/^eg\, /) || ($mutation_info eq 'please specify') ) { $ace_body .= "$val\n"; }
              else { $ace_body .= "$val\t\"$mutation_info\"\n"; } }
# 	    elsif ($var eq 'assoc_strain') {
#               my ($var, $assoc_strain) = &getHtmlVar($query, 'assoc_strain');
#               if ($assoc_strain) {
#                 my @pairs = split /\n/, $assoc_strain;
#                 foreach (@pairs) {
#                   my ($genotype, $strain) = split/\t/, $_;
# 		  $strain =~ s///g;
# 	          $ace_body .= "Strain\t\"$strain\"\n";
# 	          $strain_body .= "Strain : \"$strain\"\n";
# 	          $strain_body .= "Genotype\t\"$genotype\"\n";
# 	          $strain_body .= "Allele\t\"$allele\"\n\n";
#                 }
#               }
#             }
#             elsif ($var eq 'paper_evidence') {
#               my ($var, $paper_evidence) = &getHtmlVar($query, 'paper_evidence');
#               if ( ($paper_evidence =~ m/cgc/) || ($paper_evidence =~ m/pmid/) ) {
# #                 $ace_body .= "Reference\t\"$paper_evidence\" XREF $allele\n";
#                 $ace_body .= "Reference\t\"$paper_evidence\"\n";
#               } elsif ( ($paper_evidence =~ m/CGC/) || ($paper_evidence =~ m/PMID/) ) {
#                 $paper_evidence =~ s/CGC/cgc/g; $paper_evidence =~ s/PMID/pmid/g;
# #                 $ace_body .= "Reference\t\"$paper_evidence\" XREF $allele\n";
#                 $ace_body .= "Reference\t\"$paper_evidence\"\n";
#               } else { $ace_body .= "Remark\t\"$paper_evidence\"\n"; }
#             }
            elsif ($var eq 'penetrance') {
              my ($var, $penetrance) = &getHtmlVar($query, 'penetrance');
              if ($penetrance eq 'complete') { 
                $ace_body .= "Penetrance\t\"Complete\"\n";
              }
            }
	    elsif ($var eq 'species') { 
              my ($var, $species_other) = &getHtmlVar($query, 'species_other');
	      $val =~ s///g; $val =~ s/\n//g;
	      unless ($species_other) { $ace_body .= "Species\t\"$val\"\n"; }
            }
            elsif ($var eq 'types_of_alteration') {
              my ($var, $alteration_text) = &getHtmlVar($query, 'alteration_text');
              if ( ($alteration_text =~ m/^eg\, /) || ($alteration_text =~ m/^enter /) ) { $ace_body .= "$val\n"; }
              else { 		# if real data entered
                my ($var, $types_of_alteration) = &getHtmlVar($query, 'types_of_alteration');
                if ($types_of_alteration eq 'Point') { 
                  $ace_body .= "Substitution\t\"$alteration_text\"\n"; 
                  $ace_body .= "Method\t\"Substitution_allele\"\n"; }
                elsif ($types_of_alteration eq 'Transposon') { 
                  my ($var, $alteration_text) = &getHtmlVar($query, 'alteration_text');
                  $ace_body .= "Transposon_insertion\t\"$alteration_text\"\n"; 
                  $alteration_text = lc($alteration_text);
                  if ($alteration_text =~ m/tc/) {
                    $ace_body .= "Method\t\"Transposon_insertion\"\n"; }
                  elsif ($alteration_text =~ m/mos/) {
                    $ace_body .= "Method\t\"Mos_insertion\"\n"; }
                  else {
                    $ace_body .= "Method\t\"Unknown\"\n"; } }
                elsif ($types_of_alteration eq 'Insert') { 
                  $ace_body .= "Insertion\t\"$alteration_text\"\n"; 
                  $ace_body .= "Method\t\"Insertion_allele\"\n"; }
                elsif ($types_of_alteration eq 'Delete') { 
                  $ace_body .= "Deletion\t\"$alteration_text\"\n"; 
                  $ace_body .= "Method\t\"Deletion_allele\"\n"; }
                elsif ($types_of_alteration eq 'Indel') { 
                  my ($var, $indel_seq) = &getHtmlVar($query, 'indel_seq');
                  $ace_body .= "Deletion_with_insertion\t\"$indel_seq\"\n"; 
                  $ace_body .= "Method\t\"Deletion_and_insertion_allele\"\n"; }
                elsif ($types_of_alteration eq 'Complex') { 
                  $ace_body .= "Method\t\"Allele\"\n"; }
                else {
                  $ace_body .= "Method\t\"Unknown\"\n"; }
              } # else # if ( ($alteration_text =~ m/^eg\, /) || ($alteration_text =~ m/^enter /) )
            } # elsif ($var eq 'types_of_alteration')
#             elsif ($var eq 'point_mutation_gene') { 1; }	# do nothing, but append to body
#             elsif ($var eq 'transposon_insertion') { 1; }	# do nothing, but append to body
#             elsif ($var eq 'sequence_insertion') { 1; }	# do nothing, but append to body
#             elsif ($var eq 'deletion') { 1; }		# do nothing, but append to body
#             elsif ($var eq 'alteration_type') { 
#               my ($var, $alteration_type) = &getHtmlVar($query, 'alteration_type');
#               if ($alteration_type eq 'point_mutation_gene') {
#                 my $ace_val = $val;
#                 if ($ace_val =~ m/([aAcCtTgG]+) [tT][oO] ([aAcCtTgG]+)/) { 
#                   my $first = uc($1); my $second = uc($2);
#                   $ace_val = '[' . $first . '\/' . $second . ']'; 
#                 }
# 	          $ace_val =~ s///g; $ace_val =~ s/\n//g;
#                 $ace_body .= "Allelic_difference\t\"$ace_val\"\n";
#               }
#               elsif ($alteration_type eq 'transposon_insertion') {
#                 my ($var, $transposon_insertion) = &getHtmlVar($query, 'transposon_insertion');
# 	        $transposon_insertion =~ s///g; $transposon_insertion =~ s/\n//g;
# 	        $ace_body .= "Transposon_insertion\t\"$transposon_insertion\"\n";
# 		$keith_method = 'Transposon_insertion';
#               }
#               elsif ($alteration_type eq 'sequence_insertion') {
#                 my ($var, $sequence_insertion) = &getHtmlVar($query, 'sequence_insertion');
# 	        $ace_body .= "Insertion\n";
# 	        $val = substr($sequence_insertion, 0, 30);
# 	         $val =~ s///g; $val =~ s/\n//g;
# 	        $ace_body .= "Remark\t\"Insertion sequence: $val\"\n";
#               }
#               elsif ($alteration_type eq 'deletion') {
#                 my ($var, $deletion) = &getHtmlVar($query, 'deletion');
# 	        $ace_body .= "Deletion\n";
# 	        $val = substr($deletion, 0, 30);
# 	        $val =~ s///g; $val =~ s/\n//g;
# 	        $ace_body .= "Deletion\t\"Deleted sequence: $val\"\n";
# 		$keith_method = 'Deletion_allele';
#               }
# 	    } # elsif ($var eq 'alteration_type')	# append to ace entry if proper
	    elsif ($var eq 'nature_of_allele') {
	      if ($val eq 'recessive') { $ace_body .= "Recessive\n"; }
	      elsif ($val eq 'semi_dominant') { $ace_body .= "Semi_dominant\n"; }
	      elsif ($val eq 'dominant') { $ace_body .= "Dominant\n"; }
	      else { print "ERROR : $var and $val don't have a matching Ace tag<BR>\n"; }
	    }					# append to ace entry if proper
	    elsif ($var eq 'heat_sensitive') {
              my ($var, $hot_temp) = &getHtmlVar($query, 'hot_temp');
              $ace_body .= "Heat_sensitive\t\"$hot_temp\"\n"; 
            }
	    elsif ($var eq 'cold_sensitive') { 
              my ($var, $cold_temp) = &getHtmlVar($query, 'cold_temp');
              $ace_body .= "Cold_sensitive\t\"$cold_temp\"\n"; 
	    }					# append to ace entry if proper
	    elsif ($var eq 'upstream') {		# now includes downstream for .ace
              my $flanking_seq = $val;
              my ($var, $val) = &getHtmlVar($query, 'downstream');
              $flanking_seq .= "\"\t\"" . $val;
	      $flanking_seq =~ s///g; $flanking_seq =~ s/\n//g;
	      $ace_body .= "Flanking_sequences\t\"$flanking_seq\"\n"; 
	    }					# append to ace entry if proper
            elsif ($field eq 'pos_phenont') { $ace_body .= "Positive Phenotype\t$val\n"; }
            elsif ($field eq 'not_phenont') { $ace_body .= "NOT Phenotype\t$val\n"; }
            elsif ($field eq 'suggest_new') { $ace_body .= "Suggested Phenotype\t$val\n"; }

	    else { 1; }

              # normal $body output for email mostly straightforward
            if ($var eq 'indel_seq') { 1; }	# ignore indel_seq deal under types_of_alteration
            elsif ($var eq 'alteration_text') { 1; }	# ignore indel_seq deal under types_of_alteration
            elsif ($var eq 'types_of_alteration') {
              my ($var, $alteration_text) = &getHtmlVar($query, 'alteration_text');
                if ($val eq 'Point') { $body .= "Substitution\t\"$alteration_text\"\n"; }
                elsif ($val eq 'Transposon') { $body .= "Transposon_insertion\t\"$alteration_text\"\n"; }
                elsif ($val eq 'Insert') { $body .= "Insertion\t\"$alteration_text\"\n"; }
                elsif ($val eq 'Delete') { $body .= "Deletion\t\"$alteration_text\"\n"; }
                elsif ($val eq 'Complex') { $body .= "Complex\t\"$alteration_text\"\n"; }
                elsif ($val eq 'Indel') { 
                  my ($var, $indel_seq) = &getHtmlVar($query, 'indel_seq');
                  $body .= "Deletion\t\"$alteration_text\"\n"; 
                  $body .= "Insertion\t\"$indel_seq\"\n"; }
                else { $body .= "$var\t\"$val\"\n"; } }
            elsif ($var eq 'mutation_info') {	# ignore mutation info if used didn't change data
              if ($val eq 'Enter mutation details') { 1; } }
            else { $body .= "$var\t\"$val\"\n"; }	# output most fields normally
 
            if ($var eq 'person_evidence') { &findName($val); }
            next if ($field eq 'pos_phenont');		# jolene does not want these in postgres  2009 06 12
            next if ($field eq 'not_phenont');		# jolene does not want these in postgres  2009 06 12
            next if ($field eq 'suggest_new');		# jolene does not want these in postgres  2009 06 12
            my $pg_table = 'ale_' . $var;
            $result = $dbh->do( "INSERT INTO $pg_table VALUES ('$joinkey', '$val');" );
          } # if ($val) 
        } # foreach $_ (@vars) 
# 	$ace_body .= "Method\t\"$keith_method\"\n";
        $ace_body .= "\n$strain_body";
        my $full_body = $body . "\n" . $ace_body;
        $keith_body .= "\n" . $body . "\n" . $ace_body;
        print OUT "$full_body\n";			# print to outfile
        close (OUT) or die "cannot close $acefile : $!";
#       print "MAIL TO : $sender :<BR>\n"; 
        $email .= ", $sender";
        &mailer($user, $email, $subject, $keith_body);	# email the data
        $body = "Dear $sender_name,\n\nYou have sucessfully submitted the following data to WormBase. You will be contacted by WormBase within three working days.\n\nIf you wish to modify your submitted information, please go back and resubmit.\n" . $body;
        $body =~ s/\n/<BR>\n/mg;
        $ace_body =~ s/\n/<BR>\n/mg;
#         print "BODY : <BR>$body<BR><BR>\n";
        print "$body<BR><BR>\n";
#         print "ACE : <BR>$ace_body<BR><BR>\n";	# don't print Ace to form for Mary Ann 2006 05 10
#         print "<P><P><P><H1>Thank you for your submission.  You will be contacted by WormBase within three working days.</H1>\n";						# put this message in front of body for Mary Ann 2006 05 10
#         print "If you wish to modify your submitted information, please go back and resubmit.<BR><P> See all <A HREF=\"http://tazendra.caltech.edu/~azurebrd/cgi-bin/data/allele.ace\">new submissions</A>.<P>\n";
        print "If you wish to modify your submitted information, please go back and resubmit.<BR><P>\n";

      } # else # unless ($allele =~ m/\S/)	# this if/then/else should be unnecessary
    } # else # unless ($sender =~ m/@.+\..+/)
  } # if ($action eq 'Submit') 

  elsif ($action eq 'instructions') {
#     print << "EndOfText";		# this text replaced with below for Karen 2013 11 04
# <p>Welcome to our online allele submission form!</p> \n
# <p>1. <b>Positive  phenotypes</b> refer to phenotypes observed by the user. <b>NOT phenotypes</b> refer to phenotypes that have been assayed for and not observed.</p>
# <p>2. Individual phenotype terms can be perused by entering a term name, synonym or ID in the <b>Positive Phenotype</b> or <b>NOT Phenotype</b> fields (e.g. dumpy, Dpy, WBPhenotype:0000583).  Any phenotype term recorded in the adjacent list field will get annotated by a WormBase curator unless the submitter deletes it prior to submission (see step 3).</p>
# <p>3. In order to delete a term, select the desired term within the list and hit the ‘Del’ button at the lower right of the corresponding list field.</p>
# <p>4. The Display of phenotype information field is a non-editable field that displays the current term name, ID, definition, synonyms (if applicable) and its parent-child relationships.</p>
# <p>5. Users can browse the tree-view of the phenotype ontology by clicking the <font color=\"purple\">purple</font> link.</p>
# <p>6. Details such as temperature sensitivity, allele nature etc. can be entered by clicking the appropriate value from the drop down menu.</p>
# <p>7. To propose a new term/definition, please enter your comments in the <b>Suggest new term and definition</b>. If you have any additional suggestions regarding the content or placement of existing phenotype terms within the ontology, please enter your comments in the <b>Suggest new term and definition</b> as well.</p>
# <p>8. Please review your entries and click <b>Submit</b> when ready.</p>
# <p>Thanks for your submission! </p>
# <p>-Team Phenotype</p>
# EndOfText
    print << "EndOfText";
<p>Welcome to our online allele submission form!</p> \n
<p>1. <b>Positive  phenotypes</b> refer to phenotypes observed by the user. <b>NOT phenotypes</b> refer to phenotypes that have been assayed for and not observed.</p>
<p>2. Individual phenotype terms can be perused by entering a term name, synonym or ID in the Positive Phenotype or NOT Phenotype fields (e.g.  dumpy, Dpy, WBPhenotype:0000583).</p>
<p>3. In order to delete a term, select the entered term and hit the 'Del' button at the lower right of the corresponding list field.</p>
<p>4. Users can browse the tree-view of the phenotype ontology by clicking this <a href="http://www.wormbase.org/tools/ontology_browser" target="new">link</a>.  Choose Phenotype as the ontology and enter a phenotype. You will be taken to the browser.</p>
<p>5. To propose a new term/definition, enter your comments in the 'Suggest new term and definition' box. You are welcome to enter additional suggestions regarding the content or placement of existing phenotype terms within the ontology in the same box.</p>
<p>6. Details such as temperature sensitivity, allele nature, etc., can be entered by clicking the appropriate value from their respective drop down menus.</p>
<p>7. Review your entries and click Submit when ready; you will be taken to a confirmation page showing the details of the information you have submitted. A WormBase curator will be in touch once the information has been curated.</p>
<p>Thanks for your submission! </p>
<p>-Team Phenotype</p>
EndOfText
  }

} # sub process


sub display {			# show form as appropriate
  my $action;			# what user clicked
  unless ($action = $query->param('action')) { $action = 'none'; }
  next if ($action eq 'instructions');

  if ($firstflag) { # if first or bad, show form 
    print << "EndOfText";
<body class="yui-skin-sam">
<script language="JavaScript">
<!--
  function SymError(){
    return true;
  }
  window.onerror = SymError;
  var SymRealWinOpen = window.open;

  function SymWinOpen(url, name, attributes){
  return (new Object());
  }
  window.open = SymWinOpen;
//-->
</script>
<script type="text/javascript">
<!--
  function c(p){location.href=p;return false;}
// -->
</script>
<!--
<table border="0" cellpadding="4" cellspacing="1" width="100%">
 <tr>
  <td bgcolor="#b4cbdb" align="center" nowrap style="cursor:hand;" onClick="c('/')"><a href="http://www.wormbase.org/" class="bactive"><font color="#FFFF99"><b>Home</b></font></a></td>
  <td bgcolor="#5870a3" align="center" nowrap style="cursor:hand;" onClick="c('/db/seq/gbrowse?source=wormbase')"><a href="http://www.wormbase.org/db/seq/gbrowse?source=wormbase" class="binactive"><font color="#FFFFFF">Genome</font></a></td>
  <td bgcolor="#5870a3" align="center" nowrap style="cursor:hand;" onClick="c('/db/searches/blat')"><a href="http://www.wormbase.org/db/searches/blat" class="binactive"><font color="#FFFFFF">Blast / Blat</font></a></td>
  <td bgcolor="#5870a3" align="center" nowrap style="cursor:hand;" onClick="c('/db/searches/info_dump')"><a href="http://www.wormbase.org/db/searches/info_dump" class="binactive"><font color="#FFFFFF">Batch Genes</font></a></td>
  <td bgcolor="#5870a3" align="center" nowrap style="cursor:hand;" onClick="c('/db/searches/advanced/dumper')"><a href="http://www.wormbase.org/db/searches/advanced/dumper" class="binactive"><font color="#FFFFFF">Batch Sequences</font></a></td>
  <td bgcolor="#5870a3" align="center" nowrap style="cursor:hand;" onClick="c('/db/searches/strains')"><a href="http://www.wormbase.org/db/searches/strains" class="binactive"><font color="#FFFFFF">Markers</font></a></td>
  <td bgcolor="#5870a3" align="center" nowrap style="cursor:hand;" onClick="c('/db/gene/gmap')"><a href="http://www.wormbase.org/db/gene/gmap" class="binactive"><font color="#FFFFFF">Genetic Maps</font></a></td>
  <td bgcolor="#5870a3" align="center" nowrap style="cursor:hand;" onClick="c('/db/curate/base')"><a href="http://www.wormbase.org/db/curate/base" class="binactive"><font color="#FFFFFF">Submit</font></a></td>
  <td bgcolor="#5870a3" align="center" nowrap style="cursor:hand;" onClick="c('/db/searches/search_index')"><a href="http://www.wormbase.org/db/searches/search_index" class="binactive"><font color="#FFFFFF"><b>More Searches</b></font></a></td>
 </tr>
</table>
-->

<!--<table cellpadding="0" width="100%" nowrap="1" cellspacing="1" border="0">
 <tr valign="top" class="white" nowrap="1">
  <td valign="MIDDLE" align="CENTER" width="50%"><h3>WormBase Release WS115</h3></td>
  <td align="right" cellspacing="1"><a href="http://www.wormbase.org/"><img alt border="0" src="http://www.wormbase.org/images/image_new_colour.jpg"></a></td>
 </tr>
</table><p>-->

<A NAME="form"><H1>Allele Data Submission Form :</H1></A>
<center>Please enter as much information as possible. Email <A HREF="mailto:genenames\@wormbase.org">genenames\@wormbase.org</A> for any questions/problems.<br /><u><b><font color="red">red fields are required</font></u></b></center>
<HR>

<form method="post" action="allele.cgi">
 <table width="100%" height="100%" align="center" cellpadding="1" cellspacing="1">
  <tr>
    <td colspan="2"><table border=0 width="100%" align="center" cellpadding="1" cellspacing="1">
    <!--<td width="34%"><FONT SIZE=+2><B>REQUIRED</B></FONT></td>
    <td width="28%">&nbsp;</td>
    <td width="38%">&nbsp;</td>-->
    <td >&nbsp;</td>
    <td >&nbsp;</td>
    <td >&nbsp;</td>
  </tr>
  <TR>
    <TD ALIGN="right"><U><FONT COLOR='red'><B>Submitter's Name</B></FONT></U><B> :</B> <BR></TD>
    <TD><Input Type="Text" ID="person_evidence" Name="person_evidence" Size="50"></TD>
    <TD><font size="1">(Please enter full name, eg. Sulston, John)</font></TD>
  </TR>
  <TR>
    <TD ALIGN="right"><U><FONT COLOR='red'><B>Submitter's Email</B></FONT></U><B> :</B> <BR></TD>
    <TD><Input Type="Text" Name="submitter_email" Size="50" Maxlength="50"></TD>
    <TD><font size="1">(for contact purpose)</font><BR>If you don't get a confirmation email, contact us at webmaster\@wormbase.org</TD>
  </TR>
  <tr> 
    <TD ALIGN="right"><U><FONT COLOR='red'><B>Allele name</B></FONT></U><B> :</B> <BR>
    <TD><Input Type="Text" Name="allele" Size="50"></TD>
    <TD><font size="1">(eg. e53)</font></TD>
  </tr>
  <tr>
    <TD width="39%" ALIGN="right"><B>WormBase approved gene name :</B></TD>
    <td width="32%"><Input Type="Text" Name="gene" Size="37">
    <!--<td width="29%">--><font size="1">(if known, eg. aap-1)</font></td>
  </tr>
  <!--<TR>
    <TD ALIGN="left"><B><font color="#330000">Species</font></B></TD>
    <TD colspan="2"></TD>
  </TR>-->
  <tr>
    <td colspan="1" align="right"><B>Species :</td><td colspan="2">
    	  <Input Type="radio" checked Name="species" Value="Caenorhabditis elegans">C. elegans
          <Input Type="radio" Name="species" Value="other_species">Other 
      <Input Type="Text" Name="species_other" Size="28"></td> </B></td>
  </tr>
</table>
<tr>
  <td width="50%">
    <!--<table width="99%" height="100%" align="center" cellpadding="1" cellspacing="5" bgcolor="#DCDDE7">-->
    <table width="99%" height="100%" align="center" cellpadding="1" cellspacing="5" bgcolor="#B0CFFA">
     <tr>
        <td colspan="3"><FONT SIZE=+2><B>PHYSICAL</B></FONT></td>
     </tr>
     <TR>
       <TD ALIGN="right"><B>Sequence name<br>of gene :</B></TD>
       <TD><Input Type="Text" Name="sequence" Size="37"><BR>
           <font size="1">(CDS, eg., B0303.3)</font></TD>
     </TR>
     <tr>
       <td colspan="3"><B><font color="#330000">Type of alteration <font color="#000000" size="1"></font></B><font size=1 color="black">&nbsp;</font></td>
     </tr>
     <TR>
      <td>
          <Select Name="types_of_alteration" Size=1 onChange="change_type_P(this.form)">
           <Option Value="" Selected>
           <Option Value="Point">Point / dinucleotide mutation
           <Option Value="Transposon">Transposon Insertion
           <Option Value="Insert">Sequence insertion
           <Option Value="Delete">Sequence deletion
           <Option Value="Indel">Deletion + insertion
           <Option Value="Complex">Complex alterations
          </Select></td>
	  <td><Input Type="text" Name="alteration_text" id="seq_input" Size="37" value="Enter mutation details"></td>
     </TR>
     <TR> 
       <TD></TD>
       <TD><Input Type="text" Name="indel_seq" id ="indel_input" Size="37" value="do not use, for insertion + deletion only"></TD>
     </TR>
     <TR>
       <TD colspan="3"><B><font color="#330000">Flanking sequences</font></B><font size=1> (necessary to map allele to the genome)</font></TD>
     </TR>
     <TR>
       <TD align="right"><B>30 bp upstream :</B></TD>
       <TD><Input Type="Text" Name="upstream" Size="37"></TD>
     </TR>
     <TR>
       <TD align="right"><B>30 bp downstream :</B></TD>
       <TD><Input Type="Text" Name="downstream" Size="37"><BR>
           <FONT SIZE=1>It is only necessary to enter longer flanking sequences if 30bp is not a unique sequence e.g. in a highly repetitive or duplicated region.</FONT></TD>
     </TR>
     <tr>
       <td ALIGN="left" colspan="3"><B><font color="#330000">Origin</font></B></td>
     </tr>
     <TR>
       <TD width="42%" ALIGN="right"><B>Strain :</B></TD>
       <TD width="19%" ALIGN="left"><Input Type="text" Name="strain" Size="37"><BR>
       <!--<TD width="39%">--><font size="1">(Strain in which the allele is maintained, eg, TR1417. If CGC strain, genotype can be omitted)<BR></TD>
     </TR>
     <TR> 
       <TD width="42%" ALIGN="right"><B>Genotype :</B></TD>
       <TD width="19%" ALIGN="left"><Input Type="text" Name="genotype" Size="37"><BR>
       <!--<TD width="39%">--><font size="1">(eg, smg-1 (r904) unc-54 (r293) I)</font></td>
     </TR>
     <TR>
       <TD ALIGN="left"><B><font color="#330000">Isolation</font></B></TD>
     </TR>
     <TR>
       <TD align="right"><B>Mutagen :</B></TD>
       <TD><Input Type="Text" Name="mutagen" Size="37"><BR>
       <font size="1">(eg. EMS, ENU, TMP/UV)</font></TD>
     </TR>
     <TR>
       <TD ALIGN="right"><strong>Forward genetics:</strong></TD>
       <TD><Input Type="Text" Name="forward" Size="37"><BR>
       <font size="1">&nbsp;(standard phenotypic screen)</font></TD>
     </TR>
     <TR>
       <TD ALIGN="right"><strong>Reverse genetics:</strong></TD>
       <TD><Input Type="Text" Name="reverse" Size="37"><BR>
       <font size="1">&nbsp;(directed screen for mutations in a particular gene, using eg, PCR or Tilling) </font></TD>
     </TR>
     <TR>
       <td ALIGN="left"><B><font color="#330000">Type of mutation</font></B></td>
       <td colspan="2">&nbsp;</td>
     </TR>
     <TR>
        <TD colspan=3 align="center">
          <Select Name="types_of_mutations" Size=1 onChange="change_type_G(this.form)">
            <Option Value="" Selected>
            <Option Value="Missense">Missense
            <Option Value="Nonsense">Nonsense
            <Option Value="Silent">Silent
            <Option Value="Splice-site">Splice-site
            <Option Value="Frameshift">Frameshift</Select>
          <Input Type="Text" Name="mutation_info" id="mutation" Size="54" value="Enter mutation details">
       	 </TD>
     </TR>
     <TR></TR><TR></TR><TR></TR><TR></TR>
    </table>
  </td>
   <td width="50%">
<!--    <table width="99%" height="100%" align="center" cellpadding="1" cellspacing="5" bgcolor="#FFFF80">-->
    <table width="99%" height="100%" align="center" cellpadding="1" cellspacing="5" bgcolor="#B0CFFA">
      <tr>
        <td colspan="3"><FONT SIZE=+2><B>GENETIC</B></FONT></td>
      </tr>
<!--      <tr>
        <TD ALIGN="left"><B><font color="#330000">Phenotypic description</font></B></TD>
        <TD colspan="3"></TD>
      </tr>
      <TR>
        <TD ALIGN="right"><B>Phenotypic description :<BR><FONT SIZE=-1 COLOR=red>* Required if any data is entered in the below fields</FONT></B></TD>
        <TD><TEXTAREA Name="phenotypic_description" Rows=3 Cols=28></TEXTAREA>
      </TR>-->
      <tr> 
        <td colspan="3"><B>Please enter <font color="#330000">phenotypes</font> that you observed or that you assayed for and did not observe in the appropriate space below.  
<!--           <a href='javascript:window.alert("<p>Welcome to our online allele submission form!</p> \n
   1. ‘Positive  phenotypes’ refer to phenotypes observed by the user. ‘NOT phenotypes’ refer to phenotypes that have been assayed for and not observed.<br/>
   2. Individual phenotype terms can be perused by entering a term name, synonym or ID in the ‘Positive Phenotype’ or ‘NOT Phenotype’ fields (e.g. dumpy, Dpy, WBPhenotype:0000583).  Any phenotype term recorded in the adjacent list field will get annotated by a WormBase curator unless the submitter deletes it prior to submission (see step 3).<br/>
   3. In order to delete a term, select the desired term within the list and hit the ‘Del’ button at the lower right of the corresponding list field.<br/>
   4. The Display of phenotype information field is a non-editable field that displays the current term name, ID, definition, synonyms (if applicable) and its parent-child relationships.<br/>
   5. Users can browse the tree-view of the phenotype ontology by clicking the purple link.<br/>
   6. Details such as temperature sensitivity, allele nature etc. can be entered by clicking the appropriate value from the drop down menu.<br/>
   7. To propose a new term/definition, please enter your comments in the ‘Suggest new term and definition’. If you have any additional suggestions regarding the content or placement of existing phenotype terms within the ontology, please enter your comments in the ‘Suggest new term and definition’ as well.<br/>
   8. Please review your entries and click ‘Submit’ when ready.<br/>
      Thanks for your submission! <br/>
      -Team Phenotype<br/>");'>(view instructions)</a>-->
           <a href="allele.cgi?action=instructions" target="new">(view instructions)</a>
</B></td>
      </tr>
      <tr>
        <!--<td colspan="3" align="left">Click <b><u><a href="http://elbrus.caltech.edu/cgi-bin/igor/ontology/ontology.cgi?ontology=phenotype" target="new">here</a></u></b> to browse phenotype ontology</td> -- removed 2013 11 04 for Karen-->
        <td colspan="3" align="left">Click <b><u><a href="http://www.wormbase.org/tools/ontology_browser" target="new">here</a></u></b> to browse phenotype ontology</td>
      </tr>
      <!--<tr> commenting out phenotype term info because of unclear instructions of what to do with them.  2013 11 05
        <TD ALIGN="right"><B><font color="grey">Display of phenotype information :</B></font></td>
        <td colspan="2"><textarea id="phenontObo" rows="10" cols="50" readonly="readonly"></textarea></td>
      </tr>
      <tr> -->
        <TD ALIGN="right" valign="top"><!--<FONT SIZE=-1 COLOR=red>1</FONT>--> <B>Enter Positive Phenotypes :</B><br />
          <style="font-family: arial;"><i>click del to delete phenotype</i></style>
        </td>
        <td colspan="2" valign="top">
          <span id="containerForcedPhenontAutoComplete">
            <div id="forcedPhenontAutoComplete">
                  <input size="25" id="forcedPhenontInput" type="text" >
                  <div id="forcedPhenontContainer"></div>
            </div></span>
          <input type="hidden" name="pos_phenont" id="pos_phenont">
          <select name="selectPhenont" id="selectPhenont" multiple="multiple" size="0" onchange="PopulatePhenontObo('Phenont', 'select')" >
          </select>
          <input type="button" value="del" onclick="RemoveSelected('Phenont')">
        </td>
      </tr>
      <tr> 
        <TD ALIGN="right" valign="top"><!--<FONT SIZE=-1 COLOR=red>2</FONT>--> <B>Enter NOT Phenotypes :</b><br />
          <style="font-family: arial;"><i>click del to delete phenotype</i></style>
        </td>
        <td colspan="2" valign="top">
          <span id="containerNotPhenontAutoComplete">
            <div id="notPhenontAutoComplete">
                  <input size="25" id="notPhenontInput" type="text" >
                  <div id="notPhenontContainer"></div>
            </div></span>
          <input type="hidden" name="not_phenont" id="not_phenont">
          <select name="selectNotPhenont" id="selectNotPhenont" multiple="multiple" size="0" onchange="PopulatePhenontObo('NotPhenont', 'select')" >
          </select>
          <input type="button" value="del" onclick="RemoveSelected('NotPhenont')">
        </td>
      </tr>
EndOfText

    print <<"EndOfText";
<script type="text/javascript">
YAHOO.example.BasicRemote = function() {
    // Use an XHRDataSource
    var oDS = new YAHOO.util.XHRDataSource("http://$domain/~azurebrd/cgi-bin/testing/javascript/autocomplete/phenont_autocomplete.cgi");

    // Set the responseType
    oDS.responseType = YAHOO.util.XHRDataSource.TYPE_TEXT;
    // Define the schema of the delimited results
    oDS.responseSchema = {
        recordDelim: "\\n",
        fieldDelim: "\\t"
    };
    oDS.maxCacheEntries = 5;		// Enable caching

    // Instantiate the AutoComplete
    var forcedOAC = new YAHOO.widget.AutoComplete("forcedPhenontInput", "forcedPhenontContainer", oDS);
    forcedOAC.maxResultsDisplayed = 20;
    forcedOAC.forceSelection = true;
    forcedOAC.itemSelectEvent.subscribe(onItemSelect);
    forcedOAC.itemArrowToEvent.subscribe(onItemHighlight);
    forcedOAC.itemMouseOverEvent.subscribe(onItemHighlight);
    return {
        oDS: oDS,
        forcedOAC: forcedOAC
    };
}();
</script>
<script type="text/javascript">
YAHOO.example.BasicRemote = function() {
    // Use an XHRDataSource
    var oDS = new YAHOO.util.XHRDataSource("http://$domain/~azurebrd/cgi-bin/testing/javascript/autocomplete/phenont_autocomplete.cgi");

    // Set the responseType
    oDS.responseType = YAHOO.util.XHRDataSource.TYPE_TEXT;
    // Define the schema of the delimited results
    oDS.responseSchema = {
        recordDelim: "\\n",
        fieldDelim: "\\t"
    };
    oDS.maxCacheEntries = 5;		// Enable caching

    // Instantiate the AutoComplete
    var notOAC = new YAHOO.widget.AutoComplete("notPhenontInput", "notPhenontContainer", oDS);
    notOAC.maxResultsDisplayed = 20;
    notOAC.forceSelection = true;
    notOAC.itemSelectEvent.subscribe(onNotSelect);
    notOAC.itemArrowToEvent.subscribe(onNotHighlight);
    notOAC.itemMouseOverEvent.subscribe(onNotHighlight);
    return {
        oDS: oDS,
        notOAC: notOAC
    };
}();
</script>

      <tr> 
        <!--<td colspan="2" valign="top"><b>If you are unable to find the phenotype you are looking for in the phenotype ontology, please suggest a new term and its definition in the section below, <u>OR</u> type ``no phenotype''.</b></td> changed by Karen 2013 11 05-->
        <td colspan="2" valign="top"><b>If you are unable to find the phenotype you are looking for in the phenotype ontology, please suggest a new term and its definition in the box below.</b></td>
      </tr>
      <tr> </tr>
      <tr> 
        <TD ALIGN="right" valign="top"><!--<FONT SIZE=-1 COLOR=red>3</FONT>--> <B>Suggest new term and definition :</B></td>
        <td colspan="2" valign="top"><textarea name="suggest_new" id="suggest_new" rows="5" cols="50"></textarea></td>
      </tr>
     

      <tr>
        <TD ALIGN="left"><B><font color="#330000">Allele Nature</font></B></TD>
        <td ALIGN="left" colspan="1" ><B>
          <!--Recessive :    <Input Type="radio" Name = "nature_of_allele" Value="recessive">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
          Semi-dominant :<Input Type="radio" Name = "nature_of_allele" Value="semi_dominant">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
          Dominant :     <Input Type="radio" Name = "nature_of_allele" Value="dominant"></td>-->
          <select name="nature_of_allele">
             <option value="" Selected></option>
             <option value="recessive">Recessive</option>
             <option value="semi_dominant">Semi-dominant</option>
             <option value="dominant">Dominant</option>
          </select></td>
      </tr>
      <tr>
        <TD ALIGN="left"><B><font color="#330000">Allele Function</font></B></TD>
        <td ALIGN="left" colspan="1" ><B>
          <select name="nature_of_allele">
             <option value="" Selected></option>
             <option value="Amorph">Amorph</option>
             <option value="Dominant Negative">Dominant Negative</option>
             <option value="Gain_of_function">Gain_of_function</option>
             <option value="Haplo-insufficient">Haplo-insufficient</option>
             <option value="Hypermorph">Hypermorph</option>
             <option value="Hypomorph">Hypomorph</option>
             <option value="Loss_of_function">Loss_of_function</option>
             <option value="Neomorph">Neomorph</option>
             <option value="Uncharacterised_gain_of_function">Uncharacterised_gain_of_function</option>
             <option value="Uncharacterised_loss_of_function">Uncharacterised_loss_of_function</option>
          </select></td>
      </tr>
      <!--<TR>
        <TD ALIGN="right"><B>Haploinsufficient :</B></TD>
        <TD><Input Type="checkbox" Name="haploinsufficient" Value="haploinsufficient"></TD>
      </TR>
      <TR>
        <TD ALIGN="right"><B>Loss of Function :</B></TD>
        <TD><Select Name="loss_of_function"  Size=1>
             <Option Value="" Selected>
             <Option Value="Uncharacterised_loss_of_function">Uncharacterised_loss_of_function
             <Option Value="Hypomorph">Hypomorph
             <Option Value="Amorph">Amorph
            </Select>
        </TD>
      </TR>
      <TR>
        <TD ALIGN="right"><B>Gain of Function :</B></TD>
        <TD><Select Name="gain_of_function"  Size=1>
             <Option Value="" Selected>
             <Option Value="Uncharacterised_gain_of_function">Uncharacterised_gain_of_function
             <Option Value="Hypermorph">Hypermorph
             <Option Value="Neomorph">Neomorph
             <Option Value="Dominant Negative">Dominant Negative
           </Select>
        </TD>
      </TR>-->
      <tr>
        <TD ALIGN="left"><B><font color="#330000">Penetrance</font></B></TD>
        <td ALIGN="left" colspan="1"><B>
		      <!--Complete :<Input Type="radio" Name="penetrance" Value="complete">
		      Partial :<Input Type="radio" Name="penetrance" Value="partial">-->
          <select name="penetrance">
             <option value="" Selected></option>
	     <option value="complete">Complete</option>
	     <option value="partial">Partial</option>
          </select>
        </td>
      </tr>
      </TR>
      <tr>
        <td ALIGN="left" colspan="1"><B><font color="#330000">Temperature Sensitive</font></B></td>
        <td ALIGN="left" colspan="3"><B>
          <select name="heat_sensitive">
             <option value="" Selected></option>
	     <option value="heat_sensitive">Heat Sensitive</option>
	     <option value="cold_sensitive">Cold Sensitive</option>
          </select>
        </td>
      </tr>
      <!--<TR>
        <TD ALIGN="right"><B>Heat sensitive :</B></TD>
        <TD><Input Type="checkbox" Name="heat_sensitive" Value="heat_sensitive">
            <Input Type="Text" Name="hot_temp" Size="32"><BR>
        <font size="1">(If available. Temp. [Celsius] at which phenotype observed, eg. 12C-15C or 30C)</font></TD>
      </TR>
      <TR>
        <TD ALIGN="right"><B>Cold sensitive :</B></TD>
        <TD><Input Type="checkbox" Name="cold_sensitive" Value="cold_sensitive">
            <Input Type="Text" Name="cold_temp" Size="32"></TD>
      </TR>-->
    </table>
  </td>
  </tr>
  <tr></tr><tr></tr><tr></tr><tr></tr><tr></tr><tr></tr>
  <table>
   <td width="1138" colspan="2" align="center"><div align="center">
     <strong><font color="#000000">Other allele comments: 
     <textarea name="comment" cols="50" rows="3"></textarea>
     </font>     </strong>   </div></td>
  </table>
  <table align="center">
  <td align="center">Clicking Submit will email you a confirmation :
   <input type="submit" name="action" value="Submit" onClick="populateSelectFields()">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
   <input name="reset" type="reset" value="Reset" onClick="rollback()">
  </td>
 </table>
</form>

<hr>
<a href="mailto:webmaster\@www.wormbase.org">webmaster\@www.wormbase.org</a><a href="http://www.wormbase.org/copyright.html">&nbsp;&nbsp;&nbsp;Copyright
    Statement</a><a href="http://www.wormbase.org/db/misc/feedback">&nbsp;&nbsp;&nbsp;Send comments or questions to WormBase</a></td> <td class="small" align="right"><a href="http://www.wormbase.org/privacy.html">&nbsp;&nbsp;&nbsp;Privacy Statement</a></td></tr>
</body>
</html>








EndOfText

  } # if (firstflag) show form 
} # sub display

sub findName {
  my $name = shift;
  if ($name !~ /\w/) { 	# if not a valid name, don't search
  } elsif ($name =~ /^\d+$/) { 		# if name is just a number, leave same
#   } elsif ($name =~ m/[\*\?]/) { 	# if it has a * or ?
#     &processpgwild($name);		# ignore pgwild for now
  } else { 			# if it doesn't do simple aka hash thing
    my %aka_hash = &getPgHash();
    &processakasearch($name, %aka_hash);
  }
} # sub findName

sub processakasearch {			# get generated aka's and try to find exact match
  my ($name, %aka_hash) = @_;
  my $search_name = lc($name);
  $search_name =~ s/[^ \w\'\-]//g; 
#   print "<table>\n";
  unless ($aka_hash{$search_name}) { 
#     print "<tr><td>name <font color=red>$name</font> not found</td></tr>\n";
    my @names = split/\s+/, $search_name; $search_name = '';
    foreach my $name (@names) {
      if ($name =~ m/^[a-za-z]$/) { $search_name .= "$name "; }
      else { $search_name .= '*' . $name . '* '; }
    }
#     &processpgwild($name);	# ignore pgwild for now
  } else { 
    my %standard_name;
    my $result = $dbh->prepare ( "select * from two_standardname;" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
    while (my @row = $result->fetchrow ) {
      $standard_name{$row[0]} = $row[2];
    } # while (my @row = $result->fetchrow )

#     print "<tr><td colspan=2 align=center>name <font color=red>$name</font> could be : </td></tr>\n";
#     $keith_body .= "name $name could be : \n";		# changed for Mary Ann 2006 05 10
    $keith_body .= "Allele submission from $name (possibly ";
    my @stuff = sort {$a <=> $b} keys %{ $aka_hash{$search_name} };
    foreach $_ (@stuff) { 		# add url link
      my $joinkey = 'two'.$_;
      my $person = 'wbperson'.$_;
#       $keith_body .= "\t$standard_name{$joinkey} $person\n";
      $keith_body .= "\t$standard_name{$joinkey} $person";	# changed for Mary Ann 2006 05 10
#       print "<tr><td>$standard_name{$joinkey}</td><td><a href=http://www.wormbase.org/db/misc/etree?name=${person};class=person>$person</a></td></tr>\n";
    }
    $keith_body .= ")\n";

  }
  unless ($keith_body) { 
    $keith_body .= $name . " has no match, look here for possible matches : \n";
    $name =~ s/\s+/+/g;
    $keith_body .= 'http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/person_name.cgi?action=Submit&name=' . "$name\n"; }
#   print "</TABLE>\n";
} # sub processAkaSearch

sub getPgHash {				# get akaHash from postgres instead of flatfile
  my $result;
  my %filter;
  my %aka_hash;
  
  my @tables = qw (first middle last);
  foreach my $table (@tables) { 
    $result = $dbh->prepare ( "SELECT * FROM two_aka_${table}name WHERE two_aka_${table}name IS NOT NULL AND two_aka_${table}name != 'NULL' AND two_aka_${table}name != '';" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
    while ( my @row = $result->fetchrow ) {
      if ($row[3]) { 					# if there's a time
        my $joinkey = $row[0];
        $row[2] =~ s/^\s+//g; $row[2] =~ s/\s+$//g;	# take out spaces in front and back
        $row[2] =~ s/[\,\.]//g;				# take out commas and dots
        $row[2] =~ s/_/ /g;				# replace underscores for spaces
        $row[2] = lc($row[2]);				# for full values (lowercase it)
        $row[0] =~ s/two//g;				# take out the 'two' from the joinkey
        $filter{$row[0]}{$table}{$row[2]}++;
        my ($init) = $row[2] =~ m/^(\w)/;		# for initials
        $filter{$row[0]}{$table}{$init}++;
      }
    }
    $result = $dbh->prepare ( "SELECT * FROM two_${table}name WHERE two_${table}name IS NOT NULL AND two_${table}name != 'NULL' AND two_${table}name != '';" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
    while ( my @row = $result->fetchrow ) {
      if ($row[3]) { 					# if there's a time
        my $joinkey = $row[0];
        $row[2] =~ s/^\s+//g; $row[2] =~ s/\s+$//g;	# take out spaces in front and back
        $row[2] =~ s/[\,\.]//g;				# take out commas and dots
        $row[2] =~ s/_/ /g;				# replace underscores for spaces
        $row[2] = lc($row[2]);				# for full values (lowercase it)
        $row[0] =~ s/two//g;				# take out the 'two' from the joinkey
        $filter{$row[0]}{$table}{$row[2]}++;
        my ($init) = $row[2] =~ m/^(\w)/;		# for initials
        $filter{$row[0]}{$table}{$init}++;
      }
    }
  } # foreach my $table (@tables)

  my $possible;
  foreach my $person (sort keys %filter) { 
    foreach my $last (sort keys %{ $filter{$person}{last}} ) {
      foreach my $first (sort keys %{ $filter{$person}{first}} ) {
        $possible = "$first"; $aka_hash{$possible}{$person}++;
        $possible = "$last"; $aka_hash{$possible}{$person}++;
        $possible = "$last $first"; $aka_hash{$possible}{$person}++;
        $possible = "$first $last"; $aka_hash{$possible}{$person}++;
        if ( $filter{$person}{middle} ) {
          foreach my $middle (sort keys %{ $filter{$person}{middle}} ) {
            $possible = "$middle"; $aka_hash{$possible}{$person}++;
            $possible = "$first $middle"; $aka_hash{$possible}{$person}++;
            $possible = "$middle $first"; $aka_hash{$possible}{$person}++;
            $possible = "$last $middle"; $aka_hash{$possible}{$person}++;
            $possible = "$last $first $middle"; $aka_hash{$possible}{$person}++;
            $possible = "$last $middle $first"; $aka_hash{$possible}{$person}++;
            $possible = "$middle $last"; $aka_hash{$possible}{$person}++;
            $possible = "$first $middle $last"; $aka_hash{$possible}{$person}++;
            $possible = "$middle $first $last"; $aka_hash{$possible}{$person}++;
          } # foreach my $middle (sort keys %{ $filter{$person}{middle}} )
        }
      } # foreach my $first (sort keys %{ $filter{$person}{first}} )
    } # foreach my $last (sort keys %{ $filter{$person}{last}} )
  } # foreach my $person (sort keys %filter) 

  return %aka_hash;
} # sub getPgHash


# sub processpgwild {
#   my $input_name = shift;
#   print "<table>\n";
#   print "<tr><td>input</td><td>$input_name</td></tr>\n";
#   my @people_ids;
#   $input_name =~ s/\*/.*/g;
#   $input_name =~ s/\?/./g;
#   my @input_parts = split/\s+/, $input_name;
#   my %input_parts;
#   my %matches;				# keys = wbid, value = amount of matches
#   my %filter;
#   foreach my $input_part (@input_parts) {
#     my @tables = qw (first middle last);
#     foreach my $table (@tables) { 
#       my $result = $dbh->prepare ( "select * from two_aka_${table}name where lower(two_aka_${table}name) ~ lower('$input_part');" );
#       $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
#       while ( my @row = $result->fetchrow ) { $filter{$row[0]}{$input_part}++; }
#       $result = $dbh->prepare ( "select * from two_${table}name where lower(two_${table}name) ~ lower('$input_part');" );
#       $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
#       while ( my @row = $result->fetchrow ) { $filter{$row[0]}{$input_part}++; }
#     } # foreach my $table (@tables)
#   } # foreach my $input_part (@input_parts)
# 
#   foreach my $number (sort keys %filter) {
#     foreach my $input_part (@input_parts) {
#       if ($filter{$number}{$input_part}) { 
#         my $temp = $number; $temp =~ s/two/wbperson/g; $matches{$temp}++; 
#         my $count = length($input_part);
#         unless ($input_parts{$temp} > $count) { $input_parts{$temp} = $count; }
#       }
#     } # foreach my $input_part (@input_parts)
#   } # foreach my $number (sort keys %filter)
#   
#   print "<tr><td></td><td>there are " . scalar(keys %matches) . " match(es).</td></tr>\n";
#   print "<tr></tr>\n";
#   print "</table>\n";
#   print "<table border=2 cellspacing=5>\n";
#   foreach my $person (sort {$matches{$b}<=>$matches{$a} || $input_parts{$b} <=> $input_parts{$a}} keys %matches) { 
#     print "<tr><td><a href=http://www.wormbase.org/db/misc/etree?name=${person};class=person>$person</a></td>\n";
#     print "<td>has $matches{$person} match(es)</td><td>priority $input_parts{$person}</td></tr>\n";
#   } 
#   print "</table>\n";
#   
#   unless (%matches) {
#     print "<font color=red>sorry, no person named '$input_name', please try again</font><p>\n" if $input_name;
#   }
# } # sub processpgwild
