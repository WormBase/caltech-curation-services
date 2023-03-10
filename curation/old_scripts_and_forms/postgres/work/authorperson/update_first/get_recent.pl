#!/usr/bin/perl -w
#
# check which one entries merge ace entries (and will need to make sure i don't
# break stuff dealing with it)

use strict;
use diagnostics;
use lib qw( /usr/lib/perl5/site_perl/5.6.1/i686-linux/ );
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $outfile = "/home/postgres/work/authorperson/update_first/outfile";
my $htmlfile = "/home/postgres/public_html/htmlfile.html";
open(OUT, ">$outfile") or die "Cannot create $outfile : $!";
open(HTM, ">$htmlfile") or die "Cannot create $htmlfile : $!";

# hashes from pg data
my %hash;
my %multace;		# has multiple ace (merge, so complicated)
my %acewbg;		# ace and wbg into one, more likely to have different data
my %aceonly;		# ace only, less likely to have new data
my %wbgonly;		# wbg only, extremely likely to have new data

# tables for data
my @ace_tables = qw(ace_author ace_name ace_lab ace_oldlab ace_address ace_email ace_phone ace_fax);
my @wbg_tables = qw(wbg_title wbg_firstname wbg_middlename wbg_lastname wbg_suffix wbg_street wbg_city wbg_state wbg_post wbg_country wbg_mainphone wbg_labphone wbg_officephone wbg_fax wbg_email);
my @one_tables = qw(one_firstname one_middlename one_lastname one_street one_city one_state one_post one_country one_mainphone one_labphone one_officephone one_otherphone one_fax one_email one_lab one_oldlab );
# my @one_tables = qw(one_firstname one_middlename one_lastname one_street one_city one_state one_post one_country one_mainphone one_labphone one_officephone one_otherphone one_fax one_email one_lab one_oldlab one_groups);


&popHash();
# &dispHash();
# &genHtmlAceWbg();
# &genAceMultAce();
 &genAceWbgOnly();
# &genAceAceOnly();
# &genAceAceWbg();
# &getAceWbg();
# &getEasy();
# my $temp = (one1 ace1 wbg338);


close (OUT) or die "Cannot close $outfile : $!";
close (HTM) or die "Cannot close $htmlfile : $!";

sub popHash {		# generate a hash of all the groups data in pg
			# then split into : mult ace, ace & wbg, ace only, wbg only hashes

  my $result = $conn->exec( "SELECT * FROM one_groups;" );
  while (my @row = $result->fetchrow) {
    if ($row[0]) { 
      $row[0] =~ s///g;
      $row[1] =~ s///g;
      $row[2] =~ s///g;
      push @{ $hash{$row[0]} }, $row[1];
    } # if ($row[0])
  } # while (@row = $result->fetchrow)

  print "Pre Total : " . scalar(keys %hash) . "\n";
  foreach my $one (sort keys %hash) {
    my $ace = 0; my $wbg = 0;
    foreach my $key ( @{ $hash{$one} } ) {
      if ($key =~ m/ace/) { $ace++; }
      if ($key =~ m/wbg/) { $wbg++; }
    } # foreach ( @{ $hash{$one} } )
    if ($ace > 1) { 			# multiple aces, complex
      foreach my $key ( @{ $hash{$one} } ) {
        push @{ $multace{$one} }, $key;
      } # foreach my $key ( @{ $hash{$one} } 
      delete $hash{$one};		# don't count again
    } elsif ( ($ace) && ($wbg) ) {	# ace and wbg, single ace
      foreach my $key ( @{ $hash{$one} } ) {
        push @{ $acewbg{$one} }, $key;
      } # foreach my $key ( @{ $hash{$one} } 
      delete $hash{$one};		# don't count again
    } elsif ($ace) {			# single ace only
      foreach my $key ( @{ $hash{$one} } ) {
        push @{ $aceonly{$one} }, $key;
      } # foreach my $key ( @{ $hash{$one} } 
      delete $hash{$one};		# don't count again
    } elsif ($wbg) {			# single wbg only
      foreach my $key ( @{ $hash{$one} } ) {
        push @{ $wbgonly{$one} }, $key;
      } # foreach my $key ( @{ $hash{$one} } 
      delete $hash{$one};		# don't count again
    } else { 1; }
  } # foreach my $one (sort keys %hash)
} # sub popHash

sub genAceMultAce {		# largely not good, check everything manually
				# then look at acedb entries to see which one to delete
				# and how to rearrange the links to papers
  foreach my $one (sort keys %multace) {
    my $confirmation_date = '2002-01-01_12:00:00';
    my $result = $conn->exec( "SELECT * FROM one_firstname WHERE joinkey = '$one';" );
    while (my @row = $result->fetchrow) {
      if ($row[3]) { $row[3] =~ s/ /_/g; $row[3] =~ s/\-\d+$//g; $confirmation_date = $row[3]; }
    } # while (@row = $result->fetchrow)
    foreach my $key ( @{ $multace{$one} }) {
      if ($key =~ m/^ace/) { 
        my $result = $conn->exec( "SELECT * FROM ace_author WHERE joinkey = '$key';" );
        while (my @row = $result->fetchrow) {
          if ($row[1]) {
            print OUT "Author\t\"$row[1]\"\nDetails_confirmed\t$confirmation_date\n\n";
          } # if ($row[1])
        } # while (@row = $result->fetchrow)
      } # if ($key =~ m/^ace/) 
    } # foreach my $key ( @{ $multace{$one} })
  } # foreach my $one (sort keys %multace)
} # sub genAceMultAce


sub genAceWbgOnly {			# data not good, check manually for collisions
					# with previously existing authors with same name
					# as authors generated here.
  foreach my $one (sort keys %wbgonly) {
    my ($firstname, $middlename, $lastname, $street, $city, $state, $post, $country);
    my $confirmation_date = '2002-01-01_12:00:00';
    my $result = $conn->exec( "SELECT * FROM one_firstname WHERE joinkey = '$one';" );
    while (my @row = $result->fetchrow) {
      if ($row[3]) { $row[3] =~ s/ /_/g; $row[3] =~ s/\-\d+$//g; $confirmation_date = $row[3]; }
    } # while (@row = $result->fetchrow)
        $result = $conn->exec( "SELECT * FROM one_firstname WHERE joinkey = '$one';" );
        my $counter = 0;
        while (my @row = $result->fetchrow) {
          if ($row[1]) { $firstname = $row[1]; $counter++; }
        } # while (@row = $result->fetchrow)
        if ($counter > 1) { print OUT "EXTRA FIRST\n"; }
        $counter = 0;
        $result = $conn->exec( "SELECT * FROM one_middlename WHERE joinkey = '$one';" );
        while (my @row = $result->fetchrow) {
          if ($row[1]) { $middlename = $row[1]; $counter++; }
        } # while (@row = $result->fetchrow)
        if ($counter > 1) { print OUT "EXTRA MIDDLE\n"; }
        $counter = 0;
        $result = $conn->exec( "SELECT * FROM one_lastname WHERE joinkey = '$one';" );
        while (my @row = $result->fetchrow) {
          if ($row[1]) { $lastname = $row[1]; $counter++; }
        } # while (@row = $result->fetchrow)
        if ($counter > 1) { print OUT "EXTRA LAST\n"; }
        my $author = $lastname . " ";
        my $name = '';
        if ($firstname) { my $init = substr($firstname,0,1); $author .= $init; $name .= $firstname .  " " }
        if ($middlename) { my $init = substr($middlename,0,1); $author .= $init; $name .= $middlename . " " }
        print OUT "Author\t\"$author\"\n";
        $name .= $lastname;
        print OUT "Also_known_as\t\"$name\"\n";
        my $result = $conn->exec( "SELECT * FROM one_lastname WHERE joinkey = '$one';" );
        while (my @row = $result->fetchrow) {
          if ($row[1]) {
            print OUT "Contact_details_confirmed\t$confirmation_date\n";
          } # if ($row[1])
        } # while (@row = $result->fetchrow)
        $result = $conn->exec( "SELECT * FROM one_street WHERE joinkey = '$one';" );
        while (my @row = $result->fetchrow) {
          if ($row[1]) { print OUT "Mail\t\"$row[1]\"\n"; }
        } # while (@row = $result->fetchrow)
        $result = $conn->exec( "SELECT * FROM one_city WHERE joinkey = '$one';" );
        while (my @row = $result->fetchrow) {
          if ($row[1]) { $city = $row[1]; }
        } # while (@row = $result->fetchrow)
        $result = $conn->exec( "SELECT * FROM one_state WHERE joinkey = '$one';" );
        while (my @row = $result->fetchrow) {
          if ($row[1]) { $state = $row[1]; }
        } # while (@row = $result->fetchrow)
        $result = $conn->exec( "SELECT * FROM one_post WHERE joinkey = '$one';" );
        while (my @row = $result->fetchrow) {
          if ($row[1]) { $post = $row[1]; }
        } # while (@row = $result->fetchrow)
        if ( ($city) | ($state) | ($post) ) {	# if something
          print OUT "Mail\t\"";
          if ($city) { print OUT $city . ", "; }
          if ($state) { print OUT $state . " "; }
          if ($post) { print OUT $post; }
          print OUT "\"\n";
        } # if ( ($city) | ($state) | ($post) )
        $result = $conn->exec( "SELECT * FROM one_country WHERE joinkey = '$one';" );
        while (my @row = $result->fetchrow) {
          if ($row[1]) { print OUT "Mail\t\"$row[1]\"\n"; }
        } # while (@row = $result->fetchrow)
        $result = $conn->exec( "SELECT * FROM one_mainphone WHERE joinkey = '$one';" );
        while (my @row = $result->fetchrow) {
          if ($row[1]) { print OUT "Phone\t\"$row[1]\"\n"; }
        } # while (@row = $result->fetchrow)
        $result = $conn->exec( "SELECT * FROM one_officephone WHERE joinkey = '$one';" );
        while (my @row = $result->fetchrow) {
          if ($row[1]) { print OUT "Phone\t\"$row[1]\"\n"; }
        } # while (@row = $result->fetchrow)
        $result = $conn->exec( "SELECT * FROM one_labphone WHERE joinkey = '$one';" );
        while (my @row = $result->fetchrow) {
          if ($row[1]) { print OUT "Phone\t\"$row[1]\"\n"; }
        } # while (@row = $result->fetchrow)
        $result = $conn->exec( "SELECT * FROM one_otherphone WHERE joinkey = '$one';" );
        while (my @row = $result->fetchrow) {
          if ($row[1]) { print OUT "Phone\t\"$row[1]\"\n"; }
        } # while (@row = $result->fetchrow)
        $result = $conn->exec( "SELECT * FROM one_fax WHERE joinkey = '$one';" );
        while (my @row = $result->fetchrow) {
          if ($row[1]) { print OUT "Fax\t\"$row[1]\"\n"; }
        } # while (@row = $result->fetchrow)
        $result = $conn->exec( "SELECT * FROM one_email WHERE joinkey = '$one';" );
        while (my @row = $result->fetchrow) {
          if ($row[1]) { print OUT "E_mail\t\"$row[1]\"\n"; }
        } # while (@row = $result->fetchrow)
        $result = $conn->exec( "SELECT * FROM one_lab WHERE joinkey = '$one';" );
        while (my @row = $result->fetchrow) {
          if ($row[1]) { print OUT "Laboratory\t\"$row[1]\"\n"; }
        } # while (@row = $result->fetchrow)
        print OUT "\n";
  } # foreach my $one (sort keys %wbgonly)
} # sub genAceWbgOnly

sub genAceAceOnly {
  foreach my $one (sort keys %aceonly) {
    my $confirmation_date = '2002-01-01_12:00:00';
    my $result = $conn->exec( "SELECT * FROM one_firstname WHERE joinkey = '$one';" );
    while (my @row = $result->fetchrow) {
      if ($row[3]) { $row[3] =~ s/ /_/g; $row[3] =~ s/\-\d+$//g; $confirmation_date = $row[3]; }
    } # while (@row = $result->fetchrow)
    foreach my $key ( @{ $aceonly{$one} }) {
      if ($key =~ m/^ace/) { 
        my $result = $conn->exec( "SELECT * FROM ace_author WHERE joinkey = '$key';" );
        while (my @row = $result->fetchrow) {
          if ($row[1]) {
            print OUT "Author\t\"$row[1]\"\nDetails_confirmed\t$confirmation_date\n\n";
          } # if ($row[1])
        } # while (@row = $result->fetchrow)
      } # if ($key =~ m/^ace/) 
    } # foreach my $key ( @{ $aceonly{$one} })
  } # foreach my $one (sort keys %aceonly)
} # sub genAceAceOnly

sub genAceAceWbg {
  foreach my $one (sort keys %acewbg) {
    my $confirmation_date = '2002-01-01_12:00:00';
    my $result = $conn->exec( "SELECT * FROM one_firstname WHERE joinkey = '$one';" );
    while (my @row = $result->fetchrow) {
      if ($row[3]) { $row[3] =~ s/ /_/g; $row[3] =~ s/\-\d+$//g; $confirmation_date = $row[3]; }
    } # while (@row = $result->fetchrow)
    foreach my $key ( @{ $acewbg{$one} }) {
      if ($key =~ m/^ace/) { 
        my $result = $conn->exec( "SELECT * FROM ace_author WHERE joinkey = '$key';" );
        while (my @row = $result->fetchrow) {
          if ($row[1]) {
            print OUT "Author\t\"$row[1]\"\nDetails_confirmed\t$confirmation_date\n\n";
          } # if ($row[1])
        } # while (@row = $result->fetchrow)
      } # if ($key =~ m/^ace/) 
    } # foreach my $key ( @{ $acewbg{$one} })
  } # foreach my $one (sort keys %acewbg)
} # sub genAceAceWbg

sub genHtmlAceWbg {	# generate the html files, just change the name of the %acewbg hash
			# to that of the other hashes, then move the htmlfile to the 
			# /home/postgres/public_html/temp_one/ directory
  my $counter = 0;
  print HTM "<TABLE>";
  foreach my $one (sort keys %acewbg) { 
    $counter++; # print HTM "Count : $counter\n";
    print HTM "<TR><TD>$counter</TD><TD>";
    &displayOneDataFromKey($one);
    foreach my $key ( @{ $acewbg{$one} }) {
      print HTM "</TD><TD>";
      if ($key =~ m/^wbg/) { &displayWbgDataFromKey($key); }
      if ($key =~ m/^ace/) { &displayAceDataFromKey($key); }
    } # foreach my $key ( @{ $acewbg{$one} })
    print HTM "</TD></TR>\n";
#     print HTM "<BR><BR>\n";
  } # foreach my $one (sort keys %acewbg) 
  print HTM "</TABLE>\n";
} # sub genHtmlAceWbg

sub dispHash {		# display the data from the various hashes
  print "Mult Ace : " . scalar(keys %multace) . "\n";
  foreach my $one (sort keys %multace) {
    print $one;
    foreach my $key ( @{ $multace{$one} }) { print "\t$key"; }
    print "\n";
  } # foreach my $one (sort keys %multace)
  print "\n";
  print "Ace Wbg : " . scalar(keys %acewbg) . "\n";
  foreach my $one (sort keys %acewbg) {
    print $one;
    foreach my $key ( @{ $acewbg{$one} }) { print "\t$key"; }
    print "\n";
  } # foreach my $one (sort keys %acewbg)
  print "\n";
  print "Ace Only : " . scalar(keys %aceonly) . "\n";
  foreach my $one (sort keys %aceonly) {
    print $one;
    foreach my $key ( @{ $aceonly{$one} }) { print "\t$key"; }
    print "\n";
  } # foreach my $one (sort keys %aceonly)
  print "\n";
  print "Wbg Only : " . scalar(keys %wbgonly) . "\n";
  foreach my $one (sort keys %wbgonly) {
    print $one;
    foreach my $key ( @{ $wbgonly{$one} }) { print "\t$key"; }
    print "\n";
  } # foreach my $one (sort keys %wbgonly)
  print "\n";
} # sub dispHash


### display from key ###

sub displayAceDataFromKey {             # show all ace data from a given key in multiline table
  my ($ace_key) = @_;
  print HTM "<TABLE border=1 cellspacing=2>\n";
  foreach my $ace_table (@ace_tables) { # show the data
    my $result = $conn->exec( "SELECT * FROM $ace_table WHERE joinkey = '$ace_key';" );
    my @row;
    while (@row = $result->fetchrow) {
      if ($row[1]) {
        print HTM "<TR><TD>$ace_table</TD>";
        foreach (@row) { print HTM "<TD>$_</TD>"; }
        print HTM "</TR>\n";
      } # if ($row[1])
    } # while (@row = $result->fetchrow)
  } # foreach (@ace_tables)
  print HTM "</TABLE><BR><BR>\n";
} # sub displayAceDataFromKey

sub displayWbgDataFromKey {             # show all wbg data from a given key in multiline table
  my ($wbg_key) = @_;
  print HTM "<TABLE border=1 cellspacing=2>\n";
  foreach my $wbg_table (@wbg_tables) { # go through each table for the key
    my $result = $conn->exec( "SELECT * FROM $wbg_table WHERE joinkey = '$wbg_key';" );
    my @row;
    while (@row = $result->fetchrow) {
      if ($row[1]) {
        print HTM "<TR><TD>$wbg_table</TD>";
        foreach (@row) { print HTM "<TD>$_</TD>"; }
        print HTM "</TR>\n";
      } # if ($row[1])
    } # while (@row = $result->fetchrow)
  } # foreach my $wbg_table (@wbg_tables)
  print HTM "</TABLE><BR><BR>\n";
} # sub displayWbgDataFromKey

sub displayOneDataFromKey {
#   my ($one_key) = 'one' . $_[0];
  my ($one_key) = shift;
  print HTM "<TABLE border=1 cellspacing=2>\n";
  my $counter = 0;
  foreach my $one_table (@one_tables) {
    my $result = $conn->exec( "SELECT * FROM $one_table WHERE joinkey = '$one_key';" );
    while (my @row = $result->fetchrow) {
      if ($row[1]) {
        print HTM "<TR><TD>$one_table</TD>";
        print HTM "<TD>$row[0]</TD>"; 
        if ($row[3]) { 			# if it has two dates
          print HTM "<TD>$row[1]</TD>";
          print HTM "<TD>$row[2]</TD>";
          print HTM "<TD>$row[3]</TD>";
        } else {			# only has one date
          print HTM "<TD>$row[1]</TD>";
          print HTM "<TD></TD>";
          print HTM "<TD>$row[2]</TD>";
        }
        $counter++;
        print HTM "</TR>\n";
      } # if ($row[1])
    } # while (my @row = $result->fetchrow)
  } # foreach my $one_table (@one_tables)
  print HTM "</TABLE><BR><BR>\n";
} # sub displayOneDataFromKey

### display from key ###



# DEPRECATED

# used to get simple samples, now done at once in &popHash
sub getAceWbg {		# those with wbg and acej
  my $counter = 0; 	# how many entries in set
  foreach my $one (sort keys %hash) {
    my $ace = 0; my $wbg = 0;
    foreach my $key ( @{ $hash{$one} } ) {
      if ($key =~ m/ace/) { $ace++; }
      if ($key =~ m/wbg/) { $wbg++; }
    } # foreach ( @{ $hash{$one} } )
    if (($ace == 1) && ($wbg > 0)) { 
      $counter++;
      print "$one";
      foreach my $key ( @{ $hash{$one} } ) {
        print "\t$key";
      } # foreach ( @{ $hash{$one} } )
      print "\n";
#   print "$one : $ace\n"; 
    }
  } # foreach my $one (sort keys %hash)
  print "Counter : $counter\n";
} # sub getAceWbg

sub getEasy {		# those with only one ace, no merge
  foreach my $one (sort keys %hash) {
    my $ace = 0; my $wbg = 0;
    foreach my $key ( @{ $hash{$one} } ) {
      if ($key =~ m/ace/) { $ace++; }
      if ($key =~ m/wbg/) { $wbg++; }
    } # foreach ( @{ $hash{$one} } )
    if ($ace == 1) { 
      print "$one";
      foreach my $key ( @{ $hash{$one} } ) {
        print "\t$key";
        } # foreach ( @{ $hash{$one} } )
      print "\n";
#   print "$one : $ace\n"; 
    }
  } # foreach my $one (sort keys %hash)
} # sub getEasy
