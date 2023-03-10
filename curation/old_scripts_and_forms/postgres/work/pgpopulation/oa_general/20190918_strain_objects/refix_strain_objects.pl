#!/usr/bin/perl -w

# source ftp://ftp.sanger.ac.uk/pub/wormbase/STAFF/pad/Caltech/Strain2WBStrain_conversion.csv

# check oa tables for strain names and update to WBStrain ids.

# fix trp_strain data that was convert substrings of objects, so e.g. UPDATE trp_strain SET trp_strain = '"WBStrain00034472","WBStrain00034473","WBStrain00034468","WBStrain000344680","WBStrain000344681","WBStrain000344682","WBStrain00034483","WBStrain00034484"' WHERE joinkey = '1249' AND trp_strain = 'ST15 | ST16 | ST2 | ST20 | ST21 | ST22 | ST30 | ST35';   instead of the correct mapping for ST20 ST21 etc.   2019 10 08


use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %text; my %obo; my %all;

# $text{app}{strain}++;
# $text{app}{controlstrain}++;
# $text{cns}{strain}++;
$text{trp}{strain}++;

# $obo{app}{parentstrain}++;
# $obo{dis}{strain}++;
# $obo{dis}{modstrain}++;
# $obo{dit}{strain}++;
# $obo{exp}{strain}++;
# $obo{rna}{strain}++;
# 
# $all{app}{strain}++;
# $all{app}{controlstrain}++;
# $all{cns}{strain}++;
$all{trp}{strain}++;

# $all{app}{parentstrain}++;
# $all{dis}{strain}++;
# $all{dis}{modstrain}++;
# $all{dit}{strain}++;
# $all{exp}{strain}++;
# $all{rna}{strain}++;


my %nameToId;
# my $infile = 'Strain2WBStrain_conversion.csv';
# open (IN, "<$infile") or die "Cannot open $infile : $!";
# while (my $line = <IN>) {
#   chomp $line;
#   $line =~ s/^"//g;
#   $line =~ s/"$//g;
#   my ($name, $id) = split/","/, $line;
#   $nameToId{$name} = $id;
# #   print qq(N $name I $id E\n);
# }
# close (IN) or die "Cannot close $infile : $!";

$result = $dbh->prepare( "SELECT * FROM obo_name_strain" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  $nameToId{$row[1]} = $row[0];
}


my %bad;
my @pgcommands;

# process text files
foreach my $type (sort keys %text) {
  foreach my $field (sort keys %{ $text{$type} }) {
    my $table = $type . '_' . $field;
#     my $table = $type . '_' . $field . '_hst';
    $result = $dbh->prepare( "SELECT * FROM $table" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) {
      my @data = ();
      next unless $row[1];
      my $orig_entry = $row[1];
      my $new_entry = $row[1];
      my $entry = $row[1];
      if ($entry =~ m/ \| /) { (@data) = split/ \| /, $entry; }
        elsif ($entry =~ m/\|/) { (@data) = split/\|/, $entry; }
        else { push @data, $entry; }
      my %convert;
      foreach my $origName (@data) {
        my $name = $origName;
        $name =~ s/^\s+//g;
        $name =~ s/\s+$//g;
        next unless $name;
        if ($nameToId{$name}) {
          $convert{$name} = $nameToId{$name};
        } else {
          $bad{name}{$name}{$table}{$row[0]}++;
          $bad{table}{$table}{$name}{$row[0]}++;
#           print qq(NO MAP $table\t$row[0]\t$name\n);
        }
      }
#       foreach my $old (sort keys %convert) {
#         my $new = $convert{$old};
#         $new_entry =~ s/\Q$old\E/$new/g;
#       } # foreach my $name (sort keys %convert)
      @data = ();
      if ($entry =~ m/ \| /) { (@data) = split/ \| /, $new_entry; }
        elsif ($entry =~ m/\|/) { (@data) = split/\|/, $new_entry; }
        else { push @data, $new_entry; }
      my @converted = ();
      foreach my $data (@data) {
        $data =~ s/^\s+//g;
        $data =~ s/\s+$//g;
        next unless $data;
        if ($convert{$data}) {
            push @converted, $convert{$data}; }
          else {
            print qq(NO MAP $table\t$data\t@row\n); } }
      $new_entry = join'","', @converted;
      $new_entry = '"' . $new_entry . '"';
      push @pgcommands, qq(UPDATE $table SET $table = '$new_entry' WHERE joinkey = '$row[0]' AND $table = '$orig_entry';);
      push @pgcommands, qq(UPDATE ${table}_hst SET ${table}_hst = '$new_entry' WHERE joinkey = '$row[0]' AND ${table}_hst = '$orig_entry';);
    }
  } # foreach my $field (sort keys %{ $obo{$type} })
} # foreach my $type (sort keys %obo)

foreach my $pgcommand (@pgcommands) {
  print qq($pgcommand\n);
# UNCOMMENT TO POPULATE
#   $dbh->do( $pgcommand );
}



__END__
# process OBO files

foreach my $type (sort keys %obo) {
  foreach my $field (sort keys %{ $obo{$type} }) {
    my $table = $type . '_' . $field;
#     my $table = $type . '_' . $field . '_hst';
    $result = $dbh->prepare( "SELECT * FROM $table" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) {
      my @data = ();
      next unless $row[1];
      my $orig_entry = $row[1];
      my $new_entry = $row[1];
      my $entry = $row[1];
      if ($entry =~ m/"/) {
            $entry =~ s/^"//g;
            $entry =~ s/"$//g; }
      next unless ($entry);
      if ($entry =~ m/","/) { (@data) = split/","/, $entry; }
        elsif ($entry =~ m/ \| /) { (@data) = split/ \| /, $entry; }
        elsif ($entry =~ m/\|/) { (@data) = split/\|/, $entry; }
        else { push @data, $entry; }
      my %convert;
      foreach my $origName (@data) {
        my $name = $origName;
        $name =~ s/^\s+//g;
        $name =~ s/\s+$//g;
        next unless $name;
        if ($nameToId{$name}) {
          $convert{$name} = $nameToId{$name};
        } else {
          $bad{name}{$name}{$table}{$row[0]}++;
          $bad{table}{$table}{$name}{$row[0]}++;
#           print qq(NO MAP $table\t$row[0]\t$name\n);
        }
      }
      foreach my $old (sort keys %convert) {
        my $new = $convert{$old};
        $new_entry =~ s/\Q$old\E/$new/g;
      } # foreach my $name (sort keys %convert)
      push @pgcommands, qq(UPDATE $table SET $table = '$new_entry' WHERE joinkey = '$row[0]' AND $table = '$orig_entry';);
      push @pgcommands, qq(UPDATE ${table}_hst SET ${table}_hst = '$new_entry' WHERE joinkey = '$row[0]' AND ${table}_hst = '$orig_entry';);
    }
  } # foreach my $field (sort keys %{ $obo{$type} })
} # foreach my $type (sort keys %obo)

foreach my $pgcommand (@pgcommands) {
  print qq($pgcommand\n);
# UNCOMMENT TO POPULATE
#   $dbh->do( $pgcommand );
}

	

__END__

# FIND bad entries below 
foreach my $type (sort keys %all) {
  foreach my $field (sort keys %{ $all{$type} }) {
    my $table = $type . '_' . $field;
#     my $table = $type . '_' . $field . '_hst';
    $result = $dbh->prepare( "SELECT * FROM $table" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) {
      my @data = ();
      next unless $row[1];
      my $entry = $row[1];
      if ($entry =~ m/"/) {
            $entry =~ s/^"//g;
            $entry =~ s/"$//g; }
      if ($entry =~ m/","/) { (@data) = split/","/, $entry; }
        elsif ($entry =~ m/ \| /) { (@data) = split/ \| /, $entry; }
        elsif ($entry =~ m/\|/) { (@data) = split/\|/, $entry; }
        else { push @data, $entry; }
      foreach my $origName (@data) {
        my $name = $origName;
        $name =~ s/^\s+//g;
        $name =~ s/\s+$//g;
        next unless $name;
        if ($nameToId{$name}) {
        } else {
          $bad{name}{$name}{$table}{$row[0]}++;
          $bad{table}{$table}{$name}{$row[0]}++;
#           print qq(NO MAP $table\t$row[0]\t$name\n);
        }
      }
    }
  } # foreach my $field (sort keys %{ $obo{$type} })
} # foreach my $type (sort keys %obo)

foreach my $name (sort keys %{ $bad{name} }) {
  foreach my $table (sort keys %{ $bad{name}{$name} }) {
    next if ($table eq 'trp_strain');
    next if ($table eq 'exp_strain');
#     print qq($name\t$table\n);
  }
  print qq($name\n);
}

foreach my $table (sort keys %{ $bad{table} }) {
  my $outfile = $table;
  open (OUT, ">$table") or die "Cannot create $outfile : $!";
  foreach my $name (sort keys %{ $bad{table}{$table} }) {
    my @pgids = sort keys %{ $bad{table}{$table}{$name} };
    my $pgids = join", ", @pgids;
    print OUT qq($table\t$name\t$pgids\n); 
#     print qq($table\t$name\t$pgids\n); 
  }
  close (OUT) or die "Cannot close $outfile : $!";
}


__END__

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

