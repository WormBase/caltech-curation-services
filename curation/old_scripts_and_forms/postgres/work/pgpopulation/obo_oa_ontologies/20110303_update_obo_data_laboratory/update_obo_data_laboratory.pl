#!/usr/bin/perl -w

# add allele_code from  http://www.cbs.umn.edu/CGC/nomenclature/allele.html
# need manual representatives for new labs.  
# If running this script again manually in the future, take out the 4 / 6 lines 
# referring to the trp_location obo_ tables.
# Also in the future don't need to add allele_code, only need to add new labs.
# for Karen  2011 03 03
#
# ran live on tazendra.  2011 03 18


use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my %lab;
my $result = $dbh->prepare( "SELECT * FROM obo_data_laboratory " );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $lab{$row[0]} = $row[1]; }

my %lab_to_rep;
$lab_to_rep{MVG} = 'Marc Van Gilst';
$lab_to_rep{EVL} = 'Brian Ackley';
$lab_to_rep{SX} = 'Erik Miska';
$lab_to_rep{XE} = 'Marc Hammalund';

my @pgcommands;

my $infile = 'allele.txt';
open (IN, "$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) {
  chomp $line;
  next unless ($line);
  my ($lab, $allele, $address) = split/\t/, $line;
  if ($lab{$lab}) {				# COMMENT THIS OUT in the future, reprentatives have already been added
      my $data = $lab{$lab};
      if ($data =~ m/\'/) { $data =~ s/\'/''/g; }
      $data .= "\nallele_code: $allele";
      my $command = "DELETE FROM obo_data_laboratory WHERE joinkey = '$lab'";
      push @pgcommands, $command;
      $command = "INSERT INTO obo_data_laboratory VALUES ('$lab', '$data');";
      push @pgcommands, $command;
        # when new OA is live, get rid of the next 4 lines, they're for old tables
      $command = "DELETE FROM obo_data_trp_location WHERE joinkey = '$lab'";
      push @pgcommands, $command;
      $command = "INSERT INTO obo_data_trp_location VALUES ('$lab', '$data');";
      push @pgcommands, $command;
    }
    elsif ($lab_to_rep{$lab}) { &addNewLab($lab, $allele, $lab_to_rep{$lab}); }
    else { print "new lab $lab\n"; }
} # while (my $line = <IN>)
close (IN) or die "Cannot close $infile : $!";

foreach my $command (@pgcommands) {
  print "$command\n";
# UNCOMMENT TO RUN
#   my $result = $dbh->do( $command );
}

sub addNewLab {
  my ($lab, $allele, $rep) = @_;
  if ($rep =~ m/\'/) { $rep =~ s/\'/''/g; }
  my $data = "id: $lab\nRepresentatives: $rep\nallele_code: $allele";
  my $command = "INSERT INTO obo_name_laboratory VALUES ('$lab', '$lab');";
  push @pgcommands, $command;
  $command = "INSERT INTO obo_syn_laboratory VALUES ('$lab', '$rep');";
  push @pgcommands, $command;
  $command = "INSERT INTO obo_data_laboratory VALUES ('$lab', '$data');";
  push @pgcommands, $command;
    # when new OA is live, get rid of the next 6 lines, they're for old tables
  $command = "INSERT INTO obo_data_trp_location VALUES ('$lab', '$data');";
  push @pgcommands, $command;
  $command = "INSERT INTO obo_syn_trp_location VALUES ('$lab', '$rep');";
  push @pgcommands, $command;
  $command = "INSERT INTO obo_name_trp_location VALUES ('$lab', '$lab');";
  push @pgcommands, $command;
}

__END__

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

