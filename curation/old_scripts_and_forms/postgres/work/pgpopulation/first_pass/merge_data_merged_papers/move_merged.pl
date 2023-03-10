#!/usr/bin/perl -w

# look at all invalid wbpapers that have been merged into other wbpapers.  
# If the invalid papers have cur_ table data, append them to the cur_ table 
# of the paper that it has been merged into.  UPDATE with | -- merged from WBPaper
# if already has entry (and update timestamp if more recent), INSERT with same
# data and timestamp if new entry.  update cur_curator (don't say it was merged or 
# append stuff).  Check if the data for a paper already exists by doing a match 
# for data to move inside data that it's being appended into.  Possibly need to
# run this periodically, but not setting a cronjob.  2009 02 12
#
# account for wpa_rnai_int_done and wpa_*_curation tables having data that needs
# to be merged.  2009 02 18


use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my @PGparameters = qw(curator fullauthorname
                      genesymbol mappingdata genefunction generegulation
                      expression marker microarray rnai lsrnai transgene overexpression
                      structureinformation functionalcomplementation
                      invitro mosaic site antibody covalent
                      extractedallelenew newmutant nonntwo
                      sequencechange geneinteractions geneproduct
                      structurecorrectionsanger structurecorrectionstlouis
                      sequencefeatures massspec cellfunction
                      ablationdata newsnp stlouissnp supplemental
                      chemicals humandiseases comment);
my @wpa_tables = qw( wpa_rnai_int_done wpa_rnai_curation wpa_transgene_curation wpa_allele_curation );

my %wpa;

my $result = $conn->exec( "SELECT * FROM wpa ORDER BY wpa_timestamp;" );
while (my @row = $result->fetchrow) {
  if ($row[3] eq 'valid') { delete $wpa{invalid}{$row[0]}; }
    else { $wpa{invalid}{$row[0]}++; }
} # while (@row = $result->fetchrow)

$result = $conn->exec( "SELECT * FROM wpa_identifier WHERE wpa_identifier ~ '^00' OR wpa_identifier ~ '^WBPaper' ORDER BY wpa_timestamp;" );
while (my @row = $result->fetchrow) {
  if ($row[1] =~ m/WBPaper/) { $row[1] =~ s/WBPaper//; }
  if ($row[3] eq 'valid') { $wpa{mergedinto}{$row[1]}{$row[0]}++; }
    else { delete $wpa{mergedinto}{$row[1]}{$row[0]}; }
} # while (@row = $result->fetchrow)

foreach my $joinkey (sort keys %{ $wpa{invalid} }) {
  if ($wpa{mergedinto}{$joinkey}) {
    foreach my $mergedinto (sort keys %{ $wpa{mergedinto}{$joinkey} }) {
      &mergeFPData($joinkey, $mergedinto);
    } # foreach my $mergedinto (sort keys %{ $wpa{mergedinto}{$joinkey} }) 
  } # if ($wpa{mergedinto}{$joinkey})
} # foreach my $joinkey (sort keys %{ $wpa{invalid} })

sub mergeFPData {
  my ($joinkey, $mergedinto) = @_;
  foreach my $table (@wpa_tables) {
    $result = $conn->exec( "SELECT * FROM $table WHERE joinkey = '$joinkey' ORDER BY wpa_timestamp DESC;" );
    my @row = $result->fetchrow;
    next unless ($row[1]);
    my $data = $row[1];
    my $time = $row[5];
    $result = $conn->exec( "SELECT * FROM $table WHERE joinkey = '$mergedinto' AND $table = '$data' AND wpa_timestamp = '$time';" );
    my @row2 = $result->fetchrow;
    unless ($row2[1]) {
      foreach (@row) { unless ($_) { $_ = 'NULL'; } else { $_ = "\'$_\'"; } }
      my $command = "INSERT INTO $table VALUES ('$mergedinto', $row[1], $row[2], $row[3], $row[4], $row[5]);";
      print "$command\n";
# UNCOMMENT TO MERGE
#       $result = $conn->exec( $command );
    }

  } # foreach my $table (@wpa_tables)
#       print "$joinkey NOW $mergedinto\n"; 
  foreach my $table (@PGparameters) {
    my ($tomerge, $merged, $odate, $mdate);
    $result = $conn->exec( "SELECT * FROM cur_$table WHERE joinkey = '$joinkey';" );
    my @row = $result->fetchrow;
    next unless ($row[1]);
    if ($row[1] =~ m//) { $row[1] =~ s///g; }
    $tomerge = $row[1];
    my $tdate = $row[2];
    $result = $conn->exec( "SELECT * FROM cur_$table WHERE joinkey = '$mergedinto';" );
    @row = $result->fetchrow;
    $merged = $row[1];
    if ($tomerge) {		# data existed, merge
      my $pgcommand = '';
      if ($merged) {		# UPDATE
        my $set_to = '';
        if ($merged =~ m//) { $merged =~ s///g; }
        my $tomerge_regex = $tomerge; 
        $tomerge_regex =~ s/\//\\\//g;
        $tomerge_regex =~ s/\(/\\\(/g;
        $tomerge_regex =~ s/\)/\\\)/g;
        $tomerge_regex =~ s/\+/\\\+/g;
        next if ($merged =~ m/$tomerge_regex/);	# skip if stuff to merge already mentioned in field to merge into
        $mdate = $row[2];
        my ($ttime) = $tdate =~ m/^(\d{4}\-\d{2}\-\d{2})/; $ttime =~ s/\-//g; 
        my ($mtime) = $mdate =~ m/^(\d{4}\-\d{2}\-\d{2})/; $mtime =~ s/\-//g; 
        if ($ttime > $mtime) { 			# if stuff to merge is more recent, change date, change curator field
          my $pgthing = "UPDATE cur_$table SET cur_timestamp = '$tdate' WHERE joinkey = '$mergedinto'";
          print "$pgthing\n";
# UNCOMMENT TO MERGE
#           $result = $conn->exec( $pgthing );
#           print "$mergedinto from $joinkey $table : $tdate more recent than $mdate\n";	# UPDATE timestamp
          if ($table eq 'curator') { 	# update curator field if more recent time
#             print "$mergedinto from $joinkey $table : set curator $tomerge\n";		# UPDATE curator
            $set_to = $tomerge; 
          }
        }
        if ($table ne 'curator') { 	# always UPDATE non-curator field
#           $pgcommand = "$merged | $tomerge -- merged from WBPaper$joinkey"; 
          $set_to = "$merged | $tomerge -- merged from WBPaper$joinkey"; 
        } 
        if ($set_to) { 
          $pgcommand = "UPDATE cur_$table SET cur_$table = '$set_to' WHERE joinkey = '$mergedinto';";
        }
      }
      else {			# INSERT   no previous data, move
#         $pgcommand = "$tomerge, $tdate";
        if ($table ne 'curator') { $tomerge .= " -- merged from WBPaper$joinkey"; }
        if ($row[0]) { $pgcommand = "UPDATE cur_$table SET cur_$table = '$tomerge' WHERE joinkey = '$mergedinto';"; }
          else { $pgcommand = "INSERT INTO cur_$table VALUES ('$mergedinto', '$tomerge', '$tdate');"; }
      }
      if ($pgcommand) {
        print "$mergedinto from $joinkey $table : $pgcommand\n";
# UNCOMMENT TO MERGE
#         $result = $conn->exec( $pgcommand );
      }
    }
  } # foreach my $table (@PGparameters)
} # sub mergeFPData
__END__

