#!/usr/bin/perl -w

# Revision to be used with wrapper.  Take the time as passed in by wrapper to
# create a time dependent gophbib.endnote.time file to keep different versions
# based on different times the scripts were called.  Change to not print out the
# accession number nor the heading labels.  Change to read in the time from the
# argument passed instead of the input file.  Change to get the input file
# directly from the web with a system call to wget.  2002-01-26
#
# Updated to get the latest version take out the new ----etc dividers, and do
# the usual erich thing.  2002-04-03
#
# Updated to take out the  that were messing up the parsing.  2002 06 17
#
# Updated to get the pages from Theresa's page by parts.  2002 08 26
# Updated to check with previous gophbib by system call diff.  If different,
# run the insertmaker.pl (which creates and runs an insertfile and moves 
# gophbib files to a new directory, and also emails daniel)  2002 08 26
#
# Added possible full_citation without year, and without year or volume number
# 2004 02 23
#
#################################################################################
#
# Program: cgc_to_endnote.pl
#    Erich Schwarz, emsch@its.caltech.edu, 3/27/00
#    (Revision of buggy 12/00 version.)
# 
# Purpose: Convert CGC references to Endnote references.
#
#################################################################################
#
# Development directory for 
# /home/postgres/work/pgpopulation/wpa_new_wbpaper_tables/perl_wpa_match/cgc/cgc_to_wpa_with_module.pl
# Updated to check if the created endnote file is different from the previous
# one, and if so to use the wpa_match.pm at
# /home/postgres/work/pgpopulation/wpa_new_wbpaper_tables/perl_wpa_match/
# to check whether it's a new or old paper, then create it / merge it / flag it
# for a manual check in
# /home/postgres/work/pgpopulation/wpa_new_wbpaper_tables/perl_wpa_match/manual_check_file.endnote
# Update the wbpapers with pmid from ncbi if missing volume or pages first.



use LWP::Simple;
use Jex;
use Pg;

use lib qw( /home/postgres/work/pgpopulation/wpa_new_wbpaper_tables/perl_wpa_match );
use wpa_match qw(processEndnote) ;	# process endnote file, match to wpa_ papers and create / merge / update them


my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

# 1. If not given a CGC file as argument, ask for its name.

chdir("/home/postgres/work/reference/20050803_wpa_automatic") or die "Cannot go to /home/postgres/work/reference/20050803_wpa_automatic ($!)";

$infile = 'gophbib';
$outfile = ($infile . ".endnote" );
$botchfile = ($infile . ".botchlist" );
print "The input file is $infile; the output file $outfile;\n";
print "   and the list of botched citations is $botchfile.\n";

# &getBigGophbib();	# UNCOMMENT THIS
my $diff = `diff gophbib gophbib.current`;
if ($diff) { &doStuff(); }

sub getBigGophbib {
  my $file = get "http://biosci.umn.edu/CGC/Bibliography/gophbib";
  $file =~ s///g;
  $file =~ s/             -------------------//g;
  open (OUT, ">$infile") or die "Cannot create $infile : $!";
  print OUT $file;
  close (OUT) or die "Cannot close $infile : $!";
} # sub getBigGophbib


my %keys_wpa; 

sub doStuff {
#   &convertToEndnote();	# UNCOMMENT THIS
  &processEndnote('/home/postgres/work/reference/20050803_wpa_automatic/gophbib.endnote');
#   &emailAndSortFiles();			# UNCOMMENT THIS
} # sub doStuff


  


sub emailAndSortFiles {
  system("mkdir /home/postgres/work/reference/new_way_automatic/from_parts/$date");
  my $insertfile = "/home/postgres/work/reference/new_way_automatic/from_parts/$date/insertfile." . $date . ".pl";
  open (PG, ">$insertfile") or die "Cannot create $insertfile : $!";
  
  
  close PG or die "Cannot close $insertfile : $!";
  
  my $user = 'automatic_cgc_updating_script@tazendra.caltech.edu';
  my $email = 'azurebrd@tazendra.caltech.edu';				# UNCOMMENT THIS (fix this)
#   my $email = 'qwang@its.caltech.edu, ranjana@its.caltech.edu';		# added Ranjana since she's part of the paper pipeline.  for Eimear.  2005 05 26
  my $subject = 'Updated CGC data from Theresa in PostgreSQL';
#   my $body = 'See http://minerva.caltech.edu/~postgres/cgi-bin/endnoter.cgi New files at $updatefile and $updatefile2';
  my $body = 'See http://tazendra.caltech.edu/~postgres/cgi-bin/wbpaper_editor.cgi New files at $updatefile and $updatefile2';
  &mailer($user, $email, $subject, $body);

  rename("/home/postgres/work/reference/new_way_automatic/from_parts/gophbib", "/home/postgres/work/reference/new_way_automatic/from_parts/$date/gophbib");
  rename("/home/postgres/work/reference/new_way_automatic/from_parts/gophbib.botchlist", "/home/postgres/work/reference/new_way_automatic/from_parts/$date/gophbib.botchlist");
  rename("/home/postgres/work/reference/new_way_automatic/from_parts/gophbib.endnote", "/home/postgres/work/reference/new_way_automatic/from_parts/$date/gophbib.endnote");
} # sub emailAndSortFiles

sub convertToEndnote {
  # 2. Open the CGC and future Endnote files or die.
  
#   system("cp gophbib gophbib.current");	# UNCOMMENT THIS
  open (INFILE, "<$infile") || die "CGC file $infile not found.  $!\n";
  open (OUTFILE, ">$outfile") || die "Couldn't open Endnote file $outfile.  $!\n";
  open (BOTCHFILE, ">$botchfile") || die "Couldn't open botch list $botchfile.  $!\n";
  
  # 3. Insert header required for .endnote to be readable by Endnote
  #       as a tab-delimited file.
  
  # print OUTFILE ("*Journal Article\n");
  # print OUTFILE ("Label\tAccession Number\tAuthor\tTitle\tJournal\tVolume\tPages\tYear\tAbstract\n");
  
  # 4. Do a big initial round of initialization (to be redone at each Key).
  
  $key = "";
  $ignore_this_key = "-1";
  $medline = "";  # Could alternatively be "no_medline_number".
  $authors = "";
  $title = "";
  $genes = "";
  $authors_reading = "yes";	# Purpose: 
  $title_reading = "no";          # Make sure that blocked 
  $citation_reading = "no";       #   text is only read when 
  $genes_reading = "no";				# added for reading genes 2003 08 25 -- Juancarlos
  $abstract_reading = "no";	#   it should be.
  
  $volume_title = "";
  $volume_number = "";
  $page_numbers = "";
  $year = "";
  $abstract = "";
  $first_citation_line = "";
  $full_citation = "";
  $append_to_citation = "";
  $citation_text = "";
  
  $botch_warning = "";
  
  # 5. Extract everything I want in a format which is of real use.
  
  while (<INFILE>) 
  {
  	if ($_ =~ /Key:[\D]+([\d]+)/) 
  	{
  		# Initialize a bunch of non-key variables.
  
  		$medline = "";  # Could alternatively be "no_medline_number".
  		$authors = "";
  		$title = "";
  		$genes = "";					# added for reading genes 2003 08 25 -- Juancarlos
  		$authors_reading = "no";	# Purpose:
  		$title_reading = "no";		# Make sure that blocked 
  		$citation_reading = "no";	#   text is only read when 
  		$genes_reading = "no";				# added for reading genes 2003 08 25 -- Juancarlos
                  $abstract_reading = "no";	#   it should be.
  
  		$volume_title = "";
  		$volume_number = "";
  		$page_numbers = "";  
  		$year = "";
  		$abstract = "";
  		$first_citation_line = "";
  		$full_citation = "";
  		$append_to_citation = "";
  		$citation_text = "";
  
  		$botch_warning = "";
  
  		# Get on with ordinary stuff.
  
  		# Scan number after "Key: " into $key.
  		$key = $1;
  		if ($key eq "") 
  		{
  			die ("No CGC index key no. found! $!\n");
  		}
  	}
  	elsif ($_ =~ /Medline:[\D]+([\d]+)/) 
  	{
  		# Scan number after "Medline: " into $medline.
  		$medline = $1;
          }
  	elsif ($_ =~ /Authors:[ ]+(.+)/) 
  	{
  		# Pick up list into $authors.
  		$authors = $1;
  		chomp ($authors);
  		# Convert ";" into "//"
  		$authors =~ s/;/\/\//g;  # Must be global subst.
  		$authors =~ s/([a-zA-Z]+) ([a-zA-Z]+)/$1, $2/g;	#Global comma-ing.
  		$authors_reading = "yes";
  	}
          elsif ($_ =~ /^[ ]{13}(.+)/ && $authors_reading eq "yes")
          {
                  # Append following lines of blocked text to $authors.
                  $append_to_authors = $1;   
                  chomp ($append_to_authors);
                  $authors = $authors . " " . $append_to_authors;
                  # Convert ";" into "//"
                  $authors =~ s/;/\/\//g;  # Must be global subst.
                  $authors =~ s/([a-zA-Z]+) ([a-zA-Z]+)/$1, $2/g; #Global comma-ing.
          }
          elsif ($_ =~ /Title: (.+)/)
          {
  		$authors_reading = "no";
                  # Enter all text after "Title: " into $title.
                  $title = $1;
                  chomp ($title);
  		$title_reading = "yes";
  	}
  	elsif ($_ =~ /^[ ]{13}(.+)/ && $title_reading eq "yes") 
  	{
  		# Append following lines of blocked text to $title.		
  		$append_to_title = $1;
  		chomp ($append_to_title);
  		$title = $title . " " . $append_to_title;
  	}
  
  # ---------------- Citation processing.  ----------------
  
          elsif ($_ =~ /Citation: (.+)/) 
  	{
  		$title_reading = "no";
  		$citation_reading = "yes";
  		$first_citation_line = $1;   
  		chomp ($first_citation_line);
  		$full_citation = $first_citation_line;
  	}
          elsif ($_ =~ /^[ ]{13}(.+)/ && $citation_reading eq "yes") 
  	{
                  # Append following lines of blocked text to $full_citation.
  
                  $append_to_citation = $1;   
                  chomp ($append_to_citation);
                  $full_citation = $full_citation . " " . $append_to_citation;
  	}
          elsif ($citation_reading eq "yes")
          {
                  # Process out values from $full_citation.
  
  		if ($full_citation =~ /^(.*) : ([\S]*-[\S]*)[\s]+([\d]+)/) 
  		{
  			$citation_text = $1;
                  	$page_numbers = $2;
                  	$year = $3;
                  	$citation_reading = "no";			
  		}                
  		elsif ($full_citation =~ /^(.*) ([\S]+): ([\S]*-[\S]*)[\s]+([\d]+)/)
          	{
                  	$citation_text = $1;   
                  	$volume_number = $2;  
                  	$page_numbers = $3;   
                  	$year = $4;
  			$citation_reading = "no";
          	}
  		elsif ($full_citation =~ /^(.*) ([\S]+): ([\S]*-[\S]*)/)
          	{
                  	$citation_text = $1;   
                  	$volume_number = $2;  
                  	$page_numbers = $3;   
  			$citation_reading = "no";
          	}
  		elsif ($full_citation =~ /^(.*): ([\S]*-[\S]*)/)
          	{
                  	$citation_text = $1;   
                  	$page_numbers = $2;   
  			$citation_reading = "no";
          	}
  		elsif ($ignore_this_key ne $key) 
  		{
  		$botch_warning = "Citation $key was botched.\n";
  		print BOTCHFILE ($botch_warning . "\n");
                  $botch_warning = "";
  		$ignore_this_key = $key;
  		}
          }
  
  # ---------------- End citation processing.  ----------------
  
  # Skip "Type: " and "Genes: " lines and their text.
  # 2003 08 25 Added dealing with Genes to Erich's script -- Juancarlos
          elsif ($_ =~ /Genes: (.+)/)
          {
                  $citation_reading = "no";
                  # Enter all text after "Genes: " into $genes.
                  $genes = $1;
                  chomp ($genes);
  		$genes_reading = "yes";
  	}
  	elsif ($_ =~ /^[ ]{13}(.+)/ && $genes_reading eq "yes") 
  	{
  		# Append following lines of blocked text to $genes.		
  		$append_to_genes = $1;
  		chomp ($append_to_genes);
  		$genes = $genes . " " . $append_to_genes;
  	}
  
          elsif ($_ =~ /Abstract:(.*)/)
          {
                  # Enter all text after "Abstract: " into $abstract.
                  
                  $genes_reading = "no";
                  $abstract = $1;   
                  chomp ($abstract);
                  $abstract_reading = "yes";
  		if ($abstract =~ /[ ](.+)/) 		# CHECK SYNTAX HERE...
  		{
  			($abstract =~ s/^[ ]//);
  		}
  	}
          elsif ($_ =~ /^[ ]{13}(.+)/ && $abstract_reading eq "yes")
          {
                  # Append following lines of blocked text to $abstract.
                  $append_to_abstract = $1;  
                  chomp ($append_to_abstract);
                  $abstract = $abstract . " " . $append_to_abstract;
          }
  
  # 5. Print output.
  
  	elsif ($abstract_reading eq "yes")
  	{
  		print OUTFILE ($key . "\t");
  # 		print OUTFILE ($medline . "\t");
  		print OUTFILE ($authors . "\t");
                  print OUTFILE ($title . "\t");
  		print OUTFILE ($citation_text . "\t");
  		print OUTFILE ($volume_number . "\t");
  		print OUTFILE ($page_numbers . "\t");
  		print OUTFILE ($year . "\t");
  		print OUTFILE ($abstract . "\t");
  		print OUTFILE ($genes . "\n");	# 2003 08 25  added genes at end
  	}
  }
} # sub convertToEndnote


