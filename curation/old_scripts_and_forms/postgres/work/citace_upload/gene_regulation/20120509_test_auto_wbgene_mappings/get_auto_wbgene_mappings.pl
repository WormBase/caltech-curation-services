#!/usr/bin/perl -w

# automatically generate grg OA mappings of antibody/exprpattern/transgene to WBGenes  2012 05 09

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my %mappings;
my $result = $dbh->prepare( " SELECT abp_name.joinkey, abp_name.abp_name, abp_gene.abp_gene FROM abp_name, abp_gene WHERE abp_name.joinkey = abp_gene.joinkey; ");
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  my $pgid = $row[0];
  my $antibody = $row[1];
  my $genes = $row[2];
  $genes =~s /^\"//; $genes =~s /\"$//;
  my (@genes) = split/\",\"/, $genes;
  foreach my $gene (@genes) { $mappings{antibody}{$antibody}{$gene}++; } }

$result = $dbh->prepare( " SELECT exp_name.joinkey, exp_name.exp_name, exp_gene.exp_gene FROM exp_name, exp_gene WHERE exp_name.joinkey = exp_gene.joinkey; ");
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  my $pgid = $row[0];
  my $antibody = $row[1];
  my $genes = $row[2];
  $genes =~s /^\"//; $genes =~s /\"$//;
  my (@genes) = split/\",\"/, $genes;
  foreach my $gene (@genes) { $mappings{exprpattern}{$antibody}{$gene}++; } }

$result = $dbh->prepare( " SELECT trp_name.joinkey, trp_name.trp_name, trp_driven_by_gene.trp_driven_by_gene FROM trp_name, trp_driven_by_gene WHERE trp_name.joinkey = trp_driven_by_gene.joinkey; ");
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  my $pgid = $row[0];
  my $antibody = $row[1];
  my $genes = $row[2];
  $genes =~s /^\"//; $genes =~s /\"$//;
  my (@genes) = split/\",\"/, $genes;
  foreach my $gene (@genes) { $mappings{transgene}{$antibody}{$gene}++; } }
$result = $dbh->prepare( " SELECT trp_name.joinkey, trp_name.trp_name, trp_gene.trp_gene FROM trp_name, trp_gene WHERE trp_name.joinkey = trp_gene.joinkey; ");
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  my $pgid = $row[0];
  my $antibody = $row[1];
  my $genes = $row[2];
  $genes =~s /^\"//; $genes =~s /\"$//;
  my (@genes) = split/\",\"/, $genes;
  foreach my $gene (@genes) { $mappings{transgene}{$antibody}{$gene}++; } }


my %grg;
my @grgFields = qw( name antibody exprpattern transgene transregulator transregulated );
foreach my $field (@grgFields) {
  my $table = "grg_$field";
  $result = $dbh->prepare( "SELECT * FROM $table" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    my $pgid = $row[0];
    $row[1] =~s /^\"//; $row[1] =~s /\"$//;
    my (@objs) = split/\",\"/, $row[1];
    foreach my $obj (@objs) {
      $grg{$field}{$pgid}{$obj}++; }
  } # while (@row = $result->fetchrow)
}

&check('antibody');
&check('exprpattern');
&check('transgene');

sub check {
  my ($table) = @_;
  my $tag = 'Expr_pattern';
  if ($table eq 'exprpattern') { $tag = 'Expr_pattern'; }
    elsif ($table eq 'antibody') { $tag = 'Antibody'; }
    elsif ($table eq 'transgene') { $tag = 'Transgene'; }
  foreach my $pgid (sort keys %{ $grg{name} }) {
    my ($name, @junk) = keys %{ $grg{name}{$pgid} };
    my (@antibodies) = keys %{ $grg{$table}{$pgid} };
    foreach my $antibody (@antibodies) {
      next unless ($antibody);
# print "OBJ $antibody\n";
      unless ($mappings{$table}{$antibody}) { 
#         print "ERROR, $table no genes for $antibody with $pgid\n"; 		# do something with antibodies without gene later
        next; }
      my %good = ();
    my (@genes) = sort keys %{ $mappings{$table}{$antibody} };
      foreach my $gene (@genes) {
        if ($grg{transregulator}{$pgid}{$gene}) { $good{$gene}++; }
        if ($grg{transregulated}{$pgid}{$gene}) { $good{$gene}++; }
      } # foreach my $gene (sort keys %{ $mappings{$table}{$antibody} })
      my @good = sort keys %good;
#       if (scalar @good > 1) { print "MULTIPLE $table $name $antibody @good\n"; }	# just to test that multiples work
      if (scalar @good > 0) {
          foreach my $gene (@good) { print "$table\t$name\tInteractor_overlapping_gene\t$gene\t$tag\t$antibody\n"; } }
        else {
          print "ERROR $table $pgid $antibody has @genes, but no gene match in transregulator nor transregulated\n"; }
    } # foreach my $antibody (@antibodies)
  } # foreach my $pgid (sort keys %{ $grg{name} })
}




# my %abp;
# my @abpFields = qw( name gene );
# foreach my $field (@abpFields) {
#   my $table = "abp_$field";
#   my $result = $dbh->prepare( "SELECT * FROM $table" );
#   $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
#   while (my @row = $result->fetchrow) {
#     my $pgid = $row[0];
#     $row[1] =~s /^\"//; $row[1] =~s /\"$//;
#     my (@objs) = split/\",\", $row[1];
#     foreach my $obj (@objs) {
#       $abp{$field}{$pgid}{$obj}++; }
#   } # while (@row = $result->fetchrow)
# }

  
__END__

my $result = $dbh->prepare( 'SELECT * FROM two_comment WHERE two_comment ~ ?' );
$result->execute('elegans') or die "Cannot prepare statement: $DBI::errstr\n"; 

$result->execute("doesn't") or die "Cannot prepare statement: $DBI::errstr\n"; 
my $var = "doesn't";
$result->execute($var) or die "Cannot prepare statement: $DBI::errstr\n"; 

my $data = 'data';
unless (is_utf8($data)) { from_to($data, "iso-8859-1", "utf8"); }

my $result = $dbh->do( "DELETE FROM friend WHERE firstname = 'bl\"ah'" );
(also do for INSERT and UPDATE if don't have a variable to interpolate with ? )

can cache prepared SELECTs with $dbh->prepare_cached( &c. );

if ($result->rows == 0) { print "No names matched.\n\n"; }	# test if no return

$result->finish;	# allow reinitializing of statement handle (done with query)
$dbh->disconnect;	# disconnect from DB

http://209.85.173.132/search?q=cache:5CFTbTlhBGMJ:www.perl.com/pub/1999/10/DBI.html+dbi+prepare+execute&cd=4&hl=en&ct=clnk&gl=us

interval stuff : 
SELECT * FROM afp_passwd WHERE joinkey NOT IN (SELECT joinkey FROM afp_lasttouched) AND joinkey NOT IN (SELECT joinkey FROM cfp_curator) AND afp_timestamp < CURRENT_TIMESTAMP - interval '21 days' AND afp_timestamp > CURRENT_TIMESTAMP - interval '28 days';

casting stuff to substring on other types :
SELECT * FROM afp_passwd WHERE CAST (afp_timestamp AS TEXT) ~ '2009-05-14';

to concatenate string to query result :
  SELECT 'WBPaper' || joinkey FROM pap_identifier WHERE pap_identifier ~ 'pmid';
to get :
  SELECT DISTINCT(gop_paper_evidence) FROM gop_paper_evidence WHERE gop_paper_evidence NOT IN (SELECT 'WBPaper' || joinkey FROM pap_identifier WHERE pap_identifier ~ 'pmid') AND gop_paper_evidence != '';

