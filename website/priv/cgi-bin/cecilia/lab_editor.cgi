#!/usr/bin/env perl

# edit lab_ tables's laboratory data
#
# made some fields multi value for Cecilia.  2018 07 09
#
# http for .js wasn't working anymore after tazendra move to Chen and back, and possibly because of ssl cert that Valerio wanted.
# cloudflare links Sybil found weren't working because of a type error or something.  Downloaded needed files and pointed to
# https://tazendra.caltech.edu/~azurebrd/javascript/yui/2.7.0/  2021 11 16

 


use strict;
use CGI;
use Jex;		# &getPgDate; &getSimpleDate;
use DBI;
use Tie::IxHash;
use Dotenv -load => '/usr/lib/cgi-bin/.env';


# Use all timestamps to use latest to create  Last_verified  date
#
# Created a comment field, made email url remark comment multivalue.  2018 07 03


# my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $dbh = DBI->connect ( "dbi:Pg:dbname=$ENV{PSQL_DATABASE};host=$ENV{PSQL_HOST};port=$ENV{PSQL_PORT}", "$ENV{PSQL_USERNAME}", "$ENV{PSQL_PASSWORD}") or die "Cannot connect to database!\n";
my $result;

my $query = new CGI;

my $frontpage = 1;
# my $blue = '#b8f8ff';			# redefine blue to a mom-friendly color
my $blue = '#e8f8ff';			# redefine blue to a mom-friendly color
my $grey = '#d0d0d0';			# redefine grey to a mom-friendly color
my $red = '#ff00cc';			# redefine red to a mom-friendly color

my $tdDot = qq(td align="center" style="border-style: dotted; border-color: #007FFF");
my $thDot = qq(th align="center" style="border-style: dotted; border-color: #007FFF");

my %curators;                           # $curators{two}{two#} = std_name ; $curators{std}{std_name} = two#

# my @normal_tables = qw( name mail phone email fax url straindesignation alleledesignation remark );
my @normal_tables = qw( name alleledesignation status mail email phone fax url remark comment );

my %order_type;
# my @single_order = qw( name alleledesignation mail phone email fax url straindesignation remark );
my @single_order = qw( name alleledesignation status );
my @multi_order = qw( mail email phone fax url remark comment );
foreach (@single_order) { $order_type{single}{$_}++; }
foreach (@multi_order) { $order_type{multi}{$_}++; }

my %min_rows;
foreach my $table (@normal_tables) { $min_rows{$table} = 1; }
$min_rows{'mail'} = 4;



my %type_input;				# all inputs are inputs, but usefulwebpage is a checkbox
foreach (@normal_tables) { $type_input{$_} = 'input'; } 
$type_input{'usefulwebpage'} = 'checkbox';


&display();


sub display {
  my $action; my $normal_header_flag = 1;

  unless ($action = $query->param('action')) {
    $action = 'none';
    if ($frontpage) { &firstPage(); }
  } else { $frontpage = 0; }

  if ($action eq 'autocompleteXHR') { &autocompleteXHR(); }
    elsif ($action eq 'updatePostgresTableField') { &updatePostgresTableField(); }
    elsif ($action eq 'Search') { &search(); }
    elsif ($action eq 'Create New Lab') { &createNewLab(); }
} # sub display


sub createNewLab {
  &printHtmlHeader();
  my ($curator_two) = &getCuratorFromForm();
  (my $var, my $labname) = &getHtmlVar($query, 'new_lab');

  my $result = $dbh->prepare( "SELECT * FROM lab_name WHERE lab_name = '$labname';" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  my @row = $result->fetchrow();
  if ($row[0]) { 
    print qq(ERROR, this lab $labname already exists.<br/>\n); 
    return; }

  my ($lab_number) = &getHighestJoinkey(); 
  $lab_number++; my $joinkey = 'lab' . $lab_number;
  my ($curator_two) = &getCuratorFromForm();
  my $url = "lab_editor.cgi?curator_two=$curator_two&action=Search&display_or_edit=edit&input_number_1=$joinkey";
  print "<input type=\"hidden\" name=\"which_page\" id=\"which_page\" value=\"createNewLab\">";
  print "<input type=\"hidden\" name=\"redirect_to\" id=\"redirect_to\" value=\"$url\">";
  my @pgcommands;
  push @pgcommands, "INSERT INTO lab_name       VALUES ('$joinkey', '1', '$labname', '$curator_two');";
  push @pgcommands, "INSERT INTO lab_name_hst   VALUES ('$joinkey', '1', '$labname', '$curator_two');";
  push @pgcommands, "INSERT INTO lab_status     VALUES ('$joinkey', '1', 'Valid', '$curator_two');";
  push @pgcommands, "INSERT INTO lab_status_hst VALUES ('$joinkey', '1', 'Valid', '$curator_two');";
  foreach my $command (@pgcommands) {
    print "$command<br />\n";
    $result = $dbh->do( $command );
  } # foreach my $command (@pgcommands)
} # sub createNewLab

sub getHighestJoinkey {
  $result = $dbh->prepare( "SELECT * FROM lab_status" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  my %hash;
  while ( my @row = $result->fetchrow() ) {
    $row[0] =~ s/lab//; $hash{$row[0]}++; }
  my (@highest) = sort {$b<=>$a} keys %hash;
  return $highest[0];
} # sub getHighestJoinkey


sub autocompleteXHR {
  print "Content-type: text/plain\n\n";
  (my $var, my $words) = &getHtmlVar($query, 'query');
  ($var, my $order) = &getHtmlVar($query, 'order');
  ($var, my $field) = &getHtmlVar($query, 'field');
  my $table = 'lab_' . $field; my $column = $table;
  if ($field eq 'number') { $table = 'lab_name'; $column = 'joinkey'; }
  my $max_results = 20; if ($words =~ m/^.{5,}/) { $max_results = 500; }
  ($words) = lc($words);                                        # search insensitively by lowercasing query and LOWER column values
  my %matches; my $t = tie %matches, "Tie::IxHash";     # sorted hash to filter results
  my $result = $dbh->prepare( "SELECT DISTINCT($column) FROM $table WHERE LOWER($column) ~ '^$words' ORDER BY $column;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while ( (my @row = $result->fetchrow()) && (scalar keys %matches < $max_results) ) { $matches{"$row[0]"}++; }
  $result = $dbh->prepare( "SELECT DISTINCT($column) FROM $table WHERE LOWER($column) ~ '$words' AND LOWER($column) !~ '^$words' ORDER BY $column;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while ( (my @row = $result->fetchrow()) && (scalar keys %matches < $max_results) ) { $matches{"$row[0]"}++; }
  if (scalar keys %matches >= $max_results) { $t->Replace($max_results - 1, 'no value', 'more ...'); }
  my $matches = join"\n", keys %matches; print $matches;
} # sub autocompleteXHR

sub fromUrlToPostgres {
  my $value = shift;
  if ($value) {
    if ($value =~ m/%2B/) { $value =~ s/%2B/+/g; }                # convert URL plus to literal
    if ($value =~ m/%23/) { $value =~ s/%23/#/g; }                # convert URL pound to literal
    if ($value =~ m/\'/) { $value =~ s/\'/''/g; }                 # escape singlequotes
  }
  return $value;
} # sub fromUrlToPostgres

sub updatePostgresByTableJoinkeyNewvalue {
  my ($field, $joinkey, $order, $newValue, $curator_two) = @_;
# print "F $field J $joinkey O $order N $newValue E<br/>\n";
  my $uid = 'joinkey'; my $sorter = 'lab_order';
  my @pgcommands;
# on update  delete from data table and insert ; delete from history table current-10 minutes and insert
  if ($order) { 
      my $command = "DELETE FROM lab_$field WHERE $uid = '$joinkey' AND $sorter = '$order'";
      push @pgcommands, $command;
      $command = "DELETE FROM lab_${field}_hst WHERE $uid = '$joinkey' AND $sorter = '$order' AND lab_timestamp > now() - interval '10 minutes'";
      push @pgcommands, $command;
      $order = "'$order'"; } 
    else { 
      my $command = "DELETE FROM lab_$field WHERE $uid = '$joinkey' AND $sorter IS NULL";
      push @pgcommands, $command;
      $command = "DELETE FROM lab_${field}_hst WHERE $uid = '$joinkey' AND $sorter IS NULL AND lab_timestamp > now() - interval '10 minutes'";
      push @pgcommands, $command;
      $order = 'NULL'; }

  if ($newValue) { $newValue = "'$newValue'"; }
    else { $newValue = 'NULL'; }

  my $command = "INSERT INTO lab_${field}_hst VALUES ('$joinkey', $order, $newValue, '$curator_two')";
  push @pgcommands, $command;
  if ($newValue ne 'NULL') {
    $command = "INSERT INTO lab_$field VALUES ('$joinkey', $order, $newValue, '$curator_two')";
    push @pgcommands, $command; }

  foreach my $command (@pgcommands) {
#     print "$command<br />\n";
    $result = $dbh->do( $command );
  }
  return "OK";
} # sub updatePostgresByTableJoinkeyNewvalue

sub updatePostgresTableField {                          # if updating postgres table values, update postgres and return OK if ok
  print "Content-type: text/html\n\n";
  (my $var, my $field) = &getHtmlVar($query, 'field');
  ($var, my $joinkey) = &getHtmlVar($query, 'joinkey');
  ($var, my $order) = &getHtmlVar($query, 'order');
  ($var, my $curator_two) = &getHtmlVar($query, 'curator_two');
  ($var, my $newValue) = &getHtmlVar($query, 'newValue');
  ($newValue) = &fromUrlToPostgres($newValue);

  my $isOk = 'NO';

  ($isOk) = &updatePostgresByTableJoinkeyNewvalue($field, $joinkey, $order, $newValue, $curator_two);

  if ($isOk eq 'OK') { print "OK"; }
} # sub updatePostgresTableField


sub firstPage {
  &printHtmlHeader();
  print "<input type=\"hidden\" name=\"which_page\" id=\"which_page\" value=\"firstPage\">";
  my $date = &getDate();
    # using post instead of get makes a confirmation request when javascript reloads the page after a change.  2010 03 12
  print "<form name='form1' method=\"get\" action=\"lab_editor.cgi\">\n";
  print "<table border=0 cellspacing=5>\n";
  print "<tr><td colspan=\"2\">Select your Name : <select name=\"curator_two\" size=\"1\">\n";
  &populateCurators();
  my $ip = $query->remote_host();                               # select curator by IP if IP has already been used
  my $curator_by_ip = '';
  my $result = $dbh->prepare( "SELECT * FROM two_curator_ip WHERE two_curator_ip = '$ip';" ); 
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; my @row = $result->fetchrow;
  if ($row[0]) { $curator_by_ip = $row[0]; }
#   my @curator_list = ('two1823', 'two1', 'two12028', 'two712', 'two2970');
  my @curator_list = ('two1823', 'two1');
  foreach my $joinkey (@curator_list) {                         # display curators in alphabetical (array) order, if IP matches existing ip record, select it
    my $curator = $joinkey;
    if ($curators{two}{$curator}) { $curator = $curators{two}{$curator}; }
    if ($joinkey eq $curator_by_ip) { print "<option value=\"$joinkey\" selected=\"selected\">$curator</option>\n"; }
      else { print "<option value=\"$joinkey\" >$curator</option>\n"; } }
  print "</select></td>";
  print "<td colspan=\"2\">Date : $date</td></tr>\n";

  print "<tr><td>&nbsp;</td></tr>\n";

  print "<tr>\n";
  print qq(<td colspan="3"><input name="new_lab">\n);
  print "<input type=submit name=action value=\"Create New Lab\"></tr>\n";
  print "<tr><td colspan=\"3\">\n";
  print "<input type=submit name=action value=\"Search\">\n";
  (my $var, my $display_or_edit) = &getHtmlVar($query, "display_or_edit"); my $display_checked = 'checked="checked"'; my $edit_checked = ''; 
  if ($display_or_edit) { if ($display_or_edit eq 'edit') { $edit_checked = 'checked="checked"'; $display_checked = ''; } }
#       if ($current_value) { if ($current_value eq $value) { $selected = "selected=\"selected\""; $found_value++; } }
  print "<input type=\"radio\" name=\"display_or_edit\" value=\"display\" $display_checked />display\n";
  print "<input type=\"radio\" name=\"display_or_edit\" value=\"edit\" $edit_checked />edit\n";
  print "</td>\n";
  print "</tr>\n";
  foreach my $table (@normal_tables) {
    my $order = 1; my $input_size = 80; my $colspan = 1;
    my $table_to_print = &showEditorText($table, $order, $input_size, $colspan, '');
    $table_to_print .= "<input type=\"hidden\" class=\"fields\" value=\"$table\" \/>\n";
    $table_to_print .= "<input type=\"hidden\" id=\"type_input_$table\" value=\"$type_input{$table}\">\n";
    $table_to_print .= "<input type=\"hidden\" id=\"highest_order_$table\" value=\"1\">\n";

    print "<tr>";
    print $table_to_print;
    my $style = ''; 
    if ( ($table eq 'number') || ($table eq 'status') ) { $style = 'display: none'; }
    print "<td style='$style'><input type=\"checkbox\" value=\"on\" name=\"substring_$table\">substring</td>\n";
    print "<td style='$style'><input type=\"checkbox\" value=\"on\" name=\"case_$table\">case insensitive (automatic substring)</td>\n"; 
    print "</tr>\n";
  } # foreach my $table "number", (@normal_tables)

  print "</table>\n";
  print "</form>\n";
  &printFooter();
} # sub firstPage


sub showEditorText {
  my ($table, $order, $input_size, $colspan, $value) = @_;
  my $table_to_print = "<td id=\"label_$table\">$table</td><td width=\"550\" colspan=\"$colspan\">\n";  # there's some weird auto-sizing of the table where it shrinks to nothing if the td doesn't have a size, so min size is 550
#   $table_to_print .= "<input id=\"input_$table\" name=\"input_$table\" size=\"$input_size\">\n";
  my $freeForced = 'free';
  my $containerSpanId = "container${freeForced}${table}${order}AutoComplete";
  my $divAutocompleteId = "${freeForced}${table}${order}AutoComplete";
  my $inputId = "input_${table}_$order";
  my $divContainerId = "${freeForced}${table}${order}Container";
  $table_to_print .= "<span id=\"$containerSpanId\">\n";
  $table_to_print .= "<div id=\"$divAutocompleteId\" class=\"div-autocomplete\">\n";
  $table_to_print .= "<input id=\"$inputId\" name=\"$inputId\" size=\"$input_size\" value=\"$value\">\n";
  $table_to_print .= "<div id=\"$divContainerId\"></div></div></span>\n";
  $table_to_print .= "</td>\n";
  return $table_to_print;
} # sub showEditorText


### Search Section ###
 
sub search {
  &printHtmlHeader();
  my ($curator_two) = &getCuratorFromForm();
  (my $var, my $number) = &getHtmlVar($query, "input_number_1");
  if ($number) {
    &displayLab("$number", $curator_two); return;
#     if ($number =~ m/(\d+)/) { &displayLab("$1", $curator_two); return; }
#       else { print "Not a number in a number search for $number<br />\n"; } 
  }

  print "<input type=\"hidden\" name=\"which_page\" id=\"which_page\" value=\"searchResults\">";

  my %hash;
  my $order = 1;
  foreach my $table (@normal_tables) {
    ($var, my $data) = &getHtmlVar($query, "input_${table}_${order}");
    next unless ($data);	# skip those with search params
    my $substring = ''; my $case = ''; my $operator = '=';
    ($var, $substring) = &getHtmlVar($query, "substring_$table");
    ($var, $case)      = &getHtmlVar($query, "case_$table");
    unless ($substring) { $substring = ''; }
    unless ($case)      { $case = '';      }
    if ($case eq 'on') { $operator = '~*'; }
    elsif ($substring eq 'on') { $operator = '~'; }
#     print "SELECT joinkey, lab_$table FROM lab_$table WHERE lab_$table $operator '$data'<br />\n";
    $result = $dbh->prepare( "SELECT joinkey, lab_$table FROM lab_$table WHERE lab_$table $operator '$data'" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) { 
      $hash{matches}{$row[0]}{$table}++; 
      push @{ $hash{table}{$table}{$row[0]} }, $row[1]; }
  } # foreach my $table (@normal_tables)
  my %matches; 
  my $joinkeys = join"','", keys %{ $hash{matches} }; my %std_name; my %status;
  $result = $dbh->prepare( "SELECT joinkey, lab_name FROM lab_name WHERE joinkey IN ('$joinkeys')" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { $std_name{$row[0]} = $row[1]; }
#   $result = $dbh->prepare( "SELECT joinkey, lab_status FROM lab_status WHERE joinkey IN ('$joinkeys')" );
#   $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
#   while (my @row = $result->fetchrow) { if ($row[1] eq 'Invalid') { $status{$row[0]} = $row[1]; } else { $status{$row[0]} = ''; } }
  foreach my $joinkey (keys %{ $hash{matches} }) {
    my $count = scalar keys %{ $hash{matches}{$joinkey} }; $matches{$count}{$joinkey}++; }
  foreach my $count (reverse sort {$a<=>$b} keys %matches) {
    print "<br />Matches $count<br />\n";
    foreach my $joinkey (sort keys %{ $matches{$count} }) {
#       print "<font color=\"red\">$status{$joinkey}</font> ";	# add invalid flag to person search 2012 07 31
      print "<a href=\"lab_editor.cgi?curator_two=$curator_two&action=Search&display_or_edit=display&input_number_1=$joinkey\">$joinkey</a>\n";
      print "<font color=\"brown\">$std_name{$joinkey}</font> ";
      foreach my $table (keys %{ $hash{table} }) {
        next unless $hash{table}{$table}{$joinkey};
        my $data_match = join", ", @{ $hash{table}{$table}{$joinkey} }; 
        print "$table : <font color=\"green\">$data_match</font>\n"; }
      print "<br />\n";
    } # foreach my $joinkey (sort {$a<=>$b} keys %{ $matches{$count} })
  } # foreach my $count (reverse sort {$a<=>$b} keys %matches)
  &printFooter();
} # sub search

### End Search Section ###

### Person Editing Section ###

sub displayLab {
  my ($joinkey, $curator_two) = @_;
  (my $var, my $display_or_edit) = &getHtmlVar($query, "display_or_edit");
  print "<input type=\"hidden\" name=\"person_joinkey\" id=\"person_joinkey\" value=\"$joinkey\">";

  my %display_data;
  my $header_bgcolor = '#dddddd'; my $header_color = 'black';

  print "<table style=\"border-style: none;\" border=\"0\" >\n";
  my $entry_data = "<tr bgcolor='$header_bgcolor'><td>$joinkey</td><td colspan=6><div style=\"color:$header_color\">Person Information</div></td></tr>\n";

  my %pgdata;
  foreach my $table (@normal_tables) {
    $entry_data .= "<input type=\"hidden\" class=\"fields\" value=\"$table\" \/>\n";
    my $pg_table = 'lab_' . $table; 
    $result = $dbh->prepare( "SELECT * FROM $pg_table WHERE joinkey = '$joinkey' ORDER BY lab_order" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) {
      next unless ($row[2]);				# skip blank entries
      $pgdata{$table}{$row[1]}{highest_order} = $row[1];
      $pgdata{$table}{$row[1]}{data} = $row[2];
      $pgdata{$table}{$row[1]}{row_curator} = $row[3];
      $pgdata{$table}{$row[1]}{timestamp} = $row[4]; }
  } # foreach my $table (@normal_tables)

  my $is_valid = '';			# if person status is Invalid make red to show on toggle href switch  2012 07 30
  if ($pgdata{'status'}{1}{data}) { if ($pgdata{'status'}{1}{data} eq 'Invalid') { $is_valid = qq(<b style="color: red;font-size: 14pt">Invalid : </b>\n); } }

  my $which_page = 'displayLabEditor'; my $opp_display_or_edit = 'display';
  if ($display_or_edit eq 'display') { $which_page = 'displayLabDisplay'; $opp_display_or_edit = 'edit'; }
  print "<input type=\"hidden\" name=\"which_page\" id=\"which_page\" value=\"$which_page\">";
  my $toggle_url = "lab_editor.cgi?curator_two=$curator_two&action=Search&display_or_edit=$opp_display_or_edit&input_number_1=$joinkey";	# add link to lab_editor in display mode
  $entry_data .= "$is_valid Switch to <a href=\"$toggle_url\">$opp_display_or_edit</a>.<br />\n";

  foreach my $table (@normal_tables) {
    next if ( ($table eq 'middlename') || ($table eq 'lastname') || ($table eq 'aka_middlename') || ($table eq 'aka_lastname') || 
              ($table eq 'old_inst_date') || ($table eq 'old_email_date') || ($table eq 'usefulwebpage') );
    my $highest_order = 0;
#     if ($table eq 'status') { $entry_data .= "<tr bgcolor='$header_bgcolor'><td colspan=7><div style=\"color:$header_color\">Publication Information</div></td></tr>\n"; }

    foreach my $order (sort {$a<=>$b} keys %{ $pgdata{$table} }) {
      $entry_data .= &makeSingleNormal(\%pgdata, $display_or_edit, $joinkey, $order, $table);
      if ($order > $highest_order) { $highest_order = $order; }
    } # foreach my $order (sort {$a<=>$b} keys %{ $pgdata{$table} })

    if ($display_or_edit eq 'edit') {					# in edit mode, show extra fields
      if ($order_type{multi}{$table}) { if ($highest_order) { 
        if ($highest_order >= $min_rows{$table}) { $min_rows{$table} = $highest_order+1; } } }	# always make one more row than are for multi value tables
      while ($highest_order < $min_rows{$table}) {						# while there are less rows than should be
        $highest_order++; my $order = $highest_order;
        $pgdata{$table}{$highest_order}{highest_order} = $highest_order;
        $entry_data .= &makeSingleNormal(\%pgdata, $display_or_edit, $joinkey, $order, $table);
      } # while ($highest_order < $min_rows{$table})
    } # if ($display_or_edit eq 'edit')
  } # foreach my $table (@normal_tables)

  foreach my $table (@normal_tables) {
    my ($highest_order, @junk) = sort {$b<=>$a} keys %{ $pgdata{$table} };
    unless ($highest_order) { $highest_order = 1; }
    print "<input type=\"hidden\" id=\"type_input_$table\" value=\"$type_input{$table}\">\n";
    print "<input type=\"hidden\" id=\"highest_order_$table\" value=\"$highest_order\">\n";
  } # foreach my $table (@normal_tables)

  print "$entry_data\n";
  print "</table>\n";
} # sub displayLab

sub makeSingleNormal {
  my ($pgdata_ref, $display_or_edit, $joinkey, $order, $one_table) = @_;
  my %pgdata = %$pgdata_ref;
  my $td_width = '550';		# there's some weird auto-sizing of the field where it shrinks to nothing if the td doesn't have a size, so min size is 550
  my $input_size = '80';
  my $bgcolor = 'white';
  my ($one_data, $one_row_curator, $one_timestamp, $two_data, $two_row_curator, $two_timestamp) = ('', '', '', '', '', '');
  if ($pgdata{$one_table}{$order}{data}) { $one_data = $pgdata{$one_table}{$order}{data}; $bgcolor = $blue; }
  if ($pgdata{$one_table}{$order}{row_curator}) { $one_row_curator = $pgdata{$one_table}{$order}{row_curator}; }
  if ($pgdata{$one_table}{$order}{timestamp}) { $one_timestamp = $pgdata{$one_table}{$order}{timestamp}; $one_timestamp =~ s/\.[\d\+\-]+$//; $one_timestamp .= "<input type=\"hidden\" id=\"timestamp_${one_table}_${order}\" value=\"$one_timestamp\">"; }
  my $td_one_data = '';
  if ($display_or_edit eq 'edit') {
      ($td_one_data) = &makeInputField($one_data, $one_table, $joinkey, $order, '3', '1', '', $td_width, $input_size); }
    else {
      ($td_one_data) = &makeDisplayField($one_data, $one_table, $joinkey, $order, '3', '1', '', $td_width, $input_size); }
  if ($bgcolor eq 'white') { $order .= "<input type=\"hidden\" id=\"highest_${one_table}_order\" value=\"$order\">\n"; }	# have an id for the next highest order of the old tables for oldlab
  return "<tr bgcolor='$bgcolor'><td>$one_table</td><td>$order</td>$td_one_data<td style=\"width:12em\">&nbsp; $one_timestamp</td></tr>\n";
} # sub makeSingleNormal


sub makeDisplayField {
  my ($current_value, $table, $joinkey, $order, $colspan, $rowspan, $class, $td_width, $input_size) = @_;
  unless ($current_value) { $current_value = ''; }
  if ($table eq 'webpage') { $current_value = "<a href=\"$current_value\" target=\"new\">$current_value</a>"; }
  my $data = "<td width=\"$td_width\" class=\"$class\" rowspan=\"$rowspan\" colspan=\"$colspan\">$current_value</td>";
  return $data;
} # sub makeDisplayField

sub makeInputField {
  my ($current_value, $table, $joinkey, $order, $colspan, $rowspan, $class, $td_width, $input_size) = @_;
  unless ($current_value) { $current_value = ''; }
  my $freeForced = 'free';
  my $containerSpanId = "container${freeForced}${table}${order}AutoComplete";
  my $divAutocompleteId = "${freeForced}${table}${order}AutoComplete";
  my $inputId = "input_${table}_$order";
  my $divContainerId = "${freeForced}${table}${order}Container";
  my $data = "<td width=\"$td_width\" class=\"$class\" rowspan=\"$rowspan\" colspan=\"$colspan\">
  <span id=\"$containerSpanId\">
  <div id=\"$divAutocompleteId\" class=\"div-autocomplete\">
  <input id=\"$inputId\" name=\"$inputId\" size=\"$input_size\" value=\"$current_value\">
  <div id=\"$divContainerId\"></div></div></span>
  </td>";
#    <span id=\"container${freeForced}${table}AutoComplete\">
#    <div id=\"${freeForced}${table}AutoComplete\" class=\"div-autocomplete\">
#    <input id=\"input_$table\" name=\"input_$table\" size=\"$input_size\">
#    <div id=\"${freeForced}${table}Container\"></div></div></span>
  return $data;
} # sub makeInputField

### End Person Editing Section ###


sub populateCurators {
  my $result = $dbh->prepare( "SELECT * FROM two_standardname; " );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
    $curators{two}{$row[0]} = $row[2];
    $curators{std}{$row[2]} = $row[0]; } }

sub updateCurator {
  my ($joinkey) = @_;
  my $ip = $query->remote_host();
  my $result = $dbh->prepare( "SELECT * FROM two_curator_ip WHERE two_curator_ip = '$ip' AND joinkey = '$joinkey';" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  my @row = $result->fetchrow;
  unless ($row[0]) {
    $result = $dbh->do( "DELETE FROM two_curator_ip WHERE two_curator_ip = '$ip' ;" );
    $result = $dbh->do( "INSERT INTO two_curator_ip VALUES ('$joinkey', '$ip')" );
    print "IP $ip updated for $joinkey<br />\n"; } }


sub printHtmlHeader {
  print "Content-type: text/html\n\n";
  my $title = 'Lab Editor';
  my $header = '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"><HTML><HEAD>';
  $header .= "<title>$title</title>\n";

  $header .= '<link rel="stylesheet" href="https://tazendra.caltech.edu/~azurebrd/stylesheets/jex.css" />';
#   $header .= '<link rel="stylesheet" type="text/css" href="http://yui.yahooapis.com/2.7.0/build/fonts/fonts-min.css" />';
#   $header .= "<link rel=\"stylesheet\" type=\"text/css\" href=\"http://yui.yahooapis.com/2.7.0/build/autocomplete/assets/skins/sam/autocomplete.css\" />";
#   $header .= "<link rel=\"stylesheet\" type=\"text/css\" href=\"https://tazendra.caltech.edu/~azurebrd/javascript/yui/2.7.0/autocomplete.css\" />";
  $header .= "<link rel=\"stylesheet\" type=\"text/css\" href=\"../javascript/yui/2.7.0/autocomplete.css\" />";


  $header .= "<style type=\"text/css\">#forcedPersonAutoComplete { width:25em; padding-bottom:2em; } .div-autocomplete { padding-bottom:1.5em; }</style>";

  $header .= '
    <!-- always needed for yui -->
    <!--<script type="text/javascript" src="http://yui.yahooapis.com/2.7.0/build/yahoo-dom-event/yahoo-dom-event.js"></script>-->
    <!--<script type="text/javascript" src="https://tazendra.caltech.edu/~azurebrd/javascript/yui/2.7.0/yahoo-dom-event.js"></script>-->
    <script type="text/javascript" src="../javascript/yui/2.7.0/yahoo-dom-event.js"></script>

    <!-- for autocomplete calls -->
    <!--<script type="text/javascript" src="http://yui.yahooapis.com/2.7.0/build/datasource/datasource-min.js"></script>-->
    <!--<script type="text/javascript" src="https://tazendra.caltech.edu/~azurebrd/javascript/yui/2.7.0/datasource-min.js"></script>-->
    <script type="text/javascript" src="../javascript/yui/2.7.0/datasource-min.js"></script>

    <!-- OPTIONAL: Connection Manager (enables XHR for DataSource)	needed for Connect.asyncRequest -->
    <!--<script type="text/javascript" src="http://yui.yahooapis.com/2.7.0/build/connection/connection-min.js"></script> -->
    <!--<script type="text/javascript" src="https://tazendra.caltech.edu/~azurebrd/javascript/yui/2.7.0/connection-min.js"></script> -->
    <script type="text/javascript" src="../javascript/yui/2.7.0/connection-min.js"></script> 

    <!-- Drag and Drop source file --> 
    <!--<script src="http://yui.yahooapis.com/2.7.0/build/dragdrop/dragdrop-min.js" ></script>-->
    <!--<script src="https://tazendra.caltech.edu/~azurebrd/javascript/yui/2.7.0/dragdrop-min.js" ></script>-->
    <script type="text/javascript"  src="../javascript/yui/2.7.0/dragdrop-min.js" ></script>

    <!-- At least needed for drag and drop easing -->
    <!--<script type="text/javascript" src="http://yui.yahooapis.com/2.7.0/build/animation/animation-min.js"></script>-->
    <!--<script type="text/javascript" src="https://tazendra.caltech.edu/~azurebrd/javascript/yui/2.7.0/animation-min.js"></script>-->
    <script type="text/javascript" src="../javascript/yui/2.7.0/animation-min.js"></script>

    <!-- autocomplete js -->
    <!--<script type="text/javascript" src="http://yui.yahooapis.com/2.7.0/build/autocomplete/autocomplete-min.js"></script>-->
    <!--<script type="text/javascript" src="https://tazendra.caltech.edu/~azurebrd/javascript/yui/2.7.0/autocomplete-min.js"></script>-->
    <script type="text/javascript" src="../javascript/yui/2.7.0/autocomplete-min.js"></script>

    <!-- form-specific js put this last, since it depends on YUI above -->
    <script type="text/javascript" src="../javascript/lab_editor.js"></script>

  ';
  $header .= "</head>";
  $header .= '<body class="yui-skin-sam">';
  print $header;
} # printHtmlHeader

sub getCuratorFromForm {
  (my $var, my $curator_two) = &getHtmlVar($query, "curator_two");
  if ($curator_two) { &updateCurator($curator_two); } else { print "ERROR : No curator chosen, using two1<br />\n"; $curator_two = 'two1'; }
  print "<input type=\"hidden\" name=\"curator_two\" id=\"curator_two\" value=\"$curator_two\">";
  return $curator_two;
} # sub getCuratorFromForm


__END__
