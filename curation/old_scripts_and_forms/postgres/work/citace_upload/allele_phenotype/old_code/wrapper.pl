#!/usr/bin/perl

# Dump allele phenotype data.

# Dump concise description data to old/concise_dump.date.hour.ace
# and symlink to /home/postgres/public_html/cgi-bin/data/concise_dump_new.ace
# for cronjob for Erich.
# 0 2 * * wed /home/postgres/work/citace_upload/concise/wrapper.pl
# Matches script on altair at /home/citace/cronjobs/copyConciseAndGOTerms.pl
# 2005 09 15

# Adapted for allele-phenotype data.  2005 12 16


use Pg;
use Jex;
use lib qw( /home/postgres/work/citace_upload/allele_phenotype/ );
use get_allele_phenotype_ace;


my $date = &getSimpleSecDate();

my $directory = '/home/postgres/work/citace_upload/allele_phenotype';
my $outfile = $directory . '/old/allele_phenotype.' . $date . '.ace';

chdir($directory) or die "Cannot go to $directory ($!)";

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;
my %filterHash;
$result = $conn->exec( "SELECT * FROM alp_type WHERE alp_type = 'Transgene' OR alp_type = 'Allele';" );
while (my @row = $result->fetchrow) {                               # get Alleles and Transgenes
  my $result2 = $conn->exec( "SELECT * FROM alp_finalname WHERE joinkey = '$row[0]' ORDER BY alp_timestamp DESC;" );
  while (my @row2 = $result2->fetchrow) {                           # if they have a finalname, queue to get values
    if ($row[1]) { if ($row[1] =~ m/\w/) { $filterHash{$row[0]}++; } } } }

# my @list = qw(a83 ad1674 ad446 ak41);
# foreach my $joinkey (@list) {
#   my $entry = ''; my $err_text = '';
#   ($entry, $err_text) = &getAllelePhenotype($joinkey);
#   print "E $entry R $err_text\n";
# }

open (OUT, ">>$outfile") or die "Cannot create $outfile : $!";		# init and symlink to file since html will time out before it stops being created
print OUT "\n";
close (OUT) or die "Cannot close $outfile : $!";
my $location_of_latest = '/home/postgres/public_html/cgi-bin/data/allele_phenotype.ace';
unlink ("$location_of_latest") or die "Cannot unlink $location_of_latest : $!";       # unlink symlink to latest
symlink("$outfile", "$location_of_latest") or warn "cannot symlink $location_of_latest : $!";


foreach my $joinkey (sort keys %filterHash) {
  my $entry = ''; my $err_text = '';
  ($entry, $err_text) = &getAllelePhenotype($joinkey);
  open (OUT, ">>$outfile") or die "Cannot create $outfile : $!";
  if ($entry) { print OUT "$entry\n"; }
  if ($err_text) { print OUT "$err_text\n"; }
  close (OUT) or die "Cannot close $outfile : $!";
}




__END__

# open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
my ($all_entry, $err_text) = &getAllelePhenotype("all");
if ($err_text) { print OUT "$err_text\n"; }
my (@lines) = split/\n/, $all_entry;
foreach my $line (@lines) { 
  open (OUT, ">>$outfile") or die "Cannot create $outfile : $!";
  print OUT "$line\n"; 
  close (OUT) or die "Cannot close $outfile : $!";
}
# print OUT "$all_entry";
# close (OUT) or die "Cannot close $outfile : $!";

my $location_of_latest = '/home/postgres/public_html/cgi-bin/data/allele_phenotype.ace';
unlink ("$location_of_latest") or die "Cannot unlink $location_of_latest : $!";       # unlink symlink to latest
symlink("$outfile", "$location_of_latest") or warn "cannot symlink $location_of_latest : $!";



