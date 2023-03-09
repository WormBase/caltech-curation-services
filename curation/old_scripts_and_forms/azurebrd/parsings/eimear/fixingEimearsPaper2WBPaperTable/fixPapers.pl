#!/usr/bin/perl -w

# This script would have fixed Eimear's paper2wbpaper table, but the cgcs and
# medlines don't have other matching WBPaper values, so this doesn't do anything.
# 2005 05 26

use strict;
use diagnostics;

my $current_file = 'paper2wbpaper.txt.messedup';
my $outfile = 'paper2wbpaper.txt.fixed';
my $bad_files = 'Papers_with_only_Person_data.txt';
