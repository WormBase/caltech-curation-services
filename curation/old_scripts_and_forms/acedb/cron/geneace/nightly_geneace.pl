#!/usr/bin/perl

# starting point to populate postgres tables based on nightly geneace dump.  2013 09 27

use strict;
use diagnostics;
use Jex;
use DBI;
use LWP::UserAgent;
use Tie::IxHash;
use LWP::Simple;


my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my $directory = '/home/acedb/cron/geneace/temp/';
chdir($directory) or die "Cannot go to $directory ($!)";


my $ftp_dir = 'ftp://ftp.sanger.ac.uk/pub2/wormbase/STAFF/mh6/nightly_geneace/';
# my @gz = qw( cloness.ace.gz genes.ace.gz rearrangements.ace.gz strains.ace.gz variations.ace.gz );
my @gz = qw( cloness.ace.gz rearrangements.ace.gz strains.ace.gz variations.ace.gz );

my %wbgeneToLocus;
my $result = $dbh->prepare( "SELECT * FROM gin_locus" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) { $wbgeneToLocus{"WBGene$row[0]"} = $row[1]; }


foreach my $gz (@gz) {
  my ($datatype) = $gz =~ m/^(.*)\.ace.gz/;
  my $ftp = $ftp_dir . $gz;
  my $ftpdata = get $ftp;	# this gunzips the file
  if ($ftpdata =~ m/^\n/) { $ftpdata =~ s/^\n//; }
  my (@entries) = split/\n\n/, $ftpdata;
#   my $tempfile = $directory . 'temp.gz'; 
#   print $ftpdata;
#   open (OUT, ">$tempfile") or die "Cannot create $tempfile : $!";
#   print OUT $ftpdata;
#   close (OUT) or die "Cannot close $tempfile : $!";
# }
# __END__
# #   my $infile = 'rearrangements.ace.gz';
#   $/ = "";
#   open (IN, "gunzip -c $tempfile |") or die "Cannot open $tempfile : $!";
#   while (my $entry = <IN>) {
  foreach my $entry (@entries) {
    next if ( ($datatype eq 'cloness') && ($entry !~ m/\nPlasmid/) );
    next if ( ($datatype eq 'variations') && 
              ($entry !~ m/Method\s+\"Allele\"/) &&
              ($entry !~ m/Method\s+\"Deletion_allele\"/) &&
              ($entry !~ m/Method\s+\"Deletion_and_insertion_allele\"/) &&
              ($entry !~ m/Method\s+\"Deletion_polymorphism\"/) &&
              ($entry !~ m/Method\s+\"Insertion_allele\"/) &&
              ($entry !~ m/Method\s+\"Insertion_polymorhism\"/) &&
              ($entry !~ m/Method\s+\"KO_consortium_allele\"/) &&
              ($entry !~ m/Method\s+\"Mos_insertion\"/) &&
              ($entry !~ m/Method\s+\"NBP_knockout_allele\"/) &&
              ($entry !~ m/Method\s+\"NemaGENETAG_consortium_allele\"/) &&
              ($entry !~ m/Method\s+\"Substitution_allele\"/) &&
              ($entry !~ m/Method\s+\"Transposon_insertion\"/)
            );
    my (@lines) = split/\n/, $entry;
    my $header = shift @lines;
    my ($objName) = $header =~ m/ : \"(.*?)\"/;
#     print "ENTRY $entry HEADER $header NAME $objName END\n";
    my %data; tie %data, "Tie::IxHash";
    $data{"id"}{$objName}++;
    my $name = $objName;
    if ($datatype eq 'variations') {
      if ($entry =~ m/Public_name\s+\"(.*?)\"/) { $name = $1; } }
    $data{"name"}{$name}++;
#     my $data = qq(id: $objName\nname: "$name");
    foreach my $line (@lines) {
      if ($line =~ m/Reference\t \"(.*?)\"/) { 
        if ( ($datatype eq 'cloness') || ($datatype eq 'variations') ) { 
          $data{"reference"}{$1}++; } }
      elsif ($line =~ m/Accession_number\t \"(.*?)\"/) { 
        if ($datatype eq 'cloness') { 
          $data{"accession_number"}{$1}++; } }
      elsif ($line =~ m/General_remark\t \"(.*?)\"/) { 
        if ($datatype eq 'cloness') { 
          $data{"remark"}{$1}++; } }
      elsif ($line =~ m/In_strain\t \"(.*?)\"/) { 
        if ($datatype eq 'cloness') { 
          $data{"strain"}{$1}++; } }
      elsif ($line =~ m/Transgene\t \"(.*?)\"/) { 
        if ($datatype eq 'cloness') { 
          $data{"transgene"}{$1}++; } }
      elsif ($line =~ m/Location\t \"(.*?)\"/) {
        if ( ($datatype eq 'cloness') || ($datatype eq 'strains') ) { 
          $data{"location"}{$1}++; } }
      elsif ($line =~ m/Map\t \"(.*?)\"/) { 
        if ($datatype eq 'rearrangements') { 
          $data{"map"}{$1}++; } }
      elsif ($line =~ m/Gene_outside\t \"(WBGene\d+)\"/) {
        if ($datatype eq 'rearrangements') { 
          my $wbgene = $1;
          if ($wbgeneToLocus{$wbgene}) { $wbgene .= ' ' . $wbgeneToLocus{$wbgene}; }
          $data{"gene_outside"}{$wbgene}++; } }
      elsif ($line =~ m/Gene_inside\t \"(WBGene\d+)\"/) {
        if ($datatype eq 'rearrangements') { 
          my $wbgene = $1;
          if ($wbgeneToLocus{$wbgene}) { $wbgene .= ' ' . $wbgeneToLocus{$wbgene}; }
          $data{"gene_inside"}{$wbgene}++; } }
      elsif ($line =~ m/Strain\t \"(.*?)\"/) {
        if ($datatype eq 'strains') { 
          $data{"strain"}{$1}++; } }
      elsif ($line =~ m/Genotype\t \"(.*?)\"/) {
        if ($datatype eq 'strains') { 
          $data{"summary"}{$1}++; } }
      elsif ($line =~ m/Gene\t \"(WBGene\d+)\"/) {
        if ($datatype eq 'variations') { 
          my $wbgene = $1;
          if ($wbgeneToLocus{$wbgene}) { $wbgene .= ' ' . $wbgeneToLocus{$wbgene}; }
          $data{"gene"}{$wbgene}++; } }
      elsif ($line =~ m/^Dead/) {
        if ($datatype eq 'variations') { 
          $data{"status"}{"Dead"}++; } }
      elsif ($line =~ m/^Live/) {
        if ($datatype eq 'variations') { 
          $data{"status"}{"Live"}++; } }
    } # foreach my $line (@lines)
    my $all_data = '';
    foreach my $key (keys %data) {
      foreach my $data (sort keys %{ $data{$key} }) {
        unless ($key eq 'id') { $data = '"' . $data . '"'; }
        $all_data .= qq(${key}: $data\n);
      }
    }
    print qq($all_data\n\n);
  } # while (my $entry = <IN>)
#   close (IN) or die "Cannot close $tempfile : $!";
#   $/ = "\n";
}

__END__

this works from a file, but not from a variable through get

# use IO::Uncompress::Bunzip2 qw(bunzip2 $Bunzip2Error);
use IO::Uncompress::Gunzip qw(gunzip $GunzipError);

# my $infile = 'test.gz';

$/ = undef;
open (IN, "<$infile") or die "Cannot open $infile : $!";
my $allfile = <IN>;

# my $z = new IO::Uncompress::Bunzip2 $allfile or die "bunzip2 failed: $Bunzip2Error\n";
my $z = new IO::Uncompress::Gunzip $allfile or die "gunzip failed: $GunzipError\n";

my $line = $z->getline();
print "$line\n";

# my $qwer = <$z>;
# print "$qwer\n";


__END__


# ftp://ftp.sanger.ac.uk/pub2/wormbase/STAFF/mh6/nightly_geneace/rearrangements.ace.gz

__END__

my %dead_in_pg;
my $result = $dbh->prepare( "SELECT * FROM gin_dead" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) { $dead_in_pg{$row[0]} = $row[1]; }

my %pg_syns; my %pg_locus;
$result = $dbh->prepare( "SELECT * FROM gin_synonyms" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) { $pg_syns{$row[0]}{$row[1]}++; }
$result = $dbh->prepare( "SELECT * FROM gin_locus" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) { $pg_locus{$row[0]} = $row[1]; }


# my $directory = '/home/azurebrd/public_html/sanger/gene_postgres';
my $directory = '/home/acedb/cron';
chdir($directory) or die "Cannot go to $directory ($!)";

my $start = &getSimpleSecDate();


my $ua = LWP::UserAgent->new;
# $ua->timeout(10);	# maybe this is causing timeout on cronjob
# $ua->env_proxy;

# my $response = $ua->get("http://www.sanger.ac.uk/tmp/Projects/C_elegans/LOCI/genes2molecularnamestest.txt");
# my $response = $ua->get("http://www.sanger.ac.uk/cgi-bin/Projects/C_elegans/nameserver_json.pl?domain=Gene");
my $url = "http://www.sanger.ac.uk/cgi-bin/Projects/C_elegans/nameserver_json.pl?domain=Gene";
my $request = HTTP::Request->new(GET => $url);	#grabs url
my $response = $ua->request($request);		#checks url, dies if not valid.

# my $response = $ua->get("http://tazendra.caltech.edu/~azurebrd/sanger/gene_postgres/nameserverGene");
my $sanger = '';
if ($response->is_success) { $sanger = $response->content; $sanger .= "\n"; }
  else { die $response->status_line; }

my @pgcommands; my %gene; 
my $nameserverGeneFile = $directory . '/nameserverGene.txt';
$/ = undef;
open (IN, "<$nameserverGeneFile") or die "Cannot open $nameserverGeneFile : $!";
my $lastFileContent = <IN>;
close (IN) or die "Cannot close $nameserverGeneFile : $!";
$/ = "\n";
if ($lastFileContent eq $sanger) { exit 1; }	# last downloaded file is the same, don't do anything

open (OUT, ">$nameserverGeneFile") or die "Cannot open $nameserverGeneFile : $!";
print OUT $sanger; 
close (OUT) or die "Cannot close $nameserverGeneFile : $!";
my (@entries) = split/\n   \],\n   \[\n/, $sanger;
foreach my $entry (@entries) {
  my ($gene, $type, $value, $dead) = $entry =~ m/\"([^\"]+)\"/g;
#   next if ($type eq 'Public_name');			# was skipping Public_name but some values need to be in gin_wbgene for the OA, so only adding to that and gin_dead 
  my ($joinkey) = $gene =~ m/WBGene(\d+)/;
  if ($type eq 'CGC') { $gene{$joinkey}{locus} = $value; }
  elsif ($type eq 'Sequence') { $gene{$joinkey}{seqname} = $value; }
  elsif ($type eq 'Public_name') { $gene{$joinkey}{wbgene} = $value; }	# store wbgene only, not name
  if ($dead == 0) {
    $gene{$joinkey}{dead} = 'Dead'; 
    if ( $dead_in_pg{$joinkey} ) { $gene{$joinkey}{dead} = $dead_in_pg{$joinkey}; } }
#   print "G $gene T $type V $value D $dead E\n";
} # foreach my $entry (@entries)

foreach my $joinkey (sort keys %gene) {
  push @pgcommands, "INSERT INTO gin_wbgene VALUES ('$joinkey', 'WBGene$joinkey')";
  if ($gene{$joinkey}{locus}) {
    if ($pg_locus{$joinkey}) {									# if there is an old locus value to transfer
      if ($pg_locus{$joinkey} ne $gene{$joinkey}{locus}) {		# if the old locus is different from the new locus
        unless ($pg_syns{$joinkey}{$pg_locus{$joinkey}}) {		# and the old locus is not already a synonym
          push @pgcommands, "INSERT INTO gin_synonyms VALUES ('$joinkey', '$pg_locus{$joinkey}')"; } } }	# add old locus to synonyms
    push @pgcommands, "INSERT INTO gin_locus VALUES ('$joinkey', '$gene{$joinkey}{locus}')"; }
  if ($gene{$joinkey}{seqname}) { 
    push @pgcommands, "INSERT INTO gin_seqname VALUES ('$joinkey', '$gene{$joinkey}{seqname}')"; }
  if ($gene{$joinkey}{dead}) { 
    push @pgcommands, "INSERT INTO gin_dead VALUES ('$joinkey', '$gene{$joinkey}{dead}')"; }
}

# foreach my $joinkey (sort keys %dead_in_ns) {
#   unless ($dead_in_pg{$joinkey}) { 
#     push @pgcommands, "INSERT INTO gin_dead VALUES ('$joinkey', '$dead_in_ns{$joinkey}')"; } }
# foreach my $joinkey (sort keys %dead_in_pg) {
#   unless ($dead_in_ns{$joinkey}) { 
#     push @pgcommands, "DELETE FROM gin_dead WHERE joinkey = '$joinkey' AND gin_dead = '$dead_in_pg{$joinkey}'"; } }

if (scalar(@pgcommands) > 1000) {	# since can't split whole file anymore, guessing that if there's 1000 entries, that it's a good set
  unshift @pgcommands, "DELETE FROM gin_wbgene";
  unshift @pgcommands, "DELETE FROM gin_locus";
  unshift @pgcommands, "DELETE FROM gin_seqname";
  unshift @pgcommands, "DELETE FROM gin_dead";
  foreach my $pgcommand (@pgcommands) {
#     print "$pgcommand\n";
# UNCOMMENT TO MAKE LIVE
    my $result = $dbh->do( $pgcommand );
  }
} else {
    my $user = 'populate_gin_locus.pl';
    my $email = 'vanauken@its.caltech.edu';
#     my $email = 'azurebrd@tazendra.caltech.edu';
    my $subject = 'didn\'t update nameserver Gene file because of small file size';
    my $body = "nameserver Gene file was not updated";
    &mailer($user, $email, $subject, $body);
}

__END__


G WBGene00023220 T Sequence V ZK994.t1 D 1 E
G WBGene00023221 T Sequence V ZK994.t2 D 1 E
G WBGene00023222 T Sequence V ZK994.t3 D 1 E
G WBGene00006987 T CGC V zmp-1 D 1 E
G WBGene00013683 T CGC V zoo-1 D 1 E



my (@text) = split/./, $sanger;
my $textsize = scalar(@text);
if ( ($textsize < 10000) || ($sanger =~ m/Error 404/) ) {
    my $user = 'populate_gin_locus.pl';
    my $email = 'vanauken@its.caltech.edu';
#     my $email = 'azurebrd@tazendra.caltech.edu';
    my $subject = 'didn\'t update sanger file because of small file size';
    if ($sanger =~ m/Error 404/) { $subject = 'didn\'t update sanger file because file was not found'; }
    my $body = "genes2molecular_names.txt only has $textsize characters";
    &mailer($user, $email, $subject, $body); }

  else {  
    my $outfile = $directory . '/genes2molecular_names.txt';
    open (OUT, ">$outfile") or die "Cannot open $outfile : $!";
    print OUT "$sanger\n"; 
    close (OUT) or die "Cannot close $outfile : $!";

    $outfile = $directory . '/old/sanger_genes2molecular_names.txt.' . $start;
    open (OUT, ">$outfile") or die "Cannot open $outfile : $!";
    print OUT "$sanger\n"; 
    close (OUT) or die "Cannot close $outfile : $!"; 

    $outfile = $directory . '/old/' . 'gin_locus.' . $start . '.pg';
    open (PG, ">$outfile") or die "Cannot create $outfile : $!";
    print PG "-- $start\n\n";

    my $result = $dbh->do( "DELETE FROM gin_locus;" );
    $result = $dbh->do( "DELETE FROM gin_wbgene;" );
    my (@lines) = split/\n/, $sanger;
    foreach my $line (@lines) {
      next unless $line;
      my ($wbg, $loc, $junk) = split/\t/, $line;
      unless ($loc) { print PG "ERR NO locus $line\n"; next; }
      my ($joinkey) = $wbg =~ m/(\d+)/;
      my $command = "INSERT INTO gin_wbgene VALUES ('$joinkey', '$wbg');";
      print PG "$command\n";
      my $result = $dbh->do( $command );
      if ($loc =~ m/\w{3,4}\-\d+/) {
        my $command = "INSERT INTO gin_locus VALUES ('$joinkey', '$loc');";
        print PG "$command\n";
        my $result = $dbh->do( $command );
      }
    } # foreach my $line (@lines)
    my $end = &getSimpleSecDate();
    print PG "\n-- $end\n";
    close (PG) or die "Cannot create $outfile : $!";
}

