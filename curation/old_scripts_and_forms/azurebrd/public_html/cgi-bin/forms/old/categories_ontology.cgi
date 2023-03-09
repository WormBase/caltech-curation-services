#!/usr/bin/perl -w

# Edit Textpresso categories / ontologies

# Create text files into $repository_dir  for Kimberly  2008 02 01
#
# Added section to add batches, and process them for capitalization /
# pluralization, and further processing before Saving.  2008 02 24


use strict;
use CGI;
use diagnostics;
use Jex;
use Lingua::Stem qw(stem);


my $query = new CGI;
my %theHash;

my %irreg;				# key -> irregular verbs, value -> comma-separated conjugations of that verb

my $frontpage = 1;
my $blue = '#00ffcc';			# redefine blue to a mom-friendly color
my $red = '#ff00cc';			# redefine red to a mom-friendly color

my $repository_dir = '/home/azurebrd/public_html/cgi-bin/forms/textpresso/repository/';

&printHeader('Textpresso Categories / Ontology Editor');
&display();
&printFooter();


### DISPLAY ###

sub display {
  my $action;

  unless ($action = $query->param('action')) {
    $action = 'none';
    if ($frontpage) { &firstPage(); return; }
  } else { $frontpage = 0; }

  print "<FORM METHOD=\"POST\" ACTION=\"http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/categories_ontology.cgi\">\n";
  my ($oop, $curator) = &getHtmlVar($query, 'curator_name');
  if ($curator) { 
    $theHash{curator} = $curator;
    print "Curator : $curator<BR>\n"; 
    print "<INPUT TYPE=\"HIDDEN\" NAME=\"curator_name\" VALUE=\"$theHash{curator}\">\n"; }
  else { print "<FONT COLOR='red'>ERROR : You must choose a curator.<BR>\n"; }
  unless ($curator) { return; }
#   ($oop, my $file_type) = &getHtmlVar($query, 'file_type');
#   if ($file_type) { 
#     $theHash{file_type} = $file_type;
#     print "File type : $file_type<BR>\n"; 
#     print "<INPUT TYPE=\"HIDDEN\" NAME=\"file_type\" VALUE=\"$theHash{file_type}\">\n"; }
#   else { print "<FONT COLOR='red'>ERROR : You must choose a type of ontology.<BR>\n"; }
#   unless ($curator && $file_type) { return; }

  if ($action eq 'Create !') { &create('new'); }
  elsif ($action eq 'Process !') { &create('process'); }
  elsif ($action eq 'Select existing !') { &selectFile(); }
  elsif ($action eq 'Save as new file !') { &saveFile('new'); }
  elsif ($action eq 'Save and overwrite this file !') { &saveFile('overwrite'); }
  elsif ($action eq 'Load file !') { &create('load'); }
  else { 1; }
  print "</FORM>\n";
} # sub display

### FIRST PAGE ###

sub selectFile {
# my $repository_dir = '/home/azurebrd/public_html/cgi-bin/forms/textpresso/repository/';
  my (@list) = <${repository_dir}*>;
  my ($oop, $file_selection) = &getHtmlVar($query, 'file_type');
# print "FILETYPE $file_type F<BR>\n";
#   my $file_type = $theHash{file_type};
  foreach my $file (@list) {
    my $temp = $file; $temp =~ s/__space__/ /g; $temp =~ s/$repository_dir//g;
#     print "TEMP $temp EMP<BR>\n";
    my ($file_type) = $temp =~ m/_(.*?)_/;
#     print "T $file_type T<BR>\n";
    my $curator_temp = $theHash{curator};
    $curator_temp =~ s/\s+/__space__/g;
    $file_type =~ s/\s+/__space__/g;

    $file =~ s/$repository_dir//g;
# print "FILE $file F<BR>\n";
    if ($file =~ m/^${curator_temp}_$file_selection/) {
      print "<FORM METHOD=\"POST\" ACTION=\"http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/categories_ontology.cgi\">\n";
      print "<INPUT TYPE=\"HIDDEN\" NAME=\"curator_name\" VALUE=\"$theHash{curator}\">\n"; 
      print "<INPUT TYPE=\"HIDDEN\" NAME=\"file_type\" VALUE=\"$file_type\">\n"; 
      print "<INPUT TYPE=\"HIDDEN\" NAME=\"file_name\" VALUE=\"$file\">\n"; 
      $file =~ s/__space__/ /g;
      print "$file \n";
      print "<INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Load file !\"><BR>\n";
      print "</FORM>\n";
    }
  } # foreach my $file (@list)

} # sub selectFile

sub getHtmlMultvar {
  my ($query, $var) = @_;
  unless ($query->param("$var")) {              # if no such variable found
  } else { # unless ($query->param("$var"))     # if we got a value
    my (@oop) = $query->param("$var");            # get the value
    foreach my $oop (@oop) { $oop = &untaint($oop); }
    return ($var, @oop);                       # return the variable and value
  } # else # unless ($query->param("$var"))
} # sub &getHtmlMultvar


sub saveFile {
  my ($new_over) = shift;
  my ($oop, $file_data) = &getHtmlVar($query, 'file_data');
  ($oop, my $file_type) = &getHtmlVar($query, 'file_type');
#   ($oop, my $final_value) = &getHtmlVar($query, 'final_value');
  ($oop, my @mark_up) = &getHtmlMultvar($query, 'mark_up');
  my $mark_up = join"__JOIN__", @mark_up;
# foreach my $blah (@mark_up) { print "BL $blah E<BR>\n"; }
#   print "MARKUP $mark_up[0] E<BR>\n";
#   print "MARKUP $mark_up[1] E<BR>\n";
#   print "MARKUP $mark_up[2] E<BR>\n";
#   print "MARKUP $mark_up[3] E<BR>\n";
  ($oop, my $old_file_name) = &getHtmlVar($query, 'file_name');
  $old_file_name = $repository_dir . $old_file_name;
#   if ($final_value) { $final_value = 'release'; } else { $final_value = 'temp'; }
  unless ($mark_up) { $mark_up = 'temp'; }
  $theHash{curator} =~ s/\s+/__space__/g;
  $theHash{file_type} = $file_type;
  my $date = &getSimpleSecDate();
  my $file_name = $theHash{curator} . '_' . $theHash{file_type} . '_' .  $date . '_' . $mark_up;
  $file_name = $repository_dir . $file_name;
print "DATA $file_data DATA<BR>\n";
  open (OUT, ">$file_name") or die "Cannot create $file_name : $!"; 
  print OUT $file_data;
  close (OUT) or die "Cannot close $file_name : $!"; 
  my $file_url = $file_name;
  $file_url =~ s/\/home\/azurebrd\/public_html/http:\/\/tazendra.caltech.edu\/~azurebrd/g;
  print "Saved $file_data To <A HREF=\"$file_url\">$file_name</A> E<BR>\n";
  if ($new_over eq 'overwrite') {
    if (-e $old_file_name) { `rm $old_file_name`; }
    print "overwriting file $old_file_name<BR>\n"; }
} # sub saveFile

sub populateIrregular {
  my $infile = '/home/azurebrd/work/testing/perl/stem/irregular.parsed';
  open (IN, "<$infile") or die "Cannot open $infile : $!";
  while (my $line = <IN>) { chomp $line; my ($key, $rest) = split/\t/, $line; $irreg{$key} = $rest; }
  close (IN) or die "Cannot close $infile : $!";
} # sub populateIrregular

sub create {
  my ($load_or_new) = shift;
  my ($oop, $file_type) = &getHtmlVar($query, 'file_type');
  ($oop, my $file_name) = &getHtmlVar($query, 'file_name');
  if ($file_type) { 
    $theHash{file_type} = $file_type;
    print "<INPUT TYPE=\"HIDDEN\" NAME=\"file_type\" VALUE=\"$theHash{file_type}\">\n"; 
    print "<INPUT TYPE=\"HIDDEN\" NAME=\"file_name\" VALUE=\"$file_name\">\n"; 
    $file_type =~ s/__space__/ /g;
    print "File type : $file_type<BR>\n"; }
  else { print "<FONT COLOR='red'>ERROR : You must choose a type of ontology.<BR>\n"; return; } 
  my $file_data = ''; my $raw_data = ''; my @unfilt_data;
  print "Add new data on the left column, then click ``Process !'' to pluralize and capitalize new words.<BR>\n";
  print "Edit processed words on the right column, then select the mark up type, and click ``Save as new file !'' or ``Save and overwrite this file !''.<BR>\n";
  print "<TABLE border=1>\n";
  my %all_data;
  ($oop, $raw_data) = &getHtmlVar($query, 'raw_data');
  if ($load_or_new eq 'process') {
    ($oop, my $pluralize) = &getHtmlVar($query, 'pluralize');
    ($oop, my $capitalize) = &getHtmlVar($query, 'capitalize');
    ($oop, my $conjugate) = &getHtmlVar($query, 'conjugate');
    if ($conjugate eq 'checked') { &populateIrregular(); }
    my (@lines) = split/\n/, $raw_data;
    foreach my $line (@lines) {
      chomp $line; $line =~ s/\s+$//g;
      my $key = lc($line);
      my ($processed) = &processWord($line, $pluralize, $capitalize, $conjugate); 
      $all_data{$key}{$processed}++; } }
  if ( ($load_or_new eq 'load') || ($load_or_new eq 'process') ) { 
    my ($oop, $file_name) = &getHtmlVar($query, 'file_name');
    $file_name = $repository_dir . $file_name;
    open (IN, "<$file_name") or die "Cannot open $file_name : $!";
    while (my $line = <IN>) {
      chomp $line; $line =~ s/\s+$//g;
      my $key = lc($line);
      $all_data{$key}{$line}++; }
    close (IN) or die "Cannot close $file_name : $!"; }
  foreach my $key (sort keys %all_data) {
    foreach my $data (sort keys %{ $all_data{$key} }) {
      my @data = split/\n/, $data; foreach my $word (@data) { push @unfilt_data, $word; } } }
  my %filter; 			# filter multiple results through here while maintaining alphabetical minus capitalization sorting
  foreach my $data (@unfilt_data) { unless ($filter{$data}) { $filter{$data}++; $file_data .= "$data\n"; } }
  print "<TR><TD COLSPAN=2>New Data to capitalize, stem, and pluralize</TD><TD COLSPAN=2>Capitalazied, stemmed, and pluralized data for saving</TD></TR>\n";
  print "<TR>";
  print "<TD ALIGN='LEFT' COLSPAN=2><TEXTAREA NAME=\"raw_data\" ROWS=36 COLS=50 VALUE=\"\">$raw_data</TEXTAREA></TD>";
  print "<TD ALIGN='LEFT' COLSPAN=2><TEXTAREA NAME=\"file_data\" ROWS=36 COLS=50 VALUE=\"\">$file_data</TEXTAREA></TD>";
  print "</TR>\n";
  print "<TR>";
  print "<TD ALIGN='CENTER' COLSPAN=2>\n";
  print "<INPUT TYPE=\"CHECKBOX\" NAME=\"capitalize\" VALUE=\"checked\">capitalize\n";
  print "<INPUT TYPE=\"CHECKBOX\" NAME=\"pluralize\" VALUE=\"checked\">pluralize\n";
  print "<INPUT TYPE=\"CHECKBOX\" NAME=\"conjugate\" VALUE=\"checked\">conjugate<BR>\n";
  print "<INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Process !\"></TD>\n";
  print "<TD ALIGN='RIGHT' VALIGN='MIDDLE'>Mark up for : <BR><FONT SIZE=-2>hold control while clicking<BR>to select multiple values</FONT></TD>";
  print "<TD ALIGN='LEFT'><SELECT NAME=\"mark_up\" MULTIPLE SIZE=4>";
  print "<OPTION></OPTION>";
  print "<OPTION VALUE=\"elegans\">C. elegans</OPTION>";
  print "<OPTION VALUE=\"drosophila\">Drosophila</OPTION>";
  print "<OPTION VALUE=\"arabidopsis\">Arabidopsis</OPTION>";
  print "</SELECT></TD>\n"; 
  print "</TR>";
  print "<TR>";
  $raw_data =~ s/\n/<BR>\n/g;
  print "<TD COLSPAN=2>Last batch entered :<BR>\n$raw_data</TD>";
  print "<TD ALIGN='CENTER' VALIGN='TOP' COLSPAN=2><INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Save as new file !\"><INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Save and overwrite this file !\"></TD></TR><BR><BR>\n";
  print "</TABLE>\n";
} # sub create

sub firstPage {
  my $date = &getDate();
  print "$date<BR>\n";
  print "<FORM METHOD=\"POST\" ACTION=\"http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/categories_ontology.cgi\">\n";
  print "<TABLE>\n";
  print "<TR><TD>Select your Name among : </TD><TD><SELECT NAME=\"curator_name\" SIZE=5>\n";
  print "<OPTION>Juancarlos Chan</OPTION>\n";
  print "<OPTION>Kimberly Van Auken</OPTION>\n";
  print "<OPTION>Paul Sternberg</OPTION>\n";
  print "</SELECT></TD>\n";
#   print "<TD><INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Curator !\"></TD></TR><BR><BR>\n";
  print "</TABLE>\n";

  print "<TABLE border=0 cellspacing=5>\n";
  print "<TR><TD>Enter the type of ontology you'll generate : <TD><INPUT SIZE=40 NAME=\"file_type\"></TD>\n";
  print "<TD><INPUT TYPE=submit NAME=action VALUE=\"Create !\"></TD>\n";
  print "<TD><INPUT TYPE=submit NAME=action VALUE=\"Select existing !\"></TD></TR>\n";
  print "</FORM>\n";
  print "</TABLE>\n";
} # sub firstPage

### FIRST PAGE ###

sub stemify {
  my $word = shift;
  my @words;
  push @words, $word;
  my $stemmed_words_anon_array = stem(@words);
  my $stem = shift @$stemmed_words_anon_array;
  return $stem;
} # sub stemify

sub conjugatify {
  my @words;
  my $stem = shift;
  if ($stem =~ m/[aeiou]i$/) { $stem =~ s/([aeiou])i$/$1y/; }
  push @words, "$stem" . 'ing';
  push @words, "$stem" . 's';
  push @words, "$stem" . 'ed';
  my $words = join", ", @words;
  return $words;
} # sub conjugatify

sub processWord {
#   my $word = shift;
  my ($word, $pluralize, $capitalize, $conjugate) = @_;
  chomp($word);
  my %result_words; my @result_words;
  $result_words{$word}++;
  my $orig = $word;
  if ($conjugate eq 'checked') {
    if ($irreg{$word}) { 
        my (@words) = split/, /, $irreg{$word}; foreach my $irreg (@words) { $result_words{$irreg}++; } }
      else { 
        my ($stem) = &stemify($word);
        my ($words) = &conjugatify($stem);
        my (@words) = split/, /, $words; foreach my $reg (@words) { $result_words{$reg}++; } } }
  if ($pluralize eq 'checked') {
    my ($plural) = &makeplural($word); $result_words{$plural}++; }
  if ($capitalize eq 'checked') {
#     my ($up_down) = &upanddown($word); $result_words{$up_down}++; 
    foreach my $word (sort keys %result_words) { 
      my ($up_down) = &upanddown($word); $result_words{$up_down}++; } }

#   my ($ud_plural) = &makeplural($up_down); $result_words{$ud_plural}++; 
  foreach my $word (sort keys %result_words) { push @result_words, $word; }
  my $result_words = join"\n", @result_words;
  return $result_words;
} # sub processWord

sub upanddown {
  my $word = shift;
  if ($word =~ /^[a-z]/) { $word =~ s/^([a-z])/\U$1\E/g; }
  elsif ($word =~ /^[A-Z]/) { $word =~ s/^([A-Z])/\L$1\E/g; }
  return $word;
} # sub upanddown

sub makeplural {
  my $word = shift;
  $word =~ s/\s+$//g;
  if ($word =~ /[^eaoui]y$/) {
      $word =~ s/([^eaoui])y$/$1ies/g;
  } elsif ($word =~ /(x|sh|s)$/) {
      $word =~ s/(x|sh|s)$/$1es/g;
  } elsif ($word =~ /[a-z]$/) {
      $word .= 's';
  } 
  return $word;
}

__END__

my %list = ();
while (my $line = <STDIN>) {
    chomp ($line);
    if (!$list{$line}) {
        $list{$line} = 1;
        print $line, "\n";
        print "#####\n";
        my $plural = $line;
        $plural = makeplural($plural);
        if ($plural ne $line) {
            print $plural, "\n";
            print "#####\n";
        }
        if ($line =~ /^[a-z]/) {
            $line =~ s/^([a-z])/\U$1\E/g;
            print $line,"\n";
            print "#####\n";
            my $plural = $line;
            $plural = makeplural($plural);
            if ($plural ne $line) {
                print $plural, "\n";
                print "#####\n";
            }
        }
    }
}

