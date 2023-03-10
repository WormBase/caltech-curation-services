#!/usr/bin/perl -w

# take out all data, move institution, email, and lab to old_, make comment and
# left field (if left field doesn't already exist).  2008 10 30

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my @pgcommands;
my %already_done;

# my $infile = 'set1';
my $infile = 'out';

open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) {
  if ($line =~ m/(two\d+)/) {
    my $two = $1;
    next if ($line =~ m/^PI/);
    next unless ($line =~ m/only has bad emails/);
    next unless ($line =~ m/doesn't have 2008 paper/);
    next if ($already_done{$two}); $already_done{$two}++;
    push @pgcommands, "DELETE FROM two_street WHERE joinkey = '$two';";
    push @pgcommands, "DELETE FROM two_state WHERE joinkey = '$two';";
    push @pgcommands, "DELETE FROM two_city WHERE joinkey = '$two';";
    push @pgcommands, "DELETE FROM two_country WHERE joinkey = '$two';";
    push @pgcommands, "DELETE FROM two_post WHERE joinkey = '$two';";
    push @pgcommands, "DELETE FROM two_mainphone WHERE joinkey = '$two';";
    push @pgcommands, "DELETE FROM two_labphone WHERE joinkey = '$two';";
    push @pgcommands, "DELETE FROM two_officephone WHERE joinkey = '$two';";
    push @pgcommands, "DELETE FROM two_otherphone WHERE joinkey = '$two';";
    push @pgcommands, "DELETE FROM two_fax WHERE joinkey = '$two';";
    push @pgcommands, "DELETE FROM two_webpage WHERE joinkey = '$two';";
    my $order = 0; my $result = $conn->exec( "SELECT * FROM two_old_institution WHERE joinkey = '$two' ORDER BY two_order DESC;");
    my @row = $result->fetchrow; if ($row[1]) { $order = $row[1]; } 
    $result = $conn->exec( "SELECT * FROM two_institution WHERE joinkey = '$two' ORDER BY two_order;" );
    while (my @row = $result->fetchrow) { 
      $order++; my $data = $row[2]; my $old_t = $row[3];
      push @pgcommands, "INSERT INTO two_old_institution VALUES ('$two', '$order', '$data', '$old_t')"; }
    push @pgcommands, "DELETE FROM two_institution WHERE joinkey = '$two';";
    $order = 0; $result = $conn->exec( "SELECT * FROM two_old_email WHERE joinkey = '$two' ORDER BY two_order DESC;");
    @row = $result->fetchrow; if ($row[1]) { $order = $row[1]; } 
    $result = $conn->exec( "SELECT * FROM two_email WHERE joinkey = '$two' ORDER BY two_order;" );
    while (my @row = $result->fetchrow) { 
      $order++; my $data = $row[2]; my $old_t = $row[3];
      push @pgcommands, "INSERT INTO two_old_email VALUES ('$two', '$order', '$data', '$old_t')"; }
    push @pgcommands, "DELETE FROM two_email WHERE joinkey = '$two';";
    $order = 0; $result = $conn->exec( "SELECT * FROM two_oldlab WHERE joinkey = '$two' ORDER BY two_order DESC;");
    @row = $result->fetchrow; if ($row[1]) { $order = $row[1]; } 
    $result = $conn->exec( "SELECT * FROM two_lab WHERE joinkey = '$two' ORDER BY two_order;" );
    while (my @row = $result->fetchrow) { 
      $order++; my $data = $row[2]; my $old_t = $row[3];
      push @pgcommands, "INSERT INTO two_oldlab VALUES ('$two', '$order', '$data', '$old_t')"; }
    push @pgcommands, "DELETE FROM two_lab WHERE joinkey = '$two';";
    $result = $conn->exec( "SELECT * FROM two_left_field WHERE joinkey = '$two';");
    @row = $result->fetchrow; 
    unless ($row[0]) { my $result2 = $conn->exec( "INSERT INTO two_left_field VALUES ('$two', '1', 'Left the field')" ); }
    push @pgcommands, "INSERT INTO two_comment VALUES ('$two', 'Bounced newsletter and apc October 2008')";
  } # if ($line =~ m/(two\d+)/)
} # while (my $line = <IN>)
close (IN) or die "Cannot close $infile : $!";

foreach my $pgcommand (@pgcommands) { 
  print "$pgcommand\n"; 
# UNCOMMENT TO exec
#   my $result = $conn->exec( $pgcommand ); 
}

__END__

my $result = $conn->exec( "SELECT * FROM two_comment WHERE two_comment ~ 'elegans';" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[1] =~ s///g;
    $row[2] =~ s///g;
    print "$row[0]\t$row[1]\t$row[2]\n";
  } # if ($row[0])
} # while (@row = $result->fetchrow)

__END__

