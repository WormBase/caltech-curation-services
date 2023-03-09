#!/usr/bin/perl 

# for ajax calls to test auto-complete on yui_basic_xhr.html   2009 05 09
#
# poo_ tables went away, so replace with obo_name_app_term and obo_syn_app_term (no longer matches ID)  2010 07 14
#
# changed from obo_*_app_term to obo_*_phenotype.
# used by allele.cgi submission form.  2013 11 04



use CGI;
use Jex;
use DBI;
use Tie::IxHash;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 


my $query = new CGI;

print "Content-type: text/html\n\n";

my $oop;

($oop, my $words) = &getHtmlVar($query, 'query');		# all data in textarea

if ($words =~ m/^WBPhenotype:/) { $words =~ s/^WBPhenotype://; }
($words) = lc($words);						# search insensitively by lowercasing query and LOWER column values

my %matches;
tie %matches, "Tie::IxHash";               			# sorted hash 

my @matches;							# the results

# got rid of poo_ tables  2010 07 14
# my @tables = qw( poo_name poo_syn poo_id );
# foreach my $table (@tables) {
#   my $result = $dbh->prepare( "SELECT * FROM $table WHERE LOWER($table) ~ '^$words' ORDER BY $table;" );
#   $result->execute();
#   while ( (my @row = $result->fetchrow()) && (scalar(keys %matches) < 20) ) {
#     my $id = "WBPhenotype:" . $row[0]; 
#     if ($table eq 'poo_name') { $matches{"$id ( $row[1] )"}++; }
#     elsif ($table eq 'poo_syn') { $matches{"$id ( $row[1] ) [syn]"}++; }
#     elsif ($table eq 'poo_id') { $matches{"$id"}++; }
#   }
#   $result = $dbh->prepare( "SELECT * FROM $table WHERE LOWER($table) ~ '$words' AND $table !~ '^$words' ORDER BY $table;" );
#   $result->execute();
#   while ( (my @row = $result->fetchrow()) && (scalar(keys %matches) < 20) ) {
#     my $id = "WBPhenotype:" . $row[0]; 
#     if ($table eq 'poo_name') { $matches{"$id ( $row[1] )"}++; }
#     elsif ($table eq 'poo_syn') { $matches{"$id ( $row[1] ) [syn]"}++; }
#     elsif ($table eq 'poo_id') { $matches{"$id"}++; }
#   }
#   last if (scalar(keys %matches) >= 20);
# }

# my @tables = qw( obo_name_app_term obo_syn_app_term );
my @tables = qw( obo_name_phenotype obo_syn_phenotype );
foreach my $table (@tables) {
  my $result = $dbh->prepare( "SELECT * FROM $table WHERE LOWER($table) ~ '^$words' ORDER BY $table;" );
  $result->execute();
  while ( (my @row = $result->fetchrow()) && (scalar(keys %matches) < 20) ) {
#     my $id = "WBPhenotype:" . $row[0]; 
    my $id = $row[0]; 
    if ($table eq 'obo_name_phenotype') { $matches{"$id ( $row[1] )"}++; }
    elsif ($table eq 'obo_syn_phenotype') { $matches{"$id ( $row[1] ) [syn]"}++; }
  }
  $result = $dbh->prepare( "SELECT * FROM $table WHERE LOWER($table) ~ '$words' AND $table !~ '^$words' ORDER BY $table;" );
  $result->execute();
  while ( (my @row = $result->fetchrow()) && (scalar(keys %matches) < 20) ) {
    my $id = $row[0]; 
    if ($table eq 'obo_name_phenotype') { $matches{"$id ( $row[1] )"}++; }
    elsif ($table eq 'obo_syn_phenotype') { $matches{"$id ( $row[1] ) [syn]"}++; }
  }
  last if (scalar(keys %matches) >= 20);
}

(@matches) = keys %matches;
if (scalar(@matches) > 19) { $matches[$#matches] = 'more ...'; }

foreach (@matches) {
  print "$_\n";
}
