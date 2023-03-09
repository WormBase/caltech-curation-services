#!/usr/bin/perl5.6.0 -w
#
# create tables (timestamped), indices, grant all to nobody.  parse acefile, create insert lines for
# each line of data.  parse wbg file, create insert lines for each block of data.
#
# hack to output the authors which were previously wrong.  still have to do the ones with bad labs.  
# reversed the logic for when to print (if instead of unless)
# if ($authorline =~ m/\t[\.a-zA-Z_\-\']+\s+[\.a-zA-Z_\-\'][\.a-zA-Z_\-\']*\t/) and allow periods
# and underscored and apostrophes and stuff  2002 01 26

use lib qw( /usr/lib/perl5/site_perl/5.6.1/i686-linux/ );
use Pg;
use diagnostics;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;



my $acefile = "/home/azurebrd/work/parsings/authorperson/filesources/author_timestamp_contact.ace";
				# parsed file with only authors that have contact info
my $wbgtabfile = "/home/azurebrd/work/parsings/authorperson/filesources/wbg-tabbed.txt";
my $errorfile = "/home/azurebrd/work/parsings/authorperson/errors/errorfile_error_2.insertmaker";
				# make it _2 to not overwrite the manually edited _error which
				# manually changes the bad data from notas and bad ace labs.
my $insertfile = "/home/azurebrd/work/parsings/authorperson/insertfile_error.pl";

my %wbg;
my %ace;
my %timestamp;		# the timestamp of each value in %ace

open (ACE, "<$acefile") or die "Cannot open $acefile : $!";
open (TAB, "<$wbgtabfile") or die "Cannot open $wbgtabfile : $!";
open (ERR, ">$errorfile") or die "Cannot open $errorfile : $!";
open (OUT, ">$insertfile") or die "Cannot create $insertfile : $!";


&makePGtables();
&readACE();
# &readWBGtab();		# just getting the extra ACEs, don't need WBG



close (ACE) or die "Cannot close $acefile : $!";
close (TAB) or die "Cannot close $wbgtabfile : $!";
close (ERR) or die "Cannot close $errorfile : $!";
close (OUT) or die "Cannot close $insertfile : $!";



# &outputAceHash();
# &outputWbgHash();


sub readACE {
  local $/ = "";
  my %key_counter;
  my $total = '1703';		# number of ace entries	# starting with the last one, 1703
  while (<ACE>) { 
    $_ =~ s/'/\\\\'/g;		# escape apostrophies 
#     $_ =~ s/"/\\"/g;		# backslashed doublequotes manually removed out of acefile
    $_ =~ s/@/\\@/g;		# escape @s
    my @lines = split/\n/, $_;
    my $line;			# initialize
    my $authorline = $lines[0];
    if ($authorline =~ m/\t[\.a-zA-Z_\-\']+\s+[\.a-zA-Z_\-\'][\.a-zA-Z_\-\']*\t/) { 
#       print ERR "ERROR : unsplittable author : $authorline in authors_contact.ace\n";
    } else { 			# splittable, do stuff
      $total++;
      print OUT "\$result = \$conn\->exec( \"INSERT INTO ace_number VALUES (\'ace$total\', \'$total\', CURRENT_TIMESTAMP)\");\n";
#       print OUT "\$result = \$conn\->exec( \"INSERT INTO ace_timestamp VALUES (\'ace$total\', CURRENT_TIMESTAMP)\");\n";
      my ($junk, $author, $timestamp) = split/\t/, $authorline;
      print OUT "\$result = \$conn\->exec( \"INSERT INTO ace_author VALUES (\'ace$total\', \'$author\', \'$timestamp\')\");\n";
      my ($last, $firstinit) = $authorline =~ m/\t([\w\-\']+)\s+([\w\-\'])[\w\-\']*\t/;
      my $key = $last . "_" . $firstinit;
      $key_counter{$key}++;
      push @{ $ace{$key}[$key_counter{$key}-1]{author} }, $lines[0];
      for ($line = 1; $line < scalar(@lines); $line++) {
        if ($lines[$line] =~ m/^Also_known/) { 	# if entry has info
#           $lines[$line] =~ m/^.*"(.*)"$/;		# get the info
          my ($junk, $name, $timestamp) = split/\t/, $lines[$line]; 
          push @{ $ace{$key}[$key_counter{$key}-1]{name} }, $name;		# push it
          push @{ $timestamp{$key}[$key_counter{$key}-1]{name} }, $timestamp;	# push it
        }
        elsif ($lines[$line] =~ m/^Full_na/) { 	# if entry has info
#           $lines[$line] =~ m/^.*"(.*)"$/;		# get the info
          my ($junk, $name, $timestamp) = split/\t/, $lines[$line]; 
          push @{ $ace{$key}[$key_counter{$key}-1]{name} }, $name;		# push it
          push @{ $timestamp{$key}[$key_counter{$key}-1]{name} }, $timestamp;	# push it
        }
        elsif ($lines[$line] =~ m/^Labora.*\t[A-Z]{2,3}\t/) { 
#           $lines[$line] =~ m/^.*"(.*)"$/;
          my ($junk, $lab, $timestamp) = split/\t/, $lines[$line]; 
          push @{ $ace{$key}[$key_counter{$key}-1]{lab} }, $lab;
          push @{ $timestamp{$key}[$key_counter{$key}-1]{lab} }, $timestamp;
        }
        elsif ($lines[$line] =~ m/^Old_l/) { 
#           $lines[$line] =~ m/^.*"(.*)"$/;
          my ($junk, $oldlab, $timestamp) = split/\t/, $lines[$line]; 
          push @{ $ace{$key}[$key_counter{$key}-1]{old_lab} }, $oldlab;
          push @{ $timestamp{$key}[$key_counter{$key}-1]{old_lab} }, $timestamp;
        }
        elsif ($lines[$line] =~ m/^Mail/) { 
#           $lines[$line] =~ m/^.*"(.*)"$/;
          my ($junk, $address, $timestamp) = split/\t/, $lines[$line]; 
          push @{ $ace{$key}[$key_counter{$key}-1]{address} }, $address;
          push @{ $timestamp{$key}[$key_counter{$key}-1]{address} }, $timestamp;
        }
        elsif ($lines[$line] =~ m/^E_mail/) { 
#           $lines[$line] =~ m/^.*"(.*)"$/;
          my ($junk, $email, $timestamp) = split/\t/, $lines[$line]; 
          push @{ $ace{$key}[$key_counter{$key}-1]{email} }, $email;
          push @{ $timestamp{$key}[$key_counter{$key}-1]{email} }, $timestamp;
        }
        elsif ($lines[$line] =~ m/^Phone/) { 
#           $lines[$line] =~ m/^.*"(.*)"$/;
          my ($junk, $phone, $timestamp) = split/\t/, $lines[$line]; 
          push @{ $ace{$key}[$key_counter{$key}-1]{phone} }, $phone;
          push @{ $timestamp{$key}[$key_counter{$key}-1]{phone} }, $timestamp;
        }
        elsif ($lines[$line] =~ m/^Fax/) { 
#           $lines[$line] =~ m/^.*"(.*)"$/;
          my ($junk, $fax, $timestamp) = split/\t/, $lines[$line]; 
          push @{ $ace{$key}[$key_counter{$key}-1]{fax} }, $fax;
          push @{ $timestamp{$key}[$key_counter{$key}-1]{fax} }, $timestamp;
        }
        else { print ERR "ERROR : unaccounted line $lines[$line] $line reading authors_contact.ace\n"; }
      } # for ($line = 1; $line < scalar(@lines); $line++) 

      unless ( $ace{$key}[$key_counter{$key}-1]{name}[0] ) { 			# if there's no name entry
        print OUT "\$result = \$conn\->exec( \"INSERT INTO ace_name VALUES (\'ace$total\', NULL, \'1970-01-01_0:0:0\')\");\n";
      } else {									# if there's a name entry
        unless ( scalar( @{ $ace{$key}[$key_counter{$key}-1]{name} } ) > 1 ) {	# only one entry
          my $timestamp = $timestamp{$key}[$key_counter{$key}-1]{name}[0]; 
          print OUT "\$result = \$conn\->exec( \"INSERT INTO ace_name VALUES (\'ace$total\', \'$ace{$key}[$key_counter{$key}-1]{name}[0]\', \'$timestamp\')\");\n";
        } else { 								# if more than one entry
          my %names;			# temp hash to trap and ignore duplicate names
          for my $i ( 0 .. $#{ $ace{$key}[$key_counter{$key}-1]{name} } ) {	# for each of those
            $names{$ace{$key}[$key_counter{$key}-1]{name}[$i]} = "$key : $key_counter{$key} : name : $timestamp{$key}[$key_counter{$key}-1]{name}[$i] : ";
					# store in temp hash as key to filter out repeats
          } # for my $i ( 0 .. $#{ $ace{$key}[$key_counter{$key}-1]{name} } ) 
	    #           if ( keys %names > 1 ) { 	# if multiple name entries
          foreach (sort keys %names) { 	# for each of those (the non-repeats)
# COMMENT OUT NEXT LINE TO NOT PRINT STUFF
#             print $names{$_} . $_ . "\n"; 					# print 'em
            my ($timestamp) = $names{$_} =~ m/: name : (.*) : $/;
            print OUT "\$result = \$conn\->exec( \"INSERT INTO ace_name VALUES (\'ace$total\', \'$_\', \'$timestamp\')\");\n";
          } # foreach (sort keys %names) 
	    #           } # if ( keys %names > 1 ) 	# uncomment to get only those with multiple names
        } # else # if ( scalar( @{ $ace{$key}[$key_counter{$key}-1]{name} } ) > 1 )
      } # else # unless ( $ace{$key}[$key_counter{$key}-1]{name}[0] ) 

      unless ( $ace{$key}[$key_counter{$key}-1]{lab}[0] ) { 			# if there's no lab entry
        print OUT "\$result = \$conn\->exec( \"INSERT INTO ace_lab VALUES (\'ace$total\', NULL, \'1970-01-01_0:0:0\')\");\n";
      } else {									# if there's a lab entry
        unless ( scalar( @{ $ace{$key}[$key_counter{$key}-1]{lab} } ) > 1 ) {	# only one entry
#           print ERR "WRONG : $key has multiple LABS\n";
        } else { 								# if more than one entry
          my $timestamp = $timestamp{$key}[$key_counter{$key}-1]{lab}[0]; 
          print OUT "\$result = \$conn\->exec( \"INSERT INTO ace_lab VALUES (\'ace$total\', \'$ace{$key}[$key_counter{$key}-1]{lab}[0]\', \'$timestamp\')\");\n";
        }
      }

      unless ( $ace{$key}[$key_counter{$key}-1]{old_lab}[0] ) { 			# if there's no old_lab entry
        print OUT "\$result = \$conn\->exec( \"INSERT INTO ace_oldlab VALUES (\'ace$total\', NULL, \'1970-01-01_0:0:0\')\");\n";
      } else {									# if there's a old_lab entry
        my %oldlab;
        for my $i ( 0 .. $#{ $ace{$key}[$key_counter{$key}-1]{old_lab} } ) {	# for each of those
          $oldlab{$ace{$key}[$key_counter{$key}-1]{old_lab}[$i]} = "$key : $key_counter{$key} : old_lab : $timestamp{$key}[$key_counter{$key}-1]{old_lab}[$i] : ";
        } # for my $i ( 0 .. $#{ $ace{$key}[$key_counter{$key}-1]{old_lab} } ) 
        foreach (sort keys %oldlab) { 	# for each of those (the non-repeats)
          my ($timestamp) = $oldlab{$_} =~ m/: old_lab : (.*) : $/;
          print OUT "\$result = \$conn\->exec( \"INSERT INTO ace_oldlab VALUES (\'ace$total\', \'$_\', \'$timestamp\')\");\n";
        } # foreach (sort keys %oldlab) 
      } # else # unless ( $ace{$key}[$key_counter{$key}-1]{old_lab}[0] )

      unless ( $ace{$key}[$key_counter{$key}-1]{address}[0] ) { 			# if there's no address entry
        print OUT "\$result = \$conn\->exec( \"INSERT INTO ace_address VALUES (\'ace$total\', NULL, \'1970-01-01_0:0:0\')\");\n";
      } else {									# if there's a address entry
        my %address;
        for my $i ( 0 .. $#{ $ace{$key}[$key_counter{$key}-1]{address} } ) {	# for each of those
          $address{$ace{$key}[$key_counter{$key}-1]{address}[$i]} = "$key : $key_counter{$key} : address : $timestamp{$key}[$key_counter{$key}-1]{address}[$i] : ";
        } # for my $i ( 0 .. $#{ $ace{$key}[$key_counter{$key}-1]{address} } ) 
        foreach (sort keys %address) { 	# for each of those (the non-repeats)
          my ($timestamp) = $address{$_} =~ m/: address : (.*) : $/;
          print OUT "\$result = \$conn\->exec( \"INSERT INTO ace_address VALUES (\'ace$total\', \'$_\', \'$timestamp\')\");\n";
        } # foreach (sort keys %address) 
      } # else # unless ( $ace{$key}[$key_counter{$key}-1]{address}[0] )

      unless ( $ace{$key}[$key_counter{$key}-1]{email}[0] ) { 			# if there's no email entry
        print OUT "\$result = \$conn\->exec( \"INSERT INTO ace_email VALUES (\'ace$total\', NULL, \'1970-01-01_0:0:0\')\");\n";
      } else {									# if there's a email entry
        my %email;
        for my $i ( 0 .. $#{ $ace{$key}[$key_counter{$key}-1]{email} } ) {	# for each of those
          $email{$ace{$key}[$key_counter{$key}-1]{email}[$i]} = "$key : $key_counter{$key} : email : $timestamp{$key}[$key_counter{$key}-1]{email}[$i] : ";
        } # for my $i ( 0 .. $#{ $ace{$key}[$key_counter{$key}-1]{email} } ) 
        foreach (sort keys %email) { 	# for each of those (the non-repeats)
          my ($timestamp) = $email{$_} =~ m/: email : (.*) : $/;
          print OUT "\$result = \$conn\->exec( \"INSERT INTO ace_email VALUES (\'ace$total\', \'$_\', \'$timestamp\')\");\n";
        } # foreach (sort keys %email) 
      } # else # unless ( $ace{$key}[$key_counter{$key}-1]{email}[0] )

      unless ( $ace{$key}[$key_counter{$key}-1]{phone}[0] ) { 			# if there's no phone entry
        print OUT "\$result = \$conn\->exec( \"INSERT INTO ace_phone VALUES (\'ace$total\', NULL, \'1970-01-01_0:0:0\')\");\n";
      } else {									# if there's a phone entry
        my %phone;
        for my $i ( 0 .. $#{ $ace{$key}[$key_counter{$key}-1]{phone} } ) {	# for each of those
          $phone{$ace{$key}[$key_counter{$key}-1]{phone}[$i]} = "$key : $key_counter{$key} : phone : $timestamp{$key}[$key_counter{$key}-1]{phone}[$i] : ";
        } # for my $i ( 0 .. $#{ $ace{$key}[$key_counter{$key}-1]{phone} } ) 
        foreach (sort keys %phone) { 	# for each of those (the non-repeats)
          my ($timestamp) = $phone{$_} =~ m/: phone : (.*) : $/;
          print OUT "\$result = \$conn\->exec( \"INSERT INTO ace_phone VALUES (\'ace$total\', \'$_\', \'$timestamp\')\");\n";
        } # foreach (sort keys %phone) 
      } # else # unless ( $ace{$key}[$key_counter{$key}-1]{phone}[0] )

      unless ( $ace{$key}[$key_counter{$key}-1]{fax}[0] ) { 			# if there's no fax entry
        print OUT "\$result = \$conn\->exec( \"INSERT INTO ace_fax VALUES (\'ace$total\', NULL, \'1970-01-01_0:0:0\')\");\n";
      } else {									# if there's a fax entry
        my %fax;
        for my $i ( 0 .. $#{ $ace{$key}[$key_counter{$key}-1]{fax} } ) {	# for each of those
          $fax{$ace{$key}[$key_counter{$key}-1]{fax}[$i]} = "$key : $key_counter{$key} : fax : $timestamp{$key}[$key_counter{$key}-1]{fax}[$i] : ";
        } # for my $i ( 0 .. $#{ $ace{$key}[$key_counter{$key}-1]{fax} } ) 
        foreach (sort keys %fax) { 	# for each of those (the non-repeats)
          my ($timestamp) = $fax{$_} =~ m/: fax : (.*) : $/;
          print OUT "\$result = \$conn\->exec( \"INSERT INTO ace_fax VALUES (\'ace$total\', \'$_\', \'$timestamp\')\");\n";
        } # foreach (sort keys %fax) 
      } # else # unless ( $ace{$key}[$key_counter{$key}-1]{fax}[0] )

      print OUT "\n";		# print divider between separate authors
    } # else # unless ($author =~ m/\t[\w\-\']+\s+[\w\-\'][\w\-\']*\t/)
  } # while (<ACE>)
  print "read $total ACE entries\n\n";
} # sub readACE 


sub readWBGtab {
  my %key_counter;		# use this to keep track of how many different times a key has been
				# used for different people with the same name.
  my $total = '';		# number of wbg entries
  $_ = <TAB>; $_ = <TAB>; $_ = <TAB>; $_ = <TAB>; $_ = <TAB>; $_ = <TAB>; $_ = <TAB>; $_ = <TAB>; 
  while (<TAB>) { 
    $_ =~ s///g;		# take out odd thing from end of each line in wbg-tabbed.txt file
    $_ =~ s/'/\\\\'/g;		# need to escape the backslash for perl to pass in again
    $_ =~ s/"/\\"/g;
    $_ =~ s/@/\\@/g;
    chomp;
    my ($title, $firstname, $middlename, $lastname, $suffix, $busstreet, $buscity, $busstate,
      $buspost, $buscountry, $mainphone, $labphone, $officephone, $fax, $email1, $email2, $lastchange,
      $labhead, $labcode, $listed, $papercopy, $paytype, $ponumber, $poposition) = split/\t/, $_;
    my (@array) = split /\t/, $_;


    my $name = '';
    unless ( ($lastname) && ($lastchange) ) { 	# if no name or no lastchange, don't process, print error
      unless ($lastname) { print ERR "wbg-tabbed entry has no name : $_\n"; }
      unless ($lastchange) { print ERR "wbg-tabbed has no lastchange : $_\n"; }
    } else { 			# if name, process
      $total++;

      print OUT "\$result = \$conn\->exec( \"INSERT INTO wbg_number VALUES (\'wbg$total\', \'$total\', CURRENT_TIMESTAMP)\");\n";
#       print OUT "\$result = \$conn\->exec( \"INSERT INTO wbg_timestamp VALUES (\'wbg$total\', CURRENT_TIMESTAMP)\");\n";
      if ($title) { 
        print OUT "\$result = \$conn\->exec( \"INSERT INTO wbg_title VALUES (\'wbg$total\', \'$title\', \'$lastchange\')\");\n"; }
        else { print OUT "\$result = \$conn\->exec( \"INSERT INTO wbg_title VALUES (\'wbg$total\', NULL, \'$lastchange\')\");\n"; }
      if ($firstname) { 
        print OUT "\$result = \$conn\->exec( \"INSERT INTO wbg_firstname VALUES (\'wbg$total\', \'$firstname\', \'$lastchange\')\");\n"; }
        else { print OUT "\$result = \$conn\->exec( \"INSERT INTO wbg_firstname VALUES (\'wbg$total\', NULL, \'$lastchange\')\");\n"; }
      if ($middlename) { 
        print OUT "\$result = \$conn\->exec( \"INSERT INTO wbg_middlename VALUES (\'wbg$total\', \'$middlename\', \'$lastchange\')\");\n"; }
        else { print OUT "\$result = \$conn\->exec( \"INSERT INTO wbg_middlename VALUES (\'wbg$total\', NULL, \'$lastchange\')\");\n"; }
      if ($lastname) { 
        print OUT "\$result = \$conn\->exec( \"INSERT INTO wbg_lastname VALUES (\'wbg$total\', \'$lastname\', \'$lastchange\')\");\n"; }
        else { print OUT "\$result = \$conn\->exec( \"INSERT INTO wbg_lastname VALUES (\'wbg$total\', NULL)\", \'$lastchange\');\n"; }
      if ($suffix) { 
        print OUT "\$result = \$conn\->exec( \"INSERT INTO wbg_suffix VALUES (\'wbg$total\', \'$suffix\', \'$lastchange\')\");\n"; }
        else { print OUT "\$result = \$conn\->exec( \"INSERT INTO wbg_suffix VALUES (\'wbg$total\', NULL, \'$lastchange\')\");\n"; }
      if ($busstreet) { 
        print OUT "\$result = \$conn\->exec( \"INSERT INTO wbg_street VALUES (\'wbg$total\', \'$busstreet\', \'$lastchange\')\");\n"; }
        else { print OUT "\$result = \$conn\->exec( \"INSERT INTO wbg_street VALUES (\'wbg$total\', NULL, \'$lastchange\')\");\n"; }
      if ($buscity) { 
        print OUT "\$result = \$conn\->exec( \"INSERT INTO wbg_city VALUES (\'wbg$total\', \'$buscity\', \'$lastchange\')\");\n"; }
        else { print OUT "\$result = \$conn\->exec( \"INSERT INTO wbg_city VALUES (\'wbg$total\', NULL, \'$lastchange\')\");\n"; }
      if ($busstate) { 
        print OUT "\$result = \$conn\->exec( \"INSERT INTO wbg_state VALUES (\'wbg$total\', \'$busstate\', \'$lastchange\')\");\n"; }
        else { print OUT "\$result = \$conn\->exec( \"INSERT INTO wbg_state VALUES (\'wbg$total\', NULL, \'$lastchange\')\");\n"; }
      if ($buspost) { 
        print OUT "\$result = \$conn\->exec( \"INSERT INTO wbg_post VALUES (\'wbg$total\', \'$buspost\', \'$lastchange\')\");\n"; }
        else { print OUT "\$result = \$conn\->exec( \"INSERT INTO wbg_post VALUES (\'wbg$total\', NULL, \'$lastchange\')\");\n"; }
      if ($buscountry) { 
        print OUT "\$result = \$conn\->exec( \"INSERT INTO wbg_country VALUES (\'wbg$total\', \'$buscountry\', \'$lastchange\')\");\n"; }
        else { print OUT "\$result = \$conn\->exec( \"INSERT INTO wbg_country VALUES (\'wbg$total\', NULL, \'$lastchange\')\");\n"; }
      if ($mainphone) { 
        print OUT "\$result = \$conn\->exec( \"INSERT INTO wbg_mainphone VALUES (\'wbg$total\', \'$mainphone\', \'$lastchange\')\");\n"; }
        else { print OUT "\$result = \$conn\->exec( \"INSERT INTO wbg_mainphone VALUES (\'wbg$total\', NULL, \'$lastchange\')\");\n"; }
      if ($labphone) { 
        print OUT "\$result = \$conn\->exec( \"INSERT INTO wbg_labphone VALUES (\'wbg$total\', \'$labphone\', \'$lastchange\')\");\n"; }
        else { print OUT "\$result = \$conn\->exec( \"INSERT INTO wbg_labphone VALUES (\'wbg$total\', NULL, \'$lastchange\')\");\n"; }
      if ($officephone) { 
        print OUT "\$result = \$conn\->exec( \"INSERT INTO wbg_officephone VALUES (\'wbg$total\', \'$officephone\', \'$lastchange\')\");\n"; }
        else { print OUT "\$result = \$conn\->exec( \"INSERT INTO wbg_officephone VALUES (\'wbg$total\', NULL, \'$lastchange\')\");\n"; }
      if ($fax) { 
        print OUT "\$result = \$conn\->exec( \"INSERT INTO wbg_fax VALUES (\'wbg$total\', \'$fax\', \'$lastchange\')\");\n"; }
        else { print OUT "\$result = \$conn\->exec( \"INSERT INTO wbg_fax VALUES (\'wbg$total\', NULL, \'$lastchange\')\");\n"; }
      if ($email1) { 
        print OUT "\$result = \$conn\->exec( \"INSERT INTO wbg_email VALUES (\'wbg$total\', \'$email1\', \'$lastchange\')\");\n"; }
        else { print OUT "\$result = \$conn\->exec( \"INSERT INTO wbg_email VALUES (\'wbg$total\', NULL, \'$lastchange\')\");\n"; }
      if ($email2) { 
        print OUT "\$result = \$conn\->exec( \"INSERT INTO wbg_email VALUES (\'wbg$total\', \'$email2\', \'$lastchange\')\");\n"; }
      if ($lastchange) { 
        print OUT "\$result = \$conn\->exec( \"INSERT INTO wbg_lastchange VALUES (\'wbg$total\', \'$lastchange\', \'$lastchange\')\");\n"; }
        else { print OUT "\$result = \$conn\->exec( \"INSERT INTO wbg_lastchange VALUES (\'wbg$total\', NULL, \'$lastchange\')\");\n"; }
      if ($labhead) { 
        print OUT "\$result = \$conn\->exec( \"INSERT INTO wbg_labhead VALUES (\'wbg$total\', \'$labhead\', \'$lastchange\')\");\n"; }
        else { print OUT "\$result = \$conn\->exec( \"INSERT INTO wbg_labhead VALUES (\'wbg$total\', NULL, \'$lastchange\')\");\n"; }
      if ($labcode) { 
        print OUT "\$result = \$conn\->exec( \"INSERT INTO wbg_labcode VALUES (\'wbg$total\', \'$labcode\', \'$lastchange\')\");\n"; }
        else { print OUT "\$result = \$conn\->exec( \"INSERT INTO wbg_labcode VALUES (\'wbg$total\', NULL, \'$lastchange\')\");\n"; }
      if ($ponumber) { 
        print OUT "\$result = \$conn\->exec( \"INSERT INTO wbg_ponumber VALUES (\'wbg$total\', \'$ponumber\', \'$lastchange\')\");\n"; }
        else { print OUT "\$result = \$conn\->exec( \"INSERT INTO wbg_ponumber VALUES (\'wbg$total\', NULL, \'$lastchange\')\");\n"; }
      if ($poposition) { 
        print OUT "\$result = \$conn\->exec( \"INSERT INTO wbg_poposition VALUES (\'wbg$total\', \'$poposition\', \'$lastchange\')\");\n"; }
        else { print OUT "\$result = \$conn\->exec( \"INSERT INTO wbg_poposition VALUES (\'wbg$total\', NULL, \'$lastchange\')\");\n"; }
      print OUT "\n";		# divider

      $name = $firstname . " " . $middlename . " " . $lastname; 

      my $firstinitial = '';
      if ($firstname) { $firstinitial = substr($firstname, 0, 1); }
  
      my $address = '';
      if ($busstreet) { $address .= $busstreet . "\n"; }
      if ($buscity) { $address .= $buscity; }
      if ($busstate) { $address .= ", " . $busstate; }
      if ($buspost) { $address .= " " . $buspost; }
      if ($buscountry) { $address .= " " . $buscountry; }
  
      my $extra = '';
      if ($lastchange) { $extra .= $lastchange . "\t"; }
      if ($labhead) { $extra .= $labhead . "\t"; }
      if ($ponumber) { $extra .= $ponumber . "\t"; }
      if ($poposition) { $extra .= $poposition; }
  
      my $key = $lastname . "_" . $firstinitial;		# make key using last and initial
      $key_counter{$key}++;	# add to counter, so that we can keep track of those with same name
				  # with this number
  
      push @{ $wbg{$key}[$key_counter{$key}-1]{name} }, $name;
				  # use %key_counter value minus one because we don't need to make the
				  # array unnecessarily bigger
      if ($labphone) { push @{ $wbg{$key}[$key_counter{$key}-1]{lab} }, $labphone; }
      if ($fax) { push @{ $wbg{$key}[$key_counter{$key}-1]{fax} }, $fax; }
      if ($officephone) { push @{ $wbg{$key}[$key_counter{$key}-1]{office} }, $officephone; }
      if ($mainphone) { push @{ $wbg{$key}[$key_counter{$key}-1]{phone} }, $mainphone; }
      if ($email1) { push @{ $wbg{$key}[$key_counter{$key}-1]{email} }, $email1; }
      if ($email2) { push @{ $wbg{$key}[$key_counter{$key}-1]{email} }, $email2; }
      if ($labcode) { push @{ $wbg{$key}[$key_counter{$key}-1]{lab} }, $labcode; }
      if ($address) { push @{$wbg{$key}[$key_counter{$key}-1]{address} }, $address; }
      if ($extra) { push @{$wbg{$key}[$key_counter{$key}-1]{extra} }, $extra; }
    } # else # unless ($lastname)
  } # while (<TAB>)
  print "read $total WBG entries\n\n";
} # sub readWBGtab


sub outputAceHash {		# show that ace hash has been properly populated
  my $total = '';
  my ($entry, $counter, $type, $i); 				# initialize counters
  for $entry ( sort keys %ace ) {				# get keys of HoH
    for $counter ( 0 .. scalar( @{ $ace{$entry} } )-1 ) {	# get numbers of HoHoA
      $total++;
      for $type ( sort keys %{ $ace{$entry}[$counter] } ) {	# get keys of HoHoAoH
        for $i ( 0 .. $#{ $ace{$entry}[$counter]{$type} } ) {	# get numbers of HoHoAoHoA
          print "$entry : $counter : $type : $ace{$entry}[$counter]{$type}[$i]\n";
								# print the values
        } # for $i ( 0 .. $#{ $ace{$entry}[$counter]{$type} } )
      } # for $type ( sort keys $ace{$entry}[$counter] )
      print "\n";						# newline divides each entry
    } # for $counter ( 1 .. $# { $ace{$entry} } ) 
  } # for $entry ( sort keys %ace )
  print "DIVIDER : $total ace\n\n";
} # sub outputWbgHash

sub outputWbgHash {		# show that wbg hash has been properly populated
  my $total = '';
  my ($entry, $counter, $type, $i); 				# initialize counters
  for $entry ( sort keys %wbg ) {				# get keys of HoH
    for $counter ( 0 .. scalar( @{ $wbg{$entry} } )-1 ) {	# get numbers of HoHoA
      $total++;
      for $type ( sort keys %{ $wbg{$entry}[$counter] } ) {	# get keys of HoHoAoH
        for $i ( 0 .. $#{ $wbg{$entry}[$counter]{$type} } ) {	# get numbers of HoHoAoHoA
          print "$entry : $counter : $type : $wbg{$entry}[$counter]{$type}[$i]\n";
								# print the values
        } # for $i ( 0 .. $#{ $wbg{$entry}[$counter]{$type} } )
      } # for $type ( sort keys $wbg{$entry}[$counter] )
      print "\n";						# newline divides each entry
    } # for $counter ( 1 .. $# { $wbg{$entry} } ) 
  } # for $entry ( sort keys %wbg )
  print "DIVIDER : $total wbg\n\n";
} # sub outputWbgHash


sub makePGtables {
  print OUT "#!\/usr\/bin\/perl5.6.0\n";
  print OUT "\n";
  print OUT "use lib qw( \/usr\/lib/perl5\/site_perl\/5.6.1\/i686-linux\/ );\n";
  print OUT "use Pg;\n";
  print OUT "\n";
  print OUT "\$conn = Pg::connectdb(\"dbname=testdb\");\n";
  print OUT "die \$conn->errorMessage unless PGRES_CONNECTION_OK eq \$conn->status;\n\n";

} # sub makePGtables

sub oldMakePGtables {
  print OUT "\$result = \$conn\->exec( \"CREATE TABLE wbg_number ( joinkey TEXT, wbg_number INTEGER, wbg_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP )\");\n";
#   print OUT "\$result = \$conn\->exec( \"CREATE TABLE wbg_timestamp ( joinkey TEXT, wbg_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP, wbg_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE TABLE wbg_title ( joinkey TEXT, wbg_title TEXT, wbg_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE TABLE wbg_firstname ( joinkey TEXT, wbg_firstname TEXT, wbg_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE TABLE wbg_middlename ( joinkey TEXT, wbg_middlename TEXT, wbg_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE TABLE wbg_lastname ( joinkey TEXT, wbg_lastname TEXT, wbg_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE TABLE wbg_suffix ( joinkey TEXT, wbg_suffix TEXT, wbg_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE TABLE wbg_street ( joinkey TEXT, wbg_street TEXT, wbg_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE TABLE wbg_city ( joinkey TEXT, wbg_city TEXT, wbg_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE TABLE wbg_state ( joinkey TEXT, wbg_state TEXT, wbg_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE TABLE wbg_post ( joinkey TEXT, wbg_post TEXT, wbg_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE TABLE wbg_country ( joinkey TEXT, wbg_country TEXT, wbg_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE TABLE wbg_mainphone ( joinkey TEXT, wbg_mainphone TEXT, wbg_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE TABLE wbg_labphone ( joinkey TEXT, wbg_labphone TEXT, wbg_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE TABLE wbg_officephone ( joinkey TEXT, wbg_officephone TEXT, wbg_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE TABLE wbg_fax ( joinkey TEXT, wbg_fax TEXT, wbg_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE TABLE wbg_email ( joinkey TEXT, wbg_email TEXT, wbg_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE TABLE wbg_lastchange ( joinkey TEXT, wbg_lastchange TIMESTAMP, wbg_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE TABLE wbg_labhead ( joinkey TEXT, wbg_labhead TEXT, wbg_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE TABLE wbg_labcode ( joinkey TEXT, wbg_labcode TEXT, wbg_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE TABLE wbg_ponumber ( joinkey TEXT, wbg_ponumber TEXT, wbg_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE TABLE wbg_poposition ( joinkey TEXT, wbg_poposition TEXT, wbg_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE TABLE wbg_comparedvs ( joinkey TEXT, wbg_comparedvs TEXT, wbg_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE TABLE wbg_comparedby ( joinkey TEXT, wbg_comparedby TEXT, wbg_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE TABLE wbg_rejectedvs ( joinkey TEXT, wbg_rejectedvs TEXT, wbg_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE TABLE wbg_rejectedby ( joinkey TEXT, wbg_rejectedby TEXT, wbg_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE TABLE wbg_groupedwith ( joinkey TEXT, wbg_groupedwith TEXT, wbg_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE TABLE wbg_grouped ( joinkey TEXT, wbg_grouped TEXT, wbg_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP )\");\n";

  print OUT "\$result = \$conn\->exec( \"CREATE UNIQUE INDEX wbg_number_idx ON wbg_number ( joinkey )\");\n";
#   print OUT "\$result = \$conn\->exec( \"CREATE UNIQUE INDEX wbg_timestamp_idx ON wbg_timestamp ( joinkey )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE UNIQUE INDEX wbg_title_idx ON wbg_title ( joinkey )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE UNIQUE INDEX wbg_firstname_idx ON wbg_firstname ( joinkey )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE UNIQUE INDEX wbg_middlename_idx ON wbg_middlename ( joinkey )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE UNIQUE INDEX wbg_lastname_idx ON wbg_lastname ( joinkey )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE UNIQUE INDEX wbg_suffix_idx ON wbg_suffix ( joinkey )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE UNIQUE INDEX wbg_street_idx ON wbg_street ( joinkey )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE UNIQUE INDEX wbg_city_idx ON wbg_city ( joinkey )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE UNIQUE INDEX wbg_state_idx ON wbg_state ( joinkey )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE UNIQUE INDEX wbg_post_idx ON wbg_post ( joinkey )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE UNIQUE INDEX wbg_country_idx ON wbg_country ( joinkey )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE INDEX wbg_mainphone_idx ON wbg_mainphone ( joinkey )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE INDEX wbg_labphone_idx ON wbg_labphone ( joinkey )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE INDEX wbg_officephone_idx ON wbg_officephone ( joinkey )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE INDEX wbg_fax_idx ON wbg_fax ( joinkey )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE INDEX wbg_email_idx ON wbg_email ( joinkey )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE UNIQUE INDEX wbg_lastchange_idx ON wbg_lastchange ( joinkey )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE UNIQUE INDEX wbg_labhead_idx ON wbg_labhead ( joinkey )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE UNIQUE INDEX wbg_labcode_idx ON wbg_labcode ( joinkey )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE UNIQUE INDEX wbg_ponumber_idx ON wbg_ponumber ( joinkey )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE UNIQUE INDEX wbg_poposition_idx ON wbg_poposition ( joinkey )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE INDEX wbg_comparedvs_idx ON wbg_comparedvs ( joinkey )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE INDEX wbg_comparedby_idx ON wbg_comparedby ( joinkey )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE INDEX wbg_rejectedvs_idx ON wbg_rejectedvs ( joinkey )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE INDEX wbg_rejectedby_idx ON wbg_rejectedby ( joinkey )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE INDEX wbg_groupedwith_idx ON wbg_groupedwith ( joinkey )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE INDEX wbg_grouped_idx ON wbg_grouped ( joinkey )\");\n";

  print OUT "\$result = \$conn\->exec( \"GRANT ALL ON wbg_number TO nobody\");\n";
#   print OUT "\$result = \$conn\->exec( \"GRANT ALL ON wbg_timestamp TO nobody\");\n";
  print OUT "\$result = \$conn\->exec( \"GRANT ALL ON wbg_title TO nobody\");\n";
  print OUT "\$result = \$conn\->exec( \"GRANT ALL ON wbg_firstname TO nobody\");\n";
  print OUT "\$result = \$conn\->exec( \"GRANT ALL ON wbg_middlename TO nobody\");\n";
  print OUT "\$result = \$conn\->exec( \"GRANT ALL ON wbg_lastname TO nobody\");\n";
  print OUT "\$result = \$conn\->exec( \"GRANT ALL ON wbg_suffix TO nobody\");\n";
  print OUT "\$result = \$conn\->exec( \"GRANT ALL ON wbg_street TO nobody\");\n";
  print OUT "\$result = \$conn\->exec( \"GRANT ALL ON wbg_city TO nobody\");\n";
  print OUT "\$result = \$conn\->exec( \"GRANT ALL ON wbg_state TO nobody\");\n";
  print OUT "\$result = \$conn\->exec( \"GRANT ALL ON wbg_post TO nobody\");\n";
  print OUT "\$result = \$conn\->exec( \"GRANT ALL ON wbg_country TO nobody\");\n";
  print OUT "\$result = \$conn\->exec( \"GRANT ALL ON wbg_mainphone TO nobody\");\n";
  print OUT "\$result = \$conn\->exec( \"GRANT ALL ON wbg_labphone TO nobody\");\n";
  print OUT "\$result = \$conn\->exec( \"GRANT ALL ON wbg_officephone TO nobody\");\n";
  print OUT "\$result = \$conn\->exec( \"GRANT ALL ON wbg_fax TO nobody\");\n";
  print OUT "\$result = \$conn\->exec( \"GRANT ALL ON wbg_email TO nobody\");\n";
  print OUT "\$result = \$conn\->exec( \"GRANT ALL ON wbg_lastchange TO nobody\");\n";
  print OUT "\$result = \$conn\->exec( \"GRANT ALL ON wbg_labhead TO nobody\");\n";
  print OUT "\$result = \$conn\->exec( \"GRANT ALL ON wbg_labcode TO nobody\");\n";
  print OUT "\$result = \$conn\->exec( \"GRANT ALL ON wbg_ponumber TO nobody\");\n";
  print OUT "\$result = \$conn\->exec( \"GRANT ALL ON wbg_poposition TO nobody\");\n";
  print OUT "\$result = \$conn\->exec( \"GRANT ALL ON wbg_comparedvs TO nobody\");\n";
  print OUT "\$result = \$conn\->exec( \"GRANT ALL ON wbg_comparedby TO nobody\");\n";
  print OUT "\$result = \$conn\->exec( \"GRANT ALL ON wbg_rejectedvs TO nobody\");\n";
  print OUT "\$result = \$conn\->exec( \"GRANT ALL ON wbg_rejectedby TO nobody\");\n";
  print OUT "\$result = \$conn\->exec( \"GRANT ALL ON wbg_groupedwith TO nobody\");\n";
  print OUT "\$result = \$conn\->exec( \"GRANT ALL ON wbg_grouped TO nobody\");\n";
  print OUT "\n";

  print OUT "\$result = \$conn\->exec( \"CREATE TABLE ace_number ( joinkey TEXT, ace_number INTEGER, ace_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP  )\");\n";
#   print OUT "\$result = \$conn\->exec( \"CREATE TABLE ace_timestamp ( joinkey TEXT, ace_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE TABLE ace_author ( joinkey TEXT, ace_author TEXT, ace_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP  )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE TABLE ace_name ( joinkey TEXT, ace_name TEXT, ace_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP  )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE TABLE ace_lab ( joinkey TEXT, ace_lab TEXT, ace_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP  )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE TABLE ace_oldlab ( joinkey TEXT, ace_oldlab TEXT, ace_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP  )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE TABLE ace_address ( joinkey TEXT, ace_address TEXT, ace_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP  )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE TABLE ace_email ( joinkey TEXT, ace_email TEXT, ace_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP  )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE TABLE ace_phone ( joinkey TEXT, ace_phone TEXT, ace_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP  )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE TABLE ace_fax ( joinkey TEXT, ace_fax TEXT, ace_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP  )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE TABLE ace_comparedvs ( joinkey TEXT, ace_comparedvs TEXT, ace_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP  )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE TABLE ace_comparedby ( joinkey TEXT, ace_comparedby TEXT, ace_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP  )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE TABLE ace_rejectedvs ( joinkey TEXT, ace_rejectedvs TEXT, ace_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP  )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE TABLE ace_rejectedby ( joinkey TEXT, ace_rejectedby TEXT, ace_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP  )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE TABLE ace_groupedwith ( joinkey TEXT, ace_groupedwith TEXT, ace_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP  )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE TABLE ace_grouped ( joinkey TEXT, ace_grouped TEXT, ace_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP  )\");\n";

  print OUT "\$result = \$conn\->exec( \"CREATE UNIQUE INDEX ace_number_idx ON ace_number ( joinkey )\");\n";
#   print OUT "\$result = \$conn\->exec( \"CREATE UNIQUE INDEX ace_timestamp_idx ON ace_timestamp ( joinkey )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE UNIQUE INDEX ace_author_idx ON ace_author ( joinkey )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE INDEX ace_name_idx ON ace_name ( joinkey )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE UNIQUE INDEX ace_lab_idx ON ace_lab ( joinkey )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE INDEX ace_oldlab_idx ON ace_oldlab ( joinkey )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE INDEX ace_address_idx ON ace_address ( joinkey )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE INDEX ace_email_idx ON ace_email ( joinkey )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE INDEX ace_phone_idx ON ace_phone ( joinkey )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE INDEX ace_fax_idx ON ace_fax ( joinkey )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE INDEX ace_comparedvs_idx ON ace_comparedvs ( joinkey )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE INDEX ace_comparedby_idx ON ace_comparedby ( joinkey )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE INDEX ace_rejectedvs_idx ON ace_rejectedvs ( joinkey )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE INDEX ace_rejectedby_idx ON ace_rejectedby ( joinkey )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE INDEX ace_groupedwith_idx ON ace_groupedwith ( joinkey )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE INDEX ace_grouped_idx ON ace_grouped ( joinkey )\");\n";

  print OUT "\$result = \$conn\->exec( \"GRANT ALL ON ace_number TO nobody\");\n";
#   print OUT "\$result = \$conn\->exec( \"GRANT ALL ON ace_timestamp TO nobody\");\n";
  print OUT "\$result = \$conn\->exec( \"GRANT ALL ON ace_author TO nobody\");\n";
  print OUT "\$result = \$conn\->exec( \"GRANT ALL ON ace_name TO nobody\");\n";
  print OUT "\$result = \$conn\->exec( \"GRANT ALL ON ace_lab TO nobody\");\n";
  print OUT "\$result = \$conn\->exec( \"GRANT ALL ON ace_oldlab TO nobody\");\n";
  print OUT "\$result = \$conn\->exec( \"GRANT ALL ON ace_address TO nobody\");\n";
  print OUT "\$result = \$conn\->exec( \"GRANT ALL ON ace_email TO nobody\");\n";
  print OUT "\$result = \$conn\->exec( \"GRANT ALL ON ace_phone TO nobody\");\n";
  print OUT "\$result = \$conn\->exec( \"GRANT ALL ON ace_fax TO nobody\");\n";
  print OUT "\$result = \$conn\->exec( \"GRANT ALL ON ace_comparedvs TO nobody\");\n";
  print OUT "\$result = \$conn\->exec( \"GRANT ALL ON ace_comparedby TO nobody\");\n";
  print OUT "\$result = \$conn\->exec( \"GRANT ALL ON ace_rejectedvs TO nobody\");\n";
  print OUT "\$result = \$conn\->exec( \"GRANT ALL ON ace_rejectedby TO nobody\");\n";
  print OUT "\$result = \$conn\->exec( \"GRANT ALL ON ace_groupedwith TO nobody\");\n";
  print OUT "\$result = \$conn\->exec( \"GRANT ALL ON ace_grouped TO nobody\");\n";
  print OUT "\n";

} # sub oldMakePGtables



# wbg tables : 
# wbg_number	unique
# wbg_title	unique
# wbg_firstname	unique
# wbg_middlename	unique
# wbg_lastname	unique
# wbg_suffix	unique
# wbg_street	unique
# wbg_city	unique
# wbg_state	unique
# wbg_post	unique
# wbg_country	unique
# wbg_mainphone
# wbg_labphone
# wbg_officephone
# wbg_fax
# wbg_email
# wbg_lastchange	unique
# wbg_labhead	unique
# wbg_labcode	unique
# wbg_ponumber	unique
# wbg_poposition	unique
# wbg_comparedvs
# wbg_comparedby
# wbg_rejectedvs
# wbg_rejectedby
# wbg_groupedwith
# wbg_grouped

# ace tables : 
# ace_number	unique
# ace_author	unique
# ace_name
# ace_lab	unique
# ace_oldlab
# ace_address
# ace_email
# ace_phone
# ace_fax
# ace_comparedvs
# ace_comparedby
# ace_rejectedvs
# ace_rejectedby
# ace_groupedwith
# ace_grouped
