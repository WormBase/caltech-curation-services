#!/usr/bin/perl -w

# Suggest Phenotype Definitions to Gary

 


use strict;
use CGI;
use Pg;
use Jex;
# use LWP::UserAgent;
use LWP::Simple;
# use POSIX qw(ceil);



my $query = new CGI;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $frontpage = 1;
my $blue = '#00ffcc';			# redefine blue to a mom-friendly color
my $red = '#ff00cc';			# redefine red to a mom-friendly color


my %theHash;
my %obo;
my $suggested_file = '/home/postgres/public_html/cgi-bin/data/phenotype_suggestions.txt';

my %curators;				# $curators{two}{two#} = std_name ; $curators{std}{std_name} = two#

# &printHeader('Phenotype Suggestion');

print "Content-type: text/html\n\n";
print "<HTML><HEAD>\n";
print <<"EndOfText";
function populateLevel(n) {
   username=prompt("Please enter your name","Enter your name here");
   document.forms["form1"]["suggest_"+n].value = username
}
EndOfText
print "</HEAD>\n";

&display();
&printFooter();


### DISPLAY ###

sub display {
  my $action;

  unless ($action = $query->param('action')) {
    $action = 'none';
    if ($frontpage) { &firstPage(); return; }
  } else { $frontpage = 0; }

  print "<FORM NAME='form1' METHOD=\"POST\"
ACTION=\"http://tazendra.caltech.edu/~azurebrd/cgi-bin/testing/javascript/old/phenotype_definition.cgi\">\n"; my ($oop, $curator) = &getHtmlVar($query, 'curator_name');
  if ($curator) { 
    $theHash{curator} = $curator;
    print "Curator : $curator<P>\n"; 
    print "<INPUT TYPE=\"HIDDEN\" NAME=\"curator_name\" VALUE=\"$theHash{curator}\">\n"; }
  else { print "<FONT COLOR='red'>ERROR : You must choose a curator.<BR>\n"; return; }

  if ($action eq 'Enter New Definitions !') { &newDefinitions(); }
  elsif ($action eq 'Suggest !') { &suggest(); }
  else { 1; }
  print "</FORM>\n";
} # sub display

sub suggest {
  my ($oop, $count) = &getHtmlVar($query, 'amount');
  print "COUNT $count<BR>\n";
  my @data; my @errors;
  for my $i (0 .. $count) { 
    ($oop, my $checked) = &getHtmlVar($query, "check_$i");
    if ($checked) { 
      ($oop, my $id) = &getHtmlVar($query, "id_$i");
      if ($id) { unless ($id =~ m/^\d{7}$/) { push @errors, "$id doesn't have exactly 7 digits"; } }
        else { push @errors, "no id for checkbox $i"; }
      ($oop, my $suggest) = &getHtmlVar($query, "suggest_$i");
      ($oop, my $evidence) = &getHtmlVar($query, "evidence_$i");
      push @data, "$id\t$suggest\t$theHash{curator}\t$evidence"; }
  } # for (0 .. $i)
  print "<P>\n";
  if ($errors[0]) { print "<FONT COLOR=red>ERROR no data submitted :</FONT><BR>\n"; foreach my $error (@errors) { print "$error<BR>\n"; } }
    else { 
      open (OUT, ">>$suggested_file") or die "Cannot append to $suggested_file : $!";
      foreach my $data (@data) {
        print OUT "$data\n";
        print "$data<BR>\n";
      }
      close (OUT) or die "Cannot close $suggested_file : $!";
      my $user = 'phenotype_definition.cgi';
      my $email = 'garys@its.caltech.edu';
#       my $email = 'azurebrd@tazendra.caltech.edu';
      my $subject = "$theHash{curator} suggested phenotype definitions";
      my $body = join"\n", @data;
      &mailer($user, $email, $subject, $body);
    }
} # sub suggest

sub newDefinitions {
  print "<INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Suggest !\"><BR><BR>\n";
  my $obofile = get "http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/phenotype_ontology_obo.cgi";
  my (@terms) = split/\[Term\]/, $obofile;
  foreach my $term (@terms) {
    if ($term =~ m/id: WBPhenotype:(\d+)/) {
      my $id = $1;
      my ($name) = $term =~ m/name: (\w+)/;
      my ($def) = $term =~ m/def: \"(.*?)\"/;
      unless ($def) { $obo{$id}{name} = $name; }
    }
  } # foreach my $term (@terms)
  my %suggested; my @suggested;
  open (IN, "$suggested_file") or die "Cannot open $suggested_file : $!";
  while (my $line = <IN>) {
    chomp $line;
    my ($id, $sug, $cur, $evi) = split/\t/, $line;
    $suggested{$id}{sug} = $sug;
    $suggested{$id}{evi} = $evi;
  } # while (my $line = <IN>)
  close (IN) or die "Cannot close $suggested_file : $!";
  my $count = 0;
  print "<TABLE border=0 cellspacing=2>\n";
  print "<TR><TD ALIGN=CENTER>id</TD><TD ALIGN=CENTER>name</TD><TD ALIGN=CENTER>suggested definition</TD><TD ALIGN=CENTER>evidence</TD></TR>\n";
  print "<TD><INPUT NAME=\"id_$count\" SIZE=20></TD>\n";
#   print "<TD><INPUT NAME=\"name_$count\" SIZE=60></TD>\n";
  print "<TD>&nbsp;</TD>\n";
#   print "<TD><INPUT NAME=\"suggest_$count\" SIZE=20></TD>\n";
  print "<TD><TEXTAREA NAME=\"suggest_$count\" ROWS=4 COLS=60></TEXTAREA></TD>\n";
  print "<TD><INPUT NAME=\"evidence_$count\" SIZE=20></TD>\n";
  print "<TD ALIGN='CENTER'><INPUT NAME=\"check_$count\" TYPE=CHECKBOX VALUE=\"valid\"></TD>\n"; 
  print "</TR>\n";
  foreach my $id (sort keys %obo) {
    $count++;
    last if ($count > 10);
    my $name = $obo{$id}{name};
    my $line = '';
    $line .= "<TR><TD>$id</TD><TD>$name</TD>\n";
print <<"EndOfText";
<TD><form>
<select name="selectName">
<option>$count
</select>
<input type="button" value="Go" onClick="window.location.href = 'phenotype_definition.cgi?' + this.form.selectName.options[this.form.selectName.selectedIndex].text">
</form></TD>

<TD><select size=2 name=list1 onchange=populateLevel($count)>
<option>I</option>
<option>You</option>
</select></TD>
EndOfText

# function populateLevel(n) {
    $line .= "<TD><TEXTAREA NAME=\"suggest_$count\" ROWS=4 COLS=60>";
    if ($suggested{$id}{sug}) { $line .= "$suggested{$id}{sug}"; }
    $line .= "</TEXTAREA></TD>\n";
#     $line .= "<TD><INPUT NAME=\"suggest_$count\" SIZE=20";
#     if ($suggested{$id}{sug}) { $line .= " VALUE=\"$suggested{$id}{sug}\""; }
#     $line .= "></TD>\n";
    $line .= "<TD><INPUT NAME=\"evidence_$count\" SIZE=20";
    if ($suggested{$id}{evi}) { $line .= " VALUE=\"$suggested{$id}{evi}\""; }
    $line .= "></TD>\n";
    $line .= "<TD ALIGN='CENTER'><INPUT NAME=\"check_$count\" TYPE=CHECKBOX VALUE=\"valid\"></TD>\n"; 
    $line .= "<INPUT TYPE=\"HIDDEN\" NAME=\"id_$count\" VALUE=\"$id\">\n";
    $line .= "</TR>\n";
    if ($suggested{$id}{sug}) { push @suggested, $line; } else { print $line; }
  } # foreach my $id (sort keys %obo)
  print "<TR><TD COLSPAN=4>These already have suggested definitions</TD></TR>\n";
  foreach my $line (@suggested) { print $line; }
  print "</TABLE>\n";
  print "<INPUT TYPE=\"HIDDEN\" NAME=\"amount\" VALUE=\"$count\">\n";
  print "<INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Suggest !\"><BR><BR>\n";
} # sub newDefinitions


### FIRST PAGE ###

sub firstPage {
  my $date = &getDate();
  print "Value : $date<BR>\n";
  print "<FORM NAME='form1' METHOD=\"POST\" ACTION=\"http://tazendra.caltech.edu/~azurebrd/cgi-bin/testing/javascript/old/phenotype_definition.cgi\">\n";
  print "<TABLE>\n";
  print "<TR><TD>Select your Name among : <BR>\n";
  print "<INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Enter New Definitions !\"></TD>\n";
  print "<TD><SELECT NAME=\"curator_name\" SIZE=14>\n";
  print "<OPTION>Igor Antoshechkin</OPTION>\n";
  print "<OPTION>Juancarlos Chan</OPTION>\n";
  print "<OPTION>Wen Chen</OPTION>\n";
  print "<OPTION>Jolene S. Fernandes</OPTION>\n";
  print "<OPTION>Ranjana Kishore</OPTION>\n";
  print "<OPTION>Raymond Lee</OPTION>\n";
  print "<OPTION>Tuco</OPTION>\n";
  print "<OPTION>Gary C. Schindelman</OPTION>\n";
  print "<OPTION>Erich Schwarz</OPTION>\n";
  print "<OPTION>Paul Sternberg</OPTION>\n";
  print "<OPTION>Mary Ann Tuli</OPTION>\n";
  print "<OPTION>Kimberly Van Auken</OPTION>\n";
  print "<OPTION>Xiaodong Wang</OPTION>\n";
  print "<OPTION>Karen Yook</OPTION>\n";
  print "</SELECT></TD>\n";
#   print "<TD><INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Enter New Definitions !\"></TD></TR><BR><BR>\n";
  print "</TABLE>\n";
} # sub firstPage

### FIRST PAGE ###


sub filterSpaces {
  my $value = shift;
  if ($value =~ m/^\s+/) { $value =~ s/^\s+//; }
  if ($value =~ m/\s+$/) { $value =~ s/\s+$//; }
#   if ($value =~ m/\s+/) { $value =~ s/\s+/ /g; }	# don't want this, gets rid of tabs 2007 08 31
  return $value;
} # sub filterSpaces

sub filterForPg {
  my $value = shift;
  if ($value =~ m/\'/) { $value =~ s/\'/''/g; }
  return $value;
} # sub filterForPg

sub padZeros {
  my $joinkey = shift;
  if ($joinkey =~ m/^0+/) { $joinkey =~ s/^0+//g; }
  if ($joinkey < 10) { $joinkey = '0000000' . $joinkey; }
  elsif ($joinkey < 100) { $joinkey = '000000' . $joinkey; }
  elsif ($joinkey < 1000) { $joinkey = '00000' . $joinkey; }
  elsif ($joinkey < 10000) { $joinkey = '0000' . $joinkey; }
  elsif ($joinkey < 100000) { $joinkey = '000' . $joinkey; }
  elsif ($joinkey < 1000000) { $joinkey = '00' . $joinkey; }
  elsif ($joinkey < 10000000) { $joinkey = '0' . $joinkey; }
  return $joinkey;
} # sub padZeros


__END__

