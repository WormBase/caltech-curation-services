#!/usr/bin/perl

# Create new meeting people from parsed file made by Cecilia.  2009 08 25


use strict;
use diagnostics;
use DBI;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my %entries;

# my $infile = '/home/cecilia/work/IWM/iwm09forLito1';
my $infile = '/home/cecilia/work/IWM/iwm09forLito2';

my @types = qw( l m f standardname s c S p C i old_i e L aka_l aka_m aka_f aka_l2 aka_m2 aka_f2 aka_l3 aka_m3 aka_f3 aka_l4 aka_m4 aka_f4 );
my %types = (
  "l" => "lastname",
  "m" => "middlename",
  "f" => "firstname",
  "standardname" => "standardname", 
  "s" => "street",
  "c" => "city",
  "S" => "state",
  "p" => "post",
  "C" => "country",
  "i" => "institution",
  "old_i" => "old_institution",
  "e" => "email",
  "L" => "lab",
  "aka_l" => "aka_lastname",
  "aka_m" => "aka_middlename",
  "aka_f" => "aka_firstname",
  "aka_l2" => "aka_lastname2",
  "aka_m2" => "aka_middlename2",
  "aka_f2" => "aka_firstname2",
  "aka_l3" => "aka_lastname3",
  "aka_m3" => "aka_middlename3",
  "aka_f3" => "aka_firstname3",
  "aka_l4" => "aka_lastname4",
  "aka_m4" => "aka_middlename4",
  "aka_f4" => "aka_firstname4",
);


my @entries;
$/ = "";
open (IN, "<$infile") or die "Cannot open $infile : $!"; 
while (my $entry = <IN>) { if ($entry =~ m/^l:/) { push @entries, $entry; } }
close (IN) or die "Cannot close $infile : $!"; 
$/ = "\n";
shift (@entries);				# get rid of key entry
my $count = 0;
foreach my $entry (@entries) {
#   $count++; last if ($count > 10);
  my %data;
  my $cur_key = 'l';
  my (@lines) = split/\n/, $entry;
  foreach my $line (@lines) {
    if ($line =~ m/^([\w\_\d]+):\t(.*)/) { 
        $cur_key = $1; 
        if ($data{$cur_key}) { $data{$cur_key} .= "\n"; } 
        $data{$cur_key} .= $2; }
      else { 
        $line =~ s/^\t//; 
        if ($data{$cur_key}) { $data{$cur_key} .= "\n"; } 
        $data{$cur_key} .= $line; } }
  unless ($data{f}) { print "-- ERR NO FIRST $entry\n\n"; next; }
  unless ($data{l}) { print "-- ERR NO LAST $entry\n\n"; next; }
  if ($data{"m"}) { $data{standardname} = "$data{'f'} $data{'m'} $data{'l'}"; }
    else { $data{standardname} = "$data{f} $data{l}"; }

  my @commands;
  my $result = $dbh->prepare( "SELECT two FROM two ORDER BY two DESC;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  my @row = $result->fetchrow;
  my $joinkey = $row[0]; $joinkey++; 
  my $command = "INSERT INTO two VALUES ('two$joinkey', '$joinkey', CURRENT_TIMESTAMP);";
  push @commands, $command;
  foreach my $type (@types) {
    next unless ($data{$type});
    my $data = $data{$type}; 
    if ($data =~ m/'/) { $data =~ s/'/''/g; }		# filter ' for postgres
    my $table = $types{$type};
    print "-- $table\t$data\n";
    if ($table eq 'street') {				# strees have multilines in one
      my (@lines) = split/\n/, $data; 
      for (my $i = 0; $i < scalar(@lines); $i++) {
        my $order = $i + 1;
        my $command = "INSERT INTO two_$table VALUES ('two$joinkey', '$order', '$lines[$i]', CURRENT_TIMESTAMP);";
        push @commands, $command; } }
    elsif ($table =~ m/(aka_[\D]+)(\d)?/) {		# aka tables have order in their name
      $table = $1; my $order = '1'; if ($2) { $order = $2; }
#       unless ($data eq 'NULL') { $data = "'$data'"; }
      $data = "'$data'";				# thought I wanted NULL instead of 'NULL', but was wrong
      my $command = "INSERT INTO two_$table VALUES ('two$joinkey', '$order', $data, CURRENT_TIMESTAMP);";
      push @commands, $command; } 
    else {
      my $command = "INSERT INTO two_$table VALUES ('two$joinkey', '1', '$data', CURRENT_TIMESTAMP);";
      push @commands, $command; }
    delete $data{$type};
  }
  foreach my $type (sort keys %data) { 
    print "-- ERR Bad type $type : $entry\n\n";
  }
#   print "E $entry END\n";
  print "\n";
  foreach my $command (@commands) {
    print "$command\n";
# UNCOMMENT FOR DB
#     $result = $dbh->do( "$command;" );
  }
  print "\n";
}

__END__

#   unless ($entry =~ m/City:/) { print "E $entry E\n\n\n"; }
  my (@lines) = split/\n/, $entry;
  my ($fname, $mname, $lname);
  my $name = shift @lines;
  if ($name =~ m/^(\S+) (\S+) (\S+)$/) { $fname = $1; $mname = $2; $lname = $3; }
    elsif ($name =~ m/^(\S+) (\S+)$/) { $fname = $1; $lname = $2; }
    else { print "WEIRD NAME $name NAME\n"; }
  my @street; my $line = '';
  my ($city, $state, $post, $country);
  if ($entry =~ m/City:/) { 
      while ($line !~ m/City:/) { 
        $line = shift @lines; push @street, $line; }
      if ($line =~ m/^City: ([\.\-\w]+) (\w+) ([\_\-\w]+) ?$/) { $city = $1; $state = $2; $post = $3; }
        elsif ($line =~ m/^City: ([\.\-\w]+) ([\_\-\w]+) ?$/) { $city = $1; $post = $2; }
        else { print "WEIRD LINE $line LINE\n"; }
      $country = shift @lines; }
    else { print "WARNING $name doesn't have a city\n"; }
  my %aka;
  my ($phone, $fax, $email, $inst, $inst2, $lab, $webpage, $akaf, $akam, $akal, $comment);
  foreach my $line (@lines) {
    if ($line =~ m/Phone: (.*)/) { $phone = $1; }
    elsif ($line =~ m/Fax: (.*)/) { $fax = $1; }
    elsif ($line =~ m/Email: (.*)/) { $email = $1; }
    elsif ($line =~ m/Inst: (.*)/) { $inst = $1; }
    elsif ($line =~ m/Inst 1: (.*)/) { $inst = $1; }
    elsif ($line =~ m/Inst 2: (.*)/) { $inst2 = $1; }
    elsif ($line =~ m/[lL]ab: (.*)/) { $lab = $1; }
    elsif ($line =~ m/webpage: (.*)/) { $webpage = $1; }
    elsif ($line =~ m/two_aka_firstname: (.*)/) { $akaf = $1; $aka{f}{1} = $1; }
    elsif ($line =~ m/two_aka_middlename: (.*)/) { $akam = $1; $aka{m}{1} = $1; }
    elsif ($line =~ m/two_aka_lastname: (.*)/) { $akal = $1; $aka{l}{1} = $1; }
    elsif ($line =~ m/two_aka_firstname (\d+): (.*)/) { $akaf = $2; $aka{f}{$1} = $2; }
    elsif ($line =~ m/two_aka_middlename (\d+): (.*)/) { $akam = $2; $aka{m}{$1} = $2; }
    elsif ($line =~ m/two_aka_lastname (\d+): (.*)/) { $akal = $2; $aka{l}{$1} = $2; }
    elsif ($line =~ m/two_comment: (.*)/) { $comment = $1;}
    else { print "ERR $line NOT $entry VALID\n"; }
  } # foreach my $line (@lines)
  my $result = $conn->exec( "SELECT two FROM two ORDER BY two DESC;" );
  my @row = $result->fetchrow;
  my $joinkey = $row[0]; $joinkey++; 
  my $command = "INSERT INTO two VALUES ('two$joinkey', '$joinkey', CURRENT_TIMESTAMP);";
  print "$command\n"; 
# UNCOMMENT THIS TO RUN
#   $result = $conn->exec( $command );
  &putPg($joinkey, 'status', 'Valid');
  if ($name) { $name =~ s/_/ /g; &putPg($joinkey, 'standardname', $name); } 
  if ($fname) { $fname =~ s/_/ /g; &putPg($joinkey, 'firstname', $fname); }
  if ($mname) { $mname =~ s/_/ /g; &putPg($joinkey, 'middlename', $mname); }
  if ($lname) { $lname =~ s/_/ /g; &putPg($joinkey, 'lastname', $lname); }
  if ($street[0]) {
    pop @street;
    my $count = 0;
    foreach my $line (@street) { $count++;
      &putPg($joinkey, 'street', $line, $count); } }
  if ($city) { $city =~ s/_/ /g; &putPg($joinkey, 'city', $city); } 
  if ($state) { $state =~ s/_/ /g; &putPg($joinkey, 'state', $state); } 
  if ($post) { $post =~ s/_/ /g; &putPg($joinkey, 'post', $post); } 
  if ($country) { &putPg($joinkey, 'country', $country); } 
  if ($phone) { &putPg($joinkey, 'mainphone', $phone); } 
  if ($fax) { &putPg($joinkey, 'fax', $fax); } 
  if ($email) { &putPg($joinkey, 'email', $email); } 
  if ($inst) { &putPg($joinkey, 'institution', $inst); } 
  if ($inst2) { &putPg($joinkey, 'institution', $inst2, 2); } 
  if ($lab) { &putPg($joinkey, 'lab', $lab); } 
  if ($webpage) { &putPg($joinkey, 'webpage', $webpage); } 
  if ($akaf) { foreach my $order (sort keys %{ $aka{f}}) { my $akaf = $aka{f}{$order}; &putPg($joinkey, 'aka_firstname', $akaf, $order) } }
  if ($akam) { foreach my $order (sort keys %{ $aka{m}}) { my $akam = $aka{m}{$order}; &putPg($joinkey, 'aka_middlename', $akam, $order) } }
  if ($akal) { foreach my $order (sort keys %{ $aka{l}}) { my $akal = $aka{l}{$order}; &putPg($joinkey, 'aka_lastname', $akal, $order) } }
#   if ($akaf) { &putPg($joinkey, 'aka_firstname', $akaf); } 
#   if ($akam) { &putPg($joinkey, 'aka_middlename', $akam); } 
#   if ($akal) { &putPg($joinkey, 'aka_lastname', $akal); } 
  if ($comment) { &putPg($joinkey, 'comment', $comment); } 
  print "\n";
} # foreach my $entry (@entries)

sub putPg {
  my ($joinkey, $table, $value, $order) = @_;
  $joinkey = 'two' . $joinkey;
  unless ($order) { $order = 1; }
  $table = 'two_' . $table;
  my $command = "INSERT INTO $table VALUES ('$joinkey', '$order', '$value', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);";
  if ($table eq 'two_comment') { $command = "INSERT INTO $table VALUES ('$joinkey', '$value', CURRENT_TIMESTAMP );"; }
  print "$command\n";
# UNCOMMENT THIS TO RUN
#   my $result = $conn->exec( $command );
} # sub putPg


__END__ 

DELETE FROM two WHERE two_timestamp > '2009-08-26 16:35' AND two_timestamp < '2009-08-26 17:00';
DELETE FROM two_status WHERE two_timestamp > '2009-08-26 16:35' AND two_timestamp < '2009-08-26 17:00';
DELETE FROM two_standardname WHERE two_timestamp > '2009-08-26 16:35' AND two_timestamp < '2009-08-26 17:00';
DELETE FROM two_firstname WHERE two_timestamp > '2009-08-26 16:35' AND two_timestamp < '2009-08-26 17:00';
DELETE FROM two_lastname WHERE two_timestamp > '2009-08-26 16:35' AND two_timestamp < '2009-08-26 17:00';
DELETE FROM two_middlename WHERE two_timestamp > '2009-08-26 16:35' AND two_timestamp < '2009-08-26 17:00';
DELETE FROM two_street WHERE two_timestamp > '2009-08-26 16:35' AND two_timestamp < '2009-08-26 17:00';
DELETE FROM two_state WHERE two_timestamp > '2009-08-26 16:35' AND two_timestamp < '2009-08-26 17:00';
DELETE FROM two_city WHERE two_timestamp > '2009-08-26 16:35' AND two_timestamp < '2009-08-26 17:00';
DELETE FROM two_post WHERE two_timestamp > '2009-08-26 16:35' AND two_timestamp < '2009-08-26 17:00';
DELETE FROM two_country WHERE two_timestamp > '2009-08-26 16:35' AND two_timestamp < '2009-08-26 17:00';
DELETE FROM two_lab WHERE two_timestamp > '2009-08-26 16:35' AND two_timestamp < '2009-08-26 17:00';
DELETE FROM two_mainphone WHERE two_timestamp > '2009-08-26 16:35' AND two_timestamp < '2009-08-26 17:00';
DELETE FROM two_fax WHERE two_timestamp > '2009-08-26 16:35' AND two_timestamp < '2009-08-26 17:00';
DELETE FROM two_email WHERE two_timestamp > '2009-08-26 16:35' AND two_timestamp < '2009-08-26 17:00';
DELETE FROM two_institution WHERE two_timestamp > '2009-08-26 16:35' AND two_timestamp < '2009-08-26 17:00';
DELETE FROM two_webpage WHERE two_timestamp > '2009-08-26 16:35' AND two_timestamp < '2009-08-26 17:00';
DELETE FROM two_comment WHERE two_timestamp > '2009-08-26 16:35' AND two_timestamp < '2009-08-26 17:00';
DELETE FROM two_aka_firstname WHERE two_timestamp > '2009-08-26 16:35' AND two_timestamp < '2009-08-26 17:00';
DELETE FROM two_aka_lastname WHERE two_timestamp > '2009-08-26 16:35' AND two_timestamp < '2009-08-26 17:00';
DELETE FROM two_aka_middlename WHERE two_timestamp > '2009-08-26 16:35' AND two_timestamp < '2009-08-26 17:00';

my $result = $dbh->prepare( "SELECT * FROM two_comment WHERE two_comment ~ ?" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[1] =~ s///g;
    $row[2] =~ s///g;
    print "$row[0]\t$row[1]\t$row[2]\n";
  } # if ($row[0])
} # while (@row = $result->fetchrow)

__END__
