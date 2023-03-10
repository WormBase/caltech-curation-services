#!/usr/bin/perl -w

# Edit Concise Description Data
#
# Update Block button needs to be checked for the form to look at the block of data.  

 
use strict;
use CGI;
use Pg;
use Jex;

my $query = new CGI;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;



my $blue = '#00ffcc';			# redefine blue to a mom-friendly color
my $red = '#ff00cc';			# redefine red to a mom-friendly color

my $frontpage = 1;			# show the front page on first load
my $curator;
my @PGparameters = qw( concise );
# my @PGparameters = qw( concise 
#                        ort1 ort1_ref1 ort1_ref2 ort1_ref3 ort1_ref4 
#                        ort2 ort2_ref1 ort2_ref2 ort2_ref3 ort2_ref4 
#                        ort3 ort3_ref1 ort3_ref2 ort3_ref3 ort3_ref4 
#                        ort4 ort4_ref1 ort4_ref2 ort4_ref3 ort4_ref4 
#                      );
my %theHash;
my %emails;

&printHeader('Concise Description Form');
&initializeHash();              # create complex data structure
&display();
&printFooter();

sub display {
  my $action;
  unless ($action = $query->param('action')) {
    $action = 'none';
    if ($frontpage) { &firstPage(); }
  } else { $frontpage = 0; }

  print "ACTION : $action<BR>\n";
  if ($action eq 'Curator !') { &mainPage(); }
  if ($action eq 'Preview !') { &preview(); }
  if ($action eq 'New Entry !') { &write('new'); }	# write to postgres (INSERT)
  if ($action eq 'Update !') { &write('update'); }	# write to postgres (UPDATE)
  if ($action eq 'Query !') { &query(); }		# query postgres
  print "ACTION : $action<BR>\n";
} # sub display

sub query {
  my ($var, $joinkey) = &getHtmlVar($query, 'html_value_gene');
  if ($joinkey) { print "GENE $joinkey<BR>\n"; }
    else { print "<FONT SIZE=+2 COLOR='red'><B>ERROR : Need to enter a Gene</B></FONT><BR>\n"; next; }
  my $result = $conn->exec( "SELECT * FROM car_lastcurator WHERE joinkey = \'$joinkey\' ORDER BY car_timestamp DESC;" );
  my @row = $result->fetchrow; 
  my $found = $row[1];					# curator from car_lastcurator
  if ($found eq '') { 
    print "Entry not found, please click ``back'' and create it.\n"; return; }
  else {
#     print "FOUND $found<BR>\n";
    $theHash{gene}{html_value} = $joinkey; 
    my $type = 'concise';
    my $pgtable = 'concise'; my $htmltype = 'html_value';
    &getValueFromPostgres($joinkey, $pgtable, $type, $htmltype);	# get value from postgres
    $pgtable = 'con_curator'; $htmltype = 'curator_name';
    &getValueFromPostgres($joinkey, $pgtable, $type, $htmltype);	# get value from postgres
    for my $j ( 1 .. 16 ) {
      my $reftype = $type . '_ref' . $j;
      $htmltype = 'html_value';
      $pgtable = "con_ref" . $j;
      &getValueFromPostgres($joinkey, $pgtable, $reftype, $htmltype);	# get value from postgres
    } # for my $j ( 1 .. 16 )

    my @categories = qw( ort gen phy exp oth );
    foreach my $cat (@categories) {
      my $highnum = 6;
      if ($cat eq 'ort') { $highnum = 4; }
      elsif ($cat eq 'oth') { $highnum = 5; }
      for my $i (1 .. $highnum) {			# six is max amount, some have less but won't have box checked
#         $field = $cat . $i;
#           my $type = $field; my $val = $theHash{$field}{html_value};
#           &updatePostgresFieldTables($type, $val);    # update postgres for all tables
# #           print "$field CUR $theHash{$field}{curator_name}<BR>\n";
# 
#           $type = $field . '_curator'; $val = $theHash{$field}{curator_name};
#           &updatePostgresFieldTables($type, $val);    # update postgres for all tables
# #           print "$field VAL $theHash{$field}{html_value}<BR>\n";
# 
#           for my $j (1 .. 4) {				# for each reference
#             my $subtype = $cat . $i . '_ref' . $j;
#             $type = "$subtype"; $val = $theHash{$field}{$subtype};
#             &updatePostgresFieldTables($type, $val);    # update postgres for all tables
# #             print "$field SUB $subtype $theHash{$field}{$subtype}<BR>\n"; 
#           } # for my $j (1 .. 4)
        $type = $cat . $i;
        my $pgtable = $cat . $i; my $htmltype = 'html_value';
        &getValueFromPostgres($joinkey, $pgtable, $type, $htmltype);	# get value from postgres
        $pgtable = $type . '_curator'; $htmltype = 'curator_name';
        &getValueFromPostgres($joinkey, $pgtable, $type, $htmltype);	# get value from postgres
        for my $j (1 .. 4) {				# for each reference
#           my $subtype = $cat . $i . '_ref' . $j;
#           $type = "$subtype"; $val = $theHash{$field}{$subtype};
          my $reftype = $type . '_ref' . $j;
          $htmltype = 'html_value';
          $pgtable = $type . "_ref" . $j;
          &getValueFromPostgres($joinkey, $pgtable, $reftype, $htmltype);	# get value from postgres
        } # for my $j (1 .. 4)
      } # for my $i (1 .. 6)
    } # foreach my $cat (@categories)

    &mainPage(); }
} # sub query

sub getValueFromPostgres {
  my ($joinkey, $pgtable, $type, $htmltype) = @_;
  $pgtable = 'car_' . $pgtable;
#   print "TAB $pgtable<BR>\n";
#   print "SELECT * FROM $pgtable WHERE joinkey = \'$joinkey\' ORDER BY car_timestamp DESC;<BR>\n";
  my $result = $conn->exec( "SELECT * FROM $pgtable WHERE joinkey = \'$joinkey\' ORDER BY car_timestamp DESC;" );
  my @row = $result->fetchrow; 
  my $found = ' ';
  if ($row[1]) { 
    $found = $row[1]; }
  unless ($found) { $found = ' '; }
  $theHash{$type}{$htmltype} = $found;
#   print "FOUND $found<BR>\n";
} # sub getValueFromPostgres

sub write {
  my $new_or_update = shift;				# flag whether to add ``UPDATE : '' to subject line
  my $hidden_values = &getHtmlValuesFromForm();
  my $field = 'concise';
  if ($theHash{$field}{html_mail_box}) {
    my $type = 'lastcurator'; my $val = $theHash{main}{curator_name};
    print "MAIN CUR $val<BR>\n";
    &updatePostgresFieldTables($type, $val);    # update postgres for all tables
    $type = 'concise'; $val = $theHash{$field}{html_value};
    &updatePostgresFieldTables($type, $val);    # update postgres for all tables
    print "$field CUR $theHash{$field}{curator_name}<BR>\n";
    $type = 'con_curator'; $val = $theHash{$field}{curator_name};
    &notifyPostgresPreviousCurator($type, $val);	# email previous curator
    &updatePostgresFieldTables($type, $val);    # update postgres for all tables
#     print "$field VAL $theHash{$field}{html_value}<BR>\n";
    for my $j ( 1 .. 16 ) {
      my $subtype = 'ref' . $j;
      $type = "con_$subtype"; $val = $theHash{$field}{$subtype};
      &updatePostgresFieldTables($type, $val);    # update postgres for all tables
#       print "$field SUB $subtype $theHash{$field}{$subtype}<BR>\n"; 
    } # for my $j ( 1 .. 16 )
    
    my @categories = qw( ort gen phy exp oth );
    foreach my $cat (@categories) {
      for my $i (1 .. 6) {				# six is max amount, some have less but won't have box checked
        $field = $cat . $i;
        if ($theHash{$field}{html_mail_box}) {		# if box was checked
          my $type = $field; my $val = $theHash{$field}{html_value};
          &updatePostgresFieldTables($type, $val);	# update postgres for all tables
#           print "$field CUR $theHash{$field}{curator_name}<BR>\n";
          $type = $field . '_curator'; $val = $theHash{$field}{curator_name};
          &notifyPostgresPreviousCurator($type, $val);	# email previous curator
          &updatePostgresFieldTables($type, $val);	# update postgres for all tables
#           print "$field VAL $theHash{$field}{html_value}<BR>\n";
          for my $j (1 .. 4) {				# for each reference
            my $subtype = $cat . $i . '_ref' . $j;
            $type = "$subtype"; $val = $theHash{$field}{$subtype};
            &updatePostgresFieldTables($type, $val);    # update postgres for all tables
#             print "$field SUB $subtype $theHash{$field}{$subtype}<BR>\n"; 
          } # for my $j (1 .. 4)
        } # if ($theHash{$field}{html_mail_box})
      } # for my $i (1 .. 6)
    } # foreach my $cat (@categories)
  } # if ($theHash{concise}{html_mail_box})
  print "WRITE $new_or_update<BR>\n";
} # sub write

sub notifyPostgresPreviousCurator {
    # check the curator drop down menus and compare them to the previous entry (latest), if they
    # differ, then email the previous curator that someone else has written to that block of tables 2004 05 18
  my ($table, $val) = @_;
  $table = 'car_' . $table;
  my ($var, $curator) = &getHtmlVar($query, 'curator_name');
  my $joinkey = $theHash{gene}{html_value}; 
  if ($val ne ' ') { 					# if there's a value
    my $result = $conn->exec( "SELECT $table FROM $table WHERE joinkey = \'$joinkey\' ORDER BY car_timestamp DESC;" );
    print "SELECT $table FROM $table WHERE joinkey = \'$joinkey\' ORDER BY car_timestamp DESC;<BR>\n"; 
    my @row = $result->fetchrow;
    if ($row[0]) {					# if there's a previous curator
							# doesn't matter if curators don't match
#       if ($row[0] ne $val) { 				# if curators don't match
        my $old_curator;
        if ($row[0] =~ m/Carol/) { $old_curator = 'carol'; }
        elsif ($row[0] =~ m/Erich/) { $old_curator = 'erich'; }
        elsif ($row[0] =~ m/Ranjana/) { $old_curator = 'ranjana'; }
        elsif ($row[0] =~ m/Kimberly/) { $old_curator = 'kimberly'; }
        elsif ($row[0] =~ m/Paul/) { $old_curator = 'paul'; }
        elsif ($row[0] =~ m/Igor/) { $old_curator = 'igor'; }
        elsif ($row[0] =~ m/Raymond/) { $old_curator = 'raymond'; }
        elsif ($row[0] =~ m/Andrei/) { $old_curator = 'andrei'; }
        elsif ($row[0] =~ m/Wen/) { $old_curator = 'wen'; }
        elsif ($row[0] =~ m/Juancarlos/) { $old_curator = 'azurebrd'; }
        else { $old_curator = 'previous_curator_not_found'; }
#         my $user = $val;
        my $user = $curator;				# want curator that logged on, not curator in block's drop down menu
        my $email = $emails{$old_curator};
        my $subject = "$user has updated $joinkey entry in $table in the Concise Description Form.";
        my $body = '';
        &mailer($user, $email, $subject, $body);
        print "EMAIL OLD $row[0] NEW $val<BR>\n"; 
#       } # if ($row[0] ne $val)
    } # if ($row[0])
  } # if ($val ne ' ')  
} # sub notifyPostgresPreviousCurator

sub updatePostgresFieldTables {
  my ($table, $val) = @_;
  $table = 'car_' . $table;
  my $joinkey = $theHash{gene}{html_value}; 
  if ($val ne ' ') { 
    my $result = $conn->exec( "INSERT INTO $table VALUES (\'$joinkey\', \'$val\');" );
    print "INSERT INTO $table VALUES (\'$joinkey\', \'$val\');<BR>"; }
  else { 
    my $result = $conn->exec( "INSERT INTO $table VALUES (\'$joinkey\', NULL);" );
    print "INSERT INTO $table VALUES (\'$joinkey\', NULL);<BR>"; }
} # sub updatePostgresFieldTables

sub findIfPgEntry {
  my $result = $conn->exec( "SELECT * FROM car_lastcurator WHERE joinkey = '$theHash{gene}{html_value}';" );
  my $found;                            # curator from cur_curator
  while (my @row = $result->fetchrow) { $found = $row[1]; if ($found eq '') { $found = ' '; } }
  return $found;
} # sub findIfPgEntry

sub preview {
  my $hidden_values = &getHtmlValuesFromForm();
  my $errorRequire = &checkRequired();
  my $found = &findIfPgEntry('curator');              # query pg curator table for pubID
  print "<FORM METHOD=\"POST\" ACTION=\"http://minerva.caltech.edu/~postgres/cgi-bin/old/concise_description_multiref_20040528.cgi\">\n";
  print "$hidden_values<BR>\n";
  if ($found) { print "<INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Update !\"><P>\n"; }
    else { print "<INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"New Entry !\"><P>\n"; }
  print "</FORM>\n";

#   my $oop;
#   if ($query->param('two')) { $oop = $query->param('two'); } 
#     else { $oop = 'nodatahere'; }
#   my $two = untaint($oop);
#   if ($query->param('vals')) { $oop = $query->param('vals'); } 
#     else { $oop = 'nodatahere'; }
#   my $vals = untaint($oop); 
#   print "two : $two : vals : $vals<BR><BR>\n";
#   &displayOneDataFromKey($two);
#   my @keys = split /\t/, $vals;
#   print "<TABLE border=1 cellspacing=5>\n";
#   foreach my $key (@keys) {
#   } # foreach my $key (@keys)
#   print "</TABLE>\n";
} # sub preview

sub checkRequired {
  1;							# haven't implemented this
} # sub checkRequired

sub getHtmlValuesFromForm {
  my $hidden_values = '';
  my $html_type = 'html_value_gene';
  my $field = 'gene';
  my ($var, $val) = &getHtmlVar($query, $html_type);
  if ($val) { 			# if no gene entered, error
    print "GENE $val<BR>\n";
    $theHash{$field}{html_value} = $val;
    $hidden_values .= "<INPUT TYPE=\"HIDDEN\" NAME=\"html_value_gene\" VALUE=\"$val\">\n"; }
  else {
    print "<FONT SIZE=+2 COLOR='red'><B>ERROR : Need to enter a Gene</B></FONT><BR>\n";
    next; }

  ($var, my $curator) = &getHtmlVar($query, 'curator_name');
  $theHash{main}{curator_name} = $curator;
  $hidden_values .= "<INPUT TYPE=\"HIDDEN\" NAME=\"curator_name\" VALUE=\"$curator\">\n"; 

  $html_type = 'html_value_box_concise';
  $field = 'concise';
  ($var, $val) = &getHtmlVar($query, $html_type);
  if ($val) { 				# if box checked
    $theHash{$field}{html_mail_box} = $val;
    $hidden_values .= "<INPUT TYPE=\"HIDDEN\" NAME=\"$html_type\" VALUE=\"$val\">\n";
    print "There is Concise data<BR>\n"; 
    $html_type = 'html_value_concise';
    my ($var, $val) = &getHtmlVar($query, $html_type);
    $theHash{$field}{html_value} = $val;
    $hidden_values .= "<INPUT TYPE=\"HIDDEN\" NAME=\"$html_type\" VALUE=\"$val\">\n";
    print "Concise Description $val<BR>\n";
    $html_type = 'html_value_curator_concise';
    ($var, $val) = &getHtmlVar($query, $html_type);
    $theHash{$field}{curator_name} = $val;
    $hidden_values .= "<INPUT TYPE=\"HIDDEN\" NAME=\"$html_type\" VALUE=\"$val\">\n";
    print "CUR $val<BR>\n";
#     $html_type = 'html_timestamp_concise';
#     ($var, $val) = &getHtmlVar($query, $html_type);
#     $theHash{$field}{html_timestamp} = $val;
#     $hidden_values .= "<INPUT TYPE=\"HIDDEN\" NAME=\"$html_type\" VALUE=\"$val\">\n";
#     print "TIME $val<BR>\n";
    for my $j ( 1 .. 16 ) {
      $html_type = 'html_value_concise_ref' . $j;
      my $subtype = 'ref' . $j;
      ($var, $val) = &getHtmlVar($query, $html_type);
      unless ($val) { $val = ' '; }
      $theHash{$field}{$subtype} = $val;
      $hidden_values .= "<INPUT TYPE=\"HIDDEN\" NAME=\"$html_type\" VALUE=\"$val\">\n";
      print "REF $j $val<BR>\n";
    }
  } # if ($val)

  my @categories = qw( ort gen phy exp oth );
  foreach my $cat (@categories) {
    for my $i (1 .. 6) {
      $field = $cat . $i;
      my $html_type = "html_value_box_$cat$i";
      ($var, $val) = &getHtmlVar($query, $html_type);
      if ($val) {				# if box checked
        $theHash{$field}{html_mail_box} = $val;
        $hidden_values .= "<INPUT TYPE=\"HIDDEN\" NAME=\"$html_type\" VALUE=\"$val\">\n";
        print "$cat $i value checked<BR>\n";
        $html_type = "html_value_$cat$i";
        ($var, $val) = &getHtmlVar($query, $html_type);
        $theHash{$field}{html_value} = $val;
        $hidden_values .= "<INPUT TYPE=\"HIDDEN\" NAME=\"$html_type\" VALUE=\"$val\">\n";
        print "$cat $i $val<BR>\n";
        $html_type = "html_value_curator_$cat$i";
        ($var, $val) = &getHtmlVar($query, $html_type);
        $theHash{$field}{curator_name} = $val;
        $hidden_values .= "<INPUT TYPE=\"HIDDEN\" NAME=\"$html_type\" VALUE=\"$val\">\n";
        print "$html_type $i $val<BR>\n";
#         $html_type = "html_timestamp_$cat$i";
#         ($var, $val) = &getHtmlVar($query, $html_type);
#         $theHash{$field}{html_timestamp} = $val;
#         $hidden_values .= "<INPUT TYPE=\"HIDDEN\" NAME=\"$html_type\" VALUE=\"$val\">\n";
#         print "$html_type $i $val<BR>\n";
        for my $j (1 .. 4) {
          my $subtype = $cat . $i . '_ref' . $j;
          $html_type = "html_value_$subtype";
          ($var, $val) = &getHtmlVar($query, $html_type);
          unless ($val) { $val = ' '; }
          $theHash{$field}{$subtype} = $val;
          $hidden_values .= "<INPUT TYPE=\"HIDDEN\" NAME=\"$html_type\" VALUE=\"$val\">\n";
          print "$html_type $i $val<BR>\n";
        } # for my $j (1 .. 4)
      } # if ($val)
    } # for my $i (1 .. 6)
  } # foreach my $cat (@categories)
  return $hidden_values;
} # sub getHtmlValuesFromForm

sub displayOneDataFromKey {
  my $two = shift;
  print "TWO $two<BR>\n";
}

sub mainPage {
  &printHtmlFormStart();
  my ($var, $curator) = &getHtmlVar($query, 'curator_name');
  print "<INPUT TYPE=\"HIDDEN\" NAME=\"curator_name\" VALUE=\"$curator\">\n"; 
  print "CURATOR : $curator<BR>\n";
  &printHtmlFormButtonMenu();
  &printHtmlSection('Gene');
  &printHtmlInputGene();
  &printHtmlSection('Concise Description');
  &printHtmlTextarea('concise');
  &printHtmlRef16('concise');
  &printHtmlSection('Orthology/Family/Domains');
  &printHtmlInputs('ort');
  &printHtmlSection('Genetic Interactions/Pathway and/or Biological Process');
  &printHtmlInputs('gen');
  &printHtmlSection('Physical Interactions and/or Biochemical Activity');
  &printHtmlInputs('phy');
  &printHtmlSection('Expression');
  &printHtmlInputs('exp');
  &printHtmlSection('Other');
  &printHtmlInputs('oth');
  &printHtmlFormButtonMenu();
  &printHtmlFormEnd();
} # sub mainPage

sub printHtmlInputs {
  my $grouptype = shift;
  my $num = 6;
#   print "<TABLE bgcolor='cyan'>\n";
  if ($grouptype eq 'ort') { $num = 4; } 
  elsif ($grouptype eq 'oth') { $num = 5; } 
  else { 1; }
  for my $i ( 1 .. $num ) {
    my $type = $grouptype . $i;
    &printHtmlInput($type);
  }
#   print "</TABLE>\n";
} # sub printHtmlInputs

sub printHtmlInputGene {         # print html input for gene
  my $type = 'gene';
  if ($theHash{$type}{html_value}) { if ($theHash{$type}{html_value} eq 'NULL') { $theHash{$type}{html_value} = ''; } }
				# clear NULL
  print <<"  EndOfText";
  <TR>
    <TD ALIGN="right"><STRONG>Gene :</STRONG></TD>
    <TD>
      <TABLE>
        <TR>
          <TD><INPUT NAME="html_value_$type" VALUE="$theHash{$type}{html_value}"
                     SIZE=$theHash{$type}{html_size_main}></TD>
          <TD ALIGN="left"><INPUT TYPE="submit" NAME="action" VALUE="Query !"></TD>
          <TD>(3-letter gene, e.g. pie-1)</TD>
        </TR>
      </TABLE>
    </TD>
  </TR>
  EndOfText
} # sub printHtmlInputGene


sub printHtmlInput {         # print html textareas
  my $type = shift;             # get type, use hash for html parts
  my $action;
  unless ($action = $query->param('action')) { $action = 'none'; } else { $frontpage = 0; }
  if ($action eq 'Curator !') { (my $var, $theHash{$type}{curator_name}) = &getHtmlVar($query, 'curator_name'); }
  if ($theHash{$type}{html_value} eq 'NULL') { $theHash{$type}{html_value} = ''; }      # clear NULL
  print <<"  EndOfText";
  <TR></TR><TR></TR><TR></TR><TR></TR><TR></TR>
  <TR></TR><TR></TR><TR></TR><TR></TR><TR></TR>
  <TR></TR><TR></TR><TR></TR><TR></TR><TR></TR>
  <TR></TR>
  <TR>
    <TD ALIGN="right"><STRONG>$theHash{$type}{html_field_name} :</STRONG></TD>
    <TD>
      <TABLE>
        <TR>
          <TD><TEXTAREA NAME="html_value_$type" ROWS=$theHash{$type}{html_size_minor}
               COLS=$theHash{$type}{html_size_main}>$theHash{$type}{html_value}</TEXTAREA></TD>
          <TD>Update Block :<BR><INPUT NAME="html_value_box_$type" TYPE="checkbox" VALUE="yes"></TD>
          <TD> </TD>
          <TD><SELECT NAME="html_value_curator_$type" SIZE=1>
                <OPTION>$theHash{$type}{curator_name}</OPTION>
                <OPTION>Carol Bastiani</OPTION>
                <OPTION>Ranjana Kishore</OPTION>
                <OPTION>Erich Schwarz</OPTION>
                <OPTION>Kimberly Van Auken</OPTION>
                <OPTION>Paul Sternberg</OPTION>
                <OPTION>Igor Antoshechkin</OPTION>
                <OPTION>Raymond Lee</OPTION>
                <OPTION>Andrei Petcherski</OPTION>
                <OPTION>Wen Chen</OPTION>
                <OPTION>Juancarlos Testing</OPTION>
              </SELECT>
              <!--<INPUT NAME="html_timestamp_$type" VALUE="$theHash{$type}{timestamp}">--></TD>
        </TR>
      </TABLE>
    </TD>
  </TR>
  <TR>
    <TD ALIGN="right"><STRONG>$theHash{$type}{html_field_name} References :</STRONG></TD>
    <TD>
      <TABLE>
        <TR>
  EndOfText
    for my $i (1 .. 4) {
      my $subtype = $type . '_ref' . $i;
      print "      <TD><INPUT NAME=\"html_value_$subtype\" VALUE=\"$theHash{$subtype}{html_value}\"\n";
      print "           SIZE=$theHash{$subtype}{html_size_main}></TD>\n";
    }
  print <<"  EndOfText";
        </TR>
      </TABLE>
    </TD>
  </TR>
  EndOfText
} # sub printHtmlInput

sub printHtmlRef16 {
  my $type = shift;             # get type, use hash for html parts
  for my $j ( 1 .. 4) {
  print <<"  EndOfText";
  <TR>
    <TD ALIGN="right"><STRONG>$theHash{$type}{html_field_name} References :</STRONG></TD>
    <TD>
      <TABLE>
        <TR>
  EndOfText
    for my $i (1 .. 4) {
      my $num = ($j * 4) - 4 + $i;
      my $subtype = $type . '_ref' . $num;
      print "      <TD><INPUT NAME=\"html_value_$subtype\" VALUE=\"$theHash{$subtype}{html_value}\"\n";
      print "           SIZE=$theHash{$subtype}{html_size_main}></TD>\n";
    }
  print <<"  EndOfText";
        </TR>
      </TABLE>
    </TD>
  </TR>
  EndOfText
  } # for my $j ( 1 .. 4)
} # sub printHtmlRef16

sub printHtmlTextarea {         # print html textareas
  my $type = shift;             # get type, use hash for html parts
  my $action;
  unless ($action = $query->param('action')) { $action = 'none'; } else { $frontpage = 0; }
  if ($action eq 'Curator !') { (my $var, $theHash{$type}{curator_name}) = &getHtmlVar($query, 'curator_name'); }
  if ($theHash{$type}{html_value} eq 'NULL') { $theHash{$type}{html_value} = ''; }      # clear NULL
  print <<"  EndOfText";
  <TR>
    <TD ALIGN="right"><STRONG>$theHash{$type}{html_field_name} :</STRONG></TD>
    <TD>
      <TABLE>
        <TR>
          <TD><TEXTAREA NAME="html_value_$type" ROWS=$theHash{$type}{html_size_minor}
               COLS=$theHash{$type}{html_size_main}>$theHash{$type}{html_value}</TEXTAREA></TD>
          <TD>Update Block :<BR><INPUT NAME="html_value_box_$type" TYPE="checkbox" VALUE="yes"></TD>
          <TD> </TD>
          <TD><SELECT NAME="html_value_curator_$type" SIZE=1>
                <OPTION>$theHash{$type}{curator_name}</OPTION>
                <OPTION>Carol Bastiani</OPTION>
                <OPTION>Ranjana Kishore</OPTION>
                <OPTION>Erich Schwarz</OPTION>
                <OPTION>Kimberly Van Auken</OPTION>
                <OPTION>Paul Sternberg</OPTION>
                <OPTION>Igor Antoshechkin</OPTION>
                <OPTION>Raymond Lee</OPTION>
                <OPTION>Andrei Petcherski</OPTION>
                <OPTION>Wen Chen</OPTION>
                <OPTION>Juancarlos Testing</OPTION>
              </SELECT>
              <!--<INPUT NAME="html_timestamp_$type" VALUE="$theHash{$type}{timestamp}">--></TD>
  EndOfText
  unless ($theHash{$type}{html_last_curator} eq 'no one') {
    # if someone to mail, print box and email address
    print <<"    EndOfText";
<!--          <TD><INPUT NAME="html_mail_box_$type" TYPE="checkbox"
               $theHash{$type}{html_mail_box} VALUE="yes"></TD>-->
          <TD> <FONT SIZE=-1>Last Curator $theHash{$type}{html_last_curator}</FONT></TD>
    EndOfText
  } # unless ($theHash{$type}{html_last_curator} eq 'no one')
  print <<"  EndOfText";
        </TR>
      </TABLE>
    </TD>
  </TR>
  EndOfText
} # sub printHtmlTextarea


sub printHtmlSection {          # print html sections
  my $text = shift;             # get name of section
  print "\n  "; for (0..12) { print '<TR></TR>'; } print "\n\n";                # divider
  print "  <TR><TD><STRONG><FONT SIZE=+1>$text : </FONT></STRONG></TD></TR>\n"; # section
} # sub printHtmlSection

sub printHtmlFormEnd {          # ending of form
  print <<"  EndOfText";
  </TABLE>
  </FORM>
  EndOfText
} # sub printHtmlFormEnd

sub printHtmlFormStart {
  print <<"  EndOfText";
  <A NAME="form"><H1>Add your entries : </H1></A>
  <FORM METHOD="POST" ACTION="http://minerva.caltech.edu/~postgres/cgi-bin/old/concise_description_multiref_20040528.cgi">
  <TABLE>
  EndOfText
} # sub printHtmlFormStart

sub printHtmlFormButtonMenu {   # buttons of form
  print <<"  EndOfText";
  <TR><TD COLSPAN=2> </TD></TR>
  <TR></TR> <TR></TR> <TR></TR> <TR></TR> <TR></TR>
  <TR></TR> <TR></TR> <TR></TR> <TR></TR> <TR></TR>
  <TR></TR> <TR></TR> <TR></TR> <TR></TR> <TR></TR>
  <TR>
    <TD> </TD>
    <TD><INPUT TYPE="submit" NAME="action" VALUE="Preview !"></TD>
<!--      <INPUT TYPE="submit" NAME="action" VALUE="Options !">
      <INPUT TYPE="submit" NAME="action" VALUE="Save !">
      <INPUT TYPE="submit" NAME="action" VALUE="Load !">
      <INPUT TYPE="submit" NAME="action" VALUE="Reset !"></TD>
    <TD><INPUT TYPE="submit" NAME="action" VALUE="Select All E-mail !">
      <INPUT TYPE="submit" NAME="action" VALUE="Select None E-mail !"></TD>-->
  </TR>
  EndOfText
} # sub printHtmlFormButtonMenu # buttons of form


sub initializeEmails {                  # create email codes and addresses
#   $emails{erich} = 'azurebrd@minerva.caltech.edu';
#   $emails{carol} = 'azurebrd@minerva.caltech.edu';
#   $emails{ranjana} = 'azurebrd@minerva.caltech.edu';
#   $emails{kimberly} = 'azurebrd@minerva.caltech.edu';
#   $emails{azurebrd} = 'azurebrd@minerva.caltech.edu';
  $emails{erich} = 'emsch@its.caltech.edu';
  $emails{carol} = 'bastiani@its.caltech.edu';
  $emails{ranjana} = 'ranjana@its.caltech.edu';
  $emails{kimberly} = 'vanauken@its.caltech.edu';
  $emails{paul} = 'pws@its.caltech.edu';
  $emails{igor} = 'igorant@caltech.edu';
  $emails{raymond} = 'raymond@its.caltech.edu';
  $emails{andrei} = 'agp@its.caltech.edu';
  $emails{wen} = 'wen@athena.caltech.edu';
  $emails{azurebrd} = 'azurebrd@minerva.caltech.edu';
  $emails{''} = 'no one';               # just in case
                                        # (and flag to not print if irrelevant in textarea)
} # sub initializeEmails


sub initializeHash {
  # initialize the html field name, mailing codes, html mailing addresses, and mailing subjects.
  # in case of new fields, add to @PGparameters array and create html_field_name entry in %theHash
  # and other %theHash fields as necessary.  if new email address, add to %emails.

  &initializeEmails();                  # create email codes and addresses
  
  foreach my $field (@PGparameters) {
    $theHash{$field}{mail_to} = '';
    $theHash{$field}{mail_subject} = '';
    $theHash{$field}{curator_name} = '';
    $theHash{$field}{timestamp} = 'Current Timestamp';	# default no timestamp
    $theHash{$field}{html_field_name} = '';             # name for display
    $theHash{$field}{html_value_box} = '';              # checkbox for ``yes'' instead of value
    $theHash{$field}{html_value} = '';                  # value for field
#     $theHash{$field}{html_mail_box} = 'checked';        # checkbox to mail default mail everyone
    $theHash{$field}{html_mail_box} = '';        	# no, this value used to check whether curators wants block updated
    $theHash{$field}{html_last_curator} = 'no one';	# default to mail no one
    $theHash{$field}{html_size_main} = '60';            # default width 60
    $theHash{$field}{html_size_minor} = '4';            # default height 4
  } # foreach my $field (@PGparameters)

  $theHash{gene}{html_size_main} = '15';
  $theHash{gene}{html_value} = '';

  $theHash{concise}{html_field_name} = 'Concise Description';
  $theHash{concise}{mail_to} = '';
  $theHash{concise}{html_mail_name} = "$emails{$theHash{concise}{mail_to}}";
  $theHash{concise}{mail_subject} = 'Concise Description';
  for my $j (1 .. 16) {
    my $subtype = 'concise' . '_ref' . $j;
    $theHash{$subtype}{html_value} = '';
    $theHash{$subtype}{html_size_main} = '15'; }

  for my $i (1 .. 4) {					# orthology init
    $theHash{"ort$i"}{html_field_name} = "Orthology $i";
    $theHash{"ort$i"}{html_value} = '';
    $theHash{"ort$i"}{html_size_minor} = '4'; 
    $theHash{"ort$i"}{html_size_main} = '60';
    $theHash{"ort$i"}{timestamp} = 'Current Timestamp';
    $theHash{"ort$i"}{curator_name} = '';
    $theHash{"ort$i"}{mail_to} = '';
    $theHash{"ort$i"}{html_mail_name} = "$emails{$theHash{concise}{mail_to}}";
    $theHash{"ort$i"}{mail_subject} = "Orthology $i";
    for my $j (1 .. 4) {
      my $subtype = 'ort' . $i . '_ref' . $j;
      $theHash{$subtype}{html_value} = '';
      $theHash{$subtype}{html_size_main} = '15'; }
  }

  for my $i (1 .. 6) {					# genetic init
    $theHash{"gen$i"}{html_field_name} = "Genetic $i";
    $theHash{"gen$i"}{html_value} = '';
    $theHash{"gen$i"}{html_size_minor} = '4';
    $theHash{"gen$i"}{html_size_main} = '60';
    $theHash{"gen$i"}{timestamp} = 'Current Timestamp';
    $theHash{"gen$i"}{curator_name} = '';
    $theHash{"gen$i"}{mail_to} = '';
    $theHash{"gen$i"}{html_mail_name} = "$emails{$theHash{concise}{mail_to}}";
    $theHash{"gen$i"}{mail_subject} = "Genetic $i";
    for my $j (1 .. 4) {
      my $subtype = 'gen' . $i . '_ref' . $j;
      $theHash{$subtype}{html_value} = '';
      $theHash{$subtype}{html_size_main} = '15'; }
  }

  for my $i (1 .. 6) {					# physical init
    $theHash{"phy$i"}{html_field_name} = "Physical $i";
    $theHash{"phy$i"}{html_value} = '';
    $theHash{"phy$i"}{html_size_minor} = '4';
    $theHash{"phy$i"}{html_size_main} = '60';
    $theHash{"phy$i"}{timestamp} = 'Current Timestamp';
    $theHash{"phy$i"}{curator_name} = '';
    $theHash{"phy$i"}{mail_to} = '';
    $theHash{"phy$i"}{html_mail_name} = "$emails{$theHash{concise}{mail_to}}";
    $theHash{"phy$i"}{mail_subject} = "Physical $i";
    for my $j (1 .. 4) {
      my $subtype = 'phy' . $i . '_ref' . $j;
      $theHash{$subtype}{html_value} = '';
      $theHash{$subtype}{html_size_main} = '15'; }
  }

  for my $i (1 .. 6) {					# expression init
    $theHash{"exp$i"}{html_field_name} = "Expression $i";
    $theHash{"exp$i"}{html_value} = '';
    $theHash{"exp$i"}{html_size_minor} = '4';
    $theHash{"exp$i"}{html_size_main} = '60';
    $theHash{"exp$i"}{timestamp} = 'Current Timestamp';
    $theHash{"exp$i"}{curator_name} = '';
    $theHash{"exp$i"}{mail_to} = '';
    $theHash{"exp$i"}{html_mail_name} = "$emails{$theHash{concise}{mail_to}}";
    $theHash{"exp$i"}{mail_subject} = "Expression $i";
    for my $j (1 .. 4) {
      my $subtype = 'exp' . $i . '_ref' . $j;
      $theHash{$subtype}{html_value} = '';
      $theHash{$subtype}{html_size_main} = '15'; }
  }

  for my $i (1 .. 5) {					# other init
    $theHash{"oth$i"}{html_field_name} = "Other $i";
    $theHash{"oth$i"}{html_value} = '';
    $theHash{"oth$i"}{html_size_minor} = '4';
    $theHash{"oth$i"}{html_size_main} = '60';
    $theHash{"oth$i"}{timestamp} = 'Current Timestamp';
    $theHash{"oth$i"}{curator_name} = '';
    $theHash{"oth$i"}{mail_to} = '';
    $theHash{"oth$i"}{html_mail_name} = "$emails{$theHash{concise}{mail_to}}";
    $theHash{"oth$i"}{mail_subject} = "Other $i";
    for my $j (1 .. 4) {
      my $subtype = 'oth' . $i . '_ref' . $j;
      $theHash{$subtype}{html_value} = '';
      $theHash{$subtype}{html_size_main} = '15'; }
  }

} # sub initializeHash


# sub firstPage {
#   my $date = &getDate();
#   print "Value : $date<BR>\n";
# 
#   print "<TABLE border=1 cellspacing=5>\n";
#   print "<TR>\n";
#   print "<FORM METHOD=\"POST\" ACTION=\"http://minerva.caltech.edu/~postgres/cgi-bin/concise_description.cgi\">\n";
#   print "</FORM>\n";
#   print "</TABLE>\n";
# } # sub firstPage

sub firstPage {
  print "<FORM METHOD=\"POST\" ACTION=\"http://minerva.caltech.edu/~postgres/cgi-bin/old/concise_description_multiref_20040528.cgi\">\n";
  print "<TABLE>\n";
  print "<TR><TD>Select your Name among : </TD><TD><SELECT NAME=\"curator_name\" SIZE=10>\n";
#   print "<OPTION>Igor Antoshechkin</OPTION>\n";
  print "<OPTION>Carol Bastiani</OPTION>\n";
#   print "<OPTION>Wen Chen</OPTION>\n";
  print "<OPTION>Ranjana Kishore</OPTION>\n";
#   print "<OPTION>Raymond Lee</OPTION>\n"; 
#   print "<OPTION>Andrei Petcherski</OPTION>\n";
  print "<OPTION>Erich Schwarz</OPTION>\n";
#   print "<OPTION>Paul Sternberg</OPTION>\n";
  print "<OPTION>Kimberly Van Auken</OPTION>\n";
  print "<OPTION>Paul Sternberg</OPTION>\n";
  print "<OPTION>Igor Antoshechkin</OPTION>\n";
  print "<OPTION>Raymond Lee</OPTION>\n";
  print "<OPTION>Andrei Petcherski</OPTION>\n";
  print "<OPTION>Wen Chen</OPTION>\n";
#   print "<OPTION>Andrei Testing</OPTION>\n";
  print "<OPTION>Juancarlos Testing</OPTION>\n"; 
  print "</SELECT></TD><TD><INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Curator !\"></TD></TR><BR><BR>\n";
  print "</TABLE>\n"; 
  print "</FORM>\n";
} # sub firstPage

