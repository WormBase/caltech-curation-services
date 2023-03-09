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


my $acefile = "/home2/azurebrd/public_html/cgi-bin/data/allele.ace";

my $firstflag = 1;		# flag if first time around (show form for no data)

# use LWP::Simple;
# use Mail::Mailer;

use Jex;			# untaint, getHtmlVar, cshlNew
use strict;
use CGI;
use Fcntl;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $query = new CGI;
my $user = 'allele_form';	# who sends mail
# my $email = 'ck1@sanger.ac.uk';	# to whom send mail
my $email = 'cgc@wormbase.org';	# to whom send mail
# my $email = 'azurebrd@minerva.caltech.edu';	# to whom send mail
my $subject = 'Allele';		# subject of mail
my $body = '';			# body of mail
my $ace_body = '';		# body of ace file
my $keith_body = '';		# body to mail but not show in form output
my $strain_body = '';		# body of strain file

print "Content-type: text/html\n\n";
my $title = 'Allele Data Submission Form';
my ($header, $footer) = &cshlNew($title);
print "$header\n";		# make beginning of HTML page

&process();			# see if anything clicked
&display();			# show form as appropriate
print "$footer"; 		# make end of HTML page

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
      }
    } # foreach $_ (@mandatory)

    if ($mandatory_ok eq 'bad') { 
      print "Please click back and resubmit.<P>";
    } else { 					# if email is good, process
      my $result;				# general pg stuff
      my $joinkey;				# the joinkey for pg
      open (OUT, ">>$acefile") or die "Cannot create $acefile : $!";
      my $host = $query->remote_host();		# get ip address
      $body .= "$sender from ip $host sends :\n\n";
  # point_mutation_gene, transposon_insertion, sequence_insertion, deletion are mututally 
  # exclusive, but all read and added to body, and only read to ace depending on
  # alteration_type
  # added mutagen 2004 01 23
      my @all_vars = qw ( person_evidence submitter_email gene nature_of_allele penetrance partial_penetrance temperature_sensitive loss_of_function gain_of_function paper_evidence lab phenotypic_description sequence genomic assoc_strain species species_other alteration_type mutagen point_mutation_gene transposon_insertion sequence_insertion deletion upstream downstream comment );
#       my @all_vars = qw ( person_evidence submitter_email gene nature_of_allele penetrance partial_penetrance temperature_sensitive loss_of_function gain_of_function paper_evidence lab phenotypic_description sequence genomic assoc_strain species species_other alteration_type point_mutation_gene transposon_insertion sequence_insertion deletion upstream downstream comment );
  # gentoype and strain replaced by assoc_strain
#       my @all_vars = qw ( person_evidence submitter_email gene nature_of_allele penetrance partial_penetrance temperature_sensitive loss_of_function gain_of_function paper_evidence lab phenotypic_description sequence genomic genotype strain species species_other alteration_type upstream downstream comment );
#       my @all_vars = qw ( person_evidence submitter_email gene nature_of_allele penetrance partial_penetrance temperature_sensitive loss_of_function gain_of_function paper_evidence lab phenotypic_description sequence genomic genotype strain species species_other alteration_type point_mutation_gene transposon_insertion sequence_insertion deletion upstream downstream comment );
#       my @all_vars = qw ( gene sequence genomic strain species species_other alteration_type point_mutation_gene insertion deletion upstream downstream nature_of_allele penetrance partial_penetrance temperature_sensitive loss_of_function gain_of_function person_evidence paper_evidence lab submitter_email phenotypic_description comment );
#       my @vars = qw( gene strain ref_point sequence start_base end_base upstream downstream alteration insertion person paper phenotypic laboratory );
#       my @nature = qw( recessive semidominant dominant lossoffunction hypomorph amorph unspecifiedloss gainoffunction unspecifiedgain hypermorph neomorph antimorph);
  
      my %aceName;
      $aceName{allele} = 'Allele';
      $aceName{gene} = 'Gene';
      $aceName{sequence} = 'Sequence';
      $aceName{genomic} = 'NULL';
#       $aceName{genotype} = 'NULL';
#       $aceName{strain} = 'Strain';
      $aceName{assoc_strain} = 'NULL';
      $aceName{species} = 'NULL';		# check that species_other wasn't filled
      $aceName{species_other} = 'Species';
      $aceName{mutagen} = 'Mutagen';		# Mutagen  2004 01 23
      $aceName{alteration_type} = 'NULL';	# Allelic_difference / Insertion / Deletion
      $aceName{point_mutation_gene} = 'NULL';	# Allelic_difference (needs to be parsed)
      $aceName{transposon_insertion} = 'NULL';	# Insertion
      $aceName{sequence_insertion} = 'NULL';	# Insertion
      $aceName{deletion} = 'NULL';		# Deletion
# exclusive, so don't default add to .ace
#       $aceName{transposon_insertion} = 'Transposon_insertion';	# Insertion
#       $aceName{sequence_insertion} = 'Insertion';	# Insertion
#       $aceName{deletion} = 'Deletion';		# Deletion
      $aceName{upstream} = 'NULL';		# Flanking_sequences (left)
      $aceName{downstream} = 'NULL';		# Flanking_sequences (right)
      $aceName{nature_of_allele} = 'NULL';	# Recessive / Semi_dominant / Dominant
      $aceName{penetrance} = 'NULL';
      $aceName{partial_penetrance} = 'Partial';
      $aceName{temperature_sensitive} = 'NULL';	# Heat_sensitive / Cold_sensitive
      $aceName{loss_of_function} = 'Loss_of_function';	
#       $aceName{loss_of_function} = 'NULL';	# loss of function no longer in model ?
      $aceName{gain_of_function} = 'Gain_of_function';
      $aceName{paper_evidence} = 'NULL';	# put in Reference if good, else Remark
#       $aceName{paper_evidence} = 'Remark';	# put paper evidence in remark for now
#       $aceName{paper_evidence} = 'Reference';
      $aceName{lab} = 'Location';
      $aceName{phenotypic_description} = 'Phenotype';
      $aceName{person_evidence} = 'NULL';
      $aceName{submitter_email} = 'NULL';
      $aceName{comment} = 'NULL';

      my ($var, $allele) = &getHtmlVar($query, 'allele');
      unless ($allele =~ m/\S/) {			# if there's no allele text
        print "<FONT COLOR='red'>Warning, you have not picked an Allele</FONT>.<P>\n";
      } else {					# if allele text, output
#         print OUT "Allele : [$allele] \n";
#         print "Allele : [$allele]<BR>\n";
        $result = $conn->exec( "INSERT INTO ale_allele (ale_allele) VALUES ('$allele');" );
						# this updated the pg sequence ale_seq to nextval
        $result = $conn->exec( "SELECT currval('ale_seq');" );	
						# can get currval because last line updated
        my @row = $result->fetchrow;
        $joinkey = $row[0];
        print "Allele entry number $joinkey<BR><BR>\n";
        $body .= "allele\t$allele\n";
	$allele =~ s///g; $allele =~ s/\n//g;
        $ace_body .= "Allele : $allele\n";
	my $keith_method = 'Allele';
        $subject .= " : $allele";
        $result = $conn->exec( "INSERT INTO ale_submitter_email VALUES ('$joinkey', '$sender');" );
        $result = $conn->exec( "INSERT INTO ale_ip VALUES ('$joinkey', '$host');" );
  
        foreach $_ (@all_vars) { 			# for all fields, check for data and output
          my ($var, $val) = &getHtmlVar($query, $_);
          if ($val =~ m/\S/) { 	# if value entered

            if ($aceName{$var} ne 'NULL') { $ace_body .= "$aceName{$var}\t\"$val\"\n"; }
	    elsif ($var eq 'assoc_strain') {
              my ($var, $assoc_strain) = &getHtmlVar($query, 'assoc_strain');
              if ($assoc_strain) {
                my @pairs = split /\n/, $assoc_strain;
                foreach (@pairs) {
                  my ($genotype, $strain) = split/\t/, $_;
		  $strain =~ s///g;
	          $ace_body .= "Strain\t\"$strain\"\n";
	          $strain_body .= "Strain : \"$strain\"\n";
	          $strain_body .= "Genotype\t\"$genotype\"\n";
	          $strain_body .= "Allele\t\"$allele\"\n\n";
                }
              }
            }
            elsif ($var eq 'paper_evidence') {
              my ($var, $paper_evidence) = &getHtmlVar($query, 'paper_evidence');
              if ( ($paper_evidence =~ m/cgc/) || ($paper_evidence =~ m/pmid/) ) {
#                 $ace_body .= "Reference\t\"$paper_evidence\" XREF $allele\n";
                $ace_body .= "Reference\t\"$paper_evidence\"\n";
              } elsif ( ($paper_evidence =~ m/CGC/) || ($paper_evidence =~ m/PMID/) ) {
                $paper_evidence =~ s/CGC/cgc/g; $paper_evidence =~ s/PMID/pmid/g;
#                 $ace_body .= "Reference\t\"$paper_evidence\" XREF $allele\n";
                $ace_body .= "Reference\t\"$paper_evidence\"\n";
              } else { $ace_body .= "Remark\t\"$paper_evidence\"\n"; }
            }
            elsif ($var eq 'penetrance') {
              my ($var, $penetrance) = &getHtmlVar($query, 'penetrance');
              if ($penetrance eq 'complete') { 
                $ace_body .= "Penetrance\tComplete\n";
              }
            }
	    elsif ($var eq 'species') { 
              my ($var, $species_other) = &getHtmlVar($query, 'species_other');
	      $val =~ s///g; $val =~ s/\n//g;
	      unless ($species_other) { $ace_body .= "Species\t\"$val\"\n"; }
            }
            elsif ($var eq 'point_mutation_gene') { 1; }	# do nothing, but append to body
            elsif ($var eq 'transposon_insertion') { 1; }	# do nothing, but append to body
            elsif ($var eq 'sequence_insertion') { 1; }	# do nothing, but append to body
            elsif ($var eq 'deletion') { 1; }		# do nothing, but append to body
            elsif ($var eq 'alteration_type') { 
              my ($var, $alteration_type) = &getHtmlVar($query, 'alteration_type');
              if ($alteration_type eq 'point_mutation_gene') {
                my $ace_val = $val;
                if ($ace_val =~ m/([aAcCtTgG]+) [tT][oO] ([aAcCtTgG]+)/) { 
                  my $first = uc($1); my $second = uc($2);
                  $ace_val = '[' . $first . '\/' . $second . ']'; 
                }
	        $ace_val =~ s///g; $ace_val =~ s/\n//g;
                $ace_body .= "Allelic_difference\t\"$ace_val\"\n";
              }
              elsif ($alteration_type eq 'transposon_insertion') {
                my ($var, $transposon_insertion) = &getHtmlVar($query, 'transposon_insertion');
	        $transposon_insertion =~ s///g; $transposon_insertion =~ s/\n//g;
	        $ace_body .= "Transposon_insertion\t\"$transposon_insertion\"\n";
		$keith_method = 'Transposon_insertion';
              }
              elsif ($alteration_type eq 'sequence_insertion') {
                my ($var, $sequence_insertion) = &getHtmlVar($query, 'sequence_insertion');
	        $ace_body .= "Insertion\n";
	        $val = substr($sequence_insertion, 0, 30);
	         $val =~ s///g; $val =~ s/\n//g;
	        $ace_body .= "Remark\t\"Insertion sequence: $val\"\n";
              }
              elsif ($alteration_type eq 'deletion') {
                my ($var, $deletion) = &getHtmlVar($query, 'deletion');
	        $ace_body .= "Deletion\n";
	        $val = substr($deletion, 0, 30);
	        $val =~ s///g; $val =~ s/\n//g;
	        $ace_body .= "Deletion\t\"Deleted sequence: $val\"\n";
		$keith_method = 'Deletion_allele';
              }
	    } # elsif ($var eq 'alteration_type')	# append to ace entry if proper
	    elsif ($var eq 'nature_of_allele') {
	      if ($val eq 'recessive') { $ace_body .= "Recessive\n"; }
	      elsif ($val eq 'semi_dominant') { $ace_body .= "Semi_dominant\n"; }
	      elsif ($val eq 'dominant') { $ace_body .= "Dominant\n"; }
	      else { print "ERROR : $var and $val don't have a matching Ace tag<BR>\n"; }
	    }					# append to ace entry if proper
	    elsif ($var eq 'temperature_sensitive') {
	      if ($val eq 'heat_sensitive') { $ace_body .= "Heat_sensitive\n"; }
	      elsif ($val eq 'cold_sensitive') { $ace_body .= "Cold_sensitive\n"; }
	      else { print "ERROR : $var and $val don't have a matching Ace tag<BR>\n"; }
	    }					# append to ace entry if proper
	    elsif ($var eq 'upstream') {		# now includes downstream for .ace
              my $flanking_seq = $val;
              my ($var, $val) = &getHtmlVar($query, 'downstream');
              $flanking_seq .= "\"\t\"" . $val;
	      $flanking_seq =~ s///g; $flanking_seq =~ s/\n//g;
	      $ace_body .= "Flanking_sequences\t\"$flanking_seq\"\n"; 
	    }					# append to ace entry if proper
	    else { 1; }
            $body .= "$var\t\"$val\"\n";
            if ($var eq 'person_evidence') { &findName($val); }
            my $pg_table = 'ale_' . $var;
            $result = $conn->exec( "INSERT INTO $pg_table VALUES ('$joinkey', '$val');" );
          } # if ($val) 
        } # foreach $_ (@vars) 
	$ace_body .= "Method\t\"$keith_method\"\n";
        $ace_body .= "\n$strain_body";
        my $full_body = $body . "\n" . $ace_body;
        $keith_body .= "\n" . $body . "\n" . $ace_body;
        print OUT "$full_body\n";			# print to outfile
        close (OUT) or die "cannot close $acefile : $!";
#       print "MAIL TO : $sender :<BR>\n"; 
        $email .= ", $sender";
        &mailer($user, $email, $subject, $keith_body);	# email the data
        $body =~ s/\n/<BR>\n/mg;
        $ace_body =~ s/\n/<BR>\n/mg;
        print "BODY : <BR>$body<BR><BR>\n";
        print "ACE : <BR>$ace_body<BR><BR>\n";
        print "<P><P><P><H1>Thank you, your info will be updated shortly.</H1>\n";
        print "If you wish to modify your submitted information, please go back and resubmit.<BR><P> See all <A HREF=\"http://minerva.caltech.edu/~azurebrd/cgi-bin/data/allele.ace\">new submissions</A>.<P>\n";

      } # else # unless ($allele =~ m/\S/)	# this if/then/else should be unnecessary
    } # else # unless ($sender =~ m/@.+\..+/)
  } # if ($action eq 'Submit') 
} # sub process


sub display {			# show form as appropriate
  if ($firstflag) { # if first or bad, show form 
    print <<"EndOfText";


<A NAME="form"><H1>Allele Data Submission Form :</H1></A>
<B>Please fill out as many fields as possible.  First three fields are required.</B><P>

<HR>


<FORM METHOD="POST" ACTION="allele_old.cgi">
  <TABLE>
    <TR></TR> <TR></TR> <TR></TR> <TR></TR>
    <TR></TR> <TR></TR> <TR></TR> <TR></TR>
    <TR></TR> <TR></TR> <TR></TR> <TR></TR>
    <TR></TR> <TR></TR> <TR></TR> <TR></TR>
    <TR><TD><FONT SIZE=+2><B>REQUIRED</B></FONT></TD></TR>
    <TR><TD ALIGN="right"><U><FONT COLOR='red'><B>Allele</FONT></U> :</B></TD>
        <TD><Input Type="Text" Name="allele" Size="50"></TD>
        <TD>(eg. e53) <!--=&gt; main tag--></TD></TR>
    <TR><TD ALIGN="right"><U><FONT COLOR='red'><B>Submitter's Name</FONT></U> :</B>
	   <BR>Please enter full name, eg. John Sulston</TD>
        <TD><Input Type="Text" Name="person_evidence" Size="50"></TD>
        <TD><!--=&gt; Author tag (Isolation)?? Need Caltech feedback--></TD></TR>
    <TR><TD ALIGN="right"><U><FONT COLOR='red'><B>Submitter's Email</FONT></U> :</B>
	   <BR>(please enter for contact purpose)</TD>
        <TD><Input Type="Text" Name="submitter_email" Size="50" Maxlength="50"></TD>
        <TD><!--=&gt; for curator's info--></TD></TR>

    <TR></TR> <TR></TR> <TR></TR> <TR></TR>
    <TR></TR> <TR></TR> <TR></TR> <TR></TR>
    <TR></TR> <TR></TR> <TR></TR> <TR></TR>
    <TR></TR> <TR></TR> <TR></TR> <TR></TR>
    <TR><TD><FONT SIZE=+2><B>GENETIC</B></FONT></TD></TR>

    <TR><TD ALIGN="right"><B>CGC locus name of gene :</B></TD>
        <TD><Input Type="Text" Name="gene" Size="50"></TD>
        <TD>(if known, eg. aap-1) <!--=&gt; Gene tag--></TD></TR>

    <TR></TR> <TR></TR> <TR></TR> <TR></TR>
    <TR></TR> <TR></TR> <TR></TR> <TR></TR>
    <TR><TD ALIGN="left"><B>Nature of Alleles :</B></TD></TR>
    <TR><TD ALIGN="right"><B>Recessive :</B>
	   <Input Type="radio" Name="nature_of_allele" Value="recessive"></TD>
	<TD></TD>
	<TD><!--=&gt; Recessive tag (Description)--></TD></TR>
    <TR><TD ALIGN="right"><B>Semi-dominant :</B>
	   <Input Type="radio" Name="nature_of_allele" Value="semi_dominant"></TD>
        <TD></TD>
	<TD><!--=&gt; Semi_dominant tag (Description)--></TD></TR>
    <TR><TD ALIGN="right"><B>Dominant :</B>
	   <Input Type="radio" Name="nature_of_allele" Value="dominant"></TD>
	<TD></TD>
        <TD><!--=&gt; Dominant tag (Description)--></TD></TR>

    <TR></TR> <TR></TR> <TR></TR> <TR></TR>
    <TR></TR> <TR></TR> <TR></TR> <TR></TR>
    <TR><TD ALIGN="left"><B>Penetrance :</B></TD>
	<TD></TD>
	<TD>% animals displaying the phenotype</TD></TR>
    <TR><TD ALIGN="right"><B>Complete :</B>
	   <Input Type="radio" Name="penetrance" Value="complete"></TD>
	<TD></TD>
	<TD></TD></TR>
    <TR><TD ALIGN="right"><B>Partial :</B>
	   <Input Type="radio" Name="penetrance" Value="partial"></TD>
        <TD><Input Type="Text" Name="partial_penetrance" Size="50"></TD>
	<TD></TD></TR>

    <TR></TR> <TR></TR> <TR></TR> <TR></TR>
    <TR></TR> <TR></TR> <TR></TR> <TR></TR>
    <TR><TD ALIGN="left"><B>Temperature Sensitive :</B></TD></TR>
    <TR><TD ALIGN="right"><B>Heat sensitive :</B>
	   <Input Type="radio" Name="temperature_sensitive" Value="heat_sensitive"></TD>
	<TD></TD>
	<TD><!--=&gt; Heat_sensitive tag (Temperature_sensitive)--></TD></TR>
    <TR><TD ALIGN="right"><B>Cold sensitive :</B>
	   <Input Type="radio" Name="temperature_sensitive" Value="cold_sensitive"></TD>
	<TD></TD>
	<TD><!--=&gt; Cold_sensitive tag (Temperature_sensitive)--></TD></TR>

    <TR></TR> <TR></TR> <TR></TR> <TR></TR>
    <TR></TR> <TR></TR> <TR></TR> <TR></TR>
    <TR></TR><TR><TD ALIGN="right"><B>Loss of Function :</B></TD>
        <TD><Select Name="loss_of_function"  Size=1>
                   <Option Value="" Selected>Not Applicable
                   <Option Value="Uncharacterised_loss_of_function">Uncharacterised_loss_of_function
                   <Option Value="Haplo-insufficient">Haplo-insufficient
                   <Option Value="Hypomorph">Hypomorph      
                   <Option Value="Null (amorph)">Null (amorph)
            </Select></TD>
        <TD><!--Note: Drop-down option goes to Remark tag, as currently there is no such tag in
            the ?Allele model. Maybe in the future?--></TD></TR><TR></TR>

    <TR></TR><TR><TD ALIGN="right"><B>Gain of Function :</B></TD>
        <TD><Select Name="gain_of_function"  Size=1>
                   <Option Value="" Selected>Not Applicable
                   <Option Value="Uncharacterised_gain_of_function">Uncharacterised_gain_of_function
                   <Option Value="Hypermorph">Hypermorph
                   <Option Value="Neomorph">Neomorph
                   <Option Value="Dominant Negative">Dominant Negative
            </Select></TD>
        <TD><!--Note: Drop-down option goes to Remark tag, as currently there is no such tag in
            the ?Allele model. Maybe in the future?--></TD></TR><TR></TR>

    <TR></TR> <TR></TR> <TR></TR> <TR></TR>
    <TR></TR> <TR></TR> <TR></TR> <TR></TR>
    <TR><TD ALIGN="right"><B>Has this allele been published?</B><BR>If so, where:<BR>
	   (e.g. journal reference, PMID or CGC number. <BR>
	   Please leave blank if unpublished)</TD>
        <TD><Input Type="Text" Name="paper_evidence" Size="50"></TD>
        <TD><!--=&gt; ?? Need Caltech feedback--></TD></TR>
    <TR><TD ALIGN="right"><B>CGC Laboratory designation</B><BR>
	   (if known, eg., CB, PS.  <BR>See list 
	    <A HREF="http://minerva.caltech.edu/~azurebrd/cgi-bin/data/labcore.ace">here</A>.)</TD>
        <TD><Input Type="Text" Name="lab" Size="50" Maxlength="3"></TD>
        <TD><!--=&gt; Location ?Laboratory XREF Alleles--></TD></TR>

    <TR></TR><TR><TD ALIGN="right"><B>Phenotypic Description :</B></TD>
        <TD><TEXTAREA Name="phenotypic_description" Rows=5 Cols=50></TEXTAREA></TD>
        <TD><!--=&gt; Phenotype tag ?Text--></TD></TR><TR></TR>

    <TR></TR> <TR></TR> <TR></TR> <TR></TR>
    <TR></TR> <TR></TR> <TR></TR> <TR></TR>
    <TR></TR> <TR></TR> <TR></TR> <TR></TR>
    <TR></TR> <TR></TR> <TR></TR> <TR></TR>
    <TR><TD><FONT SIZE=+2><B>PHYSICAL</B></FONT></TD></TR>
    <TR><TD ALIGN="right"><B>Sequence name of gene :</B></TD>
        <TD><Input Type="Text" Name="sequence" Size="50"></TD>
        <TD>(CDS, eg., B0303.3) <!--=&gt;Sequence tag (Source)--></TD></TR>
    <TR><TD ALIGN="right"><B>Genomic Sequence that contains allele :</B></TD>
        <TD><Input Type="Text" Name="genomic" Size="50"></TD>
        <TD>(eg., B0303) <!--=&gt; for curator's info--></TD></TR>

    <TR></TR> <TR></TR> <TR></TR> <TR></TR>
    <TR></TR> <TR></TR> <TR></TR> <TR></TR>
    <TR><TD ALIGN="right"><B>Associated strain :</B></TD>
<!--    <TR><TD ALIGN="left"><B>Associated strain :</B></TD>-->
        <TD><TEXTAREA Name="assoc_strain" Rows=5 Cols=50></TEXTAREA></TD>
        <TD>Please enter the Genotype and Strain number in tab-delimited format. e.g.<BR>
	    Genotype&lt;TAB&gt;Strain# &lt;Enter&gt;<BR></TD></TR><TR></TR>
   
<!--    <TR><TD ALIGN="right"><B>Genotype :</B>
        <TD><Input Type="Text" Name="genotype" Size="50"></TD>
        <TD>(Please enter strain name if known, eg. AA18.  If not please enter both strain name and genotype) <!--=&gt; strain tag</TD></TR>
    <TR><TD ALIGN="right"><B>Strain Name :</B>
        <TD><Input Type="Text" Name="strain" Size="50"></TD>
        <TD></TD></TR>-->

    <TR></TR> <TR></TR> <TR></TR> <TR></TR>
    <TR></TR> <TR></TR> <TR></TR> <TR></TR>
    <TR><TD ALIGN="left"><B>Species :</B></TD>
	<TD></TD>
	<TD></TD></TR>
    <TR><TD ALIGN="right"><B>Caenorhabditis elegans :</B>
	   <Input Type="radio" checked Name="species" Value="Caenorhabditis elegans"></TD>
	<TD></TD>
	<TD></TD></TR>
    <TR><TD ALIGN="right"><B>Caenorhabditis briggsae :</B>
	   <Input Type="radio" Name="species" Value="Caenorhabditis briggsae"></TD>
	<TD></TD>
	<TD></TD></TR>
    <TR><TD ALIGN="right"><B>Pristionchus pacificus :</B>
	   <Input Type="radio" Name="species" Value="Pristionchus pacificus"></TD>
	<TD></TD>
	<TD></TD></TR>
    <TR><TD ALIGN="right"><B>Other :</B>
	   <Input Type="radio" Name="species" Value="other"></TD>
        <TD><Input Type="Text" Name="species_other" Size="50"></TD>
	<TD></TD></TR>

    <TR></TR> <TR></TR> <TR></TR> <TR></TR>
    <TR></TR> <TR></TR> <TR></TR> <TR></TR>
    <TR></TR><TR><TD ALIGN="left"><B>Isolation :</B></TD></TR>
    <TR><TD align="right"><B>Mutagen :</B></TD>
        <TD><Input Type="Text" Name="mutagen" Size="50"></TD>
        <TD> (eg. EMS, ENU)</TD></TR>

    <TR></TR> <TR></TR> <TR></TR> <TR></TR>
    <TR></TR> <TR></TR> <TR></TR> <TR></TR>
    <TR></TR><TR><TD ALIGN="left"><B>Type of Alterations :</B></TD></TR>
    <TR><TD align="right"><B>Point mutation/dinucleotide mutation :</B>
           <Input Type="radio" Name="alteration_type" Value="point_mutation"></TD>
        <TD><Input Type="Text" Name="point_mutation_gene" Size="50"></TD>
        <TD> (eg. c to t OR c to ag) <!--=&gt; Allelic_difference tag (Sequence_details)--></TD></TR>
    <TR><TD align="right"><B>Transposon Insertion :</B>
	   <Input Type="radio" Name="alteration_type" Value="transposon_insertion"></TD>
        <TD><Input Type="Text" Name="transposon_insertion" Size="50"></TD>
	<TD>(e.g. Tc1) <!--=&gt; Transposon_insertion tag (Description)--></TD></TR>
    <TR><TD align="right"><B>Sequence Insertion :</B>
	   <Input Type="radio" Name="alteration_type" Value="sequence_insertion"></TD>
        <TD><Input Type="Text" Name="sequence_insertion" Size="50"></TD>
	<TD>(e.g. atctggaacc...) <!--=&gt; Insertion tag (Description)--></TD></TR>
    <TR><TD align="right"><B>Deletion :</B>
	   <Input Type="radio" Name="alteration_type" Value="deletion"></TD>
        <TD><Input Type="Text" Name="deletion" Size="50"></TD>
	<TD>(Please enter deleted sequence) <!--=&gt; Deletion tag (Description)--></TD></TR>

    <TR></TR> <TR></TR> <TR></TR> <TR></TR>
    <TR></TR> <TR></TR> <TR></TR> <TR></TR>
    <TR><TD align="right"><B>As many as possible up to 30 bp upstream flanking sequence :</B></TD>
        <TD><Input Type="Text" Name="upstream" Size="50"></TD>
        <TD> <!--=&gt; Flanking_sequences UNIQUE tag Text (left)--></TD></TR>
    <TR><TD align="right"><B>As many as possible up to 30 bp downstream flanking sequence :</B></TD>
        <TD><Input Type="Text" Name="downstream" Size="50"></TD>
        <TD> <!--=&gt; Flanking_sequences UNIQUE tag Text (right)--></TD></TR>

    <TR></TR> <TR></TR> <TR></TR> <TR></TR>
    <TR></TR> <TR></TR> <TR></TR> <TR></TR>
    <TR></TR> <TR></TR> <TR></TR> <TR></TR>
    <TR></TR> <TR></TR> <TR></TR> <TR></TR>
    <TR><TD><FONT SIZE=+2><B>PERSONAL</B></FONT></TD></TR>

    <TR></TR><TR><TD ALIGN="right"><B>Comment :</B></TD>
        <TD><TEXTAREA Name="comment" Rows=3 Cols=50></TEXTAREA></TD>
        <TD><!--=&gt; for curator's info--></TD></TR><TR></TR>

    <TR></TR> <TR></TR> <TR></TR> <TR></TR>
    <TR></TR> <TR></TR> <TR></TR> <TR></TR>
    
    <TR><TD COLSPAN=2> </TD></TR>
    <TR>
      <TD> </TD>
      <TD><INPUT TYPE="submit" NAME="action" VALUE="Submit">
        <INPUT TYPE="reset"></TD>
    </TR>
  </TABLE>

</FORM>
If you have any problems, questions, or comments, please contact <A HREF=\"mailto:cgc\@wormbase.org\">cgc\@wormbase.org</A>
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
    my $result = $conn->exec ( "select * from two_standardname;" );
    while (my @row = $result->fetchrow ) {
      $standard_name{$row[0]} = $row[2];
    } # while (my @row = $result->fetchrow )

#     print "<tr><td colspan=2 align=center>name <font color=red>$name</font> could be : </td></tr>\n";
    $keith_body .= "name $name could be : \n";
    my @stuff = sort {$a <=> $b} keys %{ $aka_hash{$search_name} };
    foreach $_ (@stuff) { 		# add url link
      my $joinkey = 'two'.$_;
      my $person = 'wbperson'.$_;
      $keith_body .= "\t$standard_name{$joinkey} $person\n";
#       print "<tr><td>$standard_name{$joinkey}</td><td><a href=http://www.wormbase.org/db/misc/etree?name=${person};class=person>$person</a></td></tr>\n";
    }

  }
  unless ($keith_body) { 
    $keith_body .= $name . " has no match, look here for possible matches : \n";
    $name =~ s/\s+/+/g;
    $keith_body .= 'http://minerva.caltech.edu/~azurebrd/cgi-bin/forms/person_name.cgi?action=Submit&name=' . "$name\n"; }
#   print "</TABLE>\n";
} # sub processAkaSearch

sub getPgHash {				# get akaHash from postgres instead of flatfile
  my $result;
  my %filter;
  my %aka_hash;
  
  my @tables = qw (first middle last);
  foreach my $table (@tables) { 
    $result = $conn->exec ( "SELECT * FROM two_aka_${table}name WHERE two_aka_${table}name IS NOT NULL AND two_aka_${table}name != 'NULL' AND two_aka_${table}name != '';" );
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
    $result = $conn->exec ( "SELECT * FROM two_${table}name WHERE two_${table}name IS NOT NULL AND two_${table}name != 'NULL' AND two_${table}name != '';" );
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
#       my $result = $conn->exec ( "select * from two_aka_${table}name where lower(two_aka_${table}name) ~ lower('$input_part');" );
#       while ( my @row = $result->fetchrow ) { $filter{$row[0]}{$input_part}++; }
#       $result = $conn->exec ( "select * from two_${table}name where lower(two_${table}name) ~ lower('$input_part');" );
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
