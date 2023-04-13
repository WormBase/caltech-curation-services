#!/usr/bin/perl

# run both dumper scripts for GO to .ace and .go format  2008 10 16

use strict;
use diagnostics;

my $directory = '/home/acedb/ranjana/citace_upload/go_curation/';

chdir($directory) or die "Cannot go to $directory ($!)";

`./go_ace_phenote.pl`;
`./go_go_phenote.pl`;
