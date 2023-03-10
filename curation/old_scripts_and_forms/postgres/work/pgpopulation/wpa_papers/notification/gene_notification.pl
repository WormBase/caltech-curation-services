#!/usr/bin/perl -w

# Look at list of gen_notification for genes that curators want to be notified
# when a new paper has come out mentioning that gene in wpa_gene.   Sort them by
# curator, then by gene, then check each gene vs. wpa_gene, and if there's data,
# get the email of the curator and email the curator.  2006 11 20
#
# Set to run every day at 1 am.
# 0 1 * * * /home/postgres/work/pgpopulation/wpa_papers/notification/gene_notification.pl
#
# disabled since only kimberly ever signed up, and hasn't used it for years.  2010 06 23


use strict;
use diagnostics;
use Pg;
use Jex;

my %curators;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

&populateCurators();

my $yesterdate = &getSimpleYesterPgDate();

my %notify;
my $result = $conn->exec( "SELECT * FROM gen_notification ORDER BY gen_timestamp;" );
while (my @row = $result->fetchrow) {
  if ($row[2] eq 'valid') { $notify{$row[1]}{$row[0]}++; } 
    else { delete $notify{$row[1]}{$row[0]}; } } 

foreach my $curator (sort keys %notify) {
  my $body = '';
  my %mail_gene;
  my $two_num = $curators{std}{$curator};
  foreach my $gene (sort keys %{ $notify{$curator} }) {
#     print "NOTIFY $two_num $curator of $gene\n"; 
    my %gene;
    my $result = $conn->exec("SELECT * FROM wpa_gene WHERE wpa_gene ~ 'WBGene00001437' ORDER BY wpa_timestamp; ");

    while (my @row = $result->fetchrow) {
      if ($row[3] eq 'valid') { $gene{$row[0]}++; }
        else { delete $gene{$row[0]}; }
    } # while (my @row = $result->fetchrow)
    foreach my $paper (sort keys %gene) {
      my $result = $conn->exec("SELECT * FROM wpa_gene WHERE wpa_gene ~ 'WBGene00001437' AND joinkey = '$paper' ORDER BY wpa_timestamp; ");
      my @row = $result->fetchrow();
      my $date = $row[5];
      $date =~ s/\D//g;
      ($date) = $date =~ m/^(\d{12})/;
      if ($date > $yesterdate) { $mail_gene{$gene}{$paper}++; }
    } # foreach my $paper (sort keys %gene)
  }
  foreach my $gene (sort keys %mail_gene) {
    my @papers;
    foreach my $paper (sort keys %{ $mail_gene{$gene} }) { push @papers, $paper; }
    my $papers = join", ", @papers;
    $body .= "Gene $gene in Papers $papers\n"; }
  if ($body) { 
    my $result = $conn->exec( "SELECT two_email FROM two_email WHERE joinkey = '$two_num';" );
    my @row = $result->fetchrow;
    if ($row[0]) { 
      my $email = $row[0];
      my $user = 'gene_notification.pl';
      my $subject = 'annotated gene mentioned in new paper';
      &mailer($user, $email, $subject, $body); } }
}
  


sub populateCurators {
  my $result = $conn->exec( "SELECT * FROM two_standardname; " );
  while (my @row = $result->fetchrow) {
    $curators{two}{$row[0]} = $row[2];
    $curators{std}{$row[2]} = $row[0];
  } # while (my @row = $result->fetchrow)
} # sub populateCurators

sub getSimpleYesterPgDate {
  my $time = time;                      # set time
  $time -= 86400;
  my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) =
          localtime($time);             # get time
  if ($sec < 10) { $sec = "0$sec"; }    # add a zero if needed
  if ($min < 10) { $min = "0$min"; }    # add a zero if needed
  if ($mon < 10) { $mon = "0$mon"; }    # add a zero if needed
  if ($mday < 10) { $mday = "0$mday"; } # add a zero if needed
  $year = 1900+$year;                   # get right year in 4 digit form
  my $date = "$year$mon$mday$hour$min";
  return $date;
} # sub getSimpleYesterPgDate 


__END__

