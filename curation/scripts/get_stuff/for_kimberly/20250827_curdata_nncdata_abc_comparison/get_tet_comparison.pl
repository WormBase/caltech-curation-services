#!/usr/bin/env perl

# compare cur_curdata validated by curators, to cur_nncdata generate by NNC, to ABC tet.

# Generate ABC dump from dev server
# python /home/azurebrd/queries/20250827_kimberly_curdata_nncdata_abc_comparison/query_tet_topics.py > ~/public_html/agr-lit/kimberly/tet_confidence
# 
# wget https://dev.alliancegenome.org/azurebrd/agr-lit/kimberly/tet_confidence

# This doesn't help, need other data from reference and cross_reference
# psql -h literature-prod.cmnnhlso7wdi.us-east-1.rds.amazonaws.com -p 5432 -U postgres -e literature
# \copy topic_entity_tag TO '/home/azurebrd/tet.pg' WITH (FORMAT text, DELIMITER E'\t')


use strict;
use LWP::Simple;
use Jex;
use DBI;
use Dotenv -load => '/usr/lib/.env';



my $result;

my $dbh = DBI->connect ( "dbi:Pg:dbname=$ENV{PSQL_DATABASE};host=$ENV{PSQL_HOST};port=$ENV{PSQL_PORT}", "$ENV{PSQL_USERNAME}", "$ENV{PSQL_PASSWORD}") or die "Cannot connect to database!\n";
my $result;

my $date = &getSimpleDate();

my %nameMap;
$nameMap{'antibody'}     = 'ATP:0000096';
$nameMap{'catalyticact'} = 'ATP:0000061';
$nameMap{'geneint'}      = 'ATP:0000068';
$nameMap{'geneprod'}     = 'ATP:0000069';
$nameMap{'genereg'}      = 'ATP:0000070';
$nameMap{'humdis'}       = 'ATP:0000152';
$nameMap{'newmutant'}    = 'ATP:0000083';
$nameMap{'otherexpr'}    = 'ATP:0000010';
$nameMap{'overexpr'}     = 'ATP:0000084';
$nameMap{'rnai'}         = 'ATP:0000082';
$nameMap{'transporter'}  = 'ATP:0000062';

my %nnc;
my %cur;
my %abc;

foreach my $name (sort keys %nameMap) {
  my $result = $dbh->prepare( "SELECT cur_paper, cur_curdata FROM cur_curdata WHERE cur_datatype = '$name';" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
    if ($row[1] eq 'positive') { $cur{$name}{$row[0]} = 'yes'; }
      elsif ($row[1] eq 'curated') { $cur{$name}{$row[0]} = 'yes'; }
      elsif ($row[1] eq 'negative') { $cur{$name}{$row[0]} = 'no'; }
      elsif ($row[1] eq 'notvalidated') { 1; }		# ignore these
      else { print qq(Unexpected value for $name $row[0] $row[1]\n); }
} }

foreach my $name (sort keys %nameMap) {
  my $result = $dbh->prepare( "SELECT cur_paper, cur_nncdata FROM cur_nncdata WHERE cur_datatype = '$name';" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
    $nnc{$name}{'paper'}{$row[0]} = $row[1];
    $nnc{$name}{'ranking'}{$row[1]}{$row[0]}++;
} }

my $infile = 'tet_confidence';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) {
  chomp $line;
  my ($wbp, $agrkb, $atp, $score) = split/\t/, $line;
  $wbp =~ s/WB:WBPaper//;
  if ($score eq 'High') { $score = 'HIGH'; }
  elsif ($score eq 'Low') { $score = 'LOW'; }
  elsif ($score eq 'Med') { $score = 'MEDIUM'; }
  $abc{$atp}{'ranking'}{$score}{$wbp}++;
}
close (IN) or die "Cannot close $infile : $!";

my $name = 'catalyticact';
my $atp = $nameMap{$name};

# Collect all unique rankings from both abc and nnc
my %all_rankings;
$all_rankings{$_}++ for keys %{ $abc{$atp}{'ranking'} };
$all_rankings{$_}++ for keys %{ $nnc{$name}{'ranking'} };

foreach my $ranking (sort keys %all_rankings) {
  # Initialize counters
  my ($abc_agree, $abc_disagree, $abc_novalid) = (0, 0, 0);
  my ($nnc_agree, $nnc_disagree, $nnc_novalid) = (0, 0, 0);

  # Count for abc
  if (exists $abc{$atp}{'ranking'}{$ranking}) {
    foreach my $paper (keys %{ $abc{$atp}{'ranking'}{$ranking} }) {
      if ($cur{$name}{$paper}) {
        if    ($cur{$name}{$paper} eq 'yes') { $abc_agree++; }
        elsif ($cur{$name}{$paper} eq 'no')  { $abc_disagree++; }
        else                                 { $abc_novalid++; }
      } else {
        $abc_novalid++;
      }
    }
  }

  # Count for nnc
  if (exists $nnc{$name}{'ranking'}{$ranking}) {
    foreach my $paper (keys %{ $nnc{$name}{'ranking'}{$ranking} }) {
      if ($cur{$name}{$paper}) {
        if    ($cur{$name}{$paper} eq 'yes') { $nnc_agree++; }
        elsif ($cur{$name}{$paper} eq 'no')  { $nnc_disagree++; }
        else                                 { $nnc_novalid++; }
      } else {
        $nnc_novalid++;
      }
    }
  }

  # Print side-by-side comparison
  print "$ranking\n";
  print "abc: count_agree $abc_agree\tcount_disagree $abc_disagree\tcount_novalidation $abc_novalid\n";
  print "nnc: count_agree $nnc_agree\tcount_disagree $nnc_disagree\tcount_novalidation $nnc_novalid\n";
  print "\n";
}

__END__

foreach my $name (sort keys %nameMap) {
  next unless ($name eq 'catalyticact');
  my $atp = $nameMap{$name};
  foreach my $ranking (sort keys %{ $abc{$atp}{'ranking'} }) {
    my $count_agree = 0;
    my $count_disagree = 0;
    my $count_novalidation = 0;
    print qq($ranking\n);
    foreach my $paper (sort keys %{ $abc{$atp}{'ranking'}{$ranking} }) {
      if ($cur{$name}{$paper}) {
        if ($cur{$name}{$paper} eq 'yes') { $count_agree++; }
        elsif ($cur{$name}{$paper} eq 'no') { $count_disagree++; }
        else { $count_novalidation++; }
      }
      else { $count_novalidation++; }
    }
    print qq(count_agree        $count_agree\n);
    print qq(count_disagree     $count_disagree\n);
    print qq(count_novalidation $count_novalidation\n);
  }
}

foreach my $name (sort keys %nameMap) {
  next unless ($name eq 'catalyticact');
  foreach my $ranking (sort keys %{ $nnc{$name}{'ranking'} }) {
    my $count_agree = 0;
    my $count_disagree = 0;
    my $count_novalidation = 0;
    print qq($ranking\n);
    foreach my $paper (sort keys %{ $nnc{$name}{'ranking'}{$ranking} }) {
      if ($cur{$name}{$paper}) {
        if ($cur{$name}{$paper} eq 'yes') { $count_agree++; }
        elsif ($cur{$name}{$paper} eq 'no') { $count_disagree++; }
        else { $count_novalidation++; }
      }
      else { $count_novalidation++; }
    }
    print qq(count_agree        $count_agree\n);
    print qq(count_disagree     $count_disagree\n);
    print qq(count_novalidation $count_novalidation\n);
  }
}



__END__

my $url = $ENV{THIS_HOST} . 'priv/cgi-bin/curation_status.cgi?action=listCurationStatisticsPapersPage&select_datatypesource=caltech&select_curator=two1823&listDatatype=transporter&method=allval%20pos&checkbox_cfp=on&checkbox_afp=on&checkbox_str=on&checkbox_nnc=on&checkbox_svm=on';

my $positiveAref = &getJoinkeysFromUrl($url);
my @positive = @$positiveAref;
# print qq(@positive\n);

my $url = $ENV{THIS_HOST} . 'priv/cgi-bin/curation_status.cgi?action=listCurationStatisticsPapersPage&select_datatypesource=caltech&select_curator=two1823&listDatatype=transporter&method=allval%20neg&checkbox_cfp=on&checkbox_afp=on&checkbox_str=on&checkbox_nnc=on&checkbox_svm=on';

my $negativeAref = &getJoinkeysFromUrl($url);
my @negative = @$negativeAref;
# print qq(@negative\n);

my %toAgr;
&getJoinkeyToAgrkb();

my %any; my %pos; my %neg;
foreach my $pos (@positive) { $any{$pos}++; $pos{$pos}++; }
foreach my $neg (@negative) { $any{$neg}++; $neg{$neg}++; }
my $any = join"', '", sort keys %any;

foreach my $joinkey (sort keys %any) {
  my $val = 0;
  if ($pos{$joinkey}) { $val = 1; }
  my $agr = $toAgr{$joinkey};
  print qq($agr\tWB:WBPaper$joinkey\t$val\n);
}

sub getJoinkeyToAgrkb {
  my $result = $dbh->prepare( "SELECT joinkey, pap_identifier FROM pap_identifier WHERE pap_identifier ~ 'AGRKB';" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
    $toAgr{$row[0]} = $row[1]; } }

sub getJoinkeysFromUrl {
  my $url = shift;
  my $pageData = get $url;
  my ($joinkeys) = $pageData =~ m/<textarea.*?>(.*)<\/textarea>/;
  my (@joinkeys) = split/\s+/, $joinkeys;
  my $count = scalar @joinkeys;
#   print qq($count\n);
  return \@joinkeys;
} # sub getJoinkeysFromUrl

# print qq($joinkeys\n);

# my $outfile = $ENV{CALTECH_CURATION_FILES_INTERNAL_PATH} . '/cronjobs/curation_stats/files/curation_status.' . $date . '.html';
# my $outfile = '/home/acedb/cron/curation_stats/files/curation_status.' . $date . '.html';

# open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
# print OUT $pageData;
# close (OUT) or die "Cannot close $outfile : $!";

