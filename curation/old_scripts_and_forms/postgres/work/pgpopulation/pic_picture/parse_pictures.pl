#!/usr/bin/perl -w

# parse .ace data for pictures.  2010 11 23

# TODO enter nodump for all of them  2010 11 30

# done parsing, read to mangolassi, description tag not getting read in.  6 entries have multiple expr.  
# Of those 2 pairs have one with a paper and one without, probably better for Daniela to fix manually
# after going live.  2010 12 10
#
# live run 2010 12 21


use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my %expr_to_paper;
my $result = $dbh->prepare( " SELECT * FROM obo_data_pic_exprpattern ;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    my (@wbpapers) = $row[1] =~ m/(WBPaper\d+)/g;
    $expr_to_paper{$row[0]} = \@wbpapers;
  } # if ($row[0])
} # while (@row = $result->fetchrow)
push @{ $expr_to_paper{"Expr83"} }, "WBPaper00002319";
push @{ $expr_to_paper{"Expr85"} }, "WBPaper00002319";

my $infile = 'Chronograms.ace';
$/ = "";
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $entry = <IN>) {
  next unless ( $entry =~ m/Expr_pattern : \"(.*?)\"/);
  my ($expr) = $entry =~ m/Expr_pattern : \"(.*?)\"/;
  my (@wbpapers) = $entry =~ m/(WBPaper\d+)/g;
  $expr_to_paper{$expr} = \@wbpapers;
} # while (my $entry = <IN>)
close (IN) or die "Cannot close $infile : $!";
$/ = "\n";

my $joinkey = '0';
$result = $dbh->prepare( " SELECT * FROM pic_curator ORDER BY joinkey::integer DESC ;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
my @row = $result->fetchrow(); $joinkey = $row[0];

my @pgcommands;
$infile = 'citace220picture.ace';
$/ = "";
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $entry = <IN>) {
  my %insert; my $error = 0;
  my ($source) = $entry =~ m/Picture : \"(.*?)\"/;
  my (@expr) = $entry =~ m/Expr_pattern\s+\"(.*?)\"/g;
  my $expr = $expr[0];
  if (scalar @expr > 1) { print "ERR $source has many expr @expr\n"; }
  if ($expr_to_paper{$expr}[0]) {
# print "EXPR $expr PAP $expr_to_paper{$expr}[0]\n";
      my $paper = $expr_to_paper{$expr}[0];
      if (scalar @{ $expr_to_paper{$expr} } > 1) { 
        if ($expr_to_paper{$expr}[1] eq 'WBPaper00031006') { $paper = $expr_to_paper{$expr}[1]; }
          elsif ($expr eq 'Expr12') { $paper = 'WBPaper00001926'; }
          else { print "ERR TOO MANY PAPERS $expr @{ $expr_to_paper{$expr} }\n"; $error++; } }
      $insert{pic_paper} = $paper;
#       print "connect $expr to $paper\n";
    }
    elsif ($expr eq 'Expr35') { 
      $insert{pic_contact} = "WBPerson1232";;
#       print "connect $expr to WBPerson1232\n";
    }
    else { 
      $insert{pic_contact} = "WBPerson266";;
#       print "connect $expr to WBPerson266\n";
#       print "ERR $source $expr has no reference\n"; 
# TODO map to WBPerson266 under new table  pic_contact  (need to make the table)
    }
  my $curator = 'WBPerson12028';
  my $nodump = 'NO DUMP';
  next if ($error);
  $joinkey++;
  my $picId = &pad10Zeros($joinkey);
  push @pgcommands, "INSERT INTO pic_name VALUES ('$joinkey', 'WBPicture$picId')";
  push @pgcommands, "INSERT INTO pic_name_hst VALUES ('$joinkey', 'WBPicture$picId')";
  push @pgcommands, "INSERT INTO pic_curator VALUES ('$joinkey', '$curator')";
  push @pgcommands, "INSERT INTO pic_curator_hst VALUES ('$joinkey', '$curator')";
  push @pgcommands, "INSERT INTO pic_nodump VALUES ('$joinkey', '$nodump')";
  push @pgcommands, "INSERT INTO pic_nodump_hst VALUES ('$joinkey', '$nodump')";
  push @pgcommands, "INSERT INTO pic_source VALUES ('$joinkey', '$source')";
  push @pgcommands, "INSERT INTO pic_source_hst VALUES ('$joinkey', '$source')";
  push @pgcommands, "INSERT INTO pic_exprpattern VALUES ('$joinkey', '$expr')";
  push @pgcommands, "INSERT INTO pic_exprpattern_hst VALUES ('$joinkey', '$expr')";
  foreach my $table (sort keys %insert) {
    push @pgcommands, "INSERT INTO $table VALUES ('$joinkey', '$insert{$table}')";
    push @pgcommands, "INSERT INTO ${table}_hst VALUES ('$joinkey', '$insert{$table}')";
  }
# Assign no_dump, curator, source, expr_pattern, reference, and that's it, correct ? -- J Correct And assign IDs starting from 1 and going forward WBPicture0000000001. Thanks!! D 
} # while (my $entry = <IN>)
close (IN) or die "Cannot close $infile : $!";
$/ = "\n";

foreach my $pgcommand (@pgcommands) {
  print "$pgcommand\n";
  $result = $dbh->do( $pgcommand );
} # foreach my $pgcommand (@pgcommands)


sub pad10Zeros {
  my $number = shift;
  if ($number =~ m/^0+/) { $number =~ s/^0+//g; }
  if ($number < 10) { $number = '000000000' . $number; }
  elsif ($number < 100) { $number = '00000000' . $number; }
  elsif ($number < 1000) { $number = '0000000' . $number; }
  elsif ($number < 10000) { $number = '000000' . $number; }
  elsif ($number < 100000) { $number = '00000' . $number; }
  elsif ($number < 1000000) { $number = '0000' . $number; }
  elsif ($number < 10000000) { $number = '000' . $number; }
  elsif ($number < 100000000) { $number = '00' . $number; }
  elsif ($number < 1000000000) { $number = '0' . $number; }
  return $number;
} # sub pad10Zeros


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

