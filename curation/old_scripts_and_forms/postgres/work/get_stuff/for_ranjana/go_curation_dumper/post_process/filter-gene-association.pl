#!/usr/bin/perl
#

# filter-gene-association files
# version: $Revision: 1.24 $
# date: $Date: 2005/10/04 03:00:41 $
#
# specification of the gene_association format is defined at:
#   http://www.geneontology.org/GO.annotation.html#file
#
# Requires Perl 5.6.1 or later
#
# POD documentation is at the bottom of the file.
#  to see the documentation use pod2text from the command line
#
# Maintained by the Gene Ontology Consortium
#  author: Mike Cherry (cherry@stanford.edu)
#          Anand Sethuraman (anand@genome.stanford.edu) updated in July 2005
#
###############################################################################

use strict;
use FindBin qw($Bin);

############ Define GO CVS directory, OBO and abbreviations files #############
# copy $Bin variable as it will be changed in the next step
my $gocvsbase = $Bin;

# if GO CVS directory structure changed this will also need to change
$gocvsbase =~ s|/software/utilities||;

# my $obofile = "$gocvsbase/ontology/gene_ontology.obo";
my $obofile = "gene_ontology.obo";
# my $abbsfile = "$gocvsbase/doc/GO.xrf_abbs";
my $abbsfile = "GO.xrf_abbs";

# when a report is requested (-r switch), the report file plus a file containing all the 
# error-free lines in the gene-assoc will be written out to the following location
# Note: all the user submitted gene-assoc files will be under this directory too
my $configfile;
###############################################################################

############ Get and check user passed in single character switches ##########
# process command line arguments
our $opt_h;
our $opt_q;
our $opt_d;
our $opt_e;
our $opt_w;
our $opt_r;
our $opt_o;
our $opt_i;
our $opt_p;
our $opt_x;

use Getopt::Std;

getopts('hqdewro:i:p:x:');

# TRUE if the user wants the details report
# otherwise just the summary is provided
my $printhelp = defined($opt_h);
my $quietmode = defined($opt_q);
my $detail = defined($opt_d);
my $writebad = defined($opt_e);
my $writegood = defined($opt_w);
my $writereport = defined($opt_r);
my $inputfile = "-";
my $projectname = "";

# check the passed in options
&check_options;
###############################################################################

################## Define variables to keep track of errors ###################
# number of line in the input file
my $linenum = 0;

# current line of text
my $line = "";

# array of errors, column number is the index
my @errors = ();

# total errors, column specific errors and line errors
my $totalerr = 0;

# errors with the whole line
my $lineerr = 0;

# total number of lines writing with the -w option
my $totallines = 0;

# earliest time annotations were found
# this is for the date check
use constant MINYEAR => 1985;

# date for limiting IEA associations
my ($sec,$min,$hour,$mday,$mon,$currentyear) = localtime(time);
$currentyear += 1900;
$mon += 1;
($mon = "0" . $mon) if ($mon < 10);
($mday = "0" . $mday) if ($mday < 10);
my $datestring = $currentyear . $mon . $mday;

my $limitdate = $datestring - 10000;
print STDERR "IEA limit date defined as $limitdate\n" if ($detail);

# Hash to store dates listed in column number 14
my %dates = ();

# defined information about each column in the gene_association files
my @column = ();

# Column positions 
use constant DB => 0;
use constant DB_OBJECT_ID => 1;
use constant DB_OBJECT_SYMBOL => 2;
use constant QUALIFIER => 3;
use constant GOID => 4;
use constant REFERENCE => 5;
use constant EVIDENCE => 6;
use constant WITH => 7;
use constant ASPECT => 8;
use constant DB_OBJECT_NAME => 9;
use constant DB_OBJECT_SYNONYM => 10;
use constant DB_OBJECT_TYPE => 11;
use constant TAXON => 12;
use constant DATE => 13;
use constant ASSIGNED_BY => 14;

# Number of TAB delimited columns in file
use constant COLNUM => 15;

# Definition of positions in column array
use constant LABEL => 0;
use constant CARDINAL => 1;
use constant SPECIAL => 2;
use constant CHECKDB => 3;

# Define Column Information
&populate_column_array;

# Get Evidence Codes, Object Types, Qualifier Types
my (%evicodes,  %objtypes, %qualtypes);
&populate_evi_obj_qual_hashes;

# Load TAXID specification, which project files can have which TAXIDs
my (%taxon2species);
&populate_taxon2species_hash;

# Parse the OBO file and populate goid hashes, including alt and obsolete GOIDs
my (%goids, %altids, %obsids);
&parse_obo_file;;

# Parse the abbreviations file and find defined abbreviations
my %abbrev;
&parse_abbs_file;

### store header from parsed gene association config file
my $gene_assoc_header = "";

### parse gene associations file
&parse_gene_assoc_file;

exit;

###############################################################################
################################           ####################################
################################ FUNCTIONS ####################################
################################           ####################################
###############################################################################

###############################################################################
sub check_options {
###############################################################################

    if ($writegood && $writebad) {
	die "Unable to have both -w and -e on.  This would print both
good and bad lines to STDOUT, effectively just duplicating the input
file.\nExiting now.\n\n";

    }

    if ($printhelp) {

	print STDERR <<END;

      Usage:  filter-gene-association.pl [-h] [-q] [-d] [-w] [-r] [-o filename] [-i input file] [-p project]

	  -h displays this message
	  -q quiet mode
	  -i input to present a standard file, gzipped, or compressed file as input.
             STDIN is the default.
          -d switches to a line by line report of errors identified on STDERR
          -e write all "bad lines" to STDOUT
          -w write all "good lines" to STDOUT
          -r write e-mail report and file of all "good lines" to files
          -o alternative path to the gene_ontology.obo file.
          -p force project name
             to turn off taxid check state project name as nocheck
          -x alternative path to GO.xrf_abbs file

	  examples:

	      check a file for any errors, obsolete GOIDs or old IEA annotations

		  % filter-gene-association.pl -i gene_association.sgd.gz

	      filter any problems and output the validated lines, including headers

		  % filter-gene-association.pl -i gene_association.fb.gz -w > filtered-output

	      check file without the taxid checking on, and write the bad lines to STDOUT

		  % filter-gene-association.pl -i gene_association.fb.gz -p nocheck -e > bad-lines

END

    exit;

    }

    if ($opt_o) {
	$obofile = $opt_o;
    }
	
    if ($opt_x) {
	$abbsfile = $opt_x;
    }
	
    if ($opt_i) {
	$inputfile = $opt_i;
	$projectname = $inputfile;
	$projectname =~ s/.*gene_association\.//;
	$projectname =~ s/\.gz//;
    }
	
    if ($opt_p) {
	$projectname = $opt_p;
	print STDERR "Project Name set to $projectname\n" if ($detail);
    }
	
    print STDERR "Input filename = $inputfile\n" if ($detail);
    print STDERR "OBO filename = $obofile\n" if ($detail);
    print STDERR "Abbrev. filename = $abbsfile\n" if ($detail);
    print STDERR "Project Name = $projectname\n" if ($detail);
	
    if ( lc($opt_p) eq 'nocheck' ) {
	$projectname = "";
    }

}

###############################################################################
sub populate_column_array {
###############################################################################
# Column information:  Name, Check Cardinality, Special Check Included, Check DB name

    $column[DB] = ['DB', 1, 1, 0];
    $column[DB_OBJECT_ID] = ['DB_Object_ID', 1, 0, 0];
    $column[DB_OBJECT_SYMBOL] = ['DB_Object_Symbol', 1, 0, 0];
    $column[QUALIFIER] = ['Qualifier', 0, 1, 0];
    $column[GOID] = ['GOID', 1, 1, 0];
    $column[REFERENCE] = ['DB:Reference', 2, 1, 1];
    $column[EVIDENCE] = ['Evidence', 1, 1, 0];
    $column[WITH] = ['With', 2, 1, 1];
    $column[ASPECT] = ['Aspect', 1, 0];
    $column[DB_OBJECT_NAME] = ['DB_Object_Name', 0, 0, 0];
    $column[DB_OBJECT_SYNONYM] = ['DB_Object_Synonym', 0, 0, 0];
    $column[DB_OBJECT_TYPE] = ['DB_Object_Type', 1, 1, 0];
    $column[TAXON] = ['Taxon', 1, 1, 0];
    $column[DATE] = ['Date', 1, 1, 0];
    $column[ASSIGNED_BY] = ['Assigned_by', 1, 1, 0];

}

###############################################################################
sub populate_evi_obj_qual_hashes {
###############################################################################

    %evicodes = ( IC => 1,  IDA => 1, IEA => 1, IEP => 1, IGI => 1,
		 IMP => 1, IPI => 1, ISS => 1, NAS => 1, ND => 1,
		 TAS => 1, NR => 1, RCA =>1 );

    %objtypes = ( gene => 1, transcript => 1, protein => 1,
		 protein_structure => 1, complex => 1 );

    %qualtypes = ( not => 1, contributes_to => 1, colocalizes_with => 1 );

}

###############################################################################
sub populate_taxon2species_hash {
###############################################################################
# which taxon IDs are allowed in which project files

%taxon2species = ('taxon:686'=>'tigr_Vcholerae', 'taxon:3702'=>'tair',
		  'taxon:4528'=>'gramene_oryza', 'taxon:4530'=>'gramene_oryza',
		  'taxon:4532'=>'gramene_oryza', 'taxon:4533'=>'gramene_oryza',
		  'taxon:4534'=>'gramene_oryza', 'taxon:4535'=>'gramene_oryza',
		  'taxon:4536'=>'gramene_oryza', 'taxon:4537'=>'gramene_oryza',
		  'taxon:4538'=>'gramene_oryza', 'taxon:4539'=>'gramene_oryza',
		  'taxon:4896'=>'GeneDB_Spombe', 'taxon:4932'=>'sgd', 'taxon:5476'=>'cgd',
		  'taxon:5664'=>'GeneDB_Lmajor', 'taxon:5691'=>'tigr_Tbrucei_chr2',
		  'taxon:5782'=>'ddb', 'taxon:5833'=>'GeneDB_Pfalciparum', 'taxon:6239'=>'wb',
		  'taxon:7227'=>'fb', 'taxon:7955'=>'zfin', 'taxon:9606'=>'goa_human',
		  'taxon:9031'=>'goa_chicken',
		  'taxon:10090'=>'mgi', 'taxon:10116'=>'rgd', 'taxon:29689'=>'gramene_oryza',
		  'taxon:29690'=>'gramene_oryza', 'taxon:37546'=>'GeneDB_tsetse',
		  'taxon:39946'=>'gramene_oryza', 'taxon:39947'=>'gramene_oryza',
		  'taxon:40148'=>'gramene_oryza', 'taxon:40149'=>'gramene_oryza',
		  'taxon:52545'=>'gramene_oryza', 'taxon:63629'=>'gramene_oryza',
		  'taxon:65489'=>'gramene_oryza', 'taxon:65491'=>'gramene_oryza',
		  'taxon:77588'=>'gramene_oryza', 'taxon:83307'=>'gramene_oryza',
		  'taxon:83308'=>'gramene_oryza', 'taxon:83309'=>'gramene_oryza',
		  'taxon:110450'=>'gramene_oryza', 'taxon:110451'=>'gramene_oryza',
		  'taxon:127571'=>'gramene_oryza', 'taxon:185431'=>'GeneDB_Tbrucei',
		  'taxon:195099'=>'tigr_Cjejuni', 'taxon:198094'=>'tigr_Banthracis',
		  'taxon:211586'=>'tigr_Soneidensis', 'taxon:223283'=>'tigr_Psyringae',
		  'taxon:227377'=>'tigr_Cburnetii', 'taxon:243164'=>'tigr_Dethenogenes',
		  'taxon:243231'=>'tigr_Gsulfurreducens', 'taxon:243233'=>'tigr_Mcapsulatus',
		  'taxon:246200'=>'tigr_Spomeroyi', 'taxon:265669'=>'tigr_Lmonocytogenes'
		  );
}


###############################################################################
sub parse_obo_file {
###############################################################################

    my $readgoid;
    my $cntaltid = 0;
    my $cntobsgoid = 0;

    open (OBSGA, $obofile) || die "Cannot open file $obofile: $!\n";

    while ( <OBSGA> ) {
	chomp;

	if (/^id: (GO:\d\d\d\d\d\d\d)/) {
	    $readgoid = $1;
	    $goids{$1}++;
	}

	if (/^alt_id: (GO:\d\d\d\d\d\d\d)/) {
	    $altids{$1} = $readgoid;
	    $cntaltid++;
	}

	if (/^is_obsolete: true/) {
	    $obsids{$readgoid}++;
	    $cntobsgoid++;
	}
    }

    print STDERR "Read $cntobsgoid obsolete GOIDs from $obofile\n" if ($detail);

    close (OBSGA);

}

###############################################################################
sub parse_abbs_file {
###############################################################################

    my $cntabbs = 0;
    my $cntsyn = 0;

    open (ABBS, $abbsfile) || die "Cannot open file $abbsfile: $!\n";

    while ( <ABBS> ) {
	chomp;

	if (/^abbreviation: (\S+)/) {
	    $abbrev{ lc($1) }++;
	    $cntabbs++;
	}

	if (/^synonym: (\S+)/) {
	    my $foundstring = $1;
	    unless ( defined($abbrev{ lc($1) } )) {
		$abbrev{ lc($foundstring) }++;
		$cntsyn++;
	    }
	}
    }

    close (ABBS);

    print STDERR "Read $cntabbs abbreviations and $cntsyn synonyms from $abbsfile\n\n" if ($detail);

}

###############################################################################
sub parse_gene_assoc_config_file {
###############################################################################

    my ($base_file_name) = @_;  ### eg: gene_association.sgd

    my %gene_assoc_meta_data = ();

    $configfile = "${base_file_name}.conf";

    open (META, $configfile) || die "Cannot open file $configfile for reading: $!\n";

    while ( <META> ) {
	chomp;

	if (/^project\_name=(.+)$/) {
	    next if ($1 eq 'unspecified');
	    $gene_assoc_meta_data{ "A" } = "!Project_name: $1\n";	    
	}
	elsif (/^project\_url=(.+)$/) {
	    next if ($1 eq 'unspecified');
	    $gene_assoc_meta_data{ "B" } = "!URL: $1\n";
	}
	elsif (/^contact\_email=(.+)$/) {
	    next if ($1 eq 'unspecified');
	    $gene_assoc_meta_data{ "C" } = "!Contact Email: $1\n";
	}
	elsif (/^funding\_source=(.+)$/) {
	    next if ($1 eq 'unspecified');
	    $gene_assoc_meta_data{ "D" } = "!Funding: $1\n";
	}
	else {
	    next;
	}
    }

    close (META);

    foreach my $confinfo (sort keys %gene_assoc_meta_data) {
	$gene_assoc_header .= $gene_assoc_meta_data{ $confinfo };
    }

    $gene_assoc_header .= "!\n";

}

###############################################################################
sub parse_gene_assoc_file {
###############################################################################

    my $errorfound = 0;
    my $base_file_name;

    if  ( ($inputfile =~ /(.+)\.gz$/) || ($inputfile  =~ /(.+)\.Z$/) ) {
	open (INPUT, "gzcat $inputfile |") || die "Cannot open gzipped input $inputfile for reading: $!\n";
	$base_file_name = $1;
    } 
    else {
	open (INPUT, $inputfile) || die "Cannot open input file $inputfile: $!\n";
	$base_file_name = $inputfile;
    }
    
    if ($writereport) {

	&parse_gene_assoc_config_file($base_file_name);

	open (FILTER, "| /usr/bin/gzip > ${base_file_name}.filtered.gz") || die "Cannot write gzipped output ${base_file_name}.filtered.gz: $!\n";
	print FILTER "$gene_assoc_header";
    }

    my $headerCount = 1;

    # Begin input loop
    while ( defined($line = <INPUT>) ) {
	$linenum++;
	$errorfound = 0;
	
	unless ( $line =~ /.*\n/ ) {
	    &checkwarn ("$linenum: No end of line character, the last line of the file is probably missing a return character\n");
	    $lineerr++;
	    $totalerr++;
	    $errorfound = 1;
	}
	
	chomp $line;
	
        # skip comment lines
	if ($line =~ m/^\!/) {
	    print "$line\n" if ($writegood);
	    next;
	}

# blank line?
	if ( $line eq "" ) {
	    &checkwarn ("$linenum: BLANK line, these should be deleted or start with an \'\!\'\n");
	    $lineerr++;
	    $totalerr++;
	    next;
	}
	
# split TAB delimited columns
	my @cols = split(/\t/, $line);
	
	if ( @cols ne COLNUM ) {
	    &checkwarn ("$linenum: Too few or too many columns on this line, found " . @cols . ". There should be " . COLNUM . ". Line skipped.\n");
	    # increment error counters
	    $lineerr++;
	    $totalerr++;
	    next;
	}
	
# loop through all the columns on this line of input
	for (my $cnum=0; $cnum < @column; $cnum++) {
	    
# Any leading or trailing spaces?
	    my $value = $cols[$cnum];
	    if ( ($value =~ m/^\s/) || ($value =~ m/\s$/) ) {
		&checkwarn ($linenum . ": " . $column[$cnum][LABEL] . " column=" . ($cnum + 1) . " leading or trailing white space: \"" . $value . "\"\n");
		# error to have leading or trailing spaces, remove them and continue
		$cols[$cnum] =~ s/^\s+//;
		$cols[$cnum] =~ s/\s+$//;
		# increment error counters
		$errors[$cnum]++;
		$totalerr++;
		$errorfound = 1;
	    }
	    
# Check Cardinality
	    if ($column[$cnum][CARDINAL] == 1) {
		if ($cols[$cnum] eq "") {
		    &checkwarn ($linenum . ": " . $column[$cnum][LABEL] . " column=" . ($cnum + 1) . " cardinality should equal 1, found 0: \"" . $cols[$cnum] . "\"\n");
		    $errors[$cnum]++;
		    $totalerr++;
		    $errorfound = 1;
		}
		my @field = split(/\|/, $cols[$cnum]);
		if ( @field > 1 ) {
		    &checkwarn ($linenum . ": " . $column[$cnum][LABEL] . " column=" . ($cnum + 1) . " cardinality should equal 1, found > 1: \"" . $cols[$cnum] . "\"\n");
		    $errors[$cnum]++;
		    $totalerr++;
		    $errorfound = 1;
		}
	    }
	    
# Specific Checks
	    if ($column[$cnum][SPECIAL]) {
		
		# Was a valid DB abbreviation used
		if ($cnum == DB) {
		    unless ($abbrev{ lc($cols[DB]) }) {
			&checkwarn ("$linenum: " . $column[DB][LABEL] . " column=" . (DB + 1) . " allowed database abbreviation not correct, found \"" . $cols[DB] . "\"\n");
			$errors[DB]++;
			$totalerr++;
			$errorfound = 1;
		    }
		}
		
		# Check for valid DB name
		if ($cnum == DB_OBJECT_ID) {
		    my @fields = split(/:/, lc($cols[DB_OBJECT_ID]));
		    unless ($abbrev{ $fields[0] }) {
			&checkwarn ("$linenum: " . $column[DB_OBJECT_ID][LABEL] . " column=" . (DB_OBJECT_ID + 1) . " allowed database abbreviation not correct, found \"" . $fields[0] . "\"\n");
			$errors[DB_OBJECT_ID]++;
			$totalerr++;
			$errorfound = 1;
		    }
		}
		
		# Qualifier Column on NOT, contributes_to, colocalizes_with
		if ($cnum == QUALIFIER) {
		    my @field = split(/\|/, $cols[QUALIFIER]);
		    foreach my $value (@field) {
			unless ( $qualtypes{ lc($value) } ) {
			    &checkwarn ($linenum . ": " . $column[QUALIFIER][LABEL] . " column=" . (QUALIFIER + 1) . " allowed type not present, found \"" . $cols[QUALIFIER] . "\"\n");
			    $errors[QUALIFIER]++;
			    $totalerr++;
			    $errorfound = 1;
			}
		    }
		}
		
		# If GOID in WITH column is it valid
		
		if ($cnum == WITH && $cols[WITH] ne "") {
		    
		    my @field = split(/\|/, $cols[WITH]);
		    foreach my $value (@field) {
			
			if ($value =~ /^GO\:\w+/) {
			    #
			    # Use the %obsids hash to check if current GOID is obsolete
			    # if TRUE then $is_obs equals 1
			    #
			    
			    if (defined($obsids{$value})) {
				#obsolete
				&checkwarn ("$linenum: " . $column[WITH][LABEL] . " column=" . (WITH + 1) . " obsolete GOID in WITH: \"" . $cols[WITH] . "\"\n");
				$errors[WITH]++;
				$totalerr++;
				$errorfound = 1;
			    } elsif (defined($altids{$cols[WITH]})) {
				# Use the %altids hash to check if current GOID is an alternate
				# The secondary is the key, the primary ID is the value of the hash.
				&checkwarn ("$linenum: " . $column[WITH][LABEL] . " column=" . (WITH + 1) . " this is a secondary ID " . $cols[WITH] . " should use " . $altids{$cols[WITH]} . " instead.\n");
				$errors[WITH]++;
				$totalerr++;
				$errorfound = 1;
			    }
			    
			    if ( (! defined($goids{$value})) && ($errorfound == 0) ) {
				# A secondary or obsolete GOID
				&checkwarn ("$linenum: " . $column[WITH][LABEL] . " column=" . (WITH + 1) . " GOID in WITH \"$value\" is not valid: \"" . $cols[WITH] . "\"\n");
				$errors[WITH]++;
				$totalerr++;
				$errorfound = 1;
			    }
			    
			}
		    }
		}
		
		
		# Aspect only one of P, F or C
		if ($cnum == ASPECT) {
		    unless ( ($cols[ASPECT] eq 'P') || ($cols[ASPECT] eq 'F') || ($cols[ASPECT] eq 'C') ) {
			&checkwarn ("$linenum: " . $column[ASPECT][LABEL] . " column=" . (ASPECT + 1) . " only P, F, or C allowed \"" . $cols[ASPECT] . "\"\n");
			$errors[ASPECT]++;
			$totalerr++;
			$errorfound = 1;
		    }
		}
		
		# Was a valid Evidence code used
		if ($cnum == EVIDENCE) {
		    unless ($evicodes{ $cols[EVIDENCE] }) {
			&checkwarn ("$linenum: " . $column[EVIDENCE][LABEL] . " column=" . (EVIDENCE + 1) . " allowed evidence codes not present, found \"" . $cols[EVIDENCE] . "\"\n");
			$errors[EVIDENCE]++;
			$totalerr++;
			$errorfound = 1;
		    }
		}
		
		# Was a valid Object type provided
		if ($cnum == DB_OBJECT_TYPE) {
		    unless ($objtypes{ lc($cols[DB_OBJECT_TYPE]) }) {
			&checkwarn ("$linenum: " . $column[DB_OBJECT_TYPE][LABEL] . " column=" . (DB_OBJECT_TYPE + 1) . " allowed type not present, found \"" . $cols[DB_OBJECT_TYPE] . "\"\n");
			$errors[DB_OBJECT_TYPE]++;
			$totalerr++;
			$errorfound = 1;
		    }
		}
		
		# Basic format check for reference ids
		if ($cnum == REFERENCE) {
		    
		    my @field = split(/\|/, $cols[REFERENCE]);
		    
		    foreach my $value (@field) {
			
			# NOTE: WB uses [ & ] in their reference IDs
			unless ( $value =~ m/\w+\:[\[\]\w]+/ ) {
			    &checkwarn ("$linenum: " . $column[REFERENCE][LABEL] . " column=" . (REFERENCE + 1) . " format of reference not DB:REFID \"" . $cols[REFERENCE] . "\"\n");
			    $errors[REFERENCE]++;
			    $totalerr++;
			    $errorfound = 1;
			} elsif ($value =~ /^GO\:\w+/) {
			    
			    # Use the %obsids hash to check if current GOID is obsolete
			    # if TRUE then $is_obs equals 1
			    
			    #obsolete
			    if (defined($obsids{$value})) {
				&checkwarn ("$linenum: " . $column[REFERENCE][LABEL] . " column=" . (REFERENCE + 1) . " obsolete GOID \"$value\" as REFERENCE: \"" . $cols[REFERENCE] . "\"\n");
				$errors[REFERENCE]++;
				$totalerr++;
				$errorfound = 1;
			    } elsif (defined($altids{$cols[REFERENCE]})) {
				# Use the %altids hash to check if current GOID is an alternate
				# The secondary is the key, the primary ID is the value of the hash.
				&checkwarn ("$linenum: " . $column[REFERENCE][LABEL] . " column=" . (REFERENCE + 1) . " this is a secondary ID " . $cols[REFERENCE] . " should use " . $altids{$cols[REFERENCE]} . " instead.\n");
				$errors[REFERENCE]++;
				$totalerr++;
				$errorfound = 1;
			    }
			    
			    if ( (! defined($goids{$value})) && ($errorfound == 0) ) {
				# A secondary or obsolete GOID
				&checkwarn ("$linenum: " . $column[REFERENCE][LABEL] . " column=" . (REFERENCE + 1) . " GOID as REFERENCE \"$value\" is not valid: \"" . $cols[REFERENCE] . "\"\n");
				$errors[REFERENCE]++;
				$totalerr++;
				$errorfound = 1;
			    }
			    
			}
		    }
		}
		
		# Taxon string must start with taxon:
		if ($cnum == TAXON) {
		    my @field = split(/\|/, $cols[TAXON]);
		    foreach my $value (@field) {
			unless ( $value =~ m/^taxon:/ ) {
			    &checkwarn ("$linenum: " . $column[TAXON][LABEL] . " column=" . (TAXON + 1) . " must start with taxon: \"" . $cols[TAXON] . "\"\n");
			    $errors[TAXON]++;
			    $totalerr++;
			    $errorfound = 1;
			}
		    }
		    
#
# Only certain taxids are allowed is particular gene association files.
# The %taxon2species hash allows this check.
# If the a particular taxon is not allowed thats an error
#
# if input is from STDIN then we don't know the gene association files creator,
# in this case do not to the species filtering
#
# A taxon ID is only in the %taxon2species if there is a MOD file that specifically
# provides it.  If the taxon ID is not in the hash then do not filter
#
		    unless ($projectname eq "") {
			if (defined( $taxon2species{ $cols[TAXON] } ) ) {
			    unless ( lc($projectname) eq lc($taxon2species{ $cols[TAXON] } ) ) {
				&checkwarn ("$linenum: " . $column[TAXON][LABEL] . " column=" . (TAXON + 1) . " taxid not allowed for this project: \"" . lc($projectname) . "\" <--> \"" . $cols[TAXON] . "\"\n");
				$errors[TAXON]++;
				$totalerr++;
				$errorfound = 1;
			    }
			}
		    }
		}
		
# GOID string must start with GO:
		if ($cnum == GOID) {
		    
		    unless ( $cols[GOID] =~ m/^GO:/ ) {
			&checkwarn ("$linenum: " . $column[GOID][LABEL] . " column=" . (GOID + 1) . " must start with GO: \"" . $cols[GOID] . "\"\n");
			$errors[GOID]++;
			$totalerr++;
			$errorfound = 1;
		    }
		    
# Use the %obsids hash to check if current GOID is obsolete
# if TRUE then $is_obs equals 1
		    
		    if (defined($obsids{$cols[GOID]})) {
			# obsolete
			&checkwarn ("$linenum: " . $column[GOID][LABEL] . " column=" . (GOID + 1) . " obsolete GOID: \"" . $cols[GOID] . "\"\n");
			$errors[GOID]++;
			$totalerr++;
			$errorfound = 1;
		    } elsif (defined($altids{$cols[GOID]})) {
			# Use the %altids hash to check if current GOID is an alternate
			# The secondary is the key, the primary ID is the value of the hash.
			&checkwarn ("$linenum: " . $column[GOID][LABEL] . " column=" . (GOID + 1) . " this is a secondary ID " . $cols[GOID] . " should use " . $altids{$cols[GOID]} . " instead.\n");
			$errors[GOID]++;
			$totalerr++;
			$errorfound = 1;
		    }
		    
		    if ( (! defined($goids{$value})) && ($errorfound == 0) ) {
			# A secondary or obsolete GOID
			&checkwarn ("$linenum: " . $column[GOID][LABEL] . " column=" . (GOID + 1) . " GOID \"$value\" is not valid: \"" . $cols[GOID] . "\"\n");
			$errors[GOID]++;
			$totalerr++;
			$errorfound = 1;
		    }
		    
		}
		
# Check Date in proper format, YYYYMMDD
# arbitarily define the MINYEAR that makes sense
		if ($cnum == DATE) {
		    if ($cols[DATE] =~ m/(\d\d\d\d)(\d\d)(\d\d)/) {
			if ( ($1 > $currentyear) || ($1 < MINYEAR) || ($2 > 12) || ($3 > 31) ) {
			    &checkwarn ("$linenum: " . $column[DATE][LABEL] . " column=" . (DATE + 1) . " bad date format \"" . $cols[DATE] . "\"\n");
			    $errors[DATE]++;
			    $totalerr++;
			    $errorfound = 1;
			}
			$dates{$cols[DATE]}++;
		    } elsif ($cols[DATE] ne "") {
			# can ignore blank columns because the cardinality check would have
			# already reported them.
			&checkwarn ("$linenum: " . $column[DATE][LABEL] . " column=" . (DATE + 1) . " bad date format \"" . $cols[DATE] . "\"\n");
			$errors[DATE]++;
			$totalerr++;
			$errorfound = 1;
		    }
		    
# If IEA, is the association less than a year old?
# If the association is old then $is_oldiea equals 1
#
		    if ( $cols[EVIDENCE] eq "IEA" ) {
			
			if ( $cols[DATE] < $limitdate) {
			    &checkwarn ("$linenum: " . $column[DATE][LABEL] . " column=" . (DATE + 1) . " IEA evidence code present with a date more than a year old \"" . $cols[DATE] . "\"\n");
			    $errors[DATE]++;
			    $totalerr++;
			    $errorfound = 1;
			}
		    } elsif ( ( $cols[EVIDENCE] eq "TAS" ) ||
			     ( $cols[EVIDENCE] eq "NAS" ) ||
			     ( $cols[EVIDENCE] eq "ND" ) ) {
			
			if ( $cols[WITH] ne "" ) {
			    &checkwarn ("$linenum: " . $column[WITH][LABEL] . " column=" . (WITH + 1) . " WITH not allowed when using the TAS, NAS or ND evidence codes \"" . $cols[WITH] . "\" " . "\"" . $cols[EVIDENCE] . "\"\n");
			    $errors[WITH]++;
			    $totalerr++;
			    $errorfound = 1;
			}
			
		    }
		}
		
		if ($cnum == ASSIGNED_BY) {
		    unless ($abbrev{ lc($cols[ASSIGNED_BY]) }) {
			&checkwarn ("$linenum: " . $column[ASSIGNED_BY][LABEL] . " column=" . (ASSIGNED_BY + 1) . " allowed database abbreviation not correct, found \"" . $cols[$cnum] . "\"\n");
			$errors[ASSIGNED_BY]++;
			$totalerr++;
			$errorfound = 1;
		    }
		}
		
	    } # end of special condition
	    
# CHECK the DB part of an identifier
	    
	    if ($column[$cnum][CHECKDB]) {
		
		if ( $cols[$cnum] =~ /\:/ ) {
		    my @fields = split(/\|/, $cols[$cnum]);
		    foreach my $tmpfld ( @fields ) {
			if ( $tmpfld =~ /\:/ ) {
			    my ( @dbname ) = split(/\:/, $tmpfld);
			    unless ($abbrev{ lc($dbname[0]) }) {
				&checkwarn ("$linenum: " . $column[$cnum][LABEL] . " column=" . ($cnum + 1) . " allowed database abbreviation not correct, found \"" . $dbname[0] . "\" in the ID \"" . $cols[$cnum] . "\"\n");
				$errors[$cnum]++;
				$totalerr++;
				$errorfound = 1;
			    }
			}
		    }
		}
	    } # end of CHECKDB condition
	    
	} # end of for loop
	
	unless ($errorfound > 0) {
	    print FILTER "$line\n" if ($writereport);
	    print "$line\n" if ($writegood);
	    $totallines++;
	} 
	elsif ($writebad) {
	    print "$line\n";
	}
       
    }
    
    close(INPUT);

# output summary of errors
    
# assume TAB = 8 spaces
    use constant TABWIDTH => 8;
    
    my $report;
    
    if ($totalerr > 0) {
	$report = "\nNUMBER of ERRORS by COLUMN\n\n";
	$report .= "Column Name\t\tCol#\tNumber of Errors\n";
	for (my $index=0; $index < @errors; $index++) {
	    if ($errors[$index] > 0) {
		if (length($column[$index][LABEL]) < TABWIDTH) {
		    $column[$index][LABEL] .= "\t";
		}
		if (length($column[$index][LABEL]) < (TABWIDTH * 2)) {
		    $column[$index][LABEL] .= "\t";
		}
		$report .= $column[$index][LABEL] . "\t" . ($index + 1) . "\t" . $errors[$index] . "\n";
	    }
	}
	$report .= "General errors\t\t-\t" . $lineerr . "\n" if ($lineerr > 0);
	$report .= "\nTOTAL ERRORS = " . $totalerr . "\n";
	$report .= "TOTAL ROWS without errors = " . $totallines . "\n";
	$report .= "TOTAL ROWS in FILE = " . $linenum . "\n\n";

	if ($writereport && ($totallines == 0)) {
	    print FILTER "!\n! All Gene Associations in this file have been removed by the GO Consortium.\n!\n! The submitted associations most likely stated an NCBI TAXID\n! for each association that is available from another GO member project.\n! The GO Consortium started filtering gene association files in October 2005\n! in a effort to minimize confusion resulting in redundancy between the\n! many projects providing gene  association files. At that time the Consortium\n! also started removing associations to obsolete GOIDs, IEA annotations older than\n! one year, and any association that did not meet the syntax defined for this file.\n!\n";

	    close(FILTER);
	}

    }
    else {
	$report .= "\nCongratulations, there are no errors.\n\n";
    }
    
    my $countdates = 0;
    my $lastdate = "";
    foreach my $dkeys (keys %dates) {
	$countdates++;
	$lastdate = $dkeys;
    }
    
    if ($countdates == 1) {
	$report .= "\n********************************************************\nAll the dates in column 14 are the same ==> \"$lastdate\"!\nThis column should represent when the association was\ndetermined, not when this file was created.\n********************************************************\n\n";
    }
    
    if ($opt_w) {
	$report .= "Total of $totallines lines (not including header) written to STDOUT.\n\n";
    }
    
    if ($writereport) {
	unless ($report =~ m/Congratulations/i) {
	    &write_report($report, $base_file_name);
	}
    }
    print STDERR $report unless ($quietmode);

}

###############################################################################
sub checkwarn {
###############################################################################
# print each error if $detail equals 1
    my $linenum = $_[0];

    print STDERR $linenum if ($detail);
    print STDOUT "\n" . $linenum if ($writebad);

}

###############################################################################
sub write_report {
###############################################################################

    my ($report, $report_file_name) = @_;

    $report_file_name = $report_file_name . '.report';
    my $gafilename = $inputfile;
    $gafilename =~ s|.*/submission/||;

    my $body1 = "Please review the errors summarized in this report and fix your\ngene-associations file as is appropriate. This is an automated message\nsummarizing results of the GOC filtering for file:\n\n$gafilename\n";

    my $body2 = "To review a detailed report of all the errors use the following\ncommand from the gene-associations/submission directory:\n  ../../software/utilities/filter-gene-association.pl -d -i $gafilename\n\n";

    my $body3 = "The rows without errors are now available from the gene-associations\ndirectory at the geneontology.org web, FTP and CVS sites. Your email\nis defined as the address where these reports should be sent. If this\nis not correct please have the conf file updated. If you have any\nquestions or suggestions, please do not hesitate to contact me.\n\n";

    open (REPORT, ">${report_file_name}") || die "Cannot write to ${report_file_name}: $!\n";
    print REPORT "Dear Colleague,\n"; 
    print REPORT "\n";
    print REPORT "$body1";
    print REPORT "\n---$report---\n\n";
    print REPORT "$body2";
    print REPORT "$body3";
    print REPORT "Mike Cherry\n";
    print REPORT "E-mail: cherry\@genome.stanford.edu\n";
    close(REPORT);

}

###############################################################################

__END__


=head1 NAME

I<filter-gene-association.pl> - checks GO gene association file format and data

=head1 SYNOPSIS

=over

=item print usage

  filter-gene-association.pl -h

=back

=over

=item run checks on the specified gene association file

  filter-gene-association.pl -i gene_association.sgd.gz

=back

=over

=item run checks and provide details on all errors on GA file

  filter-gene-association.pl -i gene_association.tair.gz -d |& more

=back

=over

=item filter out lines with errors and output validated lines to STDOUT

  filter-gene-association.pl -i gene_association.fb.gz -w > filtered-output

=back

=head1 DESCRIPTION

Check gene association file for check syntax, plus removes obsolete
GOIDs, IEA annotations that are older than one year, and annotations
that are provided by one of the MOD projects.  

=head1 ARGUMENTS

Arguments can control the input file, the project name, the level of
detail and whether the filtered results are output.

=over

=item -h

print usage message

=item -q

quiet mode, don't print final report to STDERR

=item -i

name of input gene association file.  The file can be compressed or
gzipped.  To specify STDIN use "-i -".

Caveat: The project name is automatically determined from the name of
the gene association file.  When using STDIN for input you must use
the -p option to specify the project name, otherwize all rows will be
filtered out.

=item -d

turn on detailed output.  Each error, if any, are output to STDERR.
The line number within the input file and a description of the type of
error(s) are provided.

Caveat: The details are set to STDERR.  If you wish to view the errors
with a paging program such as more you will need to use "|&" instead
of the normal pipe symbol "|".  Normally only STDOUT is set through a
pipe.  Adding the ampersand will will send both STDOUT and STDERR to
through the pipe.

=item -e

Output each bad line to STDOUT.  The line number within the input file
and a description of the type of error(s) are provided.

=item -w

write validated lines, including header lines, to STDOUT.  You can use
the -d (detailed listing of errors and statistics) with the -w option.
The errors, if any will be displayed on STDERR and the validated lines
will be set to STDOUT.  If any error in format or data is identified
for a line it will not be sent to the output.

=item -r

creates two files in the submission directory: .filtered.gz and
.report files; the .filtered.gz file has all the error-free lines from
the gene_association file and the .report file has a summary of the
errors found in the MOD sumitted gene_association file.  When writing
out the .filetred.new file, the scripts uses the contents of .conf
file for that particular gene association file to create its header
section.  For more information about the format of .conf file, please
see the INPUT section below.

=item -o

full name to OBO file.  The default is
$gocvsbase/ontology/gene_ontology.obo, as if you running this script
from within the gene-associations directory in your GO CVS sandbox.
You can use any file in OBO format, the obsolete GOIDs are identified
by the "is_obsolete: true" line.

=item -p

used to define the project name.  A specific project name is required
for the species filtering.  This option takes precedent over the
automatic project name determination that uses the input file name.
The -p option is required if using STDIN to provide the gene
association file.  List of project names and taxids.  Each of these
taxids is only allowed within the defined project specific file.  All
other taxids are allowed without restriction.

NOTE: To turn off the taxid checking use the -p option and specify the
name as "nocheck".


  PROJECT NAME          TAXID
  ====================  ============
  GeneDB_Lmajor         taxon:5664
  GeneDB_Pfalciparum    taxon:5833
  GeneDB_Spombe         taxon:4896
  GeneDB_Tbrucei        taxon:185431
  GeneDB_tsetse         taxon:37546
  cgd                   taxon:5476
  ddb                   taxon:5782
  fb                    taxon:7227
  goa_human             taxon:9606
  gramene_oryza         taxon:4528, taxon:4530, taxon:4532, taxon:4533,
                        taxon:4534, taxon:4535, taxon:4536, taxon:4537,
                        taxon:4538, taxon:4539, taxon:29689, taxon:29690,
                        taxon:39946, taxon:39947, taxon:40148, taxon:40149,
                        taxon:52545, taxon:63629, taxon:65489, taxon:65491,
                        taxon:77588, taxon:83307, taxon:83308, taxon:83309,
                        taxon:110450, taxon:110451, taxon:127571
  mgi                   taxon:10090
  rgd                   taxon:10116
  sgd                   taxon:4932
  tair                  taxon:3702
  tigr_Banthracis       taxon:198094
  tigr_Cburnetii        taxon:227377
  tigr_Cjejuni          taxon:195099
  tigr_Dethenogenes     taxon:243164
  tigr_Gsulfurreducens  taxon:243231
  tigr_Lmonocytogenes   taxon:265669
  tigr_Mcapsulatus      taxon:243233
  tigr_Psyringae        taxon:223283
  tigr_Soneidensis      taxon:211586
  tigr_Spomeroyi        taxon:246200
  tigr_Tbrucei_chr2     taxon:5691
  tigr_Vcholerae        taxon:686
  wb                    taxon:6239
  zfin                  taxon:7955


=item -x

full name to GO abbreviation file.  The default is $gocvsbase/doc/GO.xrf_abbs,
as if you running this script from within the gene-associations
directory in your GO CVS sandbox.  You can use any file in a similar
form as the GO.xrf_abbs file in the GO CVS.

=back

=head1 INPUT

The specification of the gene_association format is defined at:
http://www.geneontology.org/GO.annotation.html#file

=over

=item GA file column definitions

 0: DB, database contributing the file (always "SGD" for this file).
 1: DB_Object_ID, SGDID (SGD's unique identifier for genes and
    features).
 2: DB_Object_Symbol, see below
 3: Qualifier (optional), one or more of 'NOT', 'contributes_to',
    'colocalizes_with' as qualifier(s) for a GO annotation, when needed,
    multiples separated by pipe (|)
 4: GO ID, unique numeric identifier for the GO term
 5: DB:Reference(|DB:Reference), the reference associated with the GO
    annotation
 6: Evidence, the evidence code for the GO annotation
 7: With (or) From (optional), any With or From qualifier for the GO
    annotation
 8: Aspect, which ontology the GO term belongs (Function, Process or
    Component)
 9: DB_Object_Name(|Name) (optional), a name for the gene product in
    words, e.g. 'acid phosphatase'
10: DB_Object_Synonym(|Synonym) (optional), see below
11: DB_Object_Type, type of object annotated, e.g. gene, protein, etc.
12: taxon(|taxon), taxonomic identifier of species encoding gene
    product
13: Date, date GO annotation was defined in the format YYYYMMDD
14: Assigned_by, source of the annotation (always "SGD" for this file)


=item Config file format

 project_name=Saccharomyces Genome Database (SGD)
 contact_email=yeast-curator@yeastgenome.org
 project_url=http://www.yeastgenome.org/
 funding_source=NHGRI at US NIH, grant number 5-P41-HG001315
 email_report=yeast-curator@yeastgenome.org,cherry@genome.stanford.edu

=back

=head1 OUTPUT

The default output using the -w output is a validated gene association
file on STDOUT. See the INPUT section for details on this format.
When using -r option, two output files will be creaed: .filtered.gz
and .report files.  See the INPUT section for config file format.

=head1 REASON ROWS WOULD BE REJECTED

The following is a brief summary of the common errors this script will find.

   1. Not the correct number of columns.
   2. Any leading or trailing spaces on any field.
   3. Cardinality does not match format specification.
   4. DB abbreviation is not one of the standard set used by the GO Consortium.
   5. Qualifier column can only include NOT, contributes_to or colocalizes_with
   6. One of the three aspects (ontologies) is stated for each line.
   7. Evidence code column needs to be present and one of the standard set.
   8. DB Object Type is one of the defined set.
   9. Stated Taxid is allowed for the particular project file.
  10. GOID is not obsolete.
  11. Date is in proper format.
  12. IEA annotations are less than one year old.

=head1 FUTURE ENHANCEMENTS

 Check GOID and Aspect column for consistency.

=cut

