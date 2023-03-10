#!/usr/bin/perl


# seems out of use
# -rwxr-xr-x  1 postgres postgres   8201 Nov  7 12:11 parse.pl*
# loci_all.txt no longer updated, probably not working as it should.  2006 12 15






# Parse East Asia Worm Meeting 2006 abstracts into postgres  2006 11 07

use strict;
use Pg;
use LWP::UserAgent;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

&getLoci;
my %cdsToGene;

my %hash;

my $infile = 'eawm2008.txt';
my $id = 0;
open (IN, "<$infile") or die "Cannot open $infile : $!";
<IN>;
while (my $line = <IN>) {
  chomp $line;
  my ($num, $first_mid, $last_name, $institution, $address, $zip, $country, $phone, $extension, $fax, $email, $first_mid_PI, $last_PI, $type, $inst1, $inst2, $inst3, $inst4, $first_mid_A1, $last_A1, $inst_A1, $first_mid_A2, $last_A2, $inst_A2, $first_mid_A3, $last_A3, $inst_A3, $first_mid_A4, $last_A4, $inst_A4, $first_mid_A5, $last_A5, $inst_A5, $first_mid_A6, $last_A6, $inst_A6, $first_mid_A7, $last_A7, $inst_A7, $first_mid_A8, $last_A8, $inst_A8, $first_mid_A9, $last_A9, $inst_A9, $title, $abstract) = split/\t/, $line;
  my @line = split/\t/, $line;
  my $num = shift @line;
  my ($first_mid) = shift @line;
  my ($last) = shift @line;
  my ($institution) = shift @line;
  my ($address) = shift @line;
  my ($zip) = shift @line;
  my ($country) = shift @line;
  my ($phone) = shift @line;
  my ($ext) = shift @line;
  my ($fax) = shift @line;
  my ($email) = shift @line;
  my ($first_mid_PI) = shift @line;
  my ($last_PI) = shift @line;
  my ($type) = shift @line;
  my $i = 0;
  for (1 .. 4) {
    $i++;
    $hash{inst_loc}{$i} = shift @line; }
  $i = 0;
  for (1 .. 9) {
    $i++;
    $hash{ppl}{$i}{first} = shift @line;
    $hash{ppl}{$i}{last} = shift @line;
    $hash{ppl}{$i}{inst} = shift @line; }
#   $i = 0;
#   for (1 .. 8) {
#     $i++;
#     $hash{inst_loc}{$i} = shift @line; }
#   for (1 .. 10) { shift @line; }
  my $title = shift @line;
  my $abs = shift @line;

# if ($title) { print "TITLE $title TITLE\n"; }
  unless ($title) { print "NO TITLE\n"; }
  next unless ($title);
  my $result = $conn->exec( "SELECT * FROM wpa ORDER BY joinkey DESC;" );
  my @row = $result->fetchrow;
  my $wpa = $row[0] + 1; 
  my $joinkey = &padZeros($wpa);
  my $pg_command = "INSERT INTO wpa VALUES ('$joinkey', '$wpa', NULL, 'valid', 'two1823', CURRENT_TIMESTAMP);";
#   $result = $conn->exec( $pg_command );
  print "$pg_command\n"; 
  $pg_command = "INSERT INTO wpa_type VALUES ('$joinkey', '3', NULL, 'valid', 'two1823', CURRENT_TIMESTAMP);";
#   $result = $conn->exec( $pg_command );
  print "$pg_command\n"; 
  $id++;
  my $identifier = 'eawm2006ab' . $id;
  $pg_command = "INSERT INTO wpa_identifier VALUES ('$joinkey', '$identifier', NULL, 'valid', 'two1823', CURRENT_TIMESTAMP);";
#   $result = $conn->exec( $pg_command );
  print "$pg_command\n"; 
  if ($title) { 
#     print "$title\n"; 
    if ($title =~ m/\<.*?\>/) { $title =~ s/\<.*?\>//g; }
    $pg_command = "INSERT INTO wpa_title VALUES ('$joinkey', '$title', NULL, 'valid', 'two1823', CURRENT_TIMESTAMP);";
#     $result = $conn->exec( $pg_command );
    print "$pg_command\n"; }
  if ($abs) { 
#     print "$abs\n"; 
    if ($abs =~ m/\n/) { $abs =~ s/\n/ /g; }
    if ($abs =~ m/\s+$/) { $abs =~ s/\s+$//; }
    if ($abs =~ m/\s+/) { $abs =~ s/\s+/ /g; }
    if ($abs =~ m/\<.*?\>/) { $abs =~ s/\<.*?\>//g; }
    &parseGenes('two1823', $joinkey, $abs);
    if ($abs =~ m/\'/) { $abs =~ s/\'/''/g; } 
    $pg_command = "INSERT INTO wpa_abstract VALUES ('$joinkey', '$abs', NULL, 'valid', 'two1823', CURRENT_TIMESTAMP);";
#     $result = $conn->exec( $pg_command );
    print "$pg_command\n"; }
  
  my $auth_joinkey = 0; my $author_rank = 0;
  $result = $conn->exec( "SELECT author_id FROM wpa_author_index ORDER BY author_id DESC;");
  @row = $result->fetchrow; my $auth_joinkey = $row[0];       # get highest author_id
  foreach my $i (sort {$a <=> $b} keys %{ $hash{ppl} }) {
    my $author = '';
    my $first = $hash{ppl}{$i}{first};
    my $last = $hash{ppl}{$i}{last};
    my $inum = $hash{ppl}{$i}{inst};
    $inum =~ s/\"//g;
    my $inst = '';
    if ($hash{inst_loc}{$inum}) { $inst = $hash{inst_loc}{$inum} }
      else { if ($inum =~ m/,/) { my @nums = split/,/, $inum; foreach my $num (@nums) { if ($hash{inst_loc}{$num}) { $inst .= "$hash{inst_loc}{$num}, "; } } $inst =~ s/,\s+$//g; } }
    if ($first) {
      $author = "$first $last";
      $author =~ s/\s+/ /g;
      if ($inst =~ m/^\s+/) { $inst =~ s/^\s+//g; }
      if ($inst =~ m/^"/) { $inst =~ s/^"//g; }
      if ($inst =~ m/"$/) { $inst =~ s/"$//g; }
#       print "$author\t$inst\n"; 
      $auth_joinkey++; $author_rank++;
      if ($author =~ m/\'/) { $author =~ s/\'/''/g; }
      my $result = $conn->exec( "SELECT author_id FROM wpa_author_index ORDER BY author_id DESC;");
#       $result = $conn->exec( "INSERT INTO wpa_author_index VALUES ('$auth_joinkey', '$author', '$inst', 'valid', 'two1823', CURRENT_TIMESTAMP);");
      print "INSERT INTO wpa_author_index VALUES ('$auth_joinkey', '$author', '$inst', 'valid', 'two1823', CURRENT_TIMESTAMP);\n";
#       $result = $conn->exec( "INSERT INTO wpa_author VALUES ('$joinkey', '$auth_joinkey', $author_rank, 'valid', 'two1823', CURRENT_TIMESTAMP);");
      print "INSERT INTO wpa_author VALUES ('$joinkey', '$auth_joinkey', $author_rank, 'valid', 'two1823', CURRENT_TIMESTAMP);\n";
    }
  } # foreach my $i (sort {$a <=> $b} keys %{ $hash{ppl} })
  print "\n";
} # while (my $line = <IN>)
close (IN) or die "Cannot close $infile : $!";




sub padZeros {
  my $joinkey = shift;
  if ($joinkey < 10) { $joinkey = '0000000' . $joinkey; }
  elsif ($joinkey < 100) { $joinkey = '000000' . $joinkey; }
  elsif ($joinkey < 1000) { $joinkey = '00000' . $joinkey; }
  elsif ($joinkey < 10000) { $joinkey = '0000' . $joinkey; }
  elsif ($joinkey < 100000) { $joinkey = '000' . $joinkey; }
  elsif ($joinkey < 1000000) { $joinkey = '00' . $joinkey; }
  elsif ($joinkey < 10000000) { $joinkey = '0' . $joinkey; }
  return $joinkey;
} # sub padZeros

sub parseGenes {
  my ($two_number, $joinkey, $abstract) = @_; 
  if ($abstract =~ m/,/) { $abstract =~ s/,//g; }
  if ($abstract =~ m/\(/) { $abstract =~ s/\(//g; }
  if ($abstract =~ m/\)/) { $abstract =~ s/\)//g; }
  if ($abstract =~ m/;/) { $abstract =~ s/;//g; }
  my %filtered_loci;
  my (@words) = split/\s+/, $abstract;

  foreach my $word (@words) {
    if ($cdsToGene{locus}{$word}) { $filtered_loci{$word}++; } }
  foreach my $word (sort keys %filtered_loci) { 
    my %filtered_gene;
    foreach my $wbgene (@{ $cdsToGene{locus}{$word} }) {    # each possible wbgene that matches that word
      $filtered_gene{$wbgene}++ }
    foreach my $wbgene (sort keys %filtered_gene) {
      my $evidence = "'Inferred_automatically\t\"Abstract read $word\"'"; 
      my $pm_value = $wbgene . "($word)";                      # wbgene(word)
      if ($pm_value =~ m/\'/) { $pm_value =~ s/\'/''/g; }
      my $pg_command = "INSERT INTO wpa_gene VALUES ('$joinkey', '$pm_value', $evidence, 'valid', 'two1823', CURRENT_TIMESTAMP);";
#       my $result = $conn->exec( $pg_command );
      print "$pg_command\n";
  } }
} # sub parseGenes

sub getLoci {                   # updated to use full list of words that could match multiple wbgenes in @{ %cdsToGene{locus}{word} }, wbgenes  2006 06 08
#   my $u = "http://tazendra.caltech.edu/~azurebrd/sanger/loci_all.txt";
#   my $ua = LWP::UserAgent->new(timeout => 30); #instantiates a new user agent
#   my $request = HTTP::Request->new(GET => $u); #grabs url
#   my $response = $ua->request($request);       #checks url, dies if not valid.
#   die "Error while getting ", $response->request->uri," -- ",
#   $response->status_line, "\nAborting" unless $response-> is_success;
#   my @tmp = split /\n/, $response->content;    #splits by line
#   foreach my $line (@tmp) {
#     my ($three, $wb, $useful) = $line =~ m/^(.*?),(.*?),.*?,(.*?),/;      # added to convert genes
#     if ($useful) {
#       $useful =~ s/\([^\)]*\)//g;
#       if ($useful =~ m/\s+$/) { $useful =~ s/\s+$//g; }
#       my (@cds) = split/\s+/, $useful;
#       push @{ $cdsToGene{locus}{$three} }, $wb;         # push 3-letter into array
#       if ($line =~ m/,([^,]*?) ,approved$/) {            # 2005 06 08
#         my @things = split/ /, $1;
#         foreach my $thing (@things) {
#           if ($thing =~ m/[a-zA-Z][a-zA-Z][a-zA-Z]\-\d+/) {
#             push @{ $cdsToGene{locus}{$thing} }, $wb; } } }     # still called locus but really any of multiple things
#   } }
#   $u = "http://tazendra.caltech.edu/~azurebrd/sanger/wbgenes_to_words.txt";
#   $ua = LWP::UserAgent->new(timeout => 30); #instantiates a new user agent
#   $request = HTTP::Request->new(GET => $u); #grabs url
#   $response = $ua->request($request);       #checks url, dies if not valid.
#   die "Error while getting ", $response->request->uri," -- ",
#   $response->status_line, "\nAborting" unless $response-> is_success;
#   @tmp = split /\n/, $response->content;    #splits by line
#   foreach my $line (@tmp) {
#     next unless($line);
#     my ($gene, $other) = split/\t/, $line;
#     push @{ $cdsToGene{locus}{$other} }, $gene; }
  my $result = $conn->exec( "SELECT * FROM gin_locus;" );
  while (my @row = $result->fetchrow) { push @{ $cdsToGene{locus}{$row[1]} }, "WBGene$row[0]"; }
  $result = $conn->exec( "SELECT * FROM gin_synonyms WHERE gin_syntype = 'locus';" );
  while (my @row = $result->fetchrow) { push @{ $cdsToGene{locus}{$row[1]} }, "WBGene$row[0]"; }
  if ($cdsToGene{locus}{run}) { delete $cdsToGene{locus}{run}; }        # Andrei's exclusion list 2006 07 15
  if ($cdsToGene{locus}{SC}) { delete $cdsToGene{locus}{SC}; }
  if ($cdsToGene{locus}{GATA}) { delete $cdsToGene{locus}{GATA}; }
  if ($cdsToGene{locus}{eT1}) { delete $cdsToGene{locus}{eT1}; }
  if ($cdsToGene{locus}{RhoA}) { delete $cdsToGene{locus}{RhoA}; }
  if ($cdsToGene{locus}{TBP}) { delete $cdsToGene{locus}{TBP}; }
  if ($cdsToGene{locus}{syn}) { delete $cdsToGene{locus}{syn}; }
  if ($cdsToGene{locus}{TRAP240}) { delete $cdsToGene{locus}{TRAP240}; }
  if ($cdsToGene{locus}{'AP-1'}) { delete $cdsToGene{locus}{'AP-1'}; }
} # sub getLoci

__END__

DELETE FROM wpa WHERE wpa_curator = 'two1823' AND wpa_timestamp > '2008-04-22 15:52';
DELETE FROM wpa_type WHERE wpa_curator = 'two1823' AND wpa_timestamp > '2008-04-22 15:52';
DELETE FROM wpa_identifier WHERE wpa_curator = 'two1823' AND wpa_timestamp > '2008-04-22 15:52';
DELETE FROM wpa_title WHERE wpa_curator = 'two1823' AND wpa_timestamp > '2008-04-22 15:52';
DELETE FROM wpa_abstract WHERE wpa_curator = 'two1823' AND wpa_timestamp > '2008-04-22 15:52';
DELETE FROM wpa_author WHERE wpa_curator = 'two1823' AND wpa_timestamp > '2008-04-22 15:52';
DELETE FROM wpa_author_index WHERE wpa_curator = 'two1823' AND wpa_timestamp > '2008-04-22 15:52';
DELETE FROM wpa_gene WHERE wpa_curator = 'two1823' AND wpa_timestamp > '2008-04-22 15:52';
