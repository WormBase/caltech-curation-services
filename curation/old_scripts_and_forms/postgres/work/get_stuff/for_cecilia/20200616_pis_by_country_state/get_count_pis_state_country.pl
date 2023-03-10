#!/usr/bin/perl -w

# query for pis with alphabetic labs.  get their location as their country if not US, and their state if US.
# check that if multiple PIs in a lab, they're in the same location.  Output count of PIs/Labs in each
# country / state.  Limit to PIs that have a verified paper in the last 5 years.  2020 06 16



use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %verified; my %possible; my %recent; my %pis;

my %labs;
$result = $dbh->prepare( "SELECT * FROM two_pis WHERE two_pis ~ '[A-Z]'" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $labs{$row[2]}{$row[0]}++; $pis{$row[0]} = $row[2]; }
} # while (@row = $result->fetchrow)

my %name;
$result = $dbh->prepare( "SELECT * FROM two_standardname" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $name{$row[0]} = $row[2]; }
} # while (@row = $result->fetchrow)

my %inst;
$result = $dbh->prepare( "SELECT * FROM two_institution WHERE two_order = '1'" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $inst{$row[0]} = $row[2]; }
} # while (@row = $result->fetchrow)

my %state;
$result = $dbh->prepare( "SELECT * FROM two_state WHERE two_order = '1'" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $state{$row[0]} = $row[2]; }
} # while (@row = $result->fetchrow)

my %country;
$result = $dbh->prepare( "SELECT * FROM two_country WHERE two_order = '1'" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $country{$row[0]} = $row[2]; }
} # while (@row = $result->fetchrow)




# Uncomment to get institutions that match hbcu and hsi lists
#
# my %hbcu;
# my $hbcu = 'hbcu';
# open (IN, "<$hbcu") or die "Cannot open $hbcu : $!";
# while (my $inst = <IN>) {
#   chomp $inst;
#   my $orig_inst = $inst;
#   $inst =~ s/\*//g;
#   $inst =~ s/\s+$//;
#   $inst =~ s/\'/''/;
#   $result = $dbh->prepare( "SELECT * FROM two_institution WHERE two_institution ~ '$inst'" );
#   $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
#   while (my @row = $result->fetchrow) {
#     if ($pis{$row[0]}) {
#       $hbcu{$row[0]} = $row[2];
#       my $wbperson = $row[0]; $wbperson =~ s/two/WBPerson/;
#       print qq(hbcu\t$wbperson\t$name{$row[0]}\t$orig_inst\t$row[2]\n);
#     }
#   }
# } # while (my $line = <IN>)
# close (IN) or die "Cannot close $hbcu : $!";
# 
# my %hsi;
# my $hsi = 'hsi';
# open (IN, "<$hsi") or die "Cannot open $hsi : $!";
# while (my $inst = <IN>) {
#   chomp $inst;
#   my $orig_inst = $inst;
#   $inst =~ s/\*//g;
#   $inst =~ s/\s+$//;
#   $inst =~ s/\'/''/;
#   next unless ($inst =~ m/ /);	# skip one work institutions, which are probably a state
#   next if ($inst eq 'District of Columbia');
#   next if ($inst eq 'New Jersey');
#   next if ($inst eq 'New Mexico');
#   next if ($inst eq 'New York');
#   $result = $dbh->prepare( "SELECT * FROM two_institution WHERE two_institution ~ '$inst'" );
#   $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
#   while (my @row = $result->fetchrow) {
#     if ($pis{$row[0]}) {
#       $hsi{$row[0]} = $row[2];
#       my $wbperson = $row[0]; $wbperson =~ s/two/WBPerson/;
#       print qq(hsi\t$wbperson\t$name{$row[0]}\t$orig_inst\t$row[2]\n);
#     }
#   }
# } # while (my $line = <IN>)
# close (IN) or die "Cannot close $hsi : $!";


$result = $dbh->prepare( "SELECT * FROM pap_author_possible");
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  $possible{$row[0]}{$row[2]} = $row[1]; }

$result = $dbh->prepare( "SELECT * FROM pap_author_verified WHERE pap_author_verified ~ 'YES' AND pap_timestamp >  now() - interval '5 years';");
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  $verified{$row[0]}{$row[2]}++; 
  if ($possible{$row[0]}{$row[2]}) { 
    my $person = $possible{$row[0]}{$row[2]};
    if ($pis{$person}) {
      $recent{$person}++; 
    }
  } # if ($possible{$row[0]}{$row[2]})
}


# Uncomment to output PIs and labs that have verified papers in the last 5 years, with lab, country, institution
# foreach my $lab (sort keys %labs) {
#   foreach my $two (sort keys %{ $labs{$lab} }) {
#     next unless ($recent{$two});
#     my $institution = $inst{$two};
#     my $wbperson = $two; $wbperson =~ s/two/WBPerson/;
#     my $name = $name{$two};
#     my $country = $country{$two};
#     my $state = $state{$two};
#     print qq($wbperson\t$name\t$lab\t$country\t$state\t$institution\n);
# } }


# Uncomment to output PIs and labs that have verified papers in the last 5 years, sorted by verfied publication
# foreach my $recent (sort { $recent{$b} <=> $recent{$a} } keys %recent) {
#   my $wbperson = $recent; $wbperson =~ s/two/WBPerson/;
#   print qq($pis{$recent}\t$wbperson\t$name{$recent}\t$recent{$recent}\n);
# } # foreach my $recent (sort keys %recent)


my $count = 0;
my %state;
my %country;

foreach my $lab (sort keys %labs) {
  my %location;
  foreach my $two (sort keys %{ $labs{$lab} }) {
    next unless ($recent{$two});
    $result = $dbh->prepare( "SELECT * FROM two_country WHERE joinkey = '$two' AND two_order = 1" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    my @row = $result->fetchrow();
    if ($row[2]) { 
      if ($row[2] !~ m/United States/) { $location{$row[2]}++; $country{$row[2]}++; }
        else {
          $result = $dbh->prepare( "SELECT * FROM two_state WHERE joinkey = '$two' AND two_order = 1" );
          $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
          @row = $result->fetchrow();
          if ($row[2]) { $location{$row[2]}++; $state{$row[2]}++; } } }
    $count++;
#     last if ($count > 100);
  } # foreach my $two (sort keys %{ $labs{$lab} })
  my @location = sort keys %location;
  my $location = join", ", @location;
  my @pis = sort keys %{ $labs{$lab} };
  my $pis = join", ", @pis;
  if (scalar @location > 1) { print qq($lab has multiple PIs $pis at $location\n); }
} # foreach my $lab (sort keys %labs)

foreach my $country (sort keys %country) {
  print qq($country\t$country{$country}\n);
} 
foreach my $state (sort keys %state) {
  print qq($state\t$state{$state}\n);
} 

__END__
