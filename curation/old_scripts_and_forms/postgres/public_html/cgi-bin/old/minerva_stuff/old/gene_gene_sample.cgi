#!/usr/bin/perl -w

# Curate Gene - Gene Interactions here until on Textpresso.org

# Got 18423 sentences with 2 different named genes and either association or regulation
# in them and put them on postgres.


use strict;
use diagnostics;
use CGI;
use Pg;			# update, insert, and select from postgres database
use Jex;		# printHeader, printFooter, getHtmlVar, mailer, getDate

my $query = new CGI;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;




&printHeader('new curation form');
&printHtmlMenu();		# site map, documentation, guidelines links
&process();			# do everything
&printFooter();

sub process {
  my $action = '';
  (my $var, $action) = &getHtmlVar($query, 'action');
  unless ($action) { &printHtmlForm(); }		# Display form, first time, no action
  else {						# Form Button
    print "ACTION : $action : ACTION<BR>\n";
    if ($action eq 'New Sentences !') { &printHtmlForm(); }
    if ($action eq 'Preview !') { &preview(); }		# check locus and curator
    if ($action eq 'New Entry !') { &write('new'); }	# write to postgres (INSERT)
    if ($action eq 'Filter !') { &filter(); }	# write to postgres (INSERT)
    print "ACTION : $action : ACTION<BR>\n";
  } # else # if ($action eq '') { &printHtmlForm(); }
} # sub process

sub filter {			# filter sentences and add them to and_curated
	# filtered - Curated, no Genetic_interaction
	# Filtered - Curated, Genetic_interaction
	# via filter - Fitered, not curated, Genetic_interaction - via sentence_id
  my $filtering_count = 0;	# how many have been filtered
  my $result = $conn->exec( "UPDATE and_curated SET and_filtered = 'filtered' WHERE and_curated != 'Genetic_interaction' AND and_filtered IS NULL;" );			# if not filtered, and not Genetic_interaction, set as ``filtered''
  $result = $conn->exec( "SELECT * FROM and_curated WHERE and_filtered IS NULL;" );	
  while (my @row = $result->fetchrow) {		# get those still not filtered, that is, those that are good
    my $joinkey = "$row[0]";
    my $gene1 = $row[1];
    my $gene2 = $row[2];
#     print "<FONT COLOR='blue'>JOIN $joinkey $gene1 $gene2</FONT><BR>\n"; 
    my $sub_query = "SELECT * FROM and_genes WHERE and_genes = \'$gene1, $gene2\';";	
    my $result2 = $conn->exec( "$sub_query" );	# get list of genes from sentences that match exactly (2 genes only in sentence)
    if ($result2) {				# if there are matches
      while (my @row2 = $result2->fetchrow) {
        if ($row2[0] eq $joinkey) { next; }	# don't filter a sentence by itself
        $filtering_count++;			# count all filtering
        my $result_fix = $conn->exec( "INSERT INTO and_curated VALUES ('$row2[0]', '$gene1', '$gene2', 'Genetic_interaction - via $joinkey', 'via filter');" );				# insert into list of sentences with data
    } }
    $sub_query = "SELECT * FROM and_genes WHERE and_genes = \'$gene2, $gene1\';";
    my $result3 = $conn->exec( "$sub_query" );
    if ($result3) {
      while (my @row3 = $result3->fetchrow) {
        if ($row3[0] eq $joinkey) { next; }		# don't filter something by itself
        $filtering_count++;
        my $result_fix = $conn->exec( "INSERT INTO and_curated VALUES ('$row3[0]', '$gene2', '$gene1', 'Genetic_interaction - via $joinkey', 'via filter');" );
    } }
    my $result_fix = $conn->exec( "UPDATE and_curated SET and_filtered = 'Filtered' WHERE joinkey = \'$joinkey\' AND and_gene1 = \'$gene1\' AND and_gene2 = \'$gene2\' AND and_curated = \'Genetic_interaction\';" );		# set this line as updated
  } # while (my @row = $result->fetchrow)
  print "<BR><FONT COLOR='blue'>Have Filtered $filtering_count Sentences</FONT><BR><BR>\n";
  &countSentences();
} # sub filter

sub write {
  my $hidden_values = &getHtmlValuesFromForm('write');		# read html values from form to hash and var 
  # get count of each type of Interaction, only one from each sentence.  (all genetic, all no, all
  # possible_genetic, all possible_other)
  &countSentences();
  print "<FORM METHOD=\"POST\" ACTION=\"http://minerva.caltech.edu/~postgres/cgi-bin/gene_gene_sample.cgi\">\n";
  print "<INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Filter !\"><BR>\n";
  print "<INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"New Sentences !\"><BR>\n";
  print "</FORM>\n";
} # sub write

sub countSentences {
  my %hash;
  my $result = $conn->exec( "SELECT * FROM and_curated;" );
  while (my @row = $result->fetchrow) { 
    if ($row[3] eq 'Genetic_interaction') { $hash{good}{$row[0]}++; }
    elsif ($row[3] =~ 'Genetic_interaction') { $hash{filtered}{$row[0]}++; }
    else { $hash{bad}{$row[0]}++; }
  } # while my (@row = $result->fetchow)
  foreach my $good (keys %{ $hash{good} }) { delete $hash{filtered}{$good}; delete $hash{bad}{$good}; }
  foreach my $filtered (keys %{ $hash{filtered} }) { delete $hash{bad}{$filtered}; }
  my $good = scalar( keys %{ $hash{good} } );
  my $filtered = scalar( keys %{ $hash{filtered} } );
  my $bad = scalar( keys %{ $hash{bad} } );
  print "<BR>\n";
  print "<FONT COLOR = 'green'>There are $good sentences with Genetic Interaction curated by you</FONT>.<BR>\n";
  print "<FONT COLOR = 'blue'>There are $filtered sentences with Genetic Interaction filtered</FONT>.<BR>\n";
  print "<FONT COLOR = 'red'>There are $bad sentences with no Genetic Interaction curated by you</FONT>.<BR>\n";
  print "<BR>\n";
} # sub countSentences

sub preview {
  my $hidden_values = &getHtmlValuesFromForm('preview');	# read html values from form to hash and var
  print "<FORM METHOD=\"POST\" ACTION=\"http://minerva.caltech.edu/~postgres/cgi-bin/gene_gene_sample.cgi\">\n";
  print $hidden_values;				# pass hidden values
  print "<INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"New Entry !\"><P>\n"; 
  print "</FORM>\n";
} # sub preview

sub getHtmlValuesFromForm {
  my $write_flag = shift;	# should we update postgres ?  if 'write' yes
  my $hidden_values = '';	# hidden values from the form
  my ($var, $line_count) = &getHtmlVar($query, 'line_count');	# number of sentences
  print "<BR><TABLE border=1 cellspacing=5>\n";
  print "<TR><TD>key</TD><TD>gene1</TD><TD>gene2</TD><TD>interaction</TD></TR>\n";
  for my $count ( 1 .. $line_count ) {				# for each sentence
    my $value = "key$count";					# get joinkey
    my ($var, $val) = &getHtmlVar($query, $value);
    my $joinkey = $val;
    $hidden_values .= "<INPUT TYPE=\"HIDDEN\" NAME=\"$value\" VALUE=\"$val\">\n";
    my @pg_commands;		# commands to put through Pg
    BOXES: for my $j ( 0 .. 2 ) {				# for each of 3 boxes
      $value = "gene1${count}box$j";				# gene1's box number $j
      ($var, $val) = &getHtmlVar($query, "$value");		# get the gene
      my $gene1 = $val;		
      if ($gene1) { $gene1 = "\'$gene1\'"; } else { $gene1 = 'NULL'; }	# will never be NULL at the moment
      $hidden_values .= "<INPUT TYPE=\"HIDDEN\" NAME=\"$value\" VALUE=\"$val\">\n";
      $value = "gene2${count}box$j";				# gene2's box number $j
      ($var, $val) = &getHtmlVar($query, "$value");		# get the gene
      my $gene2 = $val;
      if ($gene2) { $gene2 = "\'$gene2\'"; } else { $gene2 = 'NULL'; }
      $hidden_values .= "<INPUT TYPE=\"HIDDEN\" NAME=\"$value\" VALUE=\"$val\">\n";
      $value = "interaction${count}box$j";			# interaction for box number $j
      ($var, $val) = &getHtmlVar($query, "$value");
      my $curated = $val;
      $hidden_values .= "<INPUT TYPE=\"HIDDEN\" NAME=\"$value\" VALUE=\"$val\">\n";
      if ($gene1 eq "\'No Gene\'") {				# if there is no gene
        if ($j eq '0') { 					# if it's the first box, mark the sentence as 
								# having interation for No Gene and No Gene
          push @pg_commands,  "INSERT INTO and_curated VALUES ('$joinkey', $gene1, $gene2, '$curated')"; 
          print "<TR><TD>$joinkey</TD><TD>$gene1</TD><TD>$gene2</TD><TD>$curated</TD></TR>\n"; }
        last BOXES; }						# and don't bother to keep checking other boxes
      unless ($gene1 eq "\'No Gene\'") {			# if there are genes
        if ($gene1 eq $gene2) { 				# and both are the same, ignore them and error message
          print "<FONT COLOR=red><B>SAME GENES $gene1 $gene2 IGNORED</B></FONT><BR>\n"; next; } }
     								# for good stuff, keep going
      push @pg_commands,  "INSERT INTO and_curated VALUES ('$joinkey', $gene1, $gene2, '$curated')";
      print "<TR><TD>$joinkey</TD><TD>$gene1</TD><TD>$gene2</TD><TD>$curated</TD></TR>\n";
    } # BOXES: for my $j ( 0 .. 2 )
    if ($write_flag eq 'write') { 				# if writing, output
      foreach my $pgcommand (@pg_commands) { 			# for each command
#         print "PG : $pgcommand<BR>\n"; 				# show PG command
        my $result = $conn->exec( "$pgcommand" );		# execute PG command
      }
    } # if ($write_flag eq 'write')
  } # for my $count ( 1 .. $line_count )
  $hidden_values .= "<INPUT TYPE=\"HIDDEN\" NAME=\"line_count\" VALUE=\"$line_count\">\n";
  print "</TABLE>\n";
  return $hidden_values;
} # sub getHtmlValuesFromForm


########## Postgres ########## 


########## Postgres ########## 

########## HTML ########## 

sub printHtmlMenu {
  print <<"  EndOfText";
  <CENTER><A HREF="http://minerva.caltech.edu/~azurebrd/cgi-bin/index.cgi">Site Map</A></CENTER>
  EndOfText
} # sub printHtmlMenu

sub printHtmlField {
  my ($type, $val) = @_;
  my $color = 'black';							# default color is black
  print "<FONT COLOR='$color'>$type : $val</FONT><BR>\n";
} # sub printHtmlField


  ## HTML FORM **

sub printHtmlForm {		# display the html form
  &printHtmlFormStart();	# beginning of form 
  &getSomeSentences();		# get some sentences
#   &printHtmlSection('General Info'); 
  &printHtmlFormButtonMenu(); 	# buttons of form
  &printHtmlFormEnd();		# ending of form 
} # sub printHtmlForm

sub printHtmlFormStart {	# beginning of form
  print <<"  EndOfText";
  <A NAME="form"><H1>Choose your Interactions : </H1></A>
  <FORM METHOD="POST" ACTION="http://minerva.caltech.edu/~postgres/cgi-bin/gene_gene_sample.cgi">
  <TABLE>
  EndOfText
} # sub printHtmlFormStart

sub getSomeSentences {
  my %curatedHash;
#   my $result = $conn->exec( "SELECT * FROM and_curated WHERE and_curated IS NOT NULL;" );
#   my $result = $conn->exec( "SELECT * FROM and_curated WHERE (and_filtered = 'Filtered') OR (and_filtered ~ 'iltered');" );
  my $result = $conn->exec( "SELECT * FROM and_curated WHERE (and_filtered IS NULL) OR (and_filtered ~ 'iltered');" );
  my $max_num = 0;				# highest uncurated line number
  while (my @row = $result->fetchrow() ) {
    $row[0] =~ s/and//;
    $curatedHash{ignore}{$row[0]}++;
    if ($row[3] eq 'Filtered') { $curatedHash{filtered}{$row[0]}++; }	# filtered
      else { if ($row[0] > $max_num) { $max_num = $row[0]; } }		# update max if necessary
  } # while (my @row = $result->fetchrow(); )
  $result = $conn->exec( "SELECT * FROM and_curated;" );
  while (my @row = $result->fetchrow() ) {
    $row[0] =~ s/and//;
    $curatedHash{ignore}{$row[0]}++;
  }

#   my $start_range = 1;
#   my $end_range = 10;
#   my ($var, $val) = &getHtmlVar($query, 'start_range');
#   if ($val) { $start_range = $val; }
#   ($var, $val) = &getHtmlVar($query, 'end_range');
#   if ($val) { $end_range = $val; }
  my $end_range = $max_num + 3;		# last sentence to display (show 3)

  print "<TABLE>\n";
  my $count = 0;			# line number
  my $num = $max_num;			# max number of curated sentence 
  while ($num < $end_range) {		# while less than the max number
    $num++;				# start with the following sentence
      # if already has data, show another sentence and ignore this one
    if ($curatedHash{ignore}{$num}) { $end_range++; next; }	
    print "<TR>\n";
    $count++;
    my $result = $conn->exec( "SELECT * FROM and_location WHERE joinkey = 'and$num';" );
    my @row = $result->fetchrow();
    print "<TD></TD><TD>$row[0]</TD><TD>$row[1]</TD>\n";
    print "<INPUT TYPE=\"HIDDEN\" NAME=\"key$count\" VALUE=\"$row[0]\">\n";
    $result = $conn->exec( "SELECT * FROM and_text WHERE joinkey = 'and$num';" );
    @row = $result->fetchrow();
    $row[1] =~ s/<gene grammar[^>]*?'direct'[^>]*?>/<FONT COLOR='blue'>/g;
    $row[1] =~ s/<gene grammar[^>]*?'indirect'[^>]*?>/<FONT COLOR='cyan'>/g;
    $row[1] =~ s/<\/gene>/<\/FONT>/g;
    $row[1] =~ s/<association [^>]*?>/<FONT COLOR='red'>/g;
    $row[1] =~ s/<\/association>/<\/FONT>/g;
    $row[1] =~ s/<regulation [^>]*?>/<FONT COLOR='magenta'>/g;
    $row[1] =~ s/<\/regulation>/<\/FONT>/g;
    print "<TD></TD><TD rowspan=4>$row[1]</TD>\n";
    $result = $conn->exec( "SELECT * FROM and_genes WHERE joinkey = 'and$num';" );
    @row = $result->fetchrow();
    my (@genes) = split/, /, $row[1];
    print "</TR>\n";

    for my $j (0 .. 2) { 
      print "<TR>\n";
      print "    <TD><SELECT NAME=\"gene1${count}box$j\" SIZE=5>\n";
      print "        <OPTION selected>No Gene</OPTION>\n";
      foreach my $gene (@genes) { print "<OPTION>$gene</OPTION>\n"; }
      print "    </SELECT></TD>\n";
      print "    <TD><SELECT NAME=\"gene2${count}box$j\" SIZE=5>\n";
      print "        <OPTION selected>No Gene</OPTION>\n";
      foreach my $gene (@genes) { print "<OPTION>$gene</OPTION>\n"; }
      print "    </SELECT></TD>\n";
      print "    <TD><SELECT NAME=\"interaction${count}box$j\" SIZE=5>\n";
      print "        <OPTION>Genetic_interaction</OPTION>\n";
      print "        <OPTION selected>No_interaction</OPTION>\n";
      print "        <OPTION>Possible_genetic_interaction</OPTION>\n";
      print "        <OPTION>Possible_other_interaction</OPTION>\n";
#       print "        <OPTION>Suppression</OPTION>\n";
#       print "        <OPTION>Enhancement</OPTION>\n";
#       print "        <OPTION>Mutual_enhancement</OPTION>\n";
#       print "        <OPTION>Regulation</OPTION>\n";
#       print "        <OPTION>Physical_interaction</OPTION>\n";
      print "    </SELECT></TD>\n";
      print "</TR>\n";
    }
    print "<TR><TD>&nbsp;<BR>&nbsp;</TD></TR>\n";

  } # while ($num < $end_range)
  print "<INPUT TYPE=\"HIDDEN\" NAME=\"line_count\" VALUE=\"$count\">\n";
  print "</TABLE>\n";
} # sub getSomeSentences

sub printHtmlFormButtonMenu {	# buttons of form
  print <<"  EndOfText";
  <TR><TD COLSPAN=2> </TD></TR>
  <TR>
    <TD> </TD>
    <TD><INPUT TYPE="submit" NAME="action" VALUE="New Entry !">
    <TD><INPUT TYPE="submit" NAME="action" VALUE="Filter !">
    <!--<TD><INPUT TYPE="submit" NAME="action" VALUE="Preview !">
        <INPUT TYPE="submit" NAME="action" VALUE="Reset !"></TD>-->
  </TR>
  EndOfText
} # sub printHtmlFormButtonMenu # buttons of form

sub printHtmlFormEnd {		# ending of form
  print <<"  EndOfText";
  </TABLE>
  </FORM>
  EndOfText
} # sub printHtmlFormEnd

sub printHtmlSection {		# print html sections
  my $text = shift;		# get name of section
  print "\n  "; for (0..12) { print '<TR></TR>'; } print "\n\n";		# divider
  print "  <TR><TD><STRONG><FONT SIZE=+1>$text : </FONT></STRONG></TD></TR>\n";	# section
} # sub printHtmlSection

########## HTML ########## 


