#!/usr/bin/perl

use Ace;
use strict;
use diagnostics;
use Jex;

use constant HOST => $ENV{ACEDB_HOST} || 'aceserver.cshl.org';
use constant PORT => $ENV{ACEDB_PORT} || 2005;

my $start = &getSimpleSecDate();
print "$start\n";

my $db = Ace->connect(-host=>HOST,-port=>PORT) or warn "Connection failure: ",Ace->error;

my @genes = $db->list('Gene', 'WBGene*');

foreach my $object (@genes) {
#   my $object = $genes[0];
  my @a = $object->Other_name;
  foreach my $a (@a) {
    print "$object\t$a\n"; }
  my @b = $object->Molecular_name;
  foreach my $b (@b) {
    if ($b =~ m/^WP/) { print "$object\t($b)\n"; } }
}

my $end = &getSimpleSecDate();
print "$end\n";

__END__

my $i = $db->fetch_many(Gene=>'WBGene0000000*');

# my $i = $db->fetch_many(Gene=>’WBGene0000001');
while (my $obj = $i->next) {
   print $obj->asTable;
#    my $object = $obj->asTable;
   if ($obj->Other_name) { print "OTH $obj->Other_name OTH\n"; }
   print "\n\n";
}


__END__

my $query = "find Gene; follow Other_name";
my @class = $db->fetch(-query=>$query);
print "Class Gene " . scalar(@class) . " results :</TD></TR>\n";
foreach my $class_object (@class) { print "<TR><TD>$class_object</TD></TR>\n"; }

