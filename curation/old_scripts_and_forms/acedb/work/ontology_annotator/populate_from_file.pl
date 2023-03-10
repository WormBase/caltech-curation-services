#!/usr/bin/perl -w

# read in data for app_ gop_ and ptg_ tables.
# data must be tab-delimited
# first line must be headers 
# other lines can be commented out with a leading #
# headers must have the names of the tables they're entering data to
# only tables with headers will be populated (except for 
#   <datatype>_filereaddate and <datatype>_lastupdate)
# new pgdbID joinkeys are generated based off of last value of maintable
#   (gop_wbgene, ptg_goid, app_tempname)
# will check that all tables in the header have the same datatype 
#   (app_ / gop_ / ptg_ )
# data must be in the format that the postgres tables should hold things
#   data will always go in as it says in the file.
# for app_, if there's no app_filereaddate column, it will populate it based
#   on the run date in batches of 30 objectnames / second in the filereaddate
#   value.
# for ptg_ and gop_ if there's no <datatype>_lastupdate column, it will use
#   the current date (year-month-day)
# people need to be sure their date is in the correct format, so there's a 
#   prompt that they need to type ``yes'' for.   2009 11 17


use strict;
use diagnostics;
use DBI;
use Jex;


die "Need an inputfile ./populate_from_file.pl <inputfile>\n" unless $ARGV[0];


my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;
my @pgcommands;

my @tables;
my $datatype;

my %allowed_datatypes;
$allowed_datatypes{app}++;
$allowed_datatypes{gop}++;
$allowed_datatypes{ptg}++;

my $date = &getPgDate();
my $seconds = 0;
my $batch_count = 0;
my $batch_amount = 30;
my %objectname_date;
# print "D $date\n";

my $infile = $ARGV[0];
open (IN, $infile) or die "Cannot open $infile : $!";
my $headers = <IN>;
&processHeaders($headers);
if ($datatype eq 'gop') { processLastupdate('gop'); }
elsif ($datatype eq 'ptg') { processLastupdate('ptg'); }
elsif ($datatype eq 'app') { processApp(); }
close (IN) or die "Cannot close $infile : $!";

print "Are you sure the input file is in the correct format ? (yes / no)\n";
my $prompt_result = <STDIN>;
chomp ($prompt_result);
unless ($prompt_result eq 'yes') { die "Please check the input file's format\n"; }

foreach my $pgcommand (@pgcommands) {
  print "$pgcommand\n";
  next if ($pgcommand =~ m/DELETE FROM/i);
  next if ($pgcommand =~ m/DROP TABLE/i);
  next if ($pgcommand =~ m/DROP DATABASE/i);
  next if ($pgcommand =~ m/DROP INDEX/i);
  $result = $dbh->do( $pgcommand );
}


sub processLastupdate {
  my ($datatype) = @_;
  my $joinkey = 0;
  my $main_table = '';
  if ($datatype eq 'ptg') { $main_table = 'ptg_goid'; }
    elsif ($datatype eq 'gop') { $main_table = 'gop_wbgene'; }
    else { print "Not a valid datatype for &processLastupdate();\n"; return; }

  $result = $dbh->prepare( "SELECT CAST(joinkey AS integer) FROM $main_table ORDER BY joinkey DESC;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  my @row = $result->fetchrow(); $joinkey = $row[0];
  while (my $line = <IN>) {
    next if ($line =~ m/^#/);
    chomp $line;
    $line =~ s/\'/''/g;
    my $lastupdate = 0;
    if ($line =~ m/\S/) { $joinkey++; }
      else { print "Skipping blank line $line\n"; next; }
    my (@data) = split/\t/, $line;
    for (my $i = 0; $i < scalar(@data); $i++) {
      if ($data[$i]) {
        my $table = $tables[$i];
        if ($table =~ m/_lastupdate$/) { $lastupdate++; }
        push @pgcommands, "INSERT INTO $table VALUES ('$joinkey', '$data[$i]', CURRENT_TIMESTAMP)";
        push @pgcommands, "INSERT INTO ${table}_hst VALUES ('$joinkey', '$data[$i]', CURRENT_TIMESTAMP)";
      }
    }
    unless ($lastupdate) { 
      ($lastupdate) = $date =~ m/^(\d{4}\-\d{2}\-\d{2})/;
      push @pgcommands, "INSERT INTO ${datatype}_lastupdate VALUES ('$joinkey', '$lastupdate', CURRENT_TIMESTAMP)";
      push @pgcommands, "INSERT INTO ${datatype}_lastupdate_hst VALUES ('$joinkey', '$lastupdate', CURRENT_TIMESTAMP)";
    }
#     print "$line\n";
  }
} # sub processPtg

sub processApp {
  my $joinkey = 0;
  $result = $dbh->prepare( "SELECT CAST(joinkey AS integer) FROM app_tempname ORDER BY joinkey DESC;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  my @row = $result->fetchrow(); $joinkey = $row[0];
  while (my $line = <IN>) {
    next if ($line =~ m/^#/);
    chomp $line;
    $line =~ s/\'/''/g;
    my $filereaddate = 0;
    my $tempname = '';
    if ($line =~ m/\S/) { $joinkey++; }
      else { print "Skipping blank line $line\n"; next; }
    my (@data) = split/\t/, $line;
    for (my $i = 0; $i < scalar(@data); $i++) {
      if ($data[$i]) {
        my $table = $tables[$i];
        if ($table =~ m/_filereaddate$/) { $filereaddate++; }
        if ($table =~ m/_tempname$/) { $tempname = $data[$i]; }
        push @pgcommands, "INSERT INTO $table VALUES ('$joinkey', '$data[$i]', CURRENT_TIMESTAMP)";
        push @pgcommands, "INSERT INTO ${table}_hst VALUES ('$joinkey', '$data[$i]', CURRENT_TIMESTAMP)";
      }
    }
    unless ($filereaddate) { 
      if ($objectname_date{$tempname}) { $filereaddate = $objectname_date{$tempname}; }
        else { 
          ($filereaddate) = $date =~ m/^(\d{4}\-\d{2}\-\d{2} \d{2}:\d{2}:)/;
          $batch_count++; 
          if ($batch_count > $batch_amount) {
            $batch_count = 0; $seconds++; }
          my $padded_seconds = $seconds; if ($padded_seconds < 10) { $padded_seconds = '0' . $padded_seconds; }
          $filereaddate .= $padded_seconds;	# this will break down if there are more than $batch_amount * 60 different object names.
          $objectname_date{$tempname} = $filereaddate;
        }
      push @pgcommands, "INSERT INTO ${datatype}_filereaddate VALUES ('$joinkey', '$filereaddate', CURRENT_TIMESTAMP)";
      push @pgcommands, "INSERT INTO ${datatype}_filereaddate_hst VALUES ('$joinkey', '$filereaddate', CURRENT_TIMESTAMP)";
    }
#     print "$line\n";
  }
#   while (my $line = <IN>) {
#     chomp $line;
#     print "$line\n";
#   }
} # sub processApp

sub processHeaders {
  my ($headers) = @_;
  chomp $headers;
  @tables = split/\t/, $headers;
  my @bad_tables;
  foreach my $table (@tables) { push @bad_tables, &checkTable($table); }
  my $bad_tables = join", ", @bad_tables;
  if ($bad_tables) { die "Bad table names : $bad_tables\n"; }
}

sub checkTable {
  my $table = shift;
  my ($table_datatype) = $table =~ m/^(\w+?)_/;
  unless ($table_datatype) { return $table; }			# return tables without a datatype
  unless ($datatype) { $datatype = $table_datatype; }		# assign new datatype
  unless ($allowed_datatypes{$datatype}) { return $table; }	# only allow specific datatype to upload file data
  if ($datatype ne $table_datatype) { return $table; }		# return tables that don't match datatype (like an app_ followed by a gop_)
  $result = $dbh->prepare( "SELECT COUNT(*) FROM $table WHERE joinkey IS NOT NULL" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  my @row = $result->fetchrow();
#   unless ($row[0]) { print "BAD $row[0]\n"; return $table; } 	# this is unnecessary and will have zero if there are no values in a real table.  it's unnecessary because a select on a non-existant table will halt the program anyway.
  return;
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

__END__

my $result = $dbh->prepare( 'SELECT * FROM two_comment WHERE two_comment ~ ?' );
$result->execute('elegans') or die "Cannot prepare statement: $DBI::errstr\n"; 

$result->execute("doesn't") or die "Cannot prepare statement: $DBI::errstr\n"; 
my $var = "doesn't";
$result->execute($var) or die "Cannot prepare statement: $DBI::errstr\n"; 

my $result = $dbh->do( "DELETE FROM friend WHERE firstname = 'bl\"ah'" );
(also do for INSERT and UPDATE if don't have a variable to interpolate with ? )

can cache prepared SELECTs with $dbh->prepare_cached( &c. );

if ($result->rows == 0) { print "No names matched.\n\n"; }	# test if no return

$result->finish;	# allow reinitializing of statement handle (done with query)
$dbh->disconnect;	# disconnect from DB

http://209.85.173.132/search?q=cache:5CFTbTlhBGMJ:www.perl.com/pub/1999/10/DBI.html+dbi+prepare+execute&cd=4&hl=en&ct=clnk&gl=us

interval stuff : 
SELECT * FROM afp_passwd WHERE joinkey NOT IN (SELECT joinkey FROM afp_lasttouched) AND joinkey NOT IN (SELECT joinkey FROM cfp_curator) AND afp_timestamp < CURRENT_TIMESTAMP - interval '21 days' AND afp_timestamp > CURRENT_TIMESTAMP - interval '28 days';

casting stuff to substring on other types :
SELECT * FROM afp_passwd WHERE CAST (afp_timestamp AS TEXT) ~ '2009-05-14';
