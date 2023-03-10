#!/usr/bin/perl

# convert characters with accents to characters without accents.  seems to work with utf-8.  written for wbg abstracts.  2013 06 14
#
# modified for IWM files.  Manually fixed 3 files afterward (for ¬ × «) so do not run this again.  2013 08 10

use strict;

use Text::Unaccent;

# my $indirectory = 'Testing';
my $indirectory = 'AbsFilesOrig';
# my $outdirectory = 'AbsFiles';		# uncomment to overwrite files
my $outdirectory = 'Testing';

my (@files) = <${indirectory}/*>;

foreach my $infile (@files) {
  print "IN $infile IN\n";
  my $outfile = $infile;
  $outfile =~ s/$indirectory/$outdirectory/;
  open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
  open (IN, "<$infile") or die "Cannot open $infile : $!";
  while (my $line = <IN>) {
    $line =~ s/“/"/g;
    $line =~ s/”/"/g;
    $line =~ s/’/'/g;
    $line =~ s/‘/'/g;
#     $line =~ s/\%x101/E/g;			# these don't fix it
#     $line =~ s/é/e/g;				# these don't fix it
#     print OUT $line;
#   #   my $unaccented = unac_string_utf16($line);
    my $unaccented = unac_string("iso-8859-1", $line);		# for IWM Kimberly files
# #     my $unaccented = unac_string("utf-8", $line);		# for WBG Daniel files 
    print OUT $unaccented;
  } # while (my $line = <IN>)
  close (IN) or die "Cannot close $infile : $!";
  close (OUT) or die "Cannot close $outfile : $!";
} # foreach my $infile (@files)

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
