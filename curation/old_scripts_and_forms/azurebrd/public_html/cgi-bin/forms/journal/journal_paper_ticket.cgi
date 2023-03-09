#!/usr/bin/perl 

# get a new WBPaper journal ticket (new paper ID)

# take the latest wpa, and create the next one for a given Journal.
# for Tim Schedl use his ID as curator : two555
# create the new wpa, wpa_journal Genetics, and afp_password for authors to curate the paper.
# Later on when we get the XML from Genetics, they'll need to give us back the PaperID.
# 
# Tim can use this link :
# http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/journal/journal_paper_ticket.cgi?action=Ticket+!&tickets=1&journal=Genetics
# to generate a paperID <tab> link for author to FP curate.
#
# To go live, uncomment the UNCOMMENT lines.  2009 05 01
#
# switch from number of tickets, to DOI input.  Create wpa_identifier doi$doi.  
# create wpa as invalid, and make valid when we get the XML.  2009 07 06
#
# live 2009 07 08
#
# message Karen when a new ticket has been generated for a DOI  2009 07 09
#
# check if the DOI exists, if it doesn't generate a password and paper.  if it does
# check if it has an afp_passwd.  if it does, show it, if it doesn't generate it.
# wpa are now created as valid since they'll just get data populated from pubmed 
# later on (not xml).  2009 07 23
#
# Switched from wpa to pap tables.  Live  2010 06 24
#
# Added Daniela and Chris.  2011 02 01
#
# Added Kimberly, added g3 (to two555), strip any leading DOI (insensitive) from the doi.  2011 10 19
#
# Added description, example, made input field bigger, for Karen.  2013 12 05
#
# Changed Micropublication:biology into microPublication Biology for Daniela.  2018 10 11
# 
# Karen, Daniela, Kimberly, Valerio no longer want password assignment, nor links to have an author jfp this papers.  2021 03 16


use CGI;
use Fcntl;
use strict;
use Jex;
use DBI;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my $query = new CGI;

srand;

my $highest_pap;
my %journalToTwo;

$journalToTwo{"microPublication Biology"} = 'two555';
$journalToTwo{"Genetics"} = 'two555';
$journalToTwo{"g3"} = 'two555';

my $action;
unless ($action = $query->param('action')) {
  $action = 'none'; 
}

if ($action eq 'Ticket !') { 
    print "Content-type: text/plain\n\n"; 
    &getTickets(); 
  }
  else { 
    &printHeader('Journal Paper Ticket');      # normal form view
    &process();
    &printFooter();
}

sub process {
  if ($action eq 'none') { &firstPage(); }
} # sub process

sub firstPage {
  print "<FORM METHOD=\"POST\" ACTION=\"journal_paper_ticket.cgi\">";
  print "<TABLE>\n";
#   print "<TR><TD ALIGN=\"right\">How many tickets would you like :</TD>";
#   print "<TD ALIGN=\"right\"><INPUT NAME=tickets SIZE=10></TD>\n";
  print "<TR><TD ALIGN=\"left\" colspan=\"2\">Create a WBPaperID with a DOI</TD>";
  print "<TR><TD ALIGN=\"right\">DOI :</TD>";
  print "<TD ALIGN=\"right\"><INPUT NAME=doi SIZE=20></TD><TD>Use full DOI, ex. 10.1534/genetics.113.157685</TD>\n";
  print "<TR><TD>Select your Journal : </TD><TD ALIGN=\"right\"><SELECT NAME=\"journal\" SIZE=1>\n";
  foreach my $journal (sort keys %journalToTwo) {
    print "<OPTION VALUE=\"$journal\">$journal</OPTION>\n";
  }
  print "</SELECT></TD>";
  print "<TD><INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Ticket !\"></TD></TR><BR><BR>\n";
  print "</TABLE>\n";
  print "</FORM>\n";
} # sub firstPage


sub getTickets {
  &populateWpa();
#   my ($oop, $tickets) = &getHtmlVar($query, 'tickets');
  my ($oop, $doi) = &getHtmlVar($query, 'doi');
  if ($doi) { 
      $doi =~ s/^\s+//; $doi =~ s/\s+$//; 
      $doi = lc $doi;				# convert to lowercase for Karen 2019 01 09
      if ($doi =~ m/^DOI/i) { $doi =~ s/^DOI//i; } }
    else { print "You must enter a DOI\n"; return; }
  ($oop, my $journal) = &getHtmlVar($query, 'journal');
  unless ($journal) { print "ERROR : you must choose a Journal name\n"; return; }
  my $curator = $journalToTwo{$journal};
  my @commands;

  $highest_pap++;
  my $paper = &padZeros($highest_pap);
  my $passwd = '';

  my $already_in = 0;
#   my $result = $dbh->prepare( "SELECT * FROM wpa_identifier WHERE wpa_identifier = 'doi$doi' ORDER BY joinkey DESC;" );
#   $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
#   my @row = $result->fetchrow();
#   if ($row[3] eq 'valid') { $paper = $row[0]; $already_in++; }
  my $result = $dbh->prepare( "SELECT * FROM pap_identifier WHERE LOWER(pap_identifier) = 'doi$doi';" );	# convert to lowercase for Karen 2019 01 09
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  my @row = $result->fetchrow();
  if ($row[1]) { $paper = $row[0]; $already_in++; }

  if ($already_in) {
# Karen, Daniela, Kimberly, Valerio no longer want password assignment, nor links to have an author jfp this papers
#     $result = $dbh->prepare( "SELECT * FROM afp_passwd WHERE joinkey = '$paper';" );
#     $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
#     my @row = $result->fetchrow();
#     if ($row[1]) { $passwd = $row[1]; }
#       else {
#         $passwd = rand;
#         my $time = time;
#         $passwd += $time;
#         ($passwd) = sprintf("%.7f", $passwd);
#         my $command = "INSERT INTO afp_passwd VALUES ('$paper', '$passwd')";
#         push @commands, $command; }
  } else {
    my $command = "INSERT INTO pap_status VALUES ('$paper', 'valid', NULL, '$curator')";
    push @commands, $command;
    $command = "INSERT INTO h_pap_status VALUES ('$paper', 'valid', NULL, '$curator')";
    push @commands, $command;
    $command = "INSERT INTO pap_journal VALUES ('$paper', '$journal', NULL, '$curator')";
    push @commands, $command;
    $command = "INSERT INTO h_pap_journal VALUES ('$paper', '$journal', NULL, '$curator')";
    push @commands, $command;
    $command = "INSERT INTO pap_identifier VALUES ('$paper', 'doi$doi', '1', '$curator')";
    push @commands, $command;
    $command = "INSERT INTO h_pap_identifier VALUES ('$paper', 'doi$doi', '1', '$curator')";
    push @commands, $command;
    $passwd = rand;
    my $time = time;
    $passwd += $time;
    ($passwd) = sprintf("%.7f", $passwd);
    my $command = "INSERT INTO afp_passwd VALUES ('$paper', '$passwd')";
    push @commands, $command; 
  }

#   my $link = "http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/journal/journal_first_pass.cgi?action=Curate&paper=$paper&passwd=$passwd";
#   my $link = "journal_first_pass.cgi?action=Curate&paper=$paper&passwd=$passwd";
#   my $body = "$doi\tWBPaper$paper\n$link";
  my $body = "$doi\tWBPaper$paper\n";

#   print "DOI$doi\tWBPaper$paper\t$link\n";
  print "DOI$doi\tWBPaper$paper\t\n";

  foreach my $command (@commands) {
#     print "$command\n";
# UNCOMMENT TO GO LIVE			# live 2009 07 08
    my $result = $dbh->do( $command );
  } # foreach my $command (@commands)
  &messageKaren($body);
} # sub getTickets

sub messageKaren {
  my $body = shift;
  my $user = 'journal_paper_ticket.cgi';
  my $email = 'kyook@caltech.edu, vanauken@caltech.edu, daniela.raciti@micropublication.org, karen.yook@micropublication.org';	# karen said to add daniela and this email address. 2018 04 03
#   my $email = 'kyook@caltech.edu, vanauken@caltech.edu';
#   my $email = 'kyook@caltech.edu, draciti@caltech.edu, cgrove@caltech.edu, vanauken@caltech.edu';	# karen said to remove daniela and chris 2013 01 09
#   my $email = 'azurebrd@tazendra.caltech.edu';
  my $subject = 'new paper ticket DOI created';
#   print "$body<BR>\n";
  &mailer($user, $email, $subject, $body);    # email DOI to karen
} # sub messageAndrei




sub populateWpa {
  my $result = $dbh->prepare( "SELECT * FROM pap_status ORDER BY joinkey DESC;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  my @row = $result->fetchrow();
  $highest_pap = $row[0]; 
  $highest_pap =~ s/^0+//;
} # sub populateWpa

sub padZeros {
  my $ticket = shift;
  if ($ticket < 10) { $ticket = '0000000' . $ticket; }
    elsif ($ticket < 100) { $ticket = '000000' . $ticket; }
    elsif ($ticket < 1000) { $ticket = '00000' . $ticket; }
    elsif ($ticket < 10000) { $ticket = '0000' . $ticket; }
    elsif ($ticket < 100000) { $ticket = '000' . $ticket; }
    elsif ($ticket < 1000000) { $ticket = '00' . $ticket; }
    elsif ($ticket < 10000000) { $ticket = '0' . $ticket; }
  return $ticket;
} # sub padZeros

