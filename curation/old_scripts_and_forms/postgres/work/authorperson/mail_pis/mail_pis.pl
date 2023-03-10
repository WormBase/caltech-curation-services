#!/usr/bin/perl -w
#
# Quick PG query to get firstname of pis.  2003 03 27

use strict;
use diagnostics;
use Pg;
use Jex;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $outfile = "outfile";
open(OUT, ">$outfile") or die "Cannot create $outfile : $!";

&mail_body('azurebrd@ugcs.caltech.edu', 'Chan');


# my $result = $conn->exec( "SELECT two_firstname.joinkey, two_firstname.two_firstname FROM two_firstname, two_pis WHERE two_firstname.joinkey = two_pis.joinkey AND two_pis.two_pis IS NOT NULL" );
my $result = $conn->exec( "SELECT two_lastname.joinkey, two_lastname.two_lastname FROM two_lastname, two_pis WHERE two_lastname.joinkey = two_pis.joinkey AND two_pis.two_pis IS NOT NULL" );
while (my @row = $result->fetchrow) {
  my @email;
  my $result2 = $conn->exec( "SELECT two_email FROM two_email WHERE joinkey = '$row[0]'" );
  while (my @row2 = $result2->fetchrow) {
    if ($row2[0]) { 
      if ($row2[0] !~ m/NULL/) { 
        push @email, $row2[0];
      }
    }
  } # while (my @row2 = $result2->fetchrow)
  if ($email[0]) { print "$row[0]\tDr. $row[1]\t$email[0]\n"; }
  else { print STDERR "NO email $row[0]\t$row[1]\n"; }
} # while (my @row = $result->fetchrow)

#   unless ($row2[0]) { print STDERR "NO email $row[0]\t$row[1]\n"; }
#   else { 
#     unless ($row2[0] =~ m/NULL/) { 
#       print "$row[0]\tDr. $row[1]\t$row2[0]\n";
#     } else {
#       @row2 = $result2->fetchrow;
#       unless ($row2[0]) { print STDERR "TAKE2 NO email $row[0]\t$row[1]\n"; }
#       else { 
#         print "TAKE2 $row[0]\tDr. $row[1]\t$row2[0]\n";
#       }
#     }
#   }

sub mail_body {
  my ($email, $lastname) = @_;
  $email .= ', cecilia@minerva.caltech.edu';
  my $user = 'cecilia@minerva.caltech.edu';
  my $subject = 'WormBase Updating Laboratory Members';
  my $body = "Dear Dr. $lastname,

I am working on having updated accurate contact data of individuals in 
the Worm Community, as well of linking individuals to their publications 
and their Laboratories.

As a PI, I need your help to update Laboratory data.  Would you please 
provide us with a list of the current members of your lab, including, 
graduate students, postdocs, and anyone else who might be an author on 
a paper, meeting abstract or WBG article.  In addition, we would like 
to have a list of past lab members.

I would really appreciate your help.

Thank you.

Cecilia Nakamura
Assistant Curator
California Institute of Technology
Division of Biology 156-29
Pasadena, CA 91125
USA
tel: 626.395.5878   fax: 626.395.8611
cecilia\@minerva.caltech.edu";
  &mailer($user, $email, $subject, $body);      # email cecilia data
} # sub mail_body

