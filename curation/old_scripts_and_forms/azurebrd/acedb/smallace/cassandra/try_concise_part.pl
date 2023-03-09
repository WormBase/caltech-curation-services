#!/usr/bin/perl -w

# trying to figure out how Michael Paulini is storing stuff for Concise_description evidence in shmace2planb.pl 
# can't tell what  my @e = $g->at('Structured_description.Concise_description[2]');  does, since I can't get 
# anything out of @e that has data.  2014 04 14



use strict;
use diagnostics;
use Ace;
use feature qw(say);

# $class_name = 'Person';
# 
# my $ace_query = "Find $class_name"; 

# my $db = Ace->connect(-path  =>  '/home/acedb/WS_current',
#                       -program => '/home/acedb/bin/tace') || die "Connection failure: ",Ace->error;
# my @ready_names= $db->fetch(-query=>$ace_query);

my $db = Ace->connect(-path  =>  '/home3/acedb/ws/acedb',
                      -program => '/home/acedb/bin/tace') || die "Connection failure: ",Ace->error;

&geneQuery();
# &rnaiQuery();

sub rnaiQuery {
  my $query="find RNAi WBRNAi000000*";
  my @rnai=$db->fetch(-query=>$query);
  foreach my $r (@rnai) {
    my $name = $r;
    my $gene='{}';
    if ($r->Gene){
      $gene='{';
      my @e=$r->at('Inhibits.Gene');
      my @b = map {"'$_': '${\$_->right->asString}'"} @e;
      map {s/\n//g}@b;
      $gene.=join(',',@b);
      $gene.='}';
    }
    print "$r\t$gene\n";
  }
} # sub rnaiQuery


sub geneQuery {
  # my $genIt = $db->fetch_many(-class =>'Gene');
  # while(my $g = $genIt->next){
  #   my $name = $g;
  
  my $query="find Gene WBGene000000*";
  my @genes=$db->fetch(-query=>$query);
  
  foreach my $g (@genes) {
  #   my $rnai='{}';
  #   if ($g->RNAi_result){
  #     $rnai='{';
  #     my @e=$g->at('Experimental_info.RNAi_result');
  #     my @b = map {"'$_': '${\$_->right->asString}'"} @e;
  #     map {s/\n//g}@b;
  #     $rnai.=join(',',@b);
  #     $rnai.='}';
  #   }
  #   print "name $g\tRNAi $rnai\n";
  
    my $conciseDescription=$g->Concise_description||'';
    $conciseDescription=~s/'/''/g;
    my $cDEvidence="{}";
    if ($conciseDescription){
      $cDEvidence='{HEHE';
      my @e = $g->at('Structured_description.Concise_description[2]');
      foreach my $e (@e) { print "$g has E $e : $e->row\n"; }
      my @lines = map {"'".join(" ",$_->right->asString)."'"} @e;
      $cDEvidence.=join(',',@lines);
      $cDEvidence.='}';
    }

    my $provisionalDescription=$g->Provisional_description||'';
    $provisionalDescription=~s/'/''/g;
    my $pVEvidence="{}";
    if ($provisionalDescription){
      $pVEvidence='{HOHO';
      my @e = $g->at('Structured_description.Provisional_description[2]');
      foreach my $e (@e) { print "$g has E $e : $e->row\n"; }
      my @lines = map {"'".join(" ",$_->row)."'"} @e;
      $pVEvidence.=join(',',@lines);
      $pVEvidence.='}';
    }
  
    print "name $g\nConc\t$conciseDescription\tcdEvi $cDEvidence\nProv\t$provisionalDescription\tpvEvi $pVEvidence\n\n";
  }
} # sub geneQuery

# my $query="find Gene WBGene00000*";
# my @genes=$db->fetch(-query=>$query);
# 
# foreach my $object (@genes) {
#   print $object->asString;
#   print "\n\n";
# #   my ($geneid) = $object =~ m/(\d+)/;
# #   foreach my $tag (@tags) {
# #     my @b = $object->$tag;
# #     foreach my $b (@b) {
# #       $hash{$geneid}{$tag}{$b}++; } }
# } # foreach my $object (@genes)

__END__

my $genIt = $db->fetch_many(-class =>'Gene');
while(my $g = $genIt->next){
  my $name = $g;

  # that is for set<text>
  my $conciseDescription=$g->Concise_description||'';
  $conciseDescription=~s/'/''/g;
  my $cDEvidence="{}";
  if ($conciseDescription){
    $cDEvidence='{';
    my @e = $g->at('Structured_description.Concise_description[2]');
    my @lines = map {"'".join(" ",$_->row)."'"} @e;
    $cDEvidence.=join(',',@lines);
    $cDEvidence.='}';
  }

  print "name $g\tConcise $conciseDescription\tcdEvi $cDEvidence\n";
}

__END__ 

use strict;
use diagnostics;
use CGI;
use Ace;
use OtherModels;
use Jex;

# files
# my $models = "/home/azurebrd/models.wrm";	# not used
my $errorfile = "/home/azurebrd/public_html/cgi-bin/query_builder/error_query";

# globals
# my %models;			# get them from OtherModels.pm
my $tab = 8;			# define a tab as 8 spaces
my $box_size = 1;		# default size of fields in select boxes
my $query = new CGI;
my $firsttime = 1;
my @conditions = ("exists", "does not exist", "contains", "begins with", "ends with", "is equal to", "is not equal to", "is greater than", "is greater than or equal to", "is less than", "is less than or equal to", "COUNT is equal to", "COUNT is not equal to", "COUNT is greater than", "COUNT is greater than or equal to", "COUNT is less than", "COUNT is less than or equal to");
my @conjunctions = ("END", "and", "and subtype", "or", "exclusive or");

# emails

# open (ERR, ">$errorfile") or die "Cannot create $errorfile : $!";

my ($header, $footer) = &cshlNew();

print "Content-type: text/html\n\n";
print $header;
&process();

print $footer;

sub process {
  my $action;
  unless ($action = $query->param('action')) {
    $action = 'none';
  } # unless ($action = $query->param('action'))

  if ($action eq 'none') { &firstProcess(); }
  if ($action eq 'Class !') { &classProcess(); }
  if ($action eq 'Query !') { &queryProcess(); }
} # sub process

sub queryProcess {
  my $oop; my $class_name; my $complexity_number;

  if ( $query->param("complexity_number") ) {
    $oop = $query->param("complexity_number");
  } else { $oop = "1"; }
  $complexity_number = &untaint($oop);

  if ( $query->param("class_name") ) {
    $oop = $query->param("class_name");
  } else { $oop = "1"; }
  $class_name = &untaint($oop);

  print "<TABLE>\n";
  print "<TR>\n";
  print "<TD>Attribute : </TD>";
  print "<TD>Condition : </TD>";
  print "<TD>Value : </TD>";
  print "<TD>Conjunction : </TD>";
  print "</TR>\n";
  $ENV{PATH} = untaint($ENV{PATH});	# Taint will complain otherwise
  my $ace_query = "Find $class_name"; my $condition_type;
  for (my $i = 0, my $j = 1; $i < $complexity_number; $i++, $j++) {
    my $attribute_name = "attr_" . $i;
    if ( $query->param("$attribute_name") ) { $oop = $query->param("$attribute_name"); } 
      else { $oop = ' '; print "ERROR : Missing attribute in query $j<BR>\n"; }
    $attribute_name = untaint($oop);
    if ($attribute_name eq 'ANY') { $attribute_name = ''; }
    my $condition_name = "cond_" . $i;
    if ( $query->param("$condition_name") ) { $oop = $query->param("$condition_name"); } 
      else { $oop = ' '; print "ERROR : Missing condition in query $j<BR>\n"; }
    $condition_name = untaint($oop);
    my $query_value = "valu_" . $i;
    if ( $query->param("$query_value") ) { $oop = $query->param("$query_value"); } 
      else { $oop = ' ' }
    $query_value = untaint($oop); 
    if ($condition_name eq 'exists') { $ace_query .= " $attribute_name"; }
    elsif ($condition_name eq 'does not exist') { $ace_query .= " ! $attribute_name"; }
    elsif ($condition_name eq 'contains') { $ace_query .= " $attribute_name = \*$query_value\*"; }
    elsif ($condition_name eq 'begins with') { $ace_query .= " $attribute_name = $query_value\*"; }
    elsif ($condition_name eq 'ends with') { $ace_query .= " $attribute_name = \*$query_value"; }
    elsif ($condition_name eq 'is equal to') { $ace_query .= " $attribute_name = $query_value"; }
    elsif ($condition_name eq 'is not equal to') { $ace_query .= " $attribute_name != $query_value"; }
    elsif ($condition_name eq 'is greater than') { $ace_query .= " $attribute_name > $query_value"; }
    elsif ($condition_name eq 'is greater than or equal to') { $ace_query .= " $attribute_name >= $query_value"; }
    elsif ($condition_name eq 'is less than') { $ace_query .= " $attribute_name < $query_value"; }
    elsif ($condition_name eq 'is less than or equal to') { $ace_query .= " $attribute_name <= $query_value"; }
    elsif ($condition_name eq 'COUNT is equal to') { $ace_query .= " COUNT $attribute_name = $query_value"; }
    elsif ($condition_name eq 'COUNT is not equal to') { $ace_query .= " COUNT $attribute_name != $query_value"; }
    elsif ($condition_name eq 'COUNT is greater than') { $ace_query .= " COUNT $attribute_name > $query_value"; }
    elsif ($condition_name eq 'COUNT is greater than or equal to') { $ace_query .= " COUNT $attribute_name >= $query_value"; }
    elsif ($condition_name eq 'COUNT is less than') { $ace_query .= " COUNT $attribute_name < $query_value"; }
    elsif ($condition_name eq 'COUNT is less than or equal to') { $ace_query .= " COUNT $attribute_name <= $query_value"; }
    else { 1; }
    my $conjunction_name = "conj_" . $i;
    if ( $query->param("$conjunction_name") ) { $oop = $query->param("$conjunction_name"); } 
      else { $oop = ' '; print "ERROR : Missing conjunction in query $j<BR>\n"; }
    $conjunction_name = untaint($oop);
    if ($conjunction_name eq 'and') { $ace_query .= " & "; }
    elsif ($conjunction_name eq 'or') { $ace_query .= " | "; }
    elsif ($conjunction_name eq 'exclusive or') { $ace_query .= " ^ "; }
    else { 1; }
    print "<TR><TD>$attribute_name</TD><TD>$condition_name</TD><TD>$query_value</TD><TD>$conjunction_name</TD></TR>";
    if ($conjunction_name eq 'END') { last; }
  } # for (my $i = 0; $i < $complexity_number; $i++)
  print "</TABLE>\n";
  print "Query : <FONT COLOR=green>$ace_query</FONT> has : <FONT color=green>";
  my $db = Ace->connect(-path  =>  '/home/acedb/WS_current',
                        -program => '/home/acedb/bin/tace') || die "Connection failure: ",Ace->error;
  my @ready_names= $db->fetch(-query=>$ace_query);
  print scalar(@ready_names) . "</FONT> results<BR>\n";
  foreach (@ready_names) { print "<A HREF=\"http://www.wormbase.org/db/searches/basic?class=$class_name&query=$_\">$_</A><BR>\n"; }
} # sub queryProcess

sub classProcess {
  my $oop; my $class_name; my $complexity_number;

  if ( $query->param("complexity_number") ) {
    $oop = $query->param("complexity_number");
  } else { $oop = "1"; }
  $complexity_number = &untaint($oop);

  if ( $query->param("box_size") ) {
    $oop = $query->param("box_size");
  } else { $oop = "1"; }
  $box_size = &untaint($oop);

  if ( $query->param("class_name") ) {
    $oop = $query->param("class_name");
    my $class = &untaint($oop);
    $class_name = $class;
  } else { $oop = "1"; }
  if ($class_name eq '1') { print "ERROR : bad Class<BR>\n"; }
  else { 
    print "<FORM METHOD=\"POST\" ACTION=\"http://tazendra.caltech.edu/~azurebrd/cgi-bin/query_builder/query_builder.cgi\">";
    if ($class_name eq '') { print "<H2>ERROR : Must select a class name</H2>"; }
    else { print "<H2>Class : $class_name</H2>"; }
    print "<TABLE>\n";
    print "<TR>\n";
    print "<TD>Attribute : </TD>";
    print "<TD>Condition : </TD>";
    print "<TD>Value : </TD>";
    print "<TD>Conjunction : </TD>";
    print "</TR>\n";
    print "<INPUT TYPE=\"hidden\" NAME=\"class_name\" VALUE=\"$class_name\">\n";
    print "<INPUT TYPE=\"hidden\" NAME=\"complexity_number\" VALUE=\"$complexity_number\">\n";

    for (my $i = 0; $i < $complexity_number; $i++) {
      print "<TR>\n";
#       print "<TD>Class : $class_name</TD>";
#       print "<TD>Attribute : </TD>";
      my $attribute_name = "attr_" . $i;
      print "<TD><SELECT NAME=\"$attribute_name\" SIZE=$box_size> \n";
      print "<OPTION>ANY</OPTION>\n";
      foreach (@{ $models{$class_name} }) {
        print "<OPTION>$_</OPTION>\n";
      } # foreach (@{ $models{$class_name} })
      print "</SELECT></TD>";
#       print "<TD>Condition : </TD>";
      my $condition_name = "cond_" . $i;
      print "<TD><SELECT NAME=\"$condition_name\" SIZE=$box_size> \n";
      foreach (@conditions) {
        print "<OPTION>$_</OPTION>\n";
      } # foreach (@condition)
      print "</SELECT></TD>";
      my $query_value = "valu_" . $i;
      print "<TD><INPUT NAME=\"$query_value\" SIZE=\"20\"></TD>";
#       print "<TD>Conjunction : </TD>";
      my $conjunction_size = 5; 
      my $conjunction_name = "conj_" . $i;
      if ($conjunction_size > $box_size) { $conjunction_size = $box_size; }
      print "<TD><SELECT NAME=\"$conjunction_name\" SIZE=$conjunction_size> \n";
      foreach (@conjunctions) {
        print "<OPTION>$_</OPTION>\n";
      } # foreach (@conjunctions)
      print "</SELECT></TD>";
      print "</TR>\n";
    } # for (my $i = 0; $i < $complexity_number; $i++)

    print "<TR>\n";
    print "<TD><INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Query !\"></TD><BR><BR>\n";
    print "</TR>\n";
    print "</TABLE>\n";
    print "</FORM>\n";
  } # else # if ($class_name eq '1')
} # sub classProcess

sub firstProcess {
  print "<FORM METHOD=\"POST\" ACTION=\"http://tazendra.caltech.edu/~azurebrd/cgi-bin/query_builder/query_builder.cgi\">";
  print "<TABLE>\n";
  my $number = scalar( keys %models );
  print "<TR>";
#   print "<TD>Degree of query complexity ?</TD>\n";
  print "<TD>Number of terms in Query ?</TD>\n";
  print "<TD><INPUT NAME=\"complexity_number\" VALUE=\"1\" SIZE=\"5\"></TD>";
  print "<TD>Select your Class among : </TD><TD><SELECT NAME=\"class_name\" SIZE=$number> \n";
  foreach (sort keys %models) {
    print "<OPTION>$_</OPTION>\n";
  } # foreach (sort keys %models)
  print "</SELECT></TD>";
  print "<TD><INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Class !\"></TD><BR><BR>\n";
  print "</TR>";
  print "<TR><TD>&nbsp;</TD></TR>";
  print "<TR>";
  print "<TD>Optional : amount of fields in menus</TD>";
  print "<TD><INPUT NAME=\"box_size\" VALUE=\"$box_size\" SIZE=\"5\"></TD>";
  print "</TR>";
  print "</TABLE>\n";
  print "</FORM>\n";
} # sub firstProcess


