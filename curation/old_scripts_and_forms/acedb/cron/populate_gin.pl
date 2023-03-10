#!/usr/bin/perl

# Get gene data from aceserver and create an outfile with postgres commands for
# it, then execute it (as opposed to doing it on the fly since it takes 4 hours
# and data would not be there to use in the meantime).  2006 12 19
#
# Added a gin_wbgene table to show all wbgenes for Kimberly.  2008 05 01
#
# Copy of original using acedb account and local ws.  2009 08 31 
#
# Made gin_dead table, for Kimberly.  Populate with the equivalent of the aql :
# select all class gene where ->Species like "*elegans" and ->Status like "Dead"
# 2010 04 08
#
# Changed to also get Merged_into and Split_into   2010 04 09
#
# Also populate  obo_name_trp_lab obo_data_trp_lab  based on Lab data for antibody 
#   and transgene.
# Also populate  obo_name_trp_clone obo_data_trp_clone  based on Clone data.  Query
#   it last because it has problems sometimes.  2010 08 02
#
# Updated populate_gin_locus.pl to update  gin_seqname  and  gin_dead  as well as
#   gin_wbgene  and  gin_locus  No longer getting gin_seqname here, but still getting
#   gin_dead because  nameserver doesn't have the merged and split information, so 
#   doing it here as well, and only making changes to  gin_dead  from 
#   populate_gin_locus.pl as opposed to a full wipe and rewrite  2010 08 03
#
# Get Allele_designation: tag from laboratory objects, and store them for Karen + James.
# 2012 06 28



use Ace;
use strict;
use diagnostics;
use Jex;
use DBI;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n";


my $directory = '/home2/acedb/cron/';
chdir($directory) or die "Cannot go to $directory ($!)";

my $count_value = 0;
if ($ARGV[0]) { $count_value = $ARGV[0]; }

my $start = &getSimpleSecDate();

# use constant HOST => $ENV{ACEDB_HOST} || 'aceserver.cshl.org';
# use constant PORT => $ENV{ACEDB_PORT} || 2005;
# my $db = Ace->connect(-host=>HOST,-port=>PORT) or warn "Connection failure: ",Ace->error;

my $database_path = "/home3/acedb/ws/acedb";	# full path to local AceDB database; change as appropriate
my $program = "/home/acedb/bin/tace";		# full path to tace; change as appropriate
# my $program = "/bin/tace";		# full path to tace; change as appropriate
my $db = Ace->connect(-path => $database_path,  -program => $program) || die print "Connection failure: ", Ace->error;	# local database




# this may move to a nightly geneace file.  2013 09 27
  # START LAB #
my $query="find Laboratory";
my @tags = qw( Mail Representative Registered_lab_members Allele_designation );

my @objs=$db->fetch(-query=>$query);

# foreach my $obj (@objs) {
#   my $data = $obj->asString;
#   print "$obj\t$data\n";
# }

if (! @objs) { print "no objects found.\n"; }
else {
  my @pgcommands;
  my %std_name;
  my $result = $dbh->prepare( "SELECT * FROM two_standardname;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) { $row[0] =~ s/two/WBPerson/; $std_name{$row[0]} = $row[2]; }

  my $all_stuff;
  foreach my $obj (@objs) {
    $all_stuff .= "Lab designation : $obj\n";
  #   print "Lab designation : $obj\n";
    my $id = $obj; my $name = $obj; my @reps; my @mail; my @alleleDesignation;
    next unless ($name =~ m/[A-Z][A-Z]/);
    foreach my $tag (@tags) {
      foreach ($obj->$tag(1)) {
        if ($std_name{$_}) { $all_stuff .= "$tag\t$std_name{$_} ($_)\n"; if ($tag eq 'Representative') { push @reps, $std_name{$_}; } }
          else {
            if ($tag eq 'Mail') { push @mail, $_; }
            elsif ($tag eq 'Allele_designation') { push @alleleDesignation, $_; }
            $all_stuff .= "$tag\t$_\n"; }
      }
    } # foreach my $tag (@tags)
    $all_stuff .= "\n";
    my $reps = join", ", @reps; my $mails = join", ", @mail; my $reps_mails = "$reps - $mails";
    my $alleleDesignation = join", ", @alleleDesignation;
    $reps =~ s/\'/''/g; $reps_mails =~ s/\'/''/g; $mails =~ s/\'/''/g; my $data = "id: $id\nRepresentatives: " . $reps . "\nMail: " . $mails;
    if ($alleleDesignation) { $data .= "\nAllele_designation: " . $alleleDesignation; }
#     push @pgcommands, "INSERT INTO obo_name_trp_location VALUES ('$id', '$name')";
#     push @pgcommands, "INSERT INTO obo_syn_trp_location VALUES ('$id', '$reps')";
#     push @pgcommands, "INSERT INTO obo_data_trp_location VALUES ('$id', '$data')";
    push @pgcommands, "INSERT INTO obo_name_laboratory VALUES ('$id', '$name')";
    push @pgcommands, "INSERT INTO obo_syn_laboratory VALUES ('$id', '$reps_mails')";
    push @pgcommands, "INSERT INTO obo_data_laboratory VALUES ('$id', '$data')";
  }

  my (@length) = split/./, $all_stuff;
  if (scalar(@length) > 1000) {
    my $outfile_labs = 'out/labs.ace';
    open (OUT, ">$outfile_labs") or die "Cannot open $outfile_labs : $!";
    print OUT "$all_stuff";
    close (OUT) or die "Cannot close $outfile_labs : $!";
  }
  
#   $result = $dbh->do( "DELETE FROM obo_name_trp_location;" );
#   $result = $dbh->do( "DELETE FROM obo_syn_trp_location;" );
#   $result = $dbh->do( "DELETE FROM obo_data_trp_location;" );
  $result = $dbh->do( "DELETE FROM obo_name_laboratory;" );
  $result = $dbh->do( "DELETE FROM obo_syn_laboratory;" );
  $result = $dbh->do( "DELETE FROM obo_data_laboratory;" );
  foreach my $pgcommand (@pgcommands) {
    $result = $dbh->do( $pgcommand );
#     print "$pgcommand\n";
  } # foreach my $pgcommand (@pgcommands)
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
# print PG "DELETE FROM gin_seqname;\n";
print PG "DELETE FROM gin_molname;\n";
print PG "DELETE FROM gin_dead;\n";
print PG "\n\n";

my $count = 0;
# my $syn_count = 0;			# count synonyms INSERTs to see if good or not
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
#     $syn_count++;
    $is_good++;
    print PG "$command\n";
#     $result = $conn->exec( $command );
    print PG "-- $object\tOth\t$a\n"; 
  }
  my @b = $object->Sequence_name;
# Doing this in populate_gin_locus.pl off of nameserver now  2010 08 03
#   foreach my $b (@b) { 
#     my $command = "INSERT INTO gin_seqname VALUES ('$joinkey', '$b');";
#     $is_good++;
#     print PG "$command\n";
# #     $result = $conn->exec( $command );
#     print PG "-- $object\tSequence_name\t$b\n"; }
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

  # gin_dead status has a daily update from populate_gin_locus.pl but that doesn't have the merged and split information, so doing it here as well, and only making changes there as opposed to a full wipe and rewrite  2010 08 03
  my @f = $object->Status;
  my @g = $object->Species;
  my @h = $object->Merged_into;
  my @i = $object->Split_into;
  if ( ($f[0]) && ($g[0]) ) {
    if ( ($f[0] eq 'Dead') && ($g[0] =~ m/elegans$/) ) {
      my @value;
      if ($h[0]) { push @value, "merged_into $h[0]"; }
      if ($i[0]) { foreach (@i) { push @value, "split_into $i[0]"; } }
      my $value = join", ", @value; unless ($value) { $value = 'Dead'; }
      my $command = "INSERT INTO gin_dead VALUES ('$joinkey', '$value');";
      print PG "$command\n"; } }
    

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

# if ($syn_count > 10000) 			# use object count instead of synonym count ;  Kimberly 2011 05 06
if ($count > 47389) {
  `psql -e testdb < $outfile`;			# read in the generated data
}


# remove this later, will get from geneace nightly dump.  2013 09 27
  # START CLONE #
# AQL # select a, a->general_remark, a->positive_gene from a in class clone where a->type = "Plasmid"
# my $query='find Clone Type = "Plasmid"';	# this fails for some reason.  also sometimes clone fails, so putting it in last  2010 08 02
$query='find Clone';
@tags = qw( General_remark Positive_gene );
@objs=$db->fetch(-query=>$query);

if (! @objs) { print "no objects found.\n"; }
else {
  my @pgcommands;
  foreach my $obj (@objs) {
    my $type_tag = "Type";
    next unless ($obj->$type_tag(1));			# skip blank ones
    next unless ($obj->$type_tag(1) eq 'Plasmid');	# only get Plasmid
    my $id = $obj; my $name = $obj; my @stuff;
    next if ($id =~ m/^sjj/);				# skip those starting with sjj
    foreach my $tag (@tags) {
      foreach ($obj->$tag(1)) { if ($_) { push @stuff, $_; } } }
    my $stuff = join"\t", @stuff; $stuff =~ s/\'/''/g;
#     push @pgcommands, "INSERT INTO obo_name_trp_clone VALUES ('$id', '$name')";
    push @pgcommands, "INSERT INTO obo_name_clone VALUES ('$id', '$name')";
#     if ($stuff) { push @pgcommands, "INSERT INTO obo_data_trp_clone VALUES ('$id', '$stuff')"; }
    if ($stuff) { push @pgcommands, "INSERT INTO obo_data_clone VALUES ('$id', '$stuff')"; }
  }
#   my $result = $dbh->do( "DELETE FROM obo_name_trp_clone;" );
#   $result = $dbh->do( "DELETE FROM obo_data_trp_clone;" );
  my $result = $dbh->do( "DELETE FROM obo_name_clone;" );
  $result = $dbh->do( "DELETE FROM obo_data_clone;" );
  foreach my $pgcommand (@pgcommands) {
    $result = $dbh->do( $pgcommand );
#     print "$pgcommand\n";
  } # foreach my $pgcommand (@pgcommands)
}
  # END CLONE #
