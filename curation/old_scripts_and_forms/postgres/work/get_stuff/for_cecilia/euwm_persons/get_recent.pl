#!/usr/bin/perl -w

# Match authors from euwm to existing people and see if both names and email
# match (category 2) only names match (category 1) or neither match (category 0)
# Email new people (category 0) to fill out the form to create their person
# entry.  2006 06 06

use strict;
use diagnostics;
use Pg;
use Jex;	# mailer

print "pie\n";

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my %authors;

my $outfile = "outfile";
open(OUT, ">$outfile") or die "Cannot create $outfile : $!";

my %aka_hash = &getPgHash();
my %author_emails;

my %histogram;
my $total_authors;

# my $result = $conn->exec( "SELECT wpa_author_index, author_id, wpa_valid FROM wpa_author_index ORDER BY author_id, wpa_timestamp;" );
# my $curr_auth = ''; my %auth_filter;
# while (my @row = $result->fetchrow) {
#   if ($curr_auth ne $row[1]) { 
#     $curr_auth = $row[1];
#     foreach my $auth (sort keys %auth_filter) { $authors{$auth}++; }
#     %auth_filter = (); }
#   if ($row[0]) { 
#     if ($row[0] =~ m/,/) { $row[0] =~ s/,//g; }
#     if ($row[0] =~ m/\./) { $row[0] =~ s/\.//g; }
#     if ($row[2] eq 'valid') { $auth_filter{$row[0]}++; }
#       else { delete $auth_filter{$row[0]}; }
#   }
# }

my $result = $conn->exec( "SELECT * FROM two_email;" );
while (my @row = $result->fetchrow) {
  push @{ $author_emails{$row[2]} }, $row[0];
} # while (my @row = $result->fetchrow)

my $infile = 'EWM2006_Contacts.csv';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while(<IN>) {
  if ($_ =~ m/\s+$/) { $_ =~ s/\s+$//g; }
  chomp;
  my ($person, $email) = split/;/, $_;
  push @{ $authors{$person} }, $email;
} # while(<IN>)
close (IN) or die "Cannot close $infile : $!";

my %sorting;

foreach my $author (sort keys %authors) {
  $total_authors++;
  my $line = "AUT $author";
  my $category = 0;
#   print OUT "AUT $author";
  my $orig_author = $author;
  $author = lc($author); 
  if ($aka_hash{$author}) {
      my @twos = keys %{ $aka_hash{$author} };
      my $count = scalar(@twos);
      $histogram{count}{$count}++;
      my $list = join", ", @twos;
#       print OUT "\t$count\ttwo$list"; 
      $line .= "\t$count\ttwo$list"; 
      
      if ($authors{$orig_author}) { 
        $category++;			# category 1 for matching name
        my $emails = join", ", @{ $authors{$orig_author} }; 
        foreach my $email (@{ $authors{$orig_author} }) {
          if ($author_emails{$email}) { $category++; } }	# category 2 for matching email
#         print OUT "\t$emails";  
        $line .= "\t$emails"; } 
    } # if ($aka_hash{$author})
    else { $histogram{count}{0}++; }
#   print OUT "\n";
  $line .= "\n";
  push @{ $sorting{$category} }, $line;
} # foreach my $author (sort keys %authors)


foreach my $line (@{ $sorting{'0'} }) { 
  my $emails = '';
  chomp $line;  $line =~ s/AUT //g; 
  if ($authors{$line}) { $emails = join", ", @{ $authors{$line} }; }
    else { print OUT "NO EMAILS $line\n"; next; }
  print OUT "MAILING TO $emails\n"; 
  my $user = 'cecilia@tazendra.caltech.edu';
  my $email = $emails . ', cecilia@tazendra.caltech.edu';
  my $subject = 'Creating your WormBase profile';
  my $body = "Dear C. elegans researcher:

I would like your help to create your WormBase profile.
http://www.wormbase.org

Online update form:
http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/person.cgi

Please do not hesitate to contact me if you have any questions.
We'd really appreciate your help.

Thank you very much.
Best regards,

Cecilia";
  &mailer($user, $email, $subject, $body);    # email to user
}

print OUT "\n\nBLEH\n\n";

foreach my $category ( sort keys %sorting ) {
  print OUT "Category $category\n";
  foreach my $line (@{ $sorting{$category} }) { print OUT "$line"; }
  print OUT "\n\nDIV\n\n";
} # foreach my $category ( sort keys %sorting )

print OUT "\n\nDIVIDER\n\n\n";

print OUT "There are $total_authors different Author names\n";
print OUT "# of Hits\tInstances with # of Hits\n";
foreach my $count (reverse sort {$a<=>$b} keys %{ $histogram{count} }) {
  print OUT "$count\t$histogram{count}{$count}\n";
} # foreach my $count (reverse sort keys %{ $histogram{count} })


close (OUT) or die "Cannot close $outfile : $!";


sub getPgHash {				# get akaHash from postgres instead of flatfile
  my $result;
  my %filter;
  my %aka_hash;
  
  my @tables = qw (first middle last);
  foreach my $table (@tables) { 
    $result = $conn->exec ( "SELECT * FROM two_aka_${table}name WHERE two_aka_${table}name IS NOT NULL AND two_aka_${table}name != 'NULL' AND two_aka_${table}name != '';" );
    while ( my @row = $result->fetchrow ) {
      if ($row[3]) { 					# if there's a time
        my $joinkey = $row[0];
        $row[2] =~ s/^\s+//g; $row[2] =~ s/\s+$//g;	# take out spaces in front and back
        $row[2] =~ s/[\,\.]//g;				# take out commas and dots
        $row[2] =~ s/_/ /g;				# replace underscores for spaces
        $row[2] = lc($row[2]);				# for full values (lowercase it)
        $row[0] =~ s/two//g;				# take out the 'two' from the joinkey
        $filter{$row[0]}{$table}{$row[2]}++;
        my ($init) = $row[2] =~ m/^(\w)/;		# for initials
        $filter{$row[0]}{$table}{$init}++;
      }
    }
    $result = $conn->exec ( "SELECT * FROM two_${table}name WHERE two_${table}name IS NOT NULL AND two_${table}name != 'NULL' AND two_${table}name != '';" );
    while ( my @row = $result->fetchrow ) {
      if ($row[3]) { 					# if there's a time
        my $joinkey = $row[0];
        $row[2] =~ s/^\s+//g; $row[2] =~ s/\s+$//g;	# take out spaces in front and back
        $row[2] =~ s/[\,\.]//g;				# take out commas and dots
        $row[2] =~ s/_/ /g;				# replace underscores for spaces
        $row[2] = lc($row[2]);				# for full values (lowercase it)
        $row[0] =~ s/two//g;				# take out the 'two' from the joinkey
        $filter{$row[0]}{$table}{$row[2]}++;
        my ($init) = $row[2] =~ m/^(\w)/;		# for initials
        $filter{$row[0]}{$table}{$init}++;
      }
    }
  } # foreach my $table (@tables)

  my $possible;
  foreach my $person (sort keys %filter) { 
    foreach my $last (sort keys %{ $filter{$person}{last}} ) {
      foreach my $first (sort keys %{ $filter{$person}{first}} ) {
        $possible = "$first"; $aka_hash{$possible}{$person}++;
        $possible = "$last"; $aka_hash{$possible}{$person}++;
        $possible = "$last $first"; $aka_hash{$possible}{$person}++;
        $possible = "$first $last"; $aka_hash{$possible}{$person}++;
        if ( $filter{$person}{middle} ) {
          foreach my $middle (sort keys %{ $filter{$person}{middle}} ) {
#             $possible = "$first"; $aka_hash{$possible}{$person}++;
            $possible = "$middle"; $aka_hash{$possible}{$person}++;
            $possible = "$first $middle"; $aka_hash{$possible}{$person}++;
            $possible = "$middle $first"; $aka_hash{$possible}{$person}++;
#             $possible = "$last"; $aka_hash{$possible}{$person}++;
#             $possible = "$last $first"; $aka_hash{$possible}{$person}++;
            $possible = "$last $middle"; $aka_hash{$possible}{$person}++;
            $possible = "$last $first $middle"; $aka_hash{$possible}{$person}++;
            $possible = "$last $middle $first"; $aka_hash{$possible}{$person}++;
#             $possible = "$first $last"; $aka_hash{$possible}{$person}++;
            $possible = "$middle $last"; $aka_hash{$possible}{$person}++;
            $possible = "$first $middle $last"; $aka_hash{$possible}{$person}++;
            $possible = "$middle $first $last"; $aka_hash{$possible}{$person}++;
          } # foreach my $middle (sort keys %{ $filter{$person}{middle}} )
        }
      } # foreach my $first (sort keys %{ $filter{$person}{first}} )
    } # foreach my $last (sort keys %{ $filter{$person}{last}} )
  } # foreach my $person (sort keys %filter) 

  return %aka_hash;
} # sub getPgHash

