#!/usr/bin/perl

use strict;
use LWP::Simple;

my $pgquery = qq(SELECT exp_gene.joinkey, exp_gene.exp_gene, exp_name.exp_name, exp_anatomy.exp_anatomy, exp_paper.exp_paper, exp_endogenous.exp_endogenous, exp_qualifier.exp_qualifier  FROM exp_gene, exp_name, exp_anatomy, exp_paper, exp_endogenous, exp_qualifier WHERE (exp_endogenous='Endogenous') AND (exp_gene.joinkey=exp_endogenous.joinkey) AND (exp_gene.joinkey=exp_paper.joinkey) AND (exp_name.joinkey=exp_gene.joinkey) AND (exp_anatomy.joinkey=exp_gene.joinkey) AND (exp_qualifier.joinkey=exp_gene.joinkey) ORDER by exp_gene;);

my $baseUrl = 'http://tazendra.caltech.edu/~postgres/cgi-bin/referenceform.cgi';

# my $url = $baseUrl . '?action=Pg+!&pgcommand=SELECT+*+FROM+friend';
my $url = $baseUrl . '?action=Pg+!&perpage=all&pgcommand=' . $pgquery;
my $page = get $url;
print "PAGE $page PAGE\n";

