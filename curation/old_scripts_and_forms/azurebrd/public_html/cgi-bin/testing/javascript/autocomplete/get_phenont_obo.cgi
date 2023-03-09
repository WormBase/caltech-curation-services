#!/usr/bin/perl 

# for ajax calls from curator_first_pass.cgi / curator_first_pass.js to send in data from
# a textarea (genestudied, genesymbol, structcorr) and get the words that match a 
# gene / locus / sequence and the corresponding WBGene or Laboratory.  2009 03 19
#
# match on lower case word, but return typed word.  2009 03 21
#
# changed from Pg.pm to DBI.pm  2009 05 06
#
# used by allele.cgi submission form.  2013 11 04


use CGI;
use Jex;
use DBI;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 


my $query = new CGI;

print "Content-type: text/html\n\n";

my $oop;

($oop, my $words) = &getHtmlVar($query, 'all');		# all data in textarea
# ($oop, my $type) = &getHtmlVar($query, 'type');		# pgtable name 
# ($oop, my $sid) = &getHtmlVar($query, 'sid');		# random number to prevent browser cache

my @matches;						# results to return
my @words = split/\s+/, $words;				# array of words from textarea

if ($words =~ m/(WBPhenotype:\d+)/) {
  my $id = $1;
#   my $result = $dbh->prepare( "SELECT * FROM poo_data WHERE joinkey = '$id';" );
  my $result = $dbh->prepare( "SELECT * FROM obo_data_phenotype WHERE joinkey = '$id';" );
  $result->execute();
  my @row = $result->fetchrow;
  $matches = $row[1];
  $matches =~ s/<[^>]*>//g;
#   $matches =~ s/\n/<br \/>/g;		# for div display instead of textarea
} elsif ($words =~ m/./) {
  $matches = "new term: $words";
} else {
  $matches = '';
}

# foreach my $word (@words) {				# for each word, query postgres for exact match
# #   print "$word\n";
#   my ($lcword) = lc($word);		# words on the table are lowercased for ease of matching
#   if ($lcword =~ m/\'/) { $lcword =~ s/\'/''/g; }
#   my $result = $dbh->prepare( "SELECT * FROM gin_genesequencelab WHERE gin_genesequencelab = '$lcword';" );
#   $result->execute();
#   my @row = $result->fetchrow;
#   if ($row[0]) { 					# if a word matched
#     if ($type eq 'structcorr') {
#       push @matches, "$word \($row[2]\)"; } 		# structcorr returns lab
#     elsif ( ($type eq 'genestudied') || ($type eq 'genesymbol') ) { 
#       push @matches, "$word \(WBGene$row[1]\)"; }	# genestudied and genesymbol return wbgene
#     else { push @matches, "error on type"; }		# other fields not allowed
#   }
# }

# my $matches = join", ", @matches;			# comma separate results
print "$matches\n";					# return by printing to screen

