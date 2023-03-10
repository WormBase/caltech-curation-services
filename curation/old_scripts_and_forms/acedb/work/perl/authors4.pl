#!/usr/bin/perl

# This example will pull some information on various authors
# from the C. Elegans ACEDB.

use lib '../blib/lib','../blib/arch';
use Ace;
use diagnostics;
use strict vars;

use constant HOST => $ENV{ACEDB_HOST} || 'stein.cshl.org';
use constant PORT => $ENV{ACEDB_PORT} || 200005;

$|=1;

print "Opening the database....";
# my $db = Ace->connect(-host=>HOST,-port=>PORT) || die "Connection failure: ",Ace->error;

my $db = Ace->connect(-host => 'stein.cshl.org',
                      -port => 200005) || die "Connection failure: ",Ace->error;

print "done.\n";


my @authors = $db->list('Author','Chan*');
print "There are ",scalar(@authors)," Author objects matching the last name.\n";
print "The first one's name is ",$authors[0],"\n";

my $object = $authors[0];
$a = $object->at('Address[0]'); 
print "$a\n";
$a = $object->at('Address[1]');
print "$a\n";
$a = $object->at('Address[2]');
print "$a\n";
my @a = $object->at('Address[2]');
foreach $_ (@a) { print "$_\n";}

# my $pproduct = "C24D10.5";
my $pproduct = "sjj_ZK353.1";
print $pproduct . "\n";
my $pcr_product = $db->fetch(PCR_product => $pproduct);
print $pcr_product . "\n";
my $seq = $pcr_product->Canonical_parent;
my ($start, $end) = $seq->at("SMap.S_Child.PCR_product.\Q$pcr_product")->row(1);
print "$start\t$end\n";


# print "Address : ", join "\n\t", $authors[0]->Address(2),"\n";
# print "Address : ", join "\n\t", $authors[0]->Address(2),"\n";
# print ($authors[0]->Mail->fetch->asString);

# print "His mailing address is ",join(',',$authors[0]->Mail),"\n";
# my @papers = $authors[0]->Paper;
# print "He has published ",scalar(@papers)," papers.\n";
# my $paper = $papers[$#papers]->pick;
# print "The title of his most recent paper is ",$paper->Title,"\n";
# print "The coauthors were ",join(", ",$paper->Author->col),"\n";
# print "Here is all the information on the first coauthor:\n";
# print (($paper->Author)[0]->fetch->asString);

