package get_brief_citation;
require Exporter;

# generate Brief Citation for papers (original use) and for Picture objects (new use).  For Daniela and Raymond.  2010 11 18

our @ISA        = qw(Exporter);
our @EXPORT     = qw( getBriefCitation );
our $VERSION    = 1.00;

# usage :
#   my ($brief_citation) = &getEimearBriefCitation( $author, $year, $journal, $title );
#   if ($brief_citation) { print "Brief_citation\t\"$brief_citation\"\n"; }

sub getBriefCitation {
  my ($author, $year, $journal, $title) = @_;
  my $brief_citation = '';
  my $brief_title = '';                     # brief title (70 chars or less)
  if ($title) {
    $title =~ s/"//g;			# some titles properly have doublequotes but don't want them in brief citation
    my @chars = split //, $title;
    if ( scalar(@chars) < 70 ) {
        $brief_title = $title;
    } else {
        my $i = 0;                            # letter counter (want less than 70)
        my $word = '';                        # word to tack on (start empty, add characters)
        while ( (scalar(@chars) > 0) && ($i < 70) ) { # while there's characters, and less than 70 been read
            $brief_title .= $word;            # add the word, because still good (first time empty)
            $word = '';                       # clear word for next time new word is used
            my $char = shift @chars;          # read a character to start / restart check
            while ( (scalar(@chars) > 0) && ($char ne ' ') ) {        # while not a space and still chars
                $word .= $char; $i++;         # build word, add to counter (less than 70)
                $char = shift @chars;         # read a character to check if space
            } # while ($_ ne '')              # if it's a space, exit loop
            $word .= ' ';                     # add a space at the end of the word
        } # while ( (scalar(@chars) > 0) && ($i < 70) )
        $brief_title = $brief_title . "....";
    } }
  if ($author) { if ( length($author) > 0) { $brief_citation .= $author; } }
  if ($year) { 
    if ($year =~ m/ -C .*$/) { $year =~ s/ -C .*$//g; }
    if ( length($year) > 0) { $brief_citation .= " ($year)"; } }
  if ($journal) { 
    $journal =~ s/"//g;			# some journals are messed up and have doublequotes
    if ( length($journal) > 0) { $brief_citation .= " $journal"; } }
  if ($brief_title) { if ( length($brief_title) > 0) { $brief_citation .= " \\\"$brief_title\\\""; } }
  if ($brief_citation) { return $brief_citation; }
} # sub getBriefCitation

