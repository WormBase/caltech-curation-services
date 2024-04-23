#!/usr/bin/env perl

# populate nnc results based on http://celegans.textpressocentral.org/NNClassification/ 

# Populate nnc data.  Adapted from svm script populate_svm_result.pl
# 
# COPY cur_nncdata TO '/home/postgres/work/pgpopulation/cur_curation/cur_nncdata/cur_nncdata.pg';
# COPY cur_nncdata FROM '/home/postgres/work/pgpopulation/cur_curation/cur_nncdata/cur_nncdata.pg';
# 
# a view for Valerio to see svm + nnc data all together.  2021 01 20
# My simple union view
# CREATE VIEW cur_blackbox AS
#   SELECT cur_paper, cur_datatype, cur_date, cur_nncdata as cur_blackbox, NULL as cur_version, cur_timestamp FROM cur_nncdata UNION SELECT * FROM cur_svmdata;
# 
# Valerio's view
# CREATE VIEW cur_blackbox AS
# SELECT a.cur_paper, a.cur_datatype, a.cur_nncdata as cur_blackbox, a.cur_date, a.cur_timestamp FROM 
#   (SELECT cur_paper, cur_datatype, cur_date, cur_nncdata, NULL as cur_version, cur_timestamp, 2 as cur_preference FROM cur_nncdata
#   UNION SELECT *, 1 as cur_preference FROM cur_svmdata) AS a LEFT OUTER JOIN 
#     (SELECT cur_paper, cur_datatype, cur_date, cur_nncdata, NULL as cur_version, cur_timestamp, 2 as cur_preference FROM cur_nncdata 
#      UNION SELECT *, 1 as cur_preference FROM cur_svmdata) AS b 
#   ON a.cur_paper = b.cur_paper 
#     AND a.cur_datatype = b.cur_datatype 
#     AND a.cur_preference < b.cur_preference 
#     WHERE b.cur_paper IS NULL 
#   ORDER BY a.cur_paper, a.cur_datatype;
# GRANT SELECT ON cur_blackbox TO acedb;
# GRANT SELECT ON cur_blackbox TO azurebrd;
# GRANT SELECT ON cur_blackbox TO apache;
# GRANT SELECT ON cur_blackbox TO "www-data";
#
# GRANT SELECT ON cur_blackbox TO valerio;
# 
# Runs everyday at 4am  Chris + Daniela.  2021 01 25
# 0 4 * * * /home/postgres/work/pgpopulation/cur_curation/cur_nncdata/populate_nnc_result.pl
#
# Dockerized for crontab, but no longer output to logfile. 2023 03 15
#
# Updated url move to http://textmining.textpresso.org/  2024 04 22

# 0 4 * * * /usr/lib/scripts/pgpopulation/cur_curation/cur_nncdata/populate_nnc_result.pl



use strict;
use CGI;
use DBI;
use Jex;			# mailer
use LWP::Simple;
use Dotenv -load => '/usr/lib/.env';

my $starttime = time;

my $dbh = DBI->connect ( "dbi:Pg:dbname=$ENV{PSQL_DATABASE};host=$ENV{PSQL_HOST};port=$ENV{PSQL_PORT}", "$ENV{PSQL_USERNAME}", "$ENV{PSQL_PASSWORD}") or die "Cannot connect to database!\n";
# my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n";
my $result;

# new fields : expression_cluster genesymbol humandisease transporter

my @datatypes = qw( antibody catalyticact expression_cluster geneint geneprod genereg genesymbol humandisease newmutant otherexpr overexpr rnai seqchange structcorr transporter );

# my @datatypes = qw( antibody catalyticact geneint geneprod genereg newmutant otherexpr overexpr rnai seqchange structcorr );	# svm categories
my %datatypes; foreach (@datatypes) { $datatypes{$_}++; }

my %hash;
my %pg;
my %datesDone;				# dates and subdirectory names in caprica already in postgres

my %modifierWholePaper;			# the modifier refers to the whole paper
$modifierWholePaper{'concat'}++;
# $modifierWholePaper{'mainonly'}++;

my %badTypes;
my $err_text = '';


# Only want .concat files, for Daniela.  2013 01 14
# my %mainOnly;
# my $mainOnly_file = '/home/postgres/work/pgpopulation/cur_curation/cur_svmdata/main_only';
# open (IN, "<$mainOnly_file") or die "Cannot open $mainOnly_file : $!";
# while (my $paper = <IN>) { chomp $paper; $paper =~ s/^WBPaper//; $mainOnly{$paper}++; }
# close (IN) or die "Cannot close $mainOnly_file : $!";


&populateFromPg();

sub populateFromPg {
  $result = $dbh->prepare( "SELECT * FROM cur_nncdata" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
#     my ( $joinkey, $modifier, $type, $date, $flag, $version, $timestamp ) = @row;
    my ( $joinkey, $type, $date, $flag, $version, $timestamp ) = @row;
    $datesDone{$date}++;
#     $pg{"$joinkey\t$modifier\t$type\t$date"} = $flag;
    $pg{"$joinkey\t$type\t$date"} = $flag;
  }
}

# my $root_url = 'http://131.215.52.209/celegans/svm_results/';
# my $root_url = 'http://svm.textpresso.org/celegans/svm_results/';
# my $root_url = 'http://celegans.textpressocentral.org/NNClassification/';	# doesn't work because of masked forwarding
# my $root_url = 'http://textpressocentral.org:9000/NNClassification/';
my $root_url = 'http://textmining.textpresso.org/NNClassification/';
# print "Display of data from date directories from $root_url<br />\n";


my %validFlag;
$validFlag{"HIGH"}++;
$validFlag{"MEDIUM"}++;
$validFlag{"LOW"}++;
$validFlag{"NEG"}++;
my %invalidFlags;
my %skipFlag;
$skipFlag{"</body>"}++;
$skipFlag{"</html>"}++;
$skipFlag{"<body>"}++;
$skipFlag{"<html>"}++;


  my $count = 0;
  my $root_page = get $root_url;
# this is timing out from the new celegans.textpressocentral.org
#   print "R $root_page\n";

# __END__
  my (@dates) = $root_page =~ m/<a href=\"([\-\d]+)\/\">/g;
  foreach my $date_string (@dates) {
# print qq(D $date_string\n);
#     next unless ($date eq '20121210');			# to get only a specific directory date
    my $date = $date_string;
    $date =~ s/-//g;
    ($date) = $date =~ m/^(\d{8})/;
    next if ($datesDone{$date});				# already been processed, don't need this
#     if ($date =~ m/\D/) { print "NO DATE $date\n"; }
#     $count++; last if ($count > 4);
    my $date_url = $root_url . $date_string . '/';
#     print "<a href=$date_url>$date_url</a><br />\n";
    my $date_page = get $date_url;
# print qq(DP $date_page DP\n);
# <tr><td class="n"><a href="geneint.html">geneint.html</a></td><td class="m">2021-Jan-16 03:22:43</td><td class="s">0.5K</td><td class="t">text/html</td></tr>

    my (@date_types) = $date_page =~ m/<a href=\"([\.\w]+)\"/g;
    foreach my $date_type (@date_types) {
# print qq(D $date DT $date_type\n);
      my ($type) = $date_type =~ m/^(\w+).html$/;
#       my ($type) = $date_type =~ m/^[\d_]+_(?:and_missedPaper_)?(\w+)$/;
#       unless ($type) { $err_text .= "no type match for $date_type in $date_url\n"; next; }
      next unless ($type);
# print qq(D $date DT $date_type T $type\n);
#       next if ($type eq 'antibody');				# skip antibody for Xiaodong, but Yuling will keep generating the data.  changed mind and kept it.  2014 11 03
      if ($type eq 'geneprod_GO') { $type = 'geneprod'; }
      if ($type eq 'catalytic_act') { $type = 'catalyticact'; }
      unless ($datatypes{$type}) { $badTypes{$type}{$date_url}++; next; }
#       print $type;
      my $date_type_url = $date_url . $date_type;
#       print "<a href=$date_type_url>$date_type_url</a><br />\n";
      my $date_type_results_page = get $date_type_url;
      my (@results) = split/\n/, $date_type_results_page;
      foreach my $result (@results) { 
# print qq(R $result R\n);
        my ($flag, @junk) = split/\s/, $result;
        my ($joinkey) = $result =~ m/WBPaper(\d+)/;
        if ($validFlag{$flag}) { 
# print qq(J $joinkey F $flag\n);
#             if ($result =~ m/\"/) { $result =~ s/\"//g; }
#             my ($paper, $flag) = split/\t/, $result;
#             next unless ($paper =~ m/^WBPaper[\S]+/);
#             my ($joinkey, $modifier) = &getPaperAndModifier($paper);
# #             if ($mainOnly{$joinkey}) { $modifier = 'mainonly'; }	# remove this if mainonly is not allowed
#             next unless ($modifierWholePaper{$modifier});
            my ($tabKey) = &makeTabKey( $joinkey, $type, $date );
            next if ($pg{$tabKey});			# skip if already in postgres
# print qq($tabKey\n);
            $hash{$tabKey} = $flag; }
          elsif ($skipFlag{$flag}) { 1; }
          else { $invalidFlags{$flag}++; }
      }
    } # foreach my $type (@types)

#     my $fn_date_url = $date_url . 'checkFalseNegatives/';
#     my $fn_date_page = get $fn_date_url;
# #     unless ( $fn_date_page ) { $err_text .= "no URL result for $fn_date_url\n"; next; }
#     next unless ( $fn_date_page );		# some old directories have no FP directory
#     my (@fn_date_types) = $fn_date_page =~ m/<a href=\"(\w+)\"/g;
#     foreach my $fn_date_type (@fn_date_types) {
#       my ($type) = $fn_date_type =~ m/^[\d_]+_(?:and_missedPaper_)?checkFN_(\w+)$/;
# #       unless ($type) { $err_text .= "no type match for $fn_date_type in $fn_date_url\n"; next; }
#       next unless ($type);
#       if ($type eq 'geneprod_GO') { $type = 'geneprod'; }
#       if ($type eq 'catalytic_act') { $type = 'catalyticact'; }
#       unless ($datatypes{$type}) { $badTypes{$type}{$fn_date_url}++; next; }
# #       print $type;
#       my $fn_date_type_url = $fn_date_url . $fn_date_type;
# #       print "<a href=$fn_date_type_url>$fn_date_type_url</a><br />\n";
#       my $fn_date_type_results_page = get $fn_date_type_url;
#       my (@results) = split/\n/, $fn_date_type_results_page;
#       foreach my $result (@results) { 
#         next unless ($result =~ m/^(WBPaper[\S]+)/);
#         my $paper = $1;
#         my ($joinkey, $modifier) = &getPaperAndModifier($paper);
# #         if ($mainOnly{$joinkey}) { $modifier = 'mainonly'; }	# remove this if mainonly is not allowed
#         next unless ($modifierWholePaper{$modifier});
#         my $flag = 'NEG';
#         my ($tabKey) = &makeTabKey( $joinkey, $modifier, $type, $date );
#         next if ($pg{$tabKey});			# skip if already in postgres
#         $hash{$tabKey} = $flag;
#       }
#     } # foreach my $type (@types)
  } # foreach my $subdir (@subdirs)


my @pgcommands;
foreach my $tabKey (sort keys %hash) {
#   my ( $joinkey, $modifier, $datatype, $date ) = split/\t/, $tabKey;
  my ( $joinkey, $datatype, $date ) = split/\t/, $tabKey;
#   my $version = '1';
#   if ( ( ($datatype eq 'otherexpr') || ($datatype eq 'genereg') ) && ($date > 20120628) ) { 
#       $version = '2';									# those two datatypes after that date v2
#       if ( ($date eq '20121130') || ( $date eq '20121210') ) { $version = 1; } }	# large batches of concat still v1
#     elsif ( $date < 20111112 ) { $version = '0'; }					# ruihua stuff v0
#     else { $version = '1'; }								# everything else v1
# #	 If you want it to be complete, I would say everything before and 20111111
# #	 maybe(when I took over from ruihua) to be version 0 for all datatypes.
# #	 Everything after that to be version 1 (as I took over) for all datatypes.
# #	 And for the above two datatypes and from (20121103) to be version 2?
# #        Except for large batches 20121130 20121210, which are version 1.
  my $flag = $hash{$tabKey};
#   push @pgcommands, qq(INSERT INTO cur_nncdata VALUES('$joinkey', '$modifier', '$datatype', '$date', '$flag', '$version'));
#   push @pgcommands, qq(INSERT INTO cur_nncdata VALUES('$joinkey', '$datatype', '$date', '$flag', '$version'));
  push @pgcommands, qq(INSERT INTO cur_nncdata VALUES('$joinkey', '$datatype', '$date', '$flag'));
#   print "$tabKey\t$flag\n";
} # foreach my $tabKey (sort keys %hash)

# my $current_time = &getSimpleSecDate();
# my $logfile = '/home/postgres/work/pgpopulation/cur_curation/cur_nncdata/logfile';
# open (OUT, ">>$logfile") or die "Cannot append to $logfile : $!";
if (scalar @pgcommands > 0) {
#   print OUT "START $current_time\n";
  foreach my $pgcommand (@pgcommands) {
#     print OUT "$pgcommand\n";
# UNCOMMENT TO POPULATE
    $dbh->do( $pgcommand );
  } # foreach my $pgcommand (@pgcommands)
}



foreach my $invalidFlag (sort keys %invalidFlags) {
  $err_text .= "invalid flag : $invalidFlag\n";
} # foreach my $invalidFlag (sort keys %invalidFlags)

foreach my $badType (sort keys %badTypes) {
  $err_text .= "bad type : $badType\n";
  foreach my $bad_data_type (sort keys %{ $badTypes{$badType} }) {
    $err_text .= "$bad_data_type\n";
  } # foreach my $bad_data_type (sort keys %{ $badTypes{$badType} })
  $err_text .= "\n";
} # foreach my $badType (sort keys %badTypes)

if ($err_text) { 
#   print OUT "\n\nERRORS\n$err_text\n\n"; 
  my $user = 'populate_nnc_result.pl';
  my $email = 'draciti@caltech.edu, cgrove@caltech.edu';
#   my $email = 'azurebrd@tazendra.caltech.edu';
  my $subject = "Errors in populate_nnc_result.pl neural network classification";
  my $body = $err_text;
# PUT THIS BACK to email about errors
#   &mailer($user, $email, $subject, $body);    # email errors to curators to user
} # if ($err_text) 
# if (scalar @pgcommands > 0) { print OUT "END $current_time\n"; }
# close (OUT) or die "Cannot close $logfile : $!";


sub makeTabKey {
  my ( $joinkey, $type, $date ) = @_;
  my @array = ();
  push @array, $joinkey;
  push @array, $type;
  push @array, $date;
  my $tabKey = join"\t", @array;
  return $tabKey;
} # sub makeTabKey


# sub getPaperAndModifier {
#   my ($paper) = @_;
#   my ($joinkey, $paperModifier) = ('', 'main');
#   if ($paper =~ m/^WBPaper(\d+)\.(.*)$/) { $joinkey = $1; $paperModifier = $2; }
#     elsif ($paper =~ m/^WBPaper(\d+)$/) { $joinkey = $1; }
#     else { $err_text .= "not a paper nor paper.something : -=${paper}=-\n"; }
#   return ($joinkey, $paperModifier);
# }

# foreach my $paper (sort keys %byPaper) {
# #     print "<tr><td style=\"border-style: dotted\">$paper</td>";
# 
# #     my ($joinkey) = $paper =~ m/(\d+)/;
# #     if ($journal{$joinkey}) { print "<td style=\"border-style: dotted\" class=\"$journal{$joinkey}\">$journal{$joinkey}</td>"; } else { print "<td>&nbsp;</td>"; }
# 
#   foreach my $type (sort keys %{ $byPaper{$paper} }) {
#     next unless ($type);
#     my $result = $byPaper{$paper}{$type};
#     
# #     my $bgcolor = 'white';
# #     if ($result eq 'high')   { $bgcolor = '#FFa0a0'; }
# #     if ($result eq 'medium') { $bgcolor = '#FFc8c8'; }
# #     if ($result eq 'low')    { $bgcolor = '#FFe0e0'; }
# #     print "<td style=\"border-style: dotted; background-color: $bgcolor\">$type - $result</td>";
#   } # foreach my $type (sort keys %{ $byPaper{$paper} })
# #   print "</tr>\n";
# } # foreach my paper (sort keys %byPaper)


__END__

# To delete old cur_ tables
my @cur_tables = qw( cur_ablationdata cur_expression cur_genesymbols cur_newmutant cur_structurecorrection cur_antibody cur_extractedallelename cur_goodphoto cur_newsnp cur_structurecorrectionsanger cur_associationequiv cur_extractedallelenew cur_humandiseases cur_newsymbol cur_structurecorrectionstlouis cur_associationnew cur_fullauthorname cur_invitro cur_nonntwo cur_structureinformation cur_cellfunction cur_functionalcomplementation cur_lsrnai cur_overexpression cur_supplemental cur_cellname cur_genefunction cur_mappingdata cur_rnai cur_synonym cur_chemicals cur_geneinteractions cur_marker cur_sequencechange cur_transgene cur_comment cur_geneproduct cur_massspec cur_sequencefeatures cur_covalent cur_generegulation cur_microarray cur_site cur_curator cur_genesymbol cur_mosaic cur_stlouissnp );

my $dir = '/home/postgres/work/pgpopulation/cur_curation/backup_of_2009_tables/';


foreach my $table (@cur_tables) {
# to get most recent data
#   $result = $dbh->prepare( "SELECT cur_timestamp FROM $table ORDER BY cur_timestamp DESC;" );
#   $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
#   my @row = $result->fetchrow();
#   print "$table\t$row[0]\n";

# to backup data
  my $outfile = $dir . $table;
  my $result = $dbh->do( "COPY $table TO '$outfile'" );

# to drop tables
#   $result = $dbh->do( "DROP TABLE $table;" );
} # foreach my $table (@cur_tables)

__END__
