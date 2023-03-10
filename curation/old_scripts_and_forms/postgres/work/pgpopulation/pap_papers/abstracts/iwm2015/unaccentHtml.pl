#!/usr/bin/perl

# iwm2015 has accent characters in html format (both code and name).  Find the characters, and create mappings, then change the text.
# It also has accent characters as text, so still use Text::Unaccent.
# It also has html markup in place, so try to strip all of it out first.
# for future runs, after running, do a "grep \< *" on the output directory to see that all html was stripped.
#   Possibly comment out the   $charCodeConvert{'60'}    = '<';  first to check it.
# for future runs, also do a "grep \& *" to see if any characters didn't get converted.  In that case, 
#   uncomment the section to generate list of characters, outputting %charsCode and %charsName ;  then manually
#   add new things to  &populateCharConvert();  
# 2015 07 24

use strict;

use Text::Unaccent;

# my $indirectory = 'Testing';
my $indirectory = 'AbsFilesOrig';
my $outdirectory = 'AbsFiles';		# uncomment to overwrite files
# my $outdirectory = 'Testing';

my (@files) = <${indirectory}/*>;

my %charsCode;
my %charsName;
my %charCodeConvert;
my %charNameConvert;
&populateCharConvert();

foreach my $infile (@files) {
#   print "IN $infile IN\n";
  my $outfile = $infile;
  $outfile =~ s/$indirectory/$outdirectory/;
  open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
  open (IN, "<$infile") or die "Cannot open $infile : $!";
  while (my $line = <IN>) {
    if ($line =~ m/<[\w\\]+>/) { $line =~ s/<[\w\/]+>//g; }			# strip out html tags
    if ($line =~ m/<font face=symbol>/) { $line =~ s/<font face=symbol>//g; }	# strip out html tags that didn't come out before
    if ($line =~ m/<\/font>/) { $line =~ s/<\/font>//g; }			# strip out html tags that didn't come out before
    if ($line =~ m/&#\d+/) { 					# to find html characters to map them manually
      my (@charsCode) = $line =~ m/&#(\d+)/g;
      foreach my $char (@charsCode) { 
        $charsCode{$char}++; 
        if ($charCodeConvert{$char}) { $line =~ s/&#$char;/$charCodeConvert{$char}/g; }
    } }
    if ($line =~ m/&[\w]+;/) { 					# to find html characters to map them manually
      my (@charsName) = $line =~ m/&([\w]+);/g;
      foreach my $char (@charsName) { 
        $charsName{$char}++; 
        if ($charNameConvert{$char}) { $line =~ s/&$char;/$charNameConvert{$char}/g; }
    } }
#     print OUT $line;
  #   my $unaccented = unac_string_utf16($line);
    my $unaccented = unac_string("iso-8859-1", $line);		# for IWM Kimberly files
#     my $unaccented = unac_string("utf-8", $line);		# for WBG Daniel files 
    print OUT $unaccented;
  } # while (my $line = <IN>)
  close (IN) or die "Cannot close $infile : $!";
  close (OUT) or die "Cannot close $outfile : $!";
} # foreach my $infile (@files)

# uncomment to generate list of characters
# foreach my $char (sort keys %charsCode) { print "&amp;#$char;\t&#$char;\t$charsCode{$char}<br/>\n"; }
# foreach my $char (sort keys %charsName) { print "&amp;$char;\t&$char;\t$charsName{$char}<br/>\n";   }

sub populateCharConvert {
  $charCodeConvert{'12316'} = '~';
  $charCodeConvert{'146'}   = "'";
  $charCodeConvert{'147'}   = '"';
  $charCodeConvert{'148'}   = '"';
  $charCodeConvert{'151'}   = '-';
  $charCodeConvert{'176'}   = 'deg';
  $charCodeConvert{'177'}   = 'plus_or_minus';
  $charCodeConvert{'193'}   = 'A';
  $charCodeConvert{'197'}   = 'A';
  $charCodeConvert{'199'}   = 'C';
  $charCodeConvert{'214'}   = 'O';
  $charCodeConvert{'225'}   = 'a';
  $charCodeConvert{'227'}   = 'a';
  $charCodeConvert{'228'}   = 'a';
  $charCodeConvert{'230'}   = 'ae';
  $charCodeConvert{'231'}   = 'c';
  $charCodeConvert{'233'}   = 'e';
  $charCodeConvert{'237'}   = 'i';
  $charCodeConvert{'239'}   = 'i';
  $charCodeConvert{'241'}   = 'n';
  $charCodeConvert{'243'}   = 'o';
  $charCodeConvert{'246'}   = 'o';
  $charCodeConvert{'248'}   = 'o';
  $charCodeConvert{'250'}   = 'u';
  $charCodeConvert{'252'}   = 'u';
  $charCodeConvert{'304'}   = 'i';
  $charCodeConvert{'305'}   = 'i';
  $charCodeConvert{'38'}    = '&';
  $charCodeConvert{'39'}    = "'";
  $charCodeConvert{'60'}    = '<';
  $charCodeConvert{'62'}    = '>';
  $charCodeConvert{'65292'} = ',';
  $charCodeConvert{'8209'}  = '-';
  $charCodeConvert{'8232'}  = ' ';
  $charCodeConvert{'8239'}  = ' ';

  $charNameConvert{'Delta'}    = 'delta';
  $charNameConvert{'Omega'}    = 'omega';
  $charNameConvert{'acute'}    = "'";
  $charNameConvert{'alpha'}    = 'alpha';
  $charNameConvert{'beta'}     = 'beta';
  $charNameConvert{'bull'}     = ' ';
  $charNameConvert{'eacute'}   = 'e';
  $charNameConvert{'epsilon'}  = 'epsilon';
  $charNameConvert{'gamma'}    = 'gamma';
  $charNameConvert{'hellip'}   = '...';
  $charNameConvert{'iota'}     = 'iota';
  $charNameConvert{'lambda'}   = 'lambda';
  $charNameConvert{'ldquo'}    = '"';
  $charNameConvert{'le'}       = 'less_than_or_equal';
  $charNameConvert{'lsquo'}    = "'";
  $charNameConvert{'mdash'}    = '-';
  $charNameConvert{'micro'}    = 'micro';
  $charNameConvert{'mu'}       = 'mu';
  $charNameConvert{'ndash'}    = '-';
  $charNameConvert{'oacute'}   = 'o';
  $charNameConvert{'omega'}    = 'omega';
  $charNameConvert{'ordm'}     = ' ';
  $charNameConvert{'ouml'}     = 'o';
  $charNameConvert{'rdquo'}    = '"';
  $charNameConvert{'reg'}      = '';
  $charNameConvert{'rsquo'}    = "'";
  $charNameConvert{'shy'}      = '';
  $charNameConvert{'sim'}      = '~';
  $charNameConvert{'sup2'}     = '2';
  $charNameConvert{'szlig'}    = '';
  $charNameConvert{'trade'}    = '';
  $charNameConvert{'uring'}    = 'u';
  $charNameConvert{'uuml'}     = 'u';
} # sub populateCharConvert

__END__
Author  Hall, Sarah
Affiliation     Department of Biology, Syracuse University, Syracuse NY
URL     http://www.wormbook.org/wbg/volumes/volume-19-number-3/pdf/wbg-volume-19-number-3.20.pdf
Type    Gazette_article
Primary_data    not_designated


  ## This does something, but the new characters are not readable
my @charnames = grep /\tLATIN \S+ LETTER/, split( /^/, do 'unicore/Name.pl' );

my %accents;

for my $c ( split //, qq/AEIOUCNYaeioucny/ ) {
    my $case = ( $c eq lc $c ) ?  'SMALL' : 'CAPITAL';
    $accents{$c} =
          join( '', map { chr hex( substr $_, 0, 4 ) }
                grep /\tLATIN $case LETTER \U$c WITH/, @charnames );
}

# now use each element of %accents as a character class:

my $infile = 'wbg_19.3.txt';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (<IN>) {
    for my $c ( keys %accents ) {
        s/[$accents{$c}]/$c/g;
    }
    print;
}
close (IN) or die "Cannot close $infile : $!";
