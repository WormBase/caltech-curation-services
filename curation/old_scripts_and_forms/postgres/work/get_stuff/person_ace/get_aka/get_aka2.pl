#!/usr/bin/perl -w

# create .ace file of potential first names, middle names, and last names
# including initials, but excluding dots and commas, and replacing 
# underscores with spaces.  2003 03 21
# this gives the desired result, but it takes too long (15 seconds) due to
# multiple queries to get the exact joinkey rather than querying all six
# tables and outputting once.  2003 03 21

use strict;
use diagnostics;
use Pg;
use Jex;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $result;

$result = $conn->exec( "SELECT * FROM two ORDER BY two DESC;" );
my @row = $result->fetchrow;
my $highest_two_val = $row[1];

# my $highest_two_val = '3000';
my $lowest_two_val = '0';

my $date = &getPgDate();
print "DATE $date\n";
for (my $i = $lowest_two_val; $i < $highest_two_val; $i++) {
  my $joinkey = 'two' . $i;
    # added two IS NOT NULL because there are three people that do not want to be displayed
  $result = $conn->exec( "SELECT * FROM two WHERE joinkey = '$joinkey' AND two IS NOT NULL;" );
  while ( my @row = $result->fetchrow ) {
    if ($row[2]) { 				# if two exists
      print "Person\tWBPerson$i -O \"$row[2]\"\n"; 
      &akaPrint($joinkey);
      print "\n";  				# divider between Persons
    }
  }
} # for (my $i = 0; $i < $highest_two_val; $i++)
$date = &getPgDate();
print "DATE $date\n";

sub akaPrint {
  my $joinkey = shift;
  my @row;
  my %aka_hash;
  my @tables = qw (first middle last);
  foreach my $table (@tables) { 
    $result = $conn->exec ( "SELECT * FROM two_aka_${table}name WHERE joinkey = '$joinkey' AND two_aka_${table}name IS NOT NULL AND two_aka_${table}name != 'NULL' AND two_aka_${table}name != '';" );
    while ( @row = $result->fetchrow ) {
      if ($row[3]) { 					# if there's a time
# commented out because some entries are just an initial without a matching full entry for that initial
#         unless ($row[2] =~ m/^\w[^\w]*$/) { 		# if entry isn't just an initial
          $row[2] =~ s/^\s+//g; $row[2] =~ s/\s+$//g;	# take out spaces in front and back
          $row[2] =~ s/[\,\.]//g;			# take out commas and dots
          $row[2] =~ s/_/ /g;				# replace underscores for spaces
# if ($row[2] =~ m/\./) { print STDERR "$row[2]\n"; }
          if ($aka_hash{$table}{$row[2]}) {	# if specific name-type has a time, compare them and update with latest
            (my $now_time) = $row[3] =~ m/^(\d\d\d\d\-\d\d\-\d\d \d\d)/;
            (my $high_time) = $aka_hash{$table}{$row[2]} =~ m/^(\d\d\d\d\-\d\d\-\d\d \d\d)/;
            $now_time =~ s/\D//g; $high_time =~ s/\D//g;
            if ($now_time > $high_time) { $aka_hash{$table}{$row[2]} = $row[3]; }
          } else { $aka_hash{$table}{$row[2]} = $row[3]; }	# if not, then assign time
#         }
      }
    }
    $result = $conn->exec ( "SELECT * FROM two_${table}name WHERE joinkey = '$joinkey' AND two_${table}name IS NOT NULL AND two_${table}name != 'NULL' AND two_${table}name != '';" );
    while ( @row = $result->fetchrow ) {
      if ($row[3]) { 					# if there's a time
# commented out because some entries are just an initial without a matching full entry for that initial
#         unless ($row[2] =~ m/^\w[^\w]*$/) { 		# if entry isn't just an initial
          $row[2] =~ s/^\s+//g; $row[2] =~ s/\s+$//g;	# take out spaces in front and back
          $row[2] =~ s/[\,\.]//g;			# take out commas and dots
          $row[2] =~ s/_/ /g;				# replace underscores for spaces
          if ($aka_hash{$table}{$row[2]}) {	# if specific name-type has a time, compare them and update with latest
            (my $now_time) = $row[3] =~ m/^(\d\d\d\d\-\d\d\-\d\d \d\d)/;
            (my $high_time) = $aka_hash{$table}{$row[2]} =~ m/^(\d\d\d\d\-\d\d\-\d\d \d\d)/;
            $now_time =~ s/\D//g; $high_time =~ s/\D//g;
            if ($now_time > $high_time) { $aka_hash{$table}{$row[2]} = $row[3]; }
          } else { $aka_hash{$table}{$row[2]} = $row[3]; }	# if not, then assign time
#         }
      }
    }
  } # foreach my $table (@tables)

    foreach my $table (@tables) {
      foreach my $aka_value (sort keys %{ $aka_hash{$table} }) {
        print "Aka_$table\t\"$aka_value\" -O \"$aka_hash{$table}{$aka_value}\"\n";
      } # foreach my $aka_value (sort keys %{ $aka_hash{$table} })
    } # foreach my $table (@tables)
} # sub akaPrint

