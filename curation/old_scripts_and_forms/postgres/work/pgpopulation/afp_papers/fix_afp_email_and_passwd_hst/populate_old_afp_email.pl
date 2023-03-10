#!/usr/bin/perl -w

# had forgotten to add some data to passwd_hst, email, and email_hst.  repopulating based on textpresso emails and afp_passwd data.  2009 05 15



use strict;
use diagnostics;
use DBI;
use Jex;

my %textpresso;
my $t_file = 'textpresso_emails';
open (IN, "$t_file") or die "Cannot open $t_file : $!";
while (my $line = <IN>) { chomp $line; my ($paper, $email) = split/\t/, $line; $textpresso{$paper} = $email; }
close (IN) or die "Cannot close $t_file : $!";

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %missing;

$result = $dbh->prepare( "SELECT * FROM afp_passwd_hst ORDER BY afp_timestamp");
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $missing{"afp_passwd_hst"}{$row[0]} = @row; }

$result = $dbh->prepare( "SELECT * FROM afp_email ORDER BY afp_timestamp");
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $missing{"afp_email"}{$row[0]} = @row; }

$result = $dbh->prepare( "SELECT * FROM afp_email_hst ORDER BY afp_timestamp");
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $missing{"afp_email_hst"}{$row[0]} = @row; }

$result = $dbh->prepare( "SELECT * FROM afp_passwd ORDER BY afp_timestamp");
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { 
  unless ($missing{"afp_passwd_hst"}{$row[0]}) {
    if ($row[3]) { $row[3] = "'$row[3]'"; } else { $row[3] = 'NULL'; }
    if ($row[4]) { $row[4] = "'$row[4]'"; } else { $row[4] = 'NULL'; }
    if ($row[5]) { $row[5] = "'$row[5]'"; } else { $row[5] = 'NULL'; }
    next unless ($row[1]);
    my $command = "INSERT INTO afp_passwd_hst VALUES ('$row[0]', '$row[1]', '$row[2]', $row[3], $row[4], $row[5]);";
    my $result2 = $dbh->do( $command );
    print "$command\n"; }
  unless ($missing{"afp_email"}{$row[0]}) {
    next unless ($textpresso{$row[0]});
    my $command = "INSERT INTO afp_email VALUES ('$row[0]', '$textpresso{$row[0]}', '$row[2]');";
    my $result2 = $dbh->do( $command );
    print "$command\n"; }
  unless ($missing{"afp_email_hst"}{$row[0]}) {
    next unless ($textpresso{$row[0]});
    my $command = "INSERT INTO afp_email_hst VALUES ('$row[0]', '$textpresso{$row[0]}', '$row[2]');";
    my $result2 = $dbh->do( $command );
    print "$command\n"; }
}
