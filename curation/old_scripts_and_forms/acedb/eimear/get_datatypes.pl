#!/usr/bin/perl -w
#
# Find the pmids and get their reference info

use strict;
use diagnostics;
use Pg;

###GLOBALS
#my @papers = qw(cgc5809 cgc5810 cgc5822 cgc5832 cgc5833 cgc5835 cgc5841 cgc5861 cgc5878);

###MAIN


print "Opening PostGres database ....";
my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;
print "done!\n";

#&getRecentPapers(\@papers);
#&getRef(\@papers);
&getRef();


sub getRef {
#    my $pap = shift;

    my @fields = qw(
		ablationdata
		antibody
		associationequiv
		associationnew
		cellfunction
		cellname
		comment
		covalent
		curator
		expression
		extractedallelename
		extractedallelenew
		fullauthorname
		functionalcomplementation
		genefunction
		geneinteractions
		geneproduct
		genesymbol
		genesymbols
		goodphoto
		invitro
		mappingdata
		microarray
		mosaic
		newmutant   
		newsnp      
		newsymbol   
		overexpression
		rnai        
		sequencechange
		sequencefeatures
		site
		stlouissnp
		structurecorrection
		structurecorrectionsanger
		structurecorrectionstlouis
		structureinformation
		synonym
		transgene
		);
    
    my $outfile = "datatype_all.out";
    open(OUT, ">$outfile") || die "Can't open $outfile: $!";
#    for my $pap(@$pap){
#	print "O:$pap\n";
#	print OUT "$pap\n";
	foreach my $field (@fields) {
	    my $type = "";
	    print OUT "//\n$field\n";
	    $type = 'cur_' . $field;
#	    my $result = $conn->exec( "SELECT * FROM $type WHERE joinkey = '$pap';");
	    my $result = $conn->exec( "SELECT * FROM $type WHERE $type IS NOT NULL;");
	    my $out = '';
	    while (my @row = $result->fetchrow) {
#		next unless $row[0] =~ /cgc/;
		if ($row[1]) { 
		    $row[1] =~ s///g;
		    $row[1] =~ s/\n//g;
#		    print "$row[1]\n";
		    print OUT "$row[0]\t$row[1]\n";
		} # if ($row[0])
	    } # while (@row = $result->fetchrow)
	} # foreach my $field (@fields)
	print OUT "\n";
#    }
    close(OUT);
    return $outfile;
} # sub getRef


