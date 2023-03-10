#!/usr/bin/perl 

use strict;
use Ace;
use Bio::DB::GFF;
use DBI;
use Getopt::Std;

my %opts=();


getopts('i:o:e:d:htr',\%opts);

my $program_name=$0=~/([^\/]+)$/ ? $1 : '';

if (! defined $opts{i} || (defined $opts{t} && defined $opts{r}) || (! defined $opts{t} && ! defined $opts{r})) {
    $opts{h}=1;
}

if ($opts{h}) {
    print "usage: $program_name [options] -i data -t|r\n";
    print "       -h               help - print this message\n";
    print "       -i <data>        data table; required\n";
    print "       -o <ace>         ace file; default STDOUT\n";
    print "       -e <errors>      write errors to this file, do not die\n";
    print "       -t               testing - assign temporary WBRNAi IDs\n";
    print "       -r               real - assign real WBRNAi IDs; either -t or -r is required\n";
    print "       -d <GFF>         GFF database name; default latest available\n";
    exit(0);
}





$|=1;

my $db_name='';
if ($opts{d}) {
    $db_name=$opts{d};
}
else {
    my %attr=(user=>'igor');
    my @data_sources = grep {/elegans_latest/i} DBI->data_sources('mysql', \%attr); # get available GFF databases, use the latest
    if (!@data_sources) {
	@data_sources = grep {/elegans_ws/i} DBI->data_sources('mysql', \%attr); # get available GFF databases, use the latest by release number
	@data_sources = sort {
	    my $ver_a=$a=~/elegans_ws(\d+)/i ? $1 : die "cannot parse database version: $a\n";
	    my $ver_b=$b=~/elegans_ws(\d+)/i ? $1 : die "cannot parse database version: $b\n";
	    $ver_b <=>  $ver_a
	    } 
	@data_sources;
    }
    $db_name=$data_sources[0];
    if (!$db_name) {
	die "no C. elegans GFF databases found\n";
    }
    print "Available GFF databases are:\n", join("\n", @data_sources), "\n";
}
print "Using $db_name\n";

my $db_file="/home2/igor/AceDB/CHROMOSOMES/CHROMOSOME_all.dna";  #fasta file for e-PCR
my $rnai_db="WBRNAi";              #MySQL RNAi DB name
my $table='';                      #WBRNAi ID table in $rnaidb
my $test_interaction_number=0;
if ($opts{t}) {
    $table="rnai_curation_temp";
    warn "using $table table to assign TEMPORARY WBRNAi IDs\n";
}
elsif ($opts{r}) {
    $table="wbrnai";
    warn "using $table table to assign REAL WBRNAi IDs\n";
}
else {
    die "incorrect RNAi table in $db_name\n";
}
#my $table="wbrnai";                #WBRNAi ID table in $rnaidb
#my $table="rnai_curation_temp";
my $ontology="/home/igor/Projects/Phenotype_ontology/PhenOnt/PhenOnt.obo";     #phenotype ontology; it is updated every day by /home/igor/crontab/daily_update_PhenOnt from http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/phenotype_ontology_obo.cgi
my $ace_file;
my $temp_dir='';
my $error_file;

open(IN, "<$opts{i}") || die "cannot open $opts{i} : $!\n";
if ($opts{o}) {
    open($ace_file, ">$opts{o}") || die "cannot open $opts{o} : $!\n";
}
else {
    $ace_file=*STDOUT;
}

if ($opts{e}) {
    open($error_file, ">:unix", "$opts{e}") || die "cannot open $opts{e} : $!\n";  # unbuffered output
}
    
warn "connecting to database...";
my $db = Ace->connect('sace://elbrus.caltech.edu:40004') || die print "Connection failure: ", Ace->error;
my $sqldb=Bio::DB::GFF->new(-dsn=>$db_name, -user=>'igor') || die "cannot open $db_name $!";
warn "done\n";

my $wbrnai='';
my $paper_obj='';
my $rnai_count=0;
my $line_count=0;
my $total_line_count=0;
my $probe_count=0;

my $interactionID='';
my $interactionType='';
my %interactionTypes=(genetic=>1,
		      regulatory=>1,
		      no_interaction=>1,
		      predicted_interaction=>1,
		      physical_interaction=>1,
		      suppression=>1,
		      enhancement=>1,
		      synthetic=>1,
		      epistasis=>1,
		      mutual_enhancement=>1,
		      mutual_suppression=>1,
		      );
my %curators_interaction=("Igor Antoshechkin"=>'two22',
			  "Andrei Petcherski"=>'two480',
			  "Raymond Lee"=>'',
			  "Kimberly Van Auken"=>'',
			  "Gary Schindelman"=>'two557');
my %interactionDirections=(effector=>1,
			   effected=>1,
			   non_directional=>1,
			   );
my $interaction_count=0;
		      

my %phenotype_hash=();
open (PHEN, "<$ontology") || die " cannot open $ontology : $!\n";
my $id='';
while (<PHEN>) {
    chomp;
    if (/^id:\s+(WBPhenotype:\d+)/) {
	$id=$1;
    }
    if (/^name:\s+(.+)/) {
	$phenotype_hash{$id}=$1;
    }
}

my %gene_variation_hash=();
=head
my $gene_variation_table="/home2/igor/AceDB/gene_variation.csv";
open (VAR, "<$gene_variation_table") || die "cannot open $gene_variation_table: $!\n";
while (<VAR>) {
    chomp;
    s/\"//g;
    my @tmp=split("\t");
    push @{$gene_variation_hash{$tmp[1]}}, $tmp[0];
}
=cut
my $query="select a, a->allele from a in class gene where exists a->allele";
my @results=$db->aql($query);
foreach (@results) {
    push @{$gene_variation_hash{$$_[1]}}, $$_[0];
}
my %overlapping_genes;

#-------------- This parted added by Wen for interaction ace file. -------
open (INTER, ">RNAi_interaction.ace") || die " cannot open RNAi_interaction.ace files.\n";
#-------------------------------------------------------------------------

while (<IN>) {

    eval {

	$total_line_count++;
	chomp;
	s/\"//g;
	my @tmp=split("\t");
	foreach (@tmp) {
	    s/\'//g;
	    s/\"//g;
	    s/\s+/ /g;
	}
	next unless $tmp[0]=~/^WBPaper/ || $tmp[5] eq "YES";
	$line_count++;
	if ($line_count % 10 == 0) {
	    warn "$line_count lines processed\n";
	}
	
	if ($tmp[5]) {
	    if ($tmp[5] ne "YES") {
		die "\'Same As Above\' field has to be YES or blank : line number $total_line_count in $opts{i}\n";
	    }
	}
	
	unless ($tmp[5] eq "YES") {
	    $paper_obj=$db->fetch(paper=>$tmp[0]) || die "cannot fetch paper $tmp[0] : $!";
	    $probe_count=0;
	}
	my $lab_obj='';
	if ($tmp[1]) {
	    $lab_obj=$db->fetch(laboratory=>$tmp[1]) || die "cannot fetch laboratory $tmp[1] : $!";
	}
	if ($tmp[2]) {
	    if (!($tmp[2]=~/^\d{4}-\d{2}-\d{2}$/)) {
		die "Incorrect date format. Should be YYYY-MM-DD (e.g. 1999-07-29) : $!\n";
	    }
	}
	my $name=$tmp[3];
	my $email=$tmp[4];
	unless ($tmp[5] eq "YES") {
	    if (! ($name || $email)) {
		die "either curator\'s name or e-mail is required\n";
	    }
	}
	
	my $query="select a->author from a in class paper where a=\"$paper_obj\"";
	my @authors=$db->aql($query);
	
	unless ($tmp[5] eq "YES") {
	    $wbrnai=getWBRNAiID($rnai_db, $name, $email);
	    $rnai_count++;
	}
	if (!$wbrnai) {
	    die "WBRNAiID is not set : $!\n";
	}

	unless ($tmp[5] eq "YES") {
	    $interactionID='';
	    $interactionType='';
	    undef %overlapping_genes;
	}
	
	
	print $ace_file "\n";
	print $ace_file "///////////////////////////////////////////////////////////////\n";
	print $ace_file "//\tPaper Information: $wbrnai\n";
	print $ace_file "///////////////////////////////////////////////////////////////\n";
	print $ace_file "\n";
	
	print $ace_file "RNAi : \"$wbrnai\"\n";
	print $ace_file "Reference\t\"$paper_obj\"\n";
	print $ace_file "Laboratory\t\"$lab_obj\"\n" if $lab_obj;
	foreach (@authors) {
	    print $ace_file "Author\t\"$$_[0]\"\n";
	}
	print $ace_file "Date\t$tmp[2]\n" if $tmp[2];
	print $ace_file "Method\t\"RNAi\"\n";
	print $ace_file "\n";
	
	
	my $field_count=0;
	foreach my $i (6,7,9,10,11) {
	    if ($tmp[$i]) {
		$field_count++;
	    }
	}
	if ($field_count > 1) {
	    die "only one probe per line is allowed:  line number $total_line_count in $opts{i}\n";
	}
	elsif ($field_count == 0 && $tmp[5] ne "YES") {
	    die "no probe specified:  line number $total_line_count in $opts{i}\n";
	}
	
	
	
############################################  SEQUENCE DATA ###############################################################
	
	if ($tmp[6]) {
	    my $overlapping_genes_ref=mapPCRproduct($wbrnai, $tmp[6], $ace_file, $db, $sqldb, $total_line_count, \%opts);
	    foreach (keys %{$overlapping_genes_ref}) {
		$overlapping_genes{$_}=${$overlapping_genes_ref}{$_};
	    }
	}
	if ($tmp[7] && $tmp[8]) {
	    if ($tmp[7]=~/[^AGCT]/i || $tmp[8]=~/[^AGCT]/i) {
#		die "invalid primer sequence: line number $total_line_count in $opts{i}\n"; this will be checked in mapPrimers
	    }
	    $probe_count++;
	    my $tmp_ref=mapPrimers($paper_obj, $wbrnai, $tmp[7], $tmp[8], $ace_file, $db, $sqldb, $temp_dir, $db_file, $total_line_count, \%opts, $probe_count);
	    $probe_count=$$tmp_ref[0];
	    my $overlapping_genes_ref=$$tmp_ref[1];
	    foreach (keys %{$overlapping_genes_ref}) {
		$overlapping_genes{$_}=${$overlapping_genes_ref}{$_};
	    }
#	    $probe_count=mapPrimers($paper_obj, $wbrnai, $tmp[7], $tmp[8], $ace_file, $db, $sqldb, $temp_dir, $db_file, $total_line_count, \%opts, $probe_count);
	}
	if (($tmp[7] && !$tmp[8]) || (!$tmp[7] && $tmp[8])) {
	    die "Both primer sequences must be specified : line number $total_line_count in $opts{i}\n";
	}
	if ($tmp[9]) {
	    $probe_count++;
	    my $overlapping_genes_ref=mapCoordinates($paper_obj, $wbrnai, $tmp[9], $ace_file, $db, $sqldb, $total_line_count, \%opts, $probe_count);
	    foreach (keys %{$overlapping_genes_ref}) {
		$overlapping_genes{$_}=${$overlapping_genes_ref}{$_};
	    }
	}
	if ($tmp[10]) {
	    my $overlapping_genes_ref=mapClone($paper_obj, $wbrnai, $tmp[10], $ace_file, $db, $sqldb,  $temp_dir, $db_file, $total_line_count, \%opts, $probe_count);
	    foreach (keys %{$overlapping_genes_ref}) {
		$overlapping_genes{$_}=${$overlapping_genes_ref}{$_};
	    }
	}
	if ($tmp[11]) {
	    $probe_count++;
	    my $overlapping_genes_ref=mapSequence($paper_obj, $wbrnai, $tmp[11], $ace_file, $db, $sqldb,  $temp_dir, $db_file, $total_line_count, \%opts, $probe_count);
	    foreach (keys %{$overlapping_genes_ref}) {
		$overlapping_genes{$_}=${$overlapping_genes_ref}{$_};
	    }
	}
	
	
############################################  END SEQUENCE DATA ###########################################################
	
	
	my ($strain_obj, $stage_obj, $genotype, $species_obj, $temperature, $delivered_by, $treatment, $remark, $gene_regulation, $phenotype);
	if ($tmp[12]) {
	    $strain_obj=$db->fetch(strain=>$tmp[12]) || die "Strain $tmp[12] does not exist in the database : $!\n";
	    if ($tmp[13]) {
		die "Genotype is not necessary if strain information is entered : line number $total_line_count in $opts{i}\n";
	    }
	}
	if ($tmp[13]) {
	    $genotype=$tmp[13];
	}
	if ($tmp[14]) {
	    $treatment=$tmp[14];
	}
	if ($tmp[15]) {
	    $stage_obj=$db->fetch(life_stage=>$tmp[15]) || die "Life stage $tmp[15] does not exist in the database : $!\n";
	}
	if ($tmp[16]) {
	    unless ($tmp[16]=~/^\d+$/) {
		die "Incorrect temperature format. Should be Integer type : line number $total_line_count in $opts{i}\n";
	    }
	    $temperature=$tmp[16];
	}
	if ($tmp[17]) {
	    unless ($tmp[17]=~/Bacterial_feeding|Injection|Soaking|Transgene_expression/i) {
		die "Incorrect Delivered by format : line number $total_line_count in $opts{i}\n";
	    }
	    $delivered_by=$tmp[17];
	}
	if ($tmp[18]) {
	    $species_obj=$db->fetch(species=>$tmp[18]) || die "Species $tmp[18] does not exist in the database : $!\n";
	}
	if ($tmp[19]) {
	    $remark=$tmp[19];
	}
	if ($tmp[20]) {
	    $gene_regulation=$tmp[20];
	}
	if (!$tmp[21] && ! ($tmp[5] eq "YES")) {
	    die "phenotype id has to be specified : line number $total_line_count in $opts{i}\n";
	}
	if ($tmp[21]) {
	    $phenotype=$tmp[21];
	    unless ($phenotype_hash{$phenotype}) {
		die "Phenotype ID $tmp[21] does not exist in the database : line number $total_line_count in $opts{i}\n";
	    }
	}
	

#--------This part changed/added by Wen ---------------
	my $obs = "Phenotype";
	if ($tmp[33]) {
	    if ($tmp[33] eq "YES") {
		#print $ace_file "Phenotype\t\"$phenotype\"\tNOT\n";
		$obs = "Phenotype_not_observed";
	    }
	    else {
		die "NOT field has to be YES or blank : line number $total_line_count in $opts{i}\n";
	    }
	} 

#--------------------------------------------------------
	
	print $ace_file "\n";
	print $ace_file "///////////////////////////////////////////////////////////////\n";
	print $ace_file "//\tExperimental Information: $wbrnai\n";
	print $ace_file "///////////////////////////////////////////////////////////////\n";
	print $ace_file "\n";
	
	
	print $ace_file "RNAi : \"$wbrnai\"\n";
	if ($strain_obj) {
	    print $ace_file "Strain\t\"$strain_obj\"\n";
	}
	if ($genotype) {
	    print $ace_file "Genotype\t\"$genotype\"\n";
	}
	if ($treatment) {
	    print $ace_file "Treatment\t\"$treatment\"\n";
	}
	if ($stage_obj) {
	    print $ace_file "Life_stage\t\"$stage_obj\"\n";
	}
	if ($temperature) {
	    print $ace_file "Temperature\t$temperature\n";
	}
	if ($delivered_by) {
	    print $ace_file "Delivered_by\t\"$delivered_by\"\n";
	}
	if ($species_obj) {
	    print $ace_file "Species\t\"$species_obj\"\n";
	}
	if ($remark) {
	    print $ace_file "Remark\t\"$remark\"\n";
	}
	if ($gene_regulation) {
	    print $ace_file "Gene_regulation\t\"$gene_regulation\"\n";
	}
	if ($phenotype) {
	    print $ace_file "$obs\t\"$phenotype\"\t//$phenotype_hash{$phenotype}\n";
	}
	

	
	if ($tmp[22]) {
	    unless ($tmp[22]=~/^\d+$/) {
		die "Penetrance From has incorrect format. It has to be Int : line number $total_line_count in $opts{i}\n";
	    }
	    print $ace_file "$obs\t\"$phenotype\"\tRange\t$tmp[22]";
	    if ($tmp[23]) {
		unless ($tmp[23]=~/^\d+$/) {
		    die "Penetrance To has incorrect format. It has to be Int : line number $total_line_count in $opts{i}\n";
		}
		print $ace_file "\t$tmp[23]\n";
	    }
	    else {
		print $ace_file "\n";
	    }
	}
	if ($tmp[23]) {
	    unless ($tmp[22]) {
		die "Penetrance From must be specified : line number $total_line_count in $opts{i}\n";
	    }
	}
	
	if ($tmp[24]) {
	    if ($tmp[24] eq "YES") {
		print $ace_file "$obs\t\"$phenotype\"\tIncomplete\n";
	    }
	    else {
		print $ace_file "$obs\t\"$phenotype\"\tIncomplete\t\"$tmp[24]\"\n";
	    }
	}
	if ($tmp[25]) {
	    if ($tmp[25] eq "YES") {
		print $ace_file "$obs\t\"$phenotype\"\tLow\n";
	    }
	    else {
		print $ace_file "$obs\t\"$phenotype\"\tLow\t\"$tmp[25]\"\n";
	    }
	}
	if ($tmp[26]) {
	    if ($tmp[26] eq "YES") {
		print $ace_file "$obs\t\"$phenotype\"\tHigh\n";
	    }
	    else {
		print $ace_file "$obs\t\"$phenotype\"\tHigh\t\"$tmp[26]\"\n";
	    }
	}	
	if ($tmp[27]) {
	    if ($tmp[27] eq "YES") {
		print $ace_file "$obs\t\"$phenotype\"\tComplete\n";
	    }
	    else {
		print $ace_file "$obs\t\"$phenotype\"\tComplete\t\"$tmp[27]\"\n";
	    }
	}	
	if ($tmp[28]) {
	    if ($tmp[28] eq "YES") {
		print $ace_file "$obs\t\"$phenotype\"\tHeat_sensitive\n";
	    }
	    else {
		print $ace_file "$obs\t\"$phenotype\"\tHeat_sensitive\t\"$tmp[28]\"\n";
	    }
	}
	if ($tmp[29]) {
	    if ($tmp[29] eq "YES") {
		print $ace_file "$obs\t\"$phenotype\"\tCold_sensitive\n";
	    }
	    else {
		print $ace_file "$obs\t\"$phenotype\"\tCold_sensitive\t\"$tmp[29]\"\n";
	    }
	}
	if ($tmp[30]) {
	    unless ($tmp[30]=~/^\d+$/) {
		die "Quantity From has incorrect format. It has to be Int : line number $total_line_count in $opts{i}\n";
	    }
	    print $ace_file "$obs\t\"$phenotype\"\tQuantity\t$tmp[30]";
	    if ($tmp[31]) {
		unless ($tmp[31]=~/^\d+$/) {
		    die "Quantity To has incorrect format. It has to be Int : line number $total_line_count in $opts{i}\n";
		}
		print $ace_file "\t$tmp[31]\n";
	    }
	    else {
		print $ace_file "\n";
	    }
	}
	if ($tmp[31]) {
	    unless ($tmp[30]) {
		die "Quantity From must be specified : line number $total_line_count in $opts{i}\n";
	    }
	}
	if ($tmp[32]) {
	    print $ace_file "$obs\t\"$phenotype\"\tQuantity_description\t\"$tmp[32]\"\n";
	}

	if ($tmp[34]) {
	    print $ace_file "$obs\t\"$phenotype\"\tRemark\t\"$tmp[34]\"\n";
	}
	if ($tmp[35]) {
	    $tmp[35]=~s/\s+//g;
	    my @molecules=split(/,/, $tmp[35]);
		foreach (@molecules) {
		    print $ace_file "$obs\t\"$phenotype\"\tMolecule\t\"$_\"\n";
		}
	}


	if ($tmp[36]) {  # interaction object
	    print $ace_file "Interaction\t\"$tmp[36]\"\n";
	   
	}
	if ($tmp[37] && !$interactionID) {
	    my $curator='two22';
	    if ($curators_interaction{$name}) {
		$curator=$curators_interaction{$name};
	    }
	    if ($opts{r}) {
		my $ref=getInteractionID(1, $curator) || die "Cannot fetch new interaction ID: line number $total_line_count in $opts{i}\n";   # get ID here
		$interactionID=$$ref[0];
	    }
	    elsif ($opts{t}) {
		$test_interaction_number++;
		$interactionID="WBInteractionTEST$test_interaction_number";
	    }
	    print $ace_file "Interaction\t\"$interactionID\"\n";
	  
	    $interaction_count++;
	    if (!$interactionTypes{lc $tmp[37]}) {
		die "Interaction type $tmp[37] is invalid. It has to be one of those: genetic, regulatory, no_interaction, predicted_interaction, physical_interaction, suppression, enhancement, synthetic, epistasis, mutual_enhancement, mutual_suppression: line number $total_line_count in $opts{i}\n";
	    }
	    else {
		$interactionType=$tmp[37];
	    }
	}
	print $ace_file "\n";
	

#-----------this part added by Wen for Molecule data ---------------
	if (($tmp[35])&&($obs eq "Phenotype")) {
	        my @molecules=split(/,/, $tmp[35]);
	    	foreach (@molecules) {
		    print $ace_file "Molecule : \"$_\"\n";
		    print $ace_file "RNAi\t\"$wbrnai\"\t\"$phenotype\"\n\n";
		}	    
	} 
#---------This part changed by Wen to move Interaction data to another file --

	if ($interactionID) {
	    #print $ace_file "Interaction : \"$interactionID\"\n";
	    #print $ace_file "Paper\t$paper_obj\n";
	    print INTER "\nInteraction : \"$interactionID\"\n";
	    print INTER "Paper\t$paper_obj\n";
	    if ($tmp[38]) {
		$tmp[38]=~s/\s+//g;
		my @int_phenotypes=split(/,/, $tmp[38]);
		foreach (@int_phenotypes) {
#		    my $obj=$db->fetch('phenotype', $_) || die "Phenotype $_ (interaction information) does not exist in the database: line number $total_line_count in $opts{i}\n";  #do not check phenotype in AceDB - they are parsed from the obo file
		    #print $ace_file "Interaction_type\t$interactionType\tInteraction_phenotype\t$_\n";
		    print INTER "Interaction_type\t$interactionType\tInteraction_phenotype\t$_\n";

		}
	    }
	    if ($tmp[39]) {
		#print $ace_file "Remark\t\"$tmp[39]\"\n";
		print INTER "Remark\t\"$tmp[39]\"\n";
	    }
	    if (!$tmp[40] && ($tmp[42] || $tmp[43] || $tmp[44])) {
		if ($tmp[41]) {
		    if ($gene_variation_hash{$tmp[41]}) {
			if (scalar @{$gene_variation_hash{$tmp[41]}} == 1) {
			    $tmp[40]=$gene_variation_hash{$tmp[41]}[0];
			}
			else {
			    die "Gene ID field is empty and variation $tmp[41] (interaction information) matches more than one gene (",join("; ", @{$gene_variation_hash{$tmp[41]}}) ,"): line number $total_line_count in $opts{i}\n";
			}
		    }
		    else {
			die "Gene ID field is empty and variation $tmp[41] (interaction information) does not exist in the database: line number $total_line_count in $opts{i}\n";
		    }
		}
		elsif ($tmp[43]=~/YES/i) {
		    if (scalar keys %overlapping_genes == 1) {
			my @tmp2=keys %overlapping_genes;
			$tmp[40]=$tmp2[0];
		    }
		    elsif (scalar keys %overlapping_genes == 0) {
			die "Gene ID field is empty and RNAi (interaction information) targets cannot be identified: line number $total_line_count in $opts{i}\n";
		    }
		    else {
			die "Gene ID field is empty and RNAi (interaction information) targets more than one gene (",join("; ", map {"$_:$overlapping_genes{$_}"} keys %overlapping_genes) ,"): line number $total_line_count in $opts{i}\n";
		    }
		}
		elsif ($tmp[42]) {
		    die "Gene ID has to be specified for a transgene-based new interaction object: line number $total_line_count in $opts{i}\n";
		}
		else {
		    die "Gene ID has to be specified for the new interaction object: line number $total_line_count in $opts{i}\n";
		}
	    }
	    if ($tmp[40]) {
		my $obj=$db->fetch('gene', $tmp[40]) || die "Gene ID $tmp[40] (interaction information) does not exist in the database: line number $total_line_count in $opts{i}\n";
		#print $ace_file "Interactor\t\"$tmp[40]\"\n";
		print INTER "Interactor\t\"$tmp[40]\"\n";
	    }
	    if ($tmp[41]) {
		if ($tmp[41]=~/wbvar/i) {
		    my $obj=$db->fetch('variation', $tmp[41]) || die "Variation $tmp[41] (interaction information) does not exist in the database: line number $total_line_count in $opts{i}\n";
		    #print $ace_file "Interactor\t\"$tmp[40]\"\tVariation\t\"$tmp[41]\"\n";
		    print INTER "Interactor\t\"$tmp[40]\"\tVariation\t\"$tmp[41]\"\n";
		}
		else {
		    my $wbvar_name=$db->fetch(Variation_name => $tmp[41]);
		    if (!$wbvar_name) {
			die "Variation $tmp[41] (interaction information) does not exist in the database: line number $total_line_count in $opts{i}\n";
		    }
		    my $wbvar=$wbvar_name->right(2);
		    #print $ace_file "Interactor\t\"$tmp[40]\"\tVariation\t\"$wbvar\"\n";
                    print INTER "Interactor\t\"$tmp[40]\"\tVariation\t\"$wbvar\"\n";
		}		
	    }
	    if ($tmp[42]) {
		my $obj=$db->fetch('transgene', $tmp[42]) || die "Transgene $tmp[42] (interaction information) does not exist in the database: line number $total_line_count in $opts{i}\n";
		#print $ace_file "Interactor\t\"$tmp[40]\"\tTransgene\t\"$tmp[42]\"\n";
		print INTER "Interactor\t\"$tmp[40]\"\tTransgene\t\"$tmp[42]\"\n";
	    }	
	    if ($tmp[43]=~/YES/i) {
		#print $ace_file "Interaction_type\t$interactionType\tInteraction_RNAi\t$wbrnai\n";
		print INTER "Interaction_type\t$interactionType\tInteraction_RNAi\t$wbrnai\n";
	    }
	    if ($tmp[44]) {
		if (!$interactionDirections{lc $tmp[44]}) {
		    die "Interaction direction $tmp[44] is invalid. It has to be one of those: Effector, Effected, Non_directional or left blank (defaults to Non_directional): line number $total_line_count in $opts{i}\n";
		}
		#print $ace_file "Interaction_type\t$interactionType\t$tmp[44]\t$tmp[40]\n";
		print INTER "Interaction_type\t$interactionType\t$tmp[44]\t$tmp[40]\n";
	    }
	    else {
		#print $ace_file "Interaction_type\t$interactionType\tNon_directional\t$tmp[40]\n";
		print INTER "Interaction_type\t$interactionType\tNon_directional\t$tmp[40]\n";
	    }
#	    else {
#		if ($tmp[5] eq "YES") {       # hack - if direction is blank, use Effector for first, Effected for the rest
#		    print $ace_file "Interaction_type\t$interactionType\tEffected\t$tmp[39]\n";
#		}
#		else {
#		    print $ace_file "Interaction_type\t$interactionType\tEffector\t$tmp[39]\n";
#		}
#	    }
	    
	}
	
	
    };
    if ($@) {
	if ($opts{e}) {
	    print $error_file "$@";
	    warn $@;
	}
	else {
	    die $@;
	}
    }
}

warn "$line_count lines processed\n";
warn "$rnai_count RNAi objects created\n";
warn "$interaction_count Interaction objects created\n";	





sub getInteractionID {
    my $interaction_count=shift;
    my $curator=shift;
    my @interactionID;
    my $url="http://tazendra.caltech.edu/~postgres/cgi-bin/interaction_ticket.cgi?action=Ticket+%21&curator=$curator&tickets=";
    $url.=$interaction_count;
    my $line=`wget -q -O - \"$url\"`;
    my @lines=split(/\n/, $line);
    foreach (@lines) {
	if (/(WBInteraction\d{9})/) {
	    push (@interactionID, $1);
	}
    }
    if (@interactionID) {
	return \@interactionID;
    }
    else {
	return undef;
    }
}









sub getWBRNAiID {

    my ($rnai_db, $name, $email)=@_;
    
    my $dbh=DBI->connect("DBI:mysql:database=$rnai_db", "igor") || die "Could not connect to $rnai_db : $!";
    $dbh->do("LOCK TABLES $table WRITE");
    my $sth = $dbh->prepare("SELECT MAX(id_number) AS MAX_ID from $table");  #do not try to deprecate ids - just assign the next one
    $sth->execute();
    my $ref=$sth->fetchrow_hashref;
    $sth->finish();
    my $id_number=$ref->{'MAX_ID'};
    $id_number++;

    my $length=length $id_number;
    my $wbrnai="WBRNAi";
    for (my $i=1; $i<=8-$length; $i++) {
	$wbrnai.='0';
    }
    $wbrnai.="$id_number";
    my @tmp_date=localtime();
    $tmp_date[5]+=1900;
    $tmp_date[4]++;
    if (length $tmp_date[4] == 1) {
	$tmp_date[4]="0".$tmp_date[4];
    }
    if (length $tmp_date[3] == 1) {
	$tmp_date[3]="0".$tmp_date[3];
    }
    
    $dbh->do("INSERT INTO $table (id, id_number, created_date, created_by, email) VALUES (\"$wbrnai\", $id_number, \'$tmp_date[5]-$tmp_date[4]-$tmp_date[3]\', \"$name\", \"$email\")") || die PrintError($dbh->errstr);
    $dbh->do("UNLOCK TABLES");
    $dbh->disconnect();

    return $wbrnai;
}


sub getOverlappingGenes {
    my $segment=shift;
    my $db=shift;
    my %genes;

    my %transcript_hash=();
    my %cds_hash=();
    my %pseudo_hash=();
    my %non_coding_transcript_hash=();
    my $non_coding_transcript_count=0;
    my $transcript_count=0;
    my $cds_count=0;
    my $pseudo_count=0;

    my @features=$segment->features(-types=>'exon');
    
    foreach (@features) {
	my $fname=$_->name;
	my $fsource=$_->source;
	if ($fsource eq "Coding_transcript") {
	    unless ($transcript_hash{$fname}) {
		$transcript_hash{$fname}=1;
		$transcript_count++;
	    }
	}
	if ($fsource eq "Non_coding_transcript") {
	    unless ($non_coding_transcript_hash{$fname}) {
		$non_coding_transcript_hash{$fname}=1;
		$non_coding_transcript_count++;
	    }
	}
	if ($fsource=~/curated/) {        #coding_exon:curated, exon:curated, intron:curated, CDS:curated
	    unless ($cds_hash{$fname}) {
		$cds_hash{$fname}=1;
		$cds_count++;
	    }
	}
	if ($fsource=~/Pseudogene/) {     #added for pseudogene mapping 6/8/04
	    unless ($pseudo_hash{$fname}) {
		$pseudo_hash{$fname}=1;
		$pseudo_count++;
	    }
	}
    }
    
    foreach (keys %transcript_hash) {
	my ($tr)=$db->fetch('Transcript', $_);
	if ($tr) {
	    my $gene=$tr->Corresponding_CDS->Gene;
	    $genes{$gene}=$gene->Public_name;
	}
    }
    foreach (keys %non_coding_transcript_hash) {
	my ($tr)=$db->fetch('Transcript', $_);
	if ($tr) {
	    my $gene=$tr->Gene;
	    $genes{$gene}=$gene->Public_name;
	}
    }
    foreach (keys %pseudo_hash) {
	my ($ps)=$db->fetch('Pseudogene', $_);
	if ($ps) {
	    my $gene=$ps->Gene;
	    $genes{$gene}=$gene->Public_name;
	}
    }
    foreach (keys %cds_hash) {
	my ($cds)=$db->fetch('CDS', $_);
	if ($cds) {
	    my $gene=$cds->Gene;
	    $genes{$gene}=$gene->Public_name;
	}
    }

    if (%genes) {
	return \%genes;
    }
    else {
	return undef;
    }
}



sub mapPCRproduct {

    my $wbrnai=shift;
    my $pcr=shift;
    my $ace_file=shift;
    my $db=shift;
    my $sqldb=shift;
    my ($total_line_count, $opts_ref)=@_;
    my %opts=%$opts_ref;

    my $pcr_obj=$db->fetch(pcr_product=>$pcr) || die "PCR product $pcr does not exist in the database : line number $total_line_count in $opts{i}\n";
    my $seq_obj=$pcr_obj->Canonical_parent;
    if (!$seq_obj) {
	die "cannot fetch canonical parent for $pcr : line number $total_line_count in $opts{i}\n";
    }
    my $query="select a, b, b[1], b[2] from a in class sequence where a=\"$seq_obj\", b in a->pcr_product where b=\"$pcr_obj\"";
    my @obj=$db->aql($query);
    my ($start,$stop)=(${$obj[0]}[2],${$obj[0]}[3]);
    unless ($start and $stop) {
	die "Could not fetch PCR product coordinates : line number $total_line_count in $opts{i}\n";
    }
    
    my $seg=$sqldb->segment(-name=>$seq_obj,-start=>$start,-end=>$stop) || die "cannot fetch segment";
    my $dna=$seg->dna;
    my $length=$seg->length;
    my $gc_length=$sqldb->segment(-name=>$seq_obj)->length;

    my $method="RNAi_primary";


    print $ace_file "\n";
    print $ace_file "///////////////////////////////////////////////////////////////\n";
    print $ace_file "//\tProbe Information: $wbrnai\n";
    print $ace_file "///////////////////////////////////////////////////////////////\n";
    print $ace_file "\n";


    print $ace_file "RNAi : \"$wbrnai\"\n";
    print $ace_file "Homol_homol\t\"$seq_obj:RNAi\"\n";
    print $ace_file "PCR_product\t\"$pcr_obj\"\n";
    print $ace_file "DNA_text\t\"$dna\"\t\"$pcr_obj\"\n";
    print $ace_file "\n";

    print $ace_file "Homol_data : \"$seq_obj:RNAi\"\n";
    print $ace_file "Sequence\t\"$seq_obj\"\n";
    print $ace_file "RNAi_homol\t\"$wbrnai\"\t\"$method\"\t100\t$start\t$stop\t1\t$length\n";
    print $ace_file "\n";
    
    print $ace_file "Sequence : \"$seq_obj\"\n";
    print $ace_file "Homol_data\t\"$seq_obj:RNAi\"\t1\t$gc_length\n";
    print $ace_file "\n";

    my $overlapping_genes_ref=getOverlappingGenes($seg, $db);
    if ($overlapping_genes_ref) {
	print $ace_file "\n";
	print $ace_file "//Overlapping_genes\t", join("|", map {"$_($$overlapping_genes_ref{$_})"}sort {$a cmp $b} keys %{$overlapping_genes_ref}), "\n";
	print $ace_file "\n";
    }
    return $overlapping_genes_ref;

}



sub mapPrimers {

    my ($paper_obj, $wbrnai, $primer1, $primer2, $ace_file, $db, $sqldb, $temp_dir, $db_file, $total_line_count, $opts_ref, $probe_count)=@_;
    my %opts=%$opts_ref;

    my ($pcr_product, $primer_name1, $primer_name2);
    my $overlapping_genes_ref;

    if ($primer1=~/(.+)\((.+)\)/) {
	my @tmp=split(/\|/, $2);
	$primer_name1=$tmp[0];
	$pcr_product=$tmp[1] if $tmp[1];
	$primer1=$1;
    }
    if ($primer2=~/(.+)\((.+)\)/) {
	my @tmp=split(/\|/, $2);
	$primer_name2=$tmp[0];
	$pcr_product=$tmp[1] if $tmp[1];
	$primer2=$1;
    }
    
    if ($primer1=~/[^AGCT]/i || $primer2=~/[^AGCT]/i) {
	die "invalid primer sequence: line number $total_line_count in $opts{i}\n";
    }
    
    my $temp_in_file=$temp_dir.int(rand(1000000));
    while (-e $temp_in_file) {
	$temp_in_file=$temp_dir.int(rand(1000000));
    }
    my $temp_out_file=$temp_dir.int(rand(1000000));
    while (-e $temp_out_file) {
	$temp_out_file=$temp_dir.int(rand(1000000));
    }

    unless (-e $db_file) {
	die "Cannot run e-PCR. Database file $db_file does not exist: line number $total_line_count in $opts{i}\n";
    }
    
    open OUTTMP, ">$temp_in_file" || die $!;
    print OUTTMP "assay_1\t".uc($primer1)."\t".uc($primer2)."\t3000\n";
    close OUTTMP;

   
    eval {    `e-PCR -m 3000 -t 3 -n 1 -o $temp_out_file $temp_in_file $db_file`; }; #allow one mismatch
    if ($@) {
	warn "e-PCR generated an error: $@\nline number $total_line_count in $opts{i}\n";
	unlink $temp_in_file, $temp_out_file;
	die "e-PCR generated an error: $@\nline number $total_line_count in $opts{i}\n";
#	exit;
    }
    
    
    
    open (INTMP, "<$temp_out_file") || die $!;
    my @epcr_results=();
    my $result_count=0;

    while (<INTMP>) {
	chomp;
	@epcr_results=split('\s+');
	$result_count++;
    
	$epcr_results[0]=~/(CHROMOSOME_)(.*)/;
	my $chrom=$2;
	my ($strand,$start,$stop)=($epcr_results[2],$epcr_results[3],$epcr_results[4]);
	unless ($chrom and $start and $stop and $strand) {
	    warn "The primer pair does not generate a PCR product: line number $total_line_count in $opts{i}\n";
	    unlink $temp_in_file, $temp_out_file;
	    die "The primer pair does not generate a PCR product: line number $total_line_count in $opts{i}\n";
#	    exit;
	}
 
	my ($seg, @features, $rel_name, $rel_start, $rel_stop, $gc, $tmp_name, $tmp_start, $tmp_stop);
	
	$seg=$sqldb->segment(-name=>$epcr_results[0],-start=>$start,-end=>$stop, -absolute=>'1') || die "cannot fetch segment";
	@features=$seg->features(-types=>'region');    # Sequence:Link and Sequence:Genomic_canonical were replaced by region:Link and region:Genomic_canonical starting from ws121
    
	$gc=0;
	$rel_name='';
	$rel_start='';
	$rel_stop='';
	foreach (@features) {
	    my $fname=$_->name;
	    my $fsource=$_->source;
	    my $fmethod=$_->method;
	    my $ftype=$_->type;
	    my $flength=$_->length;
	    if ($fsource eq 'Genomic_canonical') {
		$seg->refseq($fname);
		$rel_name=$fname;
		$rel_start=$seg->start;
		$rel_stop=$seg->stop;
		unless ($rel_start <= 0 or $rel_stop <= 0 or $rel_start > $flength or $rel_stop > $flength) {
		    $gc=1; 
		    last;
		}
	    }
	    if ($fsource eq 'Link' and $fname=~/SUPERLINK/) {
		$seg->refseq($fname);
		$tmp_name=$fname;
		$tmp_start=$seg->start;
		$tmp_stop=$seg->stop;
	    }
	}
	($rel_name,$rel_start,$rel_stop)=($tmp_name,$tmp_start,$tmp_stop) unless $gc;
	
	($rel_name,$rel_start,$rel_stop)=('MTCE', $start,$stop) if $chrom eq 'MtDNA';
	
	unless ($rel_name) {
	    warn "The primer pair does not generate a PCR product: line number $total_line_count in $opts{i}\n";
	    unlink $temp_in_file, $temp_out_file;
	    die "The primer pair does not generate a PCR product: line number $total_line_count in $opts{i}\n";
#	    exit;
	}

	my $dna=$seg->dna;
	my $length=$seg->length;
	my $gc_length=$sqldb->segment(-name=>$rel_name)->length;
	
	if (!$pcr_product) {
	    $pcr_product="$paper_obj:$rel_name"."_$probe_count"."_$result_count";
	    while ($db->fetch(pcr_product=>$pcr_product)) {
		$probe_count++;
		$pcr_product="$paper_obj:$rel_name"."_$probe_count"."_$result_count";
	    }
	}
	elsif ($pcr_product && $result_count > 1) {
	    $pcr_product=~s/_$result_count-1//g;
	    $pcr_product.="_$result_count";
	}

	if (!$primer_name1) {
	    $primer_name1="$paper_obj:".uc($primer1);
	}
	if (!$primer_name2) {
	    $primer_name2="$paper_obj:".uc($primer2);
	}

#	warn "$pcr_product, $primer_name1, $primer_name2\n";

	my $method="RNAi_primary";
	
	print $ace_file "\n";
	print $ace_file "///////////////////////////////////////////////////////////////\n";
	print $ace_file "//\tProbe Information: $wbrnai\n";
	print $ace_file "///////////////////////////////////////////////////////////////\n";
	print $ace_file "\n";

	print $ace_file "Oligo : \"$primer_name1\"\n";
	print $ace_file "Sequence\t\"".uc($primer1)."\"\n";
	print $ace_file "Length\t".length($primer1)."\n";
	print $ace_file "In_sequence\t\"$rel_name\"\n";
	print $ace_file "PCR_product\t\"$pcr_product\"\n";
	print $ace_file "\n";

	print $ace_file "Oligo : \"$primer_name2\"\n";
	print $ace_file "Sequence\t\"".uc($primer2)."\"\n";
	print $ace_file "Length\t".length($primer2)."\n";
	print $ace_file "In_sequence\t$rel_name\n";
	print $ace_file "PCR_product\t\"$pcr_product\"\n";
	print $ace_file "\n";
	
	print $ace_file "PCR_product : \"$pcr_product\"\n";
	print $ace_file "Canonical_parent\t$rel_name\n";
	print $ace_file "Oligo\t\"$primer_name1\"\n";
	print $ace_file "Oligo\t\"$primer_name2\"\n";
#	print $ace_file "RNAi\t\"$wbrnai\"\t1\t".($rel_stop-$rel_start+1)."\n";
	print $ace_file "RNAi\t\"$wbrnai\"\n";
	print $ace_file "Method\t\"GenePairs\"\n";
	print $ace_file "\n";

	print $ace_file "Sequence : \"$rel_name\"\n";
	print $ace_file "PCR_product\t\"$pcr_product\"\t$rel_start\t$rel_stop\n";
	print $ace_file "Oligo\t\"$primer_name1\"";
	if ($strand eq '+') {
	    print $ace_file "\t$rel_start\t".($rel_start+length($primer1)-1)."\n";
	}
	else {
	    print $ace_file "\t$rel_stop\t".($rel_stop-length($primer1)+1)."\n";
	}
	print $ace_file "Oligo\t\"$primer_name2\"";
	if ($strand eq '-') {
	    print $ace_file "\t$rel_start\t".($rel_start+length($primer2)-1)."\n";
	}
	else {
	    print $ace_file "\t$rel_stop\t".($rel_stop-length($primer2)+1)."\n";
	}
	print $ace_file "\n";
	
	print $ace_file "RNAi : \"$wbrnai\"\n";
	print $ace_file "Homol_homol\t\"$rel_name:RNAi\"\n";
	print $ace_file "PCR_product\t\"$pcr_product\"\n";
	print $ace_file "DNA_text\t\"$dna\"\t\"$pcr_product\"\n";
	print $ace_file "\n";
	
	print $ace_file "Homol_data : \"$rel_name:RNAi\"\n";
	print $ace_file "Sequence\t\"$rel_name\"\n";
	print $ace_file "RNAi_homol\t\"$wbrnai\"\t\"$method\"\t100\t$rel_start\t$rel_stop\t1\t$length\n";
	print $ace_file "\n";
	
	print $ace_file "Sequence : \"$rel_name\"\n";
	print $ace_file "Homol_data\t\"$rel_name:RNAi\"\t1\t$gc_length\n";
	print $ace_file "\n";

	$overlapping_genes_ref=getOverlappingGenes($seg, $db);
	if ($overlapping_genes_ref) {
	    print $ace_file "\n";
	    print $ace_file "//Overlapping_genes\t", join("|", map {"$_($$overlapping_genes_ref{$_})"}sort {$a cmp $b} keys %{$overlapping_genes_ref}), "\n";
	    print $ace_file "\n";
	}
	
    }

    
    if ($result_count == 0) {
	warn "e-PCR did not produce any results. Check your primers. line number $total_line_count in $opts{i}\n";
	unlink $temp_in_file, $temp_out_file;
	die "e-PCR did not produce any results. Check your primers. line number $total_line_count in $opts{i}\n";
#	exit;
    }
 
    unlink $temp_in_file, $temp_out_file;
    my @tmp_return=($probe_count, $overlapping_genes_ref);
    return \@tmp_return;
#    return \[$probe_count, $overlapping_genes_ref];

}



sub mapCoordinates {

    my ($paper_obj, $wbrnai, $coord, $ace_file, $db, $sqldb, $total_line_count, $opts_ref, $probe_count)=@_;
    my %opts=%$opts_ref;

    my ($seq,$start,$stop)=$coord=~/(.+):(\d+)..(\d+)/ ? ($1,$2,$3) : ('','','');
    unless ($seq and $start and $stop) {
	die "Invalid genomic coordinates: line number $total_line_count in $opts{i}\n";
    }

    if (uc $seq eq "MTDNA") {
	$seq='MTCE';
    }

     my ($seg, @features, $rel_name, $rel_start, $rel_stop, $gc, $tmp_name, $tmp_start, $tmp_stop);
    
    if ($seq eq 'I' or $seq eq 'II' or $seq eq 'III' or $seq eq 'IV' or $seq eq 'V' or $seq eq 'X') {
	$seg=$sqldb->segment(-name=>"CHROMOSOME_$seq",-start=>$start,-end=>$stop, -absolute=>'1') || die "cannot fetch segment";
    }
    else {
	$seg=$sqldb->segment(-name=>$seq,-start=>$start,-end=>$stop) || die "cannot fetch segment";
    }

    
    

    if ($seq eq 'I' or $seq eq 'II' or $seq eq 'III' or $seq eq 'IV' or $seq eq 'V' or $seq eq 'X') {
	@features=$seg->features(-types=>'region');    # Sequence:Link and Sequence:Genomic_canonical were replaced by region:Link and region:Genomic_canonical starting from ws121
	$gc=0;
	$rel_name='';
	$rel_start='';
	$rel_stop='';
	foreach (@features) {
	    my $fname=$_->name;
	    my $fsource=$_->source;
	    my $fmethod=$_->method;
	    my $ftype=$_->type;
	    my $flength=$_->length;
	    if ($fsource eq 'Genomic_canonical') {
		$seg->refseq($fname);
		$rel_name=$fname;
		$rel_start=$seg->start;
		$rel_stop=$seg->stop;
		unless ($rel_start <= 0 or $rel_stop <= 0 or $rel_start > $flength or $rel_stop > $flength) {
		    $gc=1;
		    last; 
		}
	    }
	    if ($fsource eq 'Link' and $fname=~/SUPERLINK/) {
		$seg->refseq($fname);
		$tmp_name=$fname;
		$tmp_start=$seg->start;
		$tmp_stop=$seg->stop;
	    }
	}
	($rel_name,$rel_start,$rel_stop)=($tmp_name,$tmp_start,$tmp_stop) unless $gc;
	
	unless ($rel_name) {
	    die "Incorrect genomic coordinates: line number $total_line_count in $opts{i}\n";
#	    exit;
	}
    }
    else {
	($rel_name,$rel_start,$rel_stop)=(uc $seq,$start,$stop);
    }

    my $dna=$seg->dna;
    my $length=$seg->length;
    my $gc_length=$sqldb->segment(-name=>$rel_name)->length;

    my $method="RNAi_primary";


    print $ace_file "\n";
    print $ace_file "///////////////////////////////////////////////////////////////\n";
    print $ace_file "//\tProbe Information: $wbrnai\n";
    print $ace_file "///////////////////////////////////////////////////////////////\n";
    print $ace_file "\n";
    
    print $ace_file "RNAi : \"$wbrnai\"\n";
    print $ace_file "Homol_homol\t\"$rel_name:RNAi\"\n";
    print $ace_file "DNA_text\t\"$dna\"\t\"probe_$probe_count:$rel_name\"\n";
    print $ace_file "\n";

    print $ace_file "Homol_data : \"$rel_name:RNAi\"\n";
    print $ace_file "Sequence\t\"$rel_name\"\n";
    print $ace_file "RNAi_homol\t\"$wbrnai\"\t\"$method\"\t100\t$rel_start\t$rel_stop\t1\t$length\n";
    print $ace_file "\n";
    
    print $ace_file "Sequence : \"$rel_name\"\n";
    print $ace_file "Homol_data\t\"$rel_name:RNAi\"\t1\t$gc_length\n";
    print $ace_file "\n";

    my $overlapping_genes_ref=getOverlappingGenes($seg, $db);
    if ($overlapping_genes_ref) {
	print $ace_file "\n";
	print $ace_file "//Overlapping_genes\t", join("|", map {"$_($$overlapping_genes_ref{$_})"}sort {$a cmp $b} keys %{$overlapping_genes_ref}), "\n";
	print $ace_file "\n";
    }
    return $overlapping_genes_ref;
     
}





sub mapClone {

    my ($paper_obj, $wbrnai, $clone_tmp, $ace_file, $db, $sqldb,  $temp_dir, $db_file, $total_line_count, $opts_ref, $probe_count)=@_;
    my %opts=%$opts_ref;

    my $clone="no";
    my $clone_name;

    my $query="find sequence \"$clone_tmp\"";
    my @obj=$db->find(-query=>$query);
    unless (@obj) {
	$query="find clone \"$clone_tmp\"; follow sequence; follow homol_homol";
	@obj=$db->find(-query=>$query);
	if (!@obj) {
	    die "Clone name does not exist in the database: line number $total_line_count in $opts{i}\n";
	}
	else {
	    $clone="yes";
	    $query="find clone \"$clone_tmp\"";
	    my @tmp_clone_name=$db->find(-query=>$query);
	    $clone_name=$tmp_clone_name[0];
	}
    }


    if ($clone eq "yes") {
	my (@starts, @ends, $maxstart, $maxend, $minstart, $minend, $max, $min, $homol_seq);
	$query="find homol_data \"$obj[0]\"";
	my @obj_tmp=$db->find(-query=>$query);
	my $line=$obj_tmp[0]->asAce;
	my @lines=split('\n', $line);
	my @tmp_data;
	foreach (@lines) {
	    $_=~s/\"//g;
	    @tmp_data=split('\t');
	    if ($tmp_data[2] eq "Sequence" and $tmp_data[1] eq "S_parent") {
		$homol_seq=$tmp_data[3];
		next;
	    }
# 	    unless ($tmp_data[2]=~/^$clone_tmp/ and $tmp_data[3] eq "BLAT_EST_BEST") {
	    unless ($tmp_data[2]=~/^$clone_name/ and $tmp_data[3] eq "BLAT_EST_BEST") {
		next;
	    }
	    push @starts, $tmp_data[5];
	    push @ends, $tmp_data[6];
	}

	my @sorted_starts=sort {$a <=> $b} @starts;
	my @sorted_ends=sort {$a <=> $b} @ends;
	
	$minstart=$sorted_starts[0];
	$maxstart=$sorted_starts[$#starts];
	
	$minend=$sorted_ends[0];
	$maxend=$sorted_ends[$#ends];
	
	if ($maxstart > $maxend) {
	    $max=$maxstart;
	}
	else {
	    $max=$maxend;
	}

	if ($minstart < $minend) {
	    $min=$minstart;
	}
	else {
	    $min=$minend;
	}

	
	unless ($min and $max and $homol_seq) {
	    die "Could not fetch clone coordinates: line number $total_line_count in $opts{i}\n";
	}

	if ($obj[0]=~/SUPERLINK/) {
	    my $sup_index=$obj[0]=~/.+_(\d+)$/ ? $1 : '';
	    if ($sup_index) {
		my $offset=($sup_index-1)*100000;
		$min+=$offset;
		$max+=$offset;
	    }
	}
			     

	my $seg=$sqldb->segment(-name=>$homol_seq,-start=>$min,-end=>$max) || die "cannot fetch segment";
	my $dna=$seg->dna;
	my $length=$seg->length;

	my @features=$seg->features(-types=>'region');    # Sequence:Link and Sequence:Genomic_canonical were replaced by region:Link and region:Genomic_canonical starting from ws121
	    
	my $gc=0;
	my $rel_name='';
	my $rel_start='';
	my $rel_stop='';
	my ($tmp_name,$tmp_start,$tmp_stop);
	
	foreach (@features) {
	    my $fname=$_->name;
	    my $fsource=$_->source;
	    my $fmethod=$_->method;
	    my $ftype=$_->type;
	    my $flength=$_->length;
	    if ($fsource eq 'Genomic_canonical') {
		$seg->refseq($fname);
		$rel_name=$fname;
		$rel_start=$seg->start;
		$rel_stop=$seg->stop;
		$gc=1 and last unless ($rel_start <= 0 or $rel_stop <= 0 or $rel_start > $flength or $rel_stop > $flength);
	    }
	    if ($fsource eq 'Link' and $fname=~/SUPERLINK/) {
		$seg->refseq($fname);
		$tmp_name=$fname;
		$tmp_start=$seg->start;
		$tmp_stop=$seg->stop;
	    }
	}
	($rel_name,$rel_start,$rel_stop)=($tmp_name,$tmp_start,$tmp_stop) unless $gc;

	my $rel_length=$sqldb->segment(-name=>$rel_name)->length;
	    
	my $method="RNAi_primary";

	print $ace_file "\n";
	print $ace_file "///////////////////////////////////////////////////////////////\n";
	print $ace_file "//\tProbe Information: $wbrnai\n";
	print $ace_file "///////////////////////////////////////////////////////////////\n";
	print $ace_file "\n";

	print $ace_file "RNAi : \"$wbrnai\"\n";
	print $ace_file "Homol_homol\t\"$rel_name:RNAi\"\n";
	print $ace_file "DNA_text\t\"$dna\"\t\"$clone_name\"\n";
	print $ace_file "\n";

	print $ace_file "Homol_data : \"$rel_name:RNAi\"\n";
	print $ace_file "Sequence\t\"$rel_name\"\n";
	print $ace_file "RNAi_homol\t\"$wbrnai\"\t\"$method\"\t100\t$rel_start\t$rel_stop\t1\t$length\n";
	print $ace_file "\n";
    
	print $ace_file "Sequence : \"$rel_name\"\n";
	print $ace_file "Homol_data\t\"$rel_name:RNAi\"\t1\t$rel_length\n";
	print $ace_file "\n";

	my $overlapping_genes_ref=getOverlappingGenes($seg, $db);
	if ($overlapping_genes_ref) {
	    print $ace_file "\n";
	    print $ace_file "//Overlapping_genes\t", join("|", map {"$_($$overlapping_genes_ref{$_})"}sort {$a cmp $b} keys %{$overlapping_genes_ref}), "\n";
	    print $ace_file "\n";
	}
	return $overlapping_genes_ref;

    }
    else {
	
	my $clone_obj=$obj[0];

	$query="find sequence \"$clone_obj\"; follow genomic_parent";
	@obj=$db->find(-query=>$query);
	if (@obj) {   # cDNA_for_RNAi sequences mostly
	    
	    my $seq_obj=$obj[0];
	    $query="select a, b, b[1], b[2] from a in class sequence where a=\"$seq_obj\", b in a->nongenomic where b=\"$clone_obj\"";
	    my @obj=$db->aql($query);
	    my ($start,$stop)=(${$obj[0]}[2],${$obj[0]}[3]);
	    unless ($start and $stop) {
		 die "Could not fetch clone coordinates: line number $total_line_count in $opts{i}\n";
	    }
	    
	    my $seg=$sqldb->segment(-name=>$seq_obj,-start=>$start,-end=>$stop) || die "cannot fetch segment";
	    my $dna=$seg->dna;
	    my $length=$seg->length;
	    my $gc_length=$sqldb->segment(-name=>$seq_obj)->length;
	    
	    my $method="RNAi_primary";
	    
	    print $ace_file "\n";
	    print $ace_file "///////////////////////////////////////////////////////////////\n";
	    print $ace_file "//\tProbe Information: $wbrnai\n";
	    print $ace_file "///////////////////////////////////////////////////////////////\n";
	    print $ace_file "\n";
	    
	    print $ace_file "RNAi : \"$wbrnai\"\n";
	    print $ace_file "Homol_homol\t\"$seq_obj:RNAi\"\n";
	    print $ace_file "Sequence\t\"$clone_obj\"\n";
	    print $ace_file "DNA_text\t\"$dna\"\t\"$clone_obj\"\n";
	    print $ace_file "\n";
	    
	    print $ace_file "Homol_data : \"$seq_obj:RNAi\"\n";
	    print $ace_file "Sequence\t\"$seq_obj\"\n";
	    print $ace_file "RNAi_homol\t\"$wbrnai\"\t\"$method\"\t100\t$start\t$stop\t1\t$length\n";
	    print $ace_file "\n";
	    
	    print $ace_file "Sequence : \"$seq_obj\"\n";
	    print $ace_file "Homol_data\t\"$seq_obj:RNAi\"\t1\t$gc_length\n";
	    print $ace_file "\n";

	    my $overlapping_genes_ref=getOverlappingGenes($seg, $db);
	    if ($overlapping_genes_ref) {
		print $ace_file "\n";
		print $ace_file "//Overlapping_genes\t", join("|", map {"$_($$overlapping_genes_ref{$_})"}sort {$a cmp $b} keys %{$overlapping_genes_ref}), "\n";
		print $ace_file "\n";
	    }
	    return $overlapping_genes_ref;

	}
	else { #EST mapped by homol
	    $query="find sequence \"$clone_obj\"; follow dna";
	    @obj=$db->find(-query=>$query);
	    my $dna_obj=$obj[0];
	    my $dna=$dna_obj->right;
	    unless ($dna) {
		die "Could not fetch clone sequence: line number $total_line_count in $opts{i}\n";
	    }
	    
    
  
	    print $ace_file "\n";
	    print $ace_file "///////////////////////////////////////////////////////////////\n";
	    print $ace_file "//\tProbe Information: $wbrnai\n";
	    print $ace_file "///////////////////////////////////////////////////////////////\n";
	    print $ace_file "\n";
	    
#	    warn "running blat $clone_obj\n";
	    my $overlapping_genes_ref=RunBlat($dna, $clone_obj, $temp_dir, $db_file, $ace_file, $wbrnai, $total_line_count, \%opts, $probe_count, $db);
	    
	    print $ace_file "RNAi : \"$wbrnai\"\n";
	    print $ace_file "Sequence\t\"$clone_obj\"\n";
	    print $ace_file "\n";

	    return $overlapping_genes_ref;
	}
    }
}




sub RunBlat {

    my ($dna, $probe_name, $temp_dir, $db_file, $ace_file, $wbrnai, $total_line_count, $opts_ref, $probe_count, $db)=@_;
    my %opts=%$opts_ref;

    my %overlapping_genes;

    $dna=~s/\n//g;
    $dna=~s/\s+//g;
	
    my $temp_in_file=$temp_dir.int(rand(1000000));
    while (-e $temp_in_file) {
	$temp_in_file=$temp_dir.int(rand(1000000));
    }
    my $temp_out_file=$temp_dir.int(rand(1000000));
    while (-e $temp_out_file) {
	$temp_out_file=$temp_dir.int(rand(1000000));
    }

    unless (-e $db_file) {
	die "Cannot run BLAT. Database file $db_file does not exist: line number $total_line_count in $opts{i}\n";
    }
    
    open OUTTMP, ">$temp_in_file" || die $!;
    print OUTTMP ">tmp_sequence\n";
    print OUTTMP "$dna\n";
    close OUTTMP;
    
    `blat $db_file $temp_in_file $temp_out_file -noHead`;
#    `blat $db_file $temp_in_file $temp_out_file`;
    
    open (INTMP, "<$temp_out_file") || die $!;
    my %blat_results=();
    while (<INTMP>) {
	chomp;
	next if /psLayout/;
	next if /match/;
	next if /------------------------------/;
	next unless $_;
	my @data=split('\t');
	push @{$blat_results{$data[9]}}, $_;
    }
    close INTMP;
    

    my ($count,$ambigously_mapped_count,$ambiguous,$start,$stop,$strand,$mapped_count,$quality_match_count,$quality_partial_match_count,$quality_length_count,$quality_identity_count,$qstop,$qstart,$qsize,$unique_count);
    
    my ($seg, @features, $rel_name, $rel_start, $rel_stop, $gc, $tmp_name, $tmp_start, $tmp_stop);
    
    foreach my $name (sort {$a cmp $b} keys %blat_results) {
	$count++;
	my $not_empty=0;
	my $hit_count=0;
	my @multiple_hits=();
	foreach (@{$blat_results{$name}}) {
	    my @blat=split('\t');
	    $hit_count++;
	    push @multiple_hits, \@blat;
	}
	my $criterion="percent_match";
	my $match_quality=95;
	
	my %best_hit_data_hash=%{find_best_hit(\@multiple_hits, $criterion)};
	
	my $result_count=0;
	foreach (keys %best_hit_data_hash) {
	    $result_count++;
	}
	
	if ($result_count > 1) {
	    $ambigously_mapped_count++;
	    $ambiguous='ambiguous';
	}
	else {
	    $ambiguous='unique';
	}
	
	foreach (keys %best_hit_data_hash) {
	    my @best_hit_data=@{$best_hit_data_hash{$_}};
	    
	    $best_hit_data[13]=~/(CHROMOSOME_)(.*)/;
	    my $chrom=$2;
	    my $percent_match=($best_hit_data[0]/$best_hit_data[10])*100;
	    my $query_length=(($best_hit_data[12]-$best_hit_data[11]-1)/$best_hit_data[10])*100;
	    my $percent_query=($best_hit_data[0]/($best_hit_data[12]-$best_hit_data[11]-1))*100;
	    my $percent_identity=($best_hit_data[0]/($best_hit_data[0]+$best_hit_data[1]))*100;
	    
	    $best_hit_data[15]++;  # fixes off-by-one blat problem
	    
	    ($start, $stop)=($best_hit_data[15], $best_hit_data[16]) if $best_hit_data[8] eq "+";
	    ($start, $stop)=($best_hit_data[16], $best_hit_data[15]) if $best_hit_data[8] eq "-";
	    ($qsize,$qstart,$qstop)=($best_hit_data[10], $best_hit_data[11], $best_hit_data[12]);
	    $strand=$best_hit_data[8];
	    
	    $mapped_count++;
	    $quality_match_count++ if $percent_match >= $match_quality;
	    $quality_partial_match_count++ if $percent_query >= 98;
	    $quality_length_count++ if $query_length >= 95;
	    $quality_identity_count++ if $percent_identity >=95;
	    
	    
	    $seg=$sqldb->segment(-name=>$best_hit_data[13],-start=>$start,-end=>$stop, -absolute=>'1') || die "cannot fetch segment";
	    @features=$seg->features(-types=>'region');    # Sequence:Link and Sequence:Genomic_canonical were replaced by region:Link and region:Genomic_canonical starting from ws121
	    
	    $gc=0;
	    $rel_name='';
	    $rel_start='';
	    $rel_stop='';
	    foreach (@features) {
		my $fname=$_->name;
		my $fsource=$_->source;
		my $fmethod=$_->method;
		my $ftype=$_->type;
		my $flength=$_->length;
		if ($fsource eq 'Genomic_canonical') {
		    $seg->refseq($fname);
		    $rel_name=$fname;
		    $rel_start=$seg->start;
		    $rel_stop=$seg->stop;
		    unless ($rel_start <= 0 or $rel_stop <= 0 or $rel_start > $flength or $rel_stop > $flength) {
			$gc=1;
			last;
		    }
		}
		if ($fsource eq 'Link' and $fname=~/SUPERLINK/) {
		    $seg->refseq($fname);
		    $tmp_name=$fname;
		    $tmp_start=$seg->start;
		    $tmp_stop=$seg->stop;
		}
	    }
	    ($rel_name,$rel_start,$rel_stop)=($tmp_name,$tmp_start,$tmp_stop) unless $gc;
	    
	    ($rel_name,$rel_start,$rel_stop)=('MTCE', $start,$stop) if $chrom eq 'MtDNA';
	    
	    my @exon_starts=();
	    my @exon_ends=();

	    my @self_exon_starts=();   #within CDS itself
	    my @self_exon_ends=();
	    my $qmatch=$qstop-$qstart;
	    
	    if ($best_hit_data[8] eq "+") {
		@exon_starts=split(',', $best_hit_data[20]);
		@self_exon_starts=split(',', $best_hit_data[19]);
		my @blocks=split(',', $best_hit_data[18]);
		my $diff=$start-$rel_start;
		for (my $e=0; $e<=$#exon_starts; $e++) {
		    $exon_starts[$e]++;
		    $exon_starts[$e]-=$diff;
		    $exon_ends[$e]=$exon_starts[$e]+$blocks[$e]-1;

		    $self_exon_starts[$e]++;
		    $self_exon_ends[$e]=$self_exon_starts[$e]+$blocks[$e]-1;
		}
	    }
	    else {
		@exon_ends=split(',', $best_hit_data[20]);
		@self_exon_ends=split(',', $best_hit_data[19]);
		my @blocks=split(',', $best_hit_data[18]);
#		my $diff=$stop-$rel_stop;
		my $diff=$stop-$rel_start;
		for (my $e=0; $e<=$#exon_ends; $e++) {
		    $exon_ends[$e]++;
		    $exon_ends[$e]-=$diff;
		    $exon_starts[$e]=$exon_ends[$e]+$blocks[$e]-1;
#		    $self_exon_ends[$e]=$qmatch-$self_exon_ends[$e];
		    $self_exon_ends[$e]=$qsize-$self_exon_ends[$e];
		    $self_exon_starts[$e]=$self_exon_ends[$e]-($blocks[$e]-1);
		    
		}
		
		@exon_starts=sort {$a<=>$b} @exon_starts;
		@exon_ends=sort {$a<=>$b} @exon_ends;

		@self_exon_starts=sort {$b<=>$a} @self_exon_starts;
		@self_exon_ends=sort {$b<=>$a} @self_exon_ends;
	    }
	    
	    
	    $unique_count++ if $ambiguous eq 'unique' and $rel_name;
	    unless ($rel_name) {
		die "$name not mapped correctly: line number $total_line_count in $opts{i}\n";
	    }
	    if ($rel_name) {
		#merge blocks if they are immediately adjacent to each other
		my (@new_exon_starts, @new_exon_ends);
		my (@new_self_exon_starts, @new_self_exon_ends);

		if ($#exon_starts == 0) {       #no introns
		    @new_exon_ends=@exon_ends;
		    @new_exon_starts=@exon_starts;
		    @new_self_exon_ends=@self_exon_ends;
		    @new_self_exon_starts=@self_exon_starts;
		}
		else {             #multiple exons
		    for (my $e=0; $e<=$#exon_starts; $e++) {
			if ($e == 0) {
			    push @new_exon_starts, $exon_starts[$e];
			    push @new_self_exon_starts, $self_exon_starts[$e];
			    next;
			}
			if ($exon_starts[$e] == $exon_ends[$e-1] or 
			    $exon_starts[$e] == $exon_ends[$e-1]+1 or
			    $exon_starts[$e] == $exon_ends[$e-1]-1) {
			    next;
			}
			else {
			    push @new_exon_ends, $exon_ends[$e-1];
			    push @new_exon_starts, $exon_starts[$e];
			    push @new_self_exon_ends, $self_exon_ends[$e-1];
			    push @new_self_exon_starts, $self_exon_starts[$e]
				
			    }
			if ($e == $#exon_starts) {
			    push @new_exon_ends, $exon_ends[$e];
			    push @new_self_exon_ends, $self_exon_ends[$e];
			    next;
			}
		    }
		}
		    
		my @source_exon_starts=();
		my @source_exon_ends=();
		
		for (my $e=0; $e<=$#new_exon_starts; $e++) {
		    $source_exon_starts[$e]=abs($new_exon_starts[$e]-$rel_start)+1;
		    $source_exon_ends[$e]=abs($new_exon_ends[$e]-$rel_start)+1;
		}
		    
		my $gc_length=$sqldb->segment(-name=>$rel_name)->length;

		print $ace_file "RNAi : \"$wbrnai\"\n";
		print $ace_file "Homol_homol\t\"$rel_name:RNAi\"\n";
		if ($probe_name eq 'NULL') {
#		    print $ace_file "DNA_text\t\"probe_$probe_count:$rel_name\"\t\"".lc $dna."\"\n";
		    print $ace_file "DNA_text\t\"".lc $dna."\"\t";
		    print $ace_file "\"probe_$probe_count:$rel_name\"\n";
		}
		else {
#		    print $ace_file "DNA_text\t\"$probe_name\"\t\"".lc $dna."\"\n";
		    print $ace_file "DNA_text\t\"".lc $dna."\"\t";
		    print $ace_file "\"$probe_name\"\n";
		}
		print $ace_file "\n";

		my $method="RNAi_primary";
     		
		print $ace_file "Homol_data : \"$rel_name:RNAi\"\n";
		print $ace_file "Sequence\t\"$rel_name\"\n";
		for (my $e=0; $e<=$#new_exon_starts; $e++) {
		    if ($best_hit_data[8] eq "+") {
#			print $ace_file "RNAi_homol\t\"$wbrnai\"\t\"RNAi\"\t$percent_match\t$new_exon_starts[$e]\t$new_exon_ends[$e]\t$new_self_exon_starts[$e]\t$new_self_exon_ends[$e]\n";
			print $ace_file "RNAi_homol\t\"$wbrnai\"\t\"$method\"\t$percent_match\t$new_exon_starts[$e]\t$new_exon_ends[$e]\t$new_self_exon_starts[$e]\t$new_self_exon_ends[$e]\n";
			$seg=$sqldb->segment(-name=>$rel_name, -start=>$new_exon_starts[$e], -stop=>$new_exon_ends[$e]) || die "cannot fetch segment $rel_name:$new_exon_starts[$e]..$new_exon_ends[$e]:$!\n";
		    }
		    else {
#			print $ace_file "RNAi_homol\t\"$wbrnai\"\t\"RNAi\"\t$percent_match\t$new_exon_ends[$e]\t$new_exon_starts[$e]\t$new_self_exon_ends[$e]\t$new_self_exon_starts[$e]\n";
			print $ace_file "RNAi_homol\t\"$wbrnai\"\t\"$method\"\t$percent_match\t$new_exon_ends[$e]\t$new_exon_starts[$e]\t$new_self_exon_ends[$e]\t$new_self_exon_starts[$e]\n";
			$seg=$sqldb->segment(-name=>$rel_name, -start=>$new_exon_starts[$e], -stop=>$new_exon_ends[$e]) || die "cannot fetch segment $rel_name:$new_exon_ends[$e]..$new_exon_starts[$e]:$!\n";
			
		    }
		    my $temp_ref=getOverlappingGenes($seg, $db);
		    foreach (keys %{$temp_ref}) {
			$overlapping_genes{$_}=$$temp_ref{$_};
		    }
		}
		print $ace_file "\n";
		
		print $ace_file "Sequence : \"$rel_name\"\n";
		print $ace_file "Homol_data\t\"$rel_name:RNAi\"\t1\t$gc_length\n";
		print $ace_file "\n";

		if (%overlapping_genes) {
		    print $ace_file "\n";
		    print $ace_file "//Overlapping_genes\t", join("|", map {"$_($overlapping_genes{$_})"}sort {$a cmp $b} keys %overlapping_genes), "\n";
		    print $ace_file "\n";
		}
    
	    }
	}
    }
  
    unlink $temp_in_file, $temp_out_file;

    return \%overlapping_genes;

}




sub find_best_hit {
    my $blat_ref=shift;
    my $criterion=shift;
    my $hits;
    my @blat_data=();
    my %amb_blat_data=();
    my $i=0;
    my $j=0;
    my $percent_match=0;    # match/original query size
    my $query_length=0;     # length of the query that matched/original query size
    my $percent_query=0;    # match/length of the query that matched
    my $best_hit=0;
    my $best_hit_data;
    my $quality=1;
    my $number_of_hits=0;
    foreach (@$blat_ref) {
	$j=0;
	foreach (@$_) {
	    $blat_data[$i][$j]=$_;
	    $j++;
	}
	$i++;
    }
    $hits=$i;
    if ($criterion eq "percent_match") {
	for ($i=0; $i<$hits; $i++) {
	    if (($blat_data[$i][0]/$blat_data[$i][10])*100 > $percent_match) {
		$percent_match=($blat_data[$i][0]/$blat_data[$i][10])*100;
		$best_hit=$i;
	    }
	}
    }
    if ($criterion eq "query_length") {
	for ($i=0; $i<$hits; $i++) {
	    if ((($blat_data[$i][12]-$blat_data[$i][11])/$blat_data[$i][10])*100 > $query_length) {
		$query_length=(($blat_data[$i][12]-$blat_data[$i][11])/$blat_data[$i][10])*100;
		$best_hit=$i;
	    }
	}
    }	
    if ($criterion eq "percent_query") {
	for ($i=0; $i<$hits; $i++) {
	    if (($blat_data[$i][0]/($blat_data[$i][12]-$blat_data[$i][11]))*100 > $percent_query) {
		$percent_query=($blat_data[$i][0]/($blat_data[$i][12]-$blat_data[$i][11]))*100;
		$best_hit=$i;
	    }
	}
    }

    
    if ($criterion eq "percent_match") {
	for ($i=0; $i<$hits; $i++) {
	    if (($blat_data[$i][0]/$blat_data[$i][10])*100 >= (($blat_data[$best_hit][0]/$blat_data[$best_hit][10])*100) * $quality) {
		$number_of_hits++;
		@{$amb_blat_data{$number_of_hits}}=@{$blat_data[$i]};
	    }
	}
    }
    if ($criterion eq "query_length") {
	for ($i=0; $i<$hits; $i++) {
	    if ((($blat_data[$i][12]-$blat_data[$i][11])/$blat_data[$i][10])*100 >= ((($blat_data[$best_hit][12]-$blat_data[$best_hit][11])/$blat_data[$best_hit][10])*100) * $quality) {
		
		$number_of_hits++;
		@{$amb_blat_data{$number_of_hits}}=@{$blat_data[$i]};

	    }
	}
    }
    if ($criterion eq "percent_query") {
	for ($i=0; $i<$hits; $i++) {
	    if (($blat_data[$i][0]/($blat_data[$i][12]-$blat_data[$i][11]))*100 >=(($blat_data[$best_hit][0]/($blat_data[$best_hit][12]-$blat_data[$best_hit][11]))*100) * $quality) {
		
		$number_of_hits++;
		@{$amb_blat_data{$number_of_hits}}=@{$blat_data[$i]};
	    }
	}
    }




    @{$best_hit_data}=(@{$blat_data[$best_hit]}, $number_of_hits);
    
#    return $best_hit_data;
    
    my $amb_blat_data_ref=\%amb_blat_data;
    return $amb_blat_data_ref;
   
}


sub mapSequence {

    my ($paper_obj, $wbrnai, $seq, $ace_file, $db, $sqldb,  $temp_dir, $db_file, $total_line_count, $opts_ref, $probe_count)=@_;
    my %opts=%$opts_ref;


    print $ace_file "\n";
    print $ace_file "///////////////////////////////////////////////////////////////\n";
    print $ace_file "//\tProbe Information: $wbrnai\n";
    print $ace_file "///////////////////////////////////////////////////////////////\n";
    print $ace_file "\n";

    my $overlapping_genes_ref=RunBlat($seq, 'NULL', $temp_dir, $db_file, $ace_file, $wbrnai, $total_line_count, \%opts, $probe_count, $db);

    return $overlapping_genes_ref;
}



#--------This line added by Wen. --------------------
close (INTER);
