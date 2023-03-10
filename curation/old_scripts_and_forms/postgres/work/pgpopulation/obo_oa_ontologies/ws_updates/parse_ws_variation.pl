#!/usr/bin/perl

use strict;
use diagnostics;
use Jex;
use DBI;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n";
my $result = '';

my $ws_files_dir = '/home2/acedb/cron/dump_from_ws/files/';	# on tazendra to go live

# my $pg_files_dir = '/home/postgres/work/pgpopulation/obo_oa_ontologies/ws_updates/files/';
# 
# my $latestUpdateFile = '/home2/acedb/cron/dump_from_ws/files/latestDate';
# open (IN, "<$latestUpdateFile") or die "Cannot open $latestUpdateFile : $!";
# my $wsUpdateDate = <IN>; chomp $wsUpdateDate; 
# while (my $line = <IN>) { chomp $line; $wsUpdateDate = $line; }
# close (IN) or die "Cannot close $latestUpdateFile : $!";

  my $datatype = 'variation';

  my %tempVar;
  if ($datatype eq 'variation') {                       # for variations look at obo_tempfile_variation and add any terms not in geneace
    my $obotempfilevar = '/home/azurebrd/public_html/cgi-bin/data/obo_tempfile_variation';
    if (-e $obotempfilevar) {
      open (IN, "<$obotempfilevar") or warn "Cannot open $obotempfilevar : $!";
      while (my $line = <IN>) {
        chomp $line;
        my ($varid, $pubname, $pgDate, $comment) = split/\t/, $line;
        $tempVar{$varid} = $line;
      } # while (my $line = <IN>)
    } # if (-e $obotempfilevar)
  } # if ($datatype eq 'variation')

  $/ = "";
  my $infile = $ws_files_dir . 'WSVariation.ace';
  open (IN, "<$infile") or die "Cannot open $infile : $!";
  while (my $entry = <IN>) {
    $entry =~ s/\\//g;                          # take out all backslashes
    my (@lines) = split/\n/, $entry;
    my $header = shift @lines;
    my ($objName) = $header =~ m/ : \"(.*?)\"/;

    next if ( ($datatype eq 'variation') && !($tempVar{$objName}) &&
# exclude specific methods instead, for Chris 2018 05 08
              ( ($entry =~ m/Method\s+\"SNP\"/) ||
                ($entry =~ m/Method\s+\"WGS_Hawaiian_Waterston\"/) ||
                ($entry =~ m/Method\s+\"WGS_Pasadena_Quinlan\"/) ||
                ($entry =~ m/Method\s+\"WGS_Hobert\"/) ||
                ($entry =~ m/Method\s+\"Million_mutation\"/) ||
                ($entry =~ m/Method\s+\"WGS_Yanai\"/) ||
                ($entry =~ m/Method\s+\"WGS_De_Bono\"/) ||
                ($entry =~ m/Method\s+\"WGS_Andersen\"/) ||
                ($entry =~ m/Method\s+\"WGS_Flibotte\"/) ||
                ($entry =~ m/Method\s+\"WGS_Rose\"/) )
    );

    my $status = '';
    if ($entry =~ m/Live/) { $status = 'Live'; }
    elsif ($entry =~ m/Suppressed/) { $status = 'Suppressed'; }
    elsif ($entry =~ m/Dead/) { $status = 'Dead'; }

#     $data{"id"}{$objName}++;
    my $name = $objName;
    if ($entry =~ m/Public_name\s+\"(.*?)\"/) { $name = $1; }
#     $variationsInGeneace{nameToId}{$name}    = $objName;
#     $variationsInGeneace{idToName}{$objName} = $name;

    my @genes;
    if ($entry =~ m/Gene\t "(WBGene\d+)"/) {
      (@genes) = $entry =~ m/Gene\t "(WBGene\d+)"/g; }
    my $genes = join", ", @genes; 
#     if ($genes) {
    unless ($status) {
      print qq($objName\t$name\t$status\t$genes\n); 
    }


#     $entry =~ s/\\//g;                          # take out all backslashes
#     my (@lines) = split/\n/, $entry;
#     my $header = shift @lines;
#     my $cds = '';
#     if ($header =~ m/CDS : \"([^"]+)\"/) { $cds = $1; }
#     foreach my $line (@lines) {
# #       if ($line =~ m/^Corresponding_protein\t \"(.*)\"/) { $cdsToProt{$cds}{$1}++; }	# each cds maps to just one protein
#       if ($line =~ m/^Corresponding_protein\t \"(.*)\"/) { $cdsToProt{$cds} = $1; } }
  } # while (my $entry = <IN>)
  close (IN) or die "Cannot close $infile : $!";


#   if ($datatype eq 'variation') {                       # for variations look at obo_tempfile_variation and add any terms not in geneace
#     my $emailForKaren = '';
#     foreach my $objName (sort keys %tempVar) {
#       my ($varid, $pubname, $pgDate, $comment) = split/\t/, $tempVar{$objName};
#       if ( $variationsInGeneace{nameToId}{$pubname} ) {         # compare varid-pubname by pubname to different varid
#           my $geneaceVarid = $variationsInGeneace{nameToId}{$pubname};
#           if ($geneaceVarid ne $varid) { $emailForKaren .= qq($pubname in obo_tempfile_variation says $varid geneace says $geneaceVarid\n); } }
#       if ( $variationsInGeneace{idToName}{$varid} ) {                   # compare varid-pubname by varid to different pubname
#           my $geneacePubname = $variationsInGeneace{idToName}{$varid};
#           if ($geneacePubname ne $pubname) { $emailForKaren .= qq($varid in obo_tempfile_variation says $pubname geneace says $geneacePubname\n); } }
#         else {                                                  # temp varid not in geneace, add to obo tables from tempfile
#           my $terminfo = qq(id: $varid\\nname: "$pubname"\\ntimestamp: "$pgDate"\\ncomment: "$comment");
#           print DATA qq($varid\t$terminfo\t$timestamp\n);
#           print NAME qq($varid\t$pubname\t$timestamp\n);
#       } # else # if ( $variationsInGeneace{idToName}{$varid} )
#     } # foreach my $objName (sort keys %tempVar)


__END__

from here below is copy of  populate_pg_from_ws.pl

# take data from a WS dump of Gene, CDS, Expression_cluster go populate obo_<name|data>_exprcluster as well as 
# gin_molname, gin_sequence, gin_protein, gin_seqprot.  
# It must be run from postgres for the faster copying of the whole table, instead of taking nearly 2 hours to 
# insert one by one on the acedb account.
# using this scipt would require timing the WS update script to signal to also run the script to generate the 
# .ace files and this script to populate postgres.  Probably by looking at the latest /home3/acedb/ws/logs/
# although sometimes it takes 13 hours 28 minutes to update WS, so maybe it won't be good once it's so big it
# takes 24 hours.
# 2013 10 01
#
# cronjob has 0 3 * * * /home/acedb/cron/update_ws_tazendra.pl
# which triggers  /home/acedb/cron/dump_from_ws.sh  which write to file  /home3/acedb/cron/dump_from_ws/files/latestDate
# against which compare the date to trigger running this script if that is more recent than the $timestamp in 
# these files.  2013 10 18
#
# live on tazendra  2013 10 21
#
# added  &processFeature()  for Chris, it also emails him of any unexpected Methods.  2013 11 13
#
# latestDate was getting appended, not replaced (to keep history).  grabbing from latest line now.  2013 03 12
#
# disable processing Feature objects, they are now part of the nightly geneace dump from  nightly_geneace.pl
# for Chris and Xiaodong.  2014 03 19


# 0 5 * * * /home/postgres/work/pgpopulation/obo_oa_ontologies/ws_updates/populate_pg_from_ws.pl



# use Ace;
use strict;
use diagnostics;
use Jex;
use DBI;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n";
my $result = '';

# my $ws_files_dir = '/home/postgres/work/pgpopulation/obo_oa_ontologies/ws_updates/files/';	# for testing on mangolassi
my $ws_files_dir = '/home2/acedb/cron/dump_from_ws/files/';	# on tazendra to go live
my $pg_files_dir = '/home/postgres/work/pgpopulation/obo_oa_ontologies/ws_updates/files/';

my $latestUpdateFile = '/home2/acedb/cron/dump_from_ws/files/latestDate';
open (IN, "<$latestUpdateFile") or die "Cannot open $latestUpdateFile : $!";
my $wsUpdateDate = <IN>; chomp $wsUpdateDate; 
while (my $line = <IN>) { chomp $line; $wsUpdateDate = $line; }
close (IN) or die "Cannot close $latestUpdateFile : $!";

$result = $dbh->prepare( "SELECT * FROM gin_molname ORDER BY gin_timestamp DESC;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
my @row = $result->fetchrow(); my $pgTimestamp = $row[2];
my ($year, $month, $day) = $pgTimestamp =~ m/^(\d{4})-(\d{2})-(\d{2})/; 
my $fromPgSimpleDate = $year . $month . $day;

# if ($wsUpdateDate > $fromPgSimpleDate) { print "do stuff\n"; } else { print "do nothing\n"; }

my $timestamp = &getPgDate();
if ($wsUpdateDate > $fromPgSimpleDate) {			# if ws was updated more recently than postgres timestamp, do the updates
  &processGeneCds();
  &processExprCluster();
#   &processFeature();						# get features from nightly geneace dump instead  2014 03 19
#   print "DONE\n";
}


sub processGeneCds {
  my @pgcommands;
  my %cdsToProt;
  my $molfile = $pg_files_dir . 'gin_molname.pg';
  my $seqfile = $pg_files_dir . 'gin_sequence.pg';
  my $protfile = $pg_files_dir . 'gin_protein.pg';
  my $seqprotfile = $pg_files_dir . 'gin_seqprot.pg';
  open (MOL, ">$molfile") or die "Cannot create $molfile : $!";
  open (SEQ, ">$seqfile") or die "Cannot create $seqfile : $!";
  open (PRO, ">$protfile") or die "Cannot create $protfile : $!";
  open (SPR, ">$seqprotfile") or die "Cannot create $seqprotfile : $!";
  $/ = "";
  my $infile = $ws_files_dir . 'WSCDS.ace';
  open (IN, "<$infile") or die "Cannot open $infile : $!";
  while (my $entry = <IN>) {
    next unless ($entry =~ m/CDS : \"/);
    $entry =~ s/\\//g;                          # take out all backslashes
    my (@lines) = split/\n/, $entry;
    my $header = shift @lines;
    my $cds = '';
    if ($header =~ m/CDS : \"([^"]+)\"/) { $cds = $1; }
    foreach my $line (@lines) {
#       if ($line =~ m/^Corresponding_protein\t \"(.*)\"/) { $cdsToProt{$cds}{$1}++; }	# each cds maps to just one protein
      if ($line =~ m/^Corresponding_protein\t \"(.*)\"/) { $cdsToProt{$cds} = $1; } }
  } # while (my $entry = <IN>)
  close (IN) or die "Cannot close $infile : $!";
  $infile = $ws_files_dir . 'WSGene.ace';
  open (IN, "<$infile") or die "Cannot open $infile : $!";
  while (my $entry = <IN>) {
    next unless ($entry =~ m/Gene : \"/);
    $entry =~ s/\\//g;                          # take out all backslashes
    my %data;
    my (@lines) = split/\n/, $entry;
    my $header = shift @lines;
    my $joinkey = '';
    if ($header =~ m/Gene : \"WBGene([^"]+)\"/) { $joinkey = $1; }
    my @tags = qw( Molecular_name Corresponding_transcript Corresponding_CDS );
    foreach my $line (@lines) {
      foreach my $tag (@tags) { 
        if ($line =~ m/^$tag\t \"(.*)\"/) { $data{$tag}{$1}++; } } }
    foreach my $molname (sort keys %{ $data{"Molecular_name"} }) {
#       push @pgcommands, qq(INSERT INTO gin_molname VALUES ('$joinkey', '$molname'););	# for pgcommands to populate one by one from any account
      print MOL qq($joinkey\t$molname\t$timestamp\n); }
    foreach my $sequence (sort keys %{ $data{"Corresponding_transcript"} }) {
#       push @pgcommands, qq(INSERT INTO gin_sequence VALUES ('$joinkey', '$sequence'););	# for pgcommands to populate one by one from any account
      print SEQ qq($joinkey\t$sequence\t$timestamp\n); }
    foreach my $sequence (sort keys %{ $data{"Corresponding_CDS"} }) {
#       push @pgcommands, qq(INSERT INTO gin_sequence VALUES ('$joinkey', '$sequence'););	# for pgcommands to populate one by one from any account
      print SEQ qq($joinkey\t$sequence\t$timestamp\n);
      if ($cdsToProt{$sequence}) {
        my $protein = $cdsToProt{$sequence};
#         push @pgcommands, qq(INSERT INTO gin_seqprot VALUES ('$joinkey', '$sequence', '$protein'););	# for pgcommands to populate one by one from any account
#         push @pgcommands, qq(INSERT INTO gin_protein VALUES ('$joinkey', '$protein'););	# for pgcommands to populate one by one from any account
        print SPR qq($joinkey\t$sequence\t$protein\t$timestamp\n);
        print PRO qq($joinkey\t$protein\t$timestamp\n); } }
  } # while (my $entry = <IN>)
  close (IN) or die "Cannot close $infile : $!";
  $/ = "\n";
  close (MOL) or die "Cannot close $molfile : $!";
  close (SEQ) or die "Cannot close $seqfile : $!";
  close (PRO) or die "Cannot close $protfile : $!";
  close (SPR) or die "Cannot close $seqprotfile : $!";
  push @pgcommands, qq(DELETE FROM gin_molname;);
  push @pgcommands, qq(DELETE FROM gin_sequence;);
  push @pgcommands, qq(DELETE FROM gin_protein;);
  push @pgcommands, qq(DELETE FROM gin_seqprot;);
  push @pgcommands, qq(COPY gin_molname  FROM '$molfile';);
  push @pgcommands, qq(COPY gin_sequence FROM '$seqfile';);
  push @pgcommands, qq(COPY gin_protein  FROM '$protfile';);
  push @pgcommands, qq(COPY gin_seqprot  FROM '$seqprotfile';);

# for pgcommands to populate one by one from any account
#   if (scalar @pgcommands > 100) { 
#     unshift @pgcommands, qq(DELETE FROM gin_sequence;);
#     unshift @pgcommands, qq(DELETE FROM gin_seqprot;);
#     unshift @pgcommands, qq(DELETE FROM gin_protein;);
#     unshift @pgcommands, qq(DELETE FROM gin_molname;); }

  foreach my $pgcommand (@pgcommands) {
    print qq($pgcommand\n);
# UNCOMMENT TO POPULATE
    $dbh->do( $pgcommand );
  } # foreach my $pgcommand (@pgcommands)

# to test if cds map to multiple proteins
#   foreach my $cds (sort keys %cdsToProt) {
#     my (@prots) = sort keys %{ $cdsToProt{$cds} };
#     if (scalar @prots > 1) { print "$cds @prots\n"; }
#     my $prots = join"|", @prots;
#     print "$cds\t$prots\n";
#   } # foreach my $cds (sort keys %cdsToProt)
} # sub processGeneCds

sub processExprCluster {
  my @pgcommands;
  my @tags = qw( Description Reference Remark );
  my %tags; foreach (@tags) { $tags{$_}++; }
  my $name_file = $pg_files_dir . 'obo_name_exprcluster.pg';
  my $data_file = $pg_files_dir . 'obo_data_exprcluster.pg';
  open (NAME, ">$name_file") or die "Cannot create $name_file : $!";
  open (DATA, ">$data_file") or die "Cannot create $data_file : $!";
  my $infile = $ws_files_dir . 'WSExpression_cluster.ace';
  $/ = "";
  open (IN, "<$infile") or die "Cannot open $infile : $!";
  while (my $entry = <IN>) {
    next unless ($entry =~ m/Expression_cluster : \"/);
    $entry =~ s/\\//g;                          # take out all backslashes
#     $entry =~ s/\[/\\[/g;                          # escape all square brackets
#     $entry =~ s/\]/\\]/g;                          # escape all square brackets
    my %data;
    my (@lines) = split/\n/, $entry;
    my $header = shift @lines;
    my $id = '';
    if ($header =~ m/Expression_cluster : \"([^"]+)\"/) { $id = $1; }
    next if ($id =~ m/^WBPaper00029359/);	# skip for Karen, chronograms.  2013 10 01
    my @all_data; push @all_data, qq(id: $id); push @all_data, qq(name: "$id");
    foreach my $line (@lines) {
      foreach my $tag (@tags) { 
        if ($line =~ m/^$tag\t \"(.*)\"/) { $data{$tag}{$1}++; } } }
    foreach my $tag (@tags) {
      foreach my $data (sort keys %{ $data{$tag} }) {
        my $lctag = lc($tag);
        push @all_data, qq($lctag: "$data"); } }
    my $all_data = join"\\n", @all_data;
    if ($all_data =~ m/\'/) { $all_data =~ s/\'/''/g; }
    print NAME qq($id\t$id\t$timestamp\n);
    print DATA qq($id\t$all_data\t$timestamp\n);
# for pgcommands to populate one by one from any account
#     push @pgcommands, qq(INSERT INTO obo_name_exprcluster VALUES ('$id', '$id'););
#     push @pgcommands, qq(INSERT INTO obo_data_exprcluster VALUES ('$id', E'$all_data'););
#     print "ID $id\n";
#     print "DATA $all_data\n\n";
  } # while (my $entry = <IN>)
  close (IN) or die "Cannot close $infile : $!";
  $/ = "\n";
  close (DATA) or die "Cannot close $data_file : $!";
  close (NAME) or die "Cannot close $name_file : $!";
  push @pgcommands, qq(DELETE FROM obo_name_exprcluster;);
  push @pgcommands, qq(DELETE FROM obo_data_exprcluster;);
  push @pgcommands, qq(COPY obo_name_exprcluster FROM '$name_file';);
  push @pgcommands, qq(COPY obo_data_exprcluster FROM '$data_file';);

# for pgcommands to populate one by one from any account
#   if (scalar @pgcommands > 100) { 
#     unshift @pgcommands, qq(DELETE FROM obo_name_exprcluster;);
#     unshift @pgcommands, qq(DELETE FROM obo_data_exprcluster;); }
  foreach my $pgcommand (@pgcommands) {
    print qq($pgcommand\n);
# UNCOMMENT TO POPULATE
    $dbh->do( $pgcommand );
  } # foreach my $pgcommand (@pgcommands)
} # sub processExprCluster

sub processFeature {
  my @pgcommands;
  my @tags = qw( Public_name DNA_text Species Defined_by_paper Associated_with_gene Associated_with_Interaction Associated_with_expression_pattern Bound_by_product_of Transcription_factor Method );
  my %allowedMethods; my %expectedMethods; my %unexpectedMethods;
  my @allowedMethods = qw( binding_site binding_site_region DNAseI_hypersensitive_site enhancer histone_binding_site_region promoter regulatory_region TF_binding_site TF_binding_site_region );
  my @rejectedMethods = qw( Corrected_genome_sequence_error Genome_sequence_error history history_feature micro_ORF polyA_signal_sequence polyA_site segmental_duplication SL1 SL2 three_prime_UTR transcription_end_site transcription_start_site TSS_region );

  foreach (@allowedMethods) { $allowedMethods{$_}++; $expectedMethods{$_}++; }
  foreach (@rejectedMethods) { $expectedMethods{$_}++; }
  my %tags; foreach (@tags) { $tags{$_}++; }
  my $name_file = $pg_files_dir . 'obo_name_feature.pg';
  my $data_file = $pg_files_dir . 'obo_data_feature.pg';
  open (NAME, ">$name_file") or die "Cannot create $name_file : $!";
  open (DATA, ">$data_file") or die "Cannot create $data_file : $!";
  my $infile = $ws_files_dir . 'WSFeature.ace';
  $/ = "";
  open (IN, "<$infile") or die "Cannot open $infile : $!";
  while (my $entry = <IN>) {
    next unless ($entry =~ m/Feature : \"WBsf/);
    next unless ($entry =~ m/Method\s+\"(.*)\"/);
    my $method = $1; 
    unless ($expectedMethods{$method}) { $unexpectedMethods{$method}++; }
    next unless ($allowedMethods{$method});
    $entry =~ s/\\//g;                          # take out all backslashes
#     $entry =~ s/\[/\\[/g;                          # escape all square brackets
#     $entry =~ s/\]/\\]/g;                          # escape all square brackets
    my %data;
    my (@lines) = split/\n/, $entry;
    my $header = shift @lines;
    my $id = '';
    if ($header =~ m/Feature : \"(WBsf\d+)\"/) { $id = $1; }
#     next if ($id =~ m/^WBPaper00029359/);	# to skip stuff put code here
    my @all_data; push @all_data, qq(id: $id); push @all_data, qq(name: "$id");
    foreach my $line (@lines) {
      foreach my $tag (@tags) { 
        if ($line =~ m/^$tag\t \"(.*)\"/) { $data{$tag}{$1}++; } } }
    foreach my $tag (@tags) {
      foreach my $data (sort keys %{ $data{$tag} }) {
        my $lctag = lc($tag);
        push @all_data, qq($lctag: "$data"); } }
    my $all_data = join"\\n", @all_data;
    if ($all_data =~ m/\'/) { $all_data =~ s/\'/''/g; }
    print NAME qq($id\t$id\t$timestamp\n);
    print DATA qq($id\t$all_data\t$timestamp\n);
  } # while (my $entry = <IN>)
  close (IN) or die "Cannot close $infile : $!";
  $/ = "\n";
  close (DATA) or die "Cannot close $data_file : $!";
  close (NAME) or die "Cannot close $name_file : $!";
  push @pgcommands, qq(DELETE FROM obo_name_feature;);
  push @pgcommands, qq(DELETE FROM obo_data_feature;);
  push @pgcommands, qq(COPY obo_name_feature FROM '$name_file';);
  push @pgcommands, qq(COPY obo_data_feature FROM '$data_file';);

  if (scalar %unexpectedMethods > 0) {
    my $body = join", ", keys %unexpectedMethods;
    my $user = 'populate_pg_from_ws.pl';
#     my $email = 'azurebrd@tazendra.caltech.edu';
    my $email = 'cgrove@caltech.edu';
    my $subject = 'unexpected feature methods';
    &mailer($user, $email, $subject, $body);
  } # if (scalar %unexpectedMethods > 0)

  foreach my $pgcommand (@pgcommands) {
    print qq($pgcommand\n);
# UNCOMMENT TO POPULATE
    $dbh->do( $pgcommand );
  } # foreach my $pgcommand (@pgcommands)
} # sub processFeature

__END__

my $directory = '/home2/acedb/cron/';
chdir($directory) or die "Cannot go to $directory ($!)";

my $count_value = 0;
if ($ARGV[0]) { $count_value = $ARGV[0]; }

my $start = &getSimpleSecDate();

# use constant HOST => $ENV{ACEDB_HOST} || 'aceserver.cshl.org';
# use constant PORT => $ENV{ACEDB_PORT} || 2005;
# my $db = Ace->connect(-host=>HOST,-port=>PORT) or warn "Connection failure: ",Ace->error;

my $database_path = "/home3/acedb/ws/acedb";	# full path to local AceDB database; change as appropriate
# my $program = "/home/acedb/bin/tace";		# full path to tace; change as appropriate
my $program = "/bin/tace";		# full path to tace; change as appropriate
my $db = Ace->connect(-path => $database_path,  -program => $program) || die print "Connection failure: ", Ace->error;	# local database




  # START LAB #
my $query="find Laboratory";
my @tags = qw( Mail Representative Registered_lab_members );

my @objs=$db->fetch(-query=>$query);

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
    my $id = $obj; my $name = $obj; my @reps; my @mail;
    next unless ($name =~ m/[A-Z][A-Z]/);
    foreach my $tag (@tags) {
      foreach ($obj->$tag(1)) {
        if ($std_name{$_}) { $all_stuff .= "$tag\t$std_name{$_} ($_)\n"; if ($tag eq 'Representative') { push @reps, $std_name{$_}; } }
          else {
            if ($tag eq 'Mail') { push @mail, $_; }
            $all_stuff .= "$tag\t$_\n"; }
      }
    } # foreach my $tag (@tags)
    $all_stuff .= "\n";
    my $reps = join", ", @reps; my $mails = join", ", @mail; my $reps_mails = "$reps - $mails";
    $reps =~ s/\'/''/g; $reps_mails =~ s/\'/''/g; $mails =~ s/\'/''/g; my $data = "id: $id\nRepresentatives: " . $reps . "\nMail: " . $mails;
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


__END__

