#!/usr/bin/perl -w

# First Pass by users.

# For Andrei  2008 05 08

 
use strict;
use CGI;
use Fcntl;
use Pg;
use Jex;


my $query = new CGI;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $HTML_TEMPLATE_ROOT = "/home/postgres/public_html/cgi-bin/";

my $blue = '#00ffcc';			# redefine blue to a mom-friendly color
my $red = '#ff00cc';			# redefine red to a mom-friendly color

my $frontpage = 1;			# show the front page on first load

my ($header, $footer) = &cshlNew('Paper First Pass User Submission');
$header =~ s/^.*<html>/Content-type: text\/html\n\n<html>/s;


my %desc;				# description of field
my %expl;				# explanation of field

my @geneidfxn = qw( genesymbol genefxn mutant rnai lsrnai );
my @interactions = qw( geneticintxn geneproductintxn );
my @geneexpfxn = qw( exprdata transgene cisgene overexpression mosaic siteaction microarray );
my @protfxnstruc = qw( protanalysis covalent structinfo );
my @seqdata = qw( genestructcorr seqchange seqfeatures massspec );
my @celldata = qw( ablationdata cellfxn );
my @insilico = qw(phylogenetic othersilico );
my @reagents = qw( chemicals transgene antibodies newsnps geneproducts );
my @other = qw( species humandiseases supplemental );


print $header;
print "<FORM METHOD=\"POST\" ACTION=\"http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/user_firstpass.cgi\">\n";
&display();
print "</FORM>\n";
print $footer;

sub display {
  my $action;
  unless ($action = $query->param('action')) {
    $action = 'none';
    if ($frontpage) { &firstPage(); }
  } else { $frontpage = 0; }

  if ($action eq 'Flag !') { &secondPage(); }
  if ($action eq 'Submit !') { &thirdPage(); }
} # sub display

sub getTitle {
  my $joinkey = shift; my $title;
  my $result = $conn->exec( "SELECT * FROM wpa_title WHERE joinkey = '$joinkey' ORDER BY wpa_timestamp;" );
  while (my @row = $result->fetchrow) { if ($row[3] eq 'valid') { $title = $row[1]; } else { $title = 'No Title'; } }
  return $title;
} # sub getTitle

sub firstPage {
  &initializeDesc();
  my $paperId = '00000003';
  my $title = &getTitle($paperId);
  print "(Hardwired) WBPaper$paperId : $title<P>\n";
  print "<INPUT TYPE=HIDDEN NAME=paperid VALUE=$paperId>\n";
  print "<INPUT TYPE=HIDDEN NAME=title VALUE=\"$title\">\n";
#   print "User First-Pass Form Field List.  Check on the ones in your paper, then click the ``Flag !'' button below :<P>\n";
  print "<TABLE>\n";
  print "<TR><TD>&nbsp;</TD></TR><TR><TD COLSPAN=2><FONT SIZE=+2>$desc{geneidfxn}</FONT></TD></TR>\n";
  foreach my $field (@geneidfxn) { &showCheckbox($field); }
  print "<TR><TD>&nbsp;</TD></TR><TR><TD COLSPAN=2><FONT SIZE=+2>$desc{interactions}</FONT></TD></TR>\n";
  foreach my $field (@interactions) { &showCheckbox($field); }
  print "<TR><TD>&nbsp;</TD></TR><TR><TD COLSPAN=2><FONT SIZE=+2>$desc{geneexpfxn}</FONT></TD></TR>\n";
  foreach my $field (@geneexpfxn) { &showCheckbox($field); }
  print "<TR><TD>&nbsp;</TD></TR><TR><TD COLSPAN=2><FONT SIZE=+2>$desc{protfxnstruc}</FONT></TD></TR>\n";
  foreach my $field (@protfxnstruc) { &showCheckbox($field); }
  print "<TR><TD>&nbsp;</TD></TR><TR><TD COLSPAN=2><FONT SIZE=+2>$desc{seqdata}</FONT></TD></TR>\n";
  foreach my $field (@seqdata) { &showCheckbox($field); }
  print "<TR><TD>&nbsp;</TD></TR><TR><TD COLSPAN=2><FONT SIZE=+2>$desc{celldata}</FONT></TD></TR>\n";
  foreach my $field (@celldata) { &showCheckbox($field); }
  print "<TR><TD>&nbsp;</TD></TR><TR><TD COLSPAN=2><FONT SIZE=+2>$desc{insilico}</FONT></TD></TR>\n";
  foreach my $field (@insilico) { &showCheckbox($field); }
  print "<TR><TD>&nbsp;</TD></TR><TR><TD COLSPAN=2><FONT SIZE=+2>$desc{reagents}</FONT></TD></TR>\n";
  foreach my $field (@reagents) { &showCheckbox($field); }
  print "<TR><TD>&nbsp;</TD></TR><TR><TD COLSPAN=2><FONT SIZE=+2>$desc{other}</FONT></TD></TR>\n";
  foreach my $field (@other) { &showCheckbox($field); }
  print "<TR><TD>&nbsp;</TD></TR><TR><TD><INPUT TYPE=submit NAME=action VALUE=\"Flag !\"></TD></TR>\n";
  print "</TABLE>\n";
} # sub firstPage

sub showCheckbox {
  my ($field) = @_;
  print "<TR><TD><INPUT NAME=\"${field}_checked\" TYPE=CHECKBOX VALUE=\"checked\">$desc{$field}</TD>\n";
} # sub showCheckbox

sub secondPage {
  &initializeDesc();
  my ($oop, $paperId) = &getHtmlVar($query, "paperid");
  ($oop, my $title) = &getHtmlVar($query, "title");
  print "<INPUT TYPE=HIDDEN NAME=paperid VALUE=$paperId>\n";
  print "<INPUT TYPE=HIDDEN NAME=title VALUE=\"$title\">\n";
  print "(Hardwired) WBPaper$paperId : $title<P>\n";
  my $body = "(Hardwired) WBPaper$paperId : $title\n\n";
  print "<B>Optional</B> Next Level (fill details if desired)<P>\n";
  print "<TABLE>\n";
  foreach my $field ( @geneidfxn, @interactions, @geneexpfxn, @protfxnstruc, @seqdata, @celldata, @insilico, @reagents, @other ) {
    my ($oop, $checked) = &getHtmlVar($query, "${field}_checked");
    if ($checked) { &showText($field); $body .= "$field : $desc{$field}\n"; }
  } # foreach my $field ( @geneidfxn, @interactions, @geneexpfxn, @protfxnstruc, @seqdata, @celldata, @insilico, @reagents, @other )
  &showText("comments");
  print "<TR><TD>&nbsp;</TD></TR><TR><TD><INPUT TYPE=submit NAME=action VALUE=\"Submit !\"></TD></TR>\n";
  print "</TABLE>\n";

  my $user = 'user_firstpass.cgi';
  my $email = 'petcherski@gmail.com';
#   my $email = 'mailfilter@tazendra.caltech.edu';
  my $subject = "WBPaper$paperId flag data";
  &mailer($user, $email, $subject, $body);	# email comments to cecilia
} # sub secondPage

sub thirdPage {
  &initializeDesc();
  my ($oop, $paperId) = &getHtmlVar($query, "paperid");
  ($oop, my $title) = &getHtmlVar($query, "title");
  print "<INPUT TYPE=HIDDEN NAME=paperid VALUE=$paperId>\n";
  print "<INPUT TYPE=HIDDEN NAME=title VALUE=\"$title\">\n";
  print "Thanks for submitting data for (Hardwired) WBPaper$paperId : $title<P>\n";
  my $body = "(Hardwired) WBPaper$paperId : $title\n\n";
  push @other, "comments";
  foreach my $field ( @geneidfxn, @interactions, @geneexpfxn, @protfxnstruc, @seqdata, @celldata, @insilico, @reagents, @other ) {
    my ($oop, $text) = &getHtmlVar($query, "${field}_text");
    if ($text) { $body .= "$field : $text\n\n"; }
  } # foreach my $field ( @geneidfxn, @interactions, @geneexpfxn, @protfxnstruc, @seqdata, @celldata, @insilico, @reagents, @other )
  my $user = 'user_firstpass.cgi';
  my $email = 'petcherski@gmail.com';
#   my $email = 'mailfilter@tazendra.caltech.edu';
  my $subject = "WBPaper$paperId flag data";
  &mailer($user, $email, $subject, $body);	# email comments to cecilia
} # sub thirdPage

sub showText {
  my ($field) = @_;
  unless ($expl{$field}) { $expl{$field} = 'point where an example of this data type is in the paper ()e.g. fig.4, p.17, "in methods", etc.) or write a couple word summary of the data.'; }
  print "<TR><TD>$desc{$field}<BR>$expl{$field}<BR><TEXTAREA ROWS=4 COLS=120 NAME=\"${field}_text\"></TEXTAREA><BR></TD></TR>\n";
  print "<TR><TD>&nbsp;</TD></TR>\n";
} # sub showText

sub initializeDesc {
  $desc{geneidfxn} = 'Gene Identity or Gene Function';
  $desc{genesymbol} = 'Novel Gene Symbol or Gene-CDS link (e.g. xyz-1 gene was cloned and it turned out to be the same as abc-1 gene)';
  $expl{genesymbol} = 'write the gene and or CDS name(s) here :';
  $desc{genefxn} = 'Gene Function (novel function for a gene (not reported in Wormbase under Concise Description on the Gene page)';
  $desc{mutant} = 'Mutant Phenotype (mutant phenotypes are observed or measured)';
  $desc{rnai} = 'RNAi (small scale, less than 100 individual experiments)';
  $desc{lsrnai} = 'RNAi (large scale >100 individual experiments)';
  
  $desc{interactions} = 'Interactions';
  $desc{geneticintxn} = 'Genetic interactions (e.g. daf-16(mu86) suppresses daf-2(e1370), daf-16(RNAi) suppresses daf-2(RNAi))';
  $desc{geneproductintxn} = 'Gene Product Interaction (protein-protein, RNA-protein, DNA-protein interactions, etc.)';
  
  $desc{geneexpfxn} = 'Gene Expression and Function:';
  $desc{exprdata} = 'Expression Pattern Data (such as GFP reporter assay or immunostaining.  exclude data for the reporters used exclusively as markers) ';
  $desc{transgene} = 'Trans-Gene Regulation on Expression Level (e.g. geneA-gfp reporter is mis-expressed in geneB mutant background)';
  $desc{cisgene} = 'Cis-Gene Regulation (transcription factor binding sites, PWM, etc.)';
  $desc{overexpression} = 'Overexpression (over-expression of a gene that results in a phenotypic change, genetic intractions, etc.)';
  $desc{mosaic} = 'Mosaic Analysis (e.g. extra-chromosomal transgene loss in a particular cell lineage abolishes mutant rescue)';
  $desc{siteaction} = 'Site of Action (e.g. tissue/cell specific expression rescues mutant phenotype; RNAi in rrf-1 background determines that the gene acts in the germ line)';
  $desc{microarray} = 'Microarray';
  
  $desc{protfxnstruc} = 'Protein Function and Structure';
  $desc{protanalysis} = 'Protein Analysis In Vitro (e.g. kinase assay)';
  $desc{covalent} = 'Covalent Modification (e.g. phosphorylation site is studies via mutagenesis and in vitro assay)';
  $desc{structinfo} = 'Structure Information (e.g. NMR structure, functional domain info for a protein (e.g. removal of the first 50aa causes mislocalization of the protein))';
  
  $desc{seqdata} = 'Sequence Data';
  $desc{genestructcorr} = 'Gene Structure Correction (Gene Structure is different from the one in Wormbase: e.g. different splice-site, SL1 instead of SL2, etc.) ';
  $desc{seqchange} = 'Sequence Change (mutation were sequenced in the paper)';
  $desc{seqfeatures} = 'Sequence Features (DNA/RNA elements required for gene expression, )';
  $desc{massspec} = 'Mass Spectrometry';
  
  $desc{celldata} = 'Cell Data';
  $desc{ablationdata} = 'Ablation Data (cells were ablated using a laser or by other means (e.g.  by expressing a cell-toxic protein))';
  $desc{cellfxn} = 'Cell Function (the paper describes new function for a cell)';
  
  $desc{insilico} = 'In Silico Data';
  $desc{phylogenetic} = 'Phylogenetic Analysis';
  $desc{othersilico} = 'Other Silico Data';
  
  $desc{reagents} = 'Reagents';
  $desc{chemicals} = 'Chemicals (typically a small-molecule chemical was used: butanol, prozac, etc.)';
  $desc{transgene} = 'Transgene (integrated or extra-chromosomal)';
  $desc{antibodies} = 'C.elegans Antibodies (Abs were created in the paper, or Abs used were created before elsewhere)';
  $desc{newsnps} = 'New SNPs (SNPs that are not in Wormbase)';
  $desc{geneproducts} = 'Gene or gene products were studied in the paper (excluding common markers and reporters)';
  $expl{geneproducts} = 'List Gene names for gene or gene products studied in the paper (exclude common markers and reporters)';

  $desc{other} = 'Other';
  $desc{species} = 'Nematode species (there is info about non-C.elegans nematodes)';
  $desc{humandiseases} = 'Human Diseases (relevant to human diseases, e.g. the gene studied is a ortholog of a human disease gene) :';
  $desc{supplemental} = 'Check if the paper is accompnied by the supplemental materials';

  $desc{comments} = 'Comments on this Form';
  $expl{comments} = 'Write your suggestions/comments about this form here :';
} # sub initializeDesc

__END__


sub connect {
  my ($two, $aid, $wpa_join, $curator, $yes_no);
  if ($query->param('two_number')) { $two = $query->param('two_number'); } 
  if ($query->param('aid')) { $aid = $query->param('aid'); } 
  if ($query->param('wpa_join')) { $wpa_join = $query->param('wpa_join'); } 
  if ($query->param('yes_no')) { $yes_no = $query->param('yes_no'); } 
  if ($two) { 
    my $result = $conn->exec( "SELECT two_standardname FROM two_standardname WHERE joinkey = 'two$two';" );
    my @row = $result->fetchrow;
    if ($row[0]) { $curator = $row[0]; } }
  my $error = 0;
  unless ($two) { print "ERROR, no WBPerson number : $aid, $wpa_join<BR>\n"; $error++; }
  unless ($aid) { print "ERROR, no AuthorID number : $two, $wpa_join<BR>\n"; $error++; }
  unless ($wpa_join) { print "ERROR, no wpa_join number : $two, $aid<BR>\n"; $error++; }
  unless ($curator) { print "ERROR, no Curator Standardname : $two, $aid, $wpa_join<BR>\n"; $error++; }
  unless ($yes_no) { print "ERROR, no selection for Yours or Not Yours : $two, $aid, $wpa_join<BR>\n"; $error++; }
  if ($error) { die "Improper selections on single connection\n"; }

  if ($curator =~ m/\"/) { $curator =~ s/\"/\\\"/g; }			# escape double quotes for postgres and html display
  if ($curator =~ m/\'/) { $curator =~ s/\'/''/g; }			# escape single quotes for postgres and html display
  my $command = "INSERT INTO wpa_author_verified VALUES ($aid, '$yes_no $curator', $wpa_join, 'valid', 'two$two', CURRENT_TIMESTAMP);";
  &mailConfirmation($two);
  my $result = $conn->exec( $command );		# uncomment this for sub to work
  print "<!--$command<BR>-->\n";
  print "Thank you for connecting this paper as $yes_no<BR>\n";
# http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/confirm_paper.cgi?action=Connect&two_number=1823&aid=18165&wpa_join=1&yes_no=YES
} # sub connect

sub papComment {				# authors that want to leave comments
  my ($oop2, $curator) = &getHtmlVar($query, 'curator_name');
  $curator =~ s/^\s+//g;
  $curator =~ s/\s+$//g;
  print "Curator : $curator<P>\n";

  my $oop;
  if ($query->param('two')) { $oop = $query->param('two'); } 
    else { $oop = 'nodatahere'; }
  my $two = untaint($oop);
  print "WBPerson : $two<P>\n";

  if ($query->param('comment')) { $oop = $query->param('comment'); } 
    else { $oop = 'nodatahere'; }
  my $comment = untaint($oop);
  print "Comment : $comment<P>\n";
  $comment =~ s/\"/\\\"/g;			# escape double quotes for postgres and html display
  $comment =~ s/\'/''/g;			# escape single quotes for postgres and html display

#   print "<FONT COLOR='blue'>INSERT INTO two_comment VALUES ('two$two', '$curator : $comment');</FONT><BR>\n";
  print "<B>Thank you for your comments, these are being stored and emailed to cecilia\@tazendra.caltech.edu</B><BR>\n";
  my $result = $conn->exec( "INSERT INTO two_comment VALUES ('two$two', '$curator : $comment');" );

  my $user = $curator;
  $user =~ s/\s+/_/g;				# get rid of spaces for email address
  my $email = 'cecilia@tazendra.caltech.edu';
  my $subject = "$two $curator comment for paper connections";
  my $body = $comment;
  &mailer($user, $email, $subject, $body);	# email comments to cecilia
} # sub papComment

sub papEdit {
  my $check_or_yours_or_not = shift;
  my ($oop2, $curator) = &getHtmlVar($query, 'curator_name');
  print "Curator : $curator<P>\n";
  $curator =~ s/\"/\\\"/g;			# escape double quotes for postgres and html display
  $curator =~ s/\'/''/g;			# escape single quotes for postgres and html display
  my ($oop, $i_am_cecilia);
  if ($query->param('i_am_cecilia')) { ($oop, $i_am_cecilia) = &getHtmlVar($query, 'i_am_cecilia'); }

  if ($query->param('two_number')) { $oop = $query->param('two_number'); } 
    else { $oop = 'nodatahere'; }
  my $two_number = untaint($oop);
  print "WBPerson : $two_number<BR>\n";
  print "<B>Thank you for verifying these paper connections.  <P>Please <A href=\"http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/confirm_paper.cgi?two_num=two$two_number&action=Pick+%21\"><FONT SIZE =+2>click here</FONT></A> to select another batch if there is another still unselected.  <P>Please leave a comment if something is incorrect or unclear.<BR>Your record has been updated and changes will show in a WormBase release soon.</B><P>\n";
  if ($query->param('count')) { $oop = $query->param('count'); } 
    else { $oop = 'nodatahere'; }
  my $count = untaint($oop);
#   print "COUNT : $count<BR>\n";
  for (my $i = 1; $i <= $count; $i++) {
    my $join = ''; my $aid = ''; my $wpa = '';
    if ($query->param("val_join$i")) { $oop = $query->param("val_join$i"); } 
      else { $oop = 'nodatahere'; }		# wpa_join
    $join = untaint($oop);
    if ($query->param("val_wpa$i")) { $oop = $query->param("val_wpa$i"); } 
      else { $oop = 'nodatahere'; }		# paper joinkey
    $wpa = untaint($oop);
    if ($query->param("val_aid$i")) { $oop = $query->param("val_aid$i"); } 
      else { $oop = 'nodatahere'; }		# author_id
    $aid = untaint($oop);
    my $yours_or_not = 'yours';			# default all is theirs
    if ($check_or_yours_or_not eq 'check') {
      if ($query->param("yours_or_not$i")) { $oop = $query->param("yours_or_not$i"); } 
        else { $oop = 'nodatahere'; }
      $yours_or_not = untaint($oop); }
    elsif ($check_or_yours_or_not eq 'yours') { $yours_or_not = 'yours'; }
    elsif ($check_or_yours_or_not eq 'notyours') { $yours_or_not = 'not'; }
    else { print "<FONT COLOR=red>ERROR not a valid choice in subroutine papEdit : $check_or_yours_or_not</FONT><BR>.\n"; }
#     print "JOIN $join AID $aid YN $yours_or_not<BR>\n";
    if ($yours_or_not) {			# should always be
      my $wpa_verified = ''; my $not = '';	# verified value and html message
      if ($yours_or_not eq 'yours') { $wpa_verified = 'YES ' . $curator; }
      elsif ($yours_or_not eq 'not') { $wpa_verified = 'NO ' . $curator; $not = 'not '; }
      else { next; }				# skip if neither yes nor no
      my $pgcommand = "INSERT INTO wpa_author_verified VALUES ('$aid', '$wpa_verified', '$join', 'valid', 'two$two_number', CURRENT_TIMESTAMP);";
      if ($i_am_cecilia) { 
        if ($yours_or_not eq 'yours') { $pgcommand = "INSERT INTO wpa_author_verified VALUES ('$aid', 'YES  Cecilia Nakamura', '$join', 'valid', 'two1', CURRENT_TIMESTAMP);"; } 
        elsif ($yours_or_not eq 'not') { $pgcommand = "INSERT INTO wpa_author_verified VALUES ('$aid', 'NO  Cecilia Nakamura', '$join', 'valid', 'two1', CURRENT_TIMESTAMP);"; } }
      my $result = $conn->exec( $pgcommand );
      print "$pgcommand<BR>\n";
      print "Your publication record has been updated to show $wpa as ${not}yours.<BR>\n";
    } # if ($yours_or_not)
 
#     $pap_author =~ s/\"/\\\"/g;			# escape double quotes for postgres and html display
#     $pap_author =~ s/\'/''/g;			# escape single quotes for postgres and html display
# #     print "<BR>JOIN $joinkey : AUTH $pap_author<BR>\n";
#   
#     if ($yours_or_not eq 'yours') { 		# for yours, change the verified field
# #       print "<FONT COLOR='blue'>UPDATE pap_verified SET pap_timestamp = CURRENT_TIMESTAMP WHERE joinkey = \'$joinkey\' AND pap_author = \'$pap_author\';</FONT><BR>\n";
#       my $result = $conn->exec( "UPDATE pap_verified SET pap_timestamp = CURRENT_TIMESTAMP WHERE joinkey = \'$joinkey\' AND pap_author = \'$pap_author\'" );
# #       print "<FONT COLOR='blue'>UPDATE pap_verified SET pap_verified = \'YES $curator\' WHERE joinkey = \'$joinkey\' AND pap_author = \'$pap_author\';</FONT><BR><BR>\n";
#       $result = $conn->exec( "UPDATE pap_verified SET pap_verified = \'YES $curator\' WHERE joinkey = \'$joinkey\' AND pap_author = \'$pap_author\'" );
#       print "Your publication record has been updated to show $joinkey as yours.<BR>\n";
#     } elsif ($yours_or_not eq 'not') { 		# for not yours, change the verified field
# #       print "<FONT COLOR='blue'>UPDATE pap_verified SET pap_timestamp = CURRENT_TIMESTAMP WHERE joinkey = \'$joinkey\' AND pap_author = \'$pap_author\';</FONT><BR>\n";
#       my $result = $conn->exec( "UPDATE pap_verified SET pap_timestamp = CURRENT_TIMESTAMP WHERE joinkey = \'$joinkey\' AND pap_author = \'$pap_author\'" );
# #       print "<FONT COLOR='blue'>UPDATE pap_verified SET pap_verified = \'NO $curator\' WHERE joinkey = \'$joinkey\' AND pap_author = \'$pap_author\';</FONT><BR><BR>\n";
#       $result = $conn->exec( "UPDATE pap_verified SET pap_verified = \'NO $curator\' WHERE joinkey = \'$joinkey\' AND pap_author = \'$pap_author\'" );
#       print "Your publication record has been updated to show $joinkey as not yours.<BR>\n";
#     } else { 1; } # print "<FONT COLOR=red>WARNING, not a valid option $yours_or_not</FONT>.<BR>";
  } # for (my $i = 1; $i <= $count; $i++)
  unless ($i_am_cecilia) { &mailConfirmation($two_number); }		# don't send email if Cecilia does the connection  2007 05 29
} # sub papEdit


## papSelect block ##

sub papSelect {
  my ($oop2, $curator) = &getHtmlVar($query, 'curator_name');
  print "Curator : $curator<P>\n";

  my ($oop3, $check_all) = &getHtmlVar($query, 'all_check');
  if ($check_all) { print "Check All : $check_all<P>\n"; }
    else { $check_all = 'neither'; }

  my $result = $conn->exec( "SELECT * FROM wpa_type_index ORDER BY wpa_timestamp; ");
  while (my @row = $result->fetchrow) {
    if ($row[3] eq "valid") { $type_index{$row[0]} = $row[1]; }		# type_id, wpa_type_index
      else { delete $type_index{$row[0]}; } }				# delete invalid

  my $oop;
  if ($query->param('two')) { $oop = $query->param('two'); } 
    else { $oop = 'nodatahere'; }
  my $two = untaint($oop);
  if ($query->param('paper_range')) { $oop = $query->param('paper_range'); } 
    else { $oop = 'nodatahere'; }
  my $paper_range = untaint($oop); 

  &displayOneDataFromKey($two);

#   &displaySelectAllCheck($two, $curator, $paper_range);

  &displayEditor($two, $paper_range, $curator, $check_all);

} # sub papSelect

# sub displaySelectAllCheck {
#   my ($two, $curator_name, $paper_range) = @_;
#   print "<TABLE>\n";
#   print "<FORM METHOD=\"POST\" ACTION=\"http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/confirm_paper.cgi\">\n";
#   print "<INPUT TYPE=HIDDEN NAME=curator_name VALUE=\"$curator_name\">\n";
#   print "<INPUT TYPE=\"HIDDEN\" NAME=\"two\" VALUE=\"$two\">\n";
#   print "<INPUT TYPE=\"HIDDEN\" NAME=\"paper_range\" VALUE=\"$paper_range\">\n";
#   print "<INPUT TYPE=\"HIDDEN\" NAME=\"all_check\" VALUE=\"yes\">\n";
#   print "<TR><TD>Check all as Yours : </TD><TD><INPUT TYPE=submit NAME=action VALUE=\"Select !\"></TD>\n";
#   print "</FORM>\n";
#   print "<FORM METHOD=\"POST\" ACTION=\"http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/confirm_paper.cgi\">\n";
#   print "<INPUT TYPE=HIDDEN NAME=curator_name VALUE=\"$curator_name\">\n";
#   print "<INPUT TYPE=\"HIDDEN\" NAME=\"two\" VALUE=\"$two\">\n";
#   print "<INPUT TYPE=\"HIDDEN\" NAME=\"paper_range\" VALUE=\"$paper_range\">\n";
#   print "<INPUT TYPE=\"HIDDEN\" NAME=\"all_check\" VALUE=\"no\">\n";
#   print "<TD>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</TD>\n";
#   print "<TD>Check all as <B>Not</B> Yours : </TD><TD><INPUT TYPE=submit NAME=action VALUE=\"Select !\"></TD></TR>\n";
#   print "</FORM>\n";
#   print "</TABLE>\n";
# } # sub displaySelectAllCheck


sub displayEditor {
  my ($two_key, $paper_range, $curator, $check_all) = @_;
  print "<TABLE>\n";
  print "<FORM METHOD=\"POST\" ACTION=\"http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/confirm_paper.cgi\">\n";
  print "<TR><TD><FONT COLOR=green>Update all publications from this batch as Yours : </FONT></TD><TD><INPUT TYPE=submit NAME=action VALUE=\"Update Yours !\"></TD>\n";
  print "<TD>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</TD>\n";
  print "<TD><FONT COLOR=red>Update all publications from this batch as <B>Not</B> Yours : </FONT></TD><TD><INPUT TYPE=submit NAME=action VALUE=\"Update NOT Yours !\"></TD></TR>\n";
  print "</TABLE>\n";
  print "<P><B>From each table of Papers below, please check the radio button corresponding to whether a paper is Yours or Not Yours.<BR>When finished choosing for all papers, click the <FONT COLOR=blue SIZE=+2>``Edit !''</FONT> button  :<BR>(If a checkbox says YES or NO with a name next to it, it is because someone with that name has already chosen YES or NO for it.  Reselecting the checkbox and clicking the ``Edit !'' button will override the previous value with your name.)<BR>(Note : Author names may not be in order, they will be when you see them in WormBase.)</B><P>\n";
  if ($query->param('i_am_cecilia')) {			# if is cecilia
    my ($oop, $i_am_cecilia) = &getHtmlVar($query, 'i_am_cecilia'); 
    if ($i_am_cecilia) { print "<INPUT TYPE=HIDDEN NAME=i_am_cecilia VALUE=\"YES\">\n"; } }
  print "<INPUT TYPE=HIDDEN NAME=curator_name VALUE=\"$curator\">\n";
  print "<INPUT TYPE=\"HIDDEN\" NAME=\"two_number\" VALUE=\"$two_key\">\n";
  print "<INPUT TYPE=submit NAME=action VALUE=\"Edit !\"><BR><BR>\n";
  my @papers = split /\t/, $paper_range;
  my $count = 0;
  foreach my $author_key (@papers) { $count = &displayPaperDataFromKey($author_key, $count, $two_key, $check_all); }
    # display tables with paper data and checkboxes (for each author) for each of the papers
#   print "TOTAL authors : $count<BR>\n";
  print "<INPUT TYPE=\"HIDDEN\" NAME=\"count\" VALUE=\"$count\">\n";
  print "<INPUT TYPE=submit NAME=action VALUE=\"Edit !\"><BR><BR>\n";
  print "</FORM>\n";
} # sub displayEditor

## papSelect block ##

## papPick block ##

sub papPick {				# display matching papers in groups of 10
  my %names; my %two;
  my $result = $conn->exec( "SELECT * FROM two_fullname ORDER BY two_lastname, two_firstname, two_middlename;" );
  while (my @row = $result->fetchrow) {
    my $lastname = ''; my $firstname = ''; my $middlename = '';
    if ($row[1]) { $lastname = $row[1]; }
    if ($row[2]) { $firstname = $row[2]; }
    if ($row[3]) { $middlename = $row[3]; }
    my $full_name = $lastname . ", " . $firstname . " " . $middlename;
    $full_name =~ s/^\s+//g;
    $full_name =~ s/\s+$//g;
    $names{$full_name} = $row[0];
    $two{$row[0]} = $full_name;
  } # while (my @row = $result->fetchrow)
  $result = $conn->exec( "SELECT * FROM two_standardname;" );
  while (my @row = $result->fetchrow) {
    $names{$row[2]} = $row[0];
    $two{$row[0]} = $row[2];
  } # while (my @row = $result->fetchrow)

  my $two = ''; my $curator = ''; my $oop = '';
  if ($query->param('two_num')) {	# if picked a number, get data
    ($oop, $two) = &getHtmlVar($query, 'two_num'); 
    $two =~ s/two//g;
    my $two_temp = 'two' . $two;
    $curator = $two{$two_temp};
  } else { 				# if not, if picked a name, get data
    ($oop, $curator) = &getHtmlVar($query, 'curator_name');
    my $two_name = $names{$curator};

    $two_name =~ s/two//g;
    $two = $two_name;
  } # else # if ($two_name)

  print "WBPerson : $two<P>\n";		# display two number

  if ($curator =~ m/,/) {
    my ($last, $rest) = split/,/, $curator;
    $curator = $rest . " " . $last; }
  print "Curator : $curator<P>\n";	# display full name

  &displayOneDataFromKey($two);

  print "</TABLE>\n";

  &displaySelector($two, $curator);
} # sub papPick

sub displaySelector {
  my ($two_key, $curator) = @_;
  my @lastnames;			# all lastnames from two tables
  my %lastnames;			# hash to filter multiple lastnames
  my @two_tables_last = qw( two_lastname two_aka_lastname two_apu_lastname );
  foreach my $two_table_last (@two_tables_last) { 
    my $result = $conn->exec( "SELECT $two_table_last FROM $two_table_last WHERE joinkey = 'two$two_key';" );
    while (my @row = $result->fetchrow) {
      push @lastnames, $row[0];
    } # while (my @row = $result->fetchrow)
  }
  foreach $_ (@lastnames) { $_ =~ s/^\s+//g; $_ =~ s/\s+$//g; $lastnames{$_}++; }
#   print "<FONT COLOR=red SIZE=14>WARNING : This form is being updated.  Please don't use and instead contact cecilia\@tazendra.caltech.edu instead.</FONT><P>\n";
  &findPapList($two_key, $curator);				# no longer need lastname since using two
#   foreach my $lastname (sort keys %lastnames) { 
#     print "two$two_key finds : $lastname<BR><BR>\n"; 
#     &findPapList($lastname, $two_key, $curator);
#   }
} # sub displaySelector

sub findPapList {
  my $action; my $show_all = 0;
  $action = $query->param('action');
  if ($action eq 'Pick !') { $show_all = 0; }
    else { $show_all = 1; }

#   my ($lastname, $two_key, $curator) = @_;
  my ($two_key, $curator) = @_;
  my $papercount = 0;			# count of papers
  my @papers;				# list of papers
  my %filter_papers;			# hash to filter papers
  my %join_hash;                	# the aids and joins of the twos that match
  my %author_paper;			# mapping of aids to paperids
  my %invalid_papers;
  my $i_am_cecilia = '';		# is not cecilia by default


  if ($query->param('i_am_cecilia')) {	# if picked a number, get data
    (my $oop, $i_am_cecilia) = &getHtmlVar($query, 'i_am_cecilia'); 
    if ($i_am_cecilia) { $show_all = 1; } }

  if ($show_all) {			# show different menus depending on whether showing all paper or only unverified  2006 02 22
      print "<P><B>From each batch of papers below, please click the corresponding <FONT COLOR=green SIZE=+2>``Select !''</FONT> button, and follow the directions there.<BR>Afterwards, come back to this page if there is another batch of papers you have not selected :</B><BR>1) Publications and Abstracts (not confirmed by author in black)<BR>2) Publications and Abstracts (author confirmed in <FONT COLOR=red>red</FONT> and <FONT COLOR=blue>blue</FONT>)<BR>3) Papers are grouped in batches of 10 or less. When a batch is verified, these papers will go to the bottom grouped as blue or red accordingly. For your convenience the next unverified batch will show always on top in black as batch 'papers: 1 to 10'.<BR>4) If you have already confirmed some publications (in red and bue), there is no need to confirm them again unless you'd like to review them.<P>\n"; }
    else { 				# default menu and link to show all papers
      print "<FORM METHOD=\"POST\" ACTION=\"http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/confirm_paper.cgi\"><INPUT TYPE=HIDDEN NAME=curator_name VALUE=\"$curator\"><INPUT TYPE=HIDDEN NAME=two_num VALUE=\"$two_key\">\n";
      print "<P><B>From each batch of papers below, please click the corresponding <FONT COLOR=green SIZE=+2>``Select !''</FONT> button, and follow the directions there.<BR>Afterwards, come back to this page if there is another batch of papers you have not selected :</B><BR>Papers are grouped in batches of 10 or less.  When a batch is verified, these papers will be obscured from the main list.  Selecting 'Show All!' will show your papers as blue, black or red accordingly.  For your convenience the next unverified batch will show always on top in black as batch 'papers: 1 to 10'.<BR>To see all papers (including verified ones) : <INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Show All !\"></FORM><P>\n"; }

  my $result = $conn->exec( " SELECT * FROM wpa ORDER BY wpa_timestamp; " );
  while (my @row = $result->fetchrow) {
    if ($row[3] ne 'valid') { $invalid_papers{$row[0]}++; }
      else { if ($invalid_papers{$row[0]}) { delete $invalid_papers{$row[0]}; } } }
  $result = $conn->exec( "SELECT * FROM wpa_author WHERE wpa_author IS NOT NULL ORDER BY wpa_timestamp; ");
  while (my @row = $result->fetchrow) {
    if ($row[3] eq "valid") { $author_paper{$row[1]} = $row[0]; }	# aid, wbpaper id
      else { delete $author_paper{$row[1]}; } }				# delete invalid
  $result = $conn->exec( "SELECT * FROM wpa_author_possible WHERE wpa_author_possible = 'two$two_key' ORDER BY wpa_timestamp; ");
  while (my @row = $result->fetchrow) {
    if ($row[3] eq "valid") { $join_hash{$row[0]}{$row[2]}++; }		# aid, wpa_join
      else { delete $join_hash{$row[0]}{$row[2]}; } }			# delete invalid
  foreach my $aid (sort keys %join_hash) {
    foreach my $wpa_join (sort keys %{ $join_hash{$aid} }) {
      my $yes_or_no = '';
      $result = $conn->exec( "SELECT * FROM wpa_author_verified WHERE author_id = '$aid' AND wpa_join = '$wpa_join' ORDER BY wpa_timestamp; ");
      while (my @row = $result->fetchrow) {
      if ($row[3] eq "valid") { 
          unless ($row[1]) { $row[1] = ''; }				# set to blank if no value (to make sure to overwrite with a blank)
          $yes_or_no = $row[1]; }					# store value
        else { $yes_or_no = ''; } }					# delete invalid
      $papercount++;
      if ($yes_or_no) { 
         if ($yes_or_no =~ m/^YES/) { $filter_papers{$aid}{YES}++; }	# if confirmed as YES
         elsif ($yes_or_no =~ m/^NO/) { $filter_papers{$aid}{NO}++; }	# if confirmed as NO
         else { $filter_papers{$aid}{unverified}++ } }			# otherwise still add to filter hash
       else { $filter_papers{$aid}{unverified}++ }			# otherwise still add to filter hash
    } # foreach my $wpa_join (sort keys %{ $join_hash{$aid} })
  } # foreach my $aid (sort keys %join_hash)
  foreach $_ (sort keys %filter_papers) { unless ($author_paper{$_}) { delete $filter_papers{$_}; } }		# exclude invalid authors  2006 07 12
  foreach $_ (sort keys %filter_papers) { if ($invalid_papers{$author_paper{$_}}) { delete $filter_papers{$_}; } }	# exclude invalid papers  2005 10 21
  foreach $_ (sort keys %filter_papers) { if ($filter_papers{$_}{unverified}) { push @papers, $_; } }		# put back in array unverified to sort new ones first 2004 08 17
  foreach $_ (sort keys %filter_papers) { unless ($filter_papers{$_}{unverified}) { push @papers, $_; } }	# put back in array verified 2004 08 17
#   print "There are " . scalar(@papers) . " matching papers for $lastname :<BR>\n";	# No longer need lastname since using two
  my %temp; foreach (@papers) { $temp{$_}++; } @papers = (); foreach (sort {$a<=>$b} keys %temp) { push @papers, $_; }	# sort @papers numerically  2005 10 21
  %temp = ();  foreach (@papers) { 					# color sort into hash of arrays by verification color  2005 11 08
    if ($filter_papers{$_}{YES}) { push @{ $temp{blue} }, $_; }
    elsif ($filter_papers{$_}{NO}) { push @{ $temp{red} }, $_; }
    else { push @{ $temp{black} }, $_; } }
  unless ($show_all) { delete $temp{blue}; delete $temp{red}; @papers = (); foreach (@{ $temp{black} }) { push @papers, $_; } }	# ignore verified stuff by default 2006 02 22
  print "There are " . scalar(@papers) . " matching papers :<BR>\n";
  print "(Unverified are <B>black</B>, Yours are <FONT COLOR = 'blue'>blue</FONT>, Not Yours are <FONT COLOR = 'red'>red</FONT>)<BR><BR>\n";
  print "<TABLE border=1 cellspacing=2>\n";
  foreach my $color (sort keys %temp) { 
    for (my $i = 0; $i < scalar(@{ $temp{$color} }); $i+=10) {
      print "<FORM METHOD=\"POST\" ACTION=\"http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/confirm_paper.cgi\">\n";
      print "<INPUT TYPE=HIDDEN NAME=curator_name VALUE=\"$curator\">\n";
      if ($i_am_cecilia) { print "<INPUT TYPE=HIDDEN NAME=i_am_cecilia VALUE=\"YES\">\n"; }
      print "<INPUT TYPE=\"HIDDEN\" NAME=\"two\" VALUE=\"$two_key\">\n";
      my @papers_in_group;
      print "<TR><TD>papers : " . (1 + $i) . " to " . (10 + $i) . "</TD><TD>";
      for (my $j = $i; ( ($j < $i+10) && ($j < scalar(@{ $temp{$color} })) ); $j++) { 
        print "<FONT COLOR = '$color'>"; 
        print "paper " . ($j + 1) . " : $author_paper{$temp{$color}[$j]}<BR>\n";
        push @papers_in_group, $temp{$color}[$j];
        print "</FONT>";
      } # for (my $j = $i; $j < $i+10; $j++)
      print "</TD><TD><INPUT TYPE=submit NAME=action VALUE=\"Select !\"></TD>\n";
      my $papers_in_group = join "\t", @papers_in_group;
      print "<INPUT TYPE=\"HIDDEN\" NAME=\"paper_range\" VALUE=\"$papers_in_group\">";
      print "</TR>\n";
      print "</FORM>\n";
    } # for (my $i = 0; $i < scalar(@papers); $i+=10)
  } # foreach my $color (sort keys %temp)
#   for (my $i = 0; $i < scalar(@papers); $i+=10) {				# old method without grouping by color sort
#     print "<FORM METHOD=\"POST\" ACTION=\"http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/confirm_paper.cgi\">\n";
#     print "<INPUT TYPE=HIDDEN NAME=curator_name VALUE=\"$curator\">\n";
#     print "<INPUT TYPE=\"HIDDEN\" NAME=\"two\" VALUE=\"$two_key\">\n";
#     my @papers_in_group;
#     print "<TR><TD>papers : " . (1 + $i) . " to " . (10 + $i) . "</TD><TD>";
#     for (my $j = $i; ( ($j < $i+10) && ($j < scalar(@papers)) ); $j++) { 
#       if ($filter_papers{$papers[$j]}{YES}) { print "<FONT COLOR = 'blue'>"; }
#       if ($filter_papers{$papers[$j]}{NO}) { print "<FONT COLOR = 'red'>"; }
#       print "paper " . ($j + 1) . " : $author_paper{$papers[$j]}<BR>\n";
#       push @papers_in_group, $papers[$j];
#       if ($filter_papers{$papers[$j]}{NO}) { print "</FONT>"; }
#       if ($filter_papers{$papers[$j]}{YES}) { print "</FONT'>"; }
#     } # for (my $j = $i; $j < $i+10; $j++)
#     print "</TD><TD><INPUT TYPE=submit NAME=action VALUE=\"Select !\"></TD>\n";
#     my $papers_in_group = join "\t", @papers_in_group;
#     print "<INPUT TYPE=\"HIDDEN\" NAME=\"paper_range\" VALUE=\"$papers_in_group\">";
#     print "</TR>\n";
#     print "</FORM>\n";
#   } # for (my $i = 0; $i < scalar(@papers); $i+=10)
  print "</TABLE><BR><P><BR>\n";
  print "<FORM METHOD=\"POST\" ACTION=\"http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/confirm_paper.cgi\">\n";
  print "<B>Please feel free to leave us any comments, especially if there are any other <I>C. elegans</I> papers you have published, excluding those that appeared in pubmed in the last 2 months, that are not in the list : </B><BR>\n";
  print "<TEXTAREA Name=\"comment\" Rows=5 Cols=40></TEXTAREA><BR>\n";
  print "<INPUT TYPE=submit NAME=action VALUE=\"Comment !\"><BR>\n";
  print "<INPUT TYPE=HIDDEN NAME=curator_name VALUE=\"$curator\">\n";
  print "<INPUT TYPE=\"HIDDEN\" NAME=\"two\" VALUE=\"$two_key\">\n";
  print "</FORM>\n";
} # sub findPapList

## papPick block ##

sub firstPage {
  my @names;		# ordered by last name order
  my %names;		# hash std and full names  2005 05 03
  my $result = $conn->exec( "SELECT * FROM two_standardname;" );
  while (my @row = $result->fetchrow) { $names{$row[0]}{std} = $row[2]; }
  $result = $conn->exec( "SELECT * FROM two_lastname ORDER BY two_lastname;" );
  while (my @row = $result->fetchrow) {
    my $joinkey = "$row[0]";
    my $fullname = "$row[2],";
    my $result2 = $conn->exec( "SELECT * FROM two_firstname WHERE joinkey = '$joinkey';" );
    my @row2 = $result2->fetchrow;
    if ($row2[1]) { $fullname .= " $row2[2]"; }
    $result2 = $conn->exec( "SELECT * FROM two_middlename WHERE joinkey = '$joinkey';" );
    @row2 = $result2->fetchrow;
    if ($row2[1]) { $fullname .= " $row2[2]"; }
    push @names, $row[0];
    $names{$row[0]}{full} = $fullname;
    $fullname = lc($fullname);			# need to lowercase for sorting
    $names{two}{$fullname} = $row[0];
  } # while (my @row = $result->fetchrow)
    
# two_fullname not kept updated, this doesn't show names without a fullname 2006 03 10
#   $result = $conn->exec( "SELECT * FROM two_fullname ORDER BY two_lastname, two_firstname, two_middlename;" );
#   while (my @row = $result->fetchrow) {
#     my $lastname = ''; my $firstname = ''; my $middlename = '';
#     if ($row[1]) { $lastname = $row[1]; }
#     if ($row[2]) { $firstname = $row[2]; }
#     if ($row[3]) { $middlename = $row[3]; }
#     my $full_name = $lastname . ", " . $firstname . " " . $middlename;
#     push @names, $row[0];
#     $names{$row[0]}{full} = $full_name;
#   } # while (my @row = $result->fetchrow)

  print "<TABLE>\n";
  print "<FORM METHOD=\"POST\" ACTION=\"http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/confirm_paper.cgi\">";
  print "<TR><TD>Select your Name among : </TD><TD colspan=2><SELECT NAME=\"curator_name\">\n";
  foreach my $fullname (sort keys %{ $names{two} }) {
    my $two = $names{two}{$fullname};
    if ($names{$two}{full}) { print "<OPTION value=\"$names{$two}{full}\">$names{$two}{full}</OPTION>\n"; } }
#   foreach my $two (@names) {			# used for fullnames, not useful anymore 2006 03 10	
#     if ($names{$two}{std}) { print "<OPTION value=\"$names{$two}{std}\">$names{$two}{full}</OPTION>\n"; } }
  print "</SELECT></TD>";
  print "<TD><INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Pick !\"></TD></TR>\n";
  print "</FORM>\n";
  print "<FORM METHOD=\"POST\" ACTION=\"http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/confirm_paper.cgi\">";
  print "<TR><TD>Or type your WBPerson number : </TD><TD><INPUT NAME=\"two_num\" SIZE=15></TD><TD>I am Cecilia<INPUT TYPE=checkbox name=\"i_am_cecilia\" value=\"YES\" CHECKED></TD>\n";
  print "<TD><INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Pick !\"></TD></TR>\n";
  print "</FORM>\n";
  print "</TABLE>\n";
} # sub firstPage



### display from key ###

sub displayOneDataFromKey {
  my ($two_key) = 'two' . $_[0];
  print "<TABLE border=1 cellspacing=2>\n";
  my $counter = 0;
  print "<TR bgcolor='$blue'><TD align='center'>table</TD><TD>WBPerson number</TD><TD>order</TD>
         <TD align='center'>Value</TD></TR>\n";
#   print "<TR bgcolor='$blue'><TD align='center'>table</TD><TD>WBPerson number</TD><TD>order</TD>
#          <TD align='center'>Value</TD><TD align='center'>Timestamp</TD></TR>\n";
  foreach my $two_table (@two_tables) {
    my $result = $conn->exec( "SELECT * FROM $two_table WHERE joinkey = '$two_key' ORDER BY two_order;" );
    while (my @row = $result->fetchrow) {
      if ($row[1]) {
        $two_table =~ s/two_//g;
        print "<TR bgcolor='$blue'>\n  <TD>$two_table</TD>\n";
        $row[0] =~ s/two//g;
        print "  <TD align='center'>$row[0]</TD>\n"; 
        print "  <TD align='center'>$row[1]</TD>\n";
        print "  <TD>$row[2]</TD>\n";
#         print "  <TD>$row[3]</TD>\n";
        print "</TR>\n";
      } # if ($row[1])
    } # while (my @row = $result->fetchrow)
  } # foreach my $two_table (@two_tables)

#   foreach my $two_simpler (@two_simpler) {
#     my $result = $conn->exec( "SELECT * FROM $two_simpler WHERE joinkey = '$two_key';" );
#     while (my @row = $result->fetchrow) {
#       if ($row[1]) {
#         $two_simpler =~ s/two_//g;
#         print "<TR bgcolor='$blue'>\n  <TD>$two_simpler</TD>\n";
#         $row[0] =~ s/two//g;
#         print "  <TD align='center'>$row[0]</TD>\n"; 
#         print "  <TD>&nbsp;</TD>\n"; 
#         print "  <TD>$row[1]</TD>\n";
#         print "  <TD>$row[2]</TD>\n";
#         print "</TR>\n";
#       } # if ($row[1])
#     } # while (my @row = $result->fetchrow)
#   } # foreach my $two_simpler (@two_simpler)

  print "</TABLE><BR><BR>\n";
} # sub displayOneDataFromKey

sub displayPaperDataFromKey {             # show all paper info from key, and checkbox for each author
  my ($author_key, $count, $two_key, $check_all) = @_;
  my $i_am_cecilia = 0;
  if ($query->param('i_am_cecilia')) {	# if picked a number, get data
    (my $oop, $i_am_cecilia) = &getHtmlVar($query, 'i_am_cecilia'); }
  $two_key = 'two' . $two_key;
  my $check_yes = '';
  my $check_no = '';
  if ($check_all eq 'yes') { $check_yes = 'CHECKED'; }
  elsif ($check_all eq 'no') { $check_no = 'CHECKED'; }
  else { 1; }
  my $paper_key = '';
  my $result = $conn->exec( "SELECT * FROM wpa_author WHERE wpa_author = '$author_key' ORDER BY wpa_timestamp; ");
  while (my @row = $result->fetchrow) {
    if ($row[3] eq "valid") { $paper_key = $row[0]; }		# paper joinkey
      else { $paper_key = ''; } }				# clear paper key
  unless ($paper_key) { print "<FONT COLOR='red'> ERROR : AUTHOR $author_key has no valid PAPER</FONT>.<BR>\n"; return; }
  if ($i_am_cecilia) { print "<TABLE border=1 cellspacing=2>\n"; }
    else { print "<TABLE cellspacing=2>\n"; }
  if ($i_am_cecilia) { print "<TR><TD align='center'>data</TD><TD>WBPerson</TD><TD align='center'>Yours</TD><TD align='center'>Not<BR>Yours</TD><TD align='center'>Selected</TD><TD>Timestamp</TD></TR>"; }
#   print "<TR><TD align='center'>table</TD><TD align='center'>data</TD><TD>WBPerson</TD><TD align='center'>Yours</TD><TD align='center'>Not<BR>Yours</TD><TD align='center'>Selected</TD></TR>";
#   print "<TR><TD align='center'>table</TD><TD align='center'>paper id</TD><TD align='center'>data</TD><TD>WBPerson</TD><TD align='center'>Yours</TD><TD align='center'>Not<BR>Yours</TD><TD align='center'>Timestamp</TD></TR>";
#   print "<TR><TD>&nbsp;wbpaper&nbsp;</TD><TD>$paper_key</TD><TD>&nbsp;</TD><TD>&nbsp;</TD><TD>&nbsp;</TD><TD>&nbsp;</TD></TR>"; 

  $result = $conn->exec( "SELECT * FROM wpa_identifier WHERE joinkey = '$paper_key' ORDER BY wpa_timestamp;" );
  my %valid_hash;						# filter things through a hash to get rid of invalid data.  2005 12 07
  while (my @row = $result->fetchrow) {
    if ($row[1]) {
      if ($row[3] eq 'valid') { $valid_hash{$row[1]}++; }
        else { delete $valid_hash{$row[1]}; } } }
  my $data = join ", ", sort keys %valid_hash;
  print "<TR><TD colspan=6>WBPaper$paper_key; $data</TD></TR>\n";

  $result = $conn->exec( "SELECT * FROM wpa_title WHERE joinkey = '$paper_key' ORDER BY wpa_timestamp;" );
  %valid_hash = ();						# filter things through a hash to get rid of invalid data.  2005 12 07
  while (my @row = $result->fetchrow) {
    if ($row[1]) {
#       $row[1] = "<A HREF=http://www.wormbase.org/db/misc/paper?name=WBPaper$paper_key;class=Paper TARGET=new>$row[1]</A>"; 
      $row[1] = "<A HREF=http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/wbpaper_display.cgi?action=Number+%21&number=$row[0] TARGET=new>$row[1]</A>";	# cecilia didn't want papers not in wormbase to not show  2008 02 05
      if ($row[3] eq 'valid') { $valid_hash{$row[1]}++; }
        else { delete $valid_hash{$row[1]}; } } }
  $data = join ", ", sort keys %valid_hash;
  print "<TR><TD colspan=6>$data</TD></TR>\n";

  my @line; 
  foreach my $paper_table (@paper_tables) { # go through each table for the key
    my %valid_hash;						# filter things through a hash to get rid of invalid data.  2005 12 07
    my $result = $conn->exec( "SELECT * FROM $paper_table WHERE joinkey = '$paper_key' ORDER BY wpa_timestamp;" );
    while (my @row = $result->fetchrow) {
      if ($row[1]) {
        if ($paper_table eq 'wpa_type') { $row[1] = $type_index{$row[1]}; }
        if ($row[3] eq 'valid') { $valid_hash{$row[1]}++; }
          else { delete $valid_hash{$row[1]}; } } }
    foreach my $data (sort keys %valid_hash) { push @line, $data; }
  } # foreach my $paper_table (@paper_tables)
  $data = join "; ", @line;
  print "<TR><TD colspan=6>$data</TD></TR>\n";

#   print "<TR><TD>&nbsp;wbpaper&nbsp;</TD><TD>$paper_key</TD><TD>&nbsp;</TD><TD>&nbsp;</TD><TD>&nbsp;</TD><TD>&nbsp;</TD></TR>"; 
#   foreach my $paper_table (@paper_tables) { # go through each table for the key
#     my $result = $conn->exec( "SELECT * FROM $paper_table WHERE joinkey = '$paper_key' ORDER BY wpa_timestamp;" );
#     my %valid_hash;						# filter things through a hash to get rid of invalid data.  2005 12 07
#     while (my @row = $result->fetchrow) {
#       if ($row[1]) {
#         if ($paper_table eq 'wpa_type') { $row[1] = $type_index{$row[1]}; }
#         my $table_name = $paper_table; $table_name =~ s/wpa_//g;
#         my $line = "<TR><TD>&nbsp;$table_name&nbsp;</TD>";
#         if ($paper_table eq 'wpa_title') { $line .= "<TD><A HREF=http://www.wormbase.org/db/misc/paper?name=WBPaper$paper_key;class=Paper TARGET=new>$row[1]</A></TD>"; }
#           else { $line .= "<TD>$row[1]</TD>"; }			# link titles to wormbase paper reports.  2005 10 11
#         $line .= "<TD>&nbsp;</TD>"; 
#         $line .= "<TD>&nbsp;</TD>"; 
#         $line .= "<TD>&nbsp;</TD>"; 
#         $line .= "<TD>&nbsp;</TD></TR>"; 
#         if ($row[3] eq 'valid') { $valid_hash{$line}++; }
#           else { delete $valid_hash{$line}; } } }
#     foreach my $line (sort keys %valid_hash) { print "$line\n"; }
#   } # foreach my $paper_table (@paper_tables)

  my %valid_authors;		# valid authors for that paper joinkey
  $result = $conn->exec( "SELECT * FROM wpa_author WHERE joinkey = '$paper_key' ORDER BY wpa_order, wpa_timestamp; ");
  while (my @row = $result->fetchrow) {
    if ($row[3] eq "valid") { $valid_authors{$row[2]} = $row[1]; }		# order, aid#
      else { delete $valid_authors{$row[2]}; } }				# delete invalid

  my @filter_authors = (); my %filter_authors = ();
  my $checkbox_sentence = '';					# hidden and checkbox data for the appropriate person to check whether their paper is theirs or not
  foreach my $order (sort { $a <=> $b } keys %valid_authors) {
    my $aid = $valid_authors{$order};				# author id
    my %author_hash;						# hash or possible, sent, and verified values for that aid
    my $author_name = ''; my $wpa_possible = ''; my $wpa_verified = ''; my $wpa_sent; my $wpa_timestamp = '';
    $result = $conn->exec( "SELECT * FROM wpa_author_sent WHERE author_id = '$aid' ORDER BY wpa_timestamp; ");
    while (my @row = $result->fetchrow) {
    if ($row[3] eq "valid") { 
        unless ($row[1]) { $row[1] = ''; }			# set to blank if no value (to make sure to overwrite with a blank)
        $author_hash{$row[2]}{timestamp} = $row[5]; 		# store timestamp value
        $author_hash{$row[2]}{sent} = $row[1]; }		# store sent value
      else { 
        $author_hash{$row[2]}{sent} = ''; 			# delete invalid
        $author_hash{$row[2]}{timestamp} = ''; } }		# delete invalid
    $result = $conn->exec( "SELECT * FROM wpa_author_verified WHERE author_id = '$aid' ORDER BY wpa_timestamp; ");
    while (my @row = $result->fetchrow) {
    if ($row[3] eq "valid") { 
        unless ($row[1]) { $row[1] = ''; }			# set to blank if no value (to make sure to overwrite with a blank)
        $author_hash{$row[2]}{timestamp} = $row[5]; 		# store timestamp value
        $author_hash{$row[2]}{verified} = $row[1]; }		# store verified value
      else { 
        $author_hash{$row[2]}{verified} = '';  			# delete invalid
        $author_hash{$row[2]}{timestamp} = ''; } }		# delete invalid
    $result = $conn->exec( "SELECT * FROM wpa_author_possible WHERE author_id = '$aid' ORDER BY wpa_timestamp; ");
    while (my @row = $result->fetchrow) {
    if ($row[3] eq "valid") { 
        unless ($row[1]) { $row[1] = ''; }			# set to blank if no value (to make sure to overwrite with a blank)
        $author_hash{$row[2]}{possible} = $row[1]; }		# store possible value
      else { $author_hash{$row[2]}{possible} = ''; } }		# delete invalid
    $result = $conn->exec( "SELECT * FROM wpa_author_index WHERE author_id = '$aid' ORDER BY wpa_timestamp; ");
    while (my @row = $result->fetchrow) {
    if ($row[3] eq "valid") { 
        unless ($row[1]) { $row[1] = ''; }			# set to blank if no value (to make sure to overwrite with a blank)
        $author_name = $row[1]; }				# store name value
      else { $author_name = ''; } }				# delete invalid
    unless ($i_am_cecilia) {					# if not cecilia, push all authors to an array to list them all
      unless ($filter_authors{$author_name}) { push @filter_authors, $author_name; }		# if not already in list of authors, push into array
      $filter_authors{$author_name}++; }			# add to list of authors already used to prevent duplicates from those who confirmed as ``no'' under another person number
    my $has_possible = 0;		# flag if author already printed in %author_hash foreach loop, otherwise print single line
    foreach my $join (sort keys %author_hash) {
      $has_possible++; 
      if ($author_hash{$join}{possible}) { $wpa_possible = $author_hash{$join}{possible}; } else { $wpa_possible = ''; }	# need to empty values if not
      if ($author_hash{$join}{verified}) { $wpa_verified = $author_hash{$join}{verified}; } else { $wpa_verified = ''; }	# 2005 11 18
      if ($author_hash{$join}{sent}) { $wpa_sent = $author_hash{$join}{sent}; } else { $wpa_sent = ''; }
      if ($author_hash{$join}{timestamp}) { $wpa_timestamp = $author_hash{$join}{timestamp}; } else { $wpa_timestamp = '&nbsp;'; }
      if ($i_am_cecilia) { 
        print "<TR>";
#         print "<TR><TD>&nbsp;author&nbsp;</TD>";
#         print "<TD>$paper_key</TD>"; 
#         print "<TD>$author_name $aid $order</TD>"; 	# just the author name, no aid nor order  2005 09 19
        print "<TD>$author_name</TD>"; 
        print "<TD ALIGN='center'>"; 
        if ($wpa_possible) { 				# link WBPerson to wormbase person report  2005 10 11
            my $link = $wpa_possible; $link =~ s/two//; print "<A HREF=http://www.wormbase.org/db/misc/person?name=WBPerson$link;class=Person TARGET=new>$link</A>"; }
          else { print "&nbsp;"; } print "</TD>";
        if ($wpa_possible eq "$two_key") {		# if Cecilia checked it and two number matches,  give option of radio button
            $count++;					# add to checkbox counter
            print "<INPUT TYPE=\"HIDDEN\" NAME=\"val_join$count\" VALUE=\"$join\">\n";		# pass wpa_join
            print "<INPUT TYPE=\"HIDDEN\" NAME=\"val_aid$count\" VALUE=\"$aid\">\n";		# pass wpa author id
            print "<INPUT TYPE=\"HIDDEN\" NAME=\"val_wpa$count\" VALUE=\"$paper_key\">\n";	# pass wpa joinkey
            if ($wpa_verified =~ m/YES/) { $check_yes = 'CHECKED'; }
            print "<TD ALIGN='center'><INPUT NAME=\"yours_or_not$count\" TYPE=\"radio\" VALUE=\"yours\" $check_yes>";
            if ($wpa_verified =~ m/YES/) { print "$wpa_verified</TD>\n"; } else { print "</TD>\n"; }
            if ($wpa_verified =~ m/NO/) { $check_no = 'CHECKED'; }
            print "<TD ALIGN='center'><INPUT NAME=\"yours_or_not$count\" TYPE=\"radio\" VALUE=\"not\" $check_no>";
            if ($wpa_verified =~ m/NO/) { print "$wpa_verified</TD>\n"; } else { print "</TD>\n"; } }
          else { print "<TD>&nbsp;</TD><TD>&nbsp;</TD>\n"; }
        print "<TD ALIGN='center'>"; 
        if ($wpa_verified) { print "$wpa_verified"; } 	# show verified
          elsif ($wpa_sent) { print "$wpa_sent"; } 	# or show sent or not
          else { print "&nbsp;"; } print "</TD>";	# or show blank
        print "<TD>$wpa_timestamp</TD>";		# also display the timestamp for VERIFIED if exists, or SENT if exists 2006 10 02
        print "</TR>\n";
      } else {
        if ($wpa_possible eq "$two_key") {		# if Cecilia checked it and two number matches,  give option of radio button
          $count++;					# add to checkbox counter
          if ($wpa_verified =~ m/YES/) { $check_yes = 'CHECKED'; }
          if ($wpa_verified =~ m/NO/) { $check_no = 'CHECKED'; }
#           print "<INPUT TYPE=\"HIDDEN\" NAME=\"val_join$count\" VALUE=\"$join\">\n";		# pass wpa_join
#           print "<INPUT TYPE=\"HIDDEN\" NAME=\"val_aid$count\" VALUE=\"$aid\">\n";		# pass wpa author id
#           print "<INPUT TYPE=\"HIDDEN\" NAME=\"val_wpa$count\" VALUE=\"$paper_key\">\n";	# pass wpa joinkey
#           print "<TR><TD><B>Confirm Yes mine or Not mine : <FONT COLOR='green'>Yes</FONT><INPUT NAME=\"yours_or_not$count\" TYPE=\"radio\" VALUE=\"yours\" $check_yes>";
#           print "<FONT COLOR='red'>No</FONT><INPUT NAME=\"yours_or_not$count\" TYPE=\"radio\" VALUE=\"not\" $check_no></B></TD></TR>\n"; 
          $checkbox_sentence .= "<INPUT TYPE=\"HIDDEN\" NAME=\"val_join$count\" VALUE=\"$join\">\n";		# pass wpa_join
          $checkbox_sentence .= "<INPUT TYPE=\"HIDDEN\" NAME=\"val_aid$count\" VALUE=\"$aid\">\n";		# pass wpa author id
          $checkbox_sentence .= "<INPUT TYPE=\"HIDDEN\" NAME=\"val_wpa$count\" VALUE=\"$paper_key\">\n";	# pass wpa joinkey
          $checkbox_sentence .= "<TR><TD><B>Confirm Yes mine or Not mine : <FONT COLOR='green'>Yes</FONT><INPUT NAME=\"yours_or_not$count\" TYPE=\"radio\" VALUE=\"yours\" $check_yes>";
          $checkbox_sentence .= "<FONT COLOR='red'>No</FONT><INPUT NAME=\"yours_or_not$count\" TYPE=\"radio\" VALUE=\"not\" $check_no></B></TD></TR>\n"; }
      }
    } # foreach my $join (sort keys %author_hash)
    if ($i_am_cecilia) { unless ($has_possible) { print "<TR><TD>&nbsp;author&nbsp;</TD><TD>$author_name</TD><TD>&nbsp;</TD><TD>&nbsp;</TD><TD>&nbsp;</TD><TD>&nbsp;</TD>"; } }
      # show separetly to cecilia list of authors that don't have a possible
  } # foreach my $order (sort keys %valid_authors)
  if (@filter_authors) { my $filtered_authors = join"; ", @filter_authors; print "<TR><TD>$filtered_authors</TD></TR>\n"; }	# show list of authors from array
  if ($checkbox_sentence) { print $checkbox_sentence; }

#   $result = $conn->exec( "SELECT * FROM pap_view WHERE joinkey = '$paper_key';" );
#     # use the view instead of separate tables
#   while (my @row = $result->fetchrow) {
#     if ($row[1]) {
#       my $joinkey = ''; my $pap_author = ''; my $pap_person = ''; my $pap_email = ''; my $pap_verified = ''; my $pap_timestamp = '';
#       if ($row[0]) { $joinkey = $row[0]; }
#       if ($row[1]) { $pap_author = $row[1]; }
#       if ($row[2]) { $pap_person = $row[2]; $pap_person =~ s/two//g; }
#       if ($row[3]) { $pap_email = $row[3]; }
#       if ($row[4]) { $pap_verified = $row[4]; }
#       if ($row[5]) { $pap_timestamp = $row[5]; }
#       print "<TR><TD>&nbsp;author&nbsp;</TD>";
#       print "<TD>$joinkey</TD>"; 
#       print "<TD>$pap_author</TD>"; 
#       my $pap_value = $joinkey . '_JOIN_' . $pap_author; 
#       print "<TD ALIGN='center'>";
#       if ($pap_person) { print "$pap_person"; } else { print "&nbsp;"; }
#       print "</TD>";
#       if ($pap_person eq "$two_key") { 	# if Cecilia checked it and two number matches,  give option of radio button
#           $count++;			# add to checkbox counter
# 					# only count and pass values for authors that can be modified with the checkbox
# 					# (don't pass all values, otherwise updating all will change all authors for those papers)
#           $pap_value =~ s/\"/REPQ/g;	# sub out doublequotes for replacement text to pass the value
#           print "<INPUT TYPE=\"HIDDEN\" NAME=\"val$count\" VALUE=\"$pap_value\">\n";
#           if ( ($pap_email eq '') && ($pap_verified eq '') ) {	# if both blank, show radio
#               print "<TD ALIGN='center'><INPUT NAME=\"yours_or_not$count\" TYPE=\"radio\" VALUE=\"yours\" $check_yes></TD>\n";
#               print "<TD ALIGN='center'><INPUT NAME=\"yours_or_not$count\" TYPE=\"radio\" VALUE=\"not\" $check_no></TD>\n"; }
#             else { 
#               print "<TD ALIGN='center'><INPUT NAME=\"yours_or_not$count\" TYPE=\"radio\" VALUE=\"yours\" $check_yes>";
#                 if ($pap_verified =~ m/YES/) { print "$pap_verified"; }
#               print "</TD>\n";
#               print "<TD ALIGN='center'><INPUT NAME=\"yours_or_not$count\" TYPE=\"radio\" VALUE=\"not\" $check_no>";
#               if ($pap_verified =~ m/NO/) { print "$pap_verified"; }
#               print "</TD>\n"; } }
#         else { print "<TD>&nbsp;</TD><TD>&nbsp;</TD>\n"; }
#       if ($pap_email eq 'NO EMAIL') { $pap_verified = $pap_email; }
#       if ($pap_verified) { print "<TD>$pap_verified</TD>"; } else { print "<TD>&nbsp;</TD>"; }
#       print "</TR>\n";
#     } # if ($row[1])
#   } # while (my @row = $result->fetchrow)
  print "</TABLE><BR><BR>\n";
  return $count;
} # sub displayPaperDataFromKey

### display from key ###

sub getCookDate {                       # get cookie date (parameter is expiration time)
  my $expires = shift;
  my @months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
  my @days = qw(Sun Mon Tue Wed Thu Fri Sat);
#   my $time_diff = 8 * 60 * 60;                # 8 hours * 60 mins * 60 sec =
#   difference to GMT
#   my $time = time;                    # set time
#   my $gmt = $time + $time_diff;               # set to gmt
  my $time = time;
  $time += $expires;                    # add extra secs to it for expiration
  my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime($time);
                                        # get time
  if ($hour < 10) { $hour = "0$hour"; } # add a zero if needed
  if ($min < 10) { $min = "0$min"; }    # add a zero if needed
  if ($sec < 10) { $sec = "0$sec"; }    # add a zero if needed
  $year = 1900+$year;                   # get right year in 4 digit form
#   my $date = "$days[$wday], ${mday}-${months[$mon]}-${year} $hour\:$min\:$sec GMT";
  my $date = "$days[$wday], ${mday}-${months[$mon]}-${year} $hour\:$min\:$sec PST";
  return $date;
} # sub getCookDate

sub mailConfirmation {
  my $two = shift;
    # used to only happen with Edit, now also email for ``Update Yours !'' or ``Update NOT Yours !''
# if ($query->param('action') eq 'Edit !') { 	# if Edit, check cookie or set cookie
  # used to check cookies, now want to always mail.
#   my $cookie_name = 'verified_connection';	# name of the cookie
#   my $cookie_is = $query->cookie( -name => "$cookie_name" );	# get cookie if there
#   unless ($cookie_is) {			# unless there's a cookie, set a cookie and email
#     $header =~ s/^.*<html>/Set-Cookie: $cookie_name=time\nContent-type: text\/html\n\n<html>/s;
    my $two_num = &getHtmlVar($query, 'two_number');
    my $result = $conn->exec( "SELECT two_email FROM two_email WHERE joinkey = 'two$two_num';" );
    my @row = $result->fetchrow; 
    my $email = "$row[0], cecilia\@tazendra.caltech.edu";
    my $user = 'cecilia@tazendra.caltech.edu';
    my $subject = "WBPerson$two Thank you for updating your Author Person Paper connection";
    my $std_name = 'C. elegans researcher';
    $result = $conn->exec( "SELECT * FROM two_standardname WHERE joinkey = 'two$two' AND two_order = '1' ORDER BY two_timestamp DESC;");
    @row = $result->fetchrow; if ($row[2]) { $std_name = $row[2]; }	# get the std name for Cecilia  2007 08 29
#     my $body = 'This is an Automatic Response.  If you have not done so, please reply to let us know, as someone has connected you with Papers you may not have published.  
# 
# Your updated profile will show in our next upload in WormBase.
# 
# Thank you,
# Cecilia Nakamura
# Assistant Curator
# California Institute of Technology
# Division of Biology 156-29
# Pasadena, CA 91125
# USA
# tel: 626.395.5878   fax: 626.395.8611
# cecilia@tazendra.caltech.edu';
# new email 2006 06 07
    my $body = "Dear $std_name :\n\n";
    $body .= 'Thank you very much for helping associate your C. elegans publications and
abstracts.

Your updated bibliography will show in our next release in your WBPerson page:
4 weeks in dev site http://dev.wormbase.org
8 weeks in live site http://www.wormbase.org

Please update or check if your information in our lineage of C. elegans
scientists is correct.
http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/person_lineage.cgi

You will be contacted if we need further assistance.

Thank you.

Please do not hesitate to contact me if you have any questions.

Have a great day.

Cecilia';
# COMMENTED OUT next line so as not to email people as Paul agrees with Cecilia 2004 01 26
# UNCOMMENTED since Cecilia wants emails sent automatically and not verify everyone's data herself 2006 06 07
#     &mailer($user, $email, $subject, $body);	# email comments to cecilia
#     $subject = "Author Person Paper updated by $two_num";
#     $body = '';
#     &mailer($user, $user, $subject, $body);	# email comments to cecilia
#   }
# } # if ($query->param('action') eq 'Edit !') 
    # Added a file to only email confirmations if they haven't confirmed within the last 86400 seconds  2006 10 02
  my $data_file = '/home/postgres/public_html/cgi-bin/data/confirm_paper_mailing.txt';
  my %time_hash;
  open (IN, "<$data_file") or die "Cannot open $data_file : $!";
  while (<IN>) { chomp; my ($file_two, $time) = split/\t/, $_; $time_hash{$file_two} = $time; }
  close (IN) or die "Cannot close $data_file : $!";
  my $time = time;
  my $mail_stuff = 1;							# by default mail confimation
  if ($time_hash{$two}) { 
    my $diff = $time - $time_hash{$two};
    if ($diff < 86400) { $mail_stuff = 0; } }				# less than a day
  if ($mail_stuff) {
    &mailer($user, $email, $subject, $body);				# email letter
    $time_hash{$two} = $time;
    open (OUT, ">$data_file") or die "Cannot create $data_file : $!";
    foreach my $two (sort keys %time_hash) { print OUT "$two\t$time_hash{$two}\n"; }
    close (OUT) or die "Cannot close $data_file : $!";
  }
} # sub mailConfirmation


__END__

