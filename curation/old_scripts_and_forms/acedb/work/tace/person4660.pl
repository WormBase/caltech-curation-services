#!/usr/bin/perl


# old cron :
# 0 4 * * * /home/azurebrd/public_html/sanger/labs/labs.pl
# 0 3 * * tue,wed,thu,fri,sat /home/azurebrd/public_html/sanger/alp_class/update_class.pl
# 0 4 * * tue,wed,thu,fri,sat /home/azurebrd/public_html/sanger/gene_rnai_variation_transgene/update_gene_rnai_variation_transgene.pl
# 0 3 * * thu /home/azurebrd/public_html/sanger/gene_postgres/wrapper.pl
#
# replaced to try every day, checking that the current_ws file has udpdated  2009 04 03
# 0 3 * * * /home/azurebrd/work/cron/postgres/ws_postgres.pl

# this works off of ace server, but takes forever (four hours ?)  no one wants these files anyway  2009 08 13



use strict;
use diagnostics;
use Jex;	# date stuff
use Ace;


# my $database_path = "/home2/acedb/ws/acedb";	# full path to local AceDB database; change as appropriate
# my $database_path = "/home3/acedb/ws/acedb";	# full path to local AceDB database; change as appropriate
my $database_path = "/home2/acedb/citace";	# full path to local citace database; change as appropriate
my $program = "/home/acedb/bin/tace";  		# full path to tace; change as appropriate

# print "Connecting to database...";

# my $db = Ace->connect('sace://aceserver.cshl.org:2005') || die "Connection failure: ", Ace->error;                      # uncomment to use aceserver.cshl.org - may be slow
my $db = Ace->connect(-path => $database_path,  -program => $program) || die print "Connection failure: ", Ace->error;   # local database

# print "done.\n";

my $query="find Person WBPerson4660";
my @objs=$db->fetch(-query=>$query);
my @tags = qw( Old_laboratory Laboratory Standard_name );
# my $person = $objs[0]->fetch->asString;
# foreach my $obj (@objs) {
#   print $obj;
# }
  foreach my $obj (@objs) {
    foreach my $tag (@tags) {
      foreach ($obj->$tag(1)) { print "$tag\t$_\n"; }
  } }


#   # START LAB #
# my $query="find Laboratory";
# my @tags = qw( Mail Representative Registered_lab_members );
# 
# my @objs=$db->fetch(-query=>$query);
# 
# if (! @objs) { print "no objects found.\n"; }
# else {
#   my %std_name;
#   my $result = $conn->exec( "SELECT * FROM two_standardname;" );
#   while (my @row = $result->fetchrow) { $row[0] =~ s/two/WBPerson/; $std_name{$row[0]} = $row[2]; }
# 
#   my $all_stuff;
#   foreach my $obj (@objs) {
#     $all_stuff .= "Lab designation : $obj\n";
#   #   print "Lab designation : $obj\n";
#     foreach my $tag (@tags) {
#       foreach ($obj->$tag(1)) {
#         if ($std_name{$_}) { $all_stuff .= "$tag\t$std_name{$_} ($_)\n"; }
#           else { $all_stuff .= "$tag\t$_\n"; }
#       }
#     } # foreach my $tag (@tags)
#     $all_stuff .= "\n";
#   }
#   
#   my (@length) = split/./, $all_stuff;
#   if (scalar(@length) > 1000) {
#     my $outfile = '/home/azurebrd/public_html/sanger/labs/labs.ace';
#     open (OUT, ">$outfile") or die "Cannot open $outfile : $!";
#     print OUT "$all_stuff";
#     close (OUT) or die "Cannot close $outfile : $!";
#   }
# }
#   # END LAB #
# 
# 
# 
#   # START gene rnai variation transgene
  
# my $directory = '/home/azurebrd/public_html/sanger/gene_rnai_variation_transgene';
# chdir($directory) or die "Cannot go to $directory ($!)";

my $aql_rnai = 'select a, b, c, d, e from a in class Gene, b in a->cgc_name, c in a -> Sequence_name, d in a->RNAi_result, e in d->Phenotype where d[2]="RNAi_primary" and not exists_tag e[Not]';
my $aql_rnai_n = 'select a, b, c, d, e from a in class Gene, b in a->cgc_name, c in a -> Sequence_name, d in a->RNAi_result, e in d->Phenotype where d[2]="RNAi_primary" and exists_tag e[Not]';
my $aql_transgene = 'select a, b, c, d, e from a in class Gene, b in a->cgc_name, c in a -> Sequence_name, d in a->Transgene_product, e in d->Phenotype where not exists_tag e[Not]';
my $aql_transgene_n = 'select a, b, c, d, e from a in class Gene, b in a->cgc_name, c in a -> Sequence_name, d in a->Transgene_product, e in d->Phenotype where exists_tag e[Not]';
my $aql_variation = 'select a, b, c, d, e from a in class Gene, b in a->cgc_name, c in a -> Sequence_name, d in a->Allele, e in d->Phenotype where not exists_tag e[Not]';
my $aql_variation_n = 'select a, b, c, d, e from a in class Gene, b in a->cgc_name, c in a -> Sequence_name, d in a->Allele, e in d->Phenotype where exists_tag e[Not]';

my $date = &getSimpleSecDate();
my @objects; my $data; my $outfile; my $old_data = '';

@objects = $db->aql($aql_rnai);
$data = '';
foreach my $object (@objects) {
  my $text = join"\t", @$object;
  $data .= "$text\n"; }
# $outfile = '/home/azurebrd/public_html/sanger/gene_rnai_variation_transgene/rnai_phenotypes';
$outfile = 'rnai_phenotypes';
$/ = undef;
# open (IN, "<$outfile") or die "Cannot open $outfile : $!";
# $old_data = <IN>;
# close (IN) or die "Cannot close $outfile : $!";

if ($data ne $old_data) {
  $date = &getSimpleSecDate();
  open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
  print OUT $data;
  close (OUT) or die "Cannot close $outfile : $!";
  $outfile = '/home/azurebrd/public_html/sanger/gene_rnai_variation_transgene/old/rnai_phenotypes.' . $date;
  open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
  print OUT $data;
  close (OUT) or die "Cannot close $outfile : $!";
}

__END__

@objects = $db->aql($aql_rnai_n);
$data = '';
foreach my $object (@objects) {
  my $text = join"\t", @$object;
  $data .= "$text\n"; }
$outfile = '/home/azurebrd/public_html/sanger/gene_rnai_variation_transgene/rnai_not_phenotypes';
open (IN, "<$outfile") or die "Cannot open $outfile : $!";
$old_data = <IN>;
close (IN) or die "Cannot close $outfile : $!";
if ($data ne $old_data) {
  $date = &getSimpleSecDate();
  open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
  print OUT $data;
  close (OUT) or die "Cannot close $outfile : $!";
  $outfile = '/home/azurebrd/public_html/sanger/gene_rnai_variation_transgene/old/rnai_not_phenotypes.' . $date;
  open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
  print OUT $data;
  close (OUT) or die "Cannot close $outfile : $!";
}

@objects = $db->aql($aql_variation);
$data = '';
foreach my $object (@objects) {
  my $text = join"\t", @$object;
  $data .= "$text\n"; }
$outfile = '/home/azurebrd/public_html/sanger/gene_rnai_variation_transgene/allele_phenotypes';
open (IN, "<$outfile") or die "Cannot open $outfile : $!";
$old_data = <IN>;
close (IN) or die "Cannot close $outfile : $!";
if ($data ne $old_data) {
  $date = &getSimpleSecDate();
  open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
  print OUT $data;
  close (OUT) or die "Cannot close $outfile : $!";
  $outfile = '/home/azurebrd/public_html/sanger/gene_rnai_variation_transgene/old/allele_phenotypes.' . $date;
  open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
  print OUT $data;
  close (OUT) or die "Cannot close $outfile : $!";
}
 
@objects = $db->aql($aql_variation_n);
$data = '';
foreach my $object (@objects) {
  my $text = join"\t", @$object;
  $data .= "$text\n"; }
$outfile = '/home/azurebrd/public_html/sanger/gene_rnai_variation_transgene/allele_not_phenotypes';
open (IN, "<$outfile") or die "Cannot open $outfile : $!";
$old_data = <IN>;
close (IN) or die "Cannot close $outfile : $!";
if ($data ne $old_data) {
  $date = &getSimpleSecDate();
  open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
  print OUT $data;
  close (OUT) or die "Cannot close $outfile : $!";
  $outfile = '/home/azurebrd/public_html/sanger/gene_rnai_variation_transgene/old/allele_not_phenotypes.' . $date;
  open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
  print OUT $data;
  close (OUT) or die "Cannot close $outfile : $!";
}

@objects = $db->aql($aql_transgene);
$data = '';
foreach my $object (@objects) {
  my $text = join"\t", @$object;
  $data .= "$text\n"; }
$outfile = '/home/azurebrd/public_html/sanger/gene_rnai_variation_transgene/transgene_phenotypes';
open (IN, "<$outfile") or die "Cannot open $outfile : $!";
$old_data = <IN>;
close (IN) or die "Cannot close $outfile : $!";
if ($data ne $old_data) {
  $date = &getSimpleSecDate();
  open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
  print OUT $data;
  close (OUT) or die "Cannot close $outfile : $!";
  $outfile = '/home/azurebrd/public_html/sanger/gene_rnai_variation_transgene/old/transgene_phenotypes.' . $date;
  open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
  print OUT $data;
  close (OUT) or die "Cannot close $outfile : $!";
}

@objects = $db->aql($aql_transgene_n);
$data = '';
foreach my $object (@objects) {
  my $text = join"\t", @$object;
  $data .= "$text\n"; }
$outfile = '/home/azurebrd/public_html/sanger/gene_rnai_variation_transgene/transgene_not_phenotypes';
open (IN, "<$outfile") or die "Cannot open $outfile : $!";
$old_data = <IN>;
close (IN) or die "Cannot close $outfile : $!";
if ($data ne $old_data) {
  $date = &getSimpleSecDate();
  open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
  print OUT $data;
  close (OUT) or die "Cannot close $outfile : $!";
  $outfile = '/home/azurebrd/public_html/sanger/gene_rnai_variation_transgene/old/transgene_not_phenotypes.' . $date;
  open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
  print OUT $data;
  close (OUT) or die "Cannot close $outfile : $!";
}

  # END gene rnai variation transgene


  # START alp class	# not needed in phenote  2009 03 27
# $directory = '/home/azurebrd/public_html/sanger/alp_class/';
# # chdir($directory) or die "Cannot switch to $directory : $!";
# 
# my @classes = qw( Life_stage Strain );
# 
# foreach my $class (@classes) {
#   my $query = "find $class";
#   my @class = $db->fetch(-query=>$query);
#   if ($class[0]) {
#     my $outfile = $directory . $class;
#     open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
#     foreach my $obj (@class) { print OUT "$obj\n"; }
#     close (OUT) or die "Cannot close $outfile : $!"; }
# } # foreach my $class (@classes)
  # END alp class

__END__

  # START gin_
$directory = '/home/azurebrd/public_html/sanger/gene_postgres';
# chdir($directory) or die "Cannot go to $directory ($!)";

$date = &getSimpleSecDate();
$outfile = $directory . '/gin_main.' . $date . '.pg';

 
open (PG, ">$outfile") or die "Cannot create $outfile : $!";
print PG "-- $date\n\n";

print PG "DELETE FROM gin_sequence;\n";
print PG "DELETE FROM gin_protein;\n";
print PG "DELETE FROM gin_seqprot;\n";
print PG "DELETE FROM gin_synonyms;\n";
print PG "DELETE FROM gin_seqname;\n";
print PG "DELETE FROM gin_molname;\n\n";

close (PG) or die "Cannot close $outfile : $!";

system(`/home/azurebrd/public_html/sanger/gene_postgres/populate_gin.pl 0000 $outfile`);
system(`/home/azurebrd/public_html/sanger/gene_postgres/populate_gin.pl 0001 $outfile`);
system(`/home/azurebrd/public_html/sanger/gene_postgres/populate_gin.pl 0002 $outfile`);
system(`/home/azurebrd/public_html/sanger/gene_postgres/populate_gin.pl 0003 $outfile`);
system(`/home/azurebrd/public_html/sanger/gene_postgres/populate_gin.pl 0004 $outfile`);
system(`/home/azurebrd/public_html/sanger/gene_postgres/populate_gin.pl 0005 $outfile`);
system(`/home/azurebrd/public_html/sanger/gene_postgres/populate_gin.pl 0006 $outfile`);
system(`/home/azurebrd/public_html/sanger/gene_postgres/populate_gin.pl 0007 $outfile`);
system(`/home/azurebrd/public_html/sanger/gene_postgres/populate_gin.pl 0008 $outfile`);
system(`/home/azurebrd/public_html/sanger/gene_postgres/populate_gin.pl 0009 $outfile`);
system(`/home/azurebrd/public_html/sanger/gene_postgres/populate_gin.pl 0010 $outfile`);
system(`/home/azurebrd/public_html/sanger/gene_postgres/populate_gin.pl 0011 $outfile`);
system(`/home/azurebrd/public_html/sanger/gene_postgres/populate_gin.pl 0012 $outfile`);
system(`/home/azurebrd/public_html/sanger/gene_postgres/populate_gin.pl 0013 $outfile`);
system(`/home/azurebrd/public_html/sanger/gene_postgres/populate_gin.pl 0014 $outfile`);
system(`/home/azurebrd/public_html/sanger/gene_postgres/populate_gin.pl 0015 $outfile`);
system(`/home/azurebrd/public_html/sanger/gene_postgres/populate_gin.pl 0016 $outfile`);
system(`/home/azurebrd/public_html/sanger/gene_postgres/populate_gin.pl 0017 $outfile`);
system(`/home/azurebrd/public_html/sanger/gene_postgres/populate_gin.pl 0018 $outfile`);
system(`/home/azurebrd/public_html/sanger/gene_postgres/populate_gin.pl 0019 $outfile`);

open (IN, "<$outfile") or die "Cannot open $outfile : $!";
for (1 .. 100) { <IN>; }	# skip 100 lines
my $is_there_insert = '';
for (1 .. 100) { $is_there_insert .= <IN>; }
close (IN) or die "Cannot close $outfile : $!";

if ($is_there_insert =~ m/INSERT INTO/) {	# delete and insert only if there are inserts to avoid wiping out tables if they're empty  2007 08 29
#   system(`psql -e testdb < $outfile`);	# this gives an error after doing everything Can't exec "DELETE FROM gin_sequence; ": No such file or directory at ./wrapper.pl line 59.
  `psql -e testdb < $outfile`;
}
  # END gin_

# started on 2009 03 27  12:28
# started on 2009 03 31  13:22   ended  2009 04 03  09:44   hoping that running off an internal drive on new tazendra will be faster
