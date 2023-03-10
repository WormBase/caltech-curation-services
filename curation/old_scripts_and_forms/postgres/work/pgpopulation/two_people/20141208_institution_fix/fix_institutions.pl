#!/usr/bin/perl -w

# fix institutions based on tab-delimited file of names before and after.  for Cecilia.
#
# live run on tazendra for first set 2014 12 13.  future sets will have an extra second column
# with two# from old institution matches.
#
# new set on tazendra.  2015 04 24
#
# new set on tazendra.  2015 06 12
#
# new set on tazendra.  2015 07 23
#
# new set on tazendra.  2015 09 24
#
# new set on tazendra.  2015 11 24
#
# new set on tazendra.  2016 02 09
#
# new set on tazendra.  2016 04 20
#
# new set on tazendra.  2016 06 22
#
# new set on tazendra.  2016 08 24
#
# new set on tazendra.  2016 10 21


use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %comment;
$result = $dbh->prepare( "SELECT * FROM two_comment ORDER BY two_order DESC;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  unless ($comment{$row[0]}) { $comment{$row[0]} = $row[1]; }
} # while (my @row = $result->fetchrow)


my @pgcommands;
my $infile = 'institutions.tsv.20161021';
# my $infile = 'institutions.tsv.20160824';
# my $infile = 'institutions.tsv.20160621';
# my $infile = 'institutions.tsv.20160420';
# my $infile = 'institutions.tsv.20160209';
# my $infile = 'institutions.tsv.20151124';
# my $infile = 'institutions.tsv.20150923';
# my $infile = 'institutions.tsv.20150723';
# my $infile = 'institutions.tsv.20150709';
# my $infile = 'institutions.tsv.20150612';
# my $infile = 'institutions.tsv.20150424';
# my $infile = 'institutions.tsv';
# my $infile = 'institutions2.tsv';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) {
  chomp $line;
  my ($twos, $old_twos, $before, $after) = split/\t/, $line;
  if ($after) { 
    next if ($before eq $after);			# some are already correct
#     print "CHANGE $before TO $after\n";
    my $pgbefore = $before; $pgbefore =~ s/\'/''/g;
    my $pgafter  = $after ; $pgafter  =~ s/\'/''/g;
    $result = $dbh->prepare( "SELECT * FROM two_institution WHERE two_institution = '$pgbefore'" );
#     print qq( "SELECT * FROM two_institution WHERE two_institution = '$pgbefore'" \n);
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) {
      my ($date) = $row[4] =~ m/^(\d{4}\-\d{2}\-\d{2} \d{2}:\d{2})/;
      push @pgcommands, qq(DELETE FROM two_institution WHERE joinkey = '$row[0]' AND two_order = '$row[1]' AND two_institution = '$pgbefore');
      push @pgcommands, qq(INSERT INTO two_institution   VALUES ('$row[0]', '$row[1]', '$pgafter', 'two1'));
      push @pgcommands, qq(INSERT INTO h_two_institution VALUES ('$row[0]', '$row[1]', '$pgafter', 'two1'));
      my $comment_order = 0;  if ($comment{$row[0]}) { $comment_order = $comment{$row[0]}; }
      $comment_order++; $comment{$row[0]} = $comment_order;
      push @pgcommands, qq(INSERT INTO two_comment   VALUES ('$row[0]', '$comment_order', 'inst $row[1]: $pgbefore | $date', 'two1'));
      push @pgcommands, qq(INSERT INTO h_two_comment VALUES ('$row[0]', '$comment_order', 'inst $row[1]: $pgbefore | $date', 'two1'));
    }
    $result = $dbh->prepare( "SELECT * FROM two_old_institution WHERE two_old_institution = '$pgbefore'" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) {
      my ($date) = $row[4] =~ m/^(\d{4}\-\d{2}\-\d{2} \d{2}:\d{2})/;
      push @pgcommands, qq(DELETE FROM two_old_institution WHERE joinkey = '$row[0]' AND two_order = '$row[1]' AND two_old_institution = '$pgbefore');
      push @pgcommands, qq(INSERT INTO two_old_institution VALUES ('$row[0]', '$row[1]', '$pgafter', 'two1'));
      push @pgcommands, qq(INSERT INTO h_two_old_institution VALUES ('$row[0]', '$row[1]', '$pgafter', 'two1'));
      my $comment_order = 0;  if ($comment{$row[0]}) { $comment_order = $comment{$row[0]}; }
      $comment_order++; $comment{$row[0]} = $comment_order;
      push @pgcommands, qq(INSERT INTO two_comment   VALUES ('$row[0]', '$comment_order', 'old_inst $row[1]: $pgbefore | $date', 'two1'));
      push @pgcommands, qq(INSERT INTO h_two_comment VALUES ('$row[0]', '$comment_order', 'old_inst $row[1]: $pgbefore | $date', 'two1'));
    }
  }
} # while (my $line = <IN>)
close (IN) or die "Cannot close $infile : $!";

foreach my $pgcommand (@pgcommands) {
  print "$pgcommand\n";
# UNCOMMENT TO FIX DATA
#   $dbh->do( $pgcommand );
} # foreach my $pgcommand (@pgcommands)

__END__

