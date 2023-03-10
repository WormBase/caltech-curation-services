#!/usr/bin/perl -w

# check OA fields for postgres data with html entities to convert to unicode
# 2021 04 11

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 decode encode);
use HTML::Entities;


my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;


use lib qw( /home/postgres/public_html/cgi-bin/oa/ );           # to get tables/fields and which ones to split as multivalue
use wormOA;

# my $datatype = 'pic';


my $datatype_list_href = &populateWormDatatypeList();
my %datatypes = %$datatype_list_href;

foreach my $datatype (sort keys %datatypes) {
  print qq(D $datatype D\n);
  my ($fieldsRef, $datatypesRef) = &initModFields($datatype, 'two1823');
  my %fields = %$fieldsRef;
  # my %datatypes = %$datatypesRef;
  foreach my $table (sort keys %{ $fields{$datatype} }) {
    my $output = '';
#     next unless ($table eq 'phen_remark');
    next if ($table eq 'id');             # skip pgid column
    $result = $dbh->prepare( "SELECT * FROM ${datatype}_$table WHERE ${datatype}_$table IS NOT NULL;" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
    while (my @row = $result->fetchrow) {
      next unless $row[1];
      if ($row[1] =~ m/&\S+?;/) {		# must have something that someone might have type as an html entity, otherwise will convert weird chracters into other weird characters
        my $before = $row[1];

        my $after = $row[1]; 
        my (@html) = $row[1] =~ m/(&\S+?;)/g;
        foreach my $html (@html) {
          my $utf = &htmlToUtf8($html);
#           print qq(HTML $html TO UTF $utf END\n);
          $after =~ s/$html/$utf/g;
        }

# doing conversion of the whole line
#     #     my $after = &htmlToUtf8($before);		# this over-escapes the unicode into having extra character, e.g. Âµm
#         my $after = &htmlToUtf8($before);

        if ($before ne $after) { $output .= qq($datatype\t$table\t$row[0]\t$before\t$after\n); }
      }
    }
    if ($output) {
      my $outfile = "diff/${datatype}_${table}.diff";
      open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
      print OUT $output;
      close (OUT) or die "Cannot close $outfile : $!";
    }
  }
}


# my $unistring = '';
# $result = $dbh->prepare( "SELECT * FROM app_phen_remark WHERE joinkey = '26100';" );
# $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
# while (my @row = $result->fetchrow) { $unistring = $row[1]; }

# my $testfile = 'test_unicode_input';
# open (IN, "<$testfile") or die "Cannot open $testfile : $!";
# my $unistring = <IN>; chomp $unistring;
# close (IN) or die "Cannot close $testfile : $!";
 
# my $unistring = '5 © as μm (37°C, 38.5°F';
# print qq(ST $unistring ST\n);
# my $decoded = decode('utf-8', $unistring);
# print qq(DEC $unistring ODE\n);
# my $conv = &utf8ToHtml($unistring);
# print qq(CO $conv NV\n);
# my $overconv = &utf8ToHtml($conv);
# print qq(OV $overconv NV\n);
 
#  my $htmlstring = '5 &mu;m (37&deg;C, 38.5&deg;F';
#  print qq(HTML $htmlstring STR\n);
#  my $decoded = encode('utf-8', decode_entities($htmlstring));
#  print qq(DE $decoded COD\n);
#  my $overdecoded = encode('utf-8', decode_entities($decoded));
#  print qq(OV $overdecoded COD\n);


sub utf8ToHtml {
  my $value = shift;
  return encode_entities(decode('utf-8', $value));
} # sub utf8ToHtml

# into string with wide characters
# sub htmlToUtf8 {
#   my $value = shift;
#   return decode_entities($value);
# } # sub utf8ToHtml

# with over-escaped characters
sub htmlToUtf8 {
  my $value = shift;
  return encode('utf-8', decode_entities($value));
} # sub utf8ToHtml

__END__

$result = $dbh->prepare( "SELECT * FROM two_comment LIMIT 5" );
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

