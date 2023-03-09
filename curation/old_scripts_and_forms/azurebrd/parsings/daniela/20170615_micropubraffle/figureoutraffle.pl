#!/usr/bin/perl 

# Find a winner for expr submissions since previous run of this script.  Set marker on data file for cutoff for next run.  2017 06 15
# 30 21 * * * /home/azurebrd/work/parsings/daniela/20170615_micropubraffle/figureoutraffle.pl



use Jex;
use strict;

my $datafile = '/home/azurebrd/public_html/cgi-bin/data/expr_micropub.data';

$/ = undef;

open (IN, "<$datafile") or die "Cannot open $datafile : $!";
my $allfile = <IN>;
close (IN) or die "Cannot open $datafile : $!";

my $realEntries;
my %score;
my %contact;

my (@dates) = split/__DIVIDER__/, $allfile;
my $recent = pop @dates;
my (@entries) = split/\n/, $recent;
foreach my $entry (@entries) {
  my ($timestamp, $flag, $wbperson, $personname, $email) = split/\t/, $entry;
  my $score = 1; if ($flag eq 'realdata') { $score = 10; $realEntries++; }
  if ($score > $score{$wbperson}) { $score{$wbperson} = $score; }
  $contact{$wbperson}{name}  = $personname;
  $contact{$wbperson}{email} = $email;
} # foreach my $entry (@entries)

my $body = qq(Results from expr micropublication raffle\n);
my $uniquePeople = scalar keys %score;
$body .= qq(There are $realEntries real data entries\n);
$body .= qq(There are $uniquePeople unique submitters\n);

my %raffle;
my $count = 0;
foreach my $person (sort keys %score) {
  next unless $person;
  for (1 .. $score{$person}) {
    $count++;
    $raffle{$count} = $person;
#     print qq($count\t$person\n);
  } }
my $rand = int($count * rand()) + 1;
my $winner = $raffle{$rand};
my $name  = $contact{$winner}{name };
my $email = $contact{$winner}{email};
$body .= qq(Winner is $winner, $name, $email\n);

# print qq($body);

my $email   = 'draciti@caltech.edu, kyook@caltech.edu';
# my $email   = 'azurebrd@tazendra.caltech.edu';
my $user    = 'expr_micropublication_raffle';    # who sends mail
my $subject = 'Raffle results';
&mailer($user, $email, $subject, $body);                    # email the data

open (OUT, ">>$datafile") or die "Cannot append $datafile : $!";
print OUT qq(__DIVIDER__\n);
close (OUT) or die "Cannot close $datafile : $!";
