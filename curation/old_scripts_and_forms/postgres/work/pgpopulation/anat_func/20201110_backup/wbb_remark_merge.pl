#!/usr/bin/perl -w

# merge remark data from wbb_remark, wbb_phenotype, wbb_involved, wbb_notinvolved, wbb_assay
# 2020 07 30
#
# added Insufficient, Unnecessary, Sufficient, Necessary  2020 08 05
#
# skip entries that are just 'CHECKED'.  2020 08 06
#
# separate entries with linebreak into separate entries.  2020 08 07
#
# populated based on tazendra data 2020 11 04, ran again.  raymond's gotten all data out of 
# assay order!=1, so that valerio only looks at order=1.  
# To restore to tables before this script run, use files at
# /home/postgres/work/pgpopulation/anat_func/20201104_backup
# 2020 11 04
#
# Transfer wbb_gene published_as into remark as well.  2020 11 05
#
#
# To restore from back up
# COPY wbb_remark FROM '/home/postgres/work/pgpopulation/anat_func/20200730_remark_merge/pgbackup/wbb_remark.pg.20200814';
# 
# To delete changes made after <date> from this script
# DELETE FROM wbb_remark WHERE wbb_timestamp > '2020-08-14 16:20:01';


use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;


my %obj;
my %orderCounter;
my %phenotype;
my %involved;
my %sufficient;
my %necessary;
my %notinvolved;
my %insufficient;
my %unnecessary;
my %remark;
my %assay;
my %genePublishedAs;

$result = $dbh->prepare( "SELECT * FROM wbb_remark WHERE wbb_evitype = 'none' ORDER BY wbb_timestamp" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  $obj{$row[0]}++;
  $remark{$row[0]}{$row[1]}{data} = $row[2];
#   $remark{$row[0]}{$row[1]}{timestamp} = $row[5];
}

# $result = $dbh->prepare( "SELECT * FROM wbb_assay WHERE wbb_cond IS NOT NULL;" );	# this was skipping overwritten data
$result = $dbh->prepare( "SELECT * FROM wbb_assay ORDER BY wbb_timestamp;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  $obj{$row[0]}++;
  $assay{$row[0]}{$row[1]}{data} = $row[3];
#   $remark{$row[0]}{$row[1]}{timestamp} = $row[4];
}

$result = $dbh->prepare( "SELECT * FROM wbb_gene WHERE wbb_evitype = 'Published_as' ORDER BY wbb_timestamp" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  $obj{$row[0]}++;
  if ($row[3]) {
    $genePublishedAs{$row[0]}{data} = $row[3];
#   $genePublishedAs{$row[0]}{$row[1]}{timestamp} = $row[4];
  }
}

$result = $dbh->prepare( "SELECT * FROM wbb_notinvolved WHERE wbb_evitype = 'Remark' ORDER BY wbb_timestamp" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  $obj{$row[0]}++;
  $notinvolved{$row[0]}{$row[1]}{data} = $row[4];
#   $notinvolved{$row[0]}{$row[1]}{timestamp} = $row[5];
}

$result = $dbh->prepare( "SELECT * FROM wbb_notinvolved WHERE wbb_evitype = 'Insufficient' ORDER BY wbb_timestamp" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  $obj{$row[0]}++;
  $insufficient{$row[0]}{$row[1]}{data} = $row[4];
}

$result = $dbh->prepare( "SELECT * FROM wbb_notinvolved WHERE wbb_evitype = 'Unnecessary' ORDER BY wbb_timestamp" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  $obj{$row[0]}++;
  $unnecessary{$row[0]}{$row[1]}{data} = $row[4];
}

$result = $dbh->prepare( "SELECT * FROM wbb_involved WHERE wbb_evitype = 'Remark' ORDER BY wbb_timestamp" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  $obj{$row[0]}++;
  $involved{$row[0]}{$row[1]}{data} = $row[4];
#   $involved{$row[0]}{$row[1]}{timestamp} = $row[5];
}
$result = $dbh->prepare( "SELECT * FROM wbb_involved WHERE wbb_evitype = 'Sufficient' ORDER BY wbb_timestamp" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  $obj{$row[0]}++;
  $sufficient{$row[0]}{$row[1]}{data} = $row[4];
}
$result = $dbh->prepare( "SELECT * FROM wbb_involved WHERE wbb_evitype = 'Necessary' ORDER BY wbb_timestamp" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  $obj{$row[0]}++;
  $necessary{$row[0]}{$row[1]}{data} = $row[4];
}

$result = $dbh->prepare( "SELECT * FROM wbb_phenotype WHERE wbb_evitype = 'Remark' ORDER BY wbb_timestamp" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  $obj{$row[0]}++;
  $phenotype{$row[0]}{1}{data} = $row[3];
#   $phenotype{$row[0]}{1}{timestamp} = $row[4];
}

my @pgcommands;
foreach my $obj (sort keys %obj) {
#   next unless ($obj =~ m/0010/);
  my $current = 0;
  my %data;
  foreach my $order (sort keys %{ $remark{$obj} }) {
    if ($remark{$obj}{$order}{data}) { $current = $order; } }
  foreach my $order (sort keys %{ $phenotype{$obj} }) {
    if ($phenotype{$obj}{$order}{data}) { 
      my $data = $phenotype{$obj}{$order}{data};
      $data{$data}++;
    }
  } # foreach my $order (sort keys %{ $phenotype{$obj} })
  foreach my $order (sort keys %{ $involved{$obj} }) {
    if ($involved{$obj}{$order}{data}) { 
      my $data = $involved{$obj}{$order}{data};
      $data =~ s/\'/''/g;
      $data{$data}++;
#       my $timestamp = $involved{$obj}{$order}{timestamp};
#       push @pgcommands, qq(INSERT INTO wbb_remark VALUES ('$obj', '$current', '$data', 'none', NULL, '$timestamp'));
    }
  } # foreach my $order (sort keys %{ $involved{$obj} })
  foreach my $order (sort keys %{ $sufficient{$obj} }) {
    if ($sufficient{$obj}{$order}{data}) { 
      my $data = $sufficient{$obj}{$order}{data};
      $data =~ s/\'/''/g;
      $data{$data}++; }
  } # foreach my $order (sort keys %{ $sufficient{$obj} })
  foreach my $order (sort keys %{ $necessary{$obj} }) {
    if ($necessary{$obj}{$order}{data}) { 
      my $data = $necessary{$obj}{$order}{data};
      $data =~ s/\'/''/g;
      $data{$data}++; }
  } # foreach my $order (sort keys %{ $necessary{$obj} })
  foreach my $order (sort keys %{ $notinvolved{$obj} }) {
    if ($notinvolved{$obj}{$order}{data}) { 
      my $data = $notinvolved{$obj}{$order}{data};
      $data =~ s/\'/''/g;
      $data{$data}++;
    }
  } # foreach my $order (sort keys %{ $notinvolved{$obj} })
  foreach my $order (sort keys %{ $insufficient{$obj} }) {
    if ($insufficient{$obj}{$order}{data}) { 
      my $data = $insufficient{$obj}{$order}{data};
      $data =~ s/\'/''/g;
      $data{$data}++;
    }
  } # foreach my $order (sort keys %{ $insufficient{$obj} })
  foreach my $order (sort keys %{ $unnecessary{$obj} }) {
    if ($unnecessary{$obj}{$order}{data}) { 
      my $data = $unnecessary{$obj}{$order}{data};
      $data =~ s/\'/''/g;
      $data{$data}++;
    }
  } # foreach my $order (sort keys %{ $unnecessary{$obj} })

  if ($genePublishedAs{$obj}{data}) {
    my $data = $genePublishedAs{$obj}{data};
    $data =~ s/\'/''/g;
    $data = 'Published_as ' . $data;
    $data{$data}++;
  } # if ($genePublishedAs{$obj}{data})


  foreach my $order (sort keys %{ $assay{$obj} }) {
    if ($assay{$obj}{$order}{data}) { 
      my $data = $assay{$obj}{$order}{data};
      if ($data =~ m/Remark/) {
        if ($data =~ m/Remark\s+"([^"]+)"/ms) {
          my $remark = $1;
          $remark =~ s///g;
          $remark =~ s/\n//g;
          $remark =~ s/\'/''/g;
          $data{$remark}++; } }
      if ($data =~ m/Genotype/) {
# print qq(START $obj GENOTYPE $data DATA\nEND\n);
        if ($data =~ m/Genotype\s+"([^"]+)"/ms) {
          my $genotype = $1;
          $genotype =~ s///g;
          $genotype =~ s/\n//g;
          $genotype =~ s/\'/''/g;
          $genotype = qq(Genotype "$genotype");
# print qq($obj GENOTYPE $genotype GENOTYPE\n);
          $data{$genotype}++; } }
        
#       my @lines = split/\n/, $data;
#       foreach my $line (@lines) {
#         if ($line =~ m/^Remark (.*)/) { 
#           my $remark = $1; 
#           $remark =~ s/^\s+//;
#           $remark =~ s/\s+$//;
#           $remark =~ s/^"//;
#           $remark =~ s/"$//;
#           $remark =~ s///g;
#           $remark =~ s/\'/''/g;
#           $remark =~ s/^\s+//;
#           $remark =~ s/\s+$//;
#           $data{$remark}++; }
#         elsif ($line =~ m/^Genotype/) { 
#           my $genotype = $line;
#           if ($genotype =~ m/Genotype "/) {
#             $genotype =~ s/Genotype "//; }
#           $genotype =~ s/^\s+//;
#           $genotype =~ s/\s+$//;
#           $genotype =~ s/"$//;
#           $genotype =~ s///g;
#           $genotype =~ s/\'/''/g;
#           $genotype =~ s/^\s+//;
#           $genotype =~ s/\s+$//;
#           $genotype = qq(Genotype "$genotype");
#           $data{$genotype}++; }
#       } # foreach my $line (@lines)
    }
  } # foreach my $order (sort keys %{ $assay{$obj} })

  foreach my $data (sort keys %data) {
    next if ($data eq 'CHECKED');	# skip data that is just the checkbox being checked on
    my @data = split/\n/, $data;
    foreach my $data (@data) {
      $data =~ s///g;
      $current++;
      push @pgcommands, qq(INSERT INTO wbb_remark VALUES ('$obj', '$current', '$data', 'none'));
    }
  }
} # foreach my $obj (sort keys %obj)

foreach my $pgcommand (@pgcommands) {
  print qq($pgcommand\n);
# UNCOMMENT TO POPULATE
#   $dbh->do($pgcommand);
} # foreach my $pgcommand (@pgcommands)

__END__

SELECT * FROM wbb_involved WHERE wbb_evitype = 'Remark' 
SELECT * FROM wbb_phenotype WHERE wbb_evitype = 'Remark' 

SELECT * FROM wbb_remark 
SELECT * FROM wbb_assay WHERE wbb_cond IS NOT NULL;


$result = $dbh->prepare( "SELECT * FROM two_comment" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[1] =~ s///g;
    $row[2] =~ s///g;
    print "$row[0]\t$row[1]\t$row[2]\n";
  } # if ($row[0])
} # while (@row = $result->fetchrow)

__END__

my $result = $dbh->prepare( 'SELECT * FROM two_comment WHERE two_comment ~ ?' );
$result->execute('elegans') or die "Cannot prepare statement: $DBI::errstr\n"; 

$result->execute("doesn't") or die "Cannot prepare statement: $DBI::errstr\n"; 
my $var = "doesn't";
$result->execute($var) or die "Cannot prepare statement: $DBI::errstr\n"; 

my $data = 'data';
unless (is_utf8($data)) { from_to($data, "iso-8859-1", "utf8"); }

my $result = $dbh->do( "DELETE FROM friend WHERE firstname = 'bl\"ah'" );
(also do for INSERT and UPDATE if don't have a variable to interpolate with ? )

can cache prepared SELECTs with $dbh->prepare_cached( &c. );

if ($result->rows == 0) { print "No names matched.\n\n"; }	# test if no return

$result->finish;	# allow reinitializing of statement handle (done with query)
$dbh->disconnect;	# disconnect from DB

http://209.85.173.132/search?q=cache:5CFTbTlhBGMJ:www.perl.com/pub/1999/10/DBI.html+dbi+prepare+execute&cd=4&hl=en&ct=clnk&gl=us

interval stuff : 
SELECT * FROM afp_passwd WHERE joinkey NOT IN (SELECT joinkey FROM afp_lasttouched) AND joinkey NOT IN (SELECT joinkey FROM cfp_curator) AND afp_timestamp < CURRENT_TIMESTAMP - interval '21 days' AND afp_timestamp > CURRENT_TIMESTAMP - interval '28 days';

casting stuff to substring on other types :
SELECT * FROM afp_passwd WHERE CAST (afp_timestamp AS TEXT) ~ '2009-05-14';

to concatenate string to query result :
  SELECT 'WBPaper' || joinkey FROM pap_identifier WHERE pap_identifier ~ 'pmid';
to get :
  SELECT DISTINCT(gop_paper_evidence) FROM gop_paper_evidence WHERE gop_paper_evidence NOT IN (SELECT 'WBPaper' || joinkey FROM pap_identifier WHERE pap_identifier ~ 'pmid') AND gop_paper_evidence != '';

