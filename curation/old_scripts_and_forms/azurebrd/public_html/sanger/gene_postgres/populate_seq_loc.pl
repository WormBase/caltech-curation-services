#!/usr/bin/perl

# Get gene data from aceserver and create an outfile with postgres commands for
# it, then execute it (as opposed to doing it on the fly since it takes 4 hours
# and data would not be there to use in the meantime).  2006 12 19
#
# Added a gin_wbgene table to show all wbgenes for Kimberly.  2008 05 01

use Ace;
use strict;
use diagnostics;
use Jex;
use Pg;

my $directory = '/home/azurebrd/public_html/sanger/gene_postgres';
chdir($directory) or die "Cannot go to $directory ($!)";

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

use constant HOST => $ENV{ACEDB_HOST} || 'aceserver.cshl.org';
use constant PORT => $ENV{ACEDB_PORT} || 2005;

my $count_value = 0;
if ($ARGV[0]) { $count_value = $ARGV[0]; }

my $start = &getSimpleSecDate();

# my $outfile = 'old/gin_main.' . $start . '.pg';
my $outfile = 'seq_loc';
if ($ARGV[1]) { $outfile = $ARGV[1]; }
open (PG, ">>$outfile") or die "Cannot create $outfile : $!";
print PG "-- $start\n\n";

my $db = Ace->connect(-host=>HOST,-port=>PORT) or die "Connection failure: ",Ace->error;

my @sequences;

# if ($count_value == 0) { @genes = $db->list('Gene', 'WBGene*'); }	# when given 0000, this would not loop over WBGene0000, it would loop over everything, which is not what's intended  2008 01 10
# if ($count_value eq '0') { @genes = $db->list('Gene', 'WBGene00009998'); }

# if ($count_value eq '0') { @genes = $db->list('Sequence', 'WBGene*'); }
#   else { 
#     my $search = 'WBGene' . $count_value . '*';
#     print PG "-- \@genes = \$db->list('Gene', '$search');\n"; 
#     @genes = $db->list('Gene', $search); }

# if ($count_value eq '0') { @sequences = $db->list('Sequence', 'Y73C8B*'); }
# @sequences = $db->list('Sequence', '*'); 
if ($count_value eq '0') { @sequences = $db->list('Sequence', '*'); }
  else { 
    my $search = $count_value . '*';
    print PG "-- \@sequences = \$db->list('Gene', '$search');\n"; 
    @sequences = $db->list('Sequence', $search); }


my $result = '';

# print PG "-- DELETE FROM gin_sequence;\n";
# print PG "-- DELETE FROM gin_protein;\n";
# print PG "-- DELETE FROM gin_seqprot;\n";
# print PG "-- DELETE FROM gin_synonyms;\n";
# print PG "-- DELETE FROM gin_seqname;\n";
# print PG "-- DELETE FROM gin_molname;\n";

my $count = 0;
my $email_message = '';

foreach my $object (@sequences) {

  $count++;
  my $is_good = 0;

  my ($joinkey) = $object =~ m/(\d+)/;
# doing this in populate_gin_locus now  2008 05 31
#   my $command = "INSERT INTO gin_wbgene VALUES ('$joinkey', '$object');";
#   print PG "$command\n";
#   print PG "-- $object\tgin_wbgene\n"; 
  my @a = $object->From_laboratory;
  my $labs = join"\t", @a;
  if ($labs) {
    print PG "$object\t$labs\n";
  }
}

__END__

  my @junk = $object->CGC_name;			# these mean there's data even if we're not capturing it
  foreach my $a (@junk) { $is_good++; }
  @junk = $object->Public_name;			# these mean there's data even if we're not capturing it
  foreach my $a (@junk) { $is_good++; }
  my @a = $object->Other_name;
  foreach my $a (@a) {
    my $locus = 'other';
    if ($a =~ m/\w{3,4}\-\d+/) { $locus = 'locus'; }
    my $command = "INSERT INTO gin_synonyms VALUES ('$joinkey', '$a', '$locus');";
    $is_good++;
    print PG "$command\n";
#     $result = $conn->exec( $command );
    print PG "-- $object\tOth\t$a\n"; 
  }
  my @b = $object->Sequence_name;
  foreach my $b (@b) { 
    my $command = "INSERT INTO gin_seqname VALUES ('$joinkey', '$b');";
    $is_good++;
    print PG "$command\n";
#     $result = $conn->exec( $command );
    print PG "-- $object\tSequence_name\t$b\n"; }
  @b = $object->Molecular_name;
  foreach my $b (@b) { 
    my $command = "INSERT INTO gin_molname VALUES ('$joinkey', '$b');";
    $is_good++;
    print PG "$command\n";
#     $result = $conn->exec( $command );
    print PG "-- $object\tMolecular_name\t$b\n"; }
  my @c = $object->Corresponding_CDS;
  foreach my $c (@c) {
    my $command = "INSERT INTO gin_sequence VALUES ('$joinkey', '$c');";
    $is_good++;
    print PG "$command\n";
#     $result = $conn->exec( $command );
    my $d = '';
    $d = $c->Corresponding_protein;
    if ($d) { 
        my $command = "INSERT INTO gin_protein VALUES ('$joinkey', '$d');";
        print PG "$command\n";
#         $result = $conn->exec( $command );
        $command = "INSERT INTO gin_seqprot VALUES ('$joinkey', '$c', '$d');";
        print PG "$command\n";
#         $result = $conn->exec( $command );
        print PG "-- $object\tCDS\t$c\tCorr\t$d\n"; }
      else { 
        print PG "-- $object\tCDS\t$c\n"; }
  }
  my @e = $object->Corresponding_Transcript;
  foreach my $e (@e) { 
    my $command = "INSERT INTO gin_sequence VALUES ('$joinkey', '$e');";
    $is_good++;
    print PG "$command\n";
#     $result = $conn->exec( $command );
    print PG "-- $object\tTranscript\t$e\n"; }

  unless ($is_good > 0) { $email_message .= "$object does not have data\n"; }
}

my $user = 'populate_gin.pl';
my $email = 'vanauken@its.caltech.edu';
my $subject = 'populate_gin.pl result';
my $body = "There are $count wbgenes\n";
if ($ARGV[0]) { $body .= "For wbgenes starting with WBGene$ARGV[0]\n"; }
$body .= "\n$email_message";
&mailer($user, $email, $subject, $body);

my $end = &getSimpleSecDate();
print PG "\n-- $end\n";

close (PG) or die "Cannot create $outfile : $!";


# `psql -e testdb < $outfile`;			# read in the generated data
