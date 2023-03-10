#!/usr/bin/perl -w

# Revision to be used with wrapper.  Take the time as passed in by wrapper to
# create a time dependent gophbib.endnote.time file to keep different versions
# based on different times the scripts were called.  Change to not print out the
# accession number nor the heading labels.  Change to read in the time from the
# argument passed instead of the input file.  Change to get the input file
# directly from the web with a system call to wget.  2002-01-26
#
# Update to work by itself with Theresa's update.txt (rename to update and 
# manually edited to have 5 lines only [join titles and authors]) and create an
# insertfile to enter all the data for these updated entries.  2002 03 05
#
# Updated to also enter NULLs for ref_pdf, ref_tif, ref_lib, ref_html, and 
# ref_hardcopy.  2002 03 07

# Program: cgc_to_endnote.pl
#    Erich Schwarz, emsch@its.caltech.edu, 3/27/00
#    (Revision of buggy 12/00 version.)
# 
# Purpose: Convert CGC references to Endnote references.

# 1. If not given a CGC file as argument, ask for its name.

chdir("/home/postgres/work/reference/gophbibless_update") || die "Cannot go to /home/postgres/work/reference/gophbibless_update ($!)";

$infile = 'update';

my $time = time;

$endfile = ($infile . ".endnote." . $time);
$botchfile = ($infile . ".botchlist." . $time);
$insertfile = "insertfile_update_" . $time . ".pl";
print "The input file is $infile; the output file $endfile;\n";
print "   and the list of botched citations is $botchfile.\n";


# Stick extra line onto infile to make last entry printable.
# Note: this is an utter kluge but should let me get on with other things.

open (INFILE, ">>$infile") || die "CGC file $infile not found.  $!\n";
print INFILE ("\n");
close INFILE;

# 2. Open the CGC and future Endnote files or die.

open (INFILE, "$infile") || die "CGC file $infile not found.  $!\n";
open (INS, ">$insertfile") || die "Couldn't create PG file $insertfile.  $!\n";
open (END, ">$endfile") || die "Couldn't open Endnote file $endfile.  $!\n";
open (BOTCHFILE, ">$botchfile") || die "Couldn't open botch list $botchfile.  $!\n";

print INS "#!\/usr\/bin\/perl5.6.0\n";
print INS "\n";
print INS "use lib qw( \/usr\/lib/perl5\/site_perl\/5.6.1\/i686-linux\/ );\n";
print INS "use Pg;\n";
print INS "\n";
print INS "\$conn = Pg::connectdb(\"dbname=testdb\");\n";
print INS "die \$conn->errorMessage unless PGRES_CONNECTION_OK eq \$conn->status;\n\n";

# 3. Insert header required for .endnote to be readable by Endnote
#       as a tab-delimited file.
# print END ("*Journal Article\n");
# print END ("Label\tAccession Number\tAuthor\tTitle\tJournal\tVolume\tPages\tYear\tAbstract\n");

# 4. Do a big initial round of initialization (to be redone at each Key).

$key = "";
$ignore_this_key = "-1";
$medline = "";  # Could alternatively be "no_medline_number".
$authors = "";
$title = "";
$authors_reading = "yes";	# Purpose: 
$title_reading = "no";          # Make sure that blocked 
$citation_reading = "no";       #   text is only read when 
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

undef $/;
my $whole_thing = <INFILE>;
my @entries = $whole_thing =~ m/(CGC.*?\n\n)/gs;

foreach my $entry (@entries) {
  my ($cgc, $authors, $title, $citation, $type) = $entry =~ m/^CGC #(\d+)\n(.*?)\n(.*?)\n(.*?)\n(.*?)\n\n/gs;

    # deal authors
  chomp ($authors);
  # Convert ";" into "//"
  $authors =~ s/;/\/\//g;  # Must be global subst.
  $authors =~ s/([a-zA-Z]+) ([a-zA-Z]+)/$1, $2/g;	#Global comma-ing.
  $authors_reading = "yes";
                
    # Process out values from $citation.
  if ($citation =~ /^(.*) : ([\S]*-[\S]*)[\s]+([\d]+)/) {	# not sure, maybe books ? colon 
								# in different place
    $citation_text = $1;
    $page_numbers = $2;
    $year = $3;
  } # if ($citation =~ /^(.*) : ([\S]*-[\S]*)[\s]+([\d]+)/)
  elsif ($citation =~ /^(.*) ([\S]+): ([\S]*-[\S]*)[\s]+([\d]+)/) {	# general case with all data
    $citation_text = $1;   
    $volume_number = $2;  
    $page_numbers = $3;   
    $year = $4;
  } # elsif ($citation =~ /^(.*) ([\S]+): ([\S]*-[\S]*)[\s]+([\d]+)/)
  elsif ($citation =~ /^(.*) ([\S]+): ([\S]+)[\s]+([\d]+)/) {		# case of only one page
    $citation_text = $1;   
    $volume_number = $2;  
    $page_numbers = $3;   
    $year = $4;
  } # elsif ($citation =~ /^(.*) ([\S]+): ([\S]*-[\S]*)[\s]+([\d]+)/)
  else {
    $botch_warning = "Citation $cgc was botched.\n";
    print BOTCHFILE ($botch_warning . "\n");
    $botch_warning = "";
  } # else 

  print END ($cgc . "\t");
  print END ($authors . "\t");
  print END ($title . "\t");
  print END ($citation_text . "\t");			# journal
  print END ($volume_number . "\t");
  print END ($page_numbers . "\t");
  print END ($year . "\t");
  print END ($abstract . "\n");

  print INS "\$result = \$conn\->exec( \"INSERT INTO ref_cgc VALUES (\'cgc$cgc\', \'$cgc\')\");\n";
  print INS "\$result = \$conn\->exec( \"INSERT INTO ref_reference_by VALUES (\'cgc$cgc\', \'postgres\')\");\n";
  print INS "\$result = \$conn\->exec( \"INSERT INTO ref_checked_out VALUES (\'cgc$cgc\', NULL)\");\n";
  print INS "\$result = \$conn\->exec( \"INSERT INTO ref_pdf VALUES (\'cgc$cgc\', NULL)\");\n";
  print INS "\$result = \$conn\->exec( \"INSERT INTO ref_tif VALUES (\'cgc$cgc\', NULL)\");\n";
  print INS "\$result = \$conn\->exec( \"INSERT INTO ref_lib VALUES (\'cgc$cgc\', NULL)\");\n";
  print INS "\$result = \$conn\->exec( \"INSERT INTO ref_html VALUES (\'cgc$cgc\', NULL)\");\n";
  print INS "\$result = \$conn\->exec( \"INSERT INTO ref_hardcopy VALUES (\'cgc$cgc\', NULL)\");\n";

  if ($authors) { 
    $authors =~ s/'/''/g; $authors =~ s/"/\\"/g; $authors =~ s/@/\\@/g;
    print INS "\$result = \$conn\->exec( \"INSERT INTO ref_author VALUES (\'cgc$cgc\', \'$authors\')\");\n";
  } else {
    print INS "\$result = \$conn\->exec( \"INSERT INTO ref_author VALUES (\'cgc$cgc\', NULL)\");\n";
  } # else # if ($authors) 

  if ($title) { 
    $title =~ s/'/''/g; $title =~ s/"/\\"/g; $title =~ s/@/\\@/g;
    print INS "\$result = \$conn\->exec( \"INSERT INTO ref_title VALUES (\'cgc$cgc\', \'$title\')\");\n";
  } else {
    print INS "\$result = \$conn\->exec( \"INSERT INTO ref_title VALUES (\'cgc$cgc\', NULL)\");\n";
  } # else # if ($title) 

  if ($citation_text) { 
    $citation_text =~ s/'/''/g; $citation_text =~ s/"/\\"/g; $citation_text =~ s/@/\\@/g;
    print INS "\$result = \$conn\->exec( \"INSERT INTO ref_journal VALUES (\'cgc$cgc\', \'$citation_text\')\");\n";
  } else {
    print INS "\$result = \$conn\->exec( \"INSERT INTO ref_journal VALUES (\'cgc$cgc\', NULL)\");\n";
  } # else # if ($citation_text) 

  if ($volume_number) { 
    $volume_number =~ s/'/''/g; $volume_number =~ s/"/\\"/g; $volume_number =~ s/@/\\@/g;
    print INS "\$result = \$conn\->exec( \"INSERT INTO ref_volume VALUES (\'cgc$cgc\', \'$volume_number\')\");\n";
  } else {
    print INS "\$result = \$conn\->exec( \"INSERT INTO ref_volume VALUES (\'cgc$cgc\', NULL)\");\n";
  } # else # if ($volume_number) 

  if ($page_numbers) { 
    $page_numbers =~ s/'/''/g; $page_numbers =~ s/"/\\"/g; $page_numbers =~ s/@/\\@/g;
    print INS "\$result = \$conn\->exec( \"INSERT INTO ref_pages VALUES (\'cgc$cgc\', \'$page_numbers\')\");\n";
  } else {
    print INS "\$result = \$conn\->exec( \"INSERT INTO ref_pages VALUES (\'cgc$cgc\', NULL)\");\n";
  } # else # if ($page_numbers) 

  if ($year) { 
    $year =~ s/'/''/g; $year =~ s/"/\\"/g; $year =~ s/@/\\@/g;
    print INS "\$result = \$conn\->exec( \"INSERT INTO ref_year VALUES (\'cgc$cgc\', \'$year\')\");\n";
  } else {
    print INS "\$result = \$conn\->exec( \"INSERT INTO ref_year VALUES (\'cgc$cgc\', NULL)\");\n";
  } # else # if ($year) 


  if ($abstract) { 
    $abstract =~ s/'/''/g; $abstract =~ s/"/\\"/g; $abstract =~ s/@/\\@/g;
    print INS "\$result = \$conn\->exec( \"INSERT INTO ref_abstract VALUES (\'cgc$cgc\', \'$abstract\')\");\n";
  } else {
    print INS "\$result = \$conn\->exec( \"INSERT INTO ref_abstract VALUES (\'cgc$cgc\', NULL)\");\n";
  } # else # if ($abstract) 



#   print "CG : $cgc\n";
#   print "AU : $authors\n";
#   print "TI : $title\n";
#   print "CI : $citation\n";
#   print "TY : $type\n\n";
} # foreach my $entry (@entries)

# 		print END ($key . "\t");
# 		print END ($authors . "\t");
# 		print END ($title . "\t");
# 		print END ($citation_text . "\t");
# 		print END ($volume_number . "\t");
# 		print END ($page_numbers . "\t");
# 		print END ($year . "\t");
# 		print END ($abstract . "\n");

sub oldStuff {

while (<INFILE>) 
{
	if ($_ =~ /Key:[\D]+([\d]+)/) 
	{
		# Initialize a bunch of non-key variables.

		$medline = "";  # Could alternatively be "no_medline_number".
		$authors = "";
		$title = "";
		$authors_reading = "no";	# Purpose:
		$title_reading = "no";		# Make sure that blocked 
		$citation_reading = "no";	#   text is only read when 
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

        elsif ($_ =~ /Abstract:(.*)/)
        {
                # Enter all text after "Abstract: " into $abstract.
                
                $citation_reading = "no";
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
		print OUTFILE ($abstract . "\n");
	}
}

} # sub oldStuff
