#!/usr/bin/perl

# run this every Monday at 4am, to sync with textpresso running every Monday at
# 2am.  2007 07 18
#
# oops, email Kimberly, not me.  2007 08 13
#
# updated to textpresso-dev.caltech.edu  2008 08 06

# 0 5 * * mon /home/postgres/public_html/cgi-bin/data/ccc_gocuration/get_newset.pl
#
# moved files to /home2/postgres/work/pgpopulation/ccc_gocuration/sentences
# compare proteins and components to those in ccc_gene_comp_go and and exclude any
# protein that has been matches to all components, and any component that has been
# matched to all proteins.  Put these bad ones at the end of the sentences for the 
# CGI to display.  If a sentence has no good prot / comp, skip the sentence 
# completely.  2009 05 25
#
# don't email kimberly nothing happenned every day  2010 11 03


# moved into : 
# 0 4 * * * /home/postgres/work/pgpopulation/textpresso/wrapper.sh
# 2009 05 25


use strict;
use LWP::Simple;
use Jex;
use DBI;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my %alreadyPg;

# my $local_dir = '/home/postgres/public_html/cgi-bin/data/ccc_gocuration';
my $local_dir = '/home2/postgres/work/pgpopulation/ccc_gocuration/sentences';
chdir($local_dir) or die "Cannot change directory to $local_dir : $!";

# my $recent_file_name = get "http://main.textpresso.org/azurebrd/ccc_datafiles/recent_cccfile";
# my $recent_file_data = get "http://main.textpresso.org/azurebrd/ccc_datafiles/$recent_file_name";
my $recent_file_name = get "http://textpresso-dev.caltech.edu/azurebrd/ccc_datafiles/recent_cccfile";
my $recent_file_data = get "http://textpresso-dev.caltech.edu/azurebrd/ccc_datafiles/$recent_file_name";

if ($recent_file_data =~ m/^No data for/) { 
    my $user = 'ccc_cron_job';
    my $email = 'vanauken@its.caltech.edu';
#     my $email = 'azurebrd@tazendra.caltech.edu';
    my $subject = "No new data for CCC sentences from textpresso for $recent_file_name";
    my $body = '/home/postgres/public_html/cgi-bin/data/ccc_gocuration/get_newset.pl';
#     &mailer($user, $email, $subject, $body); 	# don't email kimberly nothing happenned every day  2010 11 03
  }
  else {
    &readAlreadyPg();
    my (@lines) = split/\n/, $recent_file_data;
    open (OUT, ">$recent_file_name") or die "Cannot create $recent_file_name : $!";
    my $count = 0;
    foreach my $line (@lines) {
      my ($sfile, $newSentCount, $sentLoc, $prots, $comps, $sent) = split/\t/, $line;
      my (@prots) = split/, /, $prots;
      my (@comps) = split/, /, $comps;
      my @gprots; my @gcomps;				# good comp, good prot
      my @bprots; my @bcomps;				# bad comp, bad prot
      my %gprots; my %gcomps;				# good comp, good prot
      foreach my $prot (@prots) {			# for all prots
        $prot =~ s/\s//g;				# take out spaces from tokenizer
        foreach my $comp (@comps) { 			# for all comps
          unless ($alreadyPg{$prot}{$comp}) { $gcomps{$comp}++; $gprots{$prot}++; } }	# doesn't have that component / prot relationship
      } # foreach my $prot (@prots)
      foreach my $prot (@prots) {			# for all prots
        if ($gprots{$prot}) { push @gprots, $prot; } else { push @bprots, $prot; } }
      foreach my $comp (@comps) { 			# for all comps
        if ($gcomps{$comp}) { push @gcomps, $comp; } else { push @bcomps, $comp; } }
      if ($gprots[0]) {					# if something is good, get good and bad and print it
        $count++;					# maybe should keep the old file count, but making count for this file
        my $gprots = join", ", @gprots; my $gcomps = join", ", @gcomps; 	
        my $bprots = join", ", @bprots; my $bcomps = join", ", @bcomps; 	
        print OUT "$sfile\t$count\t$sentLoc\t$gprots\t$gcomps\t$sent\t$bprots\t$bcomps\n"; }
#       else { print "BAD $line\n"; }			# this would print out excluded lines
    }
#     print OUT "$recent_file_data";
    close (OUT) or die "Cannot close $recent_file_name : $!"; 

    my $good_file_name = $recent_file_name;
    $good_file_name =~ s/recent/good/;
#     my $good_file_data = get "http://main.textpresso.org/azurebrd/ccc_datafiles/$good_file_name";
    my $good_file_data = get "http://textpresso-dev.caltech.edu/azurebrd/ccc_datafiles/$good_file_name";
    open (OUT, ">$good_file_name") or die "Cannot create $good_file_name : $!";
    print OUT "$good_file_data";
    close (OUT) or die "Cannot close $good_file_name : $!";
#     &checkVsFirstpass($good_file_data);	# not sure what the point of this is
}

sub readAlreadyPg {
  my $result = $dbh->prepare( "SELECT ccc_gene, ccc_component FROM ccc_gene_comp_go WHERE ccc_gene IS NOT NULL AND ccc_component IS NOT NULL;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { $alreadyPg{$row[0]}{$row[1]}++; }
} # sub readAlreadyPg

sub checkVsFirstpass {
  my $good_file_data = shift;
  my $false_negative = '';
  my $result = $dbh->prepare( "SELECT * FROM cur_expression WHERE cur_expression IS NOT NULL;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    if ($row[0]) { 
      $row[0] =~ s///g;
      $row[1] =~ s///g;
      $row[2] =~ s///g;
      unless ($good_file_data =~ m/P WBPaper$row[0] S/) { $false_negative .= "@row\n"; }
    } # if ($row[0])
  } # while (@row = $result->fetchrow)
  print "FALSE NEG $false_negative FALSE\n"; 
} # sub checkVsFirstpass


