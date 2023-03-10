#!/usr/bin/perl

# use the get_paper_ace.pm module from /home/postgres/work/citace_upload/papers/ 
# to dump the papers, abstracts (LongText objects), and errors associated with
# them.  2005 07 13
#
# Change to default get all papers, not just valid ones.  2005 11 10

use strict;
use Jex;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $date = &getSimpleSecDate();
my $start_time = time;
my $estimate_time = time + 157;
my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime($estimate_time);             # get time
if ($sec < 10) { $sec = "0$sec"; }    # add a zero if needed
if ($min < 10) { $min = "0$min"; }    # add a zero if needed
print "START $date -> Estimate $hour:$min:$sec\n";

$date = &getSimpleDate();

use lib qw( /home/postgres/work/citace_upload/interaction/ );
use get_interaction_ace;

my $directory = '/home/postgres/work/citace_upload/interaction/';
chdir($directory) or die "Cannot switch directory to $directory : $!";

&associateMissingInteractionIDs();

my $outfile = 'interaction.ace.' . $date;
my $outfile2 = 'interaction.ace';
my $errfile = 'err.out.' . $date;
open (OUT, ">$outfile") or die "Cannot create $outfile : $!\n";
open (OU2, ">$outfile2") or die "Cannot create $outfile2 : $!\n";
open (ERR, ">$errfile") or die "Cannot create $errfile : $!\n";


my ($all_entry, $long_text, $err_text) = &getInteraction('all');
# my ($all_entry, $long_text, $err_text) = &getInteraction('WBInteraction0000074');
# my ($all_entry, $long_text, $err_text) = &getInteraction('tm1821');

print OUT "$all_entry\n";
print OU2 "$all_entry\n";
if ($err_text) { print ERR "$err_text\n"; }

close (OUT) or die "Cannot close $outfile : $!";
close (OU2) or die "Cannot close $outfile2 : $!";
close (ERR) or die "Cannot close $errfile : $!";

$date = &getSimpleSecDate();
my $end_time = time;
my $diff_time = $end_time - $start_time;
print "DIFF $diff_time\n";
print "END $date\n";

sub associateMissingInteractionIDs {
  my %hash;
  my @tables = qw( name effected effector type phenotype curator paper person );
  foreach my $table (@tables) {
    my $result = $conn->exec( "SELECT * FROM int_$table;" );
    while (my @row = $result->fetchrow) {
      $hash{$table}{$row[0]} = $row[1];
      $hash{joinkeys}{$row[0]}++;
    } # while (my @row = $result->fetchrow)
  } # foreach my $table (@tables)
  my @need_interactionID = ();
  foreach my $joinkey ( sort {$a<=>$b} keys %{ $hash{joinkeys} }) {
    next if ($hash{name}{$joinkey});
    if ( ($hash{effected}{$joinkey}) && ($hash{effector}{$joinkey}) && 
         ($hash{type}{$joinkey}) && ($hash{phenotype}{$joinkey}) && 
         ($hash{curator}{$joinkey}) && 
         ( ($hash{paper}{$joinkey}) || ($hash{person}{$joinkey}) ) ) {
      push @need_interactionID, $joinkey;
    }
  } # foreach my $joinkey ( sort {$a<=>$b} keys %{ $hash{joinkeys} })
  my $count = scalar( @need_interactionID );
  print "There are $count interactions that need an ID<BR><BR>\n";
  foreach my $joinkey (@need_interactionID) {
    print "NEED $joinkey ID fake code assigning it blah blah blah<BR>\n";
  } # foreach my $joinkey (@need_interactionID)
} # sub associateMissingInteractionIDs


__END__
