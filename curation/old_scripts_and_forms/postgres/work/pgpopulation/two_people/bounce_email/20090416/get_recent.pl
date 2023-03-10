#!/usr/bin/perl -w

# just find which emails bounced (don't change yet)  2009 04 17

use strict;
use diagnostics;
use DBI;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "");
if ( !defined $dbh ) { die "Cannot connect to database!\n"; }


my %pgemails;
my %emails;
my $infile = 'bad_emails';


# my $result = $dbh->prepare( "SELECT * FROM two_comment WHERE two_comment ~ 'elegans';" );
my $result = $dbh->prepare( "SELECT * FROM two_email ;" );
if ( !defined $result ) { die "Cannot prepare statement: $DBI::errstr\n"; }
$result->execute;
while ( my @row = $result->fetchrow()) { $pgemails{$row[2]} = "$row[0]\t$row[1]"; }



# $pgemails{$row[2]} = "$row[0]\t$row[1]"; }

my %erase;
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) {
  my ($email) = $line =~ m/To: (.*)$/;
  $email =~ s/<//g;
  $email =~ s/>//g;
  $email =~ s/&lt;//g;
  $email =~ s/&gt;//g;
  next if ($email =~ m/pws\@/);
  $emails{$email}++;
  if ($pgemails{$email}) { $erase{$email}++; }
  else { print "ERR no match $email\n"; }
} # while (my $line = <IN>)
close (IN) or die "Cannot close $infile : $!";

foreach my $email (sort keys %erase) {
  print "$pgemails{$email}\t$email\n";
} # foreach my $email (sort keys %erase)


__END__

use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my %pgemails;
my %emails;
my $infile = 'bad_emails';

my $result = $conn->exec( "SELECT * FROM two_email ;" );
# while (my @row = $result->fetchrow) {
#   if ($row[0]) { 
#     $row[0] =~ s///g;
#     $row[1] =~ s///g;
#     $row[2] =~ s///g;
#     $pgemails{$row[2]} = "$row[0]\t$row[1]";
#   } # if ($row[0])
# } # while (@row = $result->fetchrow)

my %erase;
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) {
  my ($email) = $line =~ m/To: (.*)$/;
  $email =~ s/<//g;
  $email =~ s/>//g;
  $email =~ s/&lt;//g;
  $email =~ s/&gt;//g;
  next if ($email =~ m/pws\@/);
  $emails{$email}++;
  if ($pgemails{$email}) { $erase{$email}++; }
  else { print "ERR no match $email\n"; }
} # while (my $line = <IN>)
close (IN) or die "Cannot close $infile : $!";

foreach my $email (sort keys %erase) {
  print "$pgemails{$email}\t$email\n";
} # foreach my $email (sort keys %erase)


__END__

