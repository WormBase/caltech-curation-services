#!/usr/bin/perl 

# for ajax calls from curator_first_pass.cgi / curator_first_pass.js to send in data from
# a textarea (genestudied, genesymbol, structcorr) and get the words that match a 
# gene / locus / sequence and the corresponding WBGene or Laboratory.  2009 03 19
#
# match on lower case word, but return typed word.  2009 03 21


use CGI;
use Jex;
use DBI;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

# my $result = $dbh->prepare( 'SELECT * FROM two_comment WHERE two_comment ~ ?' );
# $result->execute('elegans') or die "Cannot prepare statement: $DBI::errstr\n"; 


my $query = new CGI;

print "Content-type: text/html\n\n";

print "<html><head>\n";
print "<script type=\"text/javascript\" src=\"wormbase_autocomplete.js\"></script>\n";
print "<script type=\"text/javascript\" src=\"connection-min.js\"></script>\n";
print "<script type=\"text/javascript\" src=\"autocomplete-min.js\"></script>\n";
print "<link rel=\"stylesheet\" href=\"autocomplete.css\">\n";
print "</head>\n";

# print "<body onLoad=\"goAutoComplete();sf()\">\n";
print "<body onLoad=\"goAutoComplete();\">\n";

print "<span id=\"autoCompleteSearch\" style=\"position:relative\">\n";
print "<input id=\"autoCompleteInput\" type=\"text\" name=\"query\" autocomplete=\"off\" onKeyDown=\"skipAutoComplete(event)\">\n";
print "</span>\n";
print "<div id=autoCompleteContainer></div>\n";
print "<input type=\"submit\" id=\"autoCompleteSubmit\" name=\"Search\" value=\"Search\">\n";




my $oop;

($oop, my $words) = &getHtmlVar($query, 'all');		# all data in textarea
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

print "</body></html>\n";
