#!/usr/bin/perl

# Compare Sanger's loci_all.txt with current copy.  If different backup the copy
# and overwrite current copy with Sanger copy.  Couldn't get LWP::Simple to get 
# Sanger's loci_all.txt (don't know why it failed).  2005 10 10
#
# Set to cronjob to update everyday.  2005 10 10
# 0 4 * * * /home/azurebrd/public_html/sanger/update_loci.pl

# maybe also need to get :
# http://www.sanger.ac.uk/Projects/C_elegans/LOCI/genes2molecular_names.txt

# Updated to also get genes2molecular_names.txt  2006 01 17

# Updated because comparison wasn't working because was printing with an extra
# newline, so it never matched Sanger file.  Also wasn't doing a
# $response->content for the local file.  Added a filesize check before
# overwriting, and emails Kimberly if it's too small (like
# genes2molecular_names.txt being 0 sized sometimes)  2006 03 24

# Query aceserver for names that match any wbgene, based on Igor's code.  Output
# to wbgenes_to_words.txt   2006 07 08
#
# New location of genes2mol :
# http://www.sanger.ac.uk/tmp/Projects/C_elegans/LOCI/genes2molecularnamestest.txt
# 2006 12 18



use strict;
use LWP::Simple;
use Jex;
use diagnostics;
use LWP::UserAgent;					# not in use

use Ace;




my $date = &getSimpleSecDate();

my $directory = '/home/azurebrd/public_html/sanger';

chdir($directory) or die "Cannot go to $directory ($!)";


my $ua = LWP::UserAgent->new;
$ua->timeout(10);
$ua->env_proxy;


# Test Carol's search thing, doesn't work  2006 09 14
#     use constant HOST => $ENV{ACEDB_HOST} || 'aceserver.cshl.org';
#     use constant PORT => $ENV{ACEDB_PORT} || 2005;
#     my $db = Ace->connect(-host=>HOST,-port=>PORT) or warn "Connection failure: ",Ace->error;
# #     my $query = "find RNAi $tempname";
#     my $query = "select a, b, c, d from a in class Gene, b in a->cgc_name, c in a ->RNAi_result, d in c ->Phenotype where not exists_tag d[Not]";
#     my @rnai = $db->fetch(-query=>$query);
#     if ($rnai[0]) { print "aceserver found $rnai[0]<BR>\n"; }

my $response = $ua->get("http://www.sanger.ac.uk/Projects/C_elegans/LOCI/loci_all.txt");

my $sanger = '';
if ($response->is_success) { $sanger = $response->content;  }
  else { die $response->status_line; }

# my $sanger2 = get("http://www.sanger.ac.uk/Projects/C_elegans/LOCI/loci_all.txt");
#         die "Couldn’t get it!" unless defined $sanger2;
# print "$sanger2\n";

$response = $ua->get("http://tazendra.caltech.edu/~azurebrd/sanger/loci_all.txt");
my $local = $response->content;

if ($sanger eq $local) { 1; }	# nothing to be done
else { 
  my (@text) = split/./, $local;
  my $textsize = scalar(@text);
  if ($textsize < 10000) { 
    my $user = 'automated sanger getting script';
    my $email = 'vanauken@its.caltech.edu';
#     my $email = 'azurebrd@tazendra.caltech.edu';
    my $subject = 'didn\'t update sanger file because of small file size';
    my $body = "loci_all.txt only has $textsize characters";
    &mailer($user, $email, $subject, $body); }
  else {  
    my $outfile = $directory . '/loci_all.txt';
    open (OUT, ">$outfile") or die "Cannot open $outfile : $!";
    print OUT "$sanger"; 
    close (OUT) or die "Cannot close $outfile : $!";
    
    $outfile = $directory . '/old/sanger_loci_all.txt.' . $date;
    open (OUT, ">$outfile") or die "Cannot open $outfile : $!";
    print OUT "$sanger"; 
    close (OUT) or die "Cannot close $outfile : $!"; }
}

$response = $ua->get("http://www.sanger.ac.uk/Projects/C_elegans/LOCI/genes2molecular_names.txt");

$sanger = '';
if ($response->is_success) { $sanger = $response->content;  }
  else { die $response->status_line; }

$response = $ua->get("http://tazendra.caltech.edu/~azurebrd/sanger/genes2molecular_names.txt");
$local = $response->content;


if ($sanger eq $local) { 1; }	# nothing to be done
else { 
  my (@text) = split/./, $local;
  my $textsize = scalar(@text);
  if ($textsize < 10000) {
    my $user = 'automated sanger getting script';
    my $email = 'vanauken@its.caltech.edu';
#     my $email = 'azurebrd@tazendra.caltech.edu';
    my $subject = 'didn\'t update sanger file because of small file size';
    my $body = "genes2molecular_names.txt only has $textsize characters";
    &mailer($user, $email, $subject, $body); }

  else {  
    my $outfile = $directory . '/genes2molecular_names.txt';
    open (OUT, ">$outfile") or die "Cannot open $outfile : $!";
    print OUT "$sanger\n"; 
    close (OUT) or die "Cannot close $outfile : $!";
    
    $outfile = $directory . '/old/sanger_genes2molecular_names.txt.' . $date;
    open (OUT, ">$outfile") or die "Cannot open $outfile : $!";
    print OUT "$sanger\n"; 
    close (OUT) or die "Cannot close $outfile : $!"; }
}


  # Query aceserver for names that match any wbgene, based on Igor's code.  2006 07 08
$|=9;   #turn off output caching
# print "Connecting to database...";
my $db = Ace->connect('sace://aceserver.cshl.org:2005') || die "Connection failure: ", Ace->error;
# my $db = Ace->connect(-path => '/home/igor/AceDB',  -program =>
# '/home/igor/AceDB/bin/tace') || die print "Connection failure: ", Ace->error;
# print "done\n";
my $wbgenes_to_words;
my $query="find gene live AND species=\"*elegans\"";
my @genes=$db->find($query);
foreach (@genes) {
    my @names=();
    push @names, $_->CGC_name;
    push @names, $_->Sequence_name;
    push @names, $_->Molecular_name;
    push @names, $_->Other_name;
    my %name_hash=();
    foreach my $n (@names) { $name_hash{$n}=1; }
    foreach my $k (keys %name_hash) { $wbgenes_to_words .= "$_\t$k\n"; }
}
my (@text) = split/./, $wbgenes_to_words;
my $textsize = scalar(@text);
my $outfile = $directory . '/wbgenes_to_words.txt';
if ($textsize > 10000) {
  open (OUT, ">$outfile") or die "Cannot open $outfile : $!";
  print OUT "$wbgenes_to_words\n"; 
  close (OUT) or die "Cannot close $outfile : $!";
  
  $outfile = $directory . '/old/wbgenes_to_words.txt.' . $date;
  open (OUT, ">$outfile") or die "Cannot open $outfile : $!";
  print OUT "$wbgenes_to_words\n"; 
  close (OUT) or die "Cannot close $outfile : $!"; }

