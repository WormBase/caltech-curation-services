#!/usr/bin/perl -w

# make summary has only the stuff within square bracket.  stick all else into remark.
# found some things wrong with algorithm, sent ticket to Karen.
# for Karen  2011 03 04
#
# if summary has stuff for remark, change summary and remark tables.  had to E'' escape
# stuff, and also \\ as well as the usual ''.  ran on mangolassi   2011 03 08
#
# ran on tazendra.  2011 03 18


use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 


my @pgcommands;

my %remark;
my %summary;

my $result = $dbh->prepare( "SELECT * FROM trp_remark" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $remark{$row[0]} = $row[1]; }

$result = $dbh->prepare( "SELECT * FROM trp_summary ORDER BY joinkey::integer" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  next unless ($row[1] =~ m/^(\[.*?\])(.*?)$/);
  my $summary = $1;
  my $rest = $2;
  if ($rest =~ m/^[\. ]+/) { 
      $rest =~ s/^[\. ]+//; 
#       print "stripped $row[1]  TO  $rest\n"; 
    }
#     elsif ($rest) { print "NO STRIP $row[1]  TO  $rest\n"; }
#     else { print "NO CHANGE $row[1]\n"; }
  if ($rest) {
    my $remark = $remark{$row[0]};
    my @remarks;
    if ($remark) { (@remarks) = split/\|/, $remark; foreach (@remarks) { $_ =~ s/^\s+//; $_ =~ s/\s+$//; } }
    push @remarks, $rest;
    $remark = join" | ", @remarks;
#     ($rest) = &filterForPg($rest);
    ($summary) = &filterForPg($summary);
    ($remark) = &filterForPg($remark);
    
    push @pgcommands, "DELETE FROM trp_summary WHERE joinkey = '$row[0]';";
    push @pgcommands, "INSERT INTO trp_summary VALUES ('$row[0]', E'$summary');";
    push @pgcommands, "INSERT INTO trp_summary_hst VALUES ('$row[0]', E'$summary');";
    push @pgcommands, "DELETE FROM trp_remark WHERE joinkey = '$row[0]';";
    push @pgcommands, "INSERT INTO trp_remark VALUES ('$row[0]', E'$remark');";
    push @pgcommands, "INSERT INTO trp_remark_hst VALUES ('$row[0]', E'$remark');";
  }
}

foreach my $command (@pgcommands) {
  print "$command\n";
# UNCOMMENT TO delete from trp_location and insert NULLs into trp_location_hst
#   $result = $dbh->do( $command );
} # foreach my $command (@pgcommands)

sub filterForPg {
  my $val = shift;
  if ($val =~ m/\'/) { $val =~ s/\'/''/g; }
  if ($val =~ m/\\/) { $val =~ s/\\/\\\\/g; }
  return $val;
}

__END__
