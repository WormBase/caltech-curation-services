#!/usr/bin/perl -w

# Display Go Meeting Registration data.

# Re-created after Tazendra's Hard drive crash.  2005 02 07
 
use strict;
use CGI;
use Fcntl;
use Pg;
use Jex;

my $query = new CGI;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

&printHeader('GO Meeting Registration Display');
&display();
&printFooter();

sub display {
  my @all_vars = qw ( Reg_fee Diet Country PostalCode State City Street Institution Department URL FAX Phone Email Last_Name First_Name );

  my %theHash;

  foreach my $var (reverse @all_vars) {
    my $table = 'gom_' . lc($var);
    my $result = $conn->exec( "SELECT * FROM $table ORDER BY gom_timestamp;" );
    while (my @row=$result->fetchrow) { 
      $row[0] =~ s/gom//;	# take out gom to sort numerically	
      $row[0]--;		# subtract one because starts at 2
      $theHash{$table}{$row[0]} = $row[1];
    } # while (my @row=$result->fetchrow) 
  } # foreach my $var (reverse @all_vars)

  print "<TABLE border=1>\n";
  print "<TR><TD>order</TD>";
  foreach my $var (reverse @all_vars) { print "<TD>$var</TD>"; }
  print "</TR>";
  foreach my $person (reverse sort {$a<=>$b} keys %{ $theHash{gom_first_name} }) { 
    print "<TR>";
    print "<TD>$person</TD>";
    foreach my $var (reverse @all_vars) {
      my $table = 'gom_' . lc($var);
      unless ($theHash{$table}{$person}) { $theHash{$table}{$person} = '&nbsp;';
}
      print "<TD>$theHash{$table}{$person}</TD>";
    } # foreach my $var (reverse @all_vars)
    print "</TR>\n";
  } # foreach my $person (sort keys %{ $theHash{gom_first_name} }) 
  print "</TABLE>\n";
} # sub display


__END__

my $HTML_TEMPLATE_ROOT = "/home/postgres/public_html/cgi-bin/";

my @ace_tables = qw(ace_author ace_name ace_lab ace_oldlab ace_address ace_email ace_phone ace_fax);
my @wbg_tables = qw(wbg_title wbg_firstname wbg_middlename wbg_lastname wbg_suffix wbg_street wbg_city wbg_state wbg_post wbg_country wbg_mainphone wbg_labphone wbg_officephone wbg_fax wbg_email);
my @paper_tables = qw(pap_paper pap_title pap_journal pap_page pap_volume pap_year pap_inbook pap_contained pap_pmid pap_affiliation pap_type pap_contains);
# my @two_tables = qw(two_firstname two_middlename two_lastname two_street two_city two_state two_post two_country two_mainphone two_labphone two_officephone two_otherphone two_fax two_email two_old_email two_lab two_oldlab two_left_field two_unable_to_contact two_privacy two_aka_firstname two_aka_middlename two_aka_lastname two_apu_firstname two_apu_middlename two_apu_lastname two_webpage two_comment two_groups);
my @two_tables = qw(two_firstname two_middlename two_lastname two_standardname two_street two_city two_state two_post two_country two_institution two_mainphone two_labphone two_officephone two_otherphone two_fax two_email two_old_email two_pis two_lab two_oldlab two_left_field two_unable_to_contact two_privacy two_aka_firstname two_aka_middlename two_aka_lastname two_apu_firstname two_apu_middlename two_apu_lastname two_webpage two_wormbase_comment two_hide );
my @two_simpler = qw(two_comment two_groups two_contactdata);
my @two_complex = qw(two_lineage);

my $blue = '#00ffcc';			# redefine blue to a mom-friendly color
my $red = '#ff00cc';			# redefine red to a mom-friendly color

my $frontpage = 1;			# show the front page on first load

&printHeader('Two-Display');
&display();
&printFooter();

sub display {
  my $action;
  unless ($action = $query->param('action')) {
    $action = 'none';
    if ($frontpage) { &firstPage(); }
  } else { $frontpage = 0; }

  if ($action eq 'Number !') {		# display a range with 50 twos
    &pickNumber();
  } # if ($action eq 'Number !')

  if ($action eq 'Last !') {		# display a range with 50 twos
    &pickLast();
  } # if ($action eq 'Last !')

  if ($action eq 'First !') {		# display a range with 50 twos
    &pickFirst();
  } # if ($action eq 'First !')

  if ($action eq 'Lab !') { &pickLab(); }

  if ($action eq 'Old Lab !') { &pickOldLab(); }

  if ($action eq 'Email !') { &pickEmail(); }

  if ($action eq 'Old Email !') { &pickOldEmail(); }

} # sub display

sub pickOldEmail {
  my ($oop, $oldemail) = &getHtmlVar($query, 'oldemail');
  unless ($oldemail) { $oldemail = 'none'; }	# sometimes no lab or zero would cause a serverlog error on next line
  print "Old Email : $oldemail<P>\n";
  my %keys = ();
  my $result = $conn->exec( "SELECT joinkey FROM two_old_email WHERE two_old_email ~ '$oldemail' ;" );
#   while (my @row = $result->fetchrow) { $row[0] =~ s/two//g; &displayOneDataFromKey($row[0]); }
  while (my @row = $result->fetchrow) { $row[0] =~ s/two//g; $keys{$row[0]}++; }
  my $keys = join ", ", sort({$a <=> $b} keys %keys); 
  print "Person Numbers : $keys<P>\n";
  foreach (sort {$a <=> $b} keys %keys) { &displayOneDataFromKey($_); }
} # sub pickOldEmail

sub pickEmail {
  my ($oop, $email) = &getHtmlVar($query, 'email');
  unless ($email) { $email = 'none'; }	# sometimes no lab or zero would cause a serverlog error on next line
  print "Email : $email<P>\n";
  my %keys = ();
  my $result = $conn->exec( "SELECT joinkey FROM two_email WHERE two_email ~ '$email' ;" );
#   while (my @row = $result->fetchrow) { $row[0] =~ s/two//g; &displayOneDataFromKey($row[0]); }
  while (my @row = $result->fetchrow) { $row[0] =~ s/two//g; $keys{$row[0]}++; }
  my $keys = join ", ", sort({$a <=> $b} keys %keys); 
  print "Person Numbers : $keys<P>\n";
  foreach (sort {$a <=> $b} keys %keys) { &displayOneDataFromKey($_); }
} # sub pickEmail

sub pickOldLab {
  my ($oop, $oldlab) = &getHtmlVar($query, 'oldlab');
  unless ($oldlab) { $oldlab = 'PS'; }	# sometimes no lab or zero would cause a serverlog error on next line
  print "OldLab : $oldlab<P>\n";
  my %keys = ();
  my $result = $conn->exec( "SELECT joinkey FROM two_oldlab WHERE two_oldlab = '$oldlab' ;" );
#   while (my @row = $result->fetchrow) { $row[0] =~ s/two//g; &displayOneDataFromKey($row[0]); }
  while (my @row = $result->fetchrow) { $row[0] =~ s/two//g; $keys{$row[0]}++; }
  my $keys = join ", ", sort({$a <=> $b} keys %keys); 
  print "Person Numbers : $keys<P>\n";
  foreach (sort {$a <=> $b} keys %keys) { &displayOneDataFromKey($_); }
} # sub pickOldLab

sub pickLab {
  my ($oop, $lab) = &getHtmlVar($query, 'lab');
  unless ($lab) { $lab = 'PS'; }	# sometimes no lab or zero would cause a serverlog error on next line
  print "Lab : $lab<P>\n";
  my %keys = ();
  my $result = $conn->exec( "SELECT joinkey FROM two_lab WHERE two_lab = '$lab' ;" );
  while (my @row = $result->fetchrow) { $row[0] =~ s/two//g; $keys{$row[0]}++; }
  my $keys = join ", ", sort({$a <=> $b} keys %keys); 
  print "Person Numbers : $keys<P>\n";
  foreach (sort {$a <=> $b} keys %keys) { &displayOneDataFromKey($_); }
} # sub pickLab

sub pickNumber {
  my ($oop, $number) = &getHtmlVar($query, 'number');
  unless ($number) { $number = 1; }	# sometimes no number or zero would cause a serverlog error on next line
  print "NUMBER : $number<P>\n";
  &displayOneDataFromKey($number);
} # sub pickNumber

sub pickLast {
  my ($oop, $last) = &getHtmlVar($query, 'last_name');
  my ($oop2, $exact_or_sub) = &getHtmlVar($query, 'exact_or_sub');
  my $result;
  my %lastnames;
  print "LAST : $last<P>\n";

  if ($exact_or_sub eq 'exact') {
    $result = $conn->exec( "SELECT joinkey FROM two_lastname WHERE two_lastname = '$last' ;" );
    while (my @row = $result->fetchrow) { $row[0] =~ s/two//g; $lastnames{$row[0]}++; }
    $result = $conn->exec( "SELECT joinkey FROM two_aka_lastname WHERE two_aka_lastname = '$last' ;" );
    while (my @row = $result->fetchrow) { $row[0] =~ s/two//g; $lastnames{$row[0]}++; }
    $result = $conn->exec( "SELECT joinkey FROM two_apu_lastname WHERE two_apu_lastname = '$last' ;" );
    while (my @row = $result->fetchrow) { $row[0] =~ s/two//g; $lastnames{$row[0]}++; }
  } elsif ($exact_or_sub eq 'sub') { 
    $result = $conn->exec( "SELECT joinkey FROM two_lastname WHERE two_lastname ~ '$last' ;" );
    while (my @row = $result->fetchrow) { $row[0] =~ s/two//g; $lastnames{$row[0]}++; }
    $result = $conn->exec( "SELECT joinkey FROM two_aka_lastname WHERE two_aka_lastname ~ '$last' ;" );
    while (my @row = $result->fetchrow) { $row[0] =~ s/two//g; $lastnames{$row[0]}++; }
    $result = $conn->exec( "SELECT joinkey FROM two_apu_lastname WHERE two_apu_lastname ~ '$last' ;" );
    while (my @row = $result->fetchrow) { $row[0] =~ s/two//g; $lastnames{$row[0]}++; }
  } else { print "ERROR : Must select Exact or Substring<P>\n"; }

  my $twos = join ', ', (sort { $a <=> $b } keys %lastnames);
  print "TWOS : $twos<P>\n";
  foreach my $two (sort { $a <=> $b} keys %lastnames) { &displayOneDataFromKey($two); }
  print "LAST : $last<P>\n";
} # sub pickLast

sub pickFirst {
  my ($oop, $first) = &getHtmlVar($query, 'first_name');
  my ($oop2, $exact_or_sub) = &getHtmlVar($query, 'exact_or_sub');
  my $result;
  my %firstnames;
  print "FIRST : $first<P>\n";

  if ($exact_or_sub eq 'exact') {
    $result = $conn->exec( "SELECT joinkey FROM two_firstname WHERE two_firstname = '$first' ;" );
    while (my @row = $result->fetchrow) { $row[0] =~ s/two//g; $firstnames{$row[0]}++; }
    $result = $conn->exec( "SELECT joinkey FROM two_aka_firstname WHERE two_aka_firstname = '$first' ;" );
    while (my @row = $result->fetchrow) { $row[0] =~ s/two//g; $firstnames{$row[0]}++; }
    $result = $conn->exec( "SELECT joinkey FROM two_apu_firstname WHERE two_apu_firstname = '$first' ;" );
    while (my @row = $result->fetchrow) { $row[0] =~ s/two//g; $firstnames{$row[0]}++; }
  } elsif ($exact_or_sub eq 'sub') { 
    $result = $conn->exec( "SELECT joinkey FROM two_firstname WHERE two_firstname ~ '$first' ;" );
    while (my @row = $result->fetchrow) { $row[0] =~ s/two//g; $firstnames{$row[0]}++; }
    $result = $conn->exec( "SELECT joinkey FROM two_aka_firstname WHERE two_aka_firstname ~ '$first' ;" );
    while (my @row = $result->fetchrow) { $row[0] =~ s/two//g; $firstnames{$row[0]}++; }
    $result = $conn->exec( "SELECT joinkey FROM two_apu_firstname WHERE two_apu_firstname ~ '$first' ;" );
    while (my @row = $result->fetchrow) { $row[0] =~ s/two//g; $firstnames{$row[0]}++; }
  } else { print "ERROR : Must select Exact or Substring<P>\n"; }

  my $twos = join ', ', (sort { $a <=> $b } keys %firstnames);
  print "TWOS : $twos<P>\n";
  foreach my $two (sort { $a <=> $b} keys %firstnames) { &displayOneDataFromKey($two); }
  print "FIRST : $first<P>\n";
} # sub pickFirst

sub firstPage {
  my $date = &getDate();
  print "Value : $date<BR>\n";


  print "<FORM NAME='form1' METHOD=\"POST\" ACTION=\"http://tazendra.caltech.edu/~postgres/cgi-bin/cecilia/two_display.cgi\">\n";
  print "<TABLE border=1 cellspacing=5>\n";
  print "<TR><TD>Number : <TD><INPUT SIZE=40 NAME=\"number\" onChange=\"checkifempty()\"></TD>\n";
  print "<TD><INPUT TYPE=submit NAME=action VALUE=\"Number !\"></TD></TR>\n";
  print "<TR><TD>Last Name : <TD><INPUT SIZE=40 NAME=\"last_name\" onChange=\"checkifempty()\"></TD>\n";
  print "<TD><INPUT TYPE=submit NAME=action VALUE=\"Last !\"></TD></TR>\n";
  print "<TR><TD>First Name : <TD><INPUT SIZE=40 NAME=\"first_name\" onChange=\"checkifempty()\"></TD>\n";
  print "<TD><INPUT TYPE=submit NAME=action VALUE=\"First !\"></TD></TR>\n";
  print "<TR><TD>Exact</TD><TD><INPUT NAME=\"exact_or_sub\" TYPE=\"radio\" VALUE=\"exact\"></TD></TR>\n";
  print "<TR><TD>Substring</TD><TD><INPUT NAME=\"exact_or_sub\" TYPE=\"radio\" VALUE=\"sub\" CHECKED></TD></TR>\n";
  print "<TR><TD>Lab : <TD><INPUT SIZE=40 NAME=\"lab\" onChange=\"checkifempty()\"></TD>\n";
  print "<TD><INPUT TYPE=submit NAME=action VALUE=\"Lab !\"></TD></TR>\n";
  print "<TR><TD>Old Lab : <TD><INPUT SIZE=40 NAME=\"oldlab\" onChange=\"checkifempty()\"></TD>\n";
  print "<TD><INPUT TYPE=submit NAME=action VALUE=\"Old Lab !\"></TD></TR>\n";
  print "<TR><TD>Email : <TD><INPUT SIZE=40 NAME=\"email\" onChange=\"checkifempty()\"></TD>\n";
  print "<TD><INPUT TYPE=submit NAME=action VALUE=\"Email !\"></TD></TR>\n";
  print "<TR><TD>Old Email : <TD><INPUT SIZE=40 NAME=\"oldemail\" onChange=\"checkifempty()\"></TD>\n";
  print "<TD><INPUT TYPE=submit NAME=action VALUE=\"Old Email !\"></TD></TR>\n";
  print "</FORM>\n";
  print "</TABLE>\n";

  print <<"EndOfText";
    <script language="JavaScript1.1">
    function checkifempty(){
      if (document.form1.number.value=='') { document.form1.action[0].disabled=true } 
        else { document.form1.action[0].disabled=false }
      if (document.form1.last_name.value=='') { document.form1.action[1].disabled=true } 
        else { document.form1.action[1].disabled=false }
      if (document.form1.first_name.value=='') { document.form1.action[2].disabled=true } 
        else { document.form1.action[2].disabled=false }
      if (document.form1.lab.value=='') { document.form1.action[3].disabled=true } 
        else { document.form1.action[3].disabled=false }
      if (document.form1.oldlab.value=='') { document.form1.action[4].disabled=true } 
        else { document.form1.action[4].disabled=false }
      if (document.form1.email.value=='') { document.form1.action[5].disabled=true } 
        else { document.form1.action[5].disabled=false }
      if (document.form1.oldemail.value=='') { document.form1.action[6].disabled=true } 
        else { document.form1.action[6].disabled=false }
    }
    checkifempty();
    </script>
EndOfText


} # sub firstPage

### display from key ###

sub displayOneDataFromKey {
  my ($two_key) = 'two' . $_[0];
  print "<TABLE border=1 cellspacing=2>\n";
  my $counter = 0;
  foreach my $two_table (@two_tables) {
    my $result = $conn->exec( "SELECT * FROM $two_table WHERE joinkey = '$two_key' ORDER BY two_order;" );
    while (my @row = $result->fetchrow) {
      if ($row[1]) {
        print "<TR bgcolor='$blue'>\n  <TD>$two_table</TD>\n";
        print "  <TD>$row[0]</TD>\n"; 
        print "  <TD>$row[1]</TD>\n";
        print "  <TD>$row[2]</TD>\n";
        print "  <TD>$row[3]</TD>\n";
        print "</TR>\n";
      } # if ($row[1])
    } # while (my @row = $result->fetchrow)
  } # foreach my $two_table (@two_tables)

  foreach my $two_simpler (@two_simpler) {
    my $result = $conn->exec( "SELECT * FROM $two_simpler WHERE joinkey = '$two_key';" );
    while (my @row = $result->fetchrow) {
      if ($row[1]) {
        print "<TR bgcolor='$blue'>\n  <TD>$two_simpler</TD>\n";
        print "  <TD>$row[0]</TD>\n"; 
        print "  <TD>&nbsp;</TD>\n"; 
        print "  <TD>$row[1]</TD>\n";
        print "  <TD>"; if ($row[2]) { print $row[2]; } print "</TD>\n";
        print "</TR>\n";
      } # if ($row[1])
    } # while (my @row = $result->fetchrow)
  } # foreach my $two_simpler (@two_simpler)
  print "</TABLE><BR><BR>\n";

  print "<TABLE border=1 cellspacing=2>\n";
  foreach my $two_complex (@two_complex) {
    my $result = $conn->exec( "SELECT * FROM $two_complex WHERE joinkey = '$two_key';" );
    while (my @row = $result->fetchrow) {
      if ($row[1]) {
        print "<TR bgcolor='$blue'>\n  <TD>$two_complex</TD>\n";
        print "  <TD>$row[0]</TD>\n"; 
        print "  <TD>$row[2]</TD>\n"; 
        print "  <TD>$row[3]</TD>\n"; 
        print "  <TD>$row[4]</TD>\n";
        if ($row[5]) { print "  <TD>$row[5]</TD>\n"; } else { print "  <TD>&nbsp;</TD>\n"; }
        if ($row[6]) { print "  <TD>$row[6]</TD>\n"; } else { print "  <TD>&nbsp;</TD>\n"; }
        if ($row[7]) { print "  <TD>$row[7]</TD>\n"; } else { print "  <TD>&nbsp;</TD>\n"; }
        print "  <TD>$row[8]</TD>\n";
        print "</TR>\n";
      } # if ($row[1])
    } # while (my @row = $result->fetchrow)
  } # foreach my $two_simpler (@two_simpler)
  print "</TABLE><BR><BR>\n";

} # sub displayOneDataFromKey

sub displayAceDataFromKey {             # show all ace data from a given key in multiline table
  my ($ace_key) = @_;
  print "<TABLE border=1 cellspacing=2>\n";
  foreach my $ace_table (@ace_tables) { # show the data
    my $result = $conn->exec( "SELECT * FROM $ace_table WHERE joinkey = '$ace_key';" );
    my @row;
    while (@row = $result->fetchrow) {
      if ($row[1]) {
        print "<TR><TD>$ace_table</TD>";
        foreach (@row) { print "<TD>$_</TD>"; }
        print "</TR>\n";
      } # if ($row[1])
    } # while (@row = $result->fetchrow)
  } # foreach (@ace_tables)
  print "</TABLE><BR><BR>\n";
} # sub displayAceDataFromKey

sub displayWbgDataFromKey {             # show all wbg data from a given key in multiline table
  my ($wbg_key) = @_;
  print "<TABLE border=1 cellspacing=2>\n";
  foreach my $wbg_table (@wbg_tables) { # go through each table for the key
    my $result = $conn->exec( "SELECT * FROM $wbg_table WHERE joinkey = '$wbg_key';" );
    my @row;
    while (@row = $result->fetchrow) {
      if ($row[1]) {
        print "<TR><TD>$wbg_table</TD>";
        foreach (@row) { print "<TD>$_</TD>"; }
        print "</TR>\n";
      } # if ($row[1])
    } # while (@row = $result->fetchrow)
  } # foreach my $wbg_table (@wbg_tables)
  print "</TABLE><BR><BR>\n";
} # sub displayWbgDataFromKey

### display from key ###

