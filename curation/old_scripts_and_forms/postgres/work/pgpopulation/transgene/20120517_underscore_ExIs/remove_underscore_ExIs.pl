#!/usr/bin/perl -w

# remove underscores from transgenes that are ^WBPaper.*_(Ex|Is).*  2012 05 17
#
# add old names to trp_synonym.  change names in trp_name.  Replace values in other existing OA tables and history tables.  Keep all timestamps except for the trp_synonym which is actually new data.  2012 05 18
#
# live run on tazendra  2012 05 19

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result; my @pgcommands;

my %nameToPgid;
my %trp_synonym;
my %allTrpName;

$result = $dbh->prepare( "SELECT * FROM trp_synonym;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $trp_synonym{$row[0]} = $row[1]; }

$result = $dbh->prepare( "SELECT * FROM trp_name;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $allTrpName{$row[1]}{$row[0]}++; }

$result = $dbh->prepare( "SELECT * FROM trp_name WHERE trp_name ~ '^WBPaper.*_Ex';" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $nameToPgid{$row[1]} = $row[0]; }
$result = $dbh->prepare( "SELECT * FROM trp_name WHERE trp_name ~ '^WBPaper.*_Is';" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $nameToPgid{$row[1]} = $row[0]; }


foreach my $origName (sort keys %nameToPgid) {
  my $pgid = $nameToPgid{$origName};
  my $newName = $origName; $newName =~ s/_Ex/Ex/; $newName =~ s/_Is/Is/;
  if ($allTrpName{$newName}) {
    my $pgids = join", ", sort keys %{ $allTrpName{$newName} };
    print "ERR $newName for $origName already existed for $pgids\n"; 
  }
  my $old_syn = $trp_synonym{$pgid}; my $new_syn = $old_syn;
  if ($new_syn) { $new_syn .= " | $origName"; }
    else { $new_syn = $origName; }
  if ($new_syn =~ m/'/) { $new_syn =~ s/'/''/g; }
  push @pgcommands, "UPDATE trp_name SET trp_name = '$newName' WHERE trp_name = '$origName'";
  push @pgcommands, "UPDATE trp_name_hst SET trp_name_hst = '$newName' WHERE trp_name_hst = '$origName'";
  push @pgcommands, "DELETE FROM trp_synonym WHERE joinkey = '$pgid'";
  push @pgcommands, "INSERT INTO trp_synonym VALUES ('$pgid', '$new_syn')";
  push @pgcommands, "INSERT INTO trp_synonym_hst VALUES ('$pgid', '$new_syn')";
#   print "$pgid\t$origName\t$newName\t$new_syn\n"; 
} # foreach my $name (sort keys %nameToPgid)


my %inPg; my %pgDataOnly;
# my @pgtables = qw( app_transgene app_rescuedby exp_transgene grg_transgene int_transgeneone int_transgenetwo );
my @pgtables = qw( app_transgene app_rescuedby exp_transgene grg_transgene int_transgeneone int_transgenetwo app_transgene_hst app_rescuedby_hst exp_transgene_hst grg_transgene_hst int_transgeneone_hst int_transgenetwo_hst );
foreach my $pgtable (@pgtables) {
  $result = $dbh->prepare( "SELECT * FROM $pgtable WHERE $pgtable IS NOT NULL;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { 
    $inPg{$pgtable}{$row[0]} = $row[1];
    $pgDataOnly{$pgtable}{$row[1]}++;
  }
} # foreach my $pgtable (@pgtables)

foreach my $pgtable (sort keys %pgDataOnly) {
  foreach my $value (sort keys %{ $pgDataOnly{$pgtable} }) {
    foreach my $oldName (sort keys %nameToPgid) {
      if ($value =~ m/$oldName/) {
        my $newName = $oldName; $newName =~ s/_Ex/Ex/; $newName =~ s/_Is/Is/;
        my $oldValue = $value; my $newValue = $value; $newValue =~ s/$oldName/$newName/;
        my $command = "UPDATE $pgtable SET $pgtable = '$newValue' WHERE $pgtable = '$oldValue'";
        push @pgcommands, $command;
#         print "$pgtable $oldValue TO $newValue\n";
#         print "$pgtable $pgid $value matches $oldName\n";
      } # if ($value =~ m/$oldName/)
    } # foreach my $oldName (sort keys %nameToPgid)
  } # foreach my $pgid (sort keys %{ $inPg{$pgtable} })
} # foreach my $pgtable (sort keys %inPg)

foreach my $command (@pgcommands) {
  print "$command\n";
# UNCOMMENT TO CHANGE
#   $dbh->do( $command );
} # foreach my $command (@pgcommands)


__END__

foreach my $pgtable (sort keys %inPg) {
  foreach my $pgid (sort keys %{ $inPg{$pgtable} }) {
    my $value = $inPg{$pgtable}{$pgid};
    foreach my $name (sort keys %nameToPgid) {
      if ($value =~ m/$name/) { print "$pgtable $pgid $value matches $name\n"; }
    } # foreach my $name (sort keys %nameToPgid)
  } # foreach my $pgid (sort keys %{ $inPg{$pgtable} })
} # foreach my $pgtable (sort keys %inPg)


__END__
