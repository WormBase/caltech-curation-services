#!/usr/bin/perl -w

# generate cytoscape data based on two_lineage info, manually read into code.js  2016 06 23

# test looping through to find all nodes and a count of how many descendants each has.  2016 07 01

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );
use Clone 'clone';


my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %nodes;
my %edges;
my %relationship;
my %twos;
# $result = $dbh->prepare( "SELECT * FROM two_lineage WHERE (two_role = 'Phd' OR two_role = 'Postdoc' OR two_role = 'Undergrad' OR two_role = 'Masters') AND joinkey ~ 'two' AND two_number ~ 'two'" );
# $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
# while (my @row = $result->fetchrow) {
#   my ($joinkey, $two_sentname, $two_othername, $two_number, $two_role, @other) = @row;
#   $two_sentname =~ s/\'//g;
#   $two_othername =~ s/\'//g;
#   $nodes{$joinkey} = $two_sentname;
#   $nodes{$two_number} = $two_othername;
#   $edges{$joinkey}{$two_number}++;
# }


      $result = $dbh->prepare( "SELECT * FROM two_lineage WHERE (two_role = 'Phd' OR two_role = 'Postdoc' OR two_role = 'Undergrad' OR two_role = 'Masters') AND joinkey ~ 'two' AND two_number ~ 'two'" );
#       $result = $dbh->prepare( "SELECT * FROM two_lineage WHERE (two_role = 'Masters') AND joinkey ~ 'two' AND two_number ~ 'two'" );
      $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
      while (my @row = $result->fetchrow) {
        my ($joinkey, $two_sentname, $two_othername, $two_number, $relationship, @other) = @row;
        $two_sentname =~ s/\'//g;
        $two_othername =~ s/\'//g;
        $twos{$row[0]}++;
        $twos{$row[3]}++;
        my ($parent, $child) = ($joinkey, $two_number);
#         $nodes{$joinkey} = $two_sentname;
#         $nodes{$two_number} = $two_othername;
#         if ($relationship =~ m/with/) { $relationship =~ s/with//; $relationship{$two_number}{$joinkey}{$relationship}++; $edges{$two_number}{$joinkey}++; }
#           else { $relationship{$joinkey}{$two_number}{$relationship}++; $edges{$joinkey}{$two_number}++; }
        if ($relationship =~ m/with/) { $relationship =~ s/with//; ($child, $parent) = ($joinkey, $two_number); }
        next if ($relationship{$child}{$parent}{$relationship});		# skip if exists backwards
        $relationship{$parent}{$child}{$relationship}++; $edges{$relationship}{$parent}{$child}++;
        $nodes{$parent}++; $nodes{$child}++;
      }
      my %scaling; foreach my $node (sort keys %nodes) { $scaling{$node}++; }
      my %hasChild;
#       my %edgeClone = clone( %relationship );
      foreach my $relationship (sort keys %edges) {
        while (scalar keys %{ $edges{$relationship} } > 0) {
          foreach my $one (sort keys %{ $edges{$relationship} }) {
  print qq(OUTER FE $one\n);
            foreach my $two (sort keys %{ $edges{$relationship}{$one} }) {
  print qq(MIDDLE FE $two\n);
if ($one eq 'two625') { print qq(SCALING ONE $one $scaling{$one}\n); }
if ($two eq 'two625') { print qq(SCALING TWO $two $scaling{$two}\n); }
              unless (scalar keys %{ $edges{$relationship}{$two}} > 0) {
  print qq(TWO $two has no children\n);
                if ($scaling{$two}) { $scaling{$one} += $scaling{$two}; 
}
                  else { $scaling{$one}++; }
if ($one eq 'two625') { print qq(SCALING ADDED ONE $one $scaling{$one}\n); }
                delete $edges{$relationship}{$one}{$two};
                delete $edges{$relationship}{$two};
  print qq(REMOVING child $two OF $one\n);
                unless (scalar keys %{ $edges{$relationship}{$one}} > 0) { delete $edges{$relationship}{$one}; 
  print qq(REMOVING parent $one\n);
  }
              }
            } # foreach my $two (sort keys %{ $edges{$one} })
          } # foreach my $one (sort keys %edges)
        } # while (scalar keys %edges > 0)
      }# foreach my $relationship (sort keys %edges)
      foreach my $node (sort keys %scaling) {
print qq($node\t$scaling{$node}\n);
      } # foreach my $node (sort keys %scaling)


# my @nodes;
# my @edges;
# foreach my $node (sort keys %nodes) {
#   push @nodes, qq({ data: { id: '$node', name: '$nodes{$node}' } }); }
# my $nodes = join",\n", @nodes;
# print qq(elements: {\n  nodes: [\n$nodes\n],\n);
# foreach my $e1 (sort keys %edges) {
#   foreach my $e2 (sort keys %{ $edges{$e1} }) {
#     push @edges, qq({ data: { source: '$e1', target: '$e2' } }); } }
# my $edges = join",\n", @edges;
# print qq(  edges: [\n$edges\n]\n},\n);

