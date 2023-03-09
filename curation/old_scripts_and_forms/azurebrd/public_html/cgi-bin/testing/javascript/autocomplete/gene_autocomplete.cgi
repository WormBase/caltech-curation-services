#!/usr/bin/perl 

# for ajax calls to test auto-complete on yui_basic_xhr.html   2009 05 09


use CGI;
use Jex;
use DBI;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 


my $query = new CGI;

print "Content-type: text/html\n\n";

my $oop;

($oop, my $words) = &getHtmlVar($query, 'query');		# all data in textarea

my @matches;							# the results

my @tables = qw( gin_locus gin_synonyms gin_wbgene );
foreach my $table (@tables) {
  my $result = $dbh->prepare( "SELECT * FROM $table WHERE $table ~ '^$words' ORDER BY $table;" );
  $result->execute();
  while ( (my @row = $result->fetchrow()) && (scalar(@matches) < 20) ) {
    my $id = "WBGene" . $row[0]; 
    if ($table eq 'gin_locus') { push @matches, "$id ( $row[1] )"; }
    elsif ($table eq 'gin_synonyms') { push @matches, "$id ( $row[1] ) [syn]"; }
    elsif ($table eq 'gin_wbgene') { push @matches, "$id"; }
  }
  $result = $dbh->prepare( "SELECT * FROM $table WHERE $table ~ '$words' AND $table !~ '^$words' ORDER BY $table;" );
  $result->execute();
  while ( (my @row = $result->fetchrow()) && (scalar(@matches) < 20) ) {
    my $id = "WBGene" . $row[0]; 
    if ($table eq 'gin_locus') { push @matches, "$id ( $row[1] )"; }
    elsif ($table eq 'gin_synonyms') { push @matches, "$id ( $row[1] ) [syn]"; }
    elsif ($table eq 'gin_wbgene') { push @matches, "$id"; }
  }
  last if (scalar(@matches) >= 20);
}

if (scalar(@matches) > 19) { $matches[$#matches] = 'more ...'; }

foreach (@matches) {
  print "$_\n";
}
