#!/usr/bin/env perl 
use Carp;
use LWP::Simple;
use OBO::Parser::OBOParser;
use File::Slurp;
use strict;
use warnings;

my $input_file = $ARGV[0];
#my $input_file = 'phenotype_ontology.WS243.obo';
#my $input_file = 'gene_ontology_ext.obo';
#my $url= 'http://geneontology.org/ontology/go.obo';
#my $input_file = 'go.obo';
my $output_file = $ARGV[1];
#getstore($url, $input_file);

my $file_size= -s $input_file;

if ($file_size gt 0) {

my $text = read_file( $input_file ) ;
#$text =~s/expand\_assertion\_to\:\s\"Class\:\s\<http\:\/\/www\.w3\.org\/2002\/07\/owl\#Nothing\>\sEquivalentTo\:\s\?X\sand\s\(RO\_0002162\ssome\s\?Y\)\"\s\[\]//gi;
#$text =~s/property\_value\: propformat\-version \"1\.2\" xsd\:string//gi;
write_file( $input_file, \$text ) ;
			
my $my_parser = OBO::Parser::OBOParser->new();
my $ontology  = $my_parser->work($input_file);

my @terms;
my $my_term="";

foreach my $term (sort {$a->id() cmp $b->id()} @{$ontology->get_terms()}) {
        if ( defined ($term->id()) && defined($term->name()) ) {
            if ( $term->is_obsolete() ){
                 $my_term = $term->name() . "\t \(" . $term->id() . "\)" . " \( Obsolete \) \n";
               }
               else{
                     $my_term = $term->name() . "\t \(" . $term->id() . "\)\n";
                   }
	    push @terms, $my_term;
        }
}

my @output_terms = sort(@terms);

write_file( $output_file, @output_terms ) ;

}

exit 0;
