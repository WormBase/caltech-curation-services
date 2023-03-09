#!/usr/bin/perl
#
# Take the parsed models and rewrite the OtherModels.pm module, which holds a
# hash of models and tags for query_builder to use.  2002 07 04

use strict;
use diagnostics;

my @models;				# array of @models

my $infile = 'models.wrm.parsed';	# read the parsed models file
open (MOD, "<$infile") or die "Cannot open $infile : $!";
$/ = "";
while (<MOD>) {
  push @models, $_;			# put models in @models array
} # while (<MOD>)
close (MOD) or die "Cannot close $infile : $!";

my $module = "/usr/lib/perl5/5.6.1/OtherModels.pm";
open (MOD, ">$module") or die "Cannot overwrite $module : $!";
					# write to module

print MOD "package OtherModels;\n";	# write standard module opening stuff
print MOD "require Exporter;\n\n";
print MOD "our \@ISA        = qw\(Exporter\);\n";
print MOD "our \@EXPORT     = qw\( \%models \);\n";
print MOD "our \$VERSION    = 1.00;\n\n";
print MOD "\%models = \(\n";		# write start of %models hash


foreach my $model (@models) {		# for each of the models
  my %words;
  my ($name) = $model =~ m/^\?(\w+).*/;	# get the name of the model
  if ($name =~ m/^\d/) { next; }	# skip those that begin with a number
					# (don't know why 2_point_data doesn't work)
  $model =~ s/\?\w+//g;			# take out ?tags
  $model =~ s/\#\w+//g;			# take out #tags
  my @words = split/\s/, $model;	# break up into tags
  foreach my $word (@words) {		# for each tag, put it in a hash to filter
    $words{$word}++;
  } # foreach my $word (@words)
  delete $words{''};			# take out blanks
  delete $words{UNIQUE};		# take out non-tag words
  delete $words{XREF};
  delete $words{Text};
  delete $words{Int};
  delete $words{Float};
  delete $words{DateType};
  my $words = join("\", \"", sort keys %words);	# join in hash format
  print MOD "$name\t=> [ \"${words}\" ],\n";	# and put in module
} # foreach my $model (@models)

print MOD "\);\n";			# close the hash in the module

close MOD or die "Cannot close $module : $!";	# close the module
