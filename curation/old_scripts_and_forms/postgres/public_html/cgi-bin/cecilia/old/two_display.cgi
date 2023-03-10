#!/usr/bin/perl -w

# Display two data based on last name or number  
# 2003 01 03
#
# Added two_wormbase_comment to display.  2003 02 28
#
# Added two_standardname and two_pis to display.  2003 03 24
#
# Added a bit of javascript, too annoying ?  2003 04 04
#
# Added a display to show all Persons by Lab designation.  2003 05 06
#
# Added a display to show all Persons by Old Lab designation.  2003 05 08
# Added a list of person numbers before displaying form Lab and Old Lab.  2003 05 08
#
# Added table two_hide to flag people that shouldn't be up on WormBase. 2003 05 13
#
# Added email search.  2003 07 31
#
# Added old_email search.  2004 05 18
#
# Added Country, City, Street, Institution for Cecilia.  2006 01 12
#
# Added exact match of lastname with substring search of first initial.  2006 02 14
#
# Added two_status, two_mergedinto, two_acqmerge.  2006 11 03
#
# Show Invalid in Red at the top.  2007 03 13
#
# Added PI search.  2007 04 27
#
# Parse down timestamps to second.  2008 05 21
#
# Add display of people who are possible but not verified.  2008 07 15
#
# Added two_old_institution, fixed substring search to work on all.  2008 07 16
#
# Converted from Pg.pm to DBI.pm  2009 04 17
#
# Got rid of annoying form disabling.  2009 09 03
# 
# Switched from wpa to pap tables, although they're not live yet.  2010 06 24

 
use strict;
use CGI;
use Fcntl;
# use Pg;
use DBI;
use Jex;

my $query = new CGI;

# my $conn = Pg::connectdb("dbname=testdb");
# die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "");
if ( !defined $dbh ) { die "Cannot connect to database!\n"; }


my $HTML_TEMPLATE_ROOT = "/home/postgres/public_html/cgi-bin/";

my @ace_tables = qw(ace_author ace_name ace_lab ace_oldlab ace_address ace_email ace_phone ace_fax);
my @wbg_tables = qw(wbg_title wbg_firstname wbg_middlename wbg_lastname wbg_suffix wbg_street wbg_city wbg_state wbg_post wbg_country wbg_mainphone wbg_labphone wbg_officephone wbg_fax wbg_email);
my @paper_tables = qw(pap_paper pap_title pap_journal pap_page pap_volume pap_year pap_inbook pap_contained pap_pmid pap_affiliation pap_type pap_contains);
# my @two_tables = qw( two_firstname two_middlename two_lastname two_street two_city two_state two_post two_country two_mainphone two_labphone two_officephone two_otherphone two_fax two_email two_old_email two_lab two_oldlab two_left_field two_unable_to_contact two_privacy two_aka_firstname two_aka_middlename two_aka_lastname two_apu_firstname two_apu_middlename two_apu_lastname two_webpage two_comment two_groups );
my @two_tables = qw( two_firstname two_middlename two_lastname two_standardname two_street two_city two_state two_post two_country two_institution two_old_institution two_mainphone two_labphone two_officephone two_otherphone two_fax two_email two_old_email two_pis two_lab two_oldlab two_left_field two_unable_to_contact two_privacy two_aka_firstname two_aka_middlename two_aka_lastname two_apu_firstname two_apu_middlename two_apu_lastname two_webpage two_wormbase_comment two_hide two_status two_mergedinto two_acqmerge );
my @two_simpler = qw( two_comment two_groups two_contactdata );
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

  if ($action eq 'Number !') { &pickNumber(); } 
  elsif ($action eq 'Last !') { &pickLast(); }
  elsif ($action eq 'First !') { &pickFirst(); }
  elsif ($action eq 'Last & First Initial !') { &pickLastFI(); }
  elsif ($action eq 'PI !') { &pickPI(); }
  elsif ($action eq 'Lab !') { &pickLab(); }
  elsif ($action eq 'Old Lab !') { &pickOldLab(); }
  elsif ($action eq 'Email !') { &pickEmail(); }
  elsif ($action eq 'Old Email !') { &pickOldEmail(); }
  elsif ($action eq 'Country !') { &pickCountry(); }
  elsif ($action eq 'City !') { &pickCity(); }
  elsif ($action eq 'Street !') { &pickStreet(); }
  elsif ($action eq 'Institution !') { &pickInstitution(); }
  elsif ($action eq 'Old Institution !') { &pickOldInstitution(); }
#   elsif ($action eq 'Unverified !') { &pickUnverified(); }	# Cecilia wasn't using this  2010 06 24
} # sub display

# Cecilia wasn't using this  2010 06 24
# sub pickUnverified {
#   my %possible; my %verified; my %aid_paper; my %unverified; my %two_email; my %valid_pap;
# #   my $result = $conn->exec( "SELECT * FROM wpa ORDER BY wpa_timestamp; ");
#   my $result = $dbh->prepare( "SELECT * FROM wpa ORDER BY wpa_timestamp; ");
#   $result->execute;
#   while (my @row = $result->fetchrow) {
#     if ($row[3] eq "valid") { $valid_pap{$row[0]}++ ; }
#       else { delete $valid_pap{$row[0]}; } }
# #   $result = $conn->exec( "SELECT * FROM wpa_author_possible ORDER BY wpa_timestamp; ");
#   $result = $dbh->prepare( "SELECT * FROM wpa_author_possible ORDER BY wpa_timestamp; ");
#   $result->execute;
#   while (my @row = $result->fetchrow) {
#     if ($row[3] eq "valid") { $possible{$row[0]}{$row[2]} = $row[1]; }	# aid, wpa_join
#       else { delete $possible{$row[0]}{$row[2]}; } }
# #   $result = $conn->exec( "SELECT * FROM wpa_author_verified ORDER BY wpa_timestamp; ");
#   $result = $dbh->prepare( "SELECT * FROM wpa_author_verified ORDER BY wpa_timestamp; ");
#   $result->execute;
#   while (my @row = $result->fetchrow) {
#     if ($row[3] eq "valid") { $verified{$row[0]}{$row[2]}++; }
#       else { delete $verified{$row[0]}{$row[2]}; } }
# #   $result = $conn->exec( "SELECT * FROM wpa_author ORDER BY wpa_timestamp; ");
#   $result = $dbh->prepare( "SELECT * FROM wpa_author ORDER BY wpa_timestamp; ");
#   $result->execute;
#   while (my @row = $result->fetchrow) {
#     if ($row[3] eq "valid") { $aid_paper{$row[1]} = $row[0]; }
#       else { delete $aid_paper{$row[0]}{$row[2]}; } }
# #   $result = $conn->exec( "SELECT * FROM two_email WHERE two_order = '1' AND two_email IS NOT NULL ORDER BY two_timestamp; ");
#   $result = $dbh->prepare( "SELECT * FROM two_email WHERE two_order = '1' AND two_email IS NOT NULL ORDER BY two_timestamp; ");
#   $result->execute;
#   while (my @row = $result->fetchrow) { $two_email{$row[0]} = $row[2]; }
#   foreach my $aid (sort keys %possible) { 
#     foreach my $wpa_join (sort keys %{ $possible{$aid} }) { 
#       unless ($verified{$aid}{$wpa_join}) { 
#         my $two = $possible{$aid}{$wpa_join};
#         my $paper = $aid_paper{$aid};
#         next unless ($valid_pap{$paper});
#         my $has_email = 'noemail';
#         my $email = '';
#         if ($two_email{$two}) { $has_email = 'hasemail'; $email = $two_email{$two}; }
#         push @{ $unverified{$has_email}{$two}{paper} }, $paper; 
#         $unverified{$has_email}{$two}{count}++; } } }
#   print "<FONT COLOR=green>green</FONT> have emails, <FONT COLOR=red>red</FONT>
# do not : <BR><BR>\n";
#   foreach my $has_email ( sort keys %unverified ) {
#     foreach my $two ( sort { $unverified{$has_email}{$b}{count} <=> $unverified{$has_email}{$a}{count} } keys %{ $unverified{$has_email} } ) {
#       my $twokey = $two; $twokey =~ s/two//g;
#       my $color = 'red';
#       if ($has_email eq 'hasemail') { $color = 'green'; } else { $color = 'red'; }
#       print "<FONT COLOR=$color>($unverified{$has_email}{$two}{count})</FONT> "; 
#       print "<A HREF=\"http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/confirm_paper.cgi?action=Pick+%21&two_num=$twokey\" TARGET=new>WBPerson$twokey</A> &nbsp; : ";
#       foreach my $paper (@{ $unverified{$has_email}{$two}{paper} }) {
#         print "<A HREF=\"http://tazendra.caltech.edu/~postgres/cgi-bin/wbpaper_display.cgi?action=Number+%21&number=$paper\" TARGET=new>$paper</A>\n"; }
#       print "<BR>\n";
#   } }
# } # sub pickUnverified

sub pickOldInstitution {
  my ($oop, $institution) = &getHtmlVar($query, 'old_institution');
  my ($oop2, $exact_or_sub) = &getHtmlVar($query, 'exact_or_sub');
  if ($exact_or_sub eq 'exact') { $exact_or_sub = '='; } else { $exact_or_sub = '~'; }
  unless ($institution) { $institution = 'Caltech'; }	# sometimes no institution or zero would cause a serverlog error on next line
  print "Old Institution : $institution<P>\n";
  my %keys = ();
#   my $result = $conn->exec( "SELECT joinkey FROM two_old_institution WHERE two_old_institution $exact_or_sub '$institution' ;" );
  my $result = $dbh->prepare( "SELECT joinkey FROM two_old_institution WHERE two_old_institution $exact_or_sub '$institution' ;" );
  $result->execute;
  while (my @row = $result->fetchrow) { $row[0] =~ s/two//g; $keys{$row[0]}++; }
  my $keys = join ", ", sort({$a <=> $b} keys %keys); 
  print "Person Numbers : $keys<P>\n";
  foreach (sort {$a <=> $b} keys %keys) { &displayOneDataFromKey($_); }
} # sub pickOldInstitution

sub pickInstitution {
  my ($oop, $institution) = &getHtmlVar($query, 'institution');
  my ($oop2, $exact_or_sub) = &getHtmlVar($query, 'exact_or_sub');
  if ($exact_or_sub eq 'exact') { $exact_or_sub = '='; } else { $exact_or_sub = '~'; }
  unless ($institution) { $institution = 'Caltech'; }	# sometimes no institution or zero would cause a serverlog error on next line
  print "Institution : $institution<P>\n";
  my %keys = ();
#   my $result = $conn->exec( "SELECT joinkey FROM two_institution WHERE two_institution $exact_or_sub '$institution' ;" );
  my $result = $dbh->prepare( "SELECT joinkey FROM two_institution WHERE two_institution $exact_or_sub '$institution' ;" );
  $result->execute;
  while (my @row = $result->fetchrow) { $row[0] =~ s/two//g; $keys{$row[0]}++; }
  my $keys = join ", ", sort({$a <=> $b} keys %keys); 
  print "Person Numbers : $keys<P>\n";
  foreach (sort {$a <=> $b} keys %keys) { &displayOneDataFromKey($_); }
} # sub pickInstitution

sub pickStreet {
  my ($oop, $street) = &getHtmlVar($query, 'street');
  my ($oop2, $exact_or_sub) = &getHtmlVar($query, 'exact_or_sub');
  if ($exact_or_sub eq 'exact') { $exact_or_sub = '='; } else { $exact_or_sub = '~'; }
  unless ($street) { $street = 'Avenue'; }	# sometimes no street or zero would cause a serverlog error on next line
  print "Street : $street<P>\n";
  my %keys = ();
#   my $result = $conn->exec( "SELECT joinkey FROM two_street WHERE two_street $exact_or_sub '$street' ;" );
  my $result = $dbh->prepare( "SELECT joinkey FROM two_street WHERE two_street $exact_or_sub '$street' ;" );
  $result->execute;
  while (my @row = $result->fetchrow) { $row[0] =~ s/two//g; $keys{$row[0]}++; }
  my $keys = join ", ", sort({$a <=> $b} keys %keys); 
  print "Person Numbers : $keys<P>\n";
  foreach (sort {$a <=> $b} keys %keys) { &displayOneDataFromKey($_); }
} # sub pickStreet

sub pickCity {
  my ($oop, $city) = &getHtmlVar($query, 'city');
  my ($oop2, $exact_or_sub) = &getHtmlVar($query, 'exact_or_sub');
  if ($exact_or_sub eq 'exact') { $exact_or_sub = '='; } else { $exact_or_sub = '~'; }
  unless ($city) { $city = 'Pasadena'; }	# sometimes no city or zero would cause a serverlog error on next line
  print "City : $city<P>\n";
  my %keys = ();
#   my $result = $conn->exec( "SELECT joinkey FROM two_city WHERE two_city $exact_or_sub '$city' ;" );
  my $result = $dbh->prepare( "SELECT joinkey FROM two_city WHERE two_city $exact_or_sub '$city' ;" );
  $result->execute;
  while (my @row = $result->fetchrow) { $row[0] =~ s/two//g; $keys{$row[0]}++; }
  my $keys = join ", ", sort({$a <=> $b} keys %keys); 
  print "Person Numbers : $keys<P>\n";
  foreach (sort {$a <=> $b} keys %keys) { &displayOneDataFromKey($_); }
} # sub pickCity

sub pickCountry {
  my ($oop, $country) = &getHtmlVar($query, 'country');
  my ($oop2, $exact_or_sub) = &getHtmlVar($query, 'exact_or_sub');
  if ($exact_or_sub eq 'exact') { $exact_or_sub = '='; } else { $exact_or_sub = '~'; }
  unless ($country) { $country = 'USA'; }	# sometimes no country or zero would cause a serverlog error on next line
  print "Country : $country<P>\n";
  my %keys = ();
#   my $result = $conn->exec( "SELECT joinkey FROM two_country WHERE two_country $exact_or_sub '$country' ;" );
  my $result = $dbh->prepare( "SELECT joinkey FROM two_country WHERE two_country $exact_or_sub '$country' ;" );
  $result->execute;
  while (my @row = $result->fetchrow) { $row[0] =~ s/two//g; $keys{$row[0]}++; }
  my $keys = join ", ", sort({$a <=> $b} keys %keys); 
  print "Person Numbers : $keys<P>\n";
  foreach (sort {$a <=> $b} keys %keys) { &displayOneDataFromKey($_); }
} # sub pickCountry

sub pickOldEmail {
  my ($oop, $oldemail) = &getHtmlVar($query, 'oldemail');
  my ($oop2, $exact_or_sub) = &getHtmlVar($query, 'exact_or_sub');
  if ($exact_or_sub eq 'exact') { $exact_or_sub = '='; } else { $exact_or_sub = '~'; }
  unless ($oldemail) { $oldemail = 'none'; }	# sometimes no lab or zero would cause a serverlog error on next line
  print "Old Email : $oldemail<P>\n";
  my %keys = ();
#   my $result = $conn->exec( "SELECT joinkey FROM two_old_email WHERE two_old_email $exact_or_sub '$oldemail' ;" );
  my $result = $dbh->prepare( "SELECT joinkey FROM two_old_email WHERE two_old_email $exact_or_sub '$oldemail' ;" );
  $result->execute;
#   while (my @row = $result->fetchrow) { $row[0] =~ s/two//g; &displayOneDataFromKey($row[0]); }
  while (my @row = $result->fetchrow) { $row[0] =~ s/two//g; $keys{$row[0]}++; }
  my $keys = join ", ", sort({$a <=> $b} keys %keys); 
  print "Person Numbers : $keys<P>\n";
  foreach (sort {$a <=> $b} keys %keys) { &displayOneDataFromKey($_); }
} # sub pickOldEmail

sub pickEmail {
  my ($oop, $email) = &getHtmlVar($query, 'email');
  my ($oop2, $exact_or_sub) = &getHtmlVar($query, 'exact_or_sub');
  if ($exact_or_sub eq 'exact') { $exact_or_sub = '='; } else { $exact_or_sub = '~'; }
  unless ($email) { $email = 'none'; }	# sometimes no lab or zero would cause a serverlog error on next line
  print "Email : $email<P>\n";
  my %keys = ();
#   my $result = $conn->exec( "SELECT joinkey FROM two_email WHERE two_email $exact_or_sub '$email' ;" );
  my $result = $dbh->prepare( "SELECT joinkey FROM two_email WHERE two_email $exact_or_sub '$email' ;" );
  $result->execute;
#   while (my @row = $result->fetchrow) { $row[0] =~ s/two//g; &displayOneDataFromKey($row[0]); }
  while (my @row = $result->fetchrow) { $row[0] =~ s/two//g; $keys{$row[0]}++; }
  my $keys = join ", ", sort({$a <=> $b} keys %keys); 
  print "Person Numbers : $keys<P>\n";
  foreach (sort {$a <=> $b} keys %keys) { &displayOneDataFromKey($_); }
} # sub pickEmail

sub pickOldLab {
  my ($oop, $oldlab) = &getHtmlVar($query, 'oldlab');
  my ($oop2, $exact_or_sub) = &getHtmlVar($query, 'exact_or_sub');
  if ($exact_or_sub eq 'exact') { $exact_or_sub = '='; } else { $exact_or_sub = '~'; }
  unless ($oldlab) { $oldlab = 'PS'; }	# sometimes no lab or zero would cause a serverlog error on next line
  print "OldLab : $oldlab<P>\n";
  my %keys = ();
#   my $result = $conn->exec( "SELECT joinkey FROM two_oldlab WHERE two_oldlab $exact_or_sub '$oldlab' ;" );
  my $result = $dbh->prepare( "SELECT joinkey FROM two_oldlab WHERE two_oldlab $exact_or_sub '$oldlab' ;" );
  $result->execute;
#   while (my @row = $result->fetchrow) { $row[0] =~ s/two//g; &displayOneDataFromKey($row[0]); }
  while (my @row = $result->fetchrow) { $row[0] =~ s/two//g; $keys{$row[0]}++; }
  my $keys = join ", ", sort({$a <=> $b} keys %keys); 
  print "Person Numbers : $keys<P>\n";
  foreach (sort {$a <=> $b} keys %keys) { &displayOneDataFromKey($_); }
} # sub pickOldLab

sub pickLab {
  my ($oop, $lab) = &getHtmlVar($query, 'lab');
  my ($oop2, $exact_or_sub) = &getHtmlVar($query, 'exact_or_sub');
  if ($exact_or_sub eq 'exact') { $exact_or_sub = '='; } else { $exact_or_sub = '~'; }
  unless ($lab) { $lab = 'PS'; }	# sometimes no lab or zero would cause a serverlog error on next line
  print "Lab : $lab<P>\n";
  my %keys = ();
#   my $result = $conn->exec( "SELECT joinkey FROM two_lab WHERE two_lab $exact_or_sub '$lab' ;" );
  my $result = $dbh->prepare( "SELECT joinkey FROM two_lab WHERE two_lab $exact_or_sub '$lab' ;" );
  $result->execute;
  while (my @row = $result->fetchrow) { $row[0] =~ s/two//g; $keys{$row[0]}++; }
  my $keys = join ", ", sort({$a <=> $b} keys %keys); 
  print "Person Numbers : $keys<P>\n";
  foreach (sort {$a <=> $b} keys %keys) { &displayOneDataFromKey($_); }
} # sub pickLab

sub pickPI {
  my ($oop, $pi) = &getHtmlVar($query, 'pi');
  my ($oop2, $exact_or_sub) = &getHtmlVar($query, 'exact_or_sub');
  if ($exact_or_sub eq 'exact') { $exact_or_sub = '='; } else { $exact_or_sub = '~'; }
  unless ($pi) { $pi = 'PS'; }	# sometimes no pi or zero would cause a serverlog error on next line
  print "PI : $pi<P>\n";
  my %keys = ();
#   my $result = $conn->exec( "SELECT joinkey FROM two_pis WHERE two_pis $exact_or_sub '$pi' ;" );
  my $result = $dbh->prepare( "SELECT joinkey FROM two_pis WHERE two_pis $exact_or_sub '$pi' ;" );
  $result->execute;
  while (my @row = $result->fetchrow) { $row[0] =~ s/two//g; $keys{$row[0]}++; }
  my $keys = join ", ", sort({$a <=> $b} keys %keys); 
  print "Person Numbers : $keys<P>\n";
  foreach (sort {$a <=> $b} keys %keys) { &displayOneDataFromKey($_); }
} # sub pickPI

sub pickNumber {
  my ($oop, $number) = &getHtmlVar($query, 'number');
  unless ($number) { $number = 1; }	# sometimes no number or zero would cause a serverlog error on next line
  if ($number =~ m/two(\d+)/) { $number = $1; }
  print "NUMBER : $number<P>\n";
  &displayOneDataFromKey($number);
} # sub pickNumber

sub pickLastFI {		# search for exact match on last name and substring search on first initial   2006 02 14
  my ($oop, $last) = &getHtmlVar($query, 'last_name');
  ($oop, my $firstinit) = &getHtmlVar($query, 'first_init');
  my $result;
  my %lastnames;
  print "LAST : $last<BR>FIRST INITIAL : $firstinit<BR>\n";

    # search combination of last, first, aka_last, aka_first
#   $result = $conn->exec( "SELECT two_lastname.joinkey FROM two_lastname, two_firstname WHERE two_lastname.joinkey = two_firstname.joinkey AND two_lastname = '$last' AND two_firstname ~ '^$firstinit';" );
  $result = $dbh->prepare( "SELECT two_lastname.joinkey FROM two_lastname, two_firstname WHERE two_lastname.joinkey = two_firstname.joinkey AND two_lastname = '$last' AND two_firstname ~ '^$firstinit';" );
  $result->execute;
  while (my @row = $result->fetchrow) { $row[0] =~ s/two//g; $lastnames{$row[0]}++; }
#   $result = $conn->exec( "SELECT two_lastname.joinkey FROM two_lastname, two_aka_firstname WHERE two_lastname.joinkey = two_aka_firstname.joinkey AND two_lastname = '$last' AND two_aka_firstname ~ '^$firstinit';" );
  $result = $dbh->prepare( "SELECT two_lastname.joinkey FROM two_lastname, two_aka_firstname WHERE two_lastname.joinkey = two_aka_firstname.joinkey AND two_lastname = '$last' AND two_aka_firstname ~ '^$firstinit';" );
  $result->execute;
  while (my @row = $result->fetchrow) { $row[0] =~ s/two//g; $lastnames{$row[0]}++; }
#   $result = $conn->exec( "SELECT two_aka_lastname.joinkey FROM two_aka_lastname, two_firstname WHERE two_aka_lastname.joinkey = two_firstname.joinkey AND two_aka_lastname = '$last' AND two_firstname ~ '^$firstinit';" );
  $result = $dbh->prepare( "SELECT two_aka_lastname.joinkey FROM two_aka_lastname, two_firstname WHERE two_aka_lastname.joinkey = two_firstname.joinkey AND two_aka_lastname = '$last' AND two_firstname ~ '^$firstinit';" );
  $result->execute;
  while (my @row = $result->fetchrow) { $row[0] =~ s/two//g; $lastnames{$row[0]}++; }
#   $result = $conn->exec( "SELECT two_aka_lastname.joinkey FROM two_aka_lastname, two_aka_firstname WHERE two_aka_lastname.joinkey = two_aka_firstname.joinkey AND two_aka_lastname = '$last' AND two_aka_firstname ~ '^$firstinit';" );
  $result = $dbh->prepare( "SELECT two_aka_lastname.joinkey FROM two_aka_lastname, two_aka_firstname WHERE two_aka_lastname.joinkey = two_aka_firstname.joinkey AND two_aka_lastname = '$last' AND two_aka_firstname ~ '^$firstinit';" );
  $result->execute;
  while (my @row = $result->fetchrow) { $row[0] =~ s/two//g; $lastnames{$row[0]}++; }

  my $twos = join ', ', (sort { $a <=> $b } keys %lastnames);
  print "TWOS : $twos<P>\n";
  foreach my $two (sort { $a <=> $b} keys %lastnames) { &displayOneDataFromKey($two); }
  print "LAST : $last<BR>FIRST INITIAL : $firstinit<BR>\n";
} # sub pickLastFI

sub pickLast {
  my ($oop, $last) = &getHtmlVar($query, 'last_name');
  my ($oop2, $exact_or_sub) = &getHtmlVar($query, 'exact_or_sub');
  my $result;
  my %lastnames;
  print "LAST : $last<P>\n";

  if ($exact_or_sub eq 'exact') {
#     $result = $conn->exec( "SELECT joinkey FROM two_lastname WHERE two_lastname = '$last' ;" );
    $result = $dbh->prepare( "SELECT joinkey FROM two_lastname WHERE two_lastname = '$last' ;" );
    $result->execute;
    while (my @row = $result->fetchrow) { $row[0] =~ s/two//g; $lastnames{$row[0]}++; }
#     $result = $conn->exec( "SELECT joinkey FROM two_aka_lastname WHERE two_aka_lastname = '$last' ;" );
    $result = $dbh->prepare( "SELECT joinkey FROM two_aka_lastname WHERE two_aka_lastname = '$last' ;" );
    $result->execute;
    while (my @row = $result->fetchrow) { $row[0] =~ s/two//g; $lastnames{$row[0]}++; }
#     $result = $conn->exec( "SELECT joinkey FROM two_apu_lastname WHERE two_apu_lastname = '$last' ;" );
    $result = $dbh->prepare( "SELECT joinkey FROM two_apu_lastname WHERE two_apu_lastname = '$last' ;" );
    $result->execute;
    while (my @row = $result->fetchrow) { $row[0] =~ s/two//g; $lastnames{$row[0]}++; }
  } elsif ($exact_or_sub eq 'sub') { 
#     $result = $conn->exec( "SELECT joinkey FROM two_lastname WHERE two_lastname ~ '$last' ;" );
    $result = $dbh->prepare( "SELECT joinkey FROM two_lastname WHERE two_lastname ~ '$last' ;" );
    $result->execute;
    while (my @row = $result->fetchrow) { $row[0] =~ s/two//g; $lastnames{$row[0]}++; }
#     $result = $conn->exec( "SELECT joinkey FROM two_aka_lastname WHERE two_aka_lastname ~ '$last' ;" );
    $result = $dbh->prepare( "SELECT joinkey FROM two_aka_lastname WHERE two_aka_lastname ~ '$last' ;" );
    $result->execute;
    while (my @row = $result->fetchrow) { $row[0] =~ s/two//g; $lastnames{$row[0]}++; }
#     $result = $conn->exec( "SELECT joinkey FROM two_apu_lastname WHERE two_apu_lastname ~ '$last' ;" );
    $result = $dbh->prepare( "SELECT joinkey FROM two_apu_lastname WHERE two_apu_lastname ~ '$last' ;" );
    $result->execute;
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
#     $result = $conn->exec( "SELECT joinkey FROM two_firstname WHERE two_firstname = '$first' ;" );
    $result = $dbh->prepare( "SELECT joinkey FROM two_firstname WHERE two_firstname = '$first' ;" );
    $result->execute;
    while (my @row = $result->fetchrow) { $row[0] =~ s/two//g; $firstnames{$row[0]}++; }
#     $result = $conn->exec( "SELECT joinkey FROM two_aka_firstname WHERE two_aka_firstname = '$first' ;" );
    $result = $dbh->prepare( "SELECT joinkey FROM two_aka_firstname WHERE two_aka_firstname = '$first' ;" );
    $result->execute;
    while (my @row = $result->fetchrow) { $row[0] =~ s/two//g; $firstnames{$row[0]}++; }
#     $result = $conn->exec( "SELECT joinkey FROM two_apu_firstname WHERE two_apu_firstname = '$first' ;" );
    $result = $dbh->prepare( "SELECT joinkey FROM two_apu_firstname WHERE two_apu_firstname = '$first' ;" );
    $result->execute;
    while (my @row = $result->fetchrow) { $row[0] =~ s/two//g; $firstnames{$row[0]}++; }
  } elsif ($exact_or_sub eq 'sub') { 
#     $result = $conn->exec( "SELECT joinkey FROM two_firstname WHERE two_firstname ~ '$first' ;" );
    $result = $dbh->prepare( "SELECT joinkey FROM two_firstname WHERE two_firstname ~ '$first' ;" );
    $result->execute;
    while (my @row = $result->fetchrow) { $row[0] =~ s/two//g; $firstnames{$row[0]}++; }
#     $result = $conn->exec( "SELECT joinkey FROM two_aka_firstname WHERE two_aka_firstname ~ '$first' ;" );
    $result = $dbh->prepare( "SELECT joinkey FROM two_aka_firstname WHERE two_aka_firstname ~ '$first' ;" );
    $result->execute;
    while (my @row = $result->fetchrow) { $row[0] =~ s/two//g; $firstnames{$row[0]}++; }
#     $result = $conn->exec( "SELECT joinkey FROM two_apu_firstname WHERE two_apu_firstname ~ '$first' ;" );
    $result = $dbh->prepare( "SELECT joinkey FROM two_apu_firstname WHERE two_apu_firstname ~ '$first' ;" );
    $result->execute;
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
  print "<TR><TD>First Initial : <TD><INPUT SIZE=40 NAME=\"first_init\" onChange=\"checkifempty()\"></TD>\n";
  print "<TD><INPUT TYPE=submit NAME=action VALUE=\"Last & First Initial !\"></TD></TR>\n";
  print "<TR><TD>Exact</TD><TD><INPUT NAME=\"exact_or_sub\" TYPE=\"radio\" VALUE=\"exact\"></TD></TR>\n";
  print "<TR><TD>Substring</TD><TD><INPUT NAME=\"exact_or_sub\" TYPE=\"radio\" VALUE=\"sub\" CHECKED></TD></TR>\n";
  print "<TR><TD>PI : <TD><INPUT SIZE=40 NAME=\"pi\" onChange=\"checkifempty()\"></TD>\n";
  print "<TD><INPUT TYPE=submit NAME=action VALUE=\"PI !\"></TD></TR>\n";
  print "<TR><TD>Lab : <TD><INPUT SIZE=40 NAME=\"lab\" onChange=\"checkifempty()\"></TD>\n";
  print "<TD><INPUT TYPE=submit NAME=action VALUE=\"Lab !\"></TD></TR>\n";
  print "<TR><TD>Old Lab : <TD><INPUT SIZE=40 NAME=\"oldlab\" onChange=\"checkifempty()\"></TD>\n";
  print "<TD><INPUT TYPE=submit NAME=action VALUE=\"Old Lab !\"></TD></TR>\n";
  print "<TR><TD>Email : <TD><INPUT SIZE=40 NAME=\"email\" onChange=\"checkifempty()\"></TD>\n";
  print "<TD><INPUT TYPE=submit NAME=action VALUE=\"Email !\"></TD></TR>\n";
  print "<TR><TD>Old Email : <TD><INPUT SIZE=40 NAME=\"oldemail\" onChange=\"checkifempty()\"></TD>\n";
  print "<TD><INPUT TYPE=submit NAME=action VALUE=\"Old Email !\"></TD></TR>\n";
  print "<TR><TD>Country : <TD><INPUT SIZE=40 NAME=\"country\" onChange=\"checkifempty()\"></TD>\n";
  print "<TD><INPUT TYPE=submit NAME=action VALUE=\"Country !\"></TD></TR>\n";
  print "<TR><TD>City : <TD><INPUT SIZE=40 NAME=\"city\" onChange=\"checkifempty()\"></TD>\n";
  print "<TD><INPUT TYPE=submit NAME=action VALUE=\"City !\"></TD></TR>\n";
  print "<TR><TD>Street : <TD><INPUT SIZE=40 NAME=\"street\" onChange=\"checkifempty()\"></TD>\n";
  print "<TD><INPUT TYPE=submit NAME=action VALUE=\"Street !\"></TD></TR>\n";
  print "<TR><TD>Institution : <TD><INPUT SIZE=40 NAME=\"institution\" onChange=\"checkifempty()\"></TD>\n";
  print "<TD><INPUT TYPE=submit NAME=action VALUE=\"Institution !\"></TD></TR>\n";
  print "<TR><TD>Old Institution : <TD><INPUT SIZE=40 NAME=\"old_institution\" onChange=\"checkifempty()\"></TD>\n";
  print "<TD><INPUT TYPE=submit NAME=action VALUE=\"Old Institution !\"></TD></TR>\n";
  print "<TR><TD>Unverified : </TD><TD></TD>\n";
  print "<TD><INPUT TYPE=submit NAME=action VALUE=\"Unverified !\"></TD></TR>\n";
  print "</FORM>\n";
  print "</TABLE>\n";

# This is just annoying 2009 01 03
#   print <<"EndOfText";
#     <script language="JavaScript1.1">
#     function checkifempty(){
#       if (document.form1.number.value=='') { document.form1.action[0].disabled=true } 
#         else { document.form1.action[0].disabled=false }
#       if (document.form1.last_name.value=='') { document.form1.action[1].disabled=true } 
#         else { document.form1.action[1].disabled=false }
#       if (document.form1.first_name.value=='') { document.form1.action[2].disabled=true } 
#         else { document.form1.action[2].disabled=false }
#       if (document.form1.first_init.value=='') { document.form1.action[3].disabled=true } 
#         else { document.form1.action[3].disabled=false }
#       if (document.form1.pi.value=='') { document.form1.action[4].disabled=true } 
#         else { document.form1.action[4].disabled=false }
#       if (document.form1.lab.value=='') { document.form1.action[5].disabled=true } 
#         else { document.form1.action[5].disabled=false }
#       if (document.form1.oldlab.value=='') { document.form1.action[6].disabled=true } 
#         else { document.form1.action[6].disabled=false }
#       if (document.form1.email.value=='') { document.form1.action[7].disabled=true } 
#         else { document.form1.action[7].disabled=false }
#       if (document.form1.oldemail.value=='') { document.form1.action[8].disabled=true } 
#         else { document.form1.action[8].disabled=false }
#       if (document.form1.country.value=='') { document.form1.action[9].disabled=true } 
#         else { document.form1.action[9].disabled=false }
#       if (document.form1.city.value=='') { document.form1.action[10].disabled=true } 
#         else { document.form1.action[10].disabled=false }
#       if (document.form1.street.value=='') { document.form1.action[11].disabled=true } 
#         else { document.form1.action[11].disabled=false }
#       if (document.form1.institution.value=='') { document.form1.action[12].disabled=true } 
#         else { document.form1.action[12].disabled=false }
#       if (document.form1.old_institution.value=='') { document.form1.action[13].disabled=true } 
#         else { document.form1.action[13].disabled=false }
#     }
#     checkifempty();
#     </script>
# EndOfText


} # sub firstPage

### display from key ###

sub displayOneDataFromKey {
  my ($two_key) = 'two' . $_[0];
#   my $result = $conn->exec( "SELECT * FROM two_status WHERE joinkey = '$two_key' ORDER BY two_order;" );
  my $result = $dbh->prepare( "SELECT * FROM two_status WHERE joinkey = '$two_key' ORDER BY two_order;" );
  $result->execute;
  my @row = $result->fetchrow; if ($row[2]) { if ($row[2] eq 'Invalid') { print "<FONT SIZE=+2 COLOR=red>INVALID</FONT><P>\n"; } }
  print "<TABLE border=1 cellspacing=2>\n";
  my $counter = 0;
  foreach my $two_table (@two_tables) {
#     my $result = $conn->exec( "SELECT * FROM $two_table WHERE joinkey = '$two_key' ORDER BY two_order;" );
    my $result = $dbh->prepare( "SELECT * FROM $two_table WHERE joinkey = '$two_key' ORDER BY two_order;" );
    $result->execute;
    while (my @row = $result->fetchrow) {
      if ($row[1]) {
        if ($row[3] =~ m/(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})/) { $row[3] = $1; }
        print "<TR bgcolor='$blue'>\n  <TD>$two_table</TD>\n";
        print "  <TD>$row[0]</TD>\n"; 
        print "  <TD>$row[1]</TD>\n";
        print "  <TD WIDTH=50%>$row[2]</TD>\n";
        print "  <TD>$row[3]</TD>\n";
        print "</TR>\n";
      } # if ($row[1])
    } # while (my @row = $result->fetchrow)
  } # foreach my $two_table (@two_tables)

  foreach my $two_simpler (@two_simpler) {
#     my $result = $conn->exec( "SELECT * FROM $two_simpler WHERE joinkey = '$two_key' ORDER BY two_timestamp DESC;" );
    my $result = $dbh->prepare( "SELECT * FROM $two_simpler WHERE joinkey = '$two_key' ORDER BY two_timestamp DESC;" );
    $result->execute;
    while (my @row = $result->fetchrow) {
      if ($row[1]) {
        print "<TR bgcolor='$blue'>\n  <TD>$two_simpler</TD>\n";
        print "  <TD>$row[0]</TD>\n"; 
        print "  <TD>&nbsp;</TD>\n"; 
        print "  <TD>$row[1]</TD>\n";
        print "  <TD>"; if ($row[2]) { 
          if ($row[2] =~ m/(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})/) { $row[2] = $1; }
          print $row[2]; } print "</TD>\n";
        print "</TR>\n";
      } # if ($row[1])
    } # while (my @row = $result->fetchrow)
  } # foreach my $two_simpler (@two_simpler)
  print "</TABLE><BR><BR>\n";

  print "<TABLE border=1 cellspacing=2>\n";
  foreach my $two_complex (@two_complex) {
#     my $result = $conn->exec( "SELECT * FROM $two_complex WHERE joinkey = '$two_key' ORDER BY two_number, two_role;" );
    my $result = $dbh->prepare( "SELECT * FROM $two_complex WHERE joinkey = '$two_key' ORDER BY two_number, two_role;" );
    $result->execute;
    while (my @row = $result->fetchrow) {
      if ($row[1]) {
        print "<TR bgcolor=\"$blue\">\n  <TD>$two_complex</TD>\n";
        print "  <TD>$row[0]</TD>\n"; 
        print "  <TD>$row[2]</TD>\n"; 
        print "  <TD>$row[3]</TD>\n"; 
        print "  <TD>$row[4]</TD>\n";
        if ($row[5]) { print "  <TD>$row[5]</TD>\n"; } else { print "  <TD>&nbsp;</TD>\n"; }
        if ($row[6]) { print "  <TD>$row[6]</TD>\n"; } else { print "  <TD>&nbsp;</TD>\n"; }
        if ($row[7]) { print "  <TD>$row[7]</TD>\n"; } else { print "  <TD>&nbsp;</TD>\n"; }
        if ($row[8] =~ m/(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})/) { $row[8] = $1; }
        print "  <TD WIDTH=18%>$row[8]</TD>\n";
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
#     my $result = $conn->exec( "SELECT * FROM $ace_table WHERE joinkey = '$ace_key';" );
    my $result = $dbh->prepare( "SELECT * FROM $ace_table WHERE joinkey = '$ace_key';" );
    $result->execute;
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
#     my $result = $conn->exec( "SELECT * FROM $wbg_table WHERE joinkey = '$wbg_key';" );
    my $result = $dbh->prepare( "SELECT * FROM $wbg_table WHERE joinkey = '$wbg_key';" );
    $result->execute;
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

