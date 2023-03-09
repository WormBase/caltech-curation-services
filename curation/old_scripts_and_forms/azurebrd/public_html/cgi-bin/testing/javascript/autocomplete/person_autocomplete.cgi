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

my $count = 0;
my @matches;
my $moreFlag = '';

my $result = $dbh->prepare( "SELECT * FROM two_standardname WHERE two_standardname ~ '$words' ORDER BY two_standardname;" );
$result->execute();
while ( (my @row = $result->fetchrow()) && ($count < 20) ) {
  $count++; 
  my $id = $row[0]; $id =~ s/two/WBPerson/;
  push @matches, "$id ( $row[2] )";
}

if ($count < 20) { 
  $result = $dbh->prepare( "SELECT * FROM two_standardname WHERE joinkey ~ '$words' ORDER BY joinkey;" );
  $result->execute();
  while ( (my @row = $result->fetchrow()) && ($count < 20) ) {
    $count++; 
    my $id = $row[0]; $id =~ s/two/WBPerson/;
    push @matches, "$id ( $row[2] )";
  }
}

if ($count > 19) { $matches[$#matches] = 'more ...'; }

foreach (@matches) {
  print "$_\n";
}
# print "$words\n";
# print "b$words\n";
# print "c$words\n";

__END__
($oop, my $type) = &getHtmlVar($query, 'type');		# pgtable name 
# ($oop, my $sid) = &getHtmlVar($query, 'sid');		# random number to prevent browser cache

my @matches;						# results to return
my @words = split/\s+/, $words;				# array of words from textarea

foreach my $word (@words) {				# for each word, query postgres for exact match
#   print "$word\n";
  my ($lcword) = lc($word);		# words on the table are lowercased for ease of matching
  if ($lcword =~ m/\'/) { $lcword =~ s/\'/''/g; }
  my $result = $dbh->prepare( "SELECT * FROM gin_genesequencelab WHERE gin_genesequencelab = '$lcword';" );
  $result->execute();
  my @row = $result->fetchrow;
  if ($row[0]) { 					# if a word matched
    if ($type eq 'structcorr') {
      push @matches, "$word \($row[2]\)"; } 		# structcorr returns lab
    elsif ( ($type eq 'genestudied') || ($type eq 'genesymbol') ) { 
      push @matches, "$word \(WBGene$row[1]\)"; }	# genestudied and genesymbol return wbgene
    else { push @matches, "error on type"; }		# other fields not allowed
  }
}

my $matches = join", ", @matches;			# comma separate results
print "$matches\n";					# return by printing to screen

