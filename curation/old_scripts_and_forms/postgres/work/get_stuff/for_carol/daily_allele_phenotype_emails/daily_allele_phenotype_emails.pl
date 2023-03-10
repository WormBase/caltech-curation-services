#!/usr/bin/perl -w

# Send one email per paper, where that paper has a variation that has been
# created this (the previous) day and has no final name.  Get a list of Alleles
# that don't have a finalname, grab all the papers attached to it.  Then for
# each paper get all Allele objects and send an email.  For Mary Ann  2005 11 24
#
# Adapted to do the same for Transgene for Wen.  2005 11 28
#		
# added Anthony for Mary Ann  2006 08 23
#
# No longer email those with final names.  Sort those that need final names into
# those created ``before yesterday'' and those create on or after.  2006 10 12
#
# Set to run every day at 1am	2005 11 24
# 0 1 * * * /home/postgres/work/get_stuff/for_carol/daily_allele_phenotype_emails/daily_allele_phenotype_emails.pl


use strict;
use diagnostics;
use Pg;
use Jex;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $date = &getPreviousPgDate();
# print "DATE $date\n";

# my $outfile = "outfile";
# open(OUT, ">$outfile") or die "Cannot create $outfile : $!";

my @types = qw(Allele Trasgene);		# need to change Allele below to loop through these types, then set to Wen or Mary Ann
my %alleles; my %papers; 
foreach my $type (@types) {
  my $command = "SELECT joinkey FROM alp_type WHERE alp_type = '$type' AND joinkey IN (SELECT alp_tempname FROM alp_tempname WHERE alp_timestamp ~ '$date');" ;
  # print "COM $command\n";
  my $result = $conn->exec( $command );
  while (my @row = $result->fetchrow) { if ($row[0]) { $alleles{$row[0]}++; } }
  foreach my $allele (sort keys %alleles) {
    $result = $conn->exec( "SELECT * FROM alp_paper WHERE joinkey = '$allele';" );
    while (my @row = $result->fetchrow) { if ($row[2]) { $papers{$row[2]}++; } } }
  foreach my $paper (sort keys %papers) {
    %alleles = (); my $papers = ''; my $joinkey = $paper; $joinkey =~ s/\D//g; 
    $result = $conn->exec( "SELECT wpa_identifier FROM wpa_identifier WHERE joinkey = '$joinkey';" );
    while (my @row = $result->fetchrow) { $papers .= "$row[0]\n"; }
    $result = $conn->exec( "SELECT joinkey, alp_timestamp FROM alp_paper WHERE alp_paper = '$paper' AND joinkey IN (SELECT joinkey FROM alp_type WHERE alp_type = '$type') ORDER BY alp_timestamp;" );
    while (my @row = $result->fetchrow) { if ($row[0]) { 
      my ($timestamp) = $row[1] =~ m/(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})/;
      $alleles{$row[0]} = $timestamp; } } 
    my $need_final_old = ''; my $need_final_new = ''; my $have_final = '';
    foreach my $allele (sort keys %alleles) {
      $result = $conn->exec( "SELECT alp_finalname FROM alp_finalname WHERE joinkey = '$allele' ;" );
      my @row = $result->fetchrow;
#       if ($row[0]) { $have_final .= "$allele\n"; }			# Mary Ann no longer wants those with final name
      if ($row[0]) { delete $alleles{$allele}; }
#       else { $need_final .= "$allele\t$alleles{$allele}\n"; }		# need final stuff sorted by age and name instead of appended
    } # foreach my $allele (sort keys %alleles)
    foreach my $allele (sort keys %alleles) { 
      my ($a_time) = $alleles{$allele}; $a_time =~ s/\D//g; ($a_time) = $a_time =~ m/^(\d{8})/;
      my ($y_time) = $date; $y_time =~ s/\D//g;
      if ($y_time > $a_time) { $need_final_old .= "$allele\t$alleles{$allele}\n"; }
        else { $need_final_new .= "$allele\t$alleles{$allele}\n"; } }
    if ( ($need_final_old) || ($need_final_new) ) {
#       my $subject = $need_final; $subject =~ s/\s+/ /g;		# used to have data in the subject
      my $email = 'mt3@sanger.ac.uk, ar2@sanger.ac.uk';		# added Anthony for Mary Ann  2006 08 23
      my $word = 'Variation';
      if ($type eq 'Transgene') { $word = 'Transgene'; }
      my $user = 'daily_allele_phenotype_emails.pl';
#       my $subject = "$word objects created at Caltech $paper : $subject";	# used to have data in the subject
      my $subject = "$word objects created at Caltech";
      my $body = "$papers\n";
      if ($need_final_new) {
        $body .= "The following temporary $word names have been created :\n";
        $body .= "$need_final_new\n"; }
      if ($need_final_old) {
        $body .= "The following temporary $word names were created before yesterday :\n";
        $body .= "$need_final_old\n"; }
      $body .= "Please create live $word objects and enter final name at :\n";
      $body .= "http://tazendra.caltech.edu/~postgres/cgi-bin/allele_phenotype_curation.cgi\n\n";
# Mary Ann no longer wants those with final name  2006 10 12
#       if ($have_final) { 
#         $body .= "The following ${word}s are attached to the paper and already have a final name :\n$have_final\n"; }
      $body .= "Lots of love and here's some chocolate,\n";
      $body .= "Caltech";
      &mailer($user, $email, $subject, $body); 
    } # if ( ($need_final_old) || ($need_final_new) )
  } # foreach my $paper (sort keys %papers)
} # foreach my $type (@types)



# close (OUT) or die "Cannot close $outfile : $!";

sub getPreviousPgDate {                         # begin getPgDate
  my @days = qw(Sunday Monday Tuesday Wednesday Thursday Friday Saturday);
                                        # set array of days
  my @months = qw(January February March April May June
          July August September October November December);
                                        # set array of months
  my $time = time;                      # set time
  $time -= 86400;			# get previous date
  my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) =
          localtime($time);             # get time
  $mon++;
  if ($sec < 10) { $sec = "0$sec"; }    # add a zero if needed
  if ($min < 10) { $min = "0$min"; }    # add a zero if needed
  if ($mon < 10) { $mon = "0$mon"; }    # add a zero if needed
  if ($mday < 10) { $mday = "0$mday"; } # add a zero if needed
  $year = 1900+$year;                   # get right year in 4 digit form
  my $todaydate = "${year}-${mon}-${mday}"; 
                                        # set current date
#   my $date = $todaydate . " $hour\:$min\:$sec";
  my $date = $todaydate;
                                        # set final date
  return $date;
} # sub getPreviousPgDate                       # end getPgDate
