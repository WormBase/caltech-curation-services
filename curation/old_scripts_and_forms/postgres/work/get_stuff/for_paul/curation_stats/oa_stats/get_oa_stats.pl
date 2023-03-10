#!/usr/bin/perl -w

# for a set of intervals, loop through all datatypes in the OA, getting counts of papers and objects.
# for Paul.  2012 09 17

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;


  my %datatypeName;
  $datatypeName{'abp'} = 'antibody';
  $datatypeName{'app'} = 'phenotype';
  $datatypeName{'con'} = 'concise';
  $datatypeName{'exp'} = 'expression';
  $datatypeName{'gcl'} = 'gene_class';
  $datatypeName{'gop'} = 'go';
  $datatypeName{'grg'} = 'gene_regulation';
  $datatypeName{'int'} = 'interaction';
  $datatypeName{'mop'} = 'molecule';
  $datatypeName{'pic'} = 'picture';
  $datatypeName{'pro'} = 'process';
  $datatypeName{'prt'} = 'process_term';
  $datatypeName{'rna'} = 'rnai';
  $datatypeName{'trp'} = 'transgene';
  $datatypeName{'all'} = 'all_datatypes';

  my %fields;
  $fields{abp}{name}{label}                          = 'Name';
  $fields{abp}{paper}{ontology_type}                 = 'WBPaper';
  $fields{app}{variation}{type}                      = 'ontology';
  $fields{app}{transgene}{type}                      = 'ontology';
  $fields{app}{strain}{type}                         = 'text';
  $fields{app}{rearrangement}{type}                  = 'ontology';
  $fields{app}{paper}{type}                          = 'ontology';
  $fields{con}{wbgene}{type}                         = 'ontology';
  $fields{con}{paper}{ontology_type}                 = 'WBPaper';
  $fields{exp}{name}{type}                           = 'text';
  $fields{exp}{paper}{ontology_type}                 = 'WBPaper';
  $fields{gcl}{name}{type}                           = 'ontology';
  $fields{gcl}{paper}{label}                         = 'WBPaper';
  $fields{gop}{paper}{ontology_type}                 = 'WBPaper';
  $fields{gop}{wbgene}{type}                         = 'ontology';
  $fields{grg}{paper}{type}                          = 'ontology';
  $fields{grg}{name}{type}                           = 'text';
  $fields{int}{name}{type}                           = 'ontology';
  $fields{int}{paper}{ontology_type}                 = 'WBPaper';
  $fields{mop}{paper}{label}                         = 'WBPaper';
  $fields{mop}{publicname}{type}                     = 'bigtext';
  $fields{pic}{paper}{ontology_type}                 = 'WBPaper';
  $fields{pic}{name}{type}                           = 'text';
  $fields{pro}{paper}{type}                          = 'ontology';
  $fields{pro}{process}{type}                        = 'ontology';
  $fields{prt}{processid}{type}                      = 'text';
  $fields{prt}{paper}{type}                          = 'multiontology';
  $fields{rna}{name}{type}                           = 'text';
  $fields{rna}{paper}{type}                          = 'ontology';
  $fields{trp}{name}{type}                           = 'text';
  $fields{trp}{paper}{ontology_type}                 = 'WBPaper';

my @intervals = ( '1 week', '5 weeks', '1 year', '2 years', '3 years', '4 years', '5 years', '99 years' );
# my @intervals = ( '1 week', '15 years' );
my %data;
foreach my $interval (@intervals) {
  foreach my $datatype (sort keys %datatypeName) {
    if ($fields{$datatype}{'paper'}) {
      my $table = $datatype . '_paper';
      my $ts_col = $datatype . '_timestamp';
      $result = $dbh->prepare( "SELECT * FROM $table WHERE $ts_col > now () - interval '$interval'" );
      $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
      while (my @row = $result->fetchrow) {
        if ($row[0]) { 
          my (@papers) = $row[1] =~ m/(WBPaper\d+)/g;
          foreach (@papers) { $data{$datatype}{paper}{$_}++; $data{all}{paper}{$_}++; }
        } # if ($row[0])
      } # while (@row = $result->fetchrow)
 
      foreach my $typeTable (sort keys %{ $fields{$datatype} }) {
        next if ($typeTable eq 'paper');		# paper is not a type
        my $table = $datatype . '_' . $typeTable;
        my $ts_col = $datatype . '_timestamp';
        $result = $dbh->prepare( "SELECT * FROM $table WHERE $ts_col > now () - interval '$interval'" );
        $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
        while (my @row = $result->fetchrow) {
          if ($row[0]) { 
            my @objects;
            if ($row[1] =~ m/\".*\"/g) { (@objects) = $row[1] =~ m/\"(.*)\"/g; } 
              else { push @objects, $row[1]; }
            foreach (@objects) { $data{$datatype}{object}{$_}++; $data{all}{object}{$_}++; }
          } # if ($row[0])
        } # while (@row = $result->fetchrow)
        
      } # foreach my $typeTable (sort keys %{ $fields{$datatype} })
    } # if ($fields{$datatype}{'paper'})
  } # foreach my $datatype (sort keys %datatypeName)
  foreach my $datatype (sort keys %datatypeName) {
    my $countPaper  = scalar keys %{ $data{$datatype}{paper} };
    my $countObject = scalar keys %{ $data{$datatype}{object} };
    print "Interval $interval\tDatatype $datatypeName{$datatype}\tUnique Paper Count $countPaper\tUnique Object Count $countObject\n"; 
  }
} # foreach my $interval (@intervals)




__END__
