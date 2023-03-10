#!/usr/bin/perl -w

# populate poo_ tables (phenotype ontology obo)  for allele.cgi and future phenote for Jolene  2009 06 09
#
# only include specific tags.
# these are different postgres tables from the OA asyncTermInfo (for some reason, 
# possibly should be merged but right now it's good that they're showing different 
# things).  2009 12 15
#
# added to daily cronjob at 3am :
# 0 3 * * * /home/postgres/work/pgpopulation/phenont_obo/pop_phenont_obo.pl


use strict;
use diagnostics;
use DBI;
use LWP::Simple;


__END__

# This poo_ tables no longer seem necessary since we have the obo_ tables instead.  replacing this script with a script to get phenont from spica

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my $page = get "http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/phenotype_ontology_obo.cgi";

my (@text) = split/./, $page;
my $textsize = scalar(@text);
die if ($textsize < 10000);
die if ($page =~ m/Error 404/);


my (@terms) = split/\n\n/, $page;
shift @terms;

my $result = $dbh->do( "DELETE FROM poo_name" );
$result = $dbh->do( "DELETE FROM poo_data" );
$result = $dbh->do( "DELETE FROM poo_syn" );
$result = $dbh->do( "DELETE FROM poo_id" );

my %ids;
foreach my $term (@terms) {
  my ($id) = $term =~ m/id: WBPhenotype:(\d+)/;
  next unless ($id);
  if ($ids{$id}) { print "Duplicate $id\n"; }
  $ids{$id}++;
  my @lines = split/\n/, $term;
  my $data; my @syns; my $name;
  foreach my $line (@lines) {
    next unless $line;
    next if ($line eq '[Term]');
    if ($data) { $data .= "\n$line"; }
      else { $data = "$line"; }
    if ($line =~ m/^name: (.*)/) { $name = $1; }
    if ($line =~ m/^synonym: \"([^\"]*)\"/) { push @syns, $1; }
  } # foreach my $line (@lines)
#   print "ID\t$id\n";
  $result = $dbh->do( "INSERT INTO poo_id VALUES ('$id', '$id')" );
  ($name) = &filterForPg($name);
  $result = $dbh->do( "INSERT INTO poo_name VALUES ('$id', '$name')" );
#   print "NAME\t$name\n";
  foreach my $syn (@syns) { 
    ($syn) = &filterForPg($syn);
#     print "SYN\t$syn\n"; 
    $result = $dbh->do( "INSERT INTO poo_syn VALUES ('$id', '$syn')" );
  } # foreach my $syn (@syns) 
#   print "DATA\t$data\n";
  ($data) = &filterForPg($data);
  my (@data) = split/\n/, $data; $data = '';
  foreach my $line (@data) {
    if ( ($line =~ m/^id:/) || ($line =~ m/^name:/) || ($line =~ m/^def:/) || ($line =~ m/^synonym:/)
      || ($line =~ m/^relationship:/) || ($line =~ m/^is_a:/) ) { $data .= "$line\n"; } }
  $result = $dbh->do( "INSERT INTO poo_data VALUES ('$id', '$data')" );
} # foreach my $term (@terms)


sub filterForPg {
  my $value = shift;
  if ($value =~ m/\'/) { $value =~ s/\'/''/g; }
  return $value;
} # sub filterForPg



__END__

my $result = $dbh->prepare( 'SELECT * FROM two_comment WHERE two_comment ~ ?' );
$result->execute('elegans') or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[1] =~ s///g;
    $row[2] =~ s///g;
    print "$row[0]\t$row[1]\t$row[2]\n";
  } # if ($row[0])
} # while (@row = $result->fetchrow)

__END__
