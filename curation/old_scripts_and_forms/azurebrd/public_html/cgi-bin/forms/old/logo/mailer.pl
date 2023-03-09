#!/usr/bin/perl 

# email passwords to wormbase people allowed to vote

use strict;
use Jex; 	# mailer

my %passwd		# emails and passwords
&populatePasswd();

my $user = 'logo';
my $subject = 'logo form updated for final vote';

foreach my $email (sort keys %passwd) {
  my $body = "Please vote at http://minerva.caltech.edu/~azurebrd/cgi-bin/forms/logo.cgi\nYour password for the WormBase Logo vote is : $passwd{$email}";
  &mailer($user, $email, $subject, $body);        # email the data
} # foreach my $email (sort keys %passwd)

# sub populatePasswd {
#   $passwd{'azurebrd@ugcs.caltech.edu'} = 'NE&7=rep';
#   $passwd{'bounce@minerva.caltech.edu'} = 'guw4boP+';
# } # sub populatePasswd

sub populatePasswd {
  $passwd{'lstein@cshl.org'} = 'NE&7=rep';
  $passwd{'jspieth@watson.wustl.edu'} = 'guw4boP+';
  $passwd{'pws@caltech.edu'} = 'Zo!1tHux';
  $passwd{'emsch@its.caltech.edu'} = 'ClImo5-7';
  $passwd{'rd@sanger.ac.uk'} = 'tr=TRa?i';
  $passwd{'mueller@its.caltech.edu'} = '6r#!ufAy';
  $passwd{'dl1@sanger.ac.uk'} = 'n7Jo$l=h';
  $passwd{'srk@sanger.ac.uk'} = '4op3ust*';
  $passwd{'dblasiar@watson.wustl.edu'} = 'tHilo1*a';
  $passwd{'todd.harris@cshl.org'} = 'p8*lIl_p';
  $passwd{'krb@sanger.ac.uk'} = '9#Uloy#4';
  $passwd{'tbieri@watson.wustl.edu'} = 'x83etru$';
  $passwd{'eimear@its.caltech.edu'} = 'SPI&ahe8';
  $passwd{'wen@athena.caltech.edu'} = 'h05r_sTI';
  $passwd{'raymond@caltech.edu'} = 'st0x@=ra';
  $passwd{'azurebrd@lek.ugcs.caltech.edu'} = 'qOyiW9o!';
  $passwd{'andrei@tuco.caltech.edu'} = '-to-o1aC';
  $passwd{'ar2@sanger.ac.uk'} = 'q=24briM';
  $passwd{'ranjana@its.caltech.edu'} = 'c#maBef3';
  $passwd{'ck1@sanger.ac.uk'} = '51&&ziPU';
  $passwd{'cunningh@cshl.edu'} = 'w8obI-8T';
  $passwd{'qwang@caltech.edu'} = '55*Nozac';
  $passwd{'cecilia@minerva.caltech.edu'} = '@1q+chIw';
} # sub populatePasswd


