#!/usr/bin/env perl

# validate ontology data in OAs

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

use Dotenv -load => '/usr/lib/.env';

my $dbh = DBI->connect ( "dbi:Pg:dbname=$ENV{PSQL_DATABASE};host=$ENV{PSQL_HOST};port=$ENV{PSQL_PORT}", "$ENV{PSQL_USERNAME}", "$ENV{PSQL_PASSWORD}") or die "Cannot connect to database!\n";
# my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %ont;

my @obos = qw( anatomy phenotype humando soid goid goidprocess goidfunction goidcomponent lifestage quality );

foreach my $obo_type (@obos) {
  $result = $dbh->prepare( "SELECT joinkey FROM obo_data_${obo_type} WHERE obo_data_${obo_type} ~ 'is_obsolete: true'" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    if ($row[0]) { 
      $ont{$obo_type}{$row[0]}{exists}++;
      $ont{$obo_type}{$row[0]}{obsolete}++; } } 
  $result = $dbh->prepare( "SELECT joinkey FROM obo_data_${obo_type} WHERE obo_data_${obo_type} !~ 'is_obsolete: true'" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    if ($row[0]) { 
      $ont{$obo_type}{$row[0]}{exists}++;
      $ont{$obo_type}{$row[0]}{valid}++; } } 
}  


my %tables;			# pg table to ontology table

$tables{'app'}{'anatomy'} = 'anatomy';
$tables{'app'}{'child_of'} = 'phenotype';
$tables{'app'}{'term'} = 'phenotype';
$tables{'app'}{'goprocess'} = 'goidprocess';
$tables{'app'}{'gofunction'} = 'goidfunction';
$tables{'app'}{'gocomponent'} = 'goidcomponent';
$tables{'app'}{'gocomponentquality'} = 'quality';
$tables{'app'}{'gofunctionquality'} = 'quality';
$tables{'app'}{'goprocessquality'} = 'quality';
$tables{'app'}{'lifestage'} = 'lifestage';
$tables{'app'}{'lifestagequality'} = 'quality';
$tables{'app'}{'molaffectedquality'} = 'quality';

$tables{'exp'}{'anatomy'}         = 'anatomy';
$tables{'exp'}{'goid'}            = 'goid';
$tables{'exp'}{'granatomy'}       = 'anatomy';
$tables{'exp'}{'grcellcycle'}     = 'goid';
$tables{'exp'}{'grlifestage'}     = 'lifestage';
$tables{'exp'}{'lifestage'}       = 'lifestage';
$tables{'exp'}{'qualifierls'}     = 'lifestage';

$tables{'gop'}{'goid'}            = 'goid';
$tables{'gop'}{'with_phenotype'}  = 'phenotype';

$tables{'grg'}{'anatomy'}         = 'anatomy';
$tables{'grg'}{'lifestage'}       = 'lifestage';

$tables{'pic'}{'goid'}            = 'goid';
$tables{'pic'}{'anat_term'}       = 'anatomy';
$tables{'pic'}{'lifestage'}       = 'lifestage';
$tables{'pic'}{'phenotype'}       = 'phenotype';

$tables{'pro'}{'anatomy'}         = 'anatomy';
$tables{'pro'}{'humdisease'}      = 'humando';
$tables{'pro'}{'lifestage'}       = 'lifestage';
$tables{'pro'}{'phenotype'}       = 'phenotype';

$tables{'prt'}{'goid'}            = 'goid';

$tables{'rna'}{'anatomy'} = 'anatomy';
$tables{'rna'}{'child_of'} = 'phenotype';
$tables{'rna'}{'phenotype'} = 'phenotype';
$tables{'rna'}{'goprocess'} = 'goidprocess';
$tables{'rna'}{'gofunction'} = 'goidfunction';
$tables{'rna'}{'gocomponent'} = 'goidcomponent';
$tables{'rna'}{'gocomponentquality'} = 'quality';
$tables{'rna'}{'gofunctionquality'} = 'quality';
$tables{'rna'}{'goprocessquality'} = 'quality';
$tables{'rna'}{'lifestage'} = 'lifestage';
$tables{'rna'}{'lifestagequality'} = 'quality';
$tables{'rna'}{'molaffectedquality'} = 'quality';

# $tables{'sqf'}{'soterm'}           = 'soid';	# sqf data is read only, we don't need to fix it

$tables{'trp'}{'humandoid'}      = 'humando';

foreach my $oa (sort keys %tables) {
  my $outfile = $oa;
  open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
  foreach my $table (sort keys %{ $tables{$oa}}) {
    my $ontology = $tables{$oa}{$table};
    $result = $dbh->prepare( "SELECT * FROM ${oa}_${table}" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) {
      next unless ($row[1]);
      next if ($row[1] eq '""');
      next if ($row[1] eq '');
      my $data = $row[1];
      my @data;
      if ($data =~ m/^\"/) { $data =~ s/^\"//;  }
      if ($data =~ m/\"$/) { $data =~ s/\"$//;  }
      if ($data =~ m/\",\"/) { (@data) = split/\",\"/, $data; }
        else { push @data, $data; }
      my $row = join"\t", @row;
      foreach my $entry (@data) {
        if ($ont{$ontology}{$entry}{exists}) {
            if ($ont{$ontology}{$entry}{valid}) { 1; }
              elsif ($ont{$ontology}{$entry}{obsolete}) { print OUT qq(${oa}_${table}\tobsolete\t$entry\t$row\n); } }
          else {
            print OUT qq(${oa}_${table}\tinvalid\t$entry\t$row\n); }
      }
    } 
  }
  close (OUT) or die "Cannot close $outfile : $!";
} 
