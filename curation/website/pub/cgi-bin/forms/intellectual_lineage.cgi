#!/usr/bin/env perl 

# Display of Worm Lineage information.


use strict;
use diagnostics;
# use LWP::Simple;
# use Mail::Mailer;

# my ($header, $footer) = &cshlNew();

use Jex;			# untaint, getHtmlVar, cshlNew
use CGI;
use Fcntl;
use DBI;
use Clone 'clone';

use Dotenv -load => '/usr/lib/.env';

my $dbh = DBI->connect ( "dbi:Pg:dbname=$ENV{PSQL_DATABASE};host=$ENV{PSQL_HOST};port=$ENV{PSQL_PORT}", "$ENV{PSQL_USERNAME}", "$ENV{PSQL_PASSWORD}") or die "Cannot connect to database!\n";
# my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;


my $query = new CGI;


my $action;			# what user clicked
unless ($action = $query->param('action')) { $action = 'none'; }

my $twonumber = 'all';
my %relationship; my %twos; my %standardname;
my %children; my %parents;
my %scaling; 
# $action = 'lineage';
if ($action eq 'lineage') {
  my ($var, $twonum) = &getHtmlVar($query, 'twonumber');
# $twonum = 'two625';
  if ($twonum) {
#     if ($twonum =~ m/two\d+/) {
#       $twonumber = $twonum; 
#       $result = $dbh->prepare( "SELECT * FROM two_lineage WHERE joinkey = '$twonumber' AND joinkey ~ 'two' AND two_number ~ 'two' AND two_role !~ 'Unknown'");
#       $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
#       while (my @row = $result->fetchrow) {
#         $twos{$row[0]}++;
#         $twos{$row[3]}++;
#         my $relationship = $row[4];
#         if ($relationship =~ m/with/) { $relationship =~ s/with//; $relationship{$row[3]}{$row[0]}{$relationship}++; }
#           else { $relationship{$row[0]}{$row[3]}{$relationship}++; }
#       } # while (@row = $result->fetchrow)
#       $result = $dbh->prepare( "SELECT * FROM two_lineage WHERE two_number = '$twonumber' AND two_number ~ 'two' AND joinkey ~ 'two' AND two_role !~ 'Unknown'");
#       $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
#       while (my @row = $result->fetchrow) {
#         next if ($row[4] =~ m/Collaborated/);
#         $twos{$row[0]}++;
#         $twos{$row[3]}++;
#         my $relationship = $row[4];
#         if ($relationship =~ m/with/) { $relationship =~ s/with//; $relationship{$row[3]}{$row[0]}{$relationship}++; }
#           else { $relationship{$row[0]}{$row[3]}{$relationship}++; }
#       } # while (@row = $result->fetchrow)
#     } else {
      my %nodes;
      my %edges;
#  Assistant_professor     |    20
#  Highschool              |    26
#  Sabbatical              |    49
#  PhD                     |   113
#  Lab_visitor             |   189
#  Research_staff          |   360
#  Masters                 |   405
#  Unknown                 |   411
#  Undergrad               |   428
#  Collaborated            |   958
#  Postdoc                 |  1854
#  Phd                     |  1933

#       $result = $dbh->prepare( "SELECT * FROM two_lineage WHERE joinkey ~ 'two' AND two_number ~ 'two' AND two_role !~ 'with'" );
      $result = $dbh->prepare( "SELECT * FROM two_lineage WHERE (two_role = 'Phd' OR two_role = 'Postdoc' OR two_role = 'Undergrad' OR two_role = 'Masters' OR two_role = 'Research_staff' OR two_role = 'Lab_visitor' OR two_role = 'Sabbatical' OR two_role = 'Highschool' OR two_role = 'Assistant_professor' OR two_role = 'Undergrad') AND joinkey ~ 'two' AND two_number ~ 'two'" );
#       $result = $dbh->prepare( "SELECT * FROM two_lineage WHERE (two_role = 'Phd' OR two_role = 'Postdoc' OR two_role = 'Undergrad' OR two_role = 'Masters' OR two_role = 'Research_staff' OR two_role = 'Lab_visitor' OR two_role = 'Sabbatical' OR two_role = 'Highschool' OR two_role = 'Assistant_professor' OR two_role = 'Undergrad' OR two_role = 'Collaborated') AND joinkey ~ 'two' AND two_number ~ 'two'" );
#       $result = $dbh->prepare( "SELECT * FROM two_lineage WHERE (two_role = 'Phd' OR two_role = 'Postdoc' OR two_role = 'Undergrad' OR two_role = 'Masters') AND joinkey ~ 'two' AND two_number ~ 'two'" );
#       $result = $dbh->prepare( "SELECT * FROM two_lineage WHERE (two_role = 'Masters') AND joinkey ~ 'two' AND two_number ~ 'two'" );
      $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
      while (my @row = $result->fetchrow) {
        my ($joinkey, $two_sentname, $two_othername, $two_number, $relationship, @other) = @row;
        $two_sentname =~ s/\'//g;
        $two_othername =~ s/\'//g;
# next unless ($row[0] =~ m/two2/);
        if ($row[0] =~ m/twotwo/) { $row[0] =~ s/twotwo/two/; }
        if ($row[3] =~ m/twotwo/) { $row[3] =~ s/twotwo/two/; }
        $twos{$row[0]}++;
        $twos{$row[3]}++;
        my ($parent, $child) = ($joinkey, $two_number);
        if ($relationship =~ m/with/) { $relationship =~ s/with//; ($child, $parent) = ($joinkey, $two_number); }
        next if ($relationship{$child}{$parent}{$relationship});                # skip if exists backwards
        $relationship{$parent}{$child}{$relationship}++; 		# if showing full graph, %relationship has all edges
        $edges{$relationship}{$parent}{$child}++;			# store edges again to calculate scaling
        $children{$parent}{$child}{$relationship}++; $parents{$child}{$parent}{$relationship}++; 	# store parents and children for individuals's graph
        $nodes{$parent}++; $nodes{$child}++;
      }
      foreach my $node (sort keys %nodes) { $scaling{$node}++; }
      my %hasChild;
# print qq(BLA1\n);
      foreach my $relationship (sort keys %edges) {
next unless ( ($relationship eq 'Phd') || ($relationship eq 'Postdoc') || ($relationship eq 'Undergrad') || ($relationship eq 'Masters') );
        while (scalar keys %{ $edges{$relationship} } > 0) {
# print qq(WHILE $relationship\n);
          foreach my $one (sort keys %{ $edges{$relationship} }) {
# print qq(WHILE $relationship O $one\n);
            foreach my $two (sort keys %{ $edges{$relationship}{$one} }) {
# print qq(WHILE $relationship O $one T $two\n);
              unless (scalar keys %{ $edges{$relationship}{$two}} > 0) {
#                 if ( ($relationship eq 'Phd') || ($relationship eq 'Postdoc') || ($relationship eq 'Undergrad') || ($relationship eq 'Masters') ) {
#                   if ($scaling{$two}) { $scaling{$one} += $scaling{$two}; }
#                     else { $scaling{$one}++; }
#                 }
                if ($scaling{$two}) { $scaling{$one} += $scaling{$two}; }
                  else { $scaling{$one}++; }
                delete $edges{$relationship}{$one}{$two};
# print qq(DELETE $relationship O $one T $two E\n);
                delete $edges{$relationship}{$two};
# print qq(DELETE $relationship T $two E\n);
                unless (scalar keys %{ $edges{$relationship}{$one}} > 0) { delete $edges{$relationship}{$one}; 
# print qq(DELETE $relationship O $one E\n);
}
# print qq(R $relationship O $one T $two E\n);
              }
            } # foreach my $two (sort keys %{ $edges{$one} })
          } # foreach my $one (sort keys %edges)
        } # while (scalar keys %edges > 0)
      } # foreach my $relationship (sort keys %edges)
# print qq(BLA3\n);
#       foreach my $node (sort keys %scaling) { print qq($node\t$scaling{$node}\n); } 
    if ($twonum =~ m/two\d+/) {
      %relationship = ();
      %twos = (); $twos{$twonum}++;
      &addChildren($twonum);
#       foreach my $child (sort keys %{ $children{$twonum} }) {
#         $twos{$child}++;
#         foreach my $relationship (sort keys %{ $children{$twonum}{$child} }) {
#           $relationship{$twonum}{$child}{$relationship}++; } }
      &addParents($twonum);
#       foreach my $parent (sort keys %{ $parents{$twonum} }) {
#         $twos{$parent}++;
#         foreach my $relationship (sort keys %{ $parents{$twonum}{$parent} }) {
#           $relationship{$parent}{$twonum}{$relationship}++; } }
    }

#     }

    my $twos = join"','", sort keys %twos;
    $result = $dbh->prepare( "SELECT * FROM two_standardname WHERE joinkey IN ('$twos');" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) { $row[2] =~ s/\'//g; $standardname{$row[0]} = $row[2]; }

my $code_js = << "EndOfText";
document.addEventListener('DOMContentLoaded', function(){ // on dom ready

var cy = cytoscape({
  container: document.querySelector('#cy'),
    
  boxSelectionEnabled: false,
  autounselectify: true,
  
  style: cytoscape.stylesheet()
    .selector('node')
      .css({
        'content': 'data(name)',
        'text-valign': 'center',
        'color': 'blue',
        'width': 'data(radius)',
        'height': 'data(radius)',
        'shape':'data(nodeshape)',
        'text-outline-width': 2,
        'backgrund-color': '#999',
        'text-outline-color': '#999',
        'url' : 'data(url)'
      })
    .selector('edge')
      .css({
        'label': 'data(label)',
        'curve-style': 'bezier',
        'target-arrow-shape': 'triangle',
        'target-arrow-color': 'data(lineColor)',
        'line-color': 'data(lineColor)',
        'color': 'data(lineColor)',
        'width': 5
      })
    .selector(':selected')
      .css({
        'background-color': 'black',
        'line-color': 'black',
        'target-arrow-color': 'black',
        'source-arrow-color': 'black'
      })
    .selector('.faded')
      .css({
        'opacity': 0.25,
        'text-opacity': 0
      }),
EndOfText
  
my @nodes; my @edges;
# if ($twonumber eq 'all') {
#   $code_js .= << "EndOfText";
#   elements: {
#     nodes: [
#   { data: { id: 'two10063', name: 'rebecca cheeks' } },
#   { data: { id: 'two15087', name: 'ines carrera' } },
#   { data: { id: 'two10092', name: 'nicolas chartier' } },
#   { data: { id: 'two29317', name: 'yushu chen' } },
#   { data: { id: 'two29318', name: 'yushu pepper' } },
#   { data: { id: 'two29319', name: 'pepper' } },
#   { data: { id: 'two29320', name: 'apepper' } }
#   ],
#     edges: [
#   { data: { source: 'two10063', target: 'two15087' } },
#   { data: { source: 'two10092', target: 'two29317' } },
#   { data: { source: 'two10092', target: 'two29318' } },
#   { data: { source: 'two10092', target: 'two29319' } },
#   { data: { source: 'two10092', target: 'two29320' } }
#   ]
#   },
# EndOfText
# } else {
  my $largestScaling = 0;
  foreach my $two (sort keys %twos) {
    unless ($scaling{$two}) { $scaling{$two} = 1; }
    if ($scaling{$two} > $largestScaling) { $largestScaling = $scaling{$two}; } }
  if ($largestScaling == 1) { $largestScaling = 2; }
  foreach my $two (sort keys %twos) {
#     my $radius = $scaling{$two} * 50;
    my $radius = 25 + log($scaling{$two})/log($largestScaling) * 50;
#     my $radius = 25 + log($scaling{$two} / $largestScaling) * 50;
#     $radius = 25;
    my $nodeshape = 'ellipse'; if ($two eq $twonum) { $nodeshape = 'rectangle'; $radius = 100; }
    # push @nodes, qq({ data: { id: '$two', name: '$standardname{$two}', url: 'http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/intellectual_lineage.cgi?action=lineage&twonumber=$two', radius: '$radius', nodeshape: '$nodeshape', blah: '$two', bleh: '$twonumber' } });
    push @nodes, qq({ data: { id: '$two', name: '$standardname{$two}', url: '$ENV{THIS_HOST}pub/cgi-bin/forms/intellectual_lineage.cgi?action=lineage&twonumber=$two', radius: '$radius', nodeshape: '$nodeshape', blah: '$two', bleh: '$twonumber' } });
  }
  foreach my $source (sort keys %relationship) { 
    foreach my $target (sort keys %{ $relationship{$source} }) { 
      foreach my $relationship (sort keys %{ $relationship{$source}{$target} }) { 
        my $colour = '#ccc';
        if ($relationship eq 'Phd')            { $colour = 'blue';  }
        if ($relationship eq 'Postdoc')        { $colour = 'green'; }
        if ($relationship eq 'Masters')        { $colour = 'cyan';  }
        if ($relationship eq 'Collaborated')   { $colour = 'yellow';  }
        if ($relationship eq 'Undergrad')      { $colour = 'red';  }
        if ($relationship eq 'Research_staff') { $colour = 'orange';  }
        push @edges, qq({ data: { source: '$source', target: '$target', label: '$relationship', lineColor: '$colour' } });  
  } } }
  my $nodes = join",\n", @nodes; 
  my $edges = join",\n", @edges; 
  $code_js .= qq(elements: {\n  nodes: [\n$nodes\n], edges: [\n$edges\n] },\n);
# }


#     name: 'concentric',
#     name: 'dagre',
#     name: 'breadthfirst',
  
$code_js .= << "EndOfText";

  layout: {
    name: 'cose',
    directed: true,
    padding: 10
  }
});

var pos = cy.nodes("#$twonum").position();
cy.zoom({
  level: 1,
  position: pos
});

cy.on('taphold', 'node', function(e){
    var url = this.data('url');
    window.open(url);
});

cy.on('tap', 'node', function(e){
  var node = e.cyTarget; 
  var neighborhood = node.neighborhood().add(node);
  
  cy.elements().addClass('faded');
  neighborhood.removeClass('faded');
});

cy.on('tap', function(e){
  if( e.cyTarget === cy ){
    cy.elements().removeClass('faded');
  }
});

}); // on dom ready
EndOfText

    &printStuff($code_js);


  } # if ($twonum)
} # if ($action eq 'lineage')

sub addParents {
  my $twonum = shift;
  foreach my $parent (sort keys %{ $parents{$twonum} }) {
    $twos{$parent}++;
#     print qq(TWONUM $twonum PARENT $parent END\n); 
    foreach my $relationship (sort keys %{ $parents{$twonum}{$parent} }) {
#     print qq(TWONUM $twonum ADDS $relationship PARENT $parent END\n); 
      delete $parents{$twonum}{$parent}{$relationship};			# prevent going through here again if connection exists through other relationship
      if (scalar keys %{ $parents{$twonum}{$parent} } == 0) { delete $parents{$twonum}{$parent}; }
      if (scalar keys %{ $parents{$twonum} } == 0) { delete $parents{$twonum}; }
      $relationship{$parent}{$twonum}{$relationship}++; }
# uncomment to recurse ancestry
#    &addParents($parent);
  }
}

sub addChildren {
  my $twonum = shift;
  foreach my $child (sort keys %{ $children{$twonum} }) {
#     print qq(TWONUM $twonum CHILD $child END\n); 
    $twos{$child}++;
    foreach my $relationship (sort keys %{ $children{$twonum}{$child} }) {
#     print qq(TWONUM $twonum ADDS $relationship CHILD $child END\n); 
      delete $children{$twonum}{$child};
      $relationship{$twonum}{$child}{$relationship}++; }
# uncomment to recurse descendants
#    &addChildren($child);
  }
}

# recursion failure from Collaboration here
# TWONUM two533 CHILD two1480 END
# TWONUM two533 CHILD two154 END
# TWONUM two533 CHILD two1952 END
# TWONUM two533 CHILD two2126 END
# TWONUM two533 CHILD two2496 END
# TWONUM two533 CHILD two26122 END
# TWONUM two533 CHILD two36 END
# TWONUM two36 CHILD two3392 END
# TWONUM two36 CHILD two3520 END
# TWONUM two36 CHILD two405 END
# TWONUM two36 CHILD two427 END
# TWONUM two36 CHILD two463 END
# TWONUM two36 CHILD two487 END
# TWONUM two36 CHILD two491 END
# TWONUM two36 CHILD two528 END
# TWONUM two36 CHILD two533 END
# TWONUM two533 CHILD two1480 END




sub printStuff {
  my ($code_js) = @_;
  print << "EndOfText";
Content-type: text/html

<!DOCTYPE html>
<html>
<head>
  <meta charset=utf-8 />
  <meta name="viewport" content="user-scalable=no, initial-scale=1.0, minimum-scale=1.0, maximum-scale=1.0, minimal-ui">
  <title>Intellectual Lineage Display</title>
  <script src="http://cytoscape.github.io/cytoscape.js/api/cytoscape.js-latest/cytoscape.min.js"></script>
  <script src="https://cdn.rawgit.com/cpettitt/dagre/v0.7.4/dist/dagre.min.js"></script>
  <script src="https://cdn.rawgit.com/cytoscape/cytoscape.js-dagre/1.1.2/cytoscape-dagre.js"></script>
<script>$code_js</script>

<style>
body { 
  font: 14px helvetica neue, helvetica, arial, sans-serif;
}

#cy {
  height: 100%;
  width: 100%;
  position: absolute;
  left: 0;
  top: 0;
}

#info {
  color: #c88;
  font-size: 1em;
  position: absolute;
  z-index: -1;
  left: 1em;
  top: 1em;
}
</style>
</head>
  
<body>
  <div id="cy"></div>
</body>
</html>
EndOfText
}

