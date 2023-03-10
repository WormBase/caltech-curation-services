#!/usr/bin/perl

# Dump the .ace output from the allele_phenotype_curation.cgi for the altair
# script to grab it.  Dump the phenotype_from_obo.ace file for the same script
# to grab it.  For Carol  2006 08 24


use diagnostics;
use strict;

use LWP::Simple;

my $page =  get "http://tazendra.caltech.edu/~postgres/cgi-bin/allele_phenotype_curation.cgi?action=Dump+.ace+%21";

my $directory = '/home/acedb/carol/dump_phenotype_ace';
chdir($directory) or die "Cannot go to $directory ($!)";

my $stuff = `./dump_phenotype_ace2.pl`;

