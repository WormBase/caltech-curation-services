#!/usr/bin/perl 

use strict;
use diagnostics;
use LWP::UserAgent;
use DBI;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $ua = new LWP::UserAgent;

&updateVariationObo();




sub updateVariationObo {
  my %hash;

  my $jo_path = '/home/acedb/jolene/WS_AQL_queries/';

  my %junk_variation;		# junk variations are total variations minus latest set of real variations from Variation_gene.txt   These junk vars are excluded from going into obo_ when getting all values from nameserver.
  my $all_ws_variation_file = $jo_path . 'total_variations.txt';
  open(IN, "<$all_ws_variation_file") or die "Cannot open $all_ws_variation_file : $!";
  while (my $line = <IN>) {
    chomp $line;
    my ($junk) = $line =~ m/\"(.*?)\"\t/;
    $junk_variation{$junk}++;
  } # while (my $line = <IN>)
  close(IN) or die "Cannot open $all_ws_variation_file : $!";
  
# my $infile = 'Variation_gene.txt';
  my $infile = $jo_path . 'Variation_gene.txt';
  open (IN, "<$infile") or die "Cannot open $infile : $!";
# my $junk = <IN>;	# no longer expecting a junk line
  while (my $line = <IN>) {
    if ($line =~ m/\"(.*?)\"\t\"(WBGene\d+)\"\t\"(.*?)\"/) {
      my ($varid, $gene, $pub) = $line =~ m/\"(.*?)\"\t\"(WBGene\d+)\"\t\"(.*?)\"/;
      my $data = "$gene\t$pub";
      if ($junk_variation{$varid}) { delete $junk_variation{$varid}; }
      $hash{$varid}{allele}{$data}++; }
    elsif ($line =~ m/\"(.*?)\"/) { 
      if ($junk_variation{$1}) { delete $junk_variation{$1}; }
      $hash{$1}{allele}{blank}++; }
  } # while (my $line = <IN>)
  close (IN) or die "Cannot close $infile : $!";
  
#   foreach my $id (sort keys %junk_variation) { print "JUNK $id JUNK\n"; }
  
  
  my %var_data;			# to get name and dead when writing data
  my $url = 'http://www.sanger.ac.uk/cgi-bin/Projects/C_elegans/nameserver_json.pl?domain=Variation';
#   my $url = 'http://tazendra.caltech.edu/~azurebrd/var/work/nameserverVariation_temp';
  print "downloading from $url\n";
  my $request = HTTP::Request->new(GET => $url); #grabs url
  my $response = $ua->request($request);       #checks url, dies if not valid.
  unless ($response-> is_success) { print "nameserver not responding\n"; }
  my $variation_nameserver_file = $response->content;	# LWP::Simple fails for some reason

  $variation_nameserver_file =~ s/^\[\n\s+\[\n//s;
  $variation_nameserver_file =~ s/\n\s+\]\n\]//s;
  my @var_entries = split/\n\s+\],\n\s+\[\n\s+/, $variation_nameserver_file;
  foreach my $entry (@var_entries) {
    my (@lines) = split/\n/, $entry;
    my ($id) = $lines[0] =~ m/(WBVar\d+)/;
    next if ($junk_variation{$id});
    my ($name) = $lines[2] =~ m/\"(.*)\",/;
    my ($dead) = $lines[3] =~ m/\"([10])\"/;
    $var_data{$id}{name} = $name;
    $var_data{$id}{dead} = !$dead;
    $hash{$id}{allele}{""}++; 
  }
  
  $infile = $jo_path . 'transgene_summary.txt';
  open (IN, "<$infile") or die "Cannot open $infile : $!";
# my $junk = <IN>;	# no longer expecting a junk line
  while (my $line = <IN>) {
    if ($line =~ m/\"(.*?)\"\t\"(WBPaper\d+)\"\t\"(.*?)\"/) {
      my ($transgene, $paper, $summary) = $line =~ m/\"(.*?)\"\t\"(WBPaper\d+)\"\t\"(.*?)\"/;
#     my $data = "$gene\t$pub";
#     $hash{$transgene}{paper}{$paper}++;
      $hash{$transgene}{transgene}{$summary}++; }
    elsif ($line =~ m/\"(.*?)\"/) { $hash{$1}{transgene}{blank}++; }
  } # while (my $line = <IN>)
  close (IN) or die "Cannot close $infile : $!";

  $infile = $jo_path . 'rearr_simple.txt';
  open (IN, "<$infile") or die "Cannot open $infile : $!";
  # my $junk = <IN>;
  while (my $line = <IN>) {
    if ($line =~ m/\"(.*?)\"\t\"(.*?)\"/) {
#     my ($allele, $gene, $pub) = $line =~ m/\"(.*?)\"\t\"(WBGene\d+)\"\t\"(.*?)\"/;
      my ($rearrangement, $stuff) = $line =~ m/\"(.*?)\"\t\"(.*)\"/;
      $stuff =~ s/\"//g;
      $hash{$rearrangement}{rearrangement}{$stuff}++; }
    elsif ($line =~ m/\"(.*?)\"/) { $hash{$1}{rearrangement}{blank}++; }
  } # while (my $line = <IN>)
  close (IN) or die "Cannot close $infile : $!";


# uncomment this and the print OUT lines to make an .obo file
#   my $outfile = '/home/azurebrd/public_html/cgi-bin/forms/temp/var.obo';
#   open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
#   print OUT "default-namespace: wb_variation\n";
#   my $date = &getOboDate();
#   print OUT "date: $date\n\n";

  my @pgcommands;
  foreach my $object_id (sort keys %hash) { 
    my $id = $object_id;
    my $name = $object_id;
    if ($var_data{$object_id}{name}) { $name = $var_data{$object_id}{name}; }
#     print OUT "[Term]\nid: $id\n";
    my $data = "id: $id\n";
    $name =~ s/\\/\\\\/g;			# \ need to be escaped in name for some reason
#     print OUT "name: \"$name\"\n";
    $data .= "name: \"$name\"\n";
    if ($var_data{$object_id}{dead}) { 
#       print OUT "dead: \"dead\"\n"; 
      $data .= "dead: \"dead\"\n"; }
    foreach my $type (%{ $hash{$object_id} }) {
      foreach my $line (sort keys %{ $hash{$object_id}{$type} }) {
        if ($line) {
#           print OUT "$type: \"$line\" []\n";
          $data .= "$type: \"$line\" []"; } } }
#     print OUT "\n";
    my $pgcommand = "INSERT INTO obo_name_app_tempname VALUES ('$id', '$name', CURRENT_TIMESTAMP);";
    push @pgcommands, $pgcommand;
    if ($data =~ m/\'/) { $data =~ s/\'/''/g; }	# escape '
    if ($data =~ m/\\/) { 			# \ have to be escaped in E'' quote
        $data =~ s/\\/\\\\/g; 
        $data = "E'" . $data . "'"; }
      else { $data = "'" . $data . "'"; }
    $pgcommand = "INSERT INTO obo_data_app_tempname VALUES ('$id', $data, CURRENT_TIMESTAMP);";
    push @pgcommands, $pgcommand;
  } # foreach my $object_id (sort keys %hash) 
  
  if (scalar (@pgcommands > 1)) { 		# only wipe and repopulate if there's something to enter
    print "data parsed, writing to postgres\n";
    $dbh->do( "DELETE FROM obo_name_app_tempname;" );
    $dbh->do( "DELETE FROM obo_data_app_tempname;" );
    foreach my $pgcommand (@pgcommands) {
#       print "$pgcommand\n";
      $dbh->do( $pgcommand );
    } # foreach my $pgcommand (@pgcommands)
  }
#   close (OUT) or die "Cannot close $outfile : $!";

  print "Thanks for updating the variation / rearrangement / transgene OA autocomplete data based on four files in $jo_path and $url\n";
} # sub updateVariationObo

