#!/bin/perl

#Copyright (C) 2015 Joerg Fallmann E<lt>joerg.fallmann@univie.ac.atE<gt>
#This library is free software; you can redistribute it and/or modify
#it under the same terms as Perl itself, either Perl version 5.10.0 or,
#at your option, any later version of Perl 5 you may have available.
#This program is distributed in the hope that it will be useful, but
#WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
#General Public License for more details.

#Last changed Time-stamp: <2015-10-30 15:25:52> by joerg.fallmann@univie.ac.at

########## Load Modules ##########
#### We use LWP simple to send a GET request to aresite2
#### The returned JSON object is parsed with the module JSON
#### Data::Dumper is used to print the returned hash ref
use strict;
use warnings;
use LWP::Simple;
use JSON qw( decode_json );
use Data::Dumper;
use Getopt::Long qw( :config posix_default bundling no_ignore_case );
use Pod::Usage;

########## MAIN ##########

########## Define variables ##########
my ($VERBOSE, $species, @motifs, $gene, $list);

########## Process Commandline ##########
Getopt::Long::config('no_ignore_case');
pod2usage(-verbose => 0)
	unless GetOptions(
		"species|s=s" => \$species,
		"motifs|o=s"  => \@motifs,
		"gene|g=s"	  => \$gene,
		"help|h"			=> sub{pod2usage(-verbose => 1)},
		"man|m"				=> sub{pod2usage(-verbose => 2)},      
		"verbose"			=> sub{ $VERBOSE++ }
	);

########## Get PID and print command ##########
my $pid = $$;
(my $job = `cat /proc/$pid/cmdline`)=~ s/\0/ /g;
print STDERR "You called ",$job,"\n";

########## Send request ##########
### Define url
my $url = 'http://rna.tbi.univie.ac.at/AREsite/api/';

### Define gene, species, and a comma-separated list of motifs
$species = "Homo_sapiens" unless (defined $species);
$list = join(",",split(/,/,join(",",@motifs))) if (@motifs);
$list = "ATTTA" unless (defined $list);
$gene = "cxcl2" unless (defined $gene);

### Create query
my $query = join("&","?query=$gene","species=$species","list=$list");
$url .= $query;

### Fetch response and create hash ref from response
print STDERR "Fetching from ",$url,"\n";
#print Dumper (get($url));
my $aresite = {@{decode_json (get($url))}};
die "Error getting $url" unless defined $aresite;

### print hash dump to STDOUT
print Dumper (\$aresite);

### Check for request errors
print STDOUT "ERROR:\t".$aresite->{message}."\n" if (defined $aresite->{reason});

### print some values to STDOUT if no error
print STDOUT "GENE: $aresite->{id}\tENSEMBL: $aresite->{ensid}\tCoords: $aresite->{coordinates}\n" unless (defined $aresite->{reason});
