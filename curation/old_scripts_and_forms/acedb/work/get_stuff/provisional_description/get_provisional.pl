#!/usr/bin/perl

# Get gene data from aceserver and create an outfile with postgres commands for
# it, then execute it (as opposed to doing it on the fly since it takes 4 hours
# and data would not be there to use in the meantime).  2006 12 19
#
# Added a gin_wbgene table to show all wbgenes for Kimberly.  2008 05 01
#
# Copy of original using acedb account and local ws.  2009 08 31 
#
# Get some cosmid chromosome and ends for Jean-Louis (feedback@wormbase.org)
# 2009 12 28
#
# Get some WBPapers used in Provisional_description for Erich, I haven't run this on
# all genes, since I think it would take too long.  2010 01 09

use Ace;
use strict;
use diagnostics;
use Jex;
use DBI;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n";


my $start = &getSimpleSecDate();

my $database_path = "/home3/acedb/ws/acedb";	# full path to local AceDB database; change as appropriate
my $program = "/home/acedb/bin/tace";		# full path to tace; change as appropriate
my $db = Ace->connect(-path => $database_path,  -program => $program) || die print "Connection failure: ", Ace->error;	# local database

my %hash;


# my $query="find Gene WBGene00006714";
my $query="find Gene WBGene*";
my @genes=$db->fetch(-query=>$query);

foreach my $gene (@genes) {
  my $tag = 'Provisional_description';
  if ($gene->$tag) { 
    my $map = $gene->$tag->fetch->asString; 
    if ($map =~ m/(WBPaper\d+)/) { $hash{$1}++; }
  }
}

foreach my $paper (sort keys %hash) {
  print "$paper\n";
}

#   push @result, $map;
#   my $obj = $objs[0]->fetch->asString;
#   my $left = ''; my $right = '';
#   if ($obj =~ m/Left\s+(\d+)/) { $left = $1; }
#   if ($obj =~ m/Right\s+(\d+)/) { $right = $1; }
#   push @result, $left;
#   push @result, $right;
#   my $result = join"\t", @result;
#   print "$result\n";
#   print "OB $obj OB\n";
# }

__END__

  # START LAB #
my $query="find Laboratory";
my @tags = qw( Mail Representative Registered_lab_members );

my @objs=$db->fetch(-query=>$query);

if (! @objs) { print "no objects found.\n"; }
else {
  my %std_name;
  my $result = $dbh->prepare( "SELECT * FROM two_standardname;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) { $row[0] =~ s/two/WBPerson/; $std_name{$row[0]} = $row[2]; }

  my $all_stuff;
  foreach my $obj (@objs) {
    $all_stuff .= "Lab designation : $obj\n";
  #   print "Lab designation : $obj\n";
    foreach my $tag (@tags) {
      foreach ($obj->$tag(1)) {
        if ($std_name{$_}) { $all_stuff .= "$tag\t$std_name{$_} ($_)\n"; }
          else { $all_stuff .= "$tag\t$_\n"; }
      }
    } # foreach my $tag (@tags)
    $all_stuff .= "\n";
  }

  my (@length) = split/./, $all_stuff;
  if (scalar(@length) > 1000) {
    my $outfile_labs = 'out/labs.ace';
    open (OUT, ">$outfile_labs") or die "Cannot open $outfile_labs : $!";
    print OUT "$all_stuff";
    close (OUT) or die "Cannot close $outfile_labs : $!";
  }
}
  # END LAB #




my $outfile = 'out/gin_main.' . $start . '.pg';
if ($ARGV[1]) { $outfile = $ARGV[1]; }
open (PG, ">>$outfile") or die "Cannot create $outfile : $!";
print PG "-- $start\n\n";


$query="find Gene WBGene*";

my @genes=$db->fetch(-query=>$query);

# # if ($count_value == 0) { @genes = $db->list('Gene', 'WBGene*'); }	# when given 0000, this would not loop over WBGene0000, it would loop over everything, which is not what's intended  2008 01 10
# # if ($count_value eq '0') { @genes = $db->list('Gene', 'WBGene00009998'); }
# if ($count_value eq '0') { @genes = $db->list('Gene', 'WBGene*'); }
#   else { 
#     my $search = 'WBGene' . $count_value . '*';
#     print PG "-- \@genes = \$db->list('Gene', '$search');\n"; 
#     @genes = $db->list('Gene', $search); }


# my $result = '';

print PG "DELETE FROM gin_sequence;\n";
print PG "DELETE FROM gin_protein;\n";
print PG "DELETE FROM gin_seqprot;\n";
print PG "DELETE FROM gin_synonyms;\n";
print PG "DELETE FROM gin_seqname;\n";
print PG "DELETE FROM gin_molname;\n";
print PG "\n\n";

my $count = 0;
my $syn_count = 0;			# count synonyms INSERTs to see if good or not
my $email_message = '';
foreach my $object (@genes) {

  $count++;
#   last if ($count > 10);
  my $is_good = 0;

#   print "$object\n\n";

  my ($joinkey) = $object =~ m/(\d+)/;
# doing this in populate_gin_locus now  2008 05 31
#   my $command = "INSERT INTO gin_wbgene VALUES ('$joinkey', '$object');";
#   print PG "$command\n";
#   print PG "-- $object\tgin_wbgene\n"; 

  my @junk = $object->CGC_name;			# these mean there's data even if we're not capturing it
  foreach my $a (@junk) { $is_good++; }
  @junk = $object->Public_name;			# these mean there's data even if we're not capturing it
  foreach my $a (@junk) { $is_good++; }
  my @a = $object->Other_name;
  foreach my $a (@a) {
    my $locus = 'other';
    if ($a =~ m/\w{3,4}\-\d+/) { $locus = 'locus'; }
    my $command = "INSERT INTO gin_synonyms VALUES ('$joinkey', '$a', '$locus');";
    $syn_count++;
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

  print PG "\n";
  unless ($is_good > 0) { $email_message .= "$object does not have data\n"; }
}

my $end = &getSimpleSecDate();
print PG "\n-- $end\n";

close (PG) or die "Cannot create $outfile : $!";

my $user = 'populate_gin.pl';
my $email = 'vanauken@its.caltech.edu';
my $subject = 'populate_gin.pl result';
my $body = "There are $count wbgenes\n";
if ($ARGV[0]) { $body .= "For wbgenes starting with WBGene$ARGV[0]\n"; }
$body .= "\n$email_message";
&mailer($user, $email, $subject, $body);

if ($syn_count > 10000) {
  `psql -e testdb < $outfile`;			# read in the generated data
}
