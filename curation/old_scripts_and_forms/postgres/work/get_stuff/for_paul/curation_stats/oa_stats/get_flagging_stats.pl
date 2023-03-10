#!/usr/bin/perl -w

# look at afp / cfp / svm results for datatypes that correspond to OA datatypes, 
# and gives paper counts for each datatype for  
# 1) combination of curator FP + author FP + all SVM not-Negative   
# 2) curator FP + author FP   
# 3) all SVM not-Negative
#
# for Paul 2012 09 17


use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

# I think newmutant is phenotype
# no concise, no gene class, no gene ontology, no picture, no process, no process term
# no molecule (or is it chemicals ?)

  my %datatypeName;
  $datatypeName{'antibody'}   = 'antibody';
  $datatypeName{'newmutant'}  = 'phenotype';
  $datatypeName{'expression'} = 'expression';
  $datatypeName{'genereg'}    = 'gene_regulation';
  $datatypeName{'geneint'}    = 'interaction';
  $datatypeName{'rnai'}       = 'rnai';
  $datatypeName{'transgene'}  = 'transgene';

  my %svmName;
  $svmName{'otherexpr'} = 'expression';
  $svmName{'overexpr'}  = 'phenotype';
  $svmName{'newmutant'} = 'phenotype';
  $svmName{'antibody'}  = 'antibody';
  $svmName{'genereg'}   = 'gene_regulation';
  $svmName{'geneint'}   = 'interaction';
  $svmName{'rnai'}      = 'rnai';

my %data;
foreach my $datatype (sort keys %datatypeName) {
  my $reportName = $datatypeName{$datatype};
  my $table = 'afp_' . $datatype;
  $result = $dbh->prepare( "SELECT DISTINCT(joinkey) FROM $table " );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { if ($row[0]) { $data{$reportName}{$row[0]}++; } }
  next if ($datatype eq 'expression');		# no expression for cfp_ tables
  $table = 'cfp_' . $datatype;
  $result = $dbh->prepare( "SELECT DISTINCT(joinkey) FROM $table " );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { if ($row[0]) { $data{$reportName}{fp}{$row[0]}++; $data{$reportName}{all}{$row[0]}++; } }
} # foreach my $datatype (sort keys %datatypeName)

foreach my $datatype (sort keys %svmName) {
  my $reportName = $svmName{$datatype};
  $result = $dbh->prepare( "SELECT DISTINCT(cur_paper) FROM cur_svmdata WHERE cur_datatype = '$datatype' AND cur_svmdata != 'NEG' " );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { if ($row[0]) { $data{$reportName}{svm}{$row[0]}++; $data{$reportName}{all}{$row[0]}++; } }
} # foreach my $datatype (sort keys %svmName)

foreach my $name (sort keys %data) {
  my $countFp  = scalar keys %{ $data{$name}{fp} };
  my $countSvm = scalar keys %{ $data{$name}{svm} };
  my $countAll = scalar keys %{ $data{$name}{all} };
  print "$name\tall $countAll\tFp $countFp\tsvm $countSvm\n";
} # foreach my $name (sort keys %data)

__END__


# my @intervals = ( '1 week', '5 weeks', '1 year', '2 years', '3 years', '4 years', '5 years', '99 years' );
my @intervals = ( '1 week', '99 years' );
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

